import '../../../utils.dart';

/// Base exception for all security feature errors.
sealed class SecurityException(final String message, [final Object? reason]) implements Exception {
  this {
    logger.e('[Security] $message${reason != null ? '; Reason: $reason' : ''}');
  }

  @override
  String toString() {
    if (reason != null) {
      return 'SecurityException: $message; Reason: $reason';
    }
    return 'SecurityException: $message';
  }
}

/// Exception thrown when Windows Defender operations fail.
final class DefenderOperationException(super.message, [super.reason]) extends SecurityException {
  @override
  String toString() {
    if (reason != null) {
      return 'DefenderOperationException: $message\nReason: $reason';
    }
    return 'DefenderOperationException: $message';
  }
}
