import 'package:loki/core/error/failures.dart';

/// Pure Dart functional result type separating success from [Failure].
sealed class Result<T, E extends Failure> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is FailureResult<T, E>;

  T? get dataOrNull => switch (this) {
    Success<T, E>(:final data) => data,
    FailureResult<T, E>() => null,
  };

  E? get failureOrNull => switch (this) {
    Success<T, E>() => null,
    FailureResult<T, E>(:final failure) => failure,
  };

  R fold<R>(R Function(T data) onSuccess, R Function(E failure) onFailure) {
    return switch (this) {
      Success<T, E>(:final data) => onSuccess(data),
      FailureResult<T, E>(:final failure) => onFailure(failure),
    };
  }
}

final class Success<T, E extends Failure> extends Result<T, E> {
  const Success(this.data);
  final T data;
}

final class FailureResult<T, E extends Failure> extends Result<T, E> {
  const FailureResult(this.failure);
  final E failure;
}
