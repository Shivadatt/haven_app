import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/account/controllers/account_controller.dart';
import 'package:haven_app/features/account/data/account_repository.dart';
import 'package:haven_app/features/account/views/pages/account_page.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

void main() {
  const profile = Profile(id: 'u1', role: 'parent', displayName: 'Rae');
  final AccountInfo info = AccountInfo(
    userId: 'u1',
    email: 'parent@example.invalid',
    profile: profile,
  );

  late List<String> routes;
  late FakeAccountRepository repository;

  Future<void> open(
    WidgetTester tester, {
    AccountInfo? forAccount,
    FakeAccountRepository? repo,
  }) async {
    routes = <String>[];
    repository = repo ?? FakeAccountRepository(info: forAccount ?? info);
    Get.put<AccountController>(
      AccountController(
        repository: repository,
        goTo: (String route, Object? _) => routes.add(route),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const AccountPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
  }) async {
    final Finder action = find.descendant(
      of: find.byType(buttonType),
      matching: find.text(label),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('the name is shown before it is ever edited', (tester) async {
    await open(tester);

    expect(find.text('Rae'), findsOneWidget);
    expect(find.textContaining('parent@example.invalid'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
  });

  testWidgets('every ability with no contract says so', (tester) async {
    await open(tester);

    // The page renders whatever the repository's BlockedFailure names, so the
    // gap text here comes from the fake seam: proof the screen has no invented
    // copy and no dead button of its own.
    expect(
      find.textContaining('no contract for password change'),
      findsOneWidget,
    );
    expect(find.textContaining('no contract for email change'), findsOneWidget);
    expect(
      find.textContaining('no contract for account deletion'),
      findsOneWidget,
    );
  });

  testWidgets('saving sends the edited name', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextFormField), 'Rae Rivera');
    await press(tester, 'Save name');

    expect(repository.lastDisplayName, 'Rae Rivera');
  });

  testWidgets('an account with no record is offered setup, not a dead form', (
    tester,
  ) async {
    await open(
      tester,
      forAccount: const AccountInfo(userId: 'u1', email: 'p@example.invalid'),
    );

    expect(find.text('Save name'), findsNothing);
    await press(tester, 'Set up Haven');

    expect(routes, [AppRoutes.onboarding]);
  });

  testWidgets('signing out is confirmed first', (tester) async {
    await open(tester);

    await press(tester, 'Sign out', buttonType: OutlinedButton);
    expect(find.text('Sign out of Haven?'), findsOneWidget);

    await press(tester, 'Cancel', buttonType: TextButton);
    expect(repository.calls.contains('signOut'), isFalse);
    expect(routes, isEmpty);
  });

  testWidgets('confirming signs out and explains where the parent landed', (
    tester,
  ) async {
    await open(tester);

    await press(tester, 'Sign out', buttonType: OutlinedButton);
    await press(tester, 'Sign out');

    expect(repository.calls, contains('signOut'));
    expect(routes, [AppRoutes.sessionEnded]);
  });
}
