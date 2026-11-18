# HAVEN STAGE 4 — STEP 2 SUB-STEP 2.1 PRE-IMPLEMENTATION AUDIT
## Evaluation Quota Input Contracts & Tri-State Boundary

**Document Version:** 1.3.0-FINAL-MICRO-CORRECTED  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Current Reported HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Target Milestone:** Stage 4 Step 2 — Sub-step 2.1  
**Status:** FINAL SPECIFICATION READY — AWAITING OWNER IMPLEMENTATION AUTHORIZATION  
**Execution Mode:** STRICT READ-ONLY PRE-IMPLEMENTATION AUDIT  
**Implementation Authorization:** NOT GRANTED  

---

## 1. Executive Summary & Git Preflight

### 1.1 Scope of Sub-Step 2.1
Sub-step 2.1 establishes the pure-Dart evaluator quota input contract and compatibility boundary for **Stage 4 Step 2: Pure-Dart Deterministic Policy Evaluation Engine**.
This document reconciles all thirteen owner decisions (Decisions 2.1 through 2.13), with specific focus on:
1. **Decision 2.12 (Emergency Package Encapsulation & Pure Query Helper):** The five-package constant is strictly private (`_defaultEmergencyPackages`). It is **never** exposed as a public constant, public getter, or constructor parameter. A public static query helper `isEmergencyPackage(String)` is provided for evaluator queries.
2. **Decision 2.13 (Quota Override Validation Contract):** Disentangles persistent model authoring validation (`PolicyRules.validateMinutesLimit`) from transient evaluation override validation. Evaluator overrides strictly reject negative values (`override < 0`) with `ArgumentError.value`, with **no artificial 1440-minute ceiling** imposed on evaluation overrides.

