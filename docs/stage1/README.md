# Stage 1 — Backend audit and configuration record

**Stage verdict: `BLOCKED — ACCESS OR APPROVAL REQUIRED`** on G2, G3, G5 and G6; G4 awaits a confirmation of the no-change recommendation, and G7 applies only at FCM wiring. **G1 was executed read-only on 2026-10-29**, **B3b on 2026-10-30**, and **Phase E read all nine Edge Functions read-only on 2026-10-30**; all are answered — evidence in [evidence/](evidence/), interpretation in [00-status-register.md](00-status-register.md). No change has been applied to the live Supabase or Firebase projects.

## Documents

| # | Document | Covers |
| --- | --- | --- |
| 00 | [Status register](00-status-register.md) | Item-by-item PASS / PARTIAL / BLOCKED / NOT TESTED, and the four highest-risk questions with their answers |
| 01 | [Baseline inventory](01-baseline-inventory.md) | Read-only discovery of projects, 19 tables, RLS policy names, 9 Edge Functions, auth settings, quotas, Firebase state, access limits |
| 02 | [Architecture](02-architecture.md) | Component responsibilities, trust boundaries, source-of-truth rules, FCM integration sequence, credential placement, failure/recovery |
| 03 | [Data model](03-data-model.md) | Proposed-entity coverage matrix, gaps (push tokens, acks, consents, deletion jobs, entitlements), retention, additive proposals |
| 04 | [RLS matrix](04-rls-matrix.md) | Table × verb matrix, design-intent analysis, verification risks, least-privilege proposals |
| 05 | [Change plan](05-change-plan.md) | Approval gates G1–G7 and what happens once each is answered |
| 06 | [Secrets and environments](06-secrets-and-environments.md) | Secret inventory and placement, prod-only environment gap, rotation and exposure response |
| 07 | [Ops and observability](07-ops-and-observability.md) | Quota headroom, backup status, migration workflow, monitoring gaps, cost exposure, change control |
| 08 | [Test matrix](08-test-matrix.md) | Introspection queries (executed 2026-10-29) plus 19 negative/isolation tests; three read-only rows `PARTIAL`, the rest not executed |
| 09 | [Access and audit plan](09-access-and-audit-plan.md) | Gate checklist, safest SQL-access method, audit phases, exact file map, risk register and recovery |
| 10 | [Owner runbook](10-owner-runbook.md) | Executable G1 procedure (one query per read-only transaction), evidence return format, G2 package verification |
| 11 | [Remediation proposals](11-remediation-proposals.md) | F1–F8, each with root cause, impact, fix, compatibility, rollback, approval and verification — **nothing applied** |
| 12 | [G3 baseline plan](12-g3-baseline-plan.md) | Schema-only capture, cross-schema trigger, no-diff proof, write steps that are not authorised — **not executed** |
| 13 | [Edge Function source inventory](13-edge-function-source-inventory.md) | Phase E: all 9 functions and 6 shared modules captured read-only, dependency matrix, capture provenance and digests, missing-source export procedure |
| 14 | [Edge Function security audit](14-edge-function-security-audit.md) | Phase E: the 17 mandatory checks with evidence, per-endpoint verdicts, positive controls, F7/F8 resolution — **source only, nothing executed** |
| 15 | [Edge Function test plan](15-edge-function-test-plan.md) | Phase E: TE-01…TE-20, per-endpoint and concurrency cases, fixtures and result recording — **not executed** |
| 16 | [Phase E findings](16-phase-e-findings.md) | E1–E14 with the full eight-field schema, severity, and a recommended order — **proposed, not applied** |
| rp | [Final report](reports/stage1-final.md) | Phase F: G1 closure, B3b audit, F1–F8 proposals, G3/G2 readiness, G5/G6 blockers, documentation state, operations performed |
| ch | [Changelog](CHANGELOG.md) | Dated record of documentation corrections; it is not evidence that any query ran or any setting changed |
| ev | [evidence/](evidence/) | `schema-columns.md`, `functions-and-triggers.md`, `g2-apk-identity-20261030.md`, the G1 capture (`g1-q1…q10-20261029.json`, `g1-b3b-20261029.json`, `g1-run-manifest-20261029.md`), and the Phase E capture `edge-functions/capture-20261030.json` |

## Evidence and status rules

Every claim in these documents carries one of: **VERIFIED** (observed directly), **INFERRED** (derived from UI
affordances), **NOT VERIFIED** (not observable read-only), **NOT TESTED** (observable, but no live request or test was
made), **PROPOSED — NOT APPLIED** (design only), or **BLOCKED** (needs owner input, credential or environment).

