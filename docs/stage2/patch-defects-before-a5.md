# Patch documentation defects to resolve before A5

**Status: `PROPOSED — NOT APPLIED`.** Documentation review only. **No SQL file was changed by this pass**, no patch was
run, no project was created, and no dashboard was opened. Where a defect cannot be fixed by documentation, it is listed
as **`PATCH REVISION REQUIRED`** and stays unapplied until it gets its own review (A5 evidence must hash the file it
actually ran).

Inputs reviewed: [03](03-patch-S2-P01.md), [patches/S2-P01-e2-f8.sql](patches/S2-P01-e2-f8.sql),
[parts/D](parts/D-e3-f7-e1.md), [patches/S2-P02-e3-actor-binding.sql](patches/S2-P02-e3-actor-binding.sql),
[parts/E](parts/E-e4-session-invariant.md), [patches/S2-P03-e4-session-invariant.sql](patches/S2-P03-e4-session-invariant.sql),
against the rollback and verification rules in [04](04-risks-rollback-approvals.md) §2–§4 and
[06](06-redteam-resolution.md) J-04, J-07, J-09.

**Severity legend.** **S1** = a reviewer following the document would false-pass, or a prescribed step is impossible as
written → fix before A5. **S2** = ambiguity that costs time but not safety → fix before A5 where cheap. **S3** = patch
revision (SQL text), outside this pass.

---

## 1. Summary

| Patch | S1 | S2 | S3 (revision) | Verdict |
| --- | --- | --- | --- | --- |
| S2-P01 | 3 | 1 | 3 | Doc half of D-01/D-02/D-03/D-04 applied in [03](03-patch-S2-P01.md) 2026-11-02 — **re-check required**; the SQL-side revisions stay open |
| S2-P02 | 4 | 1 | 4 | Not ready for A5: no in-file rollback, advisory-only post-check, hidden gate edit |
| S2-P03 | 2 | 1 | 2 | Not ready for A5: no in-file rollback, preconditions incomplete |
| **Total** | **9** | **3** | **7 defects / 9 file revisions** | Recounted 2026-11-02 from the rows below |

**S3 recount (FX-12, 2026-11-02).** The seven defects carrying a **Patch revision (`S3`)** instruction are **D-01, D-02, D-05,
D-06, D-07, D-09, D-10**; D-03 states explicitly "No SQL change (`S3` not needed)" and D-04, D-08, D-11, D-12 are
document-only. Spreading D-09 across all three files gives nine file-level revisions: P01 = D-01 + D-02 + D-09 = 3; P02 =
D-05 + D-06 + D-07 + D-09 = 4; P03 = D-10 + D-09 = 2. The previous row printed "P01 S3=1, P03 S3=3" and §5 printed "four
`PATCH REVISION REQUIRED` items"; both miscounted this file's own rows. Per-patch **S1/S2** recount: P01 S1 = D-01, D-02,
D-03 (3) and S2 = D-04 (1, previously printed as 0); P02 S1 = D-05, D-06, D-07, D-08 (4), S2 = D-09 (1); P03 S1 = D-10, D-11
(2), S2 = D-12 (1).

None of these defects affects the *security logic* of the patches. All of them affect whether the evidence produced at
A5 can be trusted — which is the only reason A5 exists.

---

## 2. S2-P01 — `03-patch-S2-P01.md` + `patches/S2-P01-e2-f8.sql`

### D-01 — Pre-check 0.4 row count is wrong (`S1`, doc + file comment)

**Current text.** [03](03-patch-S2-P01.md) §4: *"0.4 explicit ACL | one row per function: grantee `PUBLIC`, `EXECUTE`,
not grantable"*. The same assumption is in the SQL comment `S2-P01-e2-f8.sql:55`: *"Expect grantee 0 (PUBLIC) with
EXECUTE only."*

**Why it is wrong.** Query 0.4 explodes `coalesce(p.proacl, acldefault('f', p.proowner))`. For a `NULL` `proacl`,
`acldefault('f', owner)` yields **two** entries per function — the owner's implicit EXECUTE and `PUBLIC`'s EXECUTE. The
real output is **4 rows** (2 functions × owner + PUBLIC), all `is_grantable = f`, owner shown as `postgres`.

**Impact.** A reviewer matching the document sees 4 rows where 1 was promised, and either stops a correct patch or
learns to wave the table through. Both outcomes make 0.4 worthless as a control.

