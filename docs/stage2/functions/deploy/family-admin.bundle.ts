// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `family-admin`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:116-119 — MINIFIED BUNDLE, 9386 chars / 2 lines, sha256 b6864fdd.... No source maps.
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../family-admin.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:122): cors, envelope, auth, audit,
//   validation. NOT inlined: rate_limit — no rate limiting in the captured bundle (E7).
//   THAT MATTERS HERE: this slug performs DESTRUCTIVE actions (purge_data deletes real
//   location/usage history), so an unthrottled burst is capacity/destruction abuse.
// TABLES TOUCHED: devices (SELECT — hardening scope read only; the UPDATE happens inside the
//   RPC), safety_alerts (SELECT, UPDATE), location_events (DELETE), usage_daily (DELETE),
//   families (SELECT, UPDATE), audit_logs (INSERT), + profiles / family_members via auth.
// RPCs CALLED: public.revoke_device, public.request_device_recovery.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. No values; no service-role credential in a
//   client path.
// HARDENING DEVIATION (disclosed): the captured revoke_device authorises only "a parent
//   somewhere" and delegates the family check to private.revoke_device, whose body is one of
//   the 24 unread implementations (14:149-152 — that check's PASS rating is marked with an
//   asterisk for exactly this reason). This bundle loads the device and asserts parent
//   membership in THAT device's family BEFORE the RPC, because service_role makes RLS inert.
//   STRICTER than captured; the only observable difference is which layer rejects first.
// GAPS THIS BUNDLE CANNOT CLOSE: revoke_device's audit event_type string (`device_revoked` is
//   invented-adjacent and labelled UNVERIFIED); purge_data's timestamp column choice
//   (recorded_at vs received_at); retention min/max bounds (PLACEHOLDER 1..3650); all five
//   response shapes; gateway verify_jwt; A13 (UNSIGNED).
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
// Carried subset: readString / readUuid / readInt.
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

// ---------------------------------------------------------------------------
// INLINED: _shared/audit.ts — RE-AUTHORED (capture:165, 1101 chars / 38 lines, never read).
// A failed insert THROWS (500 audit_failed) (14:293, 14:340). capture:126-128 name four audit
// events for this slug; a fifth (device_recovery_started) comes from 15:173.
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
// :68-75, :92, :93-104, :123-127, :139-149, :151-196.
//
// IDENTITY SEAM — A13 IS UNSIGNED: one switch (IDENTITY_MODE), one Firebase-UID function that
// fails closed with 503, two verified-email readings in emailVerifiedFor(). The actor passed to
// every RPC below is the VERIFIED SUBJECT, never a body field.
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

/** capture:128 — "owner_required via O()". This is that check. */
async function assertFamilyOwner(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  if (family.owner_id !== userId) throw new ApiError(403, "owner_required", "This action requires the family owner.");
  return family;
}

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../family-admin.ts. Five actions, exactly capture:120.
// ---------------------------------------------------------------------------

const DEFAULT_LOCATION_RETENTION_DAYS = 30; // capture:127 + A3:...:253 default
const DEFAULT_USAGE_RETENTION_DAYS = 90; // capture:127 + A3:...:253 default
const RETENTION_MIN_DAYS = 1; // PLACEHOLDER — only `0` is evidenced as invalid (15:178)
const RETENTION_MAX_DAYS = 3650; // PLACEHOLDER

