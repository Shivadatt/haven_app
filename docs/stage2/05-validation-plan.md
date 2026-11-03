# Stage 2 validation plan (G5-S / G5-E)

**Status: `PROPOSED — NOT RUN`.** Every case below is unexecuted. Where a fix has not been applied, the case is
`BLOCKED — FIX NOT APPLIED`; where the staging database lacks the objects under test, `BLOCKED — STAGING IS EMPTY
(0 tables; no schema, no sentinel, no test principals)`; where the case needs a deployed function, `BLOCKED — STAGING
FUNCTIONS NOT DEPLOYED`. **No expected result is recorded as an observation.**

**Correction (S2-DOC-02, 2026-11-02).** The former reason `BLOCKED — STAGING PROJECT NOT CREATED` was doubly wrong: the
staging Supabase project (`parent-control-staging`, `dzonzgngwxclhfnvxtvu`) and the Firebase shell (`haven-staging-46822`)
were created 2026-10-30 under direct owner instruction, but the Supabase project is an empty shell — 0 tables, no
migrations, 0 Edge Functions, no sentinel, no schema, no secrets ([evidence/S2-CREATE-01-new-projects.md](evidence/S2-CREATE-01-new-projects.md)).
The blockers are real; the reason was not.

Source of cases: [15-edge-function-test-plan.md](../stage1/15-edge-function-test-plan.md) (20 `TE`, 78 `PE`, 7 `CI`),
[08-test-matrix.md](../stage1/08-test-matrix.md) `T-01…T-18`, plus patch-specific cases in
[03](03-patch-S2-P01.md) §6, [parts/D](parts/D-e3-f7-e1.md) §8 and [parts/E](parts/E-e4-session-invariant.md) §7.

---

## 1. The split, and why it is mandatory

