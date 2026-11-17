# HAVEN STAGE 4 — STEP 1 EXECUTION PLAN
## Canonical Policy Models Extraction

**Document Version:** 1.1.0-RECONCILED  
**Date:** November 17, 2026  
**Repository:** `D:\control`  
**Target Milestone:** Stage 4 — Step 1  
**Status:** RECONCILED EXECUTION PLAN — AWAITING EXPLICIT OWNER IMPLEMENTATION AUTHORIZATION  
**Author:** Antigravity Engineering  
**Reference Audit:** `docs/implementation/phase_4/STAGE_4_STEP_1_CLARIFICATION_AUDIT.md`

---

## 1. Executive Summary & Preflight

### 1.1 Context
In Stage 4, HAVEN implements the **Pure-Dart Deterministic Policy Evaluation Engine (E)**. 

To enable both the parent application (`haven_app`) and the child application (`haven_child`) to operate against an authoritative policy contract without code duplication or drift, Step 1 extracts policy models and validation rules into `packages/haven_models/`.

### 1.2 Owner Decision Confirmation
The owner has approved all four Stage 4 foundational decisions:
- **Decision 4.1 (Pure-Dart Scope):** Approved Option A. Evaluation is pure Dart; no native Android app blocking or Device Owner enforcement.
- **Decision 4.2 (Model Placement):** Approved Option A. Canonical models migrate to `packages/haven_models/`.
- **Decision 4.3 (Child Policy Source):** Approved Option A. Persisted locally via `haven_local.json`.
- **Decision 4.4 (Honest Disclaimer):** Approved Option A. Child UI will explicitly declare that policies are evaluated locally without active enforcement.

### 1.3 Accepted Technical Clarifications
The technical clarification audit (`STAGE_4_STEP_1_CLARIFICATION_AUDIT.md`) resolved the three design questions:
1. **JSON Helpers (`json_utils.dart`):** Reuses the existing canonical helper at `packages/haven_models/lib/src/json_utils.dart`. No duplication or extraction is required.
2. **Conflict Components (`ScheduleConflict` & `ScheduleConflictDetector`):** `ScheduleConflict` is a canonical data model. `ScheduleConflictDetector` is a 100% deterministic, clock-independent validation utility requiring no clock injection; both are co-located in `packages/haven_models/lib/src/policy_conflicts.dart`.
3. **Compatibility Barrels:** Employs explicit `show` exports (Option A) rather than full barrel exports, strictly isolating the exposed public API and preventing namespace pollution.

### 1.4 Verified Repository Preflight
- **Repository Path:** `D:\control`
- **Branch:** `main`
- **Base HEAD:** `354f1f30742936fe8e327d1f70c529308b2393eb`
- **Historical Test Suite Baseline:** **1,404 passed, 0 failures, 0 skips** (943 parent target, 330 child target, 96 packages target, 35 Kotlin JVM target).
- **Line Count Compliance:** 793 handwritten source files scanned, **0 violations** (all files $\le 200$ lines).
- **Static Analysis:** **0 issues** across `haven_child`, `haven_app`, and root.
- **Git Mutation Guard:** Strictly zero Git mutations executed.

---

## 2. Current Policy Model Inventory

The policy feature currently resides in `apps/haven_app/lib/features/policies/data/`:

