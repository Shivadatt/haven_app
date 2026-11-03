# 00 — Status register

Last updated 2026-10-30 (G1 executed read-only on 2026-10-29; B3b follow-up read-only pass on 2026-10-30; Phase A reconciliation same day; Phase E Edge Function source audit same day). One label per item: **PASS — VERIFIED**, **PARTIAL**, **FAIL**, **BLOCKED — ACCESS OR APPROVAL REQUIRED**, **NOT TESTED**, **NOT APPLICABLE**.

**Stage 1 overall: `BLOCKED — ACCESS OR APPROVAL REQUIRED`** — G1 and B3b are answered, and Phase E answered the Edge Function source question at the Edge tier. G2 (Firebase project), G3 (baseline migration), G5 (test identities) and G6 (non-production environment) remain open; G4 (Data API exposure) awaits a confirmation of the no-change recommendation and G7 (secret placement) applies only at FCM wiring. B7–B9 below are open blocked items, not missing work.

## G1 execution record

| Field | Value |
| --- | --- |
| Project | `parent-control-prod` / `hhqgreaoqulmfwfwarhc` (verified in the page header and URL before the first statement) |
| Server | PostgreSQL **17.11** |
| Method | Dashboard SQL Editor, one query per `begin transaction read only; … commit;` wrapper |
| Read-only proof | `show transaction_read_only` returned **`on`** inside the wrapper before any catalogue query ran |
| Queries executed | Q1, Q2, Q3, Q3b, Q4, Q5, Q6, Q7, Q8, Q10, plus a `server_version` probe; Q9 read from the dashboard Safety Advisor (its own `run-lints` response) |
| Failures | none — no statement errored |
| DDL/DML | none |
| Evidence | `evidence/g1-q1…q10-20261029.json`, `evidence/g1-run-manifest-20261029.md` |

## B3b execution record (2026-10-30)

| Field | Value |
| --- | --- |
| Scope | the five functions named in the follow-up, every trigger body, and — because the query surfaced them — the whole `private` schema |
| Method | same read-only wrapper, `statement_timeout = '20s'`, three statements; one read of the Data API settings page |
| Read-only proof | `transaction_read_only` = **`on`** in all three results |
| Rows read | **none** — `prosrc` is source text, not table data |
| Evidence | `evidence/g1-b3b-20261029.json` |
| Effect on the register | P4, P12, P13, P14, P17, P19 tightened; P20 added; PA2 narrowed to N5 (live probe still not run); PA3 re-scoped to 11 unread `private` twin implementations (24 unread bodies in total); **F7 rewritten, F8 added**; B3b closed |

## Phase E execution record (2026-10-30)

| Field | Value |
| --- | --- |
| Scope | all 9 deployed Edge Functions (`pairing`, `auth-bootstrap`, `device-command`, `device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`) and all 6 shared modules (`auth.ts`, `audit.ts`, `cors.ts`, `envelope.ts`, `rate_limit.ts`, `validation.ts`) |
| Method | dashboard Edge Function editor; source read from the Monaco model in the page and hashed with `crypto.subtle`; no download, no clipboard, no network request to any function |
| Read-only proof | no request was sent to any endpoint; no deploy, save, secret view or config change; no cookie, session token or credential was read |
| Artifact | [evidence/edge-functions/capture-20261030.json](evidence/edge-functions/capture-20261030.json) — per-artifact length, line count, SHA-256 and evidence anchors |
| Documents | [13](13-edge-function-source-inventory.md) inventory, [14](14-edge-function-security-audit.md) audit, [15](15-edge-function-test-plan.md) test plan, [16](16-phase-e-findings.md) findings |
| Effect on the register | **PA1 closed at the Edge tier**; F7's Edge half resolved (actor always bound to the verified JWT); F7's SQL half and F8 unchanged and still open; E1–E14 added, none applied |

## PASS — VERIFIED

