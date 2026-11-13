# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 3: IMPLEMENTATION EXECUTION PLAN
**Usage Access & Screen-Time Monitoring**

**Document Version**: 1.2.0-RECONCILED  
**Date**: November 13, 2026  
**Status**: PLANNING AUDITED & RECONCILED — IMPLEMENTATION ON HOLD (AWAITING OWNER AUTHORIZATION)  
**Target Evidence Ceiling**: Ladder Level 2 (Flutter Logic) Baseline; Level 3/4 (Native Kotlin + Emulator Verified) Target for Stage 3 Completion

---

## 1. Current Baseline & Exact Starting Assumptions

### 1.1 Verified Repository Facts (as of 2026-11-13)
- **Git State**:
  - Current Branch: `main`
  - Current HEAD: **`b5fd32d`** (full SHA: `b5fd32d5b76aba4144e9e2f24b415ad636a40394`).
  - Historical Lineage & Reconciliation:
    - `50b4425`: Pre-Stage-2 backlog commit (previously recorded as HEAD during early Stage 2 preparation).
    - `8fccd66`: Stage 2 implementation commit (`feat: implement phase 3 stage 2 android device capability inventory and registration architecture`).
    - `b5fd32d`: Stage 3 readiness audit commit (`refactor(docs): add Phase 3 Stage 3 readiness audit report`), which is the true authoritative starting HEAD for Stage 3 planning.
  - Zero git mutations have been performed by this planning process.
- **Code Hygiene**:
  - `dart scripts/check_line_counts.dart` → **740 hand-written files / 0 violations** (strict ≤200 lines per file upheld).
  - `fvm flutter analyze` → **`No issues found!`** across `apps/haven_child`, `apps/haven_app`, and all `packages/*`.
- **Test Baseline**: **1,290 tests**, 0 failures, 0 skips:
  - `apps/haven_child`: **251** tests (Stage 1: 167; Stage 2: 84)
  - `apps/haven_app`: **943** tests (Phase 2: 924; Stage 2: 19)
  - `packages/haven_api`: **66** tests (offline store, constraints, queries)
  - `packages/haven_core`: **18** tests (Result, Failures, Clock, Validators)
  - `packages/haven_models`: **12** tests (serialization, wire labels)
- **Native Implementation State**:
  - `android_native/child_services/` contains 10 Kotlin files (713 lines total) compiled **only into `haven_app`** via `srcDir` redirect in `apps/haven_app/android/app/build.gradle.kts`.
  - `apps/haven_child/android/` has **no `srcDir` redirect**, no native channels, and contains only a 5-line `MainActivity.kt`.
  - Native Kotlin test coverage is **0%**; directory `android_native/child_services/src/test/java/com/haven/childservices/` exists but is empty.
