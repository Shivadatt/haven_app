// ============================================================================
// _shared/rate_limit.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   Deployed text never read. capture-20261030.json:169 records 7148 chars / 211 lines,
//   sha256 754502ef..., and gives the whole quota table verbatim:
//     "Pairing-only limits: 5 failed attempts per parent / 10 per identifier in 10 min,
//      5 live codes per 24 h, 10 creations per hour, 3 pending invites, 10 invites per
//      24 h. All counts are read-then-act."
//   Anchors: docs/stage1/14-edge-function-security-audit.md:168-171
//     (:54-93 redeem limits, :110-151 creation limits, :153-211 invite limits),
//   call sites pairing anchors 567 / 771-772 (capture:37-38), guard names from
//   docs/stage1/evidence/functions-and-triggers.md:80.
//   429 shape: 15-edge-function-test-plan.md:96, :100 — `rate_limited` plus
//   `retry_after_seconds`; PE-P03 (:90) and PE-P13 (:100).
//
// read-then-act IS the deployed weakness (finding E8): counts are SELECTed and then acted
// on with no lock, so parallel callers overshoot (CI-01, 15:211). PRESERVED, NOT FIXED —
// changing it is an A7-R decision, not an IMP-5 edit.
//
// STATELESSNESS CAVEAT (docs/stage2/parts/F-e6-e7.md): Edge isolates scale horizontally and
//   share no memory, so every limit here is a DATABASE count and the effective ceiling is
//   configured-limit x concurrent-instances under load. Nothing is cached in-process.
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: pairing_attempts (SELECT, INSERT), device_pairing_tokens (SELECT).
// SECRETS BY NAME: PAIRING_HASH_PEPPER — indirectly, because `attemptHash` is produced by
//   validation.identifierHash. This module never sees the pepper.
//
// UNVERIFIED BEHAVIOUR:
//   - Which actor the "live codes / creations per hour" windows are keyed on (the child
//     that mints them, per schema-columns.md:72 child_user_id) is INFERRED, not captured.
//   - The window arithmetic for retry_after_seconds is not captured; oldest-row + window
//     minus now is used, which is the only reading consistent with "rolling 10 minutes"
//     (14:168-169).
//   - Whether invite limits key on the TARGET child or the acting parent is not captured;
//     the child is used, matching "per child" at 14:171.
// ============================================================================

import { ApiError } from "./envelope.ts";

export const REDEEM_WINDOW_MINUTES = 10; // 14:168
export const MAX_FAILED_PER_PARENT_PER_WINDOW = 5; // capture:169
export const MAX_FAILED_PER_IDENTIFIER_PER_WINDOW = 10; // capture:169
export const MAX_LIVE_CODES_PER_24H = 5; // capture:169
export const MAX_CREATIONS_PER_HOUR = 10; // capture:169
export const MAX_PENDING_INVITES = 3; // capture:169
export const MAX_INVITES_PER_24H = 10; // capture:169

function minutesAgo(minutes: number, now: Date): string {
  return new Date(now.getTime() - minutes * 60_000).toISOString();
}

function retrySecondsFrom(oldestIso: string | null, windowMinutes: number, now: Date): number {
  if (!oldestIso) return windowMinutes * 60;
  const t = new Date(oldestIso).getTime();
  if (Number.isNaN(t)) return windowMinutes * 60;
  return Math.max(1, Math.ceil((t + windowMinutes * 60_000 - now.getTime()) / 1000));
}

async function countFailed(
  db: any,
  filters: Array<[string, string]>,
  since: string,
): Promise<{ n: number; oldest: string | null }> {
  let q = db
    .from("pairing_attempts")
    .select("attempted_at", { count: "exact", head: true })
    .eq("success", false)
    .gte("attempted_at", since);
  for (const [col, val] of filters) q = q.eq(col, val);
  const { count, error } = await q;
  if (error) {
    console.error(`rate_count: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  // Oldest surviving attempt, for retry_after_seconds.
  let oq = db
    .from("pairing_attempts")
    .select("attempted_at")
    .eq("success", false)
    .gte("attempted_at", since)
    .order("attempted_at", { ascending: true })
    .limit(1);
  for (const [col, val] of filters) oq = oq.eq(col, val);
  const { data: oldestRow } = await oq.maybeSingle();
  return { n: count ?? 0, oldest: oldestRow?.attempted_at ?? null };
}

/**
 * assertPairingRedeemAllowed — :54-93, called BEFORE the token lookup at pairing:567 so a
 * throttled caller cannot probe code validity at all.
 * `attemptHash` is validation.identifierHash(normalized) — the KEYED digest, deliberately
 * different from the token row's plain SHA-256 code_hash (pairing:562-566, finding E5).
 */
export async function assertPairingRedeemAllowed(
  db: any,
  parentUserId: string,
  attemptHash: string,
): Promise<void> {
  const now = new Date();
  const since = minutesAgo(REDEEM_WINDOW_MINUTES, now);

  const perParent = await countFailed(db, [["parent_user_id", parentUserId]], since);
  if (perParent.n >= MAX_FAILED_PER_PARENT_PER_WINDOW) {
    throw new ApiError(429, "rate_limited", "Too many attempts. Try again later.", {
      retry_after_seconds: retrySecondsFrom(perParent.oldest, REDEEM_WINDOW_MINUTES, now),
    });
  }

  const perIdentifier = await countFailed(db, [["code_hash", attemptHash]], since);
  if (perIdentifier.n >= MAX_FAILED_PER_IDENTIFIER_PER_WINDOW) {
    throw new ApiError(429, "rate_limited", "Too many attempts. Try again later.", {
      retry_after_seconds: retrySecondsFrom(perIdentifier.oldest, REDEEM_WINDOW_MINUTES, now),
    });
  }
}

/** recordPairingAttempt — pairing:771-772 and every redeem failure branch (14:169). */
export async function recordPairingAttempt(
  db: any,
  input: { parentUserId: string; codeHash: string; success: boolean },
): Promise<void> {
  const { error } = await db.from("pairing_attempts").insert({
    parent_user_id: input.parentUserId,
    code_hash: input.codeHash,
    attempted_at: new Date().toISOString(),
    success: input.success,
  });
  if (error) {
    console.error(`attempt_record: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
}

/**
 * assertPairingCodeCreationAllowed — :110-151.
 * "5 live codes per 24 h" = purpose 'code' rows still active/undecreed in the window;
 * "10 creations per hour" = every purpose 'code' row created in the hour, live or not,
 * so minting-and-expiring cannot bypass it.
 */
export async function assertPairingCodeCreationAllowed(
  db: any,
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
export async function assertInviteQuotaAllowed(db: any, childUserId: string): Promise<void> {
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
