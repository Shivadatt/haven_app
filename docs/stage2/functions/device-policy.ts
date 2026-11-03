// ============================================================================
// Edge Function: device-policy            TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:86-90: MINIFIED BUNDLE, 11174 chars / 2 lines, sha256 3efdb19b..., no source maps.
//
// CAPTURED FACTS USED (file:line):
//   capture:91  actions = ["update"] — exactly one
//   capture:92  auth_model = "parent JWT + verified email + requireActiveDeviceForParent"
//   capture:93  inlined_modules = cors, envelope, auth, audit, validation (NO rate_limit)
//   capture:95  if(I(e)!=="update") throw unknown_action | requireRole(parent);
//               requireActiveDeviceForParent(device_id) | strict key allowlists V/X/Z;
//               arrays capped 200; app_rules 100 | policy JSON size cap 256*1024 |
//               rpc apply_policy_version {p_device_id, p_policy, p_actor:o.user.id,
//               p_idempotency_key} | idempotent result skips audit
//   14-edge-function-security-audit.md:221-228 check 10 (allowlists reject unknown keys with
//     "policy.<key> is not allowed"; screen-time 1-1440 min; minute values 0-1439; weekday
//     1-7 with duplicate rejection; policy JSON 256 KB; app_rules 100; package arrays 200),
//     :277 (RPC failures mapped by SUBSTRING to fixed messages; the RPC's own message is
//     never returned), :344 ("Policy and payload allowlists with explicit 'not allowed'
//     errors — device-policy, device-command bundles")
//   15-edge-function-test-plan.md:140-149 PE-PL01..PL07 (400 "... is not allowed", 400 on 101
//     app_rules, 400 "policy is too large", 400 bedtime start without end, 403 D2, idempotent
//     second call with no duplicate audit)
//   docs/stage1/evidence/functions-and-triggers.md:36 apply_policy_version(p_device_id uuid,
//     p_policy jsonb, p_actor uuid, p_idempotency_key text) -> jsonb
//   docs/stage2/migrations/A3-staging-load-v1.sql:454 device_policies.policy must be a JSON
//     object; :455 version >= 1; :452 enforcement_status vocabulary
//
// TABLES TOUCHED: profiles / families / family_members / devices (SELECT via auth),
//   device_policies and device_commands (written INSIDE public.apply_policy_version — this
//   handler never touches them directly), audit_logs (INSERT).
// RPCs CALLED: public.apply_policy_version.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY.
// AUTH MODEL: parent + verified email + requireActiveDeviceForParent(device_id) — family_id
//   comes from the DEVICE ROW, never the body (14:134-135, TE-03/PE-PL07 -> 403).
// IDEMPOTENCY: PRESENT — delegated to the RPC via p_idempotency_key; an idempotent result
//   SKIPS the audit write (capture:95, PE-PL05 15:147).
// RATE LIMITING: ABSENT (capture:93; finding E7 preserved).
// AUDIT LOGGING: PRESENT (capture:93 inlines audit; PE-PL05 requires one row per real change).
// verify_jwt: NOT CAPTURED. Auth is in-handler.
//
// *** BLOCKED ON SPEC — READ THIS BEFORE DEPLOYING THIS SLUG ***
//   capture:95 names three allowlist constants in the minified bundle as `V`, `X` and `Z`
//   ("strict key allowlists V/X/Z"). Their CONTENTS ARE NOWHERE IN THE EVIDENCE. Verified
//   absence: grep of docs/stage2/S2-A6-child-app-report.md for app_rules|screen_time|
//   bedtime|allowlist|policy\.|content_filter returns NO MATCHES; no other file in the
//   repository names a single policy key. Writing plausible key names would be inventing the
//   business logic this function exists to police — a policy allowlist is the enforcement
//   surface for a parental-control product, and a wrong list either rejects real policies or
//   admits unenforceable ones.
//   Therefore: everything evidenced AROUND the allowlist is implemented (auth, device scope,
//   the 256 KB cap, the array caps, the RPC call, the idempotency/audit interaction), and the
//   allowlist itself FAILS CLOSED with 501 policy_schema_missing until the owner supplies the
//   three key sets. Supplying them is a ONE-LINE edit to TOP_LEVEL_POLICY_KEYS /
//   SUB_OBJECT_KEYS / APP_RULE_KEYS below.
//   The semantic bounds that the missing key names would carry are recorded in the validator
//   comments so nothing is lost: screen-time 1..1440 minutes, minute-of-day values 0..1439,
//   weekday 1..7 with duplicate rejection, bedtime requiring both start and end (15:148).
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import { ApiError, errorResponse, fail, ok, readJson, requireAction } from "./_shared/envelope.ts";
import { requireActiveDeviceForParent, requireRole, requireUser } from "./_shared/auth.ts";
import { recordAudit } from "./_shared/audit.ts";
import { assertAllowedKeys, readObject, readUuid } from "./_shared/validation.ts";

const POLICY_JSON_MAX = 256 * 1024; // capture:95 "policy JSON size cap 256*1024"
const POLICY_ARRAY_MAX = 200; // capture:95 "arrays capped 200"
const APP_RULES_MAX = 100; // capture:95 "app_rules 100" (name appears in the capture itself)

