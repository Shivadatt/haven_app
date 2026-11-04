// ============================================================================
// tests/auth_bootstrap_test.ts — auth-bootstrap, device-register helpers and the
// device-policy spec guard.
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY (see envelope_test.ts for what a pass means).
// Offline shapes of PE-A01, PE-A02, PE-A04, PE-A05, PE-A06, PE-R01, PE-R06-adjacent bounds.
// PE-A03 (`email_not_verified`) is NOT reproducible offline: it is raised in the `requireUser`
// composition inside an index.ts that calls Deno.serve at module scope, so it stays NOT EXECUTED.
// ============================================================================

import { assertEquals, assertRejects, assertStringIncludes, assertThrows } from "@std/assert";

import { ApiError } from "../functions/_shared/envelope.ts";
import type { Actor } from "../functions/_shared/auth.ts";
import { createFamily } from "../functions/auth-bootstrap/create_family.ts";
import { setRole } from "../functions/auth-bootstrap/set_role.ts";
import { publicDevice, readInstallationId } from "../functions/device-register/register_flow.ts";
import { FakeClient, jsonOf } from "./stub_db.ts";

const UID = "11111111-1111-4111-8111-111111111111";

function actor(role: string): Actor {
  return { userId: UID, role, email: null, authUser: null, mode: "supabase-auth" };
}

Deno.test("PE-A06 (15:111): an out-of-vocabulary role is a 400 before anything is read", async () => {
  const db = new FakeClient({});
  const err = await assertRejects(() => setRole(db as never, actor("unset"), "unset", { role: "admin" }), ApiError);
  assertEquals([err.status, err.code], [400, "validation_error"]);
  assertEquals(db.ops(), []);
});

Deno.test("PE-A02 (15:109): a role already set cannot be set again — 409, no write", async () => {
  const db = new FakeClient({});
  const err = await assertRejects(() => setRole(db as never, actor("parent"), "parent", { role: "child" }), ApiError);
  assertEquals([err.status, err.code], [409, "role_already_set"]);
  assertEquals(db.ops(), []);
});

Deno.test("PE-A01 (15:108): set_role writes the caller's own row and audits the caller", async () => {
  const db = new FakeClient({ "profiles.update": { error: null }, "audit_logs.insert": { error: null } });
  const res = await setRole(db as never, actor("unset"), "unset", { role: "parent" });
  assertEquals(res.status, 200);
  const update = db.calls.find((c) => c.op === "update");
  assertEquals(update?.table, "profiles");
  assertEquals(update?.predicates, [`id:eq:${UID}`]); // self-scoped: no admin path here
  assertEquals(update?.payload, { role: "parent" });
  const audit = db.calls.find((c) => c.table === "audit_logs");
  assertEquals((audit?.payload as Record<string, unknown>).event_type, "role_set");
  assertEquals((audit?.payload as Record<string, unknown>).actor_user_id, UID);
});

Deno.test("PE-A05 (15:110): a child cannot create a family", async () => {
  const db = new FakeClient({});
  const err = await assertRejects(() => createFamily(db as never, actor("child"), "child", { name: "Aurora" }), ApiError);
  assertEquals([err.status, err.code], [403, "role_required"]);
  assertEquals(db.ops(), []);
});

Deno.test("create_family name bound: empty and over-80 are both 400 (families_name_check, A3:...:467)", async () => {
  for (const name of ["", "x".repeat(81)]) {
    const db = new FakeClient({});
    const err = await assertRejects(() => createFamily(db as never, actor("parent"), "parent", { name }), ApiError);
    assertEquals([err.status, err.code], [400, "validation_error"]);
    assertEquals(db.ops(), []); // rejected before the owner lookup
  }
});

Deno.test("PE-A04 (15:110): one active family per owner -> 409 family_exists", async () => {
  const db = new FakeClient({
    "families.select": { data: { id: "33333333-3333-4333-8333-333333333333" } },
  });
  const err = await assertRejects(() => createFamily(db as never, actor("parent"), "parent", { name: "Aurora" }), ApiError);
  assertEquals(err.code, "family_exists");
  assertEquals(err.status, 409);
  assertEquals(db.calls[0].predicates, [`owner_id:eq:${UID}`, "deleted_at:is:null"]);
});

Deno.test("PE-R01 (15:131): the device projection strips the secret hash and the installation id", () => {
  const row = {
    id: "44444444-4444-4444-8444-444444444444",
    family_id: "33333333-3333-4333-8333-333333333333",
    status: "active",
    secret_hash: "a".repeat(64),
    installation_id: "installation-value",
  };
  const projected = publicDevice(row);
  assertEquals(Object.keys(projected ?? {}).sort(), ["family_id", "id", "status"]);
  assertEquals(JSON.stringify(projected).includes("a".repeat(64)), false);
  assertEquals(publicDevice(null), null);
});

Deno.test("readInstallationId - the DDL bound 8..128 is the gate (A3:...:461)", () => {
  assertEquals(readInstallationId({ installation_id: "12345678" }), "12345678");
  assertEquals(readInstallationId({ installation_id: "x".repeat(128) }).length, 128);
  for (const bad of [{}, { installation_id: "1234567" }, { installation_id: "x".repeat(129) }]) {
    assertEquals((assertThrows(() => readInstallationId(bad)) as ApiError).code, "validation_error");
  }
});

Deno.test("device-policy - the spec gap is still declared, and no key names were invented", async () => {
  // Read as TEXT, not imported: `device-policy/index.ts` calls Deno.serve at module scope, so
  // importing it would open a listener inside the test runner. That is the reason every test in
  // this directory imports action modules rather than entry points.
  const source = await Deno.readTextFile(new URL("../functions/device-policy/index.ts", import.meta.url));
  for (const name of ["TOP_LEVEL_POLICY_KEYS", "SUB_OBJECT_KEYS", "APP_RULE_KEYS"]) {
    const line = source.split("\n").find((l) => l.includes(`export const ${name}`));
    assertEquals(String(line).includes("= []"), true, `${name} must stay empty until the owner supplies V/X/Z`);
  }
  assertStringIncludes(source.split("\n").map((l) => l.trim().replace(/^\/\/\s*/, "")).join(" "),
    "NOT DEPLOYABLE WITHOUT SPEC");
});

Deno.test("stub sanity: a handler returning ok() is readable without a server", async () => {
  const db = new FakeClient({ "profiles.update": { error: null }, "audit_logs.insert": { error: null } });
  const body = await jsonOf(await setRole(db as never, actor("unset"), "unset", { role: "child" }));
  assertEquals([body.ok, body.role, body.contact_id_prefix], [true, "child", "PC"]);
});
