import 'package:get/get.dart';

import '../../features/device/bindings/device_bindings.dart';
import '../../features/device/views/pages/device_page.dart';
import '../../features/onboarding/bindings/onboarding_bindings.dart';
import '../../features/onboarding/views/pages/onboarding_page.dart';
import '../../features/permissions/bindings/permissions_bindings.dart';
import '../../features/permissions/views/pages/permissions_page.dart';
import '../../features/profile/bindings/profile_bindings.dart';
import '../../features/profile/views/pages/profile_page.dart';
import '../../features/splash/bindings/splash_bindings.dart';
import '../../features/splash/views/pages/splash_page.dart';
import 'child_routes.dart';
import 'unknown_page.dart';

/// The child route table (Phase 3 Stage 1). Route names are fixed — later
/// stages add entries (pairing, usage, policy, location), never rename.
///
/// A route not listed here lands on [unknown], which says the screen is not
/// built yet — the honest answer, same precedent as the parent's `AppPages`.
abstract final class ChildPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(
      name: ChildRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBindings(),
    ),
    GetPage(
      name: ChildRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBindings(),
    ),
    GetPage(
      name: ChildRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBindings(),
    ),
    GetPage(
      name: ChildRoutes.device,
      page: () => const DevicePage(),
      binding: DeviceBindings(),
    ),
    GetPage(
      name: ChildRoutes.permissions,
      page: () => const PermissionsPage(),
      binding: PermissionsBindings(),
    ),
  ];

  static GetPage<dynamic> get unknown =>
      GetPage(name: ChildRoutes.unknown, page: () => const UnknownPage());
}
