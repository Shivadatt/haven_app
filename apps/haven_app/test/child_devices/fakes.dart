import 'package:haven_app/features/child_devices/data/devices_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// A device row as the model would carry it. `secretHash` is set only because
/// the real row has the column; no screen renders it, and a test that needs to
/// prove that says so out loud.
///
/// Times are ISO text because a Dart default value has to be a compile-time
/// constant; `lastSeenAt: ''` is the never-reported state.
Device device(
  String id, {
  String name = 'Ivy phone',
  String status = 'active',
  String lastSeenAt = '2026-11-01T09:00:00.000Z',
  String? revokedAt,
}) => Device(
  id: id,
  familyId: 'f1',
  childUserId: 'c1',
  installationId: 'i-$id',
  displayName: name,
  platform: 'android',
  enforcementMode: 'block',
  policyVersion: 3,
  status: status,
  lastSeenAt: DateTime.tryParse(lastSeenAt),
  credentialRevokedAt: revokedAt == null ? null : DateTime.parse(revokedAt),
  secretHash: 'never-shown',
);

/// The device lane's answers. Every field defaults to the refusal the real
/// repository gives, so a test that forgets to seed a fake still exercises the
/// honest path.
class FakeDevicesRepository implements DevicesRepository {
  FakeDevicesRepository({this.devices, this.record});

  /// Null means the list read is refused. An empty list is a different answer:
  /// nothing is paired.
  List<Device>? devices;

  /// The one record this device's screen asks for. Null means refused.
  Device? record;

  HavenFailure? listFailWith;
  HavenFailure? recordFailWith;
  HavenFailure? revokeFailWith;
  HavenFailure? recoveryFailWith;

  final List<String> calls = [];
  final List<String> named = [];

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
  Future<Result<void>> revoke(String deviceId) async {
    calls.add('revoke');
    named.add(deviceId);
    return _refused(revokeFailWith, 'revoking a device');
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
