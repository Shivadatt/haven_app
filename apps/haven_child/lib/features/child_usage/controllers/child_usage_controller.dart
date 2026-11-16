import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/native/usage_envelope_models.dart';
import '../data/child_usage_repository.dart';
import '../domain/usage_freshness_status.dart';

/// Discrete states of the child usage monitoring feature.
enum ChildUsageStatus {
  initial, loading, permissionRequired, unsupported, loaded, empty, delayed, error,
}

/// Reactive GetX controller for child device Usage Access & screen time.
final class ChildUsageController extends GetxController with WidgetsBindingObserver {
  ChildUsageController({
    required this.repository,
    this.clock = systemClock,
    bool registerObserver = true,
  }) : _registerObserver = registerObserver;

  final ChildUsageRepository repository;
  final Clock clock;
  final bool _registerObserver;

  final Rx<ChildUsageStatus> status = ChildUsageStatus.initial.obs;
  final RxBool isBusy = false.obs;
  final Rx<UsagePermissionStatus?> permissionStatus = Rx<UsagePermissionStatus?>(null);
  final Rxn<UsageDailyResult> dailyUsage = Rxn<UsageDailyResult>();
  final Rxn<UsageFreshnessStatus> freshness = Rxn<UsageFreshnessStatus>();
  final Rxn<HavenFailure> failure = Rxn<HavenFailure>();
  final RxnString errorMessage = RxnString();

  int _activeRequestId = 0;
  bool _observerRegistered = false;
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed || isClosed;
  bool get isLoading => isBusy.value || status.value == ChildUsageStatus.loading;
  bool get isPermissionGranted => permissionStatus.value == UsagePermissionStatus.granted;
  bool get isPermissionRequired => status.value == ChildUsageStatus.permissionRequired;
  bool get isUnsupported => status.value == ChildUsageStatus.unsupported;
  bool get hasData => dailyUsage.value != null && dailyUsage.value!.apps.isNotEmpty;
  bool get isEmpty => status.value == ChildUsageStatus.empty;
  bool get isDelayed => status.value == ChildUsageStatus.delayed;
  bool get hasError => status.value == ChildUsageStatus.error;
  Duration get totalForegroundDuration => dailyUsage.value?.totalForegroundDuration ?? Duration.zero;
  List<UsageAppRecord> get appRecords => dailyUsage.value?.apps ?? const <UsageAppRecord>[];

  @override
  void onInit() {
    super.onInit();
    if (_registerObserver && !_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }
    unawaited(loadUsage());
  }

  @override
  void onClose() {
    _isDisposed = true;
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    clearUsageData();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isDisposed) {
      unawaited(handleAppResume());
    }
  }

  /// Clears all transient usage records, timestamps and freshness from memory.
  void clearUsageData() {
    dailyUsage.value = null;
    freshness.value = null;
  }

  void _setFailure(HavenFailure f) {
    clearUsageData();
    failure.value = f;
    errorMessage.value = f.message;
    status.value = ChildUsageStatus.error;
  }

  /// Verifies permission status with native bridge.
  Future<Result<UsagePermissionResult>> checkPermission() async {
    final Result<UsagePermissionResult> result = await repository.getPermissionStatus();
    if (isDisposed) return result;

    if (result case Ok<UsagePermissionResult>(:final value)) {
      permissionStatus.value = value.status;
      if (value.status == UsagePermissionStatus.denied) {
        clearUsageData();
        status.value = ChildUsageStatus.permissionRequired;
      } else if (value.status == UsagePermissionStatus.unsupported) {
        clearUsageData();
        status.value = ChildUsageStatus.unsupported;
      }
    } else if (result case Err<UsagePermissionResult>(:final failure)) {
      _setFailure(failure);
    }
    return result;
  }

  /// Opens the native Android Usage Access settings screen.
  Future<Result<UsageSettingsLaunchResult>> openUsageSettings() async {
    final Result<UsageSettingsLaunchResult> result = await repository.openUsageSettings();
    if (isDisposed) return result;
    if (result case Err<UsageSettingsLaunchResult>(:final failure)) {
      this.failure.value = failure;
      errorMessage.value = failure.message;
    }
    return result;
  }

  /// Loads daily usage statistics with stale-response protection.
  Future<void> loadUsage({int? startTimeMillis, int? endTimeMillis}) async {
    final int requestId = ++_activeRequestId;
    isBusy.value = true;
    status.value = ChildUsageStatus.loading;
    failure.value = null;
    errorMessage.value = null;

    try {
      final Result<UsagePermissionResult> permResult = await repository.getPermissionStatus();
      if (isDisposed || requestId != _activeRequestId) return;

      if (permResult case Err<UsagePermissionResult>(:final failure)) {
        _setFailure(failure);
        return;
      }

      final UsagePermissionResult perm = permResult.valueOrNull!;
      permissionStatus.value = perm.status;

      if (perm.status == UsagePermissionStatus.denied) {
        clearUsageData();
        status.value = ChildUsageStatus.permissionRequired;
        return;
      }
      if (perm.status == UsagePermissionStatus.unsupported) {
        clearUsageData();
        status.value = ChildUsageStatus.unsupported;
        return;
      }

      final (:start, :end) = _calculateRange(startTimeMillis, endTimeMillis);
      final Result<UsageDailyResult> usageResult =
          await repository.getDailyUsage(startTimeMillis: start, endTimeMillis: end);
      if (isDisposed || requestId != _activeRequestId) return;

      if (usageResult case Err<UsageDailyResult>(:final failure)) {
        _setFailure(failure);
        return;
      }

      final UsageDailyResult data = usageResult.valueOrNull!;
      dailyUsage.value = data;
      freshness.value = UsageFreshnessStatus.fromDataFreshness(data.dataFreshness);

      if (data.apps.isEmpty) {
        status.value = ChildUsageStatus.empty;
      } else if (data.dataFreshness == UsageDataFreshness.delayed) {
        status.value = ChildUsageStatus.delayed;
      } else {
        status.value = ChildUsageStatus.loaded;
      }
    } catch (e) {
      if (isDisposed || requestId != _activeRequestId) return;
      _setFailure(UnknownFailure('Unexpected controller error', detail: e.toString()));
    } finally {
      if (!isDisposed && requestId == _activeRequestId) {
        isBusy.value = false;
      }
    }
  }

  /// Triggers a manual refresh of usage data.
  Future<void> refreshUsage() => loadUsage();

  /// Rechecks permissions and reloads usage upon returning to the app.
  Future<void> handleAppResume() => loadUsage();

  ({int start, int end}) _calculateRange(int? startMillis, int? endMillis) {
    if (startMillis != null && endMillis != null) return (start: startMillis, end: endMillis);
    final now = clock.now();
    final start = startMillis ?? DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = endMillis ??
        (now.millisecondsSinceEpoch > start ? now.millisecondsSinceEpoch : start + 1000);
    return (start: start, end: end);
  }
}
