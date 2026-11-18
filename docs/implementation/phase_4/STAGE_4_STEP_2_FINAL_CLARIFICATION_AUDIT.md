# HAVEN STAGE 4 — STEP 2 FINAL TECHNICAL CLARIFICATION AUDIT
## Pure-Dart Deterministic Policy Evaluation Engine

**Document Version:** 1.0.0  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Branch:** `main`  
**Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Status:** COMPLETE — AWAITING OWNER REVIEW  
**Execution Mode:** STRICT READ-ONLY INVESTIGATION (Zero Source Code / Git Mutations)  

---

## 1. Executive Summary & Git Preflight

### 1.1 Context
Stage 4 Step 1 established the canonical policy data models in `packages/haven_models`. Following the preliminary Step 2 readiness audit, the owner has approved three foundational policy semantics decisions (Decisions 2.1–2.3). 

This document conducts the final, exhaustive pre-implementation investigation covering:
1. Timezone and daylight-saving time (DST) semantics.
2. Complete, pair-by-pair rule precedence matrix.
3. Usage data completeness and boundary conditions.
4. Package placement and architectural coupling.
5. Quota semantics and canonical model compatibility.
6. Multi-dimensional result contracts.
7. Consolidated specification and deterministic test matrix.

### 1.2 Mandatory Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Exact HEAD Commit:** `711b209aed99f8e024fc8c924c8b30ecb10849e8` (`feat: extract canonical policy models and rules to haven_models package`)
- **Working Tree State:**
  - `git diff --stat`: Clean (0 unstaged changes).
  - `git diff --cached --stat`: Clean (0 staged changes).
  - Untracked files: Previous planning documents (`STAGE_4_STEP_2_EXECUTION_PLAN.md`, `STAGE_4_STEP_2_READINESS_AUDIT.md`).
- **Line Count Compliance:** 801 handwritten source and test files scanned, **0 violations** (all files $\le 200$ lines).
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Confirmed Owner Decisions (2.1–2.3)

### Decision 2.1 — Whitelist vs Global Daily Quota [APPROVED: Option A]
- Applications in `PolicyConfig.allowedApps` remain accessible after the global daily screen-time quota is exhausted.
- Emergency applications also remain exempt.
- The evaluator must still report global quota exhaustion as an overall condition.
- The evaluator must distinguish global quota status from the access assessment of an exempt or whitelisted application.
- *Strict Boundary:* Whitelist access evaluation is pure computation and does not imply native Android enforcement.

### Decision 2.2 — Emergency Applications [APPROVED: Option A]
- Emergency and essential telephony applications use immutable built-in defaults.
- No configurable `emergencyApps` or `exemptApps` field is added in this step.
- The evaluator uses a narrowly scoped, documented set of standard emergency/telephony package identifiers:
  - `com.android.phone` (AOSP telephony)
  - `com.google.android.dialer` (Google Pixel / Android One dialer)
  - `com.android.server.telecom` (Android Telecom subsystem)
  - `com.android.emergency` (AOSP Emergency assistance)
  - `com.google.android.apps.safetyhub` (Google Personal Safety)
  - `com.samsung.android.dialer` (Samsung OneUI dialer)
- *Limitation Disclosure:* Android OEM variations exist (e.g. Xiaomi, BBK/Realme dialers). The evaluator operates on package identifiers supplied in its context and does not query `PackageManager` or native APIs.

### Decision 2.3 — Daily Limit Zero Semantics [APPROVED: Option A]
- `dailyScreenTimeMinutes == 0` means **zero minutes allowed** (no screen time permitted).
- A missing or null daily limit means **unlimited**.
- A positive value represents the configured daily allowance in minutes.

