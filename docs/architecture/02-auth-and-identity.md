# 02 — Auth and identity

## 1. The one switch, and where the truth comes from

`backend/supabase/functions/_shared/identity.ts:53` fixes the mode:

```ts
export const IDENTITY_MODE: IdentityMode = "supabase-auth";   // :51 defines the union
```

`IdentityMode` is `"supabase-auth" | "firebase-uid"`. The named type is a **port-time correction**:
the lane originally used `typeof IDENTITY_MODE`, which narrowed to the single initialised literal and
made `emailVerifiedFor`'s firebase branch an impossible comparison under `deno check`. That was the
first time any of this TypeScript had ever been type-checked (`identity.ts:44-50`).

Three rules the file states and the code enforces (`identity.ts:37-40`):

1. **Cutover is one edit** — flip `IDENTITY_MODE` and replace the body of `resolveFirebaseIdentity`.
2. **No other file in the package reads an actor id.** Everything downstream takes an `Actor`.
3. **A client-supplied UID is never authoritative** and never establishes parent-child ownership in
   either mode. In the app, the Firebase-identity sign-in path is refused outright
   (`packages/haven_api/lib/src/supabase_user_auth.dart:90-96`, returning
   `blocked('A13 unsigned + firebase_identity_mapping not loaded + profile provisioning gap')`).

The `firebase-uid` branch **fails closed by design**: instrument A13 is
`DECIDED — INSTRUMENT PREPARED, FENCE UNSIGNED`, the staging Third-Party Auth provider list is empty,
the mapping (`M-B`, authored as `docs/stage2/migrations/A3d-firebase-identity-mapping.sql`,
`PREPARED — NOT EXECUTED`) does not exist in the database, and no evidenced action provisions a
profile from a Firebase identity (`identity.ts:30-36`, citing `S2-A1-auth-architecture.md:503`,
`S2-EXEC-06 §3`, `S2-EXEC-08 §2(4)`). Flipping the mode early closes with **503** rather than opening
a path (`identity.ts:120`, `:137`).

## 2. The two authentication channels in the backend

| Channel | Carried by | Verified by | Used by |
| --- | --- | --- | --- |
| **User JWT** | `Authorization: Bearer …` (`bearerToken`, `identity.ts:67`) | `db.auth.getUser(token)` — the whole of authentication in this lane (`_shared/identity.ts:86`, recorded in `backend/supabase/tests/stub_db.ts`'s auth seam) | `auth-bootstrap`, `pairing`, `device-policy`, `device-register`, `family-admin`, `remote-session` |
| **Device credential** | `x-device-id` + `x-device-secret` headers | SHA-256 of the secret compared constant-time to the stored `secret_hash`, then a family-scope read | `device-command` (`poll`/`ack`), `device-telemetry` |
| Shared secret | `x-cron-secret` | SHA-256 both sides, constant-time, case-insensitive; **< 16 chars ⇒ `503 cron_not_configured`** | `cron` |

`requireUser` (`_shared/auth.ts:109`) returns `{ auth: Actor; db: DbClient; profile: { role: string } }`
— the profile row is what carries the role, so a token alone never grants anything.
`requireRole(profile, "parent" | "child")` (`auth.ts:122`) is the only role gate; tested behaviour is
that `"parent"` passes and `child`/`unset`/`"Parent"`/`""` all yield `403 role_required`
(`backend/supabase/tests/auth_roles_test.ts`).

`verify_jwt` at the gateway is **NOT CAPTURED for any slug** — the capture has no such field, so the
dashboard value must be read before deploying; the expectation column in
`docs/stage2/functions/DEPLOYMENT-MAP.md` §2 is derived from the captured auth channels, not observed.
Auth is in-handler on every channel regardless.

## 3. Authorisation guards (the `_shared` layer)

| Guard | File | Refuses |
| --- | --- | --- |
| `assertFamilyParent` / `assertFamilyChild` / `assertFamilyMember` | `_shared/auth.ts` | a membership row of the wrong role, a soft-deleted family, a caller from another family → `403 forbidden` |
| `assertFamilyOwner` | `_shared/auth.ts` | non-owner → `403 owner_required` |
| `requireActiveDeviceForParent` | `_shared/device_authority.ts:26` | a device outside the caller's family, or a non-`active` device |
| `requireDevice` | `_shared/device_authority.ts:57` | bad credential → `401 invalid_device_credentials`; a revoked credential row is refused |
| `recordAudit` | `_shared/audit.ts` | any audit write failure → `500 audit_failed` (the mutation does not silently succeed) |
| quota + rate-limit helpers | `_shared/quotas.ts`, `_shared/rate_limit.ts` | pairing over-limit → `429` with numeric `retry_after_seconds` |

Two preserved weaknesses are **asserted by tests rather than fixed**, because the captured bundle
behaves that way and silently changing enforcement is not this project's call:

- **E4** — pending remote sessions stack (`backend/supabase/tests/handlers_test.ts` pins two
  `remote_sessions.insert` calls).
- **E7** — no attempt counting / no lockout on the device-credential channel; a wrong secret and an
  unknown id return byte-identical responses (`tests/guards_test.ts` pins `[401,
  "invalid_device_credentials", message]` equality for both).

## 4. What is NOT true about auth today

- There is **no login in staging**. `auth-bootstrap` is not deployed, so nothing can set a role, and
  no profile rows exist to read (`docs/stage2/functions/DEPLOYMENT-MAP.md` §1: 0 tables).
- The Firebase bridge is **not configured**: `haven-staging` has no Auth provider enabled and no
  registered app (`docs/stage2/S2-A2-firebase-console-audit.md:216-217`, and
  [`backend/firebase/SETUP.md`](../../backend/firebase/SETUP.md) §1).
- The device credential path cannot be exercised: no `devices` rows exist, and
  `device-register`/`device-command` are not deployed.
- `register-token`, `send-push`, `verify-firebase-token` and `notification-cron` **do not exist** and
  are forbidden as references (`docs/stage2/S2-A4-edge-functions-audit.md:171-177`;
  `packages/haven_api/lib/src/backend_endpoints.dart:150-156`).
- Every one of these decisions is verified only **offline**: the 82 Deno tests assert the re-authored
  logic matches its own documented contract, and reproduce the *decision* behind a `15-*` case id,
  never the case itself (`backend/supabase/tests/README.md` §1).

Related: [03-data-and-backend-contract.md](03-data-and-backend-contract.md) ·
[04-refusal-model.md](04-refusal-model.md) ·
[`docs/stage2/S2-A1-auth-architecture.md`](../../docs/stage2/S2-A1-auth-architecture.md)
