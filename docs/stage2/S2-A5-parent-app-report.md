# S2-A5 — Flutter Parent App report

| Field | Value |
| --- | --- |
| Assigned role | Subagent 5 — Flutter Parent Application specialist (Firebase Auth, login/registration, password reset, auth state, token lifecycle, Supabase API integration, FCM registration, secure logout, session expiry, parent-child association) |
| Date | 2026-11-03 |
| Class | Offline repository-only assessment. **No build was attempted, because there is nothing to build.** |
| **Status** | **`BLOCKED — APPROVAL REQUIRED`** for every integration item, and additionally **`NOT STARTED` at the source level**: the parent application's source code does not exist in this repository |
| Authored by | Main agent, after direct verification. Recorded here rather than delegated, because the deliverable is a premise correction, not an implementation |

---

## 1. The finding that governs everything else in this file

**There is no Flutter application source anywhere in this repository, and no evidence that one exists at all.**

Measured this pass:

| Probe | Result |
| --- | --- |
| Total files in `D:\control` (excluding `.git`) | **95** — 75 `.md`, 13 `.json`, 3 `.sql`, 2 `.gitignore`, 1 `.toml`, 1 `.env.example` |
| `pubspec.yaml` | **0 matches** |
| `*.dart` | **0 matches** |
| `google-services.json` | **0 matches** |
| `AndroidManifest.xml`, `build.gradle(.kts)`, `*.kt`, `*.java` | **0 matches each** |
| What the project's own architecture doc says | `docs/stage1/02-architecture.md:25` — Parent app (Flutter), present-tense column reads **`—`**, described as **"Future: family administration, policy editing, command issuing, alert viewing, live view"**; `:181` — "Parent app, child app **DO NOT EXIST** — Stage 2+; toolchain present only (`flutter` 3.38.8, JDK 17)" |

So the brief's premise "Flutter for the Parent Application" describes an **intent recorded as future work**, not a codebase
to audit. The toolchain is installed (`docs/stage1/01-baseline-inventory.md:107`: `flutter 3.38.8 / Dart 3.10.7`,
JDK 17, Node 24.14.0, `supabase 2.109.0`, `firebase 15.23.0`) — **a toolchain is not an application.**

**Consequence for the required deliverables:** a "changed-file list" is empty, and "build and test evidence" cannot be
produced honestly. Any `flutter build`, `flutter analyze` or `dart test` output presented as evidence for this programme
would be fabricated. It is not. It does not exist, and writing it would be the single most damaging thing this phase could
do, because downstream approvals would then rest on a fake green tick.

## 2. Per-requirement status (the brief's Subagent 5 list, item by item)

