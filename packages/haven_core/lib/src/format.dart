import 'dart:math' as math;

import 'clock.dart';

/// Screen-time and staleness wording in plain English.
///
/// `usage_daily.total_ms` is an `int8` of milliseconds; this is the only place
/// that turns it into a human span, so a screen never formats it inline.
String formatSpan(Duration span) {
  if (span.isNegative) return '0s';
  final totalSeconds = span.inSeconds;
  if (totalSeconds < 60) return '${totalSeconds}s';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

String formatSpanFromMs(int? milliseconds) => milliseconds == null
    ? 'no data'
    : formatSpan(Duration(milliseconds: milliseconds));

/// "Just now / 12 min ago / 3 h ago / yesterday / 4 Sep".
///
/// Anything older falls back to a date, because "1200 h ago" is not readable.
String formatRelative(DateTime? at, {Clock clock = systemClock}) {
  final value = at;
  if (value == null) return 'unknown';
  final diff = clock.now().difference(value);
  if (diff.isNegative) return 'scheduled';
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return formatDate(value);
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime? at) {
  final v = at;
  if (v == null) return 'unknown';
  final local = v.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

String formatTimeOfDay(DateTime? at) {
  final v = at;
  if (v == null) return '--:--';
  final local = v.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Distance in metres, worded for a parent, never with false precision.
String formatDistanceM(int? metres) {
  final m = metres;
  if (m == null) return 'unknown distance';
  if (m < 1000) return '${m < 1 ? 0 : m} m';
  return '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km';
}

/// Straight-line metres between two WGS-84 points.
///
/// Used only for "inside a circular zone" checks and for display; GPS accuracy
/// is not modelled, so the result is stated to the nearest metre and never
/// presented as more precise than the fix that produced it.
double haversineMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusM = 6371008.8;
  double rad(double deg) => deg * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  double sin2(double x) {
    final s = math.sin(x);
    return s * s;
  }

  final a =
      sin2(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * sin2(dLon / 2);
  return 2 * earthRadiusM * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
