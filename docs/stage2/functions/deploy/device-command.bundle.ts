// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `device-command`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:59-60 — MINIFIED BUNDLE, 18124 chars / 2 lines, sha256 4e31901a.... No source maps
//   exist (14:409 "Bundle-to-source equivalence — INFERRED"), so this is a re-authoring from
//   the anchor spec, not a de-minification, and it has NOT been compared to the captured bundle.
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../device-command.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:65): cors, envelope, auth, audit,
//   validation. NOT inlined: rate_limit — this function has no rate limiting in the captured
//   bundle either (finding E7 preserved).
// TABLES TOUCHED: devices, device_commands, device_policies, audit_logs (+ families,
//   family_members, profiles via the inlined assertions).
// RPCs CALLED: public.apply_policy_version, public.poll_device_commands.
//   public.expire_stale_commands exists (functions-and-triggers.md:41) but no capture anchor
//   shows a caller, so it is NOT called here.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. Device secrets arrive over x-device-secret and
//   are compared only as SHA-256 digests; the raw secret is never stored, logged or returned.
//   No service-role credential reaches any client path.
// *** PARTIALLY DEPLOYABLE: `create` accepts only apply_policy and custom. The other four
//   command types (sync_policy, request_usage, request_location, end_session) FAIL CLOSED with
//   501 command_spec_missing because no evidence names their payload allowlists (14:221).
//   This is an honest gap, not a no-op: see DEPLOYMENT-MAP.md. ***
// GAPS THIS BUNDLE CANNOT CLOSE: response shapes (never captured); the audit event_type
//   strings used here (`command_created`, `command_ack_recorded`) are labelled, not captured;
//   the gateway verify_jwt setting; the A13 identity decision (UNSIGNED).
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"; // version NOT captured (no import map in the repository)

// ---------------------------------------------------------------------------
// INLINED: _shared/cors.ts — RE-AUTHORED (capture:167, 490 chars / 13 lines, text never read).
// Wildcard origin + credential-bearing headers = finding E9, preserved deliberately.
// ---------------------------------------------------------------------------

const CORS_ALLOW_HEADERS =
  "authorization, x-client-info, apikey, content-type, x-device-id, x-device-secret, x-cron-secret";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": CORS_ALLOW_HEADERS,
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ ok: false, error: { code: "method_not_allowed", message: "POST only." } }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" } },
    );
  }
  return null;
}

// ---------------------------------------------------------------------------
// INLINED: _shared/envelope.ts — RE-AUTHORED (capture:168, 3517 chars / 112 lines, never read).
// POST-only, object-only, 512 KB enforced twice, action 1-64, no-store, name-only 500 logging,
// error.code-only DB logging (14:209-228, 14:269-283).
// ---------------------------------------------------------------------------

const MAX_BODY_CHARS = 512 * 1024;
const MAX_ACTION_LEN = 64;

class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly extra: Record<string, unknown>;
  constructor(status: number, code: string, message: string, extra: Record<string, unknown> = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}

function jsonHeaders(): Record<string, string> {
  return { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" };
}

function ok(data: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: true, ...data }), { status: 200, headers: jsonHeaders() });
}

function fail(status: number, code: string, message: string, extra: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: false, error: { code, message, ...extra } }), {
    status,
    headers: jsonHeaders(),
  });
}

function errorResponse(err: unknown): Response {
  if (err instanceof ApiError) return fail(err.status, err.code, err.message, err.extra);
  console.error(`edge_error: ${err instanceof Error ? err.name : "unknown"}`);
  return fail(500, "internal_error", "An unexpected error occurred.");
}

async function readJson(req: Request): Promise<Record<string, unknown>> {
  const declared = req.headers.get("content-length");
  if (declared !== null) {
    const n = Number(declared);
    if (Number.isFinite(n) && n > MAX_BODY_CHARS) {
      throw new ApiError(413, "payload_too_large", "Request body is too large.");
    }
  }
  const text = await req.text();
  if (text.length > MAX_BODY_CHARS) throw new ApiError(413, "payload_too_large", "Request body is too large.");
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new ApiError(400, "invalid_json", "Body must be JSON.");
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new ApiError(400, "invalid_payload", "Body must be a JSON object.");
  }
  return parsed as Record<string, unknown>;
}

function requireAction(body: Record<string, unknown>): string {
  const a = body["action"];
  if (typeof a !== "string" || a.length < 1 || a.length > MAX_ACTION_LEN) {
    throw new ApiError(400, "invalid_action", "action must be a string of 1 to 64 characters.");
  }
  return a;
}

