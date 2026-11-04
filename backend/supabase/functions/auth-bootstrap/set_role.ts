// auth-bootstrap / set_role — one-time self-service role choice.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts`
// at port time for the project's 200-line source rule; behaviour unchanged.
//
// Captured anchors (capture:53-54, index lines 38-80 of the readable 140-line source):
//   requireUser(requireVerifiedEmail) -> role already set = 409 -> profiles update scoped to
//   the caller's own row -> recordAudit("role_set") -> child_contact_ids upsert, BEST EFFORT.
// Tests: 15-edge-function-test-plan.md:106-111 (PE-A01..A06).

import type { Actor, DbClient } from "../_shared/auth.ts";
import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { recordAudit } from "../_shared/audit.ts";
import { CONTACT_ID_PREFIX, readEnum } from "../_shared/validation.ts";
import { newContactId } from "../_shared/validation.ts";

/**
 * `profiles_role_check` (A3:...:479) admits only `unset|parent|child`, so self-service to
 * `unset` is impossible from the body — an out-of-vocabulary role is a 400 validation_error,
 * not a 403 (PE-A06, 15:111).
 */
export async function setRole(
  db: DbClient,
  auth: Actor,
  profileRole: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const requested = readEnum(body, "role", ["parent", "child"] as const);

  // capture:54 — 44-50: reject an existing role. One-time, from 'unset' only.
  if (profileRole !== "unset") {
    throw new ApiError(409, "role_already_set", "A role is already set for this account.");
  }

  // capture:54 — 53-58: profiles.update scoped to the caller's own row.
  // Self-escalation is bounded twice: the value set is the caller's own id, and
  // profiles_before_update rejects role changes once old.role <> 'unset'
  // (functions-and-triggers.md:22 — that body WAS read in B3b).
  const { error: perr } = await db.from("profiles").update({ role: requested }).eq("id", auth.userId);
  ensureNoError(perr, "Could not save the role.");

  // capture:54 — 61-67: recordAudit role_set. Actor from the verified token only.
  await recordAudit(db, {
    eventType: "role_set",
    actorUserId: auth.userId,
    familyId: null,
    deviceId: null,
    targetType: "profile",
    targetId: auth.userId,
    metadata: { role: requested, from: "unset" },
  });

  // capture:54 — 72-80: child_contact_ids upsert, BEST EFFORT. A contact-id failure must not
  // undo a committed role change, so this is wrapped and swallowed with a name-only log,
  // exactly as the anchor describes.
  if (requested === "child") {
    try {
      const { data: existing } = await db
        .from("child_contact_ids")
        .select("child_user_id, contact_id, created_at, rotated_at")
        .eq("child_user_id", auth.userId)
        .maybeSingle();
      if (!existing) {
        const { error: cerr } = await db
          .from("child_contact_ids")
          .upsert(
            {
              child_user_id: auth.userId,
              contact_id: newContactId(),
              created_at: new Date().toISOString(),
            },
            { onConflict: "child_user_id" },
          );
        if (cerr) console.error(`contact_id_upsert: ${cerr.code ?? "unknown"}`);
      }
    } catch (err) {
      console.error(`contact_id_best_effort: ${err instanceof Error ? err.name : "unknown"}`);
    }
  }

  // UNVERIFIED BEHAVIOUR — response shape not captured; {role} is a minimal honest body.
  return ok({ role: requested, contact_id_prefix: CONTACT_ID_PREFIX });
}
