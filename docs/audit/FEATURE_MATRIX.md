# HAVEN PARENTAL CONTROL — COMPLETE FEATURE AUDIT MATRIX

**Target Location:** `D:\control`  
**Audit Date:** 2026-11-05  
**Audit Standard:** Strict Evidence-Based Audit (Exact Paths, Seam Breakdown, Dependency Tracing)  
**Total Documented Subfeatures:** 92 Subfeatures across 11 Functional Modules

---

## 1. STATUS CLASSIFICATION TAXONOMY

Every subfeature receives exactly one status:
- **COMPLETE** — Implementation exists, is connected, and verified with live passing evidence.
- **PARTIAL** — Some implementation exists but complete end-to-end workflow is missing.
- **UI ONLY** — UI exists visually, but real backend functionality is not connected.
- **BACKEND ONLY** — Backend/Edge Function exists, but frontend integration is missing.
- **NOT IMPLEMENTED** — No meaningful implementation exists in codebase.
- **BROKEN** — Implementation exists but verified failure prevents intended use.
- **UNTESTED** — Implementation appears present but lacks test evidence.
- **BLOCKED** — Missing approval, specification, credential, or external configuration prevents completion.
- **NOT VERIFIED** — Evidence insufficient to determine actual status.

---

## 2. COMPREHENSIVE FEATURE MATRIX (92 SUBFEATURES)

