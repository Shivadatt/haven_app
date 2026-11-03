# S2-EXEC-05 — Function-body coverage register (every function, individually)

| Field | Value |
| --- | --- |
| Domain | The function-body coverage register for the G3 offline reconstruction: all 38 inventoried functions, one row each; dependents map; the 24 absent bodies individually accounted; A5/D-06 pre-image interaction; domain verdict |
| Mode | Offline, repository-only. No browser, no dashboard, no CLI, no API, no SQL execution, no DB connection. Production `parent-control-prod` was NOT opened or inspected; every fact below is read from in-repo files |
| Date | 2026-11-02 (parallel eight-auditor pass, after S2-EXEC-03) |
| Primary inputs | `docs/stage1/evidence/g1-b3b-20261029.json`, `g1-q2/g1-q3/g1-q3b/g1-q6/g1-q7/g1-q10`, `g1-run-manifest-20261029.md`, `functions-and-triggers.md`, `edge-functions/capture-20261030.json`; artefact `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\40/50/55/60/80*.sql`, `90-limitations.md`, `92-provenance-manifest.md`, `93-counts.json`; `docs/stage2/04-risks-rollback-approvals.md` §3 (A5), `00-stage2-execution-plan.md`, `patches/S2-P01..P03`, `patch-defects-before-a5.md` (D-06) |
| Boundaries honoured | No `S2-EXEC-04-*` file read, created or touched. Nothing modified except this file. No git write. Bodies are NOT reproduced here — only char counts, SHA-256 digests and evidence paths. No body was invented, no return type guessed, no placeholder function created, nothing marked reconstructed |

