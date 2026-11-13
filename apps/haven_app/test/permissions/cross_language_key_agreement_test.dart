import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/permissions/channel_device_state.dart';

/// D-4 option B: the Kotlin contract under `android_native/` is authoritative
/// and this test is the enforcement mechanism. It PARSES the Kotlin sources off
/// disk, extracts every string constant, and asserts per-item equality against
/// the Dart mirror — `DeviceStateChannel`'s named constants for the channel and
/// method, and the actual string literals `channel_device_state.dart`,
/// `device_state_decoding.dart` and `device_state_card.dart` read today.
///
/// This is not Dart-literal-vs-Dart-literal: change a Kotlin constant (e.g.
/// `KEY_API_LEVEL = "api"`) and the envelope/section assertions fail naming the
/// key; ADD a Kotlin constant and the count/set checks fail for having no
/// Dart-side use; rename a Dart literal and the parsed set stops equalling
/// Kotlin's. Error codes are the one family the parent Dart passes through
/// opaquely (verbatim `RefusedArea.reason` strings), so their Dart mirror is
/// the table below — still a real check, because the Kotlin side is read
/// from disk, never from this file.
void main() {
  final Directory nativeRoot = androidNativeRoot();
  final String bridgeSource = _readFile(
      '${nativeRoot.path}/child_services/platform_bridge/BridgeContract.kt');
  final Map<String, String> bridge = _constants(bridgeSource);
  final Map<String, String> sections = _constants(_readFile(
      '${nativeRoot.path}/child_services/platform_bridge/DeviceStateReader.kt'));
  final List<String> readers = RegExp(r'([A-Za-z0-9_.]+StateReader)\(\)')
      .allMatches(_readFile(
          '${nativeRoot.path}/child_services/platform_bridge/HavenBridge.kt'))
      .map((RegExpMatch m) => m.group(1)!)
      .toList();
  final Map<String, String> permissionKeys = _trackedPermissionKeys(_readFile(
      '${nativeRoot.path}/child_services/platform_bridge/OsAnswers.kt'));

  final String channelSource = _readFile('lib/core/permissions/channel_device_state.dart');
  final String decodingSource = _readFile('lib/core/permissions/device_state_decoding.dart');
  final String cardSource = _readFile(
      'lib/features/settings/views/widgets/device_state_card.dart');

  // The Dart mirror as it actually exists in the files that talk to the lane:
  // the keys the decoder indexes with, and the sections it asks for by name.
  final Set<String> dartEnvelopeKeys = _quoted(channelSource, r"envelope\['([^']+)'\]")
      .union(_quoted(decodingSource, r"envelope\['([^']+)'\]"));
  final Set<String> dartSectionKeys = _quoted(channelSource, r"areaReading\(\s*'([^']+)'");
  final Set<String> dartPermissionKeys = _quoted(cardSource, r"answerFor\('([^']+)'\)");

  test('the Kotlin and Dart sources parse to the shapes this test needs', () {
    // A vacuous regex would silently disarm every check below; fail loudly.
    expect(bridge, hasLength(9));
    expect(sections, hasLength(5));
    expect(readers, hasLength(5));
    expect(permissionKeys, hasLength(5));
    expect(dartEnvelopeKeys, hasLength(4));
    expect(dartSectionKeys, hasLength(5));
    expect(dartPermissionKeys, isNotEmpty);
  });

  test('channel and method: named Dart constants equal the Kotlin on disk', () {
    expect(bridge['CHANNEL'], DeviceStateChannel.name);
    expect(bridge['METHOD_READ_ALL'], DeviceStateChannel.readAllMethod);
  });

  test('every envelope key Kotlin sends is read by Dart under the same string', () {
    Map<String, String> kotlinKeys = Map.fromEntries(bridge.entries
        .where((MapEntry<String, String> e) => e.key.startsWith('KEY_')));
    expect(kotlinKeys, hasLength(4));
    for (MapEntry<String, String> key in kotlinKeys.entries) {
      expect(
        dartEnvelopeKeys,
        contains(key.value),
        reason: '${key.key} = "${key.value}" in BridgeContract.kt but the '
            'Dart decoders no longer index that string — drift, one key at a '
            'time, exactly as D-4 requires',
      );
    }
    expect(dartEnvelopeKeys, kotlinKeys.values.toSet(),
        reason: 'the Dart side reads a key Kotlin never declares');
  });

  test('every section name is agreed, per item, in both directions', () {
    for (MapEntry<String, String> section in sections.entries) {
      expect(dartSectionKeys, contains(section.value),
          reason: 'Sections.${section.key} = "${section.value}" is not read '
              'by ChannelNativeDeviceState.decode any more');
    }
    expect(dartSectionKeys, sections.values.toSet());
  });

  test('error codes: the Kotlin values equal the Dart-side mirror vocabulary', () {
    const Map<String, String> dartMirror = <String, String>{
      'ERROR_UNKNOWN_METHOD': 'unknown-method',
      'ERROR_NO_CONTEXT': 'no-context',
      'ERROR_SECTION_FAILED': 'section-failed',
    };
    for (MapEntry<String, String> code in dartMirror.entries) {
      expect(bridge[code.key], code.value,
          reason: '${code.key} drifted; Dart passes these through verbatim as '
              'RefusedArea.reason and renders them on screen');
    }
    expect(bridge.keys.where((String k) => k.startsWith('ERROR_')).toSet(),
        dartMirror.keys.toSet());
  });

  test('HavenBridge registers exactly the five readers, names stable', () {
    expect(readers, const <String>[
      'com.haven.haven_app.child_services.permissions.PermissionStateReader',
      'com.haven.haven_app.child_services.monitoring.MonitoringStateReader',
      'com.haven.haven_app.child_services.location.LocationStateReader',
      'com.haven.haven_app.child_services.device_admin.DeviceAdminStateReader',
      'com.haven.haven_app.child_services.communication.CommunicationStateReader',
    ]);
  });

  test('the TrackedPermission wire keys Kotlin answers cover every Dart read', () {
    expect(permissionKeys.values.toSet(), const <String>{
      'notifications', 'locationInUse', 'locationBackground',
      'microphone', 'camera',
    });
    for (String key in dartPermissionKeys) {
      expect(permissionKeys.values, contains(key),
          reason: 'device_state_card.dart asks for "$key", which Kotlin no '
              'longer answers — that key would silently render "unknown"');
    }
  });
}

