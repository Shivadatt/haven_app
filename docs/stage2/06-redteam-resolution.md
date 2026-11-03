# Red-team resolution — J-01 … J-23

Purpose: dispose of every objection raised in [J-redteam.md](parts/J-redteam.md) against the plan as it now stands, and
record the corrections applied to the working papers. Every disposition is one of **ACCEPTED** (change made),
**ACCEPTED IN SUBSTANCE** (objection valid, narrower than stated), **REJECTED ON EVIDENCE** (premise false),
**DEFERRED** (valid, out of Stage 2), or **SUPERSEDED** (the objection addresses a document that has since changed).

Reviewer J read the working papers while they were still being written, so several premises are stale. Where that is the
case it is shown with the evidence, not asserted.

---

## 1. Dispositions

| ID | Sev | Objection (short) | Disposition | Where resolved |
| --- | --- | --- | --- | --- |
| J-01 | P0 | G3 is unexecutable under the CLI/Docker ban, and everything is sequenced behind it | **ACCEPTED** — G3's method is amended (A0) to catalogue capture + reconstruction + staging equivalence; the objective ("restorable, equivalent baseline") is unchanged. If A0 is refused, G3 is recorded `BLOCKED — METHOD NOT PERMITTED` and steps 3–5 do not start *(step numbering in 00 was revised by S2-DOC-02 — re-verify the reference)* | [00](00-stage2-execution-plan.md) D-01, §3; [04](04-risks-rollback-approvals.md) R-14 |
| J-02 | P1 | Four documents state opposite G6/G3 orders | **ACCEPTED** — one authoritative sequence published: G6-a creates the shell, G3 captures and restores into it. Contradicting sentences in [`stage1/06`](../stage1/06-secrets-and-environments.md) §3 and part A are superseded for Stage 2. **G6-a now executed (S2-CREATE-01); G3 `NOT DONE`** | [00](00-stage2-execution-plan.md) §3 *(step numbering in 00 was revised by S2-DOC-02 — re-verify the reference)* |
| J-03 | P1 | Nothing proves a SQL session is attached to staging | **ACCEPTED** — mandatory `private.s2_environment` sentinel, created in G6-b, read at the top of every patch. A paste into the production editor fails before the first DDL statement | [01](01-staging-project-proposal.md) §3; [03](03-patch-S2-P01.md) §2.3; patch §1 |
| J-04 | P1 | P01 has no permitted rollback and no rollback block | **ACCEPTED** — rollback ships inside the patch file (commented, reviewed as executed), the GRANT precedes the REVOKE, and the ACL non-identity is stated rather than hidden | [03](03-patch-S2-P01.md) §7; patch §2 |
| J-05 | P1 | P01 changes nothing for the real caller; revoke-before-grant is an unexamined window | **ACCEPTED** — relabelled "latent-route closure"; GRANT moved before REVOKE; the whole patch is one transaction | [03](03-patch-S2-P01.md) §1.2, §2.1 |
| J-06 | P1 | P02 relabels F7 rather than fixing it, and P01 forecloses its only beneficiary | **ACCEPTED** — F7 is **downgraded to "latent, not remediable in the database"** in the mapping and must not be reported closed. P02 ships a guard for a caller that does not exist; the release gate does not claim F7 closure | [02](02-findings-to-fix-mapping.md) §3; [04](04-risks-rollback-approvals.md) §4 |
| J-07 | P1 | "P02 rewrites three whole bodies, one unread; the design doc does not exist" | **REJECTED ON EVIDENCE, ACCEPTED IN SUBSTANCE** — see §2 below | [parts/D](parts/D-e3-f7-e1.md) §2, §6; [00](00-stage2-execution-plan.md) §4 |
| J-08 | P1 | No test identity model; P02's tests will false-PASS or block | **ACCEPTED** — every case names principal, claim set and expected SQLSTATE; unconstructible cases are `BLOCKED — NO REACHABLE CALLER`, never `PASS` | [05](05-validation-plan.md) §3.2, §2 |
| J-09 | P1 | P03 cannot satisfy the "duplicate → 409" gate | **ACCEPTED** — the gate item is rewritten: the 500 is recorded as a staging caveat; production deployment of P03 is blocked until the Edge mapping exists. The unsatisfiable requirement is withdrawn, not carried | [04](04-risks-rollback-approvals.md) §4 item 3; R-20 |
| J-10 | P1 | The index build cannot be validated on empty staging; the trigger mutates rows; `if not exists` checks only the name | **ACCEPTED** — a read-only **production duplicate count** is a precondition for P03 approval; the index definition, not only its name, is compared; the transition guard's allowed exits are confirmed before apply | [05](05-validation-plan.md) §3.3; [04](04-risks-rollback-approvals.md) R-05 |
| J-11 | P1 | "E7 rate limits" is a deliverable with no writer | **ACCEPTED** — E7 produces no patch and is not marked mitigated; a DB counter with no writer is explicitly rejected as a control | [02](02-findings-to-fix-mapping.md) §2; [04](04-risks-rollback-approvals.md) R-21 |
| J-12 | P1 | No rollback for a half-applied staging restore | **ACCEPTED** — explicit failure branch with classification, a one-session time box, and a named decision point (repair vs delete-and-recreate) that reuses the same slot and needs a new A2 | [04](04-risks-rollback-approvals.md) §2.4 |
| J-13 | P1 | The reconstruction artefact writes never-read bodies, possibly with literal secrets | **ACCEPTED** — `prosrc` is scanned and redacted **before** the artefact enters the repository; raw `prosrc` never goes into `evidence/`; the scan is recorded | [00](00-stage2-execution-plan.md) §4; [04](04-risks-rollback-approvals.md) R-18 |
| J-14 | P1 | The approval matrix assumes a second approver who does not exist | **ACCEPTED** — A5/A6/A10 are rewritten as single-owner approvals with compensating evidence and a time-separated reviewer pass; the document says plainly that this is not two-person control | [04](04-risks-rollback-approvals.md) §3 |
| J-15 | P1 | G5's 104 HTTP cases are blocked, yet G5 is the terminal gate | **ACCEPTED** — split into G5-S / G5-E / G5-C; no verdict may read "G5 passed" | [05](05-validation-plan.md) §1; [00](00-stage2-execution-plan.md) §5 |
| J-16 | P2 | "S2-P01" means two different things | **ACCEPTED** — staging items renumbered `G6-a…d`; patch IDs `S2-P01…P03` are unique | [00](00-stage2-execution-plan.md) §4; part G §2 edited |
| J-17 | P2 | Two parts disagree on what the baseline artefact *is* | **ACCEPTED** — one name: **G3 catalogue baseline (reconstructed DDL)**, built from a read-only capture, validated by equivalence, never called a "dump" | [01](01-staging-project-proposal.md) §3; [00](00-stage2-execution-plan.md) §4 |
| J-18 | P2 | B forbids the ACL change C requires | **ACCEPTED** — parity is declared a **pre-P01 snapshot**; P01 is an approved, recorded divergence, not drift | [04](04-risks-rollback-approvals.md) R-19 |
| J-19 | P2 | Three projects needed, one available | **ACCEPTED (realised & superseded in part by S2-CREATE-01)** — the objection held pre-creation: it said `one slot remains`, `no second project`. On 2026-10-30 staging took the 2nd slot: org shows **`2 of 2 used, 0 remaining`** (S2-CREATE-01 §2.4). The shell IS the second project; a third (dev / foreign) stays `BLOCKED — NO SLOT REMAINING`. Never pause or delete production to free one. **Prior disposition retained as historical** | [01](01-staging-project-proposal.md) §5/§7; S2-CREATE-01 §2.4; [05](05-validation-plan.md) §4 |
| J-20 | P2 | Staging proves catalogue shape, not behaviour | **ACCEPTED** — a per-dimension fidelity table with pass/fail per dimension; behavioural assertions staging cannot predict are `BLOCKED` | [05](05-validation-plan.md) §5 |
| J-21 | P2 | P03 duplicates P02's request path and must land after it | **ACCEPTED** — `P02 → P03` is the only permitted order; a review check requires identical advisory key, expiry predicate and status list in both texts. **Not applied — patches unapplied, all D-01…D-12 OPEN** | [00](00-stage2-execution-plan.md) §3 *(step numbering in 00 was revised by S2-DOC-02 — re-verify the reference)*; [04](04-risks-rollback-approvals.md) §2.3 |
| J-22 | P3 | Stale and self-contradictory statements across parts | **ACCEPTED** — one execution model (every patch is an explicit transaction with a sentinel); the wrapper-owner and statement-order contradictions are resolved in the plan-of-record | [03](03-patch-S2-P01.md) §1.1, §2.3 |
| J-23 | P2 | (S2-REVIEW-03) Several dispositions above rest on a project that has since been created | **ACCEPTED — supersession note** — S2-CREATE-01 (2026-10-30) created the Supabase shell and, exceeding A12, the Firebase shell `haven-staging-46822`. Dispositions that assume creation is **pending**, that "one slot remains" (J-19), or that a failed-create reuses an untouched slot (J-12) are **overtaken**; their text is retained as historical, **not deleted**. Sentinel/schema/secrets/Edge remain `NOT DONE`; apps/credentials `NOT CREATED`; A0/A2 never signed | [01](01-staging-project-proposal.md) §1/§6/§7; S2-CREATE-01 §2, §3 |

