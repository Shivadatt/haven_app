# 12 — G3 baseline capture plan

**Status: `READY — NOT EXECUTED`.** No command in this document has been run. No `db push`, `db pull`, `migration up`,
`db reset` or `migration repair` was issued, and the project's migration history table has not been touched.

G3 is the gate that turns the live schema into reviewable code. Today the database is the only copy of itself: there is
no `supabase/migrations/` directory, and the remote `supabase_migrations.schema_migrations` history is empty. This plan
captures it **read-only**, verifies the capture against the live catalogue, and stops before anything is written back.

---

## 1. What "baseline" means here

A baseline is one SQL file that recreates the schema from nothing: schemas, types, tables, constraints, indexes,
functions, triggers, policies, grants and default privileges, plus a separate file for the one cross-schema trigger
(§4a). It contains **no rows** and **no roles' passwords**.

It does **not** contain:

| Excluded | Why | Where it is recorded instead |
| --- | --- | --- |
| Table data of any kind | The rule for this gate is schema only; several tables hold child location and contact data | Nothing captures it; backup is N1 |
| `auth`, `storage`, `realtime`, `extensions`, `graphql_public` schemas | Platform-managed; recreating them by hand breaks a Supabase project | Supabase project creation |
| The `auth.users` **trigger** — the object lives on a platform table | A `--schema public,private` dump structurally cannot include it | §4, created separately and explicitly |
| Supabase-managed roles (`anon`, `authenticated`, `service_role`, `supabase_admin`, …) | Created by the platform | Present in every project by default |
| Migration history rows | Writing them is a remote metadata write (G3 approval below) | §6 |

## 2. Preconditions

- [ ] Supabase CLI installed and logged in. Check `supabase --version`; the bundled `pg_dump` must be **17.x** to match
      the server (`PostgreSQL 17.11`). A 16.x client refuses or silently omits 17-only syntax.
- [ ] **Docker running — hard precondition for a G3 pass, not for the capture.** The no-diff proof in §5 requires a local
      Supabase stack, and that stack runs in Docker. This machine has no Docker ([01](01-baseline-inventory.md) §8), so
      the capture (steps 1–2) can be prepared but **G3 cannot be closed here**; the verification half is blocked until
      Docker is available. Do not record a baseline as verified on the strength of a file that was never restored.
- [ ] The owner supplies the **database password** interactively at `supabase link`. Nobody needs to paste it into a
      chat, a file or this document; if a tool asks for it in plain text, stop.
- [ ] A scratch space outside the repository for the raw dumps (they contain the schema, not data, but they are large
      and should not land in git by accident).
- [ ] Confirm the working tree is clean before adding files, so the baseline commit is reviewable on its own.

## 3. Capture procedure — read-only

Run from the repository root, with `supabase/` present. **Not executed.**

```bash
# 1. Link (local metadata only; prompts for the DB password interactively)
supabase link --project-ref hhqgreaoqulmfwfwarhc

# 2. Dump the two schemas Haven owns. Schema only: --data-only is NOT used.
#    Output goes to scratch first; it is reviewed before anything is committed.
supabase db dump --schema public --schema private --keep-comments \
  -f /tmp/haven-baseline-$(date +%Y%m%d).sql
```

**Do not use `--role-only` here.** In the Supabase CLI that flag maps to `pg_dumpall --roles-only`: it emits `CREATE
ROLE` statements, not privileges, it carries password verifiers, and it needs privileges the project's `postgres` role
may not hold. Roles are platform-managed and excluded by §1 anyway.

Object grants and default privileges are already part of a schema dump. Verify, do not assume:

```bash
grep -c '^GRANT ' /tmp/haven-baseline-*.sql                 # expect > 0
grep -c '^ALTER DEFAULT PRIVILEGES' /tmp/haven-baseline-*.sql  # expect 24-ish; compare to g1-q6
```

If either count is zero, the dump is missing the privilege layer and is not a baseline — stop and report it. The
authoritative comparison is the `g1-q6` JSON, not the expected number in this document.

Notes that decide whether the output is usable:

- `supabase db dump` without `--data-only` emits **schema only**. Verify, do not assume: the file must contain no
  `COPY ` block and no `INSERT INTO`. Both are greppable and cheap to check (§5).
- `--keep-comments` matters here: the table comments carry the design intent that [04-rls-matrix.md](04-rls-matrix.md)
  repeatedly says the schema *states* but cannot enforce.
