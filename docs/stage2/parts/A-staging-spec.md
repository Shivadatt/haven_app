# A — Staging project specification

> **WORKING PAPER — SUBORDINATE AND PARTLY SUPERSEDED (2026-11-02, S2-DOC-02).**
> `docs/stage2/00`–`06`, `README.md` and `evidence/S2-CREATE-01-new-projects.md` are the plan of record and the
> authoritative evidence. Where this part disagrees with them, those documents win. Statements below written before
> 2026-11-02 that describe staging as uncreated, or a plan step as approved/executed, are historical proposals, not
> current status. Read the dated addendum at the end of this file before acting on anything here.

**Status: `PROPOSED — NOT CREATED`.** Planning only. No project, key, user, schema or setting exists, and nothing in
this document authorises a Supabase, Firebase or CLI action. Every observed figure traces to a Stage 1 file; anything
else is labelled **INFERRED** or **PROPOSED**. Stage 1 records `staging = No` and one environment only
([06](../../stage1/06-secrets-and-environments.md) §3).

## 1. Name, region, plan

| Decision | Options | Recommendation | Basis |
| --- | --- | --- | --- |
| Project name | `parent-control-staging`; `haven-control-staging`; `haven-staging` | **`parent-control-staging`** | Mirrors the production name `parent-control-prod` ([01](../../stage1/01-baseline-inventory.md) §1). `haven-control-staging` is acceptable but introduces a second naming stem. Availability is **NOT VERIFIED** — no name is reserved until creation is approved. |
| Region | `ap-northeast-2`; any other | **`ap-northeast-2`** | Production is there ([01](../../stage1/01-baseline-inventory.md) §1). Same-region parity keeps latency and platform behaviour as close as the tier allows. No data-residency requirement is recorded in Stage 1, so this is parity, not compliance — **PROPOSED**. |
| Plan / compute | Free / NANO; paid | **Free, NANO** | Production is Free/NANO ([01](../../stage1/01-baseline-inventory.md) §1). [07](../../stage1/07-ops-and-observability.md) §6 forbids any paid tier without written approval. NANO is compute, not a plan. |
| Organisation | existing org; new org | **existing org** | One owner already controls the production org ([06](../../stage1/06-secrets-and-environments.md) §1). A second org would add an owner and billing surface without improving isolation. |

The staging project must be a **separate project**, not a branch or schema inside `parent-control-prod`
(`hhqgreaoqulmfwfwarhc`). Creating it is **G6**; Stage 1 documents that gate as a decision, not an implementation detail
([05](../../stage1/05-change-plan.md) G6).

## 2. Configuration matrix

`R` = replicate production; `D` = deliberate deviation. Production values are those observed in Stage 1; where a value
was not captured, the row says so rather than guessing.

