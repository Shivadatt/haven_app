# Changelog — Stage 1 documents

One entry per correction pass. This is a record of documentation edits only; it is not evidence that any query ran or that
any project setting changed.

## 2026-10-30 — Phase E, Edge Function security source audit

Documentation and read-only source capture only. No request was sent to any Edge Function; no function was deployed, saved
or modified; no SQL DDL/DML ran; no `GRANT`, `REVOKE` or `ALTER FUNCTION`; no secret was generated, viewed or rotated; no
Firebase setting changed; no cookie, session token or credential was read. The nine deployed functions and six shared
modules were read from the dashboard editor's in-page model and hashed locally in the page.

| File | Change |
| --- | --- |
| [evidence/edge-functions/capture-20261030.json](evidence/edge-functions/capture-20261030.json) | New. Provenance manifest: capture method, operations performed and explicitly not performed, sanitisation, and per-artifact form, length, line count, SHA-256, actions, auth model, inlined modules and evidence anchors. |
| [13-edge-function-source-inventory.md](13-edge-function-source-inventory.md) | New. Repository state (no `supabase/functions/`), acquisition method, 9-function inventory, 6 shared modules, dependency matrix, full digests, limits of a minified review, owner export procedure, open items I1–I6. |
| [14-edge-function-security-audit.md](14-edge-function-security-audit.md) | New. Per-endpoint verdicts, the 17 mandatory checks with evidence and locations, positive controls, resolution of F7 (Edge half closed) and F8 (consequence sharpened), and what the audit does not establish. |
| [15-edge-function-test-plan.md](15-edge-function-test-plan.md) | New. **NOT EXECUTED.** TE-01…TE-20, per-endpoint cases, concurrency cases, fixtures, result recording and exclusions. |
| [16-phase-e-findings.md](16-phase-e-findings.md) | New. E1–E14, each with evidence, severity (latent and live), preconditions, impact, remediation, compatibility, rollback and verification, plus a recommended order. All PROPOSED — NOT APPLIED. |
| [00-status-register.md](00-status-register.md) | Phase E execution record added; PA1 closed at the Edge tier and re-scoped to the SQL tier; F7 and F8 annotated with the Phase E result. |
| [README.md](README.md) | Index rows 13–16 and the Phase E evidence file added; the "still not captured" paragraph no longer lists the seven minified functions as uncaptured; role 10 now covers the Phase E capture. |
| [01-baseline-inventory.md](01-baseline-inventory.md), [02-architecture.md](02-architecture.md), [04-rls-matrix.md](04-rls-matrix.md), [07-ops-and-observability.md](07-ops-and-observability.md), [08-test-matrix.md](08-test-matrix.md), [09-access-and-audit-plan.md](09-access-and-audit-plan.md), [11-remediation-proposals.md](11-remediation-proposals.md), [reports/stage1-final.md](reports/stage1-final.md) | Stale "Edge Functions unread / PA1 blocked" statements replaced with the Phase E result, each linked to 13 or 14. No count changed; the 11/12/24 unread *SQL* bodies stay unread and are still labelled so. |

Counts introduced by this pass: 9 functions, 6 shared modules, 15 captured artifacts, 17 checks, 14 findings, 20 named
scenarios plus per-endpoint and concurrency cases. No earlier count changed.

## 2026-10-30 — Phase F verification sweep

Documentation only. No live query, no dashboard action, no production or Firebase change. This pass checked the finished set
rather than adding content: every relative link in `docs/` and `firebase/` resolves; the 19/21/38/14/24/13/11/12 counts agree
across 00, 02, 08, 11, README and the report; every B3b count was re-derived from `g1-b3b-20261029.json` (38 functions,
34 definer, 36 + 2 `search_path` groups, ACL groups 27/4/5/2, 14 bodies); the repository contains no JWT, `sbp_`/`sb_secret_`
token, private key or service-account literal.