/// Resolves the authoritative tree from the test working directory: normally
/// `apps/haven_app`, so `android_native/` is two levels up; the walk-up loop
/// keeps this honest when a runner starts elsewhere.
Directory androidNativeRoot() {
  for (Directory d = Directory.current;;) {
    final File probe = File(
        '${d.path}/android_native/child_services/platform_bridge/BridgeContract.kt');
    if (probe.existsSync()) return Directory('${d.path}/android_native');
    if (d.parent.path == d.path) break;
    d = d.parent;
  }
  throw StateError(
    'cross_language_key_agreement_test cannot find android_native/child_services/'
    'platform_bridge/BridgeContract.kt by walking up from ${Directory.current.path}. '
    'The Kotlin tree is the authoritative contract (D-4) — failing here is '
    'correct, skipping is not.',
  );
}

String _readFile(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError('agreement test cannot read $path — it refuses to check a '
        'contract against a file that is not there.');
  }
  return file.readAsStringSync();
}

Map<String, String> _constants(String source) => <String, String>{
  for (final RegExpMatch m
      in RegExp(r'const\s+val\s+(\w+)\s*=\s*"([^"]*)"').allMatches(source))
    m.group(1)!: m.group(2)!,
};

Set<String> _quoted(String source, String pattern) => RegExp(pattern)
    .allMatches(source)
    .map((RegExpMatch m) => m.group(1)!)
    .toSet();

Map<String, String> _trackedPermissionKeys(String source) => <String, String>{
  for (final RegExpMatch m in RegExp(
    r'([A-Z][A-Z0-9_]*)\(\s*Manifest\.permission\.\w+\s*,\s*'
    r'Build\.VERSION_CODES\.\w+\s*,\s*"([^"]+)"\s*,?\s*\)',
    dotAll: true,
  ).allMatches(source))
    m.group(1)!: m.group(2)!,
};
