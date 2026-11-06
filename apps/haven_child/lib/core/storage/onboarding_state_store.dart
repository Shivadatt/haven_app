import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'child_local_state.dart';

/// The resumable onboarding draft: which step the child stopped on and the
/// fields typed so far. Non-sensitive by rule — a first name, an age bracket
/// and an avatar label; nothing secret is ever written to the draft.
final class OnboardingDraft {
  const OnboardingDraft({
    required this.stepIndex,
    this.displayName,
    this.ageBracket,
    this.avatar,
  });

  factory OnboardingDraft.fromMap(Map<String, Object?> map) => OnboardingDraft(
    stepIndex: asInt(map['step_index']) ?? 0,
    displayName: asText(map['display_name']),
    ageBracket: asText(map['age_bracket']),
    avatar: asText(map['avatar']),
  );

  final int stepIndex;
  final String? displayName;
  final String? ageBracket;
  final String? avatar;

  Map<String, Object?> toMap() => <String, Object?>{
    'step_index': stepIndex,
    if (displayName != null) 'display_name': displayName,
    if (ageBracket != null) 'age_bracket': ageBracket,
    if (avatar != null) 'avatar': avatar,
  };
}

/// Persisted at every step change so a relaunch resumes where the child left
/// off. Feature code talks to this store, never to the raw document.
abstract interface class OnboardingStateStore {
  Future<Result<OnboardingDraft?>> read();
  Future<Result<void>> save(OnboardingDraft draft);
  Future<Result<void>> clear();
}

final class LocalOnboardingStateStore implements OnboardingStateStore {
  LocalOnboardingStateStore(this._state);

  final ChildLocalStateStore _state;

  @override
  Future<Result<OnboardingDraft?>> read() async {
    final section = await _state.readSection(ChildLocalStateStore.onboardingSection);
    if (section.isErr) return Err<OnboardingDraft?>(section.failureOrNull!);
    final map = section.valueOrNull;
    return Ok<OnboardingDraft?>(map == null ? null : OnboardingDraft.fromMap(map));
  }

  @override
  Future<Result<void>> save(OnboardingDraft draft) =>
      _state.writeSection(ChildLocalStateStore.onboardingSection, draft.toMap());

  @override
  Future<Result<void>> clear() =>
      _state.writeSection(ChildLocalStateStore.onboardingSection, null);
}
