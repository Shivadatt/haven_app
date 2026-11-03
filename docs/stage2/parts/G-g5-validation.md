# G5 — Staging validation map

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

Status: **`PLANNING ONLY — NOTHING EXECUTED`**. This part invents no tests. It maps the Stage 1 cases onto a
staging environment that does not yet exist, and states which layer can run each one.

Labels: **VERIFIED** (read from a Stage 1 document or the repository) / **INFERRED** (deduced, not observed) /
**PROPOSED** (a plan step) / **NOT TESTED** (default for every case below) / **BLOCKED — …** as required by the
brief. Inputs: [15 — test plan](../../stage1/15-edge-function-test-plan.md),
[08 — test matrix](../../stage1/08-test-matrix.md), [16 — findings](../../stage1/16-phase-e-findings.md),
[06 — environments](../../stage1/06-secrets-and-environments.md).

## 1. What is being mapped

- Doc 15 holds **105 cases**: 20 `TE-xx`, 78 `PE-xx` (13 `PE-P`, 6 `PE-A`, 9 `PE-C`, 7 `PE-R`, 7 `PE-PL`,
  12 `PE-T`, 7 `PE-F`, 10 `PE-S`, 7 `PE-CR`), 7 `CI-xx`. **VERIFIED** by counting the tables in doc 15 §2–§4.
- Doc 08 adds 19 SQL-shaped rows `T-01…T-19`, of which `T-01`, `T-02`, `T-18` are `PARTIAL` on catalogue evidence
  and `T-19` is source-verified. **VERIFIED** from doc 08 §1 header.
- Staging does not exist: doc 06 §3 records `dev = No`, `staging = No`. **VERIFIED**, so every row below is a plan
  against a future environment, and the only live environment remains `parent-control-prod` (`hhqgreaoqulmfwfwarhc`),
  which is out of bounds for this gate.
- Edge Function source is not in the repository (doc 13 §1, `supabase/functions/` absent). **VERIFIED**, so nothing
  can be deployed to staging from this repo, which is the root of the Layer-2 block.

## 2. Staging prerequisites (assumed work items)

**Renumbered.** The staging work items are `G6-a…d`; `S2-P01…P03` are the SQL patches. The earlier draft of this
part used `S2-P01…P03` for both, which would have pointed the test mapping at the wrong artefact
([06](../06-redteam-resolution.md) J-16).

| Item | Deliverable | Label |
| --- | --- | --- |
| G6-a | Staging Supabase project created (G6 decision), ref recorded, staging keys held only in the owner's secret store | PROPOSED |
| G6-b | Environment sentinel `private.s2_environment` plus the settings checklist | PROPOSED |
| G6-c | G3 catalogue baseline applied (19 tables, 21 policies, 38 functions, `auth.users` trigger) | PROPOSED |
| G6-d | SQL access (owner-run dashboard editor) plus a harness that can `set local role` and set `request.jwt.claims` for a synthetic fixture | PROPOSED |

No staging-specific item unblocks a single `PE-*` or `CI-*` case: those are HTTP tests against deployed functions.
That is the central finding of this part.

## 3. Layer table

| Layer | What it needs | Cases that can run | Status |
| --- | --- | --- | --- |
| L1 — SQL only | G6-a…d + `S2-P01…P03` | `TE-02`; doc 08 `T-01…T-18` | Runnable once staging exists; destructive cases still need the ordering rules in §9 |
| L2 — deployed Edge Functions | L1 **plus** function source in the repo, a build, staging secrets (`PAIRING_HASH_PEPPER`, `CRON_SECRET`, `TURN_*`) and a deploy | 19 `TE` + 78 `PE` + 7 `CI` = **104 cases** | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| L3 — client builds | L2 plus an owner-supplied APK with the staging URL/anon key baked in | No doc-15 case; only the compatibility sign-off in §8 | `BLOCKED — NO APP SOURCE IN THIS REPO` |

**Why only one doc-15 case is L1.** Every `PE-*` row is written as `POST /<slug>` with gateway headers; the
authorisation, validation and rate-limit logic under test lives in the handlers, not in SQL. Running the RPC
underneath a handler is not the same test and cannot be substituted (`PE-C05`, `PE-T11`, `TE-15` are specifically
handler-level). **INFERRED** from doc 15 §3 request column, and consistent with doc 08 `T-19`.

