# HAVEN PARENTAL CONTROL — CHILD APP ARCHITECTURE

**Scope**: Phase 3 Stage 1 — architecture of `apps/haven_child` (child companion, local-first)
**Date**: November 6, 2026
**Status**: COMPLETE at ladder level 2 (Flutter logic + tests) — **PARTIAL by design**: no Kotlin/native lane exists yet (D-4 open)
**Verified against**: the files on disk this session; the 167-test child suite; the root analyzer and line-count gates

---

## 1. Shape

The child app is a second, independent Flutter application that mirrors the parent's layering 1:1 and reuses the same three shared packages. It does **not** import `apps/haven_app` — an architecture test proves it (§7).

```
apps/haven_child/
  lib/
    main.dart                     # reads HAVEN_CHILD_ENV -> ChildConfig -> ChildApp
    app/
      app.dart                    # ChildApp: GetMaterialApp, named routes, ChildTheme
      bindings/child_initial_bindings.dart   # register() (sync, idempotent) + startStorage() (async)
      routes/child_routes.dart    # ChildRoutes constants (fixed table)
      routes/child_pages.dart     # ChildPages.pages + ChildPages.unknown
      routes/unknown_page.dart    # honest "not part of the child app yet"
      theme/                      # child_colors / child_spacing / child_text / child_theme
    core/
      constants/child_config.dart
      device/                     # DeviceFacts + DeviceInformation seam + real & fake readers
      permissions/                # ChildPermission enum + PermissionStatusSource seam + Unconfigured impl
      session/child_local_session.dart          # child-lane session (replaces LocalUserAuth here)
      storage/                    # ChildDatabase, ChildLocalStateStore, repositories, resetter, paths
    shared/components/            # ChildScaffold/ChildPageBody, ChildStateView, ChildStatusChip,
                                  # ChildField, ChildInfoRow, ChildBlockedNotice
    features/<feature>/{bindings,controllers,services,domain,data,views/pages,views/steps,views/widgets}
  test/  (feature-mirrored + app/ + architecture/ + core/ + narrow/ + support/)
  android/ (own Gradle project, com.haven.child, zero permissions)
```

| Layer | Files | Lines | Longest file |
| :--- | :--- | :--- | :--- |
| `lib/` | 58 Dart | 3,342 | 160 — `features/onboarding/controllers/onboarding_controller.dart` |
| `test/` | 29 Dart | 3,450 | 199 — `test/support/fakes.dart` |
| Kotlin | 1 | 5 | `MainActivity.kt` (`class MainActivity : FlutterActivity()`) — no logic by design |

## 2. Composition Root and DI

