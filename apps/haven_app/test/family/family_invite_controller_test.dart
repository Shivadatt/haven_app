import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/controllers/family_invite_controller.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  group('FamilyInviteController', () {
    late FakeRowReader reader;
    late FakeRowWriter writer;
    late FakeUserAuth auth;

    setUp(() {
      reader = FakeRowReader({
        TableName.familyMembers: [
          {
            'id': 'mem-owner',
            'family_id': 'fam-1',
            'user_id': 'parent-1',
            'role': 'parent',
            'status': 'active',
          },
          {
            'id': 'mem-invite-1',
            'family_id': 'fam-1',
            'user_id': 'invited-user-1',
            'role': 'co_parent',
            'status': 'invited',
            'created_at': '2026-11-05T10:00:00Z',
          },
        ],
        TableName.profiles: [
          {
            'id': 'invited-user-1',
            'email': 'coparent@example.com',
            'display_name': 'Invited Partner',
          },
        ],
      });
      writer = FakeRowWriter();
      auth = FakeUserAuth(
        const AuthSession(
          userId: 'parent-1',
          email: 'parent@example.com',
          accessToken: 'local:parent-1',
        ),
      );
    });

    test('loads pending invitations correctly', () async {
      final scopeReader = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final controller = FamilyInviteController(
        scopeReader: () => scopeReader,
        rows: () => reader,
        writer: () => writer,
      );

      await controller.loadInvites();

      expect(controller.pendingInvites.length, equals(1));
      expect(controller.pendingInvites.first.email, equals('coparent@example.com'));
      expect(controller.pendingInvites.first.role, equals('co_parent'));
    });

    test('validates email before sending invite', () async {
      final scopeReader = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final controller = FamilyInviteController(
        scopeReader: () => scopeReader,
        rows: () => reader,
        writer: () => writer,
      );

      controller.email.text = 'invalid-email';
      final ok = await controller.sendInvite();

      expect(ok, isFalse);
      expect(controller.emailError.value, isNotNull);
      expect(writer.writtenTables, isEmpty);
    });

    test('sends invitation and records in family_members and profiles', () async {
      final scopeReader = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final controller = FamilyInviteController(
        scopeReader: () => scopeReader,
        rows: () => reader,
        writer: () => writer,
      );

      controller.email.text = 'guardian@example.com';
      controller.selectedRole.value = 'guardian';
      final ok = await controller.sendInvite();

      expect(ok, isTrue);
      expect(writer.writtenTables, contains(TableName.profiles));
      expect(writer.writtenTables, contains(TableName.familyMembers));
      final memberInsert = writer.payloads.last;
      expect(memberInsert['role'], equals('guardian'));
      expect(memberInsert['status'], equals('invited'));
    });

    test('cancels invitation by deleting row from family_members', () async {
      final scopeReader = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final controller = FamilyInviteController(
        scopeReader: () => scopeReader,
        rows: () => reader,
        writer: () => writer,
      );

      final ok = await controller.cancelInvite('mem-invite-1');

      expect(ok, isTrue);
      expect(writer.writtenTables, contains(TableName.familyMembers));
      expect(writer.matchers.last['id'], equals('mem-invite-1'));
    });
  });
}
