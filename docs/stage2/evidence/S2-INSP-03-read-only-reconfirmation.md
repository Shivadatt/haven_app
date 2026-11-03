# S2-INSP-03 — Read-only re-confirmation of both staging shells

**Record ID:** S2-INSP-03
**Executed:** 2026-11-02T07:16Z (single continuous browser session, 07:16Z–07:19Z)
**Operator:** agent session, Qoder in-app browser, signed-in sessions carried over from S2-CREATE-01.
**Authority basis:** owner instruction accompanying S2-DOC-02 — "use browser access on supabase and firebase, not
use cli". The S2-DOC-02 brief itself restricts the pass to documentation changes. The conflict was resolved
**narrowly**: page views only, addressed by URL, with **zero clicks on any state-changing control**. Everything the
brief forbids — creation, deletion, pause/resume, SQL, patch application, settings change, secrets, app registration,
deployment, CLI, REST — did not occur. See §6 for the one control that was clicked and why.
**Purpose:** re-confirm, on a dated record, that both shells exist, are unpaused, and are empty; and establish whether
the S2-DOC-02 status claims survive contact with the live consoles.

**SCOPE CONSTRAINT ISSUED DURING THIS PASS (owner, 2026-11-02):** on Supabase, use `parent-control-staging`
(`dzonzgngwxclhfnvxtvu`) — **no other project**. Recorded as **R-43** in [04](../04-risks-rollback-approvals.md) §1 and
in [README](../README.md). It binds from that moment. The single production surface touched earlier in this pass — the
Auth → Users **aggregate total** read at §3 line-by-line to characterise the staging figure — was opened under the
prior instruction set and is disclosed here rather than deleted, because deleting an observation would itself be an
accuracy failure (R-41). No production control was activated, no user row, email, key or setting was read or
transcribed, nothing was written, and **production will not be opened again under this constraint.** All subsequent
Supabase access in this programme is staging-ref-only.

---

## 1. Supabase — observed, verbatim

### 1.1 Project home `https://supabase.com/dashboard/project/dzonzgngwxclhfnvxtvu`

| Panel | Observed string |
| --- | --- |
| Title / header | `parent-control-staging main` |
| Project URL | `https://dzonzgngwxclhfnvxtvu.supabase.co` |
| STATUS | **`Healthy`** |
| COMPUTE SIZE | `NANO` |
| GITHUB | `No repository connected` |
| RECENT BRANCH | `No branches` |
| LAST MIGRATION | **`No migrations`** |
| LAST BACKUP | **`No backups`** |
| Infrastructure diagram node | `Primary Database` · `Northeast Asia (Seoul)` · `ap-northeast-2` · `Nano` |
| Database meters | `CPU 2% · Disk 13% · RAM 54% · 6/60 conns` |
| Requests carousel | `9` `Total Requests`, `100.0` `%` `Success Rate`, window `Nov 2, 11:41am` → `Nov 2, 12:41pm` |
| Service panels | `API GATEWAY` 5 WARNINGS / 0 ERRORS · `STORAGE` 2 / 0 · `REALTIME` 2 / 0 · `POSTGRES` 0 / 0 · `EDGE FUNCTIONS` 0 / 0 · `AUTH` 0 / 0 |
| Advisor | `Advisor found no issues` — `No security or performance issues found` |

Reading notes:
- `No migrations` + `No backups` corroborate an unloaded project: nothing has been restored or migrated into it.
- The WARNINGS figures are **log-line counts** over the trailing hour, not Advisor findings; the Advisor panel
  separately reports none. Do not record them as "5 API gateway problems".
- The `9 Total Requests` in the trailing hour is attributable to this and the previous dashboard session, not to
  application traffic — there is no client pointed at this project.
- Meters (`RAM 54%`, `Disk 13%`) are Nano-baseline occupancy on an empty database, not usage growth. They are recorded
  for completeness and carry no parity meaning.

### 1.2 Organizations list `https://supabase.com/dashboard/organizations`

`spg7753@gmail.com's Org` · `Free` `Plan` · `2 projects`. Organization id in the link target: `symqztrmaziuwdibcfrq`.

### 1.3 Organization projects `https://supabase.com/dashboard/org/symqztrmaziuwdibcfrq`

