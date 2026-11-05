/// Every route the app can name. The paths are fixed by
/// `docs/implementation/00-app-contract.md`; feature code navigates with these
/// constants and never with a string literal.
///
/// A route only appears in `AppPages.pages` once its page exists. Jumping to an
/// unlisted name lands on `unknown`, which is the honest answer: the screen was
/// specified, not built.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String register = '/register';
  static const String sessionEnded = '/session-ended';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String family = '/family';
  static const String childProfile = '/family/child';
  static const String pairing = '/pairing';
  static const String pairingCode = '/pairing/code';
  static const String pairingSimulation = '/pairing/simulation';
  static const String devices = '/devices';
  static const String deviceDetail = '/devices/detail';
  static const String activity = '/devices/activity';
  static const String commands = '/devices/commands';
  static const String policies = '/devices/policies';
  static const String location = '/devices/location';
  static const String safeZones = '/safe-zones';
  static const String safeZoneEditor = '/safe-zones/editor';
  static const String safeZoneCreate = '/safe-zones/create';
  static const String remoteSessions = '/remote-sessions';
  static const String remoteSessionDetail = '/remote-session';
  static const String notifications = '/notifications';
  static const String account = '/account';
  static const String settings = '/settings';
  static const String permissionStatus = '/settings/permissions';
  static const String about = '/settings/about';
  static const String unknown = '/unknown';
}