**`TE-02` is the one exception** and stays L1: its request is `rpc/request_device_recovery` executed as
`authenticated` with `p_actor_user_id` forged. On staging it can be issued two ways, both recorded separately:
direct SQL with `set local role authenticated` + `request.jwt.claims`, or `POST /rest/v1/rpc/...` if `private` is
exposed on staging (an exposure change, staged only). **INFERRED**.

**Coverage gaps to record, not fill.** Doc 16 carries verification tests with no doc-15 case: E1 (forged
`p_parent_user_id` to `public.request_remote_session`), E4's *sequential* double request (doc 15 has `PE-S08`
concurrent-ish and `CI-04`, not the sequential 409), E6 (unset pepper → 503), E10 (server-issued secret), E13
(`apps_upload` writes an audit row). Adding case IDs is an owner decision; until then these are
`BLOCKED — NO CASE ID`. **VERIFIED** by comparing doc 16 "Verification test" paragraphs against doc 15.

## 4. Fixture instantiation for staging

Seeded after G6-c by one idempotent, owner-run seed script kept outside the repository (it holds staging-only fixture
identifiers). **PROPOSED — NOT APPLIED.**
Synthetic only: emails `*@fixture.example.test` (reserved TLD), UUIDs from the fixed range
`00000000-0000-4000-8000-00000000NNNN`, device secrets generated at seed time and never written into evidence.

| Fixture | Object | Synthetic identity | Seed state | First needed by |
| --- | --- | --- | --- | --- |
| A | parent, owner of F | `a@fixture.example.test` | verified email, `family_members.role='parent'` | `TE-01`, `TE-10`, `PE-A04`, `PE-F01` |
| B | parent in F | `b@fixture.example.test` | verified, second parent, not owner | `TE-10`, `TE-11`, `PE-F06` |
| C | parent, owner of G | `c@fixture.example.test` | verified, **no** membership in F | `TE-01`, `TE-03`, `PE-F02`, `TE-02` |
| K | child in F | `k@fixture.example.test` | verified, active membership | `TE-05`, `PE-P01`, `PE-R01` |
| M | child in G | `m@fixture.example.test` | verified, device D2 | `PE-C02`, `PE-R04`, `PE-T11` |
| N | parent, no family | `n@fixture.example.test` | verified, zero memberships | `PE-A04` baseline, doc 08 `T-02` |
| U | unset role | `u@fixture.example.test` | `profiles.role='unset'`, verified | `PE-A01`, `PE-A02` |
| X | unverified | `x@fixture.example.test` | email unconfirmed — needs admin-API creation, not public signup | `PE-A03` |
| D1 | device of K, family F | `…000000d1` (device id) | active, known secret, `pending_policy_version` set | `PE-C01`, `PE-PL01`, `PE-F01` |
| D2 | device of M, family G | `…000000d2` | active, known secret | `PE-C02`, `PE-PL07`, `PE-T11` |
| R1 | revoked device of K | `…000000e1` | `revoked_at` set, `secret_hash` null, revoked **after** a later approved pairing | `PE-R05` |

Also seed, per doc 15 §1: one active pairing code for K, one expired code for K, one pending `pairing_request`
for K from A, one `requested` remote session from A to D1, one live `safety_alert` in G (for `PE-F04`), and 60
pending rows for `PE-S10`. **PROPOSED**.

**Naming collision to resolve.** Doc 15 uses `R1` for the revoked device *and* as the `request_id` in `TE-10`
(`request_id:"<R1>"`). Record the pairing request as `PR-1` while quoting `TE-10` verbatim; do not let the seed
script alias the two. **VERIFIED** collision, **PROPOSED** disambiguation.

## 5. Pass/fail/evidence record

One JSON object per case, `docs/stage2/evidence/g5-<runid>/<case-id>.json`, raw response minus redactions, plus
one CSV index per suite. **PROPOSED**, matching doc 08 §3 and doc 15 §5.

