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

## 5. Stage 4 Step 2 Confirmed Owner Decisions (Decisions 2.28 & 2.29)

The owner has formally confirmed the following architectural decisions for Stage 4 Step 2 Sub-step 2.4:

### Decision 2.28: Emergency Package vs Per-App Limits — APPROVED OPTION A
- **Contract:**
  1. The five immutable emergency packages (`com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`) are exempt from active schedule restrictions.
  2. They are exempt from global daily quota restrictions.
  3. They are also exempt from explicit per-app time limits configured through `PolicyConfig.appLimits`.
  4. Parent `blockedApps` remains the highest-priority hard veto. An emergency package present in the parent blocklist must be evaluated as `blockedByParent`.
  5. Unknown packages must not receive emergency exemptions.
  6. No configurable emergency package injection or additional emergency package identifiers may be introduced.
- **Precedence:** Parent blocklist first; emergency exemption immediately afterward.
- **Conflict Matrix (C-09):** Emergency package wins over per-app limit unless parent-blocklisted.

### Decision 2.29: Snapshot Date Mismatch — APPROVED OPTION A
- **Contract:**
  When `PolicyUsageSnapshot.isSameLocalDate(context.evaluationTime, usage.snapshotDate)` is false:
  1. Global daily usage is unavailable for evaluation.
  2. Per-app usage is also unavailable for evaluation.
  3. `DailyQuotaEvaluation.isUnavailable` must reflect unavailable global usage when a finite quota requires usage measurement.
  4. `DailyQuotaEvaluation.usedMinutes` must be null when global usage is invalidated by the date mismatch.
  5. Per-app usage lookups must resolve to null rather than using stale usage from the previous date.
  6. Neither global nor per-app limits may be falsely reached using stale previous-day measurements (fail-safe unblocked).
  7. Do not convert unavailable usage to zero.
  8. Preserve existing Decision 2.16 missing-usage semantics.
  9. Preserve telemetry completeness, permission, and freshness disclosures.
  10. Do not add per-package timestamps, intervals, or schema fields. Such metadata is outside this approved decision and Sub-step 2.4 scope.
- **Reason:** `totalForegroundMillis` and `appForegroundMillis` share the same observation interval, while per-package usage has no independent date or interval metadata. Evaluating previous-day app usage against the current day's quota could falsely restrict an application.

---

## 6. Stage 4 Step 5 Confirmed Owner Decisions (Decisions 5.1–5.4)

The project owner formally approved and ratified all Option A decisions on **November 24, 2026** against checkpoint `6ae46f567de4772d3252215b19e5302a3d255071`:

### Decision 5.1: Dedicated `WebPolicyEvaluator` — APPROVED OPTION A
- **Contract:**
  1. Web domain filtering is encapsulated within a dedicated, standalone pure-Dart `WebPolicyEvaluator` engine.
  2. Produces separate, defensively immutable `WebEvaluationResult` and `DomainEvaluation` models.
  3. Zero coupling to Android `USAGE_STATS` foreground telemetry or application policy evaluation.
  4. Zero breaking changes to `PolicyEvaluator.evaluate()` or `PolicyEvaluationResult`.
  5. Every handwritten source and test file must strictly remain $\le 200$ physical lines.

### Decision 5.1-S1: Blocked-Domain Absolute Hard Veto — APPROVED OPTION A
- **Contract:**
  1. `blockedDomains` takes absolute precedence over `allowedDomains`.
  2. If a domain is listed or matched in both `blockedDomains` and `allowedDomains`, it resolves strictly as `DomainPolicyStatus.blockedByParent` with reason `'Blocked by parent'`.
  3. Parent web blocklist acts as an unconditional hard veto, mirroring Level 1 `blockedApps`.

### Decision 5.1-S2: DNS-Label-Boundary Subdomain Inheritance — APPROVED OPTION A
- **Contract:**
  1. A configured domain rule matches the exact domain and any subdomains adhering to strict DNS label boundaries (e.g. `example.com` matches `example.com` and `sub.example.com`, but strictly rejects substring collisions like `badexample.com`).
  2. Allowing `sub.example.com` does not implicitly allow the root domain `example.com`.
  3. Hostnames must be normalized prior to evaluation (trimmed, lowercased, stripped of trailing dots, URI schemes, paths, and port numbers).

### Decision 5.2-1: Additive Screen-Time Extensions — APPROVED OPTION A
- **Contract:**
  1. The effective daily screen-time quota is the base daily quota plus the sum of all valid, granted extensions for the child's local calendar day:
     $$effectiveDailyLimit = dailyScreenTimeMinutes + \sum grantedMinutes$$
  2. Multiple extensions granted on the same calendar day accumulate additively.

### Decision 5.2-2: Bedtime Absolute Supremacy — APPROVED OPTION A
- **Contract:**
  1. Bedtime schedule restrictions maintain absolute supremacy over screen-time extensions (Level 3 schedule vs Level 5 quota modifier).
  2. Active Bedtime locks down non-emergency applications regardless of remaining extension minutes. Extensions modify quota only and cannot punch through schedule restrictions.

### Decision 5.2-3: Local-Midnight Expiration — APPROVED OPTION A
- **Contract:**
  1. All screen-time extensions strictly expire at the child device's exclusive local calendar-day boundary (`00:00:00` of the next local day).
  2. Extensions do not carry over across midnight. At the start of the next local calendar day, the effective quota resets to the new day's base quota.

### Decision 5.2-4: Global Daily Quota-Only Scope — APPROVED OPTION A
- **Contract:**
  1. Screen-time extensions apply exclusively to the global daily screen-time quota.
  2. Extensions do not modify explicit per-app limits configured in `PolicyConfig.appLimits`.

### Decision 5.3: Defer Category Limits to Stage 6 — APPROVED OPTION A
- **Contract:**
  1. `PolicyConfig.appLimits` remains strictly concrete package-based (`Map<String, int>`).
  2. Application category limits, category taxonomies, and multi-package usage aggregation are formally deferred to Stage 6 Advanced Filtering.

### Decision 5.4: Single Primary Application Status — APPROVED OPTION A
- **Contract:**
  1. `AppEvaluation` preserves exactly one authoritative application status (`status`) and reason (`reason`) determined by the 7-level waterfall cascade.
  2. Device-wide coexisting warnings remain exposed through `PolicyEvaluationResult.secondaryReasons`. No secondary reason collections are added to individual app records.

---

## 7. Execution Authorization Gates

Stage 4 implementation proceeds only under explicit, granular owner authorization:

- **Gate 4-A:** Approval of Decisions 4.1–4.4 $\rightarrow$ Authorizes Step 1 (Canonical Models Extraction) [CLOSED].
- **Gate 4-B:** Review of Step 1 Deliverables $\rightarrow$ Authorizes Steps 2–4 (Deterministic Evaluator & Policy UI) [CLOSED].
- **Gate 4-C:** Approval of Decisions 5.1–5.4 $\rightarrow$ Authorizes Step 5 Sub-Step 5.2 (Specification Synchronization) [ACTIVE].
- **Gate 4-D:** Review of Step 5 Specifications $\rightarrow$ Authorizes Step 5 Sub-Step 5.3+ (Precedence Engine & Tests) [PENDING OWNER APPROVAL].

---

## 8. Strict Stop Statement

> [!IMPORTANT]
> **SUB-STEP 5.2 SPECIFICATION AUTHORIZATION ONLY.**  
> Zero production implementation, test creation, database migrations, cloud configuration, or Git mutations are authorized. Implementation will commence only after formal owner review and sign-off on Sub-Step 5.2 specifications.
