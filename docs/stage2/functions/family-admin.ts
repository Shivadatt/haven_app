// ============================================================================
// Edge Function: family-admin             TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:116-119: MINIFIED BUNDLE, 9386 chars / 2 lines, sha256 b6864fdd..., no source maps.
//
// CAPTURED FACTS USED (file:line):
//   capture:120 actions = revoke_device, recover_device, ack_alert, purge_data, update_retention
//   capture:121 auth_model = "parent JWT + verified email for every action; update_retention
//               additionally owner-only"
//   capture:122 inlined_modules = cors, envelope, auth, audit, validation (NO rate_limit)
//   capture:124 rpc revoke_device {p_device_id, p_actor_user_id:i.user.id}
//   capture:125 rpc request_device_recovery {p_device_id, p_actor_user_id:i.user.id}
//   capture:126 ack_alert: safety_alerts select by alert_id, family asserted before update;
//               audit alert_acknowledged
//   capture:127 purge_data: family asserted; retention defaults 30/90 days, floor =
//               max(requested, configured); delete location_events and usage_daily scoped
//               .eq(family_id); audit data_purged with counts
//   capture:128 update_retention: owner_required via O(); families.update settings; audit
//               settings_updated
//   14-edge-function-security-audit.md:53-55 and :149-152 — "*** family-admin scope is PASS*
//     because revoke_device delegates its ONLY authorisation to private.revoke_device, whose
//     body is one of the 24 unread implementations ... the handler only checks that the caller
//     is a parent somewhere ***". recover_device IS fully verified because
//     private.request_device_recovery's body was read in B3b and asserts an active parent of
//     the device's family.
//   15-edge-function-test-plan.md:168-178 PE-F01..F07 (revoke 200 + credential nulled; other
//     family 403; recover 200 `recovery: started` + audit device_recovery_started; ack_alert
//     other family 403; purge cutoff floored at 30; update_retention by a non-owner parent
//     403 owner_required; location_days 0 -> 400)
//   docs/stage1/evidence/functions-and-triggers.md:45,48 RPC signatures
//   docs/stage2/migrations/A3-staging-load-v1.sql:253 families.settings DEFAULT
//     '{"usage_retention_days": 90, "location_retention_days": 30}' — the retention KEY NAMES
//     ARE DATABASE-VERIFIED and match capture:127's "defaults 30/90" exactly
//   docs/stage1/evidence/g1-b3b-20261029.json — private.unlink_child / request_device_recovery
//     bodies (the read predicate is an active parent of the device's family)
//
// TABLES TOUCHED: profiles / families / family_members (SELECT via auth), devices (SELECT for
//   the hardening scope check; the UPDATE happens inside the RPC), safety_alerts (SELECT,
//   UPDATE), location_events (DELETE), usage_daily (DELETE), audit_logs (INSERT — all four
//   audited actions plus the recovery start).
// RPCs CALLED: public.revoke_device, public.request_device_recovery.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY.
// AUTH MODEL: parent + verified email for all five actions; owner for update_retention. The
//   actor passed to every RPC is i.user.id == auth.user.id (capture:124-125), never a body
//   field. Target ids (device_id, alert_id, family_id) come from the body and are resolved and
//   scoped first (14:100-106).
// IDEMPOTENCY: purge_data is naturally idempotent (cutoff-based delete, 14:313); ack_alert is
//   a last-writer-wins acknowledgement; the two RPCs own their state transitions.
// RATE LIMITING: ABSENT (capture:122; finding E7 preserved) — note this slug performs
//   DESTRUCTIVE actions, so a burst of purge_data calls is capacity abuse, not access abuse.
// AUDIT LOGGING: PRESENT — alert_acknowledged, data_purged (with counts), settings_updated
//   (capture:126-128) and device_recovery_started (15:173). revoke_device's audit event name is
//   NOT in any anchor; see UNVERIFIED below.
// verify_jwt: NOT CAPTURED. Auth is in-handler.
//
// HARDENING DEVIATION (explicit, per the brief's "every protected operation must authorise
// inside the function; never rely on RLS for a service-role path"):
//   The captured handler authorises `revoke_device` only as "a parent somewhere" and delegates
//   the family check to private.revoke_device, whose body is unread (14:149-152). This
//   re-authoring loads the device and asserts parent membership in THAT device's family before
//   the RPC. It is STRICTER than the captured function; a legitimate call that production would
//   have accepted from an unrelated parent is impossible in either version (the RPC still
//   checks), so the only observable difference is which layer rejects first.
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - `audit event_type for revoke_device` — no anchor names it. `device_revoked` used here;
//     a dashboard that filters on the real string will miss these rows.
//   - purge_data request field names beyond the evidenced `older_than_days` (15:176) are not
//     captured; separate location_days/usage_days overrides are NOT accepted, only the single
//     requested floor, applied to both datasets, because that is all the evidence supports.
//   - Which timestamp column purge_data compares against: location_events.recorded_at chosen;
//     received_at is the alternative. UNVERIFIED.
//   - ack_alert does not move the alert out of any queue or mark it read beyond
//     acknowledged_at/acknowledged_by — the anchors name only those.
//   - Retention bounds for update_retention: no minimum or maximum is captured. 1..3650 is used
//     purely to reject PE-F07's `0`, and is a documented PLACEHOLDER.
//   - Whether update_retention merges into settings or replaces it: merge chosen (settings is a
//     jsonb object with two keys, A3:...:253) and labelled INFERRED.
//   - Response shapes for all five actions are not captured.
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import { ApiError, ensureNoError, errorResponse, ok, readJson, requireAction, unknownAction } from "./_shared/envelope.ts";
import { assertFamilyOwner, assertFamilyParent, requireRole, requireUser } from "./_shared/auth.ts";
import { recordAudit } from "./_shared/audit.ts";
import { readInt, readUuid } from "./_shared/validation.ts";

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

      // INFERRED merge (see header): settings is a two-key object, so preserving siblings is
      // the only reading that cannot destroy another setting.
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
