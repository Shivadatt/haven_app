# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 1 TEST RESULTS

**Scope**: Every command executed to certify Stage 1, its exit code, and its exact counts
**Date**: November 6, 2026
**Status**: ALL STAGE-1 GATES GREEN — 167/167 child tests, 1,020/1,020 protected baseline, 0 analyzer issues, 0 line violations, child debug APK built
**Environment**: Windows 10 (10.0.26300.0 x64) · Git Bash · FVM launcher `C:/Users/ASUS/AppData/Local/Pub/Cache/bin/fvm.bat` · pinned Flutter **3.44.6** / Dart **3.12.2** · branch `main` · HEAD `8e50da0` (unchanged — nothing was committed)

---

## 1. Gate Table (the five numbers that certify Stage 1)

| # | Command | Working dir | Exit | Result (exact) | Wall |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `fvm flutter test` | `D:/control/apps/haven_child` | **0** | `00:18 +167: All tests passed!` | 18s |
| 1b | `fvm flutter test` (re-run by this doc agent, post-quiescence) | `D:/control/apps/haven_child` | **0** | `00:15 +167: All tests passed!` | 15s |
| 2 | `fvm flutter test` | `D:/control/apps/haven_app` | **0** | `01:34 +924: All tests passed!` | 94s |
| 3 | `fvm flutter test` | `D:/control/packages/haven_api` | **0** | `00:03 +66: All tests passed!` | 12s |
| 4 | `fvm flutter test` | `D:/control/packages/haven_core` | **0** | `00:00 +18: All tests passed!` | 10s |
| 5 | `fvm flutter test` | `D:/control/packages/haven_models` | **0** | `00:00 +12: All tests passed!` | 5s |
| 6 | `fvm flutter analyze` (first clean run) | `D:/control` | **0** | `No issues found! (ran in 53.5s)` | 53.5s |
| 6b | `fvm flutter analyze` (re-run by this doc agent) | `D:/control` | **0** | `No issues found! (ran in 10.4s)` | 10.4s |
| 7 | `dart scripts/check_line_counts.dart` | `D:/control` | **0** | `hand-written source files scanned: 704` / `violations: 0` | <5s |
| 8 | `fvm flutter pub get` (child) | `D:/control/apps/haven_child` | **0** | `Got dependencies!` (`PUBGET_EXIT:0`) | — |
| 9 | `fvm flutter build apk --debug` (child) | `D:/control/apps/haven_child` | **0** | `√ Built build\app\outputs\flutter-apk\app-debug.apk` (`BUILD_EXIT:0`) | 211s (Gradle 199.8s) |

Re-runs (1b, 6b) are this doc agent's own confirmation on the quiescent tree; wall-time differences are cache warmth, not variance in outcome. No gate needed a third run.

## 2. Counts and the No-Double-Count Rule

| Suite | Tests | Belongs to |
| :--- | :--- | :--- |
| `apps/haven_child` | **167** | NEW in Stage 1 — child-only |
| `apps/haven_app` | 924 | protected Phase 1/2 baseline |
| `packages/haven_api` | 66 | protected baseline |
| `packages/haven_core` | 18 | protected baseline |
| `packages/haven_models` | 12 | protected baseline |
| **Protected baseline total** | **1,020** | unchanged, zero variance |
| **Repo-wide total (baseline + child)** | **1,187** | 1,020 + 167 |

**The 167 child tests are separate from the protected 1,020.** They are never added into the baseline figure, and the baseline is never re-labelled as 1,187: the regression gate is specifically "the parent app and shared packages still pass exactly as before" (924/66/18/12), which they do. Phase 2's protected-doc figure of **990** (haven_app + haven_api) is the sub-scope the Phase 2 sign-off used; the repo-wide figure is 1,020. All counts here are exact, per the correction made during Phase 2 when a doc claim of "975+" was replaced by the exact 990.

## 3. Protected-Baseline Regression Detail

