import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../auth_contracts.dart';
import '../backend_status.dart';
import '../data_contracts.dart';
import '../device_identity_impl.dart';
import '../haven_backend.dart' show HavenBackendHandle, EdgeCallerUnavailable;
import '../offline_backends.dart';
import 'local_change_feed.dart';
import 'local_store.dart';
import 'local_tables.dart';
import 'local_profile_store.dart';
import 'local_user_auth.dart';

/// Reads answer from the local tables, typed exactly like the online reader.
final class LocalRowReader implements RowReader {
  const LocalRowReader(this._tables);

  final LocalTables _tables;

  @override
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) => _tables.rows(table, eq: eq, orderDesc: orderDesc, limit: limit);

  @override
  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) => _tables.first(table, eq: eq, orderDesc: orderDesc);

  @override
  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) => _tables.count(table, eq: eq);
}

/// Writes land in the local tables, and a successful write publishes the change
/// hint [LocalChangeFeed] promises. The hint carries the filter or the inserted
/// row — payloads are hints by contract, and consumers re-read.
final class LocalRowWriter implements RowWriter {
  const LocalRowWriter(this._tables, this._feed);

  final LocalTables _tables;
  final LocalChangeFeed _feed;

  @override
  Future<Result<void>> insert(String table, Map<String, Object?> row) async {
    final done = await _tables.insert(table, row);
    if (done.isOk) _feed.publish(table, row);
    return done;
  }

  @override
  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async {
    final done = await _tables.update(table, row, eq: eq);
    if (done.isOk) _feed.publish(table, eq);
    return done;
  }

  @override
  Future<Result<void>> delete(
    String table, {
    required Map<String, Object?> eq,
  }) async {
    final done = await _tables.delete(table, eq: eq);
    if (done.isOk) _feed.publish(table, eq);
    return done;
  }
}

/// The offline engine: the same seams the app reads and writes through, served
/// entirely from this device.
///
/// `HAVEN_OFFLINE_MODE=true` routes startup here instead of [HavenBackend.install],
/// and nothing in this path touches Supabase or Firebase. Cloud-only surfaces
/// keep the honest `Unconfigured*` refusals rather than pretending: an offline
/// build says "not connected" for RPC, Edge and push, and never a fake success.
/// The cloud registrations themselves are untouched, so a later backend phase
/// flips the flag and finds the old path exactly as it was.
final class OfflineHavenBackend {
  const OfflineHavenBackend._();

  static const String reason = 'offline mode: data is local to this device';

  /// Registers every seam into Get, mirroring `HavenBackend.install`, and hands
  /// back the same handle shape. A damaged local document is *not* repaired
  /// here: it surfaces as a typed failure on every read, which is what keeps
  /// "we could not read your data" from ever being reported as "no data".
  static Future<HavenBackendHandle> installLocal({
    required LocalStore store,
    required SecretVault secretVault,
  }) async {
    final tables = LocalTables(store);
    await tables.open();
    final feed = LocalChangeFeed();
    Get
      ..put<LocalTables>(tables)
      ..put<RowReader>(LocalRowReader(tables))
      ..put<RowWriter>(LocalRowWriter(tables, feed))
      ..put<RpcCaller>(const UnconfiguredBackend(reason))
      ..put<EdgeCaller>(EdgeCallerUnavailable())
      ..put<ChangeFeed>(feed)
      ..put<UserAuth>(LocalUserAuth(tables, secretVault))
      ..put<ProfileStore>(LocalProfileStore(tables))
      ..put<PushTransport>(const UnconfiguredPushTransport(reason))
      ..put<DeviceIdentity>(VaultDeviceIdentity(secretVault));
    return const HavenBackendHandle(
      BackendStatus(
        BackendReadiness.notConfigured,
        detail: 'offline mode — all data is on this device',
      ),
    );
  }

  /// True once the offline engine owns the seams. Screens that must not lie
  /// about connectivity read this instead of guessing from a missing session.
  static bool get isActive => Get.isRegistered<LocalTables>();
}
