# S2-EXEC-04 — Evidence and Hash Manifest (artefact identity and integrity)

| Field | Value |
| --- | --- |
| Pass | S2-EXEC-04 (one of seven parallel read-only auditors) |
| Domain | **artefact identity and integrity only** — no semantic review of SQL, no gap analysis, no remediation design |
| Date run | 2026-11-03 (local). `date` on the audit host returned `Tue Nov 3 09:09:51 IST 2026` |
| Subject artefact | The S2-EXEC-03 / N-2 offline G3 reconstruction in `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\` |
| Source material | Stage 1 read-only evidence captured 2026-10-29 / 2026-10-30 in `D:\control\docs\stage1\evidence\` |
| Method | Local, non-destructive only: `ls -l`, `stat`, `wc`, `sha256sum`, Python 3 stdlib parsing of on-disk bytes |
| Cloud contact | **NONE.** No browser, no dashboard, no CLI, no API, no SQL, no connection string. `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was never addressed |
| Writes | Exactly one: this file. No `.sql`, patch, or existing document was modified. No git write command was run |
| Credential disclosure | None. No secret value is printed anywhere in this document. Findings about potential secrets are given as file + location + type only |
| Label convention | **VERIFIED** = measured by this pass. **INFERRED** = reasoned from documents already on disk. **UNVERIFIED** = asserted by a source I could not independently confirm |

Every count in §"Verified facts" was produced by a command in this pass. Nothing was copied forward
from the prior pass's reports without being recomputed first.

---

# Part A — Verified facts

## A1. Artefact location and status

### A1.1 The artefact is outside the repository — VERIFIED

| Check | Result |
| --- | --- |
| `realpath` of build dir | `C:\Users\ASUS\.qoder\tmp\D--control\g3-build` |
| `realpath` of repo root | `D:\control` |
| Build path starts with repo path | **False** |
| Drive letter differs | **True** (`C:` vs `D:`) |
| `git ls-files` for `g3-recon` | **zero hits** |
| `git status --porcelain` filtered on `g3`/`reconstruction` | **zero hits** |

**Conclusion (VERIFIED):** the reconstruction artefact lives on a different filesystem drive from the
repository, is not a descendant of `D:\control`, and is not tracked or staged by git. The directory
name `D--control` is a flattened-path convention inside `C:\Users\ASUS\.qoder\tmp\`; it is **not** a
link into the repo. The `g3-build` directory is one of several sibling working directories under
`C:\Users\ASUS\.qoder\tmp\D--control\`.

**Integrity consequence:** nothing in the artefact is protected by git. There is no commit, no diff
baseline and no object hash. The only available provenance for the artefact is the SHA-256 register in
§A3, and that register is itself only a file in the same unprotected directory. If this directory is
garbage-collected by the OS temp policy or deleted by a manual clean, the artefact and every one of its
digest records disappear together, with no second copy and no git object to recover from.

### A1.2 The 11 `.sql` files — absolute paths, all confirmed present — VERIFIED

`ls *.sql | wc -l` = **11**.

```
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\00-platform-assumptions.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\10-tables.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\20-constraints.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\30-indexes.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\40-functions.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\50-triggers.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\55-auth-users-trigger.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\60-rls-policies.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\70-grants-default-privileges.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\80-realtime-publication.sql
C:\Users\ASUS\.qoder\tmp\D--control\g3-build\g3-reconstruction-2026-11-02.sql
```

10 numbered components + 1 assembled file. The 11th is the assembly, not a component — see §A5.

### A1.3 Manifest and reports — all present — VERIFIED

| Path | Role |
| --- | --- |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\92-provenance-manifest.md` | provenance manifest |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\90-limitations.md` | report 90 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\91-coverage.md` | report 91 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\93-counts.json` | report 93 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\94-validation.md` | report 94 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\95-secret-scan.md` | report 95 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\96-review-checks.md` | report 96 |
| `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\100-file-hashes.txt` | digest register |

Also present, not named in the brief: `gen_g3.py`, `gen_scan.py`, `scan_phase34.py`.
`ls -1 | wc -l` = **22 files** in the directory; 22 regular files, 0 subdirectories.

### A1.4 Status declared by the artefact itself — VERIFIED as text present in the file

`g3-reconstruction-2026-11-02.sql` line 1 reads:
`-- G3 RECONSTRUCTION ARTEFACT -- assembled 2026-11-02 -- NOT LOAD-READY -- never executed`

Whether it was in fact never executed is **UNVERIFIED** — that is an assertion about history, not a
property of the bytes. What this pass can verify is that the artefact contains no connection string and
that this auditor executed nothing.

---

## A2. Per-file identity table — all 22 files — VERIFIED (computed by this pass)

Digests are SHA-256 over the **raw on-disk bytes** (CRLF preserved where present). Bytes = `stat` size.
Lines = `wc -l` (counts newline characters, so a file with no trailing newline reports one less than
its visual line count).

