# S2-EXEC-04 — Function and Trigger Forensic Coverage Register (domain audit)

| Field | Value |
| --- | --- |
| Domain | functions, triggers, function-dependent RLS policies only (7 parallel auditors; this file covers one domain) |
| Auditor role | read-only forensic re-derivation |
| Repo | `D:\control` |
| Artefact under audit | `C:\Users\ASUS\.qoder\tmp\D--control\g3-build\40-functions.sql`, `50-triggers.sql`, `55-auth-users-trigger.sql`, `60-rls-policies.sql` (S2-EXEC-03 / N-2, built 2026-11-02) |
| Evidence re-parsed | `D:\control\docs\stage1\evidence\g1-b3b-20261029.json`, `g1-q2-20261029.json`, `g1-q3-20261029.json`, `g1-q3b-20261029.json`, `g1-q7-20261029.json`, `g1-q10-20261029.json`, `g1-run-manifest-20261029.md`, `functions-and-triggers.md`; plus Stage 1 docs `00-status-register.md`, `03-data-model.md`, `11-remediation-proposals.md`, `14-edge-function-security-audit.md`, `reports/stage1-final.md`; plus Stage 2 `docs/stage2/patches/*.sql` |
| Operations performed | local file reads, `python` JSON parsing, `grep`, `wc`, `sha256sum`. **No cloud call, no dashboard, no CLI, no SQL executed, no DB connection. Production `parent-control-prod` not touched. No existing file modified — this is the only file created.** |
| Artefact integrity | `40-functions.sql` sha256 `599f038f85521623ef52ed7f72e1771092d69e9f755483075799a87bc93a69ef`; `50-triggers.sql` `d4615bdaae9aa7574b0ead517bbc6450677d94af96615917a156af6e02f9ac8e`; `55-auth-users-trigger.sql` `6484dbd0c436faae3adedccd676dbe0a73acdead4018601f541f51d2b96d8d7d`; `60-rls-policies.sql` `4c843ad9a1da49a7bcf75a8d7ceecd40cc3b28fa539c92b632d81cbacc00acc8`; source `g1-b3b-20261029.json` `72f0e1de49b491e46e8fee42f8bdd243ee1b8eecfb5990194e35133579be3d30` |
| Citation convention | `b3b:N` = line N of `g1-b3b-20261029.json` (a 177-line pretty-printed file; inventory rows occupy lines 44–81, `bodies` lines 84–168). `ft.md:N` = line N of `functions-and-triggers.md`. `q2[i]` = array index i of the single-line `g1-q2-20261029.json`. JSON field names are given in backticks. |
| Body-text policy | no function body text is reproduced in this file. Bodies are reported as `PRESENT (N chars)` + SHA-256 of the body text only. |

**Six-term vocabulary used in the register (defined here once, applied per row):**

| Term | Meaning in this register |
| --- | --- |
| `PRESENT — SOURCE VERIFIED` | every column needed to re-create the object is captured in authorised evidence and concordant across ≥2 independent captures. **No function in this domain reaches this state**, because no executable DDL can be written (see §1.4). |
| `PRESENT — PARTIAL` | metadata and/or original `prosrc` captured verbatim, but at least one required DDL element (return type, or in one case argument default) is absent from the evidence. |
| `MISSING — SOURCE EVIDENCE ABSENT` | the original body was never captured by any authorised read; metadata columns may still be evidenced. |
| `UNVERIFIED — SOURCE AMBIGUOUS` | a value exists in evidence but cannot be bound to this specific object (schema-less captures, name collisions). |
| `NOT APPLICABLE — EVIDENCE SUPPORTED` | the question does not arise for this object, and the non-applicability is itself evidenced. |
| `CONFLICT — SOURCE DISAGREEMENT` | two authorised sources state different values for the same column of the same object. |

---

## 1. Inventory re-derived from the evidence (not from the prior report)

### 1.1 Measurement method

Parsed `g1-b3b-20261029.json` → `inventory.rows` (a list of 38 objects, one line each, lines 44–81). Fields used, verbatim from the file: `schema_name`, `function_name`, `arguments`, `security_definer`, `anon_exec`, `auth_exec`, `service_exec`, `acl`, `settings`. Second source: `bodies[]` with fields `schema_name`, `function_name`, `arguments`, `body`. Bind rule used for body↔row: exact triple match on (`schema_name`, `function_name`, `arguments`) — this matched 14/14 with no leftovers, so no body is orphaned and no row borrowed a body by name alone.

### 1.2 Measured totals

| Measure | Field(s) used | Measured | File cite |
| --- | --- | --- | --- |
| Total inventoried functions | `len(inventory.rows)` | **38** | b3b:43–81 |
| `public` count | `schema_name == "public"` | **14** | b3b:68–81 |
| `private` count | `schema_name == "private"` | **24** | b3b:44–67 |
| Other schemas in the inventory | `schema_name` distinct values | **0** — only `{public, private}` | b3b:38 `inventory.note` |
| Auth-schema functions elsewhere in evidence | `g1-q7` rows with `owner == "supabase_auth_admin"` | **4** (`email`, `jwt`, `role`, `uid`) — deliberately excluded from b3b by `inventory.note` | q7 rows; b3b:38 |
| Distinct function *names* | `set(function_name)` | **25** | b3b:44–81 |
| Cross-schema name+signature collisions ("twins") | same `function_name`, same `arguments`, different `schema_name` | **13 pairs = 26 rows** | §1.3 |
| Same-schema overloads (same name, different signature, one schema) | grouped by (`schema_name`,`function_name`) | **0** | §1.3 |
| Unique-name rows | | **12** (11 `private` + `public.request_remote_session`) | §1.3 |
| Bodies captured verbatim (`prosrc`) | `len(bodies)` | **14** = 12 `private` + 2 `public` | b3b:84–168 |
| Bodies absent | 38 − 14, matched by triple | **24** = **12 `public` + 12 `private`** | §4.1 |
| Return types in any raw catalogue capture | key scan of every `g1-*.json` for `prorettype` / `return_type` / `rettype` | **0 of 38** | all 11 JSON files; key inventory in §1.4 |
| Return types stated in the dashboard-derived narrative | `ft.md` §1 table `Returns` column | **14 of 38** (the 14 `public` names only) | ft.md:34–49 |
| `SECURITY DEFINER` functions | `security_definer == true` | **34**; the 4 non-definers are `private.audit_logs_append_only`, `families_before_update`, `profiles_before_update`, `set_updated_at` | b3b:44–81; matches ft.md:13–16 |
| `search_path` pinned | `settings[0]` | **38 of 38** pinned; 36 = `public, private, pg_temp`; **2 omit `private`**: `public.request_remote_session` (b3b:78) and `private.remote_session_transition_guard` (b3b:60) | b3b:44–81 |
| ACL shapes | `acl` | `postgres=X/postgres,service_role=X/postgres` ×27 · `postgres=X/postgres` ×5 · `postgres=X/postgres,authenticated=X/postgres` ×4 · `(null = default PUBLIC EXECUTE)` ×2 (`private.remote_session_transition_guard` b3b:60, `private.request_device_recovery` b3b:62 → finding F8) | b3b:44–81 |

### 1.3 Overload detection (explicit)

