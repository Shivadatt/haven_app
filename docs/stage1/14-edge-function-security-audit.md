# 14 — Edge Function security audit

Status: **`PARTIAL — SOURCE REVIEWED, NOTHING EXECUTED`**.
Phase E, 2026-10-30. Scope: all nine deployed Edge Functions and all six shared modules, read from the dashboard
([capture-20261030.json](evidence/edge-functions/capture-20261030.json)). No request was made against any endpoint, no
function was invoked, no SQL ran.

Label key: **VERIFIED** (read in deployed source), **INFERRED** (follows from the source but a step was not observed),
**NOT VERIFIED**, **NOT TESTED**, **PROPOSED — NOT APPLIED**.

Reading guide: this document is the check-by-check analysis. Finding records with severity, remediation, rollback and
verification tests are in [16-phase-e-findings.md](16-phase-e-findings.md); identifiers `E1`–`E14` below refer to that
register. Inventory and provenance are in [13-edge-function-source-inventory.md](13-edge-function-source-inventory.md).

## 0. Headline

**No client-reachable authentication or authorisation bypass was found in the reviewed source.** Every user-facing path
derives the actor from the verified JWT, every family-scoped path derives the family from a device row or asserts
membership, and every device path proves possession of a secret. That is a materially better result than the Stage 1
source-form scan could support.

What the review did find is concentrated in two places:

