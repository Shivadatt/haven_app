/// Null-tolerant readers for Postgres `jsonb` row maps.
///
/// Row payloads arrive as `Map<String, dynamic>`; a single wrong cast should not
/// take down a whole screen, so callers get `null` and decide how to render.
library json_utils;

DateTime? asDate(Object? v) => switch (v) {
      final String s when s.isNotEmpty => DateTime.tryParse(s)?.toUtc(),
      DateTime d => d.toUtc(),
      _ => null,
    };

double? asDouble(Object? v) => switch (v) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };

int? asInt(Object? v) => switch (v) {
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };

bool? asBool(Object? v) => switch (v) {
      final bool b => b,
      final String s => s == 'true' ? true : (s == 'false' ? false : null),
      final int i when i == 0 || i == 1 => i == 1,
      _ => null,
    };

String? asText(Object? v) => switch (v) {
      final String s => s,
      final num n => '$n',
      _ => null,
    };

Map<String, Object?> asMap(Object? v) =>
    v is Map ? Map<String, Object?>.fromEntries(v.entries.map((e) => MapEntry('${e.key}', e.value))) : const {};

List<Object?> asList(Object? v) => v is List ? v : const [];

/// Postgres `timestamptz` renders as an ISO-8601 string in UTC.
Object? toJsonDate(DateTime? v) => v?.toUtc().toIso8601String();
