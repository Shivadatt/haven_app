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
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import {
  ApiError,
  ensureNoError,
  errorResponse,
  ok,
  readJson,
  requireAction,
  unknownAction,
} from "./_shared/envelope.ts";
import {
  assertChildMembership,
  assertFamilyParent,
  requireRole,
  requireUser,
} from "./_shared/auth.ts";
import {
  assertInviteQuotaAllowed,
  assertPairingCodeCreationAllowed,
  assertPairingRedeemAllowed,
  recordPairingAttempt,
} from "./_shared/rate_limit.ts";
import {
  CONTACT_ID_RE,
  isContactIdForm,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  PAIRING_CODE_RE,
  readBoolean,
  readUuid,
  sha256Hex,
  identifierHash,
} from "./_shared/validation.ts";

const CODE_TTL_MINUTES = 10; // capture:35 — "41: CODE_TTL_MINUTES = 10"
const INVITE_TTL_MINUTES = 24 * 60; // capture:35 — "43: INVITE_TTL_MINUTES = 24 * 60"
const MAX_ATTEMPTS_PER_CODE = 10; // matches device_pairing_tokens.max_attempts DEFAULT 10 (A3-staging-load-v1.sql:202) — the only captured value for this field
const PENDING_LIST_LIMIT = 50; // INFERRED from 16:192 (sibling endpoint), not captured for pairing

const TOKEN_COLUMNS =
  "id, child_user_id, code_hash, expires_at, redeemed_at, redeemed_by, status, attempts, max_attempts, created_at, created_by, purpose";
const REQUEST_COLUMNS =
  "id, token_id, family_id, parent_user_id, child_user_id, status, created_at, expires_at, responded_at";

/**
 * The uniform refusal. pairing:571,583,598,625,773 all return the same body for unknown /
 * expired / malformed / over-attempt identifiers (14:164-165, 14:334). Never differentiate
 * these branches: any variance is an enumeration oracle.
 */
function invalidIdentifier(): never {
  // 15:89-93 maps this body to 400 `invalid_code` for both an unknown and an expired code.
  throw new ApiError(400, "invalid_code", "Pairing identifier is not valid.");
}

