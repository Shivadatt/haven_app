import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

/// The labels are what a parent reads; the wire tokens are what the database
/// CHECK constraints accept. Both are pinned here.
void main() {
  group('enum labels', () {
    test('wire tokens map to parent wording', () {
      expect(CommandStatus.expired.label, 'Never reached the device');
      expect(PolicyEnforcementStatus.unsupported.wire, 'unsupported');
      expect(
        labelOrRaw(AlertType.fromWire('geofence_exit'), 'geofence_exit'),
        'Left a safe place',
      );
      expect(
        labelOrRaw(AlertType.fromWire('brand_new'), 'brand_new'),
        'brand_new',
      );
      expect(labelOrRaw(null, null), 'unknown');
    });

    test('every enum round-trips its own values', () {
      for (final v in CommandType.values) {
        expect(CommandType.fromWire(v.wire), v);
      }
      for (final v in SessionStatus.values) {
        expect(SessionStatus.fromWire(v.wire), v);
      }
      for (final v in PairingRequestStatus.values) {
        expect(PairingRequestStatus.fromWire(v.wire), v);
      }
    });
  });
}
