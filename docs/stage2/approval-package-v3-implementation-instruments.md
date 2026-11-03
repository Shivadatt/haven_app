# Stage 2 — Approval package v3: implementation instruments (2026-11-03)

**Purpose: this file contains only the exact text the owner signs. It is not a report, not an audit and not a status
update.** It exists because the approvals required for the owner-directed implementation phase are stale (`A12` still
attests an architecture the owner has now changed), ambiguous (`A7` forbids the only artefact that exists for 7 of 9
functions) or absent (`A13`, `A14` do not exist at all). Each section below is one instrument, self-contained and
signable as-is.

**Provenance read before writing:**
[approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) §1.7 `:104-108`, the
ratification note `:118-127`, A12 `:350-366` · [04-risks-rollback-approvals.md](04-risks-rollback-approvals.md) §3
`A0…A13`, A7 `:215-216` · [S2-EXEC-FINAL.md](S2-EXEC-FINAL.md) §3.1-3.3, §5, §6, §8.2, §13-14a (A7-F04, A7-F11), §16.2 ·
[01-staging-project-proposal.md](01-staging-project-proposal.md) service topology `:194-212` ·
[../../firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) `:14-18`, `:20-53` ·
[S2-EXEC-04-sql-structural-findings.md](S2-EXEC-04-sql-structural-findings.md) H-3 ·
[S2-A3-database-audit.md](S2-A3-database-audit.md) X-4.

**Standing constraints carried into every instrument below (not renegotiable by signing anything here):**

1. **Staging-only absolute.** Every Supabase action targets `parent-control-staging` / `dzonzgngwxclhfnvxtvu`; every
   Firebase action targets `haven-staging` / `haven-staging-46822`. Production `parent-control-prod` /
   `hhqgreaoqulmfwfwarhc` is not opened, queried, configured, read or written by any instrument in this file, and **A1
   remains `INOPERATIVE`** — no instrument here revives it (R-43 as amended by C-2: the read-only-comparison exception is
   closed; a production comparison read is *prohibited*, not merely unapproved).
2. **Browser dashboard channel only.** No Supabase CLI, no Firebase CLI, no Docker, no `pg_dump`, no `supabase db reset`,
   no REST, no PostgREST/hidden endpoints, no DevTools console, no direct database connection (constraint C1, R-22).
3. **No secret value in any artefact.** Env-var and config-key *names* appear below; values never do. No value enters a
   repository file, a change record, a transcript, a log or a screen capture (A9's rule, extended to screenshots).
4. **`D:\control` is at zero commits.** Nothing in this file is committed or staged; digests of record remain the only
   provenance, which is itself a disclosed weakness (§5 of v2).
5. **No instrument is signed by anyone at time of writing.** Every fence is blank; every status is `UNSIGNED`. Signing one
   instrument grants only what that instrument says. Nothing here is implied by the 2026-11-02 ratification of the project
   creations, which "grants nothing forward" (v2 `:123-125`).

**This file performed no cloud action.** No dashboard was opened, no URL visited, no SQL run, no setting read or changed,
no credential touched, in its making. It is repository-only authoring.

---

## 1. A13 (new) — Firebase Authentication as the identity authority

> **[Dated pointer — 2026-11-03, later in the same session this file was written.] The owner has since ruled on the fork
> this instrument left open at §1.2/`:67`, and the ruling is *not* the variant drafted above.** The chosen option is
> **Supabase Third-Party Auth as the bridge**: Supabase Auth **remains** the session and authorization authority, Firebase
> Authentication acts as an **external JWT issuer** whose tokens Supabase verifies, and the Firebase UID resolves to a
> Supabase profile only through mapping store `M-B`. Under that ruling, the §1.1 framing above — *"Firebase Authentication
> to become the product's single external identity root … Supabase Auth a consumer of that identity rather than its
> issuer"* — describes a topology the owner did **not** select.
>
> Consequences a signer must know before transcribing any fence: (i) this section's §1.3 operation list and §1.4 replacement
> wordings are superseded by
> [`S2-EXEC-08-identity-decision-A13-final.md`](file:///D:/control/docs/stage2/S2-EXEC-08-identity-decision-A13-final.md),
> which carries the chosen variant's final text, the exact dashboard values, and the ordered execution sequence; (ii) the
> preconditions this section states — including that no Firebase-UID mapping table exists in the migration artefact — are
> **not** dissolved by the bridge choice, they still gate it; (iii) the bridge opens a provisioning gap that this section
> does not mention, because Supabase's `handle_new_user` trigger only fires for `auth.users` rows that third-party
> verification never creates (S2-EXEC-08 §2(4)), so **A13 signed as drafted or as re-worded still leaves Firebase
> identities without a profile row** and no approved action to fix it; (iv) §1.2's single-authority constraint binds the
> re-worded variant too, and under the bridge it requires disabling Supabase's own Email provider at cutover, which the
> re-worded sequence deliberately defers until after the schema load.
>
> This note is an annotation, not a revision. The text below is left exactly as commissioned, because it records what was
> on the table when the instrument was drafted. **Sign §4 of S2-EXEC-08, not §1 of this file.**

### 1.1 What signing this permits, in plain English

Signing A13 reverses an approved topology. It permits **Firebase Authentication to become the product's single external
identity root** in `haven-staging-46822`, by enabling named sign-in providers on that project's Authentication → Sign-in
method surface, and it makes Supabase Auth a *consumer* of that identity rather than its issuer. It is issued as an
**architecture change**, not as a configuration step, because the current records do not merely omit Firebase Auth — they
**forbid** it, in three separate places quoted and replaced in §1.4 below. Explicitly **not** permitted by A13: Firestore,
Cloud Functions, Cloud Run, Analytics, Remote Config, App Check, any paid plan, any second identity issuer, any Firebase
project other than `haven-staging-46822`, any app registration or `google-services.json` download (that is **A12-R**,
§2), any secret or service-account key (that is **A9**), any schema object (that is **A3**), and any production change of
any kind. Signing A13 does not make the backend able to *use* the identity it enables: the migration artefact contains **no
Firebase-UID → profile mapping table**, so A13 alone yields authenticated users the database cannot bind. That gap is
A13's first precondition, not a later discovery.

### 1.2 The single-authority constraint (binding on A13 and on every instrument after it)

**Exactly one identity authority may be enabled. Never two.** Firebase Authentication is the external identity root;
Supabase issues no user JWTs to clients under this instrument, and Supabase Auth's own sign-up/sign-in surface stays
disabled so no second issuer can arise by accident. The Firebase-UID → Supabase-`profiles` mapping is **server-controlled:
unique, server-written, and never client-asserted** — no client payload, header or form field may establish an identity,
and no raw UID crosses the boundary from a client as trusted input. Every protected Edge Function verifies the Firebase ID
token server-side (signature against Google's JWKS, `iss` pinned to the decided project, `aud` = `haven-staging-46822` and
rejected otherwise, `exp` with an explicit skew bound, and a cross-project valid token from *another* Firebase project
rejected). Revocation must have a named home: the record must state where `tokens_valid_after` lives and who checks it,
because a local-JWKS verifier that stops calling `auth.getUser` silently keeps accepting a revoked token for its full
lifetime (~1 h). **If the owner's ruling is that Supabase Auth remains the authority, A13 is not signed and §1.4 wordings
stand unchanged.**

### 1.3 Operations A13 authorises, named at dashboard level

Target: Firebase console, project `haven-staging` / `haven-staging-46822` only, account named in the change record.

| # | Operation (console path) | In scope |
| --- | --- | --- |
| 1 | Build → **Authentication** → Get started (no product is enabled today) | YES |
| 2 | Authentication → **Sign-in method** → **Enable: Email/Password** | YES — only if box (a) ticked in the fence |
| 3 | Authentication → **Sign-in method** → **Enable: Google** | YES — only if box (b) ticked |
| 4 | Authentication → **User roles / Advanced settings** → record the SHA-1/`Authorized domains`/`Continue URI` values as displayed, change none | read + record only |
| 5 | Authentication → **Sign-in method** → enable **any other provider** (Apple, Phone, GitHub, anonymous, SAML/OIDC) | **NO** |
| 6 | Build → Firestore / Storage / Functions / App Check / Remote Config / Analytics → enable | **NO** |
| 7 | Project settings → Usage and billing plans → Upgrade | **NO** |
| 8 | Any operation in the FlutterFlow demo project `flutter-flow-w-ith-f-ir-6592ib` or in any other Google project | **NO** |
| 9 | Supabase → Authentication → Providers → enable/disable anything | **NO by this instrument**; under A13 the Supabase sign-up surface must be confirmed disabled and that confirmation is an evidence item, not an edit |

### 1.4 Superseding wording — the three records that currently forbid this, quoted and replaced

A13 is not signable while these sentences stand, and they must not be silently rewritten: each current sentence is quoted
verbatim with its file:line and gets one replacement sentence. **Applying these four replacements is itself an action of
A13** (documentation write, offline, no cloud effect), and must be recorded as such in the change record with the date.

**(1) [01-staging-project-proposal.md](01-staging-project-proposal.md) `:196`**

> Current, verbatim: `| 1 | Single identity authority | **Supabase Auth** (staging ref `dzonzgngwxclhfnvxtvu`) | `NOT CONFIGURED` — no sign-ups were ever run and no user was created by this programme.`

Replacement sentence: *"Single identity authority | **Firebase Authentication** in `haven-staging-46822` (external identity
root), with the Firebase-UID → Supabase-`profiles` mapping held server-side in Supabase Postgres — changed from Supabase
Auth by approval A13 on the date recorded in approval-package-v3-implementation-instruments.md §1; Supabase issues no user
JWT to clients."*

**(2) [01-staging-project-proposal.md](01-staging-project-proposal.md) `:201`**

> Current, verbatim: `| 6 | **Not in the approved architecture** | Firebase Auth / Firestore / Cloud Functions | `OUT OF SCOPE` — must not be enabled |`

Replacement sentence: *"| 6 | **Split by approval A13** | Firebase Auth: **now in the approved architecture as the single
identity authority** (A13, signed on the date recorded above). Firestore / Cloud Functions / App Check / Remote Config /
Analytics: **remain `OUT OF SCOPE` — must not be enabled.** |"*

**(3) [../../firebase/SETUP-CHECKLIST.md](../../firebase/SETUP-CHECKLIST.md) `:16` — decision D4**

> Current, verbatim: `| D4 | Firebase Auth | **Leave disabled** | Supabase Auth is the single identity authority (architecture rule) |`

Replacement sentence: *"| D4 | Firebase Auth | **Enable only under approval A13** (see approval-package-v3 §1); the
provider set is exactly what A13's fence ticks | A13 (2026-11-03) supersedes the former single-authority rule; exactly one
identity authority still applies — it is now Firebase Auth, not Supabase Auth. Never two. |"*

**(4) [approval-package-v2-ratification-and-forward.md](approval-package-v2-ratification-and-forward.md) §1.7 `:106-108`**

> Current, verbatim: `**Supabase Auth is the single identity authority.** Firebase is **FCM-transport-only by intent**, and **FCM does not exist in this programme**. Firebase Auth, Firestore and Cloud Functions are **not approved requirements** and appear in no approval row here.`

Replacement sentence: *"**Firebase Authentication is the single identity authority** under approval A13 (see
approval-package-v3 §1); Supabase Auth is no longer an issuer. Firebase's remaining role is FCM transport, governed by
A12-R. **Firestore and Cloud Functions are not approved requirements** and appear in no approval row here. The v2 §1.7
sentence is retained above as the pre-A13 record and is superseded, not deleted."*

