import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'repository_harness.dart';

/// Everything here is a write: the one UPDATE the captured grants allow, and the
/// removal that has no client path at all.
void main() {
  group('rename', () {
    test('writes only the name, scoped to the family I belong to', () async {
      final harness = Harness();

      final Result<void> result = await harness.subject.rename(
        name: '  The Riveras  ',
      );

      expect(result.isOk, isTrue);
      expect(harness.writer.writtenTables, [TableName.families]);
      expect(harness.writer.lastPayload, {'name': 'The Riveras'});
      expect(harness.writer.matchers.single, {'id': familyId});
    });

    test('refuses a name the column would reject, without writing', () async {
      final harness = Harness();

      final HavenFailure failure = (await harness.subject.rename(
        name: 'n' * 81,
      )).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect(harness.writer.writtenTables, isEmpty);
    });

    test('refuses an empty name', () async {
      final harness = Harness();

      expect(
        (await harness.subject.rename(name: '   ')).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(harness.writer.writtenTables, isEmpty);
    });

    test('cannot write before there is a family to write to', () async {
      final harness = Harness(tables: noFamilyTables());

      final HavenFailure failure = (await harness.subject.rename(
        name: 'Rivera',
      )).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect(harness.writer.writtenTables, isEmpty);
    });

    test('surfaces the backend refusing the write', () async {
      final harness = Harness();
      harness.writer.failWith = const PermissionFailure(
        'Row-level security refused.',
      );

      final HavenFailure failure = (await harness.subject.rename(
        name: 'Rivera',
      )).failureOrNull!;

      expect(failure, isA<PermissionFailure>());
    });
  });

  group('unlinkChild', () {
    test('refuses, and names the grant that is missing', () async {
      final harness = Harness();

      final HavenFailure failure = (await harness.subject.unlinkChild(
        'c1',
      )).failureOrNull!;

      expect(failure, isA<BlockedFailure>());
      final String missing = (failure as BlockedFailure).missing;
      expect(missing, contains('auth_exec=false'));
      expect(missing, contains('unlink'));
    });

    test('refuses without writing or calling anything', () async {
      final harness = Harness();

      await harness.subject.unlinkChild('c1');

      expect(harness.writer.writtenTables, isEmpty);
      expect(harness.rows.readTables, isEmpty);
    });
  });
}
