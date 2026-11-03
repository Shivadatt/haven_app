# 05 — Proposed change plan and approval gates

Derived from [01-baseline-inventory.md](01-baseline-inventory.md). **No change has been applied.** Items are ordered; each gate must be answered before the work behind it starts.

Stage 1 verdict today: **`BLOCKED — ACCESS OR APPROVAL REQUIRED`** on G2, G3, G5 and G6; G4 awaits a confirmation of the no-change recommendation and G7 applies only at FCM wiring. G1 was executed read-only on 2026-10-29 and B3b on 2026-10-30; both are answered.

| Gate | Type | State | Blocks |
| --- | --- | --- | --- |
| G1 — SQL-level introspection | Access | **ANSWERED 2026-10-29** — Q1–Q10 executed read-only; evidence in `docs/stage1/evidence/` | Audit, RLS verification, baseline, tests |
| G2 — Firebase project decision | Decision | **OPEN** | FCM, integration verification |
| G3 — Baseline migration | Approval | **OPEN — READY** — G1 satisfied; needs owner go-ahead; plan in [12-g3-baseline-plan.md](12-g3-baseline-plan.md) | Migration history |
| G4 — Data API exposure | Decision | Awaiting confirmation (no change recommended; see the default-ACL finding F1) | Nothing unless exposure is wanted |
| G5 — Negative/isolation tests | Approval | WAITING on G6 for a safe target | Authorization evidence |
| G6 — Environments | Decision | Documented, not created | Safe target for mutating tests |
| G7 — Secret placement | Decision | No live change yet | FCM wiring |

Execution detail, access-method comparison, file map and risk register: [09-access-and-audit-plan.md](09-access-and-audit-plan.md). Owner procedure for G1 and the G2 package check: [10-owner-runbook.md](10-owner-runbook.md). Item-by-item status and the finding list: [00-status-register.md](00-status-register.md).

## G1 — Provide SQL-level introspection (ANSWERED 2026-10-29)

**Outcome.** Executed through option C (read-only SQL by hand) in the project's own SQL Editor, one query per
`begin transaction read only; … commit;` wrapper, with `transaction_read_only = on` confirmed inside the transaction before
any catalogue query. No credential was created or exported, no DDL or DML was issued, and no statement failed.

**Results that close the gate:** RLS enabled on all 19 tables and no `anon` privilege anywhere (Q1, Q6); all 21 policy
expressions read and every one scoped (Q2); all 14 definer functions carry a pinned `search_path` and grant `EXECUTE` to
`postgres` and `service_role` only (Q7, Q10); the `profiles.role` path is blocked at column privilege (Q6); constraints and
indexes complete, including the idempotency and pairing-code uniques (Q4, Q5); advisors captured (Q9).

**One item was carried forward — and is now closed.** The `private` helper functions and the trigger functions were
outside Q3/Q7/Q10's schema filter, so their bodies and `EXECUTE` grants were unread. That was B3b. A further read-only
pass on 2026-10-30 read all of them ([g1-b3b](evidence/g1-b3b-20261029.json)). It found 24 functions in `private`, two of
them keeping the default `PUBLIC EXECUTE` (F8) and an actor-identity assumption in F7; the helpers themselves are clean.

**Findings raised, none applied:** default privileges leaking future objects to `anon`/`authenticated` (F1, P2), leaked
password protection disabled (F4, P2), `families_update_owner` ineffective (F2, P3), `profiles_update_self` column-agnostic
(F3, P3), `request_remote_session` search_path inconsistency (F5, P3), two policies with no matching grant (F6, P3),
actor identity taken from an argument (F7, P2), default `PUBLIC EXECUTE` on two `private` functions (F8, P3). All are
**PROPOSED — NOT APPLIED**; the per-finding plans are in [11-remediation-proposals.md](11-remediation-proposals.md).

**Why:** The dashboard exposes table names, row estimates and policy *names* only. Confirming RLS flags, policy expressions, triggers, indexes, grants, function security and the linter's warning requires SQL.

