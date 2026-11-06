import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/permissions/permission_status_source.dart';
import 'package:haven_child/core/permissions/unconfigured_permission_status_source.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/local_child_profile_repository.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/device/views/pages/device_page.dart';
import 'package:haven_child/features/onboarding/views/pages/onboarding_page.dart';
import 'package:haven_child/features/permissions/views/pages/permissions_page.dart';
import 'package:haven_child/features/profile/views/pages/profile_page.dart';

import '../support/host.dart';

/// The golden path THROUGH the real route table and the real feature
/// bindings: setup started from an empty profile, completed once, and the
/// child home afterwards — with the in-memory engine standing in for the
/// device file (no dart:io, so no runAsync needed).
void main() {
  tearDown(() => Get.reset());

  void registerSeams() {
    // One shared document, exactly the way ChildDatabase wires it.
    final store = InMemoryLocalStore();
    final tables = LocalTables(store);
    final state = ChildLocalStateStore(store: store, tables: tables);
    Get.put<ChildProfileRepository>(
      LocalChildProfileRepository(tables),
      permanent: true,
    );
    Get.put<OnboardingStateStore>(
      LocalOnboardingStateStore(state),
      permanent: true,
    );
    Get.put<ChildSessionStore>(LocalChildSessionStore(state), permanent: true);
    Get.put<DeviceInformation>(const FakeDeviceInformation(), permanent: true);
    Get.put<PermissionStatusSource>(
      const UnconfiguredPermissionStatusSource(),
      permanent: true,
    );
  }

  Future<void> tap(WidgetTester tester, String label) async {
    // alignment 0.1 parks the target near the TOP of the viewport — the
    // fixed step footer otherwise overlaps a bottom-scrolled chip and the
    // tap silently lands on the button row instead. (`WidgetTester
    // .ensureVisible` takes no alignment; the scrollable call does.)
    final target = find.text(label);
    Scrollable.ensureVisible(tester.element(target), alignment: 0.1);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('empty profile → Start setup → five steps → profile home', (
    tester,
  ) async {
    registerSeams();
    await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.profile));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Setup is not finished on this device.'), findsOneWidget);

    await tap(tester, 'Start setup');
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tap(tester, 'Continue'); // welcome -> About you
    await tester.enterText(find.byType(TextField), 'Ada');
    await tap(tester, '8-11 yrs');
    await tap(tester, 'rocket');
    await tap(tester, 'Continue'); // -> This device
    expect(find.text('Step 3 of 5'), findsOneWidget);
    await tap(tester, 'Continue'); // -> Permissions
    await tap(tester, 'Continue'); // -> All set
    await tap(tester, 'Create my profile');

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Parent connection: Not connected'), findsOneWidget);
    expect(find.text('Nothing is monitored yet'), findsOneWidget);
  });

  testWidgets('re-running the flow after completion cannot create a second profile', (
    tester,
  ) async {
    registerSeams();
    await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.profile));
    await tester.pumpAndSettle();
    await tap(tester, 'Start setup');
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextField), 'Ada');
    await tap(tester, '4-7 yrs');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Create my profile');
    expect(find.byType(ProfilePage), findsOneWidget);

    // A deep re-entry into setup on a finished device (Stage 2 pairing will
    // offer one; the create-once rule must hold regardless): completion
    // notices the EXISTING profile and finishes the session instead.
    Get.toNamed(ChildRoutes.onboarding);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    // The draft was cleared at completion, so this run starts fresh.
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextField), 'Impostor');
    await tap(tester, '8-11 yrs');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Create my profile');

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Impostor'), findsNothing);
    expect((await Get.find<ChildProfileRepository>().read()).valueOrNull!.displayName,
        'Ada');
  });

  testWidgets('profile home links reach device and permissions pages', (
    tester,
  ) async {
    registerSeams();
    await Get.find<ChildProfileRepository>().create(
      displayName: 'Ada',
      ageBracket: '8-11',
    );
    await Get.find<ChildSessionStore>().save(
      ChildLocalSession(profileId: (await Get.find<ChildProfileRepository>().read())
          .valueOrNull!
          .id,
          createdAt: DateTime.utc(2026, 11, 6)),
    );
    await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.profile));
    await tester.pumpAndSettle();

    await tap(tester, 'Device info');
    expect(find.byType(DevicePage), findsOneWidget);
    expect(find.text('Not registered'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tap(tester, 'Permission dashboard');
    expect(find.byType(PermissionsPage), findsOneWidget);
  });

  testWidgets('an unlisted route lands on the honest unknown page', (tester) async {
    registerSeams();
    await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.profile));
    await tester.pumpAndSettle();
    Get.toNamed('/not-built-yet');
    await tester.pumpAndSettle();
    expect(find.text('This screen is not part of the child app yet.'), findsOneWidget);
  });
}