| File | Primary Classes / Enums | Line Count | Current Purpose & Dependencies | Target Destination |
|:---|:---|:---:|:---|:---:|
| `policy_config.dart` | `PolicyConfig` | 117 | Full policy model (screen time, schedules, app limits, web rules). Uses `json_utils.dart`, `policy_rules.dart`, `policy_schedules.dart`. | **Extract to `haven_models`** (retained in `haven_app` as `show` barrel) |
| `policy_schedules.dart` | `PolicySchedule`, `PolicyScheduleType` | 157 | Recurring downtime/focus schedule model, overnight checks, day formatting. Uses `json_utils.dart`. | **Extract to `haven_models`** (retained in `haven_app` as `show` barrel) |
| `policy_rules.dart` | `PolicyRules` | 58 | Validation functions for domains, package names, minutes limits. Zero external dependencies. | **Extract to `haven_models`** (retained in `haven_app` as `show` barrel) |
| `schedule_conflicts.dart` | `ScheduleConflict`, `ScheduleConflictDetector` | 102 | Pure-Dart time overlap and conflict detection for schedules. Uses `policy_schedules.dart`. | **Extract to `haven_models`** (retained in `haven_app` as `show` barrel) |
| `policies_models.dart` | `PolicyLine`, `PolicyBoard` | 119 | Parent-app view models wrapping `DevicePolicy` rows from Supabase. | **Retain in `haven_app`** |
| `app_catalogue.dart` | `AppCatalogue`, `AppCatalogueItem`, `AppCategory` | 132 | Parent-app UI picker catalog with Flutter icons (`Icons.*`). | **Retain in `haven_app`** |
| `web_filter_models.dart` | `WebFilterModels`, `WebCategory` | 88 | Parent-app UI web categories with Flutter icons (`Icons.*`). | **Retain in `haven_app`** |
| `policies_repository.dart` | `PoliciesRepository`, `HavenPoliciesRepository` | 132 | Parent cloud repository interface and Supabase/offline implementation. | **Retain in `haven_app`** |
| `local_policies_repository.dart` | `LocalPoliciesRepository` | 185 | Parent offline local repository integrating preferences and family scope. | **Retain in `haven_app`** |

---

## 3. Dependency Graph & Architecture

### 3.1 Clean Architecture Layout
```
packages/haven_core/ (Result, Failures, Clock, Validation)
      ▲
packages/haven_models/ (CANONICAL: PolicyConfig, PolicySchedule, PolicyRules, ScheduleConflict, ScheduleConflictDetector)
      ▲
packages/haven_offline/ (Local storage tables, schema, constraints)
      ▲                     ▲
apps/haven_child/     packages/haven_api/
 (consumes canonical        ▲
     models)          apps/haven_app/
                       (re-exports canonical models via explicit show compatibility barrels)
```

### 3.2 Architectural Facts & Boundaries
1. **Zero Flutter in `haven_models`:** `packages/haven_models` is a pure-Dart package (`sdk: ^3.12.2`, `meta: ^1.18.0`). All extracted code and new tests remain 100% pure Dart.
2. **Canonical JSON Helper Reuse:** The 47-line helper at `packages/haven_models/lib/src/json_utils.dart` is reused as-is. Canonical models in `haven_models/lib/src/` import it via `import 'json_utils.dart';`.
3. **No New Dependencies:** Both `apps/haven_child` (`pubspec.yaml:25-26`) and `apps/haven_app` (`pubspec.yaml:26-27`) already declare path dependencies on `haven_models`. No `pubspec.yaml` requires modification.
4. **No Circular Dependencies:** The dependency hierarchy flows strictly downward (`app -> api -> offline -> models -> core`).

---

## 4. Exact Migration File List

### 4.1 New Files to Create in `packages/haven_models/`

| Target Path | Lines | Content & Responsibility |
|:---|:---:|:---|
| `packages/haven_models/lib/src/policy_config.dart` | 117 | Canonical `PolicyConfig` model, `fromJson`, `toJson`, `copyWith`, `defaults()`, `validate()`. Imports `json_utils.dart`, `policy_rules.dart`, `policy_schedules.dart`. |
| `packages/haven_models/lib/src/policy_schedules.dart` | 157 | Canonical `PolicySchedule` and `PolicyScheduleType` enum, overnight calculation, day formatting, defaults. Imports `json_utils.dart`. |
| `packages/haven_models/lib/src/policy_rules.dart` | 58 | Pure validation rules (`isValidDomain`, `validateDomain`, `validatePackageName`, `validateMinutesLimit`). Zero dependencies. |
| `packages/haven_models/lib/src/policy_conflicts.dart` | 102 | Canonical `ScheduleConflict` model and deterministic `ScheduleConflictDetector`. Imports `policy_schedules.dart`. |
| `packages/haven_models/test/policy_config_test.dart` | ~90 | Unit tests: defaults, serialization roundtrip, partial JSON fallbacks, validation. |
| `packages/haven_models/test/policy_schedules_test.dart` | ~110 | Unit tests: overnight math, days formatting, time parsing, enum wire mapping. |
| `packages/haven_models/test/policy_rules_test.dart` | ~75 | Unit tests: domain regex, package regex, minute limit bounds. |
| `packages/haven_models/test/policy_conflicts_test.dart` | ~95 | Unit tests: daytime overlaps, midnight overlaps, non-overlapping days, name collisions. |

