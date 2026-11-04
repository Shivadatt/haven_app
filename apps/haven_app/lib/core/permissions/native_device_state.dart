import 'package:haven_core/haven_core.dart';

import 'admin_and_media_states.dart';
import 'area_reading.dart';
import 'device_control_states.dart';
import 'permission_and_monitoring_states.dart';

/// The device lane's one question: what does this phone say about itself right now.
///
/// Kept as an interface rather than a call into `MethodChannel` from a controller,
/// so a screen can be tested against what the phone answered and the Android build
/// can be tested against what the operating system answers — which are different
/// questions, and only one of them has a widget in front of it.
abstract interface class NativeDeviceState {
  /// Reads every section the native lane has a reader for.
  ///
  /// A section the phone refused stays a section of the report; only the whole lane
  /// being unreachable — no channel to ask on — arrives as a failure.
  Future<Result<DeviceStateReport>> read();
}

/// One read of the phone, with the OS's own numbers attached.
///
/// [apiLevel] and [osRelease] travel with the answers because several of them only
/// exist from a given Android version, and a sentence like "notifications are
/// allowed" has to be readable next to the version that made it true.
final class DeviceStateReport {
  const DeviceStateReport({
    required this.apiLevel,
    required this.osRelease,
    required this.readAt,
    required this.permissions,
    required this.monitoring,
    required this.location,
    required this.deviceAdmin,
    required this.communication,
  });

  final int apiLevel;
  final String osRelease;

  /// When this app received the answers, not when the phone produced them: the
  /// phone's own clock is not needed for a sentence about how fresh the read is.
  final DateTime readAt;

  final AreaReading<PermissionStates> permissions;
  final AreaReading<MonitoringStates> monitoring;
  final AreaReading<LocationStates> location;
  final AreaReading<DeviceAdminStates> deviceAdmin;
  final AreaReading<CommunicationStates> communication;

  /// The sections the phone answered, in the order a screen lists them.
  List<String> get answeredSections =>
      <String, AreaReading<Object>>{
            'permissions': permissions,
            'monitoring': monitoring,
            'location': location,
            'deviceAdmin': deviceAdmin,
            'communication': communication,
          }.entries
          .where(
            (MapEntry<String, AreaReading<Object>> e) =>
                e.value is AnsweredArea,
          )
          .map((e) => e.key)
          .toList(growable: false);

  /// How long ago this read was taken, for a card that must not look like a live
  /// signal when the app has been open for an hour.
  Duration ageAt(DateTime now) => now.difference(readAt);
}
