/// Time access that tests can freeze.
abstract class Clock {
  const Clock();

  DateTime now();

  Duration since(DateTime earlier) => now().difference(earlier);

  /// True when [at] is already in the past, or when the data is missing and we
  /// cannot promise it is still ahead.
  bool isPast(DateTime? at) {
    final v = at;
    if (v == null) return true;
    return !v.isAfter(now());
  }
}

final class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

final class FixedClock extends Clock {
  FixedClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  @override
  DateTime now() => _now;

  void setTo(DateTime value) => _now = value.toUtc();

  void advance(Duration by) => _now = _now.add(by);
}

/// The one instance the app injects, so a screen never calls `DateTime.now` and
/// a test never depends on the wall clock.
const Clock systemClock = SystemClock();
