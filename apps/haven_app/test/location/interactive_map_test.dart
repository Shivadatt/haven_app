import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/location/controllers/location_controller.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

void main() {
  late FakeLocationRepository repo;
  late LocationController controller;

  setUp(() {
    repo = FakeLocationRepository(
      board: board(
        lines: [
          fixLine(
            lat: 37.7749,
            lng: -122.4194,
            source: 'demo_gps',
            deviceName: 'Child Phone',
          ),
        ],
      ),
    );
    controller = LocationController(repository: repo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('Interactive Location Map - MODULE H', () {
    test('loads fix and detects demo coordinate label', () async {
      await controller.load();
      expect(controller.activeLine, isNotNull);
      expect(controller.activeLine!.fix.lat, 37.7749);
      expect(controller.isDemoCoordinate, isTrue);
      expect(controller.isManualCoordinate, isFalse);
    });

    test('zoom controls zoom in, zoom out, and clamp properly', () {
      expect(controller.zoom.value, 1.0);
      controller.zoomIn();
      expect(controller.zoom.value, 1.25);
      controller.zoomOut();
      expect(controller.zoom.value, 1.0);

      for (int i = 0; i < 20; i++) {
        controller.zoomIn();
      }
      expect(controller.zoom.value, 4.0);

      for (int i = 0; i < 20; i++) {
        controller.zoomOut();
      }
      expect(controller.zoom.value, 0.5);
    });

    test('pan update and recenter resets state', () {
      controller.updatePan(const Offset(50, -30));
      expect(controller.panOffset.value, const Offset(50, -30));
      controller.zoomIn();
      controller.selectChild(true);

      controller.recenter();
      expect(controller.zoom.value, 1.0);
      expect(controller.panOffset.value, Offset.zero);
      expect(controller.selectedZone.value, isNull);
      expect(controller.isChildSelected.value, isFalse);
    });

    test('calculates Haversine distance and inside/outside safe zones', () async {
      await controller.load();
      final zoneNear = SafeZone(
        id: 'z1',
        familyId: 'fam1',
        name: 'Home',
        lat: 37.7749,
        lng: -122.4194,
        radiusM: 200,
        active: true,
        createdAt: DateTime.utc(2026),
      );

      final zoneFar = SafeZone(
        id: 'z2',
        familyId: 'fam1',
        name: 'School',
        lat: 37.8000,
        lng: -122.4000,
        radiusM: 100,
        active: true,
        createdAt: DateTime.utc(2026),
      );

      final distNear = controller.distanceToZone(zoneNear);
      expect(distNear, isNotNull);
      expect(distNear!, lessThan(1.0)); // basically 0 meters
      expect(controller.isInsideZone(zoneNear), isTrue);

      final distFar = controller.distanceToZone(zoneFar);
      expect(distFar, isNotNull);
      expect(distFar!, greaterThan(2000.0));
      expect(controller.isInsideZone(zoneFar), isFalse);

      controller.selectZone(zoneNear);
      expect(controller.selectedZone.value?.name, 'Home');
    });

    test('manual entry source is recognized', () async {
      final manualRepo = FakeLocationRepository(
        board: board(
          lines: [
            fixLine(
              lat: 40.7128,
              lng: -74.0060,
              source: 'manual_entry',
              deviceName: 'Manual Fix',
            ),
          ],
        ),
      );
      final manualController = LocationController(repository: manualRepo);
      await manualController.load();

      expect(manualController.isManualCoordinate, isTrue);
      expect(manualController.isDemoCoordinate, isFalse);
      manualController.dispose();
    });
  });
}
