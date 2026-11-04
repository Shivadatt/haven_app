// ============================================================================
// tests/guards_test.ts — family, device and audit guards, against a stub client.
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY (see envelope_test.ts for what a pass means).
// Offline shapes of TE-01, TE-03, TE-04, TE-19, TE-20 and PE-C02 / PE-F02 / PE-P11.
//
// WHAT IS BEING ASSERTED: not only the verdict but the PREDICATES the verdict was reached
// with, because `service_role` bypasses RLS (14:245-246) — a missing `.eq()` is the bug,
// and a test that only reads the status code cannot see it.
// ============================================================================

import { assertEquals, assertRejects } from "@std/assert";

import { ApiError, ok } from "../functions/_shared/envelope.ts";
import {
  assertFamilyChild,
  assertFamilyMember,
  assertFamilyOwner,
  assertFamilyParent,
} from "../functions/_shared/auth.ts";
import { requireActiveDeviceForParent, requireDevice } from "../functions/_shared/auth.ts";
import { recordAudit } from "../functions/_shared/audit.ts";
import { sha256Hex } from "../functions/_shared/validation.ts";
import { FakeClient, post } from "./stub_db.ts";

const FAMILY_F = "ffffffff-0000-4000-8000-000000000000";
const PARENT_A = "aaaaaaaa-0000-4000-8000-000000000000".replace(/a/g, "1");
const PARENT_C = "cccccccc-0000-4000-8000-000000000000".replace(/c/g, "2");
const DEVICE_D1 = "dddddddd-0000-4000-8000-000000000000".replace(/d/g, "3");
const SECRET = "device-secret-value-1234";

/** A: parent of F. C: no membership row in F — the cross-family caller in TE-01/03/04. */
function familyStub(memberRole: string | null, opts: { deleted?: boolean } = {}): FakeClient {
  return new FakeClient({
    "families.select": { data: { id: FAMILY_F, owner_id: PARENT_A, deleted_at: opts.deleted ? "2026-01-01" : null } },
    "family_members.select": memberRole === null
      ? { data: null }
      : { data: { family_id: FAMILY_F, user_id: PARENT_A, role: memberRole, status: "active" } },
  });
}

Deno.test("TE-01 (15:58): a parent of another family is refused before any mutation", async () => {
  const db = familyStub(null); // C has no membership row in F
  const err = await assertRejects(() => assertFamilyParent(db as never, PARENT_C, FAMILY_F), ApiError);
  assertEquals([err.status, err.code], [403, "forbidden"]);
  assertEquals(db.ops(), ["families.select", "family_members.select"]); // no third query wrote anything
});

Deno.test("a child membership row does not satisfy assertFamilyParent (PE-P11 / PE-F02)", async () => {
  const err = await assertRejects(() => assertFamilyParent(familyStub("child") as never, PARENT_A, FAMILY_F), ApiError);
  assertEquals([err.status, err.code], [403, "forbidden"]);
});

Deno.test("assertFamilyChild accepts the child and rejects the parent (TE-05 shape)", async () => {
  assertEquals((await assertFamilyChild(familyStub("child") as never, PARENT_A, FAMILY_F)).id, FAMILY_F);
  const err = await assertRejects(() => assertFamilyChild(familyStub("parent") as never, PARENT_A, FAMILY_F), ApiError);
  assertEquals(err.status, 403);
});

Deno.test("a soft-deleted family is refused even for its own owner (14:129-131)", async () => {
  const err = await assertRejects(
    () => assertFamilyMember(familyStub("parent", { deleted: true }) as never, PARENT_A, FAMILY_F), ApiError);
  assertEquals([err.status, err.code], [403, "forbidden"]);
});

Deno.test("assertFamilyOwner - PE-F06 (15:177): a parent who is not the owner gets owner_required", async () => {
  const db = new FakeClient({
    "families.select": { data: { id: FAMILY_F, owner_id: PARENT_A, deleted_at: null } },
  });
  const err = await assertRejects(() => assertFamilyOwner(db as never, PARENT_C, FAMILY_F), ApiError);
  assertEquals([err.status, err.code], [403, "owner_required"]);
});

Deno.test("TE-03 / TE-04 (15:60-61): the family is taken from the DEVICE row, never the body", async () => {
  const db = new FakeClient({
    // D1 belongs to F. The caller is a parent of F, so the call succeeds — and the test
    // proves WHICH family id was asserted: F, read off the device, not whatever the body said.
    "devices.select": { data: { id: DEVICE_D1, family_id: FAMILY_F, status: "active", child_user_id: PARENT_A } },
    "families.select": { data: { id: FAMILY_F, owner_id: PARENT_A, deleted_at: null } },
    "family_members.select": { data: { role: "parent", status: "active" } },
  });
  const device = await requireActiveDeviceForParent(db as never, PARENT_A, DEVICE_D1);
  assertEquals(device.family_id, FAMILY_F);
  const familyCall = db.calls.find((c) => c.table === "families");
  assertEquals(familyCall?.predicates, [`id:eq:${FAMILY_F}`]);
  assertEquals(db.calls[0].predicates, [`id:eq:${DEVICE_D1}`]); // device looked up by id only
});

