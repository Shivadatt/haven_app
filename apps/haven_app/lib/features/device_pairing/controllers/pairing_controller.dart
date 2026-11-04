import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/pairing_models.dart';
import '../data/pairing_repository.dart';

/// The pairing screen: the requests the family is allowed to see, and the three
/// things this build cannot do about them.
///
/// The gaps are read out of the repository rather than typed here, so a parent
/// reads the sentence the specification is missing, in the repository's words.
final class PairingController extends GetxController {
  PairingController({
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

  final PairingRepository _repository;
  final void Function(String route, Object? arg) _push;
  final void Function(String route, Object? arg) _replace;

  final RxBool isLoading = true.obs;
  final Rx<Result<PairingBoard?>?> board = Rx<Result<PairingBoard?>?>(null);

  final Rxn<BlockedFailure> inviteGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> codeGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> cancelGap = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<PairingBoard?> read = await _repository.load();
    await _readGaps(read);
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// Pull-to-refresh keeps whatever is already on the page while the re-read
  /// happens.
  @override
  Future<void> refresh() async {
    final Result<PairingBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
  }

  /// The refusals the screen has to state up front, so a parent never meets a
  /// button that can only fail. The withdrawal gap is only read for a request
  /// that is genuinely waiting on a child, because that is the only moment an id
  /// exists to withdraw.
  Future<void> _readGaps(Result<PairingBoard?> read) async {
    inviteGap.value = _blocked(await _repository.createInvite());
    codeGap.value = _blocked(await _repository.redeemCode());
    final PairingLine? waiting = read.valueOrNull?.firstWaiting;
    cancelGap.value = waiting == null
        ? null
        : _blocked(await _repository.cancel(waiting.request.id));
  }

  /// The route table fixes `familyId` as this screen's argument, so the family
  /// that was actually read is what travels with the jump.
  void goToCode() {
    final PairingBoard? value = board.value?.valueOrNull;
    if (value == null) return;
    _push(AppRoutes.pairingCode, value.familyId);
  }

  void goToSetup() => _replace(AppRoutes.onboarding, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
