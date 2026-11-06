# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 PAIRING & REGISTRATION CONTRACT

**Scope**: Child registration + pairing contract (local, deterministic) — Stage 2 module B
**Date**: November 6, 2026
**Status**: **DRAFT — NOT APPROVED.** Every row marked `⚠ D-3` or `⚠ D-5` is a placeholder that becomes binding only when the owner signs [STAGE_2_DECISION_PROPOSAL.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_DECISION_PROPOSAL.md). Implementation of this contract is **NOT STARTED**.
**Ladder ceiling for this document**: level 2 (Flutter logic). Nothing here reaches level 3+ and nothing here is a real pairing.
**Governing rules**: `Result<T>` everywhere, `blocked(...)` for unspecified behavior, no invented tables/RPCs, ≤200 hand-written lines per file ([00-app-contract.md](file:///d:/control/docs/implementation/00-app-contract.md#L10-L18))

---

## 1. What this contract is, and what it is emphatically not

| It IS | It is NOT |
| :--- | :--- |
| A deterministic, pure-Dart state machine for the pairing/registration lifecycle | A redemption protocol |
| A contract that can be unit-tested without a network, a device or a clock | Evidence that any parent is connected |
| A local record of what the child device knows about itself | A cross-device synchronization design |
| A specification of failure states so the UI can be truthful | A backend behavior change |
| An authorisation-shaped contract ready to plug into Phase 4 | Phase 4 |

**The single hard rule.** No transition in this machine may produce a state that reads as "paired with a parent" unless a verified transport delivered that fact. The state `blocked_pending_transport` exists precisely so that "correctly specified, deliberately not connected" is representable without a lie. `⚠ D-5`

## 2. Vocabulary reconciliation — proposed vs what exists today

The Stage 2 brief lists twelve states. Here they are mapped onto what the repository already has, because a contract that ignores existing wire enums is a second, incompatible vocabulary.

| Brief state | Exists today? | Where / what it maps to | Note |
| :--- | :--- | :--- | :--- |
| `not_started` | no | new | the machine's initial state |
| `code_created` | partially | simulation: `SimulatedPairingSession` exists but is modelled as three booleans ([simulation_models.dart:16-24](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/simulation_models.dart#L16-L24)) | the boolean triple permits impossible combinations — see §5 |
| `waiting_for_child` | yes | `PairingRequestStatus.pendingChild` = `pending_child` ([enums_identity.dart:75-89](file:///d:/control/packages/haven_models/lib/src/enums_identity.dart#L75-L89)) | reuse the wire label, do not invent one |
| `redeem_attempted` | yes (as a row, not a state) | `pairing_attempts` table, `PairingAttempt` model ([pairing_models.dart:167-189](file:///d:/control/packages/haven_models/lib/src/pairing_models.dart#L167-L189)) | a *fact about an attempt*, not a machine state; keep them distinct |
| `redeemed_locally` | no | new | explicitly labelled local demonstration `⚠ D-5` |
| `expired` | yes | `PairingTokenStatus.expired` / `PairingRequestStatus.expired` ([enums_identity.dart:60-89](file:///d:/control/packages/haven_models/lib/src/enums_identity.dart#L60-L89)) | reuse |
| `invalid` | no | new; backend expresses it as an HTTP 400 `invalid_code`, never as a stored status ([pairing/shared.ts:25-28](file:///d:/control/backend/supabase/functions/pairing/shared.ts#L25-L28)) | `⚠ D-3` anti-enumeration |
| `attempt_limit_reached` | no | new; derived today from an inert counter ([redeem.ts:73](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L73)) | `⚠ D-3` |
| `already_used` | yes (as a 409) | `code_unavailable` ([redeem.ts:106-115](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L106-L115)) + `PairingTokenStatus.redeemed` | reuse the token status as the evidence |
| `cancelled` | yes | `PairingRequestStatus.cancelled`; `PairingTokenStatus.revoked` | two enums, one meaning — see §4 |
| `unpaired` | partially | `private.unlink_child` sets `devices.status='revoked'`, requests `'cancelled'`, tokens `'revoked'` ([unlink.ts:102-106](file:///d:/control/backend/supabase/functions/pairing/unlink.ts#L102-L106)) | no Dart state exists |
| `blocked_pending_transport` | no | new | the D-5 truthfulness state |

**Reconciliation verdict**: 6 of 12 states already have a wire representation; 6 are new. The contract therefore extends `enums_identity.dart`'s conventions (lowerCamelCase members, snake_case `wire` labels, `matchWire`) rather than creating a parallel string vocabulary. Nothing in this table may be added to a shared enum until D-3/D-5 are approved, because these enums trace to database CHECK constraints (`docs/stage2/migrations/A3-staging-load-v1.sql:451`, `:477`) and a Dart-only value would be an invented contract.

## 3. State machine (PROPOSED)

```
                         ┌────────────────────────┐
                         │      not_started       │
                         └───────────┬────────────┘
                                     │ createCode()          [local lane only]
                                     ▼
                         ┌────────────────────────┐
        cancel() ←────── │      code_created      │
        expire() ←────── └───────────┬────────────┘
                                     │ handOff()  ⚠ D-5 (no transport exists)
                                     ▼
                         ┌────────────────────────┐
                         │     waiting_for_child  │ ← pending_child
                         └───────────┬────────────┘
                                     │ redeem(code)
                          ┌──────────┼───────────┬───────────────┐
                          ▼          ▼           ▼               ▼
                    ┌──────────┐ ┌────────┐ ┌──────────────┐ ┌───────────────┐
                    │ redeemed │ │invalid │ │   expired    │ │ attempt_limit │
                    │ _locally │ └────────┘ └──────────────┘ │   _reached    │
                    └────┬─────┘                              └───────┬───────┘
                         │ unpair()                                   │ createCode()
                         ▼                                            ▼
                    ┌──────────┐                              (a new code, not a revive)
                    │ unpaired │
                    └──────────┘

        Any state  ──cancel()──▶  cancelled ──(terminal for that code)
        blocked_pending_transport ⟵ reachable from code_created / waiting_for_child
                                    whenever no approved transport is installed  ⚠ D-5
```

### 3.1 Transition table

| From | Event | To | Guard | Audit record |
| :--- | :--- | :--- | :--- | :--- |
| `not_started` | `createCode` | `code_created` | format valid for the lane `⚠ D-3` | yes |
| `code_created` | `expire` (clock) | `expired` | `clock.isPast(expiresAt)` | yes |
| `code_created` | `cancel` | `cancelled` | — | yes |
| `code_created` | `handOff` | `waiting_for_child` | **only** if a transport is installed — none is | yes |
| `code_created` | `handOff` with no transport | `blocked_pending_transport` | always, today | yes |
| `waiting_for_child` | `redeem` with matching, live, unused code | `redeemed_locally` | `!expired && status==active && !used` | yes |
| `waiting_for_child` | `redeem` malformed | `invalid` | shape check fails | yes |
| `waiting_for_child` | `redeem` after `expiresAt` | `expired` | clock | yes |
| `waiting_for_child` | `redeem` on a used code | `already_used` | prior redemption record exists | yes |
| `waiting_for_child` | Nth failed attempt | `attempt_limit_reached` | limit = `⚠ D-3` (backend *specified* value 10, unenforced today) | yes |
| `waiting_for_child` | `cancel` | `cancelled` | — | yes |
| `redeemed_locally` | `unpair` | `unpaired` | — | yes |
| `expired` / `invalid` / `already_used` / `attempt_limit_reached` | `createCode` | `code_created` | a **new** code object with a new id; the old one is never revived | yes |
| any | any unlisted event | — | **no implicit transition**: an unlisted `(state, event)` pair returns `Err(ValidationFailure)` | n/a |

### 3.2 Forbidden transitions (must be unrepresentable, not merely unhandled)

- `expired → redeemed_locally` — no reuse of an expired code.
- `already_used → redeemed_locally` — no duplicate redemption.
- `blocked_pending_transport → redeemed_locally` or `→ waiting_for_child` without a transport interface being supplied — **this is the "no fake parent connection" rule expressed as an executable assertion.**
- `attempt_limit_reached → waiting_for_child` for the same code id.
- any transition that does not append an audit record.

## 4. Naming collision to resolve before code `⚠ D-3`

Two existing enums both mean "the parent stopped being able to use this": `PairingTokenStatus.revoked` (label `revoked`, UI "Cancelled") and `PairingRequestStatus.cancelled`. Meanwhile `PairingTokenStatus.cancelled` does not exist, so a cancelled *token* is called `revoked` while a cancelled *request* is called `cancelled`. The contract proposes to keep both wire labels (they are DDL-bound) and define **one** machine event `cancel()` that sets request→`cancelled` and token→`revoked` together, exactly as `unlink.ts:102-106` does today.

## 5. Model

| Element | Rule |
| :--- | :--- |
| Representation | a `sealed class` with one subclass per state, **not** a nullable-boolean triple. Today's `isRedeemed`/`isCancelled`/`isExpired` permits `redeemed && cancelled` ([simulation_models.dart:16-24](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/simulation_models.dart#L16-L24)); the machine must make that unrepresentable |
| Identity | stable `codeId` and `requestId`; a regenerated code gets a new id, never a mutated one |
| Clock | `Clock` injected ([clock.dart:2-40](file:///d:/control/packages/haven_core/lib/src/clock.dart#L2-L40) — `FixedClock` already exists and is exported). **No `DateTime.now()` inside the machine.** Seven pairing sites currently call it inline; they are the migration target |
| Expiry | a named constant per lane, not an inline `Duration(minutes: 5)`; value `⚠ D-3` |
| Attempts | counter owned by the machine, incremented by the machine on every failed `redeem`, limit `⚠ D-3` — note this **repairs in the local contract what the backend leaves inert** ([redeem.ts:73](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L73) reads `attempts` that nothing writes) |
| Format | supplied as `PairingCodeFormat`, never defaulted; with no format the machine returns `blocked(pairingCodeRuleGap)` exactly as the unexported validator does ([pairing_code.dart:84-96](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L84-L96)) |
| Normalisation | one rule shared with the backend `⚠ D-3`; today Dart strips `' ' - — _` and the backend strips `\s -` only — these disagree |
| Persistence | local only, via the existing `FileLocalStore` engine; `device_pairing_tokens` and `pairing_attempts` have **no local representation today** ([local_schema.dart:80](file:///d:/control/packages/haven_api/lib/src/offline/local_schema.dart#L80) registers `pairingRequests` only), so a redemption record cannot be persisted without a schema addition — and no new table/column may be invented |
| Errors | `Result<T>` + `HavenFailure`; `ValidationFailure(field:'pairing_code')` for shape, `BlockedFailure` for unapproved behavior, `UnknownFailure` never as a catch-all for a missing decision |
| Audit | every allowed transition appends `{codeId, from, to, event, at: clock.now(), lane}`; `lane` is `local_demonstration` and is required so a local record can never be mistaken for device evidence `⚠ D-5` |

## 6. Duplicate, expired, invalid, unpair scenarios (normative examples)

| Scenario | Sequence | Required outcome | Required UI statement |
| :--- | :--- | :--- | :--- |
| Duplicate redemption | `redeem(c)` → success; `redeem(c)` again | second call → `already_used`, first success never repeated | "This code has already been used." |
| Expired code | `createCode`; advance clock past `expiresAt`; `redeem` | `expired`; **never** `redeemed_locally`, even if the code matches | "This code is no longer valid." |
| Expired then re-issued | `expired`; `createCode` | new `codeId`, `code_created`; the old row stays `expired` | fresh countdown, no reuse |
| Invalid shape | `redeem('abc')` under a digits lane | `invalid` before any lookup | shape message, not "not found" |
| Unknown vs expired | network-facing surface | identical message and identical code `⚠ D-3` (mirrors `pairing/shared.ts:23-28`) | one message for both |
| Attempt limit | N failures | `attempt_limit_reached`; further `redeem` calls are refused without incrementing | "Too many attempts." |
| Unpair | `redeemed_locally` → `unpair` | `unpaired`; token→revoked semantics, local session cleared | "Not connected", "Not registered" |
| No transport | any `handOff` | `blocked_pending_transport` with `BlockedFailure` | **"Parent connection: Not connected"** — already the shipped constant ([child_local_session.dart:23](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart#L23)) |

## 7. Parent-child compatibility contract (child ↔ parent ↔ backend)

| Dimension | Parent simulation | Child app | Backend | Contract verdict |
| :--- | :--- | :--- | :--- | :--- |
| Code shape | 6 digits | nothing today | 8 of 30 `⚠ D-3` | two named lanes, or no redemption |
| TTL | 5 min | n/a | 10 min | `⚠ D-3` |
| Role that generates | parent device (simulation) | — | **child** role ([issuance.ts:67](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L67)) | the simulation inverts the real role model — must be labelled |
| Role that redeems | parent device | — | **parent** role ([redeem.ts:32](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L32)) | same |
| Storage | `haven_local.json` in the parent sandbox | own `haven_local.json` in `com.haven.child` | Postgres, hashed | separate sandboxes, no sync `⚠ D-5` |
| Connection truth | `SIMULATED DEVICE` label | `Not connected` / `Not registered` | n/a | **already correct; protect with tests** |

## 8. File plan (where approved code would go — no file exceeds 200 lines)

| Path | Content | New/changed |
| :--- | :--- | :--- |
| `packages/haven_models/lib/src/pairing_state.dart` | sealed state classes + transition table | new |
| `packages/haven_models/lib/src/pairing_models.dart` | `PairingAttempt` gains the local redemption record fields if approved | change (189 lines today — close to the ceiling, so the machine must be split out) |
| `packages/haven_core/lib/src/pairing_code.dart` | lane presets, shared normalisation, charset member | change `⚠ D-3` |
| `packages/haven_core/lib/haven_core.dart` | `export 'src/pairing_code.dart';` | change `⚠ D-3` |
| `apps/haven_child/lib/features/pairing/` | child-side machine use (new feature dir, route-aligned per Stage 1 convention) | new |
| `apps/haven_app/lib/features/device_pairing/data/pairing_machine_service.dart` | machine adapter for the parent | new |
| `test/**` | see [STAGE_2_TEST_STRATEGY.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_TEST_STRATEGY.md) | new |

## 9. Open items that block implementation

| # | Item | Owner decision |
| :--- | :--- | :--- |
| 1 | Code shape, TTL, attempt limit, single-use, normalisation | **D-3** |
| 2 | Whether `blocked_pending_transport` is a real state or a doc-only statement | **D-5** |
| 3 | Whether local audit records may be written at all, and their label | **D-5** |
| 4 | Whether a local redemption may be persisted, given no local `device_pairing_tokens` table exists | **D-3 + schema** |
| 5 | Whether `PairingRequestStatus`/`PairingTokenStatus` may gain Dart-only values (they trace to DDL CHECKs) | **D-3** |
| 6 | Whether the three-boolean simulation model may be replaced (it is Phase 1/2 code) | **owner, Phase 1/2 edit** |

**Status of this document: DRAFT / PROPOSED. Status of the implementation it describes: NOT STARTED, blocked on D-3 and D-5.**
