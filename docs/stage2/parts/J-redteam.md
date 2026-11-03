# J — Independent red-team review of the Stage 2 plan

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

Reviewer: agent J. Input: `A`–`I` and the three patches; **`D-e3-f7-e1.md` does not exist**
and is cited by [`S2-P02`](../patches/S2-P02-e3-actor-binding.sql) line 20, so P02's design
intent is reviewed from the patch itself. Method: adversarial reading only; no SQL, CLI,
browser, deploy or secret was touched. Severities: P0 blocks the plan, P1 blocks the affected
patch, P2 needs a decision before production, P3 editorial.

## P0

### J-01 — G3 is not executable under the rules, and everything is sequenced behind it
- **Severity:** P0 (attacks 1, 10).
- **Evidence:** [12 §2](../../stage1/12-g3-baseline-plan.md) calls Docker a "hard precondition" for the no-diff proof and records that this machine has none; §3 requires `supabase link` and a DB password; §5 requires `db reset`; §7 G3-a shows the missing `seed.sql` blocks `db reset`; §8 rollback is `supabase stop --no-backup` or "revert the commit" ([12:191](../../stage1/12-g3-baseline-plan.md)), impossible because the repository has **zero commits** ([stage1-final](../../stage1/reports/stage1-final.md)). Meanwhile [06:63](../../stage1/06-secrets-and-environments.md), [I:5](./I-risks-rollback-approvals.md) and [H Q4](./H-app-preservation.md) all make G3 a predecessor of staging work.
- **Why it matters:** G3 as written cannot close, so the ordered plan (`G6 → G3 → P01 → P02 → P03 → E6/E7 → G5`) stalls at step 2 and every downstream "staging pass" precondition in [I:88](./I-risks-rollback-approvals.md) is unreachable. The only escape in the set — [B:177](./B-g3-dashboard-baseline.md) item A0, redefining G3 as catalogue reconstruction plus staging equivalence — is an **owner amendment that no part records as granted**. A plan whose first gate is provably unclosable is not a plan.
- **Decision:** Owner signs A0 in writing and the amended G3 acceptance criteria (G3-D parity, explicitly *not* a `pg_dump` diff) replace doc 12 §5/§7 in the plan of record — or G3 is formally marked `READY, NOT CLOSABLE` and struck from the critical path. Silence is a No-Go.

## P1

### J-02 — Two parts state opposite orders for G6 and G3
- **Severity:** P1 (attack 1).
- **Evidence:** [I:5](./I-risks-rollback-approvals.md) = "G6 staging → G3 baseline"; [06:63](../../stage1/06-secrets-and-environments.md) = baseline first, "a fresh project would be guesswork"; [B:108](./B-g3-dashboard-baseline.md) applies the baseline **into** staging; [A:99](./A-staging-spec.md) still describes the artefact as "a schema-only dump", which cannot exist without the banned CLI.
- **Why it matters:** An executor cannot satisfy all four. If G3 precedes G6 the capture needs CLI; if G6 precedes G3 the staging shell is built from no baseline, which 06 forbids.
- **Decision:** Publish one numbered sequence with the artefact named at each step, and delete the losing sentences from the other parts.

### J-03 — Nothing proves which project a staging SQL session is attached to
- **Severity:** P1 (attacks 6, 7).
- **Evidence:** [G:107](./G-g5-validation.md) requires a `project_ref` in evidence and says "a prod ref here invalidates the whole run", but no captured query returns the ref; `current_database()` is `postgres` in every project, and [B:110](./B-g3-dashboard-baseline.md) can only *ask* the operator to "verify the staging project ref is not `hhqgreaoqulmfwfwarhc`". [15:15](../../stage1/15-edge-function-test-plan.md) keeps the production URL in the test plan text.
- **Why it matters:** The plan's safety model is "dashboard only, never production", yet the dashboard presents two identically named SQL editors. One wrong tab applies P01–P03 to production with no pre-execution check that can refuse.
- **Decision:** Adopt a mandatory pre-execution sentinel — a read-only query whose expected result is recorded per project (e.g. a staging-only marker row or setting created at G6) — as a hard precondition in every patch header, and strip the production URL from doc 15.