### 1.5 Preconditions (all must be true before any §1.3 operation runs)

1. §1.4's four replacements applied to the files and committed to the change record as a documentation event.
2. The **mapping table exists in the schema** — a signed A3 (or an A3 addendum) that creates the Firebase-UID → `profiles`
   mapping object with a uniqueness constraint. Today the artefact emits **no such table**; without it A13 is unusable and
   §1.2's constraint unenforceable. **Do not enable a provider before this exists.**
3. The two captured column defaults that hard-code the old model are dispositioned: `webrtc_signals.from_user_id`
   (`uuid NOT NULL DEFAULT auth.uid()`) fails not-null for any non-Supabase-JWT caller, and `safe_zones.created_by`
   (`uuid NULL DEFAULT auth.uid()`) **silently stores NULL**, losing audit provenance. Both are `VERIFIED` as captured and
   `INFERRED` as to load behaviour. Label them and record the chosen fix (both are behind A3).
4. `tokens_valid_after`'s home and checker named in writing.
5. The service-account / privileged credential required for custom claims and revocation is acknowledged as a **separate
   A12-R tick plus A9**, not a consequence of A13.
6. `.env.example:5`'s hard-coded production URL fixed (S-6/A7-F12) so no build born from this change defaults at
   production.

### 1.6 Evidence to capture afterwards

Console header (project display name **and** project ID) in every capture; the enabled-provider list as rendered, with the
disabled-provider list; the Auth `Authorized domains` and `Continue URI` values as read; project number
`381273275501`; UTC start/stop timestamps for the window; the count of first synthetic test principal created (under A14,
not here); an explicit statement that **no Firestore/Functions/Storage/App Check/Analytics product was enabled** and that
**no plan change was initiated**; the statement that no token, key or secret value entered any file, transcript or screen
capture. Screenshots are labelled `SCREENSHOT EVIDENCE: NOT VERIFIED` — a screen capture is not a platform record (R-27).

### 1.7 Rollback / reversal path

Authentication → Sign-in method → **Disable** the provider. Disclosed residuals, stated before signing rather than after:
disabling a provider stops future sign-ins but **does not delete Firebase Auth user records already created while it was
enabled** — the residual-user behaviour is `NOT VERIFIED` in this programme and must be read off the console at reversal
time, not assumed. Neither plan has backups or PITR, so there is no restore point on either side: the Supabase-side
mapping rows must be reversed by their own signed `DELETE`/`DROP` text under **A10**, and no rollback anywhere in this
programme has yet been tested. Reversal does not restore the pre-A13 documentation state automatically: the §1.4 wordings
must be re-applied as a documentation event with its own record.

