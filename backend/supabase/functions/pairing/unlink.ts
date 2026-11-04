// pairing / unlink — CANCEL and UNLINK — the two destructive pairing mutations.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Each action below was sliced
// VERBATIM out of the captured switch in `index.ts` at port time for the project's 200-line source
// rule; behaviour, labels and evidence anchors are unchanged. The full captured-facts header stays
// in `index.ts` — read it before editing. `db`, `uid` (the verified user id), `profile` and the
// parsed `body` are handed in by the dispatcher: no identity value is ever read from the body.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import {
  assertChildMembership,
  assertFamilyParent,
  requireRole,
  type DbClient,
} from "../_shared/auth.ts";
import { readUuid } from "../_shared/validation.ts";
import { REQUEST_COLUMNS } from "./shared.ts";

export async function handleCancel(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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

export async function handleUnlink(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
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