#### Canonical Model Audit against Decision 2.3:
Inspection of `packages/haven_models/lib/src/policy_config.dart`:
```dart
line 51: dailyScreenTimeMinutes: asInt(json['daily_screen_time_limit_minutes']) ?? 120,
line 63: final int dailyScreenTimeMinutes;
```
- **Finding:** In the current Step 1 model, `dailyScreenTimeMinutes` is declared as non-nullable `final int dailyScreenTimeMinutes;`, and `fromJson` falls back to `120` when the JSON key is null or absent.
- **Limitation:** The current model **cannot represent the "null = unlimited" state**, because it cannot store `null` and coerces missing keys to `120`.
- **Proposed Schema Adjustment (Requires Owner Sign-off prior to Step 3):**
  Change `final int dailyScreenTimeMinutes;` to `final int? dailyScreenTimeMinutes;` in `PolicyConfig`. In Step 2, the evaluator function can accept an optional or nullable limit in its evaluation context without altering the persistent model.

---

## 3. Clarification A — Timezone and Daylight-Saving (DST) Contract

### 3.1 Evaluation of Alternatives

| Evaluation Option | Technical Feasibility | Dependency Requirements | DST Behavior | Timezone Change Behavior | Historical & Test Suitability |
|:---|:---:|:---|:---|:---|:---|
| **Option A: Device-Local Wall-Clock** *(RECOMMENDED)* | **High** | Zero new dependencies (`dart:core` standard library). | Follows device clock minute-for-minute. | Immediately reflected upon next evaluation. | Fully deterministic using injected local `DateTime`. Matches parent/child UI expectations. |
| **Option B: Fixed UTC Offset** | **Low** | Zero new dependencies. | **Fails during DST switchovers** (offset changes by $\pm 1$ hour while fixed offset does not). | Fails when device travels or changes zone. | Unrealistic; timezones are not fixed integer offsets throughout the year. |
| **Option C: Named Timezone (IANA)** | **Medium** | Requires heavy 3rd-party dependency (`package:timezone`) and IANA tzdata database (~500KB+). | Handled by tz database. | Requires persistent storage of timezone ID and network update of tzdata. | Over-engineered for a local on-device child app. Introduces external dependencies. |

### 3.2 Required DST Scenarios Analysis

1. **Normal Day (No Transition):** Wall-clock minutes progress continuously from 0 to 1439. Schedule checks match `[start, end)` precisely.
2. **Spring Forward (Clock moves 02:00 $\rightarrow$ 03:00):** Wall-clock minutes 120 to 179 do not exist locally on that day. A schedule configured strictly inside `02:15 - 02:45` will not trigger because the device clock never reads those minutes. This is correct real-world behavior.
3. **Fall Back (Clock moves 02:00 $\rightarrow$ 01:00):** Wall-clock minutes 60 to 119 repeat twice. Evaluating against wall-clock time ensures that during both occurrences of 01:30, a schedule covering 01:30 remains active.
4. **Evaluation During Transition:** The evaluator evaluates against the instantaneous `evaluationTime` provided by the caller. It computes `evaluationTime.hour * 60 + evaluationTime.minute`.
5. **Device Timezone Change (e.g. Travel):** If the device changes timezone, the next call to `DateTime.now().toLocal()` or the injected timestamp reflects the new local hour/minute immediately. The schedule (e.g. Bedtime at 21:00) applies to 21:00 in the new location.
6. **Midnight Crossing on DST Day:** A day with 23 or 25 hours still transitions date at local midnight (00:00:00). The overnight transition formula evaluates the morning portion against `localTime.hour * 60 + localTime.minute < endMinutes` on the calendar day following the start day.

### 3.3 Explicit Timezone Recommendation
**Adopt Option A (Device-Local Wall-Clock Contract):**
- Schedules in `PolicySchedule` (`startTime`, `endTime`) represent local wall-clock time on the child device.
- The evaluation caller provides an explicit `DateTime evaluationTime`.
- If `evaluationTime.isUtc` is true, the evaluator converts it via `evaluationTime.toLocal()`, or caller passes a local timestamp.
- Overnight schedules identify their starting weekday as:
  - If `currentMinutes >= startMinutes`: starting day is `evaluationTime.weekday`.
  - If `currentMinutes < endMinutes`: starting day is `evaluationTime.weekday == 1 ? 7 : evaluationTime.weekday - 1`.

