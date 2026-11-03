# S2-A3 — Supabase Database & Schema Audit (subagent A3)

Date of work: 2026-11-03 (local). Method: **offline, repository-only**. No dashboard, no SQL Editor, no SQL
execution, no CLI/REST/direct connection, no schema load, no sentinel creation, no `auth.users` count.
Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was not contacted and is not referenced beyond citations to
Stage 1 files already in this repository.

**Gates: A2′(a), A2′(b), A3, A9, A12 are `UNSIGNED`. A5 is approved-but-not-executable. A1 is `INOPERATIVE`.**
The owner's Firebase-UID architecture direction is a *design* instruction; it signs nothing and lifts no gate.
Nothing in this file authorises a load, a write, a deploy or a credential action.

Object of audit: `C:/Users/ASUS/.qoder/tmp/D--control/g3-build/g3-reconstruction-2026-11-02.sql`.

**Two vocabularies are kept strictly separate throughout.**
`RECONSTRUCTED` = reproducible from the 2026-10-29/30 Stage 1 capture, cited, and if the capture is silent →
`MISSING — SOURCE EVIDENCE ABSENT`. `PROPOSED — NEW DESIGN, NOT RECONSTRUCTED` = a forward design for the
Firebase-UID architecture, carrying a rationale and never presented as evidence-derived. §1–§3 and §5 are
reconstruction. §4 is proposal. They are not merged anywhere.

---

## 1. G3 reconstruction audit re-verification (independent re-measurement)

### 1.1 Artefact integrity

| Property | Recorded | Measured by this audit | Result |
| --- | --- | --- | --- |
| Raw-byte SHA-256 | `fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6` | identical | **AGREE** |
| LF-normalised SHA-256 | `efdbf985cfc72f721f9499a856fbdf51181f8851eca565fbae9e74d0e71f7092` | identical (`tr -d '\r'`) | **AGREE** |
| Size | 150,566 bytes | 150,566 bytes | **AGREE** |
| Lines | 1,951 | 1,951 (1,951 `\n`, file ends with a newline; 1,951 CRLF pairs) | **AGREE** |
| Post-load re-hash | — | `fc996f45…` after all reads | **UNCHANGED — this audit modified nothing** |

The two digests are the *same bytes* under two normalisations; this audit reproduces both and records that they
reconcile. Digest consistency proves **consistency, not authorship** — both values are self-published by one build,
the repository has zero commits (`git status --porcelain` shows every path untracked), so the binding required by
A3's evidence row is still unfilled (precondition M-16).

### 1.2 Statement census (own parser: comment-stripped, quote-aware, semicolon-terminated)

| Category | Measured active | Recorded | Result |
| --- | ---: | ---: | --- |
| `CREATE SCHEMA` | 2 | 2 | AGREE |
| `CREATE TABLE` | 19 | 19 | AGREE |
| `ALTER TABLE … ADD CONSTRAINT` | 137 | 137 | AGREE |
| `CREATE INDEX` | 31 | 31 | AGREE |
| `CREATE UNIQUE INDEX` | 3 | 3 | AGREE |
| `ALTER TABLE … ENABLE ROW LEVEL SECURITY` | 19 | 19 | AGREE |
| `GRANT` (table-level) | 52 | 52 | AGREE |
| `GRANT` (column-level) | 183 | 183 | AGREE |
| `ALTER DEFAULT PRIVILEGES` | 13 | 13 | AGREE |
| **TOTAL active statements** | **459** | **459** | **AGREE** |
| `CREATE FUNCTION` | **0** | 0 | AGREE |
| `CREATE TRIGGER` | **0** | 0 | AGREE |
| `CREATE POLICY` | **0** | 0 | AGREE |
| publication statements | **0** | 0 | AGREE |
| `CREATE EXTENSION` | **0** | 0 | AGREE |
| `BEGIN` / `COMMIT` / `START TRANSACTION` / `SET ROLE` | **0 / 0 / 0 / 0** | 0 | AGREE (no transaction wrapper) |

**Column census.** Parsed `CREATE TABLE` bodies: 183 column definitions, matching `g1-q8` (183 rows, 19 tables)
per table exactly, including `families` at 7. (An initial 184 was my own parser splitting on a comma inside the
`settings` JSON default, not an artefact defect.)

**Constraint census.** `g1-q5` = 137 rows: 19 primary key + 44 foreign key + 9 unique + 65 check = 137; all
`validated=true`. Emitted 137. **AGREE.**

**Index census — the 62/34 question resolved.** `g1-q4` = 62 rows, 62 distinct names; 31 definitions begin
`CREATE INDEX`, 31 begin `CREATE UNIQUE INDEX`. The artefact emits 34 active index statements and comment-carries
the other 28. The split is exact and *accounted for*, not lost: 19 primary-key indexes + 9 unique-constraint
indexes = 28, which PostgreSQL creates implicitly from the 19 `ADD CONSTRAINT … PRIMARY KEY` and 9
`ADD CONSTRAINT … UNIQUE`. **0 emitted index names are absent from `g1-q4`, and 0 emitted names are invented.**
The "62 expected" figure is a raw row count of `pg_indexes`-equivalent output that double-counts constraint-backed
indexes; the correct A3 target is 34 standalone + 28 implicit. **AGREE with the matrix, with this arithmetic added.**

**Grant census — strongest positive result in this audit.** The 183 column-level `GRANT` statements, expanded back
into `(table, column, privilege, grantee)` tuples and schema-prefix-normalised, reproduce the 191
`g1-q6.update_column_grants` rows with **symmetric difference 0** (artefact-only 0, evidence-only 0). This class is
byte-faithful reconstruction. The 52 table-level statements expand to 168 distinct `(table, privilege, grantee)`
triples vs 149 evidence rows: Δ 19, which is `g1-q1.table_acl` owner privilege merged in (grantee split
`service_role` 152 + `authenticated` 16). **AGREE** with the matrix row (149/33/171/0/152/19), and record that the
Δ 19 is *intentional merge*, not drift.

### 1.3 Where this audit **disagrees** with the recorded figures

