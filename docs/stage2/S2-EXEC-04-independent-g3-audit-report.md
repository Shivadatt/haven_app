# S2-EXEC-04 — Independent G3 reconstruction audit and A3 readiness assessment

| Field | Value |
| --- | --- |
| Pass | S2-EXEC-04, §10 deliverable **1 of 6** (headline report). The other five exist as separate files, listed at §12 |
| Audit class | Offline, repository-only, read-only audit of the S2-EXEC-03 / N-2 G3 reconstruction artefact |
| Artefact under audit | `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/` — components `00`,`10`,`20`,`30`,`40`,`50`,`55`,`60`,`70`,`80` + assembled `g3-reconstruction-2026-11-02.sql` + reports `90`–`96`,`100` |
| Date | 2026-11-03 (audit host `date` → `Tue Nov 3 09:09:51 IST 2026`) |
| **Verdict** | **`NOT LOAD-READY — RECONSTRUCTION GAPS`** (§1, §8; full string at §13) |
| Operational actions performed | **NONE.** No Supabase Dashboard, no Firebase Console, no browser navigation, no cloud call, no SQL Editor, no SQL executed, no REST/CLI/API, no database connection, no sentinel, no schema load, no settings change, no patch read-as-authorisation or edit, no credential or secret read/generated, no `auth.users` count, no Firebase app registration or FCM work, no production access, no Git commit/push/reset/clean |
| Files modified | **Zero.** No `.sql`, patch, plan-of-record or evidence file was touched |
| Production | `parent-control-prod` / `hhqgreaoqulmfwfwarhc` never addressed; the ref appears in the artefact only in header comments as provenance (`00-platform-assumptions.sql:6`), never as a target |
| Authored by | Main agent, consolidating five landed domain reports and two reply-only auditor findings. The seven-auditor fan-out was truncated by execution-capacity failure; §11 records exactly which domains were covered by an independent agent and which were re-derived here |

**Standing rules applied throughout.** Ratification grants nothing forward
([approval-package-v2](approval-package-v2-ratification-and-forward.md):123-127); a recorded owner decision is not an
advance authorisation and no fence is filled by it ([04](04-risks-rollback-approvals.md):401-404); **zero signature
fences are filled by this pass**; nothing here converts an unsigned block into an executable one.

---

## 1. Executive verdict

The artefact is **structurally faithful and behaviourally empty**. Both halves of that sentence were independently
re-measured, not inherited.

- **Faithful:** every object class the Stage 1 evidence actually describes is reproduced in the artefact and reconciles
  to the capture row-for-row — 19 tables, 183 columns, 137 constraints, 62 indexes (34 emitted + 28 correctly
  represented by their backing constraint), 19 RLS enables, 235 grants, 13 default privileges, 459 active statements
  ([S2-EXEC-04-object-coverage-matrix.md](S2-EXEC-04-object-coverage-matrix.md) §Totals,
  [S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md) checks 1-8, 13).
- **Empty:** **0 active `CREATE FUNCTION`, 0 `CREATE TRIGGER`, 0 `CREATE POLICY`, 0 `ALTER PUBLICATION`,
  0 `CREATE EXTENSION`** in the assembled file — verified twice by two different methods (component-by-component parser
  and assembled-file grep), agreement with the artefact's own `91-coverage.md:35-36`.

A schema load of this file would therefore create the *shape* of the production database and **none of its behaviour**:
no signup provisioning, no append-only audit guard, no `set_updated_at`, no session-transition guard, no Realtime, and —
because 19 `ENABLE ROW LEVEL SECURITY` land with **0 policies** on tables that carry live `authenticated` write grants — a
database that returns **0 rows** to `authenticated` and refuses every write with `42501`
([S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md) H-1).

The gap is **not** a build defect. It is the direct consequence of what the authorised evidence never captured
(§4, §8). Offline reconstruction cannot close it, and this pass refused to close it by guessing.

`READY FOR OWNER REVIEW — NOT AUTHORISED TO LOAD` is **not** available, because its condition — "all required objects
traceable, artefact structurally complete" — fails on categories 11, 12, 14, 16, 19, 21 and on the seven `UNKNOWN`
populations. `BLOCKED — EVIDENCE OR ARTEFACT UNAVAILABLE` is **not** the right verdict either: the artefact was located,
hashed, and read in full, and the essential Stage 1 evidence was located (two documents earlier reported "missing" were
found and digested — §3 of the consolidated report). The correct verdict is the middle one.

**Verdict: `NOT LOAD-READY — RECONSTRUCTION GAPS`.**

---

## 2. Artefact identity and hash