Exactly two project cards, both `ap-northeast-2`, both `NANO`:

| Card | Project ref (from the card link) |
| --- | --- |
| `parent-control-prod` | `hhqgreaoqulmfwfwarhc` |
| `parent-control-staging` | `dzonzgngwxclhfnvxtvu` |

`Free plan usage` — `Current billing cycle`:

| Meter | Observed | Against |
| --- | --- | --- |
| Egress | 0.14 | 5 GB |
| Database size | 32 | 500 MB |
| Monthly active users | 10 | 50,000 |
| File storage | 0 | 1 GB |
| Log Ingestion | 0.20 | 1 GB |
| Log Query | **44.8** | **100 GB** |

Slot arithmetic: the plan allows 2 active projects per organisation and 2 are listed. **2 active, 2 used, 0
remaining.** This re-confirms the S2-DOC-02 correction and the `R-38` entry (zero slot headroom). Every usage figure
matches `S2-CREATE-01` §2.5 and `approval-package-v2` §43 exactly, and matches the corrected rows in
[01-staging-project-proposal.md](../01-staging-project-proposal.md). No drift since creation.

### 1.4 Staging tables `.../dzonzgngwxclhfnvxtvu/database/tables`

Schema selector: `public`. Body: `No tables created yet` · `There are no tables found in the schema "public"` ·
**`0 tables`**.

### 1.5 Staging Edge Functions `.../dzonzgngwxclhfnvxtvu/functions`

Onboarding state only (`DEPLOY YOUR FIRST EDGE FUNCTION`, template gallery). Toast notification:
**`Edge function cannot be found in your project`**. Confirms **0 deployed functions**, so G5-E remains correctly
blocked.

### 1.6 Staging Auth users `.../dzonzgngwxclhfnvxtvu/auth/users` — CONTRADICTION, see §3

Footer: **`Total:` `10` `user` `s` `(estimated)`**. The results grid element was present and empty in both a standard
and a verbose snapshot, and again after a full re-navigation: **zero user rows rendered**.

---

## 2. Firebase — observed, verbatim

### 2.1 Overview `https://console.firebase.google.com/project/haven-staging-46822/overview`

`haven-staging` · `Add app` button present · `Hello, Shiwa` · `Welcome to your Firebase project!` ·
`Gemini can give you suggestions for Firebase services and solutions for your app` · `Next steps with Gemini`.
Left product navigation contains **only** `Project Overview` and `Settings` — no Analytics, Auth, Firestore, RTDB,
Storage, Messaging, Hosting or App Hosting entry is present, i.e. **no Firebase product is enabled**.
Account chip: `Shiwa Goswa!i (shiwa2172000@gmail.com), Google membership`. Alerts chip: `0 unread alerts`.

### 2.2 Project settings → General `.../settings/general`

| Field | Observed |
| --- | --- |
| Project name | `haven-staging` |
| Project ID | `haven-staging-46822` |
| Project number | `381273275501` |
| Environment type | `Unspecified` |
| Your apps | **`There are no apps in your project`** |

Settings tabs offered: `General`, `Cloud Messaging`, `Integrations`, `Service accounts`, `Data privacy`,
`Users and permissions`, `Alerts`. **Only `General` was opened.** `Cloud Messaging` was deliberately not opened —
merely visiting that tab can surface registration-token and sender-ID state, and FCM configuration is A12 work.
`Service accounts` was not opened, for the same reason: it is the credential surface and A9/A12 territory.
`Delete project` was visible and not clicked.

These four values match `S2-CREATE-01` §3 exactly. Zero apps, therefore zero `google-services.json` /
`GoogleService-Info.plist` / web configs exist — the "no credentials, no FCM" claim survives.

### 2.3 Plan page — NOT RE-CONFIRMED

`.../settings/usage` and `.../settings/plan` both **redirected back to `/overview`**; the billing/plan surface is not
directly addressable in this console build, and reaching it requires clicking into the Settings menu (a pointer action
that, per §5, was unavailable). **Firebase plan = Spark is therefore `NOT VERIFIED` in this pass.** It rests on
`S2-CREATE-01` §3, where it was observed during creation. This is a gap, not a contradiction.

