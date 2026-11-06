# HAVEN PARENTAL CONTROL — PHASE 3 STAGE 2 NATIVE CHANNEL CONTRACT

**Scope**: Stage 2 module C — typed communication-channel contract between Flutter and Android native
**Date**: November 6, 2026
**Status**: **DRAFT — NOT APPROVED.** This contract becomes binding only when **D-4** (and the sub-decision **D-4a**, lane ownership) is signed in [STAGE_2_DECISION_PROPOSAL.md](file:///d:/control/docs/implementation/phase_3/STAGE_2_DECISION_PROPOSAL.md#L240). Implementation: **NOT STARTED**. Adding a MethodChannel, EventChannel or dependency is prohibited before that approval.
**Ladder ceiling**: level 3 exists **only** as a read-only diagnostic probe inside the parent build; the child app sits at level 2 with **no native lane at all**.

---

## 1. Premise correction — who owns the lane today

| Assumption in the Stage 2 brief | Repository reality |
| :--- | :--- |
| `HavenBridge.kt` is the child app's bridge | It lives in `android_native/child_services/` and is compiled into **`apps/haven_app`** ([build.gradle.kts:41](file:///d:/control/apps/haven_app/android/app/build.gradle.kts#L41) `java.srcDir("../../../../android_native/child_services")`), attached at [haven_app/.../MainActivity.kt:17](file:///d:/control/apps/haven_app/android/app/src/main/kotlin/com/haven/haven_app/MainActivity.kt#L17) |
| The child app has a native channel | The child's only Kotlin file is `class MainActivity : FlutterActivity()` ([MainActivity.kt:5](file:///d:/control/apps/haven_child/android/app/src/main/kotlin/com/haven/child/MainActivity.kt#L5)); `MethodChannel` appears **zero** times in `apps/haven_child/lib` or `test` |
| `channel_device_state.dart` is child-side | It is at [apps/haven_app/lib/core/permissions/channel_device_state.dart](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart) |

Consequence: **D-4a is unavoidable.** Any statement about "the child app's native capability surface" is currently a statement about the parent app. The two choices are (a) leave the lane in the parent and keep the child honest at level 2, or (b) create a child-owned lane — a new source directory, a new Gradle wiring, a new manifest, and a new module. Recommendation for Stage 2: **(a)**, because Stage 2's deliverable is contracts, not capabilities.

## 2. Current contract, as built (the baseline this document must not silently change)

| Element | Dart | Kotlin |
| :--- | :--- | :--- |
| Channel name | `'haven.dev/child_device_state'` ([channel_device_state.dart:13-16](file:///d:/control/apps/haven_app/lib/core/permissions/channel_device_state.dart#L13-L16)) | `"haven.dev/child_device_state"` ([BridgeContract.kt:13](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L13)) |
| Method | `'state.readAll'` | [BridgeContract.kt:16](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L16) |
| Arguments | none | none |
| Response | raw `Map` cast by hand ([device_state_decoding.dart:18-21](file:///d:/control/apps/haven_app/lib/core/permissions/device_state_decoding.dart#L18-L21)) | `Map<String, Any?>` ([HavenBridge.kt:58](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L58)) |
| Envelope keys | `apiLevel`, `osRelease`, `sections`, `sectionErrors` | [BridgeContract.kt:18-21](file:///d:/control/android_native/child_services/platform_bridge/BridgeContract.kt#L18-L21) |
| Sections | five | `permissions`, `monitoring`, `location`, `deviceAdmin`, `communication` ([DeviceStateReader.kt:31-37](file:///d:/control/android_native/child_services/platform_bridge/DeviceStateReader.kt#L31-L37)) |
| Error codes | caught as `MissingPluginException` `:36` / `PlatformException` `:45` | `unknown-method` `:24`, `no-context` `:27`, `section-failed` `:34` |
| Contract version | **absent** | **absent** |
| Timeout | **absent** | **absent** |
| Threading | awaits on the platform thread | synchronous inside `respond` |
| Write methods | none — read-only by design | none ([HavenBridge.kt:28](file:///d:/control/android_native/child_services/platform_bridge/HavenBridge.kt#L28)) |
| Tests | 7, but the constants test **re-types the literals** ([channel_device_state_test.dart:38-43](file:///d:/control/apps/haven_app/test/permissions/channel_device_state_test.dart#L38-L43)) | **0** — no `src/test`, no `src/androidTest`, no `testImplementation` |
| Other mechanisms | no `EventChannel`, no `BasicMessageChannel`, no Pigeon, no `dart:ffi` — verified repo-wide | |

## 3. PROPOSED typed contract

### 3.1 Types

| Side | Type | Purpose |
| :--- | :--- | :--- |
| Kotlin | `data class StateEnvelope(contractVersion, apiLevel, osRelease, sections: Map<String, Any?>, sectionErrors: Map<String,String>)` | replaces the anonymous `linkedMapOf` construction |
| Kotlin | one typed output class per section, owned by its reader | keeps the reader honest about what it can answer |
| Dart | `DeviceStateReport` (exists) | unchanged |
| Dart | `AreaReading<T>` = `AnsweredArea` \| `RefusedArea(reason)` (exists) | unchanged — this is already the right honest-unknown shape |
| Dart | `enum NativeErrorCode { unknownMethod, noContext, sectionFailed, contractVersionUnsupported, timeout, noLane }` | today these exist only as strings on one side |

### 3.2 Version compatibility (`⚠ D-4`)

- Add `contractVersion: Int` to the envelope. The current `apiLevel` is an **OS** number and must not be mistaken for a schema number.
- Rule: reader version `<` app version ⇒ accept, ignore unknown keys. Reader version `>` app version ⇒ **fail closed** to `RefusedArea('contract-version-unsupported')`, never partially decode.
- Rule: `contractVersion` absent ⇒ treated as version `1`, so the existing parent build keeps working when a newer app talks to it. Absent must never mean zero.

### 3.3 Nullability

- **`null` means "the OS could not answer."** Never `false`, never `0`, never `""`. This discipline already exists ([OsAnswers.kt:12](file:///d:/control/android_native/child_services/platform_bridge/OsAnswers.kt#L12), decoder returns `null` on shape mismatch) and the typed contract must preserve it as a *rule*, not an accident.
- A missing section key and a section reported as failed are different facts; both must survive into the Dart model.

### 3.4 Permission-denied vs unsupported vs unknown vs undeclared

| Case | Wire | Dart | UI sentence |
| :--- | :--- | :--- | :--- |
| granted | `true` | `AnsweredArea(true)` | "Allowed" |
| denied | `false` | `AnsweredArea(false)` | "Not allowed" |
| undeclared in manifest | `"notDeclared"` | `RefusedArea('notDeclared')` | "This build never asks for it" |
| declared, never asked | `"no-answer"` | `RefusedArea('no-answer')` ([device_state_decoding.dart:131](file:///d:/control/apps/haven_app/lib/core/permissions/device_state_decoding.dart#L131)) | "Unknown — we have not been told" |
| capability unsupported by OS | `"unsupported"` | `RefusedArea('unsupported')` | "This Android version cannot answer it" |
| reader threw | `sectionErrors[section] = 'section-failed'` | `RefusedArea('section-failed')` | "The device could not answer" |
| no lane at all (child app today) | `MissingPluginException` | `Err(UnknownFailure)` | **"Unavailable — not yet implemented on this device build"** (already the child's copy) |

`⚠ D-4`: the last three rows are the ones a typed contract must not merge. Collapsing "not asked" into "denied" is the defect that turns a truthful dashboard into a false one.

### 3.5 Timeout behavior (`⚠ D-4`)

Today there is none. Proposal: an injected `Duration readTimeout` on the Dart reader (default a named constant, not an inline literal); on expiry return `RefusedArea('timeout')` and **never** a partial report presented as complete. A timeout is not an error dialog — it is an honest "we do not know yet".

### 3.6 Serialization rules

1. Primitives, `List`, `Map` only — no custom objects, no `Serializable`.
2. Keys: the existing camelCase (`apiLevel`, `osRelease`, `sections`, `sectionErrors`) becomes frozen by test; a new convention must not be introduced mid-stage.
3. Section names are wire labels owned by `Sections` (Kotlin) and mirrored in Dart.
4. Booleans are never used to encode absence; `JSONObject.NULL`/`null` carries absence.
5. Nothing secret may ever cross the lane: no token, no code, no raw SDK payload ([failures.dart:3-4](file:///d:/control/packages/haven_core/lib/src/failures.dart#L3-L4)).
6. The envelope is read-only. **A write method is a separate security decision and is not part of D-4.**

### 3.7 Error codes — one enumeration, both sides

| Code | Kotlin origin | Dart mapping | Retryable |
| :--- | :--- | :--- | :--- |
| `unknown-method` | `BridgeContract.kt:24` | `ValidationFailure` (programming error) | no |
| `no-context` | `:27` | `UnknownFailure` | no |
| `section-failed` | `:34` | `DevicePermissionFailure`/`RefusedArea` | yes |
| `contract-version-unsupported` | new | `BlockedFailure` | no |
| `timeout` | new (Dart-side only) | `NetworkFailure`-shaped retryable refusal | yes |
| `no-lane` | `MissingPluginException` | `BlockedFailure` | no |

## 4. Drift control — the core of the D-4 recommendation

The existing test proves nothing about Kotlin because it re-states the literals. Proposal, no new dependency:

1. `BridgeContract.kt` is declared the **single source of truth**.
2. A Dart test reads that file from disk (`File('android_native/child_services/platform_bridge/BridgeContract.kt')`), parses every `const val ... = "..."`, and asserts equality with the Dart constants — so a rename on one side fails the suite on the other.
3. The same test asserts the section-name set (`Sections` in `DeviceStateReader.kt:31-37`) equals the Dart section list, and that the envelope key list matches.
4. A second test asserts the **shape**: an envelope missing `apiLevel` is a `BackendFailure`, not a silent default.
5. Optional, only if the owner approves Kotlin test deps (P-5): a JVM/Robolectric mirror of the same table. Until then this row is reported **NOT TESTED** every time it appears.

## 5. What this contract explicitly does not add

- No `EventChannel`. Polling-on-demand stays the model until a capability actually needs push.
- No Pigeon, no codegen dependency (`⚠ D-4`, recommendation is Option B).
- No new Android permission, provider, service, receiver, `<queries>` entry or `applicationId` change.
- No write/enforcement method of any kind.
- No child-app native module (that is D-4a, and the recommendation is "not in Stage 2").

## 6. Status

| Item | Status |
| :--- | :--- |
| This contract document | **PROPOSED / DRAFT** |
| Drift test design | **PROPOSED** |
| Channel typing implementation | **NOT STARTED — BLOCKED on D-4** |
| Child-owned lane | **NOT STARTED — BLOCKED on D-4a** |
| Kotlin-side verification | **NOT TESTED** (no runner, no test source set, no dependencies) |
| Emulator or device verification of any lane | **NOT TESTED** (AVD present, never launched in this stage; no physical device) |
