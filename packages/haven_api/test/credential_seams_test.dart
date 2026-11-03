import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A vault the platform keystore is unavailable, i.e. every write must fail
/// rather than fall back to plaintext.
final class _NoVault implements SecretVault {
  _NoVault({this.store = false});

  final bool store;
  final Map<String, String> written = {};

  @override
  bool get available => store;

  @override
  Future<String?> read(String key) async => written[key];

  @override
  Future<bool> write(String key, String value) async {
    written[key] = value;
    return store;
  }

  @override
  Future<void> delete(String key) async => written.remove(key);
}

void main() {
  group('device credential lane', () {
    test('refuses to issue when the vault cannot protect the secret', () async {
      final vault = _NoVault();
      final identity = VaultDeviceIdentity(vault);
      final result = await identity.issue(
        const DeviceCredential(
          deviceId: 'd1',
          secret: 'super-secret',
          storedSecurely: true,
        ),
      );
      expect(result, isA<Err<DeviceCredential>>());
      expect(
        vault.written,
        isEmpty,
        reason: 'no plaintext may survive a failed vault',
      );
    });

    test(
      'round-trips through an available vault and clears on demand',
      () async {
        final vault = _NoVault(store: true);
        final identity = VaultDeviceIdentity(vault);
        await identity.issue(
          const DeviceCredential(
            deviceId: 'd1',
            secret: 's',
            storedSecurely: true,
          ),
        );
        expect(vault.written.values.single, contains('device_id'));
        final read = await identity.credential();
        expect(read.valueOrNull?.deviceId, 'd1');
        await identity.clear();
        expect((await identity.credential()).valueOrNull, isNull);
      },
    );

    test('a corrupt payload is deleted and reported as unpaired', () async {
      final vault = _NoVault(store: true);
      vault.written['haven.device.credential'] = 'not json';
      final read = await VaultDeviceIdentity(vault).credential();
      expect(
        read.isOk,
        isTrue,
        reason: 'a junk payload means unpaired, not broken',
      );
      expect(read.valueOrNull, isNull);
      expect(vault.written, isEmpty);
    });
  });

  group('unconfigured seams', () {
    test('every call refuses instead of inventing a row', () async {
      const backend = UnconfiguredBackend('no --dart-define values');
      expect((await backend.rows(TableName.devices)).isErr, isTrue);
      expect((await backend.call(RpcName.unlinkChild, {})).isErr, isTrue);
      expect(
        (await backend.invoke(EdgeFunctionName.pairing, {})).isErr,
        isTrue,
      );
      expect((await backend.familySnapshot('f1')).isErr, isTrue);
      expect((await backend.deviceSnapshot('d1')).isErr, isTrue);
      expect((await backend.count(TableName.families)).isErr, isTrue);
      expect(
        (await const UnconfiguredChangeFeed()
            .changes(table: TableName.devices)
            .isEmpty),
        isTrue,
      );
    });

    test(
      'the Firebase bridge is blocked, not silently proxied to passwords',
      () async {
        const auth = UnconfiguredUserAuth('A13 unsigned');
        expect(isBlocked(await auth.signInWithFirebaseToken('token')), isTrue);
        expect(
          (await auth.signInWithPassword(email: 'a@b.c', password: 'x')).isErr,
          isTrue,
        );
      },
    );

    test(
      'install with no endpoints registers the unconfigured clients',
      () async {
        final handle = await HavenBackend.install(
          endpoints: BackendEndpoints.unconfigured,
        );
        addTearDown(Get.reset);
        expect(handle.status.readiness, BackendReadiness.notConfigured);
        expect(HavenBackend.rows, isA<UnconfiguredBackend>());
        expect(HavenBackend.auth, isA<UnconfiguredUserAuth>());
        expect(HavenBackend.edge, isA<EdgeCallerUnavailable>());
        expect(HavenBackend.push, isA<UnconfiguredPushTransport>());
        expect(HavenBackend.identity, isA<VaultDeviceIdentity>());
      },
    );
  });

  group('realtime feed', () {
    test('rejects a table the baseline does not publish', () {
      final feed = SupabaseChangeFeed(
        SupabaseClient('https://example.supabase.co', 'key'),
      );
      expect(
        () => feed.changes(table: TableName.profiles),
        throwsA(isA<ArgumentError>()),
      );
      expect(SupabaseChangeFeed.subscribedTables.length, 4);
      feed.dispose();
    });
  });
}
