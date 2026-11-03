-- ============================================================================
-- HAVEN PARENTAL CONTROL -- STAGE 2 / G3-c -- A3 STAGING LOAD v1
-- File: docs/stage2/migrations/A3-staging-load-v1.sql
-- ============================================================================
-- TARGET PROJECT (the ONLY permitted target): parent-control-staging
--                                            ref dzonzgngwxclhfnvxtvu
-- FORBIDDEN TARGET: parent-control-prod / hhqgreaoqulmfwfwarhc. That ref occurs in the
--   source artefact's headers as provenance only. Nothing here addresses it as a target,
--   and this file must never be pasted into that project's SQL Editor. The sentinel guard
--   in SECTION 0 is the control that makes a wrong-project paste abort before DDL #1.
--
-- SERVER ASSUMPTION: PostgreSQL 17.
--   Production capture 17.11 -- ev: g1-run-manifest-20261029.md current_setting('server_version'),
--   restated at src: 00-platform-assumptions.sql:14. Staging shell reports 17.11.0.003
--   -- ev: docs/stage2/01-staging-project-proposal.md:6. The GRANT MAINTAIN privilege (19x) and
--   the MAINTAIN keyword in ALTER DEFAULT PRIVILEGES (4x) are PG17 vocabulary, not PG15-and-below.
--
-- APPROVALS REQUIRED BEFORE ANY PASTE:
--   A2'(a) -- the environment sentinel private.s2_environment = 'staging' must ALREADY EXIST.
--              It is created BEFORE this load under the owner's Sequence A decision on blocker B-2
--              -- ev: docs/stage2/00-stage2-execution-plan.md:92, :135, :149-153. A2'(a) is UNSIGNED.
--   A3     -- authorises the G3-c staging schema load itself
--              -- ev: docs/stage2/00-stage2-execution-plan.md:90 (step 7, gate A3). A3 is UNSIGNED.
--
-- STATUS: *** NOT EXECUTED *** -- no statement in this file has been run, and none was run to
--   produce it. It was assembled offline from local files only: no dashboard, no browser, no SQL
--   execution, no REST, no supabase CLI, no database connection, no curl. A human operator pastes
--   it into the STAGING Supabase SQL Editor only after A2'(a) is signed+executed and A3 is signed.
--
-- SOURCE ARTEFACT THIS DERIVES FROM (byte-identical digest of the assembled file):
--   C:\Users\ASUS\.qoder\tmp\D--control\g3-build\g3-reconstruction-2026-11-02.sql
--   SHA-256 = fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6  (459 active statements)
--   Components used: 00-platform-assumptions.sql, 10-tables.sql, 20-constraints.sql, 30-indexes.sql,
--   40-functions.sql, 50-triggers.sql, 55-auth-users-trigger.sql, 60-rls-policies.sql,
--   70-grants-default-privileges.sql, 80-realtime-publication.sql.
--   Evidence set: docs/stage1/evidence/g1-q1, q2, q3, q3b, q4, q5, q6, q8, b3b (20261029), plus
--   docs/stage2/S2-EXEC-04-sql-structural-findings.md (work list H-1..H-3, M-1..M-5, I-1..I-4).
--   Every deviation from the source artefact is itemised in the STATUS block at the END of this file.
--
-- ============================================================================
-- HOW TO VERIFY BEFORE RUNNING (operator checklist -- run these first, in the STAGING editor)
-- ============================================================================
-- [1] Confirm the editor tab is the staging project: the dashboard header must read
--     parent-control-staging / dzonzgngwxclhfnvxtvu. The dashboard presents two identical
--     editors and no catalogue-only query distinguishes projects by itself
--     -- ev: docs/stage2/00-stage2-execution-plan.md:149-153 (rationale D-09 / redteam J-03).
-- [2] Confirm the sentinel exists and reads 'staging' (A2'(a) executed). If this returns no row
--     or any other value, DO NOT PASTE SECTION 0-8; SECTION 0's guard would abort anyway:
--        SELECT environment FROM private.s2_environment LIMIT 1;   -- expected: staging
--     (table/column shape taken verbatim from the already-reviewed patch guard
--      -- ev: docs/stage2/patches/S2-P01-e2-f8.sql:105-111.)
-- [3] Confirm the server is PG17: SELECT current_setting('server_version'); -- expected 17.x
-- [4] Re-verify the source digest this file derives from:
--        sha256sum g3-reconstruction-2026-11-02.sql
--     must equal fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6. If it differs,
--     the artefact was edited after review and this file is stale -- stop.
-- [5] Capture the staging PRIOR state before pasting (the artefact records production's intended
--     values but never staging's prior values; S2-EXEC-04 "Rollback-readiness" calls this out):
--        SELECT * FROM pg_default_acl JOIN pg_namespace n ON n.oid=defaclnamespace
--          WHERE n.nspname='public';                        -- rollback target is undefined without it
--        SELECT r.rolname, m.rolname AS member_of FROM pg_auth_members a
--          JOIN pg_roles r ON r.oid=a.roleid JOIN pg_roles m ON m.oid=a.member
--          WHERE r.rolname IN ('supabase_admin','postgres'); -- closes H-3's uncertainty
-- [6] Run the 13 per-statement probes in SECTION 9 BEFORE pasting SECTION 9 (see H-3 note there).
-- [7] Confirm the load is pasted in TWO parts: SECTION 0-8 inside one BEGIN/COMMIT, then
--     SECTION 9 separately, then SECTION 10 (read-only) separately. Never paste SECTION 11.
-- [8] Expect the statement_timeout / lock_timeout of the dashboard session to be generous;
--     the platform role config recorded for the authenticator is statement_timeout=8s,
--     lock_timeout=8s -- ev: g1-b3b authenticator_role_config / src: 00:44. That is NOT the
--     dashboard's role, but if the batch is throttled, stop and reassess rather than re-running:
--     NOTHING in SECTION 0-8 uses IF NOT EXISTS, so a retry after a partial load fails at the
--     first existing object (S2-EXEC-04: "idempotency is absent").
-- [9] Confirm no secret is expected in this file: it contains role names and ACL strings only.
--     Zero keys, JWTs, connection strings, emails, coordinates or row data appear anywhere.
--
-- ============================================================================
-- TRANSACTION POLICY (repairs S2-EXEC-04 finding M-1)
-- ============================================================================
-- The whole structural load (SECTION 0..SECTION 8) is wrapped in BEGIN ... COMMIT.
-- WHY: the source artefact has NO transaction wrapper at all (grep '^\s*(BEGIN|COMMIT|ROLLBACK)'
-- over its 11 .sql files: 0 hits -- S2-EXEC-04 M-1). Its statement #448 is
--   ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ... ON SEQUENCES TO anon;
-- (src: 70:323) and ALTER DEFAULT PRIVILEGES FOR ROLE <X> requires the executing role to be a
-- member of X. The captured membership set (g1-q6.role_memberships, 24 rows, filtered) contains
-- NO row naming supabase_admin as a group of postgres, and 00:44 records that postgres is not
-- superuser-class on Supabase. If staging mirrors production membership, statement #448 fails with
--   42501: permission denied  --  "must be member of role \"supabase_admin\""
-- and, un-wrapped, statements #1..#447 would stay applied while #448..#459 never run: 19 tables,
-- 137 constraints, 34 indexes, 19 RLS enables and 236 of the 248 section-70 grants persisted, with
-- a staging ACL divergent from both the reconstruction and production's pg_default_acl
-- (g1-q6.default_acl rows 3, 16-18). With the wrapper, that same failure rolls the ENTIRE load
-- back and staging stays the empty shell it is today. The 13 default-privilege statements are then
-- moved OUT of the transaction into SECTION 9 so a membership failure there cannot abort the load.
-- Secondary partial-failure state this wrapper also prevents (S2-EXEC-04 M-1, bare-Postgres case):
-- a load that dies at CREATE TABLE public.safe_zones because DEFAULT auth.uid() has no 'auth'
-- schema there. On Supabase auth.uid() exists, so this file keeps those two defaults as captured.

BEGIN;                                   -- transaction control; not counted as a load statement

-- ============================================================================
-- SECTION 0 -- WRONG-PROJECT SENTINEL GUARD  (1 active statement)
-- ============================================================================
-- Control added by this file; the source artefact contains no guard (S2-EXEC-04: "no rollback
-- component at all", "0 statements that prove which project you are in"). Requires A2'(a).
-- Abort conditions, in order: (a) private.s2_environment missing  -> A2'(a) not executed;
-- (b) the row value is not 'staging' -> wrong project, or a sentinel written by something else.
-- RAISE EXCEPTION inside the transaction aborts the batch, so nothing below it can apply.
DO $$                                                    -- ev: docs/stage2/00-stage2-execution-plan.md:149-153 (D-09);
DECLARE v_env text;                                      --     docs/stage2/01-staging-project-proposal.md:105-106, :179;
BEGIN                                                    --     docs/stage2/patches/S2-P01-e2-f8.sql:105-111 (guard text reused)
  IF to_regclass('private.s2_environment') IS NULL THEN
    RAISE EXCEPTION 'A3 staging load: sentinel private.s2_environment is missing; A2''(a) is not executed -- refusing to run outside staging';
  END IF;
  EXECUTE 'SELECT environment FROM private.s2_environment LIMIT 1' INTO v_env;
  IF v_env IS DISTINCT FROM 'staging' THEN
    RAISE EXCEPTION 'A3 staging load: sentinel reads %, not staging -- refusing', COALESCE(v_env, '<null>');
  END IF;
END $$;

-- ============================================================================
-- SECTION 10-equivalent (src 00) -- SCHEMAS  (2 active statements)
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS public;      -- ev: g1-q1 table_name rows all resolve in public | src: 00:33
                                         -- NOTE (S2-EXEC-04 L-2): permanent no-op NOTICE on Supabase; kept so the
                                         --      load is self-describing. Not a load blocker.
CREATE SCHEMA IF NOT EXISTS private;     -- ev: g1-b3b inventory (38 functions, schema_name per row) | src: 00:35
-- Platform-managed schemas auth / storage / realtime / extensions / graphql / graphql_public are
-- evidenced (g1-q6.default_acl schema_name values; g1-b3b schemas_exposed_chips) and deliberately
-- NOT recreated here -- A0 forbids recreating platform-managed objects (src: 00:27-32).
-- Extensions are NOT PRESENT IN EVIDENCE (no pg_extension query in the G1 series): the 16
-- DEFAULT gen_random_uuid() sites below resolve as PG13+ built-ins on a PG17 target
-- -- ev: S2-EXEC-04 I-1; src: 00:20-25. NO CREATE EXTENSION is emitted.

-- ============================================================================
-- SECTION 10 -- TABLES AND COLUMNS  (19 active statements, 183 columns)
-- ============================================================================
-- ev per table: g1-q8 rows (table_name, column_name, ordinal_position, data_type, is_nullable,
-- column_default) + g1-q1 rows (rls_enabled, rls_forced, owner). Parsed counts: tables=19,
-- columns=183, not-null=137, defaults=69 (src: 10:281). COLUMNS ONLY here: keys/checks/FKs are in
-- SECTION 2 BY DESIGN (src: 10:14-15) -- their absence here is not missing data.
-- All 19 tables are owned by postgres in the capture (g1-q1.owner); CREATE TABLE here runs as the
-- dashboard role, which on Supabase staging is postgres -- INFERRED, load-time untestable offline.

CREATE TABLE public.audit_logs (         -- ev: g1-q8 rows for audit_logs (9 columns) | src: 10:23-33
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid,
    actor_user_id uuid,
    device_id uuid,
    event_type text NOT NULL,
    target_type text,
    target_id text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.child_contact_ids ( -- ev: g1-q8 rows for child_contact_ids (4 columns) | src: 10:36-41
    child_user_id uuid NOT NULL,
    contact_id text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    rotated_at timestamp with time zone
);

CREATE TABLE public.device_apps (       -- ev: g1-q8 rows for device_apps (9 columns) | src: 10:44-54
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL,
    family_id uuid NOT NULL,
    package_name text NOT NULL,
    label text NOT NULL DEFAULT ''::text,
    is_system boolean NOT NULL DEFAULT false,
    is_suspended boolean NOT NULL DEFAULT false,
    version_name text,
    reported_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.device_commands (   -- ev: g1-q8 rows for device_commands (15 columns) | src: 10:57-73
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL,
    family_id uuid NOT NULL,
    type text NOT NULL,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    status text NOT NULL DEFAULT 'pending'::text,
    idempotency_key text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone NOT NULL,
    delivered_at timestamp with time zone,
    acked_at timestamp with time zone,
    result jsonb,
    error_message text,
    attempts integer NOT NULL DEFAULT 0
);

CREATE TABLE public.device_pairing_tokens ( -- ev: g1-q8 rows for device_pairing_tokens (12 columns) | src: 10:76-89
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    child_user_id uuid NOT NULL,
    code_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    redeemed_at timestamp with time zone,
    redeemed_by uuid,
    status text NOT NULL DEFAULT 'active'::text,
    attempts integer NOT NULL DEFAULT 0,
    max_attempts integer NOT NULL DEFAULT 10,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid,
    purpose text NOT NULL DEFAULT 'code'::text
);

CREATE TABLE public.device_policies (   -- ev: g1-q8 rows for device_policies (10 columns) | src: 10:92-103
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL,
    family_id uuid NOT NULL,
    version integer NOT NULL,
    policy jsonb NOT NULL,
    created_by uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    acknowledged_at timestamp with time zone,
    enforcement_status text NOT NULL DEFAULT 'pending'::text,
    last_error text
);

CREATE TABLE public.devices (           -- ev: g1-q8 rows for devices (25 columns) | src: 10:106-132
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL,
    child_user_id uuid NOT NULL,
    installation_id text NOT NULL,
    display_name text NOT NULL,
    platform text NOT NULL DEFAULT 'android'::text,
    android_version text,
    app_version text,
    status text NOT NULL DEFAULT 'pending'::text,
    secret_hash text,
    credential_issued_at timestamp with time zone,
    credential_revoked_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    battery_level integer,
    is_charging boolean,
    enforcement_mode text NOT NULL DEFAULT 'none'::text,
    policy_version integer NOT NULL DEFAULT 0,
    usage_access_granted boolean,
    location_granted boolean,
    background_location_granted boolean,
    camera_granted boolean,
    microphone_granted boolean,
    notifications_granted boolean,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.families (          -- ev: g1-q8 rows for families (7 columns) | src: 10:135-143
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL,
    owner_id uuid NOT NULL,
    settings jsonb NOT NULL DEFAULT '{"usage_retention_days": 90, "location_retention_days": 30}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone
);

CREATE TABLE public.family_members (    -- ev: g1-q8 rows for family_members (7 columns) | src: 10:146-154
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    status text NOT NULL DEFAULT 'active'::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    removed_at timestamp with time zone
);

CREATE TABLE public.location_events (   -- ev: g1-q8 rows for location_events (9 columns) | src: 10:157-167
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL,
    family_id uuid NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    accuracy_m real NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    received_at timestamp with time zone NOT NULL DEFAULT now(),
    source text NOT NULL DEFAULT 'device'::text
);

CREATE TABLE public.pairing_attempts (  -- ev: g1-q8 rows for pairing_attempts (5 columns) | src: 10:170-176
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    parent_user_id uuid NOT NULL,
    code_hash text NOT NULL,
    attempted_at timestamp with time zone NOT NULL DEFAULT now(),
    success boolean NOT NULL DEFAULT false
);

CREATE TABLE public.pairing_requests (  -- ev: g1-q8 rows for pairing_requests (9 columns) | src: 10:179-189
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    token_id uuid NOT NULL,
    family_id uuid NOT NULL,
    parent_user_id uuid NOT NULL,
    child_user_id uuid NOT NULL,
    status text NOT NULL DEFAULT 'pending_child'::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone NOT NULL,
    responded_at timestamp with time zone
);

CREATE TABLE public.profiles (          -- ev: g1-q8 rows for profiles (5 columns) | src: 10:192-198
    id uuid NOT NULL,
    role text NOT NULL DEFAULT 'unset'::text,
    display_name text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.remote_sessions (   -- ev: g1-q8 rows for remote_sessions (17 columns) | src: 10:201-219
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL,
    device_id uuid NOT NULL,
    parent_user_id uuid NOT NULL,
    child_user_id uuid NOT NULL,
    kind text NOT NULL,
    status text NOT NULL DEFAULT 'requested'::text,
    requested_at timestamp with time zone NOT NULL DEFAULT now(),
    accepted_at timestamp with time zone,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    expires_at timestamp with time zone,
    ended_by uuid,
    ended_reason text,
    consent_recorded boolean NOT NULL DEFAULT false,
    session_nonce uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.safe_zone_states (  -- ev: g1-q8 rows for safe_zone_states (4 columns) | src: 10:222-227
    zone_id uuid NOT NULL,
    device_id uuid NOT NULL,
    inside boolean NOT NULL,
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.safe_zones (        -- ev: g1-q8 rows for safe_zones (9 columns) | src: 10:230-240
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL,
    name text NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    radius_m double precision NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_by uuid DEFAULT auth.uid(),
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.safety_alerts (     -- ev: g1-q8 rows for safety_alerts (10 columns) | src: 10:243-254
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL,
    device_id uuid NOT NULL,
    type text NOT NULL,
    severity text NOT NULL,
    message text NOT NULL,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    acknowledged_at timestamp with time zone,
    acknowledged_by uuid
);

CREATE TABLE public.usage_daily (       -- ev: g1-q8 rows for usage_daily (10 columns) | src: 10:257-268
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL,
    family_id uuid NOT NULL,
    day date NOT NULL,
    package_name text NOT NULL,
    app_label text NOT NULL DEFAULT ''::text,
    total_ms bigint NOT NULL,
    last_used_at timestamp with time zone,
    uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
    source text NOT NULL DEFAULT 'usage_stats'::text
);

CREATE TABLE public.webrtc_signals (    -- ev: g1-q8 rows for webrtc_signals (7 columns) | src: 10:271-279
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL,
    from_user_id uuid NOT NULL DEFAULT auth.uid(),
    kind text NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    sequence bigint NOT NULL
);

-- ============================================================================
-- SECTION 20 -- CONSTRAINTS  (137 active statements)
-- ============================================================================
-- ev per statement: g1-q5 rows (constraint_name, table_name, kind, definition, validated).
-- Distribution measured from the capture and confirmed by the artefact (src: 20:14):
--   kind f=44, c=65, p=19, u=9  ->  137 total.
-- All 137 rows report validated=true (g1-q5.validated), so no NOT VALID clause is emitted --
--   S2-EXEC-04 check 4: 0 mismatches against pg_get_constraintdef text.
-- Ordering is preserved from the source: PK (indexes FKs need them) -> UNIQUE -> CHECK -> FK.
-- FK TARGETS ARE NOW schema-QUALIFIED TO public. (deviation D-1, repairs S2-EXEC-04 M-5): the
--   source emitted 43 of 44 FKs unqualified ("REFERENCES profiles(id)") and relied on the loader's
--   search_path. The single genuine cross-schema FK, profiles_id_fkey -> auth.users(id) (src: 20:147),
--   is left exactly as captured. 43 statements changed, 1 unchanged.
-- DEPENDENCY PROOF carried over from the source (S2-EXEC-04 check 2): last PK precedes first FK;
--   0 statements reference a table whose backing PK/UNIQUE is created later.

-- ---- PRIMARY KEY (19 statements) ----
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);                                        -- ev: g1-q5.constraint_name+definition (kind=p) | src: 20:21
ALTER TABLE public.child_contact_ids ADD CONSTRAINT child_contact_ids_pkey PRIMARY KEY (child_user_id);             -- ev: g1-q5 (kind=p) | src: 20:22
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_pkey PRIMARY KEY (id);                                     -- ev: g1-q5 (kind=p) | src: 20:23
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_pkey PRIMARY KEY (id);                            -- ev: g1-q5 (kind=p) | src: 20:24
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_pkey PRIMARY KEY (id);                -- ev: g1-q5 (kind=p) | src: 20:25
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_pkey PRIMARY KEY (id);                             -- ev: g1-q5 (kind=p) | src: 20:26
ALTER TABLE public.devices ADD CONSTRAINT devices_pkey PRIMARY KEY (id);                                             -- ev: g1-q5 (kind=p) | src: 20:27
ALTER TABLE public.families ADD CONSTRAINT families_pkey PRIMARY KEY (id);                                           -- ev: g1-q5 (kind=p) | src: 20:28
ALTER TABLE public.family_members ADD CONSTRAINT family_members_pkey PRIMARY KEY (id);                               -- ev: g1-q5 (kind=p) | src: 20:29
ALTER TABLE public.location_events ADD CONSTRAINT location_events_pkey PRIMARY KEY (id);                             -- ev: g1-q5 (kind=p) | src: 20:30
ALTER TABLE public.pairing_attempts ADD CONSTRAINT pairing_attempts_pkey PRIMARY KEY (id);                           -- ev: g1-q5 (kind=p) | src: 20:31
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_pkey PRIMARY KEY (id);                           -- ev: g1-q5 (kind=p) | src: 20:32
ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);                                           -- ev: g1-q5 (kind=p) | src: 20:33
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_pkey PRIMARY KEY (id);                             -- ev: g1-q5 (kind=p) | src: 20:34
ALTER TABLE public.safe_zone_states ADD CONSTRAINT safe_zone_states_pkey PRIMARY KEY (zone_id, device_id);           -- ev: g1-q5 (kind=p) | src: 20:35
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_pkey PRIMARY KEY (id);                                       -- ev: g1-q5 (kind=p) | src: 20:36
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_pkey PRIMARY KEY (id);                                  -- ev: g1-q5 (kind=p) | src: 20:37
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_pkey PRIMARY KEY (id);                                     -- ev: g1-q5 (kind=p) | src: 20:38
ALTER TABLE public.webrtc_signals ADD CONSTRAINT webrtc_signals_pkey PRIMARY KEY (id);                               -- ev: g1-q5 (kind=p) | src: 20:39

-- ---- UNIQUE (9 statements) ----
ALTER TABLE public.child_contact_ids ADD CONSTRAINT child_contact_ids_contact_id_key UNIQUE (contact_id);                            -- ev: g1-q5 (kind=u) | src: 20:42
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_device_package_key UNIQUE (device_id, package_name);                        -- ev: g1-q5 (kind=u) | src: 20:43
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_device_idempotency_key UNIQUE (device_id, idempotency_key);         -- ev: g1-q5 (kind=u) | src: 20:44
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_code_hash_key UNIQUE (code_hash);                       -- ev: g1-q5 (kind=u) | src: 20:45
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_device_version_key UNIQUE (device_id, version);                     -- ev: g1-q5 (kind=u) | src: 20:46
ALTER TABLE public.devices ADD CONSTRAINT devices_family_installation_key UNIQUE (family_id, installation_id);                         -- ev: g1-q5 (kind=u) | src: 20:47
ALTER TABLE public.family_members ADD CONSTRAINT family_members_family_user_key UNIQUE (family_id, user_id);                           -- ev: g1-q5 (kind=u) | src: 20:48
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_token_id_key UNIQUE (token_id);                                   -- ev: g1-q5 (kind=u) | src: 20:49
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_device_day_package_key UNIQUE (device_id, day, package_name);                -- ev: g1-q5 (kind=u) | src: 20:50

-- ---- CHECK (65 statements) ----
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_event_type_check CHECK (((char_length(event_type) >= 1) AND (char_length(event_type) <= 80)));       -- ev: g1-q5 (kind=c) | src: 20:53
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_metadata_check CHECK ((jsonb_typeof(metadata) = 'object'::text));                                     -- ev: g1-q5 (kind=c) | src: 20:54
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_target_id_check CHECK (((target_id IS NULL) OR (char_length(target_id) <= 128)));                      -- ev: g1-q5 (kind=c) | src: 20:55
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_target_type_check CHECK (((target_type IS NULL) OR (char_length(target_type) <= 40)));                 -- ev: g1-q5 (kind=c) | src: 20:56
ALTER TABLE public.child_contact_ids ADD CONSTRAINT child_contact_ids_contact_id_check CHECK ((contact_id ~ '^PC[23456789ABCDEFGHJKMNPQRSTVWXYZ]{8}$'::text)); -- ev: g1-q5 (kind=c) | src: 20:57
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_label_check CHECK ((char_length(label) <= 100));                                 -- ev: g1-q5 (kind=c) | src: 20:58
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_package_name_check CHECK (((char_length(package_name) >= 1) AND (char_length(package_name) <= 150)));  -- ev: g1-q5 (kind=c) | src: 20:59
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_version_name_check CHECK (((version_name IS NULL) OR (char_length(version_name) <= 64)));  -- ev: g1-q5 (kind=c) | src: 20:60
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_attempts_check CHECK ((attempts >= 0));                    -- ev: g1-q5 (kind=c) | src: 20:61
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_error_message_check CHECK (((error_message IS NULL) OR (char_length(error_message) <= 500)));  -- ev: g1-q5 (kind=c) | src: 20:62
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_idempotency_key_check CHECK (((char_length(idempotency_key) >= 1) AND (char_length(idempotency_key) <= 128)));  -- ev: g1-q5 (kind=c) | src: 20:63
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text));  -- ev: g1-q5 (kind=c) | src: 20:64
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'delivered'::text, 'succeeded'::text, 'failed'::text, 'expired'::text])));  -- ev: g1-q5 (kind=c) | src: 20:65
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_type_check CHECK ((type = ANY (ARRAY['apply_policy'::text, 'sync_policy'::text, 'request_usage'::text, 'request_location'::text, 'end_session'::text, 'custom'::text])));  -- ev: g1-q5 (kind=c) | src: 20:66
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_attempts_check CHECK ((attempts >= 0));  -- ev: g1-q5 (kind=c) | src: 20:67
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_code_hash_check CHECK ((code_hash ~ '^[0-9a-f]{64}$'::text));  -- ev: g1-q5 (kind=c) | src: 20:68
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_max_attempts_check CHECK ((max_attempts > 0));  -- ev: g1-q5 (kind=c) | src: 20:69
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_purpose_check CHECK ((purpose = ANY (ARRAY['code'::text, 'invite'::text])));  -- ev: g1-q5 (kind=c) | src: 20:70
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_status_check CHECK ((status = ANY (ARRAY['active'::text, 'redeemed'::text, 'revoked'::text, 'expired'::text])));  -- ev: g1-q5 (kind=c) | src: 20:71
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_enforcement_status_check CHECK ((enforcement_status = ANY (ARRAY['pending'::text, 'enforced'::text, 'failed'::text, 'unsupported'::text])));  -- ev: g1-q5 (kind=c) | src: 20:72
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_last_error_check CHECK (((last_error IS NULL) OR (char_length(last_error) <= 500)));  -- ev: g1-q5 (kind=c) | src: 20:73
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_policy_check CHECK ((jsonb_typeof(policy) = 'object'::text));  -- ev: g1-q5 (kind=c) | src: 20:74
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_version_check CHECK ((version >= 1));                         -- ev: g1-q5 (kind=c) | src: 20:75
ALTER TABLE public.devices ADD CONSTRAINT devices_android_version_check CHECK (((android_version IS NULL) OR ((char_length(android_version) >= 1) AND (char_length(android_version) <= 40))));  -- ev: g1-q5 (kind=c) | src: 20:76
ALTER TABLE public.devices ADD CONSTRAINT devices_app_version_check CHECK (((app_version IS NULL) OR ((char_length(app_version) >= 1) AND (char_length(app_version) <= 40))));  -- ev: g1-q5 (kind=c) | src: 20:77
ALTER TABLE public.devices ADD CONSTRAINT devices_battery_level_check CHECK (((battery_level >= 0) AND (battery_level <= 100)));  -- ev: g1-q5 (kind=c) | src: 20:78
ALTER TABLE public.devices ADD CONSTRAINT devices_display_name_check CHECK (((char_length(display_name) >= 1) AND (char_length(display_name) <= 80)));  -- ev: g1-q5 (kind=c) | src: 20:79
ALTER TABLE public.devices ADD CONSTRAINT devices_enforcement_mode_check CHECK ((enforcement_mode = ANY (ARRAY['none'::text, 'device_admin'::text, 'device_owner'::text])));  -- ev: g1-q5 (kind=c) | src: 20:80
ALTER TABLE public.devices ADD CONSTRAINT devices_installation_id_check CHECK (((char_length(installation_id) >= 8) AND (char_length(installation_id) <= 128)));  -- ev: g1-q5 (kind=c) | src: 20:81
ALTER TABLE public.devices ADD CONSTRAINT devices_platform_check CHECK (((char_length(platform) >= 1) AND (char_length(platform) <= 32)));  -- ev: g1-q5 (kind=c) | src: 20:82
ALTER TABLE public.devices ADD CONSTRAINT devices_policy_version_check CHECK ((policy_version >= 0));                         -- ev: g1-q5 (kind=c) | src: 20:83
ALTER TABLE public.devices ADD CONSTRAINT devices_revoked_credential_consistency CHECK (((status <> 'revoked'::text) OR (secret_hash IS NULL)));  -- ev: g1-q5 (kind=c) | src: 20:84
ALTER TABLE public.devices ADD CONSTRAINT devices_secret_hash_check CHECK (((secret_hash IS NULL) OR (secret_hash ~ '^[0-9a-f]{64}$'::text)));  -- ev: g1-q5 (kind=c) | src: 20:85
ALTER TABLE public.devices ADD CONSTRAINT devices_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'revoked'::text])));  -- ev: g1-q5 (kind=c) | src: 20:86
ALTER TABLE public.families ADD CONSTRAINT families_name_check CHECK (((char_length(name) >= 1) AND (char_length(name) <= 80)));  -- ev: g1-q5 (kind=c) | src: 20:87
ALTER TABLE public.families ADD CONSTRAINT families_settings_check CHECK ((jsonb_typeof(settings) = 'object'::text));              -- ev: g1-q5 (kind=c) | src: 20:88
ALTER TABLE public.family_members ADD CONSTRAINT family_members_removed_consistency CHECK (((status = 'removed'::text) = (removed_at IS NOT NULL)));  -- ev: g1-q5 (kind=c) | src: 20:89
ALTER TABLE public.family_members ADD CONSTRAINT family_members_role_check CHECK ((role = ANY (ARRAY['parent'::text, 'child'::text])));  -- ev: g1-q5 (kind=c) | src: 20:90
ALTER TABLE public.family_members ADD CONSTRAINT family_members_status_check CHECK ((status = ANY (ARRAY['active'::text, 'removed'::text])));  -- ev: g1-q5 (kind=c) | src: 20:91
ALTER TABLE public.location_events ADD CONSTRAINT location_events_accuracy_m_check CHECK ((accuracy_m >= (0)::double precision));  -- ev: g1-q5 (kind=c) | src: 20:92
ALTER TABLE public.location_events ADD CONSTRAINT location_events_lat_check CHECK (((lat >= ('-90'::integer)::double precision) AND (lat <= (90)::double precision)));  -- ev: g1-q5 (kind=c) | src: 20:93
ALTER TABLE public.location_events ADD CONSTRAINT location_events_lng_check CHECK (((lng >= ('-180'::integer)::double precision) AND (lng <= (180)::double precision)));  -- ev: g1-q5 (kind=c) | src: 20:94
ALTER TABLE public.location_events ADD CONSTRAINT location_events_source_check CHECK (((char_length(source) >= 1) AND (char_length(source) <= 40)));  -- ev: g1-q5 (kind=c) | src: 20:95
ALTER TABLE public.pairing_attempts ADD CONSTRAINT pairing_attempts_code_hash_check CHECK ((code_hash ~ '^[0-9a-f]{64}$'::text));  -- ev: g1-q5 (kind=c) | src: 20:96
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_status_check CHECK ((status = ANY (ARRAY['pending_child'::text, 'approved'::text, 'rejected'::text, 'cancelled'::text, 'expired'::text])));  -- ev: g1-q5 (kind=c) | src: 20:97
ALTER TABLE public.profiles ADD CONSTRAINT profiles_display_name_check CHECK (((char_length(display_name) >= 1) AND (char_length(display_name) <= 60)));  -- ev: g1-q5 (kind=c) | src: 20:98
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['unset'::text, 'parent'::text, 'child'::text])));  -- ev: g1-q5 (kind=c) | src: 20:99
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_ended_reason_check CHECK (((ended_reason IS NULL) OR (char_length(ended_reason) <= 200)));  -- ev: g1-q5 (kind=c) | src: 20:100
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_kind_check CHECK ((kind = ANY (ARRAY['audio'::text, 'video'::text])));  -- ev: g1-q5 (kind=c) | src: 20:101
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_pending_expiry_check CHECK (((status <> 'requested'::text) OR (expires_at IS NOT NULL)));  -- ev: g1-q5 (kind=c) | src: 20:102
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_status_check CHECK ((status = ANY (ARRAY['requested'::text, 'accepted'::text, 'active'::text, 'declined'::text, 'ended'::text, 'expired'::text, 'failed'::text])));  -- ev: g1-q5 (kind=c) | src: 20:103
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_lat_check CHECK (((lat >= ('-90'::integer)::double precision) AND (lat <= (90)::double precision)));  -- ev: g1-q5 (kind=c) | src: 20:104
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_lng_check CHECK (((lng >= ('-180'::integer)::double precision) AND (lng <= (180)::double precision)));  -- ev: g1-q5 (kind=c) | src: 20:105
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_name_check CHECK (((char_length(name) >= 1) AND (char_length(name) <= 60)));  -- ev: g1-q5 (kind=c) | src: 20:106
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_radius_m_check CHECK (((radius_m >= (50)::double precision) AND (radius_m <= (5000)::double precision)));  -- ev: g1-q5 (kind=c) | src: 20:107
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_message_check CHECK (((char_length(message) >= 1) AND (char_length(message) <= 300)));  -- ev: g1-q5 (kind=c) | src: 20:108
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text));          -- ev: g1-q5 (kind=c) | src: 20:109
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_severity_check CHECK ((severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text])));  -- ev: g1-q5 (kind=c) | src: 20:110
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_type_check CHECK ((type = ANY (ARRAY['low_battery'::text, 'offline'::text, 'geofence_enter'::text, 'geofence_exit'::text, 'app_blocked'::text, 'permission_missing'::text, 'other'::text])));  -- ev: g1-q5 (kind=c) | src: 20:111
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_app_label_check CHECK ((char_length(app_label) <= 100));                      -- ev: g1-q5 (kind=c) | src: 20:112
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_package_name_check CHECK (((char_length(package_name) >= 1) AND (char_length(package_name) <= 150)));  -- ev: g1-q5 (kind=c) | src: 20:113
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_source_check CHECK (((char_length(source) >= 1) AND (char_length(source) <= 32)));  -- ev: g1-q5 (kind=c) | src: 20:114
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_total_ms_check CHECK ((total_ms >= 0));                                    -- ev: g1-q5 (kind=c) | src: 20:115
ALTER TABLE public.webrtc_signals ADD CONSTRAINT webrtc_signals_kind_check CHECK ((kind = ANY (ARRAY['offer'::text, 'answer'::text, 'ice'::text])));  -- ev: g1-q5 (kind=c) | src: 20:116
ALTER TABLE public.webrtc_signals ADD CONSTRAINT webrtc_signals_payload_check CHECK ((octet_length((payload)::text) <= 16384));        -- ev: g1-q5 (kind=c) | src: 20:117

