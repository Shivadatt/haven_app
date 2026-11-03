# B — G3 schema baseline under a dashboard-only constraint

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

**Status: planning only. Nothing in this document has been executed. G3 remains `BLOCKED — APPROVAL REQUIRED`.**
Stage 2 states: **Supabase Web Dashboard only; no Supabase CLI; no terminal-based migrations; no direct production
API calls.** Stage 1's G3 plan [12-g3-baseline-plan.md](../../stage1/12-g3-baseline-plan.md) assumes the first three are
available. This part resolves that conflict without pretending the two positions are compatible.

Labels: **VERIFIED** (Stage 1 evidence), **INFERRED** (derived, not observed), **PROPOSED — NOT APPLIED**.

## 1. The conflict, precisely

Stage 1 closes G3 only when a **schema dump** is restored into a **Supabase stack** and a **normalised `pg_dump` diff**
is empty ([12](../../stage1/12-g3-baseline-plan.md) §3–§5). Every mechanism in that path is now prohibited:

| G3 step | Stage 1 mechanism | Stage 2 rule broken |
| --- | --- | --- |
| Capture | `supabase link` + `supabase db dump` (12 §3) | No CLI; direct production connection |
| Restore proof | `supabase start` / `db reset` / `supabase db diff` (12 §5) | No CLI; no terminal migrations; Docker |
| Establish history | `migration repair` / `db push` (12 §6) | No terminal-based migrations |

**Why this blocks closure as written.** G3's acceptance test is not "a schema file exists"; it is "a restored copy
reproduces the live catalogue, proven by an empty normalised diff" ([12](../../stage1/12-g3-baseline-plan.md) §5,
[07](../../stage1/07-ops-and-observability.md) §3). A dashboard reconstruction is a different artefact and a different
proof. Recording it as G3 `PASS` without an owner decision to amend the gate would be a false claim. The conflict is
therefore a **gate-definition conflict**, not a tooling preference.

Two independent blockers already existed: this machine has **no Docker, no `psql`, no database password and no access token** ([01](../../stage1/01-baseline-inventory.md) §8), so Stage 1 could not close G3 here either. Stage 2 removes the workaround, not the blockers.

**Interpretation that must be settled first.** "No direct production API calls" plausibly bans PostgREST, RPC, Auth
Admin and Edge Function requests, while the dashboard SQL Editor remains the sanctioned read surface used for G1 and B3b
([10](../../stage1/10-owner-runbook.md) §2). If it instead bans **all** production contact, neither option below works and
G3 needs an owner-supplied dump or a platform backup restored to staging. This is Open Question 1.

## 2. Option 1 — one-time read-only CLI dump (not recommended)

```bash
supabase db dump --db-url "$HAVEN_PROD_DB_URL" \
  --schema public --schema private --keep-comments \
  -f "$SCRATCH/haven-baseline-<date>.sql"
```

Using `--db-url` avoids `supabase link` and its local metadata write. No `push`, `pull`, `reset`, `migration up` or
`repair` is issued.

| It touches | It does not touch |
| --- | --- |
| One outbound TLS connection to production Postgres as `postgres`; catalogue reads; a local scratch file | Any table row, DDL, DML, policy, function, trigger, grant or setting |
| The database password, supplied by the owner in an environment variable | `supabase_migrations.schema_migrations`, project config, Edge Functions, secrets |
| Local shell history if the command is pasted carelessly | Roles or passwords (`--role-only` is explicitly forbidden, 12 §3) |

**Docker for capture alone.** Stage 1 asserts Docker is needed only for the restore proof, not the capture
([12](../../stage1/12-g3-baseline-plan.md) §2). That assertion is **INFERRED and doubtful**: Supabase CLI 2.109.0 commonly
runs `pg_dump` inside the `supabase/pg-dump` container, so Docker is likely required for `db dump` itself. The phrase
"bundled `pg_dump`" in 12 §2 is not supported by the CLI architecture. This must be verified before any approval; if
the CLI does use a container, Option 1 cannot run on this machine ([01](../../stage1/01-baseline-inventory.md) §8).

**Assessment: not recommended.** It produces the strongest artefact — true dependency ordering, comments and exact ACL
text — but violates three Stage 2 rules, requires a direct production credential, and still needs a staging apply and
comparison. It is a valid **owner-granted exception**, not the baseline path. If granted: take two dumps ten minutes
apart, hash both, reject any `COPY`/`INSERT`, reconcile counts, keep the file outside the repo, and delete it after
review.

## 3. Option 2 — dashboard catalogue capture plus offline reconstruction (recommended)

