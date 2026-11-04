// family-admin / device_actions — the two RPC-backed actions of this slug.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour, labels and evidence anchors are
// unchanged. Read `index.ts` for the captured-facts header and the gates that run before this.
// ============================================================================

import { assertFamilyParent, type DbClient } from "../_shared/auth.ts";
import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readUuid } from "../_shared/validation.ts";

export async function revokeDevice(
  db: DbClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = readUuid(body, "device_id");
  // HARDENING: scope asserted in-function (see index.ts on 14:149-152).
  const { data: device, error: derr } = await db
    .from("devices")
    .select("id, family_id, child_user_id, status, credential_revoked_at")
    .eq("id", deviceId)
    .maybeSingle();
  ensureNoError(derr, "Could not read the device.");
  if (!device) throw new ApiError(403, "forbidden", "Device not available.");
  await assertFamilyParent(db, userId, device.family_id);

  // capture:124 — p_actor_user_id is the verified subject.
  const { data, error } = await db.rpc("revoke_device", {
    p_device_id: deviceId,
    p_actor_user_id: userId,
  });
  if (error) {
    console.error(`rpc_revoke_device: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "Could not revoke that device.");
  }
  await recordAudit(db, {
    eventType: "device_revoked", // UNVERIFIED name — see index.ts header
    actorUserId: userId,
    familyId: device.family_id,
    deviceId,
    targetType: "device",
    targetId: deviceId,
    metadata: {},
  });
  // PE-F01 (15:171): D1 revoked AND the credential nulled. The nulling of secret_hash is
  // done inside private.revoke_device (unread body); the DB constraint
  // status='revoked' => secret_hash IS NULL (A3:...:464) makes it structural.
  return ok({ result: data ?? null });
}

export async function recoverDevice(
  db: DbClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const deviceId = readUuid(body, "device_id");
  const { data, error } = await db.rpc("request_device_recovery", {
    p_device_id: deviceId,
    p_actor_user_id: userId, // capture:125
  });
  if (error) {
    console.error(`rpc_request_device_recovery: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "Could not start device recovery.");
  }
  // No in-function scope check is added here: private.request_device_recovery's body WAS
  // read (B3b) and asserts an active parent of the device's family itself (14:55, :151).
  await recordAudit(db, {
    eventType: "device_recovery_started", // VERIFIED name from 15:173 (PE-F03)
    actorUserId: userId,
    familyId: null,
    deviceId,
    targetType: "device",
    targetId: deviceId,
    metadata: {},
  });
  return ok({ recovery: "started", result: data ?? null }); // PE-F03, 15:173
}
