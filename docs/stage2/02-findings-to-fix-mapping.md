# Findings-to-fix mapping — Stage 1 findings → Stage 2 work

**Status: `PROPOSED — NOT APPLIED`.** No finding below has been remediated. Every status in the "After Stage 2" column is
a **prediction**, not a result; it becomes a status only when the corresponding evidence in
[05](05-validation-plan.md) exists. Stage 1 identifiers and wording are authoritative
([16](../stage1/16-phase-e-findings.md), [11](../stage1/11-remediation-proposals.md)).

---

## 1. Fixability tiers

The tier determines what Stage 2 can honestly achieve, independent of effort.

| Tier | Meaning | Stage 2 outcome |
| --- | --- | --- |
| **A** | Remediable by SQL against captured evidence; body or ACL fully known | A reviewed patch can be applied in staging and validated at L1 |
| **B** | Remediable by SQL, but blocked on missing evidence or an outstanding prerequisite decision — the object definition was never captured, **or** a baseline/design/ownership/policy decision is required | `BLOCKED — BODY NOT CAPTURED` or `BACKLOG`, per finding; needs a read-only capture **or** a decision first. The qualifier in brackets (`B (body)`, `B (design)`, …) identifies which |
| **C** | The defect is in Edge Function handler code | `BLOCKED — EDGE SOURCE REQUIRED`; no patch is authored |
| **D** | Correct as designed, or not remediable in the database | Accepted and documented; not counted as fixed |
| **E** | Product/client decision | Out of Stage 2 scope; needs a separate client patch and compatibility tests |

---

## 2. Phase E findings (E1–E14)

| ID | Finding (short) | Tier | Work item | Status now | Predicted after Stage 2 | Honest limit |
| --- | --- | --- | --- | --- | --- | --- |
| **E1** | `public.request_remote_session` performs no authorisation | A | S2-P02 | `PROPOSED — NOT APPLIED` | **PARTIAL** — argument bound to an active parent of the device's family | Does not prove *which* caller sent the argument; the handler still supplies it |
| **E2** | `private.request_device_recovery` keeps PUBLIC EXECUTE and trusts its actor | A | S2-P01 (+ actor part in P02) | `PROPOSED — NOT APPLIED` | **CLOSED (latent route)** — `anon`/`authenticated` EXECUTE false | No live caller exists today, so this closes a latent path, not an exploited one |
| **E3** | SQL tier trusts actor arguments; only Edge binds them | D | S2-P02 (guard) | `OPEN` | **OPEN** — guard added, inert for every live caller | Residual is Edge-tier (C) work, counted here not twice: full closure needs user-JWT DB calls or acceptance of the Edge boundary |
| **E4** | Remote-session handler bypasses the single-session invariant | A (+C for user-visible error) | S2-P03 | `PROPOSED — NOT APPLIED` | **PARTIAL** — invariant enforced; second request raises `P0001`/`23505`, surfaced as **500** | Client-visible quality blocked on an Edge mapping that cannot be written from this repository |
| **E5** | Pairing token hashes are unsalted SHA-256 by design | D | none | `ACCEPTED` | **ACCEPTED** — documented; no change | Entropy ~39.3 bits; the load-bearing control is that pairing lookup is not an untrusted read path |
| **E6** | `PAIRING_HASH_PEPPER` falls back silently to SHA-256 | C | Step 6 decision | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | Cannot fail closed without the handler; no SQL equivalent exists |
| **E7** | No rate limiting outside pairing | C | Step 6 decision | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | A DB counter table with no writer would be "fixed on paper"; explicitly not created |
| **E8** | Pairing rate limits are count-then-act | C | — | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | Race is in handler logic; not expressible as a constraint without changing semantics |
| **E9** | Wildcard CORS including credential-bearing headers | C | — | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | Configuration inside the deployed bundle |
| **E10** | Device secret is chosen by the client | C | — | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | Server-side secret generation is a handler change |
| **E11** | Command poll returns full rows including `created_by` | B (body) | — | `BLOCKED — BODY NOT CAPTURED` | **BLOCKED** | Body of `private.poll_device_commands` was never read; no rollback text exists. This is the **only** finding blocked *wholly* on a missing capture; E14 is partially blocked on the same class |
| **E12** | Cron secret is static with no replay window | C | — | `BLOCKED — EDGE SOURCE REQUIRED` | **BLOCKED** | Secret validation lives in the handler |
| **E13** | Telemetry writes no audit rows | B (design) | — | `BACKLOG` | **BACKLOG** | Nothing is missing from the capture: a DB trigger could write audit rows today, but it changes insert cost and retention; needs an audit-event design and a baseline first |
| **E14** | Audit actor is application-supplied | A (3 bodies) / B (body, rest) | S2-P02 | `PROPOSED — NOT APPLIED` | **PARTIAL** | Guard added to the three captured bodies; the other wrappers remain unreviewed. The residual is body capture, not a design decision |

