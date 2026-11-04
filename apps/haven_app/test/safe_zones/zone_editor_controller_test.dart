import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_editor_controller.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'editor_nav.dart';

void main() {
  group('SafeZoneEditorController load', () {
    test('seeds the form from the row it read', () async {
      final (SafeZoneEditorController subject, _) = editor(
        FakeSafeZonesRepository(
          found: zone('z1', name: 'School', radiusM: 150),
        ),
      );

      await subject.load();

      expect(subject.name.text, 'School');
      expect(subject.lat.text, '37.7749');
      expect(subject.radiusM.text, '150.0');
      expect(subject.active.value, isTrue);
      expect(subject.hasZone, isTrue);
      expect(subject.hasChanges, isFalse);
    });

    test('a place that is not in this family is kept as a refusal', () async {
      final (SafeZoneEditorController subject, _) = editor(
        FakeSafeZonesRepository(),
      );

      await subject.load();

      expect(subject.zone.value!.failureOrNull, isA<BlockedFailure>());
      expect(subject.hasZone, isFalse);
      expect(subject.canSave, isFalse);
    });

    test(
      'an editor opened with no id reads that id and gets nothing',
      () async {
        final FakeSafeZonesRepository repo = FakeSafeZonesRepository();
        final (SafeZoneEditorController subject, _) = editor(repo, zoneId: '');

        await subject.load();

        expect(repo.readIds.single, '');
      },
    );
  });

  group('SafeZoneEditorController validation', () {
    test('an untouched form is valid and has nothing to send', () async {
      final (SafeZoneEditorController subject, _) = editor(
        FakeSafeZonesRepository(found: zone('z1')),
      );
      await subject.load();

      expect(subject.isValid, isTrue);
      expect(subject.errors.values, everyElement(isNull));
      expect(subject.canSave, isTrue);
      expect(subject.hasChanges, isFalse);
    });

    test('a field the parent types into is reported immediately', () async {
      final (SafeZoneEditorController subject, _) = editor(
        FakeSafeZonesRepository(found: zone('z1')),
      );
      await subject.load();

      subject.radiusM.text = '10';

      expect(subject.errors['radius_m'], isNotNull);
      expect(subject.isValid, isFalse);
      expect(subject.canSave, isFalse);
    });

    test(
      'a change that only re-types the same number is not a change',
      () async {
        final (SafeZoneEditorController subject, _) = editor(
          FakeSafeZonesRepository(found: zone('z1', radiusM: 150)),
        );
        await subject.load();

        subject.radiusM.text = '150';

        expect(subject.hasChanges, isFalse);
        subject.radiusM.text = '151';
        expect(subject.hasChanges, isTrue);
      },
    );

    test('pausing a place is a change even though no text moved', () async {
      final (SafeZoneEditorController subject, _) = editor(
        FakeSafeZonesRepository(found: zone('z1')),
      );
      await subject.load();

      subject.active.value = false;

      expect(subject.hasChanges, isTrue);
      expect(subject.draft.active, isFalse);
    });
  });
}
