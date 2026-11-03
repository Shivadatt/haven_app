# Stage 2 — Controlled remediation and staging validation: execution plan

**Status (corrected 2026-11-02 by S2-DOC-02; see §9 addendum).**

| Item | Status |
| --- | --- |
| G6-a empty-shell staging creation | `EXECUTED — SHELL ONLY` on 2026-10-30 under a **direct owner instruction** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md)); the signable A0/A2 package ([approval-package-a0-a2.md](approval-package-a0-a2.md)) was **never signed**. **Ratification status corrected on 2026-11-02: `RATIFIED — OPTION (i)`** (recorded, fence unfilled; grants nothing forward — correction C-5). **A0 was approved 2026-11-02** (method amended per C-1); **A2′, A3, A9 and A12 remain unsigned**, and no signature fence in Stage 2 is physically filled |
| G6-b sentinel + settings, G6-c schema load, G6-d verify | `NOT DONE` |
| SQL run against any project | none |
| Secret created / configuration changed / deployment | none |
| Production `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) | **unmodified** — no setting changed, no SQL run, no key read or copied. Disclosure: one read-only page (Auth → Users, aggregate total only, no row transcribed) was opened on 2026-11-02 during the re-confirmation pass, before the owner directed that Supabase work stay on `parent-control-staging`; see [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1.6, §6. **Going forward: `parent-control-staging` only; no other project is to be opened, read or used.** |

Superseded (kept as history): the original status read `PROPOSED — NOT STARTED`. Nothing in this plan has been executed.
No staging project exists … — accurate when written, now superseded by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md).

**The plan is submitted for approval; it authorises nothing by itself**, and the 2026-10-30 creation was carried out
under a direct owner instruction, not under an approval granted by this plan.

Authority: [Stage 1](../stage1/README.md) is the evidence base. Where this plan and a Stage 1 document disagree, Stage 1
evidence is authoritative and the disagreement is listed as a decision (D-xx, §7). The working papers in
[`parts/`](parts/) are inputs; **this file, [01](01-staging-project-proposal.md), [02](02-findings-to-fix-mapping.md),
[03](03-patch-S2-P01.md), [04](04-risks-rollback-approvals.md), [05](05-validation-plan.md) and
[06](06-redteam-resolution.md) are the plan of record** where they differ from a working paper.

Two supporting documents sit **outside** the plan of record and change nothing in it:
[patch-defects-before-a5.md](patch-defects-before-a5.md) records documentation defects found in the patch papers, and
[approval-package-a0-a2.md](approval-package-a0-a2.md) is the signable A0/A2 request. Files under
[`evidence/`](evidence/) are captures, not plan.

Labels used throughout Stage 2: **VERIFIED** (read from Stage 1 evidence), **INFERRED** (follows from evidence, not
observed), **PROPOSED — NOT APPLIED** (design only), **BLOCKED — <reason>**, **NOT TESTED**, **NOT VERIFIED**.

---

## 1. Constraints carried into every step

| # | Constraint | Consequence in this plan |
| --- | --- | --- |
| C1 | Supabase **web dashboard only**; no Supabase CLI, no Firebase CLI, no terminal migrations, no direct production API calls | G3 cannot use `supabase db dump`; every SQL step is a pasted, reviewed block in the dashboard SQL Editor; verification is a read-only query returning a table |
| C2 | Production `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) is **not modified** | All DDL/DML targets staging. **The older consequence "production is read-only introspection only" is superseded by C2b below: under the owner's staging-only absolute there is no authorised production read of any kind, including catalogue-only reads (A1 `INOPERATIVE`, correction C-2).** Where C2 and C2b once disagreed, C2b governs |
| **C2b** | **Supabase project scope (owner instruction, 2026-11-02): every Stage 2 dashboard page, SQL Editor tab, setting, patch and test targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu` and no other project** | Binding on all later work. **As reaffirmed on 2026-11-02 (F-5-A / C2b), this is absolute and includes reads: A1's production catalogue capture is therefore `INOPERATIVE` — void in substance — and no production page or query is authorised by anything in Stage 2** (correction C-2). The clause above that once allowed "production read-only introspection under a separately signed A1" is superseded. Echo the ref from the console header into the change record before running anything. With 2 active / 2 used / 0 remaining there is no third project to fall back to, and a statement landed on the wrong ref has no restore point (R-35, R-38, R-43) |
| C3 | No secret, JWT, service-role key or device credential is exposed, copied, logged or requested | No key value appears in any Stage 2 file; secret operations are recorded by **name and digest only**; production secrets are never copied to staging |
| C4 | Preserve the Flutter parent app, Android/Kotlin child app, backend architecture, DB structure and current functionality unless an approved fix requires change | No schema redesign; no table/column removal; patches are additive or ACL/body-only; any client change is a separate patch with its own review |
| C5 | Staging was to be **created only after** the owner approved the proposal — Superseded (history): the shell was created on 2026-10-30 under a direct owner instruction, before [01](01-staging-project-proposal.md)'s checklist was signed ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md)); the creation is **`RATIFIED — 2026-11-02 — OPTION (i)`** (correction C-5; the previously recorded `AWAITING RETROSPECTIVE RATIFICATION` is closed) | [01](01-staging-project-proposal.md) ends in an explicit approval checklist; the checklist records a **retrospective** decision, not a pre-approval, and that decision authorises nothing forward |
| C6 | No patch is applied merely because it is prepared | Every patch has a doc, a pre-state capture, a test list and a rollback; apply is a separate approval (A5) |
| C7 | A test for an unapplied fix is `BLOCKED — FIX NOT APPLIED`, never PASS | See [05](05-validation-plan.md) §2 status vocabulary; no expected result is recorded as observed |
| C8 | Remediation order is fixed: G6 → G3 → E2/F8 → E3/F7/E1/F5 → E4 → E6/E7 → G5 → G2/G7 | §3; any deviation is a recorded decision with owner approval |
| C9 | Single owner account, no second approver | Approvals are single-owner with **compensating evidence** (patch hash, pre/post snapshots, timed window, separate reviewer pass); see [04](04-risks-rollback-approvals.md) §3 |

---

## 2. What Stage 2 is, and what it is not

**Is.** A controlled, staged application of the small set of fixes that are provably correct from captured evidence, plus
the construction of the environment needed to test them, plus an honest register of what remains unfixable without
source or a second project.

**Is not.** A re-audit. It adds no new findings beyond those already in Stage 1, except where executing a step exposes a
new fact; such a fact becomes a new finding with the same labelling discipline.

**Hard limit stated up front.** The repository contains **no app source and no Edge Function source**
(VERIFIED: `supabase/functions/` absent; app trees absent). Consequently:

- 104 of the 105 HTTP-level validation cases cannot run, and app compatibility cannot be verified from source
  (see [05](05-validation-plan.md) §4).
- E6, E7 and four other findings (E8, E9, E10, E12) cannot be remediated in this stage at all, because the fix lives
  in handler code (see [02](02-findings-to-fix-mapping.md) Tier C — 6 findings; §5 coverage arithmetic).
- The one live caller path of every patch runs as `service_role`, so the SQL actor guards are **defence-in-depth, not a
  live fix** (F7 stays OPEN; §5).

A verdict of "Stage 2 complete" is therefore not available. The honest verdict ceiling is **"SQL-tier remediations applied
and validated in staging; Edge-tier and client-tier findings remain open"**.

---

## 3. Sequence (authoritative)

One order. Any earlier statement in a working paper that contradicts this table is superseded (see
[06](06-redteam-resolution.md) J-02, J-17, J-18).

| Step | Gate / patch | Deliverable | Blocking precondition | Approval |
| --- | --- | --- | --- | --- |
| 0 | — | This plan, [01](01-staging-project-proposal.md), [02](02-findings-to-fix-mapping.md), [03](03-patch-S2-P01.md) | none | Owner reads and accepts |
| 1 | **G6-a** empty-shell creation | `parent-control-staging` shell (0 tables / 0 functions / 0 migrations) + `haven-staging` Firebase project | direct owner instruction 2026-10-30 — **creation does NOT require A0** | `EXECUTED — SHELL ONLY` **[DONE]** |
| 2 | Retrospective ratification | Owner ratifies (or refuses) step 1 after the fact; **A2′** records the as-built shell | step 1 done | **`RATIFIED — 2026-11-02 — OPTION (i)`** (recorded in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1; the §3.2 signature fence is **unfilled**, and the ratification grants nothing forward). Correction C-5. |
| 3 | **A0** method approval | G3 method amendment (offline reconstruction from the in-repo catalogue capture + staging equivalence) signed | decision D-01 | A0 — **APPROVED 2026-11-02** (method amended per C-1; the physical fence remains unfilled) |
| 4 | ~~**G3-a** production read-only catalogue capture~~ | **`INOPERATIVE`** — no production read is performed. The baseline is the **2026-10-29/30 in-repo capture** (`docs/stage1/evidence/g1-q1…q10`, `g1-q3b`, `g1-b3b`, `schema-columns.md`, `functions-and-triggers.md`) | none (step removed from the chain) | **A1 is void** under the owner's staging-only absolute (F-5-A / C2b reaffirmed) — see [approval-package-v2 §3.2](approval-package-v2-ratification-and-forward.md). Correction C-2. |
| 5 | **G3-b** offline schema reconstruction | One reviewed `.sql` artefact, kept **outside** the repository | the in-repo baseline capture (step 4 substitute) | read-only over repository files; no write to any project |
| 6 | **G3-b** secret scan of the artefact | Scan for credential shapes/prefixes/base64-hex before it enters the repo; record result | step 5 artefact exists | precondition of A3 |
| 7 | **G3-c** staging schema load | Reconstructed schema applied to `parent-control-staging` in dependency order; restore log | step 6 scanned clean **AND A2′(a) signed and executed AND A3 granted** — **A1 is not a precondition of A3** | **A3 — UNSIGNED. Not executable.** The reconstructed artefact is additionally **NOT LOAD-READY** (0 function bodies of 24 absent, 0 return types captured) |
| 8 | **A2′(b)** settings + Realtime publication verification | staging settings checklist (auth, JWT, Data API) and the four-table publication re-added **after** the tables exist | step 7 loaded | A2′(b) — **UNSIGNED**. Sequence A decision (B-2): the sentinel half (A2′(a)) runs **before** A3; this half runs **after** it |
| 8a | **A2′(a)** environment sentinel | `private.s2_environment` = `staging` written before any schema load, so the load can prove which project it is in | before step 7 | A2′(a) — **UNSIGNED** |
| 9 | **G3-d** equivalence validation | Counts and ACL sets diffed **staging vs the in-repo baseline capture**; every difference accepted | steps 7–8 green | acceptance under A3 |
| 10 | **S2-P01 → P02 → P03** (E2/F8 → E3/F7/E1/F5 → E4) | Patches applied **in that order**, each with pre-state capture, post-check and rollback | step 9 accepted. **P03 is not executable at all**: its read-only production duplicate count needed A1, and A1 is void (C-2) | **A5 — APPROVED 2026-11-02 but NOT EXECUTABLE** (P03 blocked; D-07 aborts P02 unconditionally) |
| 11 | **G5-S** | SQL-runnable validation subset (TE-02, doc 08 `T-01…T-18`, patch tests) evidence | step 10 green | A11 |
| 12 | **G5-E / G5-C** + **E6/E7** decision | 104 HTTP cases and client cases `BLOCKED`; E6/E7 decision record, **no patch authored** | Edge source + deployed functions | `BLOCKED — EDGE SOURCE REQUIRED` |
| 13 | **G2 / G7** | Deferred register entry; Firebase intended for FCM transport only (FCM does not exist) | — | out of Stage 2 (A12) |

**Why the shell precedes G3, and why the load sits inside G3 (resolving the working-paper conflict).** G3's capture half
(step 4) is read-only against production and needs no new project; G3's *validation* half ("restore into a target and
prove equivalence") needs an empty project to restore into, so the shell (step 1, `EXECUTED — SHELL ONLY`) precedes it.
The schema **load is one G3-c step gated by A3** (step 7), not a G6 step: the former `G6-c schema load` was a duplicate of
`G3-c` *and* wrongly consumed the `G3-b` artefact that only exists one step later — that backwards dependency is removed
here. Superseded (history): the old step 1 gated the load under "A0 and A2". Correct gates are now A2′ = as-built
creation/settings record, **A1 = production read-only capture** (step 4), **A3 = staging schema load** (step 7). Creating
the shell required no approval; the A0/A2 package was never signed. The opposite order in
[`stage1/06`](../stage1/06-secrets-and-environments.md) §3 is superseded for Stage 2 only.

**Amendment to the paragraph above (2026-11-02, corrections C-2 and C-3 — S2-EXEC-03 pass).** The sentence "**A1** =
production read-only capture (step 4)" remains the definition of A1, but A1 is now **`INOPERATIVE`**: the owner's
staging-only absolute (F-5-A, reaffirmed as C2b) leaves no authorised production read, so step 4 has been removed from
the A3 precondition chain and the baseline is the in-repo 2026-10-29/30 capture. A3's gate chain is now **A2′(a) + A3**
(the A2′ block is split — sentinel before the load, settings and Realtime publication after it, per the owner's Sequence
A decision on B-2). Where step 4 or the older text refers to a production read of any kind, that read is prohibited, not
merely unapproved.

**Why the E6/E7 decision (step 12) produces no patch.** E6's fix is a handler branch that must refuse pairing when
`PAIRING_HASH_PEPPER` is absent; E7's fix is request metering in the handler. A database-side rate-limit table has no
writer if the handler is not deployed to increment it, which would let the plan record "E7 mitigated" while nothing is
mitigated. Both are marked `BLOCKED — EDGE SOURCE REQUIRED` and are **not** claimed as done
([06](06-redteam-resolution.md) J-11).

---

## 4. Work breakdown

*Sub-headings below are grouped by work package (G6/G3/P01/P02/P03/E6-E7/G5/G2), not by §3 step number; §3 is the
authoritative sequence. The old "Step N — …" labels predate the §3 renumbering.*

### Step 1 — G6: create and configure staging

| ID | Task | Output | Status / Gate |
| --- | --- | --- | --- |
| G6-a | Create the `parent-control-staging` shell — `ap-northeast-2`, Free/NANO, existing org | `EXECUTED — SHELL ONLY` 2026-10-30: ref `dzonzgngwxclhfnvxtvu`, 0 tables / 0 Edge Functions / no migrations ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2). Name and region selectability **RESOLVED by S2-CREATE-01** (both available) — the earlier `NOT VERIFIED` is superseded | `EXECUTED — SHELL ONLY`; **creation did not require A0**; A0/A2 package unsigned |
| G6-b / **A2′(a)** | Create the environment sentinel **before** the schema load | `private.s2_environment` with one row `staging` | `NOT DONE`; sequenced **before** the G3-c load (§3 step 8a) per the owner's **Sequence A** decision on B-2; gate **A2′(a) — UNSIGNED** |
| **A2′(b)** | Verify staging settings parity and re-add the Realtime publication | settings checklist (auth, JWT, Data API) + the four-table `supabase_realtime` publication | `NOT DONE`; sequenced **after** the G3-c load (§3 step 8); gate **A2′(b) — UNSIGNED** |

Superseded (history): the old G6-c `Load the reconstructed schema (G3-b artefact)` and G6-d `Verify the load` are
**removed** — they duplicated G3-c/G3-d (§3 steps 7 and 9) and made step 1 consume the G3-b artefact produced one step
later (a backwards dependency). The schema load is a **single G3-c action gated by A3**.

**Correction to the last sentence of the previous paragraph, and to the §3 step-8 note (2026-11-02, C-3).** The earlier
plan text said "the sentinel follows the load". Under the owner's **Sequence A** decision on blocker B-2, that ordering is
reversed for the sentinel only: **A2′(a) — the `private.s2_environment` sentinel — is created BEFORE the A3 load**, so the
load and every patch can prove which project they are in; **A2′(b) — the settings checklist and the Realtime publication,
which need tables to exist — runs AFTER it**. The A2′ block in
[approval-package-v2 §3.3](approval-package-v2-ratification-and-forward.md) is worded as two separately-timed halves.

**The environment sentinel is a safety control, not schema.** `private.s2_environment` is a one-row, staging-only table
created in G6-b. Every patch block begins by reading it and aborting unless the value is `staging`. It exists in no other
project, so a patch pasted into the wrong SQL Editor tab fails before its first DDL statement. It is excluded from the
G3 parity diff by name. Rationale: [06](06-redteam-resolution.md) J-03 — the dashboard presents two identical editors and
no captured query distinguishes projects by itself.

**One window, not three.** Free projects pause after 7 days without activity (R-30), and no platform backup or PITR
exists to recover one (R-35). The 7-day clock started at creation on **2026-10-30**, so a dated dashboard touch is
required **on or before 2026-11-06** (no UTC start timestamp was recorded — the capture shows local display only).
G6, G3 and G5-S are therefore scheduled as a **single coordinated window**; a pause or a failure inside the window stops
the window rather than rolling into a second one ([04](04-risks-rollback-approvals.md) §2.5).

### Step 2 — G3: baseline capture and restore validation

| ID | Task | Output | Gate |
| --- | --- | --- | --- |
| ~~G3-a~~ | Read-only production catalogue capture (catalogue only, never table data) — **`INOPERATIVE` 2026-11-02**: not run, not runnable | **Substituted baseline:** the 2026-10-29/30 in-repo capture — `docs/stage1/evidence/g1-q1…q10`, `g1-q3b`, `g1-b3b`, `schema-columns.md`, `functions-and-triggers.md` | **A1 — `INOPERATIVE`** (void under F-5-A / C2b; correction C-2) |
| G3-b | Offline DDL reconstruction | One reviewed `.sql` artefact, kept **outside** the repository — built 2026-11-02: **459 active statements, 0 executable functions/triggers/policies** → **NOT LOAD-READY** | read-only; no write |
| G3-b′ | **Secret scan before the artefact enters the repository** | Credential-shape/prefix/base64-hex scan; result recorded — **run 2026-11-02: 0 pattern matches** (a clean scan is not proof that no secret exists) | precondition of A3 |
| G3-c | Apply G3-b to staging in dependency order | Restore log with per-statement result | **A3 — UNSIGNED. Not executable.** |
| G3-d | Equivalence record | Counts and ACL sets compared **staging vs the in-repo baseline capture** (was: "against the G3-a capture"); every difference listed and accepted | A3 |

**Method amendment (A0).** Stage 1's G3 requires `supabase db dump` under Docker and a `pg_dump`-diff no-diff proof;
both are excluded by C1. This plan replaces the **method**, not the objective: the objective stays "a restorable schema
baseline proven equivalent to production". **A0 was approved on 2026-11-02**, and its capture step was subsequently
amended again by correction C-1: the artefact is reconstructed from the **in-repo** Stage 1 catalogue capture, not from a
fresh production read. If
A0 is refused, G3 is marked `BLOCKED — METHOD NOT PERMITTED` and the schema load and every patch step (§3 steps 7 and
10) cannot start, because applying a security fix to a schema that is not
provably equivalent produces evidence that cannot be transferred to production.

**Secret-scan gate.** 24 `private` bodies were never read in Stage 1 and `prosrc` is the one catalogue column that can
carry a pasted literal credential ([08](../stage1/08-test-matrix.md) Q7). The reconstructed artefact is scanned for
credential shapes, key prefixes and long base64/hex literals before it is written into the repository; unmatched hits are
reviewed by hand and the finding is recorded, never silently redacted.

### Step 3 — S2-P01: E2/F8

Prepared and reviewable now: [03-patch-S2-P01.md](03-patch-S2-P01.md),
[`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql). Four statements on two functions. No body change, no data change.
Expected effect is a **latent-route closure**: no deployed caller loses access, because the wrapper is `SECURITY DEFINER`
owned by `postgres` and the Edge tier runs as `service_role`.

