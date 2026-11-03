# 08 — Verification and test matrix

Status: **`PARTIAL`** — the §0 introspection queries were executed read-only on 2026-10-29 and their results are in
`evidence/g1-*.json`; the B3b body read followed on 2026-10-30 (`evidence/g1-b3b-*.json`). No row in §1 has had a live
request run against it. Three read-only rows are `PARTIAL` because the catalogue now predicts their outcome; the rest are
`BLOCKED — NOT EXECUTED`. Context:
[01-baseline-inventory.md](01-baseline-inventory.md), [03-data-model.md](03-data-model.md), [04-rls-matrix.md](04-rls-matrix.md),
[05-change-plan.md](05-change-plan.md), [06-secrets-and-environments.md](06-secrets-and-environments.md).

## 0. Introspection queries (read-only, safe on the live project)

These are plain `SELECT`s. They change nothing; the set was executed read-only on 2026-10-29 and is retained for re-runs
(one query at a time, dashboard SQL Editor, the wrapper in the G1 record below). The original note that they were the
fastest way to unblock the audit "without exporting a token or password" referred to gate G1, which is now answered. Paste
one at a time into the dashboard SQL Editor and return the single JSON value each produces. Every statement is
self-contained.

**Syntax review (2026-10-29, before execution).** All ten SQL blocks (Q1–Q8, Q3b, Q10) were parsed locally with `libpg_query`
via pglast 8.7, which bundles the PostgreSQL 18 parser, and all parse cleanly. Grammar acceptance is not execution: parse
analysis, type resolution and privilege checks still happen on the server, which is why the three type defects below were
found by reading the catalogue definitions rather than by the parser. Compatibility floor is PostgreSQL 11
(`pg_proc.prokind`); every construct used predates the version Supabase runs, and the live server version is confirmed in
[10-owner-runbook.md](10-owner-runbook.md) §2.

**G1 query set: `EXECUTED READ-ONLY 2026-10-29`.** Q1–Q8, Q3b and Q10 ran in the project's SQL Editor, one per
`begin transaction read only; … commit;` wrapper with `transaction_read_only = on` confirmed before the first catalogue
query; Q9 was read from the dashboard advisor. Results are in `evidence/g1-*.json` with provenance in
`evidence/g1-run-manifest-20261029.md`. Running successfully is not a PASS: the interpretation of those results lives in
[00-status-register.md](00-status-register.md) and [04-rls-matrix.md](04-rls-matrix.md).

| Query | Was | Why it is unsafe | Now |
| --- | --- | --- | --- |
| Q1 | `c.relacl::text[]` | `aclitem[]` has no element cast to `text`; an array cast needs a `pg_cast` entry per element, so this raises `cannot cast type aclitem[] to text[]` | `array_to_string(c.relacl, ',')` — uses each element's output function, so it cannot fail on type resolution |
| Q6 | `defaclacl::text[]` | same | `array_to_string(defaclacl, ',')` |
| Q7 | `p.proacl::text[]` | same | `array_to_string(p.proacl, ',')` |

**Q10 and Q3b are new.** Q3 filters `n.nspname = 'public'`, so it cannot see the signup trigger on `auth.users`; Q3b
closes that gap without reading any table. Q10 exists because Q6 reads `role_table_grants` and `column_privileges`, which
cover tables and columns only. Routine privileges live in `role_routine_grants`, and even that view omits access inherited
through `PUBLIC`: a function whose `proacl` is NULL — the default for a new function — grants `EXECUTE` to `PUBLIC` and
yields no per-role row at all. Q6 therefore cannot answer the RPC question, which is the highest-severity open item.

Run each statement as in [10-owner-runbook.md](10-owner-runbook.md): one query per `begin transaction read only; … commit;`
wrapper, with `show transaction_read_only;` expected to return `on`.

**Q1 — RLS flags per table** (turns the inferred RLS state into observed; `relforcerowsecurity` matters for owner-run functions). Result: 19 of 19 enabled, 0 forced — [g1-q1](evidence/g1-q1-20261029.json).