- The dump is ordered by the CLI. Do not reorder it by hand — the ordering is what makes restore work (§4).
- Take the dump **twice**, a few minutes apart, and diff them. A non-empty diff means something is changing under you
  (an Edge Function applying DDL, a scheduled job); stop until it is explained.
- The reviewed file is not placed in `supabase/migrations/` until the decision in §6 is recorded. Until then it is a
  reference artefact, not a migration; putting it in that directory is what makes `db push` want to apply it.

## 4. What the dump will be missing — handle separately

### 4a. The `auth.users` trigger

[g1-q3b](evidence/g1-q3b-20261029.json) captured exactly one user-defined trigger on `auth.users`:
`on_auth_user_created` → `private.handle_new_user()`, `SECURITY DEFINER`, `search_path = public, private, pg_temp`,
enabled. The **function** is in `private` and will be in the dump. The **trigger**, which lives on a platform table, will
not be.

The baseline therefore needs a separate, clearly-labelled section — not silently appended to the generated file:

```sql
-- Cross-schema: attaches to a platform-owned table. Recreate AFTER auth schema exists.
-- CREATE OR REPLACE avoids a window in which signup creates no profile.
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();
```

`create or replace trigger` needs PostgreSQL 14 or later; the server is 17.11, and the local stack must match. The
captured `pg_get_triggerdef` text is already available verbatim in [g1-q3b](evidence/g1-q3b-20261029.json):
`CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.handle_new_user()`.
Use that text as the source of truth; the block above is its re-application form.

Keep it in its own file (e.g. `supabase/migrations/<ts>_baseline_auth_trigger.sql`) so the environment-specific part is
obvious and can be skipped on a database that is not Supabase.

Consequence if it is forgotten: signup succeeds and **no `profiles` row is created**. The failure is silent — nothing
raises — and the app breaks on first read of a profile.

### 4b. Cross-schema dependency: `profiles.id`

[g1-q5](evidence/g1-q5-20261029.json) records
`profiles.id → auth.users(id) ON DELETE CASCADE`. A restore into a database without `auth.users` fails on this foreign
key. Two consequences:

1. The baseline cannot be applied to a plain PostgreSQL instance; it is a Supabase baseline by construction.
2. Restore order is not arbitrary: `auth` schema → `public`/`private` schemas → tables (FK resolves against
   `auth.users`) → functions → triggers (including 4a) → policies → grants → default privileges.

### 4c. Functions that call `auth.uid()`

The four policy helpers and the actor-taking RPCs call `auth.uid()`. They compile against `auth` but only *execute*
correctly when the Supabase auth service sets the JWT claim. A baseline restored without the auth extension will accept
`create function` and then return null/raise at runtime. This is another reason the baseline is Supabase-only, and a
reason the verification step (§5) must run on a Supabase stack, not a bare Postgres.

## 5. Verification — the no-diff proof

A dump that runs is not a dump that matches. The gate is only satisfied when a restore **reproduces the live schema
exactly**. Do this in a scratch project or local stack (G6), never against production.

1. **Content sanity on the file** (no database needed):
   ```bash
   grep -c '^COPY ' /tmp/haven-baseline-*.sql     # must be 0
   grep -c '^INSERT INTO' /tmp/haven-baseline-*.sql  # must be 0
   grep -c 'CREATE POLICY' /tmp/haven-baseline-*.sql # expect 21
   grep -c 'CREATE OR REPLACE FUNCTION\|CREATE FUNCTION' /tmp/haven-baseline-*.sql # expect 38
   ```
   The expected counts come from [g1-q2](evidence/g1-q2-20261029.json) (21 policies) and
   [g1-b3b](evidence/g1-b3b-20261029.json) (38 functions). A mismatch is a finding about the dump, not about the schema.

2. **Restore into a scratch stack — NOT AUTHORISED BY THIS PLAN.** The mechanism is `supabase start` followed by
   applying the baseline through the normal migration path, which for a local stack means `supabase db reset`. That
   command is destructive to the local database and is named as forbidden by the Stage 1 instructions; it is listed
   here to describe the proof, not to authorise it. It may be run only after G6 supplies a scratch environment and the
   owner approves it explicitly. §6 records the same boundary.

3. **Structural diff**: dump the restored database with the same flags and diff against the production dump, ignoring
   the expected environment-specific lines (comments mentioning roles, `OWNER TO` if the scratch owner differs,
   `SET` statements). A non-empty diff must be explained line by line. **Empty after normalisation = G3 pass.**

