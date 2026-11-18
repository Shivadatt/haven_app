# HAVEN STAGE 4 — STEP 2 READINESS AUDIT
## Pure-Dart Policy Evaluation Engine Architecture & Pre-Implementation Audit

**Document Version:** 1.0.0  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Branch:** `main`  
**Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Execution Mode:** STRICT READ-ONLY AUDIT & ARCHITECTURAL INVESTIGATION  
**Implementation Authorization:** NOT GRANTED  
**Source Code Modification:** PROHIBITED  

---

## 1. Executive Summary & Git Preflight

### 1.1 Context & Purpose
Stage 4 Step 1 successfully extracted the canonical policy models (`PolicyConfig`, `PolicySchedule`, `PolicyScheduleType`, `PolicyRules`, `ScheduleConflict`, `ScheduleConflictDetector`) into `packages/haven_models/` and established parent compatibility barrels with zero regressions across 1,427 automated tests.

This audit investigates the architectural readiness, mathematical scheduling logic, transient usage data integration, and deterministic design requirements for **Stage 4 Step 2: Pure-Dart Deterministic Policy Evaluation Engine**.

The proposed engine is an **informational evaluation calculator**. It calculates whether a child's current usage or schedule matches policy conditions. In accordance with **Owner Decision 4.1**, it executes exclusively in pure Dart and does **NOT** enforce native Android app blocking, Device Owner MDM restrictions, or accessibility-based interruptions.

### 1.2 Mandatory Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Exact HEAD Commit:** `711b209aed99f8e024fc8c924c8b30ecb10849e8` (verified)
- **Working Tree State:**
  - `git diff --stat`: Empty (0 unstaged changes).
  - `git diff --cached --stat`: Empty (0 staged changes).
  - `git status --short --branch`: Clean (`## main...origin/main`).
- **Line Count Compliance:** 801 handwritten source and test files scanned, **0 violations** (all files $\le 200$ lines).
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Step 1 Canonical Model Audit

A detailed inspection was conducted on the extracted canonical models in `packages/haven_models/lib/src/`:

### 2.1 Model Capabilities & Field Inventory

| Model Class | Source File | Line Count | Key Fields & Types | Evaluator Capability Supported |
|:---|:---|:---:|:---|:---|
| `PolicyConfig` | `src/policy_config.dart` | 117 | `dailyScreenTimeMinutes` (int)<br>`schedules` (List\<PolicySchedule\>)<br>`allowedApps` (List\<String\>)<br>`blockedApps` (List\<String\>)<br>`appLimits` (Map\<String, int\>)<br>`allowedDomains` (List\<String\>)<br>`blockedDomains` (List\<String\>)<br>`safeSearchEnabled` (bool) | Daily global quota bounds.<br>Active schedule evaluation.<br>Global app whitelist.<br>Global app blocklist.<br>Per-app time limits (in minutes).<br>Domain web filtering rules. |
| `PolicySchedule` | `src/policy_schedules.dart` | 157 | `id` (String)<br>`name` (String)<br>`type` (PolicyScheduleType)<br>`startTime` (String "HH:mm")<br>`endTime` (String "HH:mm")<br>`days` (List\<int\>, 1..7)<br>`isActive` (bool)<br>`allowedApps` (List\<String\>)<br>`category` (String?) | Recurring window detection.<br>Bedtime vs school categorization.<br>Cross-midnight overnight detection (`isOvernight`).<br>Schedule-specific app exceptions (`allowedApps`).<br>Active/inactive toggling. |
| `PolicyScheduleType` | `src/policy_schedules.dart` | 157 | `bedtime` ('bedtime', 'Bedtime')<br>`school` ('school', 'School Hours')<br>`custom` ('custom', 'Custom') | Categorical distinction for bedtime vs focus vs general downtime. |
| `PolicyRules` | `src/policy_rules.dart` | 58 | Static validators: `isValidDomain`, `validateDomain`, `validatePackageName`, `validateMinutesLimit` | Input syntax and range sanity checks. |
| `ScheduleConflict` | `src/policy_conflicts.dart` | 102 | `scheduleA`, `scheduleB`, `overlappingDays`, `summary` | Static overlap identification. |
| `ScheduleConflictDetector` | `src/policy_conflicts.dart` | 102 | Static methods: `findConflicts`, `hasDuplicateName`, `_toDailyIntervals`, `_timesOverlap` | Pure mathematical interval collision detection. |

