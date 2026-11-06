import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/app/app.dart';
import 'package:haven_child/app/bindings/child_initial_bindings.dart';
import 'package:haven_child/core/constants/child_config.dart';
import 'package:haven_child/core/storage/child_storage_paths.dart';

/// Stage 1 smoke test: the app boots to the splash screen and shows the real
/// boot's loading state. Storage stays pending under the test scheduler
/// (dart:io is deliberately not driven here — Agent 3's suite owns the
/// booted flows through the `ChildStoragePaths.overrideForTests` seam).
/// Agent 3 owns the real feature-mirrored suite; extend from there, do not
/// trust this as coverage.
void main() {
  tearDown(ChildInitialBindings.resetForTests);

  testWidgets('child app builds and the splash starts booting', (
    tester,
  ) async {
    ChildStoragePaths.overrideForTests(() async => 'test-scope-unused');
    await tester.pumpWidget(const ChildApp(config: ChildConfig()));
    await tester.pump();

    expect(find.text('Starting Haven Child…'), findsOneWidget);
    expect(find.byType(ChildApp), findsOneWidget);
  });
}
