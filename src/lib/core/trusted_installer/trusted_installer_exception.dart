import '../../utils.dart';

/// Exception thrown when TrustedInstaller operations fail.
class TrustedInstallerException implements Exception {
  TrustedInstallerException(this.message, [this.reason]) {
    logger.e(
      '[TrustedInstaller] $message${reason != null ? ' (Reason: $reason)' : ''}',
    );
  }

  final String message;
  final Object? reason;

  @override
  String toString() {
    if (reason != null) {
      return 'TrustedInstallerException: $message; (Error code: $reason)';
    }
    return 'TrustedInstallerException: $message';
  }
}
