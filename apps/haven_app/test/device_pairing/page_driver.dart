import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_code_controller.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_controller.dart';
import 'package:haven_app/features/device_pairing/views/pages/pairing_code_page.dart';
import 'package:haven_app/features/device_pairing/views/pages/pairing_page.dart';

import 'fakes.dart';

/// How a pairing page test gets onto the page and moves around it.
///
/// [routes] records which verb each navigation used, because "opens on top" and
/// "replaces the stack" are different promises to a parent.
final class PairingDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakePairingRepository repository;

  Future<void> openPairing(
    WidgetTester tester, {
    FakePairingRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakePairingRepository(board: board());
    Get.put<PairingController>(
      PairingController(
        repository: repository,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await pump(tester, const PairingPage());
  }

  Future<void> openCode(
    WidgetTester tester, {
    String familyId = 'f1',
    FakePairingRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakePairingRepository(board: board());
    Get.put<PairingCodeController>(
      PairingCodeController(
        familyId: familyId,
        repository: repository,
        goTo: (String route, Object? arg) => routes.add(('to', route, arg)),
      ),
    );
    await pump(tester, const PairingCodePage());
  }

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: page),
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

  /// The one route the pairing screen is allowed to offer onward to.
  List<String> get pushed => routes.map((r) => r.$2).toList(growable: false);
}
