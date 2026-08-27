import 'dart:io';

import 'package:dio/dio.dart';

final class const RetryPolicy({
  final int maxRetries = 2,
  final Duration initialDelay = const .new(seconds: 1),
}) {
  Duration delayForAttempt(int retryCount) {
    return initialDelay * (1 << retryCount);
  }

  bool shouldRetry(DioException error) {
    if (error.requestOptions.cancelToken?.isCancelled ?? false) {
      return false;
    }

    return switch (error.type) {
      .connectionTimeout || .receiveTimeout || .connectionError || .transformTimeout => true,
      .badResponse => (error.response?.statusCode ?? 0) >= 500,
      .unknown => error.error is SocketException || error.error is HttpException,
      .badCertificate || .cancel || .sendTimeout => false,
    };
  }
}

final class const RetryInterceptor(final Dio _dio, final RetryPolicy _policy) extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.extra['skipRetry'] == true || !_policy.shouldRetry(err)) {
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
