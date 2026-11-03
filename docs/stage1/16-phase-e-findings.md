# 16 — Phase E findings register

Status: **`OPEN — PROPOSED, NOT APPLIED`**. Every remediation below is a proposal. Nothing in this phase changed
production: no SQL, no DDL/DML, no `GRANT`/`REVOKE`/`ALTER FUNCTION`, no deployment, no configuration, no secret.

Labels: **VERIFIED** / **INFERRED** / **NOT VERIFIED** / **NOT TESTED** / **PROPOSED — NOT APPLIED**.

Severity is stated twice: the **latent** severity if the preconditions are met, and whether it is **live today**.
Evidence files: [capture-20261030.json](evidence/edge-functions/capture-20261030.json) for Edge source,
[g1-b3b-20261029.json](evidence/g1-b3b-20261029.json) for SQL bodies, grants and exposure. Analysis:
[14-edge-function-security-audit.md](14-edge-function-security-audit.md).

| ID | Title | Latent | Live today | Maps to |
| --- | --- | --- | --- | --- |
| E1 | `public.request_remote_session` authorises nothing | Medium | No | F7 |
| E2 | `private.request_device_recovery` PUBLIC EXECUTE + trusted actor | High | No | F8, F7 |
| E3 | SQL tier trusts actor arguments | Medium | No | F7 |
| E4 | Remote-session path bypasses the single-session invariant | Low–Medium | Yes (contained) | — |
| E5 | Pairing token hash is unsalted SHA-256 by design | Low | Yes | — |
| E6 | Pairing pepper falls back silently to SHA-256 | Low | Env-dependent | — |
| E7 | No rate limiting outside pairing | Low–Medium | Yes | — |
| E8 | Pairing limits are count-then-act | Low | Yes | — |
| E9 | Wildcard CORS with credential headers | Low | Yes | — |
| E10 | Device secret chosen by the client | Low | Yes | — |
| E11 | Command rows expose `created_by` to devices | Info | Yes | — |
| E12 | Cron secret static, no replay window | Low | Yes | — |
| E13 | Telemetry writes no audit rows | Low | Yes | — |
| E14 | Audit actor is application-supplied | Low | Yes | F7 |

No finding in this register is a client-reachable authentication or authorisation bypass **as deployed on 2026-10-30**.
E1, E2 and E3 are latent: they require a change to exposure or grants, or a future handler defect, to become reachable.
E4–E14 are contained weaknesses that a legitimate user can trigger within their own family.

---

<a id="e1"></a>

## E1 — `public.request_remote_session` performs no authorisation

**Evidence.** [g1-b3b](evidence/g1-b3b-20261029.json) `bodies` → `public.request_remote_session`. The body validates
`p_kind`, takes an advisory lock on the device, reloads the device, expires stale rows, refuses when another live session
exists, then inserts `remote_sessions` with `parent_user_id = p_parent_user_id` — the argument, verbatim. There is no
membership test, no `auth.uid()` comparison, and no check that the parent belongs to `v_device.family_id`.
**VERIFIED** by reading the captured body. In the same capture the function's ACL is `postgres=X,service_role=X`
(`anon_exec=false`, `auth_exec=false`), and the Data API exposes 0 of 38 functions — so there is no client route today.

**Severity.** Medium latent; not live.

**Exploit preconditions.** (1) `EXECUTE` granted to `authenticated` or `anon`, or `public` re-exposed with default
grants; (2) the function exposed through the Data API; (3) knowledge of a `device_id`. The parent id does not even have
to be real for the row to be written, which makes the forged attribution trivial.

**Actual impact.** A session request appears on a child's device attributed to a parent who did not ask for it, and the
audit trail records that parent. Because `start` still requires child consent and `consent_recorded`, this does not give
live audio/video access — it is a consent-integrity and audit-integrity defect, which in a safety product is serious on
its own.

**Proposed remediation (PROPOSED — NOT APPLIED).**

