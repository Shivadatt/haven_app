// ============================================================================
// Edge Function: remote-session           TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:134-136: MINIFIED BUNDLE, 12848 chars / 2 lines, sha256 85e30c3c..., no source maps.
//   14:50 records this slug's overall verdict as PARTIAL (abuse checks E4, E7).
//
// CAPTURED FACTS USED (file:line):
//   capture:136 actions = request, pending_child, respond, start, end, ice
//   capture:138 auth_model = "user JWT + verified email; parent for request, child for
//               pending_child/respond/start, either participant for end/ice"
//   capture:139 inlined_modules = cors, envelope, auth, audit, validation (NO rate_limit)
//   capture:141 request: requireRole(parent); requireActiveDeviceForParent(device_id);
//               DIRECT INSERT into remote_sessions (not the public.request_remote_session RPC);
//               parent_user_id = JWT user, child_user_id = device.child_user_id,
//               expires_at = now + 10 min, consent_recorded false; audit session_requested
//   capture:142 pending_child: expire stale requested rows for the child, then list up to 50
//   capture:143 respond: child must equal session.child_user_id; idempotent for accepted/
//               declined repeats; .eq(status,"requested") guard on update; accept sets
//               consent_recorded true, session_nonce randomUUID, expires_at now + 30 min
//   capture:144 start: child-only; requires status accepted and consent_recorded; .eq(status,
//               "accepted") guard
//   capture:145 end: either participant; terminal states returned as-is; update .in(status,
//               [requested,accepted,active])
//   capture:146 ice: participant; status accepted|active; consent_recorded required; TURN
//               credential HMAC-SHA1 with TURN_SECRET, username '<expiry>:<user id>',
//               TTL clamp 60..86400 default 600
//   14-edge-function-security-audit.md:181-199 (check 8: the whole consent chain, and the two
//     containment gaps E4/E7), :201-211 (check 9: compare-and-set on every transition, "no row
//     returned" -> 409 session_not_open, plus the DB trigger), :338-339 (positive controls)
//   15-edge-function-test-plan.md:181-193 PE-S01..S10 (409 session_not_open, 410
//     session_expired, 403 non-participant, kind:"screen" -> 400, 50-row cap)
//   docs/stage1/evidence/g1-b3b-20261029.json — public.request_remote_session body (read
//     VERBATIM): p_kind not in ('audio','video') -> raise 'invalid_kind', advisory lock,
//     'session_in_progress', expires_at = now() + interval '10 minutes', consent_recorded false
//   docs/stage2/migrations/A3-staging-load-v1.sql:309-327 remote_sessions DDL (status DEFAULT
//     'requested', consent_recorded DEFAULT false, session_nonce uuid, ended_by/ended_reason),
//     :481 kind IN (audio,video), :483 status vocabulary
//     requested|accepted|active|declined|ended|expired|failed, :482 status='requested' =>
//     expires_at NOT NULL, :807 trigger is BEFORE UPDATE **OF status**
//   docs/stage1/evidence/schema-columns.md:276-286 webrtc_signals — NOT written by this
//     handler in any captured anchor (see UNVERIFIED below)
//
// TABLES TOUCHED: profiles / families / family_members / devices (SELECT via auth),
//   remote_sessions (INSERT, SELECT, UPDATE), audit_logs (INSERT).
// RPCs CALLED: NONE. `public.request_remote_session` EXISTS and enforces the single-session
//   invariant (advisory lock + 'session_in_progress'), and capture:141 records that the
//   deployed handler DOES NOT CALL IT — that is finding E4. This re-authoring PRESERVES the
//   bypass, because switching to the RPC changes observable behaviour (stacked requests start
//   returning 409) and that is an A7-R decision, not an IMP-5 edit. See DEPLOYMENT-MAP.md.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY, TURN_SECRET. No value of either appears here.
//   TURN_SECRET is mandatory on this slug: with it unset the function returns 503 rather than
//   issuing an unsigned credential.
// AUTH MODEL: user JWT + verified email; parent for request, child for pending_child/respond/
//   start, EITHER PARTICIPANT for end/ice. The consent chain is the security property that
//   matters for a monitoring product and it is enforced at every step (14:193-196): a parent can
//   never start, accept, or obtain ICE for a session the child has not accepted.
// IDEMPOTENCY: PRESENT — compare-and-set on every transition (.eq/.in on status) with a re-read
//   on a lost race; repeated accept -> 200; repeated end -> 200; terminal rows returned as-is.
// RATE LIMITING: ABSENT (capture:139; finding E7). `request` in particular is unlimited, so the
//   consent inbox can be flooded — PE-S08 (15:192) records that two requests both succeed today.
//   PRESERVED, NOT FIXED.
// AUDIT LOGGING: PRESENT — session_requested is captured (capture:141); accepted / started /
//   ended rows are required by PE-S01 (15:184) but their exact event_type strings are not
//   captured. See UNVERIFIED below.
// verify_jwt: NOT CAPTURED. Auth is in-handler.
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - audit event_type strings for respond / start / end. `session_requested` is VERIFIED;
//     `session_accepted`, `session_declined`, `session_started`, `session_ended` are INFERRED
//     from PE-S01's wording. A dashboard filtering on the real strings may miss these.
//   - WebRTC SIGNAL RELAY IS NOT IN THIS FUNCTION. webrtc_signals exists in the schema
//     (schema-columns.md:276-286) and has RLS policies keyed on auth.uid()
//     (A3:...:761, :773), but NO capture anchor shows remote-session touching it, and no
//     action name for signalling exists in capture:136. Clients therefore reach it directly
//     through PostgREST — which depends on auth.uid(), i.e. the Supabase-Auth identity, and
//     BREAKS under A13 (see docs/stage2/S2-A4-edge-functions-audit.md on the DEFAULT auth.uid()
//     columns). Not implemented here because there is no evidence of an action for it.
//   - `ended_reason` value: read from the body if present (<=200 chars per A3:...:480) else
//     null. No anchor names the field.
//   - TURN server URL(s) are CONFIG, not captured: read from env TURN_HOST, which is a
//     PLACEHOLDER NAME. Missing -> 503 server_misconfigured (an evidenced code) rather than a
//     new invented one.
//   - Whether ICE credentials are per-session-scoped or per-user-scoped: the username form
//     '<expiry>:<user id>' (capture:146) is per USER, so the user id is used; the caller's own
//     id is used for the request's participant.
//   - `pending_child` "expire stale requested rows" writes status='expired' — whether it also
//     stamps ended_at/ended_reason is not captured; ended_at is not written.
//   - Response shapes for all six actions are not captured.
//
// LAYOUT: this file is the shared gate — action, verified parent/child identity — plus the
//   dispatch. The actions live beside it: ./lifecycle.ts (request, pending_child, respond) and
//   ./media.ts (start, end, ice). Split at port time for the 200-line source rule; behaviour,
//   labels and anchors unchanged. Each action still names its own required role INSIDE its
//   block, as the captured handler did, so `profile` is handed over rather than pre-checked.
// ============================================================================

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { requireUser } from "../_shared/auth.ts";
import { handlePendingChild, handleRequest, handleRespond } from "./lifecycle.ts";
import { handleEnd, handleIce, handleStart } from "./media.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true }); // capture:138
    const uid = auth.userId;

    // capture:139 — the six actions of this slug.
    if (action === "request") return await handleRequest(db, uid, profile, body);
    if (action === "pending_child") return await handlePendingChild(db, uid, profile);
    if (action === "respond") return await handleRespond(db, uid, profile, body);
    if (action === "start") return await handleStart(db, uid, profile, body);
    if (action === "end") return await handleEnd(db, uid, body);
    if (action === "ice") return await handleIce(db, uid, body);

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
