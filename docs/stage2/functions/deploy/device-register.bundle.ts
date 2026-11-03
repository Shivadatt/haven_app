// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `device-register`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:73-74 — MINIFIED BUNDLE, 9086 chars / 2 lines, sha256 712d46b0.... No source maps
//   exist (14:409), so this is a re-authoring from the anchor spec and has NOT been compared
//   to the captured bundle.
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../device-register.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:80): cors, envelope, auth, audit,
//   validation. NOT inlined: rate_limit — no rate limiting in the captured bundle (E7).
// TABLES TOUCHED: devices (SELECT, INSERT, UPDATE), audit_logs (INSERT), + profiles / families /
//   family_members via the inlined assertions.
// RPCs CALLED: NONE — capture:82 shows a direct insert/update on `devices` from this handler.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. The device credential arrives as a CLIENT-SUPPLIED
//   64-hex `secret_hash` and is stored as supplied — finding E10, preserved because changing it
//   breaks the Android client contract. The digest is never selected back out of the response
//   (publicDevice() below strips secret_hash and installation_id).
//   No service-role credential reaches any client path.
// *** DEPLOYMENT CAVEAT: the revoked-device relink rule in capture:82 is DIRECTIONALLY AMBIGUOUS
//   and is NOT resolved here. This bundle fails closed (403 device_registration_blocked) behind
//   the single flag ALLOW_RELINK_AFTER_REVOKED_PAIRING. Resolve the ambiguity before deploying —
//   this is one of the three weakest evidence links in the package. ***
// GAPS THIS BUNDLE CANNOT CLOSE: response shape beyond the two stripped columns; the inferred
//   `display_name` reader; `status = 'active'` on success; gateway verify_jwt; A13 (UNSIGNED).
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

function ensureNoError(err: { code?: string; message?: string } | null, fallbackMessage: string): void {
  if (!err) return;
  console.error(`db_error: ${err.code ?? "unknown"}`); // error.code ONLY
  throw new ApiError(500, "db_error", fallbackMessage);
}

// ---------------------------------------------------------------------------
// INLINED: _shared/validation.ts — RE-AUTHORED (capture:170, 12640 chars / 419 lines, never read).
// Only the readers this handler uses are carried. readHex64's pattern is DATABASE-VERIFIED
// (devices_secret_hash_check '^[0-9a-f]{64}$', A3-staging-load-v1.sql:465).
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
// (14:293, 14:340). capture:82 names THREE audit events for this slug, including the DENIAL.
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
// :93-104, :123-127, :139-149, :151-196, :295-338.
//
// IDENTITY SEAM — A13 IS UNSIGNED: one switch (IDENTITY_MODE), one Firebase-UID function that
// fails closed with 503, two verified-email readings in emailVerifiedFor().
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

/**
 * capture:82 — the ONLY captured path where the body legitimately names the family: membership
 * is asserted before any device row is touched (PE-R02, 15:132 -> 403).
 */
async function assertFamilyChild(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "child") throw new ApiError(403, "forbidden", "Not a child of this family.");
  return family;
}

const assertChildMembership = assertFamilyChild;

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../device-register.ts. One action, exactly capture:78.
// ---------------------------------------------------------------------------

/** See ../device-register.ts UNVERIFIED BEHAVIOUR. false = fail closed on ANY revoked match. */
const ALLOW_RELINK_AFTER_REVOKED_PAIRING = false;

const DEVICE_COLUMNS =
  "id, family_id, child_user_id, display_name, platform, android_version, app_version, status, enforcement_mode, policy_version, credential_issued_at, credential_revoked_at, last_seen_at, created_at, updated_at";
// DELIBERATELY ABSENT: secret_hash, installation_id. capture:82 "response strips secret_hash
// and installation_id (H())" — 14:254-255, 14:341. Selecting them out is the control.

/** H() — the credential-stripping projection (capture:82, VERIFIED as a control at 14:341). */
function publicDevice(row: Record<string, unknown> | null): Record<string, unknown> | null {
  if (!row) return null;
  const copy = { ...row };
  delete copy["secret_hash"];
  delete copy["installation_id"];
  return copy;
}

