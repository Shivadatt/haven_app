// pairing / redeem — the REDEEM action — the code/contact-id exchange (capture:37-38).
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Each action below was sliced
// VERBATIM out of the captured switch in `index.ts` at port time for the project's 200-line source
// rule; behaviour, labels and evidence anchors are unchanged. The full captured-facts header stays
// in `index.ts` — read it before editing. `db`, `uid` (the verified user id), `profile` and the
// parsed `body` are handed in by the dispatcher: no identity value is ever read from the body.
// ============================================================================

import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import {
  assertPairingRedeemAllowed,
  recordPairingAttempt,
} from "../_shared/rate_limit.ts";
import {
  identifierHash,
  isContactIdForm,
  normalizeIdentifier,
  PAIRING_CODE_RE,
  readUuid,
  sha256Hex,
} from "../_shared/validation.ts";
import { CODE_TTL_MINUTES, TOKEN_COLUMNS, invalidIdentifier, ttl } from "./shared.ts";

export async function handleRedeem(
  db: DbClient,
  uid: string,
  profile: { role: string },
  body: Record<string, unknown>,
): Promise<Response> {
        requireRole(profile, "parent"); // capture:37 — 548
        const familyId = readUuid(body, "family_id");
        await assertFamilyParent(db, uid, familyId); // capture:37 — 551. TE-01 (15:58) -> 403 forbidden
        const raw = (() => {
          const v = body["code"];
          if (typeof v !== "string" || v.length < 1 || v.length > 64) {
            invalidIdentifier();
          }
          return v as string;
        })();
        const normalized = normalizeIdentifier(raw);

        // pairing:555-560 routing (UNVERIFIED — see header). Anti-oracle-safe reading:
        // a Child-ID-shaped value gets the identical uniform error with NO database probe,
        // and anything outside the 30-symbol alphabet is rejected the same way.
        if (isContactIdForm(normalized)) invalidIdentifier();
        if (!PAIRING_CODE_RE.test(normalized)) invalidIdentifier();

        const codeHash = await sha256Hex(normalized); // capture:37 — 565
        const attemptHash = await identifierHash(normalized); // capture:37 — 566 (KEYED digest)
        await assertPairingRedeemAllowed(db, uid, attemptHash); // capture:37 — 567, BEFORE the lookup

        const failAttempt = async (): Promise<never> => {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          return invalidIdentifier();
        };

        // capture:37 — 574-578: token lookup by code_hash
        const { data: token, error: terr } = await db
          .from("device_pairing_tokens")
          .select(TOKEN_COLUMNS)
          .eq("code_hash", codeHash)
          .eq("purpose", "code")
          .maybeSingle();
        ensureNoError(terr, "Could not check the pairing code.");
        if (!token) return await failAttempt();

        // capture:37 — 585-599: status / expiry gate, uniform body, expired row transitioned
        // under an .eq(status,"active") guard so a concurrent redeemer cannot double-spend.
        const now = Date.now();
        const expired = new Date(token.expires_at).getTime() <= now;
        if (token.status !== "active" || expired || token.attempts >= token.max_attempts) {
          if (expired && token.status === "active") {
            await db
              .from("device_pairing_tokens")
              .update({ status: "expired" })
              .eq("id", token.id)
              .eq("status", "active");
          }
          return await failAttempt();
        }

        // A child may hold at most ONE active family (family_members_one_active_child_family,
        // A3:...:480). PE-P05: already linked here -> 409 child_already_linked.
        // PE-P06 (15:93): already linked ELSEWHERE -> the uniform 400, so family membership
        // of another household is not disclosed through this endpoint.
        const { data: membership, error: merr } = await db
          .from("family_members")
          .select("family_id, role, status")
          .eq("user_id", token.child_user_id)
          .eq("status", "active")
          .eq("role", "child")
          .maybeSingle();
        ensureNoError(merr, "Could not check the child membership.");
        if (membership) {
          if (membership.family_id === familyId) {
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "child_already_linked", "This child is already linked to your family.");
          }
          return await failAttempt();
        }

        // pairing:628-632 — a request already exists for this token? (UNIQUE token_id,
        // schema-columns.md:182). Second redemption -> 409 code_unavailable (14:173-177).
        const { data: prior, error: prerr } = await db
          .from("pairing_requests")
          .select("id")
          .eq("token_id", token.id)
          .maybeSingle();
        ensureNoError(prerr, "Could not check existing pairing requests.");
        if (prior) {
          await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
          throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
        }

        // capture:37 — 668-674: rpc create_pairing_request, p_parent_user_id = auth.user.id
        const expiresAtRequest = ttl(CODE_TTL_MINUTES);
        const { data, error } = await db.rpc("create_pairing_request", {
          p_child_user_id: token.child_user_id,
          p_family_id: familyId,
          p_parent_user_id: uid,
          p_token_id: token.id,
          p_expires_at: expiresAtRequest,
        });
        if (error) {
          // 14:277 — RPC messages are mapped by substring to fixed bodies, never forwarded.
          const m = (error.message ?? "").toLowerCase();
          if (m.includes("code_unavailable") || m.includes("already")) {
            // pairing:709-714 — revoke the token on the "already exists" path.
            await db
              .from("device_pairing_tokens")
              .update({ status: "revoked" })
              .eq("id", token.id)
              .eq("status", "active");
            await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: false });
            throw new ApiError(409, "code_unavailable", "This pairing code is no longer available.");
          }
          console.error(`rpc_create_pairing_request: ${error.code ?? "unknown"}`);
          throw new ApiError(500, "internal_error", "Could not create the pairing request.");
        }

        // INFERRED single-use consumption (14:172): mark the token redeemed, guarded so a
        // concurrent redeem cannot both win.
        await db
          .from("device_pairing_tokens")
          .update({ status: "redeemed", redeemed_at: new Date().toISOString(), redeemed_by: uid })
          .eq("id", token.id)
          .eq("status", "active");
        await recordPairingAttempt(db, { parentUserId: uid, codeHash: attemptHash, success: true });
        return ok({ request: data ?? null, status: "pending_child", expires_at: expiresAtRequest });
}
