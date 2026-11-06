# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2: ANDROID CAPABILITY INVENTORY

**Scope**: documentation-only, Module-C-style inventory of the Android platform capabilities that Stage 2
("Registration contracts + capability inventory" — `docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md:89`)
will have to reason about.
**Method**: static reading of source, manifests and Gradle files only. **No build, no test run, no experiment,
no install, no device, no git write was performed by this agent.**
**Date**: November 6, 2026 (Agent 4 of the Stage-2 readiness-only pass).
**Labels**: `FACT` = this agent opened the file and read the cited line. `FACT(doc)` = a number recorded in a
Stage-1 document; reproduced here, **not re-run**. `VERIFIED-BY-TEST` = used only when quoting a test that the
cited file itself contains. `INFERRED` = reasoned from cited code, not directly stated by it. `PROPOSED` =
suggestion, **not approved**. `UNVERIFIED` = cannot be established from source alone.
**Nothing in this file is a device claim.** Ladder ( `PHASE_3_MASTER_PLAN.md:14`, UI → Flutter logic → Kotlin
native → permission granted → physical device → parent-child E2E): the highest level any row below can reach is
**level 3 partial, and only on the parent side**, because no build has ever run this Kotlin on hardware
(`STAGE_1_KNOWN_LIMITATIONS.md:34-36`).

---

## 1. Build identities and where the Kotlin actually compiles

| Item | Value | Citation | Label |
| :--- | :--- | :--- | :--- |
| Parent namespace / applicationId | `com.haven.haven_app` / `com.haven.haven_app` | `apps/haven_app/android/app/build.gradle.kts:8`, `:19` | FACT |
| Child namespace / applicationId | `com.haven.child` / `com.haven.child` | `apps/haven_child/android/app/build.gradle.kts:10`, `:21` | FACT |
| `android_native/child_services` is compiled **into the parent only** | `java.srcDir("../../../../android_native/child_services")` inside `sourceSets { getByName("main") }` | `apps/haven_app/android/app/build.gradle.kts:36-43` (srcDir at `:41`) | FACT |
| Every Kotlin file in that tree declares the **parent** package | `package com.haven.haven_app.child_services.*` | `android_native/child_services/platform_bridge/BridgeContract.kt:1`; `monitoring/MonitoringStateReader.kt:1`; `device_admin/DeviceAdminStateReader.kt:1` | FACT |
| Child Gradle project has **no srcDir redirect** | child `android {}` block contains no `sourceSets`/`srcDir` at all | `apps/haven_child/android/app/build.gradle.kts:7-37` (read whole file) | FACT |
| Child Kotlin sources | exactly one: `class MainActivity : FlutterActivity()` (5 lines) | `apps/haven_child/android/app/src/main/kotlin/com/haven/child/MainActivity.kt:1-5`; corroborated `STAGE_1_KNOWN_LIMITATIONS.md:28` | FACT |
| Consequence | the child app **cannot compile or reach** `android_native/child_services` today; a child-side lane needs either a child srcDir/module or a child `MainActivity` attach | from the four rows above | INFERRED |
| Parent attaches the bridge on engine start | `HavenBridge.forApp { applicationContext }.attach(...)` in `configureFlutterEngine` | `apps/haven_app/android/app/src/main/kotlin/com/haven/haven_app/MainActivity.kt:15-19` | FACT |
| SDK floors as merged by the Stage-1 child build | `minSdkVersion="24"`, `targetSdkVersion="36"` | `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:7-9` (build artifact, not source) | FACT (artifact) |
| Native lane file inventory | 10 Kotlin files, 713 lines total (`wc -l`) | `communication/CommunicationStateReader.kt` 64, `device_admin/DeviceAdminStateReader.kt` 95, `device_admin/HavenDeviceAdminReceiver.kt` 17, `location/LocationStateReader.kt` 82, `monitoring/MonitoringStateReader.kt` 122, `permissions/PermissionStateReader.kt` 48, `platform_bridge/BridgeContract.kt` 35, `platform_bridge/DeviceStateReader.kt` 37, `platform_bridge/HavenBridge.kt` 89, `platform_bridge/OsAnswers.kt` 104 | FACT |

