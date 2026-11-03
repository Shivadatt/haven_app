# S2-REVIEW-02 — independent audit of the A0/A2 approval package

**Record ID:** S2-REVIEW-02
**Date:** 2026-10-30
**Type:** documentation-only audit. No operational action.
**Status of Stage 2:** `PROPOSED — NOT STARTED`. No project exists. No SQL has run. No patch has been applied.

**VERDICT: `NOT READY — CORRECTIONS REQUIRED`.**

Six corrections are required before the owner signs A0 or A2 (§9). Two of them are safety-relevant: the A2
signature does not cover two of the four actions its own §3.2 authorises, and the execution plan gates a schema load
under A0+A2 while three other pages say that load is A3. The remaining four are record-integrity defects in documents
the package cites as evidence.

No item in U-01…U-16 blocks the signature itself. They block A5 and A2 *execution*, and are correctly deferred.

---

## 1. Scope, evidence base and method

### 1.1 Documents reviewed

| Document | Role in this audit |
| --- | --- |
| [00](00-stage2-execution-plan.md) | Sequence, work breakdown, stop conditions, decision log |
| [01](01-staging-project-proposal.md) | Project parameters, cost, isolation, approval checklist |
| [02](02-findings-to-fix-mapping.md) | Findings, tiers, coverage arithmetic |
| [04](04-risks-rollback-approvals.md) | Risk register, rollback, approval matrix |
| [05](05-validation-plan.md) | G5-S/G5-E split, coverage arithmetic |
| [06](06-redteam-resolution.md) | Red-team dispositions |
| [README](README.md) | Index and status table |
| [CHANGELOG](CHANGELOG.md) | Record of the S2-DOC-01 pass |
| [patch-defects-before-a5](patch-defects-before-a5.md) | D-01…D-12 |
| [approval-package-a0-a2](approval-package-a0-a2.md) | **The document under review** |
| [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md), [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md), [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) | Evidence the package cites |
| [03](03-patch-S2-P01.md), `patches/*.sql` | Read only to test CHANGELOG claims and the patch gate |

Stage 1 was used as the authoritative baseline, specifically
[`stage1/00-status-register.md`](../stage1/00-status-register.md):29,73 and
[`stage1/evidence/g1-b3b-20261029.json`](../stage1/evidence/g1-b3b-20261029.json) (14 captured bodies).
No Stage 1 fact was overridden and no uncertainty was resolved by assumption.

### 1.2 How the review was performed

Ten disjoint review passes were run over separate document sets and then every HIGH finding was re-verified by direct
read of the cited lines. Where a pass and the text disagreed, the text won. The only commands executed were local,
read-only file inspection: `git status`/`git log`, `sha256sum` on the three patch files, and a JSON parse of the
Stage 1 evidence file. Nothing touched Supabase, Firebase, a database, a network endpoint or a browser.

### 1.3 What this audit did not do

No dashboard action; no project created, paused or deleted; no SQL, DDL or DML; no patch applied or modified; no secret
read or described; no CLI, REST, direct API, DevTools or hidden endpoint used against any platform; no Edge deployment;
no Firebase action; no production change. **No document other than this file was edited** — every correction below is
a proposal for the owner. This audit made no browser capture, so it carries no screenshot and no accessibility-tree
snapshot of its own.

### 1.4 Labels

`VERIFIED` — observed in a cited artefact. `INFERRED` — reasoned from verified facts. `PROPOSED — NOT APPLIED` —
written but not executed. `BLOCKED — <reason>` — cannot proceed. `NOT VERIFIED` — never observed. Nothing in this file
is a test result.

---

## 2. A0/A2 readiness verdict

```text
NOT READY — CORRECTIONS REQUIRED
```

**Why not `READY WITH RECORDED LIMITATIONS`.** Recorded limitations are acceptable when they are *known and disclosed*:
the last project slot, the 7-day pause, no backup, no screenshots. Those are all disclosed and consistent, and they do
not block a signature. What blocks it is different in kind — the package is **not internally consistent about what the
signature authorises**. Specifically:

1. **A2 §3.2 authorises two actions its own signature and its own exclusion list do not** (§3.2 items 3 and 4 vs
   §3.3 and §3.4). Signing would produce an approval whose scope is ambiguous at exactly the point where a later
   operator would rely on it. This is the single defect that makes the package unsafe to present as-is.
2. **The plan of record gates a schema load under A0+A2** ([00](00-stage2-execution-plan.md):71), while
   [approval-package](approval-package-a0-a2.md):91, [00](00-stage2-execution-plan.md):101 and
   [01](01-staging-project-proposal.md):174 all say the load is A3. Two mutually exclusive readings of the same
   approval exist in the same document set.
3. **The change log asserts a correction that was not made** ([CHANGELOG](CHANGELOG.md):43). The owner is being asked
   to sign on the strength of a record that is wrong about its own contents.

None of these is a reason to abandon the package. All six corrections in §9 are editorial and small. But a signature is
the one artefact that cannot be repaired by a later documentation pass, so the defects must be fixed first.

---

## 3. Boundary validation — A0 and A2

