# HAVEN STAGE 4 — STEP 2 SUB-STEP 2.3 PRE-IMPLEMENTATION AUDIT
## Core Schedule & Interval Evaluation Engine

**Document Version:** 1.1.0-FINAL-TIMEZONE-NORMALIZED  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Current Reported HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Target Milestone:** Stage 4 Step 2 — Sub-step 2.3  
**Status:** SUB-STEP 2.3 SPECIFICATION FINALIZED — AWAITING SEPARATE OWNER IMPLEMENTATION AUTHORIZATION  
**Execution Mode:** STRICT READ-ONLY PRE-IMPLEMENTATION AUDIT (DOCUMENTATION-ONLY)  
**Implementation Authorization:** NOT GRANTED  

---

## 1. Executive Summary & Git Preflight

### 1.1 Scope of Sub-Step 2.3
Sub-step 2.3 establishes the pure-Dart recurring schedule and interval evaluation engine consumed by the future policy evaluator.
This audit incorporates all seven owner decisions (Decisions 2.19 through 2.25), reconciles existing schedule models and conflict logic, enforces device-local timezone normalization, verifies decision traceability, and synchronizes the authoritative execution plan:
1. **Decision 2.19 (Half-Open Interval Boundary Standard):** Intervals operate on `[startTime, endTime)`. Exact start minute is ACTIVE; exact end minute is INACTIVE. When `startTime == endTime`, the interval duration is zero and the schedule is INACTIVE at all times.
2. **Decision 2.20 (Malformed Schedule Time Strings):** Defensive parsing ensures unparseable or out-of-range time strings evaluate as fail-safe INACTIVE without runtime exceptions.
3. **Decision 2.21 (Evaluation Result Structure):** Produces an immutable `ScheduleEvaluationResult` containing `isAnyScheduleActive`, `isBedtimeActive`, `isSchoolActive`, `activeSchedules`, `allowedAppExceptions`, and `isAppAllowed(packageName)`.
4. **Decision 2.22 (No Active Schedules Semantics):** When no schedules are active, restrictions do not apply (`isAnyScheduleActive == false`). An empty exception set must NOT independently be interpreted as lockdown when no schedule is active; callers must check `isAnyScheduleActive`.
5. **Decision 2.23 (Weekday Validation):** Weekdays are ISO 8601 integers `1` (Monday) through `7` (Sunday). Empty `days` never activates. Out-of-bounds values outside `1..7` cause the schedule to be rejected and evaluated as fail-safe INACTIVE.
6. **Decision 2.24 (Device-Local Time, Normalization and DST):** Evaluation uses device-local wall-clock time derived via explicit local normalization (`evaluationTime.toLocal()`). During a DST repeated hour, both occurrences match the configured schedule. External timezone dependencies are prohibited.
7. **Decision 2.25 (Minute Precision):** Schedule values express `HH:mm`. Evaluation compares hour and minute only; seconds and milliseconds are ignored.

