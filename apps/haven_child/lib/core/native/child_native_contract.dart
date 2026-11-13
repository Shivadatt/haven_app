/// The Dart mirror of the child device's native surface — and a mirror only.
///
/// Decision D-4, option B, standardised the seam by hand instead of generating
/// it: the Kotlin constants under `android_native/` are authoritative, this file
/// is the copy the Dart side codes against, and the two are checked against each
/// other by a test that reads the Kotlin source off disk
/// (`test/native/child_native_key_agreement_test.dart`). A rename on either side
/// is therefore a failing test, not a channel that silently stops matching.
///
/// Nothing here opens a channel, and nothing here pretends to. This build of
/// the child app has NO native lane: `android_native/` is compiled by the parent
/// app only (its `srcDir` redirect lives in the parent's Gradle config), so a
/// call made against these names from the child would throw
/// `MissingPluginException` at runtime. The honest answer for that case is in
/// `child_native_failures.dart` as a typed `blocked(...)` — see also
/// `core/permissions/unconfigured_permission_status_source.dart`, which has said
/// the same thing about permissions since Stage 1.
library;

/// Where the authoritative constants actually live, as repo-relative paths.
///
/// The agreement test resolves these from the repository root; keeping them here
/// means the path appears once for the child lane.
abstract final class ChildNativeKotlinSource {
  static const String bridgeContract =
      'android_native/child_services/platform_bridge/BridgeContract.kt';
  static const String sections =
      'android_native/child_services/platform_bridge/DeviceStateReader.kt';
  static const String osAnswers =
      'android_native/child_services/platform_bridge/OsAnswers.kt';
  static const String havenBridge =
      'android_native/child_services/platform_bridge/HavenBridge.kt';

  /// `com.haven.haven_app.child_services.permissions.PermissionStateReader` →
  /// `android_native/child_services/permissions/PermissionStateReader.kt`.
  ///
  /// The Kotlin package continues under the `child_services` directory; the
  /// `com.haven.haven_app` prefix is the app's namespace, not a folder.
  static String pathOfReader(String qualifiedClassName) {
    const String namespace = 'com.haven.haven_app.';
    final String tail = qualifiedClassName.startsWith(namespace)
        ? qualifiedClassName.substring(namespace.length)
        : qualifiedClassName;
    return '$androidNativeRoot/${tail.replaceAll('.', '/')}.kt';
  }

  static const String androidNativeRoot = 'android_native';

  /// The reader class names as `HavenBridge.forApp` registers them.
  static const String readerClassPattern =
      r'([A-Za-z0-9_.]+StateReader)\(\)';
}

/// The one channel this surface shares with the parent's device-state lane.
abstract final class ChildNativeChannel {
  static const String name = 'haven.dev/child_device_state';
}

/// The one method the lane answers.
abstract final class ChildNativeMethod {
  static const String readAll = 'state.readAll';
}

/// The four keys of the reply envelope, in the shape `readAll` sends them.
abstract final class ChildNativeEnvelopeKey {
  static const String apiLevel = 'apiLevel';
  static const String osRelease = 'osRelease';
  static const String sections = 'sections';
  static const String sectionErrors = 'sectionErrors';

  static const List<String> all = <String>[
    apiLevel,
    osRelease,
    sections,
    sectionErrors,
  ];

  /// Wire key → Kotlin constant it mirrors.
  static const Map<String, String> kotlinConstants = <String, String>{
    apiLevel: 'KEY_API_LEVEL',
    osRelease: 'KEY_OS_RELEASE',
    sections: 'KEY_SECTIONS',
    sectionErrors: 'KEY_SECTION_ERRORS',
  };
}

/// The three error codes the lane can answer with.
abstract final class ChildNativeErrorCode {
  static const String unknownMethod = 'unknown-method';
  static const String noContext = 'no-context';
  static const String sectionFailed = 'section-failed';

  static const List<String> all = <String>[
    unknownMethod,
    noContext,
    sectionFailed,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    unknownMethod: 'ERROR_UNKNOWN_METHOD',
    noContext: 'ERROR_NO_CONTEXT',
    sectionFailed: 'ERROR_SECTION_FAILED',
  };
}

/// The five readable sections, each with the Kotlin constant that names it and
/// the reader that fills it.
enum ChildNativeSection {
  permissions(
    'permissions',
    'PERMISSIONS',
    'com.haven.haven_app.child_services.permissions.PermissionStateReader',
  ),
  monitoring(
    'monitoring',
    'MONITORING',
    'com.haven.haven_app.child_services.monitoring.MonitoringStateReader',
  ),
  location(
    'location',
    'LOCATION',
    'com.haven.haven_app.child_services.location.LocationStateReader',
  ),
  deviceAdmin(
    'deviceAdmin',
    'DEVICE_ADMIN',
    'com.haven.haven_app.child_services.device_admin.DeviceAdminStateReader',
  ),
  communication(
    'communication',
    'COMMUNICATION',
    'com.haven.haven_app.child_services.communication.CommunicationStateReader',
  ),
  ;

  const ChildNativeSection(this.wire, this.kotlinConstant, this.readerClass);

  /// The key the answer is filed under, and the key Dart reads it back by.
  final String wire;

  /// `Sections.PERMISSIONS` and friends in `DeviceStateReader.kt`.
  final String kotlinConstant;

  /// The fully-qualified reader class registered in `HavenBridge.forApp`.
  final String readerClass;

  static List<String> get wires =>
      values.map((ChildNativeSection s) => s.wire).toList(growable: false);
}

/// The runtime permissions the permissions section answers, keyed by the short
/// name the Dart side reads them under (`TrackedPermission.key`).
enum ChildNativePermissionKey {
  notifications('notifications', 'NOTIFICATIONS'),
  locationInUse('locationInUse', 'LOCATION_IN_USE'),
  locationBackground('locationBackground', 'LOCATION_BACKGROUND'),
  microphone('microphone', 'MICROPHONE'),
  camera('camera', 'CAMERA'),
  ;

  const ChildNativePermissionKey(this.wire, this.kotlinEntry);

  final String wire;

  /// The `TrackedPermission` entry whose third argument is this wire name.
  final String kotlinEntry;

  static List<String> get wires => values
      .map((ChildNativePermissionKey k) => k.wire)
      .toList(growable: false);
}

/// One name both sides must agree on, and where the Kotlin says it.
final class ChildNativeContractEntry {
  const ChildNativeContractEntry({
    required this.id,
    required this.dartValue,
    required this.kotlinFile,
    required this.kotlinConstant,
  });

  /// `channel`, `method`, `envelope.apiLevel`, `section.permissions`, …
  final String id;

  /// The Dart side's copy — what this app would send or read.
  final String dartValue;

  /// The authoritative file, repo-relative.
  final String kotlinFile;

  /// The Kotlin constant's declaration name, without its object prefix.
  final String kotlinConstant;

  @override
  String toString() => '$id: $dartValue <- $kotlinFile#$kotlinConstant';
}
