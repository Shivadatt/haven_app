// pairing / issuance — ISSUANCE actions: get_contact_id, create (a code) and invite.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Each action below was sliced
// VERBATIM out of the captured switch in `index.ts` at port time for the project's 200-line source
// rule; behaviour, labels and evidence anchors are unchanged. The full captured-facts header stays
// in `index.ts` — read it before editing. `db`, `uid` (the verified user id), `profile` and the
// parsed `body` are handed in by the dispatcher: no identity value is ever read from the body.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import { recordPairingAttempt } from "../_shared/rate_limit.ts";
import {
  assertInviteQuotaAllowed,
  assertPairingCodeCreationAllowed,
} from "../_shared/quotas.ts";
import {
  CONTACT_ID_RE,
  identifierHash,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  readUuid,
  sha256Hex,
} from "../_shared/validation.ts";
import {
  CODE_TTL_MINUTES,
  INVITE_TTL_MINUTES,
  MAX_ATTEMPTS_PER_CODE,
  invalidIdentifier,
  ttl,
} from "./shared.ts";

export async function handleGetContactId(
  db: DbClient,
  uid: string,
  profile: { role: string },
): Promise<Response> {
        requireRole(profile, "child"); // 14:114
        const { data: existing, error } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id, created_at, rotated_at")
          .eq("child_user_id", uid)
          .maybeSingle();
        ensureNoError(error, "Could not read the contact id.");
        if (existing) return ok({ contact_id: existing.contact_id });
        // PE-P01 (15:88): no row yet -> 200, `PC` + 8 chars, row created.
        let contactId = newContactId();
        for (let attempt = 0; attempt < 3; attempt++) {
          const ins = await db
            .from("child_contact_ids")
            .insert({ child_user_id: uid, contact_id: contactId, created_at: new Date().toISOString() });
          if (!ins.error) break;
          if (ins.error.code !== "23505") ensureNoError(ins.error, "Could not create the contact id.");
          // UNIQUE collision on contact_id (schema-columns.md:28): draw again.
          contactId = newContactId();
          if (attempt === 2) throw new ApiError(500, "internal_error", "Could not create the contact id.");
        }
        return ok({ contact_id: contactId });
}

export async function handleCreate(
  db: DbClient,
  uid: string,
  profile: { role: string },
): Promise<Response> {
        requireRole(profile, "child");
        await assertPairingCodeCreationAllowed(db, uid); // capture:33 rate_limit; 14:171
        const code = newPairingCode();
        const normalized = normalizeIdentifier(code);
        // 16:229-237 — VERBATIM from pairing:562-564, quoted so the two-digest design is
        // not "simplified" away by a later reader:
        //   // Two digests on purpose: the token row keeps plain SHA-256 so codes
        //   // issued before this change still redeem, while attempt records use
        //   // the keyed digest so a database dump cannot recover the identifier.
        // Token rows therefore use sha256Hex (finding E5, preserved deliberately).
        const codeHash = await sha256Hex(normalized);
        const expiresAt = ttl(CODE_TTL_MINUTES);
        const { error: insErr } = await db.from("device_pairing_tokens").insert({
          child_user_id: uid,
          code_hash: codeHash,
          purpose: "code", // vocabulary VERIFIED A3:...:450
          status: "active", // vocabulary VERIFIED A3:...:451
          expires_at: expiresAt,
          attempts: 0,
          max_attempts: MAX_ATTEMPTS_PER_CODE,
          created_at: new Date().toISOString(),
          created_by: uid,
        });
        ensureNoError(insErr, "Could not create a pairing code.");
        // The plaintext code is returned exactly once and is never stored (schema-columns.md:290).
        return ok({ code, expires_at: expiresAt });
}

export async function handleInvite(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
        requireRole(profile, "parent");
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:38 — 764
        const normalized = normalizeIdentifier(
          (() => {
            const v = body["contact_id"];
            if (typeof v !== "string" || v.length < 1 || v.length > 32) invalidIdentifier();
            return v as string;
          })(),
        );
        const attemptHash = await identifierHash(normalized); // capture:38 — 771 (KEYED digest)

        // PE-P07 (15:94): a malformed Child ID is a 400 invalid_code AND exactly ONE attempt
        // recorded — hence recordPairingAttempt at :772 happens on this branch too.
        if (!CONTACT_ID_RE.test(normalized)) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false }); // :772
          invalidIdentifier();
        }

        const { data: contact, error: cerr } = await db
          .from("child_contact_ids")
          .select("child_user_id, contact_id")
          .eq("contact_id", normalized)
          .maybeSingle();
        ensureNoError(cerr, "Could not look up that Child ID.");
        if (!contact) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          invalidIdentifier();
        }

        const childUserId = contact.child_user_id as string;
        await assertInviteQuotaAllowed(db, childUserId); // 14:171: 3 pending / 10 per 24 h per child

        const { data: existingChild, error: xmerr } = await db
          .from("family_members")
          .select("family_id, status")
          .eq("user_id", childUserId)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(xmerr, "Could not check the child membership.");
        if (existingChild) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          if (existingChild.family_id === familyId) {
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          invalidIdentifier();
        }

        // capture:38 — 378-383: rpc create_pairing_invite, p_parent_user_id = auth.user.id
        const expiresAt = ttl(INVITE_TTL_MINUTES);
        const inviteCodeHash = await sha256Hex(normalized);
        const { data, error } = await db.rpc("create_pairing_invite", {
          p_child_user_id: childUserId,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_code_hash: inviteCodeHash,
          p_expires_at: expiresAt,
        });
        if (error) {
          console.error(`rpc_create_pairing_invite: ${error.code ?? "unknown"}`);
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          throw new ApiError(500, "internal_error", "Could not create the invite.");
        }
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        // UNVERIFIED BEHAVIOUR — invite response shape not captured.
        return ok({ invite: data ?? null, expires_at: expiresAt });
}
