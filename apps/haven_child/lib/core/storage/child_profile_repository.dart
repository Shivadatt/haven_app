import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// The single child profile this app owns on this device.
///
/// Contract, in the vocabulary `00-app-contract.md` fixes:
/// * every method answers with `Result<T>`/`HavenFailure` — nothing throws
///   across this boundary;
/// * **create-once**: [create] refuses when a profile row already exists.
///   There is no silent overwrite anywhere in this lane; the caller must use
///   [update] with the id it read;
/// * the row is always `role: 'child'` (`ProfileRole.child.wire`) with a
///   stable `LocalIds.create()` id and a `created_at` stamp from the injected
///   [Clock];
/// * a corrupt stored document surfaces as the typed `StorageFailure`
///   (`local_database_corrupt` detail) the store produced — never a reset.
abstract interface class ChildProfileRepository {
  /// The child profile, or `Ok(null)` when setup has not happened yet.
  Future<Result<Profile?>> read();

  /// Creates the one profile row. `Err(ValidationFailure)` with detail
  /// `child_profile_create_once` when a profile already exists.
  Future<Result<Profile>> create({
    required String displayName,
    String? ageBracket,
    String? avatar,
  });

  /// Patch-style update; a `null` argument means "leave unchanged".
  /// Validation (haven_core `validateDisplayName`) runs here, not in widgets.
  Future<Result<Profile>> update({
    required String id,
    String? displayName,
    String? ageBracket,
    String? avatar,
  });
}