function unknownAction(action: string): never {
  throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
}

function ensureNoError(err: { code?: string; message?: string } | null, fallbackMessage: string): void {
  if (!err) return;
  console.error(`db_error: ${err.code ?? "unknown"}`); // error.code ONLY
  throw new ApiError(500, "db_error", fallbackMessage);
}

// ---------------------------------------------------------------------------
// INLINED: _shared/validation.ts — RE-AUTHORED (capture:170, 12640 chars / 419 lines, never read).
// Helpers this handler uses are kept; the pairing-crypto helpers are retained because
// requireDevice() below depends on sha256Hex. PLACEHOLDER: the Android package-name regex.
// ---------------------------------------------------------------------------

function bad(message: string): never {
  throw new ApiError(400, "validation_error", message);
}

function readString(body: Record<string, unknown>, key: string, bounds: { min?: number; max?: number } = {}): string {
  const v = body[key];
  if (typeof v !== "string") bad(`${key} must be a string.`);
  const min = bounds.min ?? 1;
  const max = bounds.max ?? 4096;
  if (v.length < min || v.length > max) bad(`${key} must be ${min} to ${max} characters.`);
  return v;
}

function readOptionalString(body: Record<string, unknown>, key: string, bounds: { min?: number; max?: number } = {}): string | null {
  if (body[key] === undefined || body[key] === null) return null;
  return readString(body, key, bounds);
}

function readBoolean(body: Record<string, unknown>, key: string): boolean | null {
  const v = body[key];
  if (v === undefined || v === null) return null;
  if (typeof v !== "boolean") bad(`${key} must be a boolean.`);
  return v;
}

function readEnum<S extends string>(body: Record<string, unknown>, key: string, values: readonly S[]): S {
  const v = readString(body, key, { min: 1, max: 128 });
  if (!values.includes(v as S)) bad(`${key} must be one of: ${values.join(", ")}.`);
  return v as S;
}

function readObject(body: Record<string, unknown>, key: string, maxJsonChars: number): Record<string, unknown> {
  const v = body[key];
  if (v === null || typeof v !== "object" || Array.isArray(v)) bad(`${key} must be a JSON object.`);
  if (JSON.stringify(v).length > maxJsonChars) bad(`${key} is too large`);
  return v as Record<string, unknown>;
}

function readUuid(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 36, max: 36 });
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)) bad(`${key} must be a UUID.`);
  return v.toLowerCase();
}

function readHex64(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 64, max: 64 });
  if (!/^[0-9a-f]{64}$/.test(v)) bad(`${key} must be 64 hexadecimal characters.`);
  return v.toLowerCase();
}