| Setting | Production (observed) | Staging | R/D | Why |
| --- | --- | --- | --- | --- |
| PostgreSQL major | 17 (server 17.11) | 17 | R | The dump client must be 17.x; a 16.x client refuses or omits 17-only syntax ([12](../../stage1/12-g3-baseline-plan.md) §2). |
| Region | `ap-northeast-2` | `ap-northeast-2` | R | Parity (§1). |
| Compute / plan | NANO / Free | NANO / Free | R | Same tier and defaults; no paid upgrade ([07](../../stage1/07-ops-and-observability.md) §6). |
| Auth providers | Email on; OAuth, phone, SAML, Web3 off | same | R | [01](../../stage1/01-baseline-inventory.md) §4. |
| Signups | On | On | R | Necessary for the signup/`auth.users` trigger test ([12](../../stage1/12-g3-baseline-plan.md) §4a). |
| Confirm email | On | On | R | [01](../../stage1/01-baseline-inventory.md) §4. See the email risk in §4. |
| Anonymous sign-ins | Off | Off | R | [01](../../stage1/01-baseline-inventory.md) §4. |
| Manual linking | Off | Off | R | [01](../../stage1/01-baseline-inventory.md) §4. |
| JWT expiry | 3600 s | 3600 s | R | [01](../../stage1/01-baseline-inventory.md) §10.4. |
| Refresh rotation / reuse | On / 10 s | On / 10 s | R | [01](../../stage1/01-baseline-inventory.md) §10.4. |
| Single session / time-box / inactivity | Off / 0 / 0 | Off / 0 / 0 | R | Pro-plan features, unavailable on Free ([01](../../stage1/01-baseline-inventory.md) §10.4). |
| Leaked-password protection | Off (advisor WARN, F4) | **On** | D | One toggle, no code dependency, and a safe place to validate F4 ([00](../../stage1/00-status-register.md) F4). If strict auth parity is required, leave it off and test F4 as a patch (Open question 6). |
| Site URL / redirect URLs | Not captured | Staging URLs | D | Must not point at production. Production values are not recorded in Stage 1. |
| Data API | Global on; `public` + `extensions`; 0/19 tables; 0/38 functions; auto-expose off; extra search path `public, extensions`; max rows 1000 | same | R | [00](../../stage1/00-status-register.md) P20, [g1-b3b](../../stage1/evidence/g1-b3b-20261029.json) `data_api_exposure`. Do **not** follow `supabase/config.toml`, which declares `public` + `graphql_public` ([12](../../stage1/12-g3-baseline-plan.md) §7 G3-b). |
| Realtime | 4 tables on: `device_commands`, `remote_sessions`, `safety_alerts`, `webrtc_signals` | Mirror all 4 | R | Their SELECT policies are load-bearing today, not latent ([04](../../stage1/04-rls-matrix.md) §1), and N4 is untested ([00](../../stage1/00-status-register.md) N4). Disabling would remove the only path where those policies are exercised today. Publication membership is **not** in a schema dump (C2, [03](../../stage1/03-data-model.md) §5): capture `pg_publication_tables` and re-add explicitly. |
| Extensions | **NOT CAPTURED** | Step 1 capture (§2.2), then install the same set | R | `pg_extension` was never queried (C3, [03](../../stage1/03-data-model.md) §5). Do not infer `pgcrypto`, `uuid-ossp` or `pg_cron` from the examples in that row. |
| Edge Functions | 9 deployed; 2 readable TS, 7 minified | Deploy only if a source path exists | D/blocker | See §2.1. |
| Secrets | Values never read | Fresh staging values | D | Never copy production values ([06](../../stage1/06-secrets-and-environments.md) §3). |
| Cron | Function `cron` + `CRON_SECRET`; caller unknown | Function only, no scheduler | D | Actions are `expire_sessions` / `detect_offline` ([13](../../stage1/13-edge-function-source-inventory.md) §3); what invokes it, and whether `pg_cron` exists, is **NOT VERIFIED**. |
| TURN / STUN | `TURN_SECRET`, `STUN_URL`, `TURN_URL` read in code; values/provider not read | Separate credentials or unset | D | [13](../../stage1/13-edge-function-source-inventory.md) §6 item 4. Never copy production values. |

### 2.1 The Edge Function deployment problem, stated plainly

The nine functions are the client-facing API ([02](../../stage1/02-architecture.md) §1), but **the repository has no
function source**: `supabase/functions/` is absent ([13](../../stage1/13-edge-function-source-inventory.md) §1). Seven of
nine are 2-line minified bundles with no source maps; only `pairing` and `auth-bootstrap` are readable TS, and equality
between capture text and deployed bytes is **INFERRED**, not proven ([13](../../stage1/13-edge-function-source-inventory.md)
§5). Staging therefore cannot be built from this repository.

The documented export routes — `supabase functions download` after a link, or the dashboard ZIP — need the G3 owner
credential and return the deployed bundle, not the original modules ([13](../../stage1/13-edge-function-source-inventory.md)
§7). Options:

1. **Export and redeploy the bundles as-is.** Parity, but opaque 2-line code that cannot be reviewed or patched at module level; needs approval and fresh staging secrets.
2. **Owner supplies the original source.** Best outcome; no such source is known to exist in this repository.
3. **Create staging SQL-only.** Allows L1 schema/RLS/RPC work; blocks every HTTP-level test (L2) until 1 or 2 happens.

Recommendation: create the project and load the schema first; do **not** deploy functions until 1 or 2 is chosen. Never copy production function secrets.

### 2.2 Step 1 — capture extensions (read-only)

Run one read-only statement in the production SQL Editor: `select extname, extversion, n.nspname as ext_schema, pg_get_userbyid(e.extowner) as owner from pg_extension e join pg_namespace n on n.oid = e.extnamespace order by 1;`. Record name, version, schema and owner, then install the identical set in staging. Stop if an extension is unavailable on Free or needs a privilege the owner lacks. Capture only — nothing is installed by this step.

