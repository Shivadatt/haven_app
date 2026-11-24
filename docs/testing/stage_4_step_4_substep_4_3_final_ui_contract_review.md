# HAVEN PARENT CONTROL — STAGE 4, STEP 4, SUB-STEP 4.3
## Final UI Contract Consistency Review

**Repository:** `D:\control`  
**Branch:** `main`  
**Expected HEAD:** `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2`  
**Mode:** STRICTLY READ-ONLY AUDIT & CONTRACT RECONCILIATION  
**Implementation Authorization:** NOT GRANTED  
**Status:** Audit Complete — Awaiting Owner Review and Explicit Authorization  

---

## 1. Executive Summary & Final Verdict

### Final Readiness Verdict
# **A — FINAL UI CONTRACT READY FOR OWNER APPROVAL**

**The Sub-step 4.3 UI presentation contracts have been rigorously reconciled against the approved Sub-step 4.1 and Sub-step 4.2 technical implementations. Every apparent semantic gap—including midnight usage handling, unknown completeness boundaries, allowed-app semantics, concurrent refresh safety, and non-enforcement disclosures—is now fully grounded in the actual production code of `PolicyUsageAdapter`, `ChildPolicyController`, and `PolicyEvaluator`.**

---

## 2. Repository Preflight & Baseline Verification

| Preflight Parameter | Baseline Specification | Repository Reality | Status |
|---|---|---|---|
| **Repository Root** | `D:\control` | `D:/control` | **PASS** |
| **Active Branch** | `main` | `main` | **PASS** |
| **HEAD Commit** | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | **PASS** |
| **Working Tree** | Clean tracked files | Exactly 5 staged documentation reports, 0 unstaged modifications, 0 untracked files | **PASS** |

---

## 3. Exact Source Evidence & Contract Corrections

### 3.1 Exact-Midnight Correction
- **Source Implementation:**
  - `PolicyUsageAdapter.dailyRange(DateTime evaluationTime)`: When `evaluationTime` is exact local midnight, returns `start == end`.
  - `ChildPolicyController.evaluate()` line 132:
    ```dart
    if (range.start < range.end) {
      final result = await usageRepository.getDailyUsage(...);
      ...
    } else {
      usage = _unavailable(range, true);
    }
    ```
  - `PolicyUsageAdapter.unavailableForQuery(...)`: Returns `PolicyUsageSnapshot.unavailable` where `totalForegroundMillis: null`, `completeness: PolicyUsageCompleteness.unknown`, and `freshness: PolicyUsageFreshness.unavailable`.
  - `PolicyEvaluator.evaluate()`: Because `freshness == PolicyUsageFreshness.unavailable`, `isUsageValid` evaluates to `false`.
  - `evaluateDailyQuota()`:
    ```dart
    final used = isUsageValid ? usage.totalMinutes : null; // evaluates to null
    final isUnavailable = limit != null && used == null;   // evaluates to true
    final remaining = (limit != null && used != null) ? math.max(0, limit - used) : null; // evaluates to null
    ```
- **Correction Applied:**
  - **Forbidden:** The UI must **never** display `0m used`, **never** display full quota remaining, and **never** fabricate a zero-usage percentage.
  - **Honest Presentation:**
    - Configured Limit: Displays parent-configured quota (e.g., `"2 hr daily limit"`).
    - Status Indicator: `"New day interval starting · Screen time usage unavailable"`.
    - Remaining / Used: Both are marked `"Unavailable"` (no numerical minutes rendered).
    - Non-Quota Policies: Schedules (bedtime, school hours) continue evaluating normally.

---

### 3.2 Unknown Completeness Correction
- **Source Implementation:**
  - `PolicyUsageAdapter.fromDailyResult()` line 65:
    ```dart
    totalForegroundMillis: null,
    appForegroundMillis: apps,
    completeness: PolicyUsageCompleteness.unknown,
    ```
  - Because the Stage 3 native envelope lacks full-day completeness verification, `totalForegroundMillis` is always `null` in converted daily results.
  - In `evaluateDailyQuota()`, whenever `totalForegroundMillis` is null, `used` is `null`, `remaining` is `null`, and `isUnavailable` is `true`.
