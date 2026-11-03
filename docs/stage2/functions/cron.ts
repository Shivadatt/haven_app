// ============================================================================
// Edge Function: cron                     TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// Production (parent-control-prod / hhqgreaoqulmfwfwarhc) is NOT a target of this file
// and was not contacted. Deployment is BLOCKED by unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:152-154: MINIFIED BUNDLE, 3791 chars / 2 lines, sha256 4cb4bd11..., no source maps.
//
// *** MODULE SET IS PRESERVED VERBATIM FROM THE CAPTURE — DO NOT "FIX" IT ***
//   capture:157  inlined_modules = ["cors","envelope"]
//   That is the FULL list. `cron` inlines NEITHER `auth`, NOR `audit`, NOR `validation`,
//   NOR `rate_limit`. This is not an oversight in the capture: the brief flagged it as
//   "a real finding you must not 'fix' silently by adding them without saying so", and
//   S2-A7 §S-1 records the accepted correction that cron's service-role usage is
//   **INFERRED, NOT VERIFIED**, precisely because capture:157 shows no `auth` module to
//   supply getServiceClient.
//   Consequences, all preserved in this file and all stated in DEPLOYMENT-MAP.md:
//     (a) the Supabase client is constructed INLINE here, because there is no auth module to
//         call. Whether the deployed bundle used the service-role key or the anon key cannot
//         be read from the evidence; the two RPCs it calls are maintenance RPCs, so a
//         service-role client is the only workable reading — INFERRED, not verified.
//     (b) SHA-256 and the constant-time comparison are hand-rolled below, because `validation`
//         is not inlined. In every other bundle those come from _shared/validation.ts.
//     (c) THERE IS NO AUDIT ROW FOR A CRON RUN. No `audit` module means nothing can write
//         audit_logs. A scheduled maintenance job that expires sessions and raises offline
//         alerts leaves no application-level trace. That is the captured state. Adding
//         recordAudit here would be a behaviour change requiring an A7-R decision, so it is
//         NOT added; it is listed as a gap and as one of the three weakest links in this
//         package.
//   This file deliberately does not import ./_shared/audit.ts, ./_shared/auth.ts or
//   ./_shared/validation.ts. If a later reader adds them, capture:157 parity is lost.
//
// CAPTURED FACTS USED (file:line):
//   capture:155 actions = expire_sessions, detect_offline
//   capture:156 auth_model = "shared secret in x-cron-secret; CRON_SECRET must be at least
//               16 chars or the function returns 503"
//   capture:159 CRON_SECRET length < 16 -> 503 cron_not_configured; compare = SHA-256 of both
//               sides then constant-time equal, case-insensitive hex; missing/empty header or
//               mismatch -> 401
//   capture:160 rpc expire_stale_sessions(); rpc detect_offline_devices()
//   14-edge-function-security-audit.md:319-326 (check 17, VERIFIED: refuses to run when
//     CRON_SECRET is missing or <16 chars; 401 on missing/mismatch; hashing both sides avoids
//     the length leak a naive === would have. Weaknesses E12: static secret, no timestamp, no
//     nonce, no IP or origin restriction, preflight answered for any origin)
//   14:264-267 — OPTIONS is answered 200 by EVERY function INCLUDING cron, before any
//     authentication (finding E9, preserved)
//   15-edge-function-test-plan.md:199-205 PE-CR01..CR07 (200 {expired_sessions: n},
//     200 {alerts_created: n}, 401 wrong secret, 401 missing header, 503 cron_not_configured
//     for a 15-char secret, 400 unknown_action, OPTIONS 200 with wildcard CORS)
//   docs/stage1/evidence/functions-and-triggers.md:40,42 expire_stale_sessions() -> integer,
//     detect_offline_devices() -> integer
//
// TABLES TOUCHED: none directly. Both writes happen inside private.expire_stale_sessions and
//   private.detect_offline_devices (both bodies are among the 24 unread implementations).
// RPCs CALLED: public.expire_stale_sessions, public.detect_offline_devices.
// SECRETS BY NAME: CRON_SECRET, SUPABASE_SERVICE_ROLE_KEY. No value is written anywhere.
//   CRON_SECRET is A9-BLOCKED and NOT CREATED; a value shorter than 16 characters makes this
//   function return 503 by design, which is the fail-closed behaviour, not a bug.
// AUTH MODEL: shared secret header ONLY. No user JWT is accepted and none is required — this
//   is the one function with no per-relationship authorisation, because it has no target: both
//   actions are global maintenance sweeps. Therefore "authorise inside the function" is
//   satisfied by the secret gate alone; nothing else can be authorised.
// IDEMPOTENCY: the two actions are maintenance RPCs returning integers; replay is harmless
//   (14:326 "Actions are idempotent maintenance RPCs, so replay has low impact"). No nonce or
//   timestamp is added — that is the E12 remediation and it is NOT APPLIED.
// RATE LIMITING: ABSENT (capture:157). Finding E12's replay exposure is preserved.
// AUDIT LOGGING: ABSENT — structurally, because no audit module is inlined. See (c) above.
// verify_jwt: NOT CAPTURED. If the gateway's verify_jwt were ON for this slug, an unauthenticated
//   scheduler call would fail at the gateway; the captured behaviour shows the function itself
//   doing the secret check, so verify_jwt is expected OFF. MUST be read from the dashboard.
//
// UNVERIFIED BEHAVIOUR (labelled, not invented):
//   - Which API key the deployed bundle authenticates its PostgREST calls with (anon vs
//     service-role) — INFERRED, see (a) above.
//   - Whether the header check trims whitespace or lowercases the header name beyond HTTP
//     normalisation. Not captured; no trimming is applied here.
//   - Whether `alerts_created` counts alerts created or devices scanned. PE-CR02 (15:200)
//     names the key only; the RPC returns an integer whose MEANING lives in the unread body.
//   - The 503/401 response bodies beyond the error codes.
// ============================================================================

