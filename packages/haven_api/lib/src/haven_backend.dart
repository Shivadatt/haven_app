import 'package:get/get.dart';
import 'package:haven_offline/haven_offline.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_contracts.dart';
import 'backend_endpoints.dart';
import 'backend_status.dart';
import 'change_feed_impl.dart';
import 'data_contracts.dart';
import 'device_identity_impl.dart';
import 'edge_caller_impl.dart';
import 'offline_backends.dart';
import 'push_transport_impl.dart';
import 'supabase_data.dart';
import 'supabase_write.dart';
import 'supabase_profile_store.dart';
import 'supabase_user_auth.dart';

/// The single place that decides whether the app can talk to a backend.
///
/// When the endpoints are absent — the state of this repository while `A2′(a)`,
/// `A3`, `A12-R` and `A13` are unsigned — every seam resolves to an
/// `Unconfigured*` client, so screens render an honest "not connected" state
/// instead of inventing data. Registering happens once, at startup.
final class HavenBackend {
  const HavenBackend._();

  static const _reason = 'no staging endpoints supplied at build time';

  static Future<HavenBackendHandle> install({
    required BackendEndpoints endpoints,
    SecretVault? secretVault,
    Future<void> Function(BackendEndpoints)? firebaseInit,
  }) async {
    if (endpoints.hasSupabase) {
      await Supabase.initialize(
        url: endpoints.supabaseUrl,
        publishableKey: endpoints.supabaseAnonKey,
      );
    }
    if (endpoints.hasFirebase && firebaseInit != null) {
      await firebaseInit(endpoints);
    }

    final status = BackendStatus.of(endpoints);
    final client = status.canLoadData ? Supabase.instance.client : null;

    Get
      ..put<RowReader>(
        client == null
            ? const UnconfiguredBackend(_reason)
            : SupabaseRowReader(client),
      )
      ..put<RowWriter>(
        client == null
            ? const UnconfiguredBackend(_reason)
            : SupabaseRowWriter(client),
      )
      ..put<RpcCaller>(
        client == null
            ? const UnconfiguredBackend(_reason)
            : SupabaseRpcCaller(client),
      )
      ..put<EdgeCaller>(
        client == null ? EdgeCallerUnavailable() : SupabaseEdgeCaller(client),
      )
      ..put<ChangeFeed>(
        client == null
            ? const UnconfiguredChangeFeed()
            : SupabaseChangeFeed(client),
      )
      ..put<UserAuth>(
        client == null
            ? const UnconfiguredUserAuth(_reason)
            : SupabaseUserAuth(client),
      )
      ..put<ProfileStore>(
        client == null
            ? const UnconfiguredProfileStore(_reason)
            : SupabaseProfileStore(client),
      )
      ..put<PushTransport>(
        endpoints.hasFirebase
            ? FirebasePushTransport()
            : const UnconfiguredPushTransport(_reason),
      )
      ..put<DeviceIdentity>(
        VaultDeviceIdentity(secretVault ?? _UnavailableVault()),
      );

    return HavenBackendHandle(status);
  }

  /// Read-backs for feature bindings; each falls back so no screen can crash on
  /// a missing registration.
  static RowReader get rows => Get.isRegistered<RowReader>()
      ? Get.find<RowReader>()
      : const UnconfiguredBackend(_reason);
  static RowWriter get writer => Get.isRegistered<RowWriter>()
      ? Get.find<RowWriter>()
      : const UnconfiguredBackend(_reason);
  static RpcCaller get rpc => Get.isRegistered<RpcCaller>()
      ? Get.find<RpcCaller>()
      : const UnconfiguredBackend(_reason);
  static EdgeCaller get edge => Get.isRegistered<EdgeCaller>()
      ? Get.find<EdgeCaller>()
      : EdgeCallerUnavailable();
  static UserAuth get auth => Get.isRegistered<UserAuth>()
      ? Get.find<UserAuth>()
      : const UnconfiguredUserAuth(_reason);
  static ProfileStore get profiles => Get.isRegistered<ProfileStore>()
      ? Get.find<ProfileStore>()
      : const UnconfiguredProfileStore(_reason);
  static PushTransport get push => Get.isRegistered<PushTransport>()
      ? Get.find<PushTransport>()
      : const UnconfiguredPushTransport(_reason);
  static ChangeFeed get feed => Get.isRegistered<ChangeFeed>()
      ? Get.find<ChangeFeed>()
      : const UnconfiguredChangeFeed();
  static DeviceIdentity get identity => Get.isRegistered<DeviceIdentity>()
      ? Get.find<DeviceIdentity>()
      : VaultDeviceIdentity(_UnavailableVault());
}

final class _UnavailableVault implements SecretVault {
  @override
  bool get available => false;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<bool> write(String key, String value) async => false;

  @override
  Future<void> delete(String key) async {}
}