---

## 4. Clarification B — Complete Rule Precedence Matrix

The evaluation engine resolves policy conflicts using the following authoritative pair-by-pair matrix:

| Rule A | Rule B | Existing Codebase Behavior | Proposed Evaluator Resolution | Architectural & Safety Reason | Owner Approval Status |
|:---|:---|:---|:---|:---|:---:|
| **Emergency App** | **Bedtime Schedule** | Unspecified | **Emergency App Wins (Allowed)** | Child safety: Emergency calls/dialer must never be blocked during sleep hours. | **OWNER APPROVED (Decision 2.2)** |
| **Emergency App** | **Parent Blocklist** | Unspecified | **Emergency App Wins (Allowed)** | Safety override: Parent cannot inadvertently brick emergency calling on device. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Emergency App** | **Per-App Quota** | Unspecified | **Emergency App Wins (Allowed)** | Safety override: Dialer cannot be limited to 15 minutes. | **OWNER APPROVED (Decision 2.2)** |
| **Emergency App** | **Global Daily Quota** | Unspecified | **Emergency App Wins (Allowed)** | Safety override: Emergency calls allowed when quota reached. | **OWNER APPROVED (Decisions 2.1, 2.2)** |
| **Schedule Whitelist (`allowedApps`)** | **Bedtime Schedule** | Defined in model | **Schedule Whitelist Wins (Allowed)** | Expressly designed for bedtime exceptions (e.g. white noise or audiobook player). | **EXISTING BEHAVIOR VERIFIED** |
| **Schedule Whitelist (`allowedApps`)** | **School Schedule** | Defined in model | **Schedule Whitelist Wins (Allowed)** | Educational apps (Calculator, Docs) explicitly permitted during school hours. | **EXISTING BEHAVIOR VERIFIED** |
| **Schedule Whitelist** | **Parent Blocklist** | Unspecified | **Parent Blocklist Wins (Blocked)** | Explicit 24/7 blocklist represents an absolute parental ban that overrides schedule exceptions. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Parent Blocklist** | **Parent Whitelist (`PolicyConfig.allowedApps`)** | Model allows both | **Parent Blocklist Wins (Blocked)** | Defensive security: An explicitly banned app (e.g. TikTok) is blocked even if accidentally added to whitelist. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Parent Whitelist (`allowedApps`)** | **Per-App Quota** | Model allows both | **Per-App Quota Wins (Restricted)** | If a whitelisted app (e.g. YouTube) has an explicit 30m limit, exhausting that 30m limit restricts that specific app. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Parent Whitelist (`allowedApps`)** | **Global Daily Quota** | Unspecified | **Parent Whitelist Wins (Allowed)** | Approved Decision 2.1: Whitelisted utility apps remain accessible after global daily quota is exhausted. | **OWNER APPROVED (Decision 2.1)** |
| **Bedtime Schedule** | **School Schedule** | Checked at creation | **Most Restrictive Wins (Intersection of Whitelists)** | If both active simultaneously, only apps in BOTH `allowedApps` lists are accessible. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Bedtime Schedule** | **Custom Schedule** | Checked at creation | **Bedtime Wins (Downtime Priority)** | Bedtime represents mandatory sleep downtime. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Multiple Simultaneous Schedules** | **Multiple Simultaneous Schedules** | `findConflicts()` flags overlap | **Restrictive Conjunction** | Active schedule window restricts general apps; only apps allowed by all active schedules remain accessible. | **RECOMMENDED — APPROVAL REQUIRED** |
| **Per-App Quota Reached** | **Global Quota Remaining** | Independent fields | **Per-App Quota Wins (Restricted)** | Reaching YouTube 30m restricts YouTube even if 60m of global screen time remains. | **EXISTING BEHAVIOR VERIFIED** |
| **Per-App Quota Remaining** | **Global Quota Reached** | Independent fields | **Global Quota Wins (Restricted)** | Non-whitelisted app is restricted when global daily allowance is exhausted. | **EXISTING BEHAVIOR VERIFIED** |
| **Disabled Schedule (`isActive: false`)** | **Active Schedule** | `isActive` check | **Active Schedule Evaluated** | Inactive schedules are completely skipped during evaluation. | **EXISTING BEHAVIOR VERIFIED** |
| **Inactive / Missing Policy** | **All Other Rules** | Defaults loaded | **Fallback to Defaults** | Empty policy defaults to `PolicyConfig.defaults()` (120m, standard bedtime/school). | **EXISTING BEHAVIOR VERIFIED** |

