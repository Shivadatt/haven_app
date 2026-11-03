# I — Stage 2 risk register, rollback design and approval matrix

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

**Status: `PROPOSED — NOT APPLIED`.** Planning only. No SQL, CLI, deploy, secret or browser action was taken, and **no
rollback has been tested**. Everything below is a proposal against the state captured in Stage 1; Stage 1 is authoritative.
Remediation order assumed: G6 staging → G3 baseline → E2/F8 (S2-P01) → E3/F7/E1 (S2-P02) → E4 (S2-P03) → E6/E7 → G5
validation → G2/G7 deferred.

Labels: **VERIFIED** = read in Stage 1 evidence; **INFERRED** = follows from evidence but was not observed;
**PROPOSED — NOT APPLIED** = this document's recommendation. Likelihood/impact values are **INFERRED** judgements, not
measurements. Environment facts: one project only, `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, Free/NANO
(../../stage1/06-secrets-and-environments.md §3; ../../stage1/01-baseline-inventory.md §1). No staging or dev exists.

## 1. Consolidated risk register

| ID | Risk | Trigger | L | I | Detection | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-01 | **Staging drifts from production** | Staging built from a G3 schema dump, which excludes auth settings, the `auth.users` trigger, extensions, Edge bundles, secrets and data (../../stage1/12-g3-baseline-plan.md §1, §4) | H | H | Re-run g1-q1/q2/q3b/q5/q6/q7 against staging and diff counts/ACLs; `migration list`; auth-settings checklist; function SHA list | Baseline + separate auth-trigger file; parity checklist; synthetic seed; record accepted differences; never treat a staging pass as proof for excluded layers | Migration owner + reviewer |
| R-02 | **CLI and dashboard disagree during G3** | `config.toml` declares `public, graphql_public` while prod exposes `public, extensions`; `[db.seed] enabled = true` with no `seed.sql`; `project_id = "control"` (../../stage1/12-g3-baseline-plan.md §7 G3-a/b/c) | H | H | `supabase status`, link prompt ref, `migration list`, `db diff`; failed `db reset` at seed step | Dashboard is production truth; fix seed config before any link; one operator shell; echo project ref in every command; never link prod while staging work is open | Owner + operator |
| R-03 | **Edge source unavailable or minified, blocking handler fixes** | `supabase/functions/` absent; 7 of 9 bundles are 2-line minified esbuild output; no source maps; export needs project credentials (../../stage1/13-edge-function-source-inventory.md §1, §6.1) | H (VERIFIED absence) | H | Repository listing; editor SHA-256 vs capture; no reviewable diff possible | Owner-authorised export first (13 §7); treat bundle as evidence, not build source; do not edit/deploy handlers before export; P01–P03 are SQL-only and independent | Owner + Edge reviewer |
| R-04 | **ACL rollback is not byte-identical** | Both functions start with `proacl = NULL` (PUBLIC default); a `GRANT` leaves an explicit `=X/postgres` entry impossible to restore without a catalogue update (../../stage1/11-remediation-proposals.md F8) | Certain if rolled back | L (behaviour) / M (audit) | `proacl is null` before; `proacl` text after rollback; `has_function_privilege` | Accept functional equivalence, never `UPDATE pg_proc`; record the difference in the change record; verify effective privilege per role | DB owner |
| R-05 | **Unique index blocks sessions when expiry lags** | Partial unique index on `status in ('requested','accepted','active')`; expired rows keep a live status until `cron expire_sessions` runs; scheduler reliability is NOT VERIFIED (../../stage1/16-phase-e-findings.md E4; ../../stage1/07-ops-and-observability.md §2) | M | H | Count live-status rows with `expires_at < now()`; 23505 in handler logs; request failure rate | Prefer an insert trigger that expires stale rows under the device advisory lock, then checks; otherwise expire-before-insert in the handler; pre-check duplicates; map 23505 to 409 `session_in_progress`; test expired fixtures | Migration owner + Edge owner |
| R-06 | **Function-body replacement error** | Full-body `CREATE OR REPLACE` drops a retained statement, changes a signature (creates an overload), or omits `SECURITY DEFINER`/`search_path`; F3 explicitly warns a partial body breaks every update (../../stage1/11-remediation-proposals.md F3) | M | H | Hash `prosrc`/`pg_get_functiondef` before vs after; `prosecdef`, `proconfig`, overload count; smoke calls | Store captured text verbatim offline first; restate `SECURITY DEFINER` and `SET search_path`; one function per migration; staging first; normalised definition diff; capture the 11 unread bodies before extending the guard | Migration owner + reviewer |
| R-07 | **Secret/pepper mismatch makes old hashes unfindable** | `PAIRING_HASH_PEPPER` set, changed or absent; fail-closed build deployed before the secret; staging and prod use different peppers; service-role key rotated without redeploy (../../stage1/16-phase-e-findings.md E6; ../../stage1/13-edge-function-source-inventory.md §6.4) | M | H | Startup warning `pairing_hash_pepper_missing`; pairing success rate; 401/503 spike; `supabase secrets list` digests only | Set secret before fail-closed deploy; dual-read token hashes; **never rotate the prod pepper in Stage 2**; independent documented staging secret; mint/redeem pair as proof; rotate service key only with a redeploy plan | Owner (secrets) |
| R-08 | **Staging email is limited** | Nine fixtures, six need verified email (../../stage1/15-edge-function-test-plan.md §1); confirm-email is on; default Supabase SMTP has a low hourly cap (INFERRED; exact limit not read) | H | M | Auth logs "email rate limit exceeded"; fixtures stuck unconfirmed | Pre-create fixtures with admin API and mark `email_confirmed_at` in staging only; or disable confirm-email in staging and record the difference; stagger; plus-addressing; never use prod accounts | Test lead |
| R-09 | **Free-plan two-project ceiling** | Prod occupies one slot; the Free plan allows two active projects (INFERRED public limit; ../../stage1/07-ops-and-observability.md §6 says "not inspected"); staging + dev exceeds it | H | H | Org project list and plan page; create attempt returns a limit error | Staging is the single slot; dev deferred with G2/G7; never pause prod to free a slot; written budget check; delete staging after validation or keep it as the only non-prod; no paid upgrade without written approval | Owner |
| R-10 | **Accidental production action** | Dashboard tabs look alike; similar project refs; CLI link left pointing at prod; SQL Editor autocommits; an agent or tired operator pastes the wrong block | M | C | Project banner/ref check; `select current_database()`; audit_logs; migration list; row-count delta | Read-only wrapper; two-person rule for prod; separate browser profile; agents never execute; ref echoed in every change record; close session after the window | Owner + operator |
| R-11 | **Test data contaminates production** | G5 fixtures created on prod; prod rows copied to staging; test devices send telemetry | M | C | New profiles/families/devices unexplained; audit_logs; counts vs profiles 8 / families 3 / devices 14 (../../stage1/01-baseline-inventory.md §2) | Staging only; synthetic fixtures; no data copy (../../stage1/06-secrets-and-environments.md §3); prod tests read-only; distinct device secrets; no prod emails | Test lead + owner |
| R-12 | **Client app incompatibility** | New 409/42501/503 responses, leaked-password 4xx, CORS allowlist, or narrowed columns surface in the app; client source unavailable; 1.0 and 1.2 APKs differ in signing key (../../stage1/10-owner-runbook.md §6) | M | H | Staging smoke on `Haven-1.2-release.apk`; unhandled error codes; crash logs; parent/child flow | Preserve envelope and status shapes; map new failures to existing codes; dual path/flag; release notes; real-APK smoke before prod | Client owner + product |
| R-13 | **Rollback text missing for unread bodies** | 11 `private` and 12 `public` bodies remain unread (../../stage1/00-status-register.md PA3); the guard is extended beyond the three captured functions | M | H | Captured `prosrc` count vs 38; rollback file completeness check | Scope P02 to the three read bodies; capture all bodies read-only before any extension; no change without stored original | Migration owner |
| R-14 | **Baseline/restore proof stays blocked** | No Docker locally; `seed.sql` missing; no non-prod target; backup/restore never tested (../../stage1/12-g3-baseline-plan.md §2, §5; ../../stage1/07-ops-and-observability.md §3) | H | H | `supabase start`/`db reset` failure; empty-diff proof absent | Staging project as restore target; fix seed; keep G3 at READY not PASS until restore succeeds; record unproven restore as residual risk | Owner + operator |
| R-15 | **Quota/observability exhaustion during verification** | Log query already 33.9/100 GB; verbose function logs; repeated staging investigations (../../stage1/07-ops-and-observability.md §2) | M | M | Quota panel; log-query refusals; ingestion growth | Prefer table rows over log lines; narrow time windows; no verbose logging; snapshot quota before/after each window | Operator |
| R-16 | **Single approver, no separation of duties** | One owner account for the org; no second approver or break-glass (../../stage1/06-secrets-and-environments.md §1) | H | M | Change records where one person holds every role | Named reviewer performing a separate checklist pass; time-box; defer non-essential patches; record dissent; never rubber-stamp same-session | Owner |

## 2. Per-patch rollback (all `PROPOSED — NOT APPLIED`)

Preconditions for any rollback: the captured pre-state exists offline (`g1-b3b` bodies, `g1-q7` `proconfig`, `g1-q6`
ACLs); the rollback text is reviewed with the patch; production rollback needs the same approval as the forward change.
Rollback order is reverse of apply: **P03 → P02 → P01**. Rolling back a security fix re-opens the latent path it closed.

### S2-P01 — revoke PUBLIC EXECUTE + service_role grant + guard search_path

| Field | Proposed answer |
| --- | --- |
| Exact reversal | `grant execute on function private.request_device_recovery(uuid, uuid) to public;` · `grant execute on function private.remote_session_transition_guard() to public;` · optional `revoke execute on function private.request_device_recovery(uuid, uuid) from service_role;` · `alter function private.remote_session_transition_guard() set search_path = public, pg_temp;` |
| Behaviour vs exact state | Restores **behaviour** (PUBLIC can execute both; original guard path). **Not exact**: `proacl` becomes explicit `=X/postgres` instead of `NULL`; the service_role grant can be left or removed, neither reproduces `NULL`. Catalogue `UPDATE pg_proc` is not proposed |
| Data loss | None — privileges and one setting only; bodies untouched |
| Time to roll back | ≤5 min for four statements, plus verification |
| Verification after | `has_function_privilege('anon'/'authenticated', …)` true again; `prosrc` hash unchanged; `proconfig` exactly `{search_path=public, pg_temp}`; recovery call as service_role still succeeds |

**Warning:** this rollback restores E2/F8 exactly as Stage 1 found it (../../stage1/16-phase-e-findings.md E2). It is a
security regression, not a neutral undo; require owner sign-off and a recorded reason.

### S2-P02 — actor guard in three bodies + remote-session authorisation + search_path

| Field | Proposed answer |
| --- | --- |
| Exact reversal | `create or replace function` with the verbatim Stage 1 body for `private.request_device_recovery`, `private.unlink_child`, `public.request_remote_session`, restating `SECURITY DEFINER`, owner and `SET search_path`; restore `public.request_remote_session` to `set search_path = public, pg_temp` (its pre-patch value, F5) |
| Behaviour vs exact state | **Exact behaviour** if the captured text is used verbatim; OID and ACL are preserved by `CREATE OR REPLACE`. Definition text is exact only if no reformatting; otherwise semantically exact. Signature must not change (otherwise an overload is created) |
| Data loss | None — no table is written. Audit rows already written by a forged actor are **not** corrected by rollback; that needs a separate data decision |
| Time to roll back | 10–15 min including three staging calls |
| Verification after | Forged-actor call succeeds again **in staging only** (expected regression); legitimate service_role call still succeeds; `prosrc` hashes equal capture; `prosecdef = true`; `proconfig` restored; no new overload |

### S2-P03 — single-live-session enforcement (index or insert trigger)

| Field | Proposed answer |
| --- | --- |
| Exact reversal | Index variant: `drop index public.remote_sessions_one_live_per_device;` Trigger variant: `drop trigger remote_sessions_single_live_guard on public.remote_sessions;` then `drop function private.remote_sessions_single_live_guard();` (trigger first) |
| Behaviour vs exact state | **Exact** pre-patch state if the change was purely additive: object absent, table and rows unchanged. No ACL to restore |
| Data loss | None on rollback. Duplicate live rows created while enforcement was off are not removed; cleanup is a separate, approved DML item. Dropping the index does **not** repair duplicates already present |
| Time to roll back | <2 min; index build/drop is seconds at 39 estimated rows (../../stage1/01-baseline-inventory.md §2) |
| Verification after | `pg_indexes` / `pg_trigger` shows the object absent; two live inserts for one device are accepted in staging; production read-only confirms absence; handler no longer returns 409 for a second request |

Rollback is behaviour-restoring but leaves the live consent-integrity defect (E4) in place. If the handler was also
changed, revert handler and database together; a half-revert produces either 500s or silent duplicates.

## 3. Approval matrix

The approver is the single owner in every row because no second approver exists (R-16). "Reviewer" means a separate,
recorded checklist pass, not a second legal identity. Evidence is stored with the change record, never as a secret value.

| # | Action | Who must approve | Evidence required | Remains forbidden |
| --- | --- | --- | --- | --- |
| A1 | Read-only introspection, staging or prod | Owner (prod); test lead (staging) | Query text, read-only wrapper, project ref, result file path | Any DDL/DML; reading table data; exporting PII |
| A2 | Create staging project (G6) | Owner | Plan-slot check, cost statement, ref, no prod data, synthetic seed plan | Copying prod data; paid upgrade; creating dev as well |
| A3 | Capture G3 baseline / dump | Owner; DB password supplied interactively | Two identical dumps, zero `COPY`/`INSERT`, GRANT/default-ACL counts vs g1-q6, ref | `db push`, `migration up`, `db reset`; password in repo/chat |
| A4 | `migration repair --status applied <version>` | Owner, explicit version id written before and after | Baseline hash, target version, `migration list` before/after, empty `db diff` | Running the baseline as DDL; repairing to hide drift |
| A5 | Apply P01/P02/P03 to staging | Owner + reviewer | Patch SQL hash, pre-state capture, rollback text, staging test results | Production; touching unread bodies; secrets |
| A6 | Apply P01/P02/P03 to production | Owner + reviewer, in a stated window | Staging pass, 7-item gate met, rollback text offline, row-count snapshot, change record | Agents executing SQL; `db push --include-all`; RLS/policy widening; ad-hoc editor SQL |
| A7 | Export Edge source to repo | Owner (credential) | `functions download` output, SHA list, commit, no secret in tree | Editing live functions in the dashboard; deploying from the minified bundle |
| A8 | Deploy an Edge Function | Owner + Edge reviewer | Repo diff, staging function test, error-shape compatibility, deploy command | Production deploy by an agent; deploying untested source; secrets in code |
| A9 | Set or rotate any secret | Owner only | Secret **name**, digest from `secrets list`, sequence (set → verify → deploy), rotation reason | Reading/pasting values; rotating the prod pepper in Stage 2; service key in repo |
| A10 | Roll back any production patch | Owner + reviewer, incident note | Stop condition met, exact reversal, data-loss statement, post-rollback verification | Improvised catalogue updates; restoring PUBLIC without security sign-off |
| A11 | Create test fixtures | Test lead (staging only) | Synthetic fixture list, no prod identifiers, deletion plan | Any test user/family/device in production |
| A12 | Firebase / FCM | Owner, outside Stage 2 | G2 decision, project id, package `com.haven.familysafety` | Any Firebase action in Stage 2; service-account JSON in repo/chat |
| A13 | Client release | Product owner | Staging smoke on the release APK, error-code map, rollback/rollout plan | Shipping against an untested staging build |

**Global prohibitions for every row and every agent:** production SQL, production Edge deploy, any secret value, and any
Firebase action. An approval for A6 never implies A8, A9 or A12. No approval can be inferred from silence.

## 4. Production release gate (7 items, `PROPOSED`)

Release may start only when all seven are evidenced in one change record. "Green" means observed in staging, not inferred.

1. **Staging parity** — staging built from the reviewed G3 baseline plus the separate `auth.users` trigger file; g1-q1/q2/q3b/q5/q6/q7 re-run and diffed against prod; every difference listed and accepted (R-01).
2. **Frozen patch set** — P01, P02 (three bodies only) and P03 SQL final, hashed and reviewed; no unread body touched; no secret or Edge deploy bundled (R-06, R-13).
3. **Staging rehearsal green** — forged actor → `actor_mismatch`; `anon`/`authenticated` EXECUTE false; legitimate service_role paths 2xx; duplicate session → 409; release-APK smoke passes with no unhandled error shape (R-05, R-12).
4. **Rollback rehearsed in staging** — apply, reverse, re-apply; recorded times; ACL/body/`proconfig` comparisons; explicit statement of what is not byte-identical and what data is not restored (R-04, R-06).
5. **Baseline and recovery posture** — G3 captured and restore-proven, or a written acceptance that restore is unproven; row-count snapshot for affected tables (R-14).
6. **Window and observability** — owner + reviewer named, window stated, logs open, alert destination set, quota numbers recorded, stop conditions read aloud (R-10, R-15).
7. **Written approval and change record** — A6 signed, project ref `hhqgreaoqulmfwfwarhc` stated, forbidden actions acknowledged, post-change verification owner named.

**Stop conditions — abort immediately, do not "finish the window":** unexplained staging/prod drift; staging unavailable;
patch hash differs from review; PUBLIC/authenticated EXECUTE still true after P01; forged actor not rejected or a
legitimate call fails; duplicate live session accepted or a valid request returns 23505/500 instead of 409; non-empty
baseline diff or migration-history mismatch; any prod data in staging or test account in prod; any secret/pepper change or
401/503 spike; rollback text missing or unrehearsed; client crash or unhandled error code; log query >80 GB or DB >400 MB;
no reviewer present; any request to exceed the approval matrix.

## 5. Change-record template

```text
CHANGE ID: S2-<nnn>            DATE/TIME (UTC):            OPERATOR:
ENVIRONMENT / PROJECT REF:                                 APPROVER + REVIEWER:
PATCH / ACTION:               HASH OF SQL OR DIFF:
MOTIVATION (finding IDs):     SCOPE (objects, functions, rows):
PRE-STATE EVIDENCE:           ACL / prosrc hash / proconfig / row counts / db diff:
STAGING EVIDENCE:             test IDs, results, APK version, timestamps:
PRODUCTION PRE-CHECKS:        ref confirmed, read-only check, quota, window:
EXACT STATEMENTS APPLIED:     (verbatim, numbered)
EXPECTED EFFECT:              VERIFICATION (per statement):
ROLLBACK TEXT + TIME:         DATA-LOSS STATEMENT (none / which rows):
OBSERVED SIDE EFFECTS:        QUOTA DELTA:
DECISION:                     KEEP / ROLLBACK / FORWARD-FIX
FOLLOW-UPS / NEW RISKS:       EVIDENCE PATHS:
SIGN-OFF:                     OPERATOR:            APPROVER:            REVIEWER:
```

No record is closed while a verification cell is blank or a follow-up lacks an owner. A failed change becomes a finding,
not a silent revert (../../stage1/07-ops-and-observability.md §7).

## Open questions

1. Is the Free-plan project limit actually 2, and is staging the single permitted slot? (R-09; Stage 1 records the limit
   as "not inspected".)
2. Does the G3 baseline become migration `0001` via `migration repair`, or stay a reference dump? This must be decided
   before staging is cloned (../../stage1/12-g3-baseline-plan.md §6).
3. Is `PAIRING_HASH_PEPPER` set in production, and may staging use a different pepper? Values were not read (E6).
4. P03: index or insert trigger, and who owns the `cron expire_sessions` schedule that makes expired rows stop counting?
5. Is `Haven-1.2-release.apk` the compatibility baseline, given 1.0 uses a different signing key? (../../stage1/10-owner-runbook.md §6.)
6. Who performs the separate reviewer pass in a single-owner org, and may the 11 unread bodies be captured read-only now
   so rollback text exists before any guard extension?

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **The register now runs R-01…R-43** ([`04-risks-rollback-approvals.md`](../04-risks-rollback-approvals.md)); this part's table stops at R-16 and is only a fragment of the current register. *(Corrected 2026-11-02 in the S2-EXEC-03 pass: this line said "R-01…R-41" while 04 §1 already claimed R-01…R-43 and, until that pass, had no R-41 row — a present-tense range claim was stale. Historical statements elsewhere that said R-01…R-41, in CHANGELOG and in S2-REVIEW-03's verdict, are point-in-time records and were left as written.)*
- Newly realised/added rows: **R-36** A12 boundary breached — a Firebase project was created (`haven-staging` / `haven-staging-46822`, Spark, zero apps, zero credentials, FCM not configured); **R-37** A0/A2 were never signed yet the creation was executed, so it can only be **retrospectively ratified**, never honoured in advance; **R-38** zero slot headroom; **R-39** the staging DB password exists with unmanaged custody; **R-40** the auto-pause deadline is running with no recorded start timestamp; **R-41** falsified status lines across the plan of record.
- **§1's "No staging or dev exists" and R-09's "INFERRED ceiling" are superseded.** The ceiling is verified and realised: **2 active / 2 used / 0 remaining**; `parent-control-staging` (ref `dzonzgngwxclhfnvxtvu`) holds the second slot, so no `dev` project is possible on Free ([S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)). The shell is nevertheless **empty** — 0 tables, no schema, no `private.s2_environment` sentinel, no secrets, no test principals, no Edge Functions.
- **The "delete and re-create" rollback branch is WITHDRAWN** (R-17/R-38 in the plan of record): with 0 slots remaining it destroys the only non-production target and slot reuse after deletion is unproven. Failures are repaired in place, or stopped and recorded — never deleted to "start clean".
- **`A4` in §3 is historical only** — the CLI `migration repair --status applied` approval. The plan of record numbers approvals **A0–A3 and A5–A13 and has no A4**; do not cite A4 as a live gate.
- **Approval reality:** A0/A2 never signed ([`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`); the replacement [`approval-package-v2-ratification-and-forward.md`](../approval-package-v2-ratification-and-forward.md) has seven independently signable blocks A0, A1, A2′, A3, A5, A9, A12, and **A2′ authorises only the sentinel plus approved settings** — no schema load, no secrets, no Firebase app registration. A3, A5, A9, A10, A11, A12, A13 remain unsigned and unexecuted.
- **All three patches remain `PROPOSED — NOT APPLIED`** and defects D-01…D-12 are OPEN, so §2's rollback designs are unrehearsed and §4's release gate is unmet. G5-S is `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)`, G5-E `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`, app compatibility `BLOCKED — NO APP SOURCE IN THIS REPO`.
- **R-13's premise is partly corrected:** the original function bodies (prosrc) — `create_edge_api_token` etc. — ARE captured in the repository at [`g1-b3b-20261029.json`](../../stage1/evidence/g1-b3b-20261029.json) lines 149/155/159/165 (metadata 62/67/78); any claim that rollback bodies exist nowhere is false and superseded.
- Screenshots were NOT captured, so evidence claims of that form are `NOT VERIFIED`; auto-pause needs a dated dashboard touch **on or before 2026-11-06** (approximate).
- No operational action taken in this pass — and nothing was signed: this addendum is not an approval and does not ratify anything.