```sql
select json_agg(t order by t.table_name) as rls_flags from (
  select c.relname as table_name, c.relrowsecurity as rls_enabled,
         c.relforcerowsecurity as rls_forced,
         pg_get_userbyid(c.relowner) as owner,
         coalesce(array_to_string(c.relacl, ','), '(null = owner-only default)') as table_acl
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r','p')
) t;
```

**Q2 — All policies with expressions** (the missing half of [04-rls-matrix.md](04-rls-matrix.md)). NULL is normal where
the command has no such expression, and the command decides which one applies. A SELECT policy carries `qual` alone and
Postgres rejects `WITH CHECK` on it; DELETE likewise. An INSERT policy has no `USING`, so `qual` is NULL **by design** and
`with_check` is its only expression — that is the case for the two INSERT policies here. UPDATE uses `USING` for the rows
it may see and `WITH CHECK` for the rows it may write; when `WITH CHECK` is omitted Postgres reuses `USING`, so a NULL
check is not itself a defect. The findings are: a NULL `qual` on a **PERMISSIVE** SELECT, DELETE or UPDATE policy
(nothing filters rows; on a RESTRICTIVE policy a NULL expression restricts nothing and must be read with its siblings),
a NULL `with_check` on an INSERT policy (nothing checks the new row), and a `WITH CHECK` weaker than or disagreeing with
`USING`. Expected here: 19 of the 21 policies have a non-null `qual`; the 2 INSERT policies are NULL by design.

```sql
select json_agg(p order by p.tablename, p.policyname) as policies from (
  select tablename, policyname, permissive, cmd,
         array_to_string(roles, ',') as roles, qual, with_check
  from pg_policies where schemaname = 'public'
) p;
```

**Q3 — Triggers** (profile creation from `auth.users`, `updated_at` maintenance, any `role` guard).

```sql
select json_agg(t order by t.table_name, t.trigger_name) as triggers from (
  select c.relname as table_name, tg.tgname as trigger_name,
         pg_get_triggerdef(tg.oid) as definition, p.proname as function_name,
         p.prosecdef as security_definer, tg.tgenabled as enabled_flag
  from pg_trigger tg join pg_class c on c.oid = tg.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  join pg_proc p on p.oid = tg.tgfoid
  where n.nspname = 'public' and not tg.tgisinternal
) t;
```

**Q3b — Triggers on `auth.users`** (the signup path that creates `profiles`; its existence is **not** assumed). Q3 cannot
see this trigger because it filters `public`. The query reads catalogue rows only and never references `auth.users` as an
object, so it needs no `USAGE` on the `auth` schema and no `SELECT` on the table. An empty array means there is no
user-defined trigger on `auth.users` — record that as a finding, not as a failed query.

```sql
select coalesce(json_agg(t order by t.trigger_name), '[]'::json) as auth_users_triggers from (
  select n.nspname as table_schema, c.relname as table_name, tg.tgname as trigger_name,
         pg_get_triggerdef(tg.oid) as definition, tg.tgenabled as enabled_flag,
         fn.nspname as function_schema, p.proname as function_name,
         p.prosecdef as security_definer,
         coalesce(array_to_string(p.proconfig, ','), '(null = no pinned settings)') as function_settings
  from pg_trigger tg join pg_class c on c.oid = tg.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  join pg_proc p on p.oid = tg.tgfoid
  join pg_namespace fn on fn.oid = p.pronamespace
  where n.nspname = 'auth' and c.relname = 'users' and not tg.tgisinternal
) t;
```

`coalesce(..., '[]'::json)` is used here, unlike Q1/Q3, because "no trigger exists" is a meaningful audit result and must
not be indistinguishable from SQL NULL at a glance. An empty array means **no matching non-internal row**; it does not by
itself prove `auth.users` exists. On Supabase that table is guaranteed, so an empty array is read as "no user-defined
signup trigger" — but if you want that stated in the evidence, confirm the relation first with a one-line
`select c.relkind from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'auth' and c.relname = 'users';`.
`tgenabled`: `O` enabled, `D` disabled, `R` replica-only, `A` always. The trigger function's body is not
returned — `prosrc` is deliberately excluded (see Q7).