| Layer | Needs | Cases | Status after Stage 2 can run |
| --- | --- | --- | --- |
| **G5-S** — SQL | A staging project with the baseline plus applied patches; dashboard SQL Editor; `set local role` + `request.jwt.claims` | `TE-02`; `T-01…T-18`; P01 T1–T4, T6; P02 T0–T8; P03 concurrency 1–6 | `BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)` — the project exists (G6-a shell only, 2026-10-30) but holds nothing |
| **G5-E** — HTTP | Deployed functions, staging secrets, a client build | 19 `TE` + 78 `PE` + 7 `CI` = **104** (Doc 15 suite) + 4 patch-specific HTTP cases (P01-T5, P03-C2/C7/C8) = **108** plan-of-record total | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` (0 Edge Functions observed) |
| **G5-C** — client | An APK built against staging | Compatibility sign-off only | `BLOCKED — NO APP SOURCE IN THIS REPO` |

**G5-S unblock chain — restated 2026-11-02 (corrections C-2/C-3/C-5).** The former chain read
"A0 → A1 → catalogue capture → reconstruction → secret scan → A3 → schema load → A2′ sentinel + settings → A5 patches →
G5-S runnable" and said "A0 has never been approved". Both are superseded. The chain is now:
**A0 (approved 2026-11-02, method amended to offline reconstruction) → reconstruction from the in-repo Stage 1 capture →
secret scan (run 2026-11-02, 0 pattern matches) → A2′(a) sentinel → A3 load → A2′(b) settings + publication → equivalence
diff → A5 patches → G5-S runnable.**
**A1 is deleted from this chain**: it is `INOPERATIVE` under the owner's staging-only absolute, so no production capture
step exists. **A3 is unsigned and the artefact is `NOT LOAD-READY`** (0 functions, 0 triggers, 0 policies reconstructable),
so **G5-S, G5-E and G5-C all stay `BLOCKED` — no status in the table above changes.**

**No verdict may read "G5 passed".** The maximum available verdict is *"G5-S: n passed, m failed, k blocked; G5-E and
G5-C blocked"*. A plan that collapses the layers would report 20 green SQL cases as coverage for a 105-case suite whose
real content is handler behaviour ([06](06-redteam-resolution.md) J-15).

---

## 2. Status vocabulary

| Status | Meaning |
| --- | --- |
| `PASS` | Executed in staging, against the expected post-fix state, with recorded output |
| `FAIL` | Executed, output differs from expected |
| `BLOCKED — FIX NOT APPLIED` | The code under test does not yet contain the fix |
| `BLOCKED — STAGING IS EMPTY` | Target exists (`parent-control-staging`) but holds 0 tables in `public` (`No migrations`, re-confirmed 2026-11-02 in [S2-INSP-03](evidence/S2-INSP-03-read-only-reconfirmation.md) §1.4); no schema, no sentinel, no test principals created by this programme — supersedes the false `STAGING PROJECT NOT CREATED`, which is retired. **Open item FX-18:** the staging Auth page prints `Total: 10 users (estimated)` over an empty result grid, so "`auth.users` is empty" is `NOT VERIFIED`, not `PASS` material. A test that depends on `auth.users` being empty must state that dependency as unproven. **Decision B-3 (2026-11-02, option A; correction C-4/C-11):** the closing read — `select count(*) from auth.users;` — is **inside A3's window**, as its first statement, and a non-zero answer stops the load. **A3 is unsigned, so the count has not been run and FX-18 remains open**; no test below may treat an empty `auth.users` as verified |
| `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` | Needs HTTP |
| `BLOCKED — NO APP SOURCE` / `BLOCKED — NO SECOND PROJECT` / `BLOCKED — BODY NOT CAPTURED` | Environment or evidence gap |
| `BLOCKED — NO REACHABLE CALLER` | The behaviour cannot be exercised by any principal that exists (P02's actor guard under `service_role`) |
| `NOT TESTED` | In scope, executable in principle, but not run this window |
| `NOT VERIFIED` | An assertion about the system that no test here can establish |

A `PASS` requires the principal, the SQL, the SQLSTATE or result set, and the timestamp. Anything less is `NOT TESTED`.

---

## 3. Patch-specific cases

### 3.1 S2-P01 — E2/F8 (all `BLOCKED — FIX NOT APPLIED` until §1 of the patch commits)

| # | Principal | Action | Expected | Proves |
| --- | --- | --- | --- | --- |
| TE-02 | `authenticated` | `select private.request_device_recovery(uuid, null)` | `42501` (schema USAGE may fail first) | The PUBLIC grant is gone |
| P01-T1 | `service_role` | same call, unknown UUID | `P0002 device_not_found` | EXECUTE passed; the patch did not over-revoke |
| P01-T2 | `authenticated` | same call | `42501 permission denied for function` | Direct EXECUTE denied |
| P01-T3 | `anon` | same call | `42501 permission denied for schema private` | USAGE fails before EXECUTE |
| P01-T4 | `service_role` | terminal `remote_sessions` row → `update … status='requested'` | `P0001 session_terminal`; `has_function_privilege(...,'EXECUTE') = false` on the guard | Trigger still fires with no EXECUTE |
| P01-T5 | Edge | `family-admin recover_device` on a staging fixture | HTTP 200, one `device_recovery_started` audit row naming the JWT subject | **`BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`** |
| P01-T6 | `postgres` | re-run §0 and §1.5 of the patch | Matches the post-check table | Idempotence and final state |

### 3.2 S2-P02 — E1/E3/E14/F5

Test principal model (**INFERRED**, must be confirmed at apply time): the owner `SET ROLE`s to a role that holds EXECUTE,
and `auth.uid()` is driven by `request.jwt.claims` + `request.jwt.claim.sub`. Role membership of the owner in
`authenticated` was not captured, so the harness grants EXECUTE **inside a transaction that is rolled back**.

| # | Principal | Call | Expected | Status |
| --- | --- | --- | --- | --- |
| T0 | `service_role` | `recovery(D, B)` | Succeeds — **characterises the residual**: E3 is still open | `BLOCKED — FIX NOT APPLIED` |
| T1 | JWT A | `recovery(D, B)` | `42501 actor_mismatch`, no audit row | `BLOCKED — FIX NOT APPLIED` |
| T2 | JWT A | `recovery(D, A)` | Succeeds; audit actor = A | `BLOCKED — FIX NOT APPLIED` |
| T3 | JWT A | `unlink(F, K, B)` | `42501 actor_mismatch` | `BLOCKED — FIX NOT APPLIED` |
| T4 | JWT A | `unlink(F, K, A)` | Succeeds; audit actor = A | `BLOCKED — FIX NOT APPLIED` |
| T5 | `service_role` | `request_remote_session(D, C, 'audio')`, C an outsider | `42501 forbidden`, no row | `BLOCKED — FIX NOT APPLIED` |
| T6 | `service_role` | `request_remote_session(D, A, 'audio')` | Row: family F, parent A, `requested` | `BLOCKED — FIX NOT APPLIED` |
| T7 | JWT A | `request_remote_session(D, B, 'audio')` | `42501 actor_mismatch` | `BLOCKED — FIX NOT APPLIED` |
| T8 | `postgres` | post-check query in the patch | `prosecdef=true`; `proconfig = public, private, pg_temp`; ACL unchanged | `BLOCKED — FIX NOT APPLIED` |

**Reachability caveat carried into the report.** T1–T4 and T7 need a principal that holds EXECUTE **and** a non-null
`auth.uid()`. After P01, no deployed role has both. These cases are constructible only with test-only grants inside a
rolled-back transaction; if the harness cannot construct that principal, the case is `BLOCKED — NO REACHABLE CALLER`, not
`PASS`. T0 is not a pass: it shows the residual.

### 3.3 S2-P03 — E4

| # | Scenario | Expected | Status |
| --- | --- | --- | --- |
| C1 | Two sessions, same device, both `insert … 'requested'` before either commits | One row; the other `P0001` | `BLOCKED — FIX NOT APPLIED` |
| C2 | Two handler `request` calls in parallel | one 200, one **500** today (409 after the Edge patch) | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| C3 | RPC and direct insert in parallel | One wins; no `23505` | `BLOCKED — FIX NOT APPLIED` |
| C4 | Seed `requested` with `expires_at` in the past, then request | Old row → `expired`, new row inserted | `BLOCKED — FIX NOT APPLIED` |
| C5 | Two different devices in parallel | Both succeed | `BLOCKED — FIX NOT APPLIED` |
| C6 | Trigger disabled (staging only, re-enable immediately), second insert | `23505` — the index backstop | `BLOCKED — FIX NOT APPLIED` |
| C7 | Regression: request → accept → start → ice → end | Each step succeeds | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| C8 | Regression: decline then accept | `409 session_not_open` | `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| C9 | Regression: terminal → open update | `P0001 session_terminal` (the new trigger is INSERT-only) | `BLOCKED — FIX NOT APPLIED` |

