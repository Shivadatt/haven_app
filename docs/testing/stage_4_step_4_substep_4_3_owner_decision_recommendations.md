# HAVEN PARENT CONTROL — STAGE 4, STEP 4, SUB-STEP 4.3
## Owner Decision & UI Contract Finalization Report

**Repository:** `D:\control`  
**Branch:** `main`  
**Expected HEAD:** `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2`  
**Execution Mode:** STRICT READ-ONLY AUDIT & DECISION PREPARATION  
**Implementation Authorization:** NOT GRANTED  
**Status:** Audit Complete — Awaiting Owner Review and Explicit Authorization  

---

## 1. Executive Summary & Final Verdict

### Final Readiness Verdict
# **A — READY FOR OWNER APPROVAL**

**The architectural contracts, reactive GetX interfaces, and presentation requirements for Sub-step 4.3 have been rigorously audited. Every decision has been verified against the immutable production source code, ensuring that the child UI remains strictly read-only, transparent, and non-enforcing, with zero policy mutation capability, zero remote sync, and zero changes to underlying controller or repository layers.**

---

## 2. Preflight & Baseline Verification

| Preflight Parameter | Required Baseline | Verified Reality in Repository | Status |
|---|---|---|---|
| **Repository Root** | `D:\control` | `D:/control` | **PASS** |
| **Current Branch** | `main` | `main` | **PASS** |
| **Baseline HEAD** | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | **PASS** |
| **Working Tree State** | Clean tracked files | Exactly 4 staged documentation reports from previous audits, 0 unstaged modifications, 0 untracked files | **PASS** |

---

## 3. Verified Controller APIs & Public Contract

A thorough inspection of `apps/haven_child/lib/features/policies/controllers/child_policy_controller.dart` reveals its exact public contract:

```dart
final class ChildPolicyController extends GetxController {
  // Public final dependencies
  final ChildPolicyRepository policyRepository;
  final ChildUsageRepository usageRepository;
  final Clock clock;

  // Public reactive state observables
  final Rx<ChildPolicyStatus> status;
  final Rxn<ChildPolicyRecord> activePolicy;
  final Rxn<HavenFailure> policyFailure;
  final Rxn<PolicyEvaluationResult> lastEvaluation;

  // Public getters
  ChildPolicyRecord? get lastValidPolicy;
  HavenFailure? get lastUsageFailure;
  UsagePermissionStatus? get lastUsagePermissionStatus;
  bool get isDisposed;

  // Public lifecycle and operation methods
  @override void onInit();
  @override void onClose();
  Future<Result<void>> loadPolicy();
  Future<Result<PolicyEvaluationResult>> evaluate();
}
```

**Key Findings:**
1. **Zero Policy Mutation Methods:** `ChildPolicyController` has no `savePolicy()`, `updatePolicy()`, `setRules()`, or edit endpoints.
2. **Zero Remote Sync APIs:** The controller only re-reads local storage (`policyRepository.getPolicy()`) and queries the local device usage repository (`usageRepository`). It has no network, Supabase, or polling dependencies.
3. **Public Repository Reference:** While `controller.policyRepository` is a public field, `ChildPolicyRepository.saveSyncedPolicy` is reserved strictly for Stage 5 sync. The UI will **never** receive or invoke `policyRepository`.

---

## 4. Analysis of Owner Decisions

### Decision 4.3.1 — Read-Only Reactive State
**Question:** How can the UI observe controller state without receiving mutation-capable references?

#### Technical Analysis:
- `ChildPolicyController` exposes GetX observables (`Rx<ChildPolicyStatus>`, `Rxn<ChildPolicyRecord>`, `Rxn<PolicyEvaluationResult>`, `Rxn<HavenFailure>`).
- In GetX, `Rx<T>` allows reading `.value` and observing via `Obx(...)`. However, an `Rx<T>` theoretically permits `.value = ...` reassignment if exposed directly to subcomponents.
- In `ChildPolicyController`, `policyRepository` is a public field. If card widgets receive `ChildPolicyController`, they gain indirect access to `controller.policyRepository`.