Grouping `inventory.rows` by `function_name` gives 13 names with exactly 2 rows each and 12 names with 1 row. In **all 13 cases** the two rows have **byte-identical `arguments`** and **different `schema_name`** — i.e. these are `public`/`private` twin pairs, **not** Postgres overloads:

`apply_policy_version` (b3b:44/68) · `create_family_with_owner` (46/69) · `create_pairing_invite` (47/70) · `create_pairing_request` (48/71) · `detect_offline_devices` (49/72) · `expire_stale_commands` (50/73) · `expire_stale_sessions` (51/74) · `poll_device_commands` (56/75) · `replace_device_apps` (61/76) · `request_device_recovery` (62/77) · `respond_pairing_request` (63/79) · `revoke_device` (64/80) · `unlink_child` (67/81).

Unique names: `private.audit_logs_append_only` (45), `families_before_update` (52), `handle_new_user` (53), `is_family_member` (54), `is_family_parent` (55), `profiles_before_update` (57), `realtime_topic_allowed` (58), `record_audit` (59), `remote_session_transition_guard` (60), `set_updated_at` (65), `shares_active_family` (66), `public.request_remote_session` (78).

**Overloads are fully accounted for** because b3b selects `schema_name` per row and the note at b3b:38 states that membership "is proven by the result and not by the WHERE clause alone". The consequence of the twin pattern is different from an overload problem: it makes every **schema-less** capture ambiguous (§1.5, §2 `Return type` / language columns).

### 1.4 Agreement / disagreement with the prior record (38 / 14 / 24)

