# ANDROID NATIVE & CHILD SERVICES AUDIT

**Target Location:** `D:\control\android_native\child_services` and `D:\control\apps\haven_app\android`  
**Audit Date:** 2026-11-05  
**Audit Standard:** Strict Evidence-Based Audit (Zero-Assumptions, Exact Path & Line Citations)  
**Verification Level:** Read-Only Source Inspection + Build Verification

---

## 1. EXECUTIVE SUMMARY

1. **No Standalone Native Child App:** There is no separate native Android project or APK subproject for the child application in the repository. The Kotlin source located at `android_native/child_services/` is compiled directly into the single Flutter application (`apps/haven_app`) via Gradle `sourceSets` mapping ([`apps/haven_app/android/app/build.gradle.kts:41`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41)).
2. **Read-Only OS State Probe Only:** The native implementation is strictly a read-only OS diagnostics reader (`HavenBridge.kt`, method `state.readAll` on channel `haven.dev/child_device_state`). It contains **zero enforcement engines, zero background services, zero command executors, zero telemetry senders, and zero media capture pipelines**.
3. **Intentional Refusal Model:** The native layer adheres strictly to the project's documented refusal model ([`docs/architecture/04-refusal-model.md`](file:///d:/control/docs/architecture/04-refusal-model.md)). Coordinates (latitude and longitude) are deliberately stripped before leaving the file ([`android_native/child_services/location/LocationStateReader.kt:17-20`](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L17-L20)), device-admin force-lock is never invoked ([`android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt:12-16`](file:///d:/control/android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt#L12-L16)), and media capture is locked ([`android_native/child_services/communication/CommunicationStateReader.kt:16-20`](file:///d:/control/android_native/child_services/communication/CommunicationStateReader.kt#L16-L20)).
4. **Test & Device Verification:** **0 native unit tests, 0 native instrumentation tests, 0% test coverage**. The native Kotlin code has **never been run on a physical device or emulator** ([`docs/testing/README.md:93-96`](file:///d:/control/docs/testing/README.md#L93-L96)).
5. **Strict 200-Line Limit:** **100% compliant**. All 11 Kotlin source files, 9 XML files, and 3 Gradle files are strictly under 200 lines (longest Kotlin file is 113 lines).

---

## 2. NATIVE PROJECT STRUCTURE & BUILD CONFIGURATION

### 2.1 File & Module Hierarchy
The repository does not treat `android_native/child_services/` as a Gradle module or subproject:

- [`apps/haven_app/android/settings.gradle.kts:26`](file:///d:/control/apps/haven_app/android/settings.gradle.kts#L26): Only includes `:app`.
- [`apps/haven_app/android/app/build.gradle.kts:36-43`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L36-L43):
  ```kotlin
  sourceSets {
      getByName("main") {
          // The child-device native lane is repo-level code, not module code: it
          // lives at android_native/child_services so it can be read, counted and
          // reviewed beside the Dart it answers, and is compiled from there.
          java.srcDir("../../../../android_native/child_services")
      }
  }
  ```
- Package Namespace:
  - Application ID: `com.haven.haven_app` ([`apps/haven_app/android/app/build.gradle.kts:19`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L19)).
  - Kotlin Namespace: `com.haven.haven_app` ([`apps/haven_app/android/app/build.gradle.kts:8`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L8)).
  - *Discrepancy Note:* Staging documentation and historical APKs ([`docs/stage1/evidence/g2-apk-identity-20261030.md`](file:///d:/control/docs/stage1/evidence/g2-apk-identity-20261030.md)) reference `com.haven.familysafety`, whereas the local Flutter Gradle project declares `com.haven.haven_app`.

### 2.2 Effective SDK Versions & Dependencies
- `minSdkVersion`: 24 (Android 7.0 Nougat)
- `targetSdkVersion`: 36 (Android 16 preview)
- `compileSdkVersion`: 36
- JVM Target: Java 17 ([`apps/haven_app/android/app/build.gradle.kts:13-14, 48`](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L13-L14))
- **Native Dependencies Block:** **Completely absent**. `app/build.gradle.kts` has no `dependencies { ... }` block for native Android libraries. Missing libraries include:
  - `androidx.work:work-runtime-ktx` (WorkManager)
  - `org.jetbrains.kotlinx:kotlinx-coroutines-android`
  - `androidx.lifecycle:lifecycle-service`
  - `com.google.android.gms:play-services-location`
  - `org.webrtc:google-webrtc`

---

## 3. MANIFEST PERMISSIONS & RUNTIME PERMISSIONS

### 3.1 Declared Manifest Permissions
Source file: [`apps/haven_app/android/app/src/main/AndroidManifest.xml`](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml)
- **Declared in `<uses-permission>`:**
  - Line 7: `<uses-permission android:name="android.permission.INTERNET" />`
- **Receiver Permission:**
  - Line 45: `android.permission.BIND_DEVICE_ADMIN` on `HavenDeviceAdminReceiver`

### 3.2 Undeclared Permissions (Critical Deficits)
The following permissions required for parental control background monitoring are **completely absent** from the source manifest:
- `FOREGROUND_SERVICE` and foreground types (`FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_SPECIAL_USE`)
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- `PACKAGE_USAGE_STATS`
- `SYSTEM_ALERT_WINDOW` (display overlays / app blocking)
- `RECEIVE_BOOT_COMPLETED` (auto-restart on reboot)
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `CAMERA`, `RECORD_AUDIO`

*(Note: In debug APK builds, plugins like `connectivity_plus` inject `ACCESS_NETWORK_STATE` and `firebase_messaging` injects `POST_NOTIFICATIONS` / `WAKE_LOCK`, but none are declared by Haven's child services).*

### 3.3 Runtime Permission Handling
- Native code has **no mechanism to request permissions** (no `requestPermissions` or `ActivityResultLauncher`).
- [`android_native/child_services/permissions/PermissionStateReader.kt:21-47`](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L21-L47): Only checks `context.checkPermission(...) == PERMISSION_GRANTED`. Because permissions are undeclared in the manifest, the reader returns `status: undeclared` for all tracked permissions.

---

## 4. BACKGROUND SERVICES & LIFECYCLE AUDIT

| Component | Status | Source Evidence & Line Citation |
|---|---|---|
| **Foreground Service** | **NOT IMPLEMENTED** | 0 classes extend `android.app.Service`. [`MonitoringStateReader.kt:97-111`](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L97-L111) queries package services dynamically and reports count = 0. |
| **Notification Channels** | **NOT IMPLEMENTED** | No `NotificationChannel` creation in native source. |
| **WorkManager** | **NOT IMPLEMENTED** | 0 references in build scripts and Kotlin source. |
| **AlarmManager** | **READ-ONLY PROBE** | [`MonitoringStateReader.kt:41-43`](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L41-L43) checks `canScheduleExactAlarms()`. No alarms are scheduled. |
| **Boot Completed Receiver** | **NOT IMPLEMENTED** | No receiver for `BOOT_COMPLETED`. [`PermissionStateReader.kt:42`](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L42) confirms `bootReceiverDeclared: false`. |
| **Process Restart Handling** | **NOT IMPLEMENTED** | No sticky service, no watchdog alarm, no native restart mechanism. |
| **Battery Optimization** | **READ-ONLY PROBE** | [`MonitoringStateReader.kt:31-34`](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L31-L34) checks `PowerManager.isIgnoringBatteryOptimizations()`. No request intent is ever fired. |

---

## 5. CHILD SERVICES FUNCTIONALITY MATRIX

### 5.1 Device Registration & Identity
- **Status:** **NOT IMPLEMENTED**.
- **Evidence:** The Kotlin layer contains no HTTP client, no Supabase/Firebase SDK, no token store, and no knowledge of `x-device-id` or `x-device-secret`.

### 5.2 Device Telemetry Collection
- **Battery & Network:** No battery level, charging status, or network connection telemetry collectors.
- **App Inventory:** No `getInstalledApplications()` query; `device_apps` snapshot cannot be collected by native code.
- **Monitoring State Reader:** [`MonitoringStateReader.kt:27-46`](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L27-L46) inspects AppOps `get_usage_stats` mode, notification policy access, and silent mode.

### 5.3 Location Service
- **Provider:** Framework `LocationManager` ([`LocationStateReader.kt:29`](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L29)). Google Play Services `FusedLocationProviderClient` is not used.
- **Deliberate Coordinate Withholding:**
  [`LocationStateReader.kt:17-20`](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L17-L20):
  > *"No coordinates leave this file. This lane answers the question 'could a location be reported at all', and a fix's latitude and longitude are not part of that answer. Sending them would put a child's position on a channel a settings screen reads, and the brief does not ask for that."*
- **Background Location & Geofencing:** **NOT IMPLEMENTED**. No location updates are requested or streamed.

### 5.4 Policy Enforcement & Command Execution
- **App Blocking & Web Filtering:** **NOT IMPLEMENTED**. No AccessibilityService, VPNService, or UsageStats overlay monitor.
- **Screen Lock:**
  - Device admin XML declares `<force-lock />` policy ([`apps/haven_app/android/app/src/main/res/xml/haven_device_admin.xml:15-17`](file:///d:/control/apps/haven_app/android/app/src/main/res/xml/haven_device_admin.xml#L15-L17)).
  - [`HavenDeviceAdminReceiver.kt:12-16`](file:///d:/control/android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt#L12-L16):
    > *"It remembers nothing and starts nothing... this build has no code path that enforces anything, because the command lane that would authorise one is blocked at the backend."*
  - `DevicePolicyManager.lockNow()` is never called anywhere in the codebase.
- **Command Handling:** **NOT IMPLEMENTED**.

### 5.5 Remote Media & Streaming (WebRTC / Camera / Mic)
- **WebRTC & Screen Capture:** **NOT IMPLEMENTED**. No `MediaProjectionManager`, no virtual display, no WebRTC peer connection.
- **Hardware Inquiry Only:** [`CommunicationStateReader.kt:16-20`](file:///d:/control/android_native/child_services/communication/CommunicationStateReader.kt#L16-L20) only queries `AudioManager.mode`, microphone mute state, speakerphone state, and camera count via `CameraManager.cameraIdList.size`. Capture is never started.

---

## 6. FLUTTER <-> NATIVE COMMUNICATION (METHODCHANNEL)

### 6.1 Channel Definition & Surface
- **Channel Name:** `haven.dev/child_device_state` ([`BridgeContract.kt:13`](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L13))
- **Supported Methods:** Exactly **one** method: `state.readAll` ([`BridgeContract.kt:16`](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L16))
- **EventChannels:** **0 EventChannels**. Asynchronous event push from native to Flutter is impossible.

### 6.2 Connection Trace
1. **Engine Attachment:** [`MainActivity.kt:15-19`](file:///d:/control/apps/haven_app/android/app/src/main/kotlin/com/haven/haven_app/MainActivity.kt#L15-L19) invokes `HavenBridge.forApp { applicationContext }.attach(flutterEngine.dartExecutor.binaryMessenger)`.
2. **Native Handler:** [`HavenBridge.kt:28-51`](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L28-L51) handles `state.readAll`, executes 5 state readers, and returns a JSON dictionary (`apiLevel`, `osRelease`, `sections`, `sectionErrors`).
3. **Flutter Side:** [`apps/haven_app/lib/core/permissions/channel_device_state.dart:30-66`](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart#L30-L66) invokes `MethodChannel('haven.dev/child_device_state').invokeMapMethod('state.readAll')`.
4. **UI Presentation:** Consumed by `SettingsController.load()` ([`settings_controller.dart:55`](file:///d:/control/apps/haven_app/lib/features/settings/controllers/settings_controller.dart#L55)) and displayed on `PermissionStatusPage` ([`permission_status_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart#L18)).

### 6.3 Missing Bridges
There are no MethodChannels or EventChannels for:
- Executing remote device commands
- Pushing location fixes or battery/network telemetry
- Enforcing app or web blocklists
- Streaming WebRTC audio/video

---

## 7. TESTING & DEVICE VERIFICATION

- **Unit Tests:** 0 tests in `android_native/child_services/src/test/` (directory is empty).
- **Instrumentation Tests:** 0 tests in `apps/haven_app/android/app/src/androidTest/` (directory does not exist).
- **Device Run Status:** Never deployed or executed on a real device or emulator ([`docs/testing/README.md:93-96`](file:///d:/control/docs/testing/README.md#L93-L96)).
- **Compilation Status:** Compiles successfully into `app-debug.apk` (164,102,984 bytes, 2026-11-04 per [`docs/testing/README.md:16`](file:///d:/control/docs/testing/README.md#L16)).

---

## 8. STRICT 200-LINE SOURCE FILE AUDIT

All 11 Kotlin source files, 9 XML resource files, and 3 Gradle files were verified:

| File Path | Lines | Rule Limit | Status |
|---|---|---|---|
| `android_native/child_services/monitoring/MonitoringStateReader.kt` | 113 | 200 | PASS |
| `android_native/child_services/platform_bridge/OsAnswers.kt` | 96 | 200 | PASS |
| `android_native/child_services/device_admin/DeviceAdminStateReader.kt` | 87 | 200 | PASS |
| `android_native/child_services/platform_bridge/HavenBridge.kt` | 84 | 200 | PASS |
| `android_native/child_services/location/LocationStateReader.kt` | 74 | 200 | PASS |
| `android_native/child_services/communication/CommunicationStateReader.kt` | 59 | 200 | PASS |
| `android_native/child_services/permissions/PermissionStateReader.kt` | 45 | 200 | PASS |
| `android_native/child_services/platform_bridge/DeviceStateReader.kt` | 33 | 200 | PASS |
| `android_native/child_services/platform_bridge/BridgeContract.kt` | 29 | 200 | PASS |
| `apps/haven_app/android/app/src/main/kotlin/com/haven/haven_app/MainActivity.kt` | 18 | 200 | PASS |
| `android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt` | 15 | 200 | PASS |
| `apps/haven_app/android/app/src/main/AndroidManifest.xml` | 69 | 200 | PASS |
| `apps/haven_app/android/app/build.gradle.kts` | 54 | 200 | PASS |
| `apps/haven_app/android/settings.gradle.kts` | 26 | 200 | PASS |
| `apps/haven_app/android/build.gradle.kts` | 24 | 200 | PASS |
| All other XML/drawable files | 7-17 | 200 | PASS |

**Violations:** 0 files exceed 200 lines.

---

## 9. REMAINING WORK FOR NATIVE CHILD MONITORING

To transform the read-only inspection probe into a fully functional parental control child client:
1. **Declare Required Permissions:** Add foreground service, background location, usage stats, system alert window, boot completed, and battery optimization permissions to `AndroidManifest.xml`.
2. **Implement Foreground Service:** Author a persistent foreground service with a persistent notification channel to maintain process priority.
3. **Implement Boot & Restart Watchdogs:** Create a `BroadcastReceiver` on `BOOT_COMPLETED` and WorkManager periodic workers.
4. **Implement Real Telemetry Collection:** Add background workers to collect battery, network, and installed app inventory.
5. **Implement Real-Time Location Tracker:** Integrate Google Play Services `FusedLocationProviderClient` with distance/interval filters.
6. **Implement Policy Enforcement:** Build an app-blocking overlay engine via `SYSTEM_ALERT_WINDOW` or AccessibilityService, and hook `DevicePolicyManager.lockNow()`.
7. **Expand MethodChannel / EventChannel:** Add channels for commands, policies, and async telemetry events.
8. **Add Native Test Suites:** Create Robolectric unit tests and instrumentation tests verified on physical Android devices.