#### Recommended Access Pattern (Value-Binding Downward):
- **Recommendation:** Adopt a strictly unidirectional, **Value-Binding Access Pattern**.
- **Rule:** Only the top-level page widget (`ChildPolicyPage`) resolves `Get.find<ChildPolicyController>()`.
- **Card Isolation:** Individual presentation cards (`PolicyStatusCard`, `DailyQuotaCard`, `PolicySchedulesCard`, `AppRestrictionsCard`, `WebRestrictionsCard`) must **NEVER** accept `ChildPolicyController` as a constructor parameter.
- Instead, cards must accept only immutable values extracted from the controller:
  - `PolicyStatusCard` takes `final ChildPolicyRecord? record`, `final ChildPolicyStatus status`, `final PolicyOverallState? overallState`.
  - `DailyQuotaCard` takes `final DailyQuotaEvaluation? quota`, `final int configuredMinutes`, `final bool isNeutral`.
  - `AppRestrictionsCard` takes `final List<String> blockedApps`, `final List<String> allowedApps`, `final Map<String, int> appLimits`, `final Map<String, AppEvaluation>? evaluations`.
  - `WebRestrictionsCard` takes `final List<String> blockedDomains`, `final List<String> allowedDomains`, `final bool safeSearchEnabled`.
  - `PolicySchedulesCard` takes `final List<PolicySchedule> schedules`, `final List<PolicySchedule> activeSchedules`.
- **Trade-offs:** Passing pure data values slightly increases constructor parameter counts for sub-cards, but completely eliminates the risk of UI widgets invoking repository writes or modifying observable state.

---

### Decision 4.3.2 — Refresh Behavior
**Question:** Is an existing reload operation available and safe for UI invocation, or should refresh be omitted?

#### Technical Analysis:
- `ChildPolicyController` exposes two async operations:
  1. `loadPolicy()`: Asynchronously reads the policy record from `LocalChildPolicyRepository.fromDatabase(value)`. It creates zero repository writes, performs zero network operations, and simply refreshes in-memory state from the local SQLite/document store.
  2. `evaluate()`: Performs a fresh evaluation using current time and queries the native usage channel via `usageRepository`.
- Both operations are safe, idempotent, and strictly read-only.
- Pull-to-refresh (`RefreshIndicator`) or an app bar refresh button is standard in the child app (e.g. `ChildUsagePage` has both).

#### Recommended Refresh Contract:
- **Recommendation:** Support safe, local-only refresh using existing controller APIs without adding any new controller methods.
- **Implementation:**
  - Pull-to-refresh on `ChildPolicyPage` invokes:
    ```dart
    Future<void> _handleRefresh(ChildPolicyController controller) async {
      await controller.loadPolicy();
      if (controller.status.value == ChildPolicyStatus.ready) {
        await controller.evaluate();
      }
    }
    ```
  - When the controller is in `ChildPolicyStatus.failure`, the "Try again" button invokes `controller.loadPolicy()`.
- **Trade-offs:** Retaining refresh gives the child an immediate way to re-check storage if their parent just updated rules on the device or if a temporary permission/storage lock resolved, without introducing any write capabilities.

---

### Decision 4.3.3 — Failed Reload Presentation Contract
**Question:** What is the exact presentation contract when an active policy reload fails?

#### Technical Analysis:
- Under Sub-step 4.2 Decision 3A, when `loadPolicy()` fails:
  - `activePolicy.value` becomes `null` (`_active = null`).
  - `status.value` becomes `ChildPolicyStatus.failure`.
  - `policyFailure.value` holds the failure reason.
  - `_lastValid` (accessible via `controller.lastValidPolicy`) retains the previously verified record for diagnostics.
  - Subsequent `evaluate()` calls strictly return `_evalFailure('Policy evaluation refused', 'policy_evaluation_refused')`.

