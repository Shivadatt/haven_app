// device-telemetry / heartbeat — action "heartbeat" (capture:108).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors unchanged. The device
// credential gate (capture:105) runs in `index.ts` and the authenticated device row is passed in
// — `device_id` and `family_id` are never read from the body.
//
// UNVERIFIED BEHAVIOUR carried from the index.ts header:
//   - `last_seen_at` is written when `online === true` (INFERRED).
//   - LOW_BATTERY_THRESHOLD_PERCENT is a PLACEHOLDER: the value is not captured. The 6-hour
//     dedupe window IS captured (capture:108).
//   - The alert severity "warning" and the message text are INFERRED within the verified
//     vocabulary (A3:...:491).
//   - Write ordering vs the low-battery alert is not captured.
//   - `pending_policy_version` derivation (highest unacknowledged device_policies.version) is
//     INFERRED; capture:108 names only the field.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import type { DbClient } from "../_shared/auth.ts";
import { readBoolean, readInt, readObject } from "../_shared/validation.ts";

const BATTERY_MIN = 0;
const BATTERY_MAX = 100; // VERIFIED: capture:108 and devices_battery_level_check (A3:...:458)
const LOW_BATTERY_THRESHOLD_PERCENT = 20; // PLACEHOLDER — value not captured
const LOW_BATTERY_DEDUPE_HOURS = 6; // capture:108 — "deduped in a 6-hour window"

/** INFERRED from A3:...:1007-1029 (see the UNVERIFIED list in the index.ts header). */
const CAPABILITIES = [
  "usage_access_granted",
  "location_granted",
  "background_location_granted",
  "camera_granted",
  "microphone_granted",
  "notifications_granted",
] as const;

export async function handleHeartbeat(
  db: DbClient,
  device: Record<string, unknown>,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = device.id as string;
  const familyId = device.family_id as string;

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
