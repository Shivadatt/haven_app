// ============================================================================
// tests/pairing_limits_test.ts — the pairing throttle, quotas and digest rules.
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY (see envelope_test.ts for what a pass means).
// Offline shapes of PE-P03, PE-P08, PE-P13, CI-01 and the E5/E6 digest findings.
//
// WINDOW COUNTING IS NOT A CONCURRENCY CONTROL: these helpers count committed rows in a
// time window, so a burst can overshoot before any row is visible. That is finding E8 and
// is preserved here rather than fixed — see docs/stage1/16-phase-e-findings.md.
// ============================================================================

import { assertEquals, assertRejects, assertStringIncludes } from "@std/assert";

import { ApiError } from "../functions/_shared/envelope.ts";
import { identifierHash, sha256Hex } from "../functions/_shared/validation.ts";
import {
  MAX_FAILED_PER_IDENTIFIER_PER_WINDOW,
  MAX_FAILED_PER_PARENT_PER_WINDOW,
  MAX_INVITES_PER_24H,
  MAX_LIVE_CODES_PER_24H,
  MAX_PENDING_INVITES,
  assertPairingRedeemAllowed,
  minutesAgo,
  recordPairingAttempt,
  retrySecondsFrom,
} from "../functions/_shared/rate_limit.ts";
import { assertInviteQuotaAllowed, assertPairingCodeCreationAllowed } from "../functions/_shared/quotas.ts";
import { CODE_TTL_MINUTES, invalidIdentifier, ttl } from "../functions/pairing/shared.ts";
import { FakeClient } from "./stub_db.ts";

const PARENT = "11111111-1111-4111-8111-111111111111";
const CHILD = "22222222-2222-4222-8222-222222222222";
const HASH = "a".repeat(64);

/** countFailed() reads a `{count}` head then one oldest row, per filter set. */
function redeemStub(parentFailed: number, identifierFailed: number, oldest: string | null): FakeClient {
  return new FakeClient({
    "pairing_attempts.select": [
      { count: parentFailed, error: null },
      { data: oldest === null ? null : { attempted_at: oldest }, error: null },
      { count: identifierFailed, error: null },
      { data: oldest === null ? null : { attempted_at: oldest }, error: null },
    ],
  });
}

Deno.test("PE-P13 / CI-01 (15:100, 15:211): the parent window trips at 5 failed redeems", async () => {
  const now = new Date();
  const oldest = minutesAgo(9, now);
  assertEquals(MAX_FAILED_PER_PARENT_PER_WINDOW, 5);
  await assertPairingRedeemAllowed(redeemStub(4, 0, oldest) as never, PARENT, HASH); // one below: allowed
  const err = await assertRejects(() =>
    assertPairingRedeemAllowed(redeemStub(5, 0, oldest) as never, PARENT, HASH), ApiError);
  assertEquals(err.status, 429);
  assertEquals(err.code, "rate_limited");
  assertEquals(typeof (err as ApiError).extra.retry_after_seconds, "number");
  assertStringIncludes(err.message, "Too many attempts.");
});

Deno.test("the identifier window is the looser of the two, and is keyed on the digest (14:168)", async () => {
  assertEquals(MAX_FAILED_PER_IDENTIFIER_PER_WINDOW, 10);
  const now = new Date();
  const oldest = minutesAgo(3, now);
  // Four failures against this parent, ten against this identifier: the identifier wins.
  const err = await assertRejects(() =>
    assertPairingRedeemAllowed(redeemStub(4, 10, oldest) as never, PARENT, HASH), ApiError);
  assertEquals([err.status, err.code], [429, "rate_limited"]);
  const db = redeemStub(4, 9, oldest);
  await assertPairingRedeemAllowed(db as never, PARENT, HASH); // one below both caps -> allowed
  const hashed = db.calls.filter((c) => c.predicates.some((p) => p.startsWith("code_hash:")));
  assertStringIncludes(hashed.map((c) => c.predicates.join(",")).join(";"), `code_hash:eq:${HASH}`);
});

Deno.test("retry_seconds counts down from the oldest surviving attempt, never a constant", () => {
  const now = new Date("2026-11-04T12:00:00.000Z");
  assertEquals(retrySecondsFrom(new Date(now.getTime() - 60_000).toISOString(), 10, now), 9 * 60);
  assertEquals(retrySecondsFrom(null, 10, now), 600);
  assertEquals(retrySecondsFrom("not a date", 10, now), 600);
});