- **Correction Applied:**
  - **Forbidden:**
    - Do not display a confirmed daily total.
    - Do not calculate remaining quota from an unknown total.
    - Do not display a quota progress percentage or reached/exceeded status for finite quotas.
    - **Do not use the label "Estimated Usage":** Neither the repository nor the evaluator provides an estimate; the completeness is strictly `unknown`.
  - **Exact UI Wording:**
    - Quota Card Status: `"Daily screen time total is unconfirmed by device telemetry. Quota evaluation is unavailable."`
    - Per-App Limits: When individual packages have explicit limits (e.g. YouTube $\le 30$m) and measured positive app foreground minutes are present in `usage.appForegroundMillis`, individual app limits **can** evaluate and display `AppPolicyStatus.appLimitReached` with measured minutes.

---

### 3.3 Allowed-App Semantics
- **Source Implementation:**
  - `PolicyConfig` (line 74): `final List<String> allowedApps;` is a verified, explicit collection.
  - `evaluateAppPolicy()` in `policy_evaluator_helpers.dart` (lines 74–95):
    ```dart
    // Level 5: Global Daily Screen Time Quota
    else if (dailyQuota.isReached && !context.config.allowedApps.contains(pkg)) {
      status = AppPolicyStatus.dailyLimitReached;
      reason = 'Daily limit reached';
    }
    // Level 6 & 7: Parent Whitelist Exemption or Default Permitted
    else {
      final isSched = scheduleResult.isAnyScheduleActive;
      final isWhite = context.config.allowedApps.contains(pkg);
      status = isSched ? AppPolicyStatus.scheduleAllowed : AppPolicyStatus.allowed;
      reason = isSched
          ? 'Allowed during schedule'
          : (isWhite ? 'Parent whitelist exempt' : 'Allowed');
    }
    ```
- **Correction Applied:**
  - `allowedApps` is verified in production code, but it does **not** represent a restrictive "kiosk/allowlist-only" model where all other apps are blocked.
  - Instead, its exact semantic function is: **Exemption from the Global Daily Screen Time Quota**.
  - Apps not in `allowedApps` are still permitted normally until the daily quota is reached.
  - **Exact UI Presentation:**
    - The section in `AppRestrictionsCard` must be titled:  
      **"Always Allowed (Daily Limit Exempt)"** or **"Daily Quota Exempt Apps"**.
    - Subtitle: *"These apps remain accessible even when the daily screen time limit is reached."*
    - The card must never imply that unlisted apps are blocked.

---

### 3.4 Refresh Lifecycle & Concurrency
- **Source Implementation:**
  - `ChildPolicyController.loadPolicy()`:
    - Increments `_policyGeneration` and `_evaluationGeneration`.
    - Sets `status.value = ChildPolicyStatus.loading`, `_active = null`, `activePolicy.value = null`.
    - If superseded by a newer call, discards completion (`generation != _policyGeneration`).
    - On failure, sets `_active = null`, `status.value = ChildPolicyStatus.failure`.
  - `ChildPolicyController.evaluate()`:
    - Rejects immediately if `status.value == ChildPolicyStatus.loading` or `initial` (`'policy_not_ready'`).
    - Rejects immediately if `status.value != ChildPolicyStatus.ready` or `_active == null` (`'policy_evaluation_refused'`).
    - Stale guard: checks `_isStale(evaluationId, policyGeneration)` before publishing; discards if `loadPolicy()` ran concurrently.
- **Conclusion:**
  - UI invocation of refresh is completely safe.
  - Concurrent calls cannot overlap to publish stale state.
  - Evaluation cannot run while loading.
  - Failed reload suspends evaluation automatically.
- **Exact Safe UI Refresh Sequence:**
  ```dart
  Future<void> onRefresh() async {
    final loadResult = await controller.loadPolicy();
    if (loadResult.isOk && controller.status.value == ChildPolicyStatus.ready) {
      await controller.evaluate();
    }
  }
  ```

---

### 3.5 Disclosure Wording
- **Source Implementation:**
  - `PolicyEvaluationResult.disclosure`:
    `'Policies are evaluated locally. Application blocking is not enforced on this build.'`
- **Correction Applied:**
  - **Forbidden:** No claims that blocking is active; no promises of future features (e.g. do not say "Enforcement will activate in a future update"); no delivery dates.
  - **Mandatory Disclosure Wording:**
    - Primary card: Exactly renders `evaluation.disclosure`:  
      *"Policies are evaluated locally. Application blocking is not enforced on this build."*
    - Blocked apps contextual note:  
      *"Parent rules specify these apps as blocked. Application blocking is not enforced on this build."*
    - Web restrictions contextual note:  
      *"Web restrictions are evaluated locally. Browser traffic is not filtered on this build."*
    - Downtime schedules contextual note:  
      *"Scheduled downtime window. Device lockout is not enforced on this build."*

