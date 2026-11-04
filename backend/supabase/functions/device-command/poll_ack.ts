// device-command / poll_ack — the DEVICE-credential channel actions of this slug.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts` at
// port time for the project's 200-line source rule; behaviour, labels and anchors unchanged.
// Read `index.ts` for the captured-facts header.
//
// Auth: x-device-id + x-device-secret via requireDevice (capture:64). A body `device_id` is
// ignored entirely — PE-C05 (15:122) proves the forged-id case must return the AUTHENTICATED
// device's commands.
//
// UNVERIFIED BEHAVIOUR carried from index.ts:
//   - `command_ack_recorded` is a labelled invention: no anchor names the audit event_type.
//     Device-originated events carry a NULL actor (14:296).
//   - Which policy row an apply_policy `ack` acknowledges: capture:69 says only "updates
//     device_policies and devices.policy_version scoped to device". The version-selection rule
//     (latest pending for the device) is INFERRED.
//   - Whether `ack` may report enforcement failures for a failed ack: implemented as the natural
//     reading of the vocabulary and labelled INFERRED.
//   - `delivered` is written by poll_device_commands (inside the unread RPC), not here.
// ============================================================================

import { ApiError, ensureNoError, fail, ok } from "../_shared/envelope.ts";
import { getServiceClient, requireDevice } from "../_shared/auth.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readEnum, readObject, readOptionalString, readUuid } from "../_shared/validation.ts";
import { COMMAND_COLUMNS } from "./create.ts";

const POLL_LIMIT = 20; // capture:68
const COMMAND_RESULT_MAX = 32 * 1024; // 14:224
const ERROR_MESSAGE_MAX = 500; // VERIFIED by the DB check at A3:...:442

const TERMINAL_COMMAND_STATUSES = ["succeeded", "failed", "expired"] as const; // A3:...:445 vocabulary;
const ACKABLE_STATUSES = ["pending", "delivered"] as const; // capture:69 — ".in(status,[pending,delivered])"

export async function handlePoll(req: Request): Promise<Response> {
  const db = getServiceClient();
  const device = await requireDevice(req, db);
  // capture:68 — p_device_id is the AUTHENTICATED device; any body device_id is ignored
  // (PE-C05, 15:122).
  const { data, error } = await db.rpc("poll_device_commands", {
    p_device_id: device.id,
    p_limit: POLL_LIMIT,
  });
  if (error) {
    console.error(`rpc_poll_device_commands: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "Could not fetch commands.");
  }
  // Finding E11 PRESERVED (14:421-439): the rows returned carry created_by, i.e. the
  // parent's user id reaches the child's device. The projection narrowing is PROPOSED —
  // NOT APPLIED, because it is a client-visible contract change (14:434-436).
  return ok({ commands: data ?? [] });
}

export async function handleAck(
  req: Request,
  body: Record<string, unknown>,
): Promise<Response> {
  const db = getServiceClient();
  const device = await requireDevice(req, db);
  const commandId = readUuid(body, "command_id");
  const status = readEnum(body, "status", ["succeeded", "failed"] as const); // PE-C07 (15:124)
  const result = body["result"] === undefined || body["result"] === null
    ? null
    : readObject(body, "result", COMMAND_RESULT_MAX); // 14:224
  const rawError = readOptionalString(body, "error_message", { min: 1, max: ERROR_MESSAGE_MAX });
  const errorMessage = rawError === null ? null : rawError.slice(0, ERROR_MESSAGE_MAX); // 14:224 truncation

  // capture:69 — select .eq(id).eq(device_id, o.id): a command belonging to another
  // device is invisible, hence 404 not 403 (PE-C06, 15:122).
  const { data: command, error: cerr } = await db
    .from("device_commands")
    .select(COMMAND_COLUMNS)
    .eq("id", commandId)
    .eq("device_id", device.id)
    .maybeSingle();
  ensureNoError(cerr, "Could not read the command.");
  if (!command) throw new ApiError(404, "command_not_found", "No such command for this device.");

  // PE-C08 (15:124): an expired command -> 410 command_expired AND the row moved to
  // 'expired'. Compare-and-set so a concurrent ack cannot land on an expired row.
  if (new Date(command.expires_at).getTime() <= Date.now()) {
    await db
      .from("device_commands")
      .update({ status: "expired" })
      .eq("id", command.id)
      .in("status", ACKABLE_STATUSES as unknown as string[]);
    return fail(410, "command_expired", "This command has expired.");
  }

  // capture:69 — terminal status returns the existing row (TE-17, 15:74).
  if ((TERMINAL_COMMAND_STATUSES as readonly string[]).includes(command.status)) {
    return ok({ command, idempotent: true });
  }

  const { data: updated, error: uerr } = await db
    .from("device_commands")
    .update({
      status,
      acked_at: new Date().toISOString(),
      result: result ?? {},
      error_message: errorMessage,
      attempts: (command.attempts ?? 0) + 1,
    })
    .eq("id", command.id)
    .eq("device_id", device.id)
    .in("status", ACKABLE_STATUSES as unknown as string[]) // capture:69
    .select(COMMAND_COLUMNS)
    .maybeSingle();
  ensureNoError(uerr, "Could not record the acknowledgement.");
  if (!updated) {
    // 14:306-309 — lost the race: re-read and return the current row.
    const { data: again } = await db
      .from("device_commands")
      .select(COMMAND_COLUMNS)
      .eq("id", commandId)
      .eq("device_id", device.id)
      .maybeSingle();
    return ok({ command: again ?? null, idempotent: true });
  }

  // capture:69 — apply_policy ack updates device_policies AND devices.policy_version,
  // both scoped to this device.
  if (command.type === "apply_policy" && status === "succeeded") {
    const { data: pendingPolicy, error: perr2 } = await db
      .from("device_policies")
      .select("id, version, policy, enforcement_status")
      .eq("device_id", device.id)
      .eq("family_id", device.family_id)
      .eq("enforcement_status", "pending") // A3:...:452 vocabulary
      .order("version", { ascending: false })
      .limit(1)
      .maybeSingle();
    ensureNoError(perr2, "Could not read the pending policy.");
    if (pendingPolicy) {
      await db
        .from("device_policies")
        .update({ acknowledged_at: new Date().toISOString(), enforcement_status: "enforced" })
        .eq("id", pendingPolicy.id)
        .eq("device_id", device.id);
      await db
        .from("devices")
        .update({ policy_version: pendingPolicy.version })
        .eq("id", device.id); // scoped to the authenticated device
    }
  } else if (command.type === "apply_policy" && status === "failed") {
    // INFERRED (see header): a failed ack records the failure instead of advancing the version.
    const { data: failedPolicy } = await db
      .from("device_policies")
      .select("id, enforcement_status")
      .eq("device_id", device.id)
      .eq("family_id", device.family_id)
      .eq("enforcement_status", "pending")
      .order("version", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (failedPolicy) {
      await db
        .from("device_policies")
        .update({ enforcement_status: "failed", last_error: errorMessage })
        .eq("id", failedPolicy.id)
        .eq("device_id", device.id);
    }
  }

  await recordAudit(db, {
    eventType: "command_ack_recorded", // UNVERIFIED name; see header
    actorUserId: null, // 14:296 — device-originated events carry a NULL actor
    familyId: device.family_id,
    deviceId: device.id,
    targetType: "command",
    targetId: command.id,
    metadata: { type: command.type, status },
  });
  return ok({ command: updated });
}
