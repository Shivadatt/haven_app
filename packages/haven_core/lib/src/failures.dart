/// Why an operation failed, in parent-facing terms.
///
/// [message] is safe to show in the UI. [detail] is developer context and must
/// never contain credentials, tokens or raw SDK payloads.
sealed class HavenFailure {
  const HavenFailure(this.message, {this.detail, this.retryable = false});

  final String message;
  final String? detail;
  final bool retryable;

  bool get isUnauthorized => this is AuthFailure;
}

/// No usable session, or the backend rejected the bearer token.
final class AuthFailure extends HavenFailure {
  const AuthFailure(super.message, {super.detail, this.signedOut = false})
    : super(retryable: false);

  /// True when the session is gone, not merely stale: go back to sign-in.
  final bool signedOut;
}

/// The caller is authenticated but not entitled (family/device ownership).
final class PermissionFailure extends HavenFailure {
  const PermissionFailure(super.message, {super.detail});
}

/// Android or OS-level permission was declined, or is permanently denied.
final class DevicePermissionFailure extends HavenFailure {
  const DevicePermissionFailure(
    super.message, {
    super.detail,
    this.permanentlyDenied = false,
    this.openSettingsWillHelp = false,
  });

  final bool permanentlyDenied;
  final bool openSettingsWillHelp;
}

/// Network unreachable, timeout, or the backend is not configured yet.
final class NetworkFailure extends HavenFailure {
  const NetworkFailure(super.message, {super.detail, super.retryable = true});
}

/// The backend answered with a rejected request or an unexpected payload.
final class BackendFailure extends HavenFailure {
  const BackendFailure(
    super.message, {
    super.detail,
    this.code,
    super.retryable = false,
  });

  /// Backend-supplied code when one exists; never invented locally.
  final String? code;
}

/// Local storage could not be read or written.
final class StorageFailure extends HavenFailure {
  const StorageFailure(super.message, {super.detail});
}

/// Input the user can correct (empty name, out-of-range radius, bad code).
final class ValidationFailure extends HavenFailure {
  const ValidationFailure(super.message, {super.detail, this.field});

  final String? field;
}

/// A documented requirement with no specification to implement against.
///
/// Surfaced instead of a fabricated success path, per the brief: an unspecified
/// feature stays blocked and says so.
final class BlockedFailure extends HavenFailure {
  const BlockedFailure(super.message, {super.detail, required this.missing});

  /// What is missing: a spec section, a signed approval, a schema column.
  final String missing;
}

/// Anything not classified above. Reported, never silently swallowed.
final class UnknownFailure extends HavenFailure {
  const UnknownFailure(super.message, {super.detail});
}
