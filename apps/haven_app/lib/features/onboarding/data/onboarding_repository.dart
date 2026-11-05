import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

/// What first-run setup can actually do with the approved backend surface.
abstract interface class OnboardingRepository {
  Future<Result<void>> claimParentRole();
  Future<Result<void>> createFamily({required String name});
  Future<Result<bool>> hasProfile(String userId);
  Future<Result<String>> createChild({
    required String name,
    required String ageGroup,
    String? avatar,
  });
}

final class EdgeOnboardingRepository implements OnboardingRepository {
  EdgeOnboardingRepository({
    required EdgeCaller Function() edge,
    required ProfileStore Function() profiles,
  }) : _edge = edge,
       _profiles = profiles;

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

  @override
  Future<Result<String>> createChild({
    required String name,
    required String ageGroup,
    String? avatar,
  }) async => blocked(
    'EdgeOnboardingRepository cannot create a child in cloud mode',
    requirement: 'Child creation via edge functions is not available in cloud mode.',
  );

  static String? _familyNameProblem(String value) {
    if (value.isEmpty) return 'Give your family a name.';
    if (value.length > 80) return 'Use 80 characters or fewer.';
    return null;
  }
}
