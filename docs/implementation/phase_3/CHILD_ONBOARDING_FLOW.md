# HAVEN PARENTAL CONTROL — CHILD ONBOARDING FLOW

**Scope**: Phase 3 Stage 1 — the five-step child setup flow (`/onboarding`) and the boot decision that selects it
**Date**: November 6, 2026
**Status**: COMPLETE at ladder level 2 (Flutter logic + tests; 52 dedicated onboarding tests pass, 4 more end-to-end in the app-flow suite)
**Sources**: [`lib/features/onboarding/`](file:///d:/control/apps/haven_child/lib/features/onboarding), [`lib/features/splash/`](file:///d:/control/apps/haven_child/lib/features/splash), [`lib/core/session/child_local_session.dart`](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart)

---

## 1. Boot Decision (which screen the child sees first)

[`SplashController.boot()`](file:///d:/control/apps/haven_child/lib/features/splash/controllers/splash_controller.dart#L49-L82) opens storage, reads the profile row and reads the session, then routes:

| Stored state | Route | Why |
| :--- | :--- | :--- |
| no profile, no session | `/onboarding` at step 1 | genuine first launch |
| profile **and** session whose `profile_id` matches | `/profile` | setup is actually finished |
| profile but no session, or a session naming a different profile | `/onboarding` (which completes the missing half, never re-creating) | "finished" requires both halves to point at each other — never either alone |
| a persisted draft | `/onboarding` resumed at the saved step with the saved fields | kill-and-reopen honesty |
| storage open failed | stays on `/splash` with the typed message + "Try again" | no navigation on a failed boot |
| document corrupt | stays on `/splash`, message + "Try again" + the explicit developer reset | never auto-cleared |

The failure frame renders **only** when a real message exists — this was the Stage-1 lib bug fix (see [STAGE_1_IMPLEMENTATION_REPORT.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_IMPLEMENTATION_REPORT.md) §8), so a successful boot can never flash "The app could not start".

## 2. The Five Steps

[`OnboardingStep`](file:///d:/control/apps/haven_child/lib/features/onboarding/domain/onboarding_steps.dart) — the enum index **is** the persisted `step_index`, so resume is one integer. `fromIndex` clamps out-of-range values (a draft from a future build lands on a real step instead of crashing) and `progressLabel` renders "Step n of 5".

| # | Step | Body widget | Child does | Persists | Requests |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Welcome | [`welcome_step.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/views/steps/welcome_step.dart) | reads what the app is and is not ("Parent connection: Not connected", "Nothing is monitored yet") | step index | nothing |
| 2 | About you (`childProfile`) | [`profile_step.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/views/steps/profile_step.dart) | first name (max 60), one of four age brackets, one of eight avatars | step index + all three fields | nothing |
| 3 | This device (`deviceReview`) | [`device_review_step.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/views/steps/device_review_step.dart) | reads the same six `DeviceFactRows` the `/device` screen uses; may open `/device` on top | step index | nothing |
| 4 | Permissions (`permissionsIntro`) | [`permissions_intro_step.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/views/steps/permissions_intro_step.dart) | reads the four WHY explanations; may open `/permissions` on top | step index | **no permission, no dialog** |
| 5 | All set (`finish`) | [`completion_step.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/views/steps/completion_step.dart) | reviews the draft and taps "Create my profile" (busy label "Creating…") | the one profile write + session; clears the draft | nothing |

Age brackets are the parent app's vocabulary — `4-7`, `8-11`, `12-14`, `15-17` ([`child_profile_constants.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/data/child_profile_constants.dart)) — so one family sees one age language across both apps. Avatars are Material icons only, stored **by name** (`person`, `rocket`, `panda`, `star`, `bike`, `music`, `game`, `book`); `ChildAvatars.resolve` degrades to a neutral icon for an unknown name, so a later icon change cannot corrupt stored rows and no asset file ships ([`child_avatars.dart`](file:///d:/control/apps/haven_child/lib/features/onboarding/data/child_avatars.dart)).

## 3. Gate Rules (pure and side-effect free)

[`OnboardingFlow.blockerFor`](file:///d:/control/apps/haven_child/lib/features/onboarding/domain/onboarding_flow.dart) is the only place a step decides whether it may advance:

| Step | Blocker (returned verbatim to the UI) |
| :--- | :--- |
| welcome, deviceReview, permissionsIntro, finish | none — information steps never block |
| childProfile | `haven_core` `validateDisplayName` message (empty/too long), then `'Pick your age group.'` |

`OnboardingFlow.profileProblem` re-checks the same two rules at step 5, because a resumed draft may be incomplete even though step 2 was never visited this session. The gate blocks **without navigating and without saving** (a failed `goNext` leaves the draft one step behind — tested deliberately so the persisted state never lies about progress).

## 4. Resume Contract

[`OnboardingController`](file:///d:/control/apps/haven_child/lib/features/onboarding/controllers/onboarding_controller.dart) restores the draft in `onInit` (`restore()`), and re-persists step + fields on every `goNext`/`goBack` through `_persist`. Blank fields are stored as **absent**, not as empty strings. Out-of-range persisted indices clamp. A failing draft store renders an error with a working retry (`ChildStateView` → `controller.restore`); a failing *save* advances but tells the truth in `errorMessage`. `onClose` disposes the `TextEditingController`.

Resumed state is exercised by [`onboarding_resume_test.dart`](file:///d:/control/apps/haven_child/test/features/onboarding/onboarding_resume_test.dart) (5 tests: saved step + every value, stored fields visible in the UI, future-build index clamps, negative index clamps, continuing after restart does not re-save the old step).

## 5. Completion: exactly one profile, ever

[`OnboardingCompletion.call`](file:///d:/control/apps/haven_child/lib/features/onboarding/services/onboarding_completion.dart) is the only writer:

1. Read the stored profile first.
2. If a child profile already exists → **do not create**; finish by writing the session only (this is the "half-finished device" path the splash routes here).
3. If none exists → `profiles.create(displayName, ageBracket, avatar)`; a refusal (create-once, validation, role guard) is returned as a typed `Err` and shown, never swallowed.
4. Save `ChildLocalSession(profileId, createdAt)` through `ChildSessionStore`, then clear the draft. A session-write failure aborts before the draft is cleared, so no progress token is destroyed by a half-done write.

Three independent layers stop a duplicate row:

| Layer | Mechanism | Source |
| :--- | :--- | :--- |
| UI | "Create my profile" is disabled while `isSubmitting` is true | `completion_step.dart` |
| Controller | `finish()` returns immediately if a submit is in flight | `onboarding_controller.dart#L128` |
| Repository | explicit existence check → `ValidationFailure(detail: 'child_profile_create_once')` | `local_child_profile_repository.dart#L59-L67` |

The double-submit path is tested both as a fast double tap (no second create) and as a resumed already-finished state (completes instead of re-creating).

## 6. Navigation and Exit

`Continue`/`Back` are the only shell actions; `Back` is disabled on step 1 and cannot pass it, and both are hidden on the last step (finishing is `finish()`, not `goNext`). `/device` and `/permissions` are opened **on top** via the injected `push`, so `pop` returns to the same step; success exits with `finishRoute(ChildRoutes.profile)` (`Get.offNamed`), which is why a completed setup is not left behind in the stack.

## 7. Copy Discipline (what the child is told)

Fixed strings, single-sourced and asserted in tests rather than free-floating:

- `'No permission has been requested.'` — step 4 and the dashboard.
- `'Parent connection: Not connected'` — built from `ChildLocalSession.parentConnectionLabel`/`parentConnectionStatus`; the constant is deliberately not softened.
- `'Nothing is monitored yet'` — profile home chip and setup copy.
- `'Haven will save this on this device only. It happens once — the same profile cannot be created twice, and nothing here goes to a server.'` — step 5.
- Fields without a real read show `Unavailable` (`DeviceFacts.unavailable`), decided in `DeviceFactRows`, never per-widget.

## 8. Test Mapping

52 of the 167 child tests target this flow directly: [`onboarding_flow_test.dart`](file:///d:/control/apps/haven_child/test/features/onboarding/onboarding_flow_test.dart) (8, pure transitions), `onboarding_controller_test.dart` (11, restore/persist/navigation), `onboarding_finish_controller_test.dart` (5), `onboarding_completion_test.dart` (5, service-level), `onboarding_page_test.dart` (11, real widgets + gates + retry), `onboarding_completion_page_test.dart` (7), `onboarding_resume_test.dart` (5) — plus the 4 end-to-end app-flow tests in [`child_app_flow_test.dart`](file:///d:/control/apps/haven_child/test/app/child_app_flow_test.dart) (empty device → Start setup → five steps → profile home; re-running cannot create a second profile; profile links reach `/device` and `/permissions`; an unlisted route lands on the unknown page) and the narrow-screen step cases in `test/narrow/narrow_screens_test.dart`. Widget tests pump through `OnboardingDriver` with hand-written fakes and the real `ChildTheme` — no mock package, no stubbed `onPressed`. **All of it is host-side Flutter test evidence; none of it was observed on a device or emulator (NOT TESTED).**

## 9. Deferred / Out of Stage 1

| Item | Status | Gate |
| :--- | :--- | :--- |
| Real parent↔child pairing after setup | **BLOCKED** | D-5 / master-plan B-1 (no backend or approved rendezvous) |
| Pairing-code entry step in onboarding | **DEFERRED** | Stage 2, needs D-3 written spec |
| Native device facts on step 3 | **DEFERRED** | Stage 2+ native lane, D-4 |
| Profile **editing** UI after setup | **NOT IMPLEMENTED** (repository-level `update` exists and is tested) | Stage 8 dashboard scope |
| On-screen run on a device/emulator | **NOT TESTED** | P-1 |
