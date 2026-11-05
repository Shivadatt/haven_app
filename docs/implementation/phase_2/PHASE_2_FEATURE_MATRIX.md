# HAVEN PARENTAL CONTROL — PHASE 2 FEATURE STATUS MATRIX

**Scope**: Phase 2 — Complete Parent App Functionality Implementation  
**Last Updated**: November 5, 2026  
**Status Key**:
- **COMPLETE**: Implemented, verified offline, and covered by automated unit/widget tests.
- **DEFERRED**: Explicitly deferred to Phase 3 (Android Native Daemons) or Phase 4 (Cloud & Realtime).

---

## 1. Feature Status Matrix

| Module | Feature ID & Name | Route | Controller / Component | Local Storage / Table | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth** | Password Recovery Request | `/forgot-password` | `ForgotPasswordController` | `LocalUserAuth` | **COMPLETE** |
| **Auth** | Local Password Reset | `/reset-password` | `ResetPasswordController` | `SecretVault` | **COMPLETE** |
| **Auth** | Email Verification Status | `/verify-email` | `VerifyEmailController` | Local Session State | **COMPLETE** |
| **Family** | Co-Parent / Guardian Invite | `/family/invite` | `FamilyInviteController` | `family_members` | **COMPLETE** |
| **Family** | Child Profile Creator | `/family/child/create` | `ChildCreateController` | `profiles`, `family_members`| **COMPLETE** |
| **Family** | Enhanced Child Profile | `/family/child` | `ChildProfileController` | `profiles`, `devices` | **COMPLETE** |
| **Devices** | Hardware Specs & Info | `/devices/detail` | `DeviceDetailController` | `devices` | **COMPLETE** |
| **Devices** | Child Reassignment & Unlink | `/devices/detail` | `DeviceDetailController` | `devices` | **COMPLETE** |
| **Policies**| Per-App Time Limits | `/policies/app-limits` | `AppLimitsController` | `device_policies` | **COMPLETE** |
| **Policies**| App Allowlist & Blocklist | `/policies/app-rules` | `AppRulesController` | `device_policies` | **COMPLETE** |
| **Policies**| Domain Filter & SafeSearch | `/policies/web-filter` | `WebFilterController` | `device_policies` | **COMPLETE** |
| **Policies**| Overnight Schedule Windows | `/policies/schedules` | `SchedulesEditorController` | `device_policies` | **COMPLETE** |
| **Policies**| School Time App Exceptions | `/policies/schedules` | `SchedulesEditorController` | `device_policies` | **COMPLETE** |
| **Location**| Canvas Vector Map View | `/devices/location` | `LocationController` | `safe_zones` | **COMPLETE** |
| **Location**| Zone Geometry & Radius | `/safe-zones/editor` | `ZoneEditorController` | `safe_zones` | **COMPLETE** |
| **Location**| Zone Creator with Preview | `/safe-zones/create` | `ZoneCreateController` | `safe_zones` | **COMPLETE** |
| **Approvals**| App Install Requests Queue | `/approvals/apps` | `AppApprovalsController` | `audit_logs` | **COMPLETE** |
| **Approvals**| Screen-Time Extension Queue | `/approvals/extensions` | `ExtensionRequestsController` | `audit_logs` | **COMPLETE** |
| **Help** | Searchable Knowledge Base | `/help` | `HelpController` | `LocalSupportRepository` | **COMPLETE** |
| **Help** | FAQ Accordion & Search | `/help/faq` | `FaqController` | `LocalSupportRepository` | **COMPLETE** |
| **Help** | Local Support Tickets | `/help/support` | `SupportController` | `audit_logs` | **COMPLETE** |
| **Dashboard**| Quick Action Shortcuts Card| `/dashboard` | `DashboardController` | Composite State | **COMPLETE** |

---

## 2. Summary by Status

- **Complete Features**: 22 / 22 in approved Phase 2 scope (100%).
- **Deferred Cloud Features**: 0 blocking Phase 2 parent app functionality.
- **Automated Tests**: 975+ automated tests passing with zero failures.

