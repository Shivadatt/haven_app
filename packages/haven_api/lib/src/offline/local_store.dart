import 'dart:convert';
import 'dart:io';

import 'package:haven_core/haven_core.dart';

import 'local_document.dart';

/// Persistence layer under the offline tables: read one document, write one
/// document. The document's own shape, version and migration seam live in
/// `local_document.dart`.
abstract interface class LocalStore {
  /// Stored document, migrations applied. A missing file is [emptyLocalDatabase],
  /// a damaged one is a typed failure — never an empty result.
  Future<Result<Map<String, Object?>>> load();

  /// Replaces the stored document. Implementations write atomically.
  Future<Result<void>> save(Map<String, Object?> database);
}

/// Production store over `dart:io`.
///
/// [directoryPath] is injected as a string (not a `Directory`, not a plugin) so a
/// test can pass a temp directory and the app can pass its documents directory.
///
/// Writes land in `<file>.tmp` and are renamed into place, so a crash mid-write
/// leaves the previous complete document readable. Reads never consult the `.tmp`
/// file: a stale artifact is ignored, not merged, and the next save overwrites it.
final class FileLocalStore implements LocalStore {
  FileLocalStore(this.directoryPath, {this.fileName = 'haven_local.json'});

  final String directoryPath;
  final String fileName;

  File get _file => File('$directoryPath/$fileName');

  @override
  Future<Result<Map<String, Object?>>> load() async {
    try {
      if (!await _file.exists()) return Ok(emptyLocalDatabase());
      return parseLocalDatabase(await _file.readAsString());
    } on FileSystemException catch (error) {
      return Err(
        StorageFailure(
          'The local data could not be read.',
          detail: error.osError?.message ?? error.message,
        ),
      );
    }
  }

  @override
  Future<Result<void>> save(Map<String, Object?> database) async {
    final file = _file;
    final temporary = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(database),
        flush: true,
      );
      await _renameOver(temporary, file);
      return okVoid();
    } on FileSystemException catch (error) {
      await _discard(temporary);
      return Err(
        StorageFailure(
          'The local data could not be saved.',
          detail: error.osError?.message ?? error.message,
        ),
      );
    }
  }
}

/// Rename onto an existing file. POSIX and Windows both replace; a locked target
/// throws, and the copy is the fallback that still leaves no `.tmp` behind.
Future<void> _renameOver(File from, File to) async {
  try {
    await from.rename(to.path);
  } on FileSystemException {
    await from.copy(to.path);
    await from.delete();
  }
}

Future<void> _discard(File temporary) async {
  try {
    if (await temporary.exists()) await temporary.delete();
  } on FileSystemException {
    // Best effort: [load] ignores the artifact, so a cleanup failure must not
    // mask the write failure being reported.
  }
}

/// Test store: the document lives in this instance. Separate from
/// [FileLocalStore] so a rule test needs no filesystem, while a persistence test
/// can point two readers at one file through two stores.
final class InMemoryLocalStore implements LocalStore {
  InMemoryLocalStore([Map<String, Object?>? database])
    : _database = database == null ? null : <String, Object?>{...database};

  Map<String, Object?>? _database;

  /// Documents handed to [save], newest last — a test asserts on the count.
  final List<Map<String, Object?>> saves = <Map<String, Object?>>[];

  /// Makes the next [save] fail once, to prove a failed flush is reported and the
  /// rows stay pending rather than quietly dropped.
  bool failNextSave = false;

  @override
  Future<Result<Map<String, Object?>>> load() async {
    final database = _database;
    if (database == null) return Ok(emptyLocalDatabase());
    return Ok(<String, Object?>{...database});
  }

  @override
  Future<Result<void>> save(Map<String, Object?> database) async {
    if (failNextSave) {
      failNextSave = false;
      return const Err<void>(StorageFailure('Injected save failure.'));
    }
    _database = <String, Object?>{...database};
    saves.add(_database!);
    return okVoid();
  }
}
