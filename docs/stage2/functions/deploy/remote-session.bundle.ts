// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `remote-session`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:134-136 — MINIFIED BUNDLE, 12848 chars / 2 lines, sha256 85e30c3c.... No source
//   maps. 14:50 records this slug's overall verdict as PARTIAL (abuse checks E4, E7).
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../remote-session.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:139): cors, envelope, auth, audit,
//   validation. NOT inlined: rate_limit — the captured bundle has none either (finding E7),
//   which means `request` is UNLIMITED and the child's consent inbox can be flooded.
// TABLES TOUCHED: remote_sessions (INSERT, SELECT, UPDATE), audit_logs (INSERT), + profiles /
//   families / family_members / devices via the inlined assertions.
// RPCs CALLED: *** NONE. *** public.request_remote_session EXISTS and enforces the
//   single-session invariant (advisory lock + 'session_in_progress'), and capture:141 records
//   that the deployed handler does NOT call it — it inserts directly. That is FINDING E4 and it
//   is PRESERVED here, not "fixed": switching to the RPC changes observable behaviour (stacked
//   requests would start returning 409) and is an A7-R decision, not an IMP-5 edit.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY, TURN_SECRET (+ env TURN_HOST, a PLACEHOLDER NAME
//   because the real config key was never captured). No value of any secret appears in this
//   file. TURN_SECRET is mandatory: unset -> 503, never an unsigned credential.
// CONSENT MODEL (the security property that matters for a monitoring product, 14:193-196):
//   a parent can NEVER start, accept, or obtain ICE for a session the child has not accepted.
//   consent_recorded is set true ONLY by the child's accept, and `start`/`ice` both require it.
// GAPS THIS BUNDLE CANNOT CLOSE: the WebRTC SIGNAL RELAY IS NOT IN THIS FUNCTION at all —
//   webrtc_signals exists in the schema but no capture anchor touches it and no action name for
//   signalling exists, so clients must reach it through PostgREST, which depends on auth.uid()
//   and therefore BREAKS under the unsigned A13. Also unclosed: the audit event_type strings for
//   respond/start/end (INFERRED from PE-S01's wording), all six response shapes, ended_reason
//   wording, gateway verify_jwt.
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
// Carried subset: readString / readOptionalString / readBoolean / readEnum / readUuid / clampInt.
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

function readUuid(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 36, max: 36 });
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)) bad(`${key} must be a UUID.`);
  return v.toLowerCase();
}

function clampInt(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
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
// THE TRUST BOUNDARY: service_role means RLS is inert (14:245-246). Anchors preserved: :51-56,
// :68-75, :92, :93-104, :123-127, :139-149, :151-196, :266-289.
//
// IDENTITY SEAM — A13 IS UNSIGNED: one switch (IDENTITY_MODE), one Firebase-UID function that
// fails closed with 503, two verified-email readings in emailVerifiedFor(). NOTE: this slug is
// the one most exposed to A13, because the webrtc_signals RLS policies are keyed on auth.uid()
// (A3:...:761, :773) and this function never proxies them.
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

/** :266-289 — the device's family is authoritative; a body family_id is never consulted. */
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
// HANDLER — re-authored from ../remote-session.ts. Six actions, exactly capture:136.
// ---------------------------------------------------------------------------

const REQUEST_TTL_MINUTES = 10; // capture:141 "expires_at = now + 10 min"
const ACCEPTED_TTL_MINUTES = 30; // capture:143 "expires_at now + 30 min"
const PENDING_LIST_LIMIT = 50; // capture:142 "list up to 50"
const TURN_TTL_MIN_SECONDS = 60; // capture:146 "TTL clamp 60..86400"
const TURN_TTL_MAX_SECONDS = 86_400;
const TURN_TTL_DEFAULT_SECONDS = 600; // capture:146 "default 600"
const SESSION_KINDS = ["audio", "video"] as const; // VERIFIED: A3:...:481 + the quoted RPC body
const TERMINAL_SESSION_STATUSES = ["declined", "ended", "expired", "failed"] as const; // 14:209

const SESSION_COLUMNS =
  "id, family_id, device_id, parent_user_id, child_user_id, kind, status, requested_at, accepted_at, started_at, ended_at, expires_at, ended_by, ended_reason, consent_recorded, session_nonce, created_at";

const b64 = (bytes: ArrayBuffer): string => btoa(String.fromCharCode(...Array.from(new Uint8Array(bytes))));

/** TURN credential minting: HMAC-SHA1(TURN_SECRET, "<expiry>:<user id>") (capture:146). */
async function mintTurnCredential(username: string): Promise<string> {
  const secret = Deno.env.get("TURN_SECRET"); // NAME only; never logged, never returned
  if (!secret) throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  return b64(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(username)));
}

