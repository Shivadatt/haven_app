// Reads the maps the native lane sends, without inventing an answer for a key that
// is not there.
//
// A MethodChannel hands over `Map<Object?, Object?>`, so everything goes through
// the small casters below: a value of the wrong shape is read as "the phone did not
// say", never coerced into `false` or `0`, which would turn a garbled reply into a
// confident wrong sentence on screen.

import 'admin_and_media_states.dart';
import 'area_reading.dart';
import 'device_control_states.dart';
import 'permission_and_monitoring_states.dart';

Map<String, Object?> _map(Object? raw) => raw is Map
    ? raw.map((Object? k, Object? v) => MapEntry<String, Object?>('$k', v))
    : <String, Object?>{};

bool? _bool(Object? raw) => raw is bool ? raw : null;
int? _int(Object? raw) => raw is int ? raw : null;
double? _double(Object? raw) => raw is num ? raw.toDouble() : null;
String? _string(Object? raw) => raw is String ? raw : null;

List<String> _strings(Object? raw) => raw is List
    ? raw.whereType<String>().toList(growable: false)
    : const <String>[];

/// A list the phone may have withheld entirely — `null` stays `null`, because "the
/// OS would not hand us this reading" and "nothing is in force" are different facts.
List<String>? _optionalStrings(Object? raw) =>
    raw is List ? raw.whereType<String>().toList(growable: false) : null;

Map<String, bool?> _boolMap(Object? raw) => <String, bool?>{
  for (final MapEntry<String, Object?> e in _map(raw).entries)
    e.key: _bool(e.value),
};

Duration? _durationMs(Object? raw) {
  final int? ms = _int(raw);
  return ms == null ? null : Duration(milliseconds: ms);
}

PermissionStates decodePermissionStates(Map<String, Object?> section) =>
    PermissionStates(
      granted: _boolMap(section['granted']),
      undeclared: _strings(section['undeclared']).toSet(),
      declaredPermissions: _strings(section['declaredPermissions']),
      batteryExemptionDeclared:
          _bool(section['batteryExemptionDeclared']) ?? false,
      bootReceiverDeclared: _bool(section['bootReceiverDeclared']) ?? false,
    );

MonitoringStates decodeMonitoringStates(Map<String, Object?> section) {
  final Map<String, Object?> services = _map(section['runningServices']);
  return MonitoringStates(
    usageAccess: _bool(section['usageAccess']) ?? false,
    usageAccessMode: _string(section['usageAccessMode']) ?? 'refused',
    batteryOptimizationIgnored: _bool(section['batteryOptimizationIgnored']),
    notificationImportance: _string(section['notificationImportance']),
    exactAlarmsAllowed: _bool(section['exactAlarmsAllowed']),
    serviceCount: _int(services['count']),
    foregroundTypedServiceCount: _int(services['withForegroundType']),
    silentRingtone: _bool(section['silentMode']),
  );
}

LastFix? _lastFix(Object? raw) {
  final Map<String, Object?> fix = _map(raw);
  final String? provider = _string(fix['provider']);
  final double? metres = _double(fix['accuracyMetres']);
  if (provider == null || metres == null) return null;
  return LastFix(
    provider: provider,
    accuracyMetres: metres,
    age: _durationMs(fix['ageMs']),
    hasAltitude: _bool(fix['hasAltitude']) ?? false,
    fromMockProvider: _bool(fix['fromMockProvider']),
  );
}

LocationStates decodeLocationStates(Map<String, Object?> section) =>
    LocationStates(
      serviceAvailable: _bool(section['serviceAvailable']) ?? false,
      gpsOn: _bool(section['gpsOn']),
      networkOn: _bool(section['networkOn']),
      passiveOn: _bool(section['passiveOn']),
      mayAsk: _bool(section['mayAsk']),
      lastFix: _lastFix(section['lastFix']),
      withheldBecause: _string(section['lastFixWithheldBecause']),
    );

DeviceAdminStates decodeDeviceAdminStates(Map<String, Object?> section) =>
    DeviceAdminStates(
      serviceAvailable: _bool(section['serviceAvailable']) ?? false,
      receiverDeclared: _bool(section['receiverDeclared']) ?? false,
      adminActive: _bool(section['adminActive']) ?? false,
      deviceOwner: _bool(section['deviceOwner']),
      profileOwner: _bool(section['profileOwner']),
      activeAdminCount: _int(section['activeAdminCount']),
      restrictionsInForce: _optionalStrings(section['restrictionsInForce']),
      screenLockTimeout: _durationMs(section['screenLockTimeoutMs']),
      storageEncryptionState: _string(section['storageEncryptionState']),
      restrictionsReadable: _bool(section['userRestrictionsReadable']),
    );

CommunicationStates decodeCommunicationStates(Map<String, Object?> section) =>
    CommunicationStates(
      microphoneAllowed: _bool(section['microphoneAllowed']),
      cameraAllowed: _bool(section['cameraAllowed']),
      audioServiceAvailable: _bool(section['audioServiceAvailable']),
      microphoneMuted: _bool(section['microphoneMutedBySystem']),
      audioMode: _string(section['audioMode']),
      speakerphoneOn: _bool(section['speakerphoneOn']),
      inputDeviceCount: _int(section['inputDevices']),
      cameraCount: _int(section['camerasPresent']),
    );

/// One section's answer, or the reason the phone gave instead of one.
///
/// A section that arrived empty counts as refused rather than answered-with-nothing:
/// a screen has no honest sentence to build from an empty map, and `no-answer` keeps
/// that visible instead of hiding it behind a row of dashes.
AreaReading<T> areaReading<T extends Object>(
  String section,
  Map<String, Object?> sections,
  Map<String, Object?> errors,
  T Function(Map<String, Object?> values) decode,
) {
  final Object? reason = errors[section];
  if (reason is String) return RefusedArea<T>(reason);
  final Map<String, Object?> values = _map(sections[section]);
  if (values.isEmpty) return RefusedArea<T>('no-answer');
  return AnsweredArea<T>(decode(values));
}

/// The maps a reply carries, read the way the native lane files them.
(Map<String, Object?> sections, Map<String, Object?> errors) sectionMaps(
  Object? reply,
) {
  final Map<String, Object?> envelope = _map(reply);
  return (_map(envelope['sections']), _map(envelope['sectionErrors']));
}