## 3. Schema replication scope

Target: a **schema-identical, data-empty** clone of `parent-control-prod`. Counts are from the G1/B3b runs and the Phase F
report.

| Object | Count | Staging treatment |
| --- | --- | --- |
| Tables in `public` | 19 (183 columns) | Recreate all; no rows ([00](../../stage1/00-status-register.md) P2). |
| Indexes / constraints | 62 / 137 | Recreate; includes pairing-code and command-idempotency uniques ([reports/stage1-final](../../stage1/reports/stage1-final.md) §1). |
| Policies | 21: 15 SELECT, 2 INSERT, 3 UPDATE, 1 DELETE; all `authenticated`, all PERMISSIVE | Recreate verbatim ([00](../../stage1/00-status-register.md) P3). |
| Functions | 38: 14 `public` + 24 `private`; 34 `SECURITY DEFINER` | Recreate all, including bodies. 24 bodies were never read (PA3), but a dump carries them. |
| Triggers | 7 on `public` + 1 on `auth.users` | Recreate the 7 from the dump; the `auth.users` trigger is a separate file (§3.1). |
| Realtime tables | 4 | Re-add publication membership explicitly (§2). |
| Grants | 149 table, 191 column-UPDATE, 24 default-ACL rows | Recreate; `anon` holds 0 table grants, `service_role` all ([04](../../stage1/04-rls-matrix.md) §0a). |
| Roles | `anon`, `authenticated`, `service_role`, `supabase_admin`, … | **Platform-managed. Do not create, dump or restore them; never use `--role-only`** ([12](../../stage1/12-g3-baseline-plan.md) §1, §3). Only grants are replicated. |
| Data rows | 0 | No table data, no `auth.users` rows, no storage objects (production storage is 0 B), no migration-history rows. |

**Default privileges are a deliberate fidelity choice.** The observed `postgres`-owned defaults in `public` grant
`anon`/`authenticated` on future tables (F1, [00](../../stage1/00-status-register.md) F1). Staging should reproduce them so
that its baseline equals production and the eventual F1 fix can be tested as a migration. The `supabase_admin`-owned
defaults are platform-managed; do not hand-set them, and record that half as blocked on role access (F1).

**Function ACLs, including the defect, are replicated.** Two `private` functions keep default `PUBLIC EXECUTE` (F8);
staging must reproduce that, otherwise the E2/TE-02 baseline is not a real baseline. Fixes are applied to staging first
as reviewed migrations, then proposed for production.

### 3.1 Restore sequence and the two objects a dump misses

Stage 1's baseline is a schema-only dump of `public` + `private`; `private` is mandatory because it holds the
implementations behind the 14 public wrappers ([12](../../stage1/12-g3-baseline-plan.md) §3). Two objects need separate handling:

1. **`profiles.id → auth.users(id) ON DELETE CASCADE`** means restore order is `auth` → `public`/`private` → tables →
   functions → triggers → policies → grants → default privileges ([12](../../stage1/12-g3-baseline-plan.md) §4b).
2. **`on_auth_user_created` → `private.handle_new_user()`** lives on a platform table, so it cannot be in the dump. Apply
   the captured `CREATE OR REPLACE TRIGGER` text as its own file after `auth` exists
   ([12](../../stage1/12-g3-baseline-plan.md) §4a). Forgetting it is silent: signup succeeds and no `profiles` row appears.

Verification before calling the clone complete: 19/19 tables with RLS on, 21 `CREATE POLICY`, 38 functions, zero
`COPY`/`INSERT` blocks, and a signup that produces a `profiles` row with `role = 'unset'`
([12](../../stage1/12-g3-baseline-plan.md) §5). G3 has **not** produced its baseline artefact yet, so schema loading is
blocked until the capture is approved and executed. Staging can then serve as the G3 no-diff target that this machine cannot provide
without Docker ([07](../../stage1/07-ops-and-observability.md) §3) — a **PROPOSED** method change needing explicit approval.

## 4. Cost and Free-plan limits (observed figures only)

These are production's observed usage against the dashboard ceilings, not staging's entitlement. Staging starts with no
rows; its schema-only footprint was not measured.

