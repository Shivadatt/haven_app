import 'package:get/get.dart';

import '../../../core/device/device_information.dart';

/// The device screen has no data lane to wait on: [DeviceInformation] is a
/// synchronous pure-Dart reader registered at startup. This thin controller
/// exists so the page still follows the GetX bindings -> controller -> view
/// shape every other screen uses (and Agent 3 can inject a fake here).
final class DeviceInfoController extends GetxController {
  DeviceInfoController({required this.device});

  final DeviceInformation device;

  DeviceFacts get facts => device.read();
}
