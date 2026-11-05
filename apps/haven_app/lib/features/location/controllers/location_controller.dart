import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/location_models.dart';
import '../data/location_repository.dart';

/// The places this family may read, and the two questions this build cannot
/// answer about them.
///
/// Coordinates stay hidden until the parent asks for them: the row is readable,
/// but printing a child's position on a screen that is on in a room full of
/// people is a choice Haven does not make for them.
final class LocationController extends GetxController {
  LocationController({
    required LocationRepository repository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
        _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final LocationRepository _repository;
  final void Function(String route, Object? arg) _replace;

  /// The route argument this screen was opened with. Empty means the family.
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<FixBoard?>?> board = Rx<Result<FixBoard?>?>(null);
  final RxBool showsCoordinates = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<FixBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// Pull-to-refresh keeps the rows on the page while the re-read happens.
  Future<void> reload() async {
    final Result<FixBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
  }

  /// The reveal is the parent's choice and survives a refresh: resetting it on
  /// every pull would take back information they had already asked to see.
  void toggleCoordinates() => showsCoordinates.value = !showsCoordinates.value;

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