1. **The SQL tier does not authorise its own arguments.** All three actor-taking RPCs trust the actor they are given
   ([F7](11-remediation-proposals.md#f7--actor-identity-is-taken-from-an-argument-not-from-authuid), now confirmed on
   the Edge side too). Today that is contained by `EXECUTE` grants and Data API exposure, not by the functions. One of
   the three, `public.request_remote_session`, has **no authorisation check whatsoever** on its parent argument.
2. **Consent and abuse controls are uneven.** Pairing is carefully limited; sessions and telemetry are not. The
   remote-session handler also bypasses the database's own single-session invariant because it inserts directly instead
   of calling the RPC that enforces it.

There is no evidence of a live exploit. There is also no runtime evidence of anything: every verdict below is
source-derived.

## 1. Per-endpoint verdict

Columns: authentication (checks 1–2), role (4), scope (5–6), input (10), abuse (7, 11, 16), error/audit/secret
(14–15, 17). `PASS` = every applicable check VERIFIED; `PASS*` = VERIFIED with a noted weakness that is not a bypass;
`PARTIAL` = at least one applicable check is INFERRED or has a gap other than a bypass.

| Endpoint | Auth | Role | Scope | Input | Abuse | Error/audit | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `pairing` | PASS | PASS | PASS | PASS | PASS* (E5, E6, E8) | PASS | **PASS** |
| `auth-bootstrap` | PASS | PASS | PASS | PASS | PASS* (E7) | PASS | **PASS** |
| `device-command` | PASS | PASS | PASS | PASS | PASS* (E7, E11) | PASS | **PASS** |
| `device-register` | PASS | PASS | PASS | PASS | PASS* (E7, E10) | PASS | **PASS** |
| `device-policy` | PASS | PASS | PASS | PASS | PASS* (E7) | PASS | **PASS** |
| `device-telemetry` | PASS (device) | n/a | PASS | PASS | PARTIAL (E7, E13) | PASS | **PARTIAL** |
| `family-admin` | PASS | PASS | PASS* (E-infra) | PASS | PASS* (E7) | PASS | **PASS** |
| `remote-session` | PASS | PASS | PASS | PASS | PARTIAL (E4, E7) | PASS | **PARTIAL** |
| `cron` | PASS (secret) | n/a | n/a | PASS | PASS* (E12) | PASS | **PASS** |

`family-admin` scope is `PASS*` because `revoke_device` delegates its only authorisation to `private.revoke_device`,
whose body is one of the 24 unread implementations. The delegation is confirmed; the check itself is **NOT VERIFIED**.
`recover_device` is fully VERIFIED because that body was read in B3b and asserts an active parent of the device's family.

## 2. The seventeen checks

### Check 1 — JWT signature and expiry validation

**VERIFIED** for the seven user-JWT endpoints. All of them call `requireUser(req, db, …)`, which extracts the bearer
token with `/^Bearer\s+(\S+)$/i` and a minimum length of 20 (`_shared/auth.ts:68-75`), then validates it with
`db.auth.getUser(token)` (`_shared/auth.ts:92`). Signature, expiry and revocation are decided by the Auth server, not by
local decoding. A network failure is converted to `401 unauthorized`, so the path fails closed (`_shared/auth.ts:93-104`).

The same logic is inlined identically in `device-command`, `device-register`, `device-policy`, `family-admin` and
`remote-session` (the `ApiError` class, profile load and `email_confirmed_at` gate are byte-similar in each bundle;
**INFERRED** identical behaviour, **VERIFIED** presence).

`device-telemetry` and `cron` do not accept a JWT at all; they are covered by checks 6 and 17.

**NOT TESTED**: no token was presented, expired or otherwise.

### Check 2 — user identity comes from the verified JWT

**VERIFIED.** In every user-JWT endpoint the acting id is `auth.user.id` (or the minified equivalent `o.user.id`,
`i.user.id`, `s.user.id`), never a body field. Role and email verification are read from the profile row and from
`email_confirmed_at` on the Auth user object respectively, both server-side.

`requireUser` also rejects an unknown role value (`_shared/auth.ts:123-127`) and a missing profile with
`403 profile_missing`, so a user whose profile row was deleted cannot act as `unset`.

### Check 3 — never trust actor IDs supplied in request bodies

**VERIFIED at the Edge tier**; **FAILS at the SQL tier** (finding [E3](16-phase-e-findings.md#e3)).

Every RPC that takes an actor argument is called with the JWT subject:

| Call site | Argument | Source |
| --- | --- | --- |
| `pairing` → `create_pairing_request` | `p_parent_user_id` | `pairing/index.ts:671` = `auth.user.id` |
| `pairing` → `create_pairing_invite` | `p_parent_user_id` | `pairing/index.ts:381` = `auth.user.id` |
| `pairing` → `respond_pairing_request` | `p_child_user_id` | `pairing/index.ts:820` = `auth.user.id` |
| `pairing` → `unlink_child` | `p_actor_user_id` | `pairing/index.ts:945` = `auth.user.id` |
| `auth-bootstrap` → `create_family_with_owner` | `p_owner` | `auth-bootstrap/index.ts:112` = `auth.user.id` |
| `device-command` → `apply_policy_version` | `p_actor` | bundle (`create`, `apply_policy` branch) = `o.user.id` |
| `device-policy` → `apply_policy_version` | `p_actor` | bundle = `o.user.id` |
| `family-admin` → `revoke_device` | `p_actor_user_id` | bundle = `i.user.id` |
| `family-admin` → `request_device_recovery` | `p_actor_user_id` | bundle = `i.user.id` |

Target identifiers (`device_id`, `alert_id`, `session_id`, `child_user_id` on unlink) do come from the body. Each one is
resolved and scoped before use: the device is loaded and its family checked, the alert's family is checked, the session's
participants are checked, and the unlink target must be a child in a family the caller parents.

The body is never allowed to name the **actor**. Where the body names a target, the actor's authority over that target
is established separately. That is the correct pattern, and it is applied consistently across all nine functions.

### Check 4 — parent/child role enforcement

**VERIFIED** everywhere.

| Endpoint | Rule |
| --- | --- |
| `pairing` | `create`/`get_contact_id`/`pending_child`/`respond` → child; `redeem`/`invite`/`cancel`/`list_family` → parent; `unlink` → child acting on itself, or parent |
| `auth-bootstrap` | `set_role` is self-service from `unset` only; `create_family` → parent |
| `device-register` | child, plus active child membership |
| `device-policy` | parent |
| `device-command` | `create` → parent; `poll`/`ack` → device credential |
| `family-admin` | parent for all five actions; `update_retention` also `owner_required` |
| `remote-session` | `request` → parent; `pending_child`/`respond`/`start` → child; `end`/`ice` → participant |

Role comes from `profiles.role` read with the service-role client, so it cannot be influenced by a client-supplied claim
or by a stale JWT claim. `requireRole` compares exactly, so `unset` fails closed (`_shared/auth.ts:139-149`).

### Check 5 — family membership and cross-family isolation

**VERIFIED** for user-facing paths.

- Family id is either asserted from the body (`assertFamilyParent` / `assertChildMembership`, both of which first assert
  the family exists and is not soft-deleted, `_shared/auth.ts:151-196`) or derived from a row the caller has already been
  checked against.
- `assertFamilyParent` requires `family_members.status = 'active'` **and** `role = 'parent'` in that family. A parent of
  family A holds no implied authority in family B.
- Device-scoped endpoints derive `family_id` from the device row and then assert parent membership in that family
  (`requireActiveDeviceForParent`, `_shared/auth.ts:266-289`). The body never supplies the family on those paths.
- `remote-session` loads the session and requires `parent_user_id === caller` or `child_user_id === caller` before `end`
  and `ice`. `respond` and `start` require `child_user_id === caller`.

The one soft spot is structural, not per-handler: because every handler runs as `service_role`, RLS cannot catch a missed
predicate. The review therefore checked every query by hand. All writes carry a scope predicate: `eq(id, caller)`,
`eq(family_id, asserted)`, `eq(device_id, authenticated device)` or `eq(child_user_id, caller)`.

### Check 6 — device ownership

**VERIFIED** for `device-command`, `device-policy`, `remote-session` (`requireActiveDeviceForParent`), `family-admin`
`recover_device` (RPC body asserts active parent of the device's family), and `device-register` (installation id is
looked up **within** the asserted family; a row belonging to another child returns `409 device_exists`).

`family-admin revoke_device` is **NOT VERIFIED** at the handler level: the handler only checks that the caller is a parent
somewhere, and `private.revoke_device` (unread body) must perform the family check. The grant data shows it is only
callable by `postgres`/`service_role`, so the only route is this handler.

Device authentication itself is sound: `requireDevice` (`_shared/auth.ts:295-338`) requires both headers, rejects a
non-UUID id or a secret outside 16–512 chars, hashes the presented secret with SHA-256 and compares with a
length-constant-time routine, and refuses `status != 'active'` or a non-null `credential_revoked_at`. When the device
row or hash is missing it still performs a comparison against a zero digest so that unknown ids and wrong secrets cost
the same (`_shared/auth.ts:325-330`).

### Check 7 — pairing code expiry, reuse and attempt limits

**VERIFIED** except for the single-use mechanism, which is **INFERRED**.

- Lifetime 10 minutes (`pairing/index.ts:41`, applied at `:480`).
- Expired or non-active rows are rejected with the same `INVALID_IDENTIFIER` body as an unknown code, and an expired row
  is transitioned to `expired` under an `.eq(status,"active")` guard (`:585-599`).
- Codes are 8 characters from a 30-symbol alphabet, generated with `crypto.getRandomValues` and rejection sampling
  (`_shared/validation.ts:293-315`). Search space is 30⁸ ≈ 6.6 × 10¹¹.
- Attempt limits: 5 failed per parent and 10 failed per identifier in a rolling 10 minutes, checked before the lookup
  (`:567`, `_shared/rate_limit.ts:54-93`). Failed attempts are recorded on every failure branch.
- Inbound invites: at most 3 pending and 10 per 24 h per child (`_shared/rate_limit.ts:153-211`).
- Creation: at most 5 live codes per 24 h and 10 creations per hour (`_shared/rate_limit.ts:110-151`).

**Single use is INFERRED, not VERIFIED.** The handler looks up an existing `pairing_requests` row by `token_id`
(`:628-632`, a `.maybeSingle()` read that implies uniqueness) and treats a second redemption as `409 code_unavailable`.
Concurrent redemption is delegated to `private.create_pairing_request`, which returns `code_unavailable`; the handler
maps that error (`:675-687`) and revokes the token on the "already exists" path (`:709-714`). The 24 unread implementations
include `private.create_pairing_request`, so the row-level lock or unique constraint that makes this airtight was not read.

### Check 8 — remote-session consent and authorisation

**VERIFIED** for the consent chain; **PARTIAL** for containment.

The chain is correct and enforced at each step:

1. `request` (parent, verified email, active device in a family the caller parents) inserts a row with
   `parent_user_id` = JWT subject, `child_user_id` = the device's owner, `status = 'requested'`, `consent_recorded =
   false`, `expires_at = now + 10 min`.
2. `respond` is child-only and requires `session.child_user_id === caller`. Accepting sets `consent_recorded = true`,
   a fresh `session_nonce` and `expires_at = now + 30 min`; declining ends the session.
3. `start` is child-only and refuses unless `status = 'accepted'` **and** `consent_recorded` is true.
4. `ice` requires `status ∈ {accepted, active}` **and** `consent_recorded`; TURN credentials are minted per caller with
   an expiry bounded to 60–86400 s.

A parent can never start, accept, or obtain ICE for a session the child has not accepted. That is the property that
matters for a monitoring product, and it holds in the source.

Containment gaps: the handler inserts into `remote_sessions` directly instead of calling `public.request_remote_session`,
so the RPC's advisory lock and "no other live session for this device" check never run ([E4](16-phase-e-findings.md#e4)); and `request` has no
rate limit ([E7](16-phase-e-findings.md#e7)). The effect is stacked pending requests and an inflated consent inbox, not unauthorised access.

### Check 9 — session state transitions

**VERIFIED.** Two independent layers:

- Handler-side compare-and-set: every transition writes with `.eq("id", …).eq("status", <required predecessor>)` and
  treats "no row returned" as `409 session_not_open` (`respond`, `start`, `end` in the bundle). Replays are idempotent: an already
  `accepted` session returns 200 for a repeated accept, and an already-terminal session returns 200 for a repeated end.
- Database-side guard: `private.remote_session_transition_guard` raises `session_terminal` when a row moves from
  `declined|ended|expired|failed` back to `requested|accepted|active` (body read in B3b).

The guard is a `BEFORE UPDATE` trigger on `remote_sessions`; it does not constrain `INSERT`, which is why E4 exists.

### Check 10 — input schema validation

**VERIFIED** and consistently strong:

- Request envelope: `POST` only, JSON object only, 512 KB cap enforced on both the declared `content-length` and the
  actual text, `action` length 1–64 (`_shared/envelope.ts:77-110`).
- Typed readers for string / optional string / boolean / integer / number / UUID / 64-hex / enum / array, each with
  bounds and a fixed message (`_shared/validation.ts:58-215`).
- Strict key allowlists: policy objects reject unknown keys (`policy.<key> is not allowed`), command payloads are
  allowlisted per command type, app-rule and window objects are allowlisted.
- Size and count caps everywhere they matter: policy JSON 256 KB, `app_rules` 100, package arrays 200, telemetry batches
  500, command `result` 32 KB, `custom` payload 64 KB, error text truncated to 500 chars.
- Semantic bounds: battery 0–100, latitude ±90, longitude ±180, accuracy 0–100 000 m, screen-time 1–1440 min, minute
  values 0–1439, weekday 1–7 with duplicate rejection, real-calendar-date check, timestamps bounded to −7 d … +5 min
  (location) and ≤ +36 h (usage day).

Two judgement calls worth recording: `device-command`'s `custom` payload is validated only as "object ≤ 64 KB", which is
deliberate but means its schema is opaque to the server; and `secret_hash` is accepted from the client ([E10](16-phase-e-findings.md#e10)).

### Check 11 — rate limiting

**PARTIAL.** Present and well designed for pairing (see check 7). Absent for `remote-session.request`,
`device-command.create`, `device-policy`, `device-register`, `family-admin`, `auth-bootstrap` and all four telemetry
actions — **VERIFIED absent**, in the sense that no counter table, no attempt table and no quota helper appears anywhere
in those bundles. Finding [E7](16-phase-e-findings.md#e7).

The exposure differs by caller: telemetry and command endpoints require a device secret, so abuse implies a compromised
device; `remote-session.request` and `device-command.create` require a legitimate parent, so abuse is self-directed at
one's own family but still consumes database and notification capacity.

### Check 12 — service-role usage and privilege boundaries

**VERIFIED — every function uses the service-role key, therefore RLS never applies.** This is the single most important
architectural fact in this audit.

- The key is read from `Deno.env` at first use and cached; a missing value throws `503 server_misconfigured`
  (`_shared/auth.ts:51-56`). It is never returned, never logged, and never placed in a response.
- The client is created with `persistSession: false` and `autoRefreshToken: false`, so no session state leaks between
  invocations of the same isolate.
- Because the key bypasses RLS, every handler is a trust boundary. The mitigation is that all queries are explicitly
  scoped (check 5) and the service client is never exposed to a device or user.
- The device-facing responses strip credential material: `device-register` deletes `secret_hash` and `installation_id`
  from the returned row before responding.

### Check 13 — CORS and origin handling

**VERIFIED, with a weakness** ([E9](16-phase-e-findings.md#e9)). `_shared/cors.ts` returns `Access-Control-Allow-Origin: *` and allows the
headers `authorization, x-client-info, apikey, content-type, x-device-id, x-device-secret, x-cron-secret`. All nine
bundles inline the same object.

Consequences: any web origin may call any function and read the response **if** it can obtain a bearer token or device
secret. There are no cookies and no ambient credentials in this design, so the wildcard does not by itself create
cross-site request forgery; it does remove origin as a defence-in-depth signal and it advertises the internal header
names, including `x-cron-secret`, to any reader. Preflight (`OPTIONS`) is answered `200` by every function, including
`cron`, before any authentication.

### Check 14 — error responses do not expose database internals

**VERIFIED.** Three layers:

- `errorResponse` returns the curated `ApiError` message for expected failures and, for anything else, logs only
  `error.name` and returns `500 internal_error` with a fixed sentence (`_shared/envelope.ts:63-73`).
- `ensureNoError` logs only `error.code` and throws a generic 500 with a caller-supplied message
  (`_shared/envelope.ts:104-111`).
- RPC failures are mapped by substring to fixed messages (`device-policy`, `device-command`, `family-admin`) and
  otherwise become a generic 500; the RPC's own message is never returned to the client.

One path throws a raw PostgREST error object (`device-register`, insert failure that is not `23505`). It is still safe
because the top-level handler only ever returns the fixed 500 body, but it is inconsistent with the rest of the codebase.

`Cache-Control: no-store` is set on every JSON response.

### Check 15 — audit records cannot be forged by a client

**VERIFIED at the boundary, architecture-dependent underneath.**

- Clients cannot write `audit_logs`: the table is not exposed through the Data API (0 of 19 tables), and the append-only
  trigger rejects `UPDATE`/`DELETE` for non-privileged callers (body read in B3b).
- Only handlers write audit rows, through `recordAudit`, with `actor_user_id` taken from the JWT subject.
- A failed insert fails the request (`500 audit_failed`), so an action cannot silently succeed unaudited
  (`_shared/audit.ts:28-37`).
- Device-originated events are recorded with a null `actor_user_id` and a populated `device_id`, which distinguishes them
  from user actions.

Residual: the actor is a value the handler supplies, not something the database derives. A defect in a handler, or a
future handler that forwards a body value, produces a false audit trail — exactly the failure mode described in F7. See
[E3](16-phase-e-findings.md#e3) and [E14](16-phase-e-findings.md#e14). Also note `device-telemetry` writes no audit rows at all ([E13](16-phase-e-findings.md#e13)).

### Check 16 — idempotency and retry safety

**VERIFIED** for most write paths:

- `device-command create`: client `idempotency_key` (1–128 chars) is looked up before insert, `23505` falls back to a
  re-read, and `apply_policy` delegates to `apply_policy_version`, whose response carries `idempotent`.
- `device-command ack`: terminal commands are returned rather than re-applied; the update is guarded by
  `.in(status, [pending, delivered])`; a lost race re-reads and returns the current row.
- `device-telemetry`: `usage_daily` upserts on `(device_id, day, package_name)`; `safe_zone_states` upserts on
  `(zone_id, device_id)`; `apps_upload` replaces the whole snapshot; `heartbeat` is a last-writer-wins update.
- `pairing respond`, `remote-session respond` and `remote-session start` are idempotent for repeated identical requests.
- `family-admin purge_data` is naturally idempotent (cutoff-based delete).

Not idempotent: `location_events` is a plain insert, so a retried location upload creates duplicate points. Effect is
data quality, not access control. Recorded as a note, not a finding.

### Check 17 — cron authentication and secret handling

**VERIFIED.** `cron` refuses to run at all if `CRON_SECRET` is missing or shorter than 16 characters (`503
cron_not_configured`), rejects a missing or mismatched `x-cron-secret` with `401`, and compares by hashing both sides
with SHA-256 and running a length-constant-time comparison over the hex digests. That avoids the length leak a naive
`===` would have.

Weaknesses ([E12](16-phase-e-findings.md#e12)): the secret is static, sent on every request, and has no timestamp or nonce, so a captured
request can be replayed until the secret rotates; there is no IP or origin restriction; and the endpoint answers CORS
preflight for any origin. Actions are idempotent maintenance RPCs, so replay has low impact.

## 3. Positive controls worth keeping

These are not findings; they are the parts of the design that a future change should not regress.

| Control | Where |
| --- | --- |
| Uniform `INVALID_IDENTIFIER` for unknown / expired / malformed codes | `pairing/index.ts:571, 583, 598, 625, 773` |
| Child-ID-vs-code routing on format, so neither path is an oracle for the other | `pairing/index.ts:555-560` |
| No actor id ever read from a request body | all nine |
| Constant-time secret comparison for device and cron secrets | `_shared/validation.ts:355-375`, `cron` bundle |
| Consent recorded before ICE is issued, and `start` requires consent | `remote-session` bundle |
| Compare-and-set on every session transition, plus a DB trigger for terminal states | `remote-session` bundle; `private.remote_session_transition_guard` |
| Audit failure fails the request | `_shared/audit.ts:28-37` |
| Credential material stripped from responses | `device-register` bundle (`H()`) |
| Body size cap enforced twice (declared and actual) | `_shared/envelope.ts:78-92` |
| Generic 500 with name-only logging | `_shared/envelope.ts:63-73` |
| Policy and payload allowlists with explicit "not allowed" errors | `device-policy`, `device-command` bundles |

## 4. F7 and F8 — resolution

### F7 — actor identity from an argument

**Edge tier: CLOSED.** Every call site passes the verified JWT subject (table in check 3). No handler forwards a
body-supplied actor. This was the open question Phase E was asked to answer, and the answer is unambiguous.

**SQL tier: OPEN, unchanged.** The three actor-taking implementations still trust their argument:

- `private.request_device_recovery` requires the argument to be **some** active parent of the device's family, not the
  caller.
- `private.unlink_child` requires the argument to be the child itself or an active parent of the supplied family.
- `public.request_remote_session` checks neither the parent nor the caller: it writes `p_parent_user_id` straight into
  `remote_sessions`.

Because Edge Functions reach these as `service_role`, the argument is always correct in practice. The defect is only
reachable if the RPCs become callable by a user role. Finding [E3](16-phase-e-findings.md#e3); concrete consequences [E1](16-phase-e-findings.md#e1) (no check at
all in `request_remote_session`) and [E2](16-phase-e-findings.md#e2) (PUBLIC EXECUTE).

Worth stating plainly because it changes the F8 severity: the in-body family check does **not** authenticate the caller.
If `private.request_device_recovery` became reachable, a caller who knew a device id and the user id of any parent in
that family could pass that parent as `p_actor_user_id`, satisfy the family check, and force an unlink — a cross-family
destructive action plus a forged audit row. The id knowledge is the only obstacle, and parent user ids are not secret:
`device-command poll` returns full command rows including `created_by` to the child's device.

### F8 — exposure of the `private` schema

Current state, re-confirmed against the B3b capture:

| Fact | Value | Status |
| --- | --- | --- |
| Data API exposed schemas | `public`, `extensions` (3 offered, `private` not selected) | VERIFIED (rendered setting) |
| Tables exposed | 0 of 19 | VERIFIED (rendered setting) |
| Functions exposed | 0 of 38 | VERIFIED (rendered setting) |
| `authenticated` USAGE on `private` | **true** | VERIFIED (`schema_usage`) |
| `anon` USAGE on `private` | false | VERIFIED (`schema_usage`) |
| `private.request_device_recovery` ACL | `NULL` → default `PUBLIC EXECUTE` | VERIFIED (`inventory`) |
| `private.remote_session_transition_guard` ACL | `NULL` → default `PUBLIC EXECUTE` | VERIFIED (`inventory`) |

Consequence if `private` were added to the exposed schema list, with no other change:

1. `private.request_device_recovery` becomes callable at `/rest/v1/rpc/request_device_recovery` by **any authenticated
   user**, with an attacker-chosen `p_actor_user_id` — the E2/F7 scenario above.
2. `private.remote_session_transition_guard` also becomes callable, but PostgreSQL refuses direct invocation of a
   `trigger`-returning function, so its practical exposure is negligible.
3. The other 22 `private` functions remain unreachable because they are `postgres=X,service_role=X`; `authenticated`
   holds schema USAGE but no function EXECUTE.

The barrier is therefore **one configuration change plus one grant that already exists**, not two. That is why E2 is
rated High-latent rather than Low. No change was made; the remediation is `REVOKE EXECUTE … FROM PUBLIC` plus an explicit
`GRANT … TO service_role` (Stage 1 [F8](11-remediation-proposals.md#f8--two-private-functions-keep-the-default-public-execute)).

Function bodies were not modified, and no `REVOKE`, `GRANT` or `ALTER FUNCTION` was executed.

## 5. What this audit does not establish

| Gap | Why | Status |
| --- | --- | --- |
| Runtime behaviour of the deployed bundles | no request was made | **NOT TESTED** |
| 24 of 38 SQL bodies, including `private.revoke_device`, `private.create_pairing_request`, `private.create_pairing_invite`, `private.poll_device_commands` | out of scope for Phase E (PA3) | **NOT VERIFIED** |
| Whether `PAIRING_HASH_PEPPER`, `CRON_SECRET`, `TURN_SECRET` are set in production | environment values not read | **NOT VERIFIED** |
| Whether the Android client generates a high-entropy device secret | client source unavailable | **NOT VERIFIED** |
| Data API toggle semantics | rendered settings only, no request made | **INFERRED** |
| Bundle-to-source equivalence | no source maps | **INFERRED** |
| Any bypass via a path not exercised | source review cannot prove absence | open |

## 6. Finding index

| ID | Title | Severity | Live today |
| --- | --- | --- | --- |
| [E1](16-phase-e-findings.md#e1) | `public.request_remote_session` authorises nothing | Medium latent | No |
| [E2](16-phase-e-findings.md#e2) | `private.request_device_recovery` PUBLIC EXECUTE + trusted actor | High latent | No |
| [E3](16-phase-e-findings.md#e3) | SQL tier trusts actor arguments | Medium architectural | No |
| [E4](16-phase-e-findings.md#e4) | Remote-session path bypasses the single-session invariant | Low–Medium | Yes, contained |
| [E5](16-phase-e-findings.md#e5) | Pairing token hash is unsalted SHA-256 by design | Low | Yes |
| [E6](16-phase-e-findings.md#e6) | Pairing pepper falls back silently | Low | Depends on env |
| [E7](16-phase-e-findings.md#e7) | No rate limiting outside pairing | Low–Medium | Yes |
| [E8](16-phase-e-findings.md#e8) | Pairing limits are count-then-act | Low | Yes |
| [E9](16-phase-e-findings.md#e9) | Wildcard CORS with credential headers | Low | Yes |
| [E10](16-phase-e-findings.md#e10) | Device secret is chosen by the client | Low | Yes |
| [E11](16-phase-e-findings.md#e11) | Command rows expose `created_by` to devices | Info | Yes |
| [E12](16-phase-e-findings.md#e12) | Cron secret is static with no replay window | Low | Yes |
| [E13](16-phase-e-findings.md#e13) | Telemetry writes no audit rows | Low | Yes |
| [E14](16-phase-e-findings.md#e14) | Audit actor is application-supplied | Low | Yes |

Full records — evidence, preconditions, impact, remediation, compatibility, rollback, verification test — are in
[16-phase-e-findings.md](16-phase-e-findings.md).
