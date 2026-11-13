import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/core/native/child_native_contract.dart';
import 'package:haven_child/core/native/child_native_envelope.dart';
import 'package:haven_child/core/native/child_native_envelope_codec.dart';
import 'package:haven_child/core/native/child_native_failures.dart';
import 'package:haven_child/core/native/child_native_registry.dart';

/// The reply codec the future child lane will use, tested at ladder level 2.
///
/// The rules under test are the parent decoder's rules, kept identical on this
/// side: a wrong-shaped value is "the phone did not say", never a coerced
/// `false` or `0`; an unknown key is drift, and drift fails typed.
void main() {
  Map<String, Object?> fullWire() => const ChildNativeEnvelope(
    apiLevel: 34,
    osRelease: '14',
    sections: <String, Map<String, Object?>>{
      'permissions': <String, Object?>{
        'granted': <String, Object?>{
          'notifications': true,
          'locationInUse': false,
          'microphone': 'not a bool',
        },
      },
      'monitoring': <String, Object?>{'usageAccess': true},
    },
    sectionErrors: <String, String>{'location': 'section-failed'},
  ).toWireMap();

  test('toWireMap -> decode round-trips to an identical value', () {
    final Result<ChildNativeEnvelope> decoded =
        decodeChildNativeEnvelope(fullWire());
    expect(decoded.isOk, isTrue);
    final ChildNativeEnvelope back = decoded.valueOrNull!;
    expect(back.apiLevel, 34);
    expect(back.osRelease, '14');
    expect(back.sections, fullWire()[ChildNativeEnvelopeKey.sections]);
    expect(back.sectionErrors, <String, String>{'location': 'section-failed'});
    expect(back.toWireMap(), fullWire());
    expect(
      back.toWireMap().keys.toList(),
      ChildNativeEnvelopeKey.all,
      reason: 'exactly the four keys Kotlin files them under, in order',
    );
  });

  test('section helpers answer "unanswered", never "all clear"', () {
    final ChildNativeEnvelope env = decodeChildNativeEnvelope(fullWire()).valueOrNull!;
    expect(env.valuesOf(ChildNativeSection.monitoring), <String, Object?>{'usageAccess': true});
    expect(env.valuesOf(ChildNativeSection.communication), isEmpty);
    expect(env.errorOf(ChildNativeSection.location), 'section-failed');
    expect(env.isUnanswered(ChildNativeSection.location), isTrue);
    expect(env.isUnanswered(ChildNativeSection.permissions), isFalse);
    expect(env.isUnanswered(ChildNativeSection.communication), isTrue);
  });

  test('grantedAnswers keeps bools, maps everything else to null', () {
    final Map<String, bool?> answers =
        decodeChildNativeEnvelope(fullWire()).valueOrNull!.grantedAnswers();
    expect(answers['notifications'], isTrue);
    expect(answers['locationInUse'], isFalse);
    expect(answers['microphone'], isNull, reason: 'a string is not an OS answer');
    expect(
      const ChildNativeEnvelope.unknownDevice().grantedAnswers(),
      isEmpty,
    );
  });

  group('refusals name the single key that failed', () {
    Result<ChildNativeEnvelope> decodeWith(Object? wire) =>
        decodeChildNativeEnvelope(wire);

    test('a reply that is not a map', () {
      final HavenFailure failure = decodeWith('nope').failureOrNull!;
      expect(failure, isA<BackendFailure>());
      expect(failure.detail, 'envelope_is_not_a_map');
    });

    test('an unknown top-level key', () {
      final Map<String, Object?> wire = fullWire()..['batteryLevel'] = 95;
      final HavenFailure failure = decodeWith(wire).failureOrNull!;
      expect(failure, isA<ValidationFailure>());
      expect(failure.detail, 'unknown_envelope_key: batteryLevel');
    });

    test('a missing contract key', () {
      final Map<String, Object?> wire = fullWire()..remove('osRelease');
      final HavenFailure failure = decodeWith(wire).failureOrNull!;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).field,
        ChildNativeEnvelopeKey.osRelease,
      );
      expect(failure.detail, 'missing_envelope_key: osRelease');
    });

    test('wrong value shapes for apiLevel / osRelease / sections / errors', () {
      for (final (String key, Object? bad, String detail) in [
        ('apiLevel', '34', 'apiLevel_is_not_an_int'),
        ('osRelease', 14, 'osRelease_is_not_a_string'),
        ('sections', 'nope', 'sections_is_not_a_map'),
        ('sectionErrors', <Object?>[], 'sectionErrors_is_not_a_map'),
      ]) {
        final Map<String, Object?> wire = fullWire()..[key] = bad;
        expect(
          decodeWith(wire).failureOrNull!.detail,
          detail,
          reason: key,
        );
      }
    });

    test('a section or refusal filed under an undeclared name is drift', () {
      final Map<String, Object?> extraSection = fullWire();
      extraSection['sections'] = <String, Object?>{'battery': <String, Object?>{}};
      expect(
        decodeWith(extraSection).failureOrNull!.detail,
        'unknown_section: battery',
      );

      final Map<String, Object?> notAMap = fullWire();
      notAMap['sections'] = <String, Object?>{'permissions': 'flat'};
      expect(
        decodeWith(notAMap).failureOrNull!.detail,
        'section_value_is_not_a_map: permissions',
      );

      final Map<String, Object?> extraRefusal = fullWire();
      extraRefusal['sectionErrors'] = <String, Object?>{'battery': 'section-failed'};
      expect(
        decodeWith(extraRefusal).failureOrNull!.detail,
        'unknown_refused_section: battery',
      );

      final Map<String, Object?> nonStringReason = fullWire();
      nonStringReason['sectionErrors'] = <String, Object?>{'location': 7};
      expect(
        decodeWith(nonStringReason).failureOrNull!.detail,
        'section_error_is_not_a_string: location',
      );
    });
  });

  group('error mapping onto the shared HavenFailure vocabulary', () {
    test('the three Kotlin codes map to typed failures', () {
      final HavenFailure unknown = childNativeFailureFor(
        code: ChildNativeErrorCode.unknownMethod,
        message: 'state.readNothing',
      );
      expect(unknown, isA<ValidationFailure>());
      expect(unknown.detail, 'unknown-method: state.readNothing');

      final HavenFailure noContext = childNativeFailureFor(
        code: ChildNativeErrorCode.noContext,
      );
      expect(noContext, isA<UnknownFailure>());
      expect(noContext.detail, ChildNativeErrorCode.noContext);

      final HavenFailure refused = childNativeFailureFor(
        code: ChildNativeErrorCode.sectionFailed,
        section: 'location',
      );
      expect(refused, isA<BackendFailure>());
      expect(refused.detail, 'section-failed section=location');
      expect((refused as BackendFailure).retryable, isTrue);
    });

    test('an unknown code stays unknown and says which', () {
      final HavenFailure failure = childNativeFailureFor(code: 'tilt-shift');
      expect(failure, isA<UnknownFailure>());
      expect(failure.detail, 'unmapped_error_code: tilt-shift');
    });
  });

  group('the honest answer this build gives', () {
    test('every use of the lane is blocked, not empty-but-confident', () {
      final Result<ChildNativeEnvelope> result = blockedChildNativeLane<ChildNativeEnvelope>();
      expect(result.isErr, isTrue);
      expect(isBlocked(result), isTrue);
      final BlockedFailure failure = result.failureOrNull! as BlockedFailure;
      expect(failure.missing, contains('compiled by the parent app only'));
      expect(failure.message, ChildNativeContract.laneAvailabilityNote);
      expect(ChildNativeChannel.name, 'haven.dev/child_device_state');
      expect(ChildNativeMethod.readAll, 'state.readAll');
    });
  });
}
