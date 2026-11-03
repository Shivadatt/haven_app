// ============================================================================
// _shared/cors.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   The text of the deployed _shared/cors.ts was never read. capture-20261030.json:167
//   records it as 490 chars / 13 lines, sha256 33ec5b77..., with the note
//   "Access-Control-Allow-Origin: * and an allow-headers list that includes
//    authorization, x-device-secret and x-cron-secret". Everything below is derived
//   from that note plus docs/stage1/14-edge-function-security-audit.md:259-267 (check 13),
//   which is the only place the full header list is transcribed:
//     "authorization, x-client-info, apikey, content-type, x-device-id, x-device-secret, x-cron-secret"
//   and "Preflight (OPTIONS) is answered 200 by every function, including cron,
//    before any authentication."
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
//   Production parent-control-prod / hhqgreaoqulmfwfwarhc is not referenced by this file
//   and is not a deployment target of this package.
//
// TABLES TOUCHED: none.  SECRETS USED: none.
//
// KNOWN WEAKNESS, PRESERVED DELIBERATELY (finding E9, docs/stage1/16-phase-e-findings.md):
//   wildcard origin + credential-bearing allow-headers. Kept because removing it would be
//   a behaviour change outside IMP-5 authority; see DEPLOYMENT-MAP.md "deviations".
//
// UNVERIFIED BEHAVIOUR:
//   - Access-Control-Allow-Methods value is not captured; "POST, OPTIONS" chosen from
//     the POST-only envelope contract (14:219). Not observed in deployed source.
//   - Whether a max-age is set on preflight is not captured; none is set here.
// ============================================================================

/// <reference types="https://esm.sh/@types/deno@2.1.3/index.d.ts" />

export const CORS_ALLOW_HEADERS =
  "authorization, x-client-info, apikey, content-type, x-device-id, x-device-secret, x-cron-secret";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": CORS_ALLOW_HEADERS,
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/**
 * handleCors — run FIRST in every handler, before any authentication.
 * OPTIONS -> 200 with CORS headers and no body (VERIFIED behaviour of all nine bundles,
 * 14:264-267). Non-POST -> 405. Returning null means "continue".
 */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ ok: false, error: { code: "method_not_allowed", message: "POST only." } }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" },
      },
    );
  }
  return null;
}
