import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/authentication/controllers/sign_in_controller.dart';
import 'package:haven_app/features/authentication/views/pages/sign_in_page.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'token',
  );

  /// The page title and the button share the words, so the button is always
  /// found by its own type.
  Finder action() => find.descendant(
    of: find.byType(FilledButton),
    matching: find.text('Sign in'),
  );

  List<String> routes = [];

  Future<void> open(
    WidgetTester tester, {
    FakeAuthRepository? repository,
  }) async {
    routes = <String>[];
    Get.put<SignInController>(
      SignInController(
        repository: repository ?? FakeAuthRepository(session: session),
        goTo: (String route, Object? _) => routes.add(route),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const SignInPage()),
    );
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'parent@example.invalid',
    );
    await tester.enterText(find.byType(TextField).last, 'hunter2hunter2');
    await tester.pump();
  }

  tearDown(Get.reset);

  testWidgets('email, password, one action — and no unapproved provider', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(action(), findsOneWidget);
    expect(
      find.textContaining('Sign in with Google'),
      findsNothing,
      reason: 'the Firebase bridge is not approved, so it is not offered',
    );
  });

  testWidgets('an empty submit names the field and sends nothing', (
    tester,
  ) async {
    final repository = FakeAuthRepository(session: session);
    await open(tester, repository: repository);

    await tester.tap(action());
    await tester.pumpAndSettle();

    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(repository.calls, isEmpty);
    expect(routes, isEmpty);
  });

  testWidgets('a successful sign-in leaves the screen', (tester) async {
    final repository = FakeAuthRepository(session: session);
    await open(tester, repository: repository);
    await fill(tester);

    await tester.tap(action());
    await tester.pumpAndSettle();

    expect(routes, [AppRoutes.onboarding]);
    expect(repository.calls, ['signIn', 'profileFor']);
  });

  testWidgets('a rejected sign-in keeps the parent on the form', (
    tester,
  ) async {
    await open(
      tester,
      repository: FakeAuthRepository(
        failWith: const AuthFailure('Email or password is not recognised.'),
      ),
    );
    await fill(tester);

    await tester.tap(action());
    await tester.pumpAndSettle();

    expect(find.text('Email or password is not recognised.'), findsOneWidget);
    expect(routes, isEmpty);
  });

  testWidgets('revealing the password is the parent’s choice', (tester) async {
    await open(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
  });
}