**Q4 — Indexes** (uniqueness supporting idempotency and pairing-code replay protection).

```sql
select json_agg(i order by i.table_name, i.index_name) as indexes from (
  select tablename as table_name, indexname as index_name, indexdef as definition
  from pg_indexes where schemaname = 'public'
) i;
```

**Q5 — Constraints including foreign keys** (family scoping columns, cascade behaviour, unique keys).

```sql
select json_agg(k order by k.table_name, k.constraint_name) as constraints from (
  select con.conname as constraint_name, rel.relname as table_name,
         con.contype as kind, pg_get_constraintdef(con.oid) as definition,
         tgt.relname as referenced_table, con.confdeltype as on_delete_code,
         con.convalidated as validated
  from pg_constraint con join pg_class rel on rel.oid = con.conrelid
  join pg_namespace n on n.oid = rel.relnamespace
  left join pg_class tgt on tgt.oid = con.confrelid
  where n.nspname = 'public' and con.contype in ('p','u','f','c','x')
) k;
```

**Q6 — Table grants, column grants, default privileges, role membership** (posture if a table were ever exposed; the `profiles.role` guard).

```sql
select json_build_object(
 'table_grants', (select json_agg(g order by g.table_name, g.grantee, g.privilege_type) from (
   select table_name, grantee, privilege_type, is_grantable
   from information_schema.role_table_grants
   where table_schema = 'public' and grantee in ('anon','authenticated','service_role')) g),
 'update_column_grants', (select json_agg(g order by g.table_name, g.column_name, g.grantee) from (
   select table_name, column_name, grantee, privilege_type
   from information_schema.column_privileges
   where table_schema = 'public' and privilege_type = 'UPDATE'
     and grantee in ('anon','authenticated','service_role')) g),
 'default_acl', (select json_agg(d order by d.owner, d.schema_name, d.object_type) from (
   select pg_get_userbyid(defaclrole) as owner, defaclnamespace::regnamespace::text as schema_name,
          defaclobjtype as object_type,
          coalesce(array_to_string(defaclacl, ','), '(null)') as acl from pg_default_acl) d),
 'role_memberships', (select json_agg(m order by m.role, m.member) from (
   select r.rolname as role, mem.rolname as member, am.admin_option
   from pg_auth_members am join pg_roles r on r.oid = am.roleid
   join pg_roles mem on mem.oid = am.member) m)
) as grants_and_roles;
```

**Q7 — Functions with security definer, settings and ACL** (helper predicates, `auth.users` trigger function, search-path hygiene).

```sql
select json_agg(f order by f.function_name) as functions from (
  select p.proname as function_name,
         pg_get_function_identity_arguments(p.oid) as arguments,
         l.lanname as language, p.prosecdef as security_definer,
         p.provolatile as volatility, p.proconfig as settings,
         coalesce(array_to_string(p.proacl, ','), '(null = default PUBLIC EXECUTE)') as acl,
         pg_get_userbyid(p.proowner) as owner
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  join pg_language l on l.oid = p.prolang
  where n.nspname in ('public','auth') and p.prokind = 'f'
) f;
```

`prosrc` is deliberately **not** selected. Function bodies are the one place a pasted catalogue row can carry a literal
credential (a hard-coded key, a webhook URL with a token). Fourteen bodies were read separately on 2026-10-30 (B3b) and
filed in [g1-b3b](evidence/g1-b3b-20261029.json) under a recorded sanitisation note; 24 remain unread. For any future body
read, run a separate `select prosrc ...` **in your own session**, redact any literal secret, and paste only the redacted
body. Never paste a raw `prosrc` into chat or into `evidence/`.