### J-04 — S2-P01 has no rollback that the rules permit
- **Severity:** P1 (attacks 4, 10).
- **Evidence:** [C:123](./C-e2-f8.md) states that resetting `proacl` to `NULL` "needs a direct `pg_proc` catalogue write"; [I:92](./I-risks-rollback-approvals.md) forbids "improvised catalogue updates" and [11:396](../../stage1/11-remediation-proposals.md) has only a behaviour-level `grant … to public`. The patch itself contains no rollback block, and [I:34](./I-risks-rollback-approvals.md) promises per-patch rollback text.
- **Why it matters:** After P01 the pre-state cannot be restored through the dashboard at all. A failed or unwanted apply on staging leaves an ACL that only a forbidden catalogue write can undo, and the patch is declared "re-runnable" with no evidence.
- **Decision:** Either capture the exact reverse (`grant execute … to public` plus the known `service_role` entry) and accept that `NULL` is unreproducible, or drop P01 until a rollback exists. Add the rollback block to the file that will be executed, not to a neighbouring document.

### J-05 — P01 changes nothing for the real caller, so its stated purpose is wrong
- **Severity:** P1 (attack 4).
- **Evidence:** [C:17](./C-e2-f8.md) records the only live caller as `public.request_device_recovery`, `SECURITY DEFINER`, owner `postgres`; [C §6](./C-e2-f8.md) concedes the inner call "never needed the new grant (INFERRED)". [14:245](../../stage1/14-edge-function-security-audit.md) shows every Edge function uses the service-role key. The patch orders `revoke` (line 58) before `grant` (line 59) with no transaction wrapper, and [C:70](./C-e2-f8.md) says order "matters only for readability; each statement commits alone".
- **Why it matters:** The REVOKE is a real privilege reduction against `anon`/`authenticated` — but no such caller exists today, so the patch's security value is prospective, and the companion GRANT is ACL-parity hygiene rather than the compatibility mechanism the plan implies. The revoke-before-grant window is an unexamined intermediate state in an irreversible patch.
- **Decision:** Re-label P01's benefit as "closes a latent PUBLIC grant with no live path" and justify it on that basis; add the GRANT before the REVOKE, or wrap both in one transaction.

### J-06 — P02 relabels F7 rather than fixing it, and P01 forecloses its only beneficiary
- **Severity:** P1 (attack 3).
- **Evidence:** [P02:4–7](../patches/S2-P02-e3-actor-binding.sql) states the guard is "INERT today"; [11:333](../../stage1/11-remediation-proposals.md) says under `service_role` "the argument remains authoritative"; [14:245](../../stage1/14-edge-function-security-audit.md) confirms RLS never applies. P01 then removes `authenticated` EXECUTE from the private function, and [00](../../stage1/00-status-register.md) P12 records no public function executable by `anon`/`authenticated`.
- **Why it matters:** After P01 there is no role for which `auth.uid()` is non-null **and** which can reach the guarded function. F7's realistic path — a future handler forwarding a body-supplied actor — is untouched, because that path runs as `service_role` and the guard passes by design. The plan lists P02 as the F7 fix; it is at best a precondition for a fix that does not exist.
- **Decision:** Downgrade F7 to "latent, not remediable in the database" in the status register, and state that P02 ships a guard for a caller that does not exist. Do not claim F7 closure in the release gate.

### J-07 — P02 is not "guard only": it rewrites three whole bodies, one of them unread
- **Severity:** P1 (attack 3).
- **Evidence:** `create or replace function` (P02 lines 26, 51, 93) substitutes the entire body. [PA3](../../stage1/00-status-register.md) and [11:343–344](../../stage1/11-remediation-proposals.md) record 11 private bodies never read, with "rollback text does not exist" if they are changed; [I:29](./I-risks-rollback-approvals.md) R-13 accepts only the three captured functions, and P02 line 8 warns against "the 11 unread private twins". The patch cites a design document (`parts/D-e3-f7-e1.md`) that is absent.
- **Why it matters:** Restoring `private.unlink_child` after P02 requires its original text, which is not in evidence. The patch's reconstruction also silently becomes the new definition of child-unlink semantics — a behaviour change disguised as a guard.
- **Decision:** Before P02, capture the three bodies read-only from staging's own catalogue and store them as the rollback; or restrict P02 to the two bodies already captured and drop the `unlink_child` rewrite.

