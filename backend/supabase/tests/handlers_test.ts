// ============================================================================
// tests/handlers_test.ts — action handlers, driven through the stub client.
//
// STATUS: STAGE-2 RE-AUTHORED LANE ONLY (see envelope_test.ts for what a pass means).
// Offline shapes of TE-12, TE-13, TE-15, PE-S01..PE-S03, PE-S08..PE-S10, PE-S04 and
// PE-T01..PE-T03. The deployed functions are NOT involved: no index.ts is imported,
// because each calls Deno.serve at module scope and therefore cannot be imported by a test.
// ============================================================================

import { assertEquals, assertRejects } from "@std/assert";

import { ApiError } from "../functions/_shared/envelope.ts";
import { handlePendingChild, handleRequest, handleRespond } from "../functions/remote-session/lifecycle.ts";
import { handleHeartbeat } from "../functions/device-telemetry/heartbeat.ts";
import { FakeClient, jsonOf } from "./stub_db.ts";

const PARENT = "11111111-1111-4111-8111-111111111111";
const CHILD = "22222222-2222-4222-8222-222222222222";
const FAMILY = "33333333-3333-4333-8333-333333333333";
const DEVICE = "44444444-4444-4444-8444-444444444444";
const SESSION = "55555555-5555-4555-8555-555555555555";

const parentDevice = {
  "devices.select": { data: { id: DEVICE, family_id: FAMILY, child_user_id: CHILD, status: "active" } },
  "families.select": { data: { id: FAMILY, owner_id: PARENT, deleted_at: null } },
  "family_members.select": { data: { family_id: FAMILY, user_id: PARENT, role: "parent", status: "active" } },
};

function sessionStub(status: string, expiresAt: string, extra: Record<string, unknown> = {}) {
  return new FakeClient({
    ...parentDevice,
    "remote_sessions.select": { data: { id: SESSION, child_user_id: CHILD, family_id: FAMILY, device_id: DEVICE, status, expires_at: expiresAt, ...extra } },
    "remote_sessions.update": { data: { id: SESSION, status: status === "requested" ? "accepted" : status } },
    "audit_logs.insert": { error: null },
  });
}

Deno.test("TE-12 (15:69): the child cannot request a remote session, and nothing is queried", async () => {
  const db = new FakeClient(parentDevice);
  const err = await assertRejects(() =>
    handleRequest(db as never, CHILD, { role: "child" }, { device_id: DEVICE, kind: "audio" }), ApiError);
  assertEquals([err.status, err.code], [403, "role_required"]);
  assertEquals(db.ops(), []);
});

Deno.test("PE-S09 (15:192): kind \"screen\" is a 400, not a silently-dropped session", async () => {
  const db = new FakeClient(parentDevice);
  const err = await assertRejects(() =>
    handleRequest(db as never, PARENT, { role: "parent" }, { device_id: DEVICE, kind: "screen" }), ApiError);
  assertEquals([err.status, err.code], [400, "validation_error"]);
});

Deno.test("PE-S01 step 1 (15:184): the request row takes family and child from the DEVICE, never the body", async () => {
  const db = new FakeClient({
    ...parentDevice,
    "remote_sessions.insert": { data: { id: SESSION, status: "requested" } },
    "audit_logs.insert": { error: null },
  });
  const res = await handleRequest(db as never, PARENT, { role: "parent" }, {
    device_id: DEVICE,
    kind: "audio",
    // TE-15 (15:72) forged fields, which the insert must ignore:
    family_id: "99999999-9999-4999-8999-999999999999",
    child_user_id: PARENT,
    parent_user_id: "88888888-8888-4888-8888-888888888888",
    consent_recorded: true,
  });
  assertEquals(res.status, 200);
  const insert = db.calls.find((c) => c.op === "insert" && c.table === "remote_sessions");
  const row = insert?.payload as Record<string, unknown>;
  assertEquals(row.family_id, FAMILY);
  assertEquals(row.child_user_id, CHILD);
  assertEquals(row.parent_user_id, PARENT); // the verified token subject
  assertEquals(row.consent_recorded, false); // capture:141 — consent is never assumed
  assertEquals(row.status, "requested");
  const minutes = (new Date(String(row.expires_at)).getTime() - Date.now()) / 60_000;
  assertEquals(minutes > 9.5 && minutes <= 10.5, true); // REQUEST_TTL_MINUTES = 10
  const audit = db.calls.find((c) => c.table === "audit_logs");
  assertEquals((audit?.payload as Record<string, unknown>).event_type, "session_requested");
});

Deno.test("PE-S08 / E4 PRESERVED (15:191): two requests for one device both succeed", async () => {
  const db = new FakeClient({
    ...parentDevice,
    "remote_sessions.insert": [{ data: { id: SESSION } }, { data: { id: SESSION } }],
    "audit_logs.insert": { error: null },
  });
  await handleRequest(db as never, PARENT, { role: "parent" }, { device_id: DEVICE, kind: "audio" });
  await handleRequest(db as never, PARENT, { role: "parent" }, { device_id: DEVICE, kind: "audio" });
  // The advisory lock in public.request_remote_session is bypassed by design here; this test
  // pins the weakness so a future "fix" cannot be claimed silently.
  assertEquals(db.ops().filter((o) => o === "remote_sessions.insert").length, 2);
});

Deno.test("PE-S10 (15:193): pending is capped at 50 and stale rows expire first", async () => {
  const db = new FakeClient({ "remote_sessions.update": { error: null }, "remote_sessions.select": { data: [] } });
  await handlePendingChild(db as never, CHILD, { role: "child" });
  const [update, select] = db.calls;
  assertEquals(update.op, "update");
  assertEquals(update.predicates.slice(0, 2), [`child_user_id:eq:${CHILD}`, "status:eq:requested"]);
  assertEquals(String(select.predicates).includes(`n:limit:50`), true);
});

