# Firebase — configuration contract (names only)

Companion to [SETUP.md](SETUP.md), which is the owner's browser-only step guide. This file is the
**names-only contract**: what configuration exists, where a name is actually read, how it is
injected, what happens if it is absent, and whether it exists today.

TARGET: Firebase `haven-staging` / `haven-staging-46822` (number `381273275501`) —
`docs/stage2/S2-A2-firebase-console-audit.md:111`, `:113-117`. **STAGING ONLY**; the production side
of this programme is never opened, queried, configured or written, and no production identifier
appears in this file.

**No value of any kind is recorded here.** A name with the status `NOT CREATED` is not a
to-do list item for an agent — creating it requires the owner's signature on the instrument named
in [SETUP.md §2](SETUP.md), and every one of those is `STATUS: UNSIGNED`
(`docs/stage2/approval-package-v3-implementation-instruments.md:912-916`).

---

## 1. Names the code actually reads

These are read at **build time** through `String.fromEnvironment`, i.e. `--dart-define`. There is
no `.env` loader, no runtime fetch and no console read anywhere in this repository — that is the
whole injection mechanism, and it is deliberate: a mobile binary carries public config only.

| Name | Kind | Read at | Injected by | If absent | Status |
| --- | --- | --- | --- | --- | --- |
| `HAVEN_SUPABASE_URL` | public endpoint | `apps/haven_app/lib/main.dart:9` | `--dart-define` | `hasSupabase` false (`packages/haven_api/lib/src/backend_endpoints.dart:31`) → `Supabase.initialize` never runs (`haven_backend.dart:35-40`) → the app reports a `BackendStatus` of not-configured | `NOT PROVIDED IN THIS REPO` |
| `HAVEN_SUPABASE_ANON_KEY` | publishable client key | `main.dart:10` | `--dart-define` | same as above | `NOT PROVIDED` |
| `HAVEN_FIREBASE_PROJECT_ID` | public identifier | `main.dart:11` → `backend_endpoints.dart:27` | `--dart-define` | `hasFirebase` false (`:32-35`) → no `firebaseInit` → `Firebase.apps` stays empty | `NOT CREATED` (zero apps registered — `S2-A2…:216-217`) |
| `HAVEN_FIREBASE_APP_ID` | public identifier | `main.dart:12` → `:28` | `--dart-define` | as above | `NOT CREATED` |
| `HAVEN_FIREBASE_API_KEY` | client-embedded key (see §3) | `main.dart:13` → `:29` | `--dart-define` | as above | `NOT CREATED` |

All five are passed into `HavenConfig.fromDefines` (`apps/haven_app/lib/core/constants/haven_config.dart:15-29`).
The three Firebase fields are `required` and default to `''` in the empty instance
(`backend_endpoints.dart:10-12`, `:20-22`), and `hasFirebase` is the **conjunction** of all three
being non-empty — one missing name disables the whole Firebase path rather than half-enabling it.

The absence is **surfaced, never hidden**: `missingDefines()` returns the missing *names* only
(`haven_config.dart:41-48`, whose own comment says "Values are never included"), `main.dart:15-17`
debug-prints that list, and the About page renders it to the user
(`apps/haven_app/lib/features/settings/views/pages/about_page.dart:103`).

### What consumes it, and what therefore cannot work yet

| Consumer | Behaviour today | Evidence |
| --- | --- | --- |
| `HavenBackend.install` | Called **without** the `firebaseInit` argument, so the guard `endpoints.hasFirebase && firebaseInit != null` can never fire | `apps/haven_app/lib/app/bindings/initial_bindings.dart:43-45`; `packages/haven_api/lib/src/haven_backend.dart:33`, `:41-43` |
| `FirebasePushTransport` | Guards on `Firebase.apps.isNotEmpty` and returns the stated failure `"No Firebase app is registered in this build (A12-R unsigned; google-services.json absent)."` | `packages/haven_api/lib/src/push_transport_impl.dart:19-21`, `:28` |
| Push registration | Subscribes before waiting and bounds the wait at 20 s, so a silent plugin is **reported**, not assumed to have worked | `push_transport_impl.dart:23-26` |
| Firebase-identity sign-in | Returns `blocked('A13 unsigned + firebase_identity_mapping not loaded + profile provisioning gap')` | `packages/haven_api/lib/src/supabase_user_auth.dart:90-96` |
| Android child agent | **Zero Firebase references in `android_native/`** — verified by case-insensitive search of that tree | searched 2026-11-04 |

The honest verdict: **push is not functional and no Firebase app is registered in any build of this
repository.** That is the correct state while A12-R and A13 are unsigned, and nothing here should be
"fixed" into appearing to work.

### Flutter plugins vs Gradle configuration — a real gap

`firebase_core ^5.1.0`, `firebase_auth ^7.0.1` and `firebase_messaging ^17.0.1` are declared
(`apps/haven_app/pubspec.yaml:45-47`, `packages/haven_api/pubspec.yaml:13-15`), and the
**build-generated** registrant does attach the messaging plugin
(`apps/haven_app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:39` —
a generated file, not hand-written config). But a search of `apps/haven_app/android/` build scripts
finds **no `google-services` Gradle plugin applied**, consistent with `google-services.json` not
existing. Consequence: a build carrying the three defines would still have no native Firebase
options resource. `OPEN QUESTION FOR OWNER`: whether the intended path is the `google-services`
plugin (which requires committing nothing but placing that file in the project) or an explicit
`Firebase.initializeApp(options: FirebaseOptions(...))` built from the three defines. No evidence
file in this repository decides this, so neither is prescribed.

---

## 2. Names that are NOT read by any code, and are not real config today