### 2.2 Model Adequacy & Identified Gaps
1. **Sufficient Capabilities:**
   - Global daily screen time limits (`dailyScreenTimeMinutes`).
   - Per-app daily minutes limits (`appLimits`).
   - Scheduled restriction intervals (`schedules`).
   - Bedtime / downtime separation (`PolicyScheduleType`).
   - Global allowed/blocked lists (`allowedApps`, `blockedApps`).
   - Schedule-specific exempt applications (`PolicySchedule.allowedApps`).
2. **Missing / Absent Data (Requiring Architecture Recommendations):**
   - **Emergency / System Exemption List:** `PolicyConfig` has no explicit `emergencyApps` or `systemExemptApps` field. Core dialer (`com.android.phone`, `com.google.android.dialer`) and emergency services are critical and must be treated as exempt by rule precedence.
   - **Policy Master Switch:** There is no `isEnabled` boolean at the root of `PolicyConfig`. Master policy activation is currently implicit (e.g. `dailyScreenTimeMinutes == 0` or empty schedules).
   - **Rule Precedence Representation:** No priority ordering field exists in `PolicyConfig`; rule precedence must be codified deterministically in the evaluation engine.

---

## 3. Existing Parent Policy Behavior Audit

### 3.1 Behavior Mapping Table

| Parent Policy Behavior | Current Implementation Location | Proposed Evaluator Responsibility | Codebase Evidence |
|:---|:---|:---|:---|
| **Policy Authoring & Editing** | `apps/haven_app/lib/features/policies/controllers/` (`policies_controller.dart`, `app_limits_controller.dart`, etc.) | None (Authoring remains parent-only). Evaluator is a consumer of the authored `PolicyConfig`. | Controllers bind to GetX reactive state to modify and save `PolicyConfig`. |
| **Validation Rules** | `packages/haven_models/lib/src/policy_rules.dart` | Validate input before evaluation; reject unparseable time or minute values. | `PolicyRules.validateMinutesLimit`, `validateDomain`. |
| **Schedule Conflict Detection** | `packages/haven_models/lib/src/policy_conflicts.dart` | None directly during runtime evaluation; evaluator evaluates active intervals dynamically. | `ScheduleConflictDetector.findConflicts()` runs on schedule form submission. |
| **Policy Persistence** | `apps/haven_app/lib/features/policies/data/local_policies_repository.dart` | None in Step 2. Evaluator receives configuration directly via method arguments. | Stored in Postgres `device_policies` or local `PreferencesStore`. |
| **Live Policy Evaluation** | **NOT IMPLEMENTED ANYWHERE** | **Core responsibility of Step 2.** Calculates real-time policy compliance from inputs. | No evaluator exists in the codebase today. |

---

## 4. Stage 3 Child Usage Data Integration Audit

### 4.1 Usage Data Architecture & Characteristics
Stage 3 implemented child usage monitoring via Android's native `UsageStatsManager` bridge:
- **`UsageDailyResult`** (`apps/haven_child/lib/core/native/usage_envelope_models.dart`):
  - `startTimeMillis`: Epoch millis for the start of the query window.
  - `endTimeMillis`: Epoch millis for the end of the query window.
  - `totalForegroundMillis`: Total aggregate foreground screen time across all packages.
  - `dataFreshness`: Enum `UsageDataFreshness` (`recent`, `delayed`, `empty`).
  - `apps`: `List<UsageAppRecord>` with `packageName`, `totalForegroundMillis`, `isSystemApp`, `lastTimeUsedMillis`.
- **`UsageFreshnessStatus`** (`apps/haven_child/lib/features/child_usage/domain/usage_freshness_status.dart`):
  - Represents OS batching delays: `recent` (accurate), `delayed` (OS throttled/batched), `empty` (no usage recorded).
- **`ChildUsageController`** (`apps/haven_child/lib/features/child_usage/controllers/child_usage_controller.dart`):
  - In-memory only: `dailyUsage` is cleared on sign-out, permission revocation, or app close.
  - Query range is calculated from local midnight to current timestamp.

