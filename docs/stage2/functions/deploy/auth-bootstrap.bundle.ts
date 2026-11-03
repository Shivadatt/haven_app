// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `auth-bootstrap`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:45 grades this slug as "readable TypeScript" (140 lines), but NO repository file
//   holds that text (supabase/functions/ is absent — 13-edge-function-source-inventory.md §1;
//   the pairing/ directory implied by capture operations_performed is empty — S2-A4 A4-F13;
//   S2-A7 T-07: "every pairing/index.ts:<n> anchor resolves to a dashboard capture, not to a
//   repository file"). Only the anchor line numbers survived, so even this slug is a
//   re-authoring. Deployed digest 34cf6732... (capture:48); digest for this bundle not
//   computed (terminal prohibited).
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../auth-bootstrap.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED IMPORT SET (capture:51):
//   audit, auth, cors, envelope, validation.  NOT inlined: rate_limit — this function has no
//   rate limiting in the captured source either (finding E7 preserved).
// TABLES TOUCHED: profiles, families, child_contact_ids, audit_logs (+ family_members via
//   assertions). RPC: public.create_family_with_owner.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. No value anywhere. No service-role credential is
//   reachable from any client path: the client is constructed only inside this function.
// GAPS THIS BUNDLE CANNOT CLOSE: response body shapes (never captured); the A13 identity
//   decision (UNSIGNED — the seam below defaults to Supabase Auth and fails closed on the
//   Firebase branch); whether the gateway verify_jwt setting is on for this slug.
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

function readOptionalString(body: Record<string, unknown>, key: string, bounds: { min?: number; max?: number } = {}): string | null {
  if (body[key] === undefined || body[key] === null) return null;
  return readString(body, key, bounds);
}

function readBooleanWithFallback(body: Record<string, unknown>, key: string, fallback: boolean): boolean;
function readBooleanWithFallback(body: Record<string, unknown>, key: string): boolean | null;
function readBooleanWithFallback(body: Record<string, unknown>, key: string, fallback?: boolean): boolean | null {
  const v = body[key];
  if (v === undefined || v === null) return fallback === undefined ? null : fallback;
  if (typeof v !== "boolean") bad(`${key} must be a boolean.`);
  return v;
}

function readInt(body: Record<string, unknown>, key: string, bounds: { min: number; max: number }, fallback?: number): number {
  const v = body[key];
  if (v === undefined || v === null) {
    if (fallback !== undefined) return fallback;
    bad(`${key} is required.`);
  }
  if (typeof v !== "number" || !Number.isInteger(v)) bad(`${key} must be an integer.`);
  if (v < bounds.min || v > bounds.max) bad(`${key} must be between ${bounds.min} and ${bounds.max}.`);
  return v;
}

function readNumber(body: Record<string, unknown>, key: string, bounds: { min: number; max: number }, fallback?: number): number {
  const v = body[key];
  if (v === undefined || v === null) {
    if (fallback !== undefined) return fallback;
    bad(`${key} is required.`);
  }
  if (typeof v !== "number" || !Number.isFinite(v)) bad(`${key} must be a number.`);
  if (v < bounds.min || v > bounds.max) bad(`${key} must be between ${bounds.min} and ${bounds.max}.`);
  return v;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HEX64_RE = /^[0-9a-f]{64}$/; // VERIFIED from three DB checks: A3:...:448, :465, :476

function readUuid(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 36, max: 36 });
  if (!UUID_RE.test(v)) bad(`${key} must be a UUID.`);
  return v.toLowerCase();
}

function readHex64(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 64, max: 64 });
  if (!HEX64_RE.test(v)) bad(`${key} must be 64 hexadecimal characters.`);
  return v.toLowerCase();
}

function readEnum<S extends string>(body: Record<string, unknown>, key: string, values: readonly S[]): S {
  const v = readString(body, key, { min: 1, max: 128 });
  if (!values.includes(v as S)) bad(`${key} must be one of: ${values.join(", ")}.`);
  return v as S;
}

function readArray(body: Record<string, unknown>, key: string, bounds: { max: number; min?: number }): unknown[] {
  const v = body[key];
  if (!Array.isArray(v)) bad(`${key} must be an array.`);
  const min = bounds.min ?? 0;
  if (v.length < min) bad(`${key} must contain at least ${min} items.`);
  if (v.length > bounds.max) bad(`${key} must contain at most ${bounds.max} items.`);
  return v;
}

function readObject(body: Record<string, unknown>, key: string, maxJsonChars: number): Record<string, unknown> {
  const v = body[key];
  if (v === null || typeof v !== "object" || Array.isArray(v)) bad(`${key} must be a JSON object.`);
  if (JSON.stringify(v).length > maxJsonChars) bad(`${key} is too large`);
  return v as Record<string, unknown>;
}

