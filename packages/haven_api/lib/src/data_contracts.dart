import 'package:haven_core/haven_core.dart';

/// Data-plane seams. Implemented in `haven_api` over `supabase_flutter`; consumed by
/// feature repositories so that no widget or controller ever imports an SDK.

/// Reads rows from one of the 19 captured tables (`TableName`).
abstract interface class RowReader {
  /// Rows where every `eq` pair matches, newest-first on `orderDesc`, capped by `limit`.
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  });

  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  });

  /// Count of matching rows. Only where a screen genuinely needs a number, so
  /// that statistics are never fabricated from a partial page.
  Future<Result<int>> count(String table, {Map<String, Object?> eq = const {}});
}

/// Writes rows. Availability follows the approved RLS posture: most tables are
/// `service_role`-only, so writes normally go through [RpcCaller] or [EdgeCaller].
abstract interface class RowWriter {
  Future<Result<void>> insert(String table, Map<String, Object?> row);
  Future<Result<void>> update(String table, Map<String, Object?> row, {required Map<String, Object?> eq});
}

/// Calls a definer function captured in `g1-q7-20261029.json` (`RpcName`).
///
/// The capture has **no return types**, so the payload stays `Object?` and the
/// caller validates it. A caller that cannot proceed without a known shape must
/// mark the call `NOT VERIFIED — RETURN SHAPE UNCAPPED` in its own layer.
abstract interface class RpcCaller {
  Future<Result<Object?>> call(String name, Map<String, Object?> params);
}

/// Reply from an Edge Function (`EdgeFunctionName`).
final class EdgeReply {
  const EdgeReply({required this.status, required this.body, this.errorCode});

  final int status;
  final Map<String, Object?> body;
  final String? errorCode;

  bool get isSuccess => status >= 200 && status < 300;
}

/// Calls one of the nine captured Edge Function slugs.
///
/// [deviceHeaders] carries the separate device-credential lane (`x-device-id`,
/// `x-device-secret`); it is never mixed with a user bearer token.
abstract interface class EdgeCaller {
  Future<Result<EdgeReply>> invoke(
    String slug,
    Map<String, Object?> body, {
    Map<String, String> deviceHeaders = const {},
  });
}

/// Change notifications for the four Realtime-enabled tables.
abstract interface class ChangeFeed {
  /// Emits the full re-read of [query] whenever a relevant row changes.
  /// A missed event is recoverable by re-reading, per `docs/stage1/02-architecture.md:23`.
  Stream<void> changes({
    required String table,
    Map<String, Object?> eq = const {},
  });
}

/// Read-only composite used by dashboards: one call per screen section.
abstract interface class SnapshotSource {
  Future<Result<List<Map<String, Object?>>>> familySnapshot(String familyId);
  Future<Result<List<Map<String, Object?>>>> deviceSnapshot(String deviceId);
}
