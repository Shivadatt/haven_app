# S2-EXEC-09 — A3 staging load, independent release verification

| Field | Value |
| --- | --- |
| Date | 2026-11-03 |
| Reviewer | IMP-8 (release verifier, adversarial) |
| Artefact reviewed | `D:\control\docs\stage2\migrations\A3-staging-load-v1.sql` |
| Measured size | **157,738 bytes** (matches author) · **1,575 content lines** + trailing newline (1,576 on split) · **0** CRLF sequences · **0** non-ASCII bytes |
| Operations performed | **Zero terminal. Zero CLI. Zero Bash. Zero shell. Zero curl. Zero REST. Zero database connection. Zero browser. Zero dashboards visited. Zero SQL executed anywhere.** |
| Methods actually used | `Read` (targeted ranges), `Glob` (existence), `Grep`/ripgrep with explicit anchored patterns (primary counting method), local JS arithmetic/JSON parsing for set-diffs and paren-balance (`node-repl`, local computation only — no parser installed or run), and file inspection of `.git` internals |
| What I re-counted | Line-start statement census; constraint-kind sub-counts; grant composition; FK qualification; column definitions; policy predicate text vs `g1-q2`; commented policy/trigger/publication counts; dangerous-verb sweep; production-ref sweep; evidence-tag coverage; forward+reverse statement diff against `g3-reconstruction-2026-11-02.sql` |
| Explicitly NOT done | No pglast or any SQL parser was run (author's "486 statements parse" claim is therefore **CANNOT DETERMINE** — see §2.4). No digest was computed (the source SHA-256 was cross-read from the artefact's own `100-file-hashes.txt`, not recomputed). |
| Git state | Verified **by file inspection only, git was never run**. `D:\control\.git` contains `HEAD`, `config`, `description`, `info/exclude`, `hooks\*.sample` **only** — there is no `refs/`, no `objects/`, no `packed-refs`, no `logs/`, no `index`. `HEAD` = `ref: refs/heads/master` (a dangling symref). ⇒ **zero commits, nothing staged**, consistent with the file's claim at `:1463` and approval-package-v3 `:449`. |
| Live staging state used | `S2-EXEC-06` — `public` = 0 tables; sentinel `private.s2_environment` **NOT CREATED** (`A2′(a)` blocked); 0 Edge Functions; email provider ENABLED; SQL Editor unusable. |

---

## §1 Verdict

# NO-GO

The file is **not** a safe paste candidate in its current form, and `A3` **must not be signed on it**. Two binding preconditions of the very instrument it is built to satisfy are absent from it, its headline safety control is overclaimed and cannot discriminate the project, and its headline behavioural claim ("these 4 policies restore X") is not supportable and would seed a false `PASS` downstream.

**Not softenable, and to be stated without flattery:** every count the author published is **correct** (I reproduced all of them independently), the deviation register is **clean** (I found **zero undeclared statement changes** against the source artefact — the hardest thing to get right, and they got it right), and the file is honest in prose about the deny-all ceiling. The NO-GO is **not** about arithmetic or honesty of intent. It is about (a) two unmet `A3` preconditions, (b) a wrong-project control that is weaker than the file says, and (c) an efficacy claim on the 4 policies that the load's own RLS state defeats.

All six NO-GO items in §8 are **repairable offline within the same file** — none needs new cloud evidence except the one already gated on `A2′(a)`. See §9.

---

## §2 Recounted numbers, with units and method

Unit: **one statement = one top-level `;`-terminated SQL statement whose text begins at column 0** (the file is written one-statement-per-line, so a line-start keyword census is exact here). I verified the premise: the *only* active lines not beginning a statement are the interior of the `DO` block (`:109-118`) and the continuation lines of the 4 policies (`:746,:747,:754,:755,:761,:773`). No statement is hidden in indentation.

### 2.1 Raw grep output (unlimited head_limit), my method reproduced

| Pattern (anchored, case-sensitive) | Raw count |
| --- | --- |
| `^CREATE` | 59 |
| `^CREATE SCHEMA` | 2 |
| `^CREATE TABLE` | 19 |
| `^CREATE (UNIQUE )?INDEX` | 34 |
| `^CREATE POLICY` | 4 |
| `^ALTER` | 169 |
| `^ALTER TABLE` | 156 |
| `^ALTER TABLE .*ADD CONSTRAINT` | 137 |
| `^ALTER TABLE .*ADD CONSTRAINT \w+ PRIMARY KEY` | 19 |
| `^ALTER TABLE .*ADD CONSTRAINT \w+ UNIQUE` | 9 |
| `^ALTER TABLE .*ADD CONSTRAINT \w+ CHECK` | 65 |
| `^ALTER TABLE .*ADD CONSTRAINT .*FOREIGN KEY` | 44 |
| `^ALTER TABLE .*ENABLE ROW LEVEL SECURITY` | 19 |
| `^ALTER DEFAULT PRIVILEGES` | 13 |
| `^GRANT` | 236 |
| `^GRANT USAGE ON SCHEMA` | 1 |
| `^GRANT .+ ON TABLE .+ TO .+;` | 52 |
| `^GRANT UPDATE \(` | 183 |
| `^DO \$\$` | 1 |
| `^SELECT` | 19 |
| `^BEGIN` / `^COMMIT` | 1 / 1 |

Arithmetic: `59 + 169 + 236 + 1 + 19 + 1 + 1 = 486` total executable statements.
Load-affecting = `486 − 19 (read-only) − 2 (transaction control) = **465**`.
Constraint-kind check: `19 + 9 + 65 + 44 = 137` ✔. Grant composition check: `1 + 52 + 183 = 236` ✔.

### 2.2 Claim-by-claim adjudication (14 numeric claims, 10 property claims P1–P10)

