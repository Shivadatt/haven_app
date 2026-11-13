import 'child_native_contract.dart';

/// One reply from the native device-state lane, read as a typed thing.
///
/// A `MethodChannel` hands over `Map<Object?, Object?>`, and the parent's decoder
/// (`apps/haven_app/lib/core/permissions/channel_device_state.dart`) reads a value
/// of the wrong shape as "the phone did not say" rather than coercing it into a
/// confident `false` or `0`. This lane keeps that rule: nothing here turns a
/// garbled reply into a plausible sentence.
///
/// The child build has no lane to send this reply — see `blockedChildNativeLane`
/// in `child_native_failures.dart`, which is what a caller actually gets today.
final class ChildNativeEnvelope {
  const ChildNativeEnvelope({
    required this.apiLevel,
    required this.osRelease,
    required this.sections,
    required this.sectionErrors,
  });

  /// `Build.VERSION.SDK_INT`, as reported by the device that answered.
  final int apiLevel;

  /// `Build.VERSION.RELEASE`; the Kotlin side always sends a string here.
  final String osRelease;

  /// Section wire name → that section's answer map.
  final Map<String, Map<String, Object?>> sections;

  /// Section wire name → the Kotlin error code for a section it could not read.
  final Map<String, String> sectionErrors;

  /// The empty reply: nothing read, nothing refused.
  const ChildNativeEnvelope.unknownDevice()
    : apiLevel = 0,
      osRelease = '',
      sections = const <String, Map<String, Object?>>{},
      sectionErrors = const <String, String>{};

  Map<String, Object?> valuesOf(ChildNativeSection section) =>
      sections[section.wire] ?? const <String, Object?>{};

  String? errorOf(ChildNativeSection section) => sectionErrors[section.wire];

  /// A section with no answer map counts as unanswered, never as "all clear" —
  /// the same rule the parent's `areaReading` applies to an empty map.
  bool isUnanswered(ChildNativeSection section) =>
      errorOf(section) != null || !sections.containsKey(section.wire);

  /// The OS's grant answers, keyed by [ChildNativePermissionKey.wire].
  ///
  /// `null` for a key means the OS could not be asked (or the build never
  /// declared that permission); it never means "denied".
  Map<String, bool?> grantedAnswers() {
    final Object? raw = valuesOf(ChildNativeSection.permissions)['granted'];
    if (raw is! Map) return const <String, bool?>{};
    return <String, bool?>{
      for (final MapEntry<Object?, Object?> e in raw.entries)
        '${e.key}': e.value is bool ? e.value as bool : null,
    };
  }

  /// The wire form: exactly the four keys Kotlin files them under, in that
  /// order. A reply built here and read back by `decodeChildNativeEnvelope`
  /// (in `child_native_envelope_codec.dart`) must return an identical value —
  /// that round-trip is the contract test.
  Map<String, Object?> toWireMap() => <String, Object?>{
    ChildNativeEnvelopeKey.apiLevel: apiLevel,
    ChildNativeEnvelopeKey.osRelease: osRelease,
    ChildNativeEnvelopeKey.sections: sections,
    ChildNativeEnvelopeKey.sectionErrors: sectionErrors,
  };

  @override
  String toString() =>
      'ChildNativeEnvelope(api: $apiLevel, os: "$osRelease", '
      'sections: ${sections.length}, refused: ${sectionErrors.length})';
}