---

## 3. FX-18 — the staging auth-user total contradicts "no auth users"

**Observation.** The staging Auth users page reports `Total: 10 users (estimated)` while rendering zero rows.

**Control observation.** Production (`hhqgreaoqulmfwfwarhc`) at the same moment reports `Total: 8 users` — **without**
the `(estimated)` qualifier — consistent with Stage 1's 8 profiles. No production user row, email or identifier was
transcribed into this record; only the aggregate total was read, and only because the comparison was needed to
characterise the staging figure.

**Why this matters.** Four current documents assert that staging holds no identities —
[01-staging-project-proposal.md](../01-staging-project-proposal.md):191 (`NOT CONFIGURED — no auth users, no
sign-ups run`), the S2-DOC-02 empty-shell statement in [README.md](../README.md), `approval-package-v2` §1, and the
G5-S blocker text in [05-validation-plan.md](../05-validation-plan.md). If staging genuinely holds ~10 `auth.users`
rows, the clean-shell premise is wrong, and it is not cosmetic: P01's pre-check cardinality and the corrected
`4 rows total` grant expectation, the sentinel gate, and every "0 rows, so a wrong-project run is impossible"
argument in the patch set are conditioned on emptiness.

**Why it is probably a display artefact — and why that is not a verdict.** The two numbers came from different code
paths (exact vs estimated), so they are not like-for-like. Independently, the org `Monthly active users` meter reads
**10** here, read **10** at Stage 1 ([01-baseline-inventory.md](../../stage1/01-baseline-inventory.md):24) *before
staging existed*, and has not moved since staging was created — a project that acquired 10 real auth users without a
single sign-up or MAU change is not a coherent story. The two live hypotheses are therefore (a) a stale `reltuples`
-style estimate carried from the project template database, or (b) an organisation-level figure surfaced into a
project-scoped page. Neither is verified.

**Classification.** The claim "staging contains no `auth.users` rows" is downgraded from `VERIFIED` to
**`NOT VERIFIED — dashboard total contradicts, unresolved`**. The claim "no test principals were *created by this
programme*" remains `VERIFIED` on the strength of `S2-CREATE-01` §2/§4 (no `Add user` action ever occurred) and the
empty list body.

**How to close it — and why it is not closed here.** One statement resolves it: `select count(*) from auth.users;`
against **staging**. That is a staging touch executed in the SQL Editor. No signed approval covers it: A1 is scoped to
*production catalogue reads*, A3 is *schema load*, A2′ as drafted is *sentinel plus approved settings*. So it needs an
explicit owner instruction or a scope line added to A2′. **It was not run during this pass**, and the browser was not
used to reach any endpoint that would have answered it.

> **Owner decision on scope, recorded 2026-11-02 (decision B-3, option A — correction C-4).** The paragraph above stands as
> written and is not edited; this is an annotation, not a new approval. The owner decided that the count belongs **inside
> A3's window** — as its first statement, with a non-zero answer stopping the load ([approval-package-v2
> §3.4](../approval-package-v2-ratification-and-forward.md)) — rather than under A1 or as an A2′ scope line. Two
> consequences: **the read is still unauthorised, because A3 is UNSIGNED**, so this gap remains open and `NOT VERIFIED`;
> and the alternative route named above ("A1") is now closed anyway, since **A1 is `INOPERATIVE`** under the owner's
> staging-only absolute (C-2). Nothing was run in the S2-EXEC-03 pass either: it is a documentation-only task.

---

## 4. Posture confirmation

