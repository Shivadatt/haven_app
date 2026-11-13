import 'local_document.dart';

/// Column-local query helpers shared by the offline store and every feature that
/// reads from it, so that "what counts as a demo row" has exactly one definition
/// in the codebase.
///
/// The demo marker can be `demo: true` or `is_demo: true`. Table operations
/// neither set it nor strip it: a caller seeding demo content writes the flag,
/// and a caller writing real content leaves it absent.
abstract final class LocalQueries {
  static const String demoColumn = 'demo';
  static const String isDemoColumn = 'is_demo';

  /// Returns true when [row] is marked as demo content via either flag.
  static bool isDemoRow(Map<String, Object?> row) =>
      row[demoColumn] == true || row[isDemoColumn] == true;

  /// Rows explicitly marked as demo content.
  static List<Map<String, Object?>> demoRows(List<Map<String, Object?>> rows) =>
      rows.where(isDemoRow).toList();

  /// Rows that are not demo content, including rows without any demo flag.
  static List<Map<String, Object?>> userRows(List<Map<String, Object?>> rows) =>
      rows.where((row) => !isDemoRow(row)).toList();

  /// True when every `eq` pair matches. Parity with `FakeRowReader`.
  static bool matches(Map<String, Object?> row, Map<String, Object?> eq) => eq
      .entries
      .every((entry) => row[entry.key] == entry.value);

  /// Filters, sorts and caps [rows]. Returns shallow-copied row maps.
  static List<Map<String, Object?>> query(
    List<Map<String, Object?>> rows, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) {
    final matched = rows
        .where((row) => matches(row, eq))
        .map((row) => <String, Object?>{...row})
        .toList();
    if (orderDesc != null) {
      matched.sort((a, b) => compareDescending(a, b, orderDesc));
    }
    return limit != null && matched.length > limit
        ? matched.sublist(0, limit)
        : matched;
  }

  /// Newest-first comparison on [column], mirroring the fake exactly.
  static int compareDescending(
    Map<String, Object?> a,
    Map<String, Object?> b,
    String column,
  ) {
    final left = _asComparable(b[column]);
    final right = _asComparable(a[column]);
    if (left.runtimeType != right.runtimeType) return 0;
    try {
      return left.compareTo(right);
    } on TypeError {
      return 0;
    }
  }

  static Comparable<Object> _asComparable(Object? value) =>
      value is Comparable<Object> ? value : '';

  /// The `table -> rows` half of a database document, as a mutable map.
  static Map<String, Object?> tablesOf(Map<String, Object?> database) {
    final tables = database[localTablesKey];
    if (tables is Map<String, Object?>) return tables;
    final created = <String, Object?>{};
    database[localTablesKey] = created;
    return created;
  }

  /// Rows of [table] in [database]; absent table is treated as empty list.
  static List<Map<String, Object?>> rowsOf(
    Map<String, Object?> database,
    String table,
  ) {
    final stored = tablesOf(database)[table];
    if (stored is! List) return const [];
    return stored.cast<Map<String, Object?>>();
  }
}
