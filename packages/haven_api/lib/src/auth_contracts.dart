import 'package:haven_core/haven_core.dart';

/// Identity and transport seams.
///
/// The ratified topology (S2-EXEC-08): Firebase Auth issues the external ID
/// token, Supabase verifies it and stays the session/authorization authority,
/// and the Firebase UID maps to one profile only through the server-side
/// `firebase_identity_mapping` table. A client assertion of a UID is never
/// identity, so nothing here sends a Firebase UID to Supabase as proof.

/// The signed-in person, as Supabase sees them.
final class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    this.role,
    this.expiresAt,
  });

  /// Supabase `auth.users` id — also `public.profiles.id`.
  final String userId;
  final String? email;
  final String accessToken;

  /// `profiles.role`, or null when the profile row does not exist yet. Profile
  /// provisioning has no approved implementation, so null is an expected state.
  final String? role;
  final DateTime? expiresAt;

  bool get hasProfile => role != null;
}

/// Sign-in state observed by the app.
enum AuthStatusKind { unknown, signedOut, signedIn, profileMissing, expired }

final class AuthStateSnapshot {
  const AuthStateSnapshot(this.kind, {this.session});
  final AuthStatusKind kind;
  final AuthSession? session;

  bool get isSignedIn => kind == AuthStatusKind.signedIn;
}

/// User-facing identity operations.
abstract interface class UserAuth {
  Future<Result<AuthSession>> signInWithPassword({required String email, required String password});
  Future<Result<AuthSession>> register({required String email, required String password, required String displayName});

  /// Exchange a Firebase ID token for a Supabase session through Third-Party Auth.
  /// Implemented only once the approved bridge exists; otherwise returns `blocked(...)`.
  Future<Result<AuthSession>> signInWithFirebaseToken(String firebaseIdToken);

  Future<Result<AuthSession?>> currentSession();
  Future<Result<AuthSession>> refresh();
  Future<Result<void>> signOut();
  Stream<AuthStateSnapshot> get states;
}

/// Loading and updating the person's own `profiles` row.
abstract interface class ProfileStore {
  Future<Result<Map<String, Object?>?>> load(String userId);
  Future<Result<void>> updateDisplayName(String userId, String displayName);
}

/// Device-lane credential: separate from [UserAuth] and never converted into it.
final class DeviceCredential {
  const DeviceCredential({required this.deviceId, required this.secret, required this.storedSecurely});

  final String deviceId;

  /// Held only in platform secure storage; never logged, never in a report.
  final String secret;

  /// False when the platform keystore was unavailable — the caller must then
  /// treat the device as unpaired rather than silently keep a plaintext copy.
  final bool storedSecurely;
}

abstract interface class DeviceIdentity {
  Future<Result<DeviceCredential?>> credential();
  Future<Result<DeviceCredential>> issue(DeviceCredential credential);
  Future<Result<void>> clear();
}

/// FCM transport: capture and refresh of the device token.
abstract interface class PushTransport {
  Future<Result<String?>> registrationToken();
  Future<Result<void>> clearToken();
  Stream<String> get tokenChanges;

  /// Notification permission, reported as the OS states it — never assumed.
  Future<bool> requestPermission();
  Future<bool> get granted;

  /// Taps, for navigation. Payload keys are whatever the sender used; nothing is invented.
  Stream<Map<String, Object?>> get taps;
  Stream<Map<String, Object?>> get foregroundMessages;
}
