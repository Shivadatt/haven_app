// ============================================================================
// Edge Function: device-command           TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// The production project's ref is deliberately NOT written in this artefact (owner rule: the
// staging project is the only project ref that may appear in code, comments or config).
// Production is not a target of this file and was not contacted. Deployment is BLOCKED by
// unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:59-60: MINIFIED BUNDLE, 18124 chars / 2 lines, sha256 4e31901a.... No source
//   maps exist (14:409 "Bundle-to-source equivalence — INFERRED"), so this is a re-authoring
//   from the anchor spec, not a de-minification. Nothing here has been compared to the
//   captured bundle.
//
// CAPTURED FACTS USED (file:line):
//   capture:63  actions = create, poll, ack
//   capture:64  auth_model = "create: parent JWT + verified email + requireActiveDeviceForParent;
//               poll/ack: device header credentials (x-device-id + x-device-secret)"
//   capture:65  inlined_modules = cors, envelope, auth, audit, validation  (NO rate_limit)
//   capture:67  apply_policy -> rpc apply_policy_version {p_device_id, p_policy,
//               p_actor:o.user.id, p_idempotency_key}; idempotency_key min 1 max 128;
//               ttl clamps 60..900; device_commands select by device_id + idempotency_key
//               before insert; 23505 -> re-read by idempotency key
//   capture:68  poll: rpc poll_device_commands {p_device_id:o.id, p_limit:20}
//   capture:69  ack: device_commands select .eq(id).eq(device_id,o.id); terminal status
//               returns existing row; update ... .in(status,[pending,delivered]); apply_policy
//               ack updates device_policies and devices.policy_version scoped to device
//   14-edge-function-security-audit.md:122 (role from profiles.role via service-role client),
//     :229 (custom payload = "object <= 64 KB" only), :224 (command `result` 32 KB, error text
//     truncated to 500), :306-309 (check 16 idempotency), :421-439 (finding E11: poll returns
//     created_by; the narrowing is PROPOSED — NOT APPLIED, so it is PRESERVED here)
//   15-edge-function-test-plan.md:116-126 PE-C01..C09 (codes: 403 / 400 / 404 command_not_found
//     / 410 command_expired / ttl clamp 60)
//   docs/stage1/evidence/functions-and-triggers.md:36,43,41 RPC signatures
//   docs/stage2/migrations/A3-staging-load-v1.sql:446 command type vocabulary
//     (apply_policy|sync_policy|request_usage|request_location|end_session|custom) — DATABASE-VERIFIED
//   :445 status vocabulary (pending|delivered|succeeded|failed|expired); :424 UNIQUE
//     (device_id, idempotency_key); :442 error_message <= 500; :441 attempts >= 0
//
// TABLES TOUCHED: devices (SELECT via auth; UPDATE policy_version), device_commands (SELECT,
//   INSERT, UPDATE), device_policies (SELECT, UPDATE), audit_logs (INSERT), families /
//   family_members / profiles (SELECT via auth assertions).
// RPCs CALLED: public.apply_policy_version, public.poll_device_commands.
//   public.expire_stale_commands(p_device_id) EXISTS (functions-and-triggers.md:41) but no
//   capture anchor shows a caller, so it is NOT called here. UNVERIFIED.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. Device secrets arrive over x-device-secret and
//   are compared as SHA-256 digests; the raw secret is never stored, logged or returned.
// AUTH MODEL: two channels in one function — parent JWT for `create`, device credential for
//   `poll`/`ack`. Both authorise IN-HANDLER because service_role makes RLS inert (14:245).
//   `create` never takes family_id from the body: it comes from the device row
//   (requireActiveDeviceForParent, _shared/auth.ts:266-289). `poll`/`ack` ignore a body
//   device_id entirely — PE-C05 (15:122) proves the forged-id case must return D1's commands.
// IDEMPOTENCY: PRESENT. Pre-insert lookup by (device_id, idempotency_key), 23505 -> re-read,
//   apply_policy delegates to the RPC whose response carries `idempotent`; `ack` is a
//   compare-and-set with a re-read on a lost race.
// RATE LIMITING: ABSENT here — and ABSENT IN THE CAPTURED BUNDLE (capture:65 does not list
//   rate_limit). Preserved; finding E7.
// AUDIT LOGGING: PRESENT on `create` (capture:65 inlines audit). PE-C01 expects "two audit
//   rows" for apply_policy (15:118); one comes from this handler and the other is written
//   inside private.apply_policy_version, whose body is unread. See UNVERIFIED below.
// verify_jwt: NOT CAPTURED (no such field exists in the capture). Auth is in-handler on both
//   channels; a gateway verify_jwt value must be read from the dashboard before deploy.
//
// UNVERIFIED BEHAVIOUR (not implemented — no evidence):
//   - PAYLOAD SCHEMAS FOR sync_policy, request_usage, request_location, end_session.
//     14:221 says command payloads are "allowlisted per command type", but no anchor names
//     a single allowed key for these four types, and nothing in the repository describes
//     them. They therefore FAIL CLOSED with 501 `command_spec_missing` rather than accepting
//     an invented schema. `apply_policy` and `custom` ARE implemented from evidence.
//     -> This function is PARTIALLY deployable; see DEPLOYMENT-MAP.md verdict.
//   - `audit` event_type strings and metadata shapes: no anchor names them. `command_created`
//     and `command_ack_recorded` are used and labelled; a mismatch with production breaks any
//     dashboard that filters on event_type.
//   - Which policy row an apply_policy `ack` acknowledges: capture:69 says only "updates
//     device_policies and devices.policy_version scoped to device". The version-selection
//     rule (latest pending for the device) is INFERRED.
//   - `delivered` is written by poll_device_commands (inside the unread RPC), not here.
//   - Response shapes for all three actions are not captured.
//   - Whether `ack` may report enforcement failures (`enforcement_status='failed'` plus
//     last_error) for a failed ack: implemented as the natural reading of the vocabulary and
//     labelled INFERRED.
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import {
  ApiError,
  ensureNoError,
  errorResponse,
  fail,
  ok,
  readJson,
  requireAction,
  unknownAction,
} from "./_shared/envelope.ts";
import { getServiceClient, requireActiveDeviceForParent, requireDevice, requireRole, requireUser } from "./_shared/auth.ts";
import { recordAudit } from "./_shared/audit.ts";
import {
  clampInt,
  readEnum,
  readObject,
  readOptionalString,
  readUuid,
} from "./_shared/validation.ts";

