import 'package:haven_core/haven_core.dart';

import 'usage_channel_contract.dart';
import 'usage_envelope_models.dart';

/// Parses raw Map response into typed UsagePermissionResult.
Result<UsagePermissionResult> parsePermissionResult(dynamic raw) {
  if (raw is! Map) {
    return const Err<UsagePermissionResult>(
      BackendFailure(
        'Malformed permission status response from native platform',
        code: 'malformed_response',
      ),
    );
  }

  final int? apiLevel = (raw[UsageEnvelopeKey.apiLevel] as num?)?.toInt();
  final String? statusRaw = raw[UsageEnvelopeKey.status] as String?;
  final UsagePermissionStatus? status = UsagePermissionStatus.parse(statusRaw);

  if (apiLevel == null || status == null) {
    return const Err<UsagePermissionResult>(
      BackendFailure(
        'Missing required fields in permission status response',
        code: 'malformed_response',
      ),
    );
  }

  return Ok<UsagePermissionResult>(
    UsagePermissionResult(status: status, apiLevel: apiLevel),
  );
}

/// Parses raw Map response into typed UsageSettingsLaunchResult.
Result<UsageSettingsLaunchResult> parseSettingsLaunchResult(dynamic raw) {
  if (raw is! Map) {
    return const Err<UsageSettingsLaunchResult>(
      BackendFailure(
        'Malformed settings launch response from native platform',
        code: 'malformed_response',
      ),
    );
  }

  final int? apiLevel = (raw[UsageEnvelopeKey.apiLevel] as num?)?.toInt();
  final bool? launched = raw[UsageEnvelopeKey.intentLaunched] as bool?;
  final bool? packageSettings =
      raw[UsageEnvelopeKey.openedPackageSettings] as bool?;

  if (apiLevel == null || launched == null || packageSettings == null) {
    return const Err<UsageSettingsLaunchResult>(
      BackendFailure(
        'Missing required fields in settings launch response',
        code: 'malformed_response',
      ),
    );
  }

  return Ok<UsageSettingsLaunchResult>(
    UsageSettingsLaunchResult(
      intentLaunched: launched,
      openedPackageSettings: packageSettings,
      apiLevel: apiLevel,
    ),
  );
}

/// Parses raw Map response into typed UsageDailyResult.
Result<UsageDailyResult> parseDailyUsageResult(dynamic raw) {
  if (raw is! Map) {
    return const Err<UsageDailyResult>(
      BackendFailure(
        'Malformed daily usage response from native platform',
        code: 'malformed_response',
      ),
    );
  }

  final int? apiLevel = (raw[UsageEnvelopeKey.apiLevel] as num?)?.toInt();
  final int? start = (raw[UsageEnvelopeKey.startTimeMillis] as num?)?.toInt();
  final int? end = (raw[UsageEnvelopeKey.endTimeMillis] as num?)?.toInt();
  final int? totalForeground =
      (raw[UsageEnvelopeKey.totalForegroundMillis] as num?)?.toInt();
  final String? freshnessRaw = raw[UsageEnvelopeKey.dataFreshness] as String?;
  final UsageDataFreshness? freshness = UsageDataFreshness.parse(freshnessRaw);
  final dynamic appsRaw = raw[UsageEnvelopeKey.apps];

  if (apiLevel == null ||
      start == null ||
      end == null ||
      totalForeground == null ||
      freshness == null ||
      appsRaw is! List) {
    return const Err<UsageDailyResult>(
      BackendFailure(
        'Missing or malformed envelope fields in daily usage response',
        code: 'malformed_response',
      ),
    );
  }

  final List<UsageAppRecord> apps = <UsageAppRecord>[];
  for (final dynamic item in appsRaw) {
    if (item is! Map) {
      return const Err<UsageDailyResult>(
        BackendFailure(
          'Malformed application usage record',
          code: 'malformed_response',
        ),
      );
    }
    final String? packageName = item[UsageEnvelopeKey.packageName] as String?;
    final int? foreground =
        (item[UsageEnvelopeKey.totalForegroundMillis] as num?)?.toInt();
    final int? lastTimeUsed =
        (item[UsageEnvelopeKey.lastTimeUsedMillis] as num?)?.toInt();
    final bool isSystem = item[UsageEnvelopeKey.isSystemApp] as bool? ?? false;

    if (packageName == null || foreground == null) {
      return const Err<UsageDailyResult>(
        BackendFailure(
          'Missing required app record fields in daily usage response',
          code: 'malformed_response',
        ),
      );
    }

    apps.add(
      UsageAppRecord(
        packageName: packageName,
        totalForegroundMillis: foreground,
        lastTimeUsedMillis: lastTimeUsed,
        isSystemApp: isSystem,
      ),
    );
  }

  return Ok<UsageDailyResult>(
    UsageDailyResult(
      apiLevel: apiLevel,
      startTimeMillis: start,
      endTimeMillis: end,
      totalForegroundMillis: totalForeground,
      dataFreshness: freshness,
      apps: apps,
    ),
  );
}