| File | Change |
| --- | --- |
| [reports/stage1-final.md](reports/stage1-final.md) | Four relative links used `../../` from a file one level deeper; corrected to `../../../` for `firebase/SETUP-CHECKLIST.md`, `.gitignore` and the root `README.md`. |
| [README.md](README.md) | Label key now defines **NOT TESTED** separately from **NOT VERIFIED**; the 00 index row says "four highest-risk questions with their answers" rather than "open questions". |
| [08-test-matrix.md](08-test-matrix.md) | §0 preamble no longer presents the query set as a way to "unblock gate G1"; it records that the set was executed and is kept for re-runs. |
| [evidence/schema-columns.md](evidence/schema-columns.md) | Dated supersession note: the items listed as "require gate G1" are captured in `g1-q4…q8`. |
| [04-rls-matrix.md](04-rls-matrix.md) | Historical 2026-10-29 section no longer reads as if the helper bodies were still unread; the B3b read is cross-referenced. |
| [evidence/functions-and-triggers.md](evidence/functions-and-triggers.md) | Stale "NOT VERIFIED" for `search_path` and authorisation marked superseded by B3b; Edge Function export no longer attributed to gate G1 but to the linked-project credential needed for G3. |

Counts re-derived and unchanged: 19 tables, 21 policies, 38 functions (14 `public`, 24 `private`), 34 definer, 13 twins,
11 unread private twins, 12 unread public bodies, 24 unread bodies total, 14 bodies read.

## 2026-10-30 — B3b, Phase A reconciliation, remediation proposals, G3 plan, G2 package verification

Status after this pass: **G1 and B3b answered**; Stage 1 still `BLOCKED — ACCESS OR APPROVAL REQUIRED` on G2, G3, G5, G6
and G7. Live operations were two read-only SQL batches (B3b, 2026-10-30), the dashboard Data API settings read, and
local read-only inspection of three APKs. No DDL, DML, grant, revoke, policy, function, trigger, setting, Edge Function,
Firebase or repository-settings change. No production mutation, deployment or permission change.

| File | Change |
| --- | --- |
| `evidence/g1-b3b-20261029.json` | New. 38-function inventory, 14 bodies, `private` schema usage, Data API exposure, remote-session trigger map, dynamic-SQL review. |
| [evidence/g1-run-manifest-20261029.md](evidence/g1-run-manifest-20261029.md) | Amendment appended: filename/capture-date mismatch, missing narrative files, B3b has no `proowner` (private ownership INFERRED), `remote_session_triggers` is not the `auth.users` map, Q9 counts re-checked. Raw files untouched. |
| `evidence/g2-apk-identity-20261030.md` | New. Package, version, SDK, Capacitor config, signer and digests for 1.0, 1.1 and 1.2; records the 1.0 divergence. |
| [00-status-register.md](00-status-register.md) | B3b closed; P4/P12/P13/P14/P17/P19 tightened, P20 added; PA2 narrowed to N5, PA3 re-scoped to the 11 unread `private` implementations; F7 rewritten, F8 added; G2/G3/G5/G6 verdict updated. |
| [01-baseline-inventory.md](01-baseline-inventory.md) | Post-G1/B3b note; 38 functions (14 public + 24 private); app id VERIFIED with 1.0 caveat. |
| [02-architecture.md](02-architecture.md) | Label legend and post-G1 note; body-read scope; token-column absence, dedupe key and append-only claims upgraded to VERIFIED; 11/12/24 unread counts corrected. |
| [04-rls-matrix.md](04-rls-matrix.md) | Status → `PARTIAL — EXPRESSIONS AND BODIES VERIFIED, LIVE TESTS NOT TESTED`; helper and trigger bodies graded VERIFIED; families `WITH CHECK` asymmetry; profiles F3 note; 14 tables with SELECT grants; F7 qualification. |
| [05-change-plan.md](05-change-plan.md) | Verdict and G3 state; G2 package verified; G3 procedure aligned with 12 (scratch-first, no `--role-only`, seed blocker). |
| [06-secrets-and-environments.md](06-secrets-and-environments.md) | DB-password rotation trigger; service-account ignore patterns; Edge Function secrets need a linked project; `supabase/functions/` absence stated. |
| [08-test-matrix.md](08-test-matrix.md) | B3b date; body-read instruction updated; T-13 `'unset'` gap; T-17 corrected (no transfer path exists); T-18 cites `g1-q6`; T-19 cites F7/PA1; G1/G3 gate mapping clarified. |
| [09-access-and-audit-plan.md](09-access-and-audit-plan.md) | Status, B3b row, file map, answer 4 (13/14 public, 23/24 private, F5/F7/F8), R6/R7/R9/R14/R15 updated. |
| [10-owner-runbook.md](10-owner-runbook.md) | B3b executed 2026-10-30; historical re-run checklist relabelled; G2 package verification recorded. |
| [11-remediation-proposals.md](11-remediation-proposals.md) | New. F1–F8 with root cause, impact, evidence, fix, compatibility, rollback, approval and verification. |
| [12-g3-baseline-plan.md](12-g3-baseline-plan.md) | New. Read-only capture, cross-schema trigger, no-diff proof, write steps not authorised, config blockers. |
| [firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) | §0a corrected for the 1.0 divergence; orphan D2 paragraph removed; evidence link added; ignore patterns recorded. |
| [.gitignore](../../.gitignore) | Added `*.bks`, `*-firebase-adminsdk-*.json`, `keystore.properties`, `signing.properties`. |
| Root `README.md`, [docs/stage1/README.md](README.md) | Current counts, gate state, index entries for 11/12/report, B3b closed. |
| [reports/stage1-final.md](reports/stage1-final.md) | New. Phase F report with the eight required sections and label separation. |

