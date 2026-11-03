# S2-EXEC-05 — seven-agent evidence consolidation & G3 coverage reconciliation

**Verdict: `S2-EXEC-05 BLOCKED — INCOMPLETE AGENT EVIDENCE`** (the required single verdict from §10 — chosen because four
of the eight mandated reports never arrived and the eight architecture subagents all failed; **not** because the
assessment was inconclusive. The substantive A3 finding it was consolidating is negative and already independently
established: **`NOT LOAD-READY — RECONSTRUCTION GAPS`**, recorded in
[S2-EXEC-05-a3-readiness-assessment.md](S2-EXEC-05-a3-readiness-assessment.md) and
[S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md).)

Offline, repository-only. No dashboard, no SQL Editor, no SQL execution, no database connection, no CLI/API, no sentinel,
no schema load, no patch touch, no secret read or creation, no Firebase configuration, no production access, no Git
commit. No approval block was filled and no ratification, A0 approval or A5 approval was treated as permission for an
unsigned operation. The repository still has **zero commits**.

---

## 1. §4 — report validation table (a report is not complete because an agent produced a file)

| Agent | Domain | Report | Hash/lines | Scope completed | Scope NOT completed | Status |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Artefact identity + hashes | [S2-EXEC-04-evidence-and-hash-manifest.md](S2-EXEC-04-evidence-and-hash-manifest.md) | 988 L | 22 build-dir files hashed; 20/20 `100-file-hashes.txt` entries re-verified; manifest traceability 515/515 rows carry a source reference; all 7 listed authority docs PRESENT | Its three headline figures are **false**: 53 evidence files (→ 17), 56 q9/q10 rows (→ 19), "22-file hash list" (→ 20 entries / 22 files). Content descriptions of q9/q10 both wrong | **`CONFLICT REQUIRES RESOLUTION` → resolved by main agent in CF-02/03/05** |
| A2 | Object coverage | [S2-EXEC-04-object-coverage-matrix.md](S2-EXEC-04-object-coverage-matrix.md) | 478 L | All 22 categories; ACL re-measurement; index suppression; artefact-vs-`91-coverage` comparison | Object-level per-row provenance columns (§6) — delegated to the S2-EXEC-05 matrix, which failed | **`PARTIAL`** (usable; the finer matrix is missing) |
| A3 | Function/trigger forensics | [S2-EXEC-04-function-coverage-register.md](S2-EXEC-04-function-coverage-register.md) | 346 L | 38 functions; overloads; dependents; recovery hunt; A5/D-06 exposure | Did not emit the absent-body list **by name** in a machine-checkable table | **`COMPLETE`** |
| A4 | SQL structure | [S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md) | 134 L | 459 re-counted; H-1/H-2/H-3; load-order walk; rollback position | Line-level enumeration for MEDIUM/LOW findings compressed | **`COMPLETE`** |
| A5 | A3 preconditions | [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md) | 362 L | 24 precondition rows; 12 new blockers S4-BL-01…12; auto-pause | Some rows depend on A2/A4 outputs it could not see (correctly marked) | **`COMPLETE`** |
| A6 | Secret scan review | reply-only, by design | — | 13/22 scope; digest basis; pattern inventory; independent re-run | No file to hash; findings live in §2 of this report | **`PARTIAL`** (content complete, artefact-less by instruction) |
| A7 | Cross-check | reply-only, by design | — | 6 headline re-derivations; contradiction sweep; false-PASS sweep; fabricated-evidence catch | Same | **`PARTIAL`** (content complete, artefact-less) |
| B1 | Complete evidence inventory | [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md) | 350 L | Full inventory; unresolved-citation list; overstatement register | Agent died after writing; sections on coverage impact truncated | **`COMPLETE`** |
| B2 | Coverage matrix | **absent** | — | — | Terminated with "Now writing the deliverable"; `ls` confirms no file | **`PENDING`** |
| B3 | Function register | [S2-EXEC-05-function-body-coverage-register.md](S2-EXEC-05-function-body-coverage-register.md) | 225 L | 38 rows; dependents; recoverability; D-06 exposure | — | **`COMPLETE`** |
| B4 | SQL integrity | **absent** | — | — | Queue failure after 64 tool uses | **`PENDING`** |
| B5 | A3 readiness | [S2-EXEC-05-a3-readiness-assessment.md](S2-EXEC-05-a3-readiness-assessment.md) | 403 L | 11 gates; 10 preconditions nobody had checked; blockers S5-BL-nn | — | **`COMPLETE`** |
| B6 | Conflict register | **absent** → **substituted by this file's register** | — | — | Queue failure after 64 tool uses | **`PENDING`** → written by main agent |
| B7 | Final manifest | [S2-EXEC-05-final-evidence-manifest.md](S2-EXEC-05-final-evidence-manifest.md) | 528 L | Full digest register, patch digests, scan-coverage reconciliation, zero-commit confirmation | — | **`COMPLETE`** |
| B8 | Recovery hunt | **absent** | — | — | Queue failure after 78 tool uses | **`PENDING`** |
| C1–C8 | Architecture brief's 8 subagents | **all absent** | — | — | Every one failed on the credit limit (`S2-A1`…`S2-A6`, `S2-EXEC-FINAL.md` not created) | **`PENDING`** |

