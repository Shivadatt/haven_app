// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `device-telemetry`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and appears nowhere
//   in this file as one. NOTHING IS DEPLOYED by this package: A7-R / A8-R are UNSIGNED, and
//   staging has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   capture:101-103 — MINIFIED BUNDLE, 12461 chars / 2 lines, sha256 b3ca5221.... No source
//   maps. 14:48 records this slug's overall verdict as PARTIAL (abuse checks E7/E13).
//
// FULL EVIDENCE BLOCK + UNVERIFIED-BEHAVIOUR LIST: ../device-telemetry.ts (same slug).
//
// INLINED MODULES — EXACTLY THE CAPTURED SET (capture:106): cors, envelope, auth, validation.
//   *** THERE IS NO `audit` BLOCK IN THIS FILE. *** capture:106 does not list audit for this
//   slug, so the deployed telemetry writer records ZERO audit rows. That is finding E13 and it
//   is PRESERVED, not silently repaired: adding recordAudit would change what the function does
//   and is an A7-R decision, not an IMP-5 edit. Location uploads, usage uploads, app snapshots
//   and heartbeats therefore leave no audit trail at all.
//   NO rate_limit EITHER: PE-T12 (15:167) records that 100 location uploads in 60 s are all
//   accepted today. Preserved verbatim — the single most exploitable gap in this package.
//   Only the device-credential half of `auth` is carried (getServiceClient + requireDevice);
//   the A13 identity seam is NOT needed here because this slug has no user-JWT path at all.
// TABLES TOUCHED: devices (SELECT, UPDATE), location_events (INSERT — plain, so retries
//   duplicate: 14:314-315 preserved), usage_daily (UPSERT), safe_zones (SELECT),
//   safe_zone_states (UPSERT), safety_alerts (INSERT). audit_logs NOT TOUCHED.
// RPCs CALLED: public.replace_device_apps(p_device_id, p_family_id, p_apps).
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. The device secret is digested and compared, never
//   stored raw, never returned. No service-role credential reaches a client path.
// GAPS THIS BUNDLE CANNOT CLOSE: the capabilities allowlist content (INFERRED from the six
//   *_granted service_role UPDATE grants at A3:...:1007-1029); the low-battery threshold value
//   (PLACEHOLDER below); the geofence alert rule; alert message/severity wording; batch array
//   key name for location; gateway verify_jwt.
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
// Carried subset: the typed readers this handler uses. PLACEHOLDER, NOT EVIDENCE: the Android
// package-name regex (14:224 says only "package regex").
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

