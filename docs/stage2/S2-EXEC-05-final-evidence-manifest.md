# S2-EXEC-05 - Final Evidence Manifest (chain of custody register)

**Document ID:** `S2-EXEC-05` · **Programme:** governance/documentation, Stage 2 · **Class:** offline audit register
**Session date of measurement:** 2026-11-03 (local). **Method:** read-only filesystem measurement. `os.stat` byte length, newline count, and SHA-256 over the exact byte stream, computed in this session.
**Scope:** the evidence chain that `g3-build/92-provenance-manifest.md` and the Stage 2 audits depend on. Object coverage, SQL structure, function semantics and approval analysis are explicitly **out of scope** and are not judged here.

> **Integrity note.** Every SHA-256 in this file was computed by this session. No digest was copied from another document and presented as a measurement. Where a value could not be measured it reads `NOT AVAILABLE`.

---

## 0. Headline: the artifact is not in custody

Before any per-file register, one structural fact dominates this manifest.

| Fact | Measurement |
| --- | --- |
| Location of the G3 artifact and all its components | `C:/Users/ASUS/.qoder/tmp/D--control/g3-build` - a **volatile per-user session temp directory**, outside the repository |
| Copies of `g3-reconstruction-2026-11-02.sql` inside `D:/control` | **0** (verified by recursive name search of the repo) |
| Copies of the numbered SQL components inside `D:/control` | **0** |
| Total files in the repository excluding `.git/` | **83** |
| Repository commits | **0** (`git log` -> `fatal: your current branch 'master' does not have any commits yet`; `git count-objects -v` -> `count: 0, size: 0, in-pack: 0`; `.git/logs/HEAD` does not exist; `.git/refs/heads/` is empty) |

**Consequence.** The 494319 bytes of G3 evidence that A3 (load) and A5 (patch application) are gated on live on a single copy, in a directory the operating system is free to reclaim, with no version-control object behind it. There is no second witness to any digest in this manifest. Section 6 develops this.

---

## 1. Register A - G3 build directory (`g3-build/`)

Directory: `C:/Users/ASUS/.qoder/tmp/D--control/g3-build`

**Declared count in the tasking was 22. Verified count: 22 files.** The declared figure is correct. Filesystem mtimes **are** available (NTFS, reported to 100 ns) and are recorded below.

| # | File | Bytes | Lines | SHA-256 (computed this session) | mtime (local) | Role | Repo entry set? | In `100-file-hashes.txt`? |
| ---: | --- | ---: | ---: | --- | --- | --- | --- | --- |
| 1 | `00-platform-assumptions.sql` | 3,980 | 47 | `42c019cf23d7dee7...a770a37c` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 2 | `10-tables.sql` | 12,124 | 281 | `16bb23871ce9e57c...6b3fd06b` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 3 | `100-file-hashes.txt` | 1,724 | 20 | `532901382bc857da...07f634ce` | 2026-11-02 17:14:05 | digest list | YES - report | **NO - uncovered** |
| 4 | `20-constraints.sql` | 20,729 | 164 | `892f7c961503c5bb...e45881b3` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 5 | `30-indexes.sql` | 8,668 | 82 | `4391eb9242e65743...71fdead8` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 6 | `40-functions.sql` | 55,150 | 865 | `599f038f85521623...c93a69ef` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 7 | `50-triggers.sql` | 3,284 | 39 | `d4615bdaae9aa757...02f9ac8e` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 8 | `55-auth-users-trigger.sql` | 1,876 | 22 | `6484dbd0c436faae...b96d8d7d` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 9 | `60-rls-policies.sql` | 8,140 | 78 | `4c843ad9a1da49a7...cc00acc8` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 10 | `70-grants-default-privileges.sql` | 35,973 | 361 | `6d64b667f1353675...eafe2102` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 11 | `80-realtime-publication.sql` | 2,089 | 24 | `53d2b17a75907cd0...820bb1e5` | 2026-11-02 17:12:21 | SQL component | YES - artifact/component | YES |
| 12 | `90-limitations.md` | 13,065 | 185 | `fcd7686b253184ed...a63c18d6` | 2026-11-02 17:13:58 | report | YES - report | YES |
| 13 | `91-coverage.md` | 8,053 | 47 | `6202cd931ea68453...ee87f721` | 2026-11-02 17:12:22 | report | YES - report | YES |
| 14 | `92-provenance-manifest.md` | 59,442 | 521 | `5ecc9557f844b1f3...4f6ce77a` | 2026-11-02 17:12:21 | report (provenance manifest) | YES - report | YES |
| 15 | `93-counts.json` | 1,460 | 44 | `4fadc2a0c92a9d23...f46505e8` | 2026-11-02 17:12:21 | report (machine counts) | YES - report | YES |
| 16 | `94-validation.md` | 1,761 | 44 | `288d475e1952aeec...5fa1904a` | 2026-11-02 17:12:21 | report | YES - report | YES |
| 17 | `95-secret-scan.md` | 3,970 | 60 | `46b709443cbe94b7...cadd43aa` | 2026-11-02 17:12:22 | report (secret scan) | YES - report | YES |
| 18 | `96-review-checks.md` | 12,953 | 80 | `cb69cafd355ed5be...e267e27e` | 2026-11-02 17:12:22 | report (review checks) | YES - report | YES |
| 19 | `g3-reconstruction-2026-11-02.sql` | 150,566 | 1951 | `fc996f450690d8b6...d1d908f6` | 2026-11-02 17:12:21 | assembled artifact | YES - artifact/component | YES |
| 20 | `gen_g3.py` | 34,567 | 513 | `8d3aa760fcaa9a20...e5044e4b` | 2026-11-02 17:12:15 | source generator | YES - build tooling (tools/ subdir) | YES |
| 21 | `gen_scan.py` | 13,970 | 205 | `d550ab33ff777293...139f175b` | 2026-11-02 16:18:42 | source generator | YES - build tooling (tools/ subdir) | **NO - uncovered** |
| 22 | `scan_phase34.py` | 40,775 | 621 | `c1a9d1c7c0b4ffa5...bfb0ea09` | 2026-11-02 17:08:44 | scan script | YES - build tooling (tools/ subdir) | YES |

### 1.1 Digest comparison against `100-file-hashes.txt`

`100-file-hashes.txt` carries **20** entries (its own name is a misnomer - there is no 100th file). Both values are shown for every entry.

