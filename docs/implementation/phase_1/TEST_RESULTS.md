# Test Results — Phase 1 Verification

**Date:** November 5, 2026  
**Flutter SDK:** 3.44.6  
**Dart SDK:** 3.8.1  
**Runner:** `flutter test --reporter compact`  

---

## 1. Summary of Execution

| Package / Suite | Tests Run | Passed | Failed | Skipped | Duration |
|---|---|---|---|---|---|
| `apps/haven_app` | 823 | 823 | 0 | 0 | ~1m 02s |
| `packages/haven_api` | 62 | 62 | 0 | 0 | ~6s |
| **Total** | **885** | **885** | **0** | **0** | **~1m 08s** |

---

## 2. Test Suite Breakdown by Feature Module

### 2.1 `apps/haven_app` Test Suites (823 Tests)

- **Account & Authentication (`test/account/`, `test/authentication/`):**
  - Offline session creation, credential validation, display name editing, sign-out persistence.
- **Family Management (`test/family/`):**
  - Family creation, family renaming, adding child profiles, editing age brackets/avatars, child unlinking with device revocation.
- **Child Devices (`test/child_devices/`):**
  - Simulated device registration, device list rendering, renaming, credential revocation, platform badges.
- **Pairing Simulation (`test/pairing/`):**
  - 6-digit code generation, 10-minute expiry timer, countdown ticker, code validation and rejection, simulated device-child pairing.
- **Parent Dashboard (`test/dashboard/`):**
  - Full aggregated dashboard load, empty states, loading progress, active policy card counts, recent activity items, demo data mode indicators.
- **Safe Zones (`test/safe_zones/`):**
  - Safe zone CRUD, Haversine spherical geometry, inside/outside geofence point evaluations, radius slider bounds.
- **Parental Policies (`test/policies/`):**
  - Daily screen time limit validation, bedtime and school schedule creation/editing/activation, day picker logic, allowed/blocked app packages, domain rules.
- **Notifications & Alerts (`test/notifications/`):**
  - Offline alerts list, mark as read, mark as unread, delete alert, alert category filtering chips, limits card.
- **Device Activity & Timeline (`test/device_activity/`):**
  - Offline usage board, daily app usage parsing, timeline activity sorting, logging activity events into local tables.
- **Settings & Preferences (`test/settings/`):**
  - Dark/Light theme switching, local storage persistence, demo data loading and purge buttons.
- **Shell & Navigation (`test/shell/`, `test/routing/`):**
  - Bottom navigation bar, route guards, state views, confirm sheets.
- **Telemetry & Diagnostics (`test/telemetry/`):**
  - Local diagnostic event tracking and privacy guarantees.

### 2.2 `packages/haven_api` Test Suites (62 Tests)

- `test/offline/local_tables_test.dart`: In-memory table inserts, queries, updates, deletes, and uniqueness constraints.
- `test/offline/local_user_auth_test.dart`: Local parent password hashing, session tokens, account reopen survival.
- `test/offline/demo_data_suite_test.dart`: Deterministic demo record seeding and clean purge without touching real user rows.
- `test/offline/local_row_engine_test.dart`: Filter queries (`eq`), sorting (`orderDesc`), limits, and relational lookups.

---

## 3. Static Analysis & Lint Verification

- **Command:** `flutter analyze`
- **Output:** `No issues found! (ran in 10.1s)`
- **Issues:** 0 errors, 0 warnings, 0 infos.

## 4. Line Count Verification

- **Command:** `dart run scripts/check_line_counts.dart`
- **Rule:** Maximum 200 lines per hand-written source file.
- **Files Scanned:** 499 source files.
- **Violations:** 0 violations.

