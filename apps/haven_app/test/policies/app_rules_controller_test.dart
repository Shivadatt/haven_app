import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/app_rules_controller.dart';
import 'package:haven_app/features/policies/data/app_catalogue.dart';

import '../child_devices/fakes.dart';
import 'fakes.dart';

void main() {
  group('AppRulesController', () {
    late FakePoliciesRepository policiesRepo;
    late FakeDevicesRepository devicesRepo;
    late AppRulesController controller;

    setUp(() {
      policiesRepo = FakePoliciesRepository(canConfigure: true);
      devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      controller = AppRulesController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      controller.onInit();
    });

    test('initializes with allowed and blocked apps', () async {
      await pumpEventQueue();
      expect(controller.isLoading.value, isFalse);
      expect(controller.config.value.blockedApps.contains('com.zhiliaoapp.musically'), isTrue);
      expect(controller.config.value.allowedApps.contains('com.android.calculator2'), isTrue);
    });

    test('switches tabs and filters apps accordingly', () async {
      await pumpEventQueue();
      controller.switchTab(1); // Blocked
      expect(controller.activeTabIndex.value, 1);
      expect(controller.currentList, controller.config.value.blockedApps);

      controller.switchTab(0); // Allowed
      expect(controller.activeTabIndex.value, 0);
      expect(controller.currentList, controller.config.value.allowedApps);
    });

    test('prevents duplicates when switching status from allowed to blocked', () async {
      await pumpEventQueue();
      const pkg = 'com.android.calculator2';
      expect(controller.config.value.allowedApps.contains(pkg), isTrue);

      await controller.setAppRule(pkg, isBlocked: true);
      expect(controller.config.value.blockedApps.contains(pkg), isTrue);
      expect(controller.config.value.allowedApps.contains(pkg), isFalse);
    });

    test('toggles app status with toggleAppStatus', () async {
      await pumpEventQueue();
      const pkg = 'com.instagram.android';
      expect(controller.config.value.blockedApps.contains(pkg), isTrue);

      await controller.toggleAppStatus(pkg);
      expect(controller.config.value.allowedApps.contains(pkg), isTrue);
      expect(controller.config.value.blockedApps.contains(pkg), isFalse);
    });

    test('removes app rule completely', () async {
      await pumpEventQueue();
      const pkg = 'com.instagram.android';
      await controller.removeAppRule(pkg);
      expect(controller.config.value.blockedApps.contains(pkg), isFalse);
      expect(controller.config.value.allowedApps.contains(pkg), isFalse);
    });

    test('validates package name before adding rule', () async {
      await pumpEventQueue();
      final ok = await controller.setAppRule('not_valid_pkg', isBlocked: true);
      expect(ok, isFalse);
      expect(controller.errorMessage.value, contains('valid package name'));
    });

    test('filters list by category and search', () async {
      await pumpEventQueue();
      controller.switchTab(1); // Blocked
      controller.setCategory(AppCategory.social);
      controller.setSearchQuery('insta');

      final items = controller.filteredApps;
      expect(items.length, 1);
      expect(items.first.name, 'Instagram');
    });
  });
}