| Field | Content | Rule |
| --- | --- | --- |
| `case_id` | exactly as in doc 15 (`TE-04`, `PE-PL07`, `CI-02`) | no invented suffixes except `-a`/`-b` for the two halves of `TE-08` |
| `layer` | `L1` / `L2` / `L3` | must match §3 |
| `verdict` | `PASS` / `FAIL` / `FINDING` / `BLOCKED — …` | `FINDING` only for a destructive case that succeeds (§6) |
| `status` | HTTP status, or the SQLSTATE for L1 | never a guess; blank is not a value |
| `error.code` | the function's `error.code`, verbatim | `null` when the path returns 2xx |
| `response_shape` | key names, types and array lengths only | never a full body with a token or device secret in it |
| `request` | method, path, header **names**, body with fixture names | `Authorization`, `apikey`, `x-device-secret`, `x-cron-secret` → `<redacted>` |
| `request_id` | gateway/function request id if one is emitted | see open question Q3; record `none-emitted` rather than inventing one |
| `sql_evidence` | before/after row counts, `audit_logs` row count and `actor_user_id` (fixture name, not UUID), state of the fixture row | counts only; no coordinates, no emails |
| `project_ref` | the **staging** project ref | a prod ref here invalidates the whole run |
| `timestamp`, `run_id`, `patch_state` | UTC, run label, which of `E1…E14` were applied at run time | `patch_state` is what makes the result re-interpretable later |

## 6. Interpretation rules

1. **A destructive case that passes is a finding.** `TE-02` unlinks K; `PE-P09`, `PE-F01`, `PE-F03`, `PE-F05`,
   `PE-CR01`, `PE-CR02` revoke, purge or expire rows. Verdict `FINDING`, never `PASS` (doc 15 §0 rule 2).
2. **5xx stops the run.** Capture `error.code` and the redacted body, do not retry the path, do not proceed to the
   next suite until triaged (doc 15 §0 rule 4). A 5xx on a validation path is itself a reportable defect.
3. **Never print tokens.** No JWT, anon key, service-role key, device secret, cron secret or live pairing code in
   any evidence file, chat line or commit. A pairing code is a one-time secret: record `code consumed` (doc 15 §0
   rule 3, doc 08 §3).
4. **Never a production identifier.** If a run touches `hhqgreaoqulmfwfwarhc`, discard the run and report the
   process failure, not the result. No prod data is copied into staging (doc 06 §3 item 3).
5. **"No error" is not a pass.** A `200` proves nothing unless the expected column in doc 15 was met *and* the SQL
   evidence shows the row/state change the case predicts (doc 08 §3).
6. **One change at a time.** After any patch from doc 16 is applied on staging, re-run the baseline cases for that
   function before trusting later results (doc 15 §0 rule 5).
7. **A reset invalidates mutating results.** If the seed is re-run between suites, previously recorded mutating
   results for the consumed fixtures are void; read-only results survive.
8. **A 429 without a counted window is not evidence.** For `PE-P03`, `PE-P08`, `PE-P13`, `CI-01` record the
   attempt count and window start; an observed 429 alone does not show the limit was correct.

## 7. Fix gating

Per the user's rule: **a case that asserts post-fix behaviour is `BLOCKED — FIX NOT APPLIED`, never `PASS`**,
even if the pre-fix behaviour happens to match. Running the pre-fix path is allowed exactly once, on staging, and
its verdict is `FINDING` (baseline) or `PASS` (regression guard) — never "the fix works".

| Patch | Case(s) whose expectation depends on it | Before the patch | After the patch |
| --- | --- | --- | --- |
| E2 + E3 (`GRANT`/`REVOKE`, actor guard) | `TE-02` | `FINDING` — the RPC unlinks K | `BLOCKED — FIX NOT APPLIED` until applied; then `42501` expected |
| E1 (no authorisation at all) | *no doc-15 case* (doc 16 §E1) | `BLOCKED — NO CASE ID` | same |
| E3 (JWT binding) | `TE-15` | `PASS` if the audit actor equals the JWT subject | unchanged by fix; re-run as guard |
| E4 (single live session) | `PE-S08`, doc 16 §E4 sequential test | `FINDING` — both succeed | `BLOCKED — FIX NOT APPLIED`; then `409` |
| E7 (budgets) | `PE-T12`, `TE-20` | `FINDING` — 100 uploads / 20 secrets accepted | `BLOCKED — FIX NOT APPLIED` |
| E8 (atomic counter) | `CI-01` | observe only; "exactly 5" is not assertable | `BLOCKED — FIX NOT APPLIED` |
| E9 (CORS allowlist) | `PE-CR07` | `FINDING` — wildcard ACAO | `BLOCKED — FIX NOT APPLIED` |
| E12 (cron replay window) | `CI-07` | `FINDING` — replay returns 200 | `BLOCKED — FIX NOT APPLIED` |
| E10 (server-issued secret) | `PE-R06` (format only) | `PASS` on format, says nothing about predictability | `BLOCKED — FIX NOT APPLIED` for the issued-secret case |
| E11 (response projection) | `PE-C04` | not asserted by the case text | `BLOCKED — NO ASSERTION` |

