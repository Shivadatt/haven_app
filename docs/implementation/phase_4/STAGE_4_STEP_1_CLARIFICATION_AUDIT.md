# HAVEN STAGE 4 — STEP 1 CLARIFICATION AUDIT
## Read-Only Dependency & Architecture Investigation

**Document Version:** 1.0.0  
**Date:** November 17, 2026  
**Repository:** `D:\control`  
**Branch:** `main`  
**Base HEAD:** `354f1f30742936fe8e327d1f70c529308b2393eb`  
**Status:** COMPLETE — AWAITING OWNER AUTHORIZATION  
**Mode:** STRICT READ-ONLY AUDIT (Zero Source Code / Git Mutations)

---

## 1. Git Preflight & Working Tree Audit

### 1.1 Preflight Metadata
- **Repository Path:** `D:\control`
- **Current Branch:** `main` (verified)
- **Exact HEAD Commit:** `354f1f30742936fe8e327d1f70c529308b2393eb`
- **Line Count Compliance:** 793 hand-written source files scanned, **0 violations** (all files $\le 200$ lines).

### 1.2 Git Index & Status
- **Unstaged Changes:** None (`git diff --stat` is empty).
- **Staged Changes:** 15 files changed, 1,310 insertions(+), 47 deletions(-) (retaining Stage 3 Steps 11/12 verification and Phase 4 planning documents).
- **Untracked Files in Repository:** None.
- **Git Mutation Guard:** Strictly zero Git mutations executed (`git add`, `git commit`, `git reset`, `git checkout`, `git switch`, `git stash`, `git clean`, `git restore` were NOT run).

---

## 2. Clarification 1 — `json_utils.dart` Ownership & Dependency Discovery

### 2.1 Investigation Findings
A repository-wide search was conducted for `json_utils.dart`.
- **Exact Location:** Exactly one occurrence exists in the entire repository:
  `packages/haven_models/lib/src/json_utils.dart` (47 lines).
- **Public API Provided:**
  - `DateTime? asDate(Object? v)`
  - `double? asDouble(Object? v)`
  - `int? asInt(Object? v)`
  - `bool? asBool(Object? v)`
  - `String? asText(Object? v)`
  - `Map<String, Object?> asMap(Object? v)`
  - `List<Object?> asList(Object? v)`
  - `Object? toJsonDate(DateTime? v)`
- **Dependencies:** Pure Dart standard library (`dart:core`). Zero imports. Zero dependencies on Flutter, GetX, Firebase, Supabase, or application code.
- **Package Export Status:** Already exported publicly in `packages/haven_models/lib/haven_models.dart:16`:
  ```dart
  export 'src/json_utils.dart';
  ```
- **Existing Consumers:**
  - Internal to `haven_models`: `device_models.dart`, `location_models.dart`, `telemetry_models.dart`, `family_models.dart`, `session_models.dart`, `pairing_models.dart`.
  - External consumers: `apps/haven_app/lib/features/policies/data/policy_config.dart`, `policy_schedules.dart`, and `local_policies_repository.dart` (which import it via `package:haven_models/haven_models.dart`).

### 2.2 Dependency Table
| Helper | Exact Path | Dependencies | Current Consumers | Suitable for `haven_models`? |
|:---|:---|:---|:---|:---:|
| `json_utils.dart` | `packages/haven_models/lib/src/json_utils.dart` | None (`dart:core` only) | `haven_models` entities, `policy_config.dart`, `policy_schedules.dart`, `local_policies_repository.dart` | **Yes — already canonical in `haven_models`** |

### 2.3 Clarification 1 Recommendation
**Recommendation: OPTION A — Reuse the existing pure-Dart helper already available in `haven_models`.**

There is no need to create, extract, or duplicate `json_utils.dart`. When `policy_config.dart` and `policy_schedules.dart` are relocated into `packages/haven_models/lib/src/`, they will simply use a local relative import:
```dart
import 'json_utils.dart';
```
This guarantees 100% serialization compatibility and zero duplication.