**Pick one:**

| Option | How | Notes |
| --- | --- | --- |
| A. Scoped access token | Dashboard → Account → Access Tokens → generate, then `export SUPABASE_ACCESS_TOKEN=sbp_...` in your shell only | Management API only: `link`, `migration list`, `functions download`. It does **not** enable `db dump` — that needs a DB connection (option B) |
| B. Database password | Export from Project Settings → Database, then `export SUPABASE_DB_PASSWORD=...` | Enables `supabase db dump`. Before resetting, confirm nothing authenticates with the current password; rotate again afterwards |
| C. Read-only SQL by hand (recommended) | You run the queries from [08-test-matrix.md](08-test-matrix.md) §0 in the SQL Editor and paste back the JSON; step-by-step in [10-owner-runbook.md](10-owner-runbook.md) | No credential is created or exported; strongest safety, weakest repeatability |

**Never** paste a token, password or service-role key into this repository or into chat. Set it as an environment variable in your own terminal.

Safest method and its exact procedure: [09-access-and-audit-plan.md](09-access-and-audit-plan.md) §2. Option C (read-only transaction in the SQL Editor, no credential created) is recommended over A and B.

**Unblocks:** RLS matrix verification, advisor warning detail, trigger/index/grant inventory, baseline migration (G3), negative tests (G5).

## G2 — Decide the Firebase project (blocks FCM)

**Why:** No Firebase project exists for this product. The only project visible in the console is `flutter-flow-w-ith-f-ir-6592ib` ("FlutterFlowWIthFIreBase", package `com.mycompany.flutterflowwithfirebase`, Spark, environment type Unspecified), which is a FlutterFlow demo. The CLI is authenticated as a *different* Google account that cannot see it.

| Option | Action | Assessment |
| --- | --- | --- |
| A. Create a dedicated project (recommended) | New Firebase project, e.g. `parent-control-prod`, register the child-app Android package **`com.haven.familysafety` — VERIFIED from the release APKs on 2026-10-30** | Clean FCM boundary, correct env naming, no coupling to a demo |
| B. Reuse `flutter-flow-w-ith-f-ir-6592ib` | Register the real Android app alongside the demo app | Cheap but mixes unrelated apps; package/app-id ambiguity; not recommended |

Do not guess the Android package name, and do not register a duplicate app. Both options require your decision plus the real `applicationId`.

**Note:** the Firebase CLI on this machine is logged in as a different account (`om-event*` projects). Re-authenticate as the account that owns the chosen project before any CLI action: `firebase logout && firebase login`.

Step-by-step setup, verification evidence and rollback: [firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md). The Android `applicationId` is **`com.haven.familysafety` — VERIFIED on 2026-10-30** from `Haven-1.1-release.apk` and `Haven-1.2-release.apk` (package, version and cert agree); `Haven-1.0.apk` shares the package name but uses a different signing key and Capacitor config. The remaining G2 decision is the Firebase project, not the package name.

## G3 — Capture a baseline migration (depends on G1)

The live schema has no tracked migration history. Recommended, additive and non-destructive. Full procedure, preconditions and verification: [12-g3-baseline-plan.md](12-g3-baseline-plan.md).

1. `supabase db dump --schema public --schema private -f <scratch>/<timestamp>_baseline.sql` — schema only, no rows. Both schemas are required: the `private` schema holds the implementations behind the `public` wrappers. The file is reviewed in scratch and only copied into `supabase/migrations/` once the repair decision in step 3 is recorded; placing it there earlier is what makes `db push` want to apply it.
2. Do not add this file to any seed path. Seeding must be disabled (`[db.seed] enabled = false`, `sql_paths = []` in `supabase/config.toml`); it is currently `enabled = true` while `supabase/seed.sql` does not exist, which blocks a local restore (G3-a in [12](12-g3-baseline-plan.md) §7).
3. `supabase migration repair --status applied <version>` marks the baseline as already applied **without executing it**. This is a metadata write to `supabase_migrations.schema_migrations` inside the project — it changes no table, policy or function, but it is still a write and needs the same approval.
4. Verify with `supabase migration list` (local == remote) and `supabase db diff` (must report no changes).

