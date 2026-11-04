// family-admin / alerts — action "ack_alert" (capture:126).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour and anchors unchanged.
//
// UNVERIFIED (carried from index.ts): ack_alert moves the alert out of no queue and marks it
// read beyond acknowledged_at / acknowledged_by — the anchors name only those two columns.
// ============================================================================

import { assertFamilyParent, type DbClient } from "../_shared/auth.ts";
import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readUuid } from "../_shared/validation.ts";

export async function acknowledgeAlert(
  db: DbClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const alertId = readUuid(body, "alert_id");
  // capture:126 — select by alert_id, FAMILY ASSERTED BEFORE UPDATE.
  const { data: alert, error: aerr } = await db
    .from("safety_alerts")
    .select("id, family_id, device_id, type, severity, acknowledged_at, acknowledged_by")
    .eq("id", alertId)
    .maybeSingle();
  ensureNoError(aerr, "Could not read the alert.");
  if (!alert) throw new ApiError(400, "validation_error", "No such alert.");
  await assertFamilyParent(db, userId, alert.family_id); // PE-F04 (15:174) -> 403
  const { error: uerr } = await db
    .from("safety_alerts")
    .update({ acknowledged_at: new Date().toISOString(), acknowledged_by: userId })
    .eq("id", alertId)
    .eq("family_id", alert.family_id); // two-predicate scope: service-role has no RLS net
  ensureNoError(uerr, "Could not acknowledge the alert.");
  await recordAudit(db, {
    eventType: "alert_acknowledged", // capture:126
    actorUserId: userId,
    familyId: alert.family_id,
    deviceId: alert.device_id ?? null,
    targetType: "safety_alert",
    targetId: alertId,
    metadata: { alert_type: alert.type, severity: alert.severity },
  });
  return ok({ alert_id: alertId, acknowledged: true });
}
