# D — E3/F7 actor binding and E1 remote-session authorisation (S2-P02)

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

Status: **`PROPOSED — NOT APPLIED`**. Planning only. No SQL, browser, Supabase, CLI, deploy or secret action was taken.
Stage 1 is authoritative. Patch: [S2-P02](../patches/S2-P02-e3-actor-binding.sql). Sibling controls:
[P01](../patches/S2-P01-e2-f8.sql), [I — risks/rollback/approvals](I-risks-rollback-approvals.md).

Labels: **VERIFIED** (Stage 1 evidence or repository) / **INFERRED** (deduced, not observed) / **PROPOSED — NOT APPLIED** / **BLOCKED — …**.

## 1. The honesty point first

- **VERIFIED.** Every current caller of these functions is an Edge Function using the service-role key, and
  `auth.uid()` is `NULL` under `service_role` ([Phase E](../../stage1/16-phase-e-findings.md) §4). Therefore the
  `actor_mismatch` guard added here **never fires on the deployed path**. It is not a live fix for E3/F7.
- Full closure needs one of two decisions, both outside this patch: **(a)** call the database with a user JWT so
  `auth.uid()` is populated and the guard is meaningful — an architecture change that also reopens RLS questions; or
  **(b)** accept the Edge trust boundary, on evidence that all nine handlers derive the actor from the verified JWT
  ([14](../../stage1/14-edge-function-security-audit.md)). Until one is recorded, E3/F7 stays **OPEN**.
- **VERIFIED.** The E1 membership check binds `p_parent_user_id`, not `auth.uid()`, so it **does** constrain
  `service_role` callers: it stops a fabricated or cross-family parent id, but cannot prove *which* caller sent it.
- Value: it protects a future grant/exposure or user-JWT route and stops a copy-paste handler from silently forging an
  audit trail. **PROPOSED — NOT APPLIED.**

## 2. Scope and evidence grade

| Function | Captured body | Change in S2-P02 | Grade |
| --- | --- | --- | --- |
| `private.request_device_recovery(uuid,uuid)` | [g1-b3b](../../stage1/evidence/g1-b3b-20261029.json) | Full replace + actor guard | **VERIFIED** body, **PROPOSED** diff |
| `private.unlink_child(uuid,uuid,uuid)` | g1-b3b | Full replace + actor guard | **VERIFIED** body, **PROPOSED** diff |
| `public.request_remote_session(uuid,uuid,text)` | g1-b3b | Full replace + actor guard + E1 membership; then F5 | **VERIFIED** body and `plpgsql`, **PROPOSED** diff |
| `public.request_device_recovery(uuid,uuid)` | Brief says unread; g1-b3b contains the one-line delegation | No body change; re-capture only | **VERIFIED** capture exists; wrapper out of scope |
| `public.unlink_child(uuid,uuid,uuid)` | Never read | **BLOCKED**; no diff authored | **VERIFIED** absent from capture |

Capture discrepancy: the brief lists both public wrappers as unread; g1-b3b **does** contain
`public.request_device_recovery` (one-line delegation), while `public.unlink_child` is genuinely absent. Re-read both;
neither wrapper is modified here.

## 3. Exact actor guard template

Use this verbatim in every actor-taking body, substituting that function's own argument. Do **not** replace the
argument with `auth.uid()` and do **not** add an `is null` bypass: service-role callers must keep passing the actor.

```sql
if auth.uid() is not null and <actor parameter> is distinct from auth.uid() then
  raise exception 'actor_mismatch' using errcode = '42501';
end if;
```

Substitutions: `p_actor_user_id` in `request_device_recovery` and `unlink_child`; `p_parent_user_id` in
`request_remote_session`. **VERIFIED**: `service_role` has `auth.uid() = NULL`; `is distinct from` also rejects a
`NULL` actor under a user JWT. **INFERRED**: the `auth.uid()` definition was not captured, so tests set both
`request.jwt.claims` and `request.jwt.claim.sub`.

## 4. Per-function changes

**4.1 `private.request_device_recovery`.** Insert after `begin`, before the device row lock:

```sql
if auth.uid() is not null and p_actor_user_id is distinct from auth.uid() then
  raise exception 'actor_mismatch' using errcode = '42501';
end if;
```

The existing "some active parent" check, `unlink_child` call and `device_recovery_started` audit row are unchanged.
**VERIFIED** by token comparison with g1-b3b: 179 tokens before and after, identical once the guard is removed.

**4.2 `private.unlink_child`.** Same guard after `begin`, before the existing null and child/parent checks. The guard
is deliberately first: a forged actor must not reach the audit write, and the nested call from
`request_device_recovery` passes the same value, so both guards agree. The child-self path remains legal.
**VERIFIED** token-identical apart from the guard (368/368).

**4.3 `public.request_remote_session`.** Guard first; then the existing kind validation, advisory lock and device
active check; then the new membership check, before stale-session expiry and insert:

```sql
if p_parent_user_id is null or not exists (
  select 1 from public.family_members m
  join public.families f on f.id = m.family_id
  where m.family_id = v_device.family_id and m.user_id = p_parent_user_id
    and m.role = 'parent' and m.status = 'active' and f.deleted_at is null
) then raise exception 'forbidden' using errcode = '42501'; end if;
```

