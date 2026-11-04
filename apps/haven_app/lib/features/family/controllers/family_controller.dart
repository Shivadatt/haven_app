import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

/// The family screen: who is in it, what the family is called, and the one
/// membership change the backend actually accepts.
///
/// The two gaps are read out of the repository instead of typed into the page, so
/// the words a parent sees are the words the contract is missing.
final class FamilyController extends GetxController {
  FamilyController({
    required this._repository,
    void Function(String route, Object? arg)? push,
    void Function(String route, Object? arg)? replace,
  }) : _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg)),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final FamilyRepository _repository;
  final void Function(String route, Object? arg) _push;
  final void Function(String route, Object? arg) _replace;

  final RxBool isLoading = true.obs;
  final Rx<Result<FamilyBundle?>?> family = Rx<Result<FamilyBundle?>?>(null);
  final RxBool busy = false.obs;
  final RxnString message = RxnString();

  final TextEditingController familyName = TextEditingController();

  final Rxn<BlockedFailure> inviteParent = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> removeParent = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    familyName.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<FamilyBundle?> result = await _repository.load();
    inviteParent.value = _blocked(await _repository.inviteParent());
    removeParent.value = _blocked(await _repository.removeParent());
    if (isClosed) return;
    family.value = result;
    final FamilyBundle? bundle = result.valueOrNull;
    if (bundle != null) familyName.text = bundle.family.name;
    isLoading.value = false;
  }

  bool get canSave => !busy.value && family.value?.valueOrNull != null;

  Future<void> save() async {
    if (!canSave) return;
    message.value = null;
    busy.value = true;
    final HavenFailure? failure = (await _repository.rename(
      name: familyName.text,
    )).failureOrNull;
    if (isClosed) return;
    busy.value = false;
    if (failure == null) {
      await load();
      return;
    }
    message.value = failure.message;
  }

  /// Removal lives on a child's own page, where the parent can see who they are
  /// about to unlink.
  void goToChild(String childUserId) =>
      _push(AppRoutes.childProfile, childUserId);

  void goToSetup() => _replace(AppRoutes.onboarding, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
