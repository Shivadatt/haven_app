# HAVEN PARENTAL CONTROL — MASTER AUDIT REPORT

**Project Location:** `D:\control`  
**Audit Date:** 2026-11-05  
**Audit Standard:** Strict Evidence-Based Audit (Zero-Guessing, Exact Path & Line Citations)  
**Execution Posture:** Read-Only Audit (No Source Files Modified)  
**Auditor:** Antigravity Advanced Agentic Coding System (3 Parallel Deep-Dive Subagents)

---

## 1. EXECUTIVE VERDICT & HIGH-LEVEL SUMMARY

Haven Parental Control is an Android-first parental safety system. The project exhibits an extraordinarily high standard of internal architectural discipline, documentation rigor, and refusal-model honesty. However, **there is a total separation between the written codebase and the live deployment infrastructure**:

1. **Staging Environment is 100% Undeployed:** Supabase staging project `parent-control-staging` (`dzonzgngwxclhfnvxtvu`) currently runs **0 tables, 0 SQL functions, 0 Edge Functions, and 0 secrets**. Firebase staging project `haven-staging` (`haven-staging-46822`) has **0 registered Android apps and 0 credentials**.
2. **Client Architecture Built to the Seam:** The Flutter application (`apps/haven_app`, 26 routes, 16 features) and pure-Dart shared packages (`haven_core`, `haven_models`, `haven_api`) are fully authored, type-checked, and tested offline (772 passing Dart tests). Where backend capability is missing, the code does not fake data; instead, it returns typed, transparent refusal errors (`BlockedFailure`) that display the exact architectural blocker directly to the user.
3. **Android Native Child is a Read-Only Probe:** The Kotlin code (`android_native/child_services/`) is compiled directly into the Flutter app. It provides a single read-only MethodChannel method (`state.readAll`) that queries Android OS status. It contains **no background services, no foreground services, no policy enforcement, no location streaming, and no remote command execution**. It has **0 tests** and has never run on a physical device.
4. **Strict 200-Line Limit Compliance:** **0 violations across 397 hand-written source files** (100% compliant). Every single `.dart`, `.kt`, `.sql`, and `.ts` file obeys the project's strict 200-line ceiling.

---

## 2. COMPLETION METRICS & PROGRESS CALCULATION