---

## 5. Clarification C — Usage Data Completeness Contract

### 5.1 Analysis of 12 Usage Scenarios

| Scenario | Usage Input State | Interpretation | Evaluator Action |
|:---|:---|:---|:---|
| **1. Complete with app record** | Permission granted; app in `apps` list | **Confirmed Usage** | Use recorded `totalForegroundMillis`. |
| **2. Complete without app record** | Permission granted; query succeeded; app absent from `apps` | **Confirmed Zero Usage** | Foreground usage is exactly 0 ms for this query window. |
| **3. Delayed without app record** | `freshness == delayed`; app absent | **Probable Zero Usage (Flagged)** | Evaluate as 0 ms used; flag result with `isDelayed: true`. |
| **4. Empty usage result** | `freshness == empty`; `totalForegroundMillis == 0` | **Confirmed Zero Usage** | Evaluate quotas as 0 ms used; preserve empty indicator. |
| **5. Permission denied** | `permissionStatus == denied` | **Usage Unavailable** | Quotas report `usageUnavailable`; do NOT assume 0 ms; do NOT restrict apps. |
| **6. Permission revoked mid-run** | Permission changed to denied | **Usage Unavailable** | Memory cleared; quotas report `usageUnavailable`. |
| **7. Unsupported platform** | `permissionStatus == unsupported` | **Capability Unavailable** | Quotas report `usageUnavailable`; policy engine reports non-enforcing status. |
| **8. Malformed native envelope** | JSON parse exception in channel | **Evaluation Error / Unavailable** | Return typed `Err` or `usageUnavailable`. |
| **9. Stale previous-day result** | `startTimeMillis` date != evaluation date | **Stale Usage** | Flag as stale; report `usageUnavailable` for current day's quota. |
| **10. App installed, never used** | Permission granted; app absent from `apps` | **Confirmed Zero Usage** | Safe 0 ms usage. |
| **11. App uninstalled / absent** | Package not on device | **Not Applicable / 0 ms** | Evaluated as 0 ms if evaluated. |
| **12. Query failure** | Repository returned `Err(HavenFailure)` | **Usage Unavailable** | Quotas report `usageUnavailable` with failure message. |

### 5.2 Decoupled Pure-Dart Usage Contract
To avoid circular dependencies between `haven_models` and `apps/haven_child`, the evaluator **must not** import `apps/haven_child/lib/core/native/usage_envelope_models.dart`.

Instead, `haven_models` defines an immutable, pure-Dart input model:
```dart
final class PolicyUsageSnapshot {
  const PolicyUsageSnapshot({
    required this.totalForegroundMillis,
    required this.appForegroundMillis,
    required this.freshness,
    this.isPermissionGranted = true,
    this.queryDate,
  });

  final int totalForegroundMillis;
  final Map<String, int> appForegroundMillis;
  final UsageFreshnessStatus freshness;
  final bool isPermissionGranted;
  final DateTime? queryDate;

  int get totalMinutes => totalForegroundMillis ~/ 60000;
  int appMinutes(String packageName) =>
      (appForegroundMillis[packageName] ?? 0) ~/ 60000;
}
```
The child app adapts its `UsageDailyResult` into this snapshot before invoking the evaluator.

