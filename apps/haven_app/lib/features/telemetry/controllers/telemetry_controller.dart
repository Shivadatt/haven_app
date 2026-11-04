import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../data/telemetry_models.dart';
import '../data/telemetry_repository.dart';

/// The family's trail, shown where a device is already named.
///
/// Telemetry has no route of its own in the fixed contract — the contract's page
/// table lists commands and policies and nothing else — so this controller is
/// mounted inside the device screen rather than becoming an invented screen. It
/// reads what the backend recorded and carries the two refusals with it.
final class TelemetryController extends GetxController {
  TelemetryController({required this._repository, this.deviceId = ''});

  final TelemetryRepository _repository;

  /// Empty means the whole family's trail.
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<TelemetryBoard?>?> board = Rx<Result<TelemetryBoard?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<TelemetryBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// A re-read keeps the card in place; the log is a snapshot, not a stream.
  @override
  Future<void> refresh() async {
    board.value = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
  }
}
