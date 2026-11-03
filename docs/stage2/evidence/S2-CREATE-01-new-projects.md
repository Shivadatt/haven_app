# S2-CREATE-01 — Creation of the staging Supabase project and the staging Firebase project

**Record ID:** S2-CREATE-01
**Date:** 2026-10-30. Dashboard charts rendered `Oct 30, 5:25pm`–`Oct 30, 6:25pm` in local display; no UTC
conversion was recorded at capture time, so sub-day ordering is by snapshot sequence, not by clock.
**Operator:** agent session (browser UI only)
**Class:** **OPERATIONAL — create only.** Two projects were created. No schema, no secret, no app registration, no
credential exported, no production object touched, no SQL executed. Beyond the creation itself, **two wizard settings
were moved off default** — Google Analytics off as instructed, and Gemini AI assistance off as a disclosed
least-privilege deviation (§4.1); nothing else was changed.
**Approval reference:** owner instruction "create new project on both supabase and firebase … not use parent-control-prod"
plus three recorded owner decisions (§1). This record **is not a signed A0 (G3 method) or A2 (staging creation)** — the
owner's chat instruction is an **instruction, not an approval**, and the A0/A2 package was never signed (A0 has never
been approved by anyone) — and it is **not** A3 (schema load), A5 (patch apply), A9 (secrets) or A12 (Firebase/FCM)
approval either; it grants none of them.
**Ratification status (2026-11-02):** the executed creation is recorded as `AWAITING RETROSPECTIVE RATIFICATION` in
[approval-package-v2-ratification-and-forward.md](../approval-package-v2-ratification-and-forward.md) §2 (reconciled in
[04](../04-risks-rollback-approvals.md) §3.1; the Firebase creation exceeds the A12 prohibition — risks R-36/R-37), and
this record remains the evidence for it.
**Auto-pause deadline:** the Free 7-day idle clock started with this creation; the constraint is a dated dashboard
touch on or before **2026-11-06**; **no UTC start timestamp was recorded** (§4.8, R-40).

**SCREENSHOT EVIDENCE: `NOT VERIFIED` as platform records.** `take_screenshot` returns
`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE … viewport=530x554, visible=true, attached=true, visibilityState=hidden`.
Evidence below is accessibility-tree text captured by `take_snapshot`, each excerpt attributable to the URL in its
heading. No image of either console existed at capture time. The owner has since supplied two captures of the in-app
browser — the Supabase staging home page and the Firebase `haven-staging` overview — which corroborate several named
fields above (§2.2), but they are screen captures of the app window, **not platform records**: they carry no UTC
stamp, and the Firebase one shows a truncated URL so no project ID is visible. No platform audit log is claimed.

---

## 1. Owner decisions this record executes

| # | Decision | Owner's answer | Effect here |
| --- | --- | --- | --- |
| 1 | Scope of the Supabase project | **"Shell only"** | Empty project; no sentinel row, no settings checklist, no secrets, no schema |
| 2 | Database password custody | **"You type it yourself"** | Password handled in the browser by the owner; no value read, transcribed or stored by the agent |
| 3 | Firebase project | **"Create `haven-staging`, Analytics off"** | Display name `haven-staging`; Google Analytics disabled in the wizard |

Nothing outside these three was inferred. Where the wizard presented an extra choice the owner had not named, the
least-privilege option was taken and the deviation is declared in §4.

---

## 2. Supabase — `parent-control-staging`

**URL:** `https://supabase.com/dashboard/project/dzonzgngwxclhfnvxtvu`
**Project URL:** `https://dzonzgngwxclhfnvxtvu.supabase.co`
**Project ref:** `dzonzgngwxclhfnvxtvu`
**Organisation:** `spg7753@gmail.com's Org` (`symqztrmaziuwdibcfrq`), Free plan

### 2.1 Settings page (`/settings/general`) — verbatim

| Field | Value |
| --- | --- |
| Project name | `parent-control-staging` |
| Project ID (read-only) | `dzonzgngwxclhfnvxtvu` |
| Project region (read-only) | `ap-northeast-2` — "Northeast Asia (Seoul)" |
| Members | "All 1 organization members can access this project" — `spg7753@gmail.com`, role `Owner` |
| Auth version | `2.197.0` |
| PostgREST version | `14.18` |
| Postgres version | `17.11.0.003` (upgrade to `17.11.0.011` offered) |

