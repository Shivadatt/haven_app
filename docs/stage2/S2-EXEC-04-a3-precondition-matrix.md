# S2-EXEC-04 — A3 readiness precondition assessment (approval-gate audit)

**Audit class:** read-only documentation and artefact-report audit of the **A3 precondition matrix** (the gate for loading
the reconstructed schema into `parent-control-staging` / `dzonzgngwxclhfnvxtvu`).
**Verdict:** `NOT LOAD-READY — RECONSTRUCTION GAPS` (see §1–§3; totals at §2).
**Date of this audit:** 2026-11-02. **Operational actions performed by this audit: NONE.** No cloud, no dashboard, no
console page, no CLI, no API, no SQL, no `auth.users` count, no sentinel, no project opened. Nothing in the artefact
directory was written or modified — it was only read, counted and locally re-hashed for the M-06/M-17 reconciliation
(§7, Verified). No existing document modified, no git operation. **One file created: this one.**

**Out of scope by assignment:** SQL structure, object coverage, function bodies, statement hashes. Where those facts were
needed they are **cited**, not re-measured — from `g3-build/90-limitations.md`, `91-coverage.md`, `95-secret-scan.md`,
`96-review-checks.md`, `100-file-hashes.txt` (all at
`C:/Users/ASUS/.qoder/tmp/D--control/g3-build/`, cited below as `g3-build/…`) and from the Stage 2 plan of record.

**Labelling** is the plan-of-record vocabulary ([00](00-stage2-execution-plan.md):31) plus the matrix classifications
required by this task: **MET / NOT MET / NOT VERIFIED / NOT APPLICABLE**.

**Standing rule applied throughout:** a recorded owner decision is **not** an advance authorisation and no fence is filled
by it ([R-29](04-risks-rollback-approvals.md):87; [R-37](04-risks-rollback-approvals.md):95;
[04](04-risks-rollback-approvals.md):401-404), ratification grants nothing forward
([approval-package-v2](approval-package-v2-ratification-and-forward.md):123-127), and nothing in this audit converts an
unsigned block into an executable one.

---

## 1. A3 precondition matrix (the ten assigned preconditions)

Classification key: **MET** = the required state is evidenced in the repo; **NOT MET** = the required state is
affirmatively absent; **NOT VERIFIED** = no evidence exists either way; **NOT APPLICABLE** = the item is not part of A3's
chain as the documents now stand.

