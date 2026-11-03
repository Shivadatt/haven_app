# 15 — Edge Function test plan

Status: **`NOT EXECUTED`**. Nothing in this document has been run. Every case is a plan.

Phase E, 2026-10-30. Companion: [14-edge-function-security-audit.md](14-edge-function-security-audit.md),
[16-phase-e-findings.md](16-phase-e-findings.md). Source under test:
[capture-20261030.json](evidence/edge-functions/capture-20261030.json).

Labels: **VERIFIED** / **INFERRED** / **NOT VERIFIED** / **NOT TESTED** (default for every case here) /
**PROPOSED — NOT APPLIED** (setup steps, fixes referenced by a case).

## 0. Rules for whoever runs this

1. **Never against production.** Every negative or destructive case needs a scratch project seeded with synthetic users.
   The production project is `parent-control-prod` (`hhqgreaoqulmfwfwarhc`); its URL appears below only because the
   tests will eventually be pointed at a project with the same function names.
2. **A destructive case that passes is a finding, not a success.** E2's baseline case really does unlink a child. If it
   is ever run on production data, it causes the exact harm it is meant to detect.
3. **Never paste a real JWT, anon key, device secret or cron secret into a report.** Record `status`, `error.code`,
   `error.message` and a request id; redact `Authorization`, `apikey`, `x-device-secret`, `x-cron-secret`.
4. **Stop on 5xx.** A 5xx from an unplanned path is either a bug or a leaked internal error; capture `error.code` and
   the response body before continuing.
5. **One change at a time.** If a remediation from 16 is applied between runs, re-run the baseline cases for that
   function before trusting the new result.

Base URL pattern: `https://<project-ref>.supabase.co/functions/v1/<slug>`.
Required gateway headers: `apikey: <anon key>` on every call; `Authorization: Bearer <user JWT>` for user routes;
`x-device-id` + `x-device-secret` for device routes; `x-cron-secret` for cron.

## 1. Fixtures (PROPOSED — NOT APPLIED)

Seed in the scratch project only. Names are placeholders.

| Fixture | Role | Family | Notes |
| --- | --- | --- | --- |
| A | parent, owner | F | verified email |
| B | parent | F | second parent, for same-family tests |
| C | parent, owner | G | **not** a member of F |
| K | child | F | has device `D1`, verified email |
| M | child | G | has device `D2` |
| N | parent | none | verified email, no family |
| U | user | none | profile `role = 'unset'`, verified email |
| X | user | none | unverified email |
| D1 | device of K | F | active, known secret |
| D2 | device of M | G | active, known secret |
| R1 | device of K | F | revoked, to test relink guard |

Also seed: one active pairing code for K, one expired code for K, one pending `pairing_request` for K from A, one
`requested` remote session from A to D1.

## 2. Required scenarios (the ten the Phase E brief names)

Each row is a complete case: preconditions, request shape, expected result, and the finding it exercises. **All
`NOT TESTED`.**

