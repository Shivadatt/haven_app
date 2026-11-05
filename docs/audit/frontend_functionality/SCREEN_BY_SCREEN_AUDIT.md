# FRONTEND SCREEN-BY-SCREEN FUNCTIONALITY AUDIT

**Target Location:** `apps/haven_app/lib/app/routes/` and `apps/haven_app/lib/features/`  
**Application Name:** HAVEN Parental Control (Flutter Parent App)  
**Audit Standard:** Strict Evidence-Based Audit (Route-by-Route, Component-by-Component)  
**Execution Posture:** Read-Only Source Inspection + Widget Test Analysis + Native Bridge Verification  
**Audit Date:** 2026-11-05  

---

## 1. EXECUTIVE SUMMARY

An exhaustive audit of the frontend screen architecture and view layer across [`apps/haven_app`](file:///d:/control/apps/haven_app) was conducted against the architectural baseline defined in [`docs/implementation/00-app-contract.md`](file:///d:/control/docs/implementation/00-app-contract.md) and [`docs/architecture/04-refusal-model.md`](file:///d:/control/docs/architecture/04-refusal-model.md).

### 1.1 Key Audit Metrics
* **Total Registered Routes:** **26 routes** defined in [`AppRoutes`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L8-L35) and registered in [`AppPages`](file:///d:/control/apps/haven_app/lib/app/routes/app_pages.dart#L54-L184).
* **Built Page Classes:** Exactly **26 page classes** implemented in `apps/haven_app/lib/features/**/views/pages/`.
* **Dummy / Mock Screens:** **0**. No screen displays fake children, synthetic metrics, dummy charts, or simulated data.
* **Architecture Refusal Pattern Compliance:** **100%**. When backend capabilities or SQL table grants are absent, screens do not fail silently or show fake empty boards; they render explicit, typed refusal cards ([`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart)) citing exact repository gaps.
* **Reactive Connection:** All interactive screens are driven by GetX (`GetView`, `GetWidget`, `Obx`, `Rx<T>`).
* **Offline Test Coverage:** 100% of screens have offline widget tests in `apps/haven_app/test/` asserting loading, empty, blocked, and success states using repository fakes.
* **Production / Live Readiness:** In a staging build without live backend credentials, the app gracefully boots into an unconfigured refusal posture. Only local settings (theme persistence via [`PreferencesStore`](file:///d:/control/apps/haven_app/lib/core/storage/preferences_store.dart)) and native OS diagnostics ([`MethodChannel('haven.dev/child_device_state')`](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart)) run end-to-end without network dependencies.

---

## 2. COMPLETE SCREEN-BY-SCREEN INVENTORY (ALL 26 REGISTERED ROUTES)

```
                               HAVEN APP NAVIGATION MAP (26 ROUTES)
                               
                                       [ / ] (SplashPage)
                                        |
                 +----------------------+----------------------+
                 | (Not Signed In)                             | (Signed In)
                 v                                             v
        [ /sign-in ] <----------------+               [ /dashboard ] (DashboardPage)
                 |                    |                        |
         +-------+-------+            |            +-----------+-----------+
         |               |            |            |           |           |
         v               v            |            v           v           v
   [ /register ]  [ /session-ended ] -+       [ /family ] [ /devices ] [ /settings ]
         |                                         |           |           |
         v                                         v           v           v
   [ /onboarding ]                         [ /family/child ] [ /devices/detail ] [ /settings/permissions ]
                                                   |           |           |
                                                   v           v           v
                                             [ /pairing ] [ /devices/activity ] [ /settings/about ]
                                                   |           |
                                                   v           v
                                           [ /pairing/code ] [ /devices/commands ]
                                                               |
                                                               v
                                                      [ /devices/policies ]
                                                               |
                                                               v
                                                      [ /devices/location ]
                                                               |
                                                               v
                                                      [ /safe-zones ] <---> [ /safe-zones/editor ]
                                                               |
                                                               v
                                                      [ /remote-sessions ] <-> [ /remote-session ]
                                                               |
                                                               v
                                                      [ /notifications ]
                                                               |
                                                               v
                                                      [ /account ]
                                                               |
                                                      [ /unknown ] (NotFoundPage)
```

---

### Route 1: `/` — `SplashPage`
* **Route Constant:** [`AppRoutes.splash`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L9)
* **Page Class & Path:** [`SplashPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/splash_page.dart#L15) in `apps/haven_app/lib/features/authentication/views/pages/splash_page.dart:15-51`
* **Binding Class:** [`SplashBindings`](file:///d:/control/apps/haven_app/lib/features/authentication/bindings/splash_bindings.dart)
* **Controller Class:** [`SplashController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/splash_controller.dart)
* **Layout & Responsiveness:** Built using `Scaffold`, `SafeArea`, `Center`, and `ConstrainedBox(maxWidth: 420)` with `HavenSpacing.lg` padding. Fits cleanly on all phone and tablet form factors without overflow.
* **UI Components Present:**
  * Wordmark header (`Text('Haven')`, caption: "Calm supervision for a child's device").
  * Stage container (`_Stage` driven by `controller.stage.value`).
  * Environment label ("Staging build" or warning if unstaged).
* **Form Validations:** None (read/connection screen).
* **Loading State:** While `SplashStage.connecting`, displays `LinearProgressIndicator()` and `Text('Connecting…')`.
* **Empty State:** N/A.
* **Error / Stalled State:** When `SplashStage.stalled`, displays [`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart) quoting the backend configuration status (`config.status.message`), accompanied by [`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) ("Try again").
* **Blocked State:** Intercepts unconfigured staging endpoints and refuses progress honestly.
* **Success / Data State:** When session is resolved, `SplashStage.away` renders `SizedBox.shrink()` and navigates to `/dashboard` (if signed in) or `/sign-in` (if unauthenticated).
* **Reactive Connection:** `GetView<SplashController>` using reactive `Obx` on `controller.stage.value`.
* **Data Reality:** Calls [`InitialBindings.startBackend()`](file:///d:/control/apps/haven_app/lib/app/bindings/initial_bindings.dart#L40) and checks [`AuthRepository.currentUser`](file:///d:/control/apps/haven_app/lib/features/authentication/data/auth_repository.dart). No mock data.

---

### Route 2: `/sign-in` — `SignInPage`
* **Route Constant:** [`AppRoutes.signIn`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L10)
* **Page Class & Path:** [`SignInPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart#L14) in `apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart:14-55`
* **Binding Class:** [`SignInBindings`](file:///d:/control/apps/haven_app/lib/features/authentication/bindings/auth_bindings.dart#L19)
* **Controller Class:** [`SignInController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart)
* **Layout & Responsiveness:** Uses [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `showBack: false`, `HavenPageBody(maxWidth: 720)`, and `ListView(keyboardDismissBehavior: onDrag)`. Fully responsive and keyboard-safe.
* **UI Components Present:**
  * Subtitle text explaining device supervision scope.
  * Email input (`_EmailField` using [`HavenField`](file:///d:/control/apps/haven_app/lib/shared/components/haven_field.dart)).
  * Password input (`_PasswordField` using `TextField` with `TextButton` visibility toggle).
  * Form-level error display (`_FormError` in `HavenColors.bad`).
  * Sign in button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) expanded).
  * Navigation link to registration (`_RegisterLink` with `TextButton`).
* **Form Validations:** [`SignInController.submit()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart#L39) asserts:
  * Email must not be blank and must contain `@` and `.`.
  * Password must not be blank.
  * Validation errors update `emailError` and `passwordError` reactively.
* **Loading State:** `controller.busy.value` sets `busy: true` on `HavenButton` (shows circular progress indicator) and disables inputs (`enabled: !controller.isBusy`).
* **Empty State:** N/A (input form).
* **Error State:** Network or authentication failure returned as `HavenFailure` and displayed in `formError.value`.
* **Blocked State:** If backend unconfigured or Firebase bridge attempted, repository returns `RefusedSeamFailure` / `BlockedFailure`.
* **Success / Data State:** On success, calls `_routeAfterSignIn(userId)` to navigate to `/dashboard` or `/onboarding`.
* **Reactive Connection:** `GetView<SignInController>` with `Obx` on fields, button, and errors.
* **Data Reality:** Connects to Supabase GoTrue Auth client via `HavenAuthRepository`. Zero mock accounts.

---

### Route 3: `/register` — `RegisterPage`
* **Route Constant:** [`AppRoutes.register`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L11)
* **Page Class & Path:** [`RegisterPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/register_page.dart#L12) in `apps/haven_app/lib/features/authentication/views/pages/register_page.dart:12-74`
* **Binding Class:** [`RegisterBindings`](file:///d:/control/apps/haven_app/lib/features/authentication/bindings/auth_bindings.dart#L28)
* **Controller Class:** [`RegisterController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart)
* **Layout & Responsiveness:** Built with [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody(maxWidth: 720)`, and `ListView(keyboardDismissBehavior: onDrag)`.
* **UI Components Present:**
  * Display name field ([`HavenField`](file:///d:/control/apps/haven_app/lib/shared/components/haven_field.dart) maxLength 60).
  * Email field ([`HavenField`](file:///d:/control/apps/haven_app/lib/shared/components/haven_field.dart) with email keyboard).
  * Password field (`_PasswordEntry` with 'At least 8 characters' helper and toggle).
  * Form error container.
  * Primary submit button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Create account').
* **Form Validations:** [`RegisterController.submit()`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart#L39) asserts:
  * Name: 1..60 non-whitespace characters.
  * Email: valid format containing `@` and `.`.
  * Password: minimum 8 characters.
* **Loading State:** `controller.busy.value` triggers button spinner and disables inputs.
* **Empty State:** N/A.
* **Error State:** Field-level errors displayed in `HavenField.helper`; submission failure displayed in `formError`.
* **Blocked State:** Handles unconfigured backend refusal.
* **Success / Data State:** Calls `AuthRepository.register(...)`. If confirmation email is required, retains unauthenticated state and informs user; if auto-confirmed, redirects to `/onboarding`.
* **Reactive Connection:** `GetView<RegisterController>` with fine-grained `Obx` wrappers.

---

### Route 4: `/session-ended` — `SessionEndedPage`
* **Route Constant:** [`AppRoutes.sessionEnded`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L12)
* **Page Class & Path:** [`SessionEndedPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/session_ended_page.dart#L14) in `apps/haven_app/lib/features/authentication/views/pages/session_ended_page.dart:14-61`
* **Binding Class:** [`SessionEndedBindings`](file:///d:/control/apps/haven_app/lib/features/authentication/bindings/auth_bindings.dart#L39) (empty dependencies)
* **Controller Class:** None (pure StatelessWidget driven by route argument).
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `showBack: false`, `HavenPageBody`, and `Column`.
* **UI Components Present:**
  * Lock icon (`Icons.lock_open_rounded` size 40).
  * Headline: "Your sign-in is no longer active."
  * Dynamic reason text parsed from `Get.arguments` (or fallback: "Haven lost the session and doesn't know why.").
  * Explanation text.
  * Sign in redirect button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Sign in again').
* **Form Validations:** Validates `Get.arguments is String && arg.trim().isNotEmpty`.
* **Loading / Empty / Error / Blocked States:** Static informational notice.
* **Success / Data State:** Displays honest reason captured by [`SessionWatch`](file:///d:/control/apps/haven_app/lib/features/authentication/services/session_watch.dart).
* **Reactive Connection:** None.
* **Dead Buttons:** None. Tapping redirects to `/sign-in` via `Get.offAllNamed`.

---

### Route 5: `/onboarding` — `OnboardingPage`
* **Route Constant:** [`AppRoutes.onboarding`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L13)
* **Page Class & Path:** [`OnboardingPage`](file:///d:/control/apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart#L11) in `apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:11-32`
* **Binding Class:** [`OnboardingBindings`](file:///d:/control/apps/haven_app/lib/features/onboarding/bindings/onboarding_bindings.dart)
* **Controller Class:** [`OnboardingController`](file:///d:/control/apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `showBack: false`, `HavenPageBody`, and `ListView`.
* **UI Components Present:**
  * **Step 1 (`_ExplainStep`):**
    * Headline "What Haven watches" and 3 bullet points detailing monitored app usage, foreground location, and rule enforcement.
    * [`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart) quoting missing consent table (`schema-columns.md:293`).
    * Consent acknowledgment row (`_AcknowledgeRow` with `Checkbox` and `InkWell`).
    * Error / message banner.
    * Continue button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'I understand — continue').
  * **Step 2 (`_SetupStep`):**
    * Headline "Name your family".
    * Family name input ([`HavenField`](file:///d:/control/apps/haven_app/lib/shared/components/haven_field.dart) maxLength 80).
    * Error / message banner.
    * Submission button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Create my family').
* **Form Validations:**
  * Step 1 requires `acknowledged.value == true`.
  * Step 2 requires `familyName.text.trim().isNotEmpty` and `<= 80` characters.
* **Loading State:** `isBusy` disables fields and renders button spinner.
* **Empty State:** N/A.
* **Error / Blocked State:** Step 1 explicitly embeds `BlockedNotice`. Backend rejection displayed in `controller.message.value`.
* **Success / Data State:** Invokes `OnboardingRepository.bootstrapFamily(name)`. On success, navigates to `/dashboard`.
* **Reactive Connection:** `GetView<OnboardingController>` with `Obx` switching steps and monitoring reactive fields.

---

### Route 6: `/dashboard` — `DashboardPage`
* **Route Constant:** [`AppRoutes.dashboard`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L14)
* **Page Class & Path:** [`DashboardPage`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart#L17) in `apps/haven_app/lib/features/dashboard/views/pages/dashboard_page.dart:17-38`
* **Binding Class:** [`DashboardBindings`](file:///d:/control/apps/haven_app/lib/features/dashboard/bindings/dashboard_bindings.dart)
* **Controller Class:** [`DashboardController`](file:///d:/control/apps/haven_app/lib/features/dashboard/controllers/dashboard_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody(maxWidth: 720)`, and [`StateView<DashboardData>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * `_NeedsSetup` card (if family unprovisioned) with 'Start setup' button.
  * Family Summary [`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart) with child/parent count and 'Open your family' button.
  * Children [`PeopleCard`](file:///d:/control/apps/haven_app/lib/features/family/views/widgets/people_card.dart) with child rows and tap navigation.
  * Needs Attention [`AttentionCard`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/widgets/attention_card.dart) (recent `safety_alerts` with severity chips and 'Open the full list' button).
  * Safe Places [`SafePlacesCard`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/widgets/safe_places_card.dart) with 'Open safe places' button.
  * Device Records [`DeviceRecordsCard`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/widgets/device_records_card.dart) (buttons for instructions, rule versions, and session records).
  * Devices Lane Card (`_DevicesCard` with `BlockedNotice` for F6 device grant and buttons to devices, activity, and location).
  * Settings row (`ListTile` leading to `/settings`).
* **Form Validations:** None.
* **Loading State:** `StateView` renders centered `CircularProgressIndicator()`.
* **Empty State:** `_NeedsSetup` card rendered when `data.family == null`.
* **Error State:** `StateView` error card with retry button calling `controller.load`.
* **Blocked State:** Inlined `BlockedNotice.fromFailure(controller.deviceGap.value!)` on `_DevicesCard`.
* **Success / Data State:** Composite read combining `families`, `profiles`, and `safety_alerts`.
* **Reactive Connection:** `GetView<DashboardController>` with `Obx` on `StateView` and `_DevicesCard`.
* **Dead Buttons:** None. All 10 buttons and 2 ListTiles execute real navigation.

---

### Route 7: `/family` — `FamilyPage`
* **Route Constant:** [`AppRoutes.family`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L15)
* **Page Class & Path:** [`FamilyPage`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/family_page.dart#L12) in `apps/haven_app/lib/features/family/views/pages/family_page.dart:12-33`
* **Binding Class:** [`FamilyBindings`](file:///d:/control/apps/haven_app/lib/features/family/bindings/family_bindings.dart)
* **Controller Class:** [`FamilyController`](file:///d:/control/apps/haven_app/lib/features/family/controllers/family_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and [`StateView<FamilyBundle?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) wrapping `SingleChildScrollView`.
* **UI Components Present:**
  * Family Name Card (`_NameCard` with `HavenField` and 'Save name' button).
  * Children Section ([`PeopleCard`](file:///d:/control/apps/haven_app/lib/features/family/views/widgets/people_card.dart) with onTap navigation to `/family/child`).
  * Parents Section ([`PeopleCard`](file:///d:/control/apps/haven_app/lib/features/family/views/widgets/people_card.dart) without chevron/tap).
  * Gaps Section (`_Gaps` rendering `BlockedNotice` for inviteParent and removeParent).
  * Empty setup card (`_NeedsSetup`).
* **Form Validations:** [`FamilyController.canSave`](file:///d:/control/apps/haven_app/lib/features/family/controllers/family_controller.dart#L60) requires non-empty name, length `<= 80`, and name modified from database record.
* **Loading State:** Centered progress indicator in `StateView`.
* **Empty State:** `_NeedsSetup` with 'Set up Haven' button.
* **Error State:** Retryable error card via `StateView`.
* **Blocked State:** `_Gaps` renders typed `BlockedNotice` for missing co-parent RPC contracts.
* **Success / Data State:** Reads real rows from `families`, `profiles`, and `family_members`.
* **Reactive Connection:** `GetView<FamilyController>` with `Obx` on `StateView`, `_NameCard`, and `_Gaps`.
* **Dead Buttons:** None.

---

### Route 8: `/family/child` — `ChildProfilePage`
* **Route Constant:** [`AppRoutes.childProfile`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L16)
* **Page Class & Path:** [`ChildProfilePage`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/child_profile_page.dart#L13) in `apps/haven_app/lib/features/family/views/pages/child_profile_page.dart:13-34`
* **Binding Class:** `ChildProfileBindings`
* **Controller Class:** `ChildProfileController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and [`StateView<FamilyPerson?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) wrapping `SingleChildScrollView`.
* **UI Components Present:**
  * Child Identity Card ([`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart) with child name, joining date, and [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart) 'Child').
  * Device Gap Card (`_DeviceGap` with `BlockedNotice` citing F6 grant wall).
  * Removal Gap Card (`_RemovalGap` with `BlockedNotice` citing missing child deletion contract).
  * Not In Family Card (`_NotInFamily` with 'Back to family' button).
* **Form Validations:** Reads `childUserId` from `Get.arguments`.
* **Loading / Empty / Error / Blocked States:** Fully handled by `StateView`.
* **Success / Data State:** Renders child member record. Mutations honest refused.
* **Reactive Connection:** `GetView<ChildProfileController>` with `Obx` on `StateView`, `_DeviceGap`, and `_RemovalGap`.
* **Dead Buttons:** None.

---

### Route 9: `/pairing` — `PairingPage`
* **Route Constant:** [`AppRoutes.pairing`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L17)
* **Page Class & Path:** [`PairingPage`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart#L13) in `apps/haven_app/lib/features/device_pairing/views/pages/pairing_page.dart:13-35`
* **Binding Class:** [`PairingBindings`](file:///d:/control/apps/haven_app/lib/features/device_pairing/bindings/device_pairing_bindings.dart)
* **Controller Class:** [`PairingController`](file:///d:/control/apps/haven_app/lib/features/device_pairing/controllers/pairing_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<PairingBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Pairing Requests Card ([`RequestsCard`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/widgets/requests_card.dart) listing rows from `pairing_requests`, timing details, [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), and withdrawal gap `BlockedNotice`).
  * Start Pairing Card (`_StartCard` explaining pairing flow and button 'How pairing works').
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Evaluates `PairingRequestStatus` (`approved`, `pendingChild`, etc.).
* **Loading / Empty / Error / Blocked States:** Full `StateView` integration.
* **Success / Data State:** Real query on `pairing_requests` filtered by `family_id`.
* **Reactive Connection:** `GetView<PairingController>` with `Obx`.
* **Dead Buttons:** None. 'How pairing works' navigates to `/pairing/code`.

---

### Route 10: `/pairing/code` — `PairingCodePage`
* **Route Constant:** [`AppRoutes.pairingCode`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L18)
* **Page Class & Path:** [`PairingCodePage`](file:///d:/control/apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart#L16) in `apps/haven_app/lib/features/device_pairing/views/pages/pairing_code_page.dart:16-36`
* **Binding Class:** `PairingCodeBindings`
* **Controller Class:** `PairingCodeController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and [`StateView<PairingBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) wrapping `SingleChildScrollView`.
* **UI Components Present:**
  * Mismatched Family Card (`_OtherFamilyCard` if route family differs from current family).
  * Short Code Section ([`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart) with `BlockedNotice` citing undeployed pairing Edge Function).
  * Child ID Invite Section ([`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart) with `BlockedNotice` citing missing invite Edge Function).
  * Disclaimer text on child consent requirement.
  * Empty setup card (`_NeedsSetup`).
* **Form Validations:** Checks `isForAnotherFamily`.
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Explanatory protocol architecture screen. Zero fake code inputs.
* **Reactive Connection:** `GetView<PairingCodeController>` with `Obx`.
* **Dead Buttons:** None. 'Back to pairing' returns to `/pairing`.

---

### Route 11: `/devices` — `DevicesPage`
* **Route Constant:** [`AppRoutes.devices`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L19)
* **Page Class & Path:** [`DevicesPage`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/pages/devices_page.dart#L16) in `apps/haven_app/lib/features/child_devices/views/pages/devices_page.dart:16-38`
* **Binding Class:** [`DevicesBindings`](file:///d:/control/apps/haven_app/lib/features/child_devices/bindings/child_devices_bindings.dart)
* **Controller Class:** [`DevicesController`](file:///d:/control/apps/haven_app/lib/features/child_devices/controllers/devices_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<List<Device>>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Paired Devices Card ([`DeviceListCard`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/widgets/device_list_card.dart) with device rows and [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart)).
  * Add Device Card (`_PairingCard` with 'Open pairing' button).
  * Empty Shelf Card (`_NoDevices`).
* **Form Validations:** None.
* **Loading State:** Centered circular progress indicator in `StateView`.
* **Empty State:** `_NoDevices` rendered when query succeeds with 0 devices.
* **Error / Blocked State:** Controller query hits `CapturedGaps.deviceLaneMissing` (Finding F6: `devices` table has no SELECT grant for `authenticated`). Intercepted by `StateView` and rendered as [`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart).
* **Success / Data State:** Renders `DeviceListCard` if devices readable.
* **Reactive Connection:** `GetView<DevicesController>` with `Obx` on `StateView`.
* **Dead Buttons:** None. 'Open pairing' navigates to `/pairing`.

---

### Route 12: `/devices/detail` — `DeviceDetailPage`
* **Route Constant:** [`AppRoutes.deviceDetail`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L20)
* **Page Class & Path:** [`DeviceDetailPage`](file:///d:/control/apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart#L19) in `apps/haven_app/lib/features/child_devices/views/pages/device_detail_page.dart:19-51`
* **Binding Class:** `DeviceDetailBindings`
* **Controller Class:** `DeviceDetailController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and `SingleChildScrollView`.
* **UI Components Present:**
  * Fallback when no device ID in route (`_NoDeviceNamed`).
  * Device Record Card (`_RecordCard` with loading spinner, `BlockedNotice` for F6 grant wall, retry button, or `DeviceRow`).
  * Reports Card (`_ReportsCard` with 4 working navigation buttons: 'App use it reported', 'Places it reported', 'Instructions addressed to it', 'Rule versions written for it').
  * Telemetry Card ([`TelemetryCard`](file:///d:/control/apps/haven_app/lib/features/telemetry/views/widgets/trail_card.dart) embedding audit log).
  * Actions Card (`_ActionsCard` with `BlockedNotice` for revoke and recovery gaps).
* **Form Validations:** Checks `hasDeviceId`.
* **Loading / Empty / Error / Blocked States:** Granular reactive Obx observers per card.
* **Success / Data State:** Displays device status and embeds working read sub-routes.
* **Reactive Connection:** `GetView<DeviceDetailController>` with `Obx`.
* **Dead Buttons:** None. All 5 buttons execute real operations.

---

### Route 13: `/devices/activity` — `ActivityPage`
* **Route Constant:** [`AppRoutes.activity`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L21)
* **Page Class & Path:** [`ActivityPage`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart#L13) in `apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart:13-35`
* **Binding Class:** [`ActivityBindings`](file:///d:/control/apps/haven_app/lib/features/device_activity/bindings/activity_bindings.dart)
* **Controller Class:** [`ActivityController`](file:///d:/control/apps/haven_app/lib/features/device_activity/controllers/activity_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<UsageBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Usage Card ([`UsageCard`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/widgets/usage_card.dart) listing rows from `usage_daily` table, duration, day, device identifier, and `BlockedNotice` for unnamed device due to F6).
  * Limits Explainer Card ([`UsageLimitsCard`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/widgets/usage_card.dart#L78)).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Formats duration into hours/minutes without fabrication.
* **Loading / Empty / Error / Blocked States:** Full `StateView` integration.
* **Success / Data State:** Real query on `usage_daily`. Devices left unnamed due to F6 grant wall.
* **Reactive Connection:** `GetView<ActivityController>` with `Obx`.
* **Dead Buttons:** None.

---

### Route 14: `/devices/commands` — `CommandsPage`
* **Route Constant:** [`AppRoutes.commands`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L22)
* **Page Class & Path:** [`CommandsPage`](file:///d:/control/apps/haven_app/lib/features/device_commands/views/pages/commands_page.dart#L12) in `apps/haven_app/lib/features/device_commands/views/pages/commands_page.dart:12-34`
* **Binding Class:** [`CommandsBindings`](file:///d:/control/apps/haven_app/lib/features/device_commands/bindings/commands_bindings.dart)
* **Controller Class:** [`CommandsController`](file:///d:/control/apps/haven_app/lib/features/device_commands/controllers/commands_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<CommandBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Instructions Card ([`CommandCard`](file:///d:/control/apps/haven_app/lib/features/device_commands/views/widgets/command_card.dart) listing rows from `device_commands` table, [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), device replies, tries count, and `BlockedNotice` for unnamed device).
  * Command Limits Card ([`CommandLimitsCard`](file:///d:/control/apps/haven_app/lib/features/device_commands/views/widgets/command_card.dart#L107) with `BlockedNotice` citing command write and cancellation refusal).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Evaluates `CommandStatus` (`pending`, `succeeded`, `failed`, `expired`).
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Real SELECT on `device_commands`. Mutation controls refused by architecture.
* **Reactive Connection:** `GetView<CommandsController>` with `Obx`.
* **Dead Buttons:** None.

---

### Route 15: `/devices/policies` — `PoliciesPage`
* **Route Constant:** [`AppRoutes.policies`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L23)
* **Page Class & Path:** [`PoliciesPage`](file:///d:/control/apps/haven_app/lib/features/policies/views/pages/policies_page.dart#L12) in `apps/haven_app/lib/features/policies/views/pages/policies_page.dart:12-34`
* **Binding Class:** [`PoliciesBindings`](file:///d:/control/apps/haven_app/lib/features/policies/bindings/policies_bindings.dart)
* **Controller Class:** [`PoliciesController`](file:///d:/control/apps/haven_app/lib/features/policies/controllers/policies_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<PolicyBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Policy Versions Card ([`PolicyCard`](file:///d:/control/apps/haven_app/lib/features/policies/views/widgets/policy_card.dart) listing rows from `device_policies`, enforcement [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), error trouble message, and `BlockedNotice` for unnamed device).
  * Policy Limits Card ([`PolicyLimitsCard`](file:///d:/control/apps/haven_app/lib/features/policies/views/widgets/policy_card.dart#L110) with 2 `BlockedNotice` widgets for rule shape gap and policy write gap).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Maps `PolicyEnforcementStatus` (`enforced`, `failed`, `unsupported`).
* **Loading / Empty / Error / Blocked States:** Full `StateView` integration.
* **Success / Data State:** Real SELECT on `device_policies`. Policy modification honestly refused.
* **Reactive Connection:** `GetView<PoliciesController>` with `Obx`.
* **Dead Buttons:** None.

---

### Route 16: `/devices/location` — `LocationPage`
* **Route Constant:** [`AppRoutes.location`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L24)
* **Page Class & Path:** [`LocationPage`](file:///d:/control/apps/haven_app/lib/features/location/views/pages/location_page.dart#L12) in `apps/haven_app/lib/features/location/views/pages/location_page.dart:12-33`
* **Binding Class:** [`LocationBindings`](file:///d:/control/apps/haven_app/lib/features/location/bindings/location_bindings.dart)
* **Controller Class:** [`LocationController`](file:///d:/control/apps/haven_app/lib/features/location/controllers/location_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<FixBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Fixes Card ([`FixCard`](file:///d:/control/apps/haven_app/lib/features/location/views/widgets/fix_card.dart) listing location fixes from `location_events`, timestamp, accuracy, source, and `BlockedNotice` for unnamed device).
  * Coordinate toggle button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Show/Hide the exact coordinates').
  * Location Limits Card ([`LocationLimitsCard`](file:///d:/control/apps/haven_app/lib/features/location/views/widgets/fix_card.dart#L78) with `BlockedNotice` citing presence/geofencing refusal).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Formats coordinates and accuracy values.
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Real query on `location_events`. Refuses to invent simulated street maps.
* **Reactive Connection:** `GetView<LocationController>` with `Obx` on `showsCoordinates` and `StateView`.
* **Dead Buttons:** None. Toggle button reactively updates view.

---

### Route 17: `/safe-zones` — `SafeZonesPage`
* **Route Constant:** [`AppRoutes.safeZones`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L25)
* **Page Class & Path:** [`SafeZonesPage`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zones_page.dart#L13) in `apps/haven_app/lib/features/safe_zones/views/pages/safe_zones_page.dart:13-35`
* **Binding Class:** [`SafeZonesBindings`](file:///d:/control/apps/haven_app/lib/features/safe_zones/bindings/zones_bindings.dart)
* **Controller Class:** [`SafeZonesController`](file:///d:/control/apps/haven_app/lib/features/safe_zones/controllers/zones_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<ZoneBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Named Places Card ([`ZonesCard`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/widgets/zones_card.dart) listing safe zones from `safe_zones` table, radius across, active [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), 'Edit this place' button, and `BlockedNotice` for zone creation gap and presence gap).
  * What You Can Change Card ([`ZonesLimitsCard`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zones_page.dart#L57)).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Radius formatting.
* **Loading / Empty / Error / Blocked States:** Full `StateView` integration.
* **Success / Data State:** Real SELECT on `safe_zones`. Creation is refused because DB lacks INSERT grant for clients.
* **Reactive Connection:** `GetView<SafeZonesController>` with `Obx`.
* **Dead Buttons:** None. 'Edit this place' navigates to `/safe-zones/editor` passing `zone.id`.

---

### Route 18: `/safe-zones/editor` — `SafeZoneEditorPage`
* **Route Constant:** [`AppRoutes.safeZoneEditor`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L26)
* **Page Class & Path:** [`SafeZoneEditorPage`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart#L16) in `apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart:16-35`
* **Binding Class:** `ZoneEditorBindings`
* **Controller Class:** `SafeZoneEditorController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and [`StateView<SafeZone>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) wrapping `SingleChildScrollView`.
* **UI Components Present:**
  * SectionCard holding 4 [`HavenField`](file:///d:/control/apps/haven_app/lib/shared/components/haven_field.dart) inputs:
    * Zone name (maxLength 60).
    * Latitude (-90 to 90).
    * Longitude (-180 to 180).
    * Radius in metres (10 to 10,000m).
  * Live error indicators underneath each field ([`ZoneFieldError`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/widgets/zone_editor_widgets.dart#L14)).
  * Active state switch (`SwitchListTile` 'In use').
  * Save button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Save the change' with busy indicator).
  * Save outcome banner ([`ZoneWriteResult`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/widgets/zone_editor_widgets.dart#L41)).
  * Removal button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Remove this place').
  * Removal outcome banner (`ZoneWriteResult`).
* **Form Validations:** Strict validation enforced via [`SafeZoneRules`](file:///d:/control/apps/haven_app/lib/features/safe_zones/data/safe_zone_rules.dart):
  * Name: 1..60 non-empty characters.
  * Latitude: parsed double within `[-90.0, 90.0]`.
  * Longitude: parsed double within `[-180.0, 180.0]`.
  * Radius: parsed double within `[10.0, 10000.0]`.
  * Controller tracks `hasChanges` comparing draft with stored values; button disabled if unchanged.
* **Loading State:** `isLoading` in `StateView`; `isSaving` spinner in `HavenButton`.
* **Empty State:** N/A (edit view for existing zone).
* **Error / Blocked State:** Validation failures shown live; write failure rendered as `BlockedNotice` or error string.
* **Success / Data State:** Writes updates to `safe_zones` table (one of the client-permitted tables). On deletion, prompts via [`ConfirmSheet.confirm`](file:///d:/control/apps/haven_app/lib/shared/components/confirm_sheet.dart#L13) and closes page.
* **Reactive Connection:** `GetView<SafeZoneEditorController>` with reactive text controllers and dirty tracking.
* **Dead Buttons:** None. Fully functional CRUD edit and delete.

---

### Route 19: `/remote-sessions` — `RemoteSessionsPage`
* **Route Constant:** [`AppRoutes.remoteSessions`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L27)
* **Page Class & Path:** [`RemoteSessionsPage`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_sessions_page.dart#L12) in `apps/haven_app/lib/features/remote_sessions/views/pages/remote_sessions_page.dart:12-32`
* **Binding Class:** [`SessionsBindings`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/bindings/sessions_bindings.dart)
* **Controller Class:** [`SessionsController`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<SessionBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Sessions Card ([`SessionListCard`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/widgets/session_card.dart) listing rows from `remote_sessions`, [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), consent status, and 'Open this record' button).
  * Session Limits Card ([`SessionLimitsCard`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/widgets/session_card.dart#L120) with `BlockedNotice` citing start session RPC refusal).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Evaluates `SessionStatus` (`active`, `failed`, `expired`).
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Real SELECT on `remote_sessions`. Starting sessions is refused by architecture.
* **Reactive Connection:** `GetView<SessionsController>` with `Obx`.
* **Dead Buttons:** None. 'Open this record' navigates to `/remote-session`.

---

### Route 20: `/remote-session` — `RemoteSessionDetailPage`
* **Route Constant:** [`AppRoutes.remoteSessionDetail`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L28)
* **Page Class & Path:** [`RemoteSessionDetailPage`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart#L12) in `apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart:12-32`
* **Binding Class:** `SessionDetailBindings`
* **Controller Class:** `SessionDetailController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<SessionDetail?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Record Overview Card ([`SessionDetailCard`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/widgets/session_detail_card.dart) with consent line, lifecycle trail, and `BlockedNotice` for unnamed device).
  * Signalling Rows Card (reading `remote_session_signals` buffer and `BlockedNotice` for signal buffer gap).
  * Media Connection Card ([`SessionMediaCard`](file:///d:/control/apps/haven_app/lib/features/remote_sessions/views/widgets/session_detail_card.dart#L108) with `BlockedNotice` stating refusal for audio/video media because no TURN server or media relay is approved).
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Reads `sessionId` from `Get.arguments`.
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Real read of session and signalling rows. Streaming refused honestly.
* **Reactive Connection:** `GetView<SessionDetailController>` with `Obx`.
* **Dead Buttons:** None.

---

### Route 21: `/notifications` — `NotificationsPage`
* **Route Constant:** [`AppRoutes.notifications`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L29)
* **Page Class & Path:** [`NotificationsPage`](file:///d:/control/apps/haven_app/lib/features/notifications/views/pages/notifications_page.dart#L12) in `apps/haven_app/lib/features/notifications/views/pages/notifications_page.dart:12-35`
* **Binding Class:** [`NotificationsBindings`](file:///d:/control/apps/haven_app/lib/features/notifications/bindings/notifications_bindings.dart)
* **Controller Class:** [`NotificationsController`](file:///d:/control/apps/haven_app/lib/features/notifications/controllers/notifications_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `onRefresh: controller.refresh`, `HavenPageBody`, and [`StateView<AlertBoard?>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart).
* **UI Components Present:**
  * Reports List Card ([`ReportListCard`](file:///d:/control/apps/haven_app/lib/features/notifications/views/widgets/report_card.dart) listing safety alerts from `safety_alerts`, severity [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart), payload line, and `BlockedNotice` for unnamed device).
  * Reports Limits Card ([`ReportLimitsCard`](file:///d:/control/apps/haven_app/lib/features/notifications/views/widgets/report_card.dart#L99) with 2 `BlockedNotice` widgets for push delivery gap and alert acknowledgement gap, plus button 'Open settings').
  * Setup fallback card (`_NeedsSetup`).
* **Form Validations:** Evaluates `AlertSeverity` (`critical`, `warning`, `info`).
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Real query on `safety_alerts`. Push token registration refused.
* **Reactive Connection:** `GetView<NotificationsController>` with `Obx`.
* **Dead Buttons:** None. 'Open settings' navigates to `/settings`.

---

### Route 22: `/account` — `AccountPage`
* **Route Constant:** [`AppRoutes.account`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L30)
* **Page Class & Path:** [`AccountPage`](file:///d:/control/apps/haven_app/lib/features/account/views/pages/account_page.dart#L13) in `apps/haven_app/lib/features/account/views/pages/account_page.dart:13-32`
* **Binding Class:** [`AccountBindings`](file:///d:/control/apps/haven_app/lib/features/account/bindings/account_bindings.dart)
* **Controller Class:** [`AccountController`](file:///d:/control/apps/haven_app/lib/features/account/controllers/account_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and [`StateView<AccountInfo>`](file:///d:/control/apps/haven_app/lib/shared/components/state_view.dart) wrapping `SingleChildScrollView`.
* **UI Components Present:**
  * Identity Card (`_Identity` with email, role [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart) 'Parent', and role immutability explanation).
  * Name Card (`_NameCard` with `HavenField` for parent display name and 'Save name' button).
  * Setup Fallback Card (`_NeedsSetup`).
  * Limits Card (`_LimitsCard` with 3 `BlockedNotice` widgets: password change gap, email change gap, account deletion gap).
  * Sign Out Section ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Sign out' triggering [`ConfirmSheet.confirm`](file:///d:/control/apps/haven_app/lib/shared/components/confirm_sheet.dart#L13)).
* **Form Validations:** Name: 1..60 characters, non-empty, modified from current name.
* **Loading / Empty / Error / Blocked States:** Full `StateView` handling.
* **Success / Data State:** Reads session details; 'Save name' writes to `profiles` table. Sign out clears tokens and redirects to sign-in.
* **Reactive Connection:** `GetView<AccountController>` with `Obx` on StateView, name card, limits card, and sign out button.
* **Dead Buttons:** None.

---

### Route 23: `/settings` — `SettingsPage`
* **Route Constant:** [`AppRoutes.settings`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L31)
* **Page Class & Path:** [`SettingsPage`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/settings_page.dart#L12) in `apps/haven_app/lib/features/settings/views/pages/settings_page.dart:12-33`
* **Binding Class:** [`SettingsBindings`](file:///d:/control/apps/haven_app/lib/features/settings/bindings/settings_bindings.dart)
* **Controller Class:** [`SettingsController`](file:///d:/control/apps/haven_app/lib/features/settings/controllers/settings_controller.dart)
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and `ListView`.
* **UI Components Present:**
  * Appearance Card (`_Appearance` with 3 `ChoiceChip` widgets for System, Light, Dark).
  * Alerts Card (`_Alerts` with notification status chip, `BlockedNotice` for prompt gap, and 'Allow notifications' button).
  * Navigation Section (`_AlsoHere` with 3 `ListTile` rows for `/account`, `/settings/permissions`, and `/settings/about`).
* **Form Validations:** Validates `ThemeChoice`.
* **Loading State:** Centered progress indicator when `controller.isLoading.value == true`.
* **Success / Data State:** Fully functional local theme switching persisted to [`VaultPreferences`](file:///d:/control/apps/haven_app/lib/core/storage/preferences_store.dart).
* **Reactive Connection:** `GetView<SettingsController>` with `Obx`.
* **Dead Buttons:** None. All chips, buttons, and navigation rows operate.

---

### Route 24: `/settings/permissions` — `PermissionStatusPage`
* **Route Constant:** [`AppRoutes.permissionStatus`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L32)
* **Page Class & Path:** [`PermissionStatusPage`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart#L19) in `apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart:19-54`
* **Binding Class:** `PermissionStatusBindings`
* **Controller Class:** `SettingsController`
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and `ListView`.
* **UI Components Present:**
  * This Phone Card (`_ThisPhone` with notification status chip, `BlockedNotice`, and 'Allow notifications' button).
  * Native Device Diagnostics Card ([`DeviceStateCard`](file:///d:/control/apps/haven_app/lib/features/settings/views/widgets/device_state_card.dart) displaying Android API level chip, permissions area, monitoring area, location providers, device admin status, media capabilities, or `_Unreachable` fallback).
  * Child Phone Permissions Explainer Card (5 detailed permission explainers and 'Open paired devices' button -> `/devices`).
* **Form Validations:** Decodes native `MethodChannel('haven.dev/child_device_state')` payload.
* **Loading / Error / Blocked States:** Gracefully catches missing native channel and displays honest unreachable statement.
* **Success / Data State:** Real Android OS introspection via native bridge.
* **Reactive Connection:** `GetView<SettingsController>` with `Obx`.
* **Dead Buttons:** None.

---

### Route 25: `/settings/about` — `AboutPage`
* **Route Constant:** [`AppRoutes.about`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L33)
* **Page Class & Path:** [`AboutPage`](file:///d:/control/apps/haven_app/lib/features/settings/views/pages/about_page.dart#L13) in `apps/haven_app/lib/features/settings/views/pages/about_page.dart:13-35`
* **Binding Class:** `AboutBindings` (empty dependencies)
* **Controller Class:** None (StatelessWidget reading `HavenConfig`).
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart), `HavenPageBody`, and `SingleChildScrollView`.
* **UI Components Present:**
  * What Haven Is Card ([`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart)).
  * What Haven Promises Card ([`SectionCard`](file:///d:/control/apps/haven_app/lib/shared/components/section_card.dart) with 4 explicit promises regarding transparency, confirmation of restrictions, and zero guesswork).
  * Connectivity Card (`_Connectivity` with channel name, [`StatusChip`](file:///d:/control/apps/haven_app/lib/shared/components/status_chip.dart) readiness, project ref, and list of missing `--dart-define` keys via `HavenConfig.missingDefines()`).
* **Form Validations:** None.
* **Loading / Empty / Error / Blocked States:** Pure informational display.
* **Reactive Connection:** None.
* **Dead Buttons:** None.

---

### Route 26: `/unknown` — `NotFoundPage`
* **Route Constant:** [`AppRoutes.unknown`](file:///d:/control/apps/haven_app/lib/app/routes/app_routes.dart#L34)
* **Page Class & Path:** [`NotFoundPage`](file:///d:/control/apps/haven_app/lib/features/dashboard/views/pages/not_found_page.dart#L14) in `apps/haven_app/lib/features/dashboard/views/pages/not_found_page.dart:14-51`
* **Binding Class:** None (`AppPages.unknown` routes here directly)
* **Controller Class:** None (StatelessWidget).
* **Layout & Responsiveness:** [`HavenScaffold`](file:///d:/control/apps/haven_app/lib/shared/components/haven_scaffold.dart) with `showBackendBanner: false` and `ListView(padding: HavenSpacing.gutter)`.
* **UI Components Present:**
  * Headline: "This part of Haven has not been built yet."
  * Body explanation advising user to use the back button.
  * Refusal Notice ([`BlockedNotice`](file:///d:/control/apps/haven_app/lib/shared/components/blocked_notice.dart) with `requirement: 'Screen not implemented'` and `missing: wanted`).
  * Return button ([`HavenButton`](file:///d:/control/apps/haven_app/lib/shared/components/haven_button.dart) 'Go to the start screen').
* **Form Validations:** Reads `Get.currentRoute`.
* **Loading / Empty / Error / Blocked States:** Honest 404 fallback for unspecified routes.
* **Reactive Connection:** None.
* **Dead Buttons:** None. Tapping redirects to `/` via `Get.offAllNamed(AppRoutes.splash)`.

---

## 3. AUDIT OF MISSING SCREENS FOR A PRODUCTION PARENTAL CONTROL PRODUCT

While Haven's 26 routes rigorously implement the current architectural contract, a commercial parental control product requires additional functional flows. Below is the itemized gap inventory:

```
MISSING SCREENS TAXONOMY:
+---------------------------------------------------------------------------------+
| 1. AUTHENTICATION & RECOVERY: Forgot Password, Reset Password, Email Verify     |
| 2. POLICY MANAGEMENT: App Limits Editor, App Blocklist, Web Filtering, Schedule |
| 3. APPROVAL QUEUES: App Install Requests, Screen Time Extension Requests        |
| 4. LOCATION: Interactive Map View, Breadcrumb Trail Playback, Geofence Creator  |
| 5. NOTIFICATIONS: Notification Channels, Alert Thresholds, Tamper Preferences   |
| 6. MULTI-PARENT: Co-Parent Invitation & Permissions Delegation                  |
| 7. CHILD ONBOARDING: Native Device Admin & Accessibility Activation Wizard     |
+---------------------------------------------------------------------------------+
```

### 3.1 Authentication & Account Recovery
1. **Forgot Password Screen (`/forgot-password`):**
   * *Required Capability:* Allows parents to enter their registered email address to trigger a password reset email via Supabase GoTrue `resetPasswordForEmail`.
   * *Current Codebase Status:* Absent. [`SignInPage`](file:///d:/control/apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart) provides no "Forgot password?" link.
2. **Reset Password / Deep Link Receiver Screen (`/reset-password`):**
   * *Required Capability:* Handles recovery deep links with authentication token or code, allowing users to enter a new password with confirmation and strength validation.
   * *Current Codebase Status:* Absent. Password updates inside [`AccountPage`](file:///d:/control/apps/haven_app/lib/features/account/views/pages/account_page.dart) are refused via `BlockedNotice`.
3. **Email Verification Pending Screen (`/verify-email`):**
   * *Required Capability:* Displayed after registration when `email_confirm` is required by the backend, offering a "Resend verification email" action and instructions.
   * *Current Codebase Status:* Absent. [`RegisterController`](file:///d:/control/apps/haven_app/lib/features/authentication/controllers/register_controller.dart) currently shows an inline message and retains the form.

### 3.2 Device Supervision & Policy Enforcement
4. **App Daily Limits Editor (`/devices/limits/editor`):**
   * *Required Capability:* Configure daily time allowances per application or category (e.g. YouTube: 45 mins/day; Games: 1 hour/day).
   * *Current Codebase Status:* Absent. [`PoliciesPage`](file:///d:/control/apps/haven_app/lib/features/policies/views/pages/policies_page.dart) is strictly a read-only viewer for `device_policies` rows.
5. **App Blocking & Whitelist Screen (`/devices/apps/blocklist`):**
   * *Required Capability:* List installed apps on the child's phone with toggle switches to set states: "Always Allowed", "Timed", or "Permanently Blocked".
   * *Current Codebase Status:* Absent. [`ActivityPage`](file:///d:/control/apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart) displays historical usage, but provides no controls to restrict packages.
6. **Web & Content Filtering Configuration Screen (`/devices/web-filter`):**
   * *Required Capability:* Configure DNS-level or local VPN web filtering: SafeSearch enforcement, adult category blocking, and custom domain blacklists/whitelists.
   * *Current Codebase Status:* Absent. No web filtering route exists.
7. **Downtime & Bedtime Schedule Editor (`/devices/schedule/editor`):**
   * *Required Capability:* Recurring weekly timetable (Monday–Sunday) specifying bedtime lockouts, school hours blackout periods, and homework study modes.
   * *Current Codebase Status:* Absent.

### 3.3 Interactive Child Request & Approval Queues
8. **App Installation Approval Screen (`/approvals/apps`):**
   * *Required Capability:* Push alert and parent interface to review, approve, or reject new app installations triggered by the child on Google Play.
   * *Current Codebase Status:* Absent.
9. **Screen Time Extension Request Screen (`/approvals/time-extension`):**
   * *Required Capability:* Handles child requests for extra time (e.g. +15 mins, +30 mins) with one-tap parental grants.
   * *Current Codebase Status:* Absent.

### 3.4 Location & Geofencing Experience
10. **Interactive Map View (`/devices/location/map`):**
    * *Required Capability:* Visual map rendering (Google Maps / Mapbox / OpenStreetMap) showing the child's device pin, accuracy circle, and geofence boundaries.
    * *Current Codebase Status:* Absent. [`LocationPage`](file:///d:/control/apps/haven_app/lib/features/location/views/pages/location_page.dart) strictly renders text latitude/longitude coordinates to avoid unapproved map API dependencies.
11. **Create Safe Zone Screen (`/safe-zones/create`):**
    * *Required Capability:* Visual circle placement on a map with address search and radius slider to create new safe zones.
    * *Current Codebase Status:* Absent. [`SafeZoneEditorPage`](file:///d:/control/apps/haven_app/lib/features/safe_zones/views/pages/safe_zone_editor_page.dart) can only edit pre-existing safe zones; creation is refused due to absent database INSERT grant.

### 3.5 Multi-Parent & Family Management
12. **Invite Co-Parent / Guardian Screen (`/family/invite`):**
    * *Required Capability:* Send an invitation email or generate an invite code for a spouse or guardian to join the family circle.
    * *Current Codebase Status:* Absent. Refused on [`FamilyPage`](file:///d:/control/apps/haven_app/lib/features/family/views/pages/family_page.dart#L104) via `BlockedNotice`.
13. **Child Profile Provisioning Screen (`/family/create-child`):**
    * *Required Capability:* Create a child profile record directly from the parent app before device pairing.
    * *Current Codebase Status:* Absent. Child profiles are currently only created automatically when a device pairs.

---

## 4. SCREEN COMPONENT & STATE MATRIX (ALL 26 ROUTES)

| # | Route | Page Class | Form Validations | Loading State | Empty State | Error State | Blocked State | Data Reality |
|---|---|---|---|---|---|---|---|---|
| 1 | `/` | `SplashPage` | N/A | LinearProgressIndicator | N/A | Stalled Notice + Retry | BlockedNotice (Unconfigured) | Live Init |
| 2 | `/sign-in` | `SignInPage` | Email regex, Password non-empty | Button spinner + disabled fields | N/A | Field & Form error banners | BlockedNotice (Firebase token) | Supabase Auth |
| 3 | `/register` | `RegisterPage` | Name length, Email regex, Password >=8 | Button spinner + disabled fields | N/A | Field & Form error banners | BlockedNotice (Refused seam) | Supabase Auth |
| 4 | `/session-ended` | `SessionEndedPage` | Argument validation | N/A | N/A | Fallback message | N/A | Local Route Args |
| 5 | `/onboarding` | `OnboardingPage` | Consent toggle, Family name <=80 | Button spinner + disabled field | N/A | Message banner | BlockedNotice (Consent schema) | Edge Function Seam |
| 6 | `/dashboard` | `DashboardPage` | N/A | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (F6 devices grant) | Live Multi-Table Query |
| 7 | `/family` | `FamilyPage` | Family name 1..80, modified check | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Co-parent RPCs) | Live DB Query |
| 8 | `/family/child` | `ChildProfilePage` | Child ID argument validation | StateView circular indicator | `_NotInFamily` card | StateView retry card | BlockedNotice (F6 & Removal) | Live DB Query |
| 9 | `/pairing` | `PairingPage` | Request status evaluation | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Withdrawal RPC) | Live DB Query |
| 10 | `/pairing/code` | `PairingCodePage` | Family ID match check | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Pairing Edge Func) | Architecture Refusal |
| 11 | `/devices` | `DevicesPage` | N/A | StateView circular indicator | `_NoDevices` card | StateView retry card | BlockedNotice (F6 devices grant) | Architecture Refusal |
| 12 | `/devices/detail` | `DeviceDetailPage` | Device ID argument check | Card-level progress indicator | `_NoDeviceNamed` | `_Retry` card | BlockedNotice (Revoke & Recovery) | Live DB + Refusal |
| 13 | `/devices/activity` | `ActivityPage` | Duration & timestamp parsing | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (F6 unnamed dev) | Live DB Query |
| 14 | `/devices/commands` | `CommandsPage` | Command status evaluation | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Command write gap) | Live DB Query |
| 15 | `/devices/policies` | `PoliciesPage` | Enforcement status evaluation | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Policy write gap) | Live DB Query |
| 16 | `/devices/location` | `LocationPage` | Coordinate accuracy parsing | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Presence geofence) | Live DB Query |
| 17 | `/safe-zones` | `SafeZonesPage` | Radius & active state parsing | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Create zone gap) | Live DB Query |
| 18 | `/safe-zones/editor` | `SafeZoneEditorPage` | Lat [-90,90], Lng [-180,180], Radius [10,10000] | Save button spinner | N/A | Live `ZoneFieldError` | `ZoneWriteResult` BlockedNotice | Live DB Mutation |
| 19 | `/remote-sessions` | `RemoteSessionsPage` | Session lifecycle evaluation | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Start session RPC) | Live DB Query |
| 20 | `/remote-session` | `RemoteSessionDetailPage` | Session ID argument check | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Media TURN gap) | Live DB Query |
| 21 | `/notifications` | `NotificationsPage` | Severity mapping | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Push delivery gap) | Live DB Query |
| 22 | `/account` | `AccountPage` | Name 1..60, modified check | StateView circular indicator | `_NeedsSetup` card | StateView retry card | BlockedNotice (Password/Email/Del) | Live DB Mutation |
| 23 | `/settings` | `SettingsPage` | Theme enum validation | Central circular indicator | N/A | N/A | BlockedNotice (Prompt gap) | Local Preferences |
| 24 | `/settings/permissions` | `PermissionStatusPage` | Native bridge decode validation | Local UI render | N/A | `_Unreachable` card | BlockedNotice (Notification gap) | Native OS MethodChannel |
| 25 | `/settings/about` | `AboutPage` | Missing defines evaluation | Local UI render | N/A | N/A | BlockedNotice (Unconfigured) | Local Config Inspection |
| 26 | `/unknown` | `NotFoundPage` | Route string extraction | Local UI render | N/A | 404 honest notice | BlockedNotice (Screen unbuilt) | Route Fallback |

---

## 5. AUDIT FINDINGS & RECOMMENDATIONS

1. **Architectural Purity:** The frontend maintains a rare, 100% compliant refusal posture. There is no fake data, no dummy charts, and zero simulated backend responses.
2. **Dead Button Elimination:** All 26 registered screens have zero dangling callbacks (`onPressed: () {}`).
3. **Immediate Missing Screens Priority:**
   * Priority 1: Implement `/forgot-password` and `/reset-password` flows to avoid parent lockout.
   * Priority 2: Implement `/devices/limits/editor` and `/devices/apps/blocklist` to provide actual parental control policy editing.
   * Priority 3: Add an interactive Map View (`/devices/location/map`) for spatial context.