```sql
-- inside public.request_remote_session, before the advisory lock
if not exists (
  select 1 from public.family_members
  where family_id = (select family_id from public.devices where id = p_device_id)
    and user_id = p_parent_user_id
    and role = 'parent' and status = 'active'
) then
  raise exception 'forbidden' using errcode = '42501';
end if;
```

Plus the F7 identity guard (`auth.uid() is not null and p_parent_user_id is distinct from auth.uid() → actor_mismatch`).
Alternative: retire the function. It has **no first-party caller** — the deployed `remote-session` handler inserts into
the table directly (**VERIFIED** in the bundle).

**Compatibility concerns.** No Edge Function calls it. Whether an older client build calls the RPC directly cannot be
determined from this repository; check the function's invocation logs before dropping it. Adding the check is
backwards-compatible for any legitimate caller.

**Rollback plan.** `create or replace function` with the captured body, which is stored verbatim in `g1-b3b`. Reverting
is safe because the function is unused by the current server path.

**Verification test.** Staging only. As user `C` (not a member of family `F`), with `EXECUTE` granted to `authenticated`,
call `rpc/request_remote_session` with `p_device_id` of `F` and `p_parent_user_id` of a parent of `F` → expect
`42501 forbidden` after the fix; before the fix, a `requested` row is returned. Then as a real parent of `F` → 200.

---

<a id="e2"></a>

## E2 — `private.request_device_recovery` keeps PUBLIC EXECUTE and trusts its actor

**Evidence.** `g1-b3b` `inventory` → `private.request_device_recovery` has `acl = null` and therefore `anon_exec=true`,
`auth_exec=true` (PostgreSQL default `EXECUTE TO PUBLIC`). `schema_usage` shows `authenticated: true` on schema
`private`. `data_api_exposure` shows exposed schemas `public`, `extensions` — `private` is **not** exposed, and 0 of 38
functions are exposed. The body (read in B3b) checks only that `p_actor_user_id` is an active parent of the device's
family, then calls `private.unlink_child(family, child, p_actor_user_id)` and writes an audit row naming that actor.

**Severity.** High latent; not live. This is Stage 1 F8, restated with one sharper consequence (below).

**Exploit preconditions.** `private` added to the Data API exposed-schema list (one dashboard change), plus knowledge of
a `device_id` and of **any** parent's user id in that family. Both identifiers are exposed to a child device:
`device-command poll` returns full command rows including `created_by` (E11).

**Actual impact.** Forced unlink of a child: all their devices go to `revoked`, `secret_hash` is nulled, active sessions
end, pairing tokens and pending requests are cancelled — and the audit row attributes it to the parent whose id was
supplied. Cross-family, destructive, with a false audit trail. The in-body family check does not authenticate the
caller, so it does not prevent this. `private.remote_session_transition_guard` has the same NULL ACL but returns
`trigger`; PostgreSQL refuses direct invocation, so its practical exposure is negligible.

**Proposed remediation (PROPOSED — NOT APPLIED).**

```sql
revoke execute on function private.request_device_recovery(uuid, uuid) from public;
grant execute on function private.request_device_recovery(uuid, uuid) to service_role;
-- cosmetic, same file: pin the missing schema
alter function private.remote_session_transition_guard() set search_path = public, private, pg_temp;
```

plus the E3 identity guard so that exposure alone is not enough.

**Compatibility concerns.** Edge Functions connect as `service_role`, so they keep working. Any test harness that
impersonates `authenticated` to call this function will start failing — that is the intended signal. `proacl = NULL`
cannot be recreated by `GRANT`; rolling back restores equivalent privileges, not the exact original ACL.

**Rollback plan.** `grant execute on function private.request_device_recovery(uuid, uuid) to public;` restores the
current effective privilege. Body unchanged, so no body rollback is needed.

**Verification test.** Scratch project only. Add `private` to exposed schemas there, sign in as an unrelated user, POST
`/rest/v1/rpc/request_device_recovery` with a device of another family and a parent of that family → expect
`permission denied` (401/403) after the fix. Before the fix, expect a successful unlink (this is why the test must not be
run against production).

