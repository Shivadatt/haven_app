import 'package:haven_core/haven_core.dart';

import 'child_permission.dart';

/// A permission read that came from a REAL reader: [granted] is the state the
/// device reported. This type cannot be built from a guess — the only way to
/// one is a [PermissionStatusSource] that actually reads.
final class PermissionStatus {
  const PermissionStatus({required this.permission, required this.granted});

  final ChildPermission permission;
  final bool granted;
}

/// The read seam the dashboard codes against.
abstract interface class PermissionStatusSource {
  /// `Err(BlockedFailure)` until a stage ships a real reader for [permission]
  /// — the status UI then shows "Unavailable", never granted/denied.
  Future<Result<PermissionStatus>> statusOf(ChildPermission permission);
}
