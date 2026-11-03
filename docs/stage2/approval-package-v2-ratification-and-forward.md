# Stage 2 approval package — revision 2 (2026-11-02): ratification and forward authorisations

**Status: `AWAITING OWNER DECISION`.** This document is a request and a record of an outstanding decision. It is not an
approval, not a signature, and not an authorisation. **It REPLACES [approval-package-a0-a2.md](approval-package-a0-a2.md),
which must not be signed in its current form**: its line 27 states `Staging project created | **No**`, which is falsified
by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md), and its A2 signature block asks the owner to authorise in
advance an action that was already performed on 2026-10-30. Signing the old block today would certify a false premise and
would either ratify the Firebase breach silently, authorise a second creation, or approve four G6 sub-actions that were
deliberately not performed. The old file is retained unchanged as the historical request; a supersession banner marks it.

Every signature line below is **blank by design** and stays blank. Nothing in this document signs, initials, dates or
pre-fills an approval on the owner's behalf. Ground truth:
[S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) and
[S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §B, §C, §J. Approval rows:
[04](04-risks-rollback-approvals.md) §3, §3.1.

---

## 1. What has already happened

Recorded as an **EXECUTED ACTION AWAITING RETROSPECTIVE RATIFICATION** — never as an action awaiting future
authorisation. *(Status of this heading line, restated 2026-11-02: the action is now **RATIFIED — option (i)**; see §2.
This section keeps its original wording as the record of what was on the table when the package was written.)*
On 2026-10-30, under the direct owner instruction *"create new project on both supabase and firebase …
not use parent-control-prod"*, two **EMPTY** staging projects were created through the browser consoles. No SQL ran
against any project. No schema, no sentinel, no secret, no app, no credential, no Edge Function exists.

### 1.1 Supabase — `parent-control-staging` (S2-CREATE-01 §2)

| Field | Observed value | Label |
| --- | --- | --- |
| Project name | `parent-control-staging` | VERIFIED |
| Project ref / URL | `dzonzgngwxclhfnvxtvu` / `https://dzonzgngwxclhfnvxtvu.supabase.co` | VERIFIED |
| Region | `ap-northeast-2` — Northeast Asia (Seoul), read-only after creation | VERIFIED |
| Plan / compute | Free / NANO | VERIFIED |
| Organisation | `symqztrmaziuwdibcfrq`, single owner `spg7753@gmail.com` | VERIFIED |
| Tables / migrations / branches / Edge Functions | 0 / no migrations / none / 0 | VERIFIED |
| `auth.users` contents | The dashboard Auth page renders **zero rows** yet prints `Total: 10 users (estimated)`; no user was created by this programme and no sign-up was ever run against this project | **NOT VERIFIED** — FX-18, [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3 |
| Re-confirmation, 2026-11-02T07:16Z | `STATUS Healthy` (unpaused), 0 tables in `public`, `No migrations`, `No backups`, 0 Edge Functions, slots 2/2/0, usage meters unchanged | VERIFIED (read-only page views, `parent-control-staging` only) |
| "Automatically expose new tables" | **OFF** (re-set immediately before submit after a re-render) | VERIFIED |
| Sentinel `private.s2_environment` | **NOT CREATED** | — |
| Schema (G3) | **NOT LOADED** — requires A3 | — |
| Secrets | **NONE CREATED** — requires A9 | — |
| Database password | Set owner-side in the browser; **custody unconfirmed** (R-39) | NOT VERIFIED |
| Versions | Postgres `17.11.0.003` · Auth `2.197.0` · PostgREST `14.18` | VERIFIED |
| Project slots | **2 active / 2 used / 0 remaining** | VERIFIED |
| Usage meters at capture | Egress 0.14/5 GB · DB 32/500 MB · MAU 10/50,000 · Storage 0/1 GB · Log Ingestion 0.20/1 GB · Log Query 44.8/100 GB | VERIFIED |
| Auto-pause | 7 days idle from 2026-10-30 → **dated dashboard touch on or before 2026-11-06**; no UTC start timestamp exists | OPEN constraint |

### 1.2 Firebase — `haven-staging` (S2-CREATE-01 §3)

| Field | Observed value | Label |
| --- | --- | --- |
| Display name | `haven-staging` | VERIFIED |
| Project ID | `haven-staging-46822` (the exact stem was globally taken; ID and name differ) | VERIFIED |
| Project number | `381273275501` | VERIFIED |
| Plan | Spark / No-cost (the `Upgrade` call-to-action was not clicked) | VERIFIED |
| Google Analytics | **OFF** as instructed | VERIFIED |
| Gemini AI assistance | **OFF** — default was on (deviation, §1.4) | VERIFIED |
| Environment type | `Unspecified` — **not changed** (deviation, §1.4) | VERIFIED |
| Apps | `There are no apps in your project` — no Android/iOS/Web/Flutter app | VERIFIED |
| Credentials | **NONE** — no `google-services.json`, no `GoogleService-Info.plist`, no service-account key, no FCM config | VERIFIED |
| Account | `shiwa2172000@gmail.com`, not switched; pre-existing `flutter-flow-w-ith-f-ir-6592ib` untouched | VERIFIED |

### 1.3 The three recorded owner scope answers (S2-CREATE-01 §1)

| # | Question | Owner's answer | What it covered |
| --- | --- | --- | --- |
| 1 | Scope of the Supabase project | **"Shell only"** | Empty project; **no** sentinel, **no** settings checklist, **no** secrets, **no** schema |
| 2 | Database password custody | **"You type it yourself"** | Password handled in the browser by the owner; no value read, transcribed or stored by the agent |
| 3 | Firebase project | **"Create `haven-staging`, Analytics off"** | Display name and the Analytics switch only |

These are **instructions, not approvals**. They are scope, and they do not substitute for a signature the owner has
never given: A0 has never been approved by anyone and the packaged A2 signature block was never signed (04 §3.1, R-37).
*(Superseded wording, annotated 2026-11-02 under C-1/C-5: A0 is now approved as a **recorded decision** — fence
unfilled, method amended to offline reconstruction — and the creation is ratified under option (i), which grants nothing
forward; the packaged A2 signature block is still, literally, unsigned. The point of this paragraph stands: an
instruction is scope, not a signature.)*

### 1.4 Deviations from the plan

| # | Deviation | Why it happened | Disclosure |
| --- | --- | --- | --- |
| 1 | **Gemini in Firebase switched OFF** (wizard default: on) | The owner named Analytics only; the wizard presented an unanticipated choice and the least-privilege option was taken | Unrequested settings change; recorded, not hidden (S2-CREATE-01 §4.1). Switch read `false` before create |
| 2 | **Environment type left `Unspecified`** (`Staging` was offered) | Setting it is a settings change outside the approved scope | Not changed; recommended as a follow-up under A2′/A12 as applicable (S2-CREATE-01 §4.3) |

### 1.5 The prohibition this action exceeded

[04](04-risks-rollback-approvals.md) §3 row A12 forbids **"Any Firebase action in Stage 2"**, carried again in
[00](00-stage2-execution-plan.md) §4 Step 8 and [01](01-staging-project-proposal.md) §7. The `haven-staging-46822`
creation **exceeds that prohibition**. It was owner-instructed, so it is not unauthorised in substance, but **no approval
row covers it** (S2-REVIEW-03 §C row A12, B-01, R-36). It is therefore an executed action awaiting retrospective
ratification — decision §2 below.

### 1.6 Production

`parent-control-prod` / `hhqgreaoqulmfwfwarhc` is **untouched**: no production page beyond the organisation list was
opened, no SQL Editor against it, no table data read, no secret, setting, user, family, device or telemetry record read
or written, no pause, delete or plan change initiated (S2-CREATE-01 §6). Patches S2-P01/P02/P03 are **unchanged and
unapplied** (hashes stable per S2-REVIEW-03 header); all twelve defects **D-01…D-12 remain OPEN**
([patch defects](patch-defects-before-a5.md)); **P02's shipped file always aborts** because its approval gate ships
commented out while the block requires it (D-07).

### 1.7 Architecture boundary that constrains every Firebase decision

**Supabase Auth is the single identity authority.** Firebase is **FCM-transport-only by intent**, and **FCM does not
exist in this programme**. Firebase Auth, Firestore and Cloud Functions are **not approved requirements** and appear in
no approval row here. Source: S2-REVIEW-03 §G, [01](01-staging-project-proposal.md) §6.

---

## 2. Ratification decision — owner only

One decision, two **mutually exclusive** options. **This document cannot choose, cannot sign and cannot date it.** Until
the owner records one of them, R-36 and R-37 stay live and §3–§9 of this package cannot be executed in any order that
depends on a staging target.

> **RATIFIED — 2026-11-02 — OPTION (i).** Recorded in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1 from the
> owner's explicit instruction (C-5). The decision is *recorded*, not *signed*: the physical fence below remains
> unfilled and no name or UTC time has been transcribed into it (R-29 — a recorded decision is not a signature).
> The amended A12 prohibition now in force is, verbatim: **"project creation permitted under owner instruction; app
> registration, FCM configuration, credentials and settings changes remain prohibited."**
> **Retrospective ratification grants nothing forward.** It authorises no schema, sentinel, settings change, secret,
> patch, app registration, FCM configuration, credential, Edge Function or production change, and it does not sign any
> block in §3. R-36 and R-37 are closed as *decided*; the auto-pause obligation (dated dashboard touch on or before
> 2026-11-06) and the 2/2/0 slot state are unchanged by it. Option (ii) is void and was never executed:
> `haven-staging-46822` still exists.

| Option | What it means | Consequences | What it does NOT do |
| --- | --- | --- | --- |
| **(i) RATIFY** | The two shells stay as they are, and the executed creation is accepted after the fact. | A12's Stage-2 prohibition is amended to: **"project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited."** The auto-pause obligation stands (touch on or before 2026-11-06). Slots stay 2/2/0. | Grants **no** schema, **no** sentinel, **no** settings change, **no** secret, **no** patch, **no** app registration, **no** FCM, **no** credential, **no** Edge Function, **no** production change. Each still needs its own block in §3. |
| **(ii) REVERSE** | The owner personally deletes the Firebase project `haven-staging-46822`. | The record notes the deletion with date and operator; Stage 2 returns to **Supabase-only**; A12 stays exactly as written (any Firebase action in Stage 2 prohibited); G2/G7 stay deferred; the Gemini deviation closes with the project. | Does not by itself free or reuse a Supabase slot; does not undo the Supabase shell; does not authorise any later Firebase re-creation without a new A12 decision. |

**Rules that apply to either option:**

1. **Deleting a project is itself an owner-only action.** No agent deletes, pauses, restores or re-creates a project on
   the owner's behalf (04 §2.4 step 3, §2.5).
2. **Deletion consumes nothing recoverable.** Neither plan includes backups or PITR (Free / Spark); no data, schema,
   secret or credential exists in either project to lose — that is what §1 verifies. The only irreversible cost is the
   Firebase project ID namespace (`haven-staging-46822` is global and immutable and cannot be reissued).
3. **Option (ii) does not reopen the Supabase slot question.** Slot reuse after deletion is UNPROVEN and whether a
   PAUSED project counts toward the 2-active cap is `NOT VERIFIED` (R-38); nothing must be deleted to test it.

```text
RATIFICATION — EXECUTED CREATION OF 2026-10-30 (Supabase parent-control-staging / dzonzgngwxclhfnvxtvu;
Firebase haven-staging / haven-staging-46822)

I have read docs/stage2/approval-package-v2-ratification-and-forward.md §1 and §2. I record exactly one option:

[ ] (i)  RATIFY the two shells, with A12's Stage-2 prohibition amended as quoted in §2.
[ ] (ii) REVERSE — I will delete the Firebase project myself; record the deletion and return Stage 2 to Supabase-only.

I accept the compensating-control shortfall stated in §5 (zero of four required controls satisfied).
This decision grants nothing listed in §4 and authorises no production change.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision — not signed by this document
```

**Fence state after the S2-EXEC-03 pass (2026-11-02): unchanged and deliberately so.** Both options remain `[ ]`, and
`OWNER (name)` / `DATE/TIME (UTC)` remain blank. The recorded decision in the blockquote above is a governance record
transcribed from the owner's instruction; it is not a signature and was not written into this fence.

---

## 3. Forward approval blocks — seven, independently signable

Each block below is separate. Signing one grants **only** what that block states. None is implied by another, none is
implied by the ratification in §2, and none is inferred from silence or from a button being present in a console
(R-29). A block may be signed while a later one stays unsigned; the preconditions column is what then blocks execution.

### 3.1 A0 — G3 method amendment

**AMENDED 2026-11-02 by correction C-1 (S2-EXEC-02 §7), applied in the S2-EXEC-03 pass.** The owner decision recorded
in [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §5 is **A0 = APPROVED**, and the standing instruction
**staging-only absolute** (R-43) makes A1 inoperative — so the method this block approves cannot include a production
capture. The pre-amendment wording is quoted under the table so the change stays auditable; nothing
here claims a capture that did not happen.

| | |
| --- | --- |
| **Authorises** | Replacing Stage 1's G3 method (`supabase db dump` under Docker + `pg_dump` no-diff proof, both excluded by constraint C1) with: **offline reconstruction of one `.sql` artefact in dependency order, built ONLY from the read-only production catalogue capture already in this repository (`docs/stage1/evidence/g1-q1…g1-q10`, `g1-q3b`, `g1-b3b`, `schema-columns.md`, `functions-and-triggers.md`, captured 2026-10-29/30 under the G1 run manifest) → (`auth` prerequisites → schemas → tables → primary/foreign keys → constraints → indexes → functions → triggers → RLS enablement → policies → grants → default privileges; the `auth.users` trigger as a separate, never-applied component; Realtime publication as a separate post-table operation) → secret scan before the artefact enters the repository → load into staging under A3 → staging equivalence diff.** Objective unchanged; method replaced; **no new production read is authorised by this block.** |
| **Explicitly does NOT authorise** | **Any production access of any kind, read-only included** — that was A1's subject and A1 is `INOPERATIVE` under the staging-only instruction, so the capture step is deleted from the method, not deferred. Loading anything (that is **A3**). `supabase db reset`, `--role-only`, `pg_dump`, CLI, Docker, DevTools, REST or hidden endpoints. Any production write. Any patch. **Claiming a full production schema capture: this method cannot produce one.** |
| **Preconditions** | Ratification §2 option (i) — recorded 2026-11-02. Approval of this amendment is recorded; the physical fence below is still unfilled. |
| **Evidence required** | The amended method text in the change record; the superseded Stage 1 method quoted; the accepted limits below recorded as accepted; **per-object provenance for every reconstructed object** with the labels `VERIFIED FROM SOURCE` / `RECONSTRUCTED FROM MULTIPLE SOURCES` / `INFERRED` / `UNVERIFIED` / `NOT PRESENT IN EVIDENCE`; a coverage report whose counts are measured, never asserted. |
| **Stop conditions** | If the owner will not accept the limits (no platform restore point; pre-P01 baseline; row data out of scope) → record `BLOCKED — METHOD NOT PERMITTED` (R-14) and stop; do not substitute a CLI method. If the artefact would have to state a fact the evidence does not carry — a function return type, a missing body, an extension list — **record `UNVERIFIED` and stop that object; never guess SQL.** |
| **Accepted by signing A0** | Baseline is a **pre-P01 snapshot** and its post-P01 `proacl` divergence is approved, not drift (R-19); **no platform restore point** — "restore validation" means rebuilding from the artefact, not restoring a backup (R-35); **row data, `auth.users`, storage, migration history and Edge bundles are out of scope** (R-01). |
| **Disclosed limits of the offline method (added by C-1; these are costs, not caveats)** | **(1) 24 of the 38 inventoried function bodies do not exist in any approved evidence** — the `private` schema bodies were never read in Stage 1, so they are `NOT PRESENT IN EVIDENCE` and stay `UNVERIFIED`; they were also never scannable for a pasted credential. **(2) No return type was captured for any of the 38 functions** (no G1 query selects one), so **no `CREATE FUNCTION` can be written without inventing a type** — which in turn makes every trigger, policy and publication statement unexecutable. **(3) `pg_extension`, `pg_publication_tables`, views and sequences were never queried**, so their expected counts are unknown, not zero. Consequence, stated plainly: **the artefact produced under this method is not a production-equivalent dump and cannot pass A5 D-06 `prosrc` hash validation for the uncaptured bodies.** |

Pre-amendment **Authorises** cell, retained so the change is auditable: *"dashboard read-only catalogue capture →
offline reconstruction of one `.sql` artefact in dependency order (…) → secret scan before the artefact enters the
repository → apply to staging → staging equivalence diff."* The first step is what C-1 removes.

```text
A0 — G3 METHOD AMENDMENT (offline reconstruction from the existing Stage 1 catalogue capture + staging equivalence)
I approve the method in docs/stage2/approval-package-v2-ratification-and-forward.md §3.1 AS AMENDED 2026-11-02 (C-1):
reconstruction is built only from the in-repo g1-*/g1-b3b capture, with no new production read, and I accept the three
limits listed there plus the disclosed limits of the offline method (24 private bodies absent = UNVERIFIED; no function
return type captured; extension/publication/view inventory unknown). This authorises no production capture run (A1 is
inoperative), no load (A3), no CLI/Docker/pg_dump/db reset, no patch, no secret, no production write.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision recorded 2026-11-02 (S2-EXEC-02 §5) — the physical fence above is NOT filled by this document
```


### 3.2 A1 — production READ-ONLY catalogue capture — **`INOPERATIVE` (2026-11-02)**

> **Status: INOPERATIVE — this block cannot be signed to any useful effect and authorises nothing.** The owner's
> standing instruction is **staging-only absolute** ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §4; R-43):
> production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` is not opened, queried or configured. Every action this
> block would authorise is an action against that project, so the approval is void in substance, not merely unsigned.
> **A1 is removed from A3's precondition chain (§3.4, correction C-2); the substitute source is the read-only capture
> already in this repository** (`docs/stage1/evidence/g1-*`, `g1-b3b`, captured 2026-10-29/30 under
> [g1-run-manifest-20261029.md](../stage1/evidence/g1-run-manifest-20261029.md)). The text below is retained unchanged
> as the historical request: deleting it would erase the record that production capture was once contemplated, and
> re-enabling it takes a new owner instruction, not a signature here.

**This block gates catalogue capture. No read-only SQL of any kind may be run against `hhqgreaoqulmfwfwarhc` before
A1 is signed.** A1 was previously self-asserted for the Stage 2 inspections; from here it is a written approval, not a
claim (04 §3 row A1).

| | |
| --- | --- |
| **Authorises** | **SELECT-only queries against Postgres catalogues and configuration views** in the production SQL Editor, limited to: `pg_get_functiondef`, `pg_get_triggerdef`, `pg_get_constraintdef`, `pg_get_indexdef`, `pg_policies`, `pg_proc` (`prosrc`, `proacl`, `proconfig`), `pg_class.relacl`, `pg_default_acl`, `pg_extension`, `pg_publication_tables`, and the g1-* count/ACL queries used for the equivalence diff — plus re-running the same set against staging for §3.1 step 5. |
| **Explicitly does NOT authorise** | **Any DDL and any DML** — no `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `INSERT`, `UPDATE`, `DELETE`, `GRANT`, `REVOKE`, no `SET` persisted beyond session scope, no `SELECT` into a write. **No table data**: no row of any application table, no `auth.users`, no `safety_alerts`/`remote_sessions`/`device_commands`/`webrtc_signals` contents, no PII, no hashes. No artefact construction into the repository (that is A0's step 2), no load (A3). |
| **Preconditions** | A0 signed (it defines the query set). Project ref stated in every result file. Log-query headroom checked before the run (44.8/100 GB at capture). |
| **Evidence required** | Full query text (read-only), project ref, UTC timestamp, result file path and hash, statement count, rows returned per statement. Stored with the change record; never containing a secret value. |
| **Stop conditions** | Log Query reaching **80 GB** (R-15) — stop and record. Any statement that cannot be expressed as catalogue-only SELECT — stop and return; do not "adapt" it. A paste landing in the wrong tab (two similar dashboards; the editor autocommits) — stop, record, do not retry silently. |

```text
A1 — PRODUCTION READ-ONLY CATALOGUE CAPTURE
I approve only the catalogue/config-view SELECT classes enumerated in §3.2, against project
hhqgreaoqulmfwfwarhc, for schema-definition capture. I forbid any DDL, any DML, any table data, any auth.users row,
any PII export, and any write to production. Evidence: query text, ref, UTC time, file hash.
This authorises no load (A3), no sentinel (A2′), no patch (A5), no secret (A9).

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision — not signed by this document
```

### 3.3 A2′ — remaining staging shell configuration ONLY — **executes in two separated halves (C-3, 2026-11-02)**

> **Sequencing correction (owner decision Sequence A, [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §2).**
> A2′ was worded as if one signing event could execute the whole block. It cannot: half of it must run **before** the
> schema load and half **only after** it. This block is therefore **one approval, two execution stages**:
> **A2′(a) — sentinel — before A3**; **A2′(b) — settings verification and the Realtime publication — after A3**,
> because `ALTER PUBLICATION … ADD TABLE` requires those four tables to exist, and staging has none until A3 runs.
> A2′ remains **UNSIGNED**; nothing below is authorised by this note.

This is the **forward** half of what the executed A2 described but did not perform. It is not a ratification of the
creation (§2 is) and it grants nothing that the "shell only" answer withheld.

| | |
| --- | --- |
| **Authorises** | **A2′(a) — before A3:** creating the wrong-project sentinel `private.s2_environment` in `dzonzgngwxclhfnvxtvu` with exactly one row `staging` (G6-b) — the object every patch aborts on when absent. **A2′(b) — after A3, once the tables exist:** the approved staging settings checklist — **SSL enforcement**, **connection logging**, and **Realtime membership/publications** (re-add the four-table publication `device_commands`, `remote_sessions`, `safety_alerts`, `webrtc_signals`; membership is not in a schema capture and must be added explicitly) — together with recording the Data API exposed-schema state and confirming auto-expose remains OFF (01 §6, §7(b)). **The two halves are separately executable and separately evidenced; (b) cannot precede A3 as a matter of SQL, not preference.** |
| **Explicitly does NOT authorise** | **Schema loading — NOT in this block** (that is A3). **Secrets — NOT in this block** (that is A9; the old package's item listing secrets inside A2 is withdrawn, REVIEW-02 C-01 / FX-08). No patch (A5). No fixture (A11). No Edge Function (A7/A8). No Firebase action of any kind (A12). No production settings change — production states are **read and mirrored into a checklist**, not modified. No delete/re-create/pause. No acceptance of the un-actioned "automatically enable RLS on new tables" notice unless separately instructed. |
| **Preconditions** | Ratification §2 = option (i). Dashboard-only (C1). Ref `dzonzgngwxclhfnvxtvu` **mis-typing guard**: the ref must be echoed in the change record and matched against the console header before any statement runs. |
| **Evidence required** | Statement text as executed; before/after counts (tables 0 → 1 for the sentinel); settings page values as read **and** as set; the reviewer pass performed at a different time with its own notes (R-16 — a time-separated self-review, never a claim of two-person control); UTC timestamps. |
| **Stop conditions** | Sentinel creation requiring anything beyond one table and one row. Any settings page that demands a plan change. Any statement landing in the production tab — stop immediately, record, do not undo by hand. |

```text
A2′ — REMAINING STAGING SHELL CONFIGURATION ONLY (TWO EXECUTION STAGES, ONE APPROVAL)
I approve, in project dzonzgngwxclhfnvxtvu only:
  (a) BEFORE the schema load (A3): creation of private.s2_environment with one row 'staging';
  (b) ONLY AFTER A3 has created the tables: the settings checklist items SSL enforcement, connection logging and
      Realtime membership/publications for device_commands, remote_sessions, safety_alerts and webrtc_signals, plus
      recording Data API/auto-expose state.
I acknowledge that (b) is not executable before (a)+A3 because a publication cannot reference tables that do not
exist, and that signing this block does not by itself start either stage: A3 must be signed before any load, and each
half is executed and evidenced separately. I explicitly exclude schema load (A3), secrets (A9), patches (A5),
fixtures (A11), Edge Functions (A7/A8), any Firebase action (A12) and any production change.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

UNSIGNED — owner decision recorded 2026-11-02 as Sequence A (S2-EXEC-02 §2); the physical fence above is NOT filled
```

### 3.4 A3 — schema loading into staging

| | |
| --- | --- |
| **Authorises** | Applying the reconstructed G3 artefact to `dzonzgngwxclhfnvxtvu` in dependency order, plus the separate `auth.users` trigger file, with a per-statement restore log, then re-running the g1-* count/ACL queries and producing the equivalence diff. |
| **Explicitly does NOT authorise** | Loading **table data** or any row from production. Patches (A5). Secrets (A9). Edge Functions (A7/A8). Firebase (A12). Any production change (A6). Hand-editing the artefact after the secret scan. `--role-only`, `db reset`, `pg_dump`. |
| **Preconditions** | **A2′(a) signed AND executed (the sentinel must exist first), plus a completed secret scan of the artefact** with hits reviewed and recorded (never silently redacted — `prosrc` is the one catalogue column that can hold a pasted credential; 24 bodies were never read in Stage 1, so those bodies are **unscanned and unscannable**, and the artefact says so). **[00](00-stage2-execution-plan.md) step 1's "load gated on A0 and A2" is superseded by this row (REVIEW-02 C-02 / CD-08): A3 gates the load.** **A1 is NOT a precondition of A3 — correction C-2, 2026-11-02:** A1 is `INOPERATIVE` under the staging-only absolute instruction (R-43), and the artefact A3 loads is reconstructed offline, under approved A0 as amended by C-1, from the read-only capture already in this repository (`docs/stage1/evidence/g1-*`, `g1-b3b`). No production access is authorised by A3, and none is needed for it. **Status today: A3 is UNSIGNED, so none of the following is executable** — including the count. **First statement of the A3 window, before any load: `select count(*) from auth.users;` on ref `dzonzgngwxclhfnvxtvu`, recorded with the project ref and UTC timestamps** — this closes FX-18 (the dashboard printed `Total: 10 users (estimated)` over an empty grid, [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3). If the count is not 0, **stop**: the clean-shell premise fails, the pre-check cardinalities in P01 (§0.4, `4 rows total`) and the "wrong-project run is impossible" arguments are void, and the discrepancy must be explained before a single DDL statement runs. No other project may be used for this check. |
| **Evidence required** | Artefact SHA-256, secret-scan result, per-statement restore log, equivalence table with every difference named and accepted, statement error text. |
| **Stop conditions** | DDL error at statement *n* → 04 §2.4 branch: stop, classify, repair in place within one session or **record the state — the delete-and-re-create branch is withdrawn** (R-38, 0 slots). Drift discovered between the A1 capture and the load → stop, re-capture under A1, record the delta (R-28). |

```text
A3 — SCHEMA LOAD INTO STAGING
I approve loading the hashed, secret-scanned G3 artefact (and the separate auth.users trigger file) into
dzonzgngwxclhfnvxtvu, after A0 (method as amended 2026-11-02 by C-1: offline reconstruction from the in-repo g1-*
capture) and after A2'(a) has created the sentinel. A1 is INOPERATIVE under the staging-only instruction and is not a
precondition of this or any other block. I forbid loading table data or any production row, hand-editing the
artefact after scan, applying patches, creating secrets, deploying Edge Functions, or touching production.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

UNSIGNED — this block is not approved; the artefact it would load is NOT load-ready (see its 91-coverage.md and
96-review-checks.md), so this fence must not be filled on the assumption that a baseline exists
```

### 3.5 A5 — patch application (P01 → P02 → P03), staging only

| | |
| --- | --- |
| **Authorises** | Applying **S2-P01, then S2-P02, then S2-P03** in that order to `dzonzgngwxclhfnvxtvu`, each inside an explicit transaction, with the file's §0 pre-checks read before the body, post-checks asserted rather than eyeballed, and **a rollback rehearsal after each patch**. |
| **Explicitly does NOT authorise** | **Any production application — that is A6 plus the 7-item gate, which does not exist today** (04 §4 items 1 and 4 are `BLOCKED`). No secret creation or rotation (A9). No Edge deploy (A8). No fixture data (A11). No Firebase (A12). No improvised catalogue repair mid-patch. No applying a file whose hash is not the hash signed here. |
| **Preconditions** | **D-01…D-12 all cleared and the three patch files re-hashed** ([patch defects](patch-defects-before-a5.md); current hashes are pre-correction: P01 `1edad404…97be51`, P02 `01403cd7…b88c67`, P03 `8f92cc0f…d60ecd4`). Note **D-07: as shipped, P02 always aborts** — its approval gate is commented out while the block requires it, so the applied text ≠ the hashed text. A3 must be complete: no patch is applicable to an empty database — each aborts at its own sentinel and P01's §0 pre-checks hard-cast functions that do not exist there yet (S2-REVIEW-03 PE-01). Rollback is not even rehearseable before A3. |
| **Evidence required** | Hash of **the file actually executed**; §0 output; post-check output with mandatory assertions (`prosrc` hash, overload count — D-06); test results; the exact rollback text; the reviewer pass at a separate time (R-16). |
| **Stop conditions** | Sentinel mismatch (wrong-project guard). Any pre-check row count disagreeing with the corrected document. A post-check that cannot be read before the commit (D-02 two-pass rule). Any unhandled error shape beyond the recorded one. P03 double-request returning 500 → accepted as a **staging caveat**, never a release claim (R-20). |

```text
A5 — PATCH APPLICATION, STAGING ONLY
I approve applying S2-P01 → S2-P02 → S2-P03 to dzonzgngwxclhfnvxtvu in that order, after D-01…D-12 are cleared and the
files re-hashed, with a rollback rehearsal after each and a separate-time reviewer pass. This is not A6: it authorises
no production application, no secret change, no Edge deploy, no fixture creation, no Firebase action.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision — not signed by this document
```

### 3.6 A9 — fresh staging secrets

| | |
| --- | --- |
| **Authorises** | Creating **fresh** staging-only secret values in `dzonzgngwxclhfnvxtvu`: anon key, service-role key, **database password**, JWT signing secret, `PAIRING_HASH_PEPPER`, `CRON_SECRET`, TURN credentials — recorded by **name and digest only**. |
| **Explicitly does NOT authorise** | Copying, pasting or referencing **any production value**. Reading or writing a secret value into this repository, a record, a transcript or logs. Rotating the production pepper (forbidden in Stage 2 — 04 §3 row A9). Any Edge deploy sequencing beyond recording set → verify. Any Firebase credential (A12). Any production change (A6). |
| **Preconditions** | Ratification §2 = (i); A2′ complete (settings recorded) and, for anything the functions read, A3. **R-39: the database password already set at creation has unconfirmed custody** — the owner typed it in the browser, no value entered the repository, the record or the transcript, and no vault or secret manager holds it; whether any copy exists outside the owner's control is the owner's to confirm. **Re-setting that password is itself an A9 action** and must not be performed under §2, A2′ or A3. |
| **Evidence required** | Secret **name**, digest from the dashboard secrets list, the set → verify sequence, and the statement that no value was read by the agent. Password re-set recorded as a name/digest event with a UTC timestamp. |
| **Stop conditions** | Any step requiring a value to be pasted into a document. Any suggestion of reusing a production value "to save time". A staging connection attempted **before** the custody question is closed. |

```text
A9 — FRESH STAGING SECRETS
I approve creating fresh staging-only values for: anon key, service-role key, database password, JWT signing secret,
PAIRING_HASH_PEPPER, CRON_SECRET, TURN — evidenced by name and digest only, and I accept that the DB password set at
creation has unconfirmed custody (R-39) and that re-setting it is an act of this approval. No production value is
copied, read or referenced; the production pepper is not rotated in Stage 2; no Firebase credential is created.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision — not signed by this document
```

### 3.7 A12 — Firebase / FCM work

| | |
| --- | --- |
| **Authorises** | Firebase **work beyond project creation**, if and only if the owner grants it here: app registration (Android/iOS/Web) in `haven-staging-46822`, download/handling of `google-services.json`, service-account JSON, and FCM configuration for push transport. |
| **Explicitly does NOT authorise** | **Project creation is not in this block** — it is already covered by the §2 ratification decision, and **nothing in A12 is implied by that decision**, nor is it implied by A9, A3 or A5. Firebase Auth, Firestore and Cloud Functions are **not approved requirements**: Supabase Auth remains the single identity authority and Firebase is FCM-transport-only by intent, and **FCM does not exist** in this programme. No billing change. No production credential crossing. Nothing in Stage 2's Supabase path. |
| **Preconditions** | Ratification §2 = (i) with the amended prohibition text; a recorded G2 decision; the owner's named identity boundary; explicit handling rules for any downloaded credential (it must not enter this repository). Under option (ii) this block is **inapplicable** — there is no project to register an app in. |
| **Evidence required** | App IDs (not secrets), file names and hashes of any downloaded config, the statement that no key value was read into a document, and the FCM test result or the recorded decision that FCM stays absent. |
| **Stop conditions** | Any wizard offering a paid plan. Any request to enable Analytics, Gemini or environment-type settings not separately approved. Any credential landing in the repository → stop, record, treat as leaked. |

```text
A12 — FIREBASE / FCM WORK (beyond project creation, which is covered by the §2 ratification decision)
I approve, in haven-staging-46822: app registration, google-services.json handling, service-account JSON handling and
FCM configuration — or I record that this stays deferred and unapproved. I acknowledge that Supabase Auth is the
identity authority, Firebase is FCM-transport-only, and Firebase Auth / Firestore / Cloud Functions are not approved
requirements. Nothing in this block is granted by §2, A2′, A3, A5 or A9.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________

owner decision — not signed by this document
```

---

## 4. Boundary table — what the executed creation does **not** imply

| Question | Answer | Where the line is held |
| --- | --- | --- |
| Does creation imply **schema load**? | **No.** Staging has 0 tables and no schema. | A3 (§3.4); 01 §7 "Creation approval is not schema-load approval"; S2-CREATE-01 §5 |
| Does creation imply **secrets**? | **No.** No secret exists; the DB password's custody is unconfirmed (R-39). | A9 (§3.6); the old package's item listing secrets inside A2 is withdrawn |
| Does creation imply the **sentinel or the settings checklist**? | **No.** `private.s2_environment` is NOT CREATED; SSL/connection logging/Realtime membership not set or captured. | A2′ (§3.3); S2-CREATE-01 §5 |
| Does creation imply **patch application**? | **No.** P01/P02/P03 unchanged, unapplied; D-01…D-12 all open. | A5 (§3.5) |
| Does creation imply **Firebase app registration or FCM**? | **No.** Zero apps, zero credentials, no FCM config — and **FCM does not exist**. | A12 (§3.7); S2-CREATE-01 §3, §4.4 |
| Does creation imply **Edge Functions**? | **No.** Staging has 0 Edge Functions; staging is SQL-only in text. | A7/A8, not in this package |
| Does anything here permit a **production change**? | **No — no approval in this package permits any production change.** A1 is production **read-only**; every other block is staging- or Firebase-scoped. | 04 §3 row A6; §6 below |
| What does production actually need? | **A6 plus the 7-item gate in 04 §4 — which does not exist yet.** Item 1 (staging parity) `BLOCKED — CANNOT START UNTIL A0, A1 AND A3 EXIST`; item 4 (rollback rehearsed) `BLOCKED`, rehearsal impossible on an empty schema; no rollback has been tested anywhere in this programme. | 04 §4 |
| Does ratification (§2 i) imply any of the above? | **No.** It accepts two empty shells and amends one prohibition sentence. | §2 |

---

## 5. Compensating controls — the honest score for the executed creation

The plan requires four controls for any executed change
([00](00-stage2-execution-plan.md) C9; [04](04-risks-rollback-approvals.md) §3 preamble). For the 2026-10-30 creation:

| # | Required control | Satisfied? | Observed state |
| --- | --- | --- | --- |
| 1 | Patch/artefact hash as provenance | **NO** | Nothing was hashed; the repository has **no commits**, so hashes are the only provenance and none was taken for these actions |
| 2 | Before/after snapshot | **NO** | Partial at best — staging had no prior state to snapshot; no post-creation platform record was captured (screenshots carry no UTC stamp; R-27's platform-audit-log half stands: Free includes no platform audit log) |
| 3 | Timed window | **NO** | **No start timestamp exists anywhere.** Local display `Oct 30, 5:25pm–6:25pm` only; no UTC conversion at capture; the auto-pause clock is nonetheless running from 2026-10-30 |
| 4 | Separate reviewer pass | **NO** | Absent — single-owner organisation (R-16), no second pass recorded |

**Zero of the four required controls were satisfied.** The record itself is honest; honesty is not the control the plan
requires.

**What the owner accepts if they ratify (§2 option i):**

- A platform write with **no provenance hash and no platform audit record**, reconstructable only from the accessibility
  excerpts in S2-CREATE-01.
- A change with **no timed window**: the only dated obligation is the dashboard touch **on or before 2026-11-06**, and
  its exact expiry is unknown because no UTC start was recorded (U-10).
- **Self-review as the sole control** going forward, explicitly labelled as such and never described as two-person
  control.
- A **one-off settings write the owner did not request** (Gemini off), accepted as least-privilege but recorded as an
  unrequested change.
- **No slot headroom and no cheap rebuild**: 2 active / 2 used / 0 remaining, no backups on either plan, so a failed
  staging action has no restore path and no spare target (R-38).

---

## 6. Unresolved items carried forward (U-01…U-16)

Statuses are re-marked against S2-CREATE-01 and S2-REVIEW-03. Definitions are unchanged from the superseded package §4;
that table is the authoritative wording and is not edited here.

| # | Open item | Blocks | Status after 2026-10-30 |
| --- | --- | --- | --- |
| U-01 | P01 pre-check 0.4 expects 1 row per function; query returns 2 (D-01) | A5 | **OPEN** — doc correction still unapproved |
| U-02 | P01 §1 commits before its post-check can be read (D-02) | A5 | **OPEN** |
| U-03 | P01 T3 cannot distinguish pre from post (D-03) | A5 evidence quality | **OPEN** — and invalid on an empty DB |
| U-04 | P02 has no in-file rollback; bodies must be captured from staging first (D-05) | A5 | **OPEN** — capture impossible before A3 |
| U-05 | P02 post-checks do not assert `prosrc` hash / overload count (D-06) | A5 | **OPEN** |
| U-06 | P02 ships its gate commented; applied ≠ hashed text (D-07) | A5 evidence integrity | **OPEN** — the shipped file **always aborts** |
| U-07 | P03 has no rollback (D-10) and its header omits both preconditions (D-11) | A5 | **OPEN** |
| U-08 | Staging name availability | A2 execution | **RESOLVED** — `parent-control-staging` created; ref `dzonzgngwxclhfnvxtvu` (S2-CREATE-01 §2.1) |
| U-09 | Region-picker availability | A2 execution | **RESOLVED** — `ap-northeast-2` reached via "Need a specific region?" and now read-only (§2.1/§2.6; R-33 closed) |
| U-10 | The 7-day active window has no named start date | A2′/A3/A5 scheduling | **OPEN — AND NOW MATERIAL.** The clock started at creation (2026-10-30); **no UTC start timestamp exists**, so no record states the exact expiry; a **dated dashboard touch on or before 2026-11-06** is required and is written in no operational plan. R-30 realised |
| U-11 | Reviewer pass in a single-owner organisation | A5, A6 | **OPEN** — and demonstrated by §5: control 4 was absent for the executed action |
| U-12 | Edge Function source: who exports it | step 6, G5-E | **OPEN / DEFERRED** — staging has 0 Edge Functions; nothing was exported |
| U-13 | `PAIRING_HASH_PEPPER` presence in production (presence only) | Nothing in Stage 2 | **OPEN** — answer by presence/name only (R-07); production secrets were not read |
| U-14 | P03 accepted only as staging-only with a 500 for a double request | E4 verdict | **OPEN** — P03 unapplied (R-20) |
| U-15 | Log-query headroom and rising | the whole stage | **OPEN** — observed **44.8/100 GB**; 80 GB stop line stands (R-15) |
| U-16 | Firebase ownership: three identities, no Haven project confirmed | G2/G7/A12 | **SUPERSEDED IN PART** — `haven-staging-46822` now exists under `shiwa2172000@gmail.com`; the **ownership decision for apps/FCM remains OPEN**, and every further Firebase action still needs A12 (§3.7) plus the §2 ratification |

**Slot arithmetic — resolved and corrected** (old package §1 rows, not U-numbered): Free allows **2 active projects**;
the old text read "1 used / the last slot". Observed today: **2 active / 2 used / 0 remaining** (S2-CREATE-01 §2.4;
R-09/R-31 realised, R-38). No `dev` or third project is possible on Free without deleting one, and **slot reuse after
deletion is UNPROVEN** while whether a PAUSED project counts toward the cap is `NOT VERIFIED`.

**Still not open, still true:** no paid upgrade was needed or taken; neither plan has backups or PITR; production is
untouched; **no finding has been remediated** — creation of a shell closes nothing.

---

## 7. If only some items are signed

| Signed | Result |
| --- | --- |
| **§2 only** | The creation is reconciled (or reversed). Nothing else can run: no capture, no sentinel, no load, no secret, no patch, no Firebase work. |
| **§2 + A0 + A1** | The production catalogue can be captured read-only and the artefact reconstructed and scanned offline. Staging still cannot be loaded (A3) and still has no sentinel (A2′). |
| **§2 + A0 + A1 + A2′ + A3** | Staging gains a schema and the sentinel; rollback rehearsal becomes possible; **still no patch** (A5 blocked by D-01…D-12) **and no secret** (A9). |
| **A5 without A2′** | Every patch self-aborts — the sentinel is its own guard and it does not exist. |
| **A9 alone** | Secrets in an empty shell; no connection proves anything, and the R-39 custody question stays unanswered. |
| **A12 without §2 (i)** | Incoherent: under option (ii) there is no project to register apps in. |
| **A1, but treating it as A3** | The most dangerous misreading available. A1 is production SELECT against catalogues only; it authorises no write, anywhere. |

---

## 8. Reading list before any signature

[S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2, §3, §4, §5 (what happened and what it does not claim) ·
[S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §B, §C (authority matrix, C.1, C.3), §H, §J ·
[04](04-risks-rollback-approvals.md) §2.4, §2.5, §3, §3.1, §4 (R-30, R-36, R-37, R-38, R-39) ·
[01](01-staging-project-proposal.md) §6, §7 · [patch defects](patch-defects-before-a5.md) D-01…D-12 ·
[approval-package-a0-a2.md](approval-package-a0-a2.md) as the **superseded historical request** (do not sign it).

---

## 9. No operational action by this document

This document authorises nothing by existing. **No dashboard was opened, no URL was visited, no SQL was run, no patch
was applied, no setting was changed, no secret was read or created, no project was created, paused, resumed or deleted,
no CLI or REST call was made, and no credential was exported in the making of it.** It restates an executed action
awaiting retrospective ratification and lists forward approvals the owner has not granted. Nothing in it is signed,
initialled or dated on the owner's behalf, and no silence, button state or past instruction is treated as approval
(R-29). The next action is the owner's alone: §2, then any of §3 that they choose to grant.
