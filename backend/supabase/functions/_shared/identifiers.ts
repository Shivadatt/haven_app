// ============================================================================
// _shared/identifiers.ts — CSPRNG codes, Child IDs and package names, split out of
// `_shared/validation.ts` at port time for the project's 200-line source rule.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//
// THE 30-SYMBOL ALPHABET IS RECOVERED, NOT INVENTED.
//   The Edge source never captured it, but the DATABASE did:
//   docs/stage2/migrations/A3-staging-load-v1.sql:437 (from g1-q5, kind=c) emits
//     child_contact_ids_contact_id_check CHECK (contact_id ~ '^PC[23456789ABCDEFGHJKMNPQRSTVWXYZ]{8}$')
//   That class is exactly 30 symbols, matching "8 characters from a 30-symbol alphabet" and
//   "30^8 = 6.6e11" at audit 14:166-167. So the Child ID format is VERIFIED FROM DDL and the
//   pairing code alphabet is taken from it (INFERRED that the same alphabet serves both).
//   Anchors: 14:166-167, 15:88, 14:172 (routing by format so neither path is an oracle).
//
// PACKAGE_NAME_RE is a documented PLACEHOLDER — the deployed regex is NOT captured.
// ============================================================================

import { bad } from "./readers.ts";

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