---

## 4. Corrected Usage Presentation Matrix

| Operational State | Underlying Evaluator State | Corrected UI Presentation | Prohibited Presentation |
|---|---|---|---|
| **Exact Local Midnight** | `range.start == range.end`, `isUsageValid: false`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit set by parent"`. Status: `"New day starting · Usage unavailable at boundary"`. | **NEVER** display 0m used, full quota remaining, or 0% progress. |
| **Unknown Completeness** | `completeness == unknown`, `totalForegroundMillis: null`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit"`. Status: `"Daily total screen time is unconfirmed. Quota evaluation is unavailable."` | **NEVER** display a confirmed total or calculate remaining minutes. **NEVER** label as "Estimated Usage". |
| **Permission Denied** | `isPermissionGranted: false`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit"`. Status: `"Usage permission not granted — screen time cannot be measured"`. Includes "Open Settings" button. | **NEVER** show 0m used or claim limit is reached. |
| **Permission Unsupported** | `UsagePermissionStatus.unsupported`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit"`. Status: `"Usage tracking is unsupported on this platform"`. | **NEVER** fabricate usage numbers. |
| **Probe / Query Failure** | `usageFailure != null`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit"`. Status: `"Temporary error checking usage. Screen time check paused"`. Includes "Try again" button. | **NEVER** report quota reached. |
| **Empty Native Result** | `UsageDataFreshness.empty` -> `isUsageValid: false` | Quota card: `"${limit} min daily limit"`. Status: `"No usage recorded for today yet (unverified)"`. | **NEVER** show confirmed 0m screen time. |
| **Positive Quota, Unavailable Usage** | `limit > 0`, `dailyQuota.isUnavailable: true` | Quota card: `"${limit} min daily limit"`. Status: `"Daily screen time unverified (usage data unavailable)"`. | **NEVER** assume 0m used or limit reached. |
| **Per-App Limit Reached** | `appEval.status == AppPolicyStatus.appLimitReached` | App row: Displays package name, `"${appMinutes}m / ${limitMinutes}m limit"`, and status chip `"App Limit Reached"` (`StatusTone.bad`). | **NEVER** claim app process is terminated. |

---

## 5. Verified Policy-Field-to-Widget Mapping

| UI Presentation Widget | Input Data Fields | Rendered Output | Excluded / Prohibited |
|---|---|---|---|
| **`PolicyStatusCard`** | `record.provenance`<br>`record.policyVersion`<br>`record.updatedAt`<br>`evaluation.overallState`<br>`evaluation.primaryReason` | Provenance chip ("Neutral Fallback" / "Active Family Rules"), version badge (`v1`), updated timestamp, overall state label, plain-language reason. | Database hash, storage keys, raw JSON, parent account email. |
| **`DailyQuotaCard`** | `config.dailyScreenTimeMinutes`<br>`dailyQuota.limitMinutes`<br>`dailyQuota.isUnavailable`<br>`dailyQuota.isUnlimited`<br>`dailyQuota.isReached` | Daily limit (e.g. "2 hours"), unconfirmed/unavailable status message, neutral unlimited notice. | Fabricated used minutes, remaining time calculations from unknown totals, percentage bars. |
| **`PolicySchedulesCard`** | `config.schedules`<br>`evaluation.activeSchedules` | List of schedules (Bedtime, School) with days and hours; active indicator chip (`StatusTone.warning`) for active schedules. | Device lockout claims, screen-off promises. |
| **`AppRestrictionsCard`** | `config.blockedApps`<br>`config.appLimits`<br>`config.allowedApps`<br>`evaluation.appEvaluations` | - Blocked Apps list (`StatusTone.bad`)<br>- App Limits list (e.g. 30m limit)<br>- Daily Quota Exempt list (`StatusTone.good`)<br>- Contextual non-enforcement notice. | App store links, process kill guarantees, calling quota-exempt apps "the only allowed apps". |
| **`WebRestrictionsCard`** | `config.safeSearchEnabled`<br>`config.blockedDomains`<br>`config.allowedDomains` | - SafeSearch chip (Enabled/Disabled)<br>- Blocked domains list<br>- Allowed domains list (if non-empty)<br>- Contextual non-enforcement notice. | VPN filtering claims, network interception promises. |
| **`PolicyDisclosureCard`** | `evaluation.disclosure` | Prominent local evaluation notice with exact text from evaluator. | Future delivery promises, version roadmaps. |