| # | Author claim | My measured number | Verdict |
| --- | --- | --- | --- |
| 1 | 19 `CREATE TABLE` | 19 | **CONFIRMED** |
| 2 | 137 constraints | 137 (19 p / 9 u / 65 c / 44 f — all four sub-counts also match) | **CONFIRMED** |
| 3 | 34 indexes | 34 (31 `CREATE INDEX` + 3 `CREATE UNIQUE INDEX` by my sub-count, matching source `93-counts.json`) | **CONFIRMED** |
| 4 | 2 `CREATE SCHEMA` | 2 | **CONFIRMED** |
| 5 | 19 `ENABLE RLS`, 0 `FORCE` | 19; `FORCE ROW LEVEL SECURITY` appears only in prose at `:701` → 0 active | **CONFIRMED** |
| 6 | 4 policies active / 17 commented | 4 active (`^CREATE POLICY`); 17 commented at `:785-789,796-803,808-809,812-813` (I enumerated all 17 names and matched each to a `g1-q2` row) | **CONFIRMED** |
| 7 | 236 grants | 236, composition `1 schema USAGE + 52 table + 183 column` — exactly as `:842` and `:1479-1481` state | **CONFIRMED** |
| 8 | 13 `ALTER DEFAULT PRIVILEGES` | 13 (lines 1227,1229,1231,1233 postgres-grantor; 1237-1253 supabase_admin-grantor) — `4 + 9` as declared in D-4 | **CONFIRMED** |
| 9 | 1 `DO` | 1 (`:108`) | **CONFIRMED** |
| 10 | 465 load-affecting active | 465 | **CONFIRMED** |
| 11 | 19 read-only verification SELECTs (V-1..V-15) | 19 `^SELECT`, all read-only; labels V-1..V-15 present, multi-part checks (V-8,V-10,V-11,V-14) account for 19−15 = 4 extra | **CONFIRMED** |
| 12 | 486 total | 486 | **CONFIRMED** |
| 13 | File is 157,738 B / 1,575 lines | 157,738 B / 1,575 content lines | **CONFIRMED** |
| 14 | Source = 459 active statements, digest `fc996f45…908f6` | `93-counts.json:15` = 459 (and its class sum 2+19+137+31+3+19+52+183+13 = 459 ✔); `100-file-hashes.txt:11` records that exact digest for `g3-reconstruction-2026-11-02.sql` | **CONFIRMED by cross-read, not recomputed** |
| P1 | 0 DML / 0 DROP / 0 REVOKE in active text | Pattern `^(INSERT|UPDATE |DELETE|DROP|REVOKE|TRUNCATE|SET |COPY|VACUUM|CREATE (FUNCTION|TRIGGER|ROLE|DATABASE|SEQUENCE|VIEW|EXTENSION)|ALTER (ROLE|DATABASE|SYSTEM|PUBLICATION)|COMMENT ON|SECURITY)` → **0 matches** | **CONFIRMED** |
| P2 | Every active statement carries `ev:`/`src:` | 483 statement lines, 460 carry the tag **on their own line**. The 23 that do not = the 4 `CREATE POLICY` (tagged on the *following* comment line, e.g. `:748-751`) + the 19 `^SELECT` (tagged `-- expected:` / `-- ev:` on the following line). So: **all 465 load statements are evidenced**; the 19 read-only checks carry expectations, not provenance. | **CONFIRMED with a stated scope correction** |
| P3 | Triggers 0 of 8 active | 8 captured = 7 (`g1-q3`, names enumerated and matched 1:1 to commented `:661-674`) + 1 (`g1-q3b` `on_auth_user_created`, commented `:689`). `^CREATE TRIGGER` active = 0 | **CONFIRMED** |
| P4 | Sections 40/50/55/80 non-executing | No column-0 statement start exists in `:595-703` (covers 40, 50, 55) or `:773-875` (covers 80) | **CONFIRMED** |
| P5 | **"Predicates emitted verbatim, whitespace reflowed only — no token changed"** (`:729`); clause-level `[verbatim]` labels at `:751`, `:758`, `:764`, `:776` | **REFUTED** for 5 of the 6 emitted clauses. See §2.3 | **REFUTED** |
| P6 | "0 DML/DROP/REVOKE" *and* "no `WITH GRANT OPTION`" and "no anon object grant" | `WITH GRANT OPTION` occurs only at `:855,:856,:1158` (all comments); `^GRANT … TO anon` active = 0 | **CONFIRMED** |
| P7 | "452 statements inside BEGIN..COMMIT" (`:1471`) | 465 − 13 ADP-after-COMMIT = 452 ✔ | **CONFIRMED** |
| P8 | "an H-3 membership failure costs at most 9 rows rather than unwinding 447" | Arithmetic ✔: 9 supabase_admin-grantor statements sit after the 4 postgres-grantor ones, so worst-case loss = 9 default-privilege statements, structural load already committed. | **CONFIRMED as arithmetic** — but see §8 D-6: what it *buys* is a committed load whose `pg_default_acl` tail is **partially and irreversibly** applied |
| P9 | "pglast 8.7 / PG17 parses all 486" | **CANNOT DETERMINE — missing evidence: no parser was run (prohibited by the brief).** I did establish mechanically that all 4 policies have `final paren balance = 0` (measured, see §2.3), no active line contains an unterminated literal, and `$$ … $$` is opened once and closed once. |
| P10 | "no statement addresses production" | `hhqgreaoqulmfwfwarhc` / `parent-control-prod` occur at **comment lines `:7` and `:1462` only**; 0 active statements. No `ALTER DATABASE`/`CREATE DATABASE`/`\c`. | **CONFIRMED — no CRITICAL target defect** |

**Score: 14/14 numeric claims confirmed. Of the 10 property claims (P1–P10): 8 confirmed (P1, P2 with a stated scope correction, P3, P4, P6, P7, P8 as arithmetic, P10), 1 refuted (P5, verbatim predicates), 1 unverifiable by design (P9, parser).**

### 2.3 The verbatim-policy drift (measured character by character)

`g1-q2-20261029.json` parses to exactly **21 rows** ✔. My extraction joined each active `CREATE POLICY` across its continuation lines, collapsed all whitespace runs to single spaces (the reflow the file declares), and compared clause-for-clause. **Total emitted predicate slots = 6, not 8**: `webrtc_signals_insert_participant` has `qual = null` and `webrtc_signals_select_participant` has `with_check = null` in the capture, and the file emits **no clause** for either — correct behaviour (the M-3/D-3 repair), so the true denominator for "verbatim" is 6.

| Policy @ line | Clause | `g1-q2` text | Emitted text | Verdict |
| --- | --- | --- | --- | --- |
| `families_update_owner` @745 | `USING` | `((owner_id = auth.uid()) AND (deleted_at IS NULL))` | identical | **exact ✔ (50 = 50 chars)** |
| `families_update_owner` @745 | `WITH CHECK` | `(owner_id = auth.uid())` | `((owner_id = auth.uid()))` | **+1 wrapping paren — drift (25 vs 23)** |
| `profiles_update_self` @753 | `USING` | `(id = auth.uid())` | `((id = auth.uid()))` | **+1 paren — drift (19 vs 17)** |
| `profiles_update_self` @753 | `WITH CHECK` | `(id = auth.uid())` | `((id = auth.uid()))` | **+1 paren — drift (19 vs 17)** |
| `webrtc_signals_insert_participant` @760 | `WITH CHECK` | `((from_user_id = auth.uid()) AND (EXISTS ( SELECT 1 FROM remote_sessions s WHERE …))))` | same, **+1 outer paren** | **drift (max depth 8 vs 7)** |
| `webrtc_signals_select_participant` @772 | `USING` | `(EXISTS ( SELECT 1 FROM remote_sessions s WHERE …)))` | `((EXISTS ( … ))))` | **drift (max depth 7 vs 6)**; also `…)))) ;` — a stray **space before the semicolon** at `:773` |

**Result (re-measured this session, clause by clause): of the 6 non-empty predicate clauses the file emits, 1 is byte-exact and 5 carry exactly one extra wrapping parenthesis the capture does not have.** The other 2 of the nominal 8 slots are `null` in `g1-q2` (`webrtc_signals_insert_participant.qual` and `webrtc_signals_select_participant.with_check`) and the file correctly emits **no clause** for them — that part of the build is right (M-3 repair). Removing one outer paren from each of the 5 makes all 6 match. No identifier, operator, literal, cast or `ARRAY` member differs anywhere — the reflow of `SELECT 1\n   FROM remote_sessions s\n  WHERE` onto one line is faithful. Verbatim measured: `families_update_owner` USING ✔; the remaining 5 (`:747`, `:754`, `:755`, `:761`, `:773`) ✘.

Impact: **semantically nil** (PostgreSQL stores the parse tree and `pg_get_expr` re-renders without the redundant paren, so the G3-d parity diff will still match). But the file's own claim at `:729` ("no token changed") and the `[verbatim]` labels at `:751`/`:758` are **false as written**, and one of them (`:751`) labels the specific clause I measured as drifted. That is a claim-accuracy defect, not a load defect. Severity: LOW.

### 2.4 The 236 grants reconciled against `g1-q6` (exact composition derived)

