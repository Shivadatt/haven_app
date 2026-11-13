import 'package:haven_core/haven_core.dart';

import 'child_native_contract.dart';
import 'child_native_envelope.dart';

/// Reads a reply the way the Kotlin lane sends it, key by key.
///
/// Every refusal names the single key that failed and why, so a drifting contract
/// is readable in the failure rather than something a screen has to interpret.
/// Split from `child_native_envelope.dart` to stay inside the repo's 200-line
/// source rule; the round-trip with `ChildNativeEnvelope.toWireMap` is the
/// contract the agreement tests hold.
Result<ChildNativeEnvelope> decodeChildNativeEnvelope(Object? reply) {
  if (reply is! Map) {
    return const Err<ChildNativeEnvelope>(
      BackendFailure(
        'The device-state answer arrived in a shape this build does not understand.',
        detail: 'envelope_is_not_a_map',
      ),
    );
  }
  final Map<String, Object?> envelope = <String, Object?>{
    for (final MapEntry<Object?, Object?> e in reply.entries) '${e.key}': e.value,
  };

  for (final String unexpected in envelope.keys) {
    if (!ChildNativeEnvelopeKey.all.contains(unexpected)) {
      return Err<ChildNativeEnvelope>(
        ValidationFailure(
          'The device-state answer carried a key this build has no mirror for.',
          field: ChildNativeEnvelopeKey.sections,
          detail: 'unknown_envelope_key: $unexpected',
        ),
      );
    }
  }

  for (final String expected in ChildNativeEnvelopeKey.all) {
    if (!envelope.containsKey(expected)) {
      return Err<ChildNativeEnvelope>(
        ValidationFailure(
          'The device-state answer was missing a key the contract declares.',
          field: expected,
          detail: 'missing_envelope_key: $expected',
        ),
      );
    }
  }

  final Object? apiLevel = envelope[ChildNativeEnvelopeKey.apiLevel];
  if (apiLevel is! int) {
    return const Err<ChildNativeEnvelope>(
      BackendFailure(
        'The device-state answer arrived in a shape this build does not understand.',
        detail: 'apiLevel_is_not_an_int',
      ),
    );
  }
  final Object? osRelease = envelope[ChildNativeEnvelopeKey.osRelease];
  if (osRelease is! String) {
    return const Err<ChildNativeEnvelope>(
      BackendFailure(
        'The device-state answer arrived in a shape this build does not understand.',
        detail: 'osRelease_is_not_a_string',
      ),
    );
  }

  final Result<Map<String, Map<String, Object?>>> sections = _sectionMaps(
    envelope[ChildNativeEnvelopeKey.sections],
  );
  if (sections.isErr) {
    return Err<ChildNativeEnvelope>(sections.failureOrNull!);
  }
  final Result<Map<String, String>> errors = _errorMaps(
    envelope[ChildNativeEnvelopeKey.sectionErrors],
  );
  if (errors.isErr) {
    return Err<ChildNativeEnvelope>(errors.failureOrNull!);
  }

  return Ok<ChildNativeEnvelope>(
    ChildNativeEnvelope(
      apiLevel: apiLevel,
      osRelease: osRelease,
      sections: sections.valueOrNull!,
      sectionErrors: errors.valueOrNull!,
    ),
  );
}

/// Section maps are checked against the declared section names: an answer filed
/// under a name the Kotlin `Sections` object does not declare is a drift, and a
/// drift is worth failing over.
Result<Map<String, Map<String, Object?>>> _sectionMaps(Object? raw) {
  if (raw is! Map) {
    return const Err<Map<String, Map<String, Object?>>>(
      BackendFailure(
        'The device-state answer arrived in a shape this build does not understand.',
        detail: 'sections_is_not_a_map',
      ),
    );
  }
  final Map<String, Map<String, Object?>> out = <String, Map<String, Object?>>{};
  for (final MapEntry<Object?, Object?> e in raw.entries) {
    final String name = '${e.key}';
    if (!ChildNativeSection.wires.contains(name)) {
      return Err<Map<String, Map<String, Object?>>>(
        ValidationFailure(
          'The device-state answer named a section this build has no mirror for.',
          field: ChildNativeEnvelopeKey.sections,
          detail: 'unknown_section: $name',
        ),
      );
    }
    if (e.value is! Map) {
      return Err<Map<String, Map<String, Object?>>>(
        ValidationFailure(
          'A section arrived without a map of answers behind it.',
          field: name,
          detail: 'section_value_is_not_a_map: $name',
        ),
      );
    }
    out[name] = <String, Object?>{
      for (final MapEntry<Object?, Object?> v in (e.value! as Map).entries)
        '${v.key}': v.value,
    };
  }
  return Ok<Map<String, Map<String, Object?>>>(out);
}

/// The refusal side of the reply: a section name mapped to a Kotlin error code.
Result<Map<String, String>> _errorMaps(Object? raw) {
  if (raw is! Map) {
    return const Err<Map<String, String>>(
      BackendFailure(
        'The device-state answer arrived in a shape this build does not understand.',
        detail: 'sectionErrors_is_not_a_map',
      ),
    );
  }
  final Map<String, String> out = <String, String>{};
  for (final MapEntry<Object?, Object?> e in raw.entries) {
    final String name = '${e.key}';
    final Object? reason = e.value;
    if (!ChildNativeSection.wires.contains(name)) {
      return Err<Map<String, String>>(
        ValidationFailure(
          'The device-state answer refused a section this build has no mirror for.',
          field: ChildNativeEnvelopeKey.sectionErrors,
          detail: 'unknown_refused_section: $name',
        ),
      );
    }
    if (reason is! String) {
      return Err<Map<String, String>>(
        ValidationFailure(
          'A refusal arrived in a form this build cannot account for.',
          field: name,
          detail: 'section_error_is_not_a_string: $name',
        ),
      );
    }
    out[name] = reason;
  }
  return Ok<Map<String, String>>(out);
}
