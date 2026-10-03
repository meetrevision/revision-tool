import '../../../core/error/app_exception.dart';
import '../../../utils.dart';

import 'entities/appx_package.dart';

/// Base class for AppX package failures.
sealed class AppxException(final String message, [final Object? reason]) implements Exception {
  this {
    logger.e('[AppX] $message${reason != null ? '; Reason: $reason' : ''}');
  }

  @override
  String toString() => 'AppxException: $message${reason != null ? '; Reason: $reason' : ''}';
}

/// Thrown when the native bridge library fails to load.
final class AppxBridgeUnavailableException extends AppxException {
  // Fixed error message requires passing reason explicitly.
  // ignore: use_primary_constructors, unnecessary_type_name_in_constructor
  AppxBridgeUnavailableException([Object? reason])
    : super(
        'The AppX native bridge could not be loaded. Run Revision Tool from '
        'its installed location.',
        reason,
      );
}

/// Thrown when package deployment refuses a removal or deprovisioning request.
final class AppxRemovalRefusedException extends AppxException {
  // Constructed message quotes the result object.
  // ignore: use_primary_constructors, unnecessary_type_name_in_constructor
  AppxRemovalRefusedException(this.result)
    : super('AppX deployment refused ${result.identifier}: ${result.errorText}') {
    logger.e(
      '[AppX] deployment refused ${result.identifier} '
      'code=0x${result.extendedErrorCode.toRadixString(16)}',
    );
  }

  /// Deployment removal result.
  final AppxRemovalResult result;

  @override
  String toString() =>
      'AppxRemovalRefusedException: ${result.identifier}; '
      'code=0x${result.extendedErrorCode.toRadixString(16)}; ${result.errorText}';
}

/// Thrown when package enumeration fails.
final class AppxEnumerationException(super.message, [super.reason]) extends AppxException {
  @override
  String toString() => 'AppxEnumerationException: $message';
}

/// Thrown when an AppX registry write fails.
final class AppxStoreKeysException(super.message, [super.reason]) extends AppxException {
  @override
  String toString() => 'AppxStoreKeysException: $message';
}

/// Returns the underlying [AppxException] from an [AppException], if present.
AppxException? appxCause(AppException error) => switch (error.cause) {
  final AppxException cause => cause,
  _ => null,
};
