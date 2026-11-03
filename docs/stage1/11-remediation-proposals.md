# 11 — Remediation proposals (F1–F8)

**Status: `PROPOSED — NOT APPLIED`.** Nothing in this document has been executed. Every statement below is a proposal
against the schema as captured on 2026-10-29 and 2026-10-30. F8 is new: it comes from the B3b read-only pass of
2026-10-30 and did not exist when the F1–F7 list was written.

Severity is one band per finding: **P1** = exploitable now, **P2** = exploitable under a small, plausible change or an
unread code path, **P3** = hygiene or availability of a feature. **No finding in this document is an observed exploit.**

| # | Finding | Band | Fix class | Approval needed |
| --- | --- | --- | --- | --- |
| F1 | Default privileges grant client roles on future tables | P2 | DDL — `ALTER DEFAULT PRIVILEGES` | Owner, on a maintenance window |
| F2 | Ownership transfer is impossible | P3 | Product decision, then DDL | Owner (product) + owner (migration) |
| F3 | `profiles_update_self` is column-agnostic and the trigger lets `'unset'` through | P3 | DDL — replace one trigger function | Owner |
| F4 | Leaked-password protection disabled | P2 | Auth setting toggle | Owner |
| F5 | `request_remote_session` omits `private` from `search_path` | P3 | DDL — `ALTER FUNCTION … SET search_path` | Owner |
| F6 | Two policies match no grant | P3 | Documentation, optionally DDL | Owner |
| F7 | Actor identity taken from an argument, not `auth.uid()` | P2 | DDL — function bodies | Owner + Edge Function review |
| F8 | Two `private` functions keep default `PUBLIC EXECUTE` | P3 | DDL — `REVOKE` | Owner |

---

## F1 — Default privileges leak future objects

**Root cause.** `pg_default_acl` carries explicit entries for `postgres` and `supabase_admin` in `public`, and they do
not cover the same object types:

| Owner | Tables | Sequences | Functions |
| --- | --- | --- | --- |
| `postgres` | `anon=Dxtm, authenticated=Dxtm` | `service_role=rU` only — no client grant | `postgres=X` only — no client grant |
| `supabase_admin` | `anon=arwdDxtm, authenticated=arwdDxtm` | `anon=rwU, authenticated=rwU` | `anon=X, authenticated=X` |

Any object created later by those roles in `public` inherits the grant. The 24 rows also show equivalent client grants
in `storage`, `graphql` and `graphql_public`; those are Supabase platform schemas, outside this finding's scope and not
proposed for change.

**Actual impact.** None today: all 19 existing tables carry hand-set grants, and `anon` holds no privilege on any of
them. The exposure is prospective. The dangerous part is `TRUNCATE` (`D`), which is **not** filtered by RLS: a table
created by `postgres` without an explicit `REVOKE` would be truncatable by any signed-in user the moment a Data API
route existed. `arwdDxtm` from `supabase_admin` is broader still, and its function and sequence defaults would make a
new helper callable rather than merely visible.

**Evidence.** [g1-q6](evidence/g1-q6-20261029.json) → `default_acl` (24 rows). No current table carries those grants
([g1-q6](evidence/g1-q6-20261029.json) → `table_grants`: 0 `anon` rows). The `public` rows are reproduced above.

**Recommended fix.** The `postgres` half is directly executable. The `supabase_admin` half needs an owner the project
does not currently have a credential for: `ALTER DEFAULT PRIVILEGES FOR ROLE` requires membership in that role, and
[g1-q6](evidence/g1-q6-20261029.json) `role_memberships` shows `postgres` is **not** a member of `supabase_admin`.
Confirm before preparing either statement:

```sql
select current_user,
       pg_has_role(current_user, 'postgres', 'member') as can_alter_postgres,
       pg_has_role(current_user, 'supabase_admin', 'member') as can_alter_supabase_admin;
```

Then, for the role(s) the check allows:

```sql
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated;
-- optional, no current leak for this owner but keeps the three object types aligned:
alter default privileges for role postgres in schema public
  revoke all on sequences, functions from anon, authenticated;

alter default privileges for role supabase_admin in schema public
  revoke all on tables, sequences, functions from anon, authenticated;
```

