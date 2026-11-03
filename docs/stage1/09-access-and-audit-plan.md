# 09 — Access method, SQL audit plan, file map and risk register

Status: **G1 `ANSWERED 2026-10-29`, B3b `ANSWERED 2026-10-30`** — phases A1–A6 were executed read-only as queries Q1–Q10, and B3b read the function/trigger bodies; results are in `docs/stage1/evidence/`. **G2 `BLOCKED — ACCESS OR APPROVAL REQUIRED`**; G3, G5 and G6 are open, G4 awaits confirmation and G7 applies at FCM wiring. This document remains the execution plan and now doubles as the record of what was run.

## 1. Outstanding gates

| Gate | Type | Owner action | Blocks | Depends on |
| --- | --- | --- | --- | --- |
| **G1** | Access | ~~Provide an authorised read path to the Postgres catalog (§2)~~ | **Answered 2026-10-29** by Q1–Q10 in the dashboard SQL Editor; unblocks RLS verification, grants, advisor detail and baseline capture | — |
| **G2** | Decision | Choose the Firebase project; the Android `applicationId` is **VERIFIED** as `com.haven.familysafety` ([checklist](../../firebase/SETUP-CHECKLIST.md) §0a) | FCM configuration, integration verification | — |
| **G3** | Approval | Approve baseline migration capture after G1 findings are reviewed | Version-controlled schema history | G1 |
| **G4** | Decision | Confirm "keep every table API-disabled" (recommended: yes) | None if unchanged; would gate any exposure | — |
| **G5** | Approval | Approve running negative/isolation tests, and where (prod vs new dev project) | Cross-family isolation evidence | G1, and G6 if a non-prod target is required |
| **G6** | Decision | Create dev/staging or accept prod-only, documented | Safe environment for mutating tests | — |
| **G7** | Decision | Confirm secret placement (Edge Function secrets only) | Nothing now; applies at FCM wiring time | G2 |

G1 and B3b are answered. G2, G3, G5 and G6 remain open, and they block different things: **G2** blocks any push-delivery work, **G3** blocks freezing the schema as code, **G5 + G6** block every negative and isolation test. None of them blocks further read-only catalogue work. G3–G7 are decisions about work that comes after the audit.

## 2. Safest way to get read-only SQL catalog access (G1)

Ranked from least to most credential exposure.

### Option C — owner-run queries in the dashboard SQL Editor (safest; recommended)

No credential is created, exported or stored anywhere. You paste the queries from [08-test-matrix.md](08-test-matrix.md) §0 into the SQL Editor and paste the JSON results back. Procedure, order and save format: [10-owner-runbook.md](10-owner-runbook.md).

To make it provably read-only, run them as a single read-only transaction:

```sql
begin transaction read only;
-- paste one query from 08-test-matrix.md §0 here
commit;
```

A read-only transaction makes an accidental write fail with `cannot execute ... in a read-only transaction`, even if a statement were mistyped. Run one query per transaction so a failure does not discard the others.

Cost: ten paste-and-return SQL round trips plus one manual advisor capture, and repeat work later for the baseline.

### Option A — scoped Supabase access token (best repeatability)

1. Dashboard → Account → Access Tokens → generate a token, label it `stage1-audit`, set the shortest available expiry.
2. In **your own** terminal only: `export SUPABASE_ACCESS_TOKEN=sbp_...` (never in this repo, never in chat, never in a file).
3. `supabase link --project-ref hhqgreaoqulmfwfwarhc`, then `supabase migration list`, `supabase functions download`.
4. When the audit is done: revoke the token in the dashboard and `unset SUPABASE_ACCESS_TOKEN`.

A PAT is a Management-API credential: it links the CLI, lists migrations and downloads function source, and it can administer the project depending on scope. It does **not** by itself enable `supabase db dump` — that needs a database connection, which the CLI obtains from the DB password (option B). So option A unblocks the SQL-side audit only indirectly, through whatever queries the Management API runs; the catalog evidence still comes from §0 pasted into the SQL Editor as in option C.

### Option B — database password (least preferred)

Project Settings → Database → reset the password. This **breaks existing direct connections** (the UI warns about this) and creates a long-lived credential. Use only if A is unavailable, and rotate again afterwards.

### What I will not do

Read cookies, localStorage, session tokens or the dashboard's in-memory access token; drive the session API with credentials lifted from the browser; or add a read-only Postgres role (which would itself be a write). I also did not use the Firebase CLI account that is already authenticated, because it belongs to a different Google identity than this project.

