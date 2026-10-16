import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:riverpod/riverpod.dart';

import '../../utils.dart';
import '../error/app_exception.dart';
import '../error/result.dart';
import 'network_endpoints.dart';
import 'retry_policy.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient({
  Dio? dio,
  final RetryPolicy retryPolicy = const RetryPolicy(),
  HttpClient Function()? createHttpClient,
}) {
  this {
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          createHttpClient ?? _createDefaultHttpClient;
    }

    _dio.interceptors.add(RetryInterceptor(_dio, retryPolicy));
  }

  static const tag = 'ApiClient';

  static final BaseOptions _baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 15),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'user-agent': NetworkEndpoints.microsoftUserAgent,
    },
  );

  final Dio _dio = dio ?? Dio(_baseOptions);
  Future<Result<Response<T>>> get<T>(
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request(
      label: 'get',
      uri: uri,
      operation: () => _dio.getUri<T>(
        uri,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Result<Response<T>>> post<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request(
      label: 'post',
      uri: uri,
      operation: () => _dio.postUri<T>(
        uri,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  /// Suffix of the in-progress file a download streams into before it is
  /// renamed to its final path.
  static const partialFileSuffix = '.part';

  static String partialPathFor(String downloadPath) => '$downloadPath$partialFileSuffix';

  /// Downloads [uri] to [downloadPath], resuming earlier progress when possible.
  ///
  /// Data is streamed into [partialPathFor] and renamed to [downloadPath] once
  /// complete. If a partial file already exists (from a cancelled/paused call
  /// or a failed attempt), the request asks only for the missing bytes with an
  /// HTTP `Range` header; if the server ignores it, the download restarts
  /// cleanly. [onReceiveProgress] counts already-downloaded bytes too.
  ///
  /// The partial file is kept when the request is cancelled (so the next call
  /// resumes it) and between retries, and deleted on any other final failure.
  Future<Result<Response<dynamic>>> downloadFile(
    Uri uri,
    String downloadPath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final String partialPath = partialPathFor(downloadPath);

    for (var attempt = 0; attempt <= retryPolicy.maxRetries; attempt++) {
      try {
        final Response<dynamic> response = await _downloadToPartialFile(
          uri,
          partialPath,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );

        final target = File(downloadPath);
        if (target.existsSync()) await target.delete();
        await File(partialPath).rename(downloadPath);

        return Result<Response<dynamic>>.success(response);
      } on DioException catch (e) {
        final AppException exception = _mapException(e);

        // Paused or cancelled: keep the partial file so a later call can resume.
        if (e.type == DioExceptionType.cancel) {
          return Result<Response<dynamic>>.failure(exception);
        }

        final bool canRetry = attempt < retryPolicy.maxRetries && retryPolicy.shouldRetry(e);

        if (!canRetry) {
          logger.e(
            '$tag(downloadFile): Failed to download $uri '
            '(attempt=${attempt + 1}, type=${e.type}, status=${e.response?.statusCode}, '
            'error=${e.error})',
            error: exception,
            stackTrace: e.stackTrace,
          );
          await _deletePartialFile(partialPath);
          return Result<Response<dynamic>>.failure(exception);
        }

        // Keep the partial file: the next attempt resumes where this one stopped.
        await Future<void>.delayed(retryPolicy.delayForAttempt(attempt));
      }
    }

    return const Result<Response<dynamic>>.failure(UnexpectedNetworkException());
  }

  /// Streams [uri] into [partialPath], appending to it when the server honors
  /// a `Range` request for the bytes already on disk. Every failure, including
  /// cancellation and mid-stream connection errors, surfaces as a
  /// [DioException], and the file is always closed before this returns.
  Future<Response<ResponseBody>> _downloadToPartialFile(
    Uri uri,
    String partialPath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool restartOnUnsatisfiableRange = true,
  }) async {
    final partialFile = File(partialPath);
    if (!partialFile.parent.existsSync()) partialFile.parent.createSync(recursive: true);
    final int existingBytes = partialFile.existsSync() ? partialFile.lengthSync() : 0;

    final Response<ResponseBody> response = await _dio.getUri<ResponseBody>(
      uri,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        extra: const {'skipRetry': true},
        headers: existingBytes > 0 ? {HttpHeaders.rangeHeader: 'bytes=$existingBytes-'} : null,
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == HttpStatus.requestedRangeNotSatisfiable),
      ),
    );
    final ResponseBody body = response.data!;

    if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
      // The partial file doesn't fit this resource (already complete, or the
      // file changed on the server). Throw it away and start over once.
      await body.stream.listen(null).cancel();
      await _deletePartialFile(partialPath);
      if (!restartOnUnsatisfiableRange) {
        throw DioException.badResponse(
          statusCode: HttpStatus.requestedRangeNotSatisfiable,
          requestOptions: response.requestOptions,
          response: response,
        );
      }
      return _downloadToPartialFile(
        uri,
        partialPath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        restartOnUnsatisfiableRange: false,
      );
    }

    // 206 = server sent only the missing bytes; anything else is the full file.
    final bool resumed = existingBytes > 0 && response.statusCode == HttpStatus.partialContent;
    final offset = resumed ? existingBytes : 0;
    final int total = _totalDownloadLength(response.headers, offset);

    final IOSink sink = partialFile.openWrite(mode: resumed ? .append : .write);
    var received = offset;
    if (resumed) onReceiveProgress?.call(received, total);

    final done = Completer<void>();
    final StreamSubscription<Uint8List> subscription = body.stream.listen(
      (chunk) {
        sink.add(chunk);
        received += chunk.length;
        onReceiveProgress?.call(received, total);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!done.isCompleted) done.completeError(error, stackTrace);
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancel.then((cancelError) async {
          if (done.isCompleted) return;
          await subscription.cancel();
          if (!done.isCompleted) done.completeError(cancelError);
        }),
      );
    }

    Object? error;
    StackTrace? stackTrace;
    try {
      await done.future;
    } catch (e, s) {
      error = e;
      stackTrace = s;
    }
    try {
      await sink.close();
    } catch (e, s) {
      error ??= e;
      stackTrace ??= s;
    }

    if (error != null) {
      if (error is DioException) Error.throwWithStackTrace(error, stackTrace!);
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return response;
  }

  /// Full size of the resource: from `Content-Range` (`bytes a-b/total`) on a
  /// partial response, else `Content-Length` plus [offset]. -1 when unknown.
  static int _totalDownloadLength(Headers headers, int offset) {
    final String? contentRange = headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final int slash = contentRange.lastIndexOf('/');
      final int? total = slash >= 0 ? int.tryParse(contentRange.substring(slash + 1).trim()) : null;
      if (total != null) return total;
    }
    final int? length = int.tryParse(headers.value(Headers.contentLengthHeader) ?? '');
    return length != null && length >= 0 ? offset + length : -1;
  }

  Future<Result<Response<T>>> _request<T>({
    required String label,
    required Uri uri,
    required Future<Response<T>> Function() operation,
  }) async {
    try {
      return Result<Response<T>>.success(await operation());
    } on DioException catch (e) {
      final AppException exception = _mapException(e);

      logger.e(
        '$tag($label): Failed to connect to $uri '
        '(type=${e.type}, status=${e.response?.statusCode}, error=${e.error})',
        error: exception,
        stackTrace: e.stackTrace,
      );
      return Result<Response<T>>.failure(exception);
    }
  }

  AppException _mapException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutException(cause: e);
      case DioExceptionType.connectionError:
        return NetworkException(cause: e);
      case DioExceptionType.badResponse:
        final int statusCode = e.response?.statusCode ?? 500;
        return HttpStatusException(
          statusCode,
          'HTTP request failed with status $statusCode',
          responseBody: e.response?.data,
          cause: e,
        );
      case DioExceptionType.cancel:
        return CancelledRequestException(cause: e);
      case DioExceptionType.unknown:
        if (e.error is SocketException || e.error is HttpException) {
          return NetworkException(cause: e);
        }
        return UnexpectedNetworkException(cause: e);
      case DioExceptionType.badCertificate:
        return UnexpectedNetworkException(cause: e);
    }
  }

  static HttpClient _createDefaultHttpClient() {
    // Important for LTSC 2021.
    return HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }

  static Future<void> _deletePartialFile(String downloadPath) async {
    final file = File(downloadPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