**Q8 — Columns** (confirms the family-scoping column names needed to write the tests below; also exposes any column holding a token).

```sql
select json_agg(c order by c.table_name, c.ordinal_position) as columns from (
  select table_name, column_name, ordinal_position, data_type,
         is_nullable, column_default
  from information_schema.columns where table_schema = 'public'
) c;
```

**Q9 — Security advisor findings: not available as SQL.** Captured on 2026-10-29 from the dashboard's own `run-lints`
response and filed as [g1-q9](evidence/g1-q9-20261029.json). The UI groups the result as **1 warning + 4 suggestions**,
while the underlying response returns **5 distinct rules across 33 rows**, of which 2 rules (15 rows) are WARN-level and 3 rules (18 rows) are INFO; the difference
is presentation, not data. Copy any future finding's title and description by hand (no secrets appear there). Q7 lets you
pre-empt the most likely rule, `function_search_path_mutable`: any `security_definer = true` row whose `settings` is null
or lacks `search_path=...`. No public function matches that pattern. The `private` schema was out of Q7's scope and was
read on 2026-10-30: 23 of its 24 functions pin `public, private, pg_temp`; `remote_session_transition_guard` pins
`public, pg_temp` and `request_remote_session` does the same in `public` (F5, F8).

**Q10 — RPC surface: can `anon` / `authenticated` actually execute the functions?** This is the decisive query for the
highest-severity open item. `has_function_privilege` accounts for `PUBLIC` grants and role membership, which a raw ACL
listing does not. `extension_owned` separates functions installed by an extension from functions written for this app.

```sql
select json_build_object(
  'schema_usage', json_build_object(
     'anon', has_schema_privilege('anon', 'public'::text, 'USAGE'::text),
     'authenticated', has_schema_privilege('authenticated', 'public'::text, 'USAGE'::text)),
  'functions', (select json_agg(f order by f.function_name, f.arguments) from (
     select p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as arguments,
            pg_get_userbyid(p.proowner) as owner,
            p.prosecdef as security_definer,
            p.proconfig as settings,
            has_function_privilege('anon', p.oid, 'EXECUTE') as anon_exec,
            has_function_privilege('authenticated', p.oid, 'EXECUTE') as auth_exec,
            has_function_privilege('service_role', p.oid, 'EXECUTE') as service_exec,
            exists (select 1 from pg_depend d
                    where d.classid = 'pg_proc'::regclass and d.objid = p.oid
                      and d.deptype = 'e') as extension_owned,
            coalesce(array_to_string(p.proacl, ','), '(null = default: owner + PUBLIC)') as acl
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.prokind = 'f'
  ) f)
) as rpc_surface;
```

Reading it: `anon_exec = true` on any function with `extension_owned = false` is a security finding — report it
immediately and investigate before running anything else. Severity is set after the body is read, not from the grant
alone, and reachability also needs `schema_usage = true` for the calling role. One nuance: a function returning `trigger`
cannot be invoked directly (PostgreSQL refuses, and PostgREST does not expose it), so for those the grant is a
least-privilege observation rather than a call path — Q10 does not report the return type, so treat that distinction as a
question to settle when the body is read. For the five actor-less functions — `poll_device_commands`,
`replace_device_apps`, `expire_stale_commands`, `detect_offline_devices`, `expire_stale_sessions` — `auth_exec = true` is
also a finding to investigate, because the only argument is a guessable identifier. For the nine functions that take an
actor id, `auth_exec = true` is not a finding by itself, but it obliges proof that the body takes the caller's identity
from `auth.uid()`, ignores or equals-checks the argument, authorises any cross-user case explicitly, and rejects a NULL
`auth.uid()`. Q2 shows what the policies actually do: every predicate scopes by family membership, device ownership or
session participation, and 14 of the 15 SELECT predicates delegate the family test to `private.is_family_parent`,
`private.is_family_member` or `private.shares_active_family` — so those helpers are called by policies, not exposed as
routes. Their bodies were read on 2026-10-30 ([g1-b3b](evidence/g1-b3b-20261029.json)): each anchors on `auth.uid()`,
requires active membership and a non-deleted family, and contains no dynamic SQL. Rows with
`extension_owned = true` are held separately as a platform/extension observation — an extension row with
`anon_exec = true` is recorded there, never merged into the app-owned finding and never dropped from the record.
`service_exec = true` is expected for Edge Functions using the service role and is not a finding by itself. No `REVOKE`
has been applied; any revocation is **PROPOSED — NOT APPLIED** and approval-gated. Match rows by `function_name`, not by
the shorthand signatures above: `pg_get_function_identity_arguments` also shows argument types and defaults.

