import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/account_repository.dart';

/// The parent's own account: who is signed in, the name Haven shows, and the
/// way out.
///
/// Nothing here guesses. A missing `profiles` row is shown as "not set up yet"
/// with a route into setup, and each ability the backend has no contract for is
/// read from the repository rather than hard-coded into the page.
final class AccountController extends GetxController {
  AccountController({
    required this._repository,
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final AccountRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final RxBool isLoading = true.obs;
  final Rx<Result<AccountInfo>?> account = Rx<Result<AccountInfo>?>(null);
  final RxBool busy = false.obs;
  final RxnString message = RxnString();

  final TextEditingController displayName = TextEditingController();

  /// What the repository says about the three abilities it cannot perform.
  final Rxn<BlockedFailure> passwordChange = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> emailChange = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> accountDeletion = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    displayName.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<AccountInfo> result = await _repository.load();
    passwordChange.value = _blocked(await _repository.passwordChange());
    emailChange.value = _blocked(await _repository.emailChange());
    accountDeletion.value = _blocked(await _repository.accountDeletion());
    if (isClosed) return;
    account.value = result;
    final AccountInfo? info = result.valueOrNull;
    if (info?.hasProfile ?? false) {
      displayName.text = info!.profile!.displayName;
    }
    isLoading.value = false;
  }

  bool get canSave =>
      !busy.value && (account.value?.valueOrNull?.hasProfile ?? false);

  /// Writes the name Haven shows everywhere. The row has to exist first —
  /// there is no approved way for the app to create it.
  Future<void> save() async {
    if (!canSave) return;
    message.value = null;
    busy.value = true;
    final HavenFailure? failure = (await _repository.rename(
      displayName: displayName.text,
    )).failureOrNull;
    if (isClosed) return;
    busy.value = false;
    if (failure == null) {
      await load();
      return;
    }
    message.value = failure.message;
  }

  /// Ends the session, then says so. `SessionWatch` would also notice, but the
  /// parent asked for this and should land somewhere that explains it.
  Future<void> signOut() async {
    if (busy.value) return;
    busy.value = true;
    final HavenFailure? failure = (await _repository.signOut()).failureOrNull;
    if (isClosed) return;
    busy.value = false;
    if (failure != null) {
      message.value = failure.message;
      return;
    }
    _goTo(AppRoutes.sessionEnded, 'You are signed out of Haven.');
  }

  void goToSetup() => _goTo(AppRoutes.onboarding, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