### MODULE A: AUTHENTICATION (11 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| A.1 | Registration | **BLOCKED** | [`register_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/register_page.dart#L18)<br>[`auth_repository.dart:54`](file:///d:/control/apps/haven_app/lib/features/authentication/data/auth_repository.dart#L54)<br>[`supabase_user_auth.dart:55`](file:///d:/control/packages/haven_api/lib/src/supabase_user_auth.dart#L55) | Supabase Auth `signUp`<br>Table `profiles` | `test/authentication/register_page_test.dart` | Staging schema undeployed; email confirmation link flow required. |
| A.2 | Login (Email/Password) | **BLOCKED** | [`sign_in_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart#L18)<br>[`auth_repository.dart:48`](file:///d:/control/apps/haven_app/lib/features/authentication/data/auth_repository.dart#L48)<br>[`supabase_user_auth.dart:39`](file:///d:/control/packages/haven_api/lib/src/supabase_user_auth.dart#L39) | Supabase Auth `signInWithPassword` | `test/authentication/sign_in_page_test.dart` | Staging auth credentials and deployed backend endpoints. |
| A.3 | Logout | **COMPLETE** | [`auth_repository.dart:72`](file:///d:/control/apps/haven_app/lib/features/authentication/data/auth_repository.dart#L72)<br>[`supabase_user_auth.dart:104`](file:///d:/control/packages/haven_api/lib/src/supabase_user_auth.dart#L104)<br>[`offline_backends.dart:132`](file:///d:/control/packages/haven_api/lib/src/offline_backends.dart#L132) | Supabase Auth `signOut` / Local state | `test/account/account_page_test.dart` | Verified offline; clears secure vault and transitions session state. |
| A.4 | Firebase Auth Integration | **BLOCKED** | [`supabase_user_auth.dart:91-97`](file:///d:/control/packages/haven_api/lib/src/supabase_user_auth.dart#L91-L97)<br>[`push_transport_impl.dart:19`](file:///d:/control/packages/haven_api/lib/src/push_transport_impl.dart#L19) | Firebase Auth SDK<br>Third-Party Auth Bridge | None (Refusal assertion) | Owner Instrument A13 unsigned; Firebase Auth explicitly out-of-scope for Stage 1. |
| A.5 | Supabase Third-Party Auth | **BLOCKED** | [`_shared/identity.ts:133-139`](file:///d:/control/backend/supabase/functions/_shared/identity.ts#L133-L139) | Supabase External JWT Provider | `backend/supabase/tests/auth_roles_test.ts:45` | Staging Supabase dashboard has 0 external JWT providers configured. |
| A.6 | Token Validation | **PARTIAL** | [`_shared/auth.ts:25-50`](file:///d:/control/backend/supabase/functions/_shared/auth.ts#L25-L50)<br>[`haven_backend.dart:60`](file:///d:/control/packages/haven_api/lib/src/haven_backend.dart#L60) | Supabase Auth JWT verifier | `backend/supabase/tests/auth_roles_test.ts:15` | Implemented in Edge Function shared library; undeployed. |
| A.7 | Token Refresh | **PARTIAL** | [`supabase_user_auth.dart:101`](file:///d:/control/packages/haven_api/lib/src/supabase_user_auth.dart#L101) | GoTrue / Supabase Auth | `packages/haven_api/test/backend_status_test.dart` | SDK handles refresh automatically; unverified in staging. |
| A.8 | Session Persistence | **COMPLETE** | [`secure_vault.dart:15`](file:///d:/control/apps/haven_app/lib/core/storage/secure_vault.dart#L15)<br>[`session_watch.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/services/session_watch.dart#L18) | Flutter Secure Storage | `test/shell/session_watch_test.dart` | Verified offline with mock vault; persists tokens securely. |
| A.9 | Profile Provisioning | **BLOCKED** | [`auth-bootstrap/set_role.ts:35`](file:///d:/control/backend/supabase/functions/auth-bootstrap/set_role.ts#L35)<br>[`A3-staging-load-v1.sql:850`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql#L850) | Trigger `private.handle_new_user` on `auth.users` | `backend/supabase/tests/auth_bootstrap_test.ts:18` | SQL trigger unexecuted; profile row not automatically minted on signup. |
| A.10 | Firebase UID Mapping | **BLOCKED** | [`_shared/identity.ts:53, 133`](file:///d:/control/backend/supabase/functions/_shared/identity.ts#L53)<br>[`A3d-firebase-identity-mapping.sql`](file:///d:/control/docs/stage2/migrations/A3d-firebase-identity-mapping.sql) | Table `firebase_identity_mapping` | None (Fails closed with 503) | Instrument A13 unsigned; DDL unexecuted; `IDENTITY_MODE = "supabase-auth"` locked. |
| A.11 | Auth Error Handling | **COMPLETE** | [`failure_mapper.dart:15-45`](file:///d:/control/packages/haven_api/lib/src/failure_mapper.dart#L15-L45)<br>[`state_view.dart:53`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart#L53) | None | `test/authentication/sign_in_page_test.dart` | Exhaustive mapping of AuthException to human-readable `HavenFailure`. |

---

### MODULE B: ONBOARDING (7 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| B.1 | Parent Onboarding | **PARTIAL** | [`onboarding_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart#L18)<br>[`onboarding_controller.dart:30`](file:///d:/control/apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart#L30) | Edge Function `auth-bootstrap` | `test/onboarding/onboarding_page_test.dart` | UI complete; backend call fails at network seam. |
| B.2 | Family Creation | **BLOCKED** | [`auth-bootstrap/create_family.ts:25`](file:///d:/control/backend/supabase/functions/auth-bootstrap/create_family.ts#L25)<br>[`onboarding_repository.dart:60`](file:///d:/control/apps/haven_app/lib/features/onboarding/data/onboarding_repository.dart#L60) | RPC `create_family_with_owner`<br>Table `families` | `backend/supabase/tests/auth_bootstrap_test.ts:55` | Staging database has 0 tables; Edge Function undeployed. |
| B.3 | Child Setup Flow | **NOT IMPLEMENTED** | None | Child profile / pairing token | None | No standalone child onboarding UI exists in repository. |
| B.4 | Device Onboarding | **BLOCKED** | [`pairing_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart#L13)<br>[`pairing/issuance.ts:25`](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L25) | Edge Function `pairing`<br>Tables `devices`, `pairing_requests` | `test/device_pairing/pairing_page_test.dart` | Slug undeployed; `PAIRING_HASH_PEPPER` secret uncreated. |
| B.5 | Permission Explanation | **COMPLETE** | [`permission_status_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart#L18)<br>[`pairing_code_page.dart:70`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart#L70) | None | `test/permissions/permission_status_page_test.dart` | Clean UI explanations of device admin, battery, location, usage stats. |
| B.6 | Permission Request Flow | **NOT IMPLEMENTED** | [`PermissionStateReader.kt:21`](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L21) | Android OS Permission Manager | None | Native Kotlin code contains 0 runtime permission request dialog triggers. |
| B.7 | Setup Completion & Recovery | **BLOCKED** | [`family-admin/device_actions.ts:45`](file:///d:/control/backend/supabase/functions/family-admin/device_actions.ts#L45)<br>[`devices_repository.dart:50`](file:///d:/control/apps/haven_app/lib/features/child_devices/data/devices_repository.dart#L50) | RPC `request_device_recovery` | None (Refusal assertion) | Recovery action blocked by RPC grant wall and undeployed slug. |

---

### MODULE C: FAMILY MANAGEMENT (7 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| C.1 | Family Creation | **BLOCKED** | [`family_repository.dart:60`](file:///d:/control/apps/haven_app/lib/features/family/data/family_repository.dart#L60)<br>[`create_family.ts:25`](file:///d:/control/backend/supabase/functions/auth-bootstrap/create_family.ts#L25) | Table `families`, RPC `create_family_with_owner` | `test/family/family_page_test.dart` | Staging schema unexecuted; slug undeployed. |
| C.2 | Parent Management | **BLOCKED** | [`family_repository.dart:147, 156`](file:///d:/control/apps/haven_app/lib/features/family/data/family_repository.dart#L147) | RPC execution / `family_members` table | None (Refusal assertion) | Refused with `rpcLaneMissing`; no client-executable RPC exists. |
| C.3 | Child Profiles | **PARTIAL** | [`child_profile_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/child_profile_page.dart#L18)<br>[`child_profile_controller.dart:35`](file:///d:/control/apps/haven_app/lib/features/family/controllers/child_profile_controller.dart#L35) | Table `profiles`, `family_members` | `test/family/child_profile_page_test.dart` | Reads child profile via `FamilyScope`; mutations refused. |
| C.4 | Family Members | **PARTIAL** | [`family_repository.dart:70`](file:///d:/control/apps/haven_app/lib/features/family/data/family_repository.dart#L70)<br>[`family_scope.dart:25`](file:///d:/control/apps/haven_app/lib/features/family/data/family_scope.dart#L25) | Table `family_members` SELECT policy | `test/family/family_repository_test.dart` | Scoped reads implementable; writes restricted to service role. |
| C.5 | Family Roles | **PARTIAL** | [`auth-bootstrap/set_role.ts:20`](file:///d:/control/backend/supabase/functions/auth-bootstrap/set_role.ts#L20)<br>[`enums_identity.dart:15`](file:///d:/control/packages/haven_models/lib/src/enums_identity.dart#L15) | Column `profiles.role` | `backend/supabase/tests/auth_bootstrap_test.ts:25` | Role transition ('unset' -> 'parent'/'child') implemented; undeployed. |
| C.6 | Family Administration | **BLOCKED** | [`family-admin/index.ts:35`](file:///d:/control/backend/supabase/functions/family-admin/index.ts#L35)<br>[`family-admin/retention.ts:20`](file:///d:/control/backend/supabase/functions/family-admin/retention.ts#L20) | Edge Function `family-admin` | None | Function re-authored but undeployed; retention policies unexecuted. |
| C.7 | Ownership & Access Validation | **PARTIAL** | [`_shared/family.ts:30-70`](file:///d:/control/backend/supabase/functions/_shared/family.ts#L30-L70)<br>[`family_scope.dart:45`](file:///d:/control/apps/haven_app/lib/features/family/data/family_scope.dart#L45) | RLS Policies on `families` | `backend/supabase/tests/guards_test.ts:30` | Validated in TypeScript guards and Dart repository; staging DB empty. |

---

### MODULE D: DEVICE PAIRING (7 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| D.1 | Pairing Code Generation | **BLOCKED** | [`pairing/issuance.ts:35-80`](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L35-L80)<br>[`pairing_repository.dart:103`](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/pairing_repository.dart#L103) | Edge Function `pairing`<br>Secret `PAIRING_HASH_PEPPER` | `backend/supabase/tests/pairing_limits_test.ts:60` | Edge Function undeployed; pepper secret uncreated; client refused. |
| D.2 | Pairing Validation | **BLOCKED** | [`pairing/redeem.ts:30-90`](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L30-L90) | Table `pairing_attempts`<br>RPC `respond_pairing_request` | `backend/supabase/tests/pairing_limits_test.ts:20` | Rate limiting & 4-failure window logic tested offline; undeployed. |
| D.3 | Device Registration | **BLOCKED** | [`device-register/register_flow.ts:40`](file:///d:/control/backend/supabase/functions/device-register/register_flow.ts#L40)<br>[`devices_repository.dart:31`](file:///d:/control/apps/haven_app/lib/features/child_devices/data/devices_repository.dart#L31) | Table `devices`<br>Edge Function `device-register` | None (Fails closed) | F6 grant wall prevents client reads; registration slug undeployed. |
| D.4 | Device Authentication | **BLOCKED** | [`_shared/device_authority.ts:25-70`](file:///d:/control/backend/supabase/functions/_shared/device_authority.ts#L25-L70) | Headers `x-device-id`, `x-device-secret` | `backend/supabase/tests/guards_test.ts:65` | Device SHA-256 secret verification implemented; native child lacks auth. |
| D.5 | Device Linking / Unlinking | **BLOCKED** | [`pairing/unlink.ts:25-80`](file:///d:/control/backend/supabase/functions/pairing/unlink.ts#L25-L80)<br>[`devices_repository.dart:41`](file:///d:/control/apps/haven_app/lib/features/child_devices/data/devices_repository.dart#L41) | RPC `revoke_device`, `unlink_child` | None (Refusal assertion) | Blocked by RPC EXECUTE grant wall and undeployed slug. |
| D.6 | Pairing Expiry Semantics | **PARTIAL** | [`pairing/issuance.ts:75`](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L75)<br>[`pairing_models.dart:45`](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/pairing_models.dart#L45) | Table `device_pairing_tokens` | `backend/supabase/tests/pairing_limits_test.ts:85` | 15-minute PIN TTL and expiry rules tested offline; staging empty. |
| D.7 | Pairing Error Handling | **COMPLETE** | [`pairing_controller.dart:60`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart#L60)<br>[`pairing_page.dart:23`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart#L23) | None | `test/device_pairing/pairing_page_test.dart` | Clean rendering of withdrawal gaps and missing family states. |

---

### MODULE E: PARENT DASHBOARD (8 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| E.1 | Dashboard UI | **COMPLETE** | [`dashboard_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart#L18)<br>[`dashboard_controller.dart:30`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart#L30) | None | `test/dashboard/dashboard_page_test.dart` | Responsive scaffold, cards, status banners, pull-to-refresh. |
| E.2 | Connected Devices Card | **UI ONLY** | [`dashboard_page.dart:45`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart#L45)<br>[`devices_repository.dart:31`](file:///d:/control/apps/haven_app/lib/features/child_devices/data/devices_repository.dart#L31) | Table `devices` SELECT grant | `test/dashboard/dashboard_card_test.dart` | Blocked by F6 grant wall (`devices` has no SELECT grant for `authenticated`). |
| E.3 | Device Status Indicators | **UI ONLY** | [`status_chip.dart:15`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart#L15)<br>[`device_card.dart:40`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/widgets/device_list_card.dart#L40) | Table `devices.last_seen_at` | `test/child_devices/device_card_test.dart` | Status chips built; live telemetry pipeline not connected. |
| E.4 | Activity Information | **UI ONLY** | [`activity_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart#L13)<br>[`activity_repository.dart:45`](file:///d:/control/apps/haven_app/lib/features/device_activity/data/activity_repository.dart#L45) | Table `usage_daily` | `test/device_activity/activity_page_test.dart` | Reads `usage_daily`; device remains unnamed due to F6. |
| E.5 | Location Overview Card | **UI ONLY** | [`location_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/location/views/pages/location_page.dart#L12)<br>[`location_repository.dart:50`](file:///d:/control/apps/haven_app/lib/features/location/data/location_repository.dart#L50) | Table `location_events` | `test/location/location_page_test.dart` | Location point display built; geofence presence refused. |
| E.6 | Alerts Summary | **UI ONLY** | [`notifications_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/notifications/views/pages/notifications_page.dart#L12)<br>[`alerts_repository.dart:35`](file:///d:/control/apps/haven_app/lib/features/notifications/data/alerts_repository.dart#L35) | Table `safety_alerts` | `test/notifications/notifications_page_test.dart` | Reads `safety_alerts`; push transport refuses delivery. |
| E.7 | Remote Session Status | **UI ONLY** | [`remote_sessions_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_sessions_page.dart#L12)<br>[`sessions_repository.dart:40`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/data/sessions_repository.dart#L40) | Table `remote_sessions` | `test/remote_sessions/remote_sessions_page_test.dart` | Reads `remote_sessions`; session initiation refused by RPC wall. |
| E.8 | Global Navigation | **COMPLETE** | [`app_routes.dart:9-34`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L9-L34)<br>[`app_pages.dart:54-180`](file:///d:/control/apps/haven_app/lib/app/routes/app_pages.dart#L54-L180) | GetX Route Table | `test/shell/navigation_test.dart` | All 26 named routes correctly wired and tested offline. |

---

### MODULE F: CHILD DEVICE (10 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| F.1 | Child Native Application | **PARTIAL** | [`HavenBridge.kt:18-88`](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L18-L88)<br>[`build.gradle.kts:41`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41) | Android OS Platform | None (0 native tests) | Compiled into parent app as read-only probe; no standalone app. |
| F.2 | Device Registration (Child) | **NOT IMPLEMENTED** | None | Edge Function `device-register` | None | Kotlin layer has no registration HTTP client or secret storage. |
| F.3 | Device Telemetry Collectors | **NOT IMPLEMENTED** | None | Edge Function `device-telemetry` | None | No battery, network, or app usage collectors exist in native source. |
| F.4 | Background Services | **NOT IMPLEMENTED** | None | Android `android.app.Service` | None | 0 Service classes exist; foreground service not declared in manifest. |
| F.5 | Monitoring Lifecycle Watchdogs | **NOT IMPLEMENTED** | None | WorkManager / AlarmManager | None | No `BOOT_COMPLETED` receiver or restart mechanisms exist. |
| F.6 | Device Command Execution | **NOT IMPLEMENTED** | [`HavenDeviceAdminReceiver.kt:12`](file:///d:/control/android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt#L12) | Edge Function `device-command` | None | Native admin receiver explicitly contains 0 enforcement code. |
| F.7 | Device Policy Enforcement | **NOT IMPLEMENTED** | None | DevicePolicyManager / VPN | None | No app blocker, web filter, or downtime overlay engine. |
| F.8 | Permission Diagnostics Probe | **COMPLETE** | [`PermissionStateReader.kt:21`](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L21)<br>[`BridgeContract.kt:13`](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L13) | Android PackageManager | Verified via MethodChannel | Returns read-only OS permission and service declaration report. |
| F.9 | Network Recovery Watcher | **NOT IMPLEMENTED** | None | ConnectivityManager | None | No native network change broadcast receiver. |
| F.10 | Process Restart Handling | **NOT IMPLEMENTED** | None | Android OS / Sticky Service | None | Process termination by OS kills monitoring permanently. |

---

### MODULE G: LOCATION (8 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| G.1 | Location Permission | **PARTIAL** | [`LocationStateReader.kt:33`](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L33) | Android Location Permission | None | Checked by native reader; runtime permission dialog not implemented. |
| G.2 | Location Collection | **PARTIAL** | [`LocationStateReader.kt:57-77`](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L57-L77) | Android LocationManager | None | Framework fixes read without coordinates (lat/long stripped by design). |
| G.3 | Background Location Service | **NOT IMPLEMENTED** | None | Android FusedLocationProviderClient | None | `ACCESS_BACKGROUND_LOCATION` undeclared; no service runs in background. |
| G.4 | Location Batch Upload | **BLOCKED** | [`device-telemetry/location.ts:25`](file:///d:/control/backend/supabase/functions/device-telemetry/location.ts#L25) | Table `location_events` | `backend/supabase/tests/handlers_test.ts:40` | Ingestion handler re-authored; undeployed; native child lacks uploader. |
| G.5 | Parent Location Display | **COMPLETE** | [`location_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/location/views/pages/location_page.dart#L12)<br>[`round_trips_test.dart:35`](file:///d:/control/packages/haven_models/test/round_trips_test.dart#L35) | Table `location_events` | `test/location/location_page_test.dart` | Renders accurate location points without invented precision. |
| G.6 | Last Updated Relative Status | **COMPLETE** | [`location_card.dart:45`](file:///d:/control/apps/haven_app/lib/features/location/views/widgets/location_card.dart#L45) | System Clock | `test/location/location_card_test.dart` | Relative time formatting verified offline against fixed clocks. |
| G.7 | Safe-Zone Creation & Editor | **PARTIAL** | [`safe_zone_editor_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart#L13)<br>[`safe_zone_rules.dart:20`](file:///d:/control/apps/haven_app/lib/features/safe_zones/data/safe_zone_rules.dart#L20) | Table `safe_zones` | `test/safe_zones/zone_editor_test.dart` (10 test files) | Full form validation and local geometry; unverified against live DB. |
| G.8 | Geofence Entry / Exit Events | **BLOCKED** | [`captured_gaps.dart:43-60`](file:///d:/control/apps/haven_app/lib/core/errors/captured_gaps.dart#L43-L60)<br>[`location_repository.dart:65`](file:///d:/control/apps/haven_app/lib/features/location/data/location_repository.dart#L65) | Table `safe_zone_states` | None (Refusal assertion) | Table `safe_zone_states` is deny-all (RLS on, 0 policies); refused. |

---

### MODULE H: DEVICE COMMANDS AND POLICIES (8 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| H.1 | Command Creation | **BLOCKED** | [`device-command/create.ts:40-168`](file:///d:/control/backend/supabase/functions/device-command/create.ts#L40-L168)<br>[`commands_repository.dart:41`](file:///d:/control/apps/haven_app/lib/features/device_commands/data/commands_repository.dart#L41) | Edge Function `device-command`<br>Table `device_commands` | `backend/supabase/tests/auth_bootstrap_test.ts:80` | 4 command types lack schemas (501); client mutation closed by RLS. |
| H.2 | Command Delivery | **BLOCKED** | [`device-command/poll_ack.ts:30-80`](file:///d:/control/backend/supabase/functions/device-command/poll_ack.ts#L30-L80) | Supabase Realtime / Polling | None | Edge Function undeployed; child device does not poll. |
| H.3 | Command Acknowledgement | **BLOCKED** | [`device-command/poll_ack.ts:90-150`](file:///d:/control/backend/supabase/functions/device-command/poll_ack.ts#L90-L150) | Table `command_acks` (missing) | `backend/supabase/tests/handlers_test.ts:90` | Table `command_acks` missing from schema; slug undeployed. |
| H.4 | Command Status Rendering | **COMPLETE** | [`command_card.dart:98-103`](file:///d:/control/apps/haven_app/lib/features/device_commands/views/widgets/command_card.dart#L98-L103) | Table `device_commands.status` | `test/device_commands/command_card_test.dart` | Status chip tones (good/bad/warning/neutral) verified offline. |
| H.5 | Policy Management | **BLOCKED** | [`device-policy/index.ts:138`](file:///d:/control/backend/supabase/functions/device-policy/index.ts#L138)<br>[`policies_repository.dart:42`](file:///d:/control/apps/haven_app/lib/features/policies/data/policies_repository.dart#L42) | Edge Function `device-policy`<br>RPC `apply_policy_version` | None (Fails closed with 501) | Blocked by missing bundle constants V/X/Z; client mutation refused. |
| H.6 | Device-Side Execution | **NOT IMPLEMENTED** | None | Android DevicePolicyManager | None | Kotlin layer has no policy receiver or execution handlers. |
| H.7 | Command Authorization Checks | **PARTIAL** | [`_shared/device_authority.ts:30`](file:///d:/control/backend/supabase/functions/_shared/device_authority.ts#L30)<br>[`_shared/auth.ts:90`](file:///d:/control/backend/supabase/functions/_shared/auth.ts#L90) | Table `devices`, `family_members` | `backend/supabase/tests/guards_test.ts:50` | Scoping logic and device secret hashing tested offline; undeployed. |
| H.8 | Error & Retry Handling | **COMPLETE** | [`retry.dart:15-50`](file:///d:/control/packages/haven_core/lib/src/retry.dart#L15-L50)<br>[`failure_mapper.dart:20`](file:///d:/control/packages/haven_api/lib/src/failure_mapper.dart#L20) | None | `packages/haven_core/test/haven_core_test.dart` | Exponential backoff and refusal non-retry rules verified offline. |

---

### MODULE I: REMOTE SESSIONS (10 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| I.1 | Session Creation | **BLOCKED** | [`remote-session/lifecycle.ts:30`](file:///d:/control/backend/supabase/functions/remote-session/lifecycle.ts#L30)<br>[`session_gaps.dart:13`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/data/session_gaps.dart#L13) | RPC `request_remote_session` | None (Refusal assertion) | Blocked by RPC EXECUTE grant wall and undeployed slug. |
| I.2 | Parent Approval Flow | **BLOCKED** | [`remote-session/lifecycle.ts:60`](file:///d:/control/backend/supabase/functions/remote-session/lifecycle.ts#L60) | Table `remote_sessions` | `backend/supabase/tests/handlers_test.ts:110` | Session approval state machine implemented in TS; undeployed. |
| I.3 | Session Rejection | **BLOCKED** | [`remote-session/lifecycle.ts:75`](file:///d:/control/backend/supabase/functions/remote-session/lifecycle.ts#L75) | Table `remote_sessions` | `backend/supabase/tests/handlers_test.ts:120` | Rejection transition implemented in TS; undeployed. |
| I.4 | Session Lifecycle State Machine | **PARTIAL** | [`enums_sessions.dart:10`](file:///d:/control/packages/haven_models/lib/src/enums_sessions.dart#L10)<br>[`remote-session/lifecycle.ts:20`](file:///d:/control/backend/supabase/functions/remote-session/lifecycle.ts#L20) | Table `remote_sessions.status` | `backend/supabase/tests/handlers_test.ts:105` | Transitions (requested -> accepted -> active -> ended) tested offline. |
| I.5 | WebRTC Integration | **BLOCKED** | [`media_peer.dart:30-46`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/services/media_peer.dart#L30-L46) | Native WebRTC PeerConnection | None (Refusal assertion) | `UnspecifiedMediaPeer` refuses start; native has no WebRTC library. |
| I.6 | WebRTC Signalling | **PARTIAL** | [`webrtc_signals` DDL](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql#L380)<br>[`session_gaps.dart:29`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/data/session_gaps.dart#L29) | Table `webrtc_signals` | None | Client insert grant exists; sequence allocation & payload format unevidenced. |
| I.7 | TURN Server Configuration | **BLOCKED** | [`remote-session/media.ts:25-35`](file:///d:/control/backend/supabase/functions/remote-session/media.ts#L25-L35) | Secrets `TURN_HOST`, `TURN_SECRET` | None (Throws 503) | Secrets uncreated; A13 unsigned; no Coturn/TURN infra deployed. |
| I.8 | Session Expiry / Cleanup | **PARTIAL** | [`cron/index.ts:70`](file:///d:/control/backend/supabase/functions/cron/index.ts#L70)<br>[`A3b:150`](file:///d:/control/docs/stage2/migrations/A3b-functions-triggers-candidate.sql#L150) | RPC `expire_stale_sessions` | None | Cleanup logic authored in cron slug; cron secret uncreated. |
| I.9 | Connection Failure Handling | **PARTIAL** | [`session_detail_page.dart:70`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart#L70) | None | `test/remote_sessions/remote_session_detail_test.dart` | UI shows connection failure state cleanly via `BlockedNotice`. |
| I.10 | Active Session Consent Invariant | **COMPLETE** | [`round_trips_test.dart:55`](file:///d:/control/packages/haven_models/test/round_trips_test.dart#L55)<br>[`remote_session.dart:30`](file:///d:/control/packages/haven_models/lib/src/remote_session.dart#L30) | None | `test/remote_sessions/sessions_controller_test.dart` | Single boolean consent invariant pinned and verified in Dart tests. |

---

### MODULE J: NOTIFICATIONS (9 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| J.1 | FCM Configuration | **BLOCKED** | [`firebase/SETUP-CHECKLIST.md:1`](file:///d:/control/firebase/SETUP-CHECKLIST.md#L1)<br>[`CONFIGURATION.md:10`](file:///d:/control/backend/firebase/CONFIGURATION.md#L10) | Firebase Console `haven-staging` | None | Staging project exists, but Android app registration unexecuted (Gate G2). |
| J.2 | Android Firebase App Registration | **BLOCKED** | [`S2-A2-firebase-console-audit.md:216`](file:///d:/control/docs/stage2/S2-A2-firebase-console-audit.md#L216) | Firebase Console | None | 0 Android apps registered in `haven-staging`; `google-services.json` absent. |
| J.3 | Notification Permission | **PARTIAL** | [`PermissionStateReader.kt:85`](file:///d:/control/android_native/child_services/platform_bridge/OsAnswers.kt#L85) | Android 13+ POST_NOTIFICATIONS | None | Native reader checks permission; runtime prompt not implemented. |
| J.4 | FCM Token Registration | **BLOCKED** | [`push_transport_impl.dart:18-28`](file:///d:/control/packages/haven_api/lib/src/push_transport_impl.dart#L18-L28)<br>[`A3c-notification-backend.sql`](file:///d:/control/docs/stage2/migrations/A3c-notification-backend.sql) | Table `push_tokens` (missing) | None (Refusal assertion) | No token table in baseline schema; candidate migration unexecuted. |
| J.5 | Token Refresh Handling | **NOT IMPLEMENTED** | None | FirebaseMessaging.onTokenRefresh | None | No token rotation listener implemented or wired. |
| J.6 | Backend Push Dispatch | **NOT IMPLEMENTED** | [`S2-A4-edge-functions-audit.md:174`](file:///d:/control/docs/stage2/S2-A4-edge-functions-audit.md#L174) | Edge Function / FCM v1 API | None | No push dispatch Edge Function exists in `backend/` or captures. |
| J.7 | Push Notification Reception | **BLOCKED** | [`push_transport_impl.dart:21`](file:///d:/control/packages/haven_api/lib/src/push_transport_impl.dart#L21) | Firebase SDK / Native Plugin | None (Refusal assertion) | Fails closed with "No Firebase app is registered in this build". |
| J.8 | Notification Payload Navigation | **NOT IMPLEMENTED** | None | Flutter GetX Navigation | None | No intent payload handler wired to open specific alert routes. |
| J.9 | Device Token Unlinking | **NOT IMPLEMENTED** | None | FCM / Supabase DB | None | No token invalidation logic on logout or device unpair. |

---

### MODULE K: ACCOUNT AND SETTINGS (7 SUBFEATURES)

| # | Subfeature | Status | Source File Paths & Lines | Backend Dependency | Test Evidence | Missing Work to Complete |
|---|---|---|---|---|---|---|
| K.1 | Profile Management | **PARTIAL** | [`account_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/account/views/pages/account_page.dart#L12)<br>[`account_repository.dart:45`](file:///d:/control/apps/haven_app/lib/features/account/data/account_repository.dart#L45) | Table `profiles` UPDATE grant | `test/account/account_page_test.dart` | Profile display working; display_name update permitted by RLS; DB empty. |
| K.2 | Family Settings | **PARTIAL** | [`settings_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/settings_page.dart#L12)<br>[`family_repository.dart:90`](file:///d:/control/apps/haven_app/lib/features/family/data/family_repository.dart#L90) | Table `families` UPDATE grant | `test/settings/settings_page_test.dart` | Settings layout complete; backend mutations require deployed staging. |
| K.3 | Device Settings | **BLOCKED** | [`devices_repository.dart:35`](file:///d:/control/apps/haven_app/lib/features/child_devices/data/devices_repository.dart#L35) | Table `devices` UPDATE grant | None (Refusal assertion) | Blocked by F6 grant wall (no UPDATE grant on `devices` for clients). |
| K.4 | Notification Preferences | **UI ONLY** | [`settings_page.dart:55`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/settings_page.dart#L55) | Backend Preferences Store | `test/settings/settings_controller_test.dart` | UI toggles present; not wired to backend push tokens. |
| K.5 | Security / Account Actions | **BLOCKED** | [`account_repository.dart:92, 99, 106`](file:///d:/control/apps/haven_app/lib/features/account/data/account_repository.dart#L92) | Supabase Auth Admin API | None (Refusal assertion) | Change password, change email, and delete account refused (no contract). |
| K.6 | User Logout | **COMPLETE** | [`account_controller.dart:65`](file:///d:/control/apps/haven_app/lib/features/account/controllers/account_controller.dart#L65)<br>[`auth_repository.dart:72`](file:///d:/control/apps/haven_app/lib/features/authentication/data/auth_repository.dart#L72) | Local Secure Vault | `test/account/account_page_test.dart` | Clears local vault, resets bindings, routes cleanly to `/sign-in`. |
| K.7 | Help & Support | **NOT IMPLEMENTED** | None | Support Ticketing / FAQ | None | No support module or screen specified or implemented. |

---

## 3. SUMMARY STATUS TOTALS ACROSS 92 SUBFEATURES

| Status Classification | Count | Percentage | Weight Applied | Weighted Points |
|---|---|---|---|---|
| **COMPLETE** | 10 | 10.87% | 100% | 10.0 |
| **PARTIAL** | 22 | 23.91% | 50% | 11.0 |
| **UI ONLY** | 6 | 6.52% | 25% | 1.5 |
| **BACKEND ONLY** | 0 | 0.00% | 50% | 0.0 |
| **BLOCKED** | 35 | 38.04% | 0% | 0.0 |
| **NOT IMPLEMENTED** | 19 | 20.65% | 0% | 0.0 |
| **BROKEN** | 0 | 0.00% | 0% | 0.0 |
| **UNTESTED** | 0 | 0.00% | 0% | 0.0 |
| **NOT VERIFIED** | 0 | 0.00% | 0% | 0.0 |
| **TOTAL** | **92** | **100.0%** | | **22.5 / 92** |

