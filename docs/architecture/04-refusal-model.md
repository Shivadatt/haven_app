# 04 — The refusal model (why most screens state a gap instead of showing data)

## 1. The rule this design exists to satisfy

The implementation brief is explicit: **do not fake a working feature**, and **do not claim a feature
works without a successful relevant test or a verified end-to-end result**. Given the deployment state
in [01](01-system-overview.md) — 0 tables, 0 functions, 0 credentials — almost every data path can
only be honest by refusing.

The codebase makes that a first-class outcome rather than an error to be hidden.

## 2. The vocabulary

`packages/haven_core/lib/src/`:

- `Result<T>` (`result.dart`) — every repository method returns `Result`, never a bare value.
- `HavenFailure` is a **sealed class** (`failures.dart:5`) with `AuthFailure`, `PermissionFailure`,
  `DevicePermissionFailure`, `NetworkFailure`, `BackendFailure`, `StorageFailure`,
  `ValidationFailure`, `BlockedFailure`, `UnknownFailure` (`:16-84`).
- `blocked<T>(String missing, {String? requirement})` (`blocked.dart:11-17`) is the one honest outcome
  for behaviour the requirements do not specify: it produces a `BlockedFailure` whose `detail` is
  literally `BLOCKED — SPECIFICATION REQUIRED: <what is missing>`. Its own doc comment says to call it
  **at the seam**, keep the interface typed, and **name exactly what is missing** (a spec section, a
  signed approval, a schema column).
- `isBlocked(...)` (`blocked.dart:20-22`) is thrown nowhere; it exists so view code can render the
  blocked state.

## 3. Where a refusal becomes a sentence the user can read

- `apps/haven_app/lib/shared/components/blocked_notice.dart:20-23` — `BlockedNotice.fromFailure(...)`
  renders the `missing` string itself, so the UI shows *what* is absent rather than "something went
  wrong".
- `apps/haven_app/lib/shared/components/state_view.dart:53` — the loading/error/empty/blocked switch
  treats `BlockedFailure` as its own state.
- `apps/haven_app/lib/core/errors/captured_gaps.dart` holds the refusals **more than one screen has to
  give**, so each screen renders the same words instead of paraphrasing the evidence and drifting from
  it (`captured_gaps.dart:3-8`). Two of them carry the citation inline: `deviceLaneMissing` (`:9-17`,
  F6) and `rpcLaneMissing` (`:24-33`, the 14-RPC EXECUTE wall).
- `apps/haven_app/lib/features/settings/views/pages/about_page.dart:103` surfaces
  `HavenConfig.missingDefines()` — the missing **names** — in the UI, and `main.dart:15-17` prints the
  same list in debug. A build states what it lacks.

## 4. What is refused today, with the reason the code itself gives

| Screen / seam | Requirement sentence shown | Reason in code | File:line |
| --- | --- | --- | --- |
| Account | "Haven cannot change your password yet." / "…your email address yet." / "…delete your account from this app yet." | no captured contract for those operations | `features/account/data/account_repository.dart:92`, `:99`, `:106` |
| Devices | "Haven cannot show this device in this build yet." / "…revoke a device…" / "…ask a device to re-check its rules yet." | F6 grant wall + no readable request contract | `features/child_devices/data/devices_repository.dart:37`, `:46`, `:55` |
| Pairing | "Haven cannot start an invite for a child…" / "…accept a pairing code…" / "…withdraw a pairing request…" | `pairing` slug not deployed; pepper secret not created | `features/device_pairing/data/pairing_repository.dart:103`, `:109`, `:118` |
| Family | "Haven cannot add another parent yet." / "…remove another parent yet." | RPC lane unexecutable (§2 of 03) | `features/family/data/family_repository.dart:147`, `:156`, `:163` |
| Push / alerts | "Haven cannot $what in this build yet." | A12-R unsigned, no `push_tokens` home, no send path | `features/notifications/services/alert_delivery.dart:47`; `packages/haven_api/lib/src/push_transport_impl.dart:21`, `:28` |
| Remote session media | "Haven cannot $what in this build yet." | TURN names not created; A13/A12-R unsigned | `features/remote_sessions/services/media_peer.dart:45` |
| Splash / session | shows `controller.message ?? config.status.message` | backend status is "not configured" when defines are absent | `features/authentication/views/pages/splash_page.dart:76` |
| 404 route | "Screen not implemented" | an unknown route is stated, not redirected | `features/dashboard/views/pages/not_found_page.dart:38` |
| Firebase sign-in | "Sign-in with a Firebase account is not available on this build yet." | A13 unsigned + mapping not loaded + provisioning gap | `packages/haven_api/lib/src/supabase_user_auth.dart:90-96` |

And in the backend, the mirror image: `501 command_spec_missing` for four `device-command` types,
`501 policy_schema_missing`-style gating on `device-policy`, `503 server_misconfigured` when the
service-role secrets are absent, `503 cron_not_configured` for a short cron secret, and `503` when
`IDENTITY_MODE` is flipped early. A fail-closed branch is a **feature** here; the brief forbids
turning one into a default, and `backend/supabase/config/environment.md` repeats that instruction.

## 5. What this model deliberately does NOT do

- It does not fabricate statistics, charts, "recent activity", or location accuracy the schema cannot
  support — the brief bans each of these and the repositories return `blocked` instead.
- It does not claim an Android restriction was applied. Enforcement is reported only when the OS
  confirms it (child-agent lane rule; see `android_native/child_services/`).
- It does not treat an empty list as success. Where a gap has no data, the state is `blocked` or
  explicitly "no family", not a blank card — `apps/haven_app/test/telemetry/telemetry_card_test.dart`
  asserts "no family says so instead of showing an empty log", and a sibling test asserts the card
  states it is a snapshot, not a live view.
- It does not silently degrade. `missingDefines()`, `BlockedNotice`, and the backend `503`s all make
  the absence visible.

Related: [01](01-system-overview.md) · [02](02-auth-and-identity.md) ·
[03](03-data-and-backend-contract.md) · [../testing/](../testing/README.md)