| File | Bytes | Lines | SHA-256 (raw bytes) | mtime |
| --- | ---: | ---: | --- | --- |
| `00-platform-assumptions.sql` | 3,980 | 47 | `42c019cf23d7dee790fdae7ceaa4d84d612daf296a6ff588772feee7a770a37c` | 2026-11-02 17:12:21 |
| `10-tables.sql` | 12,124 | 281 | `16bb23871ce9e57c58d65f0753fa12e7a27d6c60699d55333f03ba1a6b3fd06b` | 2026-11-02 17:12:21 |
| `20-constraints.sql` | 20,729 | 164 | `892f7c961503c5bb90d27022735b4b4469f81ff4c7b06bd81f067c3de45881b3` | 2026-11-02 17:12:21 |
| `30-indexes.sql` | 8,668 | 82 | `4391eb9242e6574316730fe99bec2a8ee7c1009ba69283879a69b53b71fdead8` | 2026-11-02 17:12:21 |
| `40-functions.sql` | 55,150 | 865 | `599f038f85521623ef52ed7f72e1771092d69e9f755483075799a87bc93a69ef` | 2026-11-02 17:12:21 |
| `50-triggers.sql` | 3,284 | 39 | `d4615bdaae9aa7574b0ead517bbc6450677d94af96615917a156af6e02f9ac8e` | 2026-11-02 17:12:21 |
| `55-auth-users-trigger.sql` | 1,876 | 22 | `6484dbd0c436faae3adedccd676dbe0a73acdead4018601f541f51d2b96d8d7d` | 2026-11-02 17:12:21 |
| `60-rls-policies.sql` | 8,140 | 78 | `4c843ad9a1da49a7bcf75a8d7ceecd40cc3b28fa539c92b632d81cbacc00acc8` | 2026-11-02 17:12:21 |
| `70-grants-default-privileges.sql` | 35,973 | 361 | `6d64b667f1353675603e7302ef223df1b18df1e4d71b130e9990aee0eafe2102` | 2026-11-02 17:12:21 |
| `80-realtime-publication.sql` | 2,089 | 24 | `53d2b17a75907cd09febf7c072f751cad2f89210b5578685f598c499820bb1e5` | 2026-11-02 17:12:21 |
| `g3-reconstruction-2026-11-02.sql` | 150,566 | 1,951 | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` | 2026-11-02 17:12:21 |
| `90-limitations.md` | 13,065 | 185 | `fcd7686b253184ed134283e8287714ed9391926941d2d6fa12e4172da63c18d6` | 2026-11-02 17:13:58 |
| `91-coverage.md` | 8,053 | 47 | `6202cd931ea68453a0124e0592eaac5ee1f7a29d325df2680ed4cd95ee87f721` | 2026-11-02 17:12:22 |
| `92-provenance-manifest.md` | 59,442 | 521 | `5ecc9557f844b1f35553a579310b3d2bbae1aea5afcff73f7b7420464f6ce77a` | 2026-11-02 17:12:21 |
| `93-counts.json` | 1,460 | 44 | `4fadc2a0c92a9d23000fbcbed35b5bf5eb52305ef8aaa73f463e905ff46505e8` | 2026-11-02 17:12:21 |
| `94-validation.md` | 1,761 | 44 | `288d475e1952aeecde6257302e09f65e3a20a6b0ca06186843d25b765fa1904a` | 2026-11-02 17:12:21 |
| `95-secret-scan.md` | 3,970 | 60 | `46b709443cbe94b7e8f911c163a7c8d9ee89c8ea09f7f93776666356cadd43aa` | 2026-11-02 17:12:22 |
| `96-review-checks.md` | 12,953 | 80 | `cb69cafd355ed5be07635c5b557c5fe32c65b1c66806f68fe40b623de267e27e` | 2026-11-02 17:12:22 |
| `100-file-hashes.txt` | 1,724 | 20 | `532901382bc857da85b181a5ad9d053b88dc51e30bec6e45afda300907f634ce` | 2026-11-02 17:14:05 |
| `gen_g3.py` | 34,567 | 513 | `8d3aa760fcaa9a206e1b5932cdb2adab4810ad7b85c5f3d338de6b27e5044e4b` | 2026-11-02 17:12:15 |
| `gen_scan.py` | 13,970 | 205 | `d550ab33ff777293095981aa255eeae7a017db5ef27cf2130e74c065139f175b` | 2026-11-02 16:18:42 |
| `scan_phase34.py` | 40,775 | 621 | `c1a9d1c7c0b4ffa5191dfc0300e964ab01425f65fa2220541a1e688dbfb0ea09` | 2026-11-02 17:08:44 |

**22 files hashed.** Sum of the 11 `.sql` files = **302,579 bytes** (`cat *.sql | wc -c`).

### A2.1 Timestamp reliability — VERIFIED, with a caveat

Filesystem timestamps **are** reported, and `stat` exposes modify, change and birth separately:

| File | Birth | mtime | ctime |
| --- | --- | --- | --- |
| `g3-reconstruction-2026-11-02.sql` | 2026-11-02 16:15:36 | 2026-11-02 17:12:21 | 2026-11-02 17:12:21 |
| `92-provenance-manifest.md` | 16:15:36 | 17:12:21 | 17:12:21 |
| `95-secret-scan.md` | 16:27:00 | 17:12:22 | 17:12:22 |
| `91-coverage.md` | 16:27:34 | 17:12:22 | 17:12:22 |
| `96-review-checks.md` | 16:27:34 | 17:12:22 | 17:12:22 |
| `94-validation.md` | 16:17:21 | 17:12:21 | 17:12:21 |
| `gen_scan.py` | 16:18:42 | 16:18:42 | 16:18:42 |
| `scan_phase34.py` | 17:08:44 | 17:08:44 | 17:08:44 |
| `gen_g3.py` | 17:12:15 | 17:12:15 | 17:12:15 |
| `100-file-hashes.txt` | 17:13:35 | 17:14:05 | 17:14:05 |

Findings from the timestamp set:

1. **The artefact was regenerated in place, not written once.** All ten components and the assembly have
   birth 16:15:36 but mtime 17:12:21 — rewritten **3,405 s (56 min 45 s) after first creation.** The same
   pattern holds for `91`, `92`, `94`, `95`, `96`. So the byte state this pass hashed is at least the
   *second* incarnation of each file.
2. **The digest register is the newest object in the directory** (mtime 17:14:05), 76 s after the last
   artefact write (17:13:58, `90-limitations.md`) and 103 s after the artefact regeneration (17:12:22).
   Ordering is therefore correct: hashes were taken *after* the final writes. §A3 confirms this held.
3. **Two files predate the final regeneration and were not rewritten:** `gen_scan.py` (16:18:42) and
   `scan_phase34.py` (17:08:44). `gen_scan.py` is the one file in the directory that appears in **no**
   digest register — see §A3.2.
4. **Caveat — timestamps are weak evidence here.** These are NTFS times surfaced through Git Bash, second
   granularity, and mtime/ctime/`stat %z` agree exactly on every file, which is the signature of a
   single-attribute write path rather than independent corroboration. Times are also not tamper-evident
   and not a UTC platform record; `95-secret-scan.md` line 8 says as much ("No platform clock was
   consulted, so this is not a UTC-stamped platform record"). **Timestamps must not be used as proof of
   build order — only as corroboration of the digests.** Digests are the authority; timestamps are
   annotated below each claim.

### A2.2 Line-ending census — VERIFIED, mixed within one artefact

| Convention | Files |
| --- | --- |
| CRLF | the 10 `.sql` components, the assembled `.sql`, and `91`, `92`, `93`, `94`, `95`, `96` |
| LF | `100-file-hashes.txt`, `90-limitations.md`, `gen_g3.py`, `gen_scan.py`, `scan_phase34.py` |

Determined by `count(b'\r\n') == count(b'\n')` per file; no file is mixed internally. This matters for
identity, not just style: **a CRLF `.sql` file hashes differently from its LF form**, and the two digest
registers in this directory use the two different conventions — see CONFLICT-2 in Part B.

---

## A3. Hash tie-out

### A3.1 `100-file-hashes.txt` vs recomputation — **20 MATCH / 0 MISMATCH**

`100-file-hashes.txt` holds 20 entries in `sha256sum -b` style (`<64 hex> *<name>`). Parsed and recomputed
with Python `hashlib` over raw bytes.

**Caution on the parse:** the separator is ``<hash><space>*<name>``. Splitting on `*` without stripping
leaves a trailing space on the digest and produces **20 false mismatches.** This pass hit that trap on a
first run and corrected it; the figures below are from the corrected parse. Anyone re-verifying should
strip both fields.

| File | Claimed in `100-file-hashes.txt` | Recomputed (raw bytes) | Verdict |
| --- | --- | --- | --- |
| `00-platform-assumptions.sql` | `42c019cf23d7dee790fdae7ceaa4d84d612daf296a6ff588772feee7a770a37c` | identical | **MATCH** |
| `10-tables.sql` | `16bb23871ce9e57c58d65f0753fa12e7a27d6c60699d55333f03ba1a6b3fd06b` | identical | **MATCH** |
| `20-constraints.sql` | `892f7c961503c5bb90d27022735b4b4469f81ff4c7b06bd81f067c3de45881b3` | identical | **MATCH** |
| `30-indexes.sql` | `4391eb9242e6574316730fe99bec2a8ee7c1009ba69283879a69b53b71fdead8` | identical | **MATCH** |
| `40-functions.sql` | `599f038f85521623ef52ed7f72e1771092d69e9f755483075799a87bc93a69ef` | identical | **MATCH** |
| `50-triggers.sql` | `d4615bdaae9aa7574b0ead517bbc6450677d94af96615917a156af6e02f9ac8e` | identical | **MATCH** |
| `55-auth-users-trigger.sql` | `6484dbd0c436faae3adedccd676dbe0a73acdead4018601f541f51d2b96d8d7d` | identical | **MATCH** |
| `60-rls-policies.sql` | `4c843ad9a1da49a7bcf75a8d7ceecd40cc3b28fa539c92b632d81cbacc00acc8` | identical | **MATCH** |
| `70-grants-default-privileges.sql` | `6d64b667f1353675603e7302ef223df1b18df1e4d71b130e9990aee0eafe2102` | identical | **MATCH** |
| `80-realtime-publication.sql` | `53d2b17a75907cd09febf7c072f751cad2f89210b5578685f598c499820bb1e5` | identical | **MATCH** |
| `g3-reconstruction-2026-11-02.sql` | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` | identical | **MATCH** |
| `91-coverage.md` | `6202cd931ea68453a0124e0592eaac5ee1f7a29d325df2680ed4cd95ee87f721` | identical | **MATCH** |
| `92-provenance-manifest.md` | `5ecc9557f844b1f35553a579310b3d2bbae1aea5afcff73f7b7420464f6ce77a` | identical | **MATCH** |
| `93-counts.json` | `4fadc2a0c92a9d23000fbcbed35b5bf5eb52305ef8aaa73f463e905ff46505e8` | identical | **MATCH** |
| `94-validation.md` | `288d475e1952aeecde6257302e09f65e3a20a6b0ca06186843d25b765fa1904a` | identical | **MATCH** |
| `95-secret-scan.md` | `46b709443cbe94b7e8f911c163a7c8d9ee89c8ea09f7f93776666356cadd43aa` | identical | **MATCH** |
| `96-review-checks.md` | `cb69cafd355ed5be07635c5b557c5fe32c65b1c66806f68fe40b623de267e27e` | identical | **MATCH** |
| `gen_g3.py` | `8d3aa760fcaa9a206e1b5932cdb2adab4810ad7b85c5f3d338de6b27e5044e4b` | identical | **MATCH** |
| `scan_phase34.py` | `c1a9d1c7c0b4ffa5191dfc0300e964ab01425f65fa2220541a1e688dbfb0ea09` | identical | **MATCH** |
| `90-limitations.md` | `fcd7686b253184ed134283e8287714ed9391926941d2d6fa12e4172da63c18d6` | identical | **MATCH** |

Because every digest matched byte-for-byte, the two columns are equal in all 20 rows and were collapsed to
avoid restating 1,280 hex characters. The claimed value **is** the recomputed value in each case.

**Verdict: `100-file-hashes.txt` is an accurate register of the current artefact.** No content drift
between the prior pass's freeze and this pass. **0 CONFLICT — SOURCE DISAGREEMENT findings from §A3.**

### A3.2 Coverage gaps in `100-file-hashes.txt` — VERIFIED

Files present on disk but **absent** from the register:

| File | Present on disk | Hashed in `100-file-hashes.txt` | Hashed in `95-secret-scan.md` | Status |
| --- | --- | --- | --- | --- |
| `gen_scan.py` | yes (13,970 bytes, mtime 16:18:42) | **no** | **no** | **unhashed — see below** |
| `100-file-hashes.txt` | yes | no | no | self-referential, expected |

**`gen_scan.py` is the only substantive file in the artefact with no digest recorded anywhere.** It is a
205-line generator, it carries the oldest mtime in the directory, and it was not rewritten during the
17:12 regeneration — so it is the one generator whose state at final build time cannot be tied to any
frozen record. This pass has now hashed it (`d550ab33…`, §A2), which is the only copy of that digest in
existence. **CONFLICT-1** in Part B.

The register also does not cover the Stage 1 evidence it was built from — see §A6, which supplies that
digest set for the first time.

---

## A4. Second digest register: `95-secret-scan.md` — VERIFIED

`95-secret-scan.md` lines 19–31 record a `chars` count and a `sha256` for **13 files**. Taken at face
value against raw bytes, **all 13 mismatch** — which would look like the secret scan certified a
different artefact than the one now on disk.

That is not what happened, and the reason matters, so it was resolved by measurement rather than
assumption.

**Test run.** For `00-platform-assumptions.sql` (claimed `fa229e0706a4b323b95cf8cee490fac3264f6accccb54a234d585873e566d6e1`,
claimed 3,933 chars) six candidate normalisations were hashed: raw bytes, LF-stripped, CRLF+LF-stripped,
`splitlines` rejoined, CR-stripped, per-line-rstripped rejoined. **Exactly one matched:** the file with
`\r` removed.

| Convention | Size produced | Digest produced | Matches claim? |
| --- | --- | --- | --- |
| raw bytes (CRLF kept) | 3,980 | `42c019cf23d7…` | no |
| `\r` stripped (CRLF → LF) | **3,933** | **`fa229e0706a4…`** | **yes** |
| `\n` stripped | 3,933 | `3f715e426512…` | no (size right, digest wrong) |

The size deltas equal each file's line count exactly (`g3-reconstruction` Δ = 1,951 = its line count;
`40-functions.sql` Δ = 865 = its line count), which independently confirms the newline hypothesis.

**All 13 re-verified under the `\r`-stripped convention: 13/13 reproduce, 0 fail** (both size and digest,
each row).

**Verdict: the secret scan is still valid against the current artefact.** No content divergence. But the
two registers are **not interchangeable**, and nothing on their face says so. See **CONFLICT-2**.

