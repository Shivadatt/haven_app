# HAVEN STAGE 4 — STEP 2 SUB-STEP 2.2 PRE-IMPLEMENTATION AUDIT
## Pure-Dart Usage Snapshot & Output Contracts

**Document Version:** 1.3.0-FINAL-UNKNOWN-FRESHNESS-CONFIRMED  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Current Reported HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`  
**Target Milestone:** Stage 4 Step 2 — Sub-step 2.2  
**Status:** SUB-STEP 2.2 SPECIFICATION FINALIZED — AWAITING SEPARATE OWNER IMPLEMENTATION AUTHORIZATION  
**Execution Mode:** STRICT READ-ONLY PRE-IMPLEMENTATION AUDIT  
**Implementation Authorization:** NOT GRANTED  

---

## 1. Executive Summary & Git Preflight

### 1.1 Scope of Sub-Step 2.2
Sub-step 2.2 establishes the pure-Dart representation of transient hardware usage telemetry consumed by the future policy evaluation engine.
This audit reconciles all five owner decisions (Decisions 2.14 through 2.18), resolves native empty-freshness mapping, and synchronizes the authoritative execution plan:
1. **Decision 2.14 (Context and Snapshot Relationship):** `PolicyEvaluationContext` and `PolicyUsageSnapshot` are strictly separate, independent inputs passed to `PolicyEvaluator.evaluate(context, usage)`. Sub-step 2.1 files remain 100% untouched.
2. **Decision 2.15 (Output Model Scope Synchronization):** Sub-step 2.2 implements *only* `PolicyUsageSnapshot` and its supporting enums (`PolicyUsageCompleteness`, `PolicyUsageFreshness`). Evaluation outcome models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`, `PolicyOverallState`, `AppPolicyStatus`) are explicitly allocated to Sub-step 2.4. `STAGE_4_STEP_2_EXECUTION_PLAN.md` has been updated to `v1.5.0-SUBSTEP-SYNCHRONIZED`.
3. **Decision 2.16 (Missing Usage & Completeness Evidence):** Missing package entries resolve to `0` minutes **only** when explicit trusted evidence confirms the snapshot is complete and usage permission is granted. Incomplete, unverified, or denied telemetry resolves to `null` (unknown/unmeasured).
4. **Decision 2.17 (Capture Time vs Telemetry Freshness):** `snapshotTime` (capture instant used for age/staleness) is kept completely separate from `freshness` (native telemetry recency: `recent`, `delayed`, `unknown`, `unavailable`). A freshly captured snapshot can still contain delayed telemetry.
5. **Decision 2.18 (Local Calendar Date & Timezone):** Date comparison uses full year, month, and day (`year == other.year && month == other.month && day == other.day`). Local wall-clock midnight of the child device is authoritative. Dart `DateTime` limitations regarding named IANA timezone identifiers and timezone changes between capture and evaluation are explicitly documented without adding dependencies.
6. **Issue A (Native Empty Freshness Mapping):** Stage 3 native `FRESHNESS_EMPTY` exhibits information loss regarding whether unflushed OS buffers exist. Telemetry freshness safely maps to `PolicyUsageFreshness.unknown` when empty evidence cannot prove recency or delay. Activity state is derived independently as `isEmptyActivity: true`.
7. **Production Runtime Validation:** Enforced via imperative constructor checks throwing `ArgumentError`. Dart `assert` is not relied upon for production input enforcement. Every public constructor/factory enforces validation without bypass.

