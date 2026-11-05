import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_create_controller.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_editor_controller.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

void main() {
  late FakeSafeZonesRepository repo;

  setUp(() {
    repo = FakeSafeZonesRepository(
      board: board(
        zones: [
          SafeZone(
            id: 'z1',
            familyId: 'f1',
            name: 'Home Zone',
            lat: 37.7749,
            lng: -122.4194,
            radiusM: 200,
            active: true,
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        ],
      ),
    );
  });

  group('Safe-Zone Enhancements - MODULE I', () {
    test('create controller detects duplicate zone name and warns', () async {
      final controller = SafeZoneCreateController(repository: repo);
      await controller.loadExistingZones();

      controller.name.text = 'home zone';
      expect(controller.duplicateWarning, isNotNull);
      expect(controller.duplicateWarning, contains('already exists'));
      expect(controller.isValid, isFalse);
      expect(controller.canCreate, isFalse);

      controller.name.text = 'Grandma House';
      expect(controller.duplicateWarning, isNull);
      controller.dispose();
    });

    test('coordinate selection and radius stepping', () {
      final controller = SafeZoneCreateController(repository: repo);
      controller.setCoordinates(37.7800, -122.4100);
      expect(controller.lat.text, '37.780000');
      expect(controller.lng.text, '-122.410000');

      controller.setRadius(250);
      expect(controller.radiusM.value, 250);

      controller.stepRadius(50);
      expect(controller.radiusM.value, 300);

      controller.stepRadius(-100);
      expect(controller.radiusM.value, 200);
      controller.dispose();
    });

    test('child association selector and manual entry toggle', () {
      final controller = SafeZoneCreateController(repository: repo);
      expect(controller.associatedChild.value, 'All Children');

      controller.associatedChild.value = 'Ivy Phone';
      expect(controller.associatedChild.value, 'Ivy Phone');

      expect(controller.isManualEntry.value, isFalse);
      controller.isManualEntry.value = true;
      expect(controller.isManualEntry.value, isTrue);
      controller.dispose();
    });

    test('editor controller updates coordinates and checks duplicates excluding own id', () async {
      final controller = SafeZoneEditorController(zoneId: 'z1', repository: repo);
      await controller.load();
      await controller.loadExistingZones();

      // Keeping own name is not flagged as a duplicate
      controller.name.text = 'Home Zone';
      expect(controller.duplicateWarning, isNull);

      // Stepping radius
      controller.stepRadius(50);
      expect(controller.radiusM.text, '200');

      // Selecting coordinates from map preview
      controller.setCoordinates(37.7755, -122.4188);
      expect(controller.lat.text, '37.775500');
      expect(controller.lng.text, '-122.418800');

      controller.dispose();
    });
  });
}