### 1.2 Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`
- **Git Status:**
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_EXECUTION_PLAN.md` (v1.4.0 execution plan)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md` (Staged audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_PLAN_VALIDATION_AUDIT.md` (Staged validation audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_READINESS_AUDIT.md` (Staged readiness audit)
  - `AM docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_1_PREIMPLEMENTATION_AUDIT.md` (Updated specification)
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Authoritative Register of Thirteen Owner Decisions (2.1–2.13)

| # | Topic | Approved Option | Core Architectural Contract |
|:---:|:---|:---:|:---|
| **2.1** | **Parent Whitelist vs Global Quota** | **Option A** | `PolicyConfig.allowedApps` bypasses global daily quota only. Does not bypass blocklist, active schedules, or per-app limits. |
| **2.2** | **Emergency Package Defaults** | **Option A** | Exactly five immutable packages: `com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`. Excludes `com.android.server.telecom`. |
| **2.3** | **Global Daily Limit Semantics** | **Option A** | `0` = zero minutes allowed. `null` = unlimited. Positive integer = configured quota. |
| **2.4** | **Parent Blocklist vs Parent Whitelist** | **Option A** | `blockedApps` takes absolute precedence over `allowedApps`. |
| **2.5** | **Parent Whitelist vs Per-App Limit** | **Option A** | Explicit `appLimits` entries take precedence over parent whitelist. |
| **2.6** | **Overlapping Schedules** | **Option A** | Restrictive intersection ($\bigcap s.\text{allowedApps}$). Empty whitelist = zero exceptions. |
| **2.7** | **Nullable Canonical Model Schema** | **Option A** | Future migration of `PolicyConfig.dailyScreenTimeMinutes` to `int?` approved in principle, but deferred per Decision 2.9. |
| **2.8** | **Parent Blocklist vs Schedule Whitelist** | **Option A** | Parent `blockedApps` is a hard veto over schedule `allowedApps`. |
| **2.9** | **Two-Phase Nullable Migration** | **Option A** | In Step 2, keep `PolicyConfig.dailyScreenTimeMinutes` as `int`. Evaluator supports nullable `dailyLimitMinutesOverride`. Persistent model migration deferred to Step 7/8. |
| **2.10** | **Parent Blocklist vs Emergency Defaults** | **Option A** | Parent `blockedApps` takes precedence even over emergency defaults. Emergency exemption applies strictly *after* checking parent blocklist. |
| **2.11** | **Schedule Whitelist vs Bedtime** | **Option A** | Restrictive intersection wins; schedule whitelists cannot override active Bedtime restrictions; empty Bedtime whitelist yields empty intersection ($\emptyset$). |
| **2.12** | **Emergency Package Immutability & Visibility** | **Option A** | **Zero test seam injection. Private static constant.** Exactly the five approved emergency defaults (`_defaultEmergencyPackages`). No public constant, no public collection getter, no custom injection parameters. Exposed solely via a static boolean query helper `isEmergencyPackage(String)`. |
| **2.13** | **Maximum Daily Quota & Override Parity** | **Option A** | Reject negative quota values (`< 0`) via `ArgumentError.value`. Evaluator overrides are **not** subject to an artificial 1440-minute ceiling unless verified existing business rules require it. Existing 1440 max applies strictly to persistent `PolicyConfig` authoring validation. Zero remains valid (0 minutes). Null remains valid (unlimited). |

---

## 3. Decision 2.12 Audit: Private Encapsulation & Query Helper

### 3.1 Flaws of `@visibleForTesting` and Public Collection Exposure
A strict access-control and encapsulation review reveals that exposing the emergency package set either through `@visibleForTesting` constructors or public static constants introduces architectural vulnerabilities:
1. **`@visibleForTesting` Does Not Restrict Access:** `@visibleForTesting` is purely a static analysis lint annotation; in compiled Dart release builds, it performs zero runtime access checks. A named constructor annotated with `@visibleForTesting` remains fully callable by production code.
2. **Public Constant / Getter Leaks Configuration:** Declaring `static const Set<String> defaultEmergencyPackages` or exposing a public getter publishes internal implementation details, inviting callers to depend on or iterate over internal package lists.
3. **Mutable Ingestion Risk:** Permitting caller injection of collections invites runtime mutation or inconsistency.

### 3.2 Approved Design: Private Constant + Pure Query Helper
To guarantee complete encapsulation, zero production bypass, and absolute immutability:
1. The five-package identifier set is declared strictly **private**:
   ```dart
   static const Set<String> _defaultEmergencyPackages = {
     'com.android.phone',
     'com.google.android.dialer',
     'com.samsung.android.dialer',
     'com.android.emergency',
     'com.google.android.apps.safetyhub',
   };
   ```
2. The `Set` is **never exposed** through a public constant or public getter.
3. Callers and the policy evaluation engine query emergency membership strictly through a public static query helper:
   ```dart
   static bool isEmergencyPackage(String packageName) =>
       _defaultEmergencyPackages.contains(packageName);
   ```
4. **Zero Injection Seam:** No injection constructor exists. Unit tests directly verify the query helper and test precedence using the canonical package strings.

---

## 4. Decision 2.13 Audit: Quota Validation & 1440-Minute Evidence

### 4.1 Inspection of Call Sites & Repository Evidence
An exhaustive audit of all occurrences of `validateMinutesLimit` and `1440` in the repository was conducted:

1. **`packages/haven_models/lib/src/policy_rules.dart` (lines 51–57):**
   ```dart
   static String? validateMinutesLimit(int? minutes, {int max = 1440}) {
     if (minutes == null) return 'Limit is required.';
     if (minutes < 0 || minutes > max) {
       return 'Limit must be between 0 and $max minutes.';
     }
     return null;
   }
   ```
2. **`packages/haven_models/lib/src/policy_config.dart` (line 109):**
   ```dart
   final timeErr = PolicyRules.validateMinutesLimit(dailyScreenTimeMinutes);
   if (timeErr != null) return timeErr;
   ```
3. **`apps/haven_app/lib/features/policies/controllers/policies_controller.dart` (lines 69–77):**
   ```dart
   Future<bool> updateDailyLimit(int minutes) async {
     final err = PolicyRules.validateMinutesLimit(minutes);
     if (err != null) { ... return false; }
     ...
   }
   ```
4. **`apps/haven_app/lib/features/policies/controllers/app_limits_controller.dart` (line 98):**
   ```dart
   final err = PolicyRules.validateMinutesLimit(minutes, max: 1440);
   ```
5. **`apps/haven_app/lib/features/policies/views/widgets/screen_time_card.dart` (line 34):**
   `Slider(value: minutes.toDouble().clamp(0, 1440), min: 0, max: 1440, ...)`

### 4.2 Distinguishing Persistent Model Validation from Evaluator Override
- **Persistent Model Scope (`PolicyConfig`):**
  The existing 1440-minute limit represents the total minutes in a 24-hour day (`24 * 60 = 1440`). It is enforced when a parent *authors and saves* a policy into local persistence or Postgres.
- **Evaluator Override Scope (`dailyLimitMinutesOverride`):**
  `dailyLimitMinutesOverride` is a runtime parameter passed to `PolicyEvaluationContext`. There is **zero existing repository evidence** that an evaluation override is contractually bound to 1440 minutes. For example, a simulation, automated grant, or multi-day evaluation test may evaluate against values $> 1440$.
- **Decision 2.13 Rule:**
  *"Reject negative quota values. Do not impose a new maximum of 1440 minutes unless existing verified model/business validation already requires it. Inspect actual repository validation and document the evidence. Do not invent a new upper limit."*

### 4.3 Final Override Validation Contract
- **Negative Rejection:** `override < 0` is strictly rejected with `ArgumentError.value(override, 'dailyLimitMinutesOverride', 'Daily limit override cannot be negative.')`.
- **Zero Permitted:** `override == 0` means zero minutes permitted (immediately reached/exceeded).
- **Null Permitted:** `override == null` (with `hasDailyLimitOverride == true`) means unlimited quota.
- **Positive Quotas:** Any positive integer `override > 0` is accepted without an artificial upper bound constraint.

---

## 5. Tri-State Quota Contract Specification

The evaluator input context defines:

```dart
final int? dailyLimitMinutesOverride;
final bool hasDailyLimitOverride;
```

### 5.1 Evaluation of the Five Contract States

| State | `hasDailyLimitOverride` | `dailyLimitMinutesOverride` | Resolved Effective Limit | Semantic Meaning & Behavior |
|:---:|:---:|:---:|:---:|:---|
| **A** | `false` | `null` (or ignored) | `config.dailyScreenTimeMinutes` | **No Override:** Evaluator falls back directly to the non-nullable quota in `config`. Existing parent model is 100% preserved. |
| **B** | `true` | `null` | `null` | **Explicit Unlimited (Decision 2.3):** No daily screen time cap. Quota evaluation reports `isUnlimited: true`, `isReached: false`. |
| **C** | `true` | `0` | `0` | **Explicit Zero Minutes (Decision 2.3):** Zero minutes permitted. Immediately marked `isReached: true` (or exceeded if usage $>0$). |
| **D** | `true` | `60` (positive) | `60` | **Explicit Quota:** Replaces config with 60-minute limit. Evaluated against total usage. Any positive integer is valid. |
| **E** | `true` | `-1` (negative) | `ArgumentError` thrown | **Invalid Input (Decision 2.13):** Precondition failure. Throws `ArgumentError.value`. Never clamped to zero; never interpreted as unlimited. |

---

## 6. Recommended Implementation Specification

### 6.1 Target File: `packages/haven_models/lib/src/policy_evaluator/policy_evaluation_context.dart`

```dart
import 'package:meta/meta.dart';
import '../policy_config.dart';

/// Immutable context supplied to the pure-Dart policy evaluator.
@immutable
final class PolicyEvaluationContext {
  /// Standard production constructor.
  /// Fully encapsulated with zero emergency package injection parameters.
  const PolicyEvaluationContext({
    required this.config,
    required this.evaluationTime,
    this.dailyLimitMinutesOverride,
    this.hasDailyLimitOverride = false,
  });

  /// Production factory creating a context with an explicit unlimited daily quota.
  factory PolicyEvaluationContext.withUnlimitedQuota({
    required PolicyConfig config,
    required DateTime evaluationTime,
  }) => PolicyEvaluationContext(
    config: config,
    evaluationTime: evaluationTime,
    dailyLimitMinutesOverride: null,
    hasDailyLimitOverride: true,
  );

  /// Production factory creating a context with an explicit quota override in minutes.
  /// Rejects negative values per Decision 2.13.
  factory PolicyEvaluationContext.withQuotaOverride({
    required PolicyConfig config,
    required DateTime evaluationTime,
    required int minutes,
  }) {
    if (minutes < 0) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Daily limit override cannot be negative.',
      );
    }
    return PolicyEvaluationContext(
      config: config,
      evaluationTime: evaluationTime,
      dailyLimitMinutesOverride: minutes,
      hasDailyLimitOverride: true,
    );
  }

  /// The active policy configuration to evaluate against.
  final PolicyConfig config;

  /// Injected timestamp for deterministic evaluation (no DateTime.now()).
  final DateTime evaluationTime;

  /// Optional override for daily screen time limit in minutes.
  final int? dailyLimitMinutesOverride;

  /// Whether an explicit caller override is active.
  final bool hasDailyLimitOverride;

  /// Private immutable approved emergency packages (Decisions 2.2, 2.12).
  /// Strictly encapsulated; never exposed as a public constant or getter.
  static const Set<String> _defaultEmergencyPackages = {
    'com.android.phone',
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.android.emergency',
    'com.google.android.apps.safetyhub',
  };

  /// Returns true if [packageName] is one of the five approved emergency defaults.
  static bool isEmergencyPackage(String packageName) =>
      _defaultEmergencyPackages.contains(packageName);

  /// Effective daily screen time quota in minutes.
  /// - Returns null if quota is unlimited.
  /// - Returns 0 if zero minutes are permitted.
  /// - Returns positive integer for configured allowance.
  /// - Throws ArgumentError if an active override is negative (Decision 2.13).
  int? get effectiveDailyLimit {
    if (!hasDailyLimitOverride) {
      return config.dailyScreenTimeMinutes;
    }
    final override = dailyLimitMinutesOverride;
    if (override != null && override < 0) {
      throw ArgumentError.value(
        override,
        'dailyLimitMinutesOverride',
        'Daily limit override cannot be negative.',
      );
    }
    return override;
  }
}
```

---

## 7. Parent Application Compatibility Boundary

- **`PolicyConfig.dailyScreenTimeMinutes`:** Retains `final int dailyScreenTimeMinutes;` (non-nullable).
- **`ScreenTimeCard.dart`:** Zero modifications. `(minutes / 60)` and `minutes.toDouble()` remain valid.
- **`PoliciesController.dart`:** Zero modifications. `updateDailyLimit(int minutes)` untouched.
- **`LocalPoliciesRepository.dart`:** Zero modifications. Stored JSON and database schemas untouched.
- **Verification:** 100% backward-compatible. Eliminates any compile or runtime regressions in `haven_app`.

---

## 8. Package Boundary Verification

- **Placement:** `packages/haven_models/lib/src/policy_evaluator/policy_evaluation_context.dart`.
- **Imports:** `package:meta/meta.dart` and `../policy_config.dart`.
- **Circular Dependencies:** Zero.
- **Platform Independence:** Pure Dart. Zero Flutter, zero GetX, zero Android/native dependencies.

---

## 9. Proposed Source and Test Files for Sub-Step 2.1

| Target File Path | Estimated Lines | Purpose | Compliance |
|:---|:---:|:---|:---:|
| `packages/haven_models/lib/src/policy_evaluator/policy_evaluation_context.dart` | ~85 | Tri-state quota override contract, private emergency encapsulation, query helper. | $\le 200$ lines |
| `packages/haven_models/test/policy_evaluator/policy_evaluation_context_test.dart` | ~120 | Unit tests for tri-state quota resolution, negative rejection, emergency helper, immutability. | $\le 200$ lines |
| `packages/haven_models/lib/haven_models.dart` | ~30 | Export `policy_evaluation_context.dart`. | $\le 200$ lines |

---

## 10. Focused Test Specification (14 Tests)

When authorized for implementation, `policy_evaluation_context_test.dart` will execute:

1. **Test 1 (No Override Fallback):** `hasDailyLimitOverride == false` $\rightarrow$ `effectiveDailyLimit` returns `config.dailyScreenTimeMinutes` (120m).
2. **Test 2 (Explicit Null Unlimited):** `hasDailyLimitOverride == true`, `override == null` $\rightarrow$ `effectiveDailyLimit` returns `null`.
3. **Test 3 (Explicit Zero Minutes):** `hasDailyLimitOverride == true`, `override == 0` $\rightarrow$ `effectiveDailyLimit` returns `0`.
4. **Test 4 (Positive Override Replaces Config):** `hasDailyLimitOverride == true`, `override == 60` $\rightarrow$ `effectiveDailyLimit` returns `60`.
5. **Test 5 (Negative Override via Getter Throws):** `override == -1` $\rightarrow$ accessing `effectiveDailyLimit` throws `ArgumentError`.
6. **Test 6 (Negative Override via Factory Throws):** `withQuotaOverride(minutes: -1)` throws `ArgumentError`.
7. **Test 7 (Positive Override Beyond 1440 Allowed):** `withQuotaOverride(minutes: 1500)` succeeds and resolves to `1500` (no artificial ceiling per Decision 2.13).
8. **Test 8 (Distinguishable Null vs Omitted):** Verifies `hasDailyLimitOverride` differentiates unlimited (`true, null`) from omitted (`false, null`).
9. **Test 9 (Emergency Package Query Helper Membership):** Verifies `PolicyEvaluationContext.isEmergencyPackage` returns `true` for each of the five approved package IDs (`com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`) and `false` for unknown package IDs.
10. **Test 10 (Zero Injection Seam in Constructors):** Production constructors do not expose an emergency package parameter.
11. **Test 11 (Evaluator Precedence Integration Specification):** Verifies that emergency packages bypass schedule and quota restrictions *only when not parent-blocklisted* (testing strings alone does not establish precedence; integration with `config.blockedApps` guarantees blocklist absolute veto).
12. **Test 12 (Unknown Packages Not Exempt):** Verifies unknown package IDs evaluate to `false` in `isEmergencyPackage` and receive no exemptions.
13. **Test 13 (Existing Model Serialization Intact):** Verifies `PolicyConfig.toJson` and `fromJson` remain completely untouched.
14. **Test 14 (Pure Dart Isolation & Immutability):** Context fields are `@immutable` and final; no Flutter imports required.

---

## 11. Risks and Remaining Open Questions

- **Identified Risks:** **Zero.** All boundaries are pure-Dart and strictly non-breaking.
- **Open Questions:** **Zero.** All 13 owner decisions are reconciled without contradictions.

---

## 12. Strict Owner Authorization Gate

> [!CAUTION]
> **SUB-STEP 2.1 IMPLEMENTATION IS NOT AUTHORIZED.**  
> This document represents a completed read-only pre-implementation specification. No source code was modified, no tests were written, no models were altered, and no Git mutations were performed.  
> **Explicit owner implementation authorization is required before beginning Sub-step 2.1.**
