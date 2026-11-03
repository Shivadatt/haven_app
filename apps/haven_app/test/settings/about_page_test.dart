import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart' show BackendEndpoints;
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/core/constants/haven_config.dart';
import 'package:haven_app/features/settings/views/pages/about_page.dart';

void main() {
  const configured = HavenConfig(
    endpoints: BackendEndpoints(
      supabaseUrl: 'https://example-ref.supabase.co',
      supabaseAnonKey: 'example-anon-value',
      firebaseProjectId: 'haven-example',
      firebaseAppId: '1:0:android:0',
      firebaseApiKey: 'example-api-value',
    ),
  );

  Future<void> open(WidgetTester tester, {HavenConfig? config}) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: HavenTheme.light,
        home: AboutPage(config: config),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('an unconfigured build admits it', (tester) async {
    await open(tester, config: const HavenConfig.unconfigured());

    expect(find.text('Not connected'), findsOneWidget);
    expect(
      find.textContaining('no staging project configured'),
      findsOneWidget,
    );
    expect(
      find.textContaining('HAVEN_SUPABASE_URL'),
      findsOneWidget,
      reason: 'the define names are diagnostic and non-secret',
    );
  });

  testWidgets('a configured build shows the ref and no key material', (
    tester,
  ) async {
    await open(tester, config: configured);

    expect(find.text('Connected to staging'), findsOneWidget);
    expect(find.textContaining('example-ref'), findsOneWidget);
    expect(
      find.textContaining('example-anon-value'),
      findsNothing,
      reason: 'no client key is ever printed on screen',
    );
    expect(find.textContaining('example-api-value'), findsNothing);
  });

  testWidgets('no configuration is a state, not a crash', (tester) async {
    await open(tester);

    expect(
      find.text('Haven has not been given any build configuration.'),
      findsOneWidget,
    );
  });

  testWidgets('the promises are on the page a parent can read', (tester) async {
    await open(tester, config: configured);

    expect(find.textContaining('does not hide itself'), findsOneWidget);
    expect(
      find.textContaining('once the device confirms it'),
      findsOneWidget,
      reason: '§7F: a restriction is only claimed when the OS confirms it',
    );
    expect(
      find.textContaining('Production is never contacted'),
      findsOneWidget,
    );
  });
}