Scope limits to state plainly: even a `public` + `private` dump does **not** capture the `auth.users` trigger that creates `profiles`, nor cross-schema references. Those must be captured separately from `pg_get_triggerdef` and the FK definition (Q3b/Q5), not assumed to be in the baseline.

This records the current state; it does not alter the database. The verbatim rule: the baseline file is a **dump marked applied, never executed** — `supabase db push`, `supabase migration up`, `supabase db reset --linked` and any SQL-editor DDL must not be run against this project in Stage 1.

## G4 — Data API exposure decision (no change recommended)

All 19 tables are individually API-disabled while the Data API is globally enabled. That is a strong, deliberate posture: clients reach data through the 9 Edge Functions.

**Recommendation:** keep it. Do not expose tables to PostgREST in Stage 1. If any table is exposed later, it needs policies for every verb, not just SELECT.

Two caveats so this is not read as "no exposure": Realtime is enabled on four tables and authorises subscribers through their SELECT policies — those predicates were verified on 2026-10-29 and scope by family or session participant; and the 14 `SECURITY DEFINER` functions were checked and are **not** reachable at `/rest/v1/rpc/*` by `anon` or `authenticated` (Q10). Both are recorded in [04-rls-matrix.md](04-rls-matrix.md) §0a and §Resolution.

## G5 — Negative and isolation tests (depends on G1)

Cross-family isolation, service-role-only write paths, pairing-token rejection, expired/reused pairing codes and idempotency can only be tested with credentials. The executable test list is in [08-test-matrix.md](08-test-matrix.md).

## G6 — Environments

Only one environment exists (`prod`), and it already holds development-shaped data (1,773 location events, 39 remote sessions, 10 MAU, 8 profiles). Missing `dev` and `staging` are **documented, not created** — creating projects is your call, and a separate Firebase project per environment compounds G2.

## G7 — Secret placement (no live change yet)

When FCM is wired up: service-account JSON goes into Edge Function secrets (`supabase secrets set --env-file`), never into `supabase/config.toml`, a mobile app, or this repo. Client builds receive only the Firebase client config (`google-services.json`).

## Out of scope for Stage 1

Parent app, child app, pairing UI, command execution, WebRTC/TURN, retention jobs, billing. `webrtc_signals` and `remote_sessions` already exist with live rows — they are *existing* resources, to be left untouched and reviewed in Stage 2's threat model, not extended now.

## What happened when G1 was answered (2026-10-29)

1. ~~Full schema/policy/trigger/index/grant dump into `docs/stage1/evidence/` (sanitized).~~ **Done** — Q1–Q8, Q3b, Q10
   as JSON plus Q9 from the advisor response, with a provenance manifest.
2. ~~Verify the 19 RLS flags and every policy expression against [04-rls-matrix.md](04-rls-matrix.md).~~ **Done** — §0a
   holds the observed matrix and §3 records the outcome of R-01…R-08.
3. ~~Resolve the linter warning and 4 suggestions.~~ **Captured, not resolved** — neither needs a schema change; the one
   WARN (leaked-password protection) is an auth-config toggle awaiting an owner decision (F4).
4. Produce the baseline migration (G3) and a no-diff proof. **Next step, needs the owner's go-ahead** — G3 is `READY`;
   the procedure and its blockers are in [12-g3-baseline-plan.md](12-g3-baseline-plan.md).
5. Re-run the negative tests and publish the Phase F report with per-item PASS/BLOCKED labels. **Report produced
   2026-10-30** ([reports/stage1-final.md](reports/stage1-final.md)); the negative tests remain **blocked** on G5
   (test identities) and G6 (a non-production target for anything mutating).
