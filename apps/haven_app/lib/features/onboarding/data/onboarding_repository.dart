import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

/// What first-run setup can actually do with the approved backend surface.
///
/// `auth-bootstrap` has exactly two actions in the capture — `set_role` and
/// `create_family` — and both are used here and nowhere else. The role is
/// one-time from `unset`, so a repeat is treated as "already set up", and the
/// family name is bounded by `families_name_check` (1..80).
abstract interface class OnboardingRepository {
  Future<Result<void>> claimParentRole();
  Future<Result<void>> createFamily({required String name});

  /// Whether a `profiles` row exists for this account. Provisioning has no
  /// approved implementation, so "no row" is an expected state, not a bug.
  Future<Result<bool>> hasProfile(String userId);
}

final class EdgeOnboardingRepository implements OnboardingRepository {
  EdgeOnboardingRepository({required this._edge, required this._profiles});

  /// Providers, because `HavenBackend.install()` replaces the seams after
  /// construction.
  final EdgeCaller Function() _edge;
  final ProfileStore Function() _profiles;

  factory EdgeOnboardingRepository.live() => EdgeOnboardingRepository(
    edge: () => HavenBackend.edge,
    profiles: () => HavenBackend.profiles,
  );

  static const _alreadySet = 'role_already_set';

  @override
  Future<Result<void>> claimParentRole() async {
    final Result<Map<String, Object?>> reply = dataFrom(
      await _edge().invoke(EdgeFunctionName.authBootstrap, {
        'action': 'set_role',
        'role': 'parent',
      }),
    );
    final HavenFailure? failure = reply.failureOrNull;
    if (failure == null) return okVoid();
    // PE-A02/PE-A04: a role that is already set is not a failure to fix —
    // the account is further along than this screen assumed.
    if (failure is BackendFailure && failure.code == _alreadySet) {
      return okVoid();
    }
    return Err<void>(failure);
  }

  @override
  Future<Result<void>> createFamily({required String name}) async {
    final String trimmed = name.trim();
    final String? invalid = _familyNameProblem(trimmed);
    if (invalid != null) {
      return Err<void>(ValidationFailure(invalid, field: 'family_name'));
    }
    return dataFrom(
      await _edge().invoke(EdgeFunctionName.authBootstrap, {
        'action': 'create_family',
        'name': trimmed,
      }),
    ).map((_) => okVoid(), (failure) => Err<void>(failure));
  }

  @override
  Future<Result<bool>> hasProfile(String userId) async {
    final Result<Map<String, Object?>?> row = await _profiles().load(userId);
    return row.map(
      (Map<String, Object?>? data) => Ok<bool>(data != null),
      (HavenFailure failure) => Err<bool>(failure),
    );
  }

  /// `families.name` is checked at 1..80 in the re-authored schema
  /// (`docs/stage2/migrations/A3-staging-load-v1.sql`, `families_name_check`).
  static String? _familyNameProblem(String value) {
    if (value.isEmpty) return 'Give your family a name.';
    if (value.length > 80) return 'Use 80 characters or fewer.';
    return null;
  }
}
