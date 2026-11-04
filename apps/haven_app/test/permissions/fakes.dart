import 'package:haven_core/haven_core.dart';
import 'package:haven_app/core/permissions/admin_and_media_states.dart';
import 'package:haven_app/core/permissions/area_reading.dart';
import 'package:haven_app/core/permissions/device_control_states.dart';
import 'package:haven_app/core/permissions/native_device_state.dart';
import 'package:haven_app/core/permissions/permission_and_monitoring_states.dart';

/// A phone that answers on command, so a screen can be shown both a refusal and a
/// grant without owning either.
final class FakeNativeDeviceState implements NativeDeviceState {
  FakeNativeDeviceState(this.result);

  Result<DeviceStateReport> result;
  int readCount = 0;

  @override
  Future<Result<DeviceStateReport>> read() async {
    readCount++;
    return result;
  }
}

/// A read that went nowhere — the shape a non-Android build produces.
Result<DeviceStateReport> unavailable({String why = 'no channel'}) =>
    Err<DeviceStateReport>(
      UnknownFailure('This build has no device-state lane.', detail: why),
    );

/// A read the phone answered.
Result<DeviceStateReport> ok(DeviceStateReport report) =>
    Ok<DeviceStateReport>(report);

/// A report with every area answered, each with the plainest true values.
DeviceStateReport fullReport({
  PermissionStates? permissions,
  MonitoringStates? monitoring,
  LocationStates? location,
  DeviceAdminStates? deviceAdmin,
  CommunicationStates? communication,
  Map<String, String> refused = const <String, String>{},
  DateTime? readAt,
}) {
  AreaReading<T> area<T extends Object>(String name, T value) =>
      refused.containsKey(name)
      ? RefusedArea<T>(refused[name]!)
      : AnsweredArea<T>(value);
  return DeviceStateReport(
    apiLevel: 36,
    osRelease: '16',
    readAt: readAt ?? DateTime(2026, 11, 4, 9),
    permissions: area<PermissionStates>(
      'permissions',
      permissions ??
          PermissionStates(
            granted: <String, bool?>{'notifications': true},
            undeclared: <String>{'microphone', 'camera', 'locationInUse'},
            declaredPermissions: const <String>[
              'INTERNET',
              'POST_NOTIFICATIONS',
            ],
            batteryExemptionDeclared: false,
            bootReceiverDeclared: false,
          ),
    ),
    monitoring: area<MonitoringStates>(
      'monitoring',
      monitoring ??
          MonitoringStates(
            usageAccess: false,
            usageAccessMode: 'ignored',
            batteryOptimizationIgnored: false,
            notificationImportance: 'high',
            exactAlarmsAllowed: null,
            serviceCount: 3,
            foregroundTypedServiceCount: 0,
            silentRingtone: false,
          ),
    ),
    location: area<LocationStates>(
      'location',
      location ??
          LocationStates(
            serviceAvailable: true,
            gpsOn: true,
            networkOn: false,
            passiveOn: null,
            mayAsk: false,
            lastFix: null,
            withheldBecause: 'permission',
          ),
    ),
    deviceAdmin: area<DeviceAdminStates>(
      'deviceAdmin',
      deviceAdmin ??
          DeviceAdminStates(
            serviceAvailable: true,
            receiverDeclared: true,
            adminActive: false,
            deviceOwner: false,
            profileOwner: null,
            activeAdminCount: 0,
            restrictionsInForce: null,
            screenLockTimeout: null,
            storageEncryptionState: 'active',
            restrictionsReadable: null,
          ),
    ),
    communication: area<CommunicationStates>(
      'communication',
      communication ??
          CommunicationStates(
            microphoneAllowed: null,
            cameraAllowed: null,
            audioServiceAvailable: true,
            microphoneMuted: false,
            audioMode: 'normal',
            speakerphoneOn: false,
            inputDeviceCount: 2,
            cameraCount: 3,
          ),
    ),
  );
}

/// A reply in the shape `HavenBridge.readAll` files it: the two OS numbers at the
/// top, one map per section, and a reason per section that failed.
Map<String, Object?> deviceStateEnvelope({
  Map<String, Object?>? sections,
  Map<String, Object?> errors = const <String, Object?>{},
}) => <String, Object?>{
  'apiLevel': 36,
  'osRelease': '16',
  'sections':
      sections ??
      <String, Object?>{
        'permissions': <String, Object?>{
          'granted': <String, Object?>{'notifications': true},
          'undeclared': <Object?>[],
          'declaredPermissions': <Object?>['INTERNET'],
        },
        'monitoring': <String, Object?>{
          'usageAccess': true,
          'usageAccessMode': 'allowed',
        },
        'location': <String, Object?>{'serviceAvailable': true, 'gpsOn': true},
        'deviceAdmin': <String, Object?>{
          'serviceAvailable': true,
          'adminActive': false,
          'userRestrictionsReadable': false,
        },
        'communication': <String, Object?>{
          'inputDevices': 1,
          'camerasPresent': 1,
        },
      },
  'sectionErrors': errors,
};
