# Staging project proposal (G6) — executed as an empty shell 2026-10-30

**Status: `EXECUTED — SHELL ONLY`.** The Supabase project **is created**: name `parent-control-staging` and ref
`dzonzgngwxclhfnvxtvu` are reserved and recorded (S2-CREATE-01 §2); a database password was set **owner-side in the
browser** with custody **unconfirmed** (§2.6). The project is an empty shell — 0 tables, 0 Edge Functions, no migrations,
no branches, no repository, Postgres `17.11.0.003` / Auth `2.197.0` / PostgREST `14.18`. G6-b (sentinel), G6-c (settings
checklist) and G6-d (schema) are **`NOT DONE`**: no schema, no secrets, no sentinel, no Edge Function are configured. A
Firebase project `haven-staging-46822` was also created; that action exceeded the A12 prohibition as then written and is
**`RATIFIED — 2026-11-02 — OPTION (i)`** (§6; correction C-5/C-10 — A12's wording is amended, and the ratification grants
nothing forward).

> **Superseded proposal text.** Everything below was written pre-creation and is retained as the historical proposal
> record. Where a line reads "not created / not reserved / no action taken", it is superseded by S2-CREATE-01. The
> signable **A0/A2 package was never signed; A0 has never been approved by anyone.** Creation was carried out under
> direct owner browser instruction only.
>
> *Pointer (2026-11-02, C-5/C-10):* that second sentence is true of the package as signed — **no fence was ever filled** —
> but the approval status has since moved: **A0 is approved as a recorded decision** (method amended, C-1) and the creation
> is **ratified under option (i)**. See §7's update note.

