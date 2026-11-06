# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2: READINESS AND OWNER DECISIONS

**Purpose**: the decision packet the owner must answer before Stage 2 may start.
**Author**: Agent 4, "Phase 3 Stage 2 READINESS ONLY" pass (documentation-only; no implementation, no build, no
test run, no git operation).
**Governing contract**: `docs/implementation/00-app-contract.md`; Phase 3 ground rules
`docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md:10-17`.
**Labels used**: `FACT` (this agent read the cited line), `FACT(doc)` (a recorded result reproduced from a
Stage-1 document, **not re-run here**), `VERIFIED-BY-TEST` (asserted by a test that exists in the cited file),
`INFERRED`, `PROPOSED — awaiting owner approval`, `UNVERIFIED`.
**Nothing here says Stage 2 has started.** `PHASE_3_MASTER_PLAN.md:5` still reads "Stage 2 not started" and this
pass changed nothing but these two documents.

---

## 1. Verified baseline (no drift)

| Item | Value | How checked by this agent | Label |
| :--- | :--- | :--- | :--- |
| HEAD | `8e50da06982c495a20407a505235f230de1720f2` (`8e50da0`), branch `main`, subject "docs: add phase 2 implementation reports…" | `git log -1 --format=%H %h %s` (read-only) | FACT |
| Git index | **131 `A `, 1 `AM`, 7 ` M`** — externally staged work, untouched by this pass | `git status --porcelain` counted by status column | FACT |
| Staged content size | **139 files changed, 8,764 insertions(+), 16 deletions(-)** | `git diff --cached --shortstat` — matches the handed figure exactly | FACT |
| Untracked files | grew from 9 (handed) to **12 during this pass**, all `docs/implementation/phase_3/*.md` written by sibling agents in this same readiness pass (observed `STAGE_2_DECISION_PROPOSAL.md` re-written 14:09, `ANDROID_CAPABILITY_INVENTORY.md` 14:12, `PAIRING_REGISTRATION_CONTRACT.md` 14:14) | `git status --porcelain` re-counted at 14:14 | FACT |
| Baseline drift verdict | **No drift in tracked or staged code.** Only untracked documentation moved, and only inside `docs/implementation/phase_3/` | rows above | INFERRED |
| Protected test baseline | parent 924 + haven_api 66 + haven_core 18 + haven_models 12 = **1,020**, child **167**, repo-wide 1,187 | `STAGE_1_TEST_RESULTS.md:32-38`; **not re-run by this agent** | FACT(doc) |
| Analyzer | root `flutter analyze` → `No issues found!` | `STAGE_1_TEST_RESULTS.md:20-21` | FACT(doc) |
| Line-count gate | `hand-written source files scanned: 704`, `violations: 0` | `STAGE_1_TEST_RESULTS.md:22`; rule `scripts/check_line_counts.dart:12` (`maxLines = 200`), scanned roots `:22-28` | FACT(doc) |
| Child debug APK | `apps/haven_child/build/app/outputs/flutter-apk/app-debug.apk` = **162,458,160 B** | `ls -l` this pass | FACT |
| Parent debug APK | `apps/haven_app/build/app/outputs/flutter-apk/app-debug.apk` = **190,571,206 B** | `ls -l` this pass | FACT |
| Child tree size | **58** `lib/*.dart`, **29** `test/*.dart`; feature dirs are exactly `device, onboarding, permissions, profile, splash` | `find` + `ls` this pass | FACT |
| Parent/package drift | none observed: the only Haven-owned `MethodChannel(` in all Dart is `apps/haven_app/lib/core/permissions/channel_device_state.dart:25` | repo-wide grep this pass | FACT |
| Stage-1 status wording | "Stage 1 complete with limitations… Await go-ahead for Stage 2" | `PHASE_3_MASTER_PLAN.md:89` | FACT |

---

## 2. D-3 — pairing-code specification decision (`PROPOSED — awaiting owner approval`)

**The conflict is three-way, and all three sides are real code.**