| # | Test | Result | Evidence |
| --- | --- | --- | --- |
| B-1 | A0 authorises **only** the G3 method, not an objective change | **PASS with caveat** | [pkg](approval-package-a0-a2.md):41 keeps the objective; §2.2 list is a method. Caveat: signature says "for staging only" while step 1 reads production (X-04) |
| B-2 | A2 authorises **only** one separate staging project plus explicitly listed G6 actions | **FAIL** | §3.2 item 3 (settings) and item 4 (fresh secrets) are not in the signature (X-01, X-02) |
| B-3 | A0 does not imply A2 | **PASS** | pkg:72, §5:156–159 |
| B-4 | A2 does not imply A3 or A5 | **PASS in the package / FAIL in the plan of record** | pkg:91, 108, 120; but [00](00-stage2-execution-plan.md):71 puts G6-c under A0+A2 (X-03) |
| B-5 | Neither grants production modification | **PASS on its face; wording defect** | pkg:73 "does not authorise any production write"; but "for staging only" plus a production read in step 1 leaves the production *read* authority unstated (X-04) |
| B-6 | Neither grants Firebase, Edge, secret **values**, or client release | **PASS for A0 / FAIL for A2 on secrets** | pkg:107, 121 vs §3.2 item 4 (X-01). Firebase, Edge and client exclusions are clean |
| B-7 | Signature text matches the approval matrix ([04](04-risks-rollback-approvals.md):148) and the execution plan | **FAIL** | Signature matches [04](04-risks-rollback-approvals.md):148. §3.2 does not. [00](00-stage2-execution-plan.md):100 gates G6-b settings at A2, [04](04-risks-rollback-approvals.md):148 does not mention settings, and the signature does not either — three documents, three scopes |
| B-8 | Staging is separate from production | **PASS** | Distinct name and ref ([01](01-staging-project-proposal.md):156); sentinel ([00](00-stage2-execution-plan.md):104–108); no production ref in staging |
| B-9 | No production data or credentials are copied | **PASS on copying; FAIL on approval class** | pkg:94, 109, 121 all forbid copying. Item 4 authorises *creating* fresh secrets, which is not a copy but is A9 territory ([04](04-risks-rollback-approvals.md):154) |

**Boundary conclusion.** B-2, B-7 and B-9 fail, and B-4 fails in the plan of record. All four failures reduce to two
edits: narrow or restate §3.2, and correct the step table. Both are specified in §9.

---

## 4. U-01…U-16 gate classification

Exactly one status per item, from the permitted set. "Before signing?" answers whether the item must be resolved to
sign A0 or A2.

| # | Item | Classification | Stops | Before signing? | Reason |
| --- | --- | --- | --- | --- | --- |
| U-01 | P01 pre-check 0.4 row count ([D-01](patch-defects-before-a5.md)) | **BLOCKS A5** | P01 apply | **No** | Document correction only; no effect on the A0 method or the A2 shell |
| U-02 | P01 commits before its post-check is read (D-02) | **BLOCKS A5** | P01 apply | **No** | Execution procedure, not a signature parameter |
| U-03 | P01 T3 cannot distinguish pre from post (D-03) | **BLOCKS A5** | P01 evidence quality | **No** | A no-op control produces untrustworthy evidence, but nothing at A2 depends on it |
| U-04 | P02 has no in-file rollback (D-05) | **BLOCKS A5** | P02 apply | **No** | Must be solved before the window, not before the signature |
| U-05 | P02 post-checks are advisory (D-06) | **BLOCKS A5** | P02 apply | **No** | Same |
| U-06 | P02 ships its gate commented out (D-07) | **BLOCKS A5** | Hash integrity at A5 | **No** | Same |
| U-07 | P03 has no in-file rollback and omits both preconditions (D-10, D-11) | **BLOCKS A5** | P03 apply | **No** | Same |
| U-08 | Staging name availability | **BLOCKS A2 EXECUTION** | G6-a | **No — open at signature by design** | The signature explicitly accepts `NOT VERIFIED` and mandates stop-and-return (pkg:118–120) |
| U-09 | Region-picker availability | **BLOCKS A2 EXECUTION** | G6-a | **No — open at signature by design** | Same clause; region affects latency, not schema parity (R-33) |
| U-10 | The single 7-day window has no start date | **BLOCKS A2 EXECUTION** | The window | **No — but the owner must name the date when executing** | No start date exists anywhere in the document set (grep: zero hits for a dated window). Signature acknowledges the window but not a date |
| U-11 | Reviewer pass in a single-owner organisation | **BLOCKS A5** (also A6) | A5, A6 | **No** | R-16 already defines a timed self-review as the compensating control; naming the person can wait for the change record |
| U-12 | Who exports Edge source | **BLOCKS LATER STAGE** | Steps 6, G5-E | **No** | Out of Stage 2 scope by C1 |
| U-13 | `PAIRING_HASH_PEPPER` presence (presence only) | **BLOCKS LATER STAGE** | A future deploy | **No** | Affects no Stage 2 step |
| U-14 | P03 accepted as staging-only with a 500 for a double request | **ACCEPTED WITH RECORDED LIMITATION** | E4 verdict | **No** | Already recorded at [02](02-findings-to-fix-mapping.md):31, [04](04-risks-rollback-approvals.md):44, R-20. The owner accepts a known, bounded deviation |
| U-15 | Log-query headroom 44.8/100 GB and rising | **ACCEPTED WITH RECORDED LIMITATION** | The whole stage | **No** | The control is discipline plus an 80 GB stop line (R-15); there is no approval that changes the number |
| U-16 | Firebase ownership across three identities | **BLOCKS LATER STAGE** | G2/G7/A12 | **No** | No Firebase action occurs in Stage 2 |

