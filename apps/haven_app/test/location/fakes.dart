import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/location/data/location_models.dart';
import 'package:haven_app/features/location/data/location_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.location_events` as captured: every column is
/// `NOT NULL` and the four CHECKs bound lat, lng, accuracy and source length
/// (`docs/stage2/migrations/A3-staging-load-v1.sql:269-279,472-475`), so the
/// defaults below are inside those bounds rather than convenient.
Map<String, Object?> locationRow(
  String id, {
  String deviceId = 'd1',
  double lat = 37.7749,
  double lng = -122.4194,
  double accuracyM = 12,
  String recordedAt = '2026-11-01T09:00:00.000Z',
  String receivedAt = '2026-11-01T09:00:20.000Z',
  String source = 'fused',
}) => {
  'id': id,
  'device_id': deviceId,
  'family_id': 'f1',
  'lat': lat,
  'lng': lng,
  'accuracy_m': accuracyM,
  'recorded_at': recordedAt,
  'received_at': receivedAt,
  'source': source,
};

/// The tables the location read touches.
Map<String, List<Map<String, Object?>>> locationTables({
  List<Map<String, Object?>> fixes = const [],
}) => {
  TableName.familyMembers: const [
    {
      'id': 'm-u1',
      'family_id': 'f1',
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-05T10:00:00.000Z',
    },
  ],
  TableName.locationEvents: fixes,
};

/// One already-parsed fix for the controller and widget tests. The timestamps are
/// ISO text because a default value has to be a constant expression.
FixLine fixLine({
  String? deviceName,
  String recordedAt = '2026-11-01T09:00:00.000Z',
  String receivedAt = '2026-11-01T09:00:20.000Z',
  double accuracyM = 12,
  double lat = 37.7749,
  double lng = -122.4194,
  String source = 'fused',
}) => FixLine(
  LocationEvent(
    id: 'l-1',
    deviceId: 'd1',
    familyId: 'f1',
    lat: lat,
    lng: lng,
    accuracyM: accuracyM,
    recordedAt: DateTime.parse(recordedAt),
    receivedAt: DateTime.parse(receivedAt),
    source: source,
  ),
  deviceName: deviceName,
);

FixBoard board({
  List<FixLine> lines = const [],
  BlockedFailure? deviceGap,
  String? deviceId,
}) => FixBoard(
  familyId: 'f1',
  deviceId: deviceId,
  lines: lines,
  deviceGap: deviceGap,
  presenceGap: CapturedGaps.presenceGap,
);

/// The location lane's answers. Nothing seeded is the refusal path, so a test
/// that forgets to seed cannot pass by reading a fabricated empty board.
class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository({this.board, this.noFamily = false, this.failWith});

  FixBoard? board;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;
  String? lastDeviceId;

  @override
  Future<Result<FixBoard?>> load({String? deviceId}) async {
    loadCount++;
    lastDeviceId = deviceId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<FixBoard?>(failure);
    if (noFamily) return const Ok<FixBoard?>(null);
    final FixBoard? read = board;
    return read == null
        ? blocked<FixBoard?>('fake: no place read seeded')
        : Ok<FixBoard?>(read);
  }
}