**Method.** Freeze one query set; run each query in the SQL Editor inside
`begin transaction read only; set local statement_timeout = '20s'; show transaction_read_only; … commit;` and confirm
`on` before the catalogue statement, exactly as G1/B3b did ([10](../../stage1/10-owner-runbook.md) §2). Export each
result grid as JSON (`json_agg`) or CSV via the editor's download control; the grid renders to canvas, so text scraping
is not evidence ([README](../../stage1/README.md)). Store under `docs/stage2/evidence/`.

| Query source | Captures |
| --- | --- |
| `pg_class`, `pg_namespace`, `pg_attribute`, `pg_attrdef`, `pg_get_expr` | Tables, columns, defaults, nullability, owners, RLS flags, reloptions, schema list |
| `pg_get_constraintdef`, `pg_get_indexdef` | 137 constraints and 62 indexes, including partial predicates |
| `pg_proc`, `pg_get_functiondef`, `proacl`, `proconfig` | All 38 bodies, signatures, `SECURITY DEFINER`, volatility, pinned `search_path` |
| `pg_trigger`, `pg_get_triggerdef` (including `auth.users`) | 7 public triggers plus `on_auth_user_created` |
| `pg_policy`, `pg_policies`, `pg_get_expr(polqual/polwithcheck)` | 21 policies with exact expressions, roles and permissive mode |
| `pg_class.relacl`, `pg_attribute.attacl`, `aclexplode` | 149 table grants and 191 column-level grants |
| `pg_default_acl` | 24 default-ACL rows (6 app-relevant, 18 platform) |
| `pg_namespace.nspacl`, `has_schema_privilege` | Schema USAGE, especially `private` |
| `pg_description`, `col_description`, `shobj_description` | Object and column comments |
| `pg_extension`, `pg_type`, `pg_class.relkind`, `pg_publication_tables` | Extensions/versions, custom types, sequences/views, realtime membership |

**Honesty about the artefact.** This is **reconstruction, not a dump**. It is complete only to the extent the query set
is complete; dependency order, ownership statements and implied defaults are authored by hand. It cannot prove
byte-level equality with `pg_dump`. It does, however, capture the 24 function bodies Stage 1 never read (PA3), which is
strictly more source than the documentation currently holds.

**Drift risks.** (1) **Ordering** — functions before triggers, helpers before policies, tables before FKs; `pg_dump`
solves this automatically. (2) **Ownership** — all 19 tables and the 14 public functions are owned by `postgres`
([q1](../../stage1/evidence/g1-q1-20261029.json), [q7](../../stage1/evidence/g1-q7-20261029.json)); `private` function owners
were never recorded, so `proowner` must be captured. (3) **Comments** — Stage 1 recorded only that comments exist on
`families`, `profiles` and `child_contact_ids` ([01](../../stage1/01-baseline-inventory.md) §2), not their text. (4) **ACL
`NULL` versus explicit** — `NULL` on a function means the default `PUBLIC EXECUTE`; the two functions in that state
must stay `NULL` ([q7](../../stage1/evidence/g1-q7-20261029.json), F8). Writing `REVOKE ALL … FROM PUBLIC` changes
behaviour and breaks parity. (5) **Column grants** — `profiles.display_name` is the only client UPDATE column (P17, F3);
a table-level grant would reopen `role`. (6) **Default privileges** — they apply at object creation, not retroactively,
and the `supabase_admin` half cannot be set by `postgres` (F1). (7) **RLS flags** — 19/19 enabled, none forced; omitting
`ENABLE ROW LEVEL SECURITY` leaves every policy inert. (8) **Schema USAGE** — `private` is `authenticated=true`,
`anon=false` ([g1-b3b](../../stage1/evidence/g1-b3b-20261029.json)); this is half of the F8 barrier. (9) **Extensions** —
versions and schemas are platform-managed; enable via Dashboard, never guess `CREATE EXTENSION`. (10) **`auth.users`
privileges** — creating the FK and trigger requires `REFERENCES`/`TRIGGER` on a platform table.

**Staging apply.** Build numbered DDL sections offline, review them, then apply in order through the **staging** SQL
Editor only. No production write, no production API call. A failed section rolls back its transaction; there is no
`db reset`.

## 4. Restore order for staging

0. **Preflight.** Verify the staging project ref is not `hhqgreaoqulmfwfwarhc`; confirm `auth` exists; capture an empty
   staging snapshot; probe `has_table_privilege('auth.users','TRIGGER')` and `…'REFERENCES'`; list installed extensions.
1. **Extensions.** Compare `pg_extension`; enable missing ones through Dashboard → Database → Extensions. `plpgsql` is
   present by default. Do not create extensions by hand unless the Dashboard offers no path.
2. **Schemas.** `public` exists on Supabase; `create schema private`. Apply `nspacl`: `public` USAGE for `anon`,
   `authenticated`, `service_role`; `private` USAGE for `authenticated` and `service_role`, **not** `anon`.
