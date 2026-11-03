# S2-INSP-01 — Supabase dashboard, read-only inspection

**Record ID:** S2-INSP-01
**Date/time (UTC):** 2026-10-30T08:00Z – 2026-10-30T08:08Z
**Operator:** agent session (browser UI only; no CLI, no REST, no dev tools)
**Classification:** READ-ONLY. No project created, no SQL executed, no secret read, no settings changed.
**Approval reference:** covered by the owner's Stage 2 brief §3/§10 (inspection only). This is not A1/A2 approval and creates no right to modify.

## Evidence mode and its limitation

`take_screenshot` failed three times with `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE` (in-app browser has no visible
surface: `visible=false, attached=false, visibilityState=hidden`). Pointer actions (`click`) fail for the same reason.
Evidence below is the verbatim accessibility-tree text returned by `take_snapshot`, which the harness captures directly
from the page. **Screenshot evidence: NONE.** Status of visual-evidence requirement: `NOT VERIFIED` — see R-27 in the
report. No alternative tool was used to obtain pixels, per the browser-only rule.

## Pages inspected

| # | URL | Result |
| --- | --- | --- |
| 1 | `https://supabase.com/dashboard/organizations` | 1 organisation listed |
| 2 | `https://supabase.com/dashboard/org/symqztrmaziuwdibcfrq` | `parent-control-prod` card, Free plan usage |
| 3 | `https://supabase.com/dashboard/org/symqztrmaziuwdibcfrq/general` | Org settings, slug `symqztrmaziuwdibcfrq` |
| 4 | `https://supabase.com/dashboard/new/symqztrmaziuwdibcfrq` | New-project form rendered, **not filled, not submitted** |
| 5 | `https://supabase.com/dashboard/org/symqztrmaziuwdibcfrq/billing` | Free plan, spend cap enabled |
| 6 | `https://supabase.com/dashboard/org/symqztrmaziuwdibcfrq/usage` | Cycle 26 Oct–26 Nov 2026 |

## Observations (verbatim from page text)

### Account and organisation
- Account/org label in the dashboard header: `S spg7753@gmail.com's Org`
- Organisations page: `spg7753@gmail.com's Org  Free Plan · 1 project` — **exactly one organisation**.
- Organisation settings: name `spg7753@gmail.com's Org`, slug `symqztrmaziuwdibcfrq`.
- **Consequence:** the session that owns production is `spg7753@gmail.com`. The org switcher shows no second org.

### Project inventory
- Project card: `parent-control-prod`, link `https://supabase.com/dashboard/project/hhqgreaoqulmfwfwarhc`, region
  `ap-northeast-2`, compute `NANO`.
- Project ref in the card URL **matches** the brief: `hhqgreaoqulmfwfwarhc`. Region and compute match Stage 1.
- Project count: **1**. No project named `parent-control-staging` or similar exists.
- Project name `parent-control-staging` availability: `NOT VERIFIED` (requires attempting creation).

### Plan and billing
- Billing page: `Free` / `Plan`. `This organization is limited by the included usage`. Spend cap is `enabled` —
  `You won't be charged any extra for usage. However, your projects could become unresponsive or enter read only mode
  if you exceed the included quota.`
- **Billing implication of a second project:** no card charge while the spend cap is enabled; the risk is
  availability/quota, not invoice. `VERIFIED` (dashboard text).
- Numeric project cap for the Free plan: **not displayed anywhere in the dashboard pages inspected.** `NOT VERIFIED`.
  The commonly cited 2-project Free ceiling remains `INFERRED` (D-12 / R-09 unresolved as a number).

### Slot availability
- With 1 of 1 project shown, the new-project form at `/dashboard/new/symqztrmaziuwdibcfrq` renders fully:
  Organization combobox `spg7753@gmail.com's Org FREE`, editable Project name, editable Database password,
  Region combobox (default `Auto`), and an enabled `Create new project` button. **No limit banner, no upgrade
  interstitial, no disabled submit.**
- Interpretation: the UI currently permits creating another project in this org. `VERIFIED` that the form is
  available; the *exact* remaining slot count is `NOT VERIFIED` (only one creation attempt would prove it, which is
  forbidden in this window).
- **Paid upgrade required for staging: NO** evidence of that. Free/NANO remains offered. `VERIFIED` that no upgrade
  prompt blocks the form.

### New-project form defaults — pre-creation configuration facts
Observed default state of the creation form (read-only; nothing changed):
- `Enable Data API` — **checked**
- `Automatically expose new tables` — **checked** (production is 0 tables exposed, auto-expose off → must be
  unchecked in G6-b)
- `Enable automatic RLS` — **unchecked**
- `Region` — **`Auto`** (must be set explicitly to `ap-northeast-2`)
- Compute selector: not shown on this form; Free default expected NANO — `INFERRED`.

### Usage snapshot (org-wide, current cycle 26 Oct–26 Nov 2026)

