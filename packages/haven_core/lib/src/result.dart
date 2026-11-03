import 'failures.dart';

/// Result of an operation that can fail without throwing across layers.
///
/// Repositories and services return this instead of leaking SDK exceptions
/// into controllers. `void` operations use `Result<void>` with [okVoid].
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T> _ => null,
      };

  HavenFailure? get failureOrNull => switch (this) {
        Ok<T> _ => null,
        Err<T>(:final failure) => failure,
      };

  R map<R>(R Function(T value) onOk, R Function(HavenFailure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final HavenFailure failure;
}

/// `Result<void>` success, since `Ok<void>(null)` is noisy at call sites.
Result<void> okVoid() => const Ok<void>(null);
