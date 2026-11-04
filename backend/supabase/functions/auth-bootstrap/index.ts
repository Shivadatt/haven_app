// ============================================================================
// Edge Function: auth-bootstrap          TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// The production project's ref is deliberately NOT written in this artefact (owner rule: the
// staging project is the only project ref that may appear in code, comments or config).
// Production is not a target of this file and was not contacted. Deployment is BLOCKED by
// unsigned A7-R / A8-R.
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

// PORT NOTE (2026-11-04): the two action bodies moved to `set_role.ts` and
// `create_family.ts` so no file exceeds the project's 200-line source rule, and the
// duplicate in-branch `requireUser` call in `create_family` was removed — the dispatcher
// verifies once, which is what the hoisting comment above already described.

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { requireUser } from "../_shared/auth.ts";
import { setRole } from "./set_role.ts";
import { createFamily } from "./create_family.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // ONE token verification per request, for both actions.
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });

    if (action === "set_role") return await setRole(db, auth, profile.role, body);
    if (action === "create_family") return await createFamily(db, auth, profile.role, body);

    return unknownAction(action); // 15:137 — unknown actions are a 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
