import 'app_exception.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppException exception) = Failure<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  });
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    return success(value);
  }
}

final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  final AppException exception;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    return failure(exception);
  }
}
