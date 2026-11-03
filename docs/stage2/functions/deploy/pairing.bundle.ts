// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `pairing`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:27 grades this slug as "readable TypeScript" (972 lines / 33993 chars, sha256
//   427d419d...), but NO repository file holds that text: supabase/functions/ is ABSENT
//   (13-edge-function-source-inventory.md §1; capture-20261030.json:173-177
//   functions_directory "absent", import_map_or_deno_json "absent"), the pairing/ subdirectory
//   implied by capture operations_performed[10] is empty (S2-A4 A4-F13), and S2-A7 T-07 records
//   that "every `pairing/index.ts:<n>` anchor resolves to a dashboard capture, not to a
//   repository file". Only the anchor LINE NUMBERS survived. This bundle is therefore a
//   re-authoring even for the slug the brief calls captured.
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../pairing.ts (same slug, same handler).
//
// INLINED MODULES — ALL SIX, per capture:33: cors, envelope, validation, audit, auth,
//   rate_limit. pairing is the ONLY function that uses rate_limit (14:232-237).
//   NOTE ON `audit`: capture:33 lists audit in this function's import set, yet no capture
//   anchor for pairing names a recordAudit call and functions-and-triggers.md:80's guard
//   vocabulary has no audit helper. The module is inlined BELOW TO MATCH THE CAPTURED IMPORT
//   SET but is deliberately NEVER CALLED — writing audit rows here would be inventing logic.
//   This import-vs-anchor tension is disclosed in ../pairing.ts.
// TABLES TOUCHED: child_contact_ids, device_pairing_tokens, pairing_attempts, pairing_requests,
//   family_members, families, profiles, devices, audit_logs (module inlined, not called).
// RPCs CALLED: public.create_pairing_request, public.create_pairing_invite,
//   public.respond_pairing_request, public.unlink_child.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY, PAIRING_HASH_PEPPER. No values. A9 records both
//   as NOT CREATED; without the pepper, identifierHash degrades to SHA-256 (finding E6) and
//   attempt rows become forgeable from a dump — that is disclosed here, not hidden.
//   No service-role credential is reachable from any client path: createClient runs only here.
// GAPS THIS BUNDLE CANNOT CLOSE: response body shapes (never captured); the pairing:555-560
//   code-vs-Child-ID dispatch; the A13 identity decision (UNSIGNED); gateway verify_jwt.
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
// The 30-symbol alphabet is RECOVERED FROM THE DATABASE, not invented: child_contact_ids
// CHECK contact_id ~ '^PC[23456789ABCDEFGHJKMNPQRSTVWXYZ]{8}$' (g1-q5, emitted at
// A3-staging-load-v1.sql:437) — exactly 30 symbols, matching "8 characters from a 30-symbol
// alphabet" and 30^8 ~ 6.6e11 (14:166-167, 16:247).
// PLACEHOLDER, NOT EVIDENCE: the Android package-name regex (14:224 says only "package regex").
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

function readBoolean(body: Record<string, unknown>, key: string): boolean | null {
  const v = body[key];
  if (v === undefined || v === null) return null;
  if (typeof v !== "boolean") bad(`${key} must be a boolean.`);
  return v;
}

const validatorEncoder = new TextEncoder();

function toHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(value: string): Promise<string> {
  return toHex(await crypto.subtle.digest("SHA-256", validatorEncoder.encode(value)));
}

async function hmacSha256Hex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", validatorEncoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return toHex(await crypto.subtle.sign("HMAC", key, validatorEncoder.encode(value)));
}

let pepperWarned = false;

/** HMAC with PAIRING_HASH_PEPPER; SILENT SHA-256 FALLBACK when unset (finding E6, preserved). */
async function identifierHash(value: string, pepper?: string): Promise<string> {
  const p = pepper ?? Deno.env.get("PAIRING_HASH_PEPPER") ?? ""; // NAME only
  if (p.length === 0) {
    if (!pepperWarned) {
      pepperWarned = true;
      console.warn("pairing_hash_pepper_missing");
    }
    return sha256Hex(value);
  }
  return hmacSha256Hex(p, value);
}

