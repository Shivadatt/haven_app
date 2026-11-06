# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 INSPECTION REPORT

**Scope**: Stage 2 read-only inspection + decision proposals (Registration contracts + Android capability inventory)
**Date**: November 6, 2026
**Overall status**: **Stage 2 PREPARATION — COMPLETE. Stage 2 IMPLEMENTATION — NOT STARTED (BLOCKED pending D-3 / D-4 / D-5).**
**Governing contract**: [docs/implementation/00-app-contract.md](file:///d:/control/docs/implementation/00-app-contract.md) · Phase 3 plan: [PHASE_3_MASTER_PLAN.md](file:///d:/control/docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md) · Stage 1 verdict: [STAGE_1_AUDIT_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_AUDIT_REPORT.md)

---

## 1. Method

Five subagents were used, as instructed, in two phases so that nothing scanned while something else wrote:

| Agent | Type | Role | Writes |
| :--- | :--- | :--- | :--- |
| 1 | Explore (read-only) | governing contract + master plan + Stage 0/1 + the four CHILD_* docs | none |
| 2 | Explore (read-only) | D-3 pairing-code evidence (models, validators, backend, tests, storage) | none |
| 3 | Explore (read-only) | D-4 native channel + Kotlin test infrastructure | none |
| 4 | Explore (read-only) | capability inventory + D-5 sandbox/storage evidence | none — see §7 anomaly A-3 |
| 5 | general-purpose | baseline re-run: 5 suites, 5 analyzers, line-count rule, Deno backend, integrity hashes | temp scratch only, outside the repo |

Every decisive number and every "does not exist" claim was then re-verified **first-party** by the coordinator (`git`, `grep`, `sed`, direct test execution), not accepted from a subagent summary. Where a subagent's citation was wrong, it was corrected before publication (one path was fixed in §5 of the decision proposal; two line numbers corrected in the capability inventory).

## 2. Repository and Git state (recorded, unchanged by this task)

| Item | Value |
| :--- | :--- |
| Repository | `D:\control` (the HAVEN monorepo). The session's own working directory `D:\parentcontrol_app` is a **different** project and was not used for Stage 2 |
| Branch | `main` |
| HEAD | `8e50da06982c495a20407a505235f230de1720f2` — `docs: add phase 2 implementation reports, feature matrix, and workflow documentation` |
| Index mtime at first read | `2026-11-06 12:38:53.898953000 +0530` |
| Index mtime at last read | `2026-11-06 14:06:10.776958800 +0530` — **moved by an external process**, see anomaly A-1 |
| Staged entries | 131 `A ` + 7 `M ` + 1 `AM`, **139 paths** in `git diff --cached --name-only` — identical before and after this task |
| Untracked | 9 at first read → **18** at final read (`git status --porcelain \| grep -c '^??'`). The increase is the 7 documents this task created plus 2 created by a concurrent writer (anomalies A-3, A-8); the pre-existing 9 are the Stage 1 deliverables |
| Index mtime at final read | `2026-11-06 14:06:10.776959 +0530` — unchanged since the A-1 observation, i.e. no further index write occurred during documentation or validation |
| The `AM` entry | `docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md` (10 insertions / 10 deletions vs the index), pre-existing since `12:59:22` |
| Nested repositories | none — `find . -name .git -maxdepth 4` returns only `./.git`, so the Stage 1 nested-`git init` breach is confirmed cleaned |
| Git operations performed by this task | **none** other than read-only inspection. No add, stage, commit, push, reset, clean, checkout, restore, stash, rebase, merge or branch operation. No source or test file was modified |
| Lockfiles / `.fvmrc` | all five `pubspec.lock` files and `.fvmrc` byte-identical pre/post (sha256 verified by agent 5) |

## 3. Baseline verification — claimed versus actually re-run

All five figures below were re-executed in this session, not inherited. Commands used the repo-pinned SDK `/c/Users/ASUS/fvm/versions/3.44.6` (Flutter 3.44.6 / Dart 3.12.2); the PATH Flutter 3.38.8 was not used.

| Suite | Historical Stage 1 claim | **Actual re-run** | Delta | Command | Exit | Verbatim tally |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `apps/haven_app` | 924 | **924** | 0 | `flutter test --no-pub` | 0 | `01:36 +924: All tests passed!` |
| `packages/haven_api` | 66 | **66** | 0 | `flutter test --no-pub` | 0 | `00:03 +66: All tests passed!` |
| `packages/haven_core` | 18 | **18** | 0 | `dart test` | 0 | `00:00 +18: All tests passed!` |
| `packages/haven_models` | 12 | **12** | 0 | `dart test` | 0 | `00:00 +12: All tests passed!` |
| **Protected total** | **1,020** | **1,020** | **0** | — | — | — |
| `apps/haven_child` | 167 (106 unit + 61 widget) | **167** | 0 | `flutter test --no-pub` | 0 | `00:16 +167: All tests passed!` |
| Workspace analyzer | 0 issues | **0 issues** | 0 | `flutter analyze --no-pub` ×3, `dart analyze` ×2 | 0 | `No issues found!` in all five |
| Line-count rule | 704 files / 0 violations | **704 files / 0 violations** | 0 | `dart run scripts/check_line_counts.dart` | 0 | `hand-written source files scanned: 704 / violations: 0` |
| Skips | 0 | **0** | 0 | `grep -RIn 'skip:' <pkg>/test` | — | 0 occurrences in all five packages |
| Kotlin tests | 0 | **0** | — | `find` for `src/test`, `src/androidTest`, `*Test.kt` | — | **NOT TESTED** — no source set, no `testImplementation`, 12 `.kt` files all production |
| Backend Deno tests *(supplementary, not part of the 1,020)* | 82 (README) | **82** | 0 | `deno test --cached-only --allow-env --allow-read --no-prompt` | 0 | `ok \| 82 passed \| 0 failed (1s)` |

**Verdict: the Stage 1 baseline is preserved exactly.** Nothing was added, removed, weakened or skipped by this task; no APK was built and no device or emulator was launched.

The child 106/61 split could not be measured by separate execution because the suite is laid out by feature directory, not by unit-vs-widget; the static `testWidgets(` count (61) corroborates the recorded split. This is reported as **corroborated, not independently executed**.

## 4. What was inspected

| Area | Coverage |
| :--- | :--- |
| Governance docs | `00-app-contract.md`; all 12 files in `docs/implementation/phase_3/`; `phase_1/KNOWN_LIMITATIONS.md`, `REMAINING_KNOWN_ISSUES.md`, `IMPLEMENTED_FEATURE_MATRIX.md`; `docs/audit/**` pairing claims; `docs/stage1/08-test-matrix.md`; `docs/stage2/functions/**`, `docs/stage2/migrations/A3-staging-load-v1.sql` |
| Pairing/registration | `packages/haven_core/lib/src/{pairing_code,validation,clock,result,failures,blocked}.dart`; `packages/haven_models/lib/src/{pairing_models,enums_identity}.dart`; `apps/haven_app/lib/features/device_pairing/**` (7 files); `apps/haven_app/test/device_pairing/**` (6 files, 47 cases); `backend/supabase/functions/pairing/**` (6 files) + `_shared/{identifiers,validation,rate_limit,quotas}.ts`; `backend/supabase/tests/pairing_limits_test.ts` (11 cases); `haven_child/lib` (pairing grep) |
| Native channel | `android_native/child_services/**` (10 `.kt` files, all read); `apps/haven_app/lib/core/permissions/{channel_device_state,device_state_decoding,native_device_state,area_reading}.dart`; `apps/haven_app/test/permissions/channel_device_state_test.dart` (7 cases); both apps' Gradle files, `settings.gradle.kts`, `gradle.properties`, `local.properties`; all four manifests + device-admin XML; repo-wide Pigeon/FFI/EventChannel searches |
| Capability | 27 symbol absence checks across `apps`/`packages`/`android_native`/`backend`/`scripts`; five pubspec dependency tables; SDK/toolchain facts; storage code paths (`local_store`, `child_database`, `child_storage_paths`, `secure_vault`); UI connection-status strings in both apps |
| Environment | `scripts/check_line_counts.dart` (122 lines, read in full — it walks exactly 5 roots and 5 extensions, so `docs/` is never counted); `.fvmrc`; Deno version; absence of `fvm` on PATH |

## 5. Findings that contradict the Stage 2 brief's own premises

These are reported because §12 of the brief asks for what was actually found, not what was assumed.

| # | Brief premise | Repository reality | Where it is handled |
| :--- | :--- | :--- | :--- |
| F-1 | "Recommended: 6-digit numeric code, 10-minute expiry" | The backend generates **8 characters from a 30-symbol alphabet** and its redemption path rejects any other shape (`PAIRING_CODE_RE`, [redeem.ts:48](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L48)). The recommendation as written can never redeem | [STAGE_2_DECISION_PROPOSAL.md §2](file:///d:/control/docs/implementation/phase_3/STAGE_2_DECISION_PROPOSAL.md) |
| F-2 | "`MAX_ATTEMPTS = 10`" | The symbol is `MAX_ATTEMPTS_PER_CODE`; the per-token counter it gates is **never incremented by any code path** — verified across every `attempt` occurrence in `backend/supabase/functions/pairing/*.ts`. Real brute-force limiting comes from the window throttle (5/parent, 10/identifier per 10 min), which itself sits on a deliberately preserved read-then-act weakness | §2.2, blocker S2-04 |
| F-3 | "parent simulation: 6-digit code with 5-minute expiry" | True, and additionally: the Phase 1 matrix calls it "6-digit **alphanumeric**", and four audit documents claim **15 minutes** while citing a line that computes 10 | §2.1, blocker S2-03 |
| F-4 | "`HavenBridge.kt`" is treated as the child app's bridge | It is compiled into the **parent** app via `srcDir`; the child's only Kotlin file is a bare `FlutterActivity`, and the child uses no platform channel at all | §3.1, blocker S2-12 |
| F-5 | "`validatePairingCode` / `PairingCodeFormat` export status" to be checked | `pairing_code.dart` is **not in the barrel**, has **zero importers and zero tests**, and there is a *second*, exported `validatePairingCode` with a different signature in `validation.dart` | §2.1, blockers S2-10/S2-11 |
| F-6 | Two TTL values to reconcile | Normalisation also differs (Dart strips `' ' - — _`; backend strips `\s -`), the model default for `maxAttempts` is 1 where the DDL default is 10, and no local table exists for tokens or attempts | blockers S2-06/S2-07/S2-08 |
| F-7 | D-5 recommends UI must show `Not connected` unless verified | **Already true as shipped**: the child renders a constant `'Not connected'` and `'Not registered'`, and the parent labels `SIMULATED DEVICE`. The work is therefore *protection*, not construction | §4.1, tests T-18/T-19 |
| F-8 | The child app is cloud-free | True **as authored**, not **as built** — `haven_api` pulls firebase/supabase transitively, and the merged child manifest artifact carries `INTERNET`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `c2dm.RECEIVE` and Firebase registrars. Mitigations exist (no `google-services.json`, no `Firebase.initializeApp`, zero child network calls, "FCM is inert") | blocker S2-16 |
| F-9 | Injected `Clock` for deterministic tests | `Clock`/`FixedClock` exist and are exported, and **no pairing file uses them**; seven inline `DateTime.now()` sites and one ±5 s tolerance-band assertion | blocker S2-09 |

## 6. Deliverables produced

All in `docs/implementation/phase_3/`. Nothing outside this directory was written.

| File | Status |
| :--- | :--- |
| [STAGE_2_DECISION_PROPOSAL.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_DECISION_PROPOSAL.md) | **PROPOSED** — mandatory first deliverable; D-3/D-4/D-5 with approval fields |
| [ANDROID_CAPABILITY_INVENTORY.md](file:///d:/control/docs/implementation/phase_3/ANDROID_CAPABILITY_INVENTORY.md) | **COMPLETE** as an inventory; every capability row **NOT TESTED** |
| [PAIRING_REGISTRATION_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/PAIRING_REGISTRATION_CONTRACT.md) | **DRAFT** — pending D-3 / D-5 |
| [NATIVE_CHANNEL_CONTRACT.md](file:///d:/control/docs/implementation/phase_3/NATIVE_CHANNEL_CONTRACT.md) | **DRAFT** — pending D-4 / D-4a |
| [STAGE_2_TEST_STRATEGY.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_TEST_STRATEGY.md) | **PROPOSED** |
| [STAGE_2_BLOCKER_REGISTER.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_BLOCKER_REGISTER.md) | **COMPLETE** (living register) |
| [STAGE_2_INSPECTION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_INSPECTION_REPORT.md) | this document — **COMPLETE** |

## 7. Anomalies (disclosed, not repaired)

| ID | Anomaly | Evidence | Action taken |
| :--- | :--- | :--- | :--- |
| **A-1** | The Git index mtime moved during this task, from `12:38:53.898953000` to `14:06:10.776958800`, while HEAD, the staged classification (131/7/1), the staged path count (139) and all lockfile hashes stayed identical. A controlled test (read-only `git status` with `--no-optional-locks`, then re-reading the mtime) proved this task's own git reads do not write the index | `.git/index` stat; `git --no-optional-locks status/diff --cached` | **Left alone.** This is consistent with a benign stat-info refresh by some other process. Nothing was reverted, because reverting an index touch is itself a write |
| **A-2** | An unsolicited message inside this session asserted baseline figures that are **not reproducible** in this repository (haven_app 1080, haven_core 20, haven_models 35, child 170, total 1295, 735 files) and asserted that `D:\control` does not exist | Actual re-run: 924 / 18 / 12 / 66 / 167 = 1,020 + 167, 704 files, exit 0; `D:\control` present with HEAD `8e50da0` and 139 staged paths | **Rejected.** None of those numbers were adopted. Reported to the owner here |
| **A-3** | A **concurrent writer** created `docs/implementation/phase_3/STAGE_2_ANDROID_CAPABILITY_INVENTORY.md` at `14:19:59`, i.e. after the read-only agents finished and after this task's own correctly-named `ANDROID_CAPABILITY_INVENTORY.md` (14:12:29). Its own header says "Agent 4 of the Stage-2 readiness-only pass", which is not this task's naming and was not written by any agent launched here, all of which were instructed to write nothing | `ls -la --time-style=full-iso`; the file is untracked and was not authored by this task | **Left in place, not deleted and not merged.** It is another session's work product. The owner should decide which filename is canonical; the Stage 2 brief names `ANDROID_CAPABILITY_INVENTORY.md` |
| **A-4** | The brief's `haven_api` suite path is ambiguous and `dart test` does not accept `--no-pub` (exit 64, usage banner); `packages/haven_api` is a Flutter package and must be run with `flutter test --no-pub` | re-run transcript | Used the working commands; results in §3 |
| **A-5** | There is no root `pubspec.yaml`, so "workspace analyzer" cannot mean a single root invocation | `ls D:/control/pubspec.yaml` absent | Analyzer run per package; all five report `No issues found!` |
| **A-6** | `_scratch/` is still not gitignored, and 31 scratch files (including `.pyc` binaries) remain tracked — carried from Stage 0 hygiene findings | `STAGE_0_INSPECTION_VERIFICATION.md:19` | Not touched; this task's scratch lived outside the repository |
| **A-7** | `PHASE_3_MASTER_PLAN.md` has an unstaged modification (10/10) against its own staged version, predating this session | `git --no-optional-locks diff --stat` | Left untouched, per "do not attempt to repair previously staged changes automatically" |
| **A-8** | A **second** file from the same foreign session appeared while this task was validating: `docs/implementation/phase_3/STAGE_2_READINESS_AND_OWNER_DECISIONS.md` (37,159 B, mtime `14:26:36`, untracked). Its header self-identifies as "Agent 4, Phase 3 Stage 2 READINESS ONLY pass" and states it changed "nothing but these two documents" — i.e. it authored both A-3 and A-8. Its mtime advanced again during this check (14:24 → 14:26:36), so that session was still writing while this one was validating | `ls -la --time-style=+%H:%M:%S`; `git status --porcelain -- docs/implementation/phase_3` (both files `??`) | **Left in place, not read for validation, not deleted, not merged.** Content integrity of another session's files is not this task's to certify. Owner decision, same as A-3 |

### 7.1 Post-write consistency checks (this task's own seven documents)

Every `file:///d:/control/...` link in the seven documents was machine-checked (path exists, cited line range inside the file's real line count), together with markdown-table column consistency, malformed `#Lx-y` anchors, empty cells and H2/line counts. Two defects were found and fixed; nothing else changed:

| Check | Before | After |
| :--- | :--- | :--- |
| Broken link paths | 1 — the FCM ask-site was cited under `apps/haven_app/lib/features/remote_sessions/services/`; the real file is `packages/haven_api/lib/src/push_transport_impl.dart:91` | **0** in all seven |
| Anchors out of range / malformed (hyphen-compressed ranges written without the second `L`) | 0 / 0 | **0 / 0** |
| Tables with inconsistent column counts | 3 — one cell held raw `` `ok \| 82 passed \| 0 failed (1s)` `` (an unescaped pipe that would have split the row); the other two were already correctly escaped `\|` cells and are false positives of the counting method | **0** |
| Rows with an empty cell | 0 | **0** |
| Link labels | 8 links rendered as bare `[#L33]` with no file context | rewritten as `[MonitoringStateReader.kt:33]` etc. |
| Line-count rule re-run after these edits (`.md` is outside the script's scope, so this is a no-drift confirmation) | 704 files / 0 violations | **704 files / 0 violations** (exit 0) |

## 8. Status against the six-level ladder

| Level | Stage 2 position |
| :--- | :--- |
| 1 — UI | unchanged from Stage 1; no UI was modified |
| 2 — Flutter logic | **NOT STARTED** for Stage 2 contracts (blocked on D-3/D-5) |
| 3 — Kotlin/native | lane exists in the **parent** only; child has none; **NOT TESTED** (no runner, no deps, P-5 open) |
| 4 — Permission granted | **NOT TESTED** — no permission has ever been granted to a running build here |
| 5 — Physical-device verified | **BLOCKED** (P-1/B-3, no device attached) |
| 6 — Parent-child E2E verified | **BLOCKED** (B-1, no transport; D-5 open) |

No module was promoted. No claim is made here of real pairing, cross-device synchronization, permission grants, usage monitoring, location monitoring, app enforcement, or background reliability.

## 9. Owner decisions required to proceed

| Gate | Question | Blocking what |
| :--- | :--- | :--- |
| **D-3** | Which pairing-code option — A (brief as written) / B (backend-aligned) / **C (two named lanes, recommended)** / D (defer)? TTL, attempt ceiling, single-use, normalisation, `PairingCodeFormat` export, and whether the lenient `validatePairingCode` may be retired (breaking) | the entire registration state machine, redemption semantics, and every contract test that asserts a number |
| **D-4** | Pigeon (A) vs hand-written typed contract + drift test (**B, recommended**) vs status quo (C); plus **D-4a** lane ownership (parent = recommended for Stage 2, or child); plus whether `contractVersion`/timeout are added now; plus whether Kotlin test dependencies (P-5) are approved | channel typing, the drift test, and whether *any* Kotlin statement can ever rise above NOT TESTED |
| **D-5** | Confirm real cross-device pairing stays **BLOCKED** to Phase 4 (recommended) or approve a specifically named same-device transport; whether `blocked_pending_transport` becomes a state; whether local audit records may be written and under what label; whether the `haven_api` offline/cloud split is authorized | whether the child app may claim anything about a parent link, and whether isolation claims can be stated without the "as authored ≠ as built" caveat |
| Adjacent | Whether Phase 1/2 test files may be edited (T-01 rename, simulation model replacement); whether audit documents with 15-minute claims get an in-place correction or a superseding addendum; whether the concurrent `STAGE_2_ANDROID_CAPABILITY_INVENTORY.md` (A-3) is kept, merged or removed; when the 139 staged paths are committed (B-5/P-8) | scope and evidence hygiene |

## 10. Stop condition

Per §4 and §11 of the Stage 2 brief, work stops here. No decision-dependent behavior was implemented: no TTL changed, no attempt limit changed, no validator exported, no parent simulation behavior altered, no redemption implemented, no cross-device communication added, no MethodChannel/EventChannel added, no Android permission added, and no usage monitoring, location monitoring, background service or enforcement implemented. Stage 3 was not started.

**STOPPED — awaiting explicit owner approval of D-3, D-4 and D-5.**