| ID | Precondition | Required state (as documented) | Evidence actually available (file:line) | Class | What would make it MET | Offline / production read / owner signature? |
| --- | --- | --- | --- | --- | --- | --- |
| **M-01** | **A0 method decision** — G3 method amendment approved as a recorded decision, physical fence unfilled | A0 recorded as approved with the method amended to **offline reconstruction from the in-repo 2026-10-29/30 capture** ([00](00-stage2-execution-plan.md):86 §3 step 3; [00](00-stage2-execution-plan.md):171-178; [approval-package-v2](approval-package-v2-ratification-and-forward.md):175-189 §3.1) | `README.md`:83 (`APPROVED — 2026-11-02` by recorded owner decision, fence unfilled); [04](04-risks-rollback-approvals.md):209 (§3 row A0); [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):162 (§5 row A0, "Executable? Yes — local/offline only"); correction applied at [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):41 (C-1); fence text [approval-package-v2](approval-package-v2-ratification-and-forward.md):205 | **MET** (as a recorded decision) | Nothing further for the decision itself. The **fence** stays unfilled by design ([approval-package-v2](approval-package-v2-ratification-and-forward.md):161-163; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):205 R-4) and is covered by M-04/M-11, not by A0 | Already satisfied; **no** further action resolvable here. Filling the fence is an owner signature, not this audit's to draft |
| **M-02** | **A1 `INOPERATIVE`** — production read must be absent from A3's chain | A1 is void in substance and **explicitly removed** from A3's precondition chain | [00](00-stage2-execution-plan.md):87 (§3 step 4 struck to `INOPERATIVE`) and `:90` ("**A1 is not a precondition of A3**"); [00](00-stage2-execution-plan.md):109-115 amendment; [approval-package-v2](approval-package-v2-ratification-and-forward.md):211-219 (§3.2) and `:288` (§3.4 preconditions); [README.md](README.md):84; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):126-152 (§4, F-5-A); [04](04-risks-rollback-approvals.md):210 (§3 row A1 `PROHIBITED / INOPERATIVE`) | **NOT APPLICABLE** | Correctly a non-precondition; no satisfaction required | **n/a.** Any action here would be a **new owner ruling** changing C2b/R-43 — prohibited to this audit |
| **M-03** | **A2′(a) sentinel — signed AND executed before A3** | `private.s2_environment` with one row `staging` must exist **before** the load ([00](00-stage2-execution-plan.md):92 §3 step 8a; [approval-package-v2](approval-package-v2-ratification-and-forward.md):247-252, `:259`) | Unsigned: [04](04-risks-rollback-approvals.md):205, `:212`; [README.md](README.md):86; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):164. Not created: [approval-package-v2](approval-package-v2-ratification-and-forward.md):41 ("Sentinel … **NOT CREATED**"); [00](00-stage2-execution-plan.md):135 (`NOT DONE`); [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):194 ("`VERIFIED` — it does **not** exist (0 tables; never created)") | **NOT MET** | (i) owner signature on the A2′(a) half **and** (ii) execution of one `CREATE TABLE` + one `INSERT` in `dzonzgngwxclhfnvxtvu`, evidenced with before/after counts (`0 → 1`) | **Owner signature** (A2′) **+** an operational write. Not offline-resolvable. Note [04](04-risks-rollback-approvals.md):68 (R-10) still says "until **A3** creates it" — stale under Sequence A; see §4 S4-BL-05 |
| **M-04** | **A3 load approval signed** | A3 signature in [approval-package-v2](approval-package-v2-ratification-and-forward.md):292-304 §3.4; A3 is the gate on the load ([00](00-stage2-execution-plan.md):90, `:168`) | [approval-package-v2](approval-package-v2-ratification-and-forward.md):288 ("Status today: **A3 is UNSIGNED**, so none of the following is executable") and `:302-304` (fence text: "UNSIGNED … this fence must not be filled on the assumption that a baseline exists"); [04](04-risks-rollback-approvals.md):212 (`**UNSIGNED**, and **not executable**`); [README.md](README.md):86; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):165; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):238, `:263` | **NOT MET** | Owner signs the §3.4 fence with name and UTC time. **This audit does not draft, prefill or date it** | **Owner signature only.** Not offline-resolvable by any agent action |
| **M-05** | **Exact `auth.users` count, authorised only inside A3's window, not run** | `select count(*) from auth.users;` on `dzonzgngwxclhfnvxtvu` is the **first statement of the A3 window**; non-zero ⇒ stop ([approval-package-v2](approval-package-v2-ratification-and-forward.md):288; owner decision **B-3 = option A**, [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):99-118) | [00](00-stage2-execution-plan.md):332 (FX-18 row); [04](04-risks-rollback-approvals.md):100 (R-42); [05](05-validation-plan.md):51; [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):96-98, `:141-181` (annotation `:175-181`: "**the read is still unauthorised, because A3 is UNSIGNED** … Nothing was run"); `g3-build/90-limitations.md`:132 (L-8) | **NOT MET** | Execution of that single count with ref + UTC timestamps inside a signed A3 window; `0` clears FX-18/R-42, non-`0` stops the load | **Owner signature (A3) + an operational read.** Not offline-resolvable. `auth.users` emptiness stays `NOT VERIFIED` ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):164-167) |
| **M-06** | **Secret scan tied to the exact final artefact** | "step 6 scanned clean" is an A3 blocking precondition ([00](00-stage2-execution-plan.md):89, `:167`); "a completed secret scan **of the artefact**" ([approval-package-v2](approval-package-v2-ratification-and-forward.md):288) | Scan exists and is clean: `g3-build/95-secret-scan.md`:10-13, `:51` (13 files, 0 matches, verdict CLEAN); re-confirmed at [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):137-139. **At first read the digests do not reconcile:** `95-secret-scan.md`:29 hashes the assembled artefact as `efdbf985cfc72f72…` over **148 615 chars** while `100-file-hashes.txt`:11 and `90-limitations.md`:159 record `fc996f450690d8b6…` (on disk: **150 566 bytes / 1 951 lines**), and the same offset appears for every component (`95-secret-scan.md`:19-28 vs `100-file-hashes.txt`:1-10); **no pre-existing document states the method** (repo-wide grep for `fc996f45`/`efdbf985` before this file: no matches). **This audit closed the gap by a read-only local re-hash:** the same bytes hash to raw-byte `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` (= `100-file-hashes.txt`:11) and, with CRLF normalised to LF, to `efdbf985cfc72f721f9499a856fbdf51181f8851eca565fbae9e74d0e71f7092` (= `95-secret-scan.md`:29), so **the scan and the hashes file describe identical content under two normalisations**; the artefact's mtime (`2026-11-02 17:12:21.5`, local +0530) also precedes the scan record (`17:12:22.1`) and the hashes file (`17:14:05`) | **MET** (substance, demonstrated here; only the *statement* of the method is missing) | Nothing further for the substance — the scan **is** of the exact final artefact. To make the record self-evidencing, `95-secret-scan.md` must state its hash method and carry the **raw-byte** digest equal to the artefact of record | **Offline-resolvable — and resolved offline here** (a local re-hash; no production read, no new approval, no write into the artefact directory). What remains (re-emitting the scan report with a stated method) is an edit outside this audit's permissions (no existing file may be modified) |
| **M-07** | **Offline reconstruction sufficiently complete for the intended schema load** | A3's object is a schema load that yields the production-equivalent baseline; the checklist of record defines it as **19 tables / 38 functions / 21 policies / triggers / grants, zero rows** ([01](01-staging-project-proposal.md):252) | `g3-build/90-limitations.md`:14 ("`NOT LOAD-READY` by construction, not by omission"), `:19-23` (0 function / 0 trigger / 0 policy / 0 publication statements of 459), `:36-54` (root cause: **0 of 38 return types**, **24 of 38 bodies absent**), `:107-118`; `91-coverage.md`:14-31, `:40-46`; `96-review-checks.md`:79; [00](00-stage2-execution-plan.md):90, `:166`; [04](04-risks-rollback-approvals.md):212; [README.md](README.md):89; [01](01-staging-project-proposal.md):267-271 | **NOT MET** | Either (a) an owner decision to accept a **structural-only** baseline with the A3 text re-worded so it no longer promises the 01 §7 composition, or (b) a new evidence pass that can produce function definitions — which needs a **production read**, i.e. rescoping C2b/R-43 and re-activating A1 or a replacement approval ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):251-256; `90-limitations.md`:125-136 L-1…L-7, all "**No**" for owner-actionable-from-this-repo) | **(b) needs a production read + a new owner ruling; (a) needs an owner decision.** Neither is offline-resolvable for the *substance*; only the *wording* is |
| **M-08** | **Dependency order demonstrably correct** | The load is "applied … **in dependency order**" ([00](00-stage2-execution-plan.md):90; [approval-package-v2](approval-package-v2-ratification-and-forward.md):286); A0's amended method fixes the order: auth prerequisites → schemas → tables → PK/FK → constraints → indexes → functions → triggers → RLS enablement → policies → grants → default privileges, `auth.users` trigger separate and never applied, publication as a post-table op ([approval-package-v2](approval-package-v2-ratification-and-forward.md):183) | Static order checks pass in the artefact's own review: `96-review-checks.md`:23 (check 7 PASS — component sequence with per-file active counts), `:24` (check 8), `:55` (check 39, no FK cycle), `:34` (check 17), `:36` (check 20); build order recorded at [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):77-92 | **NOT VERIFIED** | Order can only be *demonstrated* by an execution or a dry run, and both channels are excluded (C1 [00](00-stage2-execution-plan.md):39; no CLI/Docker/`pg_dump`/`db reset`, [approval-package-v2](approval-package-v2-ratification-and-forward.md):184). Worse, the order that matters most for security — functions → triggers → policies → publication — **has no statements in it** (`40`/`50`/`55`/`80` carry 0 active statements, `90-limitations.md`:19-22, `96-review-checks.md`:64 check 48), so the emitted order is a *partial* order whose correctness for the missing classes is untestable. Also unresolved by construction: the artefact never creates an extension, and its FK to `auth.users` is satisfiable **only** because Supabase pre-creates that table (`96-review-checks.md`:28 check 12, `:54` check 38) | **Partly offline**: a written order-proof argument over the evidence (no new approval). The *demonstration* needs the signed A3 load itself; the extension/publication blind spots need a **production read** |
| **M-09** | **Provenance traceable for every reconstructed object** | Per-object provenance with the five labels, and a coverage report whose counts are **measured, never asserted** ([approval-package-v2](approval-package-v2-ratification-and-forward.md):186 §3.1 evidence row) | `g3-build/92-provenance-manifest.md` = **515 rows** (`90-limitations.md`:26, `:96-104` label distribution: 434 `VERIFIED FROM SOURCE`, 14 metadata+body, 24 metadata-only/`NOT PRESENT IN EVIDENCE`, 21 `RECONSTRUCTED FROM MULTIPLE SOURCES`, 18 `UNVERIFIED (schema not captured)`, 4 `INFERRED FROM DOCUMENTATION`); "No inferred object is labelled verified" ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):106-108); coverage cells are measured or `UNKNOWN`, never invented (`91-coverage.md`:3, `:27-31`) | **MET** (within the artefact's own record set) | Already satisfied in form. Its durability half is a **different** precondition and fails — see **M-16** (no in-repo artefact hash, zero commits). The 18 unattributable `g1-q7` rows and 4 documentary publication rows are correctly labelled, not resolved (`96-review-checks.md`:43 check 27 = FAIL; `90-limitations.md`:67`) | **Offline** to improve (re-attributing `g1-q7` needs the same production read class — `90-limitations.md`:129 L-5) |
| **M-10** | **Rollback readiness assessed without claiming an untested rollback works** | The plan must state rollback design and must **not** assert that an untested rollback works; "No rollback has been tested" is required truthfulness ([04](04-risks-rollback-approvals.md):8; §4 item 4; §2.4; R-35) | [04](04-risks-rollback-approvals.md):8 ("**No rollback has been tested.**"); `:288-292` (§4 item 4 `BLOCKED`, rehearsal impossible on an empty schema, "no rollback has been tested anywhere in this programme"); `:150-166` (§2.4, delete-and-re-create **withdrawn**); `:93` (R-35 no backups/PITR); [approval-package-v2](approval-package-v2-ratification-and-forward.md):384 (item 4 `BLOCKED`); `90-limitations.md`:113-114 ("patch rehearsal would still be impossible") | **MET** (as an assessment) | Nothing: the honest state is already recorded. Note the **substantive capability** is absent and stays absent — MET here means "correctly assessed, not claimed", not "rollback works" | **Offline / already done.** Making rollback *work* needs the signed A3 + A5 chain |

**Ten-row subtotal:** MET 4 (M-01, M-06, M-09, M-10) · NOT MET 4 (M-03, M-04, M-05, M-07) · NOT VERIFIED 1 (M-08) · NOT APPLICABLE 1 (M-02).

---

## 2. Further A3 preconditions the documents themselves require (and that the ten above omit)

Sourced by grep of [00](00-stage2-execution-plan.md) §3 (`:81-97`) and §4 (`:161-183`), [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4
(`:284-290`), [04](04-risks-rollback-approvals.md) §3 row A3 (`:212`), [01](01-staging-project-proposal.md) §6/§7
(`:194-265`), [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §8 (`:266-278`) and
[R-28](04-risks-rollback-approvals.md):86. Rows marked **(unchecked)** were not examined by any prior pass found in the repo.

| ID | Additional precondition required by the documents | Evidence / absence of evidence | Class | Offline vs read vs signature |
| --- | --- | --- | --- | --- |
| **M-11** | **Ratification §2 = option (i)** — the precondition row of A2′ and A9 ([approval-package-v2](approval-package-v2-ratification-and-forward.md):261, `:333`), which gates A2′(a), which in turn gates A3 | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):33-64; [00](00-stage2-execution-plan.md):85; [04](04-risks-rollback-approvals.md):235; fence deliberately unfilled [approval-package-v2](approval-package-v2-ratification-and-forward.md):161-163 | **MET** (recorded, unsigned; grants nothing forward) | Done. Fence-filling = owner signature |
| **M-12** | **Ref echo + console-header match before any statement** — "Echo the ref from the console header into the change record before any statement runs" ([00](00-stage2-execution-plan.md):41 C2b; [approval-package-v2](approval-package-v2-ratification-and-forward.md):261, `:335`; [R-43](04-risks-rollback-approvals.md):101) **(unchecked)** | No change record exists for any SQL action; the SQL Editor has never been opened ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):229 lists `SQL Editor` among controls **visible and not clicked**); template at [04](04-risks-rollback-approvals.md):313-330 is unfilled | **NOT VERIFIED** | Procedure is offline; first execution needs the signed window |
| **M-13** | **"A SQL Editor session cannot be shown to target staging" is a stage-wide stop condition** ([00](00-stage2-execution-plan.md):306 §8 item 2; J-03 [06](06-redteam-resolution.md):19) **(unchecked)** | The only automated proof is the sentinel, which does not exist (M-03; [04](04-risks-rollback-approvals.md):68 R-10); `select current_database()` has never been run anywhere in the programme | **NOT VERIFIED** | Resolvable **only inside** the A3 window (after A2′(a)); cannot be closed offline |
| **M-14** | **The channel A3 needs must be operable**: every SQL step is "a pasted, reviewed block in the dashboard SQL Editor" ([00](00-stage2-execution-plan.md):39 C1) **(unchecked)** | Pointer actions fail with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`; on 2026-11-02 **every** page was reached by URL navigation and the **one** click attempted failed ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):207-215, `:219-223`); [R-22](04-risks-rollback-approvals.md):80 records click failures with creation-wizard writes succeeding only "on retry" | **NOT VERIFIED** | Needs an authorised operational action (a paste-and-run). Not offline-resolvable; no approval ID covers a *capability test* — it covers statements |
| **M-15** | **"Per-statement restore log"** is an A3 deliverable and evidence requirement ([approval-package-v2](approval-package-v2-ratification-and-forward.md):286, `:289`; [04](04-risks-rollback-approvals.md):212) **(unchecked)** | The artefact is **459** terminated statements (`90-limitations.md`:18); the editor autocommits ([R-10](04-risks-rollback-approvals.md):68); §3.4's stop condition presumes a locatable "statement *n*" ([approval-package-v2](approval-package-v2-ratification-and-forward.md):290); no document records how 459 statements will be batched, logged or transaction-wrapped in the dashboard. `96-review-checks.md` counts and classes them; none of the reviewed documents demonstrates the *load mechanics* | **NOT VERIFIED** | Batching plan is **offline-draftable**; proving it works needs the signed window |
| **M-16** | **"Artefact SHA-256" bound into A3's evidence set** ([approval-package-v2](approval-package-v2-ratification-and-forward.md):289) and "capture file hash" ([04](04-risks-rollback-approvals.md):212) **(unchecked)** | The only digests of record live in the temporary build directory (`100-file-hashes.txt`:1-20). **Zero commits** in `D:\control` ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):31, `:181`; B-10 [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):210), and **no programme document recorded the artefact's byte digest before this audit** — repo-wide grep for `fc996f45`: no matches; this file is the first in-repo record, and it is **not** A3's change record. The artefact is outside the repository **by design** (`90-limitations.md`:134 L-10; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):206 R-5) | **NOT MET** | **Offline-resolvable**: bind the byte digest in the in-repo change record A3 will use, and give the artefact an owner-named durable location by owner instruction. A temp directory is an unstable object of approval |
| **M-17** | **"No hand-editing the artefact after the scan"** ([approval-package-v2](approval-package-v2-ratification-and-forward.md):287, `:297`) | `90-limitations.md`:178-180 asserts the component digests are identical before/after the generator fixes ("the artefact did not change; only the reports did"). **Closed offline by this audit:** the bytes that hash to the scan's LF digest and to the hashes file's raw digest are the **current** bytes, so no edit survived; the artefact's mtime (2026-11-02 17:12:21 local) precedes the scan record (17:12:22) and the hashes file (17:14:05), so neither record post-dates a later edit of the file | **MET** (content identity demonstrated; the mtime half rests on a local, non-UTC clock) | Offline (done). **Owner action still needed:** any future load must re-hash before pasting, because this only proves the state *at the time of this audit* |
| **M-18** | **Drift re-verification immediately before A3**: "Re-run the g1-* count/ACL queries before A3; row counts vs 8/3/14/39 … re-verify immediately before A3; any delta becomes a recorded drift" ([R-28](04-risks-rollback-approvals.md):86) **(unchecked)** | The g1-* queries ran 2026-10-29/30 against **production** ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):138-141). Under C2b/R-43 no production read of any kind is authorised ([00](00-stage2-execution-plan.md):41; [approval-package-v2](approval-package-v2-ratification-and-forward.md):184, `:211-219`), so R-28's mitigation is **unsatisfiable** and no substitute for drift checking has been recorded. A3's own stop condition still routes drift to "re-capture **under A1**" ([approval-package-v2](approval-package-v2-ratification-and-forward.md):290) — a dead branch left behind by C-2 | **NOT MET** | Owner ruling (accept "no drift check possible against a 2026-10-29/30 baseline", in writing) — or a new production-read approval. Not offline |
| **M-19** | **Equivalence diff prepared on both sides** — A3 "then re-running the g1-* count/ACL queries and producing the equivalence diff" ([approval-package-v2](approval-package-v2-ratification-and-forward.md):286); §3 step 9 requires "every difference accepted" ([00](00-stage2-execution-plan.md):93) | `90-limitations.md`:133 (L-9: "equivalence diff has no behavioural side … only meaningful once L-1…L-7 close"); `91-coverage.md`:40-46; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):235 (G3 verdict **not closed**); B-17 [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):217 | **NOT MET** | Structural half is offline-preparable; behavioural half needs a **production read** |
| **M-20** | **The load must satisfy the approval checklist's own definition of the load**: "G6-d schema load (under A3) — 19 tables / 38 functions / 21 policies / triggers / grants, zero rows" ([01](01-staging-project-proposal.md):252) | The artefact emits 19 tables and **0** functions / **0** policies / **0** triggers (`91-coverage.md`:14-21) | **NOT MET** | Owner decision (re-define the checklist row) — the artefact cannot be completed from approved evidence (`90-limitations.md`:125-136) |
| **M-21** | **Quota headroom checked before the run** — pattern stated for the capture run ([approval-package-v2](approval-package-v2-ratification-and-forward.md):229) and stop lines for the stage: log query **80 GB**, DB **400 MB** ([04](04-risks-rollback-approvals.md):309; [R-15](04-risks-rollback-approvals.md):73) **(unchecked for A3)** | Last authorised figures: `Log Query 44.8/100 GB`, `DB 32/500 MB`, at 2026-11-02T07:16Z ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):69-77) — a **historical** read, and log query is org-wide and rising | **NOT VERIFIED** | Needs a fresh authorised dashboard read (staging/org pages). Not a signature item, but not this audit to perform |
| **M-22** | **The load fits the single coordinated 7-day window**, with a dated dashboard touch on or before **2026-11-06** and a dated start kept ([00](00-stage2-execution-plan.md):156-159; [04](04-risks-rollback-approvals.md):88 R-30, `:168-192` §2.5; U-10 [approval-package-v2](approval-package-v2-ratification-and-forward.md):435) | No UTC start was ever recorded; the 2026-11-02 pass explicitly does **not** claim a clock reset ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):201, `:233-242`); no plan document carries the touch as an owned action ([04](04-risks-rollback-approvals.md):424 Q7/Q10) | **NOT MET** | Owner operational instruction (no approval ID covers it — [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):268) |
| **M-23** | **Compensating evidence per C9 for the load itself**: hash, pre/post snapshots, timed window, separate reviewer pass ([00](00-stage2-execution-plan.md):48; [04](04-risks-rollback-approvals.md):198-200 §3 preamble; [R-16](04-risks-rollback-approvals.md):74) **(unchecked for A3 — only ever scored for the 2026-10-30 creation, [approval-package-v2](approval-package-v2-ratification-and-forward.md):389-402)** | Zero of four were satisfied for the creation, and A3 inherits the same structure: no hash binding (M-16), no pre-state beyond the 2026-11-02 reads, no timed window with a UTC start (M-22), and no second reviewer exists | **NOT MET** | Offline for the *plan* (name the compensating evidence in the A3 record); the reviewer pass is structurally impossible — single owner ([R-16](04-risks-rollback-approvals.md):74), U-11 [approval-package-v2](approval-package-v2-ratification-and-forward.md):436 |
| **M-24** | **A2′(b) must NOT be treated as an A3 precondition** (it is the post-load half) | [00](00-stage2-execution-plan.md):91, `:136`, `:142-147`; [approval-package-v2](approval-package-v2-ratification-and-forward.md):251, `:259`, `:272-273` | **NOT APPLICABLE** (correctly sequenced after) | n/a |

**Additional-row subtotal (M-11…M-24, 14 rows):** MET 2 (M-11, M-17) · NOT MET 6 (M-16, M-18, M-19, M-20, M-22, M-23) · NOT VERIFIED 5
(M-12, M-13, M-14, M-15, M-21) · NOT APPLICABLE 1 (M-24).

**Matrix total: 24 rows — MET 6 · NOT MET 10 · NOT VERIFIED 6 · NOT APPLICABLE 2.**

The two rows this audit moved from `NOT VERIFIED` to `MET` (M-06, M-17) were closed by **offline local measurement only**; the
verdict does **not** change, because the failures that decide it (M-07, M-20, M-18, M-19) are evidence-absence failures, not
paperwork failures.

**Limits of that measurement, stated so it is not over-read:** the digest pair proves **consistency, not authorship**. Both
values were self-published by the same build (zero commits, no external timestamp, no third-party witness), so the comparison
shows that the scan record, the hashes record and the bytes on disk agree *now*; it cannot show that no one with write access
to the reports also rewrote the file. Anyone signing A3 must therefore **re-hash at the moment of the load** and record that
digest in the change record (M-16 / S4-BL-01) — the offline reconciliation here is not a substitute for that step.

---

## 3. Consequence analysis: if A3 were signed tomorrow

### 3.1 What the load would actually produce

Loading the artefact of record (`fc996f45…`, `100-file-hashes.txt`:11) into `dzonzgngwxclhfnvxtvu` would create — and only
create — **2 schemas, 19 tables, 183 columns, 137 constraints, 34 indexes, 19 `ENABLE ROW LEVEL SECURITY`, 235 grants, 13
default-privilege statements** (`91-coverage.md`:9-31; `96-review-checks.md`:21 check 5 class census), **plus** the A2′(a)
sentinel row if M-03 were done first. It would create **0 functions, 0 triggers, 0 policies, 0 `auth.users` trigger, 0
publication tables, 0 extensions** (`90-limitations.md`:19-23, `:107-118`; `91-coverage.md`:38; `96-review-checks.md`:64 check 48).

The security consequence is stated by the artefact itself and is not an inference of this audit: **RLS enabled with no
policies denies all rows to every non-bypassing role**, so `anon` and `authenticated` would read nothing from any of the 19
tables while `service_role` and owners bypass (`90-limitations.md`:109-113). The review report's own words: "a shell in
which **every authenticated read returns nothing**, not a parity database" (`96-review-checks.md`:79). This is the
zero-executable count meeting the deny-all consequence: the 21 captured policies exist as comment text only because their
predicates call `private.*` functions the artefact cannot define (`90-limitations.md`:46-49; `91-coverage.md`:21).

Two further consequences the documents make explicit:

* **The load is not cheaply undoable.** Free has no backups and no PITR ([R-35](04-risks-rollback-approvals.md):93;
  `No backups` observed [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):38); slots are 2 active / 2 used / 0
  remaining ([R-38](04-risks-rollback-approvals.md):96), the delete-and-re-create branch is **withdrawn**
  ([04](04-risks-rollback-approvals.md):158-166 §2.4), so a failed or mis-signatured load is repaired in place or recorded
  and lived with. Signing A3 against a `NOT LOAD-READY` artefact therefore buys a durable mis-baselined target, not a
  progress step.
* **A3's own equivalence acceptance cannot pass.** G3-d would report every behavioural row as a difference, and §3 step 9
  requires "every difference accepted" ([00](00-stage2-execution-plan.md):93) — i.e. the owner would be signing an
  acceptance of a known-zero behavioural baseline, with no drift check available either (M-18).

### 3.2 Could G5-S pass? No. Case by case

G5-S is the SQL-runnable subset of **38 cases** after de-duplicating `TE-02` ([05](05-validation-plan.md):216-219).
Post-A3 (structural-only) state per case:

| G5-S cases | Why blocked after a structural-only load | Blocking fact source |
| --- | --- | --- |
| `TE-02`, `P01-T1`, `P01-T2` (expect `42501` / `P0002 device_not_found`) | All three call `private.request_device_recovery(uuid, …)`. **The function does not exist** in a 0-function load, so the outcome is an undefined-function error, not the expected privilege error — the E2/F8 grant question is never reached | [05](05-validation-plan.md):68-70; `91-coverage.md`:14-17 |
| `P01-T3` (`anon` → `42501 permission denied for schema private`) | Would return the **expected shape**, but as a **false pass**: schema-`private` USAGE denial happens before name resolution, so the result is identical whether or not P01 ever ran. It proves nothing about E2/F8 | [05](05-validation-plan.md):71; grant classes census `96-review-checks.md`:21 |
| `P01-T4` (trigger still fires with no EXECUTE) | There is **no trigger** to fire (0 of 7 + 0 of 1) | `96-review-checks.md`:37 check 21 |
| `P01-T6` (re-run §0/§1.5, match post-check table) | P01's own pre-checks "hard-cast `private.request_device_recovery(uuid,uuid)` and `private.remote_session_transition_guard()`… which do not exist" — A5 cannot even start | [approval-package-v2](approval-package-v2-ratification-and-forward.md):312; B-6 [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):207 |
| `P02 T0–T8` (9 cases) | P02 is `APPROVED but NOT EXECUTABLE`: D-01…D-12 all OPEN, **D-07 makes the shipped P02 abort unconditionally**, files must be re-hashed, and its precondition "re-capture the three `prosrc` values from the staging catalogue immediately before apply" has nothing to capture in a 0-function load | [04](04-risks-rollback-approvals.md):213; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):206; [00](00-stage2-execution-plan.md):199-200 |
| `P03 C1, C3, C4, C5, C6, C9` (6 cases) | Order rule `P02 → P03` (J-21) is unsatisfiable while P02 aborts; P03's required production duplicate count is `BLOCKED — PRODUCTION READ NOT AUTHORISABLE`; `C9` needs the existing `remote_session_transition_guard` trigger, which is absent; `C6` tests an index backstop for a trigger that was never created | [00](00-stage2-execution-plan.md):207-221; [06](06-redteam-resolution.md):37; [05](05-validation-plan.md):103-111 |
| `T-01…T-18` (doc 08 SQL cases) | These exercise **per-role row visibility under RLS**. With 19 `ENABLE ROW LEVEL SECURITY` and **0 policies**, two failure modes appear at once: (a) any "sees its own family rows" expectation **fails** under deny-all; (b) any "cannot see another family's row" expectation **passes spuriously** — deny-all mimics correct policy behaviour. (b) is the dangerous one: it would let a report read "T-0x PASS" for a security property nothing enforces | `90-limitations.md`:109-113; [05](05-validation-plan.md):144 ("**Yes** for text; **no** for behaviour"), `:140-141`; `96-review-checks.md`:79 |
| The JWT/principal harness for `T0–T8` | `set local role` + `request.jwt.claims` needs a principal with EXECUTE **and** a non-null `auth.uid()`; `auth.users` emptiness is itself `NOT VERIFIED` (FX-18), staging secrets do not exist (A9 unsigned, [R-39](04-risks-rollback-approvals.md):97), auth settings/JWT parity were never captured (A2′(b) after A3, [01](01-staging-project-proposal.md):249-251), and fixtures need A11 | [05](05-validation-plan.md):78-81, `:94-97`; `BLOCKED — NO REACHABLE CALLER` vocabulary `:54` |

**Therefore:** a signed A3 yields, at best, **0 of 38 G5-S cases passing with evidential value**, plus a set of spurious
greens in the T-01…T-18 / `P01-T3` class that must be recorded as invalid, not as passes. The plan's own ceiling
("no verdict may read 'G5 passed'", [05](05-validation-plan.md):38-40; D-10 [00](00-stage2-execution-plan.md):295) is
consistent with that; the sharper statement is that even **G5-S: n passed** would have n ≈ 0 of evidential value.
Consequences propagate: release-gate item 1 (parity) stays unmet and item 4 (rollback rehearsed) stays `BLOCKED`
([04](04-risks-rollback-approvals.md):279-292); G5-E (104 + 4 = 108) and G5-C are unaffected by the load and remain
`BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` / `BLOCKED — NO APP SOURCE` ([05](05-validation-plan.md):25-26, `:122-132`).

### 3.3 One cross-domain tension to hand to the function/coverage auditor (not resolved here)

`91-coverage.md`:17 states "**0 of 38**" return types and "no G1 query selects one". Two in-repo facts sit awkwardly
against that: `docs/stage1/evidence/functions-and-triggers.md`:34-49 carries a **`Returns` column populated for 14
functions** (`jsonb`, `integer`, `remote_sessions (row type)`), and `patches/S2-P02-e3-actor-binding.sql`:43/`:68`/`:110`
and `patches/S2-P03-e4-session-invariant.sql`:62 declare return types literally (`returns jsonb`, `returns
public.remote_sessions`, `returns trigger`). A0's amended method admits `functions-and-triggers.md` as a source
([approval-package-v2](approval-package-v2-ratification-and-forward.md):183), so whether part of the 0-function result is
over-scoping rather than evidence-absence is a live question **for the coverage domain**, and could change M-07's remedy
from "production read required" to "re-check in-repo evidence". This audit asserts neither; it flags it (S4-BL-11).
Note that even a full 14-function recovery would not clear the deny-all state, because the 21 policy predicates depend on
`private` functions whose bodies are the absent set (`90-limitations.md`:46-49).

---

## 4. Blocker register

### 4.1 Restatement of the two assigned blockers

| ID | Documented statement | Current documented status | Source |
| --- | --- | --- | --- |
| **B-16** | v2 §3.4's A3 precondition chain was unsatisfiable **as written** — it required "A0 + A1 + A2′ all signed" while the owner made A1 inoperative, so "A3 cannot be signed coherently at all" | **RESOLVED IN ITS MAIN PART by correction C-2** (A1 deleted from the chain; §3.4 now reads "A1 is NOT a precondition of A3"; 04 row A3 states the chain as A2′(a) executed → A3 → A2′(b)). **Residual defects survive C-2**: §3.4's *stop condition* still sends drift to "re-capture under A1" ([approval-package-v2](approval-package-v2-ratification-and-forward.md):290), and [04](04-risks-rollback-approvals.md):212 still titles A3's object "G3 **catalogue capture** and schema load". Carried as new blockers S4-BL-04/S4-BL-05 | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):216; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):42; [00](00-stage2-execution-plan.md):109-115 |
| **B-17** | The equivalence diff has **no complete baseline side for 24 functions**; under F-5-A those bodies can never be captured, so A3's parity claim and A5's D-06 `prosrc` assertions are **permanently partial** for that set | **OPEN — realised, not merely prospective.** The reconstruction has now been built and measures 0 executable function/trigger/policy/publication statements (`90-limitations.md`:19-23, `:54`, `:133` L-9; `96-review-checks.md`:44 check 28) | [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):217; [04](04-risks-rollback-approvals.md):276-277 |

### 4.2 New blockers exposed by this matrix

| ID | Blocker | Severity | Owner action required | Offline-only or new approval? |
| --- | --- | --- | --- | --- |
| **S4-BL-01** | **A3 cannot currently be bound to an artefact of record.** A3's evidence row demands an artefact SHA-256, but **no programme document recorded one** (the raw-byte digest appears for the first time in this file); the only digests of record sit in a temporary build directory outside the repo, over zero commits | **HIGH** (partially mitigated by this file, which records the raw-byte digest) | Direct that the digest be bound in **A3's own change record** — not merely in any document — and that the artefact be moved to an owner-named durable location, since a temp directory is an unstable object of approval. A3 should not be signed before such a binding exists | **Offline-only** (a digest is now on record; the location decision is an owner instruction). No new approval |
| **S4-BL-02** | **Secret scan binding — closed in substance by this audit, residual defect is documentary.** `95-secret-scan.md`:29 and `100-file-hashes.txt`:11 disagreed for every file, so §3.4's "completed secret scan **of the artefact**" looked unevidenced. This audit re-hashed `g3-reconstruction-2026-11-02.sql` **read-only** and reproduced **both** recorded values from the **same bytes**: raw bytes (150 566, CRLF) → `fc996f45…d908f6`, and the same content with CRLF→LF (148 615 chars) → `efdbf985…1f7092`. The scan therefore **is** of the exact load object, and no post-scan hand-edit survives the comparison (M-06, M-17). What is still missing is that **the scan report states neither its normalisation nor the raw digest**, so a reader of the artefact directory alone cannot derive the binding | **LOW** (assessed HIGH before the measurement; downgraded by evidence, not by assertion) | Re-emit or annotate `95-secret-scan.md` with its hash method and the **raw-byte** digest, and re-hash immediately before any future load | **Offline-only** — already measured here. No new approval, no read of any project, no write to the artefact directory |
| **S4-BL-03** | **A signed A3 would produce a deny-all shell that no document prohibits signing.** §3.4's preconditions do not include "policies emitted" or "behavioural parity achievable"; only the fence annotation warns. A reader could sign A3 believing a baseline exists | **CRITICAL** (governance/safety) | Decide explicitly, in writing, whether A3 may be signed against a structural-only artefact — and if so, re-word §3.4 and the 01 §7 checklist so the acceptance criterion matches the deliverable | **New owner decision** (an approval-text amendment, not a read) |
| **S4-BL-04** | **Dead branch left in A3 by C-2**: the §3.4 stop condition routes discovered drift to "re-capture under A1", which is `INOPERATIVE`; the matching re-verification obligation in **R-28** ("re-run the g1-* count/ACL queries before A3") is therefore unsatisfiable, and **no substitute drift check is recorded** (M-18) | **HIGH** | Either record "the 2026-10-29/30 capture is a frozen, drift-unchecked baseline; drift is un-detectable by this programme" as an accepted limit, or grant a read class that can check it | Owner decision offline-facing **or** a new production-read approval, at the owner's choice |
| **S4-BL-05** | **Sentinel-ownership text conflict.** [04](04-risks-rollback-approvals.md):68 (R-10) still says "until **A3** creates it", while Sequence A assigns the sentinel to **A2′(a)** before A3; [04](04-risks-rollback-approvals.md):212 retains "catalogue capture" inside A3's object (M-03) | **MEDIUM** | Documentation correction so no reader executes the sentinel under A3 or a capture under A3 | **Offline-only** |
| **S4-BL-06** | **The FX-18 count's home is still stated two ways**: `01:196` says "Resolve with one approved read-only count **before A3**", owner decision B-3 says the count is **the first statement inside** A3 | **MEDIUM** | Re-word `01` §6 row 1 to B-3; until A3 is signed the count stays unrun and `auth.users` emptiness stays `NOT VERIFIED` | **Offline-only** for the wording; running the count needs the A3 signature |
| **S4-BL-07** | **The execution channel A3 needs has never been demonstrated.** No SQL Editor has ever been opened by this programme; the last authorised session had every click fail (`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`), and a 459-statement paste must produce a per-statement log in an autocommitting editor (M-13, M-14, M-15) | **HIGH** | Name an approach: either an owner-instructed, signed, minimal first statement inside the A3 window (the sentinel, then the count, then a bounded statement batch), or an acceptance that the load may be non-executable by channel regardless of signature | Needs an **authorised operational action** (covered by A2′(a)/A3, not offline) |
| **S4-BL-08** | **Load acceptance criterion is unmeetable as written.** `01:252` defines the A3 deliverable as 19 tables / **38 functions** / **21 policies** / triggers; the artefact yields 0 of the last three (M-20) | **HIGH** | Amend the checklist row or accept a re-scoped G3 (option 1 of `S2-EXEC-03` §11) | Owner decision, **offline-facing** |
| **S4-BL-09** | **A3 inherits the zero-of-four compensating-control structure.** Hash binding (absent), pre/post snapshot (no pre-state beyond the 2026-11-02 read), timed window (no UTC start), separate reviewer pass (no second person) — the score was published only for the 2026-10-30 creation, never for the load (M-23) | **MEDIUM** | State in the A3 block what compensating evidence the load will carry; accept, in writing, that self-review is the only control available ([R-16](04-risks-rollback-approvals.md):74) | **Offline-only** (wording), with the structural limit unfixable |
| **S4-BL-10** | **Auto-pause obligation is unowned and now inside the deadline horizon**: dated touch on or before 2026-11-06, no UTC start recorded, no document assigns it ([04](04-risks-rollback-approvals.md):98 R-40; U-10) | **HIGH** (time-critical) | Owner instruction for a dated touch; A3's own load is the cleanest touch but is unsigned | **Owner operational instruction** — no approval ID covers it ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):268) |
| **S4-BL-11** | **Possible under-scoping of the reconstruction** (cross-domain pointer, §3.3): `91-coverage.md`:17 claims 0/38 return types while in-repo evidence names returns for 14 functions and the patch files declare 4 more. If any of those are admissible under A0 as amended, part of the 0-function result is a build-scope question, not an evidence wall | **MEDIUM** (pending the coverage auditor) | Direct the coverage domain to re-test the 0/38 claim against `functions-and-triggers.md` §1 and the patch files, and to state whether in-repo return types are admissible under C-1 | **Offline-only** to check; any artefact change is still an A0-scoped offline build, **not** a load |
| **S4-BL-12** | **Quota state at the load is stale-by-definition**: last authorised read 2026-11-02T07:16Z, log query org-wide and rising toward the 80 GB stop line (M-21) | **MEDIUM** | A fresh read as part of the window's opening checklist | New authorised **dashboard read** (staging/org only, per C2b) |

---

## 5. Auto-pause obligation — `NOT EXECUTED IN THIS PHASE`

* **Obligation:** a **dated Supabase dashboard touch on or before 2026-11-06**. Free projects pause after 7 days idle; the
  clock started at creation on 2026-10-30 ([00](00-stage2-execution-plan.md):156-159; [04](04-risks-rollback-approvals.md):88
  R-30, `:168-192` §2.5; [README.md](README.md):119-122; [approval-package-v2](approval-package-v2-ratification-and-forward.md):48).
* **Status after this audit: `NOT EXECUTED IN THIS PHASE`.** This audit opened no dashboard and performed no touch. It also
  did not run the `auth.users` count, did not create the sentinel, and did not load anything.
* **Owner action remains required.** No approval ID covers the touch ([S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):268);
  it needs a separate owner instruction, and any touch must be recorded **in UTC** from the next capture onward
  ([05](05-validation-plan.md):198-202).
* **No exact UTC expiry is available anywhere.** No UTC start timestamp was ever recorded at creation — only the local
  display `Oct 30, 5:25pm–6:25pm` — so 2026-11-06 is "the latest date the touch can fall on, not a measured deadline"
  ([approval-package-v2](approval-package-v2-ratification-and-forward.md):435 U-10; [04](04-risks-rollback-approvals.md):98 R-40).
* **Whether the 2026-11-02 session reset the clock is `NOT VERIFIED`** ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):201, `:233-242`).
* **DO NOT READ THIS AS CURRENT STATE.** The last **authorised read-only observation** is
  [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) at **2026-11-02T07:16Z** (`STATUS Healthy`, unpaused, 0 tables,
  `No migrations`, `No backups`, 0 Edge Functions, slots 2/2/0). **That is a historical record, not a current
  state.** This audit makes **no claim that staging is currently active, reachable, unpaused or healthy** — as of the
  writing of this file the project's status is **UNKNOWN**, and the pause arithmetic for a paused project against the
  2-active cap is itself `NOT VERIFIED` ([R-38](04-risks-rollback-approvals.md):96; [§2.5](04-risks-rollback-approvals.md):176-179).
* **Interaction with A3:** G6 → G3 → G5-S were planned as **one coordinated window** inside a single 7-day span, and a
  pause or failure inside the window stops the window rather than rolling into a second one
  ([00](00-stage2-execution-plan.md):156-159). With no signature on A2′(a) or A3 and a deadline of 2026-11-06, the window
  has effectively no remaining runway, which is itself a reason **not** to sign A3 as a paperwork step.
* **Re-creation is not a remedy:** the delete-and-re-create branch is withdrawn; deletion is an owner-only act under a new
  A2 record, and 0 slots remain ([04](04-risks-rollback-approvals.md):158-166, `:183-192`).

---

## 6. What is prohibited and unchanged (this audit authorises nothing)

Standing constraints [00](00-stage2-execution-plan.md) §1 C1–C9, [04](04-risks-rollback-approvals.md) §3.2,
[R-43](04-risks-rollback-approvals.md):101, [approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4/§9:

1. **No production access of any kind** — `parent-control-prod` / `hhqgreaoqulmfwfwarhc` is not opened, read, queried,
   compared or configured. The staging-only absolute is binding and, since C-2, includes a **prohibition on
   catalogue-only reads**; the earlier "documented read-only comparison" exception is **closed**
   ([00](00-stage2-execution-plan.md):41; [approval-package-v2](approval-package-v2-ratification-and-forward.md):184; [R-43](04-risks-rollback-approvals.md):101).
2. **All Supabase work targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu` only**; 2 active / 2 used / **0
   remaining**; no third project, no `dev` project, never pausing or deleting production to free a slot
   ([D-12](00-stage2-execution-plan.md):297; [R-38](04-risks-rollback-approvals.md):96).
