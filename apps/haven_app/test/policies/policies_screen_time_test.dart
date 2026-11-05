import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/data/policy_config.dart';
import 'package:haven_app/features/policies/data/policy_rules.dart';

import 'fakes.dart';

void main() {
  group('Screen Time Limit Editing and Validation', () {
    test('validation helper enforces 0 to 1440 minutes range', () {
      expect(PolicyRules.validateMinutesLimit(null), isNotNull);
      expect(PolicyRules.validateMinutesLimit(-1), isNotNull);
      expect(PolicyRules.validateMinutesLimit(1441), isNotNull);
      expect(PolicyRules.validateMinutesLimit(0), isNull);
      expect(PolicyRules.validateMinutesLimit(120), isNull);
      expect(PolicyRules.validateMinutesLimit(1440), isNull);
    });

    test('updates daily limit with valid value and saves to repository', () async {
      final repo = FakePoliciesRepository(
        canConfigure: true,
        initialConfig: PolicyConfig.defaults(),
      );
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      expect(controller.config.value.dailyScreenTimeMinutes, 120);

      final success = await controller.updateDailyLimit(180);
      expect(success, isTrue);
      expect(controller.config.value.dailyScreenTimeMinutes, 180);
      expect(repo.savedConfig.dailyScreenTimeMinutes, 180);
      expect(repo.saveCount, 1);
    });

    test('boundary limit of 0 and 1440 minutes are accepted', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      expect(await controller.updateDailyLimit(0), isTrue);
      expect(controller.config.value.dailyScreenTimeMinutes, 0);

      expect(await controller.updateDailyLimit(1440), isTrue);
      expect(controller.config.value.dailyScreenTimeMinutes, 1440);
    });

    test('invalid negative or excess minutes are rejected and not saved', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final negSuccess = await controller.updateDailyLimit(-10);
      expect(negSuccess, isFalse);
      expect(controller.configMessage.value, contains('between 0 and 1440'));
      expect(repo.saveCount, 0);

      final overSuccess = await controller.updateDailyLimit(1500);
      expect(overSuccess, isFalse);
      expect(controller.configMessage.value, contains('between 0 and 1440'));
      expect(repo.saveCount, 0);
    });
  });
}
