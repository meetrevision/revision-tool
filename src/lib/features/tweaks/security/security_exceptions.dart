import '../../../utils.dart';

/// Base exception for all security feature errors.
sealed class SecurityException implements Exception {
  SecurityException(this.message, [this.reason]) {
    logger.e('[Security] $message${reason != null ? '; Reason: $reason' : ''}');
  }

  final String message;
  final Object? reason;

  @override
  String toString() {
    if (reason != null) {
      return 'SecurityException: $message; Reason: $reason';
    }
    return 'SecurityException: $message';
  }
}

/// Exception thrown when Windows Defender operations fail.
final class DefenderOperationException extends SecurityException {
  DefenderOperationException(super.message, [super.reason]);

  @override
  String toString() {
    if (reason != null) {
      return 'DefenderOperationException: $message\nReason: $reason';
    }
    return 'DefenderOperationException: $message';
  }
}
