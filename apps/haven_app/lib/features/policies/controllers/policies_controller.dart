import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/policies_models.dart';
import '../data/policies_repository.dart';
import '../data/policy_config.dart';
import '../data/policy_rules.dart';
import '../data/policy_schedules.dart';

/// The policy versions and local rule configuration for this family.
final class PoliciesController extends GetxController {
  PoliciesController({
    required PoliciesRepository repository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
        _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final PoliciesRepository _repository;
  final void Function(String route, Object? arg) _replace;
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<PolicyBoard?>?> board = Rx<Result<PolicyBoard?>?>(null);

  bool get canConfigure => _repository.canConfigure;
  final Rx<PolicyConfig> config = PolicyConfig.defaults().obs;
  final RxBool isSaving = false.obs;
  final RxnString configMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final devId = deviceId.isEmpty ? null : deviceId;
    final Result<PolicyBoard?> read = await _repository.load(deviceId: devId);
    if (canConfigure) {
      final cfgRes = await _repository.loadConfig(deviceId: devId);
      if (cfgRes.isOk) config.value = cfgRes.valueOrNull!;
    }
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  Future<void> reload() async {
    final devId = deviceId.isEmpty ? null : deviceId;
    final read = await _repository.load(deviceId: devId);
    PolicyConfig? nextConfig;
    if (canConfigure) {
      final cfgRes = await _repository.loadConfig(deviceId: devId);
      if (cfgRes.isOk) nextConfig = cfgRes.valueOrNull!;
    }
    if (isClosed) return;
    board.value = read;
    if (nextConfig != null) config.value = nextConfig;
  }

  void goToSetup() => _replace(AppRoutes.onboarding, null);

  Future<bool> updateDailyLimit(int minutes) async {
    final err = PolicyRules.validateMinutesLimit(minutes);
    if (err != null) {
      configMessage.value = err;
      return false;
    }
    config.value = config.value.copyWith(dailyScreenTimeMinutes: minutes);
    return _saveConfig();
  }

  Future<bool> saveSchedule(PolicySchedule schedule) async {
    final list = [...config.value.schedules];
    final idx = list.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) {
      list[idx] = schedule;
    } else {
      list.add(schedule);
    }
    config.value = config.value.copyWith(schedules: list);
    return _saveConfig();
  }

  Future<bool> toggleSchedule(String scheduleId) async {
    final list = config.value.schedules
        .map((s) => s.id == scheduleId ? s.copyWith(isActive: !s.isActive) : s)
        .toList();
    config.value = config.value.copyWith(schedules: list);
    return _saveConfig();
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    final list = config.value.schedules.where((s) => s.id != scheduleId).toList();
    config.value = config.value.copyWith(schedules: list);
    return _saveConfig();
  }

  Future<bool> addApp(String packageName, {required bool blocked}) async {
    final err = PolicyRules.validatePackageName(packageName);
    if (err != null) {
      configMessage.value = err;
      return false;
    }
    final clean = packageName.trim();
    final allowed = config.value.allowedApps.where((p) => p != clean).toList();
    final blk = config.value.blockedApps.where((p) => p != clean).toList();
    if (blocked) {
      blk.add(clean);
    } else {
      allowed.add(clean);
    }
    config.value = config.value.copyWith(allowedApps: allowed, blockedApps: blk);
    return _saveConfig();
  }

  Future<bool> removeApp(String packageName) async {
    final clean = packageName.trim();
    final allowed = config.value.allowedApps.where((p) => p != clean).toList();
    final blk = config.value.blockedApps.where((p) => p != clean).toList();
    final limits = Map<String, int>.from(config.value.appLimits)..remove(clean);
    config.value = config.value.copyWith(allowedApps: allowed, blockedApps: blk, appLimits: limits);
    return _saveConfig();
  }

  Future<bool> setAppLimit(String packageName, int minutes) async {
    final err = PolicyRules.validateMinutesLimit(minutes);
    if (err != null) {
      configMessage.value = err;
      return false;
    }
    final clean = packageName.trim();
    final limits = Map<String, int>.from(config.value.appLimits)..[clean] = minutes;
    config.value = config.value.copyWith(appLimits: limits);
    return _saveConfig();
  }

  Future<bool> removeAppLimit(String packageName) async {
    final limits = Map<String, int>.from(config.value.appLimits)..remove(packageName.trim());
    config.value = config.value.copyWith(appLimits: limits);
    return _saveConfig();
  }

  Future<bool> addDomain(String domain, {required bool blocked}) async {
    final err = PolicyRules.validateDomain(domain);
    if (err != null) {
      configMessage.value = err;
      return false;
    }
    final clean = domain.trim().toLowerCase();
    final allowed = config.value.allowedDomains.where((d) => d != clean).toList();
    final blk = config.value.blockedDomains.where((d) => d != clean).toList();
    if (blocked) {
      blk.add(clean);
    } else {
      allowed.add(clean);
    }
    config.value = config.value.copyWith(allowedDomains: allowed, blockedDomains: blk);
    return _saveConfig();
  }

  Future<bool> removeDomain(String domain) async {
    final clean = domain.trim().toLowerCase();
    final allowed = config.value.allowedDomains.where((d) => d != clean).toList();
    final blk = config.value.blockedDomains.where((d) => d != clean).toList();
    config.value = config.value.copyWith(allowedDomains: allowed, blockedDomains: blk);
    return _saveConfig();
  }

  Future<bool> _saveConfig() async {
    isSaving.value = true;
    configMessage.value = null;
    final res = await _repository.saveConfig(
      config.value,
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    isSaving.value = false;
    if (res.isErr) {
      configMessage.value = res.failureOrNull?.message;
      return false;
    }
    return true;
  }
}
