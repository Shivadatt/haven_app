# Stage 2 — controlled remediation and staging validation

**Status: `SCAFFOLD CREATED — REMEDIATION NOT STARTED`.** On 2026-10-30 the owner instructed creation and two empty
staging projects were created through the browser consoles:
`parent-control-staging` / `dzonzgngwxclhfnvxtvu` (Supabase, ap-northeast-2, Free/NANO) and `haven-staging` /
`haven-staging-46822` (Firebase, Spark, Analytics off) — evidence in [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md).
Both are **shells**: no schema, no sentinel, no secrets, no apps, no Firebase credentials. No SQL has been executed
against any project, no patch has been applied, no secret exists, nothing has been deployed, and production is
untouched. The remediation documents themselves remain proposals: the owner has decided the ratification question and
approved **A0** (method) and **A5** (patch application, not yet executable), while **A2′, A3, A9 and A12 are unsigned** —
see the approval status table below. Both shells were
re-confirmed read-only on 2026-11-02T07:16Z — `STATUS Healthy` (unpaused), 0 tables, `No migrations`, 0 Edge Functions,
`There are no apps in your project` ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)).

**The executed 2026-10-30 creation is `RATIFIED — 2026-11-02 — OPTION (i)`** ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1;
request in [approval package v2](approval-package-v2-ratification-and-forward.md) §2). Ratification accepts two empty
shells as they are; **it grants no forward operational permission of any kind** and is not a signature on A0, A2′, A3,
A5, A9 or A12. The owner's amended A12 prohibition reads: **project creation is permitted under owner instruction;
app registration, FCM configuration, credentials and settings changes remain prohibited.** Zero of the four physical
signature fences is filled, and none is prefilled here.

**Latest pass: [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md) (2026-11-02) — `DOCUMENTATION RECONCILIATION
COMPLETE; G3 ARTEFACT READY FOR REVIEW; NOT LOAD-READY`.** It applied the corrections C-1…C-12 that S2-EXEC-02 §7 had
scoped, and built the G3 reconstruction **offline** under approved A0, outside the repository. **No cloud operation
occurred in that pass** — no dashboard, no SQL, no settings change, no patch, no commit. Its next permitted action is
**owner review of the artefact and its limitations report**, and the decision that follows is the one this programme
cannot make for the owner: accept a structural-only baseline, or change the staging-only absolute so that real function
definitions can ever be captured (see §"Next permitted action" in that report).

**Standing owner scope constraint (2026-11-02), recorded as R-43:** every Supabase action in this programme targets
**`parent-control-staging` / `dzonzgngwxclhfnvxtvu` and no other project**. Production
(`parent-control-prod` / `hhqgreaoqulmfwfwarhc`) is not to be opened, queried, configured or used as a fallback, and no
third project exists or may be created (2 active / 2 used / 0 remaining). **Disclosure:** one production page was
opened read-only on 2026-11-02, before this constraint was stated — the Auth → Users aggregate total, needed to
characterise the staging figure in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3. No control on that
page was activated, no user row, email, key or setting was read or transcribed, and nothing was written. Under this
constraint it will not be opened again.

Stage 1 ([`../stage1/`](../stage1/README.md)) is the evidence base and remains authoritative.

---

## Read in this order

| # | Document | What it answers |
| --- | --- | --- |
| 00 | [Execution plan](00-stage2-execution-plan.md) | Constraints, authoritative sequence, work breakdown, verdict ceiling, decision log |
| 01 | [Staging project proposal](01-staging-project-proposal.md) | Name, region, plan, configuration, replication scope, cost, isolation, **approval checklist** |
| 02 | [Findings-to-fix mapping](02-findings-to-fix-mapping.md) | E1–E14 and F1–F8 → tier, patch, predicted status, honest limit |
| 03 | [S2-P01 patch review](03-patch-S2-P01.md) | The first reviewable patch, complete: evidence, diff, compatibility, tests, rollback, approvals |
| 04 | [Risks, rollback, approvals](04-risks-rollback-approvals.md) | R-01…R-43, per-patch rollback, staging pause/recovery (§2.5), Firebase ownership note (§6), A0–A3, A5–A13 (no A4 in the plan of record), executed-action reconciliation (§3.1), production release gate, change record |
| 05 | [Validation plan](05-validation-plan.md) | G5-S / G5-E / G5-C split, test principals, expected results, evidence format |
| 06 | [Red-team resolution](06-redteam-resolution.md) | J-01…J-23 dispositions and corrections to the working papers |

