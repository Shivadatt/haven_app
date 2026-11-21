# HAVEN Stage 4, Step 4, Sub-step 4.2 — Formatter Remediation Plan and Scope Freeze

## Verdict

**A — REMEDIATION PLAN COMPLETE**

A feasible plan exists that:

- preserves every existing controller test scenario and assertion,
- keeps every resulting Dart file at or below 200 physical lines after formatting,
- preserves the approved Sub-step 4.2 architecture and technical contract,
- adds exactly one controller test file, and
- limits all proposed changes to the six existing implementation paths plus that one test file.

No implementation is authorized by this report. The plan requires explicit owner approval of the additional test file, the proposed allowlist, and the split/formatting changes.

---

## 1. Baseline and Repository State

| Item | Result |
|---|---|
| Repository root | `D:/control` |
| Branch | `main` |
| HEAD | `8d0f21ebf684ebb6616cad8137c72ed8fd67e6ee` |
| Initial working-tree status | 2 modified tracked files, 4 untracked implementation files, 3 prior reports |
| Previous feasibility report | Present at `docs/testing/stage_4_step_4_substep_4_2_formatter_feasibility_report.md` |
| Changes since feasibility review | Only the feasibility report addition; implementation hashes unchanged |
| Source/test files modified by this planning task | None |
| Git mutations | None |

Current status:

```text
 M apps/haven_child/lib/app/bindings/child_initial_bindings.dart
 M apps/haven_child/test/app/child_initial_bindings_test.dart
?? apps/haven_child/lib/features/policies/controllers/
?? apps/haven_child/lib/features/policies/data/policy_usage_adapter.dart
?? apps/haven_child/test/features/policies/
?? docs/testing/stage_4_step_4_substep_4_2_final_audit.md
?? docs/testing/stage_4_step_4_substep_4_2_formatter_feasibility_report.md
?? docs/testing/stage_4_step_4_substep_4_2_verification_remediation_report.md
```

Existing six implementation paths:

1. `apps/haven_child/lib/features/policies/controllers/child_policy_controller.dart`
2. `apps/haven_child/lib/features/policies/data/policy_usage_adapter.dart`
3. `apps/haven_child/lib/app/bindings/child_initial_bindings.dart`
4. `apps/haven_child/test/features/policies/child_policy_controller_test.dart`
5. `apps/haven_child/test/features/policies/policy_usage_adapter_test.dart`
6. `apps/haven_child/test/app/child_initial_bindings_test.dart`

Implementation-file hashes are unchanged from the feasibility review:

```text
1e14964cab782e984d98dbe6cc0b482cc62170a171cd02d6e6179fee65da93c4  child_policy_controller.dart
75d8681599d58bda0db12c813a755c9b8819b34678b15558868743366bf382a1  policy_usage_adapter.dart
13471c646f3d4f9cbb78a54e4c01fa43afcc67756cf15723ac3c2151f9cdfca4  child_initial_bindings.dart
9092bcc02a0ae5bc5c5bf6d471b7896aa12583756a51cef20ce174ea50d9d35e  child_policy_controller_test.dart
efd320c314d6e7e98d580b901aeb9712785b675f8affdd08e06278bdcb622f6b  policy_usage_adapter_test.dart
d1167f8fe425476ccc8a382787cc3688c709e3e41451b9a9e5a5de626846909a  child_initial_bindings_test.dart
```

---

## 2. Proposed Final File Allowlist

| # | Path | Status | Purpose |
|---:|---|---|---|
| 1 | `apps/haven_child/lib/features/policies/controllers/child_policy_controller.dart` | Modify | Remove four internal blank lines; formatter compliance |
| 2 | `apps/haven_child/lib/features/policies/data/policy_usage_adapter.dart` | No change | Already formatter-compliant |
| 3 | `apps/haven_child/lib/app/bindings/child_initial_bindings.dart` | Modify | Shorten one method parameter name to avoid formatter wrapping |
| 4 | `apps/haven_child/test/features/policies/child_policy_controller_test.dart` | Modify | Retain lifecycle/permission/stale tests after split |
| 5 | `apps/haven_child/test/features/policies/child_policy_controller_edge_cases_test.dart` | **New** | Retain query-failure and exact-midnight tests |
| 6 | `apps/haven_child/test/features/policies/policy_usage_adapter_test.dart` | Modify | Remove four blank lines to offset formatter expansion |
| 7 | `apps/haven_child/test/app/child_initial_bindings_test.dart` | Modify | Remove blank lines to offset formatter wrapping |

### Why the additional test file is necessary

