// family-admin / retention — actions "purge_data" and "update_retention".
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors unchanged. The
// parent-role gate and the verified identity run in `index.ts` BEFORE either function here.
//
// Retention key names and defaults are DATABASE-VERIFIED: families.settings DEFAULT
// '{"usage_retention_days": 90, "location_retention_days": 30}' (A3-staging-load-v1.sql:253),
// which matches capture:127's "retention defaults 30/90" exactly.
//
// UNVERIFIED (carried from index.ts):
//   - purge_data accepts only the evidenced `older_than_days` (15:176) as a single floor
//     applied to both datasets; per-dataset overrides are not evidenced and are not accepted.
//   - location_events is compared against `recorded_at`; `received_at` is the alternative.
//   - RETENTION_MIN_DAYS / RETENTION_MAX_DAYS are PLACEHOLDERS: no bound is captured; 1..3650
//     exists solely to reject PE-F07's `0` (15:178).
//   - update_retention MERGES into settings (INFERRED) so it cannot destroy a sibling key.
// ============================================================================

import { assertFamilyOwner, assertFamilyParent, type DbClient } from "../_shared/auth.ts";
import { ensureNoError, ok } from "../_shared/envelope.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readInt, readUuid } from "../_shared/validation.ts";

const DEFAULT_LOCATION_RETENTION_DAYS = 30; // capture:127 + A3:...:253 default
const DEFAULT_USAGE_RETENTION_DAYS = 90; // capture:127 + A3:...:253 default
const RETENTION_MIN_DAYS = 1; // PLACEHOLDER — only `0` is evidenced as invalid (15:178)
const RETENTION_MAX_DAYS = 3650; // PLACEHOLDER

export const SETTINGS_LOCATION_KEY = "location_retention_days"; // DATABASE-VERIFIED (A3:...:253)
export const SETTINGS_USAGE_KEY = "usage_retention_days";

export async function purgeData(
  db: DbClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const familyId = readUuid(body, "family_id");
  await assertFamilyParent(db, userId, familyId); // capture:127 "family asserted"

  // The FLOOR is max(requested, configured) — capture:127. PE-F05 (15:176): requesting 1 day
  // with a 30-day retention deletes nothing recent.
  const { data: family, error: ferr } = await db
    .from("families")
    .select("id, settings, owner_id, deleted_at")
    .eq("id", familyId)
    .maybeSingle();
  ensureNoError(ferr, "Could not read the family settings.");
  const settings = (family?.settings ?? {}) as Record<string, unknown>;
  const configuredLocation = typeof settings[SETTINGS_LOCATION_KEY] === "number"
    ? settings[SETTINGS_LOCATION_KEY] as number
    : DEFAULT_LOCATION_RETENTION_DAYS;
  const configuredUsage = typeof settings[SETTINGS_USAGE_KEY] === "number"
    ? settings[SETTINGS_USAGE_KEY] as number
    : DEFAULT_USAGE_RETENTION_DAYS;

  const requested = body["older_than_days"] === undefined || body["older_than_days"] === null
    ? 0
    : readInt(body, "older_than_days", { min: 0, max: 36500 });
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
    actorUserId: userId,
    familyId,
    deviceId: null,
    targetType: "family",
    targetId: familyId,
    metadata: {
      location_events: locationDeleted ?? 0,
      usage_daily: usageDeleted ?? 0,
      location_days: locationDays,
      usage_days: usageDays,
    },
  });
  return ok({ location_events_deleted: locationDeleted ?? 0, usage_daily_deleted: usageDeleted ?? 0 });
}

export async function updateRetention(
  db: DbClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const familyId = readUuid(body, "family_id");
  // capture:128 — "owner_required via O()". assertFamilyOwner is that check, and it also
  // re-asserts the family is live before the write.
  const family = await assertFamilyOwner(db, userId, familyId);
  const locationDays = readInt(body, SETTINGS_LOCATION_KEY, { min: RETENTION_MIN_DAYS, max: RETENTION_MAX_DAYS }); // PE-F07: 0 -> 400
  const usageDays = readInt(body, SETTINGS_USAGE_KEY, { min: RETENTION_MIN_DAYS, max: RETENTION_MAX_DAYS });

  const current = (family.settings ?? {}) as Record<string, unknown>;
  const nextSettings = { ...current, [SETTINGS_LOCATION_KEY]: locationDays, [SETTINGS_USAGE_KEY]: usageDays };
  const { error: uerr } = await db
    .from("families")
    .update({ settings: nextSettings })
    .eq("id", familyId)
    .eq("owner_id", userId) // double scope: owner predicate in the write itself
    .is("deleted_at", null);
  ensureNoError(uerr, "Could not update the retention settings.");
  await recordAudit(db, {
    eventType: "settings_updated", // capture:128
    actorUserId: userId,
    familyId,
    deviceId: null,
    targetType: "family",
    targetId: familyId,
    metadata: { [SETTINGS_LOCATION_KEY]: locationDays, [SETTINGS_USAGE_KEY]: usageDays },
  });
  return ok({ settings: nextSettings });
}
