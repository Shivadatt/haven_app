-- ===========================================================================
-- A3c - NOTIFICATION BACKEND (push-token store + notification queue).
-- STAGING ONLY: project `parent-control-staging` / ref `dzonzgngwxclhfnvxtvu`.
--
-- Status: PREPARED - NOT EXECUTED. No SQL in this file has been run anywhere.
-- Authoring pass performed with local file tools only: no browser, no Firebase
-- console, no Supabase dashboard, no CLI, no REST, no DB connection, no curl.
--
-- PURPOSE
--   Give push delivery a schema home. Today it has none:
--     * `firebase/SETUP-CHECKLIST.md`:99  - "There is no `push_tokens` table and
--       no token column on `devices` today."
--     * `firebase/SETUP-CHECKLIST.md`:100 - "No Edge Function currently sends FCM."
--     * `firebase/SETUP-CHECKLIST.md`:101 - token rotation handling does not exist.
--     * `S2-A3-database-audit.md`:410-412 - all **183** captured production columns
--       (`g1-q8-20261029.json`) searched for push/fcm/token/registration/subscription/
--       endpoint/notification. The only `token`-bearing objects are
--       `pairing_requests.token_id (uuid)` and `device_pairing_tokens` - both PAIRING
--       artefacts, not push. `devices` has exactly 25 columns and none is sendable-to.
--   This file creates two new application tables (`public.push_tokens`,
--   `public.notification_queue`), the constraints that make token ownership
--   non-transferable by accident or by attack, the grants/RLS posture, and the
--   real-time decision. It deliberately does NOT create any function body.
--
-- READ THIS FIRST - NO FCM DELIVERY IS POSSIBLE TODAY
--   A schema cannot send a push. Firebase project `haven-staging` /
--   `haven-staging-46822` / project number `381273275501` has
--   **zero registered apps** - `S2-INSP-03-read-only-reconfirmation.md`:119 records
--   the Settings/General value for "Your apps" verbatim as
--   `There are no apps in your project` - and its left product navigation contains
--   **only** `Project Overview` and `Settings`, i.e. **no Firebase product is enabled**
--   (same file, `:107`-`:108`, `:132`-`:134`). There is therefore **no FCM sender, no
--   registration token can be minted, and nothing in this file can be exercised
--   end-to-end.** `01-staging-project-proposal.md`:200 (topology row 5) grades push
--   transport as `DOES NOT EXIST`. Loading this file produces an empty, correct,
--   unreachable store. That is the honest state, and it is not a defect of the design.
--
-- ARCHITECTURE RULE THIS FILE OBEYS (owner ruling for this phase)
--   Firebase = identity + push TRANSPORT only. Supabase = all data, token STORAGE,
--   the QUEUE, scheduling and the server-side SEND logic. No Firestore as an
--   application database. No Firebase Cloud Functions. No duplicated application
--   records in Firebase. Consequently every row below lives in Postgres, and the only
--   Firebase-side object this file assumes is a token string arriving over the wire.
--
-- APPROVALS REQUIRED BEFORE ANY STATEMENT HERE EXECUTES
--   A3   - the G3 schema load. This file is an ADDENDUM, not a load: it must run
--          AFTER `public.profiles`, `public.families`, `public.devices` and
--          `private.s2_environment` exist, because every FK and the sentinel depend
--          on them. `04-risks-rollback-approvals.md`:212 records A3 as UNSIGNED and
--          `NOT LOAD-READY`; the chain is A2'(a) executed -> A3 load -> A2'(b).
--   A12  - any Firebase-side action. `04-risks-rollback-approvals.md`:220 records
--          A12 as UNSIGNED as a forward block, its prohibition amended on 2026-11-02
--          by ratification option (i) (also `:94`, R-36) to: "project creation
--          permitted under owner instruction; **app registration, FCM configuration,
--          credentials and settings changes remain prohibited**." Nothing here asks
--          for an app, a credential or an FCM setting. NOTE ON NAMING: the repository
--          contains **no approval row literally called `A12-R`**; the amended wording
--          above is the only "A12-revised" artefact that exists, and this file cites it
--          rather than inventing a gate.
--   A2'(b) - the Realtime publication half (`00-stage2-execution-plan.md`:136;
--          `S2-A3-database-audit.md`:536-541). Its signed text enumerates exactly four
--          tables - `device_commands`, `remote_sessions`, `safety_alerts`,
--          `webrtc_signals`. **Adding `public.notification_queue` to that publication
--          is outside A2'(b) as written** and needs an amended clause; see section 6.
--   A9   - secret NAMES only (`FCM_PROJECT_ID`, the service-account secret name). This
--          file sets no secret.
--   A13  - the identity ruling. **RULED while this addendum was being authored**: the
--          owner selected the **Third-Party Auth bridge** - "Register Firebase as an
--          external JWT issuer on Supabase's Third-Party Auth page ... Supabase stays the
--          single session authority and verifies Firebase-issued tokens"
--          (`S2-EXEC-08-identity-decision-A13-final.md`:18-22), status
--          `DECIDED - INSTRUMENT PREPARED, FENCE UNSIGNED`, explicitly **not** `APPROVED`
--          (`:28`). This is the option this file anticipated as V-3
--          (`S2-A1-auth-architecture.md`:307), and it is the outcome under which
--          `auth.uid()` is unchanged - so **no column, key, FK or policy in this file
--          needs to change** (see section 8, O-8). Citation hazard still worth naming:
--          `04-risks-rollback-approvals.md`:221 attaches the label A13 to "Client
--          release"; `S2-EXEC-08`:60 states A13 "replaces **only that row**" and amends
--          row 1 (`01-staging-project-proposal.md`:196, Supabase Auth as single identity
--          authority) "by a pointer" (`:72`). Supabase Auth therefore **remains** the
--          session/authorization authority - which is why the ownership key below stays
--          `profiles.id` / `auth.uid()`.
--
-- PRODUCTION IS OFF-LIMITS
--   `parent-control-prod` / `hhqgreaoqulmfwfwarhc` was never opened by this pass and
--   must never be opened by the executor. Its captured schema is the *reference*, and
--   every type/default/constraint below is copied from that capture
--   (`g1-q5`, `g1-q8`, `g1-q4`, `g1-q1`, `g1-q2`, `g1-b3b`), not from a live read.
--
-- NO SECRET VALUES
--   The FCM server key / legacy API key, the service-account JSON and `FCM_PROJECT_ID`
--   appear in this file as NAMES ONLY. No value, no placeholder value, no digest.
--   HARD RULE, restated because it is the one that gets broken: **a Firebase
--   service-account credential must never reach a Flutter or Kotlin client, never be
--   bundled in an APK/AAB, never be placed in a client env file, and never be pasted
--   into a document, evidence file or screenshot.** It is a server-tier secret only.
--   `firebase/SETUP-CHECKLIST.md`:92 already records this ("it must never enter the
--   repo, a mobile app, or this document"); `.gitignore` patterns cover
--   `service-account*.json` and `*-firebase-adminsdk-*.json` (`:93`-`:94`).
-- ===========================================================================


-- ===========================================================================
-- 0. TRANSACTION + WRONG-PROJECT GUARDS
-- ===========================================================================

begin;

-- One transaction, matching the house style of patches/S2-P03-e4-session-invariant.sql
-- (`begin` ... `commit`, sentinel first, then prechecks, then DDL). Any failure below
-- rolls the whole addendum back, leaving no half-created table.
set local lock_timeout = '5s';
set local idle_in_transaction_session_timeout = '60s';

-- 0.1 WRONG-PROJECT SENTINEL, verbatim in intent to S2-P03 lines 21-33. Depends on
--     `private.s2_environment`, which is created by **A2'(a), BEFORE** the A3 load
--     (`S2-A3-database-audit.md`:442-443, :537). Absent sentinel = abort, never "run
--     anyway". This is also the guard that keeps the file from executing against
--     production, where the sentinel does not exist by construction.
do $sentinel$
begin
  if to_regclass('private.s2_environment') is null then
    raise exception 'A3c: sentinel private.s2_environment is missing; refusing to run outside staging';
  end if;
  if not exists (select 1 from private.s2_environment where environment = 'staging') then
    raise exception 'A3c: sentinel does not read ''staging''; refusing';
  end if;
end $sentinel$;

-- 0.2 ADDENDUM-ORDER PRECHECK. This file is meaningless before the A3 load, and a
--     half-loaded schema is worse than no load. Abort with a readable message. Four
--     separate flat tests, deliberately, so the block parses with no loop-variable
--     assumptions: `to_regclass` is the same guard S2-P03 uses for its sentinel.
do $precheck$
begin
  if to_regclass('public.profiles') is null then
    raise exception 'A3c: public.profiles absent; the A3 schema load has not run';
  end if;
  if to_regclass('public.families') is null then
    raise exception 'A3c: public.families absent; the A3 schema load has not run';
  end if;
  if to_regclass('public.devices') is null then
    raise exception 'A3c: public.devices absent; the A3 schema load has not run';
  end if;
  if to_regclass('public.audit_logs') is null then
    raise exception 'A3c: public.audit_logs absent; the A3 schema load has not run';
  end if;
end $precheck$;

-- 0.3 IDEMPOTENCY PRECHECK. Refuse rather than skip silently: a partially applied
--     addendum must be reasoned about, not patched over.
do $idempotency$
begin
  if to_regclass('public.push_tokens') is not null
     or to_regclass('public.notification_queue') is not null then
    raise exception 'A3c: one of push_tokens / notification_queue already exists; aborting so state is not guessed';
  end if;
  if exists (select 1 from pg_constraint where conname = 'devices_id_child_user_id_key') then
    raise exception 'A3c: devices_id_child_user_id_key already exists; aborting (section 2.4 would double-apply)';
  end if;
end $idempotency$;


-- ===========================================================================
-- 1. SCHEMA CHOICE: WHY `public`, NOT `private`
-- ===========================================================================
-- The captured convention is unambiguous and this file follows it rather than
-- inventing a third option:
--
--   * APPLICATION TABLES ARE IN `public`. Every index definition in the capture is
--     schema-qualified to public: `g1-q4-20261029.json` records
--     `CREATE UNIQUE INDEX devices_pkey ON public.devices ...` and
--     `CREATE UNIQUE INDEX device_commands_device_idempotency_key ON public.device_commands ...`
--     for all 19 captured tables. `g1-q6` `role_memberships`/`table_grants` carry the
--     same placement, and `g1-q1` lists the 19 RLS-enabled tables unqualified, i.e. the
--     search path the capture used.
--   * HELPER FUNCTIONS ARE IN `private`. `g1-b3b-20261029.json.inventory` is a
--     function inventory keyed by `schema_name` and yields 38 functions =
--     **14 public + 24 private** (`S2-A3-database-audit.md`:184). The `private` schema
--     exists to hold predicates and triggers, not rows:
--     `private.is_family_parent`, `private.is_family_member`,
--     `private.shares_active_family`, `private.handle_new_user`,
--     `private.realtime_topic_allowed`, `private.record_audit`.
--   * `private` is reachable but not row-bearing: `g1-b3b.schema_usage` records
--     `has_schema_privilege on schema private` = anon false / authenticated true /
--     service_role true, and its own note calls it out as exactly that - *usage*, not
--     table placement. `CREATE SCHEMA` count in the capture is **2**
--     (`S2-A3-database-audit.md`:43), i.e. `public` and `private`, no third.
--   * DECISIVE CORROBORATION (finding **X-7**, `S2-A3-database-audit.md`:93): **0
--     statements grant `USAGE` on schema `private`** in the reconstructed artefact -
--     "The artefact creates `private`, grants nothing on it, and every helper function
--     lives in it", despite `g1-b3b.schema_usage` evidencing `authenticated=true`. Rows
--     placed in `private` would therefore sit in a schema the load does not grant anyone
--     access to, which is a silent-trap table: it exists, nobody can read it, and the
--     A3 equivalence diff cannot explain why. This is a second, independent reason for
--     `public` - and it is the same X-7 defect that hardens section 5.3(b)'s blocker on
--     the family-parent policy.
--
-- DECISION: `public.push_tokens` and `public.notification_queue`. Both are application
-- records with an owning family and a client-visible lifecycle, so they belong with the
-- other 19. Putting rows in `private` would invent a placement the capture does not
-- show, would sit outside every RLS posture decision in `04-rls-matrix.md`, and would
-- make the A3 staging/production equivalence diff uninterpretable.
-- Function names that this file references but does NOT create stay in `private`, which
-- is where the captured convention puts them.


-- ===========================================================================
-- 2. PUBLIC.PUSH_TOKENS - the token store
-- ===========================================================================
-- One row per (provider, device) registration. NOT one row per (user, token): device is
-- the unit of a push registration, and the user is derived FROM the device, which is the
-- whole basis of the anti-theft control in section 3.

create table public.push_tokens (
  -- 2.1 surrogate PK. uuid + gen_random_uuid() is the capture's universal pattern:
  --     `devices`, `device_commands`, `audit_logs`, `device_apps`, `families` all use
  --     `uuid NOT NULL gen_random_uuid()` (g1-q8 ordinal 1). No bigserial exists in any
  --     of the 183 columns, so this table creates NO sequence and needs NO sequence GRANT.
  id                   uuid                     not null default gen_random_uuid(),

  -- 2.2 provider discriminator. `fcm` today, extensible by editing the CHECK only.
  --     Justification for the discriminator column rather than a bare token:
  --     `S2-A1-auth-architecture.md`:165 requires uniqueness on `(provider, external_uid)`
  --     for the identity bridge, so `(provider, <value>)` is already the programme's
  --     composite-uniqueness idiom. Default mirrors `devices.platform` default
  --     `'android'::text`. The CHECK lists exactly one value because exactly one provider
  --     is evidenced (`01-staging-project-proposal.md`:200 row 5, FCM). Adding apns is a
  --     CHECK edit, not a migration.
  provider             text          not null default 'fcm',

  -- 2.3 the registration token itself. text, not uuid: FCM tokens are opaque strings and
  --     the capture's precedent for opaque wire strings is `devices.installation_id`
  --     (`text NOT NULL`, g1-q8 ordinal 4) and `device_pairing_tokens.code_hash` (`text`).
  --     Kept in the clear ON PURPOSE and this is a recorded decision, not an oversight -
  --     see the SECURITY block (section 7) for the reasoning and for the hashed-lookup-
  --     key alternative that CANNOT be chosen here because pgcrypto's presence is
  --     unverified (`S2-A3-database-audit.md`:636-638: extensions were never queried;
  --     `pg_extension` is on the missing-evidence list).
  token_value          text          not null,

  -- 2.4 owning user. The ownership key is the **Supabase side** - `profiles.id`, the
  --     column that `auth.uid()` compares against in all 21 captured policies (g1-q2).
  --     `devices.child_user_id` is itself `uuid NOT NULL` with an FK to profiles
  --     (`devices_child_user_id_fkey -> profiles`, g1-q5), so this column reproduces the
  --     captured ownership chain exactly. Identity-provider neutrality requirement: no
  --     firebase_uid column here - see 2.11 and section 8.
  owner_user_id        uuid          not null,

  -- 2.5 owning device. NOT NULL because the capture makes every device child-owned
  --     (`devices.child_user_id` is NOT NULL), so a token without a device cannot be
  --     attributed to a human at all, and an unattributable token is unauditable.
  owner_device_id      uuid          not null,

  -- 2.6 platform label. Deliberately a *copy* of `devices.platform` rather than a join,
  --     matching how `device_apps`/`device_policies`/`safety_alerts` each carry their own
  --     `family_id` copy instead of deriving it (g1-q5). Length bound is copied verbatim
  --     from `devices_platform_check` = `char_length(platform) >= 1 and <= 32`.
  platform             text          not null,

  -- 2.7 lifecycle state, three values, and nothing else. 'active' = sendable-to;
  --     'stale' = the provider rejected it, kept for the cleanup window; 'revoked' =
  --     terminal, kept for audit. The three-state shape is the narrowest state set the
  --     evidence actually supports: `devices.status` uses pending/active/revoked and
  --     `device_commands.status` uses a five-value enum, so `text + CHECK = ANY (ARRAY[...])`
  --     is the captured mechanism, not a native enum (no `CREATE TYPE` appears anywhere
  --     in the capture; `S2-A3-database-audit.md`:475 records 0 extensions/functions/
  --     triggers/policies in the emitted artefact).
  status               text          not null default 'active',

  -- 2.8 last time the provider accepted a send to this token. Distinct from
  --     `devices.last_seen_at` (g1-q8) which is a device-heartbeat fact, not a
  --     push-transport fact; conflating them would duplicate one signal across two
  --     tables, which the owner rule forbids.
  last_seen_at         timestamptz   not null default now(),

  -- 2.9 consecutive provider rejections since the last success. Integer + `>= 0` CHECK
  --     copies `device_commands_attempts_check` = `attempts >= 0` and the
  --     `attempts integer NOT NULL DEFAULT 0` default verbatim.
  consecutive_failures integer       not null default 0,

  -- 2.10 last machine-readable provider reason (e.g. an HTTP v1 error name). Stored as a
  --      CODE, never as a message, because a provider message can quote the token in its
  --      error text - see section 7. Bound copies the `<= 500` idiom but is tightened,
  --      and the tightening is a proposal, flagged in section 8.
  last_error_code      text          null,

  -- 2.11 set when status -> 'stale'. Nullability is the proof of the transition: the
  --      CHECK in 2.14 forbids the state without the timestamp.
  stale_at             timestamptz   null,

  -- 2.12 set when status -> 'revoked'. Mirrors `devices.credential_revoked_at`
  --      (`timestamptz NULL`, g1-q8 ordinal 12) - the capture's established shape for a
  --      terminal credential timestamp, including leaving it NULL rather than duplicating
  --      the status bit.
  revoked_at           timestamptz   null,

  -- 2.13 set when this row's token superseded a previous token for the SAME device
  --      (reinstall / refresh, `SETUP-CHECKLIST.md`:101). Precedent for the column name
  --      and nullability is real, not invented: `child_contact_ids.rotated_at` is a
  --      `timestamptz NULL` in g1-q8.
  rotated_at           timestamptz   null,

  -- 2.14 audit pair copied from the capture's universal `created_at`/`updated_at`
  --      timestamptz NOT NULL now() (both present on devices, families, profiles,
  --      audit_logs). NOTE, stated plainly: the capture's artefact emits **0 triggers**
  --      (`S2-A3-database-audit.md`:475), so nothing here proves `updated_at` is
  --      maintained automatically. Whether `devices.updated_at` is trigger-maintained is
  --      `NOT VERIFIED`; this table inherits that same open question rather than
  --      inventing a trigger to answer it (section 8, item O-3).
  created_at           timestamptz   not null default now(),
  updated_at           timestamptz   not null default now(),

  -- ---- keys --------------------------------------------------------------
  constraint push_tokens_pkey primary key (id),

  -- ---- FKs, with ON DELETE taken from the captured rule, not from taste -----
  -- The capture's rule is consistent across all 137 FK rows in g1-q5:
  --   * a row that CANNOT EXIST WITHOUT its device -> `references devices ... on delete
  --     cascade`: device_apps, device_commands, device_policies, remote_sessions,
  --     safety_alerts (5 of 5 device-owned tables).
  --   * a row that merely RECORDS A HUMAN ACTOR -> `references profiles ... on delete
  --     set null`: audit_logs_actor_user_id_fkey, device_commands_created_by_fkey,
  --     device_policies_created_by_fkey, remote_sessions_ended_by_fkey,
  --     safety_alerts_acknowledged_by_fkey (5 of 5 attribution columns).
  --   * a row that is OWNED by a human -> `on delete cascade`: child_contact_ids,
  --     family_members, remote_sessions parent/child, devices_child_user_id_fkey.
  -- A push token is owned, not an attribution, and it cannot exist without its device.
  -- Both FKs therefore CASCADE. No SET NULL: a token row with a NULL owner is an
  -- un-attributable credential that could still be sent to, which is the worst row in
  -- this product. Cascade also gives the deletion path for free: dropping the device or
  -- the child profile removes the sendable credential, which `03-data-model.md`:67
  -- demands of erasure ("must reach 19 tables plus storage plus FCM tokens").
  constraint push_tokens_owner_device_fkey
    foreign key (owner_device_id) references public.devices (id) on delete cascade,
  constraint push_tokens_owner_user_fkey
    foreign key (owner_user_id) references public.profiles (id) on delete cascade,

  -- ---- CHECKs, each one a copy of a captured mechanism ---------------------
  constraint push_tokens_provider_check
    check (provider = any (array['fcm'])),
  constraint push_tokens_platform_check
    check (char_length(platform) between 1 and 32),
  constraint push_tokens_status_check
    check (status = any (array['active','stale','revoked'])),
  -- Length guard on the token, NOT a format regex. Justified: `devices.installation_id`
  -- uses `char_length between 8 and 128` and `devices.secret_hash` uses a regex
  -- `^[0-9a-f]{64}$` - but a regex here would be an invention, because **no FCM token has
  -- ever been observed by this programme**: the staging Firebase project has zero apps
  -- (`S2-INSP-03`:119), so there is no sample to derive a pattern from. The upper bound
  -- below is provisional and flagged in section 8 (item O-2).
  constraint push_tokens_token_value_check
    check (char_length(token_value) between 8 and 512),
  constraint push_tokens_consecutive_failures_check
    check (consecutive_failures >= 0),
  constraint push_tokens_last_error_code_check
    check (last_error_code is null or char_length(last_error_code) between 1 and 500),
  -- Named consistency CHECKs: the capture has direct precedent for exactly this device,
  -- `devices_revoked_credential_consistency` = `check (status <> 'revoked' or secret_hash
  -- is null)` (g1-q5). These make the state machine partly declarative - a row cannot
  -- claim a state without carrying its proof timestamp, so no writer, including
  -- service_role, can write an impossible state even though RLS does not bind it.
  constraint push_tokens_stale_state_consistency
    check (status <> 'stale' or stale_at is not null),
  constraint push_tokens_revoked_state_consistency
    check (status <> 'revoked' or revoked_at is not null),
  constraint push_tokens_active_state_consistency
    check (status <> 'active' or (stale_at is null and revoked_at is null))
);

-- 2.14b WHAT THE CHECK SET DELIBERATELY DOES *NOT* COVER, recorded instead of padded.
--     Three plausible constraints were considered and rejected as inventions:
--       (i)  a rule tying `consecutive_failures` to `status` - the evidence gives no
--            threshold at which failures force a transition (3.5/3.6), and a CHECK that
--            accepts every combination is worse than an absent one because it reads like
--            coverage;
--       (ii) `check (revoked_at is null or stale_at is null)` - FALSE by design: a token
--            normally goes active -> stale -> revoked, so it must be allowed to carry both
--            timestamps; that ordering is a function concern (3.6), not a row invariant;
--       (iii) a CHECK that `owner_user_id` matches `devices.child_user_id` - impossible,
--            a CHECK cannot reference another table, which is exactly why section 2.4
--            exists as a composite FK instead.
--     Every CHECK that IS present is a copy of a captured predicate or of the
--     `devices_revoked_credential_consistency` device (g1-q5).

comment on table public.push_tokens is
  'Push registration tokens. One row per (provider, device). Child-device credential - see A3c section 7. PREPARED - NOT EXECUTED.';

-- ===========================================================================
-- 2.4 THE OWNERSHIP-CONSISTENCY CONTROL (composite FK) - the one change to an
--     EXISTING table, and its cost, stated up front.
-- ===========================================================================
-- A CHECK cannot look at another table, so "the owner_user_id must be the human who
-- actually owns owner_device_id" is not expressible as a row constraint - and the honest
-- capture confirms nobody solved it today: `device_apps`, `device_commands`,
-- `device_policies`, `remote_sessions` and `safety_alerts` all carry an independent
-- `family_id` FK and a `device_id` FK with NO cross-check that the two agree (g1-q5).
-- This table does not repeat that gap, and it closes it declaratively, with no function:
-- `devices.child_user_id` is the single source of device ownership
-- (`devices_child_user_id_fkey -> profiles`, g1-q8 ordinal 3), so make that pair a key
-- and reference it.
alter table public.devices
  add constraint devices_id_child_user_id_key unique (id, child_user_id);

alter table public.push_tokens
  add constraint push_tokens_device_owner_matches_device_fkey
    foreign key (owner_device_id, owner_user_id)
    references public.devices (id, child_user_id) on delete cascade;

-- Effect: no row can ever claim an owner who is not that device's owning child. The
-- pairing (device D owned by A, owner_user_id = B) is rejected by the FK on insert,
-- before any policy, trigger or function runs, and it is rejected for `service_role`
-- too - which matters, because section 5 explains that RLS binds no live caller.
-- DELIBERATE REDUNDANCY, noted so it is not read as an oversight: 2.5 already FKs
-- `owner_device_id -> devices(id)`, and the constraint here FKs the PAIR. The single
-- column FK is kept on purpose, because the two fail differently - the pair FK is the
-- ownership rule, the single FK is the device-existence rule, and if the owner ever
-- removes section 2.4's `devices` constraint (see the divergence note below) the device
-- FK alone still prevents an orphaned token. Postgres does not deduplicate these and
-- the extra index on `devices(id, child_user_id)` costs nothing at the scale the
-- capture shows: `03-data-model.md`:33 records `devices` as **EXISTS with 14 rows**, and
-- the same line flags its own open question - "may already embed device metadata and
-- push state" - which this file answers in the negative from `g1-q8`: none of the 25
-- columns is push state (section 9, item O-9).
--
-- DIVERGENCE DISCLOSURE (must be read before A3 sign-off, not after):
-- `devices` is a reconstructed production table and `04-risks-rollback-approvals.md`:212
-- makes the A3 artefact the equivalence baseline. `add constraint ... unique` is
-- ADDITIVE - it drops no column, changes no type, breaks no inbound FK, and cannot make
-- any previously-valid row invalid, since (id) is already the PK so (id, child_user_id)
-- is trivially unique over any live data - but it does make staging one constraint
-- DIVERGENT from production. It also takes a brief ACCESS EXCLUSIVE lock and re-validates,
-- hence `set local lock_timeout` in section 0. The alternatives considered and rejected:
-- (i) enforce in a trigger - invents an object body, forbidden; (ii) a partial unique
-- index alone - does not constrain the (device,user) PAIRING, only the value; (iii) leave
-- it open - reproduces the defect the capture already has on five tables. If the owner
-- rules that staging must stay byte-identical to production, DELETE both statements in
-- this section and the composite FK, and the rest of the file still loads; the anti-
-- takeover control in section 3 survives on its own, and the pairing check becomes an
-- explicit item in the Edge Function contract (section 8, item O-1) instead of a schema
-- guarantee. That is the recorded trade-off and it is the owner's to make.

-- ===========================================================================
-- 3. THE ANTI-TOKEN-THEFT CONTROL, AS MECHANISM
-- ===========================================================================
-- Threat, stated precisely: principal B submits a token that is already registered to
-- principal A, hoping the write *silently reassigns* A's push target to B - or, in the
-- parental-control inversion that matters more here, hoping to *detach* a guardian's
-- alerts from a child's device, or to bind a child's device to a family B controls. A
-- token is not a credential that grants access; it is an ADDRESS. Stealing one does not
-- read data - it redirects the notification stream, and in this product it can silence a
-- safety alert. That is why this is a schema constraint, not a code-review note.

-- 3.1 THE CONTROL: a partial UNIQUE index on the value itself, scoped to sendable rows.
--     Two layers, both enforced by the index, so both hold even for `service_role`:
--       (a) one active row per token VALUE, globally;
--       (b) one active row per (provider, DEVICE), so a device cannot hold two live
--           registrations that a send loop would fan out to.
--     The partial-unique form is a captured device, not an invention:
--     `g1-q4-20261029.json` records
--     `CREATE UNIQUE INDEX devices_one_active_per_child ON public.devices USING btree
--        (child_user_id) WHERE (status = 'active'::text)`,
--     and patches/S2-P03-e4-session-invariant.sql uses the same shape
--     (`remote_sessions_one_live_per_device ... where status in (...)`), cited for
--     exactly that reason at `S2-A1-auth-architecture.md`:165-167.
create unique index push_tokens_one_active_value_per_provider
  on public.push_tokens (provider, token_value)
  where status = 'active';

create unique index push_tokens_one_active_per_device
  on public.push_tokens (provider, owner_device_id)
  where status = 'active';

-- 3.2 WHY UNIQUENESS ON (user, token) WOULD HAVE BEEN THE BUG.
--     `unique (owner_user_id, token_value)` is the intuitive index and it is worthless
--     here: it constrains each owner separately, so A's row and B's row for the SAME
--     token both satisfy it and A's alerts silently move to B. The index is therefore
--     keyed on the VALUE with NO owner column, deliberately, and the owner appears only
--     in section 2.4's composite FK. This inversion is the whole design.

-- 3.3 WHAT HAPPENS ON A CONCURRENT RE-REGISTRATION (the enforceable answer).
--     Two writers race for the same value, A's committed row already active:
--       * Writer B issues INSERT. The index on 3.1 (a) conflicts. B blocks on the index
--         entry until A's transaction resolves; if A commits, B receives SQLSTATE 23505
--         unique_violation. B never sees a successful write and never learns A's owner
--         id, token or family from the error, because 23505 carries no row payload.
--       * If A rolls back, B's insert proceeds - correct, since nothing was ever
--         registered.
--       * Two simultaneous INSERTs of a token that is NOT yet active are settled by the
--         same index: exactly one commits, the other gets 23505. No read-modify-write
--         window exists, because the check is an index, not a `select` in a function.
--     THEREFORE THE PROHIBITION THAT MAKES THIS TRUE, written as a contract:
--       ** the writer must NOT use `on conflict (provider, token_value) where status =
--       'active' do update`.** An `ON CONFLICT DO UPDATE` on this index is precisely the
--       silent takeover: it converts a security violation into a routine overwrite, and
--       the index that detects the theft also authorises it. The permitted idempotent
--       shape is `on conflict ... do nothing`, which is what the programme's own verified
--       precedent uses - `private.handle_new_user()` uses `insert ... on conflict (id) do
--       nothing` (`g1-b3b.bodies`, cited at `S2-A3-database-audit.md`:289-291 and
--       `S2-A1-auth-architecture.md`:168-170). `DO NOTHING` is idempotent for the LEGIT
--       case (same device re-registering its own unchanged token) and a no-op that must
--       be post-checked for the theft case. A 23505 or a zero-row `DO NOTHING` result on
--       a row whose `owner_device_id` differs from the caller's device is a SECURITY
--       EVENT and must be written to `audit_logs` as one - `audit_logs` already exists
--       with `event_type text NOT NULL`, `device_id uuid NULL` and `metadata jsonb`
--       (g1-q8), so the sink is there; recording the event name is section 8, not here.

-- 3.4 HOW A LEGITIMATE DEVICE-MOVE IS HANDLED (rotation, `SETUP-CHECKLIST.md`:101).
--     The device row, not the token, is the identity. `devices` is keyed by
--     `unique (family_id, installation_id)` (`devices_family_installation_key`, g1-q4/
--     g1-q5) and the token is a mutable attribute of it, so a reinstall that mints a new
--     FCM token is an **UPDATE of the existing row's `token_value`**, guarded by
--     `where owner_device_id = <caller's device> and provider = 'fcm'
--        and status = 'active'`, plus `rotated_at = now()` (2.13) and
--     `consecutive_failures = 0`.
--     Sequence, and note which parts are schema-guaranteed vs function-required:
--       1. UPDATE ... SET token_value = <new> where device matches and status='active'.
--          - if the NEW value is already active under a DIFFERENT row -> 23505 on 3.1 (a)
--            -> refused. A device cannot adopt another device's live token. Guaranteed by
--            the index alone.
--          - if the new value equals the current one -> no-op, `rotated_at` untouched.
--       2. The OLD value is now unreferenced. It is NOT kept as a history row: the owner
--          rule forbids duplicated application records, and `device_apps` establishes the
--          captured "overwrite per sync, do not accumulate history" posture
--          (`03-data-model.md`:93). Cleanup of the orphan is the provider's problem:
--          FCM stops delivering to a superseded token, and any later send attempt against
--          it - e.g. from a queue row enqueued before the rotation - returns an
--          unregister error and lands in 3.5.
--       3. Step 1's device-scoping predicate must be bound to the AUTHENTICATED device,
--          never to a device id in the request body. That binding is not available from
--          the schema: the caller tier is `service_role`, which bypasses RLS entirely, and
--          the capture's only device-authenticated precedent does it in application code
--          - `device-telemetry` takes `device_id`/`family_id` from the authenticated
--          device row and "never from the client" (`S2-EXEC-FINAL.md` §8.1, function
--          inventory row `device-telemetry`), with `x-device-id`/`x-device-secret` headers.
--          => BLOCKED - FUNCTION BODY NOT AVAILABLE (see 3.6 and section 8 O-1).
--     Device MOVE BETWEEN FAMILIES is a different event and is intentionally NOT the same
--     path: `devices.status` goes to 'revoked' with `credential_revoked_at` set
--     (`devices_revoked_credential_consistency` forces `secret_hash` to NULL in that
--     state, g1-q5), and the token row must go to 'revoked' with it. `on delete cascade`
--     from `devices` (2.5) means a device-row deletion also removes the token, so the
--     only gap is the *soft* revoke - which is exactly what 3.6 names as a function.

-- 3.5 HOW A PROVIDER INVALID-TOKEN RESPONSE MARKS A ROW STALE.
--     Declaratively, the destination state and its proof are locked: `status = 'stale'`
--     REQUIRES `stale_at is not null` (`push_tokens_stale_state_consistency`), so no
--     writer can enter the state without timestamping it, and `active` cannot carry
--     `stale_at`/`revoked_at` at all. The *transition* is the required UPDATE:
--       set status='stale', stale_at=now(), consecutive_failures = consecutive_failures + 1
--       where provider='fcm' and token_value = <the rejected token> and status='active';
--     The lookup is BY VALUE, deliberately: the send loop holds a token, not a row id.
--     On success, `consecutive_failures` resets to 0 and `last_seen_at = now()`.
--     The threshold at which 'stale' becomes 'revoked' is NOT derivable from repo
--     evidence => not invented; named in 3.6.

-- 3.6 TRANSITION RULES THAT MUST LIVE IN A SQL FUNCTION AND ARE NOT WRITTEN HERE.
--     Every object below is REFERENCED BY CONTRACT ONLY. No `create function` appears in
--     this file, for two evidenced reasons: (1) the capture holds **0 return types** for
--     any function - `S2-A3-database-audit.md`:189 records "0 return types in any
--     catalogue capture", and the programme explicitly refuses to write a guessed
--     `RETURNS boolean` into a security predicate; (2) the artefact emits **0 functions**
--     (`:475`) and `:200` states that 0 of 24 absent bodies are recoverable from
--     any authorised source. Inventing a body here would convert `INFERRED` into
--     `VERIFIED`-looking, which `04-risks-rollback-approvals.md` and the A3 audit both
--     forbid.
--       private.push_token_register(p_provider text, p_token text, p_platform text)
--         -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--            (must: authenticate the CALLER as that device, not trust a body-supplied
--             device id; perform 3.4 steps 1-2; use `do nothing` + post-check, never
--             `do update`; raise a caller-safe error on 23505 with no row disclosure;
--             write the audit event named in 3.3.)
--       private.push_token_mark_stale(p_provider text, p_token text, p_error_code text)
--         -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--            (must: perform 3.5, cap last_error_code to the CHECK bound, and never
--             store the provider's raw message, only its code.)
--       private.push_token_revoke(p_device_id uuid, p_reason text)
--         -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--            (must: set status/revoked_at, clear nothing else, and stay consistent with
--             devices_revoked_credential_consistency on the parent device row.)
--       private.push_token_retention_sweep()
--         -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--            (must: implement the delete windows in section 7; the `cron` Edge Function
--             is the only evidenced scheduler and it is `NOT STARTED` on staging,
--             `S2-EXEC-FINAL.md` §8.1/§8.3.)
--       private.is_family_parent(p_family_id uuid)
--         -> EXISTING, BODY CAPTURED (277 chars, `g1-b3b.bodies`,
--            `S2-A3-database-audit.md`:162-163), RETURN TYPE UNCATURED.
--            Referenced by section 5. Cannot be `create function`-ed by this file.


-- ===========================================================================
-- 4. PUBLIC.NOTIFICATION_QUEUE
-- ===========================================================================
-- The queue's column shapes are copied from `device_commands`, which is the programme's
-- ONLY captured queue-like table and already solves idempotency, attempts, expiry and a
-- status enum: `id`, `device_id`, `family_id`, `type`, `payload jsonb default '{}'`,
-- `status default 'pending'`, `idempotency_key text NOT NULL`, `created_by uuid NULL`,
-- `created_at`, `expires_at timestamptz NOT NULL`, `delivered_at`, `acked_at`,
-- `result jsonb`, `error_message text`, `attempts integer NOT NULL default 0` (g1-q8),
-- with `unique (device_id, idempotency_key)`, `attempts >= 0`, `char_length(key) between
-- 1 and 128`, `error_message is null or char_length <= 500`, `jsonb_typeof(payload) =
-- 'object'` and `device_commands_device_status_idx (device_id, status, created_at)`
-- (g1-q5, g1-q4). Reusing that shape is the "reuse rather than duplicate" instruction,
-- applied to the schema itself.
-- Why a NEW table instead of a `type` value on `device_commands`: `03-data-model.md`:65
-- states it directly - "Prefer a **new** table over altering `device_commands`" - and a
-- command is a *request to a device* while a notification is a *request to a push
-- provider*: different failure modes, different retry semantics, different retention.

create table public.notification_queue (
  id                   uuid        not null default gen_random_uuid(),  -- as 2.1
  -- 4.1 family_id: present so a family-scoped predicate can be written at all. Copied
  --     from every captured child table; `device_commands_family_id_fkey -> families
  --     CASCADE` (g1-q5) is the precedent, and `families` is soft-deleted by
  --     `deleted_at` (`families` g1-q8) so CASCADE on the hard delete is not the erasure
  --     path - see section 7.
  family_id            uuid        not null,
  -- 4.2 the device whose token is the send target. NOT NULL: an addressless notification
  --     cannot be delivered, retried or audited. `device_commands_device_id_fkey ->
  --     devices CASCADE` is the precedent.
  device_id            uuid        not null,
  -- 4.3 the human this notification is ABOUT/on behalf of. Distinct from device_id: the
  --     device is the transport, the person is the subject, and in a parental product
  --     they are different (a safety alert about child C is delivered to parent P's
  --     device). FK + CASCADE follows `remote_sessions_parent_user_id_fkey -> profiles
  --     CASCADE` (g1-q5): an owned reference, not an attribution.
  subject_user_id      uuid        not null,
  -- 4.4 provider discriminator, identical reasoning to 2.2, CHECK kept to the one
  --     evidenced value.
  provider             text        not null default 'fcm',
  -- 4.5 notification class. NO value enum, and that is deliberate: `device_commands`
  --     and `safety_alerts` each carry a captured CHECK = ANY (ARRAY[...]) listing their
  --     exact permitted values (g1-q5), and this programme has NO evidence for a
  --     notification type domain - no app source exists (`S2-EXEC-FINAL.md` §8.2,
  --     `repository.functions_directory: "absent"`). Writing one would be invented
  --     business logic. The candidate domain already in the schema is
  --     `safety_alerts_type_check` (low_battery, offline, geofence_enter, geofence_exit,
  --     app_blocked, permission_missing, other) - REUSE-BY-REFERENCE is the proposal,
  --     and the owner must confirm or replace it. Section 8, item O-4.
  type                 text        not null,
  -- 4.6 the send body. jsonb + object CHECK copied verbatim from
  --     `device_commands_payload_check` / `safety_alerts_payload_check`. Defaults to
  --     `'{}'::jsonb` exactly as captured. MUST NOT contain a token - enforced, see 4.7.
  payload              jsonb       not null default '{}'::jsonb,
  -- 4.7 THE NO-TOKEN-LEAK CHECK. This is not decoration: it is the only declarative way
  --     to stop a push token being copied into a queue row, which is how a token would
  --     reach an API response, a log line, a `result jsonb` column, a dashboard row view
  --     or a screenshot. The `?` operator is core jsonb, needs no extension, and rejects
  --     the four key names this design could plausibly receive. Deliberately NOT VALID on
  --     nesting: a deep or dynamic key name is not enumerable, and a false sense of
  --     coverage is worse than a stated limit - the remaining surface is the send
  --     function's contract (section 8, O-1).
  --     PORTABILITY NOTE for whoever executes this: `?` here is Postgres' jsonb
  --     key-existence OPERATOR, not a bind placeholder. A loader that binds `?` as a
  --     parameter (some driver layers do) will mis-parse it; the byte-equivalent form
  --     `not jsonb_exists(payload, 'token')` is the fallback and is functionally
  --     identical. Recorded rather than pre-empted, because the A3 execution channel is
  --     itself unresolved - `04-risks-rollback-approvals.md`:212 records A3 as UNSIGNED
  --     and "not executable", and `S2-EXEC-FINAL.md` §8.3 states the deployment channel
  --     is the browser dashboard only (no CLI), which collides with §8.2.
  constraint notification_queue_payload_no_token_key_check
    check (not (payload ? 'token')
           and not (payload ? 'push_token')
           and not (payload ? 'fcm_token')
           and not (payload ? 'registration_token')),
  -- 4.8 state machine, seven states. The mechanism (`text` + CHECK ANY ARRAY) is copied
  --     from `device_commands_status_check`; the VALUES are derived from what a queue
  --     must be able to distinguish (waiting / claimed / sent-and-accepted / retryable
  --     failure / permanent failure / abandoned-by-policy) and are labelled a PROPOSAL
  --     in section 8, item O-5, because no captured artefact names a notification state.
  status               text        not null default 'queued',
  -- 4.9 deduplication. `text NOT NULL`, same type and bounds as the captured
  --     `idempotency_key`. Bound copied verbatim from
  --     `device_commands_idempotency_key_check` (1..128).
  idempotency_key      text        not null,
  -- 4.10 attempt counter, verbatim from `attempts integer NOT NULL default 0` +
  --      `device_commands_attempts_check (attempts >= 0)`.
  attempts             integer     not null default 0,
  -- 4.11 ceiling on attempts before a row becomes 'dead'. A NUMBER IS NOT INVENTED here:
  --      0 is a sentinel meaning "no local cap - bounded only by expires_at", so the
  --      column exists to make a later decision expressible without another migration.
  max_attempts         integer     not null default 0,
  -- 4.12 earliest claim time. This is the backoff COLUMN: a worker selects
  --      `status='queued' and available_at <= now()`. The CURVE that writes it is a
  --      function (4.19) and is not available, so no formula is stated as fact.
  available_at         timestamptz not null default now(),
  -- 4.13 deliberate future delivery (a scheduled warning). NULL = not time-scheduled.
  --      Present because the owner ruling puts SCHEDULING in Supabase, and a scheduler
  --      needs a column to read; note the capture has no scheduler to read it - `pg_cron`
  --      is `NOT STARTED` and its `cron` function needs RPCs emitted 0 of
  --      (`S2-EXEC-FINAL.md` §8.3).
  scheduled_for        timestamptz null,
  -- 4.14 hard TTL. `timestamptz NOT NULL` matches `device_commands.expires_at` exactly
  --     and `device_commands_expires_idx` (g1-q4) is the captured index for the sweep.
  --     NOT NULL is the right shape here because push is best-effort by design and the
  --     programme's stated answer is client-side reconciliation on resume
  --     (`SETUP-CHECKLIST.md`:102) - so an unbounded pending row is a lie to the parent.
  expires_at           timestamptz not null,
  last_attempt_at      timestamptz null,   -- 4.15 for the retry window; NULL = never tried
  sent_at              timestamptz null,   -- 4.16 provider accepted the send
  terminal_at          timestamptz null,   -- 4.17 entered any terminal state
  -- 4.18 provider-side message id. Kept because it is the only join back to Firebase's
  --      own delivery logs during incident triage. It is NOT a secret and NOT a token.
  provider_message_id  text        null,
  -- 4.19 error CODE, never a message. Mirrors the captured `error_message` *mechanism*
  --      (`char_length <= 500`) but narrows it to a code, because a provider message body
  --      can quote the request, and the request contains a token (section 7).
  error_code           text        null,
  -- 4.20 lease holder. `text`, not a uuid: the holder is a worker identity (a function
  --      invocation), which is not a `profiles` row, so an FK would be a lie.
  locked_by            text        null,
  -- 4.21 lease expiry. Makes a crashed worker's row reclaimable without a manual UPDATE;
  --      without this pair, a queue needs a human to unstick every crash.
  locked_until         timestamptz null,
  -- 4.22 actor attribution, NULLable + SET NULL, verbatim from
  --      `device_commands_created_by_fkey -> profiles SET NULL` (g1-q5). This IS an
  --      attribution column, so unlike 4.3 it must survive the human leaving.
  created_by           uuid        null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  constraint notification_queue_pkey primary key (id),
  constraint notification_queue_family_id_fkey
    foreign key (family_id) references public.families (id) on delete cascade,
  constraint notification_queue_device_id_fkey
    foreign key (device_id) references public.devices (id) on delete cascade,
  constraint notification_queue_subject_user_id_fkey
    foreign key (subject_user_id) references public.profiles (id) on delete cascade,
  constraint notification_queue_created_by_fkey
    foreign key (created_by) references public.profiles (id) on delete set null,

  constraint notification_queue_provider_check
    check (provider = any (array['fcm'])),
  constraint notification_queue_status_check
    check (status = any (array['queued','running','delivered','failed','dead','cancelled'])),
  constraint notification_queue_type_check
    check (char_length(type) between 1 and 64),
  constraint notification_queue_idempotency_key_check
    check (char_length(idempotency_key) between 1 and 128),
  constraint notification_queue_attempts_check
    check (attempts >= 0),
  constraint notification_queue_max_attempts_check
    check (max_attempts >= 0),
  constraint notification_queue_error_code_check
    check (error_code is null or char_length(error_code) between 1 and 500),
  constraint notification_queue_provider_message_id_check
    check (provider_message_id is null or char_length(provider_message_id) between 1 and 256),
  constraint notification_queue_locked_by_check
    check (locked_by is null or char_length(locked_by) between 1 and 128),
  -- the pair-columns rule, in the capture's own `devices_revoked_credential_consistency`
  -- style (g1-q5): a lease is a state and a lease has an expiry, one without the other is
  -- a bug that silently wedges the queue.
  constraint notification_queue_lease_consistency
    check ((locked_by is null and locked_until is null)
           or (locked_by is not null and locked_until is not null)),
  -- terminal states are terminal: no lease, and proof-timestamped.
  constraint notification_queue_terminal_state_consistency
    check (status not in ('delivered','failed','dead','cancelled')
           or (terminal_at is not null and locked_by is null and locked_until is null)),
  -- a row cannot be claimed in the future, and cannot expire before it is claimable.
  constraint notification_queue_available_before_expiry_check
    check (available_at < expires_at),
  constraint notification_queue_scheduled_for_check
    check (scheduled_for is null or scheduled_for > created_at)
);

-- 4.23 DEDUPLICATION. Scoped by (device, key) exactly like
--      `device_commands_device_idempotency_key = unique (device_id, idempotency_key)`
--      (g1-q4/g1-q5), NOT global: two families can legitimately produce the same
--      client-generated key, and a global key would then silently DROP a second family's
--      safety alert - a data-loss bug dressed as a dedupe.
create unique index notification_queue_device_idempotency_key
  on public.notification_queue (device_id, idempotency_key);

-- 4.24 THE WORKER'S ACCESS PATH, copied from the captured
--      `device_commands_device_status_idx (device_id, status, created_at)` shape and
--      `device_commands_expires_idx (expires_at)`. `available_at` leads because the claim
--      query filters on it first; `status` is included so a partial index was considered
--      and rejected - the sweep must also read terminal rows for retention, so a
--      `where status='queued'` partial index would not serve section 7's purge.
create index notification_queue_claim_idx
  on public.notification_queue (available_at, status, created_at);
create index notification_queue_expires_idx
  on public.notification_queue (expires_at);
create index notification_queue_family_status_idx
  on public.notification_queue (family_id, status, created_at);

comment on table public.notification_queue is
  'Server-side push send queue: dedupe, attempts, backoff window, expiry. Internal; no client reads. PREPARED - NOT EXECUTED.';

-- 4.25 STATE MACHINE. The transitions below are the CONTRACT each writer must honour.
--      They are stated as a table, not as SQL, because the enforcing object is a function
--      and its body is not available (3.6). They are also only *partly* enforced by
--      CHECKs today: `notification_queue_terminal_state_consistency` forbids a terminal
--      state without `terminal_at`, and `notification_queue_lease_consistency` forbids a
--      half-taken lease; nothing declarative can stop a `failed -> delivered` rewrite,
--      because a CHECK cannot read the previous row value. That gap is named rather than
--      papered over.
--        queued    -> running     claim: locked_by/locked_until set, attempts+1,
--                                  last_attempt_at=now(). REQUIRES an atomic
--                                  `for update skip locked` claim.
--                                  -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--                                     (private.notification_claim(...))
--        running   -> delivered   provider 2xx: sent_at, terminal_at, lease cleared.
--        running   -> failed      retryable provider error: error_code, attempts,
--                                  available_at = now() + backoff, lease cleared,
--                                  terminal_at set ONLY if attempts hits max_attempts
--                                  (max_attempts = 0 => bounded by expires_at only).
--                                  -> BLOCKED - FUNCTION BODY NOT AVAILABLE
--                                     (private.notification_mark_failed(...); the backoff
--                                     curve, its base and its ceiling are NOT EVIDENCED
--                                     anywhere in this repo and are not invented here.)
--        running   -> dead         permanent provider refusal, incl. UNREGISTERED on the
--                                  token -> must also drive 3.5 on the paired push_tokens
--                                  row in the SAME transaction, or the queue and the
--                                  token store disagree. Which provider error names map
--                                  to which transition = Firebase-side contract,
--                                  BLOCKED on A12: no app, no sender, therefore no error
--                                  sample has ever been observed (S2-INSP-03:119).
--        *         -> cancelled    superseded / expired / family torn down; terminal_at.
--        failed    -> queued       re-arm, allowed ONLY while expires_at not passed;
--                                  NOT allowed from dead or cancelled. This arrow is the
--                                  one an UPDATE-policy would need and none exists
--                                  (section 5).
--      Illegal by the table itself: any move INTO 'queued' from a terminal state; any
--      claim of a row whose expires_at has passed (the sweep cancels it).

-- 4.26 WHAT THIS TABLE DOES NOT DUPLICATE, on purpose.
--      It has no `acked_at` and no `result jsonb`, which `device_commands` does have
--      (g1-q8). A push notification is not acknowledged by a device - the *device*
--      receives it, and the only acknowledgement path the capture actually shows is
--      `device_commands.acked_at` for a command. Adding a second ack column would create
--      two sources of truth for one fact, which the owner rule forbids. Likewise there is
--      no `notification_type_catalog` table: an enumeration the app already owns would be
--      duplicated application state.


-- ===========================================================================
-- 5. GRANTS, RLS, POLICIES - AND WHY THEY ARE NOT THE LIVE-PATH CONTROL
-- ===========================================================================
-- THE FACT THAT GOVERNS THIS WHOLE SECTION, cited as instructed:
--   docs/stage1/14-edge-function-security-audit.md:243-245 -
--     "VERIFIED - every function uses the service-role key, therefore RLS never applies."
--     "Because the key bypasses RLS, every handler is a trust boundary."
--   S2-EXEC-FINAL.md §8.1, same fact restated: "RLS is not the enforcement layer for any
--     live caller; the Edge Function is", and all 9 deployed Edge Functions are in that
--     inventory (`pairing`, `auth-bootstrap`, `device-command`, `device-register`,
--     `device-policy`, `device-telemetry`, `family-admin`, `remote-session`, `cron`).
-- So: there are ZERO deployed Edge Functions on staging (`01-staging-project-proposal.md`
-- :198 topology row 3, "0 deployed / NOT CREATED"), and when they exist they will not be
-- bound by anything below. Every authorisation decision that must actually hold is
-- implemented (a) in the function body, and (b) in the schema as CHECK/UNIQUE/FK
-- constraints, which DO bind service_role - which is precisely why section 2.4 and 3.1
-- are constraints and not policies.

-- 5.1 GRANTS: deny-all to client roles. Chosen from the capture's own two postures
--     (`g1-q1.table_acl`):
--       (i) `postgres=arwdDxtm/postgres, service_role=arwdDxtm/postgres`            ->
--           devices, child_contact_ids, device_pairing_tokens, pairing_attempts
--       (ii) the same + `authenticated=r/postgres` -> audit_logs, device_apps,
--           device_commands, device_policies, families, family_members, location_events,
--           pairing_requests, ...
--     `push_tokens` takes (i). A client already HOLDS its own token - it minted it - so a
--     read-back grants no capability and only adds a leak path; and (i) is the captured
--     posture for exactly the object type "device credential material", cf.
--     `device_pairing_tokens` and `devices` itself.
--     `notification_queue` takes (i). It is a server work ledger; the parent-facing read
--     path is `safety_alerts` / `device_commands`, both already granted (ii) and already
--     Realtime-published (§6). Giving the queue its own client read would create a second
--     view of one fact.
grant all on table public.push_tokens        to postgres, service_role;
grant all on table public.notification_queue to postgres, service_role;
revoke all on table public.push_tokens        from public, anon, authenticated;
revoke all on table public.notification_queue from public, anon, authenticated;
-- No sequence grant: neither table uses one (2.1, 4.1); uuid PKs throughout the capture.
-- No function grant: this file creates no function.

-- 5.2 RLS ENABLED, NOT FORCED. `g1-q1` records `rls_enabled: true, rls_forced: false` for
--     every one of the 19 captured tables; enabling without forcing is the convention,
--     and forcing would change owner-role semantics with no evidence that it is wanted.
--     `owner = postgres` in the same capture, so `postgres` retains bypass.
alter table public.push_tokens        enable row level security;
alter table public.notification_queue enable row level security;

-- 5.3 POLICIES: only the two this file can justify without a missing object.
--     The predicate shape below is copied verbatim from the captured
--     `device_apps_select_parent_or_child` / `device_commands_select_parent_or_child`
--     (g1-q2), which is the programme's device-ownership idiom:
--       private.is_family_parent(family_id)
--       OR exists (select 1 from devices d
--                  where d.id = <t>.device_id and d.child_user_id = auth.uid())
--     Both are `PERMISSIVE`, both `TO authenticated` - the capture's 21 policies are
--     "all PERMISSIVE, all TO authenticated" (`S2-A3-database-audit.md`:155).
--
--     (a) SELF-ONLY, needs no helper, so it is emitted.
create policy push_tokens_select_own_device
  on public.push_tokens as permissive for select to authenticated
  using (owner_user_id = auth.uid());

--     (b) FAMILY-PARENT, DEFENSIVE ONLY, and it is EMITTED WITH ITS DEPENDENCY NAMED
--     rather than silently relying on an object this file cannot create.
--     DEPENDS ON: private.is_family_parent(p_family_id uuid) - BODY CAPTURED
--     (g1-b3b.bodies, 277 chars, `S2-A3-database-audit.md`:162-163), **RETURN TYPE
--     UNCATURED** (`:189` "0 return types in any catalogue capture"), therefore not
--     creatable by this file and therefore not present on any database this file has
--     touched. `S2-A3-database-audit.md`:175 records that 17 of 21 policies are
--     "one return-type decision away" and that guessing `RETURNS boolean` is forbidden
--     (`:177`: "A `RETURNS boolean` guess written into `40-functions.sql` would convert an
--     `INFERRED` object into a `VERIFIED`-looking one"). A SECOND blocker sits underneath
--     and is new evidence for this file: `S2-A3-database-audit.md`:93 (finding **X-7**)
--     records that **0 statements grant `USAGE` on schema `private`** - "The artefact
--     creates `private`, grants nothing on it, and every helper function lives in it",
--     even though `g1-b3b.schema_usage` evidences `authenticated=true`. So even a
--     correctly-typed `private.is_family_parent` would not be callable from a policy
--     rendered against the artefact as-is. Both blockers must clear before policy (b) can
--     be emitted; either one alone makes `create policy ... private.is_family_parent(...)`
--     abort the transaction.
--     Consequence: policy (b) is left COMMENTED OUT, because a `create policy` that
--     references a missing function aborts the whole transaction - and a policy naming a
--     nonexistent function is a load failure, not a design.
-- create policy push_tokens_select_parent_or_child
--   on public.push_tokens as permissive for select to authenticated
--   using (private.is_family_parent(family_id)
--          or owner_user_id = auth.uid());
--   -- BLOCKED: (i) private.is_family_parent return type uncaptured (section 5.3 above);
--   --           (ii) `push_tokens` has no family_id column in this design - ownership is
--   --                reached via devices.child_user_id - so emitting this predicate would
--   --                ALSO need a family_id copy. That is an owner decision, not a guess:
--   --                either add `family_id uuid NOT NULL` + CASCADE (matching the five
--   --                captured child tables) to enable the helper, or keep the narrower
--   --                self-only policy and let the parent read path be `audit_logs` /
--   --                `safety_alerts`. NOT resolved here.

--     (c) NO INSERT/UPDATE/DELETE POLICY EXISTS, and one must not be manufactured. The
--     capture shows the write posture already: "16 without WITH CHECK", and
--     `04-rls-matrix.md`:64-65 - "`families.owner_id`, `family_members.*`, `devices.*`...
--     are not writable by `authenticated` at all: no UPDATE grant exists, so the absence
--     of an UPDATE policy is not the only control." All writes here go through the
--     section 3.6 functions as `service_role`, which RLS does not bind.

-- 5.4 THE UNCOMFORTABLE CONSEQUENCE, stated so no reader mistakes defence for control:
--     policy (a) is currently DEAD, in the capture's own word. `g1-q1` shows `devices`
--     carries no `authenticated` grant at all, and `04-rls-matrix.md`:67 and :110 record
--     `devices_select_parent_or_child` as "no privilege of any kind on `devices`",
--     "None - no API path, and no grant", verdict **UNREACHABLE (F6)**. Section 5.1 gives
--     `push_tokens` the same posture, so `push_tokens_select_own_device` is unreachable
--     by construction and is kept as defence-in-depth for the day someone grants `r`.
--     Two drift warnings follow from the capture and are recorded here rather than being
--     discovered later: (1) `04-rls-matrix.md`:69-71 - "a policy with no grant is dead,
--     not open", but re-enabling a table for the Data API without reading the grants
--     "would switch these predicated reads on by accident rather than by design (F6)";
--     (2) the count discipline - there are "15 SELECT policies and 14 tables that carry a
--     SELECT grant", so adding an 16th policy without a grant is normal here, and adding a
--     GRANT without a policy is the dangerous direction.
--     NET: for a live caller, the controls that bind are section 2.4 (composite FK),
--     section 3.1 (two partial unique indexes), the CHECK set, and the Edge Function body
--     - in that order. RLS is none of them.


-- ===========================================================================
-- 6. REALTIME - THE DECISION, AND THE EXACT STATEMENT IF THE OWNER OVERRIDES IT
-- ===========================================================================
-- DECISION: **no publication for either new table.** `public.notification_queue` and
-- `public.push_tokens` are NOT added to `supabase_realtime`.
-- Evidence for the decision, all reuse-based as instructed:
--   * The Realtime surface already exists and is exactly four tables:
--     `04-rls-matrix.md`:78 - "`postgres_changes` is enabled on `device_commands`,
--     `remote_sessions`, `safety_alerts` and `webrtc_signals`" - and `:60`, "Notes on the
--     four Realtime tables: ... each carry a SELECT policy that scopes by family or
--     session participant, so `postgres_changes` subscribers are filtered by a real
--     predicate", with the per-table rows at `:98`, `:138`, `:150`, `:158` all marked
--     "**Realtime live** - `postgres_changes` authorises via this policy".
--   * Adding a fifth table does not add a feature, it adds an AUTHORISATION SURFACE:
--     `04-rls-matrix.md`:188 - "Because each table is API-disabled, PostgREST exposes no
--     HTTP route. But Realtime is on for four tables and authorises subscribers through
--     these same SELECT policies, so a defective `USING` clause ... is exploitable today
--     by any authenticated user who subscribes." A queue with NO usable SELECT policy
--     (section 5.4) published into Realtime would be published into a deny-all that looks
--     like a feature, and if a policy were later added to make it readable, the queue's
--     `payload jsonb` becomes subscribable content by accident.
--   * Nothing user-visible would be gained: the parent already learns about a pending
--     action from `safety_alerts` and `device_commands`, both already published. The queue
--     is the transport's to-do list. Publishing it would duplicate the notification record
--     into a client-visible stream - forbidden by the "no duplicated application records"
--     rule.
--   * `push_tokens` is worse still: its row IS a child-device credential (section 7).
--     A Realtime `DELETE` event carries the old row values to every authorised
--     subscriber, so publishing it would broadcast token values.
--
-- IF THE OWNER OVERRIDES: the exact statement, withheld from the active path. It is NOT
-- executed here and requires **A2'(b) as AMENDED**, because the signed A2'(b) text
-- (`S2-A3-database-audit.md`:536-541) authorises Realtime membership for "device_commands,
-- remote_sessions, safety_alerts and webrtc_signals" - a named list of four, with no
-- general grant for future tables (`00-stage2-execution-plan.md`:136 states the same
-- scope). A fifth table is outside that clause.
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_queue;
-- Recorded blockers on that single line, none of them resolvable from repo evidence:
--   * `pg_publication` / `pg_publication_tables` were **never queried**; the artefact
--     contains **0 publication statements** and publication membership is
--     `UNKNOWN - SOURCE EVIDENCE ABSENT` (`S2-A3-database-audit.md`:122 row 19,
--     `:134`-`:136`, `:636`). Even the publication's NAME, let alone its ownership, is
--     documentary, not catalogued: `:549`-`:551` - "A2'(b) signed today would set a
--     publication from a guess."
--   * A publication cannot reference tables that do not exist, so it is structurally
--     after the A3 load (`:540`-`:541`, `approval-package-v2...:251`), and this file is
--     itself post-A3.
--   * The reconstruction's `80-realtime-publication.sql` records the four
--     `ALTER PUBLICATION supabase_realtime ADD TABLE ...` as **comments** tagged
--     `(AFTER A3 ... NOT EMITTED)` (`S2-EXEC-04-object-coverage-matrix.md`:332-333),
--     which is the house precedent this file follows by commenting rather than emitting.
--   * WAL / logical decoding / replica identity state is unqueried
--     (`S2-A3-database-audit.md`:136), so even a correctly-authored `ADD TABLE` has no
--     evidence that delivery would work.


-- ===========================================================================
-- 7. SECURITY - A PUSH TOKEN IN THIS PRODUCT IS A CHILD'S DEVICE IDENTIFIER
-- ===========================================================================
-- CLASSIFICATION. `devices.child_user_id` is `uuid NOT NULL` with an FK to `profiles`
-- (g1-q8 ordinal 3, g1-q5 `devices_child_user_id_fkey`), so in the captured model **every
-- device is a child's device**. There is consequently no configuration in which a
-- `push_tokens` row is anything other than a persistent identifier bound to one named
-- child and one physical handset. In a parental-control product that carries the
-- guardian/ward relationship on the row. Treat it as the capture already treats the
-- nearest analogue: `03-data-model.md`:90 grades pairing tokens at sensitivity
-- **Critical**, disposition "Expire and delete used/failed codes and tokens promptly;
-- retain attempt counts, not payloads."
-- THE THREAT IS NOT DATA THEFT, IT IS SILENCING AND TRACKING. A token lets its holder
-- (a) deliver arbitrary content to that child's lock screen, impersonating the app, and
-- (b) probe possession/liveness of the device. For a safety product the inverse also
-- matters: an attacker who can move or revoke a token suppresses a guardian's alert, which
-- is why section 3's control is an index and not a code review item.
-- ASSUMPTION ABOUT REST, STATED AS AN ASSUMPTION. This design does not encrypt the column,
-- so it relies on platform encryption at rest plus `pg_hba`/network controls. The repo
-- does not verify that: SSL enforcement is an **unsigned A2'(b) checklist item**
-- (`S2-A3-database-audit.md`:538-539, "the settings checklist items SSL enforcement,
-- connection logging" - `NOT DONE`), and `04-risks-rollback-approvals.md`:212 leaves A3's
-- settings half unexecuted. A hashed-lookup-key + ciphertext alternative was considered
-- and REJECTED for this pass on evidence, not preference: it needs pgcrypto or a verified
-- PG15 `sha256()`, and extensions were **never queried** - `pg_extension` sits on the
-- missing-evidence list (`S2-A3-database-audit.md`:636-638, `:684`). The alternative, with
-- its exact blocker, is item O-6 in section 8.
-- MINIMISATION. No new PII: no email, no push-activity history table, no per-send log row.
-- 03-data-model.md`:80 - "Minimise at write time. Do not store the same fact in two
-- tables", and `:93` establishes "overwrite per sync; do not accumulate history" for
-- device-attached rows. Enforced here by: the payload CHECK at 4.7 (a token cannot be
-- copied into the queue); `error_code` at 4.19/4.6 (code, not provider message body);
-- no token-history rows at all (3.4 step 2).
-- RETENTION. Proposed windows, in the capture's own style (`03-data-model.md`:82-95), and
-- marked PROPOSED because the capture records the same open question for the missing
-- table - `03-data-model.md`:43 flags `push_tokens` as MISSING with "no device-token
-- table" and `:78` states "Retention is a schema decision, not a cron setting. Every
-- class needs an owning table, a stated window and a purge path BEFORE any client writes
-- to it":
--    status='active'  -> life of the device pairing; deleted by CASCADE with the device.
--    status='stale'   -> 30 days, then hard delete. (30 days matches the capture's
--                        `location_events` raw window and `pairing_attempts` 30-90 day
--                        attempt band; it is a proposal, not an evidenced fact.)
--    status='revoked' -> 30 days for audit continuity, then hard delete; the durable
--                        record belongs in `audit_logs` (12/24-month band,
--                        `03-data-model.md`:89), not on a row holding a live token.
--    queue, terminal  -> 30 days after terminal_at, mirroring
--                        `03-data-model.md`:91 "Command history | 30 days after terminal
--                        state | purge resolved rows".
--    no purge exists yet: `private.push_token_retention_sweep()` is BLOCKED (3.6) and the
--    only scheduler, `cron`, is `NOT STARTED` with the RPCs it calls emitted 0 of
--    (`S2-EXEC-FINAL.md` §8.1/§8.3).
-- THE ABSOLUTE RULES. A token value must NEVER be:
--   * written to a log line, stdout/stderr, a Deno `console.log`, or an error message;
--   * echoed in an API response body, an error envelope, or a validation "got" message;
--   * placed in `audit_logs.metadata jsonb`, in a queue `payload`, or in `result`;
--   * written into an evidence file, a findings document, this migration, or any
--     screenshot - including a Supabase Table Editor cell and a Firebase console view.
--   `audit_logs` is the concrete risk because it stores `metadata jsonb NOT NULL`
--   (g1-q8) with `target_id text` - a natural place to paste "the thing that just
--   failed". `SETUP-CHECKLIST.md`:110 already sets the right habit for the adjacent
--   secret ("file diff, no key contents pasted"), and 14-edge-function-security-audit.md
--   :246-249 records the working precedent to follow: `device-register` **deletes
--   `secret_hash` and `installation_id` from the returned row before responding** - so the
--   house rule for a device-identifying column is "strip before the wire", and
--   `push_tokens.token_value` must be added to that strip list, never to a response.
-- BACKUP / COPY IMPLICATION. Because the column is in `public`, it rides every
--   `pg_dump`, every PITR restore and every dashboard "Table editor" view by default. No
--   column-level privilege exists in the capture's `table_acl` idiom (g1-q1 shows
--   table-level grants only), so column-level restriction is not available as a control
--   here; the mitigations actually available are the section 5.1 deny-all, the section 6
--   no-publication decision, and the retention windows above. State that plainly to
--   whoever signs A3: **this table silently widens the blast radius of any backup copy of
--   staging.**
-- PRODUCTION SYMMETRY. If this ever reaches production, it moves child-device
--   identifiers into a populated, live database. Production (`hhqgreaoqulmfwfwarhc`) is
--   out of scope for this file and must not be opened to check anything.


-- ===========================================================================
-- 8. OPEN DEPENDENCIES - WHAT CANNOT BE BUILT FROM REPO EVIDENCE
-- ===========================================================================
-- O-1  THE register-token-EQUIVALENT CONTRACT (write path). NOT STARTED.
--      There is no `register-token` Edge Function to extend: it does not appear in the
--      evidenced inventory of 9 - `S2-EXEC-FINAL.md` §8.1 lists `pairing`,
--      `auth-bootstrap`, `device-command`, `device-register`, `device-policy`,
--      `device-telemetry`, `family-admin`, `remote-session`, `cron`, and §8.1 closes with
--      "There is no push send path. No evidenced function delivers FCM, and `register-
--      token` from the brief does not exist." `SETUP-CHECKLIST.md`:100 gives the same list
--      independently. Per the owner's instruction this file does **not** create such a
--      function and does **not** name one. What the schema needs from it, and which of
--      3.4/3.5/3.6 it must own, is recorded above as BLOCKED - FUNCTION BODY NOT
--      AVAILABLE. Additional evidenced blocker: 7 of 9 functions exist only as minified
--      bundles and the repo holds no Edge source at all, so "no gate-compliant browser
--      path exists to redeploy 7 of 9" (`S2-EXEC-FINAL.md` §8.2); A7/A8 are separate
--      unsigned gates and authorising nothing here.
-- O-2  A REAL TOKEN SAMPLE. Impossible today: `char_length(token_value) between 8 and 512`
--      (2.3) is the only un-evidenced bound in this file. Zero apps exist
--      (`S2-INSP-03`:119), so no FCM registration token has ever been minted by this
--      programme and no length or character domain can be confirmed. Resolve after A12
--      grants an app registration; confirm by observation, not by web research.
-- O-3  `updated_at` MAINTENANCE. Whether the captured tables use a trigger to keep
--      `updated_at` is unverified and the emitted artefact contains **0 triggers**
--      (`S2-A3-database-audit.md`:475, `:644`). This file copies the column shape but not
--      an invented trigger. Decide with the A3 authoring pass, uniformly for all 21 tables.
-- O-4  NOTIFICATION TYPE DOMAIN. `notification_queue.type` has no CHECK value list (4.5).
--      The candidate is `safety_alerts_type_check`'s seven values (g1-q5) - reuse versus a
--      new domain is a product decision, and the app source that would answer it is
--      `absent` (O-1 evidence).
-- O-5  QUEUE STATE + BACKOFF CURVE. The seven status values (4.8), the transition table
--      (4.25), the retry base, the ceiling and `max_attempts` default are PROPOSALS. No
--      function body is emitted (3.6), so nothing here computes a backoff interval; the
--      columns exist so that whatever curve the owner chooses needs no further migration.
-- O-6  TOKEN ENCRYPTION / HASHING AT COLUMN LEVEL. Blocked exactly as in section 7:
--      `pg_extension` was never queried (`S2-A3-database-audit.md`:636-638, `:684`), so
--      pgcrypto availability is `NOT VERIFIED`, and PG major version is likewise
--      uncaptured, so core `sha256()` availability is `NOT VERIFIED`. One approved read
--      of `pg_extension` and `select version()` on **staging** closes this; it is
--      `A3`-window work, not this file's to assume. Note the design consequence either
--      way: a deterministic hash would keep section 3.1 (a) working, a randomised/RSA
--      envelope would not, because an index cannot match on ciphertext that differs per
--      write - so choosing column encryption silently deletes the anti-theft control.
-- O-7  THE FCM SEND PATH. `BLOCKED - APPROVAL REQUIRED`, three independent parts, all
--      unevidenced today:
--      (i)   a registered Android app. `haven-staging-46822` has **zero apps**
--            (`S2-INSP-03`:119) and **no Firebase product enabled** - the navigation
--            offers only Project Overview and Settings (`:107`-`:108`, `:132`-`:134`).
--            Package id is already verified for later use: `com.haven.familysafety`
--            (`SETUP-CHECKLIST.md`:15, §0a). A12's amended clause expressly keeps
--            "app registration ... prohibited" (04-risks-rollback-approvals.md:220).
--      (ii)  a credential. Service-account JSON / server key: NAMES ONLY anywhere in this
--            programme; never a value; never in a Flutter or Kotlin client (section 0
--            header, `SETUP-CHECKLIST.md`:92-94). A9 (secret names) is unsigned.
--      (iii) a sender. No function, no RPC, no CLI, nothing in the repo issues an FCM
--            request (`SETUP-CHECKLIST.md`:100, `S2-EXEC-FINAL.md` §8.1). `Cloud Messaging`
--            and `Service accounts` console surfaces were **deliberately not opened**
--            (`S2-INSP-03`:124-127) because they are A12 territory.
--      => A token store with no sender is still the correct first artefact: it is what
--      `02-architecture.md`:104 row 5 names as the missing piece ("the current 25 columns
--      are VERIFIED to contain no push-token column, so adding one is a G3-style
--      migration"). It is not delivery, and it must not be reported as delivery.
-- O-8  THE IDENTITY MAPPING - ruled while this addendum was authored; the schema stays
--      neutral anyway, and the neutrality is now verifiable rather than speculative.
--      THE RULING: the owner selected the **Third-Party Auth bridge**
--      (`S2-EXEC-08-identity-decision-A13-final.md`:18-22) - Firebase registered as an
--      external JWT issuer, "**Supabase stays the single session authority and verifies
--      Firebase-issued tokens**". Status `DECIDED - INSTRUMENT PREPARED, FENCE UNSIGNED`;
--      explicitly **not** `APPROVED`, and "nothing in §5 may run until it is" (`:28`).
--      `:60` records that A13 "replaces **only that row**" (the Client-release row,
--      `04-risks-rollback-approvals.md`:221) and amends topology row 1 by a pointer only
--      (`:72`) - so **Supabase Auth remains the session/authorization authority of
--      record**. This file's ownership key is therefore correct as written, not merely a
--      safe guess.
--      THE CONTEST IT WAS CONTESTED IN, kept on record because the documents still read
--      both ways until the A13 pointer is applied:
--        * Supabase Auth as the single authority: `01-staging-project-proposal.md`:196
--          (topology row 1, "**Supabase Auth** ... Single identity authority") and `:201`
--          (row 6, "Firebase Auth / Firestore / Cloud Functions | **OUT OF SCOPE** - must
--          not be enabled"), `S2-A1-auth-architecture.md`:94 (A-01, `VERIFIED`),
--          `firebase/SETUP-CHECKLIST.md`:16 (D4, "Firebase Auth | **Leave disabled** |
--          Supabase Auth is the single identity authority (architecture rule)"), and the
--          four in-repo prohibitions collected at `S2-A1-auth-architecture.md`:423.
--        * against the brief's Firebase Auth direction, which `S2-A1-auth-architecture.md`:3
--          titles as an audit of a *proposed* migration and whose provisioning chain steps
--          1-5 are `NOT STARTED`/`PLANNED`/`BLOCKED - APPROVAL REQUIRED` (`:208`-`:210`),
--          with `E-18` recording that Firebase Auth is not enabled and no app is
--          registered (`:547`) and O-2/O-4 (`:558`) left open for the owner.
--      DESIGN CONSEQUENCE, now under the ruling:
--        * The ONLY ownership key in these tables is `owner_user_id uuid` -> `profiles.id`
--          -> `auth.uid()`, i.e. the Supabase side, which is what all 21 captured policies
--          already compare against (g1-q2). Both the self-only policy (5.3a) and the
--          composite FK (2.4) resolve through it.
--        * **No `firebase_uid` column exists in either new table, by decision.** Under the
--          bridge a Firebase UID never reaches row data at all - it is verified at the
--          token layer and `auth.uid()` is minted from the Supabase identity - so a column
--          for it would be dead storage and a leak surface.
--        * The marked EXTENSION POINT remains a separate mapping table, not a column here:
--          `S2-A1-auth-architecture.md`:155 option **M-B (recommended shape)** -
--          "(external provider, external uid, supabase user id, created/confirmed
--          timestamps) with a unique constraint on `(provider, external uid)` and ON DELETE
--          CASCADE on the auth.users FK", RLS-on/zero-policies, purely additive. Under the
--          chosen bridge M-B may not even be needed for the token path, since
--          `auth.uid()` is unchanged; it stays the marked extension point if the programme
--          later needs to record which external issuer produced which session. Uniqueness
--          on `(provider, external_uid)` would inherit the same partial-index device used
--          in 3.1 (`S2-A1-auth-architecture.md`:165-167).
--        * THE OPTION ACTUALLY CHOSEN is that third possibility, and this file was built
--          to pass its test: `S2-A1-auth-architecture.md`:307 V-3, Supabase's native
--          `[auth.third_party.firebase]` bridge - "the only option that keeps invariants
--          I-1/I-2 intact with the least new code", with `auth.uid()` **unchanged**. Its
--          availability was and remains `NOT VERIFIED`: the only repo record is a
--          **local** `supabase/config.toml:180` with `enabled = false` (A-23), and
--          enabling a provider is a dashboard settings change gated A2'(b)-class plus A12
--          for the Firebase side (`:307`). Under V-3 **nothing in this file changes** -
--          no column, no key, no FK, no policy, no grant - which is the point of having
--          modelled ownership on `profiles.id` from the start. What DOES change is
--          upstream and is not this schema's to build: the external JWT issuer
--          registration itself, and the cutover duties the ruling attaches
--          (`S2-EXEC-08`:72 - "the Email provider and open sign-ups must be disabled at
--          cutover"), none of which may run while the A13 fence is unsigned (`:28`).
--      BLOCKERS on the mapping itself, none closable here: `profiles.id` cannot hold a
--      Firebase UID (uuid NOT NULL, no default, FK to auth.users - `:183` F-1); minting an
--      `auth.users` row needs a service-role/admin write to the `auth` schema with no
--      in-repo precedent (`:185`-`:188` F-2); FX-18 leaves even the staging `auth.users`
--      count `NOT VERIFIED` (`S2-INSP-03` §3, `01-staging-project-proposal.md`:196), and
--      the count is deferred INTO the A3 window (decision B-3,
--      `04-risks-rollback-approvals.md`:212); email is unusable as a merge key -
--      `03-data-model`/`S2-A3-database-audit.md`:293 record **no email column exists
--      in any of the 183**, email lives only in `auth.users`.
--      LABEL HAZARD RESTATED: the repository's pre-existing "A13" row is **Client
--      release** (`04-risks-rollback-approvals.md`:221), not identity, and
--      `S2-EXEC-08`:60 says the new A13 "replaces **only that row**". Two different
--      things are therefore numbered A13 in this plan of record. Whoever executes this
--      file must confirm which instrument the signature fence belongs to before treating
--      the identity ruling as unblocked: as written it is `DECIDED`, **not** `APPROVED`
--      (`S2-EXEC-08`:28), and nothing above its fence may run.
-- O-9  REUSE CHECK, PERFORMED, RESULT: no duplication introduced. Verified against the
--      183-column capture (g1-q8) before authoring:
--      * `devices.notifications_granted` **already exists** - `boolean NULLABLE`,
--        ordinal 23 of 25 (`g1-q8`; `schema-columns.md`:125;
--        `S2-A3-database-audit.md`:410-411, which grades it "a permission flag, not a
--        token"). It is the OS notification-permission bit and is **read, never
--        re-modelled**: neither new table carries a permission column, no
--        `notifications_granted` twin was created, and the send decision should join to
--        it. `04-rls-matrix.md` covers `devices.*` under the captured grants
--        (`:64`-`:65`), so the read path exists.
--      * `devices.platform` **already exists** (`text NOT NULL default 'android'`) and is
--        the source of 2.6's bound. 2.6 keeps a copy for the same reason the capture's
--        child tables copy `family_id` (g1-q5) - to avoid a join in the send loop - and
--        the copy is labelled as a copy, not as new information.
--      * the **four Realtime tables already exist and are published**
--        (`04-rls-matrix.md`:60, `:78`, `:98`, `:138`, `:150`, `:158`) - so
--        `notification_queue` is neither a 5th publication (section 6) nor a replacement
--        for `device_commands`, whose `status`/`attempts`/`idempotency_key`/`expires_at`
--        machinery is the template this file copied (section 4).
--      * `pairing_requests.token_id (uuid)` and `device_pairing_tokens.code_hash` are
--        **pairing artefacts and are NOT reused** for push: a 6-digit-ish single-use
--        pairing code with `char_length` bounds and a "delete used codes promptly"
--        retention band (`03-data-model.md`:90) is a different object from a long-lived
--        device registration token. Reusing them would have mixed a rotatable secret with
--        a persistent identifier in one table.
--      * `audit_logs`, `safety_alerts`, `families.deleted_at` all exist and are the
--        intended sinks; nothing here duplicates them.


-- ===========================================================================
-- 9. VALIDATION AFTER EXECUTION - READ-ONLY, RUN INSIDE THE A3 WINDOW
-- ===========================================================================
-- These are the assertions this file claims. They are LEFT AS COMMENTS because
-- executing anything is A3 work and no SQL was run to author this file.
--   (1) select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
--       where n.nspname='public' and c.relname in ('push_tokens','notification_queue');
--       -> 2.
--   (2) rls posture matches the capture (g1-q1: enabled true / forced false):
--       select relname, relrowsecurity, relforcerowsecurity from pg_class
--        where relname in ('push_tokens','notification_queue');
--       -> t / f for both.
--   (3) no client-role access, matching the `devices` row of g1-q1
--       ("None - no API path, and no grant", 04-rls-matrix.md:110):
--       select grantee, privilege_type from information_schema.role_table_grants
--        where table_name in ('push_tokens','notification_queue');
--       -> only postgres and service_role; zero rows for anon/authenticated.
--   (4) the anti-theft indexes are partial uniques, i.e. section 3.1 really applied:
--       select indexname, indexdef from pg_indexes
--        where tablename in ('push_tokens','notification_queue');
--       -> push_tokens_one_active_value_per_provider and push_tokens_one_active_per_device
--          both carry "WHERE (status = 'active'::text)", the same rendering as
--          devices_one_active_per_child in g1-q4.
--   (5) the composite FK binds: insert a push_tokens row with an owner_user_id that is
--       NOT devices.child_user_id for owner_device_id -> must fail with 23505/foreign_key
--       violation **as service_role**. This is the one test that proves a control RLS
--       cannot provide (14-edge-function-security-audit.md:243-245).
--   (6) the takeover test, two concurrent writers, same token, different devices:
--       exactly one commits; the other receives 23505; afterwards count of active rows for
--       that token = 1 AND its owner_device_id is unchanged from the winner. No third
--       state is acceptable.
--   (7) payload token rejection: insert notification_queue with payload '{"token":"x"}'
--       -> must fail on notification_queue_payload_no_token_key_check.
--   (8) stale proof: update ... set status='stale' without stale_at -> CHECK violation
--       (4.x / 2.14), the same device as devices_revoked_credential_consistency (g1-q5).
--   (9) nothing references a missing function:
--       select count(*) from pg_trigger where tgrelid in
--         ('public.push_tokens'::regclass,'public.notification_queue'::regclass);
--       -> 0, honestly reflecting 3.6, not a working enforcement layer.
--  (10) equivalence diff impact: report `devices_id_child_user_id_key` as an intentional
--       staging-only divergence from the production capture (2.4) so A3's
--       staging-vs-production comparison is not silently broken.
--  (11) negative delivery test - THE ONE THAT MATTERS MOST: assert that zero push was
--       sent, because zero push can be sent (O-7). A test suite that reports a green
--       "notification delivered" against this schema is wrong.

commit;

-- ===========================================================================
-- END OF A3c. PREPARED - NOT EXECUTED. Zero cloud calls were made to author it;
-- no secret value appears in it; nothing was staged or committed.
-- Sections 3.6, 4.5, 4.25, 5.3(b), 6 and 8 contain the parts that were marked
-- BLOCKED rather than invented: 4 function bodies, the notification type domain,
-- the queue transition/backoff rules, the parent-facing policy that depends on
-- private.is_family_parent, the Realtime publication statement, and the whole
-- FCM send path plus identity mapping.
-- ===========================================================================
