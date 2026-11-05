import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/web_filter_controller.dart';
import 'package:haven_app/features/policies/data/web_filter_models.dart';

import '../child_devices/fakes.dart';
import 'fakes.dart';

void main() {
  group('WebFilterController', () {
    late FakePoliciesRepository policiesRepo;
    late FakeDevicesRepository devicesRepo;
    late WebFilterController controller;

    setUp(() {
      policiesRepo = FakePoliciesRepository(canConfigure: true);
      devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      controller = WebFilterController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      controller.onInit();
    });

    test('initializes and loads blocked and allowed domains', () async {
      await pumpEventQueue();
      expect(controller.isLoading.value, isFalse);
      expect(controller.config.value.blockedDomains.contains('tiktok.com'), isTrue);
      expect(controller.config.value.allowedDomains.contains('wikipedia.org'), isTrue);
      expect(controller.config.value.safeSearchEnabled, isTrue);
    });

    test('normalizes domain input and adds to blocked list', () async {
      await pumpEventQueue();
      final ok = await controller.addDomain(
        'https://Roblox.com/games/play',
        isBlocked: true,
      );
      expect(ok, isTrue);
      expect(controller.config.value.blockedDomains.contains('roblox.com'), isTrue);
    });

    test('rejects invalid domain string', () async {
      await pumpEventQueue();
      final ok = await controller.addDomain('notadomain', isBlocked: true);
      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });

    test('prevents duplicates between allowed and blocked domains', () async {
      await pumpEventQueue();
      expect(controller.config.value.allowedDomains.contains('wikipedia.org'), isTrue);
      await controller.addDomain('wikipedia.org', isBlocked: true);
      expect(controller.config.value.blockedDomains.contains('wikipedia.org'), isTrue);
      expect(controller.config.value.allowedDomains.contains('wikipedia.org'), isFalse);
    });

    test('edits existing domain rule', () async {
      await pumpEventQueue();
      await controller.editDomain(
        'tiktok.com',
        'https://bytedance.com/home',
        isBlocked: true,
      );
      expect(controller.config.value.blockedDomains.contains('bytedance.com'), isTrue);
      expect(controller.config.value.blockedDomains.contains('tiktok.com'), isFalse);
    });

    test('removes domain from rules', () async {
      await pumpEventQueue();
      await controller.removeDomain('tiktok.com');
      expect(controller.config.value.blockedDomains.contains('tiktok.com'), isFalse);
    });

    test('toggles SafeSearch preference', () async {
      await pumpEventQueue();
      expect(controller.config.value.safeSearchEnabled, isTrue);
      await controller.toggleSafeSearch(false);
      expect(controller.config.value.safeSearchEnabled, isFalse);
      expect(policiesRepo.savedConfig.safeSearchEnabled, isFalse);
    });

    test('adds category preset domains to blocked list', () async {
      await pumpEventQueue();
      await controller.addCategoryPreset(WebCategory.gambling, isBlocked: true);
      for (final domain in WebFilterModels.presets[WebCategory.gambling]!) {
        expect(controller.config.value.blockedDomains.contains(domain), isTrue);
      }
    });

    test('filters domains by category and query', () async {
      await pumpEventQueue();
      controller.switchTab(0); // Blocked
      controller.setCategory(WebCategory.social);
      controller.setSearchQuery('tik');

      final domains = controller.filteredDomains;
      expect(domains.length, 1);
      expect(domains.first, 'tiktok.com');
    });
  });
}
