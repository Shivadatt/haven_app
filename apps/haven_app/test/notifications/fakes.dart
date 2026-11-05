import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/notifications/data/alerts_models.dart';
import 'package:haven_app/features/notifications/data/alerts_repository.dart';
import 'package:haven_app/features/notifications/services/alert_delivery.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Rows shaped like `public.safety_alerts` as captured: the ten columns of
/// `A3-staging-load-v1.sql:348`, with `type` bound by `safety_alerts_type_check`
/// (`:491`), `severity` by `safety_alerts_severity_check` (`:490`), `message` 1..300
/// characters (`:488`) and `payload` proven only to be a JSON object (`:489`).
Map<String, Object?> alertRow(
  String id, {
  String deviceId = 'd1',
  String type = 'geofence_exit',
  String severity = 'warning',
  String message = 'Ivy left a safe place',
  Map<String, Object?> payload = const {},
  String createdAt = '2026-11-01T09:00:00.000Z',
  String? acknowledgedAt,
  String? acknowledgedBy,
}) => {
  'id': id,
  'family_id': 'f1',
  'device_id': deviceId,
  'type': type,
  'severity': severity,
  'message': message,
  'payload': payload,
  'created_at': createdAt,
  'acknowledged_at': acknowledgedAt,
  'acknowledged_by': acknowledgedBy,
};

/// The tables the reports screen touches. `devices` is absent on purpose: naming a
/// report's device is F6 and the fake refuses that lane.
Map<String, List<Map<String, Object?>>> alertTables({
  List<Map<String, Object?>> alerts = const [],
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
  TableName.safetyAlerts: alerts,
};

AlertLine alertLine({
  String? deviceName,
  String id = 'a1',
  String type = 'geofence_exit',
  String severity = 'warning',
  String message = 'Ivy left a safe place',
  Map<String, Object?> payload = const {},
  bool acknowledged = false,
}) => AlertLine(
  SafetyAlert.fromRow(
    alertRow(
      id,
      type: type,
      severity: severity,
      message: message,
      payload: payload,
      acknowledgedAt: acknowledged ? '2026-11-01T09:30:00.000Z' : null,
      acknowledgedBy: acknowledged ? 'u1' : null,
    ),
  ),
  deviceName: deviceName,
);

AlertBoard alertBoard({
  List<AlertLine> lines = const [],
  BlockedFailure? deviceGap,
}) => AlertBoard(
  familyId: 'f1',
  lines: lines,
  ackGap: HavenAlertsRepository.ackGap,
  deliveryGap: HavenAlertsRepository.deliveryGap,
  deviceGap: deviceGap,
);

/// The reports lane's answers. Nothing seeded is the refusal path, so a test that
/// forgets to seed cannot pass by reading a fabricated empty list.
class FakeAlertsRepository implements AlertsRepository {
  FakeAlertsRepository({this.board, this.noFamily = false, this.failWith});

  AlertBoard? board;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;

  @override
  Future<Result<AlertBoard?>> load() async {
    loadCount++;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<AlertBoard?>(failure);
    if (noFamily) return const Ok<AlertBoard?>(null);
    final AlertBoard? read = board;
    return read == null
        ? blocked<AlertBoard?>('fake: no report read seeded')
        : Ok<AlertBoard?>(read);
  }

  @override
  Future<Result<void>> markAsRead(String alertId, {String? userId}) async =>
      okVoid();

  @override
  Future<Result<void>> markAsUnread(String alertId) async => okVoid();

  @override
  Future<Result<void>> deleteAlert(String alertId) async => okVoid();
}

/// A delivery lane that says it registered, which nothing in this build can.
///
/// It exists for the one assertion that matters: the card shows what the seam
/// answers rather than implying a phone is subscribed.
class RegisteredDelivery implements AlertDelivery {
  bool registered = true;
  final List<String> handedOver = [];

  @override
  Future<Result<void>> registerTarget(String target) async {
    handedOver.add(target);
    return okVoid();
  }

  @override
  Future<Result<void>> clearTarget() async {
    registered = false;
    return okVoid();
  }

  @override
  bool get isRegistered => registered;
}
