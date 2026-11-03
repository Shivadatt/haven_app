/// Argument records for the device, command and session RPCs captured in
/// `docs/stage1/evidence/g1-q7-20261029.json`. **No return types were captured.**
library;

/// `revoke_device(p_device_id uuid, p_actor_user_id uuid)`
final class RevokeDeviceArgs {
  const RevokeDeviceArgs({required this.deviceId, required this.actorUserId});

  final String deviceId;
  final String actorUserId;

  Map<String, Object?> toParams() => {
    'p_device_id': deviceId,
    'p_actor_user_id': actorUserId,
  };
}

/// `request_device_recovery(p_device_id uuid, p_actor_user_id uuid)`
final class RequestDeviceRecoveryArgs {
  const RequestDeviceRecoveryArgs({
    required this.deviceId,
    required this.actorUserId,
  });

  final String deviceId;
  final String actorUserId;

  Map<String, Object?> toParams() => {
    'p_device_id': deviceId,
    'p_actor_user_id': actorUserId,
  };
}

/// `expire_stale_commands(p_device_id uuid)`
final class ExpireStaleCommandsArgs {
  const ExpireStaleCommandsArgs({required this.deviceId});

  final String deviceId;

  Map<String, Object?> toParams() => {'p_device_id': deviceId};
}

/// `poll_device_commands(p_device_id uuid, p_limit integer)` — device-side lane.
final class PollDeviceCommandsArgs {
  const PollDeviceCommandsArgs({required this.deviceId, this.limit = 10});

  final String deviceId;
  final int limit;

  Map<String, Object?> toParams() => {
    'p_device_id': deviceId,
    'p_limit': limit,
  };
}

/// `replace_device_apps(p_device_id uuid, p_family_id uuid, p_apps jsonb)`
final class ReplaceDeviceAppsArgs {
  const ReplaceDeviceAppsArgs({
    required this.deviceId,
    required this.familyId,
    required this.apps,
  });

  final String deviceId;
  final String familyId;
  final List<Map<String, Object?>> apps;

  Map<String, Object?> toParams() => {
    'p_device_id': deviceId,
    'p_family_id': familyId,
    'p_apps': apps,
  };
}

/// `request_remote_session(p_device_id uuid, p_parent_user_id uuid, p_kind text)`
///
/// `remote_sessions.kind` is constrained to `audio|video`, enforced here so a
/// wrong value is a local mistake rather than a rejected round trip.
final class RequestRemoteSessionArgs {
  const RequestRemoteSessionArgs({
    required this.deviceId,
    required this.parentUserId,
    required this.kind,
  });

  final String deviceId;
  final String parentUserId;
  final String kind;

  static const allowedKinds = ['audio', 'video'];

  Map<String, Object?> toParams() {
    assert(
      allowedKinds.contains(kind),
      'remote_sessions.kind is constrained to audio|video',
    );
    return {
      'p_device_id': deviceId,
      'p_parent_user_id': parentUserId,
      'p_kind': kind,
    };
  }
}

/// `detect_offline_devices()` — captured with no arguments.
final class DetectOfflineDevicesArgs {
  const DetectOfflineDevicesArgs();

  Map<String, Object?> toParams() => const {};
}

/// `expire_stale_sessions()` — captured with no arguments.
final class ExpireStaleSessionsArgs {
  const ExpireStaleSessionsArgs();

  Map<String, Object?> toParams() => const {};
}