| ID | Scenario | Request | Expected today | Expected after fix | Maps to |
| --- | --- | --- | --- | --- | --- |
| TE-01 | Forged parent id | `POST /pairing` as **C**, `{action:"redeem", code:"<valid code of K>", family_id:"<F>"}` | `403 forbidden` — C is not a parent in F (`assertFamilyParent` runs before the RPC) | same | audit check 3 |
| TE-02 | Forged parent id at the SQL layer | Scratch project only, `EXECUTE` granted to `authenticated`: `rpc/request_device_recovery` as **C** with `p_device_id=D1`, `p_actor_user_id=A` | **succeeds** and unlinks K — this is the E2/F7 baseline | `actor_mismatch` (42501) | E2, E3 |
| TE-03 | Cross-family device access | `POST /device-policy` as **C**, `{action:"update", device_id:"<D1>", …}` | `403 forbidden` — `requireActiveDeviceForParent` fails on D1's family | same | audit check 5–6 |
| TE-04 | Cross-family session creation | `POST /remote-session` as **C**, `{action:"request", device_id:"<D1>", kind:"audio"}` | `403 forbidden` | same | audit check 5 |
| TE-05 | Child attempts a parent-only action | `POST /pairing` as **K**, `{action:"list_family", family_id:"<F>"}` | `403 role_required` | same | audit check 4 |
| TE-06 | Child attempts policy write | `POST /device-policy` as **K**, `{action:"update", device_id:"<D1>", …}` | `403 role_required` | same | audit check 4 |
| TE-07 | Unauthenticated request | `POST /pairing` with `apikey` but **no** `Authorization`, `{action:"pending_child"}` | `401 unauthorized` | same | audit check 1 |
| TE-08 | Malformed / foreign auth header | `Authorization: Bearer x`, and separately a token signed for another project | `401 unauthorized` | same | audit check 1 |
| TE-09 | Expired JWT | Access token with `exp` in the past (refresh disabled client-side) | `401 unauthorized` | same | audit check 1 |
| TE-10 | Replayed pairing request | `POST /pairing` as **A**, `{action:"respond", request_id:"<R1>", approve:true}` twice, then once as **B** | first 200, second 200 idempotent or 409 (`respond_pairing_request` semantics), B `403 forbidden` | same | audit check 7, 16 |
| TE-11 | Replayed pairing code | `POST /pairing` as **A** and then **B**, same code, same family F | first creates a request, second `409 code_unavailable` | same | audit check 7 |
| TE-12 | Unauthorised remote-session creation | `POST /remote-session` as **K** (the child), `{action:"request", …}` | `403 role_required` | same | audit check 4, 8 |
| TE-13 | Unauthorised session accept | `POST /remote-session` as **A** (parent), `{action:"respond", session_id:"<pending for K>", accept:true}` | `403 role_required` (respond is child-only) | same | audit check 8 |
| TE-14 | Session started without consent | Seed a session in `requested`; `POST /remote-session` as **K**, `{action:"start", …}` | `409 session_not_open` | same | audit check 8–9 |
| TE-15 | Forged audit actor | Any audited action with `actor_user_id` / `parent_user_id` / `p_actor*` added to the JSON body | body fields ignored; audit row actor equals the JWT subject | same | E14, audit check 3 |
| TE-16 | Invalid cron authentication | `POST /cron` with `x-cron-secret: wrong`, and with no header, and with a 15-character secret | `401 unauthorized`; missing header `401`; short configured secret `503 cron_not_configured` | same | audit check 17 |
| TE-17 | Duplicate command delivery | `POST /device-command` as device D1 `{action:"ack", command_id:…, status:"succeeded"}` twice | second returns the stored row, no second state change | same | audit check 16 |
| TE-18 | Duplicate command creation | `POST /device-command` as **A** twice with the same `idempotency_key` | one row; second call returns the same command | same | audit check 16 |
| TE-19 | Device without credentials | `POST /device-telemetry` with no headers | `401 device_auth_required` | same | audit check 6 |
| TE-20 | Wrong device secret | D1's id with a different 16+ char secret, 20 times | `401 invalid_device_credentials` each time; **no lockout exists** (E7 baseline) | same behaviour, but counted | E7 |

TE-02 and TE-04 are the two cases that change behaviour once E1–E3 are remediated; every other row is expected to pass
today and is a regression guard.

## 3. Per-endpoint cases

### `pairing`

| ID | Case | Expected |
| --- | --- | --- |
| PE-P01 | `get_contact_id` as child with no contact id yet | 200, `PC` + 8 chars, row created |
| PE-P02 | `create` as child, then list the code | 200, `expires_at` ≈ +10 min |
| PE-P03 | `create` 11 times in an hour | 429 `rate_limited` after the 10th |
| PE-P04 | `redeem` an expired code | 400 `invalid_code`, body identical to an unknown code |
| PE-P05 | `redeem` a code whose child is already linked to F, as parent in F | 409 `child_already_linked` |
| PE-P06 | `redeem` a code whose child is already linked to G, as parent in F | 400 `invalid_code` (uniform) |
| PE-P07 | `invite` with a malformed Child ID | 400 `invalid_code`, and **one** attempt recorded |
| PE-P08 | `invite` 11 times for one child in 24 h | 429 with `retry_after_seconds` |
| PE-P09 | `unlink` as child for self | 200, devices revoked |
| PE-P10 | `unlink` as parent for a child in their family | 200 |
| PE-P11 | `unlink` as parent for a child in another family | 403 |
| PE-P12 | `cancel` another family's request | 403 |
| PE-P13 | 6 failed redeems inside 10 min, same parent | 429 on the 6th |

