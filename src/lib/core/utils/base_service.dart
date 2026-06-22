import '../error/app_exception.dart';
import '../error/result.dart';

/// Signature for mapping raw errors into domain exceptions.
typedef ErrorMapper =
    AppException Function(Object error, StackTrace stackTrace);

/// Mixin that provides [run] (try-catch → Result) and [failure]
/// (validation short-circuit) to every feature service.
///
/// Each feature plugs in its own [errorMapper] so domain-specific
/// exception types stay isolated.
///
/// ```dart
/// class AuthService with BaseService {
///   @override
///   ErrorMapper get errorMapper => AuthErrorMapper.mapError;
///
///   @override
///   String get logTag => 'AuthService';
/// }
/// ```
mixin BaseService {
  /// Feature-specific error mapper — converts raw errors to domain exceptions.
  ErrorMapper get errorMapper;

  /// Tag used in `dart:developer` log output.
  String get logTag;

  /// Feature-specific exception returned when `requireOnline` is true and the
  /// monitor cannot verify internet access.
  AppException? get offlineException => null;

  /// Wraps [operation] in try-catch and returns a [Result].
  ///
  ///
  /// [onFinally] runs after both success and failure paths when provided.
  Future<Result<T>> run<T>(
    Future<T> Function() operation, {
    Future<void> Function()? onFinally,
  }) async {
    try {
      return .success(await operation());
    } catch (error, stackTrace) {
      final AppException mapped = errorMapper(error, stackTrace);
      return .failure(mapped);
    } finally {
      await onFinally?.call();
    }
  }

  /// Short-circuit failure from a known domain exception (e.g. validation).
  Result<T> failure<T>(AppException exception) => .failure(exception);
}
