import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'child_profile_repository.dart';

/// [ChildProfileRepository] over the reused offline engine's `profiles` table.
///
/// Duplicate prevention uses BOTH mechanisms the brief allows:
/// * an explicit existence check before creating (the create-once rule is a
///   child-lane product rule, stricter than the cloud constraint), and
/// * `LocalConstraints`' unique rule on `profiles.id`, so even a race between
///   two in-memory callers is rejected by the engine as a [BackendFailure]
///   instead of becoming a second row or an overwrite.
///
/// Reads refuse rows this lane did not write: a `profiles` row whose role is
/// not `child` is reported honestly rather than shown as the child's profile.
final class LocalChildProfileRepository implements ChildProfileRepository {
  LocalChildProfileRepository(this._tables, {this.clock = systemClock});

  final LocalTables _tables;
  final Clock clock;

  static const String _table = TableName.profiles;

  @override
  Future<Result<Profile?>> read() async {
    final found = await _tables.first(_table);
    if (found.isErr) return Err<Profile?>(found.failureOrNull!);
    final row = found.valueOrNull;
    if (row == null) return const Ok<Profile?>(null);
    final profile = Profile.fromRow(row);
    if (profile.profileRole != ProfileRole.child) {
      return const Err<Profile?>(
        BackendFailure(
          'The stored profile on this device is not a child profile. Nothing was changed.',
          detail: 'child_profile_role_mismatch',
        ),
      );
    }
    return Ok<Profile?>(profile);
  }

  @override
  Future<Result<Profile>> create({
    required String displayName,
    String? ageBracket,
    String? avatar,
  }) async {
    final trimmed = displayName.trim();
    final invalid = validateDisplayName(trimmed);
    if (invalid != null) {
      return Err<Profile>(ValidationFailure(invalid, field: 'display_name'));
    }
    final existing = await read();
    if (existing case Err<Profile?>()) {
      return Err<Profile>(existing.failureOrNull!);
    }
    if (existing.valueOrNull != null) {
      return const Err<Profile>(
        ValidationFailure(
          'A child profile already exists on this device, so nothing was created.',
          detail: 'child_profile_create_once',
          field: 'display_name',
        ),
      );
    }
    final now = clock.now().toIso8601String();
    final row = <String, Object?>{
      'id': LocalIds.create(),
      'role': ProfileRole.child.wire,
      'display_name': trimmed,
      if (ageBracket != null && ageBracket.isNotEmpty) 'age_bracket': ageBracket,
      if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      'created_at': now,
      'updated_at': now,
    };
    final inserted = await _tables.insert(_table, row);
    if (inserted.isErr) return Err<Profile>(inserted.failureOrNull!);
    return Ok(Profile.fromRow(row));
  }

  @override
  Future<Result<Profile>> update({
    required String id,
    String? displayName,
    String? ageBracket,
    String? avatar,
  }) async {
    final existing = await read();
    if (existing case Err<Profile?>()) {
      return Err<Profile>(existing.failureOrNull!);
    }
    final current = existing.valueOrNull;
    if (current == null || current.id != id) {
      return const Err<Profile>(
        ValidationFailure(
          'There is no child profile to update on this device yet.',
          detail: 'child_profile_missing',
          field: 'id',
        ),
      );
    }
    final patch = <String, Object?>{};
    if (displayName != null) {
      final trimmed = displayName.trim();
      final invalid = validateDisplayName(trimmed);
      if (invalid != null) {
        return Err<Profile>(ValidationFailure(invalid, field: 'display_name'));
      }
      patch['display_name'] = trimmed;
    }
    if (ageBracket != null) patch['age_bracket'] = ageBracket;
    if (avatar != null) patch['avatar'] = avatar;
    if (patch.isEmpty) return Ok(current);
    patch['updated_at'] = clock.now().toIso8601String();
    final done = await _tables.update(_table, patch, eq: <String, Object?>{'id': id});
    if (done.isErr) return Err<Profile>(done.failureOrNull!);
    final reread = await read();
    if (reread.isErr) return Err<Profile>(reread.failureOrNull!);
    return Ok(reread.valueOrNull ?? current);
  }
}
