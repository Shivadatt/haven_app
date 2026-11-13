# HAVEN PARENTAL CONTROL — PHASE 3 MASTER PLAN

**Scope**: Child Companion Android App — Native Capabilities & Parent-Child Integration  
**Date**: November 6, 2026 · **Last updated**: November 13, 2026 (Stage 2 approvals)  
**Status**: IN PROGRESS — Stage 0 complete ([STAGE_0_INSPECTION_VERIFICATION.md](file:///d:/control/docs/implementation/phase_3/STAGE_0_INSPECTION_VERIFICATION.md)); **Stage 1 complete with limitations** ([STAGE_1_IMPLEMENTATION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_IMPLEMENTATION_REPORT.md), [STAGE_1_AUDIT_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_AUDIT_REPORT.md)); **Stage 2 APPROVED 2026-11-13 — owner decisions recorded** ([STAGE_2_OWNER_DECISIONS.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_OWNER_DECISIONS.md)), **Stage 2 implementation COMPLETE WITH LIMITATIONS** ([STAGE_2_IMPLEMENTATION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_IMPLEMENTATION_REPORT.md))  
**Baseline protected**: 1,020/1,020 tests, 0 analyzer issues, 615 files / 0 line violations, offline isolation, Phase 2 sign-off PASS WITH LIMITATIONS  
**SDK**: FVM-pinned Flutter 3.44.6 / Dart 3.12.2 · AGP 9.0.1 · Kotlin 2.3.20 · Gradle 9.1.0 · compileSdk 36 / minSdk 24 / targetSdk 36

---

## 1. Ground Rules (inherited, non-negotiable)

1. `docs/implementation/00-app-contract.md` governs: ≤200-line hand-written files (applies to `.kt`), `blocked(...)`/`Unconfigured*` honest refusal vocabulary, no invented contracts, no cloud/backend access, **no agent git operations**, GetX everywhere.
2. Six-level completion ladder: UI → Flutter logic → Kotlin native → permission granted → physical-device verified → parent-child E2E. A module is only "COMPLETE" at the level actually evidenced.
3. Phase 2 simulation stays honest: the parent's 6-digit simulated pairing and Phase-2 banners remain; Phase 3 wraps/replaces child-side behavior, never retroactively claims the old simulation was real.
4. **Citation hygiene (added 2026-11-13)**: a citation in a Phase-3 doc must have been read by the agent that wrote it; three handed citations failed the Stage-2 readiness pass and are corrected in `STAGE_2_READINESS_AND_OWNER_DECISIONS.md` §3.
5. Nothing is presented as a physical-device result unless a device was attached and used (none is at plan time — emulator `Pixel_9a` only).

## 2. Target Structure

```
apps/haven_child/            # NEW Flutter+GetX app (mirrors haven_app layout 1:1)
  lib/app/{bindings,routes,theme}   # InitialBindings, AppRoutes/phase3_pages precedent, HavenTheme copy-or-share
  lib/core/{constants,storage,permissions,widgets}
  lib/features/{child_onboarding, child_pairing, child_status, child_usage,
                child_policy, child_location, child_events, child_settings}/
  android/                          # own manifest, Gradle, MainActivity + bridge attach
  test/                             # feature-mirrored, hand-written fakes, driver classes
android_native/child_services/      # EXISTING read-only probe — kept, extended via new readers/services
packages/haven_{core,models,api}    # path-dep reuse only; no breaking edits to parent contracts
docs/implementation/phase_3/        # 16 required deliverable docs (§6)
```

**Decision gates before their stage** (from Stage 0; **all five gates recorded 2026-11-13** in [STAGE_2_OWNER_DECISIONS.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_OWNER_DECISIONS.md)):
- **D-1** — **RESOLVED in Stage 1**: child `applicationId`/`namespace` = **`com.haven.child`**; `com.haven.familysafety` (out-of-repo Capacitor artifact) not reused. Evidence: [apps/haven_child/android/app/build.gradle.kts](file:///d:/control/apps/haven_child/android/app/build.gradle.kts#L10), asserted by the child architecture test.
- **D-2** — **RESOLVED in Stage 1**: `haven_child` owns a **separate Gradle project** (`android/settings.gradle.kts` includes only `:app`) mirroring the parent's hardening (AGP 9.0.1 / Kotlin 2.3.20 / Gradle 9.1.0 / Java 17 / build-dir redirect); no `srcDir` redirect into `android_native` and **no Kotlin native lane added yet**.
- **D-3** — **APPROVED 2026-11-13, option (ii)**: the 6-digit/5-min parent simulation stays unchanged and labelled DEMO; the backend shape is **8-char from a 30-symbol alphabet with TTL 10 min / max 10 attempts** (`backend/supabase/functions/_shared/identifiers.ts:24-25`, `:46-48`; `pairing/shared.ts:10-12`) — recorded as the **proposed Phase-4 target, not a verified canonical contract** (backend undeployed: `docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md:192`; `haven_core`'s narrowest charset `pairing_code.dart:34` is 32 symbols and cannot express it). `PairingCodeFormat`/`validatePairingCode` stay **unexported and unused**; the legacy same-named validator (`validation.dart:70-80`) is untouched pending a separate compatibility decision. Plaintext codes are never persisted or logged. P-2 is thereby resolved for Stage 2 documentation.
- **D-4** — **APPROVED 2026-11-13, option B**: standardised hand-written typed wrapper + an enforced **cross-language key-agreement test** covering every channel name, method name, envelope key, error code and section name; applies to the existing lane and future child-side lanes. **Kotlin contract constants are authoritative**; Dart mirrors them, tests detect drift. No Pigeon/`build_runner`. EventChannel deferred to the first genuinely-streaming lane. Correction (was stale): exactly **one** Haven-owned `MethodChannel` exists (`apps/haven_app/lib/core/permissions/channel_device_state.dart:25`); the duplication is Kotlin↔Dart of that single channel's constants (`BridgeContract.kt:13-16` ↔ `channel_device_state.dart:14-15`), previously defended by one verbatim-string test (`apps/haven_app/test/permissions/channel_device_state_test.dart:38-43`). Child-side native source integration must be separately scoped and tested (`srcDir` is parent-only, `apps/haven_app/android/app/build.gradle.kts:41`).
- **D-5** — **APPROVED 2026-11-13 — real cross-device pairing stays BLOCKED (B-1)**: Stage 2 delivers contracts + clearly labelled DEMO simulation only; no QR, BLE, file-based cross-sandbox exchange or backend pairing. Every fabricated capability value must be visibly labelled as simulated. Correction note: the child has no pairing feature directory at all; "Parent connection: Not connected" is a constant (`apps/haven_child/lib/core/session/child_local_session.dart:22-23`). P-4 stays blocked until an approved transport exists; simulation never counts as satisfying it.
- **D-dep** — **APPROVED 2026-11-13, option (c) for Stage 2**: keep the `haven_api` dependency (cloud plugins ship transitively into the child APK — `packages/haven_api/pubspec.yaml:13-15`, `:21` via `apps/haven_child/pubspec.yaml:21-22`) and document it; **before Stage 3** decide (a) new `haven_offline` package vs (b) gated exports inside `haven_api`, evidence-based. Never claim the child APK is free of cloud-related dependencies. Manifest policy: capability inventories distinguish source vs merged manifests; transitive plugin permissions recorded separately; source absence is never proof of merged absence.

## 3. Reuse Map (verified against barrels this session)

| Layer | Reuse as-is | Build new |
| :--- | :--- | :--- |
| haven_core | Result/failures/blocked, Clock, format+haversine, validators | nothing (export decision D-3 only) |
| haven_models | Device/DevicePolicy/UsageDaily/SafeZone/LocationEvent/DeviceCommand/Pairing* + all WireLabel enums (`ProfileRole.child` exists) | child-scoped view models (app-local per convention) |
| haven_api | offline engine (FileLocalStore/LocalTables/LocalSchema/OfflineHavenBackend), SecretVault/VaultDeviceIdentity, Unconfigured* | child-lane LocalUserAuth variant (role parameterized), device-credential registration |
| Parent app | route/binding/controller/test conventions, theme + shared components, PolicyConfig JSON shape, approval JSON contracts | child mirrors: pairing redeem screen, policy application, event writer; lift-vs-duplicate decision for approval_models |

## 4. Stage Plan (stages = brief §9; acceptance per stage before the next starts)

| Stage | Content | Key acceptance evidence | Prereqs |
| :--- | :--- | :--- | :--- |
| **1 — Child app foundation (A)** ✅ **COMPLETE WITH LIMITATIONS** (2026-11-06 — 167/167 child tests, 1,020/1,020 regression, 0 analyzer issues, 704 files / 0 line violations, child debug APK built; no native lane, no device run) | `apps/haven_child` scaffold, onboarding, profile/device-info/permission-dashboard screens, lifecycle, error/loading/empty states | child app `flutter analyze` 0 issues; widget/controller tests green; `flutter build apk --debug` for child APK; line-count 0 violations incl. new `.kt` | D-1, D-2 — both resolved in Stage 1 |
| **2 — Registration contracts + capability inventory (B, C)** 🟡 **APPROVED 2026-11-13 — in progress** | typed pairing redeem/registration state machine + contracts & tests (local), expiry/dup/unpair/audit; Android capability inventory doc | contract tests deterministic; real cross-device pairing **BLOCKED — confirmed by D-5** (no transport approved); inventory doc lists API levels + package-visibility plan, source vs merged manifests separated | D-3, D-4, D-5 — **all APPROVED** (`STAGE_2_OWNER_DECISIONS.md`) |
| **3 — Usage access + screen-time monitoring (D)** | usage-access explainer → settings nav → `UsageStatsManager` lane (Kotlin reader + EventChannel or poll), daily aggregation, per-app summaries | Kotlin unit tests (Robolectric, P-5); emulator-granted permission flow recorded; "delayed/incomplete data" states honest | P-5; device P-1 for FULL credit; **D-dep split decision (a) vs (b) recorded before this stage starts (D-4 §4 of `STAGE_2_OWNER_DECISIONS.md`)** |
| **4 — Policy evaluation engine (E)** | pure-Dart deterministic evaluator: daily/per-app limits, bedtime/school windows, overnight, tz-aware, priority/conflicts — independent of UI & native | mandated deterministic unit tests (normal/overnight/midnight/recurrence/conflict/expired/disabled/tz); no "enforced" claim from evaluator alone | Stage 2 models |
| **5 — Enforcement feasibility (F)** | written feasibility audit FIRST (usage-access limits, Accessibility restrictions, Device Owner requirements, Play policy, OEM) → implement ONLY transparent, approved, compliant path | `ENFORCEMENT_FEASIBILITY_REPORT.md`; likely outcome: blocking = device-owner-only → feature marked unavailable on consumer devices; overlay/kill decision documented before any code | Stage 3–4 reality |
| **6 — Location + safe-zones (G)** | permission-based location via documented abstraction (framework `LocationManager` precedent keeps the no-coords-on-state-channel policy), last-known + accuracy + entry/exit + dedupe + disable flow | emulator permission-denied/approximate/precise/revoked/disabled matrix; disclosure visible; no fabricated fixes | P-1 (partial via emulator) |
| **7 — Background lifecycle (H)** | foreground service w/ persistent notification + declared `foregroundServiceType`, stop/recovery, reboot only where permitted, battery-optimization disclosures | service lifecycle tests on emulator; WorkManager NOT used as realtime substitute; no "guaranteed indefinitely" claims | D/G service needs |
| **8 — Child dashboard + events (J, I)** | real status/permission/usage/policy/zone panels, local event & audit store (dedupe, retention, clear), labelled-DEMO isolation | dashboard shows only real-or-labelled data; events persisted to child `haven_local.json`; tests green | Stages 3–7 outputs |
| **9 — Parent integration contracts (K)** | shared-contract docs + typed compatibility (device model, registration status, usage summary, policy sync, zone events, capability status, error states); no cloud sync; no schema break | `PARENT_INTEGRATION_CONTRACTS.md`; Phase 2 regression proves no parent breakage; any unmet real channel = BLOCKED boundary documented | Stages 2–8 |
| **10 — Full regression + device matrix** | rerun 1,020 baseline + child suites; emulator (and device if attached) matrix; finalize 16 docs; verdict | per brief §10 acceptance list | all |

**Parallelism rule**: only audits/tests/docs run concurrently; no parallel edits to shared files (this plan file and phase_2 docs are frozen during implementation).

## 5. Testing Strategy

- **Flutter**: feature-mirrored tests, `widgetHost`-style harness through real theme, hand-written fakes only (no mocktail), drivers per page; child app gets its own `analysis_options.yaml` (flutter_lints + `prefer_initializing_formals: false`).
- **Kotlin**: introduce junit + Robolectric (P-5) — labelled as **mocked unit tests**; API-level matrices for 24/29/31/33/36 guards.
- **Physical/emulator**: separate lane; every row of DEVICE_VERIFICATION_MATRIX records model, API, steps, expected vs actual, evidence path; unrun rows say `NOT TESTED`.
- **Regression gates**: Phase 1/2 suites (1,020) re-executed at Stages 1, 3, 6, 8, 10 minimum.

## 6. Documentation Deliverables (`docs/implementation/phase_3/`)

All 16 required docs listed in the brief; produced at the stage they certify. Already created: `PHASE_3_MASTER_PLAN.md`, `STAGE_0_INSPECTION_VERIFICATION.md` (inspection evidence style follows Phase 2 FINAL_VERIFICATION_REPORT conventions; raw logs in `_scratch/p3_inspect/` and future `_scratch/p3v_*/`). **Stage 1 added 9 more** in this directory: `STAGE_1_IMPLEMENTATION_REPORT.md`, `CHILD_APP_ARCHITECTURE.md`, `CHILD_ONBOARDING_FLOW.md`, `CHILD_LOCAL_STORAGE_CONTRACT.md`, `CHILD_PERMISSION_DASHBOARD.md`, `STAGE_1_FEATURE_MATRIX.md`, `STAGE_1_TEST_RESULTS.md`, `STAGE_1_KNOWN_LIMITATIONS.md`, `STAGE_1_AUDIT_REPORT.md`. **Stage-2 readiness pass added 3**: `STAGE_2_ANDROID_CAPABILITY_INVENTORY.md`, `STAGE_2_READINESS_AND_OWNER_DECISIONS.md`, `STAGE_2_OWNER_DECISIONS.md` (decision record, 2026-11-13).

## 7. Standing BLOCKED Register (pre-declared, per brief honesty rules)

| ID | Item | Blocking dependency | Unblock path |
| :--- | :--- | :--- | :--- |
| B-1 | Real parent-phone ↔ child-phone pairing | no backend / no approved rendezvous channel | Phase 4 backend or approved local transport (D-5) |
| B-2 | Consumer-device app blocking/killing without Device Owner | Android platform + Play policy | feasibility gate (Stage 5) documents approved scope only |
| B-3 | Physical Realme RMX2161 verification rows | no device attached | device handoff; until then `NOT TESTED` |
| B-4 | Continuous background location on OEM-restricted ROMs | ColorOS battery policies | foreground-service disclosure + honest reliability limits |
| B-5 | Committing Phase 2 sign-off docs | app-contract forbids agent git ops | owner action |
| B-6 | Capability claims from merged Android manifests | plugin AARs contribute permissions the source manifests never declare (`apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16` vs the permission-free source manifest) | **policy recorded 2026-11-13** (`STAGE_2_OWNER_DECISIONS.md` §5): inventories must cite source and merged manifests separately; underlying transitive-dependency removal awaits the pre-Stage-3 D-dep decision |

## 8. Next Action

Stage 1 — Child app foundation is **complete with limitations** (verdict and evidence: [STAGE_1_AUDIT_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_AUDIT_REPORT.md)); D-1 and D-2 were resolved inside it, and its known limitations — no Kotlin/native lane, `Unavailable` device model/manufacturer, zero permission reads, no emulator or device run, transitive `firebase_auth`/`firebase_core` via `haven_api` — are carried forward, not hidden. **Stage 2 is APPROVED** (2026-11-13): D-3 (option ii), D-4 (option B), D-5 (real pairing BLOCKED, confirmed), dependency isolation (option c for Stage 2, split decision due before Stage 3) and the source-vs-merged manifest policy are recorded in `STAGE_2_OWNER_DECISIONS.md`; P-2 is resolved for Stage-2 documentation, P-4 remains blocked until an approved transport exists. Stage 2 delivers registration-protocol contracts + clearly labelled DEMO simulation only, evidence ceiling ladder level 2, no Phase 1/2 behavior changes. **Stage 2 is now implemented** — verdict **COMPLETE WITH LIMITATIONS**, with per-gate evidence, the D-4 drift experiment and the source/merged/transitive manifest layering in [STAGE_2_IMPLEMENTATION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_IMPLEMENTATION_REPORT.md) and [STAGE_2_ANDROID_CAPABILITY_INVENTORY.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_ANDROID_CAPABILITY_INVENTORY.md) §7. Measured baseline after Stage 2: child **251** + parent **943** + `haven_api` **66** + `haven_core` **18** + `haven_models` **12** = **1,290** tests, 0 failures, 0 skips; analyzers `No issues found!` on both apps; line-count **740 files / 0 violations**; both debug APKs built (child `ae671f4e…47ae` byte-identical to pre-Stage-2, parent `8645266a…3ac9`). **Stage 3 has NOT started and is NOT authorized**; it still requires the (a) `haven_offline` vs (b) gated-exports dependency decision and an approved transport for P-4. Await owner review and independent verification before any Stage 3 request.
