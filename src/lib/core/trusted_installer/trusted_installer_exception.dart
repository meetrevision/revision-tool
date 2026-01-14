/// Exception thrown when TrustedInstaller operations fail.
class TrustedInstallerException implements Exception {
  final String message;
  final int? errorCode;

  TrustedInstallerException(this.message, [this.errorCode]);

  @override
  String toString() {
    if (errorCode != null) {
      return 'TrustedInstallerException: $message (Error code: $errorCode)';
    }
    return 'TrustedInstallerException: $message';
  }
}