### 1.2 Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`
- **Working Tree State:**
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_EXECUTION_PLAN.md` (v1.6.1 synchronized execution plan)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md` (Staged audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_PLAN_VALIDATION_AUDIT.md` (Staged validation audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_READINESS_AUDIT.md` (Staged readiness audit)
  - `AM docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_1_PREIMPLEMENTATION_AUDIT.md` (Sub-step 2.1 audit)
  - `AM docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_2_PREIMPLEMENTATION_AUDIT.md` (Sub-step 2.2 audit)
  - `?? docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_3_PREIMPLEMENTATION_AUDIT.md` (This document)
  - ` M packages/haven_models/lib/haven_models.dart` (Sub-step 2.1 & 2.2 exports)
  - `?? packages/haven_models/lib/src/policy_evaluator/` (Sub-step 2.1 & 2.2 source)
  - `?? packages/haven_models/test/policy_evaluator/` (Sub-step 2.1 & 2.2 tests)
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Authoritative Register of Decisions 2.19–2.25

All seven decisions below were explicitly approved by the owner for Sub-step 2.3:

| # | Topic | Approved Option | Core Architectural Contract |
|:---:|:---|:---:|:---|
| **2.19** | **Half-Open Interval Boundary Standard** | **Option A** | Schedule intervals use `[startTime, endTime)`. Exact start minute is ACTIVE; exact end minute is INACTIVE. When `startTime == endTime`, the interval is zero duration and INACTIVE at all times. Applies consistently to normal and overnight schedules. |
| **2.20** | **Malformed Schedule Time Strings** | **Option A** | Parse time strings defensively. Invalid or unparseable time strings must never cause runtime exceptions in the evaluator; schedules with invalid start or end times evaluate as fail-safe INACTIVE. Never fabricate valid times from malformed inputs. |
| **2.21** | **Evaluation Result Structure** | **Option A** | Proposed immutable `ScheduleEvaluationResult` containing `isAnyScheduleActive`, `isBedtimeActive`, `isSchoolActive`, `activeSchedules`, `allowedAppExceptions`, and `isAppAllowed(packageName)`. Collections must be immutable (`List.unmodifiable`, `Set.unmodifiable`). |
| **2.22** | **No Active Schedules Semantics** | **Option A** | When no schedules are active, schedule restrictions do not apply (`isAnyScheduleActive == false`). `activeSchedules` is empty, and `allowedAppExceptions` is empty. An empty exception set must NOT independently be interpreted as lockdown when no schedule is active. Callers must check `isAnyScheduleActive` before applying schedule restrictions. |
| **2.23** | **Weekday Validation** | **Option A** | Valid weekday values are ISO 8601 integers: 1 (Monday) through 7 (Sunday). Empty `days` means the schedule never activates. Any invalid weekday values outside 1–7 cause the schedule to be rejected and evaluated as fail-safe INACTIVE. Do not silently ignore invalid entries and partially activate the schedule. |
| **2.24** | **Device-Local Time, Normalization and DST** | **Option A** | Schedule matching uses device-local wall-clock time derived via explicit local normalization (`evaluationTime.toLocal()`). During a DST repeated hour, both occurrences match the configured wall-clock time. Zero UTC conversion for schedule matching and zero external timezone dependencies. Document Dart `DateTime` timezone limitations. |
| **2.25** | **Minute Precision** | **Option A** | Schedules express `HH:mm`. Evaluation compares hour and minute only; seconds and milliseconds are ignored. Derive current minute-of-day from normalized local hour and minute. Half-open boundaries apply at minute precision (e.g. 08:00:59 is minute 480 and active; 15:00:00 is minute 900 and inactive for an 08:00–15:00 schedule). |

### 2.1 Confirmation of Decisions 2.1–2.18
All previous decisions remain 100% active and unchanged:
- **Decision 2.1:** Parent whitelist bypasses global daily quota only; does not bypass active schedules.
- **Decision 2.2 & 2.10:** Emergency defaults are exempt from active schedules unless explicitly listed in parent `blockedApps`.
- **Decision 2.6:** Overlapping active schedules resolve via **restrictive intersection** ($\bigcap s.\text{allowedApps}$).
- **Decision 2.8:** Parent `blockedApps` is an absolute hard veto over schedule whitelists.
- **Decision 2.11:** Bedtime default whitelist is empty (`[]`). Restrictive intersection ensures School or Custom schedule whitelists cannot override active Bedtime.
- **Decision 2.14:** Evaluator inputs `PolicyEvaluationContext` and `PolicyUsageSnapshot` remain independent.
- **Decision 2.15:** Full policy evaluation output models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`) are deferred to Sub-step 2.4.
- **Decision 2.18:** Child device-local calendar date semantics remain authoritative.

### 2.2 Emergency Schedule Exemption Traceability Analysis
A rigorous inspection of authoritative Owner Decision records and pre-implementation audits confirms the exact textual and decision basis for the rule *"Emergency defaults are exempt from active schedules unless in parent blockedApps"*:
1. **Decision 2.2 Approval:** Decision 2.2 established the immutable standard emergency package set (`com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`).
2. **Explicit Schedule Exemption in Precedence Rules:** In `STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md`, Principle **PR-02** explicitly states:
   > *"Standard emergency/telecom packages are exempt from all bedtime, schedule, and quota restrictions. | OWNER APPROVED"*
   Furthermore, the Conflict Resolution Matrix in Section 3.2 of the same document explicitly records:
   > *Row 116: Emergency App vs Bedtime Schedule $\rightarrow$ Emergency App Wins (Allowed). Reason: Child safety: Emergency calls/dialer must never be blocked during sleep hours. Status: OWNER APPROVED (Decision 2.2).*
   > *Row 117: Emergency App vs School Schedule $\rightarrow$ Emergency App Wins (Allowed). Status: OWNER APPROVED (Decision 2.2).*
3. **Execution Plan Precedence Alignment:** In `STAGE_4_STEP_2_EXECUTION_PLAN.md`, Section 3 (Priority Level 2) and Section 4 (Conflict Rows C-06 and C-07) affirm that emergency defaults are exempt from bedtime and school schedules (*"Approved (Decision 2.2)"*).
4. **Parent Blocklist Hard Veto Subordination (Decision 2.10):** Decision 2.10 explicitly ruled that explicit parent `PolicyConfig.blockedApps` takes precedence over emergency defaults:
   > *"Parent Blocklist vs Emergency Defaults [APPROVED: Option A]: Explicit parent PolicyConfig.blockedApps takes precedence even over the emergency default package set... Emergency exemption applies strictly after checking the parent blocklist."*
5. **Synthesis:** The combined rule *"Emergency defaults are exempt from active schedules (Decision 2.2, PR-02, C-06, C-07) unless explicitly present in parent blockedApps (Decision 2.10, C-01)"* is fully grounded in explicit owner approvals.
6. **Strict Scope Boundary in Sub-Step 2.3:** Sub-step 2.3 (`ScheduleEvaluator`) evaluates ONLY schedule intervals and schedule allowed app whitelists (`ScheduleEvaluationResult`). It does **NOT** evaluate emergency exemptions, parent blocklists, or quotas. Full evaluation of emergency defaults and their precedence over schedules is deferred exclusively to Sub-step 2.4 (`PolicyEvaluator`).

---

## 3. Existing Schedule Architecture & Source Evidence

### 3.1 Model Inspection: `packages/haven_models/lib/src/policy_schedules.dart`
The existing `PolicySchedule` model contains:
- `id`: Unique identifier (`String`).
- `name`: Human-readable label (`String`).
- `type`: `PolicyScheduleType` (`bedtime`, `school`, `custom`).
- `startTime`: 24-hour time string `'HH:mm'` (default `'21:00'`).
- `endTime`: 24-hour time string `'HH:mm'` (default `'07:00'`).
- `days`: `List<int>` representing active days (default `[1, 2, 3, 4, 5, 6, 7]`).
- `isActive`: Boolean enable toggle (default `true`).
- `allowedApps`: `List<String>` package exceptions (default `const []`).
- `category`: Optional grouping (`String?`).
- `isOvernight`: Getter returning `startMinutes > endMinutes`.
- `isValidTime(String time)`: RegEx validator `^([01]\d|2[0-3]):([0-5]\d)$`.

### 3.2 Conflict Inspection: `packages/haven_models/lib/src/policy_conflicts.dart`
`ScheduleConflictDetector` provides conflict detection between schedules:
- `_toMinutes`: Parses `'HH:mm'` into minutes-of-day.
- `_toDailyIntervals(int start, int end)`: Splices overnight intervals into `[(start, 1440), (0, end)]`. Note that for `start == end`, `_toDailyIntervals` returns a 24-hour interval; Sub-step 2.3 resolves this via Decision 2.19 by explicitly handling `start == end` as zero duration.

### 3.3 UI Controller Inspection: `apps/haven_app/.../schedules_editor_controller.dart`
The parent management UI creates, updates, and deletes `PolicySchedule` instances. Inactive schedules (`isActive == false`) are kept in configuration but disabled. Empty `allowedApps` corresponds to "Block all non-emergency apps" in the editor UI.

---

## 4. Schedule Interval Evaluation Math & Minute Precision

### 4.1 Device-Local Time Normalization & Minute Precision (Decisions 2.24, 2.25)
Local wall-clock time is extracted from the supplied `DateTime evaluationTime` after explicit local normalization:
```dart
final localTime = evaluationTime.toLocal();
final weekday = localTime.weekday;
final currentMinutes = localTime.hour * 60 + localTime.minute;
```
Sub-minute components (`localTime.second`, `localTime.millisecond`, `localTime.microsecond`) are discarded.

### 4.2 Half-Open Boundaries: `[startTime, endTime)` (Decision 2.19)
- Exact start minute is ACTIVE: $\text{currentMinutes} \ge \text{startMinutes}$.
- Exact end minute is INACTIVE: $\text{currentMinutes} < \text{endMinutes}$.

| Timestamp | Evaluated Minute | Schedule `08:00–15:00` State | Mathematical Rationale |
|---|:---:|:---:|---|
| `2026-11-18 07:59:59` | 479 | **INACTIVE** | $479 < 480$ |
| `2026-11-18 08:00:00` | 480 | **ACTIVE** | $480 \ge 480$ and $480 < 900$ |
| `2026-11-18 08:00:59` | 480 | **ACTIVE** | Seconds ignored; minute 480 is active |
| `2026-11-18 14:59:59` | 899 | **ACTIVE** | $899 < 900$ |
| `2026-11-18 15:00:00` | 900 | **INACTIVE** | $900 \not< 900$ (Half-open end exclusive) |

### 4.3 Normal Daytime Interval (`start < end`)
For daytime intervals (e.g. School Hours `08:00` to `15:00`):
$$\text{isActive} = \text{days}.\text{contains}(\text{currentDay}) \land (\text{currentMinutes} \ge \text{start}) \land (\text{currentMinutes} < \text{end})$$

### 4.4 Overnight Cross-Midnight Rollover (`start > end`)
For overnight intervals spanning midnight (e.g. Bedtime `21:00` to `07:00`):
The schedule spans two calendar days:
1. **Evening Segment (Day $D$):**
   - Active on day $D$ if `days.contains(currentDay)` AND $\text{currentMinutes} \ge \text{start}$.
2. **Morning Segment (Day $D+1$):**
   - Active on day $D+1$ if `days.contains(previousDay)` AND $\text{currentMinutes} < \text{end}$.
   - Where $\text{previousDay} = (\text{currentDay} == 1) ? 7 : (\text{currentDay} - 1)$.

### 4.5 Zero-Duration Intervals (`start == end`) (Decision 2.19)
When `start == end` (e.g. `12:00` to `12:00`), the interval is $[t, t) = \emptyset$.
The schedule is considered zero duration and evaluates as **INACTIVE** at all times.

### 4.6 Defensive Time String Parsing (Decision 2.20)
`_parseMinutes(String time)` parses defensively:
- Must contain exactly 2 parts separated by `:`.
- `h = int.tryParse(parts[0])`, `m = int.tryParse(parts[1])`.
- Verified in bounds: $0 \le h \le 23$ and $0 \le m \le 59$.
- If invalid or unparseable, returns `null`.
- A schedule with `null` start or end time evaluates as fail-safe **INACTIVE** (`false`) without throwing runtime exceptions.

---

## 5. Weekday Validation & Fail-Safe Inactive Contract (Decision 2.23)

### 5.1 Existing Model Analysis
`PolicySchedule` constructor does not enforce bounds checking on `days`. A schedule instantiated with invalid integers (e.g. `[0, 8, -1]`) can exist in memory.

### 5.2 Evaluator Fail-Safe Behavior
To maintain model immutability without breaking existing callers in Sub-step 2.3:
1. **Empty Days:** If `schedule.days.isEmpty`, the schedule never activates $\rightarrow$ returns `false`.
2. **Invalid Weekday Rejection:** If `schedule.days.any((d) => d < 1 || d > 7)`, the schedule contains corrupt data. The evaluator rejects the schedule and treats it as fail-safe **INACTIVE** (`false`).
3. **No Partial Activation:** The evaluator must **never** filter out invalid entries and activate the schedule on the remaining valid days.

---

## 6. Device-Local Wall-Clock, Normalization & DST Semantics (Decision 2.24)

### 6.1 Device-Local Matching & Local Normalization
All schedule matching evaluates against child device-local wall-clock time:
- Injected via `DateTime evaluationTime`.
- **Local Normalization Requirement:** Callers may pass local or UTC `DateTime` values. The evaluator normalizes the instant via `final localTime = evaluationTime.toLocal();`.
- **Normalization Semantics:** `toLocal()` performs local normalization (ensuring device-local wall-clock fields are queried), **not** conversion to UTC.
- Derives `currentDay = localTime.weekday`, `currentHour = localTime.hour`, `currentMinute = localTime.minute`.
- `DateTime.now()` is strictly prohibited in the evaluator.
- Zero conversion to UTC for schedule matching; UTC hour/weekday must not be used.

### 6.2 Weekday Boundary Crossover Handling
When an instant is represented in UTC, its UTC weekday may differ from the device-local weekday (e.g. UTC instant `2026-11-18 02:30:00 UTC` is `2026-11-17 21:30:00` in UTC-5). Explicit `toLocal()` normalization guarantees that schedule matching evaluates against the correct local weekday (`Tuesday`), ensuring seamless consistency regardless of whether the caller provided a UTC or local `DateTime`.

### 6.3 Daylight Saving Time (DST) Fall-Back
When a local timezone undergoes a daylight saving "fall-back" transition (e.g. 01:00:00 to 01:59:59 repeats twice):
- Both occurrences share identical local wall-clock hour and minute (`1:xx`).
- Both occurrences evaluate to identical schedule active states where deterministic test infrastructure permits.

### 6.4 Dart `DateTime` Limitations
Dart's core `DateTime` does not carry named IANA timezone identifiers (e.g. `America/Chicago`). Timezone offset changes between evaluations are handled seamlessly because the evaluator depends only on the numeric local fields of the normalized `localTime`.

---

## 7. Multi-Schedule Restrictive Intersection & Bedtime Lockdown

### 7.1 Restrictive Intersection (Decision 2.6)
When multiple schedules are active at the same instant (e.g. a School Focus schedule and a Custom Study schedule):
$$\text{AllowedAppExceptions} = \bigcap_{s \in \text{activeSchedules}} s.\text{allowedApps}$$
An application is permitted during concurrent schedules **only if it is present in ALL active schedule exception whitelists**.

### 7.2 Bedtime Lockdown Protection (Decision 2.11)
- Bedtime defaults to `allowedApps: const []` (zero exceptions).
- Since $\emptyset \cap S = \emptyset$ for any set $S$:
- Whenever Bedtime is active, `AllowedAppExceptions` is guaranteed to be empty ($\emptyset$).
- No School or Custom schedule whitelist can puncture Bedtime lockdown.

---

## 8. "No Active Schedules" Contract & Caller Invariants (Decision 2.22)

### 8.1 Critical Distinction
When no schedules are active:
- `isAnyScheduleActive == false`.
- `activeSchedules` is empty `[]`.
- `allowedAppExceptions` is empty `{}`.
- **CRITICAL:** An empty `allowedAppExceptions` set does **NOT** indicate lockdown when no schedules are active. It simply reflects that no schedule exception sets were aggregated.

### 8.2 Caller Invariant
Callers (specifically `PolicyEvaluator` in Sub-step 2.4) must check `isAnyScheduleActive`:
```dart
if (scheduleResult.isAnyScheduleActive) {
  // Check schedule whitelist:
  if (!scheduleResult.isAppAllowed(packageName)) {
    return AppPolicyStatus.scheduleRestricted;
  }
}
// Proceed to daily quota and app limits if no schedule is active...
```
Evaluating `scheduleResult.isAppAllowed(packageName)` alone without checking `isAnyScheduleActive` is an invariant violation.

---

## 9. Proposed API Design & Type Contracts

### 9.1 File Location: `packages/haven_models/lib/src/policy_evaluator/schedule_evaluator.dart`

```dart
import 'package:meta/meta.dart';
import '../policy_schedules.dart';

/// Pure-Dart evaluation result for active policy schedules at an evaluation instant.
@immutable
final class ScheduleEvaluationResult {
  ScheduleEvaluationResult({
    required this.isAnyScheduleActive,
    required this.isBedtimeActive,
    required this.isSchoolActive,
    required List<PolicySchedule> activeSchedules,
    required Set<String> allowedAppExceptions,
  })  : activeSchedules = List.unmodifiable(activeSchedules),
        allowedAppExceptions = Set.unmodifiable(allowedAppExceptions);

  /// True if at least one schedule is currently active.
  final bool isAnyScheduleActive;

  /// True if an active schedule is of type [PolicyScheduleType.bedtime].
  final bool isBedtimeActive;

  /// True if an active schedule is of type [PolicyScheduleType.school].
  final bool isSchoolActive;

  /// Unmodifiable list of all schedules active at evaluation time.
  final List<PolicySchedule> activeSchedules;

  /// Set of package names permitted across ALL active schedules via restrictive intersection.
  /// IMPORTANT (Decision 2.22): Empty when no schedules are active.
  /// Callers must check [isAnyScheduleActive] before enforcing restrictions.
  final Set<String> allowedAppExceptions;

  /// Helper checking if [packageName] is in [allowedAppExceptions].
  /// Callers MUST verify [isAnyScheduleActive] before treating false as a restriction.
  bool isAppAllowed(String packageName) => allowedAppExceptions.contains(packageName);
}

/// Pure-Dart deterministic evaluator for recurring schedules and intervals.
abstract final class ScheduleEvaluator {
  /// Evaluates whether a single schedule is active at [evaluationTime].
  static bool isScheduleActive(PolicySchedule schedule, DateTime evaluationTime) {
    if (!schedule.isActive) return false;
    if (schedule.days.isEmpty) return false;
    if (schedule.days.any((d) => d < 1 || d > 7)) return false;

    final start = _parseMinutes(schedule.startTime);
    final end = _parseMinutes(schedule.endTime);
    if (start == null || end == null || start == end) return false;

    final localTime = evaluationTime.toLocal();
    final currentDay = localTime.weekday;
    final currentMinutes = localTime.hour * 60 + localTime.minute;

    if (start < end) {
      return schedule.days.contains(currentDay) &&
          currentMinutes >= start &&
          currentMinutes < end;
    } else {
      final isEveningMatch = schedule.days.contains(currentDay) &&
          currentMinutes >= start;
      final previousDay = currentDay == 1 ? 7 : currentDay - 1;
      final isMorningMatch = schedule.days.contains(previousDay) &&
          currentMinutes < end;
      return isEveningMatch || isMorningMatch;
    }
  }

  /// Evaluates all active schedules in [schedules] at [evaluationTime]
  /// and computes restrictive whitelist intersection.
  static ScheduleEvaluationResult evaluate({
    required List<PolicySchedule> schedules,
    required DateTime evaluationTime,
  }) { ... }
}
```

---

## 10. Comprehensive Unit Test Matrix

The following unit test categories must be implemented in `schedule_evaluator_test.dart`:

| # | Test Category | Scenario & Inputs | Expected Result | Owner Basis |
|:---:|:---|:---|:---|:---:|
| **T-01** | **Normal Weekday Matching** | Local DateTime input matches expected local weekday and time | `isScheduleActive == true` | Core interval |
| **T-02** | **Start Inclusive Boundary** | Monday 08:00, Schedule 08:00–15:00 | `isScheduleActive == true` | Decision 2.19 (`[start, end)`) |
| **T-03** | **End Exclusive Boundary** | Monday 15:00, Schedule 08:00–15:00 | `isScheduleActive == false` | Decision 2.19 (`[start, end)`) |
| **T-04** | **Minute Precision (Seconds Ignored)** | Monday 08:00:59, Schedule 08:00–15:00 | `isScheduleActive == true` | Decision 2.25 |
| **T-05** | **Overnight Evening Segment** | Monday 21:30, Schedule Mon (1) 21:00–07:00 | `isScheduleActive == true` | Decision 2.19 / Overnight |
| **T-06** | **Overnight Morning Segment** | Tuesday 06:30, Schedule Mon (1) 21:00–07:00 | `isScheduleActive == true` (rolled from Mon) | Decision 2.19 / Overnight |
| **T-07** | **Sunday-to-Monday Rollover** | Monday 05:00, Schedule Sun (7) 21:00–07:00 | `isScheduleActive == true` (`previousDay = 7`) | Decision 2.19 / Rollover |
| **T-08** | **Equal Start/End Inactive** | Monday 12:00, Schedule 12:00–12:00 | `isScheduleActive == false` (zero-duration) | Decision 2.19 ($[t, t) = \emptyset$) |
| **T-09** | **Empty Weekdays List** | Monday 10:00, Schedule `days: []` 08:00–15:00 | `isScheduleActive == false` | Decision 2.23 |
| **T-10** | **Invalid Weekday Rejection** | Monday 10:00, Schedule `days: [1, 8]` 08:00–15:00 | `isScheduleActive == false` (rejected fail-safe) | Decision 2.23 |
| **T-11** | **Malformed Time Strings** | Monday 10:00, Schedule `startTime: "bad:time"` | `isScheduleActive == false` (no exceptions) | Decision 2.20 |
| **T-12** | **Disabled Schedule Exclusion** | Monday 10:00, Schedule `isActive: false` | `isScheduleActive == false` | Core model |
| **T-13** | **No Active Schedules** | Monday 10:00, Empty schedules list | `isAnyScheduleActive == false`, empty exceptions | Decision 2.22 |
| **T-14** | **Caller Checks isAnyScheduleActive** | Monday 10:00, Inactive schedules | Result has empty exceptions, but `isAnyScheduleActive == false` | Decision 2.22 |
| **T-15** | **Two-Schedule Whitelist Intersection** | Active S1 allowed: `['a', 'b']`, S2 allowed: `['b', 'c']` | `allowedAppExceptions == {'b'}` | Decision 2.6 |
| **T-16** | **Empty Whitelist Intersection** | Active S1 allowed: `['a']`, S2 allowed: `[]` | `allowedAppExceptions == {}` | Decision 2.6 |
| **T-17** | **Bedtime Lockdown Protection** | Active Bedtime (empty whitelist) + Active School | `allowedAppExceptions == {}`, Bedtime active | Decision 2.11 |
| **T-18** | **UTC DateTime Normalization** | UTC input representing same instant produces identical result to local input | `isScheduleActive(s, utc) == isScheduleActive(s, local)` | Decision 2.24 / Normalization |
| **T-19** | **UTC/Local Weekday Crossover** | UTC instant whose UTC weekday differs from local matches correct local weekday | Matches device-local weekday | Decision 2.24 / Normalization |
| **T-20** | **DST Repeated-Hour Matching** | First 01:30 and repeated 01:30 fall-back | Both evaluate as `isScheduleActive == true` | Decision 2.24 |
| **T-21** | **Deterministic Repeated Evaluation** | Evaluate same inputs 100 times; zero clock access (`DateTime.now()`) | 100 identical results, zero clock drift | Pure-Dart invariant |

---

## 11. Exact Proposed Implementation Scope

When explicitly authorized, Sub-step 2.3 will create/modify:
1. `packages/haven_models/lib/src/policy_evaluator/schedule_evaluator.dart` (~140 lines, $\le 200$).
2. `packages/haven_models/test/policy_evaluator/schedule_evaluator_test.dart` (~195 lines, $\le 200$).
3. `packages/haven_models/lib/haven_models.dart` (canonical export registration).
4. Package verification:
   - `fvm dart analyze packages/haven_models`
   - `fvm dart test packages/haven_models`

---

## 12. Strict Boundary Verifications & Safety Declarations

1. **Zero Source Modifications:** No source code in `packages/` or `apps/` was modified.
2. **Zero Test Modifications:** No unit or integration tests were created or modified.
3. **Zero Dependency Modifications:** `pubspec.yaml` files remain 100% untouched.
4. **Git Index & History Untouched:** Zero Git mutating commands were executed.
5. **Sub-Steps 2.3 & 2.4 Status:** Sub-step 2.3 implementation is **NOT STARTED**. Sub-step 2.4 is **NOT AUTHORIZED**.

---

## 13. Final Status Verdict

`SUB-STEP 2.3 FINAL SPECIFICATION TECHNICALLY VERIFIED — AWAITING OWNER IMPLEMENTATION AUTHORIZATION`