```text
A13 — FIREBASE AUTHENTICATION AS THE SINGLE IDENTITY AUTHORITY (ARCHITECTURE CHANGE)
I have read docs/stage2/approval-package-v3-implementation-instruments.md §1. I rule that the identity authority of the
Haven product changes from Supabase Auth to Firebase Authentication, in Firebase project haven-staging / haven-staging-46822
ONLY, and I authorise exactly the console operations in §1.3 and no others:
  [ ] (a) Authentication -> Sign-in method -> Enable Email/Password
  [ ] (b) Authentication -> Sign-in method -> Enable Google
I impose the single-authority constraint in §1.2: exactly one identity authority, never two; the Firebase-UID ->
Supabase-profile mapping is unique, server-written and never client-asserted; no client sends a trusted raw UID.
I direct the four superseding wordings in §1.4 to be applied and recorded as a documentation change, quoting the
superseded text rather than deleting it.
I acknowledge the §1.5 preconditions — in particular that the migration artefact contains NO mapping table today, so
enabling a provider before that table is loaded produces identities the database cannot bind — and I confirm this
instrument authorises NO Firestore, NO Cloud Functions, NO App Check, NO Analytics, NO Remote Config, NO paid plan,
NO app registration or google-services.json (A12-R), NO secret or service-account key (A9), NO schema object (A3),
NO test fixture (A14), NO Edge Function (A7-R/A8-R) and NO production access of any kind.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 2. A12-R (re-scoped) — Android app registration, `google-services.json`, service-account handling and FCM configuration

### 2.1 What signing this permits, and how it resolves the A12 attestation collision

Existing **A12** ([approval-package-v2 `:350-366`](approval-package-v2-ratification-and-forward.md)) already covers app
registration, `google-services.json` handling, service-account JSON handling and FCM configuration — and **does not cover
the identity provider**: its "Authorises" row `:353` reads *"app registration (Android/iOS/Web) in `haven-staging-46822`,
download/handling of `google-services.json`, service-account JSON, and FCM configuration for push transport"* and lists no
sign-in provider. Its fence `:360-364` then makes the signatory **attest** the opposite of A13: *"I acknowledge that
Supabase Auth is the identity authority, Firebase is FCM-transport-only, and Firebase Auth / Firestore / Cloud Functions
are not approved requirements."* That is why A12 as written is **`UNGRANTABLE` for identity (A7-F04) and now
mis-attesting**: after A13, a signatory who ticked A12's original fence would be swearing to a sentence the owner has
replaced. **A12-R re-scopes the block to transport and registration only, and replaces the attestation with a mandatory
branch**: the signatory must tick exactly one of the two attestation options, so nobody can be made to attest a falsehood.
Signing A12-R permits: registering an Android app for package `com.haven.familysafety` in `haven-staging-46822`,
downloading and handling `google-services.json`, optionally creating and handling a service-account JSON key, and
configuring FCM transport. It explicitly does **not** permit enabling any Authentication provider (A13), any other
Firebase product, any credential value entering this repository, or any iOS/Web app registration unless separately
ticked. It also buys **no working push**: among 183 captured columns there is **no registration-token column and no
`push_tokens` table**, and no evidenced function sends FCM — so A12-R delivers a project, an app and a JSON file, not a
delivery path.

### 2.2 The signing-certificate precondition (blocking; nothing in §2.4 is configurable until it is answered)

Three APKs share package `com.haven.familysafety` but present **two different signing certificates**, and one of the
builds loads its UI from a remote site:

| Build | Signing certificate DN | SHA-256 of certificate | Capacitor config |
| --- | --- | --- | --- |
| 1.0 | `CN=Haven, OU=Haven, O=Haven, L=Ahmedabad, ST=Gujarat, C=IN` | `eaffe1600ccc526f76a2c3c2dd336a47d42001e903985b99ff59cacc5dd078e2` | `webDir: dist` with a **remote `server.url`** |
| 1.1 and 1.2 | `CN=Haven, **O=Haven Demo**, C=US` | `ff1ad18fcc8c77fd48c126fb369e73a7a743538f6f9a542f32f726a1a9fdd67a` | bundled `dist-android` |

FCM itself needs only the package name, so **registration is not blocked**; but SHA-1/SHA-256 fingerprints (needed for
App Check or phone auth, and the field an operator will fill "while you are in there") **cannot be configured until the
owner states which build and key ship**, and whether **Play App Signing will replace the upload certificate** — Play App
Signing would change the console fingerprint a third time. The keystore is not in this repository (`*.jks`/`*.keystore`/
`*.bks` are git-ignored) and the Android source is not in this repository either, so the source-level `applicationId` is
unconfirmed and only the binaries are authoritative. **A12-R therefore carries a mandatory three-part owner statement,
blank at time of writing**, and the certificate-fingerprint operation is forbidden until all three are answered.

### 2.3 Operations A12-R authorises, named at dashboard level

| # | Operation | In scope |
| --- | --- | --- |
| 1 | Firebase console → `haven-staging-46822` → Project settings → **Your apps → Add app → Android** | YES — package `com.haven.familysafety` exactly as written on the console form; verify the echoed package before submit |
| 2 | Project settings → Your apps → **Download `google-services.json`** | YES — handling per §2.5 |
| 3 | Project settings → Your apps → add **SHA-1 / SHA-256 certificate fingerprints** | **NO until §2.2 is fully answered** |
| 4 | Grow → **Messaging / Cloud Messaging** → read sender ID; send a test message **only** if box (c) ticked | read: YES · test send: conditional |
| 5 | Google Cloud console → IAM & Admin → **Service accounts → create key (JSON)** | ONLY if box (b) ticked; never for a client |
| 6 | Project settings → Your apps → Add app → **iOS / Web** | NO unless box (d) ticked |
| 7 | Analytics, Gemini assistance, environment type, plan upgrade, or opening `flutter-flow-w-ith-f-ir-6592ib` | **NO** (the two wizard deviations of 2026-10-30 stay closed items, not precedents) |
| 8 | Firebase **Authentication** → anything | **NO — A13's subject; A12-R does not reach it** |

### 2.4 Preconditions

A13 recorded (or a recorded ruling that A13 stays unsigned, which selects attestation branch (2) below); ratification
option (i) — recorded 2026-11-02; §2.2 answered in full; a recorded G2 decision; the named console account for the session
(R-23: Supabase `spg7753…` and Firebase `shiwa2172…` are different identities — never infer one from the other); A9 signed
if any value will be stored as a Supabase Edge secret; no repository credential path exists (the repo has no
`google-services.json`, and none may gain one).

### 2.5 Evidence to capture afterwards

Firebase **App ID** and the **sender ID** (both identifiers, not secrets), the package name as echoed by the console,
`google-services.json` **file name + SHA-256 digest + byte size** and its location **outside** `D:\control`, the
statement that no key or certificate value was read into any document, logcat/console error text if a test send was
performed, the FCM test outcome **or** the recorded decision that FCM stays absent, and UTC start/stop for the window.

### 2.6 Rollback / reversal path

Project settings → Your apps → the app → ⋮ → **Remove this app** — owner-only, and disclosed as *permanent-ish*: an
Android app registration keyed to a package name is hard to undo cleanly, and re-adding can require re-entering
fingerprints. `google-services.json`: destroy the local copy (the file is not deletable from the repo because it must
never be in it); the download itself leaves no repo trace to reverse. **A service-account JSON cannot be "un-exported"** —
if box (b) is ticked, reversal is: Cloud console → Service accounts → **Delete the key**, then confirm the key ID is absent
from the keys list, then destroy every local copy; a key that was exported and not revoked is treated as leaked, and its
mere existence in a Downloads folder is unrecoverable and un-auditable by this programme. No FCM "reversal" exists beyond
deleting the app.

```text
A12-R — RE-SCOPED: ANDROID APP REGISTRATION, google-services.json, SERVICE-ACCOUNT HANDLING AND FCM TRANSPORT
I have read docs/stage2/approval-package-v3-implementation-instruments.md §2. This block REPLACES A12
(approval-package-v2 §3.7) as the forward authorisation for Firebase registration and transport work in
haven-staging / haven-staging-46822. It authorises the §2.3 operations I tick, and nothing else:
  [ ] (a) Add Android app, package com.haven.familysafety, + download google-services.json, handled per §2.5
  [ ] (b) Create and handle a service-account JSON key (server-side only, never shipped in a client)
  [ ] (c) FCM configuration and ONE test send
  [ ] (d) iOS and/or Web app registration
ATTESTATION — I must tick exactly one, and I may not tick the one my other decisions contradict:
  [ ] (1) A13 IS SIGNED: Firebase Authentication is the single identity authority. I acknowledge that A12-R reaches
          transport and registration only, that it authorises no sign-in provider, and that the "not approved
          requirements" attestation of the superseded A12 fence no longer describes the approved architecture.
  [ ] (2) A13 IS NOT SIGNED: Supabase Auth remains the single identity authority, Firebase is FCM-transport-only, and
          Firebase Auth / Firestore / Cloud Functions are not approved requirements.
I confirm this block does NOT authorise: enabling any Authentication provider, Firestore, Cloud Functions, App Check,
Remote Config, Analytics, Gemini, any environment-type or plan change, any action in flutter-flow-w-ith-f-ir-6592ib, any
credential value entering this repository, any Supabase schema object, secret, fixture, Edge Function or any production
access. I further confirm the §2.2 precondition: NO SHA-1/SHA-256 fingerprint may be entered until I have stated which
APK ships, under which key, and whether Play App Signing replaces the upload certificate — because 1.0 and 1.1/1.2 are
signed by two different certificates, 1.1/1.2 self-describe as O=Haven Demo, and 1.0 loads a remote site.

SIGNING-CERTIFICATE STATEMENT (required by §2.2; blank until the owner answers)
  Build that ships:        ______________________
  Key that ships:          ______________________
  Play App Signing will replace the upload certificate:   [ ] YES   [ ] NO   [ ] NOT DECIDED
  FCM-only (no fingerprints configured) authorised today: [ ] YES   [ ] NO

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 3. A2′(a) — staging sentinel, created before any load

### 3.1 What signing this permits, in plain English

A2′(a) permits the creation of **one table with one row** in `dzonzgngwxclhfnvxtvu` — `private.s2_environment` — *before*
any schema load, because that row is the object every patch aborts on when it is absent, and because until it exists the
programme has **no automated wrong-project refusal at all**: R-10's own text says the sentinel is `NOT CREATED`, so today
the manual ref checks are the whole control. Explicitly not permitted: the settings checklist and the Realtime publication
(that is **A2′(b)**, which is not executable before the tables exist), the schema load (**A3**), secrets (**A9**), patches
(**A5**), fixtures (**A14**), Firebase (**A12-R/A13**), anything in production. Signing A2′(a) also does not start A3: the
load needs its own signature.

### 3.2 Operations, named at dashboard level

Supabase dashboard → project `dzonzgngwxclhfnvxtvu` (header ref echoed into the change record **before** the paste) →
**SQL Editor** → one pasted, reviewed block:

```sql
create schema if not exists private;
create table if not exists private.s2_environment (environment text not null);
insert into private.s2_environment (environment) values ('staging');
select current_database() as db, private.s2_environment.environment, (select count(*) from private.s2_environment) as rows
  from private.s2_environment;
```

The final statement **is the sentinel check**, and its second column is the discriminator: `db` is expected to render the
project ref (`dzonzgngwxclhfnvxtvu`) rather than a generic database name. **That expectation is `NOT VERIFIED`** — no
`select current_database()` has been run anywhere in this programme (S2-EXEC-04 M-13) — so **the very first run of A2′(a)
is also the measurement that establishes whether this check can detect a wrong-project load at all.** If `db` renders
something project-independent, the sentinel proves only that the expected object exists; it does **not** prove *which*
project, the console-header echo becomes the sole remaining control, and a `project_ref` column with value
`dzonzgngwxclhfnvxtvu` must be added as a recorded amendment. A `private`-schema table with one row is the only object
created: no grants, no policies, no RLS on the sentinel unless separately instructed.

### 3.3 Preconditions

Ratification option (i) recorded; **A12/A13 irrelevant here — no Firebase action**; the ref mis-typing guard (console
header read and matched against the change record before the paste, R-43); the dashboard loaded and settled (R-24 — a
pre-load "No projects"/"0 tables" flicker is not evidence); a stated window with UTC start, taken *before* the touch.

### 3.4 Evidence required afterwards

Statement text as executed; before/after counts (`public` tables 0 → 0, tables in `private` 0 → 1, rows 0 → 1); the value
`db` actually rendered, labelled `MEASURED THIS PASS` if observed; UTC start and stop; the project ref as read from the
console header; the reviewer pass performed at a different time with its own notes (R-16 — a time-separated self-review,
never described as two-person control); `SCREENSHOT EVIDENCE: NOT VERIFIED` on any capture.

### 3.5 Rollback / reversal path

`drop table if exists private.s2_environment;` — additive and fully reversible in one statement, **but the drop is itself
an A2′-class action and needs its own instruction**; note also that dropping the sentinel does not merely restore the empty
shell, it removes the automated wrong-project guard every later patch depends on, so reversal must be recorded as
increasing risk, not reducing it. No backup or restore point exists (R-35).

```text
A2'(a) — STAGING SENTINEL CREATED BEFORE ANY LOAD
I approve, in project dzonzgngwxclhfnvxtvu ONLY and before any schema load, creation of private.s2_environment with one
row 'staging' plus the sentinel SELECT in §3.2, and I accept that this same first run measures whether current_database()
can actually distinguish projects — that power being NOT VERIFIED today. I require the console-header ref to be echoed in
the change record before the paste. If the SELECT shows the check cannot discriminate the project, the sentinel is
recorded as a partial control and no load (A3) or patch (A5) proceeds until the owner rules on a ref-binding column.
This authorises NO schema load, NO settings checklist item, NO Realtime publication (all A2'(b)/A3), NO secret (A9), NO
patch (A5), NO fixture (A14), NO Edge Function (A7-R/A8-R), NO Firebase action (A12-R/A13) and NO production action.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 4. A3 — schema load of the transaction-wrapped migration

### 4.1 What signing this permits, and the honest consequence

A3 permits applying the reconstructed G3 artefact to `dzonzgngwxclhfnvxtvu` in dependency order, then re-running the
g1-* count/ACL queries and producing the equivalence diff. **A load today does not produce a working backend, and signing
A3 does not make the application-ready claim true.** The measured outcome of loading the current artefact is:

| Object class | A load today yields |
| --- | --- |
| Tables | **19** |
| Constraints | **137** |
| Indexes | **34** (+28 created implicitly by constraints) |
| RLS **enabled** | **19** — and `rls_forced` false on all 19 |
| Grants | **248** persisted grant/ACL effects |
| Policies | **4** |
| Functions | **0** |
| Triggers | **0** |
| Publications / views / sequences / extensions / comments | **0 emitted; expected population `UNKNOWN`, not zero** |

**Read that line as what it is:** 19 tables with RLS enabled and 4 policies, 0 functions and 0 triggers, is a **deny-all
shell for `authenticated`** — reads return 0 rows and every write fails `42501`. It is default-deny, so there is no
confidentiality exposure, and **total availability loss for the application roles**. Any G5-S test run against that shell
would "pass" vacuously (0 rows / denied from absent policies, not from production predicates), and recording `PASS` would
breach constraint C7. The 25 behavioural objects that matter (17 policies + 8 triggers) wait on **9 return types that
exist nowhere in the authorised evidence**; 24 function bodies (12 `public` + 12 `private`) are absent and unrecoverable,
so no fence in this package can make them appear.

**Stop condition (binding, stated before signature): if the operator's or owner's expectation of A3 is "the backend works
afterwards", the answer is `NO` and the correct action is `STOP — EXPECTATION MISMATCH: A3 YIELDS A DENY-ALL STRUCTURAL
BASELINE, NOT A RUNNING APPLICATION`.** In that case A3 must not be signed on that expectation, and the owner instead
takes §16.2 actions 2 and 3 (return-type admissibility ruling; accept or reject a structural-only baseline) first.

### 4.2 Operations, named at dashboard level

Supabase dashboard → `dzonzgngwxclhfnvxtvu` → **SQL Editor** → (1) the FX-18 first statement, (2) one pasted
transaction-wrapped block, (3) the count/ACL re-queries for the equivalence diff. No Table Editor writes, no Migration
feature, no `db reset`, no `--role-only`, no `pg_dump`, no CLI, no Dashboard "add column" hand-fixes.

### 4.3 Preconditions

* **A2′(a) signed AND executed** — the sentinel must exist first.
* **`select count(*) from auth.users;` on ref `dzonzgngwxclhfnvxtvu` is the FIRST statement of the A3 window**, recorded
  with the ref and UTC timestamps, closing FX-18 (the Auth page renders zero rows yet prints `Total: 10 users
  (estimated)`). **If the count is not 0 — STOP.** The clean-shell premise fails, P01 §0.4's pre-check cardinality is void,
  the "a wrong-project run is impossible" argument is void, and until 2026-11-03 the count has simply never been run, so
  any claim that staging "has no auth users" is `NOT VERIFIED`.
* **Transaction wrap proven, not assumed.** The artefact as measured on 2026-11-02 had **no transaction wrap**, and its
  H-3 finding is that `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin …` may abort at statement **#448** while the
  preceding **447 statements persist** — a half-applied baseline with no restore point. Signing A3 requires the operator
  to paste a block carrying a single explicit `BEGIN … COMMIT`/`ROLLBACK`, and to record its presence in the change record
  *before* execution. An unwrapped load is a different action and is **not** authorised here.
* **Completed secret scan** of the artefact with hits reviewed and recorded, never silently redacted (`prosrc` is the one
  catalogue column that can hold a pasted credential; the 24 absent bodies are unscanned and unscannable and the artefact
  says so). The scan record is itself weak — 13 of 22 files covered, normalisation unstated — class `NOT VERIFIED`.
* **Digest bound in A3's own change record** with a durable, owner-named home for the artefact; it currently lives outside
  the repository in an OS-temp directory over zero commits.
* **X-4 dispositioned:** of the 4 emittable policies, `webrtc_signals_insert_participant` renders the invalid text
  `USING (None)` at `60-rls-policies.sql:71`; **3 of 4 are emittable as written**, and the 4th must be re-rendered before
  load or dropped from the load and recorded. `emittable ≠ actionable`.
* **A1 is NOT a precondition of A3** (C-2: `INOPERATIVE` under the staging-only absolute) and A3 authorises no production
  access; the artefact is reconstructed offline under approved A0 as amended by C-1, from the in-repo `g1-*` capture.

### 4.4 Evidence required afterwards

Artefact SHA-256 (raw-byte **and** CRLF-normalised, with the relationship between them stated), secret-scan result, the
`auth.users` count with ref and UTC timestamps, the transaction-wrap evidence, a per-statement restore log, before/after
counts for every §4.1 class, the equivalence table with each difference named and accepted, per-object provenance labels
(`VERIFIED FROM SOURCE` / `RECONSTRUCTED FROM MULTIPLE SOURCES` / `INFERRED` / `UNVERIFIED` / `NOT PRESENT IN EVIDENCE`),
statement error text if any, and the **post-load denial observation recorded as `DENY — VACUOUS`, never as `PASS`**.

### 4.5 Rollback / reversal path

No platform restore point exists (R-35: Free, no backups, no PITR) and the delete-and-re-create branch is **withdrawn**
(R-38: 2 active / 2 used / 0 remaining; slot reuse after deletion `UNPROVEN`; whether a paused project counts toward the
cap `NOT VERIFIED`). Reversal is therefore **only** a signed drop script: `DROP …` in reverse dependency order over the
same object list the artefact created, authored offline **before** the load and hashed alongside it — a load without its
drop script is irreversible in practice, and this instrument does not authorise one. On a DDL error inside the wrap:
`ROLLBACK` restores the prior state; outside it, stop at statement *n*, classify, repair in place within one session or
record the state (04 §2.4). A3 without a rehearsed rollback also leaves production-gate item 4 `BLOCKED`, which no
signature changes.

```text
A3 — SCHEMA LOAD OF THE TRANSACTION-WRAPPED MIGRATION, STAGING ONLY
I have read docs/stage2/approval-package-v3-implementation-instruments.md §4. I approve applying the hashed,
secret-scanned, EXPLICITLY TRANSACTION-WRAPPED G3 artefact to dzonzgngwxclhfnvxtvu in dependency order, with the
auth.users count as the first statement and with a signed reverse DROP script in hand before the paste.
I have read §4.1 and I sign it with this understanding: the load yields 19 tables, 137 constraints, 34 indexes,
19 RLS enables, 248 grants and 4 policies with 0 functions and 0 triggers — a DENY-ALL SHELL for authenticated in which
reads return 0 rows and writes fail 42501. Signing A3 does NOT make the backend application-ready, does NOT create the
Firebase-UID mapping table, does NOT re-enable RLS as a live control on a service-role path, and does NOT permit any
post-load observation to be recorded as PASS. If my expectation was a working application, this fence is not signed and
§16.2 actions 2 and 3 come first.
This authorises NO table data, NO production row, NO patch (A5), NO secret (A9), NO Edge Function (A7-R/A8-R), NO
fixture (A14), NO Firebase action (A12-R/A13), NO hand-edit of the artefact after scan, NO db reset / --role-only /
pg_dump / CLI, and NO production access of any kind. A1 remains INOPERATIVE and is not a precondition.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 5. A9 — secrets and credentials