Substantive corrections found by the Phase A audit (not rewording):

| # | Correction |
| --- | --- |
| 1 | **F1's default-ACL fix was incomplete and partly impossible.** `postgres` leaks only on tables; `supabase_admin` leaks on tables, sequences and functions. `postgres` is not a member of `supabase_admin`, so `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin` cannot be prepared from the current account. Rewritten with a precheck and a BLOCKED half. |
| 2 | **F2 said `WITH CHECK` equalled `USING`.** It is `owner_id = auth.uid()` and drops `deleted_at IS NULL`. Corrected, with the reason it is not exploitable today (no `deleted_at` column grant). |
| 3 | **F3's replacement body was a fragment** that would have removed the `id` check, `updated_at` maintenance and `return new`. Replaced with the whole body and an explicit warning. |
| 4 | **F7 used the wrong parameter name** for `request_remote_session` (`p_parent_user_id`, not `p_actor_user_id`) and said both entry points were service-role-only; the `private` implementation carries `PUBLIC EXECUTE` (F8). |
| 5 | **F8 overstated the sibling ACLs.** Five functions are `postgres=X` only, not `postgres=X,service_role=X`. Rollback is functionally equivalent, not exact, because a `NULL` `proacl` cannot be restored by `GRANT`. |
| 6 | **The G3 plan instructed `supabase db reset`** in its verification step while §6 and `09` call it unauthorised, and used `--role-only` as if it captured privileges. Both corrected; Docker is now a hard precondition for a G3 pass. |
| 7 | **"11 unread RPCs" was ambiguous.** 11 of 13 `private` implementations, 12 of 14 `public` bodies and `private.record_audit` are unread (24 of 38 bodies); the read set is 14. Counts aligned across 00, 02, 08 and 11. |
| 8 | **§0a of the Firebase checklist said all three APKs were identical.** 1.0 has a different signer and Capacitor config. Corrected from direct APK inspection. |

## 2026-10-29 — G1 independent review and reconciliation

