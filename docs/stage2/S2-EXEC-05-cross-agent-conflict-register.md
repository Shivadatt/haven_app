# S2-EXEC-05 — cross-agent conflict register

**Status of this register: `COMPLETE AS A REGISTER`; the seven-agent consolidation it serves is `PARTIAL` — see
[S2-EXEC-05-seven-agent-consolidated-report.md](S2-EXEC-05-seven-agent-consolidated-report.md).**

Compiled by the main agent from: the eight S2-EXEC-05 / seven S2-EXEC-04 auditor replies that landed, the reports they
wrote, the audited artefact at `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/`, and **measurements I took myself** in this
session. Every conflict is preserved with both claims; nothing was resolved by choosing the more convenient number
(S2-EXEC-05 §5). Offline-only: no cloud access, no SQL executed, no artefact or patch modified, no approval inferred, no
Git commit (the repository still has **zero commits** — verified: `git log` → "your current branch 'master' does not have
any commits yet").

## 1. Conflicts where the primary evidence resolves the question

| # | Claim A | Claim B | Evidence that decides it | Disposition |
| --- | --- | --- | --- | --- |
| CF-01 | "Agent 1: `schema-columns.md` and `functions-and-triggers.md` were **not found** at the expected paths" (relayed into S2-EXEC-05 §3) | Both files are cited as PRESENT by the plan of record | `find` → `docs/stage1/evidence/functions-and-triggers.md` (120 lines, 10,865 B, `835f7660…`) and `…/schema-columns.md` (297 lines, 11,964 B, `5445c69a…`); cited at [00:87](00-stage2-execution-plan.md#L87) and [S2-EXEC-03:29](S2-EXEC-03-documentation-reconciliation-report.md#L29) | **RESOLVED — claim A is FALSE.** The files exist. The real defect is that the artefact **never cites** `functions-and-triggers.md` (0 occurrences across all 16 files) |
| CF-02 | "`docs/stage1/evidence/` contains **53 files**" (relayed into S2-EXEC-05 §3.1 and my own agent briefs) | "measured 17" | `find docs/stage1/evidence -type f \| wc -l` = **17** (16 top-level + 1 in `edge-functions/`); `find docs/stage1 -type f` = **37** | **RESOLVED — 17.** The 53 figure does not reproduce. My brief to four agents propagated the error |
| CF-03 | "`g1-q9` and `g1-q10` contain **56 rows** … per-table row counts + Edge Function source inventory" (relayed into S2-EXEC-05 §3.2, S2-EXEC-04 brief, and subagent 3/4 briefs) | "measured 47 / 17 / 20; UNVERIFIED — not reproducible" | Parsed directly: `g1-q9` = `{source, findings}` with **5 findings**; `g1-q10` = `{schema_usage, functions}` with **14 function rows**. Total **19 rows**, not 56 | **RESOLVED — 19 rows.** And **both descriptions of the content are wrong** — see CF-04 |
| CF-04 | q9 = "per-table row counts"; q10 = "Edge Function source inventory" | — | `g1-q9.source.endpoint` = **"dashboard Advisor page (Security Advisor) for project `hhqgreaoqulmfwfwarhc`"**; its 5 findings are `auth_leaked_password_protection`, `auth_rls_initplan`, `rls_enabled_no_policy`, `unindexed_foreign_keys`, `unused_index`. `g1-q10.functions[0]` fields = `function_name, arguments, owner, security_definer, settings, anon_exec, auth_exec, service_exec, extension_owned, acl` | **RESOLVED — mischaracterised.** q9 is a **production Security Advisor lint capture**; q10 is the **14-row `public` function inventory**. Neither is per-table data, neither is Edge Function source |
| CF-05 | `100-file-hashes.txt` is a "22-file hash list" | "20 entries" | `grep -c ""` = **20** lines; the directory holds **22** files | **RESOLVED — 20 entries over 22 files.** Two files are unlisted, which corroborates the secret-scan scope finding (see CF-13) |
| CF-06 | "**24 `private` function bodies** absent" — `90-limitations.md:126` (L-2), [00:180](00-stage2-execution-plan.md#L180), [04:76 R-18](04-risks-rollback-approvals.md#L76), [S2-EXEC-02:145](S2-EXEC-02-owner-decision-resolution.md#L145), README, `approval-package-v2:189`, **and S2-EXEC-05 §7 / the architecture brief §6 H-2** | "12 public + 12 private" (both function auditors) | `g1-b3b`: `inventory` = 38 rows (14 `public` + 24 `private`); `bodies` = 14 rows, `Counter(schema_name)` = **12 private + 2 public**. Absent = 38 − 14, split **12 public + 12 private** | **RESOLVED — count right, composition wrong.** Materially: half the absent bodies are `public` RPC surfaces, not internal helpers. Correct split already exists at [03-data-model.md:124](../stage1/03-data-model.md#L124) |
| CF-07 | MAINTAIN "19" vs "38" | — | 38 = **privilege triples** (19 tables × `postgres` + `service_role`); 19 = **tables**. Both auditors measured the same population with different units | **RESOLVED — unit clarification, not a count error.** Use "38 triples across 19 tables" |
| CF-08 | "0 executable function/trigger/policy/publication statements" | challenged as possibly wrong | Three independent counts agree: active `CREATE FUNCTION`/`TRIGGER`/`POLICY`/`PUBLICATION` = 0; the 6/22/66/12 raw hits are all comment lines | **RESOLVED — claim stands** |
| CF-09 | 459 active statements | re-measured twice by different parsers | Structural auditor: 00=2, 10=19, 20=137, 30=34, 40=0, 50=0, 55=0, 60=19, 70=248, 80=0 → **459**; assembled file = 459 and is the exact ordered concatenation. Cross-check auditor: class sum 2+19+137+34+19+52+183+13 = **459**. Coverage auditor: agrees | **RESOLVED — AGREEMENT (3 independent methods)** |
| CF-10 | "19 credential patterns + 3 PII classes" (`90-limitations.md:145`) | "16 credential + 3 row-data" | `scan_phase34.py:40-58` read directly: 19 patterns total, of which HARD_CRED=12 | **RESOLVED — the report overstates the credential class count** |
| CF-11 | Patch files are 191 / 155 / 127 **bytes** ([S2-EXEC-03 §6](S2-EXEC-03-documentation-reconciliation-report.md#L162) — a table I authored) | line counts | `wc -l -c`: 191 lines / **9,232 B**, 155 / **9,534 B**, 127 / **5,511 B** | **RESOLVED — my own published column header is wrong.** The three digests themselves are correct and unchanged: `1edad404…`, `01403cd7…`, `8f92cc0f…`. Also the path is `docs/stage2/patches/`; there is no `D:\control\patches\` |
| CF-12 | "Zero of the **four** physical signature fences is filled" ([README:19](README.md#L19) — wording I introduced) | 8 fences in v2 alone | `grep -c "______"` on approval-package-v2 = **8** lines (74 runs repo-wide over 14 lines). The count of *unfilled* fences is not four | **RESOLVED — "zero filled" is true; "four" is a wrong count.** Also [S2-EXEC-01:87](evidence/S2-EXEC-01-phase0-readiness.md) cites eight v2 line numbers that are all stale |
| CF-13 | Secret scan "covered the artefact" | 13 of 22 files | `scan_phase34.py:35,89-90` scope = `^\d+.*\.sql$` + assembled + `92` + `94` | **RESOLVED — scope gap confirmed.** `90`, `91`, `93`, `95`, `96`, `100-file-hashes.txt` and all three scripts were never scanned |
| CF-14 | The scan is tied to the artefact digest | digest basis differs | `sha256sum g3-reconstruction-2026-11-02.sql` = `fc996f45…`; `95-secret-scan.md` records `efdbf985…` (CRLF→LF normalised). The scan auditor reproduced all 13 normalised digests and 13 char counts against today's files — **content identity holds**; `100-file-hashes.txt` uses the byte basis and no document declares the normalisation | **RESOLVED as consistency, UNRESOLVED as binding:** same bytes, different basis, undocumented. Classify the *binding* `NOT VERIFIED` (offline-closable by re-hashing on the byte basis) |
| CF-15 | "the G3 secret scan report … is timestamped" ([S2-EXEC-03:219](S2-EXEC-03-documentation-reconciliation-report.md#L219) — my line) | `95-secret-scan.md:8` says it is "not a UTC-stamped platform record" | Read both | **RESOLVED — my claim is wrong.** The scan carries a local run stamp only |
| CF-16 | R-13's arithmetic: "11 uncaptured private or 12 uncaptured public" = 23 ([04:71](04-risks-rollback-approvals.md#L71)) | measured 24 | 12 + 12 = 24; 14 + 24 = 38 | **RESOLVED — 23 is wrong; and it is wrong in the same way as CF-06** |
| CF-17 | "the 25-row inventory" (`96-review-checks.md:36`) | 38 rows | `g1-b3b.inventory` = 38 | **RESOLVED — 25 is wrong** |
| CF-18 | "`create_edge_api_token` body sits at `g1-b3b:149/155/159/165`" — [parts/D:213](parts/D-e3-f7-e1.md), parts/E:214, parts/I:168, with lineage into README and CHANGELOG | — | `grep` for the name in `g1-b3b`, `g1-q7`, `g1-q10`: **absent**. Those lines hold `request_device_recovery`, `request_remote_session`, `unlink_child` bodies. `patch-defects:143-152` names them correctly | **RESOLVED — the cited evidence does not exist.** This is an unsupported claim naming non-existent evidence, not a wording slip |
| CF-19 | "0 leaked executable fragments" (`94-validation.md`) | "6 markers in commented lines" | Structural auditor's re-read: 0 in **active** statements, 6 inside commented text | **RESOLVED — true but scope-unlabelled.** The claim must say "in active statements" |
| CF-20 | "42 of 48 checks PASS" | "40 unconditional + 2 scope-qualified + 6 blocked" | Arithmetic agrees; checks 6 and 20 are overstated in scope | **RESOLVED — count agrees, scope needs labelling** |
| CF-21 | Extensions / publication / views / sequences expected counts | — | No `pg_extension`, `pg_publication`, view or sequence query exists in the G1 series | **CONFIRMED UNKNOWN — blind spot, not an empty set.** No agent closed it |

## 2. Genuine conflicts the evidence does NOT resolve

| # | Conflict | Both positions | Why it stays open |
| --- | --- | --- | --- |
| **CU-01** | **Return types: 0/38 vs 14/38** | (a) `91-coverage.md:17` and both function auditors: **no raw catalogue capture selects `prorettype`** — 0/38 from `g1-b3b`/`g1-q7`/`g1-q10`. (b) Coverage auditor + my own read: [functions-and-triggers.md:34-49](../stage1/evidence/functions-and-triggers.md) has a populated **`Returns`** column for the 14 `public` functions (jsonb / integer / row types), and `g1-run-manifest:59` admits that file as evidence | The two claims are about **different evidence classes**: machine capture vs dashboard narrative. The artefact's error is separate: it **never cites the narrative file at all** (0 occurrences), so it under-scoped its own ceiling. Neither auditor will upgrade the narrative to `SOURCE VERIFIED`, and I have not. **Retain `CONFLICT — SOURCE DISAGREEMENT`.** Consequence differs by resolution: even at 14/38 return types, 24 `private` bodies are still absent, so the load stays blocked — the dispute changes the *label*, not the verdict |
| **CU-02** | **Are the 14 public functions' owner / `search_path` / language attributable?** | (a) Artefact: owner `INFERRED` from ACL grantor, language/volatility "unattributable" because `g1-q7` has no schema column ([S2-EXEC-03 §3.2](S2-EXEC-03-documentation-reconciliation-report.md)). (b) `g1-q10.functions`: **all 14 rows carry `owner: postgres` and non-empty `settings` (`search_path=public, private, pg_temp…`)**, plus `security_definer`, `extension_owned` and per-role exec flags | `g1-q10` is public-schema only, so it resolves the question **for those 14** and not for the 24 `private`. The auditors' own disagreement is that one treated q7↔q10↔b3b as set-identical (therefore attributable) while the artefact blanked it. **Partly resolvable: the 14 public rows ARE evidenced for owner and search_path — the artefact under-claimed.** For `private`, unresolved |
| **CU-03** | Whether 4 policies are **emittable** offline | Structural auditor: `families_update_owner`, `profiles_update_self`, both `webrtc_signals` predicates need only `auth.uid()` → over-blocked, authoring-ready. Coverage auditor: policies are blocked on section 40 as a class | True on the reading of the captured predicates — no `private.*` helper appears in those four. But emitting them is an **artefact change**, which this phase forbids and which also interacts with the Firebase-UID migration (subagent 1 never ran). **Kept as a finding, not an action** |
| **CU-04** | Whether the production Security Advisor capture in `g1-q9` is **in-scope evidence** under the staging-only absolute | It is pre-existing Stage 1 evidence already in the repo, captured 2026-10-29 read-only | R-43/C2b bars *accessing* production; it does not retroactively debar a file already captured. But no approval governs using its `rls_enabled_no_policy` INFO finding as schema evidence. **Owner call, not an auditor call** |

## 3. Duplicate findings (same fact, several auditors)

Statement count 459 (×3); 0 behavioural statements (×3); 25 of 29 dependents blocked and 4 over-blocked (×2,
independently); 0 of 24 absent bodies recoverable from in-repo evidence (×2); 13/22 scan scope (×2); digest-basis mismatch
(×2); ratification grants nothing forward and zero fences filled (×5). Duplicates are **not** independent confirmation —
several share the same underlying files.

## 4. Reports that never arrived (counted as PENDING, not as pass)

| Phase | Agent | Outcome |
| --- | --- | --- |
| S2-EXEC-04 | identity/hash | `S2-EXEC-04-evidence-and-hash-manifest.md` written (988 lines), then the agent died on the credit limit; **its two headline figures are false (CF-02, CF-03, CF-05)** |
| S2-EXEC-04 | coverage | `…-object-coverage-matrix.md` (478 lines) — COMPLETE; source of CF-01/CF-06/CU-01 |
| S2-EXEC-04 | functions | `…-function-coverage-register.md` (346 lines) — COMPLETE |
| S2-EXEC-04 | SQL structure | `…-sql-structural-findings.md` (134 lines) — COMPLETE |
| S2-EXEC-04 | A3 preconditions | `…-a3-precondition-matrix.md` (362 lines) — COMPLETE |
| S2-EXEC-04 | secret scan | **No file by design**; findings in its reply — incorporated |
| S2-EXEC-04 | cross-check | **No file by design**; findings in its reply — incorporated, and it is the source of CF-16…CF-18, CF-12 |
| S2-EXEC-05 | evidence inventory | `S2-EXEC-05-complete-stage1-evidence-inventory.md` (350 lines) written before failure — COMPLETE |
| S2-EXEC-05 | final manifest | `S2-EXEC-05-final-evidence-manifest.md` (528 lines) written before failure — COMPLETE |
| S2-EXEC-05 | function register | `S2-EXEC-05-function-body-coverage-register.md` (225 lines) — COMPLETE |
| S2-EXEC-05 | A3 readiness | `S2-EXEC-05-a3-readiness-assessment.md` (403 lines) — COMPLETE |
| S2-EXEC-05 | **coverage matrix** | **NOT WRITTEN** — the agent's last message was "Now writing the deliverable"; `ls` confirms the file is absent. `PENDING` |
| S2-EXEC-05 | **SQL integrity** | **NOT WRITTEN** (queue failure). `PENDING` |
| S2-EXEC-05 | **conflict register** | **NOT WRITTEN** (queue failure) — this file substitutes for it, authored by the main agent |
| S2-EXEC-05 | **recovery hunt** | **NOT WRITTEN** (queue failure). `PENDING` |
| Architecture | **all 8 subagents** | **0 deliverables written**; every one failed on the credit limit (`S2-A1`…`S2-A6` absent, `S2-EXEC-FINAL.md` absent) |

## 5. What I changed in the audited artefact

Nothing. `gen_g3.py`, the 11 `.sql` files, the three patches and every authoritative Stage 2 document are byte-identical
to the state recorded before this audit began; the digests are in `S2-EXEC-05-final-evidence-manifest.md` and were
re-confirmed here. No SQL was executed, no dashboard was opened by the main agent, no secret was read, printed or
created, and no approval block was filled.

**Corrections required in the plan of record (NOT applied here — S2-EXEC-05 §11 and the architecture brief §6 forbid
editing it in this phase): CF-06, CF-11, CF-12, CF-15, CF-16, CF-17, CF-18, CF-19, CF-20, CF-01's "missing files" claim.**
The architecture brief's own §6 H-2 inherits CF-06 ("24 private function bodies are missing") and CF-01-adjacent wording,
so the brief text itself needs the same correction before it is used as an instruction.
