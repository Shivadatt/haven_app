import 'dart:async';
import 'dart:math' as math;

/// Bounded retry with jitter, used by network paths.
///
/// Only [NetworkFailure]-style transience should ever reach this; a rejected
/// request is not retried, because retrying an authorization failure reads as
/// abuse and the backend rate-limits it.
final class RetryPolicy {
  const RetryPolicy({
    this.attempts = 3,
    this.base = const Duration(milliseconds: 400),
    this.ceiling = const Duration(seconds: 8),
    double? factor,
    int? seed,
  }) : factor = factor ?? 2.0,
       _seed = seed;

  final int attempts;
  final Duration base;
  final Duration ceiling;
  final double factor;
  final int? _seed;

  Duration delayFor(int attempt) {
    final raw =
        base.inMilliseconds * math.pow(factor, math.max(0, attempt - 1));
    final capped = math.min(raw, ceiling.inMilliseconds.toDouble()).round();
    final random = _seed == null ? math.Random() : math.Random(_seed);
    return Duration(
      milliseconds: (capped * (0.75 + 0.5 * random.nextDouble())).round(),
    );
  }

  Future<T> run<T>(
    Future<T> Function() body, {
    required bool Function(Object error) retryOn,
    Future<void> Function(Duration delay)? onWait,
  }) async {
    var attempt = 1;
    while (true) {
      try {
        return await body();
      } catch (error) {
        if (attempt >= attempts || !retryOn(error)) rethrow;
        final delay = delayFor(attempt);
        if (onWait != null)
          await onWait(delay);
        else
          await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }
}

/// A cancelled parent must stop the retry loop, not keep polling a dead screen.
final class RetryCancelled implements Exception {
  const RetryCancelled();
}
