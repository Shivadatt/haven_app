import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_app/features/family/data/family_models.dart';

import '../family/fakes.dart';
import '../support/data_fakes.dart';

Map<String, Object?> alertRow(
  String id,
  String at, {
  String severity = 'info',
}) => {
  'id': id,
  'family_id': 'f1',
  'device_id': 'd1',
  'type': 'geofence_exit',
  'severity': severity,
  'message': 'Left Home',
  'payload': <String, Object?>{},
  'created_at': at,
};

void main() {
  late FakeFamilyRepository family;
  late FakeRowReader rows;
  late HavenDashboardRepository subject;

  void build({
    FamilyBundle? bundle,
    List<Map<String, Object?>> alerts = const [],
    HavenFailure? alertsFailWith,
    HavenFailure? familyFailWith,
  }) {
    family = FakeFamilyRepository(bundle: bundle)
      ..loadFailWith = familyFailWith;
    rows = FakeRowReader(
      {
        TableName.safetyAlerts: alerts,
        TableName.familyMembers: const <Map<String, Object?>>[],
      },
      alertsFailWith == null ? null : {TableName.safetyAlerts: alertsFailWith},
    );
    subject = HavenDashboardRepository(family: family, rows: () => rows);
  }

  test(
    'reads this family\'s alerts, newest first, in the capped window',
    () async {
      build(
        bundle: bundle(),
        alerts: [
          alertRow('a1', '2026-11-01T08:00:00.000Z'),
          alertRow('a2', '2026-11-03T08:00:00.000Z'),
          alertRow('a3', '2026-11-02T08:00:00.000Z'),
        ],
      );

      final DashboardData data = (await subject.load()).valueOrNull!;

      expect(rows.lastTable, TableName.safetyAlerts);
      expect(rows.filters.last, {'family_id': 'f1'});
      expect(rows.orderings.last, 'created_at');
      expect(rows.limits.last, DashboardData.alertWindow);
      expect(data.alerts.map((SafetyAlert a) => a.id).toList(), [
        'a2',
        'a3',
        'a1',
      ]);
    },
  );

  test('the window is a read limit, not a claim about the family', () async {
    build(
      bundle: bundle(),
      alerts: [
        for (int i = 0; i < 9; i++)
          alertRow('a$i', '2026-11-0${(i % 3) + 1}T08:00:00.000Z'),
      ],
    );

    final DashboardData data = (await subject.load()).valueOrNull!;

    expect(data.alerts.length, DashboardData.alertWindow);
  });

  test('a failed alert read keeps the family and says what failed', () async {
    build(
      bundle: bundle(),
      alertsFailWith: const NetworkFailure('Could not read.'),
    );

    final DashboardData data = (await subject.load()).valueOrNull!;

    expect(data.family, isNotNull);
    expect(data.alerts, isEmpty);
    expect(data.alertsFailure, isA<NetworkFailure>());
  });

  test(
    'an account with no family is shown as first run, with nothing read',
    () async {
      build(bundle: null);

      final DashboardData data = (await subject.load()).valueOrNull!;

      expect(data.needsSetup, isTrue);
      expect(rows.readTables, isEmpty);
    },
  );

  test(
    'a family read that fails is a failure, not an empty dashboard',
    () async {
      build(familyFailWith: const PermissionFailure('RLS refused the read.'));

      final Result<DashboardData> result = await subject.load();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    },
  );

  test(
    'the device section refuses with the F6 evidence, not an empty list',
    () async {
      build(bundle: bundle());

      final BlockedFailure failure =
          (await subject.pairedDevices()).failureOrNull! as BlockedFailure;

      expect(failure.missing, contains('00-status-register.md:86'));
      expect(
        failure.message,
        'Haven cannot list paired devices in this build yet.',
      );
    },
  );
}
