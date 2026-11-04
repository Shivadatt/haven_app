import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/permissions/native_device_state.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/views/widgets/device_state_card.dart';
import 'package:haven_core/haven_core.dart';

import '../settings/fakes.dart';
import '../support/host.dart';
import 'fakes.dart';

/// The card a parent reads, against a phone that answers on command.
///
/// The assertions below are mostly about what the card must *not* say: no refusal is
/// shown as a grant, a section the phone failed to answer is not hidden, and nothing
/// in the card is a control — it reports the operating system, and a button here
/// would promise a change this build cannot make.
void main() {
  late FakeNativeDeviceState device;

  Future<void> show(
    WidgetTester tester, {
    Result<DeviceStateReport>? answer,
  }) async {
    device = FakeNativeDeviceState(
      answer ?? Ok<DeviceStateReport>(fullReport()),
    );
    Get.put<SettingsController>(
      SettingsController(
        repository: FakeSettingsRepository(),
        applyTheme: (_) {},
        deviceState: device,
      ),
    );
    // The page hosts this card in a ListView, where it is never height-constrained;
    // the plain test surface is, so it is given the height the page would grant.
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(widgetHost(const DeviceStateCard()));
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('the card says which phone answered and reads as a report', (
    WidgetTester tester,
  ) async {
    await show(tester);

    expect(find.text('What this phone answers'), findsOneWidget);
    expect(find.text('Android 36'), findsOneWidget);
    expect(
      find.textContaining('A paired device answers for itself'),
      findsOneWidget,
    );
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets(
    'an undeclared permission is named as not asked for, not refused',
    (WidgetTester tester) async {
      await show(tester);

      expect(
        find.textContaining('Notifications: Allowed'),
        findsOneWidget,
        reason: 'the one grant the phone gave',
      );
      expect(
        find.textContaining('Microphone: Not asked for in this build'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Camera: Not asked for in this build'),
        findsOneWidget,
      );
    },
  );

  testWidgets('usage access is shown with the mode the phone reported', (
    WidgetTester tester,
  ) async {
    await show(tester);

    expect(
      find.textContaining(
        'Usage access: not allowed (the phone answers: ignored)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('3 services are declared'), findsOneWidget);
  });

  testWidgets('no rule is claimed when the phone withheld the reading', (
    WidgetTester tester,
  ) async {
    await show(tester);

    expect(
      find.textContaining(
        'The phone says this app is not an active device admin',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('will not tell an app that is not its device owner'),
      findsOneWidget,
      reason: 'the restriction question has to stay visibly unanswered',
    );
    expect(
      find.textContaining('rule(s) in force'),
      findsNothing,
      reason: 'a count of rules is the OS answer this phone never gave',
    );
  });

  testWidgets('a location the phone would not report is said as withheld', (
    WidgetTester tester,
  ) async {
    await show(tester);

    expect(find.textContaining('Providers switched on: gps'), findsOneWidget);
    expect(
      find.textContaining('this build is not allowed to ask for one'),
      findsOneWidget,
    );
  });

  testWidgets(
    'one failed section is shown as a refusal with the phone\'s reason',
    (WidgetTester tester) async {
      await show(
        tester,
        answer: Ok<DeviceStateReport>(
          fullReport(
            refused: <String, String>{'location': 'SecurityException'},
          ),
        ),
      );

      expect(
        find.textContaining('This phone would not answer for location'),
        findsOneWidget,
      );
      expect(find.textContaining('(SecurityException)'), findsOneWidget);
      // The other four still read.
      expect(find.textContaining('Usage access'), findsOneWidget);
    },
  );

  testWidgets(
    'a build with no native lane is not shown as a phone that said no',
    (WidgetTester tester) async {
      await show(tester, answer: unavailable(why: 'no channel'));

      expect(find.text('This build has no device-state lane.'), findsOneWidget);
      expect(find.text('Android 36'), findsNothing);
      expect(find.textContaining('would not answer for'), findsNothing);
    },
  );

  testWidgets('the card asks the phone once per load, and never caches', (
    WidgetTester tester,
  ) async {
    await show(tester);
    expect(device.readCount, 1);

    Get.find<SettingsController>().load();
    await tester.pumpAndSettle();

    expect(device.readCount, 2);
  });

  testWidgets('a controller with no lane injected still gives the card an answer '
      'to show', (WidgetTester tester) async {
    // No fake injected, so this is the object the shipping controller uses. A host
    // with no Kotlin side must leave the card on its own not-available wording —
    // silence from the phone is not rendered as a blank card or as a refusal.
    device = FakeNativeDeviceState(unavailable());
    Get.reset();
    Get.put<SettingsController>(
      SettingsController(
        repository: FakeSettingsRepository(),
        applyTheme: (_) {},
      ),
    );
    await tester.pumpWidget(widgetHost(const DeviceStateCard()));
    await tester.pumpAndSettle();

    expect(find.textContaining('no device-state lane to ask'), findsOneWidget);
    expect(find.textContaining('would not answer for'), findsNothing);
    expect(device.readCount, 0, reason: 'the fake was not the lane under test');
  });
}