Raw logs, preserved: [`_scratch/p3_stage1/regression/`](file:///d:/control/_scratch/p3_stage1/regression)

| Log | Tail |
| :--- | :--- |
| `haven_app_test.log` | `01:34 +924: All tests passed!` · `EXIT_CODE=0` |
| `haven_api_test.log` | `00:03 +66: All tests passed!` · `EXIT_CODE=0` · `WALL_SECONDS=12` |
| `haven_core_test.log` | `00:00 +18: All tests passed!` · `EXIT_CODE=0` · `WALL_SECONDS=10` |
| `haven_models_test.log` | `00:00 +12: All tests passed!` · `EXIT_CODE=0` · `WALL_SECONDS=5` |

Zero reruns needed; no test was modified, skipped, weakened or deleted to reach green (`git status` shows no change under `apps/haven_app/` or `packages/`).

## 4. §7 Coverage Map — What the 167 Child Tests Cover

Composition: **106** pure/unit `test(` cases + **61** `testWidgets(` cases; 24 test files across `test/{app,architecture,core,features,narrow,support}`.

| Area | File(s) | Cases | What is asserted |
| :--- | :--- | :--- | :--- |
| Input validation & step gates | `onboarding_flow_test.dart` | 8 | enum index IS the persisted step; `fromIndex` clamps; progress labels 1..5; information steps never block; name rule before age rule; `profileProblem` re-checks at finish; parent-app age-bracket vocabulary + field cap |
| State transitions | `onboarding_controller_test.dart`, `onboarding_finish_controller_test.dart` | 11 + 5 | restore fresh/seeded/failed; navigation persists; gate blocks without navigating or saving; in-flight guard makes a second tap a no-op; refusal shown, stays in flow |
| Repository CRUD | `child_profile_repository_test.dart` | 11 | untouched device reads as "no profile yet"; foreign-role row refused unchanged; first create writes a child row with clock stamps; **create-once** refusal with the typed detail; invalid name never reaches the table; blank → absent; update targeting; null patch = no write; role guard protects update too |
| Round-trips | `storage_roundtrip_test.dart` | 9 | draft/session `toMap`/`fromMap` preserve every field; `num`→`int` decode; malformed section → `null`, never a crash; store-level persist/re-read/cleanup |
| Malformed / corrupt recovery | `malformed_recovery_test.dart` | 10 | unparseable file and valid-JSON-wrong-shape both `local_database_corrupt`; newer schema refused not downgraded; missing file is first launch; section reads pass the typed failure through; readable-first wipe **refuses** a corrupt doc; exit hatch replaces damage; path seam redirect; throwing resolver → typed failure |
| Device nulls / honest fallbacks | `device_information_test.dart` | 9 | the two native-only fields are null, never guessed; off-device read never throws; identity fields single-sourced; `Unavailable` decided once centrally; six fixed rows in order; footnote copy stable; the fake mirrors the real reader's honesty |
| Permission blocked mapping | `permission_status_test.dart` | 7 | exactly four capabilities with unique wire/label/why/icon; every category resolves to `blocked`; refusal names the missing piece and the permission; no `Ok` path from the shipped source; strings single-sourced; interface stays `Result`-typed |
| Session / boot lifecycle | `splash_controller_test.dart`, `splash_page_test.dart` | 10 + 5 | new device → onboarding; profile+matching session → home; session naming a different profile is unfinished; failed open = honest message, no navigation; corrupt flagged so the reset becomes legal; reset-then-reboot happens once; damaged session read as unfinished; loading frame; failed reset keeps the failure visible |
| Bindings / DI lifecycle | `child_initial_bindings_test.dart` | 6 | `register` idempotent and installs only honest readers; storage opens at the override lane; second call returns the SAME future; a FAILED open is not cached; seams unregister/reset; `ChildConfig` defaults local-only |
| Coexistence | `storage_coexistence_test.dart` | 3 | `childLocalState` and `tables` share one file without clobbering; last section removed → key removed; developer reset clears everything |
| Widget: welcome / profile / avatar steps | `onboarding_page_test.dart` | 11 | step 1 honest limits; Continue walks with progress copy; empty name refused visibly; missing bracket hits the second gate; name+bracket+avatar persist; pending store shows spinner; failing store shows error with working retry; device review pushes the real screen; permissions step explains all four and requests nothing; Back cannot pass step 1 |
| Widget: completion + double submit | `onboarding_completion_page_test.dart`, `onboarding_resume_test.dart` | 7 + 5 | preview + "happens once"; submit creates once, clears draft, routes to `/profile`; a fast double tap cannot start a second create; create-once refusal surfaced; incomplete resumed draft bounces to step 2; half-finished device completes without touching the profile; restart resumes step + values |
| Widget: device screen | `device_page_test.dart` | 6 | every declared row renders; native-only fields say `Unavailable`; registration reads the honest constant; why-note + no-buttons promise visible; the REAL reader works on the host (nulls fall back) |
| Widget: permission cards | `permissions_page_test.dart` | 7 | four cards keyed by wire; none can read Granted; settings action visibly dead with its explanation; WHY copy repeats setup; a real `Ok` is the only path to "Granted"; a throwing source is reported with retry |
| Widget: profile home | `profile_page_test.dart` | 6 | no profile yet = setup prompt not error; finished setup shows the honest lines; profile-without-session warns instead of claiming success; refused read shown as the refusal; missing bracket → `Unavailable` not blank |
| Widget: app flow / routes | `child_app_flow_test.dart`, `widget_test.dart` | 4 + 1 | empty device → Start setup → five steps → home; re-running cannot create a second profile; home links reach `/device` and `/permissions`; unlisted route lands on the honest unknown page |
| Narrow layout 320×568 | `narrow_screens_test.dart` | 8 | one case per surface — welcome step, About-you step, device review step, finish step, permission dashboard, device page, profile home (empty and filled), boot-failure text wrap; no RenderFlex overflow tolerated (`takeException`) |
| Architecture gates | `child_architecture_test.dart` | 8 | **no `haven_app` import/export/part anywhere in `lib/`**; pubspec dependency lines free of `haven_app`/`supabase`/`firebase_core`/`http:`; Gradle carries `com.haven.child`; route table complete, duplicate-free, no placeholder page, no extra route; `unknownRoute` honest; splash without a storage seam builds the typed failure frame with no exception |

Test hygiene: hand-written fakes only (`test/support/fakes.dart`, 199 lines) — no mocking package; every widget test pumps through the real `ChildTheme` and, for flow tests, the real route table (`childAppHost`); any lane touching `dart:io` runs inside `tester.runAsync` with `settleIo` instead of `pumpAndSettle` (fake-async never completes a real IO call). **Zero `skip:` markers and zero deleted tests** (grep-verified against `test/`).

## 5. Not Tested (recorded so it cannot be mistaken for a pass)

| Item | Status |
| :--- | :--- |
| Launching the child APK on an emulator (`Pixel_9a` exists in the SDK) | **NOT TESTED** — never attempted in Stage 1 |
| Installing/launching on any physical device | **NOT TESTED** — none attached (`adb devices` empty) |
| Real Android permission behaviour | **NOT TESTED / DEFERRED** — no reader exists |
| Kotlin native code | **NOT TESTED** — no Stage-1 Kotlin beyond the 5-line `MainActivity`; no junit/Robolectric infrastructure yet (P-5) |
| Parent↔child interaction on one device | **NOT TESTED / BLOCKED** — D-5, B-1 |
| `flutter build apk --release`, signing, Play constraints | **NOT ATTEMPTED** — Stage 1 scoped to `--debug` |

## 6. Transient Logs — Why They Are Not Evidence

`_scratch/p3_stage1/regression/` also contains three artifacts taken **while the test-completion agent was still writing files**: `root_analyze.log` (11 issues, exit 1, incl. 4 `error -` lines in not-yet-finished test files), `root_analyze_rerun.log` (15 issues, exit 1) and `check_line_counts.log` (687 files scanned, 2 violations — `storage_roundtrip_test.dart` at 206 and `onboarding_controller_test.dart` at 221, both since refactored to 119 and 126 lines). They were deliberately **not** used as Stage-1 evidence; the certified scans (§1 rows 6/7) were taken only after all agents were quiescent. They remain on disk as pipeline history.
