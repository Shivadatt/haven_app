# S2-A2 — Firebase Console Audit, Identity-Verification Plan and A12 Approval Package

**Document ID:** S2-A2
**Date:** 2026-11-03
**Class:** OFFLINE / REPOSITORY-ONLY AUDIT AND PLAN. **Grants nothing. Authorises nothing. Ratifies nothing.**
**Prepared by:** Subagent A2 (Firebase Console specialist).

---

## 0. Mode declaration — read this first

### 0.1 I performed no observation

**No browser was opened. No Firebase Console, Google Cloud console, Play Console, IAM surface, Supabase dashboard or
other network resource was contacted. No CLI, no REST, no API call, no curl, no DevTools, no direct connection was
used.** Every statement about the Firebase project's state in this document is a restatement of a capture made by
another operator on another day, cited by `file:line`. The only live operations performed to produce this file were
read-only local file reads, `grep`, `find`, `wc`, `sha256sum`, and local Python parsing of two JSON evidence files
(§5.3).

A **fresh** console observation is an **owner-instructed action**, not an audit step. It is separately entangled with an
unowned obligation (the dated-touch/auto-pause question, §6.1 `OP-01`). The brief's instruction to this agent is that the
deliverable is the **documented plan**. It is.

### 0.2 Status vocabulary

Console states in this document use exactly: `NOT STARTED`, `PLANNED`, `BLOCKED — APPROVAL REQUIRED`, `IN PROGRESS`,
`CONFIGURED`, `VERIFIED`, `FAILED`, `NOT APPLICABLE`. Where the evidence cannot speak to an item at all, this document
says in prose **`MISSING — SOURCE EVIDENCE ABSENT`** and the status cell stays `NOT STARTED`. Nothing in §2 is
`CONFIGURED`, and the reason is stated at §2.9.

Labels used alongside statuses: **Verified** (a dated observation exists), **Inferred** (reasoned from documented text,
not observed), **Missing evidence** (the repository does not contain the fact), **Unverified** (asserted somewhere but
not evidenced), **Recommendation** (this agent's opinion, binding on nobody).

### 0.3 Supersession and evidence-integrity warning

`docs/stage2/evidence/` contains **two contradictory Firebase snapshots**. `S2-INSP-02` (2026-10-30 morning window)
records that no Haven Firebase project exists; `S2-CREATE-01` (2026-10-30 later window) creates one; `S2-INSP-03`
(2026-11-02) re-confirms the new shell. Records are append-only with addenda. **A reader who cites only the earliest
record will conclude the wrong thing.** This audit treats `S2-INSP-03` (2026-11-02T07:16Z) as the current best snapshot,
with `S2-CREATE-01` as the creation evidence, and states where `S2-INSP-03` did *not* re-confirm something.

---

## 1. Evidence inventory — what each file is, dated, and what it can and cannot speak to

| File | Capture date | Console / subject | What it OBSERVED | What it did NOT observe | SHA-256 |
| --- | --- | --- | --- | --- | --- |
| [`docs/stage2/evidence/S2-INSP-02-firebase-console.md`](evidence/S2-INSP-02-firebase-console.md) | 2026-10-30T08:05–08:09Z | Firebase console root | `1 – 1 of 1` projects: only the unrelated FlutterFlow demo (`:19–22`); `Create a new Firebase project` present, not clicked (`:23`); no `haven-*`/`parent-control-*` project (`:24`) | Any product configuration — the project did not yet exist. Also: whether *another* Google account owns a Haven project — `NOT VERIFIED` (`:36`) | `fe85c7e9…7e06af9` |
| [`docs/stage2/evidence/S2-INSP-01-supabase-org-slots.md`](evidence/S2-INSP-01-supabase-org-slots.md) | 2026-10-30T08:00–08:08Z (+08:15Z addendum) | Supabase dashboard | Org/project inventory, Free plan, slot arithmetic, new-project form defaults (`:63–70`) | Firebase — nothing. Supabase is cited here only for the identity split and the slot ceiling | `9ef9948f…96eb00b64` (see §1 note) |
| [`docs/stage2/evidence/S2-CREATE-01-new-projects.md`](evidence/S2-CREATE-01-new-projects.md) | 2026-10-30 (local display `Oct 30, 5:25pm–6:25pm`, **no UTC start recorded**, `:4–5`) | Both consoles, OPERATIONAL | Creation of `haven-staging` / `haven-staging-46822` / number `381273275501` (`:116–131`); Spark plan observed (`:133–136`); project list `1 – 2 of 2` (`:138–141`); Analytics switched off and Gemini switched off (`:147–152`); environment type left `Unspecified` (`:154`); **zero apps, zero credentials, no FCM config** (`:156`) | Any product enablement, any provider, any Messaging tab content | `cf1cbc15…dda26ef` |
| [`docs/stage2/evidence/S2-INSP-03-read-only-reconfirmation.md`](evidence/S2-INSP-03-read-only-reconfirmation.md) | 2026-11-02T07:16–07:19Z | Both consoles, READ-ONLY | **The current best Firebase snapshot.** Overview (`:103–109`), Settings→General (`:111–130`), the settings tab inventory (`:121–125`), posture confirmations (`:195–198`) | `Cloud Messaging` tab **deliberately not opened** (`:122–124`); `Service accounts` **not opened** (`:124–125`); plan/usage page **not re-confirmed — redirects to `/overview`** (`:130–135`); screenshots impossible (`:205–213`) | `cdd6bd4b…a25ff429` |
| [`docs/stage2/evidence/S2-EXEC-01-phase0-readiness.md`](evidence/S2-EXEC-01-phase0-readiness.md) | 2026-11-02 | Local only | **Zero executed operations** (`:4–5`); 11 blank signature blocks, 0 filled (`:80–89`); blocker register (`:96–115`); A12 line `:132`; standing browser-only rule (`:190–193`) | Any Firebase observation — none occurred | — |
| [`docs/stage2/evidence/S2-NEXT-01-readiness-report.md`](evidence/S2-NEXT-01-readiness-report.md) | 2026-10-30T08:14Z | Firebase (brief) | Project list unchanged, `1 – 1 of 1` (`:90–95`); three-identity split (`:97–100`) | Anything post-creation | — |
| [`docs/stage1/evidence/g2-apk-identity-20261030.md`](../stage1/evidence/g2-apk-identity-20261030.md) | 2026-10-30 | **Not a console.** Local `aapt2`/`apksigner` on three APKs | Package `com.haven.familysafety` across all three builds (`:21`); two distinct signing identities (`:29–31`); version/SDK ranges (`:22–24`) | Source-level `applicationId` — no source exists (`:51–53`); Play App Signing identity (`:49–50`); **explicitly: no Firebase action of any kind** (`:54–55`) | `63ccb7ec…2e7fa2e7` |
| [`docs/stage1/evidence/g1-q8-20261029.json`](../stage1/evidence/g1-q8-20261029.json) | 2026-10-29 | Supabase production catalogue (column list) | 183 columns / 19 tables — re-parsed locally by this agent (§5.3) | Any push/FCM registration token column — **there is none** | `62aadcf2…49fc0e19be` |
| [`docs/stage1/evidence/edge-functions/capture-20261030.json`](../stage1/evidence/edge-functions/capture-20261030.json) | 2026-10-30 | Production Edge Function source, read in-page | 9 slugs + 6 `_shared/*.ts`; every `auth_model` field (`:32`, `:50`, `:64`, `:79`, `:92`, `:105`, `:121`, `:138`, `:156`) | Any Firebase reference — **zero. `grep` finds no Firebase token verification, no Admin SDK, no JWKS path** (corroborated by [S2-A1 §0.4](S2-A1-auth-architecture.md)) | `95ebe57c…86a39ce33` |

**Note on the SHA column:** hashes are the *only* provenance mechanism available in this repository — it has zero commits
and every file is untracked (`S2-EXEC-01:19–20`, `:41–44`). A hash here binds a document to the moment I read it, not to
any signature.

### 1.1 PII-IN-EVIDENCE FINDING (material, must travel with the register)

Three evidence files carry an **operator account name and email address in plaintext**:
`S2-INSP-02-firebase-console.md:17` and `:41–46` (account button text and the identity table),
`S2-CREATE-01-new-projects.md:121` and `:51`/`:60`, and
`S2-INSP-01-supabase-org-slots.md:31–34` and `S2-INSP-03-read-only-reconfirmation.md:56`.

**This document reproduces none of those values.** They are cited by file and line only.

Why it matters operationally, not just cosmetically:
- These are **personal Google identities**, and the programme's whole gating problem is *which identity holds which
  surface* ([`docs/stage1/02-architecture.md`](../stage1/02-architecture.md):227–228 records the two-identity split;
  `S2-A1` `O-10`). Persisting the identifier into a long-lived document set makes the ownership question harder to
  re-decide and creates a durable record of a person's account in a repository about **children's location and device
  telemetry**.
- The repository has **zero commits** and therefore no published history; correcting this now is a documentation act,
  not a history rewrite (§8 `Q-11`).
- `S2-INSP-02:46` additionally records a *third* identity (a CLI-authenticated account, described there as wrong and
  requiring logout), in a **partially-masked form**, which is then re-quoted verbatim by `S2-NEXT-01:97–100`. **This
  document reproduces neither the masked fragment nor the full value** — a mask that appears in two files is closer to
  unmasked than it looks, and repeating it here would be the third copy.

**Recommendation (not an instruction):** replace the literal values with opaque handles (e.g. `IDENTITY-FB-1`,
`IDENTITY-SB-1`) plus a pointer to a single owner-held custody note, and record the substitution as a dated
supersession addendum on each file. No agent may perform that edit as part of this audit — the brief permits exactly
one new file.

---

## 2. Firebase project identity verification plan (operator procedure, browser-only)

**Purpose:** prove, before the first click of any kind, that the browser is positioned on
`haven-staging-46822` and on nothing else. The reason this needs a procedure rather than a glance: at the last
authorised observation this Google account lists **exactly two projects** (`S2-CREATE-01:138–141`) — the Haven shell and
an unrelated FlutterFlow demo — so a one-click error into the wrong project is structurally easy.

### 2.1 What the console header must show

| # | Check | Where on screen | Must read | Evidence anchor |
| --- | --- | --- | --- | --- |
| H-1 | Project **display name** in the top project switcher | console header, left | `haven-staging` | `S2-INSP-03:103`, `S2-CREATE-01:127` |
| H-2 | **Project ID** | Project settings → General → `Your project` | `haven-staging-46822` | `S2-INSP-03:116`, `S2-CREATE-01:128` |
| H-3 | **Project number** | same page | `381273275501` | `S2-INSP-03:117`, `S2-CREATE-01:129` |
| H-4 | **URL path segment** | address bar | contains `/project/haven-staging-46822/` exactly | `S2-CREATE-01:118`, `S2-INSP-03:103` |
| H-5 | Project **switcher count** | project picker | `1 – 2 of 2`, i.e. exactly two projects. If it reads `1 – 1 of 1`, the operator is on a **different Google account** and must STOP | `S2-CREATE-01:138–141`; the `1 – 1 of 1` state is `S2-INSP-02:19` |
| H-6 | Absence of the wrong target | switcher list | `FlutterFlowWIthFIreBase` must **not** be the highlighted project | `S2-INSP-02:19–22`, `:33` |
| H-7 | Signed-in identity | account chip | must be the identity recorded as owning the Firebase shell — **not** the Supabase-owning identity. Value not reproduced here (§1.1) | `S2-INSP-02:41–50`, `02-architecture.md:227–228` |
| H-8 | Environment label | Project settings → General | **There is no usable environment label.** Observed value is `Unspecified` (`S2-CREATE-01:130`, `S2-INSP-03:118`), so H-2 + H-3 are the **only** project-identity proof available | — |

**H-8 is the load-bearing finding of this section.** The display name `haven-staging` is **not** a stable identifier:
display names are editable and not unique. `S2-CREATE-01:158` records that `haven-staging` was *rejected as an exact
project ID*, so Google minted `haven-staging-46822` — meaning name and ID differ permanently, and a later operator
eyeballing "haven-staging" in a header cannot distinguish it from a same-named project on another account. **Project ID
plus project number, read together, are the identity.** Any procedure that stops at the display name is insufficient.

### 2.2 The echo-before-any-click rule

Adopted from the standing Supabase rule, which states the same discipline: *"Echo the ref from the console header into
the change record before running anything"* (`04-risks-rollback-approvals.md:101` R-43; `00-stage2-execution-plan.md:41`
C2b, "Echo the ref from the console header into the change record before running anything"). Applied to Firebase:

