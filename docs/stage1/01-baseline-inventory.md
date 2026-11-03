# 01 — Baseline inventory (read-only discovery)

Captured: 2026-10-29, ~15:00–15:30 local, via the authenticated Supabase dashboard (in-app browser) and the Firebase CLI.
No changes were made to either project during discovery.

> **Post-G1 note (2026-10-29, extended 2026-10-30).** Gate G1 was answered later the same day: Q1–Q10 ran read-only in the
> project's SQL Editor and the results are in [evidence/](evidence/); B3b read the function and trigger bodies on
> 2026-10-30. Anything below that says "inferred", "not captured" or "blocked by
> G1" describes the state of *this* discovery pass and has been superseded — see [00-status-register.md](00-status-register.md)
> and [04-rls-matrix.md](04-rls-matrix.md). The Firebase section (§7) is unaffected.

## 1. Supabase

| Field | Observed value |
| --- | --- |
| Organization | `<owner-email>'s Org` (`symqztrmaziuwdibcfrq`), 1 project — email redacted |
| Project name | `parent-control-prod` |
| Project ref | `hhqgreaoqulmfwfwarhc` |
| Region | ap-northeast-2 |
| Compute | NANO |
| Plan | Free |
| Database size | 32 MB / 500 MB |
| Egress | 0.12 GB / 5 GB |
| Monthly active users | 10 / 50,000 |
| File storage | 0 B / 1 GB |
| Log ingestion | 0.17 GB / 1 GB |
| Log query | 33.9 GB / 100 GB |

The project is **not empty**: it contains live application tables, users and telemetry rows.

## 2. Tables (19, schema `public`)

Row counts are dashboard *estimates*, not `count(*)`.

| Table | Cols | Rows (est.) | Realtime | Data API | RLS policies (name · command) |
| --- | --- | --- | --- | --- | --- |
| audit_logs | 9 | 262 | off | disabled | `audit_logs_select_family_parent` · SELECT |
| child_contact_ids | 4 | 4 | off | disabled | — none — |
| device_apps | 9 | 2 | off | disabled | `device_apps_select_parent_or_child` · SELECT |
| device_commands | 15 | 17 | **on** | disabled | `device_commands_select_parent_or_child` · SELECT |
| device_pairing_tokens | 12 | 27 | off | disabled | — none — |
| device_policies | 10 | 15 | off | disabled | `device_policies_select_parent_or_child` · SELECT |
| devices | 25 | 14 | off | disabled | `devices_select_parent_or_child` · SELECT |
| families | 7 | 3 | off | disabled | `families_select_members` · SELECT; `families_update_owner` · UPDATE |
| family_members | 7 | 7 | off | disabled | `family_members_select_family` · SELECT |
| location_events | 9 | 1,773 | off | disabled | `location_events_select_parent_or_child` · SELECT |
| pairing_attempts | 5 | 68 | off | disabled | — none — |
| pairing_requests | 9 | 25 | off | disabled | `pairing_requests_select_participants` · SELECT |
| profiles | 5 | 8 | off | disabled | `profiles_select_self_or_family` · SELECT; `profiles_update_self` · UPDATE |
| remote_sessions | 17 | 39 | **on** | disabled | `remote_sessions_select_participants` · SELECT |
| safe_zone_states | 4 | 0 | off | disabled | — none — |
| safe_zones | 9 | 0 | off | disabled | `safe_zones_select_family` · SELECT; `safe_zones_insert_parent` · INSERT; `safe_zones_update_parent` · UPDATE; `safe_zones_delete_parent` · DELETE |
| safety_alerts | 10 | 2 | **on** | disabled | `safety_alerts_select_parent_or_child` · SELECT |
| usage_daily | 10 | 29 | off | disabled | `usage_daily_select_parent_or_child` · SELECT |
| webrtc_signals | 7 | 1,093 | **on** | disabled | `webrtc_signals_select_participant` · SELECT; `webrtc_signals_insert_participant` · INSERT |

Table comments visible on `families`, `profiles` and `child_contact_ids` indicate a deliberate design (soft delete via `deleted_at`, profile rows created by an `auth.users` trigger, pairing identifiers explicitly "never a credential").