3. **No SQL of any kind** — including the FX-18 `select count(*) from auth.users;` — without a signed **A3**; no sentinel
   without signed **A2′(a)** ([approval-package-v2](approval-package-v2-ratification-and-forward.md):288; [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):270).
4. **No patch execution.** A5 is approved but **not executable**; D-01…D-12 all OPEN; P02 aborts as shipped (D-07); P03 is
   `BLOCKED — PRODUCTION READ NOT AUTHORISABLE` ([04](04-risks-rollback-approvals.md):213; [00](00-stage2-execution-plan.md):216-221).
5. **No secrets, keys, JWT or credential values** read, created, rotated, copied or logged — name and digest only, under
   **A9**, and the staging DB password's custody stays `NOT VERIFIED` (R-39)
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md):327-347).
6. **No Firebase action** beyond what the ratified creation already covers: app registration, FCM configuration,
   credentials and settings changes remain prohibited; **A12 is unsigned**
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md):121-127; [04](04-risks-rollback-approvals.md):220).
7. **No project create / pause / resume / delete / re-create**, no Edge deploy (A7/A8), no fixtures (A11), no production
   change (A6 — never signed; gate items 1 and 4 `BLOCKED`) ([04](04-risks-rollback-approvals.md):249-254, `:279-292`).
