sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException({Object? cause})
    : super('Network connection failed', cause: cause);
}

final class TimeoutException extends AppException {
  const TimeoutException({Object? cause})
    : super('The network request timed out', cause: cause);
}

final class HttpStatusException extends AppException {
  const HttpStatusException(
    this.statusCode,
    String message, {
    this.responseBody,
    Object? cause,
  }) : super(message, cause: cause);

  final int statusCode;
  final Object? responseBody;
}

final class CancelledRequestException extends AppException {
  const CancelledRequestException({Object? cause})
    : super('The network request was cancelled', cause: cause);
}

final class UnexpectedNetworkException extends AppException {
  const UnexpectedNetworkException({Object? cause})
    : super('Unexpected network error', cause: cause);
}
