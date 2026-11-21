# HAVEN Stage 4, Step 4, Sub-step 4.2 — Formatter Feasibility Report

## Executive Summary

The six authorized files cannot all become formatter-compliant at or below 200 physical lines through formatting or whitespace-only changes.

- Four implementation/test files have feasible formatter-and-line-limit paths using whitespace or narrowly scoped structural adjustments.
- `child_policy_controller.dart` requires removing four existing internal blank lines after formatting to remain at 200 lines.
- `child_policy_controller_test.dart` has **no blank lines available for removal** and would grow from 197 to 264 lines under the formatter. Meeting 200 would require a substantive rewrite of test structure or a reduction in test coverage.

The previously reported five-line controller increase was not reproduced. The current read-only formatter output adds exactly **four** lines: 200 → 204.

**Recommended owner decision:** treat the controller test as the controlling constraint. Either:

1. retain the 200-line cap and approve a documented formatter exception for the non-compliant files, or
2. authorize a separate, substantive controller-test rewrite in addition to small whitespace/structure adjustments in the other files.

No implementation files were modified during this review.

---

## 1. Baseline and Repository Status

| Item | Result |
|---|---|
| Repository root | `D:/control` |
| Branch | `main` |
| HEAD | `8d0f21ebf684ebb6616cad8137c72ed8fd67e6ee` |
| Working tree | 2 modified tracked files, 4 untracked implementation files, 2 prior audit/remediation reports |
| Source/test files modified by this review | None |
| Formatter write operations | None |
| Git mutations | None |

Initial and final status:

```text
 M apps/haven_child/lib/app/bindings/child_initial_bindings.dart
 M apps/haven_child/test/app/child_initial_bindings_test.dart
?? apps/haven_child/lib/features/policies/controllers/
?? apps/haven_child/lib/features/policies/data/policy_usage_adapter.dart
?? apps/haven_child/test/features/policies/
?? docs/testing/stage_4_step_4_substep_4_2_final_audit.md
?? docs/testing/stage_4_step_4_substep_4_2_verification_remediation_report.md
```

Six-file SHA-256 values before report creation:

```text
1e14964cab782e984d98dbe6cc0b482cc62170a171cd02d6e6179fee65da93c4  child_policy_controller.dart
75d8681599d58bda0db12c813a755c9b8819b34678b15558868743366bf382a1  policy_usage_adapter.dart
13471c646f3d4f9cbb78a54e4c01fa43afcc67756cf15723ac3c2151f9cdfca4  child_initial_bindings.dart
9092bcc02a0ae5bc5c5bf6d471b7896aa12583756a51cef20ce174ea50d9d35e  child_policy_controller_test.dart
efd320c314d6e7e98d580b901aeb9712785b675f8affdd08e06278bdcb622f6b  policy_usage_adapter_test.dart
d1167f8fe425476ccc8a382787cc3688c709e3e41451b9a9e5a5de626846909a  child_initial_bindings_test.dart
```

---

## 2. Six-File Formatter Comparison

Method: read-only `dart format --output=show` against the explicit FVM Dart executable, with formatter status text removed before line counting and unified diff statistics.

| File | Current lines | Formatter-compliant lines | Added | Removed | Net | Already compliant |
|---|---:|---:|---:|---:|---:|---|
| `child_policy_controller.dart` | 200 | 204 | 4 | 0 | +4 | No |
| `policy_usage_adapter.dart` | 102 | 102 | 0 | 0 | 0 | Yes |
| `child_initial_bindings.dart` | 133 | 135 | 3 | 1 | +2 | No |
| `child_policy_controller_test.dart` | 197 | 264 | 162 | 95 | +67 | No |
| `policy_usage_adapter_test.dart` | 154 | 158 | 18 | 14 | +4 | No |
| `child_initial_bindings_test.dart` | 131 | 145 | 89 | 75 | +14 | No |

### Formatting-difference categories

