# Haven — feature status (16 features, as built 2026-11-04)

Feature-first GetX code lives in `apps/haven_app/lib/features/<name>/{bindings,controllers,data,services,views}`.
Routes are declared once in `apps/haven_app/lib/app/routes/app_routes.dart:9-34` (26 routes).
Tests are grouped by the same names in `apps/haven_app/test/<name>/`.

## How to read the verdict column

The brief's rule is "do not fake a working feature" and "do not claim that a feature works without a
successful relevant test or a verified end-to-end result". Both halves bind here, so there are three
distinct states and they are not interchangeable:

| Verdict | Meaning |
| --- | --- |
| **BUILT / TESTED OFFLINE** | UI + controller + repository exist, widget tests pass, and the behaviour asserted is reachable without a backend. Nothing more is claimed. |
| **BUILT / REFUSES AT THE SEAM** | The screen renders a stated gap (`blocked(...)`) because the backend lane it needs does not exist in staging. The refusal *is* the tested behaviour. |
| **NOT FUNCTIONAL E2E** | true of **every** feature that needs data: `parent-control-staging` has 0 tables, 0 SQL functions, 0 Edge Functions, 0 secrets (`docs/stage2/functions/DEPLOYMENT-MAP.md` §1), and a build carries no `--dart-define` values, so `Supabase.initialize` never runs (`packages/haven_api/lib/src/haven_backend.dart:35-40`). |

The reason a read is sometimes open and a write never is: **the two walls**. `device_commands` and
friends have a SELECT policy *and* grant for a parent, so rows are readable in principle; every
INSERT/UPDATE/DELETE grant is absent for client roles and the 14 captured RPCs grant EXECUTE only to
`postgres`/`service_role` (`apps/haven_app/lib/features/device_commands/data/commands_repository.dart:9-19`
citing `docs/stage1/04-rls-matrix.md:43`, `:98-101`; and `docs/stage1/00-status-register.md:86` for the
`devices` F6 case). That is why repositories say things like "reads and states that refusal; it has no
send method, because no button on any screen could succeed at one".

## 1. Feature table

| Feature | Route(s) | Controller(s) | Repository | Verdict |
| --- | --- | --- | --- | --- |
| `authentication` | `/`, `/sign-in`, `/register`, `/session-ended` | `splash`, `sign_in`, `register` | `auth_repository.dart` | BUILT / TESTED OFFLINE; **NOT FUNCTIONAL E2E** (no deployed `auth-bootstrap`, no profile rows). The Firebase-identity path **refuses** (`packages/haven_api/lib/src/supabase_user_auth.dart:90-96`) |
| `onboarding` | `/onboarding` | `onboarding` | `onboarding_repository.dart:37`, `:60` | the **only** feature that invokes a slug today (`EdgeFunctionName.authBootstrap`); BUILT / TESTED OFFLINE, **NOT FUNCTIONAL E2E** — the call cannot reach a deployed function |
| `family` | `/family`, `/family/child` | `family`, `child_profile` | `family_repository.dart:147`, `:156`, `:163` | BUILT / REFUSES AT THE SEAM for add/remove parent (RPC lane unexecutable). Reads are typed and scoped by `family_scope.dart` |
| `dashboard` | `/dashboard`, `/unknown` | `dashboard` | `dashboard_repository.dart` | BUILT / TESTED OFFLINE; renders setup state when there is no family rather than an empty board |
| `device_pairing` | `/pairing`, `/pairing/code` | `pairing`, `pairing_code` | `pairing_repository.dart:103`, `:109`, `:118` | BUILT / REFUSES AT THE SEAM for invite, accept-code and withdraw — `pairing` slug undeployed and `PAIRING_HASH_PEPPER` not created |
| `child_devices` | `/devices`, `/devices/detail` | `devices`, `device_detail` | `devices_repository.dart:37`, `:46`, `:55` | BUILT / REFUSES AT THE SEAM (F6: `devices` has no SELECT grant for `authenticated`) |
| `device_activity` | `/devices/activity` | `activity` | `activity_repository.dart` | BUILT / TESTED OFFLINE; read-only lane, **NOT FUNCTIONAL E2E** |
| `device_commands` | `/devices/commands` | `commands` | `commands_repository.dart` | BUILT / REFUSES AT THE SEAM for every mutation, by design — no write grant exists and the header records why (`:9-19`) |
| `policies` | `/devices/policies` | `policies` | `policies_repository.dart` | BUILT / REFUSES AT THE SEAM. Also backend-blocked: `device-policy`'s key allowlist is `NOT DEPLOYABLE WITHOUT SPEC` |
| `location` | `/devices/location` | `location` | `location_repository.dart` | BUILT / TESTED OFFLINE; **no invented precision** — `packages/haven_models/test/round_trips_test.dart` pins that `LocationEvent` keeps accuracy exactly as reported |
| `safe_zones` | `/safe-zones`, `/safe-zones/editor` | `zones`, `zone_editor` | `zones_repository.dart`, `safe_zone_rules.dart` | BUILT / TESTED OFFLINE. `safe_zone_rules.dart` is **pure local logic** — the geometry does not depend on the backend, which is why this feature has 10 test files |
| `remote_sessions` | `/remote-sessions`, `/remote-session` | `sessions`, `session_detail` | `sessions_repository.dart`, `session_gaps.dart`, `services/media_peer.dart:45` | BUILT / REFUSES AT THE SEAM. Consent is a single boolean in the model and is tested as such; WebRTC media is unreachable (`TURN_HOST`/`TURN_SECRET` not created, A13/A12-R unsigned) |
| `telemetry` | (device detail) | `telemetry` | `telemetry_repository.dart` | BUILT / TESTED OFFLINE. `test/telemetry/telemetry_card_test.dart` asserts "no family says so instead of showing an empty log" and that the card states it is a **snapshot, not a live view** |
| `notifications` | `/notifications` | `notifications` | `alerts_repository.dart`, `services/alert_delivery.dart:47` | BUILT / REFUSES AT THE SEAM. Push is not functional: no registered Firebase app, no `google-services.json`, no token column, no send path (`docs/stage2/S2-A4-edge-functions-audit.md:174-175`) |
| `account` | `/account` | `account` | `account_repository.dart:92`, `:99`, `:106` | BUILT / REFUSES AT THE SEAM for change-password, change-email and delete-account — no captured contract for those operations |
| `settings` | `/settings`, `/settings/permissions`, `/settings/about` | `settings` | `settings_repository.dart:117` | BUILT / TESTED OFFLINE. The only feature that persists locally (`core/storage`); `/settings/about` renders the missing **define names** so a build states what it lacks (`about_page.dart:103`) |
| *(shell)* | all of the above | `app/app.dart`, `app/bindings`, `app/theme` | — | bindings construct every feature; `shared/components/state_view.dart:53` and `blocked_notice.dart:20-23` render the blocked state; `dashboard/views/pages/not_found_page.dart:38` states "Screen not implemented" rather than redirecting |