**Consolidation completeness: 6 of 8 S2-EXEC-05 reports exist (one substituted by me), 4 required files absent; 0 of 8
architecture subagent deliverables exist.** Per §10 and §11's final rule, the seven-agent review **cannot** be marked
complete, and the architecture programme cannot be marked as audited.

## 2. §3 — Agent 1's open findings, now closed

1. **All evidence files inspected.** `docs/stage1/evidence/` = **17** (16 + 1 in `edge-functions/`), not 53. Full register
   with sizes/digests in [S2-EXEC-05-final-evidence-manifest.md](S2-EXEC-05-final-evidence-manifest.md) and
   [S2-EXEC-05-complete-stage1-evidence-inventory.md](S2-EXEC-05-complete-stage1-evidence-inventory.md). `docs/stage1` as a
   whole holds 37 files.
2. **q9/q10 rows accounted.** **19 rows, not 56.** `g1-q9` = `{source, findings}`, a **production Security Advisor lint
   capture** (2026-10-29, GET-only) whose 5 findings are `auth_leaked_password_protection`, `auth_rls_initplan`,
   `rls_enabled_no_policy`, `unindexed_foreign_keys`, `unused_index`. `g1-q10` = `{schema_usage, functions}`, the **14-row
   `public` function inventory** with `owner`, `security_definer`, `settings`, `anon_exec/auth_exec/service_exec`,
   `extension_owned`, `acl`; `schema_usage` shows `anon`/`authenticated` both true. **Neither is per-table data and
   neither is Edge Function source** — the descriptions I passed to four agents were wrong.
3. **The two "missing" documents exist**: `functions-and-triggers.md` (120 L, `835f7660…`) and `schema-columns.md`
   (297 L, `5445c69a…`). `MISSING — NOT LOCATED` is **withdrawn**.
4. **Equivalent-information test (without claiming sameness).** `functions-and-triggers.md` §1 supplies a `Returns`
   column for the 14 public functions; `schema-columns.md` supplies a rendered column/constraint view. Neither is a raw
   catalogue export, so neither can be upgraded to `SOURCE VERIFIED` — they are dashboard-derived narrative, and
   `g1-run-manifest:59` labels it as such. That distinction is what CU-01 turns on.
5. **Hash reconciliation.** `100-file-hashes.txt` = **20 entries over a 22-file directory**: `gen_scan.py` and the hashes
   file itself are unlisted. **0 mismatches** among the 20 that are listed.
