# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2: OWNER DECISION RECORD

**Date recorded**: November 13, 2026
**Source of authority**: owner message of 2026-11-13 reviewing
`STAGE_2_READINESS_AND_OWNER_DECISIONS.md` (the packet; §9 checklist) and
`STAGE_2_ANDROID_CAPABILITY_INVENTORY.md`. Every item below is the owner's
recorded decision — label **APPROVED** unless stated otherwise. Nothing in this
file authorizes Stage 3.

## 1. D-3 — Pairing code (packet §9 items 1–2)

**APPROVED — option (ii).**

1. The existing 6-digit / 5-minute parent pairing simulation stays **unchanged**
   and explicitly labelled DEMO
   (`apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart:22-24`).
2. 8-character / 30-symbol shape, `CODE_TTL_MINUTES = 10`
   (`backend/supabase/functions/pairing/shared.ts:10`) and
   `MAX_ATTEMPTS_PER_CODE = 10` (`shared.ts:12`) are recorded as the
   **proposed Phase-4 backend target — NOT a verified canonical contract**
   (the backend text is self-labelled re-authored, and staging has 0 deployed
   functions — `docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md:192`).
3. `PairingCodeFormat` / `validatePairingCode`
   (`packages/haven_core/lib/src/pairing_code.dart`) are **NOT exported and NOT
   used** until a spec is verified from a deployed backend.
4. The legacy same-named validator
   (`packages/haven_core/lib/src/validation.dart:70-80`) is **not changed or
   merged** without a separate documented compatibility decision.
5. **Never** persist or log plaintext pairing codes (contract rule,
   `docs/implementation/00-app-contract.md:108-109`; risk R-1).

## 2. D-4 — Native channel (packet §9 items 3–6)

**APPROVED — option B: standardised hand-written typed wrapper.**

1. A **cross-language key-agreement test** covers every channel name, method
   name, envelope key, error code and section name.
2. The standard applies to the **existing channel**
   (`haven.dev/child_device_state` / `state.readAll`;
   `android_native/child_services/platform_bridge/BridgeContract.kt` ↔
   `apps/haven_app/lib/core/permissions/channel_device_state.dart`) **and every
   future child-side native lane.**
3. **Kotlin contract constants are authoritative** for Android-native channel
   definitions; Dart mirrors them and tests must detect drift.
4. **No Pigeon, no `build_runner`.**
5. Any child-side native source integration must be **separately scoped and
   tested** (the current `srcDir` redirect is parent-only,
   `apps/haven_app/android/app/build.gradle.kts:41`).
6. D-4 approval (this record) is the gate required before new channel code.

## 3. D-5 — Parent-child exchange (packet §9 item 7)

1. **Real cross-device pairing remains BLOCKED** (B-1,
   `PHASE_3_MASTER_PLAN.md` §7). No transport authorized.
2. Stage 2 may provide **contracts + clearly labelled DEMO simulation only**.
3. Every fabricated capability value must be **visibly labelled as simulated**
   (covers `pairing_simulation_service.dart:115-122`; risk R-9).
4. Stage 2 must **not** implement QR, BLE, file-based cross-sandbox exchange,
   or backend pairing.

## 4. Dependency isolation (packet §9 item 8)

1. **APPROVED — option (c) for Stage 2**: retain the `haven_api` dependency and
   document its limitations.
2. **Before Stage 3**, prepare a separate evidence-based decision between
   option (a) a new `haven_offline` package and option (b) gated API entry
   points inside `haven_api`. Gate added to the Stage 3 row of the master plan.
3. **Do not claim the child APK is free of cloud-related dependencies**
   (`packages/haven_api/pubspec.yaml:13-15`, `:21`;
   `apps/haven_child/pubspec.yaml:21-22`).

## 5. Manifest policy (packet §9 item 10)

1. Every capability inventory must **distinguish source manifests from merged
   build manifests**.
2. Permissions contributed by **transitive plugin dependencies** are recorded
   separately (observed: child source declares none
   (`apps/haven_child/android/app/src/main/AndroidManifest.xml`) while its
   merged debug manifest carries INTERNET / WAKE_LOCK /
   ACCESS_NETWORK_STATE / POST_NOTIFICATIONS / GCM permissions
   (`apps/haven_child/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml:11-16`)).
3. **Absence in the source manifest is never described as proof** that the
   merged APK lacks the permission.

## 6. Stage 2 authorization (packet §9 item 9)

**APPROVED — the §7 brief as written**, including its explicit out-of-scope
list (real pairing, permission grants, monitoring/enforcement, foreground
services, background location, installed-app enumeration, UsageStatsManager
counts, battery level, network state, physical-device claims).

Evidence ceiling: **ladder level 2 (Flutter logic)** maximum; existing
parent-side native code may be described only at its previously evidenced
**level 3-partial, parent-side, host-mocked** status. No physical-device,
permission-grant, real-pairing or parent-child E2E claims without
corresponding evidence.

## 7. Prerequisites (packet §9 item 11)

1. **P-2: RESOLVED for Stage 2 documentation** through the D-3 decision above,
   while retaining the DEMO-vs-Phase-4-target distinction.
2. **P-4: real exchange remains BLOCKED** until an approved transport exists
   (D-5). A blocked prerequisite is **not** treated as satisfied by simulation.

## 8. Execution restrictions (standing)

- Preserve existing Git HEAD, index and all staged/unstaged work; **no agent
  Git operations**; no cloud/backend access; no Supabase CLI; no Firebase CLI.
- Do not modify Phase 1 or Phase 2 functionality (the only authorized Stage-2
  touch into parent surfaces is the additive, minimal DEMO labelling of
  fabricated capability values required by §3 item 3 and the D-4 agreement
  tests — behaviour must not change).
- Follow `docs/implementation/00-app-contract.md`: ≤200-line hand-written
  sources, `blocked(...)`/`Unconfigured*` vocabulary, GetX conventions,
  hand-written fakes, existing test rules.

## 9. Files updated by this record

- Created: this file.
- Updated: `PHASE_3_MASTER_PLAN.md` (status line, D-gate block, Stage 2/3
  prereq rows, B-6 register row, deliverables list, citation-hygiene rule,
  Next Action) — the packet §12 proposed edits are now applied, since the
  underlying decisions are recorded.
