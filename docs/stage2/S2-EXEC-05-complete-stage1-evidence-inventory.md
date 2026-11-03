# S2-EXEC-05 — Complete Stage 1 evidence inventory and accountability audit

Domain: **evidence discovery and accountability only.** This document does not audit SQL
structure, function semantics, or approvals. Every number below was measured in this pass by a
read-only command or a JSON field; the command/field is named next to it. Nothing was invented to
fill a cell: where a value is genuinely not obtainable it reads `UNKNOWN` with the reason.

Classification legend used throughout: **VERIFIED** (measured here) · **INFERRED** (reasoned from
measured facts) · **NOT PRESENT IN EVIDENCE** · **UNVERIFIED** (asserted but not resolvable).

| Field | Value |
| --- | --- |
| Auditor | S2-EXEC-05 (parallel offline auditor) |
| Date | 2026-11-03 (local; no platform clock consulted, so this is not a UTC platform record) |
| Method | Offline, repository-only. No browser, no Supabase/Firebase console, no CLI, no API/REST, no SQL execution, no database connection |
| Production project `parent-control-prod` | **Never opened or contacted.** All statements are about the in-repo capture files only |
| Live project refs | Deliberately not reproduced here; referred to as `<prod-ref>` and `<staging-ref>` |
| Files created / modified | **One** — this file. Nothing else in `D:\control` was touched; no `S2-EXEC-04-*`, `.sql` artefact, `patches/*`, or plan document was modified |
| Git operations | **None** (read-only shell only) |

## 0. Executive corrections to the three prior open findings

The audit that opened this work reported three findings. Measured here, **all three are wrong in
material ways and correct only in part**. Full detail is in the sections named.

| Prior finding | Verdict | Measured truth |
| --- | --- | --- |
| (a) `g1-q9`/`g1-q10` hold **56 rows of per-table row counts and an Edge Function source inventory** never used | **FALSE as described; PARTLY TRUE (unused)** | q9 = **Security Advisor findings** (33 occurrence-rows across 5 lint rules), q10 = **Postgres RPC inventory** (14 functions). Neither holds per-table row counts and neither holds an Edge Function inventory. `combined q9+q10 = 47 discrete rows, not 56`. They *are* unused by the artefact (§2). Per-table row counts are **NOT PRESENT IN EVIDENCE anywhere**; the only row-count figures in the repo (`1,773` location events, etc.) are **production** numbers in `docs/stage1/*.md`, not in q9/q10. The Edge Function inventory lives in `edge-functions/capture-20261030.json` (9 slugs), not q10. |
| (b) `schema-columns.md` and `functions-and-triggers.md` **do not exist at the cited paths** | **FALSE** | Both **exist** at `docs/stage1/evidence/` (VERIFIED: `ls`, `find`, SHA-256). Every repository citation to them resolves to these files (VERIFIED: `grep` of 21 citing lines; relative links from `docs/stage1/`, `docs/stage1/reports/`, `docs/stage2/`, and `docs/stage1/evidence/` all point to real files). They exist but are **not consumed by the artefact** and **not cited in the g3-build reports at all**. |
| (c) `docs/stage1/evidence/` contains **53 files** and the prior secret scan never covered it | **Count FALSE (17); coverage TRUE** | The directory holds **17 files** across 2 subdirectories (VERIFIED: `find -type f \| wc -l`). The prior secret scan (`95-secret-scan.md`, "Files scanned: 13") covered **0 of the 17 evidence files** — it scanned only the g3-build artefact. That second half is TRUE. (Plausible origin of "53": `docs/stage2/` whole = 36 files **+** `docs/stage1/evidence/` = 17 → 53; INFERRED, not reproducible under the stated path.) |

## 1. Task 1 — Full inventory of the evidence directory