| Required work | Status | What it is actually blocked on |
| --- | --- | --- |
| Firebase Authentication integration | `BLOCKED — APPROVAL REQUIRED` | **A12 unsigned**, and Firebase Auth is prohibited by three in-repo records (see §4) — this is a contradiction the owner must resolve before any client work |
| Login and registration screens | `NOT STARTED` | no source tree, no UI to preserve |
| Password reset | `NOT STARTED` | depends on which provider is enabled |
| Authentication state management | `NOT STARTED` | depends on the identity decision at §4 |
| Firebase token lifecycle (refresh/expiry) | `PLANNED` — design only | designed in [S2-A1-auth-architecture.md](S2-A1-auth-architecture.md); no client to hold it |
| Supabase API integration | `BLOCKED — APPROVAL REQUIRED` | staging has **0 tables**; the schema is `NOT LOAD-READY`; loading needs **A3** |
| Protected Edge Function requests | `BLOCKED — APPROVAL REQUIRED` | **0 Edge Functions deployed to staging** (`NOT CREATED`); the 9 that exist in evidence are a frozen **production** snapshot |
| FCM device registration | `BLOCKED — APPROVAL REQUIRED` | no FCM config (**A12**), **and no place to store a token** — see §3 |
| Notification handling | `NOT STARTED` | same |
| Secure logout / session expiration | `NOT STARTED` | revocation design unresolved (S2-A1: today revocation depends on `db.auth.getUser`, and a local-JWKS verifier silently loses it for up to the token's lifetime) |
| Parent-child account association | `BLOCKED — APPROVAL REQUIRED` | `family_members` / `profiles` exist only in the unloaded artefact; ownership enforcement is server-side and unbuilt |

## 3. Two blockers that are easy to miss, because they are schema-shaped rather than UI-shaped

1. **Push tokens have no home.** All 183 captured Postgres columns were re-parsed: the only `token`-ish columns are
   `pairing_requests.token_id (uuid)` and the `device_pairing_tokens` table — both **pairing** artefacts, not push
   registration tokens. `devices` has `secret_hash`, `installation_id`, `credential_issued_at`, `credential_revoked_at`
   and a `notifications_granted` boolean, but no registration-token column. This programme's own checklist already says
   it plainly: `firebase/SETUP-CHECKLIST.md:99` — "**There is no `push_tokens` table and no token column on `devices`
   today.** Adding it is a G3-style migration decision, not a dashboard click."
   → **Signing A12 buys a registration and a `google-services.json`, not a transport.** A FCM token received by a client
   has nowhere to be persisted and no server-side send path (see [S2-A4-edge-functions-audit.md](S2-A4-edge-functions-audit.md)).
2. **`.env.example:5` points at production.** The one client-config template in the repository hard-codes `SUPABASE_URL`
   to the **production** project's URL (its ref appears there; the staging ref does not). Under a staging-only absolute
   (C2b/R-43) and with the "wrong-project sentinel" mechanism built specifically to catch this class of error, a template
   whose default target is production is a **HIGH** finding — it is exactly the mistake R-43 exists to prevent, staged in
   the file a developer copies first. The other keys in that file are empty (`SUPABASE_ANON_KEY`, `FIREBASE_PROJECT_ID`,
   `FIREBASE_APP_ID_ANDROID` — all zero-length), and the file correctly comments the service-role key and
   service-account JSON out. **No value is reproduced in this report.**

## 4. The identity contradiction the owner must rule on

The architecture brief directs Firebase Authentication for the client apps. Three in-repo records forbid it:

| Record | Wording |
| --- | --- |
| `docs/stage2/01-staging-project-proposal.md:201` (approved-role table, row 6) | "**Not in the approved architecture** — Firebase Auth / Firestore / Cloud Functions — `OUT OF SCOPE` — must not be enabled" |
| `firebase/SETUP-CHECKLIST.md:16` (decision **D4**) | "Firebase Auth — **Leave disabled** — Supabase Auth is the single identity authority (architecture rule)" |
| `docs/stage1/02-architecture.md:25-26` | both apps hold "only anon key + **Firebase client config**. Never service-role, **never Admin SDK**" |
| The user's standing instruction this session | "Do not enable Firebase Auth, Firestore, Firebase Cloud Functions, Analytics or any unrelated product" |

**Two defects in the checklist itself, found while collecting the above (the owner should not sign an A12 package built on
this file without correcting them):**

| Line | Defect | Why it matters |
| --- | --- | --- |
| `firebase/SETUP-CHECKLIST.md:3` | States "No Firebase project exists for this product" — **superseded**. `haven-staging-46822` was created 2026-10-30 and `01:202` records it as `RATIFIED — 2026-11-02 — OPTION (i)` | A reader following the checklist from the top is told to *create* a project that already exists, which is how a second project gets made |
| `firebase/SETUP-CHECKLIST.md:14` (decision **D2**) | Recommends Firebase project id **`parent-control-prod`** to "match the Supabase project naming already in use" | That is the **production** name pattern applied to a Google project, in a programme whose staging-only absolute (C2b/R-43) exists to prevent name-driven wrong-project actions — the same hazard class as `.env.example:5` above. The project actually created is `haven-staging` / `haven-staging-46822` |

Row 1 of the same approved table (`01:195`) names **Supabase Auth** as the "single identity authority". Adopting Firebase
Auth is therefore not an implementation detail — it **reverses an approved topology**, and every artefact above would need
re-ruling. [S2-A1-auth-architecture.md](S2-A1-auth-architecture.md) §2-5 works out what that reversal costs (provisioning,
UID mapping, the stranded `handle_new_user` path, revocation, the `webrtc_signals.from_user_id NOT NULL DEFAULT
auth.uid()` default that bakes the old model into the schema itself). **Until the owner rules, no client authentication
code can be written without guessing the target architecture.**

## 5. "Preserve current UI/UX" and "follow the existing application architecture"

Both instructions presuppose an existing UI. There is none in the repository. The only authoritative description of the
intended application architecture is `docs/stage1/02-architecture.md:25-36` (a mermaid diagram naming the two clients and
their permitted credentials). Following it is possible; preserving it is not a defined task.

## 6. Integration flow — planned, not implemented

Recorded as `PLANNED` so that a client implementation has a target the moment the gates clear; **nothing below is built or
testable today.** Citations: identity model from [S2-A1](S2-A1-auth-architecture.md), server contracts from
[S2-A4](S2-A4-edge-functions-audit.md), schema reality from [S2-A3](S2-A3-database-audit.md).

```
sign in            → Firebase Auth (provider = owner decision, §4)
ID token           → held in memory only; refreshed by the SDK; never persisted to a log
request            → HTTPS POST to a Supabase Edge Function, Authorization: Bearer <ID token>
function           → verifies the token (aud/iss/exp/sig), maps Firebase UID → profile row,
                     then acts with the service-role key under server-side ownership checks
client             → never sees the service-role key; never talks to Postgres directly
push               → token captured at registration, stored SERVER-side (table does not exist, §3.1),
                     delivered by a Supabase-side send path (no FCM sender exists today)
logout             → local session cleared + server-side revocation recorded; both ends are unbuilt
```

The honest gap between this diagram and reality: **the middle three boxes have no deployed implementation and the
identity row they depend on has no return types** (0 of 38 in catalogue form; 25 of 29 behavioural DB objects are gated
on 9 missing return types — see [S2-EXEC-FINAL.md](S2-EXEC-FINAL.md) §3).

## 7. What this subagent could not determine, and why

- Which UI framework the parent app will use (Flutter is *stated* in `02-architecture.md`; nothing in the repo evidences a
  Flutter project existing). `UNVERIFIED — SOURCE AMBIGUOUS`.
- Whether the parent and child roles are one codebase or two. The three release APKs are identified as the **child**
  application id (`docs/stage1/01-baseline-inventory.md:152`), are **Capacitor** builds, and no parent artefact appears
  anywhere. See [S2-A6-child-app-report.md](S2-A6-child-app-report.md) §1 — this is the more important half of the premise
  correction.
- Any performance, accessibility or UX property of an application that does not exist.

## 8. Shortest path to a real Subagent 5

1. Owner ruling on §4 (identity authority) — no approval ID covers it, it is a topology decision.
2. A source tree: either point this programme at the existing repository/location that holds the parent app, or accept a
   scaffold task as new work. **Until a source tree exists, items in §2 stay `NOT STARTED` regardless of cloud approvals.**
3. A signed **A3** load (any client integration needs tables) and deployed Edge Functions (**A7/A8** class approvals).
4. A **push-token persistence decision** (§3.1) before FCM code is written.
5. Only then: implement, build with the installed `flutter 3.38.8`, and report real build output.

**Author's note:** this file reports an absent premise, not a failed implementation. Marking §2 items `COMPLETE`, or
attaching invented build output, would have been the failure mode the brief's own §8 warns against — "do not mark tests
PASS without evidence".
