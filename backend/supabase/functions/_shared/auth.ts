// ============================================================================
// _shared/auth.ts  (IMP-5, stage 2)
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   The largest unread module in the package: 9920 chars / 338 lines, sha256 34b46f5a...
//   (capture-20261030.json:166). Its exported vocabulary is recorded verbatim there:
//   "getServiceClient (service role), bearerToken, requireUser (db.auth.getUser),
//    requireRole, assertFamilyMember/Parent/Child/Owner, requireActiveDeviceForParent,
//    requireDevice (sha256 + constant-time)".
//   Every line-number anchor below is from docs/stage1/14-edge-function-security-audit.md
//   and is the ONLY surviving structure of the deployed file:
//     :51-56   missing service key -> 503 server_misconfigured
//     :49-66   client construction (persistSession:false, autoRefreshToken:false)
//     :68-75   bearerToken — /^Bearer\s+(\S+)$/i, minimum length 20
//     :92      db.auth.getUser(token)  — signature/expiry/revocation decided by the Auth server
//     :93-104  network failure -> 401 unauthorized (fails closed)
//     :123-127 unknown role value rejected; missing profile -> 403 profile_missing
//     :139-149 requireRole — exact compare, so 'unset' fails closed
//     :151-196 family assertions — family must exist and not be soft-deleted
//     :266-289 requireActiveDeviceForParent
//     :295-338 requireDevice — UUID id, 16..512-char secret, SHA-256, length-constant-time
//     :325-330 zero-digest decoy comparison so unknown ids and wrong secrets cost the same
//
// WHY THIS MODULE IS THE TRUST BOUNDARY:
//   Every function here runs with the service-role key, so RLS does not apply to any query
//   (14:245-246, "the single most important architectural fact in this audit"; staging
//   confirms rls_enabled 19/19 but rls_forced 0/19). A missing predicate is therefore not
//   caught by the database. Nothing in this module may be relaxed.
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: profiles, families, family_members, devices (SELECT).
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY (plus SUPABASE_URL, a public project URL).
//   No secret VALUE appears in this file or in any file of this package.
//
// UNVERIFIED BEHAVIOUR:
//   - The Deno.env KEY NAMES are not captured. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
//     are the Supabase Edge conventions; confirm both in the dashboard Secrets tab before
//     deploying. A wrong name degrades to 503 server_misconfigured, never to open access.
//   - @supabase/supabase-js version pin is not captured (no import map and no
//     supabase/functions/ directory exist in the repository —
//     docs/stage1/13-edge-function-source-inventory.md §1, capture:176). "@2" is a
//     PLACEHOLDER.
//   - 403 profile_missing code is evidenced only narratively (14:80-81).
//   - The exact status/code returned for a REVOKED device credential (as opposed to a wrong
//     secret) is not captured; this re-authoring reuses the evidenced 401
//     invalid_device_credentials rather than inventing a new code.
// ============================================================================

// SPLIT AT PORT TIME (2026-11-04). This module is the captured `_shared/auth.ts`, whose
// 338 lines of behaviour do not fit the project's 200-line source rule in one file. The
// identity seam moved to `identity.ts`, the family assertions to `family.ts` and the two
// device paths to `device_authority.ts`; each is re-exported below so every handler's
// `from "../_shared/auth.ts"` import still resolves. No behaviour changed in the move.
// ============================================================================

import { createClient } from "@supabase/supabase-js"; // version NOT captured
import { ApiError } from "./envelope.ts";
import {
  bearerToken,
  emailVerifiedFor,
  IDENTITY_MODE,
  resolveIdentity,
  type Actor,
  type IdentityMode,
} from "./identity.ts";

export type { Actor, IdentityMode };
export { bearerToken, emailVerifiedFor, IDENTITY_MODE };
export {
  assertChildMembership,
  assertFamilyChild,
  assertFamilyMember,
  assertFamilyOwner,
  assertFamilyParent,
} from "./family.ts";
export { requireActiveDeviceForParent, requireDevice } from "./device_authority.ts";

// The seam type lives in its own module so the shared loaders, quotas and rate limiter can
// import it without an import cycle through this file. See _shared/db.ts for why it is
// hand-typed and where the permissive `any` values are deliberately confined.
export type { DbClient } from "./db.ts";
import type { DbClient } from "./db.ts";

let cachedClient: DbClient | null = null;

/** getServiceClient — capture:166 vocabulary; 14:248-252. Missing key -> 503. */
export function getServiceClient(): DbClient {
  if (cachedClient) return cachedClient;
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // NAME only; value never logged, never returned
  if (!url || !serviceKey) {
    throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  }
  const client: DbClient = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
  });
  cachedClient = client;
  return client;
}

/** bearerToken — _shared/auth.ts:68-75. Regex and minimum length are VERIFIED anchors. */

/**
 * requireUser — the one entry point handlers call. Pass `verifyEmail: true` to compose
 * requireVerifiedEmail, matching the captured call form `requireUser(requireVerifiedEmail)`
 * (capture:53, auth-bootstrap index anchor :38).
 */
export async function requireUser(
  req: Request,
  opts: { verifyEmail?: boolean } = {},
): Promise<{ auth: Actor; db: DbClient; profile: { role: string } }> {
  const db = getServiceClient();
  const actor = await resolveIdentity(req, db);
  if (opts.verifyEmail && !emailVerifiedFor(actor)) {
    throw new ApiError(403, "email_not_verified", "Confirm your email address first.");
  }
  return { auth: actor, db, profile: { role: actor.role } };
}

/** requireRole — :139-149, exact compare. `unset` and any mismatch -> 403 role_required. */
export function requireRole(profile: { role: string }, role: "parent" | "child"): void {
  if (profile.role !== role) {
    throw new ApiError(403, "role_required", `This action requires the ${role} role.`);
  }
}
