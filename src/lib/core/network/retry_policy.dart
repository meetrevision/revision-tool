import 'dart:io';

import 'package:dio/dio.dart';

final class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(seconds: 1),
  });

  final int maxRetries;
  final Duration initialDelay;

  Duration delayForAttempt(int retryCount) {
    return initialDelay * (1 << retryCount);
  }

  bool shouldRetry(DioException error) {
    if (error.requestOptions.cancelToken?.isCancelled ?? false) {
      return false;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return (error.response?.statusCode ?? 0) >= 500;
      case DioExceptionType.unknown:
        return error.error is SocketException || error.error is HttpException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.sendTimeout:
        return false;
    }
  }
}

final class RetryInterceptor extends Interceptor {
  const RetryInterceptor(this._dio, this._policy);

  final Dio _dio;
  final RetryPolicy _policy;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.extra['skipRetry'] == true ||
        !_policy.shouldRetry(err)) {
      return handler.next(err);
    }

    final Object? retryCountValue = err.requestOptions.extra['retryCount'];
    final int retryCount = retryCountValue is int ? retryCountValue : 0;
    if (retryCount >= _policy.maxRetries) {
      return handler.next(err);
    }

    await Future<void>.delayed(_policy.delayForAttempt(retryCount));

    err.requestOptions.extra['retryCount'] = retryCount + 1;

    try {
      final Response<dynamic> response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
