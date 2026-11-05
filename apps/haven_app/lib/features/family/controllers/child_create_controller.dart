import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/child_profile_constants.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

/// Controller for standalone child profile creation.
final class ChildCreateController extends GetxController {
  ChildCreateController({
    required FamilyRepository repository,
    void Function(String route, Object? arg)? goTo,
  }) : _repository = repository,
       _goTo = goTo ?? ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final FamilyRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final TextEditingController nameController = TextEditingController();
  final RxString selectedAgeBracket = ChildProfileConstants.ageBrackets.first.obs;
  final RxString selectedAvatar = ChildProfileConstants.avatars.first.obs;
  final RxnString nameError = RxnString();
  final RxnString formError = RxnString();
  final RxBool busy = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  bool _validate() {
    final String? err = ChildProfileConstants.validateName(nameController.text);
    nameError.value = err;
    return err == null;
  }

  Future<bool> createChild() async {
    if (busy.value) return false;
    formError.value = null;
    if (!_validate()) return false;

    busy.value = true;
    final Result<FamilyPerson> result = await _repository.addChild(
      name: nameController.text.trim(),
      ageBracket: selectedAgeBracket.value,
      avatar: selectedAvatar.value,
    );
    busy.value = false;

    if (result.isOk) {
      final FamilyPerson child = result.valueOrNull!;
      _goTo(AppRoutes.childProfile, child.userId);
      return true;
    }

    formError.value = result.failureOrNull?.message ?? 'Failed to create child profile.';
    return false;
  }
}
