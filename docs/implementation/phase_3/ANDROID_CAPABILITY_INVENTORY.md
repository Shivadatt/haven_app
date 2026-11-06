# HAVEN PARENTAL CONTROL — PHASE 3 ANDROID CAPABILITY INVENTORY

**Scope**: Stage 2 deliverable — Android native capability inventory for the Child Companion app
**Date**: November 6, 2026
**Status**: **COMPLETE (documentation)** — the inventory itself is finished; the capabilities it describes are **NOT TESTED** on any device or emulator
**Method**: read-only source inspection (`apps`, `packages`, `android_native`, `backend`, `scripts`) plus first-party grep verification of every "not implemented" claim
**Repository at authoring time**: `main` @ `8e50da06982c495a20407a505235f230de1720f2`; baseline re-verified this session — 1,020/1,020 protected tests, 167 child tests, 0 analyzer issues, 704 hand-written source files / 0 line violations

---

## 0. Reading rules for this document

1. **Repo evidence vs platform fact.** A row backed by a `file:line` in this repository is labelled **REPO**. A row that states Android platform behavior with no repo code behind it is labelled **PLATFORM FACT** and is never presented as something Haven has built. Rows about Google Play policy are labelled **POLICY REVIEW REQUIRED** — this document does not assert that any policy-restricted capability is available.
2. **Status vocabulary** is the Stage 2 set only: `IMPLEMENTED`, `PARTIAL`, `NOT IMPLEMENTED`, `DOC-CLAIM-ONLY`, plus the verification states `NOT TESTED` / `BLOCKED` / `DEFERRED` / `PROPOSED`.
3. **The ladder.** No capability in this document is credited above ladder level 2 (Flutter logic). Level 3 (Kotlin native) exists only as a read-only diagnostic probe; levels 4–6 (permission granted, physical device, parent-child E2E) are **NOT TESTED** or **BLOCKED** for every row.
4. **Nothing here authorizes implementation.** Adding a permission, service, provider or receiver requires the matching D-3/D-4/D-5 approval plus a stage gate.

## 1. Build and platform envelope