### 2.1 Feature Classification Counts (92 Documented Subfeatures)
Across all 11 functional modules audited in [`FEATURE_MATRIX.md`](file:///d:/control/docs/audit/FEATURE_MATRIX.md):

| Status | Count | Percentage | Definition & Criteria |
|---|---|---|---|
| **COMPLETE** | 10 | 10.87% | Verified functional implementation with passing tests (local/offline). |
| **PARTIAL** | 22 | 23.91% | Meaningful code exists in UI/controller/model, but complete end-to-end flow is missing. |
| **UI ONLY** | 6 | 6.52% | UI screens and cards exist, but live data reads are blocked by RLS or missing schema. |
| **BACKEND ONLY** | 0 | 0.00% | Backend exists without client counterpart. |
| **BLOCKED** | 35 | 38.04% | Authored code exists up to the seam, but execution is blocked by unsigned gates, missing secrets, or undeployed backend. |
| **NOT IMPLEMENTED** | 19 | 20.65% | No meaningful code exists (e.g. background services, runtime permission triggers, app blocking). |
| **BROKEN** | 0 | 0.00% | No verified regressions (code fails closed by design). |
| **UNTESTED** | 0 | 0.00% | All authored Dart/TS logic has corresponding offline unit/widget tests. |
| **NOT VERIFIED** | 0 | 0.00% | All items have been conclusively verified from source. |
| **TOTAL** | **92** | **100.0%** | |

---

### 2.2 Completion Percentages

The audit produces two distinct scores to prevent inflation:

#### Score 1: Implementation Coverage — 40.8%
*How much of the documented functionality has written, meaningful code (including offline-tested code currently blocked by deployment):*
$$\text{Coverage} = \frac{10 \times 1.0 + 22 \times 0.5 + 6 \times 0.25 + 25 \times 0.5 \text{ (blocked with code)} + 10 \times 0.25 \text{ (blocked UI)}}{92} = \frac{37.5}{92} = 40.76\%$$

*(If calculated strictly excluding all blocked items: $(10 \times 1.0 + 22 \times 0.5 + 6 \times 0.25) / 92 = 22.5 / 92 = \mathbf{24.46\%}$.)*

#### Score 2: Verified Completion — 22.8% (Offline) / 0.0% (Live End-to-End)
*How much functionality has been demonstrated to work through tests and evidence:*
- **Verified Offline:** **22.8%** ($(10 \times 1.0 + 22 \times 0.5) / 92 = 21.0 / 92$). Verified via 772 passing Dart tests and 82 passing Deno tests against mock fakes.
- **Verified Live End-to-End against Staging/Hardware:** **0.0%**. Zero features can communicate with a live backend because staging runs 0 tables and 0 functions.

---

## 3. AUDIT FINDINGS BY SYSTEM LAYER

### 3.1 Flutter Application & GetX Architecture
- **Routes & Pages:** 26 named routes in [`AppRoutes`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart), 25 registered in `AppPages`, 1 `NotFoundPage` (404 handler) ([`UI_AUDIT.md`](file:///d:/control/docs/audit/UI_AUDIT.md)).
- **Architecture:** Feature-first GetX (`features/<name>/{bindings,controllers,data,services,views}`). Clean reactive state via `Rx` and `Obx`. Views contain 0 business logic.
- **Refusal Honesty:** Repositories return `Result<T>` and `BlockedFailure` from [`packages/haven_core`](file:///d:/control/packages/haven_core). Screens render [`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart) naming the exact gap.
- **Local Storage:** [`VaultPreferences`](file:///d:/control/apps/haven_app/lib/core/storage/preferences_store.dart) over [`SecureVault`](file:///d:/control/apps/haven_app/lib/core/storage/secure_vault.dart) persists theme settings. This is the only feature with active local persistence.

### 3.2 Android Native & Child Services
- **Structure:** Repo-level Kotlin source in `android_native/child_services/` compiled directly into `apps/haven_app` via Gradle `sourceSets` ([`apps/haven_app/android/app/build.gradle.kts:41`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41)).
- **Channel Surface:** Single MethodChannel `haven.dev/child_device_state` with single method `state.readAll`. Zero EventChannels.
- **Functionality:** Strictly a read-only diagnostics probe. All permissions (location, camera, mic, overlay, usage stats, battery) are undeclared in the manifest and evaluate to `undeclared`. Zero background services, zero command executors, zero location trackers.
- **Verification:** 0 native tests; never run on a physical device.

### 3.3 Supabase Database & SQL
- **Baseline Schema:** 19 tables, 183 columns, 137 constraints, 34 indexes captured in [`A3-staging-load-v1.sql`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql).
- **The Staging Reality:** **0 tables and 0 functions exist in `parent-control-staging`**.
- **The Two Walls:**
  1. *Table Privilege Wall:* Role `authenticated` has SELECT on 14 tables, but INSERT/UPDATE/DELETE grants are absent. Finding F6: `devices` table has 0 privileges for clients.
  2. *RPC Privilege Wall:* All 14 captured public RPCs grant EXECUTE exclusively to `postgres` and `service_role`. Client direct calls return 401/403.
- **Missing Tables:** `push_tokens`, `command_acks`, `consents`, `subscriptions`, `deletion_jobs`.

### 3.4 Supabase Edge Functions
- **Slugs:** 9 Edge Functions in `backend/supabase/functions/` (`auth-bootstrap`, `cron`, `device-command`, `device-policy`, `device-register`, `device-telemetry`, `family-admin`, `pairing`, `remote-session`).
- **Deployment Status:** **0 Edge Functions deployed to staging**.
- **Specification Gaps (`NOT DEPLOYABLE WITHOUT SPEC`):**
  - `device-policy`: Missing allowlist constants V, X, Z ([`device-policy/index.ts:78-80`](file:///d:/control/backend/supabase/functions/device-policy/index.ts#L78-L80)); fails closed with 501.
  - `device-command`: Missing payload schemas for `sync_policy`, `request_usage`, `request_location`, `end_session` ([`device-command/create.ts:163-168`](file:///d:/control/backend/supabase/functions/device-command/create.ts#L163-L168)); fails closed with 501.
- **Secrets:** `SUPABASE_SERVICE_ROLE_KEY`, `PAIRING_HASH_PEPPER`, `CRON_SECRET`, `TURN_HOST`, `TURN_SECRET` are uncreated in staging dashboard.

### 3.5 Firebase & Push Notifications
- **Project Identity:** Staging project `haven-staging` (`haven-staging-46822`) assigned under Gate G2.
- **Registration:** 0 Android apps registered. `google-services.json` is absent.
- **Pipeline Gaps:** `FirebasePushTransport` fails closed. No `push_tokens` table exists in database. No push dispatch Edge Function exists. Admin SDK service account has no private key generated.

### 3.6 Toolchain & Code Quality
- **Line Counts:** 397 hand-written files scanned; 0 violations of the 200-line rule.
- **Static Analysis:** `fvm flutter analyze` reports 0 issues.
- **Toolchain Issue:** System terminal default Flutter is 3.38.8 (Dart 3.10.7), which fails to resolve `sdk: ^3.12.2`. FVM (Flutter 3.44.6) is installed in user cache but missing from system PATH.

---

## 4. MAJOR PROJECT BLOCKERS

1. **Gate G3 / Instrument A3 Unexecuted:** The 19-table database schema has never been loaded into staging.
2. **Instrument A3b Admissibility Unruled:** 17 RLS policies and 8 triggers remain disabled pending owner ruling on function return types.
3. **Instrument A9 Secrets Unprovisioned:** Staging dashboard lacks service-role and cryptographic secrets.
4. **Specification Gaps in Edge Functions:** `device-policy` (V/X/Z allowlists) and `device-command` (4 command types) cannot be deployed without specs.
5. **Gate G2 / Instrument A12-R Unexecuted:** No Android app registered in Firebase; `google-services.json` absent; push notifications completely blocked.
6. **Instrument A13 Unsigned:** Third-Party Auth mapping `A3d` unexecuted; `IDENTITY_MODE` locked.
7. **The Two Walls (RLS & Grant Model):** Client app cannot mutate any database tables directly; all mutations require Edge Functions.
8. **Finding F6 (Devices Table Privilege Deficit):** `devices` table has 0 grants for role `authenticated`, blocking client device reads.
9. **Android Native Service Vacuum:** Child monitoring has no background services, no location updates, and no command execution engines.
10. **Zero Device Hardware Verification:** Kotlin code and built APKs have never been installed or tested on a physical phone.

---

## 5. TOP 10 BIGGEST PENDING TASKS

1. **Task 1: Load Staging Database Schema (Gate G3):** Apply [`A3-staging-load-v1.sql`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql) in `parent-control-staging` browser SQL editor.
2. **Task 2: Rule on Function Admissibility & Load A3b:** Apply [`A3b-functions-triggers-candidate.sql`](file:///d:/control/docs/stage2/migrations/A3b-functions-triggers-candidate.sql) to activate 17 RLS policies and 8 triggers.
3. **Task 3: Provision Staging Edge Secrets (Instrument A9):** Add `SUPABASE_SERVICE_ROLE_KEY`, `PAIRING_HASH_PEPPER`, `CRON_SECRET`, `TURN_HOST`, `TURN_SECRET` in Supabase dashboard.
4. **Task 4: Resolve Specification Gaps:** Define constants V, X, Z for `device-policy` and payload schemas for 4 command types in `device-command`.
5. **Task 5: Deploy the 9 Edge Functions:** Deploy bundles in `docs/stage2/functions/deploy/` to `parent-control-staging`.
6. **Task 6: Wire Firebase Staging (Gate G2 / Instrument A12-R):** Register Android app `com.haven.haven_app` in `haven-staging`, generate `google-services.json`, generate Admin SDK private key, apply `A3c-notification-backend.sql`.
7. **Task 7: Connect Parent App to Staging:** Run Flutter app with `--dart-define` for staging URL and anon key; verify live authentication and onboarding.
8. **Task 8: Implement Android Native Foreground Service:** Build persistent Android `Service` with notification channel and `BOOT_COMPLETED` auto-restart receiver.
9. **Task 9: Implement Real Background Location & Telemetry:** Integrate Google Play Services `FusedLocationProviderClient` to stream coordinates to `device-telemetry/location.ts`.
10. **Task 10: Implement Device Policy & App Blocking:** Build `SYSTEM_ALERT_WINDOW` overlay engine and integrate `DevicePolicyManager.lockNow()` on child phone.

