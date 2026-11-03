// ============================================================================
// _shared/audit.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   Deployed text never read. capture-20261030.json:165 records 1101 chars / 38 lines,
//   sha256 649d277e..., note: "recordAudit inserts audit_logs with a caller-supplied
//   actor_user_id and throws audit_failed (500) on insert error."
//   Fails-the-request behaviour VERIFIED as a control at
//   docs/stage1/14-edge-function-security-audit.md:293 ("audit.ts:28-37") and :340.
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: audit_logs (INSERT only).
//   Column whitelist from docs/stage1/evidence/schema-columns.md:10-22 and the emitted DDL
//   docs/stage2/migrations/A3-staging-load-v1.sql:433-436 — event_type 1..80 chars,
//   target_type <=40, target_id <=128, metadata must be a JSON object (jsonb_typeof).
// SECRETS USED: none (uses the service-role client passed in by the caller).
//
// ARCHITECTURAL NOTE (finding E14, 14:297-299): the actor is a value the HANDLER supplies,
//   not something the database derives. This module therefore accepts only an explicitly
//   named `actorUserId` and never reads one from a request body. Callers must pass
//   `auth.user.id` from the verified token.
//
// UNVERIFIED BEHAVIOUR:
//   - Whether recordAudit ever writes `created_at` explicitly is not captured; it is not
//     written here (the column is NOT NULL with a captured default in the A3 DDL).
//   - Whether the deployed module returns the inserted row is not captured; void here.
// ============================================================================

import { ApiError } from "./envelope.ts";

export interface SupabaseLike {
  from(table: string): any;
}

export interface AuditInput {
  eventType: string;
  actorUserId?: string | null;
  familyId?: string | null;
  deviceId?: string | null;
  targetType?: string | null;
  targetId?: string | null;
  metadata?: Record<string, unknown>;
}

/**
 * recordAudit — the only writer of audit_logs in this package.
 * A failed insert THROWS (500 audit_failed) so an action can never silently succeed
 * unaudited (14:293). Device-originated events pass actorUserId = null and a deviceId,
 * which is how they are distinguished from user actions (14:296).
 */
export async function recordAudit(db: SupabaseLike, input: AuditInput): Promise<void> {
  const eventType = input.eventType;
  if (typeof eventType !== "string" || eventType.length < 1 || eventType.length > 80) {
    // Guard the DB check constraint locally so the failure is an obvious 500 rather than
    // a PostgREST message leak. Boundary values from A3-staging-load-v1.sql:433.
    throw new ApiError(500, "audit_failed", "Audit write failed.");
  }
  const row = {
    family_id: input.familyId ?? null,
    actor_user_id: input.actorUserId ?? null,
    device_id: input.deviceId ?? null,
    event_type: eventType,
    target_type: input.targetType ?? null,
    target_id: input.targetId ?? null,
    metadata: input.metadata ?? {},
  };
  const { error } = await db.from("audit_logs").insert(row);
  if (error) {
    console.error(`audit_insert_failed: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "audit_failed", "Audit write failed.");
  }
}
