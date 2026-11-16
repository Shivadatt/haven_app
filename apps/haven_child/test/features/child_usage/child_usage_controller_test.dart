import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/bindings/child_usage_bindings.dart';
import 'package:haven_child/features/child_usage/controllers/child_usage_controller.dart';
import 'package:haven_child/features/child_usage/data/child_usage_repository.dart';
import 'package:haven_child/features/child_usage/domain/usage_freshness_status.dart';
import 'package:haven_core/haven_core.dart';

import 'fake_child_usage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeChildUsageRepository repo;
  late ChildUsageController controller;

  setUp(() {
    Get.reset();
    repo = FakeChildUsageRepository();
    controller = ChildUsageController(
      repository: repo,
      registerObserver: false,
    );
  });

  tearDown(() {
    if (!controller.isClosed) controller.onClose();
    Get.reset();
  });

  UsageDailyResult sampleUsage({
    UsageDataFreshness freshness = UsageDataFreshness.recent,
    List<UsageAppRecord> apps = const [
      UsageAppRecord(
        packageName: 'com.test.app',
        totalForegroundMillis: 5000,
        lastTimeUsedMillis: 1000,
        isSystemApp: false,
      ),
    ],
  }) =>
      UsageDailyResult(
        apiLevel: 34,
        startTimeMillis: 1000,
        endTimeMillis: 5000,
        totalForegroundMillis: 5000,
        dataFreshness: freshness,
        apps: apps,
      );

  group('ChildUsageController - Initial & Concurrency', () {
    test('initial state and successful loading sequence', () async {
      expect(controller.status.value, ChildUsageStatus.initial);
      repo.dailyUsageResult = Ok(sampleUsage());
      await controller.loadUsage();
      expect(controller.status.value, ChildUsageStatus.loaded);
      expect(controller.hasData, isTrue);
      expect(controller.appRecords.length, 1);
      expect(controller.totalForegroundDuration.inMilliseconds, 5000);
      expect(controller.freshness.value, UsageFreshnessStatus.recent);
    });

    test('out-of-order async results do not overwrite newer results', () async {
      repo.dailyUsageDelay = const Duration(milliseconds: 50);
      repo.dailyUsageResult = Ok(sampleUsage(apps: const []));
      final first = controller.loadUsage();

      repo.dailyUsageDelay = null;
      repo.dailyUsageResult = Ok(sampleUsage());
      final second = controller.loadUsage();

      await Future.wait([first, second]);
      expect(controller.status.value, ChildUsageStatus.loaded);
      expect(controller.appRecords.length, 1);
    });
  });

  group('ChildUsageController - Permission States', () {
    test('denied and unsupported permission flows', () async {
      repo.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.denied,
        apiLevel: 34,
      ));
      await controller.loadUsage();
      expect(controller.isPermissionRequired, isTrue);
      expect(controller.hasData, isFalse);

      repo.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.unsupported,
        apiLevel: 19,
      ));
      await controller.loadUsage();
      expect(controller.isUnsupported, isTrue);
    });

    test('permission error surfaces failure state', () async {
      repo.permissionResult = const Err(
        BackendFailure('Permission probe failed', code: 'probe_failed'),
      );
      await controller.loadUsage();
      expect(controller.hasError, isTrue);
      expect(controller.failure.value?.message, 'Permission probe failed');
    });
  });

  group('ChildUsageController - Usage & Settings States', () {
    test('empty and delayed usage states', () async {
      repo.dailyUsageResult = Ok(sampleUsage(apps: const []));
      await controller.loadUsage();
      expect(controller.isEmpty, isTrue);

      repo.dailyUsageResult = Ok(sampleUsage(freshness: UsageDataFreshness.delayed));
      await controller.loadUsage();
      expect(controller.isDelayed, isTrue);
      expect(controller.freshness.value, UsageFreshnessStatus.delayed);
    });

    test('query failure clears data and sets error', () async {
      repo.dailyUsageResult = Ok(sampleUsage());
      await controller.loadUsage();
      expect(controller.hasData, isTrue);

      repo.dailyUsageResult = const Err(
        BackendFailure('Read error', code: 'section_failed'),
      );
      await controller.refreshUsage();
      expect(controller.hasError, isTrue);
      expect(controller.hasData, isFalse);
    });

    test('settings launch does not mark permission granted', () async {
      repo.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.denied,
        apiLevel: 34,
      ));
      await controller.loadUsage();
      final res = await controller.openUsageSettings();
      expect(res.isOk, isTrue);
      expect(controller.isPermissionGranted, isFalse);
    });
  });

  group('ChildUsageController - Lifecycle & Revocation', () {
    test('resume triggers refresh and revocation wipes data', () async {
      repo.dailyUsageResult = Ok(sampleUsage());
      await controller.loadUsage();
      expect(controller.hasData, isTrue);

      // User revokes permission in settings and resumes app
      repo.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.denied,
        apiLevel: 34,
      ));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isPermissionRequired, isTrue);
      expect(controller.hasData, isFalse);
      expect(controller.totalForegroundDuration, Duration.zero);
      expect(controller.appRecords, isEmpty);
      expect(controller.freshness.value, isNull);
    });

    test('observer registration and disposal safety', () {
      final obsController = ChildUsageController(repository: repo, registerObserver: true);
      obsController.onInit();
      obsController.onClose();
      expect(obsController.isDisposed, isTrue);
      expect(obsController.dailyUsage.value, isNull);
    });
  });

  group('ChildUsageController - Bindings & Privacy', () {
    test('ChildUsageBindings registers repository and controller', () {
      ChildUsageBindings(repository: repo).dependencies();
      expect(Get.isRegistered<ChildUsageRepository>(), isTrue);
      expect(Get.isRegistered<ChildUsageController>(), isTrue);
    });

    test('strict transient in-memory privacy verification', () {
      final ctrlSrc = File('lib/features/child_usage/controllers/child_usage_controller.dart')
          .readAsStringSync();
      expect(ctrlSrc.contains('haven_local.json') || ctrlSrc.contains('sqflite'), isFalse);
      expect(ctrlSrc.contains('MethodChannel('), isFalse);
    });
  });
}
