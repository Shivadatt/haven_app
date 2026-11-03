-- ===========================================================================
-- S2-P01 - E2 / F8: remove the default PUBLIC EXECUTE from two private
-- functions and pin the trigger guard's search_path.
--
-- STATUS: PROPOSED - NOT APPLIED. Staging only. Executor: postgres (owner).
-- Review: docs/stage2/03-patch-S2-P01.md
-- Evidence: stage1 g1-b3b-20261029.json (inventory) + g1-q7 (proconfig)
--
-- SCOPE: 2 x REVOKE, 1 x GRANT, 1 x ALTER FUNCTION ... SET search_path.
--        No body is replaced. No table is read or written. No data change.
-- EFFECT: latent-route closure only. The only live caller is
--         public.request_device_recovery, SECURITY DEFINER owned by postgres,
--         and the Edge tier connects as service_role, so no deployed path
--         changes behaviour (docs/stage2/00 stage2-execution-plan.md D-04).
--
-- HOW TO RUN: cut-paste each section separately in the STAGING SQL Editor.
--   Section 0 is read-only. Section 1 is one transaction that aborts unless
--   the staging sentinel is present. Section 2 is the rollback, deliberately
--   commented out; uncommenting it is a separate, approved act.
-- ===========================================================================


-- ===========================================================================
-- SECTION 0 - PRE-CHECKS (read-only). Record the output with the change record.
-- Expected values are in docs/stage2/03-patch-S2-P01.md section 4.
-- ===========================================================================

-- 0.1 Identity and server
select current_user, session_user, current_database(),
       current_setting('server_version') as pg_version;

-- 0.2 Object identity: exactly one row per signature, secdef true, owner postgres
select p.oid::regprocedure as signature,
       pg_get_userbyid(p.proowner) as owner,
       p.prosecdef as secdef,
       p.prorettype::regtype as returns,
       p.proacl,
       p.proconfig
  from pg_proc p
 where p.oid in ('private.request_device_recovery(uuid,uuid)'::regprocedure,
                 'private.remote_session_transition_guard()'::regprocedure)
 order by 1;

-- 0.3 Effective EXECUTE matrix. Expect (true,true,true,true) before the patch.
select p.oid::regprocedure as signature,
       has_function_privilege('anon',          p.oid, 'EXECUTE') as anon,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated,
       has_function_privilege('service_role',  p.oid, 'EXECUTE') as service_role,
       has_function_privilege('postgres',      p.oid, 'EXECUTE') as postgres
  from pg_proc p
 where p.oid in ('private.request_device_recovery(uuid,uuid)'::regprocedure,
                 'private.remote_session_transition_guard()'::regprocedure)
 order by 1;

-- 0.4 Explicit ACL entries. Expect grantee 0 (PUBLIC) with EXECUTE only.
--     An explicit anon/authenticated row is a STOP condition.
select p.oid::regprocedure as signature,
       case when a.grantee = 0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end as grantee,
       a.privilege_type, a.is_grantable
  from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
 where p.oid in ('private.request_device_recovery(uuid,uuid)'::regprocedure,
                 'private.remote_session_transition_guard()'::regprocedure)
 order by 1, 2;

-- 0.5 Static callers: functions whose body references the recovery function.
--     Expect exactly public.request_device_recovery.
select p.oid::regprocedure as caller
  from pg_proc p
 where p.pronamespace in ('public'::regnamespace, 'private'::regnamespace)
   and p.oid <> 'private.request_device_recovery(uuid,uuid)'::regprocedure
   and p.prosrc ilike '%request_device_recovery%'
 order by 1;

-- 0.6 Trigger binding for the guard. Expect one row on public.remote_sessions.
select t.tgname, t.tgrelid::regclass as table_name, t.tgfoid::regprocedure as fn,
       t.tgenabled
  from pg_trigger t
 where not t.tgisinternal
   and t.tgfoid = 'private.remote_session_transition_guard()'::regprocedure;

-- 0.7 No login role inherits service_role. Expect 0 rows.
select r.rolname as member, m.rolname as inherited
  from pg_auth_members am
  join pg_roles r on r.oid = am.member
  join pg_roles m on m.oid = am.roleid
 where m.rolname = 'service_role';

-- 0.8 Data API exposure is a dashboard setting; NULL here is informational.
select current_setting('pgrst.db_schemas', true) as pgrst_db_schemas;


-- ===========================================================================
-- SECTION 1 - APPLY. One transaction. Aborts before any DDL unless this is
-- the staging project and the pre-state is the captured pre-state (or the
-- expected post-state, which makes a re-run harmless).
-- ===========================================================================
begin;

