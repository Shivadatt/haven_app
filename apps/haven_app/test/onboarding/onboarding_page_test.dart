import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_app/features/onboarding/views/pages/onboarding_page.dart';
import 'package:haven_core/haven_core.dart';

import '../authentication/fakes.dart';
import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'token',
  );

  late List<String> routes;
  late FakeOnboardingRepository repository;

  Future<void> open(WidgetTester tester) async {
    routes = <String>[];
    repository = FakeOnboardingRepository();
    Get.put<OnboardingController>(
      OnboardingController(
        repository: repository,
        auth: FakeAuthRepository(session: session),
        goTo: (String route, Object? _) => routes.add(route),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const OnboardingPage()),
    );
  }

  /// The copy is long enough that the controls sit below the fold in a test
  /// window, so every tap starts by scrolling its target into view.
  Future<void> press(WidgetTester tester, String label) async {
    final Finder action = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text(label),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> tick(WidgetTester tester) async {
    final Finder box = find.byType(Checkbox);
    await tester.ensureVisible(box);
    await tester.pumpAndSettle();
    await tester.tap(box);
    await tester.pump();
  }

  tearDown(Get.reset);

  testWidgets('the watch list is stated, and the consent gap is admitted', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('What Haven watches'), findsOneWidget);
    expect(
      find.textContaining('does not bypass Android'),
      findsOneWidget,
      reason: '§7C: monitoring is disclosed, not hidden',
    );
    expect(find.textContaining('cannot store a record'), findsOneWidget);
  });

  testWidgets('continuing without reading is refused, not ignored', (
    tester,
  ) async {
    await open(tester);

    await press(tester, 'I understand — continue');

    expect(
      find.text('Tick the box to say you have read this.'),
      findsOneWidget,
    );
    expect(find.text('What Haven watches'), findsOneWidget);
  });

  testWidgets('reading it moves to the family step', (tester) async {
    await open(tester);

    await tick(tester);
    await press(tester, 'I understand — continue');

    expect(find.text('Name your family'), findsOneWidget);
    expect(find.text('Family name'), findsOneWidget);
  });

  testWidgets('the family name goes to the service and the app moves on', (
    tester,
  ) async {
    await open(tester);
    await tick(tester);
    await press(tester, 'I understand — continue');

    await tester.enterText(find.byType(TextFormField).first, 'Rivera household');
    await press(tester, 'Create my family');

    expect(repository.calls, ['role', 'family']);
    expect(repository.lastFamilyName, 'Rivera household');

    // Step 3: Child creation
    expect(find.text('Add your child'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Leo');
    await press(tester, 'Continue to device setup');

    // Step 4: Device setup walkthrough & completion
    expect(find.text('Device setup'), findsOneWidget);
    await press(tester, 'Finish setup');

    expect(routes, [AppRoutes.dashboard]);
  });

  testWidgets('a refused setup says so and stays put', (tester) async {
    await open(tester);
    await tick(tester);
    await press(tester, 'I understand — continue');
    repository.roleFailWith = const BackendFailure(
      'Haven could not record your role.',
      code: 'not_signed_in',
    );

    await tester.enterText(find.byType(TextFormField), 'Rivera');
    await press(tester, 'Create my family');

    expect(find.text('Haven could not record your role.'), findsOneWidget);
    expect(routes, isEmpty);
    expect(find.text('Create my family'), findsOneWidget);
  });
}
