import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/remote_sessions/controllers/session_detail_controller.dart';
import 'package:haven_app/features/remote_sessions/controllers/sessions_controller.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_app/features/remote_sessions/views/pages/remote_session_detail_page.dart';
import 'package:haven_app/features/remote_sessions/views/pages/remote_sessions_page.dart';

import '../support/feed_fakes.dart';
import 'fakes.dart';

/// How a session test gets onto either screen.
///
/// The two routes take the same seams a binding would pass — repository, feed,
/// navigation — so a test can watch which verb the controller uses. Replacing the
/// stack with setup and pushing a record on top are different promises.
final class SessionsDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeSessionsRepository repository;

  /// The shared hint lane the list watches, so a test can say "the backend told
  /// this screen to read again" and count what the screen then read.
  final FakeChangeFeed feed = FakeChangeFeed();

  Future<void> openList(
    WidgetTester tester, {
    FakeSessionsRepository? repo,
    bool withFeed = false,
  }) async {
    routes.clear();
    repository = repo ?? FakeSessionsRepository();
    Get.put<SessionsController>(
      SessionsController(
        repository: repository,
        feed: withFeed ? () => feed : null,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const RemoteSessionsPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDetail(
    WidgetTester tester, {
    FakeSessionsRepository? repo,
    String sessionId = 's1',
  }) async {
    routes.clear();
    repository = repo ?? FakeSessionsRepository();
    Get.put<SessionDetailController>(
      SessionDetailController(
        repository: repository,
        sessionId: sessionId,
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: HavenTheme.light,
        home: const RemoteSessionDetailPage(),
      ),
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
  /// forbids a control that can only ever be refused, so the only ones allowed
  /// here are the row buttons that navigate to a record the backend returned.
  int get actionableButtons => _count(FilledButton) + _count(OutlinedButton);

  int _count(Type kind) => find
      .byType(kind)
      .evaluate()
      .map((Element e) => e.widget)
      .whereType<ButtonStyleButton>()
      .where((ButtonStyleButton button) => button.onPressed != null)
      .length;

  /// The fake's own refusal words, so a screen that paraphrases the gap instead
  /// of rendering it fails.
  static const String readGap = 'no session read seeded';
  static const String recordGap = 'no session record seeded';

  static const String setup = 'Start setup';
  static const String emptyList =
      'No session has been asked for in this family yet.';
  static const String startGap = SessionGaps.startMissing;
  static const String mediaGap = SessionGaps.mediaMissing;
  static const String signalGap = SessionGaps.signalMissing;
}