function assertAllowedKeys(obj: Record<string, unknown>, allowed: readonly string[], path: string): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.includes(k)) bad(`${path}.${k} is not allowed`);
  }
}

function clampInt(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function isRealDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [y, m, d] = value.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}

function parseTimestamp(value: string, key: string): Date {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) bad(`${key} must be an ISO-8601 timestamp.`);
  return d;
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

function constantTimeEqualHex(a: string, b: string): boolean {
  const x = a.toLowerCase();
  const y = b.toLowerCase();
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x.charCodeAt(i) ^ y.charCodeAt(i);
  return diff === 0;
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

const PACKAGE_NAME_RE = /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$/; // PLACEHOLDER

function readPackageName(value: unknown, key: string): string {
  if (typeof value !== "string") bad(`${key} must be a string.`);
  if (value.length < 1 || value.length > 150) bad(`${key} must be 1 to 150 characters.`);
  if (!PACKAGE_NAME_RE.test(value)) bad(`${key} must be a package name.`);
  return value;
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
// a missing predicate is not caught by the database. Line anchors preserved: :51-56, :49-66,
// :68-75, :92, :93-104, :123-127, :139-149, :151-196, :266-289, :295-338, :325-330.
//
// IDENTITY SEAM — A13 IS UNSIGNED. IDENTITY_MODE is the single switch; the Firebase-UID
// assumption lives in exactly ONE function (resolveFirebaseIdentity) and fails closed.
// Cutover = flip the constant and implement that one body, once A13 is signed AND mapping
// store M-B exists (S2-EXEC-08 §3-§4). Verified-email has BOTH readings behind
// emailVerifiedFor(), per S2-EXEC-08 §2(3).
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

async function assertFamilyMember(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member) throw new ApiError(403, "forbidden", "Not a member of this family.");
  return { family, member };
}

async function assertFamilyChild(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "child") throw new ApiError(403, "forbidden", "Not a child of this family.");
  return family;
}

const assertChildMembership = assertFamilyChild;

async function assertFamilyOwner(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  if (family.owner_id !== userId) throw new ApiError(403, "owner_required", "This action requires the family owner.");
  return family;
}

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
// HANDLER — re-authored from ../auth-bootstrap.ts. Actions are exactly capture:49's two.
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });

    if (action === "set_role") {
      const requested = readEnum(body, "role", ["parent", "child"] as const);
      if (profile.role !== "unset") {
        throw new ApiError(409, "role_already_set", "A role is already set for this account.");
      }
      const { error: perr } = await db.from("profiles").update({ role: requested }).eq("id", auth.userId);
      ensureNoError(perr, "Could not save the role.");
      await recordAudit(db, {
        eventType: "role_set",
        actorUserId: auth.userId,
        familyId: null,
        deviceId: null,
        targetType: "profile",
        targetId: auth.userId,
        metadata: { role: requested, from: "unset" },
      });
      if (requested === "child") {
        try {
          const { data: existing } = await db
            .from("child_contact_ids")
            .select("child_user_id, contact_id, created_at, rotated_at")
            .eq("child_user_id", auth.userId)
            .maybeSingle();
          if (!existing) {
            const { error: cerr } = await db
              .from("child_contact_ids")
              .upsert(
                { child_user_id: auth.userId, contact_id: newContactId(), created_at: new Date().toISOString() },
                { onConflict: "child_user_id" },
              );
            if (cerr) console.error(`contact_id_upsert: ${cerr.code ?? "unknown"}`);
          }
        } catch (err) {
          console.error(`contact_id_best_effort: ${err instanceof Error ? err.name : "unknown"}`);
        }
      }
      return ok({ role: requested, contact_id_prefix: CONTACT_ID_PREFIX });
    }

    if (action === "create_family") {
      requireRole(profile, "parent");
      const name = (() => {
        const v = body["name"];
        if (typeof v !== "string" || v.length < 1 || v.length > 80) {
          throw new ApiError(400, "validation_error", "name must be 1 to 80 characters.");
        }
        return v;
      })();
      const { data: existing, error: ferr } = await db
        .from("families")
        .select("id")
        .eq("owner_id", auth.userId)
        .is("deleted_at", null)
        .maybeSingle();
      ensureNoError(ferr, "Could not check existing families.");
      if (existing) throw new ApiError(409, "family_exists", "This account already owns a family.");
      const { data, error } = await db.rpc("create_family_with_owner", { p_owner: auth.userId, p_name: name });
      if (error) {
        console.error(`rpc_create_family: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not create the family.");
      }
      return ok({ family: data ?? null });
    }

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
