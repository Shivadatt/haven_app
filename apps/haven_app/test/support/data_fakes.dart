import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

/// Row-plane fakes: the contracts the family and dashboard repositories read
/// and write through. Kept out of the edge/RPC/push fakes so the line-count
/// rule is met by splitting a real seam, not by minifying a file.

/// Rows from the 19 captured tables, filtered exactly the way the real reader
/// filters them: every `eq` pair has to match, `orderDesc` orders, `limit` caps.
class FakeRowReader implements RowReader {
  FakeRowReader([
    Map<String, List<Map<String, Object?>>>? tables,
    Map<String, HavenFailure>? failTables,
  ]) : tables = tables ?? <String, List<Map<String, Object?>>>{},
       failTables = failTables ?? <String, HavenFailure>{};

  /// `table -> rows`. A table with no key answers with no rows, which is what an
  /// empty result looks like, not what a failure looks like.
  final Map<String, List<Map<String, Object?>>> tables;
  HavenFailure? failWith;

  /// Fail reads of these tables, so a test can say "the family is readable and
  /// the profiles are not" — which a global failure cannot express.
  final Map<String, HavenFailure> failTables;

  final List<String> readTables = [];
  final List<Map<String, Object?>> filters = [];
  final List<String?> orderings = [];
  final List<int?> limits = [];

  String? get lastTable => readTables.isEmpty ? null : readTables.last;

  @override
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) async {
    TableName.assertKnown(table);
    readTables.add(table);
    filters.add(eq);
    orderings.add(orderDesc);
    limits.add(limit);
    final HavenFailure? failure = failTables[table] ?? failWith;
    if (failure != null) return Err<List<Map<String, Object?>>>(failure);

    final List<Map<String, Object?>> matched =
        (tables[table] ?? const <Map<String, Object?>>[])
            .where((row) => eq.entries.every((e) => row[e.key] == e.value))
            .toList();
    if (orderDesc != null) {
      // `orderDesc` is the caller asking for newest first, so the fake compares
      // in the opposite direction to the column value.
      matched.sort(
        (a, b) => _desc(b[orderDesc]).compareTo(_desc(a[orderDesc])),
      );
    }
    return Ok<List<Map<String, Object?>>>(
      limit != null && matched.length > limit
          ? matched.sublist(0, limit)
          : matched,
    );
  }

  @override
  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) async {
    final Result<List<Map<String, Object?>>> all = await rows(
      table,
      eq: eq,
      orderDesc: orderDesc,
      limit: 1,
    );
    final List<Map<String, Object?>>? value = all.valueOrNull;
    if (value == null) return Err<Map<String, Object?>?>(all.failureOrNull!);
    return Ok<Map<String, Object?>?>(value.isEmpty ? null : value.first);
  }

  @override
  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) async {
    final Result<List<Map<String, Object?>>> all = await rows(table, eq: eq);
    final List<Map<String, Object?>>? value = all.valueOrNull;
    if (value == null) return Err<int>(all.failureOrNull!);
    return Ok<int>(value.length);
  }

  /// Column order needs a comparison; timestamps are stored as ISO text in the
  /// fixtures, which sorts the same way as the instant itself.
  static Comparable<Object> _desc(Object? v) =>
      v is Comparable<Object> ? v : '';
}

/// Writes recorded, never applied — the fake has no rows to change.
class FakeRowWriter implements RowWriter {
  FakeRowWriter({this.failWith});

  HavenFailure? failWith;
  final List<String> writtenTables = [];
  final List<Map<String, Object?>> payloads = [];
  final List<Map<String, Object?>> matchers = [];

  Map<String, Object?>? get lastPayload =>
      payloads.isEmpty ? null : payloads.last;

  @override
  Future<Result<void>> insert(String table, Map<String, Object?> row) async {
    TableName.assertKnown(table);
    writtenTables.add(table);
    payloads.add(row);
    final HavenFailure? failure = failWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async {
    TableName.assertKnown(table);
    writtenTables.add(table);
    payloads.add(row);
    matchers.add(eq);
    final HavenFailure? failure = failWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> delete(
    String table, {
    required Map<String, Object?> eq,
  }) async {
    TableName.assertKnown(table);
    writtenTables.add(table);
    matchers.add(eq);
    final HavenFailure? failure = failWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }
}
