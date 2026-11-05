import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';

/// Controller for the email verification explanation screen.
///
/// Offline-first: Explains clearly that email verification tokens require
/// a future cloud backend and that the resend action does not dispatch emails.
final class VerifyEmailController extends GetxController {
  VerifyEmailController({
    UserAuth Function()? auth,
    void Function(String route, Object? arg)? goTo,
  }) : _auth = auth ?? (() => HavenBackend.auth),
       _goTo = goTo ?? ((String route, Object? arg) => Get.offAllNamed(route, arguments: arg));

  final UserAuth Function() _auth;
  final void Function(String route, Object? arg) _goTo;

  final RxnString userEmail = RxnString();
  final RxString userRole = 'parent'.obs;
  final RxString accountStatus = 'Local / Unverified in Cloud'.obs;
  final RxnString resendFeedback = RxnString();
  final RxBool busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccount();
  }

  Future<void> loadAccount() async {
    final Result<AuthSession?> sessionRes = await _auth().currentSession();
    final AuthSession? session = sessionRes.valueOrNull;
    if (session != null) {
      userEmail.value = session.email;
      userRole.value = session.role ?? 'parent';
    } else if (Get.arguments is String) {
      userEmail.value = Get.arguments as String;
    }
  }

  Future<void> resendVerification() async {
    busy.value = true;
    resendFeedback.value = null;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    busy.value = false;
    resendFeedback.value =
        'Notice: Haven operates in offline-first mode without an SMTP provider. '
        'No email was dispatched. Real email verification will be connected in '
        'a future cloud backend release.';
  }

  void continueToDashboard() => _goTo(AppRoutes.dashboard, null);
  void goToSignIn() => _goTo(AppRoutes.signIn, null);
}
