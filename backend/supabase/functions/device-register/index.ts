// ============================================================================
// Edge Function: device-register          TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:73-74: MINIFIED BUNDLE, 9086 chars / 2 lines, sha256 712d46b0..., no source maps
//   (14:409). Re-authored from the anchor spec; NO PARITY VERIFICATION with the bundle.
//
// LAYOUT: this file is the request gate — action, identity, role, email, body readers and
//   family membership. The devices writes live in ./register_flow.ts (split at port time for
//   the 200-line source rule; behaviour and labels unchanged). Read both together.
//
// CAPTURED FACTS USED (file:line):
//   capture:78  actions = ["register"] — exactly one
//   capture:79  auth_model = "child JWT + verified email + assertChildMembership(body family_id)"
//   capture:80  inlined_modules = cors, envelope, auth, audit, validation (NO rate_limit)
//   capture:82  single action guard if(n!=="register") throw unknown_action |
//               readUuid(family_id), readInstallationId, readHex64(secret_hash) |
//               assertChildMembership(family_id from body) | existing installation in family
//               -> child mismatch = 409 device_exists | revoked device + later approved
//               pairing -> device_registration_blocked | insert/update devices with
//               secret_hash from client | response strips secret_hash and installation_id (H()) |
//               audit device_registered / device_recredentialed / device_registration_blocked
//               with actorUserId = JWT user
//   14-edge-function-security-audit.md:146-147 (installation id looked up WITHIN the asserted
//     family; a row belonging to another child returns 409 device_exists), :254-255 and :341
//     (credentials stripped from the response), :230 (finding E10: the secret is CLIENT-CHOSEN)
//   15-edge-function-test-plan.md:128-138 PE-R01..R07
//   docs/stage1/evidence/schema-columns.md:99-128 devices column whitelist
//   docs/stage2/migrations/A3-staging-load-v1.sql:221-247 (defaults: platform 'android',
//     status 'pending', enforcement_mode 'none', policy_version 0; id DEFAULT gen_random_uuid),
//     :427 UNIQUE (family_id, installation_id), :459 display_name 1..80, :461 installation_id
//     8..128, :462 platform 1..32, :465 secret_hash '^[0-9a-f]{64}$', :466 status
//     pending|active|revoked, :464 status='revoked' => secret_hash IS NULL,
//     :480 family_members_one_active_child_family, :572 devices_one_active_per_child
//
// TABLES TOUCHED: profiles / families / family_members (SELECT via auth), devices (SELECT,
//   INSERT, UPDATE), child_contact_ids (none), audit_logs (INSERT).
// RPCs CALLED: NONE — capture:82 shows a direct insert/update on `devices` from this handler.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. The device secret arrives as a CLIENT-SUPPLIED
//   64-hex digest (`secret_hash`) and is stored as supplied — finding E10, preserved because
//   changing it breaks the Android client contract. The digest is never returned.
// AUTH MODEL: child JWT, verified email, assertChildMembership on the BODY family_id — the
//   only captured path where the body legitimately names the family, because membership is
//   asserted before use (capture:82). The child id is auth.user.id, never body-supplied.
// IDEMPOTENCY: (family_id, installation_id) is UNIQUE, so a repeat register becomes a
//   re-credential UPDATE rather than a second row (PE-R03, 15:133). devices_one_active_per_child
//   (A3:...:572) is the collision guard for a second active device on one child.
// RATE LIMITING: ABSENT (capture:80 does not inline rate_limit); finding E7 preserved.
// AUDIT LOGGING: PRESENT for all three outcomes, including the BLOCKED outcome, which is
//   audited BEFORE the 403 is returned (capture:82 names device_registration_blocked as an
//   audit event, so a denial leaves a trace).
// verify_jwt: NOT CAPTURED. Auth is in-handler.
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - THE REVOKED-DEVICE GUARD DIRECTION. capture:82 says "revoked device + later approved
//     pairing -> device_registration_blocked", which is directionally ambiguous: it can mean
//     (a) a later approved pairing unblocks a revoked registration, or (b) a revoked device
//     whose child has since re-paired must not reclaim credentials. Neither reading is
//     evidenced. register_flow.ts implements (b) FAIL-CLOSED — every revoked match is a 403 —
//     behind the one-flag constant ALLOW_RELINK_AFTER_REVOKED_PAIRING there. Resolve the
//     ambiguity before deploying; this is one of the three weakest links in the package.
//   - Fourth reader: `display_name` is NOT NULL with no default (A3:...:226), so a register
//     insert MUST supply it, yet capture:82 names only three readers. Read from the body and
//     labelled as an inferred reader. If production derives it server-side, this differs.
//   - `credential_issued_at` is set to now on both paths; not anchored. INFERRED.
//   - `status` is set to 'active' on success, because requireDevice refuses every non-active
//     device (_shared/device_authority.ts, 14:153-156) and PE-R01 must yield a working device.
//     The write itself is not anchored. INFERRED.
//   - android_version / app_version / platform / enforcement_mode readers are not anchored;
//     read optionally with the DDL bounds and left to the column defaults otherwise.
//   - Response shape beyond "secret_hash and installation_id are absent" is not captured.
// ============================================================================

import { handleCors } from "../_shared/cors.ts";
import { ApiError, errorResponse, readJson, requireAction } from "../_shared/envelope.ts";
import { assertChildMembership, requireUser } from "../_shared/auth.ts";
import { readHex64, readOptionalString, readString, readUuid } from "../_shared/validation.ts";
import { readInstallationId, registerDevice } from "./register_flow.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // capture:82 — single action guard. Anything else is a 400 unknown_action, never a no-op
    // (PE-R07, 15:137).
    if (action !== "register") {
      throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
    }

    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    if (profile.role !== "child") {
      throw new ApiError(403, "role_required", "This action requires the child role.");
    }

    const familyId = readUuid(body, "family_id"); // capture:82 readUuid(family_id)
    const installationId = readInstallationId(body);
    const secretHash = readHex64(body, "secret_hash"); // capture:82 readHex64 — '^[0-9a-f]{64}$' (A3:...:465)
    const displayName = readString(body, "display_name", { min: 1, max: 80 }); // inferred reader, see header
    const androidVersion = readOptionalString(body, "android_version", { min: 1, max: 40 });
    const appVersion = readOptionalString(body, "app_version", { min: 1, max: 40 });

    // capture:82 — assertChildMembership(family_id FROM THE BODY). Blocks PE-R02 (15:132)
    // with 403 before any device row is touched.
    await assertChildMembership(db, auth.userId, familyId);

    // The re-credential path and the fresh-insert path. Split out for the project's 200-line
    // source rule; the gates above run first and are unchanged.
    return await registerDevice(db, auth.userId, {
      familyId,
      installationId,
      displayName,
      androidVersion,
      appVersion,
      secretHash,
    });
  } catch (err) {
    return errorResponse(err);
  }
});
