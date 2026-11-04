import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/notifications/controllers/notifications_controller.dart';
import 'package:haven_app/features/notifications/data/alerts_repository.dart';
import 'package:haven_app/features/notifications/services/alert_delivery.dart';
import 'package:haven_app/features/notifications/views/pages/notifications_page.dart';

import '../support/feed_fakes.dart';
import 'fakes.dart';

/// How a reports test gets onto the page. [routes] records the verb each
/// navigation used, because replacing the stack with setup and opening the
/// settings screen are different promises.
final class ReportsDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeAlertsRepository repository;

  /// The shared hint lane, so a test can say "the backend told this screen to
  /// read again" and count what the screen then read.
  final FakeChangeFeed feed = FakeChangeFeed();

  Future<void> open(
    WidgetTester tester, {
    FakeAlertsRepository? repo,
    AlertDelivery? delivery,
    bool withFeed = false,
  }) async {
    routes.clear();
    repository = repo ?? FakeAlertsRepository();
    Get.put<NotificationsController>(
      NotificationsController(
        repository: repository,
        delivery: delivery,
        feed: withFeed ? () => feed : null,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const NotificationsPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String label) async {
    final Finder action = find.text(label);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  /// Every control on the page that can actually be pressed. §2 of the brief
  /// forbids a control that can only ever be refused, so the only one allowed
  /// here is the button that opens the screen which owns the permission.
  int get actionableButtons => _count(FilledButton) + _count(OutlinedButton);

  int _count(Type kind) => find
      .byType(kind)
      .evaluate()
      .map((Element e) => e.widget)
      .whereType<ButtonStyleButton>()
      .where((ButtonStyleButton button) => button.onPressed != null)
      .length;

  /// Only the fake's own refusal words are used by these tests, so a screen that
  /// paraphrases the gap instead of rendering it fails.
  static const String readGap = 'no report read seeded';

  static const String setup = 'Start setup';
  static const String openSettings = 'Open settings';
  static const String emptyLine =
      'Nothing has been reported about this family yet.';
  static const String ackGap = HavenAlertsRepository.ackMissing;
  static const String deliveryGap = HavenAlertsRepository.deliveryMissing;
}