### What this means

- **RLS state is now observed, not inferred.** The Policies page renders a "Disable RLS" action for every table, which is only shown when RLS is currently enabled; Q1 later confirmed `relrowsecurity = true` on all 19, with `relforcerowsecurity = false` everywhere and owner `postgres` ([g1-q1](evidence/g1-q1-20261029.json)).
- **Policy bodies were captured later by Q2.** The page exposes policy name, command and role only; `USING` / `WITH CHECK` came from the G1 run ([g1-q2](evidence/g1-q2-20261029.json), summarised in [04](04-rls-matrix.md) §0a).
- **Every table is API-disabled** for the Data API (per-table toggle), while the Data API itself is globally enabled. All client reads therefore appear to go through the 9 Edge Functions or a direct connection, not PostgREST.
- **Four tables have RLS on and zero policies**: `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states`. With RLS on and no policy the default is deny-all for `anon` / `authenticated` — the right shape for secrets and attempt logs. Q1 confirmed the RLS flag on all four; the Edge Functions bypass RLS with the service role, so this is a statement about client reachability, not a test result.
- **Write paths are almost entirely service-role only.** There is no INSERT policy on `devices`, `families`, `family_members`, `location_events`, `device_commands`, `profiles` (insert), `audit_logs`, etc.

## 3. Edge Functions (9, deployed 2–3 days before capture)

`auth-bootstrap`, `cron`, `device-command`, `device-policy`, `device-register`, `device-telemetry`, `family-admin`, `pairing`, `remote-session`.

Names align with the table set: registration, pairing, command dispatch, policy sync, telemetry ingestion, remote-session signalling, family administration and scheduled work.

## 4. Authentication

| Setting | State |
| --- | --- |
| Email provider | Enabled |
| All OAuth / phone / SAML / Web3 providers | Disabled |
| Allow new users to sign up | On |
| Confirm email | On |
| Anonymous sign-ins | Off |
| Manual linking | Off |

## 5. Migration history

The dashboard Migrations page shows the empty "run your first migration" state, i.e. no CLI-tracked migrations for this project. The 19-table schema was created outside a tracked migration flow. Treat the live database as the only source of truth until a baseline migration is captured (gate G3).

## 6. Security advisors (linter)

0 errors · 1 warning · 4 informational suggestions. **The advice text did not render** during this pass because the browser surface was hidden; it was captured later from the dashboard's own `run-lints` response and filed as [g1-q9](evidence/g1-q9-20261029.json) (5 rules / 33 rows, 2 WARN — the UI groups them as 1 + 4).

## 7. Firebase

| Field | Observed value |
| --- | --- |
| Browser console account | `<account-email>`, 1 project — email redacted |
| Project | `FlutterFlowWIthFIreBase` / `flutter-flow-w-ith-f-ir-6592ib`, project number 960138869854 |
| Environment type | Unspecified |
| Android app | `com.mycompany.flutterflowwithfirebase` (FlutterFlow default package) |
| Plan | Spark |
| Firebase CLI account | **Different account** — sees `om-event`, `om-events-and-decorators`, `om-events-store` |

There is **no Firebase project belonging to this product**. The single console project is an unrelated FlutterFlow demo, and the CLI session is authenticated as a different Google identity than the console. Nothing was modified.

## 8. Toolchain present on this machine

`supabase` 2.109.0 · `firebase` 15.23.0 · `flutter` 3.38.8 / Dart 3.10.7 · JDK 17 · Node 24.14.0 · git 2.47.1.
**No Docker**, so `supabase start` (local stack) is unavailable. No `psql`. No Supabase access token and no database password on this machine.

## 9. Access limits hit during discovery

| Limit | Effect |
| --- | --- |
| No Supabase access token / DB password | Cannot run `supabase link`, `db dump`, `migration list`, or any SQL — no policy bodies, triggers, indexes, grants, advisor detail |
| In-app browser surface hidden | Pointer clicks and screenshots fail; only navigation and script reads work, so SQL Editor and lazily-rendered advisor panels are unusable |
| Firebase CLI on a different account | Cannot inspect the product's Firebase project or enable FCM from the CLI |

