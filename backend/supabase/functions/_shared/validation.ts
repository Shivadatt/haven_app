// ============================================================================
// _shared/validation.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   Deployed text never read. capture-20261030.json:170 records 12640 chars / 419 lines,
//   sha256 3b817683..., note: "Regexes, typed readers, CSPRNG pairing code / Child ID,
//   sha256Hex, identifierHash (HMAC with PAIRING_HASH_PEPPER, silent fallback to SHA-256),
//   constant-time helpers."
//   Anchors used: 14-edge-function-security-audit.md:220-228 (check 10), :337
//   ("constant-time secret comparison ... _shared/validation.ts:355-375"),
//   docs/stage1/16-phase-e-findings.md:229-240 (E5, `validation.ts:325-357` for
//   identifierHash) and :270-273 (E6, warn-once `pairing_hash_pepper_missing`),
//   docs/stage2/parts/F-e6-e7.md (identifierHash signature and fallback wording).
//
// THE 30-SYMBOL ALPHABET IS RECOVERED, NOT INVENTED.
//   The Edge source never captured it, but the DATABASE did:
//   docs/stage2/migrations/A3-staging-load-v1.sql:437 (from g1-q5, kind=c) emits
//     child_contact_ids_contact_id_check CHECK (contact_id ~ '^PC[23456789ABCDEFGHJKMNPQRSTVWXYZ]{8}$')
//   The class [23456789 A-Z minus I,L,O,U] is exactly 30 symbols — matching the
//   "8 characters from a 30-symbol alphabet" and "30^8 = 6.6e11" statements at
//   14:166-167 and 16:247. So the Child ID format is VERIFIED FROM DDL and the pairing
//   code alphabet is taken from it (INFERRED that the same alphabet serves both).
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: none (pure functions).
// SECRETS USED BY NAME: PAIRING_HASH_PEPPER (optional; silent SHA-256 fallback = finding E6).
//
// UNVERIFIED BEHAVIOUR:
//   - Exact per-reader error messages are not captured. All readers throw
//     ApiError(400,"validation_error", ...) with a plain sentence; the four messages that
//     ARE evidenced verbatim ("<key> is not allowed", "policy is too large",
//     "cannot be in the future", "older than seven days", "too far in the future" —
//     15:144,146,157,162,163 and 14:223) are preserved exactly.
//   - The Android package-name regex is NOT captured. 14:224 only says "package regex";
//     the DB gives length 1..150 (A3:...:439, :493). PACKAGE_NAME_RE below is a
//     conventional Java FQN pattern and is a documented PLACEHOLDER, not evidence.
//   - Line-number map of the deployed module (which helper lives where) is not captured.
// ============================================================================

// SPLIT AT PORT TIME (2026-11-04) for the project's 200-line source rule. The typed
// readers moved to `readers.ts` and the CSPRNG identifier / package-name helpers to
// `identifiers.ts`; both are re-exported at the bottom, so every handler's
// `from "../_shared/validation.ts"` import still resolves. No behaviour changed.
// ============================================================================

import { bad } from "./readers.ts";


// ---------- dates / timestamps (14:226-227) ---------------------------------

/** A real calendar date, not just a parseable string. Rejects 2026-02-30 style input. */
export function isRealDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [y, m, d] = value.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}

export function parseTimestamp(value: string, key: string): Date {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) bad(`${key} must be an ISO-8601 timestamp.`);
  return d;
}

// ---------- digests ---------------------------------------------------------

const encoder = new TextEncoder();

function toHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");
}

export async function sha256Hex(value: string): Promise<string> {
  return toHex(await crypto.subtle.digest("SHA-256", encoder.encode(value)));
}

async function hmacSha256Hex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return toHex(await crypto.subtle.sign("HMAC", key, encoder.encode(value)));
}

let pepperWarned = false; // "warns once per isolate (pairing_hash_pepper_missing)" — 16:270-272, parts/F-e6-e7.md

/**
 * identifierHash — keyed digest used for pairing_attempts.code_hash (capture:170,
 * 16:229-240). Falls back SILENTLY (after one warning) to plain SHA-256 when
 * PAIRING_HASH_PEPPER is unset. That fallback is finding E6 and is preserved verbatim
 * because removing it would break every deployment that has no pepper set; the secret is
 * A9-BLOCKED and NOT CREATED.
 *   Secret referenced by NAME ONLY: PAIRING_HASH_PEPPER.
 */
export function identifierHash(
  value: string,
  pepper?: string,
): Promise<string> {
  const p = pepper ?? Deno.env.get("PAIRING_HASH_PEPPER") ?? "";
  if (p.length === 0) {
    if (!pepperWarned) {
      pepperWarned = true;
      console.warn("pairing_hash_pepper_missing");
    }
    return sha256Hex(value);
  }
  return hmacSha256Hex(p, value);
}

/**
 * constantTimeEqualHex — length-constant-time comparison over case-insensitive hex
 * (14:337 "validation.ts:355-375"; 14:321-323 for the cron use). Both operands are 64-hex
 * by construction, so the early length test leaks nothing the caller does not already know.
 */
export function constantTimeEqualHex(a: string, b: string): boolean {
  const x = a.toLowerCase();
  const y = b.toLowerCase();
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x.charCodeAt(i) ^ y.charCodeAt(i);
  return diff === 0;
}


export {
  assertAllowedKeys,
  bad,
  clampInt,
  readArray,
  readBoolean,
  readEnum,
  readHex64,
  readInt,
  readNumber,
  readObject,
  readOptionalEnum,
  readOptionalString,
  readOptionalUuid,
  readString,
  readUuid,
} from "./readers.ts";
export {
  CONTACT_ID_PREFIX,
  CONTACT_ID_RE,
  IDENTIFIER_ALPHABET,
  IDENTIFIER_LENGTH,
  isContactIdForm,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  PACKAGE_NAME_RE,
  PAIRING_CODE_RE,
  randomIdentifier,
  readPackageName,
} from "./identifiers.ts";
