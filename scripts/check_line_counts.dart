// Enforcement of the owner's strict 200-line source-file rule (brief section 5).
// Pure dart:io, no package dependencies, so it runs before `pub get` succeeds.
//
//   fvm dart run scripts/check_line_counts.dart
//
// Exit code 1 when any hand-written source file exceeds the limit.
// Generated files are reported separately and never counted as violations,
// because damaging generated code to satisfy a line rule is worse than the rule.

import 'dart:io';

const int maxLines = 200;

const List<String> sourceExtensions = <String>[
  '.dart',
  '.kt',
  '.java',
  '.sql',
  '.ts',
];

const List<String> scannedRoots = <String>[
  'apps',
  'packages',
  'android_native',
  'backend',
  'scripts',
];

const List<String> ignoredDirParts = <String>[
  '/build/',
  '/.dart_tool/',
  '/.fvm/',
  '/node_modules/',
  '/.gradle/',
  '/generated/',
  '/Generated/',
];

/// Windows-native paths are normalised so the directory filters work on
/// every platform this script runs on.
String normalize(String path) => path.replaceAll(r'\', '/');

bool isGenerated(String path) {
  final String lower = normalize(path).toLowerCase();
  return lower.contains('.g.dart') ||
      lower.contains('.freezed.dart') ||
      lower.contains('.mocks.dart') ||
      lower.contains('google_services') ||
      ignoredDirParts.any(lower.contains);
}

bool inIgnoredDir(String path) {
  final lower = normalize(path).toLowerCase();
  return ignoredDirParts.any(lower.contains);
}

/// One walk, partitioned into hand-written sources and generated sources.
({List<String> handWritten, List<String> generated}) collectFiles() {
  final List<String> handWritten = <String>[];
  final List<String> generated = <String>[];

  void scan(Directory dir) {
    for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
      final String path = normalize(entity.path);
      if (entity is Directory) {
        if (!inIgnoredDir('$path/')) {
          scan(entity);
        }
      } else if (entity is File) {
        if (!sourceExtensions.any(path.endsWith)) continue;
        if (isGenerated(path)) {
          if (!inIgnoredDir(path)) generated.add(path);
        } else {
          handWritten.add(path);
        }
      }
    }
  }

  for (final String root in scannedRoots) {
    final Directory dir = Directory(root);
    if (dir.existsSync()) scan(dir);
  }
  return (handWritten: handWritten..sort(), generated: generated..sort());
}

void main(List<String> args) {
  final files = collectFiles();
  final List<String> violations = <String>[];
  final List<String> overlongGenerated = <String>[];

  for (final String path in files.handWritten) {
    final int count = countLines(File(path));
    if (count > maxLines) violations.add('$path  $count');
  }

  for (final String path in files.generated) {
    final int count = countLines(File(path));
    if (count > maxLines) overlongGenerated.add('$path  $count');
  }

  stdout.writeln('line-count rule: max $maxLines lines per source file');
  stdout.writeln(
    'hand-written source files scanned: ${files.handWritten.length}',
  );
  stdout.writeln('violations: ${violations.length}');
  for (final String v in violations) stdout.writeln('  OVER LIMIT  $v');
  if (overlongGenerated.isNotEmpty) {
    stdout.writeln('generated files over the limit (reported, not defects):');
    for (final String g in overlongGenerated)
      stdout.writeln('  GENERATED   $g');
  }
  if (violations.isNotEmpty) exitCode = 1;
}

/// Counts LF terminators, plus one when the file ends without a newline.
int countLines(File file) {
  final List<int> bytes = file.readAsBytesSync();
  if (bytes.isEmpty) return 0;
  int lines = 0;
  for (final int byte in bytes) {
    if (byte == 0x0A) lines++;
  }
  if (bytes.last != 0x0A) lines++;
  return lines;
}
