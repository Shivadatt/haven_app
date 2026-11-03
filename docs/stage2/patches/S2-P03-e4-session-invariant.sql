-- ===========================================================================
-- S2-P03 - E4: one live remote session per device. STAGING ONLY.
-- Status: PROPOSED - NOT APPLIED. Owner approval required before execution.
-- Companion: docs/stage2/parts/E-e4-session-invariant.md
--
-- Preconditions
--   1. Section 4.1 precheck returns zero duplicate live sessions.
--   2. If duplicates exist, remediate them first (section 4.2, staging only).
--   3. Section 4.1 P4 object-name precheck shows no conflicting object.
--
-- Run as the database owner (postgres), the role that owns the existing
-- remote-session objects. The file is one transaction: any failure rolls
-- everything back. Table size at Stage 1 was 39 rows, so a non-concurrent
-- CREATE INDEX is acceptable; CONCURRENTLY cannot run inside a transaction.
-- ===========================================================================

begin;

-- 0.0 WRONG-PROJECT SENTINEL. Created once in G6-b. Aborts before any DDL if
--     this session is not attached to the staging project (docs/stage2/00 D-09).
do $sentinel$
declare v_env text;
begin
  if to_regclass('private.s2_environment') is null then
    raise exception 'S2: sentinel private.s2_environment is missing; refusing to run outside staging';
  end if;
  execute 'select environment from private.s2_environment limit 1' into v_env;
  if v_env is distinct from 'staging' then
    raise exception 'S2: sentinel reads %, not staging; refusing', coalesce(v_env, '<null>');
  end if;
end $sentinel$;


-- 0. Guard against a skipped precheck. Duplicates make the unique index
--    unbuildable; this aborts with a readable message before any DDL applies.
do $precheck$
begin
  if exists (
    select 1
      from public.remote_sessions
     where status in ('requested', 'accepted', 'active')
     group by device_id
    having count(*) > 1
  ) then
    raise exception
      'E4 precheck failed: duplicate live sessions exist; remediate before applying';
  end if;
end;
$precheck$;

-- 1. Write-time enforcement -------------------------------------------------
-- SECURITY INVOKER (default) on purpose: the writers are service_role (direct
-- Edge insert; all table privileges, bypasses RLS) and postgres (inside the
-- SECURITY DEFINER RPC). Both can run the statements below. A SECURITY DEFINER
-- guard would add a privileged surface needing its own search_path pin and
-- PUBLIC EXECUTE revoke (the E2/F8 pattern) for no gain here.
-- Every object is schema-qualified; search_path is pinned defensively.
-- Keep the function VOLATILE (default) so each SQL statement inside it takes a
-- fresh snapshot and the EXISTS check sees a winner committed while this
-- transaction waited for the advisory lock.
create or replace function private.remote_session_insert_guard()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, pg_temp
as $guard$
begin
  -- Terminal rows do not participate in the invariant.
  if new.status not in ('requested', 'accepted', 'active') then
    return new;
  end if;

  -- Same lock mode and key as public.request_remote_session:
  --   pg_advisory_xact_lock(hashtextextended(p_device_id::text, 0))
  -- Transaction-scoped and re-entrant: the RPC already holds it when it
  -- reaches its own INSERT, so the guard's second acquisition is free.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.device_id::text, 0)
  );

  -- Mirror the RPC exactly: a stale pending request must not block a new one.
  -- requested -> expired is permitted by the BEFORE UPDATE transition guard.
  update public.remote_sessions
     set status = 'expired',
         ended_at = pg_catalog.now(),
         ended_reason = 'expired'
   where device_id = new.device_id
     and status = 'requested'
     and expires_at is not null
     and expires_at <= pg_catalog.now();

  -- Single user-facing conflict path; message and SQLSTATE match the RPC.
  if exists (
    select 1
      from public.remote_sessions
     where device_id = new.device_id
       and status in ('requested', 'accepted', 'active')
  ) then
    raise exception 'session_in_progress' using errcode = 'P0001';
  end if;

  return new;
end;
$guard$;

-- Trigger functions cannot be called directly, and a trigger does not consult
-- the invoker's EXECUTE at runtime. Owner-only is the intended shape, matching
-- S2-P01 and the 5 sibling trigger functions (postgres=X only). No GRANT.
revoke all on function private.remote_session_insert_guard() from public;

drop trigger if exists remote_sessions_insert_guard on public.remote_sessions;
create trigger remote_sessions_insert_guard
  before insert on public.remote_sessions
  for each row
  execute function private.remote_session_insert_guard();

-- 2. Backstop invariant ------------------------------------------------------
-- Enforced for any writer that bypasses or disables the trigger (replication
-- role, disabled trigger, future handler with no lock). The predicate must be
-- immutable and cannot reference now(); a stale `requested` row would
-- otherwise keep occupying the live slot until something expires it.
-- `if not exists` is name-based: section 4.1 P4 reports the existing definition.
create unique index if not exists remote_sessions_one_live_per_device
  on public.remote_sessions (device_id)
  where status in ('requested', 'accepted', 'active');

commit;
