import 'device_information.dart';

/// Fixed device facts for widget/unit tests (Agent 3's seam).
///
/// Mirrors the real build's honesty: `manufacturer` and `model` are null here
/// too, so a test can never accidentally prove a fabricated value renders.
final class FakeDeviceInformation implements DeviceInformation {
  const FakeDeviceInformation({
    this.androidVersion = 'SDK 36, Android 16 (test)',
    this.appVersion = '0.1.0-test',
    this.applicationId = 'com.haven.child',
    this.registrationStatus = 'Not registered',
  });

  final String? androidVersion;
  final String appVersion;
  final String applicationId;
  final String registrationStatus;

  @override
  DeviceFacts read() => DeviceFacts(
    model: null,
    manufacturer: null,
    androidVersion: androidVersion,
    appVersion: appVersion,
    applicationId: applicationId,
    registrationStatus: registrationStatus,
  );
}