### 5.1 What signing this permits, in plain English

A9 permits the creation of **fresh, staging-only** secret values and the setting of them in their only permitted homes. It
permits naming secrets and recording digests; it never permits a value to leave the platform console into a document.
Explicitly not permitted: copying, pasting or referencing any production value; reading or writing a secret value into
this repository, a change record, a transcript, a log **or a screen capture**; rotating the production pepper (forbidden in
Stage 2); creating any Firebase credential beyond what A12-R's box (b) ticked; anything in production. A9 also carries a
pre-existing liability: **the staging database password already exists with unmanaged custody (R-39)** — the owner typed it
in the browser, no value entered the repo, the record or the transcript, no vault holds it, and whether any copy exists
outside the owner's control is the owner's to confirm. **Re-setting that password is itself an A9 action** and must not be
performed under the ratification, A2′ or A3.

### 5.2 Which secrets, and where each may live

| Name (identifier only — never a value) | Permitted home | Notes |
| --- | --- | --- |
| `anon key` (Data API publishable key) | Supabase dashboard → Project Settings → Data API; owner's password manager | public-ish client key; still name+digest only in records |
| `service_role` key | Supabase dashboard → Project Settings → Data API; owner's vault | **never ships in a client**; its use on the live path is precisely why RLS is inert (§8.1) |
| Database password | Supabase dashboard → Project Settings → Database; owner's vault | re-set here = R-39 closed by rotation |
| JWT signing secret | Supabase dashboard → Project Settings → Data API | rotation invalidates every issued token at once (A7-F03) — not a session kill switch |
| `PAIRING_HASH_PEPPER` | Supabase → Project Settings → **Edge Functions → Secrets** | independent staging value; production pepper not rotated |
| `CRON_SECRET` | Edge Functions → Secrets | the deployed `cron` returns 503 below 16 chars — a length rule, not a value, is quoted here |
| TURN credentials (`TURN_SECRET`) | Edge Functions → Secrets | A7-F10: a deployed bundle references it while the secrets register files TURN as "Future" |
| Firebase Android API key / `google-services.json` contents | Firebase config file **outside** `D:\control`; Supabase Edge Secrets if a function needs it | an Android client key is not a secret from the device, but its value still never enters a repo file or capture |
| Service-account JSON (only if A12-R box (b) ticked) | owner's vault + Supabase Edge Secrets | never in a client; needed for custom claims and revocation checks (§3.2) |

### 5.3 Operations, named at dashboard level

Supabase → `dzonzgngwxclhfnvxtvu` → Project Settings → **Data API** (reset/rotate, read the key *names*), → **Database**
(reset password), → **Edge Functions → Secrets** (add by name, paste value once, save, verify). No value is ever copied
into the SQL Editor for logging; no value is pasted into a document. `.env.example:5` must be fixed **before** any `.env`
is created from it, because `cp .env.example .env` today yields a staging-labelled build pointed at production.

### 5.4 Preconditions

Ratification (i); A2′ complete for settings; **A3 for anything the functions read**; A13/A12-R rulings so the
revocation-credential need is known; the R-39 custody question faced head-on rather than assumed closed; a password
manager or equivalent owner-side store identified by name (not by contents).

### 5.5 Evidence required afterwards

Secret **name**, the **digest shown in the dashboard secrets list**, the set → verify sequence per name, the UTC timestamp
of each, the statement that no value was read or typed by any agent, the statement that no value entered a repository file
or a screen capture, and a name-only list of what was **not** created. A staging connection attempted before R-39 is
closed is itself a stop condition.

### 5.6 Rollback / reversal path

Re-rotate inside staging (a fresh value supersedes; old anon/JWT values stop validating); revoke a service-account key by
**deleting it** in the Google Cloud console and confirming its key ID is absent; delete an Edge secret by name. None of
these is available on the other side: **there is no un-rotation of a leaked value, only replacement**, and a value that
reached a repository file must be treated as leaked and replaced, not edited out. Production is out of reach: no A9 action
may be pointed at `hhqgreaoqulmfwfwarhc`.

