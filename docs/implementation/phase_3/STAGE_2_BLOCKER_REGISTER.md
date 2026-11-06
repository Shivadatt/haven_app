# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 BLOCKER REGISTER

**Scope**: every item that stops Stage 2 (or a later stage) from being credited above its evidenced level
**Date**: November 6, 2026
**Status vocabulary**: `BLOCKED` (needs an owner decision or an external capability) · `NOT TESTED` (could run, did not) · `DEFERRED` (scheduled elsewhere) · `PROPOSED` (awaiting approval) · `PARTIAL` · `COMPLETE`
**Rule**: a blocker is closed only by evidence, never by a claim.

---

## 1. Carried forward from Stage 0/1 (unchanged, still open)

| ID | Item | Type | Blocking dependency | Owner action that closes it | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **B-1** | Real parent-phone ↔ child-phone pairing | decision + capability | no backend, no approved rendezvous transport | answer **D-5**; Phase 4 backend or a named, reviewed local transport | **BLOCKED** |
| **B-2** | Consumer-device app blocking/killing without Device Owner | platform + policy | Play policy, no Device Owner path on consumer devices | Stage 5 feasibility gate; accept "no approved enforcement" as a legitimate verdict | **BLOCKED** |
| **B-3** | Physical-device verification rows | environment | no device attached (`Pixel_9a` AVD only) | hand off a Realme RMX2161 (or equivalent) with an ADB/emulator allowance | **NOT TESTED** |
| **B-4** | Continuous background reliability on OEM ROMs | platform | ColorOS/OEM battery managers; no repo code | device handoff + Stage 7 foreground-service work | **BLOCKED** |
| **B-5** | Committing Phase 2/3 sign-off docs | governance | the app contract forbids agent git operations | owner commits. Current tree: 131 staged additions, 7 staged modifications, 1 staged-add-modified, HEAD `8e50da0` | **BLOCKED (owner action)** |
| **P-1** | Physical child test device | environment | as B-3 | device handoff | **NOT TESTED** |
| **P-2** | Written pairing-code spec + `PairingCodeFormat` export decision | decision | **D-3** | sign the D-3 approval field | **PROPOSED** |
| **P-3** | Child applicationId + Gradle module strategy | decision | — | resolved in Stage 1 (`com.haven.child`, separate Gradle project) | **COMPLETE** |
| **P-4** | Same-device exchange mechanism decision | decision | **D-5** | sign the D-5 approval field | **PROPOSED** |
| **P-5** | Kotlin test infrastructure (JUnit + Robolectric, source sets) | dependency + decision | **D-4** (+ gradle change) | approve or decline the §5 recommendation in STAGE_2_TEST_STRATEGY | **BLOCKED** |
| **P-6** | Typed channel tooling decision | decision | **D-4** | sign the D-4 approval field | **PROPOSED** |
| **P-7** | Permission explanations + privacy disclosure copy | content | per-module copy | owner/stage authors it | **DEFERRED** |
| **P-8** | Commit/push of Phase 2 sign-off docs | governance | as B-5 | owner action | **BLOCKED (owner action)** |

## 2. New Stage 2 blockers