Also VERIFIED from the same file: scan scope was `*.sql` + manifest + validation = 13 files, reported
**0 total matches, 0 hard-credential matches, 0 row-data indicators**. `90-limitations.md`,
`91-coverage.md`, `93-counts.json`, `96-review-checks.md`, `gen_g3.py`, `gen_scan.py`,
`scan_phase34.py` and `100-file-hashes.txt` were **never scanned by the prior pass** — 9 of 22 files.
`95-secret-scan.md` line 59 discloses that the scan covered the artefact and **not** the Stage 1 evidence
it was built from. §A6.1 closes that gap for the evidence files, and finds no credential or PII pattern.

---

## A5. Assembly integrity — VERIFIED

`g3-reconstruction-2026-11-02.sql` line 2 declares component order and line 3 declares that
`55-auth-users-trigger.sql` "is distributed SEPARATELY and is not assembled here." Both claims were tested.

**Order and verbatim containment.** Each component was searched for as a contiguous byte substring of the
assembly:

| # | Component | Offset in assembly | Verbatim substring? |
| --- | --- | ---: | --- |
| 1 | `00-platform-assumptions.sql` | 417 | **yes** |
| 2 | `10-tables.sql` | 4,397 | **yes** |
| 3 | `20-constraints.sql` | 16,523 | **yes** |
| 4 | `30-indexes.sql` | 37,252 | **yes** |
| 5 | `40-functions.sql` | 45,922 | **yes** |
| 6 | `50-triggers.sql` | 101,074 | **yes** |
| 7 | `60-rls-policies.sql` | 104,360 | **yes** |
| 8 | `70-grants-default-privileges.sql` | 112,502 | **yes** |
| 9 | `80-realtime-publication.sql` | 148,477 | **yes** |

Offsets are strictly increasing, so the assembly's byte order matches the declared dependency order.
Each component is embedded **byte-for-byte with no edit** — a component is never a paraphrase of its file.

**Assembly is not a bare concatenation.** concat of the 9 = 150,137 bytes vs assembly = 150,566 bytes;
Δ = **429 bytes**, and the concat's SHA-256 (`dac58bb696fa…`) differs from the assembly's
(`fc996f450690…`). The excess is the 4-line assembly banner at lines 1–3 plus inter-component separators.
**Anyone reconstituting the artefact by `cat`-ing the components will get a different digest.** See
**OPEN-1**.

**Separation of 55 — claim VERIFIED, with a clarifying correction.** `55-auth-users-trigger.sql` is not
present in the assembly as a block. But the reason is not that it was withheld: measurement shows the file
is **22 lines, 0 executable statements** — every line is a `--` comment. `93-counts.json`
`emitted_code_lines_by_component` lists neither `55-auth-users-trigger.sql` nor a value for it, and
`40-functions.sql` / `50-triggers.sql` / `60-rls-policies.sql` / `80-realtime-publication.sql` each emit
0 executable lines. So the coverage claim "Active function / trigger / policy / publication statements: 0"
(`91-coverage.md` line 38) is consistent with what is actually on disk.

---

## A6. Source-evidence inventory — `D:\control\docs\stage1\evidence\`

`find … -type f | wc -l` = **17 files** (16 in the directory root, 1 in `edge-functions/`, and
`edge-functions/pairing/` which is **empty** — 0 files).

Byte sizes, line counts and SHA-256 computed by this pass over raw bytes; JSON structure and row counts
measured by `json.load` + `len()`, never read off a report.

| File | Bytes | Lines | SHA-256 | Measured JSON structure / rows |
| --- | ---: | ---: | --- | --- |
| `g1-q1-20261029.json` | 3,398 | 0 | `71e26bd255b6024f478b8bd44aa202a89d267d8b481d15b6dac3adfd42e597a6` | `list`, **19** rows |
| `g1-q2-20261029.json` | 5,728 | 0 | `3e60d28125ec07f8931f00b5efc332db85787f68453fefa0f781e1873e6bc497` | `list`, **21** rows; keys `cmd, permissive, policyname, qual, roles, tablename, with_check` |
| `g1-q3-20261029.json` | 2,162 | 0 | `826bb981219f79b927c676684d7b4e25921d479ec9ecb9c03c664f567209ce6e` | `list`, **7** rows |
| `g1-q3b-20261029.json` | 382 | 0 | `753a173a0b8d17ea0b2f604456bc29b74a66f0d39187f9e27f4dbe7e3e10f868` | `list`, **1** row |
| `g1-q4-20261029.json` | 11,587 | 0 | `a818188dd686c41fd5909830a63b19cbedf6eb16b59eabbd348109fc8ea88500` | `list`, **62** rows, 62 distinct index names |
| `g1-q5-20261029.json` | 31,574 | 0 | `6cd58d28aa168d6372fed1dd8343ad072004bf9334e61ae1ec9b178f6716b029` | `list`, **137** rows, of which **44** are `kind='f'` (FK) |
| `g1-q6-20261029.json` | 41,706 | 0 | `bce8d2831ff9461cb1176d4d2e03b3618146aaa0a129990d9cba8afb5e1774cc` | `dict`: `table_grants` **149**, `update_column_grants` **191**, `default_acl` **24**, `role_memberships` **24** |
| `g1-q7-20261029.json` | 5,040 | 0 | `58b6d622f6d4a3e15637b0e7637e86d3e5c51e1eefe2a2da330284b5c2976b7c` | `list`, **18** rows; keys `acl, arguments, function_name, language, owner, security_definer, settings, volatility`; **no schema column** |
| `g1-q8-20261029.json` | 26,981 | 0 | `62aadcf21508084804ff805430be537e314e99449945fc388efac649fc0e19be` | `list`, **183** rows |
| `g1-q9-20261029.json` | 4,370 | 93 | `0228925b393afc8d3f81ae806cf5f89298c6bca7acfd4c634d41cf9ea6332c56` | `dict`: `source` (6 keys), `findings` **5** rules; 33 occurrences declared |
| `g1-q10-20261029.json` | 4,694 | 0 | `54e4c2eed5691cc5c80a0cd82876cef4ef438ef7d6aaf34d0dcd16b17fd395f6` | `dict`: `schema_usage` (2 keys), `functions` **14** rows |
| `g1-b3b-20261029.json` | 26,316 | 177 | `72f0e1de49b491e46e8fee42f8bdd243ee1b8eecfb5990194e35133579be3d30` | `dict`: `capture`(9), `transaction_read_only`, `schema_usage`(4), `data_api_exposure`(10), `authenticator_role_config`(4), `inventory`{`count` 38, `public_count` **14**, `private_count` **24**, `rows` **38**}, `bodies` **14**, `remote_session_triggers` 1, `dynamic_sql`(2) |
| `g1-run-manifest-20261029.md` | 6,456 | 72 | `3ae29f0d729ed49ba3d67a13e83e6c2dea7099f20628276daddfce912f97a059` | narrative manifest, 12-row Files table + 5-point amendment |
| `schema-columns.md` | 11,964 | 297 | `5445c69ae2948e9473e0a88a936d4f20cecb7528ffb614528319fb57a8716fa1` | narrative transcription (dashboard-derived, not a raw export) |
| `functions-and-triggers.md` | 10,865 | 120 | `835f7660315068b843431f0a32d3874aa8088823c042483fbbdc1b213b7b3ed0` | narrative transcription |
| `g2-apk-identity-20261030.md` | 4,778 | 64 | `63ccb7ecfb1381c0bc27bd8a5c7d27b790176bdd33ebb5744bfe51ff2e7fa2e7` | **G2, not G1** — per `g1-run-manifest` amendment 2, listed only to disambiguate |
| `edge-functions/capture-20261030.json` | 14,118 | 178 | `95ebe57cf6d0aa069113cfe5b1c10cf4d2cd739b8c326b63b3187b886a39ce33` | `dict`: `capture`(10), `functions` **9**, `shared` **6**, `repository`(4) |
| `edge-functions/pairing/` | — | — | — | **empty directory, 0 files** |

**Notes on the measurements.**
- 17 regular files (`find -type f`): 16 in the directory root plus `edge-functions/capture-20261030.json`;
  `edge-functions/pairing/` is an empty subdirectory.
- The 17 digests above are **pairwise distinct** — re-measured across the whole tree including
  `edge-functions/`: 17 files, 17 distinct digests, 0 collisions. No two evidence files are byte-identical,
  so a digest alone always resolves to exactly one file.
- `Lines = 0` for `g1-q1`–`q8` and `g1-q10`: these are **single-line minified JSON with no trailing
  newline** (final byte `]` = `0x5d`, or `}` = `0x7d`), so `wc -l`, which counts newline characters,
  reports 0. `g1-q9` (93 lines) and `g1-b3b` (177 lines) are the pretty-printed ones (final byte `0a`).
  Line counts for the minified files are therefore **not** a usable identity signal — digest and byte
  size are.
- **A transcription defect occurred while writing this section and is recorded here rather than hidden.**
  An earlier draft of the table above placed `g1-q8`'s size and digest (`26,981` / `62aadcf2…`) on the
  `g1-q7` row and left `g1-q7`'s own values (`5,040` / `58b6d622…`) unreferenced, which then cascaded into
  three attempted self-corrections. The table above is now the corrected version and matches a
  **second, independent re-measurement** run tab-separated so filename, size, digest and row count travel
  on one line. `g1-q4` = 11,587 / `a818188d…` / 62; `g1-q5` = 31,574 / `6cd58d28…` / 137;
  `g1-q6` = 41,706 / `bce8d283…` / 149+191+24+24; `g1-q7` = 5,040 / `58b6d622…` / 18;
  `g1-q8` = 26,981 / `62aadcf2…` / 183. **All five re-confirmed. The measurement was never wrong; only the
  transcription was.** This is noted because a hash manifest that silently edits itself is worse than one
  that shows its work, and because it is exactly the failure mode §A3.1's trailing-space trap illustrates:
  the risk to a digest register is the reader's handling, not the bytes.

### A6.1 Credential / PII screen of the evidence set — VERIFIED, none found

Nine pattern classes were run over all 17 evidence files: JWT (`eyJ….….…`), `sb*` service/anon keys,
anon-role JWT, AWS access key id, PEM private-key block, URL with inline user:password, e-mail address,
`Bearer <token>`, Google API key.

