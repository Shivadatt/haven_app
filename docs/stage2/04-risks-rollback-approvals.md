# Stage 2 — risk register, rollback design and approval matrix

**Status: `PROPOSED — NOT APPLIED` for SQL, CLI, deploy, secret and production actions.** No SQL was run, no secret was
set or read, no patch was applied, nothing was deployed, and no production object was changed. **Browser WRITE actions
did occur on 2026-10-30:** the Supabase `parent-control-staging` project and the Firebase `haven-staging` project were
created, and two creation-wizard settings were moved off default — Google Analytics **off** as the owner instructed,
Gemini AI assistance **off** as a declared least-privilege deviation
([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §4.1–4.2). **No rollback has been tested.** Evidence:
[S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) (the creation record),
[S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md), [S2-INSP-02](evidence/S2-INSP-02-firebase-console.md),
[S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md). Everything below is a proposal against the state captured in
Stage 1 plus that inspection and that creation.

> **Superseded (retained as history — FX-01).** The revision-2026-10-30 status line read "no browser action that changed
> a setting: the only browser use was read-only inspection on 2026-10-30". That is false as written: the two project
> creations and the two wizard settings above are write actions. It is corrected above and marked here rather than
> deleted, so the change stays auditable. See §3.1 for the approval consequence.

Consolidates [I-risks-rollback-approvals.md](parts/I-risks-rollback-approvals.md), with the corrections required by
[06](06-redteam-resolution.md) (J-04, J-12, J-14, J-19, J-21). Labels as in [00](00-stage2-execution-plan.md).

**Revision 2026-10-30.** R-22…R-29 were cited by the read-only inspection evidence
([S2-INSP-01](evidence/S2-INSP-01-supabase-org-slots.md), [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md)) before
they existed in this register; they are created here so those citations resolve. R-30…R-35 record the Free-plan
constraints verified on 2026-10-30. No new approval class is introduced.

**Revision 2026-11-02 (S2-DOC-02 — documentation only).** R-36…R-41 record the executed 2026-10-30 actions and their
consequences; **R-42/R-43** were added the same day from the read-only re-confirmation
([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md): the `auth.users` estimate contradiction, and the
standing owner constraint that all Supabase work targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu` only).
**The register now runs R-01…R-43** (it previously ran to R-35). R-09 and R-30 are marked **REALISED**,
R-32 and R-33 **RESOLVED by S2-CREATE-01**; no row text was deleted. No approval row was deleted or softened: executed
actions are reconciled in §3.1 as `AWAITING RETROSPECTIVE RATIFICATION`. Nothing here was signed or dated on the owner's
behalf — approvals are recorded as decisions awaiting signature.

> **Second revision, same day (S2-EXEC-03 pass, corrections C-2/C-5/C-9).** The §3.1 reconciliation above is now
> **decided**: `RATIFIED — 2026-11-02 — OPTION (i)`, recorded and unsigned. §3 rows carry dated status stamps (A0 approved,
> A5 approved-but-not-executable, A1 `INOPERATIVE`, A2′/A3/A9/A12 unsigned), §3.1 statuses are updated in place with the
> original wording preserved, and the register gap that §1 describes is repaired there.
> Still true, unchanged: nothing in this file is signed or dated on the owner's behalf.

---

## 1. Risk register

Likelihood/impact are **INFERRED** judgements, not measurements. Rows marked `REALISED` or `RESOLVED` record an
observed 2026-10-30 state; their original judgement text is retained so the history is readable. Register range:
**R-01…R-43**.

**S2-EXEC-03 (2026-11-02, documentation only).** The range claim was not backed by the rows: **R-41 had no row** while
being cited at §1 `:27`, [00](00-stage2-execution-plan.md) `:318`, [CHANGELOG](CHANGELOG.md) `:55/:80/:160` and
[parts/I](parts/I-risks-rollback-approvals.md) `:161-162`. It is added below **from its existing definitions** —
[S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §I `:318-319` and the parts/I addendum — not invented. The register
now holds 43 rows for 43 identifiers. Historical changelog rows that said "R-01…R-41" are left as written: they
described the state at the end of that pass, and rewriting them would destroy the trail.

| ID | Risk | Trigger | L | I | Detection | Mitigation |
| --- | --- | --- | --- | --- | --- | --- |
| R-01 | Staging drifts from production | The baseline excludes auth settings, the `auth.users` trigger, extensions, Edge bundles, secrets, data | H | H | Re-run the g1-* count/ACL queries against staging and diff; auth-settings checklist; function hash list | G3-d equivalence record; separate `auth.users` trigger file; accepted-differences list; never treat a staging pass as proof for excluded layers |
| R-02 | Dashboard and repo config disagree | `config.toml` declares `public, graphql_public`, `seed.enabled = true` with no `seed.sql`, `project_id = "control"` | H | H | Configuration checklist vs dashboard | Dashboard is production truth; `config.toml` is not used as a source for staging |
| R-03 | Edge source unavailable or minified | `supabase/functions/` absent; 7 of 9 bundles minified; no source maps | H (VERIFIED) | H | Repository listing; SHA of capture vs deployed | P01–P03 are SQL-only and independent; export is a separate approval |
| R-04 | ACL rollback is not byte-identical | Both functions start with `proacl = NULL`; a GRANT leaves an explicit entry | Certain if rolled back | L (behaviour) / M (audit) | `proacl` text before/after | Accept functional equivalence; never `UPDATE pg_proc`; record the difference |
| R-05 | Unique index blocks sessions when expiry lags | Partial index cannot encode `now()`; expired rows keep a live status until something updates them | M | H | Count live-status rows with `expires_at < now()`; `23505` in logs | The insert trigger expires stale rows first; index is only a backstop; read-only production duplicate count before approval |
| R-06 | Function-body replacement error | `CREATE OR REPLACE` drops a statement, changes a signature, or omits `SECURITY DEFINER`/`search_path` | M | H | `prosrc` hash, `pg_get_functiondef`, `prosecdef`, `proconfig`, overload count | Store the captured text offline first; one function per change; staging first; normalised diff |
| R-07 | Pepper mismatch is silent | `PAIRING_HASH_PEPPER` absent, changed, or present in one tier only | M | H | Startup warning; pairing success rate; 401/503 spike | Set the secret before any fail-closed deploy; **never rotate the production pepper in Stage 2**; independent staging secret |
| R-08 | Staging email is rate-limited | Confirm-email on; nine fixtures, six need verified email; Free sender cap NOT VERIFIED | H | M | "email rate limit exceeded" in auth logs | Pre-create fixtures via the admin API with confirmed email (staging only), or disable confirmation and record the deviation |
| R-09 | Two-active-project ceiling — **REALISED 2026-10-30** (was prospective) | Free allows **2 active projects**; production holds one and staging now holds the other (limit VERIFIED 2026-10-30, official plan terms; consumption observed in [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.4) | **REALISED** | H | Organisation page count (`Free Plan · 2 projects`); a create attempt returns a limit error | Limit is 2; **2 active / 2 used / 0 remaining** — staging is no longer "the last free slot", it has taken it; no `dev` project on Free; never pause or delete production to free a slot; no paid upgrade without written approval. Interaction with auto-pause: R-30, R-31, R-38 |
| R-10 | Accidental production action | Two similar dashboard tabs; SQL Editor autocommits; a patch pasted into the wrong tab | M | C | Sentinel refusal message; project ref in every change record; row-count delta; self-captured statement log. **Not `audit_logs`** — that table records app events written by `service_role` functions, not dashboard or SQL-Editor activity, and Free includes no platform audit log (R-27) | `private.s2_environment` sentinel aborts every patch outside staging — **sentinel `NOT CREATED` as at 2026-11-02** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §5: shell only), so until A3 creates it there is no automated refusal to rely on and the manual checks below are the whole control; ref echoed in the change record; explicit transaction; reviewer pass reads the recorded statements |
| R-11 | Test data contaminates production | Fixtures created on production; production rows copied to staging | M | C | Unexplained new profiles/families/devices; counts vs 8/3/14 | Staging only; synthetic identities; no data copy; no production emails |
| R-12 | Client incompatibility | New 409/`42501`/500 responses, CORS allowlist, narrowed columns | M | H | APK smoke on staging; unhandled error codes | Preserve response shapes; map new failures to existing codes before production; APK-level test is **BLOCKED — NO APP SOURCE** |
| R-13 | Rollback text missing for unread bodies | Any change to one of the 11 uncaptured `private` or 12 uncaptured `public` bodies | M | H | Captured `prosrc` count vs 38 | P02 is scoped to the three captured bodies; no extension without a stored original |
| R-14 | Baseline/restore proof stays blocked | G3's documented method needs CLI + Docker; neither is permitted | H | H | G3-d artefact absent | A0 amendment: catalogue capture + reconstruction + staging equivalence; if refused, record `BLOCKED — METHOD NOT PERMITTED` |
| R-15 | Quota/observability exhaustion | Log query **44.8/100 GB** (re-read 2026-10-30; was 33.9 at Stage 1) and rising; verbose or repeated staging investigation. **Observed meter at creation** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.5): `Log Ingestion 0.20 / 1 GB`, `Egress 0.14 / 5 GB`, `DB 32 / 500 MB`, `MAU 10 / 50,000`, `Storage 0 / 1 GB`, `Log Query 44.8 / 100 GB` — these are the figures of record; any other usage numbers in the plan set (e.g. `0.17 GB / 1 GB`, `0.12 GB / 5 GB`) are wrong by observation | H | M | Quota panel before/after each step; log-query refusals; ingestion vs the 1 GB ceiling | Prefer table reads over log scans; narrow windows; treat 80 GB as a stop line; snapshot quota before/after each step; quote only the S2-CREATE-01 §2.5 meter |
| R-16 | Single approver, no separation of duties | One owner for the org; no break-glass | H | M | Change records where one person holds every role | **New in this plan:** compensating evidence per approval (§3), a recorded separate reviewer pass, and a timed window — not a claim of two-person control |
| **R-17** | **Staging restore fails halfway** | Reconstruction DDL errors on statement *n*; project cannot be rebuilt cheaply | M | H | Per-statement restore log | Explicit failure branch — §2.4. Repair in place if the failure is local and understood; otherwise **stop and record**. The former "delete and re-create" branch is **withdrawn (S2-DOC-02, closes the R-25 violation)**: with 0 slots remaining (R-38) it destroys the only non-production target, slot reuse after deletion is UNPROVEN, and whether a PAUSED project counts toward the 2-active cap is NOT VERIFIED. Re-creation is an owner decision only, under a new A2 + A3 (§2.4, §2.5) |
| **R-18** | **Reconstruction artefact carries a literal secret** | 24 `private` bodies were never read; `prosrc` is the one catalogue column that can hold a pasted credential | M | H | Secret scan before the artefact is written | `prosrc` is scanned and redacted **before** the artefact enters the repository; scan result recorded; raw `prosrc` never goes into `evidence/` |
| **R-19** | **Parity check reports P01 as drift after P01 is applied** | The baseline capture records `proacl = NULL`; P01 changes it | Certain after P01 | L | Re-run of the parity check flags two functions | Declare the G3 baseline a **pre-P01 snapshot**; P01 is an approved, recorded divergence, not drift |
| **R-20** | **P03 ships a 500 on a normal user action** | `P0001`/`23505` are unmapped in the deployed handler | H (VERIFIED mapping gap) | M | Staging logs; handler error rate | Production deployment of P03 is blocked until the Edge mapping exists; record the 500 as a known, accepted staging-only outcome |
| **R-21** | **A DB-only rate-limit table is mistaken for a control** | A counter table with no writer looks like mitigation | M | M | Table exists but stays empty | E7 produces no patch in this stage; any future table is labelled inert until a handler writes to it |
| R-22 | The browser session cannot interact with or capture the dashboard | `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`; viewport not attached; `click` and `screenshot` fail — and it did, repeatedly, on 2026-10-30, while **write** clicks on the creation wizards succeeded on retry | H (observed) | M | Tool error string; `visibilityState = hidden` | Accessibility-tree snapshots with exact URL and, where available, a UTC timestamp; **where no UTC timestamp was captured — as in the creation record, which has local display only — the record must say so and no UTC time may be back-filled or inferred**; any step that needs a click and does not get it is recorded `NOT EXECUTED`; **no** DevTools, REST, CLI or other-tool workaround |
| R-23 | Two consoles, two identities | Supabase org owner `spg7753@gmail.com`; Firebase console signed in as `shiwa2172000@gmail.com` | Certain | M | Account shown per console in every capture | Record the account in each evidence header; never infer Firebase ownership from Supabase ownership; no account switching without written authorisation (§6) |
| R-24 | A client-side loading artefact is read as real state | Org page renders `No projects` before data loads, then `1 project`; region picker shows "Loading available regions…" | H | M | Re-read after load; two reads compared | Record both reads and the flicker; only the settled read is evidence; anything still loading stays `NOT VERIFIED` |
| R-25 | Entitlement inferred from an enabled control | "Create project" enabled ⇒ "a second project can be created now" | M | H | Review of evidence wording | An enabled control is at most `INFERRED`; entitlement comes from plan documentation or a completed creation. Slots are settled (R-09: **2 active / 2 used / 0 remaining**); name and region were settled by the completed creations, so R-32 and R-33 are `RESOLVED`. **The inference this row warns against was itself made in §2.4/§3 of this file (slot reuse, delete-and-re-create) and in the plan-of-record status line (FX-01) — both corrected 2026-11-02; R-36/R-38 carry the residue** |
| R-26 | Free-tier feature assumptions | The plan assumes leaked-password protection, single-session/timeouts, branching, backups/PITR or platform audit logs | H (observed) | M | Plan text vs pricing page | Entitlement table in [S2-NEXT-01](evidence/S2-NEXT-01-readiness-report.md) §3; F4 removed from staging scope (R-34); no platform restore assumed (R-35) |
| **R-27** | **No independent screenshot evidence and no platform audit log** | The screenshot tool cannot attach to the viewport; the Free plan does not include platform audit logs; the app's `audit_logs` table records application events only | Certain (observed) | M | Absence is the condition; no detection step can remove it | Every capture keeps its accessibility-tree snapshot with exact URL and a UTC timestamp **or an explicit statement that no UTC timestamp exists**, and is labelled `SCREENSHOT EVIDENCE: NOT VERIFIED`; a snapshot is **never** described as a screenshot, and a screen capture supplied later is likewise **not a platform record**; **no independent screenshot or platform-audit verification may be claimed**, and no audit trail may be cited as corroboration; change records are self-captured and gain their only independent check from the timed reviewer pass (§3, R-16). **Qualification (S2-DOC-02, 2026-11-02):** the absolute wording "no screenshot exists" in [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) is true of the *tool* — `take_screenshot` failed throughout — but the owner has since supplied two captures of the in-app browser (Supabase staging home: Healthy / NANO / no repository / no branches / no migrations / no backups; Firebase `haven-staging` overview). Those are **screen captures, not platform records**: no UTC stamp, and the Firebase one shows a truncated URL so its project ID is not visible. They verify nothing beyond what they show and do not weaken this row's platform-audit-log claim |
| R-28 | Production drifts between inspection and execution | Approval signed days after the read-only capture; counts or ACLs change in between | M | M | Re-run the g1-* count/ACL queries before A3; row counts vs 8/3/14/39 | Inspection evidence is point-in-time; re-verify immediately before A3; any delta becomes a recorded drift, not a silent baseline |
| R-29 | Approval inferred from silence or from a UI affordance | No written A0/A2 reply; "the button was there" | Certain for A0/A2 (observed) | H | Approval package signature block blank | A0 and A2 require explicit written approval; nothing in this programme is approval, including a successful read-only inspection. **REALISED condition: A2's action executed 2026-10-30 on a chat instruction with the signature block still blank, and A0 has never been approved by anyone — the instruction is scope, not approval (§3.1).** *(Superseded wording, annotated 2026-11-02 — corrections C-1/C-5: the clause "A0 has never been approved by anyone" recorded the state at writing. A0 is now **APPROVED as a recorded decision** (method amended to offline reconstruction from the in-repo Stage 1 capture; physical fence still unfilled), and the 2026-10-30 creation is **RATIFIED — option (i)**, which grants nothing forward. The lesson this row carries is unchanged: an instruction is scope, not approval, and no fence is filled here.)* |
| **R-30** | **A Free project auto-pauses after one week of inactivity** — **REALISED 2026-10-30** (the clock is now running; neither project is paused) | Free projects are paused after 7 days without activity (VERIFIED, plan terms); a staging build paused mid-window is unavailable. The clock starts at **creation**, and both projects were created 2026-10-30 ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §4.8) | **REALISED (H while prospective)** | H | Project status banner; connections refuse on a paused project | **A dated dashboard touch on or before 2026-11-06 is required (§2.5).** Plan **G6 + G3 + G5-S as one coordinated window** inside a single 7-day span, with A0/A2 signed before the first action; keep a dated start; if paused, follow the recovery procedure in §2.5; **deleting or re-creating staging requires explicit written approval and a new A2 record**, and the delete branch is withdrawn (§2.4, R-38) |
| R-31 | Staging has consumed the last active-project slot — **REALISED 2026-10-30** | Free allows 2 active projects; production holds one and `parent-control-staging` holds the other (R-09; org list in [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.4) | REALISED | H | Organisation page count `Free Plan · 2 projects` | **2 active / 2 used / 0 remaining.** No `dev` project on Free; only deleting staging frees a slot, deletion is approval-gated (§2.4, §2.5), and slot reuse after deletion is UNPROVEN (R-38) |
| R-32 | Staging name availability is unknown — **RESOLVED by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.1/§2.6** | `parent-control-staging` was never reserved and the creation form was never submitted *(text retained: the pre-creation uncertainty; superseded by the completed creation)* | Resolved | L | Creation attempt returns a name collision | Settled: `parent-control-staging` was accepted and exists under ref `dzonzgngwxclhfnvxtvu`. The `PROPOSED` variant rule no longer applies to Supabase staging; it still applies to any future project name. Firebase note: the display name `haven-staging` was accepted but the **global ID** came back `haven-staging-46822` — display name and ID differ and both are recorded, so later documents do not guess |
| R-33 | Region-picker availability is unknown — **RESOLVED by [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.1/§2.6** | The new-project region list was still loading; `ap-northeast-2` selectability on a new Free project was never observed *(text retained: the pre-creation uncertainty; superseded by the completed creation)* | Resolved | M | Region list once loaded | Settled: `ap-northeast-2` (Northeast Asia, Seoul) was reached via "Need a specific region?" and is the read-only region of the created project. A2's `NOT VERIFIED` region field is now filled from the creation record. Region affects latency/platform defaults, not schema parity |
| R-34 | F4 cannot be tested on Free | Leaked-password protection is not included on the Free plan (VERIFIED, plan terms) | Certain | L | Plan entitlement page | F4 is removed from the staging deviation list and stays `BACKLOG` as a product/plan decision; no toggle experiment is planned |
| R-35 | No automatic backups or point-in-time recovery on Free | Staging or production corruption, or a destructive statement | M | H | Absence is the condition; there is no restore point to check | No platform restore exists. G3's "restore validation" means rebuilding from the reviewed artefact into a clean schema, not a platform restore; every change stays additive or ACL/body-only and reversible by its own patch text; destructive statements are forbidden (C4) |
| **R-36** | **A Firebase project was created although A12 forbids any Firebase action in Stage 2** | On 2026-10-30 `haven-staging` / `haven-staging-46822` was created on the Spark No-cost plan under a direct chat instruction, while A12 assigns Firebase to "Owner, outside Stage 2" ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §3; §3.1) | Certain (executed) | M | §3.1 reconciliation; Firebase project list `1 – 2 of 2` | **CLOSURE GIVEN 2026-11-02 — retrospective owner authorisation recorded as ratification option (i)** (was: `AWAITING RETROSPECTIVE RATIFICATION`). A12's prohibition is amended to "project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited." The closure is *retrospective only*: **A12's forward signature is still absent**, nothing further was done — no app, no credential, no FCM config, no billing change, Analytics off as instructed, Gemini off as a declared deviation; the pre-existing FlutterFlow project and production were left untouched; every other Firebase action remains unapproved |
| **R-37** | **A0/A2 were never signed, yet A2's action was executed under a verbal/chat instruction** | The signable A0/A2 package signature block is blank; A0 **was approved on 2026-11-02 as a recorded decision (its physical fence is still unfilled)** — superseded text: "A0 has never been approved by anyone"; approval can now only **ratify**, not authorise, what already happened | Certain | H | Blank signature block in the approval package; §3.1; the executed creation record | **Decision recorded 2026-11-02 — option (i) RATIFY** ([S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1). The structural consequence is permanent and stays: a retrospective ratification cannot authorise an action in advance, the physical fences remain unfilled, and A3, A5-as-executable, A9, A10, A11, A12 and A13 remain unexecuted. This document never signs or dates an approval for the owner; every subsequent action is gated on its own recorded decision |
| **R-38** | **Zero slot headroom: the only recovery branch spends the target it protects** | Free allows 2 active; 2 are used and 0 remain, so delete-and-re-create, a second staging, or a `dev` project are impossible without destroying the only non-production target; slot reuse after deletion is UNPROVEN and whether a PAUSED project counts toward the cap is NOT VERIFIED | Certain | H | Organisation count `Free Plan · 2 projects`; failed create attempt | §2.4/§2.5 delete-and-re-create branch withdrawn (§2.4 step 3); failures are repaired in place or stopped and recorded; headroom returns only by an owner decision on a paid plan — never by pausing or deleting production |
| **R-39** | **The staging DB password exists with unmanaged custody** | The owner typed the password in the browser ("you type it yourself"); no value entered the repository, this record or the transcript, and no vault or secret manager holds it ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.6) | **NOT VERIFIED** (existence and copies are the owner's to confirm) | H | Any connection attempt failing on auth; a copy surfacing in a file, shell history or paste history | Owner confirms custody; rotate through A9 before any staging connection is used; no agent reads, transcribes, stores or requests the value; any copy made outside the browser is **unrecoverable and un-auditable** by this programme and must be treated as leaked |
| **R-40** | **The auto-pause deadline is running with no recorded start or expiry timestamp and nobody watching the banner** | Free's 7-day idle clock started at creation on both surfaces; only a local display (`Oct 30, 5:25pm`–`6:25pm`) was captured, **no UTC start timestamp was recorded**; no monitoring exists on Free | Likely | M-H | Project status banner on the dashboard — a human read, not an alert | A dated dashboard touch **on or before 2026-11-06** (§2.5) recorded in UTC; G6 + G3 + G5-S in one coordinated window; a PAUSED project's slot cost is NOT VERIFIED, so never pause to test it (R-38) |
| **R-41** | **Status lines in the plan of record contradict ground truth, so a reader attempts an action believed prohibited, or skips one that is still required** | Definition carried over from [S2-REVIEW-03](S2-REVIEW-03-independent-audit.md) §I ("Certain / M") and echoed in [parts/I](parts/I-risks-rollback-approvals.md)'s addendum as "falsified status lines across the plan of record". The realised instances are the `STAGING PROJECT NOT CREATED` banner still standing after the 2026-10-30 creation, approvals A0/A1/A2 recorded as held when no signature exists, and A1 surviving as an A3 precondition after the staging-only instruction (C2b) made it inoperative | Certain (observed) | M | Read the live file, never a summary line; re-check each identifier per pass; the register's own range claim is testable against its row count (it failed exactly this test for R-41) | Documentation reconciliation only: corrections C-1…C-12 of [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §7, applied in the S2-EXEC-03 pass, each traced to a recorded owner decision rather than a new judgement; every status statement carries the evidence it comes from. No operational action closes this risk — a contradicted status line is repaired by reading the source |
| **R-42** | **The clean-shell premise is unproven for `auth.users`: the dashboard prints a non-zero estimate over an empty grid** | Staging Auth → Users renders `Total: 10 users (estimated)` with **zero rows**, while the same page on production prints an exact `Total: 8 users`; `public` has 0 tables and `No migrations`, so an empty `auth.users` is the expected state but is not observed ([S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §3, FX-18) | Likely (display artefact) / **NOT VERIFIED** (the underlying count) | M | A re-navigation reproduces the figure; the org `Monthly active users` meter has read 10 since before staging existed and has not moved | One approved read-only statement closes it — `select count(*) from auth.users;` on ref `dzonzgngwxclhfnvxtvu` as the **first** action of the A3 window ([approval-package-v2](approval-package-v2-ratification-and-forward.md) §3.4 preconditions). **Owner decision B-3 (2026-11-02, option A) fixes that read inside A3's scope — not under A1 (now `INOPERATIVE`) and not as an unapproved housekeeping query — so with A3 unsigned the count has NOT been run and this risk stays OPEN.** Until then: any claim that staging "has no auth users" is `NOT VERIFIED`; P01 §0.4's pre-check and the "0 rows, so a wrong-project run is impossible" arguments are conditioned, and a non-zero count **stops the load** |
| **R-43** | **Supabase scope creep: an action lands on the wrong project, and production is the only other target** | Two dashboards are open at once and the owner instruction of 2026-11-02 restricts all Supabase work to `parent-control-staging` / `dzonzgngwxclhfnvxtvu`; 0 slots remain, so a mistaken second project cannot be created and a mistaken statement on `parent-control-prod` cannot be undone with a restore point | M | **Catastrophic** | Console header versus the ref quoted in the change record; SQL Editor tab | **Standing owner constraint, recorded 2026-11-02:** every Stage 2 Supabase action — dashboard page, SQL Editor tab, setting, patch, test — targets `dzonzgngwxclhfnvxtvu` **only**. No other project may be opened except for a documented read-only comparison, and none may be written to. Echo the ref from the console header before any statement runs; the sentinel gate is a backstop, not a licence. **Amended 2026-11-02 (C-2):** this row's earlier exception — "no other project may be opened *except for a documented read-only comparison*" — **is closed**. The owner restated C2b as an absolute (F-5-A), so a production comparison read is prohibited, not merely unapproved; the two clauses disagreed and the stricter one governs. The one production page opened on 2026-11-02 before that restatement is disclosed at 00 §0 and [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1.6 and is not repeated |

---

## 2. Rollback

Preconditions for any rollback: the captured pre-state exists offline; the rollback text was reviewed with the patch; a
production rollback needs the same approval class as the forward change. Order is reverse of apply: **P03 → P02 → P01**.
Rolling back a security fix re-opens the path it closed.

### 2.1 S2-P01 — ACL and `search_path`

Full text: [03](03-patch-S2-P01.md) §7, also present commented inside
[`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql) §2.

| Field | Answer |
| --- | --- |
| Reversal | `grant execute … to public` ×2; `alter function … set search_path = public, pg_temp` |
| Behaviour vs exact | **Behaviour restored; ACL not byte-identical** (`proacl` becomes explicit instead of `NULL`) |
| Data loss | None |
| Time | ≤5 min |
| Verification | Effective EXECUTE true again for `anon`/`authenticated`; `prosrc` hash unchanged; `proconfig` restored |
| Consequence | Re-opens E2/F8; requires A10 and a recorded reason |

### 2.2 S2-P02 — three bodies + membership check + `search_path`

| Field | Answer |
| --- | --- |
| Reversal | `create or replace` each of the three functions with the **stored pre-apply text** captured from the staging catalogue immediately before apply; restate `SECURITY DEFINER` and the original `search_path`; restore `request_remote_session` to `search_path = public, pg_temp` |
| Behaviour vs exact | Exact behaviour; definition text exact only if formatting is preserved; OID and ACL survive `CREATE OR REPLACE` |
| Data loss | None. Audit rows already written by a forged actor are not corrected; that is a separate data decision |
| Time | 10–15 min including three staging calls |
| Verification | `prosrc` hash equals the stored capture; `prosecdef = true`; `proconfig` restored; no new overload; legitimate `service_role` call still succeeds |
| Consequence | Re-opens E1/E3; requires A10 |

### 2.3 S2-P03 — single-live-session enforcement

Actual object names in the patch: function `private.remote_session_insert_guard()`, trigger
`remote_sessions_insert_guard`, index `remote_sessions_one_live_per_device`.

| Field | Answer |
| --- | --- |
| Reversal | `drop trigger if exists remote_sessions_insert_guard on public.remote_sessions;` → `drop function if exists private.remote_session_insert_guard();` → `drop index if exists public.remote_sessions_one_live_per_device;` |
| Behaviour vs exact | Exact pre-patch state if the change was purely additive: objects absent, table and rows unchanged, no ACL restored (the guard is owner-only, matching the five sibling trigger functions) |
| Data loss | None on rollback. Rows expired by the trigger stay expired — rollback restores behaviour, not data. Duplicates created while enforcement was off are not removed |
| Time | <2 min at ~39 rows |
| Verification | `pg_indexes`/`pg_trigger` show the objects absent; two live inserts for one device are accepted again in staging |
| Consequence | Live E4 defect returns. If the Edge handler was changed too, revert both together |

### 2.4 Staging failure branch (new — J-12)

Applies to the baseline load (step 2) and to any patch apply:

1. **Stop.** Do not continue past the failing statement; the apply is in one transaction where possible, so `rollback`
   restores the prior state.
2. **Classify.** Local and understood (a missing extension, an ordering error, a privilege the owner lacks) → repair in
   place and re-run the failed section. Not understood → do not improvise.
3. **Decide.** Repair-in-place has a time box of one working session. Beyond it, **stop and record the state — the
   delete-and-re-create branch is withdrawn** (S2-DOC-02, closing the R-25 violation this file previously committed: it
   recommended deletion on an *inferred* slot reuse). With **2 active / 2 used / 0 remaining** (R-09, R-31, R-38),
   deleting staging destroys the only non-production target and there is no slot left to re-create into; slot reuse
   after deletion is UNPROVEN (nothing has been deleted to test it), and whether a PAUSED project still counts toward
   the 2-active cap is `NOT VERIFIED` (§2.5). Deletion is therefore **never** an agent-chosen recovery step: it is
   authorised only by the owner, in writing, with a new A2 record stating that the first attempt failed and why.
   Deleting staging is also the only way to free a slot, so it is never done to "start clean".
4. **Record.** The failed attempt stays in the change record. A failed change becomes a finding, never a silent retry.

### 2.5 Paused-staging recovery and re-creation (new — R-30)

Free projects pause after 7 days without activity. Pausing is not deletion, and the recovery step is different.

**The clock is now running (FX-16b).** Both new projects — Supabase `parent-control-staging` and Firebase
`haven-staging` — were created on 2026-10-30, and the creation record states the Free 7-day idle timer from creation on
both surfaces ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §4.8), so a **dated dashboard touch on or before
2026-11-06** is required. **No document records a start timestamp:** the record captured only the local display
`Oct 30, 5:25pm`–`6:25pm`, never a UTC start, so **no record states the exact expiry** — 2026-11-06 is the latest date
the touch can fall on, not a measured deadline. Whether a **PAUSED** project still counts
toward the 2-active cap is `NOT VERIFIED` (Free plan terms were read as "active projects"; the paused-state arithmetic
was never observed, and it must not be tested, because the only non-production target would itself be the test object). **Consequence: the
delete-and-recreate branch must not be attempted** (R-38, §2.4 step 3) — it is not a recovery procedure, it is an
irreversible owner decision.

