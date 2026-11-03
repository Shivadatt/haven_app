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
// ============================================================================

import { handleCors } from "./_shared/cors.ts";
import { ApiError, ensureNoError, errorResponse, ok, readJson, requireAction, unknownAction } from "./_shared/envelope.ts";
import { requireActiveDeviceForParent, requireRole, requireUser } from "./_shared/auth.ts";
import { recordAudit } from "./_shared/audit.ts";
import { clampInt, readBoolean, readEnum, readOptionalString, readUuid } from "./_shared/validation.ts";

const REQUEST_TTL_MINUTES = 10; // capture:141 "expires_at = now + 10 min"
const ACCEPTED_TTL_MINUTES = 30; // capture:143 "expires_at now + 30 min"
const PENDING_LIST_LIMIT = 50; // capture:142 "list up to 50"
const TURN_TTL_MIN_SECONDS = 60; // capture:146 "TTL clamp 60..86400"
const TURN_TTL_MAX_SECONDS = 86_400;
const TURN_TTL_DEFAULT_SECONDS = 600; // capture:146 "default 600"
const SESSION_KINDS = ["audio", "video"] as const; // VERIFIED: A3:...:481 + the unread-but-quoted RPC body
const TERMINAL_SESSION_STATUSES = ["declined", "ended", "expired", "failed"] as const; // 14:209

const SESSION_COLUMNS =
  "id, family_id, device_id, parent_user_id, child_user_id, kind, status, requested_at, accepted_at, started_at, ended_at, expires_at, ended_by, ended_reason, consent_recorded, session_nonce, created_at";

const b64 = (bytes: ArrayBuffer): string =>
  btoa(String.fromCharCode(...Array.from(new Uint8Array(bytes))));

/** TURN credential minting: HMAC-SHA1(TURN_SECRET, "<expiry>:<user id>") (capture:146). */
async function mintTurnCredential(username: string): Promise<string> {
  const secret = Deno.env.get("TURN_SECRET"); // NAME only; never logged, never returned
  if (!secret) throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  return b64(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(username)));
}

