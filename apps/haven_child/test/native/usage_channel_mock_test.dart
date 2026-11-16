import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_channel.dart';
import 'package:haven_child/core/native/usage_channel_contract.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MethodChannel channel;
  late List<MethodCall> log;
  late UsageChannel usageChannel;

  void setMock(dynamic result, {Exception? error}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      if (error != null) throw error;
      return result;
    });
  }

  setUp(() {
    channel = const MethodChannel(UsageChannelName.channelName);
    log = <MethodCall>[];
    usageChannel = UsageChannel(channel: channel, isAndroid: true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('UsageChannel Permission Tests', () {
    test('getPermissionStatus returns Ok on granted status', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.status: UsagePermissionStatusValue.granted,
      });
      final Result<UsagePermissionResult> res =
          await usageChannel.getPermissionStatus();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull?.status, UsagePermissionStatus.granted);
      expect(res.valueOrNull?.isGranted, isTrue);
      expect(res.valueOrNull?.apiLevel, 34);
    });

    test('getPermissionStatus returns Ok on denied status', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.status: UsagePermissionStatusValue.denied,
      });
      final Result<UsagePermissionResult> res =
          await usageChannel.getPermissionStatus();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull?.status, UsagePermissionStatus.denied);
      expect(res.valueOrNull?.isGranted, isFalse);
    });

    test('getPermissionStatus returns Ok on unsupported status', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 19,
        UsageEnvelopeKey.status: UsagePermissionStatusValue.unsupported,
      });
      final Result<UsagePermissionResult> res =
          await usageChannel.getPermissionStatus();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull?.status, UsagePermissionStatus.unsupported);
    });

    test('getPermissionStatus returns Err on missing or invalid data', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.status: 'invalid_token',
      });
      final Result<UsagePermissionResult> invalidToken =
          await usageChannel.getPermissionStatus();
      expect(invalidToken.isErr, isTrue);
      expect(invalidToken.failureOrNull, isA<BackendFailure>());

      setMock(<String, dynamic>{
        UsageEnvelopeKey.status: UsagePermissionStatusValue.granted,
      });
      final Result<UsagePermissionResult> missingApi =
          await usageChannel.getPermissionStatus();
      expect(missingApi.isErr, isTrue);
    });
  });

  group('UsageChannel Settings Navigation Tests', () {
    test('openSettings returns Ok on package settings launch', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.intentLaunched: true,
        UsageEnvelopeKey.openedPackageSettings: true,
      });
      final Result<UsageSettingsLaunchResult> res =
          await usageChannel.openSettings();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull?.intentLaunched, isTrue);
      expect(res.valueOrNull?.openedPackageSettings, isTrue);
      expect(res.valueOrNull?.apiLevel, 34);
    });

    test('openSettings handles generic fallback when package launch fails', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.intentLaunched: true,
        UsageEnvelopeKey.openedPackageSettings: false,
      });
      final Result<UsageSettingsLaunchResult> res =
          await usageChannel.openSettings();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull?.intentLaunched, isTrue);
      expect(res.valueOrNull?.openedPackageSettings, isFalse);
    });

    test('openSettings returns Err on malformed response', () async {
      setMock('not_a_map');
      final Result<UsageSettingsLaunchResult> res =
          await usageChannel.openSettings();
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<BackendFailure>());
    });
  });

  group('UsageChannel Platform & Error Handling Tests', () {
    test('non-Android platform returns unsupported_platform Err', () async {
      final nonAndroid = UsageChannel(channel: channel, isAndroid: false);
      final perm = await nonAndroid.getPermissionStatus();
      final sett = await nonAndroid.openSettings();
      final query = await nonAndroid.queryDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: 5000,
      );
      expect(perm.isErr && sett.isErr && query.isErr, isTrue);
      expect(perm.failureOrNull?.detail, 'unsupported_platform');
      expect(log, isEmpty);
    });

    test('PlatformException permissionDenied maps to DevicePermissionFailure', () async {
      setMock(null,
          error: PlatformException(
            code: UsageErrorCode.permissionDenied,
            message: 'Permission denied',
          ));
      final Result<UsagePermissionResult> res =
          await usageChannel.getPermissionStatus();
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<DevicePermissionFailure>());
      expect(
        (res.failureOrNull as DevicePermissionFailure).openSettingsWillHelp,
        isTrue,
      );
    });

    test('PlatformException sectionFailed maps to retryable BackendFailure', () async {
      setMock(null,
          error: PlatformException(
            code: UsageErrorCode.sectionFailed,
            message: 'Section read error',
          ));
      final Result<UsageDailyResult> res = await usageChannel.queryDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: 5000,
      );
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<BackendFailure>());
      expect(res.failureOrNull?.retryable, isTrue);
    });

    test('MissingPluginException maps to BackendFailure', () async {
      setMock(null, error: MissingPluginException());
      final Result<UsagePermissionResult> res =
          await usageChannel.getPermissionStatus();
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<BackendFailure>());
      expect((res.failureOrNull as BackendFailure).code, 'missing_plugin');
    });
  });
}