Status after this pass: **G1 answered**; Stage 1 still `BLOCKED — ACCESS OR APPROVAL REQUIRED` on G2, G5, G6, G7. Ten
subagents reviewed the G1 results with disjoint scopes. No database, Edge Function, Firebase or repository-settings change;
documentation only.

Substantive corrections (not rewording):

| # | Correction |
| --- | --- |
| 1 | **F2 was materially wrong.** `04` §0a said `families_update_owner` was "INEFFECTIVE — no client write is possible". `authenticated` does hold column UPDATE on `families.name` and `families.settings`, so the policy gates real writes; what it cannot do is change `owner_id`. Rewritten in 00 (F2) and 04 (§0a, R-05 outcome, P-06). |
| 2 | **F6 added — two policies are dead.** `devices_select_parent_or_child` matches no grant (`authenticated` has no privilege on `devices`) and `safe_zones_insert_parent` matches no grant (no INSERT). Recorded in 00 and 04. |
| 3 | **F7 added — a 15th `SECURITY DEFINER` function exists outside every query run.** `remote_sessions_transition_guard` lives in `private`; Q7 covered `public`/`auth`, Q10 covered `public`, so its `search_path` is unknown. Recorded in 00, 04 §0 and PA2/B3b. |
| 4 | **`profiles.role` enforcement attributed correctly.** The column grant excludes `role`; the `profiles_before_update` trigger is corroboration, not the load-bearing control (04 §Resolution). |

Stale pre-execution claims removed or dated across 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, README and the two markdown
evidence files: "RLS inferred", "policy bodies not captured", "blocked on G1", "a1…a6 output" file names that never
existed, "14 functions" where 18 rows exist (14 app definer + 4 `auth` helpers), "1 warning + 4 suggestions" where the
`run-lints` response holds 5 rules over 33 rows, and "the unique index is NOT CAPTURED" for two indexes that Q4 returned.

Also corrected: "12 of 15 SELECT predicates delegate to a `private` helper" → **14 of 15**; `webrtc_signals` is the only
one that does not.

## 2026-10-29 — G1 executed read-only

Status after this pass: **G1 answered**; Stage 1 still `BLOCKED — ACCESS OR APPROVAL REQUIRED` on G2, G5, G6, G7. The only
live operations were `SELECT`s over catalogue views inside read-only transactions plus a dashboard linter read. No DDL, DML,
grant, revoke, policy, function, trigger, setting, Edge Function or Firebase change.

| File | Change |
| --- | --- |
| `evidence/g1-q1…q10-20261029.json` | New. One file per executed query, raw JSON as returned. |
| `evidence/g1-run-manifest-20261029.md` | New. Project ref, server version, method, read-only proof, per-file mapping, capture notes. |
| [00-status-register.md](00-status-register.md) | Rewritten around observed results: G1 execution record; P10–P19 added; B1–B6 closed; PA2/PA3/PA4 record the `private`-schema and trigger-body gaps; F1–F5 findings with severities; B3b added; the four highest-risk questions now carry answers. |
| [04-rls-matrix.md](04-rls-matrix.md) | §0 evidence grade updated; new §0a with the observed grant table and per-table/verb verdicts; §Resolution records that RPC exposure is closed and the role-escalation path is blocked by column privilege, while the helper bodies remain unread. |
| [05-change-plan.md](05-change-plan.md) | G1 `ANSWERED`; G3 now `READY`; G5 dependency restated; the old "blocked on G1" caveat replaced with the verified outcome. |
| [08-test-matrix.md](08-test-matrix.md) | Header status `PARTIAL`; G1 readiness line replaced by an execution record; T-01/T-02/T-18 re-graded to `PARTIAL — catalogue verified, no live request`; gate-mapping row updated. |
| [09-access-and-audit-plan.md](09-access-and-audit-plan.md) | Status line records A1–A6 as executed. |
| [10-owner-runbook.md](10-owner-runbook.md) | Status `EXECUTED`; retained for re-runs; notes B3b as the uncovered item. |
| [README.md](README.md) | Stage verdict now names the gates still open and records that G1 was answered. |

