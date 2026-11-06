import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:haven_child/core/permissions/child_permission.dart';
import 'package:haven_child/core/permissions/unconfigured_permission_status_source.dart';
import 'package:haven_child/features/permissions/controllers/permissions_controller.dart';
import 'package:haven_child/features/permissions/views/pages/permissions_page.dart';
import 'package:haven_child/features/permissions/views/widgets/permission_card.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';

/// `/permissions` (brief §7): four cards, all blocked in Stage 1, disabled
/// settings action, 'User action required: No', and a retry path for the
/// impossible-throw guard.
void main() {
  late FakePermissionStatusSource source;

  tearDown(() => Get.reset());

  Future<void> openPermissions(WidgetTester tester) async {
    // The dashboard is a lazy ListView; a tall test viewport is what lets a
    // "four cards" assertion SEE four cards instead of only the built ones.
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put<PermissionsController>(PermissionsController(source: source));
    await tester.pumpWidget(childHost(const PermissionsPage()));
    await tester.pumpAndSettle();
  }

  /// Collects the wire keys of every card reachable by scrolling — the
  /// narrow-screen equivalent of "four cards" on a viewport that can only
  /// ever show one at a time.
  Future<Set<String>> scrollThroughWires(WidgetTester tester) async {
    final wires = <String>{};
    for (var i = 0; i < 12 && wires.length < ChildPermission.values.length; i++) {
      for (final card
          in tester.widgetList<PermissionCard>(find.byType(PermissionCard))) {
        wires.add(card.state.permission.wire);
      }
      await tester.drag(find.byType(ListView), const Offset(0, -240));
      await tester.pump();
    }
    return wires;
  }

  group('with the shipped unconfigured source', () {
    setUp(() => source = FakePermissionStatusSource());

    testWidgets('exactly four cards, keyed by the permission wires', (tester) async {
      await openPermissions(tester);
      expect(find.byType(PermissionCard), findsNWidgets(4));
      for (final permission in ChildPermission.values) {
        expect(
          find.byKey(ValueKey(permission.wire)),
          findsOneWidget,
          reason: 'card for ${permission.wire}',
        );
      }
      expect(source.callCount, 4);
    });

    testWidgets('no card can read granted: all fall back to Unavailable', (
      tester,
    ) async {
      await openPermissions(tester);
      expect(
        find.text(UnconfiguredPermissionStatusSource.cardStatusLabel),
        findsNWidgets(4),
      );
      expect(find.text('Granted'), findsNothing);
      expect(find.text('Not granted'), findsNothing);
      expect(
        find.byKey(const ValueKey('permission-unavailable')),
        findsNWidgets(4),
      );
    });

    testWidgets('the settings action is visibly dead with its own explanation', (
      tester,
    ) async {
      await openPermissions(tester);
      final settings = find.widgetWithText(OutlinedButton, 'Open device settings');
      expect(settings, findsNWidgets(4));
      for (final element in settings.evaluate()) {
        final button = element.widget as OutlinedButton;
        expect(button.onPressed, isNull); // disabled — no faked functionality
      }
      expect(
        find.text(UnconfiguredPermissionStatusSource.settingsActionNote),
        findsNWidgets(4),
      );
      expect(find.text('User action required: No'), findsNWidgets(4));
      expect(
        find.text('No permission has been requested.'),
        findsOneWidget,
      );
    });

    testWidgets('each card repeats the WHY copy the child read in setup', (
      tester,
    ) async {
      await openPermissions(tester);
      for (final permission in ChildPermission.values) {
        expect(find.text(permission.why), findsOneWidget);
        expect(find.text(permission.label), findsOneWidget);
      }
    });
  });

  testWidgets('a real Ok read is the ONLY way Granted can appear', (tester) async {
    source = FakePermissionStatusSource(mode: PermissionFakeMode.realReads);
    await openPermissions(tester);
    expect(find.text('Granted'), findsNWidgets(4));
    expect(find.byKey(const ValueKey('permission-real-read')), findsNWidgets(4));
    // Even then the action stays disabled until a settings lane exists.
    final settings = find.widgetWithText(OutlinedButton, 'Open device settings');
    for (final element in settings.evaluate()) {
      expect((element.widget as OutlinedButton).onPressed, isNull);
    }
  });

  testWidgets('a source that breaks the no-throw rule is REPORTED, with retry', (
    tester,
  ) async {
    source = FakePermissionStatusSource(mode: PermissionFakeMode.throws);
    await openPermissions(tester);
    expect(find.textContaining('The permission list could not be loaded'), findsOneWidget);
    await press(tester, 'Try again');

    source = FakePermissionStatusSource();
    Get.reset();
    await openPermissions(tester);
    expect(find.byType(PermissionCard), findsNWidgets(4));
  });

  testWidgets('the dashboard fits a 320x568 phone', (tester) async {
    source = FakePermissionStatusSource();
    Get.put<PermissionsController>(PermissionsController(source: source));
    await pumpNarrow(tester, childHost(const PermissionsPage()));
    expect(tester.takeException(), isNull);
    // One card fits at a time on the small phone — scroll to meet all four.
    expect(
      await scrollThroughWires(tester),
      ChildPermission.values.map((p) => p.wire).toSet(),
    );
    expect(find.text('User action required: No'), findsWidgets);
  });
}