### Step 4 — S2-P02: E3/F7/E1/F5

Prepared: [D-e3-f7-e1.md](parts/D-e3-f7-e1.md), [`patches/S2-P02-e3-actor-binding.sql`](patches/S2-P02-e3-actor-binding.sql).
Three captured bodies only. **F7 remains OPEN** after this patch; the guard cannot fire under `service_role`
([06](06-redteam-resolution.md) J-06). The E1 membership check is the part that constrains the live path, because it
binds `p_parent_user_id` rather than `auth.uid()`.

Precondition added by this plan: re-capture the three `prosrc` values **from the staging catalogue** immediately before
apply and store them as the rollback artefact, rather than relying on the Stage 1 capture, which may predate later edits.

### Step 5 — S2-P03: E4

Prepared: [E-e4-session-invariant.md](parts/E-e4-session-invariant.md),
[`patches/S2-P03-e4-session-invariant.sql`](patches/S2-P03-e4-session-invariant.sql). Two halves: a `BEFORE INSERT`
trigger that expires stale `requested` rows under the device advisory lock and raises `P0001`, and a partial unique index
as an invariant backstop.

Preconditions added: (a) **P02 must be applied first** — the trigger mirrors the RPC's expiry/exclusion text and must
mirror the post-P02 body ([06](06-redteam-resolution.md) J-21); (b) a **read-only production duplicate count** is
required before approval, **and needs its own A1 (read-only introspection) grant**, because staging is empty and cannot
exercise the one condition that makes the index fail to
build (J-10); (c) P03's user-visible outcome is a 500 until the Edge handler maps `P0001`/`23505`, so **production
deployment of P03 is blocked on an Edge patch that cannot be written from this repository**.