Distinguished deliberately from §1. Each is a name that a Firebase push setup would conventionally
need, with the evidence of its standing here.

| Name | Standing | Evidence |
| --- | --- | --- |
| `google-services.json` | **Does not exist**; referenced only as absent in a code comment, and its storage location is undecided | `push_transport_impl.dart:21`; `S2-A2…:216-217` |
| Web-Push certificate / VAPID key pair | `NOT CREATED`. A12-R permits an optional FCM test send; nothing in this repo records a VAPID key being read by any code | `approval-package-v3…:879` (A12-R scope) |
| Service-account key | `NOT CREATED`, optional under A12-R, and **may never reach a mobile binary or this repository** | `approval-package-v3…:879` |
| SHA-1 / SHA-256 app fingerprints | Decision **unticked** on the instrument: "FCM-only (no fingerprints configured) authorised today: [ ] YES [ ] NO" | `approval-package-v3…:313` |
| `register-token` / `send-push` / `verify-firebase-token` / `notification-cron` | **These are not functions and must not be referenced as if they were.** Verdicts: `MISSING — SOURCE EVIDENCE ABSENT` for `register-token` (`:175`), `send-push` (`:174`), `verify-firebase-token` (`:177`); `notification-cron` is `NOT APPLICABLE` because the captured `cron` does no notification work (`:171`) | `docs/stage2/S2-A4-edge-functions-audit.md` |
| `push_tokens` table / a token column on `devices` | **Neither exists.** "There is no `push_tokens` table and no token column on `devices` today." | `firebase/SETUP-CHECKLIST.md` §5 (quoted at `S2-A2…:505-506`); `docs/stage1/03-data-model.md:43`, `:172`; `docs/stage1/evidence/schema-columns.md:294` |

The nine Edge Function slugs that **may** be called are enumerated once, in code, from the capture:
`packages/haven_api/lib/src/backend_endpoints.dart:150-165`, whose comment states "Nine exist and
only these nine may be called" and names the three forbidden ones explicitly. All nine have a
matching directory under `backend/supabase/functions/` — checked, no fabricated endpoint exists.
`INFERRED —` and worth stating: only `auth-bootstrap` is invoked from application code today
(`apps/haven_app/lib/features/onboarding/data/onboarding_repository.dart:37`, `:60`); `pairing`
appears only in an asserted-error test (`packages/haven_api/test/credential_seams_test.dart:91`). The rest
are device-, cron- and parent-console-facing and are unreachable while staging runs 0 Edge Functions.

---

## 3. Secret classification

- `HAVEN_FIREBASE_PROJECT_ID`, `HAVEN_FIREBASE_APP_ID`: public identifiers.
- `HAVEN_SUPABASE_ANON_KEY`: publishable by design (Supabase's own anon/publishable key), and
  **not** the service-role key.
- `HAVEN_FIREBASE_API_KEY`: `INFERRED —` a Firebase *Android* key, which is shipped inside client
  apps by design and is quota-scoped rather than secret-grade. This repository nonetheless treats
  it as never-committed (it is read only from a build define), and the classification is the
  owner's to confirm. `OPEN QUESTION FOR OWNER`: treat as public-with-hygiene, or as a secret for
  this programme?
- Service-account key, FCM server key, VAPID private key: **server secrets. Not created, not
  wanted, and never in a mobile binary.** `SUPABASE_SERVICE_ROLE_KEY` is separately documented at
  [`../supabase/config/environment.md`](../supabase/config/environment.md) — a service-role key in
  the Flutter app or the child APK breaks the entire RLS model.

---

## 4. Hard rules

1. No secret value in this repository, in a commit, in a log line, in a report, in a screenshot, or
   in a chat message. Names with statuses only.
2. Nothing secret-shaped is ever compiled into the mobile app or the child agent APK. The app is
   built with public/client identifiers only (§3).
3. `google-services.json` and any service-account JSON are **not committed** — and the repo already
   enforces half of that: `.gitignore:14` lists `google-services.json` (a pattern with no instance,
   per `docs/stage2/S2-A2-firebase-console-audit.md:217`). Their storage location is an open
   question for the owner (§1, last paragraph), not a decision for an agent.
4. **Do not "improve" a fail-closed branch into a default.** `hasFirebase`'s conjunction
   (`backend_endpoints.dart:32-35`), `push_transport_impl.dart`'s `_noFirebaseApp`, and
   `supabase_user_auth.dart:93-96`'s `blocked(...)` are deliberate refusals, each naming the
   instrument that is missing. Same discipline as the backend lane's E6 pepper fallback and cron's
   short-secret rejection.
5. Do not add a `register-token`/`send-push`/`verify-firebase-token`/`notification-cron` call site.
   A new Edge Function needs a documented contract **and** an approval; inventing one is prohibited.
6. Absent configuration must remain **visible**: `missingDefines()` (`haven_config.dart:41-48`) and
   the About page (`about_page.dart:103`) exist so a build states what it lacks. Do not replace them
   with a silent default.
7. Staging only, browser only, owner-executed. No CLI (`gcloud`, `firebase`, `supabase`), no REST,
   no curl, no direct database access.

---

## 5. Related

- [SETUP.md](SETUP.md) — the owner's browser-only steps, gates, and resume conditions
- [`../supabase/config/environment.md`](../supabase/config/environment.md) — the Supabase-side
  names-only secret table (six names, seven read sites, all `NOT CREATED`)
- [`../supabase/functions/README.md`](../supabase/functions/README.md) — the re-authored lane,
  `NOTHING DEPLOYED`
- [`../supabase/migrations/README.md`](../supabase/migrations/README.md) — why the schema files are
  not in this repository's backend tree
- `docs/stage2/S2-A2-firebase-console-audit.md` — the only authorised console observation