// ---- THE MISSING SPEC (see the BLOCKED ON SPEC banner in the header) --------
export const TOP_LEVEL_POLICY_KEYS: readonly string[] = []; // bundle constant V — NOT CAPTURED
export const SUB_OBJECT_KEYS: readonly string[] = []; // bundle constant X — NOT CAPTURED
export const APP_RULE_KEYS: readonly string[] = []; // bundle constant Z — NOT CAPTURED

/**
 * assertPolicyShape — the key-agnostic part of check 10 that IS evidenced.
 * The key-name-dependent rules are recorded here rather than dropped:
 *   - screen-time limits: integers 1..1440 minutes            (14:227) — key name unknown
 *   - window minute values: integers 0..1439                   (14:227) — key name unknown
 *   - weekday values: integers 1..7, duplicates rejected        (14:227) — key name unknown
 *   - bedtime: a start without an end is a 400                 (15:148)  — key names unknown
 * Once the owner supplies V/X/Z, extend this function with those bounds.
 */
function assertPolicyShape(node: unknown, path: string, root: boolean): void {
  if (Array.isArray(node)) {
    const cap = path.endsWith("app_rules") ? APP_RULES_MAX : POLICY_ARRAY_MAX;
    if (node.length > cap) {
      throw new ApiError(400, "validation_error", `${path} must contain at most ${cap} items.`);
    }
    node.forEach((item, i) => assertPolicyShape(item, `${path}[${i}]`, false));
    return;
  }
  if (node !== null && typeof node === "object") {
    const obj = node as Record<string, unknown>;
    if (root) assertAllowedKeys(obj, TOP_LEVEL_POLICY_KEYS, "policy");
    else assertAllowedKeys(obj, SUB_OBJECT_KEYS, path);
    for (const k of Object.keys(obj)) assertPolicyShape(obj[k], `${path}.${k}`, false);
  }
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // capture:95 — single action guard (minified `if(I(e)!=="update") throw unknown_action`).
    if (action !== "update") {
      throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
    }

    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    requireRole(profile, "parent"); // capture:95 — TE-06 / PE-PL07
    const deviceId = readUuid(body, "device_id");
    const device = await requireActiveDeviceForParent(db, auth.userId, deviceId); // capture:95

    // PE-PL04 (15:146) -> 400 "policy is too large". readObject enforces the 256 KB cap.
    const policy = readObject(body, "policy", POLICY_JSON_MAX);
    const key = (() => {
      const v = body["idempotency_key"];
      if (typeof v !== "string" || v.length < 1 || v.length > 128) {
        throw new ApiError(400, "validation_error", "idempotency_key must be 1 to 128 characters.");
      }
      return v;
    })();

    // BLOCKED ON SPEC: with no captured key sets, assertPolicyShape would reject EVERY policy
    // (empty allowlist) — which is fail-closed but useless. Rather than ship either an
    // everything-rejects or an everything-admits validator, refuse explicitly.
    if (TOP_LEVEL_POLICY_KEYS.length === 0) {
      return fail(
        501,
        "policy_schema_missing",
        "The policy key allowlists (bundle constants V/X/Z, capture:95) are not present in any " +
          "available evidence. This re-authored bundle is NOT deployable for `update` until the " +
          "owner supplies TOP_LEVEL_POLICY_KEYS / SUB_OBJECT_KEYS / APP_RULE_KEYS.",
      );
    }
    assertPolicyShape(policy, "policy", true);

    // capture:95 — rpc apply_policy_version, p_actor = the verified subject (never a body field).
    const { data, error } = await db.rpc("apply_policy_version", {
      p_device_id: device.id,
      p_policy: policy,
      p_actor: auth.userId,
      p_idempotency_key: key,
    });
    if (error) {
      console.error(`rpc_apply_policy_version: ${error.code ?? "unknown"}`);
      const m = (error.message ?? "").toLowerCase();
      // 14:277 — mapped by SUBSTRING to fixed messages; the RPC message is never forwarded.
      // PE-PL02 expects the body "policy.<key> is not allowed", but the offending key lives
      // in the RPC's message, which 14:277 forbids forwarding. A fixed sentence is used and
      // the missing key name is recorded as an UNVERIFIED detail of the error contract.
      if (m.includes("not allowed")) {
        throw new ApiError(400, "validation_error", "policy key is not allowed");
      }
      if (m.includes("too large")) throw new ApiError(400, "validation_error", "policy is too large");
      throw new ApiError(500, "internal_error", "Could not apply the policy.");
    }

    // capture:95 — "idempotent result skips audit" (PE-PL05, 15:147: no duplicate audit row).
    const idempotent = !!(
      data &&
      typeof data === "object" &&
      ((data as Record<string, unknown>)["idempotent"] === true ||
        (data as Record<string, unknown>)["idempotency"] === "replayed")
    );
    if (!idempotent) {
      await recordAudit(db, {
        eventType: "policy_updated", // UNVERIFIED name — no anchor gives the event_type string
        actorUserId: auth.userId,
        familyId: device.family_id,
        deviceId: device.id,
        targetType: "policy",
        targetId: null,
        metadata: { idempotency_key: key },
      });
    }
    // UNVERIFIED BEHAVIOUR — response shape not captured.
    return ok({ result: data ?? null, idempotent });
  } catch (err) {
    return errorResponse(err);
  }
});
