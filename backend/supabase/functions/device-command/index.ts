// ============================================================================
// Edge Function: device-command           TARGET: dzonzgngwxclhfnvxtvu (STAGING ONLY)
// The production project's ref is deliberately NOT written in this artefact (owner rule: the
// staging project is the only project ref that may appear in code, comments or config).
// Production is not a target of this file and was not contacted. Deployment is BLOCKED by
// unsigned A7-R / A8-R.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   capture:59-60: MINIFIED BUNDLE, 18124 chars / 2 lines, sha256 4e31901a.... No source
//   maps exist (14:409 "Bundle-to-source equivalence — INFERRED"), so this is a re-authoring
//   from the anchor spec, not a de-minification. Nothing here has been compared to the
//   captured bundle.
//
// CAPTURED FACTS USED (file:line):
//   capture:63  actions = create, poll, ack
//   capture:64  auth_model = "create: parent JWT + verified email + requireActiveDeviceForParent;
//               poll/ack: device header credentials (x-device-id + x-device-secret)"
//   capture:65  inlined_modules = cors, envelope, auth, audit, validation  (NO rate_limit)
//   capture:67  apply_policy -> rpc apply_policy_version {p_device_id, p_policy,
//               p_actor:o.user.id, p_idempotency_key}; idempotency_key min 1 max 128;
//               ttl clamps 60..900; device_commands select by device_id + idempotency_key
//               before insert; 23505 -> re-read by idempotency key
//   capture:68  poll: rpc poll_device_commands {p_device_id:o.id, p_limit:20}
//   capture:69  ack: device_commands select .eq(id).eq(device_id,o.id); terminal status
//               returns existing row; update ... .in(status,[pending,delivered]); apply_policy
//               ack updates device_policies and devices.policy_version scoped to device
//   14-edge-function-security-audit.md:122 (role from profiles.role via service-role client),
//     :229 (custom payload = "object <= 64 KB" only), :224 (command `result` 32 KB, error text
//     truncated to 500), :306-309 (check 16 idempotency), :421-439 (finding E11: poll returns
//     created_by; the narrowing is PROPOSED — NOT APPLIED, so it is PRESERVED here)
//   15-edge-function-test-plan.md:116-126 PE-C01..C09 (codes: 403 / 400 / 404 command_not_found
//     / 410 command_expired / ttl clamp 60)
//   docs/stage1/evidence/functions-and-triggers.md:36,43,41 RPC signatures
//   docs/stage2/migrations/A3-staging-load-v1.sql:446 command type vocabulary
//     (apply_policy|sync_policy|request_usage|request_location|end_session|custom) — DATABASE-VERIFIED
//   :445 status vocabulary (pending|delivered|succeeded|failed|expired); :424 UNIQUE
//     (device_id, idempotency_key); :442 error_message <= 500; :441 attempts >= 0
//
// TABLES TOUCHED: devices (SELECT via auth; UPDATE policy_version), device_commands (SELECT,
//   INSERT, UPDATE), device_policies (SELECT, UPDATE), audit_logs (INSERT), families /
//   family_members / profiles (SELECT via auth assertions).
// RPCs CALLED: public.apply_policy_version, public.poll_device_commands.
//   public.expire_stale_commands(p_device_id) EXISTS (functions-and-triggers.md:41) but no
//   capture anchor shows a caller, so it is NOT called here. UNVERIFIED.
// SECRETS BY NAME: SUPABASE_SERVICE_ROLE_KEY. Device secrets arrive over x-device-secret and
//   are compared as SHA-256 digests; the raw secret is never stored, logged or returned.
// AUTH MODEL: two channels in one function — parent JWT for `create`, device credential for
//   `poll`/`ack`. Both authorise IN-HANDLER because service_role makes RLS inert (14:245).
//   `create` never takes family_id from the body: it comes from the device row
//   (requireActiveDeviceForParent, _shared/auth.ts:266-289). `poll`/`ack` ignore a body
//   device_id entirely — PE-C05 (15:122) proves the forged-id case must return D1's commands.
// IDEMPOTENCY: PRESENT. Pre-insert lookup by (device_id, idempotency_key), 23505 -> re-read,
//   apply_policy delegates to the RPC whose response carries `idempotent`; `ack` is a
//   compare-and-set with a re-read on a lost race.
// RATE LIMITING: ABSENT here — and ABSENT IN THE CAPTURED BUNDLE (capture:65 does not list
//   rate_limit). Preserved; finding E7.
// AUDIT LOGGING: PRESENT on `create` (capture:65 inlines audit). PE-C01 expects "two audit
//   rows" for apply_policy (15:118); one comes from this handler and the other is written
//   inside private.apply_policy_version, whose body is unread. See UNVERIFIED below.
// verify_jwt: NOT CAPTURED (no such field exists in the capture). Auth is in-handler on both
//   channels; a gateway verify_jwt value must be read from the dashboard before deploy.
//
// UNVERIFIED BEHAVIOUR (not implemented — no evidence):
//   - PAYLOAD SCHEMAS FOR sync_policy, request_usage, request_location, end_session.
//     14:221 says command payloads are "allowlisted per command type", but no anchor names
//     a single allowed key for these four types, and nothing in the repository describes
//     them. They therefore FAIL CLOSED with 501 `command_spec_missing` rather than accepting
//     an invented schema. `apply_policy` and `custom` ARE implemented from evidence.
//     -> NOT DEPLOYABLE WITHOUT SPEC for those four command types: that is the mandatory label
//     for a captured contract too thin to author against, and it is scoped to them only —
//     `apply_policy` and `custom` are authorable from evidence. See the DEPLOYMENT-MAP.md verdict.
//   - `audit` event_type strings and metadata shapes: no anchor names them. `command_created`
//     and `command_ack_recorded` are used and labelled; a mismatch with production breaks any
//     dashboard that filters on event_type.
//   - Which policy row an apply_policy `ack` acknowledges: capture:69 says only "updates
//     device_policies and devices.policy_version scoped to device". The version-selection
//     rule (latest pending for the device) is INFERRED.
//   - `delivered` is written by poll_device_commands (inside the unread RPC), not here.
//   - Response shapes for all three actions are not captured.
//   - Whether `ack` may report enforcement failures (`enforcement_status='failed'` plus
//     last_error) for a failed ack: implemented as the natural reading of the vocabulary and
//     labelled INFERRED.
//
// LAYOUT: this file is the action guard only. `create` authenticates as a PARENT and lives in
//   ./create.ts; `poll`/`ack` authenticate with the DEVICE credential and live in ./poll_ack.ts.
//   Split at port time for the 200-line source rule; behaviour, labels and anchors unchanged.
//   Because the two channels differ, auth is NOT hoisted — each module owns its own gate,
//   exactly as the captured handler did. Read all three files together.
// ============================================================================

import { handleCors } from "../_shared/cors.ts";
import { errorResponse, readJson, requireAction, unknownAction } from "../_shared/envelope.ts";
import { handleCreate } from "./create.ts";
import { handleAck, handlePoll } from "./poll_ack.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;
  try {
    const body = await readJson(req);
    const action = requireAction(body);

    // capture:63 — actions = create, poll, ack.
    if (action === "create") return await handleCreate(req, body);
    if (action === "poll") return await handlePoll(req);
    if (action === "ack") return await handleAck(req, body);

    unknownAction(action); // PE-CR06/15:137 pattern — 400, never a silent no-op
  } catch (err) {
    return errorResponse(err);
  }
});