If `can_alter_supabase_admin` is false, do not prepare that statement here: record the `supabase_admin` rows as
**BLOCKED — needs a role the operator does not hold**, and treat the `postgres` table default as the actionable part.
Objects in `public` are normally created by `postgres` through migrations, so the `supabase_admin` defaults matter only
if a future path creates objects as that role.

Then grant per table, explicitly, at creation time. Do not try to fix this by granting RLS alone — `TRUNCATE` is not an
RLS-checked command.

**Compatibility impact.** None on existing objects: `ALTER DEFAULT PRIVILEGES` only affects objects created afterwards.
A future table created without an explicit grant becomes invisible to clients, which is the intended least-privilege
default and matches the current 0-of-19 exposure setting (P20). Any Edge Function that creates tables at runtime would
need its grants added — none does today.

**Rollback plan.** Record the exact pre-change `pg_default_acl` rows first; the inverse is not automatically derivable
because the ACL letters encode privileges a blanket `GRANT ALL` would over-grant (`a`, `r`, `w`, `d` were never held by
`anon`/`authenticated` here). For the `postgres` table row the inverse is
`grant truncate, references, trigger, maintain on tables to anon, authenticated` (the `Dxtm` letters), not `grant all`.

**Required approval.** Owner. This is DDL against production and it changes the default for every future migration.

**Verification test.** Read-only, before and after:
`select defaclrole::regrole, defaclnamespace::regnamespace, defaclobjtype, defaclacl from pg_default_acl;`
Pass = no entry in `public` mentions `anon` or `authenticated`. Full proof needs a throwaway table created in a
non-production project (G6) and `has_table_privilege` checked against it; creating a table in production is not an
acceptable test.

---

## F2 — Ownership transfer is impossible

**Root cause.** The policy `families_update_owner` is `USING (owner_id = auth.uid() AND deleted_at IS NULL)` with
`WITH CHECK (owner_id = auth.uid())` — the check drops the `deleted_at` condition. `authenticated` holds column UPDATE
on `families.name` and `families.settings` but **not** `owner_id` or `deleted_at`. `families_before_update` adds a
second block: it raises `family owner is immutable` on any `owner_id` change unless the caller is privileged. Three
controls, all pointing the same way.

One correction to the earlier reading: `WITH CHECK` is not identical to `USING`. It is stricter on ownership and looser
on deletion. That asymmetry is harmless today only because `authenticated` cannot write `deleted_at`; a future column
grant would let an owner set `deleted_at` on a live family (a soft delete they can already approximate by other means),
but would still not let them touch a row that is already deleted, because `USING` excludes it.

**Actual impact.** No hijack path and no accidental-transfer path. The cost is product-level: a family cannot change
owner at the database layer at all. If the UI ever offers "transfer ownership", it will silently fail.

**Evidence.** [g1-q6](evidence/g1-q6-20261029.json) (column grants), [g1-q2](evidence/g1-q2-20261029.json) (policy),
[g1-b3b](evidence/g1-b3b-20261029.json) (`families_before_update` body).

**Recommended fix.** Decide first, then act:

- **If transfer is out of scope** — do nothing at the database layer. Record the decision in the product spec so the
  absence is deliberate rather than discovered later. Preferred: zero schema change.
- **If transfer is required** — add one `SECURITY DEFINER` function
  `private.transfer_family_ownership(p_family_id uuid, p_new_owner uuid, p_actor uuid)` that: checks
  `p_actor = auth.uid()` **or** the caller is the service role; checks the actor is the current owner; checks the new
  owner is an active `parent` member of that family; updates `families.owner_id` and the two `family_members.role`
  values; writes an audit row. Grant it to `service_role` only, like the other 14.

**Compatibility impact.** The function route adds no policy and no table grant, so nothing that works today changes.
It does need `families_before_update` to keep permitting the privileged write — which it already does for the service
role. If the child app caches ownership, it must refresh.

**Rollback plan.** `drop function private.transfer_family_ownership(uuid, uuid, uuid);` — no data is migrated by
creating it. Once a transfer has been performed, rollback means transferring back, not dropping the function.

