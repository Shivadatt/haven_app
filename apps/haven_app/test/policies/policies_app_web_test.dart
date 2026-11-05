import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/data/policy_rules.dart';

import 'fakes.dart';

void main() {
  group('App & Website Policy Mutations and Validations', () {
    test('domain format validation accepts valid DNS hostnames only', () {
      expect(PolicyRules.isValidDomain('google.com'), isTrue);
      expect(PolicyRules.isValidDomain('sub.example.co.uk'), isTrue);
      expect(PolicyRules.isValidDomain('khanacademy.org'), isTrue);

      expect(PolicyRules.isValidDomain('https://google.com'), isFalse);
      expect(PolicyRules.isValidDomain('google.com/search'), isFalse);
      expect(PolicyRules.isValidDomain('notadomain'), isFalse);
      expect(PolicyRules.isValidDomain(''), isFalse);
    });

    test('adds blocked app and removes from allowed if previously present', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      const pkg = 'com.game.minecraft';
      await controller.addApp(pkg, blocked: true);

      expect(controller.config.value.blockedApps.contains(pkg), isTrue);
      expect(controller.config.value.allowedApps.contains(pkg), isFalse);

      // Now move to allowed
      await controller.addApp(pkg, blocked: false);
      expect(controller.config.value.allowedApps.contains(pkg), isTrue);
      expect(controller.config.value.blockedApps.contains(pkg), isFalse);
    });

    test('sets and removes per-app time limit', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      const pkg = 'com.social.media';
      await controller.setAppLimit(pkg, 45);
      expect(controller.config.value.appLimits[pkg], 45);

      await controller.removeAppLimit(pkg);
      expect(controller.config.value.appLimits.containsKey(pkg), isFalse);
    });

    test('removes app from all policy lists', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      const pkg = 'com.social.media';
      await controller.addApp(pkg, blocked: true);
      await controller.setAppLimit(pkg, 30);

      await controller.removeApp(pkg);
      expect(controller.config.value.blockedApps.contains(pkg), isFalse);
      expect(controller.config.value.allowedApps.contains(pkg), isFalse);
      expect(controller.config.value.appLimits.containsKey(pkg), isFalse);
    });

    test('adds valid domain to blocked domains', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final success = await controller.addDomain('gaming.gg', blocked: true);
      expect(success, isTrue);
      expect(controller.config.value.blockedDomains.contains('gaming.gg'), isTrue);

      await controller.removeDomain('gaming.gg');
      expect(controller.config.value.blockedDomains.contains('gaming.gg'), isFalse);
    });

    test('rejects invalid domain format with validation error', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final fail = await controller.addDomain('https://invalid.com/path', blocked: true);
      expect(fail, isFalse);
      expect(controller.configMessage.value, contains('http'));
      expect(controller.config.value.blockedDomains.contains('https://invalid.com/path'), isFalse);
    });
  });
}