Corrections to earlier statements that the evidence settled: `poll_device_commands` takes `(p_device_id, p_limit)`, not one
argument; `families_update_owner` cannot transfer ownership because `owner_id` is not granted; the advisor output is 5 rules
over 33 rows (2 at WARN level) even though the UI shows "1 warning, 4 suggestions"; `request_remote_session` pins
`search_path=public, pg_temp` without `private`.

## 2026-10-29 — G1 preparation pass (Q2, Q3b, Q10)

Status after this pass: G1 query set `READY FOR OWNER READ-ONLY EXECUTION`; gate G1 still OPEN; Stage 1 still
`BLOCKED — ACCESS OR APPROVAL REQUIRED`. No SQL executed, no Supabase or Firebase setting changed.

| File | Correction |
| --- | --- |
| [08-test-matrix.md](08-test-matrix.md) | Q2 note re-specified per command: INSERT `qual` is NULL by design, 19 of 21 policies carry a non-null `qual`, UPDATE `WITH CHECK` NULL reuses `USING`, NULL-`qual` findings qualified to PERMISSIVE policies. Added **Q3b** (`auth.users` triggers, `coalesce` to `[]`, no table read). Q10 interpretation broadened: app-owned `anon_exec = true` is a finding; `auth_exec = true` is investigated for the five actor-less functions; `extension_owned` rows held separately; `service_exec` expected; reachability needs `schema_usage`; identity requirement stated as `auth.uid()`. Q6 output ordered deterministically. Parser claim corrected to the PostgreSQL 18 grammar bundled in pglast 8.7. Added G1 readiness line; T-01 `SET ROLE` caveat; Q3b added to the G1 evidence list. |
| [04-rls-matrix.md](04-rls-matrix.md) | §5 null-`WITH CHECK` note re-specified per command and qualified to PERMISSIVE policies; `auth.users` trigger reference now Q3b; actor-argument names corrected (`p_owner`, `p_child_user_id` also occur); RPC reachability conditioned on `public` being exposed and the caller holding `USAGE`; body identity requirement stated as `auth.uid()` rather than "derives from JWT". |
| [10-owner-runbook.md](10-owner-runbook.md) | Status is now `G1 — READY FOR OWNER READ-ONLY EXECUTION` with "nothing executed" retained. Q3b added to the order table and closure checklist. Stop conditions broadened to all app-owned functions for `anon_exec`, the five actor-less functions for `auth_exec`, extension rows reported separately, `service_exec` not a stop. BEGIN-in-progress path now forbids pasting `COMMIT`. Evidence list includes `g1-q3b-*.json`. Q10 row covers every `public` function, not only the 14 definer ones. |
| [09-access-and-audit-plan.md](09-access-and-audit-plan.md) | Status line split: G1 ready for execution, G2 blocked. A3 includes Q3b. The four audit questions now state RPC reachability conditions, distinguish which query identifies the trigger from which reads its body, and note that a body-level `set_config('search_path', …)` is invisible to `proconfig`. |
| [00-status-register.md](00-status-register.md) | B1 records `qual` NULL by design on the 2 INSERT policies; B4 splits Q3 (`profiles_before_update`) from Q3b (`auth.users`); highest-risk item 1 rewritten (9 actor-taking / 5 actor-less, finding vs severity, extension separation, no applied REVOKE); parser version corrected; G1 preparation label added; no item moved to PASS. |
| [02-architecture.md](02-architecture.md) | RLS row corrected from "13 of 19 tables" to 15, matching 00, 04 and its own "11 + 4 Realtime" statement. |
| [05-change-plan.md](05-change-plan.md) | G1 state now reads OPEN with preparation ready. |
| [docs/stage1/README.md](README.md) | Index entry for this changelog. |

Not changed: evidence files, schema, policies, functions, grants, secrets, Edge Functions, Firebase configuration, and the
Q10 query text itself.
