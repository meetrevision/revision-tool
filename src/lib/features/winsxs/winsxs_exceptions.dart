import '../../utils.dart';

/// Base exception for all WinSxS package-related errors.
sealed class WinSxSException implements Exception {
  WinSxSException(this.message, [this.reason]) {
    logger.e('[WinSxS] $message${reason != null ? '; Reason: $reason' : ''}');
  }

  final String message;

  final Object? reason;

  @override
  String toString() {
    if (reason != null) {
      return 'WinSxSException: $message; Reason: $reason';
    }
    return 'WinSxSException: $message';
  }
}

/// Exception thrown when a WinSxS package cannot be found.
final class WinSxSPackageNotFoundException extends WinSxSException {
  WinSxSPackageNotFoundException(super.message, [super.reason]);

  @override
  String toString() => 'WinSxSPackageNotFoundException: $message';
}

/// Exception thrown when a WinSxS package download fails.
final class WinSxSPackageDownloadException extends WinSxSException {
  WinSxSPackageDownloadException(super.message, [super.reason]);

  @override
  String toString() {
    if (reason != null) {
      return 'WinSxSPackageDownloadException: $message\nReason: $reason';
    }
    return 'WinSxSPackageDownloadException: $message';
  }
}

/// Exception thrown when a WinSxS package file is missing or inaccessible.
final class WinSxSPackageFileNotFoundException extends WinSxSException {
  WinSxSPackageFileNotFoundException(super.message, [super.reason]);

  @override
  String toString() => 'WinSxSPackageFileNotFoundException: $message';
}

/// Exception thrown when a WinSxS package signature is invalid or missing.
final class InvalidWinSxSPackageSignatureException extends WinSxSException {
  InvalidWinSxSPackageSignatureException(super.message, [super.reason]);

  @override
  String toString() => 'InvalidWinSxSPackageSignatureException: $message';
}