8. **No CLI, Docker, `supabase db dump`, `pg_dump`, `db reset`, `--role-only`, REST, curl, DevTools, hidden endpoints or
   other browser-workaround** (C1; [approval-package-v2](approval-package-v2-ratification-and-forward.md):184).
9. **No hand-editing of the artefact after the secret scan; no repository entry of the artefact without owner
   instruction** ([approval-package-v2](approval-package-v2-ratification-and-forward.md):287; `90-limitations.md`:134 L-10).
10. **No signature, initial, date or prefill on the owner's behalf** — all eleven v2 fences plus the 01 checklist remain
    blank, and **zero physical signature fences are filled anywhere**
    ([S2-EXEC-01-phase0-readiness.md](evidence/S2-EXEC-01-phase0-readiness.md):85-87; [S2-EXEC-03](S2-EXEC-03-documentation-reconciliation-report.md):205 R-4;
    [README.md](README.md):19-20).
11. **No prior instruction, ratification, A0 approval or A5 approval is read as permission for an unsigned operation**; an
    instruction is scope, not approval (R-29), and "none is implied by the ratification in §2"
    ([approval-package-v2](approval-package-v2-ratification-and-forward.md):169-171).
12. **No expected result may be recorded as observed** (C7), **no test may read PASS for an unapplied fix**, and **no
    verdict may read "G5 passed" or "production ready"** ([05](05-validation-plan.md):38-40; [00](00-stage2-execution-plan.md):295, `:46`).
