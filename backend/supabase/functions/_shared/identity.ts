// ============================================================================
// _shared/identity.ts — the request-to-actor seam, split out of _shared/auth.ts
// at port time so no file exceeds the project's 200-line source rule.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. See
//   `_shared/envelope.ts` for what that label means, and `auth.ts` for the module this
//   block came from (captured `_shared/auth.ts:68-104`, 9920 chars / 338 lines).
//
// Nothing else in this package turns a request into a verified actor id, and nothing
// here reads an id from a request body. Splitting the file did not change that.
// ============================================================================

import { ApiError } from "./envelope.ts";
import type { DbClient } from "./db.ts";

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

/**
 * IdentityMode — named rather than `typeof IDENTITY_MODE`.
 *
 * CORRECTED AT PORT TIME: `mode: typeof IDENTITY_MODE` narrowed to the single initialised
 * literal, so `emailVerifiedFor`'s firebase-uid branch failed `deno check` as an
 * impossible comparison. The lane was authored without a type checker available; this is
 * the first time any of it has been checked.
 */
export type IdentityMode = "supabase-auth" | "firebase-uid";

export const IDENTITY_MODE: IdentityMode = "supabase-auth";

export interface Actor {
  /** Supabase profile id == auth.user.id under supabase-auth mode. */
  userId: string;
  role: string;
  email: string | null;
  /** Auth-user record as returned by the token verifier; shape differs per mode. */
  authUser: any;
  mode: IdentityMode;
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
export async function resolveIdentity(req: Request, db: DbClient): Promise<Actor> {
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
// The async signature is intentional (the A13-signed implementation is async and callers await it).
// deno-lint-ignore require-await
async function resolveFirebaseIdentity(_req: Request, _db: DbClient): Promise<Actor> {
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
