-- ===========================================================================
-- S2-P02 - E3/F7 actor binding + E1 remote-session auth + F5. PROPOSED - NOT APPLIED.
-- STAGING ONLY. Executor: postgres (owner). Originals: stage1 g1-b3b-20261029.json.
-- HONEST LIMIT: all current callers use service_role, where auth.uid() is NULL, so
-- actor_mismatch is INERT today; it only protects a future user-JWT/granted caller.
-- The E1 membership check does bite for service_role. Full E3 closure needs user-JWT
-- DB calls or acceptance of the Edge boundary. This is defence-in-depth, not a live fix.
-- NOT RUNNABLE BLINDLY: step 0 aborts unless set_config is uncommented after A5 approval; never touch the 11 unread private twins or public.unlink_child.
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


-- 0. APPROVAL GATE. Uncomment only in an approved staging window.
-- select set_config('haven.patch_gate', 'S2-P02', true);
do $$
begin
  if current_setting('haven.patch_gate', true) is distinct from 'S2-P02'
     or to_regprocedure('private.request_device_recovery(uuid,uuid)') is null
     or to_regprocedure('private.unlink_child(uuid,uuid,uuid)') is null
     or to_regprocedure('public.request_remote_session(uuid,uuid,text)') is null then
    raise exception 'S2-P02: gate or signatures missing; read parts/D-e3-f7-e1.md';
  end if;
end $$;

-- 1. private.request_device_recovery: guard only. plpgsql INFERRED from the
--    captured DECLARE/BEGIN text (Q7 does not cover the private schema).
create or replace function private.request_device_recovery(
  p_device_id uuid, p_actor_user_id uuid)
returns jsonb language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_device public.devices; v_result jsonb;
begin
  -- E3/F7. Service_role: auth.uid() IS NULL, so this is skipped by design.
  if auth.uid() is not null and p_actor_user_id is distinct from auth.uid() then
    raise exception 'actor_mismatch' using errcode = '42501';
  end if;
  select * into v_device from public.devices where id = p_device_id for update;
  if not found then raise exception 'device_not_found' using errcode = 'P0002'; end if;
  if p_actor_user_id is null or not exists (select 1 from public.family_members
    where family_id=v_device.family_id and user_id=p_actor_user_id and role='parent' and status='active')
  then raise exception 'forbidden' using errcode = '42501'; end if;
  v_result := private.unlink_child(v_device.family_id, v_device.child_user_id, p_actor_user_id);
  perform private.record_audit(v_device.family_id,p_actor_user_id,v_device.id,'device_recovery_started',
    'device',v_device.id::text,jsonb_build_object('child_user_id',v_device.child_user_id,
    'devices_revoked',v_result->>'devices_revoked','already_unlinked',coalesce((v_result->>'already_removed')::boolean,false)));
  return v_result || jsonb_build_object('recovery', 'started', 'old_device_id', v_device.id);
end;
$$;

-- 2. private.unlink_child: guard only. Child-self and parent paths unchanged;
--    the guard runs before the existing null/role checks.
create or replace function private.unlink_child(
  p_family_id uuid, p_child_user_id uuid, p_actor_user_id uuid)
