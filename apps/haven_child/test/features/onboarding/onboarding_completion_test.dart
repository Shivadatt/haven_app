import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/local_child_profile_repository.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/onboarding/services/onboarding_completion.dart';

import '../../support/fakes.dart';
import '../../support/storage.dart';

/// The one write of the whole flow, run against the REAL profile repository
/// over the in-memory engine — the create-once rule is enforced by the
/// repository, not by this service's politeness.
void main() {
  late OnboardingCompletion subject;
  late LocalChildProfileRepository profiles;
  late LocalTables tables;
  late FakeChildSessionStore sessions;
  late FakeOnboardingStateStore drafts;
  final clock = FixedClock(DateTime.utc(2026, 11, 6, 9));

  setUp(() {
    tables = StorageTestLane.memoryTables();
    profiles = LocalChildProfileRepository(tables, clock: clock);
    sessions = FakeChildSessionStore();
    drafts = FakeOnboardingStateStore();
    subject = OnboardingCompletion(
      profiles: profiles,
      sessions: sessions,
      drafts: drafts,
      clock: clock,
    );
  });

  test('first completion writes profile + session and clears the draft', () async {
    drafts.draft = const OnboardingDraft(stepIndex: 4, displayName: 'Ada');
    final created = await subject(
      displayName: 'Ada',
      ageBracket: '8-11',
      avatar: 'rocket',
    );
    final profile = created.valueOrNull!;
    expect(profile.displayName, 'Ada');
    expect(sessions.session!.profileId, profile.id);
    expect(sessions.session!.createdAt, DateTime.utc(2026, 11, 6, 9));
    expect(drafts.draft, isNull);
    expect(drafts.clearCount, 1);
  });

  test('a second completion NEVER creates a row twice — it finishes instead', () async {
    final first = await subject(displayName: 'Ada', ageBracket: '8-11');
    final second = await subject(displayName: 'Someone Else', ageBracket: '4-7');
    expect(second.valueOrNull!.id, first.valueOrNull!.id);
    // Still exactly one row on the device, and it is still Ada's.
    expect((await profiles.read()).valueOrNull!.displayName, 'Ada');
    expect((await tables.count(TableName.profiles)).valueOrNull, 1);
  });

  test('a half-finished device (profile, no session) completes without a create', () async {
    await profiles.create(displayName: 'Ada', ageBracket: '8-11');
    final done = await subject(displayName: 'Ignored', ageBracket: 'ignored');
    expect(done.valueOrNull!.displayName, 'Ada');
    expect(sessions.saveCount, 1);
    expect(sessions.session!.profileId, done.valueOrNull!.id);
  });

  test('a role-mismatch row fails the completion with the guard, creating nothing', () async {
    final tables = StorageTestLane.memoryTables();
    await tables.insert(TableName.profiles, StorageTestLane.parentRoleRow());
    final foreign = OnboardingCompletion(
      profiles: LocalChildProfileRepository(tables),
      sessions: sessions,
      drafts: drafts,
      clock: clock,
    );
    final failure = (await foreign(displayName: 'Ada', ageBracket: '8-11')).failureOrNull;
    expect(failure!.detail, 'child_profile_role_mismatch');
    expect(sessions.saveCount, 0);
  });

  test('a session write failure aborts the completion — no draft is cleared', () async {
    sessions.saveCount = 0;
    final failing = OnboardingCompletion(
      profiles: profiles,
      sessions: _FailSaveSessionStore(),
      drafts: drafts,
      clock: clock,
    );
    final failure = (await failing(displayName: 'Ada', ageBracket: '8-11')).failureOrNull;
    expect(failure, isA<StorageFailure>());
    expect(drafts.clearCount, 0); // the resume point survives a failed finish
  });
}

final class _FailSaveSessionStore implements ChildSessionStore {
  @override
  Future<Result<ChildLocalSession?>> read() async =>
      const Ok<ChildLocalSession?>(null);

  @override
  Future<Result<void>> save(ChildLocalSession session) async =>
      const Err<void>(StorageFailure('The session could not be stored.'));

  @override
  Future<Result<void>> clear() async => okVoid();
}
