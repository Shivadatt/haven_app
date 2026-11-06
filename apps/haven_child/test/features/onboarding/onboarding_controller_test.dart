import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/onboarding/domain/onboarding_steps.dart';

import 'controller_harness.dart';

/// Controller transitions with the fake seam: restore clamps a resumed
/// draft before trusting it, and every navigation persists. The `finish()`
/// lane lives in `onboarding_finish_controller_test.dart` (line-count rule).
void main() {
  late ControllerHarness h;

  setUp(() => h = ControllerHarness());
  tearDown(() => h.subject.dispose());

  group('restore', () {
    test('a fresh device loads to step 1 with nothing filled', () async {
      await Future.delayed(Duration.zero); // onInit's restore is async
      expect(h.subject.isLoading.value, isFalse);
      expect(h.subject.stepIndex.value, 0);
      expect(h.subject.nameController.text, '');
      expect(h.subject.errorMessage.value, isNull);
    });

    test('an out-of-range persisted step is clamped, not trusted', () async {
      h.drafts.draft = const OnboardingDraft(stepIndex: 47, displayName: 'Ada');
      h.rebuild();
      await Future.delayed(Duration.zero);
      expect(h.subject.stepIndex.value, OnboardingStep.finish.index);
      expect(h.subject.currentStep, OnboardingStep.finish);
    });

    test('a draft pre-fills every field, including the avatar', () async {
      h.drafts.draft = const OnboardingDraft(
        stepIndex: 1,
        displayName: 'Ada',
        ageBracket: '8-11',
        avatar: 'star',
      );
      h.rebuild();
      await Future.delayed(Duration.zero);
      expect(h.subject.nameController.text, 'Ada');
      expect(h.subject.ageBracket.value, '8-11');
      expect(h.subject.avatar.value, 'star');
      expect(h.subject.currentStep, OnboardingStep.childProfile);
    });

    test('a failed read shows an honest error instead of an empty form', () async {
      h.drafts.readFailure = const StorageFailure('Cannot read the draft.');
      h.rebuild();
      await Future.delayed(Duration.zero);
      expect(h.subject.errorMessage.value, 'Cannot read the draft.');
      expect(h.subject.isLoading.value, isFalse);
    });
  });

  group('navigation persists', () {
    test('goNext from welcome lands on step 2 and saves the draft', () async {
      await h.subject.goNext();
      expect(h.subject.stepIndex.value, 1);
      expect(h.drafts.saved.last.stepIndex, 1);
    });

    test('the step-2 gate blocks WITHOUT navigating or saving', () async {
      await h.subject.goNext(); // welcome -> childProfile
      await h.subject.goNext(); // empty name: refused
      expect(h.subject.stepIndex.value, 1);
      expect(h.subject.errorMessage.value, 'Enter a name.');
      expect(h.drafts.saved.length, 1); // only the welcome transition saved
    });

    test('filling the form opens the gate; blanks are stored as absent', () async {
      await h.subject.goNext();
      h.subject.nameController.text = '  Ada  ';
      await h.subject.goNext(); // no bracket yet
      expect(h.subject.errorMessage.value, 'Pick your age group.');
      h.subject.ageBracket.value = '8-11';
      await h.subject.goNext();
      expect(h.subject.stepIndex.value, 2);
      expect(h.drafts.saved.last.displayName, 'Ada');
      expect(h.drafts.saved.last.ageBracket, '8-11');
      expect(h.drafts.saved.last.avatar, isNull);
    });

    test('a failed save advances but tells the truth (draft stays one step back)', () async {
      // Documented behaviour: navigation is not gated on the draft write —
      // losing a resume point must not block the child — but the store
      // message surfaces instead of being swallowed. The validation gate
      // still runs FIRST: with the name filled in, the save is what fails.
      await h.subject.goNext();
      h.subject.nameController.text = 'Ada';
      h.subject.ageBracket.value = '8-11'; // pass the gate, so the WRITE is next
      h.drafts.saveFailure = const StorageFailure('The disk refused.');
      await h.subject.goNext();
      expect(h.subject.stepIndex.value, 2);
      expect(h.drafts.saved.length, 1); // only the earlier welcome move logged
      expect(h.subject.errorMessage.value, 'The disk refused.');
    });

    test('goBack walks down and cannot leave step 1', () async {
      await h.subject.goNext();
      await h.subject.goBack();
      expect(h.subject.stepIndex.value, 0);
      expect(h.drafts.saved.last.stepIndex, 0);
      await h.subject.goBack(); // already first: no extra write
      expect(h.drafts.saved.length, 2);
    });

    test('goNext on the last step is inert — finishing is finish()', () async {
      h.atFinishStep();
      await h.subject.goNext();
      expect(h.subject.stepIndex.value, 4);
      expect(h.finished, isEmpty);
    });
  });

  group('detail links', () {
    test('device and permissions open ON TOP through the injected push', () {
      h.subject.openDeviceDetails();
      h.subject.openPermissionExplanations();
      expect(h.pushed, ['/device', '/permissions']);
    });
  });
}
