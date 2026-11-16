import 'package:haven_child/core/native/usage_channel.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_core/haven_core.dart';

/// Hand-written fake of [UsageChannel] for deterministic repository testing.
final class FakeUsageChannel extends UsageChannel {
  FakeUsageChannel({
    this.permissionResult,
    this.settingsResult,
    this.dailyUsageResult,
    this.throwOnPermission = false,
    this.throwOnSettings = false,
    this.throwOnQuery = false,
  }) : super(isAndroid: true);

  Result<UsagePermissionResult>? permissionResult;
  Result<UsageSettingsLaunchResult>? settingsResult;
  Result<UsageDailyResult>? dailyUsageResult;

  bool throwOnPermission;
  bool throwOnSettings;
  bool throwOnQuery;

  int getPermissionCalls = 0;
  int openSettingsCalls = 0;
  int queryDailyCalls = 0;
  int? lastQueryStart;
  int? lastQueryEnd;

  @override
  Future<Result<UsagePermissionResult>> getPermissionStatus() async {
    getPermissionCalls++;
    if (throwOnPermission) {
      throw StateError('Simulated channel crash on getPermissionStatus');
    }
    return permissionResult ??
        const Ok<UsagePermissionResult>(
          UsagePermissionResult(
            status: UsagePermissionStatus.granted,
            apiLevel: 34,
          ),
        );
  }

  @override
  Future<Result<UsageSettingsLaunchResult>> openSettings() async {
    openSettingsCalls++;
    if (throwOnSettings) {
      throw StateError('Simulated channel crash on openSettings');
    }
    return settingsResult ??
        const Ok<UsageSettingsLaunchResult>(
          UsageSettingsLaunchResult(
            intentLaunched: true,
            openedPackageSettings: true,
            apiLevel: 34,
          ),
        );
  }

  @override
  Future<Result<UsageDailyResult>> queryDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  }) async {
    queryDailyCalls++;
    lastQueryStart = startTimeMillis;
    lastQueryEnd = endTimeMillis;
    if (throwOnQuery) {
      throw StateError('Simulated channel crash on queryDailyUsage');
    }
    if (startTimeMillis < 0 ||
        endTimeMillis < 0 ||
        startTimeMillis >= endTimeMillis) {
      return const Err<UsageDailyResult>(
        ValidationFailure(
          'Invalid time range: startTimeMillis must be non-negative and strictly less than endTimeMillis',
          field: 'time_range',
        ),
      );
    }
    return dailyUsageResult ??
        Ok<UsageDailyResult>(
          UsageDailyResult(
            apiLevel: 34,
            startTimeMillis: startTimeMillis,
            endTimeMillis: endTimeMillis,
            totalForegroundMillis: 0,
            dataFreshness: UsageDataFreshness.recent,
            apps: const <UsageAppRecord>[],
          ),
        );
  }
}