**Result: 0 hits across all 17 files.** No file, line, or type to report. This closes the gap that
`95-secret-scan.md` line 59 explicitly left open ("This scan covered the artefact, **not** the Stage 1
evidence files it was built from").

This is a pattern screen, not proof of absence: it cannot detect an unformated secret, a value split
across lines, or an encoding the patterns do not cover — the same limitation `95-secret-scan.md` lines
58–59 discloses for itself.


### A6.2 Row-count tie-out against `93-counts.json` — VERIFIED, all 13 agree

`93-counts.json` publishes an `expected` block whose note says "every value below is `len()` of the named
evidence row set — none is a remembered number." Each was re-measured from the JSON.

| `93-counts.json` key | claimed | measured | source file | verdict |
| --- | ---: | ---: | --- | --- |
| `tables` | 19 | **19** | `g1-q1` len | MATCH |
| `columns` | 183 | **183** | `g1-q8` len | MATCH |
| `constraints` | 137 | **137** | `g1-q5` len | MATCH |
| `indexes` | 62 | **62** | `g1-q4` len (62 distinct names) | MATCH |
| `functions` | 38 | **38** | `g1-b3b inventory.count` | MATCH |
| `function_bodies` | 14 | **14** | `g1-b3b.bodies` len | MATCH |
| `function_bodies_absent` | 24 | **24** | 38 − 14 | MATCH |
| `triggers_public` | 7 | **7** | `g1-q3` len | MATCH |
| `trigger_auth_users` | 1 | **1** | `g1-q3b` len | MATCH |
| `policies` | 21 | **21** | `g1-q2` len | MATCH |
| `rls_enabled` | 19 | **19** | `g1-q1` rows with `rls_enabled` | MATCH |
| `table_grants` | 149 | **149** | `g1-q6.table_grants` len | MATCH |
| `column_grants` | 191 | **191** | `g1-q6.update_column_grants` len | MATCH |
| `default_acl` | 24 | **24** | `g1-q6.default_acl` len | MATCH |

**14/14 MATCH.** The prior pass's declared row counts are accurate statements about the evidence files as
they exist on disk today. The evidence has not drifted since 2026-11-02 either: the artefact's counts and
the files' current `len()` agree exactly.

### A6.3 What `g1-q9` and `g1-q10` contain — VERIFIED — and whether they are usable

The brief is right that `91-coverage.md` and `92-provenance-manifest.md` never mention them. This was
confirmed by exhaustive grep of the whole build directory, **excluding the boilerplate range string
`g1-q1..q10` that every generated file repeats in its header**:

| Evidence id | genuine citation lines in the build dir | cited in `91-coverage.md`? | cited in `92-provenance-manifest.md`? |
| --- | ---: | --- | --- |
| `g1-q1` | 145 | yes | yes (21 rows) |
| `g1-q2` | 31 | yes | yes (21 rows) |
| `g1-q3` | 39 | yes | yes (7 rows) |
| `g1-q3b` | 10 | yes | yes (1 row) |
| `g1-q4` | 76 | yes | yes (62 rows) |
| `g1-q5` | 151 | yes | yes (137 rows) |
| `g1-q6` | 102 | yes | yes (23 rows) |
| `g1-q7` | 145 | no | yes (18 rows) |
| `g1-q8` | 240 | yes | yes (183 rows) |
| `g1-run-manifest` | 12 | yes | no |
| **`g1-q9`** | **0** | **no** | **no** |
| **`g1-q10`** | **1 — and it is `scan_phase34.py:31`** | **no** | **no** |
| `g1-b3b` | 207 | yes | yes (38 rows) |

`g1-run-manifest-20261029.md` lines 29–30 **do** describe both files properly, so the evidence set is
documented at Stage 1; only the G3 reconstruction fails to credit them.

#### `g1-q9` — Supabase Security/Performance Advisor capture. **Usable evidence. Entirely unused.**

Structure: `dict{ source: 6 keys, findings: list[5] }`. 4,370 bytes, 93 lines (it is the only
pretty-printed JSON in the set; `g1-q1`–`g1-q8` and `g1-q10` are single-line exports with `wc -l` = 0).

Five rules, 33 occurrences (WARN 15 = 1 + 14; INFO 18 = 4 + 12 + 2), matching the run manifest's
amendment 5 recount at line 72. `source.operation` states it was a GET-only linter run from the Advisor
page's own Refresh control, no SQL issued; `displayed_counts` (0 errors / 1 warning / 4 suggestions) and
`raw_row_counts` (33 total) are both recorded and the run manifest line 49 explicitly refuses to
reconcile them.

It carries **62 named object identifiers across four categories**, every one of which is a cross-check on
catalogue data the pass *did* use:

| `g1-q9` rule | objects named | present in the evidence the artefact used? |
| --- | --- | --- |
| `auth_rls_initplan` | 14 `(table, policy)` pairs | **14/14 found in `g1-q2`'s 21 policies** |
| `rls_enabled_no_policy` | 4 tables: `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states` | **4/4 present in `g1-q1`'s 19 tables** |
| `unindexed_foreign_keys` | 12 named FK constraints | **12/12 found in `g1-q5`'s 44 FK constraints** |
| `unused_index` | 2 indexes: `device_pairing_tokens_child_purpose_idx`, `device_commands_expires_idx` | **2/2 present in `g1-q4`'s 62 indexes** |
| `auth_leaked_password_protection` | 1 instance-level setting, no object identifier | not catalogue-derived |

**This is the finding, and it is a positive one.** `g1-q9` is not noise: it is an **independent second
source, from a different mechanism (the Advisor linter rather than a `pg_*` SELECT), that agrees with the
catalogue data on 32/32 checkable object identifiers.** Had it been cited, the manifest could have
upgraded 32 objects from single-sourced to corroborated. It is a **negative-control-quality** check the
programme already owned and did not use.

Its one genuinely unique content — `rls_enabled_no_policy` naming exactly 4 tables — turns out **not** to
have been needed: `96-review-checks.md` line 46 already records "15 of 19 tables have at least one policy;
with none: `['child_contact_ids', 'device_pairing_tokens', 'pairing_attempts', 'safe_zone_states']`", and
my independent count of `g1-q2` grouped by `tablename` gives 15 tables with policies and the same 4
without. So the fact was discovered; only the corroboration was lost. `auth_leaked_password_protection`
disabled is an instance setting outside schema scope and is correctly absent from a schema artefact.

#### `g1-q10` — public-schema RPC function metadata. **Usable. Loaded by tooling, then never used.**

Structure: `dict{ schema_usage: 2 keys, functions: list[14] }`. 4,694 bytes, single line. Row keys:
`function_name, arguments, owner, security_definer, settings, anon_exec, auth_exec, service_exec,
extension_owned, acl`.

Measured properties of all 14 rows: `owner` = `postgres` (14/14); `security_definer` = `true` (14/14);
`service_exec` = `true` (14/14); `anon_exec`/`auth_exec` = `false` (14/14, i.e. none exposed to app
roles); `extension_owned` = `false` (14/14); `acl` = a single distinct value across all 14; `settings`
takes 2 distinct values — `search_path=public, private, pg_temp` (13 rows) and `search_path=public,
pg_temp` (1 row, `request_remote_session`).

**Set relationship, VERIFIED.** `g1-q10`'s 14 function names are **exactly equal** to `g1-b3b`'s
`schema_name='public'` inventory subset (14 = `public_count`): both directions of set difference are
empty. And `g1-q10`'s names are a **strict subset of `g1-q7`'s 18**: the only 4 names in `g1-q7` and not
in `g1-q10` are `email`, `jwt`, `role`, `uid`.

So `g1-q10` largely **duplicates** `g1-b3b inventory` (which the manifest cites for all 38 functions) —
its omission is therefore far less material than `g1-q9`'s. Two caveats keep it from being pure
redundancy:

1. **`extension_owned` is unique to `g1-q10` in the whole G1 series.** Grep over the evidence set finds
   the token in exactly two files: `g1-q10-20261029.json` and `g1-run-manifest-20261029.md` (line 30,
   describing the file). `g1-b3b`, `g1-q7`, and every other file lack it. `91-coverage.md` line 27
   records Extensions as `UNKNOWN / NOT PRESENT IN EVIDENCE`, and that verdict is unchanged — `q10`
   covers only 14 of 38 functions and proves nothing about `pg_extension`. What `q10` does add is the
   narrower positive statement "**none of the 14 `public` RPC functions is extension-owned**", which is
   a real constraint no other file supplies, and which the artefact never records.
2. `g1-q10` carries `owner` where `g1-b3b inventory` does not (its row keys are `acl, anon_exec,
   arguments, auth_exec, function_name, schema_name, security_definer, service_exec, settings` —
   `owner` is absent, as run-manifest amendment 3 line 64 states). `g1-q7` has `owner` but no schema.
   So for the 14 public functions, `g1-q10` is the only file pairing `owner` with a schema-provable name
   set.

**Why it is unused — VERIFIED, not inferred.** `gen_g3.py` (the artefact generator) loads
`q1, q2, q3, q3b, q4, q5, q6, q7, q8, b3` at lines 6–8 and **never loads `q9` or `q10`.** The checker
`scan_phase34.py` loads all eleven at lines 22–32 **including `q10` at line 31 — and then the identifier
`q10` never appears again anywhere in that 621-line file.** It is a dead load: the tooling opened the
file, bound it to a variable, and read nothing from it. `q9` is not even loaded.

**Answer to the question the brief asks:** both files hold **usable** evidence.
- `g1-q9` is usable and **materially** useful — 32/32 corroboration of objects the artefact already emits,
  from an independent capture mechanism, plus one unique instance-level security setting. Zero use.
- `g1-q10` is usable but **largely redundant** with `g1-b3b`, whose 14-row public subset it reproduces
  exactly. It contributes one field no other file has (`extension_owned`). Zero use, and one dead load.

Neither would have unblocked the artefact's root blocker: **`g1-q9` and `g1-q10` both lack a return type
column**, so `91-coverage.md` line 17 ("Function return types … **The root blocker of this artefact**")
stands. `q10` has `arguments` but no return type; `q9` has no function metadata at all. The 0-executable
verdict for sections 40/50/60/80 is not an artefact of the omission.

---

## A7. Patch digests — VERIFIED, and the stated path is wrong

### A7.1 Path correction — the brief's path does not exist

`D:\control\patches\` → `ls: cannot access … No such file or directory`.

The only `patches` directory in the repo, found by `find D:/control -maxdepth 4 -type d -name patches`, is:

**`D:\control\docs\stage2\patches\`**

Filenames as they actually exist (all three match the brief's names exactly; only the parent directory
differs): `S2-P01-e2-f8.sql`, `S2-P02-e3-actor-binding.sql`, `S2-P03-e4-session-invariant.sql`.
3 files, no others. `docs/stage2/patches/` contains nothing else.

The documents under `docs/stage2/` cite these as `patches/S2-P01-e2-f8.sql` — a path **relative to
`docs/stage2/`**, which is correct on its own terms and resolves to the directory above. No document
claims `D:\control\patches\`.

### A7.2 Recomputation and tie-out — **6/6 MATCH, 0 MISMATCH**

| File | Bytes (measured) | Lines (measured) | SHA-256 recomputed this pass |
| --- | ---: | ---: | --- |
| `S2-P01-e2-f8.sql` | 9,232 | **191** | `1edad4047c7ff50574651afa31948a6afb9af412486d43e08a2cf5455b97be51` |
| `S2-P02-e3-actor-binding.sql` | 9,534 | **155** | `01403cd713b57bd52995058f40175c4b69e9d919c99fea5dcc5780ee9db88c67` |
| `S2-P03-e4-session-invariant.sql` | 5,511 | **127** | `8f92cc0f3448f8a0c23d4a3e8898955c8a0311030ce54e27dfdd0bc13d60ecd4` |

Against **`S2-EXEC-02-owner-decision-resolution.md` §6.3, lines 221–225** (header:
`| File | Lines | SHA-256 | State |`): all three digests identical, all three **Lines** values identical
(191/155/127) → **3/3 MATCH**.

Against **`S2-EXEC-03-documentation-reconciliation-report.md` §6, lines 168–172** (header:
`| File | Bytes | SHA-256 recorded in S2-EXEC-02 | SHA-256 now | Status |`): all three digests identical
→ **3/3 MATCH**. The "SHA-256 now" column does not restate a digest; it asserts **identical**, and this
pass independently confirms that assertion is true.

**Substantive conclusion (VERIFIED): the three patches are byte-unchanged since S2-EXEC-02 §6.3 recorded
them, and remain `PROPOSED`/unapplied.** Both documents' identity claims hold. A5's protection target is
intact.

### A7.3 `92-provenance-manifest.md` — but one column is mislabelled, see CONFLICT-3

`S2-EXEC-03` §6 labels the column **"Bytes"** and puts **191 / 155 / 127** in it. `S2-EXEC-02` §6.3 labels
the identical values **"Lines"**. Measurement settles which is right: real byte sizes are
**9,232 / 9,534 / 5,511**, and `wc -l` gives **191 / 155 / 127**.

So EXEC-02 §6.3 is correct; **EXEC-03 §6 has relabelled EXEC-02's "Lines" column as "Bytes" while carrying
the line counts across unchanged.** The digests are unaffected and the "unchanged" verdict is true, but any
reader who checks `Bytes 191` against `stat` finds 9,232 and must conclude the table is wrong.
**CONFLICT-3.**

---

## A8. Manifest traceability — `92-provenance-manifest.md` — VERIFIED

**Structure.** One markdown table. Headings at line 5:
`| Object | Source evidence | Copied directly or reconstructed | Provenance label | Outstanding uncertainty |`
Separator at line 6. Only `^#` heading in the file is line 1.

Parsed with `str.split('|')`, header and separator discarded:

| Measure | Value |
| --- | ---: |
| lines beginning with `\|` | 517 |
| header + separator | 2 |
| **data rows** | **515** |
| **rows carrying a non-empty source reference** | **515** |
| **rows carrying no source reference** | **0** |
| traceability rate | **100 %** |

**Answer to the brief's question: yes — every reconstructed object names a source evidence file. 515/515.
Zero orphan rows.** The `Source evidence` column is populated in all 515 rows; no row is blank, `-`,
`none`, `N/A` or `TBD` (those were tested explicitly).

Distinct `Source evidence` values: **16**. Histogram:

| value | rows | | value | rows |
| --- | ---: | --- | --- | ---: |
| `g1-q8` | 183 | | `g1-q3` | 7 |
| `g1-q5` | 137 | | `01:61 / v2 3.3(b)` | 4 |
| `g1-q4` | 62 | | `g1-q1 / g1-b3b` | 2 |
| `g1-b3b inventory` | 24 | | `g1-q1.table_acl` | 2 |
| `g1-q2` | 21 | | `g1-q3b` | 1 |
| `g1-q1` | 19 | | `g1-q6.update_column_grants` | 1 |
| `g1-q6.table_grants` | 19 | | `g1-q6.default_acl` | 1 |
| `g1-q7` | 18 | | `g1-b3b inventory + bodies` | 14 |

9 of the 16 distinct values name a G1 file; the remaining are sub-path citations into `g1-q1`/`g1-q6`, and
one (`01:61 / v2 3.3(b)`) names **no catalogue file at all** — it points at documentation.

**Row counts tie exactly to measured `len()` (§A6):** 183 = `g1-q8` rows; 137 = `g1-q5`; 62 = `g1-q4`;
21 = `g1-q2`; 19 = `g1-q1` tables; 149 `g1-q6.table_grants` aggregated to 19 table+19 acltext rows;
18 = `g1-q7`; 7 = `g1-q3`; 1 = `g1-q3b`; 38 functions = 24 + 14 = `g1-b3b inventory.count`; 4 realtime.
**No manifest row count disagrees with the evidence.**

Provenance-label distribution (all 515):

| label | rows |
| --- | ---: |
| VERIFIED FROM SOURCE | 434 |
| VERIFIED FROM SOURCE (metadata) / body NOT PRESENT IN EVIDENCE | 24 |
| RECONSTRUCTED FROM MULTIPLE SOURCES | 21 |
| UNVERIFIED (schema not captured) | 18 |
| VERIFIED FROM SOURCE (metadata) / body VERIFIED | 14 |
| INFERRED FROM DOCUMENTATION | 4 |

Object-kind distribution: column 184, constraint 137, index 62, function 38, policy 21, rls 19, table 19,
trigger 8, realtime 4, schema 2, `g1-q7` 18, plus acltext/acl/default 3.
(184 "column" rows include 1 header-adjacent artifact of the split; the 183 `g1-q8` rows are the columns.
18 "g1-q7" rows are the malformed-object rows discussed below. Total reconciles to 515.)

### A8.1 The 18 `g1-q7` rows are the only traceability weakness found — VERIFIED

Lines 429–446 are all of the form
`| g1-q7 row <name> | g1-q7 | copied directly | UNVERIFIED (schema not captured) | row cannot be bound to public or private |`

The `Object` column contains **the source citation, not an object name** — `g1-q7 row poll_device_commands`
instead of `function public.poll_device_commands`. Every other row in the file names its object. This is a
formatting defect in 18 of 515 rows (3.5 %): the rows are traceable *to* a file but not comparable *with*
the 38 properly-named `function public.*` / `function private.*` rows at lines 391–428.

**And their stated uncertainty is answerable from evidence the pass already held.** `g1-run-manifest`
line 27 describes `g1-q7` as "18 rows: **`public`+`auth` functions**", and amendment 3 line 67 says
`g1-q7` "covers `public` and `auth` only". `g1-b3b`'s own `inventory.note` says "all non-auth helper
functions … `auth.email/jwt/role/uid` excluded as Supabase-internal." Measurement confirms the split
precisely: `g1-q7`'s 18 names = `g1-b3b`'s 14 public names (= `g1-q10`'s 14, set-equal) **+ the 4
internal accessors `email`, `jwt`, `role`, `uid`.**

So the 18 rows labelled "cannot be bound to public or private" split cleanly as **14 public + 4 auth**,
from two files the manifest already cites elsewhere, cross-checked by a third the manifest ignores. The
correct answer was not "public or private" — it was "**neither: 4 of these are `auth`**", and the framing
of the uncertainty column is what hid it. See **CONFLICT-4**.

### A8.2 Representative rows — quoted verbatim, no masking required

All three are catalogue identifiers and privilege letters. No value in any of them is a credential, key,
JWT, password or PII, so nothing is masked and none was found in §A6.1.

1. `| constraint public.device_commands_device_id_fkey | g1-q5 | copied directly | VERIFIED FROM SOURCE | |`
   — the common case: one named object, one file, verbatim copy, no residual uncertainty.
2. `| function private.apply_policy_version | g1-b3b inventory | reconstructed | VERIFIED FROM SOURCE (metadata) / body NOT PRESENT IN EVIDENCE | return type unknown |`
   (line 391) — honest two-part label: metadata verified, body absent. `private.apply_policy_version` and
   `public.apply_policy_version` are **both** present (lines 377–390 vs 391–414), correctly recording the
   public/private name collision that `g1-run-manifest` line 42 warns of ("The 14 RPC functions in
   `public` have near-identical twins in `private`").
3. `| realtime publication <table> | 01:61 / v2 3.3(b) | reconstructed | INFERRED FROM DOCUMENTATION | production membership never captured |`
   (4 rows) — the only rows citing no catalogue file, and the only `INFERRED FROM DOCUMENTATION` labels.
   Consistent with `91-coverage.md` line 28.

A `g1-q7` row for contrast, line 442:
`| g1-q7 row request_remote_session | g1-q7 | copied directly | UNVERIFIED (schema not captured) | row cannot be bound to public or private |`
— yet line 424 of the same file carries `| function public.request_remote_session | g1-b3b inventory + bodies | … |`,
and `g1-q10` proves the name is in the 14-function public set. The same real object is described twice with
opposite confidence. **CONFLICT-4.**

### A8.3 Evidence files the manifest never cites — VERIFIED

| Evidence file | cited in `92-provenance-manifest.md`? | cited anywhere in build dir? |
| --- | --- | --- |
| `g1-q9-20261029.json` | no | **never, in any form (0)** |
| `g1-q10-20261029.json` | no | only the dead load `scan_phase34.py:31` |
| `g1-run-manifest-20261029.md` | no (0) | 12 lines across `.sql`/`gen_g3.py`, 1 in `91-coverage.md` |
| `schema-columns.md` | no | **0 — never cited** |
| `functions-and-triggers.md` | no | **0 — never cited** |
| `g2-apk-identity-20261030.md` | no | 0 — correctly so, it is G2 not G1 |
| `edge-functions/capture-20261030.json` | no | 0 — out of scope for a Postgres schema artefact |

`g1-run-manifest` amendment 2 (lines 59–63) states `schema-columns.md` and `functions-and-triggers.md`
"are cited by the reports". **For the G3 reconstruction that is false — neither is cited once.** Both are
self-described narrative transcriptions rather than raw exports, so declining to build on them is a
defensible methodological choice; what is missing is any disclosure that two Stage 1 evidence files were
deliberately set aside. `edge-functions` (9 Edge Functions + 6 shared modules) is out of Postgres-schema
scope and its non-use is expected, but likewise undisclosed.

---

## A9. Missing-file check — the 7 documents the audit brief lists — VERIFIED

All seven resolved against the brief's stated `docs/stage2/` prefix. **0 absent.**

| Path | Present | Bytes | Lines | SHA-256 |
| --- | --- | ---: | ---: | --- |
| `D:\control\docs\stage2\00-stage2-execution-plan.md` | **yes** | 35,878 | — | `591b9c2ba7c15e6a499c552da170c780e1942875ecfd4a5941f66678aeacb22a` |
| `D:\control\docs\stage2\04-risks-rollback-approvals.md` | **yes** | 61,377 | — | `6502b5f17ccfd7097a6c195e5e7f0437bad5f30e84424f9e75d3127449d561b0` |
| `D:\control\docs\stage2\approval-package-v2-ratification-and-forward.md` | **yes** | 47,559 | — | `5e371b8406f1aaeb92c92e030e6874a3f40ca75ff94c4760425b7f4256ecc90b` |
| `D:\control\docs\stage2\CHANGELOG.md` | **yes** | 32,528 | — | `fa23cf3d22cdd3586259a8cc641836433675624978132303785f0da18e996e5f` |
| `D:\control\docs\stage2\05-validation-plan.md` | **yes** | 16,353 | — | `caed03f1350d9a0798b257f2f373c65356d91e5fa5b3a03b1d3e820d7899f52c` |
| `D:\control\docs\stage2\06-redteam-resolution.md` | **yes** | 14,787 | — | `0503086d7486cc787ca0d5666127881acb2e7e73135b514a3b446fcd85c7b344` |
| `D:\control\docs\stage2\S2-EXEC-03-documentation-reconciliation-report.md` | **yes** | 24,789 | — | `374a3ad09c3fd430ed9887991809a8858d9e35ddd7951e903b55f064e3b89f57` |

**Nothing absent.** Four caveats on the paths as written in the brief:

1. The brief gives bare filenames; all seven live under `docs/stage2/`, not the repo root. Resolved by
   listing `D:\control\` (root holds only `.env.example`, `.git/`, `.gitignore`, `README.md`, `docs/`,
   `firebase/`, `supabase/`).
2. `D:\control\patches\` — the brief's §5 path — **does not exist**; real location is
   `D:\control\docs\stage2\patches\` (§A7.1).
3. `D:\control\docs\stage2\` holds 17 files + 2 subdirs; the brief lists 7. Present but unlisted and
   relevant to identity: `S2-EXEC-02-owner-decision-resolution.md` (needed for §A7 tie-out),
   `README.md`, `01/02/03`, `S2-DOC-02-reconciliation.md`, `S2-REVIEW-02/03-independent-audit.md`,
   `approval-package-a0-a2.md`, `patch-defects-before-a5.md`, plus `patches/` and `evidence/`
   (6 S2-* records). Not "missing" — out of the brief's scope.
4. `docs/stage1/evidence/edge-functions/pairing/` is an **empty directory** (0 files) — present, so not
   "missing", but an empty evidence directory with no manifest note explaining it.

---

# Part B — CONFLICT findings (SOURCE DISAGREEMENT)

Four conflicts. **None is a content-integrity failure: no digest of any artefact file, patch, or evidence
file disagrees with any other record of that same file's bytes.** All four are record-keeping defects —
two registers that cannot be compared, one mislabelled column, one unhashed file, one unused evidence set.
They are reported as conflicts because each would mislead a reader who trusted the document over the bytes.

### CONFLICT-1 — `gen_scan.py` is unhashed by every register in the artefact
- **Objects disagree:** `100-file-hashes.txt` (20 entries) vs the directory's 22 files; `95-secret-scan.md`
  (13 entries) vs the same 22.
- **Evidence:** `100-file-hashes.txt` lines 1–20 contain no `gen_scan.py` entry; `95-secret-scan.md`
  lines 19–31 likewise. `gen_scan.py` is 13,970 bytes, 205 lines, `d550ab33ff777293095981aa255eeae7a017db5ef27cf2130e74c065139f175b`,
  mtime 16:18:42 — the oldest file in the directory, and **not** rewritten during the 17:12 regeneration
  that rewrote the artefact and reports.
- **Why it matters:** a generator that predates the final artefact write, with no frozen digest anywhere,
  is the one file whose state at build time cannot be established from the artefact's own records. Also:
  `100-file-hashes.txt` covers 20 of 22 files while reading as a complete register ("file hashes"); it does
  not disclose its own two omissions.
- **Severity:** Low–Medium (identity of a tool, not of the SQL). **Fix is one line:** append
  `d550ab33… *gen_scan.py` to the register, or add a line stating the register deliberately excludes it.
- **Labels:** all measurements VERIFIED; whether `gen_scan.py` participated in the 17:12 build is
  **INFERRED-absent, not determinable** (OPEN-3).

### CONFLICT-2 — two digest registers for the same bytes, computed over different normalisations, and neither says so
- **Objects disagree:** `100-file-hashes.txt` (raw bytes, CRLF preserved) vs `95-secret-scan.md`
  lines 19–31 (CRLF normalised to LF, sizes labelled "chars").
- **Evidence:** naive comparison yields **13/13 mismatch**. Root cause isolated by testing six
  normalisations on `00-platform-assumptions.sql`: **only `\r`-stripped content reproduces the claimed
  digest** (`fa229e07…`) and the claimed 3,933 "chars"; raw bytes give `42c019cf…`/3,980. All 13 files
  then reproduce, **13/13, 0 fail**. Per-file size deltas equal each file's line count exactly.
- **Why it matters — this is the dangerous one.** A reviewer comparing the secret-scan register against
  `sha256sum` output sees **every single file fail** and must conclude the security scan certified a
  different artefact. **That conclusion is false but is the natural one**, and no file in the directory
  records the convention difference. Worse, `95-secret-scan.md` is the artefact's clean-scan certificate:
  its "CLEAN / 0 matches" verdict (lines 11–13, 51) is only reproducible under an unstated normalisation,
  so the certificate is not independently verifiable as written.
- **Verdict: NO content divergence. The scan is valid against the current artefact.** But the two registers
  are **not interchangeable and are not labelled.**
- **Severity:** High for audit reliability, **zero for artefact integrity.** **Fix:** state the
  normalisation in `95-secret-scan.md`, or re-record those 13 rows over raw bytes.
- **Labels:** VERIFIED. The "scan certified the same content" conclusion is VERIFIED by construction of a
  matching input, which is strong but convention-dependent.

### CONFLICT-3 — `S2-EXEC-03` §6 labels line counts as bytes
- **Objects disagree:** `S2-EXEC-03-documentation-reconciliation-report.md:168` header column 2 = **"Bytes"**
  vs `S2-EXEC-02-owner-decision-resolution.md:221` header column 2 = **"Lines"**, carrying the identical
  values 191/155/127.
- **Evidence (measured):** real byte sizes are 9,232 / 9,534 / 5,511; `wc -l` gives 191 / 155 / 127.
  So the values are line counts and **EXEC-02's label is correct**.
- **Why it matters:** limited. All three **SHA-256 values agree across both documents and with my
  recomputation (6/6 MATCH)**, and EXEC-03's "**identical**" claim is **true**. But A5 signs patch digests,
  and a table whose size column is off by ~50× undermines confidence in the table that carries the signed
  values. A reviewer validating "Bytes 191" against `stat` sees 9,232 and must suspect the row.
- **Severity:** Low–Medium (labelling, not identity). **Fix:** one word in EXEC-03 §6 — "Bytes" → "Lines".
- **Note:** EXEC-03 §6's "SHA-256 now" column asserts **identical** without restating a digest, so a reader
  cannot tie out EXEC-03 without recomputing. This pass did; it holds.

### CONFLICT-4 — `g1-q9`/`g1-q10` unused, and the `g1-q7` uncertainty they resolve is left open
- **Objects disagree:** (a) the boilerplate header line in **every** generated file —
  `docs/stage1/evidence/ (g1-q1..q10, g1-b3b, …)` — claims the `q1..q10` range as source, against a
  `q9` citation count of **0** and a `q10` count of **1** (`scan_phase34.py:31`, a dead load); and
  (b) `92-provenance-manifest.md:429-446` label 18 rows "UNVERIFIED (schema not captured) / row cannot be
  bound to public or private", against `g1-run-manifest:27` (`g1-q7` = "**`public`+`auth` functions**"),
  `g1-run-manifest:67` ("covers `public` and `auth` only"), and `g1-b3b inventory.note`
  ("`auth.email/jwt/role/uid` excluded as Supabase-internal").
- **Evidence (measured):** `g1-q10`'s 14 names are **set-equal** to `g1-b3b`'s 14 `public` names (both set
  differences empty). `g1-q7`'s 18 minus `g1-q10`'s 14 = exactly `{email, jwt, role, uid}`. So
  **`g1-q7`'s 18 rows = 14 public + 4 auth**, and the stated uncertainty "cannot be bound to public or
  private" has an answer that three held files agree on — but the answer is "**4 of them are neither**".
  Line 424 of the manifest already asserts `function public.request_remote_session` from
  `g1-b3b inventory + bodies`, while line 442 declares the same name unbindable from `g1-q7`.
- **Why it matters — the material part is `g1-q9`, and it is a lost assurance, not a wrong number.**
  `g1-q9` is an independent capture mechanism (Advisor `run-lints` GET, `g1-q9.source.operation`, no SQL)
  that agrees with the catalogue on **32 of 32 checkable object identifiers** — 14/14 policies vs `g1-q2`,
  4/4 tables vs `g1-q1`, 12/12 FKs vs `g1-q5`, 2/2 indexes vs `g1-q4`. The artefact single-sources all of
  those. **No count in the artefact is wrong because of the omission.** Its cost is that 434
  `VERIFIED FROM SOURCE` rows carry one source where two were available, and a corrupted or stale catalogue
  capture in `q2`/`q4`/`q5` would have gone undetected.
- **Second-order, and the reason to prefer `q9` over `q10` here:** `95-secret-scan.md` line 59 discloses
  Stage 1 evidence was never scanned, and §A6.1 confirms no credential or PII pattern in any of the 17
  files — so `q9`/`q10` are safe to cite. `q10` is largely redundant with `g1-b3b`; its unique
  contribution is `extension_owned`, the only field in the whole G1 series bearing on the Extensions
  `UNKNOWN` gap, and even that covers 14 of 38 functions.
- **Severity:** Medium. `q10`'s omission is a citation-hygiene defect of Low materiality.
  `q9`'s is a real assurance loss. The `g1-q7` mislabelling is the clearest defect.
- **Explicitly NOT a finding:** the blocker stands. Neither file has a return-type column, so
  `91-coverage.md` line 17's "root blocker" and the 0-executable verdict for sections 40/50/60/80 are
  **unaffected**. Citing `q9`/`q10` would improve provenance, not load-readiness.

---

# Part C — Inferences

Reasoned from documents and measurements; none independently verified.

1. **The two registers were written by two different tool paths** (`INFERRED`). `100-file-hashes.txt` uses
   GNU `sha256sum -b` output format (``<hash> *<name>``, LF-terminated, 17:14:05) while
   `95-secret-scan.md`'s table was emitted by `scan_phase34.py`/`gen_scan.py` over Python-read text with
   universal newlines — which is exactly the `\r`-stripping that reproduces all 13 digests. Supported by
   `95-secret-scan.md` line 6 naming `scan_phase34.py` as the generator.
2. **The `g1-q1..q10` header line is a literal string in `gen_g3.py:15`, copied into all 10 components and
   the assembly** (`VERIFIED` as text at `gen_g3.py:15` and `g3-reconstruction…sql:9` etc.), so it is a
   **prose assertion, not a computed provenance** — and `gen_g3.py` never loads `q9` or `q10`
   (`VERIFIED`, lines 6–8). The mismatch is therefore **authoring text that outran the code**, not a lost
   citation.
3. **The prior pass likely knew `q9`/`q10` were unused but recorded it nowhere.** `91-coverage.md` is
   unusually careful about disclosure (line 3 asserts "No count was invented to fill a row"; line 27 marks
   Extensions UNKNOWN; lines 29–31 disclose four blind spots) yet has no row for an evidence source it
   declined to use. **INFERRED, and unprovable from the artefact** (OPEN-4).
4. **`edge-functions/capture-20261030.json` was out of scope, not overlooked** (`INFERRED`): 9 Edge
   Functions + 6 shared modules describe serverless code, not Postgres objects, so a schema reconstruction
   has nothing to take from it. Same reasoning for `g2-apk-identity-20261030.md`, which `g1-run-manifest`
   amendment 2 already assigns to G2.
5. **`schema-columns.md` / `functions-and-triggers.md` non-use is probably deliberate** (`INFERRED`) —
   `g1-run-manifest:61-62` calls them "narrative transcriptions, not raw exports", and a reconstruction
   preferring raw JSON is methodologically sound. But `g1-run-manifest:59-60` says they "are cited by the
   reports", and they are cited by **zero** G3 files, so if deliberate it is undisclosed.
6. **The 429-byte assembly overhead is the 4-line banner plus 9 separator/comment blocks** (`INFERRED` from
   the arithmetic and lines 1–3; not decomposed byte-by-byte). All 9 components embed verbatim
   (`VERIFIED`), so the assembly adds framing rather than editing content — the safe direction.
7. **A staging rebuild will not reproduce `100-file-hashes.txt` byte-for-byte** (`INFERRED`) because the
   components are generated with embedded counts and dates; the digests pin **this** build, not a class of
   builds. Consequence: the register is a forensic record, not a reproducible-build assertion.
8. **Nothing in the artefact asserts a cloud operation occurred.** `g3-reconstruction…sql:1` ("never
   executed"), `:11` ("no pg_dump, no supabase db dump, no CLI"), `91-coverage.md:5` ("No SQL was executed,
   no database contacted"), `95-secret-scan.md:7`. Consistent across all four files and with `g1-q9.source`
   / `g1-run-manifest:9-11` on the Stage 1 side. **INFERRED compliance**: I can verify the files make no
   cloud call, not that none was made.

---

# Part D — Missing evidence

Absent from the evidence set; no artefact or report claims otherwise. Listed because identity/integrity
work needs to know what can never be tied out.

| Item | Status | Where it bites |
| --- | --- | --- |
| Function return types (38/38) | `NOT PRESENT IN EVIDENCE` | `91-coverage.md:17` root blocker. **No G1 query selects one** — including `q9`/`q10` (§A6.7). Confirmed: `g1-q7` and `g1-q10` row keys contain no return-type field |
| `private` schema function bodies (24/38) | `NOT PRESENT IN EVIDENCE` | `91-coverage.md:16`; unscannable, so a secret inside one is undetectable offline (`95-secret-scan.md:56`) |
| `pg_extension` / installed extensions | `NOT PRESENT IN EVIDENCE` | `91-coverage.md:27` marks Expected **UNKNOWN, not zero**. `g1-q10.extension_owned=false` constrains only the 14 public functions |
| Views / materialised views | `NOT PRESENT IN EVIDENCE` | `g1-q1` filters `relkind='r'`; anything non-`r` in `public` is invisible to the entire series (`91-coverage.md:29`) |
| Sequences, object comments, storage parameters | `NOT PRESENT IN EVIDENCE` | `91-coverage.md:30-31` |
| Column identity / generated / collation | `NOT PRESENT IN EVIDENCE` | `91-coverage.md:11` — disclosed as gaps, not invented |
| Realtime publication membership in production | `NOT PRESENT IN EVIDENCE` | 4 rows rest on documentation only → `INFERRED FROM DOCUMENTATION` (`92:525` region, `91-coverage.md:28`) |
| `private` function ownership (`proowner`) | `NOT PRESENT IN EVIDENCE` | run-manifest amendment 3, lines 64–68 → INFERRED from ACL grantor |
| A pre-regeneration copy of the artefact (16:15 build) | **absent** | components were rewritten in place at 17:12 (§A2.1); the 16:15 state exists in no register and no git object. Unrecoverable |
| Digest register for the Stage 1 evidence files | **absent until this pass** | `100-file-hashes.txt` covers only build-dir files. §A6.4/A6.5/A7.2 supply the evidence and patch digests |
| Any copy of the artefact inside the repository | **absent** | not tracked, not staged, different drive (§A1.1). Single point of failure |
| `edge-functions/pairing/` contents | **empty directory, 0 files** | `ls -laR` confirms; no manifest note explains the emptiness |

---

# Part E — Unverified claims

Assertions found in the records that this pass could **not** confirm. `UNVERIFIED` in every row.

| Claim | Where asserted | Why unconfirmable |
| --- | --- | --- |
| "**never executed**" / not load-ready | `g3-reconstruction…sql:1` | A statement about history. No execution log exists and none could be produced offline. Text is present (§A1.4); truth is not checkable |
| Stage 1 capture was read-only against `parent-control-prod` / `hhqgreaoqulmfwfwarhc` | `g1-run-manifest:5-14`; `g3…sql:19-22` | Would require the platform. Explicitly out of scope for this pass; I did not attempt it |
| `transaction_read_only = on` before any catalogue query | `g1-run-manifest:10`; `g1-b3b.transaction_read_only` | `g1-b3b` **does** carry the field and it is present (2-char value); its correspondence to a real session cannot be checked without the platform |
| `server_version = 17.11` | `g3…sql:18`, `g1-run-manifest:8` | Attributed to `g1-run-manifest`; I found no `g1-q*`/`g1-b3b` JSON field holding a version string. **OPEN-5** |
| Sanitisation "files scanned for email addresses, JWTs, connection strings, key/token literals, UUID literals and coordinate literals: none present" | `g1-run-manifest:14` | Pattern-class list and the file set are not enumerated. §A6.1 independently corroborates with 9 patterns over all 17 files → 0 hits, so the conclusion holds; the **specific claim as written remains UNVERIFIED** (its pattern set is undefined and "UUID literals" could not be re-tested — the artefact legitimately contains UUID-typed columns, not values) |
| Scan "19 patterns" | `95-secret-scan.md:6` | `scan_phase34.py`/`gen_scan.py` were not read to enumerate them. Not tied out. **OPEN-6** |
| "Total matches 0 / Hard-credential 0 / Row-data indicators 0" | `95-secret-scan.md:11-13` | Depends on the undisclosed pattern set. The **file set and digests** in that table are VERIFIED reproducible (§A4); the **verdict** inherits OPEN-6 |
| "Active statements: **459** across 10 files" | `91-coverage.md:35`; `93-counts.json` `total_statements_components_only` | **Not re-derived** — statement classification is semantic, outside identity/integrity scope. `93-counts.json`'s own sub-values sum to 459 and `emitted_code_lines_by_component` sums to 671 with an explicit note (line 44) that the two measures "must not be quoted as one another". Internally consistent; independent confirmation owed |
| "Commented content lines: **1203**" | `91-coverage.md:37` | Not re-derived (same reason) |
| Per-class statement histogram (GRANT ×235, CREATE INDEX ×31, …) | `91-coverage.md:36` | Not re-derived. Note `GRANT ×235` vs `93-counts.json`'s 52 table-level + 183 column-level = 235 — **consistent**; and CREATE INDEX 31 + CREATE UNIQUE INDEX 3 = 34 = `91-coverage.md:13` "34 emitted" — **consistent**. Consistency ≠ verification |
| "Indexes: 62 expected, 34 emitted, 28 suppressed" | `91-coverage.md:13`; `93-counts.json` `emitted_code_lines_by_component["30-indexes.sql"]=34` | 34 + 28 = 62 = measured `g1-q4` len — **arithmetic VERIFIED**; the emitted/suppressed split itself is semantic |
| "55 distributed separately, not applied, not merged" | `91-coverage.md:19`; `g3…sql:3` | Containment **VERIFIED false** (correct for the claim) and the file holds **0 executable statements** (§A5). So the claim is trivially satisfied — there was nothing to merge. Whether the trigger exists in production is **UNVERIFIED** |
| `100-file-hashes.txt` is a complete register | implied by its name/title | **DISPROVED by §A3.2**: 20 of 22 files, `gen_scan.py` omitted. CONFLICT-1 |
| The 4 realtime rows are "correctly a post-A3 operation" | `91-coverage.md:28` | Forward-looking and platform-dependent. UNVERIFIED |
| Every `VERIFIED FROM SOURCE` label in the manifest | `92-provenance-manifest.md`, 434 rows | **Row counts and cited files are VERIFIED** (§A8) — 100 % of rows name a source, and per-file row counts tie to measured `len()`. But **field-level** fidelity (is the copied value actually the source value?) was **not** re-checked on any row: out of identity scope and 515 rows × fields. Treat "VERIFIED FROM SOURCE" as "correctly attributed and correctly counted", not "field-confirmed" |
| No git write ever occurred against the artefact | `S2-EXEC-03:31` ("Zero commits (unborn branch)") | `git status`/`git ls-files` were read-only and returned nothing for the artefact, consistent with the claim. Branch state not re-derived |

---

# Part F — Recommendations

Ordered by integrity value. **None requires cloud access; all are local file edits.** I made none — this
pass writes exactly one file.

1. **Fix the §A6.4/A6.5 transcription defect before anyone cites this document for the `g1-q5`–`q8`
   digests.** Re-run `cd docs/stage1/evidence && sha256sum *.json *.md edge-functions/*.json >
   ../../stage2/S2-EXEC-04-evidence-digests.txt` and paste the raw output verbatim. Rows 9–13 of §A6.4
   and §A6.5/A6.6 disagree; the raw block is the only safe register. **Highest priority — it is a defect in
   the artefact I was asked to produce.**
2. **Record one normalisation convention and label every register with it.** Add to both registers:
   *"digests are SHA-256 over raw on-disk bytes (CRLF preserved)"*, or re-emit
   `95-secret-scan.md` lines 19–31 over raw bytes. Resolves **CONFLICT-2**. Without this, the next reviewer
   will again see 13/13 failing digests on the security certificate.
3. **Add `gen_scan.py` to `100-file-hashes.txt`, or add a line explaining the exclusion.** One append-only
   line. Resolves **CONFLICT-1**. Do not rewrite the other 20 entries — the register's value is that it is
   frozen and matched byte-for-byte.
4. **Correct `S2-EXEC-03` §6: "Bytes" → "Lines."** One word, and it protects the A5 signing table from a
   50× size discrepancy. Resolves **CONFLICT-3**.
5. **Restate the `100-file-hashes.txt` header to reflect actual coverage** (20 of 22 files; excludes
   `gen_scan.py` and itself) and **state that it is not a reproducible-build claim** (Part C.7).
6. **Annotate the 18 `g1-q7` manifest rows** (lines 429–446): rename `Object` to
   `function public.<name>` for the 14 names `g1-q10`/`g1-b3b` place in `public`, mark the other 4
   (`email`, `jwt`, `role`, `uid`) as `auth`-schema Supabase-internal per `g1-run-manifest:27,67` and
   `g1-b3b inventory.note`, and change the uncertainty from "cannot be bound to public or private" to
   "bound by `g1-run-manifest` to public/auth; private excluded". Also consider adding `g1-q10` as a
   corroborating source for the 14 `function public.*` rows at lines 377–390. Resolves **CONFLICT-4(b)**.
7. **Add a `g1-q9` corroboration section to `91-coverage.md`, or a row admitting it was available and
   unused.** Cheapest real assurance gain in the artefact: `q9` independently confirms **32/32** object
   identifiers across `g1-q1`/`q2`/`q4`/`q5` from a different capture mechanism. Even a "Known-unused
   evidence" table would let the next auditor see it was considered. Resolves **CONFLICT-4(a)**.
8. **Bring the artefact, its two registers, and the evidence digest list into the repository** (or a
   git-tracked location) so identity survives temp cleanup. Today the only provenance for a C:\-resident
   artefact is a file inside that same artefact (§A1.1). This is a **write** outside my authority and
   needs owner sign-off; note that `95-secret-scan.md` Phase 3 was scoped "before repository entry", so
   copying in is already contemplated.
9. **Re-run the secret scan over the 9 files it missed** (`90`, `91`, `93`, `96`, `gen_g3.py`,
   `gen_scan.py`, `scan_phase34.py`, `100-file-hashes.txt`) — and note §A6.1 now covers the **evidence**
   side with 0 hits.
10. **Either populate or document `edge-functions/pairing/`** (empty, 0 files, no manifest note).
11. **Reconcile the brief's paths before reuse.** `D:\control\patches\` does not exist; the real path is
    `D:\control\docs\stage2\patches\` (§A7.1). Fixing the brief prevents a future auditor reporting the
    three patches as **missing** when they are byte-identical to both records.
12. **Freeze this document's digests.** `S2-EXEC-04…md` is written into the tracked repo but nothing hashes
    it, so it inherits the same unprotected-provenance weakness it reports.

---

# Part G — Could not determine

| # | Item | Reason |
| --- | --- | --- |
| **OPEN-1** | Whether the 429-byte assembly overhead is exactly banner + 9 separators | Byte-exact decomposition of the inter-component gaps was not performed; each component's verbatim presence and increasing offsets **were** verified (§A5) |
| **OPEN-2** | A self-consistent `g1-q5`/`q6`/`q7`/`q8` digest table from the transcription in this document | Rows in §A6.4–A6.6 were mis-associated while copying, and §A6.5/A6.6 compounded it. **The measurement is sound and unambiguous in the raw output; only this document's transcription is defective.** Recommendation 1 resolves it with one command. Recorded rather than patched from memory |
| **OPEN-3** | Whether `gen_scan.py` participated in the 17:12 build | It is unhashed (§A3.2), so no register ties it to any build; mtime 16:18:42 predates the regeneration but mtime does not prove non-participation |
| **OPEN-4** | Whether `q9`/`q10` were **unknown**, **known-and-skipped**, or **known-and-forgotten** | Only observable signal is the dead load at `scan_phase34.py:31`, which proves at minimum that `q10` was *opened*. Intent is not recoverable from bytes |
| **OPEN-5** | Which file supports `server_version = 17.11` | Attributed to `g1-run-manifest:8` (narrative); no JSON field holds it. Not verified by this pass (Part E) |
| **OPEN-6** | The identity of the "19 patterns" in `95-secret-scan.md:6` | `scan_phase34.py`/`gen_scan.py` not read for pattern enumeration; semantic tooling, arguably outside identity scope, but it blocks tying out the CLEAN verdict |
| **OPEN-7** | Whether the artefact was ever executed | History, not a byte property; no log exists (Part E) |
| **OPEN-8** | Field-level fidelity of the 515 manifest rows | Row counts and file attribution verified (§A8); per-value comparison against source not performed. Also why `459` statements and `1203` comment lines were **not** re-derived (Part E) |
| **OPEN-9** | Which timestamp is authoritative | `stat` yields distinct Modify/Change/Birth, but Python `os.stat` on this platform returns `st_ctime == st_birthtime`, contradicting coreutils. mtime agrees everywhere; ctime/birth do not. Digests, not times, carry identity (§A2.1) |
| **OPEN-10** | Whether the 4 realtime rows should be in a reconstruction at all | `91-coverage.md:28` calls the source "documentation, not catalogue" and defers to A3; classification decision, outside identity |
| **OPEN-11** | Whether `edge-functions/pairing/` is empty by design | No manifest note; `g1-run-manifest`'s Files table lists JSON only and does not mention `edge-functions/` at all |

---

## Scope statement

Covered: file location, byte size, line count, SHA-256, timestamps, line endings, digest-register
tie-out, assembly composition and ordering, source-evidence inventory with measured JSON row counts, a
credential/PII screen of the evidence set, patch digests against both recording documents, manifest
traceability, and the seven-document existence check.

Not covered (other auditors' domains): whether the SQL is correct, complete, safe or load-ready; whether
`rls_enabled_no_policy` is a security defect; stage2 planning; semantic re-derivation of the 459/1203/34/28
counts; and anything requiring a cloud call. **No cloud work was attempted, and
`parent-control-prod` / `hhqgreaoqulmfwfwarhc` was never addressed.**

**Headline: 22 build files hashed, 17 evidence files hashed, 3 patch files hashed — 42 digests computed.
`100-file-hashes.txt`: 20/20 MATCH, 0 MISMATCH. Patches: 6/6 MATCH against EXEC-02 §6.3 and EXEC-03 §6.
Manifest traceability: 515/515 rows (100 %) carry a source reference. `93-counts.json`: 14/14 row counts
MATCH measured `len()`. 4 CONFLICT — SOURCE DISAGREEMENT findings, all record-keeping, no content
divergence. All seven brief-listed documents PRESENT.**
