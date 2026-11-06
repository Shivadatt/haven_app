import 'package:haven_core/haven_core.dart';

import 'child_permission.dart';
import 'permission_status_source.dart';

/// The Stage-1 source: nothing reads Android, so every status is a typed
/// `blocked(...)` refusal with the missing piece named precisely.
///
/// This class is the whole implementation of brief §4.E: "the action only
/// when a supported implementation exists". The dashboard renders
/// [cardStatusLabel] for a blocked read; it can only render
/// granted/not-granted when a future source returns an `Ok`, which requires a
/// real read. A permission can therefore never look granted from a UI alone.
final class UnconfiguredPermissionStatusSource implements PermissionStatusSource {
  const UnconfiguredPermissionStatusSource();

  static const String cardStatusLabel =
      'Unavailable — not yet implemented on this device build';

  static const String settingsActionNote =
      'Opening device settings is not part of this build yet.';

  @override
  Future<Result<PermissionStatus>> statusOf(
    ChildPermission permission,
  ) async =>
      blocked<PermissionStatus>(
        'native permission reader for "${permission.wire}" (Kotlin lane, '
        'Phase 3 Stage 2+)',
        requirement:
            'This build does not read Android permission state, so Haven '
            'reports nothing about ${permission.label.toLowerCase()}.',
      );
}
