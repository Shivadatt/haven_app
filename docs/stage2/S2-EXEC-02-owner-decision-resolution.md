# S2-EXEC-02 — Owner decision & approval-conflict resolution report

**Task class:** owner-decision and approval-resolution. **Operational execution performed in this task: NONE.**
**Date/time decisions were recorded (UTC): 2026-11-02, collected 09:40Z–09:52Z** (timestamp taken from the local clock
at the moment the decision request was issued: `2026-11-02T09:40:52Z`).

| Prohibited in this task (§8) | Held |
| --- | --- |
| Supabase dashboard access / Firebase console access | **YES — none performed.** No page opened. |
| SQL / migrations / schema or sentinel creation | **YES — none run.** |
| Patch change or application | **YES — the three `.sql` files are untouched** (hashes in §6.3). |
| Secret creation, reading or rotation | **YES — none.** No value appears anywhere in this file. |
| Firebase app registration / FCM configuration | **YES — none.** |
| Edge deployment / production access | **YES — none.** |
| Git commits / repository modification | **YES — no commit, and no authoritative document edited.** The only file created by this pass is this report. |

**Standing owner constraints, reaffirmed and carried forward to every future phase:**
(1) **browser dashboards only** for Supabase and Firebase — no CLI, terminal, PowerShell, CMD, REST, curl, Postman,
DevTools, direct database connection or undocumented workaround; SQL only in the Supabase Dashboard SQL Editor, and only
after approval for that exact SQL. (2) **Supabase work targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu` and no
other project** — reaffirmed as absolute by the Phase D decision below.
*Recorded deviation from the task footer:* this task was issued with "use browser supabase and firebase", but §8 bars
any console access during an owner-decision pass. The browser rule is applied as a **forward** restriction on
authorised work, not as a licence to open a dashboard now. Nothing was opened to "check".

**Method:** 7 read-only research agents, disjoint document domains, no stateful tool, no file writes
(doc-inventory and package-v2 text; 01 proposal/sentinel; patch defects + patch files; 04 risk register + approval
matrix; 05/06/evidence labelling; working papers A–J + Stage 1 G3 baseline plan). Findings below were re-checked
against the files, not accepted on report.

---

## 1. RATIFY / REVERSE decision — **RECORDED: option (i) RATIFY**

The owner recorded the §2 retrospective decision as **(i) RATIFY**: the 2026-10-30 creation of
Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` and Firebase `haven-staging` / `haven-staging-46822`
is accepted after the fact, and the two shells stay as they are.

**Amended A12 prohibition, exactly as ratified** ([approval-package-v2 §2](approval-package-v2-ratification-and-forward.md)` :114`):

> project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited.

**Disclosed to the owner before the decision, and disclosed again here:**

* Ratification accepts the **zero-of-four compensating-control shortfall** stated in v2 §5
  (`:336-341`) — no artefact hash, no before/after snapshot, no UTC start timestamp, no separate reviewer pass.
* Ratification **authorises no future operation**. Verbatim exclusion list (`:114`): "Grants **no** schema, **no**
  sentinel, **no** settings change, **no** secret, **no** patch, **no** app registration, **no** FCM, **no** credential,
  **no** Edge Function, **no** production change. Each still needs its own block in §3."
* The auto-pause obligation stands: **dated dashboard touch on or before 2026-11-06**; slots stay **2 active / 2 used / 0
  remaining** (B-7).
* **R-36 and R-37 are now historical rather than live**: the Firebase creation is no longer an unratified breach of the
  A12 prohibition, and the executed A2 action is now accepted. The *unsigned paper* state of A0/A2 is unchanged
  (§3 below) — ratification does not retro-sign a signature block that was never signed.

**Status of the physical signature fence.** The fenced block at v2 `:127-142` still reads
`OWNER (name): ______________________ DATE/TIME (UTC): ______________________` followed by
`owner decision — not signed by this document`. **It has not been transcribed or prefilled** — §7 of this brief forbids
prefilling signatures, and the owner's own hand is the record. This report is the decision record for the agent-side
workflow; if the owner wants the fence itself filled, that is an instruction to issue, not an inference.

