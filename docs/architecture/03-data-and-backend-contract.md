# 03 — Data model and backend contract

## 1. What the code references, versus what exists

Table names read from the actual call sites in `backend/supabase/functions/` (17 distinct; a generic
loader also passes a literal `table` variable, which is not a table):

```
audit_logs            device_policies        pairing_attempts      safe_zones
child_contact_ids     devices                pairing_requests      safety_alerts
device_commands       families               profiles              usage_daily
device_pairing_tokens location_events        remote_sessions       safe_zone_states
family_members
```

RPC names the handlers call (12, same extraction method):

```
apply_policy_version        expire_stale_sessions   request_device_recovery
create_family_with_owner    poll_device_commands    respond_pairing_request
create_pairing_invite       replace_device_apps     revoke_device
create_pairing_request      detect_offline_devices   unlink_child
```

**Every one of these exists only as candidate DDL.** `docs/stage2/migrations/A3-staging-load-v1.sql`
creates all 17 tables — spot-verified for `device_pairing_tokens`, `child_contact_ids`,
`pairing_attempts`, `remote_sessions`, `safe_zone_states` — and defines 1 function;
`A3b-functions-triggers-candidate.sql` defines 13 and is gated on an owner ruling about whether
call-site + body derivation of **return types** is admissible;
`A3c-notification-backend.sql` defines 2; `A3d-firebase-identity-mapping.sql` defines 0.
All four are `PREPARED — NOT EXECUTED`, and staging has **0 tables**
(`docs/stage2/functions/DEPLOYMENT-MAP.md` §1).

Consequences recorded in the same table: every read/write fails at first contact, and every
`db.rpc(...)` returns `404`/`PGRST202`. Triggers on `remote_sessions`, `families` and `profiles` are
also absent (A3b candidate only).

## 2. Why the client cannot read any of it directly

Two separate walls, both evidenced in stage 1:

1. **Grant wall on `devices`.** `public.devices` has a SELECT *policy* but no SELECT **grant** for the
   `authenticated` role, so no client can read it at all — finding **F6**
   (`docs/stage1/00-status-register.md:86`, restated in
   `apps/haven_app/lib/core/errors/captured_gaps.dart:9-17`).
2. **EXECUTE wall on the RPC lane.** All 14 captured `public` functions carry
   `acl = "postgres=X/postgres, service_role=X/postgres"` and `auth_exec = false`, so the signed-in
   role cannot execute a single one (`captured_gaps.dart:24-33`, citing
   `docs/stage1/evidence/g1-q7-20261029.json` and `g1-b3b-20261029.json:68-81`).

That is the entire architectural reason an Edge Function lane exists: the function holds
`service_role` and does the read on the client's behalf. Staging deploys **0** of them, so today
neither wall has a door.

Note the RLS corollary that shapes the backend tests: because the handlers run as `service_role`,
**RLS does not apply to any of their queries**, so the predicates they write are the only control
(`docs/stage1/14-edge-function-security-audit.md:245-246`, applied in
`backend/supabase/tests/README.md` §2 — the tests assert recorded predicates, not just status codes).

## 3. The response envelope (the app/backend contract)

`backend/supabase/functions/_shared/envelope.ts`:

| Helper | Shape | Notes |
| --- | --- | --- |
| `ok(x)` | `{ ok: true, ...fields }` | always `Cache-Control: no-store`; CORS headers on every response |
| `fail(status, code, message, extra?)` | `{ ok: false, error: { code, message } }` | `extra` merges in (e.g. numeric `retry_after_seconds` on `429`) |
| `handleCors(req)` | OPTIONS → `200` with `Access-Control-Allow-Origin: *` | finding **E9** preserved verbatim; any other method with no handler → `405` |
| `readJson(req)` | object-only | non-object body → `400`; a declared length over 512 KiB → `413 payload_too_large` |
| `errorResponse(err)` | passthrough for `ApiError` | anything else becomes `internal_error`, and the message is asserted not to leak internal text |

The Dart side mirrors this as typed replies (`packages/haven_api/lib/src/data_contracts.dart`,
`edge_caller_impl.dart:22-29`), and slug names are a closed set —
`EdgeFunctionName` (`backend_endpoints.dart:150-165`) enumerates exactly the nine captured slugs.

## 4. Deployment gates (nothing may be shipped without these)

| Instrument | Gates | Status |
| --- | --- | --- |
| **A3** | landing the schema | prepared, owner-paste only, browser SQL Editor |
| **A3b** | 9 function bodies + 25 blocked dependents | `PREPARED — NOT EXECUTED — DERIVATION ADMISSIBILITY REQUIRED` |
| **A7-R** | authoring/deploying Edge Functions (Option 2 = re-authored, labelled) | `UNSIGNED` (`docs/stage2/approval-package-v3-implementation-instruments.md:723`) |
| **A8-R** | the deploy itself | `UNSIGNED` (same line) |
| **A9** | the six secret names | `UNSIGNED` (`:565`) — see `backend/supabase/config/environment.md` |
| **A12-R** | Firebase app registration + FCM | `UNSIGNED` (`:315`) |
| **A13** | the identity bridge / `firebase_identity_mapping` | `UNSIGNED` (`:201`) |

Order of operations, from `backend/supabase/migrations/README.md` §3: A3 → A3b → A3d → A3c → the
`S2-P0x` patches → the Edge Functions → the secrets. Secrets last, because A9's names are scoped to
roles A3 creates.

## 5. Two scopes that are `NOT DEPLOYABLE WITHOUT SPEC`

Mandated by the implementation brief and asserted by a test
(`backend/supabase/tests/auth_bootstrap_test.ts` reads `device-policy/index.ts` as text and fails if
the label is removed):

| Slug | Blocked scope | Why |
| --- | --- | --- |
| `device-policy` | the key-allowlist part of `update` | `capture:95` names three allowlists as `V`/`X`/`Z` and their **contents appear nowhere** in the evidence |
| `device-command` | `sync_policy`, `request_usage`, `request_location`, `end_session` | no anchor names an allowed key for these four, so they fail closed with `501 command_spec_missing`; `apply_policy` and `custom` **are** authored |

All nine slugs additionally carry `RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION`.

Related: [02-auth-and-identity.md](02-auth-and-identity.md) ·
[04-refusal-model.md](04-refusal-model.md) ·
[`backend/supabase/functions/README.md`](../../backend/supabase/functions/README.md)
