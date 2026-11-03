# S2-NEXT-01 — Final staging readiness and approval gate (read-only)

**Record ID:** S2-NEXT-01
**Date/time (UTC):** 2026-10-30T08:10Z – 2026-10-30T08:16Z
**Operator:** agent session, browser UI only
**Classification:** READ-ONLY verification. No project created, no form submitted, no SQL executed, no secret read,
no Firebase action.
**Approval reference:** A1-class read-only inspection only. This record is not A0, A2, A3, A5, A6, A9 or A12, and grants
nothing.
**Environment observed:** production `parent-control-prod` / `hhqgreaoqulmfwfwarhc`, org `symqztrmaziuwdibcfrq`.
**Screenshot evidence:** `NOT VERIFIED` — `take_screenshot` returned `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`
(`visible=false, attached=false, visibilityState=hidden`) again in this window. Evidence is the verbatim
accessibility-tree text with exact URL and UTC timestamp.

---

## 1. Supabase recheck

| Page (UTC) | Observation |
| --- | --- |
| `/dashboard/org/symqztrmaziuwdibcfrq` 08:11Z | Header `S spg7753@gmail.com's Org 1 project`; single project card `parent-control-prod`, URL `/project/hhqgreaoqulmfwfwarhc`, `ap-northeast-2`, `NANO`; Free plan usage panel |
| `/dashboard/new/symqztrmaziuwdibcfrq` 08:12Z | `Create a new project` form renders; no quota banner, no upgrade interstitial; **not filled, not submitted** |
| `supabase.com/pricing` 08:13Z | Free plan terms, including the project limit (below) |
| `console.firebase.google.com` 08:14Z | Firebase account and project list unchanged |

Creation-form state observed this window:
- Organization combobox: `spg7753@gmail.com's Org FREE`
- Project name and Database password: empty (deliberately)
- Region combobox: `Loading available regions...` (list had not resolved) — `ap-northeast-2` availability in the picker
  is therefore `NOT VERIFIED` for a *new* project, though production already runs there
- `Enable Data API`: **checked**
- `Automatically expose new tables`: **checked** (must be cleared — production has 0 exposed tables)
- `Enable automatic RLS`: **unchecked**
- `Create new project` button: disabled, consistent with empty required fields
- No upgrade prompt, no project-limit message

Navigation artefact, recorded to prevent later misreading: the header briefly renders `No projects` before the project
list loads. The authoritative organisation page shows **1 project**. This is a client-side loading state, not a change.

## 2. Project limit — `VERIFIED`

The dashboard itself does not display a project count limit. The official plan documentation does, and it is linked
from the dashboard's own billing page ("Compare plans", "Supabase Plans"). Verbatim from `https://supabase.com/pricing`:

> *"Free projects are paused after 1 week of inactivity. Limit of 2 active projects."*

Conclusion:
- Free-plan cap: **2 active projects** — `VERIFIED` (official documentation), cross-checked against the dashboard plan
  label `Free`.
- Active projects now: **1**. Remaining slots: **1**.
- A single staging project is permitted **without a paid upgrade** — `VERIFIED`.
- No room for a `dev` project at the same time; a third project, or a staging replacement while another exists,
  requires an upgrade or a deletion.
- Whether the name `parent-control-staging` is still available: `NOT VERIFIED` (only a creation attempt would prove it).
- Whether creation actually succeeds: `INFERRED` — never attempted.

## 3. Free-tier constraints with direct Stage 2 consequences (`VERIFIED` as plan terms)

Same official page, Free plan column. Each line below is a documented entitlement; the *consequence* is my inference.

| Free-plan term | Stage 2 consequence |
| --- | --- |
| **Leaked password protection — not included** | F4 cannot be toggled on Free. The proposal's "leaked-password off initially, toggled only as a recorded F4 experiment" is **not executable** without a paid plan. F4 stays BACKLOG with a plan constraint attached. |
| **Single session per user — not included** | The proposal's `R` row "single-session Off / time-box 0 / inactivity 0" is plan-forced, not a configuration choice. Those behaviours cannot be tested in staging. |
| **Session timeouts — not included** | Same. |
| **Branching — not included** | The rejection of a branch-based staging is forced by plan, not only by isolation reasoning. |
| **Automatic backups / PITR — not included** | Staging has no restore point. All rollback safety rests on the offline captured pre-state (R-14, R-17). A bad staging load is recovered by re-creation, not restore. |
| **Platform audit logs — not included** | Dashboard actions leave no platform-side audit trail available to us. Evidence must be self-generated; this strengthens R-27 and weakens any later "prove what was clicked" claim. |
| **Auth audit logs — 1 hour** | Auth events must be captured immediately; no 24-hour retrospective. |
| **Free projects paused after 1 week of inactivity** | **New risk (R-30).** A staging project idle for more than 7 days can be paused. Staging must be created inside a planned working window, or an explicit restore step must be scheduled. This also constrains any long gap between G6, G3 and G5-S. |
| **Custom SMTP — included** | Offers a real mitigation for R-08 (Free built-in email rate limit), at the cost of SMTP credentials — itself an A9-class decision. |
| **Log query 100 GB / Log ingestion 1 GB** | Matches the dashboard panels; no discrepancy. |

