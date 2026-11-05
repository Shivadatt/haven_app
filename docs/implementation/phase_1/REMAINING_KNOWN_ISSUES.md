# HAVEN PARENTAL CONTROL — REMAINING KNOWN ISSUES & LIMITATIONS

**Scope**: Post-Phase 1 Stabilization  
**Date**: November 5, 2026  
**Status**: All Phase 1 Core App Offline Foundation bugs resolved; items below represent planned limitations by design.

---

## 1. Intentional Phase 1 Architectural Limitations

### 1. Single Active Local Parent Session
- **Description**: The offline authentication engine (`LocalUserAuth`) maintains one active `AuthSession` in memory per process execution.
- **Why It Remains**: This is the intended offline design. Multi-user concurrent switching on a single parent device without cloud identity synchronization is not required for Phase 1.
- **Impact**: When signing into another local account, the previous session is terminated.
- **Target Resolution**: Phase 2 (Supabase JWT multi-account/session support).

### 2. Device Pairing is Simulated On-Device
- **Description**: The 6-digit pairing code workflow creates simulated child devices (`SimulatedDevice`) within the local database instead of linking an external physical phone.
- **Why It Remains**: Remote physical pairing requires server-side token rendezvous or local network (mDNS/Bluetooth) socket handshakes, which are excluded from Phase 1.
- **Impact**: Real physical child devices cannot receive remote policy commands until the transport layer is built.
- **Target Resolution**: Phase 2 (Edge Functions / Supabase realtime pairing exchange).

### 3. Policy Enforcement is Model-Level (Not OS-Level)
- **Description**: Parental policies (screen time limits, schedules, website categories) are stored, versioned, and validated in `TableName.devicePolicies`, but are not enforced by the Android operating system on this device.
- **Why It Remains**: Android `DevicePolicyManager`, Knox SDK, and `AccessibilityService` native daemons belong to Phase 3 child app implementation.
- **Impact**: Policies are displayed, scheduled, and validated in the Parent App UI, but apps on the host phone are not killed or blocked.
- **Target Resolution**: Phase 3 (Android Native Child Daemon & Enforcement).

### 4. Continuous GPS Tracking is Calculated Statistically
- **Description**: Safe zone evaluation (`SafeZonePresenceCalculator`) calculates distances using the Haversine formula against coordinate inputs. Continuous background GPS logging daemon is not running in Phase 1.
- **Why It Remains**: Background location services consume battery and require native Android foreground service notifications with `ACCESS_BACKGROUND_LOCATION` runtime permissions.
- **Impact**: Presence calculation works on coordinate demand or simulated events.
- **Target Resolution**: Phase 3 (Android Native Background Geofencing Service).

### 5. Kotlin Gradle Plugin (KGP) Warning on Android Build
- **Description**: During `flutter build apk`, a warning is emitted:  
  `WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_auth, firebase_core. Future versions of Flutter will fail to build if your app uses plugins that apply KGP.`
- **Why It Remains**: Upstream Flutter Firebase plugins (`firebase_core` and `firebase_auth`) still use the legacy KGP application pattern in their current releases. The build succeeds cleanly with exit code 0.
- **Impact**: Informational build warning only; does not affect application runtime or APK generation.
- **Target Resolution**: Upstream plugin updates in Phase 2.

---

## 2. Summary of Resolved Issues

For detailed root-cause analyses and verification test results for all 8 issues discovered and resolved during this audit, see:
- [`ISSUE_AUDIT.md`](file:///d:/control/docs/implementation/phase_1/ISSUE_AUDIT.md)
- [`ISSUE_FIX_REPORT.md`](file:///d:/control/docs/implementation/phase_1/ISSUE_FIX_REPORT.md)
- [`FINAL_VERIFICATION_REPORT.md`](file:///d:/control/docs/implementation/phase_1/FINAL_VERIFICATION_REPORT.md)

