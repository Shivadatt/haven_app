# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 1 KNOWN LIMITATIONS

**Scope**: Every honest gap, deliberate fallback and deferred surface in `apps/haven_child` after Stage 1
**Date**: November 6, 2026
**Status**: ALL NON-BLOCKING FOR STAGE 1 ACCEPTANCE — each row is by design, documented in code, or a pre-declared BLOCKED/DEFERRED gate from [PHASE_3_MASTER_PLAN.md](file:///d:/control/docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md) §7
**Not limitations (checked and clean)**: no failing test, no skipped test, no analyzer issue, no line-count violation, no secret in the tree, no parent-app regression.

---

## 1. Transitive Cloud Dependencies Leak Into the Child Build (**highest-value finding**)

**Observed**: `fvm flutter build apk --debug` for the child app warns
`WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_auth, firebase_core`
(log: [`_scratch/p3_stage1/build/build_log.txt`](file:///d:/control/_scratch/p3_stage1/build/build_log.txt)).

**Reality**:
- The child `pubspec.yaml` declares **no** cloud package — only `get`, `path_provider`, `flutter_secure_storage` and the three local `haven_*` path deps.
- No child Dart file imports `supabase`, `firebase_core` or `firebase_auth`; an architecture test asserts the dependency lines stay clean.
- They arrive **transitively through the `haven_api` path dependency**, which is built for the parent app's cloud lanes.
- The Stage-1 offline runtime path is unchanged: nothing initialises or calls them; the child manifest declares no `INTERNET`, so the shipped build has no network lane.

**Impact**: (a) the "no cloud deps in the child APK" promise is only true of *declared* deps, and the docs must keep saying it that way; (b) the KGP warning is a future build-breaking risk the master plan already flagged (Stage 0 §8.6); (c) the APK carries unused Firebase/Supabase code (~162 MB).

**Recommendation (before Stage 3)**: split `haven_api` into an offline lane and a cloud lane (e.g. `haven_api` + `haven_api_cloud`, or conditional exports) so the child app can depend only on the offline core. This is a shared-package change and must be an owned decision, not a side effect of a child-stage task.

## 2. No Kotlin / Native Lane At All

`apps/haven_child/android` contains exactly one Kotlin file — the 5-line `MainActivity : FlutterActivity`. There is no method channel, no EventChannel, no service, no receiver, no device-admin. Consequence: ladder level 3 is unreached for every feature, and **D-4** (Pigeon vs hand-rolled typed contracts) is still open. Stage 0's `android_native/child_services` probe stays parent-side only and was not extended. Kotlin test infrastructure (P-5: junit + Robolectric) still does not exist.

## 3. Device Model and Manufacturer Render `Unavailable`

`Build.MODEL` / `Build.MANUFACTURER` have no pure-Dart reader on Android, so [`RealDeviceInformation`](file:///d:/control/apps/haven_child/lib/core/device/real_device_information.dart) returns `null` for both and `DeviceFactRows` renders the literal `Unavailable` plus a footnote. This is the **by-design fallback** the brief requires instead of an invented value. `Platform.operatingSystemVersion` *is* a real pure-Dart read and shows a genuine value on-device (on a non-Android test host it is null, also handled). Tests assert the nulls rather than a fake value, and the fake reader mirrors the same honesty so a test can never accidentally prove a fabricated model renders.

## 4. No Emulator or Device Run Was Performed

The child APK was compiled, never installed or launched. No `Pixel_9a` session, no `adb install`, no screenshot, no on-device navigation. Every Stage-1 "it works" statement in these docs is **host-side Flutter test** evidence. Physical-device verification stays blocked on P-1 / B-3; the brief's expected Realme RMX2161 (Android 12, ColorOS) was never attached.

## 5. Create-Once Is an Application Rule, Not a Database Constraint

Duplicate prevention is real but layered, and the layers do different jobs:
- the repository's explicit read-before-create enforces "at most one child profile" (`child_profile_create_once`);
- `LocalConstraints` enforces uniqueness on `profiles.id` (`local_unique_violation: profiles.id`).

Because `LocalIds.create()` mints a fresh random id per call, the *engine* rule alone would not stop two concurrently created rows with different ids — the explicit check does, and it is sound for Stage 1's single-isolate write path (plus the controller's in-flight guard). If a later stage introduces a second writer lane, this needs a genuine single-row guard (fixed id, or a composite/conditional rule in the engine) rather than reliance on id uniqueness. Documented at [`CHILD_LOCAL_STORAGE_CONTRACT.md`](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md) §5.

## 6. `childLocalState` Is an Additive Non-Table Key

Onboarding drafts and the local session live under one extra top-level JSON key because the 19-table `TableName` registry has no key-value table and inventing one would breach contract rule 3. Consequences: this key is **outside** the registry's constraint checks (no unique/foreign-key rule applies to it), it is preserved as-is by the engine's parse/save path, and it is removed entirely when its last section is cleared. Migration handling for it is a Stage-2+ decision; the schema-version refusal path is already tested.

## 7. No Profile-Editing UI

`ChildProfileRepository.update` exists and is tested at repository level (patch semantics, validation at the boundary, `updated_at` stamp, role guard, id targeting), but **no screen exposes editing** after setup. The profile home is read-only plus navigation. Deliberate: Stage 1 brief scope is the foundation; edit UX belongs to Stage 8. Not a bug, but it must not be described as "profile management complete".

## 8. Manual Version Sync

[`ChildConfig.appVersion`](file:///d:/control/apps/haven_child/lib/core/constants/child_config.dart#L28-L31) is hand-kept equal to `pubspec.yaml` `version:` (both `0.1.0` at sign-off) because the device screen displays it. Nothing asserts the two match yet; the code comment invites exactly that Stage-2 test. Until it exists, a version bump in one place silently lies on the device screen.

## 9. Cosmetic Test-Runner Warning (documented, then re-checked)

During the test-completion pass a cosmetic hit-test warning was observed from taps on partially visible widgets (the driver now calls `Scrollable.ensureVisible` before tapping). On this doc agent's two clean post-quiescence suite runs (167/167, exit 0) **no warning line was emitted at all** — grepping the full run for `warning`/`hit test` produced nothing. Reported as: observed mid-pipeline, not reproducible on the final tree; if it returns it is cosmetic (a test-harness advisory), never a product claim.

## 10. Out-of-Scope by Brief §5 (DEFERRED / BLOCKED, restated so nothing is implied)

| Area | Status | Gate |
| :--- | :--- | :--- |
| Real parent↔child pairing / registration | **BLOCKED** | D-5 / B-1 — no backend, no approved same-device rendezvous; the "Not registered" and "Parent connection: Not connected" strings are the honest state |
| 6-digit pairing-code entry + validation | **DEFERRED** | Stage 2, needs the written code spec (**D-3**) — simulation TTL 5 min vs evidenced `CODE_TTL_MINUTES = 10` unresolved |
| Usage access / screen-time monitoring | **DEFERRED** | Stage 3 (needs P-5, P-1 for FULL credit) |
| Policy evaluation engine | **DEFERRED** | Stage 4 (pure Dart, no device needed) |
| Enforcement / app blocking | **DEFERRED** | Stage 5 feasibility gate first; likely B-2 outcome "not available on consumer devices" |
| Location + safe zones | **DEFERRED** | Stage 6 |
| Background lifecycle / foreground service | **DEFERRED** | Stage 7 |
| Child dashboard, events, audit store | **DEFERRED** | Stage 8 |
| Parent-integration contracts | **DEFERRED** | Stage 9 |
| Full device matrix + final verification | **DEFERRED** | Stage 10 |

## 11. Smaller Honest Notes

- **Release build not exercised**: only `--debug`; the release block still carries the template's debug-signing placeholder, and Play/signing constraints are untested.
- **Launcher icon is the Flutter template default** (`ic_launcher.png` set); child-specific art is not a Stage-1 scope item.
- **`flutter_secure_storage` is a declared dependency but Stage 1 stores nothing in it** — the child lane has no secret to hold; keeping it registered is a Stage-2 pairing/credential affordance, not current behaviour.
- **Gradle wrapper scripts (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) and `GeneratedPluginRegistrant.java` are ignore-covered** by `apps/haven_child/android/.gitignore`, matching the parent app exactly — a fresh clone relies on `flutter` to regenerate them, same as for `haven_app`.
- **Phase 2's simulated pairing is untouched** and remains labelled as a simulation; Stage 1 wraps nothing parent-side.
- **Working tree is staged, not untracked** — see the audit report Part C.3 for that verification finding and its disposition.
