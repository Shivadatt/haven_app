// pairing / shared — the constants, column whitelists and two helpers all nine actions use.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Moved verbatim out of
// `index.ts` at port time for the project's 200-line source rule; values and anchors unchanged.
// The full captured-facts header stays in `index.ts` — read it before editing this file.
// ============================================================================

import { ApiError } from "../_shared/envelope.ts";

export const CODE_TTL_MINUTES = 10; // capture:35 — "41: CODE_TTL_MINUTES = 10"
export const INVITE_TTL_MINUTES = 24 * 60; // capture:35 — "43: INVITE_TTL_MINUTES = 24 * 60"
export const MAX_ATTEMPTS_PER_CODE = 10; // matches device_pairing_tokens.max_attempts DEFAULT 10 (A3-staging-load-v1.sql:202) — the only captured value for this field
export const PENDING_LIST_LIMIT = 50; // INFERRED from 16:192 (sibling endpoint), not captured for pairing

export const TOKEN_COLUMNS =
  "id, child_user_id, code_hash, expires_at, redeemed_at, redeemed_by, status, attempts, max_attempts, created_at, created_by, purpose";
export const REQUEST_COLUMNS =
  "id, token_id, family_id, parent_user_id, child_user_id, status, created_at, expires_at, responded_at";

/**
 * The uniform refusal. pairing:571,583,598,625,773 all return the same body for unknown /
 * expired / malformed / over-attempt identifiers (14:164-165, 14:334). Never differentiate
 * these branches: any variance is an enumeration oracle.
 */
export function invalidIdentifier(): never {
  // 15:89-93 maps this body to 400 `invalid_code` for both an unknown and an expired code.
  throw new ApiError(400, "invalid_code", "Pairing identifier is not valid.");
}

export function ttl(minutes: number): string {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}
