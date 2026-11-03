import 'enums_commands.dart';
import 'json_utils.dart';

/// `public.devices` — one paired child device.
///
/// `secret_hash` is a hash and the KDF behind it is not captured; it is carried
/// so that lifecycle checks can read it, never so the app can display it.
final class Device {
  const Device({
    required this.id,
    required this.familyId,
    required this.childUserId,
    required this.installationId,
    required this.displayName,
    required this.platform,
    required this.enforcementMode,
    required this.policyVersion,
    this.androidVersion,
    this.appVersion,
    this.status,
    this.secretHash,
    this.credentialIssuedAt,
    this.credentialRevokedAt,
    this.lastSeenAt,
    this.batteryLevel,
    this.isCharging,
    this.usageAccessGranted,
    this.locationGranted,
    this.backgroundLocationGranted,
    this.cameraGranted,
    this.microphoneGranted,
    this.notificationsGranted,
    this.createdAt,
    this.updatedAt,
  });

  factory Device.fromRow(Map<String, Object?> row) => Device(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    childUserId: asText(row['child_user_id']) ?? '',
    installationId: asText(row['installation_id']) ?? '',
    displayName: asText(row['display_name']) ?? '',
    platform: asText(row['platform']) ?? '',
    androidVersion: asText(row['android_version']),
    appVersion: asText(row['app_version']),
    status: asText(row['status']),
    secretHash: asText(row['secret_hash']),
    credentialIssuedAt: asDate(row['credential_issued_at']),
    credentialRevokedAt: asDate(row['credential_revoked_at']),
    lastSeenAt: asDate(row['last_seen_at']),
    batteryLevel: asInt(row['battery_level']),
    isCharging: asBool(row['is_charging']),
    enforcementMode: asText(row['enforcement_mode']),
    policyVersion: asInt(row['policy_version']) ?? 0,
    usageAccessGranted: asBool(row['usage_access_granted']),
    locationGranted: asBool(row['location_granted']),
    backgroundLocationGranted: asBool(row['background_location_granted']),
    cameraGranted: asBool(row['camera_granted']),
    microphoneGranted: asBool(row['microphone_granted']),
    notificationsGranted: asBool(row['notifications_granted']),
    createdAt: asDate(row['created_at']),
    updatedAt: asDate(row['updated_at']),
  );

  final String id;
  final String familyId;
  final String childUserId;
  final String installationId;
  final String displayName;
  final String platform;
  final String? androidVersion;
  final String? appVersion;
  final String? status;
  final String? secretHash;
  final DateTime? credentialIssuedAt;
  final DateTime? credentialRevokedAt;
  final DateTime? lastSeenAt;
  final int? batteryLevel;
  final bool? isCharging;
  final String? enforcementMode;
  final int policyVersion;
  final bool? usageAccessGranted;
  final bool? locationGranted;
  final bool? backgroundLocationGranted;
  final bool? cameraGranted;
  final bool? microphoneGranted;
  final bool? notificationsGranted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeviceStatus? get deviceStatus => DeviceStatus.fromWire(status);
  EnforcementMode? get mode => EnforcementMode.fromWire(enforcementMode);

  /// The column constraint `devices_revoked_credential_consistency` ties a
  /// revoked status to a null secret, so either signal is enough.
  bool get isUsable =>
      deviceStatus == DeviceStatus.active && credentialRevokedAt == null;

  bool get hasLocation => locationGranted == true;
  bool get hasBackgroundLocation => backgroundLocationGranted == true;
  bool get hasUsageAccess => usageAccessGranted == true;
}

/// `public.device_apps` — an app as the device reported it.
final class DeviceApp {
  const DeviceApp({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.packageName,
    required this.label,
    required this.isSystem,
    required this.isSuspended,
    required this.reportedAt,
    this.versionName,
  });

  factory DeviceApp.fromRow(Map<String, Object?> row) => DeviceApp(
    id: asText(row['id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    packageName: asText(row['package_name']) ?? '',
    label: asText(row['label']) ?? '',
    isSystem: asBool(row['is_system']) ?? false,
    isSuspended: asBool(row['is_suspended']) ?? false,
    reportedAt: asDate(row['reported_at']) ?? DateTime.utc(1970),
    versionName: asText(row['version_name']),
  );

  final String id;
  final String deviceId;
  final String familyId;
  final String packageName;
  final String label;
  final bool isSystem;
  final bool isSuspended;
  final DateTime reportedAt;
  final String? versionName;

  Map<String, Object?> toRow() => {
    'id': id,
    'device_id': deviceId,
    'family_id': familyId,
    'package_name': packageName,
    'label': label,
    'is_system': isSystem,
    'is_suspended': isSuspended,
    if (versionName != null) 'version_name': versionName,
    'reported_at': toJsonDate(reportedAt),
  };
}

/// `public.device_policies` — a versioned rule set and what the device did with it.
final class DevicePolicy {
  const DevicePolicy({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.version,
    required this.policy,
    required this.createdAt,
    this.createdBy,
    this.acknowledgedAt,
    this.enforcementStatus,
    this.lastError,
  });

  factory DevicePolicy.fromRow(Map<String, Object?> row) => DevicePolicy(
    id: asText(row['id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    version: asInt(row['version']) ?? 0,
    policy: asMap(row['policy']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    createdBy: asText(row['created_by']),
    acknowledgedAt: asDate(row['acknowledged_at']),
    enforcementStatus: asText(row['enforcement_status']),
    lastError: asText(row['last_error']),
  );

  final String id;
  final String deviceId;
  final String familyId;
  final int version;
  final Map<String, Object?> policy;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? acknowledgedAt;
  final String? enforcementStatus;
  final String? lastError;

  PolicyEnforcementStatus? get statusEnum =>
      PolicyEnforcementStatus.fromWire(enforcementStatus);

  /// Never claim a rule is active unless the device acknowledged it.
  bool get isEnforcedOnDevice => statusEnum == PolicyEnforcementStatus.enforced;
}
