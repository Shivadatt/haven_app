import 'package:haven_core/haven_core.dart';

import '../../../core/native/usage_channel.dart';
import '../../../core/native/usage_envelope_models.dart';

/// Repository interface for child device usage access.
///
/// Provides a typed abstraction over the native Android Usage Access bridge,
/// keeping domain and presentation layers decoupled from platform channel details.
abstract interface class ChildUsageRepository {
  /// Queries the current Usage Access permission status on this device.
  Future<Result<UsagePermissionResult>> getPermissionStatus();

  /// Launches the Android Usage Access settings screen.
  Future<Result<UsageSettingsLaunchResult>> openUsageSettings();

  /// Queries daily foreground application usage for the given time range.
  Future<Result<UsageDailyResult>> getDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  });
}

/// Concrete implementation of [ChildUsageRepository] delegating to [UsageChannel].
final class ChildUsageRepositoryImpl implements ChildUsageRepository {
  ChildUsageRepositoryImpl({
    UsageChannel? usageChannel,
  }) : _usageChannel = usageChannel ?? UsageChannel();

  final UsageChannel _usageChannel;

  @override
  Future<Result<UsagePermissionResult>> getPermissionStatus() async {
    try {
      return await _usageChannel.getPermissionStatus();
    } catch (e) {
      return Err<UsagePermissionResult>(
        UnknownFailure(
          'Unexpected error querying permission status',
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<UsageSettingsLaunchResult>> openUsageSettings() async {
    try {
      return await _usageChannel.openSettings();
    } catch (e) {
      return Err<UsageSettingsLaunchResult>(
        UnknownFailure(
          'Unexpected error opening usage settings',
          detail: e.toString(),
        ),
      );
    }
  }

  /// Convenience alias matching [UsageChannel.openSettings].
  Future<Result<UsageSettingsLaunchResult>> openSettings() =>
      openUsageSettings();

  @override
  Future<Result<UsageDailyResult>> getDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  }) async {
    try {
      return await _usageChannel.queryDailyUsage(
        startTimeMillis: startTimeMillis,
        endTimeMillis: endTimeMillis,
      );
    } catch (e) {
      return Err<UsageDailyResult>(
        UnknownFailure(
          'Unexpected error querying daily usage',
          detail: e.toString(),
        ),
      );
    }
  }

  /// Convenience alias matching [UsageChannel.queryDailyUsage].
  Future<Result<UsageDailyResult>> queryDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  }) =>
      getDailyUsage(
        startTimeMillis: startTimeMillis,
        endTimeMillis: endTimeMillis,
      );
}

/// Type alias for repository implementation.
typedef NativeChildUsageRepository = ChildUsageRepositoryImpl;
