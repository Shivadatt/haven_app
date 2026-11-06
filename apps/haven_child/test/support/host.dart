import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:haven_child/app/bindings/child_initial_bindings.dart';
import 'package:haven_child/app/routes/child_pages.dart';
import 'package:haven_child/app/theme/child_theme.dart';

/// Every child widget test pumps through the REAL [ChildTheme] — a token that
/// only exists in one brightness is a bug the suite must be able to see
/// (same rule as the parent's `widgetHost`).
Widget childHost(Widget page, {Brightness brightness = Brightness.light}) =>
    GetMaterialApp(
      theme: ChildTheme.light,
      darkTheme: ChildTheme.dark,
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: page,
    );

/// The full route-table host: named routes only, exactly like the shipped
/// app, so tests that press a real button exercise `ChildPages` + the feature
/// bindings instead of a stubbed `onPressed`. Callers must register every
/// seam those bindings `Get.find` BEFORE pumping.
Widget childAppHost({required String initialRoute}) => GetMaterialApp(
  theme: ChildTheme.light,
  initialRoute: initialRoute,
  getPages: ChildPages.pages,
  unknownRoute: ChildPages.unknown,
);

/// Unmounts, lets pending disposals land, then resets every registration —
/// the sequence Agent 2's handoff requires (never call `resetForTests` with
/// a live widget still mounted).
Future<void> unmountAndReset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  ChildInitialBindings.resetForTests();
}

/// Presses a labelled button wherever it lives, scrolling it into view.
Future<void> press(WidgetTester tester, String label) async {
  final Finder action = find.text(label);
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

/// Agent 2's handoff rule: dart:io never completes under fake-async pumps,
/// so every lane that REALLY touches the filesystem (`ChildDatabase.openAt`,
/// `ChildDataResetter.clearAll`, path_provider) is driven inside
/// `tester.runAsync` with duration-based pumps instead of `pumpAndSettle`.
Future<void> settleIo(WidgetTester tester, {int iterations = 20}) =>
    tester.runAsync(() async {
      for (var i = 0; i < iterations; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));
      }
    });

/// [press] for buttons whose handler performs real dart:io. No
/// `pumpAndSettle` inside — the IO loop replaces it.
Future<void> pressIo(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await settleIo(tester);
  await tester.pump();
}

/// Renders [page] at a small phone size. Every narrow-screen case in the
/// suite funnels through this so the 320x568 promise is tested, not hoped.
/// `settle: false` skips `pumpAndSettle` — required while an honest loading
/// spinner (an infinite animation) is on screen.
Future<void> pumpNarrow(
  WidgetTester tester,
  Widget page, {
  double width = 320,
  double height = 568,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
