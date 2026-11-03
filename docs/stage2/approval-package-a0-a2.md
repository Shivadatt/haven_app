> **SUPERSEDED 2026-11-02 — DO NOT SIGN.** Replaced by
> [approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md), which carries the
> retrospective ratification decision and all forward approvals. Line 27 as originally numbered, below
> (`Staging project created | **No**`), and this document's forward-authorisation framing of A2 are **falsified** by
> [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md): both shells were created on 2026-10-30. Body below unedited.
>
> **Do not rely on these lines as they now stand** (current numbering; body retained unedited as history):
> **:9-10** "Nothing here has been executed: no project exists… no Firebase action has been taken" — false; both shells
> were created and the Firebase project was created **inside** Stage 2.
> **:28** "Slots in use **1** … staging would use the **last** slot" — false; 2 active / 2 used / **0 remaining**
> (re-confirmed 2026-11-02 in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1.3).
> **:31** "egress 0.12/5 GB" — stale; observed **0.14**, and log ingestion **0.20/1 GB**.
> **:33** "Staging project created | **No**" — false.
> **:34** "Stage 2 status | `PROPOSED — NOT STARTED`" — false.
> The A0/A2 signature blocks in §2/§3 describe actions that were **partly performed under owner instruction without a
> signed approval**, so they cannot be signed prospectively as written; A2's scope also mixed secrets into project
> creation, which A9 now separates. Ratify or reverse the executed creation first (§2 of the v2 package).

# Approval package — A0 (G3 method) and A2 (staging project)

**Status: `AWAITING OWNER SIGNATURE`.** This document is a request, not an approval. Nothing here has been executed:
no project exists, no SQL has run, no secret exists, no Firebase action has been taken. Signing A0 or A2 authorises
**only** what the signed item states — not A3, A5, A6, A7, A8, A9, A11, A12 or A13
([04](04-risks-rollback-approvals.md) §3).

Evidence behind this request: [S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md) (organisation, slots, limits),
[S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) (readiness, entitlement, patch mapping), and
[02](02-findings-to-fix-mapping.md) (corrected). Screenshot evidence is **`NOT VERIFIED`** throughout; every capture is
an accessibility-tree snapshot with its URL and UTC timestamp (R-27).

---

## 1. What is already settled

| Item | Result | Label |
| --- | --- | --- |
| Production project | `parent-control-prod` / `hhqgreaoqulmfwfwarhc` / `ap-northeast-2` / NANO / Free | VERIFIED |
| Organisation | `symqztrmaziuwdibcfrq`, single owner `spg7753@gmail.com` | VERIFIED |
| Free project limit | **2 active projects per organisation** (official plan terms) | VERIFIED |
| Slots in use | **1** (production). Staging would use the **last** slot | VERIFIED |
| Paid upgrade needed for staging | **No** | VERIFIED |
| Free-plan features excluded | leaked-password protection, single-session/timeouts, branching, automatic backups, PITR, platform audit logs; 7-day idle auto-pause | VERIFIED |
| Production usage (re-read 2026-10-30) | DB 32/500 MB; log query **44.8/100 GB**; egress 0.12/5 GB | VERIFIED |
| Firebase under inspected identity | one unrelated demo project; no Haven project | VERIFIED for `shiwa2172000@gmail.com` only |
| Staging project created | **No** | — |
| Stage 2 status | `PROPOSED — NOT STARTED` | — |

---

## 2. A0 — G3 method amendment

### 2.1 The problem A0 resolves

Stage 1's G3 method is `supabase db dump` under Docker plus a `pg_dump` no-diff proof. Both are excluded by constraint
C1 (web dashboard only, no CLI). Without an amendment, G3 is unexecutable and steps 2–5 have no baseline.

### 2.2 The method being approved (replaces the method, not the objective)

**Objective (unchanged):** a restorable schema baseline proven equivalent to production, with every difference listed
and accepted.

