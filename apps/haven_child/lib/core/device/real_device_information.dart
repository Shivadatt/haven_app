import 'dart:io';

import '../constants/child_config.dart';
import 'device_information.dart';

/// Pure-Dart device facts. No plugin, no method channel, no permission.
///
/// Exactly what `dart:io` exposes on Android is read here:
/// * `Platform.operatingSystemVersion` — the engine's pure-Dart view of
///   Android's `Build.VERSION` release information (e.g. `SDK 36, Android 16`).
///   This is a real read, so the field shows a value, not a fallback.
/// * `Build.MODEL` / `Build.MANUFACTURER` have **no pure-Dart reader** on
///   Android — the only honest Stage-1 answer is null, and the UI says
///   "Unavailable". Stage 2's native lane (decision D-4) replaces them;
///   until then adding channel code here would violate the stage plan.
final class RealDeviceInformation implements DeviceInformation {
  const RealDeviceInformation();

  static const String notRegistered = 'Not registered';

  @override
  DeviceFacts read() {
    String? androidVersion;
    try {
      if (Platform.isAndroid) {
        androidVersion = Platform.operatingSystemVersion;
      }
    } on Object {
      androidVersion = null;
    }
    return DeviceFacts(
      // Model and manufacturer are deliberately null (see class comment):
      // they arrive with the Stage-2 native reads, never as guesses here.
      model: null,
      manufacturer: null,
      androidVersion: androidVersion,
      appVersion: ChildConfig.appVersion,
      applicationId: ChildConfig.applicationId,
      registrationStatus: notRegistered,
    );
  }
}
