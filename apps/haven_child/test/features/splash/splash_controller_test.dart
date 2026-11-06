import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_data_resetter.dart';
import 'package:haven_child/core/storage/child_database.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/features/splash/controllers/splash_controller.dart';

import '../../support/fakes.dart';
import '../../support/storage.dart';

/// Brief §7 boot decisions: profile home ONLY when the session names the
/// profile that is actually on the device — never on either half alone.
void main() {
  late List<String> navigated;
  late FakeChildSessionStore sessions;
  late String emptyDir;

  SplashController build({
    Future<Result<ChildDatabase>> Function()? openStorage,
    Future<Result<void>> Function()? resetStorage,
    ChildProfileRepository? profiles,
    ChildSessionStore? store,
  }) {
    final subject = SplashController(
      openStorage: openStorage ?? (() => ChildDatabase.openAt(emptyDir)),
      resetStorage: resetStorage ?? () async => okVoid(),
      profileRepository: () => profiles ?? FakeChildProfileRepository(),
      sessionStore: () => store ?? sessions,
      navigate: navigated.add,
    );
    // No onInit here: every case below calls boot()/resetAndReboot() itself
    // so the boot happens exactly once and is fully awaited.
    return subject;
  }

  Profile childProfile({String id = 'p1'}) => Profile(
    id: id,
    role: ProfileRole.child.wire,
    displayName: 'Ada',
  );

  setUp(() {
    navigated = [];
    sessions = FakeChildSessionStore();
    emptyDir = StorageTestLane.createTempDirectory();
  });

  tearDown(() => StorageTestLane.deleteTemp(emptyDir));

  test('a brand-new device boots into onboarding', () async {
    await build().boot();
    expect(navigated, [ChildRoutes.onboarding]);
    expect(sessions.readCount, 1);
  });

  test('profile + matching session boots straight to the child home', () async {
    final profiles = FakeChildProfileRepository()..profile = childProfile();
    sessions.session = ChildLocalSession(
      profileId: 'p1',
      createdAt: DateTime.utc(2026, 11, 6),
    );
    await build(profiles: profiles).boot();
    expect(navigated, [ChildRoutes.profile]);
    expect(sessions.session!.profileId, 'p1');
  });

  test('a session naming a DIFFERENT profile is not a finished setup', () async {
    final profiles = FakeChildProfileRepository()..profile = childProfile(id: 'p1');
    sessions.session = ChildLocalSession(
      profileId: 'ghost',
      createdAt: DateTime.utc(2026, 11, 6),
    );
    await build(profiles: profiles).boot();
    expect(navigated, [ChildRoutes.onboarding]);
  });

  test('a profile without a session is also unfinished setup', () async {
    await build(profiles: FakeChildProfileRepository()..profile = childProfile())
        .boot();
    expect(navigated, [ChildRoutes.onboarding]);
  });

  test('a failed open stops the boot with the honest message, no navigation', () async {
    final subject = build(
      openStorage: () async =>
          Err<ChildDatabase>(const StorageFailure('The local data could not be read.')),
    );
    await subject.boot();
    expect(subject.isBooting.value, isFalse);
    expect(subject.errorMessage.value, 'The local data could not be read.');
    expect(subject.storageIsCorrupt.value, isFalse);
    expect(navigated, isEmpty);
  });

  test('a corrupt document is FLAGGED corrupt — the reset exit becomes legal', () async {
    final subject = build(
      openStorage: () async => Err<ChildDatabase>(
        const StorageFailure(
          'The stored local data is damaged and was not overwritten.',
          detail: 'local_database_corrupt: not an object',
        ),
      ),
    );
    await subject.boot();
    expect(subject.storageIsCorrupt.value, isTrue);
  });

  test('resetAndReboot replaces the damage and boots again — once', () async {
    var attempts = 0;
    var resets = 0;
    final goodDir = StorageTestLane.createTempDirectory();
    addTearDown(() => StorageTestLane.deleteTemp(goodDir));
    final subject = SplashController(
      openStorage: () async {
        attempts++;
        if (attempts == 1) {
          return Err<ChildDatabase>(
            const StorageFailure('damaged', detail: 'local_database_corrupt: x'),
          );
        }
        return ChildDatabase.openAt(goodDir);
      },
      resetStorage: () async {
        resets++;
        return ChildDataResetter.clearAll(
          directoryPath: goodDir,
          verifyReadableFirst: false,
        );
      },
      profileRepository: () => FakeChildProfileRepository(),
      sessionStore: () => sessions,
      navigate: navigated.add,
    );
    // First boot fails as corrupt; the reset then re-boots into onboarding.
    await subject.boot();
    expect(subject.storageIsCorrupt.value, isTrue);
    await subject.resetAndReboot();
    expect(resets, 1);
    expect(navigated.last, ChildRoutes.onboarding);
    expect(subject.errorMessage.value, isNull);
    expect(subject.isResetting.value, isFalse);
  });

  test('a failing reset reports instead of spinning forever', () async {
    final subject = SplashController(
      openStorage: () async =>
          Err<ChildDatabase>(const StorageFailure('nope', detail: 'local_database_corrupt: x')),
      resetStorage: () async =>
          const Err<void>(StorageFailure('The reset could not be written.')),
      profileRepository: () => FakeChildProfileRepository(),
      sessionStore: () => sessions,
      navigate: navigated.add,
    );
    await subject.resetAndReboot();
    expect(subject.errorMessage.value, 'The reset could not be written.');
    expect(subject.isResetting.value, isFalse);
    expect(navigated, isEmpty);
  });

  test('a damaged SESSION section is read as unfinished, not an error', () async {
    final store = InMemoryLocalStore();
    await store.save(<String, Object?>{
      'schemaVersion': 1,
      'tables': <String, Object?>{},
      ChildLocalStateStore.documentKey: <String, Object?>{
        ChildLocalStateStore.sessionSection: <String, Object?>{'nonsense': true},
      },
    });
    final profiles = FakeChildProfileRepository()..profile = childProfile();
    await build(
      profiles: profiles,
      store: LocalChildSessionStore(
        ChildLocalStateStore(store: store, tables: LocalTables(store)),
      ),
    ).boot();
    expect(navigated, [ChildRoutes.onboarding]);
  });

  test('a refused profile read boots into the error, not the empty state', () async {
    final profiles = FakeChildProfileRepository()
      ..readFailure = const BackendFailure(
        'The stored profile on this device is not a child profile. Nothing was changed.',
        detail: 'child_profile_role_mismatch',
      );
    await build(profiles: profiles).boot();
    expect(navigated, isEmpty);
    expect(sessions.session, isNull);
  });
}