**Required approval.** Owner, twice: the product decision (does transfer exist?) and the migration.

**Verification test.** In a non-production project: as an owner, call the function with a valid parent → `owner_id`
changes, both audit and membership rows are consistent; with a non-member → `forbidden`; as a non-owner → `forbidden`.
In production, read-only: confirm the function exists with `proacl` = `postgres=X,service_role=X` and is absent from
the Data API exposure list.

---

## F3 — `profiles_update_self` is column-agnostic; the trigger does not compensate

**Root cause.** The policy filters rows (`id = auth.uid()`) but not columns. The only column-level control is the
UPDATE grant on `profiles.display_name`. `profiles_before_update` looks like a second control but is not one for new
accounts: it rejects a `role` change only when `old.role <> 'unset'`, so any profile still in `'unset'` — every account
created by `handle_new_user` — passes untouched.

**Actual impact.** None today: `update profiles set role = 'parent'` fails at column privilege before policy or trigger
runs. The risk is entirely in the "what if someone widens the grant" case, which is exactly the kind of change a future
migration makes without thinking about a trigger three files away. The current design has one control where the schema
appears to have two.

**Evidence.** [g1-q6](evidence/g1-q6-20261029.json) (column grants), [g1-q2](evidence/g1-q2-20261029.json) (policy),
[g1-b3b](evidence/g1-b3b-20261029.json) (`profiles_before_update`, `handle_new_user` bodies).

**Recommended fix.** Replace the trigger body so the column is protected regardless of the current value. The block
below is the **whole replacement body**, not a fragment: it keeps the `id` check, the `updated_at` maintenance and the
`return new`, and changes only the `if new.role is distinct from old.role then … end if` branch. Dropping any of the
three retained statements would make every `profiles` UPDATE fail or return NULL.

```sql
begin
  if new.id is distinct from old.id then
    raise exception 'profile id is immutable' using errcode = '42501';
  end if;
  if new.role is distinct from old.role
     and not (
       current_user in ('service_role', 'postgres', 'supabase_admin', 'supabase_auth_admin')
       or coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role'
     ) then
    raise exception 'profile role is immutable' using errcode = '42501';
  end if;
  new.updated_at := now();
  return new;
end;
```

i.e. delete the `old.role <> 'unset'` escape. Keep the column grant as the first control; the trigger becomes the second.
Onboarding already has to write the role through a privileged path (the Edge Function), which this preserves.

**Compatibility impact.** Any onboarding path that currently sets `role` while running as `authenticated` would start
failing. That is the point of the change, but it must be checked against the Edge Functions before deploying — if
onboarding does write the role as `authenticated`, that path is itself a bypass and needs fixing first. **This is the
one fix in this document with a credible chance of breaking a working flow**, so it should ship behind a test in G6.

**Rollback plan.** Keep the old body text; restore with `create or replace function`. No data is touched.

**Required approval.** Owner, plus a read of the onboarding Edge Function before deployment.

**Verification test.** Non-production, with two accounts: (a) `authenticated` update of `display_name` succeeds;
(b) `authenticated` update of `role` fails even when the row is `'unset'`; (c) service role update of `role` succeeds;
(d) `id` change still fails. Production, read-only after the fact: `select prosrc from pg_proc where proname =
'profiles_before_update'` contains no `'unset'` comparison.

---

## F4 — Leaked-password protection disabled

**Root cause.** The Supabase Auth setting is off; the advisor reports it as a WARN-level finding.

**Actual impact.** Supabase's leaked-password check compares new passwords against a breached-password corpus at signup
and reset. With it off, a user can set a password that is already in a public breach list. There is no database-side
control for this; it is an Auth service setting.

**Evidence.** [g1-q9](evidence/g1-q9-20261029.json) → `auth_leaked_password_protection`, level `WARN`, count 1.

**Recommended fix.** Enable it in the dashboard: Authentication → Sign In / Providers → Email → "Prevent use of leaked
passwords" (the exact label varies by dashboard version). No SQL, no code change.

