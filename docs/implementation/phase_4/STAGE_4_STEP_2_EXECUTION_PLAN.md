# HAVEN STAGE 4 — STEP 2 RECONCILED EXECUTION PLAN
## Pure-Dart Deterministic Policy Evaluation Engine

**Document Version:** 1.8.0-SUBSTEP-2-4-OWNER-APPROVED  
**Date:** November 18, 2026  
**Repository:** `D:\control`  
**Target Milestone:** Stage 4 — Step 2: Pure-Dart Deterministic Policy Evaluation Engine  
**Status:** FULLY RECONCILED EXECUTION PLAN — ALL DECISIONS 2.1–2.30 APPROVED — AWAITING SUB-STEP 2.4 AUTHORIZATION  
**Author:** Antigravity Engineering  
**Reference Documents:**
- `docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_4_PREIMPLEMENTATION_AUDIT.md` (v1.1.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_3_PREIMPLEMENTATION_AUDIT.md` (v1.1.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_2_PREIMPLEMENTATION_AUDIT.md` (v1.3.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_SUBSTEP_2_1_PREIMPLEMENTATION_AUDIT.md` (v1.3.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_PLAN_VALIDATION_AUDIT.md` (v1.0.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_FINAL_CLARIFICATION_AUDIT.md` (v1.0.0)
- `docs/implementation/phase_4/STAGE_4_STEP_2_READINESS_AUDIT.md` (v1.0.0)
- `docs/implementation/phase_4/STAGE_4_STEP_1_IMPLEMENTATION_REPORT.md` (v1.0.0)
- `docs/implementation/phase_4/STAGE_4_OWNER_DECISIONS.md`

---

## 1. Executive Summary & Objective

This document defines the authoritative, implementation-ready execution plan for **Stage 4 Step 2: Pure-Dart Deterministic Policy Evaluation Engine**.

### 1.1 Core Objective
Implement a pure-Dart, deterministic, side-effect-free policy evaluation engine in `packages/haven_models/lib/src/policy_evaluator/`. The engine calculates real-time, multi-dimensional policy compliance from an injected policy configuration, transient usage metrics, and an explicit evaluation timestamp without invoking platform APIs, reading device clocks, or performing native enforcement.

### 1.2 Approved Architectural Boundaries
1. **Pure Dart:** Strictly zero Flutter (`dart:ui`), zero GetX, zero Android/MethodChannel, and zero database dependencies.
2. **Informational Evaluation Only (Decision 4.1):** The engine calculates and reports policy status; it does **NOT** enforce native Android app blocking, Device Owner MDM restrictions, or accessibility-based interruptions.
3. **No Direct Clock Reads:** The engine must never invoke `DateTime.now()`. All temporal context is injected by the caller via `DateTime evaluationTime`.
4. **Mandatory Non-Enforcement Disclosure (Decision 4.4):** Every evaluation result carries an explicit declaration that evaluation is local and informational, without active app blocking.

---

## 2. Authoritative Register of Owner Decisions (2.1–2.30)

All thirty decisions below are explicitly confirmed and approved by the owner and govern every contract, algorithm, and test in this plan:

| # | Topic | Approved Decision | Core Architectural Contract |
|:---:|:---|:---:|:---|
| **2.1** | **Parent Whitelist vs Global Quota** | **Option A** | Applications in `PolicyConfig.allowedApps` remain accessible after global daily quota exhaustion. Emergency defaults also bypass global quota. Quota exhaustion is still reported independently. Whitelist does *not* bypass parent blocklist, active schedule restrictions, or per-app limits. |
| **2.2** | **Emergency Application Defaults** | **Option A** | Evaluator uses a narrowly scoped immutable set of **five** verified emergency/telephony package identifiers (`com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`). `com.android.server.telecom` is excluded as an internal framework daemon. No configurable model field in Step 2; no Android `PackageManager` queries. Unknown packages are not exempt. |
| **2.3** | **Global Daily Limit Semantics** | **Option A** | `0` = zero minutes allowed (immediately reached/exceeded if usage $>0$). `null` = unlimited (quota never reached). Positive integer = configured daily quota in minutes. |
| **2.4** | **Parent Blocklist vs Parent Whitelist** | **Option A** | `PolicyConfig.blockedApps` takes absolute precedence over `PolicyConfig.allowedApps`. An application present in both is blocked by parent (`AppPolicyStatus.blockedByParent`). |
| **2.5** | **Parent Whitelist vs Per-App Limit** | **Option A** | Explicit entries in `PolicyConfig.appLimits` take precedence over `PolicyConfig.allowedApps`. An allowed app with an explicit per-app limit is restricted once that per-app limit is reached. |
| **2.6** | **Overlapping Schedules** | **Option A** | Simultaneously active restrictive schedules use **restrictive intersection** ($\text{Allowed} = \bigcap s.\text{allowedApps}$). An application must satisfy all applicable schedule whitelists. Empty `allowedApps` represents **zero exceptions** (all non-emergency apps restricted during that schedule). |
| **2.7** | **Canonical Nullable Daily Limit Schema** | **Option A** | Future migration to `PolicyConfig.dailyScreenTimeMinutes: int?` is approved in principle, but deferred according to Decision 2.9 to avoid breaking parent UI compilation during Step 2. |
| **2.8** | **Parent Blocklist vs Schedule Whitelist** | **Option A** | Explicit parent `PolicyConfig.blockedApps` is a **hard veto** over schedule-specific `allowedApps`. An application blocked by parent remains blocked during School, Bedtime, or Custom schedules. A schedule whitelist never overrides the explicit parent blocklist. |
| **2.9** | **Two-Phase Nullable Migration** | **Option A** | In Step 2, keep `PolicyConfig.dailyScreenTimeMinutes` as non-nullable `int`. Do not modify parent UI, controller, or persistence. The evaluator accepts an optional tri-state `int? dailyLimitMinutesOverride` in its input context. Defer persistent model migration to Step 7/8. |
| **2.10** | **Parent Blocklist vs Emergency Defaults** | **Option A** | Explicit parent `PolicyConfig.blockedApps` takes precedence even over the emergency default package set. An emergency package is **not** exempt if its exact package identifier is explicitly present in the parent blocklist. Emergency exemption applies strictly *after* checking the parent blocklist. |
| **2.11** | **Schedule Whitelist vs Bedtime** | **Option A** | Restrictive intersection wins. A schedule-specific whitelist (e.g. School Hours or Custom Focus) cannot override an active Bedtime/downtime restriction. If an active Bedtime schedule has an empty whitelist, its intersection with other active schedule whitelists remains empty ($\emptyset$), resulting in a complete non-emergency lockout. |
| **2.12** | **Sub-Step 2.1 Scope** | **Option A** | Pure-Dart evaluation context and tri-state daily quota override input contract (`PolicyEvaluationContext`). Canonical `PolicyConfig` remains untouched. |
| **2.13** | **Sub-Step 2.2 Scope** | **Option A** | Pure-Dart transient usage snapshot contracts (`PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`). Output models deferred to Sub-step 2.4. |
| **2.14** | **Context and Snapshot Relationship** | **Option A** | The future evaluator receives two independent parameters: `PolicyEvaluationContext` and `PolicyUsageSnapshot` (`evaluate(context, usage)`). Do not embed snapshot inside context. |
| **2.15** | **Evaluator Output Model Scope** | **Option A** | Multi-dimensional evaluation output models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`, `PolicyOverallState`, `AppPolicyStatus`) are implemented in Sub-step 2.4 concurrently with evaluator logic. |
| **2.16** | **Missing-App Usage Resolution** | **Option A** | A missing package's usage resolves to `0` only when `completeness == complete && isPermissionGranted && freshness != unavailable && freshness != unknown`. Otherwise resolves to `null`. |
| **2.17** | **Permission Status Explicitness** | **Option A** | Permission status (`isPermissionGranted`) must be explicitly required in both primary constructor and empty factory of `PolicyUsageSnapshot`. Zero implicit permission defaults. |
| **2.18** | **Child Device-Local Calendar Date** | **Option A** | Date comparison evaluates full year, month, and day against child device-local wall clock. Document Dart `DateTime` timezone limitations without external dependencies. |
| **2.19** | **Half-Open Interval Boundary Standard** | **Option A** | Schedule intervals use `[startTime, endTime)`. Exact start minute is ACTIVE; exact end minute is INACTIVE. When `startTime == endTime`, the interval duration is zero and the schedule is INACTIVE at all times. Applies consistently to normal and overnight schedules. |
| **2.20** | **Malformed Schedule Time Strings** | **Option A** | Parse time strings defensively. Invalid or unparseable time strings must never cause runtime exceptions in the evaluator; schedules with invalid start or end times evaluate as fail-safe INACTIVE. Never fabricate valid times from malformed inputs. |
| **2.21** | **Evaluation Result Structure** | **Option A** | Proposed immutable `ScheduleEvaluationResult` containing `isAnyScheduleActive`, `isBedtimeActive`, `isSchoolActive`, `activeSchedules`, `allowedAppExceptions`, and `isAppAllowed(packageName)`. Collections must be immutable (`List.unmodifiable`, `Set.unmodifiable`). |
| **2.22** | **No Active Schedules Semantics** | **Option A** | When no schedules are active, schedule restrictions do not apply (`isAnyScheduleActive == false`). `activeSchedules` is empty, and `allowedAppExceptions` is empty. An empty exception set must NOT independently be interpreted as lockdown when no schedule is active. Callers must check `isAnyScheduleActive` before applying schedule restrictions. |
| **2.23** | **Weekday Validation** | **Option A** | Valid weekday values are ISO 8601 integers: 1 (Monday) through 7 (Sunday). Empty `days` means the schedule never activates. Any invalid weekday values outside 1–7 cause the schedule to be rejected and evaluated as fail-safe INACTIVE. Do not silently ignore invalid entries and partially activate the schedule. |
| **2.24** | **Device-Local Time and DST** | **Option A** | Schedule matching uses device-local wall-clock time (`evaluationTime.weekday`, `evaluationTime.hour`, `evaluationTime.minute`). During a DST repeated hour, both occurrences match the configured wall-clock time. Zero UTC conversion and zero external timezone dependencies. Document Dart `DateTime` timezone limitations. |
| **2.25** | **Minute Precision** | **Option A** | Schedules express `HH:mm`. Evaluation compares hour and minute only; seconds and milliseconds are ignored. Derive current minute-of-day from local hour and minute. Half-open boundaries apply at minute precision (e.g. 08:00:59 is minute 480 and active; 15:00:00 is minute 900 and inactive for an 08:00–15:00 schedule). |
| **2.26** | **Target Package Scope** | **Option A (Approved)** | When `targetPackages` is omitted, the evaluator derives the target package set dynamically as the union of: `config.blockedApps`, `config.allowedApps`, `config.appLimits.keys`, active schedule `allowedApps` exceptions, and `usage.appForegroundMillis.keys` using set semantics to avoid duplicates. Explicitly supplied `targetPackages` acts authoritatively for the evaluated app set. |
| **2.27** | **Overall State Priority** | **Option A (Approved)** | Active schedule state receives visual priority over global quota state when determining `PolicyEvaluationResult.overallState` and `primaryReason`. When schedule and quota conditions coexist, overall state and primary reason reflect the active schedule, while global quota details remain in `dailyQuota` and quota status is retained in `secondaryReasons`. App-specific restrictions do not redefine device-level overall state. |
| **2.28** | **Emergency Per-App Limit Exemption** | **Option A (Approved)** | The five immutable emergency packages (`com.android.phone`, `com.google.android.dialer`, `com.samsung.android.dialer`, `com.android.emergency`, `com.google.android.apps.safetyhub`) are exempt from active schedules, global daily quota, and explicit per-app limits in `PolicyConfig.appLimits`. Parent `blockedApps` remains the highest-priority hard veto (`blockedByParent`). Unknown packages do not receive exemptions. Zero configurable emergency package injection. |
| **2.29** | **Usage Snapshot Date Mismatch** | **Option A (Approved)** | When `PolicyUsageSnapshot.isSameLocalDate(context.evaluationTime, usage.snapshotDate)` is false, both global and per-app usage become unavailable fail-safe (`dailyQuota.isUnavailable = true`, `dailyQuota.usedMinutes = null`, `appMinutes` resolves to `null`). Prevents stale previous-day usage from falsely blocking the current day. Unavailable usage is never converted to zero. Telemetry completeness, permission, and freshness disclosures are preserved without adding schema fields. |
| **2.30** | **Unknown Usage and Overall State** | **Option A (Approved)** | Overall state reflects actual policy outcomes; unavailable telemetry is disclosed separately via `dailyQuota.isUnavailable`, `usageCompleteness`, and `isDelayed`. Unknown usage alone must not automatically force `overallState = usageUnavailable`. If no quota or schedule is violated, overall state remains allowed. |

---

## 3. Corrected Authoritative Precedence Contract

The evaluation engine resolves overlapping and conflicting rules according to this strict, corrected 7-level priority hierarchy:

```
[Level 1: Explicit Parent Blocklist] ──────── (Absolute Hard Veto: Blocked by Parent;
                 │                             Overrides emergency defaults, whitelists & quotas)
                 │ (if not in blockedApps)
[Level 2: Emergency & Telephony Defaults] ─── (Exempt from active schedules, daily quota & per-app limits;
                 │                             Applies ONLY after parent blocklist check)
                 │ (if not an emergency package)
[Level 3: Active Restrictive Schedules] ───── (Intersection: Allowed iff in ALL active whitelists;
                 │                             Bedtime cannot be overridden by other schedules;
                 │                             Empty whitelist = zero exceptions)
                 │ (if schedule allows or no active schedule)
[Level 4: Explicit Per-App Time Limits] ───── (Blocked: App Limit Reached;
                 │                             Overrides parent whitelist)
                 │ (if app limit not reached)
[Level 5: Global Daily Screen Time Quota] ─── (Blocked: Daily Limit Reached;
                 │                             Bypassed by Parent Whitelist allowedApps)
                 │ (if quota not reached OR app in allowedApps)
[Level 6: Parent Whitelist Exemption] ─────── (Allowed: Bypasses Global Daily Quota only)
                 │
[Level 7: Default Permitted Applications] ─── (Allowed: Normal permitted usage)
```

### 3.1 Precedence Principles & Invariants
1. **Absolute Hard Veto:** Parent `blockedApps` is the single supreme rule across all categories. No emergency exemption, schedule exception, or whitelist rule can unblock an application explicitly listed in `blockedApps` (Decisions 2.4, 2.8, 2.10).
2. **Subordinate Emergency Exemption:** Emergency defaults bypass schedule restrictions, global daily quotas, and explicit per-app limits (`PolicyConfig.appLimits`), but are subordinate to the parent blocklist (Decisions 2.10, 2.28).
3. **Restrictive Schedule Intersection:** Multiple active schedules intersect. A school schedule whitelist cannot puncture or override an active Bedtime schedule lockout (Decisions 2.6, 2.11).
4. **Targeted Whitelist Exemption:** Parent `allowedApps` confers exemption from the global daily quota *only* (Decision 2.1). It provides zero protection against blocklists, bedtime, school hours, or per-app limits.
5. **Schedule Visual Priority (Decision 2.27):** Active schedule state receives visual priority over global daily quota for `overallState` and `primaryReason`. Coexisting quota exhaustion is preserved in `dailyQuota` and retained in `secondaryReasons`.
6. **Device State vs App Status Independence (Decision 2.27):** An individual application's restriction (e.g. per-app limit reached) never redefines device-level `overallState`.

---

## 4. Corrected Conflict Resolution Matrix

The evaluation engine resolves all rule collisions according to this authoritative decision matrix:

| # | Conflict Pair | High Priority Rule | Lower Priority Rule | Approved Outcome | Status & Reason Code | Owner Basis |
|:---:|:---|:---|:---|:---|:---|:---:|
| **C-01** | Parent Blocklist vs Emergency Default | Parent Blocklist | Emergency Default | **Restricted** (Hard Veto) | `AppPolicyStatus.blockedByParent` ("Blocked by parent") | **Approved (Decision 2.10)** |
| **C-02** | Parent Blocklist vs Schedule Whitelist | Parent Blocklist | Schedule Whitelist | **Restricted** (Hard Veto) | `AppPolicyStatus.blockedByParent` ("Blocked by parent") | **Approved (Decision 2.8)** |
| **C-03** | Parent Blocklist vs Parent Whitelist | Parent Blocklist | Parent Whitelist | **Restricted** (Hard Veto) | `AppPolicyStatus.blockedByParent` ("Blocked by parent") | **Approved (Decision 2.4)** |
| **C-04** | Parent Blocklist with Quota Remaining | Parent Blocklist | Available Daily Quota | **Restricted** | `AppPolicyStatus.blockedByParent` ("Blocked by parent") | Derived |
| **C-05** | Parent Blocklist with App Limit Remaining | Parent Blocklist | Available App Limit | **Restricted** | `AppPolicyStatus.blockedByParent` ("Blocked by parent") | Derived |
| **C-06** | Emergency Default vs Bedtime | Emergency Default | Bedtime Schedule | **Allowed** (unless blocklisted) | `AppPolicyStatus.exempt` ("Emergency service") | **Approved (Decision 2.2)** |
| **C-07** | Emergency Default vs School Schedule | Emergency Default | School Schedule | **Allowed** (unless blocklisted) | `AppPolicyStatus.exempt` ("Emergency service") | **Approved (Decision 2.2)** |
| **C-08** | Emergency Default vs Global Quota | Emergency Default | Daily Quota | **Allowed** (unless blocklisted) | `AppPolicyStatus.exempt` ("Emergency service") | **Approved (Decision 2.2)** |
| **C-09** | Emergency Default vs Per-App Limit | Emergency Default | Per-App Limit | **Allowed** (unless blocklisted) | `AppPolicyStatus.exempt` ("Emergency service") | **Approved (Decisions 2.2, 2.28 - Option A)** |
| **C-10** | Schedule Whitelist vs Bedtime | Restrictive Intersection | Schedule Whitelist | **Restricted** (Empty intersection) | `AppPolicyStatus.scheduleRestricted` ("Bedtime active") | **Approved (Decision 2.11)** |
| **C-11** | School Whitelist vs Custom Downtime | Restrictive Intersection | School Whitelist | **Allowed iff in BOTH whitelists** | `AppPolicyStatus.scheduleAllowed` or `scheduleRestricted` | **Approved (Decision 2.6)** |
| **C-12** | Empty Bedtime Whitelist vs Active School Whitelist | Restrictive Intersection | Active Whitelist | **Restricted** ($\emptyset \cap S = \emptyset$) | `AppPolicyStatus.scheduleRestricted` ("Bedtime active") | **Approved (Decision 2.11)** |
| **C-13** | Inactive Schedule vs Active Schedule | Active Schedule | Inactive Schedule | **Inactive schedule excluded** | Evaluates active schedule only | Derived |
| **C-14** | Parent Whitelist vs Per-App Limit | Per-App Limit | Parent Whitelist | **Restricted** | `AppPolicyStatus.appLimitReached` ("App limit reached") | **Approved (Decision 2.5)** |
| **C-15** | Parent Whitelist vs Global Quota | Parent Whitelist | Daily Quota | **Allowed** (Bypasses quota) | `AppPolicyStatus.allowed` ("Parent whitelist exempt") | **Approved (Decision 2.1)** |
| **C-16** | Parent Whitelist vs Bedtime | Bedtime Schedule | Parent Whitelist | **Restricted** (Bedtime wins) | `AppPolicyStatus.scheduleRestricted` ("Bedtime active") | Derived (Decision 2.1) |
| **C-17** | Per-App Limit Exceeded within Daily Quota | Per-App Limit | Available Daily Quota | **Restricted** | `AppPolicyStatus.appLimitReached` ("App limit reached") | Derived |
| **C-18** | Daily Quota Exceeded with Per-App Limit Remaining | Daily Quota | Available Per-App Limit | **Restricted** (non-whitelist) | `AppPolicyStatus.dailyLimitReached` ("Daily limit reached") | Derived |
| **C-19** | Usage Data Unavailable / Permission Denied | Safety Fallback | Quotas | **Allowed** (Not falsely blocked) | `AppPolicyStatus.allowed` (`dailyQuota.isUnavailable: true`) | Derived |
| **C-20** | Delayed Usage Data (> 15 min old) | Freshness Flag | Realtime Evaluation | **Evaluates with Warning** | Evaluated state + `isDelayed: true` | Derived |

---

## 5. Two-Phase Quota Override Contract

### 5.1 Step 2 Tri-State Quota Input Contract
To preserve compatibility with `apps/haven_app`'s non-nullable `ScreenTimeCard.dart` arithmetic and controller signatures, canonical `PolicyConfig.dailyScreenTimeMinutes` remains `final int dailyScreenTimeMinutes;` throughout Step 2.

The evaluator input context defines an explicit tri-state override mechanism:

```dart
final class PolicyEvaluationContext {
  const PolicyEvaluationContext({
    required this.config,
    required this.evaluationTime,
    this.usage,
    this.dailyLimitMinutesOverride,
    this.hasDailyLimitOverride = false,
    this.emergencyPackages = defaultEmergencyPackages,
  });

  final PolicyConfig config;
  final DateTime evaluationTime;
  final PolicyUsageSnapshot? usage;

  /// Optional override for daily screen time limit in minutes.
  /// Must be interpreted strictly via [hasDailyLimitOverride].
  final int? dailyLimitMinutesOverride;

  /// Whether an explicit caller override is active.
  final bool hasDailyLimitOverride;

  final Set<String> emergencyPackages;

  /// Evaluates effective quota under the tri-state contract:
  /// 1. hasDailyLimitOverride == false:
  ///    - Uses config.dailyScreenTimeMinutes (non-nullable fallback).
  /// 2. hasDailyLimitOverride == true && dailyLimitMinutesOverride == null:
  ///    - Explicit unlimited quota (no screen time cap).
  /// 3. hasDailyLimitOverride == true && dailyLimitMinutesOverride == 0:
  ///    - Explicit zero-minute quota (0 minutes allowed).
  /// 4. hasDailyLimitOverride == true && dailyLimitMinutesOverride > 0:
  ///    - Explicit quota of N minutes.
  /// 5. hasDailyLimitOverride == true && dailyLimitMinutesOverride < 0:
  ///    - Throws ArgumentError (invalid input; never clamped or made unlimited).
  int? get effectiveDailyLimit {
    if (!hasDailyLimitOverride) {
      return config.dailyScreenTimeMinutes;
    }
    if (dailyLimitMinutesOverride != null && dailyLimitMinutesOverride! < 0) {
      throw ArgumentError.value(
        dailyLimitMinutesOverride,
        'dailyLimitMinutesOverride',
        'Daily limit override cannot be negative.',
      );
    }
    return dailyLimitMinutesOverride;
  }
}
```

### 5.2 Why Both Fields Are Necessary
In Dart, `null` is a valid semantic value representing "unlimited screen time" (Decision 2.3). If only `int? dailyLimitMinutesOverride` were used, passing `null` would be ambiguous: it could mean "no override provided, use `config`" or "override with unlimited". The companion boolean `hasDailyLimitOverride` removes all ambiguity.

### 5.3 Deferred Persistent Model Migration (Step 7/8)
The persistent canonical model migration is deferred to Stage 4 Step 7/8 under separate authorization:
- Migrate `PolicyConfig.dailyScreenTimeMinutes` to `int?`.
- Update `ScreenTimeCard.dart` with an "Unlimited" switch and null-safe slider arithmetic.
- Update `PoliciesController.updateDailyLimit(int? minutes)`.
- Update `PolicyConfig.fromJson` to deserialize missing/null keys as `null` (unlimited).
- Update parent persistence schema and verify legacy database records.
- **Strict Boundary:** This deferred scope must NOT be executed in Step 2.

---

## 6. Emergency Defaults Contract & Limitations

### 6.1 Finalized Immutable Package Set
The evaluation engine defines an immutable set of exactly **five** standard emergency and essential telephony package identifiers:

```dart
static const Set<String> defaultEmergencyPackages = {
  'com.android.phone',                 // Universal AOSP telephony provider & in-call UI
  'com.google.android.dialer',          // Google Phone (Pixel, Motorola, Android One, Xiaomi Global)
  'com.samsung.android.dialer',         // Samsung One UI Phone
  'com.android.emergency',              // AOSP Emergency Information & ICE lockscreen
  'com.google.android.apps.safetyhub',  // Google Personal Safety & 5-click Emergency SOS
};
```

### 6.2 Documented Operational Limitations
1. **Conservative Package Allowlist:** This is an exact string matching allowlist, not a universal Android runtime capability detector.
2. **OEM Variation:** On devices from OEMs with proprietary dialers (e.g. Huawei, non-global BBK/Oppo), parents must add the specific package to `PolicyConfig.allowedApps` or caller must inject it via `emergencyPackages`.
3. **Pure-Dart Isolation:** The engine never queries Android `PackageManager`, `TelecomManager`, or native APIs.
4. **Subordinate to Parent Blocklist (Decision 2.10):** If a parent explicitly adds any of these package names to `PolicyConfig.blockedApps`, the package is **blocked** (`blockedByParent`).
5. **Exempt from Per-App Limits (Decision 2.28 — Approved Option A):** Emergency packages bypass configured per-app time limits in `PolicyConfig.appLimits` as well as active schedules and global daily quotas, ensuring dialer availability is never restricted by usage duration.
6. **No Feature Unbundling:** Exempting a dialer package allows launching that dialer; it does not restrict dialing non-emergency numbers.

---

## 7. Planned Pure-Dart Usage Snapshot Contract

*(Status: Pure-Dart snapshot contract implemented in Sub-step 2.2; output models deferred to Sub-step 2.4).*

To completely decouple `packages/haven_models` from `apps/haven_child` native channel envelopes, a pure-Dart snapshot contract is implemented in `packages/haven_models/lib/src/policy_evaluator/`:

```dart
/// Completeness status of the supplied usage snapshot.
enum PolicyUsageCompleteness {
  /// Confirmed complete snapshot across all active applications.
  complete,
  /// Partial snapshot (e.g. capped top N applications or query truncated).
  incomplete,
  /// Completeness cannot be verified or evidence is absent.
  unknown,
  /// Usage unavailable (permission denied, query failure, unsupported platform).
  unavailable,
}

/// Freshness state of the supplied usage snapshot.
enum PolicyUsageFreshness {
  /// Telemetry reflects recent usage data up to the native threshold (e.g. within 15 minutes).
  recent,
  /// Telemetry is delayed by native OS batching or throttling (>15 minutes lag).
  delayed,
  /// Telemetry freshness is unknown (e.g. native empty activity without timestamp).
  unknown,
  /// Telemetry is unavailable or could not be queried.
  unavailable,
}

/// Immutable, pure-Dart transient usage snapshot.
@immutable
final class PolicyUsageSnapshot {
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

  final DateTime snapshotDate;
  final DateTime snapshotTime;
  final DateTime startInterval;
  final DateTime endInterval;
  final int? totalForegroundMillis;
  final Map<String, int> appForegroundMillis;
  final PolicyUsageCompleteness completeness;
  final PolicyUsageFreshness freshness;
  final bool isPermissionGranted;

  /// Total measured foreground screen time in minutes, or null if unmeasured.
  int? get totalMinutes =>
      totalForegroundMillis != null ? totalForegroundMillis! ~/ 60000 : null;

  /// Whether the snapshot records zero foreground activity today.
  bool get isEmptyActivity =>
      totalForegroundMillis == 0 &&
      (appForegroundMillis.isEmpty ||
          appForegroundMillis.values.every((m) => m == 0));

  /// Whether the snapshot has any recorded foreground activity today.
  bool get hasRecordedActivity =>
      (totalForegroundMillis != null && totalForegroundMillis! > 0) ||
      appForegroundMillis.values.any((m) => m > 0);

  /// Foreground minutes for a package under Decision 2.16:
  /// Returns 0 ONLY if completeness == complete AND isPermissionGranted == true AND freshness != unavailable.
  /// Returns null (unknown) if the package is missing from an incomplete or unverified dataset.
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

### 7.1 Missing-App Usage Resolution Contract (Decision 2.16 & Freshness Reconciliation)

A missing package's usage may resolve to `0` only when ALL of these conditions are true:
```dart
completeness == PolicyUsageCompleteness.complete &&
    isPermissionGranted &&
    freshness != PolicyUsageFreshness.unavailable
```
Otherwise, missing package usage must resolve to `null`.

#### Authoritative Truth Table:
| Completeness | Permission | Freshness | Missing package usage |
|---|---|---|---|
| `complete` | `granted` | `recent` | `0` (Confirmed Unused) |
| `complete` | `granted` | `delayed` | `0` (Confirmed Unused) |
| `complete` | `granted` | `unknown` | `0` (Confirmed Unused) |
| `complete` | `granted` | `unavailable` | `null` (Unknown/Unmeasured) |
| `complete` | `denied` | `any` | `null` (Unknown/Unmeasured) |
| `unknown`/`incomplete` | `any` | `any` | `null` (Unknown/Unmeasured) |

#### Critical Distinctions:
- `unknown` is not the same as `unavailable`.
- `unknown` does not independently prove data completeness.
- `unknown` may be accepted only when explicit completeness evidence is `complete` and permission is granted.
- `unavailable` always prevents zero inference.
- Permission granted, query success, or an empty map alone must never establish completeness.
- Capture time must never promote telemetry freshness.
- **Scope Allocation (Decision 2.15):** Sub-step 2.2 implements `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and helpers. Evaluation output models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`) are implemented in Sub-step 2.4 alongside the evaluator.

### 7.2 Calendar Date Alignment & Rollover Contract (Decision 2.29 — Approved Option A)
To eliminate stale previous-day usage from falsely blocking applications across midnight date rollover:
1. **Local Calendar Date Matching:** The evaluator evaluates date alignment using the child device-local calendar date:
   `PolicyUsageSnapshot.isSameLocalDate(context.evaluationTime, usage.snapshotDate)`
2. **Invalidation on Date Mismatch:** If this check returns `false`:
   - Aggregate device usage is invalidated: `dailyQuota.isUnavailable = true`, `dailyQuota.usedMinutes = null`, and `dailyQuota.remainingMinutes = null`.
   - Per-app usage lookups resolve to `null` (unmeasured) rather than using stale previous-day data.
   - Neither global nor per-app quotas can be falsely reached or exceeded based on stale previous-day measurements. Quota restrictions fail-safe to unblocked.
3. **No Zero Conversion:** Unavailable or mismatched usage is never converted to zero.
4. **Preservation of Disclosures:** Telemetry completeness (`usageCompleteness`), permission status, and `isDelayed` flags continue to accurately disclose pipeline metadata.
5. **Zero Schema Expansion:** Both `totalForegroundMillis` and `appForegroundMillis` share the snapshot interval. No per-package timestamp or interval fields are added to `PolicyUsageSnapshot` in Step 2.

---

## 8. Time and Schedule Evaluation Contract

### 8.1 Device-Local Wall-Clock Standard & DST (Decision 2.24)
All schedules (e.g. `"21:00"`) express local wall-clock intent on the child's device:
- **Injected Timestamp:** Caller supplies `DateTime evaluationTime`. The evaluator strictly contains **zero** direct calls to `DateTime.now()`.
- **Local Time Normalization:** Callers may supply a `DateTime` whose `isUtc` is true or false. To guarantee that schedule matching always evaluates against the child device's wall-clock time, the evaluator strictly performs local normalization:
  ```dart
  final localTime = evaluationTime.toLocal();
  final weekday = localTime.weekday;
  final hour = localTime.hour;
  final minute = localTime.minute;
  ```
  `toLocal()` performs **local normalization**, guaranteeing device-local wall-clock fields even if the caller passes a UTC `DateTime`. It is **not** conversion to UTC.
- **Weekday Boundary Crossover Example:** When an instant is supplied in UTC, its UTC weekday may differ from device-local weekday (e.g. UTC instant `2026-11-18 02:30:00 UTC` is `2026-11-17 21:30:00` in UTC-5, where local weekday is Tuesday). Explicit `toLocal()` normalization guarantees that schedule matching evaluates against the correct local weekday (`Tuesday`).
- **Zero UTC Matching:** UTC hour and UTC weekday are never used for schedule matching.
- **Deterministic Evaluation:** For any given evaluation instant and device-local timezone, evaluation is strictly deterministic and repeatable.
- **DST Repeated-Hour Semantics (Decision 2.24):** During daylight saving "fall back" (e.g. repeated 01:00 to 01:59 wall-clock hour), both occurrences match the configured wall-clock schedule where deterministic timezone test infrastructure permits.
- **Dart DateTime Timezone Limitations:** Standard Dart `DateTime` does not retain named IANA timezone identifiers (e.g. `America/New_York`). Schedule matching is purely numerical against local wall-clock fields without external timezone dependencies.

### 8.2 Minute Precision & Half-Open Boundaries (Decisions 2.19, 2.25)
- **Minute-of-Day:** Derived strictly from the normalized local time as `currentMinutes = localTime.hour * 60 + localTime.minute` (range `0..1439`).
- **Seconds & Milliseconds Ignored:** Seconds and sub-second components are discarded after normalization:
  - `08:00:59.999` belongs to minute `480` and is ACTIVE at an `08:00` start.
  - `14:59:59.999` belongs to minute `899` and is ACTIVE before a `15:00` end.
  - `15:00:00.000` belongs to minute `900` and is INACTIVE at a `15:00` end.
- **Half-Open Standard:** All intervals operate on `[startTime, endTime)`:
  - Exact start minute is ACTIVE (`currentMinutes >= startMinutes`).
  - Exact end minute is INACTIVE (`currentMinutes < endMinutes`).

### 8.3 Weekday Validation & Fail-Safe Inactive (Decision 2.23)
- **ISO 8601 Range:** Valid weekdays are integers `1` (Monday) through `7` (Sunday).
- **Empty Days:** A schedule with empty `days` never activates (`false`).
- **Invalid Weekday Entries:** If any element of `days` is outside `1..7` (e.g. `0`, `8`, `-1`), the schedule is invalid. The evaluator rejects the schedule and treats it as fail-safe INACTIVE (`false`). The evaluator must **not** silently ignore invalid entries and partially activate on remaining valid days.

### 8.4 Zero-Duration Intervals & Defensive Time Parsing (Decisions 2.19, 2.20)
- **Zero-Duration (`startTime == endTime`):** If `startTime == endTime`, the interval is $[t, t) = \emptyset$ (zero minutes). The schedule is INACTIVE at all times.
- **Malformed Time String Resilience:** Time strings are parsed defensively (`parts.length == 2`, hours `0..23`, minutes `0..59`). Unparseable or out-of-range strings evaluate as fail-safe INACTIVE without throwing exceptions. Valid times are never fabricated from malformed input.

### 8.5 Restrictive Intersection & Bedtime Lockdown (Decisions 2.6, 2.11)
- **Restrictive Intersection (Decision 2.6):** When multiple schedules are simultaneously active, allowed applications are the strict set intersection of all active schedule whitelists:
  $$\text{AllowedAppExceptions} = \bigcap_{s \in \text{activeSchedules}} s.\text{allowedApps}$$
- **Bedtime Lockdown Protection (Decision 2.11):** Default Bedtime has `allowedApps: const []`. Because intersection with an empty set is empty ($\emptyset$), active Bedtime guarantees zero allowed app exceptions, preventing School or Custom schedule whitelists from overriding Bedtime.
- **Zero Exceptions:** An empty `allowedApps` list represents zero exceptions (all non-emergency applications restricted).

### 8.6 Evaluation Result Architecture (Decision 2.21)
The schedule evaluator produces an immutable `ScheduleEvaluationResult`:
```dart
@immutable
final class ScheduleEvaluationResult {
  const ScheduleEvaluationResult({
    required this.isAnyScheduleActive,
    required this.isBedtimeActive,
    required this.isSchoolActive,
    required this.activeSchedules,
    required this.allowedAppExceptions,
  });

  final bool isAnyScheduleActive;
  final bool isBedtimeActive;
  final bool isSchoolActive;
  final List<PolicySchedule> activeSchedules;
  final Set<String> allowedAppExceptions;

  bool isAppAllowed(String packageName) => allowedAppExceptions.contains(packageName);
}
```
All collection fields (`activeSchedules`, `allowedAppExceptions`) must be defensively copied and unmodifiable (`List.unmodifiable`, `Set.unmodifiable`).

### 8.7 No Active Schedules Semantics & Caller Invariants (Decision 2.22)
- When no schedules are active:
  - `isAnyScheduleActive == false`.
  - `activeSchedules` is empty (`[]`).
  - `allowedAppExceptions` is empty (`{}`).
- **CRITICAL DISTINCTION:** An empty `allowedAppExceptions` set must **NOT** independently be interpreted as lockdown when no schedule is active.
- **Caller Invariant:** Callers (such as `PolicyEvaluator` in Sub-step 2.4) must check `isAnyScheduleActive` before applying schedule restrictions. Calling `isAppAllowed()` alone does not establish whether a schedule restriction is active.

### 8.8 Authoritative Schedule Evaluation Algorithm
```dart
int? _parseMinutes(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

bool isScheduleActive(PolicySchedule schedule, DateTime evaluationTime) {
  if (!schedule.isActive) return false;
  if (schedule.days.isEmpty) return false;
  // Decision 2.23: Reject invalid weekday values fail-safe
  if (schedule.days.any((d) => d < 1 || d > 7)) return false;

  final start = _parseMinutes(schedule.startTime);
  final end = _parseMinutes(schedule.endTime);
  if (start == null || end == null) return false;
  // Decision 2.19: Equal start/end is zero-duration, never active
  if (start == end) return false;

  // Local normalization: guarantees device-local wall-clock fields (Decision 2.24)
  final localTime = evaluationTime.toLocal();
  final currentDay = localTime.weekday;
  final currentMinutes = localTime.hour * 60 + localTime.minute;

  if (start < end) {
    // Normal daytime interval: [start, end)
    return schedule.days.contains(currentDay) &&
           currentMinutes >= start &&
           currentMinutes < end;
  } else {
    // Overnight cross-midnight interval
    final isEveningMatch = schedule.days.contains(currentDay) &&
                           currentMinutes >= start;
    final previousDay = currentDay == 1 ? 7 : currentDay - 1;
    final isMorningMatch = schedule.days.contains(previousDay) &&
                           currentMinutes < end;
    return isEveningMatch || isMorningMatch;
  }
}
```

---

## 9. Multi-Dimensional Result Contract

```dart
enum PolicyOverallState {
  allowed,
  bedtimeActive,
  schoolActive,
  scheduleRestricted,
  dailyLimitReached,
  dailyLimitExceeded,
  usageUnavailable,
}

enum AppPolicyStatus {
  exempt,
  allowed,
  scheduleAllowed,
  scheduleRestricted,
  appLimitReached,
  dailyLimitReached,
  blockedByParent,
  usageUnavailable,
}

final class DailyQuotaEvaluation {
  const DailyQuotaEvaluation({
    required this.limitMinutes,
    required this.usedMinutes,
    required this.remainingMinutes,
    required this.isReached,
    required this.isExceeded,
    required this.isUnavailable,
    required this.isUnlimited,
  });

  final int? limitMinutes;
  final int? usedMinutes;
  final int? remainingMinutes;
  final bool isReached;
  final bool isExceeded;
  final bool isUnavailable;
  final bool isUnlimited;
}

final class AppEvaluation {
  const AppEvaluation({
    required this.packageName,
    required this.status,
    required this.reason,
    required this.usedMinutes,
    this.limitMinutes,
    this.remainingMinutes,
  });

  final String packageName;
  final AppPolicyStatus status;
  final String reason;
  final int? usedMinutes;
  final int? limitMinutes;
  final int? remainingMinutes;

  bool get isRestricted =>
      status == AppPolicyStatus.scheduleRestricted ||
      status == AppPolicyStatus.appLimitReached ||
      status == AppPolicyStatus.dailyLimitReached ||
      status == AppPolicyStatus.blockedByParent;
}

final class PolicyEvaluationResult {
  PolicyEvaluationResult({
    required this.overallState,
    required this.evaluationTime,
    required List<PolicySchedule> activeSchedules,
    required this.dailyQuota,
    required Map<String, AppEvaluation> appEvaluations,
    required this.isDowntimeActive,
    required this.primaryReason,
    List<String> secondaryReasons = const [],
    this.usageCompleteness = PolicyUsageCompleteness.complete,
    this.isDelayed = false,
  }) : activeSchedules = List.unmodifiable(activeSchedules),
       appEvaluations = Map.unmodifiable(appEvaluations),
       secondaryReasons = List.unmodifiable(secondaryReasons);

  final PolicyOverallState overallState;
  final DateTime evaluationTime;
  final List<PolicySchedule> activeSchedules;
  final DailyQuotaEvaluation dailyQuota;
  final Map<String, AppEvaluation> appEvaluations;
  final bool isDowntimeActive;
  final String primaryReason;
  final List<String> secondaryReasons;
  final PolicyUsageCompleteness usageCompleteness;
  final bool isDelayed;

  /// Mandatory transparent disclosure required by Decision 4.4.
  String get disclosure =>
      'Policies are evaluated locally. Application blocking is not enforced on this build.';
}
```

### 9.1 Multi-Dimensional Result Invariants & Decision Synchronization

1. **Non-Const Constructor with Defensive Immutability:** `PolicyEvaluationResult` requires a non-const constructor because `List.unmodifiable` and `Map.unmodifiable` are runtime factory calls. Value objects without collection fields (`DailyQuotaEvaluation`, `AppEvaluation`) remain `const`. No mutable collection references leak through the public result model.
2. **Target Package Resolution (Decision 2.26):**
   - When `targetPackages` is omitted (`null`), the evaluator dynamically evaluates the union of:
     `config.blockedApps` $\cup$ `config.allowedApps` $\cup$ `config.appLimits.keys` $\cup$ active schedule `allowedApps` exceptions $\cup$ `usage.appForegroundMillis.keys`. Deduplication is performed using set semantics.
   - When `targetPackages` is explicitly passed (`Iterable<String>`), it is **authoritative** for the returned `appEvaluations` map (deduplicated via `toSet()`). The evaluator produces evaluation entries specifically for the requested packages.
3. **Overall State Visual Priority (Decision 2.27):**
   - Active schedule state receives visual priority over global daily quota when determining `overallState` and `primaryReason`.
   - When an active schedule (e.g. Bedtime or School Hours) and daily quota exhaustion coexist:
     - `overallState` reflects the schedule state (`bedtimeActive`, `schoolActive`, or `scheduleRestricted`).
     - `primaryReason` reflects the active schedule.
     - Full quota mathematics remain accessible in `dailyQuota`.
     - Quota status is retained as a warning in `secondaryReasons`.
   - When an active schedule has no package restrictions (or exceptions cover queried apps), `overallState` reflects the schedule presence while individual app statuses are `scheduleAllowed` (or `allowed`).
   - App-specific limits (e.g. YouTube per-app limit reached) never silently redefine the device-level `overallState`.
4. **Unknown Usage & Overall State Policy (Decision 2.30):**
   - Unknown or unavailable usage telemetry alone must NOT force `overallState = usageUnavailable`.
   - The device `overallState` reflects the actual policy outcome: if no schedule is active and quotas cannot be proven exceeded, `overallState = allowed`.
   - Unavailable telemetry is disclosed via `dailyQuota.isUnavailable = true`, per-package `usedMinutes = null`, and `usageCompleteness = unknown` (or `incomplete`).
   - If telemetry lag exceeds native thresholds, `isDelayed = true` is set.
   - Missing app usage resolves to `0` only under the strict Decision 2.16 conditions.

---

## 10. Revised Six-Step Implementation Sequence

Every handwritten source and test file strictly adheres to the $\le 200$-line limit.

```
Sub-step 2.1: Evaluation Quota Input Contracts & Tri-State Boundary
     │
     ▼
Sub-step 2.2: Pure-Dart Transient Usage Snapshot Contracts
     │
     ▼
Sub-step 2.3: Core Schedule & Interval Evaluation Engine
     │
     ▼
Sub-step 2.4: Deterministic Policy Evaluator & Multi-Dimensional Output Contracts (7-level precedence)
     │
     ▼
Sub-step 2.5: Comprehensive Unit, Conflict, and Edge-Case Test Suites (C-01..C-20)
     │
     ▼
Sub-step 2.6: Full Repository Regression Run & Verification
```

---

### Sub-Step 2.1: Evaluation Quota Input Contracts & Tri-State Boundary
- **Scope:** Define `PolicyEvaluationContext` with tri-state `int? dailyLimitMinutesOverride` and `hasDailyLimitOverride`. Verify existing canonical `PolicyConfig` remains 100% untouched.
- **Files Created:**
  - `packages/haven_models/lib/src/policy_evaluator/policy_evaluation_context.dart` (~80 lines)
- **Dependencies:** `packages/haven_models/lib/src/policy_config.dart`.
- **Tests Required:**
  - Effective limit resolution (fallback to config, explicit null unlimited, explicit zero, explicit positive, negative throws ArgumentError).
- **Acceptance Criteria:** `packages/haven_models` and `apps/haven_app` compile cleanly without modifications to `PolicyConfig`.
- **Exclusions:** Zero changes to `policy_config.dart`, `ScreenTimeCard.dart`, or parent controllers.

---

### Sub-Step 2.2: Pure-Dart Transient Usage Snapshot Contracts
- **Scope:** Create `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and snapshot-specific validation and conversion helpers. Evaluation output models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`) are explicitly deferred to Sub-step 2.4 per Decision 2.15.
- **Files Created:**
  - `packages/haven_models/lib/src/policy_evaluator/policy_usage_snapshot.dart` (~125 lines)
- **Dependencies:** Pure Dart standard library (`dart:core`).
- **Tests Required:**
  - Usage snapshot minutes conversion (`totalMinutes`, `appMinutes`).
  - Production-safe runtime validation via `ArgumentError` (negative total millis, negative per-package millis, blank package keys, invalid interval ordering).
  - Preservation of valid zero usage values.
  - Decision 2.16 missing package resolution (0 for complete + permission, null for incomplete, unknown, or permission denied).
  - Decoupling of telemetry freshness (`recent`, `delayed`, `unknown`, `unavailable`) from empty activity (`isEmptyActivity`).
  - Decision 2.17 capture instant vs native freshness independence.
  - Immutability of package map (`Map.unmodifiable`).
  - Discrepancy tolerance between total foreground millis and app sum.
- **Acceptance Criteria:** Types compile cleanly under pure Dart SDK; zero Flutter imports; all files $\le 200$ lines.

---

### Sub-Step 2.3: Core Schedule & Interval Evaluation Engine
- **Scope:** Implement pure-Dart deterministic wall-clock interval math, daytime intervals, cross-midnight overnight intervals, minute precision, ISO weekday validation, defensive time parsing, and multi-schedule restrictive intersection under Decisions 2.19–2.25.
- **Files Created:**
  - `packages/haven_models/lib/src/policy_evaluator/schedule_evaluator.dart` (~140 lines)
  - `packages/haven_models/test/policy_evaluator/schedule_evaluator_test.dart` (~195 lines)
- **Files Modified:**
  - `packages/haven_models/lib/haven_models.dart` (export `ScheduleEvaluator` and `ScheduleEvaluationResult`)
- **Dependencies:** `packages/haven_models/lib/src/policy_schedules.dart`, `package:meta/meta.dart`.
- **Tests Required (Comprehensive Test Matrix):**
  1. Normal weekday matching (local DateTime matches expected local weekday and time).
  2. Start inclusive boundary (`currentMinutes == startMinutes` -> active).
  3. End exclusive boundary (`currentMinutes == endMinutes` -> inactive).
  4. Seconds and milliseconds ignored (minute precision preserved after normalization).
  5. Overnight evening segment (day $D$, `currentMinutes >= startMinutes`).
  6. Overnight morning segment (day $D+1$, `currentMinutes < endMinutes`).
  7. Sunday-to-Monday rollover (`previousDay = 7` when `currentDay = 1`).
  8. Equal start and end times inactive at all times (`startTime == endTime`).
  9. Empty weekdays list never active (`days: []`).
  10. Invalid weekday values rejected fail-safe (`days: [0, 8, -1]`).
  11. Malformed time strings fail-safe inactive without throwing (`"bad:time"`, `""`, `"25:00"`).
  12. Disabled schedules ignored (`isActive: false`).
  13. No active schedules means no restriction (`isAnyScheduleActive == false`).
  14. Caller checks `isAnyScheduleActive` (empty exceptions != lockdown when inactive).
  15. Two-schedule whitelist restrictive intersection.
  16. Empty whitelist intersection yields empty set ($\emptyset$).
  17. Bedtime lockdown protection (Bedtime empty whitelist forces total intersection to $\emptyset$).
  18. UTC DateTime input normalization (UTC instant produces identical schedule result to local instant).
  19. UTC/Local boundary crossover (UTC instant crossing midnight/weekday matches correct device-local weekday).
  20. DST repeated-hour matching (both wall-clock occurrences match where test infrastructure permits).
  21. Deterministic repeated evaluation (zero clock drift, zero `DateTime.now()` calls).
- **Acceptance Criteria:** 100% branch coverage of schedule evaluation math; all files $\le 200$ lines.

---

### Sub-Step 2.4: Deterministic Policy Evaluator & Multi-Dimensional Output Contracts
- **Scope:** Implement multi-dimensional evaluation output models (`PolicyEvaluationResult`, `DailyQuotaEvaluation`, `AppEvaluation`, `PolicyOverallState`, `AppPolicyStatus`) in `policy_evaluation_models.dart` per Decision 2.15 (with non-const runtime defensive copies for result collections), and implement `PolicyEvaluator.evaluate()` in `policy_evaluator.dart` resolving the 7-level precedence hierarchy, hard parent blocklist veto (overrides emergency, whitelists, and quotas), emergency defaults bypassing schedules, daily quota, and per-app limits (Decision 2.28 — Approved Option A), local calendar-date rollover fail-safe invalidation of global and per-app usage (Decision 2.29 — Approved Option A), schedule visual priority (Decision 2.27), dynamic target package union (Decision 2.26), and data-quality reporting without forcing overall state to unavailable (Decision 2.30).
- **Files Created:**
  - `packages/haven_models/lib/src/policy_evaluator/policy_evaluation_models.dart` (~150 lines)
  - `packages/haven_models/lib/src/policy_evaluator/policy_evaluator.dart` (~180 lines)
- **Files Modified:**
  - `packages/haven_models/lib/haven_models.dart` (register canonical exports)
- **Dependencies:** Sub-steps 2.1–2.3, plus `policy_evaluation_models.dart`.
- **Tests Required:**
  - 100% pure determinism: identical inputs yield identical outputs.
  - Zero direct clock reads.
  - Mandatory disclosure string verified on all outputs.
  - Dynamic target package union evaluation when `targetPackages` is omitted; authoritative filtering when supplied.
  - Active schedule visual priority over daily quota in `overallState` and `primaryReason`.
  - Retention of quota metrics in `dailyQuota` and quota warning in `secondaryReasons`.
  - Fail-safe evaluation when telemetry is unknown/unavailable without forcing `overallState = usageUnavailable`.
  - Emergency package bypass of per-app limits (Decision 2.28).
  - Date mismatch invalidation of both global and per-app usage (Decision 2.29).
  - Full evaluation output model contract verification.
- **Acceptance Criteria:** Evaluator resolves all inputs without throwing runtime exceptions; all files $\le 200$ lines.

---

### Sub-Step 2.5: Comprehensive Unit, Conflict, and Edge-Case Test Suites
- **Scope:** Implement comprehensive unit test suites covering all 20 conflict scenarios (C-01 through C-20), DST transitions, and usage completeness.
- **Files Created:**
  - `packages/haven_models/test/schedule_evaluator_test.dart` (~190 lines)
  - `packages/haven_models/test/policy_evaluator_test.dart` (~190 lines)
  - `packages/haven_models/test/policy_precedence_test.dart` (~195 lines)
  - `packages/haven_models/test/policy_usage_snapshot_test.dart` (~120 lines)
- **Dependencies:** Sub-steps 2.1–2.4.
- **Tests Required:**
  - All 20 pair-by-pair conflicts verified (including parent blocklist over emergency, and bedtime over school whitelist).
  - Emergency packages with per-app limits below, at, and above threshold (exempt).
  - Emergency package blocklisted by parent (`blockedByParent`).
  - Snapshot date mismatch invalidates global and per-app usage without false blocking.
  - DST 23-hour spring forward and 25-hour fall back edge cases.
  - Complete vs incomplete usage data evaluation.
- **Acceptance Criteria:** All test files $\le 200$ lines; all tests pass.

---

### Sub-Step 2.6: Full Repository Regression Run & Verification
- **Scope:** Execute full repository-wide regression tests and static analysis.
- **Verification Commands:**
  - `fvm dart test packages/haven_models`
  - `fvm flutter test packages/haven_core`
  - `fvm flutter test packages/haven_offline`
  - `fvm flutter test packages/haven_api`
  - `fvm flutter test apps/haven_child`
  - `fvm flutter test apps/haven_app`
  - `flutter analyze`
- **Line Count Verification:** Automated script verifying all handwritten source/test files are $\le 200$ lines.
- **Acceptance Criteria:** All 1,427+ baseline tests pass; zero analyzer warnings; zero line-count violations.

---

## 11. Required Regression and Acceptance Baseline

| Test Suite | Historical Baseline | Step 2 Target |
|:---|:---:|:---:|
| `packages/haven_models` | 35 tests | ~75+ tests |
| `packages/haven_core` | 18 tests | 18 tests |
| `packages/haven_offline` | 44 tests | 44 tests |
| `packages/haven_api` | 22 tests | 22 tests |
| `apps/haven_child` | 330 tests | 330 tests |
| `apps/haven_app` (Parent) | 943 tests | 943 tests |
| Native Kotlin (`apps/haven_child`) | 35 tests | 35 tests |
| **Total Test Count** | **1,427 tests** | **~1,467+ tests** |

*Note: The 1,427 figure is a reported historical baseline. A fresh full regression run will be executed during implementation.*

---

## 12. Remaining Owner Clarifications & Revision Log

There are currently **zero open architectural blockers**. All thirty Stage 4 owner decisions (Decisions 2.1 through 2.30) are now fully confirmed, reconciled, and approved:
- **v1.5.0-SUBSTEP-SYNCHRONIZED:** Synchronized Sub-step 2.2 and Sub-step 2.4 scopes with Decision 2.15 (deferring `PolicyEvaluationResult`, `DailyQuotaEvaluation`, and `AppEvaluation` to Sub-step 2.4; restricting Sub-step 2.2 to `PolicyUsageSnapshot`, `PolicyUsageCompleteness`, `PolicyUsageFreshness`, and helpers). Updated Section 7 snapshot contract and Section 10 implementation sequence.
- **v1.5.1-FINAL-UNKNOWN-FRESHNESS-CONFIRMED:** Added explicit missing-package resolution condition, authoritative truth table, and critical distinctions in Section 7.1 confirming that `PolicyUsageFreshness.unknown` resolves to 0 only when completeness is `complete` and permission is `granted`.
- **v1.6.0-SUBSTEP-2-3-SYNCHRONIZED:** Synchronized Sub-step 2.3 with Owner Decisions 2.19–2.25: half-open interval boundaries `[start, end)`, defensive time parsing without runtime exceptions, zero-duration inactive intervals, immutable `ScheduleEvaluationResult`, 'no active schedules' semantics and caller invariants, ISO weekday validation (rejecting out-of-bounds days fail-safe), device-local wall-clock and DST repeated-hour handling, and minute precision. Added 20-category test matrix to Sub-step 2.3.
- **v1.6.1-FINAL-TIMEZONE-NORMALIZED:** Updated Section 8.1 and 8.8 to require explicit local normalization via `evaluationTime.toLocal()` ensuring callers passing UTC DateTime correctly evaluate against device-local wall clock, clarified that `toLocal()` is local normalization rather than UTC conversion, verified emergency schedule exemption decision traceability (Decisions 2.2, 2.10, PR-02, C-06, C-07), and expanded Sub-step 2.3 test matrix to include explicit UTC normalization, boundary crossover, and zero clock-access invariants.
- **v1.7.0-SUBSTEP-2-4-SYNCHRONIZED:** Synchronized Sub-step 2.4 with Owner Decisions 2.26 (dynamic target package union when omitted, authoritative when supplied), 2.27 (active schedule visual priority in `overallState` and `primaryReason`, with quota metrics preserved in `dailyQuota` and `secondaryReasons`), and 2.30 (telemetry unavailability disclosed separately without forcing `overallState = usageUnavailable`). Recorded Decisions 2.28 and 2.29 as under clarification.
- **v1.8.0-SUBSTEP-2-4-OWNER-APPROVED:** Synchronized confirmed Owner Decisions 2.28 (Emergency packages exempt from explicit per-app limits unless parent-blocklisted) and 2.29 (Date mismatch invalidates both global and per-app usage fail-safe without false blocking or schema changes). All 30 Stage 4 owner decisions (2.1–2.30) are now fully confirmed and approved.

---

## 13. Strict Owner Authorization Gate

> [!CAUTION]
> **IMPLEMENTATION REMAINS STRICTLY UNAUTHORIZED.**  
> This document represents the final, reconciled, implementation-ready execution plan for Stage 4 Step 2. No source code was modified, no tests were written, and no Git mutations were performed.  
> **Explicit owner implementation authorization is required before beginning Sub-Step 2.1.**

---

## 13. Strict Owner Authorization Gate

> [!CAUTION]
> **IMPLEMENTATION REMAINS STRICTLY UNAUTHORIZED.**  
> This document represents the final, reconciled, implementation-ready execution plan for Stage 4 Step 2. No source code was modified, no tests were written, and no Git mutations were performed.  
> **Explicit owner implementation authorization is required before beginning Sub-Step 2.1.**
