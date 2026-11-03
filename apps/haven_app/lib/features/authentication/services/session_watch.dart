import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../../app/routes/app_routes.dart';
import '../data/auth_repository.dart';

/// Moves the app to `sessionEnded` when the session goes away on its own.
///
/// Supabase is the session authority, so its change stream is the only honest
/// source for "you are no longer signed in". Navigation is suppressed when the
/// app is already on a page that explains it, and `signedIn` or an unresolved
/// status is not something to announce.
final class SessionWatch extends GetxService {
  SessionWatch({
    required this._repository,
    void Function(String route, Object? arg)? onLost,
    String Function()? currentRoute,
  }) : _onLost =
           onLost ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg)),
       _currentRoute = currentRoute ?? _routeNow;

  static const _identity = [AppRoutes.signIn, AppRoutes.sessionEnded];

  final AuthRepository _repository;
  final void Function(String route, Object? arg) _onLost;
  final String Function() _currentRoute;

  StreamSubscription<AuthStateSnapshot>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.states.listen(_onSnapshot);
  }

  void _onSnapshot(AuthStateSnapshot snapshot) {
    final String? reason = switch (snapshot.kind) {
      AuthStatusKind.expired => 'Your sign-in expired.',
      AuthStatusKind.signedOut => 'You are signed out.',
      AuthStatusKind.profileMissing =>
        'This account has no profile yet, so there is nothing to show.',
      AuthStatusKind.unknown || AuthStatusKind.signedIn => null,
    };
    if (reason == null) return;
    if (_identity.contains(_currentRoute())) return;
    _onLost(AppRoutes.sessionEnded, reason);
  }

  static String _routeNow() => Get.currentRoute;

  @override
  void onClose() {
    _sub?.cancel();
    _sub = null;
    super.onClose();
  }
}
