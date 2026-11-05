import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/bindings/initial_bindings.dart';
import 'package:haven_app/core/constants/haven_config.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../support/fakes.dart';

/// Offline mode selection: a build with `offlineMode` must land on the local
/// engine, must answer through the real seams, and must refuse cloud surfaces
/// honestly. The reader returning an Ok for a locally inserted row is itself
/// the proof it is not the `Unconfigured*` refusal object.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('haven_offline_routing');
    InitialBindings.resetForTests();
    Get.put<HavenConfig>(
      const HavenConfig(
        endpoints: BackendEndpoints.unconfigured,
        offlineMode: true,
      ),
      permanent: true,
    );
    Get.put<SecretVault>(FakeVault(), permanent: true);
    Get.put<PreferencesStore>(FakePreferencesStore(), permanent: true);
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
    InitialBindings.resetForTests();
  });

  group('offline mode routing', () {
    test('startBackend installs the local engine into the seams', () async {
      final handle = await InitialBindings.startBackend(
        offlineDirectory: dir.path,
      );
      expect(handle.status.detail, contains('offline mode'));
      expect(OfflineHavenBackend.isActive, isTrue);
      expect(Get.find<RowReader>(), isA<LocalRowReader>());
      expect(Get.find<UserAuth>(), isA<LocalUserAuth>());
    });

    test('insert then read round-trips through the registered seams', () async {
      await InitialBindings.startBackend(offlineDirectory: dir.path);
      final writer = Get.find<RowWriter>();
      final inserted = await writer.insert(TableName.families, <String, Object?>{
        'id': 'fam_offline',
        'name': 'Offline family',
      });
      expect(inserted.isOk, isTrue, reason: 'the seam is a live store');
      final rows = await Get.find<RowReader>().rows(
        TableName.families,
        eq: {'id': 'fam_offline'},
      );
      expect(rows.valueOrNull!.single['name'], 'Offline family');
    });

    test('data written in one startup is there on the next', () async {
      await InitialBindings.startBackend(offlineDirectory: dir.path);
      await Get.find<RowWriter>().insert(TableName.families, <String, Object?>{
        'id': 'fam_restart',
        'name': 'Kept',
      });
      InitialBindings.resetForTests();
      Get.put<HavenConfig>(
        const HavenConfig(
          endpoints: BackendEndpoints.unconfigured,
          offlineMode: true,
        ),
        permanent: true,
      );
      Get.put<SecretVault>(FakeVault(), permanent: true);
      Get.put<PreferencesStore>(FakePreferencesStore(), permanent: true);
      await InitialBindings.startBackend(offlineDirectory: dir.path);
      final rows = await Get.find<RowReader>().rows(
        TableName.families,
        eq: {'id': 'fam_restart'},
      );
      expect(rows.valueOrNull!.length, 1, reason: 'survives a simulated restart');
    });

    test('cloud surfaces stay typed refusals in offline mode', () async {
      await InitialBindings.startBackend(offlineDirectory: dir.path);
      final rpc = await Get.find<RpcCaller>().call(RpcName.createFamilyWithOwner, {});
      expect(rpc.isErr, isTrue);
      expect(rpc.failureOrNull, isA<NetworkFailure>());
      expect(Get.find<PushTransport>(), isA<UnconfiguredPushTransport>());
      expect(Get.find<EdgeCaller>(), isA<EdgeCallerUnavailable>());
    });

    test('offline config reports nothing missing: defines are not wanted', () {
      const config = HavenConfig(
        endpoints: BackendEndpoints.unconfigured,
        offlineMode: true,
      );
      expect(config.missingDefines(), isEmpty);
      expect(
        const HavenConfig(endpoints: BackendEndpoints.unconfigured)
            .missingDefines()
            .length,
        5,
        reason: 'the cloud posture is unchanged',
      );
    });
  });
}
