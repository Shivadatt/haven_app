// The database's own rules, transcribed from evidence, so a handler can refuse a write
// before the database does.
//
// Status: **VERIFIED against `docs/stage1/evidence/g1-q5-20261029.json`** (CHECK constraint
// definitions, project `parent-control-prod`, read-only, 2026-10-29). This is the one module in
// `_shared/` that is not re-authored from a minified bundle: every value below is a constraint the
// database enforces, copied from the capture rather than inferred from behaviour.
//
// Why it exists anyway: these functions run as `service_role`, so a value that violates a CHECK
// becomes a 500 whose message contains a constraint name — exactly the leak §check 14 of
// `docs/stage1/14-edge-function-security-audit.md` says the code goes out of its way to avoid.
// Checking first turns that into a 400 with a sentence a parent can read.
//
// It is not a substitute for the constraint. A direct write through the Data API, or a handler
// bug, still lands on the database rule.

/** `devices.status`. */
export const DEVICE_STATUS = ["pending", "active", "revoked"] as const;
/** `devices.enforcement_mode`. */
export const ENFORCEMENT_MODES = ["none", "device_admin", "device_owner"] as const;
/** `device_commands.type`. */
export const COMMAND_TYPES = [
  "apply_policy",
  "sync_policy",
  "request_usage",
  "request_location",
  "end_session",
  "custom",
] as const;
/** `device_commands.status`. */
export const COMMAND_STATUS = ["pending", "delivered", "succeeded", "failed", "expired"] as const;
/** A command may still be acknowledged only while it is in one of these. */
export const ACKABLE_COMMAND_STATUS = ["pending", "delivered"] as const;
/** `device_policies.enforcement_status`. */
export const POLICY_ENFORCEMENT_STATUS = ["pending", "enforced", "failed", "unsupported"] as const;
/** `remote_sessions.kind`. */
export const SESSION_KINDS = ["audio", "video"] as const;
/** `remote_sessions.status`. */
export const SESSION_STATUS = [
  "requested",
  "accepted",
  "active",
  "declined",
  "ended",
  "expired",
  "failed",
] as const;
/** `safety_alerts.type`. */
export const ALERT_TYPES = [
  "low_battery",
  "offline",
  "geofence_enter",
  "geofence_exit",
  "app_blocked",
  "permission_missing",
  "other",
] as const;
/** `safety_alerts.severity`. */
export const ALERT_SEVERITIES = ["info", "warning", "critical"] as const;
/** `webrtc_signals.kind`. */
export const SIGNAL_KINDS = ["offer", "answer", "ice"] as const;
/** `pairing_requests.status` default is `pending_child`; the full set is NOT CAPTURED. */
export const MEMBER_ROLES = ["parent", "child"] as const;

/**
 * Length and range bounds, keyed as the capture names them.
 *
 * A handler that writes past one of these produces a database error, not a validation error,
 * so the number matters: it is the difference between a 400 sentence and a 500 that says
 * "the request could not be completed" for a value that was never going to fit.
 */
export const LIMITS = {
  displayNameMax: 80,
  installationIdMin: 8,
  installationIdMax: 128,
  platformMax: 32,
  versionStringMax: 40,
  idempotencyKeyMax: 128,
  errorMessageMax: 500,
  alertMessageMax: 300,
  endedReasonMax: 200,
  appLabelMax: 100,
  packageNameMax: 150,
  sourceMax: 40,
  usageSourceMax: 32,
  webrtcPayloadMaxChars: 16384,
  batteryMin: 0,
  batteryMax: 100,
  latMin: -90,
  latMax: 90,
  lngMin: -180,
  lngMax: 180,
  accuracyMaxM: 100_000,
  screenTimeMinutesMax: 1440,
  familyNameMax: 80,
} as const;

/** `devices.secret_hash` and `device_pairing_tokens.code_hash` are both `^[0-9a-f]{64}$`. */
export const DIGEST_PATTERN = /^[0-9a-f]{64}$/;

/**
 * `devices_revoked_credential_consistency`: `status <> 'revoked' OR secret_hash IS NULL`.
 *
 * A revocation therefore has to clear the hash in the same statement, which is why
 * `family-admin revoke_device` cannot be expressed as a bare status update.
 */
export function revokedRowIsConsistent(status: string, secretHash: unknown): boolean {
  return status !== "revoked" || secretHash === null || secretHash === undefined;
}

/**
 * `family_members_removed_consistency`: `(status = 'removed') = (removed_at IS NOT NULL)`.
 *
 * Recorded because a handler that soft-removes a member must set both halves, and setting only
 * one is a constraint violation that looks like an unrelated failure.
 */
export function memberRowIsConsistent(status: string, removedAt: unknown): boolean {
  return (status === "removed") === (removedAt !== null && removedAt !== undefined);
}

/** `remote_sessions_pending_expiry_check`: a `requested` row always carries `expires_at`. */
export function sessionRowIsConsistent(status: string, expiresAt: unknown): boolean {
  return status !== "requested" || (expiresAt !== null && expiresAt !== undefined);
}

/**
 * The two keys `families.settings` is known to hold, taken from the column default
 * `{"usage_retention_days": 90, "location_retention_days": 30}` in the same capture.
 *
 * DECISION, not evidence: the capture gives the keys and their defaults, not an accepted range.
 * A 1–3650 day guard is chosen here and is not a database rule; the deployed
 * `family-admin.update_retention` body was one of the 24 the review could not read.
 */
export const RETENTION_KEYS = ["usage_retention_days", "location_retention_days"] as const;
export const RETENTION_MIN_DAYS = 1;
export const RETENTION_MAX_DAYS = 3650;