**Distribution:** 8 × `BLOCKS A5` (U-01…U-07, U-11) · 3 × `BLOCKS A2 EXECUTION` (U-08…U-10) · 3 ×
`BLOCKS LATER STAGE` (U-12, U-13, U-16) · 2 × `ACCEPTED WITH RECORDED LIMITATION` (U-14, U-15) · 0 × `BLOCKS A0` ·
0 × `BLOCKS A2` · 0 × `BLOCKS A3`.

**Why no U item blocks A0, A2 or A3.** A0 and A2 are signature-level approvals. Their blockers are contradictions in
the text being signed (§9), not unresolved technical unknowns. A3's preconditions are A0 in writing, A1 for the
read-only capture, and an A3 approval — none of which is a U item. U-08…U-10 are visible at signature and explicitly
accepted in the signature text, which is exactly the correct design: they must not be allowed to block the signature,
and they must stop execution cold if they fail.

---

## 5. Findings mapping reconciliation

| # | Test | Result | Evidence |
| --- | --- | --- | --- |
| F-1 | 14 E + 8 F + 1 X = 23 | **PASS** | [02](02-findings-to-fix-mapping.md):96 reconciles 6+1+4+6+5+1 = 23; §2 rows are E1–E14, §3 rows F1–F8 + X |
| F-2 | E3 counted once | **PASS** | Only in the D bucket ([02](02-findings-to-fix-mapping.md):85); its Edge residual is named in the honest-limit column, not as a second row |
| F-3 | F4 has its own category | **PASS** | Tier E, own row ([02](02-findings-to-fix-mapping.md):86); plan-forced, not a Stage 2 test |
| F-4 | E11 is the only body-capture blocker | **PASS as whole-finding claim / FAIL as written** | [02](02-findings-to-fix-mapping.md):38 says "the **only** finding blocked on a missing capture", but E14's residual is `B (body, rest)` and its own honest limit says "the residual is body capture" ([02](02-findings-to-fix-mapping.md):41). Both statements cannot be true |
| F-5 | E13, F1, F3, F6 are not capture-blocked | **PASS** | [02](02-findings-to-fix-mapping.md):40, 49, 51, 54; qualifiers `(design)`, `(ownership)`, `(policy)`, `(backlog)` |
| F-6 | F3's trigger body was captured in Stage 1 | **PASS** | [02](02-findings-to-fix-mapping.md):51 states it, cites the capture, and preserves status `BACKLOG` with "not fixed, not started" |
| F-7 | No finding is marked fixed on a prediction | **FAIL** | [02](02-findings-to-fix-mapping.md):41 records E14's **Status now** as `PARTIAL` with "Guard added to the three captured bodies". [02](02-findings-to-fix-mapping.md):3 says "No finding below has been remediated". The status column is a *now* column; `PARTIAL` is E14's *predicted* post-Stage-2 state |

**Findings conclusion.** The arithmetic, tiers and F3 correction are sound. Two wording defects remain (F-4, F-7), both
in E14's row. F-7 matters more than its size: a reader of [02](02-findings-to-fix-mapping.md):41 would conclude a
remediation has already happened, which is the one claim this programme must never make without evidence.

---

## 6. Risk and execution-window reconciliation

| # | Test | Result | Evidence |
| --- | --- | --- | --- |
| K-1 | R-09/R-31: 2 active projects, 1 used, staging is the last slot | **PASS** | [04](04-risks-rollback-approvals.md):33, 55; [00](00-stage2-execution-plan.md):230; [01](01-staging-project-proposal.md):131; [pkg](approval-package-a0-a2.md):21–23; [06](06-redteam-resolution.md):J-19; [README](README.md):44. One stale evidence row (X-08) |
| K-2 | R-30: 7-day auto-pause, one coordinated window | **PASS** | [04](04-risks-rollback-approvals.md):54 and §2.5:122–129; [00](00-stage2-execution-plan.md):110–113. One stale report statement (X-12) |
| K-3 | R-27: no screenshot and no platform-audit claim | **PASS** | [04](04-risks-rollback-approvals.md):51; [README](README.md):70; [pkg](approval-package-a0-a2.md):10. One missing label (X-10) |
| K-4 | R-15: 44.8/100 GB and the 80 GB stop line | **PASS where updated / FAIL in 01** | [04](04-risks-rollback-approvals.md):39, 199 and [01](01-staging-project-proposal.md):124 carry 44.8 and 80 GB; [01](01-staging-project-proposal.md):123,126 carry stale 0.17/0.12 labelled as a 2026-10-30 re-read (X-13). The 80 GB line is recorded only at [04](04-risks-rollback-approvals.md):199 — it is absent from the stage's own stop conditions ([00](00-stage2-execution-plan.md):236–245) |
| K-5 | R-34: F4 cannot be tested on Free | **PASS** | [04](04-risks-rollback-approvals.md):58; [02](02-findings-to-fix-mapping.md):52; [README](README.md):67; [01](01-staging-project-proposal.md):145 removes it from scope |
| K-6 | R-35: no backup or PITR; restore means rebuild | **PASS** | [04](04-risks-rollback-approvals.md):59; [pkg](approval-package-a0-a2.md):61; [README](README.md):68; [01](01-staging-project-proposal.md):143 |
| K-7 | G6 + G3 + G5-S fit one 7-day period | **NOT VERIFIED — and as sequenced, not evidenced as feasible** | See below |
| K-8 | A start date exists | **Not present — owner decision** | Zero dated window starts in 00–06 or the package. U-10 records it as an execution blocker |