4. **Catalogue spot-checks** on the restored database — the same queries the G1 run used, expecting the same answers:
   `g1-q1` (19 tables, RLS on, none forced), `g1-q2` (21 policies), `g1-q6` (grants + default ACLs), `g1-q7`/`g1-b3b`
   (38 functions with the same ACLs), `g1-q5` (137 constraints).

5. **Negative control**: confirm the restored database *without* the 4a trigger creates a user and **does not** create a
   profile — that proves the trigger file is actually load-bearing, rather than assumed.

## 6. The write steps that are NOT authorised

Nothing below may be run as part of this plan. Each is listed so the boundary is explicit.

| Operation | What it writes | Why it needs approval |
| --- | --- | --- |
| `supabase db push` | Executes the baseline against production | Applying a generated baseline to a database that already has the schema is destructive-by-omission; there is no dry run that proves it safe |
| `supabase migration up` | Same, for a specific version | Same |
| `supabase db reset` | Drops and recreates the **local** database and runs `seed.sql` | Local only, but it destroys the local database and currently fails at the seed step (§7 G3-a). It is not authorised here; the verification in §5 needs G6 plus an explicit owner approval |
| `supabase migration repair --status applied <version>` | Writes a row into `supabase_migrations.schema_migrations` **in production** | This is remote metadata, not SQL. It makes future `db push` believe a migration already ran. Silent, hard to audit afterwards, and the exact reason the master prompt names it explicitly |
| `supabase link` | Local config only | Safe, but it stores a project ref and asks for the DB password |

When the owner does decide to establish history, the normal sequence is: baseline file → `migration repair --status
applied <baseline-version>` **only if** production is already at that schema → then future migrations are additive. The
repair is the one step that must be a deliberate, recorded decision with the version id written down before and after.

## 7. Repository state found while preparing this plan

Discrepancies in `supabase/config.toml`. One blocks any local verification; the others are risks to record, not bars to
capture.

| # | Observation | Consequence |
| --- | --- | --- |
| G3-a | `[db.seed] enabled = true`, `sql_paths = ["./seed.sql"]`, but `supabase/seed.sql` **does not exist** | **Blocks `supabase db reset`**: it fails at the seed step, so the §5 restore proof cannot run until this is fixed (create an empty `seed.sql` with a comment explaining it is intentionally empty, or set `enabled = false`). This is a blocker for G3 closure, not a cosmetic issue |
| G3-b | `[api] schemas = ["public", "graphql_public"]`, while the dashboard reports the exposed schemas as **`public` + `extensions`** | Local config and remote settings disagree. The remote value is authoritative for production; the config file describes the local stack. Reconcile before anyone trusts a local run as a production predictor |
| G3-c | `project_id = "control"` (local stack name) vs the remote project `parent-control-prod` | Expected — `project_id` names the local Docker stack, not the remote project — but it is a common source of "linked to the wrong project" confusion. `supabase status` should be read before any write step |

## 8. Rollback

Steps 1–5 are read-only against production. There is nothing to roll back until §6 is attempted. If a scratch stack is
created, `supabase stop --no-backup` removes it. If a baseline commit is wrong, it is a file: revert the commit.

## 9. Owner checklist

- [ ] CLI ≥ the version that bundles `pg_dump` 17; verified with `supabase --version`
- [ ] Docker available for the restore proof — without it G3 stays `READY`, not `PASS`
- [ ] Two consecutive dumps, diffed, identical
- [ ] No `COPY`/`INSERT` in either file
- [ ] `GRANT` and `ALTER DEFAULT PRIVILEGES` statements present and compared to `g1-q6`
- [ ] 21 `CREATE POLICY` and 38 `CREATE FUNCTION` lines present
- [ ] `auth.users` trigger stored as its own file, using the `g1-q3b` definition and `CREATE OR REPLACE TRIGGER`
- [ ] `profiles.id → auth.users(id)` acknowledged in the restore order
- [ ] `seed.sql` fixed or disabled (G3-a) before any local restore
- [ ] Restore into a scratch stack reproduces the production catalogue (queries q1/q2/q5/q6/q7/b3b) — only after G6 and explicit approval
- [ ] Normalised diff empty
- [ ] Decision recorded: does the baseline become migration `0001` via `migration repair`, or stay a reference dump?
- [ ] No `push`, no `reset`, no `repair` run before that decision is written down