Observed before G1 (browser only):
- Project identity, region, plan, quotas, storage and MAU.
- 19 table names with column counts, row estimates and Realtime flags.
- All 21 policy names with their command and the single role they apply to.
- Per-table Data API exposure, auth provider settings, 9 function names, and the absence of tracked migrations.
- Firebase account mismatch and the absence of a product Firebase project.
- A second pass then captured the 19 tables' columns/types/constraint flags, the 14 `public` function signatures (with the `private` schema still unknown) and 7 `public` triggers.

Captured by the G1 run on 2026-10-29: policy `USING`/`WITH CHECK` expressions, indexes, foreign keys, table/column/default
grants, role membership, function security settings and ACLs, trigger definitions, and the advisor findings. B3b on
2026-10-30 added 14 function bodies, the full 38-function inventory (14 `public` + 24 `private`), `private` schema
usage, the Data API exposure values and the remote-session trigger map.

Phase E on 2026-10-30 captured all nine deployed Edge Functions and the six shared modules they inline — two functions
readable as TypeScript, seven as minified bundles read by identifier — into
[evidence/edge-functions/capture-20261030.json](evidence/edge-functions/capture-20261030.json), with a SHA-256 per
artifact. Still not captured: 24 function bodies (11 `private` twins, 12 `public` bodies, `private.record_audit`), the
unminified source of the seven bundled functions (the bundles are the deployed artifact, not the repository source), and
any live behaviour test (G5/G6). The Edge-tier authentication and actor-binding question is answered in
[14](14-edge-function-security-audit.md); the SQL-tier half of the same question stays open (F7/E3).

## Why the first browser pass stopped — and how it was resolved

The first pass had no usable viewport: pointer and screenshot actions were rejected, and the SQL Editor plus the lazily
rendered advisor panel cannot be driven without one. Script-based reads still worked for fully-rendered pages, which is how
the baseline inventory was captured. The dashboard's own API requires an access token, which was deliberately not extracted
from the page session.

G1 was later executed without solving that first-pass problem: native clicks still failed, so the editor was driven through
its Monaco model and menus were opened with dispatched pointer events, all inside the browser page. Results were extracted
with the grid's own CSV export, because the result grid renders to canvas and exposes no DOM text. No access token, no
database password and no service-role key was requested, read or stored; the queries ran in a `begin transaction read only`
wrapper that returned `transaction_read_only = on` before the first catalogue statement.

## Role coverage

The master prompt specifies 15 specialised reviewer roles. Four parallel subagents were run with disjoint document ownership; the 15 roles are preserved as an explicit mapping rather than claimed as 15 separate runs.

| Role | Owned by | Where it lands |
| --- | --- | --- |
| 1. Project inventory | main agent (live discovery) | 01 |
| 2. Backend architecture | agent A | 02 |
| 3. Database auditor | agent B | 03 |
| 4. Auth specialist | main agent (dashboard) | 01 §4 |
| 5. RLS security engineer | agent C | 04 |
| 6. Data model architect | agent B | 03 |
| 7. Firebase/FCM specialist | main agent (console) | 01 §7, 02 |
| 8. Integration architect | agent A | 02 |
| 9. Secrets engineer | agent D | 06 |
| 10. Edge Functions engineer | main agent (function list and Phase E source capture) | 02, 05, 13, 14 |
| 11. Migration/rollback engineer | agent D + main | 05 §G3, 07 |
| 12. QA / integration tester | agent C | 08 |
| 13. DevOps/observability | agent D | 07 |
| 14. Independent security review | reviewer subagents before any change, again over the G1 results, and a ten-scope Phase A audit on 2026-10-30 | 04, 00, CHANGELOG |
| 15. Release audit / report owner | main agent | this index + [Phase F report](reports/stage1-final.md) |

Role 14 has run three times: against the documents before any change, again over the G1 results, and on 2026-10-30 over
the B3b results and the new remediation/G3/G2 documents. The 2026-10-30 pass ran ten subagents with disjoint scopes:
evidence-vs-register reconciliation, remediation-proposal audit, G3-plan audit, Firebase/APK audit, secrets/no-production-
action audit, link and count integrity, stale-claim sweep, SQL-body review, status-label audit, and an adversarial
wording review. It found and corrected the defects listed in [CHANGELOG.md](CHANGELOG.md), including the incomplete F1
fix, the fragmentary F3 replacement body and the 1.0/1.2 APK divergence. A fourth pass on 2026-10-30 covered the Edge
Function source (documents 13–16). The review of *implemented* changes is still owed, because no change has been
implemented.

Subagent count: **4** discovery agents and **1** independent reviewer in the first pass; **10** audit/verification agents
in the G1 pass; **10** disjoint audit agents in the 2026-10-30 Phase A pass. Phase E was performed by the main agent alone,
without subagents. Corrections were applied by the main agent and are recorded rather than asserted.
