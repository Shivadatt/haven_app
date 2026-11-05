# UI / UX AND SCREEN INVENTORY AUDIT

**Target Location:** `D:\control\apps\haven_app\lib\features` and `lib\app\routes`  
**Audit Date:** 2026-11-05  
**Audit Standard:** Strict Evidence-Based Audit (Route-by-Route, Component-by-Component)  
**Execution Posture:** Read-Only Source Inspection + Widget Test Analysis

---

## 1. EXECUTIVE SUMMARY

1. **Complete Screen Inventory:** Exactly **26 routes** are defined in [`AppRoutes`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart) and registered in [`AppPages`](file:///d:/control/apps/haven_app/lib/app/routes/app_pages.dart). All 26 routes have corresponding page widgets, GetX bindings, and controllers.
2. **Zero Dummy/Mock Screens:** There are **zero decorative or fake mockup screens**. Screens do not display fake hardcoded statistics, dummy charts, or simulated data.
3. **The Refusal UI Pattern:** Where backend capability is absent, the UI explicitly renders typed refusal notices using [`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart) and [`StateView`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) quoting the exact architectural gap ([`docs/architecture/04-refusal-model.md`](file:///d:/control/docs/architecture/04-refusal-model.md)).
4. **Offline Widget Test Verification:** All screens are covered by 93 test files (720 passing tests in `apps/haven_app/test/`). Widget tests pump screens using hand-written repository fakes to verify loading, empty, blocked, and data states offline.
5. **End-to-End Reality:** **Zero screens function end-to-end against a live backend**, because staging runs 0 tables and 0 Edge Functions. When launched without `--dart-define` parameters, the app loads `UnconfiguredBackend` and presents honest refusal states.

---

## 2. COMPLETE SCREEN-BY-SCREEN INVENTORY (26 ROUTES)

| # | Route | Page Class & File | Binding Class | Controller Class | UI Status | Functional Status | UX & Refusal State Handling |
|---|---|---|---|---|---|---|---|
| 1 | `/` | `SplashPage`<br>[`splash_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/splash_page.dart#L18) | `SplashBindings` | `SplashController` | Complete | Partial | Awaits `startBackend()`. If unconfigured, renders backend status message ("Backend not configured"). Navigates to `/dashboard` if signed in, or `/sign-in`. |
| 2 | `/sign-in` | `SignInPage`<br>[`sign_in_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart#L18) | `SignInBindings` | `SignInController` | Complete | Partial | Form validation for email/password. Password toggle. Submits to `AuthRepository.signIn`. Firebase sign-in button triggers `signInWithFirebaseToken`, which displays `BlockedNotice` (A13 unsigned). |
| 3 | `/register` | `RegisterPage`<br>[`register_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/register_page.dart#L18) | `RegisterBindings` | `RegisterController` | Complete | Partial | Form validation (name, email, password min 8 chars). Handles email-confirmation-pending result without falsely claiming user is signed in. |
| 4 | `/session-ended` | `SessionEndedPage`<br>[`session_ended_page.dart:14`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/session_ended_page.dart#L14) | `SessionEndedBindings` | `SessionEndedController` | Complete | Complete (Offline) | Static notice explaining session expired or terminated remotely; button redirects to `/sign-in`. |
| 5 | `/onboarding` | `OnboardingPage`<br>[`onboarding_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart#L18) | `OnboardingBindings` | `OnboardingController` | Complete | Refuses at Seam | Parent onboarding flow (family name input, role selection). Calls `EdgeFunctionName.authBootstrap`. Fails closed at network seam. |
| 6 | `/dashboard` | `DashboardPage`<br>[`dashboard_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart#L18) | `DashboardBindings` | `DashboardController` | Complete | Partial | Top-level summary board. When family is unprovisioned, renders `_NeedsSetup` card with setup action rather than a fake empty state. Links to all features. |
| 7 | `/family` | `FamilyPage`<br>[`family_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/family_page.dart#L18) | `FamilyBindings` | `FamilyController` | Complete | Refuses at Seam | Lists parents and children. Add/remove parent actions display `BlockedNotice` quoting RPC EXECUTE grant wall ([`family_repository.dart:147, 156`](file:///d:/control/apps/haven_app/lib/features/family/data/family_repository.dart#L147)). |
| 8 | `/family/child` | `ChildProfilePage`<br>[`child_profile_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/child_profile_page.dart#L18) | `ChildProfileBindings` | `ChildProfileController` | Complete | Partial | Reads child profile and paired devices via `FamilyRepository`. Refuses mutations. |
| 9 | `/pairing` | `PairingPage`<br>[`pairing_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart#L13) | `PairingBindings` | `PairingController` | Complete | Refuses at Seam | Lists pending pairing requests from `pairing_requests`. Request withdrawal button renders `BlockedNotice`. Button navigates to `/pairing/code`. |
| 10 | `/pairing/code` | `PairingCodePage`<br>[`pairing_code_page.dart:16`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart#L16) | `PairingCodeBindings` | `PairingCodeController` | Complete | Refuses at Seam | Explains pairing protocol. Does not provide dummy input box; quotes exact missing edge contracts (`pairing` Edge Function undeployed). |
| 11 | `/devices` | `DevicesPage`<br>[`devices_page.dart:16`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/pages/devices_page.dart#L16) | `DevicesBindings` | `DevicesController` | Complete | Refuses at Seam | Refuses with `CapturedGaps.deviceLaneMissing` (Finding F6: `devices` table has no SELECT grant for `authenticated`). Renders `StateView` blocked state. |
| 12 | `/devices/detail` | `DeviceDetailPage`<br>[`device_detail_page.dart:19`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart#L19) | `DeviceDetailBindings` | `DeviceDetailController` | Complete | Refuses at Seam | Displays device details. Revoke and Recovery cards render `BlockedNotice` citing RPC EXECUTE and F6 grant walls. Embeds telemetry summary card. |
| 13 | `/devices/activity` | `ActivityPage`<br>[`activity_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart#L13) | `ActivityBindings` | `ActivityController` | Complete | Refuses at Seam | Reads `usage_daily` table. Renders `UsageLimitsCard` explaining that devices are left unnamed due to F6 grant wall. |
| 14 | `/devices/commands` | `CommandsPage`<br>[`commands_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/device_commands/views/pages/commands_page.dart#L12) | `CommandsBindings` | `CommandsController` | Complete | Refuses at Seam | Reads `device_commands`. Renders `CommandLimitsCard` explicitly stating that writing, cancelling, or sending commands is closed by RLS. |
| 15 | `/devices/policies` | `PoliciesPage`<br>[`policies_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/policies/views/pages/policies_page.dart#L12) | `PoliciesBindings` | `PoliciesController` | Complete | Refuses at Seam | Reads `device_policies`. Renders `PolicyLimitsCard` explaining that policy modification is blocked by missing bundle constants V/X/Z and RLS. |
| 16 | `/devices/location` | `LocationPage`<br>[`location_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/location/views/pages/location_page.dart#L12) | `LocationBindings` | `LocationController` | Complete | Refuses at Seam | Reads `location_events`. Renders coordinates without invented precision. Renders `PresenceCard` stating refusal for geofencing (`safe_zone_states` is deny-all). |
| 17 | `/safe-zones` | `SafeZonesPage`<br>[`safe_zones_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zones_page.dart#L12) | `SafeZonesBindings` | `ZonesController` | Complete | Partial | Lists safe zones from `safe_zones` table. Local geometry calculation (`Haversine`). Add zone button navigates to `/safe-zones/editor`. |
| 18 | `/safe-zones/editor` | `SafeZoneEditorPage`<br>[`safe_zone_editor_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart#L13) | `ZoneEditorBindings` | `ZoneEditorController` | Complete | Partial | Name, latitude, longitude, radius form with full validation. Calls `ZonesRepository.save` (one of the few client-permitted tables). |
| 19 | `/remote-sessions` | `RemoteSessionsPage`<br>[`remote_sessions_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_sessions_page.dart#L12) | `SessionsBindings` | `SessionsController` | Complete | Refuses at Seam | Reads `remote_sessions`. Renders request refusal notice (`SessionGaps.startGap`) citing RPC privilege wall. |
| 20 | `/remote-session` | `RemoteSessionDetailPage`<br>[`remote_session_detail_page.dart:13`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart#L13) | `SessionDetailBindings` | `SessionDetailController` | Complete | Refuses at Seam | Displays session status. Media peer is `UnspecifiedMediaPeer`, which refuses audio/video streaming (`SessionGaps.mediaMissing`, no TURN server). |
| 21 | `/notifications` | `NotificationsPage`<br>[`notifications_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/notifications/views/pages/notifications_page.dart#L12) | `NotificationsBindings` | `NotificationsController` | Complete | Refuses at Seam | Reads `safety_alerts`. Renders `DeliveryCard` explaining push delivery gap (A12-R unsigned, no `push_tokens` table, no send function). |
| 22 | `/account` | `AccountPage`<br>[`account_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/account/views/pages/account_page.dart#L12) | `AccountBindings` | `AccountController` | Complete | Partial | Displays profile details. Change password/email and delete account render `BlockedNotice` (no backend contract). Logout action is functional. |
| 23 | `/settings` | `SettingsPage`<br>[`settings_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/settings_page.dart#L12) | `SettingsBindings` | `SettingsController` | Complete | Complete (Local) | Theme selection (System, Light, Dark) persisted via `VaultPreferences`. Only feature with working local storage! Links to permissions and about. |
| 24 | `/settings/permissions` | `PermissionStatusPage`<br>[`permission_status_page.dart:18`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart#L18) | `PermissionStatusBindings` | `SettingsController` | Complete | Complete (Native Bridge) | Invokes `MethodChannel('haven.dev/child_device_state')`. Displays Android OS diagnostics (API level, release, service counts, permissions). |
| 25 | `/settings/about` | `AboutPage`<br>[`about_page.dart:12`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/about_page.dart#L12) | `AboutBindings` | `AboutController` | Complete | Complete (Local) | Displays app version, git revision, build timestamp, environment configuration, and lists missing `--dart-define` names via `HavenConfig.missingDefines()`. |
| 26 | `/unknown` | `NotFoundPage`<br>[`not_found_page.dart:14`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/not_found_page.dart#L14) | None | None | Complete | Complete | Fallback 404 handler for unknown routes. Explicitly displays `"Screen not implemented"` with the target route name, rather than redirecting. |

---

## 3. UI/UX EVALUATION CRITERIA & COMPLIANCE

### 3.1 Button & Action Connectivity
- **Findings:** Every single button in every view is connected to a controller method. There are no dangling `onPressed: () {}` or unhandled callbacks.
- Where an action cannot succeed at the backend, the controller triggers a typed failure or routes to an explanatory screen (e.g. `goToPairing`, `goToSetup`).

### 3.2 Form Validation
- **Sign-In Form:** Validates non-empty email format and non-empty password ([`sign_in_page.dart:53`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart#L53)).
- **Register Form:** Validates display name length, email regex, and password min 8 characters ([`register_page.dart:61`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/register_page.dart#L61)).
- **Safe Zone Editor Form:** Validates zone name, latitude (-90 to 90), longitude (-180 to 180), and radius (10m to 10,000m) ([`safe_zone_editor_page.dart:73-110`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart#L73-L110)).

### 3.3 State Representation (Loading, Empty, Error, Blocked, Success)
- Managed centrally by [`StateView<T>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart):
  - **Loading:** Displays `HavenProgressIndicator` when `isLoading == true`.
  - **Empty:** Renders custom empty state widget (e.g. `_NeedsSetup` or `_NoDevices`).
  - **Error:** Displays `ErrorCard` with human-readable error message and retry button.
  - **Blocked:** Automatically intercepted when result is `BlockedFailure`, rendering `BlockedNotice` with requirement and missing reason.
  - **Success / Data:** Renders typed content via `onData(context, data)`.

### 3.4 Responsiveness & Visual Cleanliness
- All pages use `HavenScaffold` with consistent typography (`HavenText`), spacing (`HavenSpacing`), and color palettes (`HavenTheme`).
- Body content wrapped in `SingleChildScrollView` or `ListView` with responsive gutter padding.
- Pull-to-refresh (`onRefresh: controller.refresh`) supported across list pages.

---

## 4. SCREENS WITH HARDCODED / MOCK DATA AUDIT

- **Zero Mock Data Screens:** A strict search across `apps/haven_app/lib/features/` confirms that no view displays hardcoded fake children, mock locations, or synthetic charts.
- **Fakes in Test Only:** Fake data exists strictly within `apps/haven_app/test/support/` (`data_fakes.dart`, `backend_fakes.dart`, `fakes.dart`) for headless widget test harness verification.

