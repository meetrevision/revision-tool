import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/error/app_exception.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/core/network/api_client.dart';
import 'package:revitool/core/network/retry_policy.dart';

void main() {
  group('ApiClient', () {
    test('maps connection failures to NetworkException', () async {
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: const SocketException('offline'),
            );
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect((result as Failure<Response<dynamic>>).exception, isA<NetworkException>());
    });

    test('maps timeout failures to TimeoutException', () async {
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            throw DioException(requestOptions: options, type: DioExceptionType.receiveTimeout);
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect((result as Failure<Response<dynamic>>).exception, isA<TimeoutException>());
    });

    test('maps bad responses to HttpStatusException', () async {
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            return ResponseBody.fromString('not found', 404);
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      final AppException exception = (result as Failure<Response<dynamic>>).exception;
      expect(exception, isA<HttpStatusException>());
      expect((exception as HttpStatusException).statusCode, 404);
    });

    test('retries transient failures and succeeds', () async {
      var attempts = 0;
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            attempts++;
            if (attempts < 3) {
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: const SocketException('reset'),
              );
            }
            return ResponseBody.fromString('ok', 200);
          }),
        retryPolicy: const RetryPolicy(initialDelay: Duration.zero),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Success<Response<dynamic>>>());
      expect(attempts, 3);
    });

    test('does not retry non-transient client errors', () async {
      var attempts = 0;
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            attempts++;
            return ResponseBody.fromString('bad request', 400);
          }),
        retryPolicy: const RetryPolicy(initialDelay: Duration.zero),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect(attempts, 1);
    });

    test('does not retry cancelled requests', () async {
      var attempts = 0;
      final cancelToken = CancelToken()..cancel('test');
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            attempts++;
            return ResponseBody.fromString('ok', 200);
          }),
        retryPolicy: const RetryPolicy(initialDelay: Duration.zero),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
        cancelToken: cancelToken,
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect((result as Failure<Response<dynamic>>).exception, isA<CancelledRequestException>());
      expect(attempts, 0);
    });

    test('download retry restarts when the server ignores the range request', () async {
      var attempts = 0;
      final Directory tempDir = Directory.systemTemp.createTempSync('api_client_test_');
      final file = File('${tempDir.path}\\download.txt');
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            attempts++;
            if (attempts == 1) {
              return ResponseBody(
                _failingStream(),
                200,
                headers: {
                  Headers.contentLengthHeader: ['7'],
                },
              );
            }
            return ResponseBody.fromString('complete', 200);
          }),
        retryPolicy: const RetryPolicy(maxRetries: 1, initialDelay: Duration.zero),
      );

      final Result<Response<dynamic>> result = await client.downloadFile(
        Uri.parse('https://example.test/download'),
        file.path,
      );

      expect(result, isA<Success<Response<dynamic>>>());
      expect(attempts, 2);
      expect(file.readAsStringSync(), 'complete');

      tempDir.deleteSync(recursive: true);
    });

    test('download resumes a partial file with a range request', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('api_client_test_');
      final file = File('${tempDir.path}\\download.txt');
      File(ApiClient.partialPathFor(file.path)).writeAsStringSync('comp');
      String? rangeHeader;
      final progress = <(int, int)>[];
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            rangeHeader = options.headers[HttpHeaders.rangeHeader] as String?;
            return ResponseBody.fromString(
              'lete',
              206,
              headers: {
                HttpHeaders.contentRangeHeader: ['bytes 4-7/8'],
                Headers.contentLengthHeader: ['4'],
              },
            );
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.downloadFile(
        Uri.parse('https://example.test/download'),
        file.path,
        onReceiveProgress: (count, total) => progress.add((count, total)),
      );

      expect(result, isA<Success<Response<dynamic>>>());
      expect(rangeHeader, 'bytes=4-');
      expect(file.readAsStringSync(), 'complete');
      expect(File(ApiClient.partialPathFor(file.path)).existsSync(), isFalse);
      expect(progress.first, (4, 8));
      expect(progress.last, (8, 8));

      tempDir.deleteSync(recursive: true);
    });

    test('cancelled download keeps the partial file for resuming', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('api_client_test_');
      final file = File('${tempDir.path}\\download.txt');
      final cancelToken = CancelToken();
      final body = StreamController<Uint8List>();
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            body.add(Uint8List.fromList('part'.codeUnits));
            return ResponseBody(
              body.stream,
              200,
              headers: {
                Headers.contentLengthHeader: ['8'],
              },
            );
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.downloadFile(
        Uri.parse('https://example.test/download'),
        file.path,
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) => cancelToken.cancel('paused'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect((result as Failure<Response<dynamic>>).exception, isA<CancelledRequestException>());
      expect(file.existsSync(), isFalse);
      expect(File(ApiClient.partialPathFor(file.path)).readAsStringSync(), 'part');

      await body.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}

typedef _AdapterHandler = FutureOr<ResponseBody> Function(RequestOptions options, int attempt);

final class _SequenceAdapter(final _AdapterHandler _handler) implements HttpClientAdapter {
  var _attempt = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _attempt++;
    return _handler(options, _attempt);
  }
}

Stream<Uint8List> _failingStream() async* {
  yield Uint8List.fromList('partial'.codeUnits);
  throw const HttpException('Connection closed while receiving data');
}
