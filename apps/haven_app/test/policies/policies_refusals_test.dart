import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/data/policies_models.dart';

import 'fakes.dart';
import 'harness.dart';

/// The two things this screen cannot do, and the evidence each one cites. A
/// third test checks the one place a refusal could leak into the copy: a rule
/// key this build has no specification for.
void main() {
  group('the two refusals the rules screen carries', () {
    test('writing a version is refused with its own evidence', () async {
      final PolicyBoard board = await Harness(
        tables: policyTables(rows: [policyRow('p1')]),
      ).okBoard();

      expect(
        board.writeGap.message,
        'Haven cannot set or change a device\'s rules in this build yet.',
      );
      expect(board.writeGap.missing, contains('04-rls-matrix.md:107-109'));
      expect(board.writeGap.missing, contains('apply_policy_version'));
      expect(
        board.writeGap.detail,
        startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
      );
    });

    test(
      'the shape of a rule set is refused, citing the only CHECK captured',
      () async {
        final PolicyBoard board = await Harness(
          tables: policyTables(rows: [policyRow('p1')]),
        ).okBoard();

        expect(
          board.ruleShapeGap.message,
          'Haven cannot show what the rules in a version say in this build yet.',
        );
        expect(board.ruleShapeGap.missing, contains('jsonb_typeof(policy)'));
        expect(
          board.ruleShapeGap.missing,
          contains('A3-staging-load-v1.sql:454'),
        );
      },
    );

    test(
      'a rule key inside a version is never translated into a claim',
      () async {
        final PolicyBoard board = await Harness(
          tables: policyTables(
            rows: [
              policyRow('p1', policy: const {'sunday_limit_minutes': 0}),
            ],
          ),
        ).okBoard();

        final PolicyLine line = board.lines.single;
        expect(line.policy.policy['sunday_limit_minutes'], 0);
        expect(
          [line.which, line.written, line.outcome, line.statusLabel].join(' '),
          isNot(contains('sunday')),
          reason:
              'a key this build has no specification for must not reach '
              'the screen as a rule the parent can read',
        );
      },
    );
  });
}
