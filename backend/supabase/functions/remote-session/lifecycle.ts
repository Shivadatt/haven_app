// remote-session / lifecycle — the REQUEST-side actions: "request" (capture:141),
// "pending_child" (capture:142) and "respond" (capture:143).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors are unchanged and the
// full captured-facts header stays in `index.ts`. Read that header before editing this file.
//
// The verified identity, verified email and role gate are NOT hoisted into index.ts for this
// slug's actions: each action names its own required role, exactly as the captured handler did,
// so `profile` is passed in and requireRole runs inside each block.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { requireActiveDeviceForParent, requireRole, type DbClient } from "../_shared/auth.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readBoolean, readEnum, readUuid } from "../_shared/validation.ts";

const REQUEST_TTL_MINUTES = 10; // capture:141 "expires_at = now + 10 min"
const ACCEPTED_TTL_MINUTES = 30; // capture:143 "expires_at now + 30 min"
const PENDING_LIST_LIMIT = 50; // capture:142 "list up to 50"

const SESSION_KINDS = ["audio", "video"] as const; // VERIFIED: A3:...:481 + the unread-but-quoted RPC body

export const SESSION_COLUMNS =
  "id, family_id, device_id, parent_user_id, child_user_id, kind, status, requested_at, accepted_at, started_at, ended_at, expires_at, ended_by, ended_reason, consent_recorded, session_nonce, created_at";

export function isoIn(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

export async function handleRequest(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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

export async function handlePendingChild(
  db: DbClient,
  uid: string,
  profile: { role: string },
): Promise<Response> {
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

export async function handleRespond(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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
