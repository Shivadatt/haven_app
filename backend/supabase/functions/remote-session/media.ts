// remote-session / media — the MEDIA-plane actions: "start" (capture:144), "end" (capture:145)
// and "ice" (capture:146).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors are unchanged and the
// full captured-facts header stays in `index.ts`. Read that header before editing this file.
//
// Consent is load-bearing here: "start" needs status accepted AND consent_recorded, and "ice"
// refuses to mint a TURN credential without both (PE-S05, 15:188). TURN_SECRET and TURN_HOST are
// read by NAME only — never logged, never returned, never written to a file in this repository.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { requireRole, type DbClient } from "../_shared/auth.ts";
import { recordAudit } from "../_shared/audit.ts";
import { clampInt, readOptionalString, readUuid } from "../_shared/validation.ts";
import { SESSION_COLUMNS } from "./lifecycle.ts";

const TURN_TTL_MIN_SECONDS = 60; // capture:146 "TTL clamp 60..86400"
const TURN_TTL_MAX_SECONDS = 86_400;
const TURN_TTL_DEFAULT_SECONDS = 600; // capture:146 "default 600"

const TERMINAL_SESSION_STATUSES = ["declined", "ended", "expired", "failed"] as const; // 14:209

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

export async function handleStart(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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

export async function handleEnd(
  db: DbClient,
  uid: string,
  body: Record<string, unknown>,
): Promise<Response> {
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

export async function handleIce(
  db: DbClient,
  uid: string,
  body: Record<string, unknown>,
): Promise<Response> {
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
