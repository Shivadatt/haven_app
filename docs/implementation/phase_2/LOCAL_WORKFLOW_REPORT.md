# HAVEN PARENTAL CONTROL — LOCAL WORKFLOW REPORT

**Scope**: Phase 2 — End-to-End Local User Workflows  
**Date**: November 5, 2026 (re-verified November 6, 2026)  
**Status**: VERIFIED OFFLINE — workflows covered by the 990-test baseline; zero cloud/network calls executed in the shipped offline path  

---

## 1. End-to-End User Workflows

### Workflow 1: Local Account Recovery & Password Reset
1. Parent enters email on `/forgot-password` and taps "Request password recovery".
2. System explains that without cloud SMTP, emails cannot be dispatched in offline mode.
3. System presents a direct action button: "Reset password locally".
4. Navigates to `/reset-password` with prefilled email.
5. Parent enters new password, validates length and matching confirmation, and taps "Save new password".
6. Credentials safely update in the local `SecretVault`.

### Workflow 2: Co-Parent & Guardian Invitation
1. Parent opens `/family/invite`.
2. Form accepts partner's email address and role selection (Co-Parent or Guardian).
3. System persists the invitation into `TableName.familyMembers` with status `invited`.
4. Pending invitation immediately appears under "Pending invitations".
5. Parent can review invitation details or cancel the invitation via the dismiss action.

### Workflow 3: Per-App Screen-Time Limits
1. Parent navigates to `/policies/app-limits` via Dashboard or Child Profile.
2. If multiple devices exist, parent selects the target device from the device dropdown.
3. Parent browses or searches the application catalogue (e.g. YouTube, Roblox, Minecraft).
4. Tapping the edit icon opens `LimitPickerDialog`.
5. Parent adjusts daily minutes (e.g. 45 minutes) and saves.
6. Local policy configuration is serialized into `TableName.devicePolicies`.

### Workflow 4: App Rules Configuration (Allow / Block)
1. Parent opens `/policies/app-rules`.
2. Segmented control switches between Allowed and Blocked lists.
3. Tapping "Block" on an allowed app moves it to the Blocked list.
4. Tapping "Add Custom App Rule" allows entering any custom package name.
5. Status banner informs parent that active OS blocking activates in Phase 3.

### Workflow 5: Website Filter & SafeSearch Management
1. Parent opens `/policies/web-filter`.
2. SafeSearch switch toggles Google/Bing/YouTube strict mode configuration.
3. Parent enters a URL in "Add Domain". System automatically normalizes `https://Roblox.com/games` to `roblox.com`.
4. Domain is added to blocked or allowed list with optional category tag.

### Workflow 6: Advanced Schedules with Overnight & App Exceptions
1. Parent opens `/policies/schedules`.
2. Parent creates a schedule (e.g. "Bedtime" 21:00 to 07:00 next day).
3. System automatically calculates overnight duration (+10 hours).
4. Parent selects active days (e.g. Mon–Fri) and adds app exceptions (e.g. Clock, Audible).
5. Conflict validator verifies against existing schedules before saving.

### Workflow 7: App Install & Screen-Time Extension Approvals
1. Child requests are queued locally in `ApprovalSamples` / `LocalApprovalsRepository`.
2. Parent opens `/approvals/apps` or `/approvals/extensions`.
3. Parent taps "Approve" or "Reject", entering a parenting note.
4. System updates the status, records a timestamped audit log in `TableName.auditLogs`, and moves the request to the History tab.

### Workflow 8: Offline Help Centre & Support Inquiries
1. Parent opens `/help` to search setup guides and FAQ articles.
2. Parent navigates to `/help/support` to submit a technical inquiry.
3. Parent drafts subject, category, and issue description.
4. System validates inputs and persists the inquiry directly to local audit tables.

