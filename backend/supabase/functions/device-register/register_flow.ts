// device-register / register_flow — the two write paths behind action "register".
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Split out of `index.ts`
// at port time for the project's 200-line source rule; behaviour unchanged. The identity,
// role, email and family-membership gates stay in `index.ts` and run BEFORE this code.
//
// What lives here and why: `publicDevice` is the captured H() projection (capture:82; VERIFIED
// as a control at 14:341) — secret_hash and installation_id are selected OUT of the response;
// the re-credential and fresh-insert branches as the review described them (14:146-147 lookup
// within the asserted family, PE-R03/R04 in 15:132-133); and ALLOW_RELINK_AFTER_REVOKED_PAIRING
// = false, which keeps capture:82's ambiguity fail-closed. Flipping that flag is an owner
// ruling, not an edit to make here.
// ============================================================================

import type { DbClient } from "../_shared/auth.ts";
import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { recordAudit } from "../_shared/audit.ts";
import { readString } from "../_shared/validation.ts";

const ALLOW_RELINK_AFTER_REVOKED_PAIRING = false;

const DEVICE_COLUMNS =
  "id, family_id, child_user_id, display_name, platform, android_version, app_version, status, enforcement_mode, policy_version, credential_issued_at, credential_revoked_at, last_seen_at, created_at, updated_at";
// DELIBERATELY ABSENT: secret_hash, installation_id — capture:82 "response strips secret_hash
// and installation_id (H())" (14:254-255, 14:341). Selecting them out is the control.

export function publicDevice(
  row: Record<string, unknown> | null,
): Record<string, unknown> | null {
  if (!row) return null;
  const copy = { ...row };
  delete copy["secret_hash"];
  delete copy["installation_id"];
  return copy;
}

export function readInstallationId(body: Record<string, unknown>): string {
  // readInstallationId (capture:82). Bound VERIFIED from devices_installation_id_check,
  // A3-staging-load-v1.sql:461 -> 8..128 characters.
  return readString(body, "installation_id", { min: 8, max: 128 });
}

/** The body fields `index.ts` read and validated, handed over as one object. */
export interface RegistrationInput {
  familyId: string;
  installationId: string;
  displayName: string;
  androidVersion: string | null;
  appVersion: string | null;
  secretHash: string;
}

export async function registerDevice(
  db: DbClient,
  userId: string,
  input: RegistrationInput,
): Promise<Response> {
  const {
    familyId,
    installationId,
    displayName,
    androidVersion,
    appVersion,
    secretHash,
  } = input;
  const now = new Date().toISOString();

  // capture:82 / 14:146-147 — the installation id is looked up WITHIN the asserted family.
  const { data: existing, error: ferr } = await db
    .from("devices")
    .select(
      "id, family_id, child_user_id, status, secret_hash, credential_issued_at, credential_revoked_at",
    )
    .eq("family_id", familyId)
    .eq("installation_id", installationId)
    .maybeSingle();
  ensureNoError(ferr, "Could not look up this installation.");

  if (existing) {
    // A row owned by a DIFFERENT child in the same family: 409 device_exists (PE-R04).
    if (existing.child_user_id !== userId) {
      throw new ApiError(
        409,
        "device_exists",
        "That installation already belongs to another child.",
      );
    }

    if (existing.status === "revoked") {
      // capture:82 — device_registration_blocked. Audited BEFORE the 403 so a denial trace
      // exists (14:122 audit vocabulary for this slug).
      if (!ALLOW_RELINK_AFTER_REVOKED_PAIRING) {
        await recordAudit(db, {
          eventType: "device_registration_blocked",
          actorUserId: userId,
          familyId,
          deviceId: existing.id,
          targetType: "device",
          targetId: existing.id,
          metadata: { reason: "revoked_installation" },
        });
        throw new ApiError(
          403,
          "device_registration_blocked",
          "This device was revoked and cannot re-register.",
        );
      }
      // UNREACHED while the flag is false — the alternative reading of capture:82 would
      // allow a re-credential here only if a pairing_request for this child has
      // status='approved' and responded_at > existing.credential_revoked_at.
      throw new ApiError(
        501,
        "device_registration_blocked",
        "Revoked-device relink is not specified (capture:82 is ambiguous).",
      );
    }

    // PE-R03 (15:133) — same installation again = re-credential, audit device_recredentialed.
    // devices_revoked_credential_consistency (A3:...:464) forbids status='revoked' with a
    // non-null secret_hash, so status and secret_hash are always written together here.
    const { data: updated, error: uerr } = await db
      .from("devices")
      .update({
        secret_hash: secretHash,
        credential_issued_at: now,
        credential_revoked_at: null,
        status: "active", // INFERRED — see header
        display_name: displayName,
        android_version: androidVersion,
        app_version: appVersion,
      })
      .eq("id", existing.id)
      .eq("family_id", familyId)
      .eq("child_user_id", userId) // three-part scope: service-role has no RLS net
      .select(DEVICE_COLUMNS)
      .maybeSingle();
    ensureNoError(uerr, "Could not re-credential this device.");
    await recordAudit(db, {
      eventType: "device_recredentialed",
      actorUserId: userId,
      familyId,
      deviceId: existing.id,
      targetType: "device",
      targetId: existing.id,
      metadata: {},
    });
    return ok({
      device: publicDevice(
        (updated ?? existing) as Record<string, unknown> | null,
      ),
    });
  }

  // Fresh registration.
  const insertRow: Record<string, unknown> = {
    family_id: familyId,
    child_user_id: userId, // from the verified token only
    installation_id: installationId,
    display_name: displayName,
    secret_hash: secretHash, // capture:82 "secret_hash from client" — finding E10
    credential_issued_at: now,
    status: "active", // INFERRED — see header
    created_at: now,
    updated_at: now,
  };
  if (androidVersion !== null) insertRow["android_version"] = androidVersion;
  if (appVersion !== null) insertRow["app_version"] = appVersion;

  const inserted = await db.from("devices").insert(insertRow).select(
    DEVICE_COLUMNS,
  );
  if (inserted.error) {
    if (inserted.error.code === "23505") {
      // UNIQUE (family_id, installation_id) or devices_one_active_per_child (A3:...:480, :572).
      throw new ApiError(
        409,
        "device_exists",
        "A device already exists for this installation.",
      );
    }
    // 14:280-283 notes the captured bundle throws the RAW error object on this path
    // (inconsistent with the rest of the codebase). Re-authored with ensureNoError,
    // which is strictly less leaky; disclosed as a deviation in DEPLOYMENT-MAP.md.
    ensureNoError(inserted.error, "Could not register this device.");
  }
  const created = inserted.data?.[0] ?? null;
  await recordAudit(db, {
    eventType: "device_registered",
    actorUserId: userId,
    familyId,
    deviceId: created?.id ?? null,
    targetType: "device",
    targetId: created?.id ?? null,
    metadata: {},
  });
  // capture:82 / PE-R01 (15:131): the response carries NEITHER secret_hash NOR installation_id.
  return ok({
    device: publicDevice(created as Record<string, unknown> | null),
  });
}
