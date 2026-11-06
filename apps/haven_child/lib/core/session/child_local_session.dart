import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../storage/child_local_state.dart';

/// The child app's local session.
///
/// What this IS: "this device has finished setup for the child profile with
/// id [profileId], at [createdAt]". It is a memory of a completed local
/// onboarding, nothing more.
///
/// What it is NOT — stated exactly once here because every later screen leans
/// on it: it is NOT a verified, parent-linked account. There is no credential,
/// no token, no server check, no family row. `haven_api`'s `LocalUserAuth`
/// hard-codes the parent role and is deliberately unused in this lane; the
/// child app keeps its own honest session abstraction instead. Until Stage-2
/// pairing exists there is no parent link at all, which is why the UI text is
/// [parentConnectionStatus] and not anything softer.
final class ChildLocalSession {
  const ChildLocalSession({required this.profileId, required this.createdAt});

  static const String parentConnectionLabel = 'Parent connection';
  static const String parentConnectionStatus = 'Not connected';

  final String profileId;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'profile_id': profileId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  /// Null when the stored map is missing or malformed — a damaged session
  /// section sends the child back through onboarding, and the create-once
  /// profile rule keeps the profile itself safe from a second write.
  static ChildLocalSession? fromMap(Map<String, Object?> map) {
    final id = asText(map['profile_id']);
    final created = asDate(map['created_at']);
    if (id == null || id.isEmpty || created == null) return null;
    return ChildLocalSession(profileId: id, createdAt: created);
  }
}

abstract interface class ChildSessionStore {
  Future<Result<ChildLocalSession?>> read();
  Future<Result<void>> save(ChildLocalSession session);
  Future<Result<void>> clear();
}

/// Persists the session through the same document conventions as every other
/// child-lane state (`childLocalState.session`, non-sensitive by rule).
final class LocalChildSessionStore implements ChildSessionStore {
  LocalChildSessionStore(this._state);

  final ChildLocalStateStore _state;

  @override
  Future<Result<ChildLocalSession?>> read() async {
    final section = await _state.readSection(ChildLocalStateStore.sessionSection);
    if (section.isErr) return Err<ChildLocalSession?>(section.failureOrNull!);
    final map = section.valueOrNull;
    return Ok<ChildLocalSession?>(map == null ? null : ChildLocalSession.fromMap(map));
  }

  @override
  Future<Result<void>> save(ChildLocalSession session) =>
      _state.writeSection(ChildLocalStateStore.sessionSection, session.toMap());

  @override
  Future<Result<void>> clear() =>
      _state.writeSection(ChildLocalStateStore.sessionSection, null);
}
