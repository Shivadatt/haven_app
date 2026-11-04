import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/notifications/data/alerts_models.dart';
import 'package:haven_app/features/notifications/data/alerts_repository.dart';

import 'fakes.dart';
import 'harness.dart';

/// The two walls beside the reports list, checked as the evidence strings the
/// screen prints. They live apart from the read because a read answers with rows
/// and these answer with a refusal, and the two promises break differently.
void main() {
  group('the two refusals the reports screen carries', () {
    test('answering a report is refused, citing the column grants', () async {
      final AlertBoard board = await Harness(
        tables: alertTables(alerts: [alertRow('a1')]),
      ).okBoard();

      expect(
        board.ackGap.message,
        'Haven cannot mark a report as read or answered in this build yet.',
      );
      expect(board.ackGap.missing, contains('acknowledged_at'));
      expect(board.ackGap.missing, contains('acknowledged_by'));
      expect(board.ackGap.missing, contains('04-rls-matrix.md:151-153'));
      expect(board.ackGap.missing, contains(':1102-1103'));
      expect(
        board.ackGap.detail,
        startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
      );
      expect(board.ackGap, same(HavenAlertsRepository.ackGap));
    });

    test('delivery is refused, citing the column that does not exist', () async {
      final AlertBoard board = await Harness(
        tables: alertTables(alerts: [alertRow('a1')]),
      ).okBoard();

      expect(
        board.deliveryGap.message,
        'Haven cannot register this device to be pushed to in this build yet.',
      );
      expect(board.deliveryGap.missing, contains('push_tokens'));
      expect(
        board.deliveryGap.missing,
        contains('A3c-notification-backend.sql'),
      );
      expect(board.deliveryGap.missing, contains('register-token'));
      expect(board.deliveryGap, same(HavenAlertsRepository.deliveryGap));
    });

    test('the two sentences are not the same sentence', () async {
      // A single generic "notifications are blocked" would let a parent read a
      // missing token column as a missing permission.
      expect(
        HavenAlertsRepository.ackMissing,
        isNot(HavenAlertsRepository.deliveryMissing),
      );
      expect(
        HavenAlertsRepository.ackGap.message,
        isNot(HavenAlertsRepository.deliveryGap.message),
      );
    });
  });
}
