# S2-EXEC-05 — A3 readiness assessment (the A3 readiness matrix)

**Record ID:** S2-EXEC-05
**Delivered:** 2026-11-02 (offline pass; no platform clock consulted, so this line is not a UTC-stamped platform record)
**Domain:** whether the offline G3 reconstruction artefact at `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\` may
legitimately be put in front of the owner for an **A3 (staging schema load)** decision, and what still blocks A3.
**Verdict:** `NOT LOAD-READY — RECONSTRUCTION GAPS` (§8).

| | |
| --- | --- |
| **Class** | Offline, repository-only audit. Read-only file inspection; local shell read commands only. |
| **Operational actions performed** | **ZERO.** No Supabase dashboard, no Firebase console, no browser, no CLI, no API, no REST, no DevTools, no database connection, no SQL of any kind, no migration, no load, no settings change, no secret read or created. Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was not opened, read or referenced as a target at any point. |
| **Specifically not done** | The `auth.users` count was **not run**; the sentinel was **not created**; nothing was **loaded**; the auto-pause deadline was **not touched** (§6). |
| **Files created / modified by this pass** | **One** — this file. Nothing else was written: not the artefact, not `docs/stage2/patches/*`, not any authoritative plan document, not any `S2-EXEC-04-*` file. |
| **Approvals** | **No owner approval block was filled, signed, pre-filled or drafted by this document.** The 2026-10-30 creation, the ratification, A0, A5 and every other recorded owner decision are read as *records*, and none of them is treated as permission for an unsigned operation (rule of [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :11-12`, [04](04-risks-rollback-approvals.md) R-29 at ` :87`). |
| **Not measured here** | SQL structure, function semantics and hashes belong to other auditors. Where their reports are needed and not published, the dependency is marked **PENDING**, never assumed. A concurrent `S2-EXEC-04-a3-precondition-matrix.md` exists in this directory; per this pass's rules it is **not read as authority and not cited**, and its domain is treated as **PENDING**. |

---

## 1. Established state, verified against the documents (not restated from assumption)

| Item | State as documented | Citation |
| --- | --- | --- |
| 2026-10-30 creation | `RATIFIED — 2026-11-02 — OPTION (i)`; **grants nothing forward**; the §2 fence is unfilled | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :118-127`, fence ` :144-159`, fence-state note ` :161-163`; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §` :33-64`; [04](04-risks-rollback-approvals.md)` :235-237` |
| A0 | **APPROVED as a recorded decision**, method amended to offline reconstruction from the in-repo `g1-*`/`g1-b3b` capture; physical fence unfilled | [00](00-stage2-execution-plan.md)` :86`, ` :173-178`; [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.1 ` :175-206`; [04](04-risks-rollback-approvals.md)` :209` |
| A1 | **`INOPERATIVE`** under the staging-only absolute (F-5-A / C2b); void in substance, not merely unsigned; **removed from A3's precondition chain** | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :211-219`; [00](00-stage2-execution-plan.md)` :87`, ` :109-115`, ` :165`; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :126-135`; [04](04-risks-rollback-approvals.md)` :210` |
| A2′ | Split into **(a) sentinel BEFORE A3** and **(b) settings + Realtime publication AFTER A3** (owner "Sequence A" on B-2); **UNSIGNED**, fence unfilled | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :68-96`; [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :245-280`; [00](00-stage2-execution-plan.md)` :91-92`, ` :142-147`; [04](04-risks-rollback-approvals.md)` :212` |
| A3 / A9 / A12 | **UNSIGNED** (fences ` :300`, ` :344`, ` :366` blank) | [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4/§3.6/§3.7; [04](04-risks-rollback-approvals.md)` :212`, ` :217`, ` :220`; [README](README.md)` :86` |
| A5 | **APPROVED but NOT EXECUTABLE** (P02 aborts by D-07; P03 blocked on a production read A1 can no longer authorise) | [00](00-stage2-execution-plan.md)` :94`, ` :216-220`; [04](04-risks-rollback-approvals.md)` :213`; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :166`, ` :179-184` |
| Signature fences | **Zero filled anywhere.** Every `OWNER (name)` line in both packages is blank underscores only (8 blocks in v2, 2 in the superseded package); a repo-wide scan for a non-blank `OWNER (name):` returns nothing | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :156, 203, 240, 277, 300, 322, 344, 366`; [approval-package-a0-a2.md](approval-package-a0-a2.md)` :93, 141`; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md) residual R-4 ` :205` |
| FX-18 `auth.users` count | Sits **inside A3's window** as its first statement (owner decision B-3, option A); **unrun**, and its subject fact `NOT VERIFIED` | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :99-118`; [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :288`; [04](04-risks-rollback-approvals.md)` :100` (R-42); [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :94-98`, ` :141-181` |
| Blockers B-16 / B-17 | B-16 (A3 chain unsatisfiable as written) and B-17 (no complete baseline for 24 functions) | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :216-217`; B-16 closed in documentation by C-2 ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :42`); B-17 stands |
| Staging target | `parent-control-staging` / `dzonzgngwxclhfnvxtvu` **only**; production is not a fallback and not a read target | [00](00-stage2-execution-plan.md)` :41` (C2b); [04](04-risks-rollback-approvals.md)` :101` (R-43, exception closed by C-2); [README](README.md)` :30-37` |
| Free plan | **No backups, no PITR**; `No backups` re-observed 2026-11-02 | [04](04-risks-rollback-approvals.md)` :93` (R-35); [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :38` |
| Slots | **2 active / 2 used / 0 remaining**; delete-and-re-create branch withdrawn | [00](00-stage2-execution-plan.md)` :297` (D-12); [04](04-risks-rollback-approvals.md)` :96` (R-38), ` :158-165` (§2.4 step 3); [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :78-81` |
| Last authorised read-only observation | 2026-11-02T07:16Z, single session 07:16Z–07:19Z, page views by URL | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :4`, §1–§2 |

---

## 2. The A3 readiness matrix

Status vocabulary is [00](00-stage2-execution-plan.md)` :31`: `MET` / `NOT MET` / `NOT VERIFIED` / `NOT APPLICABLE`.
The last column answers: **OFFLINE-ONLY** (closable from evidence already in the repo), **NEW EVIDENCE** (needs a
capture or read that does not exist), or **SIGNATURE** (needs an owner approval/decision).

| # | Gate | Current documented authority + citation | Required state for a legitimate A3 decision | Status | Deciding evidence | What would change the state | Type of change |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **A0 — G3 method amendment** | APPROVED 2026-11-02 as a **recorded decision**, method = offline reconstruction from the in-repo `g1-*`/`g1-b3b` capture (C-1); fence physically unfilled — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :175-206`; [00](00-stage2-execution-plan.md)` :86`, ` :173-178`; [04](04-risks-rollback-approvals.md)` :209` | A method exists that produces the artefact without a production read, and its disclosed limits are accepted | **MET** (as a recorded decision) **— fence NOT MET** | The artefact was built under it on 2026-11-02: 10 components + assembled file, `91-coverage.md` table ` :9-31`; limits disclosed verbatim at [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :189` | If the owner treats an unfilled fence as no approval (R-29 permits that reading), A0 reverts to `NOT MET` and G3 becomes `BLOCKED — METHOD NOT PERMITTED` (R-14) | **SIGNATURE** (only to move from "recorded" to "signed") |
| 2 | **A1 — production read-only capture** | `INOPERATIVE` — void in substance under the staging-only absolute; explicitly **removed from A3's chain** — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :211-219`; [00](00-stage2-execution-plan.md)` :87`, ` :109-115`; [04](04-risks-rollback-approvals.md)` :210` | Not a precondition of A3. Must stay un-executed | **NOT APPLICABLE** to A3 (and **NOT MET** as an executable approval) | Signing it would authorise prohibited production access; nothing in the A3 chain requires it | Nothing inside Stage 2 re-activates it; only a **new owner ruling** amending C2b/F-5-A | **SIGNATURE** (owner decision to rescope) + **NEW EVIDENCE** |
| 3 | **A2′(a) — sentinel BEFORE the load** | UNSIGNED, NOT CREATED; Sequence A — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :245-280`; [00](00-stage2-execution-plan.md)` :92`, ` :135`, ` :142-153`; [04](04-risks-rollback-approvals.md)` :212`; absence verified 0 tables — [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :85`, ` :194` | Signed **and executed** before any DDL; A3's stop condition 1 (§8 of [00](00-stage2-execution-plan.md)` :306`) depends on it | **NOT MET** | `private.s2_environment` is recorded `NOT CREATED` ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :41`); every patch self-aborts without it ([patches/S2-P02](patches/S2-P02-e3-actor-binding.sql)` :14-25`) | Owner signature on A2′ **plus** execution inside a window — and the executability defect **S5-BL-01** (§5) closed first: the sentinel needs a `private` schema that A2′ does not authorise and whose absence on staging is itself unproven | **SIGNATURE** + **NEW EVIDENCE** (read-only staging schema list) |
| 4 | **A2′(b) — settings checklist + Realtime publication AFTER the load** | UNSIGNED; structurally impossible before A3 (a publication cannot reference absent tables) — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :250-259`, ` :272-274`; [00](00-stage2-execution-plan.md)` :91`; [04](04-risks-rollback-approvals.md)` :212` | Signed, then executed after A3 with its own evidence | **NOT MET** | 0 tables in `public` ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :85`); publication membership never captured, `INFERRED FROM DOCUMENTATION` only (`g3-build/91-coverage.md` ` :28`; `80-realtime-publication.sql` ` :14-24`) | Owner signature; execution is a separate post-A3 action. Note it is **not** an A3 precondition — it is an A3 *successor* | **SIGNATURE** |
| 5 | **A3 — staging schema load** | UNSIGNED; annotated "the artefact it would load is NOT load-ready … this fence must not be filled on the assumption that a baseline exists" — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :282-304`; [00](00-stage2-execution-plan.md)` :90`, ` :168`; [04](04-risks-rollback-approvals.md)` :212` | A signed block **and** an artefact whose load produces something the plan treats as a baseline | **NOT MET** | The fence at ` :300` is blank; the artefact itself measures 0 executable function/trigger/policy/publication statements (`g3-build/90-limitations.md` ` :16-28`, `91-coverage.md` ` :14-28`, `96-review-checks.md` checks 21/23/25) | Signature alone does not close it — see rows 7–9. A meaningful A3 needs the reconstruction gaps closed, which needs a production read class that is currently prohibited | **SIGNATURE** + **NEW EVIDENCE** |
| 6 | **FX-18 `auth.users` count** | Owner decision B-3 (option A) places `select count(*) from auth.users;` on `dzonzgngwxclhfnvxtvu` as the **first statement inside A3's window**; A3 unsigned ⇒ unauthorised and **unrun** — [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :99-118`; [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :288`; [04](04-risks-rollback-approvals.md)` :100`; [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :175-181` | The count executed with ref echoed + UTC timestamps before any DDL; `0` clears FX-18, non-`0` stops the load | **NOT MET** (approval absent) **and** its subject fact **NOT VERIFIED** | No record anywhere contains an executed count; the dashboard prints `Total: 10 users (estimated)` over an empty grid ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :96-98`) | Signing A3 and running it inside the window. This pass did **not** run it and nothing here authorises running it | **SIGNATURE** + operational read (not offline-resolvable) |
| 7 | **G3 reconstruction sufficiency** | Built under approved A0 on 2026-11-02; artefact's own verdict `NOT LOAD-READY`; [README](README.md)` :89`; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :230`, ` :235` | An artefact that, loaded, yields a baseline against which patches and equivalence can be proven (the A0 objective: "a restorable schema baseline proven equivalent to production", [00](00-stage2-execution-plan.md)` :171-173`) | **NOT MET** | Measured in-artefact: 459 active statements, **0** functions / **0** triggers / **0** policies / **0** publication statements; 38 of 38 return types absent; 24 of 38 bodies absent (`g3-build/90-limitations.md` ` :16-54`, `91-coverage.md` ` :14-21`, `93-counts.json` ` :15`); 6 of 48 review checks FAIL/BLOCKED (`96-review-checks.md` ` :37, 39, 41, 43, 44, 29`) | Either (i) the owner accepts a **structural-only** baseline and accepts that G3 cannot close and G5-S cannot run, or (ii) a new production capture of return types / bodies / extensions / publication (`L-1`…`L-7`, `g3-build/90-limitations.md` ` :125-131`) — which requires rescoping C2b/F-5-A. **Not obtainable offline.** | **NEW EVIDENCE** (and a **SIGNATURE** to change the scope rule) |
| 8 | **Secret scan tied to the exact final artefact hash** | A3's precondition is "a completed secret scan of the artefact with hits reviewed and recorded" and A3's evidence requirement is "**Artefact SHA-256**, secret-scan result …" — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :288`, ` :289`; [00](00-stage2-execution-plan.md)` :89`, ` :167`, ` :181-184`; R-18 [04](04-risks-rollback-approvals.md)` :76` | One recorded digest, computed over the **exact bytes of the final artefact**, produced by the scan, so the "no hand-editing after scan" prohibition at ` :287` is enforceable | **NOT VERIFIED** | A scan exists and is honest (`95-secret-scan.md` — 13 files, 19 patterns + 3 PII classes, **0 matches**, disclosed as non-proof at ` :53-59`). But its per-file digests **do not equal** the digests in `100-file-hashes.txt` / `90-limitations.md` §9 for any file: e.g. `10-tables.sql` `53d137e3…` (`95-secret-scan.md` ` :20`) vs `16bb2387…` (`100-file-hashes.txt` ` :2`); assembled file `efdbf985…` (`95-secret-scan.md` ` :29`) vs `fc996f45…` (`100-file-hashes.txt` ` :11`). The scan hashed decoded text re-encoded as UTF-8 (`g3-build/scan_phase34.py:94-95`, a Python `hashlib.sha256` over `open(..., encoding="utf-8").read()`), while the hash file is `sha256sum` over raw bytes — **INFERRED** cause of the mismatch, not proven. The scan's 13-file list also omits 8 files in the same directory (`90`, `91`, `93`, `96`, `100`, `gen_g3.py`, `gen_scan.py`, `scan_phase34.py`), although [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :130` describes it as "every file in the build directory" | Re-run the scan over the final artefact **bytes** and record that digest alongside the `sha256sum` digest; state the hash input in the report; extend the file list to the whole directory. All of it is local file work. The byte-vs-text question should be confirmed by the hash-domain auditor — **PENDING** | **OFFLINE-ONLY** |
| 9 | **Rollback readiness** | No rollback tested anywhere in the programme; §4 item 4 `BLOCKED — rehearsal impossible on an empty schema`; §2.4 delete-and-re-create **withdrawn**; no platform restore — [04](04-risks-rollback-approvals.md)` :8`, ` :288-292`, ` :158-165`, ` :93` | An object in staging to apply, reverse and re-apply, with rehearsed rollback text | **NOT MET** | 0 tables today ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :85`); and after a hypothetical A3 load the P01/P02 objects **still would not exist** (0 functions emitted), so rehearsal remains impossible — see §4 | A3 + a *load-ready* artefact + A5 execution + a separate-time reviewer pass (R-16). B-6 as written ("A3 must complete first") is **not sufficient** — see S5-BL-06 | **SIGNATURE** (A3, A5 execution) + **NEW EVIDENCE** |
| 10 | **A9 — fresh staging secrets** | UNSIGNED; preconditions "ratification (i); **A2′ complete (settings recorded)** and, for anything the functions read, A3"; R-39 password custody `NOT VERIFIED` — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :327-347`; [04](04-risks-rollback-approvals.md)` :97`, ` :217`; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :209` | Owner signature + the custody question answered before any staging connection | **NOT MET** (and R-39 **NOT VERIFIED**) | No secret exists ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :43`); the DB password was typed owner-side with no copy in repo/record/transcript | Owner signature **plus the owner's own custody answer** (only the owner can give it). Also: the "A2′ complete" wording was not updated for the C-3 split and now implies A9 needs A2′(b), i.e. needs A3 — S5-BL-08 | **SIGNATURE** (owner-only facts; wording fix is **OFFLINE-ONLY**) |
| 11 | **A12 — Firebase / FCM work** | UNSIGNED; the amended Stage-2 prohibition ("project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited") is in force; preconditions need a **recorded G2 decision**, an identity boundary and credential-handling rules — [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :349-369`, ` :121-122`; [00](00-stage2-execution-plan.md)` :241-246`; [04](04-risks-rollback-approvals.md)` :94`, ` :220` | A signed forward block **and** the three named preconditions | **NOT MET** | No G2 decision exists in the repo (G2/G7 are deferred, [00](00-stage2-execution-plan.md)` :97`); zero apps/credentials re-confirmed ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :119`, ` :196`); FCM does not exist | Owner signature plus a recorded G2 decision; none is implied by the ratification | **SIGNATURE** |

**Counts:** `MET` 1 (A0, as a recorded decision) · `NOT MET` 8 (A2′(a), A2′(b), A3, FX-18 count, G3 sufficiency,
rollback readiness, A9, A12) · `NOT VERIFIED` 1 (secret-scan-to-hash binding) · `NOT APPLICABLE` 1 (A1 as an A3
precondition). A1 additionally scores `NOT MET` as an executable approval; the FX-18 count scores both `NOT MET`
(approval) and `NOT VERIFIED` (its subject fact) on one row.

---

## 3. Every A3 precondition the plan of record itself states

Enumerated from [00](00-stage2-execution-plan.md) §3 (` :81-98`) and §4 (` :130-184`), plus
[approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4 (` :282-304`). "Checked by whom" names the
published document that actually assessed it; **UNCHECKED** means no document in the repo assesses it.

### 3.1 Preconditions stated in `approval-package-v2` §3.4 (the operative row)

| # | Precondition (verbatim requirement) | State | Checked by whom |
| --- | --- | --- | --- |
| P-01 | **A2′(a) signed AND executed** — the sentinel must exist first | NOT MET — unsigned, not created | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :164`; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :262` |
| P-02 | A **completed secret scan of the artefact**, hits reviewed and recorded, **never silently redacted** | Partially met — scan run, 0 matches; the 24 uncaptured bodies are "unscanned and unscannable" and the artefact says so (`95-secret-scan.md` ` :56`) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md) §4 ` :128-139` |
| P-03 | **A1 is NOT a precondition** (C-2) — and no production access is authorised by A3 | Met as documentation | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :42` |
| P-04 | Artefact reconstructed under **approved A0 as amended by C-1** | Met (recorded decision) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md) §3 |
| P-05 | **A3 itself signed** | NOT MET | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :302-303` |
| P-06 | **First statement of the window:** `select count(*) from auth.users;` on `dzonzgngwxclhfnvxtvu`, recorded **with the project ref and UTC timestamps** | NOT MET (unauthorised, unrun) | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §3 |
| P-07 | If the count ≠ 0 → **STOP**; explain the discrepancy before a single DDL statement; P01 §0.4 `4 rows total` and every "wrong-project run is impossible" argument are void | NOT MET — conditional control, cannot be exercised | [04](04-risks-rollback-approvals.md)` :100` (R-42) |
| P-08 | **No other project** may be used for that check | Met as a rule; binding (C2b/R-43) | [00](00-stage2-execution-plan.md)` :41` |
| P-09 | **Evidence required:** artefact **SHA-256**, secret-scan result, per-statement **restore log**, equivalence table with every difference **named and accepted**, statement error text | NOT MET — no restore log (nothing run); the **SHA-256 binding is contradictory** (row 8 of §2) | **UNCHECKED** — no document compares `95-secret-scan.md` digests against `100-file-hashes.txt`; see **S5-BL-02** |
| P-10 | **Stop condition:** DDL error at statement *n* → 04 §2.4 branch (stop, classify, repair in place within one session **or record the state**; delete-and-re-create **withdrawn**) | Met as documentation | [04](04-risks-rollback-approvals.md)` :158-165` |
| P-11 | **Stop condition:** "Drift discovered between the **A1 capture** and the load → stop, **re-capture under A1**, record the delta (R-28)" | **NOT MET — unsatisfiable.** It commands a re-capture under an approval the same package declares `INOPERATIVE` | **UNCHECKED** — C-2 rewrote the preconditions cell but left this stop-condition cell intact ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :290`); see **S5-BL-03** |
| P-12 | **Explicit exclusions:** no table data / no production row; no patches; no secrets; no Edge; no Firebase; no production change; **no hand-editing the artefact after the scan**; no `--role-only` / `db reset` / `pg_dump` | Met as prohibitions (§7) | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :287`; [04](04-risks-rollback-approvals.md)` :212` |
| P-13 | A3 also authorises loading **"the separate `auth.users` trigger file"** | **NOT MET — the file has 0 executable statements**; its one trigger is commented `BLOCKED - DO NOT APPLY` (`g3-build/55-auth-users-trigger.sql` ` :19`, `91-coverage.md` ` :19`) | **UNCHECKED** — no document notes that A3's authorisation covers an object the artefact cannot emit; see **S5-BL-05** |
| P-14 | A3 includes "then re-running the g1-* count/ACL queries and producing the **equivalence diff**" | PARTIALLY satisfiable — structural rows only; every behavioural row has no baseline side (B-17) | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :217` (B-17); `g3-build/90-limitations.md` ` :133` (L-9) |

### 3.2 Preconditions stated in `00` §3 / §4

| # | Precondition | State | Checked by whom |
| --- | --- | --- | --- |
| P-15 | §3 step 5 — the artefact is built **from the in-repo baseline capture** (step 4 substitute) | MET (built 2026-11-02 from `g1-q1…q10`, `g1-q3b`, `g1-b3b`, `schema-columns.md`, `functions-and-triggers.md`) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :29`, §3 |
| P-16 | §3 step 5 / §4 G3-b — it must be **"one reviewed `.sql` artefact"** | **NOT VERIFIED** — the only review is the same pass's automated structural check (`96-review-checks.md`); no **separate reviewer pass at a different time** exists (R-16, 04 §3 preamble) | **UNCHECKED** — see **S5-BL-07** |
| P-17 | §3 step 6 / §4 G3-b′ — "secret scan … **before it enters the repo**"; "precondition of A3"; "unmatched hits reviewed by hand … never silently redacted" | MET for the artefact itself (still outside the repo, 0 matches, nothing redacted) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :139`, R-5 |
| P-18 | §3 step 7 — "step 6 scanned clean **AND** A2′(a) signed and executed **AND** A3 granted" | NOT MET (rows 3, 5, 8 above) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :262-263` |
| P-19 | §3 step 7 — load **"in dependency order"** with a **restore log** | Satisfiable in design: order verified by `96-review-checks.md` check 7/8; the log is an execution artefact that does not exist | **PARTLY** — order checked; log N/A until execution |
| P-20 | §3 step 9 / G3-d — equivalence accepted **under A3**, differences accepted | NOT MET (behavioural side absent; extensions/views/sequences **UNKNOWN**) | `g3-build/90-limitations.md` ` :60-69` |
| P-21 | §1 C1 — dashboard SQL Editor only; no CLI/Docker/`pg_dump`/`db reset` | Met (no operation occurred) | [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :12` |
| P-22 | §1 C2b — **"Echo the ref from the console header into the change record before running anything"** | **UNCHECKED / NOT VERIFIED** — it is an execution-time guard; no A3 change record exists, and none has been drafted | **UNCHECKED** — recorded here for the first time (S5-BL-09) |
| P-23 | §4 "One window, not three" — G6 + G3 + G5-S scheduled as **a single coordinated window**; a pause or failure inside the window **stops the window**; and the dated dashboard touch **on or before 2026-11-06** is a standing precondition of any window | NOT MET — no window is scheduled; the touch has no owner (§6) | [04](04-risks-rollback-approvals.md)` :172-192` (R-30/R-40); [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :208` (B-7) |
| P-24 | §8 stop conditions 1–7 for the whole stage (sentinel returns `staging`; session provably targets staging; **pre-state capture compared against Stage 1 evidence**; patch/post-check match; no legitimate `service_role` regression; no cross-environment data; no matrix overreach) | **NOT VERIFIED** — stop condition 3 requires a **pre-state capture of staging** that has never been taken; stop condition 6 is unassessable while `auth.users` is `NOT VERIFIED` | **UNCHECKED** — the pre-state-capture obligation is not carried into A3's §3.4 evidence list (S5-BL-09) |
| P-25 | §4 Step 2 — "If A0 is refused, G3 is `BLOCKED — METHOD NOT PERMITTED`" | Not triggered (A0 recorded approved) | [04](04-risks-rollback-approvals.md)` :72` (R-14) |
| P-26 | Ratification §2 = option (i) (precondition of A2′/A9/A12 and, through A2′(a), of A3) | MET as a recorded decision, unfilled fence | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1 |
| P-27 | Quota headroom before the window (R-15: `Log Query 44.8/100 GB`, stop line **80 GB**; 04 §4 stop list adds **database > 400 MB**) | **NOT VERIFIED** — last meter read 2026-11-02T07:16Z, a historical record; A3's evidence list omits a quota check | **UNCHECKED** — appears only in the A1 row ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :229`) which is `INOPERATIVE`, so the check has no live home (S5-BL-09) |

### 3.3 Preconditions carried by the Phase 0 checklist (still unreconciled after C-1…C-12)

[evidence/S2-EXEC-01-phase0-readiness.md](evidence/S2-EXEC-01-phase0-readiness.md)` :176-188` steps 3–8 still state:
step 4 "**A1 capture complete**" and step 7 "**A0+A1+A2′ signed** … artefact **hashed and secret-scanned** … step 5 = 0 …
drift vs A1 → stop and re-capture (R-28)". That file is dated evidence predating C-2 and was **not** in C-1…C-12's
edited list, so it remains internally inconsistent with the plan of record on the same two points (§5, S5-BL-03/04).
Its genuinely additive requirements — "**both sides exist**" for the equivalence diff (step 8) and "**never declare
equivalence from 'SQL editor said success'**" — are the ones no later document restates.

---

## 4. Consequence analysis: what a load signed tomorrow would actually produce

### 4.1 The database it would create

Loading `g3-reconstruction-2026-11-02.sql` (459 terminated active statements, `93-counts.json` ` :15`) would create:

| Would be created | Count | Source |
| --- | ---: | --- |
| Schemas (`public`, `private`) | 2 (`CREATE SCHEMA IF NOT EXISTS`) | `g3-build/00-platform-assumptions.sql` ` :33-36` |
| Tables / columns | 19 / 183 | `91-coverage.md` ` :10-11` |
| Constraints (19 PK / 9 UNIQUE / 65 CHECK / 44 FK) | 137 | `91-coverage.md` ` :12` |
| Indexes emitted (28 of 62 suppressed to comments) | 34 | `91-coverage.md` ` :13` |
| `ENABLE ROW LEVEL SECURITY` (0 `FORCE` — faithful, forced RLS is off) | 19 | `91-coverage.md` ` :20`; `60-rls-policies.sql` ` :16-17` |
| GRANT statements (33 q6 + 19 acltext `MAINTAIN` + 183 column) | 235 | `91-coverage.md` ` :36` |
| `ALTER DEFAULT PRIVILEGES` | 13 | `91-coverage.md` ` :25` |

| Would **not** be created | Count | Why |
| --- | ---: | --- |
| Functions | **0 of 38** | no return type captured for any function — root blocker (`90-limitations.md` ` :34-41`, `91-coverage.md` ` :17`) |
| Triggers (7 `public` + 1 `auth.users`) | **0 of 8** | each `EXECUTE FUNCTION`s an undefined function (`90-limitations.md` ` :46`) |
| RLS policies | **0 of 21** | predicates call undefined `private.is_family_member` / `is_family_parent` / `shares_active_family` (`90-limitations.md` ` :47`, `96-review-checks.md` check 22) |
| Realtime publication tables | **0 of 4** | membership never captured; deferred to A2′(b) by design (`80-realtime-publication.sql` ` :14-24`) |
| Extensions, views, sequences, comments | **0 emitted; expected count UNKNOWN** | never queried — a blind spot, not an empty set (`90-limitations.md` ` :60-69`) |

**Resulting security posture:** 19 RLS-enabled tables with **zero policies**. In Postgres, RLS enabled with no policies
denies all rows to every non-bypassing role: `anon` and `authenticated` would read nothing, while `service_role` and the
owners bypass RLS (`g3-build/90-limitations.md` ` :107-118`). So the load would produce a structurally shaped,
**behaviourally hollow** database in which the application's security model, its `auth.users` → `profiles` provisioning
path and its Realtime lanes are all absent. Two dependent consequences the artefact itself flags: `gen_random_uuid()` is
used by 16 column defaults with **no extension captured** (`00-platform-assumptions.sql` ` :22`), so if it is
extension-provided rather than built-in, **the load fails at table creation**; and one FK targets `auth.users`, which
resolves **only** because Supabase pre-creates that table (`96-review-checks.md` check 12).

### 4.2 It would **not** unblock A5 — the plan's stated reason for the block is wrong

[04](04-risks-rollback-approvals.md)` :212` and [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :207` (B-6) say
patches cannot run because "staging is empty" and that "A3 must be complete" first. **A3 as specced creates no
functions**, so after the load:

- P01 §0.2–§0.4 cast `'private.request_device_recovery(uuid,uuid)'::regprocedure` and
  `'private.remote_session_transition_guard()'::regprocedure` at
  [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql)` :40-41, 51-52, 61-62` — a missing function makes those casts
  raise, aborting the patch in its pre-checks;
- P02's own gate tests `to_regprocedure(...)` for `private.request_device_recovery`, `private.unlink_child` and
  `public.request_remote_session` and raises if any `is null` ([`patches/S2-P02-e3-actor-binding.sql`](patches/S2-P02-e3-actor-binding.sql)` :32-35`) — all three are artefact-absent; P02 additionally aborts unconditionally because its approval gate ships commented (` :28`, D-07);
- rollback rehearsal ([04](04-risks-rollback-approvals.md)` :288-292`, §4 item 4) **remains impossible**, since there is
  still no function/trigger/policy object to apply, reverse and compare.

This is **S5-BL-06**: the documented unblock path for A5 does not exist.

### 4.3 Validation tests that stay blocked, and why

Baseline: [05](05-validation-plan.md)` :24-26` sets G5-S / G5-E / G5-C all `BLOCKED`, and ` :30-36` restates the
unblock chain without A1 while saying explicitly "**no status in the table above changes**".

| Test ID | Where defined | After a hypothetical A3 load | Reason |
| --- | --- | --- | --- |
| `TE-02` | [05](05-validation-plan.md)` :68` | **Still blocked** | Calls `private.request_device_recovery(uuid, null)` expecting `42501`; with 0 functions the statement fails as undefined-function, not as a privilege denial |
| `P01-T1, T2, T3, T4, T6` | [05](05-validation-plan.md)` :69-74` | **Still blocked** | All presuppose the two P01 objects; T4 additionally needs the `remote_sessions` transition trigger (0 emitted) |
| `P01-T5` | [05](05-validation-plan.md)` :73` | **Still blocked** | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` (0 Edge Functions, [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :88-92`) |
| `P02-T0 … T8` | [05](05-validation-plan.md)` :84-92` | **Still blocked** | `BLOCKED — FIX NOT APPLIED`; P02 cannot apply at all (§4.2); T1–T4/T7 also `BLOCKED — NO REACHABLE CALLER` (` :94-97`) |
| `P03-C1, C3, C4, C5, C6, C9` | [05](05-validation-plan.md)` :103-111` | **Still blocked** | C1/C3/C9 depend on the transition guard and the P02 body (order fixed by J-21); C4 on `expires_at` semantics inside an uncaptured body; C6 assumes a trigger that P03 itself creates **after** P02, which cannot apply |
| `P03-C2, C7, C8` | [05](05-validation-plan.md)` :104, 109-110` | **Still blocked** | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| `T-02` (authenticated non-member denied) | [05](05-validation-plan.md)` :24`; [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :266` | **Still blocked** | Its denial is produced by SELECT policies scoped by `is_family_parent` / `is_family_member` / `auth.uid()` — 0 policies, 0 functions |
| `T-03 … T-07` (cross-family denial, `devices`/`location_events`/`safety_alerts`/`device_commands`/`family_members`) | [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :267-271` | **Still blocked** | Need both the 21 absent policies **and** A11 fixtures across two families |
| `T-08 … T-12`, `T-14 … T-16` (write/deny semantics) | [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :272-280` | **Still blocked** | Insert/update denial rests on policies plus command-level grants; with 0 policies the observed behaviour is "deny everything", which is not the tested property |
| `T-13` (`profiles.role` self-escalation) and `T-17` (`families_update_owner` hijack) | [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :277, 281` | **Still blocked** | Column `UPDATE` grants **would** exist (183 emitted), but the `profiles_before_update` / `families_before_update` trigger functions are 0-emitted, so the second control cannot be exercised |
| `T-01`, `T-18` (anon denied on 19 tables; four deny-all tables) | [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :265, 282` | **False-signal risk, not a pass** | They would return "0 rows / denied" **vacuously** — from absent policies and absent grants, not from the production predicates. Recording them `PASS` breaches C7 ([00](00-stage2-execution-plan.md)` :46`) and the `PASS` rule ([05](05-validation-plan.md)` :58`); see **S5-BL-10** |
| **G5-E** — 104 suite cases + 4 patch-specific = **108** | [05](05-validation-plan.md)` :25, 122-127` | **Unchanged `BLOCKED`** | 0 Edge Functions; no source in the repo; deployment needs A7/A8 + A9 secrets |
| **G5-C** — client compatibility | [05](05-validation-plan.md)` :26, 130-132` | **Unchanged `BLOCKED — NO APP SOURCE`** | No Flutter/Android source; APK smoke never performed |
| **Staging-parity checks** — 04 §4 items 1, 3, 4, 5 | [04](04-risks-rollback-approvals.md)` :279-294` | Item 1 **partial at best**; items 3, 4, 5 **remain `BLOCKED`** | Item 1's diff has no behavioural side (B-17) and unknown extension/view/sequence counts; item 3 needs P01–P03 applied; item 4 needs objects to rehearse (§4.2); item 5 needs the artefact "restored **and** equivalence-proven" — the equivalence half is unachievable, so only the written acceptance of an unproven restore remains available |
| Fidelity rows — [05](05-validation-plan.md)` :145, 148` | "**Yes** for the 38 captured functions" / "publication **Yes** if re-added" | **Void after this load** | 0 functions exist in staging, so even the "38 captured" row cannot be compared; the publication row depends on unsigned A2′(b) |
| SQL ceiling — [05](05-validation-plan.md)` :216-219` | 38 SQL-runnable cases | **Not reachable** | The 38-case ceiling assumes a loaded baseline **with** the functions and policies; the honest post-A3 figure is close to 0 behavioural SQL cases |

### 4.4 Consequences for the record itself

A load also **irrevocably spends the decision**: with 2/2/0 slots and no backup/PITR (R-35, R-38), a failed load is
repaired in place or recorded as-is — there is no second target and no restore point. And under §3.4's own words, if the
FX-18 count returns non-zero the clean-shell premise fails **before** the first DDL statement, voiding P01 §0.4's `4 rows
total` and the "wrong-project run is impossible" arguments ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :288`).

---

## 5. New blockers exposed by this matrix

Beyond B-16 (A3 chain) and B-17 (no complete baseline for 24 functions). Severity P0 = blocks the A3 decision itself.

| ID | Blocker | Severity | Owner action required | Route |
| --- | --- | --- | --- | --- |
| **S5-BL-01** | **A2′(a) is not executable exactly as authorised.** Sequence A puts `private.s2_environment` **before** the load, but staging's `private` schema is created **by** the load (`CREATE SCHEMA IF NOT EXISTS private`, `g3-build/00-platform-assumptions.sql` ` :35`). A2′ authorises "one table and one row" and its own stop condition is "sentinel creation requiring anything beyond one table and one row" ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :259, 263`). Whether `private` already exists on the empty shell is **NOT VERIFIED** — [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :85` records only the `public` selector | P1 | Sign A2′ re-worded to cover the one `CREATE SCHEMA IF NOT EXISTS private` needed, **or** accept that A2′(a) executes after that statement only | **NEW EVIDENCE** (read-only staging schema list) + **SIGNATURE** (re-worded block) |
| **S5-BL-02** | **The secret scan is not bound to the final artefact hash.** `95-secret-scan.md` ` :19-31` and `100-file-hashes.txt` ` :1-20` report different SHA-256 values for **every** shared file (e.g. assembled artefact `efdbf985…` vs `fc996f45…`); the scan hashed decoded text re-encoded (`g3-build/scan_phase34.py:94-95`, Python `hashlib.sha256` over a text-mode read) while the hash list is `sha256sum` over raw bytes. A3's evidence cell demands "**Artefact SHA-256**" and its exclusions forbid hand-editing after the scan — neither is enforceable while two digest sets disagree, and the scan's 13-file list omits 8 files the pass report says were covered | P1 | Do not sign A3 until one byte-exact digest of the loadable file is recorded **by** the scan; re-scope the scan to the whole directory | **OFFLINE-ONLY** (re-run scan/re-hash). Confirmation by the hash-domain auditor is **PENDING** |
| **S5-BL-03** | **A3 contains an instruction that cannot be carried out.** Its stop-condition cell still says "Drift … → stop, **re-capture under A1**" ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :290`; echoed at [evidence/S2-EXEC-01-phase0-readiness.md](evidence/S2-EXEC-01-phase0-readiness.md)` :182`), but A1 is `INOPERATIVE` (C-2) and no re-capture route exists. Signing A3 today signs a block whose failure path is prohibited | P2 | Accept an amended failure path (record the drift, stop, do not re-capture) — that is a documentation edit **the owner must approve**, since §3.4 is authoritative text | **SIGNATURE** (content fix itself is offline-only wording) |
| **S5-BL-04** | **R-28's pre-A3 re-verification has no authorised route.** Mitigation reads "re-run the g1-* count/ACL queries **before A3** … re-verify immediately before A3; any delta becomes a recorded drift" ([04](04-risks-rollback-approvals.md)` :86`), but the baseline side is production and production reads are prohibited; staging is empty, so there is nothing to compare | P2 | Owner explicitly accepts that baseline freshness is **unprovable** for this load and records the date of the last production capture (2026-10-29/30) as the accepted staleness | **SIGNATURE** (acceptance) — no evidence route |
| **S5-BL-05** | **A3 authorises loading an `auth.users` trigger file that emits nothing.** §3.4 authorises "the separate `auth.users` trigger file", but `55-auth-users-trigger.sql` ` :19` holds one commented `BLOCKED - DO NOT APPLY` trigger (its function `private.handle_new_user` has no return type). Consequence: post-load, `auth.users` inserts create no `profiles` row, i.e. the provisioning path is absent, and FX-18's premise (a template-copied estimate) is left untestable | P1 | Owner records that A3 delivers **no** auth trigger, or authorises the read that would make it emittable | **NEW EVIDENCE** (return type capture) + **SIGNATURE** |
| **S5-BL-06** | **A3 does not unblock A5 (B-6 is misdiagnosed).** The plan blocks patches on "staging is empty / A3 must complete"; after a faithful A3 load staging still has **0 functions**, so P01's `::regprocedure` pre-checks raise and P02's `to_regprocedure` gate aborts ([patches/S2-P01-e2-f8.sql](patches/S2-P01-e2-f8.sql)` :40-41`; [patches/S2-P02-e3-actor-binding.sql](patches/S2-P02-e3-actor-binding.sql)` :32-35`), and rollback rehearsal (04 §4 item 4) stays impossible | **P0** | Owner decides between accepting a structural-only ceiling (G3 never closes) and authorising the read class that produces function definitions | **NEW EVIDENCE** + **SIGNATURE** (C2b rescope) |
| **S5-BL-07** | **"One reviewed `.sql` artefact" has no independent review.** The only review is the building pass's own automated check (`96-review-checks.md`); no separate-time reviewer pass exists (R-16; U-11 open), and with **zero commits** there is no diff baseline — hashes are the only provenance and bind to no signature | P2 | A named reviewer pass at a different time, recorded in its own notes; optionally an initial commit as the pre-action baseline | **OFFLINE-ONLY** (a review pass needs no cloud action) |
| **S5-BL-08** | **A9's preconditions were not updated for the C-3 split.** §3.6 requires "**A2′ complete** (settings recorded)" — after the split, A2′ completeness includes A2′(b), which requires A3, so A9 is now transitively gated on the load while the sentence "and, for anything the functions read, A3" implies A9 could precede it ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :333`) | P3 | Re-word A9 to name A2′(b)/A3 explicitly | **OFFLINE-ONLY** wording + owner acceptance |
| **S5-BL-09** | **Three A3-window guards have no owner and no home:** the C2b ref-echo guard before any statement ([00](00-stage2-execution-plan.md)` :41`), stage stop-condition 3's **pre-state capture** of staging ([00](00-stage2-execution-plan.md)` :307`), and the R-15 quota headroom check with its 80 GB / 400 MB stop lines, which currently live only inside the `INOPERATIVE` A1 row | P2 | Fold all three into A3's evidence list as mandatory pre-window reads | **OFFLINE-ONLY** wording; execution is **SIGNATURE**-gated |
| **S5-BL-10** | **A load would generate false-positive validation signal.** `T-01` / `T-18` (and any "deny-all" observation) would return the expected result for the wrong reason (0 policies, not policy predicates), creating exactly the "recorded expectation as observation" hazard C7 and [05](05-validation-plan.md)` :58` forbid, and tempting a reader to write "G5-S: 2 passed" | P1 | Owner instruction that post-load deny-all observations are labelled `BLOCKED — NO POLICY BASELINE`, never `PASS` | **OFFLINE-ONLY** (label rule) — already implied by 05 §2 |

**Dependency notes marked PENDING (not assumed satisfied):** independent hash verification for S5-BL-02; independent
SQL-structure verification of the 459 statements; independent function-semantics verification of the 14 commented
`prosrc` bodies; and any concurrent `S2-EXEC-04-*` A3 matrix, which this pass neither read nor relied on.

---

## 6. Auto-pause obligation

**`NOT EXECUTED IN THIS PHASE.`** No dashboard page was opened and no touch was performed by this pass, deliberately.

| Element | State | Citation |
| --- | --- | --- |
| Obligation | A **dated dashboard touch on or before 2026-11-06** is required for `parent-control-staging` (and, on the Firebase side, for `haven-staging-46822`) | [04](04-risks-rollback-approvals.md)` :172-192` (§2.5), R-30 ` :88`, R-40 ` :98`; [00](00-stage2-execution-plan.md)` :156-159`; [05](05-validation-plan.md)` :198-202`; [README](README.md)` :119-122` |
| **Owner action still required** | **Yes.** A touch is an **operational action** needing the owner's own instruction; it is covered by **no approval block**, and "recording this deadline is documentation; meeting it would be an operational action" | [05](05-validation-plan.md)` :200-201`; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :208` (B-7, "owner action required"), ` :277`; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :268` |
| **No exact UTC start recorded** | Correct and material: the clock started at creation on **2026-10-30**, and the only timestamp in existence is a **local display** (`Oct 30, 5:25pm`–`6:25pm`) with no UTC conversion. **Therefore no record states the exact expiry** — 2026-11-06 is the latest date the touch can fall on, not a measured deadline (U-10 "OPEN — AND NOW MATERIAL") | [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :48`, ` :398` (§5 control 3), ` :435` (U-10); [04](04-risks-rollback-approvals.md)` :176-179`; [S2-DOC-02](S2-DOC-02-reconciliation.md)` :245-247` |
| Did the 2026-11-02 pass reset the clock? | **`NOT VERIFIED`** — whether a page view counts as activity is unrecorded; the `6/60 conns` and 9 requests are consistent with dashboard-generated traffic but prove nothing | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :235-242` (§7), ` :201` |
| Paused-project arithmetic | Whether a **PAUSED** project still counts toward the 2-active cap is `NOT VERIFIED` and **must not be tested** — the test object would be the only non-production target | [04](04-risks-rollback-approvals.md)` :177-181`, R-38 ` :96` |
| Consequence if it pauses | No backup and no PITR (R-35) and no slot headroom (R-38): the recovery route is restore-in-dashboard then re-verify, and the re-verification targets (`private.s2_environment`, counts, last post-check) **do not exist yet** | [04](04-risks-rollback-approvals.md)` :183-188` (§2.5 table, incl. its own parenthetical "the first two checks have nothing to read until A3 runs") |

**Do not read any statement in this file as claiming staging is currently active or healthy.** The `STATUS Healthy` /
unpaused, 0-tables, `No migrations`, `No backups` readings are from the **2026-11-02T07:16Z** observation
([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :33-38`, ` :189-192`) — a **historical record, not a
present state**. This pass performed no observation, so the current pause status is `NOT VERIFIED` as of now, and any
planning of an A3 window must start by establishing it again under an owner instruction.

---

## 7. What remains prohibited and unchanged

This assessment is **not** an authorisation. Restating the boundaries that no reader may infer away:

1. **No approval was granted, signed, dated or pre-filled here.** Every fence stays blank by design
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :11-12`); an owner decision recorded in a
   report is **not** a signature on a fence ([README](README.md)` :59`), and no approval is inferred from silence or
   from a console button (R-29).
2. **The ratification grants nothing forward** — no schema, sentinel, settings change, secret, patch, app registration,
   FCM, credential, Edge Function or production change
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :123-127`, ` :131`).
3. **A0's approval authorises the method, not the load**; A5's approval is **not executable**; A1 is **inoperative** and
   cannot be signed to effect ([04](04-risks-rollback-approvals.md)` :209-213`).
4. **No SQL of any kind is authorised**, including the FX-18 `auth.users` count — it lives inside the unsigned A3
   ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md)` :105-106`, ` :270`).
5. **No production access of any kind** — not a write, not a read, not a "documented read-only comparison": the C2b/R-43
   exception is closed and the stricter clause governs
   ([04](04-risks-rollback-approvals.md)` :101`; [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :184`).
   `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was not opened in this pass.
6. **Staging-only absolute:** every Supabase action targets `dzonzgngwxclhfnvxtvu` and no other project; there is no
   third project to fall back to ([00](00-stage2-execution-plan.md)` :41`).
7. **Nothing may be loaded, applied, created, paused, resumed, deleted or re-created** by reading this document. The
   delete-and-re-create branch stays withdrawn (R-38, [04](04-risks-rollback-approvals.md)` :158-165`).
8. **The artefact stays outside the repository**; a clean scan is **not** permission to bring it in
   ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :139`, R-5).
9. **Browser-only, no tooling workarounds** (CLI, Docker, `pg_dump`, `db reset`, `--role-only`, DevTools, REST, hidden
   endpoints) — C1, [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :184`, ` :287`.
10. **Verdict ceilings hold:** "G5 passed", "app compatible", "production ready", "E3/F7 closed", "E4 closed",
    "E6/E7 closed" and "Stage 2 complete" remain unavailable
    ([00](00-stage2-execution-plan.md)` :250-262`); the production gate's items 1 and 4 remain `BLOCKED`
    ([04](04-risks-rollback-approvals.md)` :279-292`).
11. **Secrets, credentials and PII:** no value appears in this file; secrets remain by **name and digest only**
    ([00](00-stage2-execution-plan.md)` :42` C3); R-39's custody question is the owner's alone to answer.
12. **A12's amended prohibition still bites:** app registration, FCM configuration, credentials and settings changes
    remain prohibited, and A12 is unsigned ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :121-122`).

---

## 8. Recommended verdict

> ### `NOT LOAD-READY — RECONSTRUCTION GAPS`

**Deciding reason:** A3's own precondition list requires an artefact that constitutes a baseline
([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :286-289`), and the artefact's measured
position is that **0 of its 459 active statements create a function, trigger, policy or publication**, because **all 38
return types and 24 of 38 bodies are absent from any approved evidence**
(`g3-build/90-limitations.md` ` :16-54`; `91-coverage.md` ` :14-21`; `96-review-checks.md` checks 21/23/25/28). Signing
A3 would load a 19-table, RLS-**enabled**, zero-policy database (`90-limitations.md` ` :107-118`) that still cannot host
P01/P02 (§4.2, **S5-BL-06**), cannot produce the behavioural half of its own equivalence diff (B-17), and cannot make
G5-S, G5-E or G5-C runnable ([05](05-validation-plan.md)` :30-36`). That is a reconstruction gap, not a missing
signature.

**Honest disclosure about `PENDING` dependencies.** Several concurrent auditors' reports are unpublished or unreadable to
this pass (hash verification of S5-BL-02, independent SQL-structure review, function-semantics review of the 14 captured
bodies, and the `S2-EXEC-04-*` matrix, which this pass neither read nor treated as authority). **That cannot move this
verdict in the permissive direction**: the deciding evidence is the artefact's own measured coverage, published before
this pass began. Those dependencies can only **add** blockers or downgrade rows from `MET`/`NOT VERIFIED` to `NOT MET` —
most plausibly row 8 (scan-to-hash binding) and row 1 (A0's "reviewed" requirement, **S5-BL-07**). Had the deciding gap
depended on an unpublished report, the correct verdict would instead have been `BLOCKED — INCOMPLETE AGENT EVIDENCE`;
it does not. `BLOCKED — UNRESOLVED EVIDENCE CONFLICT` was also considered because of the two contradictory digest sets,
but both are explainable by a stated hashing input difference (text-mode read vs raw bytes,
`g3-build/scan_phase34.py:94-95`) and are closable offline, so it is carried as `NOT VERIFIED` (row 8) rather than as
the verdict.

**Second-order note for the owner, not a verdict:** the artefact **is** legitimately presentable for **review** as N-3
([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :249-256`) — its provenance labels, coverage table and
limitations report are honest and measured. Presentable-for-review and load-ready are different claims, and only the
first is supported.

---

## 9. Evidence classification

### 9.1 VERIFIED (read from a cited document; no inference)

- Every approval status: ratification `RATIFIED — 2026-11-02 — OPTION (i)`; A0 approved-as-recorded; A1 `INOPERATIVE`
  and removed from A3's chain; A2′ split and unsigned; A3/A9/A12 unsigned; A5 approved-not-executable
  (§1 citations). **Zero signature fences filled** — verified by direct inspection of all 10 fence lines
  ([approval-package-v2](approval-package-v2-ratification-and-forward.md)` :156, 203, 240, 277, 300, 322, 344, 366`;
  [approval-package-a0-a2.md](approval-package-a0-a2.md)` :93, 141`).
- The artefact's measured insufficiency and its full L-1…L-12 closure table (`g3-build/90-limitations.md` ` :16-54`, ` :124-136`).
- The secret scan's own recorded result and its self-disclosed non-proof (`95-secret-scan.md` ` :11-14`, ` :53-59`).
- That A3's preconditions are enumerated at [approval-package-v2](approval-package-v2-ratification-and-forward.md)` :288`
  and [00](00-stage2-execution-plan.md)` :90`, ` :166-169`; and that P01/P02 abort on absent function signatures
  ([patches/S2-P01-e2-f8.sql](patches/S2-P01-e2-f8.sql)` :40-41`; [patches/S2-P02-e3-actor-binding.sql](patches/S2-P02-e3-actor-binding.sql)` :32-35`).
- That the FX-18 count **has not been run** and that staging had 0 tables / `No migrations` / `No backups` / 0 Edge
  Functions **as at 2026-11-02T07:16Z** ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :33-38`, ` :85`, ` :96-98`).
- That this pass performed no operation and created exactly one file (§header).

### 9.2 INFERRED (follows from evidence; not observed)

- **The load's Postgres effects** — 19 RLS-enabled tables with 0 policies ⇒ deny-all to non-bypassing roles: Postgres
  semantics applied to the artefact's measured contents; the artefact states the same conclusion (`90-limitations.md` ` :110-113`).
- **The cause of the digest mismatch** — text-mode read then UTF-8 re-encode (`scan_phase34.py:94-95`) vs `sha256sum`
  over raw bytes; supported by the scan reporting **chars** (11 843) below the on-disk size (12 124) for the same file.
  Needs the hash-domain auditor's confirmation (**PENDING**).
- **`private` schema absence** on the empty shell — inferred from `private` being an application schema holding the 24
  uncaptured functions (`00-platform-assumptions.sql` ` :29`) and from the load being the only recorded creator of it;
  **not** observed.
- **Patch-execution failure after A3** — inferred by joining the artefact's 0-function measure to the patches'
  `regprocedure`/`to_regprocedure` guards; never tested (nothing was run).
- **False-signal risk on `T-01`/`T-18`** — inferred from expected-result text at [../stage1/08-test-matrix.md](../stage1/08-test-matrix.md)` :265, 282`
  against the post-load state.

### 9.3 MISSING EVIDENCE (what does not exist anywhere in the repo)

- A **byte-exact digest of the loadable artefact recorded by the scan itself**, and one reconciled digest set.
- A **separate-time reviewer pass** over the artefact (R-16 / "one **reviewed** artefact", [00](00-stage2-execution-plan.md)` :88`).
- A **staging pre-state capture** and a **staging schema list** (00 §8 stop condition 3; S5-BL-01).
- Any **A3 change record** with the ref-echo guard, quota snapshot and evidence cells required by
  [04](04-risks-rollback-approvals.md)` :313-340` — no template instance exists.
- Function **return types** (38), `private` **bodies** (24), `pg_extension`, `pg_publication_tables`, **views**,
  **sequences**, object comments — the L-1…L-7 blind spots (`g3-build/90-limitations.md` ` :60-69`, ` :125-131`).
- A **restoration/verification harness** proving a SQL Editor session targets staging before the first statement (00 §8 stop condition 2).
- A **recorded G2 decision** (A12 precondition) and the owner's **R-39 password custody** answer.
- A **UTC start timestamp** for the auto-pause clock (§6) — and any post-2026-11-02 observation of project status.
- Published reports from the parallel hash / SQL-structure / function-semantics / `S2-EXEC-04` auditors — **PENDING**.

### 9.4 UNVERIFIED / NOT VERIFIED (assertions this matrix refuses to treat as satisfied)

- `auth.users` emptiness on staging (FX-18 / R-42) — dashboard prints `Total: 10 users (estimated)` over an empty grid.
- Whether staging is **currently** unpaused and healthy — only the 2026-11-02T07:16Z historical record exists (§6).
- Whether a page view resets the Free 7-day clock ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :235-242`).
- Whether a **PAUSED** project counts toward the 2-active cap (R-38) — and it must not be tested.
- Firebase plan `Spark` (not re-confirmed; plan page redirects).
- Current quota meters vs the 80 GB / 400 MB stop lines (last read 2026-11-02T07:16Z).
- Whether `gen_random_uuid()` is built-in or extension-provided — decides whether the load survives table creation.
- The claim that the scan covered "every file in the build directory"
  ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :130` vs `95-secret-scan.md` ` :10`, 13 files).
- That the assembled file is byte-for-byte the concatenation of the scanned components at scan time (component digests
  are claimed stable — `90-limitations.md` ` :178-180` — but the assembled file's two recorded digests disagree).

### 9.5 RECOMMENDATIONS (owner-facing; none authorised by this document)

1. **Take the N-3 review, not an A3 signature, as the next step**: read `90-limitations.md`, `91-coverage.md`,
   `92-provenance-manifest.md`, `94-validation.md`, `95-secret-scan.md`, `96-review-checks.md`, then choose between
   (a) accepting a **structural-only** baseline with its stated ceiling, or (b) authorising the evidence class that could
   produce function definitions — which requires amending the staging-only absolute ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md)` :252-256`).
2. **Close S5-BL-02 before any A3 signature is contemplated** — it is the one blocker on this list that is fully
   closable offline and that A3's own evidence cell already demands.
3. **Correct the A3 text's two dead paths** (S5-BL-03 re-capture-under-A1; S5-BL-05 auth.users trigger file) before the
   owner signs, so that signing A3 does not sign an impossible instruction.
4. **Re-diagnose B-6/A5** (S5-BL-06): the record should say patches are blocked because **the objects they alter cannot
   be created from available evidence**, not merely because staging is empty.
5. **Give the auto-pause touch a named owner and a UTC stamp** (§6) before planning any coordinated window; treat
   re-establishing current project status as the first action of that planning, not as evidence already in hand.
6. **Resolve A2′(a)'s schema precondition** (S5-BL-01) with one read-only schema observation and a re-worded block.
7. **Record the reviewer pass and consider an initial commit** (S5-BL-07) so that hashes stop being the sole,
   self-referential provenance ([S2-DOC-02](S2-DOC-02-reconciliation.md)` :174-184`).
8. **Pre-declare the label rule for post-load deny-all observations** (S5-BL-10) so no future G5-S report can count
   `T-01`/`T-18` vacuity as coverage.

---

*End of S2-EXEC-05. No approval is granted, signed or implied by this document; no operation is authorised by it; no
data connection, SQL statement, dashboard page or project setting was touched in its making.*