These were consolidated as gates G1 and G2 in [05-change-plan.md](05-change-plan.md). G1 was answered on 2026-10-29 through the first row's alternative — the dashboard SQL Editor — so no token or password was ever needed. G2 is still open.

---

## 10. Second pass (2026-10-29, ~15:40–16:05) — deeper credential-free discovery

The dashboard renders more than the first pass used. Pages that render without interaction were read directly; the Monaco editor exposed the Edge Function entry files. No SQL was executed and no control was changed.

### 10.1 Schema

All 19 tables' column names, types and rendered constraint flags were captured. See [evidence/schema-columns.md](evidence/schema-columns.md). This supersedes the "columns not captured" caveat in §2 for names/types/flags. Defaults came from Q8, FK targets and delete rules from Q5, and unique/check indexes and constraints from Q4/Q5 in the G1 run ([evidence/](evidence/)).

Notable structure: `devices.secret_hash`, `device_pairing_tokens.code_hash` and `pairing_attempts.code_hash` are the only credential-bearing columns — no plaintext codes; `device_commands` carries `idempotency_key` (NOT NULL), `acked_at`, `result`, `attempts`; `remote_sessions` carries `consent_recorded` and `session_nonce`; `profiles` has a `role` column.

### 10.2 Postgres functions and triggers

14 `public` functions (wrappers) plus 24 in `private`, all 14 public wrappers `SECURITY DEFINER`, implementing pairing, policy application, command polling, device revocation/recovery, offline detection and stale-session expiry. 7 triggers, including `audit_logs_append_only` (BEFORE UPDATE/DELETE), `profiles_before_update` and `remote_sessions_transition_guard`. Details: [evidence/functions-and-triggers.md](evidence/functions-and-triggers.md), [g1-b3b](evidence/g1-b3b-20261029.json).

### 10.3 Edge Functions

Two functions served readable TypeScript (`pairing` 972 lines, `auth-bootstrap` 140 lines); the other seven are minified bundles in the editor. `pairing` shows a layered guard vocabulary — `requireUser`, `requireRole`, `requireVerifiedEmail`, `requireAction`, `assertFamilyParent`, `assertChildMembership`, `assertInviteQuotaAllowed`, `assertPairingCodeCreationAllowed`, `assertPairingRedeemAllowed`, `ensureContactId` — plus `_shared/{auth,audit,cors,envelope,rate_limit,validation}.ts` modules. `cron` references a cron credential. The `pairing` summary tile reported 1,756 invocations and 0 errors since the last deploy; that figure is platform-reported and not independently verified (the 4XX chart had no data points in a hidden browser surface). All nine were reviewed read-only in Phase E on 2026-10-30 — the seven bundles by identifier, not from exported repository source; see [13-edge-function-source-inventory.md](13-edge-function-source-inventory.md).

### 10.4 Settings not captured in the first pass

| Setting | Value |
| --- | --- |
| JWT expiry | 3600 s |
| Refresh-token rotation | enabled; reuse interval 10 s |
| Single-session / time-box / inactivity timeout | off / 0 / 0 (Pro-plan features, unavailable on Free) |
| Connection pool | 15 (Nano default), 200 max clients |
| Network restrictions | none — database reachable from all IPs |
| SSL enforcement, connection logging | toggles present; state **NOT CAPTURED** |
| Storage buckets | none |
| Data API | globally enabled; all 19 tables individually API-disabled |

### 10.5 Child application id (verified 2026-10-30)

A local build artefact, `Haven-1.2-release.apk`, declares application id **`com.haven.familysafety`** (versionCode 3,
versionName 1.2); `Haven-1.1-release.apk` agrees (versionCode 2). This is **VERIFIED** for G2 by `aapt2 dump badging`;
`Haven-1.0.apk` shares the package name but is signed with a different key and carries a different Capacitor config.
See [g2-apk-identity-20261030.md](evidence/g2-apk-identity-20261030.md) and
[firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) §0a.
