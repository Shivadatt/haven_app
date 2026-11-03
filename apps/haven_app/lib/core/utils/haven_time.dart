/// One relative-time sentence, because every "last seen" on the app has to be
/// readable by a parent who is not thinking in timestamps.
///
/// Pure and clock-injected so a test can pin the instant. It never rounds a
/// missing value into "just now": no time means "no time", which is what the
/// screens show when a device has never reported in.
library;

/// A short, plain phrase for `instant` as seen from `now`.
String havenTimeAgo(DateTime? instant, {DateTime? now}) {
  if (instant == null) return 'No time recorded';
  final DateTime from = now ?? DateTime.now();
  final Duration elapsed = from.difference(instant.toUtc());

  if (elapsed.isNegative) return 'Scheduled';
  if (elapsed.inMinutes < 1) return 'This minute';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} minutes ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours} hours ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
  if (elapsed.inDays < 31) {
    final int weeks = elapsed.inDays ~/ 7;
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  }
  if (elapsed.inDays < 365) {
    final int months = (elapsed.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
  final int years = (elapsed.inDays / 365).floor();
  return '$years ${years == 1 ? 'year' : 'years'} ago';
}

/// A date a parent can read out loud, or nothing when there is no date.
String? havenDay(DateTime? instant) =>
    instant == null ? null : '${instant.day}/${instant.month}/${instant.year}';