### 6.1 The window question, answered honestly

The package asks the owner to accept "G6 + G3 + G5-S inside one 7-day active period" ([pkg](approval-package-a0-a2.md):95,
118). Whether that is feasible is not a documentation question, and no evidence in the repository answers it. Two facts do
bear on it:

1. **The reconstruction is the heavy half, and it does not need the project.** [00](00-stage2-execution-plan.md):80–84
   says so explicitly: "G3's capture half is read-only against production and needs no new project". G3-a and G3-b
   therefore can and should be completed and reviewed **before** G6-a. As currently sequenced, all of G3 sits after the
   project is created, so the 7-day clock carries the entire capture, reconstruction, secret scan, apply and equivalence
   diff — plus 38 SQL validation cases.
2. **No rehearsal exists.** No baseline artefact has ever been built, so the time estimate is `INFERRED` from object
   counts (19 tables, 38 functions, 21 policies, 137 constraints, 62 indexes), not measured.

**Recommendation, for the owner:** treat the single-window rule as a budget, not a formality. Complete G3-a (under A1)
and G3-b (offline) before A2 executes, and let the 7-day window cover G6-a, G6-b, G3-c, G3-d and G5-S only. This is
recorded as W-01 because it changes execution planning, not the text the owner signs. It does not change the verdict.

---

## 7. Patch defect gate

| # | Test | Result | Evidence |
| --- | --- | --- | --- |
| P-1 | P01 remains blocked | **PASS** | [patch-defects](patch-defects-before-a5.md):24 — 3 × S1 (D-01…D-03), 1 × S3 (D-04) |
| P-2 | P02 remains blocked until rollback, assertions and hash requirements are met | **PASS** | [patch-defects](patch-defects-before-a5.md):25 — 4 × S1 (D-05…D-08), plus D-09 |
| P-3 | P03 remains blocked until rollback and both preconditions are recorded | **PASS** | [patch-defects](patch-defects-before-a5.md):26 — 2 × S1 (D-10, D-11), plus D-12 |
| P-4 | No patch becomes A5-ready from A0/A2 | **PASS** | [pkg](approval-package-a0-a2.md):130, 163; [patch-defects](patch-defects-before-a5.md):227. A5 needs the S1 corrections **and** reviewed S3 revisions with new hashes |
| P-5 | SQL hashes and statuses unchanged | **PASS with a provenance limitation** | No SQL file was edited by S2-DOC-01 ([CHANGELOG](CHANGELOG.md):47). Point-in-time SHA-256 computed by this audit: P01 `1edad404…7be51`, P02 `01403cd7…8c67`, P03 `8f92cc0f…0ecd4` (full values in §7.1) |
| P-6 | Every patch still reads `PROPOSED — NOT APPLIED` | **PASS** | [README](README.md):47–49; [00](00-stage2-execution-plan.md):137; patch headers |

### 7.1 Two notes the gate needs

- **No patch hash is recorded anywhere before A5.** The A5 evidence model requires "patch hash" as compensating
  evidence ([04](04-risks-rollback-approvals.md):150), but no document records a pre-approval hash. The first hash taken
  at A5 would therefore have nothing to be compared against. The three values below were computed by this audit as a
  baseline; they should be written into the change record **before** any apply, and the file re-hashed at apply time:

  ```text
  1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51  S2-P01-e2-f8.sql
  01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67  S2-P02-e3-actor-binding.sql
  8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4  S2-P03-e4-session-invariant.sql
  ```

- **The repository has no commits** (`git log` → "does not have any commits yet"; `docs/stage2/` is untracked). No
  "unchanged since review" claim can rest on version history. The hash is the only provenance mechanism available, which
  makes recording it now more important, not less.

- **D-05 overstates its case.** It says the rollback text "exists **nowhere in the repository**"
  ([patch-defects](patch-defects-before-a5.md):108). The three pre-P02 bodies *are* in
  [`stage1/evidence/g1-b3b-20261029.json`](../stage1/evidence/g1-b3b-20261029.json) — `private.request_device_recovery`,
  `public.request_remote_session` and `private.unlink_child` are captured entries 11, 13 and 14. They are a starting
  point, not an approved rollback: the rollback must be re-captured from staging and reviewed. The conclusion (P02
  blocked) stands; the reasoning needs correcting before A5 (W-11).

---

## 8. Cross-document contradictions

Severity: **HIGH** = changes what an approval authorises, or makes a safety step ambiguous. **MEDIUM** = a factual
claim is wrong or two documents disagree visibly. **LOW** = navigation, labels, or a stale snapshot.

