import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/family/controllers/family_controller.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/views/pages/family_page.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  late FakeFamilyRepository repository;
  late List<(String, String, Object?)> routes;

  Future<void> open(
    WidgetTester tester, {
    FamilyBundle? bundle,
    FakeFamilyRepository? repo,
  }) async {
    routes = <(String, String, Object?)>[];
    repository = repo ?? FakeFamilyRepository(bundle: bundle);
    Get.put<FamilyController>(
      FamilyController(
        repository: repository,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const FamilyPage()),
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

  testWidgets('the family and everyone in it are shown', (tester) async {
    await open(
      tester,
      bundle: bundle(
        parents: [parent('u1', 'Rae')],
        children: [child('c1', 'Ivy'), childWithoutProfile('c2')],
      ),
    );

    expect(find.text('Rivera'), findsOneWidget);
    expect(find.text('Ivy'), findsOneWidget);
    // A member with no profile row is named by role, never hidden.
    expect(find.text('A child'), findsOneWidget);
    expect(find.textContaining('no name on file'), findsOneWidget);
    expect(find.textContaining('In the family since'), findsWidgets);
    expect(find.textContaining('5/1/2026'), findsWidgets);
  });

  testWidgets('the two abilities with no contract say so', (tester) async {
    await open(tester, bundle: bundle());

    // Rendered from the repository's own BlockedFailure, so the screen cannot
    // carry an invented promise or a dead control of its own.
    expect(
      find.textContaining('no contract for adding a parent'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no contract for removing a parent'),
      findsOneWidget,
    );
  });

  testWidgets('saving sends the edited name', (tester) async {
    await open(tester, bundle: bundle());

    await tester.enterText(find.byType(TextFormField), 'The Riveras');
    await press(tester, 'Save name');

    expect(repository.lastName, 'The Riveras');
  });

  testWidgets('a refused save is read back, not swallowed', (tester) async {
    await open(
      tester,
      repo: FakeFamilyRepository(
        bundle: bundle(),
      )..renameFailWith = const PermissionFailure('Only the owner may rename.'),
    );

    await tester.enterText(find.byType(TextFormField), 'Nope');
    await press(tester, 'Save name');

    expect(find.textContaining('Only the owner may rename'), findsOneWidget);
  });

  testWidgets('a child opens its own page with its id', (tester) async {
    await open(tester, bundle: bundle(children: [child('c1', 'Ivy')]));

    await tester.tap(find.text('Ivy'));
    await tester.pumpAndSettle();

    expect(routes, [('push', AppRoutes.childProfile, 'c1')]);
  });

  testWidgets('a parent row has no chevron, because there is nothing to open', (
    tester,
  ) async {
    await open(tester, bundle: bundle(parents: [parent('u1', 'Rae')]));

    expect(find.text('Rae'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('no family is offered setup instead of an empty form', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Save name'), findsNothing);
    expect(find.textContaining('no family yet'), findsOneWidget);

    await press(tester, 'Set up Haven');

    expect(routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a failed read offers a retry, not a blank page', (tester) async {
    await open(
      tester,
      repo: FakeFamilyRepository(bundle: bundle())
        ..loadFailWith = const NetworkFailure('No connection.'),
    );

    expect(find.textContaining('No connection'), findsOneWidget);

    repository.loadFailWith = null;
    await press(tester, 'Try again');

    expect(find.text('Rivera'), findsOneWidget);
  });
}