---

## 3. Clarification 2 — `ScheduleConflict` & `ScheduleConflictDetector` Ownership

### 3.1 Source Inspection & Class Definitions
Source file: `apps/haven_app/lib/features/policies/data/schedule_conflicts.dart` (102 lines total).

#### Component A: `ScheduleConflict` (Lines 4–20)
```dart
final class ScheduleConflict {
  const ScheduleConflict({
    required this.scheduleA,
    required this.scheduleB,
    required this.overlappingDays,
  });

  final PolicySchedule scheduleA;
  final PolicySchedule scheduleB;
  final List<int> overlappingDays;

  String get summary { ... }
}
```
- **Nature:** Immutable data model representing an overlap between two `PolicySchedule` entities.
- **Dependencies:** Depends only on `PolicySchedule`. Pure Dart.
- **Placement Decision:** Belongs in `packages/haven_models/lib/src/policy_conflicts.dart` as a canonical domain model.

#### Component B: `ScheduleConflictDetector` (Lines 23–102)
```dart
abstract final class ScheduleConflictDetector {
  static List<ScheduleConflict> findConflicts({
    required PolicySchedule candidate,
    required List<PolicySchedule> existingList,
  });

  static bool hasDuplicateName({
    required String name,
    required List<PolicySchedule> existingList,
    String? excludeId,
  });
  
  static bool _timesOverlap(PolicySchedule a, PolicySchedule b);
  static List<(int, int)> _toDailyIntervals(int start, int end);
  static int? _toMinutes(String time);
}
```
- **Nature:** Pure static mathematical interval calculation comparing schedule start/end minutes and day sets.
- **Dependencies:** `PolicySchedule` and `ScheduleConflict`. Zero Flutter, zero GetX, zero repository or database dependencies.
- **Determinism:** **100% deterministic.** Produces identical results given identical inputs.
- **Clock / System Time Dependence:** **Zero.** Does not use `DateTime.now()` or wall-clock time; it compares static `HH:mm` time window strings.
- **Injected Clock:** Not applicable or required.
- **Consumers:**
  - `apps/haven_app/lib/features/policies/controllers/schedules_editor_controller.dart`
  - `apps/haven_app/lib/features/policies/views/widgets/schedule_form_dialog.dart`
  - `apps/haven_app/test/policies/advanced_schedules_editor_test.dart`
- **Placement Decision:** Co-locate in `packages/haven_models/lib/src/policy_conflicts.dart`.

### 3.2 Evaluation of Decision Framework
- `haven_models` holds canonical models and static model-level validation (e.g., `PolicyRules.validateDomain()` and `PolicySchedule.isOvernight`).
- Placing both `ScheduleConflict` and `ScheduleConflictDetector` in `packages/haven_models/lib/src/policy_conflicts.dart` results in a compact file of **102 lines** ($\le 200$ line constraint), with zero Flutter coupling.
- This allows both `haven_app` (parent schedule editor) and `haven_child` (child policy conflict validation) to reuse identical validation algorithms without code duplication or splitting 102 lines across two packages.

---

## 4. Clarification 3 — Compatibility Export Design

### 4.1 Usage & Consumer Audit
The four legacy files in `apps/haven_app/lib/features/policies/data/` were audited across all consumers:
1. `policy_config.dart`: 11 consumers (5 controllers, 2 repositories, 4 tests). Symbol used: `PolicyConfig`.
2. `policy_schedules.dart`: 10 consumers (2 controllers, 2 data models, 4 widgets, 2 tests). Symbols used: `PolicySchedule`, `PolicyScheduleType`.
3. `policy_rules.dart`: 13 consumers (4 controllers, 1 data model, 6 dialogs/cards, 2 tests). Symbol used: `PolicyRules`.
4. `schedule_conflicts.dart`: 3 consumers (1 controller, 1 widget, 1 test). Symbols used: `ScheduleConflict`, `ScheduleConflictDetector`.