This mirrors the captured `private.is_family_parent` predicate but binds `p_parent_user_id`; calling
`private.is_family_parent` would test `auth.uid()` and fail under `service_role` (**VERIFIED** helper body).
Placement is after the device load because the family id comes from `v_device`; before the expiry/insert because no
row may be attributed first. **VERIFIED** original body is otherwise token-identical (226/226).

## 5. F5 — `search_path`

`public.request_remote_session` currently has `proconfig = {search_path=public, pg_temp}` (**VERIFIED**, g1-q7); after
P01 fixes the trigger guard it is the only one of 38 still omitting `private`. Patch step 4 runs:

```sql
alter function public.request_remote_session(uuid, uuid, text)
  set search_path = public, private, pg_temp;
```

The body already schema-qualifies its `public` objects, so behaviour does not change; this is hygiene for future `private.*` calls.
It is separate from the body replacement so E1 and F5 have independent review and rollback; the patch applies the
pre-patch `search_path` first, then F5, avoiding a silent config change inside `CREATE OR REPLACE`.

## 6. Precondition: capture before authoring any further diff

Before extending the guard, run this read-only capture in staging/prod (g1-b3b style) and store the result with the
change record:

```sql
select p.oid::regprocedure, pg_get_userbyid(p.proowner) as owner, p.prosecdef,
       p.proconfig, p.proacl, md5(p.prosrc) as prosrc_md5, pg_get_functiondef(p.oid)
  from pg_proc p
 where p.pronamespace in ('public'::regnamespace, 'private'::regnamespace)
   and p.proname in ('request_device_recovery','unlink_child','apply_policy_version',
     'create_family_with_owner','create_pairing_invite','create_pairing_request',
     'detect_offline_devices','expire_stale_commands','expire_stale_sessions',
     'poll_device_commands','replace_device_apps','respond_pairing_request','revoke_device',
     'record_audit')
 order by 1;
```

**The 11 unread `private` twins, all `BLOCKED — BODY NOT CAPTURED`, and out of scope:** `apply_policy_version`,
`create_family_with_owner`, `create_pairing_invite`, `create_pairing_request`, `detect_offline_devices`,
`expire_stale_commands`, `expire_stale_sessions`, `poll_device_commands`, `replace_device_apps`,
`respond_pairing_request`, `revoke_device`. Also out of scope: `private.record_audit` (unread, no twin),
`public.unlink_child` (unread wrapper), `public.request_device_recovery` (capture only), and the other 11 public
wrappers. None may receive a guard until its body and rollback text exist. Guarded snippet, **do not apply**:

```sql
-- BLOCKED: only after the body is captured; insert after DECLARE/BEGIN.
-- if auth.uid() is not null and <actor> is distinct from auth.uid() then
--   raise exception 'actor_mismatch' using errcode = '42501';
-- end if;
```

## 7. Compatibility

- `CREATE OR REPLACE` keeps OID, owner, ACL/grants, dependencies and signature; return types are unchanged (`jsonb`, `jsonb`, `public.remote_sessions`), so no overload is created.
  **VERIFIED** PostgreSQL semantics; ACL preservation is still re-checked post-apply.
- `service_role`: guards are skipped; the two recovery/unlink bodies are token-identical, so no behaviour change.
  `request_remote_session` now rejects a non-parent id, which the only first-party path does not send.
- `authenticated`/`anon`: still no `EXECUTE` (**VERIFIED**, g1-q10), so no working client path breaks. A test harness
  granted `EXECUTE` will start seeing `42501` — the intended signal.
- **VERIFIED** Phase E: the `remote-session` handler inserts into the table directly (E4), so it does not call this
  RPC; this patch cannot break it. Dropping the RPC remains an E1 alternative.
- No table data is written by the patch; existing `remote_sessions` rows and audit rows are untouched. A forged audit
  row already written is not corrected by rollback either.

## 8. Regression tests (staging only)

Fixtures from [I](I-risks-rollback-approvals.md) §4: family F, parents A and B, child K, outsider C, device D of F.
Each test in a transaction ending `rollback`; grants below are **test-only**, not part of the patch. Because P01
revokes PUBLIC on recovery, grant test access explicitly; **INFERRED** that the owner may `SET ROLE authenticated`
(role membership not captured — otherwise use a dedicated test role).

```sql
begin;
grant execute on function private.request_device_recovery(uuid,uuid) to authenticated;
grant execute on function private.unlink_child(uuid,uuid,uuid) to authenticated;
grant execute on function public.request_remote_session(uuid,uuid,text) to authenticated;
set request.jwt.claims = '{"sub":"<A>","role":"authenticated"}';
set request.jwt.claim.sub = '<A>'; set request.jwt.claim.role = 'authenticated';
set role authenticated;
-- call; then: reset role; reset request.jwt.claims; reset request.jwt.claim.sub; rollback;
```

