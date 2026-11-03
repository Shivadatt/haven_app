import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';
import 'package:haven_app/features/settings/views/pages/permission_status_page.dart';

import 'fakes.dart';

void main() {
  late FakeSettingsRepository repository;

  Future<void> open(
    WidgetTester tester, {
    NotificationAccess access = NotificationAccess.denied,
  }) async {
    repository = FakeSettingsRepository(access: access);
    Get.put<SettingsController>(
      SettingsController(repository: repository, applyTheme: (_) {}),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: HavenTheme.light,
        home: const PermissionStatusPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('every permission is named with the reason it is needed', (
    tester,
  ) async {
    await open(tester);

    for (final String name in [
      'Usage access',
      'Location, while in use',
      'Background location',
      'Notifications',
      'Camera and microphone',
    ]) {
      expect(find.text(name), findsOneWidget, reason: '$name is not explained');
    }
    expect(
      find.textContaining('does not turn either one on by itself'),
      findsOneWidget,
    );
  });

  testWidgets('this phone’s own permission is a state, not a promise', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Not allowed'), findsOneWidget);
    expect(
      find.textContaining('does not ask for this phone’s location'),
      findsOneWidget,
    );
  });

  testWidgets('a build with no push backend is not called a refusal', (
    tester,
  ) async {
    await open(tester, access: NotificationAccess.unavailable);

    expect(find.text('Not in this build'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);
  });

  testWidgets('the device list is where the child’s answers live', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('On your child’s phone'), findsOneWidget);
    expect(
      find.textContaining('The device reports these itself'),
      findsOneWidget,
    );
    expect(find.text('Open paired devices'), findsOneWidget);
    // Nothing here pretends to know a device's state.
    expect(find.text('Granted'), findsNothing);
  });
}
