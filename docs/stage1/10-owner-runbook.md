# 10 — Owner runbook: G1 queries, evidence return, G2 package verification

Status: **`EXECUTED 2026-10-29` — G1 answered; B3b executed 2026-10-30.** Q1–Q8, Q3b and Q10 ran in the project's SQL Editor, one per
`begin transaction read only; … commit;` wrapper with `transaction_read_only = on` confirmed first; Q9 was read from the
dashboard advisor; B3b read the function and trigger bodies the G1 query set deliberately excluded. Evidence:
`docs/stage1/evidence/g1-q1…q10-20261029.json`, `g1-b3b-20261029.json` and `g1-run-manifest-20261029.md`. No statement
failed and no DDL/DML was issued. The procedure below is retained for re-runs.

Related: [08-test-matrix.md](08-test-matrix.md) §0 (query text), [09-access-and-audit-plan.md](09-access-and-audit-plan.md)
§2–§5 (access options and risks), [firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) (what happens *after*
G2 is decided).

## 1. Before you start

- Confirm the project selector reads `parent-control-prod` (`hhqgreaoqulmfwfwarhc`). Results from the wrong project are
  worse than no results.
- Open **SQL Editor**. No access token, database password, service-role key or browser credential is needed for any step.
- If the project is paused (Free plan), resume it first. That is a hosting action, not a configuration change.
- **Q1–Q10 read catalogue metadata only.** None of them returns rows from `profiles`, `devices`, `location_events` or any
  other table. If a result ever contains something that looks like a person's data, stop and do not share it.
- Run **one query per run**, inside the read-only wrapper below. Do not paste the whole document at once.

## 2. Per-query procedure

1. Run `show server_version;` once on its own and note the value in the return message. It is read-only, takes a second,
   and records which Postgres version the evidence came from.
2. Paste the template below, then replace the comment with exactly one query block from
   [08-test-matrix.md](08-test-matrix.md) §0:

```sql
begin transaction read only;
set local statement_timeout = '15s';
show transaction_read_only;   -- expect exactly: on
-- one Qn block here
commit;
```

3. Run it. The **first** result grid must show `on`. If it shows `off`, the wrapper did not take effect — stop and report
   that, do not continue with the query.
4. If the editor warns that a transaction is already in progress, it has wrapped the script itself. Run the bare `SELECT`
   with no wrapper **and no `COMMIT`**, note the warning in the return message, and mark that query's read-only
   enforcement as **not proven**. Never paste `COMMIT` into a session whose transaction state you did not open.
5. The **last** result grid holds one cell of JSON (a `json_agg` array or a `json_build_object`). Copy the cell contents,
   not the grid.
6. If the grid truncates, use the editor's download/export control and take the value from that file.
7. Save the raw JSON unchanged as `docs/stage1/evidence/g1-<qn>-20261029.json`. Do not reformat it.
8. Sanitise before sharing: these queries should contain no emails, coordinates, phone numbers or identifiers. Scan for
   any long random string that looks like a key or token; if one appears, stop and report its location, not its value.

## 3. Order, and what each step settles

Q10 is first because it is the only query that can turn the highest-severity open question into a fact.

| Step | Query | Settles | Time |
| --- | --- | --- | --- |
| 1 | **Q10** | Whether `anon` / `authenticated` / `service_role` can execute every function in `public` (the 14 app definer functions plus any extension function); `search_path`; owner; extension-owned; schema usage | 1 min |
| 2 | **Q1** | RLS and forced-RLS flags per table, table owner, table ACL — the observed state (run gave 19/19 enabled, none forced) | 1 min |
| 3 | **Q2** | Every policy's `qual`, `with_check`, permissive mode and roles — the missing half of the RLS matrix | 1 min |
| 4 | **Q7** | Function security flags and pinned settings (no bodies; `prosrc` is deliberately excluded) | 1 min |
| 5 | **Q6** | Table and column grants, default ACLs, role memberships | 1 min |
| 6 | **Q5** | Foreign keys, delete rules, unique and check constraints | 1 min |
| 7 | **Q3** | Trigger definitions on `public` tables, including `profiles_before_update` | 1 min |
| 7b | **Q3b** | Triggers on `auth.users` — the signup path. An empty array is itself a finding, not a failed query | 1 min |
| 8 | **Q4** | Indexes, including the uniqueness behind idempotency and pairing-code replay protection | 1 min |
| 9 | **Q8** | Column names, types, defaults and nullability as stored | 1 min |
| 10 | **Q9** | The advisor findings (UI groups them as 1 warning + 4 suggestions; `run-lints` returns 5 rules / 33 rows, 2 WARN): Dashboard → Advisors → Security Advisors, copied by hand as title + description | 2 min |

Stop after step 1 if Q10 shows `anon_exec = true` on any app-owned function (`extension_owned = false`), or
`auth_exec = true` on any of the five actor-less functions: `poll_device_commands`, `replace_device_apps`,
`expire_stale_commands`, `detect_offline_devices`, `expire_stale_sessions`. Report either result immediately and do not run
steps 2–10; the recovery decision comes before more work. `extension_owned = true` rows are reported separately as a
platform/extension observation, never as an app-owned finding and never dropped. `service_exec = true` is expected for
Edge Functions and is not a stop condition. No `REVOKE` or other change is applied or authorised by this runbook;
containment is a **PROPOSED — NOT APPLIED** action requiring separate owner approval.

