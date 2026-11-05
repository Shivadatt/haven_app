import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/family/controllers/child_profile_controller.dart';

import '../support/data_fakes.dart';
import 'fakes.dart';

void main() {
  group('ChildProfileController Enhancements', () {
    late FakeFamilyRepository repo;
    late FakeRowReader reader;

    setUp(() {
      repo = FakeFamilyRepository(bundle: bundle());
      reader = FakeRowReader({
        TableName.devices: [
          {
            'id': 'dev-child-1',
            'family_id': 'f1',
            'child_user_id': 'c1',
            'device_name': 'Sam Phone',
            'platform': 'android',
            'status': 'active',
          },
        ],
        TableName.devicePolicies: [
          {'id': 'pol-1', 'family_id': 'f1'},
          {'id': 'pol-2', 'family_id': 'f1'},
        ],
        TableName.safeZones: [
          {'id': 'zone-1', 'family_id': 'f1', 'name': 'Home'},
        ],
        TableName.usageDaily: [
          {
            'device_id': 'dev-child-1',
            'duration_seconds': 3600,
          },
        ],
      });
    });

    test('loads assigned devices and summaries for child', () async {
      final controller = ChildProfileController(
        childUserId: 'c1',
        repository: repo,
        rows: () => reader,
      );

      await controller.load();

      expect(controller.assignedDevices.length, equals(1));
      expect(controller.assignedDevices.first.id, equals('dev-child-1'));
      expect(controller.policiesCount.value, equals(2));
      expect(controller.safeZonesCount.value, equals(1));
      expect(controller.dailyUsageMinutes.value, equals(60));
    });

    test('removes child and navigates back to family', () async {
      String? routed;
      final controller = ChildProfileController(
        childUserId: 'c1',
        repository: repo,
        rows: () => reader,
        goTo: (route, arg) => routed = route,
      );

      final ok = await controller.removeChild();

      expect(ok, isTrue);
      expect(repo.calls, contains('unlinkChild'));
      expect(repo.lastChildUserId, equals('c1'));
      expect(routed, equals(AppRoutes.family));
    });
  });
}
