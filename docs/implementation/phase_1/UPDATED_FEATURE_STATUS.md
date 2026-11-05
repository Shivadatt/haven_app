# HAVEN PARENTAL CONTROL — UPDATED FEATURE STATUS MATRIX

**Scope**: Phase 1 Core Parent App Offline Foundation  
**Last Updated**: November 5, 2026  
**Status Key**:
- **COMPLETE**: Implemented, stabilized, verified offline without network, and covered by automated tests.
- **PARTIAL**: Basic parent UI and data models exist; live hardware/native enforcement deferred.
- **DEFERRED**: Explicitly excluded from Phase 1 scope (cloud backends, Android native OS management).
- **UNVERIFIED**: Untested or unvalidated (currently 0 in Phase 1 scope).

---

## 1. Phase 1 Core Modules Status

| Feature ID | Module & Feature | Status | Offline Storage / Mechanism | Test Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **F-001** | Offline Local Data Engine | **COMPLETE** | `OfflineHavenBackend` / `FileLocalStore` (`haven_local.json`) | 66 API tests, `local_store_test.dart` |
| **F-002** | Local Table Operations & Schema Constraints | **COMPLETE** | `LocalTables`, `LocalConstraints`, `LocalSchema` | `local_constraints_test.dart`, `stabilization_regression_test.dart` |
| **F-003** | Local Crash & Atomic Write Protection | **COMPLETE** | `.tmp` file atomic rename with copy fallback | `local_store_test.dart` |
| **F-004** | Parent Account Registration & Password Vault | **COMPLETE** | `LocalUserAuth`, `SecretVault` / `SecureVault` | `local_user_auth_test.dart` |
| **F-005** | Parent Sign-In & Local Session Gate | **COMPLETE** | Local password matching, in-memory `AuthSession` | `sign_in_page_test.dart`, `local_user_auth_test.dart` |
| **F-006** | Local Sign-Out & Session Lifetime | **COMPLETE** | Session drop, data & credentials preserved | `account_controller_test.dart`, `session_watch_test.dart` |
| **F-007** | Parent Onboarding — Ethics & Disclosure | **COMPLETE** | `OnboardingStep.explain`, `PreferenceKey.onboardingEthicsAcknowledged` | `onboarding_page_test.dart` |
| **F-008** | Parent Onboarding — Step Resumption | **COMPLETE** | Saved step in `PreferencesStore` (`onboarding.step`) | `onboarding_resumption_test.dart` |
| **F-009** | Family Creation & Scope Management | **COMPLETE** | `TableName.families`, `TableName.familyMembers` | `family_page_test.dart`, `family_scope_test.dart` |
| **F-010** | Child Profile Management (Create, Edit, Unlink)| **COMPLETE** | `TableName.profiles`, `TableName.familyMembers` | `child_profile_page_test.dart`, `local_family_mutations.dart` |
| **F-011** | Local Device Management (List, Rename, Revoke) | **COMPLETE** | `TableName.devices`, `LocalDevicesRepository` | `device_management_test.dart`, `device_detail_page_test.dart` |
| **F-012** | Local Pairing Simulation & Code Validation | **COMPLETE** | 6-digit code generator, 5-min timer, `SimulatedDevice` | `pairing_page_test.dart`, `pairing_simulation_page_test.dart` |
| **F-013** | Parent Dashboard State & Data Aggregation | **COMPLETE** | Multi-lane aggregation, pull-to-refresh, attention cards | `dashboard_page_test.dart`, `dashboard_controller_test.dart` |
| **F-014** | Safe Zones (Creation, Radius, Unique Names) | **COMPLETE** | `TableName.safeZones`, `SafeZoneRules` | `safe_zones_page_test.dart`, `safe_zone_create_page_test.dart` |
| **F-015** | Safe Zone Presence Calculation | **COMPLETE** | Haversine formula calculation (`SafeZonePresenceCalculator`) | `safe_zone_presence_test.dart` |
| **F-016** | Basic Parental Policy Configuration | **COMPLETE** | `TableName.devicePolicies`, `PolicyConfig` JSON | `policies_page_test.dart`, `local_policies_repository.dart` |
| **F-017** | Daily Screen Time Limits & Schedules | **COMPLETE** | Bedtime, school time, time allowances | `policies_controller_test.dart`, `schedules_card_test.dart` |
| **F-018** | Local Safety Alerts Feed & Triage | **COMPLETE** | `TableName.safetyAlerts`, acknowledge/unread | `notifications_page_test.dart`, `local_alerts_repository.dart` |
| **F-019** | Device Activity Timeline & Daily Usage | **COMPLETE** | `TableName.usageDaily`, `TimelineActivityEvent` | `activity_page_test.dart`, `local_activity_repository.dart` |
| **F-020** | Theme Selection (System, Light, Dark) | **COMPLETE** | `PreferencesStore` (`pref.theme_mode`), `ThemeChoice` | `settings_page_test.dart`, `theme_preference_test.dart` |
| **F-021** | Notification Preferences (Local Toggles) | **COMPLETE** | `PreferencesStore` (screen time, bedtime, zones) | `settings_page_test.dart` |
| **F-022** | Deterministic Demo Data Seeding & Isolation | **COMPLETE** | `DemoDataSuite`, `is_demo` tags, idempotent seed | `demo_data_suite_test.dart`, `demo_data_card_test.dart` |
| **F-023** | Clean Reset Operations (Demo vs Full Reset) | **COMPLETE** | `clearDemoData` vs `resetAll` + preference flush | `settings_profile_reset_test.dart`, `phase1_stabilization_test.dart` |

---

## 2. Deferred Capabilities (Explicitly Excluded from Phase 1)

| Capability Category | Specific Features | Target Phase | Reason for Exclusion in Phase 1 |
| :--- | :--- | :--- | :--- |
| **Cloud Backend** | Supabase Auth, PostgreSQL RLS, Edge Functions, Migrations | Phase 2 | Explicit brief restriction; Phase 1 is offline-first foundation. |
| **Push & Messaging**| Firebase Cloud Messaging (FCM), push token exchange | Phase 2 | Requires live Google Cloud/Firebase project endpoints. |
| **Real Device Pairing**| Remote QR scanning, network-based pairing exchange | Phase 2 | Replaced with Phase 1 Local Pairing Simulation. |
| **Android Native OS**| `AccessibilityService`, `DevicePolicyManager`, App Lock | Phase 3 | Requires Android native Kotlin plugins and child daemon. |
| **Network Filtering**| Android VpnService, DNS filtering, URL blocking | Phase 3 | Android OS-level networking integration. |
| **Live Remote Media**| WebRTC streaming, camera, microphone, screen share | Phase 4 | Advanced child monitoring media streaming. |
| **Real GPS Tracking** | Continuous Android background location service | Phase 3 | Native Android background geofencing service. |

