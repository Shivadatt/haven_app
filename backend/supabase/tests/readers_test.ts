// ============================================================================
// tests/readers_test.ts — the input gate shared by all seven functions
// (_shared/readers.ts, _shared/validation.ts, _shared/identifiers.ts).
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY — see envelope_test.ts for what a pass means and
// does not mean. Row ids below are docs/stage1/15-edge-function-test-plan.md cases whose
// DECISION is reproduced offline; none of those rows is thereby executed.
//
// WHY THIS FILE MATTERS MORE THAN IT LOOKS: the functions run with the service-role key,
// so RLS does not apply to any query (14:245-246). The readers are the only place a bad
// value can be stopped before it reaches a table.
// ============================================================================

import { assertEquals } from "@std/assert";

import { ApiError } from "../functions/_shared/envelope.ts";
import {
  CONTACT_ID_RE,
  IDENTIFIER_ALPHABET,
  PACKAGE_NAME_RE,
  PAIRING_CODE_RE,
  assertAllowedKeys,
  clampInt,
  constantTimeEqualHex,
  isContactIdForm,
  isRealDate,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  parseTimestamp,
  readArray,
  readBoolean,
  readEnum,
  readHex64,
  readInt,
  readObject,
  readOptionalString,
  readPackageName,
  readString,
  readUuid,
  sha256Hex,
} from "../functions/_shared/validation.ts";

function code(fn: () => unknown): string | null {
  try {
    fn();
    return null;
  } catch (e) {
    return e instanceof ApiError ? `${e.status} ${e.code}` : "non-api-error";
  }
}

Deno.test("readString - bounds and the 400 shape (14:220)", () => {
  assertEquals(readString({ name: "Kitchen" }, "name", { max: 60 }), "Kitchen");
  assertEquals(code(() => readString({ name: 3 }, "name", {})), "400 validation_error");
  assertEquals(code(() => readString({ name: "" }, "name", { min: 1 })), "400 validation_error");
  assertEquals(readOptionalString({}, "reason"), null);
});

Deno.test("readBoolean - the two overloads differ on absence (readers.ts:48-59)", () => {
  assertEquals(readBoolean({ on: true }, "on", false), true);
  assertEquals(readBoolean({}, "on", false), false); // fallback form never returns null
  assertEquals(readBoolean({}, "on"), null); // no fallback => nullable
  assertEquals(code(() => readBoolean({ on: "true" }, "on", false)), "400 validation_error");
});

Deno.test("readUuid - 36 chars and canonical form, lower-cased (audit check 5)", () => {
  const id = "11111111-1111-4111-8111-111111111111".toUpperCase();
  assertEquals(readUuid({ device_id: id }, "device_id"), id.toLowerCase());
  assertEquals(code(() => readUuid({ device_id: "not-a-uuid" }, "device_id")), "400 validation_error");
});

Deno.test("readHex64 - PE-R06 (15:136): secret_hash \"abc\" is rejected, 64 hex is not", () => {
  assertEquals(code(() => readHex64({ secret_hash: "abc" }, "secret_hash")), "400 validation_error");
  assertEquals(readHex64({ h: "ab".repeat(32) }, "h"), "ab".repeat(32));
  assertEquals(code(() => readHex64({ h: `${"a".repeat(63)}z` }, "h")), "400 validation_error");
  // OBSERVED, NOT EVIDENCED: the pattern is the DDL check `^[0-9a-f]{64}$` (A3:...:448),
  // which is lower-case-only, so an upper-case digest is refused even though this helper
  // ends in `.toLowerCase()`. That trailing call is unreachable for accepted input. Left
  // as authored rather than relaxed: a client's sha256Hex output is always lower case.
  assertEquals(code(() => readHex64({ h: "A".repeat(64) }, "h")), "400 validation_error");
});

Deno.test("readEnum - PE-C09 / PE-A06 / PE-S09: unknown vocabulary value is a 400", () => {
  assertEquals(readEnum({ kind: "audio" }, "kind", ["audio", "video"]), "audio");
  assertEquals(code(() => readEnum({ kind: "screen" }, "kind", ["audio", "video"])), "400 validation_error");
  assertEquals(code(() => readEnum({ role: "admin" }, "role", ["parent", "child"])), "400 validation_error");
});

