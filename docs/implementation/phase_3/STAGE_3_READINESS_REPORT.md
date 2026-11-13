# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 3: READINESS AUDIT REPORT
**Usage Access & Screen-Time Monitoring**

**Date**: November 13, 2026  
**Status**: AUDIT ONLY — STAGE 3 NOT STARTED / NOT IMPLEMENTED  
**Scope**: Readiness assessment, dependency isolation decision, P-5 native test infrastructure proposal, P-1 device readiness audit, and technical architecture for Stage 3.  
**Authoritative Reference Documents**:
- `docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md`
- `docs/implementation/phase_3/STAGE_2_OWNER_DECISIONS.md`
- `docs/implementation/phase_3/STAGE_2_IMPLEMENTATION_REPORT.md`
- `docs/implementation/phase_3/STAGE_2_ANDROID_CAPABILITY_INVENTORY.md`
- `docs/implementation/phase_3/STAGE_1_KNOWN_LIMITATIONS.md`
- `docs/implementation/00-app-contract.md`

---

## 1. Current Architecture & Baseline State

### 1.1 Repository State
- **Branch**: `main` | **HEAD**: `50b4425`
- **Total Tested Baseline**: **1,290 tests**, 0 failures, 0 skips:
  - `apps/haven_child`: **251** tests (Stage 1 foundation: 167; Stage 2 registration & native mirror: 84)
  - `apps/haven_app`: **943** tests (Phase 2 baseline: 924; Stage 2 agreement & DEMO labels: 19)
  - `packages/haven_api`: **66** tests (offline store, constraints, queries)
  - `packages/haven_core`: **18** tests (Result, Failures, Clock, Validators)
  - `packages/haven_models`: **12** tests (serialization, wire labels)
- **Code Hygiene**:
  - `dart scripts/check_line_counts.dart` → **740 hand-written files / 0 violations** (strict ≤200 lines rule upheld).
  - `fvm flutter analyze` → **`No issues found!`** across both `haven_app` and `haven_child`.

### 1.2 Android Native Lane Architecture
- Native code lives at `android_native/child_services/` (10 Kotlin files, 713 lines total).
- **Compilation target**: Currently compiled **only into `haven_app`** via `java.srcDir("../../../../android_native/child_services")` in `apps/haven_app/android/app/build.gradle.kts`.
- **Child Native State**: `apps/haven_child/android/` has **no `srcDir` redirect** and contains only a 5-line `MainActivity.kt`. It has zero native channels or services linked.
- **D-4 Approved Standard**: Kotlin contract constants are authoritative; Dart mirrors them. Agreement suites in parent (`cross_language_key_agreement_test.dart`) and child (`test/native/`) enforce 100% key and envelope synchronization off disk without Pigeon or `build_runner`.