Classification scope: the closed vocabulary below classifies **body coverage of the function** (this register's domain). Metadata disagreements (return type, signature presentation) are recorded in the "outstanding issue" column and in §1.3 as dimension-level findings, labelled there `CONFLICT — SOURCE DISAGREEMENT`.

Vocabulary: `PRESENT — SOURCE VERIFIED` · `PRESENT — PARTIAL` · `MISSING — SOURCE EVIDENCE ABSENT` · `UNVERIFIED — SOURCE AMBIGUOUS` · `NOT APPLICABLE — EVIDENCE SUPPORTED` · `CONFLICT — SOURCE DISAGREEMENT`.

---

## 1. Re-derived population (measured, not recalled)

Parsed directly from `g1-b3b-20261029.json` (Python, offline; every figure recomputed from the file, none quoted from memory).

| Measure | Claimed (S2-EXEC-03 record) | Measured by this audit | JSON source field | Verdict |
| --- | --- | --- | --- | --- |
| Functions inventoried | 38 | **38** rows | `inventory.count` = 38; `len(inventory.rows)` = 38 (measured) | **AGREEMENT** |
| public functions | — | **14** | `inventory.public_count` = 14; row scan `schema_name=='public'` = 14 (measured) | consistent |
| private functions | — | **24** | `inventory.private_count` = 24; row scan = 24 (measured) | consistent |
| Bodies present in evidence | 14 | **14** | `len(bodies)` = 14 (measured); every body key `(schema,name,args)` ⊆ inventory keys (verified) | **AGREEMENT** |
| Bodies absent | 24 | **24** = 38 − 14 | measured set difference `inventory_keys − body_keys`; also `inventory.rows` private/public split 12 + 12 | **AGREEMENT** |
| Return types captured | 0 of 38 | **0** in any raw export | `bodies[]` entries carry only `{schema_name, function_name, arguments, body}`; `inventory.rows[]` carry only `{schema_name, function_name, arguments, security_definer, anon_exec, auth_exec, service_exec, acl, settings}`; `g1-q7` rows carry no return field; `g1-q10` rows carry no return field; `g1-run-manifest` Q7/Q10/Q6 descriptions select none | **AGREEMENT on raw exports** — but see §1.3, dimension-level CONFLICT |
| Corroboration | — | Data API "functions_exposed: 0 of 38" | `g1-b3b.data_api_exposure.functions_exposed` | consistent with 38 |

**No count disagreement.** The claimed 38 / 14 / 24 / 0 are all reproducible from `g1-b3b` alone.

### 1.1 Overload analysis (measured)

- **Intra-schema overloads: zero.** 38 unique `(schema_name, function_name, arguments)` tuples = 38 rows; no `(schema, name)` key in `g1-b3b.inventory.rows` carries two different `arguments` strings. So within `public` and within `private`, each name has exactly one signature in the capture.
- **Cross-schema same-signature twins: 13 name pairs** (`arguments` byte-identical in both rows): `apply_policy_version`, `create_family_with_owner`, `create_pairing_invite`, `create_pairing_request`, `detect_offline_devices`, `expire_stale_commands`, `expire_stale_sessions`, `poll_device_commands`, `replace_device_apps`, `request_device_recovery`, `respond_pairing_request`, `revoke_device`, `unlink_child`. These are **not Postgres overloads** (different namespaces); they are the wrapper/implementation duality `g1-run-manifest` calls "near-identical twins" (§B3b, line 42). The 14th public name `request_remote_session` has no private twin; 11 private names have no public twin (helpers and trigger functions).
- **Distinct names: 25** across 38 rows. Consequence, measured: `g1-q7` (18 rows) and `g1-q10` (14 rows) select **no `schema_name` per row** (`g1-run-manifest` Files table: Q7 = "public+auth functions"; the 14 q10 names measured == the 14 public names). Because twin names are identical, a q7/q10 row cannot be bound to a schema from the file alone; the artefact's refusal to attribute (40-functions.sql appendix, `g3-build:844-865`) is upheld. `g1-q10` rows carry owner `postgres` + `extension_owned:false`, but the same non-attributability applies.
- Attribution exception worth recording: q10's `request_device_recovery` row shows `acl: postgres=X/postgres,service_role=X/postgres`, which matches the **public** twin; the private twin's acl is `(null = default PUBLIC EXECUTE)` (`g1-b3b` inventory row). This does not make q7/q10 generally attributable; it is consistency evidence only.

### 1.2 Security-definer / search_path totals (measured, `g1-b3b.inventory.rows[].security_definer` / `[].settings`)

- `security_definer = true`: **34** rows; `false`: **4** rows, all private trigger functions: `audit_logs_append_only`, `families_before_update`, `profiles_before_update`, `set_updated_at` (matches the `functions-and-triggers.md` amendment, line 14-16).
- `search_path` pinned in `settings` on **38/38**. Two omit `private`: `private.remote_session_transition_guard` and `public.request_remote_session` (`settings = ["search_path=public, pg_temp"]`) — the F5/F8 defect the patches target.
- Two rows carry `acl = "(null = default PUBLIC EXECUTE)"`: `private.request_device_recovery`, `private.remote_session_transition_guard` — the E2/F8 exposure S2-P01 targets (both bodies are in fact captured; see §5).

### 1.3 Dimension-level source disagreements (headline findings, marked `CONFLICT — SOURCE DISAGREEMENT`)

1. **Return type.** Raw exports (`g1-b3b`, `g1-q7`, `g1-q10`) capture **no return type for any of the 38** — verified by field inspection above. However `docs/stage1/evidence/functions-and-triggers.md` §1 (lines 34-49) carries a "Returns" column for 14 functions (`jsonb` ×9 per its table, `integer` ×3, `remote_sessions (row type)` ×1, plus one more `jsonb`). That file self-labels as a **dashboard-derived narrative transcription, not a raw export** (header lines 3-8; manifest amendment note 2), was captured **before** G1, and was partially superseded by its own B3b amendment without the Returns table being retracted. The two sources genuinely disagree about whether return-type evidence exists. Treatment in this register: return types remain `NOT PRESENT IN EVIDENCE`; the narrative claims are logged `UNVERIFIED — SOURCE AMBIGUOUS` and are **not** upgraded into register data, **not** used anywhere, and must not be used by patches as authority (see §5 note on S2-P02's asserted `RETURNS jsonb`).
2. **Signature presentation of `poll_device_commands`.** `g1-b3b` (and q7, q10): `p_device_id uuid, p_limit integer`. Narrative `functions-and-triggers.md` §1: "`p_limit integer default 20`". A raw `pg_get_function_arguments` capture would render DEFAULT inline, so either the export or the transcription is lossy; the edge capture (`edge-functions/capture-20261030.json`, `poll` anchor: `rpc poll_device_commands {p_device_id:o.id, p_limit:20}`) shows the caller supplying 20 but cannot decide whether the server had a DEFAULT. Unresolved: `CONFLICT — SOURCE DISAGREEMENT` (presentation dimension only; the argument count/types are consistent).
3. **Counts 14 vs 38** (historical): already reconciled in-file by the B3b amendment; not an open conflict.

---

## 2. Body-digest record for the 14 present bodies

Digest computed offline (Python `hashlib.sha256`) over the JSON-decoded `body` string exactly as stored in `g1-b3b-20261029.json`. Full body text is deliberately **not** pasted here. Masking check: all 14 bodies were inspected for credential/PII-shaped literals — none present; `private.handle_new_user` references the column `new.email` (a catalog column reference, no value), noted only. Line endings vary in the capture (some bodies carry CRLF): the digest is over the decoded string, byte-identical re-derivation requires the same JSON parse; recorded here as the offline pre-image store for §5.

| schema.function (arguments) | `g1-b3b.bodies[]` | PRESENT (chars) | SHA-256 of prosrc string |
| --- | --- | --- | --- |
| private.is_family_member (p_family_id uuid) | bodies[0] | PRESENT (249 chars) | `30c867ff754af8aff2d3bce89f5c3cc4f3668f0eaadafd27d0559a55be591348` |
| private.is_family_parent (p_family_id uuid) | bodies[1] | PRESENT (277 chars) | `6f9719ef0579bdca62b9ecfeceeecf86be2a35f333cbc07490fdb761edce479d` |
| private.shares_active_family (p_user_id uuid) | bodies[2] | PRESENT (372 chars) | `9a446aeece9ae6c41b571ba0eaf99b0cd534c8eb88e1dea559080d91f5309c89` |
| private.handle_new_user () | bodies[3] | PRESENT (463 chars) | `7cf70be9a66fafb78666b93c8241589221c8bf83af882f4a2836fa8395c21bb7` |
| private.remote_session_transition_guard () | bodies[4] | PRESENT (226 chars) | `f524a247d182f2b990b7c8a5b5e8a55ef7e22d663dffd6f5e256cd2f0c27712e` |
| private.profiles_before_update () | bodies[5] | PRESENT (578 chars) | `66a4488beefb12dc05668a426a685d257cb2b6d9cb3d230f15735b18bdf04d78` |
| private.families_before_update () | bodies[6] | PRESENT (377 chars) | `cabb3f6c7b9bbced6e9eb982d4b499f0bec513f2d8dc571fed641ce691a05968` |
| private.audit_logs_append_only () | bodies[7] | PRESENT (420 chars) | `a359bcd80c3fc66940f6bbb934135b6c48d2a55bf300d4c6a5c09e6e3cd671a7` |
| private.set_updated_at () | bodies[8] | PRESENT (58 chars) | `c64cd9cc61d0e6df4bb6cc12e674734d27627d430474ab6d08436092743303c5` |
| private.realtime_topic_allowed (p_topic text) | bodies[9] | PRESENT (752 chars) | `aaf0e5791b1479eb279d2f2a3a6f0b68a76fbf560826bf3f88950f158d9bf3ed` |
| private.request_device_recovery (p_device_id uuid, p_actor_user_id uuid) | bodies[10] | PRESENT (1146 chars) | `f95442fb5bffd6f2fa1587f39feef49f31d47b5f6e6c19794933d418abd4caac` |
| public.request_device_recovery (p_device_id uuid, p_actor_user_id uuid) | bodies[11] | PRESENT (73 chars) | `92ae5bd4a52778a2e37d3090565d28e371c0abd1c999e75f45a72efd8402bf3e` |
| public.request_remote_session (p_device_id uuid, p_parent_user_id uuid, p_kind text) | bodies[12] | PRESENT (1401 chars) | `34cba351ce9bf56931682393074fbd47fdedbb2a57c202fb262ecc98edfeef8c` |
| private.unlink_child (p_family_id uuid, p_child_user_id uuid, p_actor_user_id uuid) | bodies[13] | PRESENT (2514 chars) | `fcafab3585d3d2870ff168a2c66fcb3c21751a9755373bc964a296c7d788082c` |

Split: 12 private + 2 public present; consequently 12 private + 12 public absent. All digests are independently re-computable from the same file by any reader (offline verifiability).

---

## 3. The register — 38 rows, every function, no sampling

Legend used in cells: **args** = `g1-b3b.inventory.rows[].arguments` (VERIFIED FROM SOURCE). **ret** = `NOT PRESENT IN EVIDENCE` in every raw export (`g1-b3b`, `g1-q7`, `g1-q10`); `[narr]=` marks an untraceable return-type claim existing only in `functions-and-triggers.md` §1, recorded UNVERIFIED — SOURCE AMBIGUOUS, **not used**. **body** = `g1-b3b.bodies[]` (raw `prosrc`). **artefact** = `g3-build\40-functions.sql` block (marker line; whole file has 0 executable statements — measured: no `CREATE FUNCTION` outside comment lines; `93-counts.json.emitted_code_lines_by_component["40-functions.sql"]=0`); prosrc preserved as comment at the quoted sub-range when present. **def** = `security_definer`; **spath** = `settings`; **ovld** = overload accounting (§1.1); **prov** = source provenance; **verif** = independent verifiability (repo-only re-measure); **class** = body-coverage classification.

| schema | name | argument signature (evidenced?) | return type (evidenced?) | original body in Stage 1 evidence? | reconstructed body in artefact? (`file:line`) | security-definer/invoker (evidenced?) | search_path (evidenced?) | overload accounted for? | source provenance | independent verifiability | final classification | outstanding issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| private | apply_policy_version | YES args (VERIFIED) | NO — NOT PRESENT IN EVIDENCE | NO | comment-only metadata block `40-functions.sql:24-34`; NOT EMITTED | YES def=true (VERIFIED) | YES spath=`public, private, pg_temp` | single sig in schema; public twin same sig (pair 1) | g1-b3b inventory | row + absence re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | body + ret uncaptured; 0 dependents; RPC route to Edge tier only |
| private | audit_logs_append_only | YES args (VERIFIED) | NO — NOT PRESENT IN EVIDENCE | YES (420 chars, §2) | body preserved verbatim as comment `:36-62` (prosrc `:47-61`); NOT EMITTED | YES def=false → SECURITY INVOKER (VERIFIED) | YES `public, private, pg_temp` | single | g1-b3b inventory+bodies; g1-q3 row 1 | body hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured → trigger 50 cannot bind |
| private | create_family_with_owner | YES | NO | NO | comment-only `:63-73` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | create_pairing_invite | YES | NO | NO | comment-only `:75-85` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1; caller-side use in edge capture (`invite` anchor) is not a definition |
| private | create_pairing_request | YES | NO | NO | comment-only `:87-97` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | detect_offline_devices | YES args="" (VERIFIED) | NO | NO | comment-only `:99-109` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | expire_stale_commands | YES | NO | NO | comment-only `:111-121` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | expire_stale_sessions | YES args="" | NO | NO | comment-only `:123-133` | def=true | YES | twin pair | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | families_before_update | YES args="" | NO | YES (377 chars) | body comment `:135-158` (prosrc `:146-157`); NOT EMITTED | def=false (INVOKER) | YES | single | g1-b3b; g1-q3 row 3 | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured |
| private | handle_new_user | YES args="" | NO | YES (463 chars) | body comment `:159-191` (prosrc `:170-190`); NOT EMITTED | def=true | YES | single | g1-b3b; g1-q3b (auth.users trigger) | hash recomputable | **PRESENT — SOURCE VERIFIED** | sole dependent = 55-auth-users-trigger; ret uncaptured; touches platform `auth` schema |
| private | is_family_member | YES | NO | YES (249 chars) | body comment `:192-214` (prosrc `:203-213`); NOT EMITTED | def=true | YES | single | g1-b3b; referenced in 3 g1-q2 policies | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured **and** narrative `[narr]` claims boolean — CONFLICT-SOURCE DISAGREEMENT on ret dimension only |
| private | is_family_parent | YES | NO | YES (277 chars) | body comment `:215-238` (prosrc `:226-237`); NOT EMITTED | def=true | YES | single | g1-b3b; 13 g1-q2 policies | hash recomputable | **PRESENT — SOURCE VERIFIED** | same ret-dimension conflict |
| private | poll_device_commands | YES; sig rendering conflicted (§1.3.2: export "p_limit integer" vs narrative "default 20") | NO | NO | comment-only `:239-249` | def=true | YES | twin pair | g1-b3b; g1-q7/q10 rows (unattributable) | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | DEFAULT-presence unresolved; never emit both variants |
| private | profiles_before_update | YES args="" | NO | YES (578 chars; CRLF captured) | body comment `:251-280` (prosrc `:262-279`); NOT EMITTED | def=false (INVOKER) | YES | single | g1-b3b; g1-q3 row 5 | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured |
| private | realtime_topic_allowed | YES | NO | YES (752 chars) | body comment `:281-324` (prosrc `:292-323`); NOT EMITTED | def=true | YES | single | g1-b3b | hash recomputable | **PRESENT — SOURCE VERIFIED** | called by Realtime layer (80 section has no publication evidence); ret uncaptured |
| private | record_audit | YES (7 args) | NO | NO | comment-only `:325-335` | def=true | YES | single | g1-b3b inventory | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | **transitive dependent blocker**: invoked inside 2 captured bodies (private.request_device_recovery, private.unlink_child) — call sites are evidence, body is not; P02 rollback equivalence incomplete without it |
| private | remote_session_transition_guard | YES args="" | NO | YES (226 chars) | body comment `:337-357` (prosrc `:348-356`); NOT EMITTED | def=true | YES but `public, pg_temp` only — F5/F8 flag | single | g1-b3b; g1-q3 row 6; b3b `remote_session_triggers[0]` | hash recomputable | **PRESENT — SOURCE VERIFIED** | acl = null → default PUBLIC EXECUTE (E2/F8, S2-P01 target); ret uncaptured |
| private | replace_device_apps | YES | NO | NO | comment-only `:358-368` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | request_device_recovery | YES | NO | YES (1146 chars) | body comment `:370-430` (prosrc `:381-429`); NOT EMITTED | def=true | YES | twin pair | g1-b3b; g1-q3 n/a; S2-P01/P02 targets | hash recomputable | **PRESENT — SOURCE VERIFIED** | acl = null → PUBLIC EXECUTE (E2/F8); ret uncaptured; calls absent private.record_audit (transitive gap) |
| private | respond_pairing_request | YES | NO | NO | comment-only `:431-441` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | revoke_device | YES | NO | NO | comment-only `:443-453` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | as row 1 |
| private | set_updated_at | YES args="" | NO | YES (58 chars) | body comment `:455-472` (prosrc `:466-471`); NOT EMITTED | def=false (INVOKER) | YES | single | g1-b3b; 3 g1-q3 triggers | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured; 3 triggers blocked on it |
| private | shares_active_family | YES | NO | YES (372 chars) | body comment `:473-497` (prosrc `:484-496`); NOT EMITTED | def=true | YES | single | g1-b3b; 1 g1-q2 policy | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured |
| private | unlink_child | YES | NO | YES (2514 chars) | body comment `:498-603` (prosrc `:510-602`); NOT EMITTED | def=true | YES | twin pair | g1-b3b; S2-P02 target | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured; calls absent private.record_audit (transitive gap) |
| public | apply_policy_version | YES | NO; `[narr]` claims jsonb (untraceable) | NO | comment-only `:604-614` | def=true | YES | twin pair | g1-b3b; q7/q10 rows unattributable | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict §1.3.1; owner postgres evidenced only via unattributable q10 row |
| public | create_family_with_owner | YES | NO; `[narr]` jsonb | NO | comment-only `:616-626` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict; edge capture shows caller `p_owner = auth.user.id` (caller-side only) |
| public | create_pairing_invite | YES | NO; `[narr]` jsonb | NO | comment-only `:628-638` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | create_pairing_request | YES | NO; `[narr]` jsonb | NO | comment-only `:640-650` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | detect_offline_devices | YES args="" | NO; `[narr]` integer | NO | comment-only `:652-662` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | expire_stale_commands | YES | NO; `[narr]` integer | NO | comment-only `:664-674` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | expire_stale_sessions | YES args="" | NO; `[narr]` integer | NO | comment-only `:676-686` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | poll_device_commands | YES; rendering conflict (default 20) §1.3.2 | NO; `[narr]` jsonb | NO | comment-only `:688-698` | def=true | YES | twin pair | g1-b3b; edge capture caller `{p_limit:20}` | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict + DEFAULT-presence conflict |
| public | replace_device_apps | YES | NO; `[narr]` integer | NO | comment-only `:700-710` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | request_device_recovery | YES | NO; `[narr]` jsonb | YES (73 chars — captured wrapper `select private.request_device_recovery(...)`) | body comment `:712-726` (prosrc `:723-725`); NOT EMITTED | def=true | YES | twin pair | g1-b3b bodies[11]; b3b `dynamic_sql` review | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured; only *evidenced* wrapper in the whole population — twins' wrapper status is otherwise ASSUMED-NOWHERE (not assumed here) |
| public | request_remote_session | YES | NO; `[narr]` "remote_sessions (row type)" untraceable | YES (1401 chars) | body comment `:727-805` (prosrc `:738-804`); NOT EMITTED | def=true | YES but `public, pg_temp` only — F5 flag | no twin | g1-b3b; q7 row (unattributable) | hash recomputable | **PRESENT — SOURCE VERIFIED** | ret uncaptured despite `[narr]` claim — CONFLICT-SOURCE DISAGREEMENT (ret dim); S2-P02/P03 depend on its pre-image |
| public | respond_pairing_request | YES | NO; `[narr]` jsonb | NO | comment-only `:806-816` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | revoke_device | YES | NO; `[narr]` jsonb | NO | comment-only `:818-828` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict |
| public | unlink_child | YES | NO; `[narr]` jsonb | NO | comment-only `:830-840` | def=true | YES | twin pair | g1-b3b | re-measurable | **MISSING — SOURCE EVIDENCE ABSENT** | ret conflict; P02 forbids touching it ("never touch … public.unlink_child") |

Register totals (measured): 38 rows · PRESENT — SOURCE VERIFIED = **14** · MISSING — SOURCE EVIDENCE ABSENT = **24** · PRESENT — PARTIAL = 0 · UNVERIFIED — SOURCE AMBIGUOUS = 0 as row class (applies to the return-type/narrative dimension on 14 public rows and both `poll_device_commands` rows) · NOT APPLICABLE = 0 · CONFLICT = 0 as row class (2 dimension-level findings in §1.3). Executable DDL in `40-functions.sql` = **0** (agrees with artefact claim).

---

## 4. Dependents map (8 triggers + 21 policies; measured references from captured definition text)

### 4.1 Triggers — `g1-q3` (7 rows) + `g1-q3b` (1 row)

| Dependent object | Referenced function (from captured `definition` text) | Status |
| --- | --- | --- |
| trigger audit_logs_append_only ON public.audit_logs | `private.audit_logs_append_only()` (body PRESENT) | BLOCKED ON ABSENT FUNCTION DDL (blockage = missing DDL emission, not missing body) — `50-triggers.sql:18` |
| trigger devices_set_updated_at ON public.devices | `private.set_updated_at()` (body PRESENT) | BLOCKED — `50-triggers.sql:21` |
| trigger families_before_update ON public.families | `private.families_before_update()` (body PRESENT) | BLOCKED — `:24` |
| trigger families_set_updated_at ON public.families | `private.set_updated_at()` | BLOCKED — `:27` |
| trigger profiles_before_update ON public.profiles | `private.profiles_before_update()` (body PRESENT) | BLOCKED — `:30` |
| trigger remote_sessions_transition_guard ON public.remote_sessions | `private.remote_session_transition_guard()` (body PRESENT) | BLOCKED — `:33`; corroborated by `g1-b3b.remote_session_triggers[0]` |
| trigger safe_zone_states_set_updated_at ON public.safe_zone_states | `private.set_updated_at()` | BLOCKED — `:36` |
| trigger on_auth_user_created ON auth.users | `private.handle_new_user()` (body PRESENT) | BLOCKED — `55-auth-users-trigger.sql:20-22`; also platform-schema dependency (auth.users DDL is out of scope per `00-platform-assumptions.sql`) |

### 4.2 Policies — `g1-q2` (21 rows), functions parsed from `qual`/`with_check` text (regex-measured, counts in §4.3)

- Reference `private.is_family_parent` (**13**): audit_logs_select_family_parent, device_apps_/device_commands_/device_policies_/devices_select_parent_or_child, location_events_/pairing_requests_/remote_sessions_/safety_alerts_/usage_daily_select_parent_or_child, safe_zones_delete_parent, safe_zones_insert_parent (with_check), safe_zones_update_parent (qual+with_check) — all BLOCKED (`60-rls-policies.sql:40,41,44,46,50,54,57,60,61,62,64,65,68`).
- Reference `private.is_family_member` (**3**): families_select_members, family_members_select_family, safe_zones_select_family — BLOCKED (`:51,53,63`).
- Reference `private.shares_active_family` (**1**): profiles_select_self_or_family — BLOCKED (`:58`).
- **17 policies** therefore reference `private.*` functions; matches the artefact's stated "17 of the 21" (`60-rls-policies.sql:16`).
- All three referenced policy functions (`is_family_parent`, `is_family_member`, `shares_active_family`) have **bodies PRESENT** — these policies are blocked solely by the return-type gap, not by absent bodies.

### 4.3 Measured blocked counts and orphan cases

- Captured dependent objects: 7 + 1 + 21 = **29**; all 29 carry `BLOCKED ON SECTION 40` in the artefact — **29/29 blocked**, 0 emitted.
- Strictly blocked on absent `private.*` **function DDL**: **25** (8 triggers + 17 policies). Distinct functions the 25 depend on: **9** (`audit_logs_append_only`, `set_updated_at`, `families_before_update`, `profiles_before_update`, `remote_session_transition_guard`, `handle_new_user`, `is_family_member`, `is_family_parent`, `shares_active_family`) — **all 9 are PRESENT — SOURCE VERIFIED bodies**. None of the 24 absent bodies has a captured trigger or policy dependent.
- **Orphans: 4** policies whose predicate references something other than an inventoried function: `families_update_owner`, `profiles_update_self`, `webrtc_signals_insert_participant`, `webrtc_signals_select_participant` — they reference only `auth.uid()` (`auth` schema helper, excluded from the 38 per `g1-b3b.inventory.note` as Supabase-internal) plus table columns. They are marked BLOCKED ON SECTION 40 in the artefact, which is **over-blocking for this domain**: nothing they need is a missing private function; their true blockers are the platform `auth` schema assumption (`00-platform-assumptions.sql`) and the artefact's blanket rule. Flag: on any future load order these 4 can be emitted as soon as `auth.uid()` exists, independent of §40.
- `80-realtime-publication.sql` depends on `private.realtime_topic_allowed` only documentarily (Realtime authorization); publication state itself is NOT PRESENT IN EVIDENCE (`:14-15`) — outside this domain, noted for completeness.

---

## 5. The 24 absent bodies, individually accounted

Grouping criterion is **the name pattern of the `g1-b3b` inventory row only** — presence/absence of a public twin of the same name+signature. The grouping is **INFERRED (name-pattern)**; it asserts nothing about semantics. For every row: *Could authorised in-repo evidence supply the definition?* searched candidates: `D:\control\supabase\` (contains only `config.toml` + `.gitignore`; edge capture's own `repository` key states `functions_directory: "absent"`, `import_map_or_deno_json: "absent"`); repo-wide `find` for `*.sql` (only the 3 patch files + artefact); repo-wide grep for `CREATE (OR REPLACE )?FUNCTION` in `docs/**` (all hits are prose references, patch post-images, or checklist expectations — no captured original body anywhere outside `g1-b3b.bodies`); `docs/stage1/reports/stage1-final.md` (0 function definitions); `edge-functions/capture-20261030.json` (TypeScript **caller-side** `rpc(name, args)` references for: apply_policy_version, poll_device_commands, create_pairing_request, create_pairing_invite, respond_pairing_request, unlink_child, create_family_with_owner, replace_device_apps, revoke_device — caller argument shapes corroborate signatures but cannot supply a SQL/plpgsql definition; `pairing/` directory is **empty** (measured)); `firebase/SETUP-CHECKLIST.md` (no SQL).

| # | schema.name (signature per `g1-b3b`) | Name-pattern group (INFERRED criterion) | Any authorised in-repo source able to supply the definition? | Classification |
| --- | --- | --- | --- | --- |
| 1 | private.apply_policy_version (p_device_id uuid, p_policy jsonb, p_actor uuid, p_idempotency_key text) | A — private twin, body absent (11) | NO — edge capture shows caller only | MISSING — SOURCE EVIDENCE ABSENT |
| 2 | private.create_family_with_owner (p_owner uuid, p_name text) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 3 | private.create_pairing_invite (5 args per inventory) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 4 | private.create_pairing_request (5 args) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 5 | private.detect_offline_devices () | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 6 | private.expire_stale_commands (p_device_id uuid) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 7 | private.expire_stale_sessions () | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 8 | private.poll_device_commands (p_device_id uuid, p_limit integer) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT (sig rendering §1.3.2) |
| 9 | private.replace_device_apps (3 args) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 10 | private.respond_pairing_request (3 args) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 11 | private.revoke_device (2 args) | A (11) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 12 | private.record_audit (7 args) | B — private singleton helper (1) | NO. Its *call sites* appear inside two captured bodies (`perform private.record_audit(...)` in request_device_recovery/unlink_child prosrc) — call-site text is evidence of use and signature arity, **not** of definition; and use-by-name inside a body must not be read as semantics | MISSING — SOURCE EVIDENCE ABSENT |
| 13 | public.apply_policy_version (4 args) | C — public wrapper, body absent (12) | NO | MISSING — SOURCE EVIDENCE ABSENT. The one *evidenced* wrapper (`public.request_device_recovery`) shows a delegation pattern, but pattern-transfer to other wrappers would be body invention — forbidden, not done |
| 14 | public.create_family_with_owner (2 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 15 | public.create_pairing_invite (5 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 16 | public.create_pairing_request (5 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 17 | public.detect_offline_devices () | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 18 | public.expire_stale_commands (1 arg) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 19 | public.expire_stale_sessions () | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 20 | public.poll_device_commands (2 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 21 | public.replace_device_apps (3 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 22 | public.respond_pairing_request (3 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 23 | public.revoke_device (2 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |
| 24 | public.unlink_child (3 args) | C (12) | NO | MISSING — SOURCE EVIDENCE ABSENT |

Group totals measured against the §2 presence set: A=11, B=1, C=12 → 24. Patch files: S2-P02 contains **post**-image text for `private.request_device_recovery`, `private.unlink_child`, `public.request_remote_session` — all three already have captured pre-images (§2), so patches add **zero** coverage for any of the 24; the `RETURNS jsonb` / `RETURNS public.remote_sessions` asserted in S2-P02 (`patches/S2-P02:43,68,110`) aligns with the `functions-and-triggers.md` narrative but neither is raw-export traceable — that assertion is **not** adopted here (§1.3.1 stands: CONFLICT — SOURCE DISAGREEMENT, return type NOT PRESENT IN EVIDENCE). Nothing found deserves `UNVERIFIED — SOURCE AMBIGUOUS` **as a body candidate** (no in-repo file claims a body for any of the 24); the AMBIGUOUS label attaches only to the narrative return-type/signature-rendering dimensions. **Recovery count: 0 of 24 from authorised in-repo evidence.**

---

## 6. A5 interaction — pre-image `prosrc` hash (D-06) for patch-affected functions

Requirement chain: `04-risks-rollback-approvals.md` §3 row **A5** (approved 2026-11-02, NOT EXECUTABLE; evidence fields "Patch hash, §0 output, post-check output…"; forbidden: "production; touching unread bodies") + `approval-package-v2` §A5 "post-check output with mandatory assertions (`prosrc` hash, overload count — D-06)" + `patch-defects-before-a5.md` **D-06 = OPEN** (`S2-P02:147-154` post-checks are advisory selects; no `md5(prosrc)`, no overload count, nothing raises) + `00-stage2-execution-plan.md:199` (re-capture the three `prosrc` values from the staging catalogue immediately before apply) + `S2-EXEC-02:147-149` (D-06 "cannot be satisfied for any uncaptured function").

Patch-affected existing functions (measured from the patch files' referenced objects):

| Function | Patch | Body in evidence? | Pre-image hash producible from existing evidence? |
| --- | --- | --- | --- |
| private.request_device_recovery | P01 §1.1-1.2 (ACL), P02 §1 (replace) | YES (1146 chars) | YES from `g1-b3b` (§2 digest) — but **not verifiable against staging**: staging cannot hold the function because A3 load is impossible (§7), and byte-equality of stored capture vs live `prosrc` is unproven (capture shows mixed CRLF/LF; plan itself demands re-capture because the 2026-10-30 snapshot "may predate later edits") |
| private.remote_session_transition_guard | P01 §1.3-1.4 (ACL, search_path) | YES (226 chars) | YES from `g1-b3b` (§2) — same staging-verifiability caveat |
| private.unlink_child | P02 §2 (replace) | YES (2514 chars) | YES from `g1-b3b` (§2) — same caveat |
| public.request_remote_session | P02 §3 (replace) | YES (1401 chars) | YES from `g1-b3b` (§2) — same caveat |
| private.remote_session_insert_guard | P03 §1 (CREATE) | **Not in the 38; no production pre-image exists by design** | **NOT APPLICABLE — EVIDENCE SUPPORTED** (new object; only post-image hash exists; P03 additionally mirrors the post-P02 `request_remote_session` text, J-21 ordering constraint) |

Functions for which the pre-image `prosrc` hash **cannot be produced from existing evidence** — the full list, all 24 of §5: the 11 group-A private twins (apply_policy_version, create_family_with_owner, create_pairing_invite, create_pairing_request, detect_offline_devices, expire_stale_commands, expire_stale_sessions, poll_device_commands, replace_device_apps, respond_pairing_request, revoke_device), group-B (record_audit), and the 12 public wrappers (apply_policy_version, create_family_with_owner, create_pairing_invite, create_pairing_request, detect_offline_devices, expire_stale_commands, expire_stale_sessions, poll_device_commands, replace_device_apps, respond_pairing_request, revoke_device, unlink_child). None is directly replaced by P01-P03, so no A5 statement is *immediately* blocked by that; but (a) any A5 window that later touches any of them has no stored original and no rollback text (risk R-13, `04-risks:71`), and (b) `private.record_audit` is a **transitive co-dependent** of the P02 replacement bodies — P02 post-checks cannot prove equivalence on a collaborator whose pre-image cannot be hashed. Overload assertion (second half of D-06): §1.1 gives the offline baseline — zero intra-schema overloads for all patch-affected names; live overload count still must be asserted at apply time.

---

## 7. Domain verdict

**No — the function/trigger/policy layer cannot be completed under the current offline evidence boundary.** The inventory, signatures, definer flags, search_paths, ACLs and 14 of 38 bodies are verified from source, and this register now also fixes SHA-256 pre-images for all 14; but **not one of the 38 functions has a captured return type**, and `CREATE FUNCTION` without a declared return type is either invalid or a guess, which the reconstruction rules forbid. With zero functions emittable, all 29 captured dependents stay blocked (25 on function DDL; the 4 `auth.uid()`-only policies are orphans of this domain and over-blocked). Repairing the 14 present bodies alone would unblock 9 functions → 25 dependents, but only if return types existed; repairing the 24 absent bodies is additionally required for the RPC layer and for complete D-06 pre-images — neither repair is possible from any in-repo file (searched: supabase/, migrations, patches, edge captures, Stage 1 reports; §5). **The single piece of evidence that would change this:** one read-only catalogue capture selecting, per function, `format_type(prorettype)` **and `prosrc`** (and `proowner`, `prolang`) for all 38 — e.g. a `pg_get_functiondef`-class result wrapped in the same `begin transaction read only` pattern as G1. That evidence would require **A1 (read-only introspection) — and A1 is `PROHIBITED / INOPERATIVE` (2026-11-02, C-2)** for production under the owner's staging-only absolute; this audit does **not** recommend the prohibited production read and says so plainly. The in-boundary alternative (re-capture from the **staging** catalogue, as `00-stage2-execution-plan.md:199` demands) is circular at Stage 2: staging cannot receive the function DDL that a capture would read, because A3's load source is the blocked artefact. The only non-circular in-boundary path is evidence the owner already holds outside this repository — the project's own migration history / source repository (Stage 1 records the source tree as unavailable) — released under A0/A7-class owner decision; any such candidate must be signature- and ACL-cross-checked against §2 before any upgrade, and would at best move bodies from MISSING to UNVERIFIED — SOURCE AMBIGUOUS until traceable.

---

## 8. Evidence split

**Verified (raw-export traceable):** population 38/14/24 (`g1-b3b` fields, §1); per-function args/definer/search_path/ACL (`inventory.rows[]`); 14 bodies + digests (§2); 7+1 trigger definitions (`g1-q3`, `g1-q3b`); 21 policy predicates and the 17-function-referrer count (`g1-q2`, §4); zero intra-schema overloads, 13 cross-schema twin pairs; `93-counts.json` emitted-lines 40=0; absence of `supabase/functions`, empty `pairing/` dir; P01/P02/P03 referenced-object lists; A5 row text; D-06 = OPEN.
**Inferred (declared criterion, never promoted):** private-schema ownership (`postgres`, from ACL grantor strings only — manifest amendment 3); §5 grouping A/B/C (name-pattern criterion); q10↔public-set name correspondence (no per-row schema field); the delegation *pattern* of the one evidenced wrapper (recorded, deliberately **not** transferred to other wrappers); `functions_exposed "0 of 38"` as population corroboration.
**Missing — source evidence absent (24 bodies + return types):** every §5 row; return type for all 38 in raw exports; publication state (80); proowner column; staging-catalogue pre-images (§6).
**Unverified / conflicting:** return-type narrative claims in `functions-and-triggers.md` §1 vs raw exports — `CONFLICT — SOURCE DISAGREEMENT` (ret dimension, 14 public rows); `poll_device_commands` DEFAULT rendering — same label (signature dimension, both schemas); q7/q10 attribution (unattributable rows, artefact appendix upheld); 4 orphan policies over-blocked in `60-rls-policies.sql`.
**Recommendations:** (1) adopt §2 digests as the D-06 offline pre-image store and add hash+overload **assertions** (not advisory selects) to P01/P02 post-checks when D-06 is revised — patch files themselves untouched here; (2) emit the 4 `auth.uid()`-only policies first in any future load order (they do not need §40); (3) keep all 24 bodies `MISSING — SOURCE EVIDENCE ABSENT` and all narrative return types out of every artefact and patch; (4) if the owner ever releases the project migration history or a staging capture, re-run this register and upgrade row-by-row against signature+ACL traceability only; (5) do not schedule A5 until D-06, D-07 and the P03 count precondition are closed — none can be closed by this or any offline pass.
