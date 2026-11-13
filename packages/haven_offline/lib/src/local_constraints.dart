import 'package:haven_core/haven_core.dart';

import 'local_schema.dart';

/// The constraint checks [LocalTables] runs before it writes, expressed against a
/// [LocalSchema] and a row lookup. Split out so the table operations stay readable
/// and the rules — the part a reviewer has to trust — stay in one place.
///
/// Failure types are chosen the way the online plane chooses them: a caller
/// mistake about *which* row (missing key, empty filter) is a [ValidationFailure]
/// the user can correct, and a rejected write against stored data is a
/// [BackendFailure], because locally the store *is* the backend.
final class LocalConstraints {
  LocalConstraints({required this.schema, required this.rowsOf});

  final LocalSchema schema;

  /// Current rows of one table, read from the live document.
  final List<Map<String, Object?>> Function(String table) rowsOf;

  /// Null when [candidate] may be written next to [others].
  HavenFailure? violationFor(
    String table,
    Map<String, Object?> candidate,
    List<Map<String, Object?>> others,
  ) {
    final rule = schema.ruleFor(table);
    return _uniqueViolation(table, rule, candidate, others) ??
        _compositeViolation(table, rule, candidate, others) ??
        _referenceViolation(table, candidate);
  }

  HavenFailure? _uniqueViolation(
    String table,
    LocalTableRule rule,
    Map<String, Object?> candidate,
    List<Map<String, Object?>> others,
  ) {
    final column = rule.uniqueColumn;
    if (column == null) return null;
    final value = candidate[column];
    if (value == null) {
      return ValidationFailure(
        'A local $table row needs a value in "$column".',
        field: column,
      );
    }
    if (others.any((row) => row[column] == value)) {
      return BackendFailure(
        'A local $table row with that "$column" already exists.',
        detail: 'local_unique_violation: $table.$column',
      );
    }
    return null;
  }

  /// Composite uniques, e.g. `safe_zones` on `family_id + name`. A candidate
  /// missing any member column is skipped: without a value there is nothing to
  /// collide with, which is also how the database treats a null in a unique index.
  HavenFailure? _compositeViolation(
    String table,
    LocalTableRule rule,
    Map<String, Object?> candidate,
    List<Map<String, Object?>> others,
  ) {
    for (final columns in rule.uniqueComposites) {
      if (columns.any((column) => candidate[column] == null)) continue;
      if (others.any(
        (row) => columns.every((column) => row[column] == candidate[column]),
      )) {
        return BackendFailure(
          'A local $table row with the same ${columns.join(' + ')} already exists.',
          detail: 'local_composite_unique_violation: $table.${columns.join('.')}',
        );
      }
    }
    return null;
  }

  /// A child row must name a parent that exists locally; a null key is a missing
  /// parent, not an unparented row. That is what makes orphans impossible.
  HavenFailure? _referenceViolation(String table, Map<String, Object?> candidate) {
    for (final key in schema.keysOn(table)) {
      final value = candidate[key.column];
      if (value == null) {
        return BackendFailure(
          'A local $table row must name the ${key.parentTable} it belongs to.',
          detail: 'local_fk_missing: $table.${key.column}',
        );
      }
      final parentExists =
          schema.isKnown(key.parentTable) &&
          rowsOf(key.parentTable).any((parent) => parent[key.parentColumn] == value);
      if (!parentExists) {
        return BackendFailure(
          'The ${key.parentTable} this $table row belongs to does not exist locally.',
          detail:
              'local_fk_violation: $table.${key.column} -> '
              '${key.parentTable}.${key.parentColumn}',
        );
      }
    }
    return null;
  }

  /// Refuse a delete of [doomed] rows while registered children still point at
  /// them. Refuse, not cascade — see [LocalSchema].
  HavenFailure? blockedDelete(
    String table,
    List<Map<String, Object?>> doomed,
  ) {
    for (final key in schema.referencesTo(table)) {
      final children = rowsOf(key.childTable);
      final inUse = doomed.any(
        (parent) =>
            parent[key.parentColumn] != null &&
            children.any(
              (child) => child[key.column] == parent[key.parentColumn],
            ),
      );
      if (inUse) {
        return BackendFailure(
          'This still has ${key.childTable} records linked to it, so nothing was deleted.',
          detail: 'local_fk_refused: ${key.childTable}.${key.column}',
        );
      }
    }
    return null;
  }
}
