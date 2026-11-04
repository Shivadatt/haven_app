import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/session_detail_models.dart';
import '../data/sessions_repository.dart';
import '../services/media_peer.dart';

/// One session and the signalling rows around it.
///
/// The screen reads the lifecycle. It does not act on it: no session can be
/// started from here, and the peer that would carry sound or picture is the
/// interface in `services/media_peer.dart`, whose only implementation refuses.
final class SessionDetailController extends GetxController {
  SessionDetailController({
    required this._repository,
    required this.sessionId,
    SessionMediaPeer? peer,
    this._feed,
    void Function(String route, Object? arg)? replace,
  }) : _peer = peer ?? const UnspecifiedMediaPeer(),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final SessionsRepository _repository;
  final SessionMediaPeer _peer;
  final void Function(String route, Object? arg) _replace;

  /// The route argument (`docs/implementation/00-app-contract.md:166`).
  final String sessionId;

  final ChangeFeed Function()? _feed;
  StreamSubscription<Map<String, Object?>>? _watch;

  final RxBool isLoading = true.obs;
  final Rx<Result<SessionDetail?>?> detail = Rx<Result<SessionDetail?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
    _watchBuffer();
  }

  @override
  void onClose() {
    _watch?.cancel();
    _watch = null;
    super.onClose();
  }

  /// Both tables the screen reads are Realtime-published, so a change to the
  /// session row or to its buffer is a reason to re-read rather than to assume.
  void _watchBuffer() {
    final ChangeFeed Function()? feed = _feed;
    if (feed == null || sessionId.isEmpty) return;
    final ChangeFeed source = feed();
    _watch = source
        .changes(
          table: TableName.webrtcSignals,
          eq: <String, Object?>{'session_id': sessionId},
        )
        .listen((Map<String, Object?> _) {
          if (!isClosed) load();
        });
  }

  Future<void> load() async {
    if (sessionId.isEmpty) {
      // A route opened without a session id has nothing to read; the id is not
      // guessed from the last row on the list.
      detail.value = const Err<SessionDetail?>(
        ValidationFailure('No session was named.', field: 'session'),
      );
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    final Result<SessionDetail?> read = await _repository.loadDetail(sessionId);
    if (isClosed) return;
    detail.value = read;
    isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    if (sessionId.isEmpty) return;
    detail.value = await _repository.loadDetail(sessionId);
  }

  /// False for the whole life of this build. The screen says so rather than
  /// leaving a player-shaped gap.
  bool get carriesMedia => _peer.isCarrying;

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