**Compatibility impact.** Signup and password reset can now fail with a "weak/leaked password" error. Existing
passwords are not re-checked, so nobody is locked out. Clients must surface the new error message rather than
treating any 4xx as "network error".

**Rollback plan.** Flip the toggle back. Nothing else depends on it.

**Required approval.** Owner. It is a production setting change, but it is reversible in one click.

**Verification test.** Re-run the advisor (Refresh) → the rule disappears. Then attempt a signup in a non-production
project with a known-breached password → rejected.

---

## F5 — `request_remote_session` omits `private` from `search_path`

**Root cause.** `public.request_remote_session` sets `search_path = public, pg_temp`; 36 of the 38 functions set
`public, private, pg_temp`, and the only other exception is the guard in F8. Most likely a function written before the
`private` schema existed and never re-issued.

**Actual impact.** None exploitable: the path is pinned (not mutable by a caller), and the body references only
`public.*` objects plus `pg_advisory_xact_lock` / `hashtextextended`, which resolve in `pg_catalog` regardless of
`search_path`. The cost is inconsistency — a future edit that calls an unqualified `private.*` helper from this function
would fail at runtime, and reviewers would have to know which of the 38 functions has a different path.

**Evidence.** [g1-q7](evidence/g1-q7-20261029.json) (settings), [g1-b3b](evidence/g1-b3b-20261029.json) (`inventory`),
body in [g1-b3b](evidence/g1-b3b-20261029.json) (`bodies`).

**Recommended fix.**

```sql
alter function public.request_remote_session(uuid, uuid, text)
  set search_path = public, private, pg_temp;
```

**Compatibility impact.** None. The function's resolution behaviour for every identifier in the body is unchanged.

**Rollback plan.** `alter function … set search_path = public, pg_temp;` — restores the captured value exactly.

**Required approval.** Owner. Small, but it is a production DDL statement.

**Verification test.** Read-only: `select proname, proconfig from pg_proc where proname = 'request_remote_session';`
→ exactly one row, `{search_path=public, private, pg_temp}`.

---

## F6 — Two policies match no grant

**Root cause.** `devices_select_parent_or_child` and `safe_zones_insert_parent` are correct policies on verbs the
`authenticated` role cannot perform: there is no SELECT grant on `devices` and no INSERT grant on `safe_zones`. They
were written for a direct-client access model that the project then chose not to use (0 of 19 tables exposed).

**Actual impact.** No exposure — the opposite. The cost is a misleading schema: a reviewer reading 21 policies concludes
21 client operations are guarded, when two of them cannot happen. That is how a real gap later hides behind a
plausible-looking policy.

**Evidence.** [g1-q1](evidence/g1-q1-20261029.json) (RLS on), [g1-q2](evidence/g1-q2-20261029.json) (policies),
[g1-q6](evidence/g1-q6-20261029.json) (grants), [g1-b3b](evidence/g1-b3b-20261029.json) (`data_api_exposure`).

**Recommended fix.** Documentation first: record in [04-rls-matrix.md](04-rls-matrix.md) that 15 SELECT policies exist
but only 14 SELECT grants do, and that device reads and safe-zone inserts are Edge Function operations. If the project
prefers the schema to state the truth, drop the two policies in a later migration:

```sql
drop policy devices_select_parent_or_child on public.devices;
drop policy safe_zones_insert_parent on public.safe_zones;
```

Dropping is optional and is a **harder** decision than it looks: if a future migration grants the verb, the policy that
would have protected it is gone. The safer order is "document now, drop only together with a decision that these
operations stay server-side".

**Compatibility impact.** Documentation: none. Dropping: none today (no grant), but it removes a safety net for a future
grant.

**Rollback plan.** Recreate the policy from the captured `qual` / `with_check` in
[g1-q2](evidence/g1-q2-20261029.json) — the text is stored verbatim, so this is exactly reversible.

**Required approval.** Owner, and only if dropping. The documentation half needs no approval.

**Verification test.** Read-only: count policies per (table, cmd) against
`information_schema.role_table_grants` for `authenticated`. Pass = every policy has at least one matching grant, or is
listed as intentionally server-side.

---

