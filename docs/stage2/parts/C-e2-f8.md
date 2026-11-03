# S2-P01 — E2 / F8: `private` function permissions

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

**Status: PROPOSED — NOT APPLIED.** Staging only. Runnable patch: [`S2-P01-e2-f8.sql`](../patches/S2-P01-e2-f8.sql). Part C, Stage 2 fan-out.

| Field | Value |
| --- | --- |
| Findings | E2 ([16 §E2](../../stage1/16-phase-e-findings.md#e2)); F8 ([11 §F8](../../stage1/11-remediation-proposals.md#f8--two-private-functions-keep-the-default-public-execute)) |
| Evidence | [g1-b3b-20261029.json](../../stage1/evidence/g1-b3b-20261029.json) `inventory`, `schema_usage`, `data_api_exposure`, `bodies`, `remote_session_triggers`; [14 §4](../../stage1/14-edge-function-security-audit.md#4-f7-and-f8--resolution) |
| Objects | `private.request_device_recovery(p_device_id uuid, p_actor_user_id uuid)`; `private.remote_session_transition_guard()` |
| Change | 2 × `REVOKE`, 1 × `GRANT`, 1 × `ALTER FUNCTION … SET search_path` |
| Excluded | Bodies, the F7/E3 identity guard, Data API exposure, `public` wrappers |

## 1. Verified current state

| Fact | Value | Status |
| --- | --- | --- |
| `private.request_device_recovery(uuid, uuid)` | `SECURITY DEFINER`, owner `postgres`, `proacl = NULL` (default `PUBLIC EXECUTE`), `anon/auth/service_exec = true`, `search_path = public, private, pg_temp` | VERIFIED (`inventory`) |
| `private.remote_session_transition_guard()` | `SECURITY DEFINER`, `proacl = NULL`, returns `trigger`, `search_path = public, pg_temp` (missing `private`) | VERIFIED (`inventory`) |
| Sibling ACL pattern | 27 functions `postgres=X/postgres,service_role=X/postgres`; 5 trigger/helper functions `postgres=X/postgres` | VERIFIED (`inventory`) |
| Schema usage | `authenticated` USAGE on `private` = true; `anon` = false | VERIFIED (`schema_usage`) |
| Data API exposure | exposed schemas `public, extensions`; 0 of 38 functions exposed; `private` not selected | VERIFIED (rendered dashboard setting) |
| Trigger binding | `remote_sessions_transition_guard` — `BEFORE UPDATE FOR EACH ROW` on `public.remote_sessions`, enabled | VERIFIED (`remote_session_triggers`) |
| `public.request_device_recovery` wrapper | body is `select private.request_device_recovery(...)`, `SECURITY DEFINER`, ACL `postgres=X,service_role=X` | VERIFIED (`bodies`, `inventory`) |

`private` sits one dashboard change (add to exposed schemas) away from being reachable by any signed-in user. The
in-body family check accepts *any* active parent of the device's family as `p_actor_user_id`; it does not authenticate
the caller. That is the E2/F7 scenario, not something this patch fixes. — VERIFIED by body text and [14 §4](../../stage1/14-edge-function-security-audit.md#4-f7-and-f8--resolution).

## 2. Defect

Both functions inherited PostgreSQL's default `EXECUTE TO PUBLIC`. Every other `private` function carries an explicit
ACL. For `request_device_recovery` that is a live RPC implementation: exposure plus the already-present
`authenticated` schema USAGE would let any signed-in user force an unlink and write an audit row naming a forged
actor. `remote_session_transition_guard` cannot be invoked directly (it returns `trigger`), so its NULL ACL is
negligible; the missing `private` in its `search_path` is a consistency defect (F8), not an exploitable one — its body
touches only `OLD`/`NEW`. Both are **latent, not live** on 2026-10-30.

## 3. Prechecks (staging)

Run SQL §0 before any change. Expected results, and what forces a stop:

1. **Identity** — `current_user` must be `postgres` (owner); otherwise the `REVOKE`/`GRANT`/`ALTER` will fail.
2. **Object identity** — exactly one row per signature in `private`; `prosecdef = true`; owner `postgres`. Any
   overload, different owner or missing function is a stop.
3. **ACL and matrix** — `proacl IS NULL`; anon/auth/service/postgres = `true/true/true/true`. `proacl` already
   non-NULL means drift since capture: stop and re-baseline.
4. **Explicit entries** (`aclexplode`) — only grantee `0` (PUBLIC), `EXECUTE`, not grantable. An explicit
   `anon`/`authenticated` entry means a `REVOKE … FROM PUBLIC` alone would not close the hole: stop.
5. **`service_role` already has EXECUTE?** Yes, but only through PUBLIC. `has_function_privilege` cannot distinguish
   inherited from explicit, so §0.2 is the authoritative check. After the patch the only source is the new grant.
6. **Non-service callers** — expect the `public` wrapper from §0.3 (static `prosrc` scan across all 38 bodies), one
   trigger binding, and no login role inheriting `service_role` (§0.4). The scan covers bodies Stage 1 never read;
   it cannot see dynamic SQL, but B3b found no `EXECUTE`/`format()` in any body (`dynamic_sql`). Edge source: the only
   caller is `family-admin recover_device` → `rpc request_device_recovery`, and all handlers run as `service_role`
   ([capture](../../stage1/evidence/edge-functions/capture-20261030.json)).
7. **Exposure** — `pgrst.db_schemas` is NULL at role level; exposure was read from the dashboard, not SQL. Re-confirm
   the dashboard shows `public, extensions` only before staging.

## 4. SQL diff

```sql
revoke all on function private.request_device_recovery(uuid, uuid) from public;
grant execute on function private.request_device_recovery(uuid, uuid) to service_role;

revoke all on function private.remote_session_transition_guard() from public;
alter function private.remote_session_transition_guard()
  set search_path = public, private, pg_temp;
```

`REVOKE ALL` is equivalent to `REVOKE EXECUTE` on a function. Statement order matters only for readability; each
statement commits alone. No `GRANT` for the guard: trigger invocation does not consult the invoker's `EXECUTE`, so
owner-only is the intended shape (the 5 sibling trigger functions are `postgres=X` only). — VERIFIED (PostgreSQL
trigger semantics), re-confirmed by T4.

## 5. Post-checks

| Object | Expected `proacl` | anon | authenticated | service_role | postgres |
| --- | --- | --- | --- | --- | --- |
| `private.request_device_recovery` | `{postgres=X/postgres,service_role=X/postgres}` | false | false | true | true |
| `private.remote_session_transition_guard` | `{postgres=X/postgres}` | false | false | **false** | true |

`service_role = false` on the guard is expected and correct: the guard is never called as a function, only fired as a
trigger. `proconfig` must read `public, private, pg_temp` on both. Compare ACLs as sets; display order is not
semantic. If either ACL differs, do not "fix forward" — capture and stop.

## 6. Compatibility

- **Edge `family-admin recover_device`** — anchor `rpc request_device_recovery {p_device_id, p_actor_user_id:i.user.id}`
  (VERIFIED, Edge capture). Runs as `service_role`. The public wrapper keeps its `service_role` grant, and because the
  wrapper is `SECURITY DEFINER` owned by `postgres`, its inner call runs as the owner and never needed the new grant
  (INFERRED from wrapper body + ownership). No handler change.
- **Trigger** — `remote_sessions` updates continue to fire the guard with no `EXECUTE` on it (VERIFIED semantics).
- **What could break** — only direct callers outside the Edge tier: staging harnesses that `SET ROLE authenticated`
  or `anon` and call the private function will now get `42501`; that is the intended signal. A login role inheriting
  `service_role` would still pass — §0.4 checks there is none. `anon` already fails on schema USAGE, so its behaviour
  is unchanged in practice.
- **No reload** — no signature or schema change, so no PostgREST schema-cache notification. Privileges are checked per
  request. `ALTER FUNCTION` touches `pg_proc.proconfig` only; no table lock, no body recompile risk.

## 7. Regression tests (staging only, rolled-back transactions)

| # | Actor | Action | Expected |
| --- | --- | --- | --- |
| T1 | `service_role` | `set local role service_role; select private.request_device_recovery('00000000-0000-0000-0000-000000000000'::uuid, null);` | `P0002 device_not_found` — proves EXECUTE passed; `42501` means the grant failed |
| T2 | `authenticated` | same call | `42501 permission denied for function` |
| T3 | `anon` | same call | `42501 permission denied for schema private` (USAGE fails before EXECUTE) |
| T4 | `service_role` | fixture `remote_sessions` row in a terminal state, then `update … set status = 'requested'` | `P0001 session_terminal`; and `has_function_privilege('service_role', guard, 'EXECUTE') = false` |
| T5 | Edge | `family-admin recover_device` against a throwaway family | HTTP 200, one `device_recovery_started` audit row naming the JWT subject |
| T6 | `postgres` | re-run SQL §3 | matrix and `proacl` exactly as §5 |

T1–T4 run inside `begin; … rollback;`; T5 uses staging data only. Never run T1/T5 against production: before the fix
T5's pre-state would unlink a real child.

## 8. Rollback

```sql
grant execute on function private.request_device_recovery(uuid, uuid) to public;
grant execute on function private.remote_session_transition_guard() to public;
alter function private.remote_session_transition_guard() set search_path = public, pg_temp;
```

**Caveat.** `GRANT … TO PUBLIC` restores the captured *behaviour* (PUBLIC can execute) but not the byte-identical
`NULL` ACL: `proacl` becomes an explicit `{=X/postgres}` entry. Resetting it to NULL needs a direct `pg_proc` catalogue
update, which is not proposed. Record the difference in the change log and in the G3 baseline. Bodies are untouched,
so no body rollback exists.

## 9. Approvals and stop conditions

**Approvals.** DB owner (`postgres`) executes; security owner signs off E2 (High latent) and F8; reviewer signs the
SQL diff; change record names the staging project ref. Production is out of scope for this patch.

**Stop conditions.** Any of: prior `REVOKE`/`GRANT` drift (`proacl` not NULL); explicit `anon`/`authenticated` ACL
entry; unexpected owner or overload; a non-service caller found by §0.3/§0.4; function missing; `ALTER`/`GRANT`
denied; T1 returns `42501`; T4 does not raise `session_terminal`; T5 fails or writes the wrong audit actor; staging
dashboard shows `private` exposed. On any stop: apply §8, re-capture, do not continue.

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **S2-P01 remains `PROPOSED — NOT APPLIED`**, like S2-P02 and S2-P03. No `REVOKE`, `GRANT` or `ALTER` has been run anywhere.
- Defects **D-01, D-02, D-03, D-04** (as numbered in [`patch-defects-before-a5.md`](../patch-defects-before-a5.md)) remain **OPEN**; none may be described as fixed. The document half was corrected 2026-11-02 in [`03-patch-S2-P01.md`](../03-patch-S2-P01.md) line 135 — **documentation-only**.
- The patch file itself is **byte-unchanged**: SHA-256 `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51`. A patch revision would change that hash and must be re-hashed before A5.
- Staging now exists as a shell (`parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)), so this part's "no project" premise is superseded — but it is an **empty shell**: 0 tables, no schema, no `private.s2_environment` sentinel, no secrets, no test users/principals, no Edge Functions. §3 prechecks and §7 T1–T6 therefore have no objects to act on; G5-S is `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)`.
- §9 approvals: **A5 is unsigned**. The A0/A2 package is `SUPERSEDED — DO NOT SIGN`; the replacement [`approval-package-v2-ratification-and-forward.md`](../approval-package-v2-ratification-and-forward.md) carries A2′, which authorises the sentinel and approved settings only — not a schema load, not secrets.
- §6/§7 assume `service_role` Edge callers exist on staging: they do not — G5-E is `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`. The approved architecture keeps Supabase Auth as the only identity authority (all 9 handlers call `db.auth.getUser(token)`); Firebase Auth remains disabled and FCM is not configured.
- Auto-pause applies: a dated dashboard touch is needed **on or before 2026-11-06** (approximate; no start timestamp recorded). T5-style evidence claims resting on screenshots are `NOT VERIFIED` — screenshots were never captured.
- No operational action taken in this pass — no SQL, no dashboard, no CLI, no approval signed.
