# HAVEN PARENTAL CONTROL — CHILD LOCAL STORAGE CONTRACT

**Scope**: Phase 3 Stage 1 — what the child companion persists, where, under which keys, and how each failure is named
**Date**: November 6, 2026
**Status**: COMPLETE at ladder level 2 (Flutter logic + tests) — local-only by design; **no cloud, no sync, no device-verified run**
**Decision that had to be documented at the facade**: yes — it is documented in code at [`child_database.dart`](file:///d:/control/apps/haven_child/lib/core/storage/child_database.dart#L8-L24) and in §2–§3 below.

---

## 1. Reuse Decision (required by the Phase 3 brief)

The child app **does not invent a competing persistence abstraction**. It reuses the `haven_api` offline engine exactly as the parent app does:

| Engine piece | File | What the child lane gets from it |
| :--- | :--- | :--- |
| `FileLocalStore` | [`packages/haven_api/lib/src/offline/local_store.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_store.dart) | one JSON document named `haven_local.json`, atomic tmp+rename writes, typed corrupt-file failure, never a silent reset |
| `LocalTables` | [`local_tables.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_tables.dart) | registry-guarded `first`/`insert`/`update`, plus `reload()` used by the additive-key writer |
| `LocalSchema` / `LocalConstraints` | [`local_schema.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_schema.dart), [`local_constraints.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_constraints.dart) | 19-table `TableName` registry; unique/composite/foreign-key rules evaluated before the write |
| `LocalIds` | [`local_ids.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_ids.dart) | `Random.secure()` 12-byte hex row ids |
| `local_document.dart` | [`local_document.dart`](file:///d:/control/packages/haven_api/lib/src/offline/local_document.dart) | `localSchemaVersion = 1`, `emptyLocalDatabase()`, `localCorruptDetail = 'local_database_corrupt'`, `isCorruptLocalDatabase()` |

Nothing in `packages/` was modified for Stage 1 (`git status`: zero changes under `packages/` and `apps/haven_app/`).

**Same file name ≠ shared state.** Each app runs in its own Android sandbox with its own application-scoped documents directory, and the ids differ (`com.haven.child` vs `com.haven.haven_app`), so the two `haven_local.json` files are separate files that happen to share a name. There is **no** same-device parent↔child exchange mechanism — that is decision **D-5 / BLOCKED B-1**, not an oversight in this contract.

## 2. Document Shape

```json
{
  "schemaVersion": 1,
  "tables": {
    "profiles": [
      {
        "id": "24-hex-local-id",
        "role": "child",
        "display_name": "Sam",
        "age_bracket": "8-11",
        "avatar": "rocket",
        "created_at": "ISO-8601",
        "updated_at": "ISO-8601"
      }
    ]
  },
  "childLocalState": {
    "session":    { "profile_id": "…", "created_at": "ISO-8601" },
    "onboarding": { "step_index": 1, "display_name": "…", "age_bracket": "…", "avatar": "…" }
  }
}
```

- `tables.profiles` holds **at most one row** — the child's own profile, always `role: 'child'` (`ProfileRole.child.wire`), written by [`LocalChildProfileRepository`](file:///d:/control/apps/haven_child/lib/core/storage/local_child_profile_repository.dart). No other registry table is written by this lane in Stage 1.
- Empty-string `ageBracket`/`avatar` are stored as **absent keys**, not as `""`.
- `childLocalState` is the **additive top-level key** (§3).
- Path: this app's own `getApplicationDocumentsDirectory()` via [`ChildStoragePaths`](file:///d:/control/apps/haven_child/lib/core/storage/child_storage_paths.dart), which has a documented test override and converts a missing plugin or a refused folder into a typed `StorageFailure` (`storage_path_unresolved: …`) instead of throwing.

## 3. The `childLocalState` Additive Key (decision)

The `TableName` registry is the 19 captured **cloud** tables and none of them is a key-value/preferences table, so an onboarding draft and a local device session cannot honestly live in `tables`. The brief's fallback is applied instead: **one additive top-level key**, written and read through the existing `{schemaVersion, tables}` conventions — `emptyLocalDatabase`/`parseLocalDatabase` pass unknown top-level keys through untouched, and `LocalTables` only replaces the `tables` map ([`child_local_state.dart`](file:///d:/control/apps/haven_child/lib/core/storage/child_local_state.dart#L8-L21)).

| Section | Key | Content | Sensitivity |
| :--- | :--- | :--- | :--- |
| local session | `childLocalState.session` | `profile_id` + `created_at` | non-sensitive: a memory that setup finished, **not** a credential |
| onboarding draft | `childLocalState.onboarding` | `step_index` + first name + age bracket + avatar name | non-sensitive; contract rule 4 still applies — no tokens, no secrets, ever |

Two writers share one file, so [`writeSection`](file:///d:/control/apps/haven_child/lib/core/storage/child_local_state.dart#L48-L72) always re-reads from disk, mutates only its own section, saves, and then calls `_tables.reload()`. A `null` section value removes that section; when the last section goes, the `childLocalState` key itself is removed rather than left as an empty map. Coexistence is tested directly (write a section → table rows survive, and vice versa; developer reset removes everything).

## 4. Identity: Why `LocalUserAuth` Was Left Alone

`haven_api`'s `LocalUserAuth` hard-codes `role: 'parent'` ([`local_user_auth.dart:94`](file:///d:/control/packages/haven_api/lib/src/offline/local_user_auth.dart#L94)). Editing it would mean changing a parent-app contract during a child-stage, which the brief forbids. Stage 1 therefore **does not use it at all** and introduces a deliberately smaller abstraction — [`ChildLocalSession`](file:///d:/control/apps/haven_child/lib/core/session/child_local_session.dart) — whose doc comment states what it is *not*: no verified account, no credential, no token, no server check, no family row. The UI text "Parent connection: Not connected" is single-sourced from that class.

## 5. Integrity Rules (enforced, and each one tested)

| Rule | Mechanism | Failure returned |
| :--- | :--- | :--- |
| Create-once | explicit read-before-create in `LocalChildProfileRepository.create` | `ValidationFailure(field: 'display_name', detail: 'child_profile_create_once')` — "A child profile already exists on this device, so nothing was created." |
| Primary-key collision | `LocalTableRule()` default `uniqueColumn: 'id'` evaluated by `LocalConstraints` before the write | `BackendFailure(detail: 'local_unique_violation: profiles.id')` |
| Role guard (read **and** update) | a stored `profiles` row whose role is not `child` is refused rather than displayed | `BackendFailure(detail: 'child_profile_role_mismatch')` — nothing is changed |
| Name validation | `haven_core` `validateDisplayName` at the repository boundary (not in widgets) | `ValidationFailure(field: 'display_name')` |
| Update targeting | `update` requires the id of the stored child profile | `ValidationFailure(field: 'id', detail: 'child_profile_missing')` |
| No-write patch | a null-only patch returns the current profile without touching the store | — |
| Damaged document | store refuses to parse; `ChildDatabase.open` propagates, never repairs | `StorageFailure(detail: 'local_database_corrupt…')` |
| Newer schema | a document with `schemaVersion` above 1 is refused, never downgraded | same corrupt `StorageFailure` family |
| Missing file | first launch | `Ok(null)` — "no profile yet", **not** an error |
| Malformed session/draft section | decoded to `null` | child is sent back through onboarding; the profile row itself stays safe because of create-once |

**Honest limit on create-once**: the engine's unique rule keys on `profiles.id`, and `LocalIds.create()` mints a fresh random id per call. So the *engine* prevents overwriting/colliding with an existing row; the *"at most one child profile"* product rule is enforced by the repository's explicit read-before-create (plus the onboarding in-flight guard), not by a database constraint. Within one isolate this is a read-check-write on a single-threaded event loop; a Stage-2+ multi-writer lane would need a real single-row guard (e.g. a fixed id or a composite rule) rather than relying on the id uniqueness alone. Recorded in [STAGE_1_KNOWN_LIMITATIONS.md](file:///d:/control/docs/implementation/phase_3/STAGE_1_KNOWN_LIMITATIONS.md) §5.

## 6. Corruption and the Developer Exit

A corrupt document is **loud, typed and untouched**: the splash renders "The app could not start" + the message + "Try again", and *only* when `isCorruptLocalDatabase(failure)` is true does it add the reset copy and the "Reset local data (developer)" button ([`splash_page.dart`](file:///d:/control/apps/haven_child/lib/features/splash/views/pages/splash_page.dart#L92-L117), [`splash_controller.dart`](file:///d:/control/apps/haven_child/lib/features/splash/controllers/splash_controller.dart#L84-L104)). Nothing auto-clears — silently losing a family's data is the exact failure mode the engine exists to prevent.

[`ChildDataResetter.clearAll`](file:///d:/control/apps/haven_child/lib/core/storage/child_data_resetter.dart) is the only wipe path. `verifyReadableFirst: true` is the plain data-wipe path and **refuses** when the current document cannot be read; the corrupt-database exit passes `false` deliberately, because the unreadable bytes are exactly what the confirmed action agreed to replace. The fresh document is written through the same atomic tmp+rename save, so a reset cannot leave a half-written file.

## 7. What Is Never Stored Here

No password, no token, no device secret, no pairing code, no location, no usage statistics, no analytics payload, no stack traces. Stage 1 has no code path that could produce most of those; the rule is stated so later stages cannot drift. There is no `haven_local.json` anywhere in the repository working tree (`find` verified) and none is tracked.

## 8. Test Mapping

[`test/core/storage/`](file:///d:/control/apps/haven_child/test/core/storage) — `child_profile_repository_test.dart` (11: CRUD, create-once, role guard on read and update, validation at the boundary, absent-not-empty fields, patch + `updated_at` + re-read), `storage_roundtrip_test.dart` (9: draft/session map round-trips, num→int decode, malformed section), `malformed_recovery_test.dart` (10: unparseable file, valid-JSON-wrong-shape, newer schema, missing file is first launch, section reads pass the typed failure through, readable-first wipe refuses a corrupt document, exit hatch then opens empty, path seam redirects and typed path failures), `storage_coexistence_test.dart` (3: one file, two writers, no clobbering). All run against the real `FileLocalStore` in a temp directory (no filesystem mock), via `ChildStoragePaths.overrideForTests`.