**Amendment to (b) (2026-11-02, correction C-2).** A1 is `INOPERATIVE` under the owner's staging-only absolute, so the
production duplicate count cannot be authorised by any route that exists today. **P03 is therefore `BLOCKED — PRODUCTION
READ NOT AUTHORISABLE`, not merely "awaiting a grant".** The requirement itself stands: the count is what would show
whether pre-existing `requested` duplicates prevent the partial unique index from building, and no staging-side
substitute can answer it, because staging holds none of production's rows.

### Step 6 — E6/E7: decision only

Deliverable: a decision record naming (a) whether `PAIRING_HASH_PEPPER` is present in production (answerable by
presence/digest, never value), (b) the chosen fail-closed policy, (c) the abuse-control design, and (d) the Edge patch
that would implement them. No SQL, no deployment. Status: `BLOCKED — EDGE SOURCE REQUIRED`.

### Step 7 — G5-S / G5-E

Split is mandatory ([06](06-redteam-resolution.md) J-15). G5-S is the SQL-runnable subset (TE-02, doc 08 `T-01…T-18`,
plus patch-specific tests). G5-E is the 104 HTTP cases and remains `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`. No verdict
may read "G5 passed" without the qualifier.

### Step 8 — G2/G7

Firebase/FCM stays deferred as a *stage objective*. Superseded (history): this line read "No Firebase action of any kind
occurs in Stage 2." That no longer holds — a Firebase project **was created** on 2026-10-30 under the same direct owner
instruction: `haven-staging` / `haven-staging-46822` (Spark, Analytics off, Gemini off)
([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §3). The creation **exceeded the A12 prohibition** in
[04](04-risks-rollback-approvals.md) §3 as originally written (no Firebase action in Stage 2) and was
**`RATIFIED — 2026-11-02 — OPTION (i)`** (recorded in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1; correction
C-5). The prohibition in force is now the amended A12 wording: **"project creation permitted under owner instruction; app
registration, FCM configuration, credentials and settings changes remain prohibited."** **A12 itself is unsigned**, and the
ratification grants nothing forward. No Firebase app, credential, FCM configuration or
setting change occurred; **FCM does not exist**. Firebase is intended for FCM transport only; Firebase Auth, Firestore
and Cloud Functions are not part of the approved architecture.

---

## 5. Verdict ceiling (read before any status report)

| Claim | Available after Stage 2? | Why |
| --- | --- | --- |
| "E2/F8 closed" | **Yes**, if P01 applies and post-checks match | ACL is directly observable; latent route only |
| "E1 closed" | **Yes for the RPC argument**, no for the Edge tier | Membership check binds the argument; handler still chooses it |
| "E3/F7 closed" | **No** | `auth.uid()` is NULL for every live caller; guard is inert |
| "E4 closed" | **No** | Invariant enforced in SQL, but client sees 500 until the Edge mapping exists |
| "E6/E7 closed" | **No** | Fix lives in handler code that is not in this repository |
| "G5 passed" | **No** | 104/105 HTTP cases blocked |
| "App compatible" | **No** | No app source; APK-level smoke not performed |
| "Production ready" | **No** | Production release gate ([04](04-risks-rollback-approvals.md) §4) is unmet by construction |

---

## 6. Deliverables of this planning turn

| File | Content |
| --- | --- |
| [00](00-stage2-execution-plan.md) | This plan: constraints, sequence, WBS, verdict ceiling, decision log |
| [01](01-staging-project-proposal.md) | Staging name/region/plan/config, replication scope, cost/limits, isolation, approval checklist |
| [02](02-findings-to-fix-mapping.md) | E1–E14 and F1–F8 → patch/step/status, fixability tiers |
| [03](03-patch-S2-P01.md) | First reviewable patch, complete |
| [04](04-risks-rollback-approvals.md) | Consolidated risks, rollback, approvals **A0–A3, A5–A13** (no A4 exists in the plan of record; A4 appears only in the working papers), production gate, change record |
| [05](05-validation-plan.md) | G5-S / G5-E split, test principals, expected results, evidence format |
| [06](06-redteam-resolution.md) | J-01…J-22 dispositions and corrections to the working papers |
| [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql) | Hardened patch: sentinel, GRANT-before-REVOKE, in-file rollback |
| [`patches/S2-P02-e3-actor-binding.sql`](patches/S2-P02-e3-actor-binding.sql) | Prepared, not applied; sentinel included |
| [`patches/S2-P03-e4-session-invariant.sql`](patches/S2-P03-e4-session-invariant.sql) | Prepared, not applied; sentinel included |

---

## 7. Decision log

| ID | Decision | Reason | Owner action |
| --- | --- | --- | --- |
| D-01 | G3 method amended to dashboard catalogue capture + offline reconstruction + staging equivalence | CLI and Docker are excluded (C1); the original method is unexecutable | **Sign A0** |
| D-02 | Step order is G6 then G3; G6-a creates only the shell, G3 restores into it | Only executable order; supersedes [`stage1/06`](../stage1/06-secrets-and-environments.md) §3 for Stage 2 | Acknowledge |
| D-03 | Staging reproduces the F1 and F8 defects, then patches them | A hardened creation makes the E2/TE-02 baseline unreal | Acknowledge |
| D-04 | P01 is labelled latent-route closure, not a live fix | Wrapper is definer-owned and Edge runs as `service_role` | Acknowledge |
| D-05 | F7 is downgraded to "latent, not remediable in the database" | Guard cannot fire for any live caller | **Confirm** |
| D-06 | P03 is applied in staging only; production is blocked on an Edge mapping | Otherwise a normal double-request returns 500 | Acknowledge |
| D-07 | E6/E7 produce a decision, not a patch | A DB-only rate limit has no writer | Acknowledge |
| D-08 | G5 splits into G5-S (runnable) and G5-E (blocked) | 104/105 cases need deployed functions | Acknowledge |
| D-09 | Staging-only table `private.s2_environment` as the wrong-project sentinel | Dashboard cannot otherwise distinguish projects | Acknowledge |
| D-10 | No verdict may read "G5 passed" or "production ready" | §5 | Acknowledge |
| D-11 | Edge source recovery is a prerequisite for the E6/E7 decision (§3 step 12) and G5-E, and is not in this stage | Repository has no function source | **Decide who exports** |
| D-12 | Project-slot ceiling is a hard constraint: **2 active Free projects / 2 used / 0 remaining** — staging (`parent-control-staging`) consumed the last slot; **never pause or delete production to free a slot** | Official plan terms; org list shows 2 of 2 used. Superseded (history): the pre-creation state read "2 active, 1 used, production holds the other slot" | **Confirmed 2026-10-30** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.4; earlier readiness [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) §2) |