[`main.dart`](file:///d:/control/apps/haven_child/lib/main.dart) → [`ChildApp`](file:///d:/control/apps/haven_child/lib/app/app.dart) → [`ChildInitialBindings`](file:///d:/control/apps/haven_child/lib/app/bindings/child_initial_bindings.dart). The parent's two-tier split is copied on purpose:

| Tier | When | What is registered | Honesty property |
| :--- | :--- | :--- | :--- |
| `register(config)` | synchronous, idempotent (hot restart re-runs `build`) | `ChildConfig`, `DeviceInformation` → `RealDeviceInformation`, `PermissionStatusSource` → `UnconfiguredPermissionStatusSource` (all `permanent: true`) | every screen resolves a reader even before storage is open, and those readers can only answer with a real read or a typed refusal |
| `dependencies()` / `startStorage()` | async, once | on a successful open: `ChildDatabase`, `ChildProfileRepository`, `OnboardingStateStore`, `ChildSessionStore` | a **failed open is not cached** — the next call performs a genuine second attempt (the splash's "Try again" is real); providers, not instances, are handed to the splash controller so nothing resolves a half-built repository |
| `resetForTests()` / `unregisterStorageSeams()` | test seam | clears the static register flag, the storage future, the path override and `Get.reset()` | `GetxController.onClose` is asynchronous, so a second explicit unregister prevents one stale write leaking across suites |

Per-feature `Bindings` compose controllers only (`SplashBindings`, `OnboardingBindings`, `ProfileBindings`, `DeviceBindings`, `PermissionsBindings`) and are attached to their `GetPage`. The splash binding is the only one that injects functions rather than instances, because storage exists only after `openStorage()` resolves.

## 3. Route Table (fixed)

| Route | Path | Page | Binding | Arguments |
| :--- | :--- | :--- | :--- | :--- |
| `splash` | `/splash` | `features/splash/views/pages/splash_page.dart` → `SplashPage` | `SplashBindings` | — |
| `onboarding` | `/onboarding` | `features/onboarding/views/pages/onboarding_page.dart` → `OnboardingPage` | `OnboardingBindings` | — |
| `profile` | `/profile` | `features/profile/views/pages/profile_page.dart` → `ProfilePage` | `ProfileBindings` | — |
| `device` | `/device` | `features/device/views/pages/device_page.dart` → `DevicePage` | `DeviceBindings` | — |
| `permissions` | `/permissions` | `features/permissions/views/pages/permissions_page.dart` → `PermissionsPage` | `PermissionsBindings` | — |
| `unknown` | `/unknown` | `app/routes/unknown_page.dart` → `UnknownPage` | none | — |

`initialRoute` is `/splash`; `unknownRoute` is the honest "This screen is not part of the child app yet." page — the same policy as the parent's `AppPages`. Detail screens (`/device`, `/permissions`) open **on top of** onboarding via the injected `push`, so the child can always return to the same step; onboarding exit uses `Get.offNamed` so a finished setup is not sitting behind a stale setup flow.

## 4. Persistence and Seams

The storage lane reuses the `haven_api` offline engine rather than inventing a second one; the full contract, document shape and failure vocabulary are in [CHILD_LOCAL_STORAGE_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md). Architecture-relevant points:

- **One document, two writers.** [`ChildDatabase`](file:///d:/control/apps/haven_child/lib/core/storage/child_database.dart) owns one `FileLocalStore` + one `LocalTables`; [`ChildLocalStateStore`](file:///d:/control/apps/haven_child/lib/core/storage/child_local_state.dart) writes the additive `childLocalState` key through the *same* store and calls `LocalTables.reload()` after every save, so neither writer can resurrect a stale copy of the other's data.
- **Seams, not SDKs.** Screens/controllers depend on `DeviceInformation`, `PermissionStatusSource`, `ChildProfileRepository`, `OnboardingStateStore`, `ChildSessionStore`. Nothing in `lib/features/` touches `dart:io`, `path_provider`, or the store classes directly.
- **Result-only boundary.** Every seam returns `Result<T>`; a corrupt document returns the typed `StorageFailure` (`local_database_corrupt`) and is never silently reset.
- **Identity.** `LocalUserAuth` (which hard-codes `role: 'parent'`) is untouched in `packages/haven_api` and deliberately unused here; child identity is [`ChildLocalSession`](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart) + `ProfileRole.child`.

## 5. UI System

Flat by construction: elevation 0, hairline separators instead of stacked shadows, one saturated accent, `ThemeMode.system` with both `ChildTheme.light` and `ChildTheme.dark` shipped as app-owned tokens (`ChildColors`, `ChildSpacing`, `ChildText`, `ChildRadius`) — the child copy is used rather than importing the parent app, because importing `haven_app` is forbidden.

[`ChildStateView<T>`](file:///d:/control/apps/haven_child/lib/shared/components/state_view.dart) is the single place that decides loading / error / blocked / empty / data, and it accepts both a typed `Result<T>` (so a `BlockedFailure` renders the shared `ChildBlockedNotice` vocabulary) and a plain `errorMessage` channel for text-only states. A non-retryable failure renders no "Try again" button. There is **no backend banner** in the child app: Stage 1 declares no network, so a banner would be decoration.

Every data-bearing screen also renders correctly at 320×568; eight narrow-screen widget tests enforce it rather than assume it.

## 6. Deviations from the Master Plan (recorded, not hidden)

| Master plan §2 | Stage 1 reality | Reason |
| :--- | :--- | :--- |
| `lib/features/{child_onboarding, child_pairing, child_status, child_usage, child_policy, child_location, child_events, child_settings}` | `lib/features/{splash, onboarding, profile, device, permissions}` | route-aligned naming, matching the parent app's actual convention (`features/onboarding`, `features/device_pairing`, …); Stage 1 has no pairing/usage/policy/location/event/settings surface to create a directory for. The later stage that builds one adds its own directory. |
| `AppRoutes` / `AppPages` / `phase3_pages.dart` precedent | `ChildRoutes` / `ChildPages` | the child app owns its own tables; a `phaseN_pages` split was unnecessary with one stage's worth of routes |
| "HavenTheme copy-or-share" | app-owned `ChildTheme` (copy) | sharing would require importing the parent app or adding a new package — both out of Stage-1 scope |
| `android/` "MainActivity + bridge attach" | `MainActivity` only, **no bridge attached** | the native lane is deferred with decision D-4; adding a channel now would be unverifiable code |
| `test/` "driver classes" | present: [`test/features/onboarding/driver.dart`](file:///d:/control/apps/haven_child/test/features/onboarding/driver.dart) plus `support/{host,fakes,storage}.dart` | — |

## 7. Enforced Invariants (tested, not documented-only)

[`test/architecture/child_architecture_test.dart`](file:///d:/control/apps/haven_child/test/architecture/child_architecture_test.dart) (8 tests) asserts:

1. Zero `import`/`export`/`part` line in `lib/` mentions `haven_app` (scans every Dart file at test time).
2. The `pubspec.yaml` dependency lines contain neither `haven_app` nor `supabase` nor `firebase_core` nor `http:` (comments stripped first, so the header comment that *names* the banned SDKs to explain their absence does not trip the check).
3. The Gradle file carries the child-owned `com.haven.child` (D-1 can never silently regress).
4. Route table completeness: each named route maps to exactly one real page type, no duplicates, no route served by `UnknownPage`, and **no extra route** beyond the Stage-1 promise.
5. The splash route, pumped with no storage seam registered, lands on the typed "Local storage is not available on this device." failure frame — never an unhandled exception.

## 8. Extension Points for Stage 2+

| Need | Where it lands | Guardrail already in place |
| :--- | :--- | :--- |
| Real device model/manufacturer | `core/device/` gains a native reader behind the existing `DeviceInformation` seam | `DeviceFacts` nulls render `Unavailable`; D-4 decides channel typing first |
| Real permission status | `core/permissions/` gains a reader behind `PermissionStatusSource` | `PermissionStatus` is constructible only behind an `Ok`; cards cannot print Granted otherwise |
| Pairing / registration | new `features/pairing/` + `ChildRoutes` entries + `RealDeviceInformation.notRegistered` replaced by a real read | registration string is single-sourced; D-3/D-5 gates apply |
| Usage, policy, location, events | their own feature directories + new `childLocalState` sections or registry tables | `TableName`/`LocalConstraints` reject invented tables; additive-key decision is documented |
| Backend lanes | only through `haven_api` seams | child pubspec forbids cloud SDKs; the transitive KGP leak should be fixed by splitting `haven_api` first |