### 1.2 Git Preflight Verification
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Base HEAD:** `711b209aed99f8e024fc8c924c8b30ecb10849e8`
- **Working Tree State (`git status --short --branch`):**
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_EXECUTION_PLAN.md` (v1.5.0 synchronized execution plan)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md` (Staged audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_PLAN_VALIDATION_AUDIT.md` (Staged validation audit)
  - `A  docs/implementation/phase_4/STAGE_4_STEP_2_READINESS_AUDIT.md` (Staged readiness audit)
  - `AM docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_1_PREIMPLEMENTATION_AUDIT.md` (Updated specification)
  - ` M packages/haven_models/lib/haven_models.dart` (Sub-step 2.1 export)
  - `?? docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_2_PREIMPLEMENTATION_AUDIT.md` (This specification document)
  - `?? packages/haven_models/lib/src/policy_evaluator/` (Sub-step 2.1 source)
  - `?? packages/haven_models/test/policy_evaluator/` (Sub-step 2.1 test)
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Authoritative Register of Decisions 2.14–2.18

| # | Topic | Approved Option | Core Architectural Contract |
|:---:|:---|:---:|:---|
| **2.14** | **Context and Snapshot Relationship** | **Option A** | Evaluator receives two independent inputs: `PolicyEvaluationContext` and `PolicyUsageSnapshot` (`evaluate(context, usage)`). Do NOT add a usage reference to `PolicyEvaluationContext`. Keep policy/quota context separate from transient hardware telemetry. Sub-step 2.1 source files remain 100% untouched. |
| **2.15** | **Output Model Scope** | **Option A** | Sub-step 2.2 implements *only* `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and snapshot-specific conversion helpers. Defer `PolicyEvaluationResult`, `DailyQuotaEvaluation`, and `AppEvaluation` to Sub-step 2.4 so they can be implemented and tested concurrently with the evaluator engine. |
| **2.16** | **Missing Usage and Completeness** | **Option A** | A missing package entry resolves to `0` usage **only** when: (1) explicit evidence confirms the snapshot is complete for the interval and package population, AND (2) usage permission is granted. Otherwise, missing package resolves to `null` (unknown/unmeasured). The existing Stage 3 native envelope does not carry completeness evidence; trusted callers must supply it explicitly. |
| **2.17** | **Capture Time vs Telemetry Freshness** | **Option A** | Keep independent: `snapshotTime` (capture instant for staleness evaluation) and `freshness` (native telemetry recency: `recent`, `delayed`, `unknown`, `unavailable`). A freshly captured snapshot can still contain delayed telemetry. Fresh capture time does not convert delayed telemetry into realtime. |
| **2.18** | **Local Calendar Date and Timezone** | **Option A** | Device-local calendar date semantics. Compare full year, month, and day (never compare `.day` alone). The child device's local wall-clock is authoritative. Across midnight transitions, previous-day snapshots are recognized as mismatched. Document Dart `DateTime` limitation regarding named IANA timezone identifiers without adding external dependencies. |

---

## 3. Existing Stage 3 Usage Data Architecture & Native Evidence

### 3.1 Flow from Hardware to Domain
The native Usage Access telemetry pipeline flows across four distinct tiers:

1. **Android OS (`UsageStatsManager`):**  
   Queries `INTERVAL_DAILY` from local wall-clock midnight to current query instant.
2. **Native Kotlin Layer (`UsageStatsReader.kt`, `UsageAggregator.kt`):**  
   - Aggregates intervals by package name (`mergedMap`).
   - **Zero-Usage Apps Stripped:** Line 40 of `UsageAggregator.kt` filters out zero-usage apps:
     ```kotlin
     val nonZeroApps = mergedMap.values.filter { it.totalForegroundMillis > 0L }
     ```
     *Finding:* The native Android bridge **never transmits applications that were not used today**. An installed app with zero screen time is omitted from the payload rather than transmitted with `totalForegroundMillis: 0`.
   - **Total Duration Is Native Sum:** Line 43 of `UsageAggregator.kt` calculates:
     ```kotlin
     val totalDuration = nonZeroApps.sumOf { it.totalForegroundMillis }
     ```
   - **Native Freshness Classification:** In `UsageAggregator.kt` (lines 46–56):
     ```kotlin
     val freshness = when {
         nonZeroApps.isEmpty() -> UsageContract.FRESHNESS_EMPTY
         else -> {
             val mostRecent = nonZeroApps.maxOf { it.lastTimeUsedMillis }
             if (mostRecent >= (endTimeMillis - RECENT_THRESHOLD_MILLIS)) {
                 UsageContract.FRESHNESS_RECENT
             } else {
                 UsageContract.FRESHNESS_DELAYED
             }
         }
     }
     ```
     *Critical Finding on Native Information Loss:* When `nonZeroApps.isEmpty()`, Kotlin returns `FRESHNESS_EMPTY`. Because there are no app records, Kotlin has no `lastTimeUsedMillis` to compare against `(endTimeMillis - RECENT_THRESHOLD_MILLIS)`. Android's `UsageStatsManager` does not provide an independent timestamp for the last OS buffer flush. Consequently, the native envelope **lacks evidence to determine whether the empty activity reflects recent telemetry or delayed telemetry**.
3. **Flutter Native Wrapper (`UsageChannel`, `UsageChannelParser`, `UsageEnvelopeModels`):**  
   `UsageChannelParser.dart` parses `dataFreshness` into `UsageDataFreshness.empty`, `recent`, or `delayed`. It performs no timestamp synthesis or inference.
4. **Child App Domain (`ChildUsageRepository`, `ChildUsageController`):**  
   Manages transient `Rxn<UsageDailyResult>`, evaluates `hasData: apps.isNotEmpty`, `isEmpty: status == ChildUsageStatus.empty`, and clears memory on dispose/errors.

### 3.2 Native Completeness Limitation (Decision 2.16)
**Critical Finding:** `UsageDailyResult` in `usage_envelope_models.dart` contains **no boolean or metadata indicating whether the query was complete**.  
The native bridge simply returns the non-zero apps reported by Android's `UsageStatsManager`. Android itself does not indicate if system throttling or batching truncated the app list.  
**Resolution:** The pure-Dart `PolicyUsageSnapshot` must accept a `completeness` parameter (`PolicyUsageCompleteness`) supplied by the trusted caller (e.g. repository or background sync service). If the caller cannot confirm complete population coverage, it must pass `completeness: PolicyUsageCompleteness.incomplete` or `PolicyUsageCompleteness.unknown`, preventing unmeasured apps from falsely evaluating as zero.

---

## 4. Final `PolicyUsageSnapshot` Data Contract

### 4.1 Enums and Data Models

```dart
/// Completeness status of the supplied usage telemetry dataset.
enum PolicyUsageCompleteness {
  /// Confirmed complete snapshot across all active packages for the observation interval.
  complete,
  /// Partial or truncated snapshot (e.g. capped top N packages or partial batch).
  incomplete,
  /// Completeness cannot be verified or evidence is absent.
  unknown,
  /// Telemetry unavailable (permission denied, query failure, unsupported platform).
  unavailable,
}

/// Telemetry pipeline recency status reflecting native OS query freshness.
enum PolicyUsageFreshness {
  /// Telemetry reflects recent usage data up to the native threshold (e.g. within 15 minutes).
  recent,
  /// Telemetry is delayed by native OS batching or throttling (>15 minutes lag).
  delayed,
  /// Telemetry freshness is unknown (e.g. native empty activity without timestamp evidence).
  unknown,
  /// Telemetry was not returned or could not be queried (permission denied, query error).
  unavailable;

  /// Safe conversion from Stage 3 native envelope freshness tokens.
  /// Does NOT fabricate recent or delayed status when native reports empty.
  static PolicyUsageFreshness fromNativeFreshness(String? raw) => switch (raw) {
    'recent' => PolicyUsageFreshness.recent,
    'delayed' => PolicyUsageFreshness.delayed,
    'empty' => PolicyUsageFreshness.unknown, // Information loss preserved safely
    _ => PolicyUsageFreshness.unavailable,
  };
}

/// Immutable, pure-Dart transient snapshot of application foreground usage.
@immutable
final class PolicyUsageSnapshot {
  /// Primary generative constructor enforcing production-safe runtime validation.
  PolicyUsageSnapshot({
    required this.snapshotDate,
    required this.snapshotTime,
    required this.startInterval,
    required this.endInterval,
    required this.totalForegroundMillis,
    required Map<String, int> appForegroundMillis,
    required this.completeness,
    required this.freshness,
    this.isPermissionGranted = true,
  }) : appForegroundMillis = Map.unmodifiable(appForegroundMillis) {
    // Runtime validation via ArgumentError (production safe; not assert)
    if (totalForegroundMillis != null && totalForegroundMillis! < 0) {
      throw ArgumentError.value(
        totalForegroundMillis,
        'totalForegroundMillis',
        'Total daily foreground millis cannot be negative.',
      );
    }
    for (final entry in this.appForegroundMillis.entries) {
      if (entry.key.trim().isEmpty) {
        throw ArgumentError.value(
          entry.key,
          'appForegroundMillis',
          'Package identifier key cannot be empty or whitespace.',
        );
      }
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          'appForegroundMillis[${entry.key}]',
          'Per-package foreground millis cannot be negative.',
        );
      }
    }
    if (endInterval.isBefore(startInterval)) {
      throw ArgumentError.value(
        endInterval,
        'endInterval',
        'End interval cannot precede start interval.',
      );
    }
  }

  /// Factory creating an explicit unavailable snapshot (permission denied or query failed).
  /// Cannot bypass constructor validation.
  factory PolicyUsageSnapshot.unavailable({
    required DateTime snapshotDate,
    required DateTime snapshotTime,
    required DateTime startInterval,
    required DateTime endInterval,
    bool isPermissionGranted = false,
  }) => PolicyUsageSnapshot(
    snapshotDate: snapshotDate,
    snapshotTime: snapshotTime,
    startInterval: startInterval,
    endInterval: endInterval,
    totalForegroundMillis: null,
    appForegroundMillis: const <String, int>{},
    completeness: PolicyUsageCompleteness.unavailable,
    freshness: PolicyUsageFreshness.unavailable,
    isPermissionGranted: isPermissionGranted,
  );

  /// Factory creating a confirmed-complete empty snapshot (e.g. first boot of the day).
  /// Cannot bypass constructor validation.
  factory PolicyUsageSnapshot.empty({
    required DateTime snapshotDate,
    required DateTime snapshotTime,
    required DateTime startInterval,
    required DateTime endInterval,
    PolicyUsageFreshness freshness = PolicyUsageFreshness.unknown,
  }) => PolicyUsageSnapshot(
    snapshotDate: snapshotDate,
    snapshotTime: snapshotTime,
    startInterval: startInterval,
    endInterval: endInterval,
    totalForegroundMillis: 0,
    appForegroundMillis: const <String, int>{},
    completeness: PolicyUsageCompleteness.complete,
    freshness: freshness,
    isPermissionGranted: true,
  );

  /// Device-local calendar date of the observation interval.
  final DateTime snapshotDate;

  /// Wall-clock instant when this snapshot was queried/assembled.
  final DateTime snapshotTime;

  /// Local wall-clock start of the observation interval (local midnight).
  final DateTime startInterval;

  /// Local wall-clock end of the observation interval.
  final DateTime endInterval;

  /// Aggregate foreground screen time in milliseconds across the device,
  /// or null if telemetry is unavailable.
  final int? totalForegroundMillis;

  /// Immutable map of package identifier to foreground milliseconds.
  final Map<String, int> appForegroundMillis;

  /// Completeness indicator (Decision 2.16).
  final PolicyUsageCompleteness completeness;

  /// Native telemetry freshness indicator (Decision 2.17).
  final PolicyUsageFreshness freshness;

  /// Whether USAGE_STATS permission was granted at capture time.
  final bool isPermissionGranted;

  /// Total foreground duration in whole minutes, or null if unmeasured.
  int? get totalMinutes =>
      totalForegroundMillis != null ? totalForegroundMillis! ~/ 60000 : null;

  /// Whether the snapshot records zero foreground activity today.
  /// Derived safely from usage metrics; independent of telemetry freshness.
  bool get isEmptyActivity =>
      totalForegroundMillis == 0 &&
      (appForegroundMillis.isEmpty ||
          appForegroundMillis.values.every((m) => m == 0));

  /// Whether the snapshot has any recorded foreground activity today.
  bool get hasRecordedActivity =>
      (totalForegroundMillis != null && totalForegroundMillis! > 0) ||
      appForegroundMillis.values.any((m) => m > 0);

  /// Resolves foreground minutes for a package under Decision 2.16:
  /// - Returns observed minutes if present in [appForegroundMillis].
  /// - Returns 0 ONLY if completeness == complete AND isPermissionGranted == true AND freshness != unavailable.
  /// - Returns null (unknown/unmeasured) if absent from incomplete, unknown, or unavailable telemetry.
  int? appMinutes(String packageName) {
    if (appForegroundMillis.containsKey(packageName)) {
      return (appForegroundMillis[packageName] ?? 0) ~/ 60000;
    }
    if (completeness == PolicyUsageCompleteness.complete &&
        isPermissionGranted &&
        freshness != PolicyUsageFreshness.unavailable) {
      return 0;
    }
    return null;
  }
}
```

---

## 5. Missing-versus-Zero Telemetry Semantics (Decision 2.16 & Freshness Reconciliation)

The snapshot enforces the strict distinction mandated by the owner:

### 5.1 Exact Missing-App Usage Resolution Condition
A missing package's usage may resolve to `0` only when ALL of these conditions are true:
```dart
completeness == PolicyUsageCompleteness.complete &&
    isPermissionGranted &&
    freshness != PolicyUsageFreshness.unavailable
```
Otherwise, missing package usage must resolve to `null`.

```
                                [Query appMinutes(pkg)]
                                           │
                        ┌──────────────────┴──────────────────┐
                        │                                     │
                [Package in Map?]                     [Package NOT in Map]
                        │                                     │
                YES: Return value ~/ 60000                     │
                                              ┌────────────────┴────────────────┐
                                              │                                 │
                         [completeness == complete && permGranted               │
                          && freshness != unavailable]                 [incomplete, unknown, permDenied,
                                              │                         or freshness == unavailable]
                                     Return 0 (Confirmed Unused)                │
                                                                       Return NULL (Unknown/Unmeasured)
```

### 5.2 Authoritative Truth Table
| Completeness | Permission | Freshness | Missing package usage |
|---|---|---|---|
| `complete` | `granted` | `recent` | `0` (Confirmed Unused) |
| `complete` | `granted` | `delayed` | `0` (Confirmed Unused) |
| `complete` | `granted` | `unknown` | `0` (Confirmed Unused) |
| `complete` | `granted` | `unavailable` | `null` (Unknown/Unmeasured) |
| `complete` | `denied` | `any` | `null` (Unknown/Unmeasured) |
| `unknown`/`incomplete` | `any` | `any` | `null` (Unknown/Unmeasured) |

### 5.3 Critical Distinctions and Invariant Rules:
1. **`unknown` is NOT `unavailable`:** `unknown` reflects native information loss (e.g. empty app list without native timestamps), whereas `unavailable` indicates permission denial, bridge failure, or missing platform service.
2. **`unknown` Does Not Establish Completeness:** `unknown` freshness does not independently prove dataset completeness. It resolves to `0` only when explicit completeness evidence confirms `complete` AND permission is granted.
3. **`unavailable` Always Prevents Zero Inference:** When `freshness == PolicyUsageFreshness.unavailable`, missing packages evaluate to `null` even if completeness was marked complete.
4. **Never Infer Zero on Incomplete or Unverified Data:** If `completeness != complete`, an absent app returns `null`. The policy evaluator will report `usageUnavailable` rather than falsely granting access or declaring quota compliance.
5. **Permission Denied Safety:** When `isPermissionGranted == false`, `appMinutes(pkg)` unconditionally returns `null` for unmapped packages. Quota evaluation sets `dailyQuota.isUnavailable: true`, guaranteeing apps are never locked due to revoked permissions.
6. **No False Inferences:** Permission granted, query success, or an empty map alone must never establish completeness.
7. **Independence of Capture Time:** Snapshot capture time must never promote telemetry freshness (Decision 2.17).

---

## 6. Freshness vs Activity Semantics (Issue A & Decision 2.17)

### 6.1 Telemetry Freshness vs Activity State
- **Telemetry Freshness (`freshness`):**  
  Measures the health and latency of the OS telemetry pipeline:
  - `recent`: Android OS updated usage stats within the last 15 minutes.
  - `delayed`: Android OS batching or power-saving throttling has delayed data updates beyond 15 minutes.
  - `unknown`: Native telemetry exhibits information loss (e.g. empty app list without timestamps).
  - `unavailable`: Permission denied, system service unreachable, or platform unsupported.
- **Activity State (`isEmptyActivity` / `hasRecordedActivity`):**  
  Measures whether the child used applications today:
  - Derived directly from `totalForegroundMillis` and `appForegroundMillis`.
  - Independent of telemetry freshness.

### 6.2 Safe Native Empty Freshness Mapping
When Stage 3 native returns `FRESHNESS_EMPTY`:
- **Problem:** Native Kotlin computes freshness via `nonZeroApps.maxOf { it.lastTimeUsedMillis }`. With zero apps, there is no timestamp evidence to verify whether Android's OS buffers are flushed or delayed.
- **Resolution:** Native `empty` maps to `PolicyUsageFreshness.unknown`.
- **Integrity Rule:** Neither `recent` nor `delayed` is fabricated.
- **Activity Derivation:** `isEmptyActivity` evaluates to `true` directly from `totalForegroundMillis == 0 && appForegroundMillis.isEmpty`.

---

## 7. Date, Time, and Timezone Contract (Decision 2.18)

### 7.1 Child Device-Local Date Authority
1. **Local Calendar Day is Authoritative:**  
   Daily screen time quotas reset at child device-local midnight (`00:00:00.000`).
2. **Full Calendar Date Comparison:**  
   When checking whether a snapshot matches the evaluation context, the system normalizes both timestamps to local representation and compares year, month, and day:
   ```dart
   bool isSameLocalDate(DateTime a, DateTime b) {
     final localA = a.toLocal();
     final localB = b.toLocal();
     return localA.year == localB.year &&
         localA.month == localB.month &&
         localA.day == localB.day;
   }
   ```
   Comparing `.day` alone is strictly prohibited because identical day numbers recur across different months.
3. **Midnight Rollover:**  
   If `!isSameLocalDate(context.evaluationTime, snapshot.snapshotDate)`, the snapshot belongs to a previous day. The evaluator detects the date rollover, flags telemetry as mismatched/unavailable, and requests a fresh snapshot for the new day.

### 7.2 Dart `DateTime` Guarantees and Limitations
- **Guarantees Supported:**
  1. Full year, month, day matching prevents day-of-month false positives.
  2. Device-local midnight rollover resets daily allowances cleanly.
  3. Strict zero-dependency implementation using only `dart:core`.
- **Documented Limitations:**
  1. *No Named IANA Timezones:* Dart standard library `DateTime` only knows UTC (`isUtc: true`) or host local time (`isUtc: false`). It does not store or validate named timezone identifiers (e.g. `'America/Chicago'`).
  2. *Timezone Changes Between Capture and Evaluation:* If the child device travels across timezones between snapshot capture and policy evaluation, the host OS adjusts its local UTC offset. `toLocal()` reflects the new local time. If this shift causes the local calendar day to differ, `isSameLocalDate` detects the day mismatch and rejects the previous day's snapshot as stale.
  3. *Daylight Saving Transitions:* On 23-hour or 25-hour transition days, the calendar day is still treated as one unit of daily quota.
  4. *Device Clock Tampering:* Handled at the OS layer via Android `SystemClock.elapsedRealtime()`, outside pure-Dart `haven_models`.

---

## 8. Data Validation & Total-versus-App-Sum Invariants

- **Rule 1 (Non-Negative Total via ArgumentError):**  
  `totalForegroundMillis != null && totalForegroundMillis! < 0` throws `ArgumentError.value(totalForegroundMillis, 'totalForegroundMillis', 'Total daily foreground millis cannot be negative.')`.
- **Rule 2 (Non-Negative App Millis via ArgumentError):**  
  Any package entry with value $< 0$ throws `ArgumentError.value(entry.value, 'appForegroundMillis[${entry.key}]', 'Per-package foreground millis cannot be negative.')`.
- **Rule 3 (Valid Package Identifiers via ArgumentError):**  
  Any package key with `entry.key.trim().isEmpty` throws `ArgumentError.value(entry.key, 'appForegroundMillis', 'Package identifier key cannot be empty or whitespace.')`.
- **Rule 4 (Interval Ordering via ArgumentError):**  
  `endInterval.isBefore(startInterval)` throws `ArgumentError.value(endInterval, 'endInterval', 'End interval cannot precede start interval.')`.
- **Rule 5 (Every Construction Path Validated):**  
  Generative constructors and factories (`empty`, `unavailable`) all enforce validation. No public pathway bypasses checks.
- **Rule 6 (Zero Values Preserved):**  
  `0` total milliseconds and `0` per-package milliseconds are completely valid and preserved.
- **Rule 7 (No Silent Clamping):**  
  Invalid values are never clamped using `math.max(0, val)` or filtered out silently.
- **Rule 8 (Total-versus-App-Sum Discrepancy Accepted):**  
  Discrepancies where total foreground millis does not equal the sum of app foreground millis are accepted without throwing. Total is authoritative for daily quota; per-app records are authoritative for app-level rules.

---

## 9. Relationship with `PolicyEvaluationContext` (Decision 2.14)

- `PolicyEvaluationContext` (implemented in Sub-step 2.1) remains **100% untouched**.
- The evaluation context represents static policy rules and quota overrides.
- `PolicyUsageSnapshot` represents transient hardware telemetry.
- In Sub-step 2.4, the evaluator engine accepts both as independent parameters:
  ```dart
  PolicyEvaluationResult evaluate({
    required PolicyEvaluationContext context,
    PolicyUsageSnapshot? usage,
  });
  ```

---

## 10. Execution Plan Synchronization (Decision 2.15)

### 10.1 Plan Reconciliation Complete
- In `STAGE_4_STEP_2_EXECUTION_PLAN.md`, Section 7, Section 10, and Section 12 have been updated to **v1.5.0-SUBSTEP-SYNCHRONIZED**.
- **Scope Reallocation:**
  - **Sub-step 2.2 Scope:** Implements *only* `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and conversion helpers.
  - **Sub-step 2.4 Scope:** Implements `PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`, and evaluation logic together in `policy_evaluation_models.dart` and `policy_evaluator.dart`.
- The execution plan now perfectly mirrors Owner Decision 2.15 with zero discrepancies.

---

## 11. Proposed Source and Test Files for Sub-Step 2.2

| Target File Path | Estimated Lines | Purpose | Compliance |
|:---|:---:|:---|:---:|
| `packages/haven_models/lib/src/policy_evaluator/policy_usage_snapshot.dart` | ~125 | Pure-Dart transient usage snapshot, completeness & freshness enums, ArgumentError validation, and helpers. | $\le 200$ lines |
| `packages/haven_models/test/policy_evaluator/policy_usage_snapshot_test.dart` | ~175 | Focused unit tests for snapshot construction, ArgumentError rejection, zero-inference, and immutability. | $\le 200$ lines |
| `packages/haven_models/lib/haven_models.dart` | ~32 | Export `policy_usage_snapshot.dart`. | $\le 200$ lines |

---

## 12. Focused Test Specification (16 Tests)

When authorized for implementation, `policy_usage_snapshot_test.dart` will execute:

### Category A: Pure-Dart Model Invariant & Validation Tests (Direct Unit Tests)
1. **Test 1 (Standard Complete Snapshot):** Verifies construction with valid total and app map; asserts `totalMinutes` and `appMinutes(pkg)` conversions.
2. **Test 2 (Negative Total Millis Throws ArgumentError):** Precondition check throws `ArgumentError` when `totalForegroundMillis < 0` (production-safe, not assert).
3. **Test 3 (Negative App Millis Throws ArgumentError):** Precondition check throws `ArgumentError` when any package entry has milliseconds $< 0$.
4. **Test 4 (Empty or Whitespace Package Identifier Throws ArgumentError):** Precondition check throws `ArgumentError` when a package key is `""` or `"   "`.
5. **Test 5 (Zero Usage Values Preserved):** Verifies `totalForegroundMillis: 0` and package value `0` are valid and preserved without throwing or clamping.
6. **Test 6 (Factory Validation Enforcement):** Verifies `PolicyUsageSnapshot.empty` and `unavailable` enforce interval ordering and throw `ArgumentError` if end precedes start.
7. **Test 7 (Map Immutability):** Verifies `appForegroundMillis` is wrapped in `Map.unmodifiable()` and throws `UnsupportedError` on mutation attempt.
8. **Test 8 (Total vs App Sum Discrepancy Accepted):** Verifies snapshot accepts `totalForegroundMillis` differing from the sum of apps without throwing.
9. **Test 9 (Pure Dart Isolation):** Verifies zero Flutter framework or native platform imports.

### Category B: Decision 2.16 & 2.17 Semantic Tests (Simulated Caller Evidence)
10. **Test 10 (Decision 2.16 Missing App in Verified Complete Data):** Missing package resolves to `0` minutes when `completeness == complete` and `isPermissionGranted == true`.
11. **Test 11 (Decision 2.16 Missing App in Incomplete Data):** Missing package resolves to `null` when `completeness == incomplete`.
12. **Test 12 (Decision 2.16 Missing App in Unknown Data):** Missing package resolves to `null` when `completeness == unknown`.
13. **Test 13 (Decision 2.16 Permission Denied Safety):** Missing package resolves to `null` when `isPermissionGranted == false` even if completeness is marked complete.
14. **Test 14 (Issue A Empty Freshness Mapping & Empty Activity):** Verifies native `empty` maps safely to `PolicyUsageFreshness.unknown`, while `isEmptyActivity == true`.
15. **Test 15 (Decision 2.17 Capture Time vs Native Freshness):** Snapshot captured at `DateTime.now()` retains `freshness: PolicyUsageFreshness.delayed` without conversion.
16. **Test 16 (Decision 2.18 Full Date Rollover):** Verifies date comparison helper evaluates full year, month, and day; rejects previous-day snapshot.

---

## 13. Privacy and Transient-Memory Compliance

The proposed `PolicyUsageSnapshot` strictly honors the Stage 3 privacy invariant:
- **In-Memory Only:** Transient value object instantiated only during policy evaluation turns.
- **Zero Local Persistence:** Never written to SQLite, SharedPreferences, or Postgres.
- **Zero Network Egress:** Never serialized to REST APIs, Supabase, or Firebase.
- **Zero Background Polling:** Relies strictly on caller-injected telemetry.
- **Pure Data Contract:** Introduces no native permissions, hooks, or accessibility monitoring.

---

## 14. Remaining Owner Decisions & Risks

- **Owner Decisions Required:** **None.** Decisions 2.14 through 2.18, Issue A (empty freshness mapping), and Issue B (execution plan synchronization) are fully resolved.
- **Identified Risks:** **Zero.** Scope is strictly isolated to pure-Dart telemetry contracts in `packages/haven_models`.

---

## 15. Strict Owner Authorization Gate

> [!CAUTION]
> **SUB-STEP 2.2 IMPLEMENTATION IS NOT AUTHORIZED.**  
> This document represents a completed read-only pre-implementation specification. No source code was modified, no tests were written, no models were altered, and no Git mutations were performed.  
> **Explicit owner implementation authorization is required before beginning Sub-step 2.2.**

---

## 16. FINAL-TECHNICAL-CLARIFICATION — VALIDATION, FRESHNESS AND TIMEZONE

### 16.1 Issue A — Native Empty Freshness Mapping & Information Loss
- **Root Cause in Stage 3 Kotlin:** In `UsageAggregator.kt`, freshness is calculated strictly from `nonZeroApps.maxOf { it.lastTimeUsedMillis }`. If `nonZeroApps.isEmpty()`, Kotlin returns `FRESHNESS_EMPTY`. Android OS does not expose a timestamp for when UsageStatsManager was last flushed.
- **Information Loss:** The native bridge cannot prove whether the absence of events was confirmed within the last 15 minutes, or whether the device was in deep sleep / battery saver with unflushed events.
- **Safe Mapping:** Native `empty` maps to `PolicyUsageFreshness.unknown`. No attempt is made to fabricate `recent` or `delayed` status. Activity status is derived independently as `isEmptyActivity: true`.

### 16.2 Issue B — Execution Plan Synchronization
- **Scope Reconciled:** `STAGE_4_STEP_2_EXECUTION_PLAN.md` updated to `v1.5.0-SUBSTEP-SYNCHRONIZED`.
- **Sub-step 2.2:** `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and helpers (~125 lines).
- **Sub-step 2.4:** `PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`, `PolicyOverallState`, `AppPolicyStatus`, and evaluator logic (~150 lines + ~180 lines).

### 16.3 Timezone & Local Date Authority
- **Local Authority:** Child device wall-clock is authoritative. Quota resets at device-local midnight.
- **Timezone Drift:** If device timezone changes between capture and evaluation, `isSameLocalDate` detects any calendar day shift and rejects stale previous-day snapshots.
- **Zero Dependencies:** Pure Dart standard library (`dart:core`) without external timezone packages.

### 16.4 Missing-App Usage Resolution with Unknown Freshness
- **Exact Condition:**
  ```dart
  completeness == PolicyUsageCompleteness.complete &&
      isPermissionGranted &&
      freshness != PolicyUsageFreshness.unavailable
  ```
- **Semantics:** When explicit caller evidence confirms `completeness == complete` and `isPermissionGranted == true`, missing packages resolve to `0` minutes even if `freshness == PolicyUsageFreshness.unknown`.
- **Safety Boundary:** `unknown` freshness never independently proves completeness. It is accepted only because explicit evidence has established `completeness == complete`. If `freshness == PolicyUsageFreshness.unavailable`, missing packages resolve to `null` under all circumstances.