| Attribute | Measured value | Basis |
| --- | --- | --- |
| Path | `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/g3-reconstruction-2026-11-02.sql` | `realpath`; **outside** the repo (`D:\control`), different drive, `git ls-files` zero hits |
| Size | **150,566 bytes** | `wc -c` / Python `len(bytes)` |
| Lines | **1,951** LF terminators (1,952 split segments incl. trailing) | this pass |
| Composition | **661** code lines · **1,186** comment-only · **104** blank = 1,951 | measured this pass; arithmetic closes exactly |
| Active statements | **459** = 00:2 · 10:19 · 20:137 · 30:34 · 40:0 · 50:0 · 55:0 · 60:19 · 70:248 · 80:0 | independent re-termination, two auditors, both agree with `91-coverage.md:35-36` |
| SHA-256 (raw bytes, CRLF preserved) | **`fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6`** | `100-file-hashes.txt:11`, re-verified |
| SHA-256 (CRLF→LF normalised) | `efdbf985cfc72f721f9499a856fbdf51181f8851eca565fbae9e74d0e71f7092` | `95-secret-scan.md:29`, re-verified |
| Relationship of the two digests | **Same bytes, two normalisations** — demonstrated by read-only re-hash, not asserted | [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md) M-06 |
| Component digests | 10 fingerprints recorded at [S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md):9-19 and in [S2-EXEC-04-evidence-and-hash-manifest.md](S2-EXEC-04-evidence-and-hash-manifest.md) §A3 | `sha256sum` |
| Modification metadata | assembled file mtime `2026-11-02 17:12:21.5` local +0530; scan record 17:12:22.1; hashes file 17:14:05 | stat, ordering consistent with "scan then hash" |
| Changed by this audit? | **No.** Read, counted, hashed only | §"Files modified" |
| Provenance manifest | `g3-build/92-provenance-manifest.md`, **515 rows**, every row carries a source reference | re-counted |

**Two provenance facts the owner must see.** (a) The artefact sits in an OS-temp directory: nothing protects it, and the
digest register that is its only provenance lives in the same unprotected directory
([S2-EXEC-04-evidence-and-hash-manifest.md](S2-EXEC-04-evidence-and-hash-manifest.md) A1.1). (b) The repository has
**zero commits**, so git offers no baseline at all. Before A3 can be signed against an "artefact of record", the digest
must be bound in A3's own change record and the file given a durable, owner-named home — blocker **S4-BL-01**.

**Compilation note on the two line/comment totals.** `91-coverage.md:37` asserts 1,203 commented lines (component basis);
this pass measured **1,186 in the assembled file** and did **not** re-derive the 1,203 figure
([S2-EXEC-04-evidence-and-hash-manifest.md](S2-EXEC-04-evidence-and-hash-manifest.md) §Part E, OPEN-8). Both numbers are
probably correct on their own basis; the prior report did not label which basis it used. Reported as a **basis defect**,
not a value conflict.

---

## 3. Object coverage totals by category

22 categories, each classified with the mandated six-term vocabulary. Full per-category evidence chains in
[S2-EXEC-04-object-coverage-matrix.md](S2-EXEC-04-object-coverage-matrix.md).

| # | Category | Expected | Emitted active | State |
| --- | --- | --- | --- | --- |
| 1 | Extensions | **UNKNOWN** (no `pg_extension` query exists) | 0 | `MISSING — SOURCE EVIDENCE ABSENT` |
| 2 | Schemas (application) | 2 | 2 | `PRESENT — SOURCE VERIFIED` |
| 3 | Tables | 19 | 19 | `PRESENT — SOURCE VERIFIED` |
| 4 | Columns & data types | 183 | 183 | `PRESENT — PARTIAL` (collation/domain never captured) |
| 5 | Defaults & identity | 69 defaults / identity **UNKNOWN** | 69 | `PRESENT — PARTIAL` |
| 6 | Primary keys | 19 | 19 | `PRESENT — SOURCE VERIFIED` |
| 7 | Foreign keys | 44 | 44 | `PRESENT — SOURCE VERIFIED` |
| 8 | Unique constraints | 9 | 9 | `PRESENT — SOURCE VERIFIED` |
| 9 | Check constraints | 65 | 65 | `PRESENT — SOURCE VERIFIED` |
| 10 | Indexes | 62 | 34 (+28 via constraints) | `PRESENT — SOURCE VERIFIED` |
| 11 | Functions & overloads | 38 / 0 overloads | **0** | `MISSING — SOURCE EVIDENCE ABSENT` (executable object) |
| 12 | Function return types & args | args 38; RT 14 narrative + 24 absent | **0** | **`CONFLICT — SOURCE DISAGREEMENT`** |
| 13 | Function security properties | 38 definer + search_path | 0 | `PRESENT — PARTIAL` (24 owners INFERRED) |
| 14 | Triggers on `public` tables | 7 | **0** | `PRESENT — PARTIAL` (blocked) |
| 15 | RLS enable / forced state | 19 enabled, 0 forced | 19 ENABLE | `PRESENT — SOURCE VERIFIED` |
| 16 | RLS policies | 21 | **0** | `PRESENT — PARTIAL` (blocked; 4 over-blocked, §8-B6) |
| 17 | Grants & ACLs | q6 149 / q1 320 (Δ 171) | 235 | `PRESENT — PARTIAL` + conflict flag |
| 18 | Default privileges | 24 rows / 70 entries | 13 | `PRESENT — PARTIAL` |
| 19 | Realtime publication membership | **UNKNOWN** (doc asserts 4) | 0 | `MISSING — SOURCE EVIDENCE ABSENT` |
| 20 | Auth-related configuration | partial; 2 toggles never captured | 0 | `UNVERIFIED — SOURCE AMBIGUOUS` |
| 21 | `auth.users` trigger | 1 | 0 | `PRESENT — PARTIAL` (isolated, blocked) |
| 22 | Platform-level non-SQL configuration | roles evidenced; WAL/vault/Edge/views UNKNOWN | 0 | `MISSING — SOURCE EVIDENCE ABSENT` |

