import 'package:haven_app/features/child_devices/data/devices_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// A device row as the model would carry it.
Device fakeDevice(
  String id, {
  String name = 'Ivy phone',
  String status = 'active',
  String lastSeenAt = '2026-11-01T09:00:00.000Z',
  String? revokedAt,
  String childUserId = 'c1',
  int? batteryLevel,
  String installationId = '',
}) => Device(
  id: id,
  familyId: 'f1',
  childUserId: childUserId,
  installationId: installationId.isEmpty ? 'i-$id' : installationId,
  displayName: name,
  platform: 'android',
  enforcementMode: 'block',
  policyVersion: 3,
  status: status,
  batteryLevel: batteryLevel,
  lastSeenAt: DateTime.tryParse(lastSeenAt),
  credentialRevokedAt: revokedAt == null ? null : DateTime.parse(revokedAt),
  secretHash: 'never-shown',
);

const device = fakeDevice;

/// The device lane's answers. Every field defaults to the refusal the real
/// repository gives, so a test that forgets to seed a fake still exercises the
/// honest path.
class FakeDevicesRepository implements DevicesRepository {
  FakeDevicesRepository({this.devices, this.record});

  List<Device>? devices;
  Device? record;

  HavenFailure? listFailWith;
  HavenFailure? recordFailWith;
  HavenFailure? revokeFailWith;
  HavenFailure? recoveryFailWith;
  HavenFailure? createFailWith;
  HavenFailure? renameFailWith;
  HavenFailure? assignFailWith;

  final List<String> calls = [];
  final List<String> named = [];
  String? lastRenamedId;
  String? lastNewName;
  String? lastAssignedChildUserId;

  @override
  Future<Result<List<Device>>> pairedDevices() async {
    calls.add('pairedDevices');
    final HavenFailure? failure = listFailWith;
    if (failure != null) return Err<List<Device>>(failure);
    final List<Device>? read = devices;
    return read == null
        ? blocked<List<Device>>('fake: no contract for listing devices')
        : Ok<List<Device>>(read);
  }

  @override
  Future<Result<Device>> device(String deviceId) async {
    calls.add('device');
    named.add(deviceId);
    final HavenFailure? failure = recordFailWith;
    if (failure != null) return Err<Device>(failure);
    final Device? read = record;
    return read == null
        ? blocked<Device>('fake: no contract for reading a device')
        : Ok<Device>(read);
  }

  @override
  Future<Result<void>> revoke(String deviceId, {bool execute = false}) async {
    calls.add('revoke');
    named.add(deviceId);
    return _refused(revokeFailWith, 'revoking a device');
  }

  @override
  Future<Result<void>> unlink(String deviceId) async {
    calls.add('unlink');
    named.add(deviceId);
    if (devices != null) {
      devices = devices!.where((d) => d.id != deviceId).toList();
    }
    return _refused(revokeFailWith, 'unlinking a device');
  }

  @override
  Future<Result<Device>> createDevice({
    required String displayName,
    required String childUserId,
    String platform = 'android',
    int? batteryLevel,
  }) async {
    calls.add('createDevice');
    final HavenFailure? failure = createFailWith;
    if (failure != null) return Err<Device>(failure);
    final Device created = fakeDevice(
      'd-${calls.length}',
      name: displayName,
      childUserId: childUserId,
      batteryLevel: batteryLevel,
      installationId: 'sim-d-${calls.length}',
    );
    if (devices != null) {
      devices = [...devices!, created];
    }
    return Ok<Device>(created);
  }

  @override
  Future<Result<void>> rename({
    required String deviceId,
    required String name,
  }) async {
    calls.add('rename');
    lastRenamedId = deviceId;
    lastNewName = name;
    final HavenFailure? failure = renameFailWith;
    if (failure != null) return Err<void>(failure);
    if (record != null && record!.id == deviceId) {
      record = fakeDevice(
        deviceId,
        name: name,
        childUserId: record!.childUserId,
        status: record!.status ?? 'active',
        batteryLevel: record!.batteryLevel,
        installationId: record!.installationId,
      );
    }
    return okVoid();
  }

  @override
  Future<Result<void>> assignChild({
    required String deviceId,
    required String childUserId,
  }) async {
    calls.add('assignChild');
    lastAssignedChildUserId = childUserId;
    final HavenFailure? failure = assignFailWith;
    if (failure != null) return Err<void>(failure);
    if (record != null && record!.id == deviceId) {
      record = fakeDevice(
        deviceId,
        name: record!.displayName,
        childUserId: childUserId,
        status: record!.status ?? 'active',
        batteryLevel: record!.batteryLevel,
        installationId: record!.installationId,
      );
    }
    return okVoid();
  }

  @override
  Future<Result<void>> requestRecovery(String deviceId) async {
    calls.add('requestRecovery');
    named.add(deviceId);
    return _refused(recoveryFailWith, 'asking a device to re-check');
  }

  Future<Result<void>> _refused(HavenFailure? override, String what) async =>
      override == null
      ? blocked<void>('fake: no contract for $what')
      : Err<void>(override);
}