function isoIn(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    const { auth, db, profile } = await requireUser(req, { verifyEmail: true }); // capture:138
    const uid = auth.userId;

    // ---- request (parent only) -------------------------------------------------------
    if (action === "request") {
      requireRole(profile, "parent"); // capture:141 — TE-12 (15:69): the child gets 403 role_required
      const deviceId = readUuid(body, "device_id");
      // capture:141 — requireActiveDeviceForParent(device_id): family comes from the DEVICE.
      // TE-04 (15:61): another family's device -> 403 forbidden.
      const device = await requireActiveDeviceForParent(db, uid, deviceId);
      const kind = readEnum(body, "kind", SESSION_KINDS); // PE-S09 (15:193): kind "screen" -> 400

      // capture:141 — DIRECT INSERT, deliberately bypassing public.request_remote_session.
      // Finding E4 PRESERVED (see header): the RPC's advisory lock and 'session_in_progress'
      // check never run on this path, so pending requests stack (PE-S08, 15:192).
      const { data, error } = await db
        .from("remote_sessions")
        .insert({
          family_id: device.family_id, // from the device row
          device_id: device.id,
          parent_user_id: uid, // from the verified token — never a body field
          child_user_id: device.child_user_id, // from the device row (capture:141)
          kind,
          status: "requested", // column default too (A3:...:316)
          requested_at: new Date().toISOString(),
          expires_at: isoIn(REQUEST_TTL_MINUTES), // satisfies remote_sessions_pending_expiry_check, A3:...:482
          consent_recorded: false, // capture:141 — consent is NOT assumed
        })
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(error, "Could not create the session request.");
      await recordAudit(db, {
        eventType: "session_requested", // capture:141 (VERIFIED name)
        actorUserId: uid,
        familyId: device.family_id,
        deviceId: device.id,
        targetType: "remote_session",
        targetId: data?.id ?? null,
        metadata: { kind },
      });
      return ok({ session: data });
    }

    // ---- pending_child (the child's consent inbox) ----------------------------------
    if (action === "pending_child") {
      requireRole(profile, "child"); // capture:138
      const nowIso = new Date().toISOString();
      // capture:142 — expire stale requested rows for THIS child first, then list.
      // remote_sessions_transition_guard is BEFORE UPDATE OF status and raises only on a
      // terminal -> live move (14:209), so requested -> expired is permitted by the trigger.
      await db
        .from("remote_sessions")
        .update({ status: "expired" })
        .eq("child_user_id", uid)
        .eq("status", "requested")
        .lte("expires_at", nowIso);
      const { data, error } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("child_user_id", uid)
        .eq("status", "requested")
        .gt("expires_at", nowIso)
        .order("requested_at", { ascending: false })
        .limit(PENDING_LIST_LIMIT); // PE-S10 (15:193): 60 seeded rows -> at most 50 returned
      ensureNoError(error, "Could not list session requests.");
      return ok({ sessions: data ?? [] });
    }

    // ---- respond (child only) --------------------------------------------------------
    if (action === "respond") {
      requireRole(profile, "child"); // capture:138; TE-13 (15:70): a parent gets 403 role_required
      const sessionId = readUuid(body, "session_id");
      const accept = readBoolean(body, "accept");
      if (accept === null) throw new ApiError(400, "validation_error", "accept must be a boolean.");

      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      // capture:143 — the child must equal session.child_user_id.
      if (session.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your session.");

      // capture:143 — idempotent for accepted/declined repeats.
      if (session.status !== "requested") {
        const sameAnswer = (accept && session.status === "accepted") || (!accept && session.status === "declined");
        if (sameAnswer) return ok({ session, idempotent: true }); // PE-S02 (15:185)
        throw new ApiError(409, "session_not_open", "This session is not awaiting a response."); // PE-S03 (15:186)
      }
      if (new Date(session.expires_at).getTime() <= Date.now()) {
        await db.from("remote_sessions").update({ status: "expired" }).eq("id", sessionId).eq("status", "requested");
        throw new ApiError(410, "session_expired", "This session request has expired.");
      }

      const patch: Record<string, unknown> = accept
        ? {
            status: "accepted",
            accepted_at: new Date().toISOString(),
            consent_recorded: true, // capture:143 — consent is recorded ONLY by the child's accept
            session_nonce: crypto.randomUUID(), // capture:143 — randomUUID, uuid column (A3:...:325)
            expires_at: isoIn(ACCEPTED_TTL_MINUTES),
          }
        : { status: "declined", ended_at: new Date().toISOString(), ended_by: uid, consent_recorded: false };

      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update(patch)
        .eq("id", sessionId)
        .eq("child_user_id", uid)
        .eq("status", "requested") // capture:143 — compare-and-set
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not respond to the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        return ok({ session: again, idempotent: true }); // lost the race
      }
      await recordAudit(db, {
        eventType: accept ? "session_accepted" : "session_declined", // INFERRED names, see header
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: { consent_recorded: accept },
      });
      return ok({ session: updated });
    }

    // ---- start (child only, consent-gated) ------------------------------------------
    if (action === "start") {
      requireRole(profile, "child"); // capture:144
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session || session.child_user_id !== uid) throw new ApiError(403, "forbidden", "Not your session.");
      if (new Date(session.expires_at).getTime() <= Date.now() && session.status === "accepted") {
        await db.from("remote_sessions").update({ status: "expired" }).eq("id", sessionId).eq("status", "accepted");
        throw new ApiError(410, "session_expired", "This session has expired."); // PE-S04 (15:187)
      }
      // capture:144 — requires status accepted AND consent_recorded. TE-14 (15:71) / PE-S05.
      if (session.status !== "accepted" || session.consent_recorded !== true) {
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }
      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update({ status: "active", started_at: new Date().toISOString() })
        .eq("id", sessionId)
        .eq("child_user_id", uid)
        .eq("status", "accepted") // capture:144 — compare-and-set
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not start the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        if (again?.status === "active") return ok({ session: again, idempotent: true }); // CI-04 (15:213)
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }
      await recordAudit(db, {
        eventType: "session_started", // INFERRED name
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: {},
      });
      return ok({ session: updated });
    }

    // ---- end (either participant) ----------------------------------------------------
    if (action === "end") {
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      // capture:145 — either participant; 14:136-137 parent OR child must equal the caller.
      if (session.parent_user_id !== uid && session.child_user_id !== uid) {
        throw new ApiError(403, "forbidden", "Not your session.");
      }
      // capture:145 — terminal states returned as-is (PE-S07: both calls 200).
      if ((TERMINAL_SESSION_STATUSES as readonly string[]).includes(session.status)) {
        return ok({ session, idempotent: true });
      }
      const reason = readOptionalString(body, "reason", { min: 1, max: 200 }); // A3:...:480 bound
      const { data: updated, error: uerr } = await db
        .from("remote_sessions")
        .update({
          status: "ended",
          ended_at: new Date().toISOString(),
          ended_by: uid,
          ended_reason: reason,
        })
        .eq("id", sessionId)
        .in("status", ["requested", "accepted", "active"]) // capture:145
        .select(SESSION_COLUMNS)
        .maybeSingle();
      ensureNoError(uerr, "Could not end the session.");
      if (!updated) {
        const { data: again } = await db.from("remote_sessions").select(SESSION_COLUMNS).eq("id", sessionId).maybeSingle();
        return ok({ session: again, idempotent: true });
      }
      await recordAudit(db, {
        eventType: "session_ended", // INFERRED name
        actorUserId: uid,
        familyId: session.family_id,
        deviceId: session.device_id,
        targetType: "remote_session",
        targetId: sessionId,
        metadata: { by: session.parent_user_id === uid ? "parent" : "child", reason },
      });
      return ok({ session: updated });
    }

    // ---- ice (participant, consent-gated, TURN credential) ---------------------------
    if (action === "ice") {
      const sessionId = readUuid(body, "session_id");
      const { data: session, error: lerr } = await db
        .from("remote_sessions")
        .select(SESSION_COLUMNS)
        .eq("id", sessionId)
        .maybeSingle();
      ensureNoError(lerr, "Could not read the session.");
      if (!session) throw new ApiError(403, "forbidden", "Not your session.");
      if (session.parent_user_id !== uid && session.child_user_id !== uid) {
        throw new ApiError(403, "forbidden", "Not your session."); // PE-S06 (15:189)
      }
      // capture:146 — status accepted|active AND consent_recorded required. PE-S05 (15:188):
      // ICE before consent is a 409, never a credential.
      if (!["accepted", "active"].includes(session.status) || session.consent_recorded !== true) {
        throw new ApiError(409, "session_not_open", "This session is not open.");
      }

      const ttl = clampInt(
        typeof body["ttl_seconds"] === "number" ? (body["ttl_seconds"] as number) : TURN_TTL_DEFAULT_SECONDS,
        TURN_TTL_MIN_SECONDS,
        TURN_TTL_MAX_SECONDS,
      );
      const expiry = Math.floor(Date.now() / 1000) + ttl;
      const username = `${expiry}:${uid}`; // capture:146 exact form
      const credential = await mintTurnCredential(username);
      const host = Deno.env.get("TURN_HOST"); // CONFIG, name NOT captured — see header
      if (!host) throw new ApiError(503, "server_misconfigured", "Server is not configured.");

      return ok({
        ice_servers: [
          { urls: [`turn:${host}:3478?transport=udp`, `turn:${host}:3478?transport=tcp`], username, credential },
        ],
        ttl_seconds: ttl,
        session_id: sessionId,
      });
    }

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
