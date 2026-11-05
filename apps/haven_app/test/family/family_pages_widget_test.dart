import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/family/controllers/child_create_controller.dart';
import 'package:haven_app/features/family/controllers/family_invite_controller.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/family/views/pages/child_create_page.dart';
import 'package:haven_app/features/family/views/pages/family_invite_page.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('ChildCreatePage Widget Tests', () {
    testWidgets('renders child create form and validates empty name', (tester) async {
      final repo = FakeFamilyRepository(bundle: bundle());
      final controller = ChildCreateController(repository: repo);
      Get.put<ChildCreateController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ChildCreatePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add child'), findsOneWidget);
      expect(find.text('Child details'), findsOneWidget);
      expect(find.text('Create profile'), findsOneWidget);

      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name for the child.'), findsOneWidget);
    });

    testWidgets('fills child name, selects bracket and avatar, then submits', (tester) async {
      final repo = FakeFamilyRepository(bundle: bundle());
      final controller = ChildCreateController(
        repository: repo,
        goTo: (route, arg) {},
      );
      Get.put<ChildCreateController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ChildCreatePage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Maya');
      await tester.tap(find.text('8–11 yrs'));
      await tester.tap(find.text('🐼'));
      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();

      expect(repo.lastChildName, equals('Maya'));
      expect(repo.lastAgeBracket, equals('8–11'));
      expect(repo.lastAvatar, equals('🐼'));
    });
  });

  group('FamilyInvitePage Widget Tests', () {
    testWidgets('renders invite form and shows pending invitations', (tester) async {
      final reader = FakeRowReader({
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
      final writer = FakeRowWriter();
      final auth = FakeUserAuth(
        const AuthSession(
          userId: 'parent-1',
          email: 'parent@example.com',
          accessToken: 'local:parent-1',
        ),
      );

      final scopeReader = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final controller = FamilyInviteController(
        scopeReader: () => scopeReader,
        rows: () => reader,
        writer: () => writer,
      );
      Get.put<FamilyInviteController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const FamilyInvitePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Family invitations'), findsOneWidget);
      expect(find.text('Invite co-parent or guardian'), findsOneWidget);
      expect(find.text('Pending invitations'), findsOneWidget);
      expect(find.text('coparent@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
