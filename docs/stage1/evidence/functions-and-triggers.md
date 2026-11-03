# Evidence — Postgres functions, triggers, Edge Functions and security settings (dashboard-derived)

Source: Supabase dashboard, project `hhqgreaoqulmfwfwarhc`, read-only, 2026-10-29 ~15:45–16:05. No SQL executed, nothing deployed or modified.

All items here are **dashboard-observed**, captured before G1. Function bodies, trigger bodies, `search_path` settings and
grants were **not captured here**; they were captured by the G1 run the same day and live in
[g1-q3](g1-q3-20261029.json), [g1-q3b](g1-q3b-20261029.json), [g1-q7](g1-q7-20261029.json) and
[g1-q10](g1-q10-20261029.json). Bodies (`prosrc`) remain uncaptured by design (B3b).

> **Amendment — 2026-10-30 (B3b). Supersedes several statements below.** This file is kept as the pre-G1 dashboard note;
> the observed catalogue now says:
>
> - **38 functions, not 14.** `public` has the 14 RPC wrappers; `private` has 24 more (13 twins, `record_audit`, and 10
>   helpers/triggers). 34 of the 38 are `SECURITY DEFINER`; the four that are not are all trigger functions
>   (`private.audit_logs_append_only`, `families_before_update`, `profiles_before_update`, `set_updated_at`)
>   ([g1-b3b](g1-b3b-20261029.json)).
> - **14 bodies were read**, not zero: the five helpers named in the audit follow-up, all five trigger bodies,
>   `private.request_device_recovery`, `private.unlink_child` and two `public` bodies. 24 remain unread (PA3). Source:
>   [g1-b3b](g1-b3b-20261029.json) `bodies`.
> - **`search_path` is pinned on all 38.** Two omit `private`: `public.request_remote_session` and
>   `private.remote_session_transition_guard` (F5, F8). The "NOT VERIFIED" note in §1 below is superseded.
> - **`profiles_before_update` was read.** It rejects `role` changes only when `old.role <> 'unset'`, so the `'unset'`
>   bootstrap value bypasses the guard; `id` is immutable and `updated_at` is maintained (F3). The "behaviour NOT
>   VERIFIED" note in §2 is superseded.
> - **`audit_logs_append_only` was read.** It raises for non-privileged UPDATE/DELETE and returns `old` on DELETE; the
>   append-only claim is now behaviour-verified, not just trigger-existence.
> - **The child application id is VERIFIED** as `com.haven.familysafety` on `Haven-1.1-release.apk` and
>   `Haven-1.2-release.apk`; `Haven-1.0.apk` shares the package but not the signer or Capacitor config. See
>   [g2-apk-identity-20261030.md](g2-apk-identity-20261030.md). The "candidate only" note in §5 is superseded.
> - **Edge Functions are still unread** (PA1); §3 is unchanged and remains a source-form scan, not a review.

## 1. Postgres functions (14, all `SECURITY DEFINER`)

| Function | Arguments | Returns |
| --- | --- | --- |
| `apply_policy_version` | p_device_id uuid, p_policy jsonb, p_actor uuid, p_idempotency_key text | jsonb |
| `create_family_with_owner` | p_owner uuid, p_name text | jsonb |
| `create_pairing_invite` | p_child_user_id uuid, p_family_id uuid, p_parent_user_id uuid, p_code_hash text, p_expires_at timestamptz | jsonb |
| `create_pairing_request` | p_child_user_id uuid, p_family_id uuid, p_parent_user_id uuid, p_token_id uuid, p_expires_at timestamptz | jsonb |
| `detect_offline_devices` | — | integer |
| `expire_stale_commands` | p_device_id uuid | integer |
| `expire_stale_sessions` | — | integer |
| `poll_device_commands` | p_device_id uuid, p_limit integer default 20 | jsonb |
| `replace_device_apps` | p_device_id uuid, p_family_id uuid, p_apps jsonb | integer |
| `request_device_recovery` | p_device_id uuid, p_actor_user_id uuid | jsonb |
| `request_remote_session` | p_device_id uuid, p_parent_user_id uuid, p_kind text | remote_sessions (row type) |
| `respond_pairing_request` | p_request_id uuid, p_child_user_id uuid, p_approve boolean | jsonb |
| `revoke_device` | p_device_id uuid, p_actor_user_id uuid | jsonb |
| `unlink_child` | p_family_id uuid, p_child_user_id uuid, p_actor_user_id uuid | jsonb |

**What this tells us (design, not verification):** state transitions are implemented in the database, not in the Edge Function layer. Actor identity is passed explicitly as `p_actor` / `p_actor_user_id` / `p_parent_user_id` parameters, which means **the calling function must supply the identity from the verified JWT, never from the request body**. Whether every caller does that is a top-priority review item once the Edge Function source is exported (now blocked on a linked project and an owner credential, not on gate G1 — see PA1).

`SECURITY DEFINER` functions run with the owner's privileges, so each one must set a safe `search_path` and validate that the actor is authorised. Both are **NOT VERIFIED**. *(Superseded 2026-10-30: B3b read 14 bodies; all 38 functions pin a `search_path`, and the read predicates are `auth.uid()`-anchored. The actor-argument gap is F7 — see the amendment at the top.)*

## 2. Triggers (7, all `public` schema, all `BEFORE UPDATE/DELETE`, all row-level)

