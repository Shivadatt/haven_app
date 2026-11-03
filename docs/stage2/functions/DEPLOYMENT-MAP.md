# DEPLOYMENT MAP — IMP-5 Edge Function source package (stage 2)

TARGET PROJECT: Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` — **staging only**.
Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` is not a target of any file in this
directory, was never opened, and is not referenced as a target anywhere in the source.
**NOTHING HERE IS DEPLOYED.** Deployment requires `A7-R` + `A8-R`, both `STATUS: UNSIGNED`
(`approval-package-v3-implementation-instruments.md` §7). This is preparation only.

Every file here is **RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION** (mandatory A7-R
Option 2 label, §7.1/§7.5). Reason: `supabase/functions/` is ABSENT from the repository and the
capture records `functions_directory: "absent"`, `import_map_or_deno_json: "absent"`
(`evidence/edge-functions/capture-20261030.json:173-177`). The package emits **0** of the
`private.*`/`public.*` SQL functions the handlers call; the artefacts under `migrations/` are
candidates, not landed schema.

Secrets are referenced **BY NAME ONLY** everywhere. No secret value appears in this directory.
Digests quoted in headers are transcribed from the capture; no digest was computed by IMP-5
(terminal prohibited) — where a digest of an authored file would be needed it is stated as
"not computed (terminal prohibited)".

## 1. Current staging state (why preconditions matter)

| Object | Staging today | Consequence for a deploy |
|---|---|---|
| Tables | 0 (A3 not landed) | Every read/write fails at first contact |
| SQL functions | 0 | Every `db.rpc(...)` returns 404/PGRST202 |
| Edge Functions | 0 | No slug exists yet; deploy = create |
| Edge secrets | 0 (A9 NOT SIGNED) | `getServiceClient()` throws `503 server_misconfigured`; cron `503 cron_not_configured`; `ice` `503`; `identifierHash` silently degrades to SHA-256 (E6) |
| Triggers on `remote_sessions`, `families`, `profiles` | 0 (A3b candidate only) | Transition guards absent; the `requested -> expired` writes rely on them being benign once landed |

## 2. Master map — one row per function

Legend: **RL** = rate limiting, **IDEM** = idempotency, **AUD** = audit logging.
`verify_jwt` is **NOT CAPTURED** for any slug — `capture-20261030.json` has no such field. The
column below is an expectation derived from the captured auth channels, not an observation:
* `OFF (required)` — the slug accepts requests that carry **no Supabase user JWT** (device header
  or shared secret), so an enabled gateway `verify_jwt` would reject legitimate traffic.
* `ON permitted` — every action carries a user JWT, so either setting can work; the function
  still verifies the token itself, so ON adds gateway defence, not authorisation.
Read the real value from the dashboard before deploying; do not infer it from this table.

