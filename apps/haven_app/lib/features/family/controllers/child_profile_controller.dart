import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../../child_devices/data/device_route_args.dart';
import '../../../core/errors/captured_gaps.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

/// One child, as far as a parent may manage them.
final class ChildProfileController extends GetxController {
  ChildProfileController({
    required this.childUserId,
    required FamilyRepository repository,
    RowReader Function()? rows,
    void Function(String route, Object? arg)? goTo,
    void Function(String route, Object? arg)? push,
  }) : _repository = repository,
       _rows = rows ?? (() => HavenBackend.rows),
       _goTo = goTo ?? ((String route, Object? arg) => Get.offAllNamed(route, arguments: arg)),
       _push = push ?? ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final String childUserId;
  final FamilyRepository _repository;
  final RowReader Function() _rows;
  final void Function(String route, Object? arg) _goTo;
  final void Function(String route, Object? arg) _push;

  final RxBool isLoading = true.obs;
  final Rx<Result<FamilyPerson?>?> person = Rx<Result<FamilyPerson?>?>(null);
  final RxBool isRemoving = false.obs;
  final RxList<Device> assignedDevices = <Device>[].obs;
  final RxInt safeZonesCount = 0.obs;
  final RxInt policiesCount = 0.obs;
  final RxInt dailyUsageMinutes = 0.obs;

  final Rxn<BlockedFailure> deviceGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> removalGap = Rxn<BlockedFailure>();

  bool get canRemove => removalGap.value == null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<FamilyBundle?> bundle = await _repository.load();
    final BlockedFailure? devGap = _blocked(await _deviceGap());
    final BlockedFailure? remGap = _blocked(
      await _repository.unlinkChild(childUserId, execute: false),
    );
    if (isClosed) return;
    deviceGap.value = devGap;
    removalGap.value = remGap;

    await _loadSummaries(bundle.valueOrNull);

    final FamilyBundle? value = bundle.valueOrNull;
    if (value == null) {
      final HavenFailure? failure = bundle.failureOrNull;
      person.value = failure == null
          ? const Ok<FamilyPerson?>(null)
          : Err<FamilyPerson?>(failure);
      isLoading.value = false;
      return;
    }
    person.value = Ok<FamilyPerson?>(_find(value));
    isLoading.value = false;
  }

  Future<void> _loadSummaries(FamilyBundle? bundle) async {
    final Result<List<Map<String, Object?>>> devRows =
        await _rows().rows(TableName.devices, eq: {'child_user_id': childUserId});
    final List<Device> devs = (devRows.valueOrNull ?? []).map(Device.fromRow).toList();
    assignedDevices.assignAll(devs);

    if (bundle != null) {
      final String fid = bundle.family.id;
      final Result<int> zCount = await _rows().count(TableName.safeZones, eq: {'family_id': fid});
      safeZonesCount.value = zCount.valueOrNull ?? 0;
      final Result<int> pCount = await _rows().count(TableName.devicePolicies, eq: {'family_id': fid});
      policiesCount.value = pCount.valueOrNull ?? 0;
    }

    int mins = 0;
    for (final d in devs) {
      final Result<List<Map<String, Object?>>> uRows =
          await _rows().rows(TableName.usageDaily, eq: {'device_id': d.id});
      for (final r in uRows.valueOrNull ?? []) {
        mins += (r['duration_seconds'] as int? ?? 0) ~/ 60;
      }
    }
    dailyUsageMinutes.value = mins;
  }

  FamilyPerson? _find(FamilyBundle bundle) {
    for (final FamilyPerson child in bundle.children) {
      if (child.userId == childUserId) return child;
    }
    return null;
  }

  Future<bool> removeChild() async {
    isRemoving.value = true;
    final Result<void> result = await _repository.unlinkChild(childUserId, execute: true);
    if (isClosed) return false;
    isRemoving.value = false;
    if (result.isOk) {
      goToFamily();
      return true;
    }
    return false;
  }

  Future<bool> updateProfile({required String name, String? ageBracket, String? avatar}) async {
    final Result<void> result = await _repository.updateChild(
      childUserId: childUserId,
      name: name,
      ageBracket: ageBracket,
      avatar: avatar,
    );
    if (result.isOk) {
      await load();
      return true;
    }
    return false;
  }

  void goToFamily() => _goTo(AppRoutes.family, null);
  void goToDevice(String deviceId) =>
      _push(AppRoutes.deviceDetail, DeviceRouteArgs(deviceId: deviceId));
  void goToPolicies() => _push(AppRoutes.policies, null);
  void goToSafeZones() => _push(AppRoutes.safeZones, null);

  Future<Result<void>> _deviceGap() async =>
      CapturedGaps.deviceLaneUnavailable(subject: "this child's");

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
