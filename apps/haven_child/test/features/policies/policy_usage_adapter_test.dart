import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/policies/data/policy_usage_adapter.dart';
import 'package:haven_models/haven_models.dart';

void main() {
  final local = DateTime(2026, 11, 18);
  final start = local.millisecondsSinceEpoch;
  final end = local.add(const Duration(hours: 10)).millisecondsSinceEpoch;

  UsageDailyResult usage({
    int startMillis = 0,
    int endMillis = 0,
    int total = 0,
    UsageDataFreshness freshness = UsageDataFreshness.recent,
    List<UsageAppRecord> apps = const [],
  }) => UsageDailyResult(
    apiLevel: 34,
    startTimeMillis: startMillis == 0 ? start : startMillis,
    endTimeMillis: endMillis == 0 ? end : endMillis,
    totalForegroundMillis: total,
    dataFreshness: freshness,
    apps: apps,
  );

  group('dailyRange', () {
    test('uses local midnight and keeps exact midnight equal', () {
      final midnight = DateTime(2026, 11, 18);
      final range = PolicyUsageAdapter.dailyRange(midnight);
      expect(range.start, midnight.millisecondsSinceEpoch);
      expect(range.end, range.start);
    });

    test('uses a positive window during the day', () {
      final range = PolicyUsageAdapter.dailyRange(DateTime(2026, 11, 18, 10));
      expect(range.end, greaterThan(range.start));
      expect(DateTime.fromMillisecondsSinceEpoch(range.start), local);
    });
  });

  group('fromDailyResult', () {
    test('empty native result is unavailable, never zero', () {
      final result = PolicyUsageAdapter.fromDailyResult(
        usage(freshness: UsageDataFreshness.empty),
        isPermissionGranted: true,
      );
      final snapshot = result.valueOrNull!;
      expect(snapshot.freshness, PolicyUsageFreshness.unavailable);
      expect(snapshot.totalForegroundMillis, isNull);
      expect(snapshot.appForegroundMillis, isEmpty);
      expect(snapshot.completeness, PolicyUsageCompleteness.unknown);
    });
    test('empty app list and all-zero records are unavailable', () {
      final empty = PolicyUsageAdapter.fromDailyResult(
        usage(),
        isPermissionGranted: true,
      ).valueOrNull!;
      expect(empty.freshness, PolicyUsageFreshness.unavailable);
      expect(empty.totalForegroundMillis, isNull);

      final zero = PolicyUsageAdapter.fromDailyResult(
        usage(
          apps: const [
            UsageAppRecord(
              packageName: 'com.zero',
              totalForegroundMillis: 0,
              isSystemApp: false,
            ),
          ],
        ),
        isPermissionGranted: true,
      ).valueOrNull!;
      expect(zero.freshness, PolicyUsageFreshness.unavailable);
      expect(zero.totalForegroundMillis, isNull);
    });
    test('keeps measured apps but never forwards the native total', () {
      final result = PolicyUsageAdapter.fromDailyResult(
        usage(
          total: 90000,
          apps: const [
            UsageAppRecord(
              packageName: 'com.used',
              totalForegroundMillis: 90000,
              isSystemApp: false,
            ),
          ],
        ),
        isPermissionGranted: true,
      ).valueOrNull!;
      expect(result.totalForegroundMillis, isNull);
      expect(result.appMinutes('com.used'), 1);
      expect(result.appMinutes('com.missing'), isNull);
      expect(result.completeness, PolicyUsageCompleteness.unknown);
      expect(result.freshness, PolicyUsageFreshness.recent);
    });
    test('maps delayed freshness and preserves source interval', () {
      final result = PolicyUsageAdapter.fromDailyResult(
        usage(
          freshness: UsageDataFreshness.delayed,
          apps: const [
            UsageAppRecord(
              packageName: 'com.used',
              totalForegroundMillis: 60000,
              isSystemApp: false,
            ),
          ],
        ),
        isPermissionGranted: true,
      ).valueOrNull!;
      expect(result.freshness, PolicyUsageFreshness.delayed);
      expect(result.startInterval.millisecondsSinceEpoch, start);
      expect(result.endInterval.millisecondsSinceEpoch, end);
      expect(result.snapshotDate, local);
    });
    test('rejects malformed interval and malformed app records', () {
      expect(
        PolicyUsageAdapter.fromDailyResult(
          usage(startMillis: end, endMillis: start),
          isPermissionGranted: true,
        ).isErr,
        isTrue,
      );
      expect(
        PolicyUsageAdapter.fromDailyResult(
          usage(
            apps: const [
              UsageAppRecord(
                packageName: ' ',
                totalForegroundMillis: 1,
                isSystemApp: false,
              ),
            ],
          ),
          isPermissionGranted: true,
        ).isErr,
        isTrue,
      );
    });
  });

  test('unavailableForQuery accepts equal exact-midnight interval', () {
    final snapshot = PolicyUsageAdapter.unavailableForQuery(
      startTimeMillis: start,
      endTimeMillis: start,
      isPermissionGranted: true,
    );
    expect(snapshot.startInterval, snapshot.endInterval);
    expect(snapshot.totalForegroundMillis, isNull);
    expect(snapshot.appForegroundMillis, isEmpty);
    expect(snapshot.freshness, PolicyUsageFreshness.unavailable);
    expect(snapshot.completeness, PolicyUsageCompleteness.unknown);
    expect(snapshot.snapshotDate, local);
  });
}
