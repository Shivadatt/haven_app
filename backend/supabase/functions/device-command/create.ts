// device-command / create — the PARENT-channel action.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour, labels and anchors unchanged.
// Read `index.ts` for the captured-facts header.
//
// Auth: this path authenticates as a parent (JWT + verified email + requireActiveDeviceForParent)
// and is the ONLY action of this slug that does; `poll`/`ack` use the device credential channel
// in ./poll_ack.ts. `family_id` is never read from the body — it comes from the device row.
//
// UNVERIFIED BEHAVIOUR carried from index.ts:
//   - `command_created` is a labelled invention: no anchor names the audit event_type.
//   - sync_policy / request_usage / request_location / end_session FAIL CLOSED with 501
//     `command_spec_missing`. 14:221 says payloads are allowlisted per command type but no
//     anchor names a single allowed key for those four, so accepting one would mean inventing
//     a schema. Only `apply_policy` and `custom` are implemented from evidence.
// ============================================================================

import {
  ApiError,
  ensureNoError,
  fail,
  ok,
} from "../_shared/envelope.ts";
import { requireActiveDeviceForParent, requireRole, requireUser } from "../_shared/auth.ts";
import { recordAudit } from "../_shared/audit.ts";
import { clampInt, readEnum, readObject, readUuid } from "../_shared/validation.ts";

const IDEMPOTENCY_KEY_MIN = 1; // capture:67 "idempotency_key min 1 max 128"
const IDEMPOTENCY_KEY_MAX = 128;
const TTL_MIN_SECONDS = 60; // capture:67 "ttl clamps 60..900"
const TTL_MAX_SECONDS = 900;
const CUSTOM_PAYLOAD_MAX = 64 * 1024; // 14:229

export const COMMAND_TYPES = [
  "apply_policy",
  "sync_policy",
  "request_usage",
  "request_location",
  "end_session",
  "custom",
] as const; // VERIFIED: device_commands_type_check, A3-staging-load-v1.sql:446

export const COMMAND_COLUMNS =
  "id, device_id, family_id, type, payload, status, idempotency_key, created_by, created_at, expires_at, delivered_at, acked_at, result, error_message, attempts";

/** capture:67 — the RPC response carries its own `idempotent` flag. */
export function isIdempotent(rpcData: unknown): boolean {
  return !!(rpcData && typeof rpcData === "object" &&
    (rpcData as Record<string, unknown>)["idempotent"] === true);
}

export async function handleCreate(
  req: Request,
  body: Record<string, unknown>,
): Promise<Response> {
  const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
  requireRole(profile, "parent"); // capture:64 + 14:110 (create -> parent); TE-06 (15:63) needs 403 role_required
  const deviceId = readUuid(body, "device_id");
  const type = readEnum(body, "type", COMMAND_TYPES); // PE-C09 (15:126): unknown type -> 400
  const key = (() => {
    const v = body["idempotency_key"];
    if (typeof v !== "string" || v.length < IDEMPOTENCY_KEY_MIN || v.length > IDEMPOTENCY_KEY_MAX) {
      throw new ApiError(400, "validation_error", "idempotency_key must be 1 to 128 characters.");
    }
    return v;
  })();
  const ttlSeconds = clampInt(
    typeof body["ttl_seconds"] === "number" ? (body["ttl_seconds"] as number) : TTL_MIN_SECONDS,
    TTL_MIN_SECONDS,
    TTL_MAX_SECONDS,
  ); // PE-C03 (15:120): ttl_seconds 10 -> clamped to 60

  // 14:217 — requireActiveDeviceForParent loads the device, requires it active, and
  // asserts parent membership in the DEVICE'S family. family_id is never body-supplied.
  const device = await requireActiveDeviceForParent(db, auth.userId, deviceId);

  // capture:67 — pre-insert idempotency lookup on (device_id, idempotency_key).
  const { data: prior, error: perr } = await db
    .from("device_commands")
    .select(COMMAND_COLUMNS)
    .eq("device_id", device.id)
    .eq("idempotency_key", key)
    .maybeSingle();
  ensureNoError(perr, "Could not check the idempotency key.");
  if (prior) return ok({ command: prior, idempotent: true }); // PE-C05/CI-05 (15:123, 15:215)

  if (type === "apply_policy") {
    // capture:67 — apply_policy is NOT inserted here; it delegates wholesale to the RPC.
    const policy = readObject(body, "policy", 256 * 1024); // 14:223 cap; policy must be an object (A3:...:454)
    const { data, error } = await db.rpc("apply_policy_version", {
      p_device_id: device.id,
      p_policy: policy,
      p_actor: auth.userId, // NEVER a body field (14:96)
      p_idempotency_key: key,
    });
    if (error) {
      console.error(`rpc_apply_policy_version: ${error.code ?? "unknown"}`);
      throw new ApiError(500, "internal_error", "Could not apply the policy.");
    }
    // UNVERIFIED: `command_created` event_type is not captured (see header).
    await recordAudit(db, {
      eventType: "command_created",
      actorUserId: auth.userId,
      familyId: device.family_id,
      deviceId: device.id,
      targetType: "command",
      targetId: null,
      metadata: { type, idempotency_key: key },
    });
    return ok({ command: data ?? null, idempotent: isIdempotent(data) });
  }

  if (type === "custom") {
    // 14:229 — VERIFIED as an intentional gap in validation: "custom payload is
    // validated only as 'object <= 64 KB', which is deliberate but means its schema is
    // opaque to the server."
    const payload = readObject(body, "payload", CUSTOM_PAYLOAD_MAX);
    const inserted = await db.from("device_commands").insert({
      device_id: device.id,
      family_id: device.family_id, // from the device row, not the body
      type,
      payload,
      status: "pending",
      idempotency_key: key,
      created_by: auth.userId,
      created_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + ttlSeconds * 1000).toISOString(),
      attempts: 0,
    });
    if (inserted.error) {
      if (inserted.error.code === "23505") {
        // capture:67 — UNIQUE (device_id, idempotency_key) violation -> re-read.
        const { data: again, error: aerr } = await db
          .from("device_commands")
          .select(COMMAND_COLUMNS)
          .eq("device_id", device.id)
          .eq("idempotency_key", key)
          .maybeSingle();
        ensureNoError(aerr, "Could not re-read the command.");
        return ok({ command: again ?? null, idempotent: true });
      }
      ensureNoError(inserted.error, "Could not create the command.");
    }
    const created = inserted.data?.[0] ?? null;
    await recordAudit(db, {
      eventType: "command_created",
      actorUserId: auth.userId,
      familyId: device.family_id,
      deviceId: device.id,
      targetType: "command",
      targetId: created?.id ?? null,
      metadata: { type, ttl_seconds: ttlSeconds },
    });
    return ok({ command: created });
  }

  // sync_policy / request_usage / request_location / end_session:
  // UNVERIFIED BEHAVIOUR — not implemented (no evidence). 14:221 states command payloads are
  // allowlisted per command type, but NO anchor or spec names the allowed keys for these four
  // types, and nothing in the repository describes them. They therefore FAIL CLOSED rather
  // than accepting an invented schema.
  return fail(
    501,
    "command_spec_missing",
    `Command type "${type}" is not specified in any available evidence; this re-authored ` +
      `bundle implements apply_policy and custom only. Not deployable for "${type}" without spec.`,
  );
}
