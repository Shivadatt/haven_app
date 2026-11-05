import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart' show LocalIds;

import '../data/policies_repository.dart';
import '../data/policy_config.dart';
import '../data/policy_schedules.dart';
import '../data/schedule_conflicts.dart';

/// Controller for the Advanced Schedule Editor (/policies/schedules).
final class SchedulesEditorController extends GetxController {
  SchedulesEditorController({
    required PoliciesRepository repository,
    this.deviceId = '',
  }) : _repository = repository;

  final PoliciesRepository _repository;
  final String deviceId;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final Rx<PolicyConfig> config = PolicyConfig.defaults().obs;
  final RxnString errorMessage = RxnString();
  final RxnString statusMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final devId = deviceId.isEmpty ? null : deviceId;
    final res = await _repository.loadConfig(deviceId: devId);
    if (isClosed) return;
    if (res.isOk) {
      config.value = res.valueOrNull!;
    }
    isLoading.value = false;
  }

  List<PolicySchedule> get schedules => config.value.schedules;
  List<PolicySchedule> get bedtimeSchedules =>
      schedules.where((s) => s.type == PolicyScheduleType.bedtime).toList();
  List<PolicySchedule> get schoolSchedules =>
      schedules.where((s) => s.type == PolicyScheduleType.school).toList();
  List<PolicySchedule> get customSchedules =>
      schedules.where((s) => s.type == PolicyScheduleType.custom).toList();

  Future<bool> toggleSchedule(String scheduleId) async {
    final list = schedules
        .map((s) => s.id == scheduleId ? s.copyWith(isActive: !s.isActive) : s)
        .toList();
    return _applySchedules(list);
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    final list = schedules.where((s) => s.id != scheduleId).toList();
    return _applySchedules(list);
  }

  Future<bool> saveSchedule(PolicySchedule schedule) async {
    errorMessage.value = null;
    statusMessage.value = null;

    if (schedule.name.trim().isEmpty) {
      errorMessage.value = 'Schedule name cannot be empty.';
      return false;
    }
    if (!PolicySchedule.isValidTime(schedule.startTime) ||
        !PolicySchedule.isValidTime(schedule.endTime)) {
      errorMessage.value = 'Start and end times must be in valid HH:mm format.';
      return false;
    }
    if (schedule.days.isEmpty) {
      errorMessage.value = 'Please select at least one active day.';
      return false;
    }

    if (ScheduleConflictDetector.hasDuplicateName(
      name: schedule.name,
      existingList: schedules,
      excludeId: schedule.id,
    )) {
      errorMessage.value = 'A schedule named "${schedule.name}" already exists.';
      return false;
    }

    final conflicts = ScheduleConflictDetector.findConflicts(
      candidate: schedule,
      existingList: schedules,
    );
    if (conflicts.isNotEmpty) {
      statusMessage.value = 'Saved with warning: ${conflicts.first.summary}';
    }

    final list = [...schedules];
    final idx = list.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) {
      list[idx] = schedule;
    } else {
      list.add(schedule);
    }

    return _applySchedules(list);
  }

  PolicySchedule createDraft(PolicyScheduleType type) {
    final id = LocalIds.create();
    switch (type) {
      case PolicyScheduleType.bedtime:
        return PolicySchedule(
          id: id,
          name: 'Bedtime',
          type: PolicyScheduleType.bedtime,
          startTime: '21:00',
          endTime: '07:00',
          days: const [1, 2, 3, 4, 5, 6, 7],
          isActive: true,
        );
      case PolicyScheduleType.school:
        return PolicySchedule(
          id: id,
          name: 'School Hours',
          type: PolicyScheduleType.school,
          startTime: '08:30',
          endTime: '15:00',
          days: const [1, 2, 3, 4, 5],
          isActive: true,
          allowedApps: const ['com.android.calculator2'],
        );
      case PolicyScheduleType.custom:
        return PolicySchedule(
          id: id,
          name: 'Custom Focus',
          type: PolicyScheduleType.custom,
          startTime: '16:00',
          endTime: '18:00',
          days: const [1, 2, 3, 4, 5],
          isActive: true,
          category: 'Focus',
        );
    }
  }

  Future<bool> _applySchedules(List<PolicySchedule> list) async {
    isSaving.value = true;
    final updated = config.value.copyWith(schedules: list);
    final devId = deviceId.isEmpty ? null : deviceId;
    final res = await _repository.saveConfig(updated, deviceId: devId);
    isSaving.value = false;
    if (res.isOk) {
      config.value = updated;
      return true;
    } else {
      errorMessage.value = res.failureOrNull?.message ?? 'Failed to save schedule.';
      return false;
    }
  }
}