**Exact correction.** In §4 row 0.4, replace the Expected cell with:

> `2 rows per function (4 total)`: one owner row (`postgres`, `EXECUTE`, not grantable) and one `PUBLIC` row
> (`EXECUTE`, not grantable). An explicit `anon`/`authenticated` row is the stop condition.

**Patch revision (`S3`).** Correct the comment at `S2-P01-e2-f8.sql:55` to the same wording. Comment-only, no logic
change, but it alters the file hash — so it must be re-reviewed and re-hashed **before** A5, not during the window.

**Status (S2-DOC-02, 2026-11-02).** `OPEN (document corrected, re-check required)` — the §4 row 0.4 in [03](03-patch-S2-P01.md)
(`03:135`) now reads "`2 rows per function` (owner + PUBLIC), **4 rows total**: owner row `postgres`/`EXECUTE`/not grantable,
PUBLIC row `EXECUTE`/not grantable" — the same content as the spec above, in the neighbouring rows' table style — plus the
note under §4 that this is a documentation fix and the SQL was not modified. The SQL comment at `S2-P01-e2-f8.sql:55` is
**unchanged** and still wrong; that half remains `PATCH REVISION REQUIRED`.

### D-02 — §1 commits before the post-check can be compared (`S1`, doc + file structure)

**Current text.** [03](03-patch-S2-P01.md) §2: *"the post-check runs inside the transaction so a mismatch can be rolled
back before commit"*; §5: *"If any cell differs, `rollback;` — do not fix forward"*.

**Why it is wrong.** The patch file is `begin; … 1.5 post-check … commit;` at line 170, followed by a comment at 171–172:
*"If the post-check above did not match, run: rollback; instead of commit"*. Pasted and executed as one block, `commit`
fires before the operator has read 1.5's output. "Instead of commit" is only achievable by **editing the file before
running it** — which changes the hashed text the reviewer approved and is not what the document describes.

**Exact correction.** In §2 and §5, state the execution model explicitly:

> §1 is executed as **two passes in one open transaction**, not one paste: run `begin;` through statement 1.5, compare
> the output with §5, and only then run `commit;` as a separate execution. "Instead of commit" means **omitting or
> deleting line 170** for this run, not rewriting any other statement. The applied text and its hash are recorded in the
> change record; a file edited this way is recorded as an edited copy of the reviewed hash.

**Patch revision (`S3`).** Move `commit;` behind an explicit stop-and-confirm comment block so the safe path is the
default paste. Until then the two-pass instruction above is the controlling procedure.

**Status (S2-DOC-02, 2026-11-02).** `OPEN (document corrected, re-check required)` + `OPEN (patch file unchanged)`. In
[03](03-patch-S2-P01.md): §2.3's "Single transaction" row now points at the two-pass procedure, and new §5.1 "Two-pass
execution" states that the four-step run is pass 1 = file lines 97–168, verify against §5, pass 2 = `commit;` (line 170) as
a separate execution; it says plainly that omitting line 170 is an **edit of the hashed file**, recorded as an edited copy
of the reviewed hash. `S2-P01-e2-f8.sql:170` and the 171–172 comment are **unchanged**; the commit placement itself is not
fixed.

### D-03 — T3 cannot discriminate pre-state from post-state (`S1`, doc)

**Current text.** §6 T3 (line 167): `anon` call → *"`42501 permission denied for schema private` (USAGE fails first)"*.
§9 (line 221) makes *"T2/T3 do not return `42501`"* a stop condition. §3 line 113 already says `anon` is *"already
blocked by schema USAGE"*.

**Why it is wrong.** The identical error occurs **before** the patch, so T3 passes whether or not P01 was applied. It
looks like a privilege test and is actually a no-op, and it sits in the stop-condition list.

**Exact correction.** Relabel T3 as an **invariant control** (must be identical before and after), and make the
assertion explicit:

> T3 — `anon`: `set local role anon; select has_function_privilege('anon',
> 'private.request_device_recovery(uuid,uuid)', 'EXECUTE');` → `false`. The direct call also returns
> `42501 permission denied for schema private`, **before and after** the patch; the error text alone is not evidence.
> Remove T3 from the stop conditions as a "must return 42501" check; keep it as "privilege must be false".

No SQL change (`S3` not needed).

