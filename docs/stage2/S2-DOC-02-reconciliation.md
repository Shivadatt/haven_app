# S2-DOC-02 — Truth restoration and approval reconciliation: deliverable record

**Pass:** S2-DOC-02 (documentation) plus one strictly read-only console re-confirmation
**Delivered:** 2026-11-02
**Scope constraint honoured throughout this record:** Supabase work is `parent-control-staging` /
`dzonzgngwxclhfnvxtvu` **only**. Production is not a target for any action. Recorded as **C2b** in
[00](00-stage2-execution-plan.md) §1 and **R-43** in [04](04-risks-rollback-approvals.md) §1.
**Verdict:** `READY WITH RECORDED LIMITATIONS` (§8).

This file changes no status anywhere else — it *reports* the statuses that the edited documents now carry, and each
claim cites the file that demonstrates it.

---

## 1. Phase 1 — exact identifiers of the two created shells

| Surface | Field | Value | Label |
| --- | --- | --- | --- |
| Supabase | Project name | `parent-control-staging` | VERIFIED |
| Supabase | Ref / URL | `dzonzgngwxclhfnvxtvu` / `https://dzonzgngwxclhfnvxtvu.supabase.co` | VERIFIED |
| Supabase | Region | `ap-northeast-2` — Northeast Asia (Seoul), not selectable after creation | VERIFIED |
| Supabase | Plan / compute | Free / NANO | VERIFIED |
| Supabase | Organisation | `symqztrmaziuwdibcfrq`, single owner `spg7753@gmail.com` | VERIFIED |
| Supabase | Status | `Healthy` (unpaused) at 2026-11-02T07:16Z | VERIFIED |
| Supabase | Contents | 0 tables in `public`, `No migrations`, `No branches`, `No backups`, 0 Edge Functions | VERIFIED |
| Supabase | `auth.users` | grid empty, page prints `Total: 10 users (estimated)` | **NOT VERIFIED** (FX-18 / R-42) |
| Firebase | Display name | `haven-staging` | VERIFIED |
| Firebase | Project ID | `haven-staging-46822` (the bare stem was globally taken; name ≠ ID) | VERIFIED |
| Firebase | Project number | `381273275501` | VERIFIED |
| Firebase | Plan | Spark | created-state record only; **NOT VERIFIED** this pass (plan page redirects to overview) |
| Firebase | Analytics | Off, as instructed | VERIFIED |
| Firebase | Gemini assistance | Off — a disclosed least-privilege deviation from the wizard defaults | VERIFIED |
| Firebase | Environment type | `Unspecified` (left deliberately) | VERIFIED |
| Firebase | Apps / credentials | **zero apps, therefore zero configs and zero credentials** | VERIFIED |