## 3. Read-only SQL audit plan

Every step below produces a file under `docs/stage1/evidence/`. All queries are `SELECT`-only; none create, alter or drop anything.

| Phase | Scope | Queries | Output as filed 2026-10-29 |
| --- | --- | --- | --- |
| A1 | RLS ground truth | Q1 (pg_class flags per table) | [g1-q1](evidence/g1-q1-20261029.json) |
| A2 | Policies and helper functions | Q2 (pg_policies with `qual`/`with_check`), Q7 (public functions incl. `prosecdef`, `proconfig`/`search_path`) | [g1-q2](evidence/g1-q2-20261029.json), [g1-q7](evidence/g1-q7-20261029.json) — §0a of [04-rls-matrix.md](04-rls-matrix.md) is the narrative form |
| A3 | Structure | Q3 triggers on `public`, **Q3b** triggers on `auth.users`, Q4 indexes, Q5 constraints/FKs, Q8 columns | [g1-q3](evidence/g1-q3-20261029.json), [g1-q3b](evidence/g1-q3b-20261029.json), [g1-q4](evidence/g1-q4-20261029.json), [g1-q5](evidence/g1-q5-20261029.json), [g1-q8](evidence/g1-q8-20261029.json) |
| A4 | Privileges | Q6 grants, column grants, default privileges, role membership, plus **Q10** — `has_function_privilege` for `anon`/`authenticated`/`service_role` on all 14 definer functions | [g1-q6](evidence/g1-q6-20261029.json), [g1-q10](evidence/g1-q10-20261029.json) — the decisive pair for the RPC-exposure question |
| A5 | Linter | The Security Advisor findings, matched to catalog facts | [g1-q9](evidence/g1-q9-20261029.json) — UI shows 1 warning + 4 suggestions; `run-lints` returns 5 rules / 33 rows, 2 WARN |
| A6 | Reconciliation | Diff A1–A5 against 01/03/04; every divergence recorded, not silently corrected | [00-status-register.md](00-status-register.md), [04-rls-matrix.md](04-rls-matrix.md) §3 outcome, [CHANGELOG.md](CHANGELOG.md) |
| B3b | Bodies and `private` schema | Function and trigger bodies, `private` inventory, ACLs, `search_path`, Data API exposure (read-only) | [g1-b3b](evidence/g1-b3b-20261029.json) — filed 2026-10-30 |

### The four questions the audit had to answer before any DDL is proposed

1. **Are the functions in `public` executable by `anon` / `authenticated`?** The Data API is globally enabled, so a function with `EXECUTE` granted is reachable at `/rest/v1/rpc/<name>` when `public` is an exposed schema and the caller holds `USAGE` — Q10 reports both as `schema_usage`. `anon_exec = true` on any app-owned function is a security finding to report and investigate immediately; severity is confirmed after the body is read. For the five functions that take no actor id — a `device_id` is the only input — `auth_exec = true` is also a finding. Extension-owned functions are recorded separately. Any change here is proposed, not applied.
2. **Do the family-scoping predicates actually scope by family?** Policy names say `select_family` / `parent_or_child`; only `qual` proves it. `qual` is legitimately NULL on INSERT policies.
3. **Does `profiles_before_update` block `role` self-escalation, and does a trigger on `auth.users` create profiles with a safe role?** Q3/Q3b identify the trigger and its function; the redacted body (Q7) and the `role` column default (Q8) show how the role is set. Neither trigger's existence is assumed.
4. **Do the definer functions set a safe `search_path`?** `proconfig` answers this for function-level settings; a body-level `set_config('search_path', …)` is visible only in the redacted body and must be checked there.

If question 1 or 3 comes back unfavourable, that is a **High/Critical** finding and Stage 1 cannot be marked PASS regardless of everything else.

