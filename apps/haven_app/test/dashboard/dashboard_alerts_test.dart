import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The reports section on its own, because its three states — read, empty, and
/// unreadable — are the difference between a parent being informed and being
/// falsely reassured.
void main() {
  final driver = DashboardDriver();
  tearDown(Get.reset);

  testWidgets('reports are listed with the backend\'s own severity word', (
    tester,
  ) async {
    await driver.open(
      tester,
      data: driver.sampleData(
        alerts: [
          alert('a1', severity: 'critical', message: 'Battery low'),
          alert('a2', message: 'Left Home'),
        ],
      ),
    );

    expect(find.text('Battery low'), findsOneWidget);
    expect(find.text('Needs attention now'), findsOneWidget);
    expect(find.text('Worth a look'), findsOneWidget);
    expect(find.text('Left Home'), findsOneWidget);
    expect(find.textContaining('2 most recent reports'), findsOneWidget);
  });

  testWidgets('a failed report read is said in its own section', (
    tester,
  ) async {
    await driver.open(
      tester,
      data: driver.sampleData(
        alertsFailure: const NetworkFailure('Could not read.'),
      ),
    );

    // The rest of the page survives: only the section that failed speaks up.
    expect(find.text('Ivy'), findsOneWidget);
    expect(
      find.textContaining('Haven could not read the reports: Could not read.'),
      findsOneWidget,
    );
    expect(
      find.text('Nothing has been reported about this family yet.'),
      findsNothing,
    );
  });

  testWidgets('nothing reported is stated as nothing reported', (tester) async {
    await driver.open(tester, data: driver.sampleData());

    expect(
      find.text('Nothing has been reported about this family yet.'),
      findsOneWidget,
    );
  });

  testWidgets('an unreadable alerts read still refuses on the devices card', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeDashboardRepository(
        data: driver.sampleData(alertsFailure: const NetworkFailure('Gone.')),
      ),
    );

    expect(find.text('fake: no device list'), findsOneWidget);
  });
}