Deno.test("a non-active device cannot be used at all (PE-C02 shape)", async () => {
  const db = new FakeClient({ "devices.select": { data: { id: DEVICE_D1, family_id: FAMILY_F, status: "revoked" } } });
  const err = await assertRejects(() => requireActiveDeviceForParent(db as never, PARENT_A, DEVICE_D1), ApiError);
  assertEquals([err.status, err.code], [403, "forbidden"]);
  assertEquals(db.ops(), ["devices.select"]); // stopped before the family read
});

Deno.test("TE-19 (15:76): device telemetry without credentials is 401 device_auth_required", async () => {
  const headerSets: Record<string, string>[] = [{}, { "x-device-id": DEVICE_D1 }, { "x-device-secret": SECRET }];
  for (const headers of headerSets) {
    const err = await assertRejects(() => requireDevice(post({}, headers) as never, new FakeClient({}) as never), ApiError);
    assertEquals([err.status, err.code], [401, "device_auth_required"]);
  }
});

Deno.test("TE-20 (15:77): a wrong secret and an unknown device id are indistinguishable", async () => {
  const storedHash = await sha256Hex(SECRET);
  const wrong = new FakeClient({
    "devices.select": { data: { id: DEVICE_D1, family_id: FAMILY_F, status: "active", secret_hash: storedHash } },
  });
  const e1 = await assertRejects(() =>
    requireDevice(post({}, { "x-device-id": DEVICE_D1, "x-device-secret": "a-different-secret-value" }) as never, wrong as never), ApiError);
  const unknown = new FakeClient({ "devices.select": { data: null } });
  const e2 = await assertRejects(() =>
    requireDevice(post({}, { "x-device-id": DEVICE_D1, "x-device-secret": "a-different-secret-value" }) as never, unknown as never), ApiError);
  assertEquals([e1.status, e1.code, e1.message], [401, "invalid_device_credentials", e2.message]);
  assertEquals(e2.message, "Device credentials are not valid."); // no enumeration, no leak
  // E7 baseline, preserved rather than silently fixed: neither path counts attempts.
  assertEquals(wrong.ops().includes("pairing_attempts.insert"), false);
});

Deno.test("a revoked credential is refused even with the right secret", async () => {
  const storedHash = await sha256Hex(SECRET);
  const db = new FakeClient({
    "devices.select": {
      data: { id: DEVICE_D1, family_id: FAMILY_F, status: "active", secret_hash: storedHash, credential_revoked_at: "2026-01-01T00:00:00Z" },
    },
  });
  const err = await assertRejects(() =>
    requireDevice(post({}, { "x-device-id": DEVICE_D1, "x-device-secret": SECRET }) as never, db as never), ApiError);
  assertEquals([err.status, err.code], [401, "invalid_device_credentials"]);
});

Deno.test("a secret under 16 characters is refused before any lookup (14:295-338)", async () => {
  const err = await assertRejects(() =>
    requireDevice(post({}, { "x-device-id": DEVICE_D1, "x-device-secret": "tooshort" }) as never, new FakeClient({}) as never), ApiError);
  assertEquals([err.status, err.code], [401, "invalid_device_credentials"]);
});

Deno.test("recordAudit - the actor is the caller's, and an over-long event type fails loudly", async () => {
  const db = new FakeClient({ "audit_logs.insert": { error: null } });
  await recordAudit(db as never, { eventType: "session_requested", actorUserId: PARENT_A, familyId: FAMILY_F });
  const row = db.last()?.payload as Record<string, unknown>;
  assertEquals(row.actor_user_id, PARENT_A);
  assertEquals(row.family_id, FAMILY_F);
  assertEquals(row.event_type, "session_requested");

  const err = await assertRejects(() =>
    recordAudit(new FakeClient({}) as never, { eventType: "x".repeat(81) }), ApiError);
  assertEquals([err.status, err.code], [500, "audit_failed"]); // A3:...:433 boundary, guarded locally
});

Deno.test("recordAudit - a failed insert throws, so no action can succeed unaudited (14:293)", async () => {
  const db = new FakeClient({ "audit_logs.insert": { error: { code: "23505", message: "duplicate key value violates" } } });
  const err = await assertRejects(() => recordAudit(db as never, { eventType: "device_registered" }), ApiError);
  assertEquals([err.status, err.code], [500, "audit_failed"]);
  assertEquals(err.message.includes("duplicate key"), false); // the PostgREST text never reaches the client
});

Deno.test("ok() is what the handlers return, so a Response is assertable without a server", async () => {
  assertEquals((await ok({ ping: true }).json()).ping, true);
});
