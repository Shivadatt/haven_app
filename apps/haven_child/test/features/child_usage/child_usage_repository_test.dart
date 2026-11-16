import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/data/child_usage_repository.dart';
import 'package:haven_child/features/child_usage/domain/usage_freshness_status.dart';
import 'package:haven_core/haven_core.dart';

import 'fake_usage_channel.dart';

void main() {
  late FakeUsageChannel fakeChannel;
  late ChildUsageRepositoryImpl repository;

  setUp(() {
    fakeChannel = FakeUsageChannel();
    repository = ChildUsageRepositoryImpl(usageChannel: fakeChannel);
  });

  group('ChildUsageRepository - Permission Tests', () {
    test('reports granted permission correctly', () async {
      fakeChannel.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.granted,
        apiLevel: 34,
      ));
      final res = await repository.getPermissionStatus();
      expect(res.isOk && res.valueOrNull!.isGranted, isTrue);
      expect(fakeChannel.getPermissionCalls, 1);
    });

    test('reports denied and unsupported permission status', () async {
      fakeChannel.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.denied,
        apiLevel: 34,
      ));
      final denied = await repository.getPermissionStatus();
      expect(denied.isOk && !denied.valueOrNull!.isGranted, isTrue);

      fakeChannel.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.unsupported,
        apiLevel: 19,
      ));
      final unsupp = await repository.getPermissionStatus();
      expect(unsupp.valueOrNull?.status, UsagePermissionStatus.unsupported);
    });

    test('maps channel errors and exceptions safely', () async {
      fakeChannel.permissionResult =
          const Err(BackendFailure('Query failed', code: 'permission_failed'));
      expect((await repository.getPermissionStatus()).failureOrNull,
          isA<BackendFailure>());

      fakeChannel.throwOnPermission = true;
      expect((await repository.getPermissionStatus()).failureOrNull,
          isA<UnknownFailure>());
    });
  });

  group('ChildUsageRepository - Settings Navigation Tests', () {
    test('reports package and generic fallback settings launch', () async {
      fakeChannel.settingsResult = const Ok(UsageSettingsLaunchResult(
        intentLaunched: true,
        openedPackageSettings: true,
        apiLevel: 34,
      ));
      final pkg = await repository.openUsageSettings();
      expect(pkg.valueOrNull?.openedPackageSettings, isTrue);

      fakeChannel.settingsResult = const Ok(UsageSettingsLaunchResult(
        intentLaunched: true,
        openedPackageSettings: false,
        apiLevel: 34,
      ));
      final generic = await repository.openSettings();
      expect(generic.valueOrNull?.openedPackageSettings, isFalse);
    });

    test('opening settings does not imply permission is granted', () async {
      fakeChannel.permissionResult = const Ok(UsagePermissionResult(
        status: UsagePermissionStatus.denied,
        apiLevel: 34,
      ));
      await repository.openUsageSettings();
      final perm = await repository.getPermissionStatus();
      expect(perm.valueOrNull?.isGranted, isFalse);
    });

    test('settings launch failure and crash handling', () async {
      fakeChannel.settingsResult =
          const Err(BackendFailure('Failed', code: 'launch_failed'));
      expect((await repository.openUsageSettings()).isErr, isTrue);

      fakeChannel.throwOnSettings = true;
      expect((await repository.openUsageSettings()).failureOrNull,
          isA<UnknownFailure>());
    });
  });

  group('ChildUsageRepository - Daily Usage & Error Tests', () {
    test('forwards query parameters and maps summary and apps', () async {
      fakeChannel.dailyUsageResult = const Ok(UsageDailyResult(
        apiLevel: 34,
        startTimeMillis: 1000,
        endTimeMillis: 5000,
        totalForegroundMillis: 3000,
        dataFreshness: UsageDataFreshness.recent,
        apps: <UsageAppRecord>[
          UsageAppRecord(
            packageName: 'com.test.app',
            totalForegroundMillis: 3000,
            lastTimeUsedMillis: 4500,
            isSystemApp: false,
          ),
        ],
      ));

      final res = await repository.getDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: 5000,
      );
      expect(res.isOk, isTrue);
      final data = res.valueOrNull!;
      expect(data.totalForegroundMillis, 3000);
      expect(data.apps.first.packageName, 'com.test.app');
      expect(data.apps.first.lastTimeUsedMillis, 4500);
      expect(fakeChannel.lastQueryStart, 1000);
      expect(fakeChannel.lastQueryEnd, 5000);
    });

    test('handles empty results and all freshness states', () async {
      for (final freshness in UsageDataFreshness.values) {
        fakeChannel.dailyUsageResult = Ok(UsageDailyResult(
          apiLevel: 34,
          startTimeMillis: 100,
          endTimeMillis: 200,
          totalForegroundMillis: 0,
          dataFreshness: freshness,
          apps: const [],
        ));
        final res = await repository.queryDailyUsage(
          startTimeMillis: 100,
          endTimeMillis: 200,
        );
        expect(res.valueOrNull?.dataFreshness, freshness);
      }
    });

    test('rejects invalid range and maps errors', () async {
      final bad = await repository.getDailyUsage(startTimeMillis: 500, endTimeMillis: 100);
      expect(bad.failureOrNull, isA<ValidationFailure>());

      fakeChannel.dailyUsageResult = const Err(
        DevicePermissionFailure('Denied', detail: 'permission_denied'),
      );
      final denied = await repository.getDailyUsage(startTimeMillis: 100, endTimeMillis: 200);
      expect(denied.failureOrNull, isA<DevicePermissionFailure>());

      fakeChannel.throwOnQuery = true;
      final crash = await repository.getDailyUsage(startTimeMillis: 100, endTimeMillis: 200);
      expect(crash.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('ChildUsage - Domain Freshness & Architecture Tests', () {
    test('converts correctly between enum, wire tokens and models', () {
      expect(UsageFreshnessStatus.fromDataFreshness(UsageDataFreshness.recent),
          UsageFreshnessStatus.recent);
      expect(UsageFreshnessStatus.fromDataFreshness(null), isNull);
      expect(UsageFreshnessStatus.parse('recent'), UsageFreshnessStatus.recent);
      expect(UsageFreshnessStatus.parse('unknown'), isNull);
      expect(UsageFreshnessStatus.recent.wireToken, 'recent');
      expect(UsageFreshnessStatus.delayed.toDataFreshness(),
          UsageDataFreshness.delayed);
    });

    test('enforces architectural decoupling and privacy rules', () {
      final repo = File('lib/features/child_usage/data/child_usage_repository.dart').readAsStringSync();
      final dom = File('lib/features/child_usage/domain/usage_freshness_status.dart').readAsStringSync();
      expect(repo.contains('package:get/'), isFalse);
      expect(repo.contains('MethodChannel('), isFalse);
      expect(repo.contains('haven_local.json') || repo.contains('sqflite'), isFalse);
      expect(dom.contains('widgets.dart') || dom.contains('MethodChannel'), isFalse);
    });
  });
}
