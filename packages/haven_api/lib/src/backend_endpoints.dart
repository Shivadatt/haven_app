/// Which staging projects this build talks to, and which contracts are real.
///
/// Values are non-secret identifiers and are supplied at build time; they are
/// never hard-coded credentials. See `docs/stage2/S2-EXEC-08-identity-decision-A13-final.md`
/// for the identity topology these imply.
final class BackendEndpoints {
  const BackendEndpoints({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.firebaseProjectId,
    required this.firebaseAppId,
    required this.firebaseApiKey,
  });

  /// Unconfigured build. Everything still compiles and runs; each call returns
  /// a [BlockedFailure] rather than a fabricated success.
  static const unconfigured = BackendEndpoints(
    supabaseUrl: '',
    supabaseAnonKey: '',
    firebaseProjectId: '',
    firebaseAppId: '',
    firebaseApiKey: '',
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String firebaseProjectId;
  final String firebaseAppId;
  final String firebaseApiKey;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasFirebase =>
      firebaseProjectId.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseApiKey.isNotEmpty;

  bool get isConfigured => hasSupabase && hasFirebase;
}

/// Database objects the app is allowed to read or write.
///
/// Restricted to the 19 tables captured in
/// `docs/stage1/evidence/schema-columns.md`. Adding a name here requires the
/// column capture to contain it.
abstract final class TableName {
  static const auditLogs = 'audit_logs';
  static const childContactIds = 'child_contact_ids';
  static const deviceApps = 'device_apps';
  static const deviceCommands = 'device_commands';
  static const devicePairingTokens = 'device_pairing_tokens';
  static const devicePolicies = 'device_policies';
  static const devices = 'devices';
  static const families = 'families';
  static const familyMembers = 'family_members';
  static const locationEvents = 'location_events';
  static const pairingAttempts = 'pairing_attempts';
  static const pairingRequests = 'pairing_requests';
  static const profiles = 'profiles';
  static const remoteSessions = 'remote_sessions';
  static const safeZoneStates = 'safe_zone_states';
  static const safeZones = 'safe_zones';
  static const safetyAlerts = 'safety_alerts';
  static const usageDaily = 'usage_daily';
  static const webrtcSignals = 'webrtc_signals';

  static const all = [
    auditLogs,
    childContactIds,
    deviceApps,
    deviceCommands,
    devicePairingTokens,
    devicePolicies,
    devices,
    families,
    familyMembers,
    locationEvents,
    pairingAttempts,
    pairingRequests,
    profiles,
    remoteSessions,
    safeZoneStates,
    safeZones,
    safetyAlerts,
    usageDaily,
    webrtcSignals,
  ];

  /// Local guard: a table name outside the captured set cannot reach the SDK, so
  /// an invented table fails in review instead of at runtime against staging.
  static void assertKnown(String table) {
    if (!all.contains(table)) {
      throw ArgumentError.value(
        table,
        'table',
        'not one of the 19 captured tables',
      );
    }
  }
}

/// RPC names captured in `docs/stage1/evidence/g1-q7-20261029.json`.
///
/// The capture records signature, language, definer flag, settings and ACL but
/// **no return type**. Callers must therefore treat the decoded result as
/// `Object?` and validate it; nothing here assumes a shape.
abstract final class RpcName {
  static const applyPolicyVersion = 'apply_policy_version';
  static const createFamilyWithOwner = 'create_family_with_owner';
  static const createPairingInvite = 'create_pairing_invite';
  static const createPairingRequest = 'create_pairing_request';
  static const detectOfflineDevices = 'detect_offline_devices';
  static const expireStaleCommands = 'expire_stale_commands';
  static const expireStaleSessions = 'expire_stale_sessions';
  static const pollDeviceCommands = 'poll_device_commands';
  static const replaceDeviceApps = 'replace_device_apps';
  static const requestDeviceRecovery = 'request_device_recovery';
  static const requestRemoteSession = 'request_remote_session';
  static const respondPairingRequest = 'respond_pairing_request';
  static const revokeDevice = 'revoke_device';
  static const unlinkChild = 'unlink_child';

  static const all = [
    applyPolicyVersion,
    createFamilyWithOwner,
    createPairingInvite,
    createPairingRequest,
    detectOfflineDevices,
    expireStaleCommands,
    expireStaleSessions,
    pollDeviceCommands,
    replaceDeviceApps,
    requestDeviceRecovery,
    requestRemoteSession,
    respondPairingRequest,
    revokeDevice,
    unlinkChild,
  ];

  static void assertKnown(String name) {
    if (!all.contains(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'not one of the 14 captured public RPCs',
      );
    }
  }
}

/// Edge Function slugs captured in
/// `docs/stage1/evidence/edge-functions/capture-20261030.json`.
///
/// Nine exist and only these nine may be called. `notification-cron`,
/// `register-token` and `verify-firebase-token` are **not** among them and must
/// not be referenced.
abstract final class EdgeFunctionName {
  static const authBootstrap = 'auth-bootstrap';
  static const cron = 'cron';
  static const deviceCommand = 'device-command';
  static const devicePolicy = 'device-policy';
  static const deviceRegister = 'device-register';
  static const deviceTelemetry = 'device-telemetry';
  static const familyAdmin = 'family-admin';
  static const pairing = 'pairing';
  static const remoteSession = 'remote-session';

  static const all = [
    authBootstrap,
    cron,
    deviceCommand,
    devicePolicy,
    deviceRegister,
    deviceTelemetry,
    familyAdmin,
    pairing,
    remoteSession,
  ];

  /// Only these nine slugs existed in the 2026-10-30 capture. Anything else —
  /// including `notification-cron`, `register-token` and `verify-firebase-token`,
  /// which were never present — fails here rather than at runtime.
  static void assertKnown(String slug) {
    if (!all.contains(slug)) {
      throw ArgumentError.value(
        slug,
        'slug',
        'not one of the 9 captured Edge Functions',
      );
    }
  }
}