---

## 6. Clarification D — Package Placement Architecture

### 6.1 Comparison of Candidate Locations

| Package Option | Layering Cleanliness | Dependency Flow | Code Reuse | Verdict |
|:---|:---|:---|:---|:---:|
| **Option A: `packages/haven_models`** | High. Models & evaluation rules co-located. | Clean: `haven_models` depends on `dart:core`. No circularity. | Immediate reuse by both `haven_app` and `haven_child`. | **RECOMMENDED (Smallest Architecture)** |
| **Option B: `packages/haven_core`** | Inverted. `haven_core` would have to depend on `haven_models`. | **Cyclic Risk:** Violates bottom-up hierarchy (`haven_models` -> `haven_core`). | Unacceptable architectural regression. | **REJECTED** |
| **Option C: Separate `haven_policy` package** | Maximum isolation. | Clean but introduces a 5th package, new `pubspec.yaml`, and build overhead. | High, but violates "no new package" constraint. | **REJECTED** |
| **Option D: `haven_child` domain only** | Low. Duplicates logic if parent app needs to simulate policies. | One-sided: Parent app cannot evaluate child policy scenarios. | Poor reuse. | **REJECTED** |

### 6.2 Selected Architecture
Place the evaluator in `packages/haven_models/lib/src/policy_evaluator/`:
- `packages/haven_models` is already pure Dart (`sdk: ^3.12.2`).
- Already contains `PolicyConfig`, `PolicySchedule`, `PolicyRules`, and `ScheduleConflictDetector`.
- Zero new package manifests. Zero circular imports.

---

## 7. Clarification E — Daily Limit and Per-App Limit Semantics

### 7.1 Global Daily Quota Semantics
- `dailyScreenTimeMinutes == null`: **Unlimited** (no global screen time cap).
- `dailyScreenTimeMinutes == 0`: **Zero Minutes Allowed** (general apps immediately reach daily limit).
- `dailyScreenTimeMinutes > 0`: **Configured Limit** (exceeded when `usedMinutes >= dailyScreenTimeMinutes`).

### 7.2 Per-Application Limit Semantics
- **Absence from `appLimits`:** The application has **no individual limit** (governed solely by global quota and schedules).
- **`appLimits[pkg] == 0`:** **Zero Minutes Allowed** for this specific application (app is immediately limited).
- **`appLimits[pkg] > 0`:** Configured allowance. Exceeded when package `usedMinutes >= limitMinutes`.
- **Negative Values in `appLimits`:** Rejected by `PolicyRules.validateMinutesLimit()`. If encountered at runtime, treated as unconfigured (no limit).
- **Package Name Normalization:** Trimmed and matched case-insensitively (`pkg.trim().toLowerCase()`).
- **Interaction with Whitelist:** Per Decision 2.1, whitelisted apps bypass the *global* quota, but if a parent explicitly configures a per-app limit on a whitelisted app (e.g. Docs allowed, but limited to 60m), the per-app limit applies.

---

## 8. Clarification F — Multi-Dimensional Result Contract

The evaluator must never collapse policy state into a single boolean. Multiple distinct conditions can and do co-exist:

### 8.1 Multi-Dimensional Result Structure
An evaluation at 22:30 with 130m/120m usage and delayed data will simultaneously report:
1. `overallState`: `PolicyOverallState.scheduleRestricted` (Bedtime is the dominant restriction).
2. `isDowntimeActive`: `true` (Bedtime active).
3. `activeSchedules`: `[ActiveScheduleInfo("Bedtime", type: bedtime, allowedApps: [])]`.
4. `dailyQuota`: `DailyQuotaEvaluation(limit: 120, used: 130, remaining: 0, isExceeded: true)`.
5. `appEvaluations['com.android.phone']`: `AppEvaluation(status: exempt, reason: "Emergency service")`.
6. `appEvaluations['com.android.calculator2']`: `AppEvaluation(status: allowed, reason: "Whitelisted utility")`.
7. `appEvaluations['com.instagram.android']`: `AppEvaluation(status: blockedByParent, reason: "Parent blocklist")`.
8. `usageFreshness`: `UsageFreshnessStatus.delayed` (`isDelayed: true`).
9. `disclosure`: `"Policies are evaluated locally. Application blocking is not enforced on this build."`

