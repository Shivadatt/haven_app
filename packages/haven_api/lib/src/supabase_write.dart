import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_endpoints.dart';
import 'data_contracts.dart';
import 'failure_mapper.dart';

/// `RowWriter` over the PostgREST row plane.
///
/// Most tables are `service_role`-only under RLS, so a direct client write is
/// expected to be refused; that refusal is reported, not worked around. Filters
/// are equality-only, for the reason stated in `supabase_data.dart`: a wider
/// filter would let a screen ask for rows the policies were never written to
/// scope.
final class SupabaseRowWriter implements RowWriter {
  SupabaseRowWriter(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void>> insert(String table, Map<String, Object?> row) async {
    try {
      TableName.assertKnown(table);
      await _client.from(table).insert(row);
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async {
    try {
      var query = _client.from(table).update(row);
      query = _scope(query, table, eq);
      await query;
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> delete(
    String table, {
    required Map<String, Object?> eq,
  }) async {
    try {
      // An unfiltered delete clears every row the caller can see, so it is
      // refused here instead of being left for the database to allow.
      if (eq.isEmpty) {
        throw ArgumentError.value(eq, 'eq', 'a delete needs a filter');
      }
      var query = _client.from(table).delete();
      await _scope(query, table, eq);
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  /// The same table check and the same equality filter for both write verbs, so
  /// they cannot drift apart.
  PostgrestFilterBuilder<dynamic> _scope(
    PostgrestFilterBuilder<dynamic> query,
    String table,
    Map<String, Object?> eq,
  ) {
    TableName.assertKnown(table);
    var scoped = query;
    for (final MapEntry<String, Object?> entry in eq.entries) {
      final Object? value = entry.value;
      if (value == null) {
        throw ArgumentError.value(
          null,
          entry.key,
          'equality filter needs a value',
        );
      }
      scoped = scoped.eq(entry.key, value);
    }
    return scoped;
  }
}
