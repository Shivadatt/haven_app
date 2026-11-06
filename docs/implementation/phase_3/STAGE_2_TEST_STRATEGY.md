# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 TEST STRATEGY

**Scope**: How Stage 2's registration/pairing contracts and the native-channel contract will be proven
**Date**: November 6, 2026
**Status**: **PROPOSED.** The scenario designs below are non-binding; the assertions that depend on a numeric code spec depend on **D-3**, the assertions that depend on transport depend on **D-5**, and everything on the Kotlin side depends on **D-4 / P-5**.
**Rule honored**: no test is written that asserts behavior the owner has not approved; where the number is undecided, the test is written against a **named constant**, so it becomes meaningful the moment the decision is signed.

---

## 1. What can actually execute in this environment

| Runner | Command | Status | Evidence |
| :--- | :--- | :--- | :--- |
| Flutter (3 apps + `haven_api`) | `flutter test --no-pub` with `/c/Users/ASUS/fvm/versions/3.44.6/bin` | **AVAILABLE** | re-executed this session: haven_app 924, haven_api 66, haven_child 167 — all exit 0 |
| Dart (pure packages) | `dart test` (note: `dart test` has **no** `--no-pub` flag; the flag is flutter-only) | **AVAILABLE** | haven_core 18, haven_models 12 — exit 0 |
| Analyzer | `flutter analyze --no-pub` / `dart analyze`, per package (there is **no root pubspec**, so the repo is not a Dart workspace and a single root analyze is impossible) | **AVAILABLE** | 0 issues across all five packages this session |
| Line-count rule | `dart run scripts/check_line_counts.dart` | **AVAILABLE** | 704 hand-written files, 0 violations |
| Deno backend tests | `deno test --cached-only --allow-env --allow-read` in `backend/supabase/tests` | **AVAILABLE, offline** | 82 passed / 0 failed, exit 0 (`deno 2.9.4`) |
| **Kotlin / JVM unit tests** | none | **NOT AVAILABLE** | no `src/test`, no `src/androidTest`, no `testImplementation`, no `testInstrumentationRunner`, zero `.kt` test files repo-wide; Gradle execution was not attempted |
| Instrumented / emulator / device | none | **NOT AVAILABLE / NOT TESTED** | `Pixel_9a` AVD exists, never launched in this stage; no physical device attached |

**Consequence that must never be papered over**: any Kotlin claim in Stage 2 is **source inspection only**, and must be labelled **NOT TESTED**. Code review is not compilation and compilation is not execution.

## 2. Determinism requirements for the new contract tests