```text
A9 — SECRETS AND CREDENTIALS, STAGING ONLY
I have read docs/stage2/approval-package-v3-implementation-instruments.md §5. I approve creating fresh staging-only values
for the names in §5.2 in dzonzgngwxclhfnvxtvu (and, only where A12-R box (b) is ticked, a service-account key held per
§5.2), evidenced by NAME AND DIGEST ONLY. I accept that re-setting the staging database password is an act of this
approval and is how R-39's unconfirmed custody is closed. I impose the absolute rule: no secret VALUE enters any
repository file, change record, transcript, log or SCREEN CAPTURE, and no production value is copied, pasted, referenced
or read.
This authorises NO production secret, NO rotation of the production pepper, NO Firebase provider or app registration
(A13/A12-R), NO schema object (A3), NO patch (A5), NO fixture (A14), NO Edge deploy (A7-R/A8-R). I further confirm
.env.example is repaired before any .env is created from it.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 6. A5 — patch execution (S2-P01 → S2-P02 → S2-P03), staging only

### 6.1 What signing this permits, stated without flattering it

A5 permits applying **P01, then P02, then P03** in that order to `dzonzgngwxclhfnvxtvu`, each inside an explicit
transaction, with §0 pre-checks read before the body, post-checks asserted rather than eyeballed, and a rollback rehearsal
after each. **As shipped, P02 aborts unconditionally** — D-07: its approval gate is commented out while its own block
requires it, so the applied text ≠ the hashed text and the file cannot reach commit. **P03 is blocked** — it has no
in-file rollback (D-10), its header omits both preconditions (D-11), and the pre-check it needs (the read-only production
duplicate-session count) can no longer be authorised because A1 is `INOPERATIVE`. And the actor-binding fix A5 would apply
in P02 is **inert on the live path while callers authenticate with `service_role`**: `rls_forced` is false on all 19
tables, `auth.uid()` is NULL for real callers, actor identity is application-supplied on both tiers, and A7-F11 states the
conclusion directly — **"actor binding fixed" would be a false statement about the live path**. So A5's honest product is
P01 (an ACL/`search_path` change that *tightens* EXECUTE grants and is executable once A3 lands) plus two files that need
new work, not new signatures. All twelve defects D-01…D-12 remain OPEN and the three files are currently byte-identical to
their recorded pre-correction digests (P01 `1edad404…97be51`, P02 `01403cd7…b88c67`, P03 `8f92cc0f…d60ecd4`).

### 6.2 Operations, named at dashboard level

Supabase → `dzonzgngwxclhfnvxtvu` → **SQL Editor** → one hashed file per session, wrapped `BEGIN … COMMIT`, with the
sentinel guard SELECT as the first statement of each; then the post-check SELECTs; then the rollback text executed against
staging as a **rehearsal** (apply → reverse → re-apply) recorded with timings. No editor SQL improvised between patches; no
catalogue `UPDATE`.

### 6.3 Preconditions

**A3 complete and the objects present** — every patch self-aborts on the absent sentinel, and P01's §0 pre-checks
hard-`CAST` functions that do not exist in an empty database (PE-01); rollback is not even rehearseable before A3.
**D-01…D-12 cleared and the three files re-hashed**, with the new digests written into this instrument's change record —
including D-07 (P02's gate) and D-06 (post-checks must assert `prosrc` hash and overload count). No patch may be applied
whose executed file hash is not the hash signed here. A10 named for any reversal. Production application remains a
different object entirely: **A6 plus the 7-item gate, which does not exist** (items 1 and 4 are `BLOCKED`).

### 6.4 Evidence required afterwards

Hash of **the file actually executed** (not of the file intended); full §0 output; post-check output with the mandatory
assertions; test IDs and results; the exact rollback text and the rehearsal timings; the separate-time reviewer pass notes
(R-16); and — for P02 — a written statement on the record that **the actor binding is inert while callers use
`service_role`**, so no later document can translate "P02 applied" into "E3/F7 closed".

### 6.5 Rollback / reversal path

Reverse order **P03 → P02 → P01**. P01: `grant execute … to public` ×2 plus `alter function … set search_path = public,
pg_temp` — behaviour restored, **ACL not byte-identical** (`proacl` becomes explicit instead of `NULL`: R-04), accepted
and recorded, never `UPDATE pg_proc`. P02: `create or replace` each of the three bodies with the pre-apply text captured
from the staging catalogue immediately before apply, restating `SECURITY DEFINER` and the original `search_path`; OID and
ACL survive `CREATE OR REPLACE`; **audit rows already written by a forged actor are not corrected** — that is a separate
data decision. P03: `drop trigger if exists remote_sessions_insert_guard on public.remote_sessions;` → `drop function if
exists private.remote_session_insert_guard();` → `drop index if exists public.remote_sessions_one_live_per_device;` —
rows expired by the trigger stay expired; rollback restores behaviour, not data. Each reversal re-opens the exploit it
closed (E2/F8, E1/E3, E4) and needs **A10** plus a recorded reason. No platform restore exists behind any of it.

```text
A5 — PATCH EXECUTION (P01 -> P02 -> P03), STAGING ONLY
I have read docs/stage2/approval-package-v3-implementation-instruments.md §6. I approve applying S2-P01, then S2-P02, then
S2-P03 to dzonzgngwxclhfnvxtvu in that order, each inside an explicit transaction with §0 pre-checks read, post-checks
asserted and a rollback rehearsal after each, AFTER D-01…D-12 are cleared and all three files re-hashed, and only where
the executed file hash equals the hash recorded.
I sign with these facts on the record: P02 AS SHIPPED ABORTS UNCONDITIONALLY (D-07) and must be corrected before it can
run; P03 IS BLOCKED (D-10, D-11, and its pre-check depends on a production read A1 can no longer authorise); and the P02
actor-binding fix is INERT WHILE CALLERS USE service_role, so "actor binding fixed" is a false statement about the live
path and no change record may say it. This is not A6: it authorises NO production application, NO secret creation or
rotation (A9), NO Edge deploy (A7-R/A8-R), NO fixture (A14), NO Firebase action (A12-R/A13), NO improvised catalogue
repair, and NO rehash-free file.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 7. A7-R / A8-R — Edge Function source export and deployment

### 7.1 The collision, resolved

`04-risks-rollback-approvals.md:215` gives A7 ("Export Edge source") the forbidden column **"Editing live functions in the
dashboard; deploying from a minified bundle"**, and `:216` gives A8 ("Deploy an Edge Function") **"Production deploy by an
agent; deploying untested source"** plus a required repo diff. **7 of the 9 evidenced functions exist only as minified
bundles** (`device-command`, `device-register`, `device-policy`, `device-telemetry`, `family-admin`, `remote-session`,
`cron`), there are **no source maps**, and `supabase/functions` is **absent** from the repository. Therefore **as written
the two gates are mutually unsatisfiable for those 7**: A8 cannot accept source A7 cannot lawfully produce. The collision
is independent of every signature — signing A7/A8 unchanged creates no deployable source; only an owner ruling changes
what is possible. Note also that the browser-only channel is part of the trap: exporting from the dashboard yields the same
bundle. A7-R is therefore issued as **a choice of exactly one option**, and A8-R inherits it.

* **Option 1 — obtain readable source out of band.** The owner supplies the original TypeScript source tree (or matching
  source maps) from wherever it exists outside this repository, as an owner-held artefact with a digest, after which A7's
  prohibition is satisfied because the bundle was never the source. This programme has **never performed such an export**
  (U-12 OPEN/DEFERRED), so Option 1's cost is a real owner-side search for the pre-deploy repo. Nothing is re-authored;
  parity is provable by diff.
* **Option 2 — authorise re-authoring the seven from specification.** New engineering, **not migration**: each function is
  rewritten against the captured contract (§8.1's auth-model rows: parent/child JWT + verified email, `x-device-id` +
  `x-device-secret` for device-only paths, `x-cron-secret` with the ≥16-char rule) and labelled
  **`RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION`** in every artefact, test record and change record. The
  label is mandatory and may not be dropped in later documents; the owner accepts that behaviour may differ from what is
  deployed, that 8 of 9 depend on `private.*` SQL the artefact emits **0 of**, and that a redeploy without those functions
  simply fails at its first RPC.

Two functions — `pairing` (972 readable lines) and `auth-bootstrap` (140 readable lines) — are separable from the seven
and their deployment can be authorised independently of the option chosen. **The brief's nine names
(`notification-cron`, `register-token`, `verify-firebase-token`, …) appear in no repository evidence and there is nothing
to export or deploy for them** (P-1); `verify-firebase-token` is `MISSING — SOURCE EVIDENCE ABSENT`, so under A13 its
function must be authored, not reviewed.

### 7.2 Operations, named at dashboard level

Supabase → `dzonzgngwxclhfnvxtvu` → **Project Settings → Edge Functions** (deploy/register, one slug at a time, staging
ref only) and **Edge Functions → Secrets** (set before deploy where a function reads one). **No "edit code in the
dashboard" for live functions** (A7's own prohibition survives any re-scope). Production function surface is not opened.

### 7.3 Preconditions

Option ticked in the fence; A3 landed (otherwise every deployed function fails its first `private.*` RPC); A9 landed for
functions that read secrets; A12-R/A13 ruled if a function must verify Firebase tokens; readable source in hand or the
re-authoring specification signed; staging test plan for each slug; the error-shape contract preserved (R-12: new
409/`42501`/500 must be mapped to existing client codes before any production thought).

### 7.4 Evidence required afterwards

Per slug: source form (`READABLE SOURCE SUPPLIED` or `RE-AUTHORED — NO PARITY VERIFICATION`), file digest, the repo diff
A8 requires, the staging test executed and its result, the error shapes returned, the statement that no minified bundle
was deployed and that no live function was edited in the dashboard, the secret names read (never values), UTC window, and
the separate-time reviewer pass.

### 7.5 Rollback / reversal path