---

## 2. The existing native bridge, documented exactly

| Property | Answer | Citation | Label |
| :--- | :--- | :--- | :--- |
| Transport | one `MethodChannel` (no other plugin-common type) | `android_native/child_services/platform_bridge/HavenBridge.kt:5-7`, `:22-26` | FACT |
| Channel name | `haven.dev/child_device_state` | Kotlin `BridgeContract.kt:13` ↔ Dart `apps/haven_app/lib/core/permissions/channel_device_state.dart:14` | FACT |
| Method name | `state.readAll` — the only one answered | Kotlin `BridgeContract.kt:16`; enforced `HavenBridge.kt:29-36`; Dart `channel_device_state.dart:15` | FACT |
| Any other method | `reply.error("unknown-method", ...)` | `BridgeContract.kt:24`; `HavenBridge.kt:29-36` | FACT |
| No context | `reply.error("no-context", ...)` | `BridgeContract.kt:27`; `HavenBridge.kt:42-49` | FACT |
| Response envelope keys | `apiLevel`, `osRelease`, `sections`, `sectionErrors` | `BridgeContract.kt:18-21`; built at `HavenBridge.kt:68-73` | FACT |
| Readers registered | **5**: permissions, monitoring, location, deviceAdmin, communication | `HavenBridge.kt:80-87`; section names `platform_bridge/DeviceStateReader.kt:31-37` | FACT |
| Failure granularity | a throwing reader is filed under its own section as `section-failed`; the other four still answer | `HavenBridge.kt:58-67`; `BridgeContract.kt:34` | FACT |
| Value codec rule | only what a MethodChannel carries natively; `null` means "the OS could not be asked", never "no" | `DeviceStateReader.kt:20-24`; `OsAnswers.kt:9-16`, `:22-34` | FACT |
| Write/apply surface | **none by design** — "Adding an 'apply' method would let a screen claim a restriction the OS had not confirmed" | `HavenBridge.kt:13-17` (comment), whole file has one method | FACT |
| EventChannel | **zero** anywhere in the repo | grep for `EventChannel` across `apps`, `packages`, `android_native` (`.dart`/`.kt`): no matches | FACT |
| BasicMessageChannel | **zero** | same grep sweep | FACT |
| Pigeon | **absent**: no `pigeon` in any pubspec/lock/gradle/kts, no `pigeons/` dir, no generated file | grep sweep over `apps`, `packages`, `android_native`, `scripts` | FACT |
| Drift defense today | one verbatim-string test in the **parent** suite: `expect(DeviceStateChannel.name, 'haven.dev/child_device_state')` / `expect(DeviceStateChannel.readAllMethod, 'state.readAll')`, plus a real `MethodChannel` + `setMockMethodCallHandler` harness | `apps/haven_app/test/permissions/channel_device_state_test.dart:21-30`, `:38-43` | FACT |
| Self-declared weakness | "changing one without the other is a compile-time error on neither side" | `channel_device_state.dart:10-12`; restated in the test comment `:39-40` | FACT |
| Who consumes the bridge | only the parent app (`ChannelNativeDeviceState`, settings controller). The child app has **no channel use at all** | `apps/haven_app/lib/features/settings/controllers/settings_controller.dart:6`; grep `MethodChannel`/`EventChannel` under `apps/haven_child/lib` → no matches | FACT |
| Child-side device facts are pure Dart | `RealDeviceInformation` reads only `dart:io` | `apps/haven_child/lib/core/device/real_device_information.dart:1`, `:6-15` | FACT |

---

## 3. Capability matrix

"Read by Stage-1 code?" means: does code that shipped in Stage 1 actually ask the OS this question. "Honest
Stage-1 status" uses: `not implemented` / `genuinely read via channel (parent-side, never run on a device)` /
`blocked`.

