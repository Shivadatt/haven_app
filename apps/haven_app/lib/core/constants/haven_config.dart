import 'package:haven_api/haven_api.dart';

/// Build-time configuration, assembled from `--dart-define` values.
///
/// Nothing here is a secret: Supabase URL and anon key are client-side
/// identifiers, and the Firebase values come from the public app registration.
/// Service-role keys and Admin SDK credentials must never enter this class or
/// any file in the app.
final class HavenConfig {
  const HavenConfig({required this.endpoints, this.channel = 'staging'});

  const HavenConfig.unconfigured() : this(endpoints: BackendEndpoints.unconfigured);

  factory HavenConfig.fromDefines(
    String supabaseUrl,
    String supabaseAnonKey,
    String firebaseProjectId,
    String firebaseAppId,
    String firebaseApiKey,
  ) =>
      HavenConfig(
        endpoints: BackendEndpoints(
          supabaseUrl: supabaseUrl,
          supabaseAnonKey: supabaseAnonKey,
          firebaseProjectId: firebaseProjectId,
          firebaseAppId: firebaseAppId,
          firebaseApiKey: firebaseApiKey,
        ),
      );

  final BackendEndpoints endpoints;

  /// This programme is staging-only; the field exists so a release build can
  /// assert it rather than infer it from a URL.
  final String channel;

  BackendStatus get status => BackendStatus.of(endpoints);

  bool get isStaging => channel == 'staging';

  /// Names of defines that are absent. Values are never included.
  List<String> missingDefines() => [
        if (!endpoints.hasSupabase) 'HAVEN_SUPABASE_URL',
        if (!endpoints.hasSupabase) 'HAVEN_SUPABASE_ANON_KEY',
        if (!endpoints.hasFirebase) 'HAVEN_FIREBASE_PROJECT_ID',
        if (!endpoints.hasFirebase) 'HAVEN_FIREBASE_APP_ID',
        if (!endpoints.hasFirebase) 'HAVEN_FIREBASE_API_KEY',
      ];
}