## 4. G1 closure checklist

This checklist was used for the 2026-10-29 run. The run satisfied it and the results were independently reviewed, so G1 is
closed; the unticked boxes are retained as a re-run procedure, not as open work.

- [ ] Q10 returned; `anon_exec` is false for every app-owned (`extension_owned = false`) function
- [ ] Q10 returned; `auth_exec` is false for the five actor-less functions
- [ ] Q10 extension-owned rows recorded separately, not folded into the app-owned finding
- [ ] Q1 returned; `rls_enabled` is true for all 19 tables
- [ ] Q2 returned; 21 policies present, counted by command: SELECT 15, INSERT 2, UPDATE 3, DELETE 1
  - [ ] SELECT: `qual` non-null on every PERMISSIVE policy and family/participant-scoped; `with_check` NULL by design
  - [ ] INSERT: `with_check` non-null and scoped; `qual` NULL by design, not a defect
  - [ ] UPDATE: `qual` non-null on every PERMISSIVE policy; `with_check` recorded as stored — NULL means `USING` is
        reused, so confirm `qual` blocks moving a row to another family
  - [ ] DELETE: `qual` non-null on every PERMISSIVE policy; `with_check` NULL by design
  - [ ] ALL: none exists; if one appears, review `qual` and `with_check` per command
- [ ] Q7 returned; every definer function has a pinned `search_path`
- [ ] Q6 returned; no unexpected `anon` table privileges
- [ ] Q5 returned; every family-scoped table has a path to `families`
- [ ] Q3 returned; `profiles_before_update` body retrieved separately and read
- [ ] Q3b returned; every `auth.users` trigger listed with its function — an empty array means no signup trigger exists
- [ ] Q4 returned; unique index exists on the pairing-code and idempotency columns
- [ ] Q8 returned
- [ ] Q9 advisor text captured

## 5. Evidence return format

| Field | Value |
| --- | --- |
| Files | `docs/stage1/evidence/g1-q1-20261029.json` … `g1-q10-20261029.json`, plus `g1-q3b-20261029.json` and `g1-b3b-20261029.json` |
| Project ref | `hhqgreaoqulmfwfwarhc` — state it in the return message |
| Operation | read-only catalogue `SELECT`; no DDL, DML, role change or config change |
| Timestamp | when the batch was run |
| Exceptions | any query that failed, and the exact error text (error text contains no secrets here) |
| Advisor text | pasted separately, title + description only |

Raw output stays unedited. Interpretation happens in the reports, after the independent review, so a finding is never
mixed into the evidence file.

## 6. G2 — verify the Android `applicationId` without creating anything

The Android `applicationId` is **VERIFIED** as `com.haven.familysafety` from `Haven-1.1-release.apk` and
`Haven-1.2-release.apk` (2026-10-30); `Haven-1.0.apk` has the same package but a different signing key and Capacitor
config. Firebase ties an Android app to the package name, and the package half is now closed. The procedure below remains
useful for re-verifying a new build; nothing in this section touches Firebase.

| Method | How | Weight |
| --- | --- | --- |
| A. Source tree | In the child-app repository, read `applicationId` in `android/app/build.gradle` (or `.kts`), and the `package` attribute in `AndroidManifest.xml` | Good, but the manifest can differ after merging |
| B. Built artifact (authoritative) | On the exact release APK: `aapt2 dump badging <file>.apk \| head -1` — the `package: name='…'` value is what ships. For an `.aab`: `bundletool dump manifest --bundle <file>.aab --module base` | Highest — this is the shipped identity |
| C. Play Console | If the app is published: Play Console → app → Test and release → App bundle explorer → package name | High, if the owner has console access |
| D. Signing certificate | `apksigner verify --print-certs <file>.apk` — record the SHA-256 | Needed later for FCM/App Check, not for the package itself |

Record four values and stop: package name, version code, certificate SHA-256, artifact path. If A and B disagree, B wins
and the disagreement itself is the finding. This was completed on 2026-10-30 and recorded in
[firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) §0a plus
`docs/stage1/evidence/g2-apk-identity-20261030.md`. The project-creation half stays blocked until you approve a dedicated
project and decide on the name in [firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) §0.

## 7. Production protections in force for this runbook

Not to be run against `parent-control-prod` at any point in Stage 1:

- `supabase db push`, `supabase migration up`, `supabase db reset`, `db reset --linked`
- any DDL in the SQL Editor: `CREATE`, `ALTER`, `DROP`, `GRANT`, `REVOKE`, `CREATE OR REPLACE`
- any `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`
- creating test users, families, devices, pairing codes or telemetry rows
- changing table exposure, Realtime settings, auth settings, Edge Functions or secrets

The only permitted write anywhere in Stage 1 is the metadata row written by `migration repair` after G3 approval, and it
does not touch user data.

## 8. After the results arrive

1. File the JSON unchanged under `docs/stage1/evidence/`.
2. Independent review of the raw results (role 14) before any verdict is written.
3. Reconcile [04-rls-matrix.md](04-rls-matrix.md), [03-data-model.md](03-data-model.md) and
   [00-status-register.md](00-status-register.md) against the observed facts; divergences are recorded, not smoothed over.
4. Escalate any Critical/High finding immediately; Stage 1 cannot pass while one is open.
5. Only then propose implementation changes, each behind its own approval.