---

## 3. Earlier findings (F1–F8) and the cross-cutting item

| ID | Finding (short) | Tier | Work item | Status now | Predicted after Stage 2 | Honest limit |
| --- | --- | --- | --- | --- | --- | --- |
| **F1** | Default privileges leak future objects | B (ownership) | — | `BACKLOG` | **BACKLOG** | Not a capture gap: the default-ACL rows were read. Fixing them before a baseline exists makes the baseline unreproducible, and `supabase_admin`-owned defaults are platform-managed and may be outside owner control — an ownership decision precedes any SQL |
| **F2** | Ownership transfer is impossible | D | — | `ACCEPTED` | **ACCEPTED** | Structural property of the single-owner org; recorded, not changed |
| **F3** | `profiles_update_self` is column-agnostic; the trigger does not compensate | B (policy) | — | `BACKLOG` | **BACKLOG** | **Not blocked on a body capture — the trigger body was captured in Stage 1 (VERIFIED).** It needs a policy rewrite plus a reviewed trigger change, in one reviewed patch; a partial fix breaks every profile update. Status unchanged: not fixed, not started |
| **F4** | Leaked-password protection disabled | E | — | `BACKLOG` | **BACKLOG** | Leaked-password protection is **not included on the Free plan (VERIFIED, plan terms)**, so the staging experiment cannot run and the toggle cannot be flipped there. The finding stays a product-plan decision, not a Stage 2 test |
| **F5** | `request_remote_session` omits `private` from `search_path` | A | S2-P02 | `PROPOSED — NOT APPLIED` | **CLOSED** | Hygiene only; all objects are already schema-qualified |
| **F6** | Two policies match no grant | B (backlog) | — | `BACKLOG` | **BACKLOG** | Nothing missing from the evidence; cleanup with no security effect that must not ride along with a security patch. Sequenced behind the patches, not blocked by a capture |
| **F7** | Actor identity is taken from an argument, not `auth.uid()` | D | S2-P02 (precondition) | `OPEN` | **OPEN — downgraded to "latent, not remediable in the database"** | No role exists that can reach the guarded function *and* has a non-null `auth.uid()` |
| **F8** | Two `private` functions keep the default PUBLIC EXECUTE | A | S2-P01 | `PROPOSED — NOT APPLIED` | **CLOSED** | Same latent-route caveat as E2 |
| **X** | Duplicated function set (public wrapper ↔ private twin) | D | — | `ACCEPTED` | **ACCEPTED** | Documented architecture choice; not a defect by itself |

---

## 4. What Stage 2 does not touch, and why

- **No table, column, constraint or policy is dropped, renamed or narrowed.** Every patch is additive or ACL/body-only
  (C4).
- **No RLS policy is widened.** RLS is not the control for any Edge path, because all nine functions use the
  service-role key.
