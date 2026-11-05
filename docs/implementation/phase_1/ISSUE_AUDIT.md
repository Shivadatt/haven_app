# HAVEN PARENTAL CONTROL — PHASE 1 DEEP ISSUE AUDIT

**Environment**: Flutter 3.44.6 • Dart 3.12.2 (via FVM)  
**Root Path**: `D:\control`  
**Audit Scope**: Phase 1 Core Parent App Offline Foundation & Functionality  
**Status**: Completed & Verified  

---

## 1. Executive Summary

An independent, rigorous line-by-line audit and stabilization sweep was conducted across the Phase 1 Core Parent App offline implementation. The investigation verified environment health, Dart syntax correctness, offline storage reliability, GetX reactive state management, line-count constraints, and isolation from cloud services.

A total of **8 issues** were discovered, analyzed, categorized by severity (P0–P3), and resolved with regression tests.

---

## 2. Discovered Issues Catalog

### Issue ISS-001: 912 Dart Analysis Errors Caused by Underscore-Prefixed Named Parameters
- **Location**: 45 source files across `apps/haven_app/lib` (25 controllers, 20 repository adapters)
- **Severity**: **P0 (Blocker)**
- **Expected Behavior**: Controllers and repositories must compile cleanly without `private_optional_parameter` compiler errors.
- **Actual Behavior**: Parameter declarations used `required this._repository`, which is illegal in Dart 3 named parameters (`Named parameters can't start with an underscore`). This caused 912 cascade compilation errors in VS Code and blocked code navigation.
- **Evidence**: `fvm flutter analyze` failed with 912 errors in `initial_bindings.dart`, `account_bindings.dart`, `account_controller.dart`, etc.
- **Resolution**: **Fixed**. Refactored all 45 files to standard Dart public named parameters (`required RepositoryType repository`) with initializer lists (`: _repository = repository`).
- **Regression Test**: `fvm flutter analyze` runs in 6.5s with **0 issues found**.

---

### Issue ISS-002: Incomplete Forward-Uniqueness Validation on Row Updates
- **Location**: `packages/haven_api/lib/src/offline/local_tables.dart` (lines 104–114)
- **Severity**: **P1 (Data Integrity)**
- **Expected Behavior**: When updating an existing row, the prospective row must be validated against all other rows in the table to prevent duplicate unique/composite-unique records.
- **Actual Behavior**: `LocalTables.update` validated candidate rows against `rebuilt`, which only contained rows traversed *prior* to the updated row. If the first row was updated to collide with a later row (e.g. renaming Safe Zone 1 to match existing Safe Zone 2), `rebuilt` was empty and the collision went undetected, creating duplicate rows in persistent storage.
- **Evidence**: Updating Row 0 in a 2-row table containing `{Home, School}` to `{School, School}` succeeded without error.
- **Resolution**: **Fixed**. Modified `LocalTables.update` to collect all matching indices, assemble prospective table rows, and validate each candidate against all other rows (`j != i`) prior to committing.
- **Regression Test**: `packages/haven_api/test/offline/stabilization_regression_test.dart` (`updating the first row to conflict with a subsequent row is refused`).

---

### Issue ISS-003: Demo Seeding Collided with Active User Profile and Demo Clear Deleted It
- **Location**: `packages/haven_api/lib/src/offline/demo_data_records.dart` (lines 41–47)
- **Severity**: **P1 (Data Integrity)**
- **Expected Behavior**: When an authenticated parent loads demo data from the dashboard, their real user profile must be preserved and must never receive demo flags or be deleted during demo reset.
- **Actual Behavior**: `DemoDataRecords.seed()` unconditionally executed `insert(TableName.profiles, {'id': parentId, 'is_demo': true})`. When `parentId` was an existing user profile, this either failed due to primary key conflict or marked the user's authentic profile as demo data. Subsequent calls to `clearDemoData()` then wiped the parent's actual profile.
- **Evidence**: Loading demo data while signed in failed or marked the parent profile with `is_demo = true`.
- **Resolution**: **Fixed**. Added conditional check: only insert demo profile when `parentId == demoParentUserId`. Authentic user profiles are left intact without demo tags.
- **Regression Test**: `packages/haven_api/test/offline/stabilization_regression_test.dart` (`seeding demo data preserves user profile and does not mark it as demo`).

---

