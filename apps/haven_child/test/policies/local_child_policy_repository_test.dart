import 'package:flutter_test/flutter_test.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_offline/haven_offline.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/data/local_child_policy_repository.dart';

import 'fakes.dart';

void main() {
  late InMemoryLocalStore store;
  late ChildLocalStateStore state;
  late LocalChildPolicyRepository repo;

  setUp(() {
    store = InMemoryLocalStore();
    state = ChildLocalStateStore(store: store, tables: LocalTables(store));
    repo = LocalChildPolicyRepository(store: store, state: state);
  });

  const sample = PolicyTestFixtures.sampleParentPolicy;
  final ts = PolicyTestFixtures.canonicalTimestamp;
  const docKey = ChildLocalStateStore.documentKey;

  group('Neutral In-Memory Fallback', () {
    test('missing document returns in-memory neutral record', () async {
      final res = await repo.getPolicy();
      expect(res.isOk, isTrue);
      final r = res.valueOrNull!;
      expect(r.provenance, PolicyProvenance.inMemoryNeutral);
      expect(r.isParentSynced, isFalse);
      expect(r.isUnlimitedQuota, isTrue);
      expect(r.policyVersion, isNull);
      expect(r.updatedAt, isNull);
    });

    test('empty database without childLocalState returns neutral', () async {
      await store.save({'schemaVersion': 1, 'tables': <String, Object?>{}});
      final res = await repo.getPolicy();
      expect(res.valueOrNull?.provenance, PolicyProvenance.inMemoryNeutral);
    });

    test('valid childLocalState without policy returns neutral', () async {
      await store.save({'schemaVersion': 1, 'tables': {}, docKey: {'s': 1}});
      final res = await repo.getPolicy();
      expect(res.valueOrNull?.provenance, PolicyProvenance.inMemoryNeutral);
    });

    test('clean read performs zero writes to store', () async {
      await repo.getPolicy();
      expect(store.saves, isEmpty);
      final loaded = await store.load();
      expect(loaded.valueOrNull?.containsKey(docKey), isFalse);
    });

    test('neutral evaluation context provides unlimited daily quota', () {
      final now = DateTime.utc(2026, 11, 20, 10);
      final ctx = ChildPolicyRecord.inMemoryNeutral().toEvaluationContext(
        evaluationTime: now,
      );
      expect(ctx.effectiveDailyLimit, isNull);

      final usage = PolicyUsageSnapshot(
        snapshotDate: now,
        snapshotTime: now,
        startInterval: now,
        endInterval: now,
        totalForegroundMillis: 120000,
        appForegroundMillis: const {'com.example.app': 120000},
        freshness: PolicyUsageFreshness.recent,
        completeness: PolicyUsageCompleteness.complete,
        isPermissionGranted: true,
      );

      final eval = PolicyEvaluator.evaluate(context: ctx, usage: usage);
      expect(eval.dailyQuota.isUnlimited, isTrue);
      expect(eval.dailyQuota.isReached, isFalse);
      expect(eval.dailyQuota.isExceeded, isFalse);
      expect(eval.overallState, PolicyOverallState.allowed);
      expect(
        eval.appEvaluations['com.example.app']?.status,
        AppPolicyStatus.allowed,
      );
    });
  });

  group('Option B Malformed Storage States', () {
    void tMal(String n, Object? val, String d) => test('fails on $n', () async {
      await store.save({'schemaVersion': 1, 'tables': {}, docKey: val});
      expect((await repo.getPolicy()).failureOrNull?.detail, d);
    });

    tMal('state: null', null, 'malformed_child_local_state_null');
    tMal('state: primitive', 'bad', 'malformed_child_local_state_not_map');
    tMal('policy: null', {'policy': null}, 'malformed_policy_section_null');
    tMal('policy: bad', {'policy': 'bad'}, 'malformed_policy_section_not_map');
  });

  group('Parent-Synced Save & Load Round-Trips', () {
    test('saves and loads valid policy preserving quota and instant', () async {
      final saveRes = await repo.saveSyncedPolicy(
        config: sample,
        policyVersion: 2,
        updatedAt: ts,
      );
      expect(saveRes.isOk, isTrue);

      final r = (await repo.getPolicy()).valueOrNull!;
      expect(r.provenance, PolicyProvenance.parentSynced);
      expect(r.isParentSynced, isTrue);
      expect(r.isUnlimitedQuota, isFalse);
      expect(r.policyVersion, 2);
      expect(r.updatedAt, ts);
      expect(r.config.dailyScreenTimeMinutes, 120);
      expect(r.config.schedules.length, 2);
    });

    test('preserves empty schedules list without injecting defaults', () async {
      await repo.saveSyncedPolicy(
        config: sample.copyWith(schedules: const []),
        policyVersion: 1,
        updatedAt: ts,
      );
      final loadRes = await repo.getPolicy();
      expect(loadRes.valueOrNull?.config.schedules, isEmpty);
    });

    test('normalizes non-UTC timestamp to UTC instant', () async {
      final localTime = DateTime.parse('2026-11-20T15:30:00+05:30');
      await repo.saveSyncedPolicy(
        config: sample,
        policyVersion: 1,
        updatedAt: localTime,
      );

      final r = (await repo.getPolicy()).valueOrNull!;
      expect(r.updatedAt?.isUtc, isTrue);
      expect(
        r.updatedAt?.millisecondsSinceEpoch,
        localTime.millisecondsSinceEpoch,
      );
    });

    test('preserves existing tables and other state sections', () async {
      await store.save({
        'schemaVersion': 1,
        'tables': {'profiles': [{'id': 'p1'}]},
        docKey: {'session': {'id': 's1'}, 'onboarding': {'step': 3}},
      });

      await repo.saveSyncedPolicy(
        config: sample,
        policyVersion: 1,
        updatedAt: ts,
      );

      final doc = (await store.load()).valueOrNull!;
      expect(((doc['tables'] as Map)['profiles'] as List).length, 1);
      final stateMap = doc[docKey] as Map<String, Object?>;
      expect((stateMap['session'] as Map)['id'], 's1');
      expect((stateMap['onboarding'] as Map)['step'], 3);
      expect(stateMap.containsKey('policy'), isTrue);
    });
  });

  group('ChildPolicyRecord Invariants', () {
    test('runtime invariant checks for ChildPolicyRecord constructors', () {
      ChildPolicyRecord rec(PolicyProvenance p, int? v, DateTime? u) =>
          ChildPolicyRecord(
            config: sample,
            provenance: p,
            policyVersion: v,
            updatedAt: u,
          );

      for (final (p, v, u) in [
        (PolicyProvenance.parentSynced, 0, ts),
        (PolicyProvenance.parentSynced, 1, null),
        (PolicyProvenance.inMemoryNeutral, 1, null),
        (PolicyProvenance.inMemoryNeutral, null, ts),
      ]) {
        expect(() => rec(p, v, u), throwsArgumentError);
      }
    });
  });
}
