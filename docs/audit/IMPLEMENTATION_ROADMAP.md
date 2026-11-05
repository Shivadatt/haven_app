# HAVEN PARENTAL CONTROL — IMPLEMENTATION ROADMAP

**Target Location:** `D:\control`  
**Audit Date:** 2026-11-05  
**Document Standard:** Strict Evidence-Based Engineering Roadmap  
**Dependency Flow:** Prerequisite Gates → Schema & Secrets → Edge Deployment → Client Wiring → Native Child Service

---

## 1. CRITICAL DEPENDENCY GRAPH & EXECUTION PHASES

```
[ Phase 0: Approvals & Staging Infra ]
  │
  ├─► 0.1 Toolchain: Add FVM (Flutter 3.44.6) to system PATH
  ├─► 0.2 Gate G3: Load A3 DDL into Supabase Staging (dzonzgngwxclhfnvxtvu)
  ├─► 0.3 Admissibility Ruling: Load A3b Functions & Triggers DDL
  ├─► 0.4 Gate G7 / A9: Provision 6 Edge Secrets in Staging Dashboard
  ├─► 0.5 Spec Resolutions: Provide Policy V/X/Z keys & 4 missing command schemas
  ├─► 0.6 Edge Deployment: Deploy 9 Edge Function slugs (A7-R / A8-R)
  ├─► 0.7 Gate G2 / A12-R: Register Android App in haven-staging & fetch google-services.json
  ├─► 0.8 Load A3c (Push Tokens) & A3d (Identity Mapping, A13) DDL
  │
[ Phase 1: Parent App Live Integration ]
  │
  ├─► 1.1 Wire --dart-define build flags for Staging Supabase URL & Anon Key
  ├─► 1.2 Verify End-to-End Auth: Sign-Up, Email Confirmation, Sign-In, Session Watch
  ├─► 1.3 Verify Onboarding & Family Creation (auth-bootstrap slug)
  ├─► 1.4 Wire Live Data Streams: Family, Child Profiles, Activity, Location Points
  │
[ Phase 2: Android Native Child Transformation ]
  │
  ├─► 2.1 Manifest Updates: Declare Foreground Service, Location, UsageStats, Overlays
  ├─► 2.2 Implement Persistent Foreground Service with Notification Channel
  ├─► 2.3 Implement BootReceiver (BOOT_COMPLETED) & WorkManager Watchdogs
  ├─► 2.4 Implement FusedLocationProviderClient background updates
  ├─► 2.5 Implement Child Native Registration & Encrypted Credential Vault
  ├─► 2.6 Expand MethodChannel & EventChannel for Async Telemetry & Commands
  │
[ Phase 3: Core Safety Feature Delivery ]
  │
  ├─► 3.1 Device Pairing Flow (PIN generation, redemption, rate limits)
  ├─► 3.2 Device Policy Enforcement (App lock overlay, DevicePolicyManager screen lock)
  ├─► 3.3 Device Command Pipeline (Polling, execution, acknowledgment)
  ├─► 3.4 Geofence Event Pipeline (Safe zone entry/exit triggers)
  ├─► 3.5 Push Notification Pipeline (FCM token registration, backend dispatch)
  ├─► 3.6 Remote WebRTC Media Sessions (Coturn deployment, TURN auth, WebRTC streaming)
```

---

## 2. PHASE 0: APPROVALS, SPECIFICATIONS & INFRASTRUCTURE (P0 - IMMEDIATE BLOCKERS)

### Task 0.1: Toolchain Normalization
- **Priority:** P0 (Build / Test prerequisite)
- **Problem:** Terminal runs Flutter 3.38.8 / Dart 3.10.7, causing pub resolution failure on `sdk: ^3.12.2`.
- **Action:** Add `C:\Users\ASUS\fvm\versions\3.44.6\bin` to user PATH or use FVM wrapper.
- **Acceptance Criteria:** `flutter --version` outputs Flutter 3.44.6; `dart pub get` succeeds across all packages.

