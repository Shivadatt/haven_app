import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/constants/haven_config.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../support/host.dart';

/// Every data screen carries this line, so an empty dashboard can never be
/// mistaken for a quiet child.
void main() {
  tearDown(Get.reset);

  testWidgets('an unconfigured build says so', (tester) async {
    Get.put<HavenConfig>(const HavenConfig.unconfigured(), permanent: true);
    await tester.pumpWidget(widgetHost(const BackendBanner()));

    expect(
      find.textContaining('no staging project configured'),
      findsOneWidget,
    );
  });

  testWidgets('a configured build stays quiet', (tester) async {
    Get.put<HavenConfig>(
      HavenConfig.fromDefines(
        'https://example.supabase.co',
        'anon-key',
        'example-firebase',
        '1:0:example',
        'build-key',
      ),
      permanent: true,
    );
    await tester.pumpWidget(widgetHost(const BackendBanner()));

    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });

  testWidgets('only the data backend missing is named as the gap', (
    tester,
  ) async {
    Get.put<HavenConfig>(
      HavenConfig.fromDefines('', '', 'example-firebase', '1:0:example', 'key'),
      permanent: true,
    );
    await tester.pumpWidget(widgetHost(const BackendBanner()));

    expect(
      find.textContaining("the data backend isn't"),
      findsOneWidget,
      reason: 'Firebase alone is never presented as a session',
    );
  });

  testWidgets('no config registered is no banner, not a crash', (tester) async {
    await tester.pumpWidget(widgetHost(const BackendBanner()));

    expect(find.byType(BackendBanner), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });
}
