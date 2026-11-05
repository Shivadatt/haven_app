import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/authentication/controllers/forgot_password_controller.dart';
import 'package:haven_app/features/authentication/controllers/reset_password_controller.dart';
import 'package:haven_app/features/authentication/controllers/verify_email_controller.dart';
import 'package:haven_app/features/authentication/views/pages/forgot_password_page.dart';
import 'package:haven_app/features/authentication/views/pages/reset_password_page.dart';
import 'package:haven_app/features/authentication/views/pages/verify_email_page.dart';

import '../support/fakes.dart';

void main() {
  tearDown(Get.reset);

  group('ForgotPasswordPage Widget Tests', () {
    testWidgets('renders recovery form and validates empty email', (tester) async {
      final controller = ForgotPasswordController();
      Get.put<ForgotPasswordController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ForgotPasswordPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recover password'), findsOneWidget);
      expect(find.text('Request password recovery'), findsOneWidget);

      await tester.tap(find.text('Request password recovery'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an email address.'), findsOneWidget);
    });

    testWidgets('submits email and displays offline recovery note', (tester) async {
      final controller = ForgotPasswordController();
      Get.put<ForgotPasswordController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ForgotPasswordPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text('Request password recovery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Offline recovery note'), findsOneWidget);
      expect(find.text('Reset password locally'), findsOneWidget);
    });
  });

  group('ResetPasswordPage Widget Tests', () {
    testWidgets('renders reset password form with mismatch error', (tester) async {
      final fakeVault = FakeVault();
      final fakeAuth = FakeUserAuth(
        const AuthSession(
          userId: 'parent-1',
          email: 'parent@example.com',
          accessToken: 'local:parent-1',
          role: 'parent',
        ),
      );
      final controller = ResetPasswordController(
        emailHint: 'parent@example.com',
        auth: () => fakeAuth,
        vault: () => fakeVault,
      );
      Get.put<ResetPasswordController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ResetPasswordPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Resetting password for: parent@example.com'), findsOneWidget);

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'ValidPass123!');
      await tester.enterText(textFields.at(1), 'DifferentPass123!');
      await tester.tap(find.text('Save new password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('VerifyEmailPage Widget Tests', () {
    testWidgets('renders email verification status and offline notice', (tester) async {
      final fakeAuth = FakeUserAuth(
        const AuthSession(
          userId: 'u-local-1',
          email: 'parent@haven.local',
          accessToken: 'local:u-local-1',
          role: 'parent',
        ),
      );
      final controller = VerifyEmailController(auth: () => fakeAuth);
      Get.put<VerifyEmailController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const VerifyEmailPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify email'), findsOneWidget);
      expect(find.text('parent@haven.local'), findsOneWidget);

      final button = find.text('Resend verification email');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final resendCard = find.text('Resend response');
      await tester.ensureVisible(resendCard);
      expect(resendCard, findsOneWidget);
    });
  });
}
