import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/onboarding/data/onboarding_repository.dart';

/// The setup steps answered on demand, so the controller's ordering is what is
/// under test rather than the network.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.profileExists = true});

  HavenFailure? roleFailWith;
  HavenFailure? familyFailWith;
  bool profileExists;

  final List<String> calls = [];
  String? lastFamilyName;

  @override
  Future<Result<void>> claimParentRole() async {
    calls.add('role');
    final HavenFailure? failure = roleFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> createFamily({required String name}) async {
    calls.add('family');
    lastFamilyName = name;
    final HavenFailure? failure = familyFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<bool>> hasProfile(String userId) async =>
      Ok<bool>(profileExists);
}