1. **Capture** — read-only catalogue queries in the production SQL Editor: `pg_get_functiondef`, `pg_get_triggerdef`,
   `pg_get_constraintdef`, `pg_get_indexdef`, `pg_policies`, `pg_proc` (`prosrc`, `proacl`, `proconfig`), `pg_class.relacl`,
   `pg_default_acl`, `pg_extension`, `pg_publication_tables`. **No table data.**
2. **Reconstruct offline** — build one `.sql` artefact in dependency order: `auth` → schemas → tables → functions →
   triggers → policies → grants → default privileges. The `auth.users` trigger is a **separate file** applied after `auth`
   exists.
3. **Secret-scan before the artefact enters the repository** — `prosrc` is the one catalogue column that can hold a
   pasted credential; 24 bodies were never read in Stage 1. Hits are reviewed and recorded, never silently redacted.
4. **Apply to staging** in that order, with a per-statement restore log.
5. **Equivalence record** — re-run the g1-* count/ACL queries against staging and diff against the capture; every
   difference listed and accepted by name.

### 2.3 What A0 explicitly accepts

- **The baseline is a pre-P01 snapshot.** After P01, `proacl` on two functions legitimately differs; that divergence is
  approved, not drift (R-19).
- **There is no platform restore point.** Free includes no backup or PITR, so "restore validation" means rebuilding from
  the artefact into a clean schema, not restoring a platform backup (R-35).
- **Row data, `auth.users`, storage, migration history and Edge bundles are out of scope**; a staging pass proves nothing
  about them (R-01).
- **`supabase db reset`, `--role-only` and `pg_dump` remain unauthorised.** A0 does not reintroduce them.

### 2.4 Signature

```text
A0 — G3 METHOD AMENDMENT
I approve replacing Stage 1's G3 method with the five-step capture → reconstruct → scan → apply → equivalence
procedure in docs/stage2/approval-package-a0-a2.md §2.2, for staging only. I accept the four limits in §2.3.
This approval does not authorise A2, A3, A5, A6, A7, A8, A9, A11, A12 or A13, and does not authorise any production
write.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 3. A2 — create the staging project

### 3.1 Requested parameters

| Parameter | Value | Confidence |
| --- | --- | --- |
| Name | `parent-control-staging` | **NOT VERIFIED** — never reserved; could collide (R-32) |
| Region | `ap-northeast-2` | Production region VERIFIED; **selectability on a new project NOT VERIFIED** (R-33) |
| Plan / compute | Free / NANO | VERIFIED |
| Organisation | existing `symqztrmaziuwdibcfrq` | VERIFIED |
| Slot consumed | the last of 2 active projects | VERIFIED |
| Contents at creation | empty shell. **No schema load** (that is A3) | — |
| Edge Functions | none deployed; staging is SQL-only ([01](01-staging-project-proposal.md) §4) | PROPOSED |
| Data | zero rows, synthetic identities only | PROPOSED |
| Secret values | none copied from production; fresh staging values only | PROPOSED |
| Window | G6 + G3 + G5-S inside **one 7-day active period** | required by R-30 |

### 3.2 What A2 authorises

1. Creating one Free/NANO project in the existing organisation.
2. Creating the staging-only sentinel table `private.s2_environment` with one row `staging` (G6-b). Nothing else.
3. Mirrored dashboard settings for auth, JWT, Data API (`public`, `extensions`; 0 tables; 0 functions; auto-expose off)
   and Realtime membership — recorded as a checklist, not changed on production.
4. Creating fresh staging secrets, recorded by **name and digest only**.

### 3.3 What A2 does **not** authorise

- **A3** (schema capture and load), **A5** (patch application), **A6** (production), **A7/A8/A9** (Edge source, deploy,
  secrets rotation), **A11** (fixtures), **A12** (Firebase), **A13** (client release).
- Copying production data, credentials or keys; any paid upgrade; any `dev` project; pausing or deleting production.
- Deleting or re-creating staging (needs a **new A2** stating why — [04](04-risks-rollback-approvals.md) §2.5).
- Any workaround for the browser limitation (DevTools, REST, CLI, hidden endpoints).

### 3.4 Signature

```text
A2 — CREATE STAGING PROJECT
I approve creating ONE Free/NANO project named 'parent-control-staging' in region 'ap-northeast-2' inside the existing
organisation, as an empty shell plus the one-row sentinel, inside a single 7-day active window. I acknowledge: it uses
the last of 2 active project slots; the name and region are NOT VERIFIED and a failure is reported rather than worked
around; Free projects auto-pause after 7 days; there is no backup or PITR. This authorises no schema load, no patch, no
production change, no Edge deploy, no Firebase action, and no secret value from production.

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 4. Unresolved items — read before signing

