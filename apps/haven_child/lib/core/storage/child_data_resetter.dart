import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'child_storage_paths.dart';

/// Deliberate, destructive clear of the whole local document.
///
/// This is the dev/test exit hatch the Stage 1 brief asks for: the splash
/// offers it when the document is corrupt, and tests use it for a hard reset.
/// It is never automatic — silently losing data is exactly the failure mode
/// `local_document.dart` exists to prevent, so every call is a human-confirmed
/// (or test-harness) action.
///
/// A fresh `{schemaVersion, tables}` document is written through the same
/// [FileLocalStore] conventions as every other save (atomic tmp + rename),
/// so a reset cannot leave a half-written file.
final class ChildDataResetter {
  const ChildDataResetter();

  /// When [verifyReadableFirst] is true the current document is read first and
  /// the reset refuses on any read failure — that is the plain data-wipe path.
  /// The corrupt-database exit passes `false`: the damaged bytes are exactly
  /// what the user agreed to replace, so reading them must not gate the fix.
  static Future<Result<void>> clearAll({
    String? directoryPath,
    bool verifyReadableFirst = true,
  }) async {
    final Result<String> path = directoryPath == null
        ? await ChildStoragePaths.resolve()
        : Ok<String>(directoryPath);
    if (path case Err<String>()) {
      return Err<void>(path.failureOrNull!);
    }
    final store = FileLocalStore(path.valueOrNull!);
    if (verifyReadableFirst) {
      final loaded = await store.load();
      if (loaded.isErr) return Err<void>(loaded.failureOrNull!);
    }
    return store.save(emptyLocalDatabase());
  }
}
