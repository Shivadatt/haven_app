import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/zones_models.dart';
import '../data/zones_repository.dart';

/// The list of places the family named.
///
/// Two boundaries are read here rather than discovered by the parent: a new place
/// cannot be added (the table has an INSERT policy but no INSERT grant), and no
/// screen can say whether a device is inside one (the state table is deny-all).
final class SafeZonesController extends GetxController {
  SafeZonesController({
    required SafeZonesRepository repository,
    void Function(String route, Object? arg)? push,
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
        _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg)),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final SafeZonesRepository _repository;
  final void Function(String route, Object? arg) _push;
  final void Function(String route, Object? arg) _replace;

  final RxBool isLoading = true.obs;
  final Rx<Result<ZoneBoard?>?> board = Rx<Result<ZoneBoard?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<ZoneBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  Future<void> reload() async {
    final Result<ZoneBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
  }

  /// Editing an existing place is one of the few writes this build can actually
  /// make, so the control leads somewhere real.
  void goToEditor(String zoneId) => _push(AppRoutes.safeZoneEditor, zoneId);

  /// Creating a new safe place (available in offline mode).
  void goToCreate() => _push(AppRoutes.safeZoneCreate, null);

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