---

## 2. J-07 in detail

**What J claimed.** (a) `parts/D-e3-f7-e1.md` does not exist; (b) P02 rewrites an *unread* body
(`private.unlink_child`), so no rollback text exists; (c) therefore P02 is a behaviour change disguised as a guard.

**What is true.**

| Claim | Evidence | Verdict |
| --- | --- | --- |
| (a) D is absent | `docs/stage2/parts/D-e3-f7-e1.md` exists, 200 lines, and is cited by P02 line 20 | **False** — the file was written after J read the directory |
| (b) `unlink_child` body was never read | [g1-b3b](../stage1/evidence/g1-b3b-20261029.json) `bodies` contains `private.unlink_child`, 2514 characters; `private.request_device_recovery` 1146; `public.request_remote_session` 1401; `public.request_device_recovery` 73 | **False** — all three bodies P02 touches are captured |
| (c) P02 is "guard only" | P02 uses `create or replace function` three times: it substitutes whole bodies, with only the guard block inserted. The Stage 1 capture is the source for the replacement text | **True as a description, but not a defect**: the inserted text is the captured text plus the guard |

**What is nonetheless accepted.** J's underlying concern is right even though its premises are wrong:

1. A whole-body replacement makes the *stored capture* the rollback artefact, so the capture must be current. **Added
   precondition:** re-capture the three `prosrc` values from the **staging catalogue** immediately before apply, and store
   them as the rollback — do not rely on a capture that may predate later edits.