function ttl(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true });
    const uid = auth.userId;

    switch (action) {
      // ---- get_contact_id -------------------------------------------------------------
      case "get_contact_id": {
        requireRole(profile, "child"); // 14:114
        const { data: existing, error } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id, created_at, rotated_at")
          .eq("child_user_id", uid)
          .maybeSingle();
        ensureNoError(error, "Could not read the contact id.");
        if (existing) return ok({ contact_id: existing.contact_id });
        // PE-P01 (15:88): no row yet -> 200, `PC` + 8 chars, row created.
        let contactId = newContactId();
        for (let attempt = 0; attempt < 3; attempt++) {
          const ins = await db
            .from("child_contact_ids")
            .insert({ child_user_id: uid, contact_id: contactId, created_at: new Date().toISOString() });
          if (!ins.error) break;
          if (ins.error.code !== "23505") ensureNoError(ins.error, "Could not create the contact id.");
          // UNIQUE collision on contact_id (schema-columns.md:28): draw again.
          contactId = newContactId();
          if (attempt === 2) throw new ApiError(500, "internal_error", "Could not create the contact id.");
        }
        return ok({ contact_id: contactId });
      }

      // ---- create ---------------------------------------------------------------------
      case "create": {
        requireRole(profile, "child");
        await assertPairingCodeCreationAllowed(db, uid); // capture:33 rate_limit; 14:171
        const code = newPairingCode();
        const normalized = normalizeIdentifier(code);
        // 16:229-237 — VERBATIM from pairing:562-564, quoted so the two-digest design is
        // not "simplified" away by a later reader:
        //   // Two digests on purpose: the token row keeps plain SHA-256 so codes
        //   // issued before this change still redeem, while attempt records use
        //   // the keyed digest so a database dump cannot recover the identifier.
        // Token rows therefore use sha256Hex (finding E5, preserved deliberately).
        const codeHash = await sha256Hex(normalized);
        const expiresAt = ttl(CODE_TTL_MINUTES);
        const { error: insErr } = await db.from("device_pairing_tokens").insert({
          child_user_id: uid,
          code_hash: codeHash,
          purpose: "code", // vocabulary VERIFIED A3:...:450
          status: "active", // vocabulary VERIFIED A3:...:451
          expires_at: expiresAt,
          attempts: 0,
          max_attempts: MAX_ATTEMPTS_PER_CODE,
          created_at: new Date().toISOString(),
          created_by: uid,
        });
        ensureNoError(insErr, "Could not create a pairing code.");
        // The plaintext code is returned exactly once and is never stored (schema-columns.md:290).
        return ok({ code, expires_at: expiresAt });
      }

      // ---- redeem ---------------------------------------------------------------------
      case "redeem": {
        requireRole(profile, "parent"); // capture:37 — 548
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:37 — 551. TE-01 (15:58) -> 403 forbidden
        const raw = (() => {
          const v = body["code"];
          if (typeof v !== "string" || v.length < 1 || v.length > 64) {
            invalidIdentifier();
          }
          return v as string;
        })();
        const normalized = normalizeIdentifier(raw);

        // pairing:555-560 routing (UNVERIFIED — see header). Anti-oracle-safe reading:
        // a Child-ID-shaped value gets the identical uniform error with NO database probe,
        // and anything outside the 30-symbol alphabet is rejected the same way.
        if (isContactIdForm(normalized)) invalidIdentifier();
        if (!PAIRING_CODE_RE.test(normalized)) invalidIdentifier();

        const codeHash = await sha256Hex(normalized); // capture:37 — 565
        const attemptHash = await identifierHash(normalized); // capture:37 — 566 (KEYED digest)
        await assertPairingRedeemAllowed(db, uid, attemptHash); // capture:37 — 567, BEFORE the lookup

        const failAttempt = async (): Promise<never> => {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          return invalidIdentifier();
        };

        // capture:37 — 574-578: token lookup by code_hash
        const { data: token, error: terr } = await db
          .from("device_pairing_tokens")
          .select(TOKEN_COLUMNS)
          .eq("code_hash", codeHash)
          .eq("purpose", "code")
          .maybeSingle();
        ensureNoError(terr, "Could not check the pairing code.");
        if (!token) return await failAttempt();

        // capture:37 — 585-599: status / expiry gate, uniform body, expired row transitioned
        // under an .eq(status,"active") guard so a concurrent redeemer cannot double-spend.
        const now = Date.now();
        const expired = new Date(token.expires_at).getTime() <= now;
        if (token.status !== "active" || expired || token.attempts >= token.max_attempts) {
          if (expired && token.status === "active") {
            await db
              .from("device_pairing_tokens")
              .update({ status: "expired" })
              .eq("id", token.id)
              .eq("status", "active");
          }
          return await failAttempt();
        }

        // A child may hold at most ONE active family (family_members_one_active_child_family,
        // A3:...:480). PE-P05: already linked here -> 409 child_already_linked.
        // PE-P06 (15:93): already linked ELSEWHERE -> the uniform 400, so family membership
        // of another household is not disclosed through this endpoint.
        const { data: membership, error: merr } = await db
          .from("family_members")
          .select("family_id, role, status")
          .eq("user_id", token.child_user_id)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(merr, "Could not check the child membership.");
        if (membership) {
          if (membership.family_id === familyId) {
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          return await failAttempt();
        }

        // pairing:628-632 — a request already exists for this token? (UNIQUE token_id,
        // schema-columns.md:182). Second redemption -> 409 code_unavailable (14:173-177).
        const { data: prior, error: prerr } = await db
          .from("pairing_requests")
          .select("id")
          .eq("token_id", token.id)
          .maybeSingle();
        ensureNoError(prerr, "Could not check existing pairing requests.");
        if (prior) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
        }

        // capture:37 — 668-674: rpc create_pairing_request, p_parent_user_id = auth.user.id
        const expiresAtRequest = ttl(CODE_TTL_MINUTES);
        const { data, error } = await db.rpc("create_pairing_request", {
          p_child_user_id: token.child_user_id,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_token_id: token.id,
          p_expires_at: expiresAtRequest,
        });
        if (error) {
          // 14:277 — RPC messages are mapped by substring to fixed bodies, never forwarded.
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            // pairing:709-714 — revoke the token on the "already exists" path.
            await db
              .from("device_pairing_tokens")
              .update({ status: "revoked" })
              .eq("id", token.id)
              .eq("status", "active");
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          console.error(`rpc_create_pairing_request: ${error.code ?? "unknown"}`);
          throw new ApiError(500, "internal_error", "Could not create the pairing request.");
        }

        // INFERRED single-use consumption (14:172): mark the token redeemed, guarded so a
        // concurrent redeem cannot both win.
        await db
          .from("device_pairing_tokens")
          .update({ status: "redeemed", redeemed_at: new Date().toISOString(), redeemed_by: uid })
          .eq("id", token.id)
          .eq("status", "active");
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        return ok({ request: data ?? null, status: "pending_child", expires_at: expiresAtRequest });
      }

      // ---- invite -----------------------------------------------------------------------
      case "invite": {
        requireRole(profile, "parent");
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:38 — 764
        const normalized = normalizeIdentifier(
          (() => {
            const v = body["contact_id"];
            if (typeof v !== "string" || v.length < 1 || v.length > 32) invalidIdentifier();
            return v as string;
          })(),
        );
        const attemptHash = await identifierHash(normalized); // capture:38 — 771 (KEYED digest)

        // PE-P07 (15:94): a malformed Child ID is a 400 invalid_code AND exactly ONE attempt
        // recorded — hence recordPairingAttempt at :772 happens on this branch too.
        if (!CONTACT_ID_RE.test(normalized)) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false }); // :772
          invalidIdentifier();
        }

        const { data: contact, error: cerr } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id")
          .eq("contact_id", normalized)
          .maybeSingle();
        ensureNoError(cerr, "Could not look up that Child ID.");
        if (!contact) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          invalidIdentifier();
        }

        const childUserId = contact.child_user_id as string;
        await assertInviteQuotaAllowed(db, childUserId); // 14:171: 3 pending / 10 per 24 h per child

        const { data: existingChild, error: xmerr } = await db
          .from("family_members")
          .select("family_id, status")
          .eq("user_id", childUserId)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(xmerr, "Could not check the child membership.");
        if (existingChild) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          if (existingChild.family_id === familyId) {
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          invalidIdentifier();
        }

        // capture:38 — 378-383: rpc create_pairing_invite, p_parent_user_id = auth.user.id
        const expiresAt = ttl(INVITE_TTL_MINUTES);
        const inviteCodeHash = await sha256Hex(normalized);
        const { data, error } = await db.rpc("create_pairing_invite", {
          p_child_user_id: childUserId,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_code_hash: inviteCodeHash,
          p_expires_at: expiresAt,
        });
        if (error) {
          console.error(`rpc_create_pairing_invite: ${error.code ?? "unknown"}`);
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          throw new ApiError(500, "internal_error", "Could not create the invite.");
        }
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        // UNVERIFIED BEHAVIOUR — invite response shape not captured.
        return ok({ invite: data ?? null, expires_at: expiresAt });
      }

      // ---- pending_child ------------------------------------------------------------------
      case "pending_child": {
        requireRole(profile, "child"); // 14:114
        const nowIso = new Date().toISOString();
        const { data, error } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("child_user_id", uid)
          .eq("status", "pending_child")
          .gt("expires_at", nowIso) // INFERRED read filter; see header UNVERIFIED list
          .order("created_at", { ascending: false })
          .limit(PENDING_LIST_LIMIT);
        ensureNoError(error, "Could not list pairing requests.");
        return ok({ requests: data ?? [] });
      }

      // ---- respond ------------------------------------------------------------------------
      case "respond": {
        requireRole(profile, "child"); // capture:39 — 814
        const requestId = readUuid(body, "request_id");
        const approve = readBoolean(body, "approve");
        if (approve === null) throw new ApiError(400, "validation_error", "approve must be a boolean.");

        // HARDENING DEVIATION (see header): the capture passes p_child_user_id and relies on
        // private.respond_pairing_request, whose body is unread (PA3). Service-role bypasses
        // RLS, so the relationship is asserted here as well. TE-10's "B -> 403" (15:67) is the
        // behaviour this reproduces at the Edge tier.
        const { data: row, error: rerr } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("id", requestId)
          .maybeSingle();
        ensureNoError(rerr, "Could not read the pairing request.");
        if (!row) throw new ApiError(403, "forbidden", "Not your pairing request.");
        if (row.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your pairing request.");

        // capture:39 — 818-821: rpc respond_pairing_request, p_child_user_id = auth.user.id
        const { data, error } = await db.rpc("respond_pairing_request", {
          p_request_id: requestId,
          p_child_user_id: uid,
          p_approve: approve,
        });
        if (error) {
          console.error(`rpc_respond_pairing_request: ${error.code ?? "unknown"}`);
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("expired") || m.includes("not_pending")) {
            throw new ApiError(409, "code_unavailable", "This pairing request is no longer available.");
          }
          throw new ApiError(500, "internal_error", "Could not respond to the pairing request.");
        }
        return ok({ request: data ?? null }); // INFERRED idempotent repeat, 14:311
      }

      // ---- cancel ---------------------------------------------------------------------------
      case "cancel": {
        requireRole(profile, "parent"); // 14:114. PE-P12 (15:99): another family's request -> 403
        const requestId = readUuid(body, "request_id");
        const { data: row, error: rerr } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("id", requestId)
          .maybeSingle();
        ensureNoError(rerr, "Could not read the pairing request.");
        if (!row) throw new ApiError(400, "validation_error", "No such pairing request.");
        await assertFamilyParent(db, uid, row.family_id);

        // Compare-and-set (14:205 pattern); terminal rows return as-is (idempotent repeat).
        if (row.status !== "pending_child") return ok({ request: row });
        const { data: updated, error: uerr } = await db
          .from("pairing_requests")
          .update({ status: "cancelled", responded_at: new Date().toISOString() })
          .eq("id", requestId)
          .eq("status", "pending_child")
          .select(REQUEST_COLUMNS)
          .maybeSingle();
        ensureNoError(uerr, "Could not cancel the pairing request.");
        if (!updated) {
          const { data: again } = await db
            .from("pairing_requests")
            .select(REQUEST_COLUMNS)
            .eq("id", requestId)
            .maybeSingle();
          return ok({ request: again ?? null });
        }
        // Token released so the code is not burned by a cancelled request. INFERRED.
        await db
          .from("device_pairing_tokens")
          .update({ status: "revoked" })
          .eq("id", row.token_id)
          .eq("status", "active");
        return ok({ request: updated });
      }

      // ---- list_family ----------------------------------------------------------------------
      case "list_family": {
        requireRole(profile, "parent"); // 14:114. TE-05 uses list_family for the child-role test.
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId);
        // UNVERIFIED BEHAVIOUR — content not captured; three scoped reads only (all family-
        // scoped, so a predicate miss cannot leak another household).
        const { data: members, error: e1 } = await db
          .from("family_members")
          .select("id, family_id, user_id, role, status, created_at, removed_at")
          .eq("family_id", familyId)
          .eq("status", "active");
        ensureNoError(e1, "Could not list family members.");
        const { data: devices, error: e2 } = await db
          .from("devices")
          .select(
            "id, family_id, child_user_id, display_name, platform, status, enforcement_mode, policy_version, last_seen_at, battery_level, is_charging",
          )
          .eq("family_id", familyId);
        ensureNoError(e2, "Could not list devices.");
        const { data: requests, error: e3 } = await db
          .from("pairing_requests")
          .select(REQUEST_COLUMNS)
          .eq("family_id", familyId)
          .eq("status", "pending_child")
          .order("created_at", { ascending: false })
          .limit(PENDING_LIST_LIMIT);
        ensureNoError(e3, "Could not list pairing requests.");
        return ok({ family_id: familyId, members: members ?? [], devices: devices ?? [], requests: requests ?? [] });
      }

      // ---- unlink -------------------------------------------------------------------------------
      case "unlink": {
        const familyId = readUuid(body, "family_id");
        const targetChild = readUuid(body, "child_user_id"); // TARGET, not actor (14:102)
        // capture:40 — 929-939: "actor is child (self) or parent in the body family".
        if (profile.role === "child") {
          if (targetChild !== uid) {
            throw new ApiError(403, "forbidden", "A child may only unlink their own link.");
          }
          await assertChildMembership(db, uid, familyId);
        } else {
          requireRole(profile, "parent");
          await assertFamilyParent(db, uid, familyId);
          const { data: tm, error: tmerr } = await db
            .from("family_members")
            .select("family_id, role, status")
            .eq("user_id", targetChild)
            .eq("family_id", familyId)
            .eq("status", "active")
            .eq("role", "child")
            .maybeSingle();
          ensureNoError(tmerr, "Could not check the child membership.");
          if (!tm) throw new ApiError(403, "forbidden", "That child is not in this family.");
        }
        // capture:40 — 942-945: rpc unlink_child, p_actor_user_id = auth.user.id
        const { data, error } = await db.rpc("unlink_child", {
          p_family_id: familyId,
          p_child_user_id: targetChild,
          p_actor_user_id: uid,
        });
        if (error) {
          console.error(`rpc_unlink_child: ${error.code ?? "unknown"}`);
          throw new ApiError(500, "internal_error", "Could not unlink that child.");
        }
        // PE-P09 (15:96): 200 and devices revoked — the revocation itself happens inside
        // private.unlink_child, whose body WAS read (docs/stage1/evidence/g1-b3b-20261029.json):
        // devices -> status 'revoked', secret_hash null, credential_revoked_at now();
        // pairing_requests status 'pending_child' -> 'cancelled'; tokens -> 'revoked';
        // family_members -> 'removed'; audit event 'member_removed'.
        return ok({ result: data ?? null });
      }

      default:
        unknownAction(action); // 15:137 — never a silent no-op
    }
  } catch (err) {
    return errorResponse(err);
  }
});
