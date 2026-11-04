// device-telemetry / usage_apps — actions "usage_upload" (capture:109) and
// "apps_upload" (capture:111).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors unchanged. The device
// credential gate (capture:105) runs in `index.ts`; both ids come from the authenticated device
// row, never the body.
//
// UNVERIFIED BEHAVIOUR carried from the index.ts header:
//   - The `source` column is intentionally NOT sent on usage rows: usage_daily_source DEFAULT
//     'usage_stats' (A3:...:371) is the database's own value and no capture anchor names another.
//   - PE-T10's replace semantics live inside private.replace_device_apps, whose body is unread.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import type { DbClient } from "../_shared/auth.ts";
import {
  isRealDate,
  parseTimestamp,
  readArray,
  readInt,
  readPackageName,
  readString,
} from "../_shared/validation.ts";
import { TELEMETRY_BATCH_MAX } from "./limits.ts";

const USAGE_DAY_FUTURE_MS = 36 * 60 * 60 * 1000; // capture:109 — "not beyond now+36h"

export async function handleUsageUpload(
  db: DbClient,
  device: Record<string, unknown>,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = device.id as string;
  const familyId = device.family_id as string;

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
    if (typeof e["last_used_at"] === "string") {
      row["last_used_at"] = parseTimestamp(e["last_used_at"] as string, "last_used_at").toISOString();
    }
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

export async function handleAppsUpload(
  db: DbClient,
  device: Record<string, unknown>,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = device.id as string;
  const familyId = device.family_id as string;

  // capture:111 — "apps max 500; package regex", then replace_device_apps.
  const apps = readArray(body, "apps", { max: TELEMETRY_BATCH_MAX, min: 0 }); // PE-T09 (15:165)
  const normalized: Record<string, unknown>[] = [];
  for (let i = 0; i < apps.length; i++) {
    if (apps[i] === null || typeof apps[i] !== "object" || Array.isArray(apps[i])) {
      throw new ApiError(400, "validation_error", `apps[${i}] must be an object.`);
    }
    const a = apps[i] as Record<string, unknown>;
    const row: Record<string, unknown> = {
      package_name: readPackageName(a["package_name"], `apps[${i}].package_name`),
    };
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