## F7 — Actor identity is taken from an argument, not from `auth.uid()`

**Root cause.** The `private` implementations accept the acting user as a parameter and never compare it with
`auth.uid()`. Two observed consequences:

- `private.request_device_recovery(p_device_id, p_actor_user_id)` only requires that `p_actor_user_id` is **some** active
  parent of that device's family. Any parent can therefore act under another parent's id, and the audit row written by
  `record_audit` records the forged actor.
- `public.request_remote_session(p_device_id, p_parent_user_id, p_kind)` does not check the parent at all: it writes the
  argument straight into `remote_sessions.parent_user_id`.

The two `public` entry points are `service_role`-only, so today the real control is that the Edge Function derives the
id from the verified JWT. `private.request_device_recovery` is the exception: it still carries the default `PUBLIC
EXECUTE` (F8), but `private` is not an exposed schema and `anon` has no `USAGE` on it, so there is no client route. The
database does not enforce the identity binding at any layer.

**Actual impact.** Not exploitable by a client (P12: no client role holds EXECUTE). It is a trust-boundary defect: the
design assumes every caller is a correct Edge Function. If any Edge Function forwards a client-supplied id, or if one
is added later that does, the effect is within-family impersonation and a false audit trail — the worst kind of defect
in a safety product, because the audit log is what a parent would rely on after an incident. Cross-family action is
blocked by the family check that does exist.

**Evidence.** [g1-b3b](evidence/g1-b3b-20261029.json) `bodies` → `request_device_recovery` (private and public),
`request_remote_session`, `unlink_child` (which does compare: `p_actor_user_id <> p_child_user_id` gates the parent
check).

**Recommended fix.** Add an identity assertion at the top of every actor-taking body, keeping the argument for
service-role callers. Substitute each function's own actor parameter: `p_actor_user_id` in
`request_device_recovery` and `unlink_child`, `p_parent_user_id` in `request_remote_session`:

```sql
if auth.uid() is not null and <actor parameter> is distinct from auth.uid() then
  raise exception 'actor_mismatch' using errcode = '42501';
end if;
```

Under `service_role`, `auth.uid()` is null and the argument remains authoritative. Under any user JWT the function
stops trusting the caller. Apply to the two read implementations (`private.request_device_recovery`,
`private.unlink_child`) and to each of the 11 unread `private` implementations as they are read (PA3);
`private.record_audit` is unread too. None of the 11 may be assumed safe.

**Compatibility impact.** Edge Functions running as `service_role` are unaffected (`auth.uid()` is null). A client
calling directly is already blocked by the grant, so nothing that works today breaks. Anything that calls these as
`authenticated` in a test harness would start failing — which is the desired signal.

**Rollback plan.** `create or replace function` with the captured original bodies
([g1-b3b](evidence/g1-b3b-20261029.json) stores them verbatim for the two read implementations). The 11 unread bodies
must be captured before they are changed, or the rollback text does not exist.

**Required approval.** Owner. The Edge-tier statement this change depends on now exists: Phase E confirmed that every
handler derives the actor from the verified JWT ([14](14-edge-function-security-audit.md) §4). What remains is the SQL
tier itself (F7/E3).

**Verification test.** Non-production, with a role granted EXECUTE for the test: set
`request.jwt.claims` to user A, call `request_device_recovery(device_of_A_family, B)` where B is another parent →
`actor_mismatch`. Call with A → succeeds. Then confirm the audit row actor equals the JWT subject.

---

## F8 — Two `private` functions keep the default `PUBLIC EXECUTE`

**Root cause.** Of the 38 functions, 27 carry an explicit `proacl` of `postgres=X,service_role=X`; four policy helpers
carry `postgres=X,authenticated=X`; and **five carry `postgres=X` only** (`private.audit_logs_append_only`,
`private.families_before_update`, `private.handle_new_user`, `private.profiles_before_update`, `private.set_updated_at`).
The two outliers are `private.request_device_recovery` and `private.remote_session_transition_guard`, which have
`proacl = NULL`, i.e. the PostgreSQL default of `EXECUTE TO PUBLIC`. The most likely cause is that these two were created
by a path that skipped the `REVOKE` applied to their siblings. `remote_session_transition_guard` additionally pins
`search_path = public, pg_temp`, unlike every other trigger function in `private`.