---

<a id="e3"></a>

## E3 — The SQL tier trusts actor arguments; only the Edge tier binds them

**Evidence.** [g1-b3b](evidence/g1-b3b-20261029.json) `bodies`:

- `private.request_device_recovery` — requires the actor to be *some* active parent of the device's family; no
  `auth.uid()` comparison.
- `private.unlink_child` — requires the actor to be the child or an active parent of the supplied family; no `auth.uid()`
  comparison.
- `public.request_remote_session` — no check at all (E1).

Edge side is clean: every call site passes the JWT subject (audit check 3, table of nine call sites). So the argument is
always correct **while the only caller is the Edge tier**.

**Severity.** Medium architectural; not live. It is the root cause behind E1 and E2.

**Exploit preconditions.** Any direct RPC route (grant or exposure change) or any future handler that forwards a
body-supplied actor. The second is the realistic one: the pattern is easy to copy by accident.

**Actual impact.** Within-family impersonation and a false audit trail; cross-family action where the function's family
check is satisfied by the forged actor (E2). For a parental-control product, a false audit trail is worse than no audit
trail, because a parent will rely on it after an incident.

**Proposed remediation (PROPOSED — NOT APPLIED).** Add the Stage 1 F7 guard to the top of every actor-taking body,
keeping the argument for service-role callers:

```sql
if auth.uid() is not null and <actor parameter> is distinct from auth.uid() then
  raise exception 'actor_mismatch' using errcode = '42501';
end if;
```

Apply to `private.request_device_recovery`, `private.unlink_child`, `public.request_remote_session`, and to each of the
remaining unread implementations as they are read (PA3). `private.record_audit` must be treated the same way even
though it is internal.

**Compatibility concerns.** `service_role` has `auth.uid() = NULL`, so every Edge Function path is unaffected. A client
calling directly is already blocked by the grant, so nothing that works today breaks.

**Rollback plan.** `create or replace` with the captured bodies. Two of the three are stored verbatim in `g1-b3b`; the
unread ones must be captured before they are changed, or no rollback text exists.

**Verification test.** Non-production, with a role granted `EXECUTE`. Set `request.jwt.claims` to user A; call
`request_device_recovery(device_of_A_family, B)` where B is another parent → `actor_mismatch`. Call with A → succeeds,
and the audit row actor equals the JWT subject.

---

<a id="e4"></a>

## E4 — The remote-session handler bypasses the single-session invariant

**Evidence.** `remote-session` bundle, `request` branch: after `requireActiveDeviceForParent` it inserts into
`remote_sessions` directly with `status: "requested"` and `expires_at = now + 10 min`. It performs **none** of the
guards that `public.request_remote_session` contains: no `pg_advisory_xact_lock`, no "existing live session for this
device" check (both **VERIFIED** in the RPC body in `g1-b3b`). `pending_child` will list up to 50 pending rows.

**Severity.** Low–Medium; live and containable by any parent, but only against their own family.

**Exploit preconditions.** An authenticated parent of the device's family simply calls `request` repeatedly.

**Actual impact.** A child's device can accumulate many pending consent prompts; two or more requests can be accepted
and started concurrently, producing simultaneous sessions, duplicate ICE issuance and an ambiguous `end`. It is a
consent-integrity and UX defect, not an authority escalation: each session still targets the child of that device.

**Proposed remediation (PROPOSED — NOT APPLIED).** Prefer calling `public.request_remote_session` from the handler once
E1/E3 are fixed — it already implements the lock and the invariant. If the direct insert must stay, add the lock and the
check in the handler **and** a database constraint:

```sql
create unique index remote_sessions_one_live_per_device
  on public.remote_sessions (device_id)
  where status in ('requested', 'accepted', 'active');
```

Precheck before creating the index: a partial unique index fails to build if existing rows violate it.