Prior record audited: `90-limitations.md`, `91-coverage.md`, `92-provenance-manifest.md`, `93-counts.json` (in `g3-build\`) and `D:\control\docs\stage2\S2-EXEC-03-documentation-reconciliation-report.md`, `approval-package-v2-ratification-and-forward.md`.

| # | Claim as recorded | Where recorded | Measured | Verdict |
| --- | --- | --- | --- | --- |
| 1 | "38 functions inventoried" | `93-counts.json` `expected.functions` = 38; `91-coverage.md:14`; `S2-EXEC-03:84` | 38 | **AGREES** |
| 2 | "14 bodies present" | `93-counts.json` `expected.function_bodies` = 14; `40-functions.sql:843` `COUNTS` line | 14 | **AGREES** |
| 3 | "24 bodies absent" | `93-counts.json` `expected.function_bodies_absent` = 24; `40-functions.sql:843` | 24 | **AGREES on the total** |
| 4 | **"24 `private`-schema bodies absent"** | `90-limitations.md:126` (row L-2: "24 `private` bodies absent"); echoed at `approval-package-v2-ratification-and-forward.md:189` ("the `private` schema bodies were never read") | 24 absent = **12 `public` + 12 `private`** | **DISAGREES — misattribution of the schema split.** Correct split is already in the repo at `docs/stage1/03-data-model.md:124–127` ("11 `private` RPC implementations, 12 `public` bodies and `private.record_audit` remain unread" = 24) and `docs/stage1/00-status-register.md:29` ("PA3 re-scoped to 11 unread `private` twin implementations (24 unread bodies in total)"). The number 24 is right; the label "private" is wrong for half of it. |
| 5 | **"0 return types captured for any function"** | `91-coverage.md:17` ("Function return types \| 38 \| 0 \| 0 \| 38 \| no G1 query selects one"); `S2-EXEC-03:112` ("Zero return types for 38 functions"); `S2-EXEC-03:153` ("0 of 38"); `approval-package-v2:189` ("No return type was captured for any of the 38 functions"); `40-functions.sql:14–15` | **0 of 38 in the raw catalogue captures** (true: no `g1-*.json` carries `prorettype`/`return_type`/`rettype` — verified by key scan of all 11 files) but **14 of 38 in the authorised evidence set**: `ft.md:34–49` has a `Returns` column for all 14 `public` names (`jsonb` ×9, `integer` ×4, `remote_sessions` row ×1). `g1-run-manifest-20261029.md:59` (amendment note 2) states explicitly that `functions-and-triggers.md` "is also part of this evidence set". | **DISAGREES — partially.** The claim is correct for raw catalogue exports and wrong for the evidence set as a whole. Corrected statement: **return types are absent from every raw capture; a narrative dashboard transcription supplies them for the 14 `public` names; 0 of 24 `private` functions have any return-type evidence.** Consequence for executability is unchanged (§5) because the narrative table carries no `schema_name` (see §6-D U-1) and `prosrc` alone cannot close 24 bodies. |
| 6 | "all 38 pin a `search_path`" | ft.md:20–21; `40-functions.sql` per-row `search_path` lines | 38 of 38 | **AGREES** |
| 7 | "`g1-q7` rows not attributable to a schema; attribution unsafe" → language/volatility/owner left `NOT PRESENT` | `40-functions.sql:32` (first per-row occurrence; repeated on all 38 blocks) and per-row; `90-limitations.md:129` (L-5); `S2-EXEC-03:113–114` | q7 has indeed no `schema_name` field, **but** its 14 non-`supabase_auth_admin` rows are **set-identical** to `g1-q10.functions` (14 rows) and to b3b's 14 `public` rows on the 5-tuple (`function_name`, `arguments`, `acl`, `security_definer`, `settings`) — measured equal, and the remaining 4 q7 rows are `email/jwt/role/uid` with `owner=supabase_auth_admin`, exactly the set b3b:38 excludes | **DISAGREES on strength, AGREES on caution.** Three-way set concordance + `g1-run-manifest-20261029.md:27` ("Q7 \| 18 rows: `public`+`auth` functions") attributes `language`/`volatility`/`owner` to the **14 `public`** functions at `PRESENT — PARTIAL` (conditional on the manifest's description of the query), not `NOT PRESENT`. It remains genuinely unattributable for the 13 `private` twins (identical 5-tuples, so content cannot discriminate) and **absent** for the 11 `private`-only names. The artefact's conservative blanking is defensible but under-states what the evidence supports. |
| 8 | "0 of 21 policies emittable — all blocked on section 40" | `S2-EXEC-03:156`; `90-limitations.md:130` (L-6 "21 policies blocked on undefined functions"); per-row tag `BLOCKED ON SECTION 40` on all 21 lines of `60-rls-policies.sql:40–76` | **17 of 21** call a `private.*` function; **4 of 21** call only `auth.uid()` (platform-supplied, not defined in section 40) — measured in §3.3. `60-rls-policies.sql:16–17` itself says "17 of the 21" | **DISAGREES — internal inconsistency in the artefact set.** The header count (17) matches measurement; the per-row tags and the two summary rows (21) over-count by 4. |
| 9 | "7 triggers + 1 auth trigger, all blocked on section 40" | `50-triggers.sql:19–37`, `55-auth-users-trigger.sql:19–22`, `S2-EXEC-03:85–86`, `93-counts.json` `triggers_public`=7, `trigger_auth_users`=1 | 7 + 1 = 8 triggers, each calling exactly one `private.*` function; all 8 called functions have **captured bodies** but **no captured return type** | **AGREES**, with the refinement that the blocker for all 8 is the return type (and, for `private`-only names, language), not the body (§3.1). |

---

## 2. Per-function register — all 38, one row each (no sampling)

Legend for the source tokens: `b3b:N` = `g1-b3b-20261029.json` line N (`inventory.rows` entry) · `q7` = `g1-q7-20261029.json` (18 rows, no `schema_name`) · `q10` = `g1-q10-20261029.json` `functions[]` (14 rows, no `schema_name`) · `q3`/`q3b` = trigger captures · `q2[i]` = policy array index · `ft.md:N` = `functions-and-triggers.md` line N · `40:x-y` = `40-functions.sql` line range.
`return type` column values: `NOT PRESENT IN EVIDENCE` = no authorised source states one; `NARRATIVE ft.md:NN <type>` = stated in the dashboard-derived §1 table (pre-B3b, no `schema_name`), no raw catalogue corroboration.
`§40` column: every one of the 38 blocks in `40-functions.sql` is comment-only. Measured: `40-functions.sql` has 0 non-comment lines in 866 lines (same for `50-triggers.sql` 0/40 and `55-auth-users-trigger.sql` 0/23; `60-rls-policies.sql` has 19, all `ALTER TABLE … ENABLE ROW LEVEL SECURITY`). So "executable?" = **no, for all 38**.

| # | Schema | Function (b3b line) | Arg signature | Return type | Original body in Stage 1 evidence | Body in `40-functions.sql` | Definer flag evidenced | `search_path` evidenced | Overloads accounted for | Independently verifiable from existing authorised evidence | State |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 1 | private | `apply_policy_version` :44 | EVIDENCED `.arguments` :44 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :24–34 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :68, same signature | NO second source (b3b only) — but caller-side contract exists, see §4.4 | MISSING — SOURCE EVIDENCE ABSENT |
| 2 | private | `audit_logs_append_only` :45 | EVIDENCED `.arguments` :45 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (420 chars) sha256:a359bcd8… | COMMENT-ONLY :36–61 (prosrc block :47–61) | EVIDENCED `=False`, cross-check q3 row 1 | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b flag + `q3` verbatim trigger DDL + behaviour read (`reports/stage1-final.md:87`, ft.md:25–26) | PRESENT — PARTIAL |
| 3 | private | `create_family_with_owner` :46 | EVIDENCED `.arguments` :46 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :63–73 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :69 | NO second source (b3b only); Edge caller `auth-bootstrap → create_family` (`evidence/edge-functions/capture-20261030.json` `functions[].actions`) | MISSING — SOURCE EVIDENCE ABSENT |
| 4 | private | `create_pairing_invite` :47 | EVIDENCED `.arguments` :47 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :75–85 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :70 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 5 | private | `create_pairing_request` :48 | EVIDENCED `.arguments` :48 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :87–97 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :71 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 6 | private | `detect_offline_devices` :49 | EVIDENCED `.arguments` :49 (empty) | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :99–109 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :72 | NO second source (b3b only); Edge `cron → detect_offline` action recorded | MISSING — SOURCE EVIDENCE ABSENT |
| 7 | private | `expire_stale_commands` :50 | EVIDENCED `.arguments` :50 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :111–121 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :73 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 8 | private | `expire_stale_sessions` :51 | EVIDENCED `.arguments` :51 (empty) | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :123–133 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :74 | NO second source (b3b only); Edge `cron → expire_sessions` action recorded | MISSING — SOURCE EVIDENCE ABSENT |
| 9 | private | `families_before_update` :52 | EVIDENCED `.arguments` :52 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (377 chars) sha256:cabb3f6c… | COMMENT-ONLY :135–157 (prosrc :146–157) | EVIDENCED `=False`, cross-check q3 row 3 | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q3 + behaviour read (`reports/stage1-final.md` §2.2, F2) | PRESENT — PARTIAL |
| 10 | private | `handle_new_user` :53 | EVIDENCED `.arguments` :53 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (463 chars) sha256:7cf70be9… | COMMENT-ONLY :159–190 (prosrc :170–190) | EVIDENCED `=True`, cross-check q3b | EVIDENCED `public, private, pg_temp`, also in q3b `.function_settings` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q3b verbatim trigger DDL + behaviour read (F3 `'unset'` bootstrap) | PRESENT — PARTIAL |
| 11 | private | `is_family_member` :54 | EVIDENCED `.arguments` :54 | NOT PRESENT IN EVIDENCE | PRESENT (249 chars) sha256:30c867ff… | COMMENT-ONLY :192–213 (prosrc :203–213) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q2[5],q2[7],q2[15] predicate text + ACL `authenticated=X` | PRESENT — PARTIAL |
| 12 | private | `is_family_parent` :55 | EVIDENCED `.arguments` :55 | NOT PRESENT IN EVIDENCE | PRESENT (277 chars) sha256:6f9719ef… | COMMENT-ONLY :215–237 (prosrc :226–237) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q2 predicate text (13 policies) + ACL | PRESENT — PARTIAL |
| 13 | private | `poll_device_commands` :56 | EVIDENCED `.arguments` :56 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :239–249 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :75 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 14 | private | `profiles_before_update` :57 | EVIDENCED `.arguments` :57 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (578 chars) sha256:66a4488b… | COMMENT-ONLY :251–279 (prosrc :262–279) | EVIDENCED `=False`, cross-check q3 row 5 | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q3 + behaviour read; supersedes ft.md:69 "NOT VERIFIED" (ft.md:22–24) | PRESENT — PARTIAL |
| 15 | private | `realtime_topic_allowed` :58 | EVIDENCED `.arguments` :58 | NOT PRESENT IN EVIDENCE | PRESENT (752 chars) sha256:aaf0e579… | COMMENT-ONLY :281–323 (prosrc :292–323) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + read body + `00-status-register.md:64` (P19 routing description) | PRESENT — PARTIAL |
| 16 | private | `record_audit` :59 | EVIDENCED `.arguments` :59 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :325–335 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | NO — b3b only. Semantics partially bounded by `_shared/audit.ts` note in `evidence/edge-functions/capture-20261030.json` (`shared[]`: caller-supplied `actor_user_id`, throws `audit_failed`) — Edge-side, not the SQL body | MISSING — SOURCE EVIDENCE ABSENT |
| 17 | private | `remote_session_transition_guard` :60 | EVIDENCED `.arguments` :60 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (226 chars) sha256:f524a247… | COMMENT-ONLY :337–356 (prosrc :348–356) | EVIDENCED `=True`, cross-check q3 row 6 | EVIDENCED `public, pg_temp` — **omits `private`** (F8) | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q3 verbatim DDL + b3b `remote_session_triggers[0]` (independent second trigger capture, lines 170–172) | PRESENT — PARTIAL |
| 18 | private | `replace_device_apps` :61 | EVIDENCED `.arguments` :61 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :358–368 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :76 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 19 | private | `request_device_recovery` :62 | EVIDENCED `.arguments` :62 | NARRATIVE `ft.md:45 jsonb` (public-named table; see §Unverified U-2) | PRESENT (1146 chars) sha256:f95442fb… | COMMENT-ONLY :370–429 (prosrc :381–429) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :77, same signature | PARTIAL — b3b body + F7/F8 narrative (`00-status-register.md:87–88`) + Edge caller; **no raw return type, no `proowner`, ACL `(null = default PUBLIC EXECUTE)`** | PRESENT — PARTIAL |
| 20 | private | `respond_pairing_request` :63 | EVIDENCED `.arguments` :63 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :431–441 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :79 | NO second source (b3b only) | MISSING — SOURCE EVIDENCE ABSENT |
| 21 | private | `revoke_device` :64 | EVIDENCED `.arguments` :64 | NOT PRESENT IN EVIDENCE | NOT PRESENT IN EVIDENCE | no body text; comment header :443–453 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :80 | NO second source; `14-edge-function-security-audit.md:405` lists it explicitly as NOT VERIFIED | MISSING — SOURCE EVIDENCE ABSENT |
| 22 | private | `set_updated_at` :65 | EVIDENCED `.arguments` :65 (empty) | NOT PRESENT IN EVIDENCE | PRESENT (58 chars) sha256:c64cd9cc… | COMMENT-ONLY :455–471 (prosrc :466–471) | EVIDENCED `=False`, cross-check q3 rows 2,4,7 | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name, **shared by 3 triggers**) | YES — b3b + 3 × q3 DDL | PRESENT — PARTIAL |
| 23 | private | `shares_active_family` :66 | EVIDENCED `.arguments` :66 | NOT PRESENT IN EVIDENCE | PRESENT (372 chars) sha256:9a446aee… | COMMENT-ONLY :473–496 (prosrc :484–496) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name) | YES — b3b + q2[10] predicate + ACL | PRESENT — PARTIAL |
| 24 | private | `unlink_child` :67 | EVIDENCED `.arguments` :67 | NARRATIVE `ft.md:49 jsonb` (public-named table) | PRESENT (2514 chars) sha256:fcafab35… | COMMENT-ONLY :498–602 (prosrc :509–602) | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in public :81, same signature | PARTIAL — b3b body + F7 narrative + is called from `private.request_device_recovery` body (second, independent mention inside captured source); no raw return type | PRESENT — PARTIAL |
| 25 | public | `apply_policy_version` :68 | EVIDENCED `.arguments` :68 ≡ q7 ≡ q10 | NARRATIVE `ft.md:36 jsonb`; raw catalogue: none | NOT PRESENT IN EVIDENCE | no body text; comment header :604–614 only | EVIDENCED `=True` (also q7, q10) | EVIDENCED `public, private, pg_temp` (also q7, q10) | twin in private :44 | YES for metadata — 3 concordant captures (b3b+q7+q10) · **NO for the object as a whole** (body absent) | MISSING — SOURCE EVIDENCE ABSENT |
| 26 | public | `create_family_with_owner` :69 | EVIDENCED :69 ≡ q7 ≡ q10 | NARRATIVE `ft.md:37 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :616–626 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :46 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 27 | public | `create_pairing_invite` :70 | EVIDENCED :70 ≡ q7 ≡ q10 | NARRATIVE `ft.md:38 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :628–638 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :47 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 28 | public | `create_pairing_request` :71 | EVIDENCED :71 ≡ q7 ≡ q10 | NARRATIVE `ft.md:39 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :640–650 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :48 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 29 | public | `detect_offline_devices` :72 | EVIDENCED :72 (empty) ≡ q7 ≡ q10 | NARRATIVE `ft.md:40 integer` | NOT PRESENT IN EVIDENCE | no body text; comment header :652–662 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :49 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 30 | public | `expire_stale_commands` :73 | EVIDENCED :73 ≡ q7 ≡ q10 | NARRATIVE `ft.md:41 integer` | NOT PRESENT IN EVIDENCE | no body text; comment header :664–674 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :50 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 31 | public | `expire_stale_sessions` :74 | EVIDENCED :74 (empty) ≡ q7 ≡ q10 | NARRATIVE `ft.md:42 integer` | NOT PRESENT IN EVIDENCE | no body text; comment header :676–686 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :51 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 32 | public | `poll_device_commands` :75 | EVIDENCED :75 ≡ q7 ≡ q10 = `p_device_id uuid, p_limit integer`; **ft.md:43 records `p_limit integer default 20`** — no raw capture carries a DEFAULT | NARRATIVE `ft.md:43 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :688–698 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :56 | YES 3-source metadata; body absent | **CONFLICT — SOURCE DISAGREEMENT** (argument-signature completeness) |
| 33 | public | `replace_device_apps` :76 | EVIDENCED :76 ≡ q7 ≡ q10 | NARRATIVE `ft.md:44 integer` | NOT PRESENT IN EVIDENCE | no body text; comment header :700–710 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :61 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 34 | public | `request_device_recovery` :77 | EVIDENCED :77 ≡ q7 ≡ q10 | NARRATIVE `ft.md:45 jsonb` | PRESENT (73 chars) sha256:92ae5bd4… | COMMENT-ONLY :712–725 (prosrc :723–725) | EVIDENCED `=True` (also q7, q10) | EVIDENCED `public, private, pg_temp` | twin in private :62 | YES — b3b+q7+q10 + body + `12-g3-baseline-plan` wrapper pattern; the only fully read public/private pair | PRESENT — PARTIAL |
| 35 | public | `request_remote_session` :78 | EVIDENCED :78 ≡ q7 ≡ q10 | NARRATIVE `ft.md:46 remote_sessions (row type)` | PRESENT (1401 chars) sha256:34cba351… | COMMENT-ONLY :727–804 (prosrc :738–804) | EVIDENCED `=True` | EVIDENCED `public, pg_temp` — **omits `private`** (F5) | NOT APPLICABLE — EVIDENCE SUPPORTED (unique name, no private twin) | YES — b3b+q7+q10 + body + q7 `language=plpgsql`; `language=plpgsql` is content-consistent with the captured `declare … begin` body | PRESENT — PARTIAL |
| 36 | public | `respond_pairing_request` :79 | EVIDENCED :79 ≡ q7 ≡ q10 | NARRATIVE `ft.md:47 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :806–816 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :63 | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |
| 37 | public | `revoke_device` :80 | EVIDENCED :80 ≡ q7 ≡ q10 | NARRATIVE `ft.md:48 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :818–828 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :64 | YES 3-source metadata; body absent (`14-edge-function-security-audit.md:405` NOT VERIFIED) | MISSING — SOURCE EVIDENCE ABSENT |
| 38 | public | `unlink_child` :81 | EVIDENCED :81 ≡ q7 ≡ q10 | NARRATIVE `ft.md:49 jsonb` | NOT PRESENT IN EVIDENCE | no body text; comment header :830–843 only | EVIDENCED `=True` | EVIDENCED `public, private, pg_temp` | twin in private :67 (**whose body IS present**) | YES 3-source metadata; body absent | MISSING — SOURCE EVIDENCE ABSENT |

Register totals measured from the table above: `PRESENT — PARTIAL` **14** (exactly the 14 rows whose body is present) · `MISSING — SOURCE EVIDENCE ABSENT` **23** · `CONFLICT — SOURCE DISAGREEMENT` **1** (#32) · `PRESENT — SOURCE VERIFIED` **0** · `UNVERIFIED — SOURCE AMBIGUOUS` used in §Unverified for column-level findings · `NOT APPLICABLE — EVIDENCE SUPPORTED` recorded in the Overloads column for 12 unique-name rows.

### 2.1 The 14 captured bodies (full digests, for A5 D-06 comparison)

| Body (schema.function) | b3b `bodies` lines | Measurement | SHA-256 of body text |
| --- | --- | --- | --- |
| `private.is_family_member` | 85–90 | PRESENT (249 chars) | `30c867ff754af8aff2d3bce89f5c3cc4f3668f0eaadafd27d0559a55be591348` |
| `private.is_family_parent` | 91–96 | PRESENT (277 chars) | `6f9719ef0579bdca62b9ecfeceeecf86be2a35f333cbc07490fdb761edce479d` |
| `private.shares_active_family` | 97–102 | PRESENT (372 chars) | `9a446aeece9ae6c41b571ba0eaf99b0cd534c8eb88e1dea559080d91f5309c89` |
| `private.handle_new_user` | 103–108 | PRESENT (463 chars) | `7cf70be9a66fafb78666b93c8241589221c8bf83af882f4a2836fa8395c21bb7` |
| `private.remote_session_transition_guard` | 109–114 | PRESENT (226 chars) | `f524a247d182f2b990b7c8a5b5e8a55ef7e22d663dffd6f5e256cd2f0c27712e` |
| `private.profiles_before_update` | 115–120 | PRESENT (578 chars) | `66a4488beefb12dc05668a426a685d257cb2b6d9cb3d230f15735b18bdf04d78` |
| `private.families_before_update` | 121–126 | PRESENT (377 chars) | `cabb3f6c7b9bbced6e9eb982d4b499f0bec513f2d8dc571fed641ce691a05968` |
| `private.audit_logs_append_only` | 127–132 | PRESENT (420 chars) | `a359bcd80c3fc66940f6bbb934135b6c48d2a55bf300d4c6a5c09e6e3cd671a7` |
| `private.set_updated_at` | 133–138 | PRESENT (58 chars) | `c64cd9cc61d0e6df4bb6cc12e674734d27627d430474ab6d08436092743303c5` |
| `private.realtime_topic_allowed` | 139–144 | PRESENT (752 chars) | `aaf0e5791b1479eb279d2f2a3a6f0b68a76fbf560826bf3f88950f158d9bf3ed` |
| `private.request_device_recovery` | 145–150 | PRESENT (1146 chars) | `f95442fb5bffd6f2fa1587f39feef49f31d47b5f6e6c19794933d418abd4caac` |
| `public.request_device_recovery` | 151–156 | PRESENT (73 chars) | `92ae5bd4a52778a2e37d3090565d28e371c0abd1c999e75f45a72efd8402bf3e` |
| `public.request_remote_session` | 157–162 | PRESENT (1401 chars) | `34cba351ce9bf56931682393074fbd47fdedbb2a57c202fb262ecc98edfeef8c` |
| `private.unlink_child` | 163–168 | PRESENT (2514 chars) | `fcafab3585d3d2870ff168a2c66fcb3c21751a9755373bc964a296c7d788082c` |

Secret scan of the 14 bodies (local regex over `secret|password|token|api[_-]?key|eyJ…|key=`): two hits, both **identifiers, not values** — the column name `secret_hash` in an assignment to `null`, and the table name `device_pairing_tokens`, both inside `private.unlink_child`. No credential-shaped literal is present in any captured body. This does **not** extend to the 24 unread bodies (agrees with `90-limitations.md:146–147`).

---

## 3. Cross-reference: dependents on section 40

### 3.1 Triggers — 7 × `g1-q3` + 1 × ``g1-q3b`

Measured from the `definition` text of each row (regex `EXECUTE FUNCTION <schema>.<name>()`), then bound to `b3b:inventory.rows` by (`schema_name`,`function_name`) and checked against `b3b:bodies`.

| # | Trigger | Table | Function called (from captured DDL) | b3b row | `security_definer` q-capture vs b3b | Body of called function | Return type | Blocked by §40? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | `audit_logs_append_only` | `public.audit_logs` (BEFORE DELETE OR UPDATE, FOR EACH ROW) | `private.audit_logs_append_only()` | :45 | `False` = `False` ✓ | PRESENT (420) | none | YES |
| T2 | `devices_set_updated_at` | `public.devices` (BEFORE UPDATE) | `private.set_updated_at()` | :65 | `False` = `False` ✓ | PRESENT (58) | none | YES |
| T3 | `families_before_update` | `public.families` (BEFORE UPDATE) | `private.families_before_update()` | :52 | `False` = `False` ✓ | PRESENT (377) | none | YES |
| T4 | `families_set_updated_at` | `public.families` (BEFORE UPDATE) | `private.set_updated_at()` | :65 | `False` = `False` ✓ | PRESENT (58) | none | YES |
| T5 | `profiles_before_update` | `public.profiles` (BEFORE UPDATE) | `private.profiles_before_update()` | :57 | `False` = `False` ✓ | PRESENT (578) | none | YES |
| T6 | `remote_sessions_transition_guard` | `public.remote_sessions` (BEFORE UPDATE **OF status**) | `private.remote_session_transition_guard()` | :60 | `True` = `True` ✓ | PRESENT (226) | none | YES |
| T7 | `safe_zone_states_set_updated_at` | `public.safe_zone_states` (BEFORE UPDATE) | `private.set_updated_at()` | :65 | `False` = `False` ✓ | PRESENT (58) | none | YES |
| T8 | `on_auth_user_created` | `auth.users` (AFTER INSERT) | `private.handle_new_user()` | :53 | `True` = `True` ✓ | PRESENT (463) | none | YES |

Measurement: 8 triggers → **6 distinct functions** (`audit_logs_append_only`, `set_updated_at` ×3, `families_before_update`, `profiles_before_update`, `remote_session_transition_guard`, `handle_new_user`). All 6 have **bodies present** and **return types absent**; all 6 are `private`-only names, so `g1-q7` supplies them no language either. Definer flags: **8/8 concordant** between the trigger captures and the b3b inventory (no conflict).

Second-order effect: T1/T3/T5/T6 are security controls (append-only audit, role/ownership guards, session-transition guard). Because §40 emits nothing, `50-triggers.sql:19–37` and `55-auth-users-trigger.sql:19–22` are correct to hold all 8 as comments — **0 of 8 emittable**.

### 3.2 RLS policies — 21 × `g1-q2`, functions called measured from `qual` + `with_check`

Regex over both fields for `private.<fn>(` and `auth.<fn>(`:

| Policy (table · name · cmd · role) | q2 index | `private.*` called | `auth.*` called | Dependent on §40 |
| --- | --- | --- | --- | --- |
| `audit_logs` · `audit_logs_select_family_parent` · SELECT · authenticated | [0] | `is_family_parent` | — | **YES** |
| `device_apps` · `device_apps_select_parent_or_child` · SELECT · authenticated | [1] | `is_family_parent` | `uid` | **YES** |
| `device_commands` · `device_commands_select_parent_or_child` · SELECT · authenticated | [2] | `is_family_parent` | `uid` | **YES** |
| `device_policies` · `device_policies_select_parent_or_child` · SELECT · authenticated | [3] | `is_family_parent` | `uid` | **YES** |
| `devices` · `devices_select_parent_or_child` · SELECT · authenticated | [4] | `is_family_parent` | `uid` | **YES** |
| `families` · `families_select_members` · SELECT · authenticated | [5] | `is_family_member` | — | **YES** |
| `families` · `families_update_owner` · UPDATE · authenticated | [6] | — | `uid` | **NO** |
| `family_members` · `family_members_select_family` · SELECT · authenticated | [7] | `is_family_member` | — | **YES** |
| `location_events` · `location_events_select_parent_or_child` · SELECT · authenticated | [8] | `is_family_parent` | `uid` | **YES** |
| `pairing_requests` · `pairing_requests_select_participants` · SELECT · authenticated | [9] | `is_family_parent` | `uid` | **YES** |
| `profiles` · `profiles_select_self_or_family` · SELECT · authenticated | [10] | `shares_active_family` | `uid` | **YES** |
| `profiles` · `profiles_update_self` · UPDATE · authenticated | [11] | — | `uid` | **NO** |
| `remote_sessions` · `remote_sessions_select_participants` · SELECT · authenticated | [12] | `is_family_parent` | `uid` | **YES** |
| `safe_zones` · `safe_zones_delete_parent` · DELETE · authenticated | [13] | `is_family_parent` | — | **YES** |
| `safe_zones` · `safe_zones_insert_parent` · INSERT · authenticated | [14] | `is_family_parent` (WITH CHECK only; `qual` is null) | — | **YES** |
| `safe_zones` · `safe_zones_select_family` · SELECT · authenticated | [15] | `is_family_member` | — | **YES** |
| `safe_zones` · `safe_zones_update_parent` · UPDATE · authenticated | [16] | `is_family_parent` (USING + CHECK) | — | **YES** |
| `safety_alerts` · `safety_alerts_select_parent_or_child` · SELECT · authenticated | [17] | `is_family_parent` | `uid` | **YES** |
| `usage_daily` · `usage_daily_select_parent_or_child` · SELECT · authenticated | [18] | `is_family_parent` | `uid` | **YES** |
| `webrtc_signals` · `webrtc_signals_insert_participant` · INSERT · authenticated | [19] | — | `uid` | **NO** |
| `webrtc_signals` · `webrtc_signals_select_participant` · SELECT · authenticated | [20] | — | `uid` | **NO** |

Aggregation measured: **17 blocked / 4 not blocked**; per-function fan-out `private.is_family_parent` → 13 policies, `private.is_family_member` → 3, `private.shares_active_family` → 1. All three are `PRESENT — PARTIAL` rows (#11, #12, #23): bodies captured, return types absent — and a policy `USING` predicate requires a boolean-returning function, so the missing return type is the binding constraint for these 17.

### 3.3 Total objects blocked by the absent function DDL

| Class | Captured | Blocked on §40 | Emittable today | Evidence |
| --- | --- | --- | --- | --- |
| `public`-table triggers | 7 | **7** | 0 | §3.1; `50-triggers.sql:19–37` |
| `auth.users` trigger | 1 | **1** | 0 | §3.1 T8; `55-auth-users-trigger.sql:19–22` |
| RLS policies | 21 | **17** (not 21) | 0 | §3.2; `60-rls-policies.sql:16–17` header vs per-row tags |
| RLS policies not dependent on §40 | 4 | 0 | 4 in principle (they call only `auth.uid()`, platform-supplied; §40 defines no `auth.*` object — b3b:38) | §3.2; b3b:38; `data_api_exposure.schemas_offered` |
| RLS enablement | 19 tables | 0 | 19 (emitted) | `60-rls-policies.sql:20–38`, `93-counts.json` |
| Realtime publication | 4 tables | not a §40 dependency | 0, but blocked for a different reason: `pg_publication` never captured | `80-realtime-publication.sql:14–24` |
| **Total function-dependent objects** | **29** | **25** | **0** | sum of the three blocked rows |

No function among the 38 is recorded here as "unused": the caller side is evidenced only for the 14 `public` RPC names (Edge tier: `14-edge-function-security-audit.md:96–97, 306`; `evidence/edge-functions/capture-20261030.json` `functions[].actions`), and 24 bodies were never read, so usage of any individual `private` function cannot be asserted either way.

### 3.4 Defects observed in the audited artefact (recorded, not fixed — §40 and siblings are out of bounds for this audit)

1. `60-rls-policies.sql:62` and `:71` render null `qual` as the literal string `USING (None)` inside the policy text (source values at q2[14] and q2[19] are JSON null). A verbatim copy would not reproduce `g1-q2`. Cosmetic in a comment file, but it is a transcription defect on a line the file labels `VERIFIED FROM SOURCE`.
2. All 21 policy lines carry the tag `BLOCKED ON SECTION 40` while the same file's header (line 16) says 17 of 21; `90-limitations.md:130` (L-6) and `S2-EXEC-03:156` repeat 21. Measurement is 17 (§3.2).
3. `40-functions.sql:14–15` states "the approved evidence contains NO return type for ANY of the 38 functions". Correct for raw captures, **not** for the evidence set as a whole (`ft.md:34–49`, admitted as evidence by `g1-run-manifest-20261029.md` amendment note 2). See §1.4 row 5 for the consequence analysis.
4. `90-limitations.md:126` (L-2) attributes all 24 absent bodies to `private`; measurement is 12 `public` + 12 `private` (§4.1). `93-counts.json` `function_bodies_absent` = 24 is right.
5. `40-functions.sql` per-row line "language/volatility: NOT PRESENT IN EVIDENCE … attribution unsafe" is stricter than the evidence supports for the 14 `public` rows (§1.4 row 7).

---

## 4. The 24 absent bodies

### 4.1 The list, grouped

**Group A — `public` RPC wrappers, body never read (12):** `apply_policy_version` :68 · `create_family_with_owner` :69 · `create_pairing_invite` :70 · `create_pairing_request` :71 · `detect_offline_devices` :72 · `expire_stale_commands` :73 · `expire_stale_sessions` :74 · `poll_device_commands` :75 · `replace_device_apps` :76 · `respond_pairing_request` :79 · `revoke_device` :80 · `unlink_child` :81.

**Group B — `private` implementations behind a `public` twin, body never read (11):** `apply_policy_version` :44 · `create_family_with_owner` :46 · `create_pairing_invite` :47 · `create_pairing_request` :48 · `detect_offline_devices` :49 · `expire_stale_commands` :50 · `expire_stale_sessions` :51 · `poll_device_commands` :56 · `replace_device_apps` :61 · `respond_pairing_request` :63 · `revoke_device` :64.

**Group C — `private` helper with no twin (1):** `record_audit` :59.

Cross-check: `public.request_remote_session` has no private twin and its body **is** present, so it is in neither group; `private.request_device_recovery` and `private.unlink_child` are read, so their twin rows are in Group A only. 12 + 11 + 1 = 24 ✓, and matches `03-data-model.md:124–127` and `00-status-register.md:29` independently.

### 4.2 Recovery routes searched in this repository (all negative for the 24)

| Candidate route | Searched how | Result | Verdict if it had been used |
| --- | --- | --- | --- |
| Supabase migrations / SQL source tree | `find . -name "*.sql"`, `find -type d` over `D:\control` (79 files, no `supabase/migrations`, `supabase/functions` absent) | Only 3 `.sql` files exist, all Stage 2 patches (§4.3). `supabase/` contains `config.toml` + `.gitignore` only | — |
| `supabase/config.toml` | read + `evidence/edge-functions/capture-20261030.json` `repository.note` | Declares local API schemas `[public, graphql_public]`; the note records that it "is not a description of production" and `functions_directory: absent` | No body text |
| `functions-and-triggers.md` | full read | §1 gives names/args/**returns** for the 14 public; §2 gives trigger names; **no `prosrc` text at all** (line 8: "Function bodies … were not captured here") | Names/returns only |
| Stage 1 `reports/` and phase docs | grep for `create … function`, per-function names across `docs/stage1/**` | `reports/stage1-final.md` §2.2 describes **behaviour of the 14 read bodies only**; `03-data-model.md:124–127` and `11-remediation-proposals.md:330–345` explicitly state the 24 are unread and that "the rollback text does not exist" for them | Behaviour prose ≠ body; would be a guess |
| Edge Function capture (`evidence/edge-functions/capture-20261030.json`, `14-edge-function-security-audit.md`) | parsed `functions[].actions/anchors`, grep RPC names | Caller-side contract evidence: which RPC a handler calls, which JWT field feeds `p_actor` (`:96–97`), and that an `apply_policy_version` response carries `idempotent` (`:306`). 7 of 9 handlers are minified bundles, so even this is partial | Constrains semantics for a few names; **cannot** recover a body; any body written from it would be `UNVERIFIED — SOURCE AMBIGUOUS` at best |
| `edge-functions/pairing/` directory | `ls` | Empty (0 files) | — |
| Firebase / docs elsewhere | `find` + grep | No SQL sources | — |

**Conclusion of the search: no authorised offline route in this repository recovers any of the 24 bodies.** Zero of 24 recovered; 24 remain `MISSING — SOURCE EVIDENCE ABSENT`. Nothing was guessed, stubbed, emptied or inferred from a name.

### 4.3 Patch files — why they are not a recovery route

`docs/stage2/patches/` contains 4 function definitions. None restores an unread body:

| Definition | File:line | Relationship to the 24 |
| --- | --- | --- |
| `private.request_device_recovery(uuid, uuid)` `returns jsonb` | `S2-P02-e3-actor-binding.sql:41–43` | Stage 2 **replacement** of a body that is already captured (b3b:145–150). Header of that patch says "Originals: stage1 g1-b3b-20261029.json" (:3) and line 8 warns "never touch the 11 unread `private` twins or `public.unlink_child`" |
| `private.unlink_child(uuid, uuid, uuid)` `returns jsonb` | `S2-P02:66–68` | Replacement of captured body (b3b:163–168) |
| `public.request_remote_session(uuid, uuid, text)` `returns public.remote_sessions` | `S2-P02:108–110` | Replacement of captured body (b3b:157–162) |
| `private.remote_session_insert_guard()` `returns trigger` | `S2-P03-e4-session-invariant.sql:61–62` | **New** Stage 2 object, not among the 38 inventoried; adds to the inventory, does not recover from it |

`S2-P01-e2-f8.sql` contains no body at all (2 × `REVOKE`, 1 × `GRANT`, 1 × `ALTER FUNCTION … SET search_path`, per its SCOPE line :9).

### 4.4 Corroborations worth recording (do not close the gap)

For the 3 functions that `S2-P02` re-declares, its `returns` clauses agree with `ft.md:45`, `:49`, `:46` (`jsonb`, `jsonb`, `remote_sessions`). Two repo sources therefore agree — but the patch is written against `ft.md`, so this is **not** an independent capture; it does not upgrade the type to catalogue-verified, and it still leaves 0 of 24 absent-body functions with a type that traces to a capture.

---

## 5. Verdict for this domain

**No. Under the current evidence boundary, offline reconstruction cannot complete the function / trigger / policy layer.**

Plainly, with the counts measured above: 0 of 38 function definitions can be emitted as valid DDL, therefore 0 of 8 triggers and 0 of 17 function-dependent policies can be emitted, and 4 of 21 policies plus 19 RLS-enable statements are the only objects in this dependency chain that are not held by §40.

Two independent gaps, not one, cause this, and the prior record conflates them:

1. **24 original bodies were never read** (12 `public` + 12 `private` — not "24 private"). Nothing in the repo recovers them (§4.2). This gap is unrecoverable offline **at any return type**.
2. **Return types are absent from every raw catalogue capture.** 14 of 38 have a narrative return type (`ft.md:34–49`, `public` names only) — which is why 12 of the 14 `PRESENT — PARTIAL` rows are still not emittable: the narrative table has no `schema_name`, so for the 13 twin names it cannot be bound to `private` at all, and it is a pre-B3b transcription rather than a catalogue value. Triggers are the sharpest case: all 6 called functions have bodies yet none has a captured return type, so 8 of 8 security triggers stay unemittable purely on this gap.

**The single piece of evidence that would change the verdict:** one read-only catalogue result over `pg_proc` returning, per function, `n.nspname · proname · pg_get_function_arguments(oid) · prorettype::regtype · prolang · prosecdef · proconfig · proacl · prosrc` (equivalently `pg_get_functiondef(oid)`) for all 38 rows — the shape already authored but never executed in `S2-P01-e2-f8.sql:33–42`. With that one result the 14 read bodies become emittable (unblocking all 8 triggers and the 17 policies) **even if the 24 unread bodies stay unread**; without it, nothing in this domain closes. Stating it as evidence, not as an instruction: no action is authorised by this audit, `A1` remains `INOPERATIVE` per `S2-EXEC-03:42` (C-2), and no production read was performed or is proposed here.

---

## 6. Evidence split

### A. VERIFIED FROM SOURCE (measured directly in the raw captures, this run)

1. 38 inventory rows; 14 `public` + 24 `private`; no third schema in the inventory (b3b:44–81, `schema_name`).
2. 25 distinct names; 13 cross-schema twins with byte-identical `arguments`; **0 same-schema overloads**; 12 unique names (§1.3).
3. 14 `prosrc` bodies bound to rows by (`schema_name`,`function_name`,`arguments`) with 14 matches and 0 orphans; 24 rows unmatched (§1.2, b3b:84–168).
4. Absent bodies = **12 `public` + 12 `private`** (§4.1); independently corroborated by `03-data-model.md:124–127` and `00-status-register.md:29`.
5. `search_path` pinned on 38/38; exactly 2 omit `private` (b3b:78, b3b:60) — supports F5/F8.
6. 34 `SECURITY DEFINER` / 4 not, and the 4 are exactly the named trigger functions (b3b:44–81; ft.md:13–16).
7. ACL shapes 27 / 5 / 4 / 2, the two `(null = default PUBLIC EXECUTE)` being `private.remote_session_transition_guard` and `private.request_device_recovery` (b3b:60, :62) — supports F8.
8. Trigger set: 7 (`g1-q3`, definitions verbatim) + 1 (`g1-q3b`); 8/8 definer flags concordant with b3b; 6 distinct called functions, all with captured bodies (§3.1).
9. Policy set: 21 (`g1-q2`); 17 call `private.*` (`is_family_parent` 13, `is_family_member` 3, `shares_active_family` 1), 4 call only `auth.uid()` (§3.2).
10. Emittable content of the audited artefact in this domain: `40-functions.sql` 0 non-comment lines / 866; `50-triggers.sql` 0 / 40; `55-auth-users-trigger.sql` 0 / 23; `60-rls-policies.sql` 19 / 79 (all `ENABLE ROW LEVEL SECURITY`) (§2 preamble).
11. q7 ↔ q10 ↔ b3b-`public` three-way set equality on (`function_name`,`arguments`,`acl`,`security_definer`,`settings`) — measured equal; q7's other 4 rows are `supabase_auth_admin`-owned `email/jwt/role/uid` (§1.4 row 7).
12. No credential-shaped literal in the 14 captured bodies; the 2 regex hits are the identifier `device_pairing_tokens` and the column `secret_hash` assigned `null` (§2.1).
13. No `migrations` / `supabase/functions` / SQL source tree exists in the repo; 79 files in the working tree excluding `.git` (§4.2).

### B. INFERRED (stated as inference; not promoted)

1. **Ownership** of all 24 `private` functions: no `proowner` field exists in b3b (`g1-run-manifest-20261029.md:64`, amendment note 3, says so explicitly). `postgres` is inferred from the ACL grantor suffix. This audit does not upgrade it.
2. **Attribution of q7 language/volatility/owner to the 14 `public` rows**: relies on `g1-run-manifest-20261029.md:27` describing q7's scope as `public`+`auth`. The 5-tuple equality is measured; the scope statement is text.
3. **`public` wrappers delegate to their `private` twin**: supported by the 2 read pairs (b3b:151–156 wrapper of 73 chars; `reports/stage1-final.md:91` "the other 12 wrappers are INFERRED, not read"). Not extended beyond those 2.
4. **"The 4 `auth.uid()`-only policies are not blocked by §40"**: based on `g1-q2` predicate text containing no `private.*` reference, plus b3b:38 excluding `auth.*` from §40's scope and `data_api_exposure` showing `auth` not among offered schemas. The `auth.uid()` object itself is platform-managed and was never captured here.
5. **The `poll_device_commands` default**: `ft.md:43` says `default 20`; no capture carries it. Treated as a disagreement, not as the true signature.

### C. MISSING — SOURCE EVIDENCE ABSENT (nothing in any authorised source)

1. `prosrc` for **24** functions (§4.1 list).
2. **Return type for 24 of 38** in raw catalogue form and for **all 24 `private`** in any form; `CREATE FUNCTION` is therefore unwritable for every one of the 38.
3. `pg_language` / `prolang` for the 11 `private`-only names (`set_updated_at`, `handle_new_user`, `is_family_member`, `is_family_parent`, `shares_active_family`, `realtime_topic_allowed`, `audit_logs_append_only`, `families_before_update`, `profiles_before_update`, `remote_session_transition_guard`, `record_audit`) — none appears in q7.
4. `proowner` for every `private` row (§B.1).
5. Argument modes/defaults (`IN`/`OUT`/`DEFAULT`) — `arguments` is a plain type list everywhere.
6. Any capture of `pg_get_functiondef` (whole-statement text incl. security clause + language + return type).
7. `pg_extension`, `pg_publication*`, views, sequences (out of this domain but named at `90-limitations.md:127–128` for completeness).
8. Invocation/usage evidence for any of the 24 unread functions — hence none is marked "unused" anywhere in this register.

### D. UNVERIFIED — SOURCE AMBIGUOUS

1. **U-1 · `ft.md:34–49` schema binding.** The narrative table lists 14 bare names with a `Returns` column and no `schema_name`. For the 13 twin names the return type cannot be bound to `private`. Applied in §2 only to the `public` rows, flagged `NARRATIVE`, never as catalogue-verified.
2. **U-2 · `private.request_device_recovery` / `private.unlink_child` return type.** Bodies are read and `ft.md:45`/`:49` give `jsonb` for the same name, but under U-1 the type belongs to the `public` row. Both rows are held at `PRESENT — PARTIAL` with return type unresolved.
3. **U-3 · `poll_device_commands` signature** — `CONFLICT — SOURCE DISAGREEMENT` (§1.4, register row #32).
4. **U-4 · q7 rows vs `private` twins.** 13 of the 14 q7 app rows are, on content alone, indistinguishable between `public.x` and `private.x` (identical args/ACL/definer/settings). Only the manifest's scope statement breaks the tie; recorded as §B.2, never as verified.
5. **U-5 · `private.record_audit` semantics.** Only `pg_proc` metadata (b3b:59) plus Edge-side notes in `evidence/edge-functions/capture-20261030.json` (`shared[]`: `audit.ts` "caller-supplied `actor_user_id`", throws `audit_failed`). Edge audit writes `audit_logs` from TypeScript, so it is not evidence about the SQL function's body; any body built from it would be `UNVERIFIED — SOURCE AMBIGUOUS`, and none was built.
6. **U-6 · `realtime_topic_allowed` as a Realtime dependency.** b3b and the read body agree; the subscription path itself was never exercised (`00-status-register.md:64`, P19: "the subscription path is not exercised").
7. **U-7 · the `remote_session_triggers` block in b3b (lines 170–172).** Its `timing` renders `BEFORE UPDATE FOR EACH ROW` while the verbatim `g1-q3` DDL says `BEFORE UPDATE OF status`; the `tgtype` integer (19) is the primary. `g1-q3` is used as authoritative for the DDL text; the field-level difference is recorded rather than reconciled.
8. **U-8 · prior-record arithmetic.** Two statements in the audited artefact set conflict with measurement and with each other (21 vs 17 policies; "24 `private`" vs 12+12; "0 return types" vs 14 narrative). Each is logged in §1.4 and §3.4; **no `.sql` artefact was edited to fix them** — out of bounds for this audit.

### E. RECOMMENDATIONS (documentation only; no action taken, none authorised)

1. Correct `90-limitations.md:126` (L-2) to "24 bodies absent = 12 `public` + 12 `private`" when an owner authorises a text change; keep `93-counts.json` as-is (its 24 is right).
2. Restate the return-type blocker as two facts, not one: "0 of 38 in raw catalogue captures; 14 of 38 narrative (`public` only, unbindable to `private`)" — replacing "zero for any function" at `S2-EXEC-03:112`/`:153` and `approval-package-v2:189`.
3. Align the policy blocker to the measured **17 of 21** at `S2-EXEC-03:156` and `90-limitations.md:130`, and reconcile it with `60-rls-policies.sql:16`.
4. Record the 4 `auth.uid()`-only policies (`q2[6]`, `[11]`, `[19]`, `[20]`) as a separate emittability class in the next artefact pass; they are currently over-tagged.
5. Log the `USING (None)` transcription defect (`60-rls-policies.sql:62`, `:71`) as a generator bug in `gen_g3.py`-produced output, so a future pass renders a null `qual` as omitted `USING`, not the string `None`.
6. Add to the register: `public.poll_device_commands` needs the `DEFAULT 20` question settled before any DDL, since `ft.md:43` and all three raw captures disagree.
7. When and if a function-definition read is authorised by the owner, the minimum column set is already specified at `S2-P01-e2-f8.sql:33–42`; extend it to `pg_get_functiondef` over all 38 rows in one batch. Until then the honest coverage statement for this domain is: **metadata 38/38 · bodies 14/38 · executable DDL 0/38 · dependent objects emittable 0/25**.
