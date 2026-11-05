import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/controllers/forgot_password_controller.dart';

void main() {
  group('ForgotPasswordController', () {
    test('validates bad email without submitting', () async {
      final controller = ForgotPasswordController();
      controller.email.text = 'not-an-email';
      await controller.submit();
      expect(controller.emailError.value, isNotNull);
      expect(controller.isSubmitted.value, isFalse);
    });

    test('valid email displays offline notice without claiming email sent', () async {
      final controller = ForgotPasswordController();
      controller.email.text = 'parent@example.com';
      await controller.submit();
      expect(controller.emailError.value, isNull);
      expect(controller.isSubmitted.value, isTrue);
      expect(controller.feedbackMessage.value, contains('offline mode'));
    });

    test('navigates to sign in', () {
      String? routed;
      final controller = ForgotPasswordController(
        goTo: (route, arg) => routed = route,
      );
      controller.goToSignIn();
      expect(routed, equals(AppRoutes.signIn));
    });
  });
}