Supabase → Edge Functions → **delete the deployed function** (staging only), which returns staging to "Edge function
cannot be found" — the observed current state — so reversal is genuinely available and cheap here. If a secret was changed
to make it work, that is an A9 rotation event with its own record. Reversal of an Option-2 re-authoring additionally means
deleting the authored source from the record or re-labelling it `SUPERSEDED`, so the codebase cannot later be read as
parity-verified. No production Edge deployment is in scope under any option (A6/A8 boundary; `04` §3.2 forbids it, and R-20
keeps P03's 500 a staging caveat precisely because the mapping is absent).

```text
A7-R / A8-R — EDGE FUNCTION SOURCE EXPORT AND DEPLOYMENT
I have read docs/stage2/approval-package-v3-implementation-instruments.md §7. I acknowledge the collision: A7 forbids
"deploying from a minified bundle", 7 of the 9 evidenced functions exist only as minified bundles with no source maps, and
the repository holds no Edge source — so as written the two gates are mutually unsatisfiable for those 7 and no signature
alone resolves them. I select exactly one option:
  [ ] OPTION 1 — READABLE SOURCE OBTAINED OUT OF BAND. The owner supplies the original source (or source maps) with a
        digest; A7's prohibition is satisfied because a bundle is never the source; parity is diff-provable.
  [ ] OPTION 2 — AUTHORISE RE-AUTHORING THE SEVEN FROM SPECIFICATION. This is NEW ENGINEERING, NOT MIGRATION, and every
        artefact, test and change record for those seven must carry the label
        "RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION". That label may never be dropped downstream.
Separable authorisation:  [ ] deploy the two readable functions (pairing, auth-bootstrap) to staging under A8-R.
I confirm A7-R's surviving prohibitions: NO deploying from a minified bundle, NO editing live functions in the dashboard,
NO production Edge deployment by any agent, NO deploying untested source, NO secret value in any record. I accept that
with A3 incomplete, or with the private.* RPCs absent, a deployed function fails at its first call, and that
notification-cron / register-token / verify-firebase-token and the other six brief names exist in no repository evidence.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 8. A14 (new) — synthetic test fixtures (staging only)

### 8.1 What signing this permits, in plain English

A14 permits creation, in `dzonzgngwxclhfnvxtvu` **only**, of **synthetic** parent accounts, child accounts and devices —
plus the families, memberships, policies, sessions and telemetry rows the tests need — so that the programme's zero
executed functional and security tests can become executed tests. **No A11-style row covers this in its A13 form**: `04`
§3 row A11 exists (owner, staging only, synthetic fixture list, deletion plan) but is unsigned, predates the identity
change, and does not contemplate Firebase-UID principals or mapping rows. A14 is the identity-aware successor and must state
which identity model the fixtures are born under. **PII rule, absolute:** no real personal information and **no real child
data** — no real name, no real email domain, no real device, no real location history, no production identifier of any
kind; reserved-domain addresses (`@example.invalid` and equivalents) and fixed test UUIDs only; no production email may
appear in any staging fixture; no production row may be copied into staging (that is R-11, a catastrophic-risk row on a
product holding children's location data). Explicitly not permitted: any test user, family or device in production; any
real-user import; any telemetry that could be mistaken for observed data; and any `PASS` claim from a fixture that
vacuously satisfies an absent policy.

### 8.2 Which tests are impossible without A14

Every functional and security test in the programme's scope is currently `NOT RUN` (0 executed) precisely because no
principal exists to run it. Concretely, without A14 the owner cannot get: any `auth.uid()`-dependent policy test, including
the 4 emittable policies (`families_update_owner`, `profiles_update_self`, `webrtc_signals_insert_participant`,
`webrtc_signals_select_participant`) and the 2 known-unreachable ones (`devices_select_parent_or_child`,
`safe_zones_insert_parent`); parent↔child membership isolation tests; the `handle_new_user` provisioning path (which
**cannot fire at all** for a Firebase-authenticated user — see A13 §1.2); Firebase-UID → profile mapping and
cross-family UID-conflict tests; device registration, pairing and command/ack tests behind `x-device-id`/`x-device-secret`;
single-live-session enforcement (P03's `23505`/500 error-shape, R-20); remote-session and WebRTC signal tests, including
the `webrtc_signals.from_user_id` NOT-NULL failure mode; retention and audit-append tests; the `cron` expiry run with a
real device set; and any APK smoke against staging. With A14 and nothing else signed, all of the above stay impossible —
A14 sits **behind** A3 and behind the identity ruling, it does not bypass them.

### 8.3 Operations, named at dashboard level

Supabase → `dzonzgngwxclhfnvxtvu` → **Table Editor / SQL Editor** (fixture inserts inside an explicit transaction, each
labelled with a fixture-ID prefix) and, if Supabase Auth were retained, **Authentication → Users → Add user** with
`email_confirm` handled per R-08 (Free sender cap `NOT VERIFIED`; the pre-verified path is a deviation to record, not to
whisper). Under A13, identity principals are created through the Firebase-served path and only their **mapping and profile
rows** are written here. No `auth.users` row is ever hand-edited, and the `auth.users` trigger stays a never-applied
component unless separately instructed.

### 8.4 Preconditions

A3 landed (a deny-all shell cannot host a meaningful fixture test — see §4.1, and record fixtures created before
behavioural objects exist as `VACUOUS`); A13 ruled, so the fixture's identity model is known; A2′(a) sentinel present;
A9 landed where a fixture exercises a secret-dependent path; a fixture manifest naming every synthetic identity and the
deletion plan **before** creation; reserved domains confirmed by a written rule, not by habit.

### 8.5 Evidence required afterwards

The synthetic fixture list with the reserved-domain/UUID pattern actually used, counts by class (parents/children/devices
vs the production reference counts **never copied**), confirmation that no production identifier, email or row appears in
any staging object, the UTC window, the deletion plan as recorded, and a per-test note that no result was derived from an
absent policy. Fixture manifests are redacted of any credential name-with-value; names only.

### 8.6 Rollback / reversal path

Delete by fixture-ID in reverse dependency order (telemetry → sessions → commands → devices → policies → memberships →
families → profiles → principals), inside an explicit transaction, with before/after counts; teardown ends with the
redacted evidence export and the fixture manifest, then the deletions (04 §2.5 teardown row). A fixture that cannot be
identified by prefix is a contamination incident, not a cleanup: record it as a finding rather than deleting ad hoc, and
never "fix" it by touching production. Free has no PITR, so reversal is data-level and hand-written, and the only
whole-database "undo" — deletion and re-creation — remains withdrawn (R-38, 0 slots).

```text
A14 — SYNTHETIC TEST FIXTURES, STAGING ONLY
I have read docs/stage2/approval-package-v3-implementation-instruments.md §8. I approve creating SYNTHETIC parent, child
and device accounts with their families, memberships, policies, sessions and telemetry in dzonzgngwxclhfnvxtvu ONLY,
under a fixture manifest recorded BEFORE creation, with a deletion plan and a fixture-ID prefix on every row.
PII rule, absolute: NO real personal information and NO real child data; reserved-domain addresses and fixed test UUIDs
only; no production email, identifier, row or device credential in any staging object; no production data copied to
staging; no hand-edit of auth.users.
I acknowledge that without this instrument the functional and security test set remains 0 executed, and that with it and
nothing else signed the tests remain impossible because A3 and the identity ruling come first. I further acknowledge that
a fixture test run against a 4-policy deny-all shell can only be recorded VACUOUS, never PASS.
This authorises NO production fixture, NO real-user import, NO schema change (A3), NO secret (A9), NO patch (A5), NO Edge
deploy (A7-R/A8-R), NO Firebase provider or app (A13/A12-R) and NO project deletion or re-creation.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 9. Auto-pause obligation — the dated dashboard touch due on or before 2026-11-06

### 9.1 What it requires

Free/NANO Supabase projects pause after **7 days without activity**, and the clock started at **creation (2026-10-30)**,
not at the first patch. Both staging surfaces are therefore under a running clock with **no recorded UTC start and no
record stating the exact expiry** — only the local display `Oct 30, 5:25pm–6:25pm` was ever captured (U-10, R-40). The
obligation is a **dated dashboard touch on or before 2026-11-06**, written in no operational plan and assigned to nobody
(S4-BL-10). 2026-11-06 is *the latest date the touch can fall on*, not a measured deadline. This is not an approval — no
gate covers it, and it cannot be discharged by signing anything; it is discharged by an observation, recorded.

### 9.2 The unresolved criterion, stated as `NOT VERIFIED`

**Whether a read-only page view counts as "activity" for the idle clock is `NOT VERIFIED`.** The 2026-11-02T07:16Z
read-only re-confirmation session was composed entirely of failed pointer actions
(`NATIVE_BROWSER_VIEWPORT_UNAVAILABLE`) with pages reached by URL navigation, and whether that session reset the Free-plan
idle clock was never established (S2-EXEC-FINAL §15, `:201`/`:236`). So the programme cannot claim, on the evidence, that
any observation it has performed satisfied the obligation — and it equally cannot claim the opposite. The conservative
reading is that **only a genuine dashboard interaction on the project page is a defensible touch**, and that a paused
project's slot cost is `NOT VERIFIED`, so pausing must never be used to test anything (R-38).

### 9.3 Status of today's observation

The main agent's browser observation of the staging project today **discharges this obligation as a dated observation
only**: it establishes that on that date the project was reached and its status was read, and it is recorded in UTC with
the ref echoed from the console header. It does **not** prove the idle clock was reset, is not an approval, is not a write,
confers no authorisation for A2′(a)/A3 or anything else, and does not exempt the next window — **a fresh dated touch is
still required before 2026-11-06, and if a scheduled window (G6 → G3 → G5-S) is planned, it must fit inside one 7-day
active span with a dated start.**

### 9.4 Reversal / what happens if it pauses

Supabase → project → **Restore project** — a resume, recorded in the change record, needing no approval beyond the window
already signed; then re-verify before continuing: the sentinel value, table/policy/function counts and the last applied
patch's post-checks (**today there is nothing to re-verify against: no sentinel exists and the schema is empty, so these
checks have no objects until A3 runs**). If it pauses **and cannot be restored**: stop the window, record the state, do
**not** delete and do not create a replacement in the same session — 0 slots remain (R-38). Deletion or re-creation is
never an agent-chosen recovery step; it requires a new owner-written A2 (+ A3) stating why the first attempt failed, and
the previous records stay on file as history.