| ID | Sev | Where | Contradiction | Disposition |
| --- | --- | --- | --- | --- |
| X-01 | **HIGH** | [pkg](approval-package-a0-a2.md):103 vs :107 vs [04](04-risks-rollback-approvals.md):154 | §3.2 item 4 authorises "Creating fresh staging secrets"; §3.3 says A2 does **not** authorise A9 (secrets); the signature makes no mention of secrets; the matrix assigns secrets to A9, owner only | C-01 |
| X-02 | **HIGH** | [pkg](approval-package-a0-a2.md):101 vs :118 and [04](04-risks-rollback-approvals.md):148 vs [00](00-stage2-execution-plan.md):100, 119, 122 | §3.2 item 3 mirrors "auth, JWT, Data API … and Realtime membership"; the signature covers only "an empty shell plus the one-row sentinel"; 00 gates G6-b settings at A2; 04's A2 row omits settings; and 00 lists `pg_publication_tables` as a G3-a capture and a G3-d diff item, so configuring Realtime membership at A2 pre-empts the baseline it is supposed to be compared against | C-01, C-02 |
| X-03 | **HIGH** | [00](00-stage2-execution-plan.md):71 vs :101, :121; [pkg](approval-package-a0-a2.md):91; [01](01-staging-project-proposal.md):174 | Step 1's approval is "A0 and A2" and its deliverables include "G6-c schema load", whose own row is gated A3. G6-c (00:101) also duplicates G3-c (00:121) and consumes the G3-b artefact produced in step 2 — a dependency inversion inside the authoritative sequence | C-02 |
| X-04 | **HIGH** | [pkg](approval-package-a0-a2.md):71 vs :44, :72 | A0's signature says the method is approved "for staging only", but the method's step 1 is a read-only catalogue capture **in the production SQL Editor**. A1 (read-only introspection) is absent from the non-authorisation list, so A0 can be read as authorising production reading | C-03 |
| X-05 | **MEDIUM** | [02](02-findings-to-fix-mapping.md):41 vs :3 vs :38 | E14's Status-now is `PARTIAL` with "Guard added", contradicting "No finding below has been remediated"; and E11 is called "the **only** finding blocked on a missing capture" while E14's residual is capture-bound | C-04 |
| X-06 | **MEDIUM** | [CHANGELOG](CHANGELOG.md):43 vs [03](03-patch-S2-P01.md):135 and [patch-defects](patch-defects-before-a5.md):35 | Correction #11 claims "P01 pre-check 0.4 expects 2 rows per function, not 1". The document still reads "one row per function"; D-01 and U-01 remain open. The changelog records an edit that was not made | C-05 |
| X-07 | **MEDIUM** | [CHANGELOG](CHANGELOG.md):17 vs [00](00-stage2-execution-plan.md):230 | "D-12 closed as VERIFIED" vs "**Confirmed 2026-10-30**". Both are stronger than the evidence label used elsewhere, and they are not the same claim | C-05 |
| X-08 | **MEDIUM** | [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):95 vs [pkg](approval-package-a0-a2.md):23 and [01](01-staging-project-proposal.md):131 | The status table row reads "Creating staging needs a paid upgrade — `VERIFIED` — no upgrade prompt". The claim and the status are inverted: the evidence supports "**no** paid upgrade needed" | C-06 |
| X-09 | **MEDIUM** | [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):49–50 vs :97 and the addendum :113–118 | "The commonly cited 2-project Free ceiling remains `INFERRED`" sits 47 lines above a status table that says it is `VERIFIED` in the addendum, with no forward reference | C-06 |
| X-10 | **MEDIUM** | [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md):1–8 vs [pkg](approval-package-a0-a2.md):10 and [README](README.md):29 | INSP-02 carries no `SCREENSHOT EVIDENCE: NOT VERIFIED` header, although the package asserts the label holds "throughout" | C-06 |
| X-11 | **MEDIUM** | [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md):195–216 vs [02](02-findings-to-fix-mapping.md):83–92 | §9 still quotes the pre-correction row `4 (E11, E13, F1, F3, F6-minor)` and says "No downstream document repeats the count". Both are now false: 02 has been corrected and does carry the count | C-06 |
| X-12 | **MEDIUM** | [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md):222–223 vs [04](04-risks-rollback-approvals.md):54 | "R-30 (new) … Not currently in the risk register" — R-30 is now registered, with a recovery procedure | C-06 |
| X-13 | **MEDIUM** | [01](01-staging-project-proposal.md):116, 123, 126 vs [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):76, 80; [pkg](approval-package-a0-a2.md):25 | 01 presents a "re-read 2026-10-30" usage table containing log ingestion 0.17 and egress 0.12. The capture behind it records 0.20 and 0.14. The package repeats egress 0.12 | W-03 |
| X-14 | **MEDIUM** | [00](00-stage2-execution-plan.md):130; [04](04-risks-rollback-approvals.md):42 vs [stage1/00](../stage1/00-status-register.md):29, 73 | "24 `private` bodies were never read" mislabels the total. Stage 1 records 11 of 13 `private` twin implementations unread and **24 unread bodies in total**. `R-13`'s "11 … private or 12 … public" should be reconciled with the same total | W-05 |
| X-15 | **MEDIUM** | [05](05-validation-plan.md):181, 187 | "21" patch cases but the listed sets sum to 20 (5 + 9 + 6); "39" SQL-runnable cases should be 38 (20 + 19 − 1) | W-02 |
| X-16 | **MEDIUM** | [00](00-stage2-execution-plan.md):76 | Step 6's approval reads "A0 decision only". A0 is the G3 method; the E6/E7 decision is D-07 and needs no patch or approval class | W-04 |
| X-17 | **MEDIUM** | [00](00-stage2-execution-plan.md):77 | Step 7 (G5-S) is gated "A11" only, but G5-S runs the patches and therefore needs the A5 window; A11 covers fixtures | W-04 |
| X-18 | **LOW** | [06](06-redteam-resolution.md):75 | Literal placeholder "B §?..." in the correction table | W-06 |
| X-19 | **LOW** | [00](00-stage2-execution-plan.md):206; [README](README.md):19 | Both advertise "A0–A13", but the matrix has no A4. A4 exists in the working papers as a CLI migration-repair approval that Stage 2 forbids | W-07 |
| X-20 | **LOW** | [00](00-stage2-execution-plan.md) §7 vs [patch-defects](patch-defects-before-a5.md) | Two unrelated D-01…D-12 series. `D-05` means "F7 downgrade" in one document and "P02 has no rollback" in the other | W-08 |
| X-21 | **LOW** | [README](README.md):23–29 | The supporting-documents table lists the package, the patch defects and `evidence/` but not `CHANGELOG.md`, so the change log is unreachable from the index | W-09 |
| X-22 | **LOW** | [00](00-stage2-execution-plan.md):236–245 vs [04](04-risks-rollback-approvals.md):39, 199 | R-15 calls 80 GB a "stop line", but the stage's stop conditions omit quota entirely and R-22 (clicks unavailable) is absent, although it would stop G6-a | W-10 |
| X-23 | **LOW** | [patch-defects](patch-defects-before-a5.md):108 | "Exists nowhere in the repository" is false for the three pre-P02 bodies (Stage 1 capture entries 11, 13, 14) | W-11 |

