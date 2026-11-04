// ============================================================================
// Edge Function: pairing                 TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// The production project's ref is deliberately NOT written in this artefact (owner rule: the
// staging project is the only project ref that may appear in code, comments or config).
// Production is not a target of this file and was not contacted. Deployment is BLOCKED by
// unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   (mandatory label, docs/stage2/approval-package-v3-implementation-instruments.md §7.)
//   capture:27 calls this "readable TypeScript" (972 lines / 33993 chars, sha256
//   427d419d..., capture:30) — but the TEXT IS NOT IN THIS REPOSITORY. What survives is
//   only the anchor line-numbers. Evidence for that:
//     docs/stage1/13-edge-function-source-inventory.md §1 — supabase/functions/ ABSENT
//     docs/stage1/evidence/edge-functions/capture-20261030.json:173-177 — functions_directory
//       "absent", import_map_or_deno_json "absent"
//     docs/stage2/S2-A4-edge-functions-audit.md finding A4-F13 — the pairing/ subdirectory
//       implied by capture operations_performed[10] holds nothing
//     docs/stage2/S2-A7-security-audit.md test T-07 — "directory exists with 0 entries.
//       Every `pairing/index.ts:<n>` anchor ... resolves to a dashboard capture, not to a
//       repository file"
//   So this is NOT CAPTURED SOURCE, and the brief's "two functions are captured" framing is
//   disagreed with in the report. Line numbers below are the ONLY surviving structure.
//
// CAPTURED FACTS USED (file:line):
//   capture:31  actions = get_contact_id, create, redeem, invite, pending_child, respond,
//               cancel, list_family, unlink  (nine, no others)
//   capture:32  auth_model = "user JWT (all actions); parent or child role per action;
//               family membership asserted per action"
//   capture:33  imports ALL SIX _shared modules including rate_limit (pairing is the only
//               function that uses rate_limit — 14:232-237, VERIFIED absent everywhere else)
//   capture:35  41: CODE_TTL_MINUTES = 10 | 43: INVITE_TTL_MINUTES = 24 * 60
//   capture:36  445: switch (action)
//   capture:37  548 requireRole(parent); 551 assertFamilyParent; 562-564 two-digest comment;
//               565 codeHash = sha256Hex(normalized); 566 attemptHash = identifierHash(normalized);
//               567 assertPairingRedeemAllowed; 574-578 token lookup by code_hash;
//               585-599 status/expiry gate with uniform INVALID_IDENTIFIER;
//               668-674 rpc create_pairing_request with p_parent_user_id = auth.user.id
//   capture:38  764 assertFamilyParent; 771-772 identifierHash + recordPairingAttempt;
//               378-383 rpc create_pairing_invite with p_parent_user_id = auth.user.id
//   capture:39  814 requireRole(child); 818-821 rpc respond_pairing_request p_child_user_id = auth.user.id
//   capture:40  929-939 actor is child (self) or parent in the body family;
//               942-945 rpc unlink_child with p_actor_user_id = auth.user.id
//   docs/stage1/evidence/functions-and-triggers.md:80 guard vocabulary actually found in the
//     file: requireUser, requireRole, requireVerifiedEmail, requireAction, assertFamilyParent,
//     assertChildMembership, assertInviteQuotaAllowed, assertPairingCodeCreationAllowed,
//     assertPairingRedeemAllowed, ensureContactId, ensureNoError — 1 catch block, 0 console.log
//   14-edge-function-security-audit.md:114 role per action; :159-178 check 7; :334-335
//     uniform INVALID_IDENTIFIER at :571,:583,:598,:625,:773 and routing at :555-560
//   15-edge-function-test-plan.md:84-100 PE-P01..P13 (expected codes per action)
//   16-phase-e-findings.md:229-237 verbatim pairing:562-566 comment (quoted in-code below)
//   docs/stage1/evidence/functions-and-triggers.md:38-49 exact RPC signatures
//   docs/stage2/migrations/A3-staging-load-v1.sql:437,448-451,477 status/purpose/code_hash/
//     contact_id vocabularies (from g1-q5 check constraints — DATABASE-VERIFIED)
//   docs/stage2/migrations/A3-staging-load-v1.sql:480 (family_members_one_active_child_family
//     partial unique) and :572 devices_one_active_per_child
//
// TABLES TOUCHED: child_contact_ids (SELECT, INSERT), device_pairing_tokens (SELECT, INSERT,
//   UPDATE), pairing_attempts (INSERT, SELECT via rate_limit), pairing_requests (SELECT,
//   UPDATE; INSERT via RPC), family_members (SELECT), families (SELECT), profiles (SELECT),
//   devices (SELECT, list_family only), audit_logs (INSERT).
// RPCs CALLED: public.create_pairing_request, public.create_pairing_invite,
//   public.respond_pairing_request, public.unlink_child.
// SECRETS BY NAME (values never written): SUPABASE_SERVICE_ROLE_KEY, PAIRING_HASH_PEPPER.
//   A9 records both as NOT CREATED; without the pepper, identifierHash degrades to SHA-256
//   (finding E6) and attempt records become forgeable from a dump — disclosed, not hidden.
// AUTH MODEL: user JWT verified server-side; role from profiles.role; family authority from
//   assertFamilyParent / assertChildMembership. Actor id is ALWAYS auth.user.id. Target ids
//   (family_id, request_id, child_user_id on unlink, contact_id/code) may come from the body
//   and are scoped before use (14:100-106). No service-role credential reaches a client.
// IDEMPOTENCY: pairing_requests.token_id is UNIQUE (schema-columns.md:182), a second
//   redemption maps to 409 code_unavailable (14:173-177 — single use is INFERRED, not
//   VERIFIED, because private.create_pairing_request's body is one of the 24 unread).
// RATE LIMITING: PRESENT here and ONLY here — assertPairingRedeemAllowed before the lookup
//   (anti-enumeration), assertPairingCodeCreationAllowed, assertInviteQuotaAllowed,
//   recordPairingAttempt on every failure branch. read-then-act overshoot (E8) is PRESERVED.
// AUDIT LOGGING: capture:33 states that pairing imports ALL SIX _shared modules, which
//   includes audit. But NOT ONE capture anchor for this slug names a recordAudit call, and
//   functions-and-triggers.md:80 lists the guard vocabulary actually found in the file
//   (requireUser, requireRole, requireVerifiedEmail, requireAction, assertFamilyParent,
//   assertChildMembership, assertInviteQuotaAllowed, assertPairingCodeCreationAllowed,
//   assertPairingRedeemAllowed, ensureContactId, ensureNoError) — no audit helper among them.
//   That import set and that anchor set are in tension. RESOLUTION USED: no audit row is
//   written, because inventing one would violate "do not invent business logic"; the tension
//   is DISCLOSED rather than papered over. See deploy/pairing.bundle.ts, which does inline
//   the audit module (unused) purely to match the captured import set.
// verify_jwt: NOT CAPTURED (no such field exists in the capture for any function).
//   Authentication is IN-HANDLER. Gateway verify_jwt must be read from the dashboard.
//
// IDENTITY: A13 UNSIGNED -> actor resolution happens only through the labelled seam in
//   _shared/auth.ts (IDENTITY_MODE = "supabase-auth"). Parent-child ownership is NEVER
//   established from a client-supplied UID: p_parent_user_id / p_child_user_id /
//   p_actor_user_id are always the verified subject (capture:37-40).
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - pairing:555-560 CHILD-ID-vs-CODE ROUTING. Evidence states only that routing is by
//     format so that neither path becomes an oracle for the other (14:335). The deployed
//     dispatch is not readable. This re-authoring implements the anti-oracle-safe reading:
//     a value in Child-ID form is refused by `redeem` with the SAME uniform error a bad code
//     gives, with no database lookup at all. If production instead routes Child-ID input
//     into the invite path, this differs. UNVERIFIED.
//   - device_pairing_tokens.max_attempts VALUE: RESOLVED from the emitted DDL —
//     "max_attempts integer NOT NULL DEFAULT 10" (A3-staging-load-v1.sql:202). The handler
//     writes 10 to match; the deployed Edge constant itself remains uncaptured.
//   - pairing_requests response shapes for every action: no shape is captured. Bodies below
//     are minimal and marked.
//   - The status a token row moves to on successful redemption: 'redeemed' exists in the
//     vocabulary (A3:...:451) and 14:172 treats second redemption as code_unavailable; the
//     write itself is INFERRED.
//   - Which identity the "live codes / creations per hour" windows key on (rate_limit header).
//   - `list_family` content: 14:114 evidences only that it is parent-only and family-scoped.
//     Three scoped reads are implemented; if production returns more or less, UNVERIFIED.
//   - `cancel`: no capture anchor exists at all. Implemented from 14:114 (parent) and
//     15:99 PE-P12 (another family -> 403) only.
//   - `pending_child`: no capture anchor. Implemented as a scoped read of status
//     'pending_child' for the caller; the 50-row cap is borrowed from the sibling
//     remote-session action (16:192) and is INFERRED.
// HARDENING DEVIATIONS FROM THE CAPTURED FUNCTION (disclosed, per the brief's
// "every protected operation must authorise inside the function"):
//   - `respond` and `cancel` and `unlink` now PRE-READ pairing_requests and assert the
//     caller's relationship before the RPC. The capture shows `respond` relying on the RPC
//     (capture:39, 814-821) whose private body is NOT VERIFIED. Because service_role bypasses
//     RLS, a function-side check is required by the brief. Flagged in-code.
//
// LAYOUT: this file is the shared gate — action, verified identity, verified email — plus the
//   dispatch. The nine captured actions live beside it, sliced verbatim: ./issuance.ts
//   (get_contact_id, create, invite), ./redeem.ts (redeem), ./requests.ts (pending_child,
//   respond, list_family) and ./unlink.ts (cancel, unlink); the constants, column whitelists and
//   the two shared helpers are in ./shared.ts. Split at port time for the 200-line source rule;
//   behaviour, labels and anchors are unchanged. Every handler takes the SAME arguments —
//   (db, uid, profile, body) — and each still calls requireRole for its own role inside its own
//   block, exactly as the captured switch did. Read all six files together with this header.
// ============================================================================

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { requireUser } from "../_shared/auth.ts";
import { handleCreate, handleGetContactId, handleInvite } from "./issuance.ts";
import { handlePendingChild, handleListFamily, handleRespond } from "./requests.ts";
import { handleCancel, handleUnlink } from "./unlink.ts";
import { handleRedeem } from "./redeem.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    const uid = auth.userId;

    // The captured switch, preserved action-for-action. Each handler returns its own Response.
    if (action === "get_contact_id") return await handleGetContactId(db, uid, profile);
    if (action === "create") return await handleCreate(db, uid, profile);
    if (action === "invite") return await handleInvite(db, uid, profile, body);
    if (action === "redeem") return await handleRedeem(db, uid, profile, body);
    if (action === "pending_child") return await handlePendingChild(db, uid, profile);
    if (action === "respond") return await handleRespond(db, uid, profile, body);
    if (action === "cancel") return await handleCancel(db, uid, profile, body);
    if (action === "list_family") return await handleListFamily(db, uid, profile, body);
    if (action === "unlink") return await handleUnlink(db, uid, profile, body);

    unknownAction(action); // 15:137 — never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
