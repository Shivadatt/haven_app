// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `device-policy`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:86-90 — MINIFIED BUNDLE, 11174 chars / 2 lines, sha256 3efdb19b.... No source maps.
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../device-policy.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:93): cors, envelope, auth, audit,
//   validation. NOT inlined: rate_limit — no rate limiting in the captured bundle (E7).
// TABLES TOUCHED: profiles / families / family_members / devices (SELECT via auth), audit_logs
//   (INSERT). device_policies and device_commands are written INSIDE
//   public.apply_policy_version — this handler never touches them directly.
// RPCs CALLED: public.apply_policy_version.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. No values anywhere; no service-role credential is
//   reachable from any client path.
//
// *** BLOCKED ON SPEC — THIS BUNDLE IS NOT DEPLOYABLE FOR ITS ONLY ACTION AS WRITTEN ***
//   capture:95 names the three policy key allowlists as the minified constants `V`, `X` and `Z`.
//   Their CONTENTS ARE NOWHERE IN THE EVIDENCE (verified absence: no file in the repository names
//   a single policy key; grep of S2-A6-child-app-report.md for
//   app_rules|screen_time|bedtime|allowlist|policy.|content_filter returns no matches).
//   An empty allowlist would reject every policy; a plausible invented list would be exactly the
//   "invented business logic" the brief forbids — the policy allowlist IS the enforcement surface
//   of a parental-control product. So everything evidenced AROUND the allowlist is implemented
//   (auth, device scope, 256 KB cap, array caps, RPC call, idempotency/audit interaction) and the
//   allowlist itself fails closed with 501 policy_schema_missing.
//   FIX = a one-line edit to the three constants below once the owner supplies V/X/Z.
//   The bounds the missing keys carry are recorded in assertPolicyShape's comments so nothing is
//   lost: screen-time 1..1440 min, minute-of-day 0..1439, weekday 1..7 with duplicate rejection,
//   bedtime needs both start and end (14:227, 15:148).
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
// POST-only, object-only, 512 KB enforced twice, action 1-64, no-store, name-only 500 logging
// (14:209-228, 14:269-283).
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

// ---------------------------------------------------------------------------
// INLINED: _shared/validation.ts — RE-AUTHORED (capture:170, 12640 chars / 419 lines, never read).
// Carried subset: readString / readUuid / readObject / assertAllowedKeys.
// 14:344 records the "'not allowed'" rejection style as VERIFIED for this bundle's family.
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

function readUuid(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 36, max: 36 });
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)) bad(`${key} must be a UUID.`);
  return v.toLowerCase();
}

function readObject(body: Record<string, unknown>, key: string, maxJsonChars: number): Record<string, unknown> {
  const v = body[key];
  if (v === null || typeof v !== "object" || Array.isArray(v)) bad(`${key} must be a JSON object.`);
  if (JSON.stringify(v).length > maxJsonChars) bad(`${key} is too large`); // PE-PL04, 15:146
  return v as Record<string, unknown>;
}

function assertAllowedKeys(obj: Record<string, unknown>, allowed: readonly string[], path: string): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.includes(k)) bad(`${path}.${k} is not allowed`); // 14:222, 14:344
  }
}

// ---------------------------------------------------------------------------
// INLINED: _shared/audit.ts — RE-AUTHORED (capture:165, 1101 chars / 38 lines, never read).
// A failed insert THROWS (500 audit_failed) (14:293, 14:340).
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
// THE TRUST BOUNDARY: service_role means RLS is inert (14:245-246). Anchors preserved:
// :51-56, :68-75, :92, :93-104, :123-127, :139-149, :151-196, :266-289.
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

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