**Tally (22 categories): 8 `SOURCE VERIFIED` · 8 `PARTIAL` · 4 `MISSING` · 1 `UNVERIFIED` · 1 `CONFLICT`.**
Object-level records across the countable categories: **858**.
Categories with **no countable population** stay `UNKNOWN` — extensions, views/materialised views, sequences, object
comments, storage parameters, identity/generated columns, publication membership. `UNKNOWN` means *the evidence series
cannot see the class*, and is **not** an empty set; a "successful" load would silently omit whatever is in them.

Against the artefact's own `91-coverage.md`: **agreement on 20 of 22 rows**; the two divergences are category 12
(this audit says 14 narrative return types exist in-repo; the prior said 0/38) and category 20 (unscored by the prior).

---

## 4. Function-body coverage and the status of the 24 absent bodies

Register: [S2-EXEC-04-function-coverage-register.md](S2-EXEC-04-function-coverage-register.md) (38 rows, per-object, with
body↔row bound by exact triple match on `schema_name`+`function_name`+`arguments` — 14/14 matched, **no orphan bodies, no
name-only borrowing**).

| Measure | Value | Evidence |
| --- | --- | --- |
| Functions inventoried | **38** = 14 `public` + 24 `private` | `g1-b3b-20261029.json` `inventory.rows` (b3b:43-81) |
| Bodies **present** in evidence | **14** = 12 `private` + 2 `public` | b3b `bodies[]` (b3b:84-168) |
| Bodies **absent** from evidence | **24** = **12 `public` + 12 `private`** | derived by set difference over the 38-row inventory |
| Return types from **catalogue** captures | **0 / 38** | no `prorettype` column exists in q7, q10 or b3b |
| Return types from **narrative** capture | **14 / 38**, `public` names only | `docs/stage1/evidence/functions-and-triggers.md:34-49` (120 L, `835f7660…`) |
| Executable `CREATE FUNCTION` emitted | **0 / 38** | parser, `40-functions.sql` (865 lines, 0 active) |
| Overloads | **0** same-schema overloads; **13** cross-schema name twins | register §1.4 |
| Objects blocked behind the function cliff | **8 triggers** (7 + 1 on `auth.users`), **21 policies**, **4 publication adds** | `50`/`55`/`60`/`80` all 0 active |
| Bodies recovered by repo-wide search | **0 of 24** — 79 files searched; no migrations, no `supabase/functions`; the patches define only already-captured bodies plus one new function | register §"MISSING", consolidated report §4 |

**Nothing was invented.** No body, return type, empty stub or placeholder function was written anywhere in this phase, in
the artefact or in a report. All 24 absent bodies read `UNVERIFIED` / `MISSING — SOURCE EVIDENCE ABSENT`. No function is
marked "unused" — there is no invocation evidence for any of the 24 unread ones, so that claim would itself be a guess.

**Two prior claims were refuted and are corrected here rather than smoothed over:**

1. **"24 *private* function bodies are missing" is wrong as to composition.** The count (24) is right; the label is not.
   The absent set is **12 `public` + 12 `private`**; the 12 `private` bodies that *are* in evidence were read verbatim.
   The mislabel is inherited by the brief's own §6 H-2 and by `90-limitations.md:126` (L-2). `93-counts.json`'s "24" is
   correct and stays.
2. **"0 of 38 return types captured" needs its scope stated.** It is true of **raw catalogue captures**; it is not true
   of the corpus, because `functions-and-triggers.md` §1 carries a `Returns` column for the 14 `public` functions. That
   narrative source cannot be upgraded to `SOURCE VERIFIED` (it is a dashboard-derived note, labelled as such at
   `g1-run-manifest-20261029.md:59`), and for the 13 twin names it cannot be bound to `private` at all
   (register §D U-1/U-2). **This does not change the verdict:** the 14 public return types do not unblock the 24 private
   helpers, do not supply the 24 absent bodies, and cannot be cross-checked against a body that was never captured. It
   does change what a future *offline* build pass could legitimately emit for the `public` set.

**The blocking mechanism is also different from what the record says.** The prior framing was "the bodies are missing,
therefore nothing can be emitted." Measured against `g1-q2` predicate text, **25 of the 29 captured dependents**
(8 triggers + 17 policies) are blocked on functions whose **bodies are already present** — the missing element is
`prorettype`, not `prosrc`. Four policies (`families_update_owner`, `profiles_update_self`,
`webrtc_signals_insert_participant`, `webrtc_signals_select_participant`; `q2[6],[11],[19],[20]`) reference only
`auth.uid()` and plain SQL, were never blocked by the function cliff at all, and were batch-suppressed with the rest —
they are **offline-emittable today** (`60-rls-policies.sql:52,59,71-76`).

