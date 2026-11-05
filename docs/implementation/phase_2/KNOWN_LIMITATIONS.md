# HAVEN PARENTAL CONTROL — PHASE 2 KNOWN LIMITATIONS

**Scope**: Phase 2 — Parent App Offline Implementation  
**Date**: November 5, 2026  
**Status**: DESIGN LIMITATIONS (PLANNED)  

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