- **No function is deployed.** No source exists in the repository.
- **No secret is generated, read, rotated or copied.** Step 6 records secret *presence* and *name* only.
- **Firebase — corrected.** The prior blanket "No Firebase action" was false: a Firebase project **was** created on
  2026-10-30 (`haven-staging`, project ID `haven-staging-46822`) under direct owner instruction, exceeding the A12
  prohibition in [04](04-risks-rollback-approvals.md) §3; it was **`RATIFIED — 2026-11-02 — OPTION (i)`** (recorded in
  [S2-EXEC-02](S2-EXEC-02-owner-decision-resolution.md) §1; correction C-5 — the previously stated `AWAITING RETROSPECTIVE
  RATIFICATION` is closed). **A12 itself is unsigned and the ratification grants nothing forward.** No Firebase app, credential, FCM configuration or other settings change occurred
  ([evidence/S2-CREATE-01-new-projects.md](evidence/S2-CREATE-01-new-projects.md)). G2/G7 remains deferred; step
  numbering in [00](00-stage2-execution-plan.md) was revised by S2-DOC-02 — the "step 8 = G2/G7" reference there was
  re-verified against 00 and is kept as-is, not renumbered here.
- **No client change.** Any 409/`42501`/503 mapping needed for E4 or E6 is a separate client/Edge patch with its own
  review and compatibility tests.

---

## 5. Coverage arithmetic

| Bucket | Count | Share of Stage 1 findings+ |
| --- | --- | --- |
| Addressed by a prepared patch (A) | 6 items (E1, E2, E4, E14, F5, F8) | — |
| Of which fully closable after Stage 2 | 3 (E2, F5, F8) | — |
| Of which only partially closable | 3 (E1, E4, E14) | — |
| Blocked on Edge source (C) | 6 (E6, E7, E8, E9, E10, E12) | — |
| Blocked on a body capture — `B (body)` | 1 (E11) | — |
| Blocked on a decision, not a capture — `B (design/ownership/policy/backlog)` | 4 (E13, F1, F3, F6) | — |
| Accepted / documented (D) | 5 (E5, F2, F7, X, E3) | — |
| Product/plan decision (E) | 1 (F4) | — |

**Arithmetic correction (2026-10-30).** The previous single row read `4 (E11, E13, F1, F3, F6-minor)` — five items
listed under a count of four. Tier B holds **5**, not 4, and the five were not the same kind of blocker. Only **E11**
is blocked on a missing body capture; **E13** needs an audit-event design, **F1** an ownership decision on
platform-managed default privileges, **F3** a policy rewrite plus a reviewed trigger change (its trigger body was
captured — see §3), and **F6** sequencing. The `F6-minor` label is dropped: F6 is a single finding, counted once.

Two further corrections in the same pass: the C row listed `E3-residual` **and** the D row listed `E3`, counting one
finding twice — E3 now appears once, in D, and its residual Edge work is named in that row's honest limit. **F4** was
tier E and had no row at all; it now has one. The buckets therefore reconcile to **23 findings exactly**: 6 + 1 + 4 + 6
+ 5 + 1 = 23 (E1–E14 = 14, F1–F8 = 8, X = 1).

**Topology note.** Supabase Auth is the single identity authority — `auth.uid()`, the `anon`/`authenticated`/`service_role`
roles and RLS are all Supabase-side, and Firebase is intended for FCM transport only (FCM does not exist) — so every
auth-related finding in this mapping is Supabase-side and the new Firebase shell (`haven-staging-46822`) has no bearing
on any finding here.

**Read this table as the honest ceiling.** Stage 2 closes three findings outright, improves three partially, and leaves
the Edge tier untouched. Any summary that reports a higher number is overstating the evidence.

---

## 6. Traceability

| Patch | Findings | Doc | SQL | Tests |
| --- | --- | --- | --- | --- |
| S2-P01 | E2, F8 | [03](03-patch-S2-P01.md) | [`patches/S2-P01-e2-f8.sql`](patches/S2-P01-e2-f8.sql) | [05](05-validation-plan.md) §3.1 |
| S2-P02 | E1, E3, E14, F5, F7-precondition | [parts/D](parts/D-e3-f7-e1.md) | [`patches/S2-P02-e3-actor-binding.sql`](patches/S2-P02-e3-actor-binding.sql) | [05](05-validation-plan.md) §3.2 |
| S2-P03 | E4 | [parts/E](parts/E-e4-session-invariant.md) | [`patches/S2-P03-e4-session-invariant.sql`](patches/S2-P03-e4-session-invariant.sql) | [05](05-validation-plan.md) §3.3 |
| — | E6, E7 | step 6 | none authored | — |

---

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed.