**Production duplicate count is a precondition, not a test.** Staging is empty, so the index builds regardless of real
data. The read-only production query in [parts/E](parts/E-e4-session-invariant.md) §4.1 P1/P2 must be run and recorded
before P03 approval ([06](06-redteam-resolution.md) J-10). If it is non-empty, the staging-only expiry remediation in §4.2
of that part is required, with its own approval.

---

## 4. G5-E and G5-C — blocked, stated plainly

- **104-case HTTP suite** (`BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`): the enumeration `TE-01…TE-20, PE-*, CI-01…CI-07`
  literally counts 20 + 78 + 7 = 105, but `TE-02` is a SQL case that runs under G5-S, so the HTTP suite is
  **19 `TE` (TE-01…TE-20 excluding TE-02) + 78 `PE` + 7 `CI` = 104**, consistent with §1 and §8. The four patch-specific
  HTTP cases (P01-T5, P03-C2/C7/C8) are *outside* that 104 — the plan of record uses **108 for G5-E** (104 + 4), with no
  de-duplication overlap between them. No source in the repository; 7 of 9 bundles minified; deployment would need fresh
  staging secrets and an approved export.
- **`TE-08` foreign-project half**: `BLOCKED — NO SECOND PROJECT`. Replace with a locally signed token only if the staging
  JWT secret is deliberately used for that test, which is itself an owner decision.
- **App compatibility**: `BLOCKED — NO APP SOURCE IN THIS REPO`. No claim about Flutter or Android behaviour may be made
  from this plan. If an APK is supplied later, the smoke script is: install → sign in → pair → issue a command → open a
  remote session → decline → end → uninstall, on staging only, with the error-code map recorded.

---

## 5. Fidelity dimensions (what staging can and cannot predict)

Catalogue equality is the weakest form of fidelity. Each dimension is reported separately, never aggregated
([06](06-redteam-resolution.md) J-20).

| Dimension | Staging predicts production? | Evidence |
| --- | --- | --- |
| Table/column/index/constraint shape | **Yes**, if G3-d matches | Catalogue counts and definitions |
| RLS policy text | **Yes** for text; **no** for behaviour | Policies are never exercised by Edge calls (all `service_role`) |
| Function bodies and ACLs | **Yes** for the 38 captured functions | `pg_get_functiondef`, `proacl` set comparison |
| Auth settings | **Partially** — mirrored deliberately, verified by checklist, not by query | Dashboard settings |
| Default privileges | **Partially** — `supabase_admin`-owned half is platform-managed | `pg_default_acl` |
| Realtime publication | **Yes** if re-added explicitly | `pg_publication_tables` |
| Edge runtime and deployed bundle | **No** | Editor text ≠ deployed bytes (**INFERRED**) |
| Error mapping (`409`/`500`) | **No** | Handler code, absent from repo |
| Client behaviour | **No** | No app source |
| Data-dependent behaviour (duplicate rows, stale expiry) | **No** — staging starts empty | Requires a production read-only count |

