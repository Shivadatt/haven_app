# Evidence — column inventory (dashboard-derived)

Source: Supabase Table Editor column pages, project `parent-control-prod` (`hhqgreaoqulmfwfwarhc`), read-only, 2026-10-29 ~15:40.
Method: page-level DOM read of the column list. **No SQL was executed.**

Verification grade: **INFERRED FROM DASHBOARD**. Column names, types and the constraint flags the dashboard renders (PRIMARY / FOREIGN KEY / UNIQUE / NULLABLE / NON-NULLABLE) are captured. **Not captured here:** default values, foreign-key target tables and delete rules, unique index definitions, check constraints, column grants, index definitions. Those require gate G1 and are listed in [08-test-matrix.md](../08-test-matrix.md) §0 (Q2–Q6). *(Superseded 2026-10-29: G1 was answered; defaults, foreign keys, checks, column grants and indexes are in [g1-q8](g1-q8-20261029.json), [g1-q5](g1-q5-20261029.json) and [g1-q6](g1-q6-20261029.json), with index definitions in [g1-q4](g1-q4-20261029.json). This file remains the pre-G1 dashboard transcription.)*

No row data was read or recorded.

## audit_logs

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NULLABLE |
| actor_user_id | uuid | FOREIGN KEY, NULLABLE |
| device_id | uuid | FOREIGN KEY, NULLABLE |
| event_type | text | NON-NULLABLE |
| target_type | text | NULLABLE |
| target_id | text | NULLABLE |
| metadata | jsonb | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |

## child_contact_ids

| Column | Type | Constraints | Note |
| --- | --- | --- | --- |
| child_user_id | uuid | PRIMARY, FOREIGN KEY, NON-NULLABLE | |
| contact_id | text | UNIQUE, NON-NULLABLE | Canonical Child ID. One per account, assigned once, never regenerated on launch. |
| created_at | timestamptz | NON-NULLABLE | |
| rotated_at | timestamptz | NULLABLE | |

## device_apps

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| package_name | text | NON-NULLABLE |
| label | text | NON-NULLABLE |
| is_system | bool | NON-NULLABLE |
| is_suspended | bool | NON-NULLABLE |
| version_name | text | NULLABLE |
| reported_at | timestamptz | NON-NULLABLE |

## device_commands

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| type | text | NON-NULLABLE |
| payload | jsonb | NON-NULLABLE |
| status | text | NON-NULLABLE |
| idempotency_key | text | NON-NULLABLE |
| created_by | uuid | FOREIGN KEY, NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| expires_at | timestamptz | NON-NULLABLE |
| delivered_at | timestamptz | NULLABLE |
| acked_at | timestamptz | NULLABLE |
| result | jsonb | NULLABLE |
| error_message | text | NULLABLE |
| attempts | int4 | NON-NULLABLE |

## device_pairing_tokens

| Column | Type | Constraints | Note |
| --- | --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE | |
| child_user_id | uuid | FOREIGN KEY, NON-NULLABLE | |
| code_hash | text | UNIQUE, NON-NULLABLE | |
| expires_at | timestamptz | NON-NULLABLE | |
| redeemed_at | timestamptz | NULLABLE | |
| redeemed_by | uuid | FOREIGN KEY, NULLABLE | |
| status | text | NON-NULLABLE | |
| attempts | int4 | NON-NULLABLE | |
| max_attempts | int4 | NON-NULLABLE | |
| created_at | timestamptz | NON-NULLABLE | |
| created_by | uuid | FOREIGN KEY, NULLABLE | |
| purpose | text | NON-NULLABLE | code = child-initiated short-lived secret; invite = server-minted for a Child ID invite. |

## device_policies

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| version | int4 | NON-NULLABLE |
| policy | jsonb | NON-NULLABLE |
| created_by | uuid | FOREIGN KEY, NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| acknowledged_at | timestamptz | NULLABLE |
| enforcement_status | text | NON-NULLABLE |
| last_error | text | NULLABLE |

## devices

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| child_user_id | uuid | FOREIGN KEY, UNIQUE, NON-NULLABLE |
| installation_id | text | NON-NULLABLE |
| display_name | text | NON-NULLABLE |
| platform | text | NON-NULLABLE |
| android_version | text | NULLABLE |
| app_version | text | NULLABLE |
| status | text | NON-NULLABLE |
| secret_hash | text | NULLABLE |
| credential_issued_at | timestamptz | NULLABLE |
| credential_revoked_at | timestamptz | NULLABLE |
| last_seen_at | timestamptz | NULLABLE |
| battery_level | int4 | NULLABLE |
| is_charging | bool | NULLABLE |
| enforcement_mode | text | NON-NULLABLE |
| policy_version | int4 | NON-NULLABLE |
| usage_access_granted | bool | NULLABLE |
| location_granted | bool | NULLABLE |
| background_location_granted | bool | NULLABLE |
| camera_granted | bool | NULLABLE |
| microphone_granted | bool | NULLABLE |
| notifications_granted | bool | NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| updated_at | timestamptz | NON-NULLABLE |

## families

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| name | text | NON-NULLABLE |
| owner_id | uuid | FOREIGN KEY, UNIQUE, NON-NULLABLE |
| settings | jsonb | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| updated_at | timestamptz | NON-NULLABLE |
| deleted_at | timestamptz | NULLABLE |

## family_members

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| user_id | uuid | FOREIGN KEY, UNIQUE, NON-NULLABLE |
| role | text | NON-NULLABLE |
| status | text | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| removed_at | timestamptz | NULLABLE |

