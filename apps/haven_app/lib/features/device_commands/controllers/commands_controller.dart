import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/commands_models.dart';
import '../data/commands_repository.dart';

/// The instructions written for this family, and the write lane that is closed.
///
/// The screen is a log, not a control panel: refreshing re-reads the rows, and the
/// refusal to send anything is part of what is displayed rather than something a
/// button discovers when it is pressed.
final class CommandsController extends GetxController {
  CommandsController({
    required this._repository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final CommandsRepository _repository;
  final void Function(String route, Object? arg) _replace;

  /// The route argument this screen was opened with. Empty means the family.
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<CommandBoard?>?> board = Rx<Result<CommandBoard?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<CommandBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// A pull re-reads. `device_commands` is one of the four tables Realtime is
  /// live on, but no screen claims a subscription here: the read lane for that
  /// has its own unanswered questions.
  @override
  Future<void> refresh() async {
    board.value = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
  }

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