const IDENTIFIER_ALPHABET = "23456789ABCDEFGHJKMNPQRSTVWXYZ"; // 30 symbols, DB-recovered
const IDENTIFIER_LENGTH = 8;
const CONTACT_ID_PREFIX = "PC";
const CONTACT_ID_RE = new RegExp(`^${CONTACT_ID_PREFIX}[${IDENTIFIER_ALPHABET}]{8}$`); // == the DB CHECK
const PAIRING_CODE_RE = new RegExp(`^[${IDENTIFIER_ALPHABET}]{8}$`);

function randomIdentifier(length: number = IDENTIFIER_LENGTH): string {
  const out: string[] = [];
  const buf = new Uint8Array(64);
  while (out.length < length) {
    crypto.getRandomValues(buf);
    for (let i = 0; i < buf.length && out.length < length; i++) {
      const b = buf[i];
      if (b < 240) out.push(IDENTIFIER_ALPHABET[b % IDENTIFIER_ALPHABET.length]); // 256 % 30 = 16 -> reject 240..255
    }
  }
  return out.join("");
}

function newPairingCode(): string {
  return randomIdentifier();
}

function newContactId(): string {
  return CONTACT_ID_PREFIX + randomIdentifier();
}

function normalizeIdentifier(value: string): string {
  return value.toUpperCase().replace(/[\s-]/g, "");
}

function isContactIdForm(normalized: string): boolean {
  return normalized.startsWith(CONTACT_ID_PREFIX);
}

// ---------------------------------------------------------------------------
// INLINED: _shared/audit.ts — RE-AUTHORED (capture:165, 1101 chars / 38 lines, never read).
// INLINED ONLY TO REPRODUCE capture:33's import set. NEVER CALLED FROM THIS BUNDLE: no pairing
// anchor evidences an audit write (see the header note). A deployed pairing that DID audit is
// possible; this package does not guess which events it logged.
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

// deno-lint-ignore no-unused-vars
void recordAudit; // intentional: inlined-but-uncalled, see the block above

// ---------------------------------------------------------------------------
// INLINED: _shared/rate_limit.ts — RE-AUTHORED (capture:169, 7148 chars / 211 lines, never read).
// capture:169 gives the quota table VERBATIM: "Pairing-only limits: 5 failed attempts per
// parent / 10 per identifier in 10 min, 5 live codes per 24 h, 10 creations per hour,
// 3 pending invites, 10 invites per 24 h. All counts are read-then-act."
// read-then-act IS the deployed weakness (finding E8, CI-01 at 15:211) — PRESERVED, NOT FIXED:
// changing it is an A7-R decision, not an IMP-5 edit. Nothing is cached in-process, so under
// load the effective ceiling is limit x concurrent isolates (docs/stage2/parts/F-e6-e7.md).
// Anchors: 14:168-171 (rate_limit.ts:54-93, :110-151, :153-211); call sites pairing 567,
// 771-772 (capture:37-38).
// ---------------------------------------------------------------------------

const REDEEM_WINDOW_MINUTES = 10; // 14:168
const MAX_FAILED_PER_PARENT_PER_WINDOW = 5; // capture:169
const MAX_FAILED_PER_IDENTIFIER_PER_WINDOW = 10; // capture:169
const MAX_LIVE_CODES_PER_24H = 5; // capture:169
const MAX_CREATIONS_PER_HOUR = 10; // capture:169
const MAX_PENDING_INVITES = 3; // capture:169
const MAX_INVITES_PER_24H = 10; // capture:169

function minutesAgo(minutes: number, now: Date): string {
  return new Date(now.getTime() - minutes * 60_000).toISOString();
}

function retrySecondsFrom(oldestIso: string | null, windowMinutes: number, now: Date): number {
  if (!oldestIso) return windowMinutes * 60;
  const t = new Date(oldestIso).getTime();
  if (Number.isNaN(t)) return windowMinutes * 60;
  return Math.max(1, Math.ceil((t + windowMinutes * 60_000 - now.getTime()) / 1000));
}

