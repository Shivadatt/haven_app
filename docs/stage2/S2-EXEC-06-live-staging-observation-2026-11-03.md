# S2-EXEC-06 — Live staging observation record (browser-only)

| Field | Value |
| --- | --- |
| Date | 2026-11-03 |
| Author | Main agent (owner-directive execution, "not use cli use browser access") |
| Purpose | Dashboard evidence for every claim of staging state, and the exact list of what is blocking writes |
| Method | `browser-use` MCP only: `navigate_page` + `take_snapshot` (incl. one `verbose`), zero CLI, zero terminal, zero REST, zero curl, zero direct DB connection, zero DevTools console |
| Targets observed | Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` · Firebase `haven-staging` / `haven-staging-46822` |
| Production | `parent-control-prod` / `hhqgreaoqulmfwfwarhc` — **not opened, not navigated to, not contacted.** Every observed URL carries the staging ref; each page header was read back as `parent-control-staging` before the snapshot was taken |
| Cloud writes performed | **Zero.** See §1 for the two independent reasons |
| Timestamps | Date-level only. Minute-precision clock readings would require a terminal call, which the brief prohibits; no fabricated times appear in this file |
| PII / credentials | No email address, account identifier, API key, JWT, service-account key or user row is reproduced here. The dashboard page titles for Supabase carry the owner's account address; it is deliberately omitted from every line of this file |

---

## 1. The two blockers, stated before any observation

**Blocker A — mechanical, and it is absolute right now.** Every pointer or keyboard action against the dashboard fails with
`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE: … viewport=524x553, visible=false, attached=false, cdpAttached=true, visibilityState=hidden`.
Reproduced three times against three different elements (a list-refresh button, a view-mode toggle, and a page control). URL
navigation and accessibility-tree snapshots succeed; **click and type do not**, because the in-app Browser surface is not
attached. Consequence, stated plainly: *even a fully signed approval could not be executed in this session state.* Not one
provider toggle, not one "Add user", not one "Generate key", not one SQL Editor paste. The owner must make the Qoder
in-app Browser panel visible (attached, non-zero viewport) for any cloud write to be physically possible.

**Blocker B — governance.** `A2′(a)`, `A2′(b)`, `A3`, `A9`, `A12`, `A7`, `A8` remain UNSIGNED, and the owner's new
implementation directive does not sign them (brief §7: "The new owner direction does not automatically sign these existing
approval fences"). The signable instruments for each are on disk at
[`docs/stage2/approval-package-v3-implementation-instruments.md`](file:///D:/control/docs/stage2/approval-package-v3-implementation-instruments.md)
(9 instruments; all 9 fences published blank with `STATUS: UNSIGNED`).

These are independent. Clearing B does not clear A; clearing A does not clear B.

---

## 2. Firebase `haven-staging` — observed state

| Surface | URL | Observed | Status vocabulary |
| --- | --- | --- | --- |
| Overview | console.firebase.google.com/project/haven-staging-46822 | Project exists; Environment type "Unspecified" | CONFIGURED (project only) |
| Authentication | `…/authentication/users` | "Get started" screen — **Firebase Authentication is not enabled**, no provider configured, no users | NOT STARTED |
| Apps | `…/settings/general` | **Zero registered apps** — no Android, no iOS, no web. No `google-services.json` exists to download | NOT STARTED |
| Cloud Messaging | `…/settings/cloudmessaging` | **FCM API (V1) is already Enabled.** Legacy FCM API Disabled. Sender ID is the project number `381273275501`. No Web Push key pairs | CONFIGURED (transport API only) |
| Service accounts | `…/settings/serviceaccounts/adminsdk` | Admin SDK service account exists at `firebase-adminsdk-fbsvc@haven-staging-46822.iam.gserviceaccount.com`; **no private key generated** (the generate button was not clicked) | NOT STARTED (credential) |

**Correction this walkthrough forces on the record.** Earlier reports treated FCM as absent from this programme. Wrong: the
FCM v1 transport API is enabled on the staging project today. What is genuinely missing is (i) an Android app registration,
(ii) a credential able to send, and (iii) a token store — none of which is "FCM is off". Related consequence: the Sender ID
is *not* a separate secret to obtain; it is the project number already published above, so A12/A9 wording that implies a
sender-ID provisioning step is describing something that already exists.

**Firebase Auth is still not enabled, and this record does not enable it.** Brief §3: "Do not silently enable Firebase Auth"
— it remains untouched, awaiting `A13` (the architecture change replacing Supabase Auth as identity authority) plus the
`A12-R` re-draft. The existing `A12` fence is `UNGRANTABLE AS WRITTEN` because the ratified architecture (`01-staging-project-proposal.md:201`)
lists Firebase Auth as out-of-scope/must-not-be-enabled; enabling it requires replacing that sentence, not ticking a box.

---

## 3. Supabase `parent-control-staging` — observed state

| Surface | URL | Observed | Status vocabulary |
| --- | --- | --- | --- |
| Project | `/dashboard/project/dzonzgngwxclhfnvxtvu` | Healthy, NANO compute, region `ap-northeast-2`, free plan | CONFIGURED (shell only) |
| Tables | `…/database/schemas` | `public` = **"No tables in schema"** — 0 tables against the 19 the G3 artefact defines | NOT STARTED |
| Migrations | `…/database/migrations` | No migrations recorded | NOT STARTED |
| Backups | `…/database/backups` | None | NOT STARTED |
| Branching / GitHub | surfaces visited earlier in this walkthrough | No branches, no repository connection | NOT STARTED |
| Advisor | `…/advisor` | "found no issues" — **vacuous on a zero-table database**; this is not a clean bill of health and must never be quoted as one | NOT A FINDING |
| Edge Functions | `…/functions` | "DEPLOY YOUR FIRST EDGE FUNCTION" empty state. **0 of the 9 evidenced slugs deployed** (`pairing`, `auth-bootstrap`, `device-command`, `device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`) and 0 `_shared` modules | NOT STARTED |
| Auth → Users | `…/auth/users` | Footer reads `Total: 10 users (estimated)` while the results grid (`role=grid`, one node, no children) renders **zero rows** | UNRESOLVED — see §4 |
| Auth → Sign In / Providers | `…/auth/providers` | **Email ENABLED.** Phone, SAML 2.0, Web3 Wallet, Apple, Azure, Bitbucket, Discord, Facebook, Figma, GitHub, GitLab, Google, Kakao, KeyCloak, LinkedIn, Notion, Twitch, X/Twitter, Twitter (deprecated), Slack (OIDC), Slack (deprecated), Spotify, WorkOS, Zoom all **DISABLED**. Toggles: Allow new users to sign up **ON** · Confirm email **ON** · Allow anonymous sign-ins **OFF** · Allow manual linking **OFF** | CONFIGURED |
| Auth → Third-Party Auth | `…/auth/third-party` | **Zero external JWT providers configured.** "Add provider" control present | NOT STARTED |
| Replication | `…/database/replication` → redirects to `…/database/pipelines` | 0 pipelines. The legacy publications panel is not at this URL in the current dashboard, so `supabase_realtime` publication membership was **not** verified directly; with 0 tables in `public` it cannot reference a real table (inference, not observation) | NOT VERIFIED |
| Infrastructure | `…/settings/infrastructure` | NANO radio checked and `disabled` (plan-locked), no read replicas, disk **0.00 GB used of 2 GB**, GP3, 3000 IOPS, 125 MB/s, scaling Pro-only | CONFIGURED (defaults) |
| Settings → API / API keys | deliberately **not** snapshotted | These screens render key values. Under "Do not print credentials in reports or screenshots", the pages were left unopened rather than opened and redacted | NOT OBSERVED BY DESIGN |

---

## 4. Two findings that change what has to be signed

**Finding 1 — Supabase Auth is already live on staging, so "add Firebase Auth" is not an additive change.**
The Email provider is ENABLED with email confirmation ON and open sign-ups ON. If Firebase Authentication is enabled on top
without a decision about this provider, staging carries two independent identity authorities issuing verified claims for the
same application — exactly what brief §3 prohibits ("Do not create two independent authentication authorities"). The
earlier record described staging as empty; it was empty of *tables and functions*, and that framing hid the fact that the
identity layer was already switched on. `A13` must therefore state, in its own body, what happens to Supabase's Email
provider and to open sign-ups at cutover — the three honest options are (a) disable the Supabase Email provider and route
all sign-in through Firebase, (b) keep Supabase Auth and drop the Firebase-identity direction, or (c) use Supabase
Third-Party Auth so Supabase verifies Firebase-issued JWTs and remains the single session authority. Anything else leaves
two authorities running.

**Finding 2 — the browser has a supported, CLI-free path for the Firebase→Supabase bridge.**
`…/auth/third-party` exposes "Add provider" for external JWT issuers. That is the mechanism the brief's target architecture
wants (Firebase UID as external identity, verified server-side, mapped to one Supabase profile), it is reachable through the
exact interface the brief allows, and it is currently empty. This materially strengthens `A13`: the identity bridge does not
depend on a bespoke token-verification path in every Edge Function once a Third-Party Auth issuer is registered, though
per-function server-side verification of the Firebase ID token remains required by the brief and is retained in the
instruments.

**The "10 users (estimated)" line is not evidence that users exist.** Supabase labels this figure as an estimate, and the
page's own results grid rendered no rows. It is also inconsistent with `0.00 GB used` on a schema-less database. It is
recorded as observed and left UNRESOLVED. Resolving it needs either a row-level read (prohibited: it would expose user rows
and PII, and the brief bans credential/PII disclosure) or a catalogue query in SQL Editor (prohibited until `A2′(a)`/`A3`).
No conclusion about user population is drawn from it here, and nothing in §6 depends on it.

> **[Anchored correction — same date, later in the same session.]** The paragraph immediately above presents the
> `Total: 10 users (estimated)` figure as though this walkthrough had surfaced it. It had not. It is already recorded at
> [`docs/stage2/01-staging-project-proposal.md:196`](file:///D:/control/docs/stage2/01-staging-project-proposal.md#L196)
> as finding **FX-18** of `evidence/S2-INSP-03-read-only-reconfirmation.md`, together with two facts this file was silent
> about: production prints an exact `Total: 8 users`, and the resolution was already specified there — "resolve with one
> approved read-only count before A3". What this walkthrough adds is only a re-observation at a later date, and one
> corroborating detail (the results grid rendered zero rows). The finding itself is not new, and the §4 framing that the
> earlier record "hid" staging's state is **wrong for this item**: the earlier record saw it and named it. It remains
> correct for the provider-configuration detail in §4 Finding 1, which is genuinely absent from every prior document.
>
> The same correction applies in reverse to one line of §4 Finding 1's evidence base: `01:196` classes Supabase Auth as
> the "Single identity authority" with status `NOT CONFIGURED`, because no sign-up was ever run by this programme. "Email
> provider ENABLED" is the *default* provisioning state of a new Supabase project, not a configuration act by anyone in
> this programme. The finding therefore stands — enabling Firebase Auth on top of a live email provider does create two
> authorities — but it is a warning about a default, not about a decision someone made.

---

## 5. What "verified" means in this record, and what it does not

Under brief §8, `VERIFIED` requires an actual test with evidence. **Nothing in this programme is `VERIFIED` except the
observations in §2 and §3 themselves**, which verify *absence* or *default presence*, not application behaviour. The status
of the backend, stated in the brief's own vocabulary:

| Operation | Status | Blocking reason |
| --- | --- | --- |
| Enable Firebase Authentication + providers | BLOCKED — APPROVAL REQUIRED (`A13`, then `A12-R`) + Blocker A | §3 Finding 1; nothing clickable this session |
| Register Android app, download `google-services.json` | BLOCKED — APPROVAL REQUIRED (`A12-R`) + Blocker A | needs the package/signing-certificate decision |
| Generate Admin SDK key / set secrets | BLOCKED — APPROVAL REQUIRED (`A9`) + Blocker A | key generation is an irreversible credential event |
| Create sentinel `private.s2_environment` | BLOCKED — APPROVAL REQUIRED (`A2′(a)`) + Blocker A | — |
| Load staging schema (19 tables / 183 columns) | BLOCKED — APPROVAL REQUIRED (`A3`) + Blocker A | load file in progress, §6 |
| SQL functions + 8 triggers | BLOCKED — SOURCE MISSING → candidate prepared | see §6 on `A3b` |
| Deploy Edge Functions | BLOCKED — APPROVAL REQUIRED (`A7-R`/`A8-R`) + `BLOCKED — SOURCE MISSING` for 7 of 9 | 7 are minified bundles; deploying them is separately prohibited by brief §4 |
| Notification backend (tokens, queue, send) | BLOCKED — DEPENDENCY MISSING | needs the schema, a credential and a deployed sender |
| Security/integration tests (invalid token, RLS, cross-family isolation) | BLOCKED — DEPENDENCY MISSING | there is no system to test; 0 tables, 0 functions, 0 Firebase products |

---

## 6. Implementation artefacts produced instead of further reports

These are the load-ready/ signable products, not analyses. They are listed so the owner can tick the approvals against real
files.

1. [`docs/stage2/approval-package-v3-implementation-instruments.md`](file:///D:/control/docs/stage2/approval-package-v3-implementation-instruments.md) —
   9 instruments (`A13`, `A12-R`, `A2′(a)`, `A3`, `A9`, `A5`, `A7-R`/`A8-R`, `A14`, auto-pause obligation), 898 lines. All
   fences blank and marked `STATUS: UNSIGNED`; `approval-package-v2` and `04-risks-rollback-approvals.md` untouched.
2. [`docs/stage2/migrations/A3-staging-load-v1.sql`](file:///D:/control/docs/stage2/migrations/A3-staging-load-v1.sql) —
   the transaction-safe staging load, still being written by its agent at the time of this record. Section skeleton
   confirmed on disk: a wrong-project sentinel guard (aborts before DDL #1 if pasted into the wrong editor), `BEGIN` at
   line 98 wrapping sections 0–8, then 2 schema / 19 table / 137 constraint statements, with the 13 `ALTER DEFAULT
   PRIVILEGES` statements deliberately split out of the main transaction (that split is defect M-3/H-3's fix: they were
   what could abort the batch at statement #448 with no rollback). Marked `*** NOT EXECUTED ***`, derived from the G3
   artefact at digest `fc996f45…908f6`.
3. [`docs/stage2/migrations/A3b-functions-triggers-candidate.sql`](file:///D:/control/docs/stage2/migrations/A3b-functions-triggers-candidate.sql) —
   959 lines. **Independently confirmed by me to contain zero executable statements**: a grep for any line beginning
   (with or without indentation) with `CREATE|ALTER|GRANT|DROP|BEGIN|COMMIT|SELECT` returns no matches, because every
   definition is commented out pending `A3`. Its agent reports all 9 blocked return types as STRUCTURALLY FORCED
   (3 helpers → `boolean`; 6 triggers → `trigger`), 24 absent bodies verdicted UNRECOVERABLE OFFLINE with no stubs, and
   0 previously-missed definitions recovered. Its own disclosed weakness, kept visible: the trigger-type derivation
   assumes the catalogue stored exactly the type `CREATE TRIGGER` validates, and `prorettype` itself was never captured;
   language, volatility and strictness are derived, not evidence.

---

## 7. Exact approvals requested (nothing broader)

Per brief §9, "Where an operation is blocked, request only the exact approval needed for that operation."

1. **`A13` — identity authority.** Sign the architecture change *and* choose the fate of Supabase's Email provider (§4
   Finding 1, options a/b/c). Until this is signed, Firebase Auth stays on its "Get started" screen.
2. **`A12-R` — Firebase Android app + FCM + SHA configuration.** Requires the package identity and the
   signing-certificate decision.
3. **`A2′(a)` — staging sentinel.** One `INSERT`; unblocks the wrong-project guard everything else relies on.
4. **`A3` — schema load** of artefact 2 above, once it reports complete.
5. **`A9` — secrets.** Which named secrets may be set, and whether an Admin SDK private key may be generated at all.
6. **`A7-R`/`A8-R` — Edge Function deployment**, with the explicit answer for the 7 minified functions: re-author from
   specification (no parity claim) or leave undeployed. Deploying a minified bundle is not available under either reading.
7. **`A14` — synthetic fixtures.** Without it there is no legitimate way to test auth, ownership or isolation.

Plus one non-approval requirement: **open the in-app Browser surface** (Blocker A). Without it, signed approvals produce
nothing, because no dashboard control can be clicked.

---

## 8. Anchored update — same date, after the owner's Phase 1 directive

This section supersedes parts of §1 and §3 above. Those sections are left intact as what was actually observed at the
time, per the project's rule that stale readings are annotated rather than rewritten.

**(a) Blocker A is cleared for pointer actions, and the evidence is a state flip.** Two clicks on the staging
Infrastructure page succeeded: "Show infrastructure on the map" went `pressed="false"` → `pressed="true"` while
"Show infrastructure as a diagram" went `pressed="true"` → `pressed="false"`, the map rendered roughly 200 node symbols,
and keyboard focus moved onto the clicked control. The element was then toggled back to the diagram view. The same
control that returned `NATIVE_BROWSER_VIEWPORT_UNAVAILABLE` three times earlier in this session now accepts clicks.

**(b) Screenshots are still blocked, by a different condition than clicks.** `take_screenshot` returns
`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE … operation=screenshot, visible=false, attached=false, cdpAttached=true`. Pointer
actions need only CDP attachment; a pixel capture needs the panel to be **visible on screen**. Consequence: PNG evidence
is unavailable, and the structural accessibility snapshots in §2/§3 remain the only evidence form this programme can
produce without the owner watching the panel. **No PNG file was written, and none should be claimed.**

**(c) A §3 figure in this file was wrong and is corrected: disk usage.** §3 recorded `0.00 GB used of 2 GB` and
inferred a corroborating "essentially empty database". The same page later rendered **`0.25 GB used of 2 GB`** —
Database `25 MB`, WAL `64 MB`, System `167.4 MB` — plus a node reading `CPU 2% · Disk 13% · RAM 53% · 7/60 conns`.
The `0.00` was an un-loaded chart, not a measurement. **The §3 inference drawn from it is withdrawn**; the empty-schema
conclusion stands on its own direct evidence (`"No tables in schema"` on the Schemas page, re-confirmed today), not on
disk figures. This also weakens the §4 argument that the `Total: 10 users (estimated)` footer is inconsistent with disk
usage — 25 MB of database could hold ten rows without noticing.

**(d) Today's observation is a stronger auto-pause touch than the 2026-11-02 one.** Instruments §9.2 states the
conservative criterion: *"only a genuine dashboard interaction on the project page is a defensible touch"*, and that the
2026-11-02 session "was composed entirely of failed pointer actions". That criterion is now met on staging: two
successful interactions occurred on the project's own Settings page, dated 2026-11-03, inside the on-or-before
2026-11-06 window. **What still is not established, unchanged:** whether any of this resets the Free/NANO idle clock.
`NOT VERIFIED` remains the correct label, the §9.4 fence is still `STATUS: UNSIGNED`, and a fresh dated touch is still
owed before the next 7-day span lapses.

**(e) §6 item 2 is complete.** `A3-staging-load-v1.sql` finished at **157,738 bytes / 1,575 lines**, reporting 465
active load statements (19 tables, 137 constraints, 34 indexes, 2 schemas, 19 `ENABLE RLS`, **4 policies**, 236 grants,
13 `ALTER DEFAULT PRIVILEGES`, 1 `DO`) plus 19 read-only verification SELECTs. It emits 4 policies active with 17
commented, **0 of 8 triggers active**, and declares itself NOT application-ready with 16 of 19 RLS tables deny-all —
which is the honest outcome the brief's §3 rule demands ("Do not mark a deny-all database as application-ready"). Two of
its three volunteered risk calls matter for review: the author **added an executable sentinel `DO` guard that does not
exist in the source artefact**, and **moved the 13 `ALTER DEFAULT PRIVILEGES` statements after `COMMIT`** so an H-3
membership failure can cost 9 grant rows instead of unwinding 447. Neither is now accepted on the author's word: both
files are under independent adversarial verification, and their reports land as
`S2-EXEC-07-a3b-independent-verification.md` and `S2-EXEC-09-a3-load-independent-verification.md`.

**(f) The identity fork is resolved, and it resolved against §7 item 1 as written.** The owner selected the Supabase
**Third-Party Auth bridge** — Supabase Auth stays the session and authorization authority, Firebase only issues external
ID tokens — plus "re-author, labelled" for the 7 minified bundles, "I edit the files myself" for signing, "defer the
cutover" for the provisioning gap, and "defer A9" for the Admin SDK key. §7 item 1 above asked the owner to choose the
fate of the Supabase Email provider; that question is now answered, and the answer plus its six consequences, the final
`A13` text and the execution sequence are in
[`S2-EXEC-08-identity-decision-A13-final.md`](file:///D:/control/docs/stage2/S2-EXEC-08-identity-decision-A13-final.md).
§7's remaining value is historical; the live signing list is in that file's §1a and §5.
