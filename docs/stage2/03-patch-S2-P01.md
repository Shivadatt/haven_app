# S2-P01 — E2 / F8: `private` function permissions (first reviewable patch)

**Status: `PROPOSED — NOT APPLIED`.** Prepared for review only. No SQL has been executed against any project. Apply
requires **A5** ([04](04-risks-rollback-approvals.md) §3) after steps 1–2 of the sequence are green
([00](00-stage2-execution-plan.md) §3).

| Field | Value |
| --- | --- |
| Findings | **E2** ([16 §E2](../stage1/16-phase-e-findings.md#e2)); **F8** ([11 §F8](../stage1/11-remediation-proposals.md#f8--two-private-functions-keep-the-default-public-execute)) |
| Evidence | [g1-b3b](../stage1/evidence/g1-b3b-20261029.json) `inventory`, `schema_usage`, `data_api_exposure`, `bodies`, `remote_session_triggers`; [g1-q7](../stage1/evidence/g1-q7-20261029.json); [14 §4](../stage1/14-edge-function-security-audit.md#4-f7-and-f8--resolution) |
| Objects | `private.request_device_recovery(p_device_id uuid, p_actor_user_id uuid)`; `private.remote_session_transition_guard()` |
| Change | `GRANT EXECUTE` ×1, `REVOKE ALL` ×2, `ALTER FUNCTION … SET search_path` ×1 |
| Excluded | Both bodies, the F7/E3 guard, Data API exposure, the `public` wrappers, all table data |
| SQL | [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql) |
| Size | 4 DDL statements, 1 transaction, no body replacement |

---

## 1. Current behaviour and defect

### 1.1 Verified state

| Fact | Value | Status |
| --- | --- | --- |
| `private.request_device_recovery(uuid, uuid)` | `SECURITY DEFINER`, owner `postgres`, `proacl = NULL` (⇒ default `PUBLIC EXECUTE`), `proconfig = search_path=public, private, pg_temp` | **VERIFIED** (`inventory`) |
| Same function, effective privileges | `anon`, `authenticated`, `service_role`, `postgres` all `EXECUTE = true` | **VERIFIED** (`inventory`) |
| `private.remote_session_transition_guard()` | `SECURITY DEFINER`, `proacl = NULL`, returns `trigger`, `proconfig = search_path=public, pg_temp` (missing `private`) | **VERIFIED** (`inventory`) |
| Sibling ACL pattern | 27 functions `{postgres=X, service_role=X}`; 5 trigger/helper functions `{postgres=X}` | **VERIFIED** (`inventory`) |
| Schema USAGE on `private` | `authenticated` = true; `anon` = false | **VERIFIED** (`schema_usage`) |
| Data API exposed schemas | `public, extensions`; 0 of 38 functions exposed; `private` not selected | **VERIFIED** (dashboard setting, [00](../stage1/00-status-register.md) P20) |
| Trigger binding | `remote_sessions_transition_guard`, `BEFORE UPDATE FOR EACH ROW` on `public.remote_sessions`, enabled | **VERIFIED** (`remote_session_triggers`) |
| `public.request_device_recovery` wrapper | body `select private.request_device_recovery(...)`; `SECURITY DEFINER`; ACL `{postgres=X, service_role=X}` | **VERIFIED** (`bodies`, `inventory`) |

### 1.2 Why it is a defect

Both functions inherited PostgreSQL's default `EXECUTE TO PUBLIC`. Every other function in `private` — without
exception — carries an explicit ACL. These two are the outliers.

- **`request_device_recovery`** is a live RPC implementation with no independent authorisation of the caller: the
  in-body check accepts *any* active parent of the device's family as `p_actor_user_id`. `private` is one dashboard
  change (add it to the exposed schemas) away from being reachable by any signed-in user, and `authenticated` already
  holds schema USAGE. Exposure plus the inherited grant would let a signed-in user force an unlink and write an audit
  row naming a forged actor. This is the **E2** scenario.
- **`remote_session_transition_guard`** cannot be invoked directly because it returns `trigger`; its NULL ACL is
  therefore negligible. The missing `private` in its `search_path` is a consistency defect (**F8**), not an exploitable
  one: its body reads only `OLD`/`NEW`.

**Neither is live today.** `private` is not exposed, so the inherited grant is unreachable from the Data API, and every
deployed caller runs as `service_role`. This patch closes a **latent route**, not an exploited one. Stating that
precisely matters: the patch is not urgent because of what is happening, but because the cost of closing it is four
statements and the cost of forgetting it is a permanently open PUBLIC grant on an unauthenticated RPC.

---

## 2. Proposed change

### 2.1 Statement-by-statement

| # | Statement | Purpose |
| --- | --- | --- |
| 1 | `grant execute on function private.request_device_recovery(uuid, uuid) to service_role;` | Preserve the only legitimate caller's access **before** it is removed from PUBLIC |
| 2 | `revoke all on function private.request_device_recovery(uuid, uuid) from public;` | Remove the inherited grant from `anon`/`authenticated` |
| 3 | `revoke all on function private.remote_session_transition_guard() from public;` | Same, for the guard (owner-only thereafter) |
| 4 | `alter function private.remote_session_transition_guard() set search_path = public, private, pg_temp;` | F8 second half: align with the 27 siblings |

`REVOKE ALL` is equivalent to `REVOKE EXECUTE` on a function. The GRANT precedes the REVOKE so that there is no instant
at which `service_role` lacks access — the window is invisible inside one transaction, but ordering it correctly also
makes the file safe to read statement-by-statement.

### 2.2 Complete diff

There is no source-code diff: the patch touches catalogues only. The effective change is:

```diff
  private.request_device_recovery(uuid, uuid)
- proacl    = NULL                                  -- implicit PUBLIC EXECUTE
+ proacl    = {postgres=X/postgres,service_role=X/postgres}
- anon/authenticated/service_role/postgres = t/t/t/t
+ anon/authenticated/service_role/postgres = f/f/t/t
  proconfig = search_path=public, private, pg_temp   -- unchanged
  prosrc    = <unchanged>                            -- body not touched

  private.remote_session_transition_guard()
- proacl    = NULL                                  -- implicit PUBLIC EXECUTE
+ proacl    = {postgres=X/postgres}
- proconfig = search_path=public, pg_temp
+ proconfig = search_path=public, private, pg_temp
  prosrc    = <unchanged>
```

Full runnable text, including the sentinel, drift guard, pre-checks, in-transaction post-checks and the commented
rollback: [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql).

### 2.3 In-file safety controls

| Control | Behaviour |
| --- | --- |
| Staging sentinel | Aborts unless `private.s2_environment` exists and equals `staging`. A paste into the production editor fails before the first DDL statement |
| Drift guard | Aborts if any grantee other than PUBLIC / `postgres` / `service_role` holds a privilege — an explicit `anon`/`authenticated` entry means `REVOKE FROM PUBLIC` would not close the hole |
| Idempotence | The drift guard's allow-list is the *post*-state too, so a re-run is harmless rather than a second, possibly-different change |
| Single transaction | All four statements commit together or not at all; the post-check runs inside the transaction (file lines 158–168) so a mismatch can be rolled back before commit — reachable **only via the two-pass procedure in §5**, since `commit;` sits at file line 170 in the same pasted block |
| No body change | `CREATE OR REPLACE` is not used anywhere in this patch |

---

## 3. Compatibility impact

| Consumer | Effect | Basis |
| --- | --- | --- |
| Edge `family-admin recover_device` → `rpc request_device_recovery` | **None.** Runs as `service_role`, which keeps EXECUTE via the new grant | VERIFIED (Edge capture: all nine handlers use the service-role key) |
| `public.request_device_recovery` wrapper | **None.** `SECURITY DEFINER` owned by `postgres`; the inner call executes as the owner and never needed the PUBLIC grant | INFERRED from wrapper body + ownership; confirmed by the post-check matrix showing `postgres = true` |
| `remote_sessions` updates | **None.** Trigger invocation does not consult the invoker's EXECUTE | VERIFIED PostgreSQL trigger semantics |
| `anon` | Effectively unchanged: already blocked by schema USAGE | VERIFIED (`schema_usage`) |
| `authenticated` | Loses a privilege it never exercised; a staging harness that `SET ROLE authenticated` will now get `42501` | Intended signal |
| PostgREST schema cache | No reload needed: no signature or schema change; privileges are checked per request | VERIFIED PostgreSQL semantics |
| Locks | `GRANT`/`REVOKE`/`ALTER … SET` touch catalogue rows only; no table lock, no body recompile | INFERRED (standard catalogue update) |
| Client apps | **No visible change.** No response shape, status code or endpoint is affected | VERIFIED: no client calls the private function directly (only the wrapper is referenced) |

**What could break.** Only a direct caller outside the Edge tier: an ad-hoc `psql`/SQL-Editor session that assumed
`authenticated` or `anon` could execute the private function. A login role that inherits `service_role` would still pass;
pre-check 0.7 verifies no such role exists. Both failure modes are the intended ones.

---

## 4. Preconditions and expected pre-check output

Run §0 of the SQL and record the output. Expected:

| Check | Expected | If not |
| --- | --- | --- |
| 0.1 `current_user` | `postgres` | Stop: the REVOKE/GRANT/ALTER will fail or be attributed to the wrong role |
| 0.2 signature/owner/secdef | exactly 2 rows; owner `postgres`; `secdef = true`; guard returns `trigger` | Stop: overload, different owner, or missing function |
| 0.2 `proacl` | `NULL` for both | Stop if non-NULL **and** an unexpected grantee is present; the in-file drift guard is authoritative |
| 0.3 matrix | `t/t/t/t` for both | Stop: drift since capture |
| 0.4 explicit ACL | `2 rows per function` (owner + PUBLIC), **4 rows total**: owner row `postgres`/`EXECUTE`/not grantable, PUBLIC row `EXECUTE`/not grantable | Stop if `anon`/`authenticated` appears explicitly |
| 0.5 static callers | exactly `public.request_device_recovery(uuid,uuid)` | Stop on any other caller: a non-service path would lose access |
| 0.6 trigger binding | one row, `public.remote_sessions`, enabled | Stop if absent: revoking the guard would be pointless and the trigger state is not what was captured |
| 0.7 role inheritance | 0 rows | Stop if any login role inherits `service_role` |
| 0.8 `pgrst.db_schemas` | NULL (informational) | Confirm in the dashboard that only `public, extensions` are exposed, and that `private` is not |

**Additional precondition:** steps 1–2 of [00](00-stage2-execution-plan.md) §3 (staging exists, baseline loaded and
equivalent). Without them the post-check has no meaning as evidence.

> **D-01 correction note (2026-11-02, S2-DOC-02):** row 0.4 previously promised "one row per function"; the query at
> `patches/S2-P01-e2-f8.sql:60` explodes `acldefault('f', owner)` for a `NULL` `proacl`, which returns the owner row as
> well as the PUBLIC row. **This is a documentation fix only — the SQL file was not modified and its hash is unchanged.**
> The matching comment at `S2-P01-e2-f8.sql:55` ("Expect grantee 0 (PUBLIC) with EXECUTE only") still carries the wrong
> expectation and stays `PATCH REVISION REQUIRED`.

---

## 5. Post-checks (must match exactly)

| Object | Expected `proacl` | anon | authenticated | service_role | postgres | `proconfig` |
| --- | --- | --- | --- | --- | --- | --- |
| `private.request_device_recovery` | `{postgres=X/postgres,service_role=X/postgres}` | false | false | true | true | `public, private, pg_temp` |
| `private.remote_session_transition_guard` | `{postgres=X/postgres}` | false | false | **false** | true | `public, private, pg_temp` |

Compare ACLs as **sets**; display order is not semantic. `service_role = false` on the guard is correct: it is only ever
fired as a trigger. If any cell differs, `rollback;` — do not fix forward.

### 5.1 Two-pass execution (D-02, corrected 2026-11-02)

The whole file is **not** a safe single paste. `begin;` … post-check … `commit;` is one block (`commit;` at
`patches/S2-P01-e2-f8.sql:170`), and the "run `rollback;` instead of commit" instruction lives in the comment at
171–172 — so following it requires the operator **not** to execute line 170. That is a real cost, not a free option, and
the procedure is:

1. **Pass 1:** execute `begin;` through the post-check (file lines 97–168) and leave the transaction open.
2. **Verify:** compare the 1.5 output cell-by-cell with the table above; record it in the change record.
3. **Pass 2:** on an exact match, execute `commit;` (line 170) as a separate, later execution. On any mismatch, execute
   `rollback;` and record.

Line 170 is the only line an operator may omit for a mismatch run; no other statement is rewritten. The text actually
applied and its hash go into the change record, and a copy with line 170 omitted is recorded as an **edited copy of the
reviewed hash**, not as the reviewed file. The `PATCH REVISION REQUIRED` half of D-02 — putting `commit;` behind an
explicit stop-and-confirm block so the safe path is the default paste — is **not done**: the SQL file is unchanged and its
hash is unchanged. Until that revision lands and is re-hashed, this two-pass procedure is the controlling instruction.

Nothing above can be exercised on the current staging database: §0's `::regprocedure` hard casts
(`S2-P01-e2-f8.sql:40–41`) fail because neither function exists there, and `SECTION 1` aborts at the sentinel (105–107).

---

## 6. Regression tests (staging only)

Test principals are explicit because an unqualified test proves only that SQL compiles, not that a caller can reach it
([06](06-redteam-resolution.md) J-08). Full plan: [05](05-validation-plan.md) §3.1.

| # | Principal | Action | Expected | Status now |
| --- | --- | --- | --- | --- |
| T1 | `service_role` | `set local role service_role; select private.request_device_recovery('00000000-0000-0000-0000-000000000000', null);` | `P0002 device_not_found` — proves EXECUTE passed | `BLOCKED — FIX NOT APPLIED` |
| T2 | `authenticated` | same call | `42501 permission denied for function` | `BLOCKED — FIX NOT APPLIED` |
| T3 | `anon` | same call | **INVARIANT control — not a discriminating test (D-03).** Expected `false` from `has_function_privilege('anon', 'private.request_device_recovery(uuid,uuid)', 'EXECUTE')`, and `42501 permission denied for schema private` for the call — **identical before and after the patch** (§3: `anon` is "already blocked by schema USAGE"). The error text alone is not evidence | `BLOCKED — FIX NOT APPLIED` |
| T4 | `service_role` | fixture `remote_sessions` row in a terminal state, then `update … set status = 'requested'` | `P0001 session_terminal`; `has_function_privilege('service_role', guard, 'EXECUTE') = false` | `BLOCKED — FIX NOT APPLIED` |
| T5 | Edge `family-admin recover_device` | call against a throwaway staging family | HTTP 200, one `device_recovery_started` audit row naming the JWT subject | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| T6 | `postgres` | re-run §0 + §1.5 | Matches §5 exactly | `BLOCKED — FIX NOT APPLIED` |

T1–T4 run inside `begin; … rollback;`. T5 needs a deployed handler and therefore cannot run in a SQL-only staging
project; it stays blocked until the Edge strategy is decided. **Never run T5 against production** — its pre-state would
unlink a real child.

> **D-03 correction note (2026-11-02, S2-DOC-02).** T3 used to be presented as a privilege test and §9 listed "T2/T3 do
> not return `42501`" as a stop. Since §3 records `anon` as "already blocked by schema USAGE" (`schema_usage`:
> `anon` = false), T3 returns the same error before and after the patch: it proves nothing about P01. It is relabelled an
> **invariant control** here and removed from §9. Documentation only; the SQL file was not modified and its hash is
> unchanged. Note also that **T3 cannot run at all on the current staging database**: `set local role anon` needs a role
> and a `private` schema, and staging (`dzonzgngwxclhfnvxtvu`) is an empty shell with 0 tables, no schema, no
> `private.s2_environment` sentinel and no test principals. The same absence blocks T1/T2/T4/T6; the `BLOCKED` statuses
> above are not provisional passes.

---

## 7. Rollback

```sql
grant execute on function private.request_device_recovery(uuid, uuid) to public;
grant execute on function private.remote_session_transition_guard() to public;
alter function private.remote_session_transition_guard()
  set search_path = public, pg_temp;
```

| Dimension | Answer |
| --- | --- |
| Behaviour | Restored: PUBLIC can execute both functions; the guard's original `search_path` |
| Byte-identical ACL | **No.** `proacl` becomes an explicit `{=X/postgres, …}` instead of `NULL`. Restoring `NULL` requires a direct `pg_proc` catalogue update, which [04](04-risks-rollback-approvals.md) §3 forbids |
| `service_role` grant | May be left in place: it is a subset of PUBLIC EXECUTE and changes no effective privilege |
| Data loss | None — privileges and one setting only; bodies untouched |
| Time | ≤5 minutes plus verification |
| Verification | `has_function_privilege('anon'/'authenticated', …)` true again; `prosrc` hash unchanged; `proconfig` exactly `{search_path=public, pg_temp}`; a `service_role` recovery call still behaves as before |
| Consequence | Re-opens E2/F8 exactly as Stage 1 found them. This is a **security regression**, requiring A10 and a recorded reason |

The rollback block ships **inside the SQL file** — specifically the file's own **`SECTION 2 - ROLLBACK`**, the heading at
`patches/S2-P01-e2-f8.sql:176` with the commented statements at 183–191 — commented out, so the text that would be executed
is the text that was reviewed. It does **not** mean §2 of this document ([03](03-patch-S2-P01.md) §2 is the proposed
change); the file's section numbering and the document's section numbering are unrelated. The block is commented out in the
shipped file, so as written the file never executes it (D-04 correction note, 2026-11-02: documentation only, SQL
unmodified).

---

## 8. Approvals

| Approval | Holder | Evidence |
| --- | --- | --- |
| **A5** apply to staging | Owner + separate reviewer pass | SQL hash, §0 output, §5 output, §5.1 two-pass record, T1/T2/T4 results (T3 recorded as the invariant control, not as evidence of the change), rollback acknowledged |
| **A10** rollback | Owner + reviewer, reason recorded | Stop condition met, reversal statements, ACL difference acknowledged |
| **A6** production | **Not requested here.** Production is out of scope for this patch until staging evidence exists and the 7-item gate in [04](04-risks-rollback-approvals.md) §4 is met | — |
| **A9** secrets | **Not applicable.** This patch touches no secret | — |

Single-owner reality: the "reviewer" is a separate, recorded checklist pass, not a second person
([04](04-risks-rollback-approvals.md) §3). Compensating evidence is the hash, the pre/post tables and the transaction.

---

## 9. Stop conditions

Any of the following: sentinel absent or not `staging`; `current_user` ≠ `postgres`; missing function, unexpected
overload or owner; explicit `anon`/`authenticated` ACL entry; a caller other than the public wrapper found in 0.5; trigger
binding absent or disabled; a login role inheriting `service_role`; the staging dashboard shows `private` exposed;
`GRANT`/`REVOKE`/`ALTER` denied; T1 returns `42501`; T2 does not return `42501`; T4 does not raise `session_terminal`;
T6 does not match §5. **T3 is not a stop condition** — it is an invariant control that returns `42501` identically before
and after the patch (§6); what must hold across the patch is `has_function_privilege('anon', …) = false`.

On any stop: run the rollback if `SECTION 1 - APPLY` in the SQL file (lines 97–170) already committed — this is the file's
section, not §1 of this document — re-capture, record, and do not continue to S2-P02.

---

S2-DOC-02 addendum (2026-11-02): documentation correction only; no patch file modified; no patch applied; no operational
action.
