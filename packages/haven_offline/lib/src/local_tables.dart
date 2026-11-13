import 'package:haven_core/haven_core.dart';

import 'local_constraints.dart';
import 'local_queries.dart';
import 'local_schema.dart';
import 'local_store.dart';

/// Stateful table operations over [LocalStore] with schema constraint checks.
final class LocalTables {
  LocalTables(this._store, {this.schema = LocalSchema.defaults});

  final LocalStore _store;
  final LocalSchema schema;

  Map<String, Object?>? _database;
  bool _dirty = false;

  late final LocalConstraints _constraints = LocalConstraints(
    schema: schema,
    rowsOf: _rowsOf,
  );

  /// Loads the document. Idempotent and called by every operation.
  Future<Result<void>> open() async {
    if (_database != null) return okVoid();
    final loaded = await _store.load();
    if (loaded case Err<Map<String, Object?>>()) {
      return Err<void>(loaded.failureOrNull!);
    }
    _database = loaded.valueOrNull!;
    return okVoid();
  }

  /// Writes pending changes. Retries on the next mutation if a save fails.
  Future<Result<void>> flush() async {
    final database = _database;
    if (database == null || !_dirty) return okVoid();
    final saved = await _store.save(database);
    if (saved.isOk) _dirty = false;
    return saved;
  }

  /// Drops the loaded document so the next call re-reads from the store.
  void reload() {
    _database = null;
    _dirty = false;
  }

  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) async {
    final failure = await _guard(table);
    if (failure != null) return Err<List<Map<String, Object?>>>(failure);
    return Ok<List<Map<String, Object?>>>(
      LocalQueries.query(_rowsOf(table), eq: eq, orderDesc: orderDesc, limit: limit),
    );
  }

  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) async {
    final found = await rows(table, eq: eq, orderDesc: orderDesc, limit: 1);
    final value = found.valueOrNull;
    if (value == null) return Err<Map<String, Object?>?>(found.failureOrNull!);
    return Ok<Map<String, Object?>?>(value.isEmpty ? null : value.first);
  }

  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) async {
    final found = await rows(table, eq: eq);
    return found.isOk
        ? Ok<int>(found.valueOrNull!.length)
        : Err<int>(found.failureOrNull!);
  }

  Future<Result<void>> insert(String table, Map<String, Object?> row) async {
    final failure = await _guard(table);
    if (failure != null) return Err<void>(failure);
    final current = _rowsOf(table);
    final candidate = <String, Object?>{...row};
    final violation = _constraints.violationFor(table, candidate, current);
    if (violation != null) return Err<void>(violation);
    _write(table, [...current, candidate]);
    return flush();
  }

  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async {
    final failure = await _guard(table);
    if (failure != null) return Err<void>(failure);
    final current = _rowsOf(table);
    final indices = [
      for (var i = 0; i < current.length; i++)
        if (LocalQueries.matches(current[i], eq)) i,
    ];
    if (indices.isEmpty) return okVoid();
    final updated = [
      for (var i = 0; i < current.length; i++)
        indices.contains(i)
            ? <String, Object?>{...current[i], ...row}
            : current[i],
    ];
    for (final i in indices) {
      final others = [
        for (var j = 0; j < updated.length; j++) if (j != i) updated[j],
      ];
      final violation = _constraints.violationFor(table, updated[i], others);
      if (violation != null) return Err<void>(violation);
    }
    _write(table, updated);
    return flush();
  }

  Future<Result<void>> delete(
    String table, {
    required Map<String, Object?> eq,
  }) async {
    final failure = await _guard(table);
    if (failure != null) return Err<void>(failure);
    if (eq.isEmpty) {
      return const Err<void>(
        ValidationFailure('A local delete needs a filter naming the rows.', field: 'eq'),
      );
    }
    final current = _rowsOf(table);
    final doomed = current.where((r) => LocalQueries.matches(r, eq)).toList();
    if (doomed.isEmpty) return okVoid();
    final blocked = _constraints.blockedDelete(table, doomed);
    if (blocked != null) return Err<void>(blocked);
    _write(table, current.where((r) => !LocalQueries.matches(r, eq)).toList());
    return flush();
  }

  /// Removes demo rows where `is_demo == true` or `demo == true`.
  Future<Result<void>> clearDemoData() async {
    final opened = await open();
    if (opened.isErr) return opened;
    final tables = LocalQueries.tablesOf(_database!);
    var changed = false;
    for (final key in tables.keys.toList()) {
      final current = LocalQueries.rowsOf(_database!, key);
      final kept = LocalQueries.userRows(current);
      if (kept.length != current.length) {
        tables[key] = kept;
        changed = true;
      }
    }
    if (!changed) return okVoid();
    _dirty = true;
    return flush();
  }

  /// Alias for [clearDemoData].
  Future<Result<void>> clearDemoRows() => clearDemoData();

  /// Alias for [clearDemoData].
  Future<Result<void>> removeDemoData() => clearDemoData();

  /// Clears all rows in all local tables and flushes to the store.
  Future<Result<void>> resetAll() async {
    final opened = await open();
    if (opened.isErr) return opened;
    LocalQueries.tablesOf(_database!).clear();
    _dirty = true;
    return flush();
  }

  Future<HavenFailure?> _guard(String table) async {
    final opened = await open();
    if (opened.isErr) return opened.failureOrNull;
    if (schema.isKnown(table)) return null;
    return ValidationFailure(
      'No local table named "$table".',
      detail: 'not one of the captured tables',
      field: 'table',
    );
  }

  List<Map<String, Object?>> _rowsOf(String table) =>
      _database == null ? const [] : LocalQueries.rowsOf(_database!, table);

  void _write(String table, List<Map<String, Object?>> rows) {
    LocalQueries.tablesOf(_database!)[table] = rows;
    _dirty = true;
  }
}