**Compatibility concerns.** The handler must translate the resulting 409 into an existing error shape; a client that
already stacks requests will start receiving `409 session_in_progress`. Index creation is DDL and needs the owner's
approval; it also needs a read-only duplicate count first.

**Rollback plan.** Drop the index; revert the handler to the current insert. Both are reversible.

**Verification test.** Staging: two sequential `request` calls for one device → first 201/200, second 409. Then five
parallel `request` calls → exactly one `requested` row.

---

<a id="e5"></a>

## E5 — Pairing token hashes are unsalted SHA-256 by design

**Evidence.** `pairing/index.ts:562-566`:

```
// Two digests on purpose: the token row keeps plain SHA-256 so codes
// issued before this change still redeem, while attempt records use
// the keyed digest so a database dump cannot recover the identifier.
const codeHash = await sha256Hex(normalized);
const attemptHash = await identifierHash(normalized);
```

Token rows are created with `sha256Hex(code)` (`:478`) and looked up by the same digest (`:574-578`).
`identifierHash` (`_shared/validation.ts:325-357`) is the only HMAC path.

**Severity.** Low.

**Exploit preconditions.** Read access to `device_pairing_tokens` — a database dump, a leaked backup, or a future
read-grant regression — plus the 10-minute validity window.

**Actual impact.** The identifier space is 30⁸ ≈ 6.6 × 10¹¹, so an offline attacker recovers a live code and can submit
it as a linking request into their own family. The child must still approve, and the request is visible to them. Effect:
an unsolicited, plausibly-worded linking request plus consumption of the code — not account or device access.

**Proposed remediation (PROPOSED — NOT APPLIED).** Switch the token column to the keyed digest with a dual-read window:
look up `identifierHash(code)` first, fall back to `sha256Hex(code)` for rows created before the cutover, and revoke all
legacy active codes at cutover so the fallback can be deleted afterwards.

**Compatibility concerns.** Create and redeem must change and deploy together; a split deploy makes every code minted
in between unredeemable. The client never sees the hash, so no client change is needed.

**Rollback plan.** Revert the code. Rows minted under the new scheme become unredeemable after a rollback, so rollback
means revoking them — an acceptable 10-minute-wide loss, but it must be stated before deploying.

**Verification test.** Unit-test vectors for both digests; staging: mint a code, redeem it (success), then read the row
and assert `code_hash != sha256(code)`.

---

<a id="e6"></a>

## E6 — `PAIRING_HASH_PEPPER` falls back silently to SHA-256

**Evidence.** `_shared/validation.ts:325-357`: if the pepper is empty, the function warns once per isolate
(`pairing_hash_pepper_missing`) and returns `sha256Hex(value)`. The RFC in the code comment acknowledges the risk. The
deployed value of the variable was not read; whether the fallback is active is **NOT VERIFIED**.

**Severity.** Low (Medium if the pepper is genuinely unset).

**Exploit preconditions.** Pepper unset at runtime, plus read access to `pairing_attempts`.

**Actual impact.** Attempt hashes become brute-forceable, revealing which identifiers were tried and when. It does not
grant access; it degrades the privacy of the rate-limit log and is a signal that a secret is missing.

**Proposed remediation (PROPOSED — NOT APPLIED).** Fail closed when the pepper is absent in production (return
`503 pairing_unavailable`), and alert on the startup warning. Set the secret as a prerequisite.

**Compatibility concerns.** Deploying fail-closed **before** setting the secret stops all pairing. Sequence: set
`PAIRING_HASH_PEPPER` first, verify pairing in staging, then deploy the fail-closed build.

**Rollback plan.** Revert to the warn-and-fallback behaviour, which keeps the service working.

**Verification test.** Local isolate with the variable unset → after the fix, pairing actions return 503; with the variable
set → normal behaviour, and the same code produces different digests under two peppers.

---

<a id="e7"></a>

## E7 — No rate limiting outside pairing