```text
PRE-FLIGHT IDENTITY RECORD  (written into the change record BEFORE the first click)
  utc_start ........................
  console URL as shown ............. /project/haven-staging-46822/…
  H-1 project name read ............ haven-staging
  H-2 project id read .............. haven-staging-46822
  H-3 project number read .......... 381273275501
  H-4 URL segment read ............. haven-staging-46822
  H-5 switcher count read .......... 1 – 2 of 2
  ALL FIVE MATCH THE RECORD ABOVE?   yes → proceed / no → CLOSE TAB, RECORD, STOP
  identity used ...................  handle only, never the address (§1.1)
```

Rules that make the echo meaningful:
1. **Copy from the page, never from this document.** The point is to compare what the console says *now* against what
   the evidence says *then*. Typing `haven-staging-46822` from memory defeats it.
2. **Any mismatch aborts by closing the tab, not by navigating to the expected project.** A mismatch means the session
   is not where the plan thinks it is; that fact is the finding and must be recorded before it is "fixed".
3. **A third project appearing in the switcher is itself a STOP**, because nothing in this programme created one.
4. **Never navigate by project name** — navigate by the full URL containing the project ID, which is the read-only path
   that worked throughout `S2-INSP-03:211–212`.

### 2.3 Known console-surface hazards that undermine naive verification

