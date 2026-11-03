/// `Duration` to the short human strings Haven shows for screen time and
/// freshness: "2h 14m", "45s", "1d 3h", "0s".
///
/// Rules kept small on purpose: at most two units, largest first, no
/// padding, no locale tables. A parent reads these in a list, so consistency
/// beats precision — the full value stays available in the model.
library;

/// True when [value] is short enough to display as "0s" rather than a gap.
bool isZeroLike(Duration value) => value.abs() < const Duration(seconds: 1);

/// Two largest units of [value]. Negative durations are formatted from their
/// magnitude; call [describeDuration] when the sign must also be spoken.
String formatDuration(Duration value) {
  final parts = _units(value.abs());
  final shown = <String>[];
  for (final part in parts) {
    if (part.$1 > 0) shown.add('${part.$1}${part.$2}');
    if (shown.length == 2) break;
  }
  return shown.isEmpty ? '0s' : shown.join(' ');
}

/// Formatted duration with the sign explained in words, for "3h remaining" or
/// "2h over" style lines where a minus sign is easy to miss.
String describeDuration(
  Duration value, {
  String? pastTense,
  String? futureTense,
}) {
  final text = formatDuration(value);
  if (isZeroLike(value)) return text;
  if (value.isNegative) return pastTense ?? '$text over';
  return futureTense ?? text;
}

/// Sum of [values] as one formatted string; used by usage totals.
String formatDurationTotal(Iterable<Duration> values) {
  var total = Duration.zero;
  for (final value in values) {
    total += value;
  }
  return formatDuration(total);
}

/// Minutes to the same style, for backends that hand whole minutes.
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0s';
  return formatDuration(Duration(minutes: minutes));
}

List<(int, String)> _units(Duration value) {
  final total = value.inSeconds;
  return [
    (total ~/ 86400, 'd'),
    ((total % 86400) ~/ 3600, 'h'),
    ((total % 3600) ~/ 60, 'm'),
    (total % 60, 's'),
  ];
}
