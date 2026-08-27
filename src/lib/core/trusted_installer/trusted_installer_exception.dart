import '../../utils.dart';

/// Exception thrown when TrustedInstaller operations fail.
final class TrustedInstallerException(final String message, [final Object? reason])
    implements Exception {
  this {
    logger.e('[TrustedInstaller] $message${reason != null ? ' (Reason: $reason)' : ''}');
  }

  @override
  String toString() {
    if (reason != null) {
      return 'TrustedInstallerException: $message; (Error code: $reason)';
    }
    return 'TrustedInstallerException: $message';
  }
}