### 4.2 Handling of Missing, Stale, Delayed, or Denied Usage Data
The evaluator must be strictly honest regarding data quality:
1. **Permission Denied / Unsupported:** The evaluator **must NOT** assume 0 minutes used. It must return a status of `usageUnavailable` (or `permissionDenied`), explaining to the UI that usage cannot be measured.
2. **Missing Usage Records:** If an app is installed but has no record in `UsageDailyResult.apps`, its foreground usage is safely evaluated as 0 milliseconds.
3. **Delayed Freshness:** If `dataFreshness == UsageDataFreshness.delayed`, the evaluator evaluates against the available data but flags the result with `isDelayed: true` so the UI can display an appropriate disclosure banner.
4. **Empty Interval:** If `dataFreshness == UsageDataFreshness.empty` and `totalForegroundMillis == 0`, the evaluator evaluates quotas as 0 used while preserving the empty indicator.

---

## 5. Dependency Architecture & Isolation

### 5.1 Package Hierarchy Audit
```
packages/haven_core/ (Clock, Result, HavenFailure, Validation)
      ▲
packages/haven_models/ (PolicyConfig, PolicySchedule, PolicyRules, ScheduleConflict)
      ▲
packages/haven_offline/ (LocalStore, LocalTables)
      ▲                     ▲
apps/haven_child/     packages/haven_api/
                            ▲
                      apps/haven_app/
```

### 5.2 Isolation Rules for Step 2
1. **Pure Dart:** Must compile with Dart SDK `3.12.2` without Flutter (`dart:ui`) or GetX dependencies.
2. **Zero Platform Channels:** No MethodChannel calls or Android imports.
3. **No Direct System Clock:** Must not call `DateTime.now()`. Evaluation timestamp must be injected.
4. **No New Dependencies:** Must not add third-party packages to any `pubspec.yaml`.

---

## 6. Schedule Evaluation Analysis

### 6.1 Boundary Semantics & Interval Math
A schedule defines a time window on given weekdays (`days: [1..7]`).
- **Half-Open Interval Standard:** Schedules must be evaluated using the standard half-open interval `[start, end)`.
  - At `startTime` (inclusive), the schedule becomes active.
  - At `endTime` (exclusive), the schedule becomes inactive.
  - *Example:* `09:00 - 17:00` is active at `09:00:00` and `16:59:59`, but inactive at `17:00:00`. This prevents adjacent schedule collisions (e.g. `08:00–12:00` and `12:00–15:00`).

### 6.2 Normal Daytime Schedule
- Condition: `startTime < endTime`.
- Active if and only if:
  1. The evaluation day-of-week matches one of the schedule's `days`.
  2. The evaluation wall-clock minute satisfies: `startMinutes <= currentMinutes < endMinutes`.

### 6.3 Overnight Schedule & Cross-Midnight Continuity
- Condition: `startTime > endTime` (e.g. Bedtime `21:00` to `07:00`).
- Cross-midnight intervals span two calendar days: Day $D$ evening and Day $D+1$ morning.
- **Evaluation Logic:**
  An overnight schedule is active at evaluation timestamp $T$ if:
  1. **Evening Segment:** Day $D$ matches `schedule.days` AND `currentMinutes >= startMinutes` (from `startMinutes` to `1440`).
  2. **Morning Segment:** Yesterday (Day $D-1$) matched `schedule.days` AND `currentMinutes < endMinutes` (from `0` to `endMinutes`).
- *Concrete Example:* A bedtime schedule configured for weekdays (`days: [1, 2, 3, 4, 5]`, Mon–Fri) from `21:00` to `07:00`:
  - Monday at 21:30: Active (Mon is day 1 $\in$ days).
  - Tuesday at 06:30: Active (Mon was day 1 $\in$ days).
  - Saturday at 06:30: Active (Fri was day 5 $\in$ days).
  - Sunday at 22:00: Inactive (Sun is day 7 $\notin$ days).
  - Monday at 06:30: Inactive (Sun was day 7 $\notin$ days).

---

## 7. Time-Zone & Daylight Saving Time (DST) Limitations

