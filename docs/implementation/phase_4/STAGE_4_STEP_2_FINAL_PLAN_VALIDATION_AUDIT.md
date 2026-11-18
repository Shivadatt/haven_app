# HAVEN STAGE 4 — STEP 2 FINAL PLAN VALIDATION AUDIT
## Pure-Dart Deterministic Policy Evaluation Engine

**Document Version:** 1.0.0  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Current Reported HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Status:** COMPLETE — AWAITING OWNER REVIEW  
**Execution Mode:** STRICT READ-ONLY PLAN VALIDATION (Zero Source Code / Git Mutations)  
**Implementation Authorization:** NOT GRANTED  

---

## 1. Executive Summary & Git Preflight

### 1.1 Context
Following the completion of the Step 2 technical clarification audit and the reconciliation of the Step 2 execution plan, this audit provides a rigorous, read-only architectural validation of four unresolved technical questions:
1. **JSON Migration Compatibility:** Investigates whether migrating `PolicyConfig.dailyScreenTimeMinutes` to `int?` breaks existing parent consumers, SharedPreferences persistence, or Postgres fixtures under Dart sound null safety.
2. **Empty Schedule Whitelist Semantics:** Examines how empty `allowedApps` lists are treated across the parent UI ("Allowed App Exceptions") and defines their mathematical interaction under restrictive intersection.
3. **Emergency Package Defaults:** Audits the 6 proposed emergency package identifiers, reporting their true OS function, OEM distribution, and necessity, and identifies packages that should be excluded.
4. **Schedule Intersection Validation:** Validates the multi-schedule intersection algorithm and surfaces an unresolved precedence contradiction between parent blocklists and schedule whitelists.
5. **Execution Sequence Feasibility:** Reviews the proposed 6-sub-step implementation sequence and identifies a major compilation hazard in Sub-step 2.1.

### 1.2 Mandatory Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`
- **Working Tree State:**
  - Staged files: Documentation only (`STAGE_4_STEP_2_EXECUTION_PLAN.md`, `STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md`, `STAGE_4_STEP_2_READINESS_AUDIT.md`).
  - Unstaged files: Reconciled execution plan documentation updates.
  - Untracked files: None.
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Issue 1: JSON Migration Compatibility Audit

### 2.1 Inspection of Codebase Consumers
A comprehensive inspection of all references to `dailyScreenTimeMinutes` revealed critical dependencies in the parent application (`apps/haven_app`):

1. **`ScreenTimeCard.dart` (`apps/haven_app/lib/features/policies/views/widgets/screen_time_card.dart`):**
   ```dart
   final minutes = controller.config.value.dailyScreenTimeMinutes;
   final hours = (minutes / 60).toStringAsFixed(1);
   ...
   Slider(
     value: minutes.toDouble().clamp(0, 1440),
     ...
   )
   ```
2. **`PoliciesController.dart` (`apps/haven_app/lib/features/policies/controllers/policies_controller.dart`):**
   ```dart
   Future<bool> updateDailyLimit(int minutes) async { ... }
   ```
3. **`policy_config_test.dart` (`packages/haven_models/test/policy_config_test.dart`):**
   ```dart
   test('fromJson falls back gracefully on empty or missing fields', () {
     final parsed = PolicyConfig.fromJson(const {});
     expect(parsed.dailyScreenTimeMinutes, 120);
   });
   ```

### 2.2 Compilation Hazard under Dart Sound Null Safety
> [!CAUTION]
> **Direct Model Migration Breaks Parent Compilation:**  
> If `PolicyConfig.dailyScreenTimeMinutes` is changed from `final int dailyScreenTimeMinutes;` to `final int? dailyScreenTimeMinutes;` in `packages/haven_models`, `apps/haven_app` will immediately fail compilation with static analysis errors:
> - `The operator '/' can't be unconditionally invoked because the receiver can be 'null'.` (ScreenTimeCard line 18)
> - `The method 'toDouble' can't be unconditionally invoked because the receiver can be 'null'.` (ScreenTimeCard line 34)
> 
> Because Stage 4 Step 2 authorizes work **only** in `packages/haven_models`, modifying `apps/haven_app` UI components is out of scope until Stage 4 Step 7/8.

### 2.3 Evaluation of the Six JSON Deserialization States

