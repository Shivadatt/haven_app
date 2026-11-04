import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/family/controllers/child_profile_controller.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/views/pages/child_profile_page.dart';

import 'fakes.dart';

void main() {
  late FakeFamilyRepository repository;
  late List<String> routes;

  Future<void> open(
    WidgetTester tester, {
    String childUserId = 'c1',
    FamilyBundle? bundle,
    FakeFamilyRepository? repo,
  }) async {
    routes = <String>[];
    repository = repo ?? FakeFamilyRepository(bundle: bundle);
    Get.put<ChildProfileController>(
      ChildProfileController(
        childUserId: childUserId,
        repository: repository,
        goTo: (String route, Object? _) => routes.add(route),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const ChildProfilePage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
  }) async {
    final Finder action = find.descendant(
      of: find.byType(buttonType),
      matching: find.text(label),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('the child is named and the device gap is shown', (tester) async {
    await open(tester, bundle: bundle(children: [child('c1', 'Ivy')]));

    expect(find.text('Ivy'), findsOneWidget);
    expect(find.text('Child'), findsOneWidget);
    // The refusal is the repository's own sentence, not copy written for this
    // screen: the F6 citation has to reach the parent.
    expect(find.textContaining('Haven cannot show this child'), findsOneWidget);
    expect(find.textContaining('00-status-register.md:86'), findsOneWidget);
  });

  testWidgets('removal names the missing grant instead of offering a button', (
    tester,
  ) async {
    await open(tester, bundle: bundle(children: [child('c1', 'Ivy')]));

    expect(find.text('Removing Ivy'), findsOneWidget);
    // The words are the repository's own, so the evidence reaches the screen —
    // and there is no control a parent could tap only to be refused.
    expect(
      find.textContaining('no contract for removing a child'),
      findsOneWidget,
    );
    expect(find.text('Remove from this family'), findsNothing);
    expect(repository.lastChildUserId, 'c1');
  });

  testWidgets('the page asks about the child it was opened for', (
    tester,
  ) async {
    await open(
      tester,
      childUserId: 'c2',
      bundle: bundle(children: [child('c1', 'Ivy'), child('c2', 'Kai')]),
    );

    expect(find.text('Removing Kai'), findsOneWidget);
    expect(repository.lastChildUserId, 'c2');
  });

  testWidgets('someone who is not in the family is not shown', (tester) async {
    await open(
      tester,
      childUserId: 'c9',
      bundle: bundle(children: [child('c1', 'Ivy')]),
    );

    expect(find.text('Ivy'), findsNothing);
    expect(find.textContaining('not in your family'), findsOneWidget);

    await press(tester, 'Back to family');
    expect(routes, [AppRoutes.family]);
  });

  testWidgets('no family at all falls to the same honest empty state', (
    tester,
  ) async {
    await open(tester);

    expect(find.textContaining('not in your family'), findsOneWidget);
  });
}