**Evidence.** `_shared/rate_limit.ts` is imported only by `pairing` (inventory, dependency matrix). None of the other
bundles contains a counter table, an attempts table or a quota helper — **VERIFIED absent** by reading each bundle.
Affected: `remote-session.request`, `device-command.create`, `device-policy.update`, `device-register.register`,
all five `family-admin` actions, both `auth-bootstrap` actions, and all four telemetry uploads.

**Severity.** Low–Medium; live.

**Exploit preconditions.** A legitimate parent or child account, or a compromised device secret.

**Actual impact.** Storage growth (location and usage rows), notification and consent spam, audit-table growth, CPU
consumption, and — for `auth-bootstrap.create_family` — repeated family-creation attempts (already bounded to one
active family per owner, so mostly noise). No authority escalation.

**Proposed remediation (PROPOSED — NOT APPLIED).** Add per-actor budgets, starting with the two that a user can trigger
most cheaply: `remote-session.request` (for example 5 per device per 10 min) and `device-command.create` (for example 60
per device per hour). Reuse the existing `pairing_attempts` pattern or a generic counter table keyed by
`(actor_id, action, window_start)`.

**Compatibility concerns.** Telemetry bursts legitimately (the Android client chooses its cadence). Measure real
inter-upload intervals before choosing a budget; a budget set from guesswork will drop legitimate data.

**Rollback plan.** Make budgets configuration values, so rollback is a config raise or a disabled flag — no deploy.

**Verification test.** Staging burst: 20 requests in 10 s to `remote-session.request` → 429 with `retry_after_seconds`
after the budget is consumed; a single request still succeeds.

---

<a id="e8"></a>

## E8 — Pairing rate limits are count-then-act

**Evidence.** `_shared/rate_limit.ts:54-93` reads a `count: "exact"` and *then* the caller proceeds to insert the attempt
row (`recordPairingAttempt`). The same pattern appears in `:110-151` and `:153-211` for codes and invites.

**Severity.** Low.

**Exploit preconditions.** Parallel requests inside the same window.

**Actual impact.** The effective limit is the configured limit plus the number of in-flight requests. A determined
attacker gains a small multiple, not a bypass. Brute force remains impractical: 10 attempts per identifier per 10
minutes against a 6.6 × 10¹¹ space.

**Proposed remediation (PROPOSED — NOT APPLIED).** Make the counter atomic — an `insert … on conflict do update …
returning` counter row, or `pg_advisory_xact_lock` keyed on `(parent, hash)` around check-and-record.

**Compatibility concerns.** Requires a table or a lock; both are schema-level changes needing approval. Latency increases
by one round trip.

**Rollback plan.** Drop the counter table / lock and revert to the current functions.

**Verification test.** Fire 10 failed redeems in parallel; count the recorded failures. Expect exactly 5 after the fix,
6–10 before.

---

<a id="e9"></a>

## E9 — Wildcard CORS including credential-bearing headers

**Evidence.** `_shared/cors.ts:1-8` — `Access-Control-Allow-Origin: *`, allow-headers include `authorization`,
`x-device-secret`, `x-cron-secret`. All nine bundles inline the same object. Every function answers `OPTIONS` with 200
before any authentication.

**Severity.** Low.

**Exploit preconditions.** A victim token or device secret present in a browser context controlled by, or readable by,
an attacker-controlled origin.

**Actual impact.** No cookies are used, so the wildcard alone does not create CSRF. The real effects are: origin stops
being a defence-in-depth signal; if a token ever reaches a web page, any origin can use it and read the response; and the
allowlist advertises internal header names to anyone who reads the preflight.

**Proposed remediation (PROPOSED — NOT APPLIED).** Echo an allowlisted origin (`capacitor://localhost`,
`https://localhost`, plus named dev origins) and add `Vary: Origin`; drop `x-cron-secret` from the browser-facing list.
`cron` does not need CORS at all.

**Compatibility concerns.** Any web client served from another origin breaks. No web client exists in this repository;
enumerate the Android WebView origins before changing.

**Rollback plan.** Restore the wildcard object; it is one file (or nine inlined copies).