| # | JSON Scenario | Value in JSON | Legacy Deserialization | Proposed Nullable Deserialization | Behavioral Compatibility Impact |
|:---:|:---|:---|:---:|:---:|:---|
| **1** | **Persisted Legacy Record** | Missing key | `120` minutes | `null` (Unlimited) | **HIGH RISK / BREAKING:** A legacy device configured under older builds without an explicit limit key would suddenly have its screen time cap removed (unlimited), and parent UI will crash on render. |
| **2** | **Newly Created Config** | Via `PolicyConfig.defaults()` | `120` minutes | `120` minutes | **COMPATIBLE:** Default constructor explicitly provides 120 minutes. |
| **3** | **Explicit JSON Null** | `"daily_screen_time_limit_minutes": null` | `120` minutes (coerced via `?? 120`) | `null` (Unlimited) | **INTENDED CHANGE:** Fulfills Decision 2.3 & 2.7 (explicit null = unlimited). |
| **4** | **Missing JSON Key** | Key omitted (`{}`) | `120` minutes | `null` (Unlimited) | **REGRESSION RISK:** Breaks `policy_config_test.dart` line 35. |
| **5** | **Explicit Zero** | `"daily_screen_time_limit_minutes": 0` | `0` minutes | `0` minutes | **COMPATIBLE:** Correctly parsed as 0 (zero minutes permitted per Decision 2.3). |
| **6** | **Positive Integer** | `"daily_screen_time_limit_minutes": 90` | `90` minutes | `90` minutes | **COMPATIBLE:** Matches existing parent fixtures (`policies_local_persistence_test.dart`). |

### 2.4 Comparison of Migration Approaches

- **Approach A (Immediate Model Schema Migration in Step 2):**
  - Change `PolicyConfig.dailyScreenTimeMinutes` to `int?`.
  - *Verdict:* **REJECTED.** Breaks Dart static analysis in `apps/haven_app` without modifying out-of-scope parent UI widgets.
- **Approach B (Two-Phase Migration — Recommended):**
  - **Phase 1 (Step 2 Evaluator Scope):** In `packages/haven_models`, `PolicyEvaluationContext` accepts an optional `int? dailyLimitMinutesOverride` (or evaluates `config.dailyScreenTimeMinutes` while supporting nullable inputs). The evaluator engine is fully tested with `null`, `0`, and positive limits. `PolicyConfig` remains `final int dailyScreenTimeMinutes;` in Step 2.
  - **Phase 2 (Step 7/8 Parent Integration Scope):** When parent UI (`ScreenTimeCard`, `PoliciesController`) is updated to support an "Unlimited" toggle, migrate `PolicyConfig.dailyScreenTimeMinutes` to `int?` and update serialization across both apps simultaneously.
  - *Verdict:* **SAFEST & ZERO-BREAKAGE.**
- **Approach C (Backward-Compatible Model with Nullable Wire Helper):**
  - Add `int? get effectiveDailyLimit` or schema versioning.
  - *Verdict:* Adds temporary API clutter in canonical models.

---

## 3. Issue 2: Empty Schedule Whitelist Semantics Audit

### 3.1 Codebase & UI Evidence
Investigation of the parent app authoring screens reveals the exact mental model designed for schedules:
- In `apps/haven_app/lib/features/policies/views/widgets/schedule_app_exceptions.dart`:
  - Bedtime schedules display: `'Allowed Emergency Exceptions'`
  - School/Custom schedules display: `'Allowed App Exceptions (${widget.allowedApps.length})'`
- In `schedule_card_item.dart`:
  - When `schedule.allowedApps.isNotEmpty`, it renders: `'${schedule.allowedApps.length} allowed app exceptions'`.
- In `PolicySchedule.defaultBedtime()`:
  - `allowedApps` is `const <String>[]` (empty).
- In `PolicySchedule.defaultSchool()`:
  - `allowedApps` is `['com.android.calculator2', 'com.google.android.apps.docs']`.

### 3.2 Evaluation of Meaning Options
- **Option A (Empty means NO applications allowed):**
  - A schedule is fundamentally a **downtime/lockout** window. Any app listed in `allowedApps` is an explicit *exception* to that lockout.
  - Therefore, an empty `allowedApps` list means there are **zero exceptions** (all non-emergency applications are restricted).
- **Option B (Empty means NO whitelist restriction / All apps allowed):**
  - If empty meant all apps are allowed, creating a schedule with no exceptions would restrict nothing, rendering Bedtime completely inert. This directly contradicts `defaultBedtime()` having an empty list.
