// ignore_for_file: use_null_aware_elements

import 'dart:async';

import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/core/permissions/child_permission.dart';
import 'package:haven_child/core/permissions/permission_status_source.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';

/// Hand-written seam fakes — no mocking package, per
/// `docs/implementation/00-app-contract.md` ("Test conventions").
///
/// Why fakes and not the real repositories: the widget/controller tests below
/// need to hold a call open (double-tap guard), fail a read on purpose
/// (error/retry states) and count writes (create-once). `LocalChildProfileRepository`
/// et al. get their own dedicated unit files against the REAL in-memory
/// engine (`support/storage.dart`), so the behaviour itself is still proven —
/// these fakes only replace it where a seam must misbehave on cue.

/// Profile repository whose every answer the test picks.
final class FakeChildProfileRepository implements ChildProfileRepository {
  Profile? profile;
  HavenFailure? readFailure;
  HavenFailure? createFailure;
  HavenFailure? updateFailure;

  /// When set, [create] waits on it — the double-tap guard's stopcock.
  Completer<void>? createGate;

  int readCount = 0;
  int createCount = 0;
  int updateCount = 0;
  String? lastCreateName;

  @override
  Future<Result<Profile?>> read() async {
    readCount++;
    final HavenFailure? failure = readFailure;
    if (failure != null) return Err<Profile?>(failure);
    return Ok<Profile?>(profile);
  }

  @override
  Future<Result<Profile>> create({
    required String displayName,
    String? ageBracket,
    String? avatar,
  }) async {
    final Completer<void>? gate = createGate;
    if (gate != null) await gate.future;
    createCount++;
    lastCreateName = displayName;
    final HavenFailure? failure = createFailure;
    if (failure != null) return Err<Profile>(failure);
    profile = Profile(
      id: 'p1',
      role: ProfileRole.child.wire,
      displayName: displayName.trim(),
      ageBracket: ageBracket,
      avatar: avatar,
      createdAt: DateTime.utc(2026, 11, 6),
    );
    return Ok<Profile>(profile!);
  }

  @override
  Future<Result<Profile>> update({
    required String id,
    String? displayName,
    String? ageBracket,
    String? avatar,
  }) async {
    updateCount++;
    final HavenFailure? failure = updateFailure;
    if (failure != null) return Err<Profile>(failure);
    final Profile? current = profile;
    if (current == null) {
      return Err<Profile>(
        const ValidationFailure('No profile.', detail: 'child_profile_missing'),
      );
    }
    profile = Profile(
      id: current.id,
      role: current.role,
      displayName: (displayName ?? current.displayName).trim(),
      ageBracket: ageBracket ?? current.ageBracket,
      avatar: avatar ?? current.avatar,
      createdAt: current.createdAt,
    );
    return Ok<Profile>(profile!);
  }
}

/// Onboarding draft store with scripted read/save failures and a save log.
final class FakeOnboardingStateStore implements OnboardingStateStore {
  OnboardingDraft? draft;
  HavenFailure? readFailure;
  HavenFailure? saveFailure;

  /// When set, [read] waits on it — proves the loading state is real.
  Completer<void>? readGate;

  final List<OnboardingDraft> saved = <OnboardingDraft>[];
  int readCount = 0;
  int clearCount = 0;

  @override
  Future<Result<OnboardingDraft?>> read() async {
    readCount++;
    final Completer<void>? gate = readGate;
    if (gate != null) await gate.future;
    final HavenFailure? failure = readFailure;
    if (failure != null) return Err<OnboardingDraft?>(failure);
    return Ok<OnboardingDraft?>(draft);
  }

  @override
  Future<Result<void>> save(OnboardingDraft draft) async {
    final HavenFailure? failure = saveFailure;
    if (failure != null) return Err<void>(failure);
    this.draft = draft;
    saved.add(draft);
    return okVoid();
  }

  @override
  Future<Result<void>> clear() async {
    clearCount++;
    draft = null;
    return okVoid();
  }
}

/// Session store that remembers what it was told, on cue.
final class FakeChildSessionStore implements ChildSessionStore {
  ChildLocalSession? session;
  HavenFailure? readFailure;
  int readCount = 0;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<Result<ChildLocalSession?>> read() async {
    readCount++;
    final HavenFailure? failure = readFailure;
    if (failure != null) return Err<ChildLocalSession?>(failure);
    return Ok<ChildLocalSession?>(session);
  }

  @override
  Future<Result<void>> save(ChildLocalSession session) async {
    saveCount++;
    this.session = session;
    return okVoid();
  }

  @override
  Future<Result<void>> clear() async {
    clearCount++;
    session = null;
    return okVoid();
  }
}

/// Permission source with three scripted modes: every entry `blocked`
/// (unless overridden), all granted, or a thrown error — the interface
/// forbids throws, so this fake exists to prove the controller's
/// report-instead-of-freeze branch.
final class FakePermissionStatusSource implements PermissionStatusSource {
  FakePermissionStatusSource({this.mode = PermissionFakeMode.blocked});

  PermissionFakeMode mode;
  final Map<ChildPermission, bool> grantedOverrides = {};
  int callCount = 0;

  @override
  Future<Result<PermissionStatus>> statusOf(ChildPermission permission) async {
    callCount++;
    if (mode == PermissionFakeMode.throws) {
      throw StateError('fake source broke the no-throw rule');
    }
    final bool? override = grantedOverrides[permission];
    if (mode == PermissionFakeMode.realReads || override != null) {
      return Ok<PermissionStatus>(
        PermissionStatus(
          permission: permission,
          granted: override ?? mode == PermissionFakeMode.realReads,
        ),
      );
    }
    return blocked<PermissionStatus>('fake: ${permission.wire} reader absent');
  }
}

enum PermissionFakeMode { blocked, realReads, throws }