| Attribute | Value | Evidence |
| :--- | :--- | :--- |
| Parent `applicationId` / `namespace` | `com.haven.haven_app` | [haven_app/android/app/build.gradle.kts:8,19](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L8) |
| Child `applicationId` / `namespace` | `com.haven.child` | [haven_child/android/app/build.gradle.kts:10,21](file:///d:/control/apps/haven_child/android/app/build.gradle.kts#L10) |
| `compileSdk` / `minSdk` / `targetSdk` in **source** | `flutter.compileSdkVersion` / `flutter.minSdkVersion` / `flutter.targetSdkVersion` — **no literal override in either app** | [haven_app build.gradle.kts:9,22,23](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L9), [haven_child build.gradle.kts:11,24,25](file:///d:/control/apps/haven_child/android/app/build.gradle.kts#L11) |
| Resolved SDK values | `minSdkVersion 24`, `targetSdkVersion 36` — observed **only in merged-manifest build artifacts**, not in source | `apps/*/build/app/intermediates/merged_manifest/debug/.../AndroidManifest.xml:8-9` (artifact, regenerable, **NOT TESTED** as shipped behavior) |
| Toolchain | Flutter 3.44.6 / Dart 3.12.2 ([.fvmrc:2](file:///d:/control/.fvmrc#L2)), AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, Java 17 | `apps/haven_app/android/settings.gradle.kts:22-23`, `gradle/wrapper/gradle-wrapper.properties:5` |
| Native lane location | `android_native/child_services/` (10 `.kt` files, max 122 lines), compiled into the **PARENT** app | [haven_app/android/app/build.gradle.kts:41](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41) |
| Child app native code | `class MainActivity : FlutterActivity()` — nothing else | [haven_child/.../MainActivity.kt:5](file:///d:/control/apps/haven_child/android/app/src/main/kotlin/com/haven/child/MainActivity.kt#L5) |
| Permissions declared by child source manifest | **none** | [haven_child/.../AndroidManifest.xml](file:///d:/control/apps/haven_child/android/app/src/main/AndroidManifest.xml) |
| Permissions declared by parent source manifest | `INTERNET` only, + `BIND_DEVICE_ADMIN` receiver | [haven_app/.../AndroidManifest.xml:7](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml#L7), [:41-53](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml#L41-L53) |
| Kotlin tests anywhere in repo | **0 files, 0 tests**, no `src/test`, no `src/androidTest`, no `testImplementation` dependency → **NOT TESTED** | `find apps -path '*/android/*' -type d -name test` → 0 results |
| Device attached | none; `Pixel_9a` AVD exists, never launched in this stage | [STAGE_0_INSPECTION_VERIFICATION.md:34](file:///d:/control/docs/implementation/phase_3/STAGE_0_INSPECTION_VERIFICATION.md#L34) |

## 2. Verified absences (source-only, build artifacts excluded)

`UsageStatsManager`, `queryUsageStats`, `queryEvents`, `totalTimeInForeground`, `getInstalledPackages`, `getInstalledApplications`, `QUERY_ALL_PACKAGES`, `AccessibilityService`, `VpnService`, `BOOT_COMPLETED` (as a receiver), `RECEIVE_BOOT_COMPLETED` (as a declaration), `FileProvider`, `android:sharedUserId`, `content://`, `MediaStore`, `BluetoothAdapter`, `NsdManager`, `WifiManager`, `WorkManager`, `MediaProjection`, `INSTALL_PACKAGES`, `setLockTaskPackages`, `startLockTask`, `forceStopPackage`, `setPackagesSuspended`, `suspendApp` — **0 files matched** across `apps`, `packages`, `android_native`, `backend`, `scripts` (excluding `build/`, `.dart_tool/`, `_scratch/`, `.git/`).

The only non-zero near-misses, which are **reads about** a capability rather than uses of it:

| Symbol | File:line | What it actually is |
| :--- | :--- | :--- |
| `AlarmManager.canScheduleExactAlarms()` | [MonitoringStateReader.kt:42](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L42) | reports whether exact alarms *would* be allowed; schedules nothing |
| `OP_GET_USAGE_STATS = "android:get_usage_stats"` | [MonitoringStateReader.kt:54,120](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L120) | app-ops **permission state** probe; no usage data read |
| `isIgnoringBatteryOptimizations(pkg)` | [MonitoringStateReader.kt:33](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L33) | exemption **state** read |
| `"bootReceiverDeclared" to isDeclared(..., "RECEIVE_BOOT_COMPLETED")` | [PermissionStateReader.kt:42](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L42) | manifest **declaration** check; no receiver exists |
| `getPackageInfo(context.packageName, GET_SERVICES)` | [MonitoringStateReader.kt:100](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L100) | self-introspection only — not an app inventory |

---

## 3. Capability areas

### 3.1 Device identity and device information — **PARTIAL**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `Build.MODEL`/`Build.MANUFACTURER` unrestricted; API 26+ tightened some reads (PLATFORM FACT) |
| Permission / special access | none for basic identity |
| Runtime vs settings | n/a |
| Kotlin API / service | none used. `Build.*` is never read; envelope exposes only `apiLevel`, `osRelease` ([BridgeContract.kt:18-19](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L18-L19)) |
| OEM limitations | none observed (nothing is read) |
| Play policy | disclosure required if a stable device identifier is ever introduced — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | required before any persistent hardware id is stored |
| Implementation status | **PARTIAL**: OS version via `Platform.operatingSystemVersion` ([real_device_information.dart:26](file:///d:/control/apps/haven_child/lib/core/device/real_device_information.dart#L26)); `model: null`, `manufacturer: null` deliberately ([real_device_information.dart:34-35](file:///d:/control/apps/haven_child/lib/core/device/real_device_information.dart#L34-L35)); no install-referrer or installer query anywhere. Stage 1 recorded this as **PARTIAL (by-design fallback)** |
| Emulator verification possible | yes for version fields |
| Physical device required | yes for meaningful model/manufacturer evidence |
| Approved / blocked / deferred | **DEFERRED** — the brief's rule "device model/manufacturer render `Unavailable` instead of a guessed read" stands |

### 3.2 Installed application inventory — **NOT IMPLEMENTED**

| Attribute | Record |
| :--- | :--- |
| API levels affected | API 30+ package visibility applies to every enumeration query (PLATFORM FACT) |
| Permission / special access | none required for a `<queries>`-scoped read; `QUERY_ALL_PACKAGES` is a Play-restricted permission |
| Runtime vs settings | n/a — visibility is manifest-declared, not granted at runtime |
| Kotlin API | `PackageManager.getInstalledPackages/getInstalledApplications` — **0 call sites** |
| OEM limitations | not assessed |
| Play policy | `QUERY_ALL_PACKAGES` requires a qualifying core use case — **POLICY REVIEW REQUIRED**; the brief forbids adding it without documented justified need, and this inventory records none |
| Privacy disclosure | an installed-app list is personal data; disclosure required before collection |
| Implementation status | **NOT IMPLEMENTED IN REPO**. Only self-introspection exists ([MonitoringStateReader.kt:100](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L100)) |
| Emulator verification possible | yes, once a `<queries>` block and a reader exist |
| Physical device required | recommended (OEM store/preinstall differences change the list) |
| Approved / blocked / deferred | **DEFERRED** to Stage 3/5; no `<queries>` may be added before that gate |

### 3.3 Usage statistics access — **PARTIAL (permission state only), zero data path**

| Attribute | Record |
| :--- | :--- |
| API levels affected | API 21+ for `UsageStatsManager`; app-ops probe forms changed across releases (PLATFORM FACT) |
| Permission / special access | `PACKAGE_USAGE_STATS` — a **Settings-granted special access**, not a runtime permission; the repo documents this itself ([OsAnswers.kt:76-80](file:///d:/control/android_native/child_services/platform_bridge/OsAnswers.kt#L76-L80)) |
| Runtime vs settings | **settings-based** (`Settings > Special app access > Usage access`); no `requestPermissions()` dialog exists |
| Kotlin API | present: `AppOpsManager.unsafeCheckOpNoThrow` / `checkOpNoThrow` ([MonitoringStateReader.kt:53-61](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L53-L61)). **absent**: `queryUsageStats`, `queryEvents`, `totalTimeInForeground`, any polling, any caching |
| OEM limitations | aggregation delay and truncation are device/vendor dependent — **not assessed here** |
| Play policy | usage data is a sensitive permission — **POLICY REVIEW REQUIRED** with a declared use case |
| Privacy disclosure | mandatory: which apps, what granularity, retention, where stored |
| Implementation status | **PARTIAL**: the app can truthfully answer *"is usage access granted?"* and nothing else |
| Emulator verification possible | yes for the grant-state read; **delay semantics cannot be proven on an emulator** |
| Physical device required | yes for data-quality and OEM behavior |
| Approved / blocked / deferred | **DEFERRED** to Stage 3 (P-5 Kotlin test infra + P-1 device). Rule carried forward: **UsageStats is not realtime and must never be presented as realtime** |

### 3.4 Location access — **PARTIAL / DOC-CLAIM-ONLY**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `ACCESS_FINE_LOCATION` runtime since API 23; `ACCESS_BACKGROUND_LOCATION` separate since API 29; approximate-precision toggle API 12+ (PLATFORM FACT) |
| Permission / special access | fine/coarse location; background location is a second, separately granted permission |
| Runtime vs settings | runtime, with a settings-level background grant flow on API 29+ |
| Kotlin API | provider enabled-ness ([LocationStateReader.kt:48](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L48)) and `getLastKnownLocation` cache read ([LocationStateReader.kt:62](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L62)). **No** `requestLocationUpdates`, no `FusedLocationProviderClient` |
| OEM limitations | background location reliability is OEM-dependent (see 3.8) |
| Play policy | background location + location-in-app require prominent disclosure and a declared use case — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | required, and the repo already refuses coordinates on the state channel: **"No coordinates leave this file"** ([LocationStateReader.kt:17](file:///d:/control/android_native/child_services/location/LocationStateReader.kt#L17)) |
| Implementation status | **PARTIAL (read-only state)**; `geolocator ^14.0.1` is declared ([haven_app/pubspec.yaml:50](file:///d:/control/apps/haven_app/pubspec.yaml#L50)) and registered as a plugin, but **has zero call sites in any `lib/`**. Neither location permission is declared in any source manifest → **DOC-CLAIM-ONLY** for any location feature |
| Emulator verification possible | yes for permission states and mocked single fixes |
| Physical device required | yes for accuracy, background, and safe-zone reliability |
| Approved / blocked / deferred | **DEFERRED** to Stage 6 (needs P-1) |

### 3.5 Notification permission — **PARTIAL (read-only)**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `POST_NOTIFICATIONS` runtime permission from API 33 (PLATFORM FACT) |
| Permission / special access | `POST_NOTIFICATIONS`; notification channels required API 26+ |
| Runtime vs settings | runtime (33+), settings-toggled below that |
| Kotlin API | tracked as an enum member ([OsAnswers.kt:90](file:///d:/control/android_native/child_services/platform_bridge/OsAnswers.kt#L90)); no channel creation code, no notification authoring code |
| OEM limitations | OEM notification throttling not assessed |
| Play policy | none beyond ordinary permission declaration |
| Privacy disclosure | not required for the permission alone |
| Implementation status | **PARTIAL**: state read only. The only ask-site is FCM's own `requestPermission()` in the shared API package ([push_transport_impl.dart:91](file:///d:/control/packages/haven_api/lib/src/push_transport_impl.dart#L91)); the child declares nothing. **No `AndroidNotificationChannel` exists repo-wide**, so a persistent foreground-service notification is not currently buildable from app code |
| Emulator verification possible | yes |
| Physical device required | no |
| Approved / blocked / deferred | **DEFERRED** — the child app may not add permissions before its owning stage |

### 3.6 Background execution — **NOT IMPLEMENTED**

| Attribute | Record |
| :--- | :--- |
| API levels affected | API 26+ background-execution limits; API 31+ stricter; exact alarms special access API 31+ (PLATFORM FACT) |
| Permission / special access | `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (special access), `WAKE_LOCK` (normal) |
| Runtime vs settings | special-access grant via Settings on API 31+ |
| Kotlin API | `AlarmManager` appears only as a *state probe* ([MonitoringStateReader.kt:42](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L42)); `WorkManager` 0 hits; no receivers, no `JobScheduler` |
| OEM limitations | OEM killers defeat all background lanes; see 3.8 |
| Play policy | location/background exemption declarations required for some types — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | required if background collection continues after the visible session ends |
| Implementation status | **NOT IMPLEMENTED IN REPO** |
| Emulator verification possible | partially (Doze can be induced), **but the emulator cannot prove OEM behavior** |
| Physical device required | yes, on the actual target ROM |
| Approved / blocked / deferred | **DEFERRED** to Stage 7. Standing rule: **no promise of continuous background execution**, and WorkManager is never presented as a realtime substitute |

### 3.7 Foreground services — **NOT IMPLEMENTED (app-authored); plugin-declared only**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `foregroundServiceType` mandatory from API 29; per-type runtime permissions from API 34 (PLATFORM FACT) |
| Permission / special access | `FOREGROUND_SERVICE` (normal) + a per-type permission (location/camera/media-*), API 34+ |
| Runtime vs settings | the type's underlying permission is runtime |
| Kotlin API | none authored. **Zero `<service>` elements in any source manifest**; `MonitoringStateReader.kt:100-108` only *counts* declared service types |
| OEM limitations | OEMs stop foreground services; not assessed |
| Play policy | FGS type declarations must match the app's use case; misleading types are rejected — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | a visible persistent notification is the platform's disclosure requirement |
| Implementation status | **NOT IMPLEMENTED**. The only FGS in the build is plugin-owned (`GeolocatorLocationService`, type `location`) and appears **only in merged-manifest build artifacts**, e.g. `apps/haven_app/build/.../AndroidManifest.xml:171` — that is a build fact, **NOT TESTED** behavior |
| Emulator verification possible | yes for lifecycle and notification |
| Physical device required | yes for reliability claims |
| Approved / blocked / deferred | **DEFERRED** to Stage 7 |

### 3.8 Battery-optimization restrictions — **PARTIAL (read-only); highest OEM risk**

| Attribute | Record |
| :--- | :--- |
| API levels affected | Doze from API 23; app-standby buckets API 28+ (PLATFORM FACT) |
| Permission / special access | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (signature\|privileged\|appop in practice); most OEM auto-start switches have **no public API at all** |
| Runtime vs settings | settings-based; user must act in system UI |
| Kotlin API | `PowerManager.isIgnoringBatteryOptimizations` ([MonitoringStateReader.kt:33](file:///d:/control/android_native/child_services/monitoring/MonitoringStateReader.kt#L33)); declaration check only for the request permission ([PermissionStateReader.kt:38-40](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L38-L40)) |
| OEM limitations | **documented in-repo as risk 4 / B-4**: ColorOS (PHASE_3_MASTER_PLAN.md:84, STAGE_0:97), Realme RMX2161 as the target device (STAGE_1_KNOWN_LIMITATIONS.md:36), Samsung Knox (docs/audit/frontend_functionality/ANDROID_NATIVE_GAP_AUDIT.md:283). Xiaomi / Huawei / OnePlus / auto-start / lock-screen-whitelist: **no repo evidence, no code, no documented handling** |
| Play policy | battery-exemption requests must serve a user-facing core function — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | the reason an exemption is needed must be explained to the parent |
| Implementation status | **PARTIAL**: state read only, never acted upon |
| Emulator verification possible | **no** for the risk that matters — Doze on an emulator is not ColorOS |
| Physical device required | **yes** (B-3, P-1). Until a Realme RMX2161 is attached, every background-reliability row stays **NOT TESTED** |
| Approved / blocked / deferred | **BLOCKED** for reliability claims (B-4); investigation **DEFERRED** to Stage 7 |

### 3.9 Package visibility — **MINIMAL**

| Attribute | Record |
| :--- | :--- |
| API levels affected | API 30+ (`targetSdk 36` ⇒ fully enforced) (PLATFORM FACT) |
| Permission / special access | none for `<queries>`; `QUERY_ALL_PACKAGES` if the broad read were needed |
| Runtime vs settings | manifest-declared |
| Kotlin API | affected reads: `getPackageInfo(own package)` only |
| OEM limitations | unknown; visibility filtering can differ with preinstalled package managers |
| Play policy | `QUERY_ALL_PACKAGES` is Play-restricted — **POLICY REVIEW REQUIRED**; the brief's rule stands: do not add it without a documented justified need, and **none exists in this inventory** |
| Privacy disclosure | a broad visibility query is itself a privacy exposure |
| Implementation status | parent declares exactly one `<intent>` (`PROCESS_TEXT`) at [haven_app/.../AndroidManifest.xml:66-71](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml#L66-L71); child declares **none**, deliberately ([haven_child/.../AndroidManifest.xml:41-47](file:///d:/control/apps/haven_child/android/app/src/main/AndroidManifest.xml#L41-L47)) |
| Emulator verification possible | yes — visibility is not OEM-specific in practice |
| Physical device required | no |
| Approved / blocked / deferred | **DEFERRED**; a package-visibility plan is a Stage 2→3 prerequisite (master plan §4 Stage 2 acceptance mentions exactly that) |

### 3.10 Device administration — **DECLARED-ONLY, zero enforcement**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `DevicePolicyManager` API 8+; most dangerous policies require Device Owner, not an active admin (PLATFORM FACT) |
| Permission / special access | receiver `android.permission.BIND_DEVICE_ADMIN`; user must enable via Settings |
| Runtime vs settings | **settings-based** user consent, not a runtime dialog |
| Kotlin API | `isAdminActive` ([DeviceAdminStateReader.kt:30](file:///d:/control/android_native/child_services/device_admin/DeviceAdminStateReader.kt#L30)), `getUserRestrictions` ([DeviceAdminStateReader.kt:34](file:///d:/control/android_native/child_services/device_admin/DeviceAdminStateReader.kt#L34)). Receiver is an empty subclass ([HavenDeviceAdminReceiver.kt:17](file:///d:/control/android_native/child_services/device_admin/HavenDeviceAdminReceiver.kt#L17)); policy set is **`<force-lock/>` only** ([res/xml/haven_device_admin.xml:16](file:///d:/control/apps/haven_app/android/app/src/main/res/xml/haven_device_admin.xml#L16)) |
| OEM limitations | admin-removal UX differs per ROM |
| Play policy | device-admin declaration requires a declared use case — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | mandatory; an admin can lock the screen |
| Implementation status | **PARTIAL / declared-only**: no `lockNow`, no wipe, no password policy, no restriction is ever set. `isDeviceOwnerApp` is read at [DeviceAdminStateReader.kt:39](file:///d:/control/android_native/child_services/device_admin/DeviceAdminStateReader.kt#L39) |
| Emulator verification possible | yes for enable/disable and read paths |
| Physical device required | yes for any behavior claim parents rely on |
| Approved / blocked / deferred | **DEFERRED**; nothing may be *enforced* before the Stage 5 feasibility gate |

### 3.11 Device-owner provisioning — **NOT IMPLEMENTED, not a consumer capability**

| Attribute | Record |
| :--- | :--- |
| API levels affected | owner APIs available since API 50/18 but unreachable without provisioning (PLATFORM FACT) |
| Permission / special access | none — provisioning is the gate: `adb dpm set-primary-app-admin` on a wiped, no-account device, or a dpc/`ADD_DEVICE_ADMIN` intent flow, or QR pairing (enterprise) |
| Runtime vs settings | neither; requires a wiped device + adb or an enterprise flow |
| Kotlin API | **0 hits**: no `SETUP_COMPLETE_INTENT`, no owner-provisioning Activity, no `setLockTaskPackages` |
| OEM limitations | OEM firmware frequently blocks the adb path entirely |
| Play policy | not a Play distribution path |
| Privacy disclosure | n/a — the mode itself is the disclosure |
| Implementation status | **NOT IMPLEMENTED IN REPO**, and the repo already rules it out: "NOT achievable on the Play-managed consumer path; must be documented *not available on ordinary consumer devices*" ([STAGE_0_INSPECTION_VERIFICATION.md:94](file:///d:/control/docs/implementation/phase_3/STAGE_0_INSPECTION_VERIFICATION.md#L94)) |
| Emulator verification possible | only in a rooted/emulator-specific provisioning path — not representative |
| Physical device required | yes, and a dedicated test device the owner is willing to wipe |
| Approved / blocked / deferred | **BLOCKED** (B-2 / risk 1). Device Owner is **not** an ordinary consumer capability and Stage 2 does not treat it as available |

### 3.12 AccessibilityService restrictions — **NOT IMPLEMENTED**

| Attribute | Record |
| :--- | :--- |
| API levels affected | service declaration + config XML; key-event and window-content limits tightened API 13+ (PLATFORM FACT) |
| Permission / special access | user enables in Settings; `BIND_ACCESSIBILITY_SERVICE` signature permission held by the system |
| Runtime vs settings | settings-based |
| Kotlin API | **0 hits** — no `AccessibilityService` subclass, no `accessibility_service_config.xml`, no `bind-accessibility-service` |
| OEM limitations | not assessed |
| Play policy | Accessibility access is restricted to a short list of use cases and is heavily reviewed; parental-control use is reviewed case-by-case — **POLICY REVIEW REQUIRED, do not assume availability** |
| Privacy disclosure | an accessibility service reads on-screen content; disclosure is mandatory and the governing contract forbids hidden capture |
| Implementation status | **NOT IMPLEMENTED IN REPO** |
| Emulator verification possible | yes mechanically, but it proves nothing about Play acceptance |
| Physical device required | yes, if ever pursued |
| Approved / blocked / deferred | **BLOCKED** pending the Stage 5 feasibility gate; the repo already records that app-killing via accessibility "conflicts with Play policy and this project's privacy rules (§3)", and that a "no approved enforcement" verdict is an **allowed outcome, not a failure** (STAGE_0:95) |

### 3.13 App blocking feasibility — **NOT IMPLEMENTED**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `setPackagesSuspended` requires Device Owner; `forceStopPackage` is system/signature-only (PLATFORM FACT) |
| Permission / special access | Device Owner, or nothing usable by a consumer app |
| Runtime vs settings | n/a |
| Kotlin API | **0 hits** for `setPackagesSuspended`, `suspendApp`, `forceStopPackage`, `SYSTEM_ALERT_WINDOW`, overlay blocking. The command vocabulary itself has no blocking verb: `apply_policy, sync_policy, request_usage, request_location, end_session, custom` ([enums_commands.dart:35-40](file:///d:/control/packages/haven_models/lib/src/enums_commands.dart#L35-L40)) |
| OEM limitations | some OEMs expose their own "app lock" that third-party apps cannot use |
| Play policy | blocking other apps via accessibility or overlay is a policy-rejected pattern — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | required only if built |
| Implementation status | **NOT IMPLEMENTED IN REPO**. Likely honest outcome, already forecast: blocking is device-owner-only ⇒ unavailable on ordinary consumer devices (STAGE_0:82 / master plan Stage 5) |
| Emulator verification possible | no meaningful verification without Device Owner |
| Physical device required | yes |
| Approved / blocked / deferred | **BLOCKED** (B-2) until the Stage 5 written feasibility audit; **no consumer-device app blocking may be claimed as available** |

### 3.14 Website filtering feasibility — **DOC-CLAIM-ONLY (UI exists, filtering does not)**

| Attribute | Record |
| :--- | :--- |
| API levels affected | VPN `VpnService` API 4+; Private DNS API 28+; system-wide content filters require Device Owner (PLATFORM FACT) |
| Permission / special access | a VPN profile is a user-approved, always-on-noticeable lane; DNS/profile changes are Device Owner |
| Runtime vs settings | user confirmation dialog for VPN |
| Kotlin API | **0 hits** for `VpnService`, DNS configuration, proxy setup, or a filtering WebView |
| OEM limitations | not assessed |
| Play policy | VPN use requires a declared VPN use case — **POLICY REVIEW REQUIRED** |
| Privacy disclosure | a VPN sees traffic; disclosure is mandatory |
| Implementation status | **DOC-CLAIM-ONLY**: a rich Dart UI exists (`policies/.../web_filter_page.dart`, `add_domain_dialog.dart`) that writes rules into the local JSON store, but no mechanism enforces them. A parent-visible filter list with no enforcement path is the single most dangerous false claim in this inventory |
| Emulator verification possible | yes for a VPN lane once built |
| Physical device required | yes for routing/kill-switch behavior |
| Approved / blocked / deferred | **DEFERRED** to the Stage 5 feasibility audit; until then any UI must state that filtering is not enforced |

### 3.15 Reboot and background recovery — **NOT IMPLEMENTED**

| Attribute | Record |
| :--- | :--- |
| API levels affected | `BOOT_COMPLETED` receivers are exempt from the API 26+ implicit-broadcast ban but are the only reliable lane (PLATFORM FACT) |
| Permission / special access | `RECEIVE_BOOT_COMPLETED` (normal), declared receiver |
| Runtime vs settings | install-time declaration; some OEMs gate auto-start separately (see 3.8) |
| Kotlin API | **0 receivers**. `RECEIVE_BOOT_COMPLETED` appears only as a declaration *check* ([PermissionStateReader.kt:42](file:///d:/control/android_native/child_services/permissions/PermissionStateReader.kt#L42)) |
| OEM limitations | OEM auto-start managers silently prevent boot receivers |
| Play policy | none specific |
| Privacy disclosure | required — the device resumes monitoring after reboot |
| Implementation status | **NOT IMPLEMENTED**. Persistence today is a JSON file (`haven_local.json`) that survives reboot as data, with **no reschedule logic and no state restoration code**. Quota-style "did a reboot reset the counter" questions therefore cannot be answered from this repo |
| Emulator verification possible | partially (`adb shell am broadcast -a android.intent.action.BOOT_COMPLETED`), with an ADB allowance the current brief does not grant |
| Physical device required | yes |
| Approved / blocked / deferred | **DEFERRED** to Stage 7 ("reboot only where permitted") |

### 3.16 Native communication channels — **IMPLEMENTED, one read-only method**

| Attribute | Record |
| :--- | :--- |
| API levels affected | none — `MethodChannel` is Flutter-level, not API-level |
| Permission / special access | none (in-process) |
| Runtime vs settings | n/a |
| Kotlin API | `HavenBridge.kt` (89 lines) — channel `haven.dev/child_device_state`, one method `state.readAll`, five sections (permissions / monitoring / location / deviceAdmin / communication), three error codes `unknown-method` / `no-context` / `section-failed` ([BridgeContract.kt:13-34](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L13-L34)) |
| OEM limitations | n/a |
| Play policy | n/a |
| Privacy disclosure | the channel is the disclosure surface — it reports capability state to honest UI |
| Implementation status | **IMPLEMENTED (parent build only)**, read-only, untyped on the wire (`Map<String, Any?>`), constants duplicated Dart↔Kotlin, **no contract version, no timeout, no EventChannel, no Pigeon**, **zero Kotlin tests**. `apps/haven_child` has **no lane at all** |
| Emulator verification possible | yes — and it is the one capability that could be proven on the existing `Pixel_9a` AVD, which has **not** been done |
| Physical device required | no |
| Approved / blocked / deferred | **PROPOSED** — typing, version field, drift test and lane ownership are exactly decision **D-4 / D-4a**; nothing may be added before approval |

---

## 4. Consolidated capability matrix

| # | Capability | Repo status | Ladder level | Verification | Path forward |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Device identity | PARTIAL | 2 | NOT TESTED (device) | Stage 2/9 contracts only |
| 2 | Installed-app inventory | NOT IMPLEMENTED | 0 | NOT TESTED | Stage 3 (needs visibility plan) |
| 3 | Usage statistics | PARTIAL (state only) | 2 | NOT TESTED | Stage 3, P-1 + P-5 |
| 4 | Location | PARTIAL / DOC-CLAIM-ONLY | 2 | NOT TESTED | Stage 6, P-1 |
| 5 | Notifications | PARTIAL (state only) | 2 | NOT TESTED | Stage 7 prerequisite |
| 6 | Background execution | NOT IMPLEMENTED | 0 | NOT TESTED | Stage 7 |
| 7 | Foreground services | NOT IMPLEMENTED (app-authored) | 0 | NOT TESTED | Stage 7 |
| 8 | Battery optimization | PARTIAL (state only) | 2 | **BLOCKED B-4** | Stage 7, physical device required |
| 9 | Package visibility | MINIMAL | 2 | NOT TESTED | Stage 3 gate |
| 10 | Device administration | DECLARED-ONLY | 2 | NOT TESTED | Stage 5 feasibility |
| 11 | Device owner | NOT IMPLEMENTED | 0 | n/a | **BLOCKED B-2** — not a consumer path |
| 12 | AccessibilityService | NOT IMPLEMENTED | 0 | n/a | **BLOCKED** pending Stage 5 + POLICY REVIEW |
| 13 | App blocking | NOT IMPLEMENTED | 0 | n/a | **BLOCKED B-2**; likely "unavailable on consumer devices" |
| 14 | Website filtering | DOC-CLAIM-ONLY | 2 | NOT TESTED | Stage 5 feasibility; UI must not imply enforcement |
| 15 | Reboot recovery | NOT IMPLEMENTED | 0 | NOT TESTED | Stage 7 |
| 16 | Native channel | IMPLEMENTED (parent), untyped | 2 | NOT TESTED | **PROPOSED** under D-4 |

## 5. Standing prohibitions carried into every later stage

- No `QUERY_ALL_PACKAGES` without a documented justified need — **this inventory records none**.
- UsageStats is never presented as realtime; delay and incompleteness are stated in the UI.
- No promise of continuous background execution; no promise of reliability on ColorOS or other OEM-restricted ROMs.
- No consumer-device app blocking claimed as available before the Stage 5 written feasibility audit.
- Device Owner provisioning is not an ordinary consumer capability and is not treated as available.
- No AccessibilityService-based app killing.
- No new permission, provider, service or receiver without its own approval row.
- No physical-device claim without a device attached; none is attached.
