# Firebase / FCM setup checklist — gate G2

Status: **NOT STARTED — requires an owner decision.** No Firebase project exists for this product. Nothing here has been executed.
The Android `applicationId` is **VERIFIED** from the shipped binaries (§0a); everything else remains a proposal. Raw
capture: [docs/stage1/evidence/g2-apk-identity-20261030.md](../docs/stage1/evidence/g2-apk-identity-20261030.md).

Do **not** use `flutter-flow-w-ith-f-ir-6592ib` ("FlutterFlowWIthFIreBase", package `com.mycompany.flutterflowwithfirebase`). It is an unrelated FlutterFlow demo on a different app id, and reusing it would mix this product's push identity with a demo forever.

## 0. Decisions needed before any console action

| # | Decision | Recommended | Why it is needed |
| --- | --- | --- | --- |
| D1 | New dedicated project vs reuse the demo | **New project** | Clean FCM boundary; the demo's package id cannot match the real app |
| D2 | Project id | `parent-control-prod` | Matches the Supabase project naming already in use |
| D3 | Confirm the Android `applicationId` | **`com.haven.familysafety` — VERIFIED** (§0a) | An app registration is permanent-ish and hard to undo cleanly |
| D4 | Firebase Auth | **Leave disabled** | Supabase Auth is the single identity authority (architecture rule) |
| D5 | Analytics | **Off** | Not needed for FCM; avoids extra data collection in a children's product |
| D6 | Environments | one project now, second later if G6 creates staging | Environment separation is documented as missing, not invented |

## 0a. Verified Android identity — 2026-10-30

Read from the build artefacts with the local Android SDK build-tools; no Firebase or Play Console action.

| Field | Value | Source |
| --- | --- | --- |
| Package name | `com.haven.familysafety` | `aapt2 dump badging` on all three APKs (1.0, 1.1-release, 1.2-release) |
| Version | versionCode **3**, versionName **1.2** | `aapt2 dump badging` on `Haven-1.2-release.apk` |
| SDK range | minSdk **24**, targetSdk **36**, compileSdk **36** | same |
| Capacitor `appId` | `com.haven.familysafety` (`appName` `Haven`, `androidScheme` `https`) | `assets/capacitor.config.json` inside `Haven-1.2-release.apk` |
| Signing certificate | `CN=Haven, O=Haven Demo, C=US`; SHA-256 `ff1ad18fcc8c77fd48c126fb369e73a7a743538f6f9a542f32f726a1a9fdd67a`; SHA-1 `b836708aea5cfc376f884c508aee83070e237e7a` | `apksigner verify --print-certs` on 1.1/1.2 |
| APK SHA-256 | `fbd0a09a1c67ddc841459c7d7a8e5da5cc34148ed5f8d6e40c2220fa30610c58` | `sha256sum` |
| Artefact path | `%USERPROFILE%\Downloads\Haven-1.2-release.apk` | local |

**1.0 is not the same build.** It declares the same package name but a different signing certificate
(`CN=Haven, OU=Haven, O=Haven, L=Ahmedabad, ST=Gujarat, C=IN`, SHA-256 `eaffe1600ccc526f76a2c3c2dd336a47d42001e903985b99ff59cacc5dd078e2`)
and a different Capacitor configuration (`webDir: dist` with a remote `server.url`, rather than the bundled
`dist-android` used by 1.1/1.2). Version 1.1 and 1.2 share the certificate and config above and differ only in version
code. Full table: [g2-apk-identity](../docs/stage1/evidence/g2-apk-identity-20261030.md).

Two caveats that matter for D3 and later Play enrolment:

1. **The signing key is a demo key.** `O=Haven Demo` is not a production keystore, and the keystore itself is not in the repository (`*.jks`/`*.keystore`/`*.bks` are git-ignored). Package name is what FCM needs, so registration is not blocked — but the certificate fingerprint recorded here will **not** be the one Play App Signing uses, and any App Check or phone-auth setup keyed to this fingerprint would have to be redone. Decide the production signing key before Play upload.
2. **The Android source is not in this repository.** Only release APKs exist locally, so `android/app/build.gradle` could not be compared against the manifest. The binary is authoritative, and **1.1/1.2 agree**, but the source-level `applicationId` remains unconfirmed — there is no source to check.

**D2 remains unverified.** Whether the project id `parent-control-prod` is still available cannot be determined without
attempting to create it, which is a console action and out of scope here. Treat it as preferred, not confirmed.

The package verification procedure and exact commands are in
[10-owner-runbook.md](../docs/stage1/10-owner-runbook.md) §6; it was executed on 2026-10-30 and recorded in §0a above and
in the evidence file. The remaining source-level comparison cannot be done because the Android source is not in this
repository.

Do not register an app until this record exists and the project decision (D1/D2) is approved.

## 1. Prerequisites