### 2.2 Project home (`/project/dzonzgngwxclhfnvxtvu`) — verbatim

`STATUS Healthy` · `COMPUTE SIZE NANO` · `GITHUB No repository connected` · `RECENT BRANCH No branches` ·
`LAST MIGRATION No migrations` · `LAST BACKUP No backups` · `EDGE FUNCTIONS 0` · `Advisor found no issues` —
`No security or performance issues found`.

### 2.3 Database tables (`/database/tables`) — verbatim

Schema selector `public`; `No tables created yet` / `0 tables`. An unaccepted notice reads
"Automatically enable Row Level Security (RLS) on new tables" with a `Set up trigger` button — **not** actioned.

### 2.4 Org list (`/org/symqztrmaziuwdibcfrq`) — verbatim

Two project cards only:

| Card | Project ID | Region | Compute |
| --- | --- | --- | --- |
| `parent-control-prod` | `hhqgreaoqulmfwfwarhc` | `ap-northeast-2` | `NANO` |
| `parent-control-staging` | `dzonzgngwxclhfnvxtvu` | `ap-northeast-2` | `NANO` |

Header: `spg7753@gmail.com's Org` `Free` `Plan` `·` `2` `projects`; `/dashboard/projects` independently renders
`Free Plan · 2 projects`. The **last Free slot is now consumed** — this matches the prediction in
[01-staging-project-proposal.md](../01-staging-project-proposal.md) §5.1 and now leaves no room for a `dev` project
without a paid plan or deleting a project.

### 2.5 Org usage meter observed at the same time (material correction)

`Egress 0.14 / 5 GB` · `Database size 32 / 500 MB` · `Monthly active users 10 / 50,000` · `File storage 0 / 1 GB` ·
`Log Ingestion 0.20 / 1 GB` · `Log Query 44.8 / 100 GB`.

These are the figures in [S2-INSP-01](S2-INSP-01-supabase-org-slots.md), **not** the `0.17 GB / 1 GB` and
`0.12 GB / 5 GB` printed in [01-staging-project-proposal.md](../01-staging-project-proposal.md) §5. That table is
therefore wrong by observation, independently of the audit's arithmetic finding. Recorded here; **not edited** —
the proposal is a document under review and changing it is the owner's call.

### 2.6 Creation parameters as submitted

| Parameter | Value |
| --- | --- |
| Name | `parent-control-staging` |
| Region | `Northeast Asia (Seoul)` / `ap-northeast-2` — reachable only via "Need a specific region?" |
| Plan | Free / NANO |
| Organisation | existing `symqztrmaziuwdibcfrq` |
| "Automatically expose new tables" | **unchecked** — re-set immediately before submit after the control re-rendered back to checked |
| Database password | owner-supplied, browser-side; **never read, logged or stored by the agent**; no value appears in this repository, this record or the session transcript |

Custody of the password rests with the owner. If it was also written anywhere outside the browser during creation,
that copy is unmanaged by this programme and should be re-set (A9) before any staging connection is used.

---

## 3. Firebase — `haven-staging`

**URL:** `https://console.firebase.google.com/project/haven-staging-46822/overview`
**Project ID:** `haven-staging-46822`
**Project number:** `381273275501`
**Account:** `Shiwa Goswa!i (shiwa2172000@gmail.com)` — unchanged, not switched

### 3.1 Project settings (`/settings/general`) — verbatim

| Field | Value |
| --- | --- |
| Project name | `haven-staging` |
| Project ID | `haven-staging-46822` |
| Project number | `381273275501` |
| Environment type | `Unspecified` — **not changed** |
| Your apps | `There are no apps in your project` |

### 3.2 Usage and billing (`/usage`) — verbatim

`Project cost Current billing plan: Spark` · `No-cost` · `Your project hasn't used any billable Firebase services
recently.` A `Upgrade` call-to-action is displayed and was **not** clicked.

### 3.3 Project list (`console.firebase.google.com/`) — verbatim