| # | Capability | Current usage in this repo (cited, or "absent") | Read by Stage-1 code? | Real Android API surface | Permission / settings requirement | Honest Stage-1 status |
| :-- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Installed-app inventory + package visibility | **No native reader.** Contract shapes exist only: `TableName.deviceApps = 'device_apps'` `packages/haven_api/lib/src/backend_endpoints.dart:48`; RPC `replace_device_apps` `:115`; row model `DeviceApp(packageName,isSystem,isSuspended,reportedAt,versionName)` `packages/haven_models/lib/src/device_models.dart:104-116`; args `packages/haven_models/lib/src/rpc_args_device.dart:56-62`; a hand-written UI catalogue `apps/haven_app/lib/features/policies/data/app_catalogue.dart:16-25`. grep `getInstalledPackages\|queryIntentActivities\|QUERY_ALL_PACKAGES\|getInstalledApplications` over `apps`+`android_native`: **zero source matches**. Child manifest declares **no `<queries>`** `apps/haven_child/android/app/src/main/AndroidManifest.xml:41-47`; parent declares only the template PROCESS_TEXT query `apps/haven_app/android/app/src/main/AndroidManifest.xml:66-71` | No | `PackageManager.getInstalledPackages/getInstalledApplications`, `queryIntentActivities`, `resolveActivity`; Android 11+ requires `<queries>` elements or `QUERY_ALL_PACKAGES` (Play-policy-sensitive) | `QUERY_ALL_PACKAGES` is the blunt option; the honest option is narrow `<queries>` per use case. Nothing in either manifest does this today | `not implemented` — and note the nearest thing that exists, `PackageInfo(GET_SERVICES)` (`MonitoringStateReader.kt:99-101`), returns **this package's own** services, not an installed-app list |
| 2 | `UsageStatsManager` (per-app foreground counts) | **Absent.** grep `UsageStatsManager\|queryUsageStats\|queryEvents` over `apps`+`android_native`+`packages`: zero matches. Only the *access gate* is read: app-ops `android:get_usage_stats` via `AppOpsManager.unsafeCheckOpNoThrow`/`checkOpNoThrow` `android_native/child_services/monitoring/MonitoringStateReader.kt:50-63`, op name constant `:118-121`; contracts for the numbers exist in `packages/haven_models/lib/src/telemetry_models.dart:3-18` (`UsageDaily`) | Only the mode, not the counts (parent-side reader; never run on a device) | `UsageStatsManager.queryUsageStats` / `queryEvents`; `AppOpsManager` for the special-access mode | `PACKAGE_USAGE_STATS` is **not** a runtime permission — it is Settings-granted special access. The code says so and deliberately excludes it from `checkPermission`, because "checkPermission answers 'denied' … even when the app-op is allowed" `OsAnswers.kt:76-80` | `genuinely read via channel` **for the mode only**, parent-side; the counts are `not implemented` |
| 3 | Battery info | Two narrow exemption reads: `PowerManager.isIgnoringBatteryOptimizations` `MonitoringStateReader.kt:31-34` (API-M guarded) and the declared-permission probe `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` `permissions/PermissionStateReader.kt:38-41`. **No** `BatteryManager`/`EXTRA_LEVEL`/`ACTION_BATTERY_CHANGED` anywhere (grep). The only battery *numbers* in the repo are fabricated DEMO values: `'battery_level': 95`, `'is_charging': false` `apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart:115-116` | Only the exemption flags (parent-side); numbers: no | `BatteryManager.getIntProperty(BATTERY_PROPERTY_CAPACITY)`, `ACTION_BATTERY_CHANGED` sticky broadcast, `PowerManager` | Battery level needs no permission; exemption **needs** the declaration the child app does not make `apps/haven_child/android/app/src/main/AndroidManifest.xml:2-8` | `not implemented` for level/charging; the DEMO row is labelled simulation, never device truth (`PHASE_3_MASTER_PLAN.md:15` rule 3) |
| 4 | `Build.MANUFACTURER` / `MODEL` / `VERSION` / `SDK_INT` | `Build.VERSION.SDK_INT` and `Build.VERSION.RELEASE` are returned as `apiLevel`/`osRelease` `HavenBridge.kt:69-70`; `Build.VERSION_CODES.*` used only as API guards (`MonitoringStateReader.kt:31,35,41,52,107`; `LocationStateReader.kt:71`; `OsAnswers.kt:43,90-98`). **`MANUFACTURER`/`MODEL` appear only in comments**, never in code: `apps/haven_child/lib/core/device/device_information.dart:5`, `real_device_information.dart:12`; grep over `.kt`: zero. Child returns `null` for both `real_device_information.dart:33-35`, rendered `Unavailable` with footnote `device_fact_rows.dart:18-26`, `:33-36`; `Platform.operatingSystemVersion` **is** a real pure-Dart read `real_device_information.dart:23-28` | SDK_INT/RELEASE yes (parent-side, via channel); MANUFACTURER/MODEL no | `android.os.Build.MANUFACTURER`, `Build.MODEL`, `Build.VERSION.RELEASE`, `Build.VERSION.SDK_INT` (no permission on any API level; Android 15+ gates `Build.MODEL` behind… nothing for normal installs — `UNVERIFIED` here, not tested) | None for these four constants | `genuinely read via channel` for SDK_INT/RELEASE (parent-side, never on a device); `not implemented` for MANUFACTURER/MODEL; the child's own `androidVersion` is a real `dart:io` read at level 2 |
| 5 | `POST_NOTIFICATIONS` (runtime notification permission) | Declared as a tracked permission: `NOTIFICATIONS(Manifest.permission.POST_NOTIFICATIONS, TIRAMISU, "notifications")` `OsAnswers.kt:90`; answered by `checkPermission` `OsAnswers.kt:42-50` and split into granted vs **undeclared** `PermissionStateReader.kt:21-46`. Neither source manifest declares it (`apps/haven_child/android/app/src/main/AndroidManifest.xml:1-48`; parent declares only `INTERNET` `apps/haven_app/android/app/src/main/AndroidManifest.xml:7`). **But** the Stage-1 child *build artifact* merged manifest carries it: `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:14` | Read only parent-side; `null` on any device where the parent APK also lacks the declaration | `Context.checkPermission`, `NotificationManager.areNotificationsEnabled`, `ActivityCompat.requestPermissions` on API 33+ | Runtime grant; a not-declared permission can never be granted — the code states this explicitly `OsAnswers.kt:52-57` | `not implemented` in the child; `genuinely read via channel` parent-side (would answer `undeclared`); **the merged-manifest row is a build fact this agent did not produce** |
| 6 | Foreground services | **Absent.** No `<service>` in either source manifest (child comment `apps/haven_child/android/app/src/main/AndroidManifest.xml:41-47`; parent declares one `<receiver>` only `apps/haven_app/android/app/src/main/AndroidManifest.xml:41-53`). grep `FOREGROUND_SERVICE\|startForeground` over `apps`+`android_native`+`packages`: zero. The only related code *reports the manifest's own answer*: service count and `foregroundServiceType` `MonitoringStateReader.kt:96-111` | No — it reports a count that is 0 for both apps today | `Service.startForeground(int, Notification)` / `startForeground(ServiceInfo.FOREGROUND_SERVICE_TYPE_*)` on API 29+; `FOREGROUND_SERVICE` permission; API 34 requires a declared type; OEM battery managers add a second gate | `FOREGROUND_SERVICE` (+ typed variant) declaration and a visible notification | `not implemented`; pre-declared as blocked scope `PHASE_3_MASTER_PLAN.md:84` (B-4) |
| 7 | Background-execution restrictions | Four narrow OS-answer reads, all in `MonitoringStateReader.kt`: `exactAlarmsAllowed` via `AlarmManager.canScheduleExactAlarms` `:41-43` (API S); `notificationImportance` via `NotificationManager.importance` `:35-40` (API N); `batteryOptimizationIgnored` `:31-34` (API M); `silentMode` via `RingtoneManager.getActualDefaultRingtoneUri` `:113-116`. No `JobScheduler`/`WorkManager`/Doze API anywhere | Yes, parent-side, read-only | `AlarmManager.canScheduleExactAlarms`, `NotificationManager.importance`, `PowerManager.isIgnoringBatteryOptimizations`, `AppOpsManager`, Doze/App Standby buckets (`UsageEvents` MOVING) | Settings-granted exemption screens (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`, `ACTION_USAGE_ACCESS_SETTINGS`); OEM (ColorOS) layers are outside the AOSP API | `genuinely read via channel` (parent-side, never run on a device); **no** mitigation is implemented, and the OEM gap is pre-declared `PHASE_3_MASTER_PLAN.md:84` (B-4) |
| 8 | Network state | **Absent from source.** grep `Connectivity` in `apps/haven_app/lib` + `apps/haven_child/lib`: no matches; `ConnectivityManager`/`NetworkCapabilities` in `.kt`: no matches. `connectivity_plus: ^7.3.2` is declared in `apps/haven_app/pubspec.yaml:49` but imported nowhere (INFERRED: declared-unused). `ACCESS_NETWORK_STATE` appears only in plugin build intermediates, e.g. `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:13` and `apps/haven_app/build/connectivity_plus/…/AndroidManifest.xml:7` | No | `ConnectivityManager.activeNetwork`, `NetworkCapabilities.hasTransport`, `registerNetworkCallback`; or `connectivity_plus` from Dart | `ACCESS_NETWORK_STATE` (not declared in either source manifest) | `not implemented`; the child is deliberately offline — "the child app is fully local at this stage: no backend, no network lane, so `android.permission.INTERNET` is deliberately absent" `apps/haven_child/android/app/src/main/AndroidManifest.xml:2-8` |
| 9 | *(supplement)* Device admin / `DevicePolicyManager` | Parent-side reader `device_admin/DeviceAdminStateReader.kt:22-54` (adminActive, deviceOwner, profileOwner, screen-lock timeout, password quality, storage encryption, `userRestrictionsReadable`) + a bare receiver `device_admin/HavenDeviceAdminReceiver.kt:17` declared in the **parent** manifest `apps/haven_app/android/app/src/main/AndroidManifest.xml:41-53` | Yes, parent-side, read-only | `DevicePolicyManager.*`, `BIND_DEVICE_ADMIN`, `ACTION_DEVICE_ADMIN_SETTINGS` | Enrollment must be a human Settings action; non-admin callers get `null`, which the code treats as the stop-sign `DeviceAdminStateReader.kt:13-21`, `:30-34` | `genuinely read via channel` parent-side; nothing enforces — "nothing here enrolls, and nothing here enforces" `apps/haven_app/android/app/src/main/AndroidManifest.xml:35-40` |
| 10 | *(supplement)* Location providers | Parent-side `location/LocationStateReader.kt:25-77`: provider on/off, `mayAsk`, newest cached fix metadata; **no coordinates leave the file** `:16-24` | Yes, parent-side | `LocationManager.isProviderEnabled`, `getLastKnownLocation` | `ACCESS_FINE_LOCATION` (M), `ACCESS_BACKGROUND_LOCATION` (Q) tracked in `OsAnswers.kt:91-96`; neither declared | `genuinely read via channel` parent-side for provider state; continuous/foreground location is DEFERRED `docs/implementation/phase_1/DEFERRED_FEATURES.md:35-37` |
| 11 | *(supplement)* Mic / camera hardware presence | Parent-side `communication/CommunicationStateReader.kt:22-54`: `AudioManager` state, `CameraManager.cameraIdList.size`; "no call in this file can start capture" `:16-21` | Yes, parent-side | `AudioManager`, `CameraManager`, `Manifest.permission.RECORD_AUDIO`/`CAMERA` (`OsAnswers.kt:97-98`) | Runtime grant needed to *use*; none needed to *count* | `genuinely read via channel` parent-side; media capture is out of scope `docs/implementation/00-app-contract.md:104-107` |

---

## 4. Manifest truth: source vs merged

| Claim | Evidence | Label |
| :--- | :--- | :--- |
| Child **source** manifest declares zero permissions, no `<queries>`, no receivers, no services, no device-admin | `apps/haven_child/android/app/src/main/AndroidManifest.xml:2-8` and `:41-47`; the whole file (48 lines) contains only the launcher activity + Flutter embedding metadata `:9-39` | FACT |
| Child debug/profile source manifests are deliberately empty of `INTERNET` | `apps/haven_child/android/app/src/debug/AndroidManifest.xml:2-8` ("we removed it on purpose") | FACT |
| Parent **source** manifest declares exactly one permission | `apps/haven_app/android/app/src/main/AndroidManifest.xml:7` (`INTERNET`) | FACT |
| The Stage-1 child **merged debug** manifest nonetheless declares `INTERNET`, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `com.google.android.c2dm.permission.RECEIVE`, `...gsf.permission.READ_GSERVICES` and a signature `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16`, `:18-22` | FACT (build artifact) |
| Therefore "the child ships no network lane" is true **of the source manifest and of the Dart code**, and is **not** true of the merged artifact; the transitive plugin AARs add it | INFERRED from the two rows above + the child dependency transit (`apps/haven_child/pubspec.yaml:21-22` → `packages/haven_api/pubspec.yaml:13-15`, `:21`) | INFERRED |
| Stage 2 must decide whether inventory claims are made against source or merged manifests | see §5 | PROPOSED |

---

## 5. What this inventory says Stage 2 can honestly claim

| Statement | Can Stage 2 claim it? | Why |
| :--- | :--- | :--- |
| "Capability inventory document over contracts + labelled DEMO" | Yes, at ladder 2 | everything above is source-verifiable |
| "Child app reads device capability natively" | **No** | no Kotlin compiles into the child (§1) — FACT |
| "A permission is granted" | **No** | no grant path exists; the child's dashboard source answers `blocked(...)` for every permission `apps/haven_child/lib/core/permissions/unconfigured_permission_status_source.dart:24-33` |
| "Device state genuinely read" | Only "parent-side code path exists and is unit-tested against a mock handler" | `apps/haven_app/test/permissions/channel_device_state_test.dart:21-43`; never run on hardware (`STAGE_1_KNOWN_LIMITATIONS.md:34-36`) |
| "Model/manufacturer available" | **No** until D-4 is decided and implemented | `apps/haven_child/lib/core/device/real_device_information.dart:33-35` |
| Anything physical-device / real-pairing / native-grant | **No** — blocked register `PHASE_3_MASTER_PLAN.md:77-85` | FACT |

**Inventory gaps Stage 2 will have to name (PROPOSED, not approved):** installed-app inventory (`<queries>` design),
usage-stats counts, battery level, `Build.MANUFACTURER`/`MODEL`, foreground-service types, network state, and the
merged-manifest permission surprise in §4.

---

## 6. Citation corrections against evidence handed to this agent

Three handed citations did not verify as written; they were re-located and are corrected in the tables above.

| Handed | Reality | Label |
| :--- | :--- | :--- |
| `apps/haven_child/lib/core/device/channel_device_state.dart:7-15` | That file **does not exist**. The Dart half of the bridge is in the **parent**: `apps/haven_app/lib/core/permissions/channel_device_state.dart:13-16` (channel `:14`, method `:15`) | FACT |
| `apps/haven_child/test/device/channel_device_state_test.dart:21-43` | Path is wrong; file and line range are right in the parent: `apps/haven_app/test/permissions/channel_device_state_test.dart:21-43` | FACT |
| `backend/supabase/functions/pairing/identifiers.ts:24-25,46-48` | Path is wrong; lines are right in `_shared`: `backend/supabase/functions/_shared/identifiers.ts:24-25` (alphabet + `IDENTIFIER_LENGTH = 8`), `:46-48` (`newPairingCode`) | FACT |