---

## 6. Final 13-File Allowlist

Every file is strictly bounded to a single responsibility and guaranteed to remain **$\le 200$ physical lines**:

| File Path | Type | Action | Estimated Physical Lines ($\le 200$) |
|---|---|---|---|
| `apps/haven_child/lib/app/routes/child_routes.dart` | Existing | Add `policy = '/policy'` constant | ~25 lines |
| `apps/haven_child/lib/app/routes/child_pages.dart` | Existing | Add `GetPage(name: ChildRoutes.policy, page: () => const ChildPolicyPage())` | ~75 lines |
| `apps/haven_child/lib/features/profile/views/pages/profile_page.dart` | Existing | Add "Rules & Limits" navigation card | ~160 lines |
| `apps/haven_child/lib/features/policies/views/child_policy_page.dart` | New Page | Main page shell (`ChildScaffold`, refresh, state dispatcher) | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_status_card.dart` | New Widget | Provenance chip, version, updated time, overall state | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/daily_quota_card.dart` | New Widget | Quota limit & honest unconfirmed usage notice | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_schedules_card.dart` | New Widget | Downtime schedules & active indicators | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/app_restrictions_card.dart` | New Widget | Blocked apps, app limits, and quota-exempt apps | ~150 lines |
| `apps/haven_child/lib/features/policies/views/widgets/web_restrictions_card.dart` | New Widget | Domain lists, SafeSearch chip, and non-enforcement note | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_disclosure_card.dart` | New Widget | Mandatory local evaluation disclosure | ~70 lines |
| `apps/haven_child/test/features/policies/child_policy_page_test.dart` | New Test | Page integration test across loading, ready, and failure | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_widgets_test.dart` | New Test | Unit tests for cards, midnight, and unconfirmed states | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_navigation_test.dart` | New Test | Route transition tests from Profile to Policy and back | ~140 lines |

---

## 7. Recommended Owner Decisions

1. **Approve Exact-Midnight Presentation:** Confirm that at exact local midnight, the UI displays `"New day starting · Screen time usage unavailable at boundary"` and does not display `0m used` or full quota remaining.
2. **Approve Unknown Completeness Presentation:** Confirm that when daily screen time completeness is unknown, the UI displays `"Daily total screen time is unconfirmed. Quota evaluation is unavailable"` and never fabricates totals or labels it "Estimated Usage".
3. **Approve Allowed-App Presentation:** Confirm that `allowedApps` is displayed under the verified title `"Always Allowed (Daily Limit Exempt)"` to accurately communicate its exemption from daily quotas.
4. **Approve Refresh Lifecycle:** Confirm the safe refresh sequence (`loadPolicy()` followed by `evaluate()` when ready) using only existing approved APIs.
5. **Approve Exact Disclosure Wording:** Confirm the exact disclosure text from `PolicyEvaluationResult.disclosure` and contextual non-enforcement notes without future delivery promises.
6. **Approve 13-File Scope:** Authorize implementation of the exact 3 modified files, 7 new presentation widgets, and 3 new test files.

---

## 8. Explicit Implementation Exclusions

- **Zero Policy Mutation / Editing:** Child cannot create, edit, or delete policy rules.
- **Zero Remote Sync:** No backend sync, HTTP calls, Supabase subscriptions, or network polling.
- **Zero Native OS Enforcement:** No background services, DevicePolicyManager bindings, accessibility services, or app blocking.
- **Zero Controller or Repository Changes:** `ChildPolicyController`, `PolicyUsageAdapter`, and `LocalChildPolicyRepository` remain untouched.
- **Zero Evaluator Changes:** `PolicyEvaluator` and `haven_models` remain untouched.

---

## 9. Mandatory Stop State

- **Current Status:** Final UI contract consistency review complete.
- **Repository Integrity:** Strictly preserved in READ-ONLY mode. Zero code or test changes.
- **Report Location:** `docs/testing/stage_4_step_4_substep_4_3_final_ui_contract_review.md` (untracked, unstaged).
- **Next Step:** Await explicit owner decision and formal implementation authorization.
