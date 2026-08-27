import '../../utils.dart';

/// Base exception for all WinSxS package-related errors.
sealed class WinSxSException(final String message, [final Object? reason]) implements Exception {
  this {
    logger.e('[WinSxS] $message${reason != null ? '; Reason: $reason' : ''}');
  }

  @override
  String toString() {
    if (reason != null) {
      return 'WinSxSException: $message; Reason: $reason';
    }
    return 'WinSxSException: $message';
  }
}

/// Exception thrown when a WinSxS package cannot be found.
final class WinSxSPackageNotFoundException(super.message, [super.reason]) extends WinSxSException {
  @override
  String toString() => 'WinSxSPackageNotFoundException: $message';
}

/// Exception thrown when a WinSxS package download fails.
final class WinSxSPackageDownloadException(super.message, [super.reason]) extends WinSxSException {
  @override
  String toString() {
    if (reason != null) {
      return 'WinSxSPackageDownloadException: $message\nReason: $reason';
    }
    return 'WinSxSPackageDownloadException: $message';
  }
}

/// Exception thrown when a WinSxS package file is missing or inaccessible.
final class WinSxSPackageFileNotFoundException(super.message, [super.reason]) extends WinSxSException {
  @override
  String toString() => 'WinSxSPackageFileNotFoundException: $message';
}

/// Exception thrown when a WinSxS package signature is invalid or missing.
final class InvalidWinSxSPackageSignatureException(super.message, [super.reason]) extends WinSxSException {
  @override
  String toString() => 'InvalidWinSxSPackageSignatureException: $message';
}
