# HAVEN Parental Control — GetX Architecture & State Management Audit

**Document:** `GETX_ARCHITECTURE_AUDIT.md`  
**Scope:** `apps/haven_app/lib/` (Controllers, Bindings, Routes, Views, Lifecycle, Cleanup, Memory Leaks)  
**Date:** November 2026  
**Auditor:** Frontend Architect & GetX Specialist  
**Status:** Complete Audit  

---

## Executive Summary

The HAVEN Parental Control application frontend implements state management using the **GetX** ecosystem (`get: ^4.6.6`). The codebase exhibits exceptional architectural discipline in enforcing strict data contracts, non-fabrication of backend state, and typed route arguments.

However, the audit identified critical structural vulnerabilities and GetX anti-patterns:
1. **Method Collision with Built-in `GetxController.refresh()`**: 12 controllers override `Future<void> refresh() async`, masking GetX's native reactive `void refresh() => update()` mechanism.
2. **Systemic Async Lifecycle Safety Gaps**: 19 of 23 controllers perform state assignments after `await` operations without checking `isClosed`. In `refresh()` methods and authentication flows (`SignInController`, `RegisterController`, `OnboardingController`, `SplashController`), `isClosed` is completely omitted, risking state corruption or unmounted reactive updates.
3. **Dependency Ownership & Collision Anti-Patterns**:
   - `DeviceDetailBindings` mounts `TelemetryController` via `TelemetryDependencies.ensureController(deviceId)` without tag-based registration or route lifecycle scoping, leading to singleton stale state across multiple device navigations.
   - `SettingsBindings` and `PermissionStatusBindings` share an untagged `SettingsController`, leading to route binding lifecycle conflicts.
   - `HavenBackend.install()` registers core backend seams (`RowReader`, `RowWriter`, `UserAuth`, etc.) using `Get.put()` without `permanent: true`, leaving them vulnerable to route eviction.
   - `InitialBindings.register(config)` is invoked directly inside `HavenApp.build(BuildContext context)`, re-executing on every framework rebuild.
4. **Memory Leak Prevention Verification**: All 6 controllers managing `TextEditingController` instances properly dispose of them in `onClose()`. All 3 controllers managing `StreamSubscription` instances cancel them in `onClose()`. No GetX workers (`ever`, `debounce`, `interval`) are currently utilized.

---

## 1. Controller Audit Matrix (23 Controllers)

