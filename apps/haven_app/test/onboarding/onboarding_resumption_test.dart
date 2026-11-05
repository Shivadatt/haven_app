import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/onboarding/controllers/onboarding_controller.dart';

import '../authentication/fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'local:token',
  );

  group('Onboarding resumption & progress tracking', () {
    test('resumes at saved step and restored ethics acknowledgment', () async {
      final prefs = FakePreferencesStore(
        seed: {
          PreferenceKey.onboardingEthicsAcknowledged: 'true',
          PreferenceKey.onboardingStep: 'child',
        },
      );
      final subject = OnboardingController(
        repository: FakeOnboardingRepository(),
        auth: FakeAuthRepository(session: session),
        preferences: prefs,
      );

      await subject.restoreProgress();

      expect(subject.acknowledged.value, isTrue);
      expect(subject.step.value, OnboardingStep.child);
    });

    test('resumes at device setup step when saved', () async {
      final prefs = FakePreferencesStore(
        seed: {
          PreferenceKey.onboardingEthicsAcknowledged: 'true',
          PreferenceKey.onboardingStep: 'device',
        },
      );
      final subject = OnboardingController(
        repository: FakeOnboardingRepository(),
        auth: FakeAuthRepository(session: session),
        preferences: prefs,
      );

      await subject.restoreProgress();

      expect(subject.step.value, OnboardingStep.device);
    });

    test('advancing through steps persists progress sequentially', () async {
      final prefs = FakePreferencesStore();
      final repo = FakeOnboardingRepository();
      final routes = <String>[];
      final subject = OnboardingController(
        repository: repo,
        auth: FakeAuthRepository(session: session),
        preferences: prefs,
        goTo: (route, _) => routes.add(route),
      );

      // Step 1: Ethics
      expect(subject.step.value, OnboardingStep.explain);
      subject.acknowledged.value = true;
      await subject.continueFromExplain();

      expect(subject.step.value, OnboardingStep.setup);
      expect(prefs.stored[PreferenceKey.onboardingEthicsAcknowledged], 'true');
      expect(prefs.stored[PreferenceKey.onboardingStep], 'setup');

      // Step 2: Family
      subject.familyName.text = 'The Incredibles';
      await subject.submitFamily();

      expect(subject.step.value, OnboardingStep.child);
      expect(prefs.stored[PreferenceKey.onboardingStep], 'child');
      expect(repo.lastFamilyName, 'The Incredibles');

      // Step 3: Child
      subject.childName.text = 'Dash';
      await subject.submitChild();

      expect(subject.step.value, OnboardingStep.device);
      expect(prefs.stored[PreferenceKey.onboardingStep], 'device');
      expect(repo.lastChildName, 'Dash');

      // Step 4: Device setup completion
      await subject.completeOnboarding();

      expect(prefs.stored[PreferenceKey.onboardingCompleted], 'true');
      expect(routes, [AppRoutes.dashboard]);
    });
  });
}