**Status (S2-DOC-02, 2026-11-02).** `OPEN (document corrected, re-check required)` — [03](03-patch-S2-P01.md) §6's T3 row is
relabelled "**INVARIANT control — not a discriminating test**" with the `has_function_privilege('anon', …) = false`
assertion, T3 is deleted from §9's stop list ("T2/T3 do not return `42501`" → "T2 does not return `42501`"), and §6's note
records that on the current empty staging database T3 **cannot run at all**: `set local role anon` needs a role and a
`private` schema that are absent. Doc-only defect; nothing in the SQL refers to T3.

### D-04 — Rollback section says "§2" of the file (`S2`, doc)

The rollback block is at `S2-P01-e2-f8.sql` line 175 onward, under the heading **SECTION 2**, while [03](03-patch-S2-P01.md)
§7 is the document section. §7's closing sentence ("ships inside … §2") is correct but reads as document §2. Correct to:
*"inside the file's `SECTION 2 — ROLLBACK`, commented out."*

**Status (S2-DOC-02, 2026-11-02).** `OPEN (document corrected, re-check required)` — [03](03-patch-S2-P01.md) §7 now reads
"the file's own **`SECTION 2 - ROLLBACK`**, the heading at `patches/S2-P01-e2-f8.sql:176` with the commented statements at
183–191 … not §2 of this document", and §9's "if §1 already committed" is disambiguated to "`SECTION 1 - APPLY` in the SQL
file (lines 97–170)". Doc-only; SQL headings unchanged.

---

## 3. S2-P02 — `parts/D-e3-f7-e1.md` + `patches/S2-P02-e3-actor-binding.sql`

### D-05 — No rollback inside the patch file (`S1`, doc; revision `S3`)

**Current state.** The file ends at line 155 with `commit;`. [parts/D](parts/D-e3-f7-e1.md) §9 (≈182–190) describes the
rollback in prose: *"`CREATE OR REPLACE` … with the captured body"*.

**Correction of that claim (FX-12, 2026-11-02).** The words "text that exists **nowhere in the repository**" were false.
Verified by reading [g1-b3b-20261029.json](../stage1/evidence/g1-b3b-20261029.json) read-only: the original bodies are
**absent from the patch file; present as Stage 1 `prosrc` captures at g1-b3b-20261029.json:149/155/159/165** — `149`
`private.request_device_recovery(uuid, uuid)` body; `155` `public.request_device_recovery` wrapper body; `159` the
`public.request_remote_session(uuid, uuid, text)` `bodies` entry (its `body` value at 161); `165` the
`private.unlink_child(uuid, uuid, uuid)` entry (its `body` value at 167). Rollback must therefore be **assembled** from
those `prosrc` values plus the inventory metadata at `62` (`private.request_device_recovery`), `67`
(`private.unlink_child`) and `78` (`public.request_remote_session`) — owner, `security_definer` and `settings` — and the
assembled text **must be reviewed and hashed before A5**. It is `prosrc`, not `pg_get_functiondef` output, so the assembled
`create or replace function …` wrapper (signature, `security` clause, `set search_path`, language) is reviewer-written and
must be checked against 04 §2.2's verification row (`prosrc` hash equals the stored capture). The Stage 1 captures are the
**reference** text (staging is loaded from the same baseline), not a substitute for the 04 §2.2 pre-apply staging capture:
if staging's `prosrc` differs from `json:149/161/167`, the staging text governs the rollback.

**Attribution correction (FX-12, 2026-11-02).** This row previously said "[04] §2.2 and [06] J-04 **both** require the
rollback text to ship inside the patch file". Reading 04 §2.2 (04:107–116) it does not: it prescribes `create or replace`
each function "with the **stored pre-apply text captured from the staging catalogue immediately before apply**" (04:111),
and 04's §2 preamble requires only that "the rollback text was reviewed with the patch" (04:89) — a review condition, not an
in-file condition. The in-file rule comes **only from [06](06-redteam-resolution.md) J-04** ("rollback ships inside the patch
file (commented, reviewed as executed)"), and J-04's finding line is scoped to **P01**. Extending it to P02/P03 (as D-05 and
D-10 do) is a programme convention taken from J-04, not a rule 04 states: the requirement still stands, but it is J-04's
requirement and the 04 §2.2 capture route is the operative one for this patch.

**Impact.** At A5 the operator must hand-write three function bodies under time pressure from a catalogue read, on the
one patch that rewrites bodies. That is precisely the failure mode R-06/R-13 exist for.

**Exact correction.** parts/D §9 must state, at the top:

> **Rollback artefact is not in this file.** Before any A5 execution, capture `pg_get_functiondef` for
> `private.request_device_recovery(uuid,uuid)`, `private.unlink_child(uuid,uuid,uuid)` and
> `public.request_remote_session(uuid,uuid,text)` from **staging**, store the text outside the repository, hash it, and
> paste it into the change record as the rollback. Until that artefact exists, S2-P02 is **`BLOCKED — ROLLBACK NOT
> CAPTURED`** regardless of A5 approval.

**Patch revision (`S3`).** Add a commented `SECTION 2 — ROLLBACK` with the captured bodies (placeholders referencing the
capture file, not invented SQL). Separate review.

### D-06 — Post-checks are advisory, not assertions (`S1`, doc; revision `S3`)

**Current state.** Lines 147–154 select `prosecdef`, `proconfig`, `proacl` for the three functions. They do **not**
select a `prosrc` hash or an overload count, and nothing aborts on a mismatch. [parts/D](parts/D-e3-f7-e1.md) (≈187) and
[04](04-risks-rollback-approvals.md) R-06 require both.

**Exact correction.** parts/D §10 must say:

> Post-check 5 is **manual and mandatory**: before `commit`, record (a) `md5(prosrc)` for each of the three functions,
> (b) `count(*)` of `pg_proc` rows matching each signature's name in its schema (must remain 1), and (c) `prosecdef =
> true` and `proconfig = {search_path=public, private, pg_temp}`. A hash that differs from the pre-apply capture, or an
> overload count above 1, is a stop — `rollback;` and record.

**Patch revision (`S3`).** Convert the select into an assertion block that raises on mismatch.

### D-07 — The approval gate is shipped commented out (`S1`, doc; revision `S3`)

**Current state.** `S2-P02:27–28`: *"Uncomment only in an approved staging window"* / `-- select set_config('haven.patch_gate', 'S2-P02', true);`.
The block at 29–37 **requires** `current_setting('haven.patch_gate') = 'S2-P02'`. As shipped, the file always aborts.

**Why it matters beyond inconvenience.** The text that will run is an **edited** copy of the hashed file. If the change
record hashes the shipped file, the recorded hash is not the hash that executed — which defeats the compensating
evidence for A5.

**Exact correction.** parts/D must add a §0 note:

> The file as shipped aborts by design: line 28 is commented out. Uncommenting it is part of the A5 execution. The
> change record must hash **the file as executed** (gate uncommented) and the shipped file separately, and state that the
> only difference is line 28.

**Patch revision (`S3`).** Move the gate behind a `\set`-free explicit block that reads a value the operator sets, so no
edit is needed.

### D-08 — Capture list omits one of the three changed functions (`S1`, doc)

[parts/D](parts/D-e3-f7-e1.md) §6 (≈112–116) lists captures for `private.request_device_recovery`,
`private.unlink_child`, and the ACL/config of the third, but omits **`public.request_remote_session`'s full definition**
from the "capture before change" list, although §4 alters its `search_path`. Correct the list so all three bodies are
captured before apply.

### D-09 — `limit 1` sentinel has no ordering or cardinality contract (`S2`, doc; revision `S3` ×3)

`S2-P02:20` (and `S2-P01:108`, `S2-P03:27`) read `select environment from private.s2_environment limit 1` with no
`ORDER BY` and no row-count check. With one row this is correct; with two it is arbitrary.

**Exact correction.** State in [00](00-stage2-execution-plan.md) G6-b (already says "one row") **and** in each patch
doc: the sentinel table must return exactly one row; `count(*) = 1` is verified in G6-b and re-verified before each
apply. A second row is a stop condition.

**Patch revision (`S3`).** Add `and (select count(*) from private.s2_environment) = 1` to the sentinel condition in all
three files.

---

## 4. S2-P03 — `parts/E-e4-session-invariant.md` + `patches/S2-P03-e4-session-invariant.sql`

### D-10 — No rollback inside the patch file (`S1`, doc; revision `S3`)

The file ends at line 127 with `commit;`. Rollback exists only as prose at
[parts/E](parts/E-e4-session-invariant.md) ≈193–196. The statements are simple and fully specified there, so the risk is
lower than D-05, but the rule is the same one J-04 sets for P01 — **and only J-04 sets it**: [04](04-risks-rollback-approvals.md)
§2.3 (04:125) supplies the three `drop …` statements but nowhere requires them inside the file (see the D-05 attribution
correction).

**Exact correction.** parts/E must state that the three statements at ≈193–196 are the reviewed rollback and must be
copied into the change record as the rollback text before A5, then add: *"S2-P03 is `BLOCKED — ROLLBACK NOT IN FILE`
until the change record holds that text."* **Patch revision (`S3`)**: add the commented rollback section to the file,
matching [04](04-risks-rollback-approvals.md) §2.3's object names exactly (`remote_sessions_insert_guard`,
`private.remote_session_insert_guard()`, `public.remote_sessions_one_live_per_device`).

### D-11 — Header preconditions omit both gates (`S1`, doc)

`S2-P03:6–9` lists three preconditions: zero duplicates, remediate if not, object-name precheck. Missing:

1. **P02 must be applied first.** [06](06-redteam-resolution.md) J-19 and [00](00-stage2-execution-plan.md) §3 fix the
   order G6 → G3 → P01 → P02 → P03; the header does not say it and the file itself would run on a P02-less schema.
2. **The read-only production duplicate count.** [04](04-risks-rollback-approvals.md) R-05 requires knowing how many
   duplicate live sessions already exist in production before approving the index, because the index is the backstop
   for a state that production may already be in. The header's "target project" wording is ambiguous while parts/E
   line 3 says no production row was read.

**Exact correction.** Replace the Preconditions block with four numbered items:

> 1. P02 applied and its post-check recorded in the change record (same window).
> 2. Read-only production duplicate count recorded (`P1` from §4.1, counts only — no payload), and its result stated in
>    the A5 record. This is a read-only query; it is not a production write and does not authorise one.
> 3. Section 4.1 precheck run **in staging** returns zero duplicate live sessions.
> 4. Section 4.1 P4 object-name precheck shows no conflicting object.

### D-12 — Transition-guard compatibility is unstated (`S2`, doc)

[06](06-redteam-resolution.md) records that the existing transition guard must permit `requested → expired`; parts/E
asserts the new trigger is `BEFORE INSERT` only and therefore does not interfere, but the header does not state the
assumption the reviewer must confirm.

**Exact correction.** Add to Preconditions: *"Confirmed from the captured `remote_session_transition_guard` body that
`requested → expired` is permitted, because the insert trigger's expiry path performs that transition."*

---

## 5. What this list does not do

- It does not change any SQL, hash, patch status or finding status. Every patch remains **`PROPOSED — NOT APPLIED`**.
- It does not authorise A5. A5 needs the S1 items corrected **and** the S3 revisions reviewed as new files with new
  hashes; correcting a document does not correct a file.
- It does not establish that any pre-check output is correct — none has been run.
- It does not re-open any Stage 1 finding.

**Recommended order:** D-01…D-04 (P01 docs) → D-05…D-09 (P02 docs) → D-10…D-12 (P03 docs) → one revision pass for the
**seven** `PATCH REVISION REQUIRED` items (D-01, D-02, D-05, D-06, D-07, D-09, D-10 — **nine** file-level revisions, because
D-09 edits all three files) → re-hash → A5.

---

## 6. Defect status after S2-DOC-02 (2026-11-02)

Scope of this pass: [03](03-patch-S2-P01.md) and this file, nothing else. No `.sql` file was opened for writing and none was
executed. Staging (`dzonzgngwxclhfnvxtvu`) is an empty shell — 0 tables, no schema, no `private.s2_environment` sentinel, no
test principals — so **nothing** below is evidence of an applied change; on that database all three patches self-abort at
their own sentinel, P01's §0 additionally hard-casts `::regprocedure` (`S2-P01-e2-f8.sql:40–41`) against functions that do
not exist there, and no §4/§5/§6 table of 03 can be reproduced.

| Defect | Status | Checkable against |
| --- | --- | --- |
| D-01 | `OPEN (document corrected, re-check required)` | 03 §4 row 0.4 (`03:135`) now reads "`2 rows per function` (owner + PUBLIC), **4 rows total**"; correction note under 03 §4 says documentation-only |
| D-01 (SQL) | `OPEN (patch file unchanged)` | `S2-P01-e2-f8.sql:55` still "Expect grantee 0 (PUBLIC) with EXECUTE only" |
| D-02 | `OPEN (document corrected, re-check required)` | 03 §2.3 "Single transaction" row points to 03 §5.1; 03 §5.1 gives the two passes (lines 97–168 / line 170) and states that omitting line 170 is an **edit of the hashed file**, recorded as an edited copy |
| D-02 (SQL: commit placement) | `OPEN (patch file unchanged)` | `commit;` remains at `S2-P01-e2-f8.sql:170` in the same block as the post-check, with the 171–172 "rollback; instead of commit" comment — no stop-and-confirm gate exists |
| D-03 | `OPEN (document corrected, re-check required)` | 03 §6 T3 row relabelled "**INVARIANT control — not a discriminating test**"; 03 §9 stop list now "T2 does not return `42501`" with T3 explicitly excluded; 03 §6 note records T3 is un-runnable on empty staging (`set local role anon` needs a role/objects that are absent) |
| D-04 | `OPEN (document corrected, re-check required)` | 03 §7 now says the file's own **`SECTION 2 - ROLLBACK`** (`S2-P01-e2-f8.sql:176`, statements 183–191) and "not §2 of this document"; 03 §9 disambiguates `SECTION 1 - APPLY` (97–170) |
| D-05 | `OPEN (patch file unchanged)` | `S2-P02-e3-actor-binding.sql` has no rollback section; the file still ends at `:155` with `commit;`. Claim fixed in §3 above: prosrc bodies are at `g1-b3b-20261029.json:149/155/159/165` (metadata `62/67/78`), so the rollback is **assembled**, not absent from the repository; in-file rule attributed to 06 J-04 only |
| D-06 | `OPEN (patch file unchanged)` | `S2-P02:147–154` remain advisory selects: no `md5(prosrc)`, no overload `count(*)`, nothing raises on mismatch |
| D-07 | `OPEN (patch file unchanged)` | `S2-P02:28` is still `-- select set_config('haven.patch_gate', 'S2-P02', true);` while `S2-P02:29–37` requires that setting — **the shipped file always aborts**; running it needs a hash-changing edit |
| D-08 | `OPEN (document not corrected here — not this agent's file)` | parts/D §6 (≈112–116) capture list still omits `public.request_remote_session`'s full definition |
| D-09 | `OPEN (patch file unchanged)` | Un-ordered, un-counted `limit 1` sentinel reads remain at `S2-P01-e2-f8.sql:108`, `S2-P02:20`, `S2-P03:27`; none carries `count(*) = 1` |
| D-10 | `OPEN (patch file unchanged)` | `S2-P03` still ends at `:127` with `commit;` and has no commented rollback section; parts/E ≈193–196 is prose only |
| D-10b (P03 post-check / index identity) | `OPEN (patch file unchanged)` | `S2-P03` has **no post-check block**: after `create unique index if not exists` (`:123–125`) nothing verifies the trigger, the index definition, or the guard function before `commit;`. `if not exists` is **name-only** — the file's own comment at `:122` says so — so a same-named object with a different predicate is accepted and committed silently |
| D-11 | `OPEN (document not corrected here — not this agent's file)` | `S2-P03:6–9` header still lists three preconditions; P02-first ordering and the read-only production duplicate count are absent |
| D-12 | `OPEN (document not corrected here — not this agent's file)` | parts/E preconditions still omit the "`requested → expired` is permitted by the transition guard" confirmation |

**Ownership note.** Only [03](03-patch-S2-P01.md) and this file were written by this pass. The document halves of D-05,
D-06, D-07, D-09 and D-10 that live in [parts/D](parts/D-e3-f7-e1.md), [parts/E](parts/E-e4-session-invariant.md) and
[00](00-stage2-execution-plan.md) G6-b are **not** corrected here; each row's "Exact correction" above is the text still to
be applied in those files by their owners.

**Hashes.** No patch hash changed in this pass; the three `.sql` files were only read. Re-computed with `sha256sum`
(read-only) after the pass, matching the values recorded before it:

| File | SHA-256 | State |
| --- | --- | --- |
| `patches/S2-P01-e2-f8.sql` | `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51` | unchanged |
| `patches/S2-P02-e3-actor-binding.sql` | `01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67` | unchanged |
| `patches/S2-P03-e4-session-invariant.sql` | `8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4` | unchanged |

Correcting a document does not correct a file: none of these patches is A5-ready, because the SQL-side halves above are
unresolved and, until they are revised and re-hashed, the A5 record would hash a file whose stated expectations are the ones
this table still calls wrong. No approval is signed here and no patch is claimed as applied.

---

S2-DOC-02 addendum (2026-11-02): documentation correction only; no patch file modified; no patch applied; no operational
action.