Signing A0 and A2 does **not** make the stage executable. These are open and each blocks something specific.

| # | Open item | Blocks | Owner decision needed |
| --- | --- | --- | --- |
| U-01 | P01 pre-check 0.4 expects 1 row per function; the query returns 2 ([patch defects](patch-defects-before-a5.md) D-01) | A5 (P01) | Approve the doc correction; it is documentation only |
| U-02 | P01 §1 commits before its post-check can be read (D-02) | A5 (P01) | Approve the two-pass execution rule or a file revision |
| U-03 | P01 T3 cannot distinguish pre from post state (D-03) | A5 evidence quality | Approve relabel |
| U-04 | P02 has **no rollback in the file**; bodies must be captured from staging first (D-05) | A5 (P02) | Choose: capture-and-record at A5, or revise the file first |
| U-05 | P02 post-checks do not assert `prosrc` hash or overload count (D-06) | A5 (P02) | Approve mandatory manual assertions or a revision |
| U-06 | P02 ships its approval gate commented out; applied text ≠ hashed text (D-07) | A5 evidence integrity | Approve hashing the executed file |
| U-07 | P03 has no rollback in the file (D-10) and its header omits the P02-first and production duplicate-count preconditions (D-11) | A5 (P03) | Approve doc corrections / revision |
| U-08 | Staging name availability | A2 execution | Accept `NOT VERIFIED`; if taken, stop and return |
| U-09 | Region-picker availability | A2 execution | Accept `NOT VERIFIED`; if unavailable, stop and return |
| U-10 | The 7-day active window: G6, G3 and G5-S must fit in one period | A2 scheduling | Name the start date; accept a pause may force a second A2 |
| U-11 | Reviewer pass in a single-owner organisation | A5, A6 | Name who performs it, or accept a time-separated self-review as compensating evidence (R-16) |
| U-12 | Edge Function source: who exports it | Steps 6 and G5-E | Defer (D-11) or name an exporter |
| U-13 | `PAIRING_HASH_PEPPER` presence in production (presence only) | Nothing in Stage 2; affects a future deploy | Answer by presence/name only (R-07) |
| U-14 | P03 accepted only as staging-only with a 500 for a double request | E4 verdict | Accept the staging caveat (R-20) |
| U-15 | Log-query headroom 44.8/100 GB and rising | The whole stage | Accept narrow-window investigation discipline; 80 GB stop line (R-15) |
| U-16 | Firebase ownership: three identities, no Haven project confirmed | G2/G7/A12 | Deferred; no action in Stage 2 ([04](04-risks-rollback-approvals.md) §6) |

**What is *not* unresolved:** the project limit (2, one used), the plan (Free, no upgrade), the slot cost, and the
absence of backups — all VERIFIED. No finding status changed in this pass: Stage 2 closes nothing until evidence exists.

---

## 5. If only one item is signed

- **A0 alone** — G3's method is approved, but nothing can be captured into, because no staging project exists. No
  validation value.
- **A2 alone** — a project can be created and will pause after 7 days unused; G3 and every patch stay blocked. This
  spends the last slot for no evidence, which is why [01](01-staging-project-proposal.md) §7 recommends signing both or
  neither.
- **Both** — G6 → G3 → G5-S may begin inside one window, still subject to U-01…U-07 for A5 and U-08…U-11 for execution.

---

## 6. After signature

Nothing happens automatically. The next action is a change record opened under A2 with the slot check, the window start
and the teardown owner named, followed by G6-a. A0 and A2 are the only approvals this package requests.
