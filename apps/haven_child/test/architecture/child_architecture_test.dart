import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:haven_child/app/routes/child_pages.dart';
import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/app/routes/unknown_page.dart';
import 'package:haven_child/features/device/views/pages/device_page.dart';
import 'package:haven_child/features/onboarding/views/pages/onboarding_page.dart';
import 'package:haven_child/features/permissions/views/pages/permissions_page.dart';
import 'package:haven_child/features/profile/views/pages/profile_page.dart';
import 'package:haven_child/features/splash/views/pages/splash_page.dart';

import '../support/host.dart';

/// Architecture contract for the child lane (brief §7 additions):
/// the companion never depends on the parent app, and its route table is
/// complete — every named route resolves to a real page, never a
/// placeholder.
void main() {
  final libDir = Directory('../haven_child/lib').absolute;

  test('the child app lib exists where the gate expects it', () {
    expect(libDir.existsSync(), isTrue, reason: 'run from apps/haven_child');
  });

  group('no parent-app dependency', () {
    test('zero import/export/part lines mention haven_app', () {
      final offenders = <String>[];
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final line in file.readAsLinesSync()) {
          final trimmed = line.trim();
          final isDirective = trimmed.startsWith('import ') ||
              trimmed.startsWith('export ') ||
              trimmed.startsWith('part ');
          if (isDirective && trimmed.contains('haven_app')) {
            offenders.add('${file.path}: $trimmed');
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('the pubspec declares no haven_app dependency', () {
      // The header comment NAMES the banned SDKs to explain why they are
      // absent; only the dependency lines themselves must stay clean.
      final raw = File('../haven_child/pubspec.yaml').readAsStringSync();
      final code = raw
          .split('\n')
          .map((line) {
            final hash = line.indexOf('#');
            return hash == -1 ? line : line.substring(0, hash);
          })
          .join('\n');
      expect(code, isNot(contains('haven_app')));
      // Stage 1 is local-first: no cloud SDKs either.
      for (final banned in ['supabase', 'firebase_core', 'http:']) {
        expect(code, isNot(contains(banned)), reason: banned);
      }
    });

    test('the applicationId is the child-owned one (decision D-1)', () {
      final gradle = File(
        '../haven_child/android/app/build.gradle.kts',
      ).readAsStringSync();
      expect(gradle, contains('com.haven.child'));
    });
  });

  group('route table completeness', () {
    final expected = <String, Type>{
      ChildRoutes.splash: SplashPage,
      ChildRoutes.onboarding: OnboardingPage,
      ChildRoutes.profile: ProfilePage,
      ChildRoutes.device: DevicePage,
      ChildRoutes.permissions: PermissionsPage,
    };

    test('every named route has exactly one GetPage with a real builder', () {
      final names = ChildPages.pages.map((p) => p.name).toList();
      expect(names.toSet().length, names.length); // no duplicates
      for (final entry in expected.entries) {
        final page = ChildPages.pages.firstWhere((p) => p.name == entry.key);
        final built = page.page();
        expect(built.runtimeType, entry.value, reason: entry.key);
        expect(
          built.runtimeType,
          isNot(UnknownPage),
          reason: '${entry.key} must not be a placeholder',
        );
      }
    });

    test('unknownRoute is the honest not-built page', () {
      expect(ChildPages.unknown.name, ChildRoutes.unknown);
      expect(ChildPages.unknown.page().runtimeType, UnknownPage);
    });

    test('the table has no extra routes beyond the Stage-1 promise', () {
      expect(
        ChildPages.pages.map((p) => p.name).toSet(),
        expected.keys.toSet(),
      );
    });
  });

  testWidgets('the splash route builds honestly with no storage seam registered', (
    tester,
  ) async {
    // No override here: path_provider's missing channel must land as the
    // typed storage failure frame, never as an exception. The platform
    // lane completes on the REAL event loop, so the pumps go through
    // settleIo (Agent 2's handoff rule), not pumpAndSettle.
    await tester.runAsync(() async {
      await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.splash));
    });
    await settleIo(tester);
    expect(find.text('The app could not start'), findsOneWidget);
    expect(
      find.text('Local storage is not available on this device.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}