/** :266-289 — family_id is taken from the DEVICE ROW, never from the body (TE-03, PE-PL07). */
async function requireActiveDeviceForParent(db: any, userId: string, deviceId: string): Promise<any> {
  const { data: device, error } = await db.from("devices").select(DEVICES_SELECT).eq("id", deviceId).maybeSingle();
  if (error) {
    console.error(`device_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!device) throw new ApiError(403, "forbidden", "Device not available.");
  if (device.status !== "active") throw new ApiError(403, "forbidden", "Device is not active.");
  await assertFamilyParent(db, userId, device.family_id);
  return device;
}

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../device-policy.ts. One action, exactly capture:91.
// ---------------------------------------------------------------------------

const POLICY_JSON_MAX = 256 * 1024; // capture:95 "policy JSON size cap 256*1024"
const POLICY_ARRAY_MAX = 200; // capture:95 "arrays capped 200"
const APP_RULES_MAX = 100; // capture:95 "app_rules 100" (the name appears in the capture itself)

// ---- THE MISSING SPEC (see the BLOCKED ON SPEC banner in the header) --------
const TOP_LEVEL_POLICY_KEYS: readonly string[] = []; // bundle constant V — NOT CAPTURED
const SUB_OBJECT_KEYS: readonly string[] = []; // bundle constant X — NOT CAPTURED
const APP_RULE_KEYS: readonly string[] = []; // bundle constant Z — NOT CAPTURED

/**
 * assertPolicyShape — the key-agnostic part of check 10 that IS evidenced.
 * The key-name-dependent rules are recorded here rather than dropped:
 *   - screen-time limits: integers 1..1440 minutes            (14:227) — key name unknown
 *   - window minute values: integers 0..1439                   (14:227) — key name unknown
 *   - weekday values: integers 1..7, duplicates rejected        (14:227) — key name unknown
 *   - bedtime: a start without an end is a 400                 (15:148)  — key names unknown
 * APP_RULE_KEYS is reserved for the per-rule key check once Z is supplied.
 */
function assertPolicyShape(node: unknown, path: string, root: boolean): void {
  if (Array.isArray(node)) {
    const cap = path.endsWith("app_rules") ? APP_RULES_MAX : POLICY_ARRAY_MAX;
    if (node.length > cap) {
      throw new ApiError(400, "validation_error", `${path} must contain at most ${cap} items.`);
    }
    node.forEach((item, i) => assertPolicyShape(item, `${path}[${i}]`, false));
    return;
  }
  if (node !== null && typeof node === "object") {
    const obj = node as Record<string, unknown>;
    if (root) assertAllowedKeys(obj, TOP_LEVEL_POLICY_KEYS, "policy");
    else assertAllowedKeys(obj, SUB_OBJECT_KEYS, path);
    for (const k of Object.keys(obj)) assertPolicyShape(obj[k], `${path}.${k}`, false);
  }
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // capture:95 — single action guard (minified `if(I(e)!=="update") throw unknown_action`).
    if (action !== "update") {
      throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
    }

    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    requireRole(profile, "parent"); // capture:95 — TE-06 / PE-PL07
    const deviceId = readUuid(body, "device_id");
    const device = await requireActiveDeviceForParent(db, auth.userId, deviceId); // capture:95

    // PE-PL04 (15:146) -> 400 "policy is too large". readObject enforces the 256 KB cap.
    const policy = readObject(body, "policy", POLICY_JSON_MAX);
    const key = (() => {
      const v = body["idempotency_key"];
      if (typeof v !== "string" || v.length < 1 || v.length > 128) {
        throw new ApiError(400, "validation_error", "idempotency_key must be 1 to 128 characters.");
      }
      return v;
    })();

    // BLOCKED ON SPEC: with no captured key sets, assertPolicyShape would reject EVERY policy
    // (empty allowlist) — which is fail-closed but useless. Rather than ship either an
    // everything-rejects or an everything-admits validator, refuse explicitly.
    if (TOP_LEVEL_POLICY_KEYS.length === 0) {
      return fail(
        501,
        "policy_schema_missing",
        "The policy key allowlists (bundle constants V/X/Z, capture:95) are not present in any " +
          "available evidence. This re-authored bundle is NOT deployable for `update` until the " +
          "owner supplies TOP_LEVEL_POLICY_KEYS / SUB_OBJECT_KEYS / APP_RULE_KEYS.",
      );
    }
    assertPolicyShape(policy, "policy", true);

    // capture:95 — rpc apply_policy_version, p_actor = the verified subject (never a body field).
    const { data, error } = await db.rpc("apply_policy_version", {
      p_device_id: device.id,
      p_policy: policy,
      p_actor: auth.userId,
      p_idempotency_key: key,
    });
    if (error) {
      console.error(`rpc_apply_policy_version: ${error.code ?? "unknown"}`);
      const m = (error.message ?? "").toLowerCase();
      // 14:277 — mapped by SUBSTRING to fixed messages; the RPC message is never forwarded.
      // PE-PL02 expects the body "policy.<key> is not allowed", but the offending key lives
      // in the RPC's message, which 14:277 forbids forwarding. A fixed sentence is used and
      // the missing key name is recorded as an UNVERIFIED detail of the error contract.
      if (m.includes("not allowed")) {
        throw new ApiError(400, "validation_error", "policy key is not allowed");
      }
      if (m.includes("too large")) throw new ApiError(400, "validation_error", "policy is too large");
      throw new ApiError(500, "internal_error", "Could not apply the policy.");
    }

    // capture:95 — "idempotent result skips audit" (PE-PL05, 15:147: no duplicate audit row).
    const idempotent = !!(
      data &&
      typeof data === "object" &&
      ((data as Record<string, unknown>)["idempotent"] === true ||
        (data as Record<string, unknown>)["idempotency"] === "replayed")
    );
    if (!idempotent) {
      await recordAudit(db, {
        eventType: "policy_updated", // UNVERIFIED name — no anchor gives the event_type string
        actorUserId: auth.userId,
        familyId: device.family_id,
        deviceId: device.id,
        targetType: "policy",
        targetId: null,
        metadata: { idempotency_key: key },
      });
    }
    // UNVERIFIED BEHAVIOUR — response shape not captured.
    return ok({ result: data ?? null, idempotent });
  } catch (err) {
    return errorResponse(err);
  }
});