**Verification test.** Preflight from `https://evil.example` with `Access-Control-Request-Headers: authorization` →
after the fix, no `Access-Control-Allow-Origin` in the response.

---

<a id="e10"></a>

## E10 — The device secret is chosen by the client

**Evidence.** `device-register` bundle: `readHex64(secret_hash)` then the value is stored as-is
(`{secret_hash: c, …}`), on both the insert and the re-credential update path. At authentication time
`requireDevice` compares `sha256Hex(presented)` against it. The only entropy requirement is the 16–512 character length
check at authentication. **VERIFIED** on the Edge side; whether the Android client generates a strong secret is
**NOT VERIFIED** (client source unavailable).

**Severity.** Low.

**Exploit preconditions.** The client derives its secret from something predictable (installation id, device id, a
constant), and an attacker knows the `device_id`.

**Actual impact.** Device impersonation: forged telemetry, forged command acknowledgements, policy-version manipulation,
and (via E11) disclosure of the parent's user id. Unauthorised access to the parent's other data is not implied.

**Proposed remediation (PROPOSED — NOT APPLIED).** Issue the secret server-side and return it exactly once, storing only
its hash — the client sends the hash of a secret it does not choose. Alternatively require a KDF with a per-device salt
and a minimum work factor.

**Compatibility concerns.** Requires a client change and a re-registration path for existing devices. A dual-mode period
is needed: accept the current client-supplied hash while the new flow rolls out.

**Rollback plan.** Stop issuing server-side secrets and keep verifying both formats; existing devices keep working.

**Verification test.** Staging: register with `secret_hash = sha256("0"*16)` → after the fix, rejected; the normal
registration flow returns a one-time secret and a subsequent `heartbeat` succeeds with it.

---

<a id="e11"></a>

## E11 — Command poll returns full rows including `created_by`

**Evidence.** `device-command` bundle: `poll` selects `"*"` from `device_commands` (via `poll_device_commands`), and
`ack` returns the full updated row. Those rows carry `created_by`, the parent's user id.

**Severity.** Info.

**Exploit preconditions.** Control of a child device — that is, the legitimate child user.

**Actual impact.** The child learns the parent's user UUID. On its own this is minor; it is the identifier E2 would need
if the `private` schema were ever exposed. Data minimisation, not an access-control defect.

**Proposed remediation (PROPOSED — NOT APPLIED).** Project explicit columns in the device-facing response and in the
RPC's `RETURNS TABLE`: `id, type, payload, status, created_at, expires_at`.

**Compatibility concerns.** The Android client may read fields that disappear. Check the client's parser before
narrowing, or add the projection server-side only after a client release that tolerates the smaller shape.

**Rollback plan.** Restore `"*"`.

**Verification test.** A poll response from a registered device contains no `created_by`.

---

<a id="e12"></a>

## E12 — Cron secret is static with no replay window

**Evidence.** `cron` bundle: `CRON_SECRET` must be ≥ 16 characters or the function returns 503; the header is compared
by hashing both sides with SHA-256 and a constant-time equal (**VERIFIED**, and a good implementation). The secret is
otherwise static and there is no timestamp, nonce or request signature; no IP restriction; preflight is answered for any
origin.

**Severity.** Low.

**Exploit preconditions.** Capture of the header value — proxy logs, a misconfigured client, a leaked CI variable.

**Actual impact.** Replay of `expire_sessions` or `detect_offline` at will: mass session expiry and duplicate offline
alerts. Both are idempotent maintenance operations, so impact is bounded and temporary.

**Proposed remediation (PROPOSED — NOT APPLIED).** Sign `timestamp + body` with the secret (HMAC) and reject a skew
older than five minutes; or rotate to a per-invocation token issued by the scheduler. Add an IP allowlist if the
scheduler's egress ranges are known.

**Compatibility concerns.** The scheduler must change in the same window as the function; a mismatch stops all
maintenance. Roll out by accepting both schemes for one release.

**Rollback plan.** Accept the legacy static header again; no data change is involved.

