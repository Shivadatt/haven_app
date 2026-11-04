import 'package:get/get.dart';

import '../../features/account/bindings/account_bindings.dart';
import '../../features/account/views/pages/account_page.dart';
import '../../features/authentication/bindings/auth_bindings.dart';
import '../../features/authentication/bindings/splash_bindings.dart';
import '../../features/authentication/views/pages/register_page.dart';
import '../../features/authentication/views/pages/session_ended_page.dart';
import '../../features/authentication/views/pages/sign_in_page.dart';
import '../../features/authentication/views/pages/splash_page.dart';
import '../../features/child_devices/bindings/child_devices_bindings.dart';
import '../../features/child_devices/views/pages/device_detail_page.dart';
import '../../features/child_devices/views/pages/devices_page.dart';
import '../../features/dashboard/bindings/dashboard_bindings.dart';
import '../../features/dashboard/views/pages/dashboard_page.dart';
import '../../features/dashboard/views/pages/not_found_page.dart';
import '../../features/device_activity/bindings/activity_bindings.dart';
import '../../features/device_activity/views/pages/activity_page.dart';
import '../../features/device_commands/bindings/commands_bindings.dart';
import '../../features/device_commands/views/pages/commands_page.dart';
import '../../features/device_pairing/bindings/device_pairing_bindings.dart';
import '../../features/device_pairing/views/pages/pairing_code_page.dart';
import '../../features/device_pairing/views/pages/pairing_page.dart';
import '../../features/family/bindings/family_bindings.dart';
import '../../features/family/views/pages/child_profile_page.dart';
import '../../features/family/views/pages/family_page.dart';
import '../../features/location/bindings/location_bindings.dart';
import '../../features/location/views/pages/location_page.dart';
import '../../features/notifications/bindings/notifications_bindings.dart';
import '../../features/notifications/views/pages/notifications_page.dart';
import '../../features/onboarding/bindings/onboarding_bindings.dart';
import '../../features/onboarding/views/pages/onboarding_page.dart';
import '../../features/policies/bindings/policies_bindings.dart';
import '../../features/policies/views/pages/policies_page.dart';
import '../../features/remote_sessions/bindings/sessions_bindings.dart';
import '../../features/remote_sessions/views/pages/remote_session_detail_page.dart';
import '../../features/remote_sessions/views/pages/remote_sessions_page.dart';
import '../../features/safe_zones/bindings/zones_bindings.dart';
import '../../features/safe_zones/views/pages/safe_zone_editor_page.dart';
import '../../features/safe_zones/views/pages/safe_zones_page.dart';
import '../../features/settings/bindings/settings_bindings.dart';
import '../../features/settings/views/pages/about_page.dart';
import '../../features/settings/views/pages/permission_status_page.dart';
import '../../features/settings/views/pages/settings_page.dart';
import 'app_routes.dart';

/// The route table. `AppRoutes` fixes the names; this list only grows once a
/// page and its bindings exist.
///
/// A route that is not here is not broken — `unknownRoute` sends it to
/// `NotFoundPage`, which says the screen is not built yet instead of showing a
/// half-blank page or an invented one.
abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBindings(),
    ),
    GetPage(
      name: AppRoutes.signIn,
      page: () => const SignInPage(),
      binding: SignInBindings(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBindings(),
    ),
    GetPage(
      name: AppRoutes.sessionEnded,
      page: () => const SessionEndedPage(),
      binding: SessionEndedBindings(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBindings(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBindings(),
    ),
    GetPage(
      name: AppRoutes.family,
      page: () => const FamilyPage(),
      binding: FamilyBindings(),
    ),
    GetPage(
      name: AppRoutes.childProfile,
      page: () => const ChildProfilePage(),
      binding: ChildProfileBindings(),
    ),
    GetPage(
      name: AppRoutes.pairing,
      page: () => const PairingPage(),
      binding: PairingBindings(),
    ),
    GetPage(
      name: AppRoutes.pairingCode,
      page: () => const PairingCodePage(),
      binding: PairingCodeBindings(),
    ),
    GetPage(
      name: AppRoutes.devices,
      page: () => const DevicesPage(),
      binding: DevicesBindings(),
    ),
    GetPage(
      name: AppRoutes.deviceDetail,
      page: () => const DeviceDetailPage(),
      binding: DeviceDetailBindings(),
    ),
    GetPage(
      name: AppRoutes.activity,
      page: () => const ActivityPage(),
      binding: ActivityBindings(),
    ),
    GetPage(
      name: AppRoutes.commands,
      page: () => const CommandsPage(),
      binding: CommandsBindings(),
    ),
    GetPage(
      name: AppRoutes.policies,
      page: () => const PoliciesPage(),
      binding: PoliciesBindings(),
    ),
    GetPage(
      name: AppRoutes.location,
      page: () => const LocationPage(),
      binding: LocationBindings(),
    ),
    GetPage(
      name: AppRoutes.safeZones,
      page: () => const SafeZonesPage(),
      binding: SafeZonesBindings(),
    ),
    GetPage(
      name: AppRoutes.safeZoneEditor,
      page: () => const SafeZoneEditorPage(),
      binding: ZoneEditorBindings(),
    ),
    GetPage(
      name: AppRoutes.remoteSessions,
      page: () => const RemoteSessionsPage(),
      binding: SessionsBindings(),
    ),
    GetPage(
      name: AppRoutes.remoteSessionDetail,
      page: () => const RemoteSessionDetailPage(),
      binding: SessionDetailBindings(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBindings(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountPage(),
      binding: AccountBindings(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBindings(),
    ),
    GetPage(
      name: AppRoutes.permissionStatus,
      page: () => const PermissionStatusPage(),
      binding: PermissionStatusBindings(),
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutPage(),
      binding: AboutBindings(),
    ),
  ];

  static GetPage<dynamic> get unknown =>
      GetPage(name: AppRoutes.unknown, page: () => const NotFoundPage());
}
