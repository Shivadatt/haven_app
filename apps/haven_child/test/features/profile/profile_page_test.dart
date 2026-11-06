import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/features/profile/controllers/profile_controller.dart';
import 'package:haven_child/features/profile/views/pages/profile_page.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';

/// `/profile` home: honest labels, the setup prompt when there is no
/// profile, the half-finished warning, and the error posture.
void main() {
  late FakeChildProfileRepository profiles;
  late FakeChildSessionStore sessions;

  tearDown(() => Get.reset());

  Profile ada() => Profile(
    id: 'p1',
    role: ProfileRole.child.wire,
    displayName: 'Ada',
    ageBracket: '8-11',
    avatar: 'star',
    createdAt: DateTime.utc(2026, 11, 6),
  );

  Future<void> openProfile(WidgetTester tester) async {
    Get.put<ChildProfileRepository>(profiles, permanent: true);
    Get.put<ChildSessionStore>(sessions, permanent: true);
    Get.put<DeviceInformation>(const FakeDeviceInformation(), permanent: true);
    Get.put<ProfileController>(
      ProfileController(profiles: profiles, sessions: sessions),
    );
    await tester.pumpWidget(childHost(const ProfilePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('no profile yet is the setup prompt, not an error', (tester) async {
    profiles = FakeChildProfileRepository();
    sessions = FakeChildSessionStore();
    await openProfile(tester);
    // The custom `empty` builder replaces the generic emptyMessage here.
    expect(find.text('Setup is not finished on this device.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start setup'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('a finished setup reads the child and the honest lines', (tester) async {
    profiles = FakeChildProfileRepository()..profile = ada();
    sessions = FakeChildSessionStore()
      ..session = ChildLocalSession(
        profileId: 'p1',
        createdAt: DateTime.utc(2026, 11, 6),
      );
    await openProfile(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Age group'), findsOneWidget);
    expect(find.text('8-11'), findsOneWidget);
    expect(find.text('On this device since'), findsOneWidget);
    expect(find.text('Parent connection: Not connected'), findsOneWidget);
    expect(find.text('Nothing is monitored yet'), findsOneWidget);
    expect(find.text('Setup not finished yet'), findsNothing);
  });

  testWidgets('a profile without its session warns instead of claiming success', (
    tester,
  ) async {
    profiles = FakeChildProfileRepository()..profile = ada();
    sessions = FakeChildSessionStore(); // setup half-finished
    await openProfile(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profile-setup-incomplete')),
        matching: find.text('Setup not finished yet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a refused read is shown as the refusal, not as empty', (tester) async {
    profiles = FakeChildProfileRepository()
      ..readFailure = const BackendFailure(
        'The stored profile on this device is not a child profile. Nothing was changed.',
        detail: 'child_profile_role_mismatch',
      );
    sessions = FakeChildSessionStore();
    await openProfile(tester);
    expect(find.textContaining('not a child profile'), findsOneWidget);
    expect(find.text('Start setup'), findsNothing);
  });

  testWidgets('a profile with no age bracket renders Unavailable, not blank', (
    tester,
  ) async {
    profiles = FakeChildProfileRepository()
      ..profile = Profile(
        id: 'p1',
        role: ProfileRole.child.wire,
        displayName: 'Ada',
        // createdAt stays set: the ONLY absent field is the age bracket,
        // so exactly one value falls back to 'Unavailable'.
        createdAt: DateTime.utc(2026, 11, 6),
      );
    sessions = FakeChildSessionStore();
    await openProfile(tester);
    expect(find.text('Unavailable'), findsOneWidget);
  });

  testWidgets('the profile home fits a 320x568 phone', (tester) async {
    profiles = FakeChildProfileRepository()..profile = ada();
    sessions = FakeChildSessionStore()
      ..session = ChildLocalSession(
        profileId: 'p1',
        createdAt: DateTime.utc(2026, 11, 6),
      );
    Get.put<ChildProfileRepository>(profiles, permanent: true);
    Get.put<ChildSessionStore>(sessions, permanent: true);
    Get.put<DeviceInformation>(const FakeDeviceInformation(), permanent: true);
    Get.put<ProfileController>(
      ProfileController(profiles: profiles, sessions: sessions),
    );
    await pumpNarrow(tester, childHost(const ProfilePage()));
    expect(tester.takeException(), isNull);
  });
}
