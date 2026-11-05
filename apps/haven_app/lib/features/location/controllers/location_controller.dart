import 'dart:ui';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../app/routes/app_routes.dart';
import '../../safe_zones/data/zones_models.dart';
import '../../safe_zones/data/zones_repository.dart';
import '../data/location_models.dart';
import '../data/location_repository.dart';

/// The places this family may read and their interactive map presentation.
final class LocationController extends GetxController {
  LocationController({
    required LocationRepository repository,
    SafeZonesRepository? safeZonesRepository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
       _safeZonesRepository = safeZonesRepository,
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final LocationRepository _repository;
  final SafeZonesRepository? _safeZonesRepository;
  final void Function(String route, Object? arg) _replace;
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<FixBoard?>?> board = Rx<Result<FixBoard?>?>(null);
  final RxBool showsCoordinates = false.obs;

  // Interactive map state
  final RxDouble zoom = 1.0.obs;
  final Rx<Offset> panOffset = Offset.zero.obs;
  final Rxn<SafeZone> selectedZone = Rxn<SafeZone>();
  final RxBool isChildSelected = false.obs;
  final RxInt selectedLineIndex = 0.obs;
  final RxList<SafeZone> safeZones = <SafeZone>[].obs;

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
    await _loadZones();
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  Future<void> reload() async {
    final Result<FixBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    await _loadZones();
    if (isClosed) return;
    board.value = read;
  }

  Future<void> _loadZones() async {
    SafeZonesRepository? zonesRepo = _safeZonesRepository;
    if (zonesRepo == null && Get.isRegistered<SafeZonesRepository>()) {
      zonesRepo = Get.find<SafeZonesRepository>();
    }
    if (zonesRepo != null) {
      final res = await zonesRepo.load();
      final ZoneBoard? zb = res.valueOrNull;
      if (zb != null) {
        safeZones.assignAll(zb.zones);
      }
    }
  }

  void toggleCoordinates() => showsCoordinates.value = !showsCoordinates.value;
  void goToSetup() => _replace(AppRoutes.onboarding, null);

  void recenter() {
    zoom.value = 1.0;
    panOffset.value = Offset.zero;
    selectedZone.value = null;
    isChildSelected.value = false;
  }

  void zoomIn() => zoom.value = (zoom.value + 0.25).clamp(0.5, 4.0);
  void zoomOut() => zoom.value = (zoom.value - 0.25).clamp(0.5, 4.0);
  void updatePan(Offset delta) => panOffset.value += delta;
  void selectZone(SafeZone? zone) => selectedZone.value = zone;
  void selectChild(bool selected) => isChildSelected.value = selected;
  void selectLine(int index) => selectedLineIndex.value = index;

  FixLine? get activeLine {
    final lines = board.value?.valueOrNull?.lines ?? const [];
    if (lines.isEmpty) return null;
    final idx = selectedLineIndex.value;
    return (idx >= 0 && idx < lines.length) ? lines[idx] : lines.first;
  }

  bool get isDemoCoordinate {
    final line = activeLine;
    if (line == null) return false;
    final src = line.fix.source.toLowerCase();
    return src.contains('demo') || src.contains('mock') || src.contains('synthetic');
  }

  bool get isManualCoordinate {
    final line = activeLine;
    if (line == null) return false;
    final src = line.fix.source.toLowerCase();
    return src.contains('manual');
  }

  double? distanceToZone(SafeZone zone) {
    final line = activeLine;
    if (line == null) return null;
    return haversineMeters(
      lat1: line.fix.lat,
      lon1: line.fix.lng,
      lat2: zone.lat,
      lon2: zone.lng,
    );
  }

  bool isInsideZone(SafeZone zone) {
    final dist = distanceToZone(zone);
    if (dist == null) return false;
    return dist <= zone.radiusM;
  }
}
