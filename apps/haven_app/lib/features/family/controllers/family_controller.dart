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

  /// The child whose removal is being confirmed, so a page can name them in the
  /// question without holding a second copy of the list.
  final RxnString removing = RxnString();

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

  /// Unlinking is the one membership edit with a captured contract. It is
  /// reversible only by pairing again, so the page asks first; this method is
  /// what runs after the parent says yes.
  Future<void> unlinkChild(String childUserId) async {
    if (busy.value) return;
    message.value = null;
    busy.value = true;
    final HavenFailure? failure = (await _repository.unlinkChild(
      childUserId,
    )).failureOrNull;
    if (isClosed) return;
    busy.value = false;
    removing.value = null;
    if (failure != null) {
      message.value = failure.message;
      return;
    }
    await load();
  }

  void askToRemove(String childUserId) => removing.value = childUserId;

  void cancelRemoval() => removing.value = null;

  void goToChild(String childUserId) =>
      _push(AppRoutes.childProfile, childUserId);

  void goToSetup() => _replace(AppRoutes.onboarding, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
