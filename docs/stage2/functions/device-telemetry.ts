// ============================================================================
// Edge Function: device-telemetry         TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:101-103: MINIFIED BUNDLE, 12461 chars / 2 lines, sha256 b3ca5221..., no source maps.
//   14:48 records this slug's overall verdict as PARTIAL (abuse checks E7/E13).
//
// CAPTURED FACTS USED (file:line):
//   capture:104 actions = heartbeat, usage_upload, location_upload, apps_upload
//   capture:105 auth_model = "device only (x-device-id + x-device-secret); device_id and
//               family_id always taken from the authenticated device row"
//   capture:106 inlined_modules = cors, envelope, auth, validation
//             *** NO `audit` MODULE ***  -> this function writes ZERO audit rows.
//               That absence is the captured behaviour (finding E13) and is PRESERVED here,
//               not silently repaired: adding recordAudit would change what the deployed
//               function does and would need an A7-R decision. See DEPLOYMENT-MAP.md.
//   capture:108 heartbeat: battery_level 0..100, is_charging, online, capabilities allowlist |
//               devices.update scoped .eq(id, device.id) | low_battery alert deduped in a
//               6-hour window | returns pending_policy_version
//   capture:109 usage_upload: entries max 500; day must be a real date and not beyond
//               now+36h | upsert usage_daily onConflict device_id,day,package_name | rows
//               carry device_id/family_id from the device row
//   capture:110 location_upload: lat -90..90, lng -180..180, accuracy_m 0..1e5 | recorded_at
//               window -7d .. +5min | location_events insert with device-derived ids |
//               safe_zones evaluation -> safe_zone_states upsert + safety_alerts insert
//   capture:111 apps_upload: apps max 500; package regex | rpc replace_device_apps
//               {p_device_id:device.id, p_family_id:device.family_id, p_apps}
//   14-edge-function-security-audit.md:224 (telemetry batches 500), :226-227 (semantic bounds),
//     :311-314 (check 16: usage_daily/safe_zone_states upsert keys, apps snapshot replacement,
//     heartbeat last-writer-wins; location_events is a PLAIN insert so a retry duplicates —
//     recorded there as a data-quality note, not a finding), :296 (device-originated events
//     would carry a null actor — moot here, no audit at all)
//   15-edge-function-test-plan.md:152-167 PE-T01..T12 (400 battery 101; one low_battery alert
//     per 6 h; "cannot be in the future"; duplicate (day,package) in one batch -> 400;
//     lat 91 -> 400; "older than seven days"; "too far in the future"; 501 apps -> 400;
//     second apps_upload replaces the snapshot; PE-T11 wrong-secret 401; PE-T12: 100 uploads
//     in 60 s are ALL ACCEPTED today)
//   docs/stage2/migrations/A3-staging-load-v1.sql:269-279 location_events (source DEFAULT
//     'device', received_at DEFAULT now()), :361-372 usage_daily (source DEFAULT 'usage_stats',
//     app_label DEFAULT ''), :329-334 safe_zone_states composite PK (zone_id, device_id),
//     :336-346 safe_zones (active DEFAULT true), :348-359 safety_alerts (payload DEFAULT '{}'),
//     :489-491 severity info|warning|critical and type low_battery|offline|geofence_enter|
//     geofence_exit|app_blocked|permission_missing|other, :1007-1029 the explicit
//     service_role UPDATE grants on exactly the six *_granted columns of devices
//
// TABLES TOUCHED: devices (SELECT via requireDevice, UPDATE), location_events (INSERT),
//   usage_daily (UPSERT), safe_zones (SELECT), safe_zone_states (UPSERT), safety_alerts
//   (INSERT), audit_logs (NOT TOUCHED — see capture:106 above).
// RPCs CALLED: public.replace_device_apps(p_device_id, p_family_id, p_apps) -> integer.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. The device secret is digested and compared,
//   never stored raw and never returned.
// AUTH MODEL: device credential only. NO user JWT path exists on this slug. family_id and
//   device_id are taken from the authenticated device row for EVERY write (capture:105), so a
//   body-supplied family_id or device_id is structurally ignored (TE-19/PE-T11 -> 401/400).
// IDEMPOTENCY: PARTIAL — usage_daily and safe_zone_states are keyed upserts and apps_upload
//   replaces the whole snapshot; location_events is a PLAIN insert, so a retried upload
//   duplicates points. That is the captured behaviour (14:314-315) and is preserved.
// RATE LIMITING: ABSENT — and ABSENT IN THE CAPTURED BUNDLE (capture:106 has no rate_limit).
//   PE-T12 (15:167) records that 100 location uploads in 60 s are all accepted. Preserved
//   verbatim; finding E7. This is the single most exploitable gap in this slug.
// AUDIT LOGGING: ABSENT BY CAPTURE (E13). Disclosed rather than fixed.
// verify_jwt: NOT CAPTURED. Authentication is the device credential channel.
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - CAPABILITIES ALLOWLIST CONTENT. capture:108 says only "capabilities allowlist". The six
//     *_granted columns (usage_access_granted, location_granted, background_location_granted,
//     camera_granted, microphone_granted, notifications_granted) are used because those are
//     EXACTLY the devices columns carrying explicit service_role UPDATE grants
//     (A3:...:1007-1029) and no other devices column matches a "capability". INFERRED, not
//     captured. Body key names for them are also not captured, so the body is read as an
//     object keyed by the COLUMN names; if production uses different JSON keys, this differs.
//   - LOW_BATTERY THRESHOLD VALUE is not captured (PE-T03 only shows battery 5 firing).
//     LOW_BATTERY_THRESHOLD_PERCENT below is a PLACEHOLDER.
//   - `online` has NO matching column in devices (schema-columns.md:99-128). It is honoured
//     by writing last_seen_at when true and leaving it untouched when false. INFERRED.
//   - SAFETY-ALERT SEVERITY/MESSAGE strings are not captured; the vocabulary is DB-verified
//     (A3:...:490-491) but the choice of 'warning' vs 'info' and the message text are not.
//   - GEOFENCE RULE. capture:110 says "safe_zones evaluation -> safe_zone_states upsert +
//     safety_alerts insert". The alert TYPES geofence_enter AND geofence_exit both exist in
//     the DB vocabulary (A3:...:491), so BOTH transitions are implemented as edge-triggered
//     alerts against the stored prior state. Which transitions production actually alerts on,
//     whether an initial (no prior state row) evaluation alerts, and any per-zone dedupe
//     window are NOT captured. Do not assume parity.
//   - Batch array KEY NAMES: `entries` and `apps` are verbatim from capture:109/:111; the
//     location array name is not captured (`points` used).
//   - `pending_policy_version` derivation (highest unacknowledged device_policies.version) is
//     INFERRED; capture:108 names only the field.
//   - Heartbeat write ordering vs the low-battery alert, and whether the alert is written
//     before or after the device update, is not captured.
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import { ApiError, ensureNoError, errorResponse, ok, readJson, requireAction, unknownAction } from "./_shared/envelope.ts";
import { getServiceClient, requireDevice } from "./_shared/auth.ts";
import { isRealDate, parseTimestamp, readArray, readBoolean, readInt, readNumber, readObject, readPackageName, readString } from "./_shared/validation.ts";