| # | Item | Evidence |
| --- | --- | --- |
| P1 | Correct project identified: `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, ap-northeast-2, Free/NANO | [01](01-baseline-inventory.md) §1 |
| P2 | 19 tables in `public`; **183 columns**, types, defaults and nullability as stored | [g1-q8](evidence/g1-q8-20261029.json) |
| P3 | 21 policies across 15 tables: 15 SELECT / 3 UPDATE / 2 INSERT / 1 DELETE, all **PERMISSIVE**, all role `authenticated` | [g1-q2](evidence/g1-q2-20261029.json) |
| P4 | **38 functions, not 14.** `public` holds the 14 RPC wrappers, all `SECURITY DEFINER`, owner `postgres`, all with a pinned `search_path`; `private` holds **24** — 13 twins of those wrappers, plus `record_audit` and 10 helpers/trigger functions. All 38 pin a `search_path`; two pin `public, pg_temp` and omit `private` (F5, F8). Plus 4 `auth` helper functions that are not definer | [g1-q7](evidence/g1-q7-20261029.json), [g1-q10](evidence/g1-q10-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P5 | 7 triggers on `public` tables, all enabled | [g1-q3](evidence/g1-q3-20261029.json) |
| P6 | Auth configuration: email-only, signups on, confirm-email on, anonymous off, JWT 1 h, refresh rotation on, reuse interval 10 s | [01](01-baseline-inventory.md) §4, [functions-and-triggers.md](evidence/functions-and-triggers.md) §4 |
| P7 | No storage buckets exist | [functions-and-triggers.md](evidence/functions-and-triggers.md) §4 |
| P8 | No secrets in the working tree or in any evidence file; `.gitignore` blocks `.env`, keys and client config | local scan; `g1-*.json` scanned for emails, JWTs, connection strings, UUIDs and coordinate literals — none present |
| P9 | No live schema, policy, grant, function, trigger or config change was made during Stage 1 | read-only transactions only; no console write action taken |
| P10 | **RLS enabled on all 19 tables**, owner `postgres` on every table. `relforcerowsecurity` is false everywhere: RLS constrains clients, not the table owner, so every `SECURITY DEFINER` function bypasses the policies by design | [g1-q1](evidence/g1-q1-20261029.json) |
| P11 | **`anon` holds no table privilege in `public`** — zero rows in `role_table_grants` | [g1-q6](evidence/g1-q6-20261029.json) |
| P12 | **No `public` function is executable by `anon` or `authenticated`**: `has_function_privilege` is false for both on all 14, and each `proacl` is exactly `postgres=X,service_role=X`. Client roles therefore cannot call them over `/rest/v1/rpc/*`. The `private` schema is the exception and is graded separately (P20, F8): four of its 24 functions grant `authenticated` explicitly, and two more carry the default `PUBLIC EXECUTE` | [g1-q10](evidence/g1-q10-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P13 | Every policy expression genuinely scopes: family membership via `private.is_family_parent` / `is_family_member` / `shares_active_family`, or the caller's own `auth.uid()`. **Bodies now read**: each helper anchors on `auth.uid()`, requires `status = 'active'` and `families.deleted_at is null`, and `shares_active_family` pins the caller's own membership to `auth.uid()` — so it answers "do I share a family with X" and cannot enumerate other families | [g1-q2](evidence/g1-q2-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P14 | `auth.users` carries exactly one user-defined trigger, `on_auth_user_created` → `private.handle_new_user()`, `SECURITY DEFINER`, pinned `search_path`, enabled. **Body read**: inserts `profiles(id, role, display_name)` with `role` hard-coded to `'unset'`, `on conflict (id) do nothing`; the client cannot influence the role through signup metadata | [g1-q3b](evidence/g1-q3b-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P15 | Idempotency and replay protection exist in the schema: unique `device_commands (device_id, idempotency_key)`, unique `device_pairing_tokens (code_hash)`, unique `pairing_requests (token_id)` | [g1-q4](evidence/g1-q4-20261029.json) |
| P16 | 137 constraints, all validated; 44 foreign keys, every family-scoped table has a path to `families`; delete rules are only `CASCADE` and `SET NULL` | [g1-q5](evidence/g1-q5-20261029.json) |
| P17 | `profiles.role` cannot be self-escalated by a client: `authenticated` holds column-level UPDATE on `profiles.display_name` **only**, and `profiles_before_update` independently rejects an `id` change and a `role` change. The trigger's rule is `old.role <> 'unset'` — so for a profile still in `'unset'` the trigger does **not** block a role write and the column grant is the only control (F3) | [g1-q6](evidence/g1-q6-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P18 | The four deny-all tables (`child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states`) are RLS-enabled with zero policies, so a client reads nothing | [g1-q1](evidence/g1-q1-20261029.json), [g1-q9](evidence/g1-q9-20261029.json) |
| P19 | The 4 Realtime tables carry scoping SELECT policies, and `private.realtime_topic_allowed` — the topic authoriser — routes `safety-alerts` / `remote-session-family` to `is_family_member` and `remote-session` / `webrtc-signals` to `child_user_id = auth.uid() OR is_family_parent(family_id)`, rejecting any topic that is not `kind:uuid`. Realtime membership itself comes from the dashboard baseline, so the policy and the authoriser are verified, the subscription path is not exercised | [g1-q2](evidence/g1-q2-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) |
| P20 | **The Data API is exposed on `public` + `extensions` only, with 0 of 19 tables and 0 of 38 functions exposed** and "Automatically expose new tables" off. `private` is offered but **not** selected, and `anon` holds no `USAGE` on it, so nothing in `private` is reachable through PostgREST today | [g1-b3b](evidence/g1-b3b-20261029.json) §`data_api_exposure` |

## PARTIAL

| # | Item | What is missing |
| --- | --- | --- |
| PA1 | Edge Function security review | **Edge tier closed by Phase E, SQL tier still open.** All 9 functions and all 6 shared modules were read on 2026-10-30 ([13](13-edge-function-source-inventory.md), [14](14-edge-function-security-audit.md)). Every one of the nine creates a service-role client, so RLS never applies inside a function and all authorization is application code; per-endpoint auth, family scoping and actor binding were verified at the Edge tier. What remains unproven is the SQL tier those functions call: 24 function bodies are still unread (PA3), and the wrappers they invoke trust caller-supplied actor ids (F7/E3) |
| PA2 | Live reachability of the Data API | The exposed-schema list and the 0-of-19 / 0-of-38 counts are read from the settings page (P20), but no request was made to the API. Whether those counts mean "no client can reach the database at all" or "reachable only through the service role" is **not determined**; the live probe is tracked as N5 and needs a non-production project (G6) |
| PA3 | RPC implementations | **11 of the 13** `private` implementations behind the `public` wrappers were not read. Three implementations were read: `private.request_device_recovery`, `private.unlink_child` and `public.request_remote_session` in [g1-b3b](evidence/g1-b3b-20261029.json); the other 11 are unexamined code, not a known defect. The 5 named helpers and all 5 trigger bodies are read and closed |
| PA4 | Advisor count reconciliation | The UI shows 1 warning + 4 suggestions; the underlying `run-lints` output returns **5 distinct rules / 33 rows**, of which 2 rules (15 rows) are WARN-level and 3 rules (18 rows) are INFO. Both numbers are recorded in [g1-q9](evidence/g1-q9-20261029.json); the difference is a UI grouping choice, not a data discrepancy |
| PA5 | Data-model coverage of defaults semantics | Defaults are captured verbatim, but whether each `column_default` is a safe generator (e.g. `gen_random_uuid()`) versus a literal has not been reviewed column by column |

## FAIL

| # | Item | Evidence | Severity |
| --- | --- | --- | --- |
| F1 | **Default privileges leak future objects.** `postgres` in `public` has default ACL `anon=Dxtm, authenticated=Dxtm` for new tables and `supabase_admin` in `public` has `anon=arwdDxtm, authenticated=arwdDxtm` for new tables; both also grant client roles on new functions and sequences. Any object created later by those roles inherits client privileges unless revoked; `TRUNCATE` bypasses RLS. No current table carries these grants, so exposure is prospective | [g1-q6](evidence/g1-q6-20261029.json) `default_acl` | P2 |
| F2 | **Ownership transfer is impossible; the policy is live for everything else.** `authenticated` holds UPDATE on `families.name` and `families.settings` but not `owner_id`, so `families_update_owner` gates real writes while being unable to change the owner: `USING` requires `owner_id = auth.uid() AND deleted_at IS NULL`, `WITH CHECK` requires `owner_id = auth.uid()`, and a column the client cannot set. `families_before_update` adds a second layer — it raises on any `owner_id` change unless the caller is privileged — so the transfer is blocked twice and no transfer feature exists | [g1-q6](evidence/g1-q6-20261029.json), [g1-q2](evidence/g1-q2-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) | P3 |
| F3 | **`profiles_update_self` is column-agnostic.** The policy permits every column of the caller's own row, so safety rests on the column grant (`display_name` only) — and **not** on the trigger: `profiles_before_update` only rejects a `role` change when `old.role <> 'unset'`, so any profile still in `'unset'` (every new account) passes the trigger untouched. A future widened grant would reopen `role` with the trigger providing no second line | [g1-q2](evidence/g1-q2-20261029.json), [g1-q6](evidence/g1-q6-20261029.json), [g1-b3b](evidence/g1-b3b-20261029.json) | P3 |
| F4 | **Leaked password protection disabled** (advisor WARN). Recommendation only — nothing was changed | [g1-q9](evidence/g1-q9-20261029.json) | P2 |
| F5 | **`request_remote_session` search_path omits `private`** while the other 13 `public` definer functions pin `public, private, pg_temp`. Still pinned, so not mutable — an inconsistency, not an injection vector. The only other deviation is `private.remote_session_transition_guard` (F8) | [g1-q7](evidence/g1-q7-20261029.json) | P3 |
| F6 | **Two policies are unreachable by clients.** `devices_select_parent_or_child` matches no grant — `authenticated` has no SELECT on `devices` — and `safe_zones_insert_parent` matches no grant — `authenticated` has no INSERT on `safe_zones`. The policies are correct but dead; those operations must go through Edge Functions. 15 SELECT policies versus 14 tables with a SELECT grant | [g1-q1](evidence/g1-q1-20261029.json), [g1-q2](evidence/g1-q2-20261029.json), [g1-q6](evidence/g1-q6-20261029.json) | P3 |
| F7 | **Actor identity is taken from an argument, not from `auth.uid()`.** Every actor-taking function trusts `p_actor_user_id` / `p_parent_user_id`. In `private.request_device_recovery` the argument only has to be *some* active parent of that device's family, so a parent can act under another parent's identity and the audit row records the forged actor; `public.request_remote_session` does not check the parent at all — it writes the argument straight into `remote_sessions.parent_user_id`. The `public` wrapper is `service_role`-only; the `private` implementation still carries the default `PUBLIC EXECUTE` (F8), but `private` is not an exposed schema, so no client route exists today. The real control is the caller deriving the id from the verified JWT; 11 of the 13 `private` implementations and 12 of the 14 `public` RPC bodies remain unread (PA3), and `private.record_audit` is unread too. **Phase E resolved the Edge half**: all nine functions take the actor from the verified JWT (`db.auth.getUser`) and pass it explicitly — no handler reads an actor or parent id from the request body — so the forged-actor path requires reachability to the SQL layer, not a crafted HTTP body ([14](14-edge-function-security-audit.md) §4). The SQL half is unchanged | [g1-b3b](evidence/g1-b3b-20261029.json) `bodies` | P2 |
| F8 | **Two `private` functions keep the default `PUBLIC EXECUTE`** — `request_device_recovery` and `remote_session_transition_guard` — while every sibling has an explicit ACL. `remote_session_transition_guard` also pins `search_path = public, pg_temp`, omitting `private`. No client route exists today: `private` is not an exposed schema (P20) and `anon` has no `USAGE` on it. The exposure is latent — it becomes live if `private` is ever exposed or `anon`/`authenticated` gains schema `USAGE`. **Phase E found that half the barrier is already gone**: `authenticated` holds `USAGE` on `private` today (P20), so enabling the schema in the Data API would be a single settings change, and `request_device_recovery` would then be callable by any signed-in user with a forged `p_actor_user_id` ([14](14-edge-function-security-audit.md) §4, [16](16-phase-e-findings.md#e2)) | [g1-b3b](evidence/g1-b3b-20261029.json) `inventory` | P3 |

No finding above is an observed exploit. F1 and F8 are prospective/latent; F3 is currently mitigated by the column grant, not by the trigger; F7 depends on code that Stage 1 did not read (the Edge Functions).

## BLOCKED — ACCESS OR APPROVAL REQUIRED

| # | Item | Gate |
| --- | --- | --- |
| B7 | Negative and isolation tests (anonymous read, cross-family read, write paths, pairing replay, role escalation, command idempotency) | G5 + G6 (test identities and a non-prod project); catalogue evidence cannot substitute |
| B8 | Baseline migration capture | G3 (now unblocked; needs owner go-ahead to freeze the schema as code) |
| B9 | Firebase project, Android app registration, FCM credentials and send path | G2 |

**Closed:** B3b — bodies of the five named functions, all five trigger bodies and every `private` helper are read and filed in [g1-b3b](evidence/g1-b3b-20261029.json) (2026-10-30, read-only).

## NOT TESTED

| # | Item | Reason |
| --- | --- | --- |
| N1 | Backup and restore | Free-plan backup capability is not evidenced and no restore has been performed |
| N2 | Cross-family isolation in practice | Requires authenticated test users; catalogue and policy text are consistent with isolation but no request was made |
| N3 | Push delivery to a device | Requires G2 and the Stage 2 child-app integration |
| N4 | Realtime behaviour for the 4 realtime tables | No client exists yet; policies verified, delivery not exercised |
| N5 | Live Data API probe (`/rest/v1/` reachability, RPC by role) | Needs a project where a request is authorised; a probe against production is a live request and was not run. The exposed-schema and exposure counts are UI-read only (P20) |

## NOT APPLICABLE (Stage 1)

| # | Item | Reason |
| --- | --- | --- |
| X1 | Android device compatibility / production readiness | Browser-console access proves nothing about devices; Stage 2 |
| X2 | Parent/child UI, pairing UX, command execution, WebRTC media | Out of Stage 1 scope by the master prompt |
| X3 | Paid-tier cost exposure | No paid service enabled; Spark/Free limits documented only |

## Highest-risk questions — answers

1. **RPC surface on definer functions — ANSWERED, favourable for `public`, with one caveat in `private`.** `schema_usage` is true for `anon` and `authenticated` on `public`, but `has_function_privilege` returns `anon_exec = false` and `auth_exec = false` for **all 14** `public` functions; `proacl` is non-null (`postgres=X,service_role=X`) on every one. Thirteen of those names have twins in `private` (`request_remote_session` does not), where `request_device_recovery` still carries the default `PUBLIC EXECUTE` (F8). That is latent, not live: `private` is not an exposed schema and `anon` has no `USAGE` on it. No `REVOKE` was needed or applied.
2. **`profiles.role` self-escalation — ANSWERED, favourable at the privilege layer only.** `authenticated` holds UPDATE on `profiles.display_name` only, so `update profiles set role = …` fails with a column-privilege error before any policy or trigger is consulted. The trigger body is now read: it rejects `id` and `role` changes, **except** that a write on a profile whose current role is `'unset'` passes. The column grant is therefore the only control, not the second of two (F3).
3. **Family scoping predicates — ANSWERED and implementation-verified.** Every expression scopes by a `private` helper or by `auth.uid()` directly; none is unconditional. The helper bodies are now read: each anchors on `auth.uid()`, requires `status = 'active'` and `families.deleted_at is null`, and none accepts a caller-supplied user id for its own side of the comparison (P13).
4. **Baseline drift — still open, and now evidenced.** No migration history exists; the live schema remains the only truth. The duplicated function sets in `public` and `private` are exactly the kind of drift G3 would freeze: 13 names exist in both schemas; 11 private-only functions (`record_audit` plus 10 helpers/triggers) have no `public` twin, and `public.request_remote_session` has no `private` twin.
