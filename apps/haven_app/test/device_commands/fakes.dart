import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_commands/data/commands_models.dart';
import 'package:haven_app/features/device_commands/data/commands_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.device_commands` as captured: the fifteen columns
/// of `docs/stage2/migrations/A3-staging-load-v1.sql:175-191`, with `type` and
/// `status` taken from their CHECK lists at `:441-446`. `attempts` has a CHECK of
/// `>= 0` and `idempotency_key` of 1..128, so the defaults sit inside them.
Map<String, Object?> commandRow(
  String id, {
  String deviceId = 'd1',
  String type = 'request_location',
  String status = 'pending',
  int attempts = 0,
  String createdAt = '2026-11-01T09:00:00.000Z',
  String? ackedAt,
  String? errorMessage,
  String? deliveredAt,
}) => {
  'id': id,
  'device_id': deviceId,
  'family_id': 'f1',
  'type': type,
  'payload': <String, Object?>{'reason': 'parent asked'},
  'status': status,
  'idempotency_key': 'key-$id',
  'created_by': 'u1',
  'created_at': createdAt,
  'expires_at': '2026-11-01T09:15:00.000Z',
  'delivered_at': deliveredAt,
  'acked_at': ackedAt,
  'result': null,
  'error_message': errorMessage,
  'attempts': attempts,
};

/// The tables the instruction read touches. `devices` is deliberately absent: the
/// lane that would name an instruction's addressee is F6, and the fake refuses it.
Map<String, List<Map<String, Object?>>> commandTables({
  List<Map<String, Object?>> rows = const [],
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
  TableName.deviceCommands: rows,
};

/// One already-parsed instruction. The timestamps are ISO text because a default
/// value has to be a constant expression.
CommandLine commandLine({
  String? deviceName,
  String type = 'request_location',
  String status = 'pending',
  int attempts = 0,
  String createdAt = '2026-11-01T09:00:00.000Z',
  String? ackedAt,
  String? errorMessage,
}) => CommandLine(
  DeviceCommand(
    id: 'c-1',
    deviceId: 'd1',
    familyId: 'f1',
    type: type,
    payload: const {'reason': 'parent asked'},
    status: status,
    idempotencyKey: 'key-1',
    createdBy: 'u1',
    createdAt: DateTime.parse(createdAt),
    expiresAt: DateTime.parse('2026-11-01T09:15:00.000Z'),
    ackedAt: ackedAt == null ? null : DateTime.parse(ackedAt),
    attempts: attempts,
    errorMessage: errorMessage,
  ),
  deviceName: deviceName,
);

CommandBoard cmdBoard({
  List<CommandLine> lines = const [],
  BlockedFailure? deviceGap,
  String? deviceId,
}) => CommandBoard(
  familyId: 'f1',
  deviceId: deviceId,
  lines: lines,
  writeGap: HavenCommandsRepository.writeGap,
  deviceGap: deviceGap,
);

/// The instruction lane's answers. Nothing seeded is the refusal path, so a test
/// that forgets to seed cannot pass by reading a fabricated empty board.
class FakeCommandsRepository implements CommandsRepository {
  FakeCommandsRepository({this.board, this.noFamily = false, this.failWith});

  CommandBoard? board;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;
  String? lastDeviceId;

  @override
  Future<Result<CommandBoard?>> load({String? deviceId}) async {
    loadCount++;
    lastDeviceId = deviceId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<CommandBoard?>(failure);
    if (noFamily) return const Ok<CommandBoard?>(null);
    final CommandBoard? read = board;
    return read == null
        ? blocked<CommandBoard?>('fake: no instruction read seeded')
        : Ok<CommandBoard?>(read);
  }
}