| Hazard | Evidence | Consequence for the plan |
| --- | --- | --- |
| Pointer clicks fail intermittently with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE` | `S2-INSP-03:207–209`; `S2-CREATE-01:161–164` | A click that "fails" may still have landed. Any A12 step needs a **re-read of the resulting state**, never a retry loop |
| `Enter` does not activate these Material buttons; `Space` does | `S2-CREATE-01:163` | Do not double-submit a wizard |
| `/settings/usage` and `/settings/plan` **redirect back to `/overview`** | `S2-INSP-03:130–135` | Plan tier cannot be re-confirmed by URL alone; it needs a Settings-menu click, i.e. a pointer action on an unstable surface |
| Merely *visiting* Settings → Cloud Messaging may surface sender-ID / registration-token state | `S2-INSP-03:122–124` | Visiting that tab is treated by the current evidence discipline as an **A12-adjacent act**, not a free read (§6 `OP-05`) |
| `Service accounts` is the credential surface | `S2-INSP-03:124–125` | Same treatment (`OP-07`) |
| No screenshot has ever been captured programme-wide | `S2-INSP-01:11–15`, `S2-INSP-02:9`, `S2-CREATE-01:23–29`, `S2-INSP-03:213` | Visual evidence cannot back any A12 step. Accessibility-tree text is the only evidence type this programme has ever produced |

### 2.4 Explicit non-observation statement

I performed **none** of §2.1–§2.3. I did not verify that the shell still exists today, that its identity values are
unchanged, that the project list is still two entries, or that the plan is still Spark. The most recent authorised
observation is **2026-11-02T07:16Z** (`S2-INSP-03:4`). Everything after that date is unknown.

---

## 3. Console audit from existing evidence

Project under audit: `haven-staging` / `haven-staging-46822` / number `381273275501`. Reference date of every row:
**2026-11-02T07:16Z** unless stated. "Absence is VERIFIED" means the evidence positively observed the absence.

### 3.1 Project-level

| Item | Status | Evidence (`file:line`) | What exactly the evidence says |
| --- | --- | --- | --- |
| Project exists | `VERIFIED` | `S2-CREATE-01:116–131`; `S2-INSP-03:111–118` | Created 2026-10-30, re-confirmed 2026-11-02 |
| Identity fields (name / ID / number) | `VERIFIED` | `S2-INSP-03:115–117` | All three match the creation record; `S2-INSP-03:127` "These four values match `S2-CREATE-01` §3 exactly" |
| Project **was created outside its gate** | `VERIFIED` | `04-risks…:94` R-36; `:236`; `00-stage2-execution-plan.md:235–244` | Exceeded the A12 prohibition as then written; `RATIFIED — 2026-11-02 — OPTION (i)`, retrospective only, grants nothing forward |
| Environment type set to `Staging` | `NOT STARTED` | `S2-CREATE-01:130`, `:154`; `S2-INSP-03:118` | Reads `Unspecified`; the value **is** VERIFIED, the *work* was deliberately skipped as out of scope |
| Plan tier | `VERIFIED` *(as at 2026-10-30 only)* | `S2-CREATE-01:133–136` | `Current billing plan: Spark`, `No-cost`. **Not re-confirmed** 2026-11-02 — `S2-INSP-03:130–135` records the redirect and classifies plan as `NOT VERIFIED` on that pass |
| Billing / no upgrade performed | `VERIFIED` | `S2-CREATE-01:136` | `Upgrade` call-to-action displayed and not clicked |
| Project members / roles | `NOT STARTED` | `S2-INSP-03:121` lists `Users and permissions` as offered | **Never opened.** `MISSING — SOURCE EVIDENCE ABSENT` for who else can act on this project |
| Data privacy / deletion protection | `NOT STARTED` | `S2-INSP-03:121` | Tab offered, never opened |
| Alerts | `NOT STARTED` | `S2-INSP-03:109` (`0 unread alerts`), `:121` | Only the badge count was ever read |
| Integrations | `NOT STARTED` | `S2-INSP-03:121` | Never opened |
| Gemini AI assistance | `NOT STARTED` (as a *product in use*) | `S2-CREATE-01:147–150` | Switched **off** at creation, confirmed `checked="false"` before advancing; recorded as a declared least-privilege **deviation** beyond the owner's instruction |
| Google Analytics | `NOT STARTED` | `S2-CREATE-01:151–152`; `:183` | Off as instructed, confirmed by switch state **and** by the button text changing to `Create project` |

### 3.2 Products (the "nothing is enabled" finding)

| Product | Status | Evidence | Note |
| --- | --- | --- | --- |
| **No Firebase product appears in the left navigation** — only `Project Overview` and `Settings` | `VERIFIED` | `S2-INSP-03:107–108`, `:197` | This is the single strongest negative observation in the evidence set: *"no Analytics, Auth, Firestore, RTDB, Storage, Messaging, Hosting or App Hosting entry is present, i.e. **no Firebase product is enabled**"* |
| Firestore | `NOT STARTED` | `S2-INSP-03:107–108`; `02-architecture.md:206` §9 row 7 | `MISSING — SOURCE EVIDENCE ABSENT` for database location/region — never configured, so nothing to observe |
| Realtime Database | `NOT STARTED` | `S2-INSP-03:107–108` | Absence VERIFIED |
| Storage | `NOT STARTED` | `S2-INSP-03:107–108` | Absence VERIFIED |
| App Hosting / Hosting | `NOT STARTED` | `S2-INSP-03:107–108` | Absence VERIFIED |
| Cloud Functions (Firebase) | `NOT STARTED` | `S2-INSP-03:107–108`; `02-architecture.md:206`; S2-A1 §0.4 (grep returns nothing) | Server-side logic is Supabase's assigned role in the new direction |
| Extensions, ML Kit, App Distribution, Test Labs, Remote Config, Performance, Crashlytics | `NOT STARTED` | *(no per-product row exists in the evidence)* | `MISSING — SOURCE EVIDENCE ABSENT` individually. The nav-absence observation at `S2-INSP-03:107–108` covers them **as a class** but names only eight entries. Stated honestly rather than inflated |

### 3.3 Authentication

| Item | Status | Evidence |
| --- | --- | --- |
| Any sign-in provider enabled | `NOT STARTED` | `S2-INSP-03:107–108` — no `Auth` navigation entry exists. **Absence VERIFIED** |
| Email/password provider | `NOT STARTED` | same |
| Google Sign-In provider | `NOT STARTED` | same |
| Phone, Anonymous, Apple, GitHub, custom providers | `NOT STARTED` | same |
| Firebase Auth user records | `NOT STARTED` | `02-architecture.md:18`, `:173` — "no user has a Firebase identity today"; `:205` §9 row 6 "Not in the approved architecture" |
| `auth-bootstrap` function as today's identity entry point | `VERIFIED` *(production, 2026-10-30)* | `capture-20261030.json:44–55` — `auth_model`: "user JWT + verified email; `set_role` is self-only and one-time from 'unset'". **The current identity channel is Supabase, not Firebase** |
| **Whether the new "Firebase = Authentication" direction is implementable** | `BLOCKED — APPROVAL REQUIRED` | Requires A12 (unsigned) for provider enablement, plus a documentation amendment because **four in-repo records prohibit Firebase Auth** (§7.1, S2-A1 §5.4 `A-18`) |

### 3.4 Android applications and configuration

| Item | Status | Evidence |
| --- | --- | --- |
| Registered apps of any platform | `NOT STARTED` (absence `VERIFIED`) | `S2-INSP-03:119` — `There are no apps in your project`; `S2-CREATE-01:131`, `:156`; `S2-INSP-03:196` "Firebase has zero apps and therefore zero credentials" |
| `google-services.json` | `NOT STARTED` | `S2-CREATE-01:156`; `S2-INSP-03:127–128`. Repo pattern exists but no instance: `.gitignore` blocks `google-services.json` |
| iOS `GoogleService-Info.plist`, web config | `NOT APPLICABLE` | The product surface evidenced is Android only — three APKs at `g2-apk-identity-20261030.md:12`. `S2-CREATE-01:128` also notes no plist/web config exists |
| App-nicknamed "Haven child app" | `PLANNED` | `firebase/SETUP-CHECKLIST.md:74` — proposed, never entered |
| `Add app` control | `NOT STARTED` | `S2-INSP-03:105`, `:225` — present, **not clicked**, along with all five "Add Firebase to your … app" buttons |
| Package name value to register | `VERIFIED` *(binary-level only)* | `com.haven.familysafety` across 1.0/1.1/1.2, `g2-apk-identity-20261030.md:21`, `:36`; `SETUP-CHECKLIST.md:26` `:15` (`D3` `VERIFIED`). **Source-level `applicationId` is `NOT VERIFIED` — there is no source** (§4.3) |
| Release signing identity | `VERIFIED` *(as local artefacts)* | `g2-apk-identity-20261030.md:29–31`. Two divergent certificates across three builds (`:39–42`). Values cited by line, not reproduced |
| Debug signing fingerprint | `NOT STARTED` | `MISSING — SOURCE EVIDENCE ABSENT` — nothing in the repository records a debug keystore, and `.gitignore` blocks `*.jks`/`*.keystore`/`*.bks` |
| Play App Signing fingerprint | `NOT STARTED` | `g2-apk-identity-20261030.md:49–50` states it *will differ* from both captured certificates. Play Console was never opened (`:15`) |

### 3.5 Cloud Messaging / FCM

| Item | Status | Evidence |
| --- | --- | --- |
| FCM configured | `NOT STARTED` | `S2-CREATE-01:156` "no FCM config"; `02-architecture.md:174` `DOES NOT EXIST`; `00-stage2-execution-plan.md:245` "**FCM does not exist**" |
| Cloud Messaging settings tab contents (sender ID, project number as used for sending, legacy server key state) | `NOT STARTED` | **Never observed.** `S2-INSP-03:122–124` records the tab was *deliberately not opened*. `MISSING — SOURCE EVIDENCE ABSENT` |
| Cloud Messaging API (`v1`) enabled at Google Cloud level | `NOT STARTED` | `SETUP-CHECKLIST.md:82` lists it as an unchecked TODO step. Never verified anywhere |
| Legacy FCM server key | `NOT APPLICABLE` | `SETUP-CHECKLIST.md:83` "**Do not enable the legacy server key**"; S2-A4 §credential table marks the legacy `AAAA…` shape "explicitly not to be created ⇒ `NOT APPLICABLE`" |
| Server-side send path | `NOT STARTED` | `SETUP-CHECKLIST.md:100` "No Edge Function currently sends FCM"; `02-architecture.md:176` `PROPOSED`; corroborated by my own read of all 9 `auth_model`/`imports` fields in `capture-20261030.json` — **no Firebase/Messaging module appears in any of the 9 functions or 6 shared files** |
| Device push-token storage | `NOT STARTED` | Verified absence — §5.3 |
| Console test send | `NOT STARTED` | `SETUP-CHECKLIST.md:112` describes it; `:114` states it cannot complete without the SDK integrated |
| A12 gate for all of the above | `BLOCKED — APPROVAL REQUIRED` | `approval-package-v2…:349–368` §3.7, signature fence `:366` blank; `04-risks…:220` row A12 "**UNSIGNED as a forward block**"; `S2-EXEC-01:84` lists A12 among 8 blank blocks with **0 filled** |

### 3.6 Credentials and service accounts

| Item | Status | Evidence |
| --- | --- | --- |
| Service account created | `NOT STARTED` | `S2-CREATE-01:156` "no service-account key"; `S2-INSP-03:124–125` tab never opened; `S2-INSP-03:196` |
| Any Firebase credential generated or copied | `NOT STARTED` | `S2-CREATE-01:157` "**Zero Firebase credentials were created or copied**" |
| `FCM_SERVICE_ACCOUNT_JSON` secret value | `NOT STARTED` | `.env.example:11` — the name is present **commented out with no value**. Only a placeholder |
| Secret placement mechanism | `BLOCKED — APPROVAL REQUIRED` **and** method-conflicted | A9 unsigned (`approval-package-v2…:327–346`, fence `:344`); and the *only documented placement procedure* in the repo is CLI-based — see §5.4 |
| Google Cloud IAM / service-account console surface | `NOT STARTED` | `MISSING — SOURCE EVIDENCE ABSENT`. `SETUP-CHECKLIST.md:84` names it as a step; **no capture of any Google Cloud surface exists anywhere in this repository** |

### 3.7 Cross-surface facts that constrain Firebase work

| Fact | Status | Evidence |
| --- | --- | --- |
| Every Edge Function uses the service-role key, so **RLS never applies** and `auth.uid()` is NULL for live callers | `VERIFIED` (production, 2026-10-30) | `docs/stage1/14-edge-function-security-audit.md:243` Check 12 — "**VERIFIED — every function uses the service-role key, therefore RLS never applies.** This is the single most important architectural fact in this audit"; body read from `_shared/auth.ts` `getServiceClient`, `capture-20261030.json:166` |
| Current identity channels are **three**, none of them Firebase | `VERIFIED` | `capture-20261030.json`: user JWT + verified email (`:32`, `:50`, `:64`, `:79`, `:92`, `:121`, `:138`), device headers `x-device-id`/`x-device-secret` (`:64`, `:105`), shared `x-cron-secret` (`:156`) |
| Staging has **0 Edge Functions deployed** | `VERIFIED` | `S2-INSP-03:88–92` — onboarding state, toast `Edge function cannot be found in your project` |
| Staging has **0 tables**, `No migrations` | `VERIFIED` | `S2-INSP-03:83–86`, `:37–38`, `:191–192` |
| Supabase slot headroom | `VERIFIED` | `S2-INSP-03:78–81`; `04-risks…:96` R-38 — 2 active / 2 used / **0 remaining** |
| Auto-pause obligation | `BLOCKED — APPROVAL REQUIRED` / **unowned** | `S2-INSP-03:233–242` §7; `04-risks…:98` R-40; `S2-EXEC-01:106` B-7 — dated touch "on or before **2026-11-06**", **no UTC start ever recorded**, and "Meeting it is an operational action needing owner instruction, not documentation" |

### 3.8 Why nothing is marked `CONFIGURED`

`CONFIGURED` would require an observation of a product setting holding a value. **The evidence set contains no such
observation for any Firebase product.** It contains positively-observed *absence* — a product navigation with nothing in
it (`S2-INSP-03:107–108`) and an empty app list (`:119`). `IN PROGRESS` is likewise unused: no Firebase work has begun,
because A12 is unsigned and the amended prohibition forbids exactly the actions that would constitute beginning
(`approval-package-v2…:121`, `:131`; `04-risks…:220`).

### 3.9 The one-sentence answer

**The Firebase project is a bare, product-less, app-less, credential-less shell on an unverified plan, created outside
its own approval gate and never configured since.** Every item in §3 either supports that sentence or is the honest
acknowledgement that the evidence cannot reach further.

---

## 4. Android application registration checklist

### 4.1 The fields the console will ask for

Labelled by grounding: **GROUNDED** = the field appears in this repository's own text; **INFERRED** = the console
generalises it and it must be confirmed live.

| # | Field | Grounded status | Where the value must come from | Value state in this repo |
| --- | --- | --- | --- | --- |
| F-1 | Platform choice (**Android**) | GROUNDED — `SETUP-CHECKLIST.md:72` "Project settings → **Add app** → Android" | Owner decision | `NOT STARTED` |
| F-2 | **Package name** (`applicationId`) — required | GROUNDED — `SETUP-CHECKLIST.md:73`; the console form field name is corroborated by the sibling FlutterFlow demo's declared package `com.mycompany.flutterflowwithfirebase` (`S2-INSP-02:21–22`) | The app's manifest/build config | `com.haven.familysafety` — `VERIFIED` from **binary** inspection of all three APKs (`g2-apk-identity-20261030.md:21`, `:36`); `SETUP-CHECKLIST.md:15` D3 |
| F-3 | **App nickname** — optional | GROUNDED — `SETUP-CHECKLIST.md:74` | Owner decision | `PLANNED`: `Haven child app`. **Never approved.** In the new topology there are two apps (parent + child — `02-architecture.md:25–26`), so a single nickname is ambiguous — `MISSING — SOURCE EVIDENCE ABSENT` for a naming decision |
| F-4 | **Debug signing certificate SHA-1** — optional | GROUNDED — `SETUP-CHECKLIST.md:75`, `:60` ("only if App Check / phone auth will be used") | The local debug keystore | **DOES NOT EXIST IN THIS REPOSITORY.** No debug keystore is recorded; `.gitignore` blocks `*.jks`, `*.keystore`, `*.bks`, `keystore.properties`, `signing.properties` |
| F-5 | **Release / upload SHA-1** | GROUNDED in *substance* (`g2-apk-identity-20261030.md:31`), **INFERRED in field name — verify in console at execution time** | `apksigner verify --print-certs` on the shipped APK | Recorded for 1.1/1.2 and separately for 1.0 (`:29–31`) — **two different identities for one package name** |
| F-6 | **SHA-256 certificate fingerprint** | **INFERRED — verify in console at execution time.** The repository's own checklist names SHA-1 only (`SETUP-CHECKLIST.md:60`, `:75`); it records SHA-256 as an *APK/certificate digest* (`g2-apk-identity…:30`), not as a console field | Same capture as F-5 | Value recorded; **its use as a console field is not evidenced** |
| F-7 | `google-services.json` **download** | GROUNDED — `SETUP-CHECKLIST.md:76` | Generated by the console at registration | Does not exist (`S2-CREATE-01:156`). Must not enter the repo — `.gitignore` blocks it |
| F-8 | **App ID** (`1:<project-number>:android:<hash>`) recorded after registration | GROUNDED — `SETUP-CHECKLIST.md:77` — "this is client config, not a secret" | Console, post-registration | Does not exist |
| F-9 | Firebase ML Kit / App Check prompts | **INFERRED — verify in console at execution time.** `SETUP-CHECKLIST.md:60` and `:75` imply App Check exists as a downstream concern; no registration-wizard step is documented | n/a | Must be declined. Under §7 the owner's standing instruction means **no product beyond the minimum may be switched on as a wizard side-effect** |

### 4.2 Values that DO NOT EXIST in this repository — stated plainly

Confirmed by direct inspection for this audit (`find` over every non-`.git` path; 93 files total, all listed in §4.3):

| Required value | Exists? | Where it would have to come from |
| --- | --- | --- |
| Source-level `applicationId` (`android/app/build.gradle(.kts)`, merged `AndroidManifest.xml`) | **NO** | The Android project itself. `g2-apk-identity…:51–53` and `SETUP-CHECKLIST.md:43` both say so; my `find` agrees |
| Debug keystore and its SHA-1 | **NO** | A developer machine, not the repository |
| Play App Signing certificate fingerprints | **NO** | Play Console — never opened (`g2-apk-identity…:15`) |
| Production release keystore | **NO** (and git-ignored by policy) | Owner custody. `SETUP-CHECKLIST.md:42` — the captured key is a **demo key** (`O=Haven Demo`) and "will **not** be the one Play App Signing uses" |
| `google-services.json` / App ID / sender ID | **NO** | Cannot exist before registration (`S2-INSP-03:127–128`) |
| A decision on parent-app vs child-app registration | **NO** | The architecture names two client apps (`02-architecture.md:25–26`); the checklist proposes one nickname and one registration (`:74`). `MISSING — SOURCE EVIDENCE ABSENT` |
| An approved package name for *staging* | **NO** | See §4.4 |

### 4.3 Self-verification that there is no application source (I checked; I did not take it on trust)

Command run for this audit, read-only, from `D:\control`:
`find . -path ./.git -prune -o \( -name pubspec.yaml -o -name '*.dart' -o -name '*.kt' -o -name 'build.gradle*' -o -name AndroidManifest.xml -o -name google-services.json -o -name '*.swift' -o -name Package.swift -o -name package.json -o -name '*.java' -o -name project.pbxproj -o -name 'MainActivity.*' -o -name '*.aab' -o -name '*.apk' \) -print`
→ **zero matches.**

Full repository inventory is **93 files**, all of them Markdown, three `.sql` patches, `supabase/config.toml`,
`supabase/.gitignore`, `.env.example`, `.gitignore`, `README.md`, and the JSON evidence captures. There is no
`lib/`, no `android/`, no `ios/`, no `src/`. `S2-EXEC-01:30–39` independently lists the same six untracked top-level
entries; `S2-A1 §0.3` reached the same conclusion.

**Therefore: confirmed — there is no Flutter source and no Kotlin source in this repository.** Consequences that matter
specifically to the console work:
- The `applicationId` can never be reconciled between source and manifest; the **binary is the only authority** and it
  is unauthenticated (`g2-apk-identity…:46–48`: "a hash and a TLS download are not authenticity").
- Whether the shipped apps even contain the Firebase/FCM SDK is **un-auditable here** — `S2-REVIEW-03` records it as
  `NOT VERIFIED` (quoted at S2-A1 §0.3/`A-…`), and G1's "Firebase SDK inside the shipped APKs" claim cannot be tested
  from the repository.
- No client can consume `google-services.json`, so **a registered app would be an artefact with no consumer**, and a
  console test send (§6 `OP-09`) cannot be completed.
- `G5-E`/`G5-C` validation is blocked by exactly this (`S2-EXEC-01:110` B-11: "no Edge Function source, no app source in
  this repo. 104 of 105 HTTP cases cannot run").

### 4.4 The registration decision the repository does not resolve — flag it before any A12 signature

Registering `com.haven.familysafety` **inside `haven-staging-46822`** is not a neutral staging action:

1. **One installed package can only carry one `google-services.json` per build.** If the same package name is later
   registered in a production Firebase project, a given APK build pushes to exactly one project. `06-secrets-and-environments.md:66`
   already identifies the fork: *"Each environment needs its own Firebase project, own `google-services.json` and own
   service account, or one project with distinct Android application ids per environment. That forces either distinct
   `applicationId` suffixes — **which changes the installed package, a user-visible decision** — or per-flavor config
   wiring. Do not guess the package name; no app is registered yet."* **This is a product decision, not a console step.**
2. **An Android registration is "permanent-ish and hard to undo cleanly"** — the repository's own words at
   `SETUP-CHECKLIST.md:15` (D3 rationale). Rollback exists (`:118` — delete the app; "no tokens have been issued") but
   the App ID is not reusable and any downloaded config becomes dead material.
3. **Registering with a demo certificate fingerprint** bakes a throwaway signing identity into the record and, if App
   Check or phone auth ever keys to it, must be redone (`SETUP-CHECKLIST.md:42`).
4. **`S2-CREATE-01:158` establishes that Google rewrites identifiers.** `haven-staging` → `haven-staging-46822`
   unrequested. If a similar rewrite ever touched an App ID or a project number used by a shipped client, the mapping
   recorded in the repository silently breaks. The mitigation is only discipline: record every value read from the
   console at the moment of the action.

**Recommendation:** the A12 package in §6 sequences registration *after* the environment-package decision is answered,
because registration before that decision is the irreversible half of a choice the owner has not made.

---

## 5. Authentication provider configuration plan

### 5.1 First: the direction and the repository disagree, and that is the finding

The new architecture direction assigns **Authentication** to Firebase. The repository's plan of record says the
opposite, in four places:

| Record | Wording (quoted) |
| --- | --- |
| `docs/stage1/02-architecture.md:18` | "Firebase Auth stays **disabled** unless a written decision in a later stage says otherwise; no user has a Firebase identity today." |
| `docs/stage1/02-architecture.md:173`, `:205` (addendum §9 row 6) | "`Firebase Auth disabled` — VERIFIED (current state)"; "**Not in the approved architecture.** Stays disabled" |
| `docs/stage2/approval-package-v2-ratification-and-forward.md:106–107`, `:354` | "**Supabase Auth is the single identity authority.** … Firebase Auth, Firestore and Cloud Functions are **not approved requirements**" |
| `docs/stage2/00-stage2-execution-plan.md:245–246` | "Firebase is intended for FCM transport only; Firebase Auth, Firestore and Cloud Functions are not part of the approved architecture." |
| `firebase/SETUP-CHECKLIST.md:16` (decision `D4`) | "**Leave disabled**" |
| `docs/stage2/parts/F-e6-e7.md:215` | "Firebase Auth is to remain disabled — Supabase Auth is the only identity authority (all 9 Edge handlers call `db.auth.getUser(token)`)" |

**I do not resolve this, and I do not silently agree with either side.** The `:18` record *anticipates* the change —
"unless a written decision in a later stage says otherwise" — so the new direction is not prohibited by that file. But
`approval-package-v2:354` and `00:245–246` are **live approval text**, and the A12 signature fence
(`approval-package-v2…:366`) acknowledges the FCM-only premise in its own body: *"I acknowledge that Supabase Auth is
the identity authority, Firebase is FCM-transport-only."*

**Consequence an owner must see before signing anything: the A12 block as drafted asks the owner to sign an
acknowledgement that contradicts the architecture they have just directed.** Signing it unchanged while intending
Firebase Auth would create a signed record whose stated premise is false. `docs/stage1/02-architecture.md:18` permits
the decision; **the approval text does not yet accommodate it.** Flag `Q-1` (§8) and S2-A1 `O-2`.

### 5.2 Providers the product could actually need — and the cost of each

Assuming the owner does choose Firebase Auth, `MISSING — SOURCE EVIDENCE ABSENT` for which provider, because no
requirement document names one. The candidate set, with blast radius:

| Provider | What it is for | Blast radius of enabling | Verdict |
| --- | --- | --- | --- |
| **Email/password** | Parent and child sign-in with a stored password | Creates a **second credential store** beside `auth.users`/GoTrue. Requires password policies, reset mail, and an SMTP sender for non-Firebase-branded mail. Every account becomes a record that must be deleted under GDPR-ish rules in a **children's product**. Provisioning becomes the hard problem S2-A1 §2.4 already documents (`profiles.id` is `uuid NOT NULL` with an FK to `auth.users(id)`; a Firebase UID is neither) | **Owner decision.** Not `NOT APPLICABLE` under the new direction, but not selectable by this audit |
| **Google Sign-In** | Federated parent login | Requires a **Google Cloud OAuth consent screen** on the same project — a surface that has never been observed in this repository (§3.2 note). Publishing/verifying it is a branding + support-email + privacy-policy disclosure act that becomes visible to end users. Also re-introduces the identity-ownership question: the OAuth client would live on the *non-Supabase* identity | **Owner decision**, and the largest new shared state of any provider option |
| **Anonymous** | Pre-pairing device identity | Auto-provisions identities with no credential. In a parental-control product this creates accounts a parent cannot authorise and cannot authenticate to, and inflates `MAU`-type counters. It does **not** match the device lane, which already has its own credential pair (`x-device-id`/`x-device-secret`, `capture-20261030.json:64`, `:105`) | **Recommendation: decline.** S2-A1 `O-8` already asks whether the device lane needs a Firebase token at all |
| **Phone** | SMS login | `INFERRED — verify at execution time`: this is the provider class most associated with a **paid-plan requirement**. A12's own stop condition is "Any wizard offering a paid plan" (`approval-package-v2…:357`). Phone auth also keys to the certificate fingerprint (`SETUP-CHECKLIST.md:60`) — i.e. to the **demo** key (§4.4) | **Recommendation: decline.** It would force a billing change on the same account that holds an unverified plan |

**Why email/password vs Google Sign-In is an owner decision and cannot be an audit recommendation:** it is not a
technical preference, it is (a) which **secret** the parent must hold, (b) whether a **third-party identity** may open a
family's child-tracking product, (c) whose password-hash store becomes authoritative for revocation, and (d) in a
product whose failure mode is "a removed child keeps a live session" (S2-A1 §5.5 R-1) — **which system can end a
session**. The repository has no requirement text on any of the four.

### 5.3 The irreversibility argument — what "enabling a provider" actually costs

The brief's concern is correct and worth stating precisely, because "you can just switch it off again" is the dangerous
assumption:

1. **User records outlive the provider.** Once a Firebase Auth user exists, disabling the provider leaves the identity
   behind; the records must be deleted individually. There is no bulk "un-enable". This is the same class of trap as
   FX-18 — a count that no longer maps to anything anyone created.
2. **Provider enablement is not contained to Auth.** `INFERRED — verify in console at execution time`: enabling Auth can
   surface or default a **Firestore** database, and a Firestore **location is permanent and cannot be changed** once
   chosen. Under the owner's standing instruction (§7) Firestore must stay off, so an Auth wizard that offers it is a
   **stop condition**, not a step. A12 already carries exactly this shape of stop condition (`approval-package-v2…:357`),
   and `S2-CREATE-01:147–150` is the precedent: a wizard presented an unanticipated Gemini switch the plan had not named,
   and it had to be caught manually.
3. **Plan state can change underneath the project.** A provider or an associated API that requires Blaze moves the
   project off Spark; `approval-package-v2…:357` forbids it and the plan tier is **not even currently re-confirmed**
   (`S2-INSP-03:130–135`).
4. **An OAuth consent screen is external shared state** — published to Google's verification pipeline, keyed to the
   project, visible to users. It cannot be un-published from the Firebase console.
5. **Two identities, one bridge.** The credential placement for "Supabase Edge Function verifies Firebase tokens" crosses
   the Supabase-owning and Firebase-owning identities — the boundary `02-architecture.md:227–228` explicitly does **not**
   authorise. S2-A1 `R-4` and `O-10` say the same thing.
6. **Split-brain identity is a known realised risk, not a hypothesis.** `S2-REVIEW-03` §G row 5 records
   "split-brain three identities"; `S2-INSP-02:40–50` documents the three surfaces. Adding a fourth user store is the
   action that turns a documentation problem into a production one.

### 5.4 Verification of a Firebase ID token — what the console part is and is not

This is the *Supabase* side of the new direction, but it constrains the Firebase configuration, so it belongs here:

- **Nothing exists today.** My own check: all 9 `auth_model` fields and all 6 shared modules in
  `capture-20261030.json` (`:32`–`:170`) contain no Firebase verifier; every user-facing handler is "user JWT + verified
  email". Corroborated by S2-A1 §0.4 (`verify-firebase-token` grep → nothing).
- **The service-role fact dominates.** `14-edge-function-security-audit.md:243` (Check 12): every function runs as
  service-role, so **RLS never applies and `auth.uid()` is NULL for live callers**. A Firebase ID token arriving at such
  a function does not change that: the function would still be its own trust boundary, and the mapping from verified
  `sub` → `profiles.id` would still be **argument-borne**, which is precisely the F7/E3 actor-confusion class S2-A1
  §5.5 R-3 says re-opens.
- **Console-visible dependency:** any verifier that needs a **service-account key** (S2-A1 option `V-1`) is an A9 + A12
  credential event, and the repository's only documented placement procedure for it is **CLI**
  (`SETUP-CHECKLIST.md:88`, `:89`, `:95`: `supabase secrets set --env-file`, `supabase secrets list`) — which the
  standing owner rule forbids outright (`S2-EXEC-01:190–193`; `00-stage2-execution-plan.md:41` C2b: "browser dashboards
  only … **no CLI, terminal, PowerShell, CMD, REST, curl, Postman, DevTools, direct DB connection or workaround**").
  **The A12 package therefore cannot inherit `SETUP-CHECKLIST` §4 as its runbook.** `OP-08` in §6 marks this as an
  unresolved method conflict, not a solved step.

---

## 6. FCM setup and verification plan

### 6.1 What must be true before a device token can be delivered

Eight conditions, in dependency order. Every one is currently unmet.

| # | Condition | Status today | Why |
| --- | --- | --- | --- |
| C-1 | A Firebase **Android app registered** in `haven-staging-46822` with the exact shipped package name | `NOT STARTED` | `S2-INSP-03:119` zero apps |
| C-2 | Its `google-services.json` **bundled into a built APK** | `NOT STARTED`, and **impossible here** | No app source, no build pipeline in the repo (§4.3) |
| C-3 | The client actually **requests a registration token** at runtime and survives permission denial | `NOT STARTED`, **un-auditable** | No client source; even SDK presence is `NOT VERIFIED` (S2-A1 §0.3) |
| C-4 | **Notifications permission granted on the device** | Schema has a slot for the *state*: `devices.notifications_granted boolean` (`g1-q8-20261029.json`) | A permission flag is not a token |
| C-5 | The token is **stored server-side, keyed to the installation** | `NOT STARTED` — **no home in the schema** (§6.3) | Verified absence |
| C-6 | A **server-side sender** with a valid credential exists and is reachable | `NOT STARTED`; `BLOCKED — APPROVAL REQUIRED` (A9+A12) | `SETUP-CHECKLIST.md:100`; no Edge Function in staging at all (`S2-INSP-03:88–92`) |
| C-7 | **Cloud Messaging / FCM v1 API** enabled and the correct project identified for sending | `NOT STARTED` — the tab has **never been opened** | `S2-INSP-03:122–124`; `MISSING — SOURCE EVIDENCE ABSENT` for sender ID |
| C-8 | Network path from the sender to FCM | `NOT STARTED` | Whether Edge Functions may make an **outbound HTTPS call at all** is unevidenced anywhere — S2-A1 §9 item 4 |

**Design rule the repository already fixes and that must not be re-litigated by a console step:** FCM is a best-effort
wake-up only, never authoritative state, and the message carries `type` + entity `id` only
(`02-architecture.md:24`, `:84`, `:105–107`). "Failure is normal… Success means 'accepted by FCM', which is not 'read by
the device'" (`:128`), and "State is written first, push is a hint. **Never push-then-write**" (`:153`); resume
reconciliation is a client-side obligation the repository states but never implements
(`SETUP-CHECKLIST.md:102`, `02-architecture.md:117`: "Uninstall: no signal from device… Detected by reconciliation, not
by FCM"). `S2-EXEC-01:149` flags exactly the governance risk: *"**A12 authorises work for a transport ('FCM')
that does not exist in this programme**"*.

### 6.2 Preconditions at the console level, spelled out

`google-services.json` requires C-1; C-1 requires the package decision (§4.4); the package decision requires an
environment strategy (`06-secrets-and-environments.md:66`); the environment strategy requires A12 plus §2 ratification
context. **There is no ordering in which a console click is the first move.** That is why §6.3 matters more than §6.1:
the blocking defect is a **schema** defect, and a schema defect cannot be approved away by an app-registration gate.

### 6.3 The schema problem — verified by me, not inherited

I parsed `docs/stage1/evidence/g1-q8-20261029.json` locally (Python, read-only):

```
TOTAL COLUMNS: 183      TABLES: 19
Columns matching push|fcm|messaging|notif|token|registration:
  devices.notifications_granted       :: boolean  null=YES
  pairing_requests.token_id           :: uuid      null=NO
