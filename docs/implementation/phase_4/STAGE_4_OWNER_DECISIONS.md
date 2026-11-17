# HAVEN STAGE 4 — OWNER DECISION RECORD & PROPOSAL REGISTER

**Document Version:** 1.0.0-PROPOSED  
**Date:** November 17, 2026  
**Repository:** `D:\control`  
**Status:** AWAITING OWNER REVIEW & SIGN-OFF  
**Author:** Antigravity Engineering

---

## 1. Governance & Classification Model

Decisions governing HAVEN development are partitioned into three distinct classes:
- **Category A: Approved Decisions (Binding & Preserved)** — Previously authorized by the owner in Stages 1–3. These form the architectural foundation and cannot be altered without an explicit formal review.
- **Category B: Pending & Deferred Decisions** — Architectural items previously identified as blocked or deferred to a later phase (e.g. real pairing transport B-1, physical device handoff).
- **Category C: Newly Proposed Stage 4 Decisions** — Explicit architectural choices required specifically for Stage 4 implementation.

---

## 2. Category A: Approved Decisions (Binding & Active)

| ID | Title | Summary of Decision | Source / Precedent | Status |
|:---|:---|:---|:---|:---:|
| **D-1** | Child Application ID | Canonical namespace and applicationId is **`com.haven.child`**. | Stage 1 / `build.gradle.kts` | **ACTIVE** |
| **D-2** | Separate Gradle Project | `haven_child` owns its own hardened Gradle build; no source directory redirects into `haven_app`. | Stage 1 / `settings.gradle.kts` | **ACTIVE** |
| **D-3** | Pairing Code Grammar | Parent simulation remains 6-digit DEMO; backend proposal is 8-character Base30. | Stage 2 / `STAGE_2_OWNER_DECISIONS.md` | **ACTIVE** |
| **D-4** | Contract Ownership | Kotlin `UsageContract.kt` is the authoritative contract. Dart mirrors Kotlin. Cross-language agreement tests detect drift. | Stage 2 / Stage 3 Step 5 | **ACTIVE** |
| **D-5** | Real Pairing Boundary | Real cross-device pairing remains BLOCKED (B-1). Simulations must be visibly labelled DEMO. | Stage 2 / `STAGE_2_OWNER_DECISIONS.md` | **ACTIVE** |
| **D-dep** | Dependency Isolation | Option A adopted: `packages/haven_offline` extracted; child has zero cloud SDK dependencies. | Stage 3 Step 3 | **ACTIVE** |
| **D-hygiene** | Code Hygiene Rule | Strict $\le 200$ lines per handwritten file; handwritten fakes only (no Mockito/Mocktail). | System Contract | **ACTIVE** |
| **D-priv** | Usage Data Privacy | Child usage stats remain transient and in-memory only; no disk persistence. | Stage 3 Step 9 | **ACTIVE** |

---

## 3. Category B: Standing Deferred Items

| ID | Item | Reason Deferred | Path to Unblock |
|:---|:---|:---|:---|
| **B-1** | Real Parent-Child Pairing Transport | No backend deployed; no approved local rendezvous channel (Bluetooth / Local Wi-Fi). | Dedicated transport proposal in Phase 4. |
| **B-2** | Active App Blocking / Process Killing | Android consumer restrictions; blocking requires Device Owner provisioning (MDM). | Stage 5 Feasibility Audit (`ENFORCEMENT_FEASIBILITY_REPORT.md`). |
| **B-3** | Physical Device Verification (Realme RMX2161) | Hardware testing deferred until physical testing handoff is scheduled. | Dedicated hardware test lane. |
| **B-4** | Background Monitoring Daemons | Foreground services and wake locks deferred until background lifecycle stage. | Stage 7 Background Lifecycle. |

---

## 4. Category C: Newly Proposed Stage 4 Decisions

The owner is requested to review and decide upon the following four proposals before Stage 4 implementation begins:

### Decision 4.1: Pure-Dart Evaluation Scope
- **Question:** Should Stage 4 be strictly restricted to pure-Dart deterministic policy evaluation (calculating whether an app/device is restricted), with zero attempts at native app blocking?
- **Option A (Recommended):** **Yes, enforce strict separation.** Stage 4 builds only the pure-Dart evaluator. Active app suspension or blocking is deferred to Stage 5 feasibility.
- **Option B:** Attempt native app blocking immediately. *(Not recommended: risks severe Play Store policy violations and crashes on non-Device-Owner Android versions).*
- **Recommendation:** **Approve Option A.**

### Decision 4.2: Policy Model Canonical Placement
- **Question:** Where should `PolicyConfig`, `PolicySchedule`, and associated policy models reside?
- **Option A (Recommended):** **Lift to `packages/haven_models/`.** Both `haven_app` (parent) and `haven_child` depend on `haven_models`, ensuring shared serialization and eliminating duplicate models.
- **Option B:** Duplicate the policy models into `apps/haven_child/lib/features/policies/data/`. *(Not recommended: leads to drift and duplicate JSON serialization logic).*
- **Recommendation:** **Approve Option A.**

### Decision 4.3: Child Default Policy Source
- **Question:** Prior to real parent-child sync (B-1), what policy should the child device evaluate?
- **Option A (Recommended):** **Default canonical bedtime & school policy with local persistence in `haven_local.json`.** The child app persists a local `policy` section initialized with `PolicyConfig.defaults()`, allowing local customization or testing.
- **Option B:** Pure in-memory hardcoded policy only.
- **Recommendation:** **Approve Option A.**

### Decision 4.4: Honest Informational Disclaimer in Child UI
- **Question:** Must the child policy dashboard explicitly declare that policy evaluation is local and not actively blocking apps?
- **Option A (Recommended):** **Yes.** A status card must state: *"Policy evaluated locally. App blocking is not enforced on this build."* in accordance with `00-app-contract.md`.
- **Option B:** Omit disclaimer. *(Not recommended: dishonest to user).*
- **Recommendation:** **Approve Option A.**

---

## 5. Execution Authorization Gates

Stage 4 implementation will proceed only under explicit, granular owner authorization:

- **Gate 4-A:** Approval of Decisions 4.1–4.4 $\rightarrow$ Authorizes Step 1 (Canonical Models Extraction).
- **Gate 4-B:** Review of Step 1 Deliverables $\rightarrow$ Authorizes Steps 2–5 (Deterministic Evaluator & Precedence).
- **Gate 4-C:** Review of Evaluator Tests $\rightarrow$ Authorizes Steps 6–9 (Repository, Controller & UI).
- **Gate 4-D:** Review of UI & Routes $\rightarrow$ Authorizes Step 10 (Full Regression & Verification).

---

## 6. Strict Stop Statement

> [!IMPORTANT]
> **NO WORK HAS COMMENCED ON STAGE 4.**  
> Awaiting owner review, selection of options for Decisions 4.1–4.4, and explicit authorization for Step 1.
