import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/domain/usage_freshness_status.dart';
import 'package:haven_child/features/child_usage/views/widgets/app_usage_list_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/daily_screen_time_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/usage_access_explainer_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/usage_permission_denied_card.dart';

import '../../support/host.dart';

void main() {
  group('UsageAccessExplainerCard', () {
    testWidgets('renders all privacy guarantees and local processing notice', (tester) async {
      await tester.pumpWidget(childHost(const UsageAccessExplainerCard()));
      await tester.pumpAndSettle();

      expect(find.text('About Usage Access'), findsOneWidget);
      expect(find.textContaining('Processed entirely on this device'), findsOneWidget);
      expect(find.textContaining('Cannot read messages, photos'), findsOneWidget);
      expect(find.textContaining('Cannot access camera, microphone'), findsOneWidget);
      expect(find.textContaining('Controlled entirely by Android system settings'), findsOneWidget);
    });
  });

  group('DailyScreenTimeCard', () {
    testWidgets('formats hours and minutes, minutes-only, and zero duration', (tester) async {
      await tester.pumpWidget(childHost(
        const Column(
          children: [
            DailyScreenTimeCard(totalDuration: Duration(hours: 2, minutes: 35)),
            DailyScreenTimeCard(totalDuration: Duration(minutes: 45)),
            DailyScreenTimeCard(totalDuration: Duration.zero),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2h 35m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('0m'), findsOneWidget);
      expect(find.text("Today's Screen Time"), findsNWidgets(3));
    });

    testWidgets('shows delayed freshness notice when status is delayed', (tester) async {
      await tester.pumpWidget(childHost(
        const DailyScreenTimeCard(
          totalDuration: Duration(hours: 1),
          freshness: UsageFreshnessStatus.delayed,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Usage data may be delayed'), findsOneWidget);
    });

    testWidgets('shows empty notice when duration is zero and freshness empty', (tester) async {
      await tester.pumpWidget(childHost(
        const DailyScreenTimeCard(
          totalDuration: Duration.zero,
          freshness: UsageFreshnessStatus.empty,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No device activity recorded yet today'), findsOneWidget);
    });
  });

  group('AppUsageListCard', () {
    testWidgets('renders empty state message when list is empty', (tester) async {
      await tester.pumpWidget(childHost(const AppUsageListCard(appRecords: [])));
      await tester.pumpAndSettle();

      expect(find.text('No application usage recorded today.'), findsOneWidget);
    });

    testWidgets('renders app items with duration and system app badge', (tester) async {
      final records = [
        const UsageAppRecord(
          packageName: 'com.android.settings',
          totalForegroundMillis: 600000, // 10m
          isSystemApp: true,
        ),
        const UsageAppRecord(
          packageName: 'com.example.calculator',
          totalForegroundMillis: 1500000, // 25m
          isSystemApp: false,
        ),
      ];

      await tester.pumpWidget(childHost(AppUsageListCard(appRecords: records)));
      await tester.pumpAndSettle();

      expect(find.text('App Usage'), findsOneWidget);
      expect(find.text('com.android.settings'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget);
      expect(find.text('System App'), findsOneWidget);
      expect(find.text('com.example.calculator'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
    });
  });

  group('UsagePermissionDeniedCard', () {
    testWidgets('invokes onOpenSettings callback when button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(childHost(
        UsagePermissionDeniedCard(
          onOpenSettings: () => tapped = true,
          errorMessage: 'Settings launch test error',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Settings launch test error'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders opening indicator when isOpeningSettings is true', (tester) async {
      await tester.pumpWidget(childHost(
        UsagePermissionDeniedCard(
          onOpenSettings: () {},
          isOpeningSettings: true,
        ),
      ));
      await tester.pump();

      expect(find.text('Opening Settings...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