**Answers, 2026-10-29.** 1 — **closed**: `anon_exec` and `auth_exec` are false on all 14 app-owned functions and every
`proacl` is `postgres=X,service_role=X`, so no client has a route to `/rest/v1/rpc/*` even though both roles hold `USAGE`
on `public` ([g1-q10](evidence/g1-q10-20261029.json)). 2 — **yes**: all 15 SELECT predicates scope by family membership,
device ownership or session participation; 14 delegate to a `private` helper ([g1-q2](evidence/g1-q2-20261029.json)).
3 — **escalation blocked**: `profiles.role` is not in the column UPDATE grant, and exactly one `auth.users` trigger exists
(`private.handle_new_user`, definer, pinned `search_path`, body read 2026-10-30: inserts `role = 'unset'`). 4 — **yes**: 13 of 14 `public` functions pin
`public, private, pg_temp`; `request_remote_session` pins `public, pg_temp` and omits `private` (F5). The `private`
implementations were outside Q7's scope; all 24 were inventoried and their bodies read on 2026-10-30. 23 of 24 pin all
three schemas; only `remote_session_transition_guard` omits `private` (F8). The helpers anchor on `auth.uid()`; the
actor-taking RPCs trust their arguments (F7).

## 4. Files that will be updated

| File | Change | When |
| --- | --- | --- |
| [01-baseline-inventory.md](01-baseline-inventory.md) | Second-pass section: functions, triggers, settings, storage, APK package | **done now** |
| [03-data-model.md](03-data-model.md) | "Verified against captured columns" update; gap list narrowed | **done now** |
| [04-rls-matrix.md](04-rls-matrix.md) | Trigger evidence for `profiles.role`; RPC-exposure risk added | **done now** |
| [05-change-plan.md](05-change-plan.md) | Gate table aligned with this document | **done now** |
| `evidence/schema-columns.md`, `evidence/functions-and-triggers.md` | New evidence records | **done now** |
| `evidence/g1-b3b-20261029.json` | B3b bodies and `private` inventory | **filed 2026-10-30** |
| [11-remediation-proposals.md](11-remediation-proposals.md) | F1–F8 remediation proposals | **produced 2026-10-30** |
| [12-g3-baseline-plan.md](12-g3-baseline-plan.md) | G3 capture and verification plan | **produced 2026-10-30** |
| `00-status-register.md` | PASS/FAIL/BLOCKED/NOT TESTED register | **done now** |
| [08-test-matrix.md](08-test-matrix.md) | Q1/Q6/Q7 cast corrections, new Q3b (`auth.users` triggers), new Q10, Q2 re-specified per command, execution wrapper | **done now** |
| [10-owner-runbook.md](10-owner-runbook.md) | Owner procedure, save/sanitise protocol, G2 package verification | **new now** |
| `evidence/g1-q*-20261029.json` (+ run manifest) | Audit output | **done 2026-10-29** |
| [08-test-matrix.md](08-test-matrix.md) | §0 executed; read-only rows re-graded `PARTIAL`, the rest stay `BLOCKED` | **done 2026-10-29** for §0; G5 for live tests |
| `supabase/migrations/<ts>_baseline.sql` | Baseline dump (schema only), claimed as applied via `migration repair` | after G3 |
| `firebase/SETUP-CHECKLIST.md` | Tick-off record + project id / app id once G2 is decided | after G2 |
| `docs/stage1/reports/stage1-final.md` | Phase F report | **produced 2026-10-30** |
| `README.md`, `docs/stage1/README.md` | Status only | each milestone |

Precise rule, because a dump necessarily contains `CREATE TABLE` statements for objects that already exist:

- The baseline file **describes** the live schema; executing it would be a duplicate-object error at best. It is committed as a record and marked applied with `migration repair` — never run.
- Forbidden against this project in Stage 1: `supabase db push`, `supabase migration up`, `supabase db reset` (any variant), `db reset --linked`, and any DDL typed into the SQL Editor (`CREATE`, `ALTER`, `DROP`, `GRANT`, `CREATE OR REPLACE`).
- The only permitted writes are the metadata row written by `migration repair`, and only after G3 approval.
- Success criterion after G3: `supabase db diff` returns empty. An empty diff is the proof that the file matches reality; a non-empty diff means the dump is wrong and must be regenerated, not pushed.
- A `public` + `private` schema dump does not include the `auth.users` trigger that creates `profiles`; that object is documented separately in [12-g3-baseline-plan.md](12-g3-baseline-plan.md) §4a and must be captured as an explicit note, not silently omitted.

## 5. Risk register and recovery