| File | Hunk starts (old file) | Categories of difference |
|---|---|---|
| `child_policy_controller.dart` | 46, 58, 97, 182 | Four blank-line insertions between method declarations. No removals. |
| `policy_usage_adapter.dart` | None | Already formatter-compliant. |
| `child_initial_bindings.dart` | 61 | Wraps the `_openAndRegister(String? directory)` signature into three lines. Adds 3, removes 1. |
| `child_policy_controller_test.dart` | 7, 41, 60, 183 | Import-section spacing; wraps the `synced(...)` helper; large reflow of long `test(...)` declarations and `expect(...)` calls; blank line before the fake repository class. Adds 162, removes 95. |
| `policy_usage_adapter_test.dart` | 60, 124 | Expands two `usage(apps: const [...])` argument blocks. Adds 18, removes 14. |
| `child_initial_bindings_test.dart` | 46 | Reflows long `test(...)` declarations and `expect(...)` calls across the main test body. Adds 89, removes 75. |

---

## 3. Controller-Specific Analysis

### Exact four-line increase

The current formatter output changes `child_policy_controller.dart` from 200 to 204 lines through four blank-line insertions:

| Hunk | Location | Insertion |
|---|---|---|
| 1 | Old line 46 | Blank line between `onInit()` and the `onClose()` override |
| 2 | Old line 58 | Blank line between `onClose()` and `loadPolicy()` |
| 3 | Old line 97 | Blank line between `loadPolicy()` and `evaluate()` |
| 4 | Old line 182 | Blank line between `_clearUsageDiagnostics()` and `_unavailable()` |

There are no removals. The earlier remediation report’s five-line estimate is superseded by this measured four-line result.

### Can the increase be offset without behavior changes?

**Technically yes, using existing internal blank lines.**

Current controller blank lines are at lines 38, 76, 94, 115, 123, 128, and 176. Four of these are internal method-section separators that the formatter does not insert:

- line 94 — between the successful load return and the failure branch in `loadPolicy()`
- line 115 — between the ready-policy guard and evaluation-ID capture in `evaluate()`
- line 123 — after the post-probe stale guard and before local acquisition variables
- line 128 — before the permission-result branch

Removing those four blank lines would reduce the current line count to 196. The formatter would then add its four required member-separation blank lines, producing a formatter-compliant **200 lines**.

This does not remove comments, safeguards, diagnostics, behavior, or documentation. It only reduces internal visual spacing. It does require a separate edit authorization and a formatter/analyzer/test rerun.

### Controller conclusion

A formatter-compliant controller at exactly 200 lines is technically achievable within the existing file and scope.

---

## 4. Other Five Files

### `policy_usage_adapter.dart`

- Current: 102.
- Formatter-compliant: 102.
- Already compliant. No change needed.

### `child_initial_bindings.dart`

- Current: 133.
- Formatter-compliant: 135.
- The only difference is the wrapped `_openAndRegister(String? directory)` signature.
- The signature is 82 characters and must be at most 80 to remain on one line.
- A narrow parameter rename (for example, `directory` → `dir` within that method only) would shorten the signature and keep formatter output at **133 lines**.
- Behavioral risk: none, if all method-local references are updated.
- Test implications: none expected.
- Requires separate edit authorization.

### `policy_usage_adapter_test.dart`

- Current: 154.
- Formatter-compliant: 158.
- Four lines can be offset by removing four blank lines between tests or groups.
- The formatter does not require blank lines between statements inside `main`.
- Behavioral risk: none; test content remains unchanged.
- Test implications: none.
- Requires separate edit authorization.

### `child_initial_bindings_test.dart`

- Current: 131.
- Formatter-compliant: 145.
- Fourteen lines would need to be offset. The file currently has fourteen blank lines, mostly between tests and setup sections.
- Removing internal blank lines could bring the formatted file to roughly 131–133, below 200.
- This reduces readability but does not remove tests or assertions.
- Behavioral risk: none.
- Test implications: none.
- Requires separate edit authorization and a formatter check after removal to confirm the exact count.

### `child_policy_controller_test.dart`