### J-08 — No test identity model, so P02's SQL tests will false-PASS or block
- **Severity:** P1 (attacks 2, 3).
- **Evidence:** [G:43](./G-g5-validation.md) assigns `S2-P01…P03` to L1 SQL tests. Proving the guard needs a role that holds EXECUTE **and** a JWT claim: after P01 only `service_role` holds EXECUTE, and `auth.uid()` derives from `request.jwt.claims`, which [11:333](../../stage1/11-remediation-proposals.md) shows is absent for service JWT. A `postgres`-role run proves the code compiles, not that any caller can reach it.
- **Why it matters:** The plan cannot distinguish "guard works" from "guard unreachable". A PASS produced as `postgres` would be cited as evidence for a fix that no client path exercises — the same false-assurance failure Stage 1 was written to end.
- **Decision:** Define the test principal explicitly (role, claim set, expected SQLSTATE) and mark every case that cannot be constructed as `BLOCKED — NO REACHABLE CALLER`, not `PASS`.

### J-09 — P03 cannot satisfy the release gate's "duplicate → 409"
- **Severity:** P1 (attacks 5, 7).
- **Evidence:** [I:106](./I-risks-rollback-approvals.md) makes "duplicate session → 409" a gate item. [H:123–128](./H-app-preservation.md) proves `23505` reaches the client as **500** and that the Edge mapping is blocked on source, with "deploy the Edge mapping before or with the DDL, never after"; [E:176](./E-e4-session-invariant.md) agrees. [P03:84](../patches/S2-P03-e4-session-invariant.sql) raises `P0001`, which is equally unmapped.
- **Why it matters:** The plan's own evidence says the user-visible outcome of P03 is a 500 on normal double-request behaviour. The gate is therefore unsatisfiable by this plan, and shipping P03 alone converts a security fix into an incident trigger.
- **Decision:** Either remove the 409 requirement and state "500 is accepted for one release" with an incident-budget note, or add the Edge mapping to scope (and accept that it is blocked until source is recovered). Do not carry an unsatisfiable gate.

### J-10 — P03's index build cannot be validated on staging, and the trigger has unexamined interactions
- **Severity:** P1 (attacks 5, 6).
- **Evidence:** [E:19](./E-e4-session-invariant.md) records 39 production rows but "no row was read"; [P03:21–34](../patches/S2-P03-e4-session-invariant.sql) pre-checks duplicates and aborts, so a 0-row staging project proves only that an empty index builds. `create unique index if not exists` (P03 line 108) accepts any pre-existing index of that name without checking its definition. The trigger's blanket `update … set status='expired'` (P03 lines 68–75) mutates unrelated rows during an insert, writes no audit row, and depends on the BEFORE UPDATE transition guard permitting `requested → expired` — a design P03 asserts but does not verify.
- **Why it matters:** The one precondition that can fail on contact with real data (duplicate live rows in production) is exactly the one staging cannot exercise, and [I:88](./I-risks-rollback-approvals.md) accepts "staging pass" as sufficient evidence for production. A wrong-name index or a rejected transition turns the patch into a mid-window abort.
- **Decision:** Add a read-only production duplicate-count query (allowed: read-only) as the conditioning evidence, require the index definition to be compared, not just its name, and confirm the transition guard's allowed `requested` exits before the patch is approved.

### J-11 — "E6/E7 rate limits" is listed as a deliverable but has no writer
- **Severity:** P1 (attack 7).
- **Evidence:** [F:169](./F-e6-e7.md) schedules the "E7 counter table + migration" against "G3 baseline + SQL approval, not Edge source", while [F:30](./F-e6-e7.md) says option C needs "no code change" and [F:32](./F-e6-e7.md) says it is "deployable without source". The counter table is only incremented by callers; [F:175](./F-e6-e7.md) concedes that "the only implementable enforcement is database side", and a database cannot meter an HTTP request it never sees.
- **Why it matters:** A migrated counter table with no writer is indistinguishable from no rate limit, but it will be recorded in the change log as "E7 done". That is worse than leaving E7 open, because it closes the finding on paper.
- **Decision:** Remove E7 from this plan's deliverables or rename it "E7: table only, inert until the Edge patch"; do not mark E7 mitigated.

### J-12 — No rollback exists for a failed hosted staging restore
- **Severity:** P1 (attack 10).
- **Evidence:** [B:108](./B-g3-dashboard-baseline.md) §4 defines a restore order but no failure path; [A §5](./A-staging-spec.md) names project deletion as teardown; [12 §8](../../stage1/12-g3-baseline-plan.md) rollback assumes a local Docker stack and a git commit. There is no item for "baseline apply failed halfway on staging", and re-provisioning consumes another project slot.
- **Why it matters:** The most likely failure in this plan is a partially applied reconstruction on a project that cannot be rebuilt cheaply, and the only recovery is deleting the project that G6 was approved to create — a decision nobody is assigned.
- **Decision:** Add an explicit staging-failure branch with an owner, a time box, and a decision point (repair in place vs delete and re-create); state who approves the second attempt.

