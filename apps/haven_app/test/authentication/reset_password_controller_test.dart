import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/authentication/controllers/reset_password_controller.dart';

import '../support/fakes.dart';

void main() {
  group('ResetPasswordController', () {
    late FakeVault vault;
    late FakeUserAuth auth;

    setUp(() {
      vault = FakeVault();
      auth = FakeUserAuth(
        const AuthSession(
          userId: 'parent-1',
          email: 'parent@example.com',
          accessToken: 'local:parent-1',
          role: 'parent',
        ),
      );
    });

    test('validates password matching', () async {
      final controller = ResetPasswordController(
        emailHint: 'parent@example.com',
        auth: () => auth,
        vault: () => vault,
      );
      controller.newPassword.text = 'secret123';
      controller.confirmPassword.text = 'secret999';
      await controller.submit();
      expect(controller.confirmError.value, contains('match'));
      expect(controller.isSuccess.value, isFalse);
    });

    test('validates short password length', () async {
      final controller = ResetPasswordController(
        emailHint: 'parent@example.com',
        auth: () => auth,
        vault: () => vault,
      );
      controller.newPassword.text = '123';
      controller.confirmPassword.text = '123';
      await controller.submit();
      expect(controller.passwordError.value, isNotNull);
      expect(controller.isSuccess.value, isFalse);
    });

    test('updates local password in vault successfully', () async {
      final controller = ResetPasswordController(
        emailHint: 'parent@example.com',
        auth: () => auth,
        vault: () => vault,
      );
      controller.newPassword.text = 'newSecurePass123';
      controller.confirmPassword.text = 'newSecurePass123';
      await controller.submit();
      expect(controller.isSuccess.value, isTrue);
      expect(controller.statusMessage.value, contains('updated successfully'));
      expect(await vault.read('local_auth.parent@example.com'), equals('newSecurePass123'));
    });

    test('fails gracefully when vault is unavailable', () async {
      vault.available = false;
      final controller = ResetPasswordController(
        emailHint: 'parent@example.com',
        auth: () => auth,
        vault: () => vault,
      );
      controller.newPassword.text = 'newSecurePass123';
      controller.confirmPassword.text = 'newSecurePass123';
      await controller.submit();
      expect(controller.isSuccess.value, isFalse);
      expect(controller.statusMessage.value, contains('unavailable'));
    });
  });
}
