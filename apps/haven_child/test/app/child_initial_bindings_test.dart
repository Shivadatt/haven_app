import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/app/bindings/child_initial_bindings.dart';
import 'package:haven_child/core/constants/child_config.dart';
import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/real_device_information.dart';
import 'package:haven_child/core/permissions/permission_status_source.dart';
import 'package:haven_child/core/permissions/unconfigured_permission_status_source.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_database.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/child_storage_paths.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';

import '../support/storage.dart';

/// The startup seam Agent 3 must be able to trust: idempotent register,
/// single shared storage future, and — explicitly — NO caching of a failed
/// open, so the splash retry gets a genuine second attempt.
void main() {
  late String dir;

  setUp(() => dir = StorageTestLane.createTempDirectory());

  tearDown(() {
    ChildStoragePaths.overrideForTests(null);
    ChildInitialBindings.resetForTests();
    StorageTestLane.deleteTemp(dir);
  });

  test('register is idempotent and installs only honest readers', () {
    ChildInitialBindings.register(const ChildConfig());
    ChildInitialBindings.register(const ChildConfig(environment: 'other'));

    expect(Get.find<DeviceInformation>(), isA<RealDeviceInformation>());
    expect(
      Get.find<PermissionStatusSource>(),
      isA<UnconfiguredPermissionStatusSource>(),
    );
    // The second register() call must not have replaced or duplicated them.
    expect(Get.find<ChildConfig>().environment, 'local');
  });

  test('startStorage opens at the override lane and registers every seam', () async {
    ChildStoragePaths.overrideForTests(() async => dir);
    final opened = await ChildInitialBindings.startStorage();
    expect(opened.isOk, isTrue);
    expect(Get.isRegistered<ChildDatabase>(), isTrue);
    expect(Get.isRegistered<ChildProfileRepository>(), isTrue);
    expect(Get.isRegistered<OnboardingStateStore>(), isTrue);
    expect(Get.isRegistered<ChildSessionStore>(), isTrue);
    // And they work: a profile written through the seam lands on disk.
    await Get.find<ChildProfileRepository>().create(
      displayName: 'Ada',
      ageBracket: '8-11',
    );
    expect(
      (await Get.find<ChildProfileRepository>().read()).valueOrNull!.displayName,
      'Ada',
    );
  });

  test('a second startStorage call returns the SAME future, even mid-flight', () async {
    ChildStoragePaths.overrideForTests(() async => dir);
    final first = ChildInitialBindings.startStorage();
    final second = ChildInitialBindings.startStorage();
    expect(identical(first, second), isTrue);
    expect((await first).isOk, isTrue);
  });

  test('a FAILED open is not cached — the retry gets a real second attempt', () async {
    var attempts = 0;
    ChildStoragePaths.overrideForTests(() async {
      attempts++;
      if (attempts == 1) throw StateError('the disk was busy');
      return dir;
    });

    final first = await ChildInitialBindings.startStorage();
    expect(first.isErr, isTrue);
    expect(first.failureOrNull, isA<StorageFailure>());

    final second = await ChildInitialBindings.startStorage();
    expect(second.isOk, isTrue); // genuine re-open, not a cached Err
    expect(attempts, 2);
  });

  test('unregisterStorageSeams drops the lanes; resetForTests reopens them', () async {
    ChildStoragePaths.overrideForTests(() async => dir);
    await ChildInitialBindings.startStorage();
    ChildInitialBindings.unregisterStorageSeams();
    expect(Get.isRegistered<ChildDatabase>(), isFalse);
    expect(Get.isRegistered<ChildProfileRepository>(), isFalse);
    // Documented caching: a SUCCESSFUL open future stays cached, so
    // startStorage alone deliberately does not re-register behind the
    // back of a test that just dropped the lanes.
    await ChildInitialBindings.startStorage();
    expect(Get.isRegistered<ChildDatabase>(), isFalse);
    // The real next-suite path is the full reset, and it does reopen.
    ChildInitialBindings.resetForTests();
    ChildStoragePaths.overrideForTests(() async => dir);
    await ChildInitialBindings.startStorage();
    expect(Get.isRegistered<ChildDatabase>(), isTrue);
    expect(Get.isRegistered<ChildProfileRepository>(), isTrue);
  });

  test('ChildConfig defaults to local-only, mirroring the Stage-1 promise', () {
    expect(const ChildConfig().isLocal, isTrue);
    expect(ChildConfig.fromDefines('').environment, 'local');
    expect(ChildConfig.fromDefines('staging').environment, 'staging');
    expect(ChildConfig.appName, 'Haven Child');
  });
}
