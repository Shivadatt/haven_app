import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/child_devices/controllers/device_detail_controller.dart';
import 'package:haven_app/features/child_devices/controllers/devices_controller.dart';
import 'package:haven_app/features/child_devices/data/device_route_args.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('DevicesController', () {
    (DevicesController, List<(String, String, Object?)>) build(
      FakeDevicesRepository repo,
    ) {
      final routes = <(String, String, Object?)>[];
      return (
        DevicesController(
          repository: repo,
          push: (String route, Object? arg) => routes.add(('push', route, arg)),
        ),
        routes,
      );
    }

    test('a refused list stays a refusal', () async {
      final (subject, _) = build(FakeDevicesRepository());

      await subject.load();

      expect(subject.isLoading.value, isFalse);
      expect(subject.devices.value!.failureOrNull, isA<BlockedFailure>());
    });

    test('an empty list is kept as the answer it is', () async {
      final (subject, _) = build(FakeDevicesRepository(devices: const []));
      await subject.load();

      expect(subject.devices.value!.valueOrNull, isEmpty);
      expect(subject.devices.value!.isErr, isFalse);
    });

    test('refresh re-reads rather than reporting what it asked for', () async {
      final repo = FakeDevicesRepository(devices: const []);
      final (subject, _) = build(repo);
      await subject.load();

      repo.devices = [device('d1')];
      await subject.refresh();

      expect(subject.devices.value!.valueOrNull!.single.id, 'd1');
      expect(repo.calls.where((String c) => c == 'pairedDevices').length, 2);
    });

    test('pairing is the only road this screen can offer', () async {
      final (subject, routes) = build(FakeDevicesRepository());
      await subject.load();

      subject.goToPairing();

      expect(routes, [('push', AppRoutes.pairing, null)]);
    });
  });

  group('DeviceDetailController', () {
    DeviceDetailController build(String deviceId, FakeDevicesRepository repo) =>
        DeviceDetailController(deviceId: deviceId, repository: repo);

    test('a device that was never named is not read at all', () async {
      final repo = FakeDevicesRepository();
      final subject = build('', repo);

      await subject.load();

      expect(subject.hasDeviceId, isFalse);
      expect(subject.isLoading.value, isFalse);
      expect(repo.calls, isEmpty);
    });

    test('the record and both actions are read for the named device', () async {
      final repo = FakeDevicesRepository(record: device('d7'));
      final subject = build('d7', repo);

      await subject.load();

      expect(subject.device.value!.valueOrNull!.id, 'd7');
      expect(repo.calls, ['device', 'revoke', 'requestRecovery']);
      expect(repo.named, ['d7', 'd7', 'd7']);
    });

    test('the two actions carry their own refusals', () async {
      final subject = build('d1', FakeDevicesRepository());
      await subject.load();

      expect(subject.revokeGap.value!.missing, contains('revoking a device'));
      expect(
        subject.recoveryGap.value!.missing,
        contains('asking a device to re-check'),
      );
    });

    test('a backend fault is not filed as a missing specification', () async {
      final repo = FakeDevicesRepository()
        ..revokeFailWith = const BackendFailure('The service errored.')
        ..recordFailWith = const NetworkFailure('No connection.');
      final subject = build('d1', repo);

      await subject.load();

      expect(subject.revokeGap.value, isNull);
      expect(subject.device.value!.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('DeviceRouteArgs', () {
    test('only this type parses', () {
      expect(
        DeviceRouteArgs.tryParse(
          const DeviceRouteArgs(deviceId: 'd1'),
        )!.deviceId,
        'd1',
      );
      expect(DeviceRouteArgs.tryParse('d1'), isNull);
      expect(DeviceRouteArgs.tryParse(null), isNull);
    });
  });
}
