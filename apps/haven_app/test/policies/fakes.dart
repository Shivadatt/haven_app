import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/policies/data/policies_models.dart';
import 'package:haven_app/features/policies/data/policies_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.device_policies` as captured: the ten columns of
/// `docs/stage2/migrations/A3-staging-load-v1.sql:208-219`, with `enforcement_status`
/// taken from its CHECK list at `:452` and `version` from `version >= 1` at `:475`.
/// The `policy` object itself is deliberately opaque — only `jsonb_typeof = 'object'`
/// is captured, and no screen is allowed to assume keys.
Map<String, Object?> policyRow(
  String id, {
  String deviceId = 'd1',
  int version = 1,
  String enforcementStatus = 'pending',
  String createdAt = '2026-11-01T09:00:00.000Z',
  String? acknowledgedAt,
  String? lastError,
  Map<String, Object?> policy = const {'opaque': true},
}) => {
  'id': id,
  'device_id': deviceId,
  'family_id': 'f1',
  'version': version,
  'policy': policy,
  'created_by': 'u1',
  'created_at': createdAt,
  'acknowledged_at': acknowledgedAt,
  'enforcement_status': enforcementStatus,
  'last_error': lastError,
};

/// The tables the version read touches. `devices` is absent on purpose: the lane
/// that would name a version's device is F6, and the fake refuses it.
Map<String, List<Map<String, Object?>>> policyTables({
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
  TableName.devicePolicies: rows,
};

/// One already-parsed version. Times are ISO text because a Dart default value
/// has to be a compile-time constant.
PolicyLine policyLine({
  String? deviceName,
  int version = 4,
  String enforcementStatus = 'pending',
  String createdAt = '2026-11-01T09:00:00.000Z',
  String? acknowledgedAt,
  String? lastError,
  Map<String, Object?> policy = const {'opaque': true},
}) => PolicyLine(
  DevicePolicy(
    id: 'p-1',
    deviceId: 'd1',
    familyId: 'f1',
    version: version,
    policy: policy,
    createdAt: DateTime.parse(createdAt),
    createdBy: 'u1',
    acknowledgedAt: acknowledgedAt == null
        ? null
        : DateTime.parse(acknowledgedAt),
    enforcementStatus: enforcementStatus,
    lastError: lastError,
  ),
  deviceName: deviceName,
);

PolicyBoard policyBoard({
  List<PolicyLine> lines = const [],
  BlockedFailure? deviceGap,
  String? deviceId,
}) => PolicyBoard(
  familyId: 'f1',
  deviceId: deviceId,
  lines: lines,
  writeGap: HavenPoliciesRepository.writeGap,
  ruleShapeGap: HavenPoliciesRepository.ruleShapeGap,
  deviceGap: deviceGap,
);

/// The rules lane's answers. Nothing seeded is the refusal path, so a test that
/// forgets to seed cannot pass by reading a fabricated empty list.
class FakePoliciesRepository implements PoliciesRepository {
  FakePoliciesRepository({this.board, this.noFamily = false, this.failWith});

  PolicyBoard? board;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;
  String? lastDeviceId;

  @override
  Future<Result<PolicyBoard?>> load({String? deviceId}) async {
    loadCount++;
    lastDeviceId = deviceId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<PolicyBoard?>(failure);
    if (noFamily) return const Ok<PolicyBoard?>(null);
    final PolicyBoard? read = board;
    return read == null
        ? blocked<PolicyBoard?>('fake: no version read seeded')
        : Ok<PolicyBoard?>(read);
  }
}
