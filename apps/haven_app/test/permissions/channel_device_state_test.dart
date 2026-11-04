import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/permissions/admin_and_media_states.dart';
import 'package:haven_app/core/permissions/area_reading.dart';
import 'package:haven_app/core/permissions/channel_device_state.dart';
import 'package:haven_app/core/permissions/device_control_states.dart';
import 'package:haven_app/core/permissions/native_device_state.dart';
import 'package:haven_app/core/permissions/permission_and_monitoring_states.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

/// The Dart half of the bridge, driven by a stand-in for the Kotlin one.
///
/// What matters here is not that a map becomes a model — the decoding tests hold
/// that — but what happens when there is no Kotlin side at all, when it refuses, and
/// when one of its five readers fails while the other four answer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(DeviceStateChannel.name);
  final List<MethodCall> asked = <MethodCall>[];

  void replyWith(Object? Function(MethodCall call) answer) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          asked.add(call);
          return answer(call);
        });
  }

  setUp(asked.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('the contract names match the Kotlin side', () {
    // Neither language checks these against the other, so a drifted constant is a
    // silent "no lane to ask" on a phone that has one.
    expect(DeviceStateChannel.name, 'haven.dev/child_device_state');
    expect(DeviceStateChannel.readAllMethod, 'state.readAll');
  });

  test('a full answer becomes a report with every area filled', () async {
    replyWith((_) => deviceStateEnvelope());

    final Result<DeviceStateReport> result =
        await const ChannelNativeDeviceState().read();
    final DeviceStateReport report = result.valueOrNull!;

    expect(asked.single.method, DeviceStateChannel.readAllMethod);
    expect(report.apiLevel, 36);
    expect(report.osRelease, '16');
    expect(report.answeredSections, <String>[
      'permissions',
      'monitoring',
      'location',
      'deviceAdmin',
      'communication',
    ]);
    expect(
      report.permissions.valueOrNull!.answerFor('notifications'),
      PermissionAnswer.allowed,
    );
    expect(
      report.deviceAdmin.valueOrNull!.canConfirmARestriction,
      isFalse,
      reason: 'the phone refused the restriction reading and that is kept',
    );
    expect(report.ageAt(report.readAt), Duration.zero);
  });

  test('one failed reader does not blank the other four', () async {
    replyWith(
      (_) => deviceStateEnvelope(
        sections: <String, Object?>{
          'permissions': <String, Object?>{'granted': <String, Object?>{}},
          'monitoring': <String, Object?>{'usageAccessMode': 'allowed'},
          'communication': <String, Object?>{'inputDevices': 0},
        },
        errors: const <String, Object?>{'location': 'SecurityException'},
      ),
    );

    final DeviceStateReport report =
        (await const ChannelNativeDeviceState().read()).valueOrNull!;

    expect(
      report.location,
      isA<RefusedArea<LocationStates>>(),
      reason: 'the failed section keeps the phone\'s own reason',
    );
    expect(
      (report.location as RefusedArea<LocationStates>).reason,
      'SecurityException',
    );
    expect(report.answeredSections, <String>[
      'permissions',
      'monitoring',
      'communication',
    ]);
    // Absent from the reply is not the same as present-and-refused.
    expect(report.deviceAdmin, isA<RefusedArea<DeviceAdminStates>>());
    expect(
      (report.deviceAdmin as RefusedArea<DeviceAdminStates>).reason,
      'no-answer',
    );
  });

  test(
    'a build with no native lane says so instead of showing nothing',
    () async {
      // No mock handler at all is the genuine shape of a build whose Android side never
      // attached the channel.
      final Result<DeviceStateReport> result =
          await const ChannelNativeDeviceState().read();
      final HavenFailure failure = result.failureOrNull!;

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'This build has no device-state lane to ask.');
      expect(failure.detail, contains(DeviceStateChannel.name));
      expect(asked, isEmpty);
    },
  );

  test(
    'a refusal from the bridge is reported, never read as a clean phone',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            asked.add(call);
            throw PlatformException(
              code: 'no-context',
              message: 'the bridge had no application context',
            );
          });

      final HavenFailure failure =
          (await const ChannelNativeDeviceState().read()).failureOrNull!;

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'The phone refused the device-state question.');
      expect(
        failure.detail,
        'no-context: the bridge had no application context',
      );
    },
  );

  test(
    'an answer this build cannot read is a failure, not an empty report',
    () async {
      replyWith((_) => deviceStateEnvelope()..remove('apiLevel'));
      expect(
        (await const ChannelNativeDeviceState().read()).failureOrNull,
        isA<BackendFailure>(),
      );

      replyWith((_) => 'not a map');
      final HavenFailure shape =
          (await const ChannelNativeDeviceState().read()).failureOrNull!;
      expect(shape, isA<BackendFailure>());
      expect(shape.message, contains('does not understand'));
    },
  );

  test('every read asks again, because a permission can change the moment the '
      'parent leaves for Settings', () async {
    replyWith((_) => deviceStateEnvelope());
    const ChannelNativeDeviceState state = ChannelNativeDeviceState();

    await state.read();
    await state.read();

    expect(asked.length, 2);
  });
}