- Current: 197.
- Formatter-compliant: 264.
- The file currently contains **no blank lines**, so there is no whitespace-only offset available.
- The formatter converts 95 existing lines into 162 lines through expanded test declarations and `expect(...)` expressions.
- To reach 200, at least 64 formatter-normalized lines must be eliminated.
- This cannot be done by formatting or removing blank lines. It requires substantive changes such as:
  - shortening many test descriptions,
  - introducing compact assertion/evaluation helpers,
  - merging tests or consolidating assertions, or
  - removing test coverage.
- Such a rewrite is not a narrowly scoped formatting adjustment. It carries a real risk of reducing coverage or obscuring test intent, and may not preserve all existing assertions within 200 lines.
- The two constraints therefore conflict for this file unless the owner authorizes substantive test restructuring or grants a line-count exception.

---

## 5. Feasibility Options

### Option A — All six files satisfy formatter and line limits within existing scope

**Not valid.**

Five files require changes, and `child_policy_controller_test.dart` requires a 64-line reduction with no blank lines available to remove.

### Option B — Formatter compliance requires narrowly scoped restructuring within the existing six files

**Partially valid; not sufficient for the controller test under a narrow scope.**

Files where this is feasible:

| File | Required change | Expected formatted lines | Behavioral risk | Test impact |
|---|---|---:|---|---|
| `child_policy_controller.dart` | Remove four internal blank lines | 200 | None | None |
| `child_initial_bindings.dart` | Shorten `_openAndRegister` parameter name | 133 | None if references updated | None expected |
| `policy_usage_adapter_test.dart` | Remove four blank lines | 154 | None | None |
| `child_initial_bindings_test.dart` | Remove up to fourteen internal blank lines | ~131–133 | None | None |

For `child_policy_controller_test.dart`, Option B would not be narrow: reaching 200 requires a substantial rewrite of test declarations/assertions or coverage reduction.

A separate owner authorization is required for every edit. A formatter and full-suite rerun would also be required.

### Option C — Formatter compliance and the 200-line limit cannot both be satisfied for one or more files without an owner-approved exception or scope change

**Valid for the controller test.**

- Affected file: `child_policy_controller_test.dart`.
- Formatter-compliant line count: 264.
- Maximum allowed: 200.
- No blank-line or formatting-only offset exists.
- Preserving all tests and assertions while reducing the formatted file by 64 lines would require a substantive rewrite or deletion/merging of meaningful coverage.

A separate owner decision is required: either grant a line-count exception for that file, or authorize a broader test rewrite that may reduce coverage.

### Combined technically valid path

A formatter-clean solution for all six is possible only if the owner authorizes:

1. four internal blank-line removals in `child_policy_controller.dart`,
2. a narrow parameter rename in `child_initial_bindings.dart`,
3. blank-line reductions in `policy_usage_adapter_test.dart` and `child_initial_bindings_test.dart`, and
4. a substantive rewrite of `child_policy_controller_test.dart`, with explicit permission to consolidate tests/assertions.

The combined path is **Option B expanded beyond narrow scope**, or **Option C plus a coverage-affecting rewrite authorization**.

---

## 6. Recommended Owner Decision

Do not apply formatter output wholesale. It would exceed the 200-line cap and would substantially rewrite the controller test without preserving the current compact test layout.

Recommended decision:

- **Preferred:** retain the 200-line cap and approve a documented formatter exception for the non-compliant files, with no implementation changes.
- **If formatter cleanliness is mandatory:** authorize a separate remediation that:
  - removes the four internal controller blank lines,
  - shortens the binding method parameter,
  - removes blank lines from the two test files where sufficient,
  - explicitly authorizes a substantive `child_policy_controller_test.dart` rewrite, including permission to merge or shorten tests while preserving behavior coverage,
  - reruns formatter check, analyzer, and the full child-app suite.

This review does not select or execute any option and does not declare Sub-step 4.2 accepted or closed.

---

## 7. Confirmation of Read-Only Status

- No source or test file was modified.
- No formatter write operation was performed.
- No file was created except this report.
- No Git mutation was performed.
- HEAD and branch remained unchanged.
- The six implementation-file hashes remained unchanged during the review.

Expected status after report creation adds only:

```text
?? docs/testing/stage_4_step_4_substep_4_2_formatter_feasibility_report.md
```