Supporting documents (outside the plan of record, they change nothing in it):

| Document | What it answers |
| --- | --- |
| [Approval package v2 — ratification and forward](approval-package-v2-ratification-and-forward.md) | Retrospective ratification request for the 2026-10-30 creation (§2) plus seven forward approval blocks (§3). **§2 decision recorded 2026-11-02: option (i) RATIFY**, with the A12 wording amended and no forward permission granted by it. **Every signature fence in this document is still blank** — the decisions live in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md), and an owner decision recorded in a report is not a signature on a fence. |
| [S2-EXEC-02 — owner decision & approval-conflict resolution](S2-EXEC-02-owner-decision-resolution.md) | The authoritative record of the owner decisions: RATIFY (i), Sequence A, the FX-18 count inside A3, staging-only absolute with **A1 inoperative**, the seven approval statuses, the reclassified blocker register (incl. new B-16/B-17) and the scoped correction list C-1…C-12 |
| [S2-EXEC-03 — documentation reconciliation & offline G3 reconstruction](S2-EXEC-03-documentation-reconciliation-report.md) | The pass that applied C-1…C-12 and built the offline G3 artefact outside the repository: coverage, provenance manifest, secret scan, structural review, limitations |
| [Approval package A0/A2](approval-package-a0-a2.md) | **SUPERSEDED by the v2 package — DO NOT SIGN.** Its line 27 answer to "Staging project created" (`No`) and its forward-authorisation framing are falsified by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md); retained unedited as the historical request. |
| [Patch defects before A5](patch-defects-before-a5.md) | D-01…D-12 documentation defects in the patch papers; which are must-fix, which need a patch revision |
| [S2-REVIEW-02](S2-REVIEW-02-independent-audit.md) | Audit of the old approval package — verdict `NOT READY`; its status lines are stamped as-at 2026-10-30 pre-creation |
| [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) | This stage's full consistency and readiness audit — verdict `NOT READY — CORRECTIONS REQUIRED`; source of the FX-01…FX-17 correction backlog that S2-DOC-02 executes. **FX-18 is carried in its §I list as item 18 marked "added after issue"** — it originated in S2-DOC-02, and its status stays `NOT VERIFIED — dashboard total contradicts, unresolved` |
| [S2-DOC-02-reconciliation.md](S2-DOC-02-reconciliation.md) | The closure record for that backlog: as-built identifiers, FX-01…FX-18 status with line citations, list of modified files, hashes and the zero-commit provenance gap, patch-file integrity, no-operational-action confirmation, verdict `READY WITH RECORDED LIMITATIONS` |
| [`evidence/`](evidence/) | Inspection and creation captures — **the evidence type is not uniform across them, so it is labelled per file rather than for the set.** [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md): verbatim **accessibility-tree text** from `take_snapshot`, URL per page, UTC time range recorded; `take_screenshot` failed three times (`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`) → screenshot evidence `NOT VERIFIED`. [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md): **verbatim page text** with URL and a UTC time range — the capture channel is **not** labelled in that file, and its `SCREENSHOT EVIDENCE: NOT VERIFIED` header was added 2026-11-02 for format consistency, which is not new evidence. [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md): accessibility-tree text by URL, but timestamps are **local display with no UTC conversion recorded**, so sub-day ordering is by snapshot sequence, not by clock. [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) (2026-11-02 re-confirmation; source of FX-18/R-42): URL navigation only, `take_snapshot` worked throughout, **no screenshot captured**. [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) and [S2-EXEC-01](evidence/S2-EXEC-01-phase0-readiness.md) are local read-only reports, not console captures. **Across the whole programme: no screenshot is a platform record** — the two captures the owner later supplied are screen captures of the in-app browser window, corroborating named fields only, with no UTC stamp and no project ID visible on the Firebase one; and **no platform audit log exists or is claimed** (Free plan includes none — R-27) |

