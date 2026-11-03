import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../family/data/family_models.dart';
import '../../family/data/family_repository.dart';

/// What the first screen after sign-in can honestly say.
///
/// `family` is null when this account has no family yet — the state first-run
/// setup exists for. `alerts` are the most recent rows the parent is allowed to
/// read, and `alertsFailure` carries the reason when that one read did not work,
/// so the children section can still load while the alerts section explains
/// itself instead of showing an empty list that would read as "all is well".
final class DashboardData {
  const DashboardData({
    required this.family,
    required this.alerts,
    this.alertsFailure,
  });

  final FamilyBundle? family;
  final List<SafetyAlert> alerts;
  final HavenFailure? alertsFailure;

  bool get needsSetup => family == null;
  bool get hasAlerts => alerts.isNotEmpty;

  static const int alertWindow = 5;
}

/// The parent dashboard's surface: the family, its children, and what has been
/// reported recently.
abstract interface class DashboardRepository {
  Future<Result<DashboardData>> load();

  /// Paired devices, which this build cannot list at all. Kept as a typed call
  /// so the screen renders the refusal rather than an empty device section that
  /// would imply "nothing is paired".
  Future<Result<void>> pairedDevices();
}

final class HavenDashboardRepository implements DashboardRepository {
  /// The family half is read through the family feature's own repository: one
  /// membership read, two screens, and no chance for the two to disagree.
  HavenDashboardRepository({required this._family, required this._rows});

  final FamilyRepository _family;
  final RowReader Function() _rows;

  @override
  Future<Result<DashboardData>> load() async {
    final Result<FamilyBundle?> bundle = await _family.load();
    final FamilyBundle? value = bundle.valueOrNull;
    if (value == null) {
      final HavenFailure? why = bundle.failureOrNull;
      if (why != null) return Err<DashboardData>(why);
      // No family yet is the first-run state, not a fault: the screen shows the
      // setup path and there are no alerts to read for a family that does not
      // exist.
      return const Ok<DashboardData>(
        DashboardData(family: null, alerts: <SafetyAlert>[]),
      );
    }

    final Result<List<SafetyAlert>> alerts = await _recentAlerts(value);
    final HavenFailure? alertsFailure = alerts.failureOrNull;
    if (alertsFailure != null) {
      // Keep the family half of the page. The alerts section explains the
      // failure instead of an empty list that would read as "all is well".
      return Ok<DashboardData>(
        DashboardData(
          family: value,
          alerts: const [],
          alertsFailure: alertsFailure,
        ),
      );
    }
    return Ok<DashboardData>(
      DashboardData(family: value, alerts: alerts.valueOrNull!),
    );
  }

  Future<Result<List<SafetyAlert>>> _recentAlerts(FamilyBundle bundle) async {
    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.safetyAlerts,
      eq: {'family_id': bundle.family.id},
      orderDesc: 'created_at',
      limit: DashboardData.alertWindow,
    );
    final HavenFailure? failure = rows.failureOrNull;
    if (failure != null) return Err<List<SafetyAlert>>(failure);
    return Ok<List<SafetyAlert>>(
      rows.valueOrNull!.map(SafetyAlert.fromRow).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> pairedDevices() async =>
      CapturedGaps.deviceLaneUnavailable();
}
