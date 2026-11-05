import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/controllers/verify_email_controller.dart';

import '../support/fakes.dart';

void main() {
  group('VerifyEmailController', () {
    test('loads account email and role from session', () async {
      final auth = FakeUserAuth(
        const AuthSession(
          userId: 'user-42',
          email: 'guardian@example.com',
          accessToken: 'local:42',
          role: 'guardian',
        ),
      );
      final controller = VerifyEmailController(auth: () => auth);
      await controller.loadAccount();

      expect(controller.userEmail.value, equals('guardian@example.com'));
      expect(controller.userRole.value, equals('guardian'));
      expect(controller.accountStatus.value, contains('Local'));
    });

    test('resend verification explicitly notes offline mode and no email sent', () async {
      final auth = FakeUserAuth(null);
      final controller = VerifyEmailController(auth: () => auth);
      await controller.resendVerification();

      expect(controller.resendFeedback.value, contains('offline-first'));
      expect(controller.resendFeedback.value, contains('No email was dispatched'));
    });

    test('navigates to dashboard', () {
      String? routed;
      final controller = VerifyEmailController(
        auth: () => FakeUserAuth(null),
        goTo: (route, arg) => routed = route,
      );
      controller.continueToDashboard();
      expect(routed, equals(AppRoutes.dashboard));
    });
  });
}
