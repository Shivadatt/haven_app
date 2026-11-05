# Implemented Feature Matrix — Phase 1

This matrix details the implementation status of all features approved in the Phase 1 Core Parent App Offline Foundation scope.

| Module | Feature | Implementation Details | Status | Verified Tests |
|---|---|---|---|---|
| **Offline Foundation** | Local SQLite/KV Storage | `LocalTables` with schema tables for all entities | Implemented | `local_tables_test.dart` |
| | Row Read/Write Contract | `LocalRowReader`, `LocalRowWriter` | Implemented | `local_row_engine_test.dart` |
| | Offline Backend Engine | `OfflineHavenBackend` singleton with environment switch | Implemented | `offline_haven_backend_test.dart` |
| | Demo Data Seeding & Isolation | `DemoDataSuite`, `DemoDataRecords` with explicit demo tags | Implemented | `demo_data_suite_test.dart` |
| **Parent Auth & Session** | Local Parent Account Creation | `LocalUserAuth` with password hashing & local session | Implemented | `local_user_auth_test.dart` |
| | Local Session Persistence | Stores active session token in `PreferencesStore` | Implemented | `auth_controller_test.dart` |
| | Edit Parent Profile | Profile name updating in `LocalTables.profiles` | Implemented | `account_profile_edit_test.dart` |
| | Honest Offline Indicator | Badges and captions signaling offline session | Implemented | `account_page_test.dart` |
| **Parent Onboarding** | Step 1: Parent Account | Email/password setup with form validation | Implemented | `onboarding_controller_test.dart` |
| | Step 2: Family Setup | Family name creation with character bounds | Implemented | `onboarding_validation_test.dart` |
| | Step 3: First Child Setup | Child name, age bracket, avatar selection | Implemented | `onboarding_child_step_test.dart` |
| | Step 4: Pairing Overview | Guidance and pairing simulation onboarding step | Implemented | `onboarding_pairing_step_test.dart` |
| | Progress Persistence | Multi-step progress resumed from `PreferencesStore` | Implemented | `onboarding_progress_test.dart` |
| **Family & Child** | Family Creation & Renaming | CRUD in `LocalFamilyRepository` and `LocalFamilyMutations` | Implemented | `family_controller_test.dart` |
| | Add Child Profile | Full child profile registration | Implemented | `child_profile_management_test.dart` |
| | Edit Child Details | Name, age bracket, and avatar updating | Implemented | `child_profile_controller_test.dart` |
| | Child Unlinking with Cascade | Revokes associated device credentials safely | Implemented | `family_mutations_test.dart` |
| **Device Management** | Device List & Overview | Overview of registered child devices | Implemented | `device_management_test.dart` |
| | Add Local Device | Form with platform selector and child assignment | Implemented | `add_device_dialog_test.dart` |
| | Rename Local Device | Inline renaming persisted to `TableName.devices` | Implemented | `rename_device_dialog_test.dart` |
| | Revoke / Unlink Device | Sets status to `revoked` with timestamp | Implemented | `device_detail_controller_test.dart` |
| **Pairing Simulation** | 6-Digit Code Generation | Random 6-digit alphanumeric code generation | Implemented | `pairing_simulation_test.dart` |
| | Expiry Countdown Timer | 10-minute expiry with visual countdown | Implemented | `pairing_timer_test.dart` |
| | Code Verification & Binding | Consumes code and pairs simulated device | Implemented | `pairing_controller_test.dart` |
| **Parent Dashboard** | Aggregated Overview | Family, child, device, policy, alert cards | Implemented | `dashboard_page_test.dart` |
| | Loading / Empty / Error Views | Reactive states for all edge cases | Implemented | `dashboard_states_test.dart` |
| | Active Policies Summary | Displays live count of active restrictions | Implemented | `active_policies_card_test.dart` |
| | Recent Activity Feed | Combined usage, alerts, and location feed | Implemented | `recent_activities_card_test.dart` |
| **Safe Zones** | Safe Zone List | Displays configured zones with radius badges | Implemented | `safe_zones_page_test.dart` |
| | Create / Edit / Delete Zone | Zone name, lat/lon, radius (50m-5km) | Implemented | `local_safe_zones_test.dart` |
| | Haversine Distance Calc | Spherical geometry distance in pure Dart | Implemented | `zones_geometry_test.dart` |
| | Inside / Outside Evaluation | Evaluates point-in-radius against zone bounds | Implemented | `zones_evaluation_test.dart` |
| **Parental Policies** | Daily Screen Time Limits | Validates and sets daily limit (15-720 min) | Implemented | `policies_screen_time_test.dart` |
| | Bedtime & School Schedules | Start/end times, active days (weekdays/weekends) | Implemented | `policies_schedules_test.dart` |
| | App Allowed/Blocked Lists | Package ID filtering persisted to policies | Implemented | `policies_apps_test.dart` |
| | Website Domain Filters | Allowed/blocked domain list management | Implemented | `policies_web_test.dart` |
| **Alerts & Activity** | Local Safety Alerts Board | Safety alerts with category & severity badges | Implemented | `local_alerts_repository_test.dart` |
| | Mark as Read / Unread | Updates `acknowledged_at` in `safety_alerts` | Implemented | `report_card_test.dart` |
| | Delete Alert | Removes individual alert records | Implemented | `alert_detail_dialog_test.dart` |
| | Daily App Usage Timeline | Visual timeline with app labels and durations | Implemented | `local_activity_repository_test.dart` |
| **Settings & Preferences** | Theme Mode Switcher | Dark, light, and system theme persistence | Implemented | `settings_preferences_test.dart` |
| | Demo Data Controls | Toggle to load or purge deterministic demo data | Implemented | `demo_data_card_test.dart` |

