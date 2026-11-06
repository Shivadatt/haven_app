import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/permissions/child_permission.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_database.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/device/controllers/device_info_controller.dart';
import 'package:haven_child/features/device/views/pages/device_page.dart';
import 'package:haven_child/features/permissions/controllers/permissions_controller.dart';
import 'package:haven_child/features/permissions/views/pages/permissions_page.dart';
import 'package:haven_child/features/permissions/views/widgets/permission_card.dart';
import 'package:haven_child/features/profile/controllers/profile_controller.dart';
import 'package:haven_child/features/profile/views/pages/profile_page.dart';
import 'package:haven_child/features/splash/controllers/splash_controller.dart';
import 'package:haven_child/features/splash/views/pages/splash_page.dart';

import '../support/fakes.dart';
import '../support/host.dart';
import '../features/onboarding/driver.dart';

/// Brief §7 "narrow-screen layout/overflow test (320x568 on each screen)":
/// every shipped screen at the smallest plausible phone, no RenderFlex
/// overflow tolerated (a thrown overflow error surfaces via takeException).
void main() {
  final driver = OnboardingDriver();
  tearDown(() => Get.reset());

  void smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('welcome step, long honest sentences and all', (tester) async {
    smallPhone(tester);
    await driver.open(tester);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('About-you step: chips wrap, field fits', (tester) async {
    smallPhone(tester);
    await driver.open(
      tester,
      seed: const OnboardingDraft(
        stepIndex: 1,
        displayName: 'A very long child name indeed',
      ),
    );
    // Field-scoped: the hint node is part of the TextField tree, so a bare
    // find.text('Your first name') would count label + hint on this screen.
    expect(find.widgetWithText(TextField, 'Your first name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('device review step stays readable at 320 wide', (tester) async {
    smallPhone(tester);
    await driver.open(
      tester,
      seed: const OnboardingDraft(
        stepIndex: 2,
        displayName: 'Ada',
        ageBracket: '8-11',
      ),
    );
    expect(find.text('This device'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish step at 320 wide', (tester) async {
    smallPhone(tester);
    await driver.open(
      tester,
      seed: const OnboardingDraft(
        stepIndex: 4,
        displayName: 'Ada',
        ageBracket: '8-11',
      ),
    );
    expect(find.text('All set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permission dashboard: four blocked cards, wrapped labels', (
    tester,
  ) async {
    Get.put<PermissionsController>(
      PermissionsController(source: FakePermissionStatusSource()),
    );
    await pumpNarrow(tester, childHost(const PermissionsPage()));
    // The ListView builds only what fits on 320x568 — scroll to meet every
    // card; each one must carry its own 'User action required: No' line.
    final wires = <String>{};
    var actionLines = 0;
    for (var i = 0; i < 12 && wires.length < ChildPermission.values.length; i++) {
      for (final card
          in tester.widgetList<PermissionCard>(find.byType(PermissionCard))) {
        if (wires.add(card.state.permission.wire)) {
          expect(find.text('User action required: No'), findsWidgets);
          actionLines++;
        }
      }
      await tester.drag(find.byType(ListView), const Offset(0, -240));
      await tester.pump();
    }
    expect(actionLines, 4);
    expect(
      wires,
      ChildPermission.values.map((p) => p.wire).toSet(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('device page at 320 wide', (tester) async {
    Get.put<DeviceInfoController>(
      DeviceInfoController(device: const FakeDeviceInformation()),
    );
    await pumpNarrow(tester, childHost(const DevicePage()));
    expect(find.text('Registration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile home at 320 wide, empty and filled', (tester) async {
    final profiles = FakeChildProfileRepository();
    final sessions = FakeChildSessionStore();
    Get.put<ChildProfileRepository>(profiles, permanent: true);
    Get.put<ChildSessionStore>(sessions, permanent: true);
    Get.put<ProfileController>(
      ProfileController(profiles: profiles, sessions: sessions),
    );
    await pumpNarrow(tester, childHost(const ProfilePage()));
    expect(find.text('Start setup'), findsOneWidget);

    profiles.profile = Profile(
      id: 'p1',
      role: ProfileRole.child.wire,
      displayName: 'A very long child name indeed for a 320 pixel phone',
      ageBracket: '8-11',
      createdAt: DateTime.utc(2026, 11, 6),
    );
    sessions.session = ChildLocalSession(
      profileId: 'p1',
      createdAt: DateTime.utc(2026, 11, 6),
    );
    await Get.find<ProfileController>().load();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('boot failure text wraps on the small phone', (tester) async {
    Get.put<SplashController>(
      SplashController(
        openStorage: () async => Err<ChildDatabase>(
          const StorageFailure('The stored local data is damaged and was not overwritten.',
              detail: 'local_database_corrupt: not an object'),
        ),
        resetStorage: () async => okVoid(),
        profileRepository: () => FakeChildProfileRepository(),
        sessionStore: () => FakeChildSessionStore(),
        navigate: (_) {},
      ),
    );
    await pumpNarrow(tester, childHost(const SplashPage()));
    expect(find.text('The app could not start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
