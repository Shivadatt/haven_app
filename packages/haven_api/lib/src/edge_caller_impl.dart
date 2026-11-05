import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show asMap, asText;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_endpoints.dart';
import 'data_contracts.dart';
import 'failure_mapper.dart';

/// `EdgeCaller` over Supabase Edge Functions.
///
/// Only the nine slugs captured on 2026-10-30 may be invoked; `invoke` rejects
/// anything else locally so a typo can never look like a new backend contract.
/// Replies use the `{data, error, request_id}` envelope the readable functions
/// emit, but the envelope is *parsed*, never *assumed*: a missing `data` key is
/// reported as an unexpected payload.
final class SupabaseEdgeCaller implements EdgeCaller {
  SupabaseEdgeCaller(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<EdgeReply>> invoke(
    String slug,
    Map<String, Object?> body, {
    Map<String, String> deviceHeaders = const {},
  }) async {
    EdgeFunctionName.assertKnown(slug);
    try {
      final response = await _client.functions.invoke(
        slug,
        headers: deviceHeaders,
        body: body,
      );
      return Ok(_reply(response));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  EdgeReply _reply(FunctionResponse response) {
    final json = asMap(response.data);
    final status = response.status;
    final Object? error = json['error'];
    final String? described = error is Map
        ? asText(asMap(error)['code'])
        : asText(error);
    return EdgeReply(
      status: status,
      body: json,
      errorCode: status == 200 ? null : (described ?? 'HTTP $status'),
    );
  }
}

/// Reads the reply envelope into a typed payload.
///
/// The top-level key names of the nine deployed functions were **never
/// captured** — `docs/stage2/functions/_shared/envelope.ts:22-27` records that
/// `{ok:true, ...fields}` is the re-authored choice and `error.code` /
/// `error.message` are the only verified paths. So this accepts either marker a
/// function is known to answer with, and an answer carrying neither is reported
/// as unreadable rather than being guessed at.
///
/// NOT VERIFIED against staging: no feature may claim an end-to-end Edge result
/// from this path while the schema load and function deployments are unsigned.
Result<Map<String, Object?>> dataFrom(Result<EdgeReply> reply) =>
    reply.map(_payloadFrom, (failure) => Err<Map<String, Object?>>(failure));

Result<Map<String, Object?>> _payloadFrom(EdgeReply reply) {
  final Object? error = reply.body['error'];
  if (!reply.isSuccess || reply.body['ok'] == false) {
    return Err<Map<String, Object?>>(
      BackendFailure(
        error is Map
            ? (asText(asMap(error)['message']) ??
                  'The service refused that request.')
            : (asText(error) ?? 'The service refused that request.'),
        code: reply.errorCode,
      ),
    );
  }

  final Object? nested = reply.body['data'];
  if (nested is Map) return Ok<Map<String, Object?>>(asMap(nested));
  if (reply.body['ok'] == true) {
    return Ok<Map<String, Object?>>(
      Map<String, Object?>.from(reply.body)..remove('ok'),
    );
  }
  return Err<Map<String, Object?>>(
    BackendFailure(
      'The service reported success without any data.',
      detail: 'keys: ${reply.body.keys.join(',')}',
    ),
  );
}
