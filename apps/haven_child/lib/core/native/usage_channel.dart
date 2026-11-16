import 'dart:io';

import 'package:flutter/services.dart';
import 'package:haven_core/haven_core.dart';

import 'usage_channel_contract.dart';
import 'usage_channel_failures.dart';
import 'usage_channel_parser.dart';
import 'usage_envelope_models.dart';

/// Typed wrapper communicating with the Android native Usage Bridge (D-4).
class UsageChannel {
  UsageChannel({
    MethodChannel? channel,
    bool? isAndroid,
  })  : _channel = channel ??
            const MethodChannel(UsageChannelName.channelName),
        _isAndroid = isAndroid ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool _isAndroid;

  /// Queries the current Usage Access permission status.
  Future<Result<UsagePermissionResult>> getPermissionStatus() async {
    if (!_isAndroid) {
      return const Err<UsagePermissionResult>(
        UnknownFailure(
          'Usage Access is only supported on Android',
          detail: 'unsupported_platform',
        ),
      );
    }

    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        UsageMethod.getPermissionStatus,
      );
      return parsePermissionResult(raw);
    } on PlatformException catch (e) {
      return Err<UsagePermissionResult>(usageFailureForPlatformException(e));
    } on MissingPluginException catch (e) {
      return Err<UsagePermissionResult>(
        BackendFailure(
          'Usage channel plugin is not available',
          code: 'missing_plugin',
          detail: e.message,
        ),
      );
    } catch (e) {
      return Err<UsagePermissionResult>(
        UnknownFailure(
          'Unexpected usage channel error',
          detail: e.toString(),
        ),
      );
    }
  }

  /// Dispatches navigation intent to Android Usage Access Settings screen.
  Future<Result<UsageSettingsLaunchResult>> openSettings() async {
    if (!_isAndroid) {
      return const Err<UsageSettingsLaunchResult>(
        UnknownFailure(
          'Usage Access settings is only supported on Android',
          detail: 'unsupported_platform',
        ),
      );
    }

    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        UsageMethod.openSettings,
      );
      return parseSettingsLaunchResult(raw);
    } on PlatformException catch (e) {
      return Err<UsageSettingsLaunchResult>(usageFailureForPlatformException(e));
    } on MissingPluginException catch (e) {
      return Err<UsageSettingsLaunchResult>(
        BackendFailure(
          'Usage channel plugin is not available',
          code: 'missing_plugin',
          detail: e.message,
        ),
      );
    } catch (e) {
      return Err<UsageSettingsLaunchResult>(
        UnknownFailure(
          'Unexpected usage channel error',
          detail: e.toString(),
        ),
      );
    }
  }

  /// Queries foreground usage stats for a daily time interval.
  Future<Result<UsageDailyResult>> queryDailyUsage({
    required int startTimeMillis,
    required int endTimeMillis,
  }) async {
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

    if (!_isAndroid) {
      return const Err<UsageDailyResult>(
        UnknownFailure(
          'Usage Access query is only supported on Android',
          detail: 'unsupported_platform',
        ),
      );
    }

    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        UsageMethod.queryDailyUsage,
        <String, dynamic>{
          UsageEnvelopeKey.startTimeMillis: startTimeMillis,
          UsageEnvelopeKey.endTimeMillis: endTimeMillis,
        },
      );
      return parseDailyUsageResult(raw);
    } on PlatformException catch (e) {
      return Err<UsageDailyResult>(usageFailureForPlatformException(e));
    } on MissingPluginException catch (e) {
      return Err<UsageDailyResult>(
        BackendFailure(
          'Usage channel plugin is not available',
          code: 'missing_plugin',
          detail: e.message,
        ),
      );
    } catch (e) {
      return Err<UsageDailyResult>(
        UnknownFailure(
          'Unexpected usage channel error',
          detail: e.toString(),
        ),
      );
    }
  }
}
