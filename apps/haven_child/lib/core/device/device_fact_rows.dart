import 'device_information.dart';

/// One label/value pair as the device screen and the onboarding review step
/// show it. A value is never null at render time: unknown fields are the
/// literal [DeviceFacts.unavailable] text, decided HERE so both screens read
/// identically and no widget can invent its own filler.
final class DeviceFactRow {
  const DeviceFactRow({required this.label, required this.value});

  final String label;
  final String value;

  bool get isUnavailable => value == DeviceFacts.unavailable;
}

abstract final class DeviceFactRows {
  static List<DeviceFactRow> build(DeviceFacts facts) => <DeviceFactRow>[
    DeviceFactRow(label: 'Model', value: facts.model ?? DeviceFacts.unavailable),
    DeviceFactRow(
      label: 'Manufacturer',
      value: facts.manufacturer ?? DeviceFacts.unavailable,
    ),
    DeviceFactRow(
      label: 'Android version',
      value: facts.androidVersion ?? DeviceFacts.unavailable,
    ),
    DeviceFactRow(label: 'App version', value: facts.appVersion),
    DeviceFactRow(label: 'App id', value: facts.applicationId),
    DeviceFactRow(label: 'Registration', value: facts.registrationStatus),
  ];

  /// The honest footnote for every screen that shows these rows.
  static const String stageOneNote =
      'Model and manufacturer need a system read that is not part of this '
      'build yet. Nothing here is estimated: fields without a real read say '
      'Unavailable.';

  static const String registrationNote =
      'Registration happens when a parent pairs this device. Pairing is not '
      'built yet, so this device is not registered to anyone.';
}
