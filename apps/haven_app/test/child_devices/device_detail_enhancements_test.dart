import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/child_devices/controllers/device_detail_controller.dart';

import '../support/data_fakes.dart';
import 'fakes.dart';

void main() {
  group('DeviceDetailController Enhancements', () {
    late FakeDevicesRepository repo;
    late FakeRowReader reader;

    setUp(() {
      repo = FakeDevicesRepository(
        record: fakeDevice(
          'dev-1',
          name: 'Pixel 8',
          status: 'active',
          childUserId: 'child-123',
          batteryLevel: 85,
        ),
      );
      reader = FakeRowReader({
        TableName.profiles: [
          {
            'id': 'child-123',
            'display_name': 'Leo',
            'avatar': '🦁',
            'age_bracket': '8–11',
            'role': 'child',
          },
        ],
      });
    });

    test('loads assigned child profile information', () async {
      final controller = DeviceDetailController(
        deviceId: 'dev-1',
        repository: repo,
        rows: () => reader,
      );

      await controller.load();

      expect(controller.device.value?.valueOrNull?.displayName, equals('Pixel 8'));
      expect(controller.assignedChild.value, isNotNull);
      expect(controller.assignedChild.value!.displayName, equals('Leo'));
      expect(controller.assignedChild.value!.avatar, equals('🦁'));
      expect(controller.statusExplanation, contains('Active:'));
    });

    test('device rename triggers repository and reloads', () async {
      final controller = DeviceDetailController(
        deviceId: 'dev-1',
        repository: repo,
        rows: () => reader,
      );

      final ok = await controller.rename('Leo Pixel');

      expect(ok, isTrue);
      expect(repo.lastRenamedId, equals('dev-1'));
      expect(repo.lastNewName, equals('Leo Pixel'));
    });

    test('device unlink triggers repository and navigates back', () async {
      bool backed = false;
      final controller = DeviceDetailController(
        deviceId: 'dev-1',
        repository: repo,
        rows: () => reader,
        back: () => backed = true,
      );

      final ok = await controller.unlinkDevice();

      expect(ok, isTrue);
      expect(backed, isTrue);
    });

    test('reassigns child successfully', () async {
      final controller = DeviceDetailController(
        deviceId: 'dev-1',
        repository: repo,
        rows: () => reader,
      );

      final ok = await controller.assignChild('child-456');

      expect(ok, isTrue);
      expect(repo.lastAssignedChildUserId, equals('child-456'));
    });
  });
}