---

## 9. Corrections required before owner signature

Six items. All are editorial; none requires a new decision except C-01, which needs the owner to choose the scope of A2.

### C-01 — Align A2's authorised scope with its signature (HIGH)

**The problem.** [pkg](approval-package-a0-a2.md) §3.2 lists four actions; the signature covers one and a half. Item 4
(fresh secrets) is explicitly disclaimed by §3.3 and belongs to A9. Item 3 (settings) is gated A2 by
[00](00-stage2-execution-plan.md):100 but is absent from both the signature and [04](04-risks-rollback-approvals.md):148.

**Recommended fix — two parts.**

1. **Delete §3.2 item 4.** Fresh staging secrets are A9 ([04](04-risks-rollback-approvals.md):154), set by the owner,
  recorded by name and digest. Add to §3.2: *"Creating or setting any secret — including the staging anon key,
  service-role key, JWT secret, database password or `PAIRING_HASH_PEPPER` — is **A9**, not A2."* This also fixes B-9.
2. **Amend the signature to include G6-b's settings checklist**, and add the same phrase to
  [04](04-risks-rollback-approvals.md):148's "compensating evidence" cell:

   > … as an empty shell plus the one-row sentinel, **and the G6-b dashboard settings checklist for auth, JWT and Data
   > API (`public`, `extensions`; 0 tables; 0 functions; auto-expose off)**, inside a single 7-day active window.

3. **Move "Realtime membership" out of A2 and into G3-c.** `pg_publication_tables` is a G3-a capture item
   ([00](00-stage2-execution-plan.md):119) and a G3-d diff item (:122). Creating the publication membership at A2 makes
   the equivalence check compare staging against something staging was configured into, rather than reconstructed from.
   Realtime membership belongs in the reconstructed artefact.
4. **Minor:** §3.1's "Data | zero rows, synthetic identities only" and [04](04-risks-rollback-approvals.md):148's
   "synthetic-seed plan" imply fixtures. Reword to *"zero rows at creation; fixtures are A11 and are not created under
   A2"*.

### C-02 — Remove the schema load from step 1 and de-duplicate G6-c/G3-c (HIGH)

**The problem.** [00](00-stage2-execution-plan.md):71 gates "G6-c schema load" under A0+A2. The same load is G3-c
(:121), gated A0/A1/A3 at :72, and is listed as A3 by [pkg](approval-package-a0-a2.md):91 and
[01](01-staging-project-proposal.md):174. It also consumes the G3-b artefact that step 2 produces.

**Recommended fix.** Rewrite the step table as:

| Step | Gate | Deliverable | Approval |
| --- | --- | --- | --- |
| 1 | G6-a, G6-b | project created; sentinel + settings checklist signed | **A0 + A2** |
| 2 | G3-a, G3-b | read-only capture; reviewed artefact + scan result | **A0 + A1** |
| 2 | G3-c (= G6-c), G3-d (= G6-d) | schema loaded into staging; equivalence record | **A3** |

