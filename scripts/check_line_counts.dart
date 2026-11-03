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

bool isGenerated(String path) {
  final String lower = path.toLowerCase();
  return lower.contains('.g.dart') ||
      lower.contains('.freezed.dart') ||
      lower.contains('.mocks.dart') ||
      lower.contains('google_services') ||
      ignoredDirParts.any(lower.contains);
}

bool shouldScan(String path) {
  if (!sourceExtensions.any(path.endsWith)) return false;
  return !isGenerated(path);
}

List<String> collectFiles() {
  final List<String> found = <String>[];
  for (final String root in scannedRoots) {
    if (!Directory(root).existsSync()) continue;
    for (final FileSystemEntity entity
        in Directory(root).listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (shouldScan(entity.path)) found.add(entity.path);
    }
  }
  found.sort();
  return found;
}

void main(List<String> args) {
  final List<String> files = collectFiles();
  final List<String> violations = <String>[];
  final List<String> overlongGenerated = <String>[];

  for (final String path in files) {
    final int count = countLines(File(path));
    if (count > maxLines) violations.add('$path  $count');
  }

  for (final String path in collectGenerated()) {
    final int count = countLines(File(path));
    if (count > maxLines) overlongGenerated.add('$path  $count');
  }

  stdout.writeln('line-count rule: max $maxLines lines per source file');
  stdout.writeln('hand-written source files scanned: ${files.length}');
  stdout.writeln('violations: ${violations.length}');
  for (final String v in violations) stdout.writeln('  OVER LIMIT  $v');
  if (overlongGenerated.isNotEmpty) {
    stdout.writeln('generated files over the limit (reported, not defects):');
    for (final String g in overlongGenerated) stdout.writeln('  GENERATED   $g');
  }
  if (violations.isNotEmpty) exitCode = 1;
}

int countLines(File file) {
  int lines = 0;
  final RandomAccessFile raf = file.openSync();
  try {
    for (final int byte in raf.read(raf.lengthSync())) {
      if (byte == 0x0A) lines++;
    }
    final int size = raf.lengthSync();
    if (size > 0 && raf.readByteSync(size - 1) != 0x0A) lines++;
  } finally {
    raf.closeSync();
  }
  return lines;
}

List<String> collectGenerated() {
  final List<String> found = <String>[];
  for (final String root in scannedRoots) {
    if (!Directory(root).existsSync()) continue;
    for (final FileSystemEntity entity
        in Directory(root).listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final String lower = entity.path.toLowerCase();
      final bool ext = sourceExtensions.any(lower.endsWith);
      if (ext && isGenerated(lower)) found.add(entity.path);
    }
  }
  return found..sort();
}
