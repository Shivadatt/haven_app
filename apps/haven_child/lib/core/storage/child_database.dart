import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'child_local_state.dart';
import 'child_storage_paths.dart';

/// Bootstrap and handle for the child app's local database.
///
/// REUSE DECISION (required documentation at the store facade): the child app
/// does NOT invent a competing persistence abstraction. It reuses the
/// `haven_api` offline engine exactly as the parent app does —
/// * [FileLocalStore]: one JSON document, atomic tmp+rename writes, typed
///   corrupt-file failures (`local_database_corrupt`), never a silent reset;
/// * [LocalTables]: the `{schemaVersion, tables}` conventions plus the
///   `TableName` / `LocalSchema` / `LocalConstraints` registry guards, so an
///   invented table name fails at review instead of at runtime;
/// * the same `haven_local.json` file name — which is NOT shared state: each
///   app runs in its own Android sandbox with its own documents directory,
///   and the child's `applicationId` (`com.haven.child`) differs from the
///   parent's.
///
/// The one addition is [ChildLocalStateStore]: an additive top-level key in
/// the same document for the non-secret sections the 19-table registry has no
/// place for (onboarding draft, local session).
final class ChildDatabase {
  ChildDatabase._({required this.store, required this.tables, required this.localState});

  /// The raw document gateway (same instance LocalTables was built on).
  final LocalStore store;

  /// Registry-guarded table operations: the child lane writes `profiles` only.
  final LocalTables tables;

  /// The additive `childLocalState` document key, sharing this one store.
  final ChildLocalStateStore localState;

  /// Opens at the app's documents directory. Every failure — path, I/O,
  /// corruption — comes back as a typed [HavenFailure], never a throw.
  static Future<Result<ChildDatabase>> open() async {
    final path = await ChildStoragePaths.resolve();
    if (path case Err<String>()) {
      return Err<ChildDatabase>(path.failureOrNull!);
    }
    return openAt(path.valueOrNull!);
  }

  static Future<Result<ChildDatabase>> openAt(String directoryPath) async {
    final store = FileLocalStore(directoryPath);
    final tables = LocalTables(store);
    final opened = await tables.open();
    if (opened.isErr) {
      // A corrupt document must reach the UI as corrupt: the splash offers an
      // honest error plus the explicit developer reset, nothing auto-clears.
      return Err<ChildDatabase>(opened.failureOrNull!);
    }
    return Ok(
      ChildDatabase._(
        store: store,
        tables: tables,
        localState: ChildLocalStateStore(store: store, tables: tables),
      ),
    );
  }
}