13. **Stop conditions unchanged** ([00](00-stage2-execution-plan.md):301-312; [04](04-risks-rollback-approvals.md):304-309)
    — including sentinel absent, unprovable staging targeting, unrecorded drift, quota stop lines (log query > 80 GB, DB
    > 400 MB) and any request to exceed the approval matrix.
14. **The production release gate is unmet by construction**, and no document in this programme claims a tested rollback
    ([04](04-risks-rollback-approvals.md):8, `:264-298`).

---

## 7. Split view of findings

### Verified (read from a named file)

* A0 is recorded as **approved**, method amended to offline reconstruction from the in-repo `g1-*`/`g1-b3b` capture; its
  physical fence is unfilled — [README.md](README.md):83, [04](04-risks-rollback-approvals.md):209, [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):162,
  [approval-package-v2](approval-package-v2-ratification-and-forward.md):175-206.
* A1 is `INOPERATIVE` and **removed from A3's chain** — [00](00-stage2-execution-plan.md):87, `:90`, `:109-115`; [approval-package-v2](approval-package-v2-ratification-and-forward.md):211-219, `:288`.
* A2′, A3, A9, A12 are **unsigned**; zero physical signature fences filled anywhere — [04](04-risks-rollback-approvals.md):205, `:212`, `:220`;
  [README.md](README.md):86; [S2-EXEC-01-phase0-readiness.md](evidence/S2-EXEC-01-phase0-readiness.md):85-87.
