import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/child_devices/data/devices_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// The whole device lane is closed to this build, and each refusal has to name
/// the grant it is waiting on. A parent who reads one of these can tell an owner
/// which of the four walls to settle.
void main() {
  final subject = HavenDevicesRepository();

  Future<BlockedFailure> of(Future<Result<Object?>> read) async =>
      (await read).failureOrNull! as BlockedFailure;

  test('the list refuses with F6, the policy without a grant', () async {
    final BlockedFailure gap = await of(subject.pairedDevices());

    expect(gap, isA<BlockedFailure>());
    expect(gap.message, contains('list paired devices'));
    expect(gap.missing, contains('no SELECT grant for `authenticated`'));
    expect(gap.missing, contains('00-status-register.md:86'));
  });

  test(
    'one device refuses with the same missing read, not another excuse',
    () async {
      final BlockedFailure gap = await of(subject.device('d1'));

      expect(gap.message, contains('show this device'));
      expect(gap.missing, contains('F6'));
    },
  );

  test('revoking names the RPC wall and the missing write grants', () async {
    final BlockedFailure gap = await of(subject.revoke('d1'));

    expect(gap.message, contains('revoke a device'));
    expect(gap.missing, contains('auth_exec=false'));
    expect(gap.missing, contains('04-rls-matrix.md:112-113'));
  });

  test('recovery names the unreadable Edge Function behind it', () async {
    final BlockedFailure gap = await of(subject.requestRecovery('d1'));

    expect(gap.message, contains('re-check its rules'));
    expect(gap.missing, contains('request_device_recovery'));
    expect(gap.missing, contains('capture-20261030.json'));
  });

  test('a refusal is not an empty list', () async {
    final Result<List<Device>> read = await subject.pairedDevices();

    // "Nothing is paired" and "this app cannot see the shelf" are different
    // claims, and only the first one is a value.
    expect(read.isErr, isTrue);
    expect(read.valueOrNull, isNull);
  });

  test('every refusal is marked as needing a specification', () async {
    for (final BlockedFailure gap in [
      await of(subject.pairedDevices()),
      await of(subject.device('d1')),
      await of(subject.revoke('d1')),
      await of(subject.requestRecovery('d1')),
    ]) {
      expect(gap.detail, startsWith('BLOCKED — SPECIFICATION REQUIRED:'));
    }
  });
}