#### Recommended Presentation Contract:
- **Recommendation:** Strict suspension presentation.
  1. **Primary State Banner:** Display a prominent warning banner using `ChildColors.warning`:  
     `"Rule Check Failed — Active Policy Suspended"`
  2. **Prohibited Presentation:** The UI must **NEVER** present the previous valid policy as actively in effect, nor calculate active remaining screen time quotas.
  3. **Diagnostic Attribution:** If `controller.lastValidPolicy` is non-null, display a clear, non-authoritative diagnostic note:  
     `"Last verified version on record: v${lastValid.policyVersion} (${formatDate(lastValid.updatedAt)}) — Currently inactive due to storage verification failure."`
  4. **Quota & Restrictions Cards:** Rendered in a disabled/unavailable state indicating: `"Limits cannot be evaluated while rule verification is failing."`
  5. **Recovery Action:** Render an honest `"Try again"` button that calls `controller.loadPolicy()`.
- **Trade-offs:** Showing that evaluation is suspended prevents children from operating under false assumptions of active rules, while the diagnostic note prevents panic by showing the parent's rule history was not erased.

---

### Decision 4.3.4 — Usage and Quota Presentation Matrix
**Question:** How should every combination of usage acquisition and quota state be presented?

| Scenario | Controller / Evaluator State | UI Presentation Rule | Prohibited Presentation |
|---|---|---|---|
| **1. Permission Denied** | `isPermissionGranted: false`, `quota.isUnavailable: true` | Display configured limit (e.g. "120 min daily limit set by parent"), with status: `"Usage permission not granted — screen time cannot be measured"`. Include "Open Settings" action. | **NEVER** display used as 0m or remaining as full quota. |
| **2. Permission Unsupported** | `UsagePermissionStatus.unsupported`, `quota.isUnavailable: true` | Display configured limit with notice: `"Usage tracking is unsupported on this device/platform"`. | **NEVER** claim quota is active or exceeded. |
| **3. Probe / Query Failure** | `usageFailure != null`, `quota.isUnavailable: true` | Display configured limit with notice: `"Temporary error checking usage. Screen time check paused"`. Include "Retry" button. | **NEVER** invent usage numbers or report quota reached. |
| **4. Empty Native Result** | `UsageDataFreshness.empty` -> `quota.isUnavailable: true` | Display configured limit with notice: `"No usage recorded for today yet (unverified)"`. | **NEVER** show confirmed 0m screen time. |
| **5. Unknown Completeness** | `usageCompleteness == PolicyUsageCompleteness.unknown` | Display used minutes with badge: `"Estimated Usage — Unconfirmed Total"`. Per-app lists display measured positive app usage. | **NEVER** display total as a verified daily sum. |
| **6. Exact Local Midnight** | `range.start == range.end`, query bypassed | Display: `"0m used · New day starting"`. Status: Normal. | **NEVER** display an error or negative time. |
| **7. Positive Quota, Usage Unavailable** | `quota.limitMinutes > 0`, `quota.isUnavailable: true` | Display: `"${quota.limitMinutes} min daily limit (Usage data unavailable)"`. Status: Unverified. | **NEVER** show remaining time or assume limit reached. |
| **8. Quota Reached / Exceeded** | `quota.isReached == true` or `quota.isExceeded == true` | Display status chip: `"Daily Limit Reached"` (`StatusTone.bad`), used/remaining time, and non-enforcement disclosure. | **NEVER** claim device is locked or apps are blocked. |

---

### Decision 4.3.5 — Policy Semantics & Field-to-Widget Mapping
**Question:** Exactly which fields from `PolicyConfig` and `PolicyEvaluationResult` may each card display?