Evidence parse: `table_grants` = **149** rows ✔, `update_column_grants` = **191** rows ✔, `default_acl` = **24** rows, `role_memberships` = **24** rows. `default_acl`'s `object_type` values are `S`/`f`/`r` over 8 (owner, schema) groups — **not** the strings `sequences`/`functions`/`relations` the file's `ev` tags quote (e.g. `:1227` "object_type=sequences"). Cosmetic provenance drift, LOW.

My derived composition of the 236, and the reconciliation:

| Class | Statements | Triples covered | Reconciliation |
| --- | --- | --- | --- |
| `GRANT USAGE ON SCHEMA private TO authenticated` (`:876`) | **1** | n/a | **Not from `g1-q6`.** From `g1-b3b-20261029.json:14-19` `schema_usage{anon:false, authenticated:true, service_role:true}`. Declared D-5 |
| `GRANT … ON TABLE … TO authenticated;` (`:886-918`) | **14** | **16** (12 single-privilege + `DELETE,SELECT` @911 + `INSERT,SELECT` @917) | ✔ 16 = my measured `authenticated` histogram of `q6.table_grants` |
| `GRANT … ON TABLE … TO service_role;` | **19** | 133 | ✔ 133 = measured `service_role` rows |
| `GRANT … MAINTAIN … TO postgres`-style delta (lines 923-941) | **19** | 19 `m` triples | ✔ **19** extra `MAINTAIN` triples, sourced from `g1-q1.table_acl`, **declared** at `:1480`. These are the *only* emitted privileges absent from `g1-q6` |
| `GRANT UPDATE (col) ON <table> TO role` (`:946-1128`) | **183** | **191** | ✔ Exact. 183 lines, 175 single-grantee + **8 two-grantee statements** (`TO authenticated, service_role` at `:1033,1035,1068,1093,1098,1099,1100,1101`) = 191 triples |
| **Sequences** | **0** | — | Correct: 19 uuid-defaulted tables, **no serial/identity ⇒ no sequences exist**. Sequence privileges appear only as `ADP … ON SEQUENCES` after COMMIT |
| **Functions / views / types** | **0** | — | ✔ §4.1 of `A3` requires 0 |
| **TOTAL** | **236** | **168 table + 191 column** | ✔ |

Set-diff result: **`q6.table_grants` triples not covered = 0. Emitted privileges not in `q6` = 19, all `MAINTAIN`, all declared. Emitted column triples not in `q6` = 0.** The 236 therefore **fully reconciles**; the only declared surplus is the 19 MAINTAIN triples plus the 1 schema-USAGE grant.

Also independently confirmed: all 149 `q6` rows have `is_grantable='NO'` and **0** active `WITH GRANT OPTION` — and the file honestly flags that the 191 column rows carry **no** `is_grantable` field at all, so their grant-option absence is an **assumption** (`:856-858`). ✔

### 2.5 Where I disagree with the author's own arithmetic (both directions)

* **`:820` "deny-all for their 15 SELECT-exposed tables"** — I cannot reproduce `15` from `g1-q6`: measured **14** tables carry an `authenticated` table-level `SELECT`. `15` is reproducible only as "tables that *production* exposes to `authenticated` via a SELECT **policy**" (15 of the 21 `g1-q2` rows are SELECT policies on 15 distinct tables), which is S2-EXEC-04 `H-1:40`'s different unit. Three near-synonymous units (`15` / `16` / `14`) are used in the same file. LOW, documentation.
* **`S2-EXEC-04 M-5:71` says "37 of 44 FKs unqualified"; the file's D-1 says 43 of 44.** I measured **44** FK statements, **43** with `REFERENCES public.`, **1** with `REFERENCES auth.users` (`:527`). ⇒ **the file is right and S2-EXEC-04's `37` is the wrong number.** This matters because it is the very quantity D-1/M-5 claims to have repaired.
* My *secondary* method (a hand-written statement splitter) returned 485 and 1 `CREATE SCHEMA`, merging `:123` into the `DO` block. That is a **defect in my tool, not in the file** — its own tail shows `END $$ CREATE SCHEMA IF NOT EXISTS public`. I report it so the divergence from 486 is not mistaken for a finding. The column-0 census in §2.1 is the number I stand behind.

---

## §3 Sentinel guard analysis (lines `:108-118`) — highest-risk item

Read verbatim, the guard does exactly two things: `to_regclass('private.s2_environment') IS NULL` ⇒ `RAISE EXCEPTION`, else `SELECT environment FROM private.s2_environment LIMIT 1` and `IS DISTINCT FROM 'staging'` ⇒ `RAISE EXCEPTION`. Thereafter **no further check of any kind identifies the project.**

**3.1 Does it abort cleanly, or leave the transaction open?** Cleanly, and this is its genuine strength. The `RAISE` is inside the `DO`, which is statement #2 inside `BEGIN` (`:98`). An error inside an open transaction puts the session in state `25P02`; every subsequent statement — all 450 of them — is rejected with *"current transaction is aborted, commands ignored until end of transaction block"*, and the trailing `COMMIT` (`:1182`) is coerced to a rollback. **Nothing is committed.** I confirm the file's claim at `:107` and `:1183-1184`. The guard needs no `ROLLBACK` statement of its own to be atomic here.