**Verification test.** Replay a captured request more than five minutes later → 401 `stale_request`; a fresh signed
request → 200.

---

<a id="e13"></a>

## E13 — Telemetry writes no audit rows

**Evidence.** `device-telemetry` bundle contains no insert into `audit_logs`. It updates `devices`, upserts
`usage_daily` and `safe_zone_states`, inserts `location_events` and `safety_alerts`, and calls `replace_device_apps`. The
other eight functions all audit their mutations.

**Severity.** Low; an accountability gap, not an access-control one.

**Exploit preconditions.** None — this is the normal operating path.

**Actual impact.** Device-originated mutations (notably a full apps-snapshot replacement) leave no audit record. After an
incident, a parent or investigator can see the resulting data but not when or by which device it changed. A compromised
device could rewrite its own app list without leaving an audit trail.

**Proposed remediation (PROPOSED — NOT APPLIED).** Audit low-volume, high-value events with a device actor:
`apps_snapshot_replaced`, `policy_acknowledged`, and `device_revoked`-class events. Sample or aggregate the high-volume
location and usage uploads instead of writing one row each.

**Compatibility concerns.** Write volume and table growth; `apps_upload` is rare (snapshot replacement), so the natural
start is that event only.

**Rollback plan.** Remove the audit calls; append-only rows already written stay (by design).

**Verification test.** Staging: call `apps_upload` → one `audit_logs` row with `device_id` set, `actor_user_id` null,
`event_type = 'apps_snapshot_replaced'`.

---

<a id="e14"></a>

## E14 — The audit actor is application-supplied

**Evidence.** `_shared/audit.ts:19-36` takes `actorUserId` from the caller and writes it verbatim. Every handler passes
the JWT subject, so today the value is correct (`pairing/index.ts:407,533,736,897`; `auth-bootstrap/index.ts:62`; each
bundle likewise). There is no database-side derivation or check.

**Severity.** Low; live but correct.

**Exploit preconditions.** A handler defect or a future handler that forwards a body value.

**Actual impact.** Mis-attributed audit rows. Combined with E3, this is the failure mode F7 describes: the audit log is
the artefact a parent would rely on after an incident.

**Proposed remediation (PROPOSED — NOT APPLIED).** Keep `recordAudit` as the single writer, and make the rule explicit
and testable: the actor argument may only be `auth.user.id` or `null` (device actions). Add a CI grep/test that fails if
`recordAudit` is called with any other expression, and adopt the E3 SQL guard for the database-side path.

**Compatibility concerns.** None for the Edge tier; the check is additive.

**Rollback plan.** Not applicable — test-only change.

**Verification test.** Unit tests on each handler with a forged `actor_user_id` in the body; the resulting audit row must
still carry the JWT subject. A lint rule rejects any other expression at review time.

---

## Recommended order

| Order | Item | Why first | Owner input needed |
| --- | --- | --- | --- |
| 1 | E2 (`REVOKE … FROM PUBLIC` + `GRANT … TO service_role`) | One configuration change away from live; cheapest close | yes — SQL approval |
| 2 | E3 (identity guard on actor-taking bodies) | Makes E1/E2 survivable even if exposure changes | yes — bodies must be captured first |
| 3 | E1 (add the parent check, or retire the RPC) | Closes the only function with no authorisation at all | yes — confirm no client caller |
| 4 | E4 (single-session invariant) | Live consent-integrity defect | yes — index is DDL |
| 5 | E6 (pepper present, then fail closed) | Secret hygiene, trivial | yes — set secret |
| 6 | E7 (budgets for session request and command create) | Live abuse surface | measurement first |
| 7 | E5, E8 | Hardening of an already-strong control | no |
| 8 | E9, E10, E11, E12, E13, E14 | Defence in depth, client-coupled or informational | depends |

Nothing here should be applied before the source export in
[13 §7](13-edge-function-source-inventory.md#7-owner-authorised-export-procedure-proposed--not-applied): without the
repository copy, none of these changes has a reviewable diff or a build path.