### 4.2 Files to Modify

| Target Path | Modification Description |
|:---|:---|
| `packages/haven_models/lib/haven_models.dart` | Add public exports:<br>`export 'src/policy_config.dart';`<br>`export 'src/policy_conflicts.dart';`<br>`export 'src/policy_rules.dart';`<br>`export 'src/policy_schedules.dart';` |
| `apps/haven_app/lib/features/policies/data/policy_config.dart` | Convert to compatibility barrel:<br>`export 'package:haven_models/haven_models.dart' show PolicyConfig;` |
| `apps/haven_app/lib/features/policies/data/policy_schedules.dart` | Convert to compatibility barrel:<br>`export 'package:haven_models/haven_models.dart' show PolicySchedule, PolicyScheduleType;` |
| `apps/haven_app/lib/features/policies/data/policy_rules.dart` | Convert to compatibility barrel:<br>`export 'package:haven_models/haven_models.dart' show PolicyRules;` |
| `apps/haven_app/lib/features/policies/data/schedule_conflicts.dart` | Convert to compatibility barrel:<br>`export 'package:haven_models/haven_models.dart' show ScheduleConflict, ScheduleConflictDetector;` |

---

## 5. Parent Compatibility & Export Plan

### 5.1 Explicit `show` Compatibility Barrels
To guarantee zero breaking changes and zero namespace pollution across `apps/haven_app`:
1. **Explicit Symbol Filtering:** Instead of full barrel re-exports, each compatibility file exposes exactly the symbols used by existing consumers:
   - `policy_config.dart`: `show PolicyConfig`
   - `policy_schedules.dart`: `show PolicySchedule, PolicyScheduleType`
   - `policy_rules.dart`: `show PolicyRules`
   - `schedule_conflicts.dart`: `show ScheduleConflict, ScheduleConflictDetector`
2. **Import Path Preservation:** Over 28 files across `apps/haven_app` import these four files using relative paths (`../data/policy_config.dart`, etc.). Because the files remain in place as barrels, all 28+ files resolve without requiring a single import refactoring.
3. **Namespace Isolation:** Unrelated `haven_models` symbols (e.g., `Device`, `Session`, `LocationEvent`) are not leaked into parent policy feature files.

---

## 6. Serialization Compatibility Preservation

The `DevicePolicy` table stores policy configurations as arbitrary JSON in the `policy` column. The canonical serialization format produced by `PolicyConfig.toJson()` is strictly preserved:

```json
{
  "daily_screen_time_limit_minutes": 120,
  "schedules": [
    {
      "id": "sched-bedtime",
      "name": "Bedtime",
      "type": "bedtime",
      "start_time": "21:00",
      "end_time": "07:00",
      "days": [1, 2, 3, 4, 5, 6, 7],
      "is_active": true,
      "allowed_apps": [],
      "category": null
    },
    {
      "id": "sched-school",
      "name": "School Hours",
      "type": "school",
      "start_time": "08:30",
      "end_time": "15:00",
      "days": [1, 2, 3, 4, 5],
      "is_active": true,
      "allowed_apps": ["com.android.calculator2", "com.google.android.apps.docs"]
    }
  ],
  "app_policies": {
    "allowed_apps": ["com.android.calculator2", "com.google.android.apps.docs"],
    "blocked_apps": ["com.zhiliaoapp.musically", "com.instagram.android"],
    "app_limits": {
      "com.google.android.youtube": 30
    }
  },
  "website_policies": {
    "allowed_domains": ["wikipedia.org", "khanacademy.org"],
    "blocked_domains": ["tiktok.com", "gambling.com"],
    "safe_search_enabled": true
  }
}
```

- **Keys & Field Types:** Exactly identical to existing parent implementation.
- **Null Safety & Fallbacks:** Preserved. Empty schedules or missing keys fall back to `PolicyConfig.defaults()` identically in parent and child.
- **Zero Schema Migrations:** No database migrations or persistent local store restructuring are required.

---

## 7. Test & Regression Plan