### J-13 — The reconstruction artefact writes never-read bodies, including possible literal secrets
- **Severity:** P1 (attack 7).
- **Evidence:** [B:63](./B-g3-dashboard-baseline.md) recommends rebuilding 38 functions including bodies; [PA3](../../stage1/00-status-register.md) says 24 private bodies were never read; [08:183–187](../../stage1/08-test-matrix.md) Q7 warns `prosrc` is "the one place a pasted catalogue row can carry a literal credential" and that raw `prosrc` must never enter `evidence/`.
- **Why it matters:** The plan's central G3 substitute produces a file that must contain those bodies, in a repo, with no secret-scan gate anywhere in A–I. That is a plausible secret-exposure path created by the plan itself.
- **Decision:** Require a scan-and-redact step before the artefact is written to disk, keep the artefact out of the repository until scanned, and record the scan in the change record.

### J-14 — The approval matrix assumes a second approver who does not exist
- **Severity:** P1 (attacks 9, 10).
- **Evidence:** [I:87–88](./I-risks-rollback-approvals.md) requires "Owner + reviewer" for A5/A6 and [I:110](./I-risks-rollback-approvals.md) a signed A6; [06:27](../../stage1/06-secrets-and-environments.md) records a single owner with "no second approver and no break-glass account".
- **Why it matters:** Every production gate in the plan is expressed as a two-person control against a one-person reality. Either the controls are theatre, or nothing can be approved.
- **Decision:** Either name a second approver and record that appointment, or rewrite A5/A6/A10 as single-owner controls with compensating evidence (patch hash, before/after snapshots, timed window).

### J-15 — G5's 104 HTTP cases are blocked, yet G5 is the plan's terminal gate
- **Severity:** P1 (attack 2).
- **Evidence:** [G:44](./G-g5-validation.md) marks L2 — 19 `TE` + 78 `PE` + 7 `CI` = 104 cases — `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`, repeated at [G:211](./G-g5-validation.md); `supabase/functions/` is absent ([13 §1, §7](../../stage1/13-edge-function-source-inventory.md)), 7 of 9 bundles are 2-line minified files, and deployment needs `PAIRING_HASH_PEPPER`, `CRON_SECRET` and `TURN_*` ([G:44](./G-g5-validation.md)).
- **Why it matters:** P01–P03 unblock only the ~20 SQL cases in L1. Everything the plan exists to prove — the auth boundary, 409/42501 mapping, session lifecycle through HTTP — stays untested, so a "G5 green" verdict would rest on the subset that cannot detect the defects H and E describe.
- **Decision:** Split G5 into `G5-S` (SQL, runnable after G6) and `G5-E` (HTTP, BLOCKED), and refuse any verdict worded "G5 passed" without that qualifier.

## P2

### J-16 — "S2-P01" means two different things
- **Severity:** P2. **Evidence:** [G:32](./G-g5-validation.md) defines `S2-P01` as "staging Supabase project created" and [G:26](./G-g5-validation.md) says the patches are "not yet written", while `S2-P01` is the E2/F8 patch in [`../patches/`](../patches/S2-P01-e2-f8.sql). **Why:** the test-layer mapping in G will point at the wrong artefact. **Decision:** renumber the staging items to `G6-a…d` and update G §2.

### J-17 — Two parts disagree on what the baseline artefact *is*
- **Severity:** P2. **Evidence:** [A:99](./A-staging-spec.md) "schema-only dump of `public` + `private`" vs [B:63](./B-g3-dashboard-baseline.md) reconstruction. **Why:** reviewers cannot tell which artefact G5 and A6 refer to. **Decision:** one artefact name and one acceptance test, stated once.

### J-18 — B forbids exactly the ACL change C requires
- **Severity:** P2. **Evidence:** [B:95](./B-g3-dashboard-baseline.md) — the two `NULL` ACLs "must stay `NULL` … writing `REVOKE ALL … FROM PUBLIC` changes behaviour and breaks parity"; [C:50](./C-e2-f8.md) — "after the patch the only source is the new grant". **Why:** G3 parity and P01 cannot both be true of the same catalogue, and any post-P01 re-run of the parity check reports P01 as drift. **Decision:** state that parity is a pre-P01 snapshot and that P01 is an approved, recorded divergence.

