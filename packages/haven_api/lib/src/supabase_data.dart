import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show asList, asMap;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_endpoints.dart';
import 'data_contracts.dart';
import 'failure_mapper.dart';

/// PostgREST read/write and RPC callers.
///
/// Filters are equality-only: everything the app scopes is a family id or a
/// device id, and a richer filter language would let a screen ask for rows the
/// RLS policies were not written to scope. A `null` filter value is refused
/// rather than dropped, because dropping it would silently widen the result set.
PostgrestFilterBuilder<List<Map<String, dynamic>>> _filtered(
  SupabaseClient client,
  String table,
  Map<String, Object?> eq,
) {
  TableName.assertKnown(table);
  var query = client.from(table).select();
  for (final entry in eq.entries) {
    final value = entry.value;
    if (value == null) {
      throw ArgumentError.value(
        null,
        entry.key,
        'equality filter needs a value',
      );
    }
    query = query.eq(entry.key, value);
  }
  return query;
}

final class SupabaseRowReader implements RowReader {
  SupabaseRowReader(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) async {
    try {
      final query = _filtered(_client, table, eq);
      final data = limit != null
          ? (orderDesc != null
                ? await query.order(orderDesc, ascending: false).limit(limit)
                : await query.limit(limit))
          : (orderDesc != null
                ? await query.order(orderDesc, ascending: false)
                : await query);
      return Ok(List<Map<String, Object?>>.from(data));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) async {
    final result = await rows(table, eq: eq, orderDesc: orderDesc, limit: 1);
    return result.map((rows) => Ok(rows.isEmpty ? null : rows.first), Err.new);
  }

  @override
  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) async {
    try {
      final query = _filtered(_client, table, eq).limit(0);
      final response = await query.count(CountOption.exact);
      return Ok(response.count);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }
}

/// `RowWriter`. Most tables are `service_role`-only under RLS, so a direct client
/// write is expected to be refused; that refusal is reported, not worked around.
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
      TableName.assertKnown(table);
      var query = _client.from(table).update(row);
      for (final entry in eq.entries) {
        final value = entry.value;
        if (value == null) {
          throw ArgumentError.value(
            null,
            entry.key,
            'equality filter needs a value',
          );
        }
        query = query.eq(entry.key, value);
      }
      await query;
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }
}

/// `RpcCaller` over the 14 definer functions.
///
/// **Return shapes are NOT VERIFIED**: `g1-q7-20261029.json` captured arguments,
/// language, definer flag, settings and ACL but no return type, so the payload
/// stays `Object?` and callers validate what they get. Those functions' ACL is
/// `postgres=X, service_role=X` — `authenticated` has no EXECUTE — so a direct
/// client call is expected to be refused, and the refusal says why.
final class SupabaseRpcCaller implements RpcCaller {
  SupabaseRpcCaller(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<Object?>> call(String name, Map<String, Object?> params) async {
    RpcName.assertKnown(name);
    try {
      final data = await _client.rpc(name, params: params);
      return Ok(data);
    } on PostgrestException catch (error) {
      final failure = mapPostgrest(error);
      if (failure is PermissionFailure) {
        return Err(
          PermissionFailure(
            failure.message,
            detail:
                '${failure.detail ?? ''} '
                "This function's captured ACL grants EXECUTE to service_role only, "
                'so it must be reached through an Edge Function.',
          ),
        );
      }
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }
}

/// Decodes the `{data, error, request_id}` envelope the readable functions emit.
Map<String, Object?> envelopeData(Map<String, Object?> body) =>
    asMap(body['data']);

String? envelopeError(Map<String, Object?> body) =>
    body['error'] is String ? body['error'] as String : null;

List<Object?> envelopeList(Map<String, Object?> body) => asList(body['data']);
