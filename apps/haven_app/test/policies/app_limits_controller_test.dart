import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/app_limits_controller.dart';
import 'package:haven_app/features/policies/data/app_catalogue.dart';

import '../child_devices/fakes.dart';
import 'fakes.dart';

void main() {
  group('AppLimitsController', () {
    late FakePoliciesRepository policiesRepo;
    late FakeDevicesRepository devicesRepo;
    late AppLimitsController controller;

    setUp(() {
      policiesRepo = FakePoliciesRepository(canConfigure: true);
      devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      controller = AppLimitsController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      controller.onInit();
    });

    test('initializes and loads limits and devices', () async {
      await pumpEventQueue();
      expect(controller.isLoading.value, isFalse);
      expect(controller.devices.length, 1);
      expect(controller.selectedDeviceId.value, 'd1');
      expect(controller.hasLimit('com.google.android.youtube'), isTrue);
      expect(controller.getLimitFor('com.google.android.youtube'), 30);
    });

    test('sets valid daily limit and saves config', () async {
      await pumpEventQueue();
      final success = await controller.setLimit('com.roblox.client', 45);
      expect(success, isTrue);
      expect(controller.getLimitFor('com.roblox.client'), 45);
      expect(policiesRepo.savedConfig.appLimits['com.roblox.client'], 45);
    });

    test('validates and rejects invalid daily limit', () async {
      await pumpEventQueue();
      final failure = await controller.setLimit('com.roblox.client', 2000);
      expect(failure, isFalse);
      expect(controller.errorMessage.value, isNotNull);
      expect(controller.hasLimit('com.roblox.client'), isFalse);
    });

    test('removes limit from config', () async {
      await pumpEventQueue();
      expect(controller.hasLimit('com.google.android.youtube'), isTrue);
      final ok = await controller.removeLimit('com.google.android.youtube');
      expect(ok, isTrue);
      expect(controller.hasLimit('com.google.android.youtube'), isFalse);
    });

    test('toggles limit on and off', () async {
      await pumpEventQueue();
      await controller.toggleLimit('com.roblox.client', true);
      expect(controller.hasLimit('com.roblox.client'), isTrue);

      await controller.toggleLimit('com.roblox.client', false);
      expect(controller.hasLimit('com.roblox.client'), isFalse);
    });

    test('filters catalogue by search query and category', () async {
      await pumpEventQueue();
      controller.setCategory(AppCategory.games);
      controller.setSearchQuery('roblox');

      final results = controller.filteredApps;
      expect(results.length, 1);
      expect(results.first.name, 'Roblox');
    });
  });
}
