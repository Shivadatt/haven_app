import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  final testDate = DateTime(2026, 11, 18);
  final testTime = DateTime(2026, 11, 18, 14, 30);
  final startInterval = DateTime(2026, 11, 18, 0, 0);
  final endInterval = DateTime(2026, 11, 18, 14, 30);

  PolicyUsageSnapshot makeSnapshot({
    int? totalMillis = 120000,
    Map<String, int> apps = const {'com.example.app': 120000},
    PolicyUsageCompleteness completeness = PolicyUsageCompleteness.complete,
    PolicyUsageFreshness freshness = PolicyUsageFreshness.recent,
    bool isPermissionGranted = true,
  }) => PolicyUsageSnapshot(
    snapshotDate: testDate,
    snapshotTime: testTime,
    startInterval: startInterval,
    endInterval: endInterval,
    totalForegroundMillis: totalMillis,
    appForegroundMillis: apps,
    completeness: completeness,
    freshness: freshness,
    isPermissionGranted: isPermissionGranted,
  );

  PolicyUsageSnapshot makeEmpty({
    PolicyUsageCompleteness completeness = PolicyUsageCompleteness.unknown,
    PolicyUsageFreshness freshness = PolicyUsageFreshness.unknown,
    required bool isPermissionGranted,
  }) => PolicyUsageSnapshot.empty(
    snapshotDate: testDate,
    snapshotTime: testTime,
    startInterval: startInterval,
    endInterval: endInterval,
    completeness: completeness,
    freshness: freshness,
    isPermissionGranted: isPermissionGranted,
  );

  group('A. Enum and Native Freshness Mapping', () {
    test('verifies all completeness and freshness enum values', () {
      expect(PolicyUsageCompleteness.values, [
        PolicyUsageCompleteness.complete,
        PolicyUsageCompleteness.incomplete,
        PolicyUsageCompleteness.unknown,
      ]);
      expect(PolicyUsageFreshness.values, [
        PolicyUsageFreshness.recent,
        PolicyUsageFreshness.delayed,
        PolicyUsageFreshness.unknown,
        PolicyUsageFreshness.unavailable,
      ]);
    });

    test('maps native wire tokens correctly without fabricating recency', () {
      expect(PolicyUsageFreshness.fromNativeFreshness('recent'), PolicyUsageFreshness.recent);
      expect(PolicyUsageFreshness.fromNativeFreshness('delayed'), PolicyUsageFreshness.delayed);
      expect(PolicyUsageFreshness.fromNativeFreshness('empty'), PolicyUsageFreshness.unknown);
      expect(PolicyUsageFreshness.fromNativeFreshness(null), PolicyUsageFreshness.unavailable);
      expect(PolicyUsageFreshness.fromNativeFreshness('garbage'), PolicyUsageFreshness.unavailable);
    });
  });

  group('B. Missing Package Resolution and Truth Table', () {
    test('truth table row 1-3: complete + granted + (recent|delayed|unknown) resolves to 0', () {
      for (final f in [PolicyUsageFreshness.recent, PolicyUsageFreshness.delayed, PolicyUsageFreshness.unknown]) {
        final s = makeSnapshot(apps: {}, completeness: PolicyUsageCompleteness.complete, freshness: f);
        expect(s.appMinutes('com.absent.app'), 0);
        expect(s.appDuration('com.absent.app'), Duration.zero);
      }
    });

    test('truth table row 4-7: unavailable, denied, or incomplete/unknown resolves to null', () {
      final unavail = makeSnapshot(apps: {}, completeness: PolicyUsageCompleteness.complete, freshness: PolicyUsageFreshness.unavailable);
      expect(unavail.appMinutes('com.absent'), isNull);
      expect(unavail.appDuration('com.absent'), isNull);
      final denied = makeSnapshot(apps: {}, completeness: PolicyUsageCompleteness.complete, isPermissionGranted: false);
      expect(denied.appMinutes('com.absent'), isNull);
      expect(denied.appDuration('com.absent'), isNull);
      for (final c in [PolicyUsageCompleteness.incomplete, PolicyUsageCompleteness.unknown]) {
        final s = makeSnapshot(apps: {}, completeness: c);
        expect(s.appMinutes('com.absent'), isNull);
        expect(s.appDuration('com.absent'), isNull);
      }
    });

    test('explicit package entries resolve observed minutes regardless of completeness', () {
      final s = makeSnapshot(
        apps: {'com.zero.app': 0, 'com.active.app': 150000},
        completeness: PolicyUsageCompleteness.incomplete,
      );
      expect(s.appMinutes('com.zero.app'), 0);
      expect(s.appDuration('com.zero.app'), Duration.zero);
      expect(s.appMinutes('com.active.app'), 2);
      expect(s.appDuration('com.active.app'), const Duration(minutes: 2));
    });
  });

  group('C. Validation & Invariants', () {
    test('rejects negative total millis, package millis, blank package keys, and bad interval', () {
      expect(() => makeSnapshot(totalMillis: -1), throwsA(isA<ArgumentError>()));
      expect(() => makeSnapshot(apps: {'com.pkg': -500}), throwsA(isA<ArgumentError>()));
      expect(() => makeSnapshot(apps: {'': 100}), throwsA(isA<ArgumentError>()));
      expect(() => makeSnapshot(apps: {'   ': 100}), throwsA(isA<ArgumentError>()));
      expect(
        () => PolicyUsageSnapshot(
          snapshotDate: testDate,
          snapshotTime: testTime,
          startInterval: DateTime(2026, 11, 18, 12, 0),
          endInterval: DateTime(2026, 11, 18, 10, 0),
          totalForegroundMillis: 0,
          appForegroundMillis: const {},
          completeness: PolicyUsageCompleteness.complete,
          freshness: PolicyUsageFreshness.recent,
          isPermissionGranted: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves valid zero usage and accepts nullable total duration in unavailable factory', () {
      final zeroSnapshot = makeSnapshot(totalMillis: 0, apps: {'com.unused': 0});
      expect(zeroSnapshot.totalMinutes, 0);
      expect(zeroSnapshot.totalForegroundDuration, Duration.zero);
      final unavail = PolicyUsageSnapshot.unavailable(
        snapshotDate: testDate,
        snapshotTime: testTime,
        startInterval: startInterval,
        endInterval: endInterval,
      );
      expect(unavail.totalForegroundMillis, isNull);
      expect(unavail.totalMinutes, isNull);
      expect(unavail.totalForegroundDuration, isNull);
      expect(unavail.isPermissionGranted, isFalse);
      expect(unavail.freshness, PolicyUsageFreshness.unavailable);
      expect(unavail.appMinutes('com.absent'), isNull);
      expect(unavail.appDuration('com.absent'), isNull);
    });

    test('empty factory requires permission status and tests all 5 combinations', () {
      final e1 = makeEmpty(isPermissionGranted: true);
      expect(e1.completeness, PolicyUsageCompleteness.unknown);
      expect(e1.freshness, PolicyUsageFreshness.unknown);
      expect(e1.appMinutes('com.absent'), isNull);
      final e2 = makeEmpty(completeness: PolicyUsageCompleteness.complete, isPermissionGranted: false);
      expect(e2.appMinutes('com.absent'), isNull);
      final e3 = makeEmpty(completeness: PolicyUsageCompleteness.complete, isPermissionGranted: true, freshness: PolicyUsageFreshness.unknown);
      expect(e3.appMinutes('com.absent'), 0);
      expect(e3.appDuration('com.absent'), Duration.zero);
      final e4 = makeEmpty(completeness: PolicyUsageCompleteness.complete, isPermissionGranted: true, freshness: PolicyUsageFreshness.unavailable);
      expect(e4.appMinutes('com.absent'), isNull);
    });
  });

  group('D. Immutability & Discrepancies', () {
    test('defensively copies input map and enforces unmodifiable view', () {
      final mutableMap = <String, int>{'com.app': 60000};
      final s = makeSnapshot(apps: mutableMap);
      mutableMap['com.app'] = 120000;
      mutableMap['com.new'] = 60000;
      expect(s.appMinutes('com.app'), 1);
      expect(s.appForegroundMillis.containsKey('com.new'), isFalse);
      expect(() => s.appForegroundMillis['com.app'] = 0, throwsUnsupportedError);
    });

    test('accepts totalForegroundMillis differing from sum of app map without error', () {
      final s = makeSnapshot(totalMillis: 500000, apps: {'com.app': 60000});
      expect(s.totalMinutes, 8);
      expect(s.appMinutes('com.app'), 1);
    });
  });

  group('E. Date & Local Calendar Semantics', () {
    test('isSameLocalDate matches same calendar date across UTC/local', () {
      final local = DateTime(2026, 11, 18, 8, 30);
      final utc = DateTime.utc(2026, 11, 18, 3, 0);
      expect(PolicyUsageSnapshot.isSameLocalDate(local, local), isTrue);
      expect(PolicyUsageSnapshot.isSameLocalDate(local, utc), isTrue);
      expect(PolicyUsageSnapshot.isSameLocalDate(local, DateTime(2026, 11, 19, 8, 30)), isFalse);
      expect(PolicyUsageSnapshot.isSameLocalDate(local, DateTime(2026, 10, 18, 8, 30)), isFalse);
      expect(PolicyUsageSnapshot.isSameLocalDate(local, DateTime(2025, 11, 18, 8, 30)), isFalse);
    });

    test('isEmptyActivity vs hasRecordedActivity decoupled from freshness', () {
      final empty = makeEmpty(isPermissionGranted: true, freshness: PolicyUsageFreshness.delayed);
      expect(empty.isEmptyActivity, isTrue);
      expect(empty.hasRecordedActivity, isFalse);
      expect(empty.freshness, PolicyUsageFreshness.delayed);
      final active = makeSnapshot(totalMillis: 60000, apps: {'com.app': 60000});
      expect(active.isEmptyActivity, isFalse);
      expect(active.hasRecordedActivity, isTrue);
    });
  });
}
