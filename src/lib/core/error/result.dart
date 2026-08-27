import 'app_exception.dart';

sealed class const Result<T>() {
  const factory success(T value) = Success<T>;
  const factory failure(AppException exception) = Failure<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  });
}

final class const Success<T>(final T value) extends Result<T> {
  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    return success(value);
  }
}

final class const Failure<T>(final AppException exception) extends Result<T> {
  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    return failure(exception);
  }
}