### `auth-bootstrap`

| ID | Case | Expected |
| --- | --- | --- |
| PE-A01 | `set_role` as U → parent | 200, audit `role_set` |
| PE-A02 | `set_role` again as U → child | 409 `role_already_set` |
| PE-A03 | `set_role` as X (unverified) | 403 `email_not_verified` |
| PE-A04 | `create_family` as A twice | 409 `family_exists` |
| PE-A05 | `create_family` as K (child) | 403 `role_required` |
| PE-A06 | `set_role` with `role:"admin"` | 400 `validation_error` |

### `device-command`

| ID | Case | Expected |
| --- | --- | --- |
| PE-C01 | `create` as A for D1, `apply_policy` | 200, policy version incremented, two audit rows |
| PE-C02 | `create` as A for D2 | 403 |
| PE-C03 | `create` with `ttl_seconds: 10` | clamped to 60 |
| PE-C04 | `poll` as D1 | commands for D1 only |
| PE-C05 | `poll` as D1 with a forged `device_id` in the body | body ignored; D1's commands returned |
| PE-C06 | `ack` a command belonging to D2 | 404 `command_not_found` |
| PE-C07 | `ack` with `status:"unknown"` | 400 `validation_error` |
| PE-C08 | `ack` a command whose `expires_at` has passed | 410 `command_expired`, row moved to `expired` |
| PE-C09 | `create` with an unknown `type` | 400 |

### `device-register`

| ID | Case | Expected |
| --- | --- | --- |
| PE-R01 | `register` as K for D-new in F | 200, response has no `secret_hash`, no `installation_id` |
| PE-R02 | `register` as K with a foreign `family_id` | 403 |
| PE-R03 | `register` the same installation id twice | 200 re-credential, audit `device_recredentialed` |
| PE-R04 | `register` an installation id belonging to M | 409 `device_exists` |
| PE-R05 | `register` when R1 was revoked after a later approved pairing | 403 `device_registration_blocked` |
| PE-R06 | `register` with `secret_hash: "abc"` | 400 (must be 64 hex) |
| PE-R07 | `register` with `action: "other"` | 400 `unknown_action` |

### `device-policy`

| ID | Case | Expected |
| --- | --- | --- |
| PE-PL01 | valid policy as A for D1 | 200, version increments |
| PE-PL02 | unknown policy key | 400 `... is not allowed` |
| PE-PL03 | `app_rules` 101 items | 400 |
| PE-PL04 | policy > 256 KB | 400 `policy is too large` |
| PE-PL05 | same `idempotency_key` twice | 200 `idempotent` on the second, no duplicate audit |
| PE-PL06 | bedtime start without end | 400 |
| PE-PL07 | `device_id` of D2 | 403 |

### `device-telemetry`

| ID | Case | Expected |
| --- | --- | --- |
| PE-T01 | `heartbeat` battery 50 | 200, `pending_policy_version` present |
| PE-T02 | `heartbeat` battery 101 | 400 |
| PE-T03 | `heartbeat` battery 5, twice in 6 h | one `low_battery` alert |
| PE-T04 | `usage_upload` with `day` tomorrow+2 days | 400 `cannot be in the future` |
| PE-T05 | `usage_upload` duplicate `(day, package)` in one batch | 400 duplicate error |
| PE-T06 | `location_upload` lat 91 | 400 |
| PE-T07 | `location_upload` `recorded_at` 8 days ago | 400 `older than seven days` |
| PE-T08 | `location_upload` `recorded_at` +10 min | 400 `too far in the future` |
| PE-T09 | `apps_upload` with 501 apps | 400 |
| PE-T10 | `apps_upload` twice | second replaces the snapshot; no duplicate rows |
| PE-T11 | any action with D2's id but D1's secret | 401 |
| PE-T12 | 100 `location_upload` in 60 s | currently **all accepted** (E7 baseline) |