- **Manifest & Dependency State**:
  - Source manifest `apps/haven_child/android/app/src/main/AndroidManifest.xml` declares **0 permissions**.
  - Merged debug APK manifest currently carries 7 transitive permissions (`INTERNET`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`) injected by `firebase_messaging` via the `haven_api` path dependency.
  - Gradle debug build produces a live warning regarding Kotlin Gradle Plugin (KGP) deprecation in `firebase_auth` and `firebase_core`.

### 1.2 Approved Owner Architecture Decisions (Binding & Unchanged)
1. **Dependency Isolation**: Option A — create `packages/haven_offline/` and extract the pure offline engine from `packages/haven_api/`.
2. **Native Kotlin Testing**: JUnit 4 with hand-written fakes and `isReturnDefaultValues = true`.
3. **Native Communication**: On-demand MethodChannel (`haven.dev/child_usage_stats`). Do not use EventChannel.
4. **Hardware Target**: Android emulator (`emulator-5554`, Android 17 / API 37) first. Physical-device testing is deferred.

---

## 2. Dependency Extraction Inventory & Multi-Layer Verification (Option A)

### 2.1 Extraction Architecture
```
packages/haven_core/    (leaf: Result, Failures, Clock, Validation)
      ▲
      │
packages/haven_models/  (leaf: row models, JSON utils, enums)
      ▲
      │
packages/haven_offline/ (NEW: local store, tables, schema, constraints, queries)
      ▲                     ▲
      │                     │
apps/haven_child/     packages/haven_api/ (cloud SDKs, Firebase, Supabase)
                            ▲
                            │
                      apps/haven_app/
```

### 2.2 Exact Source Files to Extract from `packages/haven_api/`
The following 13 source files will be moved from `packages/haven_api/lib/src/offline/` to `packages/haven_offline/lib/src/`:
1. `demo_data_records.dart` (6,064 bytes)
2. `demo_data_suite.dart` (2,413 bytes)
3. `local_change_feed.dart` (1,531 bytes)
4. `local_constraints.dart` (4,679 bytes)
5. `local_document.dart` (4,613 bytes)
6. `local_ids.dart` (1,991 bytes)
7. `local_profile_store.dart` (1,414 bytes)
8. `local_queries.dart` (3,135 bytes)
9. `local_schema.dart` (4,895 bytes)
10. `local_store.dart` (4,336 bytes)
11. `local_tables.dart` (6,265 bytes)
12. `local_user_auth.dart` (5,990 bytes)
13. `offline_haven_backend.dart` (4,562 bytes)

### 2.3 Exact Test Files to Extract from `packages/haven_api/test/`
The following 7 test files (accounting for **44 verified tests**) will be moved from `packages/haven_api/test/offline/` to `packages/haven_offline/test/`:
1. `demo_data_suite_test.dart` (2 tests)
2. `local_constraints_test.dart` (9 tests)
3. `local_profile_store_test.dart` (2 tests)
4. `local_store_test.dart` (7 tests)
5. `local_tables_test.dart` (10 tests)
6. `local_user_auth_test.dart` (10 tests)
7. `stabilization_regression_test.dart` (4 tests)

*(Retained in `packages/haven_api/test/`: `backend_status_test.dart` [15 tests] and `credential_seams_test.dart` [7 tests], totaling **22 tests**).*

### 2.4 Parent Compatibility Re-Export Strategy
- In `packages/haven_api/pubspec.yaml`, add:
  ```yaml
  dependencies:
    haven_offline:
      path: ../haven_offline
  ```
- In `packages/haven_api/lib/haven_api.dart`, add:
  ```dart
  export 'package:haven_offline/haven_offline.dart';
  ```
- **Parent Impact**: Exactly zero imports in `apps/haven_app` need modification. All 943 parent tests continue passing without alteration.

### 2.5 Ten-Layer Dependency Isolation Verification
Source-code import checks alone are insufficient to prove cloud isolation. The implementation must verify all 10 layers:

1. **`pubspec.yaml` Declarations**: `apps/haven_child/pubspec.yaml` declares only `haven_offline`, `haven_core`, `haven_models`, `get`, `path_provider`, `flutter_secure_storage`, and `cupertino_icons`. Zero references to `haven_api`, `firebase_*`, or `supabase_*`.
2. **Resolved `pubspec.lock`**: Inspected to verify zero entries for `firebase_auth`, `firebase_core`, `firebase_messaging`, `supabase_flutter`, `postgrest`, `gotrue`, `realtime_client`, or `storage_client`.
3. **Resolved Dependency Graph (`flutter pub deps`)**: Executed in `apps/haven_child`, confirming that no package in the child's transitive closure pulls in Firebase or Supabase.
4. **`.flutter-plugins-dependencies`**: Inspected in `apps/haven_child/`, confirming that no Android plugins from Firebase or Supabase are registered for Gradle build injection.
5. **Generated Android Plugin Registrant (`GeneratedPluginRegistrant.java`)**: Inspected in `apps/haven_child/android/` to verify that only local platform plugins (`flutter_secure_storage`, `path_provider`) are registered, and zero Firebase registrants appear.
6. **Debug Merged Manifest**: Inspected at `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml` (evaluated per Section 3 criteria).
7. **Release Merged Manifest**: Inspected at `apps/haven_child/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`.
8. **Child Debug Build (`fvm flutter build apk --debug`)**: Built cleanly with zero KGP deprecation warnings for `firebase_*`.
9. **Child Release Build (`fvm flutter build apk --release`)**: Built cleanly to confirm release tree shaking and manifest merging.
10. **Parent Regression Suite (`fvm flutter test apps/haven_app`)**: All 943 parent tests pass, proving zero breakage in parent cloud/offline behavior via the `haven_api` re-export layer.

---

## 3. Android Manifest Verification & Evidence-Based Criteria

### 3.1 Permission Classification & Origin Mapping
The blanket "zero permissions in debug merged manifest" requirement is replaced with an evidence-based dependency-isolation requirement distinguishing four permission categories:

| Category | Description | Examples | Stage 3 Expected Status |
| :--- | :--- | :--- | :--- |
| **A. Application-Declared** | Explicitly declared in `apps/haven_child/android/app/src/main/AndroidManifest.xml`. | `PACKAGE_USAGE_STATS` | **Legitimately Added**: Required by Android framework so the app appears in Settings > Special App Access > Usage Access. |
| **B. Third-Party Plugin (Cloud)** | Transitive permissions injected by Firebase / GMS plugins via `haven_api`. | `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, `INTERNET` (from Firebase) | **Must Disappear**: Severed when child switches to `haven_offline`. |
| **C. AndroidX / Platform Security** | Injected by AndroidX Core library during AAPT manifest merge for internal IPC. | `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (with `protectionLevel="signature"`) | **Legitimately Retained**: Generated by AndroidX for secure local broadcast receivers on API 33+. Not a cloud or runtime permission. |
| **D. Flutter Debug Tooling** | Injected by Flutter tooling in debug builds for Observatory/debugger sockets. | `INTERNET` (debug-only socket) | **Evidence-Based Rule**: Stage 1 removed it from debug source. Must not reappear from third-party plugins. See Section 3.2 rule. |

### 3.2 Evidence-Based Rule for the `INTERNET` Permission
To resolve any contradiction between debug tooling and child offline guarantees:
1. **Source Distinction**:
   - In the pre-Stage-3 child build, `manifest-merger-debug-report.txt` shows `INTERNET` was `ADDED from [:firebase_messaging]` and `MERGED from [firebase-auth:25.0.0]` and `[firebase-installations:20.0.0]`.
   - All `INTERNET` permissions originating from `firebase_*`, `supabase_*`, or third-party cloud SDKs **must completely disappear** when Option A dependency isolation succeeds.
2. **Release Build Strictness**:
   - In `release` builds (`fvm flutter build apk --release`), `android.permission.INTERNET` **must be 100% ABSENT** from the merged release manifest, as the child application source declares no network lane.
3. **Debug Tooling Policy**:
   - If Flutter's debug engine tooling legitimately injects an `INTERNET` socket permission for local Dart VM service / Observatory debugging, its origin must be verified via `manifest-merger-debug-report.txt`.
   - A debug build will **not** be failed merely because a legitimate debug-only tooling declaration exists, provided it is verified absent from the release build and verified to originate from local debug tooling rather than third-party cloud plugins.
4. **Evidence Requirement**:
   - Absence or presence of `INTERNET` will **never** be claimed without direct inspection of `processDebugMainManifest/AndroidManifest.xml`, `processReleaseMainManifest/AndroidManifest.xml`, and final APK badging via `apkanalyzer`/`aapt`.

### 3.3 Merged Manifest Inspection Protocol
During Step 3 and Step 12 verification:
1. **Debug Artifact Inspection**:
   - Primary: `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`
   - Merger Log: `apps/haven_child/build/app/outputs/logs/manifest-merger-debug-report.txt`
2. **Release Artifact Inspection**:
   - Primary: `apps/haven_child/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`
   - Merger Log: `apps/haven_child/build/app/outputs/logs/manifest-merger-release-report.txt`
3. **APK Manifest Badging**:
   - Run `apkanalyzer manifest permissions <path-to-apk>` or `aapt dump permissions <path-to-apk>` to confirm actual permissions embedded in the final `.apk` binary.

### 3.4 Final Report Permission Documentation Matrix
The Stage 3 implementation report will document every observed permission using the following accounting format:

```markdown
| Permission Name | Declaring Layer / Origin Artifact | Debug Manifest | Release Manifest | Disposition / Justification |
| :--- | :--- | :--- | :--- | :--- |
| `android.permission.PACKAGE_USAGE_STATS` | Application source (`com.haven.child`) | Present | Present | Legitimate: Required for Usage Access Settings enumeration |
| `com.haven.child.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX Core (`androidx.core:core`) | Present | Present | Legitimate: Signature IPC protection for Android 13+ receivers |
| `android.permission.WAKE_LOCK` | `firebase_messaging` AAR | ABSENT | ABSENT | Eliminated via Option A isolation |
| `android.permission.ACCESS_NETWORK_STATE` | `firebase_messaging` AAR | ABSENT | ABSENT | Eliminated via Option A isolation |
| `android.permission.POST_NOTIFICATIONS` | `firebase_messaging` AAR | ABSENT | ABSENT | Eliminated via Option A isolation |
| `com.google.android.c2dm.permission.RECEIVE` | Google Play Services GMS | ABSENT | ABSENT | Eliminated via Option A isolation |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | Google Play Services GMS | ABSENT | ABSENT | Eliminated via Option A isolation |
| `android.permission.INTERNET` | Third-party cloud AARs vs Debug Tooling | ABSENT (or debug tooling only) | ABSENT | Cloud SDK origin eliminated via Option A. Release manifest strictly absent. |
```

*(Note: No permission will be claimed absent unless verified by actual build logs and APK inspection).*

---

## 4. Exact Test Count Reconciliation & Arithmetic

### 4.1 Reconciliation of Previous Discrepancy
- The initial planning draft estimated "59 extracted tests and 7 retained tests" in `haven_api`.
- **Verified Repository Fact**: Direct static inspection of `packages/haven_api/test/` reveals:
  - 2 root files: `backend_status_test.dart` (15 tests) + `credential_seams_test.dart` (7 tests) = **22 tests**.
  - 7 offline files under `test/offline/`: `demo_data_suite_test.dart` (2), `local_constraints_test.dart` (9), `local_profile_store_test.dart` (2), `local_store_test.dart` (7), `local_tables_test.dart` (10), `local_user_auth_test.dart` (10), `stabilization_regression_test.dart` (4) = **44 tests**.
  - Sum: 22 + 44 = **66 tests** (matches baseline exactly).
- Therefore, exactly **44 tests** move from `packages/haven_api` to `packages/haven_offline`, leaving **22 tests** in `haven_api`.

### 4.2 Test Accounting Table & Arithmetic Formulas

| Package / Application | Existing Baseline | Extracted Tests | Retained Tests | Newly Authored Tests | Expected Final Total |
| :--- | ---:| ---:| ---:| ---:| ---:|
| **`haven_core`** | 18 | 0 | 18 | 0 | **18** |
| **`haven_models`** | 12 | 0 | 12 | 0 | **12** |
| **`haven_offline`** (NEW) | 0 | +44 | 44 | 0 | **44** |
| **`haven_api`** | 66 | -44 | 22 | $C$ ($0 \le C \le 2$ compatibility) | **$22 + C$** (22 to 24) |
| **`haven_app`** (Parent) | 943 | 0 | 943 | 0 | **943** |
| **`haven_child` (Dart)** | 251 | 0 | 251 | $N_{\text{child\_dart}}$ (target ~60–90) | **$251 + N_{\text{child\_dart}}$** |
| **`haven_child` (Kotlin P-5)** | 0 | 0 | 0 | $N_{\text{child\_kotlin}}$ (target ~15–25) | **$N_{\text{child\_kotlin}}$** *(JVM lane)* |
| **Total Dart Test Suite** | **1,290** | **0 net** | **1,290** | **$C + N_{\text{child\_dart}}$** | **$1,290 + C + N_{\text{child\_dart}}$** |

### 4.3 Precise Expected Total Scenarios
1. **Conserved Starting Baseline**:
   - $18 + 12 + 44 + 22 + 943 + 251 = \mathbf{1,290\text{ tests}}$.
   - Moving 44 tests from `haven_api` to `haven_offline` results in zero net change to the starting baseline.
2. **Scenario A (0 compatibility tests added in `haven_api`)**:
   - $C = 0 \implies \text{Total Dart Tests} = 1,290 + N_{\text{child\_dart}}$.
   - Example ($N_{\text{child\_dart}} = 70$): Total = $1,360$ Dart tests.
3. **Scenario B (2 compatibility tests added in `haven_api`)**:
   - $C = 2 \implies \text{Total Dart Tests} = 1,290 + 2 + N_{\text{child\_dart}} = \mathbf{1,292 + N_{\text{child\_dart}}}$.
   - Example ($N_{\text{child\_dart}} = 70$): Total = $1,362$ Dart tests.
4. **Native Kotlin JVM Tests ($N_{\text{child\_kotlin}}$)**:
   - Run in the separate Gradle JVM test lane via `./gradlew :app:testDebugUnitTest`.
   - Reported as a distinct native test metric, never combined or confused with Flutter Dart suite counts.

---

## 5. Usage Data Privacy and Persistence Contract

### 5.1 Data Collection Boundaries
The Stage 3 implementation is strictly bounded to the following telemetry:
- **Collected**:
  1. Total foreground usage duration (milliseconds / minutes) within the requested daily interval.
  2. Per-application foreground usage duration (package name, application label, foreground milliseconds).
  3. Last usage timestamp (`lastTimeUsedMillis` epoch timestamp) for sorting and recency display.
- **Strictly Prohibited & Excluded**:
  - NO screen capture, screenshots, or window content inspection.
  - NO keystroke logging, input monitoring, or accessibility scraping.
  - NO text messages, chat logs, notification contents, or emails.
  - NO browsing history, visited URLs, search queries, or web cookies.
  - NO camera capture, microphone recording, or audio monitoring.
  - NO device location, GPS coordinates, Wi-Fi SSID, or cell tower telemetry.

### 5.2 Persistence Contract: Transient In-Memory Only
In accordance with the owner's instruction to prefer transient in-memory results:
- **Decision**: **All Stage 3 usage statistics are TRANSIENT IN-MEMORY ONLY.**
- **Storage Boundary**:
  - Usage statistics are queried on-demand from Android's `UsageStatsManager` and held in the reactive state of `ChildUsageController`.
  - Usage statistics are **NEVER written to disk**, never persisted in `haven_local.json`, and never cached in SQLite or shared preferences.
  - When `ChildUsageController` is disposed or the application process terminates, all usage statistics are completely discarded from memory.
  - No new database table, no new schema version, and no persistent cache files are introduced in Stage 3.
  - *(Existing local storage in `haven_local.json` remains strictly confined to child profile and local session data)*.

### 5.3 Permission Revocation Protocol
When the user or device administrator revokes Usage Access in Android Settings:
1. **Lifecycle Detection**: Upon `AppLifecycleState.resumed`, `ChildUsageController` immediately invokes `usage.getPermissionStatus`.
2. **Immediate Memory Flush**: If status returns `denied` or `unsupported`, all previously queried in-memory usage statistics, daily totals, and app lists are **immediately wiped/cleared** (`_dailySummary.value = null; _appsList.clear();`).
3. **Honest UI Transition**: The UI immediately transitions from the usage dashboard to `UsagePermissionDeniedCard`.
4. **Anti-Staleness Rule**: The application will **never** display stale cached statistics or previous sessions' data when permission is currently revoked.

### 5.4 Data Freshness & Delay Disclosures
- **Platform Reality**: Android's `UsageStatsManager` buffers usage events in system memory and flushes them to disk periodically (often every few minutes or upon screen state changes). Near-real-time queries may lag by several minutes.
- **Honest UI State**: The dashboard footer displays a permanent disclosure:
  `"Usage statistics are updated periodically by the Android system; activity from recent minutes may be slightly delayed."`
- **Zero Fabrication**:
  - Empty usage intervals (`apps.isEmpty`) are clearly rendered as `"No usage recorded for this period"`, explicitly distinguished from permission denial.
  - The application will **never** interpolate missing data, fabricate estimated curves, or simulate app launches. If the platform returns 0 milliseconds, the UI displays 0 minutes.

### 5.5 Network & Cloud Boundary
- Zero network requests.
- Zero telemetry transmission.
- Zero Supabase or Firebase API calls.
- Usage statistics exist solely within the local process memory on the child device.

---

## 6. Proposed File & Folder Structure

```
packages/haven_offline/
  pubspec.yaml                                      # depends on haven_core, haven_models, flutter, get, path_provider
  lib/
    haven_offline.dart                              # primary barrel re-exporting offline engine
    src/                                            # 13 extracted offline engine files
  test/                                             # 7 extracted offline test files (44 tests)

apps/haven_child/
  android/app/
    build.gradle.kts                                # testOptions configuration + junit:4.13.2 dependency
    src/
      main/
        AndroidManifest.xml                         # declares PACKAGE_USAGE_STATS special access
        kotlin/com/haven/child/
          MainActivity.kt                           # registers UsageBridgeHandler into engine
          usage/                                    # NEW Kotlin native usage package (≤200 lines each)
            UsageContract.kt                        # authoritative channel constants (<120 lines)
            UsageBridgeHandler.kt                   # MethodCallHandler implementation (<150 lines)
            AppOpsPermissionReader.kt               # AppOpsManager permission checks (<100 lines)
            SettingsNavigator.kt                    # Intent builder with fallback (<90 lines)
            UsageStatsReader.kt                     # UsageStatsManager query delegate (<160 lines)
            UsageAggregator.kt                      # daily aggregation & top apps logic (<180 lines)
      test/
        kotlin/com/haven/child/usage/               # NEW native JVM unit tests
          UsageContractAgreementTest.kt             # Kotlin-side contract tests
          UsageAggregatorTest.kt                    # aggregation math, midnight boundaries, empty stats
          AppOpsPermissionReaderTest.kt             # mode mapping unit tests with fakes
          FakeUsageStatsProvider.kt                 # hand-written test fake (<100 lines)
          FakeAppOpsChecker.kt                      # hand-written test fake (<80 lines)
  lib/
    core/native/
      usage_channel.dart                            # Dart MethodChannel wrapper (<160 lines)
      usage_channel_contract.dart                   # Dart mirror of Kotlin UsageContract (<120 lines)
      usage_envelope_models.dart                    # typed Result models (<150 lines)
    features/child_usage/                           # NEW child usage feature
      bindings/
        child_usage_bindings.dart                   # GetX dependency injection (<60 lines)
      controllers/
        child_usage_controller.dart                 # GetX controller with in-memory state (<180 lines)
      data/
        child_usage_repository.dart                 # repository abstracting native channel (<140 lines)
      domain/
        usage_freshness_status.dart                 # enum & model for data delay indicators (<70 lines)
      views/
        child_usage_page.dart                       # main screen-time page (<170 lines)
        widgets/
          usage_access_explainer_card.dart          # transparent privacy disclosure (<140 lines)
          daily_screen_time_card.dart               # hours & minutes summary card (<150 lines)
          app_usage_list_card.dart                  # top-apps list with delay notices (<180 lines)
          usage_permission_denied_card.dart         # actionable settings navigation card (<130 lines)
  test/
    native/
      usage_cross_language_agreement_test.dart     # D-4 drift test parsing UsageContract.kt off disk
    features/child_usage/
      child_usage_controller_test.dart              # full GetX state transition tests
      child_usage_repository_test.dart              # repository & error mapping tests
      usage_channel_mock_test.dart                  # MethodChannel wrapper tests with setMockMethodCallHandler
      daily_aggregation_math_test.dart              # Dart-side timestamp & boundary unit tests
    architecture/
      child_dependency_isolation_test.dart          # asserts absence of haven_api / firebase in child
```

---

## 7. Ordered Implementation Steps

Implementation is divided into 12 distinct steps. No step may begin until the preceding step's automated gates pass.

```
Step 1: packages/haven_offline/ Scaffold & Extraction
    │ (Independent)
    ▼
Step 2: Parent Compatibility Re-Export & Verification
    │ (Depends on Step 1)
    ▼
Step 3: Child pubspec Switch & Dependency Severing
    │ (Depends on Step 1 & 2)
    ▼
Step 4: Kotlin Native Test Lane Setup (P-5)
    │ (Independent)
    ▼
Step 5: Authoritative Usage Channel Contract (D-4)
    │ (Depends on Step 4)
    ▼
Step 6: Native Implementation & JVM Tests (D-4 / P-5)
    │ (Depends on Step 5)
    ▼
Step 7: Dart MethodChannel Wrapper & Agreement Tests
    │ (Depends on Step 5 & 6)
    ▼
Step 8: Child Feature Domain & Repository Layer
    │ (Depends on Step 7)
    ▼
Step 9: GetX Controller & Lifecycle Handler (Transient In-Memory)
    │ (Depends on Step 8)
    ▼
Step 10: UI Layer (Explainer, Dashboard, Permission States)
    │ (Depends on Step 9)
    ▼
Step 11: Route & Navigation Integration
    │ (Depends on Step 10)
    ▼
Step 12: Full Regression & Emulator Verification (P-1)
    │ (Depends on All Steps)
```

---

## 8. Per-Step Files Expected to Change

### Step 1: `packages/haven_offline/` Scaffold & Extraction
- **Can complete independently**: Yes.
- **Dependencies**: None.
- **Files Created**:
  - `packages/haven_offline/pubspec.yaml`
  - `packages/haven_offline/lib/haven_offline.dart`
  - `packages/haven_offline/lib/src/*` (13 files moved from `packages/haven_api/lib/src/offline/`)
  - `packages/haven_offline/test/*` (7 files moved from `packages/haven_api/test/offline/`)
- **Files Modified**:
  - `packages/haven_api/pubspec.yaml` (adds `haven_offline` path dependency)
  - `packages/haven_api/lib/haven_api.dart` (re-exports `haven_offline`)
- **Automated Verification**:
  - `fvm flutter test packages/haven_offline` (44 tests pass).
  - `fvm flutter test packages/haven_api` (22 tests pass; or 24 if compatibility tests added).
  - `fvm flutter analyze packages/haven_offline packages/haven_api` (0 issues).

### Step 2: Parent Compatibility Re-Export & Verification
- **Can complete independently**: No (depends on Step 1).
- **Dependencies**: Step 1.
- **Files Modified**: None in `apps/haven_app`.
- **Automated Verification**:
  - `fvm flutter test apps/haven_app` (943 tests pass).
  - `fvm flutter analyze apps/haven_app` (0 issues).

### Step 3: Child pubspec Switch & Dependency Severing
- **Can complete independently**: No (depends on Step 1 & 2).
- **Dependencies**: Step 1, Step 2.
- **Files Modified**:
  - `apps/haven_child/pubspec.yaml` (replace `haven_api` with `haven_offline`)
  - `apps/haven_child/lib/core/storage/child_database.dart`
  - `apps/haven_child/lib/core/storage/child_data_resetter.dart`
  - `apps/haven_child/lib/core/storage/child_local_state.dart`
  - `apps/haven_child/lib/core/storage/local_child_profile_repository.dart`
  - `apps/haven_child/lib/features/registration/data/demo_registration_service.dart`
  - `apps/haven_child/lib/features/splash/controllers/splash_controller.dart`
  - 11 test files in `apps/haven_child/test/`
- **Files Created**:
  - `apps/haven_child/test/architecture/child_dependency_isolation_test.dart`
- **Automated Verification**:
  - `fvm flutter test apps/haven_child` (251 tests + isolation test pass).
  - Inspect `.flutter-plugins-dependencies`: assert `firebase_*` and `supabase_*` are 100% absent.
  - Rebuild debug and release APKs: confirm elimination of Firebase transitive permissions (`WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, etc.) in merger logs.

### Step 4: Kotlin Native Test Lane Setup (P-5)
- **Can complete independently**: Yes.
- **Dependencies**: None.
- **Files Modified**:
  - `apps/haven_child/android/app/build.gradle.kts`:
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
- **Automated Verification**:
  - `cd apps/haven_child/android && ./gradlew :app:testDebugUnitTest` (executes cleanly).

### Step 5: Authoritative Usage Channel Contract (D-4)
- **Can complete independently**: No (depends on Step 4).
- **Dependencies**: Step 4.
- **Files Created**:
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/UsageContract.kt`
  - `apps/haven_child/lib/core/native/usage_channel_contract.dart`
  - `apps/haven_child/test/native/usage_cross_language_agreement_test.dart`
- **Automated Verification**:
  - `fvm flutter test apps/haven_child/test/native/usage_cross_language_agreement_test.dart`.
  - Mutation test proving drift detection fails on altered constant.

### Step 6: Native Implementation & JVM Tests (D-4 / P-5)
- **Can complete independently**: No (depends on Step 5).
- **Dependencies**: Step 5.
- **Files Created**:
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/UsageBridgeHandler.kt`
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/AppOpsPermissionReader.kt`
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/SettingsNavigator.kt`
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/UsageStatsReader.kt`
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/UsageAggregator.kt`
  - `apps/haven_child/android/app/src/test/kotlin/com/haven/child/usage/UsageAggregatorTest.kt`
  - `apps/haven_child/android/app/src/test/kotlin/com/haven/child/usage/AppOpsPermissionReaderTest.kt`
  - `apps/haven_child/android/app/src/test/kotlin/com/haven/child/usage/FakeUsageStatsProvider.kt`
  - `apps/haven_child/android/app/src/test/kotlin/com/haven/child/usage/FakeAppOpsChecker.kt`
- **Files Modified**:
  - `apps/haven_child/android/app/src/main/kotlin/com/haven/child/MainActivity.kt`
  - `apps/haven_child/android/app/src/main/AndroidManifest.xml` (declares `PACKAGE_USAGE_STATS`)
- **Automated Verification**:
  - `./gradlew :app:testDebugUnitTest` (all JVM tests pass).
  - `dart scripts/check_line_counts.dart` (all `.kt` files ≤200 lines).

### Step 7: Dart MethodChannel Wrapper & Agreement Tests
- **Can complete independently**: No (depends on Step 5 & 6).
- **Dependencies**: Step 5, Step 6.
- **Files Created**:
  - `apps/haven_child/lib/core/native/usage_channel.dart`
  - `apps/haven_child/lib/core/native/usage_envelope_models.dart`
  - `apps/haven_child/test/native/usage_channel_mock_test.dart`
- **Automated Verification**:
  - `fvm flutter test apps/haven_child/test/native` (all channel mock tests pass).

### Step 8: Child Feature Domain & Repository Layer
- **Can complete independently**: No (depends on Step 7).
- **Dependencies**: Step 7.
- **Files Created**:
  - `apps/haven_child/lib/features/child_usage/domain/usage_freshness_status.dart`
  - `apps/haven_child/lib/features/child_usage/data/child_usage_repository.dart`
  - `apps/haven_child/test/features/child_usage/child_usage_repository_test.dart`
- **Automated Verification**:
  - `fvm flutter test apps/haven_child/test/features/child_usage/child_usage_repository_test.dart`.

### Step 9: GetX Controller & Lifecycle Handler (Transient In-Memory)
- **Can complete independently**: No (depends on Step 8).
- **Dependencies**: Step 8.
- **Files Created**:
  - `apps/haven_child/lib/features/child_usage/controllers/child_usage_controller.dart`
  - `apps/haven_child/lib/features/child_usage/bindings/child_usage_bindings.dart`
  - `apps/haven_child/test/features/child_usage/child_usage_controller_test.dart`
- **Automated Verification**:
  - Controller state tests verify loading, permission-required, loaded, and lifecycle resume re-queries.
  - Tests verify that on permission revocation, in-memory statistics are immediately cleared.

### Step 10: UI Layer (Explainer, Dashboard, Permission States)
- **Can complete independently**: No (depends on Step 9).
- **Dependencies**: Step 9.
- **Files Created**:
  - `apps/haven_child/lib/features/child_usage/views/child_usage_page.dart`
  - `apps/haven_child/lib/features/child_usage/views/widgets/usage_access_explainer_card.dart`
  - `apps/haven_child/lib/features/child_usage/views/widgets/daily_screen_time_card.dart`
  - `apps/haven_child/lib/features/child_usage/views/widgets/app_usage_list_card.dart`
  - `apps/haven_child/lib/features/child_usage/views/widgets/usage_permission_denied_card.dart`
  - Widget tests in `apps/haven_child/test/features/child_usage/`
- **Automated Verification**:
  - Widget test suite renders every permission state without error or overflow.

### Step 11: Route & Navigation Integration
- **Can complete independently**: No (depends on Step 10).
- **Dependencies**: Step 10.
- **Files Modified**:
  - `apps/haven_child/lib/app/routes/app_routes.dart` (adds `AppRoutes.childUsage = '/usage'`)
  - `apps/haven_child/lib/app/routes/app_pages.dart` (registers `AppPages.pages` entry)
  - `apps/haven_child/lib/features/permissions/views/child_permission_dashboard_page.dart` (links Usage Access row to `/usage`)
- **Automated Verification**:
  - `fvm flutter test apps/haven_child/test/app/child_app_flow_test.dart`.

### Step 12: Full Regression & Emulator Verification (P-1)
- **Can complete independently**: No (depends on all prior steps).
- **Dependencies**: Steps 1–11.
- **Automated Verification**:
  - Full repo test suite (1,290 baseline + $C$ compatibility + $N_{\text{child\_dart}}$ newly authored tests; exact total measured via command output).
  - Both app analyzers 0 issues.
  - Zero line violations across entire tree (`dart scripts/check_line_counts.dart`).
  - Live execution of 10 emulator verification test scenarios on `emulator-5554`.

---

## 9. Test Strategy and Commands

### 9.1 Multi-Layer Testing Architecture
- **Layer 1: Offline Engine Tests**: Pure Dart local storage engine tests (44 tests) running in `haven_offline`.
- **Layer 2: Child Unit & Widget Tests**: Flutter tests with GetX controllers, theme harnesses, and hand-written fakes.
- **Layer 3: Cross-Language Agreement Tests**: D-4 regex/AST tests reading Kotlin source off disk and verifying exact parity.
- **Layer 4: Native Kotlin JVM Tests (P-5)**: JUnit 4 tests with `isReturnDefaultValues = true` testing aggregation math and permission checks.
- **Layer 5: Live Emulator Verification (P-1)**: End-to-end execution on running `emulator-5554` (API 37).
- **Layer 6: Full Regression Suite**: Protecting the 943 parent tests and 251 child baseline tests.

### 9.2 Test Commands
```powershell
# 1. Line count check (mandatory max 200 lines rule)
dart scripts/check_line_counts.dart

# 2. Static analysis
fvm flutter analyze packages/haven_offline packages/haven_api packages/haven_core packages/haven_models apps/haven_child apps/haven_app

# 3. Native Kotlin tests
cd apps/haven_child/android
./gradlew :app:testDebugUnitTest
cd ../../..

# 4. Dart & Flutter tests
fvm flutter test packages/haven_offline
fvm flutter test packages/haven_api
fvm flutter test packages/haven_core
fvm flutter test packages/haven_models
fvm flutter test apps/haven_child
fvm flutter test apps/haven_app
```

---

## 10. Acceptance Criteria

Stage 3 acceptance requires 100% satisfaction of the following criteria:

1. **Dependency Isolation (Option A)**:
   - `packages/haven_offline` is extracted and passes all 44 tests.
   - `apps/haven_child` has zero dependencies on Firebase or Supabase in `pubspec.yaml`, `pubspec.lock`, `flutter pub deps`, or `.flutter-plugins-dependencies`.
   - Manifest merger reports prove that third-party plugin permissions (`WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, etc.) and all cloud SDK `INTERNET` injections are completely eliminated.
   - Merged release manifest contains zero `INTERNET` permissions. In debug manifests, `INTERNET` is permitted only if verified as legitimate Flutter debug engine tooling.
   - Child APK retains only legitimate permissions: `PACKAGE_USAGE_STATS` (declared special access) and `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (AndroidX signature security).
   - KGP deprecation warnings during child debug build are gone.
2. **Parent Compatibility**:
   - `packages/haven_api` re-exports `haven_offline`. All 943 parent tests pass without modifying parent application code.
3. **P-5 Kotlin Test Infrastructure**:
   - Local JVM unit tests execute via `./gradlew :app:testDebugUnitTest` without network calls or Robolectric shadows.
4. **D-4 Channel Contract Parity**:
   - Automated tests parse `UsageContract.kt` and confirm zero drift with Dart channel code.
5. **Usage Access Live Functionality (Emulator)**:
   - Successfully dispatches Intent to Android Usage Access settings.
   - Detects permission grant and revocation upon app resume.
   - Accurately queries and displays non-system daily screen time and per-app usage.
   - Displays transparent data delay indicators (`"Usage statistics are updated periodically by Android"`).
   - Discards in-memory statistics immediately upon permission revocation and renders an honest denied card with zero fabricated data.
6. **Code Hygiene**:
   - 100% of handwritten `.dart` and `.kt` files are ≤200 lines.
   - Zero analyzer issues across all packages and apps.

---

## 11. Risks and Mitigations

| ID | Risk | Impact | Mitigation |
| :--- | :--- | :--- | :--- |
| **R-1** | Transitive manifest pollution if child still links `haven_api` | High | Implement Step 1–3 first. Add architectural test asserting absence of cloud packages in dependency graph and manifests before writing native code. |
| **R-2** | OEM ROM fails on `package:` URI for Usage Access Settings | Medium | Wrap `Intent(ACTION_USAGE_ACCESS_SETTINGS)` with `package:` URI in a `try-catch`; fall back immediately to generic settings intent if resolution fails. |
| **R-3** | `UsageStatsManager` delay mistaken for application bug | Medium | Display an explicit, permanent notice in the UI footer explaining that Android flushes usage statistics periodically. |
| **R-4** | Exceeding 200-line limit in Kotlin files | Low | Separate concerns into dedicated files: `UsageContract.kt`, `UsageBridgeHandler.kt`, `AppOpsPermissionReader.kt`, `SettingsNavigator.kt`, `UsageStatsReader.kt`, `UsageAggregator.kt`. |
| **R-5** | Gradle build breaks in offline environment | Low | Use JUnit 4 (`junit:junit:4.13.2` is already in local Gradle cache) and avoid Robolectric shadow downloads. |
| **R-6** | Accidental persistence of transient usage data | Low | Enforce transient in-memory architecture in `ChildUsageRepository`. Do not inject `LocalStore` into the usage feature. |

---

## 12. Rollback Strategy

If any unresolvable issue occurs during Stage 3 implementation:
1. **Dependency Extraction Rollback**:
   - Revert `packages/haven_api/pubspec.yaml`, `packages/haven_api/lib/haven_api.dart`, and `apps/haven_child/pubspec.yaml`.
   - Restore `packages/haven_api/lib/src/offline/` and `packages/haven_api/test/offline/` from git HEAD.
2. **Native Lane Rollback**:
   - Delete `apps/haven_child/android/app/src/main/kotlin/com/haven/child/usage/` and `apps/haven_child/android/app/src/test/kotlin/com/haven/child/usage/`.
   - Revert `MainActivity.kt`, `AndroidManifest.xml`, and `build.gradle.kts`.
3. **Flutter Feature Rollback**:
   - Delete `apps/haven_child/lib/features/child_usage/` and `apps/haven_child/lib/core/native/usage_*`.
   - Revert route entries in `app_routes.dart` and `app_pages.dart`.
- The repository returns cleanly to the starting baseline commit **`b5fd32d`** (and code baseline `8fccd66`).

---

## 13. Emulator Verification Checklist (`emulator-5554`, Android 17 / API 37)

| # | Verification Scenario | ADB / Action Step | Expected Observed Result | Status |
| :- | :--- | :--- | :--- | :--- |
| **E-1** | Initial Denied State | Launch child app; navigate to Usage screen. | `UsagePermissionDeniedCard` shown; 0 usage data; explainer visible. | Pending Auth |
| **E-2** | Settings Navigation | Tap "Grant Usage Access" button. | Android OS Usage Access settings page opens. | Pending Auth |
| **E-3** | Grant via ADB | `adb -s emulator-5554 shell cmd appops set com.haven.child GET_USAGE_STATS allow` | App resumed; status updates to `granted`; usage summary loads in memory. | Pending Auth |
| **E-4** | Usage Accumulation | Open Chrome / Calculator on emulator; return to child app. | Foreground time increases; Chrome / Calculator appear in top apps list. | Pending Auth |
| **E-5** | Data Delay Disclosure | Inspect UI footer. | Notice `"Usage statistics are updated periodically by the Android system"` is visible. | Pending Auth |
| **E-6** | Midnight Boundaries | Query usage starting at today 00:00:00 local time. | Only usage from the current calendar day is aggregated into daily total. | Pending Auth |
| **E-7** | Revoke Permission | `adb -s emulator-5554 shell cmd appops set com.haven.child GET_USAGE_STATS ignore` | App resumed; UI transitions immediately back to Denied card. In-memory data wiped. | Pending Auth |
| **E-8** | Invalid Time Range | Call channel with `startTimeMillis >= endTimeMillis`. | Returns typed Flutter error `invalid-range`; error state rendered cleanly. | Pending Auth |
| **E-9** | System App Categorization | Inspect apps list. | System UI / launcher / keyboards filtered or categorized away from main list. | Pending Auth |
| **E-10**| Zero Network Traffic | Monitor emulator logcat and network socket state. | Zero network requests initiated; no Firebase/Supabase initialization. | Pending Auth |

---

## 14. Definition of Done (Stage 3)

Stage 3 will be marked **COMPLETE WITH LIMITATIONS** when:
1. `packages/haven_offline` is created, tested (44 tests), and cleanly re-exported by `haven_api`.
2. `apps/haven_child` is verified completely free of transitive cloud dependencies across `pubspec.yaml`, `pubspec.lock`, `flutter pub deps`, `.flutter-plugins-dependencies`, and merger reports.
3. Merged debug and release manifests are inspected; cloud plugin permissions (`WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `c2dm.permission.RECEIVE`, `READ_GSERVICES`, etc.) and cloud SDK `INTERNET` injections are verified absent; `INTERNET` is absent in release; only `PACKAGE_USAGE_STATS` and `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` remain.
4. Native Kotlin components are implemented under ≤200 lines per file and tested with JVM JUnit 4 tests.
5. D-4 cross-language key-agreement tests pass with zero drift.
6. All 10 emulator verification checklist scenarios are executed and evidenced on `emulator-5554`.
7. Usage statistics are strictly transient in-memory and wiped on revocation.
8. Full test regression passes with 100% success (Parent 943, Child 251 + $N_{\text{child\_dart}}$, Offline 44, API 22 + $C$, Core 18, Models 12; Total Dart = $1,290 + C + N_{\text{child\_dart}}$).
9. `STAGE_3_IMPLEMENTATION_REPORT.md` is authored using actual command output and honest limitations recorded.

---

## 15. Explicit List of Excluded Functionality

The following items are **strictly excluded** from Stage 3 scope:
- **No Background Services**: No foreground services, sticky notifications, or WorkManager tasks.
- **No EventChannel**: No continuous native polling streams or background threads.
- **No Real Enforcement / App Blocking**: No overlay windows (`SYSTEM_ALERT_WINDOW`), accessibility services, or task killing.
- **No Location Monitoring**: No GPS, network location, or geofence monitoring.
- **No Cloud Synchronization**: No Supabase or Firebase telemetry transmission; data remains transient in memory.
- **No Physical Hardware Claims**: Testing is bounded to `emulator-5554`; physical device testing remains deferred.
- **No Fabricated Data**: If permission is denied or stats unavailable, the app displays an honest empty state, never simulated numbers.
- **No Persistent Usage Cache**: No local database tables or file persistence for screen-time statistics.
