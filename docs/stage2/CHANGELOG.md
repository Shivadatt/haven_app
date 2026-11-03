# Changelog — Stage 2 documents

One entry per correction pass. This is a record of documentation edits only; it is not evidence that any query ran, any
project exists, any patch was applied or any setting changed. *(Qualification added 2026-11-02: from the S2-OPS-01 entry
onward, entries also record operational actions that did occur; the evidence for those actions is
[evidence/S2-CREATE-01-new-projects.md](evidence/S2-CREATE-01-new-projects.md) and the dated audits, not this file.)*

## 2026-10-30 — S2-OPS-01: creation of the two staging projects (operational record, added 2026-11-02)

**Operational — creation only.** This entry records what was executed; the evidence document is
[S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md), and the approval consequence is in
[approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) §2 and
[04](04-risks-rollback-approvals.md) §3.1.

- **Executed:** through the browser consoles only, under the direct owner instruction "create new project on both
  supabase and firebase … not use parent-control-prod", two **EMPTY** staging projects were created:
  Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` (ap-northeast-2, Free / NANO, 0 tables, no migrations,
  0 Edge Functions, auto-expose-new-tables off, no sentinel, no schema, no secrets; slots now **2 active / 2 used /
  0 remaining**; usage observed at capture: Egress 0.14/5 GB, DB 32/500 MB, MAU 10/50,000, Storage 0/1 GB,
  Log Ingestion 0.20/1 GB, Log Query 44.8/100 GB) and Firebase `haven-staging` / `haven-staging-46822` (project
  number 381273275501, Spark, no apps, no credentials, environment type left `Unspecified`).
- **Three owner scope answers:** Supabase **"shell only"**; database password **"you type it yourself"** (custody with
  the owner; no value read, stored or logged by the agent); Firebase **"create haven-staging, Analytics off"**.
- **Two wizard settings moved off default:** Google Analytics **off** as instructed; Gemini AI assistance **off** as a
  disclosed least-privilege deviation (S2-CREATE-01 §4.1).
- **Did not occur:** no schema load, no sentinel, no secret, no app registration, no credential export, no Edge
  Function, no SQL of any kind against any project. Production `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) untouched.
- **Approval state:** the A0/A2 package was **never signed**; **A0 has never been approved by anyone**; the owner's
  chat instruction is an instruction, not an approval.
- **A12:** the Firebase creation **exceeds the A12 prohibition** ("any Firebase action in Stage 2", 04 §3) and is
  recorded as **AWAITING RETROSPECTIVE RATIFICATION** (approval-package-v2 §2; 04 §3.1; risk R-36).
- **Auto-pause:** the 7-day idle clock started at creation; the constraint is a dated dashboard touch on or before
  **2026-11-06**; no UTC start timestamp was recorded (risk R-40).

## 2026-10-30 — S2-REVIEW-02: independent audit of the A0/A2 approval package

[S2-REVIEW-02-independent-audit.md](S2-REVIEW-02-independent-audit.md). Documentation-only audit; no operational action.
**Verdict: `NOT READY — CORRECTIONS REQUIRED`** — six required corrections before the owner signs A0 or A2, two of them
safety-relevant (the A2 signature block does not cover two of the four actions its own §3.2 authorises; the plan gates a
schema load under A0+A2 while three other pages gate it under A3). The audit's own world-state lines
("`PROPOSED — NOT STARTED`", "No project exists", "no screenshots") were accurate when written but pre-date the same
day's creation now recorded under S2-OPS-01; they are superseded on existence and screenshot questions
(S2-REVIEW-03 CD-31), which is why the entry is dated here rather than the audit being rewritten.

## 2026-11-02 — S2-REVIEW-03: independent full Stage 2 consistency and readiness audit

