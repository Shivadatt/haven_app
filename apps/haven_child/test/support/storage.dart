import 'dart:io';

import 'package:haven_api/haven_api.dart';
import 'package:haven_models/haven_models.dart';

/// Filesystem helpers for the storage unit lanes.
///
/// Plain `test()` bodies run on the real event loop, so `dart:io` needs no
/// `tester.runAsync` here — that constraint only applies inside
/// `testWidgets` (the smoke/boot tests avoid it by using fake seams or by
/// pumping inside `runAsync`).
abstract final class StorageTestLane {
  /// A fresh temp directory, deleted in the caller's `addTearDown`.
  static String createTempDirectory() {
    final Directory dir = Directory.systemTemp.createTempSync('haven_child_test_');
    return dir.path;
  }

  /// Opens the real [ChildDatabase]-equivalent stack (store + tables) at [dir]
  /// without importing the child app's own wrapper — the unit lane tests the
  /// repository over the reused engine, exactly as `ChildDatabase.openAt` wires it.
  static LocalTables tablesAt(String directoryPath) =>
      LocalTables(FileLocalStore(directoryPath));

  static LocalTables memoryTables([InMemoryLocalStore? store]) =>
      LocalTables(store ?? InMemoryLocalStore());

  /// The document path `FileLocalStore` writes into.
  static String documentPath(String directoryPath) =>
      '$directoryPath/haven_local.json';

  /// Writes raw bytes into the document so a test can hand the lane a
  /// damaged, truncated or future-versioned file.
  static void writeRawDocument(String directoryPath, String contents) {
    File(documentPath(directoryPath)).writeAsStringSync(contents);
  }

  static String readRawDocument(String directoryPath) =>
      File(documentPath(directoryPath)).readAsStringSync();

  /// A `profiles` row that this lane did NOT write — the role-guard seed.
  static Map<String, Object?> parentRoleRow({String id = 'foreign-1'}) =>
      <String, Object?>{
        'id': id,
        'role': ProfileRole.parent.wire,
        'display_name': 'A parent row on a child device',
        'created_at': '2026-11-06T00:00:00.000Z',
        'updated_at': '2026-11-06T00:00:00.000Z',
      };

  /// Best-effort temp-directory cleanup for `addTearDown`: a vanished or
  /// locked temp folder must never turn a green test red.
  static void deleteTemp(String directoryPath) {
    try {
      Directory(directoryPath).deleteSync(recursive: true);
    } on OSError {
      // Ignored on purpose — the OS owns /tmp garbage.
    }
  }
}