| Dimension | Observed used / ceiling | Source |
| --- | --- | --- |
| Database size | 32 MB / 500 MB | [01](../../stage1/01-baseline-inventory.md) §1 |
| Log ingestion | 0.17 GB / 1 GB | [01](../../stage1/01-baseline-inventory.md) §1 |
| Log query | 33.9 GB / 100 GB | [01](../../stage1/01-baseline-inventory.md) §1 |
| File storage | 0 GB / 1 GB | [01](../../stage1/01-baseline-inventory.md) §1 |
| Egress | 0.12 GB / 5 GB | [01](../../stage1/01-baseline-inventory.md) §1 |
| MAU | 10 / 50,000 (dashboard value) | [01](../../stage1/01-baseline-inventory.md) §1 |

- **Two-active-project ceiling — INFERRED, not observed.** Free-plan organisations are commonly limited to two active
  projects, but Stage 1 explicitly records that the project slot was not inspected
  ([06](../../stage1/06-secrets-and-environments.md) §3 item 4; [07](../../stage1/07-ops-and-observability.md) §6). If the
  ceiling is two, staging consumes the last slot and no `dev` project is possible without a paid plan or deleting a
  project. Treat this as a planning constraint, not a fact.
- **Email-sending limit — NOT VERIFIED.** Stage 1 contains no measurement of auth email volume or any cap. The risk is
  qualitative: confirm-email is on, so synthetic-user onboarding may stall if the Free built-in sender is throttled.
  Mitigation is the admin API to create pre-confirmed users, or staging SMTP (a provider/cost decision), both
  **PROPOSED**. No number is asserted.
- **Quota breach is an availability risk, not an invoice risk.** The exact enforcement behaviour was not observed
  ([07](../../stage1/07-ops-and-observability.md) §2). Do not plan around either outcome.
- **No paid tier, add-on or extra project is enabled without written approval**
  ([07](../../stage1/07-ops-and-observability.md) §6).

## 5. Isolation

- **Separate project and ref.** Staging is not `hhqgreaoqulmfwfwarhc`; every session must verify the project ref before
  running anything and abort on a production match. **PROPOSED** guard, not an existing control.
- **Separate keys.** Staging gets its own anon key, service-role key, DB password, JWT signing secret, and its own
  `PAIRING_HASH_PEPPER`, `CRON_SECRET` and TURN credentials. No production value is copied, and no staging value is used
  against production ([06](../../stage1/06-secrets-and-environments.md) §3). Whether production uses legacy JWT keys or the
  newer API keys is **NOT VERIFIED** ([06](../../stage1/06-secrets-and-environments.md) §1); record staging's model rather
  than assuming parity.
- **No production data.** No table rows, no `auth.users`, no location history, no storage objects. The schema-only dump is
  the only production database artefact that crosses; a data-bearing dump is out of scope ([06](../../stage1/06-secrets-and-environments.md) §3 item 3).
- **Synthetic identities only.** Fixtures use reserved-domain emails and fixed test UUIDs; no real parent, child or
  device identifiers. The exact fixture set belongs to the G5 validation part, not this spec. **PROPOSED.**
- **No production credentials in staging, and vice versa.** Production's service-role key must never be set as a staging
  function secret, and staging's keys must never be shipped in a production client build.
- **Single owner, no second approver.** The whole org has one owner ([06](../../stage1/06-secrets-and-environments.md) §1).
  Staging inherits that limitation; approval is owner-only, and the gap should be recorded rather than implied away.
- **Teardown.** Export redacted test evidence and the fixture manifest; stop any scheduler; delete the staging project in
  the dashboard as owner; revoke its API keys and delete its DB password, function secrets and local `.env.staging`/CLI
  link entries; record the ref, date and operator; confirm production is untouched. **PROPOSED** — no teardown
  automation exists in this repository.

## 6. Approval checklist — creating the project

Creation approval is not schema-load or deploy approval. Each item needs an explicit owner decision and a written record.

- [ ] Name, region `ap-northeast-2`, plan Free/NANO and existing organisation approved.
- [ ] Project-slot and billing impact confirmed; the two-project ceiling is treated as a real constraint (INFERRED).
- [ ] G3 baseline capture approved, or an explicit exception recorded for loading a schema before the baseline artefact exists.
- [ ] Step-1 read-only captures approved: `pg_extension`, `pg_publication_tables`, and the dashboard states for SSL
      enforcement and connection logging (both **NOT CAPTURED** in Stage 1).
