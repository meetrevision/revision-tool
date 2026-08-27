sealed class const AppException(final String message, {final Object? cause}) implements Exception {
  @override
  String toString() => message;
}

final class const NetworkException({super.cause}) extends AppException {
  this : super('Network connection failed');
}

final class const TimeoutException({super.cause}) extends AppException {
  this : super('The network request timed out');
}

final class const HttpStatusException(
  final int statusCode,
  super.message, {
  final Object? responseBody,
  super.cause,
}) extends AppException;

final class const CancelledRequestException({super.cause}) extends AppException {
  this : super('The network request was cancelled');
}

final class const UnexpectedNetworkException({
  String message = 'Unexpected network error',
  Object? cause,
}) extends AppException {
  this : super(message, cause: cause);
}
