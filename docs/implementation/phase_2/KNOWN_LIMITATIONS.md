# HAVEN PARENTAL CONTROL — PHASE 2 KNOWN LIMITATIONS

**Scope**: Phase 2 — Parent App Offline Implementation  
**Date**: November 5, 2026 (updated after final verification, November 6, 2026)  
**Status**: DESIGN LIMITATIONS (PLANNED) — all confirmed non-blocking at final verification  

---

## 1. Local-Only Storage Scope
- All created profiles, schedules, rules, safe zones, and approvals persist to `haven_local.json` via `OfflineHavenBackend`.
- Changes made on this phone are not synchronized to other parent devices until cloud synchronization is deployed.

## 2. Simulated Child Device Pairing & Events
- The 6-digit pairing code workflow creates simulated child devices within the local database.
- Physical pairing with a secondary phone over Bluetooth or network rendezvous is planned for subsequent phases.

## 3. Policy Enforcement Boundary
- Screen-time limits, app rules, domain blocklists, and schedule windows are persisted and validated in `TableName.devicePolicies`.
- Active process termination, app locking, and network packet dropping are not performed by the Parent App itself; enforcement occurs on the Child Companion app via Android native services (Phase 3).

## 4. Map & Coordinate Visualization
- The interactive map canvas uses mathematical projections and coordinate transforms to visualize child pins and safe-zone boundaries.
- Continuous background GPS tracking daemon is not active on this parent device; coordinates reflect simulated telemetry snapshots or manual test locations.

## 5. Unused Networking-Capable Dependencies (Dependency Hygiene)
- `connectivity_plus` and `geolocator` are declared in [`apps/haven_app/pubspec.yaml`](file:///d:/control/apps/haven_app/pubspec.yaml) but referenced by no `lib/` code in Phase 2.
- **Verification finding (Nov 6, 2026)**: these declarations predate Phase 2 (present since the first commit) and execute no network or location calls in the offline path, so they are not a Phase 2 regression. Recommend removal in a future dependency-hygiene pass to make the offline claim airtight at the binary level.
- Similarly, `supabase_flutter` and `firebase_*` packages remain declared for the Phase 4 cloud seams; they are fully gated behind `offlineMode == false` plus configured dart-defines and cannot initialize in the shipped offline build.

## 6. Kotlin Gradle Plugin Forward-Compatibility Warning
- The debug APK build emits a non-fatal Gradle warning: `firebase_auth` and `firebase_core` apply the Kotlin Gradle Plugin (KGP); future Flutter versions may fail to build with such plugins.
- Build succeeded with exit code 0 on Flutter 3.44.6; tracked for the Phase 4 cloud enablement upgrade pass.