The current formatter-compliant `child_policy_controller_test.dart` is 264 lines with no blank lines available for simple compaction. Splitting the existing tests into two files is the only plan that:

- keeps every existing test and assertion,
- avoids deleting or merging meaningful coverage,
- avoids formatter suppression,
- avoids changing the 200-line limit, and
- stays within test-code scope.

The new file is exclusively a controller test file. It does not authorize UI, navigation, policy synchronization, evaluator, native enforcement, database, Stage 5, or Sub-step 4.3 work.

---

## 3. Controller Test Split

### Destination A — existing `child_policy_controller_test.dart`

Retains:

| Test case | Current lines | Formatter-compliant lines |
|---|---:|---:|
| `initial loading refuses evaluation; neutral load permits it` | 68–76 | 71–85 (15) |
| `failed initial load refuses evaluation and records failure` | 77–82 | 86–94 (9) |
| `reload replaces the active policy; failed reload keeps it diagnostic-only` | 83–96 | 95–120 (26) |
| `disposed controller refuses evaluation and ignores late completion` | 97–108 | 121–135 (15) |
| `permission outcomes skip or query correctly and stay distinct` | 109–125 | 136–160 (25) |
| `stale evaluation after reload cannot publish state` | 173–184 | 239–250 (12) |

### Destination B — new `child_policy_controller_edge_cases_test.dart`

Retains:

| Test case | Current lines | Formatter-compliant lines |
|---|---:|---:|
| `query failures become unavailable usage and retain exact failures` | 126–148 | 161–195 (35) |
| `exact local midnight skips query and keeps unavailable usage` | 149–172 | 196–238 (43) |

### Shared setup and helpers

Both files will contain the same:

- package and relative imports,
- `main()` setup state,
- `setUp` controller/repository/clock construction,
- `tearDown` disposal,
- `config(...)`, `synced(...)`, `usage(...)`, and `app(...)` helpers,
- private `_FakePolicyRepository` implementation.

The only setup difference is that `localMidnight` is needed only by the midnight test in the new file. The existing file must omit it to avoid an unused-local analyzer warning.

The shared block is:

- **83 formatter-compliant lines for the existing file** (without `localMidnight`):
  - imports and `main()` setup/helpers: 69 lines,
  - closing `main()` brace: 1 line,
  - blank line before fake: 1 line,
  - `_FakePolicyRepository` class: 12 lines.
- **84 formatter-compliant lines for the new file** (with `localMidnight`):
  - imports and `main()` setup/helpers: 70 lines,
  - closing `main()` brace: 1 line,
  - blank line before fake: 1 line,
  - `_FakePolicyRepository` class: 12 lines.

Duplicating this block is intentional because the authorization permits exactly one additional test file and no shared helper file. The duplicated fake and helpers remain handwritten. No production abstraction is introduced.

The private fake class name may be reused in both files because each Dart library has its own private namespace.

### Estimated formatter-compliant line counts

| File | Shared block | Test bodies | Estimated total | Limit | Headroom |
|---|---:|---:|---:|---:|---:|
| `child_policy_controller_test.dart` | 83 | 102 | **185** | 200 | 15 |
| `child_policy_controller_edge_cases_test.dart` | 84 | 78 | **162** | 200 | 38 |

These are estimates derived from the formatter output of the current single file. They are not verified until the split files exist and are formatted.

### Coverage-preservation analysis

| Coverage area | Existing test | Destination | Preserved |
|---|---|---|---|
| Initial/loading refusal | Initial loading test | A | Yes |
| Neutral-policy evaluation | Initial loading test | A | Yes |
| Failed initial load | Failed initial load test | A | Yes |
| Reload replacement | Reload test | A | Yes |
| Failed reload diagnostics | Reload test | A | Yes |
| Failed reload suspends evaluation | Reload test | A | Yes |
| Disposal and late completion | Disposed controller test | A | Yes |
| Permission probe failure | Permission outcomes test | A | Yes |
| Denied permission | Permission outcomes test | A | Yes |
| Unsupported permission | Permission outcomes test | A | Yes |
| Query permission failure | Query failures test | B | Yes |
| Generic query failure | Query failures test | B | Yes |
| Diagnostics cleared on success | Query failures test | B | Yes |
| Fresh query count | Query failures test | B | Yes |
| Exact local midnight | Midnight test | B | Yes |
| Permission probe at midnight | Midnight test | B | Yes |
| Zero-duration query skip | Midnight test | B | Yes |
| Unavailable quota at midnight | Midnight test | B | Yes |
| Schedule/blocklist evaluation at midnight | Midnight test | B | Yes |
| Stale result after reload | Stale test | A | Yes |

