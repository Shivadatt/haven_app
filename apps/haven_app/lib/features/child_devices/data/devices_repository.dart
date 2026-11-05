import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';

/// A paired device repository interface.
abstract interface class DevicesRepository {
  Future<Result<List<Device>>> pairedDevices();

  Future<Result<Device>> device(String deviceId);

  Future<Result<void>> revoke(String deviceId, {bool execute = false});

  Future<Result<void>> requestRecovery(String deviceId);

  Future<Result<Device>> createDevice({
    required String displayName,
    required String childUserId,
    String platform = 'android',
    int? batteryLevel,
  });

  Future<Result<void>> rename({
    required String deviceId,
    required String name,
  });

  Future<Result<void>> unlink(String deviceId);

  Future<Result<void>> assignChild({
    required String deviceId,
    required String childUserId,
  });
}

final class HavenDevicesRepository implements DevicesRepository {
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
  Future<Result<void>> revoke(String deviceId, {bool execute = false}) async => blocked(
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

  @override
  Future<Result<Device>> createDevice({
    required String displayName,
    required String childUserId,
    String platform = 'android',
    int? batteryLevel,
  }) async =>
      CapturedGaps.deviceLaneUnavailable<Device>();

  @override
  Future<Result<void>> rename({
    required String deviceId,
    required String name,
  }) async =>
      CapturedGaps.deviceLaneUnavailable<void>();

  @override
  Future<Result<void>> unlink(String deviceId) => revoke(deviceId, execute: true);

  @override
  Future<Result<void>> assignChild({
    required String deviceId,
    required String childUserId,
  }) async =>
      CapturedGaps.deviceLaneUnavailable<void>();
}