## 2. Cross-cutting rules that are enforced in code, not just prose

- **Never trust a client-sent Firebase UID.** `IDENTITY_MODE` is the only identity switch and a
  client UID is never authoritative (`backend/supabase/functions/_shared/identity.ts:37-40`).
- **Consent-visible monitoring.** Remote-session consent is a single boolean carried through the model
  and asserted in `round_trips_test.dart`.
- **No invented location precision.** Pinned by the `LocationEvent` round trip.
- **No claim that an Android restriction applied unless the OS confirms it.** The child-agent lane
  reports confirmation or says it has none; it has **0 tests** and has never run on a device
  ([../testing/README.md](../testing/README.md) §4).
- **No screen capture, microphone or camera outside the consent + permission model** — the media lane
  refuses before any getUserMedia path exists (`features/remote_sessions/services/media_peer.dart:45`).
- **No fabricated endpoints.** `EdgeFunctionName` enumerates exactly the nine captured slugs and its
  comment forbids `notification-cron`, `register-token`, `verify-firebase-token`
  (`packages/haven_api/lib/src/backend_endpoints.dart:150-165`). Cross-checked: all nine have a
  directory under `backend/supabase/functions/`, and no app call site names a slug that does not.

## 3. What would move a feature up a verdict

1. Owner signs **A7-R** + **A8-R** and deploys the slugs (browser only), after **A3** lands.
2. **A9** signed so the six secret names exist (names-only guide:
   `backend/supabase/config/environment.md`).
3. The `device-policy` / `device-command` **spec gaps** filled — the two
   `NOT DEPLOYABLE WITHOUT SPEC` scopes (`backend/supabase/functions/README.md` §1).
4. **A12-R** + **A13** signed for push and the identity bridge (`backend/firebase/SETUP.md` §2-§3).
5. Then an actual end-to-end run against staging, whose result must be recorded before any feature is
   called working. Until that exists, the honest status of the whole app is: **code complete to the
   seam, one feature able to name an endpoint, zero features verified end to end.**

Related: [../architecture/04-refusal-model.md](../architecture/04-refusal-model.md) ·
[../testing/README.md](../testing/README.md) ·
[../architecture/03-data-and-backend-contract.md](../architecture/03-data-and-backend-contract.md)
