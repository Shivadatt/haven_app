# S2-EXEC-08 — Identity-authority decision record and final `A13` wording

| Field | Value |
| --- | --- |
| Date | 2026-11-03 |
| Purpose | Discharge the brief's §3 requirement: *"Prepare the exact replacement approval wording and owner authorization record."* |
| Decisions captured | Two owner selections made in-session, reproduced verbatim in §1 |
| Authority of this file | It **prepares** the instrument. It does not sign it. The `A13` fence in §4 is blank, and per §3 of the brief the identity change **must not be executed** until that fence is formally signed by the owner |
| Targets | Supabase `parent-control-staging` / `dzonzgngwxclhfnvxtvu` · Firebase `haven-staging` / `haven-staging-46822`. Production `parent-control-prod` / `hhqgreaoqulmfwfwarhc` appears nowhere in this file as a target and was not contacted |
| Cloud operations performed for this file | **Zero.** All configuration values below are read from the live *staging* dashboards during the observation walk recorded in [`S2-EXEC-06`](file:///D:/control/docs/stage2/S2-EXEC-06-live-staging-observation-2026-11-03.md) |
| Terminal / CLI / REST used | None. No shell command, no hash computation, no API call |
| Secrets | None. The values in §3 are public identifiers (project ID, OIDC issuer, Google's published JWKS endpoint). No key, token or account address appears here |

---

## 1. Decisions as recorded

Asked which authority wins between Firebase Auth and the already-enabled Supabase Auth email provider, the owner selected:

> **Third-Party Auth bridge** — *"Register Firebase as an external JWT issuer on Supabase's Third-Party Auth page (currently empty, browser-only, no CLI). Supabase stays the single session authority and verifies Firebase-issued tokens; the Firebase UID maps to one Supabase profile."*

Asked what to do about the 7 of 9 Edge Functions that exist only as minified bundles, the owner selected:

> **Re-author, labelled** — *"each function permanently labelled 'NO PARITY VERIFICATION' … gaps return a 'not deployable without spec' verdict rather than invented logic."*

The second decision is recorded here too because it changes what `A7-R`/`A8-R` authorise, but the implementation agent producing those sources (IMP-5) was already dispatched under exactly that labelling rule, so no instrument edit is needed for it.

**Status vocabulary for the first decision:** `DECIDED — INSTRUMENT PREPARED, FENCE UNSIGNED`. It is not `APPROVED`, and nothing in §5 may run until it is.

### 1a. Three further owner selections, 2026-11-03, recorded in the same session

Asked alongside the Phase 2 approval audit, the owner made three more selections. They are decisions about **sequencing**, not approvals, and none of them signs a fence.

| # | Question asked | Owner's selection | What it changes in this file |
| --- | --- | --- | --- |
| D-1 | How the fences get signed | **"I edit the files myself"** | No agent transcribes any signature line. The `A13` fence in §4 below stays blank until the owner's own hand fills it. A consolidation offer was declined, so the signature targets are exactly two files: this one (§4) and `approval-package-v3-implementation-instruments.md` |
| D-2 | How to close the §2(4) profile-provisioning gap | **"Defer the cutover"** — load schema and mapping first, leave Supabase's Email provider enabled, leave Firebase Auth untouched | **§5's step 5 HOLD is now the ratified plan, not a suggestion.** Steps 2–4 may proceed once `A13` is signed; step 6 stays gated behind the schema load *and* an explicitly approved provisioning implementation. Two rejected alternatives are recorded for the audit trail: authorising a new `claim`/`ensure_profile` action on `auth-bootstrap` under `A7-R`, and operator pre-seeding of mapping rows via the Table Editor |
| D-3 | Whether `A9` authorises generating an Admin SDK private key now | **"Defer A9 until the schema is loaded"** | No key generation on `firebase-adminsdk-fbsvc@haven-staging-46822.iam.gserviceaccount.com`. Consequence the owner should hold in mind: with no credential, **no FCM send can be verified**, so the notification queue, retry, dedupe and token-ownership logic can be built and reviewed but nothing reaches `VERIFIED` status for actual delivery |

Net effect on the critical path: **Phase 3 (Supabase schema) is now the only phase with nothing deferred by the owner**, and it is blocked solely by two unsigned fences — `A2′(a)` and `A3`. Phases 4 and 5 are postponed by owner decision, not by missing evidence.

---

## 2. What the bridge actually implies — six consequences, three of them unwelcome

Choosing "Supabase verifies Firebase-issued JWTs" is not a small edit. Read against the captured evidence, it has these effects:

**(1) Firebase Authentication still has to be enabled.** The bridge does not avoid the Firebase-Auth approval; Firebase is the party *issuing* the tokens Supabase will verify. What the bridge changes is which system is the session and authorization authority. `A12-R` remains a prerequisite for a working login path, and Firebase Auth's "Get started" screen stays where it is until `A13` is signed and executed.

**(2) Supabase's own Email provider must be disabled at cutover, and open sign-ups with it.** Today it is ENABLED with "Allow new users to sign up" ON and "Confirm email" ON (§3 of `S2-EXEC-06`). Leaving it on is the two-authority condition the brief forbids. This is a *disable* action on a live staging project, so it belongs in the cutover sequence with a rollback step, not in a footnote.

**(3) `requireVerifiedEmail` becomes unsatisfiable as written.** `_shared/auth`'s verified-email check is evidenced in the capture against Supabase's own confirmation state — `auth-bootstrap` is recorded as *"user JWT + verified email"* with `requireUser(requireVerifiedEmail)` at `capture-20261030.json:50`, `:38` [1](#fn-cite). Under a Firebase-issued token the verified signal is Firebase's `email_verified` claim. The check must move behind one named seam in `_shared/auth` so that both readings exist and exactly one is active — IMP-5 was instructed to build precisely this seam.

**(4) There is no evidenced action that provisions a profile from a Firebase identity, and the DB trigger cannot do it instead.** `handle_new_user` is an `AFTER INSERT` trigger on `auth.users`. A third-party JWT verified against Supabase does not insert an `auth.users` row, so the trigger never fires, so no `profiles` row is ever created — and every evidenced function keys ownership off `auth.user.id` (`device-command` `:67`, `device-register` `:82`, `auth-bootstrap` `:53-54`). The capture records `auth-bootstrap`'s actions as exactly `["set_role","create_family"]` (`:49`); **there is no `claim`/`ensure-profile` action in the evidence.** Adding one is a behaviour change to a captured function, which the brief's source-review rule and §4's "do not invent business logic" both forbid doing silently. It must be an explicit, separately-approved addition. This is the single hardest dependency the bridge creates and it is not currently in any instrument.

**(5) Whether a third-party-verified JWT reaches PostgREST/RLS at all is NOT established by any evidence in this repository,** and this file does not assume that it does. The practical consequence is benign for the current design: all 9 Edge Functions use the service-role key and authorise internally, so the live data path never depended on `auth.uid()`, and RLS remains defence-in-depth rather than the primary gate (which is exactly finding S-1). Any code that *does* rely on `auth.uid()` — including the 4 policies that can be emitted without the missing functions — must be re-checked after the bridge is live, not before.

**(6) The mapping store is already designed; the bridge needs it, not a new column.** The mapping is `M-B` in [`S2-A1-auth-architecture.md:503`](file:///D:/control/docs/stage2/S2-A1-auth-architecture.md#L503) — `(provider, firebase_uid) UNIQUE → supabase_user_id`. `A3c-notification-backend.sql:1138` records a deliberate decision **not** to duplicate `firebase_uid` into the notification tables. That decision stays correct under the bridge, and no new column should be introduced elsewhere.

---

## 3. Exact replacement wording for the ratified architecture

The ratified sentence is a row of the approved-components table at
[`docs/stage2/01-staging-project-proposal.md:201`](file:///D:/control/docs/stage2/01-staging-project-proposal.md#L201).
It currently reads, verbatim:

```
| 6 | **Not in the approved architecture** | Firebase Auth / Firestore / Cloud Functions | `OUT OF SCOPE` — must not be enabled |
```

`A13` replaces **only that row**. Row 1 (`Supabase Auth` as single identity authority, `:196`) is amended by a pointer,
not rewritten, so the ratification trail stays readable. Firestore and Cloud Functions keep their prohibition verbatim.

**Replacement row 6 (proposed text, to be transcribed into the fence only when signed):**

```
| 6 | **Identity issuer, superseded 2026-11-03 by A13** | Firebase Auth — as *token issuer only*, verified by Supabase Third-Party Auth; Firestore; Cloud Functions | Firebase Auth: `IN PROGRESS — A13 SIGNED, NOT YET EXECUTED`. It may issue tokens; it may NOT hold application records, sessions of record, or authorization state. Firestore and Cloud Functions: `OUT OF SCOPE` — must not be enabled (unchanged) |
```

**Amendment pointer appended to row 1 (`:196`), leaving its existing text intact:**

```
[SUPERSEDED IN PART by A13, 2026-11-03: Supabase Auth remains the session/authorization authority of record. Firebase becomes an external JWT issuer verified via Third-Party Auth. The Email provider and open sign-ups must be disabled at cutover; see docs/stage2/S2-EXEC-08-identity-decision-A13-final.md §2.]
```

**Third-Party Auth values to enter (all public, none secret):**

| Field | Value |
| --- | --- |
| Provider type | External JWT / third-party auth provider (Supabase dashboard → Authentication → Third-Party Auth → "Add provider") |
| Issuer | `https://securetoken.google.com/haven-staging-46822` |
| Audience | `haven-staging-46822` |
| JWKS | Google's published identity-toolkit key set for the project number `381273275501`, as offered by the dashboard's provider form — the URL is not transcribed here because it must be taken from the dashboard's own field, not from memory |
| Subject claim → user identity | `sub` (the Firebase UID) |
| Mapping | `sub` resolves to `supabase_user_id` only through mapping store `M-B` (`S2-A1-auth-architecture.md:503`); a `sub` with no `M-B` row authorises nothing |
| Current live state | **Zero providers configured** — confirmed at `S2-EXEC-06` §3, so this is an add, not an edit |

The issuer and audience strings are derived from the project ID, which is the standard Firebase JWT issuer/audience form;
they must be re-read from the Firebase console screen at execution time rather than trusted from this table.

---

## 4. `A13` — final signable text

This supersedes the generic `A13` in `approval-package-v3-implementation-instruments.md` only in that it now carries the
owner's chosen variant. The v3 file is **not** rewritten; §7 of `S2-EXEC-06` remains the request list.

```
INSTRUMENT A13 — ARCHITECTURE CHANGE: FIREBASE AS EXTERNAL JWT ISSUER VIA SUPABASE THIRD-PARTY AUTH

Decided  : 2026-11-03, owner selection "Third-Party Auth bridge" (recorded S2-EXEC-08 §1)
Targets  : Supabase parent-control-staging / dzonzgngwxclhfnvxtvu
           Firebase haven-staging / haven-staging-46822
Production: explicitly excluded. This instrument confers no authority over hhqgreaoqulmfwfwarhc.

AUTHORISES, and only this:
  1. Enabling Firebase Authentication on haven-staging with the Email provider,
     for the sole purpose of issuing ID tokens. No Firestore. No Cloud Functions.
     No Analytics. No application records held in Firebase.
  2. Adding exactly one Third-Party Auth provider to staging Supabase with the
     §3 issuer/audience/claim values, verified at execution time from the screens.
  3. Disabling Supabase's Email provider and "Allow new users to sign up" on
     staging, as the cutover step, with the §5 reversal recorded as the rollback.
  4. The one unique server-controlled mapping Firebase UID -> Supabase profile,
     realised ONLY through mapping store M-B. No new firebase_uid column elsewhere,
     including in the notification tables (A3c §1138 decision stands).
  5. Server-side verification of the Firebase ID token in every protected Edge
     Function. A client-supplied UID is never authoritative and never establishes
     parent-child ownership.

DOES NOT AUTHORISE:
  - Executing the profile-provisioning gap at §2(4). No new or altered Edge Function
    action may be created under this instrument; that requires an A7-R/A8-R addition.
  - Any assumption that third-party JWTs reach PostgREST/RLS (§2(5)) — unverified.
  - Service-account key generation (A9), Android app registration or SHA
    configuration (A12-R), synthetic fixtures (A14), schema load (A2'(a)/A3).
  - Writing any Firebase Auth user other than a synthetic fixture after A14.
  - Anything at all against production.

TOKEN LIFECYCLE OBLIGATIONS (must be implemented, not merely approved):
  - Revocation and expiry checks designed at the mapping row, not only at the token.
  - A revoked mapping row must fail closed even with a valid, unexpired Firebase token.
  - Two independent authentication authorities must not remain live after cutover.

FENCE — to be signed by the owner only, at execution time:
  Signature: ______________________   Name: ______________________
  UTC time : ______________________
  STATUS: UNSIGNED
```

---

## 5. Execution sequence once `A13` is signed **and** the in-app Browser surface is attached

Strictly ordered. Step 0 is the precondition that currently makes every other step impossible.

| # | Operation | Surface | Reversible? |
| --- | --- | --- | --- |
| 0 | Owner makes the Qoder in-app Browser panel visible so pointer actions stop failing | — | — |
| 1 | Screenshot/snapshot the staging project header before touching anything (`parent-control-staging` / `dzonzgngwxclhfnvxtvu`) | Supabase | read-only |
| 2 | Firebase Console → Authentication → Get started → enable Email provider only | Firebase | reversible (disable) |
| 3 | Supabase → Authentication → Third-Party Auth → Add provider → enter §3 values | Supabase | reversible (remove provider) |
| 4 | Verify the provider is listed; snapshot as evidence | Supabase | read-only |
| 5 | **Hold.** Do not disable the Supabase Email provider yet — with no profile-provisioning path (§2(4)) and 0 tables, disabling it removes the only working login for no benefit | Supabase | — |
| 6 | Disable Email provider + sign-ups **only after** `A2′(a)`/`A3` have loaded the schema and an approved provisioning action exists | Supabase | reversible (re-enable) |

Steps 2–4 are the only `A13`-authorised browser operations that can be executed safely today. Step 6 is deliberately gated
behind the schema load, and that ordering is a substantive recommendation of this record, not an omission.

---

## 6. Still unresolved, and owned by the owner

1. **Android package identity** — the brief says to take it from "the existing child APK evidence"; the signing-certificate decision (debug vs release SHA, and which SHA-1/SHA-256 to register) must be made before `A12-R` can be signed. `S2-EXEC-06` §11 finding F08 records a silent SHA-256 downgrade risk in the current wording.
2. **`A9`** — whether an Admin SDK private key may be generated at all. A FCM *sender* is needed before any notification can be delivered; the key event is irreversible and the v3 instruments leave the choice open.
3. **`A14`** — synthetic fixtures. Without them, none of the brief's Agent-7 security tests (invalid token, expired token, revoked mapping, cross-family isolation, notification-token ownership) can be executed, so nothing can reach `VERIFIED`.
4. **The §2(4) provisioning gap** — the hardest consequence of the chosen bridge, currently approved by nobody. It needs either an explicit `A7-R` addition authorising one new protected action, or a decision that Firebase identities are pre-seeded by an operator through the mapping store.

---

<a name="fn-cite"></a>Citation note: `capture-20261030.json` line references are into
`D:\control\docs\stage1\evidence\edge-functions\capture-20261030.json`, read directly this session; `:49` is that file's
`"actions": ["set_role","create_family"]` line for the `auth-bootstrap` entry and `:50` its `"auth_model"` line.
Per the citation convention in `S2-EXEC-FINAL.md`, paths are written out rather than abbreviated.