| File | Digest in `100-file-hashes.txt` | Digest computed this session | Result |
| --- | --- | --- | --- |
| `00-platform-assumptions.sql` | `42c019cf23d7dee790fdae7ceaa4d84d612daf296a6ff588772feee7a770a37c` | `42c019cf23d7dee790fdae7ceaa4d84d612daf296a6ff588772feee7a770a37c` | **MATCH** |
| `10-tables.sql` | `16bb23871ce9e57c58d65f0753fa12e7a27d6c60699d55333f03ba1a6b3fd06b` | `16bb23871ce9e57c58d65f0753fa12e7a27d6c60699d55333f03ba1a6b3fd06b` | **MATCH** |
| `20-constraints.sql` | `892f7c961503c5bb90d27022735b4b4469f81ff4c7b06bd81f067c3de45881b3` | `892f7c961503c5bb90d27022735b4b4469f81ff4c7b06bd81f067c3de45881b3` | **MATCH** |
| `30-indexes.sql` | `4391eb9242e6574316730fe99bec2a8ee7c1009ba69283879a69b53b71fdead8` | `4391eb9242e6574316730fe99bec2a8ee7c1009ba69283879a69b53b71fdead8` | **MATCH** |
| `40-functions.sql` | `599f038f85521623ef52ed7f72e1771092d69e9f755483075799a87bc93a69ef` | `599f038f85521623ef52ed7f72e1771092d69e9f755483075799a87bc93a69ef` | **MATCH** |
| `50-triggers.sql` | `d4615bdaae9aa7574b0ead517bbc6450677d94af96615917a156af6e02f9ac8e` | `d4615bdaae9aa7574b0ead517bbc6450677d94af96615917a156af6e02f9ac8e` | **MATCH** |
| `55-auth-users-trigger.sql` | `6484dbd0c436faae3adedccd676dbe0a73acdead4018601f541f51d2b96d8d7d` | `6484dbd0c436faae3adedccd676dbe0a73acdead4018601f541f51d2b96d8d7d` | **MATCH** |
| `60-rls-policies.sql` | `4c843ad9a1da49a7bcf75a8d7ceecd40cc3b28fa539c92b632d81cbacc00acc8` | `4c843ad9a1da49a7bcf75a8d7ceecd40cc3b28fa539c92b632d81cbacc00acc8` | **MATCH** |
| `70-grants-default-privileges.sql` | `6d64b667f1353675603e7302ef223df1b18df1e4d71b130e9990aee0eafe2102` | `6d64b667f1353675603e7302ef223df1b18df1e4d71b130e9990aee0eafe2102` | **MATCH** |
| `80-realtime-publication.sql` | `53d2b17a75907cd09febf7c072f751cad2f89210b5578685f598c499820bb1e5` | `53d2b17a75907cd09febf7c072f751cad2f89210b5578685f598c499820bb1e5` | **MATCH** |
| `90-limitations.md` | `fcd7686b253184ed134283e8287714ed9391926941d2d6fa12e4172da63c18d6` | `fcd7686b253184ed134283e8287714ed9391926941d2d6fa12e4172da63c18d6` | **MATCH** |
| `91-coverage.md` | `6202cd931ea68453a0124e0592eaac5ee1f7a29d325df2680ed4cd95ee87f721` | `6202cd931ea68453a0124e0592eaac5ee1f7a29d325df2680ed4cd95ee87f721` | **MATCH** |
| `92-provenance-manifest.md` | `5ecc9557f844b1f35553a579310b3d2bbae1aea5afcff73f7b7420464f6ce77a` | `5ecc9557f844b1f35553a579310b3d2bbae1aea5afcff73f7b7420464f6ce77a` | **MATCH** |
| `93-counts.json` | `4fadc2a0c92a9d23000fbcbed35b5bf5eb52305ef8aaa73f463e905ff46505e8` | `4fadc2a0c92a9d23000fbcbed35b5bf5eb52305ef8aaa73f463e905ff46505e8` | **MATCH** |
| `94-validation.md` | `288d475e1952aeecde6257302e09f65e3a20a6b0ca06186843d25b765fa1904a` | `288d475e1952aeecde6257302e09f65e3a20a6b0ca06186843d25b765fa1904a` | **MATCH** |
| `95-secret-scan.md` | `46b709443cbe94b7e8f911c163a7c8d9ee89c8ea09f7f93776666356cadd43aa` | `46b709443cbe94b7e8f911c163a7c8d9ee89c8ea09f7f93776666356cadd43aa` | **MATCH** |
| `96-review-checks.md` | `cb69cafd355ed5be07635c5b557c5fe32c65b1c66806f68fe40b623de267e27e` | `cb69cafd355ed5be07635c5b557c5fe32c65b1c66806f68fe40b623de267e27e` | **MATCH** |
| `g3-reconstruction-2026-11-02.sql` | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` | **MATCH** |
| `gen_g3.py` | `8d3aa760fcaa9a206e1b5932cdb2adab4810ad7b85c5f3d338de6b27e5044e4b` | `8d3aa760fcaa9a206e1b5932cdb2adab4810ad7b85c5f3d338de6b27e5044e4b` | **MATCH** |
| `scan_phase34.py` | `c1a9d1c7c0b4ffa5191dfc0300e964ab01425f65fa2220541a1e688dbfb0ea09` | `c1a9d1c7c0b4ffa5191dfc0300e964ab01425f65fa2220541a1e688dbfb0ea09` | **MATCH** |

**Verdict: 20 of 20 recorded digests MATCH. 0 MISMATCH.**

**Files present but NOT covered by the digest list (2):** `100-file-hashes.txt`, `gen_scan.py`

- `100-file-hashes.txt` does not hash itself - unavoidable for a self-referential list, but it means the list has no external anchor. Its mtime (2026-11-02 17:14:05) is the newest object in the directory, consistent with "generated last".
- `gen_scan.py` is a generator script that no digest list and no scan covers. It is the only registered file with zero integrity attestation of any kind.

### 1.2 Line-count caveat

`wc -l` above counts newline bytes. 1 files have no final newline, so their newline count under-reports the logical line count by one: `93-counts.json`

---

## 2. Register B - Stage 1 evidence cited by the G3 artifact

Directory: `D:/control/docs/stage1/evidence`

| File | Bytes | Lines | SHA-256 (this session) | JSON top-level shape | Measured row count | Cited by 92/91/90? | Citation resolves? |
| --- | ---: | ---: | --- | --- | --- | --- | --- |
| `edge-functions/capture-20261030.json` | 14,118 | 178 | `95ebe57cf6d0aa06...6a39ce33` | object | functions=9 | **PRESENT, NEVER CITED** | not cited, so N/A |
| `functions-and-triggers.md` | 10,865 | 120 | `835f7660315068b8...3b7b3ed0` | n/a (markdown) | n/a | **PRESENT, NEVER CITED** | not cited, so N/A |
| `g1-b3b-20261029.json` | 26,316 | 177 | `72f0e1de49b491e4...79be3d30` | object | inventory.rows=38, bodies=14 | CITED | YES - by naming convention (see 2.1) |
| `g1-q1-20261029.json` | 3,398 | 0 | `71e26bd255b6024f...42e597a6` | object | 19 | CITED | YES - by naming convention (see 2.1) |
| `g1-q10-20261029.json` | 4,694 | 0 | `54e4c2eed5691cc5...7fd395f6` | object | functions=14 | **PRESENT, NEVER CITED** | not cited, so N/A |
| `g1-q2-20261029.json` | 5,728 | 0 | `3e60d28125ec07f8...3e6bc497` | object | 21 | CITED | YES - by naming convention (see 2.1) |
| `g1-q3-20261029.json` | 2,162 | 0 | `826bb981219f79b9...7209ce6e` | object | 7 | CITED | YES - by naming convention (see 2.1) |
| `g1-q3b-20261029.json` | 382 | 0 | `753a173a0b8d17ea...3e10f868` | object | 1 | CITED | YES - by naming convention (see 2.1) |
| `g1-q4-20261029.json` | 11,587 | 0 | `a818188dd686c41f...8ea88500` | object | 62 | CITED | YES - by naming convention (see 2.1) |
| `g1-q5-20261029.json` | 31,574 | 0 | `6cd58d28aa168d63...6716b029` | object | 137 | CITED | YES - by naming convention (see 2.1) |
| `g1-q6-20261029.json` | 41,706 | 0 | `bce8d2831ff9461c...5e1774cc` | object | table_grants=149 | CITED | YES - by naming convention (see 2.1) |
| `g1-q7-20261029.json` | 5,040 | 0 | `58b6d622f6d4a3e1...c2976b7c` | object | 18 | CITED | YES - by naming convention (see 2.1) |
| `g1-q8-20261029.json` | 26,981 | 0 | `62aadcf215080848...fc0e19be` | object | 183 | CITED | YES - by naming convention (see 2.1) |
| `g1-q9-20261029.json` | 4,370 | 93 | `0228925b393afc8d...a6332c56` | object | findings=5 | **PRESENT, NEVER CITED** | not cited, so N/A |
| `g1-run-manifest-20261029.md` | 6,456 | 72 | `3ae29f0d729ed49b...2f97a059` | n/a (markdown) | n/a | CITED | YES - by naming convention (see 2.1) |
| `g2-apk-identity-20261030.md` | 4,778 | 64 | `63ccb7ecfb1381c0...2e7fa2e7` | n/a (markdown) | n/a | **PRESENT, NEVER CITED** | not cited, so N/A |
| `schema-columns.md` | 11,964 | 297 | `5445c69ae2948e94...a8716fa1` | n/a (markdown) | n/a | **PRESENT, NEVER CITED** | not cited, so N/A |

**Totals: 17 evidence files, 212,119 bytes, 1001 lines.** One additional entry is a directory, not a file: `edge-functions/pairing/` is **empty** (0 files, no digest taken; registered as an empty custody slot).

### 2.1 How citations actually resolve (material finding)

`92-provenance-manifest.md`, `91-coverage.md` and `90-limitations.md` contain **no filesystem path and no filename with an extension** for any Stage 1 evidence item. There is not one occurrence of `docs/stage1/`, `evidence/`, or a relative path in the three files. Evidence is named only by a bare token in a `Source` column:

`g1-q1`, `g1-q2`, `g1-q3`, `g1-q3b`, `g1-q4`, `g1-q5`, `g1-q6`, `g1-q7`, `g1-q8`, `g1-b3b`, `g1-run-manifest` - **11 distinct tokens**, occurring 473 times in total (e.g. `g1-q8` x185, `g1-q5` x139, `g1-q4` x63, `g1-b3b` x45).

Each token resolves to a real file only by an **undocumented naming convention** (token + `-20261029` + extension). No manifest or index file in `g3-build/` states that mapping. A verifier cannot machine-check a single citation without first guessing the convention. Classification for every resolvable citation is therefore `CONVENTIONAL`, not `PATH-RESOLVED`. This is the weakest link in the chain after the missing repo copy.

### 2.2 The two files reported missing are NOT missing

| Reported | Actual state measured this session |
| --- | --- |
| `schema-columns.md` "missing" | **PRESENT** - `docs/stage1/evidence/schema-columns.md` (11,964 bytes, 297 lines, SHA-256 `5445c69ae2948e9473e0a88a936d4f20cecb7528ffb614528319fb57a8716fa1`)
| `functions-and-triggers.md` "missing" | **PRESENT** - `docs/stage1/evidence/functions-and-triggers.md` (10,865 bytes, 120 lines, SHA-256 `835f7660315068b843431f0a32d3874aa8088823c042483fbbdc1b213b7b3ed0`)

The earlier "reported missing" finding is **refuted**. Both files exist and are byte-stable. What is actually true is narrower and different: neither is cited by filename or token anywhere in `g3-build/` (verified by grep over all 22 files). `functions-and-triggers.md` **is** cited from the Stage 2 side - `S2-EXEC-02` `:142` points at it for the 24 absent bodies. So the defect is *uncited by the artifact*, not *absent*. Recording them as missing would have created a false re-capture obligation.

### 2.3 Present-but-never-cited evidence (UNUSED EVIDENCE)

Six of the 17 evidence files exist but are never referenced by `92`, `91` or `90`:

| File | Bytes | SHA-256 (this session) | Content measured | Status |
| --- | ---: | --- | --- | --- |
| `edge-functions/capture-20261030.json` | 14,118 | `95ebe57cf6d0aa06...6a39ce33` | object `{capture, functions, shared, repository}`; functions = 9 | UNUSED EVIDENCE |
| `functions-and-triggers.md` | 10,865 | `835f7660315068b8...3b7b3ed0` | function/trigger listing, 120 lines (markdown) | UNUSED EVIDENCE |
| `g1-q10-20261029.json` | 4,694 | `54e4c2eed5691cc5...7fd395f6` | object `{schema_usage, functions}`; functions = 14 | UNUSED EVIDENCE |
| `g1-q9-20261029.json` | 4,370 | `0228925b393afc8d...a6332c56` | object `{source, findings}`; findings = 5 | UNUSED EVIDENCE |
| `g2-apk-identity-20261030.md` | 4,778 | `63ccb7ecfb1381c0...2e7fa2e7` | APK identity note (markdown) | UNUSED EVIDENCE |
| `schema-columns.md` | 11,964 | `5445c69ae2948e94...a8716fa1` | column listing, 297 lines (markdown) | UNUSED EVIDENCE |

`g1-q10` is mentioned **once** in the whole build directory, and only inside `scan_phase34.py` (a script), never in a report. `g1-q9`, `g2-apk-identity-20261030.md`, `capture-20261030.json` appear in **zero** files under `g3-build/`.

### 2.4 Cited-but-absent

**0.** Every one of the 11 cited tokens resolves to an existing file. There is no dangling citation of a missing evidence file in the Stage 1 direction. (`91-coverage.md` does report internal evidence *gaps* - the 24 absent function bodies, unknown extension/view/sequence coverage - but those are absent *data inside* captured files, not absent files.)

### 2.5 Row-count reconciliation (measured vs asserted)

`93-counts.json` publishes an `expected` block and `91-coverage.md` asserts an "Expected (from source)" column. This session counted the JSON arrays directly:

| Object | Asserted (91 / 93) | Measured this session | Result |
| --- | ---: | ---: | --- |
| Tables | 19 / 19 | `g1-q1` top array = 19 | **AGREES** |
| Columns | 183 / 183 | `g1-q8` top array = 183 | **AGREES** |
| Constraints | 137 / 137 | `g1-q5` top array = 137 | **AGREES** |
| Indexes | 62 / 62 | `g1-q4` top array = 62 | **AGREES** |
| Policies | 21 / 21 | `g1-q2` top array = 21 | **AGREES** |
| Triggers (public) | 7 | `g1-q3` top array = 7 | **AGREES** |
| Trigger (auth.users) | 1 | `g1-q3b` top array = 1 | **AGREES** |
| Function inventory | 38 / 38 | `g1-b3b` `inventory.rows` = 38 | **AGREES** |
| Recovered bodies | 14 / 14 | `g1-b3b` `bodies` = 14 | **AGREES** |
| Table grants | 149 / 149 | `g1-q6` `table_grants` = 149 | **AGREES** |
| q7 attributability rows | 18 | `g1-q7` top array = 18 | **AGREES** |

All eleven independently checkable counts agree. This is the strongest part of the chain: `93-counts.json` is not fabricated. One inconsistency sits in `96-review-checks.md` check 20, which refers to a "25-row inventory" where `91`, `93` and this measurement all say 38. Flagged for the approval-analysis auditor; **not** adjudicated here.

---

## 3. Register C - Stage 2 authoritative documents

Directory: `D:/control/docs/stage2`

### 3.1 Root documents (18 files authored before this session)

| File | Bytes | Lines | SHA-256 (this session) | Recorded decision carried |
| --- | ---: | ---: | --- | --- |
| `00-stage2-execution-plan.md` | 35,878 | 352 | `591b9c2ba7c15e6a...aeacb22a` | Sequence A renumbered: shell -> ratification -> A0 -> capture -> reconstruct -> scan -> A3 load -> A2-prime(a) sentinel -> equivalence -> A5 -> G5. Status table rewritten (G6-a EXECUTED shell only). |
| `01-staging-project-proposal.md` | 22,862 | 289 | `06c01caeac43b816...6209cdcb` | Staging project provisioning proposal; S2-INSP-01 19-slot cap and naming constraints; contains operator-account identity. |
| `02-findings-to-fix-mapping.md` | 12,139 | 127 | `44feca812bd03188...bd09238d` | PROPOSED - NOT APPLIED mapping of Stage 1 findings to remediation. |
| `03-patch-S2-P01.md` | 20,009 | 271 | `afe285a174a5ba64...86811934` | Patch design record for E2/F8; still labelled PROPOSED, not applied. |
| `04-risks-rollback-approvals.md` | 61,377 | 428 | `6502b5f17ccfd709...49d561b0` | Risk register + rollback + approval blocks; 3.1 records A2 shell-only execution; signature fences blank. |
| `05-validation-plan.md` | 16,353 | 223 | `caed03f1350d9a07...7899f52c` | G5 validation plan; C-11 restates the unblock chain without A1 and with the A2-prime(a)/(b) split; G5-S/G5-E/G5-C gated. |
| `06-redteam-resolution.md` | 14,787 | 116 | `0503086d7486cc78...85c7b344` | Red-team disposition record. |
| `CHANGELOG.md` | 32,528 | 268 | `fa23cf3d22cdd358...8e996e5f` | Dated record of each pass. Carries the S2-DOC-01 pass heading (no standalone S2-DOC-01 file), the RATIFY (i) entry, A1 INOPERATIVE (C-2), A2-prime split (C-3), A0 APPROVED / A5 APPROVED-NOT-EXECUTABLE / A2-prime-A3-A9-A12 UNSIGNED / zero fences filled. |
| `README.md` | 17,658 | 141 | `4f5de3e9e2254fbc...f02a756b` | Master status index. Carries: A0 APPROVED (method amended to offline reconstruction), A5 APPROVED but NOT EXECUTABLE, A2-prime / A3 / A9 / A12 UNSIGNED, A1 INOPERATIVE, executed creation RATIFIED option (i), zero physical signature fences filled. |
| `S2-DOC-02-reconciliation.md` | 26,907 | 278 | `2dec904c84149084...ab114d5d` | Documentation reconciliation pass; re-records the three patch digests (matches this session). |
| `S2-EXEC-02-owner-decision-resolution.md` | 29,637 | 308 | `fb8194237b7ddf5f...526a3458` | AUTHORITATIVE owner decision record: RATIFY (i), Sequence A, FX-18 inside A3, staging-only absolute with A1 INOPERATIVE, seven approval statuses, B-16/B-17, corrections C-1...C-12. 6.3 = pre-correction patch digests. |
| `S2-EXEC-03-documentation-reconciliation-report.md` | 24,789 | 271 | `374a3ad09c3fd430...e3b89f57` | Reconciliation of the Stage 2 document set. 6 = patch integrity table confirming the 6.3 digests unchanged; 3 git status = zero commits. |
| `S2-EXEC-05-a3-readiness-assessment.md` | 61,727 | 403 | `97bb73e91186adf8...11e62a97` | (not enumerated in the tasking; registered for completeness) |
| `S2-EXEC-05-complete-stage1-evidence-inventory.md` | 35,049 | 350 | `f5ab7e46218e9af3...7e24a28c` | (not enumerated in the tasking; registered for completeness) |
| `S2-EXEC-05-function-body-coverage-register.md` | 41,889 | 225 | `515cdc3e5317642a...1e9fa9aa` | (not enumerated in the tasking; registered for completeness) |
| `S2-REVIEW-02-independent-audit.md` | 40,344 | 444 | `3db046718e7e44eb...3ffcaf3d` | Independent audit. P-5: SQL hashes/statuses PASS with a provenance limitation; quotes P01/P02/P03 digests abbreviated. |
| `S2-REVIEW-03-independent-audit.md` | 46,000 | 481 | `97dcd611338de77c...87baff5c` | Independent audit. CD-21 records the missing CHANGELOG entry for the creation pass. |
| `approval-package-a0-a2.md` | 12,432 | 188 | `767c18d2983087cf...b9afbc58` | Original A0/A2 approval package; superseded for A0 by the amended offline method; operator identity present; fences unsigned. |
| `approval-package-v2-ratification-and-forward.md` | 47,559 | 484 | `5e371b8406f1aaeb...56ecc90b` | 2. Ratification request -> recorded owner decision OPTION (i) RATIFY, A12 wording amended, grants no forward permission; seven forward blocks A0/A1/A2-prime/A3/A5/A9/A12. Every signature fence blank. |
| `patch-defects-before-a5.md` | 25,870 | 341 | `570487be2de7298a...b6137e2f` | D-01...D-12 (+D-10b) defect register; all OPEN; D-07 makes P02 abort as shipped. Eight defects require a patch-file revision, hence re-hashing. |

**Totals: 20 files, 625,794 bytes, 5988 lines.**

### 3.2 Requested documents that do NOT exist

| Requested file | State | Evidence |
| --- | --- | --- |
| `S2-DOC-01*.md` | **MISSING - referenced but no such file** | `CHANGELOG.md:134` carries a heading `## 2026-10-30 - S2-DOC-01: ...` and `CHANGELOG.md:83`, `S2-REVIEW-02:32`, `S2-REVIEW-02:206`, `S2-REVIEW-03:214` all refer to the "S2-DOC-01 pass". No standalone file exists; the pass lives only as CHANGELOG entries. |
| `S2-REVIEW-01*.md` | **MISSING - absent from the naming series** | Only `S2-REVIEW-02` and `S2-REVIEW-03` exist. No file, and no reference resolves to a file. A gap in the independent-audit series (01 -> 02, 03). |

