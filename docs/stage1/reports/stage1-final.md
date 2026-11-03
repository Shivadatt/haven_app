# Stage 1 — Phase F final report

**Date:** 2026-10-30. **Project:** `parent-control-prod` / `hhqgreaoqulmfwfwarhc` (PostgreSQL 17.11, Free/NANO).
**Stage verdict: `BLOCKED — ACCESS OR APPROVAL REQUIRED`** on G2, G3, G5 and G6; G4 awaits a confirmation of the
no-change recommendation; G7 applies only at FCM wiring.

Label key used in this report: **VERIFIED** (observed directly), **INFERRED** (consistent with evidence, not selected),
**PROPOSED — NOT APPLIED** (design only), **NOT TESTED** (live behaviour not exercised), **BLOCKED** (needs owner input,
credential or environment).

**No production mutation, deployment, permission change or Firebase change was made at any point.** Nothing in this
report is a security PASS.

---

## 1. G1 closure

G1 was executed **read-only on 2026-10-29** through the dashboard SQL Editor, one query per
`begin transaction read only; … commit;` wrapper, with `transaction_read_only = on` confirmed before the first catalogue
statement. No statement failed, no DDL or DML was issued, and no user rows were read. Evidence:
[../evidence/g1-q1…q10-20261029.json](../evidence/), provenance in
[../evidence/g1-run-manifest-20261029.md](../evidence/g1-run-manifest-20261029.md).