[S2-REVIEW-03-independent-audit.md](S2-REVIEW-03-independent-audit.md). Seven read-only auditors with disjoint domains;
no document was edited by the audit and no operational action was taken or authorised by it.
**Verdict: `NOT READY — CORRECTIONS REQUIRED`.** Stage 2 status restated as
`SCAFFOLD CREATED — PLAN OF RECORD FALSIFIED — REMEDIATION NOT STARTED`. Key findings: the plan-of-record status lines,
the old approval package and several evidence files still asserted a pre-creation world (CD-01…CD-37); the Firebase
creation breached A12 (B-01 → R-36); A0 never approved and A2 never signed, so approvals can now only ratify (R-37);
**zero of four** single-owner compensating controls are fully satisfied for the executed creation (§C.3); the auto-pause
deadline (on or before 2026-11-06) was recorded nowhere (R-40); all twelve patch defects D-01…D-12 verified still OPEN;
the register extended to **R-01…R-41**; the correction backlog was numbered **FX-01…FX-17**. The audit also answers the
topology question from evidence: Supabase Auth is the sole identity authority; Firebase is FCM-transport-only and is
currently used for nothing.

## 2026-11-02 — S2-DOC-02: truth-restoration documentation pass (this pass)

Documentation only. No dashboard opened, no SQL executed, nothing applied, created, paused, resumed or deleted, and
**no approval signed or dated on the owner's behalf** — every signature line in the new package stays blank.

