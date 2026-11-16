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

  void setMock(dynamic result) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
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

  group('UsageChannel Daily Query Tests', () {
    test('queryDailyUsage returns parsed result with app records', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.startTimeMillis: 1000,
        UsageEnvelopeKey.endTimeMillis: 5000,
        UsageEnvelopeKey.totalForegroundMillis: 3500,
        UsageEnvelopeKey.dataFreshness: UsageDataFreshnessValue.recent,
        UsageEnvelopeKey.apps: <Map<String, dynamic>>[
          <String, dynamic>{
            UsageEnvelopeKey.packageName: 'com.example.game',
            UsageEnvelopeKey.totalForegroundMillis: 2000,
            UsageEnvelopeKey.lastTimeUsedMillis: 4500,
            UsageEnvelopeKey.isSystemApp: false,
          },
          <String, dynamic>{
            UsageEnvelopeKey.packageName: 'com.android.settings',
            UsageEnvelopeKey.totalForegroundMillis: 1500,
            UsageEnvelopeKey.lastTimeUsedMillis: null,
            UsageEnvelopeKey.isSystemApp: true,
          },
        ],
      });

      final Result<UsageDailyResult> result =
          await usageChannel.queryDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: 5000,
      );

      expect(result.isOk, isTrue);
      final UsageDailyResult data = result.valueOrNull!;
      expect(data.apiLevel, 34);
      expect(data.startTimeMillis, 1000);
      expect(data.endTimeMillis, 5000);
      expect(data.totalForegroundMillis, 3500);
      expect(data.totalForegroundDuration, const Duration(milliseconds: 3500));
      expect(data.dataFreshness, UsageDataFreshness.recent);
      expect(data.apps.length, 2);

      final UsageAppRecord app1 = data.apps[0];
      expect(app1.packageName, 'com.example.game');
      expect(app1.totalForegroundMillis, 2000);
      expect(app1.foregroundDuration, const Duration(milliseconds: 2000));
      expect(app1.lastTimeUsedMillis, 4500);
      expect(app1.isSystemApp, isFalse);

      final UsageAppRecord app2 = data.apps[1];
      expect(app2.packageName, 'com.android.settings');
      expect(app2.totalForegroundMillis, 1500);
      expect(app2.lastTimeUsedMillis, isNull);
      expect(app2.isSystemApp, isTrue);

      expect(log.length, 1);
      expect(log.first.method, UsageMethod.queryDailyUsage);
      expect(log.first.arguments, <String, dynamic>{
        UsageEnvelopeKey.startTimeMillis: 1000,
        UsageEnvelopeKey.endTimeMillis: 5000,
      });
    });

    test('queryDailyUsage rejects invalid time ranges before native call', () async {
      final resNegStart = await usageChannel.queryDailyUsage(
        startTimeMillis: -1,
        endTimeMillis: 5000,
      );
      final resNegEnd = await usageChannel.queryDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: -5,
      );
      final resInverted = await usageChannel.queryDailyUsage(
        startTimeMillis: 5000,
        endTimeMillis: 1000,
      );
      final resEqual = await usageChannel.queryDailyUsage(
        startTimeMillis: 1000,
        endTimeMillis: 1000,
      );

      expect(resNegStart.isErr && resNegEnd.isErr, isTrue);
      expect(resInverted.isErr && resEqual.isErr, isTrue);
      expect(resNegStart.failureOrNull, isA<ValidationFailure>());
      expect(resInverted.failureOrNull, isA<ValidationFailure>());
      expect(log, isEmpty);
    });

    test('queryDailyUsage parses empty and delayed freshness envelopes', () async {
      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 31,
        UsageEnvelopeKey.startTimeMillis: 100,
        UsageEnvelopeKey.endTimeMillis: 200,
        UsageEnvelopeKey.totalForegroundMillis: 0,
        UsageEnvelopeKey.dataFreshness: UsageDataFreshnessValue.empty,
        UsageEnvelopeKey.apps: <dynamic>[],
      });
      final resEmpty = await usageChannel.queryDailyUsage(
        startTimeMillis: 100,
        endTimeMillis: 200,
      );
      expect(resEmpty.isOk, isTrue);
      expect(resEmpty.valueOrNull?.dataFreshness, UsageDataFreshness.empty);
      expect(resEmpty.valueOrNull?.apps, isEmpty);

      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 31,
        UsageEnvelopeKey.startTimeMillis: 200,
        UsageEnvelopeKey.endTimeMillis: 300,
        UsageEnvelopeKey.totalForegroundMillis: 50,
        UsageEnvelopeKey.dataFreshness: UsageDataFreshnessValue.delayed,
        UsageEnvelopeKey.apps: <Map<String, dynamic>>[
          <String, dynamic>{
            UsageEnvelopeKey.packageName: 'com.test',
            UsageEnvelopeKey.totalForegroundMillis: 50,
            UsageEnvelopeKey.isSystemApp: false,
          },
        ],
      });
      final resDelayed = await usageChannel.queryDailyUsage(
        startTimeMillis: 200,
        endTimeMillis: 300,
      );
      expect(resDelayed.isOk, isTrue);
      expect(resDelayed.valueOrNull?.dataFreshness, UsageDataFreshness.delayed);
    });

    test('queryDailyUsage returns Err on malformed envelope or app records', () async {
      setMock('not_a_map');
      final notMap = await usageChannel.queryDailyUsage(
          startTimeMillis: 1, endTimeMillis: 2);
      expect(notMap.isErr, isTrue);

      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.startTimeMillis: 1,
      });
      final missingFields = await usageChannel.queryDailyUsage(
          startTimeMillis: 1, endTimeMillis: 2);
      expect(missingFields.isErr, isTrue);

      setMock(<String, dynamic>{
        UsageEnvelopeKey.apiLevel: 34,
        UsageEnvelopeKey.startTimeMillis: 1,
        UsageEnvelopeKey.endTimeMillis: 2,
        UsageEnvelopeKey.totalForegroundMillis: 0,
        UsageEnvelopeKey.dataFreshness: UsageDataFreshnessValue.recent,
        UsageEnvelopeKey.apps: <dynamic>['not_a_map_item'],
      });
      final badItem = await usageChannel.queryDailyUsage(
          startTimeMillis: 1, endTimeMillis: 2);
      expect(badItem.isErr, isTrue);
    });
  });
}