Deno.test("TE-13 (15:70): a parent cannot answer the child's session prompt", async () => {
  const db = sessionStub("requested", new Date(Date.now() + 600_000).toISOString());
  const err = await assertRejects(() =>
    handleRespond(db as never, PARENT, { role: "parent" }, { session_id: SESSION, accept: true }), ApiError);
  assertEquals([err.status, err.code], [403, "role_required"]);
});

Deno.test("PE-S01 step 2 (15:184): accept records consent, mints a nonce and re-times the TTL", async () => {
  const db = sessionStub("requested", new Date(Date.now() + 600_000).toISOString());
  await handleRespond(db as never, CHILD, { role: "child" }, { session_id: SESSION, accept: true });
  const update = db.calls.find((c) => c.op === "update");
  const patch = update?.payload as Record<string, unknown>;
  assertEquals(patch.status, "accepted");
  assertEquals(patch.consent_recorded, true); // only the child's accept can set this
  assertEquals(/^[0-9a-f-]{36}$/.test(String(patch.session_nonce)), true);
  const minutes = (new Date(String(patch.expires_at)).getTime() - Date.now()) / 60_000;
  assertEquals(minutes > 29.5 && minutes <= 30.5, true); // ACCEPTED_TTL_MINUTES = 30
  // compare-and-set: id AND child AND status, so a second responder cannot overwrite
  assertEquals(update?.predicates.slice(0, 3), [`id:eq:${SESSION}`, `child_user_id:eq:${CHILD}`, "status:eq:requested"]);
});

Deno.test("PE-S02 (15:185): repeating the same answer is idempotent, with no second transition", async () => {
  const db = sessionStub("accepted", new Date(Date.now() + 600_000).toISOString());
  const body = await jsonOf(await handleRespond(db as never, CHILD, { role: "child" }, { session_id: SESSION, accept: true }));
  assertEquals(body.idempotent, true);
  assertEquals(db.ops().filter((o) => o.endsWith(".update")).length, 0);
});

Deno.test("PE-S03 (15:186): answering the other way after a decline is a 409", async () => {
  const db = sessionStub("declined", new Date(Date.now() + 600_000).toISOString());
  const err = await assertRejects(() =>
    handleRespond(db as never, CHILD, { role: "child" }, { session_id: SESSION, accept: true }), ApiError);
  assertEquals([err.status, err.code], [409, "session_not_open"]);
});

Deno.test("PE-S04 (15:187): an expired prompt is 410 and the row is moved to expired", async () => {
  const db = sessionStub("requested", new Date(Date.now() - 60_000).toISOString());
  const err = await assertRejects(() =>
    handleRespond(db as never, CHILD, { role: "child" }, { session_id: SESSION, accept: true }), ApiError);
  assertEquals([err.status, err.code], [410, "session_expired"]);
  const update = db.calls.find((c) => c.op === "update");
  assertEquals((update?.payload as Record<string, unknown>).status, "expired");
});

Deno.test("PE-T02 (15:156): a heartbeat with battery 101 is rejected before any write", async () => {
  const db = new FakeClient({});
  const err = await assertRejects(() =>
    handleHeartbeat(db as never, { id: DEVICE, family_id: FAMILY, policy_version: 1 }, { battery_level: 101 }), ApiError);
  assertEquals([err.status, err.code], [400, "validation_error"]);
  assertEquals(db.ops(), []);
});

Deno.test("PE-T01 (15:155): the heartbeat answers with the pending policy version", async () => {
  const db = new FakeClient({
    "devices.update": { error: null },
    "device_policies.select": { data: { version: 7 } },
  });
  const body = await jsonOf(await handleHeartbeat(db as never,
    { id: DEVICE, family_id: FAMILY, policy_version: 4 }, { battery_level: 50, is_charging: false }));
  assertEquals(body.pending_policy_version, 7);
  const update = db.calls.find((c) => c.op === "update");
  assertEquals(update?.predicates, [`id:eq:${DEVICE}`, `family_id:eq:${FAMILY}`]); // 238 — no RLS net
  assertEquals((update?.payload as Record<string, unknown>).battery_level, 50);
});

Deno.test("PE-T03 (15:157): a second low battery inside the window does not re-alert", async () => {
  const withRecent = new FakeClient({
    "devices.update": { error: null },
    "safety_alerts.select": { data: { id: "66666666-6666-4666-8666-666666666666" } },
    "device_policies.select": { data: null },
  });
  const body = await jsonOf(await handleHeartbeat(withRecent as never,
    { id: DEVICE, family_id: FAMILY, policy_version: 2 }, { battery_level: 5 }));
  assertEquals(body.low_battery_alert_created, false);
  assertEquals(withRecent.ops().includes("safety_alerts.insert"), false);

  const noneRecent = new FakeClient({
    "devices.update": { error: null },
    "safety_alerts.select": { data: null },
    "safety_alerts.insert": { error: null },
    "device_policies.select": { data: null },
  });
  const body2 = await jsonOf(await handleHeartbeat(noneRecent as never,
    { id: DEVICE, family_id: FAMILY, policy_version: 2 }, { battery_level: 5 }));
  assertEquals(body2.low_battery_alert_created, true);
  assertEquals(body2.pending_policy_version, 2); // falls back to the device row
  const inserted = noneRecent.calls.find((c) => c.op === "insert")?.payload as Record<string, unknown>;
  assertEquals(inserted.type, "low_battery");
});
