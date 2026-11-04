// ============================================================================
// _shared/quotas.ts — minting and invite quotas, split out of `_shared/rate_limit.ts`
// at port time for the project's 200-line source rule. Behaviour unchanged.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   Captured anchors: `_shared/rate_limit.ts:110-151` (creation) and `:153-211` (invites),
//   audit 14:171-175, capture:169 for the seven limits.
//
// These are the ONLY quotas in the product. Finding E7 records that 8 of the 9 slugs have
// no rate limiting at all; that is preserved, not silently extended — a quota invented here
// would reject real parent traffic the deployed system accepts.
// ============================================================================

import { ApiError } from "./envelope.ts";
import type { DbClient } from "./db.ts";
import {
  MAX_INVITES_PER_24H,
  MAX_LIVE_CODES_PER_24H,
  MAX_CREATIONS_PER_HOUR,
  MAX_PENDING_INVITES,
  minutesAgo,
  retrySecondsFrom,
} from "./rate_limit.ts";

/**
 * assertPairingCodeCreationAllowed — :110-151.
 * "5 live codes per 24 h" = purpose 'code' rows still active/undecreed in the window;
 * "10 creations per hour" = every purpose 'code' row created in the hour, live or not,
 * so minting-and-expiring cannot bypass it.
 */
export async function assertPairingCodeCreationAllowed(
  db: DbClient,
  childUserId: string,
): Promise<void> {
  const now = new Date();
  const { count: live, error: e1 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "code")
    .eq("status", "active")
    .gte("created_at", minutesAgo(24 * 60, now));
  if (e1) {
    console.error(`rate_count: ${e1.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((live ?? 0) >= MAX_LIVE_CODES_PER_24H) {
    throw new ApiError(429, "rate_limited", "Too many pairing codes.", {
      retry_after_seconds: 60 * 60,
    });
  }

  const { count: recent, error: e2 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "code")
    .gte("created_at", minutesAgo(60, now));
  if (e2) {
    console.error(`rate_count: ${e2.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((recent ?? 0) >= MAX_CREATIONS_PER_HOUR) {
    throw new ApiError(429, "rate_limited", "Too many pairing codes.", {
      retry_after_seconds: 60 * 60,
    });
  }
}

/**
 * assertInviteQuotaAllowed — :153-211. "at most 3 pending and 10 per 24 h per child".
 * Pending invite = device_pairing_tokens purpose 'invite' still 'active'
 * (status vocabulary VERIFIED from A3-staging-load-v1.sql:451 — active|redeemed|revoked|expired).
 */
export async function assertInviteQuotaAllowed(db: DbClient, childUserId: string): Promise<void> {
  const now = new Date();
  const { count: pending, error: e1 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "invite")
    .eq("status", "active")
    .gt("expires_at", now.toISOString());
  if (e1) {
    console.error(`rate_count: ${e1.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((pending ?? 0) >= MAX_PENDING_INVITES) {
    throw new ApiError(429, "rate_limited", "Too many pending invites.", {
      retry_after_seconds: 60 * 60,
    });
  }

  const { count: perDay, error: e2 } = await db
    .from("device_pairing_tokens")
    .select("id", { count: "exact", head: true })
    .eq("child_user_id", childUserId)
    .eq("purpose", "invite")
    .gte("created_at", minutesAgo(24 * 60, now));
  if (e2) {
    console.error(`rate_count: ${e2.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if ((perDay ?? 0) >= MAX_INVITES_PER_24H) {
    throw new ApiError(429, "rate_limited", "Too many invites.", {
      retry_after_seconds: retrySecondsFrom(
        (await db
          .from("device_pairing_tokens")
          .select("created_at")
          .eq("child_user_id", childUserId)
          .eq("purpose", "invite")
          .gte("created_at", minutesAgo(24 * 60, now))
          .order("created_at", { ascending: true })
          .limit(1)
          .maybeSingle())
          .data?.created_at ?? null,
        24 * 60,
        now,
      ),
    });
  }
}
