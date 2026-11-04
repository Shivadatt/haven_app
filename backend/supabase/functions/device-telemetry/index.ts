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
//
// LAYOUT: this file is the device-credential gate plus the action dispatch. The four actions
//   live beside it — ./heartbeat.ts, ./usage_apps.ts (usage_upload + apps_upload), ./location.ts
//   and the shared ./limits.ts. Split at port time for the 200-line source rule; behaviour,
//   labels and anchors unchanged. Read all of them together with this header.
// ============================================================================

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { getServiceClient, requireDevice } from "../_shared/auth.ts";
import { handleHeartbeat } from "./heartbeat.ts";
import { handleLocationUpload } from "./location.ts";
import { handleAppsUpload, handleUsageUpload } from "./usage_apps.ts";

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

    switch (action) {
      case "heartbeat":
        return await handleHeartbeat(db, device, body);
      case "usage_upload":
        return await handleUsageUpload(db, device, body);
      case "location_upload":
        return await handleLocationUpload(db, device, body);
      case "apps_upload":
        return await handleAppsUpload(db, device, body);
      default:
        unknownAction(action);
    }
  } catch (err) {
    return errorResponse(err);
  }
});