| # | Risk | Sev | Mitigation | Recovery if it happens |
| --- | --- | --- | --- | --- |
| R1 | Read-only transaction still leaves a lock or long-running query on a live DB | Low | Each query is a catalog read; run one at a time; `statement_timeout = '15s'` at session start | Cancel the query in the dashboard; no state change to undo |
| R2 | A pasted query is edited and becomes a write | Medium | `begin transaction read only` wrap; review before running; queries kept in version control | Transaction aborts automatically; nothing committed |
| R3 | Access token leaks (shell history, screen share, repo) | High | Env var only; short expiry; no `echo`; revoke immediately after audit | Revoke in dashboard → all management access dies; check project audit/activity |
| R4 | Baseline migration is accidentally applied as DDL over live objects | High | Dump-only file; `migration repair --status applied` (mark, never execute); `db diff` must be empty afterwards | Do **not** push. Delete the version row, restore file, re-dump. Existing objects untouched because nothing ran |
| R5 | Test writes (negative tests) hit production data | High | Mutating tests deferred to a dev project (G6); read-only checks first; no test touches existing rows | Point-in-time restore is **not** evidenced on Free plan — this is why mutating tests are not run on prod |
| R6 | Firebase app registered with a guessed package name | Medium | Package is **VERIFIED** as `com.haven.familysafety` from the release APKs (2026-10-30); registration still needs the owner's project decision (G2) | Delete the wrong app in Firebase; no data loss (no FCM tokens issued yet) |
| R7 | FCM service-account JSON lands in the repo | High | `.gitignore` blocks `service-account*.json`, `*-firebase-adminsdk-*.json` and `google-services.json`; secrets only via `supabase secrets set` | Rotate the key in Google Cloud, purge history, force-rotate tokens |
| R8 | Out-of-order or duplicated work between the docs and the live schema | Medium | Single source of truth = catalog; docs regenerated from A1–A5 | Re-run A1–A5 and diff |
| R9 | 7 of 9 Edge Functions are minified, so source reading is identifier-level rather than line-level | Medium | Read in Phase E (2026-10-30) with per-artifact SHA-256 ([capture](evidence/edge-functions/capture-20261030.json)); export via `supabase functions download` remains the way to get reviewable diffs | Review outcome unchanged by export; export needs the G3 project credential |
| R10 | Free-plan quotas (log ingestion 0.17/1 GB, DB 32/500 MB) exhausted during testing | Low | No load tests in Stage 1; audit queries are catalog-only | Trim log drain, wait for cycle reset |
| R11 | **Realtime predicates are live today**: 4 tables stream `postgres_changes` and authorise subscribers through their SELECT policies. A wrong predicate is exploitable now, not only after a future exposure change | High | Q2 captured all four predicates; each scopes by family or session participant. Delivery remains untested (N4) | Disable Realtime on the affected table (a config change, requires approval) if a predicate is later found defective |
| R12 | **RPC surface via `SECURITY DEFINER`**: 5 of the 14 functions take no actor argument at all, so a stray `EXECUTE` grant is a cross-family primitive keyed on `device_id` | **Closed 2026-10-29 — not present** | Q10: `anon_exec` and `auth_exec` false on all 14; `proacl` stripped of `PUBLIC` at creation | Would have been `REVOKE EXECUTE FROM anon, authenticated` — now unnecessary |
| R13 | Database reachable from all IP addresses; SSL-enforcement state not captured | Medium | Confirm the SSL toggle before any direct connection is used; prefer the pooler with SSL required | Enforce SSL (single toggle); add network restrictions only after confirming no server depends on open access |
| R14 | `pg_proc.prosrc` (function bodies) may contain literals that look like secrets, and Q7 asks for bodies | Medium | Q7 excluded `prosrc`; B3b read bodies and returned them to a local file, and the evidence was scanned for literals before sharing | If a secret appears in output: rotate it, then continue |
| R15 | The APK-derived `applicationId` is treated as confirmed by mistake | Medium | Package **VERIFIED** from `Haven-1.1-release.apk` and `Haven-1.2-release.apk` (2026-10-30); `Haven-1.0.apk` uses a different signing key, so the package is verified but the signing identity is not final | Delete the wrong Firebase app; no tokens exist yet |

## 6. Execution order (G1 done; G2 outstanding)

1. ~~A1–A5 queries, results filed under `evidence/` (no interpretation yet).~~ **Done 2026-10-29.**
2. ~~Independent review of the raw results before any verdict (role 14).~~ **Done** — three read-only reviewers; their
   corrections are listed in [CHANGELOG.md](CHANGELOG.md).
3. ~~Reconcile docs; update the status register; escalate Critical/High items.~~ **Done.**
4. **Stop and report.** Implementation proposals only after that report is reviewed.

G3 (baseline), G5 (tests) and G7 (FCM secrets) follow in that order, each behind its own approval.