**3.2 Pasted into an un-sentineled staging (today's actual state).** `S2-EXEC-06:136` records the sentinel as `BLOCKED — APPROVAL REQUIRED (A2′(a))`, i.e. **not created**; `:65` records `public` = 0 tables. ⇒ abort at **statement #2**, zero objects, staging stays the shell. The file is therefore **not pasteable today at all** — which the STATUS block does declare (`:19-23`, `:1457`). Correct-by-design, but it means "would it do what the author claims" today = *"it applies nothing"*.

**3.3 Pasted into production. Two sub-cases, and only one is safe.**
* **(a) Production has no sentinel** — abort, same clean path as 3.2. ✔ This is the case the file describes.
* **(b) Production ever receives a `private.s2_environment` row reading `staging`** — **the guard passes and 452 DDL statements plus up to 13 ADP are applied to `parent-control-prod`.** This is not hypothetical: `A2′(a)`'s own authorised DDL (approval-package `:340-342`) is
  ```sql
  create table if not exists private.s2_environment (environment text not null);
  insert into private.s2_environment (environment) values ('staging');
  ```
  **there is no `project_ref` column and no ref predicate anywhere in it.** The single mistake the guard exists to catch — pasting the *staging* sentinel block into the *production* editor — is precisely the mistake the guard **cannot** catch, because that mistake manufactures the guard's own pass condition. Production would then hold a row that says `'staging'`.

**3.4 Is the project ref checked? No — and the file says so against itself.** There is no `project_ref` test, and the `A2′(a)` table shape offers none. Worse, the file **answers this question in its own verification section and then ignores its answer**: `V-1` at `:1263-1264` is annotated `expected: db=postgres` — i.e. the author has already recorded that `current_database()` returns a **project-independent** constant on Supabase, for every project including production. Yet `:1445-1447` asserts *"a paste into the production editor aborts. **It is the only control that works**"*, and `:9-10` asserts it *"makes a wrong-project paste abort before DDL #1"*. Per the same approval-package, `:347-353`, the discriminating power of that column is **`NOT VERIFIED`**, and if it fails to discriminate then *"a `project_ref` column with value `dzonzgngwxclhfnvxtvu` **must be added as a recorded amendment**"* and (`:382`) *"**no load (A3) or patch (A5) proceeds until the owner rules on a ref-binding column**"*. The file does not encode that precondition, does not reference `:352`/`:382`, and presents an absence-based control as a positive one. The guard's protection rests entirely on **someone else not doing something in another project** — that is a policy hope, not a database control.

**3.5 Bypassability — yes, and the file's own instructions invite it.** The guard is a text-position artefact with no server-side enforcement:
* Paste from `:123` (`CREATE SCHEMA … public`) onward and there is **no guard and no `BEGIN`** — the dashboard autocommits each statement, so you get a partially-applied, un-rollbackable schema.
* Checklist `[7]` (`:65-66`) and `:48` instruct the operator to paste/withhold *"SECTION 0-8"*. **No section labelled 1..8 exists in this file** (labels are 0, "10-equivalent", 10, 20, 30, 40, 50, 55, 60, 80, 70, 9, 10, 11). An operator obeying `[7]` literally must guess what "0-8" means, and the cheapest guess — "the sections before 9", or "everything before the second SECTION 10" — is how a guard-less partial paste happens. `[7]` also says *"in TWO parts"* then lists **three**.
* Checklist `[2]` (`:49`) invites the operator to run the sentinel `SELECT` **by itself** first. Once the guard has been run standalone, running the rest of the file without `:98`/`:108` is unguarded.
* `SECTION 9` (`:1189-1190`) is by design outside the wrap and carries **no** guard at all.
* The guard is not idempotent-aware, does not check `current_user`, does not check that the object it reads is owned/expected, and reads `LIMIT 1` **with no `ORDER BY` and no row-count assertion** — `A2′(a)`'s own check includes `count(*) … = 1`, but if `private.s2_environment` ever holds two rows, an arbitrary one satisfies the guard.

**3.6 Verdict on the guard.** It is a real and correctly-implemented **missing-sentinel** abort. It is **not** a wrong-project control in the sense the header and STATUS block claim, and its documentation overstates its power at the exact point (`:3.3(b)`) where overstatement is most dangerous — it is the sentence an owner reads to conclude that a production paste is impossible.

---

## §4 First-abort analysis

**Ordinal numbering** (load-affecting statements, in paste order): #1 = `DO` @`:108`; #2–#3 = `CREATE SCHEMA` @`:123,:126`; #4–#22 = the 19 `CREATE TABLE`; #23–#159 = the 137 `ADD CONSTRAINT`, ordered PK(19) → UNIQUE(9) → CHECK(65) → FK(44); #160–#178 = the 19 `ENABLE RLS`; #179–#182 = the 4 `CREATE POLICY`; #183 = `GRANT USAGE ON SCHEMA private` @`:876`; #184–#235 = the 52 table grants; #236–#418 = the 183 column grants; **⇒ 452 statements inside `BEGIN..COMMIT`** (#453–#465 = the 13 ADP after `COMMIT`).

**#1. The guard, at ordinal #1 (statement #2 of the file), is the first thing to fail on today's staging** — `DO $$ … RAISE EXCEPTION 'A3 staging load: sentinel private.s2_environment is missing …'` (`:111-112`). By design. **Nothing is committed.** This is also my answer to "where would it abort": **at the sentinel, before any DDL**, given the live state §3.2.

**#2. Assuming `A2′(a)` has been executed, I found no dependency-order failure.** Every object referenced is created earlier in the same file: `private` @`:126` precedes the only active `private` reference (`GRANT USAGE … private` @`:876`); all 19 tables precede all 137 constraints; all 19 PKs (#23–#41) precede all 44 FKs (#116–#159); the 34 indexes reference only created tables; the 4 policies reference only created tables and only columns I checked to exist (`families.owner_id/deleted_at`, `profiles.id`, `webrtc_signals.from_user_id/session_id`, `remote_sessions.id/status/parent_user_id/child_user_id` — all present at `:249-256`, `:301-306`, `:309-326`, `:374-381`); all grants follow their objects. I also confirmed **no `IF NOT EXISTS` on any table/constraint/index** (`:71-72`, `:1412-1414` are therefore accurate) ⇒ **a re-run after any partial application is not a repair, it is a 42P07 failure**; the file says so.

**#3. Four residual abort risks I cannot settle offline — each needs one probe, not a debate.**
* **(i) Ordinal #143 — `ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;` (`:527`).** This is the file's only active DDL dependency on a **platform-owned** object, and **no evidence in the G1 series captures `auth.users`' ACL or ownership.** Whether `postgres` may bind a foreign key to it is asserted ("All are satisfiable on Supabase", S2-EXEC-04 `M-5:71`) and never measured. **CANNOT DETERMINE — missing evidence: `auth.users` relacl/owner and `pg_has_role`-style reachability on `dzonzgngwxclhfnvxtvu`.**
* **(ii) Ordinals #15 and #21 — `CREATE TABLE public.safe_zones` (`:336`) and `public.webrtc_signals` (`:374`)**, which embed `DEFAULT auth.uid()` (`:344`, `:377`). Function-name resolution for a zero-argument default happens at *parse/CREATE* time, so this fails (`42883`) if the loading session cannot see `auth.uid()`. Measured: **exactly 2 such sites**, matching `:95-96` and S2-EXEC-04 `M-1:58` — which also records this as the **first failure at statement #18** on bare Postgres. On Supabase it should resolve; not evidenced. `M-1` is therefore *contained*, not *closed*.
* **(iii) Ordinals #179–#182, the 4 policies.** They need (a) `authenticated`/`postgres` reachability of `auth.uid()`, and (b) the **unqualified `FROM remote_sessions s`** in `#181`/`#182` to resolve through the *session's* `search_path` at `CREATE POLICY` time. The file declares this (D-10, `:765-770`) and reasons correctly that Supabase's default `"$user", public` yields `public.remote_sessions`. But **the file emits no `SET search_path` and its verification suite never probes `SHOW search_path`**, so M-5's own recommended mitigation ("record a `SET search_path = public, …` precondition line", S2-EXEC-04 `M-5:71`) is **not** applied. The repair that would remove the risk (qualifying the two range names) is refused on verbatim grounds — and §2.3 shows the predicates were **not** kept verbatim anyway.
* **(iv) M-4 is only half-closed, and the blind spot is load-wide.** `:876` grants `USAGE` on **`private`** only, to **`authenticated`** only (`service_role` companion deliberately not emitted, `:877-880`; `anon` correctly false). **The file emits no `GRANT USAGE ON SCHEMA public` and `V-12` (`:1347-1349`) tests only `private`.** All 236 grants and all 4 policies are inert if the staging shell does not already give `authenticated`/`anon` `USAGE` on `public`. It almost certainly does (platform default), but **no line of this file and no line of the evidence proves it**, and one `has_schema_privilege('authenticated','public','USAGE')` would. ⇒ **M-4: improved, not closed; verification gap is the residual defect.**
* **(v) `supabase_admin` grantor assumption (§9, post-COMMIT).** The `FOR ROLE supabase_admin` premise (`:1237-1253`) fails iff staging mirrors production membership. The file's handling is *better than the source* (moved after `COMMIT`, postgres-grantor first, per-statement `pg_has_role` probe above each). The failure mode is now bounded to 9 default-privilege statements. **But** §4.3 of `A3` (approval-package `:444`) says "An unwrapped load is a different action and is **not** authorised here", and `:466` says `pg_default_acl` is not self-reversing — so a SECTION 9 failure leaves a **committed** load with a partial, irreversible ACL tail, and the file's own `:1215-1216` procedure tells the operator to **delete statements before pasting**, which collides with `:487` ("NO hand-edit of the artefact after scan"). Declared (D-4), still an un-ruled scope change.

**#4. Does the wrapper mean nothing is committed?** For ordinals #1–#452, **yes** — including for risks (i)–(iii) above, all of which sit inside the wrap. For SECTION 9 (post-`COMMIT`), **no**: those 13 statements are individually autocommitted and irreversible. That asymmetry is the design, and it is sound; the consequence to accept is that `A3`'s rollback story must cover `pg_default_acl`, and currently does not (§8 D-2).

---

## §5 Deny-all honesty check

**The file does say it, in its own body, twice, in terms strong enough to satisfy C7.** Quoting exactly:

* `:815` — `-- *** READ THIS BEFORE DECLARING THE LOADED DATABASE USABLE ***`
* `:816-818` — `Loading the 4 policies above restores ONLY: parent-owned family row UPDATE, self profile UPDATE, and webrtc_signal INSERT/SELECT for an accepted-or-active session participant. Everything else is still denied.`
* `:820-822` — `The 19 RLS ENABLEs above are deny-all for their 15 SELECT-exposed tables, so authenticated reads return 0 rows and every ungranted write fails 42501 (H-1). This file therefore produces a STRUCTURALLY faithful shell that is NOT application-ready, and no count in SECTION 10 should be read as saying otherwise.`
* `:1457` — `PREPARED -- NOT EXECUTED -- REQUIRES A2'(a) + A3`
* `:1501` — `*** THE LOADED DATABASE IS NOT APPLICATION-READY. ***`
* `:1503-1507` — `…17 policies and 8 triggers remain blocked on the 9 missing function return types … so 16 of the 19 RLS-enabled tables carry no policy at all and are deny-all for authenticated (V-9 measures it). No signup provisioning, no append-only audit guard, no updated_at maintenance, no session transition guard, no Realtime. Treat every downstream G5-S case as BLOCKED, not PASSED…`

**16-of-19 verified:** tables with ≥1 active policy = `families`, `profiles`, `webrtc_signals` → 19 − 3 = **16** ✔, measured, and `V-9` (`:1310-1317`) counts exactly that predicate. **The 3 non-deny-all tables and why:** `families` (`families_update_owner` @`:745`, UPDATE), `profiles` (`profiles_update_self` @`:753`, UPDATE), `webrtc_signals` (`:760` INSERT + `:772` SELECT). Cross-checked against `g1-q6`: `authenticated` holds table privileges on **14** of 19 tables (audit_logs, device_apps, device_commands, device_policies, families, family_members, location_events, pairing_requests, profiles, remote_sessions, safe_zones, safety_alerts, usage_daily, webrtc_signals); the 5 with nothing are `child_contact_ids`, `device_pairing_tokens`, `devices`, `pairing_attempts`, `safe_zone_states`. Column-level UPDATE grants back the three: `families.name/settings` (`:1033,:1035`), `profiles.display_name` (`:1068`) — each `TO authenticated, service_role`.

**The honesty verdict is "declared, but understated in the one direction that matters".** The precise, defensible statement is **worse than 16/19**:
1. `families` and `profiles` have **no SELECT policy at all** in this load (their SELECT partners `families_select_members` `:796` and `profiles_select_self_or_family` `:800` are among the 17 commented) ⇒ **for reads, 18 of 19 tables are deny-all, not 3 of 19 exposed.**
2. And per §6, the one read policy that does exist (`webrtc_signals_select_participant`) cannot admit a row ⇒ **reads are deny-all on 19 of 19.**
The "deny-all, not application-ready" conclusion is therefore *more* true than the file states, so this is not a safety problem — but §6 shows the file simultaneously *overstates* what the 4 policies restore, which is the direction that can produce a false `PASS`.

---

## §6 The 4 active policies — names, predicates, evidence match, reachability

Names and predicates (extracted from the file at `:745,:753,:760,:772`, whitespace-normalised) are in §2.3. Each matches a real `g1-q2` row (`families_update_owner` row 6; `profiles_update_self` row 11; `webrtc_signals_insert_participant` row 19; `webrtc_signals_select_participant` row 20) on **tablename, policyname, cmd, roles=authenticated, permissive=PERMISSIVE** ✔, and both `cmd:"INSERT"` rows correctly emit **no `USING` clause** (M-3/D-3 repaired — `:760` has `WITH CHECK` only, and so does the commented `safe_zones_insert_parent` at `:803`). All four have balanced parentheses (measured `final = 0`).

**Privilege reachability from the captured grants (measured, not asserted):**

| Policy | Role privilege on the table | Privilege verdict |
| --- | --- | --- |
| `families_update_owner` | `SELECT` @`:897`; `UPDATE(name,settings)` @`:1033,:1035` | reachable |
| `profiles_update_self` | `SELECT` @`:906`; `UPDATE(display_name)` @`:1068` | reachable |
| `webrtc_signals_insert_participant` | `INSERT, SELECT` @`:917` | reachable |
| `webrtc_signals_select_participant` | `INSERT, SELECT` @`:917` | reachable |

So the file's `:730-732` privilege claim is **correct** — and its `:1567-1573` "exactly 2 of 21 are unreachable for their role" (`devices_select_parent_or_child`, `safe_zones_insert_parent`) is **correct too** and is commendably flagged as *not a defect*.

**But privilege reachability is not efficacy, and by my analysis all four are `reachable-but-inert`. Two distinct mechanisms:**

* **Mechanism A — the two webrtc policies are self-defeating through `remote_sessions`.** Both predicates contain `EXISTS ( SELECT 1 FROM remote_sessions s WHERE … )` (`:761`, `:773`). `public.remote_sessions` has **RLS enabled** (`:717`) and **no active policy** — its only SELECT policy, `remote_sessions_select_participants`, is commented at `:801`. RLS is applied to tables appearing in subqueries, evaluated as the **invoking** role (`authenticated`, not a definer). ⇒ for `authenticated` the subquery is deny-all and returns 0 rows ⇒ `EXISTS` is **always false** ⇒ `webrtc_signals_select_participant` yields **0 rows** and `webrtc_signals_insert_participant`'s `WITH CHECK` **always fails 42501**. The file's own logic at `:820-821` establishes the deny-all premise; it simply never applied it to its own 2 policies.
* **Mechanism B — the two UPDATE policies have no SELECT partner.** For `UPDATE`, the target row must first be *visible*, which requires it to pass the table's **SELECT** policies in addition to the UPDATE policy's `USING`. `families` and `profiles` get an UPDATE policy here but **no SELECT policy**. The decisive corroboration is inside the evidence itself: in production each of these UPDATE policies is **paired** with a SELECT policy (`families_select_members` + `families_update_owner`; `profiles_select_self_or_family` + `profiles_update_self` — `g1-q2` rows 5/6 and 10/11), and this load activates the UPDATE half of each pair while commenting the SELECT half. ⇒ `UPDATE … WHERE …` by `authenticated` affects **0 rows, silently**. *Confidence: analysis-derived, not executed — one dashboard probe settles it, and §9 R-4 specifies it. If Mechanism B does not hold, these 2 are the only policies with real effect and the webrtc 2 remain inert via Mechanism A.*

**Therefore:** the claim at `:816-818` / `:1501-1503` that loading these 4 "restores parent-owned family row UPDATE, self profile UPDATE, and webrtc_signal INSERT/SELECT" is **not supportable as a behavioural statement**. The `A3` table's count (`Policies: 4`) is correct; what the file *infers* from the 4 is not. The load remains **default-deny and safe** — there is no confidentiality exposure — but it delivers **zero** application behaviour, and `SECTION 10` contains **no probe capable of detecting that** (no `EXPLAIN`, no role-switched read, no `has_row_privilege`). Combined with approval-package `:462` (post-load denial "recorded as `DENY — VACUOUS`, never as `PASS`"), an unamended file is the setup in which a later G3-d/G5-S pass misreads 4 loaded policies as 4 working controls.

**Net reachability statement, per policy: all four = `reachable-but-inert`.** None is `unreachable` (role privileges do exist, unlike the 2 declared unreachable in `:1567-1573`), and none is expected to admit a row.

---

## §7 Deviation list vs the source artefact — undeclared-deviation sweep

Method: I tokenised **both** files (`g3-reconstruction-2026-11-02.sql` and the migration), normalised whitespace, and diffed as statement **sets** in both directions. Source = **459** statements ✔ (agrees with `93-counts.json:15`).

**Forward (source → migration): 44 source statements have no verbatim counterpart.**
* **43 = FK target requalification** `REFERENCES profiles(id)` → `REFERENCES public.profiles(id)` etc. ⇒ **exactly declared as D-1** (`:1512-1517`, "43 statements changed, 1 unchanged"). I verified independently: 44 FK statements, 43 `REFERENCES public.`, 1 `REFERENCES auth.users` @`:527`. ✔
* 1 = `CREATE SCHEMA IF NOT EXISTS public` — **artifact of my own splitter** (§2.5), present in the migration at `:123`.

**Reverse (migration → source): 70 statements have no source counterpart, and every one is accounted for by a declared deviation.**

| Migration-only statements | Count | Declared as |
| --- | --- | --- |
| 43 re-qualified FKs | 43 | **D-1** ✔ |
| 4 `CREATE POLICY` (source had all 21 commented) | 4 | **D-6** ✔ |
| `GRANT USAGE ON SCHEMA private TO authenticated` | 1 | **D-5** ✔ |
| Sentinel `DO $$ … $$` | 1 | **D-7** ✔ |
| `BEGIN` / `COMMIT` | 2 | **D-2** ✔ |
| 19 read-only verification `SELECT`s | 19 | **D-8** ✔ |
| **Total** | **70** | **70/70 declared** |

**⇒ Zero undeclared statement changes.** Further confirmations: the **13 ADP statements are textually identical to the source** (they matched verbatim in both directions, so D-4's relocation/reordering altered position and order only, never content — "NOT silently dropped: all 13 are present" `:1210` is true); the 19 tables' 183 column definitions, the 137 constraints (except the 43 FK clauses), the 34 indexes, the 19 RLS enables and the 235 source grants carry no silent edit. The delta the author stated (+1 `DO`, ADP after `COMMIT`, 4 policies active/17 commented, sections inert) is **exactly** the delta I measured, plus the two they also declared (D-5 schema USAGE, D-8 verification section). **This is the cleanest part of the artefact and I want it on record.**

### Defect register against S2-EXEC-04's work list

| ID | S2-EXEC-04 finding | This file | Verdict |
| --- | --- | --- | --- |
| **H-1** | 19 ENABLE RLS, 0 policies, live `authenticated` write grants ⇒ silently inert shell; aggravating sub-finding: 4 policies were emittable offline | Emits the 4 (D-6) and re-derives the 17/21 `private.` split from `g1-q2` ✔ | **Addressed on paper; NOT addressed in effect** (§6: all 4 inert). Declaration at `:815-823` is honest but understates (`16` vs the real `18`/`19` for reads) |
| **H-2** | No `prorettype` for any of 38 functions ⇒ 40/50/55/80 dead | Emits 0 functions, 0 triggers; enumerates the 9 gating return types (`:640-649`); refuses to invent a body ✔ | **Correctly ignored — cannot be fixed offline, and correctly says so** |
| **H-3** | `ADP FOR ROLE supabase_admin` may abort at #448 with 447 persisting | Moved all 13 after `COMMIT`, postgres-grantor first, per-statement `pg_has_role` probe (`:1226` etc.), operator must delete failing statements (`:1213-1219`) | **Fixed for the abort-the-load risk; converted into an un-ruled scope change** (§8 D-6) |
| **M-1** | No transaction wrapper anywhere | `BEGIN` `:98` / `COMMIT` `:1182`; no `ROLLBACK` (fine — an aborted txn coerces `COMMIT` to rollback) ✔ | **Fixed** inside the wrap only; **SECTION 9 is unwrapped by design** |
| **M-2** | `???*` undecoded ACL markers | 4 occurrences at `:1163,:1164,:1165,:1169`, **all inside `NOT EMITTED` comments**, each `SIC`-labelled and reproduced un-edited for provenance ✔ | **Neutralised for the active set (correct call).** Underlying generator bug unfixed (out of scope) |
| **M-3** | Two policies rendered `USING (None)` at `60:62`/`60:71` | **Both re-rendered with the `USING` clause omitted** — active `:760` (webrtc INSERT) and commented `:803` (safe_zones INSERT), with the exact `g1-q2` `qual:null` row quoted at `:737-740` | **Fixed ✔ — and this is exactly what `A3` §4.3's `X-4` precondition demands ("must be re-rendered before load")** |
| **M-4** | No `GRANT … ON SCHEMA` of any kind, though `private` USAGE is evidenced | `:876` adds `USAGE` on `private` → `authenticated`; deliberately withholds the `service_role` companion; no `public` USAGE, and `V-12` tests only `private` | **Partially fixed; residual = load-wide unverified assumption** (§4.3(iv)) |
| **M-5** | Unqualified FK targets bind to loader `search_path` | 43/44 qualified ✔; the 2 webrtc policies' `FROM remote_sessions s` left unqualified (D-10, reasoned at `:765-770`); **no `SET search_path` precondition, no `SHOW search_path` probe** | **Substantially fixed; residual deliberately kept and un-probed** |
| **I-1** | 16 `DEFAULT gen_random_uuid()` resolve as PG13+ built-ins; extensions uncaptured | Measured exactly **16** sites; no `CREATE EXTENSION` emitted (D-11) ✔ | **Handled, honestly labelled as an evidence gap** (`:130`) |
| **I-2** | Standalone `55-auth-users-trigger.sql` is a no-op | SECTION 55 = 0 active, trigger commented `:689` ✔ | **Consistent** |
| **I-3** | Component 55 excluded from assembled file | `on_auth_user_created` active = 0 ✔ | **Consistent** |
| **I-4** | No `ALTER SYSTEM` / `SET SESSION` / platform config | 0 matches on my dangerous-verb sweep ✔ | **Consistent** |
| **L-2** | `CREATE SCHEMA IF NOT EXISTS public` = permanent NOTICE | Kept, annotated at `:124-125` | **Consistent (harmless)** |
| **L-4** | `remote_session_transition_guard` default-PUBLIC-EXECUTE | Flagged at `:650-652` as an A-window authoring item | **Recorded, not silently dropped** |
| **L-3 / R3** | anon/authenticated future-table ADP is a latent exposure | All 13 ADP emitted as captured (`:1227-1253`), 8 of them to `anon`/`authenticated` | **Faithful; revoking would diverge — correctly not done** |

---

## §8 Defect register

| ID | Sev | file:line | Defect |
| --- | --- | --- | --- |
| **D-1** | **BLOCKING** | `A3-staging-load-v1.sql` — **absent statement** (checklist `:41-74`, `V-1..V-15` `:1258-1389`) | **`A3`'s mandated first statement of the A3 window is not in the file.** approval-package `:435-439` requires `select count(*) from auth.users;` on `dzonzgngwxclhfnvxtvu` as **the first statement**, recorded with ref + UTC stamps, *"If the count is not 0 — STOP"*, and `:479` binds the signature to it ("with the auth.users count as the first statement"). `grep FX-18` → **0 hits**; no `count(*) … auth.users` in `SECTION 10`. `S2-EXEC-06:101-105` leaves the `Total: 10 users (estimated)` anomaly **UNRESOLVED**, so the premise is live and unmeasured. A file pasted "as written" cannot satisfy the instrument it is made for |
| **D-2** | **BLOCKING** | `:1429-1439` (SECTION 11) | **No signed, hashed, executable reverse-DROP script exists.** approval-package `:468-470`: reversal is *"only a signed drop script: `DROP …` in reverse dependency order over the same object list the artefact created, authored offline **before** the load and hashed alongside it — a load without its drop script is irreversible in practice, and **this instrument does not authorise one**"*. SECTION 11 is *"EVERY STATEMENT BELOW IS COMMENTED OUT ON PURPOSE"* and is **not** that script: `:1434` collapses 19 DISABLE-RLS into one `… x19` note, `:1435` elides 19 DROP TABLEs as `public.audit_logs, … , public.webrtc_signals`, and **nothing** drops the 34 indexes, 137 constraints, 236 grants, or resets the 13 ADP (`:1422` admits "13 ADP resets (undefined target)"). `pg_default_acl` is explicitly non-self-reversing (`:1405-1407`) |
| **D-3** | **HIGH (security)** | `:108-118`; overclaim at `:9-10` and `:1445-1447`; contradicted by `:1263-1264` and approval-package `:347-353,:382` | **The sentinel guard is mis-described as the wrong-project control, and cannot perform that role.** It tests only `environment = 'staging'`; the `A2′(a)` table shape (`approval-package:341-342`) has **no `project_ref` column**, so pasting `A2′(a)` into production *creates the guard's own pass condition*; the file's `V-1` already records `expected: db = postgres`, proving `current_database()` is project-independent. `:1447`'s "It is the only control that works" and `:9-10`'s "makes a wrong-project paste abort before DDL #1" are **false as stated**. `approval-package:352-353/:382` require an **owner ruling on a ref-binding column before A3 proceeds** — the file neither encodes nor cites that precondition |
| **D-4** | **HIGH (claim accuracy → false-PASS risk)** | `:816-818`, `:1501-1503` (and reachability table `:730-732`) | **The efficacy claim for the 4 active policies is not supportable; all four are predicted reachable-but-inert** (§6): webrtc ×2 self-defeat via the deny-all `remote_sessions` subquery (`:717` + commented `:801`); families/profiles ×2 have UPDATE policies with **no SELECT partner**, so UPDATE matches 0 rows. `SECTION 10` has **no probe** that could detect this, while `approval-package:462` forbids recording denial as `PASS` |
| **D-5** | **MEDIUM (operational hazard)** | `:65-66` `[7]`, `:48` `[2]`, and duplicate labels `:121`/`:135`/`:1256`; `SECTION 80` `:826` placed before `SECTION 70` `:842` | **Section labelling is unusable and invites an unguarded partial paste.** `[7]` says *"TWO parts"* then lists three, and refers to *"SECTION 0-8"* — **no section 1..8 exists**. **Two different sections are labelled SECTION 10** (`:135` = 19 `CREATE TABLE`, DDL; `:1256` = 19 read-only SELECTs). An operator told to "paste SECTION 10 (read-only) separately / never paste SECTION 11" can reach the DDL block instead, or paste from `:123` onward and get **no guard + no transaction** (dashboard autocommit) |
| **D-6** | **MEDIUM (scope)** | `:876` (grant) vs approval-package `:407` "Grants **248**"; `:1189-1190` + `:1213-1219` vs `:444` and `:487` | **The file loads more, and differently-arranged, than `A3` enumerates.** Emitted grant/ADP statements = **249** (236 + 13) vs `A3 §4.1`'s 248 — the surplus is D-5's `USAGE` grant, an object-level ACL `A3`'s table does not list. Separately, `A3 §4.2/:444` authorises *"one pasted transaction-wrapped block"* and states *"An unwrapped load is a different action and is **not** authorised here"*, whereas SECTION 9 is an **unwrapped, operator-trimmed** block whose procedure (`:1215-1216` "DELETE that statement … from the paste") collides with `:487` *"NO hand-edit of the artefact after scan"*. Declared (D-4/D-5 in the file) ⇒ **not an undeclared deviation**, but it is an **un-ruled authorisation delta** needing an explicit owner tick or A3 addendum |
| **D-7** | **LOW (claim accuracy)** | `:729` ("no token changed"); clause-level verbatim labels `:751`, `:758`, `:764` ("quoted verbatim above"), `:776` — all four point at clauses I measured as drifted; emitted clauses `:747`/`:754`/`:755`/`:761`/`:773` | **"Verbatim" is false in 5 of the 6 emitted predicate clauses** — one extra wrapping paren per clause; only `families_update_owner`'s `USING` (`:746`) is byte-exact; `:773` also has a space before `;`. The 2 clauses the capture reports as `null` are correctly omitted (`:763`, `:776`). Semantically inert, but the label is wrong and it is the label that justifies refusing to qualify `remote_sessions` (D-10) |
| **D-8** | **LOW (residual, load-wide)** | `:876` + `V-12` `:1347-1349`; no `GRANT USAGE ON SCHEMA public`; no `SET`/`SHOW search_path` anywhere | **Two unverified preconditions underpin all 465 statements and neither is probed:** `authenticated`/`anon` `USAGE` on `public`, and the loader's `search_path` (which binds `FROM remote_sessions s` at `:761`/`:773`). M-4 half-closed; M-5's own recommended mitigation unapplied |
| **D-9** | **LOW (documentation)** | `:820` "15 SELECT-exposed tables"; `:1504` "16 of 19"; measured **14** tables with `authenticated` SELECT, **18/19** deny-all for reads | Three units used near-synonymously for the same idea, none of them the truest one (19/19 for reads). Also `D-1`'s "43 of 44" contradicts S2-EXEC-04 `M-5:71`'s "37 of 44" — **the file is right, `M-5` is wrong**, and the discrepancy is unrecorded |
| **D-10** | **INFORMATIONAL** | `:1227` etc. (`object_type=sequences`) vs `g1-q6.default_acl` actual values `S`/`f`/`r`; `:1162-1170`'s "57 rows" not reconstructible from the 24-row `default_acl` | Provenance labels paraphrase the field values they cite; commented-row arithmetic (`57`) exceeds what the 24 rows × expansion can be shown to be from in-repo evidence. No load impact |
| **D-11** | **INFORMATIONAL (positive)** | `:108-118` correctness; `:111-117` | The guard's PL/pgSQL is **valid** as measured: `$$…$$` opened once/closed once, `A2''(a)` correctly double-escaped (`:112`), `IS DISTINCT FROM` handles NULL (`:115-116`), `COALESCE` message (`:116`), all 4 policies paren-balanced. The `RAISE`-inside-`BEGIN` path aborts **cleanly and atomically** |

---

## §9 Required amendments before any `A3` signature

Ordered; R-1 … R-5 are blocking (R-1, R-2, R-3 must be closed before signature; R-4/R-5 before the paste).

1. **R-1 — Add the FX-18 statement as the literal first executable statement** (D-1): a `SELECT count(*) AS fx18_auth_users_expected_0 FROM auth.users;` ahead of `BEGIN`, plus a checklist line recording it with the console ref and UTC window, and the binding `STOP if ≠ 0`. `A3`'s signature text is un-signable without it.
2. **R-2 — Author, hash and sign the real reverse-DROP script** (D-2): expand SECTION 11 into the full, paste-ready `DROP` set in reverse dependency order — 13 ADP resets (or an explicit statement that `pg_default_acl` has *no* reversal and the project is disposable), 183 column grants, 52 table grants, 4 policies, 19 DISABLE RLS, 34 indexes, 137 constraints (FK → CHECK → UNIQUE → PK), 19 tables, `DROP SCHEMA private` — enumerated, not `… x19`. Keep it commented in this file but **complete**, and hash it with the artefact.
3. **R-3 — Demote the guard's claims to what it can actually do, and bind the ref ruling** (D-3): rewrite `:9-10` and `:1441-1452` to state that the guard detects **a missing/incorrect sentinel, not the project**, that `current_database()` is measured-project-independent (`V-1` already says `db=postgres`), and that its production protection is **contingent on `A2′(a)` never being executed in production — an absence, not a check**. Add the `A2′(a)` precondition verbatim (`approval-package:352-353`, `:382`): *"no A3 load until the owner rules on a `project_ref` column binding"*. Prefer: guard on a **ref-bearing** sentinel predicate the moment `A2′(a)` is amended, and assert `count(*) = 1` instead of `LIMIT 1` with no `ORDER BY`.
4. **R-4 — Correct the 4-policies efficacy statement to the truth and make it measurable** (D-4): replace `:816-818`/`:1501-1503` with *"0 of the 4 active policies are expected to admit a row: reads remain deny-all on 19 of 19 tables"*, and add three probes to SECTION 10 — (a) `SHOW search_path` + `has_schema_privilege('authenticated','public','USAGE')` + `…('anon','public','USAGE')` (D-8), (b) a role-switched `SELECT count(*) FROM public.webrtc_signals;` as `authenticated` expecting 0, (c) a role-switched `UPDATE public.profiles SET display_name=display_name WHERE id=(…)` reporting **rows affected = 0** to settle Mechanism B either way. Record results as `DENY — VACUOUS`, never `PASS` (`approval-package:462`).
5. **R-5 — Fix the paste instructions so a partial paste is not the easy mistake** (D-5): renumber to unique labels (`S-0 GUARD`, `S-1 SCHEMAS`, `S-2 TABLES`, … `S-9 ADP`, `S-10 VERIFY`, `S-11 ROLLBACK`), delete all "SECTION 0-8" references, make `[7]` say **three** parts explicitly, and add one line: *"the guard protects nothing unless `BEGIN;` @`:98` and the `DO` @`:108` are inside the SAME paste; pasting any later block alone is an unguarded autocommitted DDL load and is NOT authorised."*
6. **R-6 — Owner ratification of the authorisation delta** (D-6): an explicit `A3` tick (or addendum) naming (i) the 249th grant, `GRANT USAGE ON SCHEMA private TO authenticated`, and (ii) SECTION 9's unwrapped, probe-trimmed execution with a pre-state `pg_default_acl` capture as the rollback target. Do not resolve this by inventing grants; `anon` and `service_role` `private` USAGE stay **unemitted** as the file already decides.
7. **R-7 — Truthful verbatim labelling** (D-7): change `:729`, `:751`, `:758`, `:764`, `:776` to *"captured expression text, re-parenthesised and whitespace-reflowed; no identifier/operator/literal/cast changed"*, **or** strip the redundant outer paren from the 5 drifted clauses (`:747`, `:754`, `:755`, `:761`, `:773`) and the space before `;` at `:773` so that "[verbatim]" becomes true. Do not use the verbatim rule as the reason to leave `remote_sessions` unqualified while also using it as a claim of fidelity — pick one.

---

## Report-back

**Verdict: NO-GO** (D-1, D-2, D-3 blocking; D-4 must also close before the paste).

**Author claims: 14/14 numeric claims CONFIRMED by independent recount** (19/137/34/2/19/4/236/13/1/465/19/486, plus 183 columns, 16 `gen_random_uuid`, 2 `auth.uid()` defaults, 157,738 B / 1,575 lines) **and 8 of the 10 property claims CONFIRMED** (0 DML/DROP/REVOKE/`WITH GRANT OPTION`/`FORCE`/active triggers/active functions; production ref comment-only; every load statement evidenced; the 236 grants reconcile to `g1-q6` + the 19 declared MAINTAIN triples + 1 declared USAGE with **0 invented and 0 missing**). **1 property claim REFUTED**: "predicates verbatim, no token changed" — 5 of the 6 emitted predicate clauses carry an extra wrapping paren. **1 unverifiable by design**: the pglast 486-statement parse claim (no parser run). **The undeclared-deviation sweep is clean — zero undeclared statement changes** in either direction against the 459-statement source; all 70 migration-only statements map to declared deviations.

**Most dangerous defect: D-3 — the sentinel guard is described as the wrong-project control but is not one.** It compares only `environment = 'staging'` and there is no `project_ref` column to compare, per `A2′(a)`'s own DDL (`approval-package:341-342`); pasting `A2′(a)` into production *manufactures the guard's pass condition*, after which this file writes **452 DDL statements to production**. The file even measures the ref is undiscoverable (`V-1`, `expected: db=postgres`) and then asserts at `:1447` that the guard is "the only control that works". Second: D-1/D-2 are hard `A3` preconditions missing outright.

**First statement I believe aborts: ordinal #1 of the 465 (statement #2 of the file, `DO $$ … RAISE EXCEPTION '… sentinel private.s2_environment is missing; A2''(a) is not executed …'` at `:111-112`) — on today's staging, because the sentinel does not exist (`S2-EXEC-06:136`).** It aborts **cleanly**: the open transaction enters `25P02`, all 450 following statements are rejected, `COMMIT` is coerced to rollback, and **nothing is committed**. Assuming `A2′(a)` has run, **I found no dependency-order abort** — the four residual risks are all unprobed-assumption, not provable failure: ordinal #143 (`profiles_id_fkey → auth.users`, `:527`, no `auth.users` ACL in evidence), ordinals #15/#21 (`DEFAULT auth.uid()`, `:344`/`:377`), ordinals #179-#182 (4 policies, `auth.uid()` + unqualified `remote_sessions`), and SECTION 9 statement #5 (`:1237`, `FOR ROLE supabase_admin`, post-COMMIT).

**What must change before the owner signs `A3`:** add the FX-18 `auth.users` count as the window's first statement (R-1); author and hash the complete reverse-DROP script that `§4.5` demands (R-2); re-describe the guard as a missing-sentinel abort only, bind it to the `A2′(a)` ref-column ruling, and assert `count(*)=1` rather than `LIMIT 1` (R-3). Then, before any paste: correct the 4-policies efficacy claim and add the three probes that would falsify it (R-4), unambiguate the section labels and state that the guard is void unless `BEGIN;` is in the same paste (R-5), ratify the 249th grant and SECTION 9's unwrapped/operator-trimmed execution (R-6), and fix the "[verbatim]" wording (R-7).