1. **Injected clock, always.** `Clock`/`FixedClock` already exist and are exported ([clock.dart:2-40](file:///d:/control/packages/haven_core/lib/src/clock.dart#L2-L40)) and no pairing file uses them. Every new test constructs the machine with a `FixedClock`.
2. **Ban on wall-clock assertions in new code.** The current pattern — a 5-second tolerance band, `expect(session.remainingTime.inSeconds, inInclusiveRange(295, 300))` ([local_pairing_simulation_test.dart:55](file:///d:/control/apps/haven_app/test/device_pairing/local_pairing_simulation_test.dart#L55)) — is not acceptable for the new machine. New tests assert exact deltas from a `FixedClock`.
3. **Hand-written fakes only.** The repo rule forbids mock packages; existing pairing tests already hand-roll fakes, and the channel test builds its own envelope fixture (`test/permissions/fakes.dart:127`).
4. **Stable ids.** No test may depend on random ids; id generation is injected.
5. **No network, no cloud.** `--cached-only` provenance for Deno; the Flutter suites must not reach the backend (`haven_api` offline engine is the path).

## 3. Contract scenario matrix (target coverage)

Legend: **PROVEN** = an existing test already asserts it · **NEW** = Stage 2 adds it · **⚠ needs D-3/D-5** = assertion exists but the number/rule is undecided · **IMPOSSIBLE HERE** = cannot be proven in this environment.

| # | Behavior | Today | Stage 2 plan |
| :--- | :--- | :--- | :--- |
| T-01 | 6-digit format accepted (local lane) | PROVEN (`:47`) | keep, rename to the lane constant `⚠ D-3` |
| T-02 | Wrong-shape code rejected | PROVEN (`:59`) | keep |
| T-03 | Separator/case tolerance | PROVEN (`:96`) | extend to the 4-vs-2 stripper disagreement `⚠ D-3` |
| T-04 | **Cross-language normalisation parity** Dart ↔ `normalizeIdentifier` | none | NEW — table-driven, identical strings both sides |
| T-05 | Expiry at exact boundary (`== now`, `+1ms`, `-1ms`) | partial, wall-clock | NEW with `FixedClock` |
| T-06 | Expired code cannot be reused | PROVEN (`:77`) | keep + add the "status still says active" variant |
| T-07 | Already-used code → `already_used`, never a second success | PROVEN (`:88`) | keep |
| T-08 | **Duplicate redemption race** (two `redeem` calls, one code) | none | NEW (local); backend CAS stays **IMPOSSIBLE HERE** |
| T-09 | Attempt limit reached at N failures | none anywhere | NEW `⚠ D-3` (limit value) |
| T-10 | Attempts not incremented after the limit | none | NEW |
| T-11 | Single-use redemption | partial (`:88`) | NEW as an explicit state assertion `⚠ D-3` (backend marks it INFERRED) |
| T-12 | Cancellation | none | NEW |
| T-13 | Unpair → token revoked semantics | none | NEW |
| T-14 | Unlisted `(state, event)` refused, no implicit transition | none (3 booleans allow impossible combos) | NEW — unrepresentability test |
| T-15 | Invalid vs expired indistinguishable on a network-facing surface | none | NEW `⚠ D-3` |
| T-16 | Audit record written for every allowed transition | none | NEW |
| T-17 | `blocked_pending_transport` cannot reach a connected state | none | NEW `⚠ D-5` |
| T-18 | Child UI still says "Not connected" / "Not registered" with a local redemption present | none | NEW `⚠ D-5` — the anti-fake regression |
| T-19 | Parent still labels simulated devices `SIMULATED DEVICE` | none | NEW `⚠ D-5` |
| T-20 | No code is ever logged/persisted in plaintext | none | NEW |
| T-21 | Channel constant drift test (parses `BridgeContract.kt`) | none — today's test re-types literals | NEW `⚠ D-4` |
| T-22 | `contractVersion` higher / equal / absent | none | NEW `⚠ D-4` |
| T-23 | Error-code → `HavenFailure` mapping table | none | NEW `⚠ D-4` |
| T-24 | Timeout → `RefusedArea('timeout')`, never partial-complete | none | NEW `⚠ D-4` |
| T-25 | Shape mismatch decodes to `null`, never `false`/`0` | none | NEW `⚠ D-4` |
| T-26 | One failed reader does not blank the others | PROVEN (`channel_device_state_test.dart:74`) | keep |
| T-27 | Kotlin reader behavior per API level (24/29/31/33/36) | **IMPOSSIBLE HERE** | BLOCKED — no runner, no deps (P-5) |
| T-28 | Real cross-device pairing E2E | **IMPOSSIBLE HERE** | BLOCKED (B-1) |

## 4. Baseline preservation rules

1. The protected regression set is **1,020** (haven_app 924 + haven_api 66 + haven_core 18 + haven_models 12) plus **167** child tests. Every Stage 2 run must reproduce them at the same or higher count.
2. **No existing test may be weakened, skipped, deleted or `skip:`-annotated** to make room for new behavior. If an assertion must change, it is a decision, not a fix — and it needs owner approval (this is what makes T-01's rename non-trivial: it touches a Phase 1/2 suite).
3. Adding a barrel export (`⚠ D-3`) can break nothing today — `pairing_code.dart` has **zero importers and zero tests** — but it does create a public API, so a test must pin each exported symbol.
4. `packages/haven_models/lib/src/pairing_models.dart` is 189 lines, 11 below the 200-line ceiling; the state machine must therefore live in a new file, not be appended there.
5. Every new source file must be re-checked against `dart run scripts/check_line_counts.dart` before the stage closes.

## 5. Kotlin test-infrastructure recommendation (advisory only — P-5)

| Item | Recommendation | Why |
| :--- | :--- | :--- |
| Framework | JUnit 4 (`testImplementation("junit:junit:4.13.2")`) | matches what a Flutter Android module already expects; smallest addition |
| Android-in-JVM | Robolectric | lets `HavenBridge.readAll` and the five readers be exercised without a device; **must be labelled "mocked unit tests", never "device verified"** |
| Source sets | create `android_native/.../src/test/kotlin` (or move the lane behind a real Gradle module — that is D-4a) | today the lane is compiled into the parent via `srcDir`, so a test source set must be attached to the parent module or the lane must become a module |
| API-level matrix | `@Config(sdk = [24, 29, 31, 33, 36])` per test class | these are the guard levels the repo actually branches on |
| Mocking | **MockK only if unavoidable**; prefer constructor-injected `ContextProvider` lambdas, which `HavenBridge.forApp` already supports ([HavenBridge.kt:78](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L78)) | keeps the hand-written-fakes convention alive |
| Contracts | one Kotlin test mirroring the Dart drift table | makes the two sides disagree loudly |
| Cost | one gradle change + dependency resolution | **no dependency may be added before the owner approves P-5** |
| Until approved | Kotlin status stays **NOT TESTED**, stated in every report | prevents "0 Kotlin failures" being misread as "Kotlin verified" |

## 6. Evidence format

Every Stage 2 test result must be recorded as: command line · exit code · the runner's own tally line verbatim · delta versus the protected baseline · skips (count and, if non-zero, the reason) · what was **not** executed and why. A number without a command is not evidence.

## 7. Explicitly out of scope for Stage 2 testing

Usage monitoring, location monitoring, app blocking, website filtering enforcement, background/foreground service lifecycle, reboot recovery, device-owner provisioning, real cross-device pairing, physical-device behavior. Each is a later stage with its own gate; none may be marked verified on the strength of a Stage 2 contract test.
