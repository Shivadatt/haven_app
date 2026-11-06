# HAVEN PARENTAL CONTROL — CHILD PERMISSION DASHBOARD

**Scope**: Phase 3 Stage 1 — `/permissions` and the permission-status seam (brief Module E, Stage-1 slice)
**Date**: November 6, 2026
**Status**: COMPLETE **as specified for Stage 1** (explanatory dashboard over an all-`blocked()` source) — **DEFERRED**: every real Android permission read (needs the Kotlin lane, ladder level 3+)
**Sources**: [`lib/core/permissions/`](file:///d:/control/apps/haven_child/lib/core/permissions), [`lib/features/permissions/`](file:///d:/control/apps/haven_child/lib/features/permissions)

---

## 1. What Stage 1 Promises (and Promises Not To Do)

| Promised | Explicitly not done |
| :--- | :--- |
| Name the four capabilities a later Phase 3 stage may grow, each with child-readable WHY copy | request a permission (no runtime permission API is called) |
| Render each capability's status from a typed read seam | read Android permission state (no channel exists) |
| Say plainly that nothing has been requested and nothing is monitored | open system settings (the action is present but **disabled**) |
| Keep the refusal vocabulary identical to the rest of the product | present any card as Granted / Not granted |

The manifest backs the promise: **zero** `<uses-permission>` entries in the main, debug and profile manifests — Stage 1 declares nothing, not even `INTERNET` ([`AndroidManifest.xml`](file:///d:/control/apps/haven_child/android/app/src/main/AndroidManifest.xml#L2-L8)).

## 2. The Four Capabilities

Defined once in [`child_permission.dart`](file:///d:/control/apps/haven_child/lib/core/permissions/child_permission.dart); each carries a stable `wire` label, a child-facing label, a Material icon and its WHY text. The same enum feeds the onboarding step-4 explanations and the dashboard cards, so there is exactly one honest story per capability.

| `wire` | Card label | Icon | Plain-language promise (abridged) |
| :--- | :--- | :--- | :--- |
| `usage_access` | Screen time access | `hourglass_bottom` | counts how long each app was used; nothing counts until an adult switches it on in Android settings |
| `location` | Location | `location_on_outlined` | shows where the device is, only while allowed; without it no place is ever recorded |
| `notifications` | Notifications | `notifications_none` | gentle reminders (e.g. before bedtime); without it the app stays quiet |
| `background_activity` | Runs in the background | `battery_charging_full` | keeps working when the screen is off; until it exists the app only knows what it saw while open |

## 3. The Read Seam

[`PermissionStatusSource`](file:///d:/control/apps/haven_child/lib/core/permissions/permission_status_source.dart) is the only thing the dashboard codes against:

```dart
Future<Result<PermissionStatus>> statusOf(ChildPermission permission);
```

`PermissionStatus{permission, granted}` can only be built behind an `Ok`, and the only way to an `Ok` is a source that actually reads the device. There is no constructor path from a guess, a UI flag or a mocked value.

Stage 1 registers exactly one implementation, permanently at startup: [`UnconfiguredPermissionStatusSource`](file:///d:/control/apps/haven_child/lib/core/permissions/unconfigured_permission_status_source.dart). For every permission it returns `haven_core`'s `blocked(...)`, with the missing piece named precisely:

- `missing` → `native permission reader for "<wire>" (Kotlin lane, Phase 3 Stage 2+)`
- `requirement` → `This build does not read Android permission state, so Haven reports nothing about <label>.`

The same class single-sources the two strings the UI prints:

| Constant | Rendered as |
| :--- | :--- |
| `cardStatusLabel` = `Unavailable — not yet implemented on this device build` | the chip label on every card (tone `blocked`) |
| `settingsActionNote` = `Opening device settings is not part of this build yet.` | the caption under the disabled settings action |

## 4. Rendering Rules

[`PermissionsController.load()`](file:///d:/control/apps/haven_child/lib/features/permissions/controllers/permissions_controller.dart) asks all four sources once (in parallel), stores each `Result` **verbatim** in a `PermissionCardState`, and never converts a blocked read into a status word. [`PermissionCard`](file:///d:/control/apps/haven_child/lib/features/permissions/views/widgets/permission_card.dart) then:

1. renders the icon + label;
2. renders the status line — a real `Ok` alone may show `Granted` / `Not granted` (`ValueKey('permission-real-read')`); anything else shows `Unavailable — not yet implemented on this device build` with `ValueKey('permission-unavailable')` and tone `blocked`;
3. renders the WHY copy from the enum;
4. renders `User action required: No`;
5. renders `Open device settings` as `OutlinedButton.icon(onPressed: null, …)` — visibly dead, with `settingsActionNote` underneath explaining *why* it is dead, so it never reads as a broken button;
6. page level: a `ChildStatusChip` reading `No permission has been requested.` above the list, plus "Nothing is monitored yet…" and the retry-capable `ChildStateView`.

Tone discipline: `blocked` is its own colour token and is deliberately **not** red — a not-yet-built feature is not the child's mistake; the words carry the meaning so the chip still reads in greyscale.

A source that breaks the no-throw rule is **reported**, not swallowed: the controller catches, sets `errorMessage` and ends the loading state so a frozen spinner can't masquerade as progress.

## 5. Honest Baseline vs. Parent App

| | Parent app (Phase 2) | Child app (Phase 3 Stage 1) |
| :--- | :--- | :--- |
| Declared permissions | `INTERNET` + empty device-admin receiver | none |
| Status source | `Unconfigured*` seams returning `blocked(...)` | same pattern, child-owned enum |
| Card vocabulary | `BlockedNotice` (requirement + `Missing: …`) | `ChildBlockedNotice` (requirement + `Missing: …`) |
| Settings navigation | not implemented | not implemented (button disabled on purpose) |

## 6. What Stage 2+ Must Do Before Any Status Can Say "Granted"

| Prerequisite | Notes |
| :--- | :--- |
| Kotlin native lane | a real reader behind `PermissionStatusSource`; typing decision **D-4** (Pigeon vs hand-rolled contract files) must be made first |
| Manifest declarations | only with the disclosure copy the brief requires, and only when the feature that needs it ships |
| Settings navigation | a real `ACTION_*` intent lane; then `openSettingsWillHelp` from `DevicePermissionFailure` becomes meaningful |
| API-level guards | 24 / 29 / 31 / 33 / 36 matrices (master plan §5) |
| Verification | emulator rows for denied/approximate/precise/revoked/disabled; device rows stay **NOT TESTED** until a device is attached (P-1 / B-3) |

Until those exist, this dashboard is the entire Module-E deliverable and its status is **as-ex-specified for Stage 1**, never "permission handling complete".

## 7. Test Mapping

[`permission_status_test.dart`](file:///d:/control/apps/haven_child/test/core/permissions/permission_status_test.dart) (7) — exactly four categories with unique wire/label/why/icon; every category resolves to `blocked`; the refusal names the missing piece and the permission; the status type has no `Ok` path from this source; the two UI strings are single-sourced; the interface stays `Result`-typed (a blocked `Err` is not an exception).
[`permissions_controller_test.dart`](file:///d:/control/apps/haven_child/test/features/permissions/permissions_controller_test.dart) (5) — one load answers all four exactly once; blocked reads carried verbatim; a granted fake (from a test source returning `Ok`) resolves through to the card; a throwing source sets the error and ends loading; retry clears the previous error.
[`permissions_page_test.dart`](file:///d:/control/apps/haven_child/test/features/permissions/permissions_page_test.dart) (7) — exactly four cards keyed by permission wire; **no card can read Granted** with the shipped source; the settings action is visibly dead with its own explanation; WHY copy matches setup step 4; a real `Ok` read is the only way "Granted" can appear; a throwing source is reported with retry; fits 320×568. Plus one narrow-screen case in `narrow_screens_test.dart`.
