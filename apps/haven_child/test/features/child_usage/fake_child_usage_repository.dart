import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/data/child_usage_repository.dart';
import 'package:haven_core/haven_core.dart';

/// Hand-written fake of [ChildUsageRepository] for testing [ChildUsageController].
final class FakeChildUsageRepository implements ChildUsageRepository {
  FakeChildUsageRepository({
    this.permissionResult,
    this.settingsResult,
    this.dailyUsageResult,
    this.throwOnPermission = false,
    this.throwOnSettings = false,
    this.throwOnDailyUsage = false,
    this.permissionDelay,
    this.dailyUsageDelay,
  });

  Result<UsagePermissionResult>? permissionResult;
  Result<UsageSettingsLaunchResult>? settingsResult;
  Result<UsageDailyResult>? dailyUsageResult;

  bool throwOnPermission;
  bool throwOnSettings;
  bool throwOnDailyUsage;

  Duration? permissionDelay;
  Duration? dailyUsageDelay;

  int getPermissionCalls = 0;
  int openSettingsCalls = 0;
  int getDailyCalls = 0;
  int? lastStart;
  int? lastEnd;

  @override
  Future<Result<UsagePermissionResult>> getPermissionStatus() async {
    getPermissionCalls++;
    if (permissionDelay != null) {
      await Future<void>.delayed(permissionDelay!);
    }
    if (throwOnPermission) {
      throw StateError('Simulated repository crash on getPermissionStatus');
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
  Future<Result<UsageSettingsLaunchResult>> openUsageSettings() async {
    openSettingsCalls++;
    if (throwOnSettings) {
      throw StateError('Simulated repository crash on openUsageSettings');
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
  Future<Result<UsageDailyResult>> getDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  }) async {
    getDailyCalls++;
    lastStart = startTimeMillis;
    lastEnd = endTimeMillis;
    if (dailyUsageDelay != null) {
      await Future<void>.delayed(dailyUsageDelay!);
    }
    if (throwOnDailyUsage) {
      throw StateError('Simulated repository crash on getDailyUsage');
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
