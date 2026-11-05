# HAVEN PARENTAL CONTROL — PHASE 1 ISSUE FIX REPORT

**Date**: November 5, 2026  
**Project**: HAVEN Parental Control (`D:\control`)  
**Phase**: Phase 1 Core Parent App Offline Foundation  
**Auditor & Implementer**: Senior Flutter Architect & QA Engineer  

---

## 1. Summary of Changes

All 8 identified issues were resolved directly in source code within the approved Phase 1 scope. Every change complies with the **200-line source-file constraint**, maintains **offline-only isolation**, and is backed by **automated regression tests**.

---

## 2. Modified Files & Root Causes

### 1. `apps/haven_app/lib/**` (45 Controller & Repository Files)
- **Problem**: 912 analysis errors resulting from `required this._repository` named constructor parameter syntax.
- **Root Cause**: Dart language specification prohibits optional or named parameters starting with an underscore.
- **Fix**: Replaced with standard Dart public parameters (`required RepositoryType repository`) and field initializers (`: _repository = repository`).
- **Files Modified**:
  - `apps/haven_app/lib/app/bindings/initial_bindings.dart`
  - 25 GetX Controllers in `apps/haven_app/lib/features/**/controllers/`
  - 19 Repository Adapters in `apps/haven_app/lib/features/**/data/`
  - Added `prefer_initializing_formals: false` in `apps/haven_app/analysis_options.yaml`.

### 2. `packages/haven_api/lib/src/offline/local_tables.dart`
- **Problem**: Uniqueness constraint bypassed when updating rows earlier in the list than their colliding counterparts.
- **Root Cause**: `violationFor` was checked against `rebuilt`, which was populated incrementally and lacked subsequent unvisited rows.
- **Fix**: Pre-indexed all matching rows, constructed prospective table entries, and validated every updated row against all other prospective rows (`j != i`).
- **Lines Before / After**: 192 lines -> 196 lines (Strictly <= 200 lines).

### 3. `packages/haven_api/lib/src/offline/demo_data_records.dart`
- **Problem**: Loading demo data while logged in attempted to insert duplicate profile rows or marked the real parent's profile with `is_demo: true`, causing its permanent deletion upon demo data clearing.
- **Root Cause**: `seed()` unconditionally inserted `TableName.profiles` with `id: parentId` and `is_demo: true`.
- **Fix**: Guarded parent profile insertion: only insert demo parent profile when `parentId == demoParentUserId`.
- **Lines Before / After**: 189 lines -> 191 lines (Strictly <= 200 lines).

### 4. `apps/haven_app/lib/features/settings/data/settings_repository.dart`
- **Problem**: `resetAllData()` did not clear onboarding and policy keys in `PreferencesStore`.
- **Root Cause**: Method cleared `LocalTables` but omitted calls to write reset values to `PreferencesStore`.
- **Fix**: Added explicit preference clearing for `onboardingCompleted`, `onboardingStep`, `onboardingEthicsAcknowledged`, `policyConfig`, and `parentDisplayName`.
- **Lines Before / After**: 179 lines -> 185 lines (Strictly <= 200 lines).

### 5. `apps/haven_app/lib/features/onboarding/data/local_onboarding_repository.dart`
- **Problem**: `ageBracket` in `Profile` was `null` after onboarding completion.
- **Root Cause**: Row was written with key `'age_group'`, but model `Profile.fromRow` reads key `'age_bracket'`.
- **Fix**: Written with both `'age_bracket': ageGroup` and `'age_group': ageGroup`.
- **Lines Before / After**: 183 lines -> 184 lines (Strictly <= 200 lines).

### 6. `packages/haven_api/lib/src/offline/local_schema.dart`
- **Problem**: Multiple memberships could be created for the same user in the same family.
- **Root Cause**: Missing composite unique definition on `TableName.familyMembers`.
- **Fix**: Added `uniqueComposites: [[familyIdColumn, 'user_id']]`.
- **Lines Before / After**: 158 lines -> 162 lines (Strictly <= 200 lines).

### 7. `apps/haven_app/lib/features/device_activity/data/local_activity_repository.dart`
- **Problem**: Potential primary key collision when logging rapid sequential events in the same millisecond.
- **Root Cause**: IDs used `millisecondsSinceEpoch`.
- **Fix**: Changed to `LocalIds.create()` which provides cryptographically strong UUID entropy.
- **Lines Before / After**: 174 lines -> 174 lines (Strictly <= 200 lines).

### 8. `apps/haven_app/lib/features/policies/data/local_policies_repository.dart`
- **Problem**: Fallback device creation wrote `'device_type'` instead of `'platform'` and missed required fields.
- **Root Cause**: Typo in column key and incomplete record shape.
- **Fix**: Normalized to `platform: 'android'` with full schema compliance.
- **Lines Before / After**: 181 lines -> 185 lines (Strictly <= 200 lines).

---

## 3. Regression Test Coverage

Two new automated regression test suites were created:

1. **`packages/haven_api/test/offline/stabilization_regression_test.dart`** (4 tests):
   - `updating the first row to conflict with a subsequent row is refused`
   - `updating row to its own current value succeeds without self-collision`
   - `inserting the same user into the same family twice is refused`
   - `seeding demo data preserves user profile and does not mark it as demo`

2. **`apps/haven_app/test/offline/phase1_stabilization_test.dart`** (4 tests):
   - `resetAllData clears all local tables and onboarding preferences`
   - `LocalOnboardingRepository writes age_bracket for Profile model parity`
   - `consecutive activity events have unique non-colliding IDs`
   - `fallback device contains platform: android and valid fields`

---

## 4. Verification Evidence

- `packages/haven_api`: **66 / 66 passed** (0 failures).
- `apps/haven_app`: **827 / 827 passed** (0 failures).
- Combined: **893 / 893 tests passed**.
- `flutter analyze` on `apps/haven_app`: **0 issues**.
- `flutter analyze` on `packages/haven_api`: **0 issues**.
- Source file line-count scan: **501 files scanned, 0 violations**.
- Debug APK build: `build\app\outputs\flutter-apk\app-debug.apk` built successfully in 96.4s.