| Dimension | Stage 1 record | Observed now | Drift |
| --- | --- | --- | --- |
| Egress | 0.12 GB / 5 GB | 0.14 / 5 GB | +0.02 GB |
| Database size | 32 MB / 500 MB | 32 / 500 MB | none |
| MAU | 10 / 50,000 | 10 / 50,000 | none |
| File storage | 0 GB / 1 GB | 0 / 1 GB | none |
| Log ingestion | 0.17 GB / 1 GB | 0.20 / 1 GB | +0.03 GB |
| Log query | 33.9 GB / 100 GB | 44.8 / 100 GB | **+10.9 GB** |

- Log-query headroom is tightening (44.8 % of allowance). The usage page states log-ingestion and log-query
  enforcement begin `after the grace period ends at the start of 2027`, so this is currently a measurement, not an
  enforced cap. R-15 remains applicable; staging investigations should stay narrow.
- Database-size quota shown as `0.5 GB per project` — i.e. per-project, not pooled. `VERIFIED` (dashboard text).

## Status summary

| Claim | Status |
| --- | --- |
| Session owns `parent-control-prod` (`hhqgreaoqulmfwfwarhc`) | `VERIFIED` |
| Exactly one organisation, one project | `VERIFIED` |
| Plan is Free, compute NANO, region ap-northeast-2 | `VERIFIED` |
| Creating staging needs a paid upgrade | `VERIFIED` — no upgrade prompt; plan limit later confirmed as 2 active projects (see addendum) |
| A second project can be created right now | `INFERRED` — form enabled; creation itself was not attempted (corrected in addendum) |
| Free plan numeric project cap | `VERIFIED` in addendum — 2 active projects (official plan documentation) |
| `parent-control-staging` name availability | `NOT VERIFIED` |
| Production untouched by this window | `VERIFIED` — read-only navigation only |
| Screenshot evidence captured | `NOT VERIFIED` — no visible browser surface |

**Stop point:** staging creation is `BLOCKED — APPROVAL REQUIRED` (A0 + A2 unsigned). Nothing was created.

---

## Addendum — corrections and later verification (2026-10-30T08:15Z, S2-NEXT-01)

Recorded rather than silently rewritten, per the "failed change becomes a finding" rule.

1. **Corrected overclaim.** The row "A second project can be created right now — `VERIFIED` (form enabled)" is
   downgraded to `INFERRED`. An enabled form is not proof of a successful creation, and creation was deliberately not
   attempted. The slot question is instead settled by documented plan terms (item 2 below).
2. **Project limit now `VERIFIED`.** Official plan documentation at `https://supabase.com/pricing` (linked from the
   dashboard billing page as "Compare plans" / "Supabase Plans") states verbatim:
   *"Free projects are paused after 1 week of inactivity. Limit of 2 active projects."*
   The org has 1 active project, so exactly one slot remains and no paid upgrade is needed for a single staging project.
   This resolves D-12 / R-09 as a number. It does not resolve name availability, and it leaves no room for a `dev`
   project.
3. **Billing wording hedged.** "No card charge" is supported only for overage while the spend cap is enabled; it is not
   a statement that a second project is free of any billing consequence. Treat as `INFERRED` at that granularity.
4. **Record completeness gaps** (fields from the 04 §5 template not captured here): explicit
   ENVIRONMENT/PROJECT REF field, EVIDENCE PATHS with a hash, QUOTA DELTA attributable to the window, DECISION line,
   APPROVER + reviewer pass, SIGN-OFF. None of these affects any observation above.
5. **Free-tier constraints that change plan assumptions** (also official documentation, same page): leaked-password
   protection, single-session, session timeouts, branching, automatic backups, PITR and platform audit logs are **not
   included** on Free; Auth audit logs retain 1 hour; custom SMTP **is** included. Consequences are recorded in
   `S2-NEXT-01-readiness-report.md` §3.

## SUPERSESSION ADDENDUM (2026-11-02, S2-DOC-02)

**Asserted here:** at 2026-10-30T08:00–08:08Z the org held exactly 1 project and creation was `BLOCKED — APPROVAL REQUIRED`, nothing created; the
08:15Z addendum verified the Free cap at 2 active projects, leaving **1 used / one slot remaining**.

**Superseded by [S2-CREATE-01](S2-CREATE-01-new-projects.md)** (same date, later window): "1 used / one slot remains" (§Slot availability; addendum
item 2) → **2 active / 2 used / 0 remaining** (CREATE-01 §2.4); "`parent-control-staging` availability `NOT VERIFIED`" → that project now exists (§2.1);
"nothing was created" → executed under a direct owner instruction with A0 and A2 unsigned, A0 never approved by anyone (§1; R-31 and R-36…R-38 in
[04](../04-risks-rollback-approvals.md) §1). The plan-limit statements left `INFERRED` above were later `VERIFIED` from official plan terms — a
sequence of findings, not two competing claims.

**Still valid:** every observation here, including the §Usage snapshot meters, stands as a point-in-time reading for the window captured
(CREATE-01 §2.5 independently confirms those figures). Nothing above is deleted or rewritten; this record is append-only.