| Situation | Action | Approval |
| --- | --- | --- |
| Staging paused mid-window | Open the project in the dashboard and restore it; then re-verify before continuing: `private.s2_environment = 'staging'`, table/policy/function counts, and the last applied patch's post-check *(no sentinel exists yet and the schema is empty — 0 tables — so the first two checks have nothing to read until A3 runs; see §4)* | None beyond the existing A5 window; the pause and resume are recorded in the change record |
| Paused and unrecoverable | Stop the window; record the state; **do not delete** and do not create a replacement in the same session — 0 slots remain (R-38) | New A2, in writing |
| Deletion or re-creation considered for any reason | Owner states the reason (failed load, unrecoverable pause, corrupted schema), confirms the slot arithmetic (**2 active / 2 used / 0 remaining**; slot reuse after deletion UNPROVEN; whether a PAUSED project counts toward the cap `NOT VERIFIED`), and accepts that the G3 load and any applied patch must be redone | New A2 + A3; the previous records stay on file as history |
| Teardown at end of stage | Export redacted evidence and the fixture manifest first; then delete; record ref, date, operator; confirm production untouched | A2's teardown line, agreed **before** creation — *not agreed yet: A2 is unsigned* |

The 7-day clock starts at project creation, not at the first patch. Creation is recorded as 2026-10-30 with no UTC start
timestamp, so the clock's first hard obligation is the **dated touch on or before 2026-11-06** above. That is why G6, G3
and G5-S are planned as one coordinated window rather than three separate ones.