Tables matching push|fcm|messaging|notif:        (none)
```

`device_pairing_tokens` (12 columns) is `id, child_user_id, code_hash, expires_at, redeemed_at, redeemed_by, status,
attempts, max_attempts, created_at, created_by, purpose`. Its own source shows what it is: `code_hash` is looked up
against a normalised pairing code, and `_shared/validation.ts` HMACs it with `PAIRING_HASH_PEPPER`
(`capture-20261030.json:165`, `:170`, `:565`). **It is a redeemable short-lived pairing artefact with an attempt counter,
not a transport registration token.** `pairing_requests.token_id` is a `uuid NOT NULL` foreign key to that artefact
(`capture-20261030.json:31` lists `redeem`/`invite` actions against it).

**Confirmed, independently: there is no push / FCM / registration-token column anywhere in the 183 captured Postgres
columns.** The architecture document reached the same conclusion before me — `02-architecture.md:175`: "*Device-token
storage for FCM | PROPOSED | Would attach to `devices`; the current 25 columns contain no token column (Q8)*" — and
`SETUP-CHECKLIST.md:99`: "*There is no `push_tokens` table and no token column on `devices` today. Adding it is a
G3-style migration decision, not a dashboard click.*" So today **FCM token storage has no home in the reconstructed
schema.** The finding is corroborated, and now re-verified from the raw capture rather than from prose.

### 6.4 What a token-registration design would need

`MISSING — SOURCE EVIDENCE ABSENT` — no such design exists in this repository beyond the two lines quoted above. What it
would have to answer, itemised so the owner can see the true size of the gate:

| # | Requirement | Why it is non-trivial here |
| --- | --- | --- |
| T-1 | A token store keyed on the **device installation**, not the user | `devices.installation_id` already exists (`g1-q8`) and is deliberately **stripped from client-facing responses** (`capture-20261030.json:82` — `device-register` "response strips `secret_hash` and `installation_id`"), so the natural key is already treated as sensitive |
| T-2 | **Cardinality: many-to-many** | One install can hold several live tokens (restore, multi-account, token refresh before the old one dies); one token can follow an install. A single nullable column on `devices` — the shape `02-architecture.md:175` sketches — is too small. A table plus a uniqueness constraint, or a device-scoped array with an explicit retention rule |
| T-3 | **Rotation and death**: mark unusable on `UNREGISTERED` / `INVALID_ARGUMENT`, stop sending, surface "device unreachable" rather than retrying | `02-architecture.md:115` already specifies the *behaviour*; nothing specifies *where the state is written* |
| T-4 | **Permission and platform gating**: only Android, only where the user has actually allowed notifications | The schema carries the *state* (`devices.notifications_granted boolean`, §6.3), but the repository documents **no rule** suppressing a push when notifications are denied — `grep -iE "permission|granted"` over `02-architecture.md` returns nothing. **`MISSING — SOURCE EVIDENCE ABSENT`**; it must be written, not assumed. `g2-apk-identity-20261030.md:23` confirms Android API 24+ only, i.e. the runtime-permission era applies |
| T-5 | A **server-side registration endpoint** — a new or extended Edge Function | Adds a 10th slug to the 9 captured (`capture-20261030.json`), so the whole Phase-E coverage set, `15-edge-function-test-plan.md` and the HTTP matrix must be re-opened. That is A7/A8 territory, and **no A7/A8 block exists in the current package** |
| T-6 | **DDL**: new table/column + RLS policy + grants | A3 (unsigned) then an A5-class patch; and staging currently has **0 tables**, so the objects do not exist to alter (`S2-EXEC-01:100` B-1; `04-risks…` B-6) |
| T-7 | **Idempotency / dedupe** for sends | `02-architecture.md:123` states the rule `(entity_type, entity_id)` and that **no FCM dedupe column exists**, so it is a design rule, not a constraint |
| T-8 | **Treat the registration token as a bearer-ish credential** | Anyone holding a registration token can push to that device. It must not enter a log, an audit payload (`audit_logs.metadata` is free JSON, `g1-q8`), a client-visible response, or this repository. `A9`'s evidence discipline — name and digest only (`approval-package-v2…:339`) — is the right pattern |
| T-9 | **Reconciliation, not reliance** | Push is best-effort; the app must reconcile on resume (`02-architecture.md:153`, `:117` — "Uninstall: no signal from device… Detected by reconciliation, not by FCM"; `SETUP-CHECKLIST.md:102`) |
| T-10 | **Environment separation** | Tokens minted against a staging project must never be delivered for production logic and vice versa — back to §4.4 |
| T-11 | **FX-18 does not block FCM; the reverse does** | Push tokens hang off identities; the `auth.users` population of staging is `NOT VERIFIED` (`S2-INSP-03:139–181`, R-42). Designing T-1 before the count is known risks building on a premise already downgraded |

**Honest bottom line:** A12 as written authorises app registration and FCM configuration. **It cannot authorise a
working push path, because the working path needs A3 + A5-class DDL + an Edge Function that does not exist + client code
that is not in this repository.** Signing A12 buys a registration and a config file, not delivery. That asymmetry should
be in front of the owner before the signature, and it is the single strongest argument for keeping A12 deferred.

---

## 7. Minimum-footprint ruling

### 7.1 The instruction, as recorded in the repository

The owner's standing instruction is captured in this repository, in substance if not in the exact sentence of the brief:

| Where | Recorded wording |
| --- | --- |
| `docs/stage2/approval-package-v2-ratification-and-forward.md:106–107` | "**Supabase Auth is the single identity authority.** Firebase is **FCM-transport-only by intent** … Firebase Auth, Firestore and Cloud Functions are **not approved requirements** and appear in no approval row here." |
| `docs/stage2/approval-package-v2…:354` (§3.7, the A12 block itself) | "Firebase Auth, Firestore and Cloud Functions are **not approved requirements** … No billing change. No production credential crossing." |
| `docs/stage2/00-stage2-execution-plan.md:245–246` | "Firebase is intended for FCM transport only; Firebase Auth, Firestore and Cloud Functions are not part of the approved architecture." |
| `docs/stage1/02-architecture.md:206` (§9 row 7) | "**Firestore / Realtime Database / Cloud Functions / Hosting / Analytics** — **Not assumed, not used, not enabled.**" |
| `docs/stage1/02-architecture.md:189` (§8) | "No new infrastructure is proposed: no Firebase Auth, no Redis, no custom server, no paid tier." |
| `docs/stage1/02-architecture.md:18` | "Firebase Auth stays **disabled** unless a written decision in a later stage says otherwise." |
| `firebase/SETUP-CHECKLIST.md:16–17` (`D4`, `D5`) | Firebase Auth "**Leave disabled**"; Analytics "**Off** — avoids extra data collection in a children's product" |
| `docs/stage2/parts/F-e6-e7.md:215` | "Firebase Auth is to remain disabled … **no further Firebase action is authorised by this part**" |
| Executed precedent | Analytics and Gemini both left **off** at creation: `S2-CREATE-01:147–152` |

**Caveat I will not paper over:** these records prohibit Firebase Auth while the new direction requires it (§5.1). The
footprint ruling below therefore has a **conditional line** (Auth), and that line is the owner's to open, not mine.

### 7.2 Ruling

**Firebase's footprint is held to the minimum the approved architecture needs.** Under the direction as newly stated,
that minimum is three items; under the plan of record as written it is one.

| In the minimum (nothing more) | Condition |
| --- | --- |
| **Android app registration + `google-services.json`** | A12 (unsigned) **and** the §4.4 package/environment decision |
| **Cloud Messaging (FCM v1) as a best-effort wake-up transport** | A12 **and** A9 **and** the §6.4 token schema, **and** an Edge Function that does not exist. Not deliverable by A12 alone |
| **Authentication** — conditional only | Only if the owner formally directs it **and** amends the five records at §7.1. Otherwise the plan-of-record answer is "no" |

**Must stay OFF — no decision has ever named any of these:**

| Product | Basis for OFF |
| --- | --- |
| **Firestore** | §7.1 (`approval-package-v2:354`, `02:206`); database layer is Supabase's assigned role. Extra hazard: an Auth/quickstart wizard may surface it and its **location is permanent** (§5.3) |
| **Realtime Database** | `02-architecture.md:206`; live updates are **Supabase Realtime on 4 tables** (`:204` row 4) |
| **Storage** | `S2-INSP-03:107–108`; no requirement in any record |
| **Cloud Functions (Firebase)** | §7.1; server-side logic is **Supabase Edge Functions** (`02-architecture.md:203` row 3) |
| **Analytics** | Owner instruction executed off (`S2-CREATE-01:151`); `SETUP-CHECKLIST.md:17` — "avoids extra data collection in a **children's product**" |
| **Crashlytics / Performance / App Distribution / ML Kit / Test Labs / Extensions / Composer** | `MISSING — SOURCE EVIDENCE ABSENT` as requirements; `02-architecture.md:206` class ruling; several of these arrive bundled with an Analytics enablement, which is why Analytics staying off is doing real work |
| **App Check** | Not required by FCM or Auth-core. `SETUP-CHECKLIST.md:60` ties it to a fingerprint the project does not own yet (demo key, §4.4). **Recommendation:** stay off, revisit only with a production signing identity |
| **Remote Config** | Policy delivery is already an owned Supabase path (`device_policies`, `apply_policy_version` — `capture-20261030.json:67`, `:95`). Two policy planes = two owners of one responsibility |
| **Hosting / App Hosting** | `S2-INSP-03:107–108`; nothing requests it |
| **Phone Auth** | §5.2 — the provider most likely to force a **plan change**; A12's own stop condition forbids it (`approval-package-v2…:357`) |
| **Legacy FCM server key** | `SETUP-CHECKLIST.md:83` "**Do not enable the legacy server key**"; `06-secrets-and-environments.md:21` "only if a legacy sender is unavoidable" |
| **Billing change (Spark → Blaze), `Upgrade`** | `S2-CREATE-01:136` upgrade CTA left unclicked; `approval-package-v2…:354` "No billing change" |
| **Gemini in Firebase** | Already off by declared deviation; re-enabling is a settings change and "settings changes remain prohibited" (`approval-package-v2…:121`) |
| **Environment type `Staging`** | **Counter-intuitive but correct:** setting it is a settings change, prohibited by the amended A12 wording, and `S2-CREATE-01:154` deliberately declined it for exactly that reason. It is listed as `OP-02` in §6 so the owner can decide, not so this audit can do it |
| **Any second Google project / reuse of the FlutterFlow demo** | `S2-INSP-02:21–22`, `:33`; `SETUP-CHECKLIST.md:7` "reusing it would mix this product's push identity with a demo forever" |

### 7.3 The credential rule that no footprint decision may relax

**No Firebase service-account credential may ever sit in a Flutter or Kotlin client.** This is already repository law, not
a new instruction: `02-architecture.md:140` — "**no Firebase Admin SDK in any client**. If a device could send, any
device could impersonate the server"; `:25–26` both apps "Holds only anon key + Firebase client config. Never
service-role, never Admin SDK"; `:135` service-account JSON is "Edge Function secrets only … not any client bundle, repo,
Firebase client config"; `06-secrets-and-environments.md:20`, `:40`; `.gitignore` blocks `service-account*.json` and
`*-firebase-adminsdk-*.json`; S2-A1 §3.5 restates it "in full force". Corollary the console work must respect:
`google-services.json` is **client config, not a secret** (`SETUP-CHECKLIST.md:77`, `06…:39`) — but repo policy keeps it
out of version control anyway, and that asymmetry must not be read as licence to paste it anywhere.

---

## 8. Every required console operation, documented as an approval request (the A12 gate package)

**Preamble.** Nothing below is authorised. Each operation is presented for a separate, explicit owner decision. The
governing text is `approval-package-v2…:349–368` (A12), whose fence at `:366` is blank;
`04-risks-rollback-approvals.md:220` records A12 as "**UNSIGNED as a forward block**"; `S2-EXEC-01:84` counts
**8 blank blocks in v2, 0 filled**; `S2-EXEC-01:132` states Phase 3.10 A12 "**NO** — needs §2 (i) + A12".
Per `approval-package-v2…:373–381` (§4 boundary table), "Does creation imply **Firebase app registration or FCM**? **No.**"

**Every row assumes §2.2's pre-flight identity record first.** All are browser-only; CLI/API/REST are prohibited outright
(`S2-EXEC-01:190–193`). Production is never a target — `parent-control-prod` / `hhqgreaoqulmfwfwarhc` is a Supabase ref
appearing in these documents only as read-only citation, and C2b as amended (C-2) makes production a **prohibition**, not
merely an unapproved option (`04-risks…:101`).

| ID | Operation | Gate | Preconditions | Expected outcome | Risk | Rollback / recovery | Evidence required |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **OP-00** | Owner instruction to perform **any** fresh console observation | Owner instruction (not A12) | This document + a named operator + a UTC window | A dated observation replacing the 2026-11-02 snapshot | Low (read-only), but **entangled with OP-01** | Close tab; nothing to undo | New `S2-INSP-0x` record, `take_snapshot` text, no screenshot claimed, §2.2 pre-flight block filled |
| **OP-01** | Dated "touch" of the consoles to address the auto-pause obligation | **Unowned** — `S2-EXEC-01:106` B-7 "Meeting it is an operational action needing owner instruction, not documentation"; `04-risks…:98` R-40 | Owner instruction naming **which** surface (Supabase holds the pause risk; Firebase's own idle behaviour is unevidenced) | Clock reset, or a dated record that it may not have been | **Unproven that a view counts** — `S2-INSP-03:237–241` "Whether a page view counts as activity … is `NOT VERIFIED`" | None needed if read-only; a *settings* touch to be unambiguous would itself breach A12 | UTC timestamp, exact URL read, header echo; never a click |
| **OP-02** | Set **environment type** `Unspecified` → `Staging` | **A12** (settings change remains prohibited — `approval-package-v2…:121`) | §2 ratification context; owner naming the value | The General page reads `Staging` | Low-irreversibility, but it is precisely the class of change the amended wording forbids; `S2-CREATE-01:154` declined it for that reason | Set back to `Unspecified` (also a settings change) | Before/after field text, UTC, operator |
| **OP-03** | Register the **Android app** (`Add app` → Android, package `com.haven.familysafety`, nickname) | **A12** | §4.4 environment/package decision **answered first**; owner-confirmed package; owner-confirmed nickname; **GROUNDED path**: `SETUP-CHECKLIST.md:72–74` | Exactly one Android app; project shows an entry in `Your apps` | **High.** "Permanent-ish and hard to undo cleanly" (`SETUP-CHECKLIST.md:15`). Wrong project = the R-43 class of error. `S2-CREATE-01:158` proves Google may rewrite identifiers | Delete the app: Project settings → Your apps — "No data loss; no tokens have been issued" (`SETUP-CHECKLIST.md:118`). App ID is not reusable | App ID (`1:…:android:…`, client config not secret), package name as read back, project ID/number echoed, list shows exactly one app |
| **OP-04** | Add certificate **SHA-1 / SHA-256** to the registered app | **A12** | Only *with* a production signing decision; the captured key is a **demo** key (`SETUP-CHECKLIST.md:42`) | Fingerprints stored against the app | Registers a throwaway identity; **F-6 field name is `INFERRED`** — verify live. Play App Signing values will differ (`g2-apk-identity…:49–50`) | Remove/edit the fingerprint | Values cited as "recorded at `g2-apk-identity-20261030.md:31`", not transcribed here |
| **OP-05** | Open Settings → **Cloud Messaging** to read sender ID / legacy-key state | **A12-adjacent — currently treated as prohibited** | Explicit owner instruction, because `S2-INSP-03:122–124` deliberately **avoided** this page: "merely visiting that tab can surface registration-token and sender-ID state, and FCM configuration is A12 work" | Sender ID + project number + legacy key state observed | Surface instability may turn a read into an activation (`S2-CREATE-01:161–164`) | Read-only; nothing to undo **provided no control is activated** | Field text; **`0` controls clicked** statement |
| **OP-06** | Enable/confirm **Cloud Messaging API (v1)** | **A12** (+ likely a Google Cloud surface, never observed in this repo) | OP-03; `SETUP-CHECKLIST.md:82` | v1 available, legacy server key **not** created | May offer a paid path; A12 stop condition "Any wizard offering a paid plan" (`approval-package-v2…:357`) | Do not disable Supabase-side anything; API disabling is out of scope and untested here | API state as read; explicit "legacy key absent" |
| **OP-07** | Open **Service accounts** / create a service account + JSON key | **A12 + A9** (A9 fence `approval-package-v2…:344` also blank) | Named credential-handling rules; the two-identity crossing decided (`02-architecture.md:227–228`) | A key exists | **Highest.** A private key is created, must be downloaded **once**, crosses between Google identities, and is a permanent leak surface | Delete the key in Google Cloud IAM; create a new one; update the dependent secret; redeploy (`SETUP-CHECKLIST.md:120`, `06…:92`) | Key **name/ID and digest only**. `S2-EXEC-01:188` stop condition: "credential in repo → stop, **treat as leaked**" |
| **OP-08** | Place that credential as a **staging Edge Function secret** | **A9** + **A12** + **method conflict** + **impossible today** | See the note below | Secret exists by name | Method conflict is unresolved: the only documented procedure is CLI (`SETUP-CHECKLIST.md:88–89`, `:95`) which is prohibited by `S2-EXEC-01:191–193`; and staging has **0 Edge Functions** (`S2-INSP-03:88–92`) and **no A7/A8 block exists** | Delete secret via dashboard secrets UI; rotate the key (OP-07 rollback) | Name + digest only; `A9` evidence rule (`approval-package-v2…:339`) |
| **OP-09** | **Console test send** to a token | **A12** | OP-03…OP-08, **plus C-2/C-3 which cannot be met** (§6.1) | A message accepted by FCM | **Cannot be completed in this programme.** "Interactive messaging tests cannot be completed until the child app integrates the SDK… Browser console access does not prove device reachability" (`SETUP-CHECKLIST.md:114`) | n/a | Record as **`NOT RUN`** with the reason; never as `PASS` |
| **OP-10** | Enable an **Auth provider** | **A12** + **documentation amendment** + owner provider decision | §5.1 conflict resolved; §5.2 provider chosen by the owner | A sign-in method exists | **The largest irreversible shared state in this document** (§5.3): second credential store, orphanable records, possible Firestore/plan side effects, external consent screen | Providers can be switched off; **created users cannot be un-created**; consent screen publication is external | Provider list state before/after; **zero users created**; explicit "Firestore not created" confirmation |
| **OP-11** | Re-confirm **plan tier** (Spark) | **A12** (requires a Settings-menu pointer action, since `/settings/usage` and `/settings/plan` redirect — `S2-INSP-03:130–135`) | OP-00 | Gap closed | Low; but the click instability makes accidental activation plausible | Read-only | The exact string read; the number of controls activated |
| **OP-12** | Review **Users and permissions** | **A12** (page visit only) | OP-00; §1.1 PII handling agreed first | Known list of who can act on the project | May display account identifiers → **PII exposure into a new record** | Read-only | **Roles and counts only. No addresses, no names.** (§1.1) |
| **OP-13** | Reconcile Firebase state into the plan of record | Documentation pass, **not A12** | One of OP-00…OP-12 has produced a dated record | `02-architecture.md:173–176`, `S2-EXEC-01 §1.5`, `00:245` updated coherently | Stale status lines are an observed defect class — R-41 (`04-risks…:99`) | Documentation revert | Dated addendum, append-only, nothing deleted |

### 8.1 Method-conflict disclosure (OP-08) — do not let this reach execution unresolved

The repository contains a **complete, careful, and unexecutable** FCM credential runbook at `SETUP-CHECKLIST.md:84–95`.
It is unexecutable because every load-bearing line in it is a CLI command (`supabase link`, `supabase secrets set
--env-file`, `supabase secrets list`), and the owner's standing rule bans CLI, terminal, PowerShell, CMD, REST, curl,
Postman, DevTools and "direct DB connection or workaround" for these two platforms (`S2-EXEC-01:190–193`). I flag this
rather than quietly restate the checklist as if it were a plan. **A12's package must name a browser-only credential
placement path, or admit that none is documented and defer OP-08.**

### 8.2 Ordering this audit recommends

`OP-00 → OP-11 → OP-12 → OP-01 →` **STOP for the owner on §4.4 (package/environment) and §5.1 (Auth direction)** `→ OP-02
→ OP-03 → OP-05 → OP-04 → OP-06 →` **STOP, because §6.4 (token schema) is A3/A5/Edge work, not A12 work** `→ OP-07 →
OP-08 → OP-09`. **OP-10 sits outside the chain entirely** until §5.1 is resolved. **This ordering grants nothing.**

---

## 9. Open questions for the owner

| # | Question | Blocks | Gate |
| --- | --- | --- | --- |
| Q-1 | **Does Firebase own Authentication?** The plan of record says no in five places (§7.1) and the A12 signature text asks the owner to *acknowledge* FCM-only (`approval-package-v2…:363`). Do you amend those records first, or sign A12 as drafted? | Every §5 provider decision; the meaning of A12 itself | Owner decision + documentation pass; A12 unchanged is a **contradiction**, not an approval |
| Q-2 | **Which sign-in provider**, if Auth is in scope — email/password, Google, both? §5.2 shows this is a custody-and-revocation decision, not a preference. | OP-10, and S2-A1 `O-1` | A12 + a new requirement record |
| Q-3 | **Does the one-package-one-config problem get solved by distinct `applicationId` suffixes, per-flavor config, or a single project?** `06-secrets-and-environments.md:66` calls the suffix "a user-visible decision". | **OP-03 blocks behind this** | A12 + product decision |
| Q-4 | **Which Google identity may hold the Firebase project, and is a credential ever permitted to cross between the two identities?** `02-architecture.md:227–228` does not authorise it. S2-A1 `O-10`. | OP-07, OP-08, and the whole V-1 verifier option | A12 + A9 + an ownership decision |
| Q-5 | **Where do FCM registration tokens live?** No column exists (§6.3). A `devices` column is the wrong shape (§6.4 T-2). | OP-06…OP-09 — i.e. all of push | A3 + A5-class DDL, **not A12** |
| Q-6 | **Is a push path wanted at all**, given "FCM does not exist in this programme" (`S2-EXEC-01:149` F-7) and Supabase Realtime already covers live updates (`02-architecture.md:204`)? | The entire A12 package | A12 / owner scope |
| Q-7 | **Who owns the auto-pause touch**, and on which surface? The date (2026-11-06) has passed relative to this document's date, and no touch is recorded after `S2-INSP-03`'s 2026-11-02T07:16Z. | OP-00/OP-01; every later console action | Owner instruction; **unowned today** (`S2-EXEC-01:106` B-7) |
| Q-8 | **Browser-only credential placement?** §8.1. The documented method is prohibited; no substitute is recorded. | OP-08 | A9 + a method decision |
| Q-9 | **Is `haven-staging-46822` the intended Firebase home for the shipped package**, or should a differently-scoped project be created? Note Firebase project creation is *already* permitted under owner instruction, but a **new** project would be a new A12-class decision. | OP-03 and everything after | Owner decision |
| Q-10 | **Should the environment type be labelled `Staging`?** Attractive for safety, but it is a prohibited settings change today (OP-02, `S2-CREATE-01:154`). | Weakens §2.1 H-8 | A12 settings clause |
| Q-11 | **PII remediation of the evidence set** (§1.1) — replace literal account identifiers with opaque handles via a dated addendum? | Nothing operationally; does affect every future identity citation | Documentation pass |
| Q-12 | **Is App Check in scope?** It keys to a certificate the programme does not own yet, and the brief does not list it in the minimum. | OP-04 | A12 (recommend: defer) |

---

## 10. What this audit could not determine, and why

1. **Anything happening after 2026-11-02T07:16Z.** No browser, by instruction. The shell's continued existence, its
   identity values, its app list and its plan are all "last seen" facts, not current facts.
2. **The plan tier.** Spark was observed at creation (`S2-CREATE-01:133–136`) and **not re-confirmed** on the later pass,
   because `/settings/usage` and `/settings/plan` both redirect to `/overview` (`S2-INSP-03:130–135`). Whether the
   project is still no-cost is `MISSING — SOURCE EVIDENCE ABSENT`.
3. **Any Firebase product's internal configuration state** — Cloud Messaging sender ID, service accounts, Auth provider
   list, Integrations, Data privacy, Users and permissions. The settings tab **inventory** is evidenced
   (`S2-INSP-03:121–122`), but only `General` was ever opened (`:122`–`:125`). **Absence from the left navigation is
   strong evidence that nothing is enabled; it is not evidence of what each unopened tab contains.**
4. **Whether another Google account owns a Haven Firebase project.** Explicitly left `NOT VERIFIED` at
   `S2-INSP-02:36` — "requires switching accounts, not permitted here". Still unresolved; it feeds Q-4/Q-9.
5. **Whether the product requires Firebase Auth at all.** The direction is stated in the brief but not in any repository
   requirement document; the plan of record says the opposite (§5.1/§7.1). I can cite the conflict, not dissolve it.
6. **Exact console field labels for registration.** Grounded fields are limited to those named in
   `SETUP-CHECKLIST.md:72–77`. **SHA-256 as a console input, App Check/ML Kit wizard steps, and the Auth provider list
   layout are `INFERRED — verify in console at execution time`** (§4.1 F-6/F-9, §5.2).
7. **Whether the shipped APKs contain the Firebase/FCM SDK.** No source in the repo (§4.3); the binaries were inspected
   only for package/capacitor/certificate identity (`g2-apk-identity…:13`). Client behaviour, token handling and
   refresh are outside this audit's reach — as S2-A1 §9 item 1 also concludes.
8. **Whether a Supabase Edge Function can call FCM at all** — outbound egress from the Edge runtime has never been
   evidenced in this repository (S2-A1 §9 item 4), and staging has 0 deployed functions (`S2-INSP-03:88–92`).
9. **Whether the staging `auth.users` table is empty** (FX-18/R-42, `S2-INSP-03:139–181`). Not a Firebase question
   directly, but push tokens hang off identities, so the answer conditions Q-5.
10. **Screenshots.** None exist for any pass, programme-wide (`S2-CREATE-01:23–29`, `S2-INSP-03:213`). No A12 step can be
    evidenced visually, only by accessibility-tree text — a limitation to disclose **before** signing, not after.
11. **Provenance.** Zero commits, everything untracked (`S2-EXEC-01:19–20`, `:41–44`); hashes bind a file to a moment, not
    to a signature.

### 10.1 Conflicts with S2-A1 — disclosed, not harmonised

`docs/stage2/S2-A1-auth-architecture.md` is a stronger document on the identity/schema side than this one, and we agree
on the load-bearing facts: no app source (`S2-A1 §0.3`, independently re-verified at §4.3), no push-token column
(`A-20`, re-verified at §6.3), no Firebase verifier (`§0.4`), the four prohibitions (`§5.4 A-18`), the two-identity
boundary (`O-10`), and that A12 alone buys a registration and not a delivery path. Where I keep my own framing rather
than deferring silently:

- **Scope of "console".** S2-A1 treats enabling the `[auth.third_party.firebase]` bridge as `V-3`, an A2′(b)-class
  Supabase-settings change. I add the Firebase-side hazard (§5.3): the same decision may drag Firestore/plan state behind
  it, which no Supabase-side row covers.
- **A12's own acknowledgement text.** S2-A1 records the four prohibitions; I flag the narrower and sharper problem at
  §5.1: `approval-package-v2…:363` asks the owner to sign the sentence *"Firebase is FCM-transport-only"* **inside the
  very block they would sign to open Firebase**. That is a signature-integrity issue, not just a documentation conflict.
- **The runbook is prohibited.** S2-A1 quotes `SETUP-CHECKLIST §4–§5` as the credential-placement pattern. I state that
  the pattern is **CLI** and therefore forbidden by `S2-EXEC-01:190–193` — `OP-08` / §8.1 / Q-8.
- **OP-05 is not a free read.** S2-A1 does not address tab-visit risk; `S2-INSP-03:122–124` treats opening Cloud
  Messaging as an A12 act. I adopt that stricter reading.
- **Registration ordering.** I put §4.4's package/environment decision **ahead of** app registration, since
  `approval-package-v2…:355` already requires "a recorded G2 decision" as an A12 precondition and G2 (`00-status-register.md:5`,
  `:98` B9) has never been decided.

---

## 11. Verdict

**`FIREBASE CONSOLE AUDIT COMPLETE — NOTHING CONFIGURABLE EXISTS TO AUDIT — A12 REMAINS BLOCKED — APPROVAL REQUIRED`.**

The evidence supports exactly one strong claim: **`haven-staging-46822` is an empty shell** — zero apps, zero products,
zero credentials, created outside its gate and never configured (`S2-INSP-03:107–119`, `:195–197`;
`S2-CREATE-01:156–157`). Everything else §2–§8 does is prepare the owner to change that deliberately, and record what
cannot yet be known.

**Three facts should be in front of the owner before any Firebase signature:**
1. **A12 is not a push-path approval.** Signing it registers an app and a config file while leaving the transport
   unbuildable, because the schema has no place for a token (§6.3, verified from 183 columns) and no sender exists (§6.1
   C-5/C-6/C-8).
2. **A12's own text asks the owner to sign a premise the new direction rejects** (§5.1). That contradiction is the file
   to fix before the fence at `approval-package-v2…:366` is filled.
3. **App registration is the least reversible item in the package** and it sits behind an unanswered user-visible
   decision — one package name, one config, one environment (§4.4, `06-secrets-and-environments.md:66`).

**Files created or modified by this pass:** `docs/stage2/S2-A2-firebase-console-audit.md` (this file) **only.** Nothing else in
`docs/`, `firebase/`, `supabase/` or the repository root was touched. **No browser, dashboard, console, CLI, REST, API,
SQL, Git write, or cloud write of any kind occurred. No production surface — `parent-control-prod` /
`hhqgreaoqulmfwfwarhc` — was contacted; it appears here only as read-only citation. No secret, key, token, JWT,
connection string, email address, account name or other PII is reproduced in this document.**