### J-19 — Three projects are needed, two are available
- **Severity:** P2 (attack 8). **Evidence:** [A:128–131](./A-staging-spec.md) treats a two-active-project ceiling as binding and unverified; [G:197](./G-g5-validation.md) adds a foreign project for TE-08; production is the second. **Why:** the plan quietly needs a slot it may not have, and the email cap ([A:133](./A-staging-spec.md)) may stall synthetic sign-ups with confirm-email on. **Decision:** confirm the ceiling in the dashboard before G6, and replace TE-08's foreign-project case with a locally signed token or mark it BLOCKED.

### J-20 — Staging proves catalogue shape, not behaviour
- **Severity:** P2 (attack 6).
- **Evidence:** [B:160–166](./B-g3-dashboard-baseline.md) defines the "no-diff proof (redefined)" as equal counts from a frozen query set. Not compared anywhere: PG minor and extension versions, auth settings ([A:41](./A-staging-spec.md) already flags `config.toml` drift: `graphql_public`, seed enabled, `enable_confirmations = false`), default ACLs, publication membership ([B:142](./B-g3-dashboard-baseline.md) calls it "a publication setting, not baseline DDL"), Edge runtime and the deployed bundle ([13 §5](../../stage1/13-edge-function-source-inventory.md): editor text ≠ deployed bytes, INFERRED), and RLS under a real JWT — which is never exercised because every Edge call is `service_role` ([14:245](../../stage1/14-edge-function-security-audit.md)).
- **Why it matters:** Catalogue equality is the weakest form of fidelity, and the plan uses it to justify production confidence in behaviour (RLS, error mapping, session lifecycle) that staging cannot reproduce.
- **Decision:** Publish the fidelity dimensions with a pass/fail per dimension, and label every behavioural assertion in G5 that staging cannot predict as `BLOCKED`, not `PASS`.

### J-21 — P03 duplicates P02's request path and must land after it
- **Severity:** P2 (attack 9).
- **Evidence:** [P03:58–85](../patches/S2-P03-e4-session-invariant.sql) says "same lock mode and key … mirror the RPC exactly" and reimplements the expiry plus exclusion logic; [P02:104–118](../patches/S2-P02-e3-actor-binding.sql) carries the other copy, and P02 also rewrites the RPC the trigger points at.
- **Why it matters:** Run in the other order, the trigger mirrors the pre-P02 body. Edit either copy later and they diverge: the trigger raises `P0001` where the index raises `23505`, so the same user action acquires two different error shapes depending on which path won — precisely what H is trying to stabilise.
- **Decision:** Declare `P02 → P03` the only permitted order and add a review check that both texts carry an identical advisory key, identical expiry predicate and identical status list.

## P3

### J-22 — Stale and self-contradictory statements
[H:83](./H-app-preservation.md) "wrapper owner not captured" contradicts [C:17](./C-e2-f8.md); [C:70](./C-e2-f8.md) "order matters only for readability" contradicts P01's "one statement at a time"; P02/P03 use `begin; … commit;` while P01 forbids it; [F:30](./F-e6-e7.md) vs [F:32](./F-e6-e7.md) on "no code change". **Decision:** one editing pass, one execution model across all three patches.

## Design points that survived the attack

- **P03's index cannot encode expiry, and E is right about it.** `now()` is `STABLE`, so the predicate in [P03:108–110](../patches/S2-P03-e4-session-invariant.sql) is the only legal form; the trigger is the correct half. The trigger **is** concurrency-safe: `pg_advisory_xact_lock` is transaction-scoped and re-entrant, so the RPC's own insert re-acquires a lock it already holds at no cost, and the guard being VOLATILE means its post-lock `EXISTS` takes a fresh READ COMMITTED snapshot and sees a winner that committed while it queued. No stale `requested` row can block a legitimate request — the guard expires it first — provided the existing BEFORE UPDATE transition guard permits `requested → expired`, which is asserted, not verified. Residual bypasses (`session_replication_role=replica`, disabled trigger) fall through to the unique index and surface as `23505`.
- **P02's guard predicate is correct in form.** `p_actor is distinct from auth.uid()` is the right test and matches [11:333](../../stage1/11-remediation-proposals.md); the objection is reachability (J-06), not logic.

