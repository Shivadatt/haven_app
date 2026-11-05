import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';

import '../family/fakes.dart';
import 'fakes.dart';

void main() {
  (DashboardController, List<(String, String, Object?)>) build(
    FakeDashboardRepository repo,
  ) {
    final nav = <(String, String, Object?)>[];
    final subject = DashboardController(
      repository: repo,
      push: (String route, Object? arg) => nav.add(('push', route, arg)),
      replace: (String route, Object? arg) => nav.add(('replace', route, arg)),
    );
    return (subject, nav);
  }

  DashboardData withFamily() => DashboardData(
    family: bundle(children: [child('c1', 'Ivy')]),
    alerts: const [],
  );

  test('loading carries the family and the device refusal', () async {
    final (subject, _) = build(FakeDashboardRepository(data: withFamily()));

    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.data.value!.valueOrNull!.family, isNotNull);
    expect(subject.deviceGap.value, isA<BlockedFailure>());
    expect(subject.needsSetup, isFalse);
  });

  test('an account with no family is reported as first run', () async {
    final (subject, _) = build(FakeDashboardRepository());

    await subject.load();

    expect(subject.needsSetup, isTrue);
  });

  test('a failed read is kept, not turned into an empty dashboard', () async {
    final (subject, _) = build(
      FakeDashboardRepository()
        ..loadFailWith = const NetworkFailure('No connection.'),
    );

    await subject.load();

    expect(subject.data.value!.failureOrNull, isA<NetworkFailure>());
  });

  test('pull-to-refresh re-reads without re-showing the spinner', () async {
    final repo = FakeDashboardRepository(data: withFamily());
    final (subject, _) = build(repo);
    await subject.load();

    await subject.reload();

    expect(subject.isLoading.value, isFalse);
    expect(repo.calls.where((String c) => c == 'load').length, 2);
    // The refusal was already read once; refresh does not re-ask for it.
    expect(repo.calls.where((String c) => c == 'pairedDevices').length, 1);
  });

  test(
    'setup replaces the stack, everything else opens on top of it',
    () async {
      final (subject, nav) = build(FakeDashboardRepository(data: withFamily()));
      await subject.load();

      subject.goToSetup();
      subject.goToFamily();
      subject.goToChild('c1');
      subject.goToSettings();

      expect(nav, [
        ('replace', AppRoutes.onboarding, null),
        ('push', AppRoutes.family, null),
        ('push', AppRoutes.childProfile, 'c1'),
        ('push', AppRoutes.settings, null),
      ]);
    },
  );

  test(
    'the three lanes that can be read open on top, including the one that can '
    'be written',
    () async {
      final (subject, nav) = build(FakeDashboardRepository(data: withFamily()));
      await subject.load();

      subject.goToActivity();
      subject.goToLocation();
      subject.goToSafeZones();

      expect(nav, [
        ('push', AppRoutes.activity, null),
        ('push', AppRoutes.location, null),
        // Named places are reachable even while the device list is not:
        // `safe_zones` has a SELECT grant, `devices` has only a policy.
        ('push', AppRoutes.safeZones, null),
      ]);
    },
  );

  test('the two read-only records and the report list open on top', () async {
    final (subject, nav) = build(FakeDashboardRepository(data: withFamily()));
    await subject.load();

    subject.goToCommands();
    subject.goToPolicies();
    subject.goToSessions();
    subject.goToNotifications();

    expect(nav, [
      ('push', AppRoutes.commands, null),
      ('push', AppRoutes.policies, null),
      // Both are reachable as reads: `remote_sessions` and `safety_alerts`
      // carry a SELECT grant for a parent, and nothing on those screens
      // claims to move a row.
      ('push', AppRoutes.remoteSessions, null),
      ('push', AppRoutes.notifications, null),
    ]);
  });
}