3. **Tables, columns, FKs.** Create all 19 tables with types, defaults and nullability (183 columns,
   [q8](../../stage1/evidence/g1-q8-20261029.json)); `ENABLE ROW LEVEL SECURITY` on each, force none; add comments. Add the
   44 FKs after the tables, then the cross-schema constraint
   `profiles.id → auth.users(id) ON DELETE CASCADE` ([q5](../../stage1/evidence/g1-q5-20261029.json)). `auth.users` already
   exists on Supabase, so no `auth` schema is recreated.
4. **Functions.** Create the 38 functions in dependency order: the four policy helpers
   (`is_family_parent`, `is_family_member`, `shares_active_family`, `realtime_topic_allowed`), `handle_new_user`, the
   trigger functions, `record_audit`, the 13 private implementations, then the 14 public wrappers. Preserve 34
   `SECURITY DEFINER`, volatility, `proconfig` (36 `public, private, pg_temp`; 2 `public, pg_temp`), owner and ACL.
5. **Triggers.** The 7 public triggers after their functions (`audit_logs_append_only`, `devices_set_updated_at`,
   `families_before_update`, `families_set_updated_at`, `profiles_before_update`, `remote_sessions_transition_guard`,
   `safe_zone_states_set_updated_at`). Then the separate platform-table trigger, using the verbatim q3b definition:
   `CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION
   private.handle_new_user()` ([q3b](../../stage1/evidence/g1-q3b-20261029.json)). `CREATE OR REPLACE TRIGGER` needs
   PostgreSQL 14+; the server is 17.11.
6. **Policies.** All 21 after the helpers: 15 SELECT, 3 UPDATE, 2 INSERT, 1 DELETE; all `PERMISSIVE`, all role
   `authenticated` ([q2](../../stage1/evidence/g1-q2-20261029.json)). Reproduce `USING`/`WITH CHECK` text exactly,
   including the two policies that match no grant (F6).
7. **Grants.** 149 table grants, 191 column grants, no table grant to `anon` (P11). Apply column grants individually,
   especially `profiles(display_name)` UPDATE only. Preserve the ACL groups **27** `postgres=X,service_role=X`, **4**
   `postgres=X,authenticated=X`, **5** `postgres=X`, **2** `NULL` ([report](../../stage1/reports/stage1-final.md) §2.1).
8. **Default privileges.** Only the 6 app-relevant rows (`postgres` in `public`; `supabase_admin` in `public`) are in
   scope; the other 18 are platform schemas. They affect future objects only, so applying them after the restore is
   correct for `pg_default_acl` but does not retroactively grant anything. The `supabase_admin` rows may be
   unreproducible by `postgres` (F1); record the difference rather than fabricate it.
9. **Platform configuration.** Realtime membership on the 4 tables (`device_commands`, `remote_sessions`,
   `safety_alerts`, `webrtc_signals`) is a publication setting, not baseline DDL; decide separately whether staging
   needs it. Storage has no buckets (P7). Auth configuration is platform, not schema.

## 5. Verification — count reconciliation and a defined no-diff proof

| Object | Stage 1 | Evidence | Staging target |
| --- | --- | --- | --- |
| Tables / columns | 19 / 183 | [q1](../../stage1/evidence/g1-q1-20261029.json), [q8](../../stage1/evidence/g1-q8-20261029.json) | 19 / 183 |
| RLS | 19 enabled, 0 forced | q1 | 19 / 0 |
| Policies | 21 (15/3/2/1) on 15 tables | [q2](../../stage1/evidence/g1-q2-20261029.json) | 21 |
| Functions | 38 (14 public, 24 private; 34 definer) | [q7](../../stage1/evidence/g1-q7-20261029.json), [b3b](../../stage1/evidence/g1-b3b-20261029.json) | 38 |
| Triggers | 7 public + 1 on `auth.users` = 8 | [q3](../../stage1/evidence/g1-q3-20261029.json), q3b | 8 |
| Constraints | 137 (44 FK, 65 CHECK, 19 PK, 9 UNIQUE) | [q5](../../stage1/evidence/g1-q5-20261029.json) | 137 |
| Indexes | 62 (19 PK-backed, 9 unique-constraint, 34 standalone incl. 3 partial unique) | [q4](../../stage1/evidence/g1-q4-20261029.json) | 62 |
| Table / column grants | 149 / 191 | [q6](../../stage1/evidence/g1-q6-20261029.json) | 149 / 191 |
| Default ACL | 24 rows (6 app, 18 platform) | q6 | 24, or 6 + signed platform diff |
| Function ACL groups | 27 / 4 / 5 / 2 | [report](../../stage1/reports/stage1-final.md) §2.1 | 27 / 4 / 5 / 2 |

