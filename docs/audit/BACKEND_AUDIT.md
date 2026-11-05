# SUPABASE & FIREBASE BACKEND AUDIT

**Target Location:** `D:\control\backend\supabase`, `D:\control\firebase`, `D:\control\docs\stage1`, and `D:\control\docs\stage2`  
**Audit Date:** 2026-11-05  
**Audit Standard:** Strict Evidence-Based Audit (Zero-Guessing, Exact Path & Line Citations)  
**Execution Posture:** Read-Only Source and Spec Inspection

---

## 1. EXECUTIVE SUMMARY & FOUR-TIER BACKEND STATUS

A rigorous audit must strictly distinguish between four backend states:

1. **SQL File Exists Locally:** **YES.** Four comprehensive DDL migration files totaling 4,514 lines plus 3 patch files exist under [`docs/stage2/migrations/`](file:///d:/control/docs/stage2/migrations/) and [`docs/stage2/patches/`](file:///d:/control/docs/stage2/patches/).
2. **SQL Has Been Reviewed:** **YES.** Extensive documentation and independent review registers exist (`docs/stage2/S2-A3-database-audit.md`, `S2-EXEC-04-sql-structural-findings.md`, `S2-EXEC-07-a3b-independent-verification.md`).
3. **SQL Was Executed in Staging:** **NO.** Staging project `parent-control-staging` (`dzonzgngwxclhfnvxtvu`) has **0 tables, 0 SQL functions, 0 Edge Functions, and 0 secrets** ([`docs/stage2/S2-EXEC-06-live-staging-observation-2026-11-03.md:65-70`](file:///d:/control/docs/stage2/S2-EXEC-06-live-staging-observation-2026-11-03.md#L65-L70)).
4. **Database Object Is Verified in Staging:** **ZERO.** 0 tables or functions are active or verified in staging.

Due to this state, all client Flutter features fail closed with typed refusals (`BUILT / REFUSES AT THE SEAM`).

---

## 2. DATABASE SCHEMA & POSTGRESQL ARCHITECTURE

### 2.1 The 19 Tables in the Schema
Evidence Source: [`docs/stage1/04-rls-matrix.md:38-59`](file:///d:/control/docs/stage1/04-rls-matrix.md#L38-L59) and [`docs/stage2/migrations/A3-staging-load-v1.sql:144-380`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql#L144-L380). Total of 183 columns across 19 tables.

| # | Table Name | Columns | Primary Key | Foreign Keys | Key Indexes |
|---|---|---|---|---|---|
| 1 | `audit_logs` | 9 | `id` (uuid) | `family_id` -> `families`<br>`actor_user_id` -> `profiles`<br>`device_id` -> `devices` | `idx_audit_logs_family_created`<br>`idx_audit_logs_actor_created` |
| 2 | `child_contact_ids` | 4 | `(child_user_id, contact_id)` | `child_user_id` -> `profiles` | Primary key only |
| 3 | `device_apps` | 9 | `id` (uuid) | `device_id` -> `devices`<br>`family_id` -> `families` | `idx_device_apps_device_id`<br>`idx_device_apps_family_id` |
| 4 | `device_commands` | 15 | `id` (uuid) | `device_id` -> `devices`<br>`family_id` -> `families`<br>`created_by` -> `profiles` | `idx_device_commands_device_status`<br>UQ: `(device_id, idempotency_key)` |
| 5 | `device_pairing_tokens` | 12 | `id` (uuid) | `family_id` -> `families`<br>`created_by` -> `profiles`<br>`child_user_id` -> `profiles` | `idx_pairing_tokens_token_hash`<br>`idx_pairing_tokens_family_status` |
| 6 | `device_policies` | 10 | `id` (uuid) | `device_id` -> `devices`<br>`family_id` -> `families`<br>`created_by` -> `profiles` | `idx_device_policies_device_active`<br>`idx_device_policies_family_id` |
| 7 | `devices` | 25 | `id` (uuid) | `family_id` -> `families`<br>`child_user_id` -> `profiles` | `idx_devices_family_id`<br>UQ: `(family_id, installation_id)` |
| 8 | `families` | 7 | `id` (uuid) | `owner_id` -> `profiles` | `idx_families_owner_id` |
| 9 | `family_members` | 7 | `id` (uuid) | `family_id` -> `families`<br>`user_id` -> `profiles` | `idx_family_members_user_family`<br>UQ: `(family_id, user_id)` |
| 10 | `location_events` | 9 | `id` (uuid) | `device_id` -> `devices`<br>`family_id` -> `families` | `idx_location_events_device_time`<br>`idx_location_events_family_time` |
| 11 | `pairing_attempts` | 5 | `id` (uuid) | None (identifier string based) | `idx_pairing_attempts_identifier_time` |
| 12 | `pairing_requests` | 9 | `id` (uuid) | `family_id` -> `families`<br>`child_user_id` -> `profiles`<br>`parent_user_id` -> `profiles` | `idx_pairing_requests_family_status`<br>`idx_pairing_requests_child_user` |
| 13 | `profiles` | 5 | `id` (uuid) | `id` -> `auth.users(id)` | `profiles_pkey` |
| 14 | `remote_sessions` | 17 | `id` (uuid) | `family_id` -> `families`<br>`device_id` -> `devices`<br>`parent_user_id` -> `profiles` | `idx_remote_sessions_device_status`<br>`idx_remote_sessions_parent_child` |
| 15 | `safe_zone_states` | 4 | `(zone_id, device_id)` | `zone_id` -> `safe_zones`<br>`device_id` -> `devices` | Composite PK only |
| 16 | `safe_zones` | 9 | `id` (uuid) | `family_id` -> `families`<br>`created_by` -> `profiles` | `idx_safe_zones_family_active` |
| 17 | `safety_alerts` | 10 | `id` (uuid) | `family_id` -> `families`<br>`device_id` -> `devices` | `idx_safety_alerts_family_time`<br>`idx_safety_alerts_device_status` |
| 18 | `usage_daily` | 10 | `id` (uuid) | `device_id` -> `devices`<br>`family_id` -> `families` | `idx_usage_daily_device_date`<br>UQ: `(device_id, date)` |
| 19 | `webrtc_signals` | 7 | `id` (uuid) | `session_id` -> `remote_sessions`<br>`from_user_id` -> `profiles` | `idx_webrtc_signals_session_created` |

**Constraints & Index Metrics ([`A3-staging-load-v1.sql:1474-1476`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql#L1474-L1476)):**
- 19 Tables, 183 Columns.
- 137 Constraints: 19 PKs, 9 Unique, 65 Check, 44 FKs.
- 34 explicit indexes.

### 2.2 Missing Tables in Current Model
The following tables are documented as essential for a production parental-control product but are **missing from the baseline schema** ([`docs/stage1/03-data-model.md:43-48`](file:///d:/control/docs/stage1/03-data-model.md#L43-L48)):
1. `push_tokens` (device FCM token storage; currently planned in unexecuted migration `A3c-notification-backend.sql`).
2. `command_acks` (terminal state & idempotency log for commands).
3. `consents` (guardian legal consent and terms tracking).
4. `subscriptions` (billing, quota, and plan tier records).
5. `deletion_jobs` (GDPR right-to-erasure / soft-delete purge queue).

---

## 3. ROW LEVEL SECURITY (RLS) & "THE TWO WALLS"

### 3.1 RLS Status
- **RLS Enabled:** All 19 tables have `relrowsecurity = true` ([`docs/stage1/04-rls-matrix.md:15`](file:///d:/control/docs/stage1/04-rls-matrix.md#L15)).
- **RLS Forced:** 0 tables have `relforcerowsecurity = true` (service-role bypasses RLS).
- **Captured Policies:** 21 policies (15 SELECT, 6 Write). All PERMISSIVE, scoped to `authenticated`. 0 policies for `anon`.
- **4 Deny-All Tables:** `child_contact_ids`, `device_pairing_tokens`, `pairing_attempts`, `safe_zone_states` have 0 policies.
- **The Staging Policy Deficit:** In `A3-staging-load-v1.sql:1497-1507`, **only 4 policies are emitted active**; 17 policies are commented out because they depend on 3 private SQL functions whose return types require an owner admissibility ruling (`A3b-functions-triggers-candidate.sql`).

### 3.2 The Architectural Bottleneck: "The Two Walls"
Documented in [`docs/features/README.md:18-25`](file:///d:/control/docs/features/README.md#L18-L25), [`docs/stage1/04-rls-matrix.md:30-59`](file:///d:/control/docs/stage1/04-rls-matrix.md#L30-L59), and [`commands_repository.dart:9-19`](file:///d:/control/apps/haven_app/lib/features/device_commands/data/commands_repository.dart#L9-L19):

1. **Wall 1: The Table Privilege Wall:**
   - Role `authenticated` has SELECT grants on 14 tables, but INSERT/UPDATE/DELETE grants are absent across nearly all tables.
   - Client UPDATE is permitted ONLY on: `families(name, settings)`, `profiles(display_name)`, and `safe_zones(active, lat, lng, ...)`.
   - Client INSERT is permitted ONLY on: `webrtc_signals`.
   - Client DELETE is permitted ONLY on: `safe_zones`.
   - **Finding F6:** `devices` table has 0 privileges granted to `authenticated` (not even SELECT; the SELECT policy is unreachable without a GRANT).
2. **Wall 2: The RPC Privilege Wall:**
   - All 14 captured public RPC functions grant EXECUTE solely to `postgres` and `service_role`.
   - `auth_exec = false` and `anon_exec = false` for all 14 RPCs.
   - Calling `/rest/v1/rpc/<name>` as an authenticated parent returns `401 Unauthorized` or `403 Forbidden`.

**Result:** The parent Flutter app cannot write to the database directly or execute stored procedures. All mutations MUST pass through Supabase Edge Functions with `SUPABASE_SERVICE_ROLE_KEY`.

---

## 4. DATABASE FUNCTIONS & TRIGGERS (38 TOTAL)

Evidence Source: [`docs/stage1/04-rls-matrix.md:345-366`](file:///d:/control/docs/stage1/04-rls-matrix.md#L345-L366) and [`docs/stage2/migrations/A3b-functions-triggers-candidate.sql:1-120, 823-910`](file:///d:/control/docs/stage2/migrations/A3b-functions-triggers-candidate.sql#L1-L120).

- **14 Public RPC Functions (SECURITY DEFINER, owner postgres, service_role execute only):**
  1. `apply_policy_version`
  2. `create_family_with_owner`
  3. `create_pairing_invite`
  4. `create_pairing_request`
  5. `detect_offline_devices`
  6. `expire_stale_commands`
  7. `expire_stale_sessions`
  8. `poll_device_commands`
  9. `replace_device_apps`
  10. `request_device_recovery`
  11. `request_remote_session`
  12. `respond_pairing_request`
  13. `revoke_device`
  14. `unlink_child`
- **24 Private Functions:**
  - 13 private twins corresponding to public RPCs.
  - 3 RLS helper functions: `private.is_family_parent`, `private.is_family_member`, `private.shares_active_family`.
  - 6 Trigger functions: `private.handle_new_user`, `private.set_updated_at`, `private.audit_logs_append_only`, `private.families_before_update`, `private.profiles_before_update`, `private.remote_session_transition_guard`.
  - 2 Security helpers: `private.record_audit`, `private.realtime_topic_allowed`.
- **Body Coverage Status:**
  - **14 Bodies Captured:** 9 gating functions (3 helpers + 6 triggers) plus 5 recovery/session RPCs.
  - **24 Bodies Absent:** Unrecoverable offline; forbidden from being stubbed or fabricated.

---

## 5. SUPABASE EDGE FUNCTIONS AUDIT (`backend/supabase/functions/`)

### 5.1 Inventory of All 9 Edge Functions
All 9 slugs carry the mandatory label: `RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION`. All 41 files strictly obey the 200-line rule.

| Slug | Entry & Files | Lines | Actions Supported | Primary Status |
|---|---|---|---|---|
| `auth-bootstrap` | `index.ts`, `set_role.ts`, `create_family.ts` | 237 | `set_role`, `create_family` | Written, tested offline; undeployed |
| `cron` | `index.ts` | 181 | Periodic cleanup & offline detection | Written, tested offline; undeployed |
| `device-command` | `index.ts`, `create.ts`, `poll_ack.ts` | 430 | `create`, `poll`, `ack` | **PARTIAL**: 4 types `NOT DEPLOYABLE WITHOUT SPEC` |
| `device-policy` | `index.ts` | 182 | `update` | **BLOCKED**: `NOT DEPLOYABLE WITHOUT SPEC` (V/X/Z keys missing) |
| `device-register` | `index.ts`, `register_flow.ts` | 304 | `register` | Written, tested offline; undeployed |
| `device-telemetry` | `index.ts`, `heartbeat.ts`, `location.ts`, `usage_apps.ts`, `limits.ts` | 497 | `heartbeat`, `location`, `usage_apps` | Written, tested offline; undeployed |
| `family-admin` | `index.ts`, `alerts.ts`, `device_actions.ts`, `retention.ts` | 358 | `revoke_device`, `request_device_recovery`, `ack_alert`, `purge_data`, `update_retention` | Written, tested offline; undeployed |
| `pairing` | `index.ts`, `issuance.ts`, `redeem.ts`, `requests.ts`, `unlink.ts`, `shared.ts` | 724 | 9 actions (invite, create, redeem, respond, unlink, etc.) | Written, tested offline; undeployed |
| `remote-session` | `index.ts`, `lifecycle.ts`, `media.ts` | 450 | `request`, `pending_child`, `respond`, `start`, `end`, `ice` | Written, tested offline; undeployed |
| `_shared/` | 13 utility files | 1,248 | Envelope, CORS, Auth, Quotas, Rate Limiting, Identity, etc. | 100% compliant, tested offline |

### 5.2 Missing Specifications (`NOT DEPLOYABLE WITHOUT SPEC`)
1. **`device-policy` ([`device-policy/index.ts:78-80, 138-146`](file:///d:/control/backend/supabase/functions/device-policy/index.ts#L78-L80)):**
   Constants `TOP_LEVEL_POLICY_KEYS`, `SUB_OBJECT_KEYS`, and `APP_RULE_KEYS` (minified constants V, X, Z) were never captured. Updates fail closed with HTTP `501 policy_schema_missing`.
2. **`device-command` ([`device-command/create.ts:163-168`](file:///d:/control/backend/supabase/functions/device-command/create.ts#L163-L168)):**
   Payload schemas for 4 command types (`sync_policy`, `request_usage`, `request_location`, `end_session`) were never captured. Creating these command types fails closed with HTTP `501 command_spec_missing`.

### 5.3 Required Edge Secrets & Staging Status
Source: [`backend/supabase/config/environment.md`](file:///d:/control/backend/supabase/config/environment.md).
- `SUPABASE_URL`: Known (`https://dzonzgngwxclhfnvxtvu.supabase.co`).
- `SUPABASE_SERVICE_ROLE_KEY`: **NOT CREATED** (Instrument A9 unsigned).
- `PAIRING_HASH_PEPPER`: **NOT CREATED** (Falls back to plain SHA-256 + warning; Finding E6).
- `CRON_SECRET`: **NOT CREATED** (Cron throws 503 if secret < 16 chars).
- `TURN_HOST` & `TURN_SECRET`: **NOT CREATED** (Remote session ICE throws 503).

---

## 6. BACKEND TEST SUITE AUDIT (`backend/supabase/tests/`)

- **Total Test Cases:** **82 tests** across 7 test files, all passing offline.
- **Engine:** Deno 2.9.4 compatible.
- **In-Memory Stubs (`stub_db.ts`):** Tests run strictly against in-memory fake clients (`FakeClient`, `FakeQuery`). They verify logic branching and error envelopes. **They do not touch Supabase, do not execute SQL, and do not verify deployed functions** ([`stub_db.ts:12-18`](file:///d:/control/backend/supabase/tests/stub_db.ts#L12-L18)).

---

## 7. FIREBASE & PUSH NOTIFICATIONS AUDIT

### 7.1 Firebase Project Configuration
- Dedicated project: `haven-staging` (`haven-staging-46822`), Project Number: `381273275501` ([`docs/stage2/S2-A2-firebase-console-audit.md:111-125`](file:///d:/control/docs/stage2/S2-A2-firebase-console-audit.md#L111-L125)).
- Approved scope: FCM v1 push notifications only (Gate G2). Firebase Auth, Firestore, and Cloud Functions are disabled.

### 7.2 `google-services.json`
- **Current State:** **ABSENT.** Zero Android apps are registered in `haven-staging` console. No file exists in the repo ([`docs/stage2/S2-A2-firebase-console-audit.md:216-217`](file:///d:/control/docs/stage2/S2-A2-firebase-console-audit.md#L216-L217)). Root `.gitignore:14` ignores it.

### 7.3 Push Notification Pipeline Gaps
The push pipeline is broken end-to-end:
1. **Client:** `FirebasePushTransport` fails closed: `"No Firebase app is registered in this build"` ([`push_transport_impl.dart:19-21`](file:///d:/control/packages/haven_api/lib/src/push_transport_impl.dart#L19-L21)).
2. **Schema:** No `push_tokens` table or token column exists in the 19 tables. Candidate migration `A3c-notification-backend.sql` (1,317 lines) is unexecuted.
3. **Dispatch:** No push sending Edge Function exists.
4. **Credential:** Admin SDK service account exists, but **no private key has ever been generated** ([`docs/stage2/S2-EXEC-06:45`](file:///d:/control/docs/stage2/S2-EXEC-06-live-staging-observation-2026-11-03.md#L45)).

### 7.4 Third-Party Auth & UID Mapping (`IDENTITY_MODE`)
Source: [`backend/supabase/functions/_shared/identity.ts:16-54, 117-139`](file:///d:/control/backend/supabase/functions/_shared/identity.ts#L16-L54).
- `IDENTITY_MODE = "supabase-auth"` is locked.
- If changed to `"firebase-uid"`, it deliberately throws HTTP `503 identity_mode_unsigned` because Instrument A13 is unsigned and migration `A3d-firebase-identity-mapping.sql` (663 lines) is unexecuted.
- Supabase Staging dashboard has 0 external JWT providers configured.

---

## 8. STRICT 200-LINE SOURCE FILE AUDIT

All 51 TypeScript files across `functions/` and `tests/` were verified:
- **Violations (> 200 lines):** **0 files (100% compliant).**
- **Longest File:** `device-register/register_flow.ts` (187 lines).

---

## 9. STEP-BY-STEP BACKEND UNBLOCKING ROADMAP

1. **Gate G3 Execution:** Owner loads DDL into `parent-control-staging` (`dzonzgngwxclhfnvxtvu`) browser SQL editor in exact order:
   `A3-staging-load-v1.sql` → `A3b-functions-triggers-candidate.sql` (after admissibility ruling) → `A3d-firebase-identity-mapping.sql` → `A3c-notification-backend.sql` → Patches `S2-P01..P03`.
2. **Gate G7 / A9 Execution:** Owner sets 6 backend secrets in Supabase dashboard.
3. **Spec Resolution:** Supply V/X/Z policy key allowlists and 4 missing command schemas.
4. **Firebase Wiring (G2 / A12-R):** Register Android app in `haven-staging`, download `google-services.json`, generate Admin SDK private key, author push dispatch function.
5. **Slug Deployment (A7-R / A8-R):** Deploy 9 Edge Functions via Supabase dashboard / CLI.