Derived from [A-staging-spec.md](parts/A-staging-spec.md), corrected where that working paper predates the plan-of-record
decisions ([06](06-redteam-resolution.md) J-02, J-17). Production `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) remains
unchanged.

---

## 1. What is proposed

| Decision | Proposed value | Basis | Confidence |
| --- | --- | --- | --- |
| Project name | **`parent-control-staging`** | Mirrors `parent-control-prod`; single naming stem | **RESOLVED by S2-CREATE-01** — created; ref `dzonzgngwxclhfnvxtvu`; name reserved and recorded (§2.1). Pre-creation `NOT VERIFIED` is superseded |
| Region | **`ap-northeast-2`** | Same region as production; keeps latency and platform defaults close | **RESOLVED by S2-CREATE-01** — set to `ap-northeast-2` (Northeast Asia, Seoul); reachable only via "Need a specific region?" (§2.6). R-33 superseded |
| Plan | **Free** | Production is Free; no paid tier without written approval | Created on Free/NANO. Slot **realised**: `2 active / 2 used / 0 remaining` — staging consumed the last Free slot (S2-CREATE-01 §2.4) |
| Compute | **NANO** | Production is NANO | VERIFIED |
| Organisation | **Existing organisation** | One owner already controls it; a second org adds billing surface without isolation | VERIFIED single-owner org |
| Separate project, not a branch | **Yes** | A branch shares the production project and its secrets; that would violate C2 | PROPOSED |

Rejected alternatives: a staging **schema** inside production (shares the project, its secrets and its blast radius);
a **branch** (still production-adjacent and not permitted by the brief's "separate staging" requirement); a **paid**
project (needs a billing decision not in scope).

---

## 2. Configuration to mirror, and the deliberate deviations

`R` = replicate the production value; `D` = deliberate deviation, with the reason.

| Setting | Production (observed) | Staging | R/D |
| --- | --- | --- | --- |
| PostgreSQL major | 17 (server 17.11) | 17 | R |
| Auth: email provider | On | On | R |
| Auth: OAuth / phone / SAML / Web3 | Off | Off | R |
| Sign-ups | On | On | R (needed to exercise the `auth.users` trigger) |
| Confirm email | On | On | R — see the email risk in §5 |
| Anonymous sign-ins | Off | Off | R |
| Manual linking | Off | Off | R |
| JWT expiry | 3600 s | 3600 s | R |
| Refresh token rotation / reuse interval | On / 10 s | On / 10 s | R |
| Single-session / time-box / inactivity | Off / 0 / 0 | Off / 0 / 0 | R (Pro-only features) |
| Leaked-password protection | Off (F4) | **Off — plan-forced**; not available on Free, so no F4 experiment is possible here | D — F4 stays `BACKLOG` as a plan/product decision (R-34) |
| Site URL / redirect URLs | Not captured in Stage 1 | Staging URLs only | D — must never point at production |
| Data API exposed schemas | `public`, `extensions` | same | R |
| Data API table/function exposure | 0 of 19 tables, 0 of 38 functions, auto-expose off | same | R |
| Data API max rows | 1000 | 1000 | R |
| Data API extra search path | `public, extensions` | same | R |
| Realtime publication | 4 tables: `device_commands`, `remote_sessions`, `safety_alerts`, `webrtc_signals` | same four | R — membership is not in a schema capture and is re-added explicitly |
| Extensions | **NOT CAPTURED** | Capture first, then install the identical set | R — do not guess `pgcrypto`/`pg_cron` |
| Roles | Platform-managed | Never created, dumped or restored by us | R |
| Secrets | Values never read | **Fresh staging values only** | D |
| Cron scheduler | Function `cron` + `CRON_SECRET`; caller NOT VERIFIED | Function only, **no scheduler** | D — a scheduler in staging could generate traffic nobody is watching |
| TURN / STUN | Names known, provider not read | Separate credentials or unset | D |
| Edge Functions | 9 deployed, 7 minified | **Deploy nothing until source exists** | D — see §4 |
| Default privileges (`postgres`-owned, F1) | Grants `anon`/`authenticated` on future objects | Reproduce | R — so F1 can later be fixed by migration, not by hand |
| Function ACLs incl. F8 | Two `private` functions with `NULL` ACL | Reproduce | R — a hardened creation would make the TE-02 baseline unreal |

**Deliberate deviations, summarised:** staging URLs; leaked-password off because the Free plan does not include it (not a
choice — F4 cannot be tested here); no cron scheduler; separate TURN/STUN or unset; no Edge deployment; fresh secrets.
Each is recorded in the change record with the reason above.

---

## 3. What must be replicated from production

| Object class | Count (Stage 1) | Treatment |
| --- | --- | --- |
| Tables in `public` | 19 (183 columns) | Recreate all, **zero rows** |
| Indexes / constraints | 62 / 137 | Recreate, including pairing-code and command-idempotency uniqueness |
| RLS policies | 21 (15 SELECT, 2 INSERT, 3 UPDATE, 1 DELETE; all `authenticated`, all PERMISSIVE) | Recreate verbatim, all tables RLS-enabled |
| Functions | 38 (14 `public`, 24 `private`; 34 `SECURITY DEFINER`) | Recreate all, bodies included, from the G3 capture |
| Triggers | 7 on `public` + 1 on `auth.users` (`on_auth_user_created`) | Recreate; the `auth.users` trigger is a separate file applied after `auth` exists |
| Realtime tables | 4 | Re-add publication membership explicitly |
| Grants | 149 table, 191 column-UPDATE, 24 default-ACL rows | Recreate; `anon` holds no table grants, `service_role` all |
| Roles | Platform-managed | Do not create or restore |
| Table data | 0 | No rows, no `auth.users`, no storage objects, no migration history |
| Storage | 0 B in production | Nothing to copy |
| Edge Functions | 9 | **Not deployed** (§4) |

**The two objects a schema capture misses**, both mandatory:

1. `profiles.id → auth.users(id) ON DELETE CASCADE` forces restore order `auth` → `public`/`private` → tables → functions
   → triggers → policies → grants → default privileges.
2. `on_auth_user_created → private.handle_new_user()` lives on a platform table. If it is forgotten, signup succeeds and
   silently creates no `profiles` row; the G6-d check exists specifically to catch that.

**Staging-only object:** `private.s2_environment` (one row, value `staging`) — the wrong-project sentinel
([00](00-stage2-execution-plan.md) §4). It is excluded from the parity diff by name and must never exist in production.

---

## 4. The Edge Function problem (why staging will be SQL-only)

The nine functions are the client-facing API, but the repository contains no function source; seven of nine are 2-line
minified bundles with no source maps. Staging therefore cannot be built from this repository.

| Option | Effect | Cost |
| --- | --- | --- |
| 1. Export and redeploy the deployed bundles | Full HTTP parity | Opaque code that cannot be reviewed or patched; needs fresh staging secrets and an approved export |
| 2. Owner supplies the original source | Best outcome | No such source is known to exist |
| 3. **SQL-only staging (recommended for now)** | Unblocks every SQL-tier patch and test | Blocks all 104 HTTP cases and the E6/E7 work |

**Recommendation (as written, pre-creation):** take option 3 now — attempt creation, load the schema, apply P01–P03, run
G5-S. **Superseded by S2-CREATE-01:** creation **is done** as an empty shell on 2026-10-30; the name and region were
exercised and are recorded, so R-32/R-33 are `RESOLVED by S2-CREATE-01`, not `BLOCKED`. Schema load, P01–P03 and G5-S
remain **`NOT DONE`** (`BLOCKED` — no A3, sentinel absent, patches unapplied). Revisit options 1–2
only when the owner decides who exports the source (D-11). No production function secret is ever copied to staging.

---

## 5. Cost and Free-plan limits

Usage re-read 2026-10-30. The second-project slot is now **realised, not merely entitled**: staging consumed the last
Free slot — **`2 active / 2 used / 0 remaining`** (S2-CREATE-01 §2.4). The ceilings below are the same Free tier, but
usage is not an entitlement statement — see [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) §3 for the features
the tier does not include. Figures are the org meter observed at creation (S2-CREATE-01 §2.5), matching
[S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md).

| Dimension | Production used / ceiling |
| --- | --- |
| Database size | 32 MB / 500 MB |
| Log ingestion | **0.20 GB / 1 GB** (was mis-printed 0.17; corrected per S2-CREATE-01 §2.5) |
| Log query | **44.8 GB / 100 GB** (was 33.9 at Stage 1 — rising; R-15) |
| File storage | 0 GB / 1 GB |
| Egress | **0.14 GB / 5 GB** (was mis-printed 0.12; corrected per S2-CREATE-01 §2.5) |
| MAU | 10 / 50,000 |

Observed service versions at creation (S2-CREATE-01 §2.1): Postgres `17.11.0.003`, Auth `2.197.0`, PostgREST `14.18`.
These are the org-meter figures observed at creation; **staging's own footprint remains unmeasured** (`INFERRED`, not
measured — see the note below this section).

**Risks that need an owner decision before creation:**

1. **Two-active-project ceiling — realised.** Free allows 2 active projects; production holds one and staging has now
   taken the second. Org shows **`2 of 2 used, 0 remaining`** (S2-CREATE-01 §2.4): staging **did consume the last slot**
   and **no `dev`/`foreign` third project is possible** without a paid plan or deleting a project. R-32 (name) and
   R-33 (region) are `RESOLVED by S2-CREATE-01`. Confirmed from the official plan terms; the organisation page shows a
   count (2), not a limit. **Never pause or delete production to free a slot.**
2. **Auto-pause — VERIFIED.** Free projects pause after 7 days without activity. G6, G3 and G5-S must therefore run as
   **one coordinated window**; the recovery and re-creation rules are in [04](04-risks-rollback-approvals.md) §2.5 (R-30).
3. **Email sending — NOT VERIFIED.** Confirm-email is on and the Free built-in sender is commonly rate-limited. Mitigation
   is to pre-create fixtures through the admin API with confirmed email (staging only), or to disable confirmation in
   staging and record the deviation. Both are proposed; neither is assumed.
4. **Quota breach is an availability risk, not an invoice risk.** Enforcement behaviour was not observed; do not plan
   around either outcome. Log-query headroom is the tightest dimension (44.8/100 GB), so staging investigations must use
   narrow time windows and prefer table reads over log scans.
5. **No platform restore point — VERIFIED.** Free does not include automatic backups or PITR, so "restore validation"
   means rebuilding from the reviewed artefact, not restoring a platform backup (R-35).
6. **No paid tier, add-on or extra project without written approval.**

Staging's own footprint is unmeasured; an empty 19-table schema is expected to be well under 50 MB
(**INFERRED**, not measured).

---

## 6. Isolation — how test users and data stay separate

| Control | Proposal |
| --- | --- |
| Separate project and ref | Staging is never `hhqgreaoqulmfwfwarhc`; the ref is recorded in every change record |
| Wrong-project sentinel | `private.s2_environment` must return `staging` before any DDL; a missing row aborts the patch |
| Separate keys | Staging gets its own anon key, service-role key, DB password, JWT signing secret |
| Separate app secrets | Staging-only `PAIRING_HASH_PEPPER`, `CRON_SECRET`, TURN credentials; **no production value copied** |
| No production data | Zero rows; no `auth.users`, no location history, no storage objects. Only schema crosses |
| Synthetic identities | Reserved-domain emails (`@example.invalid` and similar) and fixed test UUIDs; no real parent, child or device identifiers |
| No cross-use of credentials | Production's service-role key is never set as a staging secret; staging keys never ship in a production build |
| Distinct devices | Fixture devices use generated secrets; no production device credential is ever reused |
| Teardown | Export redacted evidence and the fixture manifest; stop any scheduler; delete the project in the dashboard; revoke keys, delete the DB password and function secrets, remove local link/env entries; record ref, date, operator; confirm production untouched |

**Single-owner limitation, stated rather than hidden.** The organisation has one owner and no second approver. Staging
inherits that. Approvals in [04](04-risks-rollback-approvals.md) §3 are therefore single-owner with compensating evidence
(patch hash, before/after snapshots, timed window, separate reviewer pass), not a two-person control.

### Service topology (explicit)

| # | Approved role | Component | Status on the created shells |
| --- | --- | --- | --- |
| 1 | Single identity authority | **Supabase Auth** (staging ref `dzonzgngwxclhfnvxtvu`) | `NOT CONFIGURED` — no sign-ups were ever run and no user was created by this programme. **`auth.users` row count `NOT VERIFIED`:** the staging Auth page renders zero rows but prints `Total: 10 users (estimated)` ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3, FX-18); production prints an exact `Total: 8 users`. Resolve with one approved read-only count before A3. |
| 2 | Database | **Supabase Postgres** (0 tables) | `NOT DONE` — schema load needs A3 |
| 3 | API | **Supabase Edge Functions** (0 deployed) | `NOT CREATED` — no source; SQL-only posture (§4) |
| 4 | Subscriptions | **Supabase Realtime** | `NOT CONFIGURED` — the 4-table publication is not re-added |
| 5 | Push transport (intent only) | **Firebase FCM** | `DOES NOT EXIST` — no apps, no credentials, no FCM config (S2-CREATE-01 §4.4) |
| 6 | **Not in the approved architecture** | Firebase Auth / Firestore / Cloud Functions | `OUT OF SCOPE` — must not be enabled |
| 7 | Project created but service-unconfigured | Firebase `haven-staging-46822` (Spark, Analytics off, Gemini off) | `RATIFIED — 2026-11-02 — OPTION (i)` (recorded, not signed; was `AWAITING RETROSPECTIVE RATIFICATION`) |

**Firebase action and the A12 prohibition.** S2-CREATE-01 records that `haven-staging-46822` (project number
`381273275501`, account `shiwa2172000@gmail.com`) was created on 2026-10-30. That exceeds the **A12** (Firebase/FCM)
prohibition: no prior document authorised a Firebase project, and this proposal had assumed "no Firebase action". The
assumption is **superseded**. The project carries **no apps, no credentials, no Firestore, no Cloud Functions, no FCM**
and is a bare shell; enabling **any** Firebase service is out of scope and unapproved. **The creation was ratified on
2026-11-02 under option (i)**, and A12's prohibition was amended by that decision to: **"project creation permitted under
owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited."** The
ratification **grants no A12**: A12's forward signature is absent, and app registration, FCM configuration, credentials and
settings changes remain prohibited.

---

## 7. Approval checklist — split by what happened on 2026-10-30

**Creation approval is `not` schema-load approval, `not` secret approval, and `not` Firebase app-registration approval.**
Each needs its own decision, and none is granted by the creation that has already occurred.

> **Honesty note (S2-DOC-02):** this checklist was written **pre-creation**. The project was nevertheless created on
> 2026-10-30 under direct owner browser instruction. **A0 and A2 were never signed and A0 has never been approved by
> anyone**, so portion (a) below records executed **fact, not granted approval**.
>
> **Update 2026-11-02 (S2-EXEC-03 pass, corrections C-1/C-5/C-10).** The bold sentence above is a point-in-time record and
> is retained. Current state: the executed creation is **ratified, option (i)**; **A0 is approved as a recorded decision**
> with its method amended to offline reconstruction (its physical fence is unfilled); **A2 is still not signed** — a
> retrospective ratification cannot become an advance authorisation. Portion (a) still records fact, not granted approval.

### (a) Actually executed on 2026-10-30 (`EXECUTED — SHELL ONLY`, unapproved by A0/A2)

- [x] Supabase empty shell created: `parent-control-staging` / ref `dzonzgngwxclhfnvxtvu` / ap-northeast-2 / Free / NANO /
      existing org `symqztrmaziuwdibcfrq` (S2-CREATE-01 §2).
- [x] Database password set owner-side in the browser — **custody unconfirmed**; no value read, transcribed or stored by
      the agent (§2.6).
- [x] "Automatically expose new tables" left **OFF**; 0 tables, 0 Edge Functions, no migrations, no branches (§2.2–§2.4).
- [x] Project slot realised: **2 active / 2 used / 0 remaining**; no `dev`/third project; no upgrade (§2.4).
- [x] Firebase `haven-staging-46822` created (Spark, Analytics off, Gemini off) — **exceeded A12 as then written**;
      **`RATIFIED — 2026-11-02 — OPTION (i)`**, A12's wording amended accordingly (§6; C-5/C-10). The [x] records the
      executed fact, not an approval.

### (b) Outstanding — needs its own approval; the creation granted none of it

- [ ] **A0** — G3 method amended to dashboard capture + offline reconstruction + staging equivalence ([00](00-stage2-execution-plan.md) D-01). **Never signed.** — *status update 2026-11-02: A0 is APPROVED as a recorded decision (C-1: capture step amended to offline reconstruction from the in-repo Stage 1 capture). The box stays unticked: this checklist is not a signature and nothing here prefills one.*
- [ ] **A2** — formal sign-off of name / region / plan / organisation as an approval. **Never signed.** — *status update 2026-11-02: the executed creation is RATIFIED (option (i)); A2's own signature is still absent and cannot be granted retrospectively.*
- [ ] **G6-b sentinel = A2′(a)** — `private.s2_environment` = `staging`. `NOT DONE`; required before any DDL. **Sequence A
      (owner decision on B-2, 2026-11-02, C-3): the sentinel is created BEFORE the A3 schema load, so the load and every
      patch can prove the project they are running in.** A2′(a) is **UNSIGNED**.
- [ ] **G6-c settings checklist = A2′(b)** — Auth / site URL / Data API / Realtime / extensions mirror; SSL enforcement and
      connection-logging states still **NOT CAPTURED**. **Runs AFTER the A3 load** (the Realtime publication needs the
      tables to exist). A2′(b) is **UNSIGNED**.
- [ ] **G6-d schema load (under A3)** — 19 tables / 38 functions / 21 policies / triggers / grants, zero rows. `NOT DONE`.
- [ ] **A9 secrets** — fresh staging anon/service keys, DB password re-set if custody unconfirmed, JWT secret,
      `PAIRING_HASH_PEPPER`, `CRON_SECRET`, TURN; no production value copied. `NOT CREATED`.
- [ ] Edge Function strategy: SQL-only chosen in text; export decision deferred (D-11); nothing deployed.
- [ ] Fixture-user method, Data API and Realtime-mirroring approvals, deviation approvals, teardown owner/date — all open.

### Auto-pause deadline

Free projects idle-pause 7 days from creation. Created 2026-10-30 → a **dated dashboard touch is needed on or before
2026-11-06** to keep the shell alive; **no UTC start timestamp was recorded**, so sub-day ordering is by snapshot sequence
only. Recovery / re-creation rules: [04](04-risks-rollback-approvals.md) §2.5 (R-30).

**Consequence:** creation spent the last Free slot for a shell only. G3, every patch and G5-S remain **`BLOCKED`** until
A0/A2/A3 are separately approved; the shell alone delivers no validation value.

> **Restated 2026-11-02 (C-1/C-2/C-5).** The verdict is unchanged — still `BLOCKED` — but the gating is now precise: **A0 is
> approved** (fence unfilled), the creation is **ratified**, and **A1 is `INOPERATIVE`**, so no production capture is
> available to load. What blocks the load is **A2′(a) and A3 unsigned** plus the measured fact that the reconstructed
> artefact is **`NOT LOAD-READY`** — 459 active statements, **0** of them creating a function, trigger, policy or
> publication, because 24 of 38 bodies and all 38 return types are absent from the evidence.

---

## 8. Open questions carried to the owner

1. ~~Is the Free-plan two-project ceiling binding on this organisation, and is staging the last slot?~~ **ANSWERED &
   REALISED 2026-10-30 (S2-CREATE-01)** — staging took the last of 2 slots, `0 remaining`. The **name** and **region** are
   `RESOLVED by S2-CREATE-01` (R-32, R-33): created as `parent-control-staging`, region `ap-northeast-2` reached only via
   "Need a specific region?".
2. Which extensions and versions are installed in production, and are they all available on Free? (Region selectability
   was `RESOLVED by S2-CREATE-01`; the extension set remains **NOT CAPTURED** — §2.)
3. Who exports the Edge Function source, and does an unminified original exist?
4. What invokes `cron`, on what schedule, and is `pg_cron` installed?
5. Which TURN/STUN provider does production use? (Names are known; values were deliberately not read.)
6. Is `Haven-1.2-release.apk` the compatibility baseline, given 1.0 uses a different signing key?
7. Who performs the separate reviewer pass in a single-owner organisation?

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed.
