// ============================================================================
// _shared/device_authority.ts — the two device paths, split out of
// _shared/auth.ts at port time for the 200-line source rule. Behaviour unchanged.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   Captured anchors: `_shared/auth.ts:266-289` (parent-side device load) and
//   `:295-338` (device credential), audit 14:143-160.
// ============================================================================

import { ApiError } from "./envelope.ts";
import type { DbClient } from "./db.ts";
import { constantTimeEqualHex, sha256Hex } from "./validation.ts";
import { assertFamilyParent } from "./family.ts";

// ---------------------------------------------------------------------------
// Device authority
// ---------------------------------------------------------------------------

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

/**
 * requireActiveDeviceForParent — :266-289. family_id is ALWAYS taken from the device row,
 * never from the body (14:134-135), then parent membership in THAT family is asserted.
 */
export async function requireActiveDeviceForParent(
  db: DbClient,
  userId: string,
  deviceId: string,
): Promise<any> {
  const { data: device, error } = await db
    .from("devices")
    .select(DEVICES_SELECT)
    .eq("id", deviceId)
    .maybeSingle();
  if (error) {
    console.error(`device_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!device) throw new ApiError(403, "forbidden", "Device not available.");
  if (device.status !== "active") {
    throw new ApiError(403, "forbidden", "Device is not active.");
  }
  await assertFamilyParent(db, userId, device.family_id);
  return device;
}

/**
 * requireDevice — :295-338. The device credential channel.
 *   x-device-id (UUID) + x-device-secret (16..512 chars)
 *   secret is hashed with SHA-256 and compared to devices.secret_hash with the
 *   length-constant-time helper; a missing row or missing hash still performs a comparison
 *   against an all-zero digest so unknown ids and wrong secrets cost the same (:325-330).
 *   REVOCATION IS HONOURED: status != 'active' OR credential_revoked_at IS NOT NULL -> 401.
 *   No lockout exists on this path (finding E7); that is preserved, not silently "fixed".
 */
export async function requireDevice(req: Request, db: DbClient): Promise<any> {
  const deviceId = req.headers.get("x-device-id");
  const secret = req.headers.get("x-device-secret");
  if (!deviceId || !secret) {
    throw new ApiError(401, "device_auth_required", "Device credentials are required.");
  }
  const id = deviceId.trim().toLowerCase();
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id);
  if (!isUuid || secret.length < 16 || secret.length > 512) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }

  const { data: device, error } = await db
    .from("devices")
    .select(DEVICES_SELECT)
    .eq("id", id)
    .maybeSingle();
  if (error) {
    console.error(`device_auth_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }

  const storedHash: string | null = device?.secret_hash ?? null;
  const presentedHash = await sha256Hex(secret);
  // :325-330 decoy comparison — same cost whether or not the row exists.
  const matches = await constantTimeEqualHex(presentedHash, storedHash ?? "0".repeat(64));

  if (!device || storedHash === null || !matches) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  if (device.status !== "active" || device.credential_revoked_at !== null) {
    // Revoked credential. Code name reuses the evidenced 401 rather than inventing one.
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  return device;
}
