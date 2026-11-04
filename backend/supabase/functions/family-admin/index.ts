// ============================================================================
// Edge Function: family-admin             TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:116-119: MINIFIED BUNDLE, 9386 chars / 2 lines, sha256 b6864fdd..., no source maps.
//
// LAYOUT: this file is the shared gate — action, identity, verified email, parent role — plus
//   the dispatch. The five actions live in ./device_actions.ts (revoke, recover), ./alerts.ts
//   (ack_alert) and ./retention.ts (purge_data, update_retention). Split at port time for the
//   200-line source rule; behaviour, labels and anchors unchanged. Read all four together.
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

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { requireRole, requireUser } from "../_shared/auth.ts";
import { acknowledgeAlert } from "./alerts.ts";
import { recoverDevice, revokeDevice } from "./device_actions.ts";
import { purgeData, updateRetention } from "./retention.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    requireRole(profile, "parent"); // capture:121 — parent for every action (14:119)

    // capture:120 — the five actions of this slug. Each lives in the module named by its
    // subject; the identity, role, email and parent-role gates above are shared by all five.
    switch (action) {
      case "revoke_device":
        return await revokeDevice(db, auth.userId, body);
      case "recover_device":
        return await recoverDevice(db, auth.userId, body);
      case "ack_alert":
        return await acknowledgeAlert(db, auth.userId, body);
      case "purge_data":
        return await purgeData(db, auth.userId, body);
      case "update_retention":
        return await updateRetention(db, auth.userId, body);
      default:
        return unknownAction(action); // 15:137 — never a silent no-op
    }
  } catch (err) {
    return errorResponse(err);
  }
});
