# Modules A, B, C: Authentication & Account UI, Parent Onboarding, Family Management

def register_modules_a_b_c(add_feature):
    # MODULE A: AUTHENTICATION AND ACCOUNT UI (18 features)
    add_feature(
        fid="AUTH-01",
        module="Module A: Authentication and Account UI",
        name="Application Splash & Readiness Probe",
        expected="Initial entry screen displayed on app launch. Probes backend readiness defines, inspects local secure vault for persisted session tokens, and queries profile existence. Automatically navigates to '/dashboard' if valid profile exists, to '/onboarding' if session exists but profile is unprovisioned, or to '/sign-in' if no session is stored. If backend defines are missing or unconfigured, displays connection state and halts on splash with a diagnostic notice rather than rendering an empty dashboard.",
        screens="SplashPage (Route: '/')",
        actions="Launch app, observe connection status, view missing define diagnostic notes.",
        ui_states="Connecting (loading spinner), Stalled (diagnostic warning banner with missing defines), Away (navigating out).",
        controller="SplashController (`apps/haven_app/lib/features/authentication/controllers/splash_controller.dart`)",
        model="BackendStatus, BackendReadiness, AuthSession, Profile",
        service="HavenBackend (`packages/haven_api/lib/src/haven_backend.dart`), SecureVault (`apps/haven_app/lib/core/storage/secure_vault.dart`)",
        native="None",
        deps="None (Root entrypoint)",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/views/pages/splash_page.dart:18-50\napps/haven_app/lib/features/authentication/controllers/splash_controller.dart:44-88\ntest/shell/splash_controller_test.dart",
        missing="Verified offline with mock backend handle; live staging credentials pending external configuration.",
        priority="P0",
        classification="Shell / Auth Lifecycle"
    )

    add_feature(
        fid="AUTH-02",
        module="Module A: Authentication and Account UI",
        name="Welcome / Intro Onboarding Carousel",
        expected="Multi-slide introductory pager introducing Haven's philosophy: transparent family protection, screen time boundaries, geofence safety alerts, and zero stealth monitoring. Allows first-time parents to understand the app before registering.",
        screens="WelcomePage / IntroCarouselPage (New Route: '/welcome')",
        actions="Swipe through intro slides, tap 'Get Started' to navigate to register, tap 'Already have an account? Sign in' to navigate to sign in.",
        ui_states="Slide active states (0 to 2), page dot indicators, animated transitions.",
        controller="WelcomeController (GetxController with RxInt currentSlide)",
        model="IntroSlideModel(title, description, assetPath)",
        service="PreferencesStore (`apps/haven_app/lib/core/storage/preferences_store.dart`)",
        native="None",
        deps="AUTH-01",
        status="NOT IMPLEMENTED",
        evidence="None (`splash_page.dart` jumps directly to `sign_in_page.dart` without welcome presentation).",
        missing="Welcome carousel UI, slide illustrations, page indicator dots, route declaration in `AppRoutes`.",
        priority="P2",
        classification="Presentation UI"
    )

    add_feature(
        fid="AUTH-03",
        module="Module A: Authentication and Account UI",
        name="Email & Password Sign In Form",
        expected="Authentication form allowing parents to sign into their existing Haven account. Provides email input, password input with visibility toggle, form error banner, and 'Sign in' action button. Disables inputs while network call is in flight. Navigates to dashboard or onboarding upon success.",
        screens="SignInPage (Route: '/sign-in')",
        actions="Enter email, enter password, toggle password visibility, tap 'Sign in', tap 'Create an account' link.",
        ui_states="Default/Idle, Validation Error (inline captions), In-Flight Busy (spinner on button, inputs disabled), Auth Error (error banner at top).",
        controller="SignInController (`apps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart`)",
        model="AuthSession (`packages/haven_api/lib/src/auth_contracts.dart`)",
        service="AuthRepository (`apps/haven_app/lib/features/authentication/data/auth_repository.dart`), UserAuth",
        native="None",
        deps="AUTH-07, AUTH-08, AUTH-09, AUTH-10",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart:18-55\napps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart:25-95\ntest/authentication/sign_in_page_test.dart",
        missing="Verified offline with FakeAuthRepository; live Supabase GoTrue endpoint integration pending staging deployment.",
        priority="P0",
        classification="Auth UI"
    )

    add_feature(
        fid="AUTH-04",
        module="Module A: Authentication and Account UI",
        name="Parent Account Registration Form",
        expected="Registration form for new parents. Captures display name (max 60 chars), valid email, and strong password (min 8 chars). Performs client-side validation, submits registration request to auth backend, and redirects to onboarding wizard upon account creation.",
        screens="RegisterPage (Route: '/register')",
        actions="Enter full name, enter email, enter password, toggle password visibility, tap 'Create account'.",
        ui_states="Default, Validation Error (per-field captions), Submission Busy (loading spinner, disabled fields), Submission Failure (banner).",
        controller="RegisterController (`apps/haven_app/lib/features/authentication/controllers/register_controller.dart`)",
        model="AuthSession, Profile (`packages/haven_models/lib/src/family_models.dart`)",
        service="AuthRepository, ProfileStore (`packages/haven_api/lib/src/supabase_profile_store.dart`)",
        native="None",
        deps="AUTH-07, AUTH-08, AUTH-09, AUTH-10",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/views/pages/register_page.dart:18-74\napps/haven_app/lib/features/authentication/controllers/register_controller.dart:25-85\ntest/authentication/register_controller_test.dart",
        missing="Verified offline; live database trigger `handle_new_user` unexecuted in staging.",
        priority="P0",
        classification="Auth UI"
    )

    add_feature(
        fid="AUTH-05",
        module="Module A: Authentication and Account UI",
        name="Forgot Password / Password Reset Request",
        expected="Screen allowing parent who forgot password to submit their registered email address. Validates email format, sends password recovery request to auth service, shows rate-limit cooldown, and displays success instructions directing user to check inbox.",
        screens="ForgotPasswordPage (New Route: '/forgot-password')",
        actions="Enter email address, tap 'Send Reset Link', tap 'Back to Sign In'.",
        ui_states="Initial, Sending (spinner), Sent Confirmation (card with resend timer), Error (rate-limited, invalid email).",
        controller="ForgotPasswordController (GetxController with RxBool isSent, RxInt cooldownSeconds)",
        model="AuthFailure (`packages/haven_core/lib/src/failures.dart`)",
        service="AuthRepository (`resetPasswordForEmail`)",
        native="None",
        deps="AUTH-08, AUTH-09",
        status="NOT IMPLEMENTED",
        evidence="apps/haven_app/lib/features/account/data/account_repository.dart:89-94 (records password-change gap).",
        missing="ForgotPasswordPage view, ForgotPasswordController, route addition to `AppRoutes`, `resetPasswordForEmail` contract in `haven_api`.",
        priority="P1",
        classification="Auth Flow"
    )

    add_feature(
        fid="AUTH-06",
        module="Module A: Authentication and Account UI",
        name="Password Reset Completion Form",
        expected="Landing screen triggered via email deep link (`haven://reset-password?token=...`). Verifies recovery token, prompts parent to enter new password and confirm password, validates length >= 8, submits new credentials, and transitions to sign-in upon confirmation.",
        screens="ResetPasswordPage (New Route: '/reset-password')",
        actions="Enter new password, confirm new password, tap 'Update Password'.",
        ui_states="Token Validating, Input Form, Updating Busy, Success Notice, Expired/Invalid Token Error.",
        controller="ResetPasswordController (GetxController)",
        model="Result (`packages/haven_core/lib/src/result.dart`)",
        service="AuthRepository (`updateUserPassword`)",
        native="None",
        deps="AUTH-05, AUTH-07, AUTH-08",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="ResetPasswordPage, deep link URL intent handler, token verification controller, update password mutation.",
        priority="P1",
        classification="Auth Flow"
    )

    add_feature(
        fid="AUTH-07",
        module="Module A: Authentication and Account UI",
        name="Password Visibility Toggle",
        expected="Interactive suffix action button inside password fields allowing parent to toggle between hidden masked bullets and clear readable text. Toggles reactive boolean state and switches button label between 'Show' and 'Hide'.",
        screens="SignInPage, RegisterPage, AccountPage",
        actions="Tap 'Show' / 'Hide' button in password input.",
        ui_states="Obscured (masked characters, label 'Show'), Revealed (plaintext characters, label 'Hide').",
        controller="SignInController.showPassword (`sign_in_controller.dart:21`), RegisterController.showPassword (`register_controller.dart:21`)",
        model="RxBool",
        service="None (Pure UI state)",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart:81-100\napps/haven_app/lib/features/authentication/views/pages/register_page.dart:82-101",
        missing="None. Fully implemented and verified in widget tests.",
        priority="P0",
        classification="Form UX"
    )

    add_feature(
        fid="AUTH-08",
        module="Module A: Authentication and Account UI",
        name="Client-Side Input Validation",
        expected="Pure synchronous validation rules enforcing: non-empty email with valid RFC email format; display name between 1 and 60 non-whitespace characters; password with minimum 8 characters. Inline validation error messages display below fields on submit or unfocus.",
        screens="SignInPage, RegisterPage, AccountPage, OnboardingPage",
        actions="Type in form fields, submit form.",
        ui_states="Valid (normal outline), Invalid (caption error line rendered below field).",
        controller="Form controllers via `validateEmail`, `validatePassword`, `validateDisplayName`",
        model="ValidationFailure (`packages/haven_core/lib/src/failures.dart`)",
        service="Validation module (`packages/haven_core/lib/src/validation.dart:1-60`)",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="packages/haven_core/lib/src/validation.dart:1-60\napps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart:45-65\npackages/haven_core/test/haven_core_test.dart",
        missing="None. 100% unit tested pure logic.",
        priority="P0",
        classification="Core Validation"
    )

    add_feature(
        fid="AUTH-09",
        module="Module A: Authentication and Account UI",
        name="Form Submission & Busy/Loading States",
        expected="When an auth action is initiated, form inputs are locked (`enabled: false`), keyboard is dismissed, and primary action button displays a circular progress indicator while disabling click events to prevent duplicate submissions.",
        screens="SignInPage, RegisterPage, OnboardingPage, AccountPage",
        actions="Tap submit button.",
        ui_states="Idle, Busy (`busy.value == true`), Completed, Failed.",
        controller="SignInController.busy, RegisterController.busy, HavenButton widget",
        model="RxBool",
        service="None (UI Component state)",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="apps/haven_app/lib/shared/components/haven_button.dart:30-55\napps/haven_app/lib/features/authentication/views/pages/sign_in_page.dart:40-47",
        missing="None. Fully verified across all auth screens.",
        priority="P0",
        classification="Form UX"
    )

    add_feature(
        fid="AUTH-10",
        module="Module A: Authentication and Account UI",
        name="Auth Error Handling & Human-Readable Mapping",
        expected="Translates low-level GoTrue/network exceptions into clean user-facing error strings without leaking stack traces or technical details (e.g. 'Invalid login credentials', 'An account with this email already exists', 'Connection refused').",
        screens="SignInPage, RegisterPage, AccountPage",
        actions="Trigger network error or enter wrong credentials.",
        ui_states="Error banner visible in red (`HavenColors.bad`) above submit button.",
        controller="SignInController.formError, RegisterController.formError",
        model="HavenFailure, AuthFailure, NetworkFailure",
        service="FailureMapper (`packages/haven_api/lib/src/failure_mapper.dart:15-45`)",
        native="None",
        deps="None",
        status="COMPLETE",
        evidence="packages/haven_api/lib/src/failure_mapper.dart:15-45\napps/haven_app/lib/features/authentication/controllers/sign_in_controller.dart:75-85\ntest/authentication/sign_in_page_test.dart",
        missing="None for mapping architecture; verified in unit tests.",
        priority="P0",
        classification="Error Architecture"
    )

    add_feature(
        fid="AUTH-11",
        module="Module A: Authentication and Account UI",
        name="Session State Watch & Reactive Routing",
        expected="Background service listening to auth state stream (`UserAuth.states`). Detects token revocation, user logout, or session expiration; flushes in-memory cache and automatically navigates user to `/session-ended` or `/sign-in`.",
        screens="All screens (Background session monitor)",
        actions="Background token revocation or session expiry.",
        ui_states="None (Global route redirection).",
        controller="SessionWatch (`apps/haven_app/lib/features/authentication/services/session_watch.dart`)",
        model="AuthStateSnapshot, AuthStatusKind (`packages/haven_api/lib/src/auth_contracts.dart`)",
        service="UserAuth, SecureVault",
        native="None",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/services/session_watch.dart:18-48\ntest/authentication/session_watch_test.dart",
        missing="Verified offline with stream fakes; live token rotation unevidenced in staging.",
        priority="P0",
        classification="Auth State"
    )

    add_feature(
        fid="AUTH-12",
        module="Module A: Authentication and Account UI",
        name="Session Timeout / Termination Screen",
        expected="Dedicated screen informing the parent that their login session has ended. Displays human-readable reason (e.g. 'Signed out on another device', 'Session expired for security') and provides primary CTA button to return to Sign In.",
        screens="SessionEndedPage (Route: '/session-ended')",
        actions="View reason message, tap 'Sign in again' button.",
        ui_states="Displaying termination notice, navigating to sign in.",
        controller="None (Stateless page driven by route argument `String reason`)",
        model="String reason",
        service="None",
        native="None",
        deps="AUTH-11",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/authentication/views/pages/session_ended_page.dart:1-55\napps/haven_app/lib/app/routes/app_pages.dart:70-74",
        missing="None. Fully implemented and registered in route table.",
        priority="P0",
        classification="Auth Flow"
    )

    add_feature(
        fid="AUTH-13",
        module="Module A: Authentication and Account UI",
        name="Account Profile Information Display",
        expected="Displays the authenticated parent's account facts: email address, unique account UUID, assigned family role chip ('Parent', 'Child', 'Role not set'), and explanation that Haven does not alter role from client.",
        screens="AccountPage (Route: '/account')",
        actions="Open Account from dashboard or settings, review credentials.",
        ui_states="Loading, Data Loaded, Provisioning Gap ('Haven has no record for this account yet').",
        controller="AccountController (`apps/haven_app/lib/features/account/controllers/account_controller.dart`)",
        model="AccountInfo, Profile, ProfileRole (`packages/haven_models/lib/src/enums_identity.dart`)",
        service="AccountRepository (`apps/haven_app/lib/features/account/data/account_repository.dart`)",
        native="None",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:49, 93-120\ntest/account/account_page_test.dart",
        missing="None for offline display; live profile row minting blocked by undeployed staging schema.",
        priority="P0",
        classification="Account UI"
    )

    add_feature(
        fid="AUTH-14",
        module="Module A: Authentication and Account UI",
        name="Account Display Name Modification",
        expected="Form section in Account allowing parent to edit the name shown to their family. Enforces length <= 60 characters; saves via `ProfileStore.updateDisplayName`; shows reactive busy state and success feedback.",
        screens="AccountPage (Route: '/account')",
        actions="Edit display name text field, tap 'Save name'.",
        ui_states="Unmodified (button disabled), Modified (button active), Saving (spinner), Saved Success, Error.",
        controller="AccountController.displayName, AccountController.canSave, AccountController.save",
        model="Profile (`packages/haven_models/lib/src/family_models.dart`)",
        service="AccountRepository.rename, ProfileStore.updateDisplayName",
        native="None",
        deps="AUTH-08, AUTH-13",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:122-149\napps/haven_app/lib/features/account/controllers/account_controller.dart:50-64\napps/haven_app/lib/features/account/data/account_repository.dart:73-83",
        missing="Verified offline with mock ProfileStore; live database update policy in staging undeployed.",
        priority="P1",
        classification="Account Mutation"
    )

    add_feature(
        fid="AUTH-15",
        module="Module A: Authentication and Account UI",
        name="Account Deletion Request Flow",
        expected="Parent initiates permanent account deletion. System displays destructive confirmation dialog warning that all linked children, devices, policies, and safety alert histories will be orphaned or erased. Upon approval, invokes backend cascade deletion.",
        screens="AccountPage (Route: '/account')",
        actions="Tap 'Delete account', read warning, type confirmation phrase, confirm deletion.",
        ui_states="Refusal Notice ('Haven cannot delete your account from this app yet'), Confirmation Dialog, Deleting Busy, Deletion Complete.",
        controller="AccountController.accountDeletion",
        model="BlockedFailure (`packages/haven_core/lib/src/failures.dart`)",
        service="AccountRepository.accountDeletion (`apps/haven_app/lib/features/account/data/account_repository.dart:103`)",
        native="None",
        deps="AUTH-13",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:172-196\napps/haven_app/lib/features/account/data/account_repository.dart:103-107",
        missing="UI currently renders refusal `BlockedNotice` ('no approved contract deletes an auth user'). Cascade deletion contract and UI confirmation dialog missing.",
        priority="P2",
        classification="Account Mutation"
    )

    add_feature(
        fid="AUTH-16",
        module="Module A: Authentication and Account UI",
        name="Email Address Change Flow",
        expected="Allows authenticated parent to enter a new email address. System validates format, checks against collisions, dispatches verification emails to both old and new addresses, and updates auth session once verified.",
        screens="AccountPage / ChangeEmailPage",
        actions="Tap 'Change Email', enter new email, submit, confirm via inbox link.",
        ui_states="Refusal Notice ('Haven cannot change your email address yet'), Form Input, Verification Pending.",
        controller="AccountController.emailChange",
        model="BlockedFailure",
        service="AccountRepository.emailChange (`account_repository.dart:96-101`)",
        native="None",
        deps="AUTH-13",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:184\napps/haven_app/lib/features/account/data/account_repository.dart:96-101",
        missing="UI renders `BlockedNotice` refusal. Form fields, controller mutator, and Supabase Auth `updateUser({email})` contract missing.",
        priority="P2",
        classification="Account Mutation"
    )

    add_feature(
        fid="AUTH-17",
        module="Module A: Authentication and Account UI",
        name="In-App Password Change Flow",
        expected="Allows authenticated parent to change password from Account settings. Requires entry of current password, entry of new password >= 8 characters, and confirmation.",
        screens="AccountPage / ChangePasswordSheet",
        actions="Tap 'Change Password', enter current password, enter new password, tap 'Save Password'.",
        ui_states="Refusal Notice ('Haven cannot change your password yet'), Form Dialog, Updating, Success.",
        controller="AccountController.passwordChange",
        model="BlockedFailure",
        service="AccountRepository.passwordChange (`account_repository.dart:89-94`)",
        native="None",
        deps="AUTH-07, AUTH-08, AUTH-13",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:183\napps/haven_app/lib/features/account/data/account_repository.dart:89-94",
        missing="UI renders `BlockedNotice` refusal. In-app password change form and Supabase Auth `updateUser({password})` contract missing.",
        priority="P1",
        classification="Security Settings"
    )

    add_feature(
        fid="AUTH-18",
        module="Module A: Authentication and Account UI",
        name="Global User Logout & Confirmation Sheet",
        expected="Parent initiates sign out from Account or Settings. Displays confirmation sheet (`ConfirmSheet.confirm`), clears tokens from secure vault, wipes cached family scope, cancels active change feeds, and navigates to `/sign-in`.",
        screens="AccountPage, SettingsPage",
        actions="Tap 'Sign out', tap 'Sign out' inside confirmation sheet.",
        ui_states="Confirmation Sheet Active, Signing Out Busy, Redirecting.",
        controller="AccountController.signOut (`apps/haven_app/lib/features/account/controllers/account_controller.dart:65`)",
        model="Result<void>",
        service="AuthRepository.signOut, SecureVault.clearTokens",
        native="None",
        deps="AUTH-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/account/views/pages/account_page.dart:78-89\napps/haven_app/lib/features/account/controllers/account_controller.dart:65-75\ntest/account/account_page_test.dart",
        missing="None. Fully verified in unit and widget tests.",
        priority="P0",
        classification="Auth Flow"
    )

    # MODULE B: PARENT ONBOARDING (11 features)
    add_feature(
        fid="ONBD-01",
        module="Module B: Parent Onboarding",
        name="Onboarding Welcome & Transparency Flow",
        expected="First-run wizard introducing Haven's parent-child trust philosophy before family creation. Clearly states that monitoring is visible and transparent on the child's phone, without secret root access or hidden services.",
        screens="OnboardingPage (Route: '/onboarding')",
        actions="Launch onboarding, read philosophy introduction.",
        ui_states="Explain Step (`OnboardingStep.explain`).",
        controller="OnboardingController (`apps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart`)",
        model="OnboardingStep enum (`explain`, `setup`)",
        service="OnboardingRepository (`apps/haven_app/lib/features/onboarding/data/onboarding_repository.dart`)",
        native="None",
        deps="AUTH-04",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:34-77\ntest/onboarding/onboarding_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Onboarding UI"
    )

    add_feature(
        fid="ONBD-02",
        module="Module B: Parent Onboarding",
        name="What Haven Watches Transparency Disclosure",
        expected="Itemized transparency checklist disclosing monitoring scope: installed apps & daily usage duration, foreground-only location updates, and enforced policy rules. Prohibits fabricated promises.",
        screens="OnboardingPage (Route: '/onboarding')",
        actions="Read points, view gap notice.",
        ui_states="Visible list of bullet points, refusal notice regarding missing consent table.",
        controller="OnboardingController",
        model="None (Static transparency contract)",
        service="None",
        native="None",
        deps="ONBD-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:37-69",
        missing="None.",
        priority="P0",
        classification="Compliance / Legal UI"
    )

    add_feature(
        fid="ONBD-03",
        module="Module B: Parent Onboarding",
        name="Parental Responsibility & Consent Checkbox",
        expected="Mandatory interactive checkbox where user legally affirms: 'I have read what Haven watches and I am the parent or guardian responsible for this child.' Toggling activates the 'I understand - continue' button.",
        screens="OnboardingPage (Route: '/onboarding')",
        actions="Tap checkbox to toggle consent state, tap continue button.",
        ui_states="Unchecked (button disabled), Checked (button enabled).",
        controller="OnboardingController.acknowledged (`onboarding_controller.dart:21`)",
        model="RxBool",
        service="None (In-memory consent gate; backend consent table uncreated)",
        native="None",
        deps="ONBD-02",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:70-76, 101-123\napps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart:35-45",
        missing="Backend DB lacks consent logging table (`schema-columns.md:293`); frontend gate is 100% complete.",
        priority="P0",
        classification="Consent Gate"
    )

    add_feature(
        fid="ONBD-04",
        module="Module B: Parent Onboarding",
        name="Family Profile Setup & Family Naming",
        expected="Form prompting parent to name their family group (e.g. 'The Miller Family', max 80 chars). Validates non-empty input; creates family record via backend call; binds parent as family owner.",
        screens="OnboardingPage (Route: '/onboarding')",
        actions="Type family name, tap 'Create my family'.",
        ui_states="Setup Step (`OnboardingStep.setup`), Typing, Submitting Busy, Error Banner.",
        controller="OnboardingController.familyName, OnboardingController.finish",
        model="Family (`packages/haven_models/lib/src/family_models.dart`)",
        service="OnboardingRepository.createFamily (`onboarding_repository.dart:60-70`), EdgeCaller (`auth-bootstrap`)",
        native="None",
        deps="ONBD-03, AUTH-08",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:125-177\napps/haven_app/lib/features/onboarding/controllers/onboarding_controller.dart:50-70\ntest/onboarding/onboarding_controller_test.dart",
        missing="UI complete and tested offline; backend Edge Function `auth-bootstrap` undeployed in staging.",
        priority="P0",
        classification="Onboarding Flow"
    )

    add_feature(
        fid="ONBD-05",
        module="Module B: Parent Onboarding",
        name="Child Profile Creation Form",
        expected="Dedicated onboarding step allowing parent to create their first child profile: enters child's name (e.g. 'Leo'), age or birth year, and avatar icon/color before device pairing begins.",
        screens="OnboardingPage / ChildSetupStep",
        actions="Enter child name, select age bracket, choose avatar color, tap 'Save & Next'.",
        ui_states="Form Empty, Validating, Submitting, Success.",
        controller="OnboardingController (requires child form expansion)",
        model="ChildProfileRecord(name, birthYear, avatarColor)",
        service="FamilyRepository.createChildProfile",
        native="None",
        deps="ONBD-04",
        status="NOT IMPLEMENTED",
        evidence="onboarding_page.dart:169-173 (notes 'Adding a child... comes next, from the family and pairing screens').",
        missing="Child creation form fields, child avatar picker, and controller state in onboarding flow.",
        priority="P1",
        classification="Onboarding Flow"
    )

    add_feature(
        fid="ONBD-06",
        module="Module B: Parent Onboarding",
        name="Child Device Setup Walkthrough Guide",
        expected="Visual step-by-step onboarding guide showing parent how to install Haven Child app on child's Android phone, open the pairing screen, and scan QR code or enter PIN.",
        screens="OnboardingDeviceGuidePage (New Step)",
        actions="Swipe through instructions: Step 1 Install, Step 2 Open, Step 3 Link.",
        ui_states="Step 1, Step 2, Step 3 with active illustration.",
        controller="OnboardingController",
        model="InstructionStepModel(stepNumber, title, body, assetPath)",
        service="None",
        native="None",
        deps="ONBD-04",
        status="NOT IMPLEMENTED",
        evidence="None in onboarding wizard (only brief text in `pairing_code_page.dart`).",
        missing="Multi-step visual guide components and child setup illustrations.",
        priority="P1",
        classification="Instructional UI"
    )

    add_feature(
        fid="ONBD-07",
        module="Module B: Parent Onboarding",
        name="Child Permissions Advance Notice",
        expected="Educational screen informing parents what permissions will be requested on child's device (Usage Access, Location, Device Admin) and how they protect child safety without stealth snooping.",
        screens="OnboardingPermissionsOverviewPage",
        actions="Review permission cards, tap 'I Understand'.",
        ui_states="List of permission cards with icons and parental justification.",
        controller="OnboardingController",
        model="PermissionExplanationModel",
        service="None",
        native="None",
        deps="ONBD-06",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/settings/views/pages/permission_status_page.dart:22-50",
        missing="Card exists on settings screen, but not integrated into the onboarding flow.",
        priority="P1",
        classification="Instructional UI"
    )

    add_feature(
        fid="ONBD-08",
        module="Module B: Parent Onboarding",
        name="Onboarding Step Progress Indicator",
        expected="Top progress bar or segmented stepper indicating current onboarding progression (Step 1 of 4: Ethics & Consent, Step 2 of 4: Family Name, Step 3 of 4: Child Profile, Step 4 of 4: Device Pairing).",
        screens="OnboardingPage",
        actions="Observe progress updating as steps advance.",
        ui_states="Step 1/4, 2/4, 3/4, 4/4 active bar segments.",
        controller="OnboardingController.currentStepIndex",
        model="RxInt",
        service="None",
        native="None",
        deps="ONBD-01",
        status="NOT IMPLEMENTED",
        evidence="onboarding_page.dart:24 (currently uses binary switch without progress bar).",
        missing="Header stepper widget, step index state, progress bar UI.",
        priority="P1",
        classification="Navigation UX"
    )

    add_feature(
        fid="ONBD-09",
        module="Module B: Parent Onboarding",
        name="Onboarding Navigation Controls (Back / Skip)",
        expected="Navigation header controls: Back arrow allowing parent to return to previous step to correct input; Skip button for optional steps (e.g. 'Skip device pairing for now').",
        screens="OnboardingPage",
        actions="Tap Back button, tap Skip button.",
        ui_states="Back enabled on steps > 1; Skip visible on child/device steps.",
        controller="OnboardingController.previousStep, OnboardingController.skipStep",
        model="None",
        service="None",
        native="None",
        deps="ONBD-08",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/onboarding/views/pages/onboarding_page.dart:18 (has `showBack: false`).",
        missing="Back button navigation and Skip action buttons.",
        priority="P1",
        classification="Navigation UX"
    )

    add_feature(
        fid="ONBD-10",
        module="Module B: Parent Onboarding",
        name="Onboarding Completion Celebratory Screen",
        expected="Congratulatory screen upon family setup completion. Displays celebratory graphic, family summary card, and two action buttons: 'Pair First Device' or 'Go to Dashboard'.",
        screens="OnboardingSuccessPage (New Route: '/onboarding/complete')",
        actions="Tap 'Pair Device', tap 'Go to Dashboard'.",
        ui_states="Celebratory animation, summary card, action buttons.",
        controller="OnboardingController",
        model="FamilyBundle (`packages/haven_models/lib/src/family_models.dart`)",
        service="None",
        native="None",
        deps="ONBD-04",
        status="NOT IMPLEMENTED",
        evidence="onboarding_controller.dart:65 (currently jumps directly to Dashboard with `Get.offAllNamed`).",
        missing="Onboarding completion page, success graphics, and direct pairing CTA.",
        priority="P1",
        classification="Onboarding Flow"
    )

    add_feature(
        fid="ONBD-11",
        module="Module B: Parent Onboarding",
        name="Onboarding State Persistence & Resumption",
        expected="Persists current onboarding step in local storage (`PreferencesStore`). If app is closed mid-onboarding, relaunching automatically resumes parent at exact unfinished step instead of restarting at slide 1.",
        screens="SplashPage, OnboardingPage",
        actions="Relaunch app after killing process mid-onboarding.",
        ui_states="Resumed at saved step.",
        controller="OnboardingController, SplashController",
        model="String savedOnboardingStep",
        service="PreferencesStore (`apps/haven_app/lib/core/storage/preferences_store.dart`)",
        native="None",
        deps="ONBD-01, AUTH-01",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/authentication/controllers/splash_controller.dart:80",
        missing="Splash routes to `/onboarding` if profile is null, but step-level state is not saved in `PreferencesStore`.",
        priority="P1",
        classification="State Persistence"
    )

    # MODULE C: FAMILY MANAGEMENT (11 features)
    add_feature(
        fid="FAM-01",
        module="Module C: Family Management",
        name="Family Dashboard & Overview Hub",
        expected="Main family hub screen displaying family name, member directory, children cards, co-parents cards, and admin action buttons. Serves as root for family structure management.",
        screens="FamilyPage (Route: '/family')",
        actions="Open Family from dashboard navigation, scroll through sections.",
        ui_states="Loading, Data Loaded, Empty Setup Required.",
        controller="FamilyController (`apps/haven_app/lib/features/family/controllers/family_controller.dart`)",
        model="FamilyBundle, Family, FamilyMember (`packages/haven_models/lib/src/family_models.dart`)",
        service="FamilyRepository (`apps/haven_app/lib/features/family/data/family_repository.dart`), FamilyScope",
        native="None",
        deps="AUTH-01, ONBD-04",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/pages/family_page.dart:18-68\napps/haven_app/lib/features/family/controllers/family_controller.dart:25-70\ntest/family/family_page_test.dart",
        missing="None for offline display; backend read relies on deployed schema.",
        priority="P0",
        classification="Family UI"
    )

    add_feature(
        fid="FAM-02",
        module="Module C: Family Management",
        name="Family Member Directory Listing",
        expected="Scrollable directory categorized into 'Children' and 'Parents'. Shows avatar, member name, joined date, and chevron to detail view. Empty state shows informative explanation.",
        screens="FamilyPage (Route: '/family')",
        actions="Tap child member to open child profile.",
        ui_states="Populated with children/parents, empty children callout, empty parent callout.",
        controller="FamilyController.family",
        model="FamilyPerson, FamilyMember, Profile",
        service="FamilyRepository.load",
        native="None",
        deps="FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/widgets/people_card.dart:15-80\napps/haven_app/lib/features/family/views/pages/family_page.dart:49-62\ntest/family/family_repository_test.dart",
        missing="None.",
        priority="P0",
        classification="Family UI"
    )

    add_feature(
        fid="FAM-03",
        module="Module C: Family Management",
        name="Add Child Member Flow",
        expected="Dedicated button on family screen allowing parent to add a child to the family. Opens dialog to input child's name and age, creating child record and generating pairing invite token.",
        screens="FamilyPage, AddChildDialog (New UI)",
        actions="Tap 'Add Child', type child name, select age group, tap 'Create & Pair'.",
        ui_states="Dialog Active, Submitting, Success (opens Pairing).",
        controller="FamilyController",
        model="ChildProfileRecord",
        service="FamilyRepository.createChild",
        native="None",
        deps="FAM-01, PAIR-01",
        status="NOT IMPLEMENTED",
        evidence="family_page.dart:53-54 notes 'A child joins when you pair their device'. No standalone Add Child UI exists.",
        missing="Add Child dialog component, input fields, controller mutator, and RPC bridge.",
        priority="P1",
        classification="Family Mutation"
    )

    add_feature(
        fid="FAM-04",
        module="Module C: Family Management",
        name="Child Profile Viewer",
        expected="Detailed inspector for one child: displays name, role badge ('Child'), member since date, assigned paired devices count, and action links.",
        screens="ChildProfilePage (Route: '/family/child')",
        actions="Open child profile from Family page or Dashboard, view facts.",
        ui_states="Loading, Data Loaded, Not In Family Fallback ('This child is not in your family').",
        controller="ChildProfileController (`apps/haven_app/lib/features/family/controllers/child_profile_controller.dart`)",
        model="FamilyPerson, FamilyMember, Profile",
        service="FamilyRepository.childProfile, FamilyScope",
        native="None",
        deps="FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/pages/child_profile_page.dart:18-73\napps/haven_app/lib/features/family/controllers/child_profile_controller.dart:25-65\ntest/family/child_profile_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Family UI"
    )

    add_feature(
        fid="FAM-05",
        module="Module C: Family Management",
        name="Child Profile Editor",
        expected="Allows parent to edit child's display name, change avatar color/icon, or update birthday/age bracket from Child Profile screen.",
        screens="ChildProfilePage / EditChildDialog",
        actions="Tap 'Edit Profile', change name, save changes.",
        ui_states="Refusal Notice ('Haven cannot rewrite either name or role'), Form Active, Saving, Saved.",
        controller="ChildProfileController",
        model="BlockedFailure",
        service="FamilyRepository.updateChildProfile",
        native="None",
        deps="FAM-04",
        status="PLACEHOLDER",
        evidence="child_profile_page.dart:59-62 (states 'Their name and their role are set by the service... this screen cannot rewrite either').",
        missing="Edit profile button, name editor text field, controller update method, and Supabase RPC integration.",
        priority="P1",
        classification="Family Mutation"
    )

    add_feature(
        fid="FAM-06",
        module="Module C: Family Management",
        name="Parent Profile Card & Role Display",
        expected="Displays secondary co-parents in the family, showing email, display name, and Owner vs Co-Parent permission badge.",
        screens="FamilyPage",
        actions="View parent list, view role status.",
        ui_states="List of parents or empty state ('This family has no other parent').",
        controller="FamilyController.family",
        model="FamilyPerson, ProfileRole",
        service="FamilyRepository.load",
        native="None",
        deps="FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/widgets/people_card.dart:35-65\napps/haven_app/lib/features/family/views/pages/family_page.dart:58-62",
        missing="None.",
        priority="P1",
        classification="Family UI"
    )

    add_feature(
        fid="FAM-07",
        module="Module C: Family Management",
        name="Family Role Distinction & Permission Gates",
        expected="Distinguishes permissions between Family Owner (full admin, can delete family), Co-Parent (can configure rules and view telemetry), and Child (read-only/monitored). UI conditionally hides destructive actions for non-owners.",
        screens="FamilyPage, AccountPage, SettingsPage",
        actions="Observe permission-gated controls.",
        ui_states="Role chips ('Parent', 'Child', 'Owner'), disabled/hidden controls for non-owners.",
        controller="FamilyController, AccountController",
        model="ProfileRole (`packages/haven_models/lib/src/enums_identity.dart:15-35`)",
        service="FamilyScope (`apps/haven_app/lib/features/family/data/family_scope.dart`)",
        native="None",
        deps="AUTH-13, FAM-01",
        status="PARTIAL",
        evidence="packages/haven_models/lib/src/enums_identity.dart:15-35\napps/haven_app/lib/features/account/views/pages/account_page.dart:104-118",
        missing="Fine-grained client permission gates hiding owner-only settings from co-parents.",
        priority="P1",
        classification="Identity / Permissions"
    )

    add_feature(
        fid="FAM-08",
        module="Module C: Family Management",
        name="Family Member Online Status Indicators",
        expected="Displays live status dot (green for active, grey for offline) and relative last active timestamp next to each child member in family directory.",
        screens="FamilyPage, ChildProfilePage",
        actions="Observe live status dots.",
        ui_states="Online, Offline, Stale.",
        controller="FamilyController",
        model="Device (`packages/haven_models/lib/src/device_models.dart`)",
        service="DevicesRepository (`apps/haven_app/lib/features/child_devices/data/devices_repository.dart`)",
        native="None",
        deps="FAM-02, PAIR-11",
        status="UI ONLY",
        evidence="apps/haven_app/lib/features/family/views/widgets/people_card.dart:50-60",
        missing="Heartbeat telemetry stream from `devices.last_seen_at` not connected to family list.",
        priority="P1",
        classification="Telemetry UI"
    )

    add_feature(
        fid="FAM-09",
        module="Module C: Family Management",
        name="Remove Member Confirmation Flow",
        expected="Parent initiates removal of child or co-parent. Confirms destructive action in modal sheet; unlinks child devices; revokes family membership.",
        screens="ChildProfilePage, FamilyPage",
        actions="Tap 'Remove from family', read warning, tap 'Confirm Removal'.",
        ui_states="Refusal Notice ('Taking a child out of the family stops their reporting... no RPC lane'), Confirmation Sheet, Removal Busy, Complete.",
        controller="ChildProfileController.removalGap, FamilyController.removeParent",
        model="BlockedFailure",
        service="FamilyRepository.removeParent, FamilyRepository.removeChild",
        native="None",
        deps="FAM-04",
        status="PLACEHOLDER",
        evidence="child_profile_page.dart:78-93\napps/haven_app/lib/features/family/data/family_repository.dart:156-163",
        missing="UI renders `BlockedNotice` refusal ('Taking a child out of the family stops their reporting... no RPC lane'). Executable removal mutation absent.",
        priority="P1",
        classification="Family Mutation"
    )

    add_feature(
        fid="FAM-10",
        module="Module C: Family Management",
        name="Family Setup Empty & Error Fallback States",
        expected="When an account has no family row, renders clean setup callout ('This account has no family yet') with CTA button to start onboarding. If family fails to load, shows error with retry button.",
        screens="FamilyPage, ChildProfilePage",
        actions="Tap 'Set up family' button on empty card, tap 'Try again' on error.",
        ui_states="Empty Setup State, Network Error with Retry, Loading Spinner.",
        controller="FamilyController.family, StateView component",
        model="Result<FamilyBundle?>",
        service="None",
        native="None",
        deps="FAM-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/pages/family_page.dart:132-152\napps/haven_app/lib/features/family/views/pages/child_profile_page.dart:110-129",
        missing="None.",
        priority="P0",
        classification="Empty/Error UX"
    )

    add_feature(
        fid="FAM-11",
        module="Module C: Family Management",
        name="Family Name Modification & Persistence",
        expected="Allows family owner to edit the family name in an input field (max 80 chars) and save it. Disables button while saving; displays error if input invalid or network fails; updates locally on success.",
        screens="FamilyPage (Route: '/family')",
        actions="Edit family name field, tap 'Save name'.",
        ui_states="Pristine (disabled), Dirty (enabled), Saving (spinner), Success banner.",
        controller="FamilyController.familyName, FamilyController.canSave, FamilyController.save",
        model="Family",
        service="FamilyRepository.saveFamilyName (`apps/haven_app/lib/features/family/data/family_repository.dart:90-120`)",
        native="None",
        deps="FAM-01, AUTH-08",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/family/views/pages/family_page.dart:71-102\napps/haven_app/lib/features/family/controllers/family_controller.dart:50-65\ntest/family/family_write_test.dart",
        missing="Verified offline with FakeFamilyRepository; live database update policy in staging unexecuted.",
        priority="P0",
        classification="Family Mutation"
    )

print("Modules A, B, C registered.")