do $$
declare
  v_env  text;
  v_acl  aclitem[];
begin
  -- Wrong-project sentinel (docs/stage2/00 D-09). Created once in G6-b.
  if to_regclass('private.s2_environment') is null then
    raise exception 'S2-P01: sentinel private.s2_environment is missing; refusing to run outside staging';
  end if;
  execute 'select environment from private.s2_environment limit 1' into v_env;
  if v_env is distinct from 'staging' then
    raise exception 'S2-P01: sentinel reads %, not staging; refusing', coalesce(v_env, '<null>');
  end if;

  -- Drift guard: only PUBLIC, postgres and service_role may hold a privilege.
  -- An explicit anon/authenticated entry means a REVOKE FROM PUBLIC would not
  -- close the hole, so stop instead of half-fixing it.
  select p.proacl into v_acl
    from pg_proc p where p.oid = 'private.request_device_recovery(uuid,uuid)'::regprocedure;
  if exists (
    select 1 from aclexplode(coalesce(v_acl, acldefault('f',
             (select proowner from pg_proc
               where oid = 'private.request_device_recovery(uuid,uuid)'::regprocedure)))) a
     where a.grantee not in (0,
             'postgres'::regrole::oid,
             'service_role'::regrole::oid)
  ) then
    raise exception 'S2-P01: unexpected grantee on request_device_recovery; stop and re-baseline';
  end if;

  select p.proacl into v_acl
    from pg_proc p where p.oid = 'private.remote_session_transition_guard()'::regprocedure;
  if exists (
    select 1 from aclexplode(coalesce(v_acl, acldefault('f',
             (select proowner from pg_proc
               where oid = 'private.remote_session_transition_guard()'::regprocedure)))) a
     where a.grantee not in (0, 'postgres'::regrole::oid)
  ) then
    raise exception 'S2-P01: unexpected grantee on remote_session_transition_guard; stop and re-baseline';
  end if;
end $$;

-- 1.1 GRANT first: service_role keeps access at every instant of the change.
grant execute on function private.request_device_recovery(uuid, uuid) to service_role;

-- 1.2 REVOKE the inherited PUBLIC execute.
revoke all on function private.request_device_recovery(uuid, uuid) from public;

-- 1.3 Guard: owner only. No GRANT - a trigger does not check the invoker's
--     EXECUTE (PostgreSQL trigger semantics; siblings are postgres=X only).
revoke all on function private.remote_session_transition_guard() from public;

-- 1.4 Guard: add the missing private schema to search_path (F8, second half).
alter function private.remote_session_transition_guard()
  set search_path = public, private, pg_temp;

-- 1.5 IN-TRANSACTION POST-CHECKS. Expect the table in
--     docs/stage2/03-patch-S2-P01.md section 5. If any row differs, ROLLBACK;
--     do not COMMIT and "fix forward".
select p.oid::regprocedure as signature,
       p.proacl,
       p.proconfig,
       has_function_privilege('anon',          p.oid, 'EXECUTE') as anon,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated,
       has_function_privilege('service_role',  p.oid, 'EXECUTE') as service_role,
       has_function_privilege('postgres',      p.oid, 'EXECUTE') as postgres
  from pg_proc p
 where p.oid in ('private.request_device_recovery(uuid,uuid)'::regprocedure,
                 'private.remote_session_transition_guard()'::regprocedure)
 order by 1;

commit;
-- If the post-check above did not match, run:  rollback;
-- instead of commit, then investigate. The transaction is the safety net.


-- ===========================================================================
-- SECTION 2 - ROLLBACK. Deliberately commented out. Uncommenting is a
-- separate act requiring A10 and a recorded reason: it re-opens E2/F8.
--
-- Behaviour is restored, the ACL is NOT byte-identical: proacl becomes an
-- explicit {=X/postgres,...} instead of NULL. A catalogue UPDATE of pg_proc
-- is not proposed and is forbidden by the approval matrix.
-- ===========================================================================
-- begin;
-- grant execute on function private.request_device_recovery(uuid, uuid) to public;
-- grant execute on function private.remote_session_transition_guard() to public;
-- alter function private.remote_session_transition_guard()
--   set search_path = public, pg_temp;
-- -- The service_role grant may be left in place: it is a subset of PUBLIC
-- -- EXECUTE, so it changes no effective privilege. Removing it is optional
-- -- and adds a step without changing behaviour.
-- commit;