No test scenario or assertion is removed, merged, weakened, or duplicated.

---

## 4. Minimal Changes for the Other Five Files

### `child_policy_controller.dart`

Current: 200 lines. Formatter-compliant: 204 lines.

The formatter adds exactly four blank lines between methods:

1. between `onInit()` and `onClose()`,
2. between `onClose()` and `loadPolicy()`,
3. between `loadPolicy()` and `evaluate()`,
4. between `_clearUsageDiagnostics()` and `_unavailable()`.

Proposed removal of four existing internal blank lines:

- current line 94 — between the successful load return and failure branch,
- current line 115 — between the ready-policy guard and evaluation-ID capture,
- current line 123 — after the post-probe stale guard and before acquisition variables,
- current line 128 — before the permission-result branch.

No comments, method separation, safeguards, diagnostics, or behavior are removed. Internal visual spacing is reduced; formatter-inserted member separation remains.

**Estimated formatted count: exactly 200 lines.** Requires verification after formatting.

### `policy_usage_adapter.dart`

Current: 102 lines. Formatter-compliant: 102 lines. No change proposed.

### `child_initial_bindings.dart`

Current: 133 lines. Formatter-compliant: 135 lines.

The only formatter difference is the wrapped `_openAndRegister(String? directory)` signature, which is 82 characters and exceeds the 80-column formatter width.

Proposed narrow change:

- rename the `_openAndRegister` parameter from `directory` to `dir` within that method only,
- update its two method-local references.

Expected signature length: 77 characters. This keeps the signature on one line.

Behavior-preserving because the parameter is method-local and no public API, registration order, storage behavior, or cleanup order changes.

**Estimated formatted count: 133 lines.** Requires verification after formatting.

### `policy_usage_adapter_test.dart`

Current: 154 lines. Formatter-compliant: 158 lines.

Proposed removal of four blank lines between tests inside `group('fromDailyResult', ...)`:

- before `test('empty app list and all-zero records are unavailable'...)`
- before `test('keeps measured apps but never forwards the native total'...)`
- before `test('maps delayed freshness and preserves source interval'...)`
- before `test('rejects malformed interval and malformed app records'...)`

All tests, assertions, and group structure remain.

**Estimated formatted count: 154 lines.** Requires verification after formatting.

### `child_initial_bindings_test.dart`

Current: 131 lines. Formatter-compliant: 145 lines.

Proposed removal of the fourteen existing intra-file blank lines used only for visual separation. This offsets the formatter’s line wrapping without removing any test, setup, teardown, or assertion. Some readability is lost, but no coverage or behavior changes.

If the formatter restores one separator blank line, the result remains around 132 lines, still far below 200.

**Estimated formatted count: approximately 131 lines; at most approximately 132.** Requires verification after formatting.

---

## 5. Proposed Implementation Sequence

After owner approval:

1. Create `child_policy_controller_edge_cases_test.dart` with the duplicated shared setup/fake and the two assigned tests.
2. Remove the two split tests from the existing controller test file.
3. Remove the four internal blank lines from `child_policy_controller.dart`.
4. Rename the `_openAndRegister` parameter in `child_initial_bindings.dart`.
5. Remove the four specified blank lines from `policy_usage_adapter_test.dart`.
6. Remove the fourteen visual blank lines from `child_initial_bindings_test.dart`.
7. Run the formatter on the seven authorized files.
8. Run the verification sequence below.

---

## 6. Exact Proposed Verification Sequence

Use only the explicit FVM executables:

- Flutter: `C:\Users\ASUS\fvm\versions\3.44.6\bin\flutter.bat`
- Dart: `C:\Users\ASUS\fvm\versions\3.44.6\bin\dart.bat`

### 6.1 Format the authorized files

```text
cd /d/control
C:\Users\ASUS\fvm\versions\3.44.6\bin\dart.bat format
  apps/haven_child/lib/features/policies/controllers/child_policy_controller.dart
  apps/haven_child/lib/features/policies/data/policy_usage_adapter.dart
  apps/haven_child/lib/app/bindings/child_initial_bindings.dart
  apps/haven_child/test/features/policies/child_policy_controller_test.dart
  apps/haven_child/test/features/policies/child_policy_controller_edge_cases_test.dart
  apps/haven_child/test/features/policies/policy_usage_adapter_test.dart
  apps/haven_child/test/app/child_initial_bindings_test.dart
```

### 6.2 Verify formatter cleanliness

```text
C:\Users\ASUS\fvm\versions\3.44.6\bin\dart.bat format --output=none --set-exit-if-changed
  <the same seven files>
```

