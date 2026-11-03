# Haven app implementation contract (binding for all agents)

Read this whole file before writing anything. It is the coordination contract for
the parallel build of `apps/haven_app`, `packages/*`, `android_native/*` and
`backend/*`. Names in here are **fixed**: match them exactly or the tree will not
compile. If you need a name changed, do not change it — put it in your handoff.

Rules that override convenience (from the owner brief, §5–§12):

1. **No hand-written source file over 200 lines** (`.dart .kt .java .sql .ts`). Target 80–150.
   Verify with `dart run scripts/check_line_counts.dart` from `D:/control` before you finish.
2. **Do not fake behaviour.** Unspecified feature → a typed, isolated interface that returns
   `blocked(...)` from `haven_core`. Never a placeholder button that looks functional.
3. **No invented contracts.** Tables, columns, RPC names and Edge Function slugs come only from
   `docs/stage1/evidence/`. `TableName`, `RpcName`, `EdgeFunctionName` (in `haven_api`) already
   encode that list — import them, do not restate strings.
   `notification-cron`, `register-token`, `verify-firebase-token` **do not exist**.
4. **No secrets in the app.** No service-role key, no Admin SDK credential, no private key, no
   plaintext device secret. Client identifiers arrive only via `--dart-define` (`HavenConfig`).
5. **No cloud access.** No Supabase CLI, no Firebase CLI, no REST, no curl, no DB connection.
   Browser-dashboard-only remains in force, and no schema has been loaded (approvals unsigned),
   so nothing can be verified end-to-end against staging yet.
6. **No git operations** (commit/push/reset/clean/rebase).
7. **GetX everywhere in the app**: `GetxController` for UI state, `Bindings` for DI, named routes
   only, subscriptions/timers disposed in `onClose`. Widgets never call Supabase or Firebase.
8. **Touch only your assigned paths.** Never edit another agent's directory, and never edit this
   file, `lib/main.dart`, `lib/app/app.dart`, `packages/*/pubspec.yaml` or
   `apps/haven_app/pubspec.yaml`.

## Packages and boundaries

| Package | Owns | May import |
| --- | --- | --- |
| `packages/haven_core` | `Result`, `HavenFailure` family, `blocked()`, validation, utils, retry, clock | pure Dart |
| `packages/haven_models` | typed row models, enums, RPC argument records | `haven_core` is not needed; pure Dart |
| `packages/haven_api` | Supabase/Firebase/Edge/Realtime clients, `TableName`, `RpcName`, `EdgeFunctionName`, `BackendStatus` | core, models, SDKs |
| `apps/haven_app` | features, controllers, views, DI, theme, platform services | all three packages |

Feature agents depend on **`haven_api` abstractions**, never on `supabase_flutter` types.

Already written by the orchestrator — keep these public names, extend around them:

- `haven_core`: `Result<T>`/`Ok`/`Err`/`okVoid()`, `HavenFailure` and subclasses
  (`AuthFailure(signedOut:)`, `PermissionFailure`, `DevicePermissionFailure(permanentlyDenied:, openSettingsWillHelp:)`,
  `NetworkFailure(retryable:)`, `BackendFailure(code:)`, `StorageFailure`, `ValidationFailure(field:)`,
  `BlockedFailure(missing:)`, `UnknownFailure`), `blocked<T>(missing, {requirement})`, `isBlocked(...)`.