---

## 9. Consolidated Proposed Policy Specification

| Policy Rule | Rule Definition | Authority Status |
|:---|:---|:---:|
| **PR-01** | `PolicyConfig.allowedApps` remain accessible when daily screen time quota is exhausted. | **OWNER APPROVED** |
| **PR-02** | Standard emergency/telecom packages are exempt from all bedtime, schedule, and quota restrictions. | **OWNER APPROVED** |
| **PR-03** | `dailyScreenTimeMinutes == 0` means 0 minutes permitted; missing/null means unlimited. | **OWNER APPROVED** |
| **PR-04** | Schedules evaluate against local child device wall-clock time in half-open interval `[start, end)`. | **EXISTING BEHAVIOR VERIFIED** |
| **PR-05** | Overnight schedules (`start > end`) activate evening of day $D$ and morning of day $D+1$. | **EXISTING BEHAVIOR VERIFIED** |
| **PR-06** | Absence of an app in `UsageDailyResult.apps` after a valid query represents confirmed 0 ms usage. | **EXISTING BEHAVIOR VERIFIED** |
| **PR-07** | Permission denial or missing usage data yields `usageUnavailable` without blocking apps. | **EXISTING BEHAVIOR VERIFIED** |
| **PR-08** | Delayed usage data evaluates quotas using available data but sets `isDelayed: true`. | **EXISTING BEHAVIOR VERIFIED** |
| **PR-09** | Explicit parent blocklist (`blockedApps`) overrides whitelist and schedule allowances. | **RECOMMENDED — APPROVAL REQUIRED** |
| **PR-10** | Explicit per-app limits apply even if an application is in `PolicyConfig.allowedApps`. | **RECOMMENDED — APPROVAL REQUIRED** |
| **PR-11** | Multiple simultaneous schedules apply the intersection of their `allowedApps`. | **RECOMMENDED — APPROVAL REQUIRED** |
| **PR-12** | Every evaluation result provides transparent disclosure of no active Android enforcement. | **OWNER APPROVED** |

---

## 10. Required Test Matrix

A pure-Dart test suite using `test/test.dart` and fixed timestamps:

### 1. Time & Schedules Test Suite (`schedule_evaluation_test.dart`)
- [ ] Daytime schedule active at exact `start` (`08:30:00`).
- [ ] Daytime schedule active at mid-interval (`12:00:00`).
- [ ] Daytime schedule inactive at exact `end` (`15:00:00`) — verifies `[start, end)`.
- [ ] Daytime schedule inactive on non-scheduled day.
- [ ] Overnight schedule active at `21:00:00` Monday evening.
- [ ] Overnight schedule active at `23:59:59` Monday night.
- [ ] Overnight schedule active at `00:00:00` Tuesday morning.
- [ ] Overnight schedule active at `06:59:59` Tuesday morning.
- [ ] Overnight schedule inactive at `07:00:00` Tuesday morning.
- [ ] Overnight schedule inactive on Monday morning when Sunday was not a scheduled day.
- [ ] Spring-forward DST day (non-existent 02:30 skipped cleanly).
- [ ] Fall-back DST day (repeated 01:30 remains active).