## 4. Quota risk (material?)

| Dimension | Now | Scope | Staging consumption | Risk |
| --- | --- | --- | --- | --- |
| Log query | 44.8 / 100 GB | Org-wide | Every SQL Editor run and log scan | **HIGH** — shared, +10.9 GB since Stage 1; the >80 GB stop line is reachable by investigation volume, not by staging size |
| Log ingestion | 0.20 / 1 GB | Org-wide | ~0 (no Edge, no cron) | LOW |
| Egress | 0.14 / 5 GB | Org-wide | ~0 | LOW |
| Database size | 32 / 500 MB | **Per project** | Own 500 MB; empty schema ≪50 MB (INFERRED) | LOW |
| MAU | 10 / 50,000 | Org-wide | ≤ a handful of fixtures | LOW |
| File storage | 0 / 1 GB | Org-wide | 0 | LOW |

Billing page states the spend cap is **enabled**: no overage invoice; a quota breach degrades availability instead. Log
ingestion and log query enforcement begin after a grace period ending at the start of 2027, so today this is an
evidence-quality and hygiene issue rather than an enforced cap. **Not a reason to withhold staging; a monitoring
requirement (R-15).**

## 5. Firebase identity and scope — confirmed

- Account: `Shiwa Goswa!i (shiwa2172000@gmail.com)` — unchanged.
- Projects: `1 – 1 of 1`, being `FlutterFlowWIthFIreBase` (`flutter-flow-w-ith-f-ir-6592ib`), an unrelated demo
  (package `com.mycompany.flutterflowwithfirebase`). Not to be reused.
- No Haven / `parent-control` Firebase project is visible under this account. `VERIFIED`.
- Whether another Google account owns one: `NOT VERIFIED`; account switching was not performed and is not authorised.
- Identity split stands: Supabase owner `spg7753@gmail.com`; Firebase owner `shiwa2172000@gmail.com`; a third, wrong
  CLI account `om-event*` recorded in Stage 1. Consequence: G7's "service-account JSON into Edge secrets" would cross
  two consoles and two identities, and `firebase/SETUP-CHECKLIST.md:58` still assumes "one owner should control both" —
  an assumption now contradicted by evidence. A one-line correction is needed there (not applied).
- **G2, G7 and A12 remain deferred** pending a separate owner decision on Firebase ownership. Read-only inspection does
  not constitute any of them.

## 6. Staging creation readiness

**Verdict: `READY FOR OWNER APPROVAL` — qualified.** The approval package is complete and every read-only precondition
is satisfied. A0 and A2 are unsigned; nothing is created; no schema-load or patch authority exists.

| Readiness factor | State |
| --- | --- |
| Organisation and identity correct | `VERIFIED` |
| Slot available (limit 2, 1 used) | `VERIFIED` |
| Paid upgrade required | No — `VERIFIED` |
| Cost exposure (spend cap on) | No invoice risk; availability risk only — `VERIFIED` |
| Name availability | `NOT VERIFIED` |
| Creation itself | `INFERRED` (not attempted, by instruction) |
| Region selectable as `ap-northeast-2` in the new-project picker | `NOT VERIFIED` (list unresolved during inspection) |
| Schema-load capability | Absent — needs A3, and a reviewed reconstruction artefact |
| Staging usable for G5-S | Only after G6 + G3 + A5; currently `BLOCKED — APPROVAL REQUIRED` |

Two facts change the owner's risk picture compared with the original proposal: **exactly one slot remains** (so
staging is the last project), and **free projects pause after 7 idle days** (so the build-and-validate window must be
planned as a unit).

## 7. Approval wording for signature

### A0 — G3 method amendment

