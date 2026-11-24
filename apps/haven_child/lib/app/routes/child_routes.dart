/// Route names for the child app, fixed by the Phase 3 Stage 1 brief.
///
/// Feature code navigates with these constants and never with a string
/// literal. Later stages extend this list (pairing, usage, policy, location)
/// rather than inventing parallel route tables.
abstract final class ChildRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String device = '/device';
  static const String permissions = '/permissions';
  static const String usage = '/usage';
  static const String childUsage = usage;
  static const String policy = '/policy';
  static const String unknown = '/unknown';
}

/// Alias for [ChildRoutes] supporting the standard [AppRoutes] convention.
typedef AppRoutes = ChildRoutes;