* The sentinel is **not created** (staging has 0 tables in `public`) — [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):85-86, `:194`.
* A secret scan exists and reports **0 matches / 0 stop conditions** over 13 files — `g3-build/95-secret-scan.md`:10-13, `:51`.
* The artefact measures **459 active statements with 0 executable function / trigger / policy / publication statements**,
  and is labelled `NOT LOAD-READY` — `g3-build/90-limitations.md`:14-23; `91-coverage.md`:14-21, `:33-38`.
* Per-object provenance exists as **515 manifest rows** with a five-label distribution — `g3-build/90-limitations.md`:26, `:96-104`.
* Ratification is **option (i), recorded 2026-11-02, grants nothing forward**; A12's amended prohibition quoted — [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):33-64; [approval-package-v2](approval-package-v2-ratification-and-forward.md):118-127.
* A5 is **approved but not executable** — [04](04-risks-rollback-approvals.md):213.
* The artefact's raw-byte digest appeared in **no** file under `D:\control` before this audit (repo-wide grep for
  `fc996f45`: no matches). **This file is now the first in-repo record of it**, which mitigates but does not close M-16:
  A3's evidence row has to bind a digest in the *change record*, and the object itself still lives outside the repository
  in a temporary directory (`90-limitations.md`:134 L-10).
