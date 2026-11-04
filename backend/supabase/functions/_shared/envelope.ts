// ============================================================================
// _shared/envelope.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   Deployed text never read. capture-20261030.json:168 records 3517 chars / 112 lines,
//   sha256 cf4a6911..., note: "ApiError, ok/fail, errorResponse (logs error.name only,
//   generic 500), readJson (512 KB cap, object-only), requireAction, ensureNoError
//   (logs error.code only)". Behavioural detail is from
//   docs/stage1/14-edge-function-security-audit.md:209-228 (check 10), :269-283 (check 14),
//   and the "positive controls" table at 14:334-344.
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: none directly.  SECRETS USED: none.
//
// VERIFIED CONTRACT (14:211-219):
//   POST only, JSON object only, 512 KB cap enforced on BOTH the declared content-length
//   and the actual text, action length 1-64, Cache-Control: no-store on every JSON
//   response, errorResponse logs error.name only and returns a fixed 500 sentence,
//   ensureNoError logs error.code only.
//
// UNVERIFIED BEHAVIOUR (deliberate, disclosed deviations — see DEPLOYMENT-MAP.md):
//   - The success/error top-level KEY NAMES are NOT captured anywhere. This file uses
//     {ok:true, ...data} and {ok:false, error:{code,message}}. The error shape is
//     constrained by evidence: docs/stage1/15-edge-function-test-plan.md:20 and :222 both
//     instruct the tester to record `error.code` and `error.message`, so those two paths
//     are VERIFIED consumers. `ok` is NOT VERIFIED.
//   - 405 vs 400 for a non-POST request is not captured (14:211 says only "POST only").
//   - 413 vs 400 for an over-cap body is not captured. 413 is used here.
//   - The exact fixed 500 sentence is not captured; a neutral one is used.
// ============================================================================

import { corsHeaders } from "./cors.ts";

const MAX_BODY_CHARS = 512 * 1024; // 14:213-214 — "512 KB cap enforced on both the declared content-length and the actual text"
const MAX_ACTION_LEN = 64; // capture:168 / 14:219 — "action length 1-64"

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly extra: Record<string, unknown>;
  constructor(status: number, code: string, message: string, extra: Record<string, unknown> = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}

function jsonHeaders(): Record<string, string> {
  return { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" };
}

export function ok(data: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: true, ...data }), { status: 200, headers: jsonHeaders() });
}

export function fail(
  status: number,
  code: string,
  message: string,
  extra: Record<string, unknown> = {},
): Response {
  return new Response(JSON.stringify({ ok: false, error: { code, message, ...extra } }), {
    status,
    headers: jsonHeaders(),
  });
}

/**
 * errorResponse — top-level catch for every handler (14:271-274).
 * Curated ApiErrors pass through; anything else logs ONLY error.name (never message,
 * never stack, never a PostgREST object) and returns the same fixed 500 body.
 */
export function errorResponse(err: unknown): Response {
  if (err instanceof ApiError) return fail(err.status, err.code, err.message, err.extra);
  console.error(`edge_error: ${err instanceof Error ? err.name : "unknown"}`);
  return fail(500, "internal_error", "An unexpected error occurred.");
}

/** readJson — object-only body, double size gate (14:213, 14:342). */
export async function readJson(req: Request): Promise<Record<string, unknown>> {
  const declared = req.headers.get("content-length");
  if (declared !== null) {
    const n = Number(declared);
    if (Number.isFinite(n) && n > MAX_BODY_CHARS) {
      throw new ApiError(413, "payload_too_large", "Request body is too large.");
    }
  }
  const text = await req.text();
  if (text.length > MAX_BODY_CHARS) {
    throw new ApiError(413, "payload_too_large", "Request body is too large.");
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new ApiError(400, "invalid_json", "Body must be JSON.");
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new ApiError(400, "invalid_payload", "Body must be a JSON object.");
  }
  return parsed as Record<string, unknown>;
}

/** requireAction — reads and bounds `action` (14:219; guard name at docs/stage1/evidence/functions-and-triggers.md:80). */
export function requireAction(body: Record<string, unknown>): string {
  const a = body["action"];
  if (typeof a !== "string" || a.length < 1 || a.length > MAX_ACTION_LEN) {
    throw new ApiError(400, "invalid_action", "action must be a string of 1 to 64 characters.");
  }
  return a;
}

/** unknownAction — the 400 `unknown_action` used by all nine (15:137, 15:204). */
export function unknownAction(action: string): never {
  throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
}

/**
 * ensureNoError — PostgREST error gate. Logs ONLY error.code and throws a generic 500
 * with the caller-supplied sentence (14:275-276). Never forwards the database message.
 */
export function ensureNoError(
  err: { code?: string; message?: string } | null,
  fallbackMessage: string,
): void {
  if (!err) return;
  console.error(`db_error: ${err.code ?? "unknown"}`);
  throw new ApiError(500, "db_error", fallbackMessage);
}
