// ============================================================================
// Edge Function: auth-bootstrap          TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   Required A7-R Option 2 label (docs/stage2/approval-package-v3-implementation-instruments.md §7).
//   WHY THIS LABEL APPLIES EVEN THOUGH capture:45 calls this "readable TypeScript":
//   the repository holds NO literal source text for any Edge Function. Only the anchor
//   line-numbers survived (docs/stage1/13-edge-function-source-inventory.md §1 —
//   supabase/functions/ is ABSENT; S2-A4 finding A4-F13 — the pairing/ subdirectory
//   implied by capture:10 exists with 0 entries; S2-A7 test T-07 says every
//   "pairing/index.ts:<n>" anchor "resolves to a dashboard capture, not to a repository
//   file"). So the 140 lines of the deployed file cannot be reproduced; only re-authored.
//   Digest of the deployed file: 34cf673247a61a91dbeda77c14c06d01184aad7a0724b5f7eaeb9d2f85b7383b
//   (capture:48). digest not computed for this re-authoring (terminal prohibited).
//
// CAPTURED FACTS USED (file:line):
//   capture-20261030.json:49  actions = ["set_role","create_family"]  (nothing else exists)
//   capture-20261030.json:50  auth_model = "user JWT + verified email; set_role is self-only
//                              and one-time from 'unset'; create_family is parent-only"
//   capture-20261030.json:51  imports audit/auth/cors/envelope/validation — NO rate_limit
//   capture-20261030.json:53  38: requireUser(requireVerifiedEmail)
//   capture-20261030.json:54  44-50 reject a different existing role; 53-58 profiles.update
//                              scoped .eq(id, auth.user.id); 61-67 recordAudit role_set;
//                              72-80 child_contact_ids upsert (best effort)
//   capture-20261030.json:55  93: requireRole(parent); 96-109 one active family per owner;
//                              111-114 rpc create_family_with_owner p_owner = auth.user.id
//   14-edge-function-security-audit.md:110 role table; :124 role comes from profiles.role
//     read with the service-role client; :245 service role => RLS never applies
//   15-edge-function-test-plan.md:106-111 PE-A01..A06 expected codes
//   docs/stage1/evidence/functions-and-triggers.md:37 create_family_with_owner(p_owner uuid, p_name text) -> jsonb
//   docs/stage2/migrations/A3-staging-load-v1.sql:479 profiles role IN (unset,parent,child);
//     :467 families name 1..80; :468 families.settings must be a JSON object
//   docs/stage2/S2-EXEC-08-identity-decision-A13-final.md §2(3): the verified-email reading is
//     Supabase's email_confirmed_at today and must sit behind one named seam.
//
// TABLES TOUCHED: profiles (SELECT via auth, UPDATE), families (SELECT, INSERT via RPC),
//   child_contact_ids (UPSERT, best effort), audit_logs (INSERT).
// RPCs CALLED: public.create_family_with_owner.
// SECRETS BY NAME (no values): SUPABASE_SERVICE_ROLE_KEY (via _shared/auth). No client-side
//   path in this file receives any service-role credential. A9: secrets NOT CREATED.
// AUTH MODEL: user JWT verified SERVER-SIDE (db.auth.getUser) + verified email; actor id is
//   always auth.user.id, never a body field; profiles.update is scoped .eq('id', auth.user.id).
// IDEMPOTENCY: set_role is guarded by the one-time role check; create_family by the
//   one-active-family-per-owner check. No idempotency_key on this function (not captured).
// RATE LIMITING: ABSENT, and ABSENT IN THE CAPTURED FUNCTION TOO (capture:51 — the
//   rate_limit module is not imported here). Preserved as-is; finding E7.
// AUDIT LOGGING: PRESENT for set_role (capture:54). NOT written for create_family — no
//   recordAudit anchor exists for that branch, so none is invented.
// verify_jwt: NOT CAPTURED — the field does not exist in capture-20261030.json for any
//   function. Authentication here is IN-HANDLER (requireUser); a gateway-side verify_jwt
//   setting must be read from the dashboard before deploy, not assumed.
//
// IDENTITY: A13 is UNSIGNED. This file resolves the actor only through the labelled seam
//   in _shared/auth.ts (IDENTITY_MODE = "supabase-auth"). Firebase-UID assumptions are
//   isolated in ONE function there; cutover is one edit, not a scatter.
//
// UNVERIFIED BEHAVIOUR (not implemented — no evidence):
//   - Response body shapes for both actions (no shape is captured anywhere).
//   - Whether set_role accepts display_name (profiles.display_name is NOT NULL with a
//     trigger-maintained value; no anchor names it). Not read from the body.
//   - Whether a same-value set_role repeat is an idempotent 200 or the same 409. Anchor
//     44-50 says "reject a different existing role"; 15:107 PE-A02 shows a changed role ->
//     409. Fail-closed 409 for ANY existing non-'unset' role is used and marked here.
//   - The child_contact_ids upsert's conflict target and its generated prefix are inferred
//     from the DB CHECK (A3-staging-load-v1.sql:437); anchor 72-80 gives no detail.
//   - Whether create_family writes an audit row. It is not evidenced, so it is not written.
//   - Families.settings initial content: not touched by this handler; the DB default
//     {"usage_retention_days":90,"location_retention_days":30} (A3:...:253) applies inside
//     the RPC, whose body is one of the 24 unread implementations (PA3).
// DEPLOYABLE AS WRITTEN? The set_role/create_family control flow is deployable against the
//   staging schema; the response SHAPES are a client contract that no evidence covers, so
//   parity with the Android/parent clients is NOT ESTABLISHED.
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import { errorResponse, ensureNoError, ok, readJson, requireAction, unknownAction, ApiError } from "./_shared/envelope.ts";
import { requireUser, requireRole } from "./_shared/auth.ts";
import { recordAudit } from "./_shared/audit.ts";
import { readEnum, CONTACT_ID_PREFIX, newContactId } from "./_shared/validation.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // ONE token verification per request. The deployed anchors place requireUser inside each
    // branch (capture:53 index 38 and capture:55 index 93); hoisting it is a structural
    // difference only — same gate, same fail-closed 401, no behaviour change.
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });

    if (action === "set_role") {
      // capture:53 — 38: requireUser(requireVerifiedEmail); PE-A03: unverified -> 403 email_not_verified

      // PE-A06 (15:111) — an out-of-vocabulary role is a 400 validation_error, not a 403.
      // profiles_role_check (A3:...:479) admits only unset|parent|child; self-service to
      // 'unset' is therefore impossible from the body.
      const requested = readEnum(body, "role", ["parent", "child"] as const);

      // capture:54 — 44-50: reject an existing role. One-time, from 'unset' only.
      if (profile.role !== "unset") {
        throw new ApiError(409, "role_already_set", "A role is already set for this account.");
      }

      // capture:54 — 53-58: profiles.update scoped to the caller's own row.
      // Self-escalation is bounded twice: the value set is the caller's own id, and
      // profiles_before_update rejects role changes once old.role <> 'unset'
      // (functions-and-triggers.md:22 — that body WAS read in B3b).
      const { error: perr } = await db
        .from("profiles")
        .update({ role: requested })
        .eq("id", auth.userId);
      ensureNoError(perr, "Could not save the role.");

      // capture:54 — 61-67: recordAudit role_set. Actor from the verified token only.
      await recordAudit(db, {
        eventType: "role_set",
        actorUserId: auth.userId,
        familyId: null,
        deviceId: null,
        targetType: "profile",
        targetId: auth.userId,
        metadata: { role: requested, from: "unset" },
      });

      // capture:54 — 72-80: child_contact_ids upsert, BEST EFFORT. A contact-id failure
      // must not undo a committed role change, so this is wrapped and swallowed with a
      // name-only log, exactly as the anchor describes.
      if (requested === "child") {
        try {
          const { data: existing } = await db
            .from("child_contact_ids")
            .select("child_user_id, contact_id, created_at, rotated_at")
            .eq("child_user_id", auth.userId)
            .maybeSingle();
          if (!existing) {
            const { error: cerr } = await db
              .from("child_contact_ids")
              .upsert(
                { child_user_id: auth.userId, contact_id: newContactId(), created_at: new Date().toISOString() },
                { onConflict: "child_user_id" },
              );
            if (cerr) console.error(`contact_id_upsert: ${cerr.code ?? "unknown"}`);
          }
        } catch (err) {
          console.error(`contact_id_best_effort: ${err instanceof Error ? err.name : "unknown"}`);
        }
      }

      // UNVERIFIED BEHAVIOUR — response shape not captured; {role} is a minimal honest body.
      return ok({ role: requested, contact_id_prefix: CONTACT_ID_PREFIX });
    }

    if (action === "create_family") {
      const { auth, profile } = await requireUser(req, { verifyEmail: true });
      requireRole(profile, "parent"); // capture:55 — 93: requireRole(parent); PE-A05: child -> 403 role_required

      const name = (() => {
        const v = body["name"];
        if (typeof v !== "string" || v.length < 1 || v.length > 80) {
          throw new ApiError(400, "validation_error", "name must be 1 to 80 characters.");
        }
        return v;
      })(); // bound VERIFIED from families_name_check, A3:...:467

      // capture:55 — 96-109: one active family per owner. PE-A04 -> 409 family_exists.
      const { data: existing, error: ferr } = await db
        .from("families")
        .select("id")
        .eq("owner_id", auth.userId)
        .is("deleted_at", null)
        .maybeSingle();
      ensureNoError(ferr, "Could not check existing families.");
      if (existing) {
        throw new ApiError(409, "family_exists", "This account already owns a family.");
      }

      // capture:55 — 111-114: rpc create_family_with_owner, p_owner = auth.user.id.
      // The p_owner argument is NEVER read from the body (check 3, 14:83-106).
      const { data, error } = await db.rpc("create_family_with_owner", {
        p_owner: auth.userId,
        p_name: name,
      });
      if (error) {
        console.error(`rpc_create_family: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not create the family.");
      }
      // UNVERIFIED BEHAVIOUR — response shape not captured; no audit row is evidenced here.
      return ok({ family: data ?? null });
    }

    unknownAction(action); // 15:137 — unknown actions are a 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