returns jsonb language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_membership public.family_members; v_devices integer := 0; v_sessions integer := 0;
begin
  -- E3/F7. Inert for service_role; active for any user JWT.
  if auth.uid() is not null and p_actor_user_id is distinct from auth.uid() then
    raise exception 'actor_mismatch' using errcode = '42501';
  end if;
  if p_actor_user_id is null then raise exception 'forbidden' using errcode = '42501'; end if;
  if p_actor_user_id <> p_child_user_id then
    if not exists (
      select 1 from public.family_members where family_id=p_family_id
        and user_id=p_actor_user_id and role='parent' and status='active'
    ) then raise exception 'forbidden' using errcode = '42501'; end if;
  end if;
  select * into v_membership from public.family_members
   where family_id=p_family_id and user_id=p_child_user_id and role='child' for update;
  if not found then raise exception 'membership_not_found' using errcode = 'P0002'; end if;
  if v_membership.status = 'removed' then return jsonb_build_object('status','unlinked',
    'family_id',p_family_id,'child_user_id',p_child_user_id,'already_removed',true,'devices_revoked',0,'sessions_ended',0); end if;
  update public.family_members set status='removed', removed_at=now() where id=v_membership.id;
  update public.devices set status='revoked', secret_hash=null, credential_revoked_at=now()
   where family_id=p_family_id and child_user_id=p_child_user_id and status<>'revoked';
  get diagnostics v_devices = row_count;
  update public.remote_sessions set status='ended', ended_at=now(), ended_by=p_actor_user_id,
    ended_reason=coalesce(ended_reason,'member_unlinked')
   where family_id=p_family_id and child_user_id=p_child_user_id and status in ('requested','accepted','active');
  get diagnostics v_sessions = row_count;
  update public.device_pairing_tokens set status='revoked' where child_user_id=p_child_user_id and status='active';
  update public.pairing_requests set status='cancelled', responded_at=now() where child_user_id=p_child_user_id and status='pending_child';
  perform private.record_audit(p_family_id,p_actor_user_id,null,'member_removed','family_member',
    v_membership.id::text, jsonb_build_object('child_user_id',p_child_user_id));
  return jsonb_build_object('status','unlinked','family_id',p_family_id,'child_user_id',p_child_user_id,
    'already_removed',false,'devices_revoked',v_devices,'sessions_ended',v_sessions);
end;
$$;

-- 3. public.request_remote_session: guard + E1 membership check, preserving the
--    service_role argument path. Membership uses the device's family, not auth.uid().
--    search_path stays pre-patch here; F5 is separate so each change is reviewable.
create or replace function public.request_remote_session(
  p_device_id uuid, p_parent_user_id uuid, p_kind text)
returns public.remote_sessions language plpgsql security definer
set search_path = public, pg_temp as $$
declare v_device public.devices; v_session public.remote_sessions;
begin
  -- E3/F7. Inert for service_role; active for any user JWT.
  if auth.uid() is not null and p_parent_user_id is distinct from auth.uid() then
    raise exception 'actor_mismatch' using errcode = '42501';
  end if;
  if p_kind is null or p_kind not in ('audio','video') then raise exception 'invalid_kind'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_device_id::text,0));
  select * into v_device from public.devices where id=p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.status <> 'active' then raise exception 'device_not_active'; end if;
  -- E1: claimed parent must be active in this device's family (binds the argument).
  if p_parent_user_id is null or not exists (select 1 from public.family_members m
    join public.families f on f.id=m.family_id
    where m.family_id=v_device.family_id and m.user_id=p_parent_user_id
      and m.role='parent' and m.status='active' and f.deleted_at is null)
  then raise exception 'forbidden' using errcode='42501'; end if;
  update public.remote_sessions set status='expired', ended_at=now(), ended_reason='expired'
   where device_id=p_device_id and status='requested' and expires_at is not null and expires_at <= now();
  if exists (select 1 from public.remote_sessions where device_id=p_device_id
      and status in ('requested','accepted','active'))
  then raise exception 'session_in_progress' using errcode='P0001'; end if;
  insert into public.remote_sessions (family_id,device_id,parent_user_id,child_user_id,kind,status,
    requested_at,expires_at,consent_recorded)
  values (v_device.family_id,v_device.id,p_parent_user_id,v_device.child_user_id,p_kind,'requested',
    now(),now()+interval '10 minutes',false)
  returning * into v_session;
  return v_session;
end;
$$;

-- 4. F5: add private to search_path. All public objects are qualified; current behaviour is unchanged.
alter function public.request_remote_session(uuid, uuid, text)
  set search_path = public, private, pg_temp;

-- 5. POSTCHECKS (read-only). Expect prosecdef=true and proconfig public,private,
--    pg_temp on all three; ACL unchanged (replace keeps it).
select p.oid::regprocedure as signature, p.prosecdef, p.proconfig, p.proacl
  from pg_proc p
 where p.oid in ('private.request_device_recovery(uuid,uuid)'::regprocedure,
                 'private.unlink_child(uuid,uuid,uuid)'::regprocedure,
                 'public.request_remote_session(uuid,uuid,text)'::regprocedure)
 order by 1;
commit;
