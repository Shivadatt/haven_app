import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/family/controllers/child_profile_controller.dart';
import 'package:haven_app/features/family/controllers/family_controller.dart';
import 'package:haven_app/features/family/views/pages/child_profile_page.dart';
import 'package:haven_app/features/family/views/pages/family_page.dart';

import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('Child Profile Management', () {
    test('FamilyController.addChild adds child and refreshes bundle', () async {
      final repo = FakeFamilyRepository(bundle: bundle(children: []));
      final controller = FamilyController(repository: repo);
      await controller.load();
      expect(controller.family.value!.valueOrNull!.children, isEmpty);

      final result = await controller.addChild(
        name: 'Ivy',
        ageBracket: '8–11',
        avatar: '🦊',
      );

      expect(result.isOk, isTrue);
      expect(controller.family.value!.valueOrNull!.children.length, 1);
      expect(controller.family.value!.valueOrNull!.children.first.name, 'Ivy');
    });

    test('ChildProfileController updateProfile updates name and reloads', () async {
      final repo = FakeFamilyRepository(
        bundle: bundle(children: [child('c1', 'Ivy', ageBracket: '4–7', avatar: '🦊')]),
      );
      final controller = ChildProfileController(childUserId: 'c1', repository: repo);
      await controller.load();
      expect(controller.person.value!.valueOrNull!.name, 'Ivy');

      final ok = await controller.updateProfile(
        name: 'Ivy Updated',
        ageBracket: '8–11',
        avatar: '🦁',
      );

      expect(ok, isTrue);
      expect(controller.person.value!.valueOrNull!.name, 'Ivy Updated');
      expect(controller.person.value!.valueOrNull!.ageBracket, '8–11');
      expect(controller.person.value!.valueOrNull!.avatar, '🦁');
    });

    test('ChildProfileController removeChild unlinks child and navigates back', () async {
      final nav = <String>[];
      final repo = FakeFamilyRepository(
        bundle: bundle(children: [child('c1', 'Ivy')]),
      );
      // Fake that unlinking succeeds locally
      repo.unlinkFailWith = null;
      repo.blockedWith = null;

      final controller = ChildProfileController(
        childUserId: 'c1',
        repository: repo,
        goTo: (String route, Object? _) => nav.add(route),
      );
      await controller.load();

      final ok = await controller.removeChild();
      expect(ok, isTrue);
      expect(repo.calls, contains('unlinkChild'));
      expect(nav, contains('/family'));
    });

    testWidgets('ChildProfilePage shows avatar, age bracket and edit button', (tester) async {
      final repo = FakeFamilyRepository(
        bundle: bundle(children: [child('c1', 'Ivy', ageBracket: '8–11', avatar: '🦊')]),
      );
      Get.put<ChildProfileController>(
        ChildProfileController(childUserId: 'c1', repository: repo),
      );

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const ChildProfilePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ivy'), findsOneWidget);
      expect(find.text('🦊'), findsOneWidget);
      expect(find.text('Ages 8–11'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('FamilyPage has Add child button that opens dialog', (tester) async {
      final repo = FakeFamilyRepository(bundle: bundle(children: []));
      Get.put<FamilyController>(FamilyController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const FamilyPage()),
      );
      await tester.pumpAndSettle();

      final addButton = find.text('Add child');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Add child profile'), findsOneWidget);
      expect(find.text('Child name'), findsOneWidget);
      expect(find.text('Age bracket'), findsOneWidget);
      expect(find.text('Avatar'), findsOneWidget);
    });
  });
}