| slug | source status | auth model (captured) | verify_jwt expectation | tables / SQL functions | secrets by name | IDEM / RL | AUD | deploy preconditions | browser-paste |
|---|---|---|---|---|---|---|---|---|---|
| `auth-bootstrap` | re-authored; capture:45 calls it "readable TypeScript" but no repository text exists | user JWT + verified email; `set_role` self-only one-time; `create_family` parent-only | ON permitted | `profiles`, `families`, `child_contact_ids`, `family_members` / rpc `create_family_with_owner` | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: guard-only (`409 role_already_set`, `409 family_exists`) / RL: ABSENT | PRESENT (`role_set`); none for `create_family` (not evidenced) | A7-R Opt2 + A8-R; A3; A9 | YES — `deploy/auth-bootstrap.bundle.ts` (659 L, 5 modules inlined) |
| `pairing` | re-authored; capture:27 "readable" 972 L — text absent, only anchors survive | user JWT + verified email; parent or child per action; membership asserted per action | ON permitted | `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `pairing_requests`, `family_members`, `families`, `profiles`, `devices` / rpcs `create_pairing_request`, `create_pairing_invite`, `respond_pairing_request`, `unlink_child` | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, PAIRING_HASH_PEPPER | IDEM: UNIQUE `token_id` + `409 code_unavailable`, compare-and-set token status / RL: **PRESENT — the only slug with it** | **ABSENT** — no anchor names an audit call (import-set tension disclosed in the header) | A7-R Opt2 + A8-R; A3; A9 incl. the pepper | YES — `deploy/pairing.bundle.ts` (1084 L, **all six** modules inlined; `audit` inlined-but-uncalled) |
| `device-command` | re-authored from a MINIFIED bundle (capture:59) | `create`: parent JWT + `requireActiveDeviceForParent`; `poll`/`ack`: `x-device-id` + `x-device-secret` | **OFF (required)** — poll/ack carry no JWT | `devices`, `device_commands`, `device_policies`, `audit_logs`, + assertion reads / rpcs `apply_policy_version`, `poll_device_commands` (`expire_stale_commands` exists, no caller evidenced) | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: PRESENT (`(device_id,idempotency_key)` pre-read, `23505` re-read) / RL: ABSENT | PRESENT (`command_created`, `command_ack_recorded` — names UNVERIFIED) | A7-R Opt2 + A8-R; A3; A9; **+ payload spec for 4 of 6 command types** | **PARTIAL** — `deploy/device-command.bundle.ts` (743 L) returns `501 command_spec_missing` for `sync_policy`, `request_usage`, `request_location`, `end_session` |
| `device-register` | re-authored from a MINIFIED bundle (capture:73) | child JWT + verified email + `assertChildMembership(body family_id)` | ON permitted | `devices`, `audit_logs`, + assertion reads / **no RPC** | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: UNIQUE `(family_id,installation_id)` -> re-credential path / RL: ABSENT | PRESENT ×3 incl. the **denial** (`device_registration_blocked`) | A7-R Opt2 + A8-R; A3; A9; **+ ruling on the revoked-relink ambiguity** | **PARTIAL** — `deploy/device-register.bundle.ts` (534 L) fails closed (`403`) behind `ALLOW_RELINK_AFTER_REVOKED_PAIRING = false` |
| `device-policy` | re-authored from a MINIFIED bundle (capture:86) | parent JWT + verified email + `requireActiveDeviceForParent` | ON permitted | `devices` + assertion reads, `audit_logs` / rpc `apply_policy_version` (writes `device_policies`, `device_commands`) | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: PRESENT (delegated; replay skips audit) / RL: ABSENT | PRESENT (`policy_updated`, name UNVERIFIED) | A7-R Opt2 + A8-R; A3; A9; **+ bundle constants V/X/Z (policy key allowlists)** | **NO — BLOCKED ON SPEC.** `deploy/device-policy.bundle.ts` (483 L) gates `501 policy_schema_missing` before the RPC. Supplying the three key sets is a one-line edit |
| `device-telemetry` | re-authored from a MINIFIED bundle (capture:101) | **device credential only** — no user-JWT path exists | **OFF (required)** | `devices`, `location_events`, `usage_daily`, `safe_zones`, `safe_zone_states`, `safety_alerts` / rpc `replace_device_apps` | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: PARTIAL — keyed upserts for `usage_daily`/`safe_zone_states`, snapshot replace for apps, **plain insert for `location_events` so retries duplicate** / RL: **ABSENT** (PE-T12: 100 uploads/60 s all accepted) | **ABSENT — capture:106 inlines no `audit` module (E13)** | A7-R Opt2 + A8-R; A3; A9 | YES — `deploy/device-telemetry.bundle.ts` (606 L, **4 modules**, deliberately no audit block) |
| `family-admin` | re-authored from a MINIFIED bundle (capture:116) | parent JWT + verified email for all five actions; `update_retention` also owner-only (`403 owner_required`) | ON permitted | `devices` (scope read), `safety_alerts`, `location_events`, `usage_daily`, `families`, `audit_logs`, + assertion reads / rpcs `revoke_device`, `request_device_recovery` | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY | IDEM: `purge_data` cutoff-based delete is naturally idempotent; `ack_alert` last-writer-wins; RPCs own their transitions / RL: **ABSENT on a slug that DELETES data** | PRESENT ×5 (`device_revoked`* , `device_recovery_started`✓, `alert_acknowledged`✓, `data_purged`✓, `settings_updated`✓) | A7-R Opt2 + A8-R; A3; A9 | YES — `deploy/family-admin.bundle.ts` (560 L). **HARDENING DEVIATION** on `revoke_device` (in-function parent-of-that-family check the capture delegates to the unread RPC) |
| `remote-session` | re-authored from a MINIFIED bundle (capture:134) | user JWT + verified email; parent `request`; child `pending_child`/`respond`/`start`; either participant `end`/`ice` | ON permitted | `remote_sessions`, `devices` + assertion reads, `audit_logs` / **no RPC — see E4** | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, TURN_SECRET, TURN_HOST (name PLACEHOLDER) | IDEM: PRESENT — compare-and-set on every transition, repeats `200`, lost race re-reads / RL: **ABSENT** (E7: consent inbox floodable, PE-S08) | PRESENT (`session_requested`✓; accepted/declined/started/ended names INFERRED) | A7-R Opt2 + A8-R; A3; A9 (TURN); **A13 + A12-R for `webrtc_signals`**, which has NO evidenced action and relies on `auth.uid()` | YES — `deploy/remote-session.bundle.ts` (689 L). **E4 BYPASS PRESERVED**: direct insert, not `public.request_remote_session` |
| `cron` | re-authored from a MINIFIED bundle (capture:150) | **shared secret** `x-cron-secret`; `CRON_SECRET` shorter than 16 chars -> `503 cron_not_configured`; SHA-256 both sides, constant-time, case-insensitive | **OFF (required)** | none directly / rpcs `expire_stale_sessions`, `detect_offline_devices` | SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET | IDEM: inherent (both RPCs are state-transition sweeps) / RL: ABSENT | **ABSENT — capture:157 inlines ONLY `cors` + `envelope`** (see §3) | A7-R Opt2 + A8-R; A3; A9 (CRON_SECRET ≥16); a pg_cron schedule is a separate approval | YES — `deploy/cron.bundle.ts` (214 L) |

## 3. `cron`'s module set is a finding, not an oversight to fix

`capture-20261030.json:157` records `cron.inlined_modules = ["cors","envelope"]`. The brief flags
this as "a real finding you must not fix silently by adding them without saying so", so:

* **Both** the module file (`cron.ts`) and the bundle (`deploy/cron.bundle.ts`) carry **only**
  `cors` and `envelope`. Nothing was added.
* Three consequences are disclosed in-file rather than repaired:
  (a) the Supabase client is constructed inline in the handler (`auth` absent) — INFERRED to be
      the service-role client, because two `public.*` sweeps cannot be done as the caller;
  (b) the digest and constant-time helpers are hand-rolled locally (`validation` absent), so the
      cron path does not share the audited crypto helpers;
  (c) `audit` is absent, so **a cron run leaves no audit row at all** — expiry sweeps and offline
      alerts are unauditable. That is the captured behaviour and matches finding E13's pattern.
* Net: `cron` is the only slug with **no** `_shared` authorisation, validation, rate-limit or
  audit module inlined. Its single gate is the shared secret.

## 4. Preserved weaknesses vs deliberate hardening

Preserved **because the brief forbids silently changing deployed behaviour** (each is an A7-R
decision, not an IMP-5 edit): E4 direct-insert bypass (`remote-session`), E5 unsalted SHA-256
token digest, E6 silent pepper fallback with `pairing_hash_pepper_missing` warn-once, E7 absent
rate limits on 8 of 9 slugs, E8 read-then-act quota counting, E9 wildcard CORS with credential
headers, E10 client-chosen device secret, E11 `poll` leaking `created_by`, E12 cron replay,
E13 no audit on `device-telemetry`, plus `cron`'s bare module set (§3).

Deliberate deviations, each labelled **HARDENING DEVIATION** in-file and justified by "every
protected operation must authorise inside the function; never rely on RLS for a service-role
path": `pairing` `respond`/`cancel`/`unlink` pre-read + relationship assert; `family-admin`
`revoke_device` scope read. One leak reduction: `device-register` maps an insert failure through
`ensureNoError` instead of rethrowing the raw error object (14:280-283 records the raw rethrow).

## 5. Deploy order and procedure (staging, browser-only, when approvals land)

1. Land the A3 schema + functions/triggers artefacts, verify 19 tables and the RPC set exist.
2. Under A9, set secrets **by name** in Edge Secrets: `SUPABASE_SERVICE_ROLE_KEY`,
   `PAIRING_HASH_PEPPER`, `CRON_SECRET` (>= 16 chars), `TURN_SECRET`, and the TURN host config.
   Order per 04 §A9: set -> verify -> deploy.
3. Deploy in dependency order, one slug at a time (Supabase -> Project Settings -> Edge
   Functions -> create, paste the bundle file): `auth-bootstrap` -> `pairing` ->
   `device-register` -> `device-telemetry` -> `device-command` -> `device-policy` ->
   `family-admin` -> `remote-session` -> `cron`.
4. Do NOT edit a live function in the dashboard (A7's prohibition survives re-scope) and do NOT
   deploy any minified bundle. Dashboard pasting is permitted here only as the **transport for
   source authored in this package**, never as a way to bypass source review.
5. Gate check before `device-policy`: V/X/Z supplied. Gate before `device-command` full coverage:
   the four missing payload specs. Gate before `device-register`: the revoked-relink ruling.
6. Read each slug's actual `verify_jwt` from the dashboard and record it; the map's expectation
   column is derived, not observed.

## 6. Readiness verdict

* Deployable as written after A3 + A9: `auth-bootstrap`, `pairing`, `device-telemetry`,
  `family-admin`, `remote-session`, `cron` — six of nine, all still carrying
  **NO PARITY VERIFICATION**.
* Partially deployable: `device-command` (2 of 6 command types), `device-register` (one
  unresolved branch).
* Not deployable for its only action: `device-policy` (fail-closed `501`).
* Blocked upstream for all nine by `A7-R`/`A8-R` unsigned and staging schema emptiness.
