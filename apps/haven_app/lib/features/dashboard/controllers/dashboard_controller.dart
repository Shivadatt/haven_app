import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/dashboard_repository.dart';

/// The screen a parent lands on.
///
/// It reports what the backend actually returned and nothing else: no rounded
/// figure, no "3 hours today" that was never read, no green tick on a device the
/// app cannot list. Each section owns its own failure, so one unreadable read
/// cannot blank the whole page.
final class DashboardController extends GetxController {
  DashboardController({
    required DashboardRepository repository,
    void Function(String route, Object? arg)? push,
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
        _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg)),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final DashboardRepository _repository;

  /// Two ways to move: a parent looking at a child stays able to come back, but
  /// a parent who has no family yet must not be able to land back on an empty
  /// dashboard.
  final void Function(String route, Object? arg) _push;
  final void Function(String route, Object? arg) _replace;

  final RxBool isLoading = true.obs;
  final Rx<Result<DashboardData>?> data = Rx<Result<DashboardData>?>(null);

  /// Why the device section is a refusal instead of a list.
  final Rxn<BlockedFailure> deviceGap = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<DashboardData> result = await _repository.load();
    deviceGap.value = _blocked(await _repository.pairedDevices());
    if (isClosed) return;
    data.value = result;
    isLoading.value = false;
  }

  /// Pull-to-refresh: the same read, without the spinner that would hide the
  /// numbers already on the page.
  Future<void> reload() async {
    final Result<DashboardData> result = await _repository.load();
    if (isClosed) return;
    data.value = result;
  }

  final RxBool isDemoBusy = false.obs;

  bool get isDemoMode => data.value?.valueOrNull?.isDemo ?? false;

  Future<void> loadDemoData() async {
    if (!Get.isRegistered<LocalTables>()) return;
    isDemoBusy.value = true;
    final tables = Get.find<LocalTables>();
    final session = (await HavenBackend.auth.currentSession()).valueOrNull;
    await DemoDataSuite.loadDemoData(tables, parentUserId: session?.userId);
    if (isClosed) return;
    await reload();
    isDemoBusy.value = false;
  }

  Future<void> removeDemoData() async {
    if (!Get.isRegistered<LocalTables>()) return;
    isDemoBusy.value = true;
    final tables = Get.find<LocalTables>();
    await DemoDataSuite.clearDemoData(tables);
    if (isClosed) return;
    await reload();
    isDemoBusy.value = false;
  }

  bool get needsSetup => data.value?.valueOrNull?.needsSetup ?? false;

  void goToSetup() => _replace(AppRoutes.onboarding, null);
  void goToFamily() => _push(AppRoutes.family, null);
  void goToDevices() => _push(AppRoutes.devices, null);

  /// App use is reachable even though the device list is not: `usage_daily`
  /// carries a SELECT grant for a parent, `devices` does not (F6). Hiding this
  /// behind the unreadable lane would throw away a read that works.
  void goToActivity() => _push(AppRoutes.activity, null);

  /// Places are the same case: `location_events` carries a SELECT grant for a
  /// parent, so this read works while the device list does not.
  void goToLocation() => _push(AppRoutes.location, null);

  /// Named places read and write: `safe_zones` is the one table this build has a
  /// proven UPDATE and DELETE grant on, so this screen leads somewhere a parent
  /// can actually change.
  void goToSafeZones() => _push(AppRoutes.safeZones, null);

  /// The instruction log reads `device_commands`, which carries a SELECT grant
  /// for a parent — the same case as app use and places.
  void goToCommands() => _push(AppRoutes.commands, null);

  /// Rule versions read `device_policies`, also selectable by a parent.
  void goToPolicies() => _push(AppRoutes.policies, null);

  /// Session records read `remote_sessions`, selectable for a parent, a child, or
  /// a family parent (`04-rls-matrix.md:53`) — the read works even though the
  /// device list does not.
  void goToSessions() => _push(AppRoutes.remoteSessions, null);

  /// Reports read `safety_alerts`, the same table this page's attention section
  /// already reads; the screen gives the wider window.
  void goToNotifications() => _push(AppRoutes.notifications, null);
  void goToChild(String childUserId) =>
      _push(AppRoutes.childProfile, childUserId);
  void goToSettings() => _push(AppRoutes.settings, null);
  void goToAppLimits() => _push(AppRoutes.appLimits, null);
  void goToAppRules() => _push(AppRoutes.appRules, null);
  void goToWebFilter() => _push(AppRoutes.webFilter, null);
  void goToSchedules() => _push(AppRoutes.schedulesEditor, null);
  void goToApprovals() => _push(AppRoutes.appApprovals, null);
  void goToExtensionRequests() => _push(AppRoutes.extensionRequests, null);
  void goToHelp() => _push(AppRoutes.helpCenter, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