### 4.2 Symbol-Level Compatibility Table
| Legacy File | Symbols Currently Exposed | Symbols Used by Consumers | Proposed Export |
|:---|:---|:---|:---|
| `policy_config.dart` | `PolicyConfig` | `PolicyConfig` | `export 'package:haven_models/haven_models.dart' show PolicyConfig;` |
| `policy_schedules.dart` | `PolicySchedule`, `PolicyScheduleType` | `PolicySchedule`, `PolicyScheduleType` | `export 'package:haven_models/haven_models.dart' show PolicySchedule, PolicyScheduleType;` |
| `policy_rules.dart` | `PolicyRules` | `PolicyRules` | `export 'package:haven_models/haven_models.dart' show PolicyRules;` |
| `schedule_conflicts.dart` | `ScheduleConflict`, `ScheduleConflictDetector` | `ScheduleConflict`, `ScheduleConflictDetector` | `export 'package:haven_models/haven_models.dart' show ScheduleConflict, ScheduleConflictDetector;` |

### 4.3 Export Strategy Recommendation
**Recommendation: OPTION A — Specific `show` exports for each compatibility barrel.**

**Comparison of Options:**
- **Option A (Specific `show` exports) [RECOMMENDED]:** Strictly encapsulates the export. Files importing `policy_config.dart` will receive *only* `PolicyConfig`, preventing accidental namespace pollution from unrelated `haven_models` symbols (e.g., `Device`, `Session`, `LocationEvent`).
- **Option B (Full package barrel export):** Over-exposes 40+ domain symbols to local UI components and controllers.
- **Option C (Direct `src/` exports):** Violates Dart package boundary encapsulation conventions (`implementation_imports` lint rule).

---

## 5. Cross-Check with `STAGE_4_STEP_1_EXECUTION_PLAN.md`

Comparing the original proposed plan (`v1.0.0-PROPOSED`) with our audit findings:

| Plan Area | Original Plan (`v1.0.0`) | Audit Finding & Correction | Status |
|:---|:---|:---|:---:|
| **Compatibility Barrels** | Proposed wildcard `export 'package:haven_models/haven_models.dart';` | Refine to explicit `show` exports (Option A) to prevent symbol leaking. | **Correction Required** |
| **`json_utils.dart` Handling** | Mentioned as a dependency to be shared | Already exists at `packages/haven_models/lib/src/json_utils.dart`; zero new file or export needed. | **Clarification Noted** |
| **`ScheduleConflictDetector`** | Proposed for `haven_models/src/policy_conflicts.dart` | Confirmed deterministic, clock-independent, pure Dart, 102 lines. Co-location confirmed valid. | **Confirmed Valid** |
| **Line-Count Budget** | 4 new files: 117, 157, 58, 102 lines | All files strictly under 200 lines. Repository total will remain at 0 violations. | **Confirmed Valid** |
| **Dependency Graph** | `haven_models` pure Dart; no new dependencies | Zero new dependencies needed in `pubspec.yaml`. | **Confirmed Valid** |

---

## 6. Recommended Architecture Proposal

### 6.1 Canonical Model Locations (`packages/haven_models/`)
```
packages/haven_models/
├── lib/
│   ├── haven_models.dart (add 4 exports)
│   └── src/
│       ├── json_utils.dart (existing, 47 lines)
│       ├── policy_config.dart (new canonical, 117 lines)
│       ├── policy_schedules.dart (new canonical, 157 lines)
│       ├── policy_rules.dart (new canonical, 58 lines)
│       └── policy_conflicts.dart (new canonical, 102 lines)
└── test/
    ├── policy_config_test.dart (~6 tests)
    ├── policy_schedules_test.dart (~8 tests)
    ├── policy_rules_test.dart (~6 tests)
    └── policy_conflicts_test.dart (~6 tests)
```

