import 'dart:convert';

import 'package:haven_core/haven_core.dart';

/// Document shape, version gate and migration seam for the local database.
///
/// The whole local database is one JSON document: a `tables` map of
/// `table -> List<row>` plus an integer `schemaVersion`. One document keeps the
/// restart story trivial — everything a session wrote is either in this file or
/// it is not, and there is no journal to replay.
///
/// Losing data silently is what this file exists to prevent. A missing file is an
/// empty database (first launch). A file that is present but unreadable or
/// unparseable is a loud typed failure, never an auto-reset: the usual cause is a
/// truncated write, and resetting would delete the only copy of a family's data.
const int localSchemaVersion = 1;

const String localSchemaVersionKey = 'schemaVersion';
const String localTablesKey = 'tables';

/// Upgrade of a document at version `n` to version `n + 1`.
typedef LocalMigration =
    Map<String, Object?> Function(Map<String, Object?> database);

/// Migration seam, version-gated. Empty while [localSchemaVersion] is 1: each
/// future shape change adds one entry keyed by the version it upgrades *from* and
/// raises [localSchemaVersion]. Pure `Map -> Map`, so a migration is testable
/// without a filesystem.
const Map<int, LocalMigration> localMigrations = <int, LocalMigration>{};

/// `detail` marker on the failure a corrupt document produces. HavenFailure is
/// sealed in haven_core, so "damaged file" is carried as a stable detail rather
/// than a new failure class; [isCorruptLocalDatabase] reads it back.
const String localCorruptDetail = 'local_database_corrupt';

/// True when [failure] means "the stored document is damaged", as opposed to a
/// plain I/O error. Only this case is safe for a caller to offer a manual reset.
/// The stored detail carries a short explanation after the marker, so the test
/// is a prefix match, not an equality one.
bool isCorruptLocalDatabase(HavenFailure failure) =>
    failure is StorageFailure &&
    failure.detail?.startsWith(localCorruptDetail) == true;

/// Fresh database document.
Map<String, Object?> emptyLocalDatabase() => <String, Object?>{
  localSchemaVersionKey: localSchemaVersion,
  localTablesKey: <String, Object?>{},
};

/// Parses stored text. The shapes are checked instead of cast, because a JSON
/// array or a bare string is valid JSON and would otherwise crash the first read.
Result<Map<String, Object?>> parseLocalDatabase(String text) {
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    return Err(
      StorageFailure(
        'The stored local data is damaged and was not overwritten.',
        detail: '$localCorruptDetail: ${error.message}',
      ),
    );
  }
  if (decoded is! Map) {
    return Err(
      StorageFailure(
        'The stored local data is damaged and was not overwritten.',
        detail: '$localCorruptDetail: not an object',
      ),
    );
  }
  final database = <String, Object?>{...decoded};
  if (database[localSchemaVersionKey] is! int) {
    return Err(
      StorageFailure(
        'The stored local data is damaged and was not overwritten.',
        detail: '$localCorruptDetail: missing schemaVersion',
      ),
    );
  }
  if (database[localTablesKey] is! Map) database[localTablesKey] = <String, Object?>{};
  return applyLocalMigrations(database);
}

/// Runs the [localMigrations] chain up to [localSchemaVersion]. A document from a
/// newer build is refused rather than downgraded, so its rows survive for the app
/// version that understands them.
Result<Map<String, Object?>> applyLocalMigrations(Map<String, Object?> database) {
  var version = database[localSchemaVersionKey]! as int;
  if (version > localSchemaVersion) {
    return Err(
      StorageFailure(
        'The stored local data is from a newer version of Haven.',
        detail: '$localCorruptDetail: schema $version > $localSchemaVersion',
      ),
    );
  }
  var current = <String, Object?>{...database};
  while (version < localSchemaVersion) {
    final migration = localMigrations[version];
    if (migration == null) {
      return Err(
        StorageFailure(
          'No migration is registered for local schema version $version.',
          detail: '$localCorruptDetail: missing migration',
        ),
      );
    }
    current = {...migration(current)};
    version = current[localSchemaVersionKey] is int
        ? current[localSchemaVersionKey]! as int
        : version + 1;
    current[localSchemaVersionKey] = version;
  }
  return Ok(current);
}
