# E4 — Remote-session consent and session integrity

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

**Status: `PROPOSED — NOT APPLIED`.** Staging only. No SQL was executed, no production row was read, and no Edge source
or configuration was changed. Artefacts: this document and [S2-P03](../patches/S2-P03-e4-session-invariant.sql).

Labels: **VERIFIED** (read from Stage 1 evidence), **INFERRED** (reasoned from verified facts), **PROPOSED** (this
document's design, SQL or test). Evidence: [16 §E4](../../stage1/16-phase-e-findings.md#e4), [14 checks 8–9](../../stage1/14-edge-function-security-audit.md),
[g1-b3b](../../stage1/evidence/g1-b3b-20261029.json) bodies, [g1-q4](../../stage1/evidence/g1-q4-20261029.json)/[g1-q5](../../stage1/evidence/g1-q5-20261029.json).

## 1. Verified baseline

| Fact | Status |
| --- | --- |
| `remote-session.request` inserts into `public.remote_sessions` directly with `status='requested'`, `expires_at = now()+10 min`, `consent_recorded=false`; it does not call `public.request_remote_session` | **VERIFIED** ([14 check 8](../../stage1/14-edge-function-security-audit.md), bundle anchors) |
| `public.request_remote_session` takes `pg_advisory_xact_lock(hashtextextended(p_device_id::text,0))`, expires stale `requested` rows, refuses when a live row exists (`P0001 session_in_progress`), then inserts; it has no first-party caller | **VERIFIED** ([g1-b3b](../../stage1/evidence/g1-b3b-20261029.json) body; [16 §E1](../../stage1/16-phase-e-findings.md#e1)) |
| `remote_sessions` has one `BEFORE UPDATE` trigger, `private.remote_session_transition_guard`, which raises `session_terminal` on terminal→open transitions; there is no insert trigger and no unique constraint on `device_id` | **VERIFIED** ([g1-b3b](../../stage1/evidence/g1-b3b-20261029.json) `remote_session_triggers`; [g1-q4](../../stage1/evidence/g1-q4-20261029.json)) |
| Statuses are `requested\|accepted\|active\|declined\|ended\|expired\|failed`; `remote_sessions_pending_expiry_check` requires `expires_at` when status is `requested`; `consent_recorded` is NOT NULL; `session_nonce` is nullable | **VERIFIED** ([g1-q5](../../stage1/evidence/g1-q5-20261029.json), [g1-q8](../../stage1/evidence/g1-q8-20261029.json)) |
| The handler does not map `23505` or raised SQLSTATEs: the conflict is thrown and surfaces as HTTP 500 | **INFERRED** — the bundle is minified and shows 4 catch blocks but no `23505`/`P0001` anchor, unlike `device-command` which maps `23505` |
| `remote_sessions` held 39 rows at Stage 1; no row was read in this turn | **VERIFIED** count ([03](../../stage1/03-data-model.md) §1); data access **NOT PERFORMED** |

## 2. The two enforcement designs

### 2.1 (a) Partial unique index on `device_id` for live statuses

```sql
create unique index remote_sessions_one_live_per_device
  on public.remote_sessions (device_id)
  where status in ('requested', 'accepted', 'active');
```

Strengths (**VERIFIED** semantics): atomic under concurrency without any application lock; covers every writer,
including the current direct insert and the RPC; cannot be forgotten by a future handler; leaves terminal history in
place (the row leaves the index when it becomes terminal); one index build on 39 rows. Ordering inside the index makes
the second concurrent insert fail with `23505 unique_violation`, which PostgREST itself classifies as 409.

**The expiry problem (the decisive weakness).** An index predicate must be `IMMUTABLE`; `now()` is `STABLE`, so
`where ... and expires_at > now()` is rejected. The predicate therefore sees only `status`, never time. A row stays
`requested` after `expires_at` passes until something performs an `UPDATE`; while it does, it still occupies the single
live slot and blocks the next request. Clearing paths today: `pending_child` expires stale rows for that child when the
child opens the app (**VERIFIED** anchor); `cron → expire_stale_sessions()` exists, but whether it covers `requested`
rows is **INFERRED** because its body is unread (PA3); a parent can `end` the stale session manually. If the child is
offline and cron is paused or failing, the block is indefinite, not 10 minutes. A time-derived boolean flag maintained
by triggers would fix the predicate, but it adds a column plus another trigger — more moving parts than (b) for the same
result, so it is not proposed.

### 2.2 (b) `BEFORE INSERT` trigger `private.remote_session_insert_guard()`

The trigger takes the **same** transaction advisory lock and key as the RPC
(`pg_advisory_xact_lock(hashtextextended(new.device_id::text, 0))`), expires stale `requested` rows for that device
exactly as the RPC does, then raises `P0001 session_in_progress` if a live row exists. It runs only for
`requested|accepted|active` inserts.

Strengths: clears stale rows at write time, so the block lasts only until the next attempt; serialises with the RPC
because the key and lock mode match; fixes the root cause for every direct writer; produces the same clean message the
RPC already uses, so one future handler mapping covers both paths. **INFERRED** Postgres semantics: the function is
`VOLATILE`, so each SQL statement inside it takes a fresh snapshot and, after the lock is granted, the `EXISTS` check
sees the winner committed by the other transaction — the same mechanism the RPC relies on. This assumes READ COMMITTED
(the PostgREST default); a REPEATABLE READ caller would need an explicit re-check.

Complexity and privilege semantics:
- `CREATE TRIGGER` requires `EXECUTE` on the function for the **creator** (the owner, `postgres`); at runtime a normal
  trigger is **not** rechecked for `EXECUTE`. It runs with the privileges of the role executing the `INSERT`
  (`SECURITY INVOKER`) or of the function owner (`SECURITY DEFINER`).
- Today the writers are `service_role` (direct insert; has all table privileges and bypasses RLS per
  [04](../../stage1/04-rls-matrix.md)) and `postgres` (inside the definer RPC). Both can run the guard's `SELECT`/`UPDATE`,
  so **invoker rights are sufficient** and add no privileged surface. If a future writer lacks `UPDATE`, the insert
  fails closed (`insufficient_privilege`) instead of silently skipping the invariant.
- `SECURITY DEFINER` would work for any writer but creates a new privileged object that must pin `search_path` and
  strip `PUBLIC EXECUTE` — the E2/F8 pattern — for no gain in a two-statement guard. Rejected.
- Residual gap: a writer that disables triggers or sets `session_replication_role = replica` bypasses it; the advisory
  lock only serialises writers that use the identical key.

### 2.3 Comparison

| Dimension | (a) Partial unique index | (b) Insert trigger |
| --- | --- | --- |
| Invariant | Hard, all writers | Procedural; bypassable if triggers are disabled |
| Stale `requested` row | Blocks until cron/child/manual expiry; potentially indefinite | Expired by the guard on the next attempt |
| Concurrency | Atomic, no lock needed | Correct only because of the shared advisory lock |
| Writer coverage | Any `INSERT`/`UPDATE` | Any row-level `INSERT` with triggers enabled |
| Error surfaced | `23505` (PostgREST 409, handler 500 today) | `P0001 session_in_progress` (handler 500 today) |
| Privilege surface | None | One function; invoker rights, ACL tightened |
| Ops dependency | Cron/child app must expire rows | None at request time |
| Rollback | `drop index` | `drop trigger` + `drop function` |
| Staging risk | Fails to build if duplicates exist | Expires rows as a side effect (writes data) |

## 3. Recommendation

**Use both, in one atomic patch: (b) as the enforcement path, (a) as the invariant backstop.** (b) is the only design
that clears stale rows at write time and gives a single clean message; (a) guarantees the invariant even if a future
handler omits the lock or a writer disables triggers. There is **no double error path**: `BEFORE ROW` triggers run
before index insertion, so a normal conflict always raises `P0001`; `23505` is reachable only when the trigger is
bypassed and should be treated as an invariant-breach signal to alert on, not a second user-facing outcome. If only one can be approved, choose (b).

## 4. Precheck (read-only) and staging remediation

### 4.1 Duplicate live sessions — run in the target project before the patch

```sql
-- P1: summary. Expect 0 / 0.
select count(*) filter (where live_rows > 1) as devices_with_duplicates,
       coalesce(sum(live_rows - 1), 0)        as excess_live_rows
from (select device_id, count(*) as live_rows
      from public.remote_sessions
      where status in ('requested','accepted','active')
      group by device_id) d;

-- P2: detail for review and export (ids only; no payload).
select device_id, count(*) as live_rows,
       count(*) filter (where status='requested') as requested,
       count(*) filter (where status='accepted')  as accepted,
       count(*) filter (where status='active')    as active,
       min(requested_at) as oldest, max(requested_at) as newest,
       bool_or(expires_at is not null and expires_at <= now()) as has_stale
from public.remote_sessions
where status in ('requested','accepted','active')
group by device_id having count(*) > 1
order by live_rows desc, device_id;

-- P3: stale blockers that design (a) alone could not clear by itself.
select count(*) from public.remote_sessions
where status='requested' and expires_at is not null and expires_at <= now();

-- P4: object-name collisions and definitions (expect 0 rows).
select 'index' as kind, indexname as name, indexdef as definition from pg_indexes
 where schemaname='public' and indexname='remote_sessions_one_live_per_device'
union all
select 'function', p.proname, pg_get_function_identity_arguments(p.oid) from pg_proc p
 where p.pronamespace='private'::regnamespace and p.proname='remote_session_insert_guard'
union all
select 'trigger', tgname, pg_get_triggerdef(t.oid) from pg_trigger t
 where tgrelid='public.remote_sessions'::regclass and tgname='remote_sessions_insert_guard';
```

### 4.2 Remediation if P1/P2 are non-empty — **STAGING ONLY, no production DML proposed**

Keep the most advanced row per device (`active` > `accepted` > `requested`, then newest) and expire the rest. Expire,
never delete: `webrtc_signals.session_id` is `ON DELETE CASCADE`, so a delete would destroy signalling evidence, and
historical sessions are retained for parental transparency ([03](../../stage1/03-data-model.md) §3). Export P2 first.

```sql
-- STAGING ONLY. Review P2 output; run in one transaction; re-run P1 afterwards.
with ranked as (
  select id, row_number() over (
           partition by device_id
           order by case status when 'active' then 3 when 'accepted' then 2 else 1 end desc,
                    requested_at desc, id) as rn
  from public.remote_sessions
  where status in ('requested','accepted','active'))
update public.remote_sessions r
   set status='expired', ended_at=now(), ended_reason='duplicate_live_session'
  from ranked x where r.id=x.id and x.rn > 1;
```

The transition guard permits live→terminal. Expiring an `active` loser terminates a session that may still be signalled;
coordinate with test clients. If this script is ever adapted for production it must also write one `audit_logs` row per
affected session and needs its own approval — that is deliberately **not** proposed here.

## 5. Patch and ordering

Complete SQL: [S2-P03-e4-session-invariant.sql](../patches/S2-P03-e4-session-invariant.sql). One transaction; run as the
owner after §4.1 passes. Order: (0) duplicate precheck `DO` block that aborts readably; (1) `create or replace function`
with invoker rights and pinned `search_path`; (2) `revoke`/`grant` on the function; (3) `drop trigger if exists` +
`create trigger`; (4) `create unique index if not exists`. The index is last so a build failure rolls the whole patch
back. `if not exists` is name-based, which is why P4 checks for a same-named but differently defined object.

## 6. Compatibility

**Acceptable while staging-only:** exactly one request wins and the invariant holds; the 500 is opaque and leaks nothing;
the failure is visible in staging logs, which is how the mapping gap is proven before release. **Unacceptable for real
users:** 500 counts as an unhandled failure (error-budget alerts on normal double-request behaviour); a client that
retries 5xx will retry into the same conflict with no rate limit ([E7](../../stage1/16-phase-e-findings.md#e7)); a parent
cannot distinguish “already in progress” from a server fault; and `23505` text carries the index name into logs. Before
production, the Edge handler must map `P0001 session_in_progress` and `23505` to `409 session_in_progress` (reusing the
existing envelope), and the client contract must accept that code. That handler change is a **separate Edge patch,
blocked on source availability** (the bundles are minified; export is gated by
[13 §7](../../stage1/13-edge-function-source-inventory.md)). It cannot be written or reviewed in this repository today.

## 7. Tests, regression, rollback, approvals

**Concurrency (staging, PROPOSED — NOT EXECUTED).** (1) Two sessions, same device, both `begin; insert ... status
'requested';` before either commits → one row; the other gets `P0001`. (2) Two handler `request` calls in parallel → one
success, one 500 today (409 after the Edge patch). (3) RPC and direct insert in parallel → one wins; no `23505`, proving
the shared lock. (4) Seed `requested` with `expires_at` in the past, then request → old row becomes `expired` and the new
row inserts; this is the test that fails under design (a) alone. (5) Two different devices in parallel → both succeed.
(6) Backstop: disable the trigger (staging only, re-enable immediately) → the second insert raises `23505`.

**Regression.** Full path request → accept → start → ice → end still 200 at each step; decline-then-accept still 409
`session_not_open`; terminal→open still raises `session_terminal` (the new trigger is `BEFORE INSERT` only); the RPC
still inserts once (lock is re-entrant, extra expiry update is a no-op); `pending_child` and `cron expire_sessions` are
untouched; no `session_requested` audit row on a rejected insert (audit is written after the insert).

**Rollback.** `drop trigger if exists remote_sessions_insert_guard on public.remote_sessions;` then
`drop function if exists private.remote_session_insert_guard();` and `drop index if exists
public.remote_sessions_one_live_per_device;`. Rows expired by the trigger stay expired — rollback restores behaviour, not
data. If only the index proves problematic, drop the index alone and keep the clean `P0001` path.

**Approvals.** Database owner for the DDL and the §4.2 remediation (staging); security review of the new trigger
function and its ACL; Edge owner for the follow-up mapping patch; test owner sign-off on the concurrency and regression
evidence. No production deployment until all four, plus the G3 baseline ([12](../../stage1/12-g3-baseline-plan.md)).

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **S2-P03 remains `PROPOSED — NOT APPLIED`** (as do S2-P01 and S2-P02); its SQL file in `docs/stage2/patches/` was not edited in this pass. Defects **D-10, D-11, D-12** (as numbered in [`patch-defects-before-a5.md`](../patch-defects-before-a5.md)) remain **OPEN** — none may be described as fixed.
- **S2-P02 is a prerequisite**: `P02 → P03` is the only permitted order, because the trigger mirrors the RPC body P02 rewrites. Running P03 first leaves the guard mirroring the pre-P02 text.
- **E4 is not user-facing-correct yet.** Until an Edge handler maps `P0001` and `23505` to `409 session_in_progress`, §6's unacceptable-for-real-users path (500 on a normal double request) stands — and no handler can be written, because there is no Edge source in this repository: G5-E is `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`.
- Staging exists as a shell (`parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)) but is an **empty shell**: 0 tables, no schema, no `private.s2_environment` sentinel, no secrets, no test principals. So the §4.1 prechecks return nothing meaningful and §7 cannot run: G5-S is `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)`. The 39-row count in §1 is a production figure, not a staging one.
- **Rollback texts are not absent from the repository**: the original function bodies (prosrc) — `create_edge_api_token` etc. — ARE captured at [`g1-b3b-20261029.json`](../../stage1/evidence/g1-b3b-20261029.json) lines 149/155/159/165 (metadata lines 62/67/78). Any claim that they exist nowhere is false and superseded.
- Approvals: **A5 unsigned**; the shell creation was executed on the owner's direct instruction and awaits retrospective ratification, not a signed A0/A2. [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`; the replacement package's A2′ authorises sentinel + approved settings only. The plan of record uses A0–A3 and A5–A13 and has **no A4**.
- Free-plan auto-pause needs a dated dashboard touch **on or before 2026-11-06** (approximate; no start timestamp recorded). Screenshots were never captured, so any screenshot-based evidence is `NOT VERIFIED`.
- No operational action taken in this pass — no SQL, no DDL, no dashboard or CLI action, nothing signed.
