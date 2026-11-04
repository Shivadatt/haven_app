import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';

/// A paired device, which this build cannot list or act on.
///
/// The read is closed twice over: `devices` has a SELECT policy but no SELECT
/// grant for `authenticated` (F6), and the `device-register` Edge Function that
/// owns the device lane is a minified bundle whose request contract was never
/// readable. Revoking and recovery are captured RPCs, and the role this app
/// signs in as holds no EXECUTE on any of them. So every method here is a typed
/// refusal — a real device list would need an owner decision about the grant,
/// not a guess in this file.
abstract interface class DevicesRepository {
  Future<Result<List<Device>>> pairedDevices();

  Future<Result<Device>> device(String deviceId);

  Future<Result<void>> revoke(String deviceId);

  Future<Result<void>> requestRecovery(String deviceId);
}

final class HavenDevicesRepository implements DevicesRepository {
  /// Takes no providers: there is nothing in this build it could safely reach
  /// for. Keeping the type an interface is what lets the screens stay honest.
  HavenDevicesRepository();

  @override
  Future<Result<List<Device>>> pairedDevices() async =>
      CapturedGaps.deviceLaneUnavailable<List<Device>>();

  @override
  Future<Result<Device>> device(String deviceId) async => blocked(
    CapturedGaps.deviceLaneMissing,
    requirement: 'Haven cannot show this device in this build yet.',
  );

  @override
  Future<Result<void>> revoke(String deviceId) async => blocked(
    '${CapturedGaps.rpcLaneMissing}; and `devices` has no UPDATE or DELETE '
    'grant or policy for any client role '
    '(docs/stage1/04-rls-matrix.md:112-113), so nothing could revoke a device '
    'row from here either',
    requirement: 'Haven cannot revoke a device in this build yet.',
  );

  @override
  Future<Result<void>> requestRecovery(String deviceId) async => blocked(
    '${CapturedGaps.rpcLaneMissing}; and the device lane behind '
    '`request_device_recovery` is a minified Edge Function bundle whose request '
    'and reply shapes were never captured '
    '(docs/stage1/evidence/edge-functions/capture-20261030.json)',
    requirement: 'Haven cannot ask a device to re-check its rules yet.',
  );
}
