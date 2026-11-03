# S2-REVIEW-03 — Independent full Stage 2 consistency and readiness audit

**Record ID:** S2-REVIEW-03
**Date:** 2026-11-02
**Class:** DOCUMENTATION AND LOCAL-FILE AUDIT ONLY. No dashboard was opened, no SQL was executed, no patch was applied,
no setting was changed, no secret was read, no project was created, paused, resumed or deleted, no CLI or REST call was
made, no file under audit was edited.
**Method:** seven read-only auditors with disjoint domains (creation evidence, approval boundaries, plan-of-record
consistency, supporting docs + evidence + changelog, patch safety, readiness + risk, service topology), followed by the
author's own re-read of every load-bearing citation. Findings marked **✓** were re-verified line-by-line by the author.
**Inputs:** all of §2 of the brief — 00–06, README, approval package, patch-defects paper, CHANGELOG, S2-REVIEW-02,
all four evidence files, all ten working papers, all three patch files (read, not modified), plus Stage 1
`00/01/02/04/06/07/13/14/16` and the Stage 1 evidence JSON used as the authoritative baseline.
**Idempotency check:** all three patch files hash-match the values recorded in
[S2-REVIEW-02](S2-REVIEW-02-independent-audit.md) §7 — `1edad404…97be51` (P01), `01403cd7…b88c67` (P02),
`8f92cc0f…d60ecd4` (P03). Nothing changed since the last audit. The repository still has **no commits**, so hashes, not
history, remain the only provenance.