## 1. Test matrix

`Method` values marked **[DEV ONLY]** mutate state or consume a one-time secret and are subject to §2. Every row is still
blocked for execution: no test identity, no second environment and no live request exist. T-01, T-02 and T-18 are marked
`PARTIAL` because the catalogue and policy evidence now predicts their outcome, not because the test was performed.

| ID | Objective | Precondition | Method | Expected result | Status | Evidence required |
| --- | --- | --- | --- | --- | --- | --- |
| T-01 | Anonymous read is denied on all 19 tables | Anon key; Data API globally on | `GET /rest/v1/<table>?select=*` with the anon key for each table; in SQL `set role anon;` (where the editor account may assume it) + `select count(*)`, then `reset role;` | PostgREST returns "table not found" / no route; SQL returns 0 rows for all 19 | PARTIAL — CATALOGUE VERIFIED, NO LIVE REQUEST: `anon` holds no table privilege on any of the 19 ([g1-q6](evidence/g1-q6-20261029.json)), so a request cannot read rows; the HTTP status was not observed | HTTP status + body; per-table SQL row counts |
| T-02 | Authenticated non-member read is denied | A signed-in identity with no `family_members` row (one of 8 profiles appears unaffiliated — NOT VERIFIED) | With that JWT: read `devices`, `families`, `location_events` through the API and, if claims can be set, via SQL | 0 rows everywhere | PARTIAL — POLICY READ, NO LIVE REQUEST: the SELECT policies scope by `is_family_parent` / `is_family_member` / `auth.uid()` ([g1-q2](evidence/g1-q2-20261029.json)); an unaffiliated identity matches none, but no request was made |
| T-03 | Cross-family read denied — `devices` | Two families with devices; member of family A | As A, `select * from devices` and targeted `where id = <B device>` | Only A's rows; targeted read returns 0 | BLOCKED — NOT EXECUTED | Row counts, A/B ids hashed |
| T-04 | Cross-family read denied — `location_events` | 1,773 rows across ≥2 families | As A, count rows for B's device id and a date range | 0 | BLOCKED — NOT EXECUTED | Counts only; no coordinates in evidence |
| T-05 | Cross-family read denied — `safety_alerts` | Alerts exist in B | As A, select by B alert id | 0 | BLOCKED — NOT EXECUTED | Counts, ids hashed |
| T-06 | Cross-family read denied — `device_commands` | Commands exist in B | As A, select by B command id | 0 | BLOCKED — NOT EXECUTED | Counts, ids hashed |
| T-07 | Cross-family read denied — `family_members` | A and B populated | As A, select members of B's family id | 0 | BLOCKED — NOT EXECUTED | Counts; no emails/names |
| T-08 | Insert on `devices` is service-role only **[DEV ONLY]** | Non-prod; throwaway family | Insert as `authenticated`, then as `anon`, then via Edge Function | Denied for both client roles; succeeds only via service role | BLOCKED — NOT EXECUTED | Error code (`42501` vs success), function request id |
| T-09 | Insert on `location_events` is service-role only **[DEV ONLY]** | Non-prod; test device | Insert a synthetic point as `authenticated` | Denied (`42501` or 0 rows, no policy) | BLOCKED — NOT EXECUTED | Error code; inserted row absent |
| T-10 | `audit_logs` insert is service-role only, append-only for clients **[DEV ONLY]** | Non-prod; one audit row | INSERT / UPDATE / DELETE as `authenticated`; then the same three as service role | All three denied for `authenticated` (no policy); service role can append, and whether it may UPDATE/DELETE is a design decision, not a client control | BLOCKED — NOT EXECUTED | Error codes; row snapshots before/after |
| T-11 | A pairing token is not a credential **[DEV ONLY]** | Non-prod; one issued token (27 rows exist in prod) | Send the token as `Authorization: Bearer` / `apikey` to each Edge Function, and try it as a PostgREST `apikey` | Every path rejected; the token grants no session and is not a database credential | BLOCKED — NOT EXECUTED | Per-endpoint status; function logs (ids only) |
| T-12 | Expired or reused pairing code is rejected **[DEV ONLY]** | Non-prod; a code past `expires_at` and one already consumed | Submit expired code; then replay a consumed code; then replay a token | Distinct rejection for expired vs consumed vs replayed; no new `device_pairing_tokens` row | BLOCKED — NOT EXECUTED | Response codes; before/after token counts |
| T-13 | `profiles.role` self-escalation is denied **[DEV ONLY]** | Non-prod; a `child` profile, and one profile still in `'unset'` | `update profiles set role='parent' where id = auth.uid()`; repeat on the `'unset'` row; also via Edge Function | Denied before the trigger runs — `authenticated` has no column UPDATE on `profiles.role`. If the grant were ever widened, the trigger would catch the `child` row but **not** the `'unset'` row (F3) | BLOCKED — NOT EXECUTED | Error text; before/after role |
| T-14 | `safe_zones` write denied for a non-parent member **[DEV ONLY]** | Non-prod; child in family A, one zone | INSERT, UPDATE (incl. changing `family_id`), DELETE as the child; repeat as parent | Child denied on all three; parent allowed; zone cannot change family | BLOCKED — NOT EXECUTED | Per-verb error codes; zone row snapshots |
| T-15 | `webrtc_signals` insert is scoped to session participants **[DEV ONLY]** | Non-prod; two sessions, caller in one | Insert a signal row referencing the other session; then the own session | Foreign session denied; own session allowed | BLOCKED — NOT EXECUTED | Error code; row counts per session |
| T-16 | `device_commands` dispatch is idempotent **[DEV ONLY]** | Non-prod; one device, one command | Submit the same command/idempotency key twice and in parallel; count rows | Exactly one command row and one delivery; replay returns the original result | BLOCKED — NOT EXECUTED | Row counts, response bodies, function logs |
| T-17 | `families_update_owner` cannot be hijacked **[DEV ONLY]** | Non-prod; family A owned by A1 | As A1, set `owner_id` to a user outside A; then to A2 (an in-family parent) | Both denied: `authenticated` has no column UPDATE on `owner_id`, and `families_before_update` raises `family owner is immutable` for any privileged caller that tries. There is **no** in-family transfer path at the database layer; a transfer needs the proposed F2 function, which does not exist | BLOCKED — NOT EXECUTED | Error code (column privilege / `42501`); before/after owner id |
| T-18 | The four deny-all tables return nothing to clients | `authenticated` and `anon` identities | `select count(*)` on `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states` | 0 rows / permission denied for both roles | PARTIAL — CATALOGUE VERIFIED, NO LIVE REQUEST: all four are RLS-enabled with zero policies and no `anon`/`authenticated` grant ([g1-q1](evidence/g1-q1-20261029.json), [g1-q2](evidence/g1-q2-20261029.json), [g1-q6](evidence/g1-q6-20261029.json)); counts not taken |
| T-19 | Edge Functions act as service role, not as the caller | Function source or logs; one signed-in identity | Review each of the 9 functions for `createClient` key choice; if caller-scoped, replay T-03…T-07 through it | Every function uses the service role internally and authorizes the caller in code; no function forwards the user JWT to the database. This code-side check is the control that stands in for `auth.uid()`: the actor argument in the RPCs is not bound to the JWT (F7/E3) | **PARTIAL — SOURCE VERIFIED 2026-10-30, NO LIVE CALL**: all nine use `SUPABASE_SERVICE_ROLE_KEY` ([14](14-edge-function-security-audit.md) check 12, [capture](evidence/edge-functions/capture-20261030.json)); the replay half needs an identity and a deployed call | Per-function location in [13](13-edge-function-source-inventory.md); a live call excerpt (no keys) still owed |