**Sharpened 2026-11-03, measured independently of S2-A3:** those 25 blocked dependents turn on only **9 distinct
functions**, and **all 9 bodies are already in evidence** (`g1-b3b-20261029.json` `bodies[]`). The 17 blocked policies call
exactly one helper each — `private.is_family_parent` ×13, `private.is_family_member` ×3, `private.shares_active_family` ×1
(re-counted from `g1-q2`: 21 rows, 17 with a `private.*` call, 4 with none). The 8 triggers reference
`audit_logs_append_only`, `families_before_update`, `handle_new_user`, `profiles_before_update`,
`remote_session_transition_guard`, `set_updated_at` (`g1-q3` ×7 + `g1-q3b` ×1 — 6 distinct names, all bodies captured).
**So the whole behavioural layer is gated on 9 return types, not on 24 lost bodies.** Two caveats that keep this from being
a green light: usage context constrains but does not *capture* the type (`USING (<call>)` with no comparison forces a
boolean-typed expression; a trigger function must be `RETURNS trigger` — an inference from the call site, which the
programme's rules currently forbid as a guess), and **`provolatile`/`proisstrict`/argument modes were never captured**, so
functions authored from defaults would silently diverge from production. This is an **owner admissibility ruling**, not an
offline build step, and it does not change this report's verdict.

---

## 5. Structural findings by severity

Full detail with `file:line` for every finding in
[S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md). Count: **CRITICAL 0 · HIGH 3 · MEDIUM 5 ·
LOW 4 · INFORMATIONAL 4.**

| ID | Severity | Finding | Load consequence |
| --- | --- | --- | --- |
| — | **CRITICAL** | **None.** No active statement performs DML, drops an object, touches a platform-managed schema or embeds a production connection target. Verified absence by grep over non-comment lines of all 11 files; active first-token vocabulary = {CREATE, ALTER, GRANT} only | The worst a load can do is availability/parity damage, not data damage |
| H-1 | HIGH | 19 `ENABLE ROW LEVEL SECURITY` with 0 emitted policies on tables carrying live `authenticated` write grants | `authenticated` reads return **0 rows**; writes fail `42501`; default-deny (no confidentiality exposure, total availability loss). Any later equivalence validation would measure a dead schema |
| H-2 | HIGH | The function cliff: 0 executable function DDL cascades to 8 triggers + 21 policies + 4 publication adds + the `auth.users` trigger | Structural shell with **zero behaviour**; permanently non-equivalent under current evidence. **Not offline-resolvable** |
| H-3 | HIGH | 12 `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin` (`70:323-338`) may abort the load at **statement #448**; `g1-q6.role_memberships` (24 rows) carries no evidence that `postgres` is a member of `supabase_admin` | With **no transaction wrap**, statements 1-447 persist while the remaining 12 never run → staging ACL divergent from intent and from production `pg_default_acl`. Needs one `pg_auth_members` probe inside the A3 window |
| M-1 | MEDIUM | **0** `BEGIN`/`COMMIT`/`ROLLBACK` anywhere in 11 files | Every partial-load scenario is possible; two concrete partial states enumerated |
| M-2 | MEDIUM | Undecoded privilege letters and grant-option `*` rendered as `???*` inside commented ACL lines (`70:293-295,343`) | None on load (commented, grantee platform `postgres`). It refutes the flat claim "0 leaked fragments": correct scope is "0 in **active** statements, 6 markers in commented lines" |
| M-3 | MEDIUM | Python `None` leaked into two policy comments as `USING (None)` (`60:62,71`) | None today; **invalid SQL** if ever uncommented during A3 authoring. Correct rendering is to omit `USING` where `qual` is null |
| M-4 | MEDIUM | No `GRANT USAGE ON SCHEMA private`, although the evidence records it (`00:45`) | When functions are eventually authored, `authenticated` policies calling `private.*` fail `10503` — re-blocking the policy layer for an **evidenced** reason |
| M-5 | MEDIUM | 37 of 44 FKs emitted with unqualified `REFERENCES` targets, binding at load time to the loader's `search_path` | Valid on Supabase's default path; recorded as a `SET search_path` precondition |
| L-1 | LOW | `96-review-checks.md:36` says trigger functions were verified against "the 25-row inventory"; the inventory is 38 rows | Doc defect only; the 6 trigger-referenced functions **are** all present |
| L-2 | LOW | `CREATE SCHEMA IF NOT EXISTS public` is a permanent no-op NOTICE | Harmless, self-describing |
| L-3 | LOW | Emitted anon/authenticated default-privilege writes mirror production | Faithful and evidenced; do **not** revoke (revoking would diverge from the captured state); note in A3 rehearsal |
| L-4 | LOW | `private.remote_session_transition_guard` has `acl=null` = default PUBLIC EXECUTE with `anon_exec=True` | Any future DDL that omits `REVOKE … FROM PUBLIC` reproduces an anon-executable trigger function |
| I-1…I-4 | INFO | `gen_random_uuid()` resolves as a PG13+ built-in; `55` is a standalone no-op (0 active) and is physically excluded from the assembled file; no `ALTER SYSTEM`/`SET SESSION` exists | Verified, no action |

### Anchored correction to H-3 — issued 2026-11-03 after S2-A3 (original wording above preserved)

The prose figure "**12** `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin`" is **wrong**; the three line cites in the same
row (`70:323-325, 328-330, 336-338`) were always correct and enumerate **9**. Re-counted from the file this pass:
**13 active ADP statements total → 9 `FOR ROLE supabase_admin` (`70:323,324,325,328,329,330,336,337,338`) + 4
`FOR ROLE postgres` (`70:321,332,333,334`)**. The "12" is the length of the **never-run tail** after a failure at statement
#448 (statements #448-459 = 12), mislabelled as a role count — the same arithmetic that produced "236/248 section-70
grants persist" in M-1 (248 − 12 = 236), which is correct *as a persisted count* and is **not** the emitted-grant count
(235 `GRANT` statements). **Consequences unchanged:** the membership risk, the absent transaction wrap, and the need for a
`pg_auth_members` probe all stand. **Severity unchanged: HIGH.** Recorded here rather than silently edited, because this is
a dated audit record; the same correction is carried in [S2-EXEC-FINAL.md](S2-EXEC-FINAL.md) §4.

**Dependency order: PASS.** Component sequence matches A0's amended 15-step order; last PK statement (`20:39`) precedes
the first FK (`20:120`); **0** FKs reference a table whose backing constraint is created later; 0 duplicate statements;
assembled ≡ exact ordered concatenation of the 9 components minus 55 (set-diff empty both directions).
**Index suppression: verified exactly** — the 28 suppressed are the 19 `*_pkey` + 9 `*_key`, each also emitted as a
constraint; 62 = 34 + 28 with nothing dropped by mistake.
**Grants: evidence-bound** — 149/149 table triples and 191/191 column triples reproduced, 0 missing 0 extra, 0 `WITH
GRANT OPTION` (matching `is_grantable='NO'` on all 149), 0 `REVOKE`.

**Rollback: assessed, not claimed.** The artefact contains no rollback component. A reverse-order teardown is derivable
from the dependency graph; but the 13 ADP statements are **not self-reversing** (no "restore previous" form exists and no
staging prior state was ever captured), **no statement uses `IF NOT EXISTS`** so a retry after a partial load fails
immediately at `asm:56` `42P07 already exists`, and the plan has **no backups and no PITR**
([04](04-risks-rollback-approvals.md):93 R-35). **No rollback has been tested anywhere in this programme and none is
claimed to work.**

---

## 6. Secret-scan evidence assessment

Per the brief's §6 instruction — *"If the scan cannot be tied to the exact artefact hash, classify it as `NOT VERIFIED`"*
— the honest position has two halves, and they point in different directions.

| Question | Finding | Class |
| --- | --- | --- |
| What was scanned | 13 files of the 22 in the build directory; the scan report's own file list | scope **incomplete** |
| Does the scanned content equal the artefact of record? | **Yes** — the same bytes hash to `fc996f45…` raw and to the recorded `efdbf985…` after CRLF→LF. Demonstrated by read-only re-hash in this audit ([S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md) M-06), and no post-scan hand-edit survives the comparison | **MET in substance** |
| Does the scan **report** state its normalisation or carry the raw-byte digest? | **No.** Neither `95-secret-scan.md` nor any pre-existing document states the method (repo-wide grep for `fc996f45`/`efdbf985` found nothing before this pass) | record **NOT VERIFIED** |
| Pattern taxonomy | 16 credential patterns + 3 PII classes treated as stop conditions — the prior text described "19 credential-shaped patterns plus 3 PII", which mis-splits the taxonomy | label defect, corrected |
| Result as reported | 0 matches, 0 stop conditions, within the scanned scope | reproduced independently: **0 in scanned scope** |
| Pattern-shaped strings outside the scanned scope | **71** in the digest lists / generator scripts (values deliberately not reproduced here) | unscanned, not cleared |
| Does the scan cover the places a literal could still hide? | **No** — 24 bodies were never captured, so the scanner never read 24 of the places a pasted literal could live | structural limit |
| Any credential value printed in any report? | **No.** Findings are file + location + type only | compliant |

**Verdict on the precondition:** the scan **is** of the exact artefact, but the **binding is not self-evidencing and the
scope is 13/22**, so under §6's own rule the *record* stands at **`NOT VERIFIED`** — closable offline by re-hashing with a
stated normalisation and re-scoping to all 22 files. This is a documentary and scope gap, not evidence of a leak.

**Standing caveat, retained verbatim in force: a result of zero pattern matches is not proof that the artefact contains no
secrets.** The artefact remains outside the repository; a clean scan is not permission for it to enter
(`S2-EXEC-03-documentation-reconciliation-report.md` §8, R-5).

---

## 7. A3 precondition matrix

Full 24-row matrix with `file:line` evidence for every cell:
[S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md).

| Set | MET | NOT MET | NOT VERIFIED | NOT APPLICABLE |
| --- | --- | --- | --- | --- |
| The ten preconditions named by the brief (§7) — M-01…M-10 | **4** (M-01 A0 decision, M-06 scan substance, M-09 provenance, M-10 rollback *assessment*) | **4** (M-03 sentinel, M-04 A3 signature, M-05 `auth.users` count, M-07 reconstruction sufficiency) | 1 (M-08 dependency order — *demonstrable only by a load, which is excluded*) | 1 (M-02 A1, correctly removed from A3's chain by C-2) |
| Fourteen further preconditions the plan of record itself requires — M-11…M-24 | 2 | 6 | 5 | 1 |
| **Matrix total, 24 rows** | **6** | **10** | **6** | **2** |

Gate states restated for the owner, unchanged by this audit:

| Gate | State | What this audit did **not** do |
| --- | --- | --- |
| A0 | **MET as a recorded decision** — method amended to offline reconstruction; **physical signature fence remains unfilled** | did not fill or draft a fence |
| A1 | **`INOPERATIVE`** — no production read permitted; not a precondition of A3 | performed no production read; proposes none as a substitute |
| A2′(a) sentinel | **NOT MET** — unsigned and `private.s2_environment` not created (verified absent: staging has 0 tables) | did not create or modify a sentinel |
| A3 | **NOT MET** — unsigned; `approval-package-v2:302-304` forbids filling the fence on the assumption a baseline exists | did not sign, load, or execute schema SQL |
| `auth.users` exact count | **NOT MET / `NOT VERIFIED`** — authorised only as the *first statement inside a signed A3 window*; **not run** | ran nothing |
| G3 reconstruction sufficiency (M-07) | **NOT MET** — 0 of the behavioural classes are emittable | did not invent definitions |
| Secret scan bound to final hash | substance **MET**, record **NOT VERIFIED** (§6) | modified no file in the artefact directory |
| Rollback | **MET as an assessment only** — "correctly assessed, not claimed" ≠ "rollback works"; substantive capability absent | tested nothing |
| A9 credentials / A12 Firebase app+FCM | **NOT MET** — unsigned; both operations prohibited | generated no credential; registered no app |
| A2′(b) settings + Realtime | **NOT APPLICABLE as an A3 precondition** — it is the *post-load* half of Sequence A | did not treat it as a blocker or act on it |
| A5 patches P01/P02/P03 | approved in principle, **not executable**; all three files re-verified **byte-identical** to the digests recorded before correction (`1edad404…`, `01403cd7…`, `8f92cc0f…`) | did not edit or apply any patch |

---

## 8. Exact blockers

Ordered so that the first is the only one that can change the verdict.

| # | Blocker | Class | Only thing that closes it |
| --- | --- | --- | --- |
| **B1** | **0 of 38 return types in catalogue form ⇒ 0 executable functions ⇒ 0 triggers, 0 policies, 0 publication, 0 `auth.users` trigger.** Behavioural parity is unreachable and G3-d equivalence validation cannot be performed | `CRITICAL` | A **`pg_get_functiondef` / `prorettype` capture** = a production read, i.e. an owner ruling that changes the staging-only absolute (C2b/R-43) and re-activates A1 or a replacement — **or** owner-authored function DDL — **or** an owner decision to accept a structural-only baseline with the acceptance text re-worded |
| **B2** | **24 of 38 bodies absent** (12 `public` + 12 `private`); 0 recoverable from any authorised source | `CRITICAL` | Same read class. A5's D-06 `prosrc` hash validation is **unsatisfiable** for these 24 — there is nothing to hash |
| **B3** | **H-3**: 9 `FOR ROLE supabase_admin` ADP statements (13 emitted in total; see the anchored correction after §5) whose grantor-role membership is unevidenced, combined with **M-1** no transaction wrap ⇒ a load can half-apply and stop at statement #448, leaving the final 12 statements unrun | `HIGH` | One `pg_auth_members` probe inside the A3 window + an owner decision to rewrap/batch |
| **B4** | **Seven `UNKNOWN` populations** (extensions, views, sequences, comments, storage params, identity/generated columns, publication membership) — classes the whole evidence series cannot see | `HIGH` | New capture queries; identity/sequence divergence is data-loss-level if any load ever moves rows |
| **B5** | **S4-BL-01**: no document recorded a raw-byte digest until this pass; the artefact of record sits in an OS-temp directory over **zero commits** | `HIGH` | Bind the digest in A3's change record + an owner-named durable home. **Offline-possible, owner-instructed** |
| **B6** | **4 over-blocked policies** emitted as suppressed although `auth.uid()`-only and offline-emittable | `MEDIUM` | An offline build pass under A0 as amended (still not a load) |
| **B7** | **M-4**: evidenced `GRANT USAGE ON SCHEMA private` never rendered | `MEDIUM` | Offline build pass |
| **B8** | **S4-BL-08**: `01:252` defines the A3 deliverable as "19 tables / **38 functions** / **21 policies** / triggers / grants" — unmeetable by this artefact | `HIGH` | Owner decision: amend the checklist row or accept the re-scoped G3 |
| **B9** | **S4-BL-03 (governance)**: a reader could sign A3 believing a baseline exists — §3.4's preconditions never say "policies emitted" or "behaviour parity achievable" | `CRITICAL` (safety) | An explicit written owner ruling on whether A3 may be signed against a structural-only artefact |
| **B10** | **S4-BL-07**: the *channel* has never been demonstrated — no SQL Editor session has ever been opened by this programme, the last authorised browser session failed every click, and a 459-statement paste must yield a per-statement log in an autocommitting editor | `HIGH` | An authorised operational action inside a signed window; signature alone does not create a channel |
| **B11** | **S4-BL-10 (time-critical)**: auto-pause dated touch due **on or before 2026-11-06**; no UTC start recorded; no document assigns the obligation | `HIGH` | Owner instruction (§9 below) |
| **B12** | **`g1-q7` schema-less rows (18) + 13 cross-schema name twins** ⇒ language/volatility/owner unattributable for the `private` set | `MEDIUM` | Production read; correct to leave `UNVERIFIED` meanwhile |
| **B13** | **`is_grantable` absent** on the 191 column-grant rows ⇒ "no grant option there" is an assumption | `LOW` | Disclosed, not asserted; a capture column would close it |

---

## 9. Auto-pause obligation (§9 of the brief)

- The documents record a **dated staging dashboard touch due on or before 2026-11-06**
  ([04](04-risks-rollback-approvals.md):98 R-40).
- Status: **`NOT EXECUTED IN THIS PHASE`**. Owner action remains required and unassigned.
- **No exact UTC expiry or start time is recorded anywhere**, so the clock cannot be computed, only described.
- The last authorised read-only observation of staging is **2026-11-02T07:16Z** — a **historical record**. This report
  does **not** claim staging is currently active, healthy, empty or configured, and does not open the dashboard.
- The cleanest "touch" available would be the A3 load itself; A3 is unsigned, so it is not available to this pass.

---

## 10. What can be resolved offline · what needs new evidence · what needs an owner decision · what stays prohibited

**Resolvable offline, no new approval (but each still needs an owner instruction before anything is emitted, because the
artefact is frozen pending review):**
- Emit the 4 `auth.uid()`-only policies and the `GRANT USAGE ON SCHEMA private` line (B6, B7).
- Add the 14 evidenced `public` return types + `g1-q10` owner/`search_path`/per-role EXECUTE attributes to the register
  and the artefact's comment layer — as *evidenced narrative*, never as `SOURCE VERIFIED`.
- Wrap the assembled file in `BEGIN; … COMMIT;` (R1), with a batching note for `statement_timeout=8s` (`00:44`).
- Fix the generator so `???*` and `USING (None)` are re-rendered from `g1-q6`/`g1-q2` rather than hand-edited (R4) —
  provenance labels stay intact only if regenerated.
- Re-emit the scan report with its stated normalisation and the raw-byte digest, scoped to all 22 files (B5's twin, S4-BL-02).
- Documentation corrections: CF-01…CF-21 in the conflict register, incl. the "24 private"→12+12, "0/38 RT"→scope,
  "21 vs 17 policies", "0 leaked fragments"→"0 active", 42/48→40+2 scope-qualified, "four fences"→8, patch "Bytes"→lines.

**Requires additional source evidence (a new capture of a class never captured):** the 38 return types and 24 bodies;
`pg_extension`; publication membership; views/sequences/comments/identity; `pg_auth_members` membership of
`supabase_admin`; staging prior `pg_default_acl`. On Supabase, most of these are only reachable through a **production
read**, which the staging-only absolute bars — see the next column.

**Requires a separate owner approval or ruling:** A2′(a) sentinel · A3 load (and the `auth.users` count as its first
statement) · A2′(b) settings + Realtime · A5 execution · A9 credentials · A12 Firebase app + FCM · a **new ruling that
changes C2b/R-43** if any production read is to be permitted · a written ruling on B9 (may A3 be signed against a
structural-only baseline?) · an owner instruction for the 2026-11-06 touch · an owner-named durable home for the artefact.

**Remains prohibited to this and every subsequent agent pass, absent a signed gate:** any SQL execution or schema load ·
any dashboard write · sentinel creation · patch application or edit · reading, generating or exposing any credential, key
or PII value · Firebase app registration, provider enablement, FCM configuration or credential generation · Firestore,
Firebase Cloud Functions or Analytics enablement · opening or inspecting `parent-control-prod` in any form · any CLI/REST/
direct-DB route around the browser dashboards · filling or dating a signature fence on the owner's behalf · Git commit or
any history mutation (the repo remains at **zero commits**).

---

## 11. Evidence labelling, and how much of this report is independent

**Verified (re-measured in this pass or by an independent domain auditor, file/line/hash cited above):** 459 statements
and the per-component split · 150,566 bytes / 1,951 lines / 661+1,186+104 composition · both digests and their
normalisation relationship · 0 active function/trigger/policy/publication/extension statements · 19/19 tables and 183
columns and 137/137 constraints character-matched to `g1-q5` · 34+28 index suppression exact · 149/191 grant triples with
0 missing and 0 extra · 38-function inventory 14 `public`/24 `private`, 14 bodies, 24 absent · 0/38 catalogue return types
· 14 narrative return types in `functions-and-triggers.md:34-49` · 0 transaction wrapper · 0 DML/DROP/REVOKE/ALTER SYSTEM ·
patches byte-identical to recorded digests · 53 → **17** evidence files · 56 → **19** q9/q10 rows · q9 = production
Security-Advisor lint (5 findings incl. `rls_enabled_no_policy`), q10 = 14-row `public` function inventory · the two
"missing" documents present and digested (`835f7660…`, `5445c69a…`).

**Inferred (plausible, load-time consequences not testable offline):** the environment-specific first-failure positions
(asm:1888 on Supabase if H-3 fires; asm:281 on bare Postgres) · RLS default-deny read-empty behaviour · the reverse-order
teardown sketch · that `public` wrappers delegate to their `private` twins (2 read pairs only; the other 12 wrappers are
`INFERRED`, not read — `reports/stage1-final.md:91`).

**Missing evidence:** named at §8 B1-B4 and §10 column 2. **`UNKNOWN` is recorded as `UNKNOWN`, never as zero.**

**Unverified claims I declined to repeat:** that the artefact contains no secrets · that a rollback would work · that
staging is currently healthy · that `supabase_admin` membership is or is not present on fresh staging · that the 24 unread
functions are unused · that the 4 policies are *actionable* (they are *emittable*, which is different — emitting is A3-gated).

**Recommendations:** (a) decide B9 before considering any signature; (b) if the programme's ceiling is to be accepted,
re-word `01:252`, §3.4 and `90-limitations.md:126` so the acceptance criterion matches the deliverable; (c) close S4-BL-01
and S4-BL-02 offline; (d) run the offline build pass that emits B6/B7 and re-hash; (e) put the `pg_auth_members` +
`pg_default_acl` + `pg_extension` probes into the opening checklist of whatever window ever gets signed; (f) treat the
14 narrative return types as a *scope question for the next build*, not as an unblocker.

**Independence accounting for this headline report** (disclosed because §4's rule — "a report is not complete merely
because the agent produced a file" — cuts both ways): five domain reports were produced by five separate auditors and
read by me; **two domains (secret-scan review, cross-check) returned findings in conversation only, by instruction**, and
are carried here at §6 and §3/§4; **the four artefact-less figures in §3's object-record total (858) and the conflict
tally were consolidated by me** from the landed reports and independently spot-checked. Where a domain auditor's number
and my own re-measurement disagreed, the conflict is preserved (§3 vs `91-coverage.md`; §4 items 1-2; §6) rather than
resolved by preferring the more convenient claim.

---

## 12. Deliverable map (§10 of the brief)

| # | Deliverable | File | Status |
| --- | --- | --- | --- |
| 1 | Independent G3 audit report | **this file** | complete (written last, because it consolidates 2-5) |
| 2 | Object coverage matrix | [S2-EXEC-04-object-coverage-matrix.md](S2-EXEC-04-object-coverage-matrix.md) | 478 L, complete |
| 3 | Function coverage register | [S2-EXEC-04-function-coverage-register.md](S2-EXEC-04-function-coverage-register.md) | 346 L, complete |
| 4 | SQL structural findings | [S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md) | 134 L, complete |
| 5 | A3 precondition matrix | [S2-EXEC-04-a3-precondition-matrix.md](S2-EXEC-04-a3-precondition-matrix.md) | 362 L, complete |
| 6 | Evidence and hash manifest | [S2-EXEC-04-evidence-and-hash-manifest.md](S2-EXEC-04-evidence-and-hash-manifest.md) | 988 L; complete on hashes, **three headline figures false** (53 files / 56 rows / "22-file hash list") — corrected at §11 and in the S2-EXEC-05 conflict register, CF-02/03/05 |

Downstream consolidation: [S2-EXEC-05-seven-agent-consolidated-report.md](S2-EXEC-05-seven-agent-consolidated-report.md),
[S2-EXEC-05-cross-agent-conflict-register.md](S2-EXEC-05-cross-agent-conflict-register.md).

---

## 13. Final verdict

The artefact is structurally complete **for the classes the authorised evidence describes** and is faithful to them; it
is behaviourally empty for every class that requires a function definition, and seven object classes cannot be counted at
all because no query in the G1 series ever saw them. Required definitions — 38 return types in catalogue form, 24
function bodies, extensions, publication membership, identity/sequences — are absent and cannot be recovered offline
without inventing them, which this pass did not do.

`S2-EXEC-04 COMPLETE — A3 READINESS: NOT LOAD-READY — RECONSTRUCTION GAPS`
