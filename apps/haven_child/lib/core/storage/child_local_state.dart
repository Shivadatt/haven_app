import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

/// Non-secret child state kept inside the SAME local JSON document as the
/// tables — never in a second file, never beside the `haven_local.json`
/// engine.
///
/// Decision (for Agent 4's docs): the `TableName` registry is the 19 captured
/// cloud tables, and none of them is a key-value or preferences table, so
/// onboarding drafts and the local child session cannot live there honestly.
/// The brief's fallback applies: one additive top-level key, `childLocalState`,
/// written and read through the existing `{schemaVersion, tables}` conventions
/// (`emptyLocalDatabase` / `parseLocalDatabase` pass extra keys through
/// untouched, and [LocalTables] only replaces the `tables` map).
///
/// Every section is written through [writeSection], which re-reads the document
/// from disk first and then drops the [LocalTables] cache, so the two writers
/// of one file never resurrect a stale copy of the other's data.
///
/// Only non-sensitive fields may be stored here — no tokens, no secrets
/// (contract rule 4). The session section is a device memory, not a credential.
final class ChildLocalStateStore {
  ChildLocalStateStore({required LocalStore store, required LocalTables tables})
    : _store = store,
      _tables = tables;

  static const String documentKey = 'childLocalState';
  static const String sessionSection = 'session';
  static const String onboardingSection = 'onboarding';

  final LocalStore _store;
  final LocalTables _tables;

  /// The section's map, or `null` when absent. A damaged document is a typed
  /// failure — never an implicit "no state yet", and never an auto-reset.
  Future<Result<Map<String, Object?>?>> readSection(String section) async {
    final loaded = await _store.load();
    if (loaded case Err<Map<String, Object?>>()) {
      return Err<Map<String, Object?>?>(loaded.failureOrNull!);
    }
    return Ok<Map<String, Object?>?>(
      _sectionOf(loaded.valueOrNull!, section),
    );
  }

  /// Sets (or, with a `null` [value], removes) one section. Returns the
  /// store's own failure when the current document cannot be read or written.
  Future<Result<void>> writeSection(String section, Map<String, Object?>? value) async {
    final loaded = await _store.load();
    final database = loaded.valueOrNull;
    if (database == null) {
      return Err<void>(loaded.failureOrNull!);
    }
    final existing = database[documentKey];
    final state = <String, Object?>{
      if (existing is Map) ...existing.cast<String, Object?>(),
    };
    if (value == null) {
      state.remove(section);
    } else {
      state[section] = value;
    }
    if (state.isEmpty) {
      database.remove(documentKey);
    } else {
      database[documentKey] = state;
    }
    final saved = await _store.save(database);
    // The on-disk document changed underneath LocalTables; make it re-read.
    _tables.reload();
    return saved;
  }

  static Map<String, Object?>? _sectionOf(Map<String, Object?> database, String section) {
    final state = database[documentKey];
    if (state is! Map) return null;
    final value = state.cast<String, Object?>()[section];
    return value is Map ? value.cast<String, Object?>() : null;
  }
}
