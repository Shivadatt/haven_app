// auth-bootstrap / create_family — the first family, owned by the caller.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts`
// at port time for the project's 200-line source rule; behaviour unchanged.
//
// Captured anchors (capture:55, index lines 93-114 of the readable source):
//   requireRole(parent) -> one active family per owner -> rpc create_family_with_owner with
//   p_owner taken from the verified token, never from the body (audit 14:83-106, check 3).
// Return type IS captured: functions-and-triggers.md:37 records
//   create_family_with_owner(p_owner uuid, p_name text) -> jsonb.

import type { Actor, DbClient } from "../_shared/auth.ts";
import { requireRole } from "../_shared/auth.ts";
import { ApiError, ok } from "../_shared/envelope.ts";

/** `families_name_check` — captured in A3-staging-load-v1.sql:467 as char_length 1..80. */
const FAMILY_NAME_MAX = 80;

/**
 * PORT NOTE (2026-11-04): the pre-port `index.ts` verified the bearer token a second time
 * inside this branch (`await requireUser(...)` again after the dispatcher had already done
 * it). The duplicate call is removed; the gate itself is unchanged — one `requireUser` per
 * request, hoisted, exactly as that file's own comment described. Removing it removes one
 * round trip per request and no check.
 */
export async function createFamily(
  db: DbClient,
  auth: Actor,
  profileRole: string,
  body: Record<string, unknown>,
): Promise<Response> {
  requireRole({ role: profileRole }, "parent"); // capture:55 — 93; PE-A05: child -> 403 role_required

  const value = body["name"];
  if (typeof value !== "string" || value.length < 1 || value.length > FAMILY_NAME_MAX) {
    throw new ApiError(400, "validation_error", `name must be 1 to ${FAMILY_NAME_MAX} characters.`);
  }
  // Bound VERIFIED from families_name_check (A3:...:467), transcribed in `limits.ts`.

  // capture:55 — 96-109: one active family per owner. PE-A04 -> 409 family_exists.
  const { data: existing, error: ferr } = await db
    .from("families")
    .select("id")
    .eq("owner_id", auth.userId)
    .is("deleted_at", null)
    .maybeSingle();
  if (ferr) {
    console.error(`family_owner_lookup: ${ferr.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (existing) {
    throw new ApiError(409, "family_exists", "This account already owns a family.");
  }

  // capture:55 — 111-114.
  const { data, error } = await db.rpc("create_family_with_owner", {
    p_owner: auth.userId,
    p_name: value,
  });
  if (error) {
    console.error(`rpc_create_family: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "Could not create the family.");
  }
  // UNVERIFIED BEHAVIOUR — response shape not captured; no audit row is evidenced here.
  return ok({ family: data ?? null });
}
