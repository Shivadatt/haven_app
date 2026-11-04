# Firebase — staging setup guide (owner-executed, browser only)

TARGET: Firebase project `haven-staging`, project id `haven-staging-46822`, project number
`381273275501` — EVIDENCED: `docs/stage2/S2-A2-firebase-console-audit.md` (`:111`, `:113-117`,
`:270`).

**STAGING ONLY.** The production Supabase/Firebase side of this programme is never opened, never
queried, never configured and never written by anything in this repository. No production project
id, number or identifier appears in this file, and nothing here is addressed to it.

**STATUS: NOT CONFIGURED. NOTHING DESCRIBED IN THIS FILE HAS BEEN DONE.** This document was
authored with local file tools only — no browser, no console, no CLI, no REST, no device. It
creates nothing and authorises nothing.

**HOW EVERY STEP IS PERFORMED: by the owner, by hand, in the Firebase console in a browser.**
`gcloud`, `firebase`, `curl`, the REST API, DevTools and direct config-file writes are not
permitted in this project. Where a step below says "create", it means the owner creates it in the
console and then records only its **name** back into this repository.

**NO SECRET VALUE IS EVER WRITTEN HERE.** API keys, service-account JSONs, FCM server keys, VAPID
keys and certificate digests are referred to by NAME with the status `NOT CREATED`. A public
project id / app id / sender id is not a secret and is stated where the evidence in this repo
states it. See [CONFIGURATION.md](CONFIGURATION.md) for the names-only contract.

---

## 1. Observed state of `haven-staging` — the whole baseline

Every row is a **captured observation**, not an inference, and every one is as of the last
authorised console look. Nothing after that timestamp is knowable from this repository.

| Object | State in staging | Evidence |
| --- | --- | --- |
| Project shell | Exists: `haven-staging` / `haven-staging-46822` | `S2-A2-firebase-console-audit.md:111` |
| Environment type | Reads `Unspecified` — the project id and number are the only identity proof (finding H-8) | `S2-A2…:111`, `:113-117` |
| Registered apps | **ZERO.** No Android app, no iOS app, no Web app | `S2-A2…:216-217` |
| `google-services.json` | **None exists** — it is produced by registering an Android app | `S2-A2…:216-217`; asserted in code as absent at `packages/haven_api/lib/src/push_transport_impl.dart:21` |
| FCM configuration | **None** (no web-push certificate, no sender configuration captured) | `S2-A2…` §3.6 `:244` |
| Firebase credentials | **Zero created or copied.** "Zero Firebase credentials were created or copied" | `S2-A2…:244` |
| Auth providers | **None configured** — sign-in with a Firebase account is not available on this build | `apps/haven_app/…/supabase_user_auth.dart:93-96` (the call returns `blocked('A13 unsigned + firebase_identity_mapping not loaded + profile provisioning gap')`) |
| Analytics, Gemini | Left **off** at creation | `S2-A2…:185-186` |
| Pricing plan | `Spark` observed **2026-10-30**; **NOT RE-CONFIRMED** — `/settings/usage` and `/settings/plan` did not resolve to a readable plan page in the capture | `S2-A2…:179`, `:670` |
| Console navigation seen | Only Project Overview and Settings were enumerated | `S2-INSP-03:107-108`, quoted at `S2-A2…:270` |
| Last authorised observation | `2026-11-02T07:16Z`. Anything after is unknown, not unchanged | `S2-A2…:162` |
| Conflicting snapshots | Two captures disagree; `S2-INSP-03` is the current best | `S2-A2…:38-42` |

The project was also **created outside its own approval gate**; the 2026-11-02 ratification
(`OPTION (i)`) is retrospective and, per the instruments file, "grants nothing forward"
(`S2-A2…:177`; `docs/stage2/approval-package-v3-implementation-instruments.md:31-33`).

### What the code does with that emptiness today

The app **fails closed** rather than pretending. These are the current, verified behaviours:

- `apps/haven_app/lib/main.dart:8-13` reads five `--dart-define` values, three of them Firebase,
  and `:15-17` reports the missing **names** — the inline comment there is literal: "Names only;
  never print the values."
- `apps/haven_app/lib/app/bindings/initial_bindings.dart:43-45` calls
  `HavenBackend.install(endpoints:, secretVault:)` and **omits the `firebaseInit` parameter**.
- `packages/haven_api/lib/src/haven_backend.dart:41-43` initialises Firebase **only if**
  `endpoints.hasFirebase && firebaseInit != null`. With the callback null, no Firebase app is ever
  created, so `Firebase.apps` stays empty.
- `packages/haven_api/lib/src/push_transport_impl.dart:19-21, 28` guards on
  `Firebase.apps.isNotEmpty` and returns the explicit message "No Firebase app is registered in
  this build (A12-R unsigned; google-services.json absent)". Push is therefore **reported** as
  unavailable, never assumed to have worked (`:23-26` documents that a silent plugin is reported,
  and bounds the registration wait at 20 s).