| # | Controller Class | File Path | Lifecycles | TextControllers Disposed | Subscriptions Cancelled | `isClosed` Safety Status |
|---|------------------|-----------|:----------:|:------------------------:|:-----------------------:|:------------------------:|
| 1 | [`AccountController`](file:///d:/control/apps/haven_app/lib/features/account/controllers/account_controller.dart#L14-L108) | `features/account/controllers/account_controller.dart` | `onInit`, `onClose` | `displayName` (L46) | N/A | Partial (Gaps in L53-55) |
| 2 | [`RegisterController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart#L16-L83) | `features/authentication/controllers/register_controller.dart` | `onClose` | `displayName`, `email`, `password` (L41-43) | N/A | **FAILED** (Missing in `submit`) |
| 3 | [`SignInController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart#L16-L96) | `features/authentication/controllers/sign_in_controller.dart` | `onClose` | `email`, `password` (L41-42) | N/A | **FAILED** (Missing in `submit` & route) |
| 4 | [`SplashController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/splash_controller.dart#L16-L89) | `features/authentication/controllers/splash_controller.dart` | `onInit` | N/A | N/A | **FAILED** (Missing in `start`) |
| 5 | [`DevicesController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/devices_controller.dart#L15-L52) | `features/child_devices/controllers/devices_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L45) |
| 6 | [`DeviceDetailController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/device_detail_controller.dart#L14-L72) | `features/child_devices/controllers/device_detail_controller.dart` | `onInit` | N/A | N/A | Partial (Assigned before L53) |
| 7 | [`DashboardController`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart#L13-L108) | `features/dashboard/controllers/dashboard_controller.dart` | `onInit` | N/A | N/A | Partial (L49 assigned before L50) |
| 8 | [`ActivityController`](file:///d:/control/apps/haven_app/lib/features/device_activity/controllers/activity_controller.dart#L13-L61) | `features/device_activity/controllers/activity_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L52) |
| 9 | [`CommandsController`](file:///d:/control/apps/haven_app/lib/features/device_commands/controllers/commands_controller.dart#L13-L60) | `features/device_commands/controllers/commands_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L53) |
| 10 | [`PairingCodeController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_code_controller.dart#L14-L66) | `features/device_pairing/controllers/pairing_code_controller.dart` | `onInit` | N/A | N/A | Partial (Assigned before L44) |
| 11 | [`PairingController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart#L13-L89) | `features/device_pairing/controllers/pairing_controller.dart` | `onInit` | N/A | N/A | Partial (Assigned before L47) |
| 12 | [`ChildProfileController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/child_profile_controller.dart#L15-L84) | `features/family/controllers/child_profile_controller.dart` | `onInit` | N/A | N/A | Partial (Assigned before L51) |
| 13 | [`FamilyController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/family_controller.dart#L14-L95) | `features/family/controllers/family_controller.dart` | `onInit`, `onClose` | `familyName` (L49) | N/A | Partial (Assigned before L58) |
| 14 | [`LocationController`](file:///d:/control/apps/haven_app/lib/features/location/controllers/location_controller.dart#L14-L64) | `features/location/controllers/location_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L53) |
| 15 | [`NotificationsController`](file:///d:/control/apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart#L18-L98) | `features/notifications/controllers/notifications_controller.dart` | `onInit`, `onClose` | N/A | `_watch` (L61) | Partial (Missing in `refresh` L86) |
| 16 | [`OnboardingController`](file:///d:/control/apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart#L17-L100) | `features/onboarding/controllers/onboarding_controller.dart` | `onClose` | `familyName` (L47) | N/A | **FAILED** (Missing in `finish`) |
| 17 | [`PoliciesController`](file:///d:/control/apps/haven_app/lib/features/policies/controllers/policies_controller.dart#L13-L57) | `features/policies/controllers/policies_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L50) |
| 18 | [`SessionsController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart#L17-L93) | `features/remote_sessions/controllers/sessions_controller.dart` | `onInit`, `onClose` | N/A | `_watch` (L54) | Partial (Missing in `refresh` L85) |
| 19 | [`SessionDetailController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/session_detail_controller.dart#L17-L102) | `features/remote_sessions/controllers/session_detail_controller.dart` | `onInit`, `onClose` | N/A | `_watch` (L52) | Partial (Missing in `refresh` L93) |
| 20 | [`SafeZonesController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zones_controller.dart#L13-L58) | `features/safe_zones/controllers/zones_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L49) |
| 21 | [`SafeZoneEditorController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart#L17-L156) | `features/safe_zones/controllers/zone_editor_controller.dart` | `onInit`, `onClose` | `name`, `lat`, `lng`, `radiusM` (L67-70) | N/A | **PASS** (Protected at all awaits) |
| 22 | [`SettingsController`](file:///d:/control/apps/haven_app/lib/features/settings/controllers/settings_controller.dart#L15-L102) | `features/settings/controllers/settings_controller.dart` | `onInit` | N/A | N/A | **PASS** (Protected at all awaits) |
| 23 | [`TelemetryController`](file:///d:/control/apps/haven_app/lib/features/telemetry/controllers/telemetry_controller.dart#L13-L48) | `features/telemetry/controllers/telemetry_controller.dart` | `onInit` | N/A | N/A | Partial (Missing in `refresh` L43) |

---

## 2. In-Depth Controller Lifecycle & Memory Leak Inspection

### 2.1 TextEditingController Disposal in `onClose()`
All controllers instantiating `TextEditingController` instances consistently dispose of them within `onClose()`:
- [`AccountController`](file:///d:/control/apps/haven_app/lib/features/account/controllers/account_controller.dart#L44-L48):
  ```dart
  @override
  void onClose() {
    displayName.dispose();
    super.onClose();
  }
  ```
- [`RegisterController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart#L39-L45):
  Disposes `displayName`, `email`, and `password`.
- [`SignInController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart#L39-L44):
  Disposes `email` and `password`.
- [`FamilyController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/family_controller.dart#L47-L51):
  Disposes `familyName`.
- [`OnboardingController`](file:///d:/control/apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart#L45-L49):
  Disposes `familyName`.
- [`SafeZoneEditorController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart#L65-L72):
  Disposes `name`, `lat`, `lng`, and `radiusM`.

> [!NOTE]
> In [`SafeZoneEditorController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart#L57-L61), `addListener(_touch)` is registered during `onInit()` on each controller. While disposing `TextEditingController` cleans up internal listeners, invoking `removeListener(_touch)` explicitly prior to disposal adheres to strict Dart memory management hygiene.

### 2.2 StreamSubscription Cancellation in `onClose()`
Controllers maintaining active `StreamSubscription` instances cancel them cleanly:
- [`NotificationsController`](file:///d:/control/apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart#L60-L64):
  `_watch?.cancel(); _watch = null;` correctly cancels subscription to `TableName.safetyAlerts`.
- [`SessionsController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart#L52-L57):
  `_watch?.cancel(); _watch = null;` correctly cancels subscription to `TableName.remoteSessions`.
- [`SessionDetailController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/session_detail_controller.dart#L50-L55):
  `_watch?.cancel(); _watch = null;` correctly cancels subscription to `TableName.webrtcSignals`.
- [`SessionWatch`](file:///d:/control/apps/haven_app/lib/features/authentication/services/session_watch.dart#L56-L60):
  `_sub?.cancel(); _sub = null;` cancels authentication state stream on disposal.

Stream listeners in `NotificationsController` (L72), `SessionsController` (L66), and `SessionDetailController` (L69) all check `if (!isClosed) load();` prior to re-invoking data loads upon incoming socket hints.

### 2.3 GetX Workers Audit
Zero workers (`ever`, `debounce`, `interval`, `once`) are registered in any controller. In [`SafeZoneEditorController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zone_editor_controller.dart#L52-L63), reactivity for text fields is manually stimulated by incrementing an observable counter (`final RxInt revision = 0.obs;`) via `addListener(_touch)`.

---

## 3. Critical Structural Issues & Antipatterns

### 3.1 Method Collision: `@override Future<void> refresh() async`
In GetX, `GetxController` inherits from `GetLifeCycleBase`, which defines:
```dart
void refresh() {
  update();
}
```
In 12 controllers ([`DevicesController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/devices_controller.dart#L44-L46), [`DashboardController`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart#L57-L62), [`ActivityController`](file:///d:/control/apps/haven_app/lib/features/device_activity/controllers/activity_controller.dart#L50-L55), [`CommandsController`](file:///d:/control/apps/haven_app/lib/features/device_commands/controllers/commands_controller.dart#L51-L56), [`PairingController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart#L54-L59), [`LocationController`](file:///d:/control/apps/haven_app/lib/features/location/controllers/location_controller.dart#L51-L56), [`NotificationsController`](file:///d:/control/apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart#L84-L87), [`PoliciesController`](file:///d:/control/apps/haven_app/lib/features/policies/controllers/policies_controller.dart#L48-L53), [`SessionsController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart#L83-L86), [`SessionDetailController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/session_detail_controller.dart#L90-L94), [`SafeZonesController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zones_controller.dart#L47-L50), [`TelemetryController`](file:///d:/control/apps/haven_app/lib/features/telemetry/controllers/telemetry_controller.dart#L41-L46)), the authors wrote:
```dart
@override
Future<void> refresh() async {
  board.value = await _repository.load(...);
}
```
> [!WARNING]
> This breaks the GetX contract:
> 1. It changes the return type from `void` to `Future<void>`.
> 2. It overrides GetX's internal `refresh()` trigger, which disables `update()` notifications for any widgets relying on `GetBuilder` or GetX lifecycle event notifications.
> 3. These methods should be named `reload()` or `refreshData()`, and passed to `HavenScaffold(onRefresh: controller.reload)`.

### 3.2 Async Lifecycle Safety Violations
When an asynchronous method resumes after `await`, if the user has navigated away, the controller may already be closed (`isClosed == true`). Writing to reactive variables (`.value = ...`) or triggering navigation on a closed controller can throw unhandled runtime exceptions or leak memory.

The codebase exhibits three distinct async vulnerability patterns:

#### Pattern A: Missing `isClosed` in Authentication & Setup Flows
- [`RegisterController.submit()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart#L57-L79):
  ```dart
  busy.value = true;
  final Result<AuthSession> created = await _repository.register(...);
  final HavenFailure? failure = created.failureOrNull;
  busy.value = false; // <--- NO isClosed check!
  if (failure != null) {
    formError.value = failure.message; // <--- Unsafe
    return;
  }
  password.clear();
  _goTo(AppRoutes.onboarding, null); // <--- Unsafe navigation
  ```
- [`SignInController.submit()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart#L56-L92):
  No check after `_repository.signIn(...)` or `_repository.profileFor(...)`.
- [`OnboardingController.finish()`](file:///d:/control/apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart#L65-L98):
  Performs 3 sequential awaits (`currentSession()`, `claimParentRole()`, `createFamily(...)`) without verifying `isClosed` before mutating `busy`, `message`, or triggering `_goTo`.
- [`SplashController.start()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/splash_controller.dart#L44-L82):
  Sequential awaits without checking `isClosed`.

#### Pattern B: Unsafe Gap Assignments in `load()`
In [`AccountController`](file:///d:/control/apps/haven_app/lib/features/account/controllers/account_controller.dart#L50-L57), [`DeviceDetailController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/device_detail_controller.dart#L49-L54), [`DashboardController`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart#L47-L52), [`PairingCodeController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_code_controller.dart#L40-L46), [`PairingController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart#L65-L72), [`ChildProfileController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/child_profile_controller.dart#L47-L52), and [`FamilyController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/family_controller.dart#L53-L59), gap failures are awaited and assigned sequentially *before* `if (isClosed) return;`:
```dart
// Example from DeviceDetailController:
isLoading.value = true;
device.value = await _repository.device(deviceId);               // <--- Unsafe write
revokeGap.value = _blocked(await _repository.revoke(deviceId));  // <--- Unsafe write
recoveryGap.value = _blocked(await _repository.requestRecovery(deviceId)); // <--- Unsafe write
if (isClosed) return; // <--- TOO LATE!
isLoading.value = false;
```
If the user opens and immediately backs out of the screen, 3 reactive mutations execute against a destroyed controller.

#### Pattern C: Unchecked `refresh()` Body
In all 11 pull-to-refresh implementations ([`DevicesController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/devices_controller.dart#L45), [`ActivityController`](file:///d:/control/apps/haven_app/lib/features/device_activity/controllers/activity_controller.dart#L52), [`CommandsController`](file:///d:/control/apps/haven_app/lib/features/device_commands/controllers/commands_controller.dart#L53), [`LocationController`](file:///d:/control/apps/haven_app/lib/features/location/controllers/location_controller.dart#L53), [`NotificationsController`](file:///d:/control/apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart#L86), [`PoliciesController`](file:///d:/control/apps/haven_app/lib/features/policies/controllers/policies_controller.dart#L50), [`SessionsController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart#L85), [`SessionDetailController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/session_detail_controller.dart#L93), [`SafeZonesController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zones_controller.dart#L49), [`TelemetryController`](file:///d:/control/apps/haven_app/lib/features/telemetry/controllers/telemetry_controller.dart#L43)), the code reads:
```dart
@override
Future<void> refresh() async {
  board.value = await _repository.load(...); // <--- Direct assignment without isClosed check!
}
```
Only [`DashboardController.refresh()`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart#L58-L62) correctly includes `if (isClosed) return;`.

---

## 4. Bindings, Dependency Ownership & Injection Architecture

### 4.1 Global Initial Bindings
In [`InitialBindings`](file:///d:/control/apps/haven_app/lib/app/bindings/initial_bindings.dart#L28-L58):
```dart
Get.put<HavenConfig>(config, permanent: true);
Get.put<SecretVault>(SecureVault(), permanent: true);
Get.put<PreferencesStore>(VaultPreferences(() => Get.find<SecretVault>()), permanent: true);
```
- **Flaw**: In [`HavenApp.build()`](file:///d:/control/apps/haven_app/lib/app/app.dart#L18), `InitialBindings.register(config)` is invoked inside the Flutter `build()` method. While it guards with `if (_registered && Get.isRegistered<HavenConfig>()) return;`, executing DI registration within a build method violates Flutter architecture guidelines. This should be executed in `main()` before `runApp()`.
- **Flaw in Backend Registration**: In [`HavenBackend.install()`](file:///d:/control/apps/haven_api/lib/src/haven_backend.dart#L48-L89), services (`RowReader`, `RowWriter`, `RpcCaller`, `EdgeCaller`, `ChangeFeed`, `UserAuth`, `ProfileStore`, `PushTransport`, `DeviceIdentity`) are registered via `Get.put()` **without** `permanent: true`. When GetX performs automatic garbage collection on route transitions under `SmartManagement.full`, these dependencies risk being dropped.

### 4.2 Route Argument & Scoping Collisions

#### A. TelemetryController Scoping Collision
In [`ChildDevicesDependencies`](file:///d:/control/apps/haven_app/lib/features/child_devices/bindings/child_devices_bindings.dart#L50):
```dart
TelemetryDependencies.ensureController(deviceId);
```
And in [`TelemetryDependencies`](file:///d:/control/apps/haven_app/lib/features/telemetry/bindings/telemetry_dependencies.dart#L35-L42):
```dart
static TelemetryController ensureController(String deviceId) {
  if (!Get.isRegistered<TelemetryController>()) {
    Get.put<TelemetryController>(
      TelemetryController(repository: ensureRepository(), deviceId: deviceId),
    );
  }
  return Get.find<TelemetryController>();
}
```
> [!CAUTION]
> Because `TelemetryController` holds a specific `deviceId`, registering it untagged using `if (!Get.isRegistered<TelemetryController>())` produces a serious bug:
> If a parent opens Device A, returns to the device list, and opens Device B, `Get.isRegistered<TelemetryController>()` returns `true` (if not yet garbage collected), serving Device A's telemetry on Device B's detail page!
> **Remediation**: Use tagged registration: `Get.put<TelemetryController>(..., tag: deviceId)` or tie the controller directly to `DeviceDetailController`.

#### B. SettingsController Multi-Route Sharing
In [`settings_bindings.dart`](file:///d:/control/apps/haven_app/lib/features/settings/bindings/settings_bindings.dart#L44-L52):
```dart
final class SettingsBindings extends Bindings {
  @override
  void dependencies() => SettingsDependencies.ensureController();
}

final class PermissionStatusBindings extends Bindings {
  @override
  void dependencies() => SettingsDependencies.ensureController();
}
```
Both `/settings` and `/settings/permissions` share an untagged `SettingsController`. When navigating from Settings into Permission Status and popping back, GetX's route-binding lifecycle manager attempts to delete the controller associated with `/settings/permissions`, leaving the parent `SettingsPage` with a disposed or detached controller.
**Remediation**: Provide a dedicated `PermissionStatusController` for `/settings/permissions`.

---

## 5. Route Table & Navigation Audit

[`AppRoutes`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart) defines 25 explicit route constants. [`AppPages`](file:///d:/control/apps/haven_app/lib/app/routes/app_pages.dart) maps all 25 routes to distinct `GetPage` entries, with fallback to `unknown` -> `NotFoundPage`.

| Route Constant | Path | Page Class | Binding Class | Parameter Scheme |
|----------------|------|------------|---------------|------------------|
| `splash` | `/` | `SplashPage` | `SplashBindings` | None |
| `signIn` | `/sign-in` | `SignInPage` | `SignInBindings` | None |
| `register` | `/register` | `RegisterPage` | `RegisterBindings` | None |
| `sessionEnded` | `/session-ended` | `SessionEndedPage` | `SessionEndedBindings` | `Get.arguments` (String reason) |
| `onboarding` | `/onboarding` | `OnboardingPage` | `OnboardingBindings` | None |
| `dashboard` | `/dashboard` | `DashboardPage` | `DashboardBindings` | None |
| `family` | `/family` | `FamilyPage` | `FamilyBindings` | None |
| `childProfile` | `/family/child` | `ChildProfilePage` | `ChildProfileBindings` | `Get.arguments` (String childUserId) |
| `pairing` | `/pairing` | `PairingPage` | `PairingBindings` | None |
| `pairingCode` | `/pairing/code` | `PairingCodePage` | `PairingCodeBindings` | `Get.arguments` (String familyId) |
| `devices` | `/devices` | `DevicesPage` | `DevicesBindings` | None |
| `deviceDetail` | `/devices/detail` | `DeviceDetailPage` | `DeviceDetailBindings` | `Get.arguments` (`DeviceRouteArgs`) |
| `activity` | `/devices/activity` | `ActivityPage` | `ActivityBindings` | `Get.arguments` (String deviceId) |
| `commands` | `/devices/commands` | `CommandsPage` | `CommandsBindings` | `Get.arguments` (String deviceId) |
| `policies` | `/devices/policies` | `PoliciesPage` | `PoliciesBindings` | `Get.arguments` (String deviceId) |
| `location` | `/devices/location` | `LocationPage` | `LocationBindings` | `Get.arguments` (String deviceId) |
| `safeZones` | `/safe-zones` | `SafeZonesPage` | `SafeZonesBindings` | None |
| `safeZoneEditor` | `/safe-zones/editor` | `SafeZoneEditorPage` | `ZoneEditorBindings` | `Get.arguments` (String zoneId) |
| `remoteSessions` | `/remote-sessions` | `RemoteSessionsPage` | `SessionsBindings` | None |
| `remoteSessionDetail` | `/remote-session` | `RemoteSessionDetailPage` | `SessionDetailBindings` | `Get.arguments` (String sessionId) |
| `notifications` | `/notifications` | `NotificationsPage` | `NotificationsBindings` | None |
| `account` | `/account` | `AccountPage` | `AccountBindings` | None |
| `settings` | `/settings` | `SettingsPage` | `SettingsBindings` | None |
| `permissionStatus` | `/settings/permissions` | `PermissionStatusPage` | `PermissionStatusBindings` | None |
| `about` | `/settings/about` | `AboutPage` | `AboutBindings` | None |
| `unknown` | `/unknown` | `NotFoundPage` | None | `Get.currentRoute` |

---

## 6. Business Logic Leaks in Views & Missing Controllers

### 6.1 Logic Leaking into Views
1. **Direct Navigation Bypassing Controller**:
   - In [`SignInPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart#L134):
     `onPressed: () => Get.toNamed(AppRoutes.register)` is called directly in the widget tree, bypassing [`SignInController.goRegister()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart#L94).
2. **String Interpolation & Domain Formatting in Views**:
   - In [`DashboardPage._counted`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart#L46-L51): Pluralization and count formatting is calculated inside the private widget rather than on `FamilyBundle` or `DashboardController`.
   - In [`SafeZoneEditorPage._day`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart#L155-L156): Date formatting (`day/month/year`) is hard-coded in the view instead of using [`havenDay()`](file:///d:/control/apps/haven_app/lib/core/utils/haven_time.dart).
   - In [`ZoneRow._radius`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/widgets/zones_card.dart#L53): Radius is formatted as `"${zone.radiusM.toStringAsFixed(0)} m across"`, misrepresenting radius as diameter.
3. **DI Retrieval Inside `build()`**:
   - In [`BackendBanner`](file:///d:/control/apps/haven_app/lib/shared/components/backend_banner.dart#L21-L22): `Get.isRegistered<HavenConfig>()` and `Get.find<HavenConfig>()` are called in the widget `build()`.
   - In [`AboutPage`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/about_page.dart#L32-L34): `Get.find<HavenConfig>()` is called directly in `build()`.

### 6.2 Missing Dedicated Controllers
1. **`SessionEndedPage`**:
   Implements no controller (`SessionEndedBindings` is empty). The widget directly parses `Get.arguments` in its `build()` method (L21-24) and directly executes `Get.offAllNamed(AppRoutes.signIn)` (L54).
2. **`AboutPage`**:
   Implements no controller (`AboutBindings` is empty). Reads configuration directly from GetX locator in `build()`.
3. **`NotFoundPage`**:
   Stateless page reading `Get.currentRoute` inside `build()`.
4. **`PermissionStatusPage`**:
   Shares `SettingsController` instead of maintaining a dedicated `PermissionStatusController` for child permission inspection.

---

## 7. Key Architectural Recommendations

1. **Rename Controller `refresh()` to `reload()`**:
   Replace `@override Future<void> refresh() async` with `Future<void> reload() async` across all 12 affected controllers to eliminate masking of `GetxController.refresh()`.
2. **Enforce Post-Await `if (isClosed) return;` Checks**:
   Systematically wrap every state mutation occurring after `await` with `if (isClosed) return;`, specifically in `RegisterController`, `SignInController`, `OnboardingController`, `SplashController`, and all repository gap loading routines.
3. **Tag Scoped Dependencies**:
   Refactor `TelemetryController` in `DeviceDetailBindings` to use device-specific tags:
   `Get.put<TelemetryController>(..., tag: deviceId)`.
4. **Mark Backend Seams as Permanent**:
   Add `permanent: true` to all seam registrations in `HavenBackend.install()` (`RowReader`, `RowWriter`, `UserAuth`, etc.) to prevent premature eviction during navigation transitions.
5. **Relocate `InitialBindings.register()`**:
   Move `InitialBindings.register(config)` from `HavenApp.build()` into `main()` before `runApp()`.
6. **Split `SettingsController`**:
   Create a separate `PermissionStatusController` and `PermissionStatusBindings` for the `/settings/permissions` route to prevent cross-screen binding lifecycle interference.

---
*Report generated and validated against HAVEN Parental Control frontend architecture.*
