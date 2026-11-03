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

import { ApiError } from "./envelope.ts";

// ---------- error helpers ---------------------------------------------------

function bad(message: string): never {
  throw new ApiError(400, "validation_error", message);
}

// ---------- typed readers (14:220-221) --------------------------------------

export function readString(
  body: Record<string, unknown>,
  key: string,
  bounds: { min?: number; max?: number } = {},
): string {
  const v = body[key];
  if (typeof v !== "string") bad(`${key} must be a string.`);
  const min = bounds.min ?? 1;
  const max = bounds.max ?? 4096;
  if (v.length < min || v.length > max) bad(`${key} must be ${min} to ${max} characters.`);
  return v;
}

export function readOptionalString(
  body: Record<string, unknown>,
  key: string,
  bounds: { min?: number; max?: number } = {},
): string | null {
  if (body[key] === undefined || body[key] === null) return null;
  return readString(body, key, bounds);
}

export function readBoolean(body: Record<string, unknown>, key: string, fallback: boolean): boolean;
export function readBoolean(body: Record<string, unknown>, key: string): boolean | null;
export function readBoolean(
  body: Record<string, unknown>,
  key: string,
  fallback?: boolean,
): boolean | null {
  const v = body[key];
  if (v === undefined || v === null) return fallback === undefined ? null : fallback;
  if (typeof v !== "boolean") bad(`${key} must be a boolean.`);
  return v;
}

export function readInt(
  body: Record<string, unknown>,
  key: string,
  bounds: { min: number; max: number },
  fallback?: number,
): number {
  const v = body[key];
  if (v === undefined || v === null) {
    if (fallback !== undefined) return fallback;
    bad(`${key} is required.`);
  }
  if (typeof v !== "number" || !Number.isInteger(v)) bad(`${key} must be an integer.`);
  if (v < bounds.min || v > bounds.max) bad(`${key} must be between ${bounds.min} and ${bounds.max}.`);
  return v;
}

export function readNumber(
  body: Record<string, unknown>,
  key: string,
  bounds: { min: number; max: number },
  fallback?: number,
): number {
  const v = body[key];
  if (v === undefined || v === null) {
    if (fallback !== undefined) return fallback;
    bad(`${key} is required.`);
  }
  if (typeof v !== "number" || !Number.isFinite(v)) bad(`${key} must be a number.`);
  if (v < bounds.min || v > bounds.max) bad(`${key} must be between ${bounds.min} and ${bounds.max}.`);
  return v;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HEX64_RE = /^[0-9a-f]{64}$/; // VERIFIED from DDL: A3:...:448, :465, :476 all use '^[0-9a-f]{64}$'

export function readUuid(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 36, max: 36 });
  if (!UUID_RE.test(v)) bad(`${key} must be a UUID.`);
  return v.toLowerCase();
}

export function readOptionalUuid(body: Record<string, unknown>, key: string): string | null {
  if (body[key] === undefined || body[key] === null) return null;
  return readUuid(body, key);
}

export function readHex64(body: Record<string, unknown>, key: string): string {
  const v = readString(body, key, { min: 64, max: 64 });
  if (!HEX64_RE.test(v)) bad(`${key} must be 64 hexadecimal characters.`);
  return v.toLowerCase();
}

export function readEnum<S extends string>(
  body: Record<string, unknown>,
  key: string,
  values: readonly S[],
): S {
  const v = readString(body, key, { min: 1, max: 128 });
  if (!values.includes(v as S)) bad(`${key} must be one of: ${values.join(", ")}.`);
  return v as S;
}

export function readOptionalEnum<S extends string>(
  body: Record<string, unknown>,
  key: string,
  values: readonly S[],
): S | null {
  if (body[key] === undefined || body[key] === null) return null;
  return readEnum(body, key, values);
}

export function readArray(
  body: Record<string, unknown>,
  key: string,
  bounds: { max: number; min?: number },
): unknown[] {
  const v = body[key];
  if (!Array.isArray(v)) bad(`${key} must be an array.`);
  const min = bounds.min ?? 0;
  if (v.length < min) bad(`${key} must contain at least ${min} items.`);
  if (v.length > bounds.max) bad(`${key} must contain at most ${bounds.max} items.`); // 14:223-225 count caps
  return v;
}