async function countFailed(
  db: any,
  filters: Array<[string, string]>,
  since: string,
): Promise<{ n: number; oldest: string | null }> {
  let q = db
    .from("pairing_attempts")
    .select("attempted_at", { count: "exact", head: true })
    .eq("success", false)
    .gte("attempted_at", since);
  for (const [col, val] of filters) q = q.eq(col, val);
  const { count, error } = await q;
  if (error) {
    console.error(`rate_count: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  let oq = db
    .from("pairing_attempts")
    .select("attempted_at")
    .eq("success", false)
    .gte("attempted_at", since)
    .order("attempted_at", { ascending: true })
    .limit(1);
  for (const [col, val] of filters) oq = oq.eq(col, val);
  const { data: oldestRow } = await oq.maybeSingle();
  return { n: count ?? 0, oldest: oldestRow?.attempted_at ?? null };
}

/**
 * assertPairingRedeemAllowed — rate_limit.ts:54-93, called BEFORE the token lookup at
 * pairing:567 so a throttled caller cannot probe code validity at all. `attemptHash` is
 * identifierHash(normalized) — the KEYED digest, deliberately different from the token row's
 * plain SHA-256 code_hash (pairing:562-566, finding E5).
 */
async function assertPairingRedeemAllowed(db: any, parentUserId: string, attemptHash: string): Promise<void> {
  const now = new Date();
  const since = minutesAgo(REDEEM_WINDOW_MINUTES, now);

  const perParent = await countFailed(db, [["parent_user_id", parentUserId]], since);
  if (perParent.n >= MAX_FAILED_PER_PARENT_PER_WINDOW) {
    throw new ApiError(429, "rate_limited", "Too many attempts. Try again later.", {
      retry_after_seconds: retrySecondsFrom(perParent.oldest, REDEEM_WINDOW_MINUTES, now),
    });
  }

  const perIdentifier = await countFailed(db, [["code_hash", attemptHash]], since);
  if (perIdentifier.n >= MAX_FAILED_PER_IDENTIFIER_PER_WINDOW) {
    throw new ApiError(429, "rate_limited", "Too many attempts. Try again later.", {
      retry_after_seconds: retrySecondsFrom(perIdentifier.oldest, REDEEM_WINDOW_MINUTES, now),
    });
  }
}

/** recordPairingAttempt — pairing:771-772 and every redeem failure branch (14:169). */
async function recordPairingAttempt(
  db: any,
  input: { parentUserId: string; codeHash: string; success: boolean },
): Promise<void> {
  const { error } = await db.from("pairing_attempts").insert({
    parent_user_id: input.parentUserId,
    code_hash: input.codeHash,
    attempted_at: new Date().toISOString(),
    success: input.success,
  });
  if (error) {
    console.error(`attempt_record: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
}

/**
 * assertPairingCodeCreationAllowed — rate_limit.ts:110-151.
 * "5 live codes per 24 h" = purpose 'code' rows still active in the window; "10 creations per
 * hour" = every purpose 'code' row created in the hour, live or not, so mint-and-expire cannot
 * bypass it. UNVERIFIED: which identity these two windows key on (INFERRED the minting child,
 * schema-columns.md:72).
 */
async function assertPairingCodeCreationAllowed(db: any, childUserId: string): Promise<void> {
  const now = new Date();
  const { count: live, error: e1 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "code")
    .eq("status", "active")
    .gte("created_at", minutesAgo(24 * 60, now));
  if (e1) {
    console.error(`rate_count: ${e1.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((live ?? 0) >= MAX_LIVE_CODES_PER_24H) {
    throw new ApiError(429, "rate_limited", "Too many pairing codes.", { retry_after_seconds: 60 * 60 });
  }

  const { count: recent, error: e2 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "code")
    .gte("created_at", minutesAgo(60, now));
  if (e2) {
    console.error(`rate_count: ${e2.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((recent ?? 0) >= MAX_CREATIONS_PER_HOUR) {
    throw new ApiError(429, "rate_limited", "Too many pairing codes.", { retry_after_seconds: 60 * 60 });
  }
}

/**
 * assertInviteQuotaAllowed — rate_limit.ts:153-211. "at most 3 pending and 10 per 24 h per
 * child" (14:171). Pending invite = device_pairing_tokens purpose 'invite' still 'active'
 * (status vocabulary VERIFIED A3-staging-load-v1.sql:451 active|redeemed|revoked|expired).
 */
async function assertInviteQuotaAllowed(db: any, childUserId: string): Promise<void> {
  const now = new Date();
  const { count: pending, error: e1 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "invite")
    .eq("status", "active")
    .gt("expires_at", now.toISOString());
  if (e1) {
    console.error(`rate_count: ${e1.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((pending ?? 0) >= MAX_PENDING_INVITES) {
    throw new ApiError(429, "rate_limited", "Too many pending invites.", { retry_after_seconds: 60 * 60 });
  }

  const { count: perDay, error: e2 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "invite")
    .gte("created_at", minutesAgo(24 * 60, now));
  if (e2) {
    console.error(`rate_count: ${e2.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((perDay ?? 0) >= MAX_INVITES_PER_24H) {
    const { data: oldestInvite } = await db
      .from("device_pairing_tokens")
      .select("created_at")
      .eq("child_user_id", childUserId)
      .eq("purpose", "invite")
      .gte("created_at", minutesAgo(24 * 60, now))
      .order("created_at", { ascending: true })
      .limit(1)
      .maybeSingle();
    throw new ApiError(429, "rate_limited", "Too many invites.", {
      retry_after_seconds: retrySecondsFrom(oldestInvite?.created_at ?? null, 24 * 60, now),
    });
  }
}

// ---------------------------------------------------------------------------
// INLINED: _shared/auth.ts — RE-AUTHORED (capture:166, 9920 chars / 338 lines, never read).
// THE TRUST BOUNDARY: every query here runs as service_role, so RLS is inert (14:245-246) and
// a missing predicate is not caught by the database. Line anchors preserved: :51-56, :49-66,
// :68-75, :92, :93-104, :123-127, :139-149, :151-196, :266-289, :295-338, :325-330.
//
// IDENTITY SEAM — A13 IS UNSIGNED. IDENTITY_MODE is the single switch; the Firebase-UID
// assumption lives in exactly ONE function (resolveFirebaseIdentity) and fails closed.
// Verified-email has BOTH readings behind emailVerifiedFor(), per S2-EXEC-08 §2(3).
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

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../pairing.ts. Nine actions, exactly capture:31's set.
// ---------------------------------------------------------------------------

const CODE_TTL_MINUTES = 10; // capture:35 — "41: CODE_TTL_MINUTES = 10"
const INVITE_TTL_MINUTES = 24 * 60; // capture:35 — "43: INVITE_TTL_MINUTES = 24 * 60"
const MAX_ATTEMPTS_PER_CODE = 10; // == device_pairing_tokens.max_attempts DEFAULT 10 (A3-staging-load-v1.sql:202)
const PENDING_LIST_LIMIT = 50; // INFERRED from 16:192 (sibling endpoint), not captured for pairing

const TOKEN_COLUMNS =
  "id, child_user_id, code_hash, expires_at, redeemed_at, redeemed_by, status, attempts, max_attempts, created_at, created_by, purpose";
const REQUEST_COLUMNS =
  "id, token_id, family_id, parent_user_id, child_user_id, status, created_at, expires_at, responded_at";

/**
 * The uniform refusal. pairing:571,583,598,625,773 all return the same body for unknown /
 * expired / malformed / over-attempt identifiers (14:164-165, 14:334). Never differentiate
 * these branches: any variance is an enumeration oracle.
 */
function invalidIdentifier(): never {
  // 15:89-93 maps this body to 400 `invalid_code` for both an unknown and an expired code.
  throw new ApiError(400, "invalid_code", "Pairing identifier is not valid.");
}

function ttl(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    const uid = auth.userId;

    switch (action) {
      // ---- get_contact_id -------------------------------------------------------------
      case "get_contact_id": {
        requireRole(profile, "child"); // 14:114
        const { data: existing, error } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id, created_at, rotated_at")
          .eq("child_user_id", uid)
          .maybeSingle();
        ensureNoError(error, "Could not read the contact id.");
        if (existing) return ok({ contact_id: existing.contact_id });
        // PE-P01 (15:88): no row yet -> 200, `PC` + 8 chars, row created.
        let contactId = newContactId();
        for (let attempt = 0; attempt < 3; attempt++) {
          const ins = await db
            .from("child_contact_ids")
            .insert({ child_user_id: uid, contact_id: contactId, created_at: new Date().toISOString() });
          if (!ins.error) break;
          if (ins.error.code !== "23505") ensureNoError(ins.error, "Could not create the contact id.");
          // UNIQUE collision on contact_id (schema-columns.md:28): draw again.
          contactId = newContactId();
          if (attempt === 2) throw new ApiError(500, "internal_error", "Could not create the contact id.");
        }
        return ok({ contact_id: contactId });
      }

      // ---- create ---------------------------------------------------------------------
      case "create": {
        requireRole(profile, "child");
        await assertPairingCodeCreationAllowed(db, uid); // capture:33 rate_limit; 14:171
        const code = newPairingCode();
        const normalized = normalizeIdentifier(code);
        // 16:229-237 — VERBATIM from pairing:562-564, quoted so the two-digest design is not
        // "simplified" away by a later reader:
        //   // Two digests on purpose: the token row keeps plain SHA-256 so codes
        //   // issued before this change still redeem, while attempt records use
        //   // the keyed digest so a database dump cannot recover the identifier.
        // Token rows therefore use sha256Hex (finding E5, preserved deliberately).
        const codeHash = await sha256Hex(normalized);
        const expiresAt = ttl(CODE_TTL_MINUTES);
        const { error: insErr } = await db.from("device_pairing_tokens").insert({
          child_user_id: uid,
          code_hash: codeHash,
          purpose: "code", // vocabulary VERIFIED A3:...:450
          status: "active", // vocabulary VERIFIED A3:...:451
          expires_at: expiresAt,
          attempts: 0,
          max_attempts: MAX_ATTEMPTS_PER_CODE,
          created_at: new Date().toISOString(),
          created_by: uid,
        });
        ensureNoError(insErr, "Could not create a pairing code.");
        // The plaintext code is returned exactly once and is never stored (schema-columns.md:290).
        return ok({ code, expires_at: expiresAt });
      }

      // ---- redeem ---------------------------------------------------------------------
      case "redeem": {
        requireRole(profile, "parent"); // capture:37 — 548
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:37 — 551. TE-01 (15:58) -> 403 forbidden
        const raw = (() => {
          const v = body["code"];
          if (typeof v !== "string" || v.length < 1 || v.length > 64) {
            invalidIdentifier();
          }
          return v as string;
        })();
        const normalized = normalizeIdentifier(raw);

        // pairing:555-560 routing (UNVERIFIED — see ../pairing.ts header). Anti-oracle-safe
        // reading: a Child-ID-shaped value gets the identical uniform error with NO database
        // probe, and anything outside the 30-symbol alphabet is rejected the same way.
        if (isContactIdForm(normalized)) invalidIdentifier();
        if (!PAIRING_CODE_RE.test(normalized)) invalidIdentifier();

        const codeHash = await sha256Hex(normalized); // capture:37 — 565
        const attemptHash = await identifierHash(normalized); // capture:37 — 566 (KEYED digest)
        await assertPairingRedeemAllowed(db, uid, attemptHash); // capture:37 — 567, BEFORE the lookup

        const failAttempt = async (): Promise<never> => {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          return invalidIdentifier();
        };

        // capture:37 — 574-578: token lookup by code_hash
        const { data: token, error: terr } = await db
          .from("device_pairing_tokens")
          .select(TOKEN_COLUMNS)
          .eq("code_hash", codeHash)
          .eq("purpose", "code")
          .maybeSingle();
        ensureNoError(terr, "Could not check the pairing code.");
        if (!token) return await failAttempt();

        // capture:37 — 585-599: status / expiry gate, uniform body, expired row transitioned
        // under an .eq(status,"active") guard so a concurrent redeemer cannot double-spend.
        const now = Date.now();
        const expired = new Date(token.expires_at).getTime() <= now;
        if (token.status !== "active" || expired || token.attempts >= token.max_attempts) {
          if (expired && token.status === "active") {
            await db
              .from("device_pairing_tokens")
              .update({ status: "expired" })
              .eq("id", token.id)
              .eq("status", "active");
          }
          return await failAttempt();
        }

        // A child may hold at most ONE active family (family_members_one_active_child_family,
        // A3:...:480). PE-P05: already linked here -> 409 child_already_linked.
        // PE-P06 (15:93): already linked ELSEWHERE -> the uniform 400, so another household's
        // membership is not disclosed through this endpoint.
        const { data: membership, error: merr } = await db
          .from("family_members")
          .select("family_id, role, status")
          .eq("user_id", token.child_user_id)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(merr, "Could not check the child membership.");
        if (membership) {
          if (membership.family_id === familyId) {
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          return await failAttempt();
        }

        // pairing:628-632 — a request already exists for this token? (UNIQUE token_id,
        // schema-columns.md:182). Second redemption -> 409 code_unavailable (14:173-177).
        const { data: prior, error: prerr } = await db
          .from("pairing_requests")
          .select("id")
          .eq("token_id", token.id)
          .maybeSingle();
        ensureNoError(prerr, "Could not check existing pairing requests.");
        if (prior) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
        }

        // capture:37 — 668-674: rpc create_pairing_request, p_parent_user_id = auth.user.id
        const expiresAtRequest = ttl(CODE_TTL_MINUTES);
        const { data, error } = await db.rpc("create_pairing_request", {
          p_child_user_id: token.child_user_id,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_token_id: token.id,
          p_expires_at: expiresAtRequest,
        });
        if (error) {
          // 14:277 — RPC messages are mapped by substring to fixed bodies, never forwarded.
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            // pairing:709-714 — revoke the token on the "already exists" path.
            await db
              .from("device_pairing_tokens")
              .update({ status: "revoked" })
              .eq("id", token.id)
              .eq("status", "active");
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          console.error(`rpc_create_pairing_request: ${error.code ?? "unknown"}`);
          throw new ApiError(500, "internal_error", "Could not create the pairing request.");
        }

        // INFERRED single-use consumption (14:172): mark the token redeemed, guarded so a
        // concurrent redeem cannot both win.
        await db
          .from("device_pairing_tokens")
          .update({ status: "redeemed", redeemed_at: new Date().toISOString(), redeemed_by: uid })
          .eq("id", token.id)
          .eq("status", "active");
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        return ok({ request: data ?? null, status: "pending_child", expires_at: expiresAtRequest });
      }

      // ---- invite -----------------------------------------------------------------------
      case "invite": {
        requireRole(profile, "parent");
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:38 — 764
        const normalized = normalizeIdentifier(
          (() => {
            const v = body["contact_id"];
            if (typeof v !== "string" || v.length < 1 || v.length > 32) invalidIdentifier();
            return v as string;
          })(),
        );
        const attemptHash = await identifierHash(normalized); // capture:38 — 771 (KEYED digest)

        // PE-P07 (15:94): a malformed Child ID is a 400 invalid_code AND exactly ONE attempt
        // recorded — hence recordPairingAttempt at :772 happens on this branch too.
        if (!CONTACT_ID_RE.test(normalized)) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false }); // :772
          invalidIdentifier();
        }

        const { data: contact, error: cerr } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id")
          .eq("contact_id", normalized)
          .maybeSingle();
        ensureNoError(cerr, "Could not look up that Child ID.");
        if (!contact) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          invalidIdentifier();
        }

        const childUserId = contact.child_user_id as string;
        await assertInviteQuotaAllowed(db, childUserId); // 14:171: 3 pending / 10 per 24 h per child

        const { data: existingChild, error: xmerr } = await db
          .from("family_members")
          .select("family_id, status")
          .eq("user_id", childUserId)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(xmerr, "Could not check the child membership.");
        if (existingChild) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          if (existingChild.family_id === familyId) {
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          invalidIdentifier();
        }

        // capture:38 — 378-383: rpc create_pairing_invite, p_parent_user_id = auth.user.id
        const expiresAt = ttl(INVITE_TTL_MINUTES);
        const inviteCodeHash = await sha256Hex(normalized);
        const { data, error } = await db.rpc("create_pairing_invite", {
          p_child_user_id: childUserId,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_code_hash: inviteCodeHash,
          p_expires_at: expiresAt,
        });
        if (error) {
          console.error(`rpc_create_pairing_invite: ${error.code ?? "unknown"}`);
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          throw new ApiError(500, "internal_error", "Could not create the invite.");
        }
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        // UNVERIFIED BEHAVIOUR — invite response shape not captured.
        return ok({ invite: data ?? null, expires_at: expiresAt });
      }

      // ---- pending_child ------------------------------------------------------------------
      case "pending_child": {
        requireRole(profile, "child"); // 14:114
        const nowIso = new Date().toISOString();
        const { data, error } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("child_user_id", uid)
          .eq("status", "pending_child")
          .gt("expires_at", nowIso) // INFERRED read filter; see ../pairing.ts UNVERIFIED list
          .order("created_at", { ascending: false })
          .limit(PENDING_LIST_LIMIT);
        ensureNoError(error, "Could not list pairing requests.");
        return ok({ requests: data ?? [] });
      }

      // ---- respond ------------------------------------------------------------------------
      case "respond": {
        requireRole(profile, "child"); // capture:39 — 814
        const requestId = readUuid(body, "request_id");
        const approve = readBoolean(body, "approve");
        if (approve === null) throw new ApiError(400, "validation_error", "approve must be a boolean.");

        // HARDENING DEVIATION (../pairing.ts header): the capture passes p_child_user_id and
        // relies on private.respond_pairing_request, whose body is unread. Service-role bypasses
        // RLS, so the relationship is asserted here as well. TE-10's "B -> 403" (15:67) is the
        // behaviour this reproduces at the Edge tier.
        const { data: row, error: rerr } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("id", requestId)
          .maybeSingle();
        ensureNoError(rerr, "Could not read the pairing request.");
        if (!row) throw new ApiError(403, "forbidden", "Not your pairing request.");
        if (row.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your pairing request.");

        // capture:39 — 818-821: rpc respond_pairing_request, p_child_user_id = auth.user.id
        const { data, error } = await db.rpc("respond_pairing_request", {
          p_request_id: requestId,
          p_child_user_id: uid,
          p_approve: approve,
        });
        if (error) {
          console.error(`rpc_respond_pairing_request: ${error.code ?? "unknown"}`);
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("expired") || m.includes("not_pending")) {
            throw new ApiError(409, "code_unavailable", "This pairing request is no longer available.");
          }
          throw new ApiError(500, "internal_error", "Could not respond to the pairing request.");
        }
        return ok({ request: data ?? null }); // INFERRED idempotent repeat, 14:311
      }

      // ---- cancel ---------------------------------------------------------------------------
      case "cancel": {
        requireRole(profile, "parent"); // 14:114. PE-P12 (15:99): another family's request -> 403
        const requestId = readUuid(body, "request_id");
        const { data: row, error: rerr } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("id", requestId)
          .maybeSingle();
        ensureNoError(rerr, "Could not read the pairing request.");
        if (!row) throw new ApiError(400, "validation_error", "No such pairing request.");
        await assertFamilyParent(db, uid, row.family_id);

        // Compare-and-set (14:205 pattern); terminal rows return as-is (idempotent repeat).
        if (row.status !== "pending_child") return ok({ request: row });
        const { data: updated, error: uerr } = await db
          .from("pairing_requests")
          .update({ status: "cancelled", responded_at: new Date().toISOString() })
          .eq("id", requestId)
          .eq("status", "pending_child")
          .select(REQUEST_COLUMNS)
          .maybeSingle();
        ensureNoError(uerr, "Could not cancel the pairing request.");
        if (!updated) {
          const { data: again } = await db
            .from("pairing_requests")
            .select(REQUEST_COLUMNS)
            .eq("id", requestId)
            .maybeSingle();
          return ok({ request: again ?? null });
        }
        // Token released so the code is not burned by a cancelled request. INFERRED.
        await db
          .from("device_pairing_tokens")
          .update({ status: "revoked" })
          .eq("id", row.token_id)
          .eq("status", "active");
        return ok({ request: updated });
      }

      // ---- list_family ----------------------------------------------------------------------
      case "list_family": {
        requireRole(profile, "parent"); // 14:114. TE-05 uses list_family for the child-role test.
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId);
        // UNVERIFIED BEHAVIOUR — content not captured; three scoped reads only (all family-
        // scoped, so a predicate miss cannot leak another household).
        const { data: members, error: e1 } = await db
          .from("family_members")
          .select("id, family_id, user_id, role, status, created_at, removed_at")
          .eq("family_id", familyId)
          .eq("status", "active");
        ensureNoError(e1, "Could not list family members.");
        const { data: devices, error: e2 } = await db
          .from("devices")
          .select(
            "id, family_id, child_user_id, display_name, platform, status, enforcement_mode, policy_version, last_seen_at, battery_level, is_charging",
          )
          .eq("family_id", familyId);
        ensureNoError(e2, "Could not list devices.");
        const { data: requests, error: e3 } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("family_id", familyId)
          .eq("status", "pending_child")
          .order("created_at", { ascending: false })
          .limit(PENDING_LIST_LIMIT);
        ensureNoError(e3, "Could not list pairing requests.");
        return ok({ family_id: familyId, members: members ?? [], devices: devices ?? [], requests: requests ?? [] });
      }

      // ---- unlink -------------------------------------------------------------------------------
      case "unlink": {
        const familyId = readUuid(body, "family_id");
        const targetChild = readUuid(body, "child_user_id"); // TARGET, not actor (14:102)
        // capture:40 — 929-939: "actor is child (self) or parent in the body family".
        if (profile.role === "child") {
          if (targetChild !== uid) {
            throw new ApiError(403, "forbidden", "A child may only unlink their own link.");
          }
          await assertChildMembership(db, uid, familyId);
        } else {
          requireRole(profile, "parent");
          await assertFamilyParent(db, uid, familyId);
          const { data: tm, error: tmerr } = await db
            .from("family_members")
            .select("family_id, role, status")
            .eq("user_id", targetChild)
            .eq("family_id", familyId)
            .eq("status", "active")
            .eq("role", "child")
            .maybeSingle();
          ensureNoError(tmerr, "Could not check the child membership.");
          if (!tm) throw new ApiError(403, "forbidden", "That child is not in this family.");
        }
        // capture:40 — 942-945: rpc unlink_child, p_actor_user_id = auth.user.id
        const { data, error } = await db.rpc("unlink_child", {
          p_family_id: familyId,
          p_child_user_id: targetChild,
          p_actor_user_id: uid,
        });
        if (error) {
          console.error(`rpc_unlink_child: ${error.code ?? "unknown"}`);
          throw new ApiError(500, "internal_error", "Could not unlink that child.");
        }
        // PE-P09 (15:96): 200 and devices revoked — the revocation itself happens inside
        // private.unlink_child, whose body WAS read (evidence/g1-b3b-20261029.json):
        // devices -> status 'revoked', secret_hash null, credential_revoked_at now();
        // pairing_requests 'pending_child' -> 'cancelled'; tokens -> 'revoked';
        // family_members -> 'removed'; audit event 'member_removed'.
        return ok({ result: data ?? null });
      }

      default:
        unknownAction(action); // 15:137 — never a silent no-op
    }
  } catch (err) {
    return errorResponse(err);
  }
});