and delete G6-c and G6-d from the step-1 row and from the step-1 work-breakdown table, or relabel them as aliases of
G3-c/G3-d inside step 2. Keeping both IDs for one action is what allowed the wrong gate to appear credible.

### C-03 — Fix A0's scope sentence and its exclusion list (HIGH)

**The problem.** [pkg](approval-package-a0-a2.md):71 says "for staging only"; step 1 is a production read. A1 is absent
from :72.

**Recommended signature text.**

```text
A0 — G3 METHOD AMENDMENT
I approve replacing Stage 1's G3 method with the five-step capture → reconstruct → scan → apply → equivalence
procedure in docs/stage2/approval-package-a0-a2.md §2.2. Step 1 is a READ-ONLY catalogue capture against production
and requires A1; no table data is read. Steps 3–5 write only to staging. I accept the four limits in §2.3.
This approval does not authorise A1, A2, A3, A5, A6, A7, A8, A9, A11, A12 or A13, and does not authorise any
production write.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

**Two supporting edits in §2.2/§2.3.**

- Step 2 begins "`auth` → schemas → tables …". The `auth` schema is platform-created; only the `auth.users` trigger is a
  separate file. Reword to *"cross-schema objects the owner can legally create → `public`/`private` schemas → tables →
  functions → triggers → policies → grants → default privileges; the `auth` schema is not created by the artefact"*.
- §2.3 says "The baseline **is** a pre-P01 snapshot" for an artefact that does not exist. Reword to "**will be declared**
  a pre-P01 snapshot when it is produced".

### C-04 — Restore E14 to a prediction and scope E11's "only" (MEDIUM)

**The problem.** [02](02-findings-to-fix-mapping.md):41 records a remediation in the *now* column; :38 makes an absolute
claim that :41 contradicts.

**Recommended fix.**

- E14 **Status now** → `PROPOSED — NOT APPLIED`; move `PARTIAL` to the predicted column; change "Guard added to the
  three captured bodies" to "**Predicted:** guard applied to the three captured bodies; the other wrappers remain
  unreviewed."
- E11 honest-limit → *"… the only finding whose **entire** remaining work is a missing capture. E14's residual is also
  capture-bound, but E14 is counted in the partially-closable row."* Optionally relabel the §5 bucket
  ([02](02-findings-to-fix-mapping.md):83) "Wholly blocked on a body capture — `B (body)`". No arithmetic changes.

### C-05 — Correct the changelog's two false claims (MEDIUM)

- Line 43 (#11): replace with *"P01 pre-check 0.4 is wrong: it expects one row per function and the query returns two.
  **Recorded as [D-01](patch-defects-before-a5.md); [03](03-patch-S2-P01.md):135 is not yet corrected.**"*
- Line 17: replace "D-12 closed as VERIFIED" with "D-12 updated to `Confirmed 2026-10-30`, `VERIFIED` from official
  plan terms".
- Line 56 ("Its Stage 2 pointer is unchanged"): verify or remove. This audit found no Stage 2 pointer in the root
  `README.md`; the sentence cannot be checked as written.

### C-06 — Repair the evidence set the package cites (MEDIUM)

The package cites three evidence files. Each needs one edit so the owner is not signing against an internally
contradictory record.

| File | Edit |
| --- | --- |
| [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):95 | Claim → "**No** paid upgrade is required for staging"; status → `` `VERIFIED` — no upgrade prompt; 2 active projects allowed (addendum) `` |
| [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):49–50 | Append "*Superseded by the addendum, item 2: `VERIFIED`, 2 active projects.*" |
| [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md):1–8 | Add `**SCREENSHOT EVIDENCE: NOT VERIFIED** — no visible browser surface; captures are accessibility-tree text only.` |
| [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md):195–216 | Mark §9 "*Superseded 2026-10-30 by [02](02-findings-to-fix-mapping.md) §5: the 4→5 issue was resolved as a 1 + 4 split*", and delete "No downstream document repeats the count" |
| [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md):222–223 | Replace "Not currently in the risk register" with "Recorded as R-30 in [04](04-risks-rollback-approvals.md), §1 and §2.5" |

---

## 10. Corrections that can wait until A3/A5 or later

None of these changes what an approval authorises. Each should be fixed before the gate it touches, not before the
signature.

| ID | Where | Correction | Fix before |
| --- | --- | --- | --- |
| W-01 | [00](00-stage2-execution-plan.md):68–84, [pkg](approval-package-a0-a2.md):95 | Sequence G3-a and G3-b **before** G6-a so the 7-day window covers only G6 + G3-c/d + G5-S. Add one sentence to the "One window, not three" paragraph | A2 execution |
| W-02 | [05](05-validation-plan.md):181, 187 | 21 → **20**; 39 → **38** | A5 / G5-S |
| W-03 | [01](01-staging-project-proposal.md):123, 126; [pkg](approval-package-a0-a2.md):25 | Log ingestion 0.17 → **0.20**; egress 0.12 → **0.14** (matches the capture); or retitle the table "Stage 1 record" | A2 (cosmetic) |
| W-04 | [00](00-stage2-execution-plan.md):76, 77 | Step 6 → "none (decision record, D-07)"; step 7 → "A5 + A11" | G5-S |
| W-05 | [00](00-stage2-execution-plan.md):130; [04](04-risks-rollback-approvals.md):42, 37 | "24 bodies were never read in Stage 1, including 11 of the 13 `private` twin implementations"; reconcile R-13's 11/12 split with the 24 total | A0 / A3 |
| W-06 | [06](06-redteam-resolution.md):75 | Replace "B §?..." with the actual section (B §2, per the working paper) | Housekeeping |
| W-07 | [00](00-stage2-execution-plan.md):206; [README](README.md):19; [04](04-risks-rollback-approvals.md) §3 | State "A4 is retired for Stage 2 (migration repair is CLI-only, excluded by C1)" and change "A0–A13" to "A0–A3, A5–A13" | Any external citation |
| W-08 | [00](00-stage2-execution-plan.md) §7 vs [patch-defects](patch-defects-before-a5.md) | Rename one series — e.g. decision log `DEC-01…DEC-12` — to remove the collision | A5 |
| W-09 | [README](README.md):23–29 | Add a row for `CHANGELOG.md` | Housekeeping |
| W-10 | [00](00-stage2-execution-plan.md):236–245 | Add the R-15 80 GB stop line and R-22 (click unavailable ⇒ record `NOT EXECUTED`, stop the step) | A2 execution |
| W-11 | [patch-defects](patch-defects-before-a5.md):105–121 | Reword D-05: the rollback text is absent from the patch file and parts/D, **but** the pre-P02 bodies are captured at `stage1/evidence/g1-b3b-20261029.json` entries 11, 13, 14. They must still be re-captured from staging and reviewed | A5 (P02) |
| W-12 | [04](04-risks-rollback-approvals.md):150; [pkg](approval-package-a0-a2.md) | Record the three SHA-256 values from §7.1 in the change record before any apply | A5 |

---

## 11. Owner decision summary

1. **Do not sign yet.** Six corrections (§9), all editorial. Five are one-line edits; C-01 needs a scope choice.
2. **No unresolved item (U-01…U-16) blocks A0 or A2.** They block A5 (8 items), A2 execution (3), or a later stage (3).
   Two are accepted limitations already recorded as risks. Nothing is hidden behind the signature.
3. **The A2 scope decision is yours.** Recommended: A2 = create the project, create the sentinel, sign the G6-b settings
   checklist. Secrets move to A9. Realtime membership moves into the G3-Cs reconstruction. That is the narrowest scope
   that still lets G6-b complete.
4. **A0 needs one sentence added**: the capture is a read-only production read under A1, and A1 is not authorised by A0.
   Without it, the signature reads as a staging-only approval for a method whose first step touches production.
5. **Both or neither.** [pkg](approval-package-a0-a2.md) §5 is correct: A2 alone spends the last slot and pauses in seven
   days with nothing to show. A0 alone captures nothing.
6. **Two decisions cannot be deferred past the signature**: the window start date (U-10), and whether the window's
   budget is protected by doing G3-a/G3-b first (W-01). Neither is a documentation defect; both are operational calls
   only the owner can make.
7. **After the six corrections**, the correct verdict is `READY FOR OWNER SIGNATURE` — the remaining items are recorded
   limitations and later-gate work, not ambiguities in what is being approved.

**Verdict now: `NOT READY — CORRECTIONS REQUIRED`.**
**Verdict after C-01…C-06 are applied and re-read: `READY FOR OWNER SIGNATURE`** (with W-01 and U-10 resolved before A2
executes).

---

## 12. Statement of limitation

This audit is a review of text. It proves nothing about production, Firebase, the Free plan, the region picker, the name,
or whether any query in any document would run. Every status it reports about the environment comes from the documents it
read. It carries no screenshot; its own evidence is the cited lines, which anyone can re-read.

## SUPERSESSION ADDENDUM (2026-11-02, S2-DOC-02)

**Stamp:** `as at 2026-10-30, PRE-CREATION`. Line 6 "No project exists" and §2's recorded limitations ("the last project slot … no screenshots") were
overtaken the same day by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md): both shells exist, slots are 2 active / 2 used / 0 remaining, A0 is
unsigned and has never been approved by anyone, A2 is unsigned — the package this audit prepared for signature describes an action already performed.

**Overtaken by events:** K-1 (R-09/R-31 "2 active, 1 used, staging is the last slot") → 2 used / 0 remaining, and X-13's stale usage rows now confirmed
against CREATE-01 §2.5; U-08/U-09 (name and region `VERIFIED`, R-32/R-33 retired) and U-10 (clock running, still no UTC start — R-40); §6.1 and W-01 —
G6-a having executed, "sequence G3-a/G3-b before creation" is no longer available; and C-01…C-03, the signature-scope fixes, now carried by
[approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) as a ratification decision plus a forward A2′ rather
than as edits to this package. C-04…C-06 remain documentation work, unchanged in substance.

**Falsified premise:** "no screenshots" is answered by the owner's two in-app-browser captures (§B.4 of [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md)) — screen captures of the app window, not platform records, so R-27's audit-log half stands and this audit's own "carries no screenshot" (§1.3, §12) remains true.

**Superseded as a whole by [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md).** No finding above is deleted or rewritten; each stays valid for the pre-creation texts it read.
