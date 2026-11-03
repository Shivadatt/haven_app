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

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"; // version NOT captured
import { ApiError } from "./envelope.ts";
import { constantTimeEqualHex, sha256Hex } from "./validation.ts";

// ---------------------------------------------------------------------------
// IDENTITY SEAM — A13 IS UNSIGNED. ONE EDIT AT CUTOVER.
// ---------------------------------------------------------------------------
// This constant, and the two branches of `resolveIdentity` / `emailVerifiedFor` below,
// are the ONLY place in the whole package that turns a request into a verified actor id.
//
//   "supabase-auth"  — DEFAULT, and the only mode this package can honestly support today.
//                      It is the evidenced behaviour: db.auth.getUser(token)
//                      (14:62-64, _shared/auth.ts:92) and `email_confirmed_at` on the
//                      Auth user object (capture:50 "user JWT + verified email").
//   "firebase-uid"   — the ratified target (owner selection recorded in
//                      docs/stage2/S2-EXEC-08-identity-decision-A13-final.md §1: Firebase as
//                      an EXTERNAL JWT ISSUER verified by Supabase Third-Party Auth, with
//                      `sub` resolved to a Supabase profile ONLY through mapping store M-B,
//                      S2-A1-auth-architecture.md:503). Instrument A13 is
//                      **UNSIGNED — DECIDED, INSTRUMENT PREPARED, FENCE UNSIGNED**, the
//                      staging Third-Party Auth provider list is empty
//                      (S2-EXEC-06 §3), M-B does not exist yet, and there is no evidenced
//                      action that provisions a profile from a Firebase identity
//                      (S2-EXEC-08 §2(4)). So this branch FAILS CLOSED by design.
//
// Cutover is one edit: flip IDENTITY_MODE, and replace the body of the single function
// `resolveFirebaseIdentity` with real verification once A13 is signed AND M-B exists.
// No other file in this package reads an actor id. A client-supplied UID is never
// authoritative and never establishes parent-child ownership in either mode.
// ---------------------------------------------------------------------------

export const IDENTITY_MODE: "supabase-auth" | "firebase-uid" = "supabase-auth";

export interface Actor {
  /** Supabase profile id == auth.user.id under supabase-auth mode. */
  userId: string;
  role: string;
  email: string | null;
  /** Auth-user record as returned by the token verifier; shape differs per mode. */
  authUser: any;
  mode: typeof IDENTITY_MODE;
}

let cachedClient: ReturnType<typeof createClient> | null = null;

/** getServiceClient — capture:166 vocabulary; 14:248-252. Missing key -> 503. */
export function getServiceClient(): ReturnType<typeof createClient> {
  if (cachedClient) return cachedClient;
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // NAME only; value never logged, never returned
  if (!url || !serviceKey) {
    throw new ApiError(503, "server_misconfigured", "Server is not configured.");
  }
  cachedClient = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "X-Client-Info": "parentcontrol-edge/1" } },
  });
  return cachedClient;
}

/** bearerToken — _shared/auth.ts:68-75. Regex and minimum length are VERIFIED anchors. */
export function bearerToken(req: Request): string {
  const raw = req.headers.get("authorization") ?? "";
  const m = /^Bearer\s+(\S+)$/i.exec(raw);
  if (!m) throw new ApiError(401, "unauthorized", "Missing bearer token.");
  if (m[1].length < 20) throw new ApiError(401, "unauthorized", "Invalid token.");
  return m[1];
}

/**
 * resolveIdentity — THE SEAM. Returns a verified actor or throws 401/403.
 * Never reads a user id from the body; never accepts a client-supplied uid.
 */
