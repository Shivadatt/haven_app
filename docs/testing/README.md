# Haven — test inventory and verification status

Everything on this page was **run** on **2026-11-04** from `D:/control`, and the numbers are the
runner's own output — not a count of `test()` call sites.

## 1. §13 quality checks, one row per check

| # | Check | Command | Verdict | Measured |
| --- | --- | --- | --- | --- |
| 1 | Toolchain is 3.44.6 | `fvm flutter --version` | **PASS** | `Flutter 3.44.6 • framework ee80f08bbf • engine d3a3293399` |
| 2 | Dependency resolution | `fvm flutter pub get` in each lane | **PASS** | `Got dependencies!` in `packages/haven_core`, `packages/haven_models`, `packages/haven_api`, `apps/haven_app` (2026-11-04) |
| 3 | Formatting | `fvm dart format --output=none --set-exit-if-changed apps packages scripts android_native` | **PASS, after a correction** | first run reported `Formatted 334 files (2 changed)` — `packages/haven_api/lib/src/edge_caller_impl.dart` and `packages/haven_api/test/backend_status_test.dart` were unformatted. Both were formatted; the re-run is `0 changed`, line-count still 0 violations, `haven_api` still `+22: All tests passed!` |
| 4 | Static analysis | `fvm flutter analyze` in `apps/haven_app` | **PASS** | `No issues found! (ran in 127.8s)` |
| 5 | Unit + widget tests | `fvm flutter test` × 4 | **PASS** | **772 Dart tests, 0 failures** (§2) |
| 6 | Line-count validation | `fvm dart run scripts/check_line_counts.dart` | **PASS** | `max 200`, **397 hand-written files scanned, 0 violations** |
| 7 | Android debug APK | `fvm flutter build apk --debug` | **PASS (build only)** | `apps/haven_app/build/app/outputs/flutter-apk/app-debug.apk`, 164,102,984 bytes, 2026-11-04 14:09 |
| 8 | Backend types | `deno check` in `backend/supabase/functions` | **PASS** | 41 files |
| 9 | Backend lint | `deno lint` (functions, tests) | **PASS** | 41 files and 10 files, 0 problems |
| 10 | Backend tests | `deno test --allow-env --allow-read` | **PASS** | **82 passed, 0 failed** (Deno 2.9.4) |
| 11 | End-to-end against staging | — | **BLOCKED — cannot be run** | staging has 0 tables / 0 SQL functions / 0 Edge Functions / 0 secrets; Firebase has 0 apps and 0 credentials |
| 12 | Push delivery on a device | — | **BLOCKED** | A12-R unsigned; no `google-services.json`; `firebaseInit` never supplied |
| 13 | Android restriction enforcement | — | **NOT VERIFIED** | the child-agent lane reports enforcement only when the OS confirms it; nothing was installed on a device |

Check 7 is a **successful build**, which is not a claim that the app does anything yet: an APK that
cannot reach a backend is still a valid APK. The brief forbids treating one as a feature result.

## 2. Dart suites (772 tests, all passing)

| Lane | Test files | Tests | Runner line |
| --- | --- | --- | --- |
| `apps/haven_app` | 93 | **720** | `01:00 +720: All tests passed!` |
| `packages/haven_api` | 2 | **22** | `+22: All tests passed!` |
| `packages/haven_core` | 1 | **18** | `+18: All tests passed!` |
| `packages/haven_models` | 3 | **12** | `+12: All tests passed!` |

App tests are grouped by feature directory, mirroring `lib/features/`: `account`(3 files),
`authentication`(5), `child_devices`(4), `core`(1), `dashboard`(4), `device_activity`(4),
`device_commands`(4), `device_pairing`(4), `family`(7), `location`(4), `notifications`(8),
`onboarding`(3), `permissions`(4), `policies`(5), `remote_sessions`(8), `safe_zones`(10),
`settings`(6), `shell`(6), `telemetry`(3), plus `support/` (fakes: `backend_fakes.dart`,
`data_fakes.dart`, `fakes.dart`, `feed_fakes.dart`, `host.dart` — helpers, not tests).

### What these tests actually pin

They are **behaviour and honesty** tests, not coverage tests. Representative assertions, all passing:

- `apps/haven_app/test/telemetry/telemetry_card_test.dart` — "no family says so instead of showing an
  empty log", and "the card states that it is a snapshot, not a live view". An empty list is never
  rendered as success.
- `packages/haven_api/test/credential_seams_test.dart` — unconfigured seams install with no endpoints
  and register unconfigured clients; the realtime feed **rejects a table the baseline does not publish**;
  `EdgeFunctionName.pairing` is asserted to error rather than to succeed (`:91`).
