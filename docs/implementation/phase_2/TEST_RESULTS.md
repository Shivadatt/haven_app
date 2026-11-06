# HAVEN PARENTAL CONTROL — PHASE 2 TEST RESULTS

**Test Suite Execution Date**: November 5, 2026 (Phase 2 delivery) — independently re-executed November 6, 2026 (final verification)  
**Phase 2 Baseline (re-verified)**: 990 / 990 (100% Pass Rate) — `apps/haven_app` 924 + `packages/haven_api` 66  
**Repository-Wide Total (incl. `haven_core` + `haven_models`)**: 1020 / 1020  
**Static Analysis Result**: 0 Issues (`fvm flutter analyze`, exit code 0, "No issues found!")  
**Architecture Line Rule**: 615 Hand-Written Source Files Scanned, 0 Violations ($\le 200$ Lines)  
**SDK Used For Verification**: FVM-pinned Flutter 3.44.6 stable / Dart 3.12.2 (analyzer suite) — all evidence logs under `_scratch/p2v_agentA/`, `_scratch/p2v_agentB/`, `_scratch/p2v_agentC/`

---

## 1. Test Execution Breakdown

| Suite | Package / App | Total Tests | Passed | Failed | Skipped | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Haven Parent App** | `apps/haven_app` | 924 | 924 | 0 | 0 | **PASS** |
| **Haven API Package** | `packages/haven_api` | 66 | 66 | 0 | 0 | **PASS** |
| **Phase 2 Baseline Subtotal** | Reported 990-test baseline | **990** | **990** | **0** | **0** | **PASS** |
| **Haven Core Package** | `packages/haven_core` | 18 | 18 | 0 | 0 | **PASS** |
| **Haven Models Package** | `packages/haven_models` | 12 | 12 | 0 | 0 | **PASS** |
| **Total Test Suite** | Repository Combined | **1020** | **1020** | **0** | **0** | **PASS** |

---

## 2. Key Phase 2 Test Suites Added

1. **Authentication Widget Suite** ([`auth_pages_widget_test.dart`](file:///d:/control/apps/haven_app/test/authentication/auth_pages_widget_test.dart)):
   - `ForgotPasswordPage` recovery form rendering and empty email validation.
   - Offline recovery note display and route transition.
   - `ResetPasswordPage` password mismatch validation and secure vault update.
   - `VerifyEmailPage` metadata display, resend verification simulation, and layout responsiveness.
   - **Final verification (Nov 6, 2026)**: run in isolation — 4/4 passed, 0 failed, 0 skipped. These 4 tests were already included in the 990 baseline (not pending/excluded); no double-counting. Supplementary controller tests for the same pages: 10/10 passed (also within the 924).

2. **Family Management Widget Suite** ([`family_pages_widget_test.dart`](file:///d:/control/apps/haven_app/test/family/family_pages_widget_test.dart)):
   - `ChildCreatePage` name validation, age bracket selection, and avatar picker.
   - `FamilyInvitePage` role dropdown, invite dispatch, and pending invitations list rendering.

3. **Policies & Restrictions Widget Suite** ([`policies_advanced_widgets_test.dart`](file:///d:/control/apps/haven_app/test/policies/policies_advanced_widgets_test.dart)):
   - `AppLimitsPage` catalogue browsing, daily minute limit display, and local disclaimer banner.
   - `AppRulesPage` segmented view toggles (Allowed vs Blocked).
   - `WebFilterPage` SafeSearch switch toggle and domain filter segments.

4. **Approvals Workflow Widget Suite** ([`approvals_pages_widget_test.dart`](file:///d:/control/apps/haven_app/test/approvals/approvals_pages_widget_test.dart)):
   - `AppApprovalsPage` tab switching across Pending, Approved, and Rejected requests.
   - `ExtensionRequestsPage` extension durations, reason display, and history records.

5. **Help Centre & Support Widget Suite** ([`help_pages_widget_test.dart`](file:///d:/control/apps/haven_app/test/help/help_pages_widget_test.dart)):
   - `HelpCenterPage` search bar, category chips, and article dialog opening.
   - `FaqPage` question expansion and keyword search.
   - `ContactSupportPage` offline support banner, form submission, and draft saving.

6. **Existing Phase 1 Regression Suites**:
   - `phase1_stabilization_test.dart` (Full suite passing)
   - `stabilization_regression_test.dart` (Full suite passing)
   - `local_constraints_test.dart` & `local_tables_test.dart` (Full suite passing)
   - **Confirmed intact on Nov 6, 2026** — all appear green inside the fresh 924-test `haven_app` run and the 66-test `haven_api` run.

---

## 3. Final Verification Execution Record (November 6, 2026)

| Command | Working Directory | Exit Code | Duration | Result |
| :--- | :--- | :--- | :--- | :--- |
| `fvm flutter test test/authentication/auth_pages_widget_test.dart` | `apps/haven_app` | 0 | ~3 s test run | 4 passed / 0 failed / 0 skipped |
| `fvm flutter test test/authentication/forgot_password_controller_test.dart test/authentication/reset_password_controller_test.dart test/authentication/verify_email_controller_test.dart` | `apps/haven_app` | 0 | 13.6 s | 10 passed / 0 failed |
| `fvm flutter analyze` | `D:\control` | 0 | 31.5 s wall (analyzer: 26.3 s) | "No issues found!" — 0 issues |
| `fvm flutter test` | `apps/haven_app` | 0 | 2 m 33 s | 924 passed / 0 failed / 0 skipped |
| `fvm flutter test` | `packages/haven_api` | 0 | 38.4 s | 66 passed / 0 failed / 0 skipped |
| `fvm flutter test` | `packages/haven_core` | 0 | 11.7 s | 18 passed / 0 failed |
| `fvm flutter test` | `packages/haven_models` | 0 | 11.2 s | 12 passed / 0 failed |
| `dart scripts/check_line_counts.dart` | `D:\control` | 0 | — | 615 files scanned, 0 violations |

Full output logs: `D:\control\_scratch\p2v_agentA\` and `D:\control\_scratch\p2v_agentB\`.

