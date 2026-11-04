import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/captured_gaps.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

/// One child, as far as a parent may change them.
///
/// The read is the family bundle filtered to this child: there is no captured
/// "give me one member" contract, and inventing a narrower query would be
/// inventing a backend. Everything the screen cannot do is the repository's own
/// refusal, read back verbatim.
final class ChildProfileController extends GetxController {
  ChildProfileController({
    required this.childUserId,
    required this._repository,
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final String childUserId;
  final FamilyRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final RxBool isLoading = true.obs;
  final Rx<Result<FamilyPerson?>?> person = Rx<Result<FamilyPerson?>?>(null);

  /// The device half of a child's page, which this build cannot answer. See
  /// [CapturedGaps] for why, and for the words the screen shows.
  final Rxn<BlockedFailure> deviceGap = Rxn<BlockedFailure>();

  /// Removing a child is the one membership edit a parent would want here, and
  /// the only screen that can say why it cannot offer it is this one.
  final Rxn<BlockedFailure> removalGap = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<FamilyBundle?> bundle = await _repository.load();
    deviceGap.value = _blocked(await _deviceGap());
    removalGap.value = _blocked(await _repository.unlinkChild(childUserId));
    if (isClosed) return;
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

  void goToFamily() => _goTo(AppRoutes.family, null);

  /// Read from the one place the device gap is written down, so a parent reads
  /// the same sentence on the dashboard and on their child's page.
  Future<Result<void>> _deviceGap() async =>
      CapturedGaps.deviceLaneUnavailable(subject: "this child's");

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