### Task 0.2: Gate G3 — Staging Schema DDL Load
- **Priority:** P0 (Database blocker)
- **Source:** [`docs/stage2/migrations/A3-staging-load-v1.sql`](file:///d:/control/docs/stage2/migrations/A3-staging-load-v1.sql) (1,575 lines)
- **Action:** Owner pastes DDL into Supabase Browser SQL Editor for `parent-control-staging` (`dzonzgngwxclhfnvxtvu`).
- **Acceptance Criteria:** 19 tables created, 137 constraints active, 4 initial RLS policies enabled.

### Task 0.3: Admissibility Ruling & Staging Functions Load
- **Priority:** P0 (RLS & Triggers blocker)
- **Source:** [`docs/stage2/migrations/A3b-functions-triggers-candidate.sql`](file:///d:/control/docs/stage2/migrations/A3b-functions-triggers-candidate.sql) (959 lines)
- **Action:** Owner issues formal ruling that call-site + body derivation of function return types is admissible; executes DDL in staging SQL editor.
- **Acceptance Criteria:** 9 captured functions created; 17 commented-out RLS policies unblocked and active; 8 triggers active (including `handle_new_user` on `auth.users`).

### Task 0.4: Gate G7 / Instrument A9 — Edge Secrets Provisioning
- **Priority:** P0 (Edge Function execution blocker)
- **Source:** [`backend/supabase/config/environment.md`](file:///d:/control/backend/supabase/config/environment.md)
- **Action:** Owner enters required secrets via Supabase Dashboard (`Settings -> Vault / Secrets`):
  1. `SUPABASE_SERVICE_ROLE_KEY` (service role JWT)
  2. `PAIRING_HASH_PEPPER` (cryptographic random string)
  3. `CRON_SECRET` (≥ 16 character token)
  4. `TURN_HOST` (TURN server hostname)
  5. `TURN_SECRET` (TURN HMAC-SHA1 shared secret)
- **Acceptance Criteria:** All Edge Functions load secrets without throwing `503 server_misconfigured`.

### Task 0.5: Specification Gap Resolutions
- **Priority:** P0 (Slug deployment blocker)
- **Items:**
  1. **Policy Key Allowlist:** Supply constants `TOP_LEVEL_POLICY_KEYS`, `SUB_OBJECT_KEYS`, `APP_RULE_KEYS` for [`device-policy/index.ts:78-80`](file:///d:/control/backend/supabase/functions/device-policy/index.ts#L78-L80).
  2. **Command Schemas:** Define valid payload schemas for `sync_policy`, `request_usage`, `request_location`, `end_session` for [`device-command/create.ts:163-168`](file:///d:/control/backend/supabase/functions/device-command/create.ts#L163-L168).
- **Acceptance Criteria:** Both files remove `NOT DEPLOYABLE WITHOUT SPEC` labels; tests in `backend/supabase/tests/auth_bootstrap_test.ts` pass with live allowlists.

### Task 0.6: Edge Function Deployment (Instruments A7-R & A8-R)
- **Priority:** P0 (Backend API blocker)
- **Source:** [`docs/stage2/functions/deploy/*.bundle.ts`](file:///d:/control/docs/stage2/functions/deploy/)
- **Action:** Deploy all 9 Edge Function slugs via Supabase CLI or Dashboard:
  `auth-bootstrap`, `cron`, `device-command`, `device-policy`, `device-register`, `device-telemetry`, `family-admin`, `pairing`, `remote-session`.
- **Acceptance Criteria:** All 9 endpoints return valid JSON envelopes (`{ ok: true }` / `{ ok: false, error: ... }`) upon HTTP POST.

### Task 0.7: Gate G2 / Instrument A12-R — Firebase FCM Project Wiring
- **Priority:** P0 (Push notification blocker)
- **Source:** [`firebase/SETUP-CHECKLIST.md`](file:///d:/control/firebase/SETUP-CHECKLIST.md)
- **Action:**
  1. Register Android app `com.haven.haven_app` in `haven-staging-46822`.
  2. Download `google-services.json` to `apps/haven_app/android/app/google-services.json`.
  3. Apply `com.google.gms.google-services` plugin in `apps/haven_app/android/app/build.gradle.kts`.
  4. Generate Private Key for Admin SDK service account in Firebase Console.
  5. Apply candidate migration [`A3c-notification-backend.sql`](file:///d:/control/docs/stage2/migrations/A3c-notification-backend.sql) to staging database.
- **Acceptance Criteria:** Device tokens persist to `device_push_tokens` table; `FirebasePushTransport` initializes without refusal.

---

## 3. PHASE 1: PARENT APPLICATION LIVE INTEGRATION (P1)

### Task 1.1: Environment Configuration Wiring
- **Action:** Run Flutter app with staging defines:
  ```bash
  flutter run --dart-define=SUPABASE_URL=https://dzonzgngwxclhfnvxtvu.supabase.co \
              --dart-define=SUPABASE_ANON_KEY=<staging-anon-key> \
              --dart-define=HAVEN_ENVIRONMENT=staging
  ```
- **Acceptance Criteria:** [`HavenConfig.missingDefines()`](file:///d:/control/apps/haven_app/lib/core/constants/haven_config.dart) returns empty; `Supabase.initialize` runs; `AboutPage` displays "Configured (Staging)".

### Task 1.2: End-to-End Authentication Verification
- **Action:** Register new parent account via `RegisterPage`; verify email link; log in via `SignInPage`.
- **Acceptance Criteria:** User session persists across app restarts; `profiles` row is created with role `unset`.

### Task 1.3: Onboarding & Family Creation
- **Action:** Enter family name in `OnboardingPage`; complete setup.
- **Acceptance Criteria:** `auth-bootstrap` slug assigns role `parent` and creates family row; user navigates to `DashboardPage`.

### Task 1.4: Realtime Change Feed Integration
- **Action:** Subscribe `ChangeFeed` to `device_commands`, `location_events`, `remote_sessions`, `safety_alerts`.
- **Acceptance Criteria:** Data mutations in staging database reflect reactively in Flutter UI without manual pull-to-refresh.

---

## 4. PHASE 2: ANDROID NATIVE CHILD AGENT TRANSFORMATION (P1 - P2)

### Task 2.1: Native Permissions Declaration
- **Source:** [`apps/haven_app/android/app/src/main/AndroidManifest.xml`](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml)
- **Action:** Add permissions:
  ```xml
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
  <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
  ```
- **Acceptance Criteria:** `PermissionStateReader.kt` evaluates permissions as declared.

### Task 2.2: Native Foreground Monitoring Service
- **Action:** Create `ChildMonitorService : Service()`:
  - Create persistent low-priority NotificationChannel.
  - Call `startForeground(NOTIFICATION_ID, notification)` in `onStartCommand()`.
  - Return `START_STICKY`.
- **Acceptance Criteria:** Android OS maintains process priority; monitoring survives app task swipe-away.

### Task 2.3: Boot & Watchdog Auto-Restart
- **Action:**
  - Create `HavenBootReceiver : BroadcastReceiver()` listening to `ACTION_BOOT_COMPLETED`.
  - Schedule periodic WorkManager worker (`PeriodicWorkRequestBuilder<WatchdogWorker>(15, TimeUnit.MINUTES)`).
- **Acceptance Criteria:** Service launches immediately upon device reboot.

### Task 2.4: Real-Time Background Location Tracking
- **Action:** Integrate Google Play Services `FusedLocationProviderClient`:
  - Request updates every 5 minutes / 100 meters.
  - Upload batch fixes via `device-telemetry/location.ts` endpoint using `x-device-id` / `x-device-secret`.
- **Acceptance Criteria:** Accurate coordinates ingest into `location_events` table; parent `LocationPage` renders child position.

### Task 2.5: Native Registration & Secure Storage
- **Action:** Store issued `deviceId` and `deviceSecret` in Android `EncryptedSharedPreferences`.
- **Acceptance Criteria:** Device authenticates telemetry and command polling without user intervention.

### Task 2.6: MethodChannel & EventChannel Expansion
- **Action:** Add channels for commands, policies, and async alerts (`haven.dev/child_commands`, `haven.dev/child_events`).
- **Acceptance Criteria:** Flutter layer can send command acknowledgments and policy changes to native layer.

---

## 5. PHASE 3: CORE SAFETY FEATURE COMPLETION (P2 - P3)

### Task 3.1: Device Pairing Flow
- **Acceptance Criteria:** Parent generates 6-digit PIN on `PairingPage`; child enters PIN; `pairing/redeem.ts` binds device to family and provisions `devices` row.

### Task 3.2: App Blocking & Device Lock
- **Action:**
  - Hook `DevicePolicyManager.lockNow()` in `HavenDeviceAdminReceiver` on `force_lock` command.
  - Implement full-screen overlay window using `SYSTEM_ALERT_WINDOW` when blocked app enters foreground.
- **Acceptance Criteria:** Blocked apps cannot be opened; remote lock command locks device screen immediately.

### Task 3.3: Geofence Presence Pipeline
- **Action:** Author trigger or edge worker to evaluate incoming `location_events` against `safe_zones` and update `safe_zone_states`.
- **Acceptance Criteria:** Safe zone entry/exit events generate rows in `safety_alerts`; parent receives geofence push alert.

### Task 3.4: Push Notification Sending Engine
- **Action:** Author `push-dispatch` Edge Function integrating Firebase Admin SDK:
  - On `safety_alerts` INSERT trigger, dispatch FCM message to parent devices.
- **Acceptance Criteria:** Parent phone receives push notifications when child exits safe zone or requests remote session.

### Task 3.5: Remote Sessions WebRTC Media
- **Action:**
  - Deploy Coturn server with static auth secret matching `TURN_SECRET`.
  - Implement Flutter WebRTC peer connection (`flutter_webrtc`) in `RemoteSessionDetailPage`.
  - Implement native camera/screen capture streamer on child phone with visible consent banner.
- **Acceptance Criteria:** Two-way video/audio connects successfully between parent and child with active consent indicator.

---

## 6. DEFINITION OF DONE FOR FULL APPLICATION

A feature is strictly **COMPLETE** only when:
1. Schema objects and RLS policies are verified active in staging.
2. Edge Functions are deployed, tested, and responding with 200 OK.
3. Native Android services run reliably in the background across reboots.
4. Flutter UI executes real mutations, receives live server responses, and displays accurate data.
5. Automated integration tests verify the end-to-end flow on physical Android hardware.
6. All source files remain under the strict 200-line limit.