**Actual impact.** Latent, not live. Three facts keep it closed: `private` is **not** in the Data API exposed-schema list
(`public` + `extensions` only); `anon` has no `USAGE` on schema `private`; and `remote_session_transition_guard` returns
`trigger`, which no REST layer exposes. `authenticated` **does** hold `USAGE` on `private`, so the two grants are one
`GRANT USAGE`-equivalent change away from being live. `request_device_recovery` is a real RPC implementation, so if
`private` were ever added to the exposed schemas it would become callable by any signed-in user — subject still to the
in-body family check (F7), but with no Edge Function in front of it.

`remote_session_transition_guard`'s body touches only `OLD`/`NEW`, so the narrower `search_path` is not exploitable; the
inconsistency is still worth removing while the file is open.

**Evidence.** [g1-b3b](evidence/g1-b3b-20261029.json) → `inventory` (`remote_session_transition_guard`,
`request_device_recovery`), `data_api_exposure` (schemas exposed = `public`, `extensions`), `schema_usage`
(`anon: false`), `bodies` (guard body), `remote_session_triggers`.

**Recommended fix.**

```sql
revoke all on function private.request_device_recovery(uuid, uuid) from public;
revoke all on function private.remote_session_transition_guard() from public;
grant execute on function private.request_device_recovery(uuid, uuid) to service_role;
alter function private.remote_session_transition_guard() set search_path = public, private, pg_temp;
```

The `grant` mimics the 27 `postgres=X,service_role=X` siblings. The guard needs no `grant`: it is only ever invoked as a
trigger, and trigger execution does not consult the invoker's `EXECUTE` privilege, so the `REVOKE` leaves it at
`postgres=X` like the other trigger functions. That is the intended shape, not an omission.

**Compatibility impact.** None. Only `service_role` (and the owner) call the recovery function, and the guard is never
called directly by anyone.

**Rollback plan.** `grant execute on function … to public;` restores the captured **behaviour** (PUBLIC can execute), but
not the byte-identical `NULL` ACL: after the grant the ACL is an explicit `=X/postgres` entry. Resetting `proacl` to NULL
would require a direct catalogue update, which is not proposed. Treat the rollback as functionally equivalent, and record
that difference in the change log.

**Required approval.** Owner. Pure `REVOKE`/`GRANT` on two objects — no behaviour change intended.

**Verification test.** Read-only:
`select proname, proacl, has_function_privilege('anon', oid, 'EXECUTE') as anon,
 has_function_privilege('authenticated', oid, 'EXECUTE') as auth
 from pg_proc where proname in ('request_device_recovery','remote_session_transition_guard')
 and pronamespace = 'private'::regnamespace;`
Pass = `auth = false` on both, `anon = false` on both.

---

## Cross-cutting item — the duplicated function set

Not a finding with a fix of its own, but it should shape the G3 baseline:

`public` holds 14 RPC wrappers; `private` holds 24 functions, 13 of which share a name and signature with a `public`
twin. `private.record_audit` has no `public` twin and `public.request_remote_session` has no `private` twin. The ACLs
differ between twins in two cases (F8). `public.request_device_recovery` is a one-line wrapper around the `private`
implementation, which suggests its 12 sibling wrappers are wrappers too — but that is **inferred from one body**, not
verified (PA3).

Consequence for G3: the baseline must capture both schemas. A baseline limited to `public` would reproduce 14 empty
wrappers and none of the logic.

## What this document is not

- It is not a fix. Nothing was executed, no statement was prepared against the live project.
- It is not a penetration test. No negative test was run against production; every "fails with" statement is a
  prediction from the catalogue and the body text.
- It does not cover the 11 unread `private` implementations, the 12 unread `public` RPC bodies, `private.record_audit`,
  or any behaviour that requires authenticated test users (G5/G6). The seven previously unread Edge Functions were read
  at identifier level in Phase E ([13](13-edge-function-source-inventory.md), [14](14-edge-function-security-audit.md)).
