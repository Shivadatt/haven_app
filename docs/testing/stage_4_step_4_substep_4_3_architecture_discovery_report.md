# HAVEN PARENT CONTROL — STAGE 4, STEP 4, SUB-STEP 4.3
## UI & Navigation Integration — Architecture Discovery, Independent Review & Owner Approval Preparation

**Repository:** `D:\control`  
**Branch:** `main`  
**Baseline HEAD:** `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2`  
**Execution Mode:** STRICT READ-ONLY ARCHITECTURAL AUDIT  
**Status:** Audit Completed — Awaiting Owner Approval  

---

## 1. Executive Summary & Final Verdict

### Final Readiness Verdict
# **A — ARCHITECTURE READY FOR OWNER APPROVAL**

**The existing child application architecture, GetX reactive-state hierarchy, and `ChildPolicyController` bindings fully support a clean, modular, and strictly read-only UI and navigation integration plan without requiring any changes to underlying domain, evaluator, or repository code.**

### Summary of Findings
1. **Controller Readiness:** `ChildPolicyController` is already permanently registered at storage boot in `ChildInitialBindings._openAndRegister`. It requires zero additional service locator setup or secondary binding abstractions (satisfying Decision 2B).
2. **Read-Only Guarantees:** Neither `ChildPolicyController` nor `ChildPolicyRepository` exposes any mutation or write APIs (`savePolicy`, `updatePolicy`, etc.). The UI can observe state reactively via `Obx` without any risk of mutating parent-managed policy.
3. **Route Extensibility:** `ChildRoutes` and `ChildPages` explicitly provide the extension point for `/policy`, mirroring the established `/usage` and `/permissions` navigation precedents.
4. **Transparent Policy Presentation:** All required UI presentation states (neutral in-memory fallback, parent-synced rules, downtime schedules, per-app limits, web filters, and failure diagnostics) are cleanly supported by existing model fields on `ChildPolicyRecord` and `PolicyEvaluationResult`.
5. **No Scope Creep:** The proposed implementation is strictly confined to presentation widgets, route registration, and navigation links from the child profile home, with all files designed to remain under the mandatory 200-physical-line ceiling.

---

## 2. Mandatory Preflight Inspection

