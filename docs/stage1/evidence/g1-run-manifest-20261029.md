# G1 evidence manifest — 2026-10-29

| Field | Value |
| --- | --- |
| Project | `parent-control-prod` |
| Ref | `hhqgreaoqulmfwfwarhc` |
| Region | `ap-northeast-2` |
| Server | PostgreSQL 17.11 (`select current_setting('server_version')`) |
| Method | Supabase Dashboard → SQL Editor; one statement batch per transaction, wrapped `begin transaction read only; set local statement_timeout = '15s'; … commit;` |
| Read-only proof | `select current_setting('transaction_read_only')` executed inside the same wrapper returned `on` before any catalogue query |
| Operations | `SELECT` over `pg_*` / `information_schema`; linter read from the Advisor page. No DDL, DML, `set role`, grant, revoke, policy, function, trigger or setting change |
| Captured | 2026-10-29, 18:37–19:19 IST |
| Exceptions | none — every statement returned rows without error |
| Sanitisation | files scanned for email addresses, JWTs, connection strings, key/token literals, UUID literals and coordinate literals: none present. Catalogue metadata only; no user rows were read |

## Files

| File | Query | Content |
| --- | --- | --- |
| `g1-q1-20261029.json` | Q1 | 19 rows: table, `rls_enabled`, `rls_forced`, owner, `table_acl` |
| `g1-q2-20261029.json` | Q2 | 21 rows: table, policy, permissive, cmd, roles, `qual`, `with_check` |
| `g1-q3-20261029.json` | Q3 | 7 rows: `public` triggers with definition, function, definer flag, enabled flag |
| `g1-q3b-20261029.json` | Q3b | 1 row: `auth.users` trigger `on_auth_user_created` |
| `g1-q4-20261029.json` | Q4 | 62 rows: indexes and definitions |
| `g1-q5-20261029.json` | Q5 | 137 rows: constraints with definitions, referenced table, delete rule, validity |
| `g1-q6-20261029.json` | Q6 | table grants (149), UPDATE column grants (191), default ACLs (24), role memberships (24) |
| `g1-q7-20261029.json` | Q7 | 18 rows: `public`+`auth` functions, definer flag, volatility, settings, ACL, owner |
| `g1-q8-20261029.json` | Q8 | 183 rows: columns with type, ordinal, nullability, default |
| `g1-q9-20261029.json` | Q9 | 5 lint rules / 33 rows from the Advisor page's own linter response |
| `g1-q10-20261029.json` | Q10 | `schema_usage` plus 14 app functions with `anon_exec` / `auth_exec` / `service_exec` / `extension_owned` / ACL |
| `g1-b3b-20261029.json` | B3b (2026-10-30) | 38-row function inventory with `schema_name` per row, 14 function bodies, `auth.users`-adjacent trigger map, `schema_usage` on `private`, `authenticator` role config, and the Data API exposure values read from the settings page |

## B3b follow-up — 2026-10-30

| Field | Value |
| --- | --- |
| Scope | the five functions named in the follow-up plus every trigger body; the query also returned the rest of the schema, which is recorded rather than discarded |
| Method | same read-only wrapper as G1, three statements, `statement_timeout = '20s'` |
| Read-only proof | `transaction_read_only` = `on` inside all three results |
| Operations | `SELECT` over `pg_proc`, `pg_namespace`, `pg_roles`, `pg_db_role_setting`, `pg_trigger`; one read of the project's Data API settings page. No Save pressed; the page's Save button was disabled throughout |
| Rows read | none. `prosrc` is function source, not data |
| Result that changes prior text | the `private` schema holds **24** functions, not the five named in the follow-up. The 14 RPC functions in `public` have near-identical twins in `private`, and two `private` objects (`request_device_recovery`, `remote_session_transition_guard`) still carry the default `PUBLIC EXECUTE` |

## Capture notes

- Each file holds the value the editor returned for that query, stored as the JSON the dashboard produced for export. Formatting was not edited; nothing was added to the files. Provenance lives here, not inside them.
- Q1/Q2/Q7/Q9 additionally differ from a raw `json_agg` wrapper because the dashboard's export flattens the single result column. The content is unchanged.
- Q9 could not be copied from the rendered list: the findings table is virtualised and renders no rows without a visible viewport. The data was taken from the same origin the page displays — the project's `run-lints` response — and its findings were parsed into object identifiers. Verbatim prose remains retrievable in the dashboard by pressing Refresh.
- The advisor UI reports "1 warning, 4 suggestions" while `run-lints` returns 5 rules (2 at WARN level). Both are recorded rather than reconciled.

## Amendment — 2026-10-30 (annotations only; no raw file was edited)

This section corrects the manifest's own descriptions. The JSON files and their provenance rows above are unchanged.

1. **`g1-b3b-20261029.json` was captured on 2026-10-30, not 2026-10-29.** The `20261029` suffix was kept because the
   file belongs to the G1 evidence series and every report already links to that name; the authoritative date is inside
   the file (`capture.captured`) and in the B3b section above. Renaming raw evidence after publication would break the
   links and the audit trail, so the filename stands and this note records the mismatch.
2. **The Files table lists JSON only.** Two dashboard-derived notes are also part of this evidence set and are cited by
   the reports: `schema-columns.md` (columns, types and rendered constraint flags, second pass 2026-10-29) and
   `functions-and-triggers.md` (14 functions and 7 triggers, 2026-10-29). They are narrative transcriptions, not raw
   exports, and are labelled as such in their own headers. `g2-apk-identity-20261030.md` belongs to G2, not G1, and is
   listed here only so a reader of the evidence directory can tell the two apart.
3. **The B3b inventory has no `proowner` column.** Ownership is therefore **not selected** for the 24 `private`
   functions. The `postgres` owner shown in reports is inferred from the grantor in every ACL string
   (`…/postgres`) and from `g1-q7`, which covers `public` and `auth` only. Treat private-schema ownership as
   INFERRED, not VERIFIED, until a query selects `proowner`.
4. **`remote_session_triggers` in the B3b file is not the `auth.users` trigger map.** It holds the one trigger on
   `public.remote_sessions`. The `auth.users` trigger is in `g1-q3b-20261029.json`, and it is the only user-defined
   trigger on that table.
5. **Q9 counts re-checked:** 5 rules, 33 occurrences, WARN 15 (1 + 14) and INFO 18 (4 + 12 + 2). The manuscript's
   "1 warning + 4 suggestions" is the UI grouping, not a row count.
