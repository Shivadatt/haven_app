import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_profile_repository.dart';
import '../../../core/storage/onboarding_state_store.dart';

/// Creates the ONE profile row and the local session, exactly once.
///
/// Double-submit defence in depth (brief §4 C): the controller's in-flight
/// flag keeps a second tap out, the repository's create-once rule keeps a
/// second row out, and a resumed state that has already finished completes
/// the session instead of re-writing the profile — never a silent overwrite.
final class OnboardingCompletion {
  OnboardingCompletion({
    required this.profiles,
    required this.sessions,
    required this.drafts,
    required this.clock,
  });

  final ChildProfileRepository profiles;
  final ChildSessionStore sessions;
  final OnboardingStateStore drafts;
  final Clock clock;

  Future<Result<Profile>> call({
    required String displayName,
    required String ageBracket,
    String? avatar,
  }) async {
    final existing = await profiles.read();
    switch (existing) {
      case Err<Profile?>():
        return Err<Profile>(existing.failureOrNull!);
      case Ok<Profile?>(:final value) when value != null:
        // Profile exists but no session completed setup (the splash sends
        // that half-finished state back here): finish, do not re-create.
        return _createSession(value);
      case Ok<Profile?>():
        final created = await profiles.create(
          displayName: displayName,
          ageBracket: ageBracket,
          avatar: avatar,
        );
        if (created case Err<Profile>()) {
          return Err<Profile>(created.failureOrNull!);
        }
        return _createSession(created.valueOrNull!);
    }
  }

  Future<Result<Profile>> _createSession(Profile profile) async {
    final saved = await sessions.save(
      ChildLocalSession(profileId: profile.id, createdAt: clock.now()),
    );
    if (saved.isErr) return Err<Profile>(saved.failureOrNull!);
    final cleared = await drafts.clear();
    if (cleared.isErr) return Err<Profile>(cleared.failureOrNull!);
    return Ok(profile);
  }
}
