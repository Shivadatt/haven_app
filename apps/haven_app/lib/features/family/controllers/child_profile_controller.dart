import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/captured_gaps.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

/// One child, as far as a parent may change them.
final class ChildProfileController extends GetxController {
  ChildProfileController({
    required this.childUserId,
    required FamilyRepository repository,
    void Function(String route, Object? arg)? goTo,
  }) : _repository = repository,
        _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final String childUserId;
  final FamilyRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final RxBool isLoading = true.obs;
  final Rx<Result<FamilyPerson?>?> person = Rx<Result<FamilyPerson?>?>(null);
  final RxBool isRemoving = false.obs;

  /// The device half of a child's page, which this build cannot answer in cloud mode.
  final Rxn<BlockedFailure> deviceGap = Rxn<BlockedFailure>();

  /// Removing a child is refused in cloud mode (#5), but supported locally.
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

  FamilyPerson? _find(FamilyBundle bundle) {
    for (final FamilyPerson child in bundle.children) {
      if (child.userId == childUserId) return child;
    }
    return null;
  }

  Future<bool> removeChild() async {
    isRemoving.value = true;
    final Result<void> result = await _repository.unlinkChild(
      childUserId,
      execute: true,
    );
    if (isClosed) return false;
    isRemoving.value = false;
    if (result.isOk) {
      goToFamily();
      return true;
    }
    return false;
  }

  Future<bool> updateProfile({
    required String name,
    String? ageBracket,
    String? avatar,
  }) async {
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

  Future<Result<void>> _deviceGap() async =>
      CapturedGaps.deviceLaneUnavailable(subject: "this child's");

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