#### 1. `PolicyStatusCard`
- **Fields Displayed:**
  - `record.provenance`: Rendered as `ChildStatusChip` ("Neutral Fallback" / "Active Family Rules").
  - `record.policyVersion`: "Version v${record.policyVersion}".
  - `record.updatedAt`: Formatted date/time.
  - `evaluation.overallState`: Formatted headline ("Allowed", "Bedtime Active", "Daily Limit Reached", "Usage Unavailable").
  - `evaluation.primaryReason`: Plain-language explanation string from evaluator.
- **Explicit Exclusions:** Does not display database hash, storage keys, or raw JSON.

#### 2. `DailyQuotaCard`
- **Fields Displayed:**
  - `config.dailyScreenTimeMinutes`: Configured daily quota.
  - `quota.usedMinutes` & `quota.remainingMinutes`: Formatted in hours and minutes.
  - `quota.isReached` / `quota.isExceeded`: Visual indicator.
  - `quota.isUnavailable`: Informational unavailable state.
  - `quota.isUnlimited`: Indicates no daily screen time limit (for neutral policy).
- **Explicit Exclusions:** Does not allow adjusting minutes, requesting extra time, or resetting timers.

#### 3. `PolicySchedulesCard`
- **Fields Displayed:**
  - `config.schedules`: List of configured schedules (`PolicySchedule.name`, `type`, `startTime`, `endTime`, `daysOfWeek`).
  - `evaluation.activeSchedules`: Matched against configured schedules to render an `"Active now"` badge (`StatusTone.warning`).
- **Explicit Exclusions:** Does not claim the device is disabled, locked, or inaccessible during active downtime.

#### 4. `AppRestrictionsCard`
- **Fields Displayed:**
  - `config.blockedApps`: Cleanly formatted package names with `"Blocked by parent"` tag.
  - `config.appLimits`: List of package names with daily time limits (e.g. `"com.google.android.youtube · 30m limit"`).
  - `config.allowedApps`: List of explicitly exempt/always-allowed packages.
  - `evaluation.appEvaluations`: Granular evaluated status (`AppPolicyStatus.appLimitReached`, `scheduleRestricted`, etc.).
- **Explicit Exclusions:** Does not invent app store links, does not claim background apps are terminated, and does not hide package names.

#### 5. `WebRestrictionsCard`
- **Fields Displayed:**
  - `config.safeSearchEnabled`: Status chip ("SafeSearch: Enabled" / "Disabled").
  - `config.blockedDomains`: List of blocked domain strings.
  - `config.allowedDomains`: List of allowed domain strings (if configured).
- **Explicit Exclusions:** Does not claim network traffic is currently being intercepted or VPN-filtered on this build.

#### 6. `PolicyDisclosureCard`
- **Fields Displayed:**
  - `evaluation.disclosure`: Exactly renders `"Policies are evaluated locally. Application blocking is not enforced on this build."`.

---

### Decision 4.3.6 — UI Structure and Navigation Allowlist
**Question:** Is the proposed 13-file scope complete, cohesive, and compliant with line-count limits?

#### Confirmed 13-File Allowlist:

| File Path | Type | Action | Physical Line Budget ($\le 200$) |
|---|---|---|---|
| `apps/haven_child/lib/app/routes/child_routes.dart` | Existing | Add `policy = '/policy'` | ~25 lines |
| `apps/haven_child/lib/app/routes/child_pages.dart` | Existing | Add `GetPage(name: ChildRoutes.policy, ...)` | ~75 lines |
| `apps/haven_child/lib/features/profile/views/pages/profile_page.dart` | Existing | Add "Rules & Limits" navigation card | ~160 lines |
| `apps/haven_child/lib/features/policies/views/child_policy_page.dart` | New | Main screen with `ChildScaffold` & `Obx` | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_status_card.dart` | New | Provenance, version, overall state card | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/daily_quota_card.dart` | New | Screen time quota & usage evaluation card | ~150 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_schedules_card.dart` | New | Bedtime / school hours schedules card | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/app_restrictions_card.dart` | New | App limits & blocked apps card | ~150 lines |
| `apps/haven_child/lib/features/policies/views/widgets/web_restrictions_card.dart` | New | Domain filtering & SafeSearch card | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_disclosure_card.dart` | New | Local evaluation disclosure card | ~70 lines |
| `apps/haven_child/test/features/policies/child_policy_page_test.dart` | New Test | Page integration test across 4 states | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_widgets_test.dart` | New Test | Unit tests for cards and edge cases | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_navigation_test.dart` | New Test | Navigation transitions & route tests | ~140 lines |

**Assessment:** The scope is strictly minimal, cohesive, and contains zero extraneous utilities or abstractions. Every file comfortably sits below the 200-line ceiling.

---

### Decision 4.3.7 — Disclosure Requirements
**Question:** What exact disclosure copy is required to prevent misleading the child regarding enforcement?

#### Recommended Mandatory Disclosure:
1. **Primary Disclosure Card:** Rendered prominently at the bottom of `ChildPolicyPage`:
   > **Local Evaluation Notice**  
   > *Policies are evaluated locally. Application blocking is not enforced on this build.*
2. **Contextual Status Notes:**
   - In `AppRestrictionsCard`: Note below blocked apps: *"Parent rules specify these apps as blocked. Enforcement will activate in a future update."*
   - In `WebRestrictionsCard`: Note below blocked domains: *"Web restrictions are evaluated locally. Browser traffic is not actively filtered on this build."*
3. **Prohibited Claims:**
   - No statements that the device is "locked".
   - No claims that background processes are being killed.
   - No claims that search queries or private browsing history are being sent to parents.

---

## 5. Explicit Implementation Exclusions

The following tasks are strictly **excluded** from Sub-step 4.3:
1. **No Policy Mutation / Write APIs:** Child cannot create, edit, or delete policy rules.
2. **No Remote Sync:** No backend sync, HTTP calls, Supabase subscriptions, or network polling.
3. **No Native OS Enforcement:** No Android `AccessibilityService`, `DevicePolicyManager`, or process kill commands.
4. **No Controller or Repository Changes:** `ChildPolicyController`, `PolicyUsageAdapter`, and `LocalChildPolicyRepository` remain untouched.
5. **No Evaluator Changes:** `PolicyEvaluator` and `haven_models` remain untouched.

---

## 6. Recommended Owner Decisions Summary

The owner is invited to approve the following recommendations:
1. **Approve Decision 4.3.1 (Read-Only Reactive State):** Value-binding downward pattern; card widgets never receive controller or repository references.
2. **Approve Decision 4.3.2 (Refresh Behavior):** Support read-only refresh via existing `controller.loadPolicy()` and `controller.evaluate()` without adding new controller APIs.
3. **Approve Decision 4.3.3 (Failed Reload Presentation):** Display prominent suspension warning; diagnostic display only of past valid version; suspend quota evaluation.
4. **Approve Decision 4.3.4 (Usage/Quota Presentation):** Follow the 8-state presentation matrix; never display unknown usage as zero.
5. **Approve Decision 4.3.5 (Policy Semantics):** Strictly map verified fields from `PolicyConfig` and `PolicyEvaluationResult` to their designated cards without inventing unbacked models.
6. **Approve Decision 4.3.6 (13-File Scope):** Authorize the exact 3 modified, 7 new presentation, and 3 new test files listed in Section 4.6.
7. **Approve Decision 4.3.7 (Disclosure):** Include mandatory local evaluation disclosure and contextual non-enforcement notes.

---

## 7. Mandatory Stop State

- **Current Status:** Decision recommendations complete.
- **Repository Integrity:** Strictly preserved in READ-ONLY mode. Zero code or test changes.
- **Report Location:** `docs/testing/stage_4_step_4_substep_4_3_owner_decision_recommendations.md` (untracked, unstaged).
- **Next Step:** Await explicit owner decision and formal implementation authorization.