### 3.3 Stage 2 evidence files (`evidence/`, 6 files, 85,750 bytes)

| File | Bytes | Lines | SHA-256 (this session) |
| --- | ---: | ---: | --- |
| `evidence/S2-CREATE-01-new-projects.md` | 12,466 | 196 | `cf1cbc15636232ff...bdda26ef` |
| `evidence/S2-EXEC-01-phase0-readiness.md` | 24,732 | 292 | `5bc3ac25032c8a75...28499af4` |
| `evidence/S2-INSP-01-supabase-org-slots.md` | 9,708 | 141 | `9ef9948fb6b20702...6eb00b64` |
| `evidence/S2-INSP-02-firebase-console.md` | 4,027 | 67 | `fe85c7e975f28edd...27e06af9` |
| `evidence/S2-INSP-03-read-only-reconfirmation.md` | 16,555 | 253 | `cdd6bd4b2e6e0ab4...a25ff429` |
| `evidence/S2-NEXT-01-readiness-report.md` | 18,262 | 255 | `5e4bed7b069476ce...11d5113d` |

### 3.4 Stage 2 parts (`parts/`, 10 files, 198,345 bytes) - supporting, registered for completeness

| File | Bytes | Lines | SHA-256 (this session) |
| --- | ---: | ---: | --- |
| `parts/A-staging-spec.md` | 21,926 | 217 | `1a9b28adb4947fdc...48e413c3` |
| `parts/B-g3-dashboard-baseline.md` | 19,545 | 216 | `307afaa3a3a5bc2e...869c77a6` |
| `parts/C-e2-f8.md` | 12,994 | 152 | `fa12b99f644514aa...f667e3e2` |
| `parts/D-e3-f7-e1.md` | 15,942 | 217 | `6e692011d275c999...7998b1fa` |
| `parts/E-e4-session-invariant.md` | 18,140 | 217 | `c38344b4ba3a50d2...4e7c25f5` |
| `parts/F-e6-e7.md` | 18,862 | 217 | `d67cffd426692e05...4c6ec46a` |
| `parts/G-g5-validation.md` | 20,778 | 239 | `499f1afb77670448...63044d69` |
| `parts/H-app-preservation.md` | 17,351 | 197 | `9cd6c3e42ef30c6e...4aa196d6` |
| `parts/I-risks-rollback-approvals.md` | 25,582 | 170 | `5cf59a71191367d5...dacb9444` |
| `parts/J-redteam.md` | 27,225 | 195 | `d6c33808262d4736...04337065` |