- `haven_models`: `src/json_utils.dart` → `asDate asDouble asInt asBool asText asMap asList toJsonDate`.
- `haven_api`: `BackendEndpoints{supabaseUrl,supabaseAnonKey,firebaseProjectId,firebaseAppId,firebaseApiKey,hasSupabase,hasFirebase,isConfigured}`,
  `BackendStatus`/`BackendReadiness`, `TableName`, `RpcName`, `EdgeFunctionName`.
  **Data/identity seams in `src/data_contracts.dart` and `src/auth_contracts.dart` are fixed**:
  `RowReader{rows,first,count}`, `RowWriter{insert,update}`, `RpcCaller{call}`,
  `EdgeCaller{invoke}` + `EdgeReply{status,body,errorCode,isSuccess}`, `ChangeFeed{changes}`,
  `SnapshotSource`, `UserAuth{signInWithPassword,register,signInWithFirebaseToken,currentSession,refresh,signOut,states}`,
  `AuthSession{userId,email,accessToken,role,expiresAt,hasProfile}`, `AuthStateSnapshot`, `AuthStatusKind`,
  `ProfileStore{load,updateDisplayName}`, `DeviceCredential{deviceId,secret,storedSecurely}`,
  `DeviceIdentity{credential,issue,clear}`, `PushTransport{registrationTarget,clearRegistration,registrationChanges,requestPermission,granted,taps,foregroundMessages}`.
  Everything returns `Result<...>` from `haven_core` — never a raw throw, never a bare `null` "success".
  **Feature agents code against these interfaces only.** They do not construct SDK objects.
- app: `main.dart` (reads five `HAVEN_*` defines), `app/app.dart` (`HavenApp(config:)`),
  `core/constants/haven_config.dart` (`HavenConfig`, `endpoints`, `status`, `missingDefines()`).

`app/app.dart` already calls `InitialBindings.register(config)` (static, idempotent) and uses
`AppRoutes.splash`, `AppPages.pages`, `HavenTheme.light`, `HavenTheme.dark`, `InitialBindings()` as a
`Bindings`. Those four files are agent 4's to create with exactly those names.

## Evidence map (what each feature may use)

Authoritative sources: `docs/stage1/evidence/schema-columns.md` (19 tables, 183 columns, types and
nullability), `docs/stage1/evidence/g1-q7-20261029.json` (18 function signatures — **no return types
captured**), `docs/stage1/evidence/edge-functions/capture-20261030.json` (9 slugs, 6 `_shared`
modules; only `pairing` and `auth-bootstrap` are readable TypeScript), and the re-authored schema in
`docs/stage2/migrations/A3-staging-load-v1.sql` (CHECK constraints and defaults live there).

| Feature | Tables | RPCs | Edge Function |
| --- | --- | --- | --- |
| authentication | `profiles` | none (return type gap) | `auth-bootstrap` (actions: `set_role`, `create_family` only) |
| family | `families` `family_members` `profiles` | `create_family_with_owner` `unlink_child` | `family-admin` |
| device_pairing | `pairing_requests` `pairing_attempts` `device_pairing_tokens` | `create_pairing_invite` `create_pairing_request` `respond_pairing_request` | `pairing` |
| child_devices | `devices` | `revoke_device` `request_device_recovery` | `device-register` |
| device_commands | `device_commands` | `poll_device_commands` `expire_stale_commands` | `device-command` |
| policies | `device_policies` | `apply_policy_version` | `device-policy` |
| device_activity | `device_apps` `usage_daily` | `replace_device_apps` | `device-telemetry` |
| telemetry | `devices` (status columns) `audit_logs` | `detect_offline_devices` | `device-telemetry` |
| location | `location_events` | none | none |
| safe_zones | `safe_zones` `safe_zone_states` `safety_alerts` | none | none |
| remote_sessions | `remote_sessions` `webrtc_signals` | `request_remote_session` `expire_stale_sessions` | `remote-session` |
| notifications | `safety_alerts` (+ token lane, see below) | none | `cron` (documented only, do not invent) |

Known gaps that must surface as `blocked(...)`, not as invented code:

- **Profile provisioning**: third-party JWTs never insert into `auth.users`, so the
  `handle_new_user` trigger never fires and no evidenced action claims a profile
  (`docs/stage2/S2-EXEC-08-identity-decision-A13-final.md` §2(4)). Any screen that needs a profile
  must handle "profile does not exist yet" honestly.
