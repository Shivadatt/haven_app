// device-telemetry / location — action "location_upload" and the safe-zone evaluation it
// triggers (capture:110).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors unchanged. The device
// credential gate (capture:105) runs in `index.ts`; both ids come from the authenticated device
// row, never the body.
//
// UNVERIFIED BEHAVIOUR carried from the index.ts header:
//   - The batch array KEY NAME is not captured; `points` is used. (`entries` and `apps` ARE
//     verbatim from capture:109/:111.)
//   - 14:314-315: a PLAIN insert, so a retry duplicates. Captured behaviour, preserved.
//   - GEOFENCE RULE. capture:110 says "safe_zones evaluation -> safe_zone_states upsert +
//     safety_alerts insert". Both alert types exist in the DB vocabulary (A3:...:491), so BOTH
//     transitions are implemented as edge-triggered alerts against the stored prior state.
//     Which transitions production alerts on, whether an initial (no prior state row) evaluation
//     alerts, and any per-zone dedupe window are NOT captured. Do not assume parity.
//   - The geofence alert severity ("warning" on exit, "info" on enter) is INFERRED within the
//     verified vocabulary.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import type { DbClient } from "../_shared/auth.ts";
import { parseTimestamp, readArray, readNumber, readString } from "../_shared/validation.ts";
import { TELEMETRY_BATCH_MAX } from "./limits.ts";

const LOCATION_MIN_LAT = -90;
const LOCATION_MAX_LAT = 90;
const LOCATION_MIN_LNG = -180;
const LOCATION_MAX_LNG = 180;
const LOCATION_MAX_ACCURACY_M = 100_000; // capture:110 — 0..1e5
const RECORDING_MAX_AGE_DAYS = 7; // capture:110 — "-7d"
const RECORDING_MAX_FUTURE_MS = 5 * 60 * 1000; // capture:110 — "+5min"
const EARTH_RADIUS_M = 6_371_000;

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(a)));
}

export async function handleLocationUpload(
  db: DbClient,
  device: Record<string, unknown>,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = device.id as string;
  const familyId = device.family_id as string;

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
      (a, b) =>
        (new Date(a.recorded_at as string).getTime() >= new Date(b.recorded_at as string).getTime() ? a : b),
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
