# S2-A6 — Native Android Child App report

| Field | Value |
| --- | --- |
| Assigned role | Subagent 6 — native Kotlin child application specialist (device registration, FCM token registration, device↔user identity mapping, secure Edge Function calls, pairing, parent authorization, background service lifecycle, permissions, session management, reconnection, Android 12+ and newer compatibility, battery/background restrictions) |
| Date | 2026-11-03 |
| Class | Offline repository-only assessment. No build, no install, no emulator run, no device test |
| **Status** | **`BLOCKED — APPROVAL REQUIRED`** for the integration items, and **`NOT STARTED`** for anything requiring source |
| Authored by | Main agent, after direct verification of the APK evidence |

---

## 1. Premise correction: the child app exists — but it is **not** native Kotlin

The architecture brief says "Native Android/Kotlin for the Child Application". The repository's own verified evidence says
otherwise, and also says the opposite of Subagent 5's premise:

| Fact | Value | Evidence |
| --- | --- | --- |
| Child APKs **exist** | `Haven-1.0.apk`, `Haven-1.1-release.apk`, `Haven-1.2-release.apk` | `docs/stage1/evidence/g2-apk-identity-20261030.md:12` (paths on the operator workstation outside the repository) |
| **Source does not exist** | no `*.kt`, `*.java`, `build.gradle(.kts)`, `AndroidManifest.xml` in the repo (0 matches, re-verified this pass over 95 files) | §"probes" below; corroborated at `g2-apk-identity-20261030.md:51-53` |
| Framework actually shipped | **Capacitor** (a WebView shell): `assets/capacitor.config.json` read out of the APKs (`:13`), with `appId`/`appName` at `:26`, `webDir` at `:27`, `server` at `:28` | `docs/stage1/evidence/g2-apk-identity-20261030.md:26-28` |
| Package / application id | `com.haven.familysafety`, stable across all three artefacts | `g2-apk-identity-20261030.md:21`; `docs/stage1/01-baseline-inventory.md:152-156` ("**Child application id (verified 2026-10-30)**") |
| versionCode / versionName | 1/1.0, 2/1.1, 3/1.2 | `:22` |
| minSdk / targetSdk / compileSdk | **24 / 36 / 36** | `:23-24` |
| Which doc calls it "Android/Kotlin" | only `docs/stage1/02-architecture.md:26,36` — a **design intent**, and the same doc at `:181` says "Parent app, child app **DO NOT EXIST**" | the tension is a **terminology conflict**: binaries exist, source does not |

**Probes re-run this pass:** `find` over the repository for `pubspec.yaml` / `*.dart` / `*.kt` / `*.java` /
`build.gradle*` / `AndroidManifest.xml` / `google-services.json` → **0 matches each**. The whole repo is 95 files
(75 markdown, 13 JSON, 3 SQL, 1 TOML, 1 `.env.example`, 2 `.gitignore`).

**Why this matters more than a naming quibble.** A Capacitor/WebView client and a native Kotlin client need different
work for every item on the brief's list: FCM, foreground services, exact alarms, boot receivers and permission flows all
require a **native plugin or native module** — they are not available to web content in a WebView, and background
execution is owned by the shell, not the page. So a plan written for "native Kotlin" would be the wrong plan, and a plan
written for "the Capacitor app we already ship" cannot be executed because its **source tree is not in this repository**.

## 2. Two live hazards found in the APK evidence, which no prior phase recorded as findings

1. **Two different signing certificates across three releases.** 1.1 and 1.2 share one signer; **1.0 is signed by a
   different certificate** (`g2-apk-identity-20261030.md:29-31`). Firebase Android registration keys on package **+
   certificate fingerprint**, and a wrong fingerprint means push silently never arrives. The 1.1/1.2 certificate DN
   self-describes as **`O=Haven Demo`** — i.e. the release the child app is built from is signed with a **demo** identity.
   If Play App Signing is used, the console fingerprint differs from both (recorded at `:49-50`).
   → **The A12 package cannot be signed until "which APK is the shipping artifact, signed by which key" is an owner
   decision.** This is a permanent-ish registration step (`firebase/SETUP-CHECKLIST.md:15`, decision D3).
2. **1.0 is a different distribution, not an earlier version of the same one.** It loads a **remote site** over
   `webDir: dist` + a hosted `server.url`, while 1.1/1.2 bundle local assets with `androidScheme: https`
   (`g2-apk-identity-20261030.md:28-29, 40-42`). A remote-asset WebView shell takes its UI and logic from whatever the
   server returns — a materially different trust and update model from a bundled app, and the kind of difference that must
   be settled before any authentication or push integration is designed against "the child app".
3. **Not an authenticity claim.** The evidence itself states that digests prove the files were not altered between capture
   and record, **not** who built them and not that Play will serve them (`:46-48`). Consistent with the project's standing
   rule that a hash and a TLS download are not authenticity. This report inherits that limit and does not upgrade it.