| ID | Item | Evidence | Why it blocks | Status / owner action |
| :--- | :--- | :--- | :--- | :--- |
| **S2-01** | The Stage 2 brief's recommended code shape (6-digit numeric) is rejected by the deployed backend validator | [identifiers.ts:24-25,61](file:///d:/control/backend/supabase/functions/_shared/identifiers.ts#L24-L25), [redeem.ts:48](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L48) | adopting it produces a local contract that can never redeem; adopting the backend shape changes the Phase 1/2 simulation | **BLOCKED on D-3** — choose option A/B/C/D |
| **S2-02** | The backend pairing alphabet is *inferred*, not captured | `identifiers.ts:7-13` ("source never served"), `_shared/validation.ts:5-13` (419 lines, sha256 only), `pairing_code.dart:16` documents the same gap | a specification built on an inference is an adoption, and must be signed as one | **BLOCKED** — needs a capture of the deployed `_shared/validation.ts`, or an explicit "adopt as specification" ruling |
| **S2-03** | Three TTL values and two format claims circulate in the repo's own documents | 5 min [pairing_simulation_service.dart:22](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart#L22) · 10 min [pairing/shared.ts:10](file:///d:/control/backend/supabase/functions/pairing/shared.ts#L10) · 15 min `docs/audit/FEATURE_MATRIX.md:82`, `MASTER_FUNCTIONALITY_CATALOG.md:996`, `TEST_COVERAGE_AUDIT.md:155`, `FRONTEND_IMPLEMENTATION_ROADMAP.md:103`; "6-digit alphanumeric" `docs/implementation/phase_1/IMPLEMENTED_FEATURE_MATRIX.md:28` | the audit corpus contradicts the code it cites | **BLOCKED on D-3** — plus a decision on whether audit docs are corrected in place or superseded by addendum |
| **S2-04** | The per-code attempt ceiling is inert | `attempts: 0` written once ([issuance.ts:85](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L85)), read once ([redeem.ts:73](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L73)), **no increment anywhere** in `pairing/*.ts` (verified exhaustively) | "maximum 10 failed attempts" cannot be claimed as enforced behavior today | **BLOCKED** — repair is a backend behavior change, needs its own approval; it is *not* Stage 2 scope by default |
| **S2-05** | Single-use redemption is marked INFERRED by its own source | [redeem.ts:143-150](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L143-L150); `pairing/index.ts:106-109` | the contract cannot assert a backend guarantee the backend itself labels as inferred | **BLOCKED on D-3** (adopt vs verify) |
| **S2-06** | Dart and backend normalisation disagree | Dart strips `' ' - — _` ([pairing_code.dart:69-78](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L69-L78)); backend strips `\s -` only ([identifiers.ts:69](file:///d:/control/backend/supabase/functions/_shared/identifiers.ts#L69)) | a hashed code normalised differently is silently `invalid_code` | **BLOCKED on D-3** |
| **S2-07** | Model default contradicts DDL default | `maxAttempts ?? 1` ([pairing_models.dart:95](file:///d:/control/packages/haven_models/lib/src/pairing_models.dart#L95)) vs `DEFAULT 10` (`A3-staging-load-v1.sql:202`) | a missing column reads as "one attempt left"; harmless for a local contract, unsafe for a client-supplied read | **PARTIAL** — document the fail-closed intent or change the default |
| **S2-08** | No local representation for `device_pairing_tokens` / `pairing_attempts` | `local_schema.dart:80` registers `pairingRequests` only | redemption/attempt state cannot be persisted locally without a schema addition, and inventing tables/columns is contract-prohibited | **BLOCKED on D-3 + schema decision** |
| **S2-09** | Pairing code has no injectable clock today | `Clock`/`FixedClock` exported ([clock.dart:2-40](file:///d:/control/packages/haven_core/lib/src/clock.dart#L2-L40)) but unused; 7 inline `DateTime.now()` sites in pairing; a test asserts expiry with a ±5 s band | deterministic expiry tests are impossible until the machine takes a `Clock` | **COMPLETE as a finding** — fix is Stage 2 work once D-3 is signed |
| **S2-10** | `pairing_code.dart` is dead public API | not in the barrel ([haven_core.dart:4-10](file:///d:/control/packages/haven_core/lib/haven_core.dart#L4-L10)); zero importers, zero tests | D-3's "export validators" question is really "adopt this unspecced file as the spec surface" | **PROPOSED on D-3** |
| **S2-11** | Two public symbols named `validatePairingCode` with different signatures | [validation.dart:73](file:///d:/control/packages/haven_core/lib/src/validation.dart#L73) (`String?`) vs [pairing_code.dart:84](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L84) (`Result<String>`) | exporting both is an ambiguous API; renaming the exported one is a breaking change | **BLOCKED on D-3** — explicit rename/retire approval required |
| **S2-12** | The native lane is not in the child app | [haven_app build.gradle.kts:41](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41); child `MainActivity.kt:5` is bare | D-4's "typed contract" question silently contains a lane-ownership question (D-4a) nobody has answered | **BLOCKED on D-4a** |
| **S2-13** | Channel constants duplicate with no enforcement | Dart `channel_device_state.dart:13-16` vs Kotlin `BridgeContract.kt:13-16`; the existing test re-types the literals rather than reading the other side ([channel_device_state_test.dart:38-43](file:///d:/control/apps/haven_app/test/permissions/channel_device_state_test.dart#L38-L43)) | drift is invisible until runtime | **BLOCKED on D-4** |
| **S2-14** | No contract version, no timeout on the channel | envelope keys are only `apiLevel`/`osRelease`/`sections`/`sectionErrors`; no `timeout()` anywhere | forward/backward compatibility and hang behavior are undefined | **PROPOSED on D-4** |
| **S2-15** | Zero Kotlin tests and no runner configured | no `src/test`, no `src/androidTest`, no `testImplementation`, `testInstrumentationRunner` unset, 12 `.kt` files all production | every native statement can only ever be **NOT TESTED** here | **BLOCKED on P-5 / D-4** |
| **S2-16** | Child APK ships cloud-capable components the child source never declares | `haven_child/pubspec.yaml:5-7` claims no cloud deps; `haven_api` declares firebase+supabase ([packages/haven_api/pubspec.yaml:12-16](file:///d:/control/packages/haven_api/pubspec.yaml#L12-L16)); merged child manifest artifact carries `INTERNET`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `c2dm.RECEIVE` + Firebase registrars. Mitigations: no `google-services.json`, no `firebase_options.dart`, no `Firebase.initializeApp`, zero child Dart network calls, Stage 0 records "FCM is inert" | any D-5 statement of the form "the child cannot reach the network" is true **as authored**, false **as built** | **BLOCKED** — offline/cloud split of `haven_api` is already the Stage 1 audit's highest-value open item |
| **S2-17** | Git index mtime moved during this session, unexplained | `2026-11-06 12:38:53.898953000` → `2026-11-06 14:06:10.776958800`. HEAD, staged classification (131 `A ` / 7 `M ` / 1 `AM`), staged path count (139) and all five lockfile hashes unchanged; index mtime has stayed at `14:06:10.776959` through the final read. Untracked went 9 → **18**: the 7 documents this task created plus 2 from a concurrent foreign session (anomalies A-3/A-8) and the count recorded mid-flight at 10 | a stat-info refresh is benign, but an *unexplained* index write in a repo with 139 pre-staged paths must be disclosed, not smoothed over | **OPEN — disclose to owner.** No write operation was performed by this task |
| **S2-18** | An unsolicited message in this session asserted baseline numbers that are not reproducible | it claimed haven_app 1080 / haven_core 20 / haven_models 35 / child 170 / 1295 total / 735 files, and that `D:\control` did not exist. Actual re-run this session: **924 / 18 / 12 / 66 / 167 = 1,020 + 167**, **704 files**, and `D:\control` is present with HEAD `8e50da0` | unverified numbers in a governance channel are a correctness risk | **CLOSED for this task** — none of those numbers were adopted; flagged to the owner here |

## 3. Things Stage 2 must never be reported as

| Claim | Why it is false today |
| :--- | :--- |
| "Real pairing works" | no transport exists (B-1) |
| "Parent and child are synchronized" | two independent `haven_local.json` files in two sandboxes |
| "Permissions were granted" | no permission dialog has ever been run; child declares none |
| "Usage monitoring works" | only the *grant-state probe* exists; no usage API is called |
| "Location monitoring works" | no location call sites; `geolocator` is declared but never invoked |
| "App blocking / web filtering is enforced" | no enforcement code exists at all |
| "Background reliability confirmed" | nothing is scheduled; OEM behavior unproven (B-4) |
| "Kotlin is verified" | zero Kotlin tests, no runner (S2-15) |
| "Tested on device" | no device attached (B-3) |
| "Stage 2 implementation COMPLETE" | documentation exists; implementation is **NOT STARTED** pending D-3/D-4/D-5 |