6. **Coverage impact of the newly-read evidence — real, and it moves two rows:**
   - `g1-q10` evidences **owner (`postgres`) and `search_path` settings for all 14 public functions**, and per-role
     EXECUTE flags. The artefact blanked these ("owner INFERRED from the ACL grantor", "language/volatility
     unattributable"). **Category 13 (function security properties) improves from inferred-partial to evidenced for the
     public set**; `private` (24) stays unattributable.
   - `g1-q9` corroborates H-1 from the platform's own advisor (`rls_enabled_no_policy`), but it is a **production**
     artefact and its use as schema evidence is an owner call under R-43 (CU-04).
   - It does **not** supply return types, bodies, extensions, publications, views or sequences. **`91-coverage.md` rows
     "Function security properties" and "Grants/ACLs" need editing; rows 1, 19, and the UNKNOWN categories do not change.**

## 3. §5 — reconciliation outcome

Twenty-one conflicts resolved by primary evidence and four retained unresolved — with both claims, the deciding evidence
and the disposition — in [S2-EXEC-05-cross-agent-conflict-register.md](S2-EXEC-05-cross-agent-conflict-register.md).
Headline: **459 statements, 1203/1186 commented lines, 515 provenance rows, 0 behavioural statements, and the full
`g1-*` row counts all reproduce under independent re-measurement**; what did not reproduce were **derived labels and
composition claims** (24-vs-12+12, 19-vs-38 units, "four fences", "bytes" that were lines, "timestamped", the
non-existent `create_edge_api_token` body, R-13's 23, `96`'s 25-row inventory, the scan's pattern taxonomy and file
scope, and the scan's LF-vs-byte digest basis).

## 4. §6 / §7 — coverage and function totals actually supported

- **858 object-level records** identified across the evidenced categories (2 schemas + 19 tables + 183 columns + 137
  constraints + 62 indexes + 38 functions + 8 triggers + 21 policies + 149 table-grant rows + 191 column-grant rows +
  24 default-ACL rows + 24 role-membership rows). Categories with **no countable population** stay `UNKNOWN`:
  extensions, views/materialised views, sequences, object comments, storage parameters, identity/generated columns.
- 22-category states: **8 `PRESENT — SOURCE VERIFIED` · 8 `PRESENT — PARTIAL` · 4 `MISSING — SOURCE EVIDENCE ABSENT` ·
  1 `UNVERIFIED — SOURCE AMBIGUOUS` · 1 `CONFLICT — SOURCE DISAGREEMENT`** (category 17 carries a partial state and a
  conflict flag; counted once).
- **The 24 absent bodies: 0 recovered**, searched repo-wide (79 files by one auditor, corroborated by another): no
  migrations, no `supabase/functions`, patches define only already-captured bodies plus one new function. **Composition
  corrected to 12 `public` + 12 `private`.** All 24 remain `UNVERIFIED / MISSING — SOURCE EVIDENCE ABSENT`; no body,
  return type, empty stub or placeholder was written anywhere in this phase.
- **Blocking mechanism, corrected:** 25 of 29 captured dependents (8 triggers + 17 policies) are blocked on functions
  whose **bodies are already present** — the missing piece is `prorettype`, not `prosrc`. 4 policies (`families_update_owner`,
  `profiles_update_self`, both `webrtc_signals`) are over-blocked, needing only `auth.uid()`.

## 5. §8 — artefact integrity

Assembled artefact `g3-reconstruction-2026-11-02.sql`: byte digest **`fc996f45…`**, LF-normalised digest `efdbf985…`
(the basis the scan recorded), 459 statements, 661 code lines, 1186 commented lines in the assembled file (1203 across
components — a **basis** the prior report did not label). **Unchanged** by this audit. The secret scan is **not tied to
the byte digest** and covered 13 of 22 files → the binding is `NOT VERIFIED`, closable offline by re-hashing and
re-scoping. 71 pattern-shaped strings exist in the never-scanned digest lists/scripts (values never reproduced here);
0 in the scanned scope, reproduced independently. **Zero matches is not proof of no secrets** — the 24 absent bodies were
never in any scanned file.

## 6. §9 — A3 readiness

**MET 1 · NOT MET 8 · NOT VERIFIED 1 · NOT APPLICABLE 1** across the eleven gates (§9's own list). A0 is approved as a
recorded decision with its fence unfilled; A1 is `INOPERATIVE`; A2′(a), A2′(b), A3, A9, A12 unsigned; A5 approved but not
executable; the `auth.users` count is unrun and remains unauthorised outside a signed A3; rollback is unassessable on a
plan with no backups/PITR. Auto-pause: **`NOT EXECUTED IN THIS PHASE`** — a dated touch was due on or before 2026-11-06
with no UTC start recorded; the last authorised read-only observation is 2026-11-02T07:16Z, a historical record, **not**
a claim that staging is currently healthy.

## 7. §12 — required response, item by item

| Required item | Answer |
| --- | --- |
| All seven agents returned complete reports? | **No.** 5 of 7 first-wave reports written (2 by design reply-only), 2 of them with false headline figures; 4 of 8 second-wave reports absent; 0 of 8 architecture subagent reports exist |
| Evidence files inspected out of 53 | **17 of 17** — the denominator 53 is wrong (CF-02) |
| q9/q10 rows reconciled out of 56 | **19 of 19** — the denominator 56 is wrong (CF-03), and both files were misdescribed |
| Expected G3 objects identified | **858** object-level records + 7 `UNKNOWN` categories with no population |
| Verified / partial / missing / unverified / conflicting | Category-level: **8 / 8 / 4 / 1 / 1** (of 22) |
| Status of the 24 absent bodies | **0 recovered · all `UNVERIFIED` · composition corrected to 12 public + 12 private** |
| Were the two missing documents located? | **Yes** — both present; `MISSING — NOT LOCATED` withdrawn |
| Does the secret scan match the exact artefact hash? | **No** — LF-vs-byte basis mismatch and 13/22 scope → `NOT VERIFIED` |
| Unresolved conflicts | **CU-01** return types 0/38-vs-14/38 · **CU-02** public-vs-private attributability · **CU-03** 4 emittable policies (finding, not action) · **CU-04** whether production-lint `g1-q9` is admissible under R-43 |
| Final verdict | **`S2-EXEC-05 BLOCKED — INCOMPLETE AGENT EVIDENCE`**, with the substantive A3 finding already negative: `NOT LOAD-READY — RECONSTRUCTION GAPS` |
| Exact next permissible action | Owner-only decision, below |

## 8. Next permissible action

**One: re-run the four absent reports and the eight architecture subagents once execution capacity is restored** — an
owner/runtime action, not something I can self-authorise. Nothing in this phase creates, loads, configures or deploys
anything.

Then, for the programme itself, the ordered choices are unchanged and each still names its approval ID:

| Want | Needs | Present state |
| --- | --- | --- |
| Read the artefact and its limitations as the structural-only baseline | **owner review** (no approval ID) | available now |
| Emit the 4 `auth.uid()`-only policies / add the 14 evidenced public-function attributes to the artefact | a **new offline build pass under A0 as amended** — still not a load | A0 approved as recorded; fence unfilled |
| Sentinel `private.s2_environment` | **A2′(a)** | unsigned |
| Any schema load, incl. the `auth.users` count as first statement | **A3** | unsigned — and meaningless while 0 behavioural statements exist |
| Settings + Realtime publication | **A2′(b)**, after A3 | unsigned |
| Apply P01/P02/P03 | **A5** execution | approved, not executable (P02 aborts; P03 blocked) |
| Return types / bodies / extensions / publication for the 24 | **production read = A1 or a replacement**, i.e. an owner decision that changes the staging-only absolute | `INOPERATIVE` / prohibited |
| Firebase Auth, Android app, FCM, credentials | **A12** | unsigned; app registration and FCM prohibited |
| Staging DB credential reset | **A9** | unsigned |
| Dated dashboard touch before 2026-11-06 | **separate owner instruction** | not given |
| The architecture migration brief (Phases 4–7) | the gates above, **all still unsigned** — the brief does not override them; and **Subagents 5/6 cannot run at all: this repository contains no Flutter or Kotlin source** | `BLOCKED` |

**Final rule observed:** seven reports consolidated ≠ seven agents passed, and a clean hash comparison ≠ G3 completeness.