| Trigger | Table | Function | Events |
| --- | --- | --- | --- |
| `audit_logs_append_only` | audit_logs | `audit_logs_append_only` | BEFORE UPDATE, BEFORE DELETE |
| `devices_set_updated_at` | devices | `set_updated_at` | BEFORE UPDATE |
| `families_before_update` | families | `families_before_update` | BEFORE UPDATE |
| `families_set_updated_at` | families | `set_updated_at` | BEFORE UPDATE |
| `profiles_before_update` | profiles | `profiles_before_update` | BEFORE UPDATE |
| `remote_sessions_transition_guard` | remote_sessions | `remote_session_transition_guard` | BEFORE UPDATE |
| `safe_zone_states_set_updated_at` | safe_zone_states | `set_updated_at` | BEFORE UPDATE |

Findings:
- `audit_logs` is protected against UPDATE and DELETE at the trigger level — a real append-only control, not just a policy.
- A `profiles_before_update` trigger exists, which is the likely guard against self-escalation of `profiles.role`. **Behaviour NOT VERIFIED.**
- Session state transitions are guarded in the database rather than trusted to clients.
- The `profiles` table comment says rows are created by a trigger on `auth.users`; that trigger lives in another schema and is **not visible** in this view. Q3b later found exactly one: `on_auth_user_created` → `private.handle_new_user()`, `SECURITY DEFINER`, enabled ([g1-q3b](g1-q3b-20261029.json)).
- No trigger is visible on `pairing_requests`, `device_pairing_tokens` or `devices` for state transitions; those appear to be handled by the `SECURITY DEFINER` functions instead.

## 3. Edge Functions — source scan

Method: opened each function's Code tab and read the Monaco model in the page. Two functions show readable TypeScript; seven are served as **minified bundles** (2 lines), so identifier-based analysis under-reports their guards.

| Function | Source form | Guard identifiers found | catch blocks | `console.log` | Error-object leakage |
| --- | --- | --- | --- | --- | --- |
| pairing | readable, 972 lines | `requireUser`, `requireRole`, `requireVerifiedEmail`, `requireAction`, `assertFamilyParent`, `assertChildMembership`, `assertInviteQuotaAllowed`, `assertPairingCodeCreationAllowed`, `assertPairingRedeemAllowed`, `ensureContactId`, `ensureNoError` | 1 | 0 | yes (pattern match) |
| auth-bootstrap | readable, 140 lines | `requireUser`, `requireRole`, `requireVerifiedEmail`, `requireAction`, `ensureNoError` | 1 | 0 | no |
| device-command | minified | `requireVerifiedEmail` (visible only) | 4 | 0 | yes (pattern match) |
| device-register | minified | `requireVerifiedEmail` (visible only) | 4 | 0 | no |
| device-policy | minified | `requireVerifiedEmail` (visible only) | 4 | 0 | yes (pattern match) |
| device-telemetry | minified | none visible | 3 | 0 | no |
| family-admin | minified | `requireVerifiedEmail` (visible only) | 4 | 0 | yes (pattern match) |
| remote-session | minified | `requireVerifiedEmail` (visible only) | 4 | 0 | no |
| cron | minified | none visible; references a cron credential (`CRON_SECRET` / `x-cron` / `Authorization` present) | 3 | 0 | no |

Shared modules referenced by `pairing`: `_shared/audit.ts`, `_shared/auth.ts`, `_shared/cors.ts`, `_shared/envelope.ts`, `_shared/rate_limit.ts`, `_shared/validation.ts`. Their contents were **not readable** in this view (the editor only exposes the entry file), so the actual implementations of `requireUser` / `assertFamilyParent` / `requireRole` are **NOT VERIFIED**.

Evidence of activity: the `pairing` summary tile reports **1,756 invocations since last deploy, 0 errors**. The 4XX
percentage could not be read: the per-minute chart rendered no data points in a hidden browser surface, so treat the
error figure as a platform-reported summary, **not independently verified**. An "error" here also means an unhandled
failure, not a rejected request — a 4XX authorisation denial is counted as a successful invocation.

**Review status: PARTIAL.** The guard vocabulary is a good sign (named, layered, per-action authorisation, verified-email gate, rate-limit module), but a PASS cannot be issued for authentication, family scoping, input validation, service-role usage or sensitive-data exposure until the source is exported and read end to end. That requires a linked project (CLI link + `supabase functions download`, which needs the G3 owner credential) or the project repository.

## 4. Security and session settings observed

| Setting | Value | Plan note |
| --- | --- | --- |
| JWT access-token expiry | 3600 s (1 h) | |
| Refresh-token rotation | enabled (toggle on) | |
| Refresh-token reuse interval | 10 s | |
| Single session per user | off | Pro-plan only |
| Session time-box / inactivity timeout | 0 / 0 (disabled) | Pro-plan only |
| Connection pool size | 15 (shared pooler) | Nano default; fixed at 200 max clients |
| SSL enforcement | toggle present, state **NOT CAPTURED** | |
| Network restrictions | none — "database can be accessed by all IP addresses" | |
| Connection logging | toggles present, state **NOT CAPTURED** | |
| Network bans | none currently banned | |
| Storage buckets | none | |
| Data API | globally enabled; every table individually API-disabled | |

## 5. Child application package (from local artefact)

`C:\Users\ASUS\Downloads\Haven-1.2-release.apk` (also 1.0, 1.1 present) declares the application id **`com.haven.familysafety`** (activities: `MainActivity`, `HavenForegroundService`, `BootReceiver`, `ServiceRestartReceiver`, with a `fileprovider`).

This is a **candidate only** for the real Android `applicationId` needed by gate G2. It is **not authoritative**: the APK is a local build artefact, it was not verified against a repository or signing identity, and the package must be confirmed by the owner before any Firebase app registration. *(Superseded 2026-10-30: the package is VERIFIED on 1.1/1.2 — see the amendment at the top and [g2-apk-identity-20261030.md](g2-apk-identity-20261030.md). The source tree is still unavailable.)*