### 7.1 New Unit Tests in `haven_models`
1. `policy_config_test.dart` (~6 tests): Defaults verification, `toJson`/`fromJson` roundtrip equality, partial JSON key fallback, validation rules, immutable `copyWith`.
2. `policy_schedules_test.dart` (~8 tests): Overnight calculation (21:00 to 07:00 vs 08:30 to 15:00), formatted time strings, formatted day strings, `isValidTime`, `PolicyScheduleType.fromWire` mapping.
3. `policy_rules_test.dart` (~6 tests): Domain rejection (protocols, paths, invalid TLDs), package name syntax validation, minutes limits (0 to 1440).
4. `policy_conflicts_test.dart` (~6 tests): Daytime overlaps, cross-midnight overlaps, non-overlapping day filtering, duplicate schedule name detection.

### 7.2 Regression Suite Targets
- **Parent Test Target:** Verify that all ~943 parent tests pass without modification.
- **Package Test Target:** Package tests expand from 96 to approximately 122 tests.
- **Child Test Target:** All 330 child tests continue to pass.
- **Kotlin JVM Target:** All 35 Kotlin tests continue to pass.
- **Total Expected Target:** Approximately ~1,430 automated tests passing, 0 failures, 0 skips (exact final count to be verified and recorded during implementation).

---

## 8. Step-by-Step Implementation Sequence

1. **Preflight Verification:**
   - Confirm clean working tree and toolchain (`flutter --version`, `dart --version`).
   - Run baseline parent policy tests to confirm initial green state.
2. **Canonical Model Creation:**
   - Create `packages/haven_models/lib/src/policy_rules.dart` (58 lines).
   - Create `packages/haven_models/lib/src/policy_schedules.dart` (157 lines).
   - Create `packages/haven_models/lib/src/policy_conflicts.dart` (102 lines).
   - Create `packages/haven_models/lib/src/policy_config.dart` (117 lines).
3. **Public Barrel Export:**
   - Add the 4 exports to `packages/haven_models/lib/haven_models.dart`.
4. **Model Unit Testing:**
   - Author the 4 test files in `packages/haven_models/test/`.
   - Run `dart test` inside `packages/haven_models`.
5. **Compatibility Barrel Conversion:**
   - Replace contents of the 4 files in `apps/haven_app/lib/features/policies/data/` with the explicit `show` exports.
6. **Parent Feature Verification:**
   - Run `flutter test test/policies/` inside `apps/haven_app`.
7. **Full Repository Regression & Audits:**
   - Run `flutter test` across `packages/haven_models`, `packages/haven_offline`, `packages/haven_api`, `packages/haven_core`, `apps/haven_child`, `apps/haven_app`.
   - Run `flutter analyze` across child, parent, packages, and root.
   - Run line-count audit script to verify 0 violations of the $\le 200$-line limit.

---

## 9. Rollback Strategy

Because Step 1 extracts pure-Dart model code and replaces the original files with drop-in compatibility barrels:
- No database tables, schemas, or network APIs are touched.
- If any regression occurs, restoring the original four files in `apps/haven_app/lib/features/policies/data/` and deleting the 4 new files in `packages/haven_models/lib/src/` instantly returns the repository to the baseline state.

---

## 10. Acceptance Criteria

Step 1 will be marked **PASSED** if and only if:
1. `PolicyConfig`, `PolicySchedule`, `PolicyScheduleType`, `PolicyRules`, `ScheduleConflict`, and `ScheduleConflictDetector` reside in `packages/haven_models/lib/src/` and are exported via `haven_models.dart`.
2. All 4 new source files in `haven_models` are strictly $\le 200$ lines.
3. Compatibility barrels in `apps/haven_app/lib/features/policies/data/` use explicit `show` exports.
4. All existing parent tests pass without single-line test code alterations.
5. All new tests in `haven_models` pass.
6. `flutter analyze` reports 0 issues across child, parent, and root.
7. Line-count audit confirms 0 violations across all hand-written source files.
8. Zero new package dependencies added to any `pubspec.yaml`.
9. Zero Git mutation commands executed.

---

## 11. Strict Owner Authorization Boundary

> [!CAUTION]
> **STEP 1 IMPLEMENTATION REMAINS UNAUTHORIZED.**  
> This reconciled plan specifies the exact execution steps based on the accepted clarification audit. No source code has been altered, no files have been created or moved, and no Git mutations have occurred.  
> **Implementation may begin ONLY after explicit owner authorization.**