| Claim | Status after this pass |
| --- | --- |
| Supabase staging shell exists, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO | `VERIFIED` (re-confirmed) |
| Supabase staging is **not paused** (`STATUS Healthy`) | `VERIFIED` (re-confirmed) |
| Supabase staging has no schema loaded (0 tables in `public`, `No migrations`) | `VERIFIED` (re-confirmed) |
| Supabase staging has no Edge Functions deployed | `VERIFIED` (re-confirmed) |
| Supabase staging has no application rows | `VERIFIED` for `public` (0 tables); `NOT VERIFIED` for `auth.users` (§3) |
| Supabase staging has a wrong-project sentinel | `VERIFIED` — it does **not** exist (0 tables; never created) |
| Firebase shell exists, `haven-staging-46822`, number `381273275501`, environment type `Unspecified` | `VERIFIED` (re-confirmed) |
| Firebase has zero apps and therefore zero credentials | `VERIFIED` (re-confirmed) |
| Firebase has zero products enabled | `VERIFIED` (re-confirmed from product navigation) |
| Firebase plan is Spark | `NOT VERIFIED` this pass (§2.3); rests on `S2-CREATE-01` §3 |
| Production was not modified | `VERIFIED` — one read-only page (auth users total), no edit, no control clicked |
| Screenshots exist for this pass | `NOT VERIFIED` — capture unavailable (§5) |
| This pass reset the Free-plan 7-day auto-pause clock | `NOT VERIFIED` (§7) |

---

## 5. Tooling limitations during this pass

- Pointer actions failed with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE: In-app Browser did not provide an attached surface
  with a positive viewport within 1000ms (operation=click, viewport=524x553, visible=false, attached=false,
  cdpAttached=true, visibilityState=hidden)`. This is the same instability recorded in `S2-CREATE-01` §4 and in
  `S2-REVIEW-03` §B. `take_snapshot` worked throughout, so **structural inspection was never degraded** — only
  screenshots and clicks were.
- Every page in this record was therefore reached by **URL navigation**, which is the read-only path.
- **No screenshot was captured.** `SCREENSHOT EVIDENCE: NOT VERIFIED` continues to apply to the whole programme.
- `list_network_requests` was inspected for a schema and found not to return response headers or bodies
  ("response headers and bodies are not included"), so it could not have resolved §3. It was not used to extract
  evidence, and no request header, cookie or token was recorded.

## 6. Controls that were and were not activated

- **Clicked: one.** The `Refresh` button on the staging Auth → Users list, intended to re-fetch an already-displayed
  read-only list. The click **failed** with the viewport error above and so had no effect; the re-fetch was achieved by
  URL navigation instead. It is disclosed because it was an attempt at a control activation, even though it was
  idempotent and did not land.
- **Not clicked, and visible:** `Add user`, `New table`, `Deploy a new function`, `Open Editor`, `Open Assistant`,
  `View CLI Instructions`, every function template, `Add app`, all five "Add Firebase to your … app" buttons,
  `Tell us about your app`, `Start with an AI coding agent`, `Add Analytics and monitoring`, `Build a backend`,
  `Add AI to your app`, `Monetize your app`, `Host a web app`, `Delete project`, `Edit project name`,
  `Edit environment type`, `Upgrade to Pro`, `New organization`, `New project`, `Copy project URL and API keys`,
  `Activate Cloud Shell`, `SQL Editor`, `AI Assistant`, the `Status` and `Entity Type` filters, both schema comboboxes.
- **No value was copied, read, generated, rotated or revealed.** No key, connection string, password, token or
  service-account file was opened.

## 7. Effect on the auto-pause deadline

A dated dashboard interaction with `parent-control-staging` occurred at **2026-11-02T07:16Z**. Whether a page view
counts as activity for the Free-plan 7-day idle timer is **`NOT VERIFIED`** — Supabase's own wording is not captured
in this repository, and the project home's `6/60 conns` plus 9 requests are consistent with the dashboard generating
traffic, but that is not proof of a clock reset. **The guidance in
[04-risks-rollback-approvals.md](../04-risks-rollback-approvals.md) §2.5 is unchanged: perform a dated, unambiguous
touch (a real settings read, or better, schema load under A3) on or before 2026-11-06, and record the timestamp.**
`R-40` (auto-pause with no start timestamp) stays OPEN; this pass adds one dated observation but still no timer
baseline.

## 8. What this record does not claim

- It does not claim schema, sentinel, secrets, test users, Firebase apps, FCM, Edge Functions or credentials are
  configured. §4 states the actual position.
- It does not resolve §3; it records it and names the approval needed to resolve it.
- It does not re-confirm the Firebase plan.
- It does not constitute A0, A1, A2′, A3, A5, A9, A12 or any signature. It ratifies nothing.
- It does not modify either project in any way.

**Operational actions performed: page navigation and one failed idempotent click. Nothing else.**