**Identifier namespaces used here** (deliberately non-colliding with `D-01…D-12` patch defects, `R-01…R-35` risks,
`U-01…U-16` unresolved items, `J-01…J-23` red-team dispositions (corrected in the S2-EXEC-03 pass — this line read
`J-01…J-22` while [06](06-redteam-resolution.md) `:39` already defines J-23 and
[parts/J](parts/J-redteam.md)'s addendum now records it), `C-01…C-06` / `W-01…W-12` from REVIEW-02):
`A-` creation evidence · `B-` approval boundaries · `CD-` document consistency · `RD-` readiness · `PE-` patch
execution safety · `RK-` risk · `NX-` next sequence · `FX-` correction backlog.

---

## A. Executive summary

**Overall Stage 2 status: `SCAFFOLD CREATED — PLAN OF RECORD FALSIFIED — REMEDIATION NOT STARTED`.**

Two empty staging projects exist and are correctly described in exactly two documents:
[README.md](README.md):3-9 and [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md). **Every other Stage 2 document —
including the entire plan of record and the signable approval package — still asserts that no staging project exists.**
That is not a cosmetic staleness problem: [approval-package-a0-a2.md](approval-package-a0-a2.md):27 states
`Staging project created | **No**` ✓ and its signature block is written as a forward authorisation for an action that
has already happened, so an owner signing it today would be certifying a false premise.

**Actually complete:** project creation only — Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu`
(ap-northeast-2, Free/NANO, 0 tables, no migrations, 0 Edge Functions) and Firebase `haven-staging` /
`haven-staging-46822` (Spark, Analytics off, Gemini off, no apps, no credentials). Production is genuinely untouched.

**Incomplete:** everything from G3 onward. A0 has never been approved by anyone; A2 was never signed; A3, A5, A9, A11,
A12, A13 do not exist as decisions; no catalogue was captured; no artefact was reconstructed; no secret scan occurred;
no sentinel exists; all twelve patch defects are still open in the file text.

**Most important blockers, in order:**

1. **B-01 — the Firebase creation breached an explicit prohibition.** [04](04-risks-rollback-approvals.md):157 (A12)
   forbids "**Any Firebase action in Stage 2**" ✓ and [00](00-stage2-execution-plan.md):179 repeats it; a Firebase
   project was nevertheless created on 2026-10-30. The action was owner-instructed, so it is not unauthorised in
   substance, but **no approval row covers it** and it needs retrospective ratification, not silence.
2. **CD-01 — the plan of record's status lines are false** ([00](00-stage2-execution-plan.md):3-5 ✓,
   [01](01-staging-project-proposal.md):3-5, [04](04-risks-rollback-approvals.md):3-4 ✓ "the only browser use was
   read-only inspection").
3. **RD-02 — staging is not ready for G3.** 1 of 17 prerequisites is VERIFIED; the six G3-path gates are all unsigned,
   uncaptured or not applied. "The project exists" is not "the project is configured".
4. **RK-02 — the auto-pause clock is running with no owner and no date.** Creation was 2026-10-30; Free pauses after 7
   days idle; **no document records a start timestamp or an expiry date** (U-10 still open). The nearest real deadline
   is **on or before 2026-11-06**, and it is not written down anywhere.
5. **PE-01 — no patch is safe to apply today**, independent of the documentation: each aborts at its own sentinel on an
   empty database, and P01's §0 pre-checks hard-cast functions that do not exist there yet.

**Owner's architecture question — answered in §G. The premise is false on its first half.** Authentication is **not**
on Firebase; Supabase Auth is the sole identity authority, and Firebase is currently used for nothing at all — not even
push. Edge Functions and the database **are** on Supabase, as the premise assumed.

---

## B. Project creation verification

### B.1 Supabase staging

| Attribute | Required (plan) | Observed (S2-CREATE-01) | Status |
| --- | --- | --- | --- |
| Name | `parent-control-staging` | `parent-control-staging` | `VERIFIED` |
| Project ref | — | `dzonzgngwxclhfnvxtvu` | `VERIFIED` |
| Region | `ap-northeast-2` | `ap-northeast-2` — Northeast Asia (Seoul), read-only field | `VERIFIED` |
| Plan / compute | Free / NANO | Free / NANO | `VERIFIED` |
| Organisation | `symqztrmaziuwdibcfrq` | same, owner `spg7753@gmail.com`, 1 member | `VERIFIED` |
| Empty shell | — | 0 tables, no migrations, no branches, 0 Edge Functions, no repository | `VERIFIED` |
| Auto-expose new tables | off | unchecked at submit (re-set after a re-render) | `VERIFIED` |
| Sentinel `private.s2_environment` | G6-b object | **not created** | `NOT CREATED` (correct for "shell only") |
| Schema loaded | A3, later | **none** | `NOT DONE` |
| Secrets / keys recorded | A9, later | **none created by the agent** | `NOT CREATED` |
| DB password custody | owner-only | owner-side; no value in repo, transcript or logs | `NOT VERIFIED` — owner to confirm |
| Slot headroom | "last of 2" | **2 of 2 used, 0 remaining** | `VERIFIED` — R-09/R-31 realised |
| Postgres / Auth / PostgREST | — | `17.11.0.003` / `2.197.0` / `14.18` | `VERIFIED` (new fact, recorded nowhere else) |
| Production untouched | required | no production page opened beyond the org list | `VERIFIED` |

### B.2 Firebase staging

| Attribute | Required | Observed | Status |
| --- | --- | --- | --- |
| Display name | `haven-staging` | `haven-staging` | `VERIFIED` |
| Project ID | generated | `haven-staging-46822` (exact stem was globally taken) | `VERIFIED` |
| Project number | — | `381273275501` | `VERIFIED` |
| Plan | no paid tier | Spark / No-cost | `VERIFIED` |
| Analytics | **off** | off; `Create project` button state confirmed the choice registered | `VERIFIED` |
| Gemini assistance | not specified | **off** — default was on; switched off as the least-privilege option and disclosed | `VERIFIED`, deviation disclosed |
| Environment type | not specified | left `Unspecified` (`Staging` was available) | `VERIFIED` — deliberately not changed |
| Apps registered | none | "There are no apps in your project" | `VERIFIED` |
| Credentials / service accounts | none | none created, none copied | `VERIFIED` |
| Account | not switched | `shiwa2172000@gmail.com` | `VERIFIED` |
| Pre-existing project | untouched | `flutter-flow-w-ith-f-ir-6592ib` not opened or modified | `VERIFIED` |

### B.3 Bucket tests the brief demanded

| Bucket | Result |
| --- | --- |
| Documents still saying `PROPOSED — NOT CREATED` / "no project exists" | **found in 00, 01, 04, 05, approval package, CHANGELOG, S2-REVIEW-02, parts/A, parts/B, parts/G, parts/I, root README, stage1 README, INSP-01, INSP-02, NEXT-01** — see §D |
| Claim that a sentinel exists | **none found** — every mention is a future G6-b object |
| Claim that the schema was loaded | **none found** |
| Claim that secrets or credentials exist | **none found** |
| Claim that Firebase app registration is complete | **none found** |
| Claim that SQL or patches were executed | **none found** |
| Incorrect claim that production was modified | **none found** |
| **Net** | the failure mode is uniformly **stale non-existence**, not invented completion — but it is present in the one signable document |

### B.4 Screenshot evidence — status change

The owner supplied two captures of the in-app browser this session: the Firebase `haven-staging` overview and the
Supabase `parent-control-staging` home page (STATUS Healthy, COMPUTE SIZE NANO, No repository connected, No branches,
No migrations, No backups). These **do** prove a human-visible capture of both consoles exists, and the Supabase one
corroborates five fields of S2-CREATE-01 §2.2. They **do not** prove project IDs/refs, region, plan, Analytics-off,
Gemini-off, the 2-of-2 slot header, the usage meters, 0 tables, or any read-only window; they carry no UTC stamp and the
Firebase URL is truncated so no project ID is visible. Consequence: the absolute sentences "no image of either console
exists" ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md):13-16) and "Screenshot evidence remains `NOT VERIFIED`"
([CHANGELOG](CHANGELOG.md):9-10) are now **false as written** and must be qualified — while R-27's platform-audit-log
half stands unchanged, because a screen capture is not a platform record.

---

## C. Approval audit — A0–A13 authority matrix

| ID | Authorises (per documents) | Documented status | Actual status after 2026-10-30 | Gap |
| --- | --- | --- | --- | --- |
| A0 | G3 method amendment (04:146; pkg §2.2) | `AWAITING OWNER SIGNATURE` | **never approved by anyone** | 00:3, 01:3, 04:3, pkg:3-4, pkg:27 all assert a pre-creation world ✓ |
| A1 | Read-only introspection (04:147) | self-asserted for the inspections | unchanged | no written A1 record, only a claim |
| A2 | Create staging project (04:148; pkg §3.2) | unsigned (pkg:123) | **action performed**, scope ≠ A2 | sentinel (pkg:100), settings checklist (:101-102), fresh secrets (:103) deliberately not done |
| A3 | G3 capture + schema load (04:149) | not granted | not granted | 00:71 gates the load under A0+A2 while 00:101/01:174/pkg:91 gate it under A3 — unresolved REVIEW-02 C-02 |
| **A4** | **does not exist in the plan of record** (04 §3 jumps 148→150) | README:19 and 00:206 advertise "A0–A13" | — | parts/I:86 and parts/B:181 use A4; parts/B:177-184 reuses A0–A7 with **different meanings** — a live namespace collision |
| A5 | Apply P01/P02/P03 to staging (04:150) | not granted | not granted | D-01…D-12 all open; T3 invalid on an empty DB |
| A6 | Any production apply (04:151) | not granted | not granted | none |
| A7 / A8 | Edge export / deploy (04:152-153) | not granted | not granted | staging has 0 functions |
| A9 | Set or rotate any secret (04:154) | not granted | **arguably engaged**: a DB password was set during creation | S2-CREATE-01:99 then *recommends* re-setting it — an action requiring an approval that does not exist |
| A10 | Roll back any patch (04:155) | not granted | n/a | rollback is not rehearseable before a schema load |
| A11 | Test fixtures (04:156) | not granted | not granted | none |
| A12 | Firebase / FCM — "Owner, **outside Stage 2**", forbidden "any Firebase action in Stage 2" (04:157 ✓) | not granted | **breached**: `haven-staging-46822` created inside Stage 2, plus Gemini switched off | no approval row covers what was done; README:58 still says "no Firebase action" ✓ |
| A13 | Client release (04:158) | not granted | not granted | none |

### C.1 The eight required answers

1. **Authorised:** three scoped chat answers — Supabase "shell only" (no sentinel, no settings checklist, no secrets),
   "you type the password yourself", "create `haven-staging`, Analytics off" — under the standing instruction not to use
   the current projects or `parent-control-prod`. Nothing else.
2. **Executed:** two empty projects; auto-expose left off; Analytics off; **Gemini off** (an unrequested choice,
   disclosed in the record); environment type untouched; no app, no credential, no schema, no secret, no SQL.
3. **Not authorised:** schema load, sentinel, settings checklist, any secret, any patch, any fixture, Edge export or
   deploy, Firebase app registration or FCM, anything in production, project deletion or re-creation.
4. **Still needs separate approval:** G3 capture (A0 + A1), load (A3), P01–P03 (A5), any secret including a password
   re-set (A9), Firebase apps (A12), production (A6 + the 7-item gate).
5. **Creation ⇒ schema load? No.** pkg:91 "(that is A3)", 01:174 "Creation approval is **not** schema-load approval",
   S2-CREATE-01:169 all hold the line. **One document implies otherwise: 00:71.**
6. **Creation ⇒ secret creation? No.** 04:154, pkg:107-108/121. **Flag:** pkg:103 lists "creating fresh staging
   secrets" *inside* A2 while §3.3 disclaims A9 — the REVIEW-02 C-01 contradiction is still in the file.
7. **Creation ⇒ Firebase app/FCM? No.** S2-CREATE-01:143-144 "Zero Firebase credentials were created"; 04:157.
8. **Production changes? None.** 00:28, 04:151/160-163, README:76-77.

### C.2 Is the chat instruction misrepresented as a signed approval?

No document claims a signed A0/A2, and README:48 is explicit that "the packaged A2 signature was never signed, so the
signed record and the executed action differ" — that is the correct framing. The real misrepresentation is the opposite
direction: **stale negative claims** (pkg:3-4, pkg:27 ✓, pkg:28, 00:3 ✓, 01:3, 04:3 ✓, NEXT-01:107). One near-miss:
S2-CREATE-01:9-11 disclaims A3/A5/A9/A12 but **omits A0 and A2**, which is the closest the record comes to treating the
chat instruction as A2-equivalent. The pkg signature block (pkg:116-123, blank at :123) is now **unusable as written**:
signing it today would either ratify the A12 breach silently, authorise a second creation, or certify four G6 sub-actions
that were deliberately not performed.

### C.3 Single-owner compensating controls — score

The plan demands patch hash, before/after snapshot, timed window, separate reviewer pass (00:35 C9, 04:140-142). For the
creation: pre/post snapshot **partial** (staging had no prior state); slot check **met**; cost/ref **met**; timed window
**not met** (no start date anywhere, and the record states "no UTC conversion recorded"); reviewer pass **absent**;
patch hash **absent by design**. **Zero of four C9 controls are fully satisfied.** The record is honest; it is not the
control the plan requires.

---

## D. Document consistency matrix

| ID | File:line | Existing claim | Conflicting evidence | Severity | Recommended correction |
| --- | --- | --- | --- | --- | --- |
| CD-01 | 00:3-5 ✓; 01:3-5 | "`PROPOSED — NOT STARTED`… No staging project exists" | README:3-9; S2-CREATE-01 §2, §3 | **HIGH** | `G6-a EXECUTED (shell only) — G6-b/c/d NOT DONE`; keep "no SQL run, production untouched" |
| CD-02 | 04:3-4 ✓ | "the only browser use was read-only inspection on 2026-10-30" | creation is a browser **write**; two wizard settings moved off default | **HIGH** | Disclose the creation writes and the two deviations; add S2-CREATE-01 to the evidence list |
| CD-03 | 00:179; 02:69; 04:157 ✓, 238, 250; README:58 ✓ | "No Firebase action of any kind occurs in Stage 2"; "no Firebase action" | `haven-staging-46822` created inside Stage 2 | **HIGH** | "Firebase limited to project creation only; no app, credential, FCM or config change" |
| CD-04 | pkg:27 ✓ | "Staging project created \| **No**" | both projects exist | **HIGH** | Retitle as a pre-creation request + add a retrospective ratification record and a forward A2′ |
| CD-05 | 02:41 ✓ | E14 current status `PARTIAL` | 02:3 "No finding below has been remediated"; P02 `PROPOSED — NOT APPLIED` | **HIGH** | Current → `PROPOSED — NOT APPLIED`; keep `PARTIAL` only as the prediction |
| CD-06 | 00:230; 01:19, 116, 123, 126, 131, 179; 04:33, 55; 06:35; pkg:22, 25 ✓, 151; CHANGELOG:17 | "2 active, **1 used**"; egress 0.12/5 GB; log ingestion 0.17/1 GB; "one slot remains" | observed 2 of 2 used; egress **0.14**; log ingestion **0.20** | **HIGH** | `2 active, 2 used, 0 remaining`; refresh the two usage rows (log query 44.8/100 and DB 32/500 are correct) |
| CD-07 | 00:71 vs 00:101-102, 00:120-122, 00:220 | step 1 delivers "G6-c schema load; G6-d verification" | same artefact applied and verified twice; G6-c consumes the G3-b artefact produced one step later | **HIGH** | step 1 = "shell + sentinel"; step 2 = "load + verify"; remove the backwards dependency |
| CD-08 | 00:71 ✓-adjacent vs 04:149, 01:174 | schema load gated "A0 and A2" | A3 gates the load | MEDIUM | add A3 to step 1 or move the load to step 2 (REVIEW-02 C-02, still open) |
| CD-09 | pkg:103 vs pkg:107 | A2 authorises "creating fresh staging secrets" | §3.3 disclaims A9 | MEDIUM | delete the item from A2; secrets are A9 only (REVIEW-02 C-01, still open) |
| CD-10 | 00:99 | creation gated "A0 + A2" | 01:196-198 permits creation without A0 | MEDIUM | gate creation on A2 alone |
| CD-11 | 05:181 ✓ | patch-specific SQL cases "**21**" | 5 (P01 T1–T4,T6) + 9 (P02 T0–T8) + 6 (P03 C1,C3–C6,C9) = **20** | MEDIUM | print 20 |
| CD-12 | 05:187 ✓ | "SQL-runnable set is **39** cases" | 20 + 19 − 1 duplicate (`TE-02`) = **38** | MEDIUM | print 38 |
| CD-13 | 05:105 vs 05:7, 18 | "104 HTTP cases (`TE-01…TE-20`, `PE-*`, `CI-01…CI-07`)" | that enumeration is 20+78+7 = **105**; elsewhere TE is 19 | MEDIUM | "TE-01…TE-20 excluding TE-02 (19) + 78 PE + 7 CI = 104" |
| CD-14 | 05:18 vs 05:183 | G5-E total 104 | 4 patch-specific HTTP cases listed "with the rest of G5-E" → 108 unless counted inside | MEDIUM | state 104 or 108 and de-duplicate explicitly |
| CD-15 | 00:206; README:23 | "approvals A0–A13" | no A4 exists in 04 §3 | LOW | "A0–A3, A5–A13 (A4 retired: CLI-only, excluded by C1)" |
| CD-16 | 00:51-54 | "E6, E7 and nine other findings … (see 02 Tier 3)" | 02 uses tiers A–E, no "Tier 3"; tier C = E6,E7,E8,E9,E10,E12 = 4 others | MEDIUM | cite "Tier C", count 4 |
| CD-17 | 00:75 | P03 gated by A5 | its own precondition is a read-only production duplicate count = A1, listed nowhere | MEDIUM | add A1 to step 5 |
| CD-18 | 02:38 | E11 is "the **only** finding blocked on a missing capture" | E14 is partially blocked on the same class (06:62-63) | LOW | "only finding blocked *wholly* on a missing capture" |
| CD-19 | 00:34 (C8) | order "E3/F7/E1" | 00:74 step 4 = "E3/F7/E1/F5" | LOW | add F5 |
| CD-20 | CHANGELOG:43 ✓ (#11) | "P01 pre-check 0.4 expects 2 rows per function, not 1" recorded as applied | 03:135 ✓ still reads "one row per function" | **HIGH** | re-word to "recorded as D-01; 03:135 not yet corrected" |
| CD-21 | CHANGELOG:6-10 ✓ | last entry S2-DOC-01, "no project created… no Firebase action"; no entry for the creation | S2-CREATE-01 (later the same day) | **HIGH** | add an S2-OPS-01 entry for the creation, the README rewrite and this audit |
| CD-22 | CHANGELOG:56 | root README's "Stage 2 pointer is unchanged" | root README contains no Stage 2 pointer | MEDIUM | delete or verify |
| CD-23 | patch-defects:108 ✓ | rollback text "exists **nowhere in the repository**" | bodies captured at `docs/stage1/evidence/g1-b3b-20261029.json:149, 155, 159, 165`; `functions-and-triggers.md:18`; parts/D:182-183 itself cites g1-b3b | **HIGH** | "absent from the patch file; present as Stage 1 `prosrc` captures" |
| CD-24 | patch-defects:109-110 | "04 §2.2 and J-04 both require the rollback text inside the patch file" | 04:87 prescribes capture-based reversal; the in-file rule is J-04 only | MEDIUM | drop the 04 §2.2 attribution |
| CD-25 | patch-defects:22-26, 232-233; CHANGELOG:48 | "P01 S3=1, P03 S3=3"; "four `PATCH REVISION REQUIRED` items" | S3 items are D-01, D-02, D-05, D-06, D-07, D-09, D-10 = 7; D-04 is S2 | MEDIUM | recompute both columns |
| CD-26 | S2-CREATE-01:13-16 | "No image of either console exists" | owner-supplied app-window captures (§B.4) | **HIGH** | qualify as "none at capture time; owner captures exist, not platform records" |
| CD-27 | S2-CREATE-01:9-11 | disclaims A3/A5/A9/A12 | omits A0 and A2 — the two that actually differ | MEDIUM | add "not a signed A0 or A2" |
| CD-28 | S2-CREATE-01:13-16 vs :136-138 | "no settings change beyond the wizard's own defaults" | same file calls Gemini-off "an unrequested setting change" | MEDIUM | reclassify as "create + two wizard settings off-default"; add UTC start/end |
| CD-29 | S2-INSP-02:18-23, 31 | Firebase "1 – 1 of 1"; a Haven Firebase project "does **not** exist" | `haven-staging-46822` now exists | MEDIUM | dated supersession addendum (as INSP-01 received) |
| CD-30 | S2-NEXT-01:51, 116, 229-230, 238-240 | "one slot remains"; "creation not attempted"; "A0 **and** A2 before creation" | both created with A0/A2 unsigned | MEDIUM | addendum: superseded on execution; the unsigned-A2 deviation is itself a finding |
| CD-31 | S2-REVIEW-02:6, 73, 428 | "no project exists"; "no screenshots" | CD-01…CD-04, CD-26 | MEDIUM | stamp the audit "as at 2026-10-30, pre-creation" and re-run §2/§6 |
| CD-32 | S2-REVIEW-02:173, 207, 251 | miscites: 01:145 for F4 (F4 is 01:46); 00:137 for a `PROPOSED — NOT APPLIED` label that is not there; "47 lines above" (49→95 = 46) | direct reads | LOW | re-cite; an audit that miscites weakens its own findings |
| CD-33 | S2-REVIEW-02:184-194 vs :385 (W-01) | "G3-a/G3-b should run before G6-a" | 00:80-84 records the owner's stated order and calls staging-first "the only executable one" | MEDIUM | escalate as an owner decision — an audit may not silently reverse a recorded order |
| CD-34 | parts/A:3, 39, 128-131; parts/B:32, 199; parts/G:4, 17; parts/I:10-11, 25 | "no project exists"; F4 validatable in staging; a platform backup restorable; G5-S "Runnable" | creation; R-34; R-35; staging empty | MEDIUM | per-file `SUBORDINATE / SUPERSEDED` banner — only README:39 and CHANGELOG:54 assert subordination today |
| CD-35 | parts/A:12 | candidate names include `haven-staging` | that stem is now the **Firebase** display name; Supabase uses `parent-control-staging` | LOW | mark alternatives rejected; record the cross-platform stem collision |
| CD-36 | parts/B:177-184 | uses "A2" = read-only production SQL, "A3" = staging DDL | 04 §3 assigns those letters differently | MEDIUM | rename working-paper approvals `WP-A2′` etc. or delete the local numbering |
| CD-37 | parts/J:69 | cites "P03 line 108", "lines 21-34" | same hash, content now at :123 and :19-49 | LOW | re-cite against the hashed file |

**Verified correct — do not touch:** 02:96-97 coverage arithmetic `6+1+4+6+5+1 = 23`, every E/F/X id present exactly once;
04 §1 register has exactly 35 unique rows R-01…R-35 and every cross-reference resolves; 05:7 (20+78+7=105), 05:18,
05:182-183 sums; all project refs, names, region, plan and compute values across README and S2-CREATE-01; production
`hhqgreaoqulmfwfwarhc` everywhere it appears; the three patch headers and 03's "PROPOSED — NOT APPLIED"; E3/F7, E4,
E6/E7 status lines are consistent across 00 §5, 02 §2-3, 04 §4 and README; README:31 "16 unresolved items" matches
U-01…U-16; usage figures agree across INSP-01, NEXT-01 and CREATE-01 (0.20 / 0.14 / 44.8 / 32 / 10 / 0); no incorrect
calendar date in any reviewed file; **no document claims a sentinel, a schema load, secrets, app registration, patch
execution or a production change**.

### Citation corrections (2026-11-02)

Four citation defects in the §D rows above, found while applying CD-32 / FX-14 and recorded here **without editing the
original rows**:

1. `01:145` was cited for F4, where F4 is at `01:46`.
2. `00:137` was cited for a `PROPOSED — NOT APPLIED` label that is not on that line.
3. The README line references were made before README was rewritten on 2026-11-02 and are no longer stable.
4. "47 lines above" should read 46.

All four are historical positions: 00, 01 and README were rewritten during the S2-DOC-02 pass, so neither the cited line
nor the corrected line number above is a current reference.

---

## E. Patch readiness matrix

**No patch is safe to apply today, and the reason is structural, not documentary:** on the empty staging database each
one aborts at its own sentinel (P01 `sql:105-107`, P02 `:17-19`, P03 `:24-26` — `to_regclass` returns NULL without
erroring, so the guard does function), and P01's §0 pre-checks hard-cast functions that do not exist there
(`sql:40-41, 51-52, 61-62, 70, 79`).

| Patch | Defect | File:line | What the file actually shows | Status | Sev |
| --- | --- | --- | --- | --- | --- |
| P01 | D-01 | 03:135 ✓ / sql:55, 60 | paper still says "one row per function"; `acldefault('f',owner)` yields owner + PUBLIC = **2 rows/function, 4 total** | **OPEN** | S1 |
| P01 | D-02 | sql:158-172 ✓ | `commit;` is unconditional at :170; the instruction is still "run rollback instead of commit", which requires editing the hashed text. §0 (:29-89) sits outside `begin;` (:97) but is read-only; **no DDL runs outside the transaction** | **OPEN** | S1 |
| P01 | D-03 | 03:167, 221 / sql:46 | T3 relabel not applied; 03:113 already says anon is blocked by schema USAGE, so pre/post are identical — and on staging `set local role anon` needs a role that does not exist | **OPEN** | S1 |
| P01 | D-04 | 03:197-198 | file-vs-doc §2 ambiguity unchanged | **OPEN** | S3 low |
| P01 | rollback names | sql:184-190 | correct objects; the `GRANT … to service_role` at :142 is intentionally not reversed, and the ACL non-identity is acknowledged (04:77) | **OK** | — |
| P02 | D-05 | sql:155 | no in-file rollback (file ends at `commit;`) — **but the reason given in patch-defects:108 is false**: bodies are captured verbatim at g1-b3b `:149, 155, 159, 165` (prosrc only, no `pg_get_functiondef` header) | **OPEN / reason CLAIM FALSE** | S1 |
| P02 | D-06 | sql:149-154 | no `md5(prosrc)`, no overload count, no `RAISE` on mismatch; no prosrc hash exists anywhere to compare against | **OPEN** | S1 |
| P02 | D-07 | sql:27-37 | the gate ships commented (`:28`) while the block at `:31` requires it → **the file always aborts as shipped**, so executed text ≠ hashed text | **OPEN** | S1 |
| P02 | D-08 | parts/D:110-115 | the capture list omits `request_remote_session`, whose search_path §4 alters (sql:144) | **OPEN** | S1 |
| P02 | D-09 | sql:20 | `limit 1` un-ordered, no count assertion (same in P01:108, P03:27) | **OPEN** | S2 |
| P02 | new | sql:39-40 | header calls the bodies "INFERRED … Q7 does not cover the private schema" — understates the evidence actually captured | **NEW** | S2 |
| P02 | new | sql:44, 69, 111, 144 | signatures **are** pinned (uuid,uuid / uuid,uuid,uuid / uuid,uuid,text) and `SECURITY DEFINER` + search_path match the inventory exactly; overloads are not detected by §5 | **OK + gap** | S2 |
| P03 | D-10 | sql:127 | no in-file rollback; the prose rollback names the right objects (parts/E:193-196, 04:97-101) | **OPEN** | S1 |
| P03 | D-11 | sql:6-9 | 3 preconditions only — **no P02 prerequisite** and no production duplicate count | **OPEN** | S1 |
| P03 | D-12 | sql:6-9 vs :82-83 | guard compatibility is asserted only inline; the captured body (g1-b3b:113) **proves** `requested→expired` is allowed, so the conflict is harmless | **OPEN (harmless)** | S2 |
| P03 | new | sql:122-125 | `create unique index if not exists` is name-only: a same-named different index silently no-ops **and commits**; there is no post-check at all | **NEW** | S1 |
| P03 | new | sql:52-56 | "service_role bypasses RLS" is not evidenced — `rolbypassrls:false` at g1-b3b:34 is **authenticator**, not service_role | **NEW** | S2 |
| all | cross | — | no secret, pepper, token or credential literal in any file (only column names `secret_hash`/`code_hash`); no write to `auth`, only `auth.uid()` reads; no production-only object touched; P01 §0 is a legal A1 probe; ordering P01→P02→P03 is respected in 00:73-75 | **OK** | — |

**Every one of D-01…D-12 is still OPEN.** REVIEW-02's C-items are likewise all still open, which is the expected result
because no edits were authorised in either pass.

---

## F. Risk matrix

| Risk | Documented | Severity still matches reality | Control-violating recommendation found |
| --- | --- | --- | --- |
| Last Free slot | R-09, R-31 (04:33, 55) | **No** — was "would use the last slot", now realised and irreversible | 04:117-118 recommends delete→re-create on an **INFERRED** slot reuse, violating R-25 (04:49) |
| 7-day auto-pause | R-30 (04:54) | **No** — now certain; the clock started 2026-10-30 | 04:128 permits an un-approved console state change, in tension with R-29 |
| No backup / PITR | R-35 (04:59) | yes | none |
| Log query vs stop line | R-15 (04:39) | yes (44.8/100 GB) | 01:123-127 prints stale 0.17/0.12 |
| Firebase Spark limits | **not documented as an R-id** | n/a | the creation itself |
| Missing Firebase app registration | recorded only as absence | n/a | README:58 ✓ "no Firebase action" contradicts README:5-6 and A12 (04:157 ✓) |
| Missing Edge source | R-03 (04:27) | yes (staging has 0 functions) | none |
| Missing secrets | 01:186, A9 | yes | S2-CREATE-01:99 recommends a password re-set under an **unsigned A9** |
| Single-owner control | R-16 (04:40) | **No** — aggravated: execution preceded every signature | none |
| Screenshots unavailable | R-22, R-27 | **partly superseded** — owner captures now exist (§B.4) | none |
| Platform audit logs unavailable | R-27 (04:51) | **worse** — the unsigned creation cannot be tied to any independent record | none |
| Viewport instability | R-22 (04:46) | yes; should rise — creation only succeeded on retry | none |

**Obsolete after creation:** R-32 and R-33 (name and region now VERIFIED), U-08/U-09, D-12's "2 active, 1 used".

**New risks the register does not carry:**

- **R-36** — a Firebase project was created although A12 and 00:179 forbid any Firebase action in Stage 2. Certain / M.
  Unblock: retrospective owner authorisation + the README:58 and 02:69 corrections.
- **R-37** — A0/A2 were never signed yet A2's action executed under verbal instruction; approvals can now only
  **ratify**, not authorise. Certain / H. Violates R-29.
- **R-38** — zero slot headroom: R-17's delete/re-create branch and any second staging are impossible without
  destroying the only target, and slot reuse is unproven. Certain / H.
- **R-39** — a staging DB password exists with unmanaged custody; any copy outside the browser is unrecoverable and
  un-auditable. NOT VERIFIED / H.
- **R-40** — the auto-pause deadline is running with no recorded start/expiry timestamp and nobody watching the status
  banner. Likely / M-H.
- **R-41** — the plan of record's status lines contradict ground truth, so a reader may attempt actions believed
  prohibited, or skip actions still required. Certain / M.

**Cost/entitlement:** no new cost or entitlement is computed here. The only observed deltas are the meter values in
CD-06; staging's own footprint remains unmeasured and the "under 50 MB" figure is still `INFERRED`.

---

## G. Service topology — the owner's question, answered

**The premise "all authentication uses Firebase" is FALSE. The premise "functions and database use Supabase" is TRUE.**

| # | Claim | Evidence | Status |
| --- | --- | --- | --- |
| 1 | All auth runs on Firebase | stage1 `02-architecture.md:18` (Supabase Auth is the single identity authority, "Firebase Auth stays disabled"); `01-baseline-inventory.md:75-82` (email-only, all OAuth off); `firebase/SETUP-CHECKLIST.md:16` (D4 "Leave disabled") | **CONTRADICTED** |
| 1b | Tokens the DB and Edge layer trust are Supabase-issued | `02-architecture.md:69` (all 9 handlers call `db.auth.getUser(token)`); g1-b3b `:16-18` (`anon`/`authenticated`/`service_role`); `00-status-register.md:124` (policies anchor on `auth.uid()`) | **VERIFIED** (documentary) |
| 1c | Firebase SDK inside the shipped APKs | Android source not in repo; only activities, not SDKs, were inventoried | **NOT VERIFIED** |
| 2 | Firebase provides push (FCM) | `02-architecture.md:24, 174` (FCM "DOES NOT EXIST"); `SETUP-CHECKLIST.md:100` (no function sends FCM); staging Firebase project has **0 apps** | **CONTRADICTED — Firebase is currently used for nothing** |
| 2b | Other Firebase products | Analytics off at creation; Firestore / Realtime DB / Hosting / Crashlytics / Remote Config — no mention anywhere; `.env.example:13-14` reserves placeholders only | **ABSENT / NOT VERIFIED** |
| 3 | Edge Functions on Supabase | `13-edge-function-source-inventory.md:54-64` (9 functions); `:20` no `supabase/functions/` in repo — dashboard-only, 7 of 9 minified; `supabase/config.toml:374-375` | **VERIFIED**; source not in the repository |
| 3b | Cloud Functions on Firebase | no mention in any Stage 1/2 document; `02-architecture.md:28` "the Edge Functions are the API" | **ABSENT** |
| 4 | Database on Supabase | Postgres 17, `public`/`private`/`extensions`, 19 tables; Data API exposes `public`+`extensions` with 0/19 tables REST-exposed (g1-b3b `:20-29`) | **VERIFIED**; no Firestore/RDBT evidenced |
| 5 | Split-brain risk | R-23 (04:47) "two consoles, two identities": Supabase `spg7753@gmail.com` vs Firebase `shiwa2172000@gmail.com` vs the retired CLI account `om-event*` (`SETUP-CHECKLIST.md:57`); 04:253 "No credential crosses" | **VERIFIED** — three identities, one empty Firebase side |

**Correct target topology, as the documents define it:** Supabase owns everything server-side — Auth (email/password,
single identity authority), Postgres (RLS defence-in-depth, `auth.users` → profiles trigger), the 9 Deno Edge Functions
as the only client API, and Realtime on 4 tables. Firebase is intended **only** as an FCM transport: a best-effort
wake-up signal, client-side `google-services.json`, and a service-account JSON held exclusively as a Supabase Edge
secret (`02-architecture.md:84, 140, 189`). No Firebase Auth, no Firestore, no Cloud Functions, no Admin SDK in clients.

**What the new Firebase project does and does not do for this programme:** `haven-staging-46822` is a correct
pre-provisioning of the FCM transport lane, on the *other* Google identity, with Analytics and Gemini off and no apps.
It contributes **nothing** to Stage 2 remediation: P01–P03 are Supabase-side SQL, Firebase/FCM is deferred to A12/G2/G7,
and G5-S/G5-E/G5-C do not touch it. **If the owner believes auth lives on Firebase, remediation effort will be aimed at
an empty system** — that belief must be corrected before any Firebase work is scheduled.

**Live checks that would settle the NOT VERIFIED rows — named, not performed** (the brief bars console access): Supabase
Dashboard → Authentication → Providers and API → JWT keys, on both refs; Firebase console → `haven-staging-46822` →
Messaging / Auth / Firestore build pages; Google Cloud console → Cloud Functions for both projects; Firebase account
switcher across linked accounts (needs written authorisation per 04:251); Supabase → Edge Functions deploy hashes vs
editor text; Supabase → Project Settings → Data API exposure; and local inspection of `Haven-1.2-release.apk` for
Firebase SDK presence (a local artefact, not a console action).

---

## H. Next-step plan — recommended, not authorised

The safest order, with the approval each step needs. **This is a proposal; nothing in it is authorised by this audit.**

| # | Step | Needs | Note |
| --- | --- | --- | --- |
| 0 | **Stop the clock risk**: one dated dashboard touch on each project on or before **2026-11-06**, recorded as a read-only view | none beyond A1 | protects the last Free slot; must be logged with a UTC timestamp |
| 1 | Ratify or reverse the creation: a retrospective change record for the two projects, including the A12 breach and the Gemini deviation | owner decision | without it, R-36/R-37 stay live |
| 2 | Correct documentation status for both shells (FX-01…FX-06) | owner approval to edit | the plan of record is currently false |
| 3 | Re-issue the approval package: A2′ forward (sentinel + settings), secrets moved to A9, A12 boundary restated | owner signature | the existing block is unusable |
| 4 | Obtain **A0** (G3 method) and a written **A1** | owner signature | A0 has never been approved by anyone |
| 5 | Capture the production catalogue read-only (G3-a) | A0 + A1 | read-only SQL Editor on production is A1-class |
| 6 | Reconstruct the schema offline (G3-b) | none | produces the artefact |
| 7 | Secret-scan the artefact | none | record the scan result and hash |
| 8 | Obtain **A3** | owner signature | creation never implied this |
| 9 | Load the schema into staging | A3 | the step 00:71 gate must be fixed first (CD-08) |
| 10 | Create and verify the sentinel `private.s2_environment` | A2′ | must precede every patch |
| 11 | Verify staging settings and parity (SSL, connection logging, Realtime membership, publications) | A2′ | two of these were never captured even for production |
| 12 | Clear D-01…D-12 and re-hash the patches | owner approval to edit | P02 D-07 means the shipped file always aborts |
| 13 | Obtain **A5**, then apply P01 → P02 → P03 in the approved order, rehearsing rollback after each | A5 + reviewer pass | rollback is not rehearseable before step 9 |
| 14 | Run G5-S SQL cases | A5 | ceiling is 38, not 39 (CD-12) |
| 15 | Keep G5-E and G5-C **blocked** | A7/A8, A13 | 104 HTTP cases cannot run until functions are deployed from real source |
| 16 | Defer Firebase app registration, FCM and any credential crossing | A12, outside Stage 2 | separate owner decision, separate identity boundary |

**Do not** start step 5 or later during this audit; do not treat step 0 as a substitute for a coordinated window.

---

## I. Correction backlog (documentation-only, numbered)

1. **FX-01** — status lines in 00:3-5, 01:3-5, 04:3-4, 05:4-5, approval-package:3-4/27-28: replace "no project exists /
   read-only only" with `G6-a EXECUTED (shell only)`, and disclose the browser write actions.
2. **FX-02** — every "no Firebase action in Stage 2" statement (00:179, 02:69, 04:157/238/250, README:58): qualify as
   "project creation only, under owner instruction; no app, credential, FCM or config change".
3. **FX-03** — slot arithmetic (00:230, 01:19/116/131/179, 04:33/55, 06:35, pkg:22/151, CHANGELOG:17): `2 active, 2 used,
   0 remaining`; mark R-32/R-33 and U-08/U-09 resolved by S2-CREATE-01.
4. **FX-04** — usage rows 01:123/126 and pkg:25: log ingestion 0.20 GB, egress 0.14 GB.
5. **FX-05** — CHANGELOG: add an S2-OPS-01 entry for the creation; correct #11 (CD-20) which claims a fix that 03:135
   does not contain; delete or verify the root-README claim at :56; qualify the screenshot claim at :9-10.
6. **FX-06** — S2-CREATE-01: add A0/A2 to the non-approval list, reclassify "no settings change", add UTC start/end, and
   replace "no image of either console exists" with the §B.4 wording.
7. **FX-07** — 00 §3 sequence: split step 1 into "shell + sentinel" and step 2 into "load + verify"; delete the duplicate
   G6-c/G3-c; add A3 to the load gate; add A1 to step 5.
8. **FX-08** — approval package: move secrets out of A2 into A9, add the G6-b settings clause, retire the signature block
   and replace it with a ratification record plus a forward A2′.
9. **FX-09** — 02:41 E14 current status → `PROPOSED — NOT APPLIED`; 02:38 scope E11's "only"; 02:30 single tier for E3.
10. **FX-10** — 05 arithmetic: 21→20, 39→38, the 104/105 TE enumeration, and the 104-vs-108 G5-E total.
11. **FX-11** — 00:51-54 "Tier 3 / nine other findings" → "Tier C / 4 others"; 00:34 add F5; README:19 and 00:206
    "A0–A13" → "A0–A3, A5–A13 (A4 retired)".
12. **FX-12** — patch-defects:108 (the false "nowhere in the repository" claim), :109-110 (mis-attributed 04 §2.2),
    and the S3 counts at :22-26/232-233.
13. **FX-13** — 03:135 pre-check 0.4 → two rows per function, four total; sql:60 wording; D-02 two-pass commit gate;
    T3 relabelled as an invariant control.
14. **FX-14** — evidence addenda: INSP-02 supersession note; NEXT-01 supersession note; REVIEW-02 stamped "as at
    2026-10-30, pre-creation" plus its four miscitations.
15. **FX-15** — working papers: per-file `SUBORDINATE / SUPERSEDED` banners; strike parts/A's F4 validation, parts/B's
    platform-backup restore and parts/G's "G5-S Runnable"; rename the colliding A-numbers in parts/B:177-184; re-cite
    parts/J:69 against the hashed P03.
16. **FX-16** — risk register: add R-36…R-41; mark R-09/R-30 realised; retire R-32/R-33; raise viewport risk severity;
    record the auto-pause start date the moment it is known.
17. **FX-17** — architecture record: state plainly, in 02-architecture and Stage 2's 01, that **Supabase Auth is the
    identity authority and Firebase is FCM-transport-only**, so the topology question cannot be re-asked.
18. **FX-18** — *added after issue (2026-11-02, S2-DOC-02 pass; not a finding of this audit)*: the empty-shell premise
    is unproven — the staging Auth page renders **zero rows** while printing `Total: 10 users (estimated)`, and the
    same page on production prints an exact `Total: 8 users`, so "`auth.users` is empty" is
    **`NOT VERIFIED` — dashboard total contradicts, unresolved**, never `PASS`. Carried as risk **R-42**, defined at
    [S2-DOC-02](S2-DOC-02-reconciliation.md) `:70` and [00](00-stage2-execution-plan.md) `:304`, and placed by the
    owner (2026-11-02, S2-EXEC-02 §3) as the **first read-only statement inside the A3 window**
    (`select count(*) from auth.users;` on `dzonzgngwxclhfnvxtvu`); a non-zero answer stops the load. **A3 is unsigned,
    so the count is still unauthorised.** This row is register-parity only: it changes no status and closes nothing.

---

## J. Final verdict

### `NOT READY — CORRECTIONS REQUIRED`

**Why, with evidence:**

1. **The plan of record is factually false today** — 00:3-5 ✓, 01:3-5, 04:3-4 ✓ and approval-package:27 ✓ all assert no
   staging project exists and that the only browser use was read-only, while two projects exist and one of them (Firebase)
   was created against an explicit prohibition (04:157 ✓). A reader following these documents today would take unsafe
   actions in the wrong order or skip required approvals.
2. **No signable approval exists for the state of the world.** A0 has never been approved by anyone; A2's signature block
   is unusable because it describes a forward action already partly performed and four sub-actions deliberately not
   performed. Signing it as written would certify a false premise.
3. **G3 baseline capture is not ready** — 1 of 17 prerequisites VERIFIED; artefact, scan, A3 and sentinel all absent; and
   00:71 still gates the load on the wrong approval.
4. **No patch is applicable** — all twelve defects OPEN, P02's shipped file always aborts (D-07), P03 has no post-check and
   a name-only index guard, and every patch self-aborts on a database with no sentinel.
5. **The compensating-control claim is unmet** — zero of four single-owner controls are satisfied for the one action that
   was actually executed, and no document records the auto-pause deadline that is now the nearest real constraint.

**What *is* ready:** the two shells are correctly created, correctly named, isolated from production, and honestly
recorded; the patch files are provenance-stable; the finding, risk and coverage arithmetic in 02 and 04 is sound; and the
topology question is answerable from evidence rather than assumption.

**Minimum set to reach `READY WITH RECORDED LIMITATIONS`:** FX-01 through FX-06 (truth restoration), a ratified or
reversed creation record, and a re-issued approval package with A0 signed. Patch corrections (FX-12/FX-13) and the 05
arithmetic (FX-10) may follow, because nothing can reach A5 until A0, A1 and A3 exist.

**Stop condition for this pass:** the audit is delivered; no document was edited; no operational action was taken or is
authorised by it. Awaiting the owner's explicit instruction.

## SUPERSESSION ADDENDUM (2026-11-02, S2-DOC-02)

**Asserted here:** at issue, Stage 2 was `SCAFFOLD CREATED — PLAN OF RECORD FALSIFIED — REMEDIATION NOT STARTED`; §B/§D described documents that still
denied the creation; §I was an unapplied FX-01…FX-17 backlog; §H was a proposal, not a plan; 04 §1 was "exactly 35 rows, R-01…R-35".

**Superseded:** the backlog's currency — **FX-01…FX-06 (truth restoration) plus the Phase 4/Phase 5 items were applied by S2-DOC-02 on 2026-11-02**, so
the status lines, slot arithmetic and "no Firebase action" wording in §B/§D are corrected across 00, 01, 04, 05, README, CHANGELOG and S2-CREATE-01,
and [approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) now holds the ratification decision — recorded
`AWAITING RETROSPECTIVE RATIFICATION`, **not signed**; A0 remains unapproved by anyone. The FX-07…FX-17 items applied in the same pass are listed in
the S2-DOC-02 reconciliation matrix ([00](00-stage2-execution-plan.md) §9 and [CHANGELOG](CHANGELOG.md)) and are not enumerated again here.

**Verdict:** `NOT READY — CORRECTIONS REQUIRED` **as at issue (2026-11-02)**. No row above is deleted or rewritten: each remains valid for the
2026-11-02 read of the texts it inspected, and 04 §1 now running R-01…R-41 supersedes only its 35-row count.