Evidence: [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2–§3 (creation) and
[S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1–§2 (re-confirmation).

**No document in Stage 2 claims, and this pass created no basis for claiming:** schema loaded, sentinel present,
secrets present, test principals created, Firebase app registered, FCM configured, credential issued, Edge Function
deployed, patch applied. Each of those is asserted absent in [README](README.md) "One-line status per work item" and in
[approval-package-v2](approval-package-v2-ratification-and-forward.md) §1.

---

## 2. FX-01 … FX-18 reconciliation matrix

Source of the backlog: [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §I. Statuses below are verified by reading the
target files after the edit, not by trusting the edit report.

| FX | Required correction | Status | Where it is now visible |
| --- | --- | --- | --- |
| FX-01 | Status lines saying "no project exists / read-only only" → `G6-a EXECUTED (shell only)`, plus disclosure of the browser **write** actions | **APPLIED** | [00](00-stage2-execution-plan.md):3-14 status table + retained "superseded (kept as history)" sentence; [01](01-staging-project-proposal.md) title/status; [04](04-risks-rollback-approvals.md):3-28 status block, original wording retained under `Superseded (retained as history)`; [05](05-validation-plan.md):5,8; [README](README.md):3-16; [approval-package-a0-a2.md](approval-package-a0-a2.md) banner |
| FX-02 | Every "no Firebase action in Stage 2" statement qualified to "project creation only, under owner instruction; no app, credential, FCM or config change" | **APPLIED** | [00](00-stage2-execution-plan.md):214 (`AWAITING RETROSPECTIVE RATIFICATION`); [02](02-findings-to-fix-mapping.md) §4; [04](04-risks-rollback-approvals.md):342 + §3.1; [01](01-staging-project-proposal.md):199-201; [README](README.md) G2/G7 row. Historical assertions left in place **marked**, not deleted |
| FX-03 | Slot arithmetic → `2 active / 2 used / 0 remaining`; R-32/R-33 and U-08/U-09 resolved by the creation record | **APPLIED** | [00](00-stage2-execution-plan.md) D-12; [01](01-staging-project-proposal.md); [04](04-risks-rollback-approvals.md):142,168,371; [06](06-redteam-resolution.md) J-19 and J-23; parts/A and parts/I addenda; re-confirmed 2026-11-02 in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1.3 |
| FX-04 | Usage rows: log ingestion 0.20 GB, egress 0.14 GB | **APPLIED** | [01](01-staging-project-proposal.md):136-139 with the S2-CREATE-01 §2.5 citation; [approval-package-v2](approval-package-v2-ratification-and-forward.md):43. The superseded package's stale `0.12` at :31 is now called out in its banner instead of being rewritten |
| FX-05 | CHANGELOG: add the creation entry; fix row #11 which claimed a P01 correction that had not happened; verify/delete the root-README claim; qualify the screenshot claim | **APPLIED** | [CHANGELOG](CHANGELOG.md):8-33 (S2-OPS-01), :35-43, :45-57, :59+ (S2-DOC-02); row #11 reworded to "recorded as D-01; 03:135 not yet corrected — OPEN"; the root-README "pointer exists" claim corrected after grep proved none; screenshot wording qualified |
| FX-06 | S2-CREATE-01: name A0/A2 in the non-approval list; reconcile "no settings change" with the two wizard settings moved off default; add UTC window; soften the absolute "no image exists" | **APPLIED** | [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md):18-21 and §5 — instruction ≠ approval, `create + two wizard settings moved off default`, ratification line, auto-pause deadline, qualified screenshot wording |
| FX-07 | 00 §3: split shell/sentinel from load/verify; delete the duplicate G6-c/G3-c load; put the load behind A3 and the capture behind A1 | **APPLIED** | [00](00-stage2-execution-plan.md) §3 — thirteen ordered steps (a–l), duplicate removed, gates corrected; §9 addendum rows FX-07/FX-08 |
| FX-08 | Approval package: move secrets from A2 to A9; add the settings clause; retire the signature block; replace with ratification + a forward **A2′** | **APPLIED** | New [approval-package-v2](approval-package-v2-ratification-and-forward.md): §2 RATIFY/REVERSE decision, §3 seven independent blocks (A0, A1, A2′, A3, A5, A9, A12) each with *authorises / does NOT authorise / preconditions / evidence / stop conditions* and a **blank** signature labelled "owner decision — not signed by this document"; §4 boundary table; §7 partial-signature consequences. The old package is banner-marked `SUPERSEDED — DO NOT SIGN` with the falsified lines named at current numbering |
| FX-09 | 02: E14 → `PROPOSED — NOT APPLIED`; E11 scoped to "wholly"; E3 single tier | **APPLIED** | [02](02-findings-to-fix-mapping.md):38 (`only finding blocked *wholly* on a missing capture`), :41 (E14 `PROPOSED — NOT APPLIED`), E3 tier single `D` |
| FX-10 | 05 arithmetic: 21→20, 39→38, TE enumeration, 104 vs 108 | **APPLIED** | [05](05-validation-plan.md):204 (5+9+6=**20**, "the previously printed 21 was an off-by-one"), :206-207 (104 = 19 TE + 78 PE + 7 CI; 108 = 104+4), :211 (20+19−1=**38**); `start_utc`/`end_utc` mandatory in every run record (:176, :196) |
| FX-11 | Tier/label and approval-range corrections; F5 in the C8 order | **APPLIED** | [00](00-stage2-execution-plan.md) §6 and §2 (Tier C, four others E8/E9/E10/E12; F5 added), C8; [README](README.md):23 `A0–A3, A5–A13 (no A4 in the plan of record)`; parts/B addendum labels its historical "A4" as a CLI migration-repair approval that is **not** in the plan of record |
| FX-12 | patch-defects: the false "nowhere in the repository", the mis-attributed 04 §2.2 citation, the S3 tallies | **APPLIED** | [patch-defects-before-a5.md](patch-defects-before-a5.md):143-155 — replaced by `absent from the patch file; present as Stage 1 prosrc captures at g1-b3b-20261029.json:149/155/159/165` (metadata `62/67/78`); attribution corrected to 06 J-04; tallies recounted at :22-35 (P01 3/1/3, P02 4/1/4, P03 2/1/2; S1=9, S2=3, 7 S3 defects over 9 file revisions); closing table :294-333 gives one row per D-01…D-12 + D-10b and the three unchanged hashes |
| FX-13 | 03:135 two rows/function and four total; sql:60 wording; D-02 two-pass commit gate; T3 relabelled | **APPLIED (documentation only)** | [03](03-patch-S2-P01.md):135 `2 rows per function (owner + PUBLIC), **4 rows total**` with the note that the SQL is unmodified and the hash unchanged; §5.1 two-pass execution at :162-181; :194 T3 = `INVARIANT control — not a discriminating test`, removed from the §9 stop list; D-04 disambiguated to the SQL file's own `SECTION 2 - ROLLBACK` (sql:176). **D-01/D-02/D-03 remain `OPEN`** as re-check items — no defect is marked fixed |
| FX-14 | Evidence supersession addenda | **APPLIED (append-only)** | [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md):129-141, [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md):56-67 + header :9 `SCREENSHOT EVIDENCE: NOT VERIFIED`, [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md):242-255, [S2-REVIEW-02](S2-REVIEW-02-independent-audit.md):430-444, [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md):459-471 + citation corrections :239-250. No prior observation was deleted or rewritten |
| FX-15 | Working-paper banners and per-file dated corrections | **APPLIED — 10 of 10** | Every `parts/*.md` opens with `WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02)` and closes with `## Addendum — S2-DOC-02 status correction (2026-11-02)`. Withdrawn in the addenda: parts/A's F4 validation, parts/B's platform-backup restore and A-number collision, parts/G's "G5-S Runnable"; parts/D and parts/E carry the real prosrc locations with D-05/D-10 OPEN; parts/I runs R-01…R-43 and records the withdrawn delete-and-re-create branch; parts/J records the 2/2/0 arithmetic, J-23 and the stale step references. [README](README.md):42-44 points to them |
| FX-16 | Risk register: add R-36…R-41, mark R-09/R-30 realised, retire R-32/R-33, raise viewport severity, record the auto-pause start when known | **APPLIED** | [04](04-risks-rollback-approvals.md) §1 rows R-36…R-41 (and the two added from the re-confirmation, R-42/R-43), :27-28 revision note, register range :41 **R-01…R-43**; §2.4 delete→re-create branch **withdrawn**; §2.5 deadline ≤2026-11-06 with the paused-project slot cost `NOT VERIFIED`; §3.1 executed-action reconciliation |
| FX-17 | Architecture: state once that Supabase Auth is the identity authority and Firebase is FCM-transport-only | **APPLIED** | [01](01-staging-project-proposal.md):187-197 "Service topology (explicit)" 7-row table; [../stage1/02-architecture.md](../stage1/02-architecture.md) **§9 addendum** (append-only; §1–§8 untouched) restating rows 1–7 with citations and recording that the `haven-staging-46822` shell now exists while changing none of the topology. Basis: all 9 Edge handlers call `db.auth.getUser(token)`; `firebase/SETUP-CHECKLIST.md:16` says leave Firebase Auth disabled; no Firestore/Cloud Function/Analytics use is assumed; **no Firebase service was enabled by this pass** |
| **FX-18** *(new, from the re-confirmation)* | The empty-shell premise is unproven for `auth.users` | **RECORDED, NOT RESOLVED** | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3; claims downgraded to `NOT VERIFIED` in [01](01-staging-project-proposal.md) row 1, [05](05-validation-plan.md) glossary, [README](README.md) "cannot claim", [approval-package-v2](approval-package-v2-ratification-and-forward.md) §1.1; resolution made the **first statement of the A3 window** with a non-zero count stopping the load (approval-package-v2 §3.4 preconditions); risk **R-42** |

**Not claimed anywhere in this pass:** that any D-01…D-12 defect is *fixed*. Corrected **document text** is recorded as
`OPEN (document corrected, re-check required)`; the seven defects that need a patch-file revision are untouched,
because no approval permits editing those files.

---

## 3. Phases 2–6 — did the required outcomes actually change

| Phase | Requirement | Outcome |
| --- | --- | --- |
| 2 | Apply FX-01…FX-06 | Done; each row above cites the line that now carries it |
| 3 | Reissue approvals; A2′ must **not** include schema load or secrets; creation must **not** imply Firebase app registration | [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.3 (A2′ = sentinel + approved settings only) and §4 boundary table answer all three; §2 frames the creation as **an executed action awaiting retrospective ratification**, not a future authorisation; the old package cannot be signed |
| 4 | Correct the plan sequence and gates | A1 gates the production catalogue capture, A3 gates the staging load, duplicates removed ([00](00-stage2-execution-plan.md) §3, §9) |
| 5 | Backlog FX-07…FX-17 | All applied; nothing in that range is left described as pending |
| 6 | Make the topology explicit, enable no Firebase service | Done (§2 FX-17). **Zero Firebase products are enabled** — re-confirmed from the console's product navigation, which still lists only Overview and Settings ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §2.1) |

---

## 4. List of modified files

**Stage 2 (31 markdown files in `docs/stage2/`), touched 2026-11-02 by this programme:**

`00-stage2-execution-plan.md` · `01-staging-project-proposal.md` · `02-findings-to-fix-mapping.md` ·
`03-patch-S2-P01.md` · `04-risks-rollback-approvals.md` · `05-validation-plan.md` · `06-redteam-resolution.md` ·
`README.md` · `CHANGELOG.md` · `S2-REVIEW-02-independent-audit.md` · `S2-REVIEW-03-independent-audit.md` ·
`approval-package-a0-a2.md` · `patch-defects-before-a5.md` ·
`evidence/S2-CREATE-01-new-projects.md` · `evidence/S2-INSP-01-supabase-org-slots.md` ·
`evidence/S2-INSP-02-firebase-console.md` · `evidence/S2-NEXT-01-readiness-report.md` ·
`parts/A…J` (all ten)

**Created by this programme:**

`approval-package-v2-ratification-and-forward.md` · `evidence/S2-CREATE-01-new-projects.md` ·
`evidence/S2-INSP-03-read-only-reconfirmation.md` · `S2-REVIEW-03-independent-audit.md` · this file

**Outside `docs/stage2/`:** one file, append-only —
[`docs/stage1/02-architecture.md`](../stage1/02-architecture.md) §9 (FX-17 required the architecture record; §1–§8 are
byte-identical, no Stage 1 observation was altered). Disclosed here because Stage 1 is the authoritative baseline and a
Stage 1 edit should not pass unnoticed.

**Never touched:** `docs/stage2/patches/*.sql` (§6), any application source, any file under `firebase/` other than
reads, and every Stage 1 evidence capture.

### Hashes and mtimes at delivery (first 16 hex chars; full digests on request)

| File | SHA-256 (prefix) | mtime |
| --- | --- | --- |
| `00-stage2-execution-plan.md` | `cc86bfb39dd3f9f2` | 11-02 13:33 |
| `01-staging-project-proposal.md` | `72a51a63ee9a432c` | 11-02 12:57 |
| `02-findings-to-fix-mapping.md` | `64bedb971091846e` | 11-02 10:50 |
| `03-patch-S2-P01.md` | `afe285a174a5ba64` | 11-02 12:06 |
| `04-risks-rollback-approvals.md` | `655513e564a3353c` | 11-02 13:27 |
| `05-validation-plan.md` | `eefd51d9f27c98fa` | 11-02 12:57 |
| `06-redteam-resolution.md` | `0503086d7486cc78` | 11-02 10:25 |
| `CHANGELOG.md` | `4a45f6c4d8075a41` | 11-02 13:32 |
| `README.md` | `71e462ad2fd8e370` | 11-02 13:31 |
| `S2-REVIEW-02-independent-audit.md` | `3db046718e7e44eb` | 11-02 12:40 |
| `S2-REVIEW-03-independent-audit.md` | `dbaf5015634f4fde` | 11-02 12:38 |
| `approval-package-a0-a2.md` | `767c18d2983087cf` | 11-02 12:54 |
| `approval-package-v2-ratification-and-forward.md` | `29767b5ad0e2da04` | 11-02 12:58 |
| `patch-defects-before-a5.md` | `570487be2de7298a` | 11-02 12:02 |
| `evidence/S2-CREATE-01-new-projects.md` | `cf1cbc15636232ff` | 11-02 11:19 |
| `evidence/S2-INSP-01-supabase-org-slots.md` | `9ef9948fb6b20702` | 11-02 12:35 |
| `evidence/S2-INSP-02-firebase-console.md` | `fe85c7e975f28edd` | 11-02 12:36 |
| `evidence/S2-INSP-03-read-only-reconfirmation.md` | `9377b56eb692c441` | 11-02 13:30 |
| `evidence/S2-NEXT-01-readiness-report.md` | `5e4bed7b069476ce` | 11-02 12:36 |
| `parts/A-staging-spec.md` | `1a9b28adb4947fdc` | 11-02 12:49 |
| `parts/B-g3-dashboard-baseline.md` | `307afaa3a3a5bc2e` | 11-02 12:49 |
| `parts/C-e2-f8.md` | `fa12b99f644514aa` | 11-02 12:50 |
| `parts/D-e3-f7-e1.md` | `6e692011d275c999` | 11-02 12:52 |
| `parts/E-e4-session-invariant.md` | `c38344b4ba3a50d2` | 11-02 12:52 |
| `parts/F-e6-e7.md` | `d67cffd426692e05` | 11-02 12:53 |
| `parts/G-g5-validation.md` | `499f1afb77670448` | 11-02 12:54 |
| `parts/H-app-preservation.md` | `9cd6c3e42ef30c6e` | 11-02 12:54 |
| `parts/I-risks-rollback-approvals.md` | `f923d9cf9ee53920` | 11-02 12:55 |
| `parts/J-redteam.md` | `441ebf81c769c21e` | 11-02 13:28 |

This file (`S2-DOC-02-reconciliation.md`) is the only Stage 2 document not in the table: it is written last and its own
digest cannot be listed alongside itself.

---

## 5. Git diff — and why it is empty (provenance gap, disclosed)

```
$ git -C D:\control log --oneline
fatal: your current branch 'master' does not have any commits yet

$ git -C D:\control rev-list --count HEAD
fatal: ambiguous argument 'HEAD': unknown revision or path in the working tree

$ git -C D:\control diff --stat
(empty — no baseline exists)

$ git -C D:\control status --short
?? .env.example
?? .gitignore
?? README.md
?? docs/
?? firebase/
```

**The repository has zero commits.** Every file, including all of `docs/stage1` and `docs/stage2`, is **untracked**.
Therefore:

- `git diff` cannot show this pass's edits and **no `git diff` patch can be delivered**. The §4 hash/mtime table is the
  substitute evidence, and it is weaker: it proves content **now**, not content **before**.
- Nothing in this programme can be reverted with Git. There is no prior blob to restore.
- The patch-file hashes in §6 are the only integrity anchor for the SQL, and they are anchored to values recorded in
  documentation inside the same unversioned tree — a circularity the owner should close.
- **Recommendation (owner action, not taken here):** make an initial commit of the current state before any dashboard
  work starts, so that every later change — documents and SQL alike — has a diffable baseline. This is a local,
  reversible action; it was not performed because creating a commit was outside this brief's scope.

---

## 6. Patch integrity — three files, unchanged

```
1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51  patches/S2-P01-e2-f8.sql
01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67  patches/S2-P02-e3-actor-binding.sql
8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4  patches/S2-P03-e4-session-invariant.sql
```

Recomputed at delivery and **byte-identical to the values recorded before this pass began**
([patch-defects-before-a5.md](patch-defects-before-a5.md) closing table; [03](03-patch-S2-P01.md):178). Every FX-13
change is in the review documents, never in the SQL. All three patches remain `PROPOSED — NOT APPLIED`, and each would
still self-abort at its sentinel gate against a project that has no sentinel.

---

## 7. Confirmation: no operational action occurred

| Prohibited / not-yet-authorised action | Occurred in this pass? |
| --- | --- |
| SQL, DDL or DML executed against **any** project | **No** |
| Any patch applied or modified | **No** (§6 hashes unchanged) |
| Schema loaded, sentinel created, settings changed | **No** |
| Secret, key, token or credential created, read, rotated or copied | **No** |
| Project created, deleted, paused or resumed | **No** — only pre-existing projects viewed |
| Production modified in any way | **No**. One production page was read read-only (Auth → Users aggregate total) *before* the staging-only constraint was issued; disclosed in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) and in [README](README.md); not repeated |
| Firebase app registered, Analytics / Auth / Firestore / FCM / Hosting enabled | **No** — console product navigation still lists only Overview and Settings |
| Edge Function deployed or exported | **No** |
| Supabase CLI, Firebase CLI, PowerShell, curl, REST, DevTools | **No** |
| Application source modified | **No** |
| Any approval signed, dated or accepted on the owner's behalf | **No** — every signature line in [approval-package-v2](approval-package-v2-ratification-and-forward.md) is blank by design |
| Browser consoles opened | **Yes — this is the one deviation from the brief's letter.** Strictly read-only page views at 2026-11-02T07:16Z, made under the owner's explicit typed instruction ("use browser access on supabase and firebase not use cli"), which conflicts with the brief's "No Supabase Dashboard / No Firebase Console" line. The conflict was resolved toward the owner's later, narrower instruction and the state of the world (the constraint that actually matters is *no writes*). One idempotent click (`Refresh` on an already-displayed read-only list) was attempted and **failed** with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`; it had no effect. No state-changing control was activated. [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §5–§6 lists every control seen and not used |

**What the re-confirmation changed:** it produced evidence (both shells unpaused and empty; slots 2/2/0; meters
unchanged; zero apps) **and one new problem** (FX-18/R-42). It did not resolve, configure or advance anything.

---

## 8. Final verdict

### `READY WITH RECORDED LIMITATIONS`

**Why not `NOT READY — CORRECTIONS REQUIRED` any more.** That verdict's grounds were, item by item: false status lines,
an unusable approval package, an un-gated load, and an unreconciled execution. All four are closed in documentation —
FX-01…FX-17 are applied and each is cited to the line that now carries it (§2); the plan of record agrees with
[S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md); the retired package is marked do-not-sign with its falsified
lines enumerated; A2′ excludes schema load and secrets; the sequence gates capture on A1 and load on A3.

**Why not `READY FOR OWNER REVIEW` in the stronger sense.** Three limitations are substantive, not cosmetic, and this
pass cannot clear any of them:

1. **Owner decision outstanding — nothing downstream may start.** The 2026-10-30 creation is unratified and A0 has
   never been approved by anyone. [approval-package-v2](approval-package-v2-ratification-and-forward.md) §2 presents
   RATIFY or REVERSE with the exact amended A12 sentence under RATIFY; §3 has seven independently signable blocks. Zero
   of the four single-owner compensating controls is satisfied for the one action actually executed.
2. **FX-18 / R-42 is open by design.** `auth.users` emptiness is unproven, and the honest fix is an approved read-only
   count inside the A3 window against `dzonzgngwxclhfnvxtvu` — not a document edit. It was deliberately *not* run here.
3. **Provenance and evidence gaps persist.** Zero commits, so no diff baseline (§5); no platform screenshots and no
   platform audit log (viewport instability is reproducible, R-viewport); the Firebase plan label was not re-confirmed;
   the auto-pause clock has no recorded start, so the **2026-11-06** deadline is approximate — the nearest real
   constraint in the programme, with roughly four days of margin at delivery.

**What the owner is being handed:** accurate documents, a signable approval package that is entirely blank, three
untouched patch files with verified hashes, one dated re-confirmation record, two new risks (R-42, R-43) and the
standing scope constraint that all Supabase work targets `parent-control-staging` alone.

**Stop condition met.** The documentation pass is complete. No dashboard operation, no SQL, no patch, no setting change
and no approval signature follows without an explicit owner instruction — and any such Supabase instruction will be
executed against `dzonzgngwxclhfnvxtvu` and no other project.

---

## Addendum — superseded by the S2-EXEC-03 pass (2026-11-02, documentation only)

This record is left exactly as delivered. Two of its statements are now **closed rather than outstanding**, and the
closure came from an owner decision recorded later the same day — not from a new judgement by this pass:

| Statement in this file | Status after S2-EXEC-03 |
| --- | --- |
| The 2026-10-30 creations are `AWAITING RETROSPECTIVE RATIFICATION` (§2 FX-02 row; §3 item 3) | **`RATIFIED — 2026-11-02 — OPTION (i)`**, recorded in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1; A12's prohibition amended to "project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited." **Every physical signature fence is still blank**, and the ratification grants nothing forward (correction C-5) |
| "a signable approval package that is entirely blank" | Still literally true — **zero fences filled**. The approval *decisions* are now recorded for A0 and A5 (A5 approved but not executable); A2′, A3, A9 and A12 remain unrecorded |
| §8 item 2: the `auth.users` count is "an approved read-only count inside the A3 window" | **Confirmed as scope by owner decision B-3 (option A)** — the count is inside A3, and A3 is unsigned, so it is **still unrun and `NOT VERIFIED`** (corrections C-2/C-4) |
| §8 item 3: "R-viewport" / capture-channel wording for the evidence set | Qualification applied per **C-9**: accessibility-tree labelling is not extended to [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md) (not labelled as such; screenshot `NOT VERIFIED`) or to [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) (local display, **no UTC conversion**) |

**One correction to this addendum, made in the same pass:** the sentence above claiming "Two of its statements are now
closed" undercounted — **three** are: (1) the ratification, (2) the FX-18 count's approval home, and (3) **C-6's register
gap**, where [04](04-risks-rollback-approvals.md) §1 claimed the range R-01…R-43 while no R-41 row existed; the row is now
added **from its existing definitions** (S2-REVIEW-03 §I and parts/I), not invented. Changelog lines in this file that
still read "R-01…R-41" are point-in-time records and are left as written.

No operational action occurred in either pass. The next permitted actions are listed in
[S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md) §"next permitted action".