```text
AUTO-PAUSE OBLIGATION — DATED OBSERVATION AND CONTINUING OWNERSHIP
I have read docs/stage2/approval-package-v3-implementation-instruments.md §9. I record that a dated dashboard touch on the
Supabase staging project dzonzgngwxclhfnvxtvu (and the matching Firebase observation) is required ON OR BEFORE 2026-11-06,
that no UTC start or expiry exists anywhere in the record, and that WHETHER A READ COUNTS AS ACTIVITY IS NOT VERIFIED.
I accept that today's main-agent browser observation discharges the obligation AS A DATED OBSERVATION ONLY: it proves the
project was reached and read on that date; it does not prove the idle clock was reset; it authorises nothing.
I instruct that any coordinated G6 -> G3 -> G5-S window fit inside one 7-day active span with a dated UTC start, and that
if the project pauses, the recovery is Restore + re-verify, NOT delete: I do not authorise deletion or re-creation, and I
confirm 0 project slots remain (2 active / 2 used), so no replacement target exists.
This is an obligation record, not an approval: it authorises NO sentinel, NO load, NO patch, NO secret, NO fixture, NO
Edge Function, NO Firebase action and NO production action of any kind.

STATUS: UNSIGNED

OWNER (name): ______________________   DATE/TIME (UTC): ______________________
```

---

## 10. Dependency table

| Instrument | Signing it unlocks | What remains blocked after signing it | Next instrument |
| --- | --- | --- | --- |
| **A13** Firebase Auth as identity authority | The identity ruling itself; the four superseding wordings in §1.4; the A12-R attestation branch (1); every "which identity model" question in A3/A8-R/A14 | The mapping table (not in the artefact — needs A3 or an A3 addendum); provider enablement is still an unexecuted cloud action; the two `auth.uid()` column-default breakages; `tokens_valid_after` storage; custom claims/revocation credentials (A12-R (b) + A9); every app registration; Firestore/Functions still forbidden | **A12-R** (and an A3 addendum for the mapping table) |
| **A12-R** registration + FCM transport | Android app registration; `google-services.json` handling; optional service-account key; optional FCM test send; SHA fingerprint entry **once §2.2 is answered** | Working push — no registration-token column, no `push_tokens` table, no server-side sender, no `POST_NOTIFICATIONS` work; identity providers; any credential in the repo; billing; iOS/Web unless ticked | **A2′(a)** if no Firebase work is queued, else **A9** |
| **A2′(a)** staging sentinel | The sentinel creation, and the first-ever `current_database()` measurement that decides whether wrong-project loads are detectable | The schema (A3); the settings checklist and Realtime publication (A2′(b), not executable before A3); every patch still self-aborts until this runs | **A3** |
| **A3** schema load | 19 tables / 137 constraints / 34 indexes / 19 RLS enables / 248 grants / 4 policies; rollback rehearsal becomes possible; A2′(b) becomes executable; fixtures become storable | **Behaviour**: 0 functions, 0 triggers, deny-all for `authenticated`; the 25 return-type-blocked objects; the Firebase-UID mapping table unless added; production-gate items 1/3/4 stay `BLOCKED` | **A2′(b)** → then **A9** |
| **A9** secrets and credentials | Fresh staging values, name+digest evidence, closure of R-39 by password re-set; the preconditions Edge functions need | Any production value; the production pepper; deploy of any function (A7-R/A8-R); patch application; any claim that secrets prove connectivity works on a deny-all schema | **A5** (if patches are the goal) or **A7-R/A8-R** |
| **A5** patch execution | P01 application and its rehearsal; per-patch post-checks; the corrected-file re-hash chain | P02 until D-07 is fixed; P03 until D-10/D-11 and its production duplicate count are resolved; the *live-path* effect of the actor binding (inert under `service_role`); production application (A6 + 7-item gate) | **A7-R/A8-R** for the `23505`/500 mapping; **A14** for behavioural tests |
| **A7-R / A8-R** Edge source + deploy | Either the supplied-source path or the re-authoring path for the seven; deploy of the two readable functions to staging | Parity for anything re-authored (permanently labelled `NO PARITY VERIFICATION`); deploys that need `private.*` RPCs the artefact emits 0 of; any production Edge deploy | **A14** (functions with no principals to call them cannot be tested) |
| **A14** synthetic fixtures | The first executed functional and security tests; policy-reachability, membership-isolation, device/pairing, session and `cron` behaviour | Tests of the Firebase-UID provisioning path if A13 landed without the mapping table; `PASS` on any policy absent from the 4; production fixtures; the missing Edge source for anything that calls a function | **A2′(b)/A5/A8-R** as the window requires |
| **Auto-pause obligation** | Nothing (it is not an approval) — it keeps the target alive so every other instrument can be executed inside one 7-day span | The `NOT VERIFIED` activity criterion; the unrecorded start/expiry; a paused target's slot arithmetic | any instrument, in window order |

---

## 11. Sign these in this order

1. **§9 Auto-pause obligation** — record it first; it is not an approval but it bounds every execution window that
   follows, and its touch date is the one hard calendar fact here.
2. **A13** — the identity ruling, with §1.4's four wordings applied as a recorded documentation change. Nothing behind it
   has a stable meaning until this is settled, and A12-R cannot be attested honestly either way until it is.
3. **A12-R** — with the §2.2 signing-certificate statement filled in the same sitting; the fingerprints stay unconfigurable
   if the owner defers that answer, so tick transport-only rather than leaving it ambiguous.
4. **A2′(a)** — sentinel, before any load, and it also performs the `current_database()` measurement.
5. **A3** — only after §16.2 actions 2 and 3 (return-type admissibility; accept-or-reject a structural-only baseline) are
   ruled, and only with a signed reverse drop script and an explicit transaction wrap.
6. **A2′(b)** — settings and the four-table Realtime publication, once the tables exist.
7. **A9** — secrets, closing R-39 by re-setting the staging DB password.
8. **A14** — synthetic fixtures, so behavioural and security tests become executable at all.
9. **A5** — P01 now; P02/P03 only after their defects are cleared and re-hashed.
10. **A7-R/A8-R** — last: it depends on A3 (RPCs), A9 (secrets) and the A13 ruling (token verification).

**Do not sign A5, A7-R/A8-R or A14 on the assumption that A3 produced a working application** (§4.1). Signing is not
execution: each instrument authorises one operation set, and each half of A2′ is executed and evidenced separately.

---

## 12. Signature state of this file

**No instrument in this file is signed by anyone at time of writing.** All nine fences are blank; all nine carry
`STATUS: UNSIGNED`; no name, initials or UTC time has been transcribed into any of them, and none will be by any future
documentation pass — a recorded decision is not a signature (R-29, and the v2 `:161-163` precedent for the ratification
fence). This file authorises nothing by existing: no dashboard was opened, no URL visited, no SQL run, no setting changed,
no secret read or created, no project created, paused, resumed or deleted, no CLI/REST/DevTools call made and no
credential exported in its making, and it touched no existing record — `approval-package-v2-ratification-and-forward.md`
and `04-risks-rollback-approvals.md` remain as they were, including the sentences §1.4 proposes to supersede, which stay
in force until the owner signs A13 and applies those replacements as a separate recorded action.
