# PHASE 3 STAGE 2 — GATES (Agent 2, independent measurement)

**Measured**: 2026-11-13 12:41:20 → 12:59:14 (+0530), from `D:/control`.
**Launcher**: `C:/Users/ASUS/AppData/Local/Pub/Cache/bin/fvm.bat` (FVM-pinned Flutter 3.44.6 / Dart 3.12.2).
**Agent 2 wrote nothing under version control.** Raw command output: `_scratch/p3_stage2/logs/*`.
Every `flutter test`/`build` run touched only `build/` and `.dart_tool/` (both gitignored —
verified: `git status --short` after all gates is byte-identical to the Snapshot B listing).

Two benign toolchain notices appear in every log and are **not** failures:
`Can't load Kernel binary: Invalid kernel binary format version (expected 125, found 130).` (fvm launcher
warm-up) and, on both apps' builds, the documented KGP deprecation warning for `firebase_auth, firebase_core`
(risk R-5 — reproduced, still a warning, build still succeeds).

---

## 1. Gate table

| # | Gate | Command (cwd) | Start → End (+0530) | Exit | Measured result | Verdict |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Child analyzer | `fvm flutter analyze` (`apps/haven_child`) | 12:41:20 → 12:43:23 | 0 | `No issues found! (ran in 103.8s)` | **PASS** |
| 2 | Parent analyzer | `fvm flutter analyze` (`apps/haven_app`) | 12:43:23 → 12:44:36 | 0 | `No issues found! (ran in 49.8s)` | **PASS** |
| 3 | Child FULL suite | `fvm flutter test` (`apps/haven_child`) | 12:45:03 → 12:45:57 | 0 | `00:31 +251: All tests passed!` — 251 passed, **0 failed, 0 skipped** | **PASS** |
| 4 | Parent FULL suite | `fvm flutter test` (`apps/haven_app`) | 12:45:58 → 12:48:27 | 0 | `02:00 +943: All tests passed!` — 943 passed, **0 failed, 0 skipped** | **PASS** |
| 5a | `haven_api` | `fvm flutter test` (`packages/haven_api`) | 12:48:28 → 12:48:49 | 0 | `00:03 +66: All tests passed!` | **PASS (66 = protected 66, exact)** |
| 5b | `haven_core` | `fvm flutter test` (`packages/haven_core`) | 12:48:50 → 12:49:07 | 0 | `00:00 +18: All tests passed!` | **PASS (18 = protected 18, exact)** |
| 5c | `haven_models` | `fvm flutter test` (`packages/haven_models`) | 12:49:08 → 12:49:27 | 0 | `00:00 +12: All tests passed!` | **PASS (12 = protected 12, exact)** |
| 6 | Line-count gate | `dart scripts/check_line_counts.dart` (`D:/control`) | 12:44:36 → 12:44:41 | 0 | `line-count rule: max 200 lines per source file` / `hand-written source files scanned: 740` / `violations: 0` | **PASS (0 violations; 740 files)** |
| 7 | Child debug APK | `fvm flutter build apk --debug` (`apps/haven_child`) | 12:49:20 → 12:51:50 | 0 | `Running Gradle task 'assembleDebug'... 131.4s` · `√ Built build\app\outputs\flutter-apk\app-debug.apk` · artifact `apps/haven_child/build/app/outputs/flutter-apk/app-debug.apk` **162,458,160 B** at **2026-11-13 12:51:42.297** · sha256 `ae671f4e41431f8ba3c94ac5e7d0bedc8429963c4601e4b9d7290db59b1847ae` | **PASS** |
| 8 | Parent debug APK | `fvm flutter build apk --debug` (`apps/haven_app`) | 12:52:56 → 12:54:31 | 0 | `√ Built build\app\outputs\flutter-apk\app-debug.apk` · artifact `apps/haven_app/build/app/outputs/flutter-apk/app-debug.apk` **190,567,905 B** at **2026-11-13 12:54:24.585** · sha256 `8645266a174dbe1d0100e146e1a5a3624c30443040422be8a8eaa6b5b9fc3ac9` | **PASS** |
| 9 | Post-build child MERGED manifest re-read | `ls -la --time-style=full-iso` + `grep` on `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml` | 12:51:50 (inside gate 7 batch) | 0 | see §3 — **file was NOT rewritten by the build** (mtime still 2026-11-06 12:23:57); permissions unchanged | **PASS with recorded caveat** |