| Side | What it actually does today | Citation | Label |
| :--- | :--- | :--- | :--- |
| Parent DEMO simulation | 6 digits from `Random.secure().nextInt(1000000)` zero-padded; TTL **5 minutes**; **no attempt cap at all**; validation order format → redeemed → expired → mismatch; the code is kept in a memory-only session object and never written to storage | `apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart:22-24`, `:38-77`, `:105-125` (row map contains no code field), `:130`; `apps/haven_app/lib/features/device_pairing/data/simulation_models.dart:4-33` (in-memory `code` field at `:13`, `redeem()` at `:30-32`) | FACT |
| Backend re-authored Edge spec | `CODE_TTL_MINUTES = 10`, `MAX_ATTEMPTS_PER_CODE = 10`; code shape is **8 characters from a 30-symbol alphabet**, not 6 digits; stored artefact is a sha256 hash | `backend/supabase/functions/pairing/shared.ts:10`, `:12`; `backend/supabase/functions/_shared/identifiers.ts:24-25`, `:46-48`; `docs/stage2/migrations/A3-staging-load-v1.sql:448` (`code_hash ~ '^[0-9a-f]{64}$'`), `:425` (UNIQUE) | FACT |
| Shared validator (orphan) | `validatePairingCode(raw, {format})` returns `blocked(pairingCodeRuleGap)` whenever no `PairingCodeFormat` is supplied; **it has zero callers and zero tests**, and is **not** barrel-exported | `packages/haven_core/lib/src/pairing_code.dart:84-96`, gap string `:26-27`, formats `:31-38`; exports list `packages/haven_core/lib/haven_core.dart:4-10` (no `pairing_code.dart`); repo-wide grep for `PairingCodeFormat`/`pairingCodeRuleGap` → matches only inside that file | FACT |
| Name collision | a *different*, legacy `String? validatePairingCode(String?)` (length 4..64 heuristic) **is** exported and is a different function with the same name | `packages/haven_core/lib/src/validation.dart:70-80`; `haven_core.dart:10` | FACT |
| Backend is not deployed | "Supabase staging has no Edge Functions deployed" | `docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md:192` | FACT |
| Contract rule | never store/transmit a plaintext pairing code beyond its displayed lifetime; the KDF is not captured | `docs/implementation/00-app-contract.md:108-109` | FACT |

