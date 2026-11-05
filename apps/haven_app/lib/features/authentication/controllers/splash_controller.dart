import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';

/// Where the first screen ended up.
enum SplashStage { connecting, stalled, away }

/// Decides the first route from what the build can actually reach.
///
/// There is no optimistic navigation: a session is asked for, a profile is
/// looked up, and only then does the app move. If the backend cannot sign anyone
/// in — the state of this repository while the staging approvals are unsigned —
/// the screen says so and stays, rather than opening an empty dashboard.
final class SplashController extends GetxController {
  SplashController({
    required Future<HavenBackendHandle> Function() connect,
    required UserAuth Function() auth,
    required ProfileStore Function() profiles,
    void Function(String route)? goTo,
  }) : _connect = connect,
       _auth = auth,
       _profiles = profiles,
       _goTo = goTo ?? Get.offAllNamed;

  /// The seams are read *after* [HavenBackendHandle] resolves, so they are held
  /// as providers: `install()` replaces the unconfigured clients, and a value
  /// captured at construction would be the pre-install one.
  final Future<HavenBackendHandle> Function() _connect;
  final UserAuth Function() _auth;
  final ProfileStore Function() _profiles;
  final void Function(String route) _goTo;

  final Rx<SplashStage> stage = SplashStage.connecting.obs;
  final RxnString note = RxnString();

  /// Set once, from a failure the parent can act on.
  String? get message => note.value;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  Future<void> start() async {
    stage.value = SplashStage.connecting;
    final HavenBackendHandle handle = await _connect();

    if (!handle.status.canSignIn) {
      _hold(handle.status.message);
      return;
    }

    final Result<AuthSession?> session = await _auth().currentSession();
    final HavenFailure? authFailure = session.failureOrNull;
    if (authFailure != null) {
      _hold(authFailure.message);
      return;
    }

    final AuthSession? signedIn = session.valueOrNull;
    if (signedIn == null) {
      stage.value = SplashStage.away;
      _goTo(AppRoutes.signIn);
      return;
    }

    final Result<Map<String, Object?>?> profile = await _profiles().load(
      signedIn.userId,
    );
    final HavenFailure? profileFailure = profile.failureOrNull;
    if (profileFailure != null) {
      _hold(profileFailure.message);
      return;
    }

    // `profiles.load` returning no row is the documented provisioning gap, not a
    // failure: the account exists and has nothing set up yet.
    stage.value = SplashStage.away;
    _goTo(
      profile.valueOrNull == null ? AppRoutes.onboarding : AppRoutes.dashboard,
    );
  }

  void _hold(String reason) {
    stage.value = SplashStage.stalled;
    note.value = reason;
  }
}
