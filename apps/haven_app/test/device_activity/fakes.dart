import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_activity/data/activity_models.dart';
import 'package:haven_app/features/device_activity/data/activity_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.usage_daily` as captured
/// (`docs/stage1/03-data-model.md:56`, columns at A3 `:361-372`): one package,
/// one day, one total. `day` and `last_used_at` are nullable in the model by
/// design, so a fixture that drops them tests the fallbacks rather than hiding
/// them.
Map<String, Object?> usageRow(
  String id, {
  String deviceId = 'd1',
  String? day = '2026-11-01',
  String packageName = 'com.example.map',
  String appLabel = 'Mapler',
  int totalMs = 4_500_000,
  String? lastUsedAt = '2026-11-01T18:04:00.000Z',
  String source = 'usage_stats',
}) => {
  'id': id,
  'device_id': deviceId,
  'family_id': 'f1',
  'day': day,
  'package_name': packageName,
  'app_label': appLabel,
  'total_ms': totalMs,
  'last_used_at': lastUsedAt,
  'uploaded_at': '2026-11-02T00:30:00.000Z',
  'source': source,
};

/// The tables the activity read touches: the caller's own membership row, and
/// the day-rows for that family.
Map<String, List<Map<String, Object?>>> activityTables({
  List<Map<String, Object?>> usage = const [],
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
  TableName.usageDaily: usage,
};

/// One already-parsed line, for the controller and widget tests that care about
/// presentation and not about the row plane.
///
/// The two timestamps are ISO text with `null` reserved for "the column was
/// empty", because a default value has to be a constant expression and
/// `DateTime.utc(...)` is not one.
UsageLine line({
  String app = 'Mapler',
  int totalMs = 4_500_000,
  String? deviceName,
  String? day = '2026-11-01',
  String? lastUsedAt = '2026-11-01T18:04:00.000Z',
}) => UsageLine(
  UsageDaily(
    id: 'u-$app',
    deviceId: 'd1',
    familyId: 'f1',
    day: day == null ? null : DateTime.parse(day),
    packageName: 'com.example.map',
    appLabel: app,
    totalMs: totalMs,
    lastUsedAt: lastUsedAt == null ? null : DateTime.parse(lastUsedAt),
    uploadedAt: DateTime.utc(2026, 11, 2),
    source: 'usage_stats',
  ),
  deviceName: deviceName,
);

UsageBoard board({
  List<UsageLine> lines = const [],
  BlockedFailure? deviceGap,
  String? deviceId,
}) => UsageBoard(
  familyId: 'f1',
  lines: lines,
  deviceGap: deviceGap,
  deviceId: deviceId,
);

/// The activity lane's answers. Nothing seeded means nothing was read, which is
/// the refusal path — the same shape the real repository gives when a seam has no
/// contract — and not a silently empty board.
class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({this.board, this.noFamily = false, this.failWith});

  /// The board the read returns. Null with [noFamily] false is a refusal.
  UsageBoard? board;

  /// True answers "this account has no family yet", which the screen routes to
  /// setup.
  bool noFamily;

  HavenFailure? failWith;

  int loadCount = 0;

  /// What the last read was narrowed to. Null is "the whole family".
  String? lastDeviceId;

  @override
  Future<Result<UsageBoard?>> load({String? deviceId}) async {
    loadCount++;
    lastDeviceId = deviceId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<UsageBoard?>(failure);
    if (noFamily) return const Ok<UsageBoard?>(null);
    final UsageBoard? read = board;
    return read == null
        ? blocked<UsageBoard?>('fake: no usage read seeded')
        : Ok<UsageBoard?>(read);
  }
}
