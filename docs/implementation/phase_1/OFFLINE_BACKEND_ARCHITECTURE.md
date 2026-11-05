# Offline Backend Architecture — Haven Parental Control

## 1. Architectural Overview

HAVEN Parental Control employs an offline-first architecture designed to decouple the UI and domain logic from remote infrastructure. When running in offline mode (`HAVEN_OFFLINE_MODE=true` or via default initialization when cloud backends are unconfigured), the system selects `OfflineHavenBackend`.

```
+-------------------------------------------------------------+
|                      Haven Flutter UI                       |
|  (GetX Controllers: Family, Policies, Zones, Devices, etc.) |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                     Repository Layer                        |
|  (LocalFamilyRepo, LocalPoliciesRepo, LocalDashboardRepo)   |
+-------------------------------------------------------------+
                              |
         +--------------------+--------------------+
         |                                         |
         v                                         v
+-----------------------+              +----------------------+
|     LocalRowReader    |              |    LocalRowWriter    |
+-----------------------+              +----------------------+
         |                                         |
         +--------------------+--------------------+
                              |
                              v
+-------------------------------------------------------------+
|                        LocalTables                          |
|         In-memory / Persistent Key-Value & Row Store        |
+-------------------------------------------------------------+
```

---

## 2. Core Components

### 2.1 `OfflineHavenBackend`
Located in `packages/haven_api/lib/src/offline/offline_haven_backend.dart`.
- Manages local lifecycle (`start()`, `stop()`, `reset()`).
- Exposes `LocalRowReader` as `HavenBackend.rows` and `LocalRowWriter` as `HavenBackend.writer`.
- Provides `LocalUserAuth` as `HavenBackend.auth` for session management.
- Sets `OfflineHavenBackend.isActive = true` when enabled, allowing GetX bindings to dynamically supply local repositories.

### 2.2 `LocalTables` & `TableName`
Located in `packages/haven_api/lib/src/offline/local_tables.dart`.
Represents relational tables using indexed maps of rows:
- `TableName.profiles`: User and child profile records (id, role, display_name, age_bracket, avatar, timestamps).
- `TableName.families`: Family tenant records (id, name, created_at).
- `TableName.familyMembers`: Memberships linking profiles to families with roles (`parent`, `child`) and statuses (`active`, `removed`).
- `TableName.devices`: Enrolled child devices with metadata and credential timestamps.
- `TableName.devicePolicies`: Structured policy configurations per child/family.
- `TableName.safeZones`: Geofence definitions with coordinates and radius bounds.
- `TableName.safetyAlerts`: Safety events and notifications with severity, category, and acknowledgement statuses.
- `TableName.usageDaily`: Daily application usage statistics in milliseconds (`total_ms`).
- `TableName.locationEvents`: Geofence transition and diagnostic breadcrumbs.

### 2.3 `LocalRowReader` & `LocalRowWriter`
Implement the standard `RowReader` and `RowWriter` contracts defined in `haven_api`.
- Supports equality filters (`eq`), ordering (`orderAsc`, `orderDesc`), and pagination limits (`limit`).
- Atomically processes inserts, updates, and deletes with automatic timestamping.
- Ensures duplicate key rejections on primary identity fields.

---

## 3. Local Repositories Implementation

Each feature domain uses a dedicated `Local*Repository` implementing the corresponding abstract interface:

| Domain | Interface | Local Implementation | Primary Tables |
|---|---|---|---|
| Dashboard | `DashboardRepository` | `LocalDashboardRepository` | `families`, `safety_alerts`, `devices`, `safe_zones`, `device_policies` |
| Family | `FamilyRepository` | `LocalFamilyRepository` | `families`, `family_members`, `profiles`, `devices` |
| Devices | `DevicesRepository` | `LocalDevicesRepository` | `devices`, `profiles` |
| Safe Zones | `SafeZonesRepository` | `LocalSafeZonesRepository` | `safe_zones` |
| Policies | `PoliciesRepository` | `LocalPoliciesRepository` | `device_policies` |
| Alerts | `AlertsRepository` | `LocalAlertsRepository` | `safety_alerts`, `devices` |
| Activity | `ActivityRepository` | `LocalActivityRepository` | `usage_daily`, `safety_alerts`, `location_events` |
| Settings | `SettingsRepository` | `HavenSettingsRepository` | `PreferencesStore` |

---

## 4. Demo Data Engine (`DemoDataSuite`)

The demo data system satisfies strict data isolation guarantees:
1. **Explicit Markers:** Every simulated record contains `is_demo = true` and IDs prefixed with `demo_`.
2. **Determinism:** Seeded timestamps, names, usage numbers, and geofence events are reproducible across test runs.
3. **Clean Teardown:** The `clearDemoData()` routine removes all rows matching `is_demo == true` or `id.startsWith('demo_')` without affecting genuine parent records.