Deno.test("PE-P03 (15:90): code creation stops at 10 per hour and 5 live per 24 h", async () => {
  assertEquals(MAX_LIVE_CODES_PER_24H, 5); // capture:169 — five live codes per 24 h
  const hourly = new FakeClient({ "device_pairing_tokens.select": [{ count: 0 }, { count: 10 }, { count: 0 }] });
  const err = await assertRejects(() => assertPairingCodeCreationAllowed(hourly as never, CHILD), ApiError);
  assertEquals([err.status, err.code], [429, "rate_limited"]);

  const live = new FakeClient({ "device_pairing_tokens.select": [{ count: MAX_LIVE_CODES_PER_24H }, { count: 0 }] });
  assertEquals((await assertRejects(() => assertPairingCodeCreationAllowed(live as never, CHILD), ApiError)).message,
    "Too many pairing codes.");

  const fine = new FakeClient({ "device_pairing_tokens.select": [{ count: 1 }, { count: 1 }] });
  await assertPairingCodeCreationAllowed(fine as never, CHILD);
});

Deno.test("PE-P08 (15:95): invites stop at 3 pending and 10 per 24 h per child", async () => {
  assertEquals(MAX_PENDING_INVITES, 3);
  assertEquals(MAX_INVITES_PER_24H, 10);
  const pending = new FakeClient({ "device_pairing_tokens.select": [{ count: MAX_PENDING_INVITES }, { count: 0 }] });
  assertEquals((await assertRejects(() => assertInviteQuotaAllowed(pending as never, CHILD), ApiError)).code, "rate_limited");
  const perDay = new FakeClient({ "device_pairing_tokens.select": [{ count: 0 }, { count: MAX_INVITES_PER_24H }] });
  assertEquals((await assertRejects(() => assertInviteQuotaAllowed(perDay as never, CHILD), ApiError)).code, "rate_limited");
  const fine = new FakeClient({ "device_pairing_tokens.select": [{ count: 2 }, { count: 9 }] });
  await assertInviteQuotaAllowed(fine as never, CHILD);
});

Deno.test("recordPairingAttempt writes exactly the four evidenced columns (14:169)", async () => {
  const db = new FakeClient({ "pairing_attempts.insert": { error: null } });
  await recordPairingAttempt(db as never, { parentUserId: PARENT, codeHash: HASH, success: false });
  const row = db.last()?.payload as Record<string, unknown>;
  assertEquals(Object.keys(row).sort(), ["attempted_at", "code_hash", "parent_user_id", "success"]);
  assertEquals(row.parent_user_id, PARENT); // the JWT subject, never a body field (TE-15)
  assertEquals(row.success, false);
});

Deno.test("E5 PRESERVED: the attempt digest is keyed, the token digest is plain SHA-256", async () => {
  const code = "PAIRING1";
  const plain = await sha256Hex(code);
  const keyed = await identifierHash(code, "pepper");
  assertEquals(keyed, "ba69d641e93252c1e163c32eb30097136061f94137e2b7ec8c2b8d5ff4626b64");
  assertEquals(keyed === plain, false); // two different digests for one code — finding E5
  assertEquals(/^[0-9a-f]{64}$/.test(keyed), true);
});

Deno.test("E6 PRESERVED: with no pepper the keyed digest silently degrades to SHA-256", async () => {
  // PAIRING_HASH_PEPPER is a secret NAME only. If the runner's environment really has it,
  // this test is skipped rather than faked, because the fallback branch cannot be observed.
  if (Deno.env.get("PAIRING_HASH_PEPPER") !== undefined) return;
  const code = "PAIRING1";
  assertEquals(await identifierHash(code), await sha256Hex(code));
});

Deno.test("PE-P04 / PE-P06 (15:91-93): one uniform 400 body, so failure reasons are not oracles", () => {
  const err = assertInvalid();
  assertEquals([err.status, err.code, err.message], [400, "invalid_code", "Pairing identifier is not valid."]);
});

function assertInvalid(): ApiError {
  try {
    invalidIdentifier();
    throw new Error("unreachable");
  } catch (e) {
    return e as ApiError;
  }
}

Deno.test("ttl() and CODE_TTL_MINUTES agree with the captured 10-minute window (capture:35)", () => {
  assertEquals(CODE_TTL_MINUTES, 10);
  const minutes = (new Date(ttl(CODE_TTL_MINUTES)).getTime() - Date.now()) / 60_000;
  assertEquals(minutes > 9.9 && minutes <= 10.1, true);
});