---

## 8. Stop conditions for the whole stage

Abort the step, record, and do not "finish the window" if any of the following occurs:

1. The sentinel is absent or does not return `staging`.
2. A SQL Editor session cannot be shown to target staging.
3. Any pre-state capture differs from the Stage 1 evidence in a way not already recorded as drift.
4. A patch statement fails, or a post-check does not match its expected table.
5. A legitimate `service_role` path fails where it succeeded before.
6. Any production row, credential or secret is observed in staging, or vice versa.
7. Any request to exceed the approval matrix, to run a patch without its doc, or to record an expected result as observed.

---

## 9. S2-DOC-02 addendum (2026-11-02)

This addendum is a **documentation correction only**. It records what was changed in this plan to restore truth against
the creation record [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md). It is **not** evidence of any operational
action: no SQL was run, no schema/sentinel/secrets were configured, no app was registered, no Edge Function was deployed,
and production was not touched. Approvals below are recorded as **decisions to be signed**, never as signed.

Corrected in this file:

| FX | What was fixed | Where |
| --- | --- | --- |
| FX-01 | Status block replaced: G6-a `EXECUTED — SHELL ONLY` (2026-10-30, direct owner instruction, A0/A2 unsigned); G6-b/c/d `NOT DONE`; no SQL/secret/deployment; production untouched; "authorises nothing by itself" retained | §3 header block |
| FX-07 | §3 authoritative sequence renumbered into shell-creation[DONE] → ratification → A0 → A1 capture → reconstruct → secret scan → A3 load → sentinel+settings (A2′) → equivalence → A5 patches → G5-S → G5-E/G5-C blocked; the duplicate G6-c/G3-c schema-load item and the step-1-consumes-step-2-artefact backwards dependency removed | §3 table + rationale |
| FX-08 | Gates fixed: A1 gates the production read-only capture, A3 gates the staging load (was wrongly under "A0 and A2"); creation shown as **not** requiring A0 | §3 table; §4 G6/G3 tables |
| FX-03/04 | Slot arithmetic corrected to **2 active / 2 used / 0 remaining**; name-availability and region-selectability marked **RESOLVED by S2-CREATE-01** (was `NOT VERIFIED`); auto-pause clock start 2026-10-30 / touch deadline 2026-11-06 added; C5 reconciled | D-12; §4 G6-a; "One window" note; C5 |
| FX-02 | "No Firebase action of any kind occurs in Stage 2" reconciled: a Firebase project **was** created 2026-10-30, exceeding the A12 prohibition in 04 §3, `AWAITING RETROSPECTIVE RATIFICATION`; no app/credential/FCM/setting change | §4 Step 8 |
| FX-11 | "A0–A13" → "A0–A3, A5–A13 (no A4 in the plan of record)"; "E6, E7 and nine other findings … Tier 3" → Tier C, four other findings (E8/E9/E10/E12); F5 added to the C8 order; A1 added to the P03 preconditions | §6 table; §2 bullet; C8; §4 P03 |
| **FX-18** | The empty-shell premise is qualified: staging Auth prints `Total: 10 users (estimated)` over an empty grid, so "`auth.users` is empty" is `NOT VERIFIED` and is made the **first statement of the A3 window**, with a non-zero answer stopping the load. **Owner decision B-3 (2026-11-02, option A) confirms the count belongs inside A3's scope, not inside A1's and not outside any approval — and A3 is unsigned, so the count remains unauthorised and has not been run** (corrections C-2/C-4) | §1 C2b; [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3; [05](05-validation-plan.md) glossary; [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4 |
| **C2b** | Owner scope constraint added as a standing constraint: Supabase work targets `dzonzgngwxclhfnvxtvu` **only** — production is not a fallback, a convenience comparison, or a place to check a setting | §1 table row C2b; risk **R-43** in [04](04-risks-rollback-approvals.md) §1 |
| **S2-INSP-03** | Read-only re-confirmation of both shells at 2026-11-02T07:16Z: `Healthy` / unpaused, 0 tables, `No migrations`, `No backups`, 0 Edge Functions, slots 2/2/0, usage meters unchanged, Firebase zero apps and zero enabled products; screenshots still unavailable (`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`) and the Firebase plan page redirects, so Spark stays `NOT VERIFIED` this pass | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) |

Still open / unchanged (not correctable from documentation):

- All twelve defects **D-01…D-12 remain OPEN**; patches **S2-P01/P02/P03 are unchanged and unapplied**; none is fixed.
  D-01, D-03 and D-05 have had their **document text** corrected (documentation-only; SQL hashes unchanged) and stay
  `OPEN` pending re-check or a patch-file revision.
- **A0 has never been approved by anyone**; the A0/A2 package is unsigned; the 2026-10-30 creation awaits explicit
  retrospective ratification. No approval is inferred from this addendum.
  *(Superseded as of the S2-EXEC-03 pass, 2026-11-02 — corrections C-1/C-5: A0 is **APPROVED as a recorded decision**
  with the method amended to offline reconstruction from the in-repo Stage 1 capture, the physical fence still unfilled,
  and the creation **RATIFIED — option (i)**, which grants no forward permission. The sentence above is the state as
  this addendum recorded it; the signature blocks are still blank and nothing here is an approval.)*
- Schema, sentinel, secrets, Firebase apps/credentials and Edge Functions are **NOT CREATED**; G5-E/G5-C remain
  `BLOCKED — EDGE SOURCE REQUIRED`.
- Production `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) is **unmodified** — no setting changed, no statement run, no
  value read or copied. Qualification for accuracy's sake (R-41): one production page was opened **read-only** on
  2026-11-02 (Auth → Users aggregate total) during the re-confirmation, before the C2b constraint was issued; it is
  disclosed in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3 and is not repeated under C2b.