- [ ] Schema-load method and operator named; database password custody agreed (interactive prompt, never committed).
- [ ] Edge Function strategy chosen: export/redeploy bundles, owner-supplied source, or SQL-only staging.
- [ ] Fresh staging secrets approved and their storage location named; no production values copied.
- [ ] Synthetic fixture set and user-creation method (admin API pre-confirmed vs public signup) approved.
- [ ] Data API settings approved: `public` + `extensions`, 0 tables, 0 functions, auto-expose off.
- [ ] Realtime mirroring of the four tables approved, including publication capture and re-add.
- [ ] Deviations approved: staging URLs, leaked-password toggle, no cron scheduler, separate TURN/STUN or unset.
- [ ] Attestation recorded: no production data, no production credentials, no production writes.
- [ ] Teardown owner and date agreed before creation, not after.
- [ ] Change record opened; production remains untouched until a separate, itemised approval.

## Open questions

1. Is the Free-plan two-active-project ceiling actually binding on this org, and does staging consume the last slot?
   Stage 1 did not inspect it.
2. Which extensions and versions are installed in production (`pg_extension` never run), and are they all available on
   Free in `ap-northeast-2`? This is the first read-only capture, not an assumption.
3. Can the source be exported with the G3 credential, and does the owner hold an unminified original? If neither,
   staging stays SQL-only and every HTTP-level case remains blocked.
4. What invokes `cron`, on what schedule, and is `pg_cron` installed? Neither is recorded in Stage 1.
5. Which TURN/STUN provider and values does production use? The environment names are known; the provider and deployed
   values were deliberately not read.
6. Should staging mirror the F1/F8 defects for a true baseline and fix them by migration, or be created hardened? This
   spec recommends mirror-then-patch; a hardened creation makes the E2/TE-02 baseline unreal.
7. Is staging allowed to serve as the G3 no-diff restore target in place of the unavailable Docker stack? This changes
   G3's documented method and needs explicit approval.
8. Is the leaked-password toggle (F4) enabled in staging as a deliberate deviation, or deferred to a patch?

## Addendum — S2-DOC-02 status correction (2026-11-02)

- The status line `PROPOSED — NOT CREATED` is **superseded**: the Supabase staging shell EXISTS — `parent-control-staging`, ref `dzonzgngwxclhfnvxtvu`, region `ap-northeast-2`, Free plan, NANO compute ([S2-CREATE-01](../evidence/S2-CREATE-01-new-projects.md)).
- It is an **empty shell only**: no schema loaded, no `private.s2_environment` sentinel, no secrets, no test users/principals, no Edge Functions deployed, 0 tables. Every row of §2 and §3 therefore describes work NOT DONE, not a property of the existing project.
- §1 name candidates are **settled**: `parent-control-staging`. Availability is no longer in question.
- Slot arithmetic (§4, Open question 1): Free gives 2 active, **2 used, 0 remaining**. Any statement about a remaining or free slot — including a `dev` project — is superseded.
- The F4 leaked-password-protection deviation in §2 is **withdrawn / untestable on the Free plan**; the toggle is not available there.
- A Firebase staging shell also exists (`haven-staging` / `haven-staging-46822`, project number `381273275501`, Spark plan, Analytics off, Gemini assistance off, environment type Unspecified, **zero apps, zero credentials**); it is outside this part's Supabase scope but bears on §5 isolation. Firebase Auth is to remain disabled — Supabase Auth is the only identity authority (all 9 Edge handlers call `db.auth.getUser(token)`).
- Creation was executed on the owner's direct instruction and is an **executed action awaiting retrospective ratification**, not a signed A0/A2 approval. [`approval-package-a0-a2.md`](../approval-package-a0-a2.md) is `SUPERSEDED — DO NOT SIGN`; the replacement is [`approval-package-v2-ratification-and-forward.md`](../approval-package-v2-ratification-and-forward.md) (A2′ = sentinel + approved settings only; it authorises no schema load, no secrets, no Firebase app registration).
- Free-plan auto-pause: a dated dashboard touch is required on or before **2026-11-06**; no start timestamp was ever recorded, so the deadline is approximate. Screenshots were never captured, so any screenshot-based confirmation of the figures above is `NOT VERIFIED`.
- No operational action taken in this pass — documentation only; nothing created, configured, deployed or signed.