const BATTERY_MIN = 0;
const BATTERY_MAX = 100; // VERIFIED: capture:108 and devices_battery_level_check (A3:...:458)
const LOW_BATTERY_THRESHOLD_PERCENT = 20; // PLACEHOLDER — value not captured
const LOW_BATTERY_DEDUPE_HOURS = 6; // capture:108 — "deduped in a 6-hour window"
const TELEMETRY_BATCH_MAX = 500; // capture:109, :111 ("entries max 500", "apps max 500"); 14:224
const USAGE_DAY_FUTURE_MS = 36 * 60 * 60 * 1000; // capture:109 — "not beyond now+36h"
const LOCATION_MIN_LAT = -90;
const LOCATION_MAX_LAT = 90;
const LOCATION_MIN_LNG = -180;
const LOCATION_MAX_LNG = 180;
const LOCATION_MAX_ACCURACY_M = 100_000; // capture:110 — 0..1e5
const RECORDING_MAX_AGE_DAYS = 7; // capture:110 — "-7d"
const RECORDING_MAX_FUTURE_MS = 5 * 60 * 1000; // capture:110 — "+5min"
const EARTH_RADIUS_M = 6_371_000;

/** INFERRED from A3:...:1007-1029 (see the UNVERIFIED list in the header). */
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
    // (status != 'active' OR credential_revoked_at NOT NULL -> 401), see _shared/auth.ts.
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

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