**New finding from this pass (FACT)**: even if the owner adopts the backend shape, `haven_core` cannot express it
today — `PairingCodeCharset.upperAlphanumericNoAmbiguous` is `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (**32** symbols,
`pairing_code.dart:34`) while the backend alphabet is `23456789ABCDEFGHJKMNPQRSTVWXYZ` (**30**,
`_shared/identifiers.ts:24`); the two differ by the letters `L` and `U`.

| Option | What it means | Trade-offs |
| :--- | :--- | :--- |
| **(i) Backend shape canonical now** | Adopt 8×30-symbol as *the* rule; rework the simulation to generate it; export `PairingCodeFormat`/`validatePairingCode` and make every caller pass a format | Pro: one shape, no drift to reconcile later; the orphan validator finally gets a consumer. Con: the backend is undeployed (`:192` above) so the "canonical" rule is still a *re-authored* guess — `shared.ts:3-5` and `identifiers.ts:5` both say "RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION"; a Phase-4 deploy could contradict it; requires touching parent feature code and a shared package (contract `PHASE_3_MASTER_PLAN.md:29`) |
| **(ii) Two documented shapes: DEMO stays 6-digit, backend shape authoritative for Phase 4** | The simulation keeps its 6-digit/5-minute behaviour under a DEMO label; the written spec records TTL 10 / attempts 10 / 8×30 as the Phase-4 target; the validator stays unexported but the gap is documented | Pro: zero behavioural change, zero new surface, honest; matches the existing rule that Phase-2 simulation is never retroactively re-labelled (`PHASE_3_MASTER_PLAN.md:15`). Con: two shapes live in the repo and the next reader must be told which one is real; TTL/attempt drift stays a standing risk |
| **(iii) Freeze the format question entirely** | Declare that no code shape exists until the deployed function is read; leave the validator unexported and add no callers | Pro: maximum honesty — matches the validator's own wording "Haven can't confirm the shape" (`pairing_code.dart:92-95`). Con: Stage 2 cannot write *any* registration-contract test that asserts a shape, so the "typed pairing redeem/registration state machine" gate in `PHASE_3_MASTER_PLAN.md:54` weakens to structural-only contracts |

**Constraint that applies to all three**: whatever is chosen, the plaintext code must not be persisted or
transmitted beyond the displayed lifetime (`00-app-contract.md:108-109`), and today's simulation already satisfies
that by keeping the code memory-only (`pairing_simulation_service.dart:105-125`) — a change to option (i) must
preserve it.

---

## 3. D-4 — native channel typing decision (`PROPOSED — awaiting owner approval`)

**What exists (all FACT, read this pass):**

| Fact | Citation |
| :--- | :--- |
| Exactly one channel, one method, five readers: `haven.dev/child_device_state` / `state.readAll` | `android_native/child_services/platform_bridge/BridgeContract.kt:13`, `:16`; readers registered `HavenBridge.kt:80-87` |
| Envelope keys `apiLevel`/`osRelease`/`sections`/`sectionErrors`; error codes `unknown-method`, `no-context`, `section-failed` | `BridgeContract.kt:18-21`, `:24`, `:27`, `:34` |
| Constants are **duplicated** Kotlin↔Dart, and both sides admit it: "changing one without the other is a compile-time error on neither side" | `BridgeContract.kt:13-16` ↔ `apps/haven_app/lib/core/permissions/channel_device_state.dart:10-12`, `:14-15` |
| The only drift defense is a verbatim-string test plus a real `MethodChannel`/`setMockMethodCallHandler` harness | `apps/haven_app/test/permissions/channel_device_state_test.dart:21-30`, `:38-43` — VERIFIED-BY-TEST |
| No write/apply method by design | `HavenBridge.kt:13-17` |
| Pigeon is absent everywhere (pubspec/lock/gradle/kts/dart/kt grep: zero), zero `EventChannel`, zero `BasicMessageChannel` | greps this pass; corroborated `docs/implementation/phase_3/STAGE_2_DECISION_PROPOSAL.md` and `STAGE_1_KNOWN_LIMITATIONS.md:28` |
| No `build_runner`, no CI workflow exists in the repo to run generated code | `FACT` — `.github` absent from the tree listing and no `build_runner` dependency in any pubspec (this agent grepped `apps`+`packages`) |
| Generated-file whitelist covers `.g.dart`, `.freezed.dart`, `.mocks.dart`, `google_services`, and dirs incl. `/generated/` — so a Pigeon output named `*_pigeon.dart` outside a `generated/` dir would be counted against the 200-line rule | `scripts/check_line_counts.dart:30-41`, `:44-51`, `:12` |
| The child cannot compile the native lane at all: `android_native/child_services` is `srcDir`-redirected into the **parent** app | `apps/haven_app/android/app/build.gradle.kts:36-43` (srcDir `:41`); child config has no srcDir `apps/haven_child/android/app/build.gradle.kts:7-37`; child Kotlin is one 5-line `MainActivity` `.../com/haven/child/MainActivity.kt:1-5` |

**Correction to handed evidence** (stated plainly): the citations
`apps/haven_child/lib/core/device/channel_device_state.dart:7-15` and
`apps/haven_child/test/device/channel_device_state_test.dart:21-43` do **not** exist. The Dart half of the bridge
lives in the **parent**: `apps/haven_app/lib/core/permissions/channel_device_state.dart:13-16` and
`apps/haven_app/test/permissions/channel_device_state_test.dart:21-43` (line ranges as handed, app path wrong).
Also `backend/supabase/functions/pairing/identifiers.ts` → real path
`backend/supabase/functions/_shared/identifiers.ts` (same line numbers), and `pairing_controller.dart:89-129` →
the `submitCode` in question is at `apps/haven_app/lib/features/device_pairing/controllers/pairing_simulation_controller.dart:88-128`
(`pairing_controller.dart` is 94 lines long).

**One refinement, not a failure:** the handed note "controller `submitCode` lacks an in-flight early-return
guard" is true of the controller (`pairing_simulation_controller.dart:88-121` sets `isSubmitting` only at `:111`),
but the widget path is already guarded — the button passes `busy: controller.isSubmitting.value`
(`apps/haven_app/lib/features/device_pairing/views/widgets/pairing_simulation_forms.dart:126`) and `HavenButton`
disables the action when busy (`apps/haven_app/lib/shared/components/haven_button.dart:34`). The residual risk is
only for non-widget callers (tests, programmatic invocation). — FACT

| Option | What it means | Trade-offs |
| :--- | :--- | :--- |
| **A — Pigeon codegen** | Declare the channel contract once in Dart, generate both sides | Pro: kills the drift class at the type level. Con: needs `build_runner`/`pigeon` tooling that does not exist; needs a CI that does not exist; generated files can blow the 200-line rule unless whitelisted (`check_line_counts.dart:44-51` — `.g.dart` is covered, arbitrary `*_pigeon.dart` names are not); and the child still cannot compile the lane, so codegen would formalise a surface only the parent can use |
| **B — standardised hand-rolled typed wrapper + cross-language key-agreement test** | Keep the hand-rolled pattern already in `BridgeContract.kt` / `channel_device_state.dart`, but make it a *documented standard*: one contract file per language, one naming scheme, and a test that asserts the key/method/section strings on both sides (extending the single existing test at `channel_device_state_test.dart:38-43`) | Pro: zero new tooling, matches existing precedent, works with no CI; can be enforced today by the same suite that already runs. Con: still string-typed — it detects drift only when the test is run; a Kotlin-only key rename is caught by nothing unless the Dart test enumerates it |
| **C — B plus one `EventChannel` per streaming lane** | Same as B, and add push channels where continuous data is needed | Pro: right long-term shape for telemetry. Con: premature — no lane needs a stream yet (the bridge is read-on-demand by design `HavenBridge.kt:13-17`), and adding one would create an untested surface |

**Owner questions (four)**: (1) scope — does the decision cover only the existing `state.readAll` lane, or every
future child-side lane too? (2) key source of truth — which language's file is authoritative, and is a Dart test
allowed to assert Kotlin strings? (3) codegen acceptability — is `build_runner`/Pigeon acceptable at all, and where
would a child-side `android_native` package live (it currently compiles only under the parent namespace,
`apps/haven_app/android/app/build.gradle.kts:41`)? (4) timing — before Stage 2 code, or allowed to land during it?

---

## 4. D-5 — parent ↔ child exchange decision (`PROPOSED — awaiting owner approval`)

| Fact | Citation | Label |
| :--- | :--- | :--- |
| Separate Android sandboxes: parent `com.haven.haven_app`, child `com.haven.child` | `apps/haven_app/android/app/build.gradle.kts:8`, `:19`; `apps/haven_child/android/app/build.gradle.kts:10`, `:21` | FACT |
| Both write a document **named** `haven_local.json`, each inside its own documents directory | name default `packages/haven_api/lib/src/offline/local_store.dart:29`; child `apps/haven_child/lib/core/storage/child_database.dart:47-48` + path `child_storage_paths.dart:24-30` (documents dir at `:28`); parent `apps/haven_app/lib/app/bindings/initial_bindings.dart:56-66` (documents dir `:60`, store `:62`) | FACT |
| Same file name ≠ shared state; there is no exchange mechanism | `docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md:24`; `PHASE_3_MASTER_PLAN.md:38` (D-5 OPEN), `:81` (B-1) | FACT |
| The child has **no** pairing feature at all | feature dirs are `device, onboarding, permissions, profile, splash` (this pass, `ls apps/haven_child/lib/features`); session text is a constant "Parent connection / Not connected" `apps/haven_child/lib/core/session/child_local_session.dart:22-23` | FACT |
| Every cloud pairing seam refuses | `apps/haven_app/lib/features/device_pairing/data/pairing_repository.dart:103-121` (`createInvite`, `redeemCode`, `cancel` all `blocked(...)`) | FACT |
| QR/BLE optical exchange exists only as deferred scope | `docs/implementation/phase_1/DEFERRED_FEATURES.md:38-40` | FACT |

| Option | What it means | Trade-offs |
| :--- | :--- | :--- |
| **(a) Label-only local exchange / DEMO** | Contracts + a clearly labelled simulation on each side; no claim that two phones met | Pro: shippable now at ladder level 2; keeps the Phase-2 simulation honesty rule `PHASE_3_MASTER_PLAN.md:15`. Con: cannot satisfy anyone who reads "paired" as real; the DEMO already invents capability flags (`'usage_access_granted': true`, `'location_granted': true`, `'camera_granted': true`, `'microphone_granted': true`, `'notifications_granted': true`, `'battery_level': 95` — `pairing_simulation_service.dart:115-122`), so Stage 2 must label those explicitly as fabricated, or the capability inventory doc will contradict them |
| **(b) Backend-mediated real pairing** | Move pairing into the deployed Edge Function path | Belongs to Phase 4: needs deployed functions (zero today — `docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md:192`) and a captured KDF (not captured — `docs/implementation/00-app-contract.md:108-109`). Neither exists, so this is **BLOCKED**, not deferred-by-choice |
| **(c) QR / BLE optical exchange** | Same-device or same-room rendezvous without cloud | Zero code in the repo; deferred scope `DEFERRED_FEATURES.md:38-40`; would need its own decision, permissions and tests — outside Stage 2's local-only envelope |

**Real cross-device pairing stays BLOCKED** on the pre-declared register (`PHASE_3_MASTER_PLAN.md:81`, B-1). This
pass did not pair, grant, or run anything on a device, and nothing here may be read as having done so.

---

## 5. Recommendations awaiting approval

Each is **PROPOSED — awaiting owner approval**; none is authorization.

1. **D-3 → option (ii)**, plus a one-line doc correction: keep the 6-digit/5-minute parent simulation labelled
   DEMO, record TTL 10 / 10 attempts / 8×30-symbol as the Phase-4 target, and keep
   `packages/haven_core/lib/src/pairing_code.dart` unexported and caller-less until a spec is *verified from a
   deployed* backend. Reason: the backend text is self-labelled "RE-AUTHORED FROM SPECIFICATION — NO PARITY
   VERIFICATION" (`shared.ts:3-5`, `_shared/identifiers.ts:5`), and the shape cannot even be expressed by the
   current charset (`pairing_code.dart:34` = 32 symbols vs 30). (PROPOSED — awaiting owner approval)
2. **D-4 → option B**: standardised hand-rolled typed contract + an enforced key-agreement test; defer the
   EventChannel clause (C) to the first lane that genuinely streams. Do **not** adopt Pigeon (A) while the child
   cannot compile the native package (`apps/haven_app/android/app/build.gradle.kts:41`,
   `apps/haven_child/android/app/build.gradle.kts:7-37`). (PROPOSED — awaiting owner approval)
3. **D-5 → keep real cross-device pairing BLOCKED**; Stage 2 delivers contracts plus labelled simulation only, and
   every fabricated capability flag in the DEMO row (`pairing_simulation_service.dart:115-122`) must be labelled as
   simulation in the same screen. (PROPOSED — awaiting owner approval)
4. **Dependency isolation**: see §6. (PROPOSED — awaiting owner approval)
5. **Add a source-manifest vs merged-manifest row to the Stage 2 inventory gates** — the child's merged debug
   manifest declares `INTERNET`/`POST_NOTIFICATIONS`/`ACCESS_NETWORK_STATE`/`WAKE_LOCK` although its source
   manifest declares none (`apps/haven_child/android/app/src/main/AndroidManifest.xml:2-8` vs
   `apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16`).
   (PROPOSED — awaiting owner approval)

---

## 6. Firebase / dependency-isolation recommendation (`PROPOSED`)

| Fact | Citation | Label |
| :--- | :--- | :--- |
| `haven_api` declares `firebase_auth ^7.0.1`, `firebase_core ^5.1.0`, `firebase_messaging ^17.0.1` and `supabase_flutter ^2.18.3` | `packages/haven_api/pubspec.yaml:13-15`, `:21` | FACT |
| The child path-depends on `haven_api` | `apps/haven_child/pubspec.yaml:21-22` | FACT |
| Therefore the cloud plugins ship transitively into the child APK; the build log names them | `apps/haven_child/build/…` evidence `…/_scratch/p3_stage1/build/build_log.txt:3` ("plugins that apply Kotlin Gradle Plugin (KGP): firebase_auth, firebase_core") | FACT(doc)/FACT(artifact) |
| `firebase_auth` is imported **nowhere** in haven_api source, yet `firebase_core`/`firebase_messaging` **are** imported once each | grep `firebase_auth` over `packages/haven_api/lib` + `test`: zero; `packages/haven_api/lib/src/push_transport_impl.dart:3-4` imports `firebase_core` and `firebase_messaging` | FACT (refinement of the handed "zero Firebase imports") |
| The barrel exports cloud lanes (`:11`, `:14-16`, `:30-34`) alongside offline lanes (`:18-29`), and every child file imports the full barrel | `packages/haven_api/lib/haven_api.dart` (34 lines, read this pass) | FACT |
| The offline lane is *nearly* pure: its files import `haven_core`, `get`, `dart:async`/`convert`/`math`, plus one intra-package contract file `../backend_endpoints.dart` | `packages/haven_api/lib/src/offline/local_schema.dart:1`, `demo_data_records.dart:3`, `demo_data_suite.dart:3` | FACT (refinement of the handed "pure" claim) |
| APK carries unused cloud code (~162 MB observed size) | `docs/implementation/phase_3/STAGE_1_KNOWN_LIMITATIONS.md:22`; size `ls -l` this pass | FACT(doc); **UNVERIFIED** that removing Firebase actually shrinks the APK — needs a build |
| Prior recommendation on record: split before Stage 3 | `docs/implementation/phase_3/STAGE_1_AUDIT_REPORT.md:174` | FACT |

| Option | Meaning | Trade-offs |
| :--- | :--- | :--- |
| **(a) New `haven_offline` package** | Lift `src/offline/*` + contracts out of `haven_api`; child depends only on it | Pro: hard isolation, child APK stops carrying Firebase/Supabase by construction. Con: migration surface is large (handed counts: 44 offline-dir tests + 22 top-level; 67 parent files import `haven_api`; contracts currently live inside `haven_api`), touches parent contracts (rule `PHASE_3_MASTER_PLAN.md:29`), and the pairing/registration contracts Stage 2 needs would have to be placed deliberately or duplicated |
| **(b) Gate the cloud exports inside `haven_api`** | Conditional exports/entry points so an app that only needs offline does not pull cloud lanes | Pro: no new package, no parent-feature churn, reversible. Con: Dart still resolves the transitive plugin deps at build time, so the KGP warning may persist; needs a decision on which export set is "offline" |
| **(c) Keep the dependency and document it** | Status quo: `STAGE_1_KNOWN_LIMITATIONS.md:12-22` already states the promise is about *declared* deps only | Pro: zero risk this stage. Con: the "local-only child build" claim stays qualified, and the KGP deprecation remains a future build-breaker |

**Recommendation (PROPOSED — awaiting owner approval)**: decide (a) vs (b) *before* Stage 3, as already recorded at
`STAGE_1_AUDIT_REPORT.md:174`; Stage 2 itself may proceed under (c) because no Stage-2 deliverable needs the split.
A merged/declared-manifest comparison line (§5 item 5) should accompany whichever option is chosen.

---

## 7. Proposed Stage 2 brief — **proposal, not authorization**

**Scope (local-only, no cloud)**
1. Registration-protocol **contracts**: typed pairing redeem / registration state machine, expiry, duplicate,
   unpair and audit-row shapes, expressed against the existing honest vocabulary (`blocked(...)`, `Unconfigured*`)
   — per `PHASE_3_MASTER_PLAN.md:54` (Stage 2 row) and rule 1 at `:13`.
2. **Labelled DEMO simulation only**: keep `pairing_simulation_service.dart` behaviour, add explicit
   "fabricated capability values" labels for the flags at `:115-122` so the inventory doc cannot be read as device
   truth.
3. **Capability inventory**: `STAGE_2_ANDROID_CAPABILITY_INVENTORY.md` is the first version of the deliverable;
   Stage 2 may extend it, but every new row needs a file:line source citation.
4. Channel work only **after** the D-4 approval in §3, and only in the direction the owner picks.
5. New files stay within `apps/haven_child/` and `docs/implementation/phase_3/` — no breaking edit to parent
   contracts (`PHASE_3_MASTER_PLAN.md:29`).

**Acceptance gates**
- Child and parent `flutter analyze`: `No issues found!` on both.
- Protected baseline **1,020** (924/66/18/12) passes with zero variance **and** the child suite (167 today) passes
  — regression gate cadence per `PHASE_3_MASTER_PLAN.md:71`.
- `dart scripts/check_line_counts.dart`: 0 violations, limit 200 (`scripts/check_line_counts.dart:12`).
- Child debug APK rebuilt (today's artifact: 162,458,160 B).
- Every claim on the six-level ladder (`PHASE_3_MASTER_PLAN.md:14`) stops at **level 2 — Flutter logic**, except
  device state, which may be claimed at **level 3 partial, parent-side, host-mocked** and never higher without a
  device.
- New doc lines must not contradict §1 of this packet.

**Explicitly out of scope**: real cross-device pairing (B-1 `PHASE_3_MASTER_PLAN.md:81`), permission requests or
grant claims, monitoring/enforcement of any kind, foreground services, background location, installed-app
enumeration, `UsageStatsManager` counts, battery level, network state, and any physical-device claim.
**Stage 2 has not started.** Starting requires the owner answers in §9.

---

## 8. Risk register

| # | Risk | Evidence it is live | Impact | Mitigation available in Stage 2 | Label |
| :-- | :--- | :--- | :--- | :--- | :--- |
| R-1 | Plaintext pairing-code exposure | rule `docs/implementation/00-app-contract.md:108-109`; today the code is memory-only (`pairing_simulation_service.dart:105-125`) | Contract violation; child-safe surface | keep code out of any persisted row; never log it; add a test asserting the persisted row has no code field | FACT (rule + current state) |
| R-2 | TTL / shape drift between simulation and backend spec | 5-min 6-digit vs 10-min 8×30 (`pairing_simulation_service.dart:22-24` vs `shared.ts:10,12` + `_shared/identifiers.ts:24-25`) | Phase-4 integration surprise; wrong user instructions | D-3 decision recorded in writing; every DEMO screen states which shape it is faking | FACT |
| R-3 | Charset cannot express the chosen shape | `pairing_code.dart:34` = 32 symbols vs 30 at `_shared/identifiers.ts:24` | An "adopt backend spec" decision silently fails | note in the D-3 answer; fix is a shared-package edit, needs its own approval | FACT |
| R-4 | Channel key drift with no CI enforcement | duplicated constants (`BridgeContract.kt:13-16` ↔ `channel_device_state.dart:14-15`); one verbatim-string test only (`channel_device_state_test.dart:38-43`); no CI workflow and no `build_runner` in the tree | Silent "no lane to ask" on a phone that has one, exactly as the test comment warns `:39-40` | D-4 option B: key-agreement test covering every key and section name | FACT |
| R-5 | Transitive Firebase in child shipping builds | `packages/haven_api/pubspec.yaml:13-15`, `:21` via `apps/haven_child/pubspec.yaml:21-22`; KGP warning `_scratch/p3_stage1/build/build_log.txt:3`; merged manifest gains permissions the source never declared (artifact `:11-16`) | Future build break; overstated "no network" claims | §6 decision; inventory doc states source-vs-merged manifest separately | FACT |
| R-6 | Sandbox false-assumption of shared state | same filename in both sandboxes (`local_store.dart:29`, `child_database.dart:47-48`, `initial_bindings.dart:62`); no SAF/MediaStore/FileProvider/`content://` anywhere (grep: zero source matches) | A screen implying "the parent already knows this" | keep D-5 BLOCKED wording; `CHILD_LOCAL_STORAGE_CONTRACT.md:24` sentence belongs in every pairing doc | FACT |
| R-7 | Index-state confusion at commit time | externally staged 139 files / 8,764 insertions verified this pass; untracked docs rising during the pass (9 → 12 observed at 14:14) | A future agent staging/normalising could destroy others' work | **no agent git operations** (contract rule, `PHASE_3_MASTER_PLAN.md:13`); owner commits | FACT |
| R-8 | Doc-vs-code staleness | three handed citations wrong (§3 correction block); `PHASE_3_MASTER_PLAN.md:37` says "a second channel already duplicates constants" while the tree contains exactly **one** Haven-owned `MethodChannel` (`channel_device_state.dart:25`) | Decisions made against a wrong map | appendix §12 proposes corrections; every future claim carries a checked file:line | FACT |
| R-9 | Fabricated DEMO capability flags read as device truth | `pairing_simulation_service.dart:115-122` sets granted flags and `battery_level: 95` | A capability inventory contradicting the ladder | label as simulation in-screen (§5 item 3) | FACT |
| R-10 | Kotlin test infrastructure still absent (P-5) | `STAGE_1_AUDIT_REPORT.md:178` row; no junit/Robolectric config found in the native tree this pass | No level-3 claim can be evidenced by tests | prerequisite before any new reader is added under D-4 | FACT(doc)/UNVERIFIED (build config not exercised) |

---

## 9. Owner approval checklist

**All three Phase-3 decisions are currently UNRECORDED** (`PHASE_3_MASTER_PLAN.md:36-38`, restated at `:89`).
Approvals needed, verbatim questions:

1. **D-3** — "Which pairing-code shape is canonical, and until when?" → choose option (i), (ii) or (iii) from the
   §2 table **or freeze**; and separately: "May `validatePairingCode`/`PairingCodeFormat` be exported from `haven_core`, and
   what happens to the legacy same-named validator at `validation.dart:70-80`?" — **UNRECORDED**
2. **D-3b** — "TTL 5 min (simulation) vs 10 min (`shared.ts:10`), and the absent attempt cap vs `MAX_ATTEMPTS_PER_CODE
   = 10` (`shared.ts:12`): which does Stage 2 document as the target, and does the simulation change?" —
   **UNRECORDED**
3. **D-4 scope** — "Does the channel-typing decision cover only `haven.dev/child_device_state`/`state.readAll`, or
   every future child-side native lane?" — **UNRECORDED**
4. **D-4 truth source** — "Is a Dart test allowed to assert Kotlin string keys as the enforcement mechanism, and
   which language file is authoritative when they disagree?" — **UNRECORDED**
5. **D-4 codegen** — "Is Pigeon/`build_runner` acceptable in this repo at all (no CI exists), and where does a
   child-side `android_native` package live, given the current parent-only `srcDir` at
   `apps/haven_app/android/app/build.gradle.kts:41`?" — **UNRECORDED**
6. **D-4 timing** — "Must the decision be approved before any Stage-2 channel code, or may it land during Stage 2?"
   — **UNRECORDED**
7. **D-5** — "Real parent↔child exchange: confirm BLOCKED (label-only simulation), or authorize a transport
   (backend Phase 4 / QR / BLE), and confirm that the DEMO capability flags at
   `pairing_simulation_service.dart:115-122` are labelled in-screen?" — **UNRECORDED**
8. **Dependency isolation** — "Option (a) new `haven_offline` package, (b) gated exports inside `haven_api`, or (c)
   document-and-keep — and is the split required before Stage 3 (`STAGE_1_AUDIT_REPORT.md:174`) or before Stage
   2?" — **UNRECORDED**
9. **Stage 2 authorization** — "Is the §7 brief approved as written, including its out-of-scope list and its
   ladder-2 ceiling?" — **UNRECORDED** (and until answered, Stage 2 stays not started: `PHASE_3_MASTER_PLAN.md:5`)
10. **Manifest-policy statement** — "Do capability claims cite the *source* manifest, the *merged* manifest, or
    both?" (needed because the two disagree — §5 item 5) — **UNRECORDED**
11. **Prerequisites P-2 / P-4** (named at `PHASE_3_MASTER_PLAN.md:89`) — "Are they satisfied, and by what evidence?"
    — **UNRECORDED**

Not asking the owner to decide in this packet: anything requiring a physical device, a deployed backend, or a git
action. — FACT (none was performed)

---

## 10. Capability inventory summary

Companion file: **`docs/implementation/phase_3/STAGE_2_ANDROID_CAPABILITY_INVENTORY.md`** (written this pass,
documentation-only). Highlights:

- **One channel, one method, five readers** — `haven.dev/child_device_state` / `state.readAll`, readers registered
  at `HavenBridge.kt:80-87`; **zero** EventChannels, **zero** BasicMessageChannel, **zero** Pigeon anywhere
  (greps this pass).
- **What genuinely has a native read today**: API level + OS release (`HavenBridge.kt:69-70`), app-ops usage-access
  mode (`MonitoringStateReader.kt:50-63`), battery-exemption/notification-importance/exact-alarm flags
  (`:31-43`), device-admin & encryption state (`DeviceAdminStateReader.kt:22-54`), location provider state without
  coordinates leaving the file (`LocationStateReader.kt:16-24`, `:36-44`), mic/camera presence
  (`CommunicationStateReader.kt:22-54`) — **all parent-side, none run on a device**.
- **`Build.MANUFACTURER`/`MODEL` are absent from all Kotlin** — the child renders `Unavailable` on purpose
  (`apps/haven_child/lib/core/device/real_device_information.dart:33-35`, `device_fact_rows.dart:18-26`).
- **No installed-app inventory, no `UsageStatsManager` counts, no battery level, no `ConnectivityManager`** in
  source; the data shapes for two of them already exist in shared packages
  (`haven_models` `device_models.dart:104-116`, `telemetry_models.dart:3-18`), so Stage 2 is closing a reader gap,
  not a model gap.
- **The child cannot compile the native lane** (`srcDir` redirect is parent-only,
  `apps/haven_app/android/app/build.gradle.kts:41`; child Kotlin is one 5-line activity), which is why D-4 must be
  answered before any child-side channel code.
- **Source manifest vs merged artifact disagree**: child source declares no permissions
  (`apps/haven_child/android/app/src/main/AndroidManifest.xml:2-8`) while its merged debug manifest declares
  INTERNET, WAKE_LOCK, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS and GCM permissions
  (`…/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16`).

---

## 11. Readiness verdict

**READY FOR OWNER DECISIONS**

Rationale: the baseline is verified with no tracked or staged drift (§1); every capability and bridge fact needed to
decide is documented with source citations (§10 and the companion inventory); and all three Stage-2 gates —
**D-3, D-4, D-5 — are unapproved** (`PHASE_3_MASTER_PLAN.md:36-38`), as is the dependency-isolation question (§6).
This is not **BLOCKED** — nothing prevents work once the answers arrive, and no experiment, build, device or
backend is required to answer the questions themselves. It is not **READY FOR STAGE 2 APPROVAL** — that verdict
would require approved decisions, and Stage 2 has **not** started (`PHASE_3_MASTER_PLAN.md:5`).

---

## 12. Appendix — proposed edits to `PHASE_3_MASTER_PLAN.md` (text only; **not applied**)

Contract rule: agents do not edit files outside their assigned paths, and this pass assigns only the two Stage-2
documents. The following are *proposals for the owner or a later authorized edit* —
`PHASE_3_MASTER_PLAN.md` was **not** modified by this agent (its size/mtime stayed `12,308 B / 12:59` across the
pass). — FACT

1. **Line 37 (D-4)** — replace "a second channel already duplicates constants" with:
   "exactly one Haven-owned `MethodChannel` exists (`apps/haven_app/lib/core/permissions/channel_device_state.dart:25`);
   the duplication is Kotlin↔Dart of that single channel's constants (`BridgeContract.kt:13-16` ↔
   `channel_device_state.dart:14-15`), defended only by one verbatim-string test
   (`apps/haven_app/test/permissions/channel_device_state_test.dart:38-43`)."
2. **Line 36 (D-3)** — append: "Backend shape is 8×30-symbol, not 6-digit
   (`backend/supabase/functions/_shared/identifiers.ts:24-25`, `:46-48`); `haven_core`'s narrowest charset
   (`packages/haven_core/lib/src/pairing_code.dart:34`) is 32 symbols and cannot express it; the backend is
   undeployed (`docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md:192`)."
3. **Line 38 (D-5)** — append: "Child has no pairing feature directory at all; 'Parent connection: Not connected'
   is a constant (`apps/haven_child/lib/core/session/child_local_session.dart:22-23`)."
4. **Line 54 (Stage 2 gate row)** — change "BLOCKED-pending-D-4/backend" to
   "BLOCKED-pending-D-3/D-4/D-5 approvals (all UNRECORDED)" and cite this packet.
5. **§7 blocked register (after line 84)** — add a row **B-6**: "Capability claims from merged Android manifests
   | plugin AARs contribute permissions the source manifests never declare
   (`apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16`)
   | owner answers the source-vs-merged manifest question (§9 item 10) and the §6 isolation decision".
6. **Line 89 (Next Action)** — replace "Await go-ahead for Stage 2" with "Stage 2 readiness documented and
   verified; awaiting recorded answers to D-3, D-4, D-5, dependency isolation, and the manifest-policy question
   (`STAGE_2_READINESS_AND_OWNER_DECISIONS.md` §9)".
7. **§6 deliverables list (header at line 73, body at line 75)** — add
   `STAGE_2_ANDROID_CAPABILITY_INVENTORY.md` and `STAGE_2_READINESS_AND_OWNER_DECISIONS.md` to the list of Stage-2
   documents so the 16-doc inventory stays complete.
8. **Citation hygiene note (new line after rule 1, which is at line 13)** — "A citation in a Phase-3 doc must have been read
   by the agent that wrote it; three handed citations failed this pass and are corrected in
   `STAGE_2_READINESS_AND_OWNER_DECISIONS.md` §3."