### Issue ISS-004: Full Reset (`resetAllData`) Left Stale Onboarding & Policy Preferences
- **Location**: `apps/haven_app/lib/features/settings/data/settings_repository.dart` (lines 171–178)
- **Severity**: **P1 (State Integrity)**
- **Expected Behavior**: `resetAllData()` must completely return the application to initial state, wiping all tables and resetting all stored preferences.
- **Actual Behavior**: `resetAllData()` cleared `LocalTables` but left `PreferencesStore` with `onboardingCompleted: 'true'`, `onboardingStep: 'device'`, `onboardingEthicsAcknowledged: 'true'`, `policyConfig`, and `parentDisplayName`.
- **Evidence**: After a full reset, restarting or navigating resulted in out-of-sync onboarding and policy state.
- **Resolution**: **Fixed**. Added explicit preference cleanup for all onboarding keys, policy configuration, and parent display name in `HavenSettingsRepository.resetAllData()`.
- **Regression Test**: `apps/haven_app/test/offline/phase1_stabilization_test.dart` (`resetAllData clears all local tables and onboarding preferences`).

---

### Issue ISS-005: Child Profile Age Bracket Field Discrepancy (`age_group` vs `age_bracket`)
- **Location**: `apps/haven_app/lib/features/onboarding/data/local_onboarding_repository.dart` (line 136)
- **Severity**: **P2 (Data Consistency)**
- **Expected Behavior**: Child profile created during onboarding must populate `age_bracket` as expected by `Profile.fromRow` in `haven_models`.
- **Actual Behavior**: Onboarding inserted `'age_group': ageGroup`, while `Profile.fromRow` looked for `'age_bracket'`. As a result, `Profile.ageBracket` was `null` when read back.
- **Evidence**: Inspection of `Profile.fromRow` in `packages/haven_models/lib/src/family_models.dart`.
- **Resolution**: **Fixed**. Updated `LocalOnboardingRepository.createChild` to write both `'age_bracket': ageGroup` and `'age_group': ageGroup`.
- **Regression Test**: `apps/haven_app/test/offline/phase1_stabilization_test.dart` (`LocalOnboardingRepository writes age_bracket for Profile model parity`).

---

### Issue ISS-006: Lack of Composite Unique Constraint on Family Members
- **Location**: `packages/haven_api/lib/src/offline/local_schema.dart` (line 62)
- **Severity**: **P2 (Schema Integrity)**
- **Expected Behavior**: A user cannot be added to the same family more than once.
- **Actual Behavior**: `TableName.familyMembers` had no `uniqueComposites` declared, allowing duplicate membership records for the same `(family_id, user_id)`.
- **Evidence**: `LocalConstraints` skipped duplicate membership validation.
- **Resolution**: **Fixed**. Added `uniqueComposites: [[familyIdColumn, 'user_id']]` to `TableName.familyMembers` rule in `LocalSchema.defaults`.
- **Regression Test**: `packages/haven_api/test/offline/stabilization_regression_test.dart` (`inserting the same user into the same family twice is refused`).

---

### Issue ISS-007: Rapid Activity Logging Generated Duplicate IDs
- **Location**: `apps/haven_app/lib/features/device_activity/data/local_activity_repository.dart` (lines 147, 155)
- **Severity**: **P2 (Robustness)**
- **Expected Behavior**: Logging rapid activity events sequentially must generate distinct primary keys.
- **Actual Behavior**: IDs used `'alert_${DateTime.now().millisecondsSinceEpoch}'`. Sequential calls in the same millisecond collided and threw primary key violations.
- **Evidence**: Rapid loop of `logActivityEvent` threw `local_unique_violation`.
- **Resolution**: **Fixed**. Switched to `'alert_${LocalIds.create()}'` and `'loc_${LocalIds.create()}'`.
- **Regression Test**: `apps/haven_app/test/offline/phase1_stabilization_test.dart` (`consecutive activity events have unique non-colliding IDs`).

---

### Issue ISS-008: Fallback Device Schema Inconsistency in Policies Repository
- **Location**: `apps/haven_app/lib/features/policies/data/local_policies_repository.dart` (line 175)
- **Severity**: **P2 (Schema Integrity)**
- **Expected Behavior**: Auto-created fallback devices must conform to the `Device` model schema.
- **Actual Behavior**: Inserted `'device_type': 'android'` instead of `'platform': 'android'`, and omitted `installation_id`, `child_user_id`, `enforcement_mode`, and `policy_version`.
- **Evidence**: `Device.fromRow` returned empty string `""` for platform.
- **Resolution**: **Fixed**. Corrected column name to `platform: 'android'` and included all mandatory schema fields.
- **Regression Test**: `apps/haven_app/test/offline/phase1_stabilization_test.dart` (`fallback device contains platform: android and valid fields`).

---

## 3. Severity Distribution

| Severity | Count | Status |
| :--- | :--- | :--- |
| **P0 (Blocker)** | 1 | Fixed & Verified |
| **P1 (Critical / Data Integrity)** | 3 | Fixed & Verified |
| **P2 (Major / Schema & Consistency)** | 4 | Fixed & Verified |
| **P3 (Minor / Trivial)** | 0 | None remaining |
| **Total** | **8** | **100% Fixed** |