No gate failed. No gate was re-run more than once (each ran exactly once; no retries, no source fixes).
Total Dart tests measured across all five suites: **251 + 943 + 66 + 18 + 12 = 1,290 passed / 0 failed / 0 skipped**.

---

## 2. Protected-baseline comparison (STEP 4)

| Suite | Protected / baseline | Measured now | Δ | Interpretation (measured, not assumed) |
| :-- | :-- | :-- | :-- | :-- |
| `apps/haven_app` | **924** | **943** | **+19** | Growth only. The three new untracked files alone account for it: `fvm flutter test test/device_pairing/demo_capability_labelling_test.dart test/device_pairing/pairing_simulation_regression_test.dart test/permissions/cross_language_key_agreement_test.dart` → `+19: All tests passed!` (log `parent_new_tests.log`, exit 0). 943 − 19 = **924 exactly**: no protected test lost, none skipped, none edited (`git status` shows no ` M` under `apps/haven_app/test`; only 3 `??` files). |
| `packages/haven_api` | 66 | 66 | 0 | Exact |
| `packages/haven_core` | 18 | 18 | 0 | Exact (`packages/` has an empty `git diff` and empty `git status`) |
| `packages/haven_models` | 12 | 12 | 0 | Exact |
| **Protected 1,020** | 924+66+18+12 | 943+66+18+12 = **1,039** | **+19, zero variance inside the protected set** | PASS |
| `apps/haven_child` | 167 (Stage-1 baseline) | **251** | **+84** | Growth only, and accounted for by suite: Stage-2 new child suites (`test/registration`, `test/native`) alone → `+84: All tests passed!`; the Stage-1-era child suites re-counted separately → `test/app test/features test/narrow test/widget_test.dart test/support` = `+110` and `test/architecture test/core` = `+57`; **110 + 57 = 167 = the exact Stage-1 baseline**, and 167 + 84 = 251. So nothing was lost or silently skipped (logs `child_suite_breakdown.log`). |
| Repo-wide | coordination brief expected **1,187** | **1,290** | **+103** | The 1,187 figure assumed the child suite stays at 167 and the parent at 924. Variance = 84 new child tests + 19 new parent tests = 103. This is expected Stage-2 growth, **not** a regression: regressions are failures or lost tests, and there were **0 failures, 0 skips, 0 lost tests** in every suite. |

**Line-count growth accounting**: 740 scanned vs 704 at Snapshot A = **+36**, exactly the number of new
Stage-2 `.dart` files created today (33 under `apps/haven_child/lib|test/features|test/native|test/registration`
plus the 3 new parent test files); the 4 modified parent widgets were already counted. No existing file
crossed 200 lines — `demo_registration_service.dart` sits at exactly **200** (at the limit, not over it:
`scripts/check_line_counts.dart` rule is `maxLines = 200`), and it, `demo_code_lane.dart` and
`demo_registration_journal.dart` exist precisely because the lane split a larger service under that rule.

**APK size comparison** (recorded baseline vs now):

| Artifact | Baseline recorded pre-implementation | Pre-Agent-2 on disk | Agent 2 rebuild (12:51 / 12:54) | Note |
| :-- | :-- | :-- | :-- | :-- |
| child `app-debug.apk` | 162,458,160 B | 162,458,160 B (12:49 mtime 10:23:09) | **162,458,160 B**, sha256 `ae671f4e…47ae` | **Byte-identical** to the artifact hashed in `docs/testing/evidence/real_device_2026_11_13/child/apk_sha256.txt` (`ae671f4e…47ae`). Measured proof that the Stage-2 child code is not linked into the app binary: nothing in `lib/features/registration` or `lib/core/native` is reachable from `main.dart` (no route, no binding call) — consistent with the contracts-only scope. |
| parent `app-debug.apk` | 190,571,206 B | 190,566,532 B (10:22:06) | **190,567,905 B**, sha256 `8645266a…3ac9` | Differs from the recorded Stage-1 figure by −3,301 B. Expected: the 4 parent widget files changed (added DEMO label strings). Also **not byte-reproducible** — the 10:22 build (190,566,532 B / sha `31f00114…`) differs from my 12:54 build of the same tree, i.e. debug APK bytes/timestamps vary per run, so size deltas below ~5 KB are not by themselves evidence of a code change; the sha256 pair above is what to compare. |