- [ ] Sign in to the Firebase console as the Google account that will own the project. The Firebase CLI on this machine is authenticated as a **different** account (`om-event*`); run `firebase logout && firebase login` as the correct account before any CLI step.
- [ ] Confirm the org/account that owns `parent-control-prod` on Supabase is the same owner group (separate consoles, but one owner should control both).
- [ ] Confirm no billing change is needed. FCM sending is free; Spark is sufficient for Stage 1. A Blaze upgrade requires explicit approval and is **not** part of this checklist.
- [ ] Have the release SHA-1/SHA-256 fingerprints ready (they are only needed for App Check / phone auth, not for FCM).

## 2. Create the project

- [ ] Firebase console → **Create a project** → name `parent-control`
- [ ] Project id: `parent-control-prod` (if taken, use `parent-control-prod-<random>` and record the actual id)
- [ ] Google Analytics: **disabled**
- [ ] Confirm the project is on Spark, environment type labeled `production`
- [ ] Record in this file: project id, project number, region of default resources

## 3. Register the Android app

- [ ] Project settings → **Add app** → Android
- [ ] Package name: the confirmed `applicationId` from D3
- [ ] App nickname: `Haven child app`
- [ ] Debug signing certificate SHA-1: add only if App Check / phone auth will be used
- [ ] Download `google-services.json`
- [ ] Record the **App ID** (`1:<number>:android:<hash>`) — this is client config, not a secret
- [ ] `google-services.json` is already blocked by `.gitignore`; keep it that way. It is client config, but the repo policy is to keep client identifiers out of version control.

## 4. Enable Cloud Messaging

- [ ] Confirm **Cloud Messaging API (V1)** is enabled for the project (Firebase console → Cloud Messaging, and Google Cloud console → APIs)
- [ ] Do **not** enable the legacy server key. HTTP v1 with a service account only.
- [ ] Create a service account for server-side sending (Google Cloud console → IAM → Service accounts), role limited to Firebase Cloud Messaging (`roles/firebasecloudmessaging.admin` or narrower custom role)
- [ ] Download the JSON key **once**, and store it only as a Supabase Edge Function secret. Do **not** pass it inline as
      `"$(cat ...)"`: the value lands in your shell history and in the process argv. Flatten the JSON to one line in a
      throwaway file **outside the repository**, then load it from a file:
      `printf 'FCM_SERVICE_ACCOUNT_JSON=%s\n' "$(tr -d '\n' < /tmp/fcm-sa.json)" > /tmp/fcm.env && supabase secrets set --env-file /tmp/fcm.env && rm -f /tmp/fcm.env`
- [ ] Setting a secret requires the project to be linked (`supabase link --project-ref hhqgreaoqulmfwfwarhc`). Gate G1 is
      answered, so linking is no longer blocked by the audit — but `secrets set` is a **write to the production project**
      and needs explicit owner approval plus a decision on which environment the key belongs to (G6).
- [ ] Delete the local JSON after the secret is set; it must never enter the repo, a mobile app, or this document.
      `.gitignore` covers `service-account*.json`, `*-firebase-adminsdk-*.json`, `*.jks`, `*.keystore`, `*.bks`,
      `keystore.properties` and `signing.properties`; keep those patterns in place.
- [ ] Verify only the secret **name** exists (`supabase secrets list`); the CLI prints digests, not values.

## 5. What must still be built (not part of G2, listed so nothing is assumed to exist)

- [ ] A place to store device push tokens. **There is no `push_tokens` table and no token column on `devices` today.** Adding it is a G3-style migration decision, not a dashboard click.
- [ ] A server-side send path. No Edge Function currently sends FCM; the 9 deployed functions are pairing, registration, policy, command, telemetry, family admin, remote session, auth bootstrap and cron.
- [ ] Token rotation handling (on refresh, on reinstall, on invalid-token response).
- [ ] Reconciliation on app resume, because push is best-effort (see [02-architecture.md](../docs/stage1/02-architecture.md) §4).

## 6. Verification evidence to capture (only after the steps above)

| Check | Expected | Record |
| --- | --- | --- |
| Project id | matches the decided id | screenshot of project settings (no keys visible) |
| Registered app | exactly one Android app, package = confirmed id | app list |
| `google-services.json` | `package_name` matches the package in the app manifest | file diff, no key contents pasted |
| Service account | key exists in Google Cloud; only the secret name appears anywhere in the repo | name of secret, never its value |
| Test send | a message sent from the console to a test token arrives, or fails with a permission error that is explained | console output, sanitized |

Interactive messaging tests cannot be completed until the child app integrates the SDK — that is Stage 2, not Stage 1. Browser console access does not prove device reachability.

## 7. Rollback

- Wrong package registered: delete the app in Firebase → Project settings → Your apps. No data loss; no tokens have been issued.
- Wrong project: delete the project (irreversible, 30-day recovery window). Safer while nothing is wired: delete the Android app and recreate under the correct project id.
- Compromised service-account key: delete the key in Google Cloud, create a new one, update the Supabase secret, restart dependent functions.
