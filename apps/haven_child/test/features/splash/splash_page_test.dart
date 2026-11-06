import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/core/storage/child_data_resetter.dart';
import 'package:haven_child/core/storage/child_database.dart';
import 'package:haven_child/features/splash/controllers/splash_controller.dart';
import 'package:haven_child/features/splash/views/pages/splash_page.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';
import '../../support/storage.dart';

/// Boot-screen states are rendered through the real theme: pending boot,
/// honest failure + retry, and the corrupt-only developer reset (brief §7
/// loading/error states; "no silent reset").
void main() {
  late List<String> navigated;
  late String dir;

  setUp(() {
    navigated = [];
    dir = StorageTestLane.createTempDirectory();
  });

  tearDown(() async {
    Get.reset();
    StorageTestLane.deleteTemp(dir);
  });

  SplashController put({
    Future<Result<ChildDatabase>> Function()? openStorage,
    Future<Result<void>> Function()? resetStorage,
  }) {
    final controller = SplashController(
      openStorage: openStorage ?? () => ChildDatabase.openAt(dir),
      resetStorage: resetStorage ?? () async => okVoid(),
      profileRepository: () => FakeChildProfileRepository(),
      sessionStore: () => FakeChildSessionStore(),
      navigate: navigated.add,
    );
    Get.put<SplashController>(controller);
    return controller;
  }

  testWidgets('a pending boot shows the loading frame, nothing more', (tester) async {
    final gate = Completer<Result<ChildDatabase>>();
    put(openStorage: () => gate.future);
    await tester.pumpWidget(childHost(const SplashPage()));
    await tester.pump();

    expect(find.text('Starting Haven Child…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    gate.complete(Err<ChildDatabase>(const StorageFailure('done testing')));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed boot is honest: the message and a retry, no reset button', (
    tester,
  ) async {
    var attempts = 0;
    put(
      openStorage: () async {
        attempts++;
        if (attempts == 1) {
          return Err<ChildDatabase>(
            const StorageFailure('The local data could not be read.'),
          );
        }
        return ChildDatabase.openAt(dir); // the retry genuinely re-opens
      },
    );
    await tester.pumpWidget(childHost(const SplashPage()));
    await tester.pumpAndSettle();

    expect(find.text('The app could not start'), findsOneWidget);
    expect(find.text('The local data could not be read.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // The reset is corrupt-damage-only; a plain I/O error must not offer it.
    expect(find.text('Reset local data (developer)'), findsNothing);

    // The retry performs real dart:io, so it rides the runAsync lane.
    await pressIo(tester, 'Try again');
    expect(attempts, 2);
    expect(navigated, [ChildRoutes.onboarding]);
  });

  testWidgets('a CORRUPT document offers the explicit developer reset', (tester) async {
    StorageTestLane.writeRawDocument(dir, 'this is not json{');
    var resets = 0;
    put(
      resetStorage: () async {
        resets++;
        // The real exit hatch, exactly what the binding wires up.
        return ChildDataResetter.clearAll(
          directoryPath: dir,
          verifyReadableFirst: false,
        );
      },
    );
    // Both the failed open and the reset touch the real filesystem: the
    // loading pumps go through the runAsync IO lane (Agent 2's handoff).
    await tester.pumpWidget(childHost(const SplashPage()));
    await settleIo(tester);

    expect(find.textContaining('deliberately NOT been reset'), findsOneWidget);
    await pressIo(tester, 'Reset local data (developer)');

    expect(resets, 1);
    expect(navigated, [ChildRoutes.onboarding]);
    expect(find.text('The app could not start'), findsNothing);
  });

  testWidgets('a failed reset keeps the failure visible and stays off the app', (
    tester,
  ) async {
    put(
      openStorage: () async => Err<ChildDatabase>(
        const StorageFailure('damaged', detail: 'local_database_corrupt: x'),
      ),
      resetStorage: () async =>
          const Err<void>(StorageFailure('The reset could not be written.')),
    );
    await tester.pumpWidget(childHost(const SplashPage()));
    await tester.pumpAndSettle();

    await press(tester, 'Reset local data (developer)');
    expect(find.text('The reset could not be written.'), findsOneWidget);
    expect(navigated, isEmpty);
  });

  testWidgets('the boot frame fits a 320x568 phone', (tester) async {
    final gate = Completer<Result<ChildDatabase>>();
    put(openStorage: () => gate.future);
    // settle: false — the pending boot's spinner is an infinite animation.
    await pumpNarrow(tester, childHost(const SplashPage()), settle: false);
    expect(tester.takeException(), isNull);
    gate.complete(Err<ChildDatabase>(const StorageFailure('end of test')));
    await tester.pumpAndSettle();
  });
}