import { handleCors, corsHeaders } from "./_shared/cors.ts";
import { ApiError, errorResponse, ok, readJson, requireAction, unknownAction } from "./_shared/envelope.ts";

// Deliberately NOT imported here: ./_shared/audit.ts, ./_shared/auth.ts,
// ./_shared/validation.ts, ./_shared/rate_limit.ts. See the header block, note (c).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"; // version NOT captured (no import map exists)

const MIN_CRON_SECRET_CHARS = 16; // capture:159 "CRON_SECRET length < 16 -> 503"

const encoder = new TextEncoder();

async function sha256HexLocal(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * constantTimeEqualHexLocal — hand-rolled because `validation` is NOT inlined in this
 * bundle (capture:157). Same algorithm and same guarantees as
 * _shared/validation.ts:constantTimeEqualHex: case-insensitive, no early byte-exit, and both
 * operands are 64-hex by construction so the length test leaks nothing (14:321-323).
 */
function constantTimeEqualHexLocal(a: string, b: string): boolean {
  const x = a.toLowerCase();
  const y = b.toLowerCase();
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x.charCodeAt(i) ^ y.charCodeAt(i);
  return diff === 0;
}

/**
 * assertCronAuthorized — capture:159, all three branches, in the captured order:
 *   1. configuration gate FIRST: a missing or <16-char CRON_SECRET is a 503, so a
 *      misconfigured deploy cannot be probed for "no secret set";
 *   2. missing or empty header -> 401;
 *   3. mismatch -> 401. Both sides are hashed, then compared in constant time.
 */
async function assertCronAuthorized(req: Request): Promise<void> {
  const configured = Deno.env.get("CRON_SECRET") ?? ""; // NAME only; the value is never logged
  if (configured.length < MIN_CRON_SECRET_CHARS) {
    throw new ApiError(503, "cron_not_configured", "Cron maintenance is not configured.");
  }
  const presented = req.headers.get("x-cron-secret");
  if (!presented || presented.length === 0) {
    throw new ApiError(401, "unauthorized", "Cron credential is required.");
  }
  const [configuredHash, presentedHash] = await Promise.all([sha256HexLocal(configured), sha256HexLocal(presented)]);
  if (!constantTimeEqualHexLocal(configuredHash, presentedHash)) {
    throw new ApiError(401, "unauthorized", "Cron credential is not valid.");
  }
}

/**
 * cronClient — INLINE client construction, because no auth module is inlined (capture:157).
 * Service-role use is INFERRED, not verified: the two maintenance RPCs write across every
 * family and the schema grants them to service_role, so no other credential can work. This is
 * the exact statement S2-A7 §S-1 accepted as a correction. persistSession/autoRefreshToken are
 * off, matching _shared/auth.ts:49-66.
 */
function cronClient(): ReturnType<typeof createClient> {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // NAME only, never returned or logged
  if (!url || !key) throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
  });
}

Deno.serve(async (req: Request) => {
  // 14:264-267 — preflight is answered 200 BEFORE any authentication. Preserved (finding E9).
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // The envelope is read before the secret gate so that an over-cap body is rejected as a
    // 413 rather than reaching the digest step. The gate runs before ANY database call.
    await assertCronAuthorized(req);

    const db = cronClient();

    if (action === "expire_sessions") {
      // capture:160 — rpc expire_stale_sessions(); RETURNS integer (functions-and-triggers.md:42)
      const { data, error } = await db.rpc("expire_stale_sessions");
      if (error) {
        console.error(`rpc_expire_stale_sessions: ${error.code ?? "unknown"}`); // code only, 14:275
        throw new ApiError(500, "internal_error", "Could not expire stale sessions.");
      }
      // PE-CR01 (15:199): 200 {expired_sessions: n}
      return ok({ expired_sessions: typeof data === "number" ? data : 0 });
    }

    if (action === "detect_offline") {
      // capture:160 — rpc detect_offline_devices(); RETURNS integer
      const { data, error } = await db.rpc("detect_offline_devices");
      if (error) {
        console.error(`rpc_detect_offline_devices: ${error.code ?? "unknown"}`);
        throw new ApiError(500, "internal_error", "Could not run the offline sweep.");
      }
      // PE-CR02 (15:200): 200 {alerts_created: n}. What n counts is inside the unread body.
      return ok({ alerts_created: typeof data === "number" ? data : 0 });
    }

    unknownAction(action); // PE-CR06 (15:204): a valid secret with a bad action is still 400
  } catch (err) {
    return errorResponse(err);
  }
});

// `corsHeaders` is referenced so the inlined CORS object stays visible to a reviewer checking
// that this bundle answers preflight with the wildcard (finding E9, preserved).
void corsHeaders;