## 3. Per-requirement status (the brief's Subagent 6 list)

| Required work | Status | Blocking evidence |
| --- | --- | --- |
| Child device registration | `BLOCKED — APPROVAL REQUIRED` | The real contract exists in evidence — `device-register` (child JWT + verified email + `assertChildMembership(body family_id)`) and `device-command` poll/ack (`x-device-id` + `x-device-secret`) per `docs/stage1/evidence/edge-functions/capture-20261030.json` `functions[].auth_model` — but **0 of 9 functions are deployed to staging** and `assertChildMembership` is a `private.*` function the artefact emits **0 of** |
| Firebase Auth in the child app | `BLOCKED — APPROVAL REQUIRED` | A12 unsigned; and Firebase Auth is prohibited by `01:201`, `SETUP-CHECKLIST.md:16` (D4) and the standing instruction — see [S2-A5](S2-A5-parent-app-report.md) §4 |
| Device↔user identity mapping | `PLANNED` (design only) | `devices.child_user_id` exists in the captured schema (183 columns, `g1-q8`); the *external* identity root is unresolved; the device credential columns (`secret_hash`, `credential_issued_at`, `credential_revoked_at`) are evidenced |
| FCM token registration | `BLOCKED — APPROVAL REQUIRED` | **no FCM configuration** (A12) **and no token storage** — re-verified: among all 183 captured columns the only `token`-bearing ones are `pairing_requests.token_id (uuid)` and the `device_pairing_tokens` table (pairing, not push); `SETUP-CHECKLIST.md:99` says the same |
| Secure Supabase Edge Function communication | `BLOCKED — APPROVAL REQUIRED` | staging Edge Functions `NOT CREATED`; the design constraint from `02-architecture.md:26` is that the client holds **anon key + Firebase client config only — never service-role, never Admin SDK**, which is honoured in intent and unverifiable in code |
| Child device pairing | `PLANNED` | `device_pairing_tokens` columns (`code_hash`, `expires_at`, `redeemed_at`, `attempts`, `max_attempts`, `purpose`) and `pairing_requests` exist in the artefact; the `pairing` function exists in production evidence (readable TypeScript, 972 lines) but is undeployed in staging |
| Parent authorization of a device | `BLOCKED — APPROVAL REQUIRED` | enforced by `private.is_family_parent` (called by 13 of 21 captured policies) — **body captured, return type not**; and RLS is **inert for the live path today** because all 9 Edge Functions use the service-role key (`docs/stage1/14-edge-function-security-audit.md:243-245`) |
| Background service lifecycle | `NOT STARTED` | requires the app's native source; a Capacitor build needs a plugin/native module — `MISSING — SOURCE EVIDENCE ABSENT`, not assertable |
| Permission handling | `NOT STARTED` | the schema *anticipates* it: `devices` carries `usage_access_granted`, `location_granted`, `background_location_granted`, `camera_granted`, `microphone_granted`, `notifications_granted` — six granted-permission columns, i.e. six runtime-permission flows to build and to justify |
| Device session management | `BLOCKED — APPROVAL REQUIRED` | `remote_sessions` + `remote_session_transition_guard`; the guard's **body is captured**, its **return type is not**; patch **P03** (one-live-session invariant) is unapplied and blocked (D-10b, no post-check/rollback) |
| Network change / reconnection | `NOT STARTED` | no source; also `02-architecture.md` §4 records push as best-effort with reconciliation on app resume — unbuilt |
| Android 12 compatibility **and newer** | see §4 — the brief's framing is out of date | targetSdk is **36**, not 31 |
| Battery optimisation / background execution | see §4 | |
| **Test evidence** | **NONE** | no source, no build, no emulator session, no device. Any test result in this file would be fabricated |

## 4. Android compatibility report — corrected to the SDK level actually shipped

The brief asks about "Android 12 compatibility, newer Android version compatibility, battery optimization and background
execution restrictions". The verified APKs target **SDK 36 with minSdk 24** (`g2-apk-identity-20261030.md:26`), so the
governing constraint is **Android 14/15/16 behaviour against devices as old as Android 7.0** — a much wider surface than
Android 12. Recorded as `INFERRED — platform requirements, to be verified against the app source and manifest when they
exist` (the manifest is **not** in this repository, so nothing here can be confirmed as already handled):

