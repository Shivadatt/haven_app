# S2-EXEC-04 — G3 object coverage matrix

Domain: **object coverage only** for the S2-EXEC-03 offline Supabase/Postgres reconstruction in
`C:\Users\ASUS\.qoder\tmp\D--control\g3-build\` (components `00`–`80`, assembled
`g3-reconstruction-2026-11-02.sql`, reports `90`–`96`).

- Built by S2-EXEC-04 (read-only audit). **No cloud, no dashboard, no CLI, no SQL executed, no DB connection.**
  Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was not touched.
- Evidence basis (read first, per instruction): `docs/stage1/evidence/g1-run-manifest-20261029.md`.
- Every **expected** number below is measured from a named evidence file + the JSON key/field that produced it.
  Every **reconstructed** number is measured from the artefact file + line range. Unknowns are written `UNKNOWN`
  with the blind-spot explained. No count was invented to fill a row.
- Credential/PII note: the audit read catalogue metadata and function source only. ACL strings contain **role
  names** (anon/authenticated/service_role/postgres/supabase_*), not secrets; `search_path` settings, function
  `prosrc`, and the Edge `CRON_SECRET` *name* were seen. No key/JWT/password/PII value is reproduced here.

Six-state vocabulary used for every category:
`PRESENT — SOURCE VERIFIED` / `PRESENT — PARTIAL` / `MISSING — SOURCE EVIDENCE ABSENT` /
`UNVERIFIED — SOURCE AMBIGUOUS` / `NOT APPLICABLE — EVIDENCE SUPPORTED` / `CONFLICT — SOURCE DISAGREEMENT`.

Manifest grounding (what each g1 query selected, from `g1-run-manifest-20261029.md` §Files):
Q1 19 rows `table,rls_enabled,rls_forced,owner,table_acl`; Q2 21 rows policies; Q3 7 `public` triggers;
Q3b 1 `auth.users` trigger; Q4 62 indexes+definitions; Q5 137 constraints+definitions; Q6 grants(149)/
column-grants(191)/default-acl(24)/role-memberships(24); Q7 18 `public`+`auth` functions (no schema column);
Q8 183 columns; Q9 linter (5 rules/33 occurrences); Q10 `schema_usage`+14 public functions; B3b 38-function
inventory + 14 bodies + `auth.users`-adjacent + `private` schema_usage + authenticator config + Data API page.

---

## Independent re-measurement of the artefact's own totals (pre-check)

`g3-reconstruction-2026-11-02.sql` active (non-comment) statements, counted by stripping `--` and splitting on
`;`:

| Component | Active executable statements | Line range of active SQL |
| --- | ---: | --- |
| `00-platform-assumptions.sql` | 2 (`CREATE SCHEMA` public, private) | 33–36 |
| `10-tables.sql` | 19 (`CREATE TABLE`) | 23–271 |
| `20-constraints.sql` | 137 (`ALTER TABLE … ADD CONSTRAINT`) | 21–163 |
| `30-indexes.sql` | 34 (`CREATE INDEX`/`CREATE UNIQUE INDEX`) | 19–80 |
| `40-functions.sql` | 0 | — (865 lines, all comment) |
| `50-triggers.sql` | 0 | — |
| `55-auth-users-trigger.sql` | 0 | — |
| `60-rls-policies.sql` | 19 (`ENABLE ROW LEVEL SECURITY`) | 19–37 |
| `70-grants-default-privileges.sql` | 248 (235 `GRANT` + 13 `ALTER DEFAULT PRIVILEGES`) | 27–285, 321–338 |
| `80-realtime-publication.sql` | 0 | — |
| **Total** | **459** | |

Assembled file active-statement count = **459** (equals the component sum; the assembly adds no statements).
Active `CREATE FUNCTION`/`CREATE TRIGGER`/`CREATE POLICY`/`ALTER PUBLICATION`/`CREATE EXTENSION`/
`FORCE ROW LEVEL SECURITY` in the assembled file = **0** each. **AGREEMENT** with `91-coverage.md` line 35–36
(459 active) and with its "Active function / trigger / policy / publication statements: 0".

`70` GRANT composition re-measured at statement level: 33 aggregated table grants (from Q6 149 rows) +
183 column-scoped `GRANT UPDATE` (from Q6 191 rows) + 19 `GRANT MAINTAIN ON TABLE … TO service_role`
(from Q1 acltext) = **235**; plus 13 `ALTER DEFAULT PRIVILEGES`. **AGREEMENT** with `91-coverage.md`
and `70` lines 359–360.

---

## 1. Extensions

- **Expected:** `UNKNOWN`. No `pg_extension`/`CREATE EXTENSION` row exists anywhere in Q1–Q10 or B3b
  (`g1-run-manifest-20261029.md` Files table lists no extension query). I re-checked `g1-q9` and `g1-q10`
  for overlooked extension evidence: **0** matches for `extension`/`publication`/`view`/`sequence` object rows;
  Q10's single "extension" hit is the *field name* `extension_owned` (boolean per function), not an extension
  inventory. So the prior did **not** overlook an extension list in Q9/Q10 — the blind spot is genuine.
- **Emitted active:** 0 (no `CREATE EXTENSION`). `00` lines 20–25 record `gen_random_uuid()` (16 Q8 defaults),
  `jsonb` (native) and `supautils`/`safeupdate` as **INFERRED comment-only notes**, explicitly forbidding
  `CREATE EXTENSION` from them.
- **Comment-only/unexecutable:** 3 inferred lines (`00` 22–24).
- **State:** `MISSING — SOURCE EVIDENCE ABSENT`. Reason: the expected count is `UNKNOWN` (not zero);
  `pgcrypto` is *suggested* by `gen_random_uuid()` defaults (`g1-q8.column_default`, 16 rows) but never asserted
  by a catalogue query, so no extension DDL can be emitted or verified. On an A3 load, any object depending on a
  non-default extension would fail.

## 2. Schemas

- **Expected (application):** 2 — `public` and `private`. Evidence: `public` owns all 19 Q1 tables
  (`g1-q1.table_name`) and 14 public functions (`g1-b3b.inventory.rows[schema_name]=public`); `private` holds 24
  functions (`g1-b3b.inventory.rows[schema_name]=private`, count `private`=24) and `g1-b3b.schema_usage`.
- **Expected (platform):** `auth`, `storage`, `extensions`, `realtime`, `graphql`, `graphql_public` — evidenced
  **only** as `g1-q6.default_acl[schema_name]` values (public=6 rows, one each ×3 for the 6 platform schemas;
  `g1-b3b.data_api_exposure.schemas_exposed_chips` = public, extensions). These are out of A0 scope → §22.
- **Emitted active:** 2 — `CREATE SCHEMA IF NOT EXISTS public;` (`00` line 33) and `… private;` (`00` line 35).
- **State:** `PRESENT — SOURCE VERIFIED` for the 2 application schemas. Platform schemas intentionally excluded.

## 3. Tables

- **Expected:** 19 — `g1-q1` returns 19 rows (`table_name`), owner `postgres` for all 19
  (`g1-q1.owner`). `g1-q5` confirms 19 primary keys (one per table).
- **Emitted active:** 19 `CREATE TABLE public.*` (`10` lines 23–271), one per captured relation; no table defined
  twice; PK/UNIQUE/FK are NOT inlined in `10` (0 `PRIMARY KEY`/`UNIQUE`/`REFERENCES` tokens in `10` active SQL) so
  they cannot collide with `20`.
- **State:** `PRESENT — SOURCE VERIFIED`. **Blind spot (kept out of this row's count):** Q1 is described by
  `91-coverage.md` as filtering `relkind='r'`; the query predicate itself is **not in the JSON** (only its 19
  result rows), so whether any view/materialised view/foreign table/sequence exists in `public` is
  `UNKNOWN`, not empty — see §22.

## 4. Columns and data types

- **Expected:** 183 columns — `g1-q8` row count (183). Types per `g1-q8.data_type`: uuid 61, `timestamp with
  time zone` 44, text 43, boolean 13, jsonb 7, integer 6, `double precision` 5, bigint 2, real 1, date 1.
  Nullability from `g1-q8.is_nullable` (NO 137 / YES 46).
- **Emitted active:** 183 inline column definitions inside `10` (re-counted: 183 column lines across the 19
  `CREATE TABLE` blocks), with data type, ordinal order and NOT NULL verbatim.
- **Not captured by Q8 (disclosed gaps, not invented):** `g1-q8` selects only
  `{table_name,column_name,ordinal_position,data_type,is_nullable,column_default}` — there is **no
  `collation_name`, no domain, no `is_identity`, no `generation_expression`, no storage-parameter** field.
  `schema-columns.md` (pre-G1 dashboard note) confirms it does not add these ("Not captured here: …").
- **Comment-only:** none needed; gaps are the absence of the attributes themselves.
- **State:** `PRESENT — PARTIAL`. Data type / name / ordinal / nullability = SOURCE VERIFIED; **collations and
  domain types = MISSING — SOURCE EVIDENCE ABSENT**. Consequence for load: the 43 `text` columns are emitted with
  database-default collation, so a staging DB with a different default could sort/compare differently than prod —
  undetectable from this evidence.

## 5. Defaults and identity definitions

- **Expected defaults:** 69 — columns with a non-null `g1-q8.column_default` (re-counted; 114 of 183 null).
  Distinct default expressions: 23 `now()`, 16 `gen_random_uuid()`, 4 `false`, 3 `'{}'::jsonb`, 3 `'pending'::text`,
  3 `0`, 2 `''::text`, 2 `'active'::text`, 2 `auth.uid()`, 1 each `'code'::text`, `'android'::text`, `10`, …
- **Emitted defaults active:** 69 `DEFAULT` clauses in `10` (re-counted = 69). **AGREEMENT** with `91-coverage.md`
  ("Type, ordinal, nullability and default verbatim").
- **Identity / generated columns:** expected count `UNKNOWN`; **`g1-q8` has zero `nextval` defaults**
  (re-measured 0) and no identity/generation columns, and no query selects `attidentity` /
  `attgenerated`. Artefact emits **0 `GENERATED` and 0 `IDENTITY`** in `10`. `schema-columns.md` token "generated"
  is the word "regenerated" in a comment, not an attribute.
- **State:** `PRESENT — PARTIAL`. **Defaults = SOURCE VERIFIED** (69/69). **Identity / generated columns =
  MISSING — SOURCE EVIDENCE ABSENT** — never captured, so cannot be confirmed present or absent in prod. This is
  the second load-relevant gap (an `INTEGER GENERATED ALWAYS AS IDENTITY` primary key would currently rebuild as a
  plain integer column with no sequence).

## 6. Primary keys

- **Expected:** 19 — `g1-q5` rows with `kind='p'` = 19 (one per table; `91-coverage.md` claims 19).
- **Emitted active:** 19 `ADD CONSTRAINT … PRIMARY KEY` in `20` (kind-classified re-count: PK 19).
- **Cross-check:** each PK has a same-named backing `_pkey` index in `g1-q4` (19 `_pkey` names) — see §10.
- **State:** `PRESENT — SOURCE VERIFIED`.

## 7. Foreign keys

- **Expected:** 44 — `g1-q5` `kind='f'` = 44, all with a non-null `referenced_table` (44). Delete rules:
  `on_delete_code='c'` (CASCADE) 34, `'n'` (SET NULL) 10, `' '` blank 93 (all non-FK rows) — the 34+10 partition
  covers exactly the 44 FKs. `validated` is `true` for all 137 (`g1-q5.validated`).
- **Emitted active:** 44 `ADD CONSTRAINT … FOREIGN KEY … REFERENCES …` in `20`, ON DELETE decoded from the codes.
- **State:** `PRESENT — SOURCE VERIFIED`.

## 8. Unique constraints

- **Expected:** 9 — `g1-q5` `kind='u'` = 9.
- **Emitted active:** 9 `ADD CONSTRAINT … UNIQUE` in `20`. Each has a same-named backing index in `g1-q4`
  (`_key`/`_constraint` names = 9) — see §10.
- **Note:** 3 further standalone `UNIQUE` indexes are *not* constraints
  (`devices_one_active_per_child`, `families_one_active_per_owner`, `family_members_one_active_child_family`);
  they are emitted as `CREATE UNIQUE INDEX` (§10), correctly **not** folded into this count.
- **State:** `PRESENT — SOURCE VERIFIED`.

## 9. Check constraints

- **Expected:** 65 — `g1-q5` `kind='c'` = 65, all `validated=true`.
- **Emitted active:** 65 `ADD CONSTRAINT … CHECK` in `20` (kind-classified re-count: CHECK 65).
- `g1-q5.validated` is `true` for **all 137** rows (re-measured Counter {True: 137}); no NOT VALID / INVALID state
  to reproduce.
- **State:** `PRESENT — SOURCE VERIFIED`.

## 10. Indexes

- **Expected:** 62 — `g1-q4` row count (62).
- **Constraint-backed (must be suppressed):** 28. Independent cross-reference: the 28 `kind in (p,u)` constraint
  names in `g1-q5` each appear verbatim as an `index_name` in `g1-q4` (19 `_pkey` + 9 `_key`/`_constraint`) —
  **28/28 matched, 0 unmatched.** Emitting them again as `CREATE INDEX` would fail "already exists" on load.
- **Emitted active:** 34 `CREATE INDEX` in `30` (lines 19–80) = 31 plain + **3 `CREATE UNIQUE INDEX`** (the three
  non-constraint unique indexes above). File self-count (`30` line 82): `emitted=34 suppressed=28 total=62`.
- **Comment-only/unexecutable:** 28 suppressed `CREATE INDEX` recorded as comments in `30`.
- **State:** `PRESENT — SOURCE VERIFIED` for all 62 as a set (34 emitted directly, 28 represented by their
  same-named constraints in `20`). **AGREEMENT** with `91-coverage.md` (34 emitted / 28 suppressed). The prior's
  `91-coverage` "Indexes 62 | 34 emitted | 28 missing" phrasing calls the suppressed 28 "missing" — my refinement:
  they are **not lost**, they are created implicitly by the constraints, so this is coverage-complete, not missing.

## 11. Functions and overloads

- **Expected (application functions):** 38 — `g1-b3b.inventory.count`=38, public 14 + private 24
  (`g1-b3b.inventory.public_count`/`private_count`). Corroborated by Q7 (14 public + 4 `auth.*` internal) and
  Q10 (14 public). The 4 `auth.email/jwt/role/uid` are Supabase-internal (excluded from the B3b inventory) →
  platform, §22.
- **Overloads:** 0. `g1-b3b.inventory.rows` has **no duplicate `(schema_name, function_name)`** and Q7/Q10 have no
  duplicate `function_name`. The 13 names appearing in both `public` and `private` are **cross-schema twins**,
  not overloads. So overload reconstruction is **`NOT APPLICABLE — EVIDENCE SUPPORTED`**.
- **Emitted active:** **0**. `40-functions.sql` records 38 inventory blocks (24 private + 14 public, re-counted)
  as comments only; 0 executable `CREATE FUNCTION`. Root reason (its header, lines 14–21): the approved evidence
  selects **no `prorettype`/return type** in any catalogue query, and `91-coverage.md` §5.2 forbids guessing.
- **Comment-only/unexecutable:** 38 signature blocks; **14 bodies preserved verbatim as comments** (`40`
  re-count: `body: PRESENT`=14, `body: NOT PRESENT`=24) — never converted to runnable DDL.
- **State:** `MISSING — SOURCE EVIDENCE ABSENT` for the executable object. Existence and signatures ARE source-
  verified; the *definition* (bodies 24/38 absent, return types see §12) cannot be reconstructed, and the 24
  private bodies additionally fail the A5 D-06 prosrc-hash check. This cascades to §14, §16, §19.

## 12. Function return types and arguments

- **Arguments — expected/emitted:** 38/38 argument lists captured (`g1-b3b.inventory.rows[arguments]`, also
  `g1-q7.arguments`, `g1-q10.arguments`) and recorded verbatim in `40` comment signatures. **SOURCE VERIFIED.**
  (Nuance: `functions-and-triggers.md` §1 shows `poll_device_commands(p_limit integer DEFAULT 20)` — an argument
  *default* that the catalogue queries did not select and that `40` therefore does not carry.)
- **Return types — DISAGREEMENT with the prior number.**
  - Artefact / `90-limitations.md` line 34–37 asserts: *"All **38 of 38** functions therefore have an unknown
    return type"* and calls it *"the root blocker"*, justification *"No query in the approved G1 evidence series
    selects a function return type."* That justification is correct about **Q1–Q10 / B3b** (no `prorettype`).
  - **But the same evidence directory contains `functions-and-triggers.md` §1 (lines 34–49), a dashboard-derived
    transcription that documents the `Returns` type for all 14 public functions**: `jsonb` ×10, `integer` ×3
    (`detect_offline_devices`, `expire_stale_commands`, `expire_stale_sessions`), plus `replace_device_apps` →
    `integer` and `request_remote_session` → `remote_sessions (row type)`. The artefact **never cites this file**
    (grep: 0 references in `40`, `90`, `92`, `96`).
  - So the true return-type evidence position is **14 of 38 present (narrative/dashboard-derived), 24 absent** —
    not 0/38. The `g1-run-manifest-20261029.md` amendment 2 labels `functions-and-triggers.md` a "narrative
    transcription, not a raw export," and its §1 header ("14, all SECURITY DEFINER") was itself superseded by B3b
    (38). Therefore the 14 types are **narrative-supported, not catalogue-verified**, and 0 functions are *still*
    emittable (24 private bodies absent + the public RPCs depend on private helpers). **Operational conclusion
    (0 emittable) holds; the prior's evidence count "38/38 return types absent" is wrong.**
- **State:** `CONFLICT — SOURCE DISAGREEMENT` — between `40`/`90-limitations.md` ("none in evidence") and
  `functions-and-triggers.md` §1 (14 return types documented). Return types that remain genuinely absent: the 24
  private-only functions (13 of which have public twins whose narrative types could be *inferred*, never verified).

## 13. Function security properties (definer/invoker, `search_path`)

- **Expected definer flags:** 38 — `g1-b3b.inventory.rows[security_definer]` (34 `true`, 4 `false`; the four
  non-definers are trigger helpers). Corroborated by `g1-q7.security_definer` for the 14 public rows and the B3b
  amendment in `functions-and-triggers.md` (lines 14–16).
- **Expected `search_path`:** 38 — `g1-b3b.inventory.rows[settings]` and `g1-q7.settings` pin a `search_path` on
  every function; two omit `private` (`public.request_remote_session`, `private.remote_session_transition_guard`)
  per `functions-and-triggers.md` line 20–21 and Q7.
- **Emitted active:** 0 (no `CREATE FUNCTION … SECURITY DEFINER/SET search_path` — blocked by §11/§12).
- **Comment-only:** 38 blocks record `security_definer` and `search_path` verbatim (`40`).
- **Owner:** `g1-q7.owner`=postgres for the 14 public (and `auth.*`); **`g1-b3b.inventory` has no `proowner`
  column** (manifest amendment 3), so the 24 private owners are **INFERRED from the ACL grantor `/postgres`**, not
  verified. `40` (line 24, per-block `owner: INFERRED`) states this correctly.
- **State:** `PRESENT — PARTIAL` — definer flag + `search_path` SOURCE VERIFIED and recorded for 38/38, but 0
  emitted, and private ownership INFERRED.

## 14. Triggers (on `public` tables)

- **Expected:** 7 — `g1-q3` rows (re-counted 7). All `enabled_flag='O'` (enabled); `security_definer` False ×6 +
  True ×1 (`remote_sessions_transition_guard`). Definitions verbatim in `g1-q3.definition`; corroborated by
  `functions-and-triggers.md` §2 (same 7) and `g1-b3b.remote_session_triggers` (the 1 on `remote_sessions`).
- **Emitted active:** **0**. `50-triggers.sql` (39 lines) records all 7 `CREATE TRIGGER …` verbatim as comments
  (lines 18–37), each tagged `(BLOCKED ON SECTION 40)`; self-count line 39: `captured=7 emitted=0`.
- **Comment-only/unexecutable:** 7.
- **State:** `PRESENT — PARTIAL`. Trigger *definitions* are SOURCE VERIFIED and reproduced verbatim (this is not
  "evidence absent"); emission is blocked purely by the §11/§12 dependency on `private.*` functions.

## 15. RLS enablement and forced-RLS state

- **Expected enablement:** 19 tables `rls_enabled=true` (`g1-q1.rls_enabled`, re-counted all True).
  **Forced-RLS:** `g1-q1.rls_forced` = **false for all 19** (re-counted Counter {False:19}).
- **Emitted active:** 19 `ALTER TABLE public.* ENABLE ROW LEVEL SECURITY` (`60` lines 19–37) and **0 `FORCE ROW
  LEVEL SECURITY`** — matching `rls_forced=false` exactly. Self-count `60` line 78: `enablement emitted=19`.
- **Scope caveat:** Q1 covers `public` tables only; `auth`/`storage` table RLS state is not in this evidence
  (platform, §22).
- **State:** `PRESENT — SOURCE VERIFIED`. `rls_forced` was **captured** and reproduced faithfully (correctly no
  FORCE emitted). **AGREEMENT** with `91-coverage.md` (19 ENABLE / 0 FORCE).

## 16. RLS policies

- **Expected:** 21 policies — `g1-q2` rows. All `permissive='PERMISSIVE'`, all `roles=[authenticated]`, command
  mix SELECT 15 / UPDATE 3 / INSERT 2 / DELETE 1, spanning 15 distinct tables. 4 of the 19 RLS-enabled tables have
  **no** policy (`child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states`) — this
  cross-checks exactly against the Q9 `rls_enabled_no_policy` finding (`g1-q9`, count 4). 19 enabled − 15
  policy-bearing = 4; consistent.
- **Emitted active:** **0**. `60-rls-policies.sql` records all 21 `CREATE POLICY …` verbatim as comments (lines
  40–76), each tagged `(BLOCKED ON SECTION 40)`; self-count line 78: `policies captured=21 emitted=0`. The file
  note (line 16–17) says 17 of 21 predicates call `private.*` — re-measured from `g1-q2`: **17** call `private.*`,
  **4** do not (`families_update_owner`, `profiles_update_self`, `webrtc_signals_insert_participant`,
  `webrtc_signals_select_participant`) — **AGREEMENT**. (The 4 non-`private` ones still call `auth.uid()`, which is
  likewise platform-defined and uncreatable, so all 21 remain blocked.)
- **Comment-only/unexecutable:** 21.
- **State:** `PRESENT — PARTIAL` — definitions SOURCE VERIFIED and reproduced verbatim; 0 emitted due to the
  §11 dependency. **AGREEMENT** with `91-coverage.md` (21 captured / 0 emitted).

## 17. Grants and ACLs — and the Q1-vs-Q6 source disagreement

- **Two independent ACL sources disagree.** Re-measured at statement level:
  - `g1-q6.table_grants` = **149** rows of `(table_name, grantee, privilege_type)`, `is_grantable='NO'` for all
    149 (re-counted) → no `WITH GRANT OPTION` needed. Distinct `(table,grantee)` pairs = **33**.
  - `g1-q1.table_acl` (acltext) expanded by aclexplode (one tuple per table × grantee × privilege-letter) =
    **320 distinct triples**: 152 `postgres` (owner self-grant `arwdDxtm` on 19 tables), 152 `service_role`,
    16 `authenticated` privilege-letters across 14 tables. Set difference:
    **Q1-only = 171** (152 postgres-owner + 19 `service_role` **MAINTAIN**), **Q6-only = 0**. So Q6 ⊂ Q1.
  - **AGREEMENT** with `91-coverage.md` (149 rows, 33 aggregate, 171 Q1-only, 152 postgres-owner, 0 Q6-only) and
    with the task's "320 vs 149 with 171 Q1-only". The two sources are internally consistent in the other
    direction (nothing in Q6 is missing from Q1).
  - **Why they differ:** `aclexplode` of Q6 omits the **owner's self-grants** (postgres, which holds implicit all
    privileges) and — critically — reports **0 `MAINTAIN` rows**, whereas Q1 acltext carries the PG17
    `MAINTAIN` letter `m` on **38** triples (19 postgres + 19 `service_role`; re-measured:
    Q1 MAINTAIN=38, **Q6 MAINTAIN=0**). This is the PG17 `m` blind spot the task flagged: the Q6 privilege-name
    decoding evidently predates / drops `MAINTAIN`, while the raw acltext retains it.
- **Emitted active (reconstructed):** 33 aggregated `GRANT` (table) + 183 `GRANT UPDATE` (column) + 19 `GRANT
  MAINTAIN … TO service_role` = 235 (`70`). The 19 MAINTAIN grants are emitted **from Q1 acltext** (Q6 could not
  supply them), each annotated `-- SOURCE: g1-q1.table_acl (acltext), not g1-q6`.
- **Comment-only/unexecutable:** 19 `NOT EMITTED … TO postgres` owner-grant statements (the 152 postgres triples
  aggregated to 19, `70` lines 83–101) — postgres is platform-managed, so recorded, not emitted.
- **Column UPDATE grants:** `g1-q6.update_column_grants` = **191** rows → **183** distinct `(table,column)`
  (8 columns held by two grantees `authenticated`+`service_role`: families.name, families.settings,
  profiles.display_name, safe_zones.{active,lat,lng,name,radius_m}); those 8 merge into one statement listing both
  grantees, so all 191 rows are represented by 183 active `GRANT UPDATE`. **AGREEMENT** with `91-coverage.md`.
- **State:** `PRESENT — PARTIAL` for the artefact (all 320 acltext triples accounted: 149 emitted via Q6, 19
  MAINTAIN emitted via Q1, 152 postgres recorded as 19 comments) — **with a `CONFLICT — SOURCE DISAGREEMENT` flag**
  on the underlying Q1.table_acl vs Q6.aclexplode count (320 vs 149), which the artefact resolves by emitting from
  Q6 and back-filling the Q1-only MAINTAIN/postgres deltas rather than trusting either source alone.

## 18. Default privileges

- **Expected:** 24 `ALTER DEFAULT PRIVILEGES` source rows — `g1-q6.default_acl` (24 rows). Expanded by
  `(owner, schema, object_type, grantee, priv-set)`: **70** grantee-privilege entries across the 24 ACL strings.
  Breakdown: `schema_name` public 6 + storage/extensions/graphql/graphql_public/realtime/auth (3 each);
  `object_type` S (sequences) 8, f (functions) 8, r (relations) 8; `owner` supabase_admin 15, postgres 6,
  supabase_auth_admin 3. **Note: zero rows for `private`** — private has no default-ACL evidence.
- **Emitted active:** **13** `ALTER DEFAULT PRIVILEGES` — exactly the entries with application schema (public) and
  application grantee (anon/authenticated/service_role). Re-measured independently: 13 app-schema+app-grantee
  entries. **AGREEMENT** with `91-coverage.md`.
- **Comment-only/unexecutable:** **57** commented default-privilege lines (70 − 13) for platform-managed schemas
  and grantees. Re-counted: 57 commented `ALTER DEFAULT PRIVILEGES` in `70` (lines 321–358 region).
  **AGREEMENT** with `91-coverage.md`. Privilege letters decoded to names (incl. `m`→`MAINTAIN`).
- **State:** `PRESENT — PARTIAL` — the 13 application-relevant default privileges emitted; the 57
  platform-managed entries recorded, not emitted (A0 forbids recreating platform objects). Object_type `S`
  confirms **sequences exist** for which default privileges are set (see §22 sequences).

## 19. Realtime publication membership

- **Expected:** `UNKNOWN` — the G1 series captured **no `pg_publication` / `pg_publication_tables` query**
  (`80` line 14; manifest Files table has none). The "4 tables" figure (`device_commands`, `remote_sessions`,
  `safety_alerts`, `webrtc_signals`) is **documentary** only, from `docs/stage2/01-staging-project-proposal.md:61`
  and approval-v2 3.3(b).
- **Emitted active:** **0**. `80-realtime-publication.sql` records the 4 `ALTER PUBLICATION supabase_realtime
  ADD TABLE …` as comments tagged `(AFTER A3 … NOT EMITTED)` (lines 20–23).
- **Comment-only/unexecutable:** 4.
- **State:** `MISSING — SOURCE EVIDENCE ABSENT` — production membership was never captured; correctly a post-A3
  operation, and its count is INFERRED-FROM-DOCUMENTATION, not measured. **AGREEMENT** with `91-coverage.md`
  (4 / 0 emitted, INFERRED).

## 20. Auth-related configuration

- **Captured pieces (SOURCE VERIFIED):** the `auth.users` trigger (`g1-q3b`, see §21); `schema_usage` on `public`
  (Q10 anon/authenticated) and `private` (`g1-b3b.schema_usage` anon false / authenticated true / service_role
  true); **authenticator role config** (`g1-b3b.authenticator_role_config`: `rolsuper=false`,
  `rolbypassrls=false`, `rolconfig=[session_preload_libraries=supautils,safeupdate; statement_timeout=8s;
  lock_timeout=8s]`); Data-API exposure (`g1-b3b.data_api_exposure`: 2 of 3 schemas, 0/19 tables, 0/38 functions,
  max_rows 1000). These are mirrored as **comment-only** config notes in `00` lines 41–47.
- **Not SQL-reconstructable (dashboard narrative only):** Supabase Auth settings in `functions-and-triggers.md` §4
  (JWT access-token expiry 3600 s, refresh-token rotation enabled, reuse interval 10 s, single-session/time-box
  "Pro-plan", connection-pool 15). **`SSL enforcement` and `Connection logging` states are explicitly marked
  "NOT CAPTURED"** (that file lines 109, 111). None of these can be emitted as schema SQL.
- **State:** `UNVERIFIED — SOURCE AMBIGUOUS` for the Auth *settings* (transcribed from a settings page, two
  toggles not captured, effects "NOT exercised" per `data_api_exposure.interpretation_limits`), while the role /
  schema-usage / trigger sub-items are SOURCE VERIFIED. Overall recorded as configuration notes, 0 emitted SQL.

## 21. The `auth.users` trigger

- **Expected:** 1 — `g1-q3b` (1 row): `on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE
  FUNCTION private.handle_new_user()`, `enabled_flag='O'`, `security_definer=true`,
  `function_settings='search_path=public, private, pg_temp'`. This is the **only** user-defined trigger on
  `auth.users` (`g1-run-manifest-20261029.md` amendment 4).
- **Emitted active:** **0**. `55-auth-users-trigger.sql` keeps it in a separate file (as required) and reproduces
  the full `CREATE TRIGGER` verbatim as a comment tagged `(BLOCKED - DO NOT APPLY)` (lines 20–22). Correctly **not
  merged, not applied**: it targets the platform-managed `auth` schema and calls `private.handle_new_user`, which
  has a captured body but no captured return type (§11/§12).
- **Note:** `g1-b3b.remote_session_triggers` is **not** this trigger (it is the 1 trigger on
  `public.remote_sessions`) — matches manifest amendment 4; no conflation in the artefact.
- **State:** `PRESENT — PARTIAL` — definition SOURCE VERIFIED and reproduced verbatim, isolated as its own
  component, 0 emitted (dependency + platform-schema block).

## 22. Platform-level configuration not reconstructable through SQL

Scope: managed roles, storage, vault, Edge runtime, Supabase Auth settings, existence of
`anon`/`authenticated`/`service_role`, `supabase_realtime` publication ownership, WAL/logical-decoding settings.

- **Managed roles — existence EVIDENCED, recreation out of A0 scope:** `anon`, `authenticated`, `service_role`
  appear as ACL grantees in `g1-q6`/`g1-q1` and `service_role`/`authenticated` hold table privileges;
  `g1-q6.role_memberships` (24 rows, `role`/`member`/`admin_option`) names `authenticator`, `supabase_realtime_admin`,
  `postgres`, `dashboard_user`, `supabase_admin`, `supabase_auth_admin`. Role *attributes* beyond authenticator
  (Q1–Q10 never select `pg_roles`) and the `CREATE ROLE` statements are **not emittable**; the 24 memberships are
  recorded as **comment-only** evidence (`70` line 358, `00` lines 37–40). `g1-b3b` supplies authenticator role
  config (see §20).
- **`supabase_realtime` publication ownership:** never queried → `UNKNOWN` (§19).
- **WAL / logical decoding / `replica identity`:** no `pg_settings` or publication capture in the series →
  `MISSING — SOURCE EVIDENCE ABSENT`; Realtime delivery (which needs logical decoding) cannot be verified from
  schema SQL at all.
- **Sequences:** expected `UNKNOWN` — not enumerated by Q1–Q10/B3b; their **existence is only indirectly
  evidenced** by the 8 `object_type='S'` rows in `g1-q6.default_acl` (§18). 0 `CREATE SEQUENCE` emitted.
- **Views / materialised views / foreign tables:** expected `UNKNOWN` — Q1 is described (`91-coverage.md`) as
  filtering `relkind='r'`, but the predicate is not in the JSON (only 19 result rows), so the whole non-`r` class
  is invisible across the entire evidence series → **blind spot, not an empty set**.
- **Storage / vault / Edge Functions:** storage buckets "none" (`functions-and-triggers.md` §4, not a catalogue
  read); vault never queried; **Edge Functions are still unread (PA1)** — the `functions-and-triggers.md` §3
  source-form scan of 9 functions (2 readable, 7 minified) is explicitly a scan, "not a review."
- **State:** `MISSING — SOURCE EVIDENCE ABSENT` for reconstructable form (correctly excluded by A0). The artefact
  records them as config notes and asserts **0** SQL statements for this whole category, which is the right call —
  the honest label is "not SQL-reconstructable," not "verified absent."

---

## Totals by category

| # | Category | Expected (evidence + key) | Emitted active (file:lines) | Comment-only | State | vs `91-coverage.md` |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Extensions | **UNKNOWN** (no pg_extension query) | 0 | 3 inferred | MISSING — SOURCE EVIDENCE ABSENT | AGREEMENT (UNKNOWN, not 0) |
| 2 | Schemas (app) | 2 (g1-q1, g1-b3b schema_name) | 2 (`00` 33,35) | platform noted | PRESENT — SOURCE VERIFIED | AGREEMENT (2) |
| 3 | Tables | 19 (g1-q1.table_name) | 19 (`10` 23–271) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (19) |
| 4 | Columns & types | 183 (g1-q8 rows) | 183 (`10`) | 0 | PRESENT — PARTIAL (collation/domain absent) | AGREEMENT (183); refinement adds collation gap |
| 5 | Defaults & identity | 69 defaults (g1-q8.column_default); identity **UNKNOWN** | 69 DEFAULT (`10`) | 0 | PRESENT — PARTIAL (identity absent) | AGREEMENT (defaults); adds identity/sequence note |
| 6 | Primary keys | 19 (g1-q5 kind=p) | 19 (`20`) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (19) |
| 7 | Foreign keys | 44 (g1-q5 kind=f) | 44 (`20`) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (44) |
| 8 | Unique constraints | 9 (g1-q5 kind=u) | 9 (`20`) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (9) |
| 9 | Check constraints | 65 (g1-q5 kind=c) | 65 (`20`) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (65) |
| 10 | Indexes | 62 (g1-q4 rows) | 34 (`30` 19–80) | 28 suppressed | PRESENT — SOURCE VERIFIED (28 via constraints) | AGREEMENT (34/28); 28 reframed "not lost" |
| 11 | Functions & overloads | 38 (g1-b3b.inventory); overloads 0 | 0 (`40` all) | 38 inv., 14 bodies | MISSING — SOURCE EVIDENCE ABSENT | AGREEMENT (0 exec); overloads unaddressed by prior |
| 12 | Return types & arguments | args 38 (g1-b3b/q7/q10); RT: 14 narrative + 24 absent | 0 | 38 signatures | CONFLICT — SOURCE DISAGREEMENT | **DISAGREEMENT** — prior says 0/38 RT; functions-and-triggers.md §1 has 14 |
| 13 | Function security props | definer 38, search_path 38 (g1-b3b/q7) | 0 | 38 | PRESENT — PARTIAL (24 owners INFERRED) | AGREEMENT (flags recorded) |
| 14 | Triggers (public) | 7 (g1-q3) | 0 (`50`) | 7 | PRESENT — PARTIAL (blocked) | AGREEMENT (7/0) |
| 15 | RLS enable + forced | 19 enabled, 0 forced (g1-q1) | 19 ENABLE (`60` 19–37) | 0 | PRESENT — SOURCE VERIFIED | AGREEMENT (19/0 force) |
| 16 | RLS policies | 21 (g1-q2) | 0 (`60` 40–76) | 21 | PRESENT — PARTIAL (blocked) | AGREEMENT (21/0) |
| 17 | Grants & ACLs | q6 149 / q1 320 (Δ 171) | 235 (`70`) | 19 pg-owner | PRESENT — PARTIAL + CONFLICT flag | AGREEMENT (149/33/171/0/152/19) |
| 18 | Default privileges | 24 rows / 70 entries (g1-q6.default_acl) | 13 (`70` 321–338) | 57 | PRESENT — PARTIAL | AGREEMENT (13/57); adds seq evidence |
| 19 | Realtime publication | **UNKNOWN** (doc says 4) | 0 (`80`) | 4 | MISSING — SOURCE EVIDENCE ABSENT | AGREEMENT (4 INFERRED/0) |
| 20 | Auth-related config | partial (b3b/q3b/f&t §4; 2 toggles NOT captured) | 0 | noted in `00` | UNVERIFIED — SOURCE AMBIGUOUS | prior did not score this as a category |
| 21 | `auth.users` trigger | 1 (g1-q3b) | 0 (`55`) | 1 | PRESENT — PARTIAL (isolated, blocked) | AGREEMENT (1/0) |
| 22 | Platform non-SQL config | roles/anon/service_role evidenced; WAL/vault/Edge/views UNKNOWN | 0 | memberships 24 | MISSING — SOURCE EVIDENCE ABSENT | AGREEMENT (out of A0 scope) |

**Artefact-wide totals (independently re-measured):** 459 active statements (= component sum; assembled file =
459); 0 active function/trigger/policy/publication/extension; 69 active DEFAULTs; 183 active column definitions;
137 active constraints; 34 active indexes; 19 active RLS-ENABLE; 235 active GRANT; 13 active default-privileges.

## Top blockers to an A3 schema load

1. **Return types (all 38 from catalogue queries).** 0 executable functions ⇒ **cascading** failure of every
   trigger (§14, blocked), every policy (§16, blocked, calls `private.*`), and the `auth.users` trigger (§21).
   This is the dominant blocker. Note the §12 correction: return types for 14 public functions DO exist as
   narrative evidence — but they are not catalogue-verified, cannot be cross-checked against the 24 missing bodies,
   and don't unblock the private helpers, so the load is still blocked.
2. **24 of 38 function bodies absent** (`g1-b3b` read only 14) ⇒ A5 D-06 prosrc-hash validation cannot pass for the
   private schema; behavioural parity is unreachable from this evidence.
3. **Identity / generated columns never captured** (§5) ⇒ identity primary keys would rebuild as plain integers
   with no sequence ⇒ data-loss-level divergence on any load that moves rows.
4. **Collations never captured** (§4) ⇒ text comparison/sort semantics on the 43 `text` columns are undefined
   against a staging DB with a different default collation.
5. **Extensions UNKNOWN** (§1) ⇒ if `pgcrypto` (or any) is in fact required by `gen_random_uuid()` defaults, the
   load errors on the first such table unless the staging project pre-installs it.
6. **Sequences, views, publication membership, WAL/logical decoding, storage/vault/Edge** (§19/§22) ⇒ real,
   non-empty classes that the whole evidence series cannot see; a "successful" load would silently omit them.
7. **PG17 `MAINTAIN`** (§17) ⇒ only reconstructable from Q1 acltext, not Q6; a rebuild that trusts Q6 alone drops
   `service_role`'s MAINTAIN on all 19 tables.

## Verified / Inferred / Missing-evidence / Unverified / Recommendations

- **Verified (source, emittable):** schemas 2, tables 19, columns/types/nulls 183, defaults 69, PK 19, FK 44,
  UNIQUE 9, CHECK 65, indexes 34 (+28 by constraint), RLS-ENABLE 19 (forced correctly 0), grants 235 (incl. 19
  MAINTAIN from Q1), default-privileges 13, column grants 183. The `g1-q1` vs `g1-q6` ACL set difference
  (320/149/171/152/0) and the index-suppression (62/34/28) are both independently confirmed.
- **Inferred (recorded, not verified):** `private`-schema function ownership (24) from ACL grantor `/postgres`;
  `pgcrypto` for `gen_random_uuid()`; the 4-table Realtime membership (from `01-staging-project-proposal.md:61`
  + approval-v2 3.3(b)); Supabase-managed role existence from grantee names.
- **Missing evidence:** all 38 return types *as catalogue data*; 24 function bodies; identity/generated columns;
  collations; extensions list; sequences enumeration; views/materialised/foreign tables; publication state; WAL /
  logical-decoding; storage/vault/Edge-Function source; `SSL enforcement` + `Connection logging` toggles.
- **Unverified / ambiguous:** Supabase Auth runtime settings (JWT/refresh/pool, from a settings page, effects not
  exercised); the two unscored ACL sources' reconciliation is understood but the "expected count" of grants is
  genuinely source-dependent; whether non-`r` relations exist at all is UNKNOWN (relkind filter not visible in JSON).
- **Recommendations:**
  1. Re-open `91-coverage.md` row "Function return types 0/38" → correct to **14/38 present as narrative** and
     cite `functions-and-triggers.md` §1; keep "0 emittable" but attribute it to (bodies + private deps + catalogue-
     unverified), not to "no return type anywhere."
  2. Split `40-functions.sql`/`90-limitations.md` return-type cell into public-14 (narrative) vs private-24
     (absent) so the blocker is stated precisely.
  3. Record the 3 cross-check facts the evidence supports so a future capture can close them fast: identity/
     `attidentity` + `attgenerated` + `collation_name` are the highest-value new columns to select; and a
     `pg_roles`/`pg_extension`/`pg_publication` read would flip rows 1/19/22 from UNKNOWN to a real number.
  4. Treat the artefact as a **reviewable reconstruction, not a load-ready schema** (as `91-coverage.md` already
     concludes) — the structural core loads; the behavioural layer does not.

*End of S2-EXEC-04 object coverage matrix. No artefact other than this file was created or modified.*