### 2. Usage & Quotas Test Suite (`policy_evaluator_test.dart`)
- [ ] Null daily quota evaluates as unlimited (`remainingMinutes: null`, `isExceeded: false`).
- [ ] Zero daily quota evaluates as immediate quota reached (`used: 0, limit: 0, isReached: true`).
- [ ] 75m used of 120m limit $\rightarrow$ `withinLimit`, 45m remaining.
- [ ] 120m used of 120m limit $\rightarrow$ `limitReached`, 0m remaining.
- [ ] 130m used of 120m limit $\rightarrow$ `limitExceeded`, 0m remaining.
- [ ] Permission denied $\rightarrow$ `dailyQuota.isUnavailable: true`, apps not falsely blocked.
- [ ] Delayed freshness $\rightarrow$ `result.isDelayed: true`.
- [ ] Empty usage result $\rightarrow$ evaluates as 0m used, preserves empty indicator.
- [ ] App absent from usage list $\rightarrow$ evaluated as 0m used.

### 3. Precedence & Conflict Test Suite (`policy_precedence_test.dart`)
- [ ] Emergency dialer during Bedtime $\rightarrow$ `AppPolicyStatus.exempt`.
- [ ] Emergency dialer when daily screen time exceeded $\rightarrow$ `AppPolicyStatus.exempt`.
- [ ] Emergency dialer in `blockedApps` $\rightarrow$ `AppPolicyStatus.exempt` (safety override).
- [ ] Whitelisted app (`allowedApps`) when daily screen time exceeded $\rightarrow$ `AppPolicyStatus.allowed` (Decision 2.1).
- [ ] Whitelisted app in `blockedApps` $\rightarrow$ `AppPolicyStatus.blockedByParent` (blocklist priority).
- [ ] Whitelisted app with exhausted per-app limit $\rightarrow$ `AppPolicyStatus.appLimitReached`.
- [ ] Calculator during school schedule in `allowedApps` $\rightarrow$ `AppPolicyStatus.scheduleAllowed`.
- [ ] Game during school schedule $\rightarrow$ `AppPolicyStatus.scheduleRestricted`.

---

## 11. Unresolved Owner Decisions Requiring Explicit Direction

The owner must confirm or adjust the following four recommended rules before implementation:

1. **Rule PR-09 (Blocklist vs Whitelist):** Does `blockedApps` take absolute priority over `allowedApps` if an app appears in both? *(Recommended: Blocklist wins).*
2. **Rule PR-10 (Whitelist vs Per-App Limit):** Does an explicit per-app limit in `appLimits` (e.g. YouTube 30m) apply if YouTube is also in `allowedApps`? *(Recommended: Per-app limit wins).*
3. **Rule PR-11 (Multiple Overlapping Schedules):** When two schedules are active simultaneously (e.g. School Hours and Custom Focus), do apps need to be in both whitelists to be allowed? *(Recommended: Restrictive intersection).*
4. **Canonical Model Update:** Does the owner authorize updating `PolicyConfig.dailyScreenTimeMinutes` to `int?` in `packages/haven_models` to natively support the approved "null = unlimited" semantics in Step 3? *(Recommended: Approve for Step 3).*

---

## 12. Corrections Required to Step 2 Execution Plan

The existing `STAGE_4_STEP_2_EXECUTION_PLAN.md` must be reconciled with the following findings:
1. **Explicit Schema Note:** Document that `PolicyConfig.dailyScreenTimeMinutes` is currently non-nullable `int`, and explain how the evaluator handles nullable limits in `PolicyEvaluationContext`.
2. **Clarify Wall-Clock Timezone:** Explicitly specify Option A (Device-Local Wall-Clock) as the authoritative time standard.
3. **Decoupled Usage Input:** Remove any direct reference to child app envelope classes; use `PolicyUsageSnapshot` in `haven_models`.
4. **Update Precedence Matrix:** Incorporate the full 17-conflict resolution table.

---

## 13. Strict Owner Authorization Boundary

> [!CAUTION]
> **STEP 2 IMPLEMENTATION REMAINS UNAUTHORIZED.**  
> This document represents a completed read-only technical clarification audit. No source code was modified, no tests were written, no models were altered, and no Git mutations were performed.  
> **Explicit owner authorization is required before executing Step 2 implementation.**
