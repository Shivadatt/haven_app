import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/app/routes/child_pages.dart';
import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/features/policies/controllers/child_policy_controller.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/data/child_policy_repository.dart';
import 'package:haven_child/features/profile/controllers/profile_controller.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../support/fakes.dart';
import '../child_usage/fake_child_usage_repository.dart';

void main() {
  late FakeChildProfileRepository profileRepo;
  late FakeChildSessionStore sessionStore;
  late _FakePolicyRepo policyRepo;
  late FakeChildUsageRepository usageRepo;
  late ChildPolicyController policyController;

  setUp(() {
    Get.reset();
    profileRepo = FakeChildProfileRepository();
    sessionStore = FakeChildSessionStore();
    policyRepo = _FakePolicyRepo();
    usageRepo = FakeChildUsageRepository();

    profileRepo.profile = Profile(
      id: 'child-1',
      role: ProfileRole.child.wire,
      displayName: 'Sam',
      ageBracket: '8-11',
      createdAt: DateTime.utc(2026, 11, 1),
    );
    sessionStore.session = ChildLocalSession(
      profileId: 'child-1',
      createdAt: DateTime.utc(2026, 11, 1),
    );

    Get.put<DeviceInformation>(const FakeDeviceInformation(), permanent: true);
    Get.put<ChildProfileRepository>(profileRepo, permanent: true);
    Get.put<ChildSessionStore>(sessionStore, permanent: true);

    Get.put<ProfileController>(
      ProfileController(profiles: profileRepo, sessions: sessionStore),
      permanent: true,
    );

    policyController = ChildPolicyController(
      policyRepository: policyRepo,
      usageRepository: usageRepo,
      clock: FixedClock(DateTime(2026, 11, 20, 12)),
    );
    Get.put<ChildPolicyController>(policyController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createApp({String initialRoute = ChildRoutes.profile}) {
    return GetMaterialApp(
      initialRoute: initialRoute,
      getPages: ChildPages.pages,
    );
  }

  testWidgets('profile displays Rules & Limits entry and navigates to policy', (
    tester,
  ) async {
    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    final button = find.widgetWithText(OutlinedButton, 'Rules & Limits');
    await tester.scrollUntilVisible(button, 100);
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Family Rules'), findsOneWidget);
    expect(Get.currentRoute, ChildRoutes.policy);

    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, ChildRoutes.profile);
    expect(find.text('My profile'), findsOneWidget);
  });

  testWidgets('direct navigation to /policy resolves to ChildPolicyPage', (
    tester,
  ) async {
    await tester.pumpWidget(createApp(initialRoute: ChildRoutes.policy));
    await tester.pumpAndSettle();

    expect(find.text('Family Rules'), findsOneWidget);
    expect(Get.currentRoute, ChildRoutes.policy);
  });
}

class _FakePolicyRepo implements ChildPolicyRepository {
  @override
  Future<Result<ChildPolicyRecord>> getPolicy() async =>
      Ok(ChildPolicyRecord.inMemoryNeutral());

  @override
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) async => okVoid();
}
