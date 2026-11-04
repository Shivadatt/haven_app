import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/pairing_models.dart';
import '../data/pairing_repository.dart';

/// The screen that would start a pairing, if this build could start one.
///
/// It carries the family id the route was opened with and re-reads the board
/// rather than trusting it: a jump from another account's pairing screen would
/// otherwise offer to pair into the wrong family, and the only honest defence is
/// to check the id against the one the backend resolved for this session.
final class PairingCodeController extends GetxController {
  PairingCodeController({
    required this.familyId,
    required this._repository,
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final String familyId;
  final PairingRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final RxBool isLoading = true.obs;
  final Rx<Result<PairingBoard?>?> board = Rx<Result<PairingBoard?>?>(null);

  final Rxn<BlockedFailure> inviteGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> codeGap = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<PairingBoard?> read = await _repository.load();
    inviteGap.value = _blocked(await _repository.createInvite());
    codeGap.value = _blocked(await _repository.redeemCode());
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// True when the family this screen was opened for is not the family the
  /// session belongs to. Only judged once a board has actually been read.
  bool get isForAnotherFamily {
    final PairingBoard? read = board.value?.valueOrNull;
    return read != null && read.familyId != familyId;
  }

  String get familyName =>
      board.value?.valueOrNull?.familyName ?? 'your family';

  void goToPairing() => _goTo(AppRoutes.pairing, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