### 3.5 Concurrent auditor files - EXCLUDED, listed as PENDING

Three files appeared in `docs/stage2/` **during this session** (mtimes 2026-11-03 09:15-09:16, i.e. after my first directory listing at 09:0x). They belong to other auditors. They were **not** opened for adjudication, **not** modified, and are **not** folded into the Stage 2 register totals above. Because they were written while I measured, **every digest in this manifest is a point-in-time snapshot and the tree is not quiescent.**

| File | Size | SHA-256 (measured 09:2x, may already be stale) | Status |
| --- | ---: | --- | --- |
| `S2-EXEC-04-a3-precondition-matrix.md` | 61,854 | `781befafcbd7aa8ce15580aeb685073bcb9c3d21ab16b5dba9821acb16a5eafb` | **PENDING - concurrent author, out of my domain** |
| `S2-EXEC-04-object-coverage-matrix.md` | 38,865 | `b154acced364ea97a84366e39de13364a5eac66c41d018df7aef274f3abc4581` | **PENDING - concurrent author, out of my domain** |
| `S2-EXEC-04-sql-structural-findings.md` | 28,282 | `edbd8986306a2c9212de18a962dd9a914b4de13041b2de379141c66ba02f90fc` | **PENDING - concurrent author, out of my domain** |

No `S2-EXEC-04-*` file is referenced by any pre-existing Stage 2 document, so no citation currently depends on them.

