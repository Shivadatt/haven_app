# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 1 AUDIT REPORT

**Scope**: Final audit of Phase 3 Stage 1 (Child Companion foundation) — §12 fourteen-item response, five-way verdict, disclosed incidents, working-tree comparison, contamination scan
**Date**: November 6, 2026
**Auditor**: final Wave-B documentation agent (read-only verification: `git status`/`git diff`, `fvm flutter analyze`, `fvm flutter test`, `dart scripts/check_line_counts.dart`, `ls`, `find`, `grep`; no source, test or git mutation)
**Overall verdict**: **COMPLETE WITH LIMITATIONS** — the child app foundation is real, tested and compiles to an APK; nothing above ladder level 2 is claimed

---

## Part A — §12 Fourteen-Item Final Response

### 1. What Stage 1 was and what was delivered

Brief Module A: a second Flutter application (`apps/haven_child`) with its own Android identity, scaffold, theme, shared components, routes, onboarding, profile home, device-information screen, permission dashboard and local persistence — plus a child test suite, the unchanged Phase 1/2 regression, and a child debug APK. All delivered at ladder level 2. Companion docs: [implementation report](file:///d:/control/docs/implementation/phase_3/STAGE_1_IMPLEMENTATION_REPORT.md), [architecture](file:///d:/control/docs/implementation/phase_3/CHILD_APP_ARCHITECTURE.md), [onboarding](file:///d:/control/docs/implementation/phase_3/CHILD_ONBOARDING_FLOW.md), [storage](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md), [permissions](file:///d:/control/docs/implementation/phase_3/CHILD_PERMISSION_DASHBOARD.md), [feature matrix](file:///d:/control/docs/implementation/phase_3/STAGE_1_FEATURE_MATRIX.md), [test results](file:///d:/control/docs/implementation/phase_3/STAGE_1_TEST_RESULTS.md), [known limitations](file:///d:/control/docs/implementation/phase_3/STAGE_1_KNOWN_LIMITATIONS.md).

### 2. Repository and git state

| Item | Evidence |
| :--- | :--- |
| Branch | `main` |
| HEAD | `8e50da06982c495a20407a505235f230de1720f2` — identical to the Stage-0 baseline; **no agent committed anything** (`git rev-parse HEAD`, re-checked by this auditor) |
| Mutating git commands run by this auditor | none (only `status`, `diff`, `log`, `ls-files`, `check-ignore`, `rev-parse`) |
| Working tree | see Part C |

### 3. Files created (counts verified on disk)

| Area | Count | Lines |
| :--- | :--- | :--- |
| `apps/haven_child/lib/**` | 58 Dart files | 3,342 |
| `apps/haven_child/test/**` | 29 Dart files (24 `*_test.dart`) | 3,450 |
| `apps/haven_child/android/**` | 1 Kotlin (5 lines) + 3 manifests + 4 Gradle scripts + resources | — |
| Other app root | `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `README.md` | — |
| Files under `apps/haven_child/` in the git index | 112 (all additions; the app is entirely new) | — |
| New docs | 9 in `docs/implementation/phase_3/` (8 Stage-1 deliverables + this audit) | see Part D |

### 4. Architecture decisions and deviations

- Feature directories are route-aligned (`splash`, `onboarding`, `profile`, `device`, `permissions`) rather than the master-plan names (`child_onboarding`, `child_status`, …) — deviation recorded with its reason in [architecture §6](file:///d:/control/docs/implementation/phase_3/CHILD_APP_ARCHITECTURE.md).
- Child-owned theme/components/route tables instead of importing the parent app (contract forbids `haven_app` imports; an architecture test enforces it).
- Seams everywhere: `DeviceInformation`, `PermissionStatusSource`, `ChildProfileRepository`, `OnboardingStateStore`, `ChildSessionStore`; controllers are constructor-injected, `onInit` loads, `onClose` disposes, `isClosed` guards after every await.
- Two-tier bindings mirroring the parent, with a documented rule that a **failed** storage open is not cached.

### 5. Android identity and build configuration (**D-1 / D-2 resolved**)

`applicationId` = `namespace` = `com.haven.child` ([build.gradle.kts:10,21](file:///d:/control/apps/haven_child/android/app/build.gradle.kts#L10)); `com.haven.familysafety` deliberately not reused (out-of-repo Capacitor artifact). Own Gradle project mirroring parent hardening: AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, Java 17, build output redirected into `apps/haven_child/build/`, `kotlin.incremental=false` for the cross-drive `relativeTo` failure mode. Manifests: **zero permissions** (even `INTERNET` absent in main/debug/profile), launcher `MainActivity` only, no receivers/services/`<queries>`/device-admin, no `google-services.json`, no secrets, `app_name` = "Haven Child". `ChildConfig.applicationId` is the single source the UI displays and a test asserts the Gradle file carries it.

### 6. Local storage contract

Reuses `haven_api`'s offline engine (`FileLocalStore` → `haven_local.json` in the child's own sandbox, `{schemaVersion: 1, tables: {profiles: [one child row]}}`) rather than inventing a competing abstraction; adds one documented non-sensitive top-level key `childLocalState` for `{session, onboarding}` because no suitable table exists in the 19-table registry. Create-once (`child_profile_create_once`) + role guard (`child_profile_role_mismatch`); corrupt → typed `StorageFailure` `local_database_corrupt`, **never** auto-reset (developer exit only, via `ChildDataResetter.clearAll(verifyReadableFirst: false)`); `LocalUserAuth` untouched, child identity via `ChildLocalSession` + `ProfileRole.child` + "Parent connection: Not connected". Full contract: [CHILD_LOCAL_STORAGE_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md).

### 7. Onboarding flow

Five steps (welcome → about-you → device review → permissions intro → all set) driven by a pure state machine (`OnboardingFlow`), resumable through the persisted draft (`step_index` clamped), gated by `haven_core.validateDisplayName` + the age-bracket rule, and completed by exactly one profile write with three independent duplicate guards. 52 dedicated tests + 4 app-flow tests.

### 8. Device-information screen

Six ordered rows: Model → `Unavailable`, Manufacturer → `Unavailable`, Android version → real pure-Dart read (`Platform.operatingSystemVersion`) or `Unavailable` off-device, App version → `ChildConfig.appVersion`, App id → `com.haven.child`, Registration → `Not registered`, plus two honest footnotes and the explicit line "This screen has no buttons that pretend to work". No channel was added; **D-4 stays open on purpose**.

### 9. Permission dashboard

Four categories, one `blocked(...)`-per-category source (`UnconfiguredPermissionStatusSource`), cards rendering `Unavailable — not yet implemented on this device build` with tone `blocked`, a disabled `Open device settings` action plus its own explanation, `User action required: No`, and the page-level `No permission has been requested.` The `Ok`-only path to "Granted" is asserted by tests, so a permission can never look granted from a UI alone.

### 10. Lifecycle, loading, error, empty, retry

`ChildStateView<T>` is the only state arbiter (typed `Result` path + plain-message path; `BlockedFailure` renders `ChildBlockedNotice`; non-retryable failures render no "Try again"). Splash covers booting/failed/corrupt+reset/reset-failed; onboarding covers draft-loading, save-failure truth and a working retry; profile distinguishes empty-but-actionable from refused; app lifecycle uses `GetxController` conventions with `isClosed` guards and a documented `Get.reset` + explicit unregister sequence for tests.

### 11. Tests written

167 child tests (106 unit + 61 widget) across `app/`, `architecture/`, `core/{device,permissions,storage}`, `features/*`, `narrow/`, `support/`; hand-written fakes only (no mocking package); drivers per flow (`OnboardingDriver`, `controller_harness.dart`); real theme + real route table in widget tests; real temp-directory filesystem for storage tests; `runAsync`/`settleIo` for `dart:io`. Coverage map in [STAGE_1_TEST_RESULTS.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_TEST_RESULTS.md) §4. Zero skips, zero deleted or weakened assertions; one test-file compile error (`ensureVisible` alignment) was corrected to `Scrollable.ensureVisible`.

### 12. Gate results

| Gate | Exit | Result |
| :--- | :--- | :--- |
| child `fvm flutter test` | 0 | 167/167 `All tests passed!` (auditor re-ran: 167/167 again) |
| `haven_app` / `haven_api` / `haven_core` / `haven_models` | 0 each | 924 / 66 / 18 / 12 = **1,020/1,020**, zero variance, no reruns |
| root `fvm flutter analyze` | 0 | `No issues found!` (auditor re-ran: `No issues found! (ran in 10.4s)`) |
| `dart scripts/check_line_counts.dart` | 0 | **704 files, 0 violations** (auditor re-ran: identical) |
| child `pub get` / `build apk --debug` | 0 / 0 | APK `162,458,160` bytes, Gradle 199.8s |

No-double-count note: 167 is child-only and separate from the protected 1,020; the repo-wide sum is 1,187 and is never used as the baseline figure.

### 13. Incidents disclosed

See Part E — the nested `git init` (contract §6 breach, reverted) and the test agent's 150-turn-limit termination (continued by a scoped agent). Plus one verification finding this auditor made about the index state (Part C.3).

### 14. Residual risks, open decisions, next action

See Part F. **D-3, D-4, D-5 remain OPEN**; Stage 2 must not start without its brief and those gates.

---

## Part B — Five-Way Verdict

| Item | Verdict | Evidence |
| :--- | :--- | :--- |
| App scaffold, routes, bindings, DI | **COMPLETE** | 6 routes incl. unknown; `child_app_flow_test.dart` 4, `child_architecture_test.dart` 8, `child_initial_bindings_test.dart` 6 |
| Android project config + `com.haven.child` identity (D-1, D-2) | **COMPLETE** | `android/` tree; zero permissions in all 3 manifests; APK exit 0; architecture test asserts the id |
| Five-step onboarding (incl. resume + double-submit defence) | **COMPLETE** (as Stage 1) | 52 + 4 tests; `OnboardingFlow` pure rules; draft persistence proven by restart tests |
| Profile storage + create-once + role guard | **COMPLETE** | 11 repository + 5 completion-service tests; typed details `child_profile_create_once`, `child_profile_role_mismatch` |
| Device-information screen | **COMPLETE** with honest `Unavailable` fields | 6 + 9 tests; nulls asserted, never guessed |
| Permission dashboard | **COMPLETE as ex-specified** (explanatory, all-`blocked()`) | 7 + 5 + 7 + 1 tests; `UnconfiguredPermissionStatusSource`; disabled action + note |
| Local storage contract (engine reuse + `childLocalState`) | **COMPLETE** | 33 storage tests incl. coexistence, malformed recovery, newer-schema refusal |
| Lifecycle / loading / error / empty / retry states | **COMPLETE** | `ChildStateView` + splash/onboarding/profile/permission state tests |
| Automated tests for the child lane | **COMPLETE** — 167/167 | §12 item 11/12; two independent clean runs |
| Child debug APK build | **COMPLETE** (compile only) | `BUILD_EXIT:0`, `√ Built …app-debug.apk`, 162,458,160 bytes verified with `ls -la` |
| Phase 1/2 preservation | **COMPLETE** — 1,020/1,020 | `_scratch/p3_stage1/regression/` logs; `git status` shows no parent/package edits |
| Device model / manufacturer real values | **PARTIAL (by-design fallback)** | pure-Dart nulls → `Unavailable`; needs the Kotlin lane |
| Profile editing UI | **PARTIAL** | repository `update` implemented + tested; **no edit screen ships** |
| `ChildConfig.appVersion` ↔ pubspec sync | **PARTIAL** | both `0.1.0`, kept in sync by hand; no assertion test yet |
| Cloud-dependency-free child APK | **PARTIAL** | declared deps and code are clean (test-enforced); `firebase_auth`/`firebase_core` leak **transitively** via `haven_api` |
| Real parent↔child pairing / registration | **BLOCKED** | D-5 / master-plan B-1 — no backend, no approved same-device rendezvous |
| Native permission status reads (usage/location/notifications/background) | **BLOCKED** for real values | needs the Stage-2+ Kotlin channel (`PermissionStatusSource` has no `Ok` path today); D-4 open |
| Physical-device verification (RMX2161 / any device) | **BLOCKED** | none attached (B-3, P-1) — cannot be evidenced at all |
| Emulator launch / install behaviour | **NOT TESTED** | not attempted in Stage 1; `Pixel_9a` exists but was never used |
| `--release` build, signing, Play posture | **NOT TESTED** | out of Stage-1 scope |
| Kotlin unit tests (Robolectric/junit) | **NOT TESTED** | infrastructure (P-5) still absent; no meaningful Kotlin to test |
| Monitoring, policy evaluation, enforcement, location, background, child dashboard, parent contracts, device matrix | **DEFERRED** | brief §5 / master plan Stages 3–10 |

---

## Part C — Working-Tree Comparison vs the Stage-0 Baseline

Commands run read-only: `git -C D:/control status --porcelain`, `git -C D:/control diff --stat`, plus `git rev-parse HEAD`, `git ls-files`, `git check-ignore -v`.

1. **`git diff --stat` measured twice.** Before this auditor wrote any file: **empty output** — zero unstaged modifications, i.e. nothing in `apps/haven_app/`, `packages/`, `android_native/` or the Phase 1/2 docs differed from the index. After this auditor's own minimal `PHASE_3_MASTER_PLAN.md` status edits it reports exactly one file — `docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md | 20 ++++++++++----------` (`1 file changed, 10 insertions(+), 10 deletions(-)`) — which is this audit's only tracked-file modification, plus Git's Windows line-ending advisory (`LF will be replaced by CRLF`) on that file. No source or test file is modified in either reading.
2. **`git status --porcelain` → 139 entries before this doc agent wrote, 148 after** (9 new Phase-3 docs land as `??`, and the edited master plan flips from `A ` to `AM`). Breakdown of the pre-existing 139:

| Shape | Count | Contents |
| :--- | :--- | :--- |
| `A ` (staged additions) | **132** | 112 × `apps/haven_child/**` · 2 × `docs/implementation/phase_3/{PHASE_3_MASTER_PLAN,STAGE_0_INSPECTION_VERIFICATION}.md` · 17 × `_scratch/**` (15 × `_scratch/p3_inspect/agent_git/*.txt` + 2 pre-existing Phase-2 ones) · 1 × `docs/implementation/phase_2/FINAL_VERIFICATION_REPORT.md` |
| `M ` (staged modifications) | **7** | only the Phase 2 sign-off docs: `DEFERRED_FUNCTIONALITIES`, `KNOWN_LIMITATIONS`, `LOCAL_WORKFLOW_REPORT`, `PHASE_2_FEATURE_MATRIX`, `PHASE_2_IMPLEMENTATION_REPORT`, `SCREEN_IMPLEMENTATION_REPORT`, `TEST_RESULTS` |
| `??` (untracked) | 0 → **9** | the Stage-1 docs written by this agent (8 deliverables + this report); `PHASE_3_MASTER_PLAN.md` additionally flips to `AM` after its status edits |

Index-vs-HEAD summary (`git diff --cached --stat`, measured before this agent's writes): `139 files changed, 8764 insertions(+), 16 deletions(-)` — and **every** insertion/deletion pair outside `apps/haven_child/` and the docs belongs to `_scratch/` evidence files.
3. **Delta vs Stage 0's own description, and the one surprise.** Stage 0 §1 described the tree as "7 modified files under `docs/implementation/phase_2/`, untracked `FINAL_VERIFICATION_REPORT.md`, 2 staged `_scratch/` evidence files", i.e. **unstaged/modified** and **untracked** shapes. Today those same items read as `M ` and `A `, and the 112 child-app files plus 15 more `_scratch` files are also `A ` rather than the expected `??` untracked. Consequence for step 9's expectation: the child app is **not** "untracked as a whole" — it is **staged as a whole**. Nothing was committed (HEAD unchanged), so the repository's history is untouched and no claim is overstated, but the *index* was written to at some point during Phase 2/3 agent activity, which `00-app-contract.md` §6 ("No git operations (commit/push/reset/clean/rebase)") does not literally enumerate and which this auditor did **not** perform or reverse. Flagged as a compliance observation for the owner: the owner should decide whether to `git reset` the index before committing Phase 3 work.
4. **Surprise check against the brief's expectations**: (a) expected — new `apps/haven_child/**`, new `docs/implementation/phase_3/**`, zero modifications to `apps/haven_app`/`packages` (**confirmed: 0 entries**); (b) unexpected — the staged-not-untracked shape above; (c) expected-and-confirmed — the splash bug fix needed no separate trace: `apps/haven_child/lib/features/splash/views/pages/splash_page.dart` is a brand-new staged file containing the fixed logic, so the fix ships as part of the whole untracked-or-staged app; (d) not a surprise but recorded — `_scratch/` is still not gitignored, so the 17 staged `_scratch` evidence files remain a Phase-2-era hygiene issue.

---

## Part D — Deliverable Inventory (this audit's own output)

| Document | Purpose |
| :--- | :--- |
| [STAGE_1_IMPLEMENTATION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_IMPLEMENTATION_REPORT.md) | pipeline, inventory, gates, build, incidents, contract compliance |
| [CHILD_APP_ARCHITECTURE.md](file:///d:/control/docs/implementation/phase_3/CHILD_APP_ARCHITECTURE.md) | layering, DI, routes, seams, UI system, deviations, invariants |
| [CHILD_ONBOARDING_FLOW.md](file:///d:/control/docs/implementation/phase_3/CHILD_ONBOARDING_FLOW.md) | boot decision, five steps, gates, resume, completion, copy |
| [CHILD_LOCAL_STORAGE_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md) | reuse decision, document shape, additive key, integrity, corruption |
| [CHILD_PERMISSION_DASHBOARD.md](file:///d:/control/docs/implementation/phase_3/CHILD_PERMISSION_DASHBOARD.md) | four categories, seam, blocked mapping, rendering rules, Stage-2+ needs |
| [STAGE_1_FEATURE_MATRIX.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_FEATURE_MATRIX.md) | 24 rows across the six-level ladder |
| [STAGE_1_TEST_RESULTS.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_TEST_RESULTS.md) | commands + exits + counts, coverage map, not-tested list |
| [STAGE_1_KNOWN_LIMITATIONS.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_KNOWN_LIMITATIONS.md) | 11 limitation rows incl. the cloud-dep leak |
| this report | final response, verdicts, incidents, tree + contamination scan |

`PHASE_3_MASTER_PLAN.md` received minimal edits only (10 insertions / 10 deletions): its **Status** header line now points at Stage 1 complete-with-limitations, §2 marks D-1/D-2 **RESOLVED** and D-3/D-4/D-5 **OPEN**, §4's Stage-1 row carries the completion marker with its gate numbers, §6 lists the nine Stage-1 docs, and §8 names Stage 2 as the next gate. Nothing else in it changed.

---

## Part E — Disclosed Incidents

| # | Incident | Effect | Correction / disposition |
| :--- | :--- | :--- | :--- |
| 1 | The scaffold agent ran a stray **`git init` inside `apps/haven_child`**, creating a nested repository with **zero commits**. | Breach of `00-app-contract.md` §6 (no git operations). Root repo was never targeted. | Verified empty and **removed immediately**; root HEAD, index and refs unaffected (HEAD still `8e50da0`, `git ls-files apps/haven_child` resolves against the root repo). Self-reported by the agent and logged here as a violation, not as a near-miss. |
| 2 | The original **tests agent terminated at the 150-turn limit** mid-suite. | The stage would not have been certifiable on its own. | A scoped **continuation agent** finished the suite; no test was weakened, deleted or skipped (grep: zero `skip:` markers; 167 declared = 167 executed). Transient analyzer (11 → 15 issues) and line-count (687 files / 2 violations) reds produced **during** that parallel activity were correctly **not** used as evidence; the certified scans were taken only after quiescence, and this auditor re-ran both cleanly. |
| 3 | *(verification finding, this audit)* New files appear **staged** (`A `) rather than untracked (`??`), including 17 `_scratch` files and 112 child-app files. | Suggests a `git add` occurred in earlier agent activity. No history was altered; Phase 2/3 evidence integrity (tests, analyze, APK) is independent of the index state. | Reported in Part C.3 for the owner's decision. This auditor ran no staging command. |
| 4 | *(count-discipline reminder from Phase 2)* A prior-stage doc claim of "975+" had to be corrected to the exact 990. | — | Every count in this stage's docs is exact (167, 924, 66, 18, 12, 1,020, 1,187, 704, 162,458,160, 112, 58/29/24 files) and was re-derived from disk or from the preserved logs, not copied. |

---

## Part F — Residual Risks, Decisions and Next Action

| Risk / decision | State | Action |
| :--- | :--- | :--- |
| `firebase_auth`/`firebase_core` transitively in the child build; KGP deprecation will eventually break builds | **OPEN (highest value)** | split `haven_api` into offline vs cloud lanes **before Stage 3**; owner decision, shared-package change |
| D-3 pairing-code spec (simulation 5 min vs evidenced `CODE_TTL_MINUTES = 10`, `MAX_ATTEMPTS = 10`; `validatePairingCode`/`PairingCodeFormat` export) | **OPEN** | must be answered before Stage 2 Module B |
| D-4 channel typing (Pigeon vs hand-rolled `BridgeContract.kt` ↔ `channel_device_state.dart` precedent; a second channel already duplicates constants) | **OPEN** | Stage 2 must pick one and enforce it in tests; until then model/manufacturer stay `Unavailable` |
| D-5 same-device parent↔child exchange (per-app sandbox, two separate `haven_local.json`) | **OPEN** | label-only local exchange, or real pairing stays **BLOCKED → Phase 4 backend** |
| Kotlin test infrastructure (P-5 junit + Robolectric) absent | **OPEN** | prerequisite for any level-3 claim |
| No device (P-1 / B-3) | **OPEN** | every `DEVICE_VERIFICATION_MATRIX` row stays `NOT TESTED` until a handoff |
| 200-line rule pressure as the native lane grows (Stage 0 §8.7) | Watch | already honoured: longest child file 199 lines |
| Index/working-tree shape (Part C.3) | **Owner action** | the contract forbids agents from committing; staging reversal is likewise left to the owner |
| Phase 2 sign-off docs + Phase 3 docs uncommitted (B-5) | **Owner action** | commit is the owner's call, never an agent's |

**Next action**: Stage 1 is accepted as **COMPLETE WITH LIMITATIONS**. Stage 2 (registration contracts + capability inventory) has **not** started and must not start without its own brief **and** answers to D-3/D-4/D-5.

---

## Part G — Contamination and Scope-Hygiene Scan (step 10)

**Verdict: deliverable scope is clean.** Every command below was read-only and re-run by this auditor.

### G.1 Scope containment

| Check | Result |
| :--- | :--- |
| `git status --porcelain` entries under `apps/haven_app/` or `packages/` | **0** — parent app and shared packages untouched, so Phase 1/2 preservation holds (and is independently evidenced by 1,020/1,020, exit 0 each) |
| Stage-1 source scope | only `apps/haven_child/**` (112 index entries) + `docs/implementation/phase_3/**` |
| `android_native/`, `backend/`, `supabase/` | untouched — Stage 1 added no native or backend surface |

### G.2 Ignore coverage

| Path class | Matched rule (from `git check-ignore -v`) | Status |
| :--- | :--- | :--- |
| `apps/haven_child/build/**` (incl. the APK) | `apps/haven_child/.gitignore:33` → `/build/` (root `.gitignore` also has `build/` and `*.apk`) | **ignored** |
| `apps/haven_child/.dart_tool/**` | `apps/haven_child/.gitignore:29` → `.dart_tool/` | **ignored** |
| `apps/haven_child/.flutter-plugins-dependencies` | `apps/haven_child/.gitignore:30` | **ignored** |
| `apps/haven_child/.metadata` | `.gitignore:33` → `.metadata` | **ignored** |
| `apps/haven_child/android/local.properties` | `apps/haven_child/android/.gitignore:6` → `/local.properties` | **ignored** — note: the root rule `android/local.properties` does **not** reach nested app dirs, so this coverage comes from the app's own `android/.gitignore`, exactly as for the parent app |
| `android/gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, `GeneratedPluginRegistrant.java` | `apps/haven_child/android/.gitignore` lines 1–7 | **ignored** |
| `apps/haven_child/android/.gradle/`, `.kotlin/` | Flutter's `android/.gitignore` | **ignored** |

`apps/haven_child/.gitignore` and `apps/haven_child/android/.gitignore` **match the parent's patterns exactly** — `diff` against `apps/haven_app/.gitignore` and `apps/haven_app/android/.gitignore` reports **no differences** for either file. The android half also carries the keystore guards (`key.properties`, `**/*.keystore`, `**/*.jks`) and `/.gradle`, `/captures/`, `.cxx/`, so neither app can leak build output or signing material while the other does not.

### G.3 Secret scan

`find apps/haven_child -type f \( -iname 'google-services.json' -o -iname '*.keystore' -o -iname '*.jks' -o -iname '*.pem' -o -iname '*.p12' -o -iname '.env*' -o -iname 'service-account*' -o -iname '*firebase-adminsdk*' -o -iname 'keystore.properties' -o -iname 'signing.properties' -o -iname 'local.properties' \)`, build and tool caches excluded, returned **exactly one** file: `./android/local.properties` — a machine-local Android-SDK/Flutter-path file, **not** a credential, and ignore-covered. **No** `google-services.json`, keystore, `.env`, service-account or signing properties anywhere under `apps/haven_child/`. Release signing is still the template's debug-key placeholder, so no private key exists to leak. `find D:/control -name haven_local.json` → **no matches**: no runtime data document is committed or present in the tree.

### G.4 Scratch / telemetry / stray artifacts

| Check | Result |
| :--- | :--- |
| `find apps/haven_child -iname '*scratch*' -o -iname '*telemetry*'` | **empty** — no `_scratch` or telemetry file inside the child app |
| Stage-1 raw logs | live outside the app, under `_scratch/p3_stage1/{build,regression}/` (9 files) — the Phase 2-era `_scratch` hygiene issue (not gitignored; 17 staged evidence `.txt` files) is inherited, **not** worsened by the child app itself |
| Artifacts on disk but not in the index (7) | all generated + all ignore-covered (§G.2) — no hand-written file is untracked-but-missing from the index |
| Child APK | `162,458,160` bytes (**154.9 MiB**, the "155 MB" figure), present at `apps/haven_child/build/app/outputs/flutter-apk/app-debug.apk`, **ignore-covered**, never staged |

### G.5 Documentation hygiene

No Stage-1 doc claims a device result, a permission grant, a pairing, a monitoring or an enforcement capability. Every level-3+ row in the feature matrix is DEFERRED, BLOCKED or NOT TESTED, and the two disclosed incidents are recorded verbatim rather than summarized away.
