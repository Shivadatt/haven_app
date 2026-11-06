/// What this app can know about the device WITHOUT a native channel.
///
/// A null field is rendered "Unavailable" by the UI — the app never guesses a
/// value. `manufacturer` and `model` are honestly null in Stage 1: reading
/// `Build.MANUFACTURER` / `Build.MODEL` needs the Kotlin lane, and the brief
/// forbids adding channel code before the Stage-2 native decision D-4 is
/// implemented. That is the documented Stage-2 upgrade, recorded in
/// `real_device_information.dart` and in the device screen's footnote.
final class DeviceFacts {
  const DeviceFacts({
    required this.appVersion,
    required this.applicationId,
    required this.registrationStatus,
    this.model,
    this.manufacturer,
    this.androidVersion,
  });

  final String? model;
  final String? manufacturer;
  final String? androidVersion;
  final String appVersion;
  final String applicationId;

  /// Honest constant until Stage-2 pairing replaces it — see the rows file.
  final String registrationStatus;

  static const String unavailable = 'Unavailable';
}

/// Read seam for the device screen and the onboarding review step.
abstract interface class DeviceInformation {
  DeviceFacts read();
}
