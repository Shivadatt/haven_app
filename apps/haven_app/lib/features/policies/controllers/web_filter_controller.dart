import 'package:get/get.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../data/policies_repository.dart';
import '../data/policy_config.dart';
import '../data/policy_rules.dart';
import '../data/web_filter_models.dart';

final class WebFilterController extends GetxController {
  WebFilterController({
    required PoliciesRepository policiesRepo,
    required DevicesRepository devicesRepo,
    String? initialDeviceId,
  }) : _policiesRepo = policiesRepo,
       _devicesRepo = devicesRepo,
       selectedDeviceId = (initialDeviceId ?? '').obs;

  final PoliciesRepository _policiesRepo;
  final DevicesRepository _devicesRepo;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final Rx<PolicyConfig> config = PolicyConfig.defaults().obs;
  final RxList<Device> devices = <Device>[].obs;
  final RxString selectedDeviceId;
  final RxInt activeTabIndex = 0.obs; // 0 = Blocked Domains, 1 = Allowed Domains
  final Rx<WebCategory> selectedCategory = WebCategory.all.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final devResult = await _devicesRepo.pairedDevices();
    if (devResult.isOk) {
      devices.value = devResult.valueOrNull ?? [];
      if (selectedDeviceId.value.isEmpty && devices.isNotEmpty) {
        selectedDeviceId.value = devices.first.id;
      }
    }

    final devId = selectedDeviceId.value.isEmpty ? null : selectedDeviceId.value;
    final cfgResult = await _policiesRepo.loadConfig(deviceId: devId);
    if (cfgResult.isOk) {
      config.value = cfgResult.valueOrNull ?? PolicyConfig.defaults();
    }
    isLoading.value = false;
  }

  Future<void> selectDevice(String deviceId) async {
    if (selectedDeviceId.value == deviceId) return;
    selectedDeviceId.value = deviceId;
    await load();
  }

  void switchTab(int index) => activeTabIndex.value = index;
  void setCategory(WebCategory category) => selectedCategory.value = category;
  void setSearchQuery(String query) => searchQuery.value = query;

  List<String> get currentList => activeTabIndex.value == 0
      ? config.value.blockedDomains
      : config.value.allowedDomains;

  List<String> get filteredDomains {
    final query = searchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value;
    final domains = currentList;

    return domains.where((domain) {
      final matchesCat = (cat == WebCategory.all ||
          WebFilterModels.categorize(domain) == cat);
      final matchesQuery = query.isEmpty || domain.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();
  }

  Future<bool> addDomain(String rawDomain, {required bool isBlocked}) async {
    final clean = WebFilterModels.normalizeDomain(rawDomain);
    final err = PolicyRules.validateDomain(clean);
    if (err != null) {
      errorMessage.value = err;
      return false;
    }

    final allowed = config.value.allowedDomains.where((d) => d != clean).toList();
    final blocked = config.value.blockedDomains.where((d) => d != clean).toList();

    if (isBlocked) {
      blocked.add(clean);
    } else {
      allowed.add(clean);
    }

    config.value = config.value.copyWith(
      allowedDomains: allowed,
      blockedDomains: blocked,
    );
    return _saveConfig();
  }

  Future<bool> editDomain(
    String oldDomain,
    String newRawDomain, {
    required bool isBlocked,
  }) async {
    final cleanNew = WebFilterModels.normalizeDomain(newRawDomain);
    final err = PolicyRules.validateDomain(cleanNew);
    if (err != null) {
      errorMessage.value = err;
      return false;
    }

    final allowed = config.value.allowedDomains.where((d) => d != oldDomain).toList();
    final blocked = config.value.blockedDomains.where((d) => d != oldDomain).toList();

    if (isBlocked) {
      if (!blocked.contains(cleanNew)) blocked.add(cleanNew);
    } else {
      if (!allowed.contains(cleanNew)) allowed.add(cleanNew);
    }

    config.value = config.value.copyWith(
      allowedDomains: allowed,
      blockedDomains: blocked,
    );
    return _saveConfig();
  }

  Future<bool> removeDomain(String domain) async {
    final clean = domain.trim().toLowerCase();
    final allowed = config.value.allowedDomains.where((d) => d != clean).toList();
    final blocked = config.value.blockedDomains.where((d) => d != clean).toList();

    config.value = config.value.copyWith(
      allowedDomains: allowed,
      blockedDomains: blocked,
    );
    return _saveConfig();
  }

  Future<bool> toggleSafeSearch(bool enabled) async {
    config.value = config.value.copyWith(safeSearchEnabled: enabled);
    return _saveConfig();
  }

  Future<bool> addCategoryPreset(WebCategory category, {required bool isBlocked}) async {
    final presetDomains = WebFilterModels.presets[category] ?? [];
    if (presetDomains.isEmpty) return true;

    var allowed = [...config.value.allowedDomains];
    var blocked = [...config.value.blockedDomains];

    for (final domain in presetDomains) {
      allowed.remove(domain);
      blocked.remove(domain);
      if (isBlocked) {
        blocked.add(domain);
      } else {
        allowed.add(domain);
      }
    }

    config.value = config.value.copyWith(
      allowedDomains: allowed,
      blockedDomains: blocked,
    );
    return _saveConfig();
  }

  Future<bool> _saveConfig() async {
    isSaving.value = true;
    errorMessage.value = null;
    final devId = selectedDeviceId.value.isEmpty ? null : selectedDeviceId.value;
    final res = await _policiesRepo.saveConfig(config.value, deviceId: devId);
    isSaving.value = false;
    if (res.isErr) {
      errorMessage.value = res.failureOrNull?.message ?? 'Failed to save filter.';
      return false;
    }
    return true;
  }
}
