import 'package:get/get.dart';
import '../../features/approvals/bindings/approvals_bindings.dart';
import '../../features/approvals/views/pages/app_approvals_page.dart';
import '../../features/approvals/views/pages/extension_requests_page.dart';
import '../../features/authentication/bindings/forgot_password_bindings.dart';
import '../../features/authentication/bindings/reset_password_bindings.dart';
import '../../features/authentication/bindings/verify_email_bindings.dart';
import '../../features/authentication/views/pages/forgot_password_page.dart';
import '../../features/authentication/views/pages/reset_password_page.dart';
import '../../features/authentication/views/pages/verify_email_page.dart';
import '../../features/family/bindings/child_create_bindings.dart';
import '../../features/family/bindings/family_invite_bindings.dart';
import '../../features/family/views/pages/child_create_page.dart';
import '../../features/family/views/pages/family_invite_page.dart';
import '../../features/help/bindings/help_bindings.dart';
import '../../features/help/views/pages/contact_support_page.dart';
import '../../features/help/views/pages/faq_page.dart';
import '../../features/help/views/pages/help_center_page.dart';
import 'app_routes.dart';

final List<GetPage<dynamic>> phase2Pages = [
  GetPage(
    name: AppRoutes.forgotPassword,
    page: () => const ForgotPasswordPage(),
    binding: ForgotPasswordBindings(),
  ),
  GetPage(
    name: AppRoutes.resetPassword,
    page: () => const ResetPasswordPage(),
    binding: ResetPasswordBindings(),
  ),
  GetPage(
    name: AppRoutes.verifyEmail,
    page: () => const VerifyEmailPage(),
    binding: VerifyEmailBindings(),
  ),
  GetPage(
    name: AppRoutes.familyInvite,
    page: () => const FamilyInvitePage(),
    binding: FamilyInviteBindings(),
  ),
  GetPage(
    name: AppRoutes.childCreate,
    page: () => const ChildCreatePage(),
    binding: ChildCreateBindings(),
  ),
  GetPage(
    name: AppRoutes.appApprovals,
    page: () => const AppApprovalsPage(),
    binding: AppApprovalsBindings(),
  ),
  GetPage(
    name: AppRoutes.extensionRequests,
    page: () => const ExtensionRequestsPage(),
    binding: ExtensionRequestsBindings(),
  ),
  GetPage(
    name: AppRoutes.helpCenter,
    page: () => const HelpCenterPage(),
    binding: HelpCenterBindings(),
  ),
  GetPage(
    name: AppRoutes.faq,
    page: () => const FaqPage(),
    binding: FaqBindings(),
  ),
  GetPage(
    name: AppRoutes.contactSupport,
    page: () => const ContactSupportPage(),
    binding: ContactSupportBindings(),
  ),
];
