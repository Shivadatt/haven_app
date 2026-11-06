# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 1 FEATURE MATRIX

**Scope**: Per-feature completion level for `apps/haven_child` (Stage 1 — Child App Foundation)
**Date**: November 6, 2026
**Rule applied**: a module is credited only at the level actually **evidenced** ([PHASE_3_MASTER_PLAN.md](file:///d:/control/docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md) §1.2). No Stage-1 row reaches level 3 or above.

---

## 1. Six-Level Completion Ladder

| Level | Meaning | Highest Stage-1 row |
| :--- | :--- | :--- |
| 1 | UI — screen exists and renders | — |
| 2 | Flutter logic + tests — real controller/state/storage, covered by automated tests | **ALL Stage-1 features** |
| 3 | Kotlin native — a real native reader/service exists | none (DEFERRED) |
| 4 | Permission granted — Android granted the capability to a running build | none (DEFERRED; no permission declared) |
| 5 | Physical-device verified | none (**NOT TESTED** — no device attached; no emulator launched) |
| 6 | Parent↔child end-to-end | none (**BLOCKED** — D-5 / B-1) |

## 2. Feature Matrix

| # | Feature | L1 UI | L2 Flutter logic + tests | L3 Kotlin | L4 Permission | L5 Device | L6 E2E | Stage-1 verdict | Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | App shell, GetX bindings, route table, unknown route | ✅ | ✅ (8 architecture + 6 bindings + 4 app-flow tests) | N/A | N/A | N/A | N/A | **COMPLETE** | [`child_pages.dart`](file:///d:/control/apps/haven_child/lib/app/routes/child_pages.dart), `test/architecture/` |
| 2 | Flat theme + shared components (scaffold/state view/chips/field/info row/blocked notice) | ✅ | ✅ (every screen renders through them; 8 narrow tests) | N/A | N/A | N/A | N/A | **COMPLETE** | [`lib/app/theme/`](file:///d:/control/apps/haven_child/lib/app/theme), [`lib/shared/components/`](file:///d:/control/apps/haven_child/lib/shared/components) |
| 3 | Splash / boot decision (loading, error+retry, corrupt flag) | ✅ | ✅ (10 controller + 5 page tests) | N/A | N/A | N/A | N/A | **COMPLETE** | [`splash_controller.dart`](file:///d:/control/apps/haven_child/lib/features/splash/controllers/splash_controller.dart) |
| 4 | Five-step onboarding + resume + validation gates | ✅ | ✅ (52 tests) | N/A | N/A | N/A | N/A | **COMPLETE** | [CHILD_ONBOARDING_FLOW.md](file:///d:/control/docs/implementation/phase_3/CHILD_ONBOARDING_FLOW.md) |
| 5 | Profile create-once write + role guard + patch update | — | ✅ (11 repository tests) | N/A | N/A | N/A | N/A | **COMPLETE** (repo-level) | [`local_child_profile_repository.dart`](file:///d:/control/apps/haven_child/lib/core/storage/local_child_profile_repository.dart) |
| 6 | Profile **editing UI** after setup | ❌ | partial (update logic tested at repository level only) | N/A | N/A | N/A | N/A | **PARTIAL** — no edit screen ships | profile page has no edit affordance |
| 7 | Profile home view (identity, honest status lines, nav) | ✅ | ✅ (6 page tests) | N/A | N/A | N/A | N/A | **COMPLETE** | [`profile_page.dart`](file:///d:/control/apps/haven_child/lib/features/profile/views/pages/profile_page.dart) |
| 8 | Device information screen — Android version, app version, app id | ✅ | ✅ (6 page tests + 9 reader tests) | N/A | N/A | N/A | N/A | **COMPLETE** for the pure-Dart fields | [`real_device_information.dart`](file:///d:/control/apps/haven_child/lib/core/device/real_device_information.dart) |
| 9 | Device information — model / manufacturer | renders `Unavailable` | ✅ for the fallback path only (nulls are asserted, never guessed) | ❌ needs Kotlin `Build.MODEL`/`MANUFACTURER` | N/A | N/A | N/A | **PARTIAL by design** — native read DEFERRED (D-4) | `DeviceFacts` doc comment; `device_information_test.dart` |
| 10 | Registration status line ("Not registered") | ✅ | ✅ (asserted constant) | N/A | N/A | N/A | ❌ | **COMPLETE as Stage-1 constant**; real registration DEFERRED (Stage 2) | `RealDeviceInformation.notRegistered` |
| 11 | Permission dashboard (4 categories, blocked-derived status, disabled action) | ✅ | ✅ (7 source + 5 controller + 7 page + 1 narrow) | ❌ reader absent | ❌ nothing requested | N/A | N/A | **COMPLETE as specified for Stage 1**; real status reads DEFERRED | [CHILD_PERMISSION_DASHBOARD.md](file:///d:/control/docs/implementation/phase_3/CHILD_PERMISSION_DASHBOARD.md) |
| 12 | Local storage contract (`haven_local.json` reuse + `childLocalState`) | N/A | ✅ (33 storage tests incl. coexistence + malformed recovery) | N/A | N/A | N/A | N/A | **COMPLETE** | [CHILD_LOCAL_STORAGE_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md) |
| 13 | Child local session (identity without `LocalUserAuth`) | N/A | ✅ (round-trip + splash routing tests) | N/A | N/A | N/A | ❌ | **COMPLETE as a local memory, not an account** | [`child_local_session.dart`](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart) |
| 14 | Developer reset exit for a corrupt document | ✅ | ✅ (malformed-recovery suite; explicit, never automatic) | N/A | N/A | N/A | N/A | **COMPLETE** | [`child_data_resetter.dart`](file:///d:/control/apps/haven_child/lib/core/storage/child_data_resetter.dart) |
| 15 | Loading / error / empty / retry state coverage | ✅ | ✅ (all five screens incl. `Get.reset` lifecycle) | N/A | N/A | N/A | N/A | **COMPLETE** | `test/app/`, `test/features/*`, `ChildStateView` |
| 16 | Android project config (`com.haven.child`, hardened Gradle parity, zero permissions) | N/A | N/A | N/A (build config, not app logic — no ladder level applies; credited on its own terms) | N/A | N/A | N/A | **COMPLETE (build configuration only)** — compiles to an APK | `android/` tree; APK artifact |
| 17 | Child debug APK build | N/A | N/A | N/A | N/A | ❌ never installed/launched | N/A | **COMPLETE (build only)** — install/launch **NOT TESTED** | `BUILD_EXIT:0`, 162,458,160 B |
| 18 | Real parent↔child pairing | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **BLOCKED** (D-5 / B-1: no backend, no approved rendezvous) | master plan §7 |
| 19 | Usage access / screen-time monitoring | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stage 3 | master plan §4 |
| 20 | Policy evaluation / enforcement | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stages 4–5 (feasibility gate first) | master plan §4 |
| 21 | Location / safe zones | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stage 6 | master plan §4 |
| 22 | Background lifecycle / foreground service | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stage 7 | master plan §4 |
| 23 | Child dashboard with real data + event store | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stage 8 | master plan §4 |
| 24 | Parent-integration contracts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | **DEFERRED** — Stage 9 | master plan §4 |

## 3. Reading Rules For This Matrix

- **N/A** = the level does not apply to this kind of row (e.g. a Gradle config row cannot be "permission granted").
- **❌ with no verdict word** at a level = Stage 1 neither implemented nor claimed it.
- A row marked **COMPLETE** is complete *for its Stage-1 scope only*, which the row text states. Nothing in this matrix says "Phase 3 feature complete".
- Rows 8–10 share one screen: the screen itself is COMPLETE, two of its six fields are PARTIAL because no pure-Dart reader exists.
- No row may be promoted by citing a UI, a permission dialog, a mocked channel value or a fake-based test — the brief forbids it and the architecture tests enforce the same rule in code.
