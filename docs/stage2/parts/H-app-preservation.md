# H — Application preservation and client compatibility

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

Stage 2 planning, part H. Scope: S2-P01, S2-P02, S2-P03 and the two client apps. **Planning only.** No request, deploy,
SQL, secret or source change was made. Stage 1 links are relative to this file. Labels: VERIFIED / INFERRED / NOT VERIFIED.

## 1. What this repository can and cannot establish

### 1.1 Absence of application source (VERIFIED)

Inspected 2026-10-30. The repository holds 61 files, all Markdown, JSON evidence and minimal config.

| Probe | Result |
| --- | --- |
| `*.dart`, `*.kt`, `*.kts`, `*.java`, `AndroidManifest.xml`, `*.ts`, `*.js` | 0 |
| `build.gradle`, `settings.gradle`, `pubspec.yaml`, `package.json`, `capacitor.config.*` | 0 |
| `supabase/functions/`; `git ls-files` | absent — only `supabase/config.toml`; 0 tracked files, no commit |

Consequence: no client call sites, parsers, retry logic, error strings, build flavours or compiled JS bundle exist here.
**Static app-compatibility review is impossible in this repository**, not merely incomplete.

### 1.2 A platform discrepancy that changes the analysis (VERIFIED facts, NOT VERIFIED conclusion)

- The brief names a **Flutter parent app** and a **native Android/Kotlin child app** ([02-architecture.md](../../stage1/02-architecture.md) §1),
  but the same document records both as **DO NOT EXIST — Stage 2+; toolchain present only** (§8).
- The only app artefacts ever inspected are **Capacitor hybrid builds**: `com.haven.familysafety`, 1.0/1.1/1.2, with 1.0
  loading a remote site and 1.1/1.2 bundling `dist-android` ([g2-apk-identity-20261030.md](../../stage1/evidence/g2-apk-identity-20261030.md)).

So the shipped client may be a web bundle in a native shell, while the target architecture is Flutter + Kotlin. Which
client calls the API is **NOT VERIFIED**, and every compatibility statement below is conditional on it. Origin matters
too: 1.0 would call from a Qoder-hosted site, 1.1/1.2 from a Capacitor origin — neither origin list is captured.

### 1.3 Can / cannot

Only server-side behaviour is knowable here: handler actions, SQL effects and the error mapping recorded in Stage 1.
Client-side rendering, `error.code` parsing, retry/backoff and offline-queue behaviour are unknowable, so every
compatibility statement below is conditional and must be confirmed on a staging build.

## 2. Client-visible impact per planned fix

Flow names are Edge actions: pairing (`create`/`redeem`/`respond`/`unlink`), recovery (`family-admin.recover_device`),
remote session (`request`/`pending_child`/`respond`/`start`/`end`/`ice`), policy (`device-policy.update`). Policy touches
none of the three fixes; it is listed to bound the blast radius and must remain byte-identical in behaviour.

| Fix | Client-visible change | Flows touching it | Risk |
| --- | --- | --- | --- |
| S2-P01 revoke PUBLIC EXECUTE (two `private` functions) | None expected | Device recovery; session transitions (trigger fires) | LOW |
| S2-P02 actor guard + RPC authorisation + `search_path` | None on Edge paths; `42501` only for a direct RPC caller | Pairing `unlink`, recovery, remote-session `request` | LOW / unknown caller |
| S2-P03 single-live-session index | Second concurrent request becomes a write conflict | Remote-session `request`, `respond`, `start` | MEDIUM |

### 2.1 S2-P01 — revoke PUBLIC EXECUTE on `private.request_device_recovery` and `private.remote_session_transition_guard`

- **Expected client-visible change: none** (INFERRED, strongly). All nine Edge Functions connect as `service_role`
  (VERIFIED, [14](../../stage1/14-edge-function-security-audit.md) check 12), so the companion `GRANT … TO service_role`
  preserves the recovery call. The trigger is invoked as a trigger, which does not consult the invoker's EXECUTE privilege
  ([11](../../stage1/11-remediation-proposals.md) F8).