---

## 3. GATE 9 — child merged debug manifest, re-read after the rebuild (for Agent 3)

**Path**: `D:/control/apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`
**Size**: 15,374 B · **mtime**: `2026-11-06 12:23:57.240661500 +0530`
`package="com.haven.child"` · `android:minSdkVersion="24"` · `android:targetSdkVersion="36"` (lines 7-9)

`uses-permission` entries, verbatim with line numbers:

```
11    <uses-permission android:name="android.permission.INTERNET" />
12    <uses-permission android:name="android.permission.WAKE_LOCK" />
13    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" /> <!-- Permissions options for the `notification` group -->
14    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" /> <!-- Required by older versions of Google Play services to create IID tokens -->
15    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
16    <uses-permission android:name="com.google.android.providers.gsf.permission.READ_GSERVICES" />
22    <uses-permission android:name="com.haven.child.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />
```

Also: `uses-feature` count in the merged file = **0**; no `<queries>` block; no
`FOREGROUND_SERVICE`; no `QUERY_ALL_PACKAGES`; no `PACKAGE_USAGE_STATS`.

**Recorded caveat (does not invalidate the reading)**: the build did **not** regenerate this file —
Gradle reported `processDebugMainManifest` up-to-date, so its mtime still predates Stage 2.
Agent 2 therefore verified that the artifact is still current by input staleness instead: **every** Android
input of the child is older than the merged manifest — newest non-cache files under
`apps/haven_child/android` (excluding `.gradle/`): `local.properties` 2026-11-06 12:22:01,
`app/src/main/AndroidManifest.xml` 09:46:30, `app/src/debug/AndroidManifest.xml` 09:46:30,
`app/src/profile/AndroidManifest.xml` 09:46:31, `app/build.gradle.kts` 09:46:16; no `pubspec.yaml` /
`pubspec.lock` / `*.gradle.kts` in either app or in `packages/` has an mtime of 2026-11-13
(verified with `find … -printf '%T+'` and with `git diff -- '*pubspec.yaml' '*pubspec.lock'` = empty).
So the 7-permission merged list above **is** what today's gate-7 APK was assembled from.
The parent's merged debug manifest was likewise not rewritten
(`apps/haven_app/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`,
16,710 B, mtime 2026-11-04 13:48:50) and declares `INTERNET` `:15`, `ACCESS_NETWORK_STATE` `:31`,
`WAKE_LOCK` `:32`, `POST_NOTIFICATIONS` `:33`, `c2dm.permission.RECEIVE` `:34`,
`READ_GSERVICES` `:35`, `com.haven.haven_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` `:41`.

---

## 4. Gate-by-gate log files

| Log | Contents |
| :-- | :-- |
| `_scratch/p3_stage2/logs/analyze_snapshotB.log` | gates 1, 2, 6 with commands, start/end stamps, exit codes |
| `_scratch/p3_stage2/logs/tests_gates.log` | gates 3, 4, 5a-c orchestration transcript (exit codes + tails) |
| `_scratch/p3_stage2/logs/child_test_raw.txt` (251), `parent_test_raw.txt` (943), `haven_api_test_raw.txt` (66), `haven_core_test_raw.txt` (18), `haven_models_test_raw.txt` (12) | full per-test output of each suite |
| `_scratch/p3_stage2/logs/child_build.log` / `parent_build.log` | gates 7, 8 + the merged-manifest re-read (gate 9) |
| `_scratch/p3_stage2/logs/child_suite_breakdown.log` | Stage-2-only (84) and Stage-1-era (110 + 57) child re-counts |
| `_scratch/p3_stage2/logs/parent_new_tests.log` | the 3 new parent files in isolation (19) |