const SETTINGS_LOCATION_KEY = "location_retention_days"; // DATABASE-VERIFIED key name (A3:...:253)
const SETTINGS_USAGE_KEY = "usage_retention_days";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    requireRole(profile, "parent"); // capture:121 — parent for every action (14:119)

    if (action === "revoke_device") {
      const deviceId = readUuid(body, "device_id");
      // HARDENING: scope asserted in-function (see the header note on 14:149-152).
      const { data: device, error: derr } = await db
        .from("devices")
        .select("id, family_id, child_user_id, status, credential_revoked_at")
        .eq("id", deviceId)
        .maybeSingle();
      ensureNoError(derr, "Could not read the device.");
      if (!device) throw new ApiError(403, "forbidden", "Device not available.");
      await assertFamilyParent(db, auth.userId, device.family_id);

      // capture:124 — p_actor_user_id is the verified subject.
      const { data, error } = await db.rpc("revoke_device", {
        p_device_id: deviceId,
        p_actor_user_id: auth.userId,
      });
      if (error) {
        console.error(`rpc_revoke_device: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not revoke that device.");
      }
      await recordAudit(db, {
        eventType: "device_revoked", // UNVERIFIED name — see header
        actorUserId: auth.userId,
        familyId: device.family_id,
        deviceId,
        targetType: "device",
        targetId: deviceId,
        metadata: {},
      });
      // PE-F01 (15:171): D1 revoked AND the credential nulled. The nulling of secret_hash is
      // done inside private.revoke_device (unread body); the DB constraint
      // status='revoked' => secret_hash IS NULL (A3:...:464) makes it structural.
      return ok({ result: data ?? null });
    }

    if (action === "recover_device") {
      const deviceId = readUuid(body, "device_id");
      const { data, error } = await db.rpc("request_device_recovery", {
        p_device_id: deviceId,
        p_actor_user_id: auth.userId, // capture:125
      });
      if (error) {
        console.error(`rpc_request_device_recovery: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not start device recovery.");
      }
      // No in-function scope check is added here: private.request_device_recovery's body WAS
      // read (B3b) and asserts an active parent of the device's family itself (14:55, :151).
      await recordAudit(db, {
        eventType: "device_recovery_started", // VERIFIED name from 15:173 (PE-F03)
        actorUserId: auth.userId,
        familyId: null,
        deviceId,
        targetType: "device",
        targetId: deviceId,
        metadata: {},
      });
      return ok({ recovery: "started", result: data ?? null }); // PE-F03, 15:173
    }

    if (action === "ack_alert") {
      const alertId = readUuid(body, "alert_id");
      // capture:126 — select by alert_id, FAMILY ASSERTED BEFORE UPDATE.
      const { data: alert, error: aerr } = await db
        .from("safety_alerts")
        .select("id, family_id, device_id, type, severity, acknowledged_at, acknowledged_by")
        .eq("id", alertId)
        .maybeSingle();
      ensureNoError(aerr, "Could not read the alert.");
      if (!alert) throw new ApiError(400, "validation_error", "No such alert.");
      await assertFamilyParent(db, auth.userId, alert.family_id); // PE-F04 (15:174) -> 403
      const { error: uerr } = await db
        .from("safety_alerts")
        .update({ acknowledged_at: new Date().toISOString(), acknowledged_by: auth.userId })
        .eq("id", alertId)
        .eq("family_id", alert.family_id); // two-predicate scope: service-role has no RLS net
      ensureNoError(uerr, "Could not acknowledge the alert.");
      await recordAudit(db, {
        eventType: "alert_acknowledged", // capture:126
        actorUserId: auth.userId,
        familyId: alert.family_id,
        deviceId: alert.device_id ?? null,
        targetType: "safety_alert",
        targetId: alertId,
        metadata: { alert_type: alert.type, severity: alert.severity },
      });
      return ok({ alert_id: alertId, acknowledged: true });
    }

    if (action === "purge_data") {
      const familyId = readUuid(body, "family_id");
      await assertFamilyParent(db, auth.userId, familyId); // capture:127 "family asserted"

      // Retention comes from the family's own settings (keys VERIFIED at A3:...:253) and the
      // FLOOR is max(requested, configured) — capture:127. PE-F05 (15:176): requesting 1 day
      // with a 30-day retention deletes nothing recent.
      const { data: family, error: ferr } = await db
        .from("families")
        .select("id, settings, owner_id, deleted_at")
        .eq("id", familyId)
        .maybeSingle();
      ensureNoError(ferr, "Could not read the family settings.");
      const settings = (family?.settings ?? {}) as Record<string, unknown>;
      const configuredLocation =
        typeof settings[SETTINGS_LOCATION_KEY] === "number"
          ? (settings[SETTINGS_LOCATION_KEY] as number)
          : DEFAULT_LOCATION_RETENTION_DAYS;
      const configuredUsage =
        typeof settings[SETTINGS_USAGE_KEY] === "number"
          ? (settings[SETTINGS_USAGE_KEY] as number)
          : DEFAULT_USAGE_RETENTION_DAYS;

      const requested = (() => {
        if (body["older_than_days"] === undefined || body["older_than_days"] === null) return 0;
        return readInt(body, "older_than_days", { min: 0, max: 36500 });
      })();
      const locationDays = Math.max(requested, configuredLocation);
      const usageDays = Math.max(requested, configuredUsage);

      const locationCutoff = new Date(Date.now() - locationDays * 86_400_000).toISOString();
      const usageCutoffDay = new Date(Date.now() - usageDays * 86_400_000).toISOString().slice(0, 10);

      // capture:127 — BOTH deletes scoped .eq(family_id).
      const { count: locationDeleted, error: d1 } = await db
        .from("location_events")
        .delete({ count: "exact" })
        .eq("family_id", familyId)
        .lt("recorded_at", locationCutoff); // column choice is UNVERIFIED (received_at alternative)
      ensureNoError(d1, "Could not purge location events.");
      const { count: usageDeleted, error: d2 } = await db
        .from("usage_daily")
        .delete({ count: "exact" })
        .eq("family_id", familyId)
        .lt("day", usageCutoffDay);
      ensureNoError(d2, "Could not purge usage rows.");

      await recordAudit(db, {
        eventType: "data_purged", // capture:127
        actorUserId: auth.userId,
        familyId,
        deviceId: null,
        targetType: "family",
        targetId: familyId,
        metadata: { location_events: locationDeleted ?? 0, usage_daily: usageDeleted ?? 0, location_days: locationDays, usage_days: usageDays },
      });
      return ok({ location_events_deleted: locationDeleted ?? 0, usage_daily_deleted: usageDeleted ?? 0 });
    }

    if (action === "update_retention") {
      const familyId = readUuid(body, "family_id");
      // capture:128 — "owner_required via O()". assertFamilyOwner is that check, and it also
      // re-asserts the family is live before the write.
      const family = await assertFamilyOwner(db, auth.userId, familyId);
      const locationDays = readInt(body, SETTINGS_LOCATION_KEY, { min: RETENTION_MIN_DAYS, max: RETENTION_MAX_DAYS }); // PE-F07: 0 -> 400
      const usageDays = readInt(body, SETTINGS_USAGE_KEY, { min: RETENTION_MIN_DAYS, max: RETENTION_MAX_DAYS });

      // INFERRED merge (see ../family-admin.ts): settings is a two-key object, so preserving
      // siblings is the only reading that cannot destroy another setting.
      const current = (family.settings ?? {}) as Record<string, unknown>;
      const nextSettings = { ...current, [SETTINGS_LOCATION_KEY]: locationDays, [SETTINGS_USAGE_KEY]: usageDays };
      const { error: uerr } = await db
        .from("families")
        .update({ settings: nextSettings })
        .eq("id", familyId)
        .eq("owner_id", auth.userId) // double scope: owner predicate in the write itself
        .is("deleted_at", null);
      ensureNoError(uerr, "Could not update the retention settings.");
      await recordAudit(db, {
        eventType: "settings_updated", // capture:128
        actorUserId: auth.userId,
        familyId,
        deviceId: null,
        targetType: "family",
        targetId: familyId,
        metadata: { [SETTINGS_LOCATION_KEY]: locationDays, [SETTINGS_USAGE_KEY]: usageDays },
      });
      return ok({ settings: nextSettings });
    }

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