- **Option C (Empty means invalid/incomplete configuration):**
  - Refuted by `defaultBedtime()`, where an empty list is the default valid state.

### 3.3 Effects on Schedules & Restrictive Intersection
Under Decision 2.6, overlapping schedules use **restrictive intersection**:
$$\text{ScheduleAllowedApps} = \bigcap_{s \in \text{activeSchedules}} s.\text{allowedApps}$$

1. **Bedtime Alone:** `allowedApps: []` $\rightarrow$ 0 apps allowed. (Level 1 emergency apps remain exempt).
2. **School Hours Alone:** `allowedApps: ['calc', 'docs']` $\rightarrow$ Only `calc` and `docs` allowed.
3. **Bedtime + School Overlap:**
   $$\emptyset \cap \{\text{calc}, \text{docs}\} = \emptyset$$
   **Result:** 0 apps allowed. Bedtime total lockout dominates.
4. **School + Custom Focus Overlap:**
   $$\{\text{calc}, \text{docs}\} \cap \{\text{docs}, \text{books}\} = \{\text{docs}\}$$
   **Result:** Only `docs` allowed.
5. **Custom Schedule with Empty Whitelist:**
   Acts as a total lockdown window. If a parent creates a custom schedule and adds no exceptions, it blocks all non-emergency apps.

> [!NOTE]
> **Status:** Option A is fully supported by existing UI labels ("Allowed App Exceptions") and model defaults. However, because its intersection with any other schedule produces an empty set, it is marked **CONFIRMED ARCHITECTURAL CONTRACT SUBJECT TO FINAL OWNER ACKNOWLEDGMENT**.

---

## 4. Issue 3: Emergency Package Defaults Audit

Every proposed package identifier was audited against Android OS architecture, foreground usage mechanics, and OEM variation:

| Package Identifier | Target Function | User-Facing vs Daemon | Necessary for Emergency Calling? | OEM Distribution | Unintended Exemption Risk | Recommendation |
|:---|:---|:---:|:---:|:---|:---|:---:|
| `com.android.phone` | AOSP Telephony Subsystem & In-Call UI | Both (System process + in-call UI) | **YES.** Core telephony provider and radio interface. | Universal across all Android devices. | Standard phone calls. Unavoidable foundation. | **KEEP** |
| `com.google.android.dialer` | Google Phone Application | User-Facing Application | **YES.** Default keypad and emergency dialer on Pixel/Motorola/Android One. | Google Pixel, Motorola, Xiaomi Global, Android One. | Allows launching Google dialer app. | **KEEP** |
| `com.android.server.telecom` | Android Telecom Framework Daemon | **Internal Framework Daemon** | **NO.** Internal IPC service (`system_server`). Does NOT appear in `UsageStatsManager` foreground tasks; child cannot launch it. | Universal internal framework component. | Redundant; has no launcher or foreground presence. | **EXCLUDE** |
| `com.android.emergency` | AOSP Emergency Information & ICE | User-Facing Emergency Screen | **YES.** Lockscreen emergency contacts, ICE medical info, and emergency SOS on AOSP. | AOSP, Google Pixel. | None. Contains zero non-emergency functionality. | **KEEP** |
| `com.google.android.apps.safetyhub` | Google Personal Safety & SOS | User-Facing App & Sensor Monitor | **YES.** Powers 5-click Emergency SOS and car crash detection on Pixel. | Google Pixel exclusive (Pixel 3–9+). | Minimal. Workflows are strictly safety-oriented. | **KEEP** |
| `com.samsung.android.dialer` | Samsung One UI Phone Application | User-Facing Application | **YES.** The essential dialer on Samsung devices (~35% of Android market). | Samsung Galaxy devices only. | Allows launching Samsung dialer app. | **KEEP** |

### 4.1 Recommended Narrowest Defensible Immutable Default Set
Excluding `com.android.server.telecom` (which is an internal framework process and not an application package subject to foreground monitoring), the narrowest defensible default set consists of exactly **five** packages:

```dart
static const Set<String> defaultEmergencyPackages = {
  'com.android.phone',
  'com.google.android.dialer',
  'com.samsung.android.dialer',
  'com.android.emergency',
  'com.google.android.apps.safetyhub',
};
```

---

## 5. Issue 4: Schedule Intersection & Precedence Validation