---

## 6. Fixtures (synthetic only)

| Fixture | Role |
| --- | --- |
| F | Family |
| A, B | Active parents of F |
| K | Child of F |
| C | Outsider (parent of another family) |
| D1, D2 | Devices of F/K |
| R1 | Second family, for isolation checks |
| U | Unlinked/unset user |

Reserved-domain emails (`@example.invalid`), fixed UUIDs, generated device secrets, staging only. Deletion plan: fixtures
are created inside rolled-back transactions where possible; persistent ones are recorded with their IDs and deleted at
teardown.

---

## 7. Evidence format

One JSON per run, stored with the change record and containing **no secret, key, JWT or credential value**:

```json
{
  "run_id": "S2-<nnn>",
  "date_utc": "",
  "start_utc": "",
  "end_utc": "",
  "project_ref": "",
  "sentinel": "staging",
  "patch_hash": "",
  "cases": [
    {"id": "P01-T1", "principal": "service_role", "action": "", "expected": "",
     "observed": "", "sqlstate": "", "status": "PASS|FAIL|BLOCKED — …", "at": ""}
  ],
  "not_run": [{"id": "", "reason": ""}],
  "verdict_ceiling": ""
}
```

`observed` is required for every non-blocked case. A `PASS` with an empty `observed` is invalid.

**Auto-pause and timing constraint (S2-DOC-02).** The Free-plan 7-day idle timer is running on both staging projects
since their creation on 2026-10-30, and **no UTC start timestamp was recorded at creation**. A dated dashboard touch is
therefore required **on or before 2026-11-06** to keep either project from pausing; any touch is an operational action
requiring its own owner instruction, not a documentation change. From the next capture onward, every run record must
populate `start_utc` and `end_utc`; a capture without both is incomplete.

---

## 8. Coverage arithmetic

| Bucket | Cases | Notes |
| --- | --- | --- |
| Patch-specific SQL cases (P01 T1–T4/T6; P02 T0–T8; P03 C1/C3/C4/C5/C6/C9) | **20** | Addends: 5 (P01 T1–T4, T6) + 9 (P02 T0–T8) + 6 (P03 C1, C3–C6, C9) = **20**. The previously printed **21** was an off-by-one; verified row by row against §3. Runnable once staging holds the patches |
| Doc 15/08 SQL cases (`TE-02`, `T-01…T-18`) | **19** | Addends: 1 (`TE-02`) + 18 (`T-01…T-18`) = 19. `TE-02` overlaps P01-T2; count it once in any total |
| Patch-specific cases that need HTTP (P01-T5, P03-C2/C7/C8) | **4** | Blocked with the rest of G5-E; these sit **outside** the 104-case suite below, so the G5-E plan of record is 104 + 4 = **108** |
| HTTP suite | **104** | Addends: 19 `TE` (`TE-01…TE-20` excluding the SQL case `TE-02`) + 78 `PE` + 7 `CI` = 104. The literal enumeration `TE-01…TE-20, PE-*, CI-01…CI-07` is 20+78+7 = 105 and is wrong for HTTP by exactly `TE-02`; reconciled to 104, which is what §1 and the source line (20 `TE` in Doc 15, of which 1 is SQL) already assume. `BLOCKED — STAGING FUNCTIONS NOT DEPLOYED` |
| Client cases | all | `BLOCKED — NO APP SOURCE` |

After de-duplicating `TE-02`, the SQL-runnable set is **38 cases**: 20 (patch-specific SQL) + 19 (Doc 15/08 SQL) − 1
(`TE-02` counted once) = **38**. The previously printed **39** inherited the 21 off-by-one. That is the whole of what a
SQL-only staging project can prove. The exact number is fixed only when §3 is executed and each principal is confirmed —
the order of magnitude, roughly a third of the SQL surface and none of the HTTP surface, is the honest statement.

---

S2-DOC-02 addendum (2026-11-02): documentation correction only; no operational action; no approval signed.