Patches: [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql) (hardened, reviewable),
[`patches/S2-P02-e3-actor-binding.sql`](patches/S2-P02-e3-actor-binding.sql) (prepared, not applied),
[`patches/S2-P03-e4-session-invariant.sql`](patches/S2-P03-e4-session-invariant.sql) (prepared, not applied).

Working papers: [`parts/`](parts/) — A through J. They are the design record and are **subordinate** to 00–06. Every
part carries a `WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED` banner and a dated S2-DOC-02 addendum (2026-11-02);
read the addendum before acting on anything in a part.

---

## One-line status per work item

| Item | Status |
| --- | --- |
| A0 (G3 method) | `APPROVED — 2026-11-02` by recorded owner decision, **method = offline reconstruction from the existing Stage 1 catalogue capture** (no production dashboard capture — see C-1/C-2 below). The physical signature fence in [approval package v2](approval-package-v2-ratification-and-forward.md) §3.1 remains **unfilled**; an approved decision is not a signed fence |
| A1 (production read-only capture) | **`INOPERATIVE`** — the staging-only absolute instruction (R-43, reaffirmed 2026-11-02) means `hhqgreaoqulmfwfwarhc` is not opened, so no capture under A1 can be authorised or run. Removed from A3's precondition chain; the in-repo `g1-*`/`g1-b3b` capture is the substitute source |
| A2 (create staging) | `EXECUTED 2026-10-30` under direct owner instruction — scope **"shell only"**; the packaged A2 signature was never signed, so the signed record and the executed action differ; the executed creation is **`RATIFIED — 2026-11-02 — OPTION (i)`** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md); [04](04-risks-rollback-approvals.md) §3.1). Ratification grants nothing forward |
| A2′ / A3 / A9 / A12 | **`UNSIGNED`** — no fence filled, no operation authorised. A2′ is worded as two stages (a) sentinel before A3 and (b) settings + Realtime publication after A3, per Sequence A |
| A5 (patch application) | `APPROVED — NOT EXECUTABLE` (2026-11-02): D-01…D-12 are all still OPEN, P02 aborts as shipped (D-07), and no patch can run before A3. Approved status is not permission to act now |
| G6 staging project | `G6-a CREATED — EMPTY SHELL`; Supabase `dzonzgngwxclhfnvxtvu` + Firebase `haven-staging-46822`; last Free slot consumed (2 active / 2 used / 0 remaining); 7-day auto-pause clock running — dated touch on or before 2026-11-06, no UTC start recorded; G6-b sentinel/settings, schema load and verification `NOT DONE` |
| G3 baseline | `RECONSTRUCTED OFFLINE — NOT CAPTURED FROM PRODUCTION, NOT LOAD-READY`. Under approved A0 the artefact was built on 2026-11-02 from the in-repo Stage 1 catalogue capture (`g1-q1…q10`, `g1-b3b`) and is held **outside this repository** pending owner review of the secret scan: `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/`. 459 active statements cover schemas, tables, columns, constraints, indexes, RLS enablement, grants and default privileges; **0 function, trigger, policy or publication statements are executable** because the evidence holds no return type for any of the 38 functions and 24 `private` bodies were never captured. See its `91-coverage.md`, `95-secret-scan.md`, `96-review-checks.md` and `90-limitations.md` |
| S2-P01 (E2/F8) | `PROPOSED — NOT APPLIED`; 4 doc defects to clear first ([patch defects](patch-defects-before-a5.md)); D-01's text at 03 §4 row 0.4 is **corrected (documentation-only)** to "2 rows per function, 4 rows total" and stays `OPEN (document corrected, re-check required)` — the SQL file is unchanged and its hash is unchanged |
| S2-P02 (E3/F7/E1/F5) | `PROPOSED — NOT APPLIED`; no in-file rollback; F7 stays OPEN after it. D-05's "nowhere in the repository" is corrected: the original bodies are captured at [`g1-b3b-20261029.json`](../stage1/evidence/g1-b3b-20261029.json):149/155/159/165 |
| S2-P03 (E4) | `PROPOSED — NOT APPLIED`; production deployment blocked on an Edge mapping |
| E6 / E7 | `BLOCKED — EDGE SOURCE REQUIRED`; no patch authored |
| G5-S | `BLOCKED — STAGING IS EMPTY` (0 tables in `public`, no schema, no sentinel, no principals created by this programme); `auth.users` emptiness is separately `NOT VERIFIED` — FX-18/R-42 |
| G5-E (104 suite cases + 4 patch-specific = 108 per [05](05-validation-plan.md) §1) | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| App compatibility | `BLOCKED — NO APP SOURCE IN THIS REPO` |
| G2 / G7 | Firebase project shell created 2026-10-30 — **`RATIFIED — 2026-11-02 — OPTION (i)`**; no app, credential, FCM or config change (all still prohibited by the amended A12 wording, and A12 is unsigned); G2/G7 remain deferred |