| Platform area | Applies from | Relevance to this product | Status |
| --- | --- | --- | --- |
| `POST_NOTIFICATIONS` runtime permission | Android 13 (33) | an FCM notification is not *displayed* without it, independent of token registration | `NOT STARTED`; `devices.notifications_granted` suggests the intent existed |
| Foreground-service **types** + matching permission + property | Android 14 (34) | location/telemetry reporting from a child device is exactly the case this governs | `NOT STARTED` |
| Background-location access requires an **in-app, user-visible justification flow** and is granted to "while using" by default | Android 10 → hardened 11+ (30/31) | `background_location_granted` is a captured column; safe-zone reporting depends on it | `NOT STARTED` |
| Exact alarms need `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` | Android 12 (31) | any scheduled policy/reminder behaviour | `NOT STARTED` |
| Package-visibility (`<queries>`) for usage statistics | Android 11 (30) | `usage_daily` table + `apps_upload` action in `device-telemetry` imply `PACKAGE_USAGE_STATS` | `NOT STARTED` |
| Battery optimisation / Doze, app-standby buckets, manufacturer killers | ongoing | a monitoring app that is killed silently loses telemetry; the honest design answer is a **visible** foreground-service notification, not a bypass | `PLANNED — design only` |
| Cleartext / mixed content | ongoing | 1.0 uses a remote `server.url` with `cleartext: false`; 1.1/1.2 use `androidScheme: https` | evidenced, §2.2 |
| minSdk 24 devices | Android 7.0+ | the newest permission models must be back-ported or degraded gracefully on 12 versions of Android | `UNKNOWN` — needs source |

**Standing boundary, restated because this is where a parental-control app is most easily led wrong:** legitimate
platform restrictions are to be **preserved and surfaced**, not evaded. No stealth monitoring, no hidden permission
bypass, no device-admin or accessibility-service misuse, no silent notification-channel tricks, and nothing that hides
the app's presence from the child device's own user-visible state. The brief's own §6 imposes the same limit. Anything in
this table that looks like a "bypass" is deliberately recorded as a permission flow that must be granted and shown.

## 5. Device registration flow — as the evidence describes it (planned, undeployed)

```
child device              Edge layer (Supabase, service-role DB access)      schema (unloaded)
------------              --------------------------------------------      ---------------
install app        →      device-register: child JWT + verified email  →    devices row
                            + assertChildMembership(body.family_id)          (child_user_id,
                                                                              installation_id)
pair with parent   →      pairing: create / invite / pending_child /        device_pairing_tokens
                            redeem / respond / cancel / list_family /        (code_hash, attempts,
                            unlink                                           max_attempts, purpose)
                             ▲ these are the actions evidenced in the
                             │ production capture; `pairing` is one of only
                             │ two functions whose SOURCE is readable
credential issued  →      x-device-id + x-device-secret                  →  devices.secret_hash,
                            (device-telemetry, device-command poll/ack)       credential_issued_at
revoke / recover   →      family-admin: revoke_device / recover_device     →  credential_revoked_at
heartbeat/usage/loc→      device-telemetry: heartbeat, usage_upload,       →  usage_daily, location_events,
                            apps_upload                                      device_apps
```

Two properties of this flow that the owner should notice:

- **Two identity channels already coexist** — a *user* JWT channel and a *device* header channel. Adding Firebase UID as a
  third, without deciding which one authorises what, is how an ownership bug becomes permanent
  ([S2-A1-auth-architecture.md](S2-A1-auth-architecture.md)).
- **`device-telemetry` authenticates the device only** (`auth_model`: "device only (x-device-id + x-device-secret);
  `device_id` and `family_id` always taken from the authenticated device row"). That is good design — the client cannot
  assert its own family — but it is **production** evidence, frozen and prohibited to re-observe, and **nothing of it
  exists in staging**.

## 6. What this subagent could not determine, and why

- Whether the shipped Capacitor app contains **any** Firebase or push code: the APK asset dumps captured only
  `capacitor.config.json`; no plugin list, no manifest, no JS bundle contents were captured.
  `MISSING — SOURCE EVIDENCE ABSENT`.
- The source-level `applicationId` — never compared, because the source is not in the repository
  (`g2-apk-identity-20261030.md:51-53`).
- Whether Play App Signing will change the fingerprint the A12 package needs.
- Every permission, service and battery behaviour in §4 as *already handled* — that requires source.
- Which of 1.0 / 1.1 / 1.2 is the shipping artefact, and under which parent/child role it operates.

## 7. Shortest path to a real Subagent 6

1. **Owner: locate or create the child app source** and bring it under this programme (it is not in `D:\control`; the
   binaries are in a Downloads folder). Until then, no item in §3 can move off `NOT STARTED`.
2. **Owner decision: which signing identity ships** (§2.1) — this must precede Firebase app registration, not follow it.
3. **Owner ruling on the identity model** ([S2-A5](S2-A5-parent-app-report.md) §4) — Supabase Auth vs Firebase Auth changes
   what the device sends in every request.
4. **Schema: add push-token storage + deploy the Edge layer** (A3 / A2′ / A7-A8 class approvals), then, and only then,
   FCM: **A12**.
5. Re-run this audit against real source with an emulator session, and report actual build/test output.

**Author's note:** the brief expected a Kotlin integration plan and test evidence. The honest deliverable is the correction
above plus a plan that cannot yet be executed. No build output, emulator session, test result or "PASS" is claimed here,
because none exists.
