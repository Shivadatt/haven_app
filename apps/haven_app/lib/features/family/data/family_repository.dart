import 'package:haven_core/haven_core.dart';

import 'family_models.dart';

export 'haven_family_repository.dart';
export 'local_family_repository.dart';

/// The family screen's whole surface.
abstract interface class FamilyRepository {
  /// A null payload is not a failure: it means this account has no family yet,
  /// which is the state first-run setup exists to fix.
  Future<Result<FamilyBundle?>> load();

  Future<Result<void>> rename({required String name});

  /// `unlink_child` exists in the capture, but the role this app signs in as
  /// holds no EXECUTE on it, so the refusal is the honest answer in cloud mode.
  /// Offline, passing `execute: true` unlinks the child in local tables.
  Future<Result<void>> unlinkChild(String childUserId, {bool execute = false});

  Future<Result<void>> inviteParent();

  Future<Result<void>> removeParent();

  Future<Result<void>> createFamily({required String name});

  Future<Result<FamilyPerson>> addChild({
    required String name,
    String? ageBracket,
    String? avatar,
  });

  Future<Result<void>> updateChild({
    required String childUserId,
    required String name,
    String? ageBracket,
    String? avatar,
  });
}
