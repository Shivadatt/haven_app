import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/features/policies/controllers/child_policy_controller.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/views/widgets/app_restrictions_card.dart';
import 'package:haven_child/features/policies/views/widgets/daily_quota_card.dart';
import 'package:haven_child/features/policies/views/widgets/policy_disclosure_card.dart';
import 'package:haven_child/features/policies/views/widgets/policy_schedules_card.dart';
import 'package:haven_child/features/policies/views/widgets/policy_status_card.dart';
import 'package:haven_child/features/policies/views/widgets/web_restrictions_card.dart';
import 'package:haven_models/haven_models.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('PolicyDisclosureCard renders exact evaluator disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const PolicyDisclosureCard()));
    expect(find.text(PolicyDisclosureCard.defaultDisclosure), findsOneWidget);
  });

  testWidgets('PolicyStatusCard renders neutral and synced states', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PolicyStatusCard(
          provenance: PolicyProvenance.inMemoryNeutral,
          status: ChildPolicyStatus.ready,
        ),
      ),
    );
    expect(find.text('Neutral Rules'), findsOneWidget);
    expect(find.text('In-memory default'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        PolicyStatusCard(
          provenance: PolicyProvenance.parentSynced,
          status: ChildPolicyStatus.ready,
          policyVersion: 3,
          updatedAt: DateTime(2026, 11, 20, 10, 30),
          overallState: PolicyOverallState.allowed,
          primaryReason: 'All rules permit access',
        ),
      ),
    );
    expect(find.text('Active Family Rules'), findsOneWidget);
    expect(find.text('v3'), findsOneWidget);
    expect(find.text('Allowed'), findsOneWidget);
  });

  testWidgets(
    'DailyQuotaCard renders neutral, midnight, and unconfirmed states',
    (tester) async {
      await tester.pumpWidget(
        wrap(const DailyQuotaCard(configuredMinutes: 1440, isNeutral: true)),
      );
      expect(find.text('Unlimited'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          const DailyQuotaCard(
            configuredMinutes: 120,
            isNeutral: false,
            isExactMidnight: true,
          ),
        ),
      );
      expect(find.text(DailyQuotaCard.midnightNotice), findsOneWidget);
      expect(find.text('0m used'), findsNothing);

      await tester.pumpWidget(
        wrap(
          const DailyQuotaCard(
            configuredMinutes: 90,
            isNeutral: false,
            quota: null,
          ),
        ),
      );
      expect(find.text(DailyQuotaCard.unconfirmedNotice), findsOneWidget);
    },
  );

  testWidgets('DailyQuotaCard renders used and remaining when valid', (
    tester,
  ) async {
    const quota = DailyQuotaEvaluation(
      limitMinutes: 120,
      usedMinutes: 45,
      remainingMinutes: 75,
      isReached: false,
      isExceeded: false,
      isUnavailable: false,
      isUnlimited: false,
    );
    await tester.pumpWidget(
      wrap(
        const DailyQuotaCard(
          configuredMinutes: 120,
          isNeutral: false,
          quota: quota,
        ),
      ),
    );
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('1 hr 15 min'), findsOneWidget);
  });

  testWidgets('PolicySchedulesCard renders schedules with active indicator', (
    tester,
  ) async {
    final schedule = PolicySchedule(
      id: 'bedtime',
      name: 'Bedtime',
      type: PolicyScheduleType.bedtime,
      startTime: '21:00',
      endTime: '07:00',
      days: const [1, 2, 3, 4, 5],
    );
    await tester.pumpWidget(
      wrap(
        PolicySchedulesCard(schedules: [schedule], activeSchedules: [schedule]),
      ),
    );
    expect(find.text('Bedtime'), findsOneWidget);
    expect(find.text('Active now'), findsOneWidget);
    expect(find.text(PolicySchedulesCard.scheduleNotice), findsOneWidget);
  });

  testWidgets(
    'AppRestrictionsCard renders blocked, limits, and allowed exempt',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppRestrictionsCard(
            blockedApps: ['com.example.game'],
            allowedApps: ['com.example.learn'],
            appLimits: {'com.example.video': 30},
          ),
        ),
      );
      expect(find.text('com.example.game'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('30 min limit'), findsOneWidget);
      expect(find.text(AppRestrictionsCard.exemptTitle), findsOneWidget);
      expect(find.text(AppRestrictionsCard.exemptSubtitle), findsOneWidget);
      expect(find.text('com.example.learn'), findsOneWidget);
    },
  );

  testWidgets('WebRestrictionsCard renders SafeSearch, domains, and note', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WebRestrictionsCard(
          safeSearchEnabled: true,
          blockedDomains: ['gambling.com'],
          allowedDomains: ['wikipedia.org'],
        ),
      ),
    );
    expect(find.text('SafeSearch on'), findsOneWidget);
    expect(find.text('gambling.com'), findsOneWidget);
    expect(find.text('wikipedia.org'), findsOneWidget);
    expect(find.text(WebRestrictionsCard.nonEnforcementNotice), findsOneWidget);
  });
}