function clampInt(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

const validatorEncoder = new TextEncoder();

function toHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(value: string): Promise<string> {
  return toHex(await crypto.subtle.digest("SHA-256", validatorEncoder.encode(value)));
}

function constantTimeEqualHex(a: string, b: string): boolean {
  const x = a.toLowerCase();
  const y = b.toLowerCase();
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x.charCodeAt(i) ^ y.charCodeAt(i);
  return diff === 0;
}

// ---------------------------------------------------------------------------
// INLINED: _shared/audit.ts — RE-AUTHORED (capture:165, 1101 chars / 38 lines, never read).
// A failed insert THROWS (500 audit_failed): an action cannot silently succeed unaudited
// (14:293, 14:340).
// ---------------------------------------------------------------------------

interface AuditInput {
  eventType: string;
  actorUserId?: string | null;
  familyId?: string | null;
  deviceId?: string | null;
  targetType?: string | null;
  targetId?: string | null;
  metadata?: Record<string, unknown>;
}

async function recordAudit(db: any, input: AuditInput): Promise<void> {
  const eventType = input.eventType;
  if (typeof eventType !== "string" || eventType.length < 1 || eventType.length > 80) {
    throw new ApiError(500, "audit_failed", "Audit write failed."); // audit_logs_event_type_check, A3:...:433
  }
  const { error } = await db.from("audit_logs").insert({
    family_id: input.familyId ?? null,
    actor_user_id: input.actorUserId ?? null,
    device_id: input.deviceId ?? null,
    event_type: eventType,
    target_type: input.targetType ?? null,
    target_id: input.targetId ?? null,
    metadata: input.metadata ?? {},
  });
  if (error) {
    console.error(`audit_insert_failed: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "audit_failed", "Audit write failed.");
  }
}

// ---------------------------------------------------------------------------
// INLINED: _shared/auth.ts — RE-AUTHORED (capture:166, 9920 chars / 338 lines, never read).
// THE TRUST BOUNDARY: every query here runs as service_role, so RLS is inert (14:245-246) and
// a missing predicate is not caught by the database. Anchors preserved: :51-56, :68-75, :92,
// :93-104, :123-127, :139-149, :151-196, :266-289, :295-338, :325-330.
//
// IDENTITY SEAM — A13 IS UNSIGNED. IDENTITY_MODE is the single switch; the Firebase-UID
// assumption lives in exactly ONE function (resolveFirebaseIdentity) and fails closed.
// ---------------------------------------------------------------------------

const IDENTITY_MODE: "supabase-auth" | "firebase-uid" = "supabase-auth";

interface Actor {
  userId: string;
  role: string;
  email: string | null;
  authUser: any;
  mode: typeof IDENTITY_MODE;
}

let cachedClient: ReturnType<typeof createClient> | null = null;

function getServiceClient(): ReturnType<typeof createClient> {
  if (cachedClient) return cachedClient;
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // NAME only
  if (!url || !serviceKey) throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  cachedClient = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
  });
  return cachedClient;
}

function bearerToken(req: Request): string {
  const raw = req.headers.get("authorization") ?? "";
  const m = /^Bearer\s+(\S+)$/i.exec(raw); // :68-75, VERIFIED regex anchor
  if (!m) throw new ApiError(401, "unauthorized", "Missing bearer token.");
  if (m[1].length < 20) throw new ApiError(401, "unauthorized", "Invalid token.");
  return m[1];
}

async function resolveIdentity(req: Request, db: any): Promise<Actor> {
  if (IDENTITY_MODE === "firebase-uid") return await resolveFirebaseIdentity(req, db);
  const token = bearerToken(req);
  let res: { data: { user: any } | null; error: any };
  try {
    res = await db.auth.getUser(token); // :92 — server-side verification
  } catch {
    throw new ApiError(401, "unauthorized", "Token could not be verified."); // :93-104 fail closed
  }
  const user = res.data?.user ?? null;
  if (res.error || !user || typeof user.id !== "string") {
    throw new ApiError(401, "unauthorized", "Token could not be verified.");
  }
  const { data: profile, error: perr } = await db
    .from("profiles")
    .select("id, role, display_name, created_at, updated_at")
    .eq("id", user.id)
    .maybeSingle();
  if (perr) {
    console.error(`profile_lookup: ${perr.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!profile) throw new ApiError(403, "profile_missing", "No profile for this account.");
  if (profile.role !== "parent" && profile.role !== "child" && profile.role !== "unset") {
    throw new ApiError(403, "forbidden", "Unknown role."); // :123-127
  }
  return { userId: user.id, role: profile.role as string, email: (user.email as string | null) ?? null, authUser: user, mode: "supabase-auth" };
}

/** THE FIREBASE-UID ASSUMPTION, ISOLATED AND DELIBERATELY NON-FUNCTIONAL WHILE A13 IS UNSIGNED. */
async function resolveFirebaseIdentity(_req: Request, _db: any): Promise<Actor> {
  throw new ApiError(
    503,
    "identity_mode_unsigned",
    "Firebase-uid identity is not approved (A13 unsigned); use IDENTITY_MODE 'supabase-auth'.",
  );
}

function emailVerifiedFor(actor: Actor): boolean {
  if (actor.mode === "firebase-uid") return actor.authUser?.email_verified === true; // unreachable today
  return !!actor.authUser?.email_confirmed_at; // evidenced: capture:50
}

async function requireUser(req: Request, opts: { verifyEmail?: boolean } = {}): Promise<{ auth: Actor; db: any; profile: { role: string } }> {
  const db = getServiceClient();
  const actor = await resolveIdentity(req, db);
  if (opts.verifyEmail && !emailVerifiedFor(actor)) {
    throw new ApiError(403, "email_not_verified", "Confirm your email address first.");
  }
  return { auth: actor, db, profile: { role: actor.role } };
}

function requireRole(profile: { role: string }, role: "parent" | "child"): void {
  if (profile.role !== role) throw new ApiError(403, "role_required", `This action requires the ${role} role.`);
}

const FAMILIES_SELECT = "id, name, owner_id, settings, created_at, updated_at, deleted_at";
const MEMBERS_SELECT = "id, family_id, user_id, role, status, created_at, removed_at";

async function loadLiveFamily(db: any, familyId: string): Promise<any> {
  const { data: family, error } = await db.from("families").select(FAMILIES_SELECT).eq("id", familyId).maybeSingle();
  if (error) {
    console.error(`family_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!family || family.deleted_at !== null) throw new ApiError(403, "forbidden", "Family not available.");
  return family;
}

async function loadActiveMembership(db: any, familyId: string, userId: string): Promise<any> {
  const { data: member, error } = await db
    .from("family_members")
    .select(MEMBERS_SELECT)
    .eq("family_id", familyId)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();
  if (error) {
    console.error(`membership_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  return member;
}

async function assertFamilyParent(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "parent") throw new ApiError(403, "forbidden", "Not a parent of this family.");
  return family;
}

async function assertFamilyChild(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "child") throw new ApiError(403, "forbidden", "Not a child of this family.");
  return family;
}

const assertChildMembership = assertFamilyChild;

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

async function requireActiveDeviceForParent(db: any, userId: string, deviceId: string): Promise<any> {
  const { data: device, error } = await db.from("devices").select(DEVICES_SELECT).eq("id", deviceId).maybeSingle();
  if (error) {
    console.error(`device_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!device) throw new ApiError(403, "forbidden", "Device not available.");
  if (device.status !== "active") throw new ApiError(403, "forbidden", "Device is not active.");
  await assertFamilyParent(db, userId, device.family_id); // family comes from the ROW, never the body
  return device;
}

/** :295-338. REVOCATION HONOURED: status != 'active' OR credential_revoked_at NOT NULL -> 401. */
async function requireDevice(req: Request, db: any): Promise<any> {
  const deviceId = req.headers.get("x-device-id");
  const secret = req.headers.get("x-device-secret");
  if (!deviceId || !secret) throw new ApiError(401, "device_auth_required", "Device credentials are required.");
  const id = deviceId.trim().toLowerCase();
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id);
  if (!isUuid || secret.length < 16 || secret.length > 512) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  const { data: device, error } = await db.from("devices").select(DEVICES_SELECT).eq("id", id).maybeSingle();
  if (error) {
    console.error(`device_auth_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  const storedHash: string | null = device?.secret_hash ?? null;
  const presentedHash = await sha256Hex(secret);
  const matches = await constantTimeEqualHex(presentedHash, storedHash ?? "0".repeat(64)); // :325-330 decoy
  if (!device || storedHash === null || !matches) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  if (device.status !== "active" || device.credential_revoked_at !== null) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  return device;
}

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../device-command.ts. Three actions, exactly capture:63.
// ---------------------------------------------------------------------------

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

const TERMINAL_COMMAND_STATUSES = ["succeeded", "failed", "expired"] as const; // A3:...:445
const ACKABLE_STATUSES = ["pending", "delivered"] as const; // capture:69

const COMMAND_COLUMNS =
  "id, device_id, family_id, type, payload, status, idempotency_key, created_by, created_at, expires_at, delivered_at, acked_at, result, error_message, attempts";

function isIdempotent(rpcData: unknown): boolean {
  return !!(rpcData && typeof rpcData === "object" && (rpcData as Record<string, unknown>)["idempotent"] === true);
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // ---- create: parent channel -----------------------------------------------------
    if (action === "create") {
      const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
      requireRole(profile, "parent"); // capture:64 + 14:110; TE-06 (15:63) needs 403 role_required
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

      // 14:217 — loads the device, requires it active, asserts parent membership in the
      // DEVICE'S family. family_id is never body-supplied.
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
        // UNVERIFIED: `command_created` event_type is not captured (see ../device-command.ts).
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
        // 14:229 — VERIFIED as an intentional gap: "custom payload is validated only as
        // 'object <= 64 KB' ... its schema is opaque to the server."
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
      // Finding E11 PRESERVED (14:421-439): returned rows carry created_by, i.e. the parent's
      // user id reaches the child's device. The projection narrowing is PROPOSED — NOT APPLIED,
      // because it is a client-visible contract change (14:434-436).
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

      // capture:69 — select .eq(id).eq(device_id, o.id): a command belonging to another device
      // is invisible, hence 404 not 403 (PE-C06, 15:122).
      const { data: command, error: cerr } = await db
        .from("device_commands")
        .select(COMMAND_COLUMNS)
        .eq("id", commandId)
        .eq("device_id", device.id)
        .maybeSingle();
      ensureNoError(cerr, "Could not read the command.");
      if (!command) throw new ApiError(404, "command_not_found", "No such command for this device.");

      // PE-C08 (15:124): expired -> 410 command_expired AND the row moved to 'expired', under a
      // compare-and-set so a concurrent ack cannot land on an expired row.
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

      // capture:69 — apply_policy ack updates device_policies AND devices.policy_version, both
      // scoped to this device.
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

    unknownAction(action); // 15:137 pattern — 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