* No rollback has been tested anywhere in the programme; item 4 of the release gate is `BLOCKED` — [04](04-risks-rollback-approvals.md):8, `:288-292`.

### Inferred (follows from evidence; not observed)

* The scanner hashes **LF-normalised text** while `100-file-hashes.txt` hashes **raw bytes** — **measured here, not
  inferred**: re-hashing `g3-reconstruction-2026-11-02.sql` read-only gave raw bytes (150 566, CRLF) =
  `fc996f450690d8b6…d908f6` and LF-normalised (148 615 chars) = `efdbf985cfc72f72…1f7092`, i.e. each recorded digest
  reproduced exactly from the same bytes. The binding is therefore **now evidenced by this file**; the scan report itself
  still states no method, so a reader of the artefact directory alone cannot derive it (M-06).
* A structural-only load **would** put staging into deny-all for `anon`/`authenticated` (Postgres semantics stated by the
  artefact at `90-limitations.md`:109-113, never tested here).
* A3's practical window has near-zero runway given the 2026-11-06 touch deadline — inference from
  [00](00-stage2-execution-plan.md):156-159 + [04](04-risks-rollback-approvals.md):168-192, not from any observed platform state.

### Missing evidence (no artefact in the repo speaks to it)

* A raw-byte digest of the load object bound into **A3's own change record** — as opposed to recorded in some document
  (this file now carries the value, which is not the same thing as the approval binding) — and an owner-named durable
  home for the artefact (M-16 / S4-BL-01).