| Item | Expected | Actual | Status |
|---|---|---|---|
| **Repository Root** | `D:\control` | `D:/control` | **PASS** |
| **Current Branch** | `main` | `main` | **PASS** |
| **Baseline HEAD** | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2` | **PASS** |
| **Index / Working Tree** | Clean tracked files | 3 staged documentation reports from previous audits, 0 unstaged modifications, 0 untracked files | **PASS** |

The baseline HEAD exactly matches `b396ca7a904dc1db8f5b70b4c2a07cb315bdeed2`. All user work and historical audit documentation are fully preserved.

---

## 3. Authoritative Architectural Baseline Conformance

Sub-step 4.3 adheres to all approved Sub-step 4.2 decisions and core platform constraints:

| Approved Decision | Technical Contract | Sub-step 4.3 UI Integration Posture |
|---|---|---|
| **1A: Dedicated Controller** | `ChildPolicyController` owns active policy and evaluates rules | The UI consumes `ChildPolicyController` directly via `Get.find<ChildPolicyController>()` and `Obx`. |
| **2B: Direct Registration** | Registered directly in `ChildInitialBindings`; no `ChildPolicyBindings` | No `ChildPolicyBindings` will be created. Route `/policy` resolves the existing permanent controller. |
| **3A: Stable Detail Codes** | `UnknownFailure` with stable lifecycle detail codes | The UI inspects `UnknownFailure.detail` (`'policy_not_ready'`, `'policy_evaluation_refused'`, `'policy_controller_disposed'`) to render exact, honest user messages. |
| **4A: Fresh-Query Evaluation** | Fresh usage acquisition per evaluation; no caching | The UI triggers fresh evaluation on pull-to-refresh or page focus without client-side caching. |

### Enforced Platform Constraints:
- **No Evaluation during Initial / Loading:** UI renders calm loading view; evaluation is not attempted while status is `initial` or `loading`.
- **Unlimited Quota on Neutral Policy:** When `record.provenance == PolicyProvenance.inMemoryNeutral`, UI indicates "Neutral / Unpaired Policy" and displays unlimited daily quota without restriction warnings.
- **Failed Reload Suspends Evaluation:** On reload failure, UI renders a warning banner explaining that policy evaluation is suspended. It displays the previous valid policy version for diagnostics only, never as active rules.
- **No Stale or Neutral Evaluation:** The UI never calculates or displays simulated "fallback" allowances when an active policy reload fails.
- **Strictly Read-Only:** Zero child-side policy edit controls, sliders, override buttons, or sync APIs.
- **Fresh Context & Usage:** Evaluations display the freshly returned `PolicyEvaluationResult`.
- **Unknown Usage Completeness:** When `usageCompleteness == PolicyUsageCompleteness.unknown`, daily screen time is explicitly labeled as unconfirmed/estimated and never shown as a confirmed total.
- **Exact Midnight:** When evaluated at midnight, screen time displays 0m elapsed without presenting an error.

---

## 4. UI & Navigation Architecture Discovery

### A. Application Structure
- **Entry Point:** `apps/haven_child/lib/main.dart` initializes Flutter bindings, reads `ChildConfig` from environment defines, and invokes `runApp(ChildApp(config: config))`.
- **Root Widget:** `apps/haven_child/lib/app/app.dart` defines `ChildApp`, setting up `GetMaterialApp` with:
  - Theme: `ChildTheme.light` and `ChildTheme.dark`
  - Initial Route: `ChildRoutes.splash`
  - Initial Binding: `ChildInitialBindings`
  - Routes Table: `ChildPages.pages`
  - Unknown Route: `ChildPages.unknown`
- **Route Table:** `apps/haven_child/lib/app/routes/child_routes.dart` and `child_pages.dart` define named routes:
  - `/splash` (`SplashPage`)
  - `/onboarding` (`OnboardingPage`)
  - `/profile` (`ProfilePage`)
  - `/device` (`DevicePage`)
  - `/permissions` (`PermissionsPage`)
  - `/usage` (`ChildUsagePage`)
  - `/unknown` (`UnknownPage`)
- **Dependency Lifecycle (`ChildInitialBindings`):**
  - Synchronous startup registers honest platform readers (`ChildConfig`, `DeviceInformation`, `PermissionStatusSource`).
  - Asynchronous startup (`startStorage()`) opens `ChildDatabase` and permanently binds `ChildProfileRepository`, `OnboardingStateStore`, `ChildSessionStore`, `ChildUsageRepository`, `ChildPolicyRepository`, and `ChildPolicyController`.
- **Identity & Authentication Lifecycle:**
  - Local-first design without remote authentication credentials on the child device.
  - Setup completeness is determined by `ChildLocalSession` referencing a valid `Profile` in local storage.
  - `SplashController` verifies this pairing; if complete, it navigates to `/profile`, otherwise to `/onboarding`.

### B. Existing Screens Inventory
| Screen Purpose | Existing Source Path | Current Behavior & Navigation |
|---|---|---|
| **Child Home / Dashboard** | `apps/haven_child/lib/features/profile/views/pages/profile_page.dart` | Displays child avatar, display name, age bracket, parent connection status, device info button, and permissions button. **Lacks policy visibility.** |
| **Usage Information** | `apps/haven_child/lib/features/child_usage/views/child_usage_page.dart` | Displays daily screen time and per-app usage list. Navigated to from `PermissionCard` on the permissions page. |
| **Permission Dashboard** | `apps/haven_child/lib/features/permissions/views/pages/permissions_page.dart` | Lists capabilities (Usage Access, Notifications, etc.) and explanations. |
| **Device Information** | `apps/haven_child/lib/features/device/views/pages/device_page.dart` | Displays hardware/OS facts. |
| **Parent-Managed Policy Visibility** | **DOES NOT EXIST** | No screen or widget currently exposes `ChildPolicyController` or active policy rules. |
| **App & Website Restrictions** | **DOES NOT EXIST** | Not present anywhere in the child app. |
| **Daily Screen Time Limits** | **DOES NOT EXIST** | `ChildUsagePage` displays *measured usage*, but does not display *policy limits* or *allowances*. |
| **Policy Loading & Error States** | **DOES NOT EXIST** | Not present. |

### C. Controller Integration Feasibility
- `ChildPolicyController` is already a `GetxController` registered as `permanent: true`.
- It exposes reactive observables:
  - `status`: `Rx<ChildPolicyStatus>` (`initial`, `loading`, `ready`, `failure`)
  - `activePolicy`: `Rxn<ChildPolicyRecord>`
  - `policyFailure`: `Rxn<HavenFailure>`
  - `lastEvaluation`: `Rxn<PolicyEvaluationResult>`
- Any child view can safely observe these via `Obx` without subscribing to manual streams or risking memory leaks.
- Because `ChildPolicyController` does not implement any write or mutation methods, observing it gives the UI zero capability to alter policy state.

---

## 5. Required UI State Contract

The UI must implement an honest, predictable presentation contract across all 13 possible operational states:

| State | UI Presentation Contract | Prohibited Elements | User Action / Next Step |
|---|---|---|---|
| **1. Initial / Loading** | Calm spinner, "Reading device rules...", `ChildScaffold` with title "Family Rules". | Stale data, error banners, mock rules. | None (automatic load). |
| **2. Ready (Neutral Fallback)** | StatusChip: "Neutral Rules" (`neutral`), headline: "Device Not Paired", disclosure: "No parent rules set. Full access permitted." | Fabricated limits, sync failure warnings. | Link to Pairing / Setup if incomplete. |
| **3. Ready (Parent Synced)** | StatusChip: "Active Rules" (`good`), Policy Version `v{version}`, updated timestamp. Displays daily quota, downtime schedules, app limits, and web filter summary. | Raw JSON, internal hashes, parent email/account data. | Pull-to-refresh (`evaluate()` / `loadPolicy()`). |
| **4. Reload in Progress** | Inline subtle progress indicator (e.g. app bar spinner or `RefreshIndicator`), keeping existing view visible. | Screen flickering, full-page blocking loader. | Wait for reload. |
| **5. Reload Failure (Diagnostics)** | Warning banner: "Rules Check Failed — Evaluation Suspended". Diagnostic note: "Last verified version: v{version}". | Presenting previous rules as actively evaluating. | "Try again" button calling `loadPolicy()`. |
| **6. Refused (Not Ready)** | Informational note: "Rules are being loaded. Please try again in a moment." | False claim of policy violation or device block. | Automatic or manual retry. |
| **7. Refused (Disposed)** | Safe unmount or fallback message: "Screen closed". | Crash, null pointer exception, stale memory read. | Navigate back. |
| **8. Usage Permission Denied** | Notice: "Usage Permission Required to calculate screen time limits". Quota card shows configured limit but marks usage "Unavailable". | Presenting usage as 0 minutes or assuming quota is intact. | "Open Settings" action button. |
| **9. Usage Unsupported** | Notice: "Usage measurement is not supported on this platform." Quota evaluation marked "Platform Unsupported". | Presenting false usage numbers. | Read-only informative display. |
| **10. Permission Probe / Query Failure** | Notice: "Temporary error reading usage data. Rules remain active." | Blaming user, altering rule thresholds. | "Refresh" action button. |
| **11. Exact Local Midnight** | Elapsed time shows "0m / {quota}", status indicates "New day starting". | Error banner, negative remaining time. | Automatic refresh as day progresses. |
| **12. Unknown Usage Completeness** | Daily screen time displayed with badge: "Estimated Usage (Unconfirmed Total)". | Displaying estimated usage as confirmed total. | Informational notice on data completeness. |
| **13. Positive Quota, Usage Unavailable** | Shows: "{quotaMinutes} min daily limit (Usage data unavailable)". | Stating quota is reached or quota is safe. | Informational card explaining measurement requirement. |

---

## 6. Security & Access-Control Review

1. **Child vs. Parent Application Boundaries:**
   - The child application codebase (`apps/haven_child`) is entirely decoupled from the parent application (`apps/haven_app`).
   - No parent-only routes, administrative configuration screens, or master PIN/password overrides exist or will be introduced in `haven_child`.
2. **Read-Only Information Model:**
   - The child UI provides **transparency without configuration**. The child has the right to understand what boundaries apply to their device (screen time limits, bedtimes, restricted apps), which fosters healthy family expectations.
   - The child UI will contain zero edit controls, sliders, time extenders, or deletion buttons.
3. **Repository Isolation:**
   - The UI communicates strictly with `ChildPolicyController`.
   - `ChildPolicyController` only holds a reference to `ChildPolicyRepository`, which exposes only `getPolicy()`.
   - The storage layer's `savePolicy` method is internal to repository persistence and is completely inaccessible from the UI layer.
4. **Lifecycle Failure Containment:**
   - If a policy reload fails, the UI strictly reflects that evaluation is suspended. It never fabricates fallback rules or retains stale rules as currently active.

---

## 7. Proposed Implementation Scope

To maintain modularity and strictly adhere to the **$\le 200$ physical line ceiling**, the proposed implementation is decomposed into focused, single-responsibility files:

### Existing Files to Modify (3 files)

| File Path | Type | Responsibility & Reason for Modification | Expected Lines |
|---|---|---|---|
| `apps/haven_child/lib/app/routes/child_routes.dart` | Existing | Add `static const String policy = '/policy';` to the official route table. | ~25 lines (well below 200) |
| `apps/haven_child/lib/app/routes/child_pages.dart` | Existing | Add `GetPage(name: ChildRoutes.policy, page: () => const ChildPolicyPage())` to the pages list. | ~75 lines (well below 200) |
| `apps/haven_child/lib/features/profile/views/pages/profile_page.dart` | Existing | Add navigation entry ("Family Rules" card / button) and wire it to navigate to `ChildRoutes.policy`. | ~160 lines (well below 200) |

### New Files to Create (7 files)

| File Path | Type | Responsibility | Expected Lines |
|---|---|---|---|
| `apps/haven_child/lib/features/policies/views/child_policy_page.dart` | New Page | Main policy view with `ChildScaffold`, refresh action, and state dispatcher. | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_status_card.dart` | New Widget | Renders policy provenance chip, version, updated time, and overall evaluation status. | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/daily_quota_card.dart` | New Widget | Renders daily screen time allowance, used/remaining time, and unavailable/unconfirmed warnings. | ~150 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_schedules_card.dart` | New Widget | Renders downtime schedules (bedtime, school hours) with active badges. | ~140 lines |
| `apps/haven_child/lib/features/policies/views/widgets/app_restrictions_card.dart` | New Widget | Renders read-only list of blocked apps, allowed apps, and per-app limits. | ~150 lines |
| `apps/haven_child/lib/features/policies/views/widgets/web_restrictions_card.dart` | New Widget | Renders web filtering status (blocked domains, allowed domains, SafeSearch chip). | ~130 lines |
| `apps/haven_child/lib/features/policies/views/widgets/policy_disclosure_card.dart` | New Widget | Renders the mandatory local evaluation disclosure (`PolicyEvaluationResult.disclosure`). | ~70 lines |