## 2. Environment constraint on mutating tests

Every test marked **[DEV ONLY]** writes rows, consumes a one-time secret, or changes an auth identity. Those must run
against a **non-production** project with synthetic data. **Only one environment exists** (`parent-control-prod`, holding
1,773 location events, 39 remote sessions, 8 profiles and 10 MAU — see G6 in [05-change-plan.md](05-change-plan.md)), so:

- T-08 … T-17 are **additionally blocked by the single-environment fact**, independent of the G1 catalogue work (G1 and
  B3b are closed). Gaining SQL access will not unblock them.
- Creating a `dev` project, or a throwaway family inside prod, is a decision for the project owner and is out of scope
  here. No test user, family or row is to be created in production to make a test runnable.
- T-01, T-02, T-18 are read-only and safe on prod. T-03 … T-07 are read-only *if* suitable existing identities are
  available; they must never be widened into writes to "set up" data.
- T-01's SQL form uses `set role anon; … reset role;`. That is a session-scoped role switch, not a write, and it must end
  with `reset role`; it is not part of any G1 catalogue query and must never be left active in a shared editor session.
- T-19 needs no database writes. Its source half was completed in Phase E from the dashboard editor on 2026-10-30
  ([14](14-edge-function-security-audit.md)); the live-call half still needs a signed-in identity and a deployed call. There is
  still no `supabase/functions/` directory; export remains a G3-credential task ([13](13-edge-function-source-inventory.md) §7).