### 5.1 Critical Conflict: Schedule Whitelist vs Parent Blocklist
A deep comparison between the Section 4 Precedence Table and Decision 2.4 identified a major architectural conflict:

- **The Problem:**
  - Proposed Precedence Priority 2: **Schedule Whitelist** (`activeSchedule.allowedApps`).
  - Proposed Precedence Priority 5: **Parent Blocklist** (`PolicyConfig.blockedApps`).
  - *Conflict Scenario:* Suppose a parent explicitly puts an app (e.g. YouTube or TikTok) in `blockedApps` (a 24/7 blocklist). But a school schedule has YouTube in its `allowedApps` (e.g. for educational videos).
  - Under the current plan where Priority 2 > Priority 5, **YouTube would be ALLOWED during school hours**, overriding the parent's explicit blocklist!
- **Resolution Required:**
  - In parental control domain architecture, an explicit 24/7 parent blocklist represents a hard veto on an application.
  - **Recommendation:** Elevate **Parent Blocklist** to **Priority 2** (immediately after Emergency Defaults), or confirm whether a Schedule Whitelist is intended to override a 24/7 Blocklist.
  - Marked: **OWNER CLARIFICATION REQUIRED (Decision 2.8)**.

### 5.2 Summary of Unambiguous Precedence Rules
1. **Emergency Defaults (Level 1):** Overrides everything (bedtime, school, blocklists, quotas).
2. **Bedtime / School (Level 3/4):** Restricts all non-exempt applications.
3. **Parent Whitelist (`PolicyConfig.allowedApps`):** Bypasses **only** the global daily quota (Decision 2.1). Does *not* bypass bedtime, does *not* bypass school schedules, does *not* bypass per-app limits, does *not* bypass blocklists.
4. **Per-App Limits (`PolicyConfig.appLimits`):** Overrides Parent Whitelist (Decision 2.5).

---

## 6. Issue 5: Final Execution Plan Validation & Sequencing Review

### 6.1 Review of Implementation Sequence
The proposed 6-sub-step implementation sequence was validated:

| Sub-Step | Title | Feasibility Assessment | Required Sequencing Adjustment |
|:---:|:---|:---:|:---|
| **2.1** | Canonical Model Schema Migration | **BLOCKED BY SCOPE BOUNDARY** | Cannot change `PolicyConfig.dailyScreenTimeMinutes` to `int?` without breaking `apps/haven_app` compile. **Adjustment:** Retain `int` in `PolicyConfig` during Step 2; implement `int?` support in `PolicyEvaluationContext`. Defer `PolicyConfig` migration to Step 7. |
| **2.2** | Evaluation Contracts & Usage Snapshot | **FEASIBLE** | Zero dependencies, pure Dart, fully isolated. |
| **2.3** | Core Schedule & Interval Engine | **FEASIBLE** | Wall-clock math `[start, end)` and cross-midnight daytime logic cleanly testable in isolation. |
| **2.4** | Deterministic Policy Evaluator | **FEASIBLE** | Evaluates all 9 priority levels without system clock. |
| **2.5** | Comprehensive Test Suites | **FEASIBLE** | 4 focused test files $\le 200$ lines covering C-01 through C-17 and DST. |
| **2.6** | Full Repository Regression Run | **FEASIBLE** | Executes all 1,427 baseline tests. |

---

## 7. Actionable Plan Corrections Required

Before implementation begins, `STAGE_4_STEP_2_EXECUTION_PLAN.md` must be corrected with:
1. **Adjust Sub-Step 2.1 Scope:** Decouple evaluator nullable support from `PolicyConfig` model migration to avoid breaking `apps/haven_app`.
2. **Remove `com.android.server.telecom`:** Trim emergency defaults to the 5 verified user-facing/telephony packages.
3. **Resolve Blocklist vs Schedule Whitelist:** Explicitly position Parent Blocklist relative to Schedule Whitelist based on owner direction.
4. **Document Empty Whitelist Contract:** Formally state that an empty schedule whitelist indicates zero exceptions (lockdown).

---

## 8. Strict Owner Authorization Boundary & Verdict

> [!CAUTION]
> **IMPLEMENTATION REMAINS STRICTLY UNAUTHORIZED.**  
> This document represents a completed read-only validation audit. No source code was modified, no models were altered, no tests were written, and no Git mutations were executed.

### Verdict:
**FINAL PLAN VALIDATION COMPLETE — AWAITING OWNER REVIEW**