---

## What this stage cannot claim

- **E3/F7 is not closed** and is not closable in the database: every live caller runs as `service_role`, where
  `auth.uid()` is NULL.
- **E4 is not user-facing-correct** until an Edge handler maps `P0001`/`23505`; the SQL invariant is enforced, the
  response code is not.
- **E6/E7/E8/E9/E10/E12** need handler source that is not in this repository.
- **"G5 passed" is not an available verdict** — 104 of 105 HTTP cases cannot run.
- **App compatibility is not verified** — no Flutter or Android source is present.
- **F4 cannot be tested here** — leaked-password protection is not included on the Free plan; F4 stays `BACKLOG`.
- **No restore point exists** — Free includes no automatic backup or PITR; recovery is rebuild-from-artefact, not
  platform restore.
- **No platform screenshot record and no platform audit log exists** — console evidence is page-derived text captured
  per file (the capture channel and the timestamp quality differ between files; see the evidence row above, which
  labels each on its own terms). The two captures the owner later supplied are screen captures of the in-app browser
  window, not platform records: they carry no UTC stamp and do not show project IDs. A snapshot is never described as a
  screenshot, no audit trail is claimed, and **accessibility-tree labelling is not extended to a file that does not
  demonstrate it** (corrected in the S2-EXEC-03 pass, C-9).
- **The auto-pause deadline is a live, unowned constraint** — the Free 7-day idle clock started with the 2026-10-30
  creation; the requirement is a dated dashboard touch on or before **2026-11-06**; no UTC start timestamp was ever
  recorded (R-40, U-10). Recording this deadline is documentation; meeting it would be an operational action needing
  the owner's instruction.
- **Zero of the four single-owner compensating controls are fully satisfied for the executed creation** — patch hash
  (absent by design), before/after snapshot (partial: staging had no prior state), timed window (no start recorded),
  separate reviewer pass (absent) ([S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §C.3). The creation record is
  honest; it is not the control the plan requires.
- **The Firebase shell contributes nothing to Stage 2 remediation** — auth, database and Edge Functions are all
  Supabase-side; `haven-staging-46822` validates no G5 case and exercises no patch. It pre-provisions only the
  intended FCM transport lane. Its creation is **ratified** (2026-11-02, option (i)) under the amended A12 wording —
  project creation permitted by owner instruction, app registration / FCM configuration / credentials / settings
  changes still prohibited — and **A12 itself is unsigned**, so nothing beyond that creation is authorised.
- **"Staging has no `auth.users` rows" is not established** (FX-18, R-42). The dashboard renders an empty result grid
  yet prints `Total: 10 users (estimated)` for `parent-control-staging`
  ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3). What *is* established is that this programme
  created no user and ran no sign-up there. The count is the first statement of the A3 window, and a non-zero answer
  stops the load: P01's pre-check expectation and every "the target is empty, so a wrong-project run is impossible"
  argument are conditioned on it.
- **Production is untouched and unauthorised.** Any production change needs the seven-item gate in
  [04](04-risks-rollback-approvals.md) §4 plus an explicit approval that does not exist yet.

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed.
