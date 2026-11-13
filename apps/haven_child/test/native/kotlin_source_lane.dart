import 'dart:io';

/// Reads the authoritative Kotlin sources off disk for the child native tests.
///
/// `flutter test` runs with the package directory as the working directory
/// (`apps/haven_child`), so `android_native/` is two levels up. The walk-up
/// fallback keeps the test honest when a runner starts elsewhere; an unreadable
/// tree is a loud failure, never a skipped agreement check.
final class KotlinSourceLane {
  KotlinSourceLane(this.root);

  final Directory root;

  static const String _probePath =
      'android_native/child_services/platform_bridge/BridgeContract.kt';

  static KotlinSourceLane open() {
    Directory dir = Directory.current;
    for (var hop = 0; hop < 6; hop++) {
      final File probe = File('${dir.path}${Platform.pathSeparator}$_probePath');
      if (probe.existsSync()) return KotlinSourceLane(dir);
      dir = dir.parent;
    }
    throw StateError(
      'The child native agreement test cannot find $_probePath by walking up '
      'from ${Directory.current.path}. android_native/ is the authoritative '
      'contract (D-4): failing this test is correct, skipping is not.',
    );
  }

  String read(String repoRelativePath) {
    final File file = File('${root.path}${Platform.pathSeparator}$repoRelativePath');
    if (!file.existsSync()) {
      throw StateError('Kotlin contract file missing on disk: $repoRelativePath');
    }
    return file.readAsStringSync();
  }

  /// `const val NAME = "value"` pairs in [source].
  static Map<String, String> constValues(String source) => namedValuesIn(
    RegExp(r'const\s+val\s+(\w+)\s*=\s*"([^"]*)"').allMatches(source),
  );

  static Map<String, String> namedValuesIn(Iterable<RegExpMatch> matches) {
    final Map<String, String> out = <String, String>{};
    for (final RegExpMatch m in matches) {
      out[m.group(1)!] = m.group(2)!;
    }
    return out;
  }

  /// `TrackedPermission` entries: enum name -> the wire key (third argument).
  static Map<String, String> trackedPermissionKeys(String source) {
    final RegExp entry = RegExp(
      r'([A-Z][A-Z0-9_]*)\(\s*Manifest\.permission\.\w+\s*,\s*'
      r'Build\.VERSION_CODES\.\w+\s*,\s*"([^"]+)"\s*,?\s*\)',
      dotAll: true,
    );
    return <String, String>{
      for (final RegExpMatch m in entry.allMatches(source)) m.group(1)!: m.group(2)!,
    };
  }

  /// Fully-qualified `...StateReader()` names registered in HavenBridge.kt.
  static List<String> registeredReaders(String source) => RegExp(
    r'([A-Za-z0-9_.]+StateReader)\(\)',
  ).allMatches(source).map((RegExpMatch m) => m.group(1)!).toList();
}
