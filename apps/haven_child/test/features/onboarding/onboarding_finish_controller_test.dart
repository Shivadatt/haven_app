import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/features/onboarding/domain/onboarding_steps.dart';

import 'controller_harness.dart';

/// The `finish()` lane of the onboarding controller: create-once, the
/// in-flight double-tap guard, and the honest bounce back to step 2 for an
/// incomplete draft. Restores/navigation live in
/// `onboarding_controller_test.dart` (line-count rule).
void main() {
  late ControllerHarness h;

  setUp(() {
    h = ControllerHarness();
    h.atFinishStep();
  });
  tearDown(() => h.subject.dispose());

  test('the happy path creates once, saves the session, clears the draft', () async {
    await h.subject.finish();
    expect(h.profiles.createCount, 1);
    expect(h.sessions.session!.profileId, 'p1');
    expect(h.drafts.clearCount, 1);
    expect(h.finished, ['/profile']);
  });

  test('the in-flight guard makes a second tap a no-op, not a second row', () async {
    h.profiles.createGate = Completer<void>();
    final first = h.subject.finish();
    await Future.delayed(Duration.zero);
    await h.subject.finish(); // taps while the create is in flight
    expect(h.subject.isSubmitting.value, isTrue);
    h.profiles.createGate!.complete();
    await first;
    expect(h.profiles.createCount, 1);
    expect(h.finished, ['/profile']);
  });

  test('a resumed draft that already finished completes WITHOUT re-creating', () async {
    h.profiles.profile = Profile(
      id: 'existing',
      role: ProfileRole.child.wire,
      displayName: 'Ada',
    );
    await h.subject.finish();
    expect(h.profiles.createCount, 0);
    expect(h.sessions.session!.profileId, 'existing');
    expect(h.finished, ['/profile']);
  });

  test('a repository refusal is shown and stays on the flow', () async {
    h.profiles.createFailure = const ValidationFailure(
      'A child profile already exists on this device, so nothing was created.',
      detail: 'child_profile_create_once',
    );
    await h.subject.finish();
    expect(h.subject.errorMessage.value, contains('already exists'));
    expect(h.finished, isEmpty);
    expect(h.subject.isSubmitting.value, isFalse);
  });

  test('an incomplete resumed draft bounces back to step 2 with guidance', () async {
    h.subject.ageBracket.value = '';
    await h.subject.finish();
    expect(h.subject.stepIndex.value, OnboardingStep.childProfile.index);
    expect(h.subject.errorMessage.value, contains('Back to the "About you" step'));
    expect(h.profiles.createCount, 0);
  });
}