---

## 3. Approval matrix

The approver is the single owner in every row; no second approver exists (R-16). A "reviewer" is a separate, recorded
checklist pass performed at a different time from the change, with its own notes — **not** a claim of two-person control.
Evidence is stored with the change record and never includes a secret value.

> **Status stamps recorded 2026-11-02 (S2-EXEC-03 pass, corrections C-2/C-5).** Ratification: **option (i)** — recorded,
> no signature fence filled. **A0 approved** (method amended to offline reconstruction from the in-repo Stage 1 capture).
> **A5 approved but not executable.** **A1 `INOPERATIVE`** (void under the owner's staging-only absolute — F-5-A/C2b).
> **A2′, A3, A9, A12 unsigned.** No row below is rewritten: each carries its own date so the history stays readable.

| # | Action | Approver | Compensating evidence | Forbidden |
| --- | --- | --- | --- | --- |
| **A0** | Amend G3's method (catalogue capture + reconstruction + staging equivalence) | Owner, in writing — **APPROVED 2026-11-02** as a recorded decision; the physical fence in [approval-package-v2 §3.1](approval-package-v2-ratification-and-forward.md) is unfilled. **The method itself was amended again on 2026-11-02 (C-1): reconstruction is from the in-repo 2026-10-29/30 capture, not a fresh production read** | Signed amendment text in the change record; the superseded method quoted | Claiming G3 is "passed" while the method is unamended |
| A1 | Read-only introspection, staging or production — **`PROHIBITED / INOPERATIVE` (2026-11-02, C-2)**: void in substance under the owner's staging-only absolute, so this row cannot be signed into effect within Stage 2 | Owner | Query text (read-only), project ref, result file path | Any DDL/DML; reading table data; exporting PII |
| A2 | Create (or re-create) the staging project | Owner — **signature block UNSIGNED**; the action was nevertheless executed 2026-10-30 under a chat instruction, so this row can now only be **ratified**, never honoured in advance (§3.1, R-37). **Ratified 2026-11-02, option (i)** | Slot check (**2 active allowed / 2 used / 0 remaining**), cost statement (Free / NANO), ref, single 7-day active window stated, no production data, synthetic-seed plan. **Executed scope was narrower than this row's evidence fields: "shell only" — the `private.s2_environment` sentinel, the settings checklist and the secrets inside A2 were NOT done** ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2, §5) | Copying production data; paid upgrade; creating a `dev` project too; deleting staging to "start clean"; re-creating without a new A2 recording why |
| A3 | G3 catalogue capture and schema load — **UNSIGNED**, and **not executable**: the reconstructed artefact is `NOT LOAD-READY` (0 of 24 absent function bodies invented, 0 return types captured) | Owner. **A1 is no longer a precondition of A3** (C-2); the chain is **A2′(a) executed → A3 load → A2′(b)**, and the FX-18 `auth.users` count sits **inside** A3 (decision B-3) | Capture file hash, secret-scan result, restore log, equivalence table | Loading table data; `--role-only`; hand-editing the artefact after scan |
| A5 | Apply P01 / P02 / P03 to staging | Owner + reviewer pass — **APPROVED 2026-11-02 but NOT EXECUTABLE**: P02 aborts unconditionally under D-07, and P03 needs the production duplicate count that A1 can no longer authorise (C-2) | Patch hash, §0 output, post-check output, test results, rollback text | production; touching unread bodies; secrets |
| A6 | Apply any patch to production | Owner + reviewer pass, stated window | Staging evidence, 7-item gate, rollback offline, row-count snapshot | agents executing SQL; ad-hoc editor SQL; bundling a client/Edge change |
| A7 | Export Edge source | Owner (credential) | Export output, SHA list, commit, no secret in tree | Editing live functions in the dashboard; deploying from a minified bundle |
| A8 | Deploy an Edge Function | Owner + Edge reviewer | Repo diff, staging function test, error-shape compatibility | Production deploy by an agent; deploying untested source |
| A9 | Set or rotate any secret | Owner only | Secret **name**, digest from the secrets list, sequence (set → verify → deploy) | Reading/pasting values; rotating the production pepper in Stage 2 |
| A10 | Roll back any patch | Owner + reviewer pass, incident note | Stop condition, exact reversal, data-loss statement, post-rollback verification | Improvised catalogue updates; restoring PUBLIC without security sign-off |
| A11 | Create test fixtures | Owner (staging only) | Synthetic fixture list, no production identifiers, deletion plan | Any test user/family/device in production |
| A12 | Firebase / FCM | Owner, outside Stage 2 — **UNSIGNED as a forward block** | G2 decision | Any Firebase action in Stage 2 — the prohibition **was amended on 2026-11-02 by ratification option (i)** to: **"project creation permitted under owner instruction; app registration, FCM configuration, credentials and settings changes remain prohibited."** The 2026-10-30 `haven-staging` creation is reconciled in §3.1 as **`RATIFIED — 2026-11-02 — OPTION (i)`** (recorded, not signed); no app, credential, FCM config or billing action was taken, and the amended wording grants nothing forward |
| A13 | Client release | Product owner | Staging APK smoke, error-code map, rollout plan | Shipping against an untested staging build |

### 3.1 Executed-action reconciliation (added 2026-11-02 — FX-02)

Nothing in the matrix above was rewritten or removed. History is not edited silently: the actions actually executed on
2026-10-30 are reconciled here against the row that should have gated them.

> **Annotation (2026-11-02, S2-EXEC-03 pass, corrections C-2/C-5).** The rule above still binds the *history*, not the
> *status*: the §3 rows now carry dated status stamps (ratification, A0/A5 approved, A1 `INOPERATIVE`, A2′/A3/A9/A12
> unsigned) and, where an approval clause itself changed — A12's prohibition — the amended wording is quoted alongside the
> original rather than replacing it. No executed action below is deleted, and no row is described as signed.

| Executed action (2026-10-30) | Evidence | Approval row it falls under | Status |
| --- | --- | --- | --- |
| Supabase `parent-control-staging` created — empty shell: 0 tables, no migrations, 0 Edge Functions, auto-expose OFF, **no sentinel, no schema, no secrets** | [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2 | A2 *describes* this action, but A2 was **never signed** | **`RATIFIED — 2026-11-02 — OPTION (i)`** (recorded; A2's forward signature still absent) |
| Firebase `haven-staging` / `haven-staging-46822` created — Spark No-cost, Analytics off, Gemini off, **no apps, no credentials** | [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §3, §4.1–4.4 | **None** at the time. A12 then forbade any Firebase action in Stage 2; no other row covered creating a project on another platform. The ratification amended A12 to permit **project creation under owner instruction only** | **`RATIFIED — 2026-11-02 — OPTION (i)`**; the project still exists and **A12 itself is unsigned** |
| Two creation-wizard settings moved off default — Analytics off (instructed), Gemini AI assistance off (declared least-privilege deviation) | [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §1, §4.1–4.2 | **None** — no approval row lists wizard settings | **`RATIFIED — 2026-11-02 — OPTION (i)`** for the executed creation; the Gemini deviation stays recorded as a deviation |
| Owner scope answers recorded: Supabase "shell only"; DB password "you type it yourself"; Firebase "create haven-staging, Analytics off" | [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §1 | Instructions, **not approvals**. Superseded wording (this row formerly read "A0 has never been approved by anyone"): **A0 was approved 2026-11-02** and its method amended the same day (C-1) | Not an approval |
| SQL executed; patch applied; sentinel or settings checklist created; secret set; app registered; credential exported; Edge deployed; any production change | — | n/a | **NOT DONE — none of this occurred**: A3, A5, A9, A10, A11 and A13 remain unexecuted. A12's clause, by contrast, **was** breached by the Firebase creation in row 2 above, and it stays unapproved |

**What ratification is and is not.** Ratification is an owner decision recorded after the fact. **This document cannot
make that decision, cannot sign it and cannot date an approval on the owner's behalf** — it records only that the
decision is outstanding (R-36, R-37). Ratifying the creations grants nothing further: it does not authorise schema,
sentinel, settings, secrets, apps, credentials, Edge Functions, G2/G7 Firebase work, or any production change. Until the
owner records a decision, every prohibition in the matrix stands exactly as written.

### 3.2 Global prohibitions

For every row and every agent: production SQL, production Edge deployment, any secret value, any Firebase action, project
deletion or re-creation, and any attempt to work around the browser-only limitation (DevTools, REST, CLI, hidden
endpoints — R-22, R-27). **Status of each clause as at 2026-11-02:** production SQL, Edge deploy, secret values and
project deletion or re-creation — **not breached, none occurred**; "any Firebase action" — **breached on 2026-10-30** by
the `haven-staging` creation, reconciled in §3.1 and awaiting the owner's retrospective decision. Approval for A6 never
implies A8, A9 or A12. No approval is inferred from silence, and none is signed or dated here on the owner's behalf.

---

## 4. Production release gate — 7 items (revised)

Release may start only when all seven are evidenced in one change record. "Green" means observed in staging, not inferred.
Item 3 is revised from the working paper: it no longer demands a 409 that the deployed handler cannot produce
([06](06-redteam-resolution.md) J-09).

**Gate status as at 2026-11-02: item 4 is `BLOCKED`, not passed, and item 1 cannot start.** Staging exists as an empty
shell — 0 tables, no migrations, no sentinel, no schema, no secrets ([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md)
§2.2–2.3) — and A0, A1 and A3 do not exist as signed approvals, so there is no parity target to build, no capture to load
and nothing against which to rehearse. Items 3 and 5 inherit the same block. Nothing below the header of this section may
be read as green.

> **Status restatement after the 2026-11-02 owner decisions (S2-EXEC-03 pass; corrections C-1/C-2).** The verdict is
> unchanged — **every item below is still blocked** — but the *reason* is now precise. **A0 exists as a recorded approval**
> (fence unfilled) and its method was amended to offline reconstruction from the in-repo Stage 1 capture. **A1 is
> `INOPERATIVE`** (void under the staging-only absolute), so no fresh production capture is available or permitted.
> **A3 is unsigned**, and separately the reconstructed artefact measured on 2026-11-02 is **`NOT LOAD-READY`** — 459 active
> statements of which **0** create a function, trigger, policy or publication, because 24 of 38 bodies and all 38 return
> types are absent from the evidence. Item 1 is therefore blocked by an unsigned A3 *and* by a baseline that cannot be
> completed from available evidence (blocker B-17), not by a missing A0 signature.

1. **Staging parity** — `BLOCKED — CANNOT START UNTIL A0, A1 AND A3 EXIST` *(the parenthetical "A0 has never been approved by anyone" is superseded wording, annotated 2026-11-02 under C-1/C-2: A0 is approved as a recorded decision with the fence unfilled, and A1 is `INOPERATIVE`)*.
   Staging built from the reviewed G3 capture plus the separate `auth.users` trigger file; count and
   ACL queries re-run and diffed; every difference listed and accepted; **the baseline is declared a pre-P01 snapshot**
   (R-19).
2. **Frozen patch set** — P01, P02 (three bodies only) and P03 SQL final, hashed and reviewed; no unread body touched; no
   secret or Edge deploy bundled.
3. **Staging rehearsal green** — `anon`/`authenticated` EXECUTE false on both P01 objects; legitimate `service_role` paths
   succeed; duplicate session is rejected by the trigger (**user-visible code recorded as 500, and accepted as a staging
   caveat, not a release claim**); no unhandled error shape beyond the recorded one.
4. **Rollback rehearsed in staging** — **`BLOCKED`, NOT PASSED: rehearsal is impossible on an empty schema.** Apply,
   reverse, re-apply; times recorded; ACL/body/`proconfig` comparisons; explicit statement of what is not byte-identical
   and what data is not restored. With 0 tables and no loaded functions there is no object to apply, reverse or compare,
   so this item requires A3 (schema load) and A5 (patch apply) first; **no rollback has been tested anywhere in this
   programme** (§status).
5. **Baseline and recovery posture** — G3 artefact restored and equivalence-proven, or a written acceptance that restore
   is unproven.
6. **Window and observability** — owner and reviewer pass named, window stated, logs open, alert destination set, quota
   numbers recorded, stop conditions read aloud.
7. **Written approval and change record** — A6 signed, project ref `hhqgreaoqulmfwfwarhc` stated, forbidden actions
   acknowledged, post-change verification owner named.

**Additional gate item for P03 specifically:** no production deployment until an Edge mapping for `P0001`/`23505` exists
and is deployed. Without it, P03 converts a normal double-request into a 500 (R-20). If the mapping cannot be produced in
this stage, P03 stays a staging-only patch and E4 stays **PARTIAL**.

**Stop conditions — abort, do not "finish the window":** sentinel mismatch; unexplained staging/production drift; staging
unavailable; patch hash differs from review; PUBLIC/`authenticated` EXECUTE still true after P01; forged actor not
rejected where a reachable principal exists, or a legitimate call fails; a valid request returns `23505`/500 where it
previously succeeded; non-empty baseline diff; production data in staging or a test account in production; any secret or
pepper change or a 401/503 spike; rollback text missing or unrehearsed; a client crash or unhandled error code; log query
>80 GB or database >400 MB; no reviewer pass recorded; any request to exceed this matrix.

---

## 5. Change-record template

```text
CHANGE ID: S2-<nnn>            DATE/TIME (UTC):            OPERATOR:
ENVIRONMENT / PROJECT REF:                                 APPROVER + REVIEWER PASS:
PATCH / ACTION:               HASH OF SQL OR DIFF:
MOTIVATION (finding IDs):     SCOPE (objects, functions, rows):
PRE-STATE EVIDENCE:           ACL / prosrc hash / proconfig / row counts / equivalence table:
STAGING EVIDENCE:             test IDs, results, APK version, timestamps:
PRODUCTION PRE-CHECKS:        ref confirmed, sentinel, read-only checks, quota, window:
EXACT STATEMENTS APPLIED:     (verbatim, numbered)
EXPECTED EFFECT:              VERIFICATION (per statement):
ROLLBACK TEXT + TIME:         DATA-LOSS STATEMENT (none / which rows):
OBSERVED SIDE EFFECTS:        QUOTA DELTA:
DECISION:                     KEEP / ROLLBACK / FORWARD-FIX
FOLLOW-UPS / NEW RISKS:       EVIDENCE PATHS:
SIGN-OFF:                     OPERATOR:            APPROVER:            REVIEWER PASS:
```

No record closes while a verification cell is blank or a follow-up lacks an owner.

**Fill-in values of record (added 2026-11-02, from [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md)):** staging
project `parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, region `ap-northeast-2`, Free / NANO, Postgres
`17.11.0.003` / Auth `2.197.0` / PostgREST `14.18`; production `parent-control-prod`, ref `hhqgreaoqulmfwfwarhc` — never
a staging target; Firebase display name `haven-staging`, project ID `haven-staging-46822`, project number `381273275501`,
Spark No-cost; slots **2 active / 2 used / 0 remaining**. The `private.s2_environment` sentinel is `NOT CREATED`, so no
change record may cite a sentinel check until A3 creates it; quota cells take the S2-CREATE-01 §2.5 meter, not earlier
figures.

---

## 6. Firebase ownership — decision note

**Status: `RECORDED — NO ACTION AUTHORISED`.** This section records an ownership split; it does **not** approve G2, G7 or
A12, and it authorises no Firebase project, app, FCM credential, configuration or billing change. Evidence:
[S2-INSP-02](evidence/S2-INSP-02-firebase-console.md), read-only. **Capture channel corrected 2026-11-02 (C-9):** that
file is **not** labelled as an accessibility-tree capture — it is verbatim page text, and its screenshot status is
`NOT VERIFIED`, so no accessibility-tree provenance may be claimed for it.

**Update (S2-DOC-02, 2026-11-02).** The table below is the S2-INSP-02 read taken earlier on 2026-10-30. Later the same
day a Firebase project **was created** under the inspected identity — `haven-staging` (project ID `haven-staging-46822`,
number `381273275501`), Spark No-cost, Analytics off as instructed, Gemini assistance off as a declared deviation,
environment type left `Unspecified`, **no apps and no credentials**
([S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §3, §4.1–4.4). That creation is reconciled in §3.1 as
`AWAITING RETROSPECTIVE RATIFICATION` **— status updated the same day: `RATIFIED — 2026-11-02 — OPTION (i)`, recorded in
[S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1; see §3 and §3.1 (correction C-5)**: it is an executed action,
**not** an approval, and this section still authorises
nothing. The pre-existing FlutterFlow demo project was not opened, renamed or modified.

| Fact | Value | Label |
| --- | --- | --- |
| Supabase console identity | `spg7753@gmail.com`, org `symqztrmaziuwdibcfrq`, owner of `parent-control-prod` | VERIFIED |
| Firebase console identity (inspected session) | `shiwa2172000@gmail.com` | VERIFIED |
| Firebase projects visible to that identity | one: `FlutterFlowWIthFIreBase` / `flutter-flow-w-ith-f-ir-6592ib` *(the S2-INSP-02 read; later that day the same list showed `1 – 2 of 2`: `haven-staging` plus the demo — S2-CREATE-01 §3.3)* | VERIFIED for the read; superseded same day |
| Relationship of that project to Haven | none — it is a third-party demo project and **must not be reused, renamed or reconfigured** | PROPOSED (owner judgement required) |
| Haven Firebase project under the inspected identity | none visible at the S2-INSP-02 read *(superseded: `haven-staging` / `haven-staging-46822` was subsequently created under this identity — created is not approved, §3.1)* | VERIFIED for the read; **created ≠ authorised** |
| CLI identity seen in repository context | `om-event*` (a third address again) | VERIFIED as a string; role NOT VERIFIED |

**Consequences carried by this note:**

1. **Three identities, not one.** Supabase, Firebase console and CLI are not the same account. Evidence captured under
   one identity says nothing about the other two, and Stage 1's "single owner for every row" holds for the **Supabase**
   rows only — not for the Firebase rows.
2. **No Haven Firebase project was confirmed by the inspection.** "None under the inspected account" was not "none
   exists"; a different Google account could own one and was not inspected. **Correction (2026-11-02):** a Haven staging
   Firebase project now exists under the inspected account because it was created there on 2026-10-30 — an executed
   action awaiting retrospective ratification (§3.1), not a confirmed pre-existing asset.
3. **G2/G7 and A12 stay deferred.** Choosing, creating or migrating a Firebase project is an owner decision outside
   Stage 2. Nothing here is a decision to create `parent-control-staging`'s counterpart in Firebase — staging is SQL-only
   by [01](01-staging-project-proposal.md) §4. **Correction (2026-11-02):** such a counterpart was nevertheless created on
   2026-10-30 without an approval row (§3.1, R-36); this consequence remains the policy, and A12/G2/G7 stay closed —
   no app, credential, FCM configuration or billing action exists.
4. **Account switching is not authorised.** Any future Firebase inspection must name the account first and be approved
   separately; this note is not that approval.
5. **No credential crosses.** No FCM server key, service-account JSON, API key or Google-services file was read, copied
   or referenced.

---

## 7. Open questions

1. ~~Is the Free-plan project limit actually 2, and is staging the last slot?~~ **ANSWERED 2026-10-30** — **2 active /
   2 used / 0 remaining**: production holds one and `parent-control-staging` holds the other (R-09, R-31,
   [S2-CREATE-01](evidence/S2-CREATE-01-new-projects.md) §2.4). ~~Name and region remain `NOT VERIFIED` (R-32, R-33)~~ —
   **R-32 and R-33 are RESOLVED by S2-CREATE-01**: `parent-control-staging` under ref `dzonzgngwxclhfnvxtvu`, region
   `ap-northeast-2`, both read from the created project's settings page. (The earlier wording "1 used, staging is the
   last slot" was written before the creation and is corrected here, FX-03.)
2. ~~Will the owner sign A0, or is G3 formally accepted as unclosable for Stage 2? (R-14)~~ **ANSWERED 2026-11-02** — **A0 is
   approved as a recorded decision** and the method amended to offline reconstruction (correction C-1); the physical fence
   stays unfilled. Superseded wording: "A0 has never been approved by anyone, and A2's action has already executed with its
   signature block blank — ratification, not advance authorisation, is what remains (§3.1, R-37)." That structural point
   still holds for **every later block**: a recorded decision cannot become an advance authorisation.
3. Is `PAIRING_HASH_PEPPER` present in production? (Presence only — never the value.) (R-07)
4. P03: does the owner accept a staging-only patch with a 500 for one release, or is the Edge mapping a prerequisite for
   even staging acceptance? (R-20)
5. Is `Haven-1.2-release.apk` the compatibility baseline, given 1.0 uses a different signing key? (R-12)
6. Who performs the reviewer pass, and is a time-separated pass by the same owner acceptable as compensating evidence?
   (R-16)
7. Does the owner accept that the G6 → G3 → G5-S window must fit inside one 7-day active period, and that a pause or
   failure inside it may force a second A2? (R-30) **The clock started at creation on 2026-10-30, so a dated dashboard
   touch on or before 2026-11-06 is already required (§2.5); and a failure inside the window can no longer be answered
   with a re-creation — 0 slots remain (R-38, §2.4).**
8. ~~Does the owner **retrospectively ratify** the 2026-10-30 executions — the Supabase staging shell and the Firebase
   `haven-staging` project — and in what recorded words?~~ **ANSWERED 2026-11-02 — option (i) RATIFY**, recorded in
   [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1 and §3/§3.1 above, with the amended A12 sentence quoted there.
   Superseded wording: "This file records the decision as outstanding". This file still signs or dates nothing on the
   owner's behalf, and the ratification grants nothing forward. (R-36, R-37, §3.1)
9. Who holds the staging database password, and does any copy exist outside the browser? Unconfirmed custody is treated
   as `NOT VERIFIED`; rotate under A9 before any staging connection is used. (R-39)
10. Does the owner want the Firebase environment type moved from `Unspecified` to `Staging`, and is anyone watching the
   Supabase status banner for the auto-pause? Neither setting has been changed — both need authorisation first. (R-40)

---

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed on the owner's
behalf.