**Option (ii) not chosen**, so: no deletion proposal is prepared, and `haven-staging-46822` remains a shell with zero
registered apps, zero credentials, no FCM configuration, environment type `Unspecified`, and **Spark plan `NOT
VERIFIED`** ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :130-135`, `:115-119`).

---

## 2. B-2 — sentinel-vs-load ordering — **RECORDED: Sequence A (A2′ sentinel → A3 schema load)**

The owner approved **Sequence A**: `private.s2_environment` (one row `staging`) is created **before** the schema load;
A2′ precedes A3.

The rejected text, kept on record because it is the plan-of-record today and must be corrected:
[00-stage2-execution-plan.md](00-stage2-execution-plan.md)` :90` step 7 = "**G3-c** staging schema load … gate **A3**";
`:91` step 8 = "**G6-b / A2′** sentinel + settings … precondition `step 7 loaded`"; `:126` "now sequenced **after** the
G3-c load (§3 step 8)"; `:130` "the schema load is a **single G3-c action gated by A3**; the sentinel follows the load."
00's supersession clause `:78-79` reaches only working papers ("Any earlier statement in a working paper that
contradicts this table is superseded"), and `:25-28` places approval packages **outside** the plan of record — so 00
never overrode package v2, which is why this was an owner decision and not a document reconciliation.

Technical consequences the owner accepted by choosing A, recorded here:

1. **The wrong-project guard is live before any DDL.** The sentinel's purpose per 00 `:132-135` is that "a patch pasted
   into the wrong SQL Editor tab fails before its first DDL statement"; the in-file guards are
   [S2-P01 `:105-108`](patches/S2-P01-e2-f8.sql#L105), P02 `:17-20`, P03 `:24-27` (`to_regclass('private.s2_environment')
   is null` → `raise exception … refusing to run outside staging`).
2. **The equivalence diff must exclude the sentinel by name**, and A3's before/after table counts start at **1**, not 0
   (00 `:135` already excludes it "by name" from the G3 parity diff).
3. **Residual ordering exception inside A2′ — recorded, not silently resolved.** A2′ item (b) includes the Realtime
   4-table publication, which v2 §3.3 `:207` words as "re-add the four-table publication … **once those tables exist**"
   — impossible before A3. Under Sequence A the owner's choice therefore executes as **A2′(a) → A3 → A2′(b)**, and the
   single A2′ signature must be worded to allow that split. Until it is re-worded, **A2′ is not executable as written**
   (see §7, correction C-3). The alternative — running item (b) before the tables exist — is not possible.
4. Working-paper statements that now agree with the decision: [parts/G](parts/G-g5-validation.md)` :39-40` lists G6-b
   before G6-c, but `:72` says "**Seeded after G6-c**" — `:72` is superseded by this decision.

---

## 3. B-3 — FX-18 `auth.users` count approval home — **RECORDED: option A (inside A3's approved scope)**

The owner approved that the exact statement **`select count(*) from auth.users;`**, against
**`dzonzgngwxclhfnvxtvu`** only, is **part of A3's approved scope** as its first statement — matching the wording
already in [v2 §3.4](approval-package-v2-ratification-and-forward.md)` :231`.

**Live state unchanged by this decision: A3 is UNSIGNED (§4). So the count still has no covering approval, and no SQL
of any kind may be run.** Deciding *where* the approval lives does not create it.

Facts the count must settle, quoted as recorded: the staging Auth footer printed `Total:` `10` `user` `s`
`(estimated)` while "The results grid element was present and empty … **zero user rows rendered**"
([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :96`, `:141`); the production control reading was
`Total: 8 users` **without** the `(estimated)` qualifier (`:143`). `auth.users` emptiness is therefore
`NOT VERIFIED — dashboard total contradicts, unresolved` (`:164-167`, FX-18 / R-42 at [04 `:86`](04-risks-rollback-approvals.md#L86)).

Boundary conditions retained: **count only** — no rows, emails or other PII inspected or disclosed; ref echoed and
matched to the console header before any statement; `count ≠ 0` → **STOP**, the clean-shell premise fails, P01 §0.4
cardinalities (`4 rows total`) and the "wrong-project run is impossible" arguments are void; count
unavailable/ambiguous/failed → **STOP**; wrong or uncertain project → **STOP**; **no other project may be used for this
check**.

Corollary: S2-INSP-03 `:169-173` ("**No signed approval covers it**: A1 is scoped to *production catalogue reads*, A3 is
*schema load*, A2′ … *sentinel plus approved settings*") becomes **superseded on the scope question** once A3 is signed,
and stays correct until then. It must be annotated, not deleted (§7, correction C-4).

---

## 4. F-5 — staging-only vs A1 — **RECORDED: option A (staging-only stays absolute; A1 is inoperative)**

The owner kept the standing instruction **absolute**: every Supabase action targets `parent-control-staging` /
`dzonzgngwxclhfnvxtvu` and **no other project**. Consequences:

* **A1 is not signed and cannot be signed as written.** Its whole object — SELECTs against production
  `hhqgreaoqulmfwfwarhc` ([v2 §3.2](approval-package-v2-ratification-and-forward.md)` :174-198`, and 00 `:87` step 4
  "G3-a **production read-only catalogue capture** … **A1**") — is prohibited. **No production access occurred in this
  task and none is authorised by anything in this report.** C2b (00 `:41`) and R-43 (04 `:87`) are **reaffirmed, not
  amended**.
* **The approved alternative method is offline reconstruction from evidence already in the repository.** Verified in
  this sweep (it is not newly captured):
  | In-repo production evidence | What it holds | Citation |
  | --- | --- | --- |
  | `docs/stage1/evidence/g1-q1…g1-q10` + `g1-b3b` (2026-10-29/30) | catalogue/config capture, wrapped in `begin transaction read only` | [g1-run-manifest-20261029.md](../stage1/evidence/g1-run-manifest-20261029.md)` :9-13` |
  | same manifest `:41` | "**Rows read | none. `prosrc` is function source, not data**" | `:41` |
  | `g1-b3b` `bodies` | **14 of 38** function bodies — including **every patch-touched function**: `private.remote_session_transition_guard`, `private.request_device_recovery`, `public.request_device_recovery`, `public.request_remote_session`, `private.unlink_child`, `is_family_member`, `is_family_parent`, `shares_active_family`, `handle_new_user`, and the trigger bodies | [functions-and-triggers.md](../stage1/evidence/functions-and-triggers.md)` :17-19` |
  | `docs/stage1/evidence/schema-columns.md` | 19 tables / 183 columns, rendered constraint flags | [01 `:128`](01-staging-project-proposal.md#L128) |
  | counts on file for the future equivalence diff | 19 tables · 21 policies (15/3/2/1) · 38 functions (14 public / 24 private, 34 definer) · 7+1 triggers · 137 constraints · 62 indexes · 149/191 grants · 24 default-ACLs · ACL groups 27/4/5/2 | [parts/B `:155-164`](parts/B-g3-dashboard-baseline.md#L155) |
* **Honest limit created by this choice, recorded as a blocker not a pass:** 24 `private` bodies were never read
  (PA3; 00 `:161`), and [parts/B `:92`](parts/B-g3-dashboard-baseline.md#L92) states a fresh capture "is strictly more
  source than the documentation currently holds". So the artefact is **provably incomplete**: the 24 bodies must be
  carried as `UNVERIFIED`, and the A5 `prosrc`-hash post-check required by **D-06** cannot be satisfied for any
  uncaptured function. Backup/PITR substitution is unavailable and withdrawn (Free plan; B `:211`).
* **A1's redundancy is now moot** — but recorded for the audit trail: the capture A1 would have re-run largely
  duplicates in-repo evidence dated 2026-10-29/30, so its only remaining value was a drift check under R-28.

---

## 5. Approval status — seven independent blocks

Recorded as **explicit owner selections made through the decision interface** at 2026-11-02T~09:45Z / ~09:52Z, each
block selected separately. **No signature fence was prefilled, and RATIFY grants none of these.**

| Block | Object | Decision | Executable? | What blocks it |
| --- | --- | --- | --- | --- |
| **A0** | G3 method amendment | **APPROVED** | **Yes** — local/offline only | Ratification (i) satisfied; but §3.1 wording still names a *dashboard capture* first step that F-5-A replaces with in-repo evidence (correction C-1) |
| **A1** | production read-only catalogue capture | **INOPERATIVE — prohibited by the owner's F-5-A decision** | **No, ever, under current scope** | Requires a new owner ruling to un-prohibit production reads at all |
| **A2′** | sentinel + approved settings | **UNSIGNED — not selected** | No | Needs the owner's A2′ decision; and once signed, needs the split wording of §2 item 3 (C-3) |
| **A3** | staging schema load | **UNSIGNED — not selected** | No | Needs A0 ✓ + **A1 (now impossible)** + **A2′ (unsigned)** + artefact (B-1) + secret scan + the FX-18 count |
| **A5** | patch application P01→P02→P03, staging only | **APPROVED** | **No — not executable** | D-01…D-12 all OPEN; files must be re-hashed after correction; A3 must complete first (staging is empty); the signed hash **is not** the current pre-correction hash |
| **A9** | fresh staging secrets | **UNSIGNED — not selected** | No | R-39 password custody unresolved; needs A2′ done, A3 for anything functions read |
| **A12** | Firebase / FCM work | **UNSIGNED — not selected** | No | Ratification ✓ but needs a recorded G2 decision + identity boundary + credential-handling rules; and FCM does not exist in this programme |

Not in this package and unchanged: **A6** (production change — never signed; the 7-item gate in 04 §4 has items 1 and 4
`BLOCKED`), **A7/A8** (Edge), **A10**, **A11** (fixtures), **A13**. **There is no A4 in the plan of record** (00 `:245`;
04 §3 rows `:190-202` jump A3→A5); the historical A4 rows at parts/B `:187` and parts/I `:92`, and the A4 FK/trigger gate
at parts/B `:187`/`:201`, stay dead references and must not be cited.

**Non-implication retained verbatim** (v2 `:148-150`): "None is implied by another, none is implied by the ratification
in §2, and none is inferred from silence or from a button being present in a console (R-29)." Also 04 `:230`: "Approval
for A6 never implies A8, A9 or A12. No approval is inferred from silence."

**Coherence flag on the A5 approval:** A5 was approved while A3 stays unsigned, so A5 is a **signed-but-unactionable**
approval. It is not invalid — v2 §3 allows blocks to be signed out of order and lets preconditions block execution — but
**nothing in A5 may execute until A3 executes**, and A3 cannot execute while A1 is prohibited unless its §3.4
precondition text is corrected. Recording this rather than smoothing it over: **A5's approval currently grants an
operation that the approved decision set makes unreachable.** The owner may wish to rescind or re-state it after C-1/C-2
are applied.

---

## 6. Updated blocker register

### 6.1 Closed or reclassified by these decisions

| ID | Prior state | Now | Basis |
| --- | --- | --- | --- |
| **B-2** | STOP — owner decision | **RESOLVED — Sequence A** | §2 above; document correction still owed (C-2/C-3) |
| **B-3** | STOP — owner decision | **RESOLVED — inside A3 scope** | §3 above; A3 unsigned → statement remains unauthorized |
| **F-5** | conflict needing ruling | **RESOLVED — staging-only absolute, A1 inoperative** | §4 above |
| **R-36** | live risk (Firebase created against A12) | **RATIFIED — closed as a live risk**; the amended A12 text governs | v2 §2 (i) |
| **R-37** | live risk (A2 executed unsigned) | **Retrospectively accepted**; the *record* stays "unsigned" as historical fact | v2 §2 (i); 04 `:211-214` |
| **B-9** (compensating controls) | open shortfall | **Accepted by the owner** as disclosed; still zero-of-four satisfied — acceptance ≠ satisfaction | v2 §5 |

### 6.2 Still open (restated without attempting to fix any of them)

| ID | Blocker | Severity | Status |
| --- | --- | --- | --- |
| **B-1** | **No G3 artefact and no migration manifest exist anywhere.** The only `.sql` files in the repo are the three patches; `D:\control\supabase\` holds `config.toml` + `.gitignore` and **no `migrations/`**; 00 `:88` describes the artefact as "One reviewed `.sql` artefact, kept **outside** the repository" — nothing of the kind exists. **Path forward is now A0-offline reconstruction from in-repo Stage 1 evidence, provably short 24 bodies.** | P0 | OPEN — actionable under A0, not yet done |
| **B-5** | **D-01…D-12 all `OPEN`** (+ out-of-range **D-10b** at [patch-defects `:316`](patch-defects-before-a5.md#L316)). Seven of them require a **patch-file revision** and therefore change the hashes: D-01, D-02, D-05, D-06, D-07, D-09, D-10, D-10b. **D-07: P02 as shipped always aborts** — `-- select set_config('haven.patch_gate','S2-P02',true);` at P02 `:28` sits commented while the block at `:31-35` requires it. | P0 | OPEN |
| **B-6** | **A5 cannot execute against an empty staging database.** Each patch aborts at its own absent sentinel; P01 §0 pre-checks hard-cast `private.request_device_recovery(uuid,uuid)` and `private.remote_session_transition_guard()` (`:40-41`), which do not exist in staging; rollback cannot be rehearsed before A3. | P0 | OPEN |
| **B-7** | **Auto-pause deadline ≈ 2026-11-06, exact UTC start unknown** (R-40; 04 `:160-167`). Today is 2026-11-02. **No dashboard activity was performed to forestall it, per §6 of this brief.** A dated touch is an operational action needing separate owner instruction. | P1 (time-critical) | OPEN — owner action required |
| **B-8** | **R-39 — staging DB password custody `NOT VERIFIED`** (04 `:84`): typed owner-side at creation, no copy in repo/record/transcript, no vault; whether any copy exists outside the owner's control is the owner's to confirm. Re-setting it is an **A9** act. | P1 | OPEN |
| **B-10** | **Zero Git commits; no tracked-file provenance.** All six top-level entries untracked; `git rev-parse HEAD` fails; hashes are the only provenance and bind to no signature. | P1 | OPEN — owner decision (out of scope here) |
| **B-11** | **G5-E / G5-C blocked**: no Edge Function source, no app source in this repo. G5-E is **104 suite (19 TE + 78 PE + 7 CI) + 4 patch-specific = 108** per [05 `:25`](05-validation-plan.md#L25); 05 `:118`/`:207` reconcile the "105" literal enumeration to 104 (TE-02 is a SQL case), so README `:86`'s "104 of 105" is the pre-reconciliation phrasing. G5-S `BLOCKED — STAGING IS EMPTY`; G5-C `BLOCKED — NO APP SOURCE IN THIS REPO`. "G5 passed" is not an available verdict (05 `:32`). | P1 | OPEN |
| **B-12** | **Slots 2 active / 2 used / 0 remaining** (R-38). No recovery headroom; the delete-and-re-create branch is withdrawn (04 `:145-151`); whether a PAUSED project counts toward the cap is `NOT VERIFIED`. | P1 | OPEN — structural |
| **B-13** | **Identifier-register inconsistencies** — see correction list C-6…C-9. | P2 | OPEN |
| **B-14** | **Evidence labelling inconsistent; screenshots not verified** — S2-INSP-02 is **not** labelled accessibility-tree (zero `take_snapshot` hits; `:9` `SCREENSHOT EVIDENCE: NOT VERIFIED`) while README `:48` generalises "accessibility-tree text with URL and timestamp" across the evidence set; README `:91-94` correctly says no platform screenshot record and no platform audit log exists. | P2 | OPEN |
| **B-15** | **S2-EXEC-01 brief truncated at 445 lines**, ending mid-list under "### Prohibited"; its deliverable/verdict sections were never supplied. | P3 | OPEN — owner re-supply |
| **NEW B-16** | **v2 §3.4's A3 precondition chain is now unsatisfiable as written** — it requires "A0 + A1 + A2′ all signed" while the owner has made A1 inoperative. Until C-2 is applied, A3 cannot be signed coherently at all. | P0 | OPEN — direct consequence of F-5-A |
| **NEW B-17** | **Equivalence diff has no complete baseline side for 24 functions** — under F-5-A those bodies can never be captured, so A3's parity claim and A5's D-06 `prosrc` assertions are permanently partial for that set. | P1 | OPEN — accepted limit of the chosen method |

### 6.3 Patch integrity (recomputed locally in the Phase 0 pass; unchanged here)

| File | Lines | SHA-256 | State |
| --- | --- | --- | --- |
| `patches/S2-P01-e2-f8.sql` | 191 | `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51` | unchanged, **unapplied**, `PROPOSED` |
| `patches/S2-P02-e3-actor-binding.sql` | 155 | `01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67` | unchanged, **unapplied**, always aborts (D-07) |
| `patches/S2-P03-e4-session-invariant.sql` | 127 | `8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4` | unchanged, **unapplied**; no post-check (D-10b); no in-file rollback |

These are **pre-correction** hashes and must **not** become the hashes signed at A5.

---

## 7. Exact document sections requiring correction after these decisions

**None applied in this task** (§9: "Do not change authoritative documents until the owner decisions are explicit"; the
decisions became explicit only at the end of this pass, so the corrections are handed over as a scoped list, each one a
mechanical transcription of a decision already recorded — not a new judgement).

| # | File · section | Current text | Required change | Source decision |
| --- | --- | --- | --- | --- |
| **C-1** | [approval-package-v2 §3.1](approval-package-v2-ratification-and-forward.md)` :156` Authorises cell + signature fence `:165-166` | "dashboard read-only catalogue capture → offline reconstruction…" | Replace the capture step with "reconstruction from the 2026-10-29/30 `g1-*`/`g1-b3b` in-repo catalogue capture"; add the recorded limit "24 `private` bodies absent → `UNVERIFIED`" | F-5-A |
| **C-2** | v2 §3.4 `:231`; 00 §3 `:87` step 4 and `:90`; README A-matrix row | "A3 preconditions: **A0 + A1 + A2′ all signed**"; 00 step 4 = production capture gated on A1 | Remove A1 from A3's precondition chain and name the in-repo baseline as the substitute; state that **A1 is void under C2b as reaffirmed**. 04 §3 row A1 `:191` → `PROHIBITED / INOPERATIVE` | F-5-A + B-16 |
| **C-3** | v2 §3.3 `:207`; 01 §7(b) `:232-234`; 00 §3 `:91` | A2′ as one atomic block; §3.3(b) needs tables to exist | Word A2′ as **(a) sentinel — before A3** and **(b) settings/Realtime publication — after A3**, with the A2′ signature text amended to cover both halves | B-2 = Sequence A |
| **C-4** | [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md)` :169-173` | "**No signed approval covers it**" | Annotate (retain as written) that the owner placed the count **inside A3's scope** on 2026-11-02; the read stays unauthorized until A3 is signed | B-3 = option A |
| **C-5** | [README](README.md)` :3`, `:5-6`, `:44-46` one-line status table; 00 §3 header `:7-8`; [S2-DOC-02](S2-DOC-02-reconciliation.md) | "AWAITING RETROSPECTIVE RATIFICATION"; "authorises nothing by itself" | Re-stamp as **RATIFIED 2026-11-02, option (i)**, with the amended A12 sentence quoted and "grants nothing forward" preserved | §1 |
| **C-6** | [04 §1](04-risks-rollback-approvals.md)` :41-42` vs rows `:46-87` | "Register range: **R-01…R-43**" but 42 rows; **no R-41 row exists** (cited at 04 `:27`, 00 `:318`, CHANGELOG `:55,80,160`, parts/I `:161-162`) | Add the R-41 row or renumber the citations; fix S2-REVIEW-03 `:471` which still says "R-01…R-41" | B-13 |
| **C-7** | [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md)` :393-423` register vs `:462,467` | declares **FX-01…FX-17**; FX-18 lives only at S2-DOC-02 `:70` and 00 `:304` | Add FX-18 to the register, or point the range at its two definition sites | B-13 |
| **C-8** | [parts/J](parts/J-redteam.md) (stops at J-22) and S2-REVIEW-03 `:20` ("J-01…J-22") | 06 `:17-39` defines all **J-01…J-23** | Extend parts/J and fix the stale range in S2-REVIEW-03 | B-13 |
| **C-9** | README `:48` | "captures (accessibility-tree text with URL and timestamp)" for the whole set | Qualify: S2-INSP-02 is not labelled accessibility-tree and its screenshot status is `NOT VERIFIED`; S2-CREATE-01 records "no UTC conversion" | B-14 |
| **C-10** | [01](01-staging-project-proposal.md)` :174`, `:232` | "required before any DDL" — now **consistent** with the decision, but 01 `:197`/`:226` still read `AWAITING RETROSPECTIVE RATIFICATION` | Re-stamp ratification; keep the before-DDL rule (owner selected Sequence A) | §1 + B-2 |
| **C-11** | 05 `:24-26`, README `:72-73` | G5 statuses | No change required by these decisions; they stay `BLOCKED`. Add the FX-18 dependency already at 05 `:45` | — |
| **C-12** | [CHANGELOG](CHANGELOG.md) | — | Add an S2-EXEC-02 entry: decisions recorded, **no operational action**, corrections listed and not applied | all |

---

## 8. Next permitted action and required approval ID

**Permitted now, no further approval needed** (authorised by ratification §2(i) + **A0**, both recorded):

* **N-1 — document reconciliation C-1…C-12**, as a scoped documentation pass. Local file edits only; no console, no SQL.
* **N-2 — A0 execution, offline only**: reconstruct the G3 artefact in dependency order from
  `docs/stage1/evidence/schema-columns.md`, `functions-and-triggers.md`, `g1-q1…g1-q10` and `g1-b3b`
  (auth → schemas → tables/FK → functions → triggers → policies → grants → default privileges → platform config;
  the `auth.users` trigger as a separate file), **then scan it for hardcoded secrets before it enters the repository**,
  and record the 24 absent bodies as `UNVERIFIED`. **This touches no dashboard and loads nothing.**
  Required approval ID: **A0** ✓ (already recorded).

**NOT permitted — each needs an owner act first:**

| Action | Required approval ID | Current state |
| --- | --- | --- |
| Any SQL, including the `auth.users` count | **A3** | UNSIGNED (count now in its scope, but the block is not signed) |
| Sentinel creation | **A2′** | UNSIGNED; and needs C-3 wording before it can execute |
| Schema load into staging | **A3** | UNSIGNED + C-2 correction + artefact + secret scan |
| Patch application | **A5** | **APPROVED but non-executable** — needs C-1/C-2, D-01…D-12 cleared, files re-hashed, A3 complete |
| Secrets | **A9** | UNSIGNED + R-39 custody answer |
| Firebase app / FCM | **A12** | UNSIGNED + recorded G2 decision |
| Any production read or write | **A1 / A6** | **Prohibited / nonexistent** — A6 has never been signed and the 7-item gate has items 1 and 4 `BLOCKED` |
| Dated dashboard touch before 2026-11-06 | owner instruction, no block | **Not performed in this task** |

---

## 9. Source documents read in this pass

All current versions, actual paths: [README.md](README.md) `:3` `SCAFFOLD CREATED — REMEDIATION NOT STARTED`;
[approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) `:3`
`AWAITING OWNER DECISION`; [00-stage2-execution-plan.md](00-stage2-execution-plan.md) `:3` (S2-DOC-02 corrected, §9
addendum); [01](01-staging-project-proposal.md) `:3` `EXECUTED — SHELL ONLY`;
[02](02-findings-to-fix-mapping.md) `:3` `PROPOSED — NOT APPLIED`; [03](03-patch-S2-P01.md) `:3`
`PROPOSED — NOT APPLIED` (`:135` now reads "2 rows per function … 4 rows total", which **contradicts**
`S2-P01-e2-f8.sql:55` "exactly one row per signature" — D-01's re-check is still owed);
[04](04-risks-rollback-approvals.md) `:3`; [05](05-validation-plan.md) `:3` `PROPOSED — NOT RUN`;
[06](06-redteam-resolution.md) (no status line); [patch-defects-before-a5.md](patch-defects-before-a5.md) `:3`;
[S2-EXEC-01 Phase 0 readiness report](evidence/S2-EXEC-01-phase0-readiness.md);
[S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md); working papers
[parts/A](parts/A-staging-spec.md)–[parts/J](parts/J-redteam.md) (all 10 carry the SUBORDINATE/PARTLY SUPERSEDED banner
and an S2-DOC-02 addendum; A `:9` still reads `PROPOSED — NOT CREATED`, now falsified by the shell's existence);
plus [docs/stage1/12-g3-baseline-plan.md](../stage1/12-g3-baseline-plan.md) and
[docs/stage1/evidence/g1-run-manifest-20261029.md](../stage1/evidence/g1-run-manifest-20261029.md).
**Not used for any signature:** [approval-package-a0-a2.md](approval-package-a0-a2.md), banner `:1`
`SUPERSEDED 2026-11-02 — DO NOT SIGN`.

## 10. Verdict

`S2-EXEC-02 — DECISIONS RECORDED (RATIFY · Sequence A · count in A3 · staging-only absolute) · A0 AND A5 APPROVED ·
A2′/A3/A9/A12 UNSIGNED · A1 INOPERATIVE · NO OPERATIONAL ACTION AUTHORISED · PHASE 3 NOT STARTED`

The owner's four conflict decisions and two approvals are recorded. **No operation was executed, authorised for
execution, or prepared for execution beyond a document list.** A0 and N-2 (offline reconstruction) are the only
permitted next actions; every dashboard, SQL, secret and Firebase step remains gated behind an unsigned block.