- **Firebase UID mapping**: table `public.firebase_identity_mapping` is drafted in
  `docs/stage2/migrations/A3d-firebase-identity-mapping.sql` and is **not approved** (no instrument
  authorises it) and **not loaded**. Client code must treat the mapping as server-side only; the
  client never asserts a Firebase UID as identity.
- **RPC return types**: uncaptured for all 14 public RPCs. Decode to `Object?`, validate, and where a
  shape is genuinely required to proceed, mark that call `NOT VERIFIED — RETURN SHAPE UNCAPPED`.
- **Notification token registration**: the token columns/indexes exist only in the unapproved
  `A3c-notification-backend.sql`. FCM token *capture and lifecycle on-device* is implementable;
  *server registration* must call a typed interface that returns `blocked(...)`.
- **WebRTC media**: `webrtc_signals` (SDP/ICE transport rows) is in the schema, but there is no
  TURN/credential lifecycle anywhere in the evidence (`docs/stage1/03-data-model.md:42`) and media was
  declared out of scope in `docs/stage1/00-status-register.md` X2. Implement signalling + lifecycle;
  the media peer must stay behind an interface returning `blocked(...)`.
- **Device secrets**: `devices.secret_hash`, `device_pairing_tokens.code_hash` are hashes; the KDF is
  not captured. Never store or transmit a plaintext pairing code beyond the displayed lifetime.

## UI vocabulary (agent 4 owns, everyone consumes)

Theme tokens, in `lib/app/theme/`:
`HavenColors{primary,onPrimary,background,surface,textPrimary,textSecondary,outline,good,warning,bad,blocked}`,
`HavenSpacing{xs=4,sm=8,md=16,lg=24,xl=32,gutter=20,touchTarget=48}`,
`HavenRadius{sm=8,md=12,pill=999}`, `HavenText` (`largeTitle,title,headline,body,label,caption`) as
named `TextStyle` getters, `HavenTheme.light`, `HavenTheme.dark`.
Flat surfaces: no gradients, no stacked shadows, no decorative cards, one accent colour.

Shared widgets, in `lib/shared/components/` (import via `lib/core/widgets/widgets.dart` barrel that
agent 4 also creates):

- `HavenScaffold({required String title, Widget body, List<Widget> actions = const [], Widget? fab, bool showBackendBanner = true, bool showBack = true})`
- `StateView<T>({required bool isLoading, required Result<T>? result, required Widget Function(BuildContext, T) onData, String emptyMessage = 'Nothing here yet', Widget Function()? empty, VoidCallback? onRetry, EdgeInsets padding})`
  — renders loading / error / blocked / empty / data in one place. Every data screen uses it.
- `SectionCard({required String title, String? subtitle, Widget? trailing, required Widget child})`
- `HavenButton({required String label, required VoidCallback? onPressed, bool busy = false, IconData? icon, bool primary = true})`
- `StatusChip({required String label, required StatusTone tone})` with `enum StatusTone {neutral, good, warning, bad, blocked}`
- `HavenField({required String label, String? helper, String? Function(String?)? validator, TextEditingController? controller, TextInputType keyboardType, bool obscure = false, int? maxLength})`
- `ConfirmSheet.confirm(BuildContext, {required String title, required String body, required String confirmLabel, bool destructive = false}) → Future<bool>`
- `BlockedNotice({required String requirement})` — parent-readable line plus the technical `missing` string
- `BackendBanner()` — shows `HavenConfig.status.message` when the build is not configured
- `PermissionExplain({required String title, required String why, required IconData icon, required Future<bool> Function() onRequest, required ValueChanged<bool> onResult})`