### `family-admin`

| ID | Case | Expected |
| --- | --- | --- |
| PE-F01 | `revoke_device` as A for D1 | 200, D1 revoked, credential nulled |
| PE-F02 | `revoke_device` as C for D1 | 403 |
| PE-F03 | `recover_device` as A for D1 | 200, `recovery: started`, audit `device_recovery_started` |
| PE-F04 | `ack_alert` for an alert in another family | 403 |
| PE-F05 | `purge_data` with `older_than_days: 1` while retention is 30 | cutoff floored at 30 (nothing recent deleted) |
| PE-F06 | `update_retention` as B (parent, not owner) | 403 `owner_required` |
| PE-F07 | `update_retention` as A with `location_days: 0` | 400 |

### `remote-session`

| ID | Case | Expected |
| --- | --- | --- |
| PE-S01 | full happy path: request → accept → start → ice → end | 200 at each step, audit rows for requested/accepted/started/ended |
| PE-S02 | `respond` accept twice | second 200, no second audit transition |
| PE-S03 | `respond` decline then accept | 409 `session_not_open` |
| PE-S04 | `start` after expiry | 410 `session_expired`, row moved to `expired` |
| PE-S05 | `ice` before consent | 409 `session_not_open` |
| PE-S06 | `ice` as a non-participant | 403 |
| PE-S07 | `end` as parent, then as child | both 200 idempotent |
| PE-S08 | two `request` calls in a row for D1 | **currently both succeed** (E4 baseline) |
| PE-S09 | `request` with `kind:"screen"` | 400 |
| PE-S10 | `pending_child` as K with 60 seeded pending rows | at most 50 returned |

### `cron`

| ID | Case | Expected |
| --- | --- | --- |
| PE-CR01 | valid secret, `expire_sessions` | 200 `{expired_sessions: n}` |
| PE-CR02 | valid secret, `detect_offline` | 200 `{alerts_created: n}` |
| PE-CR03 | wrong secret | 401 |
| PE-CR04 | missing header | 401 |
| PE-CR05 | secret of 15 characters configured | 503 `cron_not_configured` |
| PE-CR06 | `action:"drop_everything"` with a valid secret | 400 `unknown_action` |
| PE-CR07 | `OPTIONS` from any origin | 200 with `Access-Control-Allow-Origin: *` (E9 baseline) |

## 4. Concurrency and abuse cases

| ID | Case | Method | Expected |
| --- | --- | --- | --- |
| CI-01 | Pairing limit overshoot | 10 parallel failed redeems for one parent | count ≤ 10 today; exactly 5 after E8 |
| CI-02 | Double redemption of one code | two parents, same code, parallel | at most one request row; the other 409 |
| CI-03 | Simultaneous `respond` from the same child | two parallel accepts | one transition, one idempotent 200 |
| CI-04 | Simultaneous `start` | two parallel starts | one 200, one 200-idempotent or 409 |
| CI-05 | Duplicate `create` with one idempotency key | 5 parallel | exactly one command row |
| CI-06 | `ack` race | 2 parallel acks | one state change, both return the same row |
| CI-07 | Replay of a captured cron request | same bytes after 10 min | **currently 200** (E12 baseline); 401 after fix |

## 5. Result recording

For each executed case record: case id, project ref, timestamp, request id, HTTP status, `error.code`, whether an audit
row was created and with which actor, and a one-line verdict (`PASS` / `FAIL` / `BLOCKED`). Do not record tokens.

A case is only `PASS` when the **observed** behaviour matches the expected column **and** the expected column was not
itself derived from the same source being tested. Where a case exercises a fix that has not been applied, the verdict is
`BLOCKED — FIX NOT APPLIED`, not `PASS`.

## 6. What this plan deliberately does not do

- No denial-of-service or volume testing beyond the small bursts needed to observe a 429.
- No attempt to brute-force a real pairing code.
- No testing of `private` schema exposure on production; TE-02 exists only for a scratch project where exposure can be
  reversed.
- No load testing of telemetry: the Android client's real cadence is unknown, and a synthetic load would not represent
  it.