function readInstallationId(body: Record<string, unknown>): string {
  // readInstallationId (capture:82). Bound VERIFIED from devices_installation_id_check,
  // A3-staging-load-v1.sql:461 -> 8..128 characters.
  return readString(body, "installation_id", { min: 8, max: 128 });
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // capture:82 — single action guard. Anything else is a 400 unknown_action, never a no-op
    // (PE-R07, 15:137).
    if (action !== "register") {
      throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
    }

    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    if (profile.role !== "child") {
      throw new ApiError(403, "role_required", "This action requires the child role.");
    }

    const familyId = readUuid(body, "family_id"); // capture:82 readUuid(family_id)
    const installationId = readInstallationId(body);
    const secretHash = readHex64(body, "secret_hash"); // capture:82 readHex64 (A3:...:465)
    const displayName = readString(body, "display_name", { min: 1, max: 80 }); // inferred reader, see header
    const androidVersion = readOptionalString(body, "android_version", { min: 1, max: 40 });
    const appVersion = readOptionalString(body, "app_version", { min: 1, max: 40 });

    // capture:82 — assertChildMembership(family_id FROM THE BODY).
    await assertChildMembership(db, auth.userId, familyId);

    const now = new Date().toISOString();

    // capture:82 / 14:146-147 — the installation id is looked up WITHIN the asserted family.
    const { data: existing, error: ferr } = await db
      .from("devices")
      .select("id, family_id, child_user_id, status, secret_hash, credential_issued_at, credential_revoked_at")
      .eq("family_id", familyId)
      .eq("installation_id", installationId)
      .maybeSingle();
    ensureNoError(ferr, "Could not look up this installation.");

    if (existing) {
      // A row owned by a DIFFERENT child in the same family: 409 device_exists (PE-R04).
      if (existing.child_user_id !== auth.userId) {
        throw new ApiError(409, "device_exists", "That installation already belongs to another child.");
      }

      if (existing.status === "revoked") {
        // capture:82 — device_registration_blocked. Audited BEFORE the 403 so a denial trace
        // exists.
        if (!ALLOW_RELINK_AFTER_REVOKED_PAIRING) {
          await recordAudit(db, {
            eventType: "device_registration_blocked",
            actorUserId: auth.userId,
            familyId,
            deviceId: existing.id,
            targetType: "device",
            targetId: existing.id,
            metadata: { reason: "revoked_installation" },
          });
          throw new ApiError(403, "device_registration_blocked", "This device was revoked and cannot re-register.");
        }
        // UNREACHED while the flag is false — the alternative reading of capture:82 would
        // allow a re-credential here only if a pairing_request for this child has
        // status='approved' and responded_at > existing.credential_revoked_at.
        throw new ApiError(501, "device_registration_blocked", "Revoked-device relink is not specified (capture:82 is ambiguous).");
      }

      // PE-R03 (15:133) — same installation again = re-credential, audit device_recredentialed.
      // devices_revoked_credential_consistency (A3:...:464) forbids status='revoked' with a
      // non-null secret_hash, so status and secret_hash are always written together here.
      const { data: updated, error: uerr } = await db
        .from("devices")
        .update({
          secret_hash: secretHash,
          credential_issued_at: now,
          credential_revoked_at: null,
          status: "active", // INFERRED — see header
          display_name: displayName,
          android_version: androidVersion,
          app_version: appVersion,
        })
        .eq("id", existing.id)
        .eq("family_id", familyId)
        .eq("child_user_id", auth.userId) // three-part scope: service-role has no RLS net
        .select(DEVICE_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not re-credential this device.");
      await recordAudit(db, {
        eventType: "device_recredentialed",
        actorUserId: auth.userId,
        familyId,
        deviceId: existing.id,
        targetType: "device",
        targetId: existing.id,
        metadata: {},
      });
      return ok({ device: publicDevice((updated ?? existing) as Record<string, unknown> | null) });
    }

    // Fresh registration.
    const insertRow: Record<string, unknown> = {
      family_id: familyId,
      child_user_id: auth.userId, // from the verified token only
      installation_id: installationId,
      display_name: displayName,
      secret_hash: secretHash, // capture:82 "secret_hash from client" — finding E10
      credential_issued_at: now,
      status: "active", // INFERRED — see header
      created_at: now,
      updated_at: now,
    };
    if (androidVersion !== null) insertRow["android_version"] = androidVersion;
    if (appVersion !== null) insertRow["app_version"] = appVersion;

    const inserted = await db.from("devices").insert(insertRow).select(DEVICE_COLUMNS);
    if (inserted.error) {
      if (inserted.error.code === "23505") {
        // UNIQUE (family_id, installation_id) or devices_one_active_per_child (A3:...:480, :572).
        throw new ApiError(409, "device_exists", "A device already exists for this installation.");
      }
      // 14:280-283 notes the captured bundle throws the RAW error object on this path
      // (inconsistent with the rest of the codebase). Re-authored with ensureNoError, which
      // is strictly less leaky; disclosed as a deviation in DEPLOYMENT-MAP.md.
      ensureNoError(inserted.error, "Could not register this device.");
    }
    const created = inserted.data?.[0] ?? null;
    await recordAudit(db, {
      eventType: "device_registered",
      actorUserId: auth.userId,
      familyId,
      deviceId: created?.id ?? null,
      targetType: "device",
      targetId: created?.id ?? null,
      metadata: {},
    });
    // capture:82 / PE-R01 (15:131): the response carries NEITHER secret_hash NOR installation_id.
    return ok({ device: publicDevice(created as Record<string, unknown> | null) });
  } catch (err) {
    return errorResponse(err);
  }
});