-- ---- FOREIGN KEY (44 statements; 43 targets qualified to public., 1 left as auth.users) ----
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;   -- ev: g1-q5 (kind=f) + g1-q1 (referenced table is in public) | src: 20:120 | QUALIFIED (D-1, M-5)
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE SET NULL;             -- ev: g1-q5 (kind=f) | src: 20:121 | QUALIFIED (D-1, M-5)
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE SET NULL;            -- ev: g1-q5 (kind=f) | src: 20:122 | QUALIFIED (D-1, M-5)
ALTER TABLE public.child_contact_ids ADD CONSTRAINT child_contact_ids_child_user_id_fkey FOREIGN KEY (child_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:123 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;           -- ev: g1-q5 (kind=f) | src: 20:124 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_apps ADD CONSTRAINT device_apps_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;          -- ev: g1-q5 (kind=f) | src: 20:125 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:126 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;   -- ev: g1-q5 (kind=f) | src: 20:127 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_commands ADD CONSTRAINT device_commands_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:128 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_child_user_id_fkey FOREIGN KEY (child_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:129 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:130 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_pairing_tokens ADD CONSTRAINT device_pairing_tokens_redeemed_by_fkey FOREIGN KEY (redeemed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:131 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:132 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;   -- ev: g1-q5 (kind=f) | src: 20:133 | QUALIFIED (D-1, M-5)
ALTER TABLE public.device_policies ADD CONSTRAINT device_policies_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:134 | QUALIFIED (D-1, M-5)
ALTER TABLE public.devices ADD CONSTRAINT devices_child_user_id_fkey FOREIGN KEY (child_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;          -- ev: g1-q5 (kind=f) | src: 20:135 | QUALIFIED (D-1, M-5)
ALTER TABLE public.devices ADD CONSTRAINT devices_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;                  -- ev: g1-q5 (kind=f) | src: 20:136 | QUALIFIED (D-1, M-5)
ALTER TABLE public.families ADD CONSTRAINT families_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;                   -- ev: g1-q5 (kind=f) | src: 20:137 | QUALIFIED (D-1, M-5)
ALTER TABLE public.family_members ADD CONSTRAINT family_members_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;   -- ev: g1-q5 (kind=f) | src: 20:138 | QUALIFIED (D-1, M-5)
ALTER TABLE public.family_members ADD CONSTRAINT family_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;        -- ev: g1-q5 (kind=f) | src: 20:139 | QUALIFIED (D-1, M-5)
ALTER TABLE public.location_events ADD CONSTRAINT location_events_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:140 | QUALIFIED (D-1, M-5)
ALTER TABLE public.location_events ADD CONSTRAINT location_events_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:141 | QUALIFIED (D-1, M-5)
ALTER TABLE public.pairing_attempts ADD CONSTRAINT pairing_attempts_parent_user_id_fkey FOREIGN KEY (parent_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:142 | QUALIFIED (D-1, M-5)
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_child_user_id_fkey FOREIGN KEY (child_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:143 | QUALIFIED (D-1, M-5)
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:144 | QUALIFIED (D-1, M-5)
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_parent_user_id_fkey FOREIGN KEY (parent_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:145 | QUALIFIED (D-1, M-5)
ALTER TABLE public.pairing_requests ADD CONSTRAINT pairing_requests_token_id_fkey FOREIGN KEY (token_id) REFERENCES public.device_pairing_tokens(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:146 | QUALIFIED (D-1, M-5)
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:147 | NOT QUALIFIED -- this is the artefact's ONE genuine
                                                             -- cross-schema FK and is already schema-qualified as captured. It is also the only ACTIVE
                                                             -- dependency on the platform auth schema besides the two DEFAULT auth.uid() columns
                                                             -- (safe_zones.created_by, webrtc_signals.from_user_id). Satisfiable on Supabase, never on
                                                             -- bare Postgres (S2-EXEC-04 check 3, M-1).
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_child_user_id_fkey FOREIGN KEY (child_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:148 | QUALIFIED (D-1, M-5)
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:149 | QUALIFIED (D-1, M-5)
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_ended_by_fkey FOREIGN KEY (ended_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:150 | QUALIFIED (D-1, M-5)
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:151 | QUALIFIED (D-1, M-5)
ALTER TABLE public.remote_sessions ADD CONSTRAINT remote_sessions_parent_user_id_fkey FOREIGN KEY (parent_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:152 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safe_zone_states ADD CONSTRAINT safe_zone_states_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:153 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safe_zone_states ADD CONSTRAINT safe_zone_states_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.safe_zones(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:154 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;         -- ev: g1-q5 (kind=f) | src: 20:155 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safe_zones ADD CONSTRAINT safe_zones_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;           -- ev: g1-q5 (kind=f) | src: 20:156 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_acknowledged_by_fkey FOREIGN KEY (acknowledged_by) REFERENCES public.profiles(id) ON DELETE SET NULL;  -- ev: g1-q5 (kind=f) | src: 20:157 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;       -- ev: g1-q5 (kind=f) | src: 20:158 | QUALIFIED (D-1, M-5)
ALTER TABLE public.safety_alerts ADD CONSTRAINT safety_alerts_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;      -- ev: g1-q5 (kind=f) | src: 20:159 | QUALIFIED (D-1, M-5)
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;          -- ev: g1-q5 (kind=f) | src: 20:160 | QUALIFIED (D-1, M-5)
ALTER TABLE public.usage_daily ADD CONSTRAINT usage_daily_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;         -- ev: g1-q5 (kind=f) | src: 20:161 | QUALIFIED (D-1, M-5)
ALTER TABLE public.webrtc_signals ADD CONSTRAINT webrtc_signals_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:162 | QUALIFIED (D-1, M-5)
ALTER TABLE public.webrtc_signals ADD CONSTRAINT webrtc_signals_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.remote_sessions(id) ON DELETE CASCADE;  -- ev: g1-q5 (kind=f) | src: 20:163 | QUALIFIED (D-1, M-5)

-- ============================================================================
-- SECTION 30 -- INDEXES  (34 active statements)
-- ============================================================================
-- ev: g1-q4 rows (table_name, index_name, definition) -- 62 captured. 28 of the 62 are the indexes
-- that the 19 PRIMARY KEY and 9 UNIQUE constraints above create implicitly; re-emitting them would
-- fail 42P07 "relation already exists" and dropping them loses no coverage. The suppression was
-- re-verified set-exact by S2-EXEC-04 check 6: 62 = 34 + 28 (19 *_pkey + 9 *_key), 3 of the 34 are
-- standalone partial UNIQUE indexes and are correctly emitted. They are listed commented below
-- (verbatim from src: 30) so a reviewer can see nothing was dropped by mistake.
-- g1-q4 carries no schemaname column; every index is assumed public -- INFERRED (src: 30:17); the
-- ON-clause in each definition names public.<table> explicitly, so the index lands in public.

CREATE INDEX audit_logs_actor_idx ON public.audit_logs USING btree (actor_user_id, created_at DESC);                       -- ev: g1-q4.definition | src: 30:19
CREATE INDEX audit_logs_family_created_idx ON public.audit_logs USING btree (family_id, created_at DESC);                  -- ev: g1-q4.definition | src: 30:20
CREATE INDEX device_apps_family_idx ON public.device_apps USING btree (family_id);                                         -- ev: g1-q4.definition | src: 30:25
CREATE INDEX device_commands_device_status_idx ON public.device_commands USING btree (device_id, status, created_at);      -- ev: g1-q4.definition | src: 30:28
CREATE INDEX device_commands_expires_idx ON public.device_commands USING btree (expires_at);                               -- ev: g1-q4.definition | src: 30:29
CREATE INDEX device_pairing_tokens_child_idx ON public.device_pairing_tokens USING btree (child_user_id, status);          -- ev: g1-q4.definition | src: 30:31
CREATE INDEX device_pairing_tokens_child_purpose_idx ON public.device_pairing_tokens USING btree (child_user_id, purpose, status);  -- ev: g1-q4.definition | src: 30:32
CREATE INDEX device_pairing_tokens_expires_idx ON public.device_pairing_tokens USING btree (expires_at);                   -- ev: g1-q4.definition | src: 30:34
CREATE INDEX device_policies_family_idx ON public.device_policies USING btree (family_id);                                 -- ev: g1-q4.definition | src: 30:37
CREATE INDEX devices_child_user_id_idx ON public.devices USING btree (child_user_id);                                      -- ev: g1-q4.definition | src: 30:39
CREATE INDEX devices_family_id_idx ON public.devices USING btree (family_id);                                              -- ev: g1-q4.definition | src: 30:40
CREATE UNIQUE INDEX devices_one_active_per_child ON public.devices USING btree (child_user_id) WHERE (status = 'active'::text);  -- ev: g1-q4.definition | src: 30:42 (standalone partial unique -- NOT constraint-backed)
CREATE INDEX devices_status_idx ON public.devices USING btree (status);                                                    -- ev: g1-q4.definition | src: 30:44
CREATE UNIQUE INDEX families_one_active_per_owner ON public.families USING btree (owner_id) WHERE (deleted_at IS NULL);   -- ev: g1-q4.definition | src: 30:45 (standalone partial unique)
CREATE INDEX family_members_family_id_idx ON public.family_members USING btree (family_id);                                -- ev: g1-q4.definition | src: 30:47
CREATE UNIQUE INDEX family_members_one_active_child_family ON public.family_members USING btree (user_id) WHERE ((status = 'active'::text) AND (role = 'child'::text));  -- ev: g1-q4.definition | src: 30:49 (standalone partial unique)
CREATE INDEX family_members_user_id_idx ON public.family_members USING btree (user_id);                                    -- ev: g1-q4.definition | src: 30:51
CREATE INDEX location_events_device_recorded_idx ON public.location_events USING btree (device_id, recorded_at DESC);       -- ev: g1-q4.definition | src: 30:52
CREATE INDEX location_events_family_recorded_idx ON public.location_events USING btree (family_id, recorded_at DESC);       -- ev: g1-q4.definition | src: 30:53
CREATE INDEX pairing_attempts_code_idx ON public.pairing_attempts USING btree (code_hash, attempted_at DESC);              -- ev: g1-q4.definition | src: 30:55
CREATE INDEX pairing_attempts_parent_idx ON public.pairing_attempts USING btree (parent_user_id, attempted_at DESC);       -- ev: g1-q4.definition | src: 30:56
CREATE INDEX pairing_requests_child_idx ON public.pairing_requests USING btree (child_user_id, status);                    -- ev: g1-q4.definition | src: 30:58
CREATE INDEX pairing_requests_family_idx ON public.pairing_requests USING btree (family_id, status);                       -- ev: g1-q4.definition | src: 30:59
CREATE INDEX pairing_requests_parent_idx ON public.pairing_requests USING btree (parent_user_id, status);                  -- ev: g1-q4.definition | src: 30:60
CREATE INDEX remote_sessions_child_status_idx ON public.remote_sessions USING btree (child_user_id, status);               -- ev: g1-q4.definition | src: 30:64
CREATE INDEX remote_sessions_device_status_idx ON public.remote_sessions USING btree (device_id, status);                  -- ev: g1-q4.definition | src: 30:65
CREATE INDEX remote_sessions_expires_idx ON public.remote_sessions USING btree (expires_at);                               -- ev: g1-q4.definition | src: 30:66
CREATE INDEX remote_sessions_family_idx ON public.remote_sessions USING btree (family_id, requested_at DESC);              -- ev: g1-q4.definition | src: 30:67
CREATE INDEX safe_zones_family_idx ON public.safe_zones USING btree (family_id);                                           -- ev: g1-q4.definition | src: 30:70
CREATE INDEX safety_alerts_device_type_created_idx ON public.safety_alerts USING btree (device_id, type, created_at DESC); -- ev: g1-q4.definition | src: 30:72
CREATE INDEX safety_alerts_family_created_idx ON public.safety_alerts USING btree (family_id, created_at DESC);            -- ev: g1-q4.definition | src: 30:73
CREATE INDEX usage_daily_device_idx ON public.usage_daily USING btree (device_id, day);                                    -- ev: g1-q4.definition | src: 30:76
CREATE INDEX usage_daily_family_day_idx ON public.usage_daily USING btree (family_id, day);                                 -- ev: g1-q4.definition | src: 30:77
CREATE INDEX webrtc_signals_session_sequence_idx ON public.webrtc_signals USING btree (session_id, sequence);              -- ev: g1-q4.definition | src: 30:80

-- 28 SUPPRESSED (constraint-backed; created implicitly by SECTION 20). Verbatim from src: 30:22-79.
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX audit_logs_pkey ON public.audit_logs USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX child_contact_ids_contact_id_key ON public.child_contact_ids USING btree (contact_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX child_contact_ids_pkey ON public.child_contact_ids USING btree (child_user_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_apps_device_package_key ON public.device_apps USING btree (device_id, package_name);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_apps_pkey ON public.device_apps USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_commands_device_idempotency_key ON public.device_commands USING btree (device_id, idempotency_key);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_commands_pkey ON public.device_commands USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_pairing_tokens_code_hash_key ON public.device_pairing_tokens USING btree (code_hash);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_pairing_tokens_pkey ON public.device_pairing_tokens USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_policies_device_version_key ON public.device_policies USING btree (device_id, version);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX device_policies_pkey ON public.device_policies USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX devices_family_installation_key ON public.devices USING btree (family_id, installation_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX devices_pkey ON public.devices USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX families_pkey ON public.families USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX family_members_family_user_key ON public.family_members USING btree (family_id, user_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX family_members_pkey ON public.family_members USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX location_events_pkey ON public.location_events USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX pairing_attempts_pkey ON public.pairing_attempts USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX pairing_requests_pkey ON public.pairing_requests USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX pairing_requests_token_id_key ON public.pairing_requests USING btree (token_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX remote_sessions_pkey ON public.remote_sessions USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX safe_zone_states_pkey ON public.safe_zone_states USING btree (zone_id, device_id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX safe_zones_pkey ON public.safe_zones USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX safety_alerts_pkey ON public.safety_alerts USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX usage_daily_device_day_package_key ON public.usage_daily USING btree (device_id, day, package_name);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX usage_daily_pkey ON public.usage_daily USING btree (id);
--   (constraint-backed, DO NOT EMIT) CREATE UNIQUE INDEX webrtc_signals_pkey ON public.webrtc_signals USING btree (id);

-- ============================================================================
-- SECTION 40 -- FUNCTIONS  (0 ACTIVE STATEMENTS -- NON-EXECUTING BY EVIDENCE)
-- ============================================================================
-- NOT EXECUTING, AND NOT REPAIRABLE OFFLINE. The approved evidence contains NO return type for ANY
-- of the 38 functions (src: 40:14-21): g1-q7 supplies language/volatility/owner/settings/acl for
-- 18 rows and selects no prorettype; g1-b3b supplies schema_name, proname, argument strings,
-- security_definer, settings, acl and 14 raw prosrc bodies -- and also no prorettype. A key scan
-- of every evidence JSON finds no prorettype / return_type / rettype / returns field at all
-- (docs/stage2/S2-A3-database-audit.md:189-192). A CREATE FUNCTION with an invented return type or
-- an invented body is forbidden by the brief, so this section emits NOTHING. The 14 preserved
-- bodies stay as comments in the source artefact only (src: 40 whole file); they are not copied here.
--
-- THE 9 FUNCTIONS THAT GATE THE SECURITY LAYER (this load needs none of them, but the 17 commented
-- policies in SECTION 6 and all 8 triggers in SECTION 5/5b need exactly these 9):
--   private.is_family_parent(p_family_id uuid)              -- src: 40:215; return type NOT PRESENT IN EVIDENCE (src: 40:217)
--   private.is_family_member(p_family_id uuid)              -- src: 40:192; return type NOT PRESENT IN EVIDENCE (src: 40:194)
--   private.shares_active_family(p_user_id uuid)            -- src: 40:473; return type NOT PRESENT IN EVIDENCE (src: 40:475)
--   private.set_updated_at()                                 -- src: 40:455; return type NOT PRESENT IN EVIDENCE (src: 40:457)
--   private.audit_logs_append_only()                         -- src: 40:36;  return type NOT PRESENT IN EVIDENCE (src: 40:38)
--   private.families_before_update()                         -- src: 40:135; return type NOT PRESENT IN EVIDENCE (src: 40:137)
--   private.profiles_before_update()                         -- src: 40:251; return type NOT PRESENT IN EVIDENCE (src: 40:253)
--   private.remote_session_transition_guard()                -- src: 40:337; return type NOT PRESENT IN EVIDENCE (src: 40:339)
--   private.handle_new_user()                                -- src: 40:159; return type NOT PRESENT IN EVIDENCE (src: 40:161)
-- 9 return types. That single gap is the whole behavioural ceiling of this load (S2-EXEC-04 H-2).
-- NOTE (S2-EXEC-04 L-4): private.remote_session_transition_guard is captured with acl=(null), i.e.
-- default PUBLIC EXECUTE, and g1-q6/g1-b3b show execute grants anon=True. Any future authored DDL
-- must decide deliberately whether to REVOKE ... FROM PUBLIC; that is an A-window authoring item.

-- ============================================================================
-- SECTION 50 -- TRIGGERS ON PUBLIC TABLES  (0 ACTIVE STATEMENTS -- NON-EXECUTING)
-- ============================================================================
-- NOT EXECUTING: each trigger EXECUTEs one of the 9 private.* functions above, so an active
-- CREATE TRIGGER would fail 42883 "function does not exist" (S2-EXEC-04 H-2; src: 50:14-16).
-- Definitions below are verbatim from src: 50:18-37 -- ev: g1-q3 rows (trigger_name, definition,
-- function_name, security_definer, enabled_flag) -- 7 rows, all enabled_flag=O, all BEFORE.
--   (BLOCKED ON SECTION 40) CREATE TRIGGER audit_logs_append_only BEFORE DELETE OR UPDATE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION private.audit_logs_append_only();
--     ev: g1-q3 (function_name=audit_logs_append_only, security_definer=False, enabled_flag=O) | src: 50:18-19
--   (BLOCKED ON SECTION 40) CREATE TRIGGER devices_set_updated_at BEFORE UPDATE ON public.devices FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();
--     ev: g1-q3 (set_updated_at, False, O) | src: 50:21-22
--   (BLOCKED ON SECTION 40) CREATE TRIGGER families_before_update BEFORE UPDATE ON public.families FOR EACH ROW EXECUTE FUNCTION private.families_before_update();
--     ev: g1-q3 (families_before_update, False, O) | src: 50:24-25
--   (BLOCKED ON SECTION 40) CREATE TRIGGER families_set_updated_at BEFORE UPDATE ON public.families FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();
--     ev: g1-q3 (set_updated_at, False, O) | src: 50:27-28
--   (BLOCKED ON SECTION 40) CREATE TRIGGER profiles_before_update BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION private.profiles_before_update();
--     ev: g1-q3 (profiles_before_update, False, O) | src: 50:30-31
--   (BLOCKED ON SECTION 40) CREATE TRIGGER remote_sessions_transition_guard BEFORE UPDATE OF status ON public.remote_sessions FOR EACH ROW EXECUTE FUNCTION private.remote_session_transition_guard();
--     ev: g1-q3 (remote_session_transition_guard, security_definer=True, O) | src: 50:33-34
--   (BLOCKED ON SECTION 40) CREATE TRIGGER safe_zone_states_set_updated_at BEFORE UPDATE ON public.safe_zone_states FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();
--     ev: g1-q3 (set_updated_at, False, O) | src: 50:36-37
-- Consequence to state plainly: with 0 active triggers there is NO append-only guard on audit_logs,
-- NO set_updated_at maintenance, NO families/profiles before-update protection and NO
-- remote_sessions status-transition guard.

-- ============================================================================
-- SECTION 55 -- THE auth.users TRIGGER  (0 ACTIVE STATEMENTS -- NON-EXECUTING, AND NOT PART OF THE
--                                         ASSEMBLED SOURCE EITHER)
-- ============================================================================
-- NOT EXECUTING. Two independent reasons:
--   (a) it calls private.handle_new_user, whose return type is NOT PRESENT IN EVIDENCE (src: 40:159, :161);
--   (b) it is a user-defined trigger ON the platform-managed auth schema, which the source keeps in
--       its own component and physically EXCLUDES from the assembled artefact this file derives from
--       (S2-EXEC-04 I-3: grep on_auth_user_created in g3-reconstruction-2026-11-02.sql -> 0 hits;
--        src: 55:14-18 explains the isolation).
--   (BLOCKED - DO NOT APPLY) CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.handle_new_user();
--     ev: g1-q3b (table_schema/table_name, trigger_name, definition, function_schema=private,
--                 function_name=handle_new_user, security_definer=True, enabled_flag=O,
--                 function_settings=search_path=public, private, pg_temp) | src: 55:20-21
-- Consequence to state plainly: signup creates NO profiles row on this staging database. Any app
-- flow that assumes the handle_new_user provisioning path will fail silently, not loudly.
-- Applying it also requires a separate owner decision beyond A3 (platform-schema object).

-- ============================================================================
-- SECTION 60 -- ROW LEVEL SECURITY  (19 ACTIVE STATEMENTS + 4 ACTIVE POLICIES + 17 COMMENTED)
-- ============================================================================
-- ev: g1-q1.rls_enabled = true for all 19 rows, rls_forced = false for all 19 rows -- so exactly
-- 19 ENABLE and ZERO FORCE ROW LEVEL SECURITY are emitted (S2-EXEC-04 check 8; src: 60:15).
-- service_role and the owner role are therefore NOT subject to FORCE, matching production.

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;          -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:19
ALTER TABLE public.child_contact_ids ENABLE ROW LEVEL SECURITY;   -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:20
ALTER TABLE public.device_apps ENABLE ROW LEVEL SECURITY;         -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:21
ALTER TABLE public.device_commands ENABLE ROW LEVEL SECURITY;     -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:22
ALTER TABLE public.device_pairing_tokens ENABLE ROW LEVEL SECURITY; -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:23
ALTER TABLE public.device_policies ENABLE ROW LEVEL SECURITY;     -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:24
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;             -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:25
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;            -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:26
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;      -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:27
ALTER TABLE public.location_events ENABLE ROW LEVEL SECURITY;     -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:28
ALTER TABLE public.pairing_attempts ENABLE ROW LEVEL SECURITY;    -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:29
ALTER TABLE public.pairing_requests ENABLE ROW LEVEL SECURITY;    -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:30
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;            -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:31
ALTER TABLE public.remote_sessions ENABLE ROW LEVEL SECURITY;     -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:32
ALTER TABLE public.safe_zone_states ENABLE ROW LEVEL SECURITY;    -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:33
ALTER TABLE public.safe_zones ENABLE ROW LEVEL SECURITY;          -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:34
ALTER TABLE public.safety_alerts ENABLE ROW LEVEL SECURITY;       -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:35
ALTER TABLE public.usage_daily ENABLE ROW LEVEL SECURITY;         -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:36
ALTER TABLE public.webrtc_signals ENABLE ROW LEVEL SECURITY;      -- ev: g1-q1.rls_enabled=true, rls_forced=false | src: 60:37

-- ---- ACTIVE POLICIES (4 of the 21 captured) -- deviation D-6, closes H-1's aggravating sub-finding
-- S2-EXEC-04 H-1 (:42) measured that exactly 4 of the 21 policies "reference ONLY auth.uid() and
-- plain SQL" and were batch-suppressed with the 17 that need private.*. Re-derived independently
-- here from g1-q2: 17/21 predicates contain 'private.', 4/21 contain none. These 4 are therefore the
-- ONLY behaviour restorable offline, and are emitted ACTIVE with the captured predicate text
-- verbatim (g1-q2.qual / g1-q2.with_check, whitespace reflowed onto one line only -- no token
-- changed). Their privilege reachability is evidenced in SECTION 7: families UPDATE (name, settings),
-- profiles UPDATE (display_name), webrtc_signals INSERT+SELECT are granted to authenticated
-- (g1-q6.update_column_grants, g1-q6.table_grants).
--
-- M-3 REPAIR (deviation D-3): webrtc_signals_insert_participant is an INSERT policy whose captured
-- g1-q2.qual is null. The source rendered that as the literal text "USING (None)" (src: 60:71), which
-- is invalid SQL if ever uncommented. The evidence row, verbatim from g1-q2-20261029.json:
--   {"tablename":"webrtc_signals","policyname":"webrtc_signals_insert_participant","permissive":"PERMISSIVE",
--    "cmd":"INSERT","roles":"authenticated","qual":null,
--    "with_check":"((from_user_id = auth.uid()) AND (EXISTS ( SELECT 1 FROM remote_sessions s WHERE ...))))"}
-- i.e. "qual":null. PostgreSQL has no USING clause on that production policy, so the correct
-- rendering is to OMIT the USING clause entirely -- which is what is emitted below, and what is done
-- for the second null-qual row (safe_zones_insert_parent, g1-q2 row: "cmd":"INSERT","qual":null --
-- src: 60:62), which stays commented because its WITH CHECK calls private.is_family_parent.

CREATE POLICY families_update_owner ON public.families AS PERMISSIVE FOR UPDATE TO authenticated
    USING ((owner_id = auth.uid()) AND (deleted_at IS NULL))
    WITH CHECK ((owner_id = auth.uid()));
    -- ev: g1-q2 row tablename=families, policyname=families_update_owner, cmd=UPDATE,
    --     roles=authenticated, permissive=PERMISSIVE,
    --     qual="((owner_id = auth.uid()) AND (deleted_at IS NULL))",
    --     with_check="(owner_id = auth.uid())"  [verbatim] | source rendering: src: 60:52

CREATE POLICY profiles_update_self ON public.profiles AS PERMISSIVE FOR UPDATE TO authenticated
    USING ((id = auth.uid()))
    WITH CHECK ((id = auth.uid()));
    -- ev: g1-q2 row tablename=profiles, policyname=profiles_update_self, cmd=UPDATE,
    --     roles=authenticated, permissive=PERMISSIVE, qual="(id = auth.uid())",
    --     with_check="(id = auth.uid())"  [verbatim] | source rendering: src: 60:59

CREATE POLICY webrtc_signals_insert_participant ON public.webrtc_signals AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (((from_user_id = auth.uid()) AND (EXISTS ( SELECT 1 FROM remote_sessions s WHERE ((s.id = webrtc_signals.session_id) AND (s.status = ANY (ARRAY['accepted'::text, 'active'::text])) AND ((s.parent_user_id = auth.uid()) OR (s.child_user_id = auth.uid())))))));
    -- ev: g1-q2 row tablename=webrtc_signals, policyname=webrtc_signals_insert_participant, cmd=INSERT,
    --     roles=authenticated, permissive=PERMISSIVE, qual=null -> NO USING CLAUSE (M-3 repair, D-3),
    --     with_check quoted verbatim above | source rendering (defective): src: 60:71-73
    -- NOTE (deviation D-10): "FROM remote_sessions s" is UNQUALIFIED because that is the byte-exact
    --     pg_get_expr output captured in g1-q2 and the brief requires these predicates verbatim. The
    --     range table is bound at CREATE POLICY time through the loading session's search_path; on
    --     the Supabase dashboard the loader is postgres with the default "$user", public path, so it
    --     binds to public.remote_sessions. If the operator runs the batch with a nonstandard
    --     search_path, this is the one statement class where that matters.

CREATE POLICY webrtc_signals_select_participant ON public.webrtc_signals AS PERMISSIVE FOR SELECT TO authenticated
    USING ((EXISTS ( SELECT 1 FROM remote_sessions s WHERE ((s.id = webrtc_signals.session_id) AND (s.status = ANY (ARRAY['accepted'::text, 'active'::text])) AND ((s.parent_user_id = auth.uid()) OR (s.child_user_id = auth.uid())))))) ;
    -- ev: g1-q2 row tablename=webrtc_signals, policyname=webrtc_signals_select_participant, cmd=SELECT,
    --     roles=authenticated, permissive=PERMISSIVE,
    --     qual="(EXISTS ( SELECT 1 FROM remote_sessions s WHERE (...)))" [verbatim], with_check=null
    --     | source rendering: src: 60:74-76. Same unqualified-range-note as D-10 above.

-- ---- COMMENTED POLICIES (17 of the 21 captured). Each names its exact blocker. ----
-- BLOCKER, uniformly: the predicate calls a private.* helper whose prorettype is NOT PRESENT IN
-- EVIDENCE, so the function does not exist and the policy cannot be created or validated.
-- 3 of the 9 helpers carry the entire policy layer: is_family_parent (10 policies),
-- is_family_member (3), shares_active_family (1), plus 3 that combine with them (audit_logs needs
-- the IS NOT NULL guard plus is_family_parent). Keep commented until a return-type capture lands.
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY audit_logs_select_family_parent ON public.audit_logs AS PERMISSIVE FOR SELECT TO authenticated USING (((family_id IS NOT NULL) AND private.is_family_parent(family_id)));   -- ev: g1-q2 row policyname=audit_logs_select_family_parent, cmd=SELECT, roles=authenticated | src: 60:40
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY device_apps_select_parent_or_child ON public.device_apps AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = device_apps.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=device_apps_select_parent_or_child) | src: 60:41-43
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY device_commands_select_parent_or_child ON public.device_commands AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = device_commands.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=device_commands_select_parent_or_child) | src: 60:44-46
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY device_policies_select_parent_or_child ON public.device_policies AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = device_policies.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=device_policies_select_parent_or_child) | src: 60:47-49
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY devices_select_parent_or_child ON public.devices AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (child_user_id = auth.uid())));   -- ev: g1-q2 (policyname=devices_select_parent_or_child) | src: 60:50
--     REACHABILITY NOTE (NOT A DEFECT, DO NOT "FIX" BY INVENTING A GRANT): this is one of exactly 2
--     of 21 policies unreachable for its named role, because g1-q6.table_grants holds NO
--     (devices, authenticated, *) row and g1-q1.table_acl for devices is
--     "postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres" -- authenticated gets nothing, so
--     the privilege check denies before RLS is consulted. That is faithful to production; recorded
--     so a later parity diff does not mistake it for a load failure.
--   (BLOCKED: missing prorettype for private.is_family_member -- src: 40:194) CREATE POLICY families_select_members ON public.families AS PERMISSIVE FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND private.is_family_member(id)));   -- ev: g1-q2 (policyname=families_select_members) | src: 60:51
--   (BLOCKED: missing prorettype for private.is_family_member -- src: 40:194) CREATE POLICY family_members_select_family ON public.family_members AS PERMISSIVE FOR SELECT TO authenticated USING (private.is_family_member(family_id));   -- ev: g1-q2 (policyname=family_members_select_family) | src: 60:53
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY location_events_select_parent_or_child ON public.location_events AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = location_events.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=location_events_select_parent_or_child) | src: 60:54-56
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY pairing_requests_select_participants ON public.pairing_requests AS PERMISSIVE FOR SELECT TO authenticated USING (((child_user_id = auth.uid()) OR (parent_user_id = auth.uid()) OR private.is_family_parent(family_id)));   -- ev: g1-q2 (policyname=pairing_requests_select_participants) | src: 60:57
--   (BLOCKED: missing prorettype for private.shares_active_family -- src: 40:475) CREATE POLICY profiles_select_self_or_family ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING (((id = auth.uid()) OR private.shares_active_family(id)));   -- ev: g1-q2 (policyname=profiles_select_self_or_family) | src: 60:58
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY remote_sessions_select_participants ON public.remote_sessions AS PERMISSIVE FOR SELECT TO authenticated USING (((parent_user_id = auth.uid()) OR (child_user_id = auth.uid()) OR private.is_family_parent(family_id)));   -- ev: g1-q2 (policyname=remote_sessions_select_participants) | src: 60:60
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY safe_zones_delete_parent ON public.safe_zones AS PERMISSIVE FOR DELETE TO authenticated USING (private.is_family_parent(family_id));   -- ev: g1-q2 (policyname=safe_zones_delete_parent, cmd=DELETE) | src: 60:61
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217; USING CLAUSE OMITTED per M-3 repair, D-3, because the g1-q2 row reads "cmd":"INSERT","qual":null) CREATE POLICY safe_zones_insert_parent ON public.safe_zones AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (private.is_family_parent(family_id));   -- ev: g1-q2 (policyname=safe_zones_insert_parent) | src: 60:62
--     REACHABILITY NOTE (NOT A DEFECT, DO NOT "FIX" BY INVENTING A GRANT): the 2nd of the 2
--     unreachable policies -- g1-q6.table_grants has no (safe_zones, authenticated, INSERT) row and
--     g1-q1.table_acl reads "authenticated=rd/postgres" (SELECT+DELETE only). Source artefact
--     rendered this as the invalid "USING (None)"; repaired here, still blocked on SECTION 40.
--   (BLOCKED: missing prorettype for private.is_family_member -- src: 40:194) CREATE POLICY safe_zones_select_family ON public.safe_zones AS PERMISSIVE FOR SELECT TO authenticated USING (private.is_family_member(family_id));   -- ev: g1-q2 (policyname=safe_zones_select_family) | src: 60:63
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY safe_zones_update_parent ON public.safe_zones AS PERMISSIVE FOR UPDATE TO authenticated USING (private.is_family_parent(family_id)) WITH CHECK (private.is_family_parent(family_id));   -- ev: g1-q2 (policyname=safe_zones_update_parent) | src: 60:64
--     (reachable once the blocker clears: g1-q6.update_column_grants grants authenticated UPDATE on
--      safe_zones.active/lat/lng/name/radius_m -- src: 70:250, 255-258.)
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY safety_alerts_select_parent_or_child ON public.safety_alerts AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = safety_alerts.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=safety_alerts_select_parent_or_child) | src: 60:65-67
--   (BLOCKED: missing prorettype for private.is_family_parent -- src: 40:217) CREATE POLICY usage_daily_select_parent_or_child ON public.usage_daily AS PERMISSIVE FOR SELECT TO authenticated USING ((private.is_family_parent(family_id) OR (EXISTS ( SELECT 1 FROM devices d WHERE ((d.id = usage_daily.device_id) AND (d.child_user_id = auth.uid()))))));   -- ev: g1-q2 (policyname=usage_daily_select_parent_or_child) | src: 60:68-70

-- *** READ THIS BEFORE DECLARING THE LOADED DATABASE USABLE ***
-- Loading the 4 policies above restores ONLY: parent-owned family row UPDATE, self profile UPDATE,
-- and webrtc_signal INSERT/SELECT for an accepted-or-active session participant. Everything else is
-- still denied. With only these 4 loaded, 17 of the 21 captured policies and 8 of the 8 captured
-- triggers (7 on public tables + 1 on auth.users) remain BLOCKED on the 9 missing function return
-- types listed in SECTION 40. The 19 RLS ENABLEs above are deny-all for their 15 SELECT-exposed
-- tables, so authenticated reads return 0 rows and every ungranted write fails 42501 (S2-EXEC-04
-- H-1). This file therefore produces a STRUCTURALLY faithful shell that is NOT application-ready,
-- and no count in SECTION 10 should be read as saying otherwise.

-- ============================================================================
-- SECTION 80 -- REALTIME PUBLICATION  (0 ACTIVE STATEMENTS -- NON-EXECUTING)
-- ============================================================================
-- NOT EXECUTING, and it is NOT in the source artefact's active set either. NOT PRESENT IN
-- EVIDENCE: the G1 series captured no pg_publication / pg_publication_tables query, so production's
-- publication membership is UNKNOWN and cannot be reconstructed (src: 80:14-15). The four-table
-- requirement below is DOCUMENTARY (INFERRED FROM DOCUMENTATION -- src: 80:16-18 cites
-- docs/stage2/01-staging-project-proposal.md:61 and approval-package-v2 3.3(b)) and the owner's
-- Sequence A decision runs it AFTER this load, under A2'(b), not under A3.
--   (AFTER A3, UNDER A2'(b), NOT EMITTED) ALTER PUBLICATION supabase_realtime ADD TABLE public.device_commands;
--   (AFTER A3, UNDER A2'(b), NOT EMITTED) ALTER PUBLICATION supabase_realtime ADD TABLE public.remote_sessions;
--   (AFTER A3, UNDER A2'(b), NOT EMITTED) ALTER PUBLICATION supabase_realtime ADD TABLE public.safety_alerts;
--   (AFTER A3, UNDER A2'(b), NOT EMITTED) ALTER PUBLICATION supabase_realtime ADD TABLE public.webrtc_signals;
-- Consequence: Realtime delivers nothing on this database after the load. Client WS subscriptions
-- must be treated as unavailable in staging until A2'(b) executes.

-- ============================================================================
-- SECTION 70 -- OBJECT GRANTS  (236 ACTIVE STATEMENTS: 1 schema USAGE + 52 table + 183 column)
-- ============================================================================
-- Two independent sources describe the same ACL and they do NOT agree, so BOTH are used and the
-- difference is shown instead of hidden (src: 70:14-25):
--   * g1-q6.table_grants       -- 149 aclexplode rows; grantees authenticated, service_role ONLY;
--                                  privileges within DELETE, INSERT, REFERENCES, SELECT, TRIGGER,
--                                  TRUNCATE, UPDATE; is_grantable='NO' on every row.
--   * g1-q1.table_acl (acltext) -- additionally shows explicit postgres grants and the PG17
--                                  MAINTAIN privilege (letter 'm'), which the q6 query did not return.
-- Rule carried over unchanged (src: 70:19-22): privileges to APPLICATION roles are EMITTED;
--   privileges whose grantee is a PLATFORM-MANAGED role (postgres), or whose object lives in a
--   PLATFORM-MANAGED schema, are RECORDED AS COMMENTS and not emitted. Nothing is dropped silently:
--   the 19 q1-only postgres triples and the 57 commented default-privilege rows are reproduced below.
-- Because is_grantable='NO' on all 149 rows, NO 'WITH GRANT OPTION' is emitted anywhere (verified:
--   S2-EXEC-04 check 7 -- 0 WITH GRANT OPTION, 0 REVOKE in active statements). The 191 column rows
--   carry no is_grantable field at all, so absence of a grant option there is an ASSUMPTION, not a
--   verified fact (src: 70:24-25) -- preserved as such.
-- Counts: 52 table-level statements covering 168 distinct (table,grantee,privilege) triples
--   (149 q6 + 19 q1 MAINTAIN) with no duplicate triple; 183 column statements covering 191 distinct
--   (table,column,grantee) triples (src: 70:359-361).

-- ---- M-4 REPAIR (deviation D-5): the schema-level USAGE grant the evidence records but the source
-- ---- artefact never emitted. S2-EXEC-04 M-4 (:67-68) measured that section 70 contains no
-- ---- "GRANT ... ON SCHEMA" statement of any kind, although the capture proves the privilege exists.
-- ---- EXACT EVIDENCE FIELD: g1-b3b-20261029.json  ->  "schema_usage" object
-- ----   { "note": "has_schema_privilege on schema private",
-- ----     "anon": false, "authenticated": true, "service_role": true }
-- ---- i.e. schema_usage.authenticated = true (g1-b3b-20261029.json:14-19), transcribed at
-- ---- src: 00:45 ("schema USAGE on private: anon=False authenticated=True service_role=True").
-- WHY IT MATTERS: without it the private schema is created but usable only by the owner, so when
-- SECTION 40 functions are eventually authored, an authenticated policy calling
-- private.is_family_parent(...) fails 10503 "permission denied for schema private" -- re-blocking the
-- policy layer for a reason that IS evidenced. Emitting it now costs nothing and cannot diverge from
-- production, because production already has it.
GRANT USAGE ON SCHEMA private TO authenticated;   -- ev g1-b3b.schema_usage.authenticated=true (g1-b3b-20261029.json:17) | src: none (M-4 omission repaired, D-5)
-- COMPANION ROW, DELIBERATELY NOT EMITTED: g1-b3b.schema_usage.service_role is also true. It is not
-- part of the authorised deviation set for this file, so it is recorded here for the A3 sign-off to
-- decide, not invented. (service_role bypasses RLS and holds table ALL PRIVILEGES via the grants
-- below, so its absence does not change any behaviour this load can produce.)
-- g1-b3b.schema_usage.anon = false -> NO anon USAGE statement, correctly, and no anon table grants
-- exist in g1-q6.table_grants either (S2-EXEC-04 H-1: anon is denied at the privilege check in
-- production too; the load is faithful, not broken).

-- ---- TABLE-LEVEL GRANTS from g1-q6.table_grants (33 statements) ----
GRANT SELECT ON TABLE public.audit_logs TO authenticated;                                    -- ev g1-q6.table_grants[grantee=authenticated] | src 70:27
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.audit_logs TO service_role;   -- ev g1-q6.table_grants[grantee=service_role] | src 70:28
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.child_contact_ids TO service_role;   -- ev g1-q6.table_grants | src 70:29
GRANT SELECT ON TABLE public.device_apps TO authenticated;                                   -- ev g1-q6.table_grants | src 70:30
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_apps TO service_role;   -- ev g1-q6.table_grants | src 70:31
GRANT SELECT ON TABLE public.device_commands TO authenticated;                               -- ev g1-q6.table_grants | src 70:32
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_commands TO service_role;   -- ev g1-q6.table_grants | src 70:33
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_pairing_tokens TO service_role;   -- ev g1-q6.table_grants | src 70:34
GRANT SELECT ON TABLE public.device_policies TO authenticated;                               -- ev g1-q6.table_grants | src 70:35
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_policies TO service_role;   -- ev g1-q6.table_grants | src 70:36
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.devices TO service_role;   -- ev g1-q6.table_grants | src 70:37
GRANT SELECT ON TABLE public.families TO authenticated;                                      -- ev g1-q6.table_grants | src 70:38
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.families TO service_role;   -- ev g1-q6.table_grants | src 70:39
GRANT SELECT ON TABLE public.family_members TO authenticated;                                -- ev g1-q6.table_grants | src 70:40
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_members TO service_role;   -- ev g1-q6.table_grants | src 70:41
GRANT SELECT ON TABLE public.location_events TO authenticated;                               -- ev g1-q6.table_grants | src 70:42
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.location_events TO service_role;   -- ev g1-q6.table_grants | src 70:43
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.pairing_attempts TO service_role;   -- ev g1-q6.table_grants | src 70:44
GRANT SELECT ON TABLE public.pairing_requests TO authenticated;                              -- ev g1-q6.table_grants | src 70:45
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.pairing_requests TO service_role;   -- ev g1-q6.table_grants | src 70:46
GRANT SELECT ON TABLE public.profiles TO authenticated;                                      -- ev g1-q6.table_grants | src 70:47
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profiles TO service_role;   -- ev g1-q6.table_grants | src 70:48
GRANT SELECT ON TABLE public.remote_sessions TO authenticated;                               -- ev g1-q6.table_grants | src 70:49
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.remote_sessions TO service_role;   -- ev g1-q6.table_grants | src 70:50
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safe_zone_states TO service_role;   -- ev g1-q6.table_grants | src 70:51
GRANT DELETE, SELECT ON TABLE public.safe_zones TO authenticated;                           -- ev g1-q6.table_grants (grantee=authenticated: SELECT+DELETE, NO INSERT -> see safe_zones_insert_parent reachability note) | src 70:52
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safe_zones TO service_role;   -- ev g1-q6.table_grants | src 70:53
GRANT SELECT ON TABLE public.safety_alerts TO authenticated;                                 -- ev g1-q6.table_grants | src 70:54
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safety_alerts TO service_role;   -- ev g1-q6.table_grants | src 70:55
GRANT SELECT ON TABLE public.usage_daily TO authenticated;                                   -- ev g1-q6.table_grants | src 70:56
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.usage_daily TO service_role;   -- ev g1-q6.table_grants | src 70:57
GRANT INSERT, SELECT ON TABLE public.webrtc_signals TO authenticated;                       -- ev g1-q6.table_grants (supports the 2 active webrtc policies) | src 70:58
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.webrtc_signals TO service_role;   -- ev g1-q6.table_grants | src 70:59

-- ---- TABLE-LEVEL GRANTS from the g1-q1.table_acl delta only (19 MAINTAIN statements) ----
-- These 19 triples are present in acltext (letter 'm') and absent from g1-q6; they are emitted
-- because the grantee is the application role service_role, not a platform role (src: 70:61-81).
GRANT MAINTAIN ON TABLE public.audit_logs TO service_role;            -- ev g1-q1.table_acl[acltext letter m] (not g1-q6) | src 70:63
GRANT MAINTAIN ON TABLE public.child_contact_ids TO service_role;     -- ev g1-q1.table_acl[m] | src 70:64
GRANT MAINTAIN ON TABLE public.device_apps TO service_role;           -- ev g1-q1.table_acl[m] | src 70:65
GRANT MAINTAIN ON TABLE public.device_commands TO service_role;       -- ev g1-q1.table_acl[m] | src 70:66
GRANT MAINTAIN ON TABLE public.device_pairing_tokens TO service_role; -- ev g1-q1.table_acl[m] | src 70:67
GRANT MAINTAIN ON TABLE public.device_policies TO service_role;       -- ev g1-q1.table_acl[m] | src 70:68
GRANT MAINTAIN ON TABLE public.devices TO service_role;               -- ev g1-q1.table_acl[m] | src 70:69
GRANT MAINTAIN ON TABLE public.families TO service_role;              -- ev g1-q1.table_acl[m] | src 70:70
GRANT MAINTAIN ON TABLE public.family_members TO service_role;        -- ev g1-q1.table_acl[m] | src 70:71
GRANT MAINTAIN ON TABLE public.location_events TO service_role;       -- ev g1-q1.table_acl[m] | src 70:72
GRANT MAINTAIN ON TABLE public.pairing_attempts TO service_role;      -- ev g1-q1.table_acl[m] | src 70:73
GRANT MAINTAIN ON TABLE public.pairing_requests TO service_role;      -- ev g1-q1.table_acl[m] | src 70:74
GRANT MAINTAIN ON TABLE public.profiles TO service_role;              -- ev g1-q1.table_acl[m] | src 70:75
GRANT MAINTAIN ON TABLE public.remote_sessions TO service_role;       -- ev g1-q1.table_acl[m] | src 70:76
GRANT MAINTAIN ON TABLE public.safe_zone_states TO service_role;      -- ev g1-q1.table_acl[m] | src 70:77
GRANT MAINTAIN ON TABLE public.safe_zones TO service_role;            -- ev g1-q1.table_acl[m] | src 70:78
GRANT MAINTAIN ON TABLE public.safety_alerts TO service_role;         -- ev g1-q1.table_acl[m] | src 70:79
GRANT MAINTAIN ON TABLE public.usage_daily TO service_role;           -- ev g1-q1.table_acl[m] | src 70:80
GRANT MAINTAIN ON TABLE public.webrtc_signals TO service_role;        -- ev g1-q1.table_acl[m] | src 70:81

-- ---- COLUMN-LEVEL UPDATE GRANTS (183 statements / 191 (table,column,grantee) triples) ----
-- ev per statement: g1-q6.update_column_grants rows (table_name, column_name, grantee, privilege_type).
-- Statements tagged "TO authenticated, service_role" carry 2 triples each; 175 carry 1 -> 191 total.
GRANT UPDATE (actor_user_id) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:103
GRANT UPDATE (created_at) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:104
GRANT UPDATE (device_id) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:105
GRANT UPDATE (event_type) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:106
GRANT UPDATE (family_id) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:107
GRANT UPDATE (id) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:108
GRANT UPDATE (metadata) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:109
GRANT UPDATE (target_id) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:110
GRANT UPDATE (target_type) ON public.audit_logs TO service_role;   -- ev g1-q6.update_column_grants | src 70:111
GRANT UPDATE (child_user_id) ON public.child_contact_ids TO service_role;   -- ev g1-q6.update_column_grants | src 70:112
GRANT UPDATE (contact_id) ON public.child_contact_ids TO service_role;   -- ev g1-q6.update_column_grants | src 70:113
GRANT UPDATE (created_at) ON public.child_contact_ids TO service_role;   -- ev g1-q6.update_column_grants | src 70:114
GRANT UPDATE (rotated_at) ON public.child_contact_ids TO service_role;   -- ev g1-q6.update_column_grants | src 70:115
GRANT UPDATE (device_id) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:116
GRANT UPDATE (family_id) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:117
GRANT UPDATE (id) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:118
GRANT UPDATE (is_suspended) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:119
GRANT UPDATE (is_system) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:120
GRANT UPDATE (label) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:121
GRANT UPDATE (package_name) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:122
GRANT UPDATE (reported_at) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:123
GRANT UPDATE (version_name) ON public.device_apps TO service_role;   -- ev g1-q6.update_column_grants | src 70:124
GRANT UPDATE (acked_at) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:125
GRANT UPDATE (attempts) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:126
GRANT UPDATE (created_at) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:127
GRANT UPDATE (created_by) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:128
GRANT UPDATE (delivered_at) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:129
GRANT UPDATE (device_id) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:130
GRANT UPDATE (error_message) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:131
GRANT UPDATE (expires_at) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:132
GRANT UPDATE (family_id) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:133
GRANT UPDATE (id) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:134
GRANT UPDATE (idempotency_key) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:135
GRANT UPDATE (payload) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:136
GRANT UPDATE (result) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:137
GRANT UPDATE (status) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:138
GRANT UPDATE (type) ON public.device_commands TO service_role;   -- ev g1-q6.update_column_grants | src 70:139
GRANT UPDATE (attempts) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:140
GRANT UPDATE (child_user_id) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:141
GRANT UPDATE (code_hash) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:142
GRANT UPDATE (created_at) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:143
GRANT UPDATE (created_by) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:144
GRANT UPDATE (expires_at) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:145
GRANT UPDATE (id) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:146
GRANT UPDATE (max_attempts) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:147
GRANT UPDATE (purpose) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:148
GRANT UPDATE (redeemed_at) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:149
GRANT UPDATE (redeemed_by) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:150
GRANT UPDATE (status) ON public.device_pairing_tokens TO service_role;   -- ev g1-q6.update_column_grants | src 70:151
GRANT UPDATE (acknowledged_at) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:152
GRANT UPDATE (created_at) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:153
GRANT UPDATE (created_by) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:154
GRANT UPDATE (device_id) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:155
GRANT UPDATE (enforcement_status) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:156
GRANT UPDATE (family_id) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:157
GRANT UPDATE (id) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:158
GRANT UPDATE (last_error) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:159
GRANT UPDATE (policy) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:160
GRANT UPDATE (version) ON public.device_policies TO service_role;   -- ev g1-q6.update_column_grants | src 70:161
GRANT UPDATE (android_version) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:162
GRANT UPDATE (app_version) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:163
GRANT UPDATE (background_location_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:164
GRANT UPDATE (battery_level) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:165
GRANT UPDATE (camera_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:166
GRANT UPDATE (child_user_id) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:167
GRANT UPDATE (created_at) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:168
GRANT UPDATE (credential_issued_at) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:169
GRANT UPDATE (credential_revoked_at) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:170
GRANT UPDATE (display_name) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:171
GRANT UPDATE (enforcement_mode) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:172
GRANT UPDATE (family_id) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:173
GRANT UPDATE (id) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:174
GRANT UPDATE (installation_id) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:175
GRANT UPDATE (is_charging) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:176
GRANT UPDATE (last_seen_at) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:177
GRANT UPDATE (location_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:178
GRANT UPDATE (microphone_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:179
GRANT UPDATE (notifications_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:180
GRANT UPDATE (platform) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:181
GRANT UPDATE (policy_version) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:182
GRANT UPDATE (secret_hash) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:183
GRANT UPDATE (status) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:184
GRANT UPDATE (updated_at) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:185
GRANT UPDATE (usage_access_granted) ON public.devices TO service_role;   -- ev g1-q6.update_column_grants | src 70:186
GRANT UPDATE (created_at) ON public.families TO service_role;   -- ev g1-q6.update_column_grants | src 70:187
GRANT UPDATE (deleted_at) ON public.families TO service_role;   -- ev g1-q6.update_column_grants | src 70:188
GRANT UPDATE (id) ON public.families TO service_role;   -- ev g1-q6.update_column_grants | src 70:189
GRANT UPDATE (name) ON public.families TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) -- makes families_update_owner reachable | src 70:190
GRANT UPDATE (owner_id) ON public.families TO service_role;   -- ev g1-q6.update_column_grants | src 70:191
GRANT UPDATE (settings) ON public.families TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) | src 70:192
GRANT UPDATE (updated_at) ON public.families TO service_role;   -- ev g1-q6.update_column_grants | src 70:193
GRANT UPDATE (created_at) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:194
GRANT UPDATE (family_id) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:195
GRANT UPDATE (id) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:196
GRANT UPDATE (removed_at) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:197
GRANT UPDATE (role) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:198
GRANT UPDATE (status) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:199
GRANT UPDATE (user_id) ON public.family_members TO service_role;   -- ev g1-q6.update_column_grants | src 70:200
GRANT UPDATE (accuracy_m) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:201
GRANT UPDATE (device_id) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:202
GRANT UPDATE (family_id) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:203
GRANT UPDATE (id) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:204
GRANT UPDATE (lat) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:205
GRANT UPDATE (lng) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:206
GRANT UPDATE (received_at) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:207
GRANT UPDATE (recorded_at) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:208
GRANT UPDATE (source) ON public.location_events TO service_role;   -- ev g1-q6.update_column_grants | src 70:209
GRANT UPDATE (attempted_at) ON public.pairing_attempts TO service_role;   -- ev g1-q6.update_column_grants | src 70:210
GRANT UPDATE (code_hash) ON public.pairing_attempts TO service_role;   -- ev g1-q6.update_column_grants | src 70:211
GRANT UPDATE (id) ON public.pairing_attempts TO service_role;   -- ev g1-q6.update_column_grants | src 70:212
GRANT UPDATE (parent_user_id) ON public.pairing_attempts TO service_role;   -- ev g1-q6.update_column_grants | src 70:213
GRANT UPDATE (success) ON public.pairing_attempts TO service_role;   -- ev g1-q6.update_column_grants | src 70:214
GRANT UPDATE (child_user_id) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:215
GRANT UPDATE (created_at) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:216
GRANT UPDATE (expires_at) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:217
GRANT UPDATE (family_id) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:218
GRANT UPDATE (id) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:219
GRANT UPDATE (parent_user_id) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:220
GRANT UPDATE (responded_at) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:221
GRANT UPDATE (status) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:222
GRANT UPDATE (token_id) ON public.pairing_requests TO service_role;   -- ev g1-q6.update_column_grants | src 70:223
GRANT UPDATE (created_at) ON public.profiles TO service_role;   -- ev g1-q6.update_column_grants | src 70:224
GRANT UPDATE (display_name) ON public.profiles TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) -- makes profiles_update_self reachable | src 70:225
GRANT UPDATE (id) ON public.profiles TO service_role;   -- ev g1-q6.update_column_grants | src 70:226
GRANT UPDATE (role) ON public.profiles TO service_role;   -- ev g1-q6.update_column_grants | src 70:227
GRANT UPDATE (updated_at) ON public.profiles TO service_role;   -- ev g1-q6.update_column_grants | src 70:228
GRANT UPDATE (accepted_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:229
GRANT UPDATE (child_user_id) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:230
GRANT UPDATE (consent_recorded) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:231
GRANT UPDATE (created_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:232
GRANT UPDATE (device_id) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:233
GRANT UPDATE (ended_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:234
GRANT UPDATE (ended_by) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:235
GRANT UPDATE (ended_reason) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:236
GRANT UPDATE (expires_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:237
GRANT UPDATE (family_id) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:238
GRANT UPDATE (id) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:239
GRANT UPDATE (kind) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:240
GRANT UPDATE (parent_user_id) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:241
GRANT UPDATE (requested_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:242
GRANT UPDATE (session_nonce) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:243
GRANT UPDATE (started_at) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:244
GRANT UPDATE (status) ON public.remote_sessions TO service_role;   -- ev g1-q6.update_column_grants | src 70:245
GRANT UPDATE (device_id) ON public.safe_zone_states TO service_role;   -- ev g1-q6.update_column_grants | src 70:246
GRANT UPDATE (inside) ON public.safe_zone_states TO service_role;   -- ev g1-q6.update_column_grants | src 70:247
GRANT UPDATE (updated_at) ON public.safe_zone_states TO service_role;   -- ev g1-q6.update_column_grants | src 70:248
GRANT UPDATE (zone_id) ON public.safe_zone_states TO service_role;   -- ev g1-q6.update_column_grants | src 70:249
GRANT UPDATE (active) ON public.safe_zones TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) -- makes safe_zones_update_parent reachable | src 70:250
GRANT UPDATE (created_at) ON public.safe_zones TO service_role;   -- ev g1-q6.update_column_grants | src 70:251
GRANT UPDATE (created_by) ON public.safe_zones TO service_role;   -- ev g1-q6.update_column_grants | src 70:252
GRANT UPDATE (family_id) ON public.safe_zones TO service_role;   -- ev g1-q6.update_column_grants | src 70:253
GRANT UPDATE (id) ON public.safe_zones TO service_role;   -- ev g1-q6.update_column_grants | src 70:254
GRANT UPDATE (lat) ON public.safe_zones TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) | src 70:255
GRANT UPDATE (lng) ON public.safe_zones TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) | src 70:256
GRANT UPDATE (name) ON public.safe_zones TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) | src 70:257
GRANT UPDATE (radius_m) ON public.safe_zones TO authenticated, service_role;   -- ev g1-q6.update_column_grants (2 triples) | src 70:258
GRANT UPDATE (acknowledged_at) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:259
GRANT UPDATE (acknowledged_by) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:260
GRANT UPDATE (created_at) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:261
GRANT UPDATE (device_id) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:262
GRANT UPDATE (family_id) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:263
GRANT UPDATE (id) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:264
GRANT UPDATE (message) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:265
GRANT UPDATE (payload) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:266
GRANT UPDATE (severity) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:267
GRANT UPDATE (type) ON public.safety_alerts TO service_role;   -- ev g1-q6.update_column_grants | src 70:268
GRANT UPDATE (app_label) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:269
GRANT UPDATE (day) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:270
GRANT UPDATE (device_id) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:271
GRANT UPDATE (family_id) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:272
GRANT UPDATE (id) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:273
GRANT UPDATE (last_used_at) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:274
GRANT UPDATE (package_name) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:275
GRANT UPDATE (source) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:276
GRANT UPDATE (total_ms) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:277
GRANT UPDATE (uploaded_at) ON public.usage_daily TO service_role;   -- ev g1-q6.update_column_grants | src 70:278
GRANT UPDATE (created_at) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:279
GRANT UPDATE (from_user_id) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:280
GRANT UPDATE (id) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:281
GRANT UPDATE (kind) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:282
GRANT UPDATE (payload) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:283
GRANT UPDATE (sequence) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:284
GRANT UPDATE (session_id) ON public.webrtc_signals TO service_role;   -- ev g1-q6.update_column_grants | src 70:285

-- ---- NOT EMITTED: g1-q1.table_acl delta whose grantee is the PLATFORM-MANAGED role postgres ----
-- 19 triples present in acltext and absent from g1-q6. Recorded verbatim from src: 70:83-101 so the
-- reviewer can see nothing was dropped silently (rule at src: 70:19-22). Reversal direction checked
-- in the source: 0 triples in g1-q6 and absent from acltext (src: 70:61-62).
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.audit_logs TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.child_contact_ids TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_apps TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_commands TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_pairing_tokens TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.device_policies TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.devices TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.families TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.family_members TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.location_events TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.pairing_attempts TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.pairing_requests TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.profiles TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.remote_sessions TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safe_zone_states TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safe_zones TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.safety_alerts TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.usage_daily TO postgres;
--   NOT EMITTED (platform-managed grantee postgres) GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.webrtc_signals TO postgres;

-- ---- NOT EMITTED: default privileges in PLATFORM-MANAGED SCHEMAS (auth, extensions, graphql, ----
-- ---- graphql_public, realtime, storage) and default privileges granted TO postgres. 57 rows.  ----
-- verbatim from src: 70:287-319, 339-356. Two of them carry the source's undecoded ACL marker
-- "???*": S2-EXEC-04 M-2 explains that the generator's decoder mapped a grant-option star to an
-- unmapped marker, so production grants postgres these privileges WITH GRANT OPTION and neither the
-- star nor the letter renders correctly. They are reproduced EXACTLY as captured and NOT hand-fixed
-- (finding R4: hand-editing the comment text would break provenance labels). They sit inside comments
-- so their load impact is nil. The 4 occurrences are marked "SIC".
--   (src 70:287-292, schema auth, grantor supabase_auth_admin) 6 rows: SEQUENCES to postgres / dashboard_user; EXECUTE ON FUNCTIONS to postgres / dashboard_user; TABLES to postgres / dashboard_user.
--   NOT EMITTED (platform-managed schema extensions) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ???*, SELECT, UPDATE, USAGE ON SEQUENCES TO postgres;         -- SIC: M-2 undecoded grant-option marker
--   NOT EMITTED (platform-managed schema extensions) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ???*, EXECUTE ON FUNCTIONS TO postgres;                         -- SIC: M-2
--   NOT EMITTED (platform-managed schema extensions) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ???*, DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO postgres;   -- SIC: M-2
--   (src 70:296-307, schema graphql, grantor supabase_admin) 12 rows: SEQUENCES / EXECUTE ON FUNCTIONS / TABLES to postgres, anon, authenticated, service_role.
--   (src 70:308-319, schema graphql_public, grantor supabase_admin) 12 rows: the same 3 object types x 4 grantees.
--   (src 70:339-344, schema realtime, grantor supabase_admin) 6 rows: SEQUENCES to postgres / dashboard_user; EXECUTE to postgres / dashboard_user;
--   NOT EMITTED (platform-managed schema realtime) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ???*, DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO postgres;   -- SIC: M-2
--   (src 70:345-356, schema storage, grantor postgres) 12 rows: SEQUENCES / EXECUTE / TABLES to postgres, anon, authenticated, service_role.
-- Of the public-schema ADP rows, 6 more are NOT EMITTED because their grantee is postgres:
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, UPDATE, USAGE ON SEQUENCES TO postgres;                    -- src 70:320
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT, UPDATE, USAGE ON SEQUENCES TO postgres;               -- src 70:322
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO postgres;                                  -- src 70:326
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO postgres;                           -- src 70:327
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO postgres;   -- src 70:331
--   NOT EMITTED (platform-managed grantee postgres) ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO postgres;   -- src 70:335
-- Role memberships (g1-q6.role_memberships, 24 rows: role/member/admin_option) are NOT emitted at all
-- -- platform-managed Supabase memberships, outside A0 and outside the staging schema scope (src: 00:37-39,
-- src: 70:358). Their absence is also the source of the H-3 uncertainty about supabase_admin membership.

COMMIT;                                  -- transaction control; not counted as a load statement
                                         -- If ANY statement above failed, PostgreSQL aborted the batch and
                                         -- NOTHING was applied: staging stays the empty shell it is today.
                                         -- If COMMIT succeeded, the 452 statements above are durable and
                                         -- SECTION 10 can count them.

-- ============================================================================
-- SECTION 9 -- ALTER DEFAULT PRIVILEGES  (13 ACTIVE STATEMENTS)  *** OPTIONAL, OUTSIDE THE
--              TRANSACTION, PASTE ONLY AFTER THE COMMIT ABOVE HAS SUCCEEDED ***
-- ============================================================================
-- H-3 REPAIR (deviation D-4). These 13 statements are the tail of the source's section 70
-- (src: 70:321-338) and were its statements #447..#459. WHY THEY ARE HERE AND NOT IN THE TRANSACTION:
--   ALTER DEFAULT PRIVILEGES FOR ROLE X ... requires the EXECUTING role to be a member of X (or a
--   superuser). 9 of the 13 name grantor supabase_admin. The captured membership set
--   (g1-q6.role_memberships, 24 rows, role/member/admin_option) contains NO row naming supabase_admin
--   as a group of postgres, and 00:44 records that postgres is not superuser-class on Supabase
--   (authenticator rolsuper=false, g1-b3b.authenticator_role_config). If staging mirrors production
--   membership, source statement #448 -- the first supabase_admin one -- fails with
--       ERROR:  42501: permission denied  --  must be member of role "supabase_admin"
--   In the un-wrapped artefact that aborts the batch with statements #1..#447 already applied and
--   #448..#459 never run (S2-EXEC-04 H-3, M-1). In THIS file that same failure happens AFTER the
--   COMMIT, so the only thing a membership failure can cost is the default-privilege tail -- and
--   because the dashboard aborts a script at the first error, the statements are ordered so that the
--   4 postgres-grantor statements (which the dashboard role certainly satisfies -- it IS postgres,
--   INFERRED from g1-q1.owner=postgres) come FIRST and run unconditionally, and the 9
--   supabase_admin-grantor statements come LAST: if membership fails, the failure point is #5 of this
--   section and at most 9 evidenced default-privilege entries are lost, never the 447 statements of
--   structure. THIS IS THE DELIBERATE REORDERING described as deviation D-4 in the STATUS block.
--   They are NOT silently dropped: all 13 are here, and each carries the g1-q6.default_acl row it
--   reproduces (fields: owner, schema_name, object_type, acl).
--
-- OPERATOR PROCEDURE FOR THIS SECTION (it is the only part of the file that is conditional):
--   1. Run the one-line PROBE printed above each statement, in this editor, one at a time.
--   2. Every probe must return true. If any returns false, DELETE that statement (and the ones after
--      it that share its grantor) from the paste -- do not paste it and do not substitute another.
--   3. Paste the remaining statements. Record which were dropped in the G3-c restore log; the
--      resulting divergence from production's pg_default_acl is then a KNOWN, DOCUMENTED difference
--      for G3-d rather than a silent one.
--   4. If ALL 13 run, compare the resulting pg_default_acl contents against
--      g1-q6.default_acl rows 3 and 16-18 (verification query V-13 in SECTION 10).
--   5. CAVEAT: ALTER DEFAULT PRIVILEGES is NOT self-reversing (S2-EXEC-04 rollback assessment). A
--      staging pre-state capture (checklist item [5]) is the only rollback target for these rows.

-- ---- grantor postgres (4 statements) -- executor IS postgres, so these should be safe ----
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'postgres', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO service_role;   -- ev g1-q6.default_acl[owner=postgres, schema_name=public, object_type=sequences] | src 70:321
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'postgres', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO anon;   -- ev g1-q6.default_acl[owner=postgres, public, relations] | src 70:332
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'postgres', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO authenticated;   -- ev g1-q6.default_acl[owner=postgres, public, relations] | src 70:333
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'postgres', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO service_role;   -- ev g1-q6.default_acl[owner=postgres, public, relations] | src 70:334

-- ---- grantor supabase_admin (9 statements) -- H-3 FAILURE MODE LIVES HERE ----
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT, UPDATE, USAGE ON SEQUENCES TO anon;   -- ev g1-q6.default_acl[owner=supabase_admin, public, sequences] | src 70:323  <-- source statement #448, the H-3 first-failure point
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT, UPDATE, USAGE ON SEQUENCES TO authenticated;   -- ev g1-q6.default_acl | src 70:324
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT, UPDATE, USAGE ON SEQUENCES TO service_role;   -- ev g1-q6.default_acl | src 70:325
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon;   -- ev g1-q6.default_acl[object_type=functions] | src 70:328
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated;   -- ev g1-q6.default_acl | src 70:329
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO service_role;   -- ev g1-q6.default_acl | src 70:330
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO anon;   -- ev g1-q6.default_acl[object_type=relations] | src 70:336
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO authenticated;   -- ev g1-q6.default_acl | src 70:337
-- PROBE (run first, expect true): SELECT pg_has_role(current_user, 'supabase_admin', 'MEMBER');
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLES TO service_role;   -- ev g1-q6.default_acl | src 70:338

-- ============================================================================
-- SECTION 10 -- POST-LOAD VERIFICATION (19 READ-ONLY SELECTs across 15 checks, V-1..V-15; run them
--               in the same editor AFTER the load, one at a time or as a batch. They change nothing.)
-- ============================================================================
-- These confirm what the load DID and, just as importantly, what it did NOT do. Expected values are
-- the counts the source artefact's evidence implies (g1-q1 / q2 / q4 / q5 / q6 / q8, g1-b3b), not
-- numbers remembered. Any mismatch is a G3-d difference to be written down, not silently accepted.

-- V-1  environment proof -- expected: db=postgres, version 17.x, sentinel='staging'
SELECT current_database() AS db, current_setting('server_version') AS server_version,
       (SELECT environment FROM private.s2_environment LIMIT 1) AS sentinel;
       -- ev: docs/stage2/00-stage2-execution-plan.md:149-153 (sentinel), g1-run-manifest-20261029.md (17.11)

-- V-2  tables -- expected: 19
SELECT count(*) AS tables_expected_19 FROM information_schema.tables
 WHERE table_schema='public' AND table_type='BASE TABLE';
       -- ev: g1-q1 19 rows (table_name) / g1-q8 distinct table_name

-- V-3  columns -- expected: 183
SELECT count(*) AS columns_expected_183 FROM information_schema.columns
 WHERE table_schema='public';
       -- ev: g1-q8 183 rows (table_name, column_name, ordinal_position)

-- V-4  constraints with kind breakdown -- expected: total 137; p=19, u=9, c=65, f=44
SELECT c.contype, count(*) AS n_expected_p19_u9_c65_f44
  FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace
 WHERE n.nspname='public' GROUP BY c.contype ORDER BY c.contype;
       -- ev: g1-q5 137 rows (kind, validated) | src: 20:14

-- V-5  indexes, total -- expected: 62 (34 emitted + 28 created implicitly by the 19 PK + 9 UNIQUE)
SELECT count(*) AS indexes_expected_62 FROM pg_indexes WHERE schemaname='public';
       -- ev: g1-q4 62 rows | suppression set verified by S2-EXEC-04 check 6

-- V-6  indexes NOT backed by a constraint -- expected: 34 (exactly the SECTION 30 statements)
SELECT count(*) AS standalone_indexes_expected_34
  FROM pg_index i JOIN pg_class ic ON ic.oid=i.indexrelid
  JOIN pg_class t ON t.oid=i.indrelid JOIN pg_namespace n ON n.oid=t.relnamespace
 WHERE n.nspname='public' AND ic.relkind IN ('i','I')
   AND NOT EXISTS (SELECT 1 FROM pg_constraint con WHERE con.conindid=i.indexrelid);
       -- ev: g1-q4 (34 non-constraint definitions) | src: 30:82 emitted=34

-- V-7  RLS state -- expected: enabled 19, forced 0
SELECT count(*) FILTER (WHERE c.relrowsecurity)     AS rls_enabled_expected_19,
       count(*) FILTER (WHERE c.relforcerowsecurity) AS rls_forced_expected_0
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind='r';
       -- ev: g1-q1.rls_enabled=true x19, g1-q1.rls_forced=false x19

-- V-8  policies -- expected: 4, and they must be exactly families_update_owner, profiles_update_self,
--      webrtc_signals_insert_participant, webrtc_signals_select_participant. PRODUCTION HAS 21.
SELECT count(*) AS policies_expected_4_this_load FROM pg_policies WHERE schemaname='public';
SELECT policyname, tablename, cmd, roles, permissive FROM pg_policies
 WHERE schemaname='public' ORDER BY policyname;
       -- ev: g1-q2 21 captured rows, of which 4 have no private.* reference (S2-EXEC-04 H-1 :42)

-- V-9  RLS-enabled tables carrying ZERO policies -- expected: 16
--      THIS IS THE H-1 DEAD-SHELL CENSUS. On these 16 tables every authenticated SELECT returns 0
--      rows and every authenticated write fails 42501, exactly because the 17 blocked policies are
--      absent. A non-zero answer here is the load working as designed, not as intended for an app.
SELECT count(*) AS tables_with_rls_and_no_policy_expected_16
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind='r' AND c.relrowsecurity
   AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid=c.oid);
       -- ev: g1-q1 (19 enabled) minus the 3 tables this load attaches policies to

-- V-10 table-level ACL entries for the application roles -- expected: 168 = 149 g1-q6.table_grants
--      triples + 19 g1-q1.table_acl 'm' MAINTAIN triples. If the answer is LARGER, the surplus comes
--      from platform default privileges (SECTION 9 / g1-q6.default_acl) merging into the same ACL;
--      list and explain the surplus, do not accept the count as a pass.
SELECT count(*) AS table_acl_entries_expected_168
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  CROSS JOIN LATERAL aclexplode(c.relacl) x
 WHERE n.nspname='public' AND c.relkind='r'
   AND x.grantee IN (SELECT oid FROM pg_roles WHERE rolname IN ('authenticated','service_role'));
       -- ev: g1-q6.table_grants 149 rows (table_name, grantee, privilege_type, is_grantable)
       --     g1-q1.table_acl (letter m) 19 | is_grantable='NO' on all 149 -> expect false below
SELECT DISTINCT x.is_grantable FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  CROSS JOIN LATERAL aclexplode(c.relacl) x
 WHERE n.nspname='public' AND c.relkind='r';   -- expected: a single row, false

-- V-11 column-level ACL -- expected: 183 columns with an explicit attacl, 191 (grantee,privilege) items
SELECT count(*) AS columns_with_column_acl_expected_183
  FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind='r' AND a.attnum>0 AND a.attacl IS NOT NULL;
SELECT count(*) AS column_acl_items_expected_191
  FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  CROSS JOIN LATERAL aclexplode(a.attacl) x
 WHERE n.nspname='public' AND c.relkind='r' AND a.attnum>0 AND a.attacl IS NOT NULL;
       -- ev: g1-q6.update_column_grants 191 rows over 183 distinct (table,column) | src: 70:359-361

-- V-12 schema USAGE on private -- expected: authenticated t, anon f
SELECT has_schema_privilege('authenticated','private','USAGE') AS expected_true,
       has_schema_privilege('anon','private','USAGE')          AS expected_false;
       -- ev: g1-b3b.schema_usage.authenticated=true, .anon=false (g1-b3b-20261029.json:14-19) -- M-4/D-5

-- V-13 default privileges in public -- expected: the 13 (grantor, object_type, grantee) combinations
--      from SECTION 9, stored as ~5 rows because pg_default_acl holds ONE row per (grantor, schema,
--      object type) and merges grantees into its ACL array. Do not read "5" as failure and do not
--      read a larger number as success without listing what the extra entries are.
SELECT pg_get_userbyid(d.defaclrole) AS grantor,
       CASE d.defaclobjtype WHEN 'r' THEN 'tables' WHEN 'S' THEN 'sequences'
                            WHEN 'f' THEN 'functions' WHEN 'v' THEN 'views'
                            WHEN 'm' THEN 'materialized views' WHEN 't' THEN 'foreign tables'
       END AS object_type,
       x.grantee::regrole::text AS grantee, count(*) AS privileges
  FROM pg_default_acl d JOIN pg_namespace n ON n.oid=d.defaclnamespace
  CROSS JOIN LATERAL aclexplode(d.defaclacl) x
 WHERE n.nspname='public'
 GROUP BY 1,2,3 ORDER BY 1,2,3;                -- expected: 13 groups if SECTION 9 fully succeeded
       -- ev: g1-q6.default_acl rows with schema_name=public (fields owner, schema_name, object_type, acl)

-- V-14 FK binding proof -- expected: 44 FKs total, 43 referencing public.*, 1 referencing auth.users
SELECT count(*) AS fks_expected_44 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace
 WHERE n.nspname='public' AND c.contype='f';
SELECT rn.nspname AS referenced_schema, count(*) AS expected_public_43_auth_1
  FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  JOIN pg_class rf ON rf.oid=c.confrelid JOIN pg_namespace rn ON rn.oid=rf.relnamespace
 WHERE n.nspname='public' AND c.contype='f' GROUP BY rn.nspname;
       -- ev: g1-q5 (44 kind=f rows) -- proves the D-1/M-5 qualification bound where intended

-- V-15 what this load did NOT create -- expected: functions 0, public-table triggers 0,
--      publication tables 0, columns with defaults referencing private 0. THIS IS THE QUERY THAT
--      KEEPS THE LOAD HONEST: any G5-S case whose expected result depends on a function, trigger or
--      Realtime message must be recorded BLOCKED, not FAILED and not PASSED.
SELECT (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
         WHERE n.nspname IN ('public','private'))               AS functions_expected_0_of_38,
       (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
          JOIN pg_namespace n ON n.oid=c.relnamespace
         WHERE n.nspname='public' AND NOT t.tgisinternal)       AS triggers_expected_0_of_7,
       (SELECT count(*) FROM pg_publication_tables WHERE schemaname='public') AS pub_tables_expected_0;
       -- ev: S2-EXEC-04 H-2 (40/50/55/80 contribute 0 active statements), g1-q3 (7), g1-q3b (1), g1-b3b (38)

-- ============================================================================
-- SECTION 11 -- ROLLBACK: WHAT IT MEANS HERE (ALL COMMENTED -- NOTHING IN THIS SECTION MAY BE PASTED
--               WITHOUT ITS OWN SEPARATE OWNER DECISION)
-- ============================================================================
-- HONEST STATEMENT OF THE POSITION (no claim is made that any of this works -- S2-EXEC-04
-- "Rollback-readiness assessment" ends with "I have run no SQL against nothing ... and therefore
-- make no claim that a rollback script would succeed"):
--   * Supabase Free/NANO has NO platform backup and NO PITR for this project -- ev:
--     docs/stage2/00-stage2-execution-plan.md:155-159 (R-30 pause-after-7-days, R-35 no backup/PITR)
--     and docs/stage2/04-risks-rollback-approvals.md. There is no "restore to before".
--   * Therefore rollback on this project is a DROP-class forward action, not a restore: either
--     (a) tear the loaded objects down in reverse dependency order, or
--     (b) delete the staging project and create a fresh one, re-run A2'(a), re-run this load.
--     Both leave the database in a state that is NOT byte-identical to "never loaded" -- the
--     pg_default_acl rows in SECTION 9 are not self-reversing (ALTER DEFAULT PRIVILEGES has no
--     "restore previous" form), which is exactly why the pre-state capture in checklist item [5]
--     is mandatory before pasting SECTION 9.
--   * THIS IS THE OTHER REASON FOR THE TRANSACTION WRAPPER. Without BEGIN/COMMIT, an aborted load
--     leaves a half-built schema (447 statements' worth of objects, constraints, RLS enables and
--     grants) that must then be hand-torn-down, with no backup to fall back on. With the wrapper,
--     an abort leaves nothing to roll back. Rollback only ever has to cover a COMMITTED load.
--   * Idempotency is absent by construction: no CREATE TABLE / ADD CONSTRAINT / CREATE INDEX in this
--     file uses IF NOT EXISTS, so a re-run after a partial or committed load fails at the first
--     existing object (42P07). Do not "retry" this file. Tear down or start a new project.
--   * DROP SCHEMA public CASCADE is NOT offered as the rollback. It is a class of action that also
--     removes anything else the platform or the operator has put in public, requires CREATE SCHEMA
--     public plus the platform's own grants to be re-established afterwards, and was never exercised
--     or verified anywhere in this programme. It is written below as a labelled LAST RESORT comment
--     with that reasoning, not as a suggestion.
--
-- Reverse-order teardown derived from the dependency graph re-confirmed in S2-EXEC-04
-- ("Missing evidence / Rollback-readiness"): 13 ADP resets (undefined target -- see above) ->
-- column GRANTs -> table GRANTs -> 4 policies -> DISABLE RLS x19 -> 34 indexes -> 137 constraints
-- (FKs first, then CHECKs, then UNIQUE/PK) -> 19 tables -> DROP SCHEMA private. No CASCADE is needed
-- between those steps because constraints and indexes attach to tables that already exist; the FK to
-- auth.users means public tables must go before (or never with) auth objects -- plain reverse order
-- respects that. Component 55 contributes nothing to tear down (0 active statements, S2-EXEC-04 I-2).
--
-- *** EVERY STATEMENT BELOW IS COMMENTED OUT ON PURPOSE. ***
-- -- DROP POLICY families_update_owner ON public.families;                       -- this load only; prod has 21
-- -- DROP POLICY profiles_update_self ON public.profiles;
-- -- DROP POLICY webrtc_signals_insert_participant ON public.webrtc_signals;
-- -- DROP POLICY webrtc_signals_select_participant ON public.webrtc_signals;
-- -- ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;                   -- ... x19, one per table in SECTION 60
-- -- DROP TABLE public.audit_logs, public.child_contact_ids, ... , public.webrtc_signals;  -- all 19, no CASCADE
-- -- DROP SCHEMA private;                                                        -- only if s2_environment is recreated too
-- -- LAST RESORT, NOT RECOMMENDED, NEVER VERIFIED: DROP SCHEMA public CASCADE; CREATE SCHEMA public;
-- --   (reason it is not recommended is in the bullet above; platform objects and grants in public
-- --    would have to be re-established by the owner from the Supabase baseline, not from this file)
--
-- SENTINEL CHECK THAT DETECTS A WRONG-PROJECT LOAD: SECTION 0's DO block. It runs as the FIRST
-- statement inside the transaction and aborts the batch before any DDL if
--   (a) private.s2_environment does not exist, or
--   (b) its one row does not read 'staging'.
-- Because A2'(a) creates that table in staging ONLY (it is excluded from the parity diff by name and
-- must never exist in production -- ev: docs/stage2/01-staging-project-proposal.md:105-106), a paste
-- into the production editor aborts. It is the only control that works, because the dashboard renders
-- two visually identical SQL Editors and no captured catalogue query distinguishes projects by itself
-- -- ev: docs/stage2/00-stage2-execution-plan.md:149-153 (D-09 / redteam J-03). The guard was reused
-- verbatim in shape from docs/stage2/patches/S2-P01-e2-f8.sql:105-111 so that this load and every
-- later patch test the same sentinel the same way. If the operator removes or comments the guard, the
-- file loses its wrong-project protection entirely: DO NOT REMOVE IT.

-- ============================================================================
-- STATUS
-- ============================================================================
-- PREPARED -- NOT EXECUTED -- REQUIRES A2'(a) + A3
--
-- Nothing in this file has been run. No cloud access of any kind was used to produce it: no
-- Supabase dashboard, no browser, no SQL execution, no REST, no supabase CLI, no database
-- connection, no curl. Reads were limited to local files under D:\control and the read-only source
-- artefact directory. The production project parent-control-prod / hhqgreaoqulmfwfwarhc was treated
-- as a string only and is not a target of any statement here. Repository remains at zero commits;
-- nothing was committed, staged, pushed, reset or cleaned, and no file other than this one was
-- created or modified.
--
-- TARGET: parent-control-staging / dzonzgngwxclhfnvxtvu   SERVER: PostgreSQL 17
-- DERIVES FROM: g3-reconstruction-2026-11-02.sql, SHA-256 fc996f450690d8b6678bd2ad02b92c1fe0df9c07120fe07f9c5733efd1d908f6 (459 active statements)
--
-- ACTIVE STATEMENT COUNT IN THIS FILE (counted by class, not estimated):
--   Inside BEGIN..COMMIT ................................................. 452
--     DO (sentinel guard) ................................................     1
--     CREATE SCHEMA ......................................................     2
--     CREATE TABLE .......................................................    19   (183 columns)
--     ALTER TABLE ... ADD CONSTRAINT .....................................   137   (19 p / 9 u / 65 c / 44 f)
--     CREATE [UNIQUE] INDEX ..............................................    34   (28 constraint-backed indexes deliberately not re-emitted)
--     ALTER TABLE ... ENABLE ROW LEVEL SECURITY ..........................    19   (0 FORCE)
--     CREATE POLICY ......................................................     4
--     GRANT USAGE ON SCHEMA private ......................................     1   (M-4 repair)
--     GRANT ... ON TABLE .................................................    52   (33 from g1-q6 + 19 MAINTAIN from g1-q1.table_acl)
--     GRANT UPDATE (column) ..............................................   183   (191 triples)
--   After COMMIT, optional SECTION 9 .....................................  13   ALTER DEFAULT PRIVILEGES
--   TOTAL LOAD-AFFECTING ACTIVE STATEMENTS ............................... 465
--     vocabulary: CREATE 59 | ALTER 169 | GRANT 236 | DO 1  (source was CREATE 55 | ALTER 169 | GRANT 235 = 459)
--   Read-only verification SELECTs, SECTION 10 (not load statements) ......  19   across 15 checks V-1..V-15
--   Transaction control, not counted above ...............................   2   (BEGIN, COMMIT)
--   GRAND TOTAL EXECUTABLE STATEMENTS IN THE FILE ....................... 486   (465 load + 19 read-only + 2 control)
--   Commented-out / non-executing statements preserved as records: 4 policy
--     text lines re-stated as blockers in SECTION 6 are counted above; the non-executing record set is
--     8 triggers (7 SECTION 50 + 1 SECTION 55), 17 policies, 4 publication ADDs, 38 function inventory
--     blocks (in the source, not restated here), 19 platform-postgres table grants, 6 public-schema
--     platform ADP grants, 57 platform-schema ADP rows.
--   465 = 459 (source) - 13 (ADP moved after COMMIT) + 4 (policies) + 1 (schema USAGE) + 1 (sentinel DO) + 13 (ADP still present, just relocated).
--   NO STATEMENT WAS DROPPED. 446 of the source's structural statements remain inside the transaction
--   (459 - 13), 13 are relocated, and 6 statements are ADDED by this file (4 policies + 1 schema USAGE + 1 sentinel DO).
--
-- POLICIES: 4 emitted ACTIVE / 17 kept COMMENTED (of 21 captured in g1-q2).
-- TRIGGERS: 0 emitted / 8 kept COMMENTED (7 public-table + 1 auth.users).
-- FUNCTIONS: 0 emitted / 38 inventoried in the source, 9 of them named explicitly in SECTION 40.
--
-- *** THE LOADED DATABASE IS NOT APPLICATION-READY. *** Loading the 4 active policies restores only
-- parent-owned family UPDATE, self-profile UPDATE and webrtc_signal INSERT/SELECT for an accepted or
-- active session participant. 17 policies and 8 triggers remain blocked on the 9 missing function
-- return types enumerated in SECTION 40, so 16 of the 19 RLS-enabled tables carry no policy at all
-- and are deny-all for authenticated (V-9 measures it). No signup provisioning, no append-only audit
-- guard, no updated_at maintenance, no session transition guard, no Realtime. Treat every downstream
-- G5-S case as BLOCKED, not PASSED, until a function capture closes H-2.
--
-- ============================================================================
-- DEVIATIONS FROM THE SOURCE ARTEFACT (every one, with the evidence line that justifies it)
-- ============================================================================
-- D-1  43 of 44 FK targets schema-qualified to public. (1 left as captured: auth.users.)
--      Justifies: S2-EXEC-04 M-5 -- "unqualified FK targets bind at load time to the loader's
--      search_path"; qualification is "fully determinable offline from g1-q5.table_name/
--      referenced_table" and the relnamespace of every referenced table is public per g1-q1.
--      Statements changed: audit_logs_actor_user_id_fkey .. webrtc_signals_session_id_fkey,
--      src 20:120-146 and 20:148-163. Unchanged: src 20:147 (profiles_id_fkey -> auth.users(id)).
-- D-2  Whole load wrapped in BEGIN; ... COMMIT;.
--      Justifies: S2-EXEC-04 M-1 ("0 hits" for BEGIN/COMMIT/ROLLBACK across all 11 component files)
--      and H-3 ("statements 1-447 stay applied while the remaining 12 never run"); R1.
-- D-3  Two INSERT policies rendered WITHOUT a USING clause instead of the source's literal
--      "USING (None)". Justifies: S2-EXEC-04 M-3, and the g1-q2 rows themselves --
--      webrtc_signals_insert_participant: "cmd":"INSERT","qual":null ;
--      safe_zones_insert_parent:       "cmd":"INSERT","qual":null.
--      PostgreSQL has no USING clause on those production policies, so omitting it is the faithful
--      rendering; "USING (None)" is a leaked Python None and invalid SQL.
-- D-4  The 13 ALTER DEFAULT PRIVILEGES statements moved AFTER the COMMIT into an explicitly optional
--      section, each preceded by a one-line pg_has_role probe, and REORDERED so the 4 postgres-grantor
--      statements precede the 9 supabase_admin-grantor statements.
--      Justifies: S2-EXEC-04 H-3 -- the failure mode is `must be member of role "supabase_admin"` at
--      source statement #448 (src 70:323); g1-q6.role_memberships (role/member/admin_option, 24 rows)
--      names no supabase_admin membership of postgres, and src 00:44 records rolsuper=False
--      (ev: g1-b3b.authenticator_role_config). Not silently dropped: all 13 are present.
-- D-5  Added GRANT USAGE ON SCHEMA private TO authenticated.
--      Justifies: S2-EXEC-04 M-4 -- "no GRANT ... ON SCHEMA statement of any kind" in section 70,
--      although the evidence records the privilege. EXACT FIELD: g1-b3b-20261029.json
--      "schema_usage" object, key "authenticated" = true (line 17); transcribed at src 00:45.
--      Companion value schema_usage.service_role = true is recorded, NOT emitted (out of scope).
-- D-6  4 CREATE POLICY emitted ACTIVE instead of commented.
--      Justifies: S2-EXEC-04 H-1 aggravating sub-finding (:42) -- exactly 4 of 21 reference only
--      auth.uid() and plain SQL and "were batch-suppressed with the rest"; re-derived here from
--      g1-q2 (17 rows contain "private.", 4 do not). Predicate text is verbatim from g1-q2.qual /
--      g1-q2.with_check; only whitespace was reflowed. Reachability evidenced in SECTION 7
--      (g1-q6.update_column_grants / table_grants).
-- D-7  Added the sentinel DO guard as statement #1 of the transaction. Absent from the source
--      entirely ("The artefact contains no rollback component at all" -- S2-EXEC-04).
--      Justifies: docs/stage2/00-stage2-execution-plan.md:92, :135, :149-153 (A2'(a) BEFORE the load,
--      D-09, redteam J-03) and docs/stage2/01-staging-project-proposal.md:105-106, :179; guard shape
--      reused from docs/stage2/patches/S2-P01-e2-f8.sql:105-111.
-- D-8  Added SECTION 10 (15 verification checks / 19 read-only SELECTs) and SECTION 11 (rollback
--      explanation).
--      Justifies: S2-EXEC-04 "Rollback-readiness assessment" (no rollback exists in the artefact; a
--      DROP-class action or a fresh project is the only route; ADP is not self-reversing; idempotency
--      is absent) and docs/stage2/00-stage2-execution-plan.md:155-159 (R-30 / R-35, no backup, no PITR).
-- D-9  Sections 40 / 50 / 55 / 80 kept NON-EXECUTING (0 active statements each), same as the source.
--      Justifies: S2-EXEC-04 H-2 and src 40:14-21 -- no prorettype for any of the 38 functions in
--      g1-q7 (18 rows, no return type selected) or g1-b3b (38-row inventory + 14 prosrc bodies, no
--      return type). Emitting a body or an empty stub would be invention, which is forbidden.
-- D-10 The active webrtc policies keep the captured UNQUALIFIED range name "remote_sessions s" rather
--      than "public.remote_sessions s". Justifies: the brief requires these predicates verbatim from
--      g1-q2; the binding happens at CREATE POLICY time through the loader's search_path and resolves
--      to public on Supabase (default "$user", public). Flagged rather than silently rewritten.
-- D-11 No CREATE EXTENSION emitted, and the 16 DEFAULT gen_random_uuid() sites left as captured.
--      Justifies: extensions are NOT PRESENT IN EVIDENCE (src 00:20, no pg_extension query in the G1
--      series) while S2-EXEC-04 I-1 confirms they resolve as PG13+ built-ins on a PG17 target.
--
-- NOT A DEVIATION, RECORDED SO IT IS NOT "FIXED" LATER: exactly 2 of the 21 captured policies are
-- unreachable for their named role -- devices_select_parent_or_child (g1-q6.table_grants has no
-- (devices, authenticated, *) row; g1-q1.table_acl for devices grants authenticated nothing) and
-- safe_zones_insert_parent (no INSERT grant; acltext shows authenticated=rd). Both are faithful to
-- production and stay commented on their own blocker in any case. Column-level UPDATE grants DO make
-- families_update_owner, profiles_update_self and safe_zones_update_parent reachable, which is why
-- two of them are active above. No grant was invented to change this.
--
-- END OF FILE -- A3-staging-load-v1.sql -- PREPARED, NOT EXECUTED.
