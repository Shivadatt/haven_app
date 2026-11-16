import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_channel_contract.dart';

import 'kotlin_source_lane.dart';

/// D-4 cross-language contract agreement test for Usage Access channel.
///
/// Kotlin (`UsageContract.kt`) is the authoritative source of truth.
/// This test parses the raw Kotlin source file from disk and validates that
/// the Dart mirror (`usage_channel_contract.dart`) matches every single
/// channel name, method name, envelope key, error code, section name, and
/// enum value without drift.
void main() {
  final KotlinSourceLane lane = KotlinSourceLane.open();
  final String rawSource = lane.read(UsageKotlinSource.contractPath);
  final Map<String, String> kotlinConstants =
      KotlinSourceLane.constValues(rawSource);

  group('UsageContract D-4 Authoritative Agreement', () {
    test('non-vacuous parsing: Kotlin source contains all expected constants', () {
      expect(
        rawSource.isNotEmpty,
        isTrue,
        reason: 'UsageContract.kt on disk must not be empty',
      );
      // 1 channel + 3 methods + 12 keys + 5 errors + 3 status + 3 freshness + 3 sections = 30
      expect(
        kotlinConstants,
        hasLength(30),
        reason: 'Parser must find exactly 30 authoritative constants in UsageContract.kt',
      );
    });

    test('MethodChannel name agrees with Kotlin authoritative constant', () {
      final String? kotlinChannel =
          kotlinConstants[UsageChannelName.kotlinConstant];
      expect(
        kotlinChannel,
        UsageChannelName.channelName,
        reason: 'Dart UsageChannelName must match Kotlin CHANNEL_NAME',
      );
    });

    test('all method names agree with Kotlin authoritative constants', () {
      expect(UsageMethod.all, hasLength(3));
      for (final String method in UsageMethod.all) {
        final String kotlinConstName = UsageMethod.kotlinConstants[method]!;
        expect(
          kotlinConstants[kotlinConstName],
          method,
          reason: 'Method $method must match Kotlin $kotlinConstName',
        );
      }
    });

    test('all envelope keys agree with Kotlin authoritative constants', () {
      expect(UsageEnvelopeKey.all, hasLength(12));
      for (final String key in UsageEnvelopeKey.all) {
        final String kotlinConstName = UsageEnvelopeKey.kotlinConstants[key]!;
        expect(
          kotlinConstants[kotlinConstName],
          key,
          reason: 'Envelope key $key must match Kotlin $kotlinConstName',
        );
      }
    });

    test('all error codes agree with Kotlin authoritative constants', () {
      expect(UsageErrorCode.all, hasLength(5));
      for (final String code in UsageErrorCode.all) {
        final String kotlinConstName = UsageErrorCode.kotlinConstants[code]!;
        expect(
          kotlinConstants[kotlinConstName],
          code,
          reason: 'Error code $code must match Kotlin $kotlinConstName',
        );
      }
    });

    test('all permission status values agree with Kotlin authoritative constants', () {
      expect(UsagePermissionStatusValue.all, hasLength(3));
      for (final String status in UsagePermissionStatusValue.all) {
        final String kotlinConstName =
            UsagePermissionStatusValue.kotlinConstants[status]!;
        expect(
          kotlinConstants[kotlinConstName],
          status,
          reason: 'Permission status $status must match Kotlin $kotlinConstName',
        );
      }
    });

    test('all data freshness values agree with Kotlin authoritative constants', () {
      expect(UsageDataFreshnessValue.all, hasLength(3));
      for (final String freshness in UsageDataFreshnessValue.all) {
        final String kotlinConstName =
            UsageDataFreshnessValue.kotlinConstants[freshness]!;
        expect(
          kotlinConstants[kotlinConstName],
          freshness,
          reason: 'Freshness value $freshness must match Kotlin $kotlinConstName',
        );
      }
    });

    test('all usage section names agree with Kotlin authoritative constants', () {
      expect(UsageSectionName.all, hasLength(3));
      for (final String section in UsageSectionName.all) {
        final String kotlinConstName = UsageSectionName.kotlinConstants[section]!;
        expect(
          kotlinConstants[kotlinConstName],
          section,
          reason: 'Section name $section must match Kotlin $kotlinConstName',
        );
      }
    });

    test('bidirectional completeness: every Kotlin constant is mirrored in Dart', () {
      final Set<String> allMirroredKotlinConsts = <String>{
        UsageChannelName.kotlinConstant,
        ...UsageMethod.kotlinConstants.values,
        ...UsageEnvelopeKey.kotlinConstants.values,
        ...UsageErrorCode.kotlinConstants.values,
        ...UsagePermissionStatusValue.kotlinConstants.values,
        ...UsageDataFreshnessValue.kotlinConstants.values,
        ...UsageSectionName.kotlinConstants.values,
      };

      expect(
        allMirroredKotlinConsts,
        hasLength(30),
        reason: 'Mirrored set must have no duplicate constant mappings',
      );

      final Set<String> actualKotlinConsts = kotlinConstants.keys.toSet();
      expect(
        actualKotlinConsts,
        equals(allMirroredKotlinConsts),
        reason: 'Every constant in UsageContract.kt must have a corresponding '
            'Dart mirror representation. Unmirrored constants or missing constants '
            'are strictly prohibited.',
      );
    });
  });
}