function isoIn(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true }); // capture:138
    const uid = auth.userId;

    // ---- request (parent only) -------------------------------------------------------
    if (action === "request") {
      requireRole(profile, "parent"); // capture:141 — TE-12 (15:69): the child gets 403 role_required
      const deviceId = readUuid(body, "device_id");
      // capture:141 — requireActiveDeviceForParent(device_id): family comes from the DEVICE.
      // TE-04 (15:61): another family's device -> 403 forbidden.
      const device = await requireActiveDeviceForParent(db, uid, deviceId);
      const kind = readEnum(body, "kind", SESSION_KINDS); // PE-S09 (15:193): kind "screen" -> 400

      // capture:141 — DIRECT INSERT, deliberately bypassing public.request_remote_session.
      // Finding E4 PRESERVED (see header): the RPC's advisory lock and 'session_in_progress'
      // check never run on this path, so pending requests stack (PE-S08, 15:192).
      const { data, error } = await db
        .from("remote_sessions")
        .insert({
          family_id: device.family_id, // from the device row
          device_id: device.id,
          parent_user_id: uid, // from the verified token — never a body field
          child_user_id: device.child_user_id, // from the device row (capture:141)
          kind,
          status: "requested", // column default too (A3:...:316)
          requested_at: new Date().toISOString(),
          expires_at: isoIn(REQUEST_TTL_MINUTES), // satisfies remote_sessions_pending_expiry_check, A3:...:482
          consent_recorded: false, // capture:141 — consent is NOT assumed
        })
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(error, "Could not create the session request.");
      await recordAudit(db, {
        eventType: "session_requested", // capture:141 (VERIFIED name)
        actorUserId: uid,
        familyId: device.family_id,
        deviceId: device.id,
        targetType: "remote_session",
        targetId: data?.id ?? null,
        metadata: { kind },
      });
      return ok({ session: data });
    }

    // ---- pending_child (the child's consent inbox) ----------------------------------
    if (action === "pending_child") {
      requireRole(profile, "child"); // capture:138
      const nowIso = new Date().toISOString();
      // capture:142 — expire stale requested rows for THIS child first, then list.
      // remote_sessions_transition_guard is BEFORE UPDATE OF status and raises only on a
      // terminal -> live move (14:209), so requested -> expired is permitted by the trigger.
      await db
        .from("remote_sessions")
        .update({ status: "expired" })
        .eq("child_user_id", uid)
        .eq("status", "requested")
        .lte("expires_at", nowIso);
      const { data, error } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("child_user_id", uid)
        .eq("status", "requested")
        .gt("expires_at", nowIso)
        .order("requested_at", { ascending: false })
        .limit(PENDING_LIST_LIMIT); // PE-S10 (15:193): 60 seeded rows -> at most 50 returned
      ensureNoError(error, "Could not list session requests.");
      return ok({ sessions: data ?? [] });
    }

    // ---- respond (child only) --------------------------------------------------------
    if (action === "respond") {
      requireRole(profile, "child"); // capture:138; TE-13 (15:70): a parent gets 403 role_required
      const sessionId = readUuid(body, "session_id");
      const accept = readBoolean(body, "accept");
      if (accept === null) throw new ApiError(400, "validation_error", "accept must be a boolean.");

      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      // capture:143 — the child must equal session.child_user_id.
      if (session.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your session.");

      // capture:143 — idempotent for accepted/declined repeats.
      if (session.status !== "requested") {
        const sameAnswer = (accept && session.status === "accepted") || (!accept && session.status === "declined");
        if (sameAnswer) return ok({ session, idempotent: true }); // PE-S02 (15:185)
        throw new ApiError(409, "session_not_open", "This session is not awaiting a response."); // PE-S03 (15:186)
      }
      if (new Date(session.expires_at).getTime() <= Date.now()) {
        await db.from("remote_sessions").update({ status: "expired" }).eq("id", sessionId).eq("status", "requested");
        throw new ApiError(410, "session_expired", "This session request has expired.");
      }

      const patch: Record<string, unknown> = accept
        ? {
            status: "accepted",
            accepted_at: new Date().toISOString(),
            consent_recorded: true, // capture:143 — consent is recorded ONLY by the child's accept
            session_nonce: crypto.randomUUID(), // capture:143 — randomUUID, uuid column (A3:...:325)
            expires_at: isoIn(ACCEPTED_TTL_MINUTES),
          }
        : { status: "declined", ended_at: new Date().toISOString(), ended_by: uid, consent_recorded: false };

      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update(patch)
        .eq("id", sessionId)
        .eq("child_user_id", uid)
        .eq("status", "requested") // capture:143 — compare-and-set
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not respond to the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        return ok({ session: again, idempotent: true }); // lost the race
      }
      await recordAudit(db, {
        eventType: accept ? "session_accepted" : "session_declined", // INFERRED names, see header
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: { consent_recorded: accept },
      });
      return ok({ session: updated });
    }

    // ---- start (child only, consent-gated) ------------------------------------------
    if (action === "start") {
      requireRole(profile, "child"); // capture:144
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session || session.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your session.");
      if (new Date(session.expires_at).getTime() <= Date.now() && session.status === "accepted") {
        await db.from("remote_sessions").update({ status: "expired" }).eq("id", sessionId).eq("status", "accepted");
        throw new ApiError(410, "session_expired", "This session has expired."); // PE-S04 (15:187)
      }
      // capture:144 — requires status accepted AND consent_recorded. TE-14 (15:71) / PE-S05.
      if (session.status !== "accepted" || session.consent_recorded !== true) {
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }
      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update({ status: "active", started_at: new Date().toISOString() })
        .eq("id", sessionId)
        .eq("child_user_id", uid)
        .eq("status", "accepted") // capture:144 — compare-and-set
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not start the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        if (again?.status === "active") return ok({ session: again, idempotent: true }); // CI-04 (15:213)
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }
      await recordAudit(db, {
        eventType: "session_started", // INFERRED name
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: {},
      });
      return ok({ session: updated });
    }

    // ---- end (either participant) ----------------------------------------------------
    if (action === "end") {
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      // capture:145 — either participant; 14:136-137 parent OR child must equal the caller.
      if (session.parent_user_id !== uid && session.child_user_id !== uid) {
        throw new ApiError(403, "forbidden", "Not your session.");
      }
      // capture:145 — terminal states returned as-is (PE-S07: both calls 200).
      if ((TERMINAL_SESSION_STATUSES as readonly string[]).includes(session.status)) {
        return ok({ session, idempotent: true });
      }
      const reason = readOptionalString(body, "reason", { min: 1, max: 200 }); // A3:...:480 bound
      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update({
          status: "ended",
          ended_at: new Date().toISOString(),
          ended_by: uid,
          ended_reason: reason,
        })
        .eq("id", sessionId)
        .in("status", ["requested", "accepted", "active"]) // capture:145
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not end the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        return ok({ session: again, idempotent: true });
      }
      await recordAudit(db, {
        eventType: "session_ended", // INFERRED name
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: { by: session.parent_user_id === uid ? "parent" : "child", reason },
      });
      return ok({ session: updated });
    }

    // ---- ice (participant, consent-gated, TURN credential) ---------------------------
    if (action === "ice") {
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      if (session.parent_user_id !== uid && session.child_user_id !== uid) {
        throw new ApiError(403, "forbidden", "Not your session."); // PE-S06 (15:189)
      }
      // capture:146 — status accepted|active AND consent_recorded required. PE-S05 (15:188):
      // ICE before consent is a 409, never a credential.
      if (!["accepted", "active"].includes(session.status) || session.consent_recorded !== true) {
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }

      const ttl = clampInt(
        typeof body["ttl_seconds"] === "number" ? (body["ttl_seconds"] as number) : TURN_TTL_DEFAULT_SECONDS,
        TURN_TTL_MIN_SECONDS,
        TURN_TTL_MAX_SECONDS,
      );
      const expiry = Math.floor(Date.now() / 1000) + ttl;
      const username = `${expiry}:${uid}`; // capture:146 exact form
      const credential = await mintTurnCredential(username);
      const host = Deno.env.get("TURN_HOST"); // CONFIG, name NOT captured — see header
      if (!host) throw new ApiError(503, "server_misconfigured", "Server is not configured.");

      return ok({
        ice_servers: [
          { urls: [`turn:${host}:3478?transport=udp`, `turn:${host}:3478?transport=tcp`], username, credential },
        ],
        ttl_seconds: ttl,
        session_id: sessionId,
      });
    }

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
