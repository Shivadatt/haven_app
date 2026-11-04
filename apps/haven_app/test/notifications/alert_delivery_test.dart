import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/notifications/data/alerts_repository.dart';
import 'package:haven_app/features/notifications/services/alert_delivery.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  group('UnregisteredAlertDelivery', () {
    test('refuses to hand a device over, citing the missing column', () async {
      final Result<void> registered = await const UnregisteredAlertDelivery()
          .registerTarget('a-token-shaped-string');

      final HavenFailure? why = registered.failureOrNull;
      expect(why, isA<BlockedFailure>());
      expect(
        (why as BlockedFailure).message,
        'Haven cannot hand this device to the backend for push delivery in this '
        'build yet.',
      );
      // The evidence the reports screen prints and the evidence the seam returns
      // come from the same constant.
      expect(why.missing, HavenAlertsRepository.deliveryMissing);
      expect(why.detail, startsWith('BLOCKED — SPECIFICATION REQUIRED:'));
    });

    test('refuses to withdraw a registration it never made', () async {
      final Result<void> cleared = await const UnregisteredAlertDelivery()
          .clearTarget();

      expect(
        (cleared.failureOrNull! as BlockedFailure).message,
        'Haven cannot withdraw this device from push delivery in this build yet.',
      );
    });

    test(
      'never reports a registered device, whatever was handed to it',
      () async {
        const UnregisteredAlertDelivery delivery = UnregisteredAlertDelivery();
        await delivery.registerTarget('anything');
        await delivery.clearTarget();

        expect(delivery.isRegistered, isFalse);
      },
    );

    test('the refusal is a value, never a thrown error', () async {
      // A screen has no reason to guard against this seam: it answers in `Result`
      // and never claims a subscription was made.
      final List<String> targets = <String>['', 'token-shaped', 'not-a-token'];
      for (final String target in targets) {
        expect(
          await const UnregisteredAlertDelivery().registerTarget(target),
          isA<Err<void>>(),
          reason: 'refusing "$target"',
        );
      }
    });
  });
}