### Test Scope (3 new test files)

| File Path | Target Under Test | Test Responsibilities | Expected Lines |
|---|---|---|---|
| `apps/haven_child/test/features/policies/child_policy_page_test.dart` | `ChildPolicyPage` | Verifies full page rendering across loading, neutral ready, parent-synced ready, and reload failure states. | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_widgets_test.dart` | Policy Cards | Unit tests for quota card, schedules card, app restrictions, and web restrictions cards. | ~180 lines |
| `apps/haven_child/test/features/policies/child_policy_navigation_test.dart` | Route Navigation | Verifies navigation from `ProfilePage` to `/policy` and back, deep linking, and unknown route handling. | ~140 lines |

---

## 8. Explicit Exclusions

The following areas are **strictly excluded** from Sub-step 4.3:
1. **No Policy Mutation / Editing:** Zero editing widgets, time-request buttons, or rule bypass switches.
2. **No Remote Backend / Sync:** No Supabase Realtime, polling services, or cloud sync integration (deferred to Stage 5+).
3. **No Native OS Enforcement:** No background Android services, DevicePolicyManager bindings, accessibility services, or app killing logic (deferred to Stage 5).
4. **No Core Domain / Evaluator Changes:** No modifications to `haven_models`, `PolicyEvaluator`, or `PolicyEvaluationContext`.
5. **No Controller / Adapter Modifications:** `ChildPolicyController` and `PolicyUsageAdapter` are verified complete and will not be altered.
6. **No Storage Schema Changes:** Local SQLite/document storage schema remains unchanged.

---

## 9. Comprehensive Testing Strategy

- **Test Infrastructure:**
  - Standard `flutter_test` with `GetMaterialApp` harness.
  - Handwritten test fakes only (`FakeChildPolicyRepository`, `FakeChildUsageRepository`).
  - Strict prohibition against `mockito` or `mocktail`.
- **Scenarios to Test:**
  1. **Route & Navigation:** Verifies `Get.toNamed(ChildRoutes.policy)` resolves `ChildPolicyPage` and verifies back-navigation to `/profile`.
  2. **Reactive State Transitions:** Tests UI transitions from `initial` -> `loading` -> `ready` upon controller emissions.
  3. **Neutral vs. Parent-Synced Display:** Verifies neutral policy renders "Neutral Rules" without error, and parent-synced policy displays correct version and rules.
  4. **Quota Unavailable & Unknown Completeness:** Verifies unconfirmed usage displays explicit estimation disclaimer rather than 0m.
  5. **Reload Failure Handling:** Verifies failure banner displays and evaluation suspension notice is visible.
  6. **Disposal & Lifecycle:** Ensures widget unmounts cleanly without throwing `GetX` reactive errors.
  7. **Accessibility & Responsive Layout:** Tests scrolling on narrow viewports (320px width) using `ChildPageBody`.

---

## 10. Risks & Unresolved Decisions for Owner Alignment

| Risk / Alignment Item | Description | Proposed Architecture Solution | Owner Decision Needed? |
|---|---|---|---|
| **Profile Screen Real Estate** | Adding policy navigation to the existing Profile screen. | Add a dedicated "Rules & Limits" card below "Capabilities" on `ProfilePage`. | **Decision 1 (Recommended: Approve Profile card entry)** |
| **Navigation Path to Policy** | Should Policy be accessible from Profile only, or also linked from Usage? | Primary navigation from Profile; secondary informational link from `ChildUsagePage` when daily limit applies. | **Decision 2 (Recommended: Profile primary)** |
| **App Name Resolution** | Policies store package names (`com.example.app`); human-readable app titles are not yet in storage. | Display package name formatted cleanly, with an icon indicator. | **Decision 3 (Recommended: Clean package format)** |

---

## 11. Recommended Owner Decisions

1. **Approve Sub-step 4.3 Scope:** Authorize implementation of the 3 existing file updates and 7 new presentation files as detailed in Section 7.
2. **Approve Profile Navigation Entry:** Authorize adding the "Rules & Limits" card to `ProfilePage` as the primary entry point to `ChildRoutes.policy`.
3. **Confirm Line-Count & Formatting Guardrails:** Confirm all files must remain $\le 200$ physical lines and pass standard Dart formatting.

---

## 12. Final Status & Mandatory Stop State

- **Current Status:** Investigation and architectural review complete.
- **Repository Integrity:** Strictly preserved. Zero source, test, or config files modified.
- **Next Step:** Awaiting formal owner review and approval of this Sub-step 4.3 Architecture Discovery Report before any implementation begins.