---

## 4. Register D - the three patch files

**Path correction.** The tasking cited `D:/control/patches/`. That directory **does not exist**. The patches are at `D:/control/docs/stage2/patches/`. Any future runbook that issues `sha256sum D:/control/patches/*.sql` will fail. The exact filenames as they exist on disk:

| Exact filename | Bytes | Lines | SHA-256 computed this session | SHA-256 recorded in S2-EXEC-02 6.3 **and** S2-EXEC-03 6 | Result |
| --- | ---: | ---: | --- | --- | --- |
| `S2-P01-e2-f8.sql` | 9,232 | 191 | `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51` | `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51` | **MATCH** |
| `S2-P02-e3-actor-binding.sql` | 9,534 | 155 | `01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67` | `01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67` | **MATCH** |
| `S2-P03-e4-session-invariant.sql` | 5,511 | 127 | `8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4` | `8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4` | **MATCH** |

**Patch digest verdict: 3 of 3 MATCH. 0 MISMATCH.** Both recording documents carry identical values, and `S2-DOC-02:191-193` carries the same three (also MATCH), so four independent statements of the digests agree with the bytes on disk.

### 4.1 These are PRE-CORRECTION digests - they must not become the A5 signature digests

This is the single most important operational warning in this manifest, and it is corroborated in the documents themselves: `S2-EXEC-02:227` - *"These are **pre-correction** hashes and must **not** become the hashes signed at A5."* `S2-EXEC-03:165` repeats it. `patch-defects-before-a5.md` lists **D-01...D-12 plus D-10b all OPEN**, of which eight (D-01, D-02, D-05, D-06, D-07, D-09, D-10, D-10b) require a patch-file revision.

Therefore: the digests above are **correct for the bytes as they exist right now**, and are simultaneously **stale as an approval anchor**. They certify an unapplied, `PROPOSED`, pre-correction state. Concretely:

- `S2-P02` as shipped **always aborts**: D-07 records that the `haven.patch_gate` `set_config` call sits commented while the following block requires it. A MATCH here is a match to a broken file.
- `S2-P03` has no post-check (D-10b) and no in-file rollback, and its required production duplicate count depended on `A1`, which the owner declared **INOPERATIVE** - so P03 is `BLOCKED - PRODUCTION READ NOT AUTHORISABLE`.
- A5 is `APPROVED but NOT EXECUTABLE`; the files must be re-hashed after correction, and A3 must complete first because staging is still empty.

**Recommendation carried forward: the A5 signature must bind to digests taken after the D-01...D-12b corrections land, never to the three values in section 4.**

### 4.2 Labelling defect in `S2-EXEC-03` 6

`S2-EXEC-03` `:168` declares the column header `| File | Bytes | SHA-256 recorded in S2-EXEC-02 | SHA-256 now | Status |`, but the values in the "Bytes" column are `191 / 155 / 127` - these are **line counts**, not byte counts (`S2-EXEC-02` `:221` labels the same numbers `Lines`, correctly). The true byte sizes are `9,232 / 9,534 / 5,511`. The digests themselves are right; the unit label is wrong. Anyone re-verifying "bytes" against `stat` will report a false MISMATCH.

---

## 5. Scan-coverage reconciliation

### 5.1 The digest-basis question - `95-secret-scan.md` vs `sha256sum` today

`95-secret-scan.md` records, for the assembled artifact:

