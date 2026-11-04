// pairing / requests — REQUEST-STATE actions: pending_child, respond and list_family.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Each action below was sliced
// VERBATIM out of the captured switch in `index.ts` at port time for the project's 200-line source
// rule; behaviour, labels and evidence anchors are unchanged. The full captured-facts header stays
// in `index.ts` — read it before editing. `db`, `uid` (the verified user id), `profile` and the
// parsed `body` are handed in by the dispatcher: no identity value is ever read from the body.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import { readBoolean, readUuid } from "../_shared/validation.ts";
import { PENDING_LIST_LIMIT, REQUEST_COLUMNS } from "./shared.ts";

export async function handlePendingChild(
  db: DbClient,
  uid: string,
  profile: { role: string },
): Promise<Response> {
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

export async function handleRespond(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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

export async function handleListFamily(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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