| # | Call | Expected |
| --- | --- | --- |
| T0 | as `service_role`, recovery(D, B) | Succeeds; **characterises the residual**: E3 is still open, not a pass. |
| T1 | JWT A, recovery(D, B) | `42501 actor_mismatch`; no audit row added. |
| T2 | JWT A, recovery(D, A) | Succeeds; audit actor = A. |
| T3 | JWT A, unlink(F, K, B) | `42501 actor_mismatch`; no membership/audit write. |
| T4 | JWT A, unlink(F, K, A) | Succeeds as parent; audit actor = A. |
| T5 | `service_role`, remote_session(D, C, 'audio') | `42501 forbidden`; no `remote_sessions` row. |
| T6 | `service_role`, remote_session(D, A, 'audio') | Row with family F, parent A, status `requested`. |
| T7 | JWT A, remote_session(D, B, 'audio') | `42501 actor_mismatch`. |
| T8 | postcheck query in patch | `prosecdef=true`; `proconfig` = public, private, pg_temp; ACL unchanged. |

**NOT TESTED** until staging exists. **BLOCKED — G6**: Stage 1 records no staging/dev project
([06](../../stage1/06-secrets-and-environments.md)); run only after the G3 baseline is restored, or the comparison is against a different schema.

## 9. Rollback

1. Capture `pg_get_functiondef`, `proacl`, `proconfig` and `md5(prosrc)` for the three functions **before** apply
   (§6); the g1-b3b text is the fallback but may predate later edits.
2. `CREATE OR REPLACE` each function with the captured body, restating `SECURITY DEFINER` and its original
   `search_path`; for `request_remote_session` restore `set search_path = public, pg_temp` (F5 reversal). Do not
   change signatures.
3. Verify `prosrc` token/hash equality, `prosecdef`, `proconfig`, ACL and overload count.
4. Rollback is exact in behaviour and near-exact in text only if formatting is preserved; OID and ACL survive.
5. Rolling back reopens E1/E3 and needs the same approval (A10) plus a recorded reason. Unread bodies are not changed,
   so they need no rollback text in this patch — but any future extension is **BLOCKED** until captured.

## 10. Approvals and stop conditions

- **A5** apply to staging: Owner + reviewer; patch hash, pre-state capture, rollback text and test results.
- **A6** production is **out of scope for Stage 2**; any later use needs separate A6 approval after staging and the
  7-item gate in [I](I-risks-rollback-approvals.md) §4. This document authorises nothing. **A10** rollback; **A11** fixtures.
- Named decision required: accept the service-role residual (**E3/F7 stays OPEN**) or approve user-JWT DB calls.
  Without it, do not report the finding as closed.
- Stop if: approval gate missing; a signature/ACL/`proconfig` differs from capture; any unread body is touched;
  T0/T5/T6 fail; T1/T3/T7 do not raise `42501`; a legitimate service_role call fails; or staging parity is unproven.

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **S2-P02 remains `PROPOSED — NOT APPLIED`**, like S2-P01 and S2-P03; its SQL file in `docs/stage2/patches/` was not edited in this pass. Defects **D-05, D-06, D-07, D-08, D-09** (as numbered in [`patch-defects-before-a5.md`](../patch-defects-before-a5.md)) remain **OPEN** — none may be described as fixed.
- **E3/F7 stays OPEN after P02**, exactly as §1 argues: every live caller runs as `service_role`, where `auth.uid()` is `NULL`, so the `actor_mismatch` guard is inert on the deployed path and closes nothing by itself.
- **§8's `BLOCKED — G6` premise is superseded**: the staging shell exists (`parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)) but is an **empty shell** — 0 tables, no schema, no `private.s2_environment` sentinel, no secrets, no test principals, no Edge Functions. So T0–T8 cannot run: G5-S `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)` and G5-E `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`.
- **Rollback texts are not missing from the repository.** The original function bodies (prosrc) — `create_edge_api_token` etc. — **ARE captured**, at [`g1-b3b-20261029.json`](../../stage1/evidence/g1-b3b-20261029.json) lines 149/155/159/165 (metadata at lines 62/67/78). Any statement in this part — or quoted from it by [J-07](J-redteam.md) — that the rollback bodies exist nowhere in the repository is **false and superseded**: the §9 rollback is *assembled from captured text*, not absent.
- Approvals: **A5 unsigned**; the creation of the shell was an executed action awaiting retrospective ratification, not a signed A0/A2. [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`; the replacement package's A2′ authorises sentinel + approved settings only — no schema load, no secrets, no Firebase app registration. The plan of record uses A0–A3 and A5–A13 and has **no A4**.
- Identity authority is unchanged and confirmed: Supabase Auth only (all 9 Edge handlers call `db.auth.getUser(token)`); Firebase Auth is to remain disabled, FCM is not configured; Postgres, Edge Functions and Realtime are all Supabase.
- Auto-pause: a dated dashboard touch is required **on or before 2026-11-06** (approximate — no start timestamp recorded). Screenshots were never captured, so any screenshot-based test evidence is `NOT VERIFIED`.
- No operational action taken in this pass — no SQL, no capture, no dashboard or CLI action, nothing signed.
