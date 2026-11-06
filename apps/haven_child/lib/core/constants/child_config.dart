/// Build-time configuration and app identity for the child companion.
///
/// Stage 1 is fully local, so the define reader stays minimal: one optional
/// `HAVEN_CHILD_ENV` value, no endpoint strings, and nothing that could carry
/// a secret. Client identifiers arrive only via `--dart-define`, never from
/// files or the network (contract rule 4). Cloud configuration lanes, if a
/// later stage ever needs them, grow here through `haven_api` types — not by
/// restating transport strings in the app.
final class ChildConfig {
  const ChildConfig({this.environment = defaultEnvironment});

  factory ChildConfig.fromDefines(String environment) => ChildConfig(
    environment: environment.isEmpty ? defaultEnvironment : environment,
  );

  /// `--dart-define=HAVEN_CHILD_ENV=...`; the only supported value in Stage 1
  /// is `local`, which is also the default when the define is absent.
  final String environment;

  static const String defaultEnvironment = 'local';

  /// Identity strings are single-sourced here. The Android applicationId in
  /// `android/app/build.gradle.kts` must match [applicationId] (decision D-1);
  /// a later test can assert that instead of trusting a comment.
  static const String applicationId = 'com.haven.child';
  static const String appName = 'Haven Child';

  /// Keep in sync with `pubspec.yaml` `version:` — the device screen shows
  /// this value, so it must be the shipped version, not a guess. A Stage-2
  /// test may assert the two match instead of trusting this comment.
  static const String appVersion = '0.1.0';

  bool get isLocal => environment == defaultEnvironment;
}
