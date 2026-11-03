import 'backend_endpoints.dart';

/// Honest report of what the current build can actually reach.
///
/// The staging schema is gated on owner-signed approvals, so a normal developer
/// build is [notConfigured]. The UI must say so instead of showing invented
/// dashboards; see `BackendStatus.message`.
enum BackendReadiness { notConfigured, supabaseOnly, firebaseOnly, configured }

final class BackendStatus {
  const BackendStatus(this.readiness, {this.projectRef, this.detail});

  final BackendReadiness readiness;

  /// Non-secret staging project ref, echoed for display only.
  final String? projectRef;
  final String? detail;

  static BackendStatus of(BackendEndpoints e) => switch ((e.hasSupabase, e.hasFirebase)) {
        (false, false) => const BackendStatus(BackendReadiness.notConfigured),
        (true, false) => BackendStatus(BackendReadiness.supabaseOnly, projectRef: _refOf(e.supabaseUrl)),
        (false, true) => BackendStatus(BackendReadiness.firebaseOnly, projectRef: e.firebaseProjectId),
        (true, true) => BackendStatus(BackendReadiness.configured, projectRef: _refOf(e.supabaseUrl)),
      };

  bool get canSignIn => readiness == BackendReadiness.configured || readiness == BackendReadiness.firebaseOnly;
  bool get canLoadData => readiness == BackendReadiness.configured || readiness == BackendReadiness.supabaseOnly;

  /// Shown on screens that need data the backend cannot yet supply.
  String get message => switch (readiness) {
        BackendReadiness.notConfigured =>
          'Not connected to a backend yet. This build has no staging project configured.',
        BackendReadiness.supabaseOnly =>
          'Data is connected, but sign-in is not configured yet.',
        BackendReadiness.firebaseOnly =>
          'Sign-in is configured, but the data backend is not yet.',
        BackendReadiness.configured => 'Connected to staging.',
      };

  static String? _refOf(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host;
    if (host == null || host.isEmpty) return null;
    final first = host.split('.').first;
    return first.isEmpty ? null : first;
  }
}
