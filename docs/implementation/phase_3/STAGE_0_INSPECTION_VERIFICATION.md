# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 0 INSPECTION VERIFICATION REPORT

**Scope**: Phase 3 — Child Companion Android App — Stage 0 (Repository Inspection & Plan)  
**Date**: November 6, 2026  
**Method**: 4 parallel read-only inspection subagents (git/baseline, Android-native, Flutter-architecture, docs/contracts). No files outside `docs/implementation/phase_3/` and `_scratch/p3_inspect/` were touched. No implementation performed.  
**Governing rules**: [`docs/implementation/00-app-contract.md`](file:///d:/control/docs/implementation/00-app-contract.md) — including the **no-git-operations** rule; nothing was committed or staged by this audit.

---

## 1. Required §11 Response Item 1 & 6 — Repository Inspection & Git State

| Item | Evidence |
| :--- | :--- |
| Branch | `main`, up to date with `origin/main` |
| HEAD | `8e50da06982c495a20407a505235f230de1720f2` — `docs: add phase 2 implementation reports, feature matrix, and workflow documentation` |
| Working tree | Doc-only Phase 2 sign-off changes: 7 modified files under `docs/implementation/phase_2/`, untracked `FINAL_VERIFICATION_REPORT.md`, 2 staged `_scratch/` evidence files. **Zero source/test drift.** |
| History | 9 commits (`63b7793 first commit` → `8e50da0`); conventional-ish `docs:`/`feat:` prefixes |
| Baseline structure sanity | Test files: haven_app 141, haven_api 9, haven_core 1, haven_models 3 — consistent with the 924/66/18/12 executed baseline (1,020). 352 Dart files under `lib/` of apps+packages; line-count script covers 615 files (0 violations, re-confirmed this session). |
| Git hygiene findings | (a) `_scratch/` is NOT gitignored — 31 scratch files tracked, incl. 5 `.pyc` binaries and 4 Dart/Flutter telemetry-state files; (b) `.gitignore` correctly excludes secrets — only `.env.example` tracked, no `google-services.json`/keystores/`haven_local.json` anywhere; (c) Phase 2 sign-off docs remain uncommitted (left for the owner per contract's no-git rule). |

## 2. Required Item 2 — Existing Child-App & Kotlin Architecture

**There is no child app.** Exactly 4 `pubspec.yaml` exist (`apps/haven_app`, `packages/haven_{api,core,models}`); no `apps/haven_child`; no second Gradle module (`settings.gradle.kts` includes only `:app`).

The existing native lane (`android_native/child_services/`, 10 Kotlin files, 693 lines, package `com.haven.haven_app.child_services.*`) is a **read-only diagnostic probe**, compiled into the PARENT app via `srcDir` redirect ([app/build.gradle.kts:36-43](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L36-L43)):

| Component | Reality |
| :--- | :--- |
| `HavenBridge.kt` | One MethodChannel `haven.dev/child_device_state`, one method `state.readAll`, 5 state readers, no "apply" method by design |
| `HavenDeviceAdminReceiver.kt` | **Empty subclass** — no `onEnabled`/`onDisable`; device-admin XML declares only `force-lock` policy |
| Dart counterpart | `lib/core/permissions/channel_device_state.dart` — hand-rolled channel constants duplicated (no Pigeon, zero EventChannels, no generated contracts anywhere) |
| Kotlin tests | **None** — empty untracked `src/test` scaffold, no junit/Robolectric deps, never executed on a device |

Build stack: `com.haven.haven_app` / compileSdk 36, minSdk 24, targetSdk 36, AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, Java 17. Android SDK present (platforms 34–37, build-tools 35/36, NDK 28.2.13676358, `Pixel_9a` AVD) but **no physical device attached** (`adb devices` empty).

## 3. Required Item 3 — Reusable Phase 1/2 Components

High reuse confirmed (full table in master plan §3):

- **haven_core** (fully reusable): `Result/Ok/Err`, 10-type `HavenFailure` sealed set incl. `BlockedFailure`, `blocked()`, `Clock/FixedClock`, `format*`/`haversineMeters`, `validate*` (incl. `validatePairingCode` — deliberately blocked pending written spec, currently NOT barrel-exported).
- **haven_models** (fully reusable): `Device/DeviceApp/DevicePolicy`, `Profile` (with `ProfileRole.child`), `SafeZone(+State)/SafetyAlert/LocationEvent`, `UsageDaily`, `DeviceCommand` + `PairingRequest/Token/Attempt`, all `WireLabel` enums incl. `EnforcementMode(none|device_admin|device_owner)`.
- **haven_api offline engine** (fully reusable): `FileLocalStore`/`LocalTables`/`LocalSchema`/`LocalConstraints`/`LocalIds`, `OfflineHavenBackend.installLocal`, `Unconfigured*` seams, `SecretVault`/`VaultDeviceIdentity`, 19-table `TableName` registry.
- **Parent app patterns**: GetX two-tier bindings, `AppPages`/route-constant convention (`phase2_pages.dart` precedent for a child `phase3_pages.dart`), `HavenScaffold`/`StateView`/`BackendBanner`/`BlockedNotice`, test harness/driver conventions with hand-written fakes (no mock packages), `flutter_lints` + single `prefer_initializing_formals: false` suppression.

**Must-build/decide**: child-lane `LocalUserAuth` variant (hard-coded `role:'parent'` at [local_user_auth.dart:94](file:///d:/control/packages/haven_api/lib/src/offline/local_user_auth.dart#L94)); child-side pairing screen + redemption write; policy-application engine; approval row contracts currently live in the parent app (lift vs duplicate decision); cross-app same-device data exchange (no precedent — per-sandbox `haven_local.json` by default).

## 4. Required Item 4 — Actual Android Package/Application IDs

| App | applicationId | Status |
| :--- | :--- | :--- |
| Parent (Phase 2) | `com.haven.haven_app` | Shipped; namespace identical |
| Child (Phase 3) | **Undetermined** — must be decided and documented | Repo-doc precedent `com.haven.familysafety` refers to an EXTERNAL Capacitor build whose source is not in this repo (`docs/stage1/05-change-plan.md:63`); reusing that ID would collide with a non-repo artifact — flagged as a Stage 0 decision gate (D-1). |
| Native lane package | `com.haven.haven_app.child_services.*` | Compiled into parent only; child app needs its own namespace + module strategy |

## 5. Required Item 5 — Existing Permissions & Native Services

- Declared by the app manifest: **`INTERNET` only** ([AndroidManifest.xml:7](file:///d:/control/apps/haven_app/android/app/src/main/AndroidManifest.xml#L7)) + `BIND_DEVICE_ADMIN` receiver (empty).
- Manifest-merged from plugins (debug): `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `c2dm.RECEIVE`, `READ_GSERVICES`, dynamic-receiver signature perm.
- Services in APK are plugin-owned only (`GeolocatorLocationService` type=location, Firebase messaging services). **Zero app-authored services.**
- `ACCESS_FINE_LOCATION`/`ACCESS_BACKGROUND_LOCATION`/`PACKAGE_USAGE_STATS`/`SYSTEM_ALERT_WINDOW`/`RECEIVE_BOOT_COMPLETED`/`QUERY_ALL_PACKAGES` etc.: **not declared** → `LocationStateReader` correctly reports `mayAsk=false`; FCM is inert (no `google-services.json`, no gradle plugin, no `Firebase.initializeApp`).

## 6. Required Item 7 — Missing Prerequisites

| # | Prerequisite | Needed by |
| :--- | :--- | :--- |
| P-1 | **Physical child test device** (brief expects Realme RMX2161 / Android 12) — none attached | D/G/H acceptance; DEVICE_VERIFICATION_MATRIX |
| P-2 | Written 6-digit pairing-code spec (TTL conflict: simulation 5 min vs evidenced backend `CODE_TTL_MINUTES = 10`) + `PairingCodeFormat` export decision | B, registration protocol doc |
| P-3 | Child applicationId + Gradle module strategy decision (D-1/D-2) | A |
| P-4 | Same-device parent↔child exchange mechanism decision (or declare real pairing BLOCKED pending Phase 4 backend) | B, K |
| P-5 | Kotlin test infra (junit + Robolectric deps, source sets) — none exists | all Kotlin work |
| P-6 | Typed channel tooling decision (Pigeon vs hand-rolled contract files) | C–H |
| P-7 | Permission explanations + disclosure copy per §3 privacy rules | all sensitive modules |
| P-8 | Commit/push of Phase 2 sign-off docs (owner action — contract forbids agent git ops) | baseline integrity |

## 7. Required Item 8 — Phase 3 Dependency Graph

```
Stage 0 (this inspection + PHASE_3_MASTER_PLAN) 
  └─> Stage 1: haven_child app foundation (A)  [needs P-3]
        └─> Stage 2: registration contracts + capability inventory (B,C)  [needs P-2,P-4,P-6]
              ├─ real cross-device pairing ──────────────> BLOCKED (backend/rendezvous = Phase 4)
              └─> Stage 3: usage access + monitoring (D)  [needs Kotlin infra P-5, device P-1]
                    └─> Stage 4: policy evaluation engine (E)  [pure Dart, no device needed]
                          └─> Stage 5: enforcement feasibility (F)  [gate: written report BEFORE any enforcement code]
                          └─> Stage 6: location + safe-zones (G)  [needs P-1 for real verification]
                                └─> Stage 7: background lifecycle (H)  [depends on D/G service needs]
                                      └─> Stage 8: child dashboard + events (I,J)  [depends on 3–7 outputs]
                                            └─> Stage 9: parent integration contracts (K)  [parallelizable once E models exist]
                                                  └─> Stage 10: full regression + device matrix + FINAL_VERIFICATION
```

## 8. Required Item 10 — Risks & Platform Restrictions

1. **Device-owner/DPM kiosk**: requires provisioning (`adb dpm set-primary-app-admin`) on a wiped non-Google-account device — NOT achievable on the Play-managed consumer path; must be documented "not available on ordinary consumer devices" rather than shipped silently.
2. **AccessibilityService app-killing** conflicts with Play policy and this project's privacy rules (§3) — feasibility gate F may legitimately conclude "no approved enforcement"; that is an allowed BLOCKED, not a failure.
3. **UsageStats delay/incompleteness** — never present as realtime.
4. **OEM battery killers (ColorOS)** — background reliability not guaranteed; foreground-service + persistent notification is the only compliant lane.
5. **Package visibility (API 30+)** — app inventory needs `<queries>`; unrestricted `QUERY_ALL_PACKAGES` disallowed without platform requirement.
6. **KGP deprecation warning** (`firebase_auth`/`firebase_core`) — future Flutter builds may fail; child app must avoid inheriting firebase deps.
7. **200-line rule applies to `.kt`** — native lane will fragment into many small files by design.
8. **Physical-device claims**: cannot be made without an attached device; current environment supports emulator verification only.

## 9. Stage 0 Verification Verdict

| Check | Result |
| :--- | :--- |
| Baseline Phase 1/2 evidence re-confirmed (this session: 1,020/1,020 tests, 0 analyzer issues, 0 line violations, APK 190,571,206 B) | **VERIFIED** |
| Working-tree integrity vs Phase 2 sign-off (doc-only delta, no code drift) | **VERIFIED** |
| Child-app / native inventory completeness | **VERIFIED** (greenfield confirmed) |
| Reusable-component inventory | **VERIFIED** (exported barrels read directly) |
| Prerequisites & dependency graph documented | **VERIFIED** (this report + master plan) |
| Stage 0 status | **COMPLETE — Phase 3 planning is VERIFIED WITH DOCUMENTED PREREQUISITES** |

No blockers prevent Stage 1. Real-device pairing (Module B, cross-device) and hardware-dependent acceptance criteria are pre-flagged as **BLOCKED-pending-prerequisite** (P-1/P-4) so they can never be silently faked.

**Raw evidence**: `_scratch/p3_inspect/agent_git/` (15 files), plus subagent transcripts preserved by the verification harness. Companion document: [PHASE_3_MASTER_PLAN.md](file:///d:/control/docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md).