### 6.2 Compatibility Barrels in Parent App (`apps/haven_app/`)
```
apps/haven_app/lib/features/policies/data/
├── policy_config.dart (compatibility barrel with `show PolicyConfig`)
├── policy_schedules.dart (compatibility barrel with `show PolicySchedule, PolicyScheduleType`)
├── policy_rules.dart (compatibility barrel with `show PolicyRules`)
├── schedule_conflicts.dart (compatibility barrel with `show ScheduleConflict, ScheduleConflictDetector`)
├── policies_models.dart (retained parent view models, 119 lines)
├── app_catalogue.dart (retained parent UI icon catalog, 132 lines)
├── web_filter_models.dart (retained parent UI category models, 88 lines)
├── policies_repository.dart (retained parent repository interface, 132 lines)
└── local_policies_repository.dart (retained parent offline repository, 185 lines)
```

---

## 7. Exact Proposed Export Statements

### 7.1 Proposed Additions to `packages/haven_models/lib/haven_models.dart`
```dart
export 'src/policy_config.dart';
export 'src/policy_conflicts.dart';
export 'src/policy_rules.dart';
export 'src/policy_schedules.dart';
```

### 7.2 Proposed Compatibility Barrels in `apps/haven_app/`
```dart
// apps/haven_app/lib/features/policies/data/policy_config.dart
export 'package:haven_models/haven_models.dart' show PolicyConfig;
```

```dart
// apps/haven_app/lib/features/policies/data/policy_schedules.dart
export 'package:haven_models/haven_models.dart'
    show PolicySchedule, PolicyScheduleType;
```

```dart
// apps/haven_app/lib/features/policies/data/policy_rules.dart
export 'package:haven_models/haven_models.dart' show PolicyRules;
```

```dart
// apps/haven_app/lib/features/policies/data/schedule_conflicts.dart
export 'package:haven_models/haven_models.dart'
    show ScheduleConflict, ScheduleConflictDetector;
```

*(Note: These statements are proposed specifications only and have NOT been written into any source file.)*

---

## 8. Remaining Unresolved Questions
**None.** All three technical questions have been resolved with concrete codebase evidence:
1. `json_utils.dart` is already canonically owned and exported by `haven_models`.
2. `ScheduleConflictDetector` is deterministic, pure-Dart, clock-independent, and suitable for co-location in `policy_conflicts.dart`.
3. Option A specific `show` exports provide 100% backward compatibility for all 28+ parent consumers without symbol leakage.

---

## 9. Implementation Acceptance Criteria (For Future Authorization)

When the owner authorizes Step 1 execution, implementation must satisfy:
1. `packages/haven_models/lib/src/` contains `policy_config.dart`, `policy_schedules.dart`, `policy_rules.dart`, and `policy_conflicts.dart`.
2. All 4 new source files are individually $\le 200$ lines.
3. `packages/haven_models/lib/haven_models.dart` exports all 4 files.
4. Compatibility barrels in `apps/haven_app/lib/features/policies/data/` use specific `show` exports.
5. All existing 943 parent tests pass without single-line test modifications.
6. New unit tests in `haven_models` pass covering all extracted logic.
7. `check_line_counts.dart` confirms 0 violations across the entire repository.
8. `flutter analyze` reports 0 issues across child, parent, and root.
9. No new dependencies added to any `pubspec.yaml`.
10. Strictly zero Git mutations executed during implementation.

---

## 10. Strict Owner Authorization Requirement

> [!CAUTION]
> **STEP 1 IMPLEMENTATION HAS NOT BEEN STARTED.**  
> This document represents a completed read-only technical clarification audit. No source code was modified, no tests were altered, no files were relocated, and no Git mutations were performed.  
> **Explicit owner authorization is required before executing Step 1 implementation.**