Deno.test("readInt - PE-T02 (15:156): battery 101 fails the 0..100 gate, 100 passes", () => {
  const bounds = { min: 0, max: 100 };
  assertEquals(code(() => readInt({ battery_level: 101 }, "battery_level", bounds)), "400 validation_error");
  assertEquals(code(() => readInt({ battery_level: -1 }, "battery_level", bounds)), "400 validation_error");
  assertEquals(code(() => readInt({ battery_level: 50.5 }, "battery_level", bounds)), "400 validation_error");
  assertEquals(readInt({ battery_level: 100 }, "battery_level", bounds), 100);
});

Deno.test("readArray - PE-T09 (15:163) and PE-PL03 (15:145): 501 items rejected at a cap of 500", () => {
  assertEquals(code(() => readArray({ apps: new Array(501) }, "apps", { max: 500 })), "400 validation_error");
  assertEquals(readArray({ apps: new Array(500) }, "apps", { max: 500 }).length, 500);
  assertEquals(code(() => readArray({ rules: [] }, "app_rules", { max: 100, min: 1 })), "400 validation_error");
});

Deno.test("readObject - PE-PL04 (15:146): the message is exactly \"policy is too large\"", () => {
  const big: Record<string, unknown> = { pad: "x".repeat(256 * 1024) };
  assertEquals(code(() => readObject({ policy: big }, "policy", 256 * 1024)), "400 validation_error");
  try {
    readObject({ policy: big }, "policy", 256 * 1024);
  } catch (e) {
    assertEquals((e as ApiError).message, "policy is too large"); // VERIFIED string, 15:146
  }
  assertEquals(code(() => readObject({ policy: [] }, "policy", 1024)), "400 validation_error");
});

Deno.test("assertAllowedKeys - PE-PL02 (15:144): the message is exactly \"policy.<key> is not allowed\"", () => {
  try {
    assertAllowedKeys({ bedtime: {}, screens: {} }, ["bedtime"], "policy");
    throw new Error("should not reach");
  } catch (e) {
    assertEquals((e as ApiError).message, "policy.screens is not allowed");
  }
  assertEquals(code(() => assertAllowedKeys({ bedtime: {} }, ["bedtime"], "policy")), null);
});

Deno.test("clampInt - PE-C03 (15:119): ttl_seconds 10 is clamped up to the 60 floor", () => {
  assertEquals(clampInt(10, 60, 3600), 60);
  assertEquals(clampInt(99999, 60, 3600), 3600);
  assertEquals(clampInt(Number.NaN, 60, 3600), 60);
});

Deno.test("isRealDate / parseTimestamp - calendar dates, not merely parseable strings", () => {
  assertEquals(isRealDate("2026-02-30"), false);
  assertEquals(isRealDate("2026-02-28"), true);
  assertEquals(isRealDate("2026-1-5"), false);
  assertEquals(code(() => parseTimestamp("yesterday", "recorded_at")), "400 validation_error");
});

Deno.test("identifiers - PE-P01 (15:88): contact id is PC + 8 alphabet symbols", () => {
  assertEquals(IDENTIFIER_ALPHABET.length, 30); // 14:166 "30-symbol alphabet"
  for (let i = 0; i < 200; i++) {
    assertEquals(CONTACT_ID_RE.test(newContactId()), true);
    assertEquals(PAIRING_CODE_RE.test(newPairingCode()), true);
  }
  for (const banned of ["0", "O", "1", "I", "L"]) {
    assertEquals(IDENTIFIER_ALPHABET.includes(banned), false); // no ambiguous glyphs
  }
  assertEquals(isContactIdForm(normalizeIdentifier("pc hjk23456")), true);
  assertEquals(isContactIdForm(normalizeIdentifier("hjk23456")), false);
});

Deno.test("normalizeIdentifier - paste variants reach the same digest input", () => {
  assertEquals(normalizeIdentifier(" pc-hjk 23456 "), "PCHJK23456");
});

Deno.test("PACKAGE_NAME_RE - documented PLACEHOLDER: rejects a bare segment, accepts an FQN", () => {
  assertEquals(PACKAGE_NAME_RE.test("com.example.app"), true);
  assertEquals(PACKAGE_NAME_RE.test("example"), false);
  assertEquals(code(() => readPackageName("1bad.name", "package_name")), "400 validation_error");
});

Deno.test("sha256Hex - the FIPS vector, so digest-based lookups are testable at all", async () => {
  assertEquals(
    await sha256Hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});

Deno.test("constantTimeEqualHex - case-insensitive, and length mismatch is still false", () => {
  const a = "ab".repeat(32);
  assertEquals(constantTimeEqualHex(a, a.toUpperCase()), true);
  assertEquals(constantTimeEqualHex(a, "cd".repeat(32)), false);
  assertEquals(constantTimeEqualHex(a, "ab".repeat(31)), false);
});