| Quantity | Value |
| --- | --- |
| Digest recorded in `95-secret-scan.md` | `efdbf985cfc72f721f9499a856fbdf51181f8851eca565fbae9e74d0e71f7092` |
| "chars" recorded in `95` for the artifact | 148615 |
| `sha256sum` of the artifact **as it exists today** | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` |
| Byte length today | 150,566 |
| Newline count today | 1951 |

**Answer: NOT MATCH** - if the comparison is raw `sha256sum` of the on-disk bytes, which is what a verifier will actually run. Both values are shown above, and they differ.

**But the mismatch is fully explained, and `95` is not wrong.** The files on disk use CRLF line endings. `95` digested the LF-normalised text (Python text-mode read). The relation holds exactly, for all 13 scanned files:

| File | `sha256sum` today (CRLF bytes) | `95` digest (LF text) | `95` chars | disk bytes | lines | bytes - lines = chars? | LF-normalised SHA-256 = `95` digest? |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `00-platform-assumptions.sql` | `42c019cf23d7...` | `fa229e0706a4...` | 3933 | 3,980 | 47 | YES | **MATCH** |
| `10-tables.sql` | `16bb23871ce9...` | `53d137e3481e...` | 11843 | 12,124 | 281 | YES | **MATCH** |
| `20-constraints.sql` | `892f7c961503...` | `598f53035108...` | 20565 | 20,729 | 164 | YES | **MATCH** |
| `30-indexes.sql` | `4391eb9242e6...` | `3e6b1bd82eca...` | 8586 | 8,668 | 82 | YES | **MATCH** |
| `40-functions.sql` | `599f038f8552...` | `a371dd90c725...` | 54285 | 55,150 | 865 | YES | **MATCH** |
| `50-triggers.sql` | `d4615bdaae9a...` | `63f43d9c99c7...` | 3245 | 3,284 | 39 | YES | **MATCH** |
| `55-auth-users-trigger.sql` | `6484dbd0c436...` | `d1802c1e3529...` | 1854 | 1,876 | 22 | YES | **MATCH** |
| `60-rls-policies.sql` | `4c843ad9a1da...` | `0fad0de37218...` | 8062 | 8,140 | 78 | YES | **MATCH** |
| `70-grants-default-privileges.sql` | `6d64b667f135...` | `92ae17d8c86a...` | 35612 | 35,973 | 361 | YES | **MATCH** |
| `80-realtime-publication.sql` | `53d2b17a7590...` | `0b09db879081...` | 2065 | 2,089 | 24 | YES | **MATCH** |
| `92-provenance-manifest.md` | `5ecc9557f844...` | `4f50ecbda9c2...` | 58921 | 59,442 | 521 | YES | **MATCH** |
| `94-validation.md` | `288d475e1952...` | `3d3eacd1b8bf...` | 1717 | 1,761 | 44 | YES | **MATCH** |
| `g3-reconstruction-2026-11-02.sql` | `fc996f450690...` | `efdbf985cfc7...` | 148615 | 150,566 | 1951 | YES | **MATCH** |

**Result: %d of 13 scanned files satisfy `bytes - lines = recorded chars`, and %d of 13 reproduce the `95` digest exactly after CRLF->LF normalisation.** Both all-13 checks pass. So the `95` digests are genuine and reproducible - but only through a normalisation step that `95` **never states anywhere in its text**. Its header describes the column as `chars`, not as a digest basis.

**This is a latent false-MISMATCH trap.** `100-file-hashes.txt` records the **raw CRLF** digest (`fc996f45...`), while `95-secret-scan.md` records the **LF-normalised** digest (`efdbf985...`) **for the same file, unmodified**. A reader comparing the two reports sees a contradiction where none exists.

### 5.2 What a future A3 owner would have to re-scan

Stated plainly, because it is a coverage question and not a judgement on the scan:

1. **Re-scan under a declared, single digest basis.** The artifact must be hashed once, in binary, and that basis written into the scan report. Otherwise `sha256sum` in the runbook will disagree with `95` on a file nobody touched.
2. **Re-scan after the D-01...D-12b patch corrections**, since those change the patch bytes and A5 signs against them.
3. **Re-scan the 9 `g3-build/` files that the `95` scan never covered** (it scanned 13 of 22): `100-file-hashes.txt`, `90-limitations.md`, `91-coverage.md`, `93-counts.json`, `95-secret-scan.md`, `96-review-checks.md`, `gen_g3.py`, `gen_scan.py`, `scan_phase34.py`.

   Note that `95`'s own declared scope was only `*.sql` plus the provenance manifest and validation report, so these nine are out-of-scope-by-design rather than skipped by error - but they are nonetheless **unscanned**, and four of them (`gen_g3.py`, `gen_scan.py`, `scan_phase34.py`, `100-file-hashes.txt`) are code or a control file, which is exactly where a credential tends to hide. `95` also self-discloses that it did not cover the Stage 1 evidence it was built from.
4. **Re-scan all 17 Stage 1 evidence files** - `95` states it covered the artifact, not its sources.
5. **Re-scan the Stage 2 document set** - see 5.3.

### 5.3 Present-but-never-scanned counts

Files that exist today and were never inside `95-secret-scan.md`'s file list (13 files). Counts only, no judgement about risk:

| Register | Files existing | Scanned by `95` | Present but never scanned |
| --- | ---: | ---: | ---: |
| `g3-build/` | 22 | 13 | **9** |
| `docs/stage1/evidence/` (incl. `edge-functions/`) | 17 | 0 | **17** |
| `docs/stage2/` (root + `evidence/` + `parts/`, excl. `patches/`) | 36 | 0 | **36** |
| `docs/stage2/patches/` | 3 | 0 | **3** |
| **Total across my registers** | **78** | **13** | **65** |

The three concurrent `S2-EXEC-04-*` files are additional present-but-never-scanned items and would bring the unscanned total to 68 if included.

---

## 6. Provenance limits

Verified this session with read-only Git commands only (`git log`, `git status`, `git branch -a`, `git symbolic-ref`, `git rev-parse --verify`, `git count-objects -v`); no git write operation was issued.

| Probe | Output |
| --- | --- |
| `git log --oneline -5` | `fatal: your current branch 'master' does not have any commits yet` |
| `git status` | `On branch master` / `No commits yet` / all six top-level entries **untracked** |
| `cat .git/HEAD` | `ref: refs/heads/master` |
| `git symbolic-ref HEAD` | `refs/heads/master` |
| `git rev-parse --verify refs/heads/master` | `fatal: Needed a single revision` |
| `ls .git/refs/heads/` | empty |
| `cat .git/logs/HEAD` | `No such file or directory` - no reflog has ever been written |
| `git count-objects -v` | `count: 0  size: 0  in-pack: 0  packs: 0  garbage: 0` - **not one object exists** |

**The repository has zero commits. The branch is unborn.** This confirms the `S2-EXEC-03:30` statement and the `S2-EXEC-02` B-10 blocker: there is no git provenance available to any artifact in this manifest.

**What that means for this manifest.** SHA-256 digests are the *only* integrity anchor that exists. There is no commit object, no tree hash, no signed tag, no reflog and no diff baseline behind any of the 78 files registered here. Two consequences follow, and both must be stated rather than smoothed over:

1. **A digest list is self-asserted.** `100-file-hashes.txt` is a text file that lists digests of other files, and its own bytes are bound to nothing. Anyone who can edit the files can edit the list that certifies them. The list is internally consistent (20/20 MATCH) but that consistency proves only arithmetic agreement, not provenance.
2. **A digest only becomes evidence when an independent copy of it exists.** Today such copies do exist for exactly 23 files, in the form of digests restated in *separate documents*: the 3 patch hashes appear in `S2-EXEC-02` 6.3, `S2-EXEC-03` 6 and `S2-DOC-02:191-193`, and `S2-REVIEW-02:206` abbreviates all three again; the 13 artifact digests appear in `95` under a different basis. That cross-document repetition is the closest thing to corroboration the project has. The remaining 55 files have one measurement from one observer in one session and no second witness at all - most critically `gen_scan.py`, which no digest list and no scan mentions.

Nothing in this register can therefore survive a determined local tamper, and nothing in it can be traced to an author. That is a property of the repository state, not of these documents.

---

## 7. Sensitive-content register (location and type only - no values recorded)

Every file in registers A-D was swept for credential- and PII-shaped content. **No value is reproduced in this manifest.** Findings are recorded as type + location + count.

| Content type | Occurrences | Files affected | Disposition |
| --- | ---: | ---: | --- |
| Email addresses (operator account identity) | **46** | **13** files, all in `docs/stage2/` | `SENSITIVE CONTENT - PII. Do not publish.` Highest concentrations: `evidence/S2-NEXT-01-readiness-report.md`, `parts/G-g5-validation.md`, `evidence/S2-INSP-01-supabase-org-slots.md`, `04-risks-rollback-approvals.md`, `S2-REVIEW-03-independent-audit.md`, `evidence/S2-CREATE-01-new-projects.md`, `evidence/S2-INSP-02-firebase-console.md`. |
| Email address, already masked with asterisks | 1 | `parts/G-g5-validation.md` | Correctly sanitised; the model for the other 44. |
| JWT-shaped three-part (`eyJ...`) strings | **0** | 0 | None detected anywhere in registers A-D, including Stage 1 evidence JSON. |
| Private-key blocks / `password:`-style assignments | **0** | 0 | None detected. |
| Supabase service-role *identifier name* (`service_role`) | 1190 | `g3-build` SQL + Stage 1 ACL JSON | **Not a credential.** A managed role *name* inside `GRANT`/ACL text. Confirmed by field-level inspection: no JSON evidence file contains a sensitive-named field carrying a value. |
| Production project reference identifier | 124 | 41 files across all three registers, incl. 18 in the assembled artifact and every SQL component header | `SENSITIVE CONTENT - infrastructure identifier. Location-only.` A future public repo entry must genericise these. |

**Summary: 43 files contain sensitive content requiring sanitisation before any repo publication** (union of email-bearing and reference-identifier-bearing files). **The count of actual exposed secret values is 0.**

**Corroboration of `95`'s CLEAN verdict.** `95-secret-scan.md` reported 0 matches over 13 files. This session's independent sweep found 0 JWT-shaped strings, 0 private keys and 0 password assignments across the whole register, and 0 email addresses anywhere in `g3-build/` or in any Stage 1 evidence JSON. The clean verdict **holds** for the artifact. The exposure is concentrated in the Stage 2 narrative documents, which `95` never covered.

`95` also self-discloses a real limit that this manifest confirms: **24 private-schema function bodies are absent from the evidence entirely**, so they were never scannable here or in Stage 1, and `A5` D-06 prosrc-hash validation cannot pass for them. No amount of scanning closes that.

---

## 8. Manifest summary

| Register | Files | Bytes | Lines (newline count) | All digests computed this session |
| --- | ---: | ---: | ---: | --- |
| A - `g3-build/` (G3 artifact + components + reports) | 22 | 494,319 | 6254 | yes |
| B - `docs/stage1/evidence/` (cited evidence) | 17 | 212,119 | 1001 | yes |
| C - `docs/stage2/` root authoritative docs | 20 | 625,794 | 5988 | yes |
| C1 - `docs/stage2/evidence/` | 6 | 85,750 | 1204 | yes |
| C2 - `docs/stage2/parts/` | 10 | 198,345 | 2037 | yes |
| D - `docs/stage2/patches/` (S2-P01/02/03) | 3 | 24,277 | 473 | yes |
| **TOTAL REGISTERED** | **78** | **1,640,604** | **16957** | **78 of 78** |

Excluded from the totals above: 3 concurrent `S2-EXEC-04-*` files (129,001 bytes, listed PENDING in 3.5), 19 `docs/stage1/` planning docs and `docs/stage1/reports/stage1-final.md` (outside the tasked registers but measured: 373,619 + 23,862 bytes), 1 empty directory (`edge-functions/pairing/`), and the 4 repo-root entries (`README.md`, `.env.example`, `.gitignore`, `supabase/` + `firebase/` config) which the manifest does not claim.

| Question | Answer |
| --- | --- |
| Total files registered | **78** |
| Total bytes registered | **1,640,604** |
| Files whose integrity this session verified against a **pre-existing recorded** digest | **23** of 78 (20 via `100-file-hashes.txt`, 3 patches via `S2-EXEC-02`/`03`/`DOC-02`) |
| Hash **MATCH** results | **36** comparisons: 20 digest-list entries + 3 patch digests (all MATCH on raw bytes), plus 13/13 MATCH for the `95` digests once CRLF->LF normalisation is applied |
| Hash **MISMATCH** results | **0** on raw bytes; **13** apparent mismatches against `95` arise purely from the undeclared digest basis (see 5.1) |
| Hash **MISMATCH** results | **0** |
| Files present but absent from the digest list | **2** (`100-file-hashes.txt`, `gen_scan.py`) |
| **Cited-but-missing** evidence | **0** - the two files previously reported missing (`schema-columns.md`, `functions-and-triggers.md`) both EXIST and are byte-stable; the earlier report is refuted |
| Requested-but-absent **documents** | **2** (`S2-DOC-01` referenced with no file; `S2-REVIEW-01` absent from the series) |
| **Present-but-unused** evidence | **6** (`g1-q9`, `g1-q10`, `g2-apk-identity-20261030.md`, `schema-columns.md`, `functions-and-triggers.md`, `edge-functions/capture-20261030.json`) |
| Present-but-never-scanned by `95` | **65** of 78 (9 in `g3-build/`, all 17 Stage 1 evidence, all 36 Stage 2 docs, all 3 patches) |
| Files containing sensitive content | **43** (types: 46 email occurrences in 13 files; 124 project-reference occurrences in 41 files) | secret values exposed: **0** | JWT-shaped found: **0** |
| Repository commits | **0** - unborn `refs/heads/master`, 0 git objects, no reflog |
| Artifact copies inside the repository | **0** |

---

## 9. Findings, split by evidential strength

### 9.1 VERIFIED - measured directly this session

1. `g3-build/` holds exactly **22** files; the tasking's figure of 22 is correct.
2. All **20** digests in `100-file-hashes.txt` MATCH the bytes on disk. 0 mismatches.
3. **`100-file-hashes.txt` covers 20 of 22 files**, omitting itself and `gen_scan.py`. Its name over-claims.
4. All **3 patch digests MATCH** the values recorded in `S2-EXEC-02` 6.3, `S2-EXEC-03` 6 and `S2-DOC-02:191-193`.
5. The recorded patch digests are **pre-correction**: D-01...D-12 + D-10b are all OPEN and 8 of them force a file revision.
6. `95-secret-scan.md`'s 13 digests reproduce **exactly** under CRLF->LF normalisation; `bytes - lines = chars` holds for 13/13. Against raw `sha256sum` the artifact is **NOT MATCH** (`efdbf985...` vs `fc996f45...`).
7. The repository has **zero commits**, 0 git objects, no reflog, HEAD pointing at an unborn `refs/heads/master`.
8. The **entire G3 artifact set lives outside the repository**, in a session temp directory, with 0 copies in `D:/control`.
9. `schema-columns.md` and `functions-and-triggers.md` **exist** and are byte-stable; the "missing" report is refuted.
10. **0 cited-but-missing** evidence files; **6 present-but-never-cited** evidence files.
11. All **11 independently checkable object counts** in `91`/`93` agree with direct array measurement of the Stage 1 JSON (19/183/137/62/21/7/1/38/14/149/18).
12. **No secret value exists** in the artifact or Stage 1 evidence: 0 JWT-shaped, 0 private keys, 0 password assignments. `95`'s CLEAN verdict is corroborated.
13. **46 email occurrences across 13 Stage 2 files** are the real sensitive-content exposure; only 1 of 45 is already masked.
14. `edge-functions/pairing/` is an **empty directory** - a registered custody slot with no content.
15. Stage 1 evidence JSON row counts were verified by parsing, not by trusting filenames.

### 9.2 INFERRED - reasoned from evidence, not directly observed

1. **`95` digested in Python text mode.** The exact `bytes - lines = chars` identity across all 13 files strongly implies an LF-normalised text read; the basis is nowhere stated in `95`.
2. **Token-to-file mapping was intended as `token + -20261029 + extension`.** Inferred from consistent size agreement between each `Source` token and the corresponding file; no document defines it.
3. **`100-file-hashes.txt` was generated after the last artifact write.** Its mtime is the newest in the directory, which is consistent with a final step but does not prove the ordering.
4. **`S2-EXEC-03` "Bytes" mislabel is a drafting error, not tampering** - the same numbers are labelled `Lines` in `S2-EXEC-02` 6.3 and the digests are correct.
5. **The 3 concurrent `S2-EXEC-04-*` files were produced by other auditors mid-session**, inferred from mtimes (09:15-09:16 on 2026-11-03) straddling my own directory listings. Not opened for adjudication.
6. **`docs/stage1/` evidence was sanitised at capture** as `95` claims; I did not re-verify the sanitisation method.

### 9.3 MISSING EVIDENCE - not obtainable, and not guessed

1. **No git provenance of any kind.** No commit object, tree, tag, reflog or signature exists to anchor any digest.
2. **No independent second copy of the artifact.** The 22 `g3-build/` files have exactly one copy, in a volatile path. This session cannot state an off-machine checksum from a prior occasion.
3. **No digest for `gen_scan.py` anywhere.** Not in `100-file-hashes.txt`, not in `95`. Its value appears in this manifest for the first time; before now it had zero integrity attestation.
4. **No platform clock evidence.** `95` states its run date is local, not UTC-stamped. No file in any register carries a trusted timestamp; filesystem mtime is host-local and trivially mutable.
5. **24 private-schema function bodies are absent from the evidence set entirely.** Not missing as files - missing as *data never captured*. `A5` D-06 prosrc-hash validation is unsatisfiable for them by any offline method.
6. **No return type for any of the 38 functions** was ever captured. This is `91`'s declared root blocker; outside my domain to adjudicate, registered here as an evidential hole.
7. **`extensions`, `views`/`matviews`, `sequences`**: `91` marks the expected counts `UNKNOWN`. I have no measurement to offer. NOT AVAILABLE, deliberately not estimated.
8. **Realtime publication membership in production** was never captured; `91` derives the 4 tables from documentation, not from a catalogue.
9. **`S2-DOC-01` and `S2-REVIEW-01` source documents** do not exist as files to register.

### 9.4 UNVERIFIED - asserted somewhere, not confirmed by this session

1. `S2-REVIEW-02:206` quotes the patch digests in **abbreviated form** (`1edad404...7be51`); the full values match, so the abbreviation is consistent, but I did not treat an abbreviation as an independent attestation.
2. `95`'s claim that Stage 1 evidence was sanitised "under a separate method" is not reproducible from anything in the repository.
3. `96-review-checks.md` 48-check results were **not** re-executed here; only its "25-row inventory" figure (vs 38 everywhere else) surfaced as an inconsistency during row-count reconciliation. Referred to the object-coverage auditor.
4. `93-counts.json` `total_statements_components_only = 459` and its per-component statement splits were not re-derived; only the `expected` block was verified.
5. Whether the `92` manifest's `copied directly` / `reconstructed` classifications are individually correct is a function-semantics question, explicitly out of scope.
6. The 3 concurrent `S2-EXEC-04-*` digests were measured once and are **already provisional** - the files were being written during my session.
7. `S2-EXEC-03`'s characterisation of the Stage 2 document set was read only for its patch-digest section, not audited.

---

## 10. Recommendations

Ordered so the cheapest, highest-value steps come first. None requires a production connection.

| # | Recommendation | Why | Blocking? |
| --- | --- | --- | --- |
| R1 | **Move all 22 `g3-build/` files into the repository** (suggested `supabase/migrations/g3/` for the SQL, `docs/stage2/g3-reports/` for the reports, `tools/` for the 3 scripts) and re-hash in place. | The artifact A3/A5 depend on currently sits in a temp dir the OS may reclaim. Single point of loss. | **Yes - highest** |
| R2 | **Make an initial git commit** of the whole tree, then record the commit hash in the manifest. | Turns a self-asserted digest list into an anchored one; closes B-10 and the `S2-EXEC-03:30` limitation. | **Yes** |
| R3 | **Regenerate `100-file-hashes.txt`** to cover all 22 files, hash itself via a detached signature or a second copy, and drop the misleading "100" name. | 2 files uncovered today, incl. `gen_scan.py` which has never been hashed anywhere. | Yes |
| R4 | **Publish one explicit digest basis** - "raw bytes, CRLF, `sha256sum`" - in `95`, `100-file-hashes.txt` and any runbook, and restate the 13 `95` digests on that basis. | A3 will run `sha256sum` against the artifact and get a false MISMATCH against `95`. This is the most likely operational failure in the whole chain. | **Yes** |
| R5 | **Add a `citations.md` index** in `g3-build/` mapping each `Source` token to its exact path, size and digest. | 473 citations currently resolve by an undocumented convention; none is machine-checkable. | Yes |
| R6 | **Never sign A5 against the section 4 digests.** Re-hash P01/P02/P03 after D-01...D-12b are applied, and record the post-correction digests as the A5 anchor. | `S2-EXEC-02:227` and `S2-EXEC-03:165` both forbid it; P02 aborts as shipped (D-07). | **Yes** |
| R7 | **Sanitise before any public repo entry**: replace all 46 email occurrences with a placeholder, genericise the 124 project-reference occurrences, and re-run the secret scan over the *whole* register (not just `*.sql`). | 44 of 46 emails are unmasked, and `95` never scanned any Stage 2 document. | **Yes** |
| R8 | **Correct `S2-EXEC-03` 6** "Bytes" header to "Lines", and fix the `96` "25-row inventory" figure (or explain it). | Two verifiable numeric mislabels that generate false MISMATCH reports. | No |
| R9 | **Adjudicate the 6 UNUSED EVIDENCE files**: either cite them (real column/trigger data in `schema-columns.md` and `functions-and-triggers.md` may bear on the missing-return-type blocker) or record them as superseded. | Uncited evidence is indistinguishable from ignored evidence. | No, but cheap |
| R10 | **Resolve or delete `edge-functions/pairing/`**, and give `S2-DOC-01`/`S2-REVIEW-01` either a file or an explicit `WITHDRAWN` entry. | Empty slots and a broken 01/02/03 series read as lost evidence. | No |
| R11 | **Re-scan after every patch revision**, and treat the `%d-file` register above as the standing scan scope rather than `*.sql` only. | `95`'s scope excludes 3 Python scripts, the digest list and all Stage 2 narrative. | No |
| R12 | **Extend `92`'s citation style to Stage 2 evidence** (APK identity, q9, q10 are currently invisible to the artifact's own provenance). | Provenance completeness. | No |

---

## 11. Reproduction recipe

Any future auditor should get identical numbers with:

```bash
# Register A
cd "C:/Users/ASUS/.qoder/tmp/D--control/g3-build" && wc -c -l * && sha256sum *
# Register B/C/D
cd D:/control && find docs/stage1/evidence docs/stage2 -type f | sort | xargs wc -c -l
find docs/stage1/evidence docs/stage2 -type f | sort | xargs sha256sum
# git provenance
git log --oneline -5; git status; git count-objects -v; git rev-parse --verify refs/heads/master
```

For the `95` digests specifically, hash the **LF-normalised** text (CRLF -> LF) rather than the raw bytes.

---

*End of S2-EXEC-05. No file outside this manifest was created or modified. No `S2-EXEC-04-*` or `S2-EXEC-06`+ sibling was opened for edit. The production project was not contacted, queried, or referenced beyond the identifier-type counts in section 7.*