- `packages/haven_api/lib/src/supabase_user_auth.dart:90-96` — the Firebase-identity sign-in path
  returns `blocked(...)`, matching the unsigned A13.

Consequence for this guide: **there is no working Firebase integration to "re-configure".** Every
step below creates the first one, and none of it is reversible by editing code alone.

---

## 2. Approval gates that must be signed BEFORE any step in §3

Nothing in §3 may be performed until the matching fence is signed. All of these are
`STATUS: UNSIGNED` as written
(`docs/stage2/approval-package-v3-implementation-instruments.md`):

| Instrument | Gates | Status | Evidence |
| --- | --- | --- | --- |
| **A12-R** | Android app registration, `google-services.json` handling, optional service-account key, optional FCM test send, SHA fingerprint entry | `UNSIGNED` | `:315` (fence), scope row `:879` |
| **A13** | The identity bridge — `firebase_identity_mapping` and the third-party-auth fence | `UNSIGNED` | `:201`; also "DECIDED — INSTRUMENT PREPARED, FENCE UNSIGNED" in `S2-EXEC-08` |
| **A9** | Edge secrets (names only until signed) | `UNSIGNED` | `:565` |
| **A7-R / A8-R** | Edge Function authoring + deploy | `UNSIGNED` | `:723` |
| **A12** (legacy) | superseded by A12-R | `BLOCKED — APPROVAL REQUIRED` | `S2-A2…:237` |

Global rule, quoted: "**No instrument in this file is signed by anyone at time of writing.** All
nine fences are blank; all nine carry `STATUS: UNSIGNED`" (`approval-package-v3…:912-916`). A
recorded decision is not a signature, and the 2026-11-02 ratification grants nothing forward.

---

## 3. The owner's steps, in order

Each step names what to do in the console, what to write back into this repo afterwards, and how
to verify. **No step is checked off here.** Perform them in this order; step boundaries are the
approval gates, not convenience.

### Phase 0 — confirm the project is the one you think it is
1. In the console, open `haven-staging` and read the project id **and** the project number.
2. Verify against §1: `haven-staging-46822` / `381273275501`.
   The `Environment type` field reads `Unspecified` in this project, which is finding H-8 — the id
   and number are the only identity proof you have. Do not rely on a name or a tag.
3. Record the observation timestamp and, if the plan page now renders, the plan tier
   (`Spark` is UNRE-CONFIRMED, §1).
   If it still does not render, write "plan tier not readable" — do not assume Spark.

### Phase 1 — Android app registration (requires A12-R signed)
1. Register an Android app with the package name `com.haven.familysafety`.
   EVIDENCED as verified from the released APKs on 2026-10-30: `docs/stage1/05-change-plan.md:70`
   (note the same row records that `Haven-1.0.apk` shares the package name but uses a **different
   signing key** — a fingerprint decision, not a naming one).
2. Download the resulting `google-services.json`. **Do not commit it and do not paste its contents
   into this repository, a report, a chat message or a screenshot.** Its *name* and the app id may
   be recorded. `OPEN QUESTION FOR OWNER: where this file is kept` — the repo has no evidenced
   location for it, and the code comment at `push_transport_impl.dart:21` treats it as absent.
3. Debug SHA-1 / release SHA fingerprint entry: A12-R line 313 shows the checkbox "FCM-only (no
   fingerprints configured) authorised today: [ ] YES [ ] NO" **unticked**.
   `OPEN QUESTION FOR OWNER`: answer that checkbox before registering, because it decides whether
   step 4 is a configuration or a blocker.
4. Verify: the project's app list shows exactly one Android app and the package string matches
   byte-for-byte.

### Phase 2 — Cloud Messaging (requires A12-R signed)
1. Confirm FCM is enabled for that Android app (it is on by default for an Android app registration
   — INFERRED, not captured: no evidence file in this repo records the FCM screen of `haven-staging`).
2. Record by name only, with status `NOT CREATED` for anything secret-shaped:
   - the **Web Push certificate / VAPID key pair** — name only. This is the key an optional
     web-push send path would need; there is no evidence that one exists in this project.
   - an **optional service-account key** — A12-R permits it (`:879`); it must never reach a mobile
     binary. If created, it lives outside this repository.
3. Optional FCM test send (A12-R allows it, `:879`): a test send requires a real device token,
   which requires the app to run. See Phase 5 — **push cannot be verified before the schema and the
   token path exist.**

### Phase 3 — Auth, if and only if the bridge is being built (requires A13 signed)
1. The decision of record is a **Third-Party Auth bridge**: Supabase Auth remains the session
   authority and a Firebase-issued identity is mapped onto it. The enforcement lives in
   `backend/supabase/functions/_shared/identity.ts` behind an `IDENTITY_MODE` fence, and the
   mapping table is `A3d` — `docs/stage2/migrations/A3d-firebase-identity-mapping.sql`, whose own
   header says `PREPARED — NOT EXECUTED`.
