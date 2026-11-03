import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

Map<String, Object?> _sessionRow() => {
  'id': 's',
  'family_id': 'f',
  'device_id': 'd',
  'parent_user_id': 'p',
  'child_user_id': 'c',
  'kind': 'video',
  'status': 'active',
  'requested_at': '2026-11-03T06:00:00Z',
  'consent_recorded': true,
  'created_at': '2026-11-03T06:00:00Z',
};

void main() {
  group('round trips', () {
    test('SafeZone survives toRow/fromRow on the columns that matter', () {
      final z = SafeZone(
        id: 'a',
        familyId: 'f',
        name: 'Home',
        lat: 12.9,
        lng: 77.6,
        radiusM: 150,
        active: true,
        createdAt: DateTime.utc(2026, 11, 1),
      );
      final back = SafeZone.fromRow(z.toRow());
      expect(back.name, 'Home');
      expect(back.radiusM, 150);
      expect(back.active, isTrue);
      expect(back.createdBy, isNull);
    });

    test('SafeZoneState writes a UTC ISO timestamp and round-trips', () {
      final state = SafeZoneState(
        zoneId: 'z',
        deviceId: 'd',
        inside: true,
        updatedAt: DateTime.utc(2026, 11, 3, 6, 15),
      );
      final row = state.toRow();
      expect(row['inside'], isTrue);
      expect(row['updated_at'], '2026-11-03T06:15:00.000Z');
      expect(
        SafeZoneState.fromRow(row).updatedAt,
        DateTime.utc(2026, 11, 3, 6, 15),
      );
    });

    test('LocationEvent keeps accuracy as reported', () {
      final e = LocationEvent.fromRow({
        'id': 'l',
        'device_id': 'd',
        'family_id': 'f',
        'lat': 1.5,
        'lng': 2.5,
        'accuracy_m': 12,
        'recorded_at': '2026-11-03T06:00:00Z',
        'received_at': '2026-11-03T06:00:05Z',
        'source': 'gps',
      });
      expect(e.accuracyM, 12.0);
      expect(e.source, 'gps');
      expect(
        e.isStale(
          maxAge: const Duration(minutes: 1),
          now: DateTime.utc(2026, 11, 3, 7),
        ),
        isTrue,
      );
      expect(
        e.isStale(
          maxAge: const Duration(minutes: 61),
          now: DateTime.utc(2026, 11, 3, 7),
        ),
        isFalse,
      );
    });

    test('RemoteSession consent is a single boolean', () {
      final s = RemoteSession.fromRow(_sessionRow());
      expect(s.sessionKind, SessionKind.video);
      expect(s.mayConnect, isTrue);
      expect(s.isLive, isTrue);
      expect(s.sessionStatus, SessionStatus.active);

      final withdrawn = RemoteSession.fromRow({
        ..._sessionRow(),
        'consent_recorded': false,
      });
      expect(
        withdrawn.mayConnect,
        isFalse,
        reason: 'live but unconsented must not connect',
      );

      final ended = RemoteSession.fromRow({
        ..._sessionRow(),
        'status': 'ended',
        'ended_reason': 'parent',
      });
      expect(ended.isClosed, isTrue);
      expect(ended.mayConnect, isFalse);
    });
  });
}
