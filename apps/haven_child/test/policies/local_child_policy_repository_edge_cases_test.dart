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
  const sched = PolicyTestFixtures.bedtimeSchedule;
  final ts = PolicyTestFixtures.canonicalTimestamp;
  const badPkg = 'com.android.calculator2';
  const docKey = ChildLocalStateStore.documentKey;

  const invCfg = 'invalid_policy_config', invPkg = 'invalid_package_name';
  const invRange = 'invalid_app_limit_range', invId = 'invalid_schedule_id';
  const invName = 'invalid_schedule_name', invTime = 'invalid_schedule_time';
  const invDays = 'invalid_schedule_days', invPolVer = 'invalid_policy_version';
  const invOrigin = 'invalid_policy_origin', invTs = 'invalid_policy_timestamp';
  const invVer = 'invalid_envelope_version';
  const invSafe = 'invalid_safe_search_enabled';

  Future<void> seed(Object? p) => store.save({
    'schemaVersion': 1,
    'tables': {},
    docKey: {'policy': p},
  });

  Map<String, Object?> env({
    int ver = 1,
    String o = 'parent_synced',
    int pv = 1,
    Object? up,
    Object? c,
  }) => {
    'envelope_version': ver,
    'origin': o,
    'policy_version': pv,
    'updated_at': up ?? '2026-11-20T10:00:00Z',
    'config': c ?? sample.toJson(),
  };

  Map<String, Object?> envMod(String k, Object? v) => env()..[k] = v;
  Map<String, Object?> envDel(String k) => env()..remove(k);

  Future<dynamic> save(PolicyConfig c, [int v = 1]) =>
      repo.saveSyncedPolicy(config: c, policyVersion: v, updatedAt: ts);

  PolicyConfig cDaily(int m) => sample.copyWith(dailyScreenTimeMinutes: m);
  PolicyConfig cDom(String d) => sample.copyWith(allowedDomains: [d]);
  PolicyConfig cBDom(String d) => sample.copyWith(blockedDomains: [d]);
  PolicyConfig cApp(String a) => sample.copyWith(allowedApps: [a]);
  PolicyConfig cBApp(String a) => sample.copyWith(blockedApps: [a]);
  PolicyConfig cLim(Map<String, int> l) => sample.copyWith(appLimits: l);
  PolicyConfig cSched(PolicySchedule s) => sample.copyWith(schedules: [s]);

  PolicySchedule sId(String id) => sched.copyWith(id: id);
  PolicySchedule sName(String n) => sched.copyWith(name: n);
  PolicySchedule sStart(String st) => sched.copyWith(startTime: st);
  PolicySchedule sEnd(String et) => sched.copyWith(endTime: et);
  PolicySchedule sDays(List<int> d) => sched.copyWith(days: d);
  PolicySchedule sApp(String a) => sched.copyWith(allowedApps: [a]);

  Map<String, Object?> badDaily(int m) =>
      sample.toJson()..['daily_screen_time_limit_minutes'] = m;

  Map<String, Object?> badSec(String sec, String k, Object? v) {
    final j = sample.toJson();
    (j[sec] as Map<String, Object?>)[k] = v;
    return j;
  }

  Map<String, Object?> badWeb(String k, Object? v) =>
      badSec('website_policies', k, v);
  Map<String, Object?> badApp(String k, Object? v) =>
      badSec('app_policies', k, v);

  Map<String, Object?> badSch(String k, Object? v) {
    final j = sample.toJson();
    ((j['schedules'] as List).first as Map<String, Object?>)[k] = v;
    return j;
  }

  void tSave(String n, PolicyConfig c, String d) =>
      test('fails save on $n', () async {
        final res = await save(c);
        expect(res.failureOrNull?.detail, d);
        expect(store.saves, isEmpty);
      });

  void tParse(String n, Map<String, Object?> payload, String d) =>
      test('parser rejects $n', () async {
        await seed(env(c: payload));
        expect((await repo.getPolicy()).failureOrNull?.detail, d);
      });

  void tSch(String n, String k, Object? v, String d) =>
      tParse(n, badSch(k, v), d);

  void tEnv(String n, Map<String, Object?> e, String d) =>
      test('envelope rejects $n', () async {
        await seed(e);
        expect((await repo.getPolicy()).failureOrNull?.detail, d);
      });

  group('Save-Time Validation & Zero-Write Guarantees', () {
    test('fails on invalid policy version <= 0', () async {
      final res = await save(sample, 0);
      expect(res.failureOrNull?.detail, invPolVer);
      final p = (await repo.getPolicy()).valueOrNull?.provenance;
      expect(p, PolicyProvenance.inMemoryNeutral);
      expect(store.saves, isEmpty);
    });

    tSave('daily quota < 0', cDaily(-1), invCfg);
    tSave('daily quota > 1440', cDaily(1441), invCfg);
    tSave('bad allowed dom', cDom('https://b.com'), invCfg);
    tSave('bad blocked dom', cBDom('bad/dom'), invCfg);
    tSave('bad allowed app', cApp('bad!'), invPkg);
    tSave('bad blocked app', cBApp('bad!'), invPkg);
    tSave('bad limit key', cLim({'bad!': 30}), invPkg);
    tSave('bad limit range', cLim({badPkg: 2000}), invRange);
    tSave('empty sched id', cSched(sId('')), invId);
    tSave('empty sched name', cSched(sName(' ')), invName);
    tSave('bad start time', cSched(sStart('25:00')), invTime);
    tSave('bad end time', cSched(sEnd('99:99')), invTime);
    tSave('empty sched days', cSched(sDays([])), invDays);
    tSave('sched day < 1', cSched(sDays([0])), invDays);
    tSave('sched day > 7', cSched(sDays([8])), invDays);
    tSave('bad sched app', cSched(sApp('bad!')), invPkg);

    test('preserves valid policy after failed save', () async {
      await save(sample, 5);
      expect(store.saves.length, 1);
      final res = await save(cApp('bad!'), 6);
      expect(res.failureOrNull?.detail, invPkg);
      expect(store.saves.length, 1);
      expect((await repo.getPolicy()).valueOrNull?.policyVersion, 5);
    });
  });

  group('Persisted JSON Parser Validation', () {
    tParse('quota < 0', badDaily(-1), 'invalid_daily_limit');
    tParse('quota > 1440', badDaily(1441), 'invalid_daily_limit');
    tParse('allow dom', badWeb('allowed_domains', ['https://b.com']), invCfg);
    tParse('blocked dom', badWeb('blocked_domains', ['bad/dom']), invCfg);
    tParse('allow app', badApp('allowed_apps', ['bad!']), invPkg);
    tParse('blocked app', badApp('blocked_apps', ['bad!']), invPkg);
    tParse('app limit key', badApp('app_limits', {'bad!': 30}), invPkg);
    tParse('app limit val', badApp('app_limits', {badPkg: 2000}), invRange);
    tSch('sched id', 'id', '', invId);
    tSch('sched name', 'name', ' ', invName);
    tSch('start time', 'start_time', '25:00', invTime);
    tSch('end time', 'end_time', '99:99', invTime);
    tSch('empty days', 'days', [], invDays);
    tSch('day < 1', 'days', [0], invDays);
    tSch('day > 7', 'days', [8], invDays);
    tSch('whitelist app', 'allowed_apps', ['bad!'], invPkg);
    tSch('non-str type', 'type', 123, 'invalid_schedule_type');
    tSch('unknown type', 'type', 'unknown_type', 'invalid_schedule_type');
    tParse('safe search', badWeb('safe_search_enabled', 'true'), invSafe);
  });

  group('Envelope Validation & Timestamp Edge Cases', () {
    tEnv('missing ver', envDel('envelope_version'), 'missing_envelope_fields');
    tEnv('null ver', envMod('envelope_version', null), invVer);
    tEnv('unsupported ver', env(ver: 2), 'unsupported_envelope_version');
    tEnv('missing origin', envDel('origin'), invOrigin);
    tEnv('null origin', envMod('origin', null), invOrigin);
    tEnv('invalid origin', env(o: 'child_authored'), invOrigin);
    tEnv('missing pol ver', envDel('policy_version'), invPolVer);
    tEnv('null pol ver', envMod('policy_version', null), invPolVer);
    tEnv('non-int pol ver', envMod('policy_version', 'v1'), invPolVer);
    tEnv('zero pol ver', env(pv: 0), invPolVer);
    tEnv('neg pol ver', env(pv: -1), invPolVer);
    tEnv('missing ts', envDel('updated_at'), invTs);
    tEnv('null ts', envMod('updated_at', null), invTs);
    tEnv('non-string ts', env(up: 123456), invTs);
    tEnv('invalid ts string', env(up: 'not-a-date'), invTs);

    test('offset-aware timestamp to UTC', () async {
      await seed(env(up: '2026-11-20T15:30:00+05:30'));
      final r = await repo.getPolicy();
      expect(r.valueOrNull?.updatedAt, DateTime.utc(2026, 11, 20, 10));
    });
  });
}