## Verdict

**No-Go on the plan as a sequence; conditional Go on G6 alone.** G6 is the one step that is
reversible, dashboard-native and unblocks the only honest route to G3 — but it is also the step
that spends the last project slot and therefore must not be taken before J-18 is settled.

### Top 5 conditions for a Go
1. Owner signs the G3 amendment (J-01) and one authoritative order replaces I:5 / 06:63 / B:108 (J-02).
2. A staging-identity sentinel exists and is a precondition in every patch header (J-03).
3. P01 gains a permitted rollback, or is dropped; the GRANT precedes the REVOKE (J-04, J-05).
4. P02 is re-scoped to captured bodies and F7 is downgraded to "latent" in the status register (J-06, J-07).
5. The 409 gate item is withdrawn or the Edge mapping enters scope; P03 waits for a production duplicate count (J-09, J-10).

---

## Addendum — S2-DOC-02 status correction (2026-11-02)

Append-only. The review above is unchanged as the design record.

- **J-19 is realised, not hypothetical, and its arithmetic is superseded.** Both staging shells were created on
  2026-10-30 — Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` and Firebase `haven-staging` /
  `haven-staging-46822` ([S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)). Slots now read
  **2 active / 2 used / 0 remaining**, re-confirmed read-only on 2026-11-02
  ([S2-INSP-03](../evidence/S2-INSP-03-read-only-reconfirmation.md) §1.3). A third project is impossible on Free, and
  **R-38** withdraws the delete-and-re-create branch.
- **"Conditional Go on G6" has been overtaken.** G6-a was executed under a direct owner instruction with A0 never
  approved and A2 never signed, so it is an executed action `AWAITING RETROSPECTIVE RATIFICATION` (04 §3.1; risks
  **R-36**, **R-37**; [approval-package-v2 §2](../approval-package-v2-ratification-and-forward.md)). This review
  cannot ratify it.
- **J-08, J-09 and J-10 stand untouched.** All three patches remain `PROPOSED — NOT APPLIED` and defects D-01…D-12 are
  OPEN, so no decision recorded above has been executed. J-09's unsatisfiable 409 gate and J-10's "an empty project
  proves only that an empty index builds" are both still live.
- **J-10's premise is now weaker than stated, not stronger.** Staging `public` holds 0 tables and `No migrations`, but
  the Auth page prints `Total: 10 users (estimated)` over an empty result grid, so `auth.users` emptiness is
  `NOT VERIFIED` (**R-42**, FX-18; [S2-INSP-03](../evidence/S2-INSP-03-read-only-reconfirmation.md) §3). A `select
  count(*) from auth.users;` on ref `dzonzgngwxclhfnvxtvu` is the first statement of the A3 window.
- **Step references into `00-stage2-execution-plan.md` are stale.** S2-DOC-02 rewrote 00 §3 into thirteen ordered steps
  a–l; re-verify any "step *n*" citation in this file against 00 §3 and its §9 addendum before acting on it.
- **Standing owner scope constraint, 2026-11-02** (**R-43**): every Supabase action in this programme targets
  `parent-control-staging` / `dzonzgngwxclhfnvxtvu` and no other project.
- **J-23 was added to the disposition list after this part was written and is defined in the plan of record, not here.**
  [`06-redteam-resolution.md`](../06-redteam-resolution.md) `:39` carries it: severity **P2**, source **S2-REVIEW-03**,
  finding "several dispositions above rest on a project that has since been created", disposition
  **ACCEPTED — supersession note**: `S2-CREATE-01` (2026-10-30) created the Supabase shell and, exceeding A12, the
  Firebase shell `haven-staging-46822`; dispositions that assume creation is **pending**, that "one slot remains"
  (**J-19**), or that a failed create reuses an untouched slot (**J-12**) are **overtaken** — their text is retained as
  historical, not deleted. Sentinel/schema/secrets/Edge remain `NOT DONE`; apps/credentials `NOT CREATED`; A0/A2 were
  never signed. This part therefore runs J-01…J-22 in its own table and J-01…J-23 across the plan of record; **06 is
  authoritative for the disposition**, and nothing in this bullet re-adjudicates it.
- **No operational action was taken in this addendum pass.** No dashboard, no SQL, no CLI, no patch, no approval
  signed. The banner and this note are documentation only.