**No-diff proof (redefined).** (1) Capture snapshot **P** from production with the frozen query set, read-only.
(2) Apply baseline **B** to empty staging. (3) Capture snapshot **S** from staging with the *same* queries.
(4) Normalise offline: sort by `(schema, name, args)`; resolve OIDs to role/owner names; canonicalise ACLs and keep
`NULL` distinct from empty; collapse whitespace in `pg_get_*def` text; exclude platform schemas and the known
`supabase_admin` default-ACL divergence. (5) Diff **P** vs **S** object by object. **Zero unexplained differences, with
every count in the table above matching, is the G3-D parity pass.** (6) Repeat the apply on a second fresh staging
project to prove determinism, if a destructive second restore is approved. (7) Optional negative control: create one
staging auth user and confirm no `profiles` row without the auth trigger — this needs the staging Auth API and is
**BLOCKED** if "no API calls" is read globally.

**Limitation to state in the gate record:** this proves equivalence over the captured object set; it is not a byte-level
`pg_dump` proof, and any property not queried remains unverified.

## 6. Approval gates and what remains blocked

| Gate | Decision required |
| --- | --- |
| A0 | Owner amends G3's acceptance criteria: dump → reconstruction; `pg_dump` diff → catalogue equivalence on staging |
| A1 | G6 staging project exists, is not production, and is approved as the restore target |
| A2 | Read-only production SQL run approved with a frozen query set and the read-only wrapper |
| A3 | Staging DDL apply approved, including a destructive re-run/cleanup if determinism is tested |
| A4 | `auth.users` privilege probe passes, or a support/owner path for the FK and trigger is agreed |
| A5 | Baseline artefact location and commit approved (schema text, no rows, no secrets) |
| A6 | Option 1 exception, only if chosen: CLI, direct database credential, Docker if required, scratch file handling |
| A7 | Written attestation that no production PostgREST/RPC/Auth/Edge request was made |

**Remains BLOCKED until A0–A5:** G3 `PASS`; true dump fidelity; migration history (`schema_migrations` stays empty
because `repair`/`push` are terminal-only); a Docker local-stack restore; the auth trigger and cross-schema FK if A4
fails; row/data recovery (N1 is unchanged by a schema-only baseline); and any live RLS/API test (G5/G6).

## Open questions

1. Does "no direct production API calls" permit dashboard SQL Editor reads, or does it ban all production contact?
2. Is G3's definition amendable to reconstruction + staging equivalence, or must it remain `pg_dump`-based (and stay blocked)?
3. Does CLI 2.109.0 run `db dump` through Docker here, and is a host-side `pg_dump` 17 available instead?
4. Does the staging `postgres` role hold `TRIGGER` and `REFERENCES` on `auth.users`?
5. Should the baseline freeze F1's leaky default ACL exactly, or exclude/remediate it and accept a documented parity gap?
6. Are object comments to be restored verbatim, and do any contain personal data?
7. Is a second, destructive staging restore authorised to prove determinism?
8. If all production contact is banned, is a Free-plan platform backup restorable to staging, given N1 is unevidenced?

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **G3 is still NOT captured.** No baseline snapshot `P`, no reconstruction `B`, no staging snapshot `S`: the staging shell is **empty** (0 tables, no schema loaded, no `private.s2_environment` sentinel, no secrets, no test principals, no Edge Functions), so §3–§5 remain entirely unexecuted.
- **No schema load is authorised until A3 is signed.** The project creation that did happen is an executed action awaiting retrospective ratification, not a formal A0/A2 approval; [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN` and the replacement package's A2′ covers the sentinel and approved settings only — explicitly not schema load, not secrets, not Firebase app registration.
- **Backup/PITR is unavailable on the Free plan.** Open question 8's assumption that a Free-plan platform backup could be restored to staging is **withdrawn**, as is any part of §5/§6 that leans on a platform backup as the fallback.
- **A4 collision:** the `A4` row in §6 is the historical CLI migration-repair approval only. The plan of record uses **A0–A3 and A5–A13 and has no A4**; read that row as historical and do not cite "A4" as a live gate.
- §5 step 6 (a second fresh staging project to prove determinism) is **impossible**: Free gives 2 active slots, **2 used, 0 remaining**. Any statement about a spare slot is superseded.
- The `parent-control-staging` shell does exist (ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)), so §4's preflight "verify the ref is not production" now has a real second ref to check against.
- Because of Free-plan auto-pause, the read-only capture in §2 and any staging apply need a dated dashboard touch **on or before 2026-11-06** (approximate — no start timestamp was recorded). Screenshots were not captured; the §3 export evidence is `NOT VERIFIED`.
- No operational action taken in this pass — no capture, no SQL, no dashboard or CLI action, nothing signed.
