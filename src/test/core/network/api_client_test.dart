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
      expect(
        (result as Failure<Response<dynamic>>).exception,
        isA<NetworkException>(),
      );
    });

    test('maps timeout failures to TimeoutException', () async {
      final client = ApiClient(
        dio: Dio()
          ..httpClientAdapter = _SequenceAdapter((options, attempt) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            );
          }),
        retryPolicy: const RetryPolicy(maxRetries: 0),
      );

      final Result<Response<dynamic>> result = await client.get<dynamic>(
        Uri.parse('https://example.test/package'),
      );

      expect(result, isA<Failure<Response<dynamic>>>());
      expect(
        (result as Failure<Response<dynamic>>).exception,
        isA<TimeoutException>(),
      );
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
      final AppException exception =
          (result as Failure<Response<dynamic>>).exception;
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
      expect(
        (result as Failure<Response<dynamic>>).exception,
        isA<CancelledRequestException>(),
      );
      expect(attempts, 0);
    });

    test('download retry deletes partial file before retrying', () async {
      var attempts = 0;
      final Directory tempDir = Directory.systemTemp.createTempSync(
        'api_client_test_',
      );
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
        retryPolicy: const RetryPolicy(
          maxRetries: 1,
          initialDelay: Duration.zero,
        ),
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
  });
}

typedef _AdapterHandler =
    FutureOr<ResponseBody> Function(RequestOptions options, int attempt);

final class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._handler);

  final _AdapterHandler _handler;
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
