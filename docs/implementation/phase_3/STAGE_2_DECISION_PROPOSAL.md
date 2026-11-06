# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 DECISION PROPOSAL

**Scope**: Stage 2 (Registration contracts + Android capability inventory) — decision gates **D-3**, **D-4**, **D-5**
**Date**: November 6, 2026
**Status**: **PROPOSED — NOT APPROVED.** Nothing in this document is an approved production contract.
**Authority**: None. This document requests decisions; it does not make them.
**Governing contract**: [`docs/implementation/00-app-contract.md`](file:///d:/control/docs/implementation/00-app-contract.md)
**Prerequisite IDs answered**: P-2 (D-3), P-4 (D-5), P-6 (D-4) — [`STAGE_0_INSPECTION_VERIFICATION.md`](file:///d:/control/docs/implementation/phase_3/STAGE_0_INSPECTION_VERIFICATION.md#L62-L73)
**Repository state at authoring time**: branch `main`, HEAD `8e50da06982c495a20407a505235f230de1720f2`, `.git/index` mtime `2026-11-06 12:38:53.898953000 +0530`, 131 `A ` + 7 `M ` + 1 `AM` + 9 `??` entries. **No file outside `docs/implementation/phase_3/` was written by this task; no git operation other than read-only inspection was performed.**

---

## 0. How to read this document

Every section has the same shape: **what the repository actually does today** (with `file:line` evidence), **the options**, **the recommendation**, **what each option costs**, and **the approval field**.

Three things are deliberately true and must not be edited away:

1. **The recommendations below differ from the ones carried in the Stage 2 brief.** The brief proposes a *6-digit numeric* pairing code with a *10-minute* expiry. Section 2 shows that the deployed backend validator rejects that shape outright, so adopting the brief verbatim would produce a local contract that can never redeem against the backend. This document proposes a shape-preserving alternative instead of silently implementing an unworkable one.
2. **Several numbers are marked `INFERRED` by the source code itself.** The pairing alphabet, the normalisation rule and the single-use write all carry `INFERRED` / "source never served" annotations in the backend files. A decision built on an inference is a decision to *adopt* a specification, not to *discover* one.
3. **No decision-dependent code was written.** Per brief §5, everything below is read-only inspection plus non-binding documentation.

### 0.1 What is NOT authorized by this document

| Prohibited until the matching approval is signed | Gate |
| :--- | :--- |
| Change pairing TTL, code length, alphabet or attempt limits | D-3 |
| Export `validatePairingCode` / `PairingCodeFormat` from `haven_core` | D-3 |
| Change the parent 6-digit simulation behavior or labels | D-3 |
| Implement redemption, expiry, duplicate or attempt-limit behavior | D-3, D-5 |
| Adopt Pigeon, or add/relocate any MethodChannel or EventChannel | D-4 |
| Add any native lane to `apps/haven_child` | D-4 |
| Add Android permissions, providers, services, or receivers | D-4, D-5 |
| Implement usage monitoring, location monitoring, background services, enforcement | deferred stages |
| Any same-device parent↔child data exchange | D-5 |
| Add Kotlin test dependencies (JUnit/Robolectric) | D-4 (P-5) |
| Any git add / commit / push / reset / checkout / restore / stash | standing rule |

---

## 1. Evidence base

Method: 4 parallel read-only inspection subagents plus first-party verification of every number this document asserts as decisive. All file:line citations were re-read directly. Companion documents: `STAGE_2_INSPECTION_REPORT.md` (same directory), `ANDROID_CAPABILITY_INVENTORY.md`, `PAIRING_REGISTRATION_CONTRACT.md`, `NATIVE_CHANNEL_CONTRACT.md`, `STAGE_2_TEST_STRATEGY.md`, `STAGE_2_BLOCKER_REGISTER.md`.

---

## 2. D-3 — Pairing-code specification

### 2.1 What exists today: four contracts, not two

| # | Contract | Length | Alphabet | Entropy | TTL | Where |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| C1 | Parent offline **simulation** | 6 | `\d` (`^\d{6}$`) | 10⁶ ≈ 19.9 bits | **5 min** | [pairing_simulation_service.dart:22-24](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart#L22-L24), [:43](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart#L43) |
| C2 | Backend **issued code** | 8 | 30 symbols `23456789ABCDEFGHJKMNPQRSTVWXYZ` | 30⁸ ≈ 39.5 bits | **10 min** | [identifiers.ts:24-25](file:///d:/control/backend/supabase/functions/_shared/identifiers.ts#L24-L25), [pairing/shared.ts:10](file:///d:/control/backend/supabase/functions/pairing/shared.ts#L10) |
| C3 | **Unspecced** typed validator | caller-supplied | caller-supplied | n/a | n/a | [pairing_code.dart:41-59](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L41-L59) — **not barrel-exported** |
| C4 | Exported lenient UI validator | 4–64 chars | any | n/a | n/a | [validation.dart:73-79](file:///d:/control/packages/haven_core/lib/src/validation.dart#L73-L79) |

Two further claims exist in older documents and contradict all four: `docs/implementation/phase_1/IMPLEMENTED_FEATURE_MATRIX.md:28` records the simulation as "Random 6-digit **alphanumeric**" (C1 is numeric), and four audit documents ([`docs/audit/FEATURE_MATRIX.md:82`](file:///d:/control/docs/audit/FEATURE_MATRIX.md#L82), `MASTER_FUNCTIONALITY_CATALOG.md:996`, `TEST_COVERAGE_AUDIT.md:155`, `FRONTEND_IMPLEMENTATION_ROADMAP.md:103`) state a **15-minute** TTL while citing `issuance.ts:75`, which actually calls `ttl(CODE_TTL_MINUTES)` = 10 at [issuance.ts:78](file:///d:/control/backend/supabase/functions/pairing/issuance.ts#L78).

### 2.2 The blocking reconciliation problem

The brief's recommended proposal — "6-digit numeric code, 10-minute expiry" — **cannot redeem against the backend path**:

```
redeem.ts:48   if (!PAIRING_CODE_RE.test(normalized)) invalidIdentifier();
identifiers.ts:61  PAIRING_CODE_RE = ^[23456789ABCDEFGHJKMNPQRSTVWXYZ]{8}$
```

A 6-digit numeric string fails that regex. The shape and the TTL are not independent knobs: choosing 6 numeric digits *decides* that the code is a demonstration artefact only, and choosing the backend-aligned shape *decides* that the parent simulation UI must change (a change currently on the not-allowed-before-approval list).

Second problem — the backend alphabet is **recovered, not captured**:

```
identifiers.ts:7-13   header: the Edge module source was never read; the 30-symbol class is
                      inferred from the child_contact_ids CHECK constraint
identifiers.ts:60     "the prefix-free form itself is INFERRED"
validation.ts:5-13    deployed module 419 lines / sha256 3b817683…, "source never served"
```

Adopting C2 is therefore an act of specification, and must be recorded as such.

Third problem — **the attempt limit the brief proposes to adopt is inert in the code**:

```
issuance.ts:85   attempts: 0,
redeem.ts:73     if (token.status !== "active" || expired || token.attempts >= token.max_attempts) {
```

`attempts` is initialized once and read once; no code path increments it (verified by exhaustive grep of every `attempt` occurrence in `backend/supabase/functions/pairing/*.ts`). `MAX_ATTEMPTS_PER_CODE = 10` ([shared.ts:12](file:///d:/control/backend/supabase/functions/pairing/shared.ts#L12)) therefore gates nothing. What actually limits brute force is the window throttle — `MAX_FAILED_PER_PARENT_PER_WINDOW = 5` and `MAX_FAILED_PER_IDENTIFIER_PER_WINDOW = 10` over `REDEEM_WINDOW_MINUTES = 10` ([rate_limit.ts:43-49](file:///d:/control/backend/supabase/functions/_shared/rate_limit.ts#L43-L49)) — and that throttle sits on top of a deliberately preserved read-then-act weakness ([rate_limit.ts:17-23](file:///d:/control/backend/supabase/functions/_shared/rate_limit.ts#L17-L23), "finding E8 … PRESERVED, NOT FIXED").

Fourth problem — the model and the DDL disagree about the default: `maxAttempts: asInt(row['max_attempts']) ?? 1` ([pairing_models.dart:95](file:///d:/control/packages/haven_models/lib/src/pairing_models.dart#L95)) versus `max_attempts integer NOT NULL DEFAULT 10` (`docs/stage2/migrations/A3-staging-load-v1.sql:202`). The Dart default is fail-closed, which is defensible, but it means a missing column reads as "one attempt left".

Fifth problem — normalisation is not equivalent across the two languages: Dart strips `' '`, `'-'`, `'—'`, `'_'` and upper-cases ([pairing_code.dart:69-78](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L69-L78)); the backend strips `\s` and `-` only ([identifiers.ts:69](file:///d:/control/backend/supabase/functions/_shared/identifiers.ts#L69)). A code typed with an underscore normalises differently on the two sides, which for a hashed code means a silent `invalid_code` rather than an error message.

### 2.3 Options

| Option | Shape | Local contract | Future backend redemption | Simulation change | Entropy | Honest label |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **A** — brief as written | 6 numeric, 10 min | Yes | **No** — rejected by `PAIRING_CODE_RE` | TTL only | 19.9 bits | Demonstration forever |
| **B** — backend-aligned | 8 of 30, 10 min | Yes | Yes, *if* the inferred alphabet is confirmed | Format + UI + tests change | 39.5 bits | Real lane, built on an inference |
| **C** — two named lanes, one authoritative spec (recommended) | `localDemonstration` = 6 numeric; `backendIdentifier` = 8 of 30 | Yes | Yes, gated on capture | **None** | 19.9 / 39.5 | Each lane states its own truth |
| **D** — defer D-3 entirely | keep C1 + C4 | Partial | No | None | mixed | Stage 2 contracts blocked |

### 2.4 D-3 recommendation — **Option C**

Specify both lanes, and refuse to invent a third:

1. **Lane `local`** — `PairingCodeFormat(length: 6, charset: digits)`. Applies to the existing parent simulation and to any Stage 2 local state machine. It is labelled *demonstration* in code and UI. Its TTL becomes a named constant, not an inline `Duration(minutes: 5)`.
2. **Lane `backend`** — `PairingCodeFormat(length: 8, charset: backendIdentifier30)` adopted as the *target* shape, marked `ADOPTED-PENDING-CAPTURE` until the deployed `_shared/validation.ts` source is captured and diffed. A new `PairingCodeCharset` member is required because the existing three ([pairing_code.dart:31-38](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L31-L38)) do not express it.
3. **Expiry** — 10 minutes for both lanes, so the two agree, *or* keep 5 for `local` and document the split. The recommendation is **10 for `backend`, 5 retained for `local` with a comment naming the difference**, because changing the simulation is a behavior change that buys no security and breaks three existing assertions ([local_pairing_simulation_test.dart:47](file:///d:/control/apps/haven_app/test/device_pairing/local_pairing_simulation_test.dart#L47), `:55` tolerance band `295-300` seconds).
4. **Attempts** — adopt `MAX_ATTEMPTS_PER_CODE = 10` as the *specified* per-code ceiling **and** record that it is unenforced today. Repairing it (increment `attempts` inside the redemption transaction) is a backend behavior change and must be scheduled separately, not bundled into Stage 2 contracts.
5. **Single-use** — adopt, but labelled `INFERRED`: the compare-and-set write at [redeem.ts:143-150](file:///d:/control/backend/supabase/functions/pairing/redeem.ts#L143-L150) and `UNIQUE (token_id)` / `UNIQUE (code_hash)` (migration `:425`, `:429`) support it; `pairing/index.ts:106-109` marks the write itself as inferred.
6. **Explicit states** — `expired`, `invalid`, `already-used`, `attempt-limit-reached`, `cancelled`, `revoked`, plus the D-5 state `blocked_pending_transport`.
7. **Deterministic clock** — inject `Clock` from [clock.dart](file:///d:/control/packages/haven_core/lib/src/clock.dart#L2-L40) (`FixedClock` already exists and is exported). Today **no pairing file uses it**; seven sites call `DateTime.now()` inline and one test measures expiry with a 5-second tolerance band, which is exactly the non-determinism the brief asks to remove.
8. **Export decision** — export `validatePairingCode`, `PairingCodeFormat`, `PairingCodeCharset`, `normalizePairingCodeInput` and `pairingCodeRuleGap` from `haven_core` by adding `export 'src/pairing_code.dart';` to the barrel. Consequence to accept: two symbols named `validatePairingCode` would then both be public with different signatures ([validation.dart:73](file:///d:/control/packages/haven_core/lib/src/validation.dart#L73) and [pairing_code.dart:84](file:///d:/control/packages/haven_core/lib/src/pairing_code.dart#L84)), so the recommendation includes **retiring the lenient one** or renaming it (e.g. `validateTypedCodeShape`). This is a shared-package change and needs explicit approval.
9. **Anti-enumeration preserved** — the uniform `invalid_code` body ([pairing/shared.ts:23-28](file:///d:/control/backend/supabase/functions/pairing/shared.ts#L23-L28)) must not be differentiated by the local contract either; a local "code not found" vs "code expired" distinction on a *network-facing* surface would reintroduce the oracle the backend deliberately closed.
10. **Normalisation** — pick one rule. Recommendation: Dart matches the backend (`\s` and `-`, uppercase), and `—`/`_` are rejected as invalid characters rather than silently stripped, so the two sides can never disagree about whether a string is a code.

### 2.5 Security implications

- 6 numeric digits are brute-forceable at 10⁶; with the per-code counter inert and the window throttle sitting on a known race, a 6-digit code is **not** a security boundary. Option C's `local` lane must therefore never be presented as a completed pairing, and must never be given a network transport.
- 8-of-30 ≈ 39.5 bits is adequate for a short-lived (10 min) code only if the attempt ceiling is actually enforced; adopting the shape without enforcing the counter inherits the same weakness at higher cost.
- Codes are stored hashed (`code_hash ~ '^[0-9a-f]{64}$'`, migration `:476`) with an HMAC pepper (`identifierHash`, `PAIRING_HASH_PEPPER`). Any local contract must not log, persist, or echo a plaintext code beyond its displayed lifetime — the governing contract already says this ([00-app-contract.md:108-109](file:///d:/control/docs/implementation/00-app-contract.md#L108-L109)).
- Detail strings must never carry tokens or raw SDK payloads ([failures.dart:3-4](file:///d:/control/packages/haven_core/lib/src/failures.dart#L3-L4)).

### 2.6 Backward compatibility

| Surface | Impact under Option C |
| :--- | :--- |
| Parent simulation (`PairingSimulationPage`, 6-digit UI, tests) | **None** — the `local` lane codifies what already exists |
| Phase 1/2 regression suites (924/66/18/12) | **None** if the lenient validator is kept; **source edits** in `haven_app` device_pairing tests if it is retired |
| Backend Edge Functions | **None** (no deployment in this stage); Option C only names the target shape |
| `haven_core` public API | **Additive** unless the lenient `validatePairingCode` is renamed — that rename is a breaking change for every caller |
| Audit documents claiming 15 min / alphanumeric | Become **superseded**; correction belongs in an addendum, not a silent edit of evidence records |

### 2.7 Required tests (all deterministic, `FixedClock`-driven)

1. Format acceptance/rejection per lane, including separator and case variants, and one negative test per alphabet.
2. **Cross-language normalisation equivalence** — a table of strings asserting Dart and backend produce the same normalised result, and that `—`/`_` behave identically.
3. Exact-boundary expiry: `expiresAt == now`, `now + 1ms`, `now - 1ms`.
4. Attempt limit reached, and the inert-counter case proving a local state machine refuses at N regardless of what the backend currently does.
5. Duplicate redemption → `already_used`, never a second success.
6. Expired code cannot be reused, even if `status` still says `active`.
7. Cancellation and unpair transitions are terminal-or-named, never implicit.
8. No state pair is representable that the machine cannot produce (the current three-boolean model permits `isRedeemed && isCancelled` — [simulation_models.dart:16-24](file:///d:/control/apps/haven_app/lib/features/device_pairing/data/simulation_models.dart#L16-L24)).
9. Anti-enumeration: an unknown code and an expired code produce the same user-visible message on any network-facing surface.
10. Every failure path returns `Result`/`HavenFailure`, never a raw throw or a bare `null` success ([00-app-contract.md:57](file:///d:/control/docs/implementation/00-app-contract.md#L57)).

### 2.8 Required contract changes

| File | Change | Breaking? |
| :--- | :--- | :--- |
| `packages/haven_core/lib/haven_core.dart` | + `export 'src/pairing_code.dart';` | No |
| `packages/haven_core/lib/src/pairing_code.dart` | + `PairingCodeCharset.backendIdentifier30`; + lane constants `localDemonstration` / `backendIdentifier` | No |
| `packages/haven_core/lib/src/validation.dart` | retire or rename the lenient `validatePairingCode` | **Yes** |
| `packages/haven_models/lib/src/pairing_models.dart` | document/decide the `?? 1` default; wire `hasAttemptsLeft` (currently zero call sites) | No |
| `docs/implementation/_work/*` or the pairing doc | record the adopted spec and the `ADOPTED-PENDING-CAPTURE` marker | No |

### 2.9 Risks and unresolved questions

- **Q-D3-1** Is the deployed pairing alphabet the recovered 30-symbol set? Only a capture of `_shared/validation.ts` answers this. Until then every backend-lane claim is inferred.
- **Q-D3-2** Is the 5-minute simulation TTL worth changing? Recommendation: no.
- **Q-D3-3** May the lenient exported validator be renamed/retired (breaking change)?
- **Q-D3-4** Is repairing the inert `attempts` counter in scope now, or a separate backend task?
- **Q-D3-5** Should the 15-minute audit claims be corrected in place or superseded by addendum?

### 2.10 Owner approval field — D-3

```text
D-3 PAIRING-CODE SPECIFICATION                                     Date: ____________
Option adopted (A / B / C / D)  : ______
Explain the choice: ________________________________________________
Name the adopted shape          : length ______ , charset ______
TTL adopted (minutes)           : local ____ , backend ____
Attempt ceiling adopted         : ______   (record: enforced today?  Y / N)
Single-use adopted              : Y / N     (record: source status INFERRED?)
Export pairing validators       : YES / NO
Retire lenient validator        : YES / NO   (breaking change)
Clock injection required in Stage 2 code : YES / NO
Authorize Phase 1/2 test edits  : YES / NO   (list files: ______________)
Authorizes implementation of D-3 only   : YES / NO
Approved by (owner)             : ____________________
```

---

## 3. D-4 — Typed native communication channel

### 3.1 What exists today — including a premise correction

**The brief assumes `HavenBridge.kt` belongs to the child app. It does not.** The native lane lives in `android_native/child_services/` (10 Kotlin files, max 122 lines) and is compiled into the **parent** app:

```
apps/haven_app/android/app/build.gradle.kts:41   java.srcDir("../../../../android_native/child_services")
apps/haven_app/.../MainActivity.kt:17            HavenBridge.forApp { applicationContext }
apps/haven_child/.../MainActivity.kt:5           class MainActivity : FlutterActivity()   // bare, zero native code
```

Confirmed by grep: `apps/haven_child/lib` and `apps/haven_child/test` contain **no** `MethodChannel`, no `haven.dev`, no channel usage of any kind. The Stage 2 decision was already recorded as "no `srcDir` redirect into `android_native` and **no Kotlin native lane added yet**" ([PHASE_3_MASTER_PLAN.md:35](file:///d:/control/docs/implementation/phase_3/PHASE_3_MASTER_PLAN.md#L35)).

The existing lane is a single read-only method with duplicated constants:

| Item | Dart | Kotlin |
| :--- | :--- | :--- |
| Channel | `'haven.dev/child_device_state'` [channel_device_state.dart:14](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart#L14) | `"haven.dev/child_device_state"` [BridgeContract.kt:13](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L13) |
| Method | `'state.readAll'` `:15` | `"state.readAll"` `:16` |
| Payload | raw `Map` → manual casts [device_state_decoding.dart:14-40](file:///d:/control/apps/haven_app/lib/core/permissions/device_state_decoding.dart#L14-L40) | `Map<String, Any?>` [HavenBridge.kt:58](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L58) |
| Errors | `MissingPluginException` `:36`, `PlatformException` `:45` | `unknown-method` `:24`, `no-context` `:27`, `section-failed` `:34` |
| Contract version | **absent** | **absent** |
| Timeout | **absent** | **absent** |
| Tests | 7, asserting **hard-coded string literals** | **zero** — no `src/test`, no `src/androidTest`, no `testImplementation` dependency |

The Dart file itself admits the risk: drift is "a compile-time error on neither side" ([channel_device_state.dart:10-12](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart#L10-L12)). **Pigeon is definitively absent** — no `pigeon` in any pubspec/lockfile/gradle file, no `pigeons/` directory, no generated `*_pigeon.dart`, no `dart:ffi`, no `BasicMessageChannel`, and **no `EventChannel` anywhere in the repository**.

Existing quality to preserve: `null` means "the OS could not answer", never `false` or `0` ([OsAnswers.kt:12](file:///d:/control/android_native/child_services/platform_bridge/OsAnswers.kt#L12)), and the decoder returns `null` on shape mismatch rather than coercing. That is the correct honest-unknown discipline and any typing scheme must keep it.

### 3.2 Options

| Option | Mechanism | New dependency | Child lane today | Constant duplication | Contract test |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A** — Pigeon | generated Dart + Kotlin interfaces | Yes (`pigeon` dev_dep + codegen + gradle wiring) | Requires adding a native source dir to `haven_child` | Eliminated by generation | Provided by generation |
| **B** — hand-written typed contract files + a drift test | one authoritative constants source read by a test | No | Same as A, needs its own decision | Reduced to one source of truth | Explicit |
| **C** — status quo | duplicated literals | No | unchanged | Yes | Weak (test repeats the strings) |

### 3.3 D-4 recommendation — **Option B, with a mandatory sub-decision**

Adopt hand-written typed contracts *plus* a test that makes drift fail, and do not add Pigeon in Stage 2. Concretely:

1. **One authoritative constants source.** Keep `BridgeContract.kt` as the declared source of truth. Add a Dart test that reads the Kotlin file from disk and asserts every `const val` equals its Dart counterpart, so the existing 7-test file stops asserting strings it typed by hand.
2. **A contract version field.** Add `contractVersion: Int` to the envelope (today only `apiLevel` — an OS number, not a schema number). Rule: an app reading a *higher* version than it knows must fail closed to `RefusedArea('contract-version-unsupported')`, never partially decode.
3. **Typed Kotlin output.** Introduce Kotlin data classes mirroring the Dart `DeviceStateReport` / `AreaReading<T>` shapes instead of `linkedMapOf(...)`, and put them behind the same 200-line rule.
4. **Error-code enum on the Dart side.** The three Kotlin codes exist only as strings today; enumerate them in Dart and map each to a `HavenFailure`, keeping the `blocked(...)` vocabulary for unimplemented capabilities.
5. **Explicit timeout policy.** A documented, injected timeout for `invokeMethod` (a `Duration` passed to the reader, not a hard-coded literal), with `RefusedArea('timeout')` as the honest outcome.
6. **Permission-denied vs unsupported vs unknown** remain three distinct states; `null` never means "denied".
7. **Serialization rule.** Primitives and `List`/`Map` only (no custom objects), snake_case keys, `null` for unknown, never `0`/`false` as a stand-in for unknown.
8. **D-4a (sub-decision, must be answered before any code): which app owns the lane?** Stage 2 can either keep the bridge in the parent and have the child display `Unavailable` (status quo, ladder level 2), or move/copy `android_native/child_services` into `apps/haven_child` (a new `srcDir`, new manifest entries, a new Gradle source set). The recommendation for Stage 2 is **keep the lane in the parent, add no native lane to the child**, because Stage 2 is a contracts stage and the brief forbids adding channels or permissions before approval.

**Why not Pigeon now**: it would add a codegen dependency and a gradle/plugin wiring step to a repo that has zero generated contract files today, in a stage whose deliverable is documentation and deterministic Dart contracts. Option B removes the duplicated-constant defect the brief cares about without any new dependency, which is the condition the brief sets for accepting it ("provided both sides can be tested against one explicit contract and duplicated constants are eliminated").

### 3.4 Security implications

- The channel is read-only by design and has no "apply" method; adding a write method is a security decision, not a typing decision, and must be separately approved.
- A `MethodChannel` is in-process and not attacker-reachable from another app, so typing introduces no new external attack surface. The real risk is *truthfulness*: a coerced `false` where the OS said nothing becomes a false "permission denied" or false "not granted" in a parental-control UI.
- Package visibility, `QUERY_ALL_PACKAGES`, usage stats and background services must not be introduced under the cover of "channel typing".

### 3.5 Backward compatibility

- Parent app keeps working unchanged (lane stays in place).
- The Dart decoder is additive if new keys are optional; `contractVersion` becomes required in the *new* contract, so old APKs reading new Dart (or vice versa) must be handled by an explicit "absent version ⇒ version 1" rule rather than a crash.
- Kotlin typed output models change no wire shape as long as the map keys stay identical, which the drift test enforces.

### 3.6 Required tests

1. Constants-equality test that parses `BridgeContract.kt` (the core of Option B).
2. `contractVersion` negotiation: higher-than-known, equal, absent.
3. Every Kotlin error code maps to a `HavenFailure`, none falls through to `UnknownFailure` silently.
4. Timeout path returns `RefusedArea('timeout')`, never a partial report presented as complete.
5. Shape-mismatch decoding returns `null` (never `false`/`0`) for every field type.
6. One failed reader does not blank the other four (already proven — keep it).
7. Kotlin-side: if P-5 is approved, a Robolectric/JUnit matrix for API 24/29/31/33/36 guards; if not approved, this row stays **NOT TESTED** and must be reported as such every time.

### 3.7 Risks and unresolved questions

- **Q-D4-1** Does the owner accept Option B's premise that a test, not a generator, is the drift control?
- **Q-D4-2** D-4a: parent-owned lane (recommended) or child-owned lane (new native module)?
- **Q-D4-3** Are Kotlin test dependencies (JUnit + Robolectric, P-5) approved now, or does Stage 2 proceed with zero Kotlin verification?
- **Q-D4-4** Is `contractVersion` added now (breaking for a future child lane) or deferred to the child-lane stage?

### 3.8 Owner approval field — D-4

```text
D-4 TYPED NATIVE CHANNEL                                           Date: ____________
Option adopted (A / B / C)        : ______
D-4a lane owner                   : PARENT (status quo) / CHILD (new native module)
Add contractVersion now           : YES / NO
Add Kotlin typed output models    : YES / NO
Enumerate error codes in Dart     : YES / NO
Timeout policy value (seconds)    : ______
Approve new dependency (Pigeon)   : YES / NO     (NO under the recommendation)
Approve Kotlin test deps P-5      : YES / NO     (JUnit / Robolectric versions: ______)
Any new channel method or event   : NONE authorized unless written here: ____________
Authorizes implementation of D-4 only : YES / NO
Approved by (owner)               : ____________________
```

---

## 4. D-5 — Parent-child communication mechanism

### 4.1 What exists today

Two separate Android applications in two separate sandboxes:

| Fact | Evidence |
| :--- | :--- |
| Parent `applicationId` `com.haven.haven_app` | [haven_app/android/app/build.gradle.kts:19](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L19) |
| Child `applicationId` `com.haven.child` | [haven_child/android/app/build.gradle.kts:21](file:///d:/control/apps/haven_child/android/app/build.gradle.kts#L21) |
| Both use the same `FileLocalStore` class, each inside its own sandbox, each writing `haven_local.json` | [local_store.dart:28-34](file:///d:/control/packages/haven_api/lib/src/offline/local_store.dart#L28-L34), [child_database.dart:48](file:///d:/control/apps/haven_child/lib/core/storage/child_database.dart#L48), [initial_bindings.dart:60](file:///d:/control/apps/haven_app/lib/app/bindings/initial_bindings.dart#L60) |
| No exchange mechanism exists — recorded as D-5 / B-1, not an oversight | [CHILD_LOCAL_STORAGE_CONTRACT.md:24](file:///d:/control/docs/implementation/phase_3/CHILD_LOCAL_STORAGE_CONTRACT.md#L24) |
| Verified absences | zero `FileProvider`, `content://`, `android:sharedUserId`, `MediaStore`, `BluetoothAdapter`, `NsdManager`, `WifiManager`, exported provider |
| Child UI already truthful | `parentConnectionStatus = 'Not connected'` [child_local_session.dart:23](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart#L23); "Pairing is not built yet" [device_fact_rows.dart:38-40](file:///d:/control/apps/haven_child/lib/core/device/device_fact_rows.dart#L38-L40); `'Not registered'`; parent labels `'SIMULATED DEVICE'` |

**One material counter-evidence item, which must be disclosed rather than resolved by this document.** `apps/haven_child/pubspec.yaml:5-7` states that no cloud dependency may appear in the child, yet the child depends on `haven_api`, which declares `firebase_core`/`firebase_auth`/`firebase_messaging`/`supabase_flutter` ([packages/haven_api/pubspec.yaml:12-16](file:///d:/control/packages/haven_api/pubspec.yaml#L12-L16)). The child APK's merged manifest therefore carries plugin-injected `INTERNET`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `com.google.android.c2dm.permission.RECEIVE` and three Firebase component registrars even though the child's *source* manifest declares nothing. Mitigating facts: no `google-services.json`, no `firebase_options.dart`, no Firebase gradle plugin and no `Firebase.initializeApp` call exist anywhere in the repo, the child Dart makes zero network calls, and Stage 0 records "FCM is inert". Consequence: **the child is network-capable as built, even though it is network-free as written.** Any D-5 option that claims "the child cannot reach the network" must say "as authored", not "as shipped".

### 4.2 Options

| Option | Mechanism | Real connection? | New permissions/surface | Works on API 36 / targetSdk 36 | Play/privacy exposure |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** — label-only local demonstration | existing per-app JSON, explicit `Not connected` | No | none | Yes | none |
| **2a** — shared external file | `MediaStore`/public dir | Pretend-synchronized | storage permissions | Blocked by scoped storage (Android 10+ platform fact) | high: any app can read |
| **2b** — exported `FileProvider` | content URI grant | Pretend-synchronized | provider + grants | Yes | high if mis-permissioned; the brief's prohibited list |
| **2c** — broadcast intents | explicit/implicit broadcast | Spoofable | signature-level perms (needs identical signing key) | Implicit broadcasts restricted (Android 8+ platform fact) | medium-high |
| **2d** — same-device loopback socket | `127.0.0.1` | Yes, same device only | `INTERNET` (already merged) | Loopback is reachable by other apps on some OEM configs; is not authenticated | medium |
| **2e** — BLE / mDNS / Wi-Fi Direct | local discovery | Yes, cross-device | `BLUETOOTH_*`, `ACCESS_*`, location for scanning | Feasible but a full feature in itself | high; already deferred in Phase 1 docs |
| **3** — Phase 4 backend rendezvous | existing `pairing_requests` / `device_pairing_tokens` contracts | Yes | none beyond `INTERNET` | Contracts exist as staging code, not deployed from this repo | documented, auditable |

### 4.3 D-5 recommendation — **Option 1 now, Option 3 as the named target; Option 2 explicitly rejected**

1. **Real cross-device pairing stays BLOCKED** (B-1) until Phase 4 backend or a specifically approved local transport exists. Contracts and their tests proceed independently of that.
2. **UI truthfulness is a test, not a intention.** Add regression tests that assert the child shows `Not connected` and `Not registered`, that the parent shows `SIMULATED DEVICE` for simulated installations, and that **no** string in the child tree renders a connected state while `parentConnectionStatus` is the constant.
3. **Never read or write another application's private sandbox.** Already true; make it a stated rule in the storage contract with a named forbidden zone.
4. **Never present two independent `haven_local.json` files as synchronized.** They are the same class, not the same file; the existing contract line already says "Same file name ≠ shared state".
5. **Prohibited-by-default list**, adopted verbatim from the brief and recorded in the blocker register: file-sharing hacks, exported insecure providers, unrestricted storage access, undocumented broadcast mechanisms.
6. **Add the `blocked_pending_transport` state** to the registration state machine so a local contract can express "correctly specified, deliberately not connected" instead of a fake success.
7. **Disclose the transitive cloud surface** (§4.1) as its own blocker, because "no cloud in the child" is currently only an authoring-level claim. Splitting `haven_api` into offline vs cloud lanes is already the highest-value open item in the Stage 1 audit and should precede any claim about child isolation.
8. **If the owner wants a same-device demonstration path at all**, the least-bad candidate is an explicitly-designed, authenticated loopback transport *named and reviewed as a feature* — not a file trick. This document does not recommend adopting it in Phase 3.

### 4.4 Security implications

- Any shared-storage mechanism between a parent app and a *child-managed* app is a privilege boundary: the child device is the untrusted side in a parental-control threat model, so "the file the child writes" is not evidence the parent may trust. Authentication and integrity, not mere co-location, are what would make Option 2 real.
- A parent that trusts a locally-written "paired" flag can be fooled by the child user; the same reason the backend path uses hashed tokens, RLS and server-side redemption.
- Local demonstration must not be able to produce an audit record that reads like a verified pairing.

### 4.5 Backward compatibility

Option 1 changes nothing: the child app already renders the truthful constants and no code path claims a connection. Phase 1/2 parent behavior is untouched. The state machine addition (`blocked_pending_transport`) is additive to the contract document, and the `PairingRequestStatus` wire enum does not gain a value unless the backend DDL does.

### 4.6 Required tests

1. Child renders `Not connected` / `Not registered` on every screen that could imply a link.
2. Parent labels simulated installations as simulated; a `sim`-prefixed `installationId` never renders as a real device.
3. Two sandboxes: a unit test that the child store path and parent store path are independent objects, and that nothing in the codebase opens a path outside its own app directory.
4. The local state machine reaches `blocked_pending_transport` and **cannot** transition from it to any redeemed/connected state without an approved transport interface being provided — the "no fake parent connection" rule expressed as an executable assertion.
5. Audit records written by local redemption are labelled `local_demonstration` in their payload.

### 4.7 Risks and unresolved questions

- **Q-D5-1** Confirm: real pairing stays BLOCKED in Phase 3 (recommended), or does the owner want a same-device transport scoped and reviewed now?
- **Q-D5-2** Authorize the offline/cloud split of `haven_api` (it gates any isolation claim)?
- **Q-D5-3** May audit records be written for local demonstration, and must they carry the `local_demonstration` label?
- **Q-D5-4** Does the owner accept the disclosure that the child APK ships network-capable components today?

### 4.8 Owner approval field — D-5

```text
D-5 PARENT-CHILD COMMUNICATION                                     Date: ____________
Option adopted (1 / 2a-e / 3 / other) : ______
Real cross-device pairing             : BLOCKED (recommended) / APPROVED-VIA: ______
Same-device transport, if any, named  : ______________________________________
Add blocked_pending_transport state   : YES / NO
Local audit records allowed, labelled : YES / NO   (label: ____________)
Authorize haven_api offline/cloud split: YES / NO
New permissions/providers/services    : NONE authorized unless written here: ________
Authorizes implementation of D-5 only : YES / NO
Approved by (owner)                   : ____________________
```

---

## 5. Cross-cutting consequences for Stage 2 implementation

| If approved | Stage 2 can implement | Stage 2 still cannot |
| :--- | :--- | :--- |
| D-3 only | local pairing/registration state machine, format validators, expiry/attempt/duplicate/cancel semantics, deterministic `FixedClock` tests | redemption against a backend; simulation behavior change unless explicitly approved |
| D-4 only | contract drift test, typed models in the parent lane, error/timeout/version handling | any child native lane, any new channel method, any permission |
| D-5 only | truthfulness regression tests, `blocked_pending_transport`, storage-boundary rules | any exchange mechanism |
| All three | the full §7 contract + tests | real pairing (remains BLOCKED), usage monitoring, location, background services, enforcement — all later stages |

**Status of this stage at the time of writing:** Stage 2 PREPARATION — documents and inspection **COMPLETE / PROPOSED**; Stage 2 IMPLEMENTATION **NOT STARTED**. Real cross-device pairing: **BLOCKED** (B-1). Kotlin native verification: **NOT TESTED** (no test source set, no runner). Physical-device verification: **NOT TESTED** (no device attached; `Pixel_9a` AVD present). Parent-child E2E: **BLOCKED** (ladder level 6 unreachable without D-5 and a transport).

Nothing in this document promotes any module up the six-level ladder, and no claim of real pairing, cross-device synchronization, permission grant, usage monitoring, location monitoring, app enforcement or background reliability is made here.
