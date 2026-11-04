// ============================================================================
// tests/auth_roles_test.ts — the trust boundary: token -> actor -> role.
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY (see envelope_test.ts for what a pass means).
// These are the offline shapes of docs/stage1/15 rows TE-05, TE-06, TE-07, TE-08, TE-09,
// TE-12, TE-13 and TE-15; the HTTP rows themselves stay NOT EXECUTED.
//
// WHY THIS IS THE ONE PLACE TO LOOK: 14:245-246 records that these functions run with the
// service-role key, so RLS is not applied to any of their queries. `resolveIdentity` and
// `requireRole` are therefore not a convenience — they are the control.
// ============================================================================

import { assertEquals, assertRejects, assertThrows } from "@std/assert";

import { ApiError, errorResponse } from "../functions/_shared/envelope.ts";
import { IDENTITY_MODE, emailVerifiedFor, resolveIdentity } from "../functions/_shared/identity.ts";
import { requireRole, getServiceClient } from "../functions/_shared/auth.ts";
import { FakeClient } from "./stub_db.ts";

const UID = "11111111-1111-4111-8111-111111111111";
const TOKEN = "eyJhbGciOiAidGVzdC1vbi1seCJ9.payload.signature"; // 20+ chars; never a real JWT

function requestWith(headers: Record<string, string>): Request {
  return new Request("http://localhost/functions/v1/pairing", { method: "POST", headers, body: "{}" });
}

Deno.test("IDENTITY_MODE is supabase-auth while A13 is unsigned (fail-closed by design)", () => {
  // This assertion is the fence. Flipping the constant in _shared/identity.ts without
  // signing A13 and creating mapping store M-B must fail here, not open a path.
  assertEquals(IDENTITY_MODE, "supabase-auth");
});

Deno.test("TE-07 (15:64): no Authorization header -> 401 unauthorized, before any table read", async () => {
  const db = new FakeClient({ "profiles.select": { data: { role: "parent" } } });
  const err = await assertRejects(() => resolveIdentity(requestWith({ apikey: "anon" }), db as never));
  assertEquals((err as ApiError).status, 401);
  assertEquals((err as ApiError).code, "unauthorized");
  assertEquals(db.ops(), []); // nothing was queried at all
});

Deno.test("TE-08 (15:65): malformed schemes and a 1-character token are both 401", async () => {
  const db = new FakeClient({});
  for (const authorization of ["Bearer x", "Basic " + TOKEN, TOKEN, "Bearer", ""]) {
    const err = await assertRejects(() =>
      resolveIdentity(requestWith({ authorization }), db as never));
    assertEquals((err as ApiError).status, 401, `accepted ${JSON.stringify(authorization)}`);
  }
  assertEquals(db.ops(), []);
});

Deno.test("TE-09 (15:66): the Auth server rejecting the token fails closed, locally decoded never", async () => {
  // An expired or foreign-signed token is `res.error` / `data.user === null` here. The
  // handler never decodes the JWT itself (14:92), so a forged signature cannot pass.
  const rejected = new FakeClient({ "auth.getUser": { data: null, error: { message: "invalid signature" } } });
  const err = await assertRejects(() => resolveIdentity(requestWith({ authorization: `Bearer ${TOKEN}` }), rejected as never), ApiError);
  assertEquals(err.status, 401);
  const body = JSON.stringify(await errorResponse(err).json());
  assertEquals(body.includes("invalid signature"), false); // the Auth message is never forwarded

  const noUser = new FakeClient({ "auth.getUser": { data: null, error: null } });
  const err2 = await assertRejects(() =>
    resolveIdentity(requestWith({ authorization: `Bearer ${TOKEN}` }), noUser as never), ApiError);
  assertEquals(err2.status, 401);
});

Deno.test("profile_missing and an unknown role value are 403, never a default role (14:123-127)", async () => {
  const missing = new FakeClient({
    "auth.getUser": { data: { id: UID } },
    "profiles.select": { data: null },
  });
  const err = await assertRejects(() => resolveIdentity(requestWith({ authorization: `Bearer ${TOKEN}` }), missing as never));
  assertEquals([(err as ApiError).status, (err as ApiError).code], [403, "profile_missing"]);

  const weird = new FakeClient({
    "auth.getUser": { data: { id: UID } },
    "profiles.select": { data: { id: UID, role: "superuser" } },
  });
  const err2 = await assertRejects(() => resolveIdentity(requestWith({ authorization: `Bearer ${TOKEN}` }), weird as never), ApiError);
  assertEquals([err2.status, err2.code], [403, "forbidden"]);
});

Deno.test("TE-15 (15:72): the actor id comes from the token, never from the body", async () => {
  const db = new FakeClient({
    "auth.getUser": { data: { id: UID, email_confirmed_at: "2026-01-01T00:00:00Z" } },
    "profiles.select": { data: { id: UID, role: "parent" } },
  });
  const actor = await resolveIdentity(requestWith({ authorization: `Bearer ${TOKEN}` }), db as never);
  assertEquals(actor.userId, UID);
  const profileCall = db.calls.find((c) => c.table === "profiles");
  assertEquals(profileCall?.predicates, [`id:eq:${UID}`]); // looked up BY the token subject
});

Deno.test("TE-05 / TE-06 / TE-12 / TE-13 (15:62-70): requireRole compares exactly", () => {
  const shape = (role: string) => {
    try {
      requireRole({ role }, "parent");
      return "allowed";
    } catch (e) {
      return `${(e as ApiError).status} ${(e as ApiError).code}`;
    }
  };
  assertEquals(shape("parent"), "allowed");
  assertEquals(shape("child"), "403 role_required");
  assertEquals(shape("unset"), "403 role_required"); // fails closed, 14:139-149
  assertEquals(shape("Parent"), "403 role_required"); // case-sensitive
  assertEquals(shape(""), "403 role_required");
});

Deno.test("emailVerifiedFor - the two readings, one per mode (S2-EXEC-08 §2(3))", () => {
  const base = { userId: UID, role: "parent", email: null };
  assertEquals(emailVerifiedFor({ ...base, authUser: { email_confirmed_at: "x" }, mode: "supabase-auth" }), true);
  assertEquals(emailVerifiedFor({ ...base, authUser: { email_confirmed_at: null }, mode: "supabase-auth" }), false);
  assertEquals(emailVerifiedFor({ ...base, authUser: { email_verified: true }, mode: "firebase-uid" }), true);
  assertEquals(emailVerifiedFor({ ...base, authUser: { email_verified: "true" }, mode: "firebase-uid" }), false);
});

Deno.test({
  name: "getServiceClient - a missing secret is 503, never an unauthenticated client (14:51-56)",
  // Skipped, never forced, if the runner's environment really does carry the staging
  // secrets. This suite never deletes or sets a secret to manufacture a result.
  ignore: Deno.env.get("SUPABASE_URL") !== undefined ||
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") !== undefined,
  fn: () => {
    const err = assertThrows(() => getServiceClient()) as ApiError;
    assertEquals(err.status, 503);
    assertEquals(err.code, "server_misconfigured");
    assertEquals(err.message.includes("SERVICE_ROLE"), false);
  },
});