| # | Recorded | Measured | Where recorded |
| --- | --- | --- | --- |
| **X-1** | "**12** `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin`" | **9** active statements carry `FOR ROLE supabase_admin` (#448–450, #451–453, #457–459); 4 carry `FOR ROLE postgres` (#447, #454–456); 13 total. The tail that never runs *is* 12 statements (#448–#459), so the number 12 is a **tail length mislabelled as a role count** | `S2-EXEC-04-independent-g3-audit-report.md:184`; `S2-EXEC-04-sql-structural-findings.md:48` |
| **X-2** | "236 grants" | **235** (52 + 183) | `S2-EXEC-04-sql-structural-findings.md:49` |
| **X-3** | "19 tables FK into `profiles`" / "a domain table that 19 tables reference" | **19 inbound FK constraints from 15 distinct tables** (`device_pairing_tokens` ×3, `remote_sessions` ×3, `pairing_requests` ×2, 12 others ×1) | `S2-A1-auth-architecture.md:143`, `:154` (its `:237`, `:409` "19 inbound FKs" is correct) |
| **X-4** | "4 policies are **emittable** offline" | True *as a dependency statement*, but the artefact renders one of the four with invalid text. The four sit at `60-rls-policies.sql:52,59,71,74` = asm `1538, 1545, 1557, 1560`; **`webrtc_signals_insert_participant` (asm:1557) carries `USING (None)`**. So **4 emittable in principle, 3 emittable as written**, 1 needing the D-6 fix first. The other `USING (None)` line, `safe_zones_insert_parent` (asm:1548), is one of the 17 helper-delegating policies and is unaffected by this correction | `S2-EXEC-05-cross-agent-conflict-register.md:45` (CU-03) |
| **X-5** | H-1 framed as "17 policies call `private.*` functions" (implying 17 blockers) | The 17 call only **3 distinct functions**: `private.is_family_parent` (13 policies), `private.is_family_member` (3), `private.shares_active_family` (1) — **and all 3 bodies are captured** in `g1-b3b.bodies` | `S2-EXEC-04-independent-g3-audit-report.md:183`; refined by `S2-EXEC-05-function-body-coverage-register.md:145` |
| **X-6** | "0 triggers, nothing recoverable" (implied by the function cliff) | All **8 trigger statements are captured verbatim as `CREATE TRIGGER` text** — 7 in `g1-q3.definition`, 1 in `g1-q3b.definition`. They are *derivative* of the missing functions, but the trigger DDL itself needs no invention | `S2-EXEC-04-object-coverage-matrix.md:417,424` records 7/0 and 1/0 but does not note the definitions are complete |
| **X-7** | Not recorded anywhere by any prior pass | **0 statements grant `USAGE` on schema `private`** (grep `ON SCHEMA` in `70-grants-default-privileges.sql` → 0 hits), although `g1-b3b.schema_usage` evidences `anon=false, authenticated=true, service_role=true` and `00-platform-assumptions.sql:46` transcribes it. The artefact creates `private`, grants nothing on it, and every helper function lives in it | NEW — see §8 D-5 |

---

## 2. Complete object coverage matrix (22 categories + the 7 UNKNOWN populations)

`UNKNOWN ≠ zero`. A `MISSING — SOURCE EVIDENCE ABSENT` row means the capture is silent, not that the object does not
exist in production.

| # | Category | Expected (evidence key) | Emitted active | State | Outstanding issue |
| --- | --- | --- | ---: | --- | --- |
| 1 | Extensions | **UNKNOWN** — no `pg_extension` query in Q1–Q10/B3b | 0 | `MISSING — SOURCE EVIDENCE ABSENT` | `gen_random_uuid()` is used by 45+ defaults; whether `pgcrypto` is present is unknowable from this evidence set |
| 2 | Schemas (app) | 2 (`g1-q1`, `g1-b3b`) | 2 | `PRESENT — SOURCE VERIFIED` | none |
| 3 | Tables | 19 (`g1-q1.table_name`) | 19 | `PRESENT — SOURCE VERIFIED` | all owner `postgres` |
| 4 | Columns & types | 183 (`g1-q8`) | 183 (verified per table) | `PRESENT — SOURCE VERIFIED` | collation / domain / numeric precision beyond `data_type` not captured |
| 5 | Defaults & identity | 69 defaults (`g1-q8.column_default`); identity/generated columns **UNKNOWN** | 69 | `PRESENT — PARTIAL` | 2 defaults call `auth.uid()` — see §4.8, load-order hazard on bare Postgres |
| 6 | Primary keys | 19 (`g1-q5` kind=p) | 19 | `PRESENT — SOURCE VERIFIED` | none |
| 7 | Foreign keys | 44 (`g1-q5` kind=f) | 44 | `PRESENT — SOURCE VERIFIED` | exactly 1 auth FK (`profiles_id_fkey`); satisfiable only because Supabase pre-creates `auth.users` |
| 8 | Unique constraints | 9 (`g1-q5` kind=u) | 9 | `PRESENT — SOURCE VERIFIED` | none |
| 9 | Check constraints | 65 (`g1-q5` kind=c) | 65 | `PRESENT — SOURCE VERIFIED` | none |
| 10 | Indexes | 62 raw rows = 34 standalone + 28 constraint-implicit | 34 | `PRESENT — SOURCE VERIFIED` | resolved at §1.2; nothing lost |
| 11 | Functions & overloads | 38 (`g1-b3b.inventory`: 14 `public` + 24 `private`); 0 overloads | **0** | `MISSING — SOURCE EVIDENCE ABSENT` | `CREATE FUNCTION` unwritable for 38/38 (no return type in any capture) |
| 12 | Return types | 0/38 in catalogue captures; 14/38 narrative (`functions-and-triggers.md:36–49`) | 0 | `CONFLICT — SOURCE DISAGREEMENT` | narrative table carries no `schema_name`; 23 of 24 absent bodies are cross-schema twins → unbindable |
| 13 | Function security props | 38 definer flags, 38 `search_path` (`g1-b3b`/`g1-q7`/`g1-q10`) | 0 | `PRESENT — PARTIAL (comment-only)` | owner of 24 `private` functions unattributed; `postgres` inferred from ACL grantor |
| 14 | Triggers (public) | 7 (`g1-q3`) | **0** | `PRESENT — SOURCE VERIFIED, SUPPRESSED` | **all 7 DDL strings are verbatim in evidence** (X-6); blocked only via their functions |
| 15 | RLS enable + forced | 19 enabled, 0 forced (`g1-q1`) | 19 | `PRESENT — SOURCE VERIFIED` | 0/19 `rls_forced` — re-verified, all `False` |
| 16 | RLS policies | 21 (`g1-q2`) | **0** | `PRESENT — SOURCE VERIFIED, SUPPRESSED` | 21/21 predicate texts are verbatim; 17 gated on 3 helpers, 4 gated on nothing; 2 carry `USING (None)` |
| 17 | Grants & ACLs | 149 table rows + 191 column rows (`g1-q6`); `g1-q1` ACL merged | 235 | `PRESENT — SOURCE VERIFIED` | column class diff = 0 (§1.2); Δ 19 table triples explained |
| 18 | Default privileges | 24 `default_acl` rows / 70 ACL entries | 13 | `PRESENT — PARTIAL` | 57 comment-only; 9 of 13 are `FOR ROLE supabase_admin` (X-1) with no membership evidence |
| 19 | Realtime publication | **UNKNOWN** — `pg_publication`/`pg_publication_tables` never queried; documentation says 4 | 0 | `MISSING — SOURCE EVIDENCE ABSENT` | 4 table names are documentary, not catalogued |
| 20 | Auth-related config | partial (`g1-b3b`, `functions-and-triggers.md` §4); 2 toggles never captured | 0 | `UNVERIFIED — SOURCE AMBIGUOUS` | `auth.users` row count `NOT VERIFIED`; Data API toggles unexercised |
| 21 | `auth.users` trigger | 1 (`g1-q3b`) | **0** | `PRESENT — SOURCE VERIFIED, SUPPRESSED` | DDL verbatim **and** `private.handle_new_user` body verbatim; only its return type is uncaptured (`trigger` is structurally implied) |
| 22 | Platform non-SQL config | roles, storage, vault, Edge runtime, WAL | 0 | `MISSING — SOURCE EVIDENCE ABSENT` | correctly excluded from A0; honest label is "not SQL-reconstructable" |

**The 7 `UNKNOWN` populations** (each an open question, none a zero):

1. **Extensions** — `pg_extension` never queried (row 1).
2. **Sequences** — never enumerated; existence only *indirectly* evidenced by 8 `object_type='S'` rows in
   `g1-q6.default_acl`; 0 `CREATE SEQUENCE` emitted.
3. **Views / materialised views / foreign tables** — `g1-q1`'s `relkind` filter is not in the JSON, so the whole
   non-`r` class is invisible across the entire series. A blind spot, not an empty set.
4. **Realtime publication membership** — which tables are in `supabase_realtime` (row 19).
5. **`supabase_realtime` publication ownership** — never queried.
6. **WAL / logical decoding / `replica identity`** — no `pg_settings` or publication capture exists; Realtime
   delivery cannot be verified from schema SQL at all.
7. **Role attributes beyond `authenticator`** — `pg_roles` was never selected; only `authenticator_role_config`
   (`rolsuper=false`, `rolbypassrls=false`, `statement_timeout=8s`, `lock_timeout=8s`) is evidenced.

**Net reconstruction position.** Structural classes (schemas, tables, columns, constraints, indexes, RLS enable,
grants) are evidence-faithful and, in the column-grant class, provably exact. **Every behavioural class — functions,
triggers, policies, publication, extensions — is 0-emitted.** The artefact is a correct empty shell, and the shell
is deny-all: RLS enabled with 0 policies denies every row to `anon`/`authenticated` while owners and `service_role`
bypass.

---

## 3. H-1 / H-2 / H-3 dispositions

### H-1 — RLS enabled, zero policies · **DISPOSITION: SUBSTANTIALLY OVER-SUPPRESSED**

**What the evidence supports (re-verified here).** 19/19 tables `rls_enabled=true`, **0/19 `rls_forced`** (all
`False`) — confirmed directly from `g1-q1`. 21 policies in `g1-q2` across **15 distinct tables** (SELECT 15 /
UPDATE 3 / INSERT 2 / DELETE 1), all `PERMISSIVE`, all `TO authenticated`, 5 with `WITH CHECK`, 16 without, 2 with
null `USING`.

**Recoverable offline?** The **predicate text of all 21 is verbatim in `g1-q2`** — nothing about the policy bodies
requires invention. The blocker is purely referential: 17 call `private.*`.

**The correction that changes the disposition (X-5).** Those 17 depend on **3 functions, and all 3 bodies are
already captured**: `private.is_family_parent(p_family_id uuid)`, `private.is_family_member(p_family_id uuid)`,
`private.shares_active_family(p_user_id uuid)` (`g1-b3b.bodies`, 277 / 249 / 372 chars). Every one is a single
`select exists (…)` anchored on `auth.uid()`. Therefore:

- **4 of 21 policies are offline-emittable today** and the artefact suppresses them wrongly. They reference no
  `private.*` helper at all: `families_update_owner`, `profiles_update_self`, `webrtc_signals_insert_participant`,
  `webrtc_signals_select_participant` (assembly lines 1539, 1546, 1557, 1560). All four are labelled
  `(BLOCKED ON SECTION 40)` — a class label applied without checking the predicate. **This is over-suppression, and
  it should be reversed by re-authoring, not by hand-editing.** One of the four (`webrtc_signals_insert_participant`)
  carries the `USING (None)` defect (X-4/D-6) and must be re-rendered before it can be emitted.
- **0 of the remaining 17 are emittable *without an owner ruling*** — not because the bodies are missing, but
  because `CREATE FUNCTION` needs a `RETURNS` clause and no capture supplies one. `boolean` is *implied* by the
  body shape and by policy semantics, and `S2-EXEC-05` correctly refuses to upgrade implication to source.
  **The honest state is: 17 policies are one return-type decision away, not 17 unrecoverable objects.**

**Explicit instruction held: nothing is silently dropped and nothing is stubbed.** A `RETURNS boolean` guess written
into `40-functions.sql` would convert an `INFERRED` object into a `VERIFIED`-looking one and would change production
behaviour on a security predicate. It is not done here and must not be done in A3 authoring without the owner
naming the inference.

### H-2 — the function cliff · **DISPOSITION: CONFIRMED UNRECOVERABLE OFFLINE**

**Re-verified against source.** 38 functions = **14 `public` + 24 `private`** (`g1-b3b.inventory`, row-level
`schema_name` counts). 14 bodies present (`g1-b3b.bodies`) = **12 `private` + 2 `public`** → **24 absent =
12 `public` + 12 `private`**. The common label "24 `private` bodies absent" is **wrong as to composition**; it is
half `public`. `93-counts.json.function_bodies_absent = 24` is right; `90-limitations.md:126` is not.

**0 return types in any catalogue capture — confirmed independently.** Key-scan of `g1-b3b`, `g1-q7`, `g1-q10` finds
no `prorettype` / `return_type` / `rettype` / `returns` field in any of the 11 evidence JSON files. The artefact
contains **0 occurrences of the word `RETURNS`** and **0 citations of `functions-and-triggers.md` or
`schema-columns.md`**, so it never admitted the narrative set into its own ceiling.

**14 narrative return types** do exist — `functions-and-triggers.md:36–49` (9 `jsonb`, 4 `integer`, 1
`remote_sessions` row type). They are dashboard-derived, `g1-run-manifest-20261029.md` admits the file as evidence,
and the table carries **no `schema_name`**. Of the 24 absent bodies, **23 have a cross-schema twin name**, so the
narrative value cannot be bound to a specific function; only `private.record_audit` is a non-twin absent name and it
has no narrative row either. **AGREE with recorded position.**

**0 of 24 absent bodies are recoverable from any authorised source.** Recovery requires a fresh production read of
`pg_proc.prosrc` — that is A1, `INOPERATIVE` under the staging-only instruction. The 14 present bodies are `prosrc`
*fragments* (no header, no `RETURNS`, no `LANGUAGE`), so even the present half of the inventory is not directly
loadable without an owner-declared inference for the signature.

### H-3 — default privileges, membership and half-apply · **DISPOSITION: CONFIRMED IN SUBSTANCE, COUNT CORRECTED**

**Re-verified.** Active ADP statements = **13**, of which **9** are `FOR ROLE supabase_admin` and **4**
`FOR ROLE postgres` (X-1). First `supabase_admin` statement is **#448 of 459**; if the executing role is not a member
of `supabase_admin`, PostgreSQL raises `must be member of role "supabase_admin"` there. `g1-q6.role_memberships`
(24 rows) contains **no row naming `supabase_admin` at all**, as member or as group. Confirmed by enumeration of all
24 pairs.

**No transaction wrapper — confirmed by direct grep: 0 `BEGIN`, 0 `COMMIT`, 0 `START TRANSACTION`, 0 `SET ROLE` in
the whole artefact.** Combined with the dashboard SQL Editor's autocommit and the recorded
`statement_timeout=8s` / `lock_timeout=8s` on `authenticator`, a load can apply statements 1–447 (19 tables, 137
constraints, 34 indexes, 19 RLS enables, 235 grants) and stop at #448 with **no automatic reversal and no rollback
capability** — Free plan has no backups and no PITR, 2 active / 2 used / 0 remaining slots, and the
delete-and-re-create branch is withdrawn. `ALTER DEFAULT PRIVILEGES` has no "restore previous" form.

**Recoverable offline?** The *risk* is real but *undecidable* offline: membership is a `pg_auth_members` fact about
**staging**, which has never been read. It is closed by one approved read-only probe inside the A3 window, or
eliminated by wrapping/batching the tail. The 13 ADP statements themselves are correctly transcribed from
`g1-q6.default_acl` rows 16–18.

---

## 4. Firebase-UID mapping schema proposal

> ## ⛔ ALL OF §4 IS `PROPOSED — NEW DESIGN, NOT RECONSTRUCTED`
> No object in §4 exists in the Stage 1 capture. The repository contains **zero** Firebase-UID columns, tables or
> constraints of any kind. Every statement below is a design proposal with a rationale, is `NOT STARTED`, and is
> `BLOCKED — APPROVAL REQUIRED` (A2′(a) → A3 → A5 chain). **Nothing in §4 may be read as evidence-derived, and
> nothing in §4 is SQL that can be written today.**

### 4.1 Gate preconditions that bind §4 (status vocabulary closed)

| Dependency | Status | Why |
| --- | --- | --- |
| A2′(a) sentinel, A3 load, A9 secrets, A12 Firebase | `BLOCKED — APPROVAL REQUIRED` | unsigned |
| Firebase Auth enablement | `BLOCKED — APPROVAL REQUIRED` | see §4.2 — currently *prohibited*, not merely unapproved |
| FCM app registration / configuration / credentials | `BLOCKED — APPROVAL REQUIRED` | A12 amended text permits **project creation only** |
| Function bodies (38-object cliff) | `MISSING — SOURCE EVIDENCE ABSENT` | H-2; §4 helpers would be new `PROPOSED` objects, not restorations |
| Staging schema | `NOT STARTED` | 0 tables; nothing to alter |

### 4.2 **Disagreement flagged (not copied)** — the Firebase direction contradicts an approved document

`01-staging-project-proposal.md:196–198` (§6 Service topology) states, as **approved role 1**, "Single identity
authority = **Supabase Auth**", and at item 6 lists **"Firebase Auth / Firestore / Cloud Functions"** as
**`OUT OF SCOPE — must not be enabled`**. `approval-package-v2:354` repeats it: "Firebase Auth, Firestore and Cloud
Functions are **not approved requirements**: Supabase Auth remains the single identity authority and Firebase is
FCM-transport-only by intent."

**A Firebase-UID front therefore does not "build on" the current approval set — it reverses it.** `S2-A1` writes the
new architecture without recording this collision. Recorded here instead of copied: any Firebase-UID SQL requires an
**owner decision that explicitly supersedes §6 item 6 and the A12 exclusion clause**, dated, before it is even a
draft. Until that decision exists, §4.3–§4.9 are conditional designs.

**Second recorded disagreement with `S2-A1` (I-1).** I-1 treats "`auth.uid()` remains the resolution path" as
load-bearing because 21/21 policies are `authenticated`-scoped. That is correct as *DDL fact* and misleading as
*control fact*. `docs/stage1/14-edge-function-security-audit.md:245` — "**VERIFIED — every function uses the
service-role key, therefore RLS never applies. This is the single most important architectural fact in this audit**"
— and `patches/S2-P02-e3-actor-binding.sql:4` — "all current callers use `service_role`, where `auth.uid()` is
NULL". Consequence: **for live callers the 21 policies are already inert today**, Firebase UID or not. The only
evidenced live path where an `authenticated` subject reaches SQL is Realtime
(`private.realtime_topic_allowed`, `auth_exec=true`, `service_exec=false`, `g1-b3b.inventory`). I-1 is therefore
defensible as **defence-in-depth for a future direct-client path**, but must not be presented as the operative access
control; the operative control is Edge Function authorisation. This changes the risk weighting of §4.6, not its
shape.

### 4.3 Where the mapping lives — options and recommendation

| Option | Shape | Rationale for / against | Verdict |
| --- | --- | --- | --- |
| **P-A** column on `profiles` | `ALTER TABLE public.profiles ADD COLUMN …` + unique index | Smallest diff, keeps `profiles.id` as key. But it puts an *auth* concern into the most-connected domain table and inherits `profiles`' column grants (`authenticated` holds SELECT only on `profiles` per `g1-q6`), so the column would be unreadable to the very clients whose identity it records | Fallback |
| **P-B separate bridge table** | new `(provider, external_uid, supabase_user_id, …)` | Keeps `profiles_id_fkey` and all 44 FKs untouched; additive-only; unique key naturally scoped to `(provider, external_uid)`; extensible to a second provider; matches the `auth.users` → `profiles` pattern already in use | **Recommended shape** |
| **P-C re-key `profiles.id`** to the Firebase UID | rewrite | Firebase UID is not a UUID and has no `auth.users` row; would drop `profiles_id_fkey` and re-author **19 inbound FK constraints across 15 tables** plus all 21 predicates | Rejected |

Recommendation **P-B**, with one condition the prior design omits: a **20th table added to an artefact that already
fails its own 19-table acceptance definition deepens the M-20 failure**, so P-B must be a *post-A3 additive patch*,
never folded into the G3 reconstruction file. Keeping the two apart is what preserves the reconstruction/proposal
boundary for the equivalence diff.

### 4.4 Uniqueness, collision and duplicate prevention

- **`PROPOSED`**: a unique constraint on `(provider, external_uid)`. Rationale: without it one Firebase UID can bind
  two Supabase identities, which is the exact actor-confusion defect F7/E3 already records.
- **`PROPOSED`**: an additional unique constraint on `supabase_user_id` (one identity ↔ at most one external UID), so
  a re-provision is an idempotent upsert rather than a second row.
- Duplicate-prevention precedent is *reconstruction-verified*: `private.handle_new_user` already uses
  `insert … on conflict (id) do nothing` (`g1-b3b.bodies`). Any bridge upsert should adopt the same shape so a
  replayed provisioning cannot create two rows. That is the only anti-duplicate mechanism the evidence actually
  shows working.
- **Missing evidence — flagged, not solved**: email as a merge key. `supabase/config.toml:180` records
  `enable_manual_linking = false` **locally**; the production/staging value is `NOT VERIFIED`. Nothing in the current
  schema stops two Firebase accounts sharing an email from producing two profiles. The repository has no unique
  constraint on any email-bearing column because **no email column exists in the 183 captured columns** — email
  lives only in `auth.users`, which the reconstruction never touches.

### 4.5 The `profiles.id` ↔ `auth.users.id` FK problem

Verified from `g1-q5`: the **only** auth-schema FK in all 137 constraints is
`profiles profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE`. From `g1-q8`,
`profiles.id` is `uuid NOT NULL` **with no default**. Fan-in: `profiles` 19 constraints / 15 tables, `families` 12,
`devices` 9, then 1 each from `users`, `safe_zones`, `remote_sessions`, `device_pairing_tokens`.

Consequences for any proposal (all `PROPOSED`):

1. `profiles.id` **cannot** hold a Firebase UID — type (`uuid`), no default, and an FK to a table the programme does
   not write. A bridge row is therefore **mandatory**, not optional, if Firebase is the front door.
2. **Every identity-bearing column in the schema stays `uuid`**, because 44 FKs and 183 columns are built on it.
   Re-keying is a schema rewrite, not a migration.
3. The bridge's own FK to `auth.users(id)` would be the **second** auth FK in the database — a new dependency on a
   platform-managed table, and the reason the bridge cannot be loaded before `auth.users` exists (it only does
   because Supabase pre-creates it; the artefact never creates it, §5 step 0).

### 4.6 How RLS predicates get an identity subject at all

This is the load-bearing question and the capture gives a hard constraint: **a policy predicate is evaluated by
PostgreSQL with no application context.** The only identity PostgreSQL can see is what the *session role and JWT*
put there — `auth.uid()` reads the request JWT claim. So there are exactly three evidenced shapes:

| Shape | Mechanism | Evidence state | Consequence |
| --- | --- | --- | --- |
| **S-α** keep `auth.uid()` and mint a real Supabase JWT whose `sub` is the mapped identity | a bridge + a Supabase-issued session | `PROPOSED`; requires an admin write into `auth` (service-role or Auth admin API) — **`NOT VERIFIED` in this repo; no in-repo evidence any such call exists or is permitted** | Preserves I-1 and all 21 predicates unchanged; is the only shape that makes RLS *live* rather than decorative. Needs the unapproved capability. |
| **S-β** keep the service-role model and pass the Firebase UID as an explicit **function argument** | predicates stop consulting the session; RPCs take `p_actor` | **Partly evidenced**: `functions-and-triggers.md:34–49` shows every RPC already takes `p_actor` / `p_actor_user_id` / `p_parent_user_id`, and `S2-P02-e3-actor-binding.sql:48` adds `if auth.uid() is not null and p_actor_user_id is distinct from auth.uid()` — i.e. the repo already tolerates `auth.uid()` being NULL | Matches reality, but **the actor argument is client-supplied**, so correctness moves entirely to the Edge Function layer. Weaker RLS posture, honest about today. |
| **S-γ** no Supabase identity at all; Firebase UID is the only key | rewrite | rejected (§4.3 P-C) | — |

**Recommendation (design authority only, grants nothing): S-α**, because S-β leaves 21 policies enforced by nothing
except Edge Function code and Realtime, and §4.2 records Realtime as the one live authenticated path. But S-α
**cannot be written as SQL today**: it depends on a capability that is `NOT VERIFIED`, and on the 38-object function
cliff. So the correct status is `BLOCKED — APPROVAL REQUIRED`, and any SQL written now would be invention.

**A fourth, unrecorded hazard found in this audit (§4.8): two column defaults break under S-α/S-β regardless.**

### 4.7 What happens to `on_auth_user_created`

Reconstruction-verified facts: `g1-q3b` holds the complete DDL
`CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.handle_new_user()`,
enabled (`O`), `SECURITY DEFINER`, `search_path = public, private, pg_temp`; and `g1-b3b.bodies` holds
`private.handle_new_user`'s body verbatim (463 chars) — it reads `new.raw_user_meta_data ->> 'display_name'`, falls
back to the email local-part, then to `'User'`, and upserts `public.profiles (id, role, display_name)` with
`role='unset'` and `on conflict (id) do nothing`. **Both the trigger and its function body are therefore offline
recoverable — the artefact emitting 0 of them is a build choice, not an evidence limit.**

`PROPOSED` consequences: the trigger fires only when an `auth.users` row is inserted by Supabase Auth. Under a
Firebase front it either never fires (deny-all silent state, no profile ever created) or double-provisions (if the
bridge also inserts into `profiles`). The `on conflict (id) do nothing` clause is what makes the double path safe
today. Its fate is an open owner decision (`S2-A1` O-5), and `S2-A1`'s S-1…S-4 case table is consistent with what
this audit measured — **no disagreement recorded there**, except that A1 describes the trigger as stranded by
evidence when it is in fact stranded only by *emission*: the bodies and DDL are in hand.

### 4.8 Two newly-recorded load hazards the Firebase design must resolve (**not in `S2-A1`**)

From `g1-q8`, of 69 captured column defaults, exactly 2 are function calls — and both are to the very identity
function the Firebase direction removes:

| Table | Column | Type | Nullability | Default |
| --- | --- | --- | --- | --- |
| `safe_zones` | `created_by` | uuid | NULL | `auth.uid()` |
| `webrtc_signals` | `from_user_id` | uuid | **NOT NULL** | `auth.uid()` |

`webrtc_signals.from_user_id` is `NOT NULL DEFAULT auth.uid()`. Under **S-β** (or under today's service-role
reality, where `auth.uid()` is NULL) an insert that omits `from_user_id` fails with a NOT NULL violation rather than
being filled in; under **S-α** it silently takes the Supabase subject, which is a *different person* from the
Firebase subject unless the bridge guarantees equality. Either way **the default must be an explicit owner decision —
keep, drop, or replace with a function parameter** — and it is `PROPOSED`, because no capture says which. This is
also why a Firebase-UID schema cannot be authored before A3: the artefact's own tables embed the identity model being
replaced (`DEFAULT auth.uid()` is even the first failure on bare Postgres, statement #18).

### 4.9 Provisioning ordering and deletion cascade (`PROPOSED`)

**Ordering** (rationale: every step depends on the object created above it, and step 0 is the step the artefact
omits):

```
0. auth.users + auth schema functions exist   ← platform-managed; NOT created by the artefact (96-review-checks check 12)
1. schemas (public, private)                  ← reconstructed, emittable
2. bridge table (provider, external_uid,      ← PROPOSED, additive, post-A3
   supabase_user_id) + unique constraints
3. auth.users identity row for the subject    ← needs the NOT-VERIFIED admin capability
4. profiles row (id = auth.users.id)          ← created by on_auth_user_created OR by provisioning, NEVER both
5. mapping upsert with on-conflict idempotency
6. domain rows (families / family_members …)  ← 44 FKs + 19 inbound profiles FKs assume 2–5 already hold
```

**Cascade.** Reconstruction-verified: the only auth-rooted cascade is `profiles_id_fkey … ON DELETE CASCADE`
(`on_delete_code='c'` on 34 of 137 constraints). Deleting an `auth.users` row deletes the `profiles` row and
transitively reaches the 19 inbound FK edges. Two structural facts constrain any proposal:

- `families.owner_id` is `NOT NULL` and the live policy is `owner_id = auth.uid()` with `WITH CHECK
  (owner_id = auth.uid())` — there is **no owner-transfer path in the schema**, so a deleted owner leaves a family
  that can never be authorised again. A FK cascade cannot fix this.
- The nearest evidenced multi-step teardown is the *unlink* RPC (`private.unlink_child`, 2 514-char body captured:
  revokes devices, ends sessions, revokes pairing tokens, writes audit, `for update` locking, raises `42501` on
  unauthorised actors). **`PROPOSED`: account deletion should route through an `unlink`-style explicit cascade, not
  through `ON DELETE CASCADE`.** Rationale: the cascade is silent and orphans `families`; the RPC is audited and
  ordered. `audit_logs_append_only` (captured body, raises on non-privileged UPDATE/DELETE) means a cascade cannot
  erase the audit trail — **preserve this deliberately** in any bridge design by keeping the bridge out of the audit
  cascade path.
- **Missing evidence**: whether Firebase account deletion propagates at all. No document in the repo states a
  deletion contract; `S2-A1` records the decision as unmade. Status `NOT STARTED`.

### 4.10 FCM registration-token storage gap — verified from `g1-q8`

**Verification performed here (not inherited).** Searched all **183** captured columns by name and all
`data_type`/`column_default` values for `push`, `fcm`, `token`, `registration`, `subscription`, `endpoint`,
`notification`, `platform`:

- **No push-token column exists anywhere in the 183.**
- The only matches are: `devices.platform` (`text`, default `'android'`), `devices.notifications_granted`
  (**boolean** — a permission flag, not a token), `devices.secret_hash` (`text`) and `devices.installation_id`
  (`text NOT NULL`) — a device credential and an installation identifier, **neither is an FCM registration token**;
  and `pairing_requests.token_id` (`uuid`) — a pairing artefact.
- `devices` has exactly 25 columns (matches `g1-q8`) and none of them is sendable-to.
- Corroborating independent statement: `docs/stage1/02-architecture.md:106` — "the current 25 columns are **VERIFIED**
  to contain no push-token column, so adding one is a G3-style migration."

**Consequence, in the closed status vocabulary:** push delivery has **no schema home**. Status of the FCM
registration capability = `BLOCKED — APPROVAL REQUIRED` (A12, unsigned, and A12's amended clause still prohibits FCM
configuration, credentials and app registration). Therefore the column below is **not merely unproposed — it is
unapprovable today**, and no SQL for it should be written.

`PROPOSED — NEW DESIGN, NOT RECONSTRUCTED`: token storage belongs on `devices` (rationale: `devices` is already the
authoritative per-install row, is `NOT NULL`-bound to `family_id` + `child_user_id`, and `docs/stage1/02-architecture.md:104`
step 4 requires binding the token to the *authenticated* device row and never to a body-supplied device id), with
per-device rotation and at most one active token — the lifecycle table at `02-architecture.md:113–117` already
specifies rotation, `UNREGISTERED`/`INVALID_ARGUMENT` handling and multi-token collapse without a schema. Rationale
for *not* choosing a separate token table: the captured lifecycle is one-active-token-per-device, so a second table
would add a 1:N relationship the design explicitly rules out. Flagged as a decision, not settled.

---

## 5. Migration dependency report

Ordered by hard dependency. "Blocked by" names whether the blocker is **the schema** (an object that must exist
first) or **the missing function definitions** (H-2) — the distinction the owner needs, because the second class
cannot be unblocked by any amount of schema work.

| Step | Object | Requires | Blocked by | Status |
| --- | --- | --- | --- | --- |
| 0 | `auth.users`, `auth.uid()`, `anon`/`authenticated`/`service_role`/`authenticator` roles | nothing — **platform pre-creates** | Not SQL. Free-plan/auth config, outside A0 | `NOT STARTED` (platform-owned; never verified) |
| 1 | sentinel `private.s2_environment` | step 2 (schema `private`) | A2′(a) **unsigned**; must precede the load under Sequence A | `BLOCKED — APPROVAL REQUIRED` |
| 2 | `CREATE SCHEMA public, private` (2) | step 0 | — | **unblocked, emittable today** |
| 3 | `CREATE TABLE` ×19 (183 cols) | step 2 | step 0 for the 2 `DEFAULT auth.uid()` columns (§4.8) | **unblocked on Supabase; fails at #18 on bare Postgres** |
| 4 | constraints ×137 (19p/44f/9u/65c) | step 3 | `profiles_id_fkey` needs `auth.users` | unblocked |
| 5 | indexes ×34 (+28 implicit) | steps 3–4 | — | unblocked |
| 6 | `ENABLE RLS` ×19 | step 3 | — | unblocked |
| 7 | **functions ×38** | step 2 | **H-2 — 0 return types captured; 24 bodies absent.** *Schema is not the blocker.* | `MISSING — SOURCE EVIDENCE ABSENT` |
| 8 | **triggers ×7** | step 7 | **H-2 only.** DDL text fully captured in `g1-q3`; nothing else missing | `BLOCKED` by functions, not by schema |
| 9 | **`auth.users` trigger ×1** | steps 0, 7 | **H-2** (`handle_new_user` return type) + `auth` schema ownership | `BLOCKED`; separate component, never applied |
| 10 | **policies ×4 (auth.uid-only)** | step 6 | **NOTHING** (X-4: 2 need `USING (None)` repaired first) | **over-suppressed — emittable today** |
| 11 | **policies ×17 (helper-delegating)** | steps 6, 7 | **H-2 only** — 3 bodies already captured (X-5) | `BLOCKED` by return types, not by schema |
| 12 | table + column grants ×235 | steps 3–6 | — | unblocked, provably exact (§1.2) |
| 13 | **`GRANT USAGE ON SCHEMA private`** | step 2 | **evidenced, never emitted** (X-7) | `MISSING — NOT EMITTED` |
| 14 | default privileges ×13 | steps 2, 3 | **H-3 membership**, not schema | `BLOCKED — pg_auth_members` probe needed |
| 15 | publication + 4 membership adds | step 3 | **U-4** (never catalogued); publication cannot precede tables | `MISSING — SOURCE EVIDENCE ABSENT`; A2′(b), structurally after A3 |
| 16 | extensions | — | **U-1** unknown requirement | `UNKNOWN` |
| 17 | equivalence diff / G5-S / G5-E / G5-C | steps 1–16 | steps 7–11 (behavioural classes all empty) | `NOT STARTED`, unmeetable |
| 18 | Firebase-UID bridge + policy re-anchor | steps 2–14 **plus §4.2 owner supersession** | the whole of §4 | `BLOCKED — APPROVAL REQUIRED` |

**Structural conclusion.** Every blocker in the security-relevant half of the load is **the missing function
definitions (step 7), not the schema**. Steps 2–6 and 12 — 458 of the 459 statements' useful content — are ready.
One single dependency (function return types) gates steps 7, 8, 9, 11 and, through them, the entire behavioural
surface and every downstream validation gate. That makes it the highest-leverage gap in the programme, and it is why
§3 H-2 records it as unrecoverable rather than merely deferred.

---

## 6. Schema load-readiness verdict

> # `NOT LOAD-READY — RECONSTRUCTION GAPS`

Reasons, each independently measured in this audit rather than inherited:

1. **0 of 459 active statements create a function, trigger, policy, publication or extension.** Re-verified with an
   independent parser. The load produces a structural shell only.
2. **H-2 is unrecoverable from authorised sources**: 0 return types in every catalogue capture, 24 of 38 bodies
   absent (12 `public` + 12 `private`), and recovery requires the `INOPERATIVE` A1.
3. **RLS enabled on 19 tables with 0 policies is deny-all** — a load would create a database whose observable
   behaviour diverges from production in the *restrictive* direction, so the equivalence diff has no behavioural
   side and §3 step 9 ("every difference accepted") would be signing an acceptance of a known-zero baseline.
4. **A3's own acceptance definition is unmeetable** — `01-staging-project-proposal.md:252` requires
   "19 tables / **38 functions** / **21 policies** / triggers / grants"; the artefact supplies 19 / **0** / **0**.
   (Precondition M-20 `NOT MET`.)
5. **H-3 can half-apply at statement #448** with no transaction wrapper and no rollback path (0 backups, 0 PITR,
   0 slots, delete-and-re-create withdrawn), and the membership question is undecidable offline.
6. **X-7**: the artefact creates `private` and grants nothing on it, so even a successful load would leave the
   helper schema unusable — an independent structural defect on top of the gaps.

This is an **evidence-absence verdict**, not a signature-absence verdict. Signing A3 would not fix it. Note that
**the artefact is legitimate for *review*** (its provenance labels, coverage table and limitations report are honest
and measured); presentable-for-review and load-ready are different claims and only the first is supported.

Status vocabulary applied: A2′(a) `BLOCKED — APPROVAL REQUIRED` · A3 `BLOCKED — APPROVAL REQUIRED` · A5
`IN PROGRESS` (approved, not executable) · A9 `BLOCKED — APPROVAL REQUIRED` · A12
`BLOCKED — APPROVAL REQUIRED` · A1 `NOT APPLICABLE` (`INOPERATIVE`) · Firebase-UID schema work `NOT STARTED`.

---

## 7. Approval requests

This audit **drafts nothing for signature, pre-fills nothing and dates nothing.** It restates the signable text that
already exists so the owner can see precisely what each fence would grant, and names the amendments that must be
decided *before* a fence is even offerable.

### 7.1 A3 — schema load into staging (`approval-package-v2:292–304`, existing text)

```text
A3 — SCHEMA LOAD INTO STAGING
I approve loading the hashed, secret-scanned G3 artefact (and the separate auth.users trigger file) into
dzonzgngwxclhfnvxtvu, after A0 (method as amended 2026-11-02 by C-1: offline reconstruction from the in-repo g1-*
capture) and after A2'(a) has created the sentinel. A1 is INOPERATIVE under the staging-only instruction and is not a
precondition of this or any other block. I forbid loading table data or any production row, hand-editing the
artefact after scan, applying patches, creating secrets, deploying Edge Functions, or touching production.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

**Not signable as written.** The block's own footer already warns: "this fence must not be filled on the assumption
that a baseline exists". Before it can be offered, the owner must additionally decide:

- **(a)** amend `01:252` so the A3 deliverable matches what an offline reconstruction can produce (structural-only
  baseline: 19 tables / 0 functions / 0 policies), **or** accept the current text as knowingly unmeetable — M-20;
- **(b)** accept in writing that **no drift check is possible** against a 2026-10-29/30 baseline (R-28 unsatisfiable,
  M-18) — the alternative is a new production-read approval;
- **(c)** decide the **transaction/batching** treatment of the #448 tail (wrap, batch, or accept half-apply) — H-3;
- **(d)** decide whether the load **re-authorises the 4 emittable policies, the 8 verbatim triggers and the
  `private` USAGE grant**, or whether those remain deferred — §3 H-1/H-3, X-6, X-7;
- **(e)** bind the byte digest `fc996f45…` into an in-repo change record with an owner-named durable artefact
  location — M-16 (the artefact currently lives in a temporary build directory).

### 7.2 A2′(a) — sentinel, before A3 (`approval-package-v2:266–278`; (a) is the pre-A3 half)

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
```

Recorded dependency the owner must not miss: **(b) cannot deliver the Realtime publication** while U-4/U-5 stay
`UNKNOWN` — the four table names are documentary, not catalogued, and `supabase_realtime` ownership was never
queried. A2′(b) signed today would set a publication from a guess.

### 7.3 The 24-item pre-A3 evidence checklist (M-01…M-24) — current measured state

`S2-EXEC-04-a3-precondition-matrix.md` carries 24 rows; this audit re-checked its arithmetic and it is internally
consistent: **MET 6** (M-01, M-06, M-09, M-10, M-11, M-17) · **NOT MET 10** (M-03, M-04, M-05, M-07, M-16, M-18, M-19,
M-20, M-22, M-23) · **NOT VERIFIED 6** (M-08, M-12, M-13, M-14, M-15, M-21) · **NOT APPLICABLE 2** (M-02, M-24).
6 + 10 + 6 + 2 = 24 ✓.

| ID | Item | Class |
| --- | --- | --- |
| M-01 | A0 method decision (recorded, fence unfilled) | MET |
| M-02 | A1 absent from A3's chain | NOT APPLICABLE |
| M-03 | A2′(a) signed **and** executed (sentinel exists) | NOT MET |
| M-04 | A3 signed | NOT MET |
| M-05 | `auth.users` count inside the A3 window | NOT MET |
| M-06 | Secret scan bound to the final artefact | MET |
| M-07 | Reconstruction sufficient for the intended load | **NOT MET (deciding)** |
| M-08 | Dependency order demonstrated | NOT VERIFIED |
| M-09 | Per-object provenance traceable | MET |
| M-10 | Rollback assessed without claiming it works | MET |
| M-11 | Ratification §2 = option (i) | MET |
| M-12 | Ref echo before any statement | NOT VERIFIED |
| M-13 | Session provably targets staging | NOT VERIFIED |
| M-14 | SQL Editor channel operable | NOT VERIFIED |
| M-15 | Per-statement restore log (459 statements, autocommit) | NOT VERIFIED |
| M-16 | Artefact digest bound into A3's evidence, durable location | NOT MET |
| M-17 | No hand-edit after scan | MET |
| M-18 | Drift re-verification before A3 | NOT MET |
| M-19 | Equivalence diff on both sides | NOT MET |
| M-20 | Load meets `01:252`'s own definition | NOT MET |
| M-21 | Quota headroom (log 80 GB / DB 400 MB) re-read | NOT VERIFIED |
| M-22 | 7-day window, dated touch ≤ 2026-11-06, UTC start kept | NOT MET |
| M-23 | C9 compensating evidence for the load | NOT MET |
| M-24 | A2′(b) correctly sequenced *after* A3 | NOT APPLICABLE |

**Items this audit adds to the list** (none is covered by M-01…M-24): bind the X-1 count correction; resolve X-7
(`private` USAGE grant); decide the §4.8 `DEFAULT auth.uid()` columns; obtain the §4.2 owner supersession of
`01-staging-project-proposal.md:196–198` before any Firebase-UID SQL is authored.

### 7.4 Owner decisions requested (the only forward-moving items in this report)

| # | Decision | Blocks |
| --- | --- | --- |
| **OD-1** | Return types for the 3 policy helpers (`boolean`) and the 6 trigger functions (`trigger`) — accept the structural inference explicitly, or keep 21/21 policies suppressed | §3 H-1, steps 7–11 |
| **OD-2** | Whether A3's deliverable is re-scoped to structural-only, or the evidence ceiling is re-opened | M-07, M-20, the verdict |
| **OD-3** | Transaction/batching of the #448 tail, or written acceptance of half-apply | H-3, M-15 |
| **OD-4** | Identity shape S-α vs S-β (§4.6), and the §4.2 supersession of "Firebase Auth is OUT OF SCOPE" | all of §4 |
| **OD-5** | Disposition of `webrtc_signals.from_user_id NOT NULL DEFAULT auth.uid()` and `safe_zones.created_by` | §4.8 |

---

## 8. Documentation defects found and verified (listed, **not edited**)

No existing file was modified by this audit. Each defect below has a measured basis.

| ID | Location | Says | Correct value | Measured basis |
| --- | --- | --- | --- | --- |
| **D-1** | `S2-EXEC-04-independent-g3-audit-report.md:184`; `S2-EXEC-04-sql-structural-findings.md:48` | "12 `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin`" | **9** `supabase_admin` ADP statements (#448–450, 451–453, 457–459); 13 ADP total, 4 `FOR ROLE postgres`. 12 *is* the never-run tail length (#448–#459) | Own parser, statement-indexed enumeration; component grep `70-grants-default-privileges.sql` → 13 active |
| **D-2** | `S2-EXEC-04-sql-structural-findings.md:49` | "236 grants" | **235** (52 table + 183 column) | Statement count, both in component and assembled file |
| **D-3** | `S2-A1-auth-architecture.md:143` and `:154` | "19 tables FK into `profiles`" / "a domain table that 19 tables reference" | **19 inbound FK constraints from 15 distinct tables** | `g1-q5` kind=f, grouped by `referenced_table` and by referencing table |
| **D-4** | `90-limitations.md:126` (L-2), echoed `approval-package-v2:189` | "24 `private` bodies absent" | 24 absent = **12 `public` + 12 `private`** | `g1-b3b.inventory` (14/24) minus `bodies` (12 private + 2 public) |
| **D-5** | `70-grants-default-privileges.sql` / assembled file | *(omission — nothing says it)* | **0 `GRANT … ON SCHEMA` statements of any kind**, though `g1-b3b.schema_usage` evidences `private`: anon `false`, authenticated `true`, service_role `true` and `00-platform-assumptions.sql:46` transcribes it | grep `ON SCHEMA` across the grants component and assembled artefact → 0 hits |
| **D-6** | `g3-reconstruction-2026-11-02.sql:1548`, `:1557` (`60-rls-policies.sql:62`, `:71`) | `CREATE POLICY … USING (None)` | `qual` is JSON `null` for both INSERT policies; correct DDL **omits `USING`** (PostgreSQL INSERT policies take `WITH CHECK` only). `None` is a leaked Python literal, not SQL | `g1-q2` rows `safe_zones_insert_parent`, `webrtc_signals_insert_participant`; exactly 2 null `qual` of 21 || **D-7** | `g3-reconstruction-2026-11-02.sql` (whole file) | provenance cites `g1-*` and `g1-b3b` only | File cites **`functions-and-triggers.md` 0 times** and `schema-columns.md` **0 times**, so it never admitted the 14 narrative return types into its own ceiling and under-declared its reachable coverage | grep counts: 0 / 0 |
| **D-8** | `S2-EXEC-04-a3-precondition-matrix.md:83` (M-07 evidence column) and `90-limitations.md:36–54` | root cause stated as "**0 of 38** return types" | Correct as to **catalogue captures**; the same sentence should not read as though the *evidence set* is silent, since `functions-and-triggers.md:36–49` supplies 14. Retain as a **wording** defect, not a numeric one — consistent with CU-01, which already flags it and which this audit does not resolve | §3 H-2 |
| **D-9** | `01-staging-project-proposal.md:196–198`, `:200` (approved topology) vs the Firebase-UID direction, and `S2-A1` (whole) | "Single identity authority: Supabase Auth"; "Firebase Auth / Firestore / Cloud Functions — **OUT OF SCOPE — must not be enabled**" | The Firebase-UID architecture **contradicts an approved topology**. `S2-A1` proceeds without recording the collision; any Firebase-UID DDL first requires an owner decision that supersedes §6 item 6 and the A12 exclusion clause | Direct read of both files; recorded at §4.2 |
| **D-10** | `S2-A1-auth-architecture.md:142` (I-1) | `auth.uid()` continuity presented as the load-bearing control | Accurate as DDL, incomplete as control: **all 9 Edge Functions use the service-role key, so RLS never applies to live callers** and `auth.uid()` is NULL for them; the only evidenced live `authenticated` path is Realtime (`realtime_topic_allowed`, `auth_exec=true`) | `14-edge-function-security-audit.md:245`; `patches/S2-P02-e3-actor-binding.sql:4`; `g1-b3b.inventory` |
| **D-11** | `S2-EXEC-04-object-coverage-matrix.md:413` (row 10) | "Indexes \| 62 (g1-q4 rows) \| 34 \| 28 suppressed \| … 28 reframed 'not lost'" | The 28 are not merely "not lost", they are **structurally impossible to emit as standalone indexes** — 19 PK + 9 UQ constraint-backed indexes are created implicitly by the 137 constraints. "62 expected" double-counts | `g1-q4`: 31 `CREATE INDEX` + 31 `CREATE UNIQUE INDEX`; `g1-q5`: 19 p + 9 u; 31 − 28 = 3 standalone unique + 31 = 34 ✓ |
| **D-12** | `93-counts.json` `expected.indexes: 62` next to `statement_types` 31+3 | 62 vs 34 | Same as D-11: the JSON presents both numbers without the reconciliation, inviting the "28 lost indexes" reading | §1.2 |

**Not defects — verified correct as recorded:** 459 statements; 19 tables; 183 columns; 137 constraints; 34 indexes;
19 RLS enables; 235 grants; 13 ADP; 0 functions/triggers/policies/publications/extensions; 21 policies over 15
tables; 0/19 `rls_forced`; 38 = 14 + 24 functions; 14 bodies present; statement #448 position; 69 defaults; the
`USING (None)` finding (M-3, already logged); the "4 of 21 emittable" finding (CU-03, already logged); the 13/3/1
helper split (already in `S2-EXEC-05-function-body-coverage-register.md:145`); the M-01…M-24 arithmetic.

---

## 9. What this audit could not determine, and why

1. **Which 38 function signatures actually exist as executable DDL** — `MISSING — SOURCE EVIDENCE ABSENT`
   (0 return types in every capture; 24 bodies unread). Only a `pg_proc` read of production closes it, and A1 is
   `INOPERATIVE`.
2. **Whether a load would abort at #448** — requires `pg_auth_members` membership of `supabase_admin` **on staging**,
   which has never been read. Staging membership is assumed to mirror production; that assumption is untested.
3. **Extensions, sequences, views/matviews/foreign tables, publication membership, publication ownership, WAL /
   logical decoding, non-`authenticator` role attributes** — the 7 `UNKNOWN` populations of §2; none was ever
   queried. A single additional catalogue read (`pg_extension`, `pg_class` unfiltered, `pg_publication*`,
   `pg_settings`, `pg_roles`) would resolve all seven; every such read is currently unauthorised.
4. **Whether the reconstruction is production-equivalent at all** — the equivalence diff has no behavioural side, and
   the production baseline is point-in-time 2026-10-29/30 with no drift check available (M-18).
5. **Whether the dependency order is correct under execution** — provable only by a dry run, and every channel
   (CLI, Docker, `pg_dump`, `db reset`) is excluded by C1; the order that matters most (functions → triggers →
   policies → publication) contains **no statements**, so its correctness is untestable by construction.
6. **`auth.users` contents and count** — deliberately not read (B-3 places that count *inside* the unsigned A3
   window). Any claim that staging has zero auth users remains `NOT VERIFIED`, which also conditions P01 §0.4.
7. **Whether `auth.uid()` returns NULL for every live caller** — strongly evidenced (D-10) but **not proven**: it
   depends on Edge Function runtime behaviour, and the Edge Function sources are still unread (PA1);
   `functions-and-triggers.md` §3 is explicitly "a source-form scan, not a review."
8. **Realtime end-to-end authorisation** — `realtime_topic_allowed` is captured, but with no publication, no
   `replica identity` evidence and no WAL knowledge, Realtime cannot be reasoned about from this schema at all.
9. **The Firebase-UID design's own feasibility** — the admin capability to create/fetch an `auth.users` identity for
   a bridged subject is `NOT VERIFIED` in this repository (no in-repo evidence such a call exists or is permitted),
   so §4.6 S-α may be unimplementable rather than merely unapproved.
10. **Whether the artefact's bytes are the bytes any reviewer saw** — digests are self-published by one build, the
    repository has zero commits, and the artefact lives in a temporary directory. Consistency is proven; authorship
    and durability are not (M-16).

---

## 10. Evidence classification

**Verified (read from a named file or measured here).** Both artefact digests, 150,566 bytes, 1,951 lines; 459 active
statements and their 9-class breakdown; 0 functions/triggers/policies/publications/extensions; 0
`BEGIN`/`COMMIT`/`SET ROLE`; 183 columns matching `g1-q8` per table; 137 constraints = 19p+44f+9u+65c; `g1-q4` 62 rows
= 31+31 and the 28-constraint-backed reconciliation; 235 grants with column-class symmetric difference 0 and table-
class Δ 19; 19 `rls_enabled` / 0 `rls_forced`; 21 policies across 15 tables, 4 with no helper, 17 with helpers, 13/3/1
helper split, 2 null `qual`; 38 functions = 14+24; 14 bodies = 12 `private` + 2 `public`; 24 absent = 12+23-twin-
counted; no return-type field in any of 11 evidence JSONs; `profiles_id_fkey` as the sole auth FK, cascade on 34
constraints; 19 inbound profiles FKs from 15 tables; 8 `CREATE TRIGGER` texts verbatim in `g1-q3`/`q3b`; 3 helper
bodies + `handle_new_user` body + `realtime_topic_allowed` body; 69 defaults with exactly 2 `DEFAULT auth.uid()`;
no push-token column among 183; `g1-q6.role_memberships` 24 rows with no `supabase_admin`; `g1-b3b.schema_usage`
for `private`; `authenticator` `statement_timeout=8s`/`lock_timeout=8s`; service-role usage by all 9 Edge Functions
at `14-edge-function-security-audit.md:245` and `S2-P02:4`; the M-01…M-24 arithmetic; **and that this audit changed
no file and left the artefact hash unchanged.**

**Inferred (follows from evidence; not observed).** That the 28 suppressed indexes are created implicitly by the
constraints; that the Δ 19 table-grant triples are a deliberate `g1-q1` ACL merge; that trigger functions return
`trigger` and the 3 helpers return `boolean` (structural implication of `EXECUTE FUNCTION` and of policy predicate
syntax — **explicitly not adopted as SQL**, see OD-1); that `postgres` owns the 24 `private` functions (from ACL
grantor suffix); that a service-role load would bypass the #448 membership error.

**Missing evidence.** All 38 return types in catalogue form; 24 of 38 bodies; every one of the 7 `UNKNOWN`
populations; publication membership and ownership; extension requirement of `gen_random_uuid()`; sequence list;
identity/generated columns; collation/domain detail; `private` function ownership; a push-token column; a
deletion-propagation contract; an email-merge-key posture beyond the unverified local `config.toml`; any production
`pg_auth_members` fact about staging.

**Unverified.** `auth.users` count and emptiness on staging; production Data API toggle effects; the live value of
`enable_manual_linking`; production `default_acl` at load time (drift); whether SQL Editor clicks work at all
(M-14); whether the Edge Functions ever rely on RLS; the artefact's authorship chain and durability; the local-clock
mtime used to close M-17.

**Recommendations (design input only; each grants nothing).**
R-1 Do not fold Firebase-UID objects into the G3 file — keep reconstruction and proposal in separate artefacts so the
equivalence diff stays honest. R-2 Re-author (never hand-edit) `40`/`50`/`55`/`60` from the captured `g1-q3`/`q3b`
trigger DDL and the captured bodies, once OD-1 names the return types; this recovers 8 triggers and 21 policy texts
without inventing anything. R-3 Fix `gen_g3.py` to omit `USING` on null `qual` and re-run the scan, so D-6 cannot
recur. R-4 Emit the `private` USAGE grant from `g1-b3b.schema_usage` (X-7/D-5) — it is evidenced, currently absent,
and the artefact is otherwise unusable. R-5 Add one `pg_auth_members`, one `pg_default_acl` and one
`pg_extension`/`pg_publication` capture to the A3 evidence set as *staging* reads: zero production risk, and they
close H-3 and most of the 7 `UNKNOWN`s. R-6 Record the §4.2 topology contradiction as an owner decision before any
Firebase-UID SQL is drafted, rather than resolving it silently in an architecture document.

---

*Prepared by subagent A3 (Supabase Database & Schema Specialist). Read-only: no file outside this deliverable was
created or modified, no SQL was executed, no project was contacted. This document authorises nothing.*