> I approve changing G3's **method only**, from the Stage 1 method (CLI `supabase db dump`, Docker local stack,
> `pg_dump` no-diff proof) to: (a) read-only catalogue capture through the dashboard SQL Editor — catalogue only, never
> table data; (b) offline reconstruction of one reviewed baseline artefact, secret-scanned before it enters the
> repository, with unmatched hits reviewed by hand and recorded rather than silently redacted; (c) application to
> staging in dependency order with a per-statement log; (d) an equivalence record comparing counts and ACL sets with
> the capture, every difference listed and accepted.
>
> The **objective is unchanged**: a restorable schema baseline proven equivalent to production. The baseline is a
> **pre-P01 snapshot**; P01's ACL change is recorded divergence, not drift.
>
> Scope captured: `public` and `private` — 19 tables, 62 indexes, 137 constraints, 21 policies, 38 functions, 7 public
> triggers, grants, 24 default-ACL rows, 4 realtime memberships, extension set as recorded. Excluded: auth settings, the
> `auth.users` trigger (separate file), platform schemas, Edge bundles, secrets (name/digest only), all table data,
> migration history, and the staging-only sentinel.
>
> This approval does **not** authorise production DDL/DML (read-only introspection remains A1), schema load (A3), any
> patch (A5), any secret operation (A9), Edge export or deploy (A7/A8), Firebase (A12), or project creation (A2).
> No production data and no production credential is read. If this approval is refused, G3 is recorded
> `BLOCKED — METHOD NOT PERMITTED` and steps 3–5 do not start.

### A2 — permission to create `parent-control-staging`

> I authorise creation of **one** Supabase project named `parent-control-staging`, region `ap-northeast-2`, plan
> **Free**, compute NANO, in the existing organisation `spg7753@gmail.com's Org` (slug
> `symqztrmaziuwdibcfrq`). It is a separate project — never a schema inside, and never a branch of,
> `parent-control-prod` (`hhqgreaoqulmfwfwarhc`).
>
> Creation-time settings: Data API **on**; **"Automatically expose new tables" off** (the form defaults to on); region
> set **explicitly** to `ap-northeast-2` (the form defaults to `Auto`); RLS is established by the approved G3
> reconstruction, not by the form's "automatic RLS" toggle, which stays **off**.
>
> The project starts empty: zero rows, no `auth.users`, no storage objects, no production data, and no production key,
> service-role key, password, JWT secret or pepper. Fresh staging credentials are A9, not this record. The sentinel
> `private.s2_environment` (one row, `staging`) is created in G6-b under this record.
>
> Recorded evidence: slot check (`S2-INSP-01` plus the documented 2-active-project limit), cost statement (Free, spend
> cap enabled, no invoice risk), project ref on creation, snapshot reference (screenshots unavailable), and an
> attestation that production is unchanged.
>
> Not authorised: A3 schema load; A5 P01/P02/P03; A9 secrets; A6 any production action; A7/A8 Edge; A11 fixtures; A12
> Firebase; any paid tier, add-on or upgrade; any second (`dev`) project.
>
> Creation proceeds only if the dashboard still permits it at submit time. If the cap blocks it, I decide between a
> separately approved upgrade and stopping. Production is never paused, deleted or downgraded to free a slot. If
> creation or the later restore fails, deletion and re-creation require a **new** A2 record citing the failure.

## 8. Prohibited until separately approved

| Prohibited now | Unlock |
| --- | --- |
| Create / delete / re-create `parent-control-staging` | A0 + A2 (deletion: new A2 citing failure) |
| Any SQL, DDL or DML against production | A6 (+ 7-item gate, staging evidence first) |
| Pause, delete or downgrade production; plan upgrade | **no approval exists** |
| Read production table data, PII, user/family/device/telemetry rows | A1, catalogue only |
| G3 catalogue capture beyond the read-only plan | A0 + A1/A3 |
| Load the reconstructed schema (G6-c) | A3 |
| Apply P01, P02 or P03 — in any environment | A5 (+ reviewer pass) |
| Create test users, families or devices | A11 |
| Read, copy, display or store any secret value | A9 — names and digests only |
| Create a cron job or scheduler in staging | **none** (deliberate deviation) |
| Export or deploy Edge Functions | A7 / A8 |
| Any Firebase action (project, services, app registration, package ID, service-account JSON, FCM, config copy) | A12 — outside Stage 2 |
| Client changes (Flutter parent, Kotlin child) or release | separate patch + A13 |
| Supabase/Firebase CLI, REST/direct API, DevTools, hidden endpoints, scripts, SQL clients | **never** (C1) |
| Recording an expected result as observed; "G5 passed"; "production ready"; "Stage 2 started/passed" | **never** |

