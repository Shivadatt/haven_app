import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/sessions_models.dart';
import '../data/sessions_repository.dart';

/// The session list, re-read when the backend says something moved.
///
/// `remote_sessions` is one of the four tables Realtime is live on, and the feed
/// is a hint, never the row: an event only means "read this again"
/// (`docs/stage1/02-architecture.md:23`), so a missed event costs a stale screen
/// rather than a lost fact.
final class SessionsController extends GetxController {
  SessionsController({
    required this._repository,
    this._feed,
    void Function(String route, Object? arg)? replace,
    void Function(String route, Object? arg)? push,
  }) : _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg)),
       _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final SessionsRepository _repository;

  /// Null means no live hint is watched and the screen reads on entry and on pull.
  final ChangeFeed Function()? _feed;
  final void Function(String route, Object? arg) _replace;
  final void Function(String route, Object? arg) _push;

  final RxBool isLoading = true.obs;
  final Rx<Result<SessionBoard?>?> board = Rx<Result<SessionBoard?>?>(null);

  StreamSubscription<Map<String, Object?>>? _watch;

  @override
  void onInit() {
    super.onInit();
    load();
    _watchSessionRows();
  }

  /// The feed is a shared singleton, so this cancels its own subscription rather
  /// than disposing the channels another open screen is watching.
  @override
  void onClose() {
    _watch?.cancel();
    _watch = null;
    super.onClose();
  }

  void _watchSessionRows() {
    final ChangeFeed Function()? feed = _feed;
    if (feed == null) return;
    _watch = feed()
        .changes(table: TableName.remoteSessions)
        .listen(
          (Map<String, Object?> _) {
            if (!isClosed) load();
          },
          onError: (Object _) {
            // A dropped channel is a stale screen, not a broken one: the pull and the
            // first read both still work, so nothing here retries the socket.
          },
        );
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<SessionBoard?> read = await _repository.load();
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    board.value = await _repository.load();
  }

  void openDetail(String sessionId) =>
      _push(AppRoutes.remoteSessionDetail, sessionId);

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
