import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Child Architecture Dependency Isolation', () {
    late Directory childRootDir;

    setUpAll(() {
      // Resolve apps/haven_child directory robustly whether executed from repo root
      // or from apps/haven_child.
      final current = Directory.current;
      if (current.path.endsWith('haven_child')) {
        childRootDir = current;
      } else {
        childRootDir = Directory('${current.path}/apps/haven_child');
      }
      expect(
        childRootDir.existsSync(),
        isTrue,
        reason: 'Child root directory must exist: ${childRootDir.path}',
      );
    });

    test('pubspec.yaml declares haven_offline and zero cloud dependencies', () {
      final pubspecFile = File('${childRootDir.path}/pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();

      // Assert haven_offline is present
      expect(
        content.contains('haven_offline:'),
        isTrue,
        reason: 'haven_offline must be declared in pubspec.yaml',
      );

      // Assert prohibited packages are absent
      const prohibited = [
        'haven_api:',
        'firebase_core:',
        'firebase_auth:',
        'firebase_messaging:',
        'supabase_flutter:',
        'supabase:',
        'postgrest:',
      ];

      for (final dep in prohibited) {
        expect(
          content.contains(dep),
          isFalse,
          reason: 'Prohibited dependency "$dep" must not be in child pubspec.yaml',
        );
      }
    });

    test('resolved pubspec.lock has zero cloud package entries', () {
      final lockFile = File('${childRootDir.path}/pubspec.lock');
      if (!lockFile.existsSync()) {
        // Lockfile may not be present before pub get, but if it exists, test it
        return;
      }

      final content = lockFile.readAsStringSync();

      const prohibitedPackages = [
        'haven_api',
        'firebase_core',
        'firebase_auth',
        'firebase_messaging',
        'supabase_flutter',
        'postgrest',
        'gotrue',
        'realtime_client',
        'storage_client',
      ];

      for (final pkg in prohibitedPackages) {
        final regex = RegExp('^  $pkg:\\s*\$', multiLine: true);
        expect(
          regex.hasMatch(content),
          isFalse,
          reason: 'Prohibited package "$pkg" must not appear in child pubspec.lock',
        );
      }
    });

    test('child lib source files never import haven_api or cloud packages', () {
      final libDir = Directory('${childRootDir.path}/lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      const prohibitedImports = [
        'package:haven_api/',
        'package:firebase_core/',
        'package:firebase_auth/',
        'package:firebase_messaging/',
        'package:supabase_flutter/',
        'package:supabase/',
        'package:postgrest/',
      ];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('import ') || line.startsWith('export ')) {
            for (final prohibited in prohibitedImports) {
              expect(
                line.contains(prohibited),
                isFalse,
                reason:
                    'Prohibited import "$prohibited" found in ${file.path}:${i + 1}',
              );
            }
          }
        }
      }
    });
  });
}