## 9. Mapping arithmetic — exact correction needed (not applied)

`docs/stage2/02-findings-to-fix-mapping.md:83` reads:

> `| Blocked on a body capture (B) | 4 (E11, E13, F1, F3, F6-minor) | — |`

Five findings are listed (E11, E13, F1, F3, F6), so the count is wrong. Required correction, one character:

- **Before:** `4 (E11, E13, F1, F3, F6-minor)`
- **After:** `5 (E11, E13, F1, F3, F6-minor)`

A second, substantive defect sits behind it: the tier label **B** means "object definition was never captured", but
verification against `docs/stage1/16-phase-e-findings.md` shows only **E11** is genuinely capture-blocked (the `poll`
path calls one of the 11 unread `private` bodies). **F3's** trigger body *was* read (Stage 1 records all five trigger
bodies as read and closed), so `02:51`'s "Needs the trigger body" is factually wrong — it needs a policy rewrite and a
reviewed trigger change. **F1** is a default-privileges/ownership problem with `g1-q6` already captured; **E13** is a
missing audit-event design; **F6** is backlog sequencing. If the row is meant to count *status* rather than *tier*, it
should read `2 (E11, F3)` and F3 should be re-labelled.

Recommended fix (owner decision, not applied): change `4` → `5` **and** correct `02:51` to "Needs a policy rewrite and
a reviewed trigger change; the trigger body is captured". No downstream document repeats the count, so nothing else
changes.

## 10. Outstanding risks and unresolved assumptions

1. **R-09 partially resolved, constraint remains:** limit is 2 active projects (`VERIFIED`); staging consumes the last
   slot, so no `dev` project exists without upgrade or deletion.
2. **R-30 (new): idle auto-pause.** Free projects pause after 1 week of inactivity. Stage 2 must be executed as a
   planned window, or a restore step added. Not currently in the risk register.
3. **R-27 amplified:** no screenshots **and** no platform audit logs on Free. Dashboard evidence is self-reported text
   only. Any future claim about what was clicked rests on this record, not on platform logs.
4. **F4 not reproducible on Free:** leaked-password protection is not included in the plan. The proposal's F4
   experiment is unavailable without upgrade.
5. **Name availability and region-picker availability** for a new project remain `NOT VERIFIED`.
6. **A0 vs "empty shell" contradiction** (01 §7 vs 00 §3/§4): conservative reading adopted — A0 **and** A2 before
   creation; an A2-only shell spends the last slot for no validation value.
7. **Patch documentation defects** found earlier remain unfixed and must be corrected before A5: P01 pre-check
   expectation and commit/rollback path; P02 missing in-file rollback and hash assertions; P03 missing in-file rollback
   and its two preconditions in the header.
8. **Firebase ownership split** is unresolved and blocks G7 design, not Stage 2 execution.

## 11. What this window did not do

No project created; no form field filled or submitted; no SQL executed; no schema loaded; no patch applied; no secret
read or displayed; no Firebase project, service, app or credential created or changed; no production modification of
any kind. Stage 2 has not started and nothing has passed.

## SUPERSESSION ADDENDUM (2026-11-02, S2-DOC-02)

**Asserted here:** after the 2026-10-30T08:10–08:16Z window — cap `VERIFIED` at 2 active with **one slot remaining**, creation "not attempted /
`INFERRED`", name and region-picker availability `NOT VERIFIED`, the conservative reading "A0 **and** A2 before creation" (§10 item 6), verdict
`READY FOR OWNER APPROVAL`, and §11 "no project created".

**Superseded by [S2-CREATE-01](S2-CREATE-01-new-projects.md)** (same date, later): "one slot remains" → **2 active / 2 used / 0 remaining** (§2.4);
"creation not attempted" / "no project created" → both Supabase and Firebase shells were created on a direct owner instruction with **A0 unsigned and
never approved by anyone and A2 unsigned** (§header, §1; R-37, R-38 in [04](../04-risks-rollback-approvals.md) §1); name and region are now `VERIFIED`.
§9's quoted `4 (E11, E13, F1, F3, F6-minor)` row and "No downstream document repeats the count" are stale — [02](../02-findings-to-fix-mapping.md) §5
carries the corrected 1 + 4 split. §10 item 2's "R-30 … Not currently in the risk register" is likewise corrected: R-30 is registered in 04 §1 marked
REALISED, and R-36…R-41 were added there on 2026-11-02.

**Still valid:** the Free-plan terms (§2, §3), the quota picture (§4) and the three-identity finding (§5); every observation stands for 08:10–08:16Z.