2. **Never accept a client-sent Firebase UID as proof of identity.** That is a brief-level rule,
   and `supabase_user_auth.dart:93-96` already refuses the path while A13 is unsigned.
3. `OPEN QUESTION FOR OWNER`: which provider(s), if any, are to be enabled in Firebase Auth. No
   evidence file in this repository names one, so no provider is prescribed here.
4. Verify: enable nothing until `A3d` is landed — a provider configured before the mapping exists
   creates identities that cannot be resolved.

### Phase 4 — schema, functions, then secrets (this order, not any other)
1. `A3` (`docs/stage2/migrations/A3-staging-load-v1.sql`) is landed by the owner in the **Supabase**
   browser SQL Editor. It is `PREPARED — NOT EXECUTED`.
2. `A3c-notification-backend.sql` (`PREPARED — NOT EXECUTED`) is what gives push a home at all.
   Today it has none — EVIDENCED: `firebase/SETUP-CHECKLIST.md` §5 "There is no `push_tokens` table
   and no token column on `devices` today"; `docs/stage1/03-data-model.md:43`, `:172`;
   `docs/stage1/evidence/schema-columns.md:294`.
3. The token-receiving endpoint **does not exist and must not be invented**. EVIDENCED as
   `MISSING — SOURCE EVIDENCE ABSENT` in `docs/stage2/S2-A4-edge-functions-audit.md`:
   `register-token` `:175`, `send-push` `:174`, `verify-firebase-token` `:177`, and
   `notification-cron` is `NOT APPLICABLE` because the captured `cron` does no notification work
   (`:171`). Deploying the nine authored functions is separately gated on A7-R/A8-R.
4. Secrets last (`A9`), because A9's names are scoped to roles A3 creates. Names only — see
   [`../supabase/config/environment.md`](../supabase/config/environment.md).

### Phase 5 — only now is push testable
A verification is only honest if the whole chain ran: app build carrying `google-services.json` →
native registration callback → token stored by a real endpoint → server-side send. Today the first
link is missing (`initial_bindings.dart:43` passes no `firebaseInit`) and the third does not exist.
Record per attempt: build, device, timestamp, and the exact failure. A test send that "appears to
work" is not evidence of delivery unless the notification reached the device.

---

## 4. Resume conditions

This task resumes when the owner supplies, in this order:

1. **A12-R signed** (with the `[ ] YES / [ ] NO` fingerprint question on `:313` answered) → Phase 1
   becomes performable.
2. The **location of `google-services.json`** and confirmation it is not committed → Phase 1 step 2.
3. **A13 signed** → Phase 3 becomes performable; before it, sign-in via Firebase stays `blocked`.
4. **A3 landed** in the Supabase browser editor → Phase 4 step 1; until then every function read
   fails at first contact.
5. **A3c landed** (or a written owner decision to defer push) → push acquires a token home.
6. A **documented contract** for a token-registration endpoint → the only sanctioned way to add
   `register-token`-equivalent behaviour; a new function needs a contract and an approval, per the
   brief. Inventing it is prohibited.
7. **A9 signed**, names only → Phase 4 step 4.
8. A current console observation, since the last authorised look is `2026-11-02T07:16Z`
   (`S2-A2…:162`).

Until then the correct status of the Firebase lane is exactly what the code already says:
**not configured, push not functional, identity bridge refused.**

---

## 5. What this document does NOT claim

- It does not claim anything in `haven-staging` is configured, enabled or verified — §1's table is
  the state at the last authorised observation, and every later row is a **proposal**.
- It does not claim push works, or that a notification was ever delivered to a device.
- It does not claim parity with any deployed function: all nine slugs in
  `backend/supabase/functions/` are labelled `RE-AUTHORED FROM SPECIFICATION — NO PARITY
  VERIFICATION`.
- It does not execute a single row of `docs/stage1/15-edge-function-test-plan.md`; those HTTP-level
  cases stay `NOT EXECUTED`, and the offline tests in `backend/supabase/tests/` reproduce only
  *decisions*, never those cases.
- It does not create, request, read or transcribe any credential.
- It does not authorise a deploy, a migration, a secret, or a console click. Only a signed
  instrument does that, and none is signed.
- It does not describe console menu paths it cannot evidence. Where the repo is silent, this file
  says `OPEN QUESTION FOR OWNER` rather than naming a screen — a wrong click in a real project is
  worse than an unfilled line here.

Related: [CONFIGURATION.md](CONFIGURATION.md) ·
[`../supabase/config/environment.md`](../supabase/config/environment.md) ·
[`../supabase/functions/README.md`](../supabase/functions/README.md)