* A statement, inside `95-secret-scan.md`, of the hash method and of the **raw-byte** digest of the object it scanned
  (M-06 / S4-BL-02 — the substance is now established by this audit, the self-describing record is still absent).
* Any drift check available between the 2026-10-29/30 baseline and a future load — R-28's route is closed by C2b and no
  substitute is written down (M-18 / S4-BL-04).
* Any record that the dashboard SQL Editor can be opened and a statement submitted under the current tooling failure mode
  (M-14 / S4-BL-07).
* A batching/log plan for a 459-statement load producing the per-statement restore log A3's evidence row demands (M-15).
* A UTC start or expiry for the auto-pause clock, and any owner assignment for the 2026-11-06 touch (M-22 / S4-BL-10).
* A statement of what compensating evidence A3 itself will carry (M-23 / S4-BL-09).
* Any re-scoping decision recorded for `01:252`'s load composition (38 functions / 21 policies) (M-20 / S4-BL-08).

### Unverified (explicitly not established by this audit)

* `auth.users` emptiness in staging — FX-18 / R-42; the count is **unrun** and this audit did not run it
  ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md):164-181).
* Current staging state (active/paused/healthy/reachable): **UNKNOWN**; the 2026-11-02T07:16Z observation is historical.
* Whether the artefact's **mtime** is trustworthy as an ordering proof — the digests establish content identity today,
  but the timestamps quoted in §1/§2 are **local (+0530) filesystem times**, never UTC, and are not an approval record
  ([05](05-validation-plan.md):198-202 requires UTC for programme records). A future load must re-hash before pasting.
* Whether the "0 of 38 return types" claim is complete, given the §3.3 tension — **coverage domain**, not resolved here.
* Whether extension, view, sequence and publication membership exist in production — `UNKNOWN`, not zero, by the
  artefact's own register (`90-limitations.md`:60-65; `91-coverage.md`:27-31).
* Whether any copy of the staging DB password exists outside the owner's control (R-39).
* Whether a paused project counts toward the 2-active cap, and whether slot reuse after deletion works (R-38) — neither
  may be tested.

### Recommendations (to the lead auditor; none is an action this audit took)

1. **Do not put A3 to the owner as a routine next signature.** Present it with the matrix: 10 NOT MET, 6 NOT VERIFIED,
   and the fact that a signed A3 loads a **deny-all, behaviour-free** shell that cannot be cheaply undone.
2. **Close the remaining offline paperwork** — S4-BL-01 (bind the raw-byte digest in **A3's own change record**, and give
   the artefact a durable owner-named home instead of a temporary build directory) and S4-BL-02 (state the scan's hash
   method inside `95-secret-scan.md`, whose substance this audit has already reconciled) — so that *whatever* the owner
   eventually signs has a named, self-describing object. **Re-hash immediately before any future load**: this audit's
   digest comparison proves the content as at 2026-11-02, not in perpetuity.
3. **Force the real fork into one decision**, as `S2-EXEC-03` §11 already frames it: accept a structural-only baseline
   (and re-word v2 §3.4 + `01` §7 + R-28/R-43's drift expectation accordingly), **or** rescope the staging-only absolute
   so real definitions can be captured. There is no third option that produces a load-ready artefact.
4. **Treat M-13/M-14/M-15 as a separate executability question** from the approvals: even fully signed, A3 has never been
   demonstrated to be runnable through the sanctioned channel.
5. **Assign the 2026-11-06 touch to the owner now**, independently of every other decision, and record it in UTC.
6. **Refer S4-BL-11 to the coverage auditor** before the structural-only acceptance decision is taken; if part of the
   0-function outcome is build scope rather than evidence absence, the fork in (3) changes shape.
7. **Keep A2′(b) after A3** in every future re-wording — it is a SQL necessity, not a preference
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md):251, `:259`).
8. **Do not merge A3 with A5 or A9 in the owner's attention.** Each block grants only its own object
   ([approval-package-v2](approval-package-v2-ratification-and-forward.md):167-171); A5's approval already grants an
   operation the decision set makes unreachable ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md):179-184).

---

## 8. No operational action by this document

This file authorises nothing by existing. In producing it: **no dashboard page was opened; no URL was visited; no SQL of
any kind was run — including the `auth.users` count; no sentinel was created; no project was opened, paused, resumed,
deleted or re-created; no secret was read or created; no patch was touched; no Firebase action occurred; no CLI, REST or
DevTools path was used; nothing in `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/` was **written, moved, renamed or
modified** — the only operations on it were reads, line/byte counts and a local SHA-256 recomputation performed to test
the M-06/M-17 digest question (which is why those two rows can read `MET` rather than `NOT VERIFIED`); no
existing document, patch or approval fence was modified; no git operation was performed.** **Exactly one new file was
created: this one.** Every classification above is drawn from a cited file, line or identifier; where a precondition has
no evidence, it is recorded as `NOT VERIFIED` or `NOT MET` and left unmet rather than assumed.