- `packages/haven_api/test/backend_status_test.dart` — status derives from which defines are present.
- `packages/haven_models/test/round_trips_test.dart` — `LocationEvent` **keeps accuracy as reported**
  (no invented precision) and `RemoteSession` consent is a single boolean.
- `packages/haven_core/test/…` — `RetryPolicy` does not retry a rejection; `FixedClock` advances and
  answers `isPast`.
- Widget tests across `features/**` drive controllers through the GetX bindings with fakes, so no test
  touches a network or a cloud project.

## 3. Backend suites (82 tests, all passing)

`cd backend/supabase/tests && deno test --allow-env --allow-read`

| File | Tests | Focus |
| --- | --- | --- |
| `envelope_test.ts` | 10 | `{ok:true}`/`{ok:false,error:{code,message}}`, `no-store`, CORS/OPTIONS (E9), `readJson` 400/413, action guard |
| `readers_test.ts` | 16 | PE-R06, PE-C07/C09, PE-A06, PE-S09, PE-T02/T09, PE-C03 clamp, PE-P01 alphabets, `sha256Hex` FIPS vector |
| `auth_roles_test.ts` | 9 | TE-07/08/09 (401 before any query), profile-missing 403, TE-15 predicate shape, `requireRole`, `getServiceClient` 503 |
| `guards_test.ts` | 14 | TE-01/03/04/05/19/20, family scope assertions, `owner_required`, revoked credential, E7 no-lockout pin, audit columns |
| `pairing_limits_test.ts` | 10 | 4-failure window then 429 + numeric `retry_after_seconds`, identifier cap, quota queues, E5/E6 pepper behaviour |
| `handlers_test.ts` | 13 | PE-S01/S02/S03/S04/S08/S10, TE-12/13, consent compare-and-set predicates, PE-T01/T02/T03 |
| `auth_bootstrap_test.ts` | 10 | PE-A01/A02/A04/A05/A06, name bounds, `publicDevice`, and the `NOT DEPLOYABLE WITHOUT SPEC` text guard |

Three things a reader must not over-read (from `backend/supabase/tests/README.md` §1-§3, restated
because they bound every claim in this repository):

1. A pass means **the re-authored logic matches its own documented contract**. It is **not** parity
   with the deployed bundles — all nine slugs keep `RE-AUTHORED FROM SPECIFICATION — NO PARITY
   VERIFICATION`.
2. It does **not** execute a row of `docs/stage1/15-edge-function-test-plan.md`. Those HTTP-level
   `TE-*`/`PE-*` cases stay `NOT EXECUTED`; each test names the case id whose *decision* it
   reproduces.
3. No `index.ts` is imported, because each calls `Deno.serve` at module scope; the entry wiring is
   verified by `deno check` and by reading, not by these tests.

Preserved weaknesses are **pinned, not fixed**: E4 (pending sessions stack) and E7 (no device
lockout, identical responses for wrong-secret vs unknown-id). Changing enforcement silently is not
permitted; the tests exist so a future change is a deliberate, labelled edit.

## 4. Kotlin

`android_native/` contains **0 test files**. The child-agent lane is compiled into the debug APK path
but has no unit or instrumentation tests, and it has never been run on a device or emulator. Any
statement that a device-admin, overlay, battery-exemption or monitoring behaviour "works" would be
unsupported — the lane reports OS confirmation and nothing has been confirmed.

## 5. Not covered, and why (carried forward from the backend README)

`TE-02`, `TE-14`/`PE-S05`/`PE-S06`, `TE-16`/all `PE-CR*`, `PE-C01`/`C04-C08`,
`PE-P02`/`P05`/`P07-P12`, `PE-PL01`/`05`/`07`, `PE-F01`/`F03`/`F05`, `PE-T04-T08`, `PE-R02-R05`, and
every `CI-*` row. Each is uncovered for one of three reasons: it needs a deployed slug, it needs a
SQL/RPC side effect that cannot be reached offline, or its contract is one of the two
`NOT DEPLOYABLE WITHOUT SPEC` scopes.

## 6. How to reproduce

```bash
cd D:/control
fvm flutter --version
(cd apps/haven_app && fvm flutter analyze && fvm flutter test)
for p in packages/haven_core packages/haven_models packages/haven_api; do (cd $p && fvm flutter test); done
fvm dart run scripts/check_line_counts.dart
(cd backend/supabase/functions && deno check $(ls */*.ts) && deno lint)
(cd backend/supabase/tests && deno lint && deno test --allow-env --allow-read)
```

Use the FVM launcher for Flutter/Dart; use the Deno on `PATH` (2.9.4) for the backend. **Never** run
`deno fmt` on `backend/` — it rewraps the split files past the 200-line gate.
