import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/features/policies/controllers/child_policy_controller.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/data/child_policy_repository.dart';
import 'package:haven_child/features/policies/views/child_policy_page.dart';
import 'package:haven_child/features/policies/views/widgets/daily_quota_card.dart';
import 'package:haven_child/features/policies/views/widgets/policy_disclosure_card.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../child_usage/fake_child_usage_repository.dart';

void main() {
  late _FakePolicyRepo policyRepo;
  late FakeChildUsageRepository usageRepo;
  late ChildPolicyController controller;

  setUp(() {
    Get.reset();
    policyRepo = _FakePolicyRepo();
    usageRepo = FakeChildUsageRepository();
  });

  tearDown(() {
    Get.reset();
  });

  void startController() {
    controller = ChildPolicyController(
      policyRepository: policyRepo,
      usageRepository: usageRepo,
      clock: FixedClock(DateTime(2026, 11, 20, 14)),
    );
    Get.put<ChildPolicyController>(controller);
  }

  Widget createPage() => const GetMaterialApp(home: ChildPolicyPage());

  testWidgets('renders loading state initially', (tester) async {
    final completer = Completer<Result<ChildPolicyRecord>>();
    policyRepo.gate = completer;
    startController();
    await tester.pumpWidget(createPage());
    await tester.pump();
    expect(find.text('Loading device rules…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(Ok(ChildPolicyRecord.inMemoryNeutral()));
    await tester.pumpAndSettle();
  });

  testWidgets('renders neutral policy when load completes without pairing', (
    tester,
  ) async {
    startController();
    await tester.pumpWidget(createPage());
    await tester.pumpAndSettle();
    expect(find.text('Neutral Rules'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text(PolicyDisclosureCard.defaultDisclosure), findsOneWidget);
  });

  testWidgets('renders parent-synced rules and unconfirmed quota notice', (
    tester,
  ) async {
    policyRepo.result = Ok(
      ChildPolicyRecord.parentSynced(
        config: const PolicyConfig(
          dailyScreenTimeMinutes: 120,
          schedules: [],
          allowedApps: ['com.example.docs'],
          blockedApps: ['com.example.bad'],
          appLimits: {'com.example.video': 45},
          allowedDomains: ['study.org'],
          blockedDomains: ['evil.com'],
          safeSearchEnabled: true,
        ),
        policyVersion: 2,
        updatedAt: DateTime(2026, 11, 20, 9),
      ),
    );
    startController();
    await tester.pumpWidget(createPage());
    await tester.pumpAndSettle();
    expect(find.text('Active Family Rules'), findsOneWidget);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text(DailyQuotaCard.unconfirmedNotice), findsOneWidget);
    expect(find.text('com.example.bad'), findsOneWidget);
    expect(find.text('evil.com'), findsOneWidget);
  });

  testWidgets(
    'failed reload suspends active policy and shows diagnostic note',
    (tester) async {
      policyRepo.result = Ok(
        ChildPolicyRecord.parentSynced(
          config: const PolicyConfig(
            dailyScreenTimeMinutes: 120,
            schedules: [],
            allowedApps: [],
            blockedApps: [],
            appLimits: {},
            allowedDomains: [],
            blockedDomains: [],
            safeSearchEnabled: true,
          ),
          policyVersion: 4,
          updatedAt: DateTime(2026, 11, 20, 8),
        ),
      );
      startController();
      await tester.pumpWidget(createPage());
      await tester.pumpAndSettle();
      expect(find.text('Active Family Rules'), findsOneWidget);

      policyRepo.result = const Err(StorageFailure('Corrupt storage disk'));
      await controller.loadPolicy();
      await tester.pumpAndSettle();

      expect(
        find.text('Rule Check Failed — Active Policy Suspended'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Last verified version on record: v4'),
        findsOneWidget,
      );
      expect(find.text('Active Family Rules'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    },
  );

  testWidgets('safe refresh triggers load and evaluate when ready', (
    tester,
  ) async {
    startController();
    await tester.pumpWidget(createPage());
    await tester.pumpAndSettle();
    expect(find.text('Neutral Rules'), findsOneWidget);

    policyRepo.loadsCount = 0;
    await tester.tap(find.byTooltip('Refresh rules'));
    await tester.pumpAndSettle();
    expect(policyRepo.loadsCount, 1);
  });
}

class _FakePolicyRepo implements ChildPolicyRepository {
  Result<ChildPolicyRecord>? result;
  Completer<Result<ChildPolicyRecord>>? gate;
  int loadsCount = 0;

  @override
  Future<Result<ChildPolicyRecord>> getPolicy() async {
    loadsCount++;
    if (gate != null) return gate!.future;
    return result ?? Ok(ChildPolicyRecord.inMemoryNeutral());
  }

  @override
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) async => okVoid();
}
