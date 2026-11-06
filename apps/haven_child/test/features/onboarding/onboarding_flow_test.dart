import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/features/onboarding/data/child_profile_constants.dart';
import 'package:haven_child/features/onboarding/domain/onboarding_flow.dart';
import 'package:haven_child/features/onboarding/domain/onboarding_steps.dart';

/// Brief §7: "onboarding progress transitions incl. out-of-range clamp +
/// step-2 gate" and "age-bracket validation" — every rule lives in the pure
/// [OnboardingFlow]/[OnboardingStep] pair, so they are testable with zero
/// widgets and zero filesystem.
void main() {
  group('OnboardingStep indices and clamping', () {
    test('the enum index IS the persisted step, five steps wide', () {
      expect(OnboardingStep.count, 5);
      expect(OnboardingStep.values.map((s) => s.index).toList(), [0, 1, 2, 3, 4]);
      expect(OnboardingStep.values.map((s) => s.title).toList(), [
        'Welcome',
        'About you',
        'This device',
        'Permissions',
        'All set',
      ]);
    });

    test('fromIndex clamps out-of-range drafts instead of crashing', () {
      // A draft from a future build with MORE steps must still land somewhere.
      expect(OnboardingStep.fromIndex(-7), OnboardingStep.welcome);
      expect(OnboardingStep.fromIndex(0), OnboardingStep.welcome);
      expect(OnboardingStep.fromIndex(4), OnboardingStep.finish);
      expect(OnboardingStep.fromIndex(99), OnboardingStep.finish);
      expect(OnboardingFlow.clampIndex(-3), 0);
      expect(OnboardingFlow.clampIndex(9), OnboardingStep.count - 1);
      expect(OnboardingFlow.clampIndex(2), 2);
    });

    test('progress labels count 1..5 and only the last step is last', () {
      expect(OnboardingStep.welcome.progressLabel, 'Step 1 of 5');
      expect(OnboardingStep.finish.progressLabel, 'Step 5 of 5');
      expect(OnboardingStep.welcome.isLast, isFalse);
      expect(OnboardingStep.permissionsIntro.isLast, isFalse);
      expect(OnboardingStep.finish.isLast, isTrue);
    });
  });

  group('OnboardingFlow blockers (the step-2 gate)', () {
    test('information steps never block', () {
      for (final step in [
        OnboardingStep.welcome,
        OnboardingStep.deviceReview,
        OnboardingStep.permissionsIntro,
        OnboardingStep.finish,
      ]) {
        expect(
          OnboardingFlow.blockerFor(
            step,
            displayName: '',
            ageBracket: '',
          ),
          isNull,
          reason: '${step.name} must advance freely',
        );
      }
    });

    test('childProfile demands a valid name before the age gate', () {
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: '',
          ageBracket: '8-11',
        ),
        'Enter a name.',
      );
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: '   ',
          ageBracket: '8-11',
        ),
        'Enter a name.',
      );
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: 'A',
          ageBracket: '8-11',
        ),
        'Use at least 2 characters.',
      );
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: 'x' * 61,
          ageBracket: '8-11',
        ),
        'Use 60 characters or fewer.',
      );
    });

    test('childProfile gates on the age bracket once the name is valid', () {
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: 'Ada',
          ageBracket: '',
        ),
        'Pick your age group.',
      );
      expect(
        OnboardingFlow.blockerFor(
          OnboardingStep.childProfile,
          displayName: 'Ada',
          ageBracket: '   ',
        ),
        'Pick your age group.',
      );
      for (final bracket in ChildProfileConstants.ageBrackets) {
        expect(
          OnboardingFlow.blockerFor(
            OnboardingStep.childProfile,
            displayName: 'Ada',
            ageBracket: bracket,
          ),
          isNull,
        );
      }
    });

    test('profileProblem re-checks the same rules for the finish step', () {
      expect(OnboardingFlow.profileProblem(displayName: '', ageBracket: ''), 'Enter a name.');
      expect(OnboardingFlow.profileProblem(displayName: 'Ada', ageBracket: ''), 'Pick your age group.');
      expect(OnboardingFlow.profileProblem(displayName: 'Ada', ageBracket: '4-7'), isNull);
    });

    test('age brackets match the parent app vocabulary and cap the field', () {
      expect(ChildProfileConstants.ageBrackets, ['4-7', '8-11', '12-14', '15-17']);
      // The field maxLength mirrors haven_core's 1..60 display-name rule.
      expect(ChildProfileConstants.maxNameLength, 60);
    });
  });
}