- **Residual risk, timing, rollback:** a direct PostgREST RPC call from an app would go from "latent" to `permission
  denied`; today there is no route (`private` not exposed, `anon` has no schema USAGE, 0 of 38 functions exposed). If an
  older build called the public wrapper `public.request_device_recovery`, it is `SECURITY DEFINER` owned by `postgres` and
  is unaffected (INFERRED). No measurable timing change; `grant execute … to public` restores behaviour, not the ACL byte.
- **Flows:** device recovery (`family-admin.recover_device` → `request_device_recovery`) and remote-session transitions
  (the trigger on `respond`/`start`/`end`). Pairing and policy untouched.

### 2.2 S2-P02 — actor guard, `request_remote_session` authorisation, `search_path` pin

- **Guard:** `auth.uid() is not null and p_actor is distinct from auth.uid()` → `42501 actor_mismatch`. Under
  `service_role` `auth.uid()` is NULL, so every current Edge path is a no-op (VERIFIED logic,
  [16](../../stage1/16-phase-e-findings.md#e3)). The `search_path` pin touches no client behaviour: the body uses only
  `OLD`/`NEW` (VERIFIED). Expected client-visible change: **none**.
- **`public.request_remote_session` parent-membership check:** the `remote-session` handler does **not** call this RPC; it
  inserts directly (VERIFIED, [16](../../stage1/16-phase-e-findings.md#e4)). So the `request` flow is unchanged **unless**
  the handler is switched to call the RPC — an Edge deploy, not a client change. If switched, the RPC's advisory lock and
  live-session check also start applying, overlapping S2-P03.
- **Error surface if the guard ever fires for a client:** `42501` is a Postgres code, not an HTTP status. Handlers map RPC
  failures by substring and otherwise return **500 `internal_error`** (VERIFIED for `device-policy`, `device-command`,
  `family-admin`; [14](../../stage1/14-edge-function-security-audit.md) check 14). Whether `actor_mismatch` is in the
  substring list is **NOT VERIFIED**.
- **Flows:** pairing `unlink` (`private.unlink_child`), device recovery, remote-session `request` (only if the RPC is
  adopted). **Risk: LOW**, plus a caller-inventory unknown.

### 2.3 S2-P03 — single live session per device

- **Mechanism:** partial unique index on `remote_sessions (device_id) where status in ('requested','accepted','active')`
  ([16](../../stage1/16-phase-e-findings.md#e4)). It constrains INSERT **and** UPDATE.
- **Expected change:** a second concurrent `request` for the same device no longer creates a second prompt. The write
  returns SQLSTATE `23505`. The handler inserts directly and, on the captured evidence, has **no branch for this
  conflict**, so the generic error path applies → **500 `internal_error`** (INFERRED from the envelope's fixed 500 and the
  absence of a mapping). This is the one place where a security fix becomes a user-visible defect.
- **Timing and flows:** one extra index probe per write (negligible, INFERRED); affects `request` (parent) and
  `pending_child`/`respond`/`start` (child). `end`/`ice` are unaffected, and Realtime simply sees no row on the rejected
  write.
- **Precondition:** the index fails if legacy rows violate it — 39 sessions exist in prod ([06](../../stage1/06-secrets-and-environments.md) §3); count duplicates first, non-destructively.
- **Risk: MEDIUM.** A parent who taps twice gets "internal error", not "session already in progress"; a client that retries
  5xx can loop. Mapping to `409 session_in_progress` **requires an Edge patch** (see §3).

## 3. API contract notes

- **Request contract (VERIFIED):** POST only, JSON object only, 512 KB cap checked on declared and actual length,
  `action` 1–64 chars, `Cache-Control: no-store` ([14](../../stage1/14-edge-function-security-audit.md) check 10/14).
- **Response envelope (PARTIAL):** success is built by `ok(...)`, failure by `fail`/`errorResponse`; the exact success
  keys and nesting are **NOT VERIFIED** — the captured evidence stores module metadata, not source text
  ([13](../../stage1/13-edge-function-source-inventory.md) §4). Tests are instructed to record `status`, `error.code`,
  `error.message` ([15](../../stage1/15-edge-function-test-plan.md) §0), so a body with `error.code`/`error.message` is
  INFERRED.
- **Error codes observed in the docs:** `unauthorized`, `forbidden`, `role_required`, `validation_error`, `invalid_code`,
  `code_unavailable`, `child_already_linked`, `session_not_open`, `rate_limited`, `internal_error`, `audit_failed`,
  `server_misconfigured`, `cron_not_configured`, `device_auth_required`, `invalid_device_credentials`, `profile_missing`,
  `email_not_verified`; proposed here: `actor_mismatch`, `session_in_progress`.
- **Status mapping (INFERRED from documented expectations, no request was ever made):**

| Status | Codes | Note |
| --- | --- | --- |
| 200 | success, idempotent replay | Repeated accept/end return 200 (VERIFIED behaviour) |
| 400 | `validation_error`, `invalid_code` | Uniform code lookups |
| 401 | `unauthorized`, `device_auth_required`, `invalid_device_credentials` | |
| 403 | `forbidden`, `role_required`, `profile_missing`, `email_not_verified` | |
| 409 | `session_not_open`, `code_unavailable`, `child_already_linked`, `role_already_set`, `family_exists` | Proposed: `session_in_progress` |
| 429 | `rate_limited` + `retry_after_seconds` | Pairing only |
| 500 | `internal_error`, `audit_failed` | Default for unmapped RPC errors |
| 503 | `server_misconfigured`, `cron_not_configured` | |

- **42501 is not an HTTP status;** it reaches the client only through a handler mapping, absent one it is a 500.
- **Editable surface:** the seven minified handlers are 2-line bundles with no source maps and no source in the repo;
  import requires gate G3 ([13](../../stage1/13-edge-function-source-inventory.md) §1, §7). Therefore `23505` from S2-P03
  cannot become `409`, and `42501` from S2-P02 cannot become a curated message, without an Edge patch.
- **Possible UX regressions (INFERRED, none tested):** conflict surfaced as 500; retry-on-5xx loops; client-side
  "unknown status" silent failure; a spinner waiting on a Realtime row that never arrives.
- **Ordering constraint:** deploy the Edge mapping **before or with** the DDL, never after. DDL-first creates a window of
  500s on a normal user action.

## 4. Required owner-supplied artefacts

| # | Artefact | Why it is required |
| --- | --- | --- |
| 1 | App repos, or at minimum installable staging builds of every supported version (1.0, 1.1, 1.2) plus the live-version inventory | Only way to observe real error handling; 1.0 is a different signer and config and may be a distinct client |
| 2 | Build-flavour / config mechanism: how API base URL, anon key and Firebase ids are injected (Gradle flavours, `--dart-define`, Capacitor config) | Determines whether a staging build is possible without source edits |
| 3 | Test accounts: one parent + one child with verified email, one unlinked user, plus a device credential | Executes pairing, recovery, session and policy flows |
| 4 | Invocation logs for `/rest/v1/rpc/*` (read-only export) | Proves no app calls the SQL functions directly; needed before P01/P02 |
| 5 | Approval of an Edge patch window (or an explicit "no patch" decision) | 409/42501 mapping cannot happen otherwise |

**App compatibility = NOT VERIFIED** until items 1–3 exist. Item 4 is additionally required before P01/P02 can be called
client-safe.

## 5. No-regression checklist (binding for Stage 2 execution)

1. No UI change: no new screens, dialogs, strings, permission prompts or notification channels.
2. No feature removal and no flow redesign: pairing, recovery, session request/accept/start/end/ICE and policy update all
   stay reachable, in the same order and with the same number of taps.
3. No client change unless separately approved and versioned; these fixes are server-side by definition.
4. No request/response-contract change: no new required field, no field removed, no envelope change; error bodies keep
   `error.code` + `error.message`. New error codes only with an Edge patch and staging evidence.
5. No change to auth semantics (JWT, refresh, email confirmation) or replay idempotency (`respond`/`start`/`end` still
   return 200, VERIFIED). Realtime contract preserved (row images only, refetch-on-resume authoritative); rollback
   rehearsed — `grant … to public` and `drop index` both re-run the smoke script.

## 6. Staging compatibility protocol (no app modification)

Preconditions: staging (does not exist; gate G6, [05](../../stage1/05-change-plan.md) G6), a baseline migration (G3) and
synthetic seed only ([06](../../stage1/06-secrets-and-environments.md) §3). The app is **rebuilt with staging config,
never edited**.

1. Owner builds the same source at the same versionCode against staging config; record versionName/versionCode, APK
   SHA-256 and signer using the G2 method.
2. Production baseline: shipped build, non-mutating flows only (no writes to prod) — screens and logs. Then the unfixed
   staging baseline: pairing create/redeem/respond/unlink, recovery, session request→respond→start→ice→end, policy
   update; screenshots, `status`/`error.code` per call, logcat. Redact tokens.
3. Apply P01+P02, then P03, in one stated window; Edge mapping in the same window. No client change.
4. Re-run the identical script; diff screens, codes and p50/p95 latency against baseline.
5. Conflict and negative cases: two requests for one device, sequential then parallel → one succeeds, second
   `409 session_in_progress` (a 500 here is a **release blocker**); a user outside the family calls `request` → 403; a
   direct RPC attempt → 42501 (scratch project only, [15](../../stage1/15-edge-function-test-plan.md) TE-02).
6. Rollback rehearsal, then smoke on 1.0, 1.1, 1.2 (or the supported subset). Pass = no screen/state difference on success
   paths, no new 4xx/5xx, no feature unreachable, no extra tap.

## Open questions

1. Which client ships — Flutter/Kotlin per the brief, or the Capacitor builds in the APK evidence — and does 1.0 still
   reach production through its remote URL?
2. Does any app call `/rest/v1/rpc/*` directly (needs invocation logs), and does any app branch on `error.code`?
3. Who owns the Edge patch that turns `23505` into `409 session_in_progress`, and is it in scope for S2-P03? Who funds and
   owns staging (G6), and is a generic-error conflict acceptable for one release if not?

## Addendum — S2-DOC-02 status correction (2026-11-02)

- **Client compatibility is `BLOCKED — NO APP SOURCE IN THIS REPO`, not "passing".** There is no app source here (§1.1), so nothing in §2 or §5 has been observed; `App compatibility = NOT VERIFIED` still holds, and no §5 checklist item may be reported as satisfied.
- **Nothing was deployed.** S2-P01, S2-P02 and S2-P03 are all `PROPOSED — NOT APPLIED`, defects D-01…D-12 remain **OPEN**, and no Edge Function has been deployed to staging — `G5-E BLOCKED — STAGING FUNCTIONS NOT DEPLOYED`.
- **No client release exists.** A13 (client release) is unsigned and unexecuted. A12 (Firebase/FCM) is unsigned as well: FCM is **not configured**, the `haven-staging` shell (`haven-staging-46822`, project number `381273275501`, Spark) has **zero apps registered and zero credentials**, and Firebase Auth is to remain disabled — Supabase Auth is the only identity authority (all 9 handlers call `db.auth.getUser(token)`).
- **§6's precondition "staging (does not exist; gate G6)" is superseded**: the shell EXISTS (`parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, `ap-northeast-2`, Free/NANO — [S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)) but is an **empty shell** — 0 tables, no schema, no `private.s2_environment` sentinel, no secrets, no test users/principals, no functions (`G5-S BLOCKED — STAGING IS EMPTY (0 tables; no schema, no sentinel, no test principals)`). Steps 2–6 of §6 therefore cannot start, and §4's owner-supplied artefacts 1–5 have not been supplied.
- The staging creation was executed on the owner's direct instruction and is an **executed action awaiting retrospective ratification**, not a signed A0/A2; [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`. The plan of record uses A0–A3 and A5–A13 and has **no A4**.
- **Slots: 2 active / 2 used / 0 remaining** on Free, so §6 step 5's "scratch project only" direct-RPC probe has nowhere to run; and the F4 leaked-password 4xx surface is **not testable on the Free plan** (withdrawn).
- Free-plan auto-pause needs a dated dashboard touch **on or before 2026-11-06** (approximate — no start timestamp recorded). **Screenshots were NOT captured** (viewport unstable, `visibilityState=hidden`), so the screenshot steps in §2/§6 are `NOT VERIFIED`.
- No operational action taken in this pass — no build, request, deploy, dashboard or CLI action, nothing signed.