Plain-language copy rules: label what a thing is for ("Screen time this week"), not the column name
(`usage_daily`); one primary action per screen; confirm anything that removes a device or a child;
state limitations in one sentence ("Location updates only while the child's app is in the
foreground"). Never print a stack trace to the user.

## Routes (fixed table; agent 4 implements, features implement the classes)

`AppRoutes` is an `abstract final class` of `String` constants; `AppPages.pages` is the
`List<GetPage>`; each feature folder holds its own `bindings/xxx_bindings.dart`.

| Route | Path | Page class (file under `lib/features/`) | `Get.arguments` |
| --- | --- | --- | --- |
| `splash` | `/` | `authentication/views/pages/splash_page.dart` `SplashPage` | — |
| `signIn` | `/sign-in` | `authentication/views/pages/sign_in_page.dart` `SignInPage` | — |
| `register` | `/register` | `authentication/views/pages/register_page.dart` `RegisterPage` | — |
| `sessionEnded` | `/session-ended` | `authentication/views/pages/session_ended_page.dart` `SessionEndedPage` | `String reason` |
| `onboarding` | `/onboarding` | `onboarding/views/pages/onboarding_page.dart` `OnboardingPage` | — |
| `dashboard` | `/dashboard` | `dashboard/views/pages/dashboard_page.dart` `DashboardPage` | — |
| `family` | `/family` | `family/views/pages/family_page.dart` `FamilyPage` | — |
| `childProfile` | `/family/child` | `family/views/pages/child_profile_page.dart` `ChildProfilePage` | `String childUserId` |
| `pairing` | `/pairing` | `device_pairing/views/pages/pairing_page.dart` `PairingPage` | — |
| `pairingCode` | `/pairing/code` | `device_pairing/views/pages/pairing_code_page.dart` `PairingCodePage` | `String familyId` |
| `devices` | `/devices` | `child_devices/views/pages/devices_page.dart` `DevicesPage` | — |
| `deviceDetail` | `/devices/detail` | `child_devices/views/pages/device_detail_page.dart` `DeviceDetailPage` | `DeviceRouteArgs` (own class) |
| `activity` | `/devices/activity` | `device_activity/views/pages/activity_page.dart` `ActivityPage` | `String deviceId` |
| `commands` | `/devices/commands` | `device_commands/views/pages/commands_page.dart` `CommandsPage` | `String deviceId` |
| `policies` | `/devices/policies` | `policies/views/pages/policies_page.dart` `PoliciesPage` | `String deviceId` |
| `location` | `/devices/location` | `location/views/pages/location_page.dart` `LocationPage` | `String deviceId` |
| `safeZones` | `/safe-zones` | `safe_zones/views/pages/safe_zones_page.dart` `SafeZonesPage` | — |
| `safeZoneEditor` | `/safe-zones/editor` | `safe_zones/views/pages/safe_zone_editor_page.dart` `SafeZoneEditorPage` | `String? zoneId` |
| `remoteSessions` | `/remote-sessions` | `remote_sessions/views/pages/remote_sessions_page.dart` `RemoteSessionsPage` | — |
| `remoteSessionDetail` | `/remote-session` | `remote_sessions/views/pages/remote_session_detail_page.dart` `RemoteSessionDetailPage` | `String sessionId` |
| `notifications` | `/notifications` | `notifications/views/pages/notifications_page.dart` `NotificationsPage` | — |
| `account` | `/account` | `account/views/pages/account_page.dart` `AccountPage` | — |
| `settings` | `/settings` | `settings/views/pages/settings_page.dart` `SettingsPage` | — |
| `permissionStatus` | `/settings/permissions` | `settings/views/pages/permission_status_page.dart` `PermissionStatusPage` | — |
| `about` | `/settings/about` | `settings/views/pages/about_page.dart` `AboutPage` | — |
| `unknown` | `/unknown` | `dashboard/views/pages/not_found_page.dart` `NotFoundPage` | — |

## Test conventions

`packages/*/test/**` uses `package:test`; app tests use `flutter_test` under
`apps/haven_app/test/<feature>/`. Widget tests pump the widget with `GetMaterialApp` and a fake
repository (hand-written fakes implementing the repository interface — no mocking package).
Name files `<subject>_test.dart`. Every feature agent writes at least: one repository test (maps a
failure correctly), one controller test (state transitions), one widget test (loading → data, and
the blocked/empty states). Do not test SDK internals; do not test copy strings.