## 3. Evidence and return protocol

| Rule | Detail |
| --- | --- |
| One file per query | `docs/stage1/evidence/g1-qN-<YYYYMMDD>.json`, raw JSON as returned, nothing added |
| Sanitize before storing | Remove emails, names, phone numbers, coordinates, tokens, UUIDs of real users (replace with stable hashes) |
| No secrets, ever | No `service_role` key, `anon` key, DB password, access token or pairing token in the repo or in chat |
| No inferred pass | A result that is merely "no error" is not evidence; record the observed status, row count or error code |
| Separate environment label | Every evidence file states which project ref it came from and whether the operation was read-only |
| Advisor findings | Pasted as text with the finding title and description only; the advisory text is not secret, screenshots are optional |

## 4. Gate mapping

| Gate | Unblocked by | Then |
| --- | --- | --- |
| G1 — SQL-level introspection | **Satisfied 2026-10-29** — Q1–Q8, Q3b, Q10 executed read-only, Q9 captured; B3b body read followed 2026-10-30 | Re-graded in [04-rls-matrix.md](04-rls-matrix.md) §0a; advisor warning F4 awaits an owner decision |
| G5 — Negative and isolation tests | G1/B3b, plus test identities | T-01, T-02, T-18 (read-only), then T-03…T-07 if identities allow |
| G6 — Environments | Owner decides on a `dev` project | T-08 … T-17 become runnable; until then they stay blocked |
| G3 — Baseline migration | G1, plus G6/Docker for the restore proof | Freeze the schema and this test set as code, so later policy edits are reviewable |

SQL access is no longer the constraint — gate G1 was answered on 2026-10-29 — so the label on every unrun row reads
`BLOCKED — NOT EXECUTED`: these are behavioural tests that need an identity, a non-production target or a running client,
none of which exists. No row is `PASS` or `FAIL`; T-01, T-02 and T-18 are `PARTIAL` only because catalogue evidence predicts
their outcome.
