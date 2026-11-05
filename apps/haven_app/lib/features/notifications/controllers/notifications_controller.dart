import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/alerts_models.dart';
import '../data/alerts_repository.dart';
import '../services/alert_delivery.dart';

/// The family's reports, re-read when the backend says something arrived.
///
/// `safety_alerts` is one of the four tables Realtime is live on, and the feed is
/// only a hint: an event says "read this again", it is never shown as the row
/// itself (`docs/stage1/02-architecture.md:23`). So a missed event costs a stale
/// screen rather than a lost fact, and a pull still works.
final class NotificationsController extends GetxController {
  NotificationsController({
    required AlertsRepository repository,
    AlertDelivery? delivery,
    ChangeFeed Function()? feed,
    void Function(String route, Object? arg)? replace,
    void Function(String route, Object? arg)? push,
  }) : _repository = repository,
       _feed = feed,
       _delivery = delivery ?? const UnregisteredAlertDelivery(),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg)),
       _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final AlertsRepository _repository;

  /// The typed seam the contract leaves for server-side registration
  /// (`00-app-contract.md:101-103`). It refuses, and the screen says so.
  final AlertDelivery _delivery;

  /// Null means no live hint is watched and the screen reads on entry and on pull.
  final ChangeFeed Function()? _feed;
  final void Function(String route, Object? arg) _replace;
  final void Function(String route, Object? arg) _push;

  final RxBool isLoading = true.obs;
  final Rx<Result<AlertBoard?>?> board = Rx<Result<AlertBoard?>?>(null);

  StreamSubscription<Map<String, Object?>>? _watch;

  @override
  void onInit() {
    super.onInit();
    load();
    _watchAlerts();
  }

  /// The feed is a shared singleton, so this drops its own subscription rather
  /// than disposing channels another open screen is watching.
  @override
  void onClose() {
    _watch?.cancel();
    _watch = null;
    super.onClose();
  }

  void _watchAlerts() {
    final ChangeFeed Function()? feed = _feed;
    if (feed == null) return;
    _watch = feed().changes(table: TableName.safetyAlerts).listen((
      Map<String, Object?> _,
    ) {
      if (!isClosed) load();
    });
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<AlertBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  Future<void> reload() async {
    final Result<AlertBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
  }

  final RxString selectedCategory = 'all'.obs;

  void selectCategory(String cat) => selectedCategory.value = cat;

  List<AlertLine> get filteredLines {
    final lines = board.value?.valueOrNull?.lines ?? const <AlertLine>[];
    final cat = selectedCategory.value;
    if (cat == 'all') return lines;
    if (cat == 'geofence') {
      return lines
          .where((l) => l.alert.type?.contains('geofence') ?? false)
          .toList();
    }
    if (cat == 'battery') {
      return lines
          .where((l) => l.alert.type?.contains('battery') ?? false)
          .toList();
    }
    return lines
        .where((l) =>
            !(l.alert.type?.contains('geofence') ?? false) &&
            !(l.alert.type?.contains('battery') ?? false))
        .toList();
  }

  Future<void> markAsRead(String alertId) async {
    final res = await _repository.markAsRead(alertId);
    if (isClosed || res.isErr) return;
    await reload();
  }

  Future<void> markAsUnread(String alertId) async {
    final res = await _repository.markAsUnread(alertId);
    if (isClosed || res.isErr) return;
    await reload();
  }

  Future<void> toggleRead(AlertLine line) async {
    if (line.isRead) {
      await markAsUnread(line.alert.id);
    } else {
      await markAsRead(line.alert.id);
    }
  }

  Future<void> deleteAlert(String alertId) async {
    final res = await _repository.deleteAlert(alertId);
    if (isClosed || res.isErr) return;
    await reload();
  }

  /// False for the whole life of this build: the list is read, not delivered.
  bool get deviceIsRegistered => _delivery.isRegistered;

  /// Notification permission belongs to the settings screen, which already owns
  /// that question; this opens it rather than asking the operating system twice.
  void goToSettings() => _push(AppRoutes.settings, null);

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
