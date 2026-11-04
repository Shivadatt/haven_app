import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';

/// The dashboard's answers, driven by the test.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.data});

  DashboardData? data;
  HavenFailure? loadFailWith;

  /// What the device section answers. A real repository returns a
  /// [BlockedFailure]; a test can put anything here.
  HavenFailure? deviceGapWith;

  final List<String> calls = [];

  @override
  Future<Result<DashboardData>> load() async {
    calls.add('load');
    final HavenFailure? failure = loadFailWith;
    if (failure != null) return Err<DashboardData>(failure);
    return Ok<DashboardData>(
      data ?? const DashboardData(family: null, alerts: []),
    );
  }

  @override
  Future<Result<void>> pairedDevices() async {
    calls.add('pairedDevices');
    final HavenFailure? failure = deviceGapWith;
    return failure == null
        ? blocked<void>(
            'fake: devices table is unreadable (F6)',
            requirement: 'fake: no device list',
          )
        : Err<void>(failure);
  }
}
