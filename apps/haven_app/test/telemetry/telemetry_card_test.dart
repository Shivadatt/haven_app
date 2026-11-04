import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/telemetry/controllers/telemetry_controller.dart';
import 'package:haven_app/features/telemetry/data/telemetry_repository.dart';
import 'package:haven_app/features/telemetry/views/widgets/trail_card.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

/// The trail card as the device screen mounts it: no route, no page, one card
/// inside a page that already names a device.
Future<void> open(WidgetTester tester, FakeTelemetryRepository repo) async {
  Get.put<TelemetryController>(TelemetryController(repository: repo));
  await tester.pumpWidget(
    GetMaterialApp(
      theme: HavenTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: const TelemetryCard())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => Get.reset());

  testWidgets('an entry is shown in the backend\'s own words', (tester) async {
    await open(
      tester,
      FakeTelemetryRepository(
        board: trailBoard(lines: [auditLine(eventType: 'zone.created')]),
      ),
    );

    expect(find.text('Recorded as: zone.created'), findsOneWidget);
    expect(find.textContaining('at 2026-11-01T09:00:00.000Z'), findsOneWidget);
    expect(find.textContaining('1 note(s) stored with it'), findsOneWidget);
    expect(find.textContaining('1 entry read'), findsOneWidget);
  });

  testWidgets('a device refusal is shown where a name would have been', (
    tester,
  ) async {
    final BlockedFailure gap =
        blocked<void>('fake: device rows unreadable here').failureOrNull!
            as BlockedFailure;
    await open(
      tester,
      FakeTelemetryRepository(
        board: trailBoard(lines: [auditLine()], deviceGap: gap),
      ),
    );

    expect(
      find.textContaining('fake: device rows unreadable here'),
      findsOneWidget,
    );
  });

  testWidgets('the online question is refused, not guessed at', (tester) async {
    final FakeTelemetryRepository repo = FakeTelemetryRepository(
      board: trailBoard(lines: [auditLine()]),
    );
    await open(tester, repo);

    expect(
      find.textContaining('Haven cannot say whether a device is online'),
      findsOneWidget,
    );
    expect(
      find.textContaining(HavenTelemetryRepository.offlineMissing),
      findsOneWidget,
      reason:
          'the card has to carry the captured evidence, not a summary of it',
    );
  });

  testWidgets('an empty trail is a read that found nothing, not a wall', (
    tester,
  ) async {
    await open(tester, FakeTelemetryRepository(board: trailBoard()));

    expect(
      find.textContaining(
        'Nothing has been recorded for this family that this account is allowed '
        'to see.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a refused read is reported as a refusal', (tester) async {
    await open(tester, FakeTelemetryRepository());

    expect(find.textContaining('fake: no trail read seeded'), findsOneWidget);
  });

  testWidgets('no family says so instead of showing an empty log', (
    tester,
  ) async {
    await open(tester, FakeTelemetryRepository(noFamily: true));

    expect(find.text('No trail to read'), findsOneWidget);
  });

  testWidgets('the card states that it is a snapshot, not a live view', (
    tester,
  ) async {
    await open(
      tester,
      FakeTelemetryRepository(board: trailBoard(lines: [auditLine()])),
    );

    expect(
      find.textContaining(
        'it shows the newest entries at the moment it was '
        'opened',
      ),
      findsOneWidget,
    );
  });
}
