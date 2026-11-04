import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/device_pairing/data/pairing_models.dart';

import '../support/data_fakes.dart';
import 'pairing_harness.dart';

/// The one reachable half of pairing: `pairing_requests` is SELECT-able, so the
/// board is real. Everything else in this file is a refusal, and a refusal has to
/// say which grant is missing.
void main() {
  group('load', () {
    test('reads this family\'s requests, newest first, one page', () async {
      final harness = Harness(
        tables: pairingTables(
          requests: [
            requestRow('r1', 'c1', createdAt: '2026-11-01T09:00:00.000Z'),
            requestRow('r2', 'c2', createdAt: '2026-11-02T09:00:00.000Z'),
            otherFamilyRow('r3'),
          ],
        ),
      );

      final PairingBoard board = (await harness.subject.load()).valueOrNull!;

      expect(board.familyId, familyId);
      expect(harness.rows.lastTable, TableName.pairingRequests);
      expect(harness.rows.filters.last, {'family_id': familyId});
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, PairingBoard.window);
      // r3 belongs to another family: the filter, not this code, keeps it out,
      // so the test checks the id list rather than trusting the count.
      expect(board.lines.map((PairingLine l) => l.request.id), ['r2', 'r1']);
    });

    test(
      'names children from the family read, not from the request row',
      () async {
        final harness = Harness(
          tables: pairingTables(requests: [requestRow('r1', 'c2')]),
        );

        final PairingBoard board = (await harness.subject.load()).valueOrNull!;

        expect(board.lines.single.childName, 'Kai');
        expect(board.familyName, 'Rivera');
      },
    );

    test('a child id with no family row is said to be unrecognised', () async {
      final harness = Harness(
        tables: pairingTables(requests: [requestRow('r9', 'c9')]),
      );

      final PairingBoard board = (await harness.subject.load()).valueOrNull!;

      expect(
        board.lines.single.childName,
        'A child who is not in your family list',
      );
    });

    test('no requests is an answer, not a failure', () async {
      final board = (await Harness().subject.load()).valueOrNull!;

      expect(board.hasLines, isFalse);
      expect(board.counted, '0 requests read, none waiting.');
    });

    test(
      'a family with no pairing rows still tells the truth about waiting',
      () async {
        final harness = Harness(
          tables: pairingTables(
            requests: [
              requestRow('r1', 'c1'),
              requestRow(
                'r2',
                'c2',
                status: 'approved',
                respondedAt: '2026-11-01T09:05:00.000Z',
              ),
            ],
          ),
        );

        final PairingBoard board = (await harness.subject.load()).valueOrNull!;

        expect(board.counted, '2 requests read, 1 waiting on the child.');
        expect(board.firstWaiting?.request.id, 'r1');
      },
    );

    test('an account with no family reads nothing at all', () async {
      final harness = Harness(
        tables: {TableName.familyMembers: const <Map<String, Object?>>[]},
      );

      expect((await harness.subject.load()).valueOrNull, isNull);
      expect(harness.rows.readTables, [TableName.familyMembers]);
    });

    test('a refused request read stays a failure', () async {
      final harness = Harness(
        withRows: FakeRowReader(
          pairingTables(requests: [requestRow('r1', 'c1')]),
          {TableName.pairingRequests: const NetworkFailure('Offline.')},
        ),
      );

      expect(
        (await harness.subject.load()).failureOrNull,
        isA<NetworkFailure>(),
      );
    });

    test(
      'a refused family read does not become a board of unnamed rows',
      () async {
        final harness =
            Harness(tables: pairingTables(requests: [requestRow('r1', 'c1')]))
              ..names.loadFailWith = const PermissionFailure(
                'Row-level security refused.',
              );

        expect(
          (await harness.subject.load()).failureOrNull,
          isA<PermissionFailure>(),
        );
      },
    );
  });

  group('the three writes', () {
    test('an invite names the RPC lane and the uncast body', () async {
      final HavenFailure failure =
          (await Harness().subject.createInvite()).failureOrNull!;

      expect(failure, isA<BlockedFailure>());
      expect(
        (failure as BlockedFailure).missing,
        contains('create_pairing_invite'),
      );
      expect(failure.missing, contains('auth_exec=false'));
      expect(failure.missing, contains('capture-20261030.json'));
    });

    test('a code cites the same wall plus the deny-all token table', () async {
      final BlockedFailure failure =
          (await Harness().subject.redeemCode()).failureOrNull!
              as BlockedFailure;

      expect(failure.missing, contains('create_pairing_request'));
      expect(failure.missing, contains('device_pairing_tokens'));
      expect(failure.missing, contains('04-rls-matrix.md:44'));
    });

    test('a withdrawal cites the missing UPDATE grant', () async {
      final BlockedFailure failure =
          (await Harness().subject.cancel('r1')).failureOrNull!
              as BlockedFailure;

      expect(failure.missing, contains('04-rls-matrix.md:132'));
      expect(failure.message, contains('withdraw a pairing request'));
    });

    test('none of them touches the row plane', () async {
      final harness = Harness();

      await harness.subject.createInvite();
      await harness.subject.redeemCode();
      await harness.subject.cancel('r1');

      expect(harness.rows.readTables, isEmpty);
    });
  });
}