> **[S2-DOC-02 amendment, same day — read before the sentence above.]** The sentence "No dashboard opened" was true of
> the documentation sub-pass as first executed, and is now **superseded by the owner's standing instruction that
> accompanies this stage** ("use browser access on supabase and firebase, not use cli"). A **strictly read-only**
> re-confirmation was therefore performed at **2026-11-02T07:16Z**, recorded as
> [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md): page navigation by URL only, **zero state-changing
> controls activated**, no SQL executed, no setting changed, no secret read, no project created/paused/resumed/deleted,
> no patch touched, no app registered. One idempotent click (Auth → Users `Refresh`) was **attempted** and **failed**
> with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`; it had no effect. The owner's further instruction — **Supabase:
> `parent-control-staging` / `dzonzgngwxclhfnvxtvu` only, never another project** — is recorded as **R-43** and binds
> from 2026-11-02; the one production page read before it arrived is disclosed in S2-INSP-03 and in the README rather
> than deleted. No approval was signed by any of this.

| File | Change |
| --- | --- |
| [00-stage2-execution-plan.md](00-stage2-execution-plan.md) | Status table rewritten (`G6-a EXECUTED — SHELL ONLY`; G6-b/c/d `NOT DONE`); §3 sequence renumbered (shell → ratification → A0 → capture → reconstruct → scan → A3 load → sentinel+settings A2′ → equivalence → A5 → G5); duplicate G6-c/G3-c load and the backwards dependency removed; §9 addendum records the FX items applied. |
| [01-staging-project-proposal.md](01-staging-project-proposal.md) | Title and status rewritten to `EXECUTED — SHELL ONLY`; as-built project facts, Firebase A12 exceedance and ratification state recorded. |
| [04-risks-rollback-approvals.md](04-risks-rollback-approvals.md) | R-36…R-41 added — register now **R-01…R-41**; R-09/R-30 marked REALISED; new §3.1 executed-action reconciliation (`AWAITING RETROSPECTIVE RATIFICATION`); A2 and A12 rows annotated; §3.2 prohibition-clause breach status added. Nothing rewritten or deleted. |
| [05-validation-plan.md](05-validation-plan.md) | Blocker reason corrected: `STAGING PROJECT NOT CREATED` → `STAGING IS EMPTY` (the project exists; it holds nothing); G5-E case total stated as 104 suite + 4 patch-specific = 108 plan-of-record. |
| [README.md](README.md) | Status paragraph aligned; G2/G7 row corrected; A0/A2/G5-E rows aligned to 00/04/05; supporting-documents table gains the v2 package and S2-REVIEW-02/03; "cannot claim" gains the auto-pause deadline, the zero-of-four control score and the Firebase-shell point. |
| [CHANGELOG.md](CHANGELOG.md) | This file: S2-OPS-01, S2-REVIEW-02, S2-REVIEW-03 and S2-DOC-02 entries added; S2-DOC-01 entry annotated (screenshot/existence claims marked true-at-the-time; row #11 corrected; root-README claim fixed). |
| [evidence/S2-CREATE-01-new-projects.md](evidence/S2-CREATE-01-new-projects.md) | FX-06: non-approval disclaimer gains A0 and A2 explicitly; "no settings change beyond wizard defaults" reconciled with §4.1 ("create + two wizard settings moved off default"); the absolute "No image of either console exists" qualified for the two later owner-supplied in-app-browser captures; ratification-status and auto-pause-deadline lines added. The record itself was not rewritten. |
| [approval-package-a0-a2.md](approval-package-a0-a2.md) | Supersession banner added at the top (**do not sign**; body unedited). |
| [approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) | **New.** Ratification decision for the executed creation (§2) plus seven forward approval blocks (§3); all signature lines blank by design. |

**Verified NOT yet applied at the time of writing this entry** (tracked under FX-12…FX-15; edited by other S2-DOC-02
owners, not claimed here): [03](03-patch-S2-P01.md) line 135 still reads "one row per function" (D-01 OPEN);
[patch-defects-before-a5.md](patch-defects-before-a5.md) line 108 still carries the "nowhere in the repository" claim;
no supersession addenda have yet been observed in [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md),
[S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) or [S2-REVIEW-02](S2-REVIEW-02-independent-audit.md); the
`parts/` working papers still carry their pre-creation status lines (e.g. parts/A `PROPOSED — NOT CREATED`), so the
planned SUBORDINATE/SUPERSEDED banners are not yet in place. [02](02-findings-to-fix-mapping.md) and
[06](06-redteam-resolution.md) headers verified unchanged in status meaning (`PROPOSED — NOT APPLIED` / dispositions);
their FX-09/FX-03 detail edits are other owners' work.

**Closure of that block, later on 2026-11-02 (verified against the files, not asserted).** The items listed as
"not yet applied" above have since landed, and the ones that remain open are named plainly:

| Item | Now | Evidence in the file |
| --- | --- | --- |
| FX-13 / D-01 (`03:135`) | **Applied — documentation only** | [03](03-patch-S2-P01.md):135 reads "2 rows per function (owner + PUBLIC), **4 rows total**" with a note that the SQL is unmodified and the hash is unchanged. D-01 itself stays `OPEN (document corrected, re-check required)` |
| FX-13 / D-02, D-03 | **Applied — documentation only** | [03](03-patch-S2-P01.md) §5.1 "Two-pass execution"; T3 relabelled `INVARIANT control — not a discriminating test` and removed from the §9 stop list |
| FX-12 / patch-defects `:108` | **Applied** | [patch-defects-before-a5.md](patch-defects-before-a5.md):143-155 replaces the false "nowhere in the repository" claim with the real capture location, `g1-b3b-20261029.json`:149/155/159/165 (metadata `62/67/78`); the closing table at :294-333 gives one row per D-01…D-12 with the three unchanged hashes |
| FX-14 / evidence addenda | **Applied, append-only** | [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md) :129-141, [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md) :56-67 plus header :9, [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) :242-255, [S2-REVIEW-02](S2-REVIEW-02-independent-audit.md) :430-444, [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) :459-471 and its citation corrections at :239-250. No prior observation deleted |
| FX-15 / working papers | **Applied — 10 of 10** | Every `parts/*.md` now opens with the `WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02)` banner and ends with a dated `## Addendum — S2-DOC-02 status correction (2026-11-02)`; parts/A's F4 validation, parts/B's platform-backup restore and parts/G's "G5-S Runnable" are withdrawn there, and parts/B's colliding A-numbers are labelled historical (there is **no A4 in the plan of record**) |
| FX-09 / FX-03 in 02 and 06 | **Applied** | [02](02-findings-to-fix-mapping.md) E14 → `PROPOSED — NOT APPLIED`, E11 scoped to "wholly", E3 single tier `D`, §4 Firebase reconciliation, §5 topology sentence; [06](06-redteam-resolution.md) J-19 → 2 used / 0 remaining and J-23 added |

**Still open after this pass — not claimed as closed:** the twelve patch defects D-01…D-12 are `OPEN` as a *class*
(seven of them need a patch-file revision, which no approval permits yet); no approval of any letter has been signed;
the 2026-10-30 creation is **not** ratified — that is the owner's §2 decision in
[approval-package-v2](approval-package-v2-ratification-and-forward.md); the G3 artefact does not exist; staging holds no
schema; and the Firebase plan label (Spark) was not re-confirmed because the plan page redirects to the overview
(S2-INSP-03 §2.3).

**New in this closure, from the read-only re-confirmation (not part of the original FX list):**

| ID | What | Where recorded |
| --- | --- | --- |
| **FX-18** | Staging Auth prints `Total: 10 users (estimated)` over an **empty** grid, so "`auth.users` is empty" is downgraded from assumed to `NOT VERIFIED`; production's exact `Total: 8 users` shows the two figures come from different code paths | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3; [01](01-staging-project-proposal.md) topology row 1; [05](05-validation-plan.md) glossary `BLOCKED — STAGING IS EMPTY`; [approval-package-v2](approval-package-v2-ratification-and-forward.md) §1.1 and §3.4 preconditions (first statement of the A3 window; non-zero ⇒ stop) |
| **R-42** | the clean-shell premise is unproven for `auth.users` | [04](04-risks-rollback-approvals.md) §1; register range now **R-01…R-43** |
| **R-43** | standing owner scope constraint: **Supabase work targets `dzonzgngwxclhfnvxtvu` only**, never another project | [04](04-risks-rollback-approvals.md) §1; [README](README.md) status paragraph; [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) header |
| — | Both shells re-confirmed unpaused and empty; slots 2/2/0; usage meters unchanged (Egress 0.14, DB 32 MB, MAU 10, Storage 0, Log Ingestion 0.20, **Log Query 44.8/100 GB**); Firebase shows zero apps and zero enabled products | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1, §2, §4 |
| — | Stage 1's architecture record gains §9: topology stated once as a table, plus the dated note that `haven-staging-46822` now exists as an empty shell while rows 1–7 of the topology are unchanged | [../stage1/02-architecture.md](../stage1/02-architecture.md) §9 (append-only; §1–§8 untouched) |
| — | The retired A0/A2 package banner now names each falsified line at its **current** numbering (:9-10, :28, :31, :33, :34) so a reader cannot take any of them forward | [approval-package-a0-a2.md](approval-package-a0-a2.md) banner |
| — | **Deliverable written:** FX-01…FX-18 matrix with line citations, as-built identifier table, modified-file list with hashes/mtimes, the zero-commit `git diff` provenance gap, patch-hash integrity, no-operational-action table, verdict `READY WITH RECORDED LIMITATIONS` | **New** [S2-DOC-02-reconciliation.md](S2-DOC-02-reconciliation.md); pointer added to the [README](README.md) supporting-documents table |
| — | Owner scope constraint propagated: **all Supabase work targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu` only** | [00](00-stage2-execution-plan.md) §1 row **C2b** + §9; [04](04-risks-rollback-approvals.md) §1 **R-43**; [README](README.md) status paragraph; [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) header; parts/J addendum |

S2-DOC-02 addendum (2026-11-02): documentation correction plus one strictly read-only console re-confirmation; no SQL
executed, nothing applied, no project created/paused/resumed/deleted, no setting changed, no secret read or created, no
app registered, no deployment, **no approval signed or dated on the owner's behalf**.

## 2026-10-30 — S2-DOC-01: findings mapping, risk register, Firebase note, patch defects, A0/A2 package

Documentation only. No Supabase or Firebase dashboard was opened; no SQL executed; no schema reconstructed; no project
created, paused or deleted; no patch applied; no secret read; no Firebase action. Screenshot evidence remains
`NOT VERIFIED`; every capture cited here is an accessibility-tree snapshot with its URL and UTC timestamp.

> **[S2-OPS-01 annotation, 2026-11-02 — retained as written, not deleted.]** The paragraph above was **true at the time
> this entry was written** (a documentation pass that itself opened no console). It is now **superseded on the existence
> and screenshot questions by S2-OPS-01 / [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md)**: later on 2026-10-30
> both consoles were opened and two projects were created under direct owner instruction, and the owner has since
> supplied two in-app-browser captures (corroborative screen captures, not platform records — see the S2-CREATE-01
> header qualification). The platform-audit-log absence that R-27 records stands unchanged.

| File | Change |
| --- | --- |
| [02-findings-to-fix-mapping.md](02-findings-to-fix-mapping.md) | Tier **B** redefined as "missing evidence **or** an outstanding decision", with a bracket qualifier per finding. E11 → `B (body)`; E13 → `B (design)`; F1 → `B (ownership)`; F3 → `B (policy)`; F6 → `B (backlog)`; E14 → `A (3 bodies) / B (body, rest)`. **F3 status corrected** from `BLOCKED — BODY NOT CAPTURED` to `BACKLOG`, with the note that its trigger body was captured in Stage 1 and the fix needs a policy rewrite plus a reviewed trigger change. F4's "safe to test in staging" corrected: the feature is not on Free. Coverage table split into one body-capture row and one decision row, with an explicit 4 → 5 arithmetic correction. |
| [04-risks-rollback-approvals.md](04-risks-rollback-approvals.md) | R-22…R-29 created (browser viewport, two identities, loading artefacts, entitlement inferred from a button, Free-tier assumptions, **R-27 screenshot/platform-audit absence**, drift between inspection and execution, approval inferred from silence). R-30…R-35 added (7-day auto-pause and the single-window rule, last slot, name, region picker, F4, no backup/PITR). R-09 amended to VERIFIED 2/1; R-10 detection no longer relies on `audit_logs`; R-15 raised to 44.8/100 GB and L→H. New §2.5 pause/recovery/re-creation procedure; §2.4 item 3 now requires written approval for deletion. A2 row and the global prohibitions updated. New §6 Firebase ownership note; Open questions renumbered to §7, Q1 answered, Q7 added. |
| [01-staging-project-proposal.md](01-staging-project-proposal.md) | Region confidence split (production VERIFIED / picker `NOT VERIFIED`); second-project entitlement VERIFIED. Leaked-password row now plan-forced; deviations summary corrected. §4 says **attempt** creation and names the failure branch. §5 re-reads usage (log query 44.8/100 GB), replaces the INFERRED ceiling with VERIFIED 2/1, adds auto-pause and no-restore-point risks, renumbers. Checklist item for slots rewritten; open question 1 answered. |
| [00-stage2-execution-plan.md](00-stage2-execution-plan.md) | Pointer to the two supporting documents outside the plan of record. G6-a is now an **attempt** with a named failure state and no substitute name/region without approval. New paragraph: G6 + G3 + G5-S are one 7-day window (R-30). D-12 closed as VERIFIED (2 active, 1 used — *(true at the time; superseded by S2-OPS-01: 2 active / 2 used / 0 remaining)*). |
| [05-validation-plan.md](05-validation-plan.md) | G5-S no longer reads "Runnable" unconditionally; it is runnable only if G6 succeeds, otherwise `BLOCKED — STAGING PROJECT NOT CREATED`. |
| [06-redteam-resolution.md](06-redteam-resolution.md) | J-19 corrected from "three projects needed, two available" to "one available"; slot limit recorded as VERIFIED. |
| [README.md](README.md) | Index now lists R-01…R-35 and the two supporting documents; status table adds A0/A2 rows and the patch-defect gate; "cannot claim" adds F4, no restore point and no screenshot/platform-audit evidence. |
| [patch-defects-before-a5.md](patch-defects-before-a5.md) | **New.** D-01…D-12: P01 pre-check row count, P01 commit-before-compare, P01 T3 non-discriminating, P01 rollback section label; P02 missing in-file rollback, advisory post-checks, commented-out gate, missing capture entry, `limit 1` sentinel; P03 missing in-file rollback and incomplete header preconditions, transition-guard assumption. **No SQL changed.** |
| [approval-package-a0-a2.md](approval-package-a0-a2.md) | **New.** What is settled, the A0 method text, the A2 parameters and bounds, two signature blocks, U-01…U-16 unresolved, and the "signing one only" consequences. |
| [CHANGELOG.md](CHANGELOG.md) | New. This file. |

Counts introduced by this pass: 35 risk rows (R-01…R-35; the register has since been extended to R-01…R-41 by
S2-DOC-02), 12 patch-documentation defects (D-01…D-12), 16 unresolved
approval items (U-01…U-16). Findings do not change count: 14 E-findings, 8 F-findings, one cross-cutting item; **no
finding changed from open to fixed**.

### Substantive corrections (not rewording)

| # | Correction | Why it mattered |
| --- | --- | --- |
| 1 | **F3 was mislabelled as body-capture blocked.** Stage 1 captured the trigger body; the fix needs a policy rewrite plus a reviewed trigger change. | The label implied the evidence did not exist and that a re-capture would unblock it. It would not — a design decision would. |
| 2 | **Coverage row said 4 and listed 5, C double-counted E3, and F4 had no row.** Split into `1 (E11)` body capture and `4 (E13, F1, F3, F6)` decisions; `F6-minor` dropped; `E3-residual` removed from C because E3 is already in D; F4 added as its own tier-E row. Buckets now reconcile to 23 findings exactly. | An arithmetic defect that made the "honest ceiling" table wrong in the one place it is quoted. |
| 3 | **R-27 and R-30 were cited but did not exist.** The register stopped at R-21. R-22…R-29 created, then R-30…R-35. | Cited-but-missing risk IDs make the evidence files unresolvable. |
| 4 | **Slot ceiling upgraded from INFERRED to VERIFIED.** Free allows 2 active projects; production holds one. | Decision-changing: staging spends the last slot. |
| 5 | **F4 is not testable on Free.** Leaked-password protection is excluded by the plan. | Decision-changing: an experiment was removed from the staging deviation list, and A2 no longer implies it. |
| 6 | **No automatic backups or PITR on Free.** | Removes the implicit "we can restore" fallback from G3 and from any failure path. |
| 7 | **Free projects auto-pause after 7 days.** Added R-30 and §2.5. | Turns three separate steps into one coordinated window and adds a deletion/re-creation approval rule. |
| 8 | **Log-query usage is 44.8/100 GB, not 33.9.** R-15 likelihood raised to H. | The tightest quota dimension was understated by a third. |
| 9 | **R-10 no longer cites `audit_logs` as detection.** That table records application events, not dashboard or SQL-Editor activity; Free has no platform audit log. | Detection was assumed where none exists — exactly the failure R-27 now records. |
| 10 | **Region-picker availability downgraded to `NOT VERIFIED`.** | A2 names `ap-northeast-2`; selectability on a new Free project was never observed. |
| 11 | **P01 pre-check 0.4 expects 2 rows per function, not 1** — recorded as defect D-01; 03:135 not yet corrected — **OPEN** *(corrected claim 2026-11-02, S2-DOC-02: this row previously read as if the fix had been applied; a re-read of [03-patch-S2-P01.md](03-patch-S2-P01.md) line 135 shows it still says "one row per function", so the change was never made)*. | A reviewer following the old text would false-stop or learn to ignore the table. |

### Not changed by this pass

- **No SQL file, hash or patch status.** Every patch remains `PROPOSED — NOT APPLIED`; the four items needing a patch
  revision (file comment, commit placement, sentinel cardinality, in-file rollback for P02/P03) are listed in
  [patch-defects-before-a5.md](patch-defects-before-a5.md) and need their own review.
- **No Stage 1 document.** Flagged but not edited, because Stage 1 is the evidence base:
  [stage1/06](../stage1/06-secrets-and-environments.md) states a "single owner for every row" that holds for Supabase
  rows only, and [stage1/07](../stage1/07-ops-and-observability.md) still marks backups/PITR `NOT VERIFIED` where they
  are now known to be absent from Free. Both should be corrected in a Stage 1 pass, not here.
- **No `parts/` working paper.** They are subordinate ([README](README.md)); A, B, I and G still carry INFERRED slot
  text, the backup fallback and the F4 "safe to validate" line. Editing them would fork the register.
- **No root `README.md`.** *Claim corrected 2026-11-02 (S2-DOC-02): the original text said "Its Stage 2 pointer is
  unchanged", but a read-only grep of `D:\control\README.md` on 2026-11-02 finds **no Stage 2 pointer at all** — the
  claim referred to a pointer that does not exist there. The root README was not edited by any pass; it still describes
  Stage 1 as current and says no dedicated Firebase project exists, both of which the S2-OPS-01 creation now bears on
  (flagged to the owner, out of Stage 2 documentation ownership).* The plan of record carries the status.

## 2026-11-02 — S2-EXEC-01 / S2-EXEC-02 / S2-EXEC-03: decisions recorded, then the corrections applied

**Documentation-only pass. No entry below records an operational action, and none was taken in any of the three passes:
no dashboard page, no SQL Editor statement, no SQL of any kind against any project, no CLI, no migration, no schema load,
no sentinel, no settings change, no secret, no patch applied, no Firebase app registration, no FCM configuration, no Edge
deployment, no production access, no Git commit or push.**

### S2-EXEC-01 — owner decision, ratification and controlled G3 execution (not executed)

Read-only repository preparation and the ratification/forward-approval gate. **The gate never opened**: no signature fence
was filled and no owner approval was prefilled, so Phase 3 controlled execution did not run. Its readiness record is
[evidence/S2-EXEC-01-phase0-readiness.md](evidence/S2-EXEC-01-phase0-readiness.md); the changelog gap for this pass is
disclosed here rather than back-dated, because the record existed before this entry was written.

### S2-EXEC-02 — owner decisions recorded (no document changed)

[S2-EXEC-02-owner-decision-resolution.md](S2-EXEC-02-owner-decision-resolution.md). Decisions transcribed from explicit
owner instruction — **not** inferred from silence, project existence, or a prior turn:

| Decision | Recorded outcome |
| --- | --- |
| Ratification of the 2026-10-30 creations | **RATIFY, option (i)**. A12's Stage-2 prohibition is amended to: **"project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited."** Grants nothing forward |
| **B-2** — sentinel vs load ordering | **Sequence A**: A2′ splits into **(a) sentinel BEFORE the A3 load** and **(b) settings + Realtime publication AFTER it** |
| **B-3** — the FX-18 `auth.users` count | **Option A**: the count sits **inside A3's window**, as its first statement, non-zero answer stops the load. A3 is unsigned, so the count is **still unauthorised and unrun** |
| **F-5-A** — production reads under the staging-only absolute (C2b) | **Staging-only is absolute.** **A1 is `INOPERATIVE`** — void in substance, not merely unsigned — and is removed from A3's precondition chain; the baseline becomes the in-repo 2026-10-29/30 Stage 1 capture |
| Approval state as at that pass | **A0 APPROVED** (method amended) · **A5 APPROVED but NOT EXECUTABLE** · **A2′, A3, A9, A12 UNSIGNED** · **zero physical signature fences filled anywhere** |
| Consequence for P03 | P03's required production duplicate count depended on A1; with A1 inoperative, **P03 is `BLOCKED — PRODUCTION READ NOT AUTHORISABLE`** |

That pass applied **no** authoritative-document edits and handed over a scoped correction list, **C-1…C-12** (§7).

### S2-EXEC-03 — corrections C-1…C-12 applied, plus the offline G3 reconstruction

Report: [S2-EXEC-03-documentation-reconciliation-report.md](S2-EXEC-03-documentation-reconciliation-report.md).

- **C-1** approval-package-v2 §3.1 — A0's capture step replaced with reconstruction from the in-repo `g1-*`/`g1-b3b`
  capture; the three disclosed limits of the offline method are recorded as accepted-with-cost.
- **C-2** A1 declared `INOPERATIVE` and removed from A3's chain; the in-repo baseline is named — package v2 §3.2/§3.4,
  00 §1 (C2/C2b) + §3 steps 4–10 + §4 G3 table + P03 preconditions, README approval rows, 04 §3 rows A1/A3/A5 and §1.
- **C-3** A2′ worded as two separated halves (a) before / (b) after the load, with its signature text amended — package v2
  §3.3, 00 §3/§4, 01 §7(b).
- **C-4** [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3 annotated (text retained) that the owner placed
  the count inside A3; the read is still unauthorised. **The count was not run.**
- **C-5** Ratification restamped **`RATIFIED — 2026-11-02 — OPTION (i)`** with the amended A12 sentence quoted and "grants
  nothing forward" preserved — README status lines, package v2 §2, 00 §1/§3/§4 Step 8, 02 §Firebase bullet, 04 §3.1/§6/§7,
  01 header/§6/§7. Historical, dated point-in-time lines are left as written.
- **C-6** **R-41 row added** to 04 §1 from its existing definitions (S2-REVIEW-03 §I and parts/I) — the register claimed
  "R-01…R-43" while no R-41 row existed; it now holds **43 rows for 43 identifiers**, verified by count. Changelog rows
  that said "R-01…R-41" are historical records and are unchanged.
- **C-7** FX-18 added to the S2-REVIEW-03 register as item 18, explicitly marked as added after the audit and **not** a
  finding of it; its `NOT VERIFIED` verdict is preserved.
- **C-8** parts/J and S2-REVIEW-03 extended to the full **J-01…J-23** range; 06 stays authoritative for J-23's disposition.
- **C-9** Capture channels per file — S2-INSP-01 accessibility-tree (`take_screenshot` failed 3×,
  `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`), S2-INSP-02 **not labelled** accessibility-tree and screenshot `NOT VERIFIED`,
  S2-CREATE-01 local display **with no UTC conversion**, S2-INSP-03 URL navigation. The blanket "captures (accessibility-
  tree text)" claim is withdrawn; **no platform audit log exists or is claimed** (Free plan includes none).
- **C-10** [01](01-staging-project-proposal.md) — the three `AWAITING RETROSPECTIVE RATIFICATION` sites (header, §6 table
  row 7, §7(a) Firebase item) restamped as ratified, the §7 honesty note and §7(b) A0/A2 lines annotated with their
  current status, and the **"sentinel required before any DDL"** rule **kept** — it is what Sequence A now formalises.
- **C-11** 05 §1: the G5-S unblock chain is restated without A1 and with the A2′(a)/(b) split; **G5-S, G5-E and G5-C stay
  `BLOCKED`** — no validation status changed — and the FX-18 dependency in §2 is tied to unsigned A3.
- **C-12** this entry.
- **Final sweep after C-1…C-12** — four present-tense status claims that had no nearby correction were annotated in place
  with their original wording preserved: 04 `:87` (R-29) and `:279` (§4 item 1), 00 `:341` (§9 addendum bullet),
  approval-package-v2 `:21` (§1) and `:74` (§1.3). Dated point-in-time records (S2-REVIEW-02/03, the Phase 0 readiness
  evidence, older entries in this file) were **left as written**; sites already followed by a dated annotation were not
  duplicated. No status upgraded, no fence filled.

**Register of what is still true after the pass:** the artefact is **`NOT LOAD-READY`** (459 active statements; 0 create a
function, trigger, policy or publication), the secret scan reported **0 pattern matches** (which is not proof that no
secret exists), **A3 and A2′ remain unsigned**, the auto-pause obligation (**dated dashboard touch on or before
2026-11-06**, no UTC start recorded) is unmet and unowned, and **zero signature fences are filled**.