## location_events

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| lat | float8 | NON-NULLABLE |
| lng | float8 | NON-NULLABLE |
| accuracy_m | float4 | NON-NULLABLE |
| recorded_at | timestamptz | NON-NULLABLE |
| received_at | timestamptz | NON-NULLABLE |
| source | text | NON-NULLABLE |

## pairing_attempts

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| parent_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| code_hash | text | NON-NULLABLE |
| attempted_at | timestamptz | NON-NULLABLE |
| success | bool | NON-NULLABLE |

## pairing_requests

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| token_id | uuid | FOREIGN KEY, UNIQUE, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| parent_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| child_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| status | text | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| expires_at | timestamptz | NON-NULLABLE |
| responded_at | timestamptz | NULLABLE |

## profiles

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, FOREIGN KEY, NON-NULLABLE |
| role | text | NON-NULLABLE |
| display_name | text | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| updated_at | timestamptz | NON-NULLABLE |

## remote_sessions

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| parent_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| child_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| kind | text | NON-NULLABLE |
| status | text | NON-NULLABLE |
| requested_at | timestamptz | NON-NULLABLE |
| accepted_at | timestamptz | NULLABLE |
| started_at | timestamptz | NULLABLE |
| ended_at | timestamptz | NULLABLE |
| expires_at | timestamptz | NULLABLE |
| ended_by | uuid | FOREIGN KEY, NULLABLE |
| ended_reason | text | NULLABLE |
| consent_recorded | bool | NON-NULLABLE |
| session_nonce | uuid | NULLABLE |
| created_at | timestamptz | NON-NULLABLE |

## safe_zone_states

| Column | Type | Constraints |
| --- | --- | --- |
| zone_id | uuid | PRIMARY, FOREIGN KEY, NON-NULLABLE |
| device_id | uuid | PRIMARY, FOREIGN KEY, NON-NULLABLE |
| inside | bool | NON-NULLABLE |
| updated_at | timestamptz | NON-NULLABLE |

## safe_zones

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| name | text | NON-NULLABLE |
| lat | float8 | NON-NULLABLE |
| lng | float8 | NON-NULLABLE |
| radius_m | float8 | NON-NULLABLE |
| active | bool | NON-NULLABLE |
| created_by | uuid | FOREIGN KEY, NULLABLE |
| created_at | timestamptz | NON-NULLABLE |

## safety_alerts

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| type | text | NON-NULLABLE |
| severity | text | NON-NULLABLE |
| message | text | NON-NULLABLE |
| payload | jsonb | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| acknowledged_at | timestamptz | NULLABLE |
| acknowledged_by | uuid | FOREIGN KEY, NULLABLE |

## usage_daily

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| device_id | uuid | FOREIGN KEY, NON-NULLABLE |
| family_id | uuid | FOREIGN KEY, NON-NULLABLE |
| day | date | NON-NULLABLE |
| package_name | text | NON-NULLABLE |
| app_label | text | NON-NULLABLE |
| total_ms | int8 | NON-NULLABLE |
| last_used_at | timestamptz | NULLABLE |
| uploaded_at | timestamptz | NON-NULLABLE |
| source | text | NON-NULLABLE |

## webrtc_signals

| Column | Type | Constraints |
| --- | --- | --- |
| id | uuid | PRIMARY, NON-NULLABLE |
| session_id | uuid | FOREIGN KEY, NON-NULLABLE |
| from_user_id | uuid | FOREIGN KEY, NON-NULLABLE |
| kind | text | NON-NULLABLE |
| payload | jsonb | NON-NULLABLE |
| created_at | timestamptz | NON-NULLABLE |
| sequence | int8 | NON-NULLABLE |

## Observations that affect earlier findings

1. **Device credential material is hashed** (`devices.secret_hash`, `device_pairing_tokens.code_hash`, `pairing_attempts.code_hash`) — single-value columns, no plaintext code column. Good sign; the hash algorithm and whether it is a slow KDF is **NOT CAPTURED**.
2. **Command acknowledgement exists** via `device_commands.acked_at`, `result`, `error_message`, `attempts`, plus a NOT NULL `idempotency_key`. There is no separate `command_acks` table, and one is not needed by this model.
3. **Policy acknowledgement exists** via `device_policies.acknowledged_at` / `enforcement_status`; `apply_policy_version` takes an idempotency key.
4. **Consent is partially modelled**: `remote_sessions.consent_recorded` (bool) exists, but there is no general consent record (no `consents` table, no consent version, no withdrawal timestamp).
5. **Push tokens have no home.** There is no FCM/device-token column in `devices` and no `push_tokens` table. This is the one clear gap for FCM.
6. **Location precision is raw**: `lat`/`lng` float8 + `accuracy_m` float4, with 1,773 rows and no retention marker. Minimisation/retention is a policy decision, not a schema rename.
7. **`safe_zone_states` has a composite primary key** (`zone_id`, `device_id`), which is why it needs no surrogate id, and `usage_daily` is keyed by `(device_id, day, package_name)` — both confirmed by Q4: `safe_zone_states_pkey` and `usage_daily_device_day_package_key` ([g1-q4](g1-q4-20261029.json)).
8. **`profiles` has a `role` column** writable by the owner of the row, with a `profiles_before_update` trigger present (see [functions-and-triggers.md](functions-and-triggers.md)). Whether the trigger blocks self-escalation is **NOT VERIFIED**.
