import 'package:flutter/services.dart';
import 'package:haven_core/haven_core.dart';

import 'usage_channel_contract.dart';

/// Maps native MethodChannel PlatformException onto HavenFailure types.
HavenFailure usageFailureForPlatformException(PlatformException e) {
  return switch (e.code) {
    UsageErrorCode.unknownMethod => ValidationFailure(
        'The native lane does not support that method',
        field: 'method',
        detail: e.message,
      ),
    UsageErrorCode.noContext => UnknownFailure(
        'Android system context is not available',
        detail: e.message,
      ),
    UsageErrorCode.permissionDenied => DevicePermissionFailure(
        'Usage Access permission is denied in Android Settings',
        detail: e.message,
        openSettingsWillHelp: true,
      ),
    UsageErrorCode.invalidRange => ValidationFailure(
        'Invalid query time range supplied',
        field: 'time_range',
        detail: e.message,
      ),
    UsageErrorCode.sectionFailed => BackendFailure(
        'Failed to query native usage statistics',
        code: UsageErrorCode.sectionFailed,
        detail: e.message,
        retryable: true,
      ),
    _ => BackendFailure(
        e.message ?? 'Unknown platform exception occurred',
        code: e.code,
        detail: e.details?.toString(),
      ),
  };
}
