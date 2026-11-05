import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_core/haven_core.dart';

import '../authentication/fakes.dart';
import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'local:token',
  );

  group('Onboarding validation & option selections', () {
    test('step 1 requires acknowledging ethics before advancing', () async {
      final subject = OnboardingController(
        repository: FakeOnboardingRepository(),
        auth: FakeAuthRepository(session: session),
      );

      expect(subject.step.value, OnboardingStep.explain);
      await subject.continueFromExplain();

      expect(subject.step.value, OnboardingStep.explain);
      expect(subject.message.value, 'Tick the box to say you have read this.');

      subject.acknowledged.value = true;
      await subject.continueFromExplain();
      expect(subject.step.value, OnboardingStep.setup);
    });

    test('step 2 validates family name length constraints', () async {
      final subject = OnboardingController(
        repository: FakeOnboardingRepository(),
        auth: FakeAuthRepository(session: session),
      );
      subject.step.value = OnboardingStep.setup;

      subject.familyName.text = '   ';
      await subject.submitFamily();
      expect(subject.message.value, 'Give your family a name.');

      subject.familyName.text = 'F' * 81;
      await subject.submitFamily();
      expect(subject.message.value, 'Use 80 characters or fewer.');
    });

    test('step 3 validates child name according to 2-60 char rule', () async {
      final subject = OnboardingController(
        repository: FakeOnboardingRepository(),
        auth: FakeAuthRepository(session: session),
      );
      subject.step.value = OnboardingStep.child;

      subject.childName.text = '';
      await subject.submitChild();
      expect(subject.message.value, 'Enter a name.');

      subject.childName.text = 'C';
      await subject.submitChild();
      expect(subject.message.value, 'Use at least 2 characters.');

      subject.childName.text = 'C' * 61;
      await subject.submitChild();
      expect(subject.message.value, 'Use 60 characters or fewer.');

      expect(validateDisplayName('Alice'), isNull);
    });

    test('age groups and avatars cover the required options', () {
      expect(ChildAgeGroup.values.map((g) => g.key), containsAll(['toddler', 'child', 'teen']));
      expect(ChildAgeGroup.toddler.label, contains('2–5'));
      expect(ChildAgeGroup.child.label, contains('6–12'));
      expect(ChildAgeGroup.teen.label, contains('13–17'));

      expect(ChildAvatar.values.map((a) => a.key), containsAll(['bear', 'fox', 'owl', 'rabbit', 'panda', 'lion']));
    });
  });
}