async function resolveIdentity(req: Request, db: any): Promise<Actor> {
  if (IDENTITY_MODE === "firebase-uid") {
    return await resolveFirebaseIdentity(req, db);
  }
  const token = bearerToken(req);
  let res: { data: { user: any } | null; error: any };
  try {
    res = await db.auth.getUser(token); // :92 — server-side verification, not local decoding
  } catch {
    throw new ApiError(401, "unauthorized", "Token could not be verified."); // :93-104 fail closed
  }
  const user = res.data?.user ?? null;
  if (res.error || !user || typeof user.id !== "string") {
    throw new ApiError(401, "unauthorized", "Token could not be verified.");
  }
  const { data: profile, error: perr } = await db
    .from("profiles")
    .select("id, role, display_name, created_at, updated_at")
    .eq("id", user.id)
    .maybeSingle();
  if (perr) {
    console.error(`profile_lookup: ${perr.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!profile) throw new ApiError(403, "profile_missing", "No profile for this account.");
  // :123-127 — an unknown role value is rejected outright, never treated as a default.
  if (profile.role !== "parent" && profile.role !== "child" && profile.role !== "unset") {
    throw new ApiError(403, "forbidden", "Unknown role.");
  }
  return {
    userId: user.id,
    role: profile.role as string,
    email: (user.email as string | null) ?? null,
    authUser: user,
    mode: "supabase-auth",
  };
}

/**
 * resolveFirebaseIdentity — THE FIREBASE-UID ASSUMPTION, ISOLATED HERE AND ONLY HERE.
 * Deliberately non-functional until A13 is signed. It does NOT stub success: it fails
 * closed with 503 so that flipping IDENTITY_MODE early cannot open a path.
 * What a real implementation must do (from S2-EXEC-08 §3-§4, not from any captured source):
 *   1. verify the ID token signature against the Third-Party Auth issuer
 *      https://securetoken.google.com/haven-staging-46822 / audience haven-staging-46822;
 *   2. take `sub` (the Firebase UID) and resolve it through mapping store M-B
 *      ((provider, firebase_uid) UNIQUE -> supabase_user_id, S2-A1:503);
 *   3. refuse when no M-B row exists, and refuse when the M-B row is revoked, EVEN IF the
 *      token is valid and unexpired ("revocation ... at the mapping row, not only at the
 *      token", A13 §TOKEN LIFECYCLE OBLIGATIONS);
 *   4. load the Supabase profile by the mapped id, exactly as the branch above does.
 */
async function resolveFirebaseIdentity(_req: Request, _db: any): Promise<Actor> {
  throw new ApiError(
    503,
    "identity_mode_unsigned",
    "Firebase-uid identity is not approved (A13 unsigned); use IDENTITY_MODE 'supabase-auth'.",
  );
}

/**
 * emailVerifiedFor — THE SECOND HALF OF THE SEAM (requireVerifiedEmail).
 * Both readings exist; exactly one is active, chosen by IDENTITY_MODE, so the cutover does
 * not need a search for scattered checks. Necessity recorded at
 * S2-EXEC-08 §2(3): under a Firebase-issued token `email_confirmed_at` is never set, so
 * the Supabase reading would make requireVerifiedEmail unsatisfiable.
 */
export function emailVerifiedFor(actor: Actor): boolean {
  if (actor.mode === "firebase-uid") {
    return actor.authUser?.email_verified === true; // Firebase claim; UNREACHABLE while A13 is unsigned
  }
  return !!actor.authUser?.email_confirmed_at; // evidenced: capture:50, auth-bootstrap anchor :38
}

/**
 * requireUser — the one entry point handlers call. Pass `verifyEmail: true` to compose
 * requireVerifiedEmail, matching the captured call form `requireUser(requireVerifiedEmail)`
 * (capture:53, auth-bootstrap index anchor :38).
 */
export async function requireUser(
  req: Request,
  opts: { verifyEmail?: boolean } = {},
): Promise<{ auth: Actor; db: any; profile: { role: string } }> {
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

// ---------------------------------------------------------------------------
// Family assertions — :151-196. Each first asserts the family exists and is not
// soft-deleted (14:129-131), then the membership row.
// ---------------------------------------------------------------------------

const FAMILIES_SELECT = "id, name, owner_id, settings, created_at, updated_at, deleted_at";
const MEMBERS_SELECT = "id, family_id, user_id, role, status, created_at, removed_at";

async function loadLiveFamily(db: any, familyId: string): Promise<any> {
  const { data: family, error } = await db
    .from("families")
    .select(FAMILIES_SELECT)
    .eq("id", familyId)
    .maybeSingle();
  if (error) {
    console.error(`family_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!family || family.deleted_at !== null) {
    throw new ApiError(403, "forbidden", "Family not available.");
  }
  return family;
}

async function loadActiveMembership(db: any, familyId: string, userId: string): Promise<any> {
  const { data: member, error } = await db
    .from("family_members")
    .select(MEMBERS_SELECT)
    .eq("family_id", familyId)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();
  if (error) {
    console.error(`membership_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  return member;
}

/** assertFamilyParent — active member AND role 'parent' in THAT family (14:132-133). */
export async function assertFamilyParent(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "parent") {
    throw new ApiError(403, "forbidden", "Not a parent of this family.");
  }
  return family;
}

/** assertFamilyMember — any active member (parent or child). */
export async function assertFamilyMember(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member) throw new ApiError(403, "forbidden", "Not a member of this family.");
  return { family, member };
}

/** assertFamilyChild / assertChildMembership — active member with role 'child'. */
export async function assertFamilyChild(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "child") {
    throw new ApiError(403, "forbidden", "Not a child of this family.");
  }
  return family;
}

export const assertChildMembership = assertFamilyChild;

/** assertFamilyOwner — families.owner_id; the code used as 403 owner_required. */
export async function assertFamilyOwner(db: any, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  if (family.owner_id !== userId) {
    throw new ApiError(403, "owner_required", "This action requires the family owner.");
  }
  return family;
}

// ---------------------------------------------------------------------------
// Device authority
// ---------------------------------------------------------------------------

const DEVICES_SELECT =
  "id, family_id, child_user_id, installation_id, display_name, platform, android_version, app_version, status, secret_hash, credential_issued_at, credential_revoked_at, last_seen_at, battery_level, is_charging, enforcement_mode, policy_version, usage_access_granted, location_granted, background_location_granted, camera_granted, microphone_granted, notifications_granted, created_at, updated_at";

/**
 * requireActiveDeviceForParent — :266-289. family_id is ALWAYS taken from the device row,
 * never from the body (14:134-135), then parent membership in THAT family is asserted.
 */
export async function requireActiveDeviceForParent(
  db: any,
  userId: string,
  deviceId: string,
): Promise<any> {
  const { data: device, error } = await db
    .from("devices")
    .select(DEVICES_SELECT)
    .eq("id", deviceId)
    .maybeSingle();
  if (error) {
    console.error(`device_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!device) throw new ApiError(403, "forbidden", "Device not available.");
  if (device.status !== "active") {
    throw new ApiError(403, "forbidden", "Device is not active.");
  }
  await assertFamilyParent(db, userId, device.family_id);
  return device;
}

/**
 * requireDevice — :295-338. The device credential channel.
 *   x-device-id (UUID) + x-device-secret (16..512 chars)
 *   secret is hashed with SHA-256 and compared to devices.secret_hash with the
 *   length-constant-time helper; a missing row or missing hash still performs a comparison
 *   against an all-zero digest so unknown ids and wrong secrets cost the same (:325-330).
 *   REVOCATION IS HONOURED: status != 'active' OR credential_revoked_at IS NOT NULL -> 401.
 *   No lockout exists on this path (finding E7); that is preserved, not silently "fixed".
 */
export async function requireDevice(req: Request, db: any): Promise<any> {
  const deviceId = req.headers.get("x-device-id");
  const secret = req.headers.get("x-device-secret");
  if (!deviceId || !secret) {
    throw new ApiError(401, "device_auth_required", "Device credentials are required.");
  }
  const id = deviceId.trim().toLowerCase();
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id);
  if (!isUuid || secret.length < 16 || secret.length > 512) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }

  const { data: device, error } = await db
    .from("devices")
    .select(DEVICES_SELECT)
    .eq("id", id)
    .maybeSingle();
  if (error) {
    console.error(`device_auth_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }

  const storedHash: string | null = device?.secret_hash ?? null;
  const presentedHash = await sha256Hex(secret);
  // :325-330 decoy comparison — same cost whether or not the row exists.
  const matches = await constantTimeEqualHex(presentedHash, storedHash ?? "0".repeat(64));

  if (!device || storedHash === null || !matches) {
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  if (device.status !== "active" || device.credential_revoked_at !== null) {
    // Revoked credential. Code name reuses the evidenced 401 rather than inventing one.
    throw new ApiError(401, "invalid_device_credentials", "Device credentials are not valid.");
  }
  return device;
}
