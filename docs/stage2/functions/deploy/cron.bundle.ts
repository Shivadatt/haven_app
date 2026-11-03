// ============================================================================
// BROWSER-DEPLOYABLE BUNDLE — Edge Function `cron`
// TARGET: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (STAGING ONLY).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is NOT a target and is not
//   referenced as one anywhere in this file. Nothing here has been deployed: A7-R / A8-R are
//   UNSIGNED, and staging currently has 0 Edge Functions and 0 secrets.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION with the captured bundle
//   (3791 chars / 2 lines, sha256 4cb4bd11..., capture-20261030.json:152-154). Required
//   A7-R Option 2 label; may not be dropped in later documents.
//   digest not computed for this bundle (terminal prohibited).
//
// FULL EVIDENCE BLOCK, TABLE/RPC/SECRET INVENTORY AND THE UNVERIFIED-BEHAVIOUR LIST ARE IN
//   ../cron.ts (same slug). This header carries only what a paste operator must see.
//
// INLINED MODULES — EXACTLY THE CAPTURED SET, NOTHING MORE:
//   capture:157 inlined_modules = ["cors","envelope"]. Both are inlined below in
//   RE-AUTHORED form. `auth`, `audit`, `validation` and `rate_limit` are NOT inlined here and
//   MUST NOT be added: their absence is the finding (S2-A7 §S-1 accepted correction —
//   service-role use is INFERRED not VERIFIED; E13-equivalent gap: a cron run writes NO audit
//   row). Consequences of that absence are implemented inline instead:
//     - sha256Hex + constant-time compare are hand-rolled (validation is unavailable);
//     - the Supabase client is constructed inline (auth is unavailable) — INFERRED service-role;
//     - there is no audit write at all (audit is unavailable).
// SECRETS BY NAME: CRON_SECRET, SUPABASE_SERVICE_ROLE_KEY. No secret VALUE appears in this file.
// GAPS THAT CANNOT BE CLOSED BY THIS FILE: whether the gateway's verify_jwt is on for this
//   slug (not captured anywhere), and what detect_offline_devices' integer actually counts
//   (private body unread, one of the 24).
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"; // version NOT captured — no import map exists in the repository

// ---------------------------------------------------------------------------
// INLINED: _shared/cors.ts (RE-AUTHORED — capture:167, 490 chars / 13 lines, never read)
// Wildcard origin + credential-bearing allow-headers is finding E9, preserved deliberately.
// ---------------------------------------------------------------------------

const CORS_ALLOW_HEADERS =
  "authorization, x-client-info, apikey, content-type, x-device-id, x-device-secret, x-cron-secret";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": CORS_ALLOW_HEADERS,
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ ok: false, error: { code: "method_not_allowed", message: "POST only." } }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" } },
    );
  }
  return null;
}

// ---------------------------------------------------------------------------
// INLINED: _shared/envelope.ts (RE-AUTHORED — capture:168, 3517 chars / 112 lines, never read)
// ---------------------------------------------------------------------------

const MAX_BODY_CHARS = 512 * 1024;
const MAX_ACTION_LEN = 64;

class ApiError extends Error {
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

function ok(data: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: true, ...data }), { status: 200, headers: jsonHeaders() });
}

function fail(status: number, code: string, message: string, extra: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: false, error: { code, message, ...extra } }), {
    status,
    headers: jsonHeaders(),
  });
}

function errorResponse(err: unknown): Response {
  if (err instanceof ApiError) return fail(err.status, err.code, err.message, err.extra);
  console.error(`edge_error: ${err instanceof Error ? err.name : "unknown"}`); // logs error.name ONLY
  return fail(500, "internal_error", "An unexpected error occurred.");
}

async function readJson(req: Request): Promise<Record<string, unknown>> {
  const declared = req.headers.get("content-length");
  if (declared !== null) {
    const n = Number(declared);
    if (Number.isFinite(n) && n > MAX_BODY_CHARS) {
      throw new ApiError(413, "payload_too_large", "Request body is too large.");
    }
  }
  const text = await req.text();
  if (text.length > MAX_BODY_CHARS) throw new ApiError(413, "payload_too_large", "Request body is too large.");
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

function requireAction(body: Record<string, unknown>): string {
  const a = body["action"];
  if (typeof a !== "string" || a.length < 1 || a.length > MAX_ACTION_LEN) {
    throw new ApiError(400, "invalid_action", "action must be a string of 1 to 64 characters.");
  }
  return a;
}

function unknownAction(action: string): never {
  throw new ApiError(400, "unknown_action", `Unknown action: ${action}`);
}

// ---------------------------------------------------------------------------
// HANDLER — re-authored from ../cron.ts. Same gate order, same codes.
// ---------------------------------------------------------------------------

const MIN_CRON_SECRET_CHARS = 16; // capture:159

const cronEncoder = new TextEncoder();

async function sha256HexLocal(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", cronEncoder.encode(value));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

function constantTimeEqualHexLocal(a: string, b: string): boolean {
  const x = a.toLowerCase();
  const y = b.toLowerCase();
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x.charCodeAt(i) ^ y.charCodeAt(i);
  return diff === 0;
}

async function assertCronAuthorized(req: Request): Promise<void> {
  const configured = Deno.env.get("CRON_SECRET") ?? ""; // NAME only; value never logged
  if (configured.length < MIN_CRON_SECRET_CHARS) {
    throw new ApiError(503, "cron_not_configured", "Cron maintenance is not configured.");
  }
  const presented = req.headers.get("x-cron-secret");
  if (!presented || presented.length === 0) {
    throw new ApiError(401, "unauthorized", "Cron credential is required.");
  }
  const [configuredHash, presentedHash] = await Promise.all([
    sha256HexLocal(configured),
    sha256HexLocal(presented),
  ]);
  if (!constantTimeEqualHexLocal(configuredHash, presentedHash)) {
    throw new ApiError(401, "unauthorized", "Cron credential is not valid.");
  }
}

function cronClient(): ReturnType<typeof createClient> {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // INFERRED service-role; see bundle header
  if (!url || !key) throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
  });
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req); // preflight answered 200 before any authentication (E9, preserved)
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);
    await assertCronAuthorized(req);
    const db = cronClient();

    if (action === "expire_sessions") {
      const { data, error } = await db.rpc("expire_stale_sessions");
      if (error) {
        console.error(`rpc_expire_stale_sessions: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not expire stale sessions.");
      }
      return ok({ expired_sessions: typeof data === "number" ? data : 0 });
    }

    if (action === "detect_offline") {
      const { data, error } = await db.rpc("detect_offline_devices");
      if (error) {
        console.error(`rpc_detect_offline_devices: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not run the offline sweep.");
      }
      return ok({ alerts_created: typeof data === "number" ? data : 0 });
    }

    unknownAction(action);
  } catch (err) {
    return errorResponse(err);
  }
});
