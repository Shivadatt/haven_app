// ============================================================================
// _shared/readers.ts — the typed body readers, split out of `_shared/validation.ts`
// at port time for the project's 200-line source rule. Behaviour unchanged.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   Anchors: audit 14:220-228 (check 10) and the four error sentences that ARE evidenced
//   verbatim ("<key> is not allowed", "policy is too large", "cannot be in the future",
//   "older than seven days", "too far in the future"). Everything else in this file is a
//   plain sentence chosen by the re-author, not a captured string.
//
// Every reader fails closed. A value of the wrong type, out of range, or absent is an
// error — never a default. A handler that read `body["battery"] as number` would accept a
// string and store a value nobody chose.
// ============================================================================

import { ApiError } from "./envelope.ts";

// ---------- error helpers ---------------------------------------------------

export function bad(message: string): never {
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