No patch is applied. **VERIFIED** — doc 16 status line reads `OPEN — PROPOSED, NOT APPLIED`. Therefore every row
in the "after" column above is currently blocked, and the only executable value of §7 today is the baseline
half, on staging, once.

## 8. App compatibility step

Purpose: prove a patched staging backend has not broken the shipped client — the risk doc 16 raises for E10
(device-secret flow) and E11 (column projection).

Protocol, **PROPOSED**, owner-run because no client source is in this repository (doc 06 §2: "No app module
exists yet"; doc 13 §1: no `supabase/functions/` either):

1. Owner builds a debug-flavoured APK (or iOS equivalent) from the client repository with `SUPABASE_URL` and
   `SUPABASE_ANON_KEY` pointing at **staging**. `applicationId` gets a staging suffix (doc 06 §3).
2. The service-role key, DB password and any `*_SECRET` never enter the build; only the anon key is client-side by
   design (doc 06 §1).
3. Record build identity: commit hash, flavour, and a **fingerprint** of the anon key (e.g. first 6 chars of its
   SHA-256), never the key itself.
4. Smoke script against fixtures: sign-in as K, pairing `create`, redeem as A, `heartbeat`, receive a policy
   version bump, background a location upload, accept a remote-session request, `ack` a command.
5. Repeat after each staging deploy that touches a response shape; a client crash or a parse error is a `FAIL`
   with the logcat excerpt redacted of tokens.

Status: **`BLOCKED — NO APP SOURCE IN THIS REPO`**. No build can be produced from `D:\control`, and no source,
signing key or CI pipeline for the app exists here. Step 3 is the only part that could be done today, and it is
worthless without 4.

## 9. Ordering and teardown

**PROPOSED**, derived from the fixture-consumption order in doc 15:

| Phase | Contents | Why here |
| --- | --- | --- |
| 0 | Seed, snapshot fixture ids, record `patch_state` | every later verdict depends on it |
| 1 | Read-only / negative, no state change: `TE-05`…`TE-09`, `TE-16`, `TE-19`, `TE-01`, `TE-03`, `TE-04`, `TE-12`, `TE-13`, `PE-P04`, `PE-P06`, `PE-P11`, `PE-P12`, `PE-A03`, `PE-A05`, `PE-A06`, `PE-PL02`…`PE-PL04`, `PE-PL06`, `PE-PL07`, `PE-C02`, `PE-C09`, `PE-CR03`…`PE-CR06`, `PE-T02`, `PE-T04`…`PE-T09`, `PE-T11`, `PE-F02`, `PE-F04`, `PE-F06`, `PE-F07`, `PE-S06`, `PE-S09` | cannot burn a fixture or a code |
| 2 | Mutating happy paths and idempotency: `PE-P01`, `PE-P02`, `PE-P05`, `PE-P07`, `PE-P10`, `PE-A01`, `PE-A02`, `PE-A04`, `PE-C01`, `PE-C03`…`PE-C08`, `PE-R01`…`PE-R04`, `PE-R06`, `PE-R07`, `PE-PL01`, `PE-PL05`, `PE-T01`, `PE-T03`, `PE-T10`, `PE-F03`, `PE-F05`, `PE-S01`…`PE-S05`, `PE-S07`, `PE-S10`, `TE-10`, `TE-11`, `TE-15`, `TE-17`, `TE-18`, `PE-CR01`, `PE-CR02` | consumes codes, sessions and policy versions |
| 3 | Destructive, once each, on a freshly reset seed: `TE-02`, `PE-P09`, `PE-F01`, `PE-R05` | irreversibly revokes or unlinks |
| 4 | `CI-01`…`CI-07`, last | parallel load perturbs counters and rate-limit windows that phase 1–3 rely on |
| 5 | Teardown: re-seed or reset staging; archive evidence; record which fixtures are now dirty | protects the next suite |

`TE-14` and `TE-20` sit in phase 3 (new `requested` row; 20 wrong secrets). Between suites 1→2 and 3→4 the seed
must be re-run: `PE-P05`/`PE-P10` link K to F, `PE-P09` unlinks K, `PE-F01` revokes D1 and `CI-02` consumes a
code, so a later suite reading the same fixture is no longer testing the state doc 15 assumes.

## Open questions

1. Is any staging work item a function deploy? None is today (G6-a…d are project, sentinel, baseline, harness), so
   Layer 2 stays blocked until the Edge source decision.
2. Is a second throwaway project available for `TE-08` ("a token signed for another project")? A foreign-project
   JWT cannot be produced on staging alone; otherwise that half is `BLOCKED — NO FOREIGN PROJECT`.
3. Do the deployed functions emit a request id (`x-request-id`, `sb-request-id`, log correlation)? Doc 15 §5
   requires recording one; nothing in doc 13/14/15 confirms one exists. **NOT VERIFIED.**
4. `TE-09` (expired JWT) needs either the staging JWT signing key or a short configured token lifetime. Which is
   the owner willing to expose — a signing key (sensitive) or a staging auth-config change (harmless)?
5. Is `PE-CR05` (15-character `CRON_SECRET`) runnable at all, since it needs a secret change **and** a redeploy
   rather than a request? It looks like a configuration test wearing a request's clothes.
6. Who approves adding case IDs for the doc-16 verification tests that doc 15 does not cover (§3 gaps)?
7. Should `TE-02`'s PostgREST variant run on staging at all, or only the SQL form, given that it needs `private`
   exposed?

## Blocked

- **All 104 `TE`/`PE`/`CI` HTTP cases** — `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`; no source in the repo
  (doc 13 §1) and no staging project (doc 06 §3).
- **`TE-02` and doc 08 `T-01…T-18`** — `BLOCKED — STAGING PROJECT NOT CREATED`; they need G6-a…d only, and
  are the first thing that becomes runnable.
- **Every post-fix expectation in §7** — `BLOCKED — FIX NOT APPLIED` (doc 16 is `PROPOSED, NOT APPLIED`).
- **App compatibility (§8)** — `BLOCKED — NO APP SOURCE IN THIS REPO`.
- **`TE-08` foreign-project half** — `BLOCKED — NO SECOND PROJECT`.
- **E1, E4-sequential, E6, E10, E11, E13 verification tests** — `BLOCKED — NO CASE ID`.
- **`PE-CR05`, `TE-16` short-secret half** — `BLOCKED — NEEDS SECRET CHANGE + REDEPLOY`.

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **Corrected counts.** Patch SQL 5 + 9 + 6 = **20** (not 21); doc SQL 1 + 18 = **19**; de-duplicated total 20 + 19 − 1 = **38** (not 39); HTTP 19 `TE` + 78 `PE` + 7 `CI` = **104**; G5-E in the plan of record is 104 + 4 = **108**. §1's "105 cases / 20 `TE`" is superseded; the §3 L2 figure of 104 stands.
- **"Staging does not exist" (§1, §2, Blocked) is superseded:** the shell exists — `parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO ([S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)). §2's `G6-a` is therefore done (shell only); **`G6-b`/`G6-c`/`G6-d` are NOT done.**
- **G5-S cannot run against an empty shell**: 0 tables, no schema loaded, no `private.s2_environment` sentinel, no secrets, no test users/principals, no Edge Functions — `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)`. G5-E `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`; app compatibility `BLOCKED — NO APP SOURCE IN THIS REPO`.
- **Every run record needs `start_utc` and `end_utc`.** §5's single `timestamp` field is not sufficient for the plan of record; add both, in UTC, per run, alongside `project_ref` and `patch_state`.
- **Screenshots were NOT captured** (the browser viewport was unstable, `visibilityState=hidden`): every screenshot-bearing step here (§6 rule set, §8 smoke) is `NOT VERIFIED` and may not be cited as evidence.
- **§7 is unchanged in substance**: all three patches remain `PROPOSED — NOT APPLIED` and defects D-01…D-12 are OPEN, so every "after the patch" cell is still `BLOCKED — FIX NOT APPLIED`.
- **Open question 2 is closed**: Free gives 2 active slots, **2 used, 0 remaining**, so no foreign/throwaway project for `TE-08` exists; that half stays `BLOCKED — NO SECOND PROJECT`.
- Approvals: **A5 unsigned**; the creation was executed on the owner's direct instruction and is an executed action awaiting retrospective ratification, not a signed A0/A2 ([`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`); the plan of record uses A0–A3 and A5–A13 and has **no A4**. Auto-pause needs a dated dashboard touch **on or before 2026-11-06** (approximate — no start timestamp recorded).
- No operational action taken in this pass — no SQL, no dashboard, no CLI, no test run, nothing signed.