2. A whole-body replacement is a behaviour change if the captured text is not what is deployed. The residual risk is
   recorded as R-06 and mitigated by hash comparison, one function per statement, and a normalised definition diff.
3. The claim "rollback text does not exist" is false for these three and remains **true** for the 11 unread `private`
   twins and 12 unread `public` wrappers — which is exactly why P02 is scoped to three functions and nothing else.

**Consequence for the plan:** no change to scope; one added precondition; J-07 is not carried as a P1 blocker.

---

## 3. Corrections applied to the working papers

| Working paper | Statement | Correction |
| --- | --- | --- |
| A §1–§3 | "schema-only dump of `public` + `private`" | Superseded: the artefact is the **G3 catalogue baseline (reconstructed DDL)**; no dump exists under the CLI ban |
| A §1 | G6 before G3 is not stated | Superseded by the single sequence in [00](00-stage2-execution-plan.md) §3 — **now historical**: the G6-a shell was created 2026-10-30; G3 capture/load is `NOT DONE` *(step numbering in 00 was revised by S2-DOC-02 — re-verify the reference)* |
| B §?... | "the two NULL ACLs must stay NULL … REVOKE breaks parity" | Correct as a statement about the *baseline snapshot*; P01 is an approved divergence applied after the snapshot (R-19) |
| G §2–§3 | `S2-P01…P03` used for staging items | Renumbered `G6-a…d`; patches keep `S2-P0n` (edited in place) |
| I §2.3 | P03 rollback names a trigger/function that the patch does not create | Corrected in [04](04-risks-rollback-approvals.md) §2.3 to the actual objects: `remote_sessions_insert_guard`, `private.remote_session_insert_guard()`, `remote_sessions_one_live_per_device` |
| H | "wrapper owner not captured" | Contradicts C §1 and `inventory`: the wrapper is `SECURITY DEFINER`, owner `postgres`. The wrapper owner **is** captured |
| P03 patch | `grant execute … to service_role` on the trigger function | Removed: a trigger does not consult the invoker's EXECUTE, and the five sibling trigger functions are owner-only. Consistency with P01 |
| P02/P03 header | `begin; … commit;` while P01 had no transaction | P01 is now an explicit transaction with a sentinel; one execution model across all three |

**Working papers remain in `parts/` as the design record.** They are subordinate to [00](00-stage2-execution-plan.md)–
[06](06-redteam-resolution.md); where they differ, the master documents win.

> **Historical after S2-CREATE-01.** The `A §1` correction above (G6-before-G3 ordering) is now **historical**: the G6-a
> shell was created on 2026-10-30, while G3 (schema capture/load) is `NOT DONE`. The step sequence it points to lives in
> [00](00-stage2-execution-plan.md) §3, whose **step numbering was revised by S2-DOC-02 — re-verify the reference**. No
> schema, sentinel, secret, app, credential or Edge Function is configured; all D-01…D-12 remain OPEN and every patch is
> unapplied.

---

## 4. What survived the attack (recorded so it is not re-litigated)

- **The index cannot encode expiry.** `now()` is `STABLE`, so `expires_at > now()` is illegal in an index predicate. The
  trigger is the correct half; the index is a backstop only.
- **The insert trigger is concurrency-safe.** `pg_advisory_xact_lock` is transaction-scoped and re-entrant; the guard is
  `VOLATILE`, so its post-lock `EXISTS` takes a fresh READ COMMITTED snapshot and sees a winner that committed while it
  queued. The residual assumption — that the BEFORE UPDATE transition guard permits `requested → expired` — is asserted
  by the design and **must be confirmed before apply** (J-10).
- **P02's guard predicate is correct in form.** `p_actor is distinct from auth.uid()` is the right test; the objection is
  reachability, not logic.

---

## 5. Residual objections the owner must decide, not the plan

1. A0: amend G3's method, or accept that G3 cannot close in Stage 2 (J-01).
2. F7: accept the downgrade to "latent, not remediable in the database" (J-06).
3. P03: accept a staging-only patch whose user-visible error is a 500 until an Edge mapping exists (J-09, R-20).
4. Edge source: name who exports it; until then steps 6 and G5-E cannot start *(step numbering in 00 was revised by S2-DOC-02 — re-verify the reference)* (D-11).

No other objection remains open.

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed.