Expected: exit code 0.

### 6.3 Verify physical line counts

```text
wc -l <the same seven files>
```

Expected: every file at or below 200 physical lines.

### 6.4 Analyzer

```text
cd /d/control/apps/haven_child
C:\Users\ASUS\fvm\versions\3.44.6\bin\flutter.bat analyze
```

Expected: no issues.

### 6.5 Focused controller tests

```text
C:\Users\ASUS\fvm\versions\3.44.6\bin\flutter.bat test
  test/features/policies/child_policy_controller_test.dart
  test/features/policies/child_policy_controller_edge_cases_test.dart
```

Expected: all controller tests pass, including all eight original scenarios.

### 6.6 Adapter and binding tests

```text
C:\Users\ASUS\fvm\versions\3.44.6\bin\flutter.bat test
  test/features/policies/policy_usage_adapter_test.dart
  test/app/child_initial_bindings_test.dart
```

Expected: all adapter and binding tests pass.

### 6.7 Full child-app suite

```text
C:\Users\ASUS\fvm\versions\3.44.6\bin\flutter.bat test
```

Expected: full suite passes on the final state.

### 6.8 Whitespace check

```text
cd /d/control
git diff --check
```

Expected: no whitespace errors.

### 6.9 Repository integrity

```text
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git diff --name-only
git ls-files --others --exclude-standard
```

Expected:

- HEAD remains `8d0f21ebf684ebb6616cad8137c72ed8fd67e6ee`,
- branch remains `main`,
- no unexpected paths,
- no Git mutations,
- only the approved seven files plus this planning report and prior reports are present.

---

## 7. Contract Preservation

The plan does not alter any approved decision or behavior:

| Contract item | Preservation |
|---|---|
| 1A baseline | HEAD and branch unchanged |
| 2B no `ChildPolicyBindings` | No binding architecture changes |
| Direct `ChildInitialBindings` registration | Parameter rename only; registration/cleanup order unchanged |
| 3A stable lifecycle codes | No production behavior changes |
| 4A fresh-query-only evaluation | No usage acquisition changes |
| Initial/loading evaluation restriction | Existing test retained |
| Failed-reload diagnostics/recovery | Existing test retained |
| Failed-reload evaluation suspension | Existing test retained |
| Unknown completeness / unavailable total | Adapter and evaluator untouched |
| Exact local midnight | Existing midnight test retained in new file |
| Diagnostics retention/clearing | Existing permission/query tests retained |
| Generation/disposal guards | Existing stale/disposal tests retained |
| Reverse-order binding cleanup | No cleanup changes |
| No evaluator/model/usage/native/route/UI changes | Outside allowlist |

No production behavior changes are planned beyond the parameter rename and blank-line removal.

---

## 8. Risks and Unresolved Questions

1. **Estimated split line counts are not verified.** They are based on the current formatter output segments. Both have headroom (15 and 38 lines), reducing the risk of exceeding 200 after formatting.
2. **Duplicated setup/fake code.** The 83/84-line shared block must be duplicated because no shared helper file is authorized. The two copies must remain identical except for `localMidnight` to avoid drift.
3. **Readability cost.** Removing internal blank lines from the controller, adapter test, and binding test reduces visual separation. No behavior or coverage is affected.
4. **Binding parameter rename.** This is the only identifier change. It is method-local and behavior-preserving, but requires careful reference updates.
5. **New file naming.** `child_policy_controller_edge_cases_test.dart` is the proposed name. Owner approval is required before creation.
6. **Full-suite count.** The split retains eight tests across two files, so the total test count should remain 413. This must be verified, not assumed.
7. **Formatter version.** All estimates assume Dart 3.12.2 from FVM 3.44.6. Different formatter versions could change counts.

---

## 9. Owner Authorization Required

Before implementation, the owner must approve:

1. The new file `apps/haven_child/test/features/policies/child_policy_controller_edge_cases_test.dart`.
2. The seven-file implementation allowlist in §2.
3. The controller test split allocation in §3.
4. The four-blank-line controller adjustment.
5. The binding parameter rename.
6. The blank-line reductions in the adapter and binding tests.
7. The verification sequence in §6.

This report is a plan only. It does not authorize implementation, formatting, test creation, Sub-step 4.3, or acceptance of Sub-step 4.2.

---

## 10. Confirmation

- No source or test file was modified.
- No formatter write operation was performed.
- No additional test file was created.
- No Git mutation was performed.
- Only this planning report was created.
- Sub-step 4.2 remains open pending explicit owner approval.