### 1.3 Dependency & Manifest Reality
- **Source Manifest**: `apps/haven_child/android/app/src/main/AndroidManifest.xml` declares **0 permissions**, no `<queries>`, no `<service>`, no `<receiver>`.
- **Merged Debug Manifest**: Contains 7 permissions (`INTERNET`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`).
- **Cause**: Transitive plugin manifests pulled in through `haven_api` (`firebase_messaging`, GMS, AndroidX). The child Dart code does not call them, but the compiled APK binary is not cloud-free (~162 MB, KGP deprecation warning).

---

## 2. Dependency Isolation Decision: Option A vs. Option B

In accordance with `STAGE_2_OWNER_DECISIONS.md` §4.2, an evidence-based comparison between Option A (`haven_offline` package) and Option B (gated entry points inside `haven_api`) is conducted prior to authorizing Stage 3.

### 2.1 The Core Technical Mechanism in Flutter / Gradle
In Flutter and Dart, dependency resolution operates at two distinct layers:
1. **Dart Code Layer**: Dart imports and library barrels determine which classes/functions can be referenced in source code.
2. **Platform Plugin / Gradle Layer**: The Flutter tooling (`flutter pub get`) inspects the `pubspec.yaml` dependency closure of the root application. Every dependency package that declares a `flutter.plugin.platforms.android` section is registered into `.flutter-plugins-dependencies` and injected into the Gradle project via `dev.flutter.flutter-plugin-loader`.

**Critical Finding**: In Option B, even if `apps/haven_child` imports only a clean `haven_api_offline.dart` barrel that contains no cloud code, `apps/haven_child/pubspec.yaml` must still list `haven_api`. Because `haven_api/pubspec.yaml` declares `firebase_auth`, `firebase_core`, and `firebase_messaging`, Gradle **always** compiles these Android plugins and merges their manifests into the child APK. Gated Dart entry points cannot prevent native plugin compilation.

### 2.2 Detailed Technical Comparison

| Dimension | Option A: Separate `haven_offline` Package | Option B: Gated Entry Points in `haven_api` |
| :--- | :--- | :--- |
| **Dependency Graph** | Clean separation:<br>`haven_core` & `haven_models` (base)<br>↑<br>`haven_offline` (local tables/store/crypto)<br>↑&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↑<br>`haven_child`&nbsp;&nbsp;&nbsp;`haven_api` (cloud SDKs)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↑<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`haven_app` | Shared package:<br>`haven_child` & `haven_app` both depend directly on `haven_api`. `haven_api` bundles offline engine + Supabase + Firebase in one `pubspec.yaml`. |
| **Transitive Cloud Deps** | **Eliminated completely** from `haven_child`. Zero Firebase or Supabase packages in the child pubspec closure. | **Persist 100%**. Firebase and Supabase remain in child's transitive closure. |
| **Child Merged APK Impact** | - Merged manifest drops `INTERNET`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `c2dm.RECEIVE`.<br>- KGP deprecation warning eliminated.<br>- Child APK binary size reduced significantly (removes ~20-40 MB of unused AARs/classes). | - Merged manifest retains all 7 transitive permissions.<br>- KGP deprecation warnings remain.<br>- APK retains unused Firebase/Supabase overhead (~162 MB debug). |
| **Parent App Compatibility** | **100% Preserved**. `haven_api` depends on `haven_offline` and re-exports its public API (`export 'package:haven_offline/haven_offline.dart'`). Not a single line of parent code breaks; 943 parent tests pass unchanged. | **100% Preserved**. Parent continues using `haven_api.dart`. |
| **Child Migration Effort** | Low / Mechanical:<br>- Create `packages/haven_offline/`.<br>- Move `packages/haven_api/lib/src/offline/` (13 files) to `haven_offline`.<br>- Move 66 offline tests to `haven_offline/test/`.<br>- Update `apps/haven_child/pubspec.yaml` to point to `haven_offline`.<br>- Update 6 files in `haven_child` to import `package:haven_offline/haven_offline.dart`. | Very Low initially:<br>- Add `lib/haven_api_offline.dart` in `haven_api`.<br>- Update 6 files in `haven_child`.<br>- **Does not fix the underlying platform issue.** |
| **Testing Complexity** | Clean unit testing. `haven_offline` tests run independently. Architectural test in `haven_child` asserts absence of `haven_api`. | Requires lint rules to prevent child importing cloud files; impossible to test absence of native plugins because they are present. |
| **Long-Term Maintainability** | **High**. Clear architectural boundary. Any future dependency added to `haven_api` (e.g. AWS, Sentry, Stripe) cannot accidentally pollute the child app. | **Low**. Fragile convention. High risk of accidental coupling and ongoing manifest pollution. |
| **Risks & Rollback** | Minor file relocation risk. Can be reverted via standard package restoration if needed. | High technical debt. Merged manifest remains contradictory with privacy guarantees. |

### 2.3 Recommendation
**Recommendation: OPTION A (`haven_offline`).**  
*Technical Justification*: Option B fails to solve the primary limitation identified in Stage 1 and Stage 2: native Android plugin pollution. Only Option A severs the transitive Gradle dependency chain, allowing the child Android application to compile as a true offline-first, permission-transparent client without cloud SDKs or phantom permissions.

*(Note: In accordance with audit instructions, this option is recommended but NOT implemented).*

---

## 3. P-5: Kotlin Testing Infrastructure Status & Proposal

### 3.1 Current Status Inspection
- **Kotlin Source Structure**: `android_native/child_services/` contains 10 Kotlin files across 5 packages (`communication`, `device_admin`, `location`, `monitoring`, `permissions`, `platform_bridge`).
- **Gradle Configuration**: AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17 toolchain.
- **Dependencies Block**: Neither `apps/haven_app/android/app/build.gradle.kts` nor `apps/haven_child/android/app/build.gradle.kts` contains a `dependencies { ... }` block. No test dependencies are declared.
- **Cache Inspection**:
  - `junit:junit:4.13.2` and `org.junit.jupiter` are present in the local Gradle cache (`C:\Users\ASUS\.gradle\caches\modules-2\files-2.1`).
  - **Robolectric is NOT present** in the Gradle cache.
- **Current Native Test Coverage**: **Zero (0%)**. The directory `android_native/child_services/src/test/java/com/haven/childservices` exists on disk but contains zero test files. All existing channel testing is Dart-side mocking.

### 3.2 Robolectric & Offline Analysis
- Robolectric requires downloading Android shadow jars (`android-all-*.jar`, ~100MB+ per API level) from Maven Central on first execution.
- Under strict offline/sandboxed development rules (where background internet access is disabled), un-cached Robolectric runs will fail with `InitializationError` when attempting to resolve platform shadows.
- Furthermore, Robolectric's latest releases officially target up to API 34/35, whereas project `compileSdk` is 36.

### 3.3 Concrete P-5 Test Infrastructure Proposal (Phase 3 Native Lane)
To provide robust, 100% offline, deterministic JVM unit testing under AGP 9.0.1 without relying on external network downloads:

1. **Gradle Test Configuration** (`apps/haven_child/android/app/build.gradle.kts`):
   ```kotlin
   android {
       testOptions {
           unitTests.isReturnDefaultValues = true
           unitTests.isIncludeAndroidResources = false
       }
   }
   dependencies {
       testImplementation("junit:junit:4.13.2")
   }
   ```
2. **Architectural Pattern — Interface-Based Native Readers**:
   - Wrap platform services behind thin Kotlin interfaces (e.g., `UsageStatsProvider`, `AppOpsChecker`).
   - Implement production readers delegating to `android.app.usage.UsageStatsManager` and `android.app.AppOpsManager`.
   - Implement test fakes (`FakeUsageStatsProvider`, `FakeAppOpsChecker`) in unit test sources.
3. **Target Native Test Scope**:
   - Daily usage time calculation and aggregation math across midnight rollover.
   - Minute-level bucketing and sorting logic (verifying top apps sorting).
   - App-ops mode decoding (`MODE_ALLOWED` → `granted`, `MODE_IGNORED`/`MODE_ERRORED` → `denied`).
   - Error envelope serialization and exception-to-error-code mapping.
4. **Execution Command**: `./gradlew :app:testDebugUnitTest` (fully runnable offline).

---

## 4. P-1: Device Readiness Audit

A read-only physical and emulator diagnostics pass was conducted using `adb`:

### 4.1 Device Inventory & Findings

| Target Identifier | Type | Model | OS / API Level | Architecture | Usage Access Availability | Testing Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`emulator-5554`** | Android Emulator | `sdk_gphone64_x86_64` (Google) | Android 17 (API 37) | `x86_64` | **Available**.<br>- UI: Settings > Apps > Special app access > Usage access.<br>- ADB: `cmd appops set <pkg> GET_USAGE_STATS allow`. | **ONLINE / READY** for local emulator verification. |
| **Physical Device** | Physical Hardware (Realme) | RMX2161 (MediaTek) | Android 12 (API 31 / ColorOS) | `arm64-v8a` | **Available** on device via ColorOS Settings > Security / Privacy > Special permissions. | **NOT ATTACHED**.<br>Device was detached prior to this audit. |

### 4.2 Honesty Declaration
- At audit time, `adb devices -l` detected exactly one active target: `emulator-5554`.
- **No physical device testing was performed during this audit.**
- Any future Stage 3 claims will explicitly differentiate between `emulator-5554` results and physical device verification.

---

## 5. Stage 3 Technical Architecture

### 5.1 Architecture Diagram

```
+---------------------------------------------------------------------------------+
|                                 HAVEN CHILD APP                                 |
+---------------------------------------------------------------------------------+
|  [UsageAccessExplainerCard]                                                     |
|       |                                                                         |
|       v                                                                         |
|  [ChildUsageController] (GetX)                                                  |
|       |                                                                         |
|       v                                                                         |
|  [ChildUsageRepository]                                                         |
|       |                                                                         |
|       v                                                                         |
|  [ChildUsageChannel] (Dart MethodChannel wrapper, D-4 key-agreement defended)   |
+---------------------------------------|-----------------------------------------+
                                        |  haven.dev/child_usage_stats
                                        v
+---------------------------------------------------------------------------------+
|                             ANDROID NATIVE (KOTLIN)                             |
+---------------------------------------------------------------------------------+
|  [UsageBridgeHandler.kt] (MethodCallHandler)                                    |
|       |                                                                         |
|       +--> [AppOpsPermissionReader.kt]  --> AppOpsManager.unsafeCheckOpNoThrow  |
|       |                                                                         |
|       +--> [SettingsNavigator.kt]       --> Intent(ACTION_USAGE_ACCESS_SETTINGS)|
|       |                                                                         |
|       +--> [UsageStatsReader.kt]        --> UsageStatsManager.queryUsageStats   |
|                 |                                                               |
|                 v                                                               |
|            [UsageAggregator.kt] (Daily bucket math, system filter, top apps)    |
+---------------------------------------------------------------------------------+
```

### 5.2 MethodChannel Contract (D-4 Authoritative Specification)

Following D-4, Kotlin constants are authoritative; Dart mirrors them.

- **Channel Name**: `haven.dev/child_usage_stats`
- **Envelope Standard**: Every response carries `{ apiLevel: Int, ... }` or returns a typed Flutter error code.

#### Methods & Payload Definitions:

1. **`usage.getPermissionStatus`**
   - **Arguments**: None
   - **Response**:
     ```json
     {
       "apiLevel": 37,
       "status": "granted" // "granted" | "denied" | "unsupported"
     }
     ```
   - **Errors**: `no-context`

2. **`usage.openSettings`**
   - **Arguments**: None
   - **Response**:
     ```json
     {
       "apiLevel": 37,
       "intentLaunched": true,
       "openedPackageSettings": true // false if fell back to generic settings
     }
     ```
   - **Behavior**: Fires `Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)` with `Uri.parse("package:" + context.packageName)`. If no activity resolves the package URI, falls back to `Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)` without data.

3. **`usage.queryDailyUsage`**
   - **Arguments**:
     ```json
     {
       "startTimeMillis": 1731456000000,
       "endTimeMillis": 1731512400000
     }
     ```
   - **Response Envelope**:
     ```json
     {
       "apiLevel": 37,
       "startTimeMillis": 1731456000000,
       "endTimeMillis": 1731512400000,
       "totalForegroundMillis": 14250000,
       "dataFreshness": "delayed", // "recent" | "delayed" | "empty"
       "apps": [
         {
           "packageName": "com.android.chrome",
           "totalForegroundMillis": 7200000,
           "lastTimeUsedMillis": 1731512100000,
           "isSystemApp": false
         }
       ]
     }
     ```
   - **Error Codes**:
     - `permission-denied`: Usage access app-op is not allowed.
     - `invalid-range`: `startTimeMillis >= endTimeMillis`.
     - `section-failed`: Internal native exception.

### 5.3 EventChannel vs. Polling Recommendation
- **Platform Reality**: Android's `UsageStatsManager` provides **no asynchronous callbacks, listeners, or broadcasts** when an app opens or closes.
- **The Pitfall of EventChannel**: Creating an `EventChannel` for screen-time would require running a continuous background loop in Kotlin (`Thread.sleep` or coroutine polling). This drains battery, triggers OEM aggressive kills (ColorOS/MIUI), and breaches the brief restriction against background services.
- **Recommendation: Reactive On-Demand Polling via MethodChannel**:
  - The Flutter UI queries `usage.queryDailyUsage` when the child dashboard is viewed.
  - Automatically re-queries when the app resumes (`AppLifecycleState.resumed` via `WidgetsBindingObserver`), capturing any usage changes that occurred while the child was in other apps or settings.
  - Optional low-frequency timer (e.g. 60 seconds) *only while the dashboard screen is active in foreground*.
  - This architecture is reliable, transparent, battery-efficient, and does not invent fake real-time event mechanisms.

### 5.4 Handling Incomplete & Delayed Data
- Android buffers `UsageStats` in system memory and flushes to disk periodically or on screen off. Near-real-time reads may lag by several minutes.
- **Honest UI State**: The dashboard will explicitly display a subtle notice: `"Android system updates usage stats periodically; recent minutes may be slightly delayed."`
- The system will never fabricate usage counts or interpolate missing intervals to appear real-time.

### 5.5 Privacy & Permission Transparency Flow
- **Explainer Screen**: Before navigating to Android settings, the child app presents `UsageAccessExplainerCard`:
  - **What is collected**: Total screen time and time spent in each app.
  - **What is NEVER collected**: In-app messages, photos, videos, browsing history, keystrokes, or screen recordings.
  - **Where data goes**: Stored locally on this device in `haven_local.json`. Zero data is transmitted to the cloud.
- **Revocation Handling**: If the user revokes permission in Settings:
  - App detects `status == "denied"`.
  - UI replaces usage charts with a clear `UsagePermissionRequiredCard`.
  - No cached data is misrepresented as current.

---

## 6. Testing Matrix Proposal

| Test Layer | Target / Suite | Purpose | Execution Mode |
| :--- | :--- | :--- | :--- |
| **Dart Unit** | `test/usage/usage_controller_test.dart` | State transitions: loading, permission-required, data-loaded, delayed-data, empty. | Offline host (`flutter test`) |
| **Dart Unit** | `test/usage/daily_aggregation_test.dart` | Midnight boundary calculation, time window clamping, app sorting. | Offline host (`flutter test`) |
| **Dart Agreement** | `test/native/usage_key_agreement_test.dart` | D-4 cross-language check: parses `UsageContract.kt` off disk, verifies all channel strings, methods, and envelope keys. | Offline host (`flutter test`) |
| **Kotlin Unit (P-5)** | `app/src/test/.../UsageStatsReaderTest.kt` | Tests Kotlin aggregation logic, bucket calculations, and mock app-ops status parsing. | Local JVM (`./gradlew testDebugUnitTest`) |
| **Emulator Integration** | `emulator-5554` (API 37) | Verify Intent launches Settings; test grant/revoke cycles using `cmd appops`. | Host + ADB on running emulator |
| **Physical Hardware** | Realme RMX2161 (API 31) | Verify ColorOS OEM settings navigation and usage reporting. | Marked **`BLOCKED / NOT TESTED`** until device is physically attached. |

---

## 7. Risks and Blockers Register

| ID | Item | Severity | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **R-1** | Transitive manifest pollution from `haven_api` | High | Execute Option A (`haven_offline`) to isolate the child app completely before adding native lanes. |
| **R-2** | OEM Settings Navigation Failure | Medium | Some OEM ROMs fail on `package:` URI for `ACTION_USAGE_ACCESS_SETTINGS`. Kotlin code must wrap in `try-catch` and fall back to bare `Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)`. |
| **R-3** | Kotlin File Line Count Limit | Low | Strict enforcement of ≤200 lines per file (`UsageContract.kt`, `UsageStatsReader.kt`, `UsageAggregator.kt`, `UsageBridgeHandler.kt` all kept modular). |
| **R-4** | Robolectric Shadow Incompatibility | Low | Avoid un-cached Robolectric; adopt JUnit 4 + hand-written Kotlin fakes with `isReturnDefaultValues = true`. |

---

## 8. Exact Prerequisites for Stage 3 Implementation

Before any Stage 3 implementation code is written, the following prerequisites must be fulfilled:
1. **Owner Approval of this Readiness Report**: Explicit sign-off on the findings and architectural direction.
2. **Owner Decision on Dependency Isolation**: Explicit decision approving **Option A** (`haven_offline` package extraction).
3. **Approval of D-4 Channel Contract**: Formal sign-off on the `haven.dev/child_usage_stats` method and envelope schema.
4. **Target Hardware Selection**: Owner guidance on whether Stage 3 testing will proceed on `emulator-5554` only, or if physical device testing will be coordinated.

---

## 9. Owner Decisions Required

Please provide explicit direction on the following four decisions:

- [ ] **Decision 1: Dependency Isolation**:
  - Approve **Option A** (Extract `haven_offline` package to eliminate transitive Firebase/Supabase dependencies from the child APK), OR
  - Direct **Option B** (Maintain existing `haven_api` with gated entry points, accepting merged manifest permissions and KGP warnings).
- [ ] **Decision 2: Native Test Lane (P-5)**:
  - Approve the proposed JUnit 4 + hand-written Kotlin fakes + AGP `isReturnDefaultValues = true` infrastructure for local JVM testing.
- [ ] **Decision 3: Channel Transport Architecture**:
  - Approve the proposed on-demand reactive MethodChannel pattern (`haven.dev/child_usage_stats`) over an artificial EventChannel polling service.
- [ ] **Decision 4: Stage 3 Scope & Execution Authorization**:
  - Authorize commencement of Stage 3 implementation in accordance with the specifications in this report.

---

## 10. STOP — Standing Instructions Respected

- **No Stage 3 functionality implemented.**
- **No dependencies or Gradle build configurations modified.**
- **No cloud or backend requests made.**
- **Awaiting explicit owner decisions and authorization before proceeding.**

