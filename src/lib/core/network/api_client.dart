import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils.dart';
import '../error/app_exception.dart';
import '../error/result.dart';
import 'network_endpoints.dart';
import 'retry_policy.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  ApiClient({
    Dio? dio,
    RetryPolicy retryPolicy = const RetryPolicy(),
    HttpClient Function()? createHttpClient,
  }) : _dio = dio ?? Dio(_baseOptions),
       retryPolicy = retryPolicy {
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

  final Dio _dio;
  final RetryPolicy retryPolicy;

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

  Future<Result<Response<dynamic>>> downloadFile(
    Uri uri,
    String downloadPath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final String safeUri = _safeUri(uri);

    for (var attempt = 0; attempt <= retryPolicy.maxRetries; attempt++) {
      try {
        logger.i('$tag(downloadFile): Downloading $safeUri to $downloadPath');
        final Response<dynamic> response = await _dio.downloadUri(
          uri,
          downloadPath,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          options: Options(extra: const {'skipRetry': true}),
        );
        logger.i('$tag(downloadFile): Download completed for $safeUri');
        return Result<Response<dynamic>>.success(response);
      } on DioException catch (e) {
        final AppException exception = _mapException(e);
        final bool canRetry =
            attempt < retryPolicy.maxRetries && retryPolicy.shouldRetry(e);

        if (!canRetry) {
          logger.e(
            '$tag(downloadFile): Failed to download $safeUri',
            error: exception,
            stackTrace: StackTrace.current,
          );
          return Result<Response<dynamic>>.failure(exception);
        }

        await _deletePartialFile(downloadPath);
        await Future<void>.delayed(retryPolicy.delayForAttempt(attempt));
      }
    }

    return const Result<Response<dynamic>>.failure(
      UnexpectedNetworkException(),
    );
  }

  Future<Result<Response<T>>> _request<T>({
    required String label,
    required Uri uri,
    required Future<Response<T>> Function() operation,
  }) async {
    try {
      logger.i('$tag($label): ${_safeUri(uri)}');

      return Result<Response<T>>.success(await operation());
    } on DioException catch (e) {
      final AppException exception = _mapException(e);

      logger.e(
        '$tag($label): Failed to connect to ${_safeUri(uri)}',
        error: exception,
        stackTrace: StackTrace.current,
      );
      return Result<Response<T>>.failure(exception);
    }
  }

  AppException _mapException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
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
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }

  static Future<void> _deletePartialFile(String downloadPath) async {
    final file = File(downloadPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static String _safeUri(Uri uri) {
    if (!uri.hasQuery) return uri.toString();
    return uri.replace(query: '<redacted>').toString();
  }
}