function readBoolean(body: Record<string, unknown>, key: string): boolean | null {
  const v = body[key];
  if (v === undefined || v === null) return null;
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

const PACKAGE_NAME_RE = /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$/; // PLACEHOLDER, 14:224

function readPackageName(value: unknown, key: string): string {
  if (typeof value !== "string") bad(`${key} must be a string.`);
  if (value.length < 1 || value.length > 150) bad(`${key} must be 1 to 150 characters.`);
  if (!PACKAGE_NAME_RE.test(value)) bad(`${key} must be a package name.`);
  return value;
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
// INLINED: _shared/auth.ts — PARTIAL (capture:166, 9920 chars / 338 lines, never read).
// Only the device-credential channel is carried, because capture:105 gives this slug NO user-JWT
// path. THE TRUST BOUNDARY: service_role means RLS is inert (14:245-246), so every update below
// carries its own predicate. Anchors preserved: :295-338, :325-330 (zero-digest decoy).
// REVOCATION HONOURED: status != 'active' OR credential_revoked_at NOT NULL -> 401.
// ---------------------------------------------------------------------------

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

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

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

// NOTE: there is deliberately no recordAudit() in this file. See the header (capture:106, E13).

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../device-telemetry.ts. Four actions, exactly capture:104.
// ---------------------------------------------------------------------------

const BATTERY_MIN = 0;
const BATTERY_MAX = 100; // VERIFIED: capture:108 and devices_battery_level_check (A3:...:458)
const LOW_BATTERY_THRESHOLD_PERCENT = 20; // PLACEHOLDER — value not captured
const LOW_BATTERY_DEDUPE_HOURS = 6; // capture:108 — "deduped in a 6-hour window"
const TELEMETRY_BATCH_MAX = 500; // capture:109, :111; 14:224
const USAGE_DAY_FUTURE_MS = 36 * 60 * 60 * 1000; // capture:109 — "not beyond now+36h"
const LOCATION_MIN_LAT = -90;
const LOCATION_MAX_LAT = 90;
const LOCATION_MIN_LNG = -180;
const LOCATION_MAX_LNG = 180;
const LOCATION_MAX_ACCURACY_M = 100_000; // capture:110 — 0..1e5
const RECORDING_MAX_AGE_DAYS = 7; // capture:110 — "-7d"
const RECORDING_MAX_FUTURE_MS = 5 * 60 * 1000; // capture:110 — "+5min"
const EARTH_RADIUS_M = 6_371_000;

/** INFERRED from A3:...:1007-1029 (the six *_granted service_role UPDATE grants). See header. */
const CAPABILITIES = [
  "usage_access_granted",
  "location_granted",
  "background_location_granted",
  "camera_granted",
  "microphone_granted",
  "notifications_granted",
] as const;

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(a)));
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const db = getServiceClient();

    // capture:105 — device-only. requireDevice honours the revocation semantics
    // (status != 'active' OR credential_revoked_at NOT NULL -> 401).
    const device = await requireDevice(req, db);
    const deviceId = device.id as string;
    const familyId = device.family_id as string;

    if (action === "heartbeat") {
      const patch: Record<string, unknown> = {};
      const battery = body["battery_level"];
      if (battery !== undefined && battery !== null) {
        patch["battery_level"] = readInt(body, "battery_level", { min: BATTERY_MIN, max: BATTERY_MAX }); // PE-T02
      }
      const charging = readBoolean(body, "is_charging");
      if (charging !== null) patch["is_charging"] = charging;
      const online = readBoolean(body, "online");
      if (online === true) patch["last_seen_at"] = new Date().toISOString(); // INFERRED, see header
      const caps = body["capabilities"];
      if (caps !== undefined && caps !== null) {
        const capObj = readObject(body, "capabilities", 8 * 1024);
        for (const k of Object.keys(capObj)) {
          if (!(CAPABILITIES as readonly string[]).includes(k)) {
            throw new ApiError(400, "validation_error", `capabilities.${k} is not allowed`); // 14:223 form
          }
          if (typeof capObj[k] !== "boolean") {
            throw new ApiError(400, "validation_error", `capabilities.${k} must be a boolean.`);
          }
          patch[k] = capObj[k];
        }
      }

      // capture:108 — devices.update scoped .eq(id, device.id). Two predicates, because the
      // service-role client has no RLS net: id AND family_id from the authenticated row.
      const { error: uerr } = await db.from("devices").update(patch).eq("id", deviceId).eq("family_id", familyId);
      ensureNoError(uerr, "Could not record the heartbeat.");

      // low_battery alert, deduped inside a 6-hour window (capture:108, PE-T03 15:157).
      let alertCreated = false;
      if (typeof patch["battery_level"] === "number" && (patch["battery_level"] as number) <= LOW_BATTERY_THRESHOLD_PERCENT) {
        const since = new Date(Date.now() - LOW_BATTERY_DEDUPE_HOURS * 3_600_000).toISOString();
        const { data: recent, error: aerr } = await db
          .from("safety_alerts")
          .select("id")
          .eq("device_id", deviceId)
          .eq("type", "low_battery") // VERIFIED vocabulary A3:...:491
          .gte("created_at", since)
          .limit(1)
          .maybeSingle();
        ensureNoError(aerr, "Could not check recent alerts.");
        if (!recent) {
          const { error: ierr } = await db.from("safety_alerts").insert({
            family_id: familyId,
            device_id: deviceId,
            type: "low_battery",
            severity: "warning", // INFERRED choice within the verified vocabulary
            message: `Device battery at ${patch["battery_level"]}%.`, // text NOT captured
            payload: { battery_level: patch["battery_level"], is_charging: patch["is_charging"] ?? null },
          });
          ensureNoError(ierr, "Could not record the alert.");
          alertCreated = true;
        }
      }

      // capture:108 — returns pending_policy_version. Derivation INFERRED (see header).
      const { data: pending, error: perr } = await db
        .from("device_policies")
        .select("version")
        .eq("device_id", deviceId)
        .eq("family_id", familyId)
        .is("acknowledged_at", null)
        .order("version", { ascending: false })
        .limit(1)
        .maybeSingle();
      ensureNoError(perr, "Could not read the pending policy.");
      return ok({
        pending_policy_version: pending?.version ?? device.policy_version ?? 0,
        low_battery_alert_created: alertCreated,
      });
    }

    if (action === "usage_upload") {
      // capture:109 — "entries max 500".
      const entries = readArray(body, "entries", { max: TELEMETRY_BATCH_MAX, min: 0 });
      const now = Date.now();
      const rows: Record<string, unknown>[] = [];
      const seen = new Set<string>();
      for (let i = 0; i < entries.length; i++) {
        if (entries[i] === null || typeof entries[i] !== "object" || Array.isArray(entries[i])) {
          throw new ApiError(400, "validation_error", `entries[${i}] must be an object.`);
        }
        const e = entries[i] as Record<string, unknown>;
        const day = readString(e, "day", { min: 10, max: 10 });
        // "day must be a real date and not beyond now+36h" — PE-T04 expects 400 with the
        // message "cannot be in the future" (15:157).
        if (!isRealDate(day)) throw new ApiError(400, "validation_error", "day is not a real calendar date.");
        const dayTime = Date.parse(`${day}T23:59:59Z`);
        if (dayTime > now + USAGE_DAY_FUTURE_MS) {
          throw new ApiError(400, "validation_error", "day cannot be in the future");
        }
        const pkg = readPackageName(e["package_name"], `entries[${i}].package_name`);
        const dedupeKey = `${day}|${pkg}`;
        // PE-T05 (15:158) — a duplicate (day, package) INSIDE one batch is a 400, so the
        // upsert never has to resolve a self-conflict.
        if (seen.has(dedupeKey)) {
          throw new ApiError(400, "validation_error", "duplicate entry for the same day and package_name");
        }
        seen.add(dedupeKey);
        const totalMs = readInt(e, "total_ms", { min: 0, max: Number.MAX_SAFE_INTEGER }); // usage_daily_total_ms_check >= 0
        const row: Record<string, unknown> = {
          device_id: deviceId, // capture:109 — from the device row, never the body
          family_id: familyId,
          day,
          package_name: pkg,
          total_ms: totalMs,
        };
        if (typeof e["app_label"] === "string") row["app_label"] = (e["app_label"] as string).slice(0, 100);
        if (typeof e["last_used_at"] === "string") row["last_used_at"] = parseTimestamp(e["last_used_at"] as string, "last_used_at").toISOString();
        // `source` is intentionally NOT sent: usage_daily_source DEFAULT 'usage_stats'
        // (A3:...:371) is the database's own value and no capture anchor names another.
        rows.push(row);
      }
      if (rows.length > 0) {
        const { error: upErr } = await db
          .from("usage_daily")
          .upsert(rows, { onConflict: "device_id,day,package_name" }); // capture:109; UNIQUE A3:...:430
        ensureNoError(upErr, "Could not store the usage entries.");
      }
      return ok({ accepted: rows.length });
    }

    if (action === "location_upload") {
      const points = readArray(body, "points", { max: TELEMETRY_BATCH_MAX, min: 0 }); // array NAME inferred
      const now = Date.now();
      const inserted: Record<string, unknown>[] = [];
      for (let i = 0; i < points.length; i++) {
        if (points[i] === null || typeof points[i] !== "object" || Array.isArray(points[i])) {
          throw new ApiError(400, "validation_error", `points[${i}] must be an object.`);
        }
        const p = points[i] as Record<string, unknown>;
        // capture:110 bounds, all VERIFIED against location_events checks (A3:...:472-475).
        const lat = readNumber(p, "lat", { min: LOCATION_MIN_LAT, max: LOCATION_MAX_LAT }); // PE-T06
        const lng = readNumber(p, "lng", { min: LOCATION_MIN_LNG, max: LOCATION_MAX_LNG });
        const accuracy = readNumber(p, "accuracy_m", { min: 0, max: LOCATION_MAX_ACCURACY_M });
        const recordedAt = parseTimestamp(
          typeof p["recorded_at"] === "string" ? (p["recorded_at"] as string) : "",
          "recorded_at",
        );
        if (recordedAt.getTime() < now - RECORDING_MAX_AGE_DAYS * 86_400_000) {
          throw new ApiError(400, "validation_error", "recorded_at is older than seven days"); // PE-T07, 15:162
        }
        if (recordedAt.getTime() > now + RECORDING_MAX_FUTURE_MS) {
          throw new ApiError(400, "validation_error", "recorded_at is too far in the future"); // PE-T08, 15:163
        }
        inserted.push({
          device_id: deviceId,
          family_id: familyId,
          lat,
          lng,
          accuracy_m: accuracy,
          recorded_at: recordedAt.toISOString(),
          // received_at and source take their DB defaults (A3:...:277-278).
        });
      }
      if (inserted.length > 0) {
        // 14:314-315: a PLAIN insert, so a retry duplicates. Captured behaviour, preserved.
        // NO AUDIT ROW IS WRITTEN HERE (capture:106 / E13) — a location upload is unauditable.
        const { error: ierr } = await db.from("location_events").insert(inserted);
        ensureNoError(ierr, "Could not store the location points.");
      }

      // capture:110 — "safe_zones evaluation -> safe_zone_states upsert + safety_alerts insert".
      let zoneEvaluations = 0;
      let geofenceAlerts = 0;
      if (inserted.length > 0) {
        const latest = inserted.reduce(
          (a, b) => (new Date(a.recorded_at as string).getTime() >= new Date(b.recorded_at as string).getTime() ? a : b),
        );
        const { data: zones, error: zerr } = await db
          .from("safe_zones")
          .select("id, family_id, name, lat, lng, radius_m, active")
          .eq("family_id", familyId)
          .eq("active", true);
        ensureNoError(zerr, "Could not read the safe zones.");
        for (const zone of zones ?? []) {
          const inside =
            haversineMeters(latest.lat as number, latest.lng as number, zone.lat as number, zone.lng as number) <=
            (zone.radius_m as number);
          const { data: prior, error: serr } = await db
            .from("safe_zone_states")
            .select("zone_id, device_id, inside, updated_at")
            .eq("zone_id", zone.id)
            .eq("device_id", deviceId)
            .maybeSingle();
          ensureNoError(serr, "Could not read the zone state.");
          const { error: uerr2 } = await db
            .from("safe_zone_states")
            .upsert(
              { zone_id: zone.id, device_id: deviceId, inside, updated_at: new Date().toISOString() },
              { onConflict: "zone_id,device_id" }, // composite PK VERIFIED A3:...:329-334
            );
          ensureNoError(uerr2, "Could not store the zone state.");
          zoneEvaluations++;
          // Edge-triggered only: an alert when the STORED state changes. Both directions exist
          // in the DB type vocabulary (A3:...:491). No prior row => no alert (INFERRED).
          if (prior && prior.inside !== inside) {
            const exit = prior.inside === true && inside === false;
            const { error: aerr2 } = await db.from("safety_alerts").insert({
              family_id: familyId,
              device_id: deviceId,
              type: exit ? "geofence_exit" : "geofence_enter",
              severity: exit ? "warning" : "info", // INFERRED within the verified vocabulary
              message: `${exit ? "Left" : "Entered"} ${readString(zone, "name", { min: 1, max: 60 })}.`,
              payload: { zone_id: zone.id, recorded_at: latest.recorded_at },
            });
            ensureNoError(aerr2, "Could not record the geofence alert.");
            geofenceAlerts++;
          }
        }
      }
      return ok({ accepted: inserted.length, zones_evaluated: zoneEvaluations, alerts_created: geofenceAlerts });
    }

    if (action === "apps_upload") {
      // capture:111 — "apps max 500; package regex", then replace_device_apps.
      const apps = readArray(body, "apps", { max: TELEMETRY_BATCH_MAX, min: 0 }); // PE-T09 (15:165)
      const normalized: Record<string, unknown>[] = [];
      for (let i = 0; i < apps.length; i++) {
        if (apps[i] === null || typeof apps[i] !== "object" || Array.isArray(apps[i])) {
          throw new ApiError(400, "validation_error", `apps[${i}] must be an object.`);
        }
        const a = apps[i] as Record<string, unknown>;
        const row: Record<string, unknown> = { package_name: readPackageName(a["package_name"], `apps[${i}].package_name`) };
        if (typeof a["label"] === "string") row["label"] = (a["label"] as string).slice(0, 100); // A3:...:438
        if (typeof a["is_system"] === "boolean") row["is_system"] = a["is_system"];
        if (typeof a["is_suspended"] === "boolean") row["is_suspended"] = a["is_suspended"];
        if (typeof a["version_name"] === "string") row["version_name"] = (a["version_name"] as string).slice(0, 64); // A3:...:440
        normalized.push(row);
      }
      const { data, error } = await db.rpc("replace_device_apps", {
        p_device_id: deviceId, // capture:111 — BOTH ids from the authenticated device row
        p_family_id: familyId,
        p_apps: normalized,
      });
      if (error) {
        console.error(`rpc_replace_device_apps: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not store the app snapshot.");
      }
      // PE-T10 (15:166): the second upload replaces the snapshot, no duplicate rows — that
      // behaviour lives inside private.replace_device_apps, whose body is unread (PA3).
      return ok({ replaced: typeof data === "number" ? data : normalized.length });
    }

    unknownAction(action); // 15:137 pattern — 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
