import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  late LocalTables tables;
  late InMemoryLocalStore store;

  Map<String, Object?> family(String id, {String name = 'F'}) => {
    'id': id,
    'name': name,
  };

  setUp(() {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
  });

  group('read semantics match FakeRowReader parity', () {
    test('every eq pair must match; unknown table is a typed failure', () async {
      await tables.insert(TableName.families, family('f1'));
      final hit = await tables.rows(
        TableName.families,
        eq: {'id': 'f1', 'name': 'F'},
      );
      expect(hit.valueOrNull!.length, 1);
      final miss = await tables.rows(
        TableName.families,
        eq: {'id': 'f1', 'name': 'Other'},
      );
      expect(miss.valueOrNull, isEmpty);
      final unknown = await tables.rows('parental_controls');
      expect(unknown.isErr, isTrue);
      expect(unknown.failureOrNull, isA<ValidationFailure>());
    });

    test('orderDesc is newest-first and limit caps', () async {
      for (final day in ['2026-01-01', '2026-01-03', '2026-01-02']) {
        await tables.insert(TableName.auditLogs, <String, Object?>{
          'id': day,
          'created_at': day,
        });
      }
      final ordered = await tables.rows(
        TableName.auditLogs,
        orderDesc: 'created_at',
        limit: 2,
      );
      expect(
        ordered.valueOrNull!.map((r) => r['created_at']).toList(),
        ['2026-01-03', '2026-01-02'],
      );
    });

    test('first returns null on no match, not an error', () async {
      final none = await tables.first(TableName.families, eq: {'id': 'ghost'});
      expect(none.isOk, isTrue);
      expect(none.valueOrNull, isNull);
    });
  });

  group('durability across reopen', () {
    test('rows written through one store reopen in another', () async {
      final dir = Directory.systemTemp.createTempSync('haven_local_tables');
      addTearDown(() => dir.deleteSync(recursive: true));
      final first = LocalTables(FileLocalStore(dir.path));
      await first.insert(TableName.families, family('f1'));
      final second = LocalTables(FileLocalStore(dir.path));
      expect(
        (await second.first(TableName.families, eq: {'id': 'f1'})).valueOrNull,
        isNotNull,
      );
    });

    test('durability across reopen with same in-memory store', () async {
      await tables.insert(TableName.families, family('f1', name: 'Persisted'));
      final reopened = LocalTables(store);
      final read = await reopened.first(TableName.families, eq: {'id': 'f1'});
      expect(read.valueOrNull?['name'], 'Persisted');
    });

    test('a failed flush keeps rows pending and a retry persists them', () async {
      final mem = InMemoryLocalStore();
      mem.failNextSave = true;
      final t = LocalTables(mem);
      final refused = await t.insert(TableName.families, family('f1'));
      expect(refused.isErr, isTrue);
      expect((await t.insert(TableName.families, family('f2'))).isOk, isTrue);
      expect((await t.count(TableName.families)).valueOrNull, 2);
    });
  });

  group('demo isolation helpers', () {
    test('demoRows and userRows partition any row set with demo or is_demo', () {
      final rows = [
        <String, Object?>{'id': 'a', 'demo': true},
        <String, Object?>{'id': 'b', 'is_demo': true},
        <String, Object?>{'id': 'c'},
        <String, Object?>{'id': 'd', 'demo': false},
        <String, Object?>{'id': 'e', 'is_demo': false},
      ];
      expect(LocalQueries.demoRows(rows).map((r) => r['id']), ['a', 'b']);
      expect(LocalQueries.userRows(rows).map((r) => r['id']), ['c', 'd', 'e']);
    });

    test('clearDemoData deletes demo rows and keeps user rows across tables', () async {
      await tables.insert(TableName.families, {...family('f1'), 'demo': true});
      await tables.insert(TableName.families, {...family('f2'), 'is_demo': true});
      await tables.insert(TableName.families, family('f3'));
      await tables.insert(TableName.profiles, {
        'id': 'p1',
        'is_demo': true,
        'display_name': 'Demo Parent',
      });
      await tables.insert(TableName.profiles, {
        'id': 'p2',
        'display_name': 'Real Parent',
      });

      expect((await tables.count(TableName.families)).valueOrNull, 3);
      expect((await tables.count(TableName.profiles)).valueOrNull, 2);

      final cleared = await tables.clearDemoData();
      expect(cleared.isOk, isTrue);

      final families = await tables.rows(TableName.families);
      expect(families.valueOrNull!.map((r) => r['id']).toList(), ['f3']);

      final profiles = await tables.rows(TableName.profiles);
      expect(profiles.valueOrNull!.map((r) => r['id']).toList(), ['p2']);

      final reopened = LocalTables(store);
      expect((await reopened.count(TableName.families)).valueOrNull, 1);
      expect((await reopened.count(TableName.profiles)).valueOrNull, 1);
    });

    test('removeDemoData and clearDemoRows aliases match clearDemoData', () async {
      await tables.insert(TableName.families, {...family('f1'), 'demo': true});
      await tables.insert(TableName.families, family('f2'));
      expect((await tables.removeDemoData()).isOk, isTrue);
      expect((await tables.count(TableName.families)).valueOrNull, 1);

      await tables.insert(TableName.families, {...family('f3'), 'is_demo': true});
      expect((await tables.clearDemoRows()).isOk, isTrue);
      expect((await tables.count(TableName.families)).valueOrNull, 1);
    });
  });

  group('reset all data', () {
    test('resetAll safely clears all local tables and persists', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.profiles, {'id': 'p1', 'display_name': 'Ada'});
      expect((await tables.count(TableName.families)).valueOrNull, 1);
      expect((await tables.count(TableName.profiles)).valueOrNull, 1);

      final reset = await tables.resetAll();
      expect(reset.isOk, isTrue);

      expect((await tables.count(TableName.families)).valueOrNull, 0);
      expect((await tables.count(TableName.profiles)).valueOrNull, 0);

      final reopened = LocalTables(store);
      expect((await reopened.count(TableName.families)).valueOrNull, 0);
      expect((await reopened.count(TableName.profiles)).valueOrNull, 0);
    });
  });
}