**True file count under `D:\control\docs\stage1\evidence\` = 17** (VERIFIED:
`find "D:/control/docs/stage1/evidence" -type f | wc -l` → `17`; `-type l` → `0` symlinks; `-type d`
→ `edge-functions` and `edge-functions/pairing`, both scanned; `pairing` is an **empty directory** —
0 files).

Per-file measurements (bytes = `wc -c`; lines = `wc -l`; hash = `sha256sum`). Consuming component was
measured by (i) which evidence file `gen_g3.py`/`scan_phase34.py` load (`grep 'J("'`), (ii) the
per-source citation-row count in `92-provenance-manifest.md` (`grep -oh` token tally), and (iii) the
component headers. "Prior scan" = the file's presence in `95-secret-scan.md`'s 13 scanned files.

| # | Relative path | Bytes | Lines | SHA-256 | Artefact kind | G3 component that consumes it (measured) | Prior secret scan covered it? |
| --- | --- | ---: | ---: | --- | --- | --- | --- |
| 1 | `edge-functions/capture-20261030.json` | 14118 | 178 | `95ebe57cf6d0aa069113cfe5b1c10cf4d2cd739b8c326b63b3187b886a39ce33` | Phase E Edge-Function source inventory (9 slugs; 2 readable TS, 7 minified) + 9 bundle-text SHA-256 | **NOT USED BY G3** (not loaded by either script; 0 rows in `92`) | **NO** |
| 2 | `functions-and-triggers.md` | 10865 | 120 | `835f7660315068b843431f0a32d3874aa8088823c042483fbbdc1b213b7b3ed0` | Dashboard-derived note: 14 public functions **with a Returns column**, 7 triggers, Edge scan, auth settings | **NOT USED BY G3** (not loaded; 0 rows in `92`) — **carries unique data, see §6** | **NO** |
| 3 | `g1-b3b-20261029.json` | 26316 | 177 | `72f0e1de49b491e46e8fee42f8bdd243ee1b8eecfb5990194e35133579be3d30` | B3b catalogue: 38-function inventory, 14 `prosrc` bodies, trigger map, `schema_usage`, `data_api_exposure`, `authenticator_role_config` | **40 rows in `92`** → `40-functions.sql` (+ review) | **NO** |
| 4 | `g1-q1-20261029.json` | 3398 | 0* | `71e26bd255b6024f478b8bd44aa202a89d267d8b481d15b6dac3adfd42e597a6` | Q1 tables (19 rows): `rls_enabled`, `rls_forced`, owner, `table_acl` | **23 rows in `92`** → `10-tables.sql`, `60-rls-policies.sql`, `70-grants…sql` | **NO** |
| 5 | `g1-q10-20261029.json` | 4694 | 0* | `54e4c2eed5691cc5c80a0cd82876cef4ef438ef7d6aaf34d0dcd16b17fd395f6` | Q10 Postgres RPC inventory: 14 functions + `schema_usage`, with `anon/auth/service_exec`, `extension_owned`, ACL | **NOT USED BY G3 artefact** — loaded at `scan_phase34.py:31` but the symbol never reappears (grep count = 1 = dead load); 0 rows in `92`; not loaded by `gen_g3.py` | **NO** |
| 6 | `g1-q2-20261029.json` | 5728 | 0* | `3e60d28125ec07f8931f00b5efc332db85787f68453fefa0f781e1873e6bc497` | Q2 RLS policies (21 rows) | **21 rows in `92`** → `60-rls-policies.sql` | **NO** |
| 7 | `g1-q3-20261029.json` | 2162 | 0* | `826bb981219f79b927c676684d7b4e25921d479ec9ecb9c03c664f567209ce6e` | Q3 `public` triggers (7 rows) with definitions | **7 rows in `92`** → `50-triggers.sql` | **NO** |
| 8 | `g1-q3b-20261029.json` | 382 | 0* | `753a173a0b8d17ea0b2f604456bc29b74a66f0d39187f9e27f4dbe7e3e10f868` | Q3b single `auth.users` trigger `on_auth_user_created` | **1 row in `92`** → `55-auth-users-trigger.sql` | **NO** |
| 9 | `g1-q4-20261029.json` | 11587 | 0* | `a818188dd686c41fd5909830a63b19cbedf6eb16b59eabbd348109fc8ea88500` | Q4 indexes (62 rows) + definitions | **62 rows in `92`** → `30-indexes.sql` | **NO** |
| 10 | `g1-q5-20261029.json` | 31574 | 0* | `6cd58d28aa168d6372fed1dd8343ad072004bf9334e61ae1ec9b178f6716b029` | Q5 constraints (137 rows) | **137 rows in `92`** → `20-constraints.sql` | **NO** |
| 11 | `g1-q6-20261029.json` | 41706 | 0* | `bce8d2831ff9461cb1176d4d2e03b3618146aaa0a129990d9cba8afb5e1774cc` | Q6 grants: table 149, column-UPDATE 191, default ACL 24, role memberships 24 | **22 rows in `92`** → `70-grants-default-privileges.sql` | **NO** |
| 12 | `g1-q7-20261029.json` | 5040 | 0* | `58b6d622f6d4a3e15637b0e7637e86d3e5c51e1eefe2a2da330284b5c2976b7c` | Q7 functions (18 rows): definer/volatility/settings/ACL/owner, **no schema column** | **36 rows in `92`** → `40-functions.sql` metadata | **NO** |
| 13 | `g1-q8-20261029.json` | 26981 | 0* | `62aadcf21508084804ff805430be537e314e99449945fc388efac649fc0e19be` | Q8 columns (183 rows): type/ordinal/nullability/default | **183 rows in `92`** → `10-tables.sql`, `20-constraints.sql` | **NO** |
| 14 | `g1-q9-20261029.json` | 4370 | 93 | `0228925b393afc8d3f81ae806cf5f89298c6bca7acfd4c634d41cf9ea6332c56` | Q9 **Security Advisor findings** (5 rules, 33 occurrences), read from `<prod-ref>` advisor `run-lints` | **NOT USED BY G3** (not loaded by either script; 0 rows in `92`) | **NO** |
| 15 | `g1-run-manifest-20261029.md` | 6456 | 72 | `3ae29f0d729ed49ba3d67a13e83e6c2dea7099f20628276daddfce912f97a059` | Provenance/capture manifest for the G1 + B3b series; capture-time sanitisation statement | **NOT used as DDL source**; named in every component header as the provenance manifest (`g1-q1..q10, g1-b3b, g1-run-manifest-20261029.md`) but not loaded; 0 rows in `92` | **NO** |
| 16 | `g2-apk-identity-20261030.md` | 4778 | 64 | `63ccb7ecfb1381c0bc27bd8a5c7d27b790176bdd33ebb5744bfe51ff2e7fa2e7` | G2 Android APK identity (package, signer certs, APK digests) — app domain, not schema | **NOT USED BY G3** (not loaded; 0 rows in `92`) — correctly out of schema scope | **NO** |
| 17 | `schema-columns.md` | 11964 | 297 | `5445c69ae2948e9473e0a88a936d4f20cecb7528ffb614528319fb57a8716fa1` | Dashboard-derived column transcription (19 tables) — pre-G1, superseded by Q4–Q8 | **NOT USED BY G3** (not loaded; 0 rows in `92`) — redundant with the consumed `g1-q8` | **NO** |

\* `wc -l = 0` = single-line minified JSON, not an empty file (bytes column confirms content).

Consumption summary (measured): of 17 evidence files, **11 carry DDL/inventory data into the artefact**
(q1–q8, q3b, q10-nominal-excluded, b3b = 10 loaded by `gen_g3.py`; q10 is loaded only by the review
checker and unused). The remaining **7 files are NOT USED BY G3**: `g1-q9`, `g1-q10` (artefact),
`schema-columns.md`, `functions-and-triggers.md`, `g2-apk-identity-20261030.md`,
`edge-functions/capture-20261030.json`, and `g1-run-manifest-20261029.md` (provenance-only).

## 2. Task 2 — Row-by-row accountability of `g1-q9` and `g1-q10`

### 2.1 Exact JSON keys (measured via `json.load` key dump)

- **`g1-q9-20261029.json`** — top keys: `source`, `findings`.
  `source` keys: `endpoint` (names the `<prod-ref>` Security Advisor page), `retrieved`
  (`2026-10-29`), `operation`, `note`, `displayed_counts` (`errors:0, warnings:1, suggestions:4`),
  `raw_row_counts` (`total:33, WARN:15, INFO:18`).
  `findings` = 5 objects, each with `name`, `title`, `level`, `facing`, `categories`, `description`,
  (`detail` for the first), and either `count` alone or `count`+`items[]`.
- **`g1-q10-20261029.json`** — top keys: `schema_usage` (`{anon:true, authenticated:true}`),
  `functions` (14 objects). Each function's keys: `function_name`, `arguments`, `owner`,
  `security_definer`, `settings`, `anon_exec`, `auth_exec`, `service_exec`, `extension_owned`, `acl`.
  **No key contains a return type** (measured: `[k for k in keys if 'ret'/'return'/'type' in k] → []`).

### 2.2 Complete enumeration — `g1-q9` (all rows, no sampling) — 33 occurrence-rows

| Rule (`name`) | level | rows | Row-by-row values (identifiers only) | Used / partial / ignored by the reconstruction |
| --- | --- | ---: | --- | --- |
| `auth_leaked_password_protection` | WARN | 1 | "Leaked Password Protection Disabled" (project auth setting, not schema) | **IGNORED** |
| `auth_rls_initplan` | WARN | 14 | `profiles`/`profiles_select_self_or_family`, `profiles`/`profiles_update_self`, `families`/`families_update_owner`, `devices`/`devices_select_parent_or_child`, `pairing_requests`/`pairing_requests_select_participants`, `device_policies`/`device_policies_select_parent_or_child`, `device_commands`/`device_commands_select_parent_or_child`, `usage_daily`/`usage_daily_select_parent_or_child`, `location_events`/`location_events_select_parent_or_child`, `device_apps`/`device_apps_select_parent_or_child`, `safety_alerts`/`safety_alerts_select_parent_or_child`, `remote_sessions`/`remote_sessions_select_participants`, `webrtc_signals`/`webrtc_signals_select_participant`, `webrtc_signals`/`webrtc_signals_insert_participant` | **IGNORED** |
| `rls_enabled_no_policy` | INFO | 4 | tables `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states` | **IGNORED** |
| `unindexed_foreign_keys` | INFO | 12 | `audit_logs`/`audit_logs_device_id_fkey`, `device_commands`/`_created_by_fkey`, `device_commands`/`_family_id_fkey`, `device_pairing_tokens`/`_created_by_fkey`, `device_pairing_tokens`/`_redeemed_by_fkey`, `device_policies`/`_created_by_fkey`, `remote_sessions`/`_ended_by_fkey`, `remote_sessions`/`_parent_user_id_fkey`, `safe_zone_states`/`_device_id_fkey`, `safe_zones`/`_created_by_fkey`, `safety_alerts`/`_acknowledged_by_fkey`, `webrtc_signals`/`_from_user_id_fkey` | **IGNORED** |
| `unused_index` | INFO | 2 | `device_pairing_tokens`/`device_pairing_tokens_child_purpose_idx`, `device_commands`/`device_commands_expires_idx` | **IGNORED** |
| **Total** | | **33** | (WARN 15 = 1+14; INFO 18 = 4+12+2; reconciles to `raw_row_counts.total` = 33) | — |

### 2.3 Complete enumeration — `g1-q10` (all rows, no sampling) — 14 function-rows + 1 `schema_usage` object

Every function is `owner: postgres`, `security_definer: true`, `anon_exec: false`, `auth_exec: false`,
`service_exec: true`, `extension_owned: false`, ACL `postgres=X/postgres,service_role=X/postgres`.

| # | `function_name` | `arguments` | `settings` | Used / ignored |
| --- | --- | --- | --- | --- |
| 1 | `apply_policy_version` | `p_device_id uuid, p_policy jsonb, p_actor uuid, p_idempotency_key text` | `search_path=public, private, pg_temp` | **IGNORED by artefact** (present in consumed `g1-b3b`) |
| 2 | `create_family_with_owner` | `p_owner uuid, p_name text` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 3 | `create_pairing_invite` | `p_child_user_id uuid, p_family_id uuid, p_parent_user_id uuid, p_code_hash text, p_expires_at timestamptz` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 4 | `create_pairing_request` | `p_child_user_id uuid, p_family_id uuid, p_parent_user_id uuid, p_token_id uuid, p_expires_at timestamptz` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 5 | `detect_offline_devices` | *(none)* | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 6 | `expire_stale_commands` | `p_device_id uuid` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 7 | `expire_stale_sessions` | *(none)* | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 8 | `poll_device_commands` | `p_device_id uuid, p_limit integer` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 9 | `replace_device_apps` | `p_device_id uuid, p_family_id uuid, p_apps jsonb` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 10 | `request_device_recovery` | `p_device_id uuid, p_actor_user_id uuid` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 11 | `request_remote_session` | `p_device_id uuid, p_parent_user_id uuid, p_kind text` | `search_path=public, pg_temp` (omits `private`) | **IGNORED** (in b3b) |
| 12 | `respond_pairing_request` | `p_request_id uuid, p_child_user_id uuid, p_approve boolean` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 13 | `revoke_device` | `p_device_id uuid, p_actor_user_id uuid` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| 14 | `unlink_child` | `p_family_id uuid, p_child_user_id uuid, p_actor_user_id uuid` | `public, private, pg_temp` | **IGNORED** (in b3b) |
| — | `schema_usage` | `{anon:true, authenticated:true}` | — | **IGNORED** (b3b supplies `schema_usage`) |

**Accountability result:** **47 / 47 rows assessed (33 q9 + 14 q10), of which 47 are unused by the
artefact** (q9 fully ignored; q10 duplicated by the consumed `g1-b3b` and ignored). The prior
"56 rows" could not be reproduced: measured q9 = 33 and q10 = 14 (+1 `schema_usage`), combined 47.

### 2.4 Would using q9 or q10 change any coverage conclusion?

- **q9 — NO.** Security Advisor findings supply no schema DDL and no function return type, body,
  index, constraint, or policy definition. Its `items` (14 policies, 12 FKs, 2 indexes) all already
  arrive via the consumed `g1-q2`/`g1-q5`/`g1-q4`. It could serve only as an independent cross-check;
  it resolves **no** `MISSING`/`UNKNOWN` row in `91-coverage.md`.
- **q10 — NO.** It has no return type (§2.1) and its 14 functions are already inventoried (with bodies)
  in the consumed `g1-b3b`. Adding it would not move the 38 return types from `MISSING`.

### 2.5 Do the "per-table row counts" contradict any staging-empty / baseline statement? — The premise is false

- There are **no per-table row counts in q9 or q10** (§2.1 keys). The q9 field `raw_row_counts` is the
  advisor finding **occurrence** tally (33), not table rows — the probable origin of the prior
  mischaracterization (INFERRED).
- The only per-table row-count figures in the repository — `location_events 1,773`, `webrtc_signals
  1,093`, `remote_sessions 39`, `profiles 8`, `10 MAU`, `~3,388 rows`, `32 MB` (measured via `grep`,
  in `docs/stage1/01,02,03,05,06,07` and `schema-columns.md:295`) — are **production** numbers for
  `<prod-ref>`. They do **not** contradict "staging is empty": staging `<staging-ref>` is a **separate,
  newly created project** described as `0 tables, no migrations, 0 Edge Functions` in
  `docs/stage1/../stage2/evidence/S2-CREATE-01` and `05-validation-plan.md`. Production holding rows
  and staging holding none are consistent statements about two different projects.
- The one genuine emptiness caveat is **FX-18**: the staging Auth page printed `Total: 10 users
  (estimated)` over an empty grid, so `auth.users`-empty is `NOT VERIFIED` (stated in `05` §2 and
  `90-limitations` L-8). This is a **staging** observation and is **not** in q9/q10; it is untouched by
  this evidence.

### 2.6 Does the Edge Function inventory bear on `BLOCKED — EDGE SOURCE REQUIRED`?

- **q9/q10 do not.** Neither contains any Edge Function data (measured: q10 keys are Postgres-RPC
  only; q9 is the SQL advisor).
- The real inventory is `edge-functions/capture-20261030.json` (9 slugs: `pairing`,
  `auth-bootstrap`, `device-command`, `device-register`, `device-policy`, `device-telemetry`,
  `family-admin`, `remote-session`, `cron`) + `docs/stage1/13-edge-function-source-inventory.md`.
- Location correction: the literal status `BLOCKED — EDGE SOURCE REQUIRED` is in
  `00-stage2-execution-plan.md` (`:96,120,226,348`), `02-findings-to-fix-mapping.md` (E6–E12) and
  `README.md:93` — **not** in `05-validation-plan.md`, which uses `BLOCKED — STAGING FUNCTIONS NOT
  DEPLOYED`. Both are Edge-lane blockers; I report the exact strings measured.
- Does the capture **unblock** it? **NO (INFERRED from measured facts).** `13-edge-function-source-inventory.md`
  §1 verifies `supabase/functions/` is absent from the repo; `functions-and-triggers.md` §3 records that
  only `pairing` (readable, 972 lines) and `auth-bootstrap` (readable, 140 lines) expose readable
  TypeScript — the other **7 of 9 bundles are minified**, and the `_shared/*.ts` modules (which hold
  `requireUser`/`requireRole`/`assertFamilyParent`) were **not readable**. So the evidence does not
  contain the end-to-end handler source the E6–E12 fixes need; the blocker stands whether or not the
  capture is consulted. The capture *does* record 9 bundle-text SHA-256 values and per-finding line
  references (e.g. the pairing `redeem` handler lines) — useful as a **content fingerprint and partial
  review aid**, but not a source export.

## 3. Task 3 — Locate the two "missing" documents

| Document | Result | Evidence |
| --- | --- | --- |
| `schema-columns.md` | **FOUND at `D:\control\docs\stage1\evidence\schema-columns.md`** (11,964 bytes / 297 lines / SHA-256 `5445c69a…`) | `find` + `ls` + `sha256sum` here; cited by 21 repo lines |
| `functions-and-triggers.md` | **FOUND at `D:\control\docs\stage1\evidence\functions-and-triggers.md`** (10,865 bytes / 120 lines / SHA-256 `835f7660…`) | `find` + `ls` + `sha256sum` here; cited by 21 repo lines |

`find "D:/control" -iname "schema-columns*" -o -iname "functions-and-triggers*"` returns exactly these
two paths — no duplicate copies exist elsewhere. **Finding (b) is therefore FALSE as written.**

What each **covers** (VERIFIED by reading them):
- `schema-columns.md`: all 19 tables with column names, types and dashboard-rendered constraint flags
  (PRIMARY/FOREIGN KEY/UNIQUE/NULLABLE). **Does NOT cover** defaults, FK target tables/delete rules,
  unique/check constraint definitions, column grants, index definitions — those are explicitly deferred
  to Q4–Q8 and **the artefact already consumed the authoritative Q5/Q6/Q4/Q8** instead. So this file is
  **redundant** to the reconstruction's column needs; not consulting it caused **no coverage loss**.
- `functions-and-triggers.md`: the 14 public functions **with a `Returns` column** (jsonb / integer /
  `remote_sessions (row type)`), 7 triggers, Edge scan (§3), auth/session settings (§4), APK id (§5).
  **Does NOT cover** the 24 `private` functions' return types or any function body.

Equivalent information elsewhere:
- The **columns/types** equivalent is the raw `g1-q8` (183 rows) — **consumed** and authoritative; it is
  not "the same document," it is the underlying capture the note transcribed.
- The **function/return-type** equivalent: the signatures/`prosrc` arrive via `g1-b3b` (consumed), but
  the **return types do not** — the **only** in-repo source of the 14 public return types is
  `functions-and-triggers.md §1`, which the artefact did not consult. See §6.

## 4. Task 4 — Cited-but-absent evidence and unresolved citations

Method: `grep -oh` of evidence filenames and evidence ids out of `90-limitations.md`,
`91-coverage.md`, `92-provenance-manifest.md` and `S2-EXEC-03-documentation-reconciliation-report.md`,
then `find docs/stage1/evidence -name <file>` to test existence.

**Evidence files/ids cited (all short ids `g1-q1..q10`, `g1-q3b`, `g1-b3b`, plus `schema-columns.md`,
`functions-and-triggers.md`, `g1-run-manifest-20261029.md`, and cross-doc refs `01`, `approval-v2`,
`S2-EXEC-02 §6.3`, `S2-INSP-02/03`, `patches/*.sql`): every one resolves to a real file on disk
(VERIFIED).** So on the *filename/ID* axis there are **0 unresolved citations**. `S2-EXEC-02 §6.3` —
which `S2-EXEC-03 §6` relies on for the patch digests — exists (`grep` → line 219).

Unresolved findings (these are the genuine `UNVERIFIED — citation does not resolve` items):

1. **Dangling internal cross-reference in `S2-EXEC-03` line 29:** the cell asserts Stage 1 evidence
   (incl. `g1-q1…q10`, `schema-columns.md`, `functions-and-triggers.md`) was "introspected for its
   actual columns **before use** (see **§4.1**)." **There is no §4.1 in that document** (VERIFIED: its
   only subsections are §3.1 and §3.2; section 4 is "Phase 3 — secret scan" with no numbered
   subsection). The pointer does not resolve.
2. **"…before use" is contradicted for four of the named files:** `g1-q9`, `g1-q10`, `schema-columns.md`
   and `functions-and-triggers.md` are **never used by the reconstruction** (not loaded by `gen_g3.py`/
   `scan_phase34.py` for q9; q10 loaded-but-unused; the two `.md` absent from `92-provenance-manifest`
   and from `90/91`). Present-and-readable is true; "introspected before use" is an overstatement for
   the unused set.
3. **Range-citation vs actual-consumption gap:** every component header cites sources as
   `g1-q1..q10, g1-b3b, g1-run-manifest-20261029.md`, implying q9 and q10 fed the artefact. Measured,
   `gen_g3.py` loads only `q1,q2,q3,q3b,q4,q5,q6,q7,q8,b3` — **q9 and q10 are never loaded by the
   generator** (the range string is the only place they appear). The range citation is misleading.
4. **Location-cited evidence, opened and checked (standing rule: open any evidence cited by line).**
   The prior programme's CD-23 (`docs/stage2/S2-REVIEW-03-independent-audit.md:216`) cites
   "`g1-b3b-20261029.json:149, 155, 159, 165`" as the location of captured `prosrc` bodies. I opened
   those exact lines (VERIFIED): **149** and **155** are genuine `"body"` fields
   (`private.request_device_recovery`, `public.request_device_recovery`); **159** and **165** are the
   `"function_name"` fields of `request_remote_session` and `unlink_child`, whose bodies actually sit at
   **161** and **167**. So the substantive claim (bodies exist in `g1-b3b`) is correct and all 14 bodies
   are present, but two of the four line anchors point one/two lines above the body they name. This is
   flagged as a citation-precision item; note `S2-REVIEW-03` is **outside** my four-file Task-4 scope
   (90/91/92 + exec-03), so it is recorded for accountability, not folded into the §4 unresolved count.

## 5. Task 5 — Hash reconciliation

- `95-secret-scan.md` "Files scanned: **13**" — all 13 are g3-build artefacts
  (10 components + assembled `.sql` + `92` + `94`). **Of the 17 evidence files, 0 were covered by the
  prior secret scan** (VERIFIED: none of the 17 appear in its scanned-file table; the scan itself
  states it "covered the artefact, **not** the Stage 1 evidence files"). Scope stated as files-scanned
  over files-present: **13 of 22** g3-build artefact files scanned; **0 of 17** evidence files scanned.
- **Scan pattern basis (measured, this pass).** Counting the keys of `PATTERNS` in `scan_phase34.py`
  gives **19 total = 16 credential-shaped + 3 row-data/PII** (`email-address`, `coordinate-pair`,
  `uuid-literal`). `95-secret-scan.md` "Method … **19 patterns**" is accurate. But `S2-EXEC-03` §4
  words it as "**19 credential-shaped** patterns … **plus 3** PII classes," which implies 22 patterns
  and double-counts the 3 row-data classes that are already inside the 19. The correct statement is
  16 credential + 3 row-data = 19. This is a phrasing/arithmetic error in the report, not in the scan.
- **The "53" figure is propagated, not measured.** It is not reproducible by `find` from the stated
  path (which yields 17); it does not correspond to any single directory here. The only arithmetic that
  produces 53 from files present is `docs/stage2/` (36) **+** `docs/stage1/evidence/` (17) (INFERRED,
  an accidental sum). Treat 53 as a carried-forward unverified count, not a discovery.
- `100-file-hashes.txt` length is **20 hash entries** (VERIFIED: `wc -l` → `20`), not "22" as the
  tasking states. The g3-build directory holds **22 files** (`ls` minus `100-file-hashes.txt` itself =
  21, +1 self = 22); the hash list omits itself and omits `gen_scan.py` (grep → 0). **0 of the 20
  hash entries are evidence files** (grep of `g1-|schema-columns|functions-and-triggers|g2-apk|capture`
  → `0`).
- Evidence-file SHA-256 recorded anywhere in the repo? **0 of 17.** The five evidence digests spot-
  searched in `docs/` (schema-columns, functions-and-triggers, edge capture, q9, q10) all returned
  "none in docs/". The only `sha256` values inside the evidence directory are the 9 **Edge-bundle-text**
  hashes in `capture-20261030.json` and the APK/cert digests in `g2-apk-identity` — hashes of *other*
  artefacts, not of the evidence files themselves.
- **Net:** previously hash-recorded evidence files = **0 / 17**; not previously recorded = **17 / 17**.
  §1 of this document establishes fresh SHA-256 baselines for all 17. Spot-check: the artefact digests
  I recompute in §1's method match those in `100-file-hashes.txt` (e.g. `95-secret-scan.md` recomputes
  to `46b709443cbe…` = the listed value), which validates that my `sha256sum`/`wc` method matches theirs.

### 5.1 Supplementary measured sanitisation sweep of the evidence directory (this pass, values not printed)

Because the prior secret scan never covered the directory, I ran the scan's own credential-shaped and
PII patterns over the 17 evidence files (read-only `grep -E`), reporting **only match counts and
locations**:

- JWT (`eyJ…` ≥8 chars), Supabase key (`sb[ru]_…`), `postgres(ql)://…:…@`, service-account JSON,
  `-----BEGIN …PRIVATE KEY-----`: **0 matches** across all 17 files.
- Email-shaped (`user@host.tld`): **0 matches** in `docs/stage1/evidence/`.
- Operator name/email (per the standing PII flag): **NOT located in `docs/stage1/evidence/`** (VERIFIED
  by the 0-email result). It **is** present in **Stage 2** evidence — cited by location only, not
  reproduced: `docs/stage2/evidence/S2-INSP-02-firebase-console.md:17` (account name + email), and the
  same operator email is embedded in org labels at `S2-CREATE-01-new-projects.md:51,60,85,121` and
  `S2-INSP-01-supabase-org-slots.md:31,32,33,34,54`. `S2-EXEC-03 §7` already discloses this
  (naming `S2-INSP-02`). Redaction is an owner decision, out of this auditor's domain.
- Identifier-shaped (not secrets, recorded for completeness): APK/certificate SHA-256 + SHA-1 in
  `g2-apk-identity` (self-declared public identifiers), 9 Edge-bundle SHA-256 in `capture-20261030.json`,
  and project-ref strings inside capture metadata. This sweep is a **discovery aid, not a substitute**
  for a full secret scan; it does not prove absence of a non-matching secret.

## 6. Task 6 — Coverage impact assessment

Cross-checked against every `MISSING`/`UNKNOWN` row in `91-coverage.md`.

| Coverage row (from `91-coverage.md`) | Its "Source" claim | Newly-discovered / unused evidence that touches it | Resolvable offline? | Confidence |
| --- | --- | --- | --- | --- |
| **Function return types = 38 MISSING** ("no G1 query selects one") | no G1 query | **`functions-and-triggers.md §1` lists return types for the 14 public functions** (jsonb / integer / row-type). The claim "*no G1 query* selects one" stays literally true (it is a pre-G1 dashboard note, not a Q query), but the value **is present in the evidence directory** the artefact never consulted. | **PARTIAL — up to 14 of 38**, dashboard-grade | **MEDIUM** — secondary (dashboard) source, self-labelled `INFERRED FROM DASHBOARD`; needs the raw `prorettype` to be `VERIFIED`. Executability judgement is referred to the SQL-structure auditors, not asserted here. |
| Functions (inventory) = 38, 0 executable | `g1-b3b` | q10 duplicates the 14 public; adds nothing new | No | — |
| 24 `private` bodies absent | run-manifest amend. 3 | no file supplies them | No | — |
| Triggers (7 + 1) | `g1-q3`/`g1-q3b` | definitions already captured; blocked only on functions | n/a (blocked-on-40) | — |
| RLS policies = 21 | `g1-q2` | q9 names 14 policies as a cross-check; no new definitions | No | — |
| Realtime publication = 4 | documentation | no evidence file | No | — |
| Extensions / views / sequences / comments = UNKNOWN | blind spots | none of the 17 files query `pg_extension`/relkind≠r/sequences | No | — |
| Tables/Columns/Constraints/Indexes/Grants = complete | q1/q4/q5/q6/q8 | `schema-columns.md` is **redundant** with the consumed q8 | No change | — |
| *(Edge lane, not in `91`)* `BLOCKED — EDGE SOURCE REQUIRED` in 00/02/README | edge lane | `capture-20261030.json` = inventory + 9 bundle hashes; **7/9 bundles minified**, `_shared/*.ts` unreadable | **No** — does not supply the readable source the fixes need | — |
| Staging emptiness / FX-18 | `05 §2`, `90 L-8` | q9/q10 hold no row counts; the `1,773`/`39`/`8` counts are **production** | **No contradiction** (separate project) | — |

**Honest overall answer: the change is narrow but not zero.**

- **No material change** to 16 of the 17 coverage rows, and **no change to the Edge `BLOCKED` status**,
  and **no contradiction of any staging-empty baseline** (there are no per-table row counts in q9/q10).
- **One material new finding** for the record: **`functions-and-triggers.md` was present, unused, and
  carries return types for the 14 public functions.** The reconstruction's root blocker is
  "38 functions, 0 emittable — no return type exists in the evidence." Measured, a return type exists
  in the evidence directory for **14** of them. That means the blocker is **over-stated as "38"**: at
  most **14** public functions have a documented (dashboard-grade) return type, leaving **24** private
  return types genuinely missing.
- **For the 24 absent function bodies:** unchanged — no evidence file contains them. A5 D-06
  (`prosrc` hash validation) stays impossible for those 24 (nothing to hash).
- **For the 38 missing return types:** reduced in the honest worst case to **24 truly missing**; 14 are
  recoverable from `functions-and-triggers.md` at medium (secondary-source) confidence. This does **not**
  by itself make the artefact load-ready — a public function still needs signature + body (both in
  `g1-b3b`) **plus** a return type (now available) assembled into DDL, which is a SQL-structure decision
  deferred to the SQL auditors, and the dashboard return type would still need verification against a
  catalogue value that the staging-only absolute forbids fetching for production.

**Bottom line:** the reconstruction correctly used the 10 catalogue files it consumed; but it declared
"no return type exists in the evidence" while an uncited sibling file in the *same directory* supplies
14 of them. That is an accountability gap (unused evidence + an over-stated blocker), not a data loss
for anything else.

## 7. Classification register for the headline claims

| Statement | Class |
| --- | --- |
| Evidence directory holds 17 files; `pairing/` is empty | **VERIFIED** (`find \| wc -l`) |
| q9 = advisor findings, 33 rows; q10 = RPC inventory, 14 rows; combined 47 | **VERIFIED** (`json.load` enumeration) |
| q9/q10 hold per-table row counts or an Edge Function inventory | **FALSE / NOT PRESENT IN EVIDENCE** |
| q9 unused by artefact; q10 loaded-but-unused by reviewer, unused by generator | **VERIFIED** (`grep 'J("'`) |
| `schema-columns.md` & `functions-and-triggers.md` exist and all citations resolve | **VERIFIED** (`find`/`grep`) |
| `functions-and-triggers.md §1` supplies return types for 14 public functions; artefact never consulted it | **VERIFIED** (read + `grep`/provenance tally) |
| Dashboard return types are authoritative | **INFERRED / UNVERIFIED** (secondary source; needs raw `prorettype`) |
| Row-count figures (1,773 etc.) are production, not staging | **VERIFIED** (`grep` context) |
| `BLOCKED — EDGE SOURCE REQUIRED` is in 00/02/README, not 05 | **VERIFIED** (`grep`) |
| Edge capture does not unblock the Edge-source status (7/9 minified) | **INFERRED** from measured file contents |
| `95-secret-scan` covered 0 of 17 evidence files; `100-file-hashes.txt` = 20 entries, 0 evidence | **VERIFIED** (`wc -l`, `grep -c`) |
| 0 credential-shaped / 0 email values in `docs/stage1/evidence/` | **VERIFIED** (this pass `grep`) |
| Operator name/email in Stage 2 evidence (locations cited, not reproduced) | **VERIFIED** (`grep`, masked) |
| exec-03 "see §4.1" reference | **UNVERIFIED — does not resolve** (no §4.1) |
| exec-03 "introspected before use" for q9/q10/the two `.md` | **UNVERIFIED / over-stated** (files unused) |
| The "56 rows" and "53 files" and "22-file hash list" figures | **UNVERIFIED — not reproducible** (measured 47 / 17 / 20) |