export function readObject(
  body: Record<string, unknown>,
  key: string,
  maxJsonChars: number,
): Record<string, unknown> {
  const v = body[key];
  if (v === null || typeof v !== "object" || Array.isArray(v)) bad(`${key} must be a JSON object.`);
  const size = JSON.stringify(v).length;
  if (size > maxJsonChars) bad(`${key} is too large`); // 15:146 -> "policy is too large"
  return v as Record<string, unknown>;
}

/**
 * assertAllowedKeys — the strict allowlist control (14:221-223: "policy objects reject
 * unknown keys (`policy.<key> is not allowed`)"). Message shape VERIFIED at 15:144.
 */
export function assertAllowedKeys(
  obj: Record<string, unknown>,
  allowed: readonly string[],
  path: string,
): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.includes(k)) bad(`${path}.${k} is not allowed`);
  }
}

export function clampInt(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

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
export async function identifierHash(
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

// ---------- CSPRNG identifiers (14:166-167, 15:88) --------------------------

/** 30 symbols, recovered from the child_contact_ids CHECK constraint (see header). */
export const IDENTIFIER_ALPHABET = "23456789ABCDEFGHJKMNPQRSTVWXYZ";
export const IDENTIFIER_LENGTH = 8;
export const CONTACT_ID_PREFIX = "PC";

/**
 * Rejection sampling over a 30-symbol alphabet: 256 % 30 = 16, so bytes >= 240 are
 * discarded. This is the uniform-generation method the audit describes
 * ("crypto.getRandomValues and rejection sampling", 14:166-167).
 */
export function randomIdentifier(length: number = IDENTIFIER_LENGTH): string {
  const out: string[] = [];
  const buf = new Uint8Array(64);
  while (out.length < length) {
    crypto.getRandomValues(buf);
    for (let i = 0; i < buf.length && out.length < length; i++) {
      const b = buf[i];
      if (b < 240) out.push(IDENTIFIER_ALPHABET[b % IDENTIFIER_ALPHABET.length]);
    }
  }
  return out.join("");
}

export function newPairingCode(): string {
  return randomIdentifier();
}

export function newContactId(): string {
  return CONTACT_ID_PREFIX + randomIdentifier();
}

export const CONTACT_ID_RE = new RegExp(`^${CONTACT_ID_PREFIX}[${IDENTIFIER_ALPHABET}]{8}$`);

/**
 * A bare pairing code: 8 symbols from the same 30-symbol alphabet, WITHOUT the `PC`
 * prefix. Derived from 14:166-167 ("8 characters from a 30-symbol alphabet") plus the
 * DATABASE-verified alphabet; the prefix-free form itself is INFERRED.
 */
export const PAIRING_CODE_RE = new RegExp(`^[${IDENTIFIER_ALPHABET}]{8}$`);

/**
 * normalizeIdentifier — uppercase and strip spaces before hashing, so the digest is
 * stable across paste variants. VERIFIED ONLY AS A NEED: pairing/index.ts:565-566 hashes
 * `normalized` (16:229-237). The exact normalisation rule is NOT captured.
 */
export function normalizeIdentifier(value: string): string {
  return value.toUpperCase().replace(/[\s-]/g, "");
}

/**
 * isContactIdForm — the format-based routing that keeps the code path and the Child ID
 * path from being oracles for each other (14:335 "pairing/index.ts:555-560").
 * The routing KEY (a `PC` prefix) is INFERRED from the DB contact-id CHECK constraint.
 */
export function isContactIdForm(normalized: string): boolean {
  return normalized.startsWith(CONTACT_ID_PREFIX);
}

// ---------- package names ---------------------------------------------------

/** PLACEHOLDER — the deployed regex is NOT captured. Length bound 1..150 IS captured
 *  (A3:...:439). Do not treat this as parity with the bundle. */
export const PACKAGE_NAME_RE = /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$/;

export function readPackageName(value: unknown, key: string): string {
  if (typeof value !== "string") bad(`${key} must be a string.`);
  if (value.length < 1 || value.length > 150) bad(`${key} must be 1 to 150 characters.`);
  if (!PACKAGE_NAME_RE.test(value)) bad(`${key} must be a package name.`);
  return value;
}
