import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_editor_controller.dart';
import 'package:haven_core/haven_core.dart';

import 'editor_nav.dart';
import 'fakes.dart';

/// What the editor does when it writes: the five granted columns and nothing
/// else, and a place is only removed after the parent has read the row.
void main() {
  group('SafeZoneEditorController writes', () {
    test(
      'save sends this zone\'s id and the typed draft, then closes',
      () async {
        final FakeSafeZonesRepository repo = FakeSafeZonesRepository(
          found: zone('z1'),
        );
        final (SafeZoneEditorController subject, EditorNav nav) = editor(repo);
        await subject.load();

        subject.name.text = 'Grandma\'s';
        await subject.save();

        expect(repo.savedIds.single, 'z1');
        expect(repo.lastSaved!.name, 'Grandma\'s');
        expect(nav.closed, 1);
        expect(subject.saveResult.value!.isOk, isTrue);
      },
    );

    test('a refused save is shown and the screen stays open', () async {
      final (SafeZoneEditorController subject, EditorNav nav) = editor(
        FakeSafeZonesRepository(found: zone('z1'))
          ..writeFailWith = const PermissionFailure('fake: write denied'),
      );
      await subject.load();

      subject.name.text = 'Grandma\'s';
      await subject.save();

      expect(subject.saveResult.value!.failureOrNull, isA<PermissionFailure>());
      expect(nav.closed, 0);
      expect(subject.isSaving.value, isFalse);
    });

    test('delete removes the zone the parent opened and then closes', () async {
      final FakeSafeZonesRepository repo = FakeSafeZonesRepository(
        found: zone('z1'),
      );
      final (SafeZoneEditorController subject, EditorNav nav) = editor(repo);
      await subject.load();

      await subject.delete();

      expect(repo.removedIds.single, 'z1');
      expect(nav.closed, 1);
    });

    test('a refused delete is reported and the place is still there', () async {
      final (SafeZoneEditorController subject, EditorNav nav) = editor(
        FakeSafeZonesRepository(found: zone('z1'))
          ..writeFailWith = const BackendFailure('fake: delete denied'),
      );
      await subject.load();

      await subject.delete();

      expect(subject.deleteResult.value!.failureOrNull, isA<BackendFailure>());
      expect(nav.closed, 0);
    });

    test(
      'a place this account never read is saved nothing and removed nothing',
      () async {
        final FakeSafeZonesRepository repo = FakeSafeZonesRepository();
        final (SafeZoneEditorController subject, _) = editor(repo);
        await subject.load();

        await subject.save();
        await subject.delete();

        expect(repo.savedIds, isEmpty);
        expect(repo.removedIds, isEmpty);
      },
    );
  });
}
