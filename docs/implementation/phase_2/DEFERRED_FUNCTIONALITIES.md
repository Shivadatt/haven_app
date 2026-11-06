# HAVEN PARENTAL CONTROL — DEFERRED FUNCTIONALITIES CATALOG

**Scope**: Post-Phase 2 Implementation Scope Boundary  
**Date**: November 5, 2026 (disclosure integrity re-audited November 6, 2026)  
**Status**: DOCUMENTED & COMMUNICATED IN UI — audit confirmed every deferred seam resolves to an honest local implementation or explicit `blocked()`/`Unconfigured*` refusal; no code pretends a deferred feature is live  

---

## 1. Explicitly Deferred Capabilities

Phase 2 focuses exclusively on the parent-facing Flutter application and its local offline workflows. The following capabilities are explicitly deferred to subsequent phases as designed:

| Category | Capability | Target Phase | Rationale & Architectural Reason |
| :--- | :--- | :--- | :--- |
| **Cloud Backend** | Supabase Auth, PostgreSQL RLS, Migrations | Phase 4 | Phase 2 runs 100% offline using `OfflineHavenBackend` and local JSON storage. |
| **Messaging & Push** | Firebase Cloud Messaging (FCM) push tokens | Phase 4 | Requires live Google Cloud project endpoints and server infrastructure. |
| **Real Email Dispatch**| SMTP relay for password reset and email confirmation | Phase 4 | Honest offline disclosure cards guide the parent to local password resets. |
| **Child OS Enforcement**| Android `AccessibilityService` daemon & app killing | Phase 3 | Native Android background daemon belongs to the child companion application. |
| **System Management** | `DevicePolicyManager` (DPM) & Knox OS kiosk lock | Phase 3 | Requires Android device owner provisioning and system-level privileges. |
| **Network Interception**| Android `VpnService` & DNS packet filtering | Phase 3 | Requires native packet inspection daemon on the child device. |
| **Continuous GPS** | Android foreground background geofencing service | Phase 3 | Background continuous location daemon requires native battery-optimized services. |
| **Remote Media** | WebRTC live video, microphone, screen streaming | Phase 4 | Advanced child monitoring media streaming. |

---

## 2. Parent App UI Disclosure Integrity

Where parental control settings are configured locally, the user interface does not pretend external enforcement has taken place:
- **App Limits Page**: Displays `AppLimitsBanner` explaining that limits are saved to local policy profile and OS enforcement activates in Phase 3.
- **App Rules Page**: Displays `AppRulesBanner` disclosing that app blocking is configured locally.
- **Website Filter Page**: Displays `WebFilterBanner` stating that domain filters and SafeSearch preferences are saved to the policy profile.
- **Location Page**: Clearly marks child marker coordinates as simulated/manual demo data.
- **Verify Email Page**: Explicitly discloses that outbound email dispatch requires an approved cloud backend.