### 7.1 Time-Zone Semantics
1. **Wall-Clock Interpretation:** In parental control, a schedule set for "21:00" represents 9:00 PM **local child wall-clock time**, not UTC.
2. **Evaluation Timestamp Standard:** The evaluation caller must provide an evaluation `DateTime`. If the `DateTime` is UTC, it must be evaluated in conjunction with the device's local timezone offset (`evaluationTime.timeZoneOffset`) or passed as a local `DateTime`.
3. **No External Timezone Package:** Without introducing third-party timezone databases, evaluation relies on standard Dart `DateTime.toLocal()` or an explicit offset in the input context.

### 7.2 DST Transition Edge Cases
- **Spring Forward (23-hour day):** The 02:00–03:00 window may not exist locally. Schedules falling entirely within the skipped hour will not trigger.
- **Fall Back (25-hour day):** The 01:00–02:00 window repeats. Evaluating against wall-clock minutes will remain active throughout the repeated wall-clock hour.
- **Limitation Acknowledgment:** Pure-Dart evaluation accurately evaluates local wall-clock minutes against static schedule windows, but duration calculations across midnight during DST shifts may vary by $\pm 60$ minutes.

---

## 8. Daily Quota Evaluation

### 8.1 Quota Evaluation Rules
Given:
- `dailyLimitMinutes = policyConfig.dailyScreenTimeMinutes`
- `usedMinutes = (usageResult.totalForegroundMillis / 60000).floor()`
- `remainingMinutes = max(0, dailyLimitMinutes - usedMinutes)`

### 8.2 Discrete Quota States
| State | Condition | Meaning |
|:---|:---|:---|
| `withinLimit` | `usedMinutes < dailyLimitMinutes` | Screen time remaining; normal operation. |
| `limitReached` | `usedMinutes == dailyLimitMinutes` | Exact threshold reached. |
| `limitExceeded` | `usedMinutes > dailyLimitMinutes` | Daily allowance exhausted. |
| `unlimited` | `dailyLimitMinutes == 0` (or unconfigured) | No global screen time cap in effect. |
| `unavailable` | Usage data missing, denied, or error | Cannot determine quota status. |

---

## 9. Per-Application Limit Evaluation

### 9.1 Package-Level Resolution
For each application package evaluated:
1. **Global Blocklist Check:** If `policyConfig.blockedApps.contains(packageName)`, status is `blocked` (always blocked by parent).
2. **Per-App Time Limit Check:** If `policyConfig.appLimits.containsKey(packageName)`:
   - `appLimitMinutes = policyConfig.appLimits[packageName]!`
   - `appUsedMinutes = (appRecord.totalForegroundMillis / 60000).floor()`
   - If `appUsedMinutes >= appLimitMinutes`: status is `appLimitReached`.
3. **Global Whitelist:** If `policyConfig.allowedApps.contains(packageName)`, the app is marked as explicitly approved.

---

## 10. Security & Privacy Boundaries

1. **Information Only:** The evaluation engine evaluates policy compliance and produces an immutable report; it **never** executes native kill signals, accessibility overlays, or VPN blocking.
2. **Transient In-Memory:** Evaluation results must not be written to persistent storage or transmitted over the network in Step 2.
3. **Disclosure Requirement:** Every evaluation result must carry an honest metadata disclosure: `"Evaluation is local and informational only; application blocking is not enforced."`

---

## 11. Existing Gaps, Risks & Mitigation

| Identified Gap / Risk | Impact | Architectural Mitigation |
|:---|:---|:---|
| **No Emergency Apps in Model** | Risk of classifying dialer/emergency services as restricted. | Evaluator will enforce an immutable hardcoded exempt list (e.g. `com.android.phone`, `com.google.android.dialer`, emergency packages) having absolute highest precedence. |
| **Ambiguous Master Switch** | No `isEnabled` flag in `PolicyConfig`. | Evaluator evaluates active rules; if all schedules are inactive and limits are 0, status evaluates to `allAllowed`. |
| **DST Wall-Clock Skew** | Minor schedule offset during daylight savings switchover. | Evaluate strictly against wall-clock `evaluationTime.hour` and `evaluationTime.minute`. |
| **Usage Data Latency** | Android OS batches usage stats (up to a few minutes delay). | Propagate `UsageDataFreshness` in evaluation result and expose clear UI warning. |

---

### Audit Conclusion
The canonical models from Step 1 and the usage contracts from Stage 3 provide complete, sound foundations for implementing a pure-Dart deterministic evaluation engine in Step 2.