const IDEMPOTENCY_KEY_MIN = 1; // capture:67 "idempotency_key min 1 max 128"
const IDEMPOTENCY_KEY_MAX = 128;
const TTL_MIN_SECONDS = 60; // capture:67 "ttl clamps 60..900"
const TTL_MAX_SECONDS = 900;
const COMMAND_RESULT_MAX = 32 * 1024; // 14:224
const CUSTOM_PAYLOAD_MAX = 64 * 1024; // 14:229
const ERROR_MESSAGE_MAX = 500; // VERIFIED by the DB check at A3:...:442
const POLL_LIMIT = 20; // capture:68

const COMMAND_TYPES = [
  "apply_policy",
  "sync_policy",
  "request_usage",
  "request_location",
  "end_session",
  "custom",
] as const; // VERIFIED: device_commands_type_check, A3-staging-load-v1.sql:446

const TERMINAL_COMMAND_STATUSES = ["succeeded", "failed", "expired"] as const; // A3:...:445 vocabulary;
const ACKABLE_STATUSES = ["pending", "delivered"] as const; // capture:69 — ".in(status,[pending,delivered])"

const COMMAND_COLUMNS =
  "id, device_id, family_id, type, payload, status, idempotency_key, created_by, created_at, expires_at, delivered_at, acked_at, result, error_message, attempts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // ---- create: parent channel -----------------------------------------------------
    if (action === "create") {
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
      // UNVERIFIED BEHAVIOUR — not implemented (no evidence). 14:221 states payloads are
      // allowlisted per command type, but NO anchor or spec names the allowed keys for these
      // four types. Accepting an invented schema would be exactly the failure the brief
      // forbids, and silently ignoring them would be a no-op. Fail closed instead.
      return fail(
        501,
        "command_spec_missing",
        `Command type "${type}" is not specified in any available evidence; this re-authored ` +
          `bundle implements apply_policy and custom only. Not deployable for "${type}" without spec.`,
      );
    }

    // ---- poll / ack: device channel ---------------------------------------------------
    if (action === "poll") {
      const db = getServiceClient();
      const device = await requireDevice(req, db);
      // capture:68 — p_device_id is the AUTHENTICATED device; any body device_id is ignored
      // (PE-C05, 15:122).
      const { data, error } = await db.rpc("poll_device_commands", {
        p_device_id: device.id,
        p_limit: POLL_LIMIT,
      });
      if (error) {
        console.error(`rpc_poll_device_commands: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not fetch commands.");
      }
      // Finding E11 PRESERVED (14:421-439): the rows returned carry created_by, i.e. the
      // parent's user id reaches the child's device. The projection narrowing is PROPOSED —
      // NOT APPLIED, because it is a client-visible contract change (14:434-436).
      return ok({ commands: data ?? [] });
    }

    if (action === "ack") {
      const db = getServiceClient();
      const device = await requireDevice(req, db);
      const commandId = readUuid(body, "command_id");
      const status = readEnum(body, "status", ["succeeded", "failed"] as const); // PE-C07 (15:124)
      const result = body["result"] === undefined || body["result"] === null
        ? null
        : readObject(body, "result", COMMAND_RESULT_MAX); // 14:224
      const rawError = readOptionalString(body, "error_message", { min: 1, max: ERROR_MESSAGE_MAX });
      const errorMessage = rawError === null ? null : rawError.slice(0, ERROR_MESSAGE_MAX); // 14:224 truncation

      // capture:69 — select .eq(id).eq(device_id, o.id): a command belonging to another
      // device is invisible, hence 404 not 403 (PE-C06, 15:122).
      const { data: command, error: cerr } = await db
        .from("device_commands")
        .select(COMMAND_COLUMNS)
        .eq("id", commandId)
        .eq("device_id", device.id)
        .maybeSingle();
      ensureNoError(cerr, "Could not read the command.");
      if (!command) throw new ApiError(404, "command_not_found", "No such command for this device.");

      // PE-C08 (15:124): an expired command -> 410 command_expired AND the row moved to
      // 'expired'. Compare-and-set so a concurrent ack cannot land on an expired row.
      if (new Date(command.expires_at).getTime() <= Date.now()) {
        await db
          .from("device_commands")
          .update({ status: "expired" })
          .eq("id", command.id)
          .in("status", ACKABLE_STATUSES as unknown as string[]);
        return fail(410, "command_expired", "This command has expired.");
      }

      // capture:69 — terminal status returns the existing row (TE-17, 15:74).
      if ((TERMINAL_COMMAND_STATUSES as readonly string[]).includes(command.status)) {
        return ok({ command, idempotent: true });
      }

      const { data: updated, error: uerr } = await db
        .from("device_commands")
        .update({
          status,
          acked_at: new Date().toISOString(),
          result: result ?? {},
          error_message: errorMessage,
          attempts: (command.attempts ?? 0) + 1,
        })
        .eq("id", command.id)
        .eq("device_id", device.id)
        .in("status", ACKABLE_STATUSES as unknown as string[]) // capture:69
        .select(COMMAND_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not record the acknowledgement.");
      if (!updated) {
        // 14:309 — lost the race: re-read and return the current row.
        const { data: again } = await db
          .from("device_commands")
          .select(COMMAND_COLUMNS)
          .eq("id", commandId)
          .eq("device_id", device.id)
          .maybeSingle();
        return ok({ command: again ?? null, idempotent: true });
      }

      // capture:69 — apply_policy ack updates device_policies AND devices.policy_version,
      // both scoped to this device.
      if (command.type === "apply_policy" && status === "succeeded") {
        const { data: pendingPolicy, error: perr2 } = await db
          .from("device_policies")
          .select("id, version, policy, enforcement_status")
          .eq("device_id", device.id)
          .eq("family_id", device.family_id)
          .eq("enforcement_status", "pending") // A3:...:452 vocabulary
          .order("version", { ascending: false })
          .limit(1)
          .maybeSingle();
        ensureNoError(perr2, "Could not read the pending policy.");
        if (pendingPolicy) {
          await db
            .from("device_policies")
            .update({ acknowledged_at: new Date().toISOString(), enforcement_status: "enforced" })
            .eq("id", pendingPolicy.id)
            .eq("device_id", device.id);
          await db
            .from("devices")
            .update({ policy_version: pendingPolicy.version })
            .eq("id", device.id); // scoped to the authenticated device
        }
      } else if (command.type === "apply_policy" && status === "failed") {
        // INFERRED (see header): a failed ack records the failure instead of advancing the version.
        const { data: failPolicy } = await db
          .from("device_policies")
          .select("id, enforcement_status")
          .eq("device_id", device.id)
          .eq("family_id", device.family_id)
          .eq("enforcement_status", "pending")
          .order("version", { ascending: false })
          .limit(1)
          .maybeSingle();
        if (failPolicy) {
          await db
            .from("device_policies")
            .update({ enforcement_status: "failed", last_error: errorMessage })
            .eq("id", failPolicy.id)
            .eq("device_id", device.id);
        }
      }

      await recordAudit(db, {
        eventType: "command_ack_recorded", // UNVERIFIED name; see header
        actorUserId: null, // 14:296 — device-originated events carry a NULL actor
        familyId: device.family_id,
        deviceId: device.id,
        targetType: "command",
        targetId: command.id,
        metadata: { type: command.type, status },
      });
      return ok({ command: updated });
    }

    unknownAction(action); // PE-CR06/15:137 pattern — 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});

function isIdempotent(rpcData: unknown): boolean {
  return !!(rpcData && typeof rpcData === "object" && (rpcData as Record<string, unknown>)["idempotent"] === true);
}