`1 – 2 of 2`: `haven-staging` (`haven-staging-46822`) and `FlutterFlowWIthFIreBase`
(`flutter-flow-w-ith-f-ir-6592ib`). The pre-existing FlutterFlow demo was not opened, renamed or modified.

---

## 4. Deviations and observations that must travel with this record

1. **The wizard has a Gemini step the plan did not anticipate.** Step order was: name → **"AI assistance for your
   Firebase project"** (`Enable Gemini in Firebase`, default **on**) → Analytics → create. The owner's decision named
   Analytics only, so the least-privilege option was taken: **Gemini switched off**, and the switched-off state was
   confirmed (`checked="false"`) before advancing. This is an unrequested setting change, recorded rather than hidden.
2. **Analytics off as instructed.** Default was `checked="true"`; after the click the switch read `checked="false"`
   and the primary button changed from `Continue` to `Create project` — the button-state change is what confirms the
   choice registered.
3. **Environment type left `Unspecified`.** `Staging` is offered. Setting it is a settings change outside the
   approved scope, so it was left alone; recommend it as a follow-up.
4. **No app registered.** No Android/iOS/Web/Flutter app, therefore no `google-services.json`, no `GoogleService-Info.plist`,
   no service-account key, no FCM config. **Zero Firebase credentials were created or copied.**
5. **Firebase project IDs are global and immutable.** `haven-staging` was rejected as an exact ID, so Google
   generated `haven-staging-46822`. Display name and ID now differ; both are recorded so later documents do not
   guess.
6. **Browser surface instability is a live operational risk.** Pointer actions on the Firebase tab intermittently fail
   with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE` (`visibilityState=hidden`) and succeed on retry; `Enter` does nothing on
   these Material buttons while `Space` activates them. Any future console run must budget for retries and must not
   use DevTools, script injection or direct API calls to work around it — none were used here.
7. **A transient "We are investigating a technical issue" banner was seen on the Supabase dashboard earlier in this
   session.** It was not present on the pages captured in §2, and no creation step failed because of it. Recorded
   because it is the kind of platform condition that must be disclosed if a later step misbehaves.
8. **Auto-pause clock is now running.** The Free 7-day idle timer starts from creation on both surfaces. Neither
   project has been paused; the coordinated-window requirement (R-30) now has a hard start date.

---

## 5. What this record does **not** claim

| Claim | Status |
| --- | --- |
| Supabase staging project exists, named, regioned, on Free | `VERIFIED` — §2.1, §2.4 |
| Supabase project is an empty shell (0 tables, 0 functions, 0 migrations) | `VERIFIED` for tables/migrations/Edge Functions — §2.2, §2.3 |
| Supabase staging is isolated from production | `VERIFIED` — distinct ref, distinct URL, production not navigated to beyond the list card |
| Sentinel `private.s2_environment` exists | `NOT CREATED` — deliberately out of scope under "shell only" |
| Staging secrets exist | `NOT CREATED` |
| Schema (G3) loaded into staging | `NOT DONE` — requires A3 |
| Firebase project exists on Spark, Analytics off | `VERIFIED` — §3.1, §3.2 |
| Firebase Gemini assistance disabled | `VERIFIED` — switch read `false` before create |
| Firebase apps / credentials exist | `VERIFIED` — none |
| Production Supabase schema, data, config or secrets changed | `VERIFIED` — none; no production page beyond the org list was opened |
| Screenshot of any console | `NOT VERIFIED` as platform records — none existed at capture time; the owner's two later in-app-browser captures corroborate named fields but are not platform records (§header) |
| Whether the database password exists outside the owner's control | `NOT VERIFIED` — owner's to confirm (§2.6) |

## 6. Production untouched — statement

`parent-control-prod` (`hhqgreaoqulmfwfwarhc`) appears in this record only as a name in the org list and as a project
card. No SQL editor was opened against it, no table data was read, no Edge Function, secret, setting, user, family,
device or telemetry record was read or written, and no pause, delete or plan change was initiated on it. The
Firebase action was confined to the new `haven-staging-46822` project; the pre-existing FlutterFlow project was left
exactly as found.