| Query | Observed result | Grade |
| --- | --- | --- |
| Q1 | RLS enabled on **19/19** tables, forced on none, owner `postgres` | VERIFIED |
| Q2 | **21** policies: 15 SELECT, 2 INSERT, 3 UPDATE, 1 DELETE; roles `authenticated` only; every SELECT predicate scopes by family, device ownership or session participation | VERIFIED |
| Q3 | **7** `public` triggers, including `audit_logs_append_only`, `profiles_before_update`, `remote_sessions_transition_guard` | VERIFIED |
| Q3b | **1** user-defined trigger on `auth.users`: `on_auth_user_created` → `private.handle_new_user()`, enabled | VERIFIED |
| Q4 | **62** indexes, including the uniqueness behind pairing-code replay and command idempotency | VERIFIED |
| Q5 | **137** constraints, foreign keys, delete rules, uniqueness and checks | VERIFIED |
| Q6 | **149** table grants, **191** UPDATE column grants, **24** default-ACL rows, **24** role memberships; `anon` holds 0 table grants | VERIFIED |
| Q7 | **18** `public`+`auth` functions: definer flags, volatility, pinned settings, ACL, owner | VERIFIED |
| Q8 | **183** columns; no push-token column anywhere | VERIFIED |
| Q9 | **5** advisor rules / **33** rows (WARN 15, INFO 18); UI groups them as 1 warning + 4 suggestions | VERIFIED (read from the page's own `run-lints` response) |
| Q10 | **14** `public` functions; `anon_exec` and `auth_exec` false on every one; `service_exec` true | VERIFIED |

**G1 is closed for the authorised query set.** It did not close three things, and they are tracked rather than folded
into a pass:

| Residual | State | Why it stays open |
| --- | --- | --- |
| PA2 / N5 — live Data API reachability | **NOT TESTED** | The settings page says 0 of 19 tables and 0 of 38 functions are exposed, and `anon` holds no grant, but no HTTP request was made. The live probe needs a non-production target (G6) |
| PA3 — RPC bodies | **PARTIAL** | 14 bodies read (B3b); 24 unread: 11 `private` twin implementations, 12 `public` bodies, `private.record_audit` |
| PA1 — Edge Function source | **SUPERSEDED — READ IN PHASE E** | The Phase F report recorded this as blocked because 7 of 9 functions were minified and no export credential existed. Phase E read all nine in the dashboard editor without an export, on 2026-10-30 ([../13-edge-function-source-inventory.md](../13-edge-function-source-inventory.md)); what remains is SQL-tier behaviour, not source access |

Consequence: RLS expressions, grants, function signatures, triggers and indexes are **VERIFIED**, but their behaviour
under a live client is **NOT TESTED**. The code that calls the database was read at identifier level in Phase E, so the
Edge tier is no longer unread; the SQL tier still trusts caller-supplied actors (F7/E3).

---

## 2. B3b audit — `private` helpers, trigger bodies, actor binding

B3b ran **read-only on 2026-10-30** (three statements, same transaction wrapper, `transaction_read_only = on`). It read
catalogue metadata and 14 function bodies; it read **no table rows, no location history, no pairing codes and no personal
data**. Evidence: [../evidence/g1-b3b-20261029.json](../evidence/g1-b3b-20261029.json). The `20261029` suffix is retained
for link stability; the capture date is inside the file and in the manifest amendment.

### 2.1 What the schema actually contains

- **38 functions, not 14.** `public` holds 14 RPC wrappers; `private` holds 24 — 13 twins of those wrappers,
  `record_audit`, and 10 helpers/trigger functions. **34** are `SECURITY DEFINER`; the four that are not
  (`audit_logs_append_only`, `families_before_update`, `profiles_before_update`, `set_updated_at`) are trigger functions.
- **All 38 pin a `search_path`.** 36 pin `public, private, pg_temp`; `public.request_remote_session` and
  `private.remote_session_transition_guard` pin `public, pg_temp` (F5, F8).
- **ACLs:** 27 functions `postgres=X,service_role=X`; 4 policy helpers `postgres=X,authenticated=X`; 5 trigger functions
  `postgres=X`; 2 functions `NULL` (default `PUBLIC EXECUTE`) — `private.request_device_recovery` and
  `private.remote_session_transition_guard` (F8).
- **`private` schema usage:** `anon` false, `authenticated` true, `service_role` true.
- **Data API:** exposed schemas `public` + `extensions`; 0 of 19 tables and 0 of 38 functions exposed; `private` offered
  but not selected.
- **No dynamic SQL:** no `EXECUTE`, `format()` or unqualified table reference that could resolve outside the pinned
  `search_path` in any of the 14 bodies.

### 2.2 Bodies read — what they do

| Body | Behaviour | Assessment |
| --- | --- | --- |
| `private.is_family_parent` | `EXISTS` on `family_members` where `user_id = auth.uid()`, role `parent`, status `active`, joined to a non-deleted family | Correct family anchor; no argument-supplied identity |
| `private.is_family_member` | Same, any role, active, non-deleted family | Correct |
| `private.shares_active_family(p_user_id)` | Both rows active in the same non-deleted family, caller anchored on `auth.uid()` | Correct |
| `private.realtime_topic_allowed(p_topic)` | Validates `kind:uuid`, then family membership for alert/session-family topics or session participation for `remote-session`/`webrtc-signals` | Correct; rejects malformed topics |
| `private.handle_new_user` | Inserts `profiles(id, role, display_name)` with role **`'unset'`**, `on conflict do nothing`; display name from metadata, then email local part, then `User`; truncated to 60 chars | Confirms the `'unset'` bootstrap value behind F3 |
| `private.profiles_before_update` | `id` immutable; role change rejected only when `old.role <> 'unset'` unless privileged; sets `updated_at`; returns `new` | **Gap:** an `'unset'` row bypasses the role guard (F3). It is not reachable today because `role` is not in the client column grant |
| `private.families_before_update` | `owner_id` change rejected unless privileged | Ownership transfer is impossible at the database layer (F2) |
| `private.audit_logs_append_only` | Raises on UPDATE/DELETE unless privileged; returns `old` on DELETE | Append-only claim is now behaviour-verified, not just trigger-existence |
| `private.set_updated_at` | `new.updated_at := now(); return new` | Correct |
| `private.remote_session_transition_guard` | Blocks terminal (`declined`, `ended`, `expired`, `failed`) → non-terminal transitions | Correct; prevents session resurrection |
| `private.request_device_recovery` | Loads device `FOR UPDATE`; requires `p_actor_user_id` to be **some** active parent of the device's family; calls `unlink_child`; writes an audit row using the **argument** as actor | **Trust-boundary gap:** any parent can act under another parent's id; the audit record then names the forged actor (F7) |
| `public.request_device_recovery` | One-line wrapper around the `private` implementation | Confirms the wrapper pattern for this name; the other 12 wrappers are **INFERRED**, not read |
| `public.request_remote_session` | Validates `kind`; advisory lock; device must be active; expires stale requests; rejects concurrent sessions; inserts `remote_sessions` with `p_parent_user_id` straight from the argument and `consent_recorded = false` | **Trust-boundary gap:** the parent is not checked at all (F7). Consent is a column, not a verified act |
| `private.unlink_child` | Null actor rejected; if actor ≠ child, actor must be an active parent of the family; removes membership, revokes devices, ends sessions, revokes pairing tokens, cancels pending requests, writes audit | The child may unlink itself by design; no `auth.uid()` binding (F7) |

### 2.3 B3b conclusions

1. **The helper predicates are sound** — `auth.uid()`-anchored, active membership, non-deleted family, no dynamic SQL.
   They are called by 14 of the 15 SELECT policies, not exposed as routes.
2. **The trigger layer is real but not complete.** Audit append-only and session terminal-state guards work; the
   `profiles` role guard has an `'unset'` hole (F3); owner transfer is blocked by design (F2).
3. **Actor identity is the weak point.** The database trusts the actor argument. Phase E verified that every Edge handler
   derives the actor from the verified JWT and passes it explicitly ([../14-edge-function-security-audit.md](../14-edge-function-security-audit.md)
   §4), so the Edge tier is closed; the SQL tier that consumes the argument is not (F7/E3).
4. **Two `private` functions retain `PUBLIC EXECUTE`** (F8). They are latent because `private` is not exposed and `anon`
   lacks `USAGE`, but the grant is one schema-exposure change away from being live.
5. **No body contains a credential, secret or dynamic SQL.** The sanitisation note in the evidence file records this.

**Status: B3b is closed for the 14 bodies read. 24 bodies remain unread — that is unexamined code, not a known defect.**

---

## 3. Remediation proposals F1–F8

**Status of every item: `PROPOSED — NOT APPLIED`.** Full text, including compatibility, rollback, approval and a
verification test for each: [../11-remediation-proposals.md](../11-remediation-proposals.md).

| # | Finding | Band | Fix class | Approval | Executed? |
| --- | --- | --- | --- | --- | --- |
| F1 | Default privileges grant client roles on future objects: `postgres` leaks on tables (`anon/authenticated Dxtm`); `supabase_admin` leaks on tables, sequences and functions | P2 | `ALTER DEFAULT PRIVILEGES` | Owner; the `supabase_admin` half needs a role the operator does not hold | No |
| F2 | Ownership transfer is impossible at the database layer (column grant + policy + trigger) | P3 | Product decision, then DDL | Owner (product) + owner (migration) | No |
| F3 | `profiles_update_self` is column-agnostic; the trigger lets `'unset'` through | P3 | Replace one trigger function | Owner + onboarding source review | No |
| F4 | Leaked-password protection disabled (advisor WARN) | P2 | Auth toggle | Owner | No |
| F5 | `public.request_remote_session` omits `private` from `search_path` | P3 | `ALTER FUNCTION … SET search_path` | Owner | No |
| F6 | Two policies match no grant (`devices` SELECT, `safe_zones` INSERT) | P3 | Documentation first; optional drop | Owner, only if dropping | No |
| F7 | Actor identity is taken from an argument, not `auth.uid()` | P2 | DDL — function bodies | Owner + Edge Function review | No |
| F8 | Two `private` functions keep default `PUBLIC EXECUTE`; one also omits `private` from `search_path` | P3 | `REVOKE` / `GRANT` | Owner | No |

Corrections made during the Phase A audit, so the proposals are executable rather than illustrative:

- F1 originally revoked only tables and assumed `postgres` could alter `supabase_admin` defaults. Neither holds; the
  revised text includes a role-membership precheck and marks the `supabase_admin` half **BLOCKED** without that access.
- F2 originally said `WITH CHECK` equalled `USING`; it is `owner_id = auth.uid()` and drops `deleted_at IS NULL`.
- F3 originally supplied a fragment that would have removed the `id` check, `updated_at` maintenance and `return new`.
- F7 now uses `p_parent_user_id` for `request_remote_session` and no longer claims both entry points are service-role-only.
- F8 now records that five siblings are `postgres=X` only, and that a `NULL` ACL cannot be restored byte-identically.

None of these proposals is a finding of an observed exploit. F7 is the one that matters most: an audit log that can
record a forged actor is the wrong failure mode for a safety product.

---

## 4. G3 readiness

**State: `READY — NOT EXECUTED` for the capture; `BLOCKED` for closure.** Plan:
[../12-g3-baseline-plan.md](../12-g3-baseline-plan.md).

| Requirement | State |
| --- | --- |
| Schema-only dump of `public` + `private` | Procedure written; not run. `private` is mandatory — a `public`-only dump reproduces 14 wrappers and none of the logic |
| `auth.users` trigger | Captured verbatim in [g1-q3b](../evidence/g1-q3b-20261029.json); must be a separate file using `CREATE OR REPLACE TRIGGER`, because a `public`/`private` dump cannot contain it |
| Cross-schema FK `profiles.id → auth.users(id)` | Recorded; the baseline is Supabase-only by construction |
| Owner go-ahead | **Not given** |
| Database password for `supabase link` | **Not held**; must be entered interactively, never stored in the repo |
| CLI with `pg_dump` 17 | Toolchain present (`supabase` 2.109.0), version to be re-checked at execution |
| Docker for the no-diff restore proof | **Not installed on this machine** — G3 cannot be closed here even after a successful dump |
| `seed.sql` | **Missing** while `[db.seed] enabled = true` — a local restore fails at the seed step (G3-a) |
| Migration-history write (`migration repair`) | **Not authorised**; it is a remote metadata write and needs explicit owner approval |
| `db push` / `migration up` / `db reset` | **Not authorised** by this stage |

The gate is satisfied only by an **empty normalised diff after restoring into a scratch stack**. A dump that merely runs
is not a baseline. The scratch stack is G6, and it does not exist.

---

## 5. G2 readiness — Firebase and the verified applicationId

Package half: **VERIFIED**. Project half: **BLOCKED — owner decision**.

| Field | Value | Grade |
| --- | --- | --- |
| Package name | `com.haven.familysafety` on 1.0, 1.1-release and 1.2-release | VERIFIED (`aapt2 dump badging`) |
| Version | versionCode 3 / versionName 1.2 on 1.2-release | VERIFIED |
| SDK | minSdk 24, targetSdk 36, compileSdk 36 | VERIFIED |
| Signer | `CN=Haven, O=Haven Demo, C=US`; SHA-256 `ff1ad18f…fdd67a` on 1.1/1.2 | VERIFIED |
| 1.0 divergence | Different signer (`O=Haven, L=Ahmedabad, C=IN`) and different Capacitor config (remote `server.url` vs bundled `dist-android`) | VERIFIED |
| Capacitor `appId` | `com.haven.familysafety`, `appName` `Haven` | VERIFIED |
| Firebase project | None for this product | VERIFIED (absent) |
| Firebase CLI account | Different Google identity from the console account | VERIFIED |

Evidence: [../evidence/g2-apk-identity-20261030.md](../evidence/g2-apk-identity-20261030.md); checklist
[../../../firebase/SETUP-CHECKLIST.md](../../../firebase/SETUP-CHECKLIST.md).

Remaining G2 decisions: D1 (new project vs reuse — recommendation: new), D2 (project id — `parent-control-prod`
preferred, availability unverified), owner account, and whether the production signing key is decided before Play
enrolment. **No project was created, no app registered, no credential generated, no `google-services.json` downloaded.**

---

## 6. G5 and G6 blockers

| Gate | What it needs | Why it is blocked | What it would unblock |
| --- | --- | --- | --- |
| G5 — negative and isolation tests | Test identities (at least two families with parents/children) and authorisation to run live requests | Only production exists, with 8 profiles and real family data; creating test users or families in production is not authorised | T-01…T-07, T-18; live confirmation of RLS, RPC grants and Data API exposure |
| G6 — non-production environment | An owner decision to create a `dev`/scratch Supabase project (and Docker for local) | No second environment; Free plan; no Docker on this machine | T-08…T-17, the G3 no-diff proof, the N5 Data API probe, any safe mutation test |

Consequences stated plainly:

- Every mutating test is **BLOCKED — NOT EXECUTED**. No row was created, changed or deleted anywhere.
- Three read-only tests (T-01, T-02, T-18) are **PARTIAL**: the catalogue predicts their outcome, but no HTTP request was
  made, so the HTTP status is unobserved.
- The absence of a non-production target also means the Data API's live reachability remains **NOT TESTED** even though
  the catalogue says it should be closed.

---

## 7. Documentation updated

All edits are documentation only. Raw evidence files were **not rewritten**; corrections to their descriptions are
appended as dated amendments.

| File | Change |
| --- | --- |
| [../00-status-register.md](../00-status-register.md) | G1/B3b records; P4/P12–P14/P17/P19/P20; PA2–PA4; F1–F8 corrected; unread-body counts aligned |
| [../01-baseline-inventory.md](../01-baseline-inventory.md) | Post-G1/B3b note; 38 functions; app id verified |
| [../02-architecture.md](../02-architecture.md) | Label legend, body-read scope, token-column absence, dedupe key, append-only, 24 unread bodies |
| [../03-data-model.md](../03-data-model.md) | RLS B1 answered; body-read scope |
| [../04-rls-matrix.md](../04-rls-matrix.md) | Status, body evidence grade, families `WITH CHECK`, profiles F3, 14 SELECT-granted tables |
| [../05-change-plan.md](../05-change-plan.md) | Verdict, G2 package, G3 procedure, Phase F report |
| [../06-secrets-and-environments.md](../06-secrets-and-environments.md) | Rotation trigger, ignore patterns, linking requirement |
| [../07-ops-and-observability.md](../07-ops-and-observability.md) | Recoverability, migration gates, monitoring blockers |
| [../08-test-matrix.md](../08-test-matrix.md) | B3b, body instruction, T-13/T-17/T-18/T-19, gate mapping |
| [../09-access-and-audit-plan.md](../09-access-and-audit-plan.md) | Status, B3b, file map, answers, risk register |
| [../10-owner-runbook.md](../10-owner-runbook.md) | B3b executed; historical checklist relabelled; G2 package verified |
| [../11-remediation-proposals.md](../11-remediation-proposals.md) | New; F1–F8 corrected per audit |
| [../12-g3-baseline-plan.md](../12-g3-baseline-plan.md) | New; `--role-only` removed, Docker precondition, reset boundary, seed blocker |
| [../../../firebase/SETUP-CHECKLIST.md](../../../firebase/SETUP-CHECKLIST.md) | §0a corrected for 1.0; evidence link; ignore patterns |
| [../../../.gitignore](../../../.gitignore) | `*.bks`, `*-firebase-adminsdk-*.json`, `keystore.properties`, `signing.properties` |
| [../../../README.md](../../../README.md), [../README.md](../README.md) | Current counts, gates, index entries |
| [../CHANGELOG.md](../CHANGELOG.md) | 2026-10-30 entry |
| [../evidence/g1-run-manifest-20261029.md](../evidence/g1-run-manifest-20261029.md) | Amendment: date mismatch, missing narrative files, no `proowner`, trigger-map scope, Q9 counts |
| [../evidence/functions-and-triggers.md](../evidence/functions-and-triggers.md) | Supersession amendment; app-id note; stale `search_path`/authorisation lines marked superseded |
| [../evidence/schema-columns.md](../evidence/schema-columns.md) | Dated supersession note for the "requires gate G1" list |
| [../evidence/g2-apk-identity-20261030.md](../evidence/g2-apk-identity-20261030.md) | New APK identity record |

---

## 8. Exact operations performed

| When | Operation | Target | Write? | Result |
| --- | --- | --- | --- | --- |
| 2026-10-29, 18:37–19:19 IST | Q1–Q8, Q3b, Q10 in read-only transactions; Q9 from the advisor's own `run-lints` response | Supabase project `hhqgreaoqulmfwfwarhc` | **No** | 10 JSON evidence files + manifest |
| 2026-10-30 | B3b: 3 read-only statements over `pg_proc`, `pg_namespace`, `pg_roles`, `pg_db_role_setting`, `pg_trigger`; `transaction_read_only = on` | Same project | **No** | `g1-b3b-20261029.json` (38 functions, 14 bodies) |
| 2026-10-30 | Read the Data API settings page (exposed schemas, table/function toggles) | Same project, dashboard | **No** — Save disabled and not pressed | Exposure values recorded in B3b |
| 2026-10-30 | `aapt2 dump badging`, `apksigner verify --print-certs`, `sha256sum`, `unzip -p … capacitor.config.json` on 1.0/1.1/1.2 | Local `%USERPROFILE%\Downloads` APKs | **No** | `g2-apk-identity-20261030.md` |
| 2026-10-30 | Documentation edits, `.gitignore` edit, two new evidence/report files, `docs/stage1/reports/` directory | Local repository | **Local files only** | This report and the changelog entry |

**Not performed, at any point:** `supabase link`, `db pull`, `db dump`, `db push`, `migration up`, `db reset`,
`migration repair`, any DDL/DML/GRANT/REVOKE in the SQL Editor; any secret creation or rotation; any Edge Function
deployment; any Firebase project creation, app registration or credential download; any change to the Supabase project's
auth, Data API, Realtime or network settings.

---

## 9. Residual risk register (current)

| Risk | Severity | State |
| --- | --- | --- |
| Actor identity is not bound to `auth.uid()` (F7); the SQL tier trusts the caller-supplied argument | High if a caller passes another parent's id | **PROPOSED — NOT APPLIED**; Edge bindings VERIFIED in Phase E ([../14](../14-edge-function-security-audit.md)), SQL tier open |
| Two `private` functions keep `PUBLIC EXECUTE` (F8) | Low today, high if `private` is exposed | **PROPOSED — NOT APPLIED** |
| Default privileges leak future tables/functions (F1) | Prospective | **PROPOSED — NOT APPLIED**; one half blocked on role access |
| `profiles.role` guard skips `'unset'` (F3) | Latent, blocked by column grant | **PROPOSED — NOT APPLIED** |
| Leaked-password protection off (F4) | Real, auth-layer | **PROPOSED — NOT APPLIED** (one toggle) |
| `search_path` inconsistency (F5) | Hygiene | **PROPOSED — NOT APPLIED** |
| Two dead policies (F6) | Misleading schema | **PROPOSED — NOT APPLIED** (documentation half can be done now) |
| 24 function bodies unread; 7 Edge Functions unread | Unknown | **BLOCKED** on source export / PA3 |
| No baseline migration | Recovery risk | **BLOCKED** on G3 |
| No non-production environment; no live tests | Verification risk | **BLOCKED** on G5/G6 |
| No FCM project | Product gap | **BLOCKED** on G2 |

---

## 10. Bottom line

The backend's **catalogue-level** security posture is coherent and largely least-privilege: RLS on every table, no
`anon` table grants, no client `EXECUTE` on the RPCs, 0 of 19 tables and 0 of 38 functions exposed, pinned `search_path`
on every function, real append-only and session-state triggers, and family-anchored policy predicates.

It is **not** a verified-secure system yet, for three reasons that this stage could not close:

1. The layer that turns requests into database calls — the 9 Edge Functions — is **unread**.
2. 24 database function bodies are **unread**, and the two actor-taking bodies that were read trust their actor argument.
3. No live request, no negative test and no restore have been executed, because there is no test identity, no
   non-production target and no Docker.

Stage 1 therefore ends at **design + evidence + proposals**, with the verdict `BLOCKED — ACCESS OR APPROVAL REQUIRED`.
The next decisions belong to the owner: approve or reject F1–F8, decide G2 (Firebase project) and G6 (dev environment),
and authorise G3 when a Docker-capable machine and the database password are available.
