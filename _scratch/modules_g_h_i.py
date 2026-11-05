# Modules G, H, I: App & Website Management, Screen Time & Schedules, Remote Monitoring & Sessions

def register_modules_g_h_i(add_feature):
    # MODULE G: APP AND WEBSITE MANAGEMENT (15 features)
    add_feature(
        fid="APP-01",
        module="Module G: App and Website Management",
        name="Installed Applications Directory Listing",
        expected="Displays complete list of applications detected on child's Android device. Shows app icon, application display label, package name, version, and status badge ('Allowed', 'Restricted', 'Blocked').",
        screens="InstalledAppsPage (New Route: '/devices/apps')",
        actions="Scroll apps list, pull to refresh, tap app row to view details, tap filter chip.",
        ui_states="Loading, Populated App List, Empty List ('No apps reported for this device yet').",
        controller="InstalledAppsController (GetxController)",
        model="DeviceAppRecord(packageName, appName, iconUrl, isSystemApp, category)",
        service="ActivityRepository.loadInstalledApps, EdgeCaller (`device-telemetry`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="NOT IMPLEMENTED",
        evidence="apps/haven_app/lib/features/device_activity/views/pages/activity_page.dart (only reads aggregated `usage_daily`; table `device_apps` is never read or displayed).",
        missing="Installed apps list view, app icon resolver, package name formatter, repository method to read `device_apps`.",
        priority="P0",
        classification="App Management"
    )

    add_feature(
        fid="APP-02",
        module="Module G: App and Website Management",
        name="App Detail Inspector",
        expected="Detailed inspector for one application: icon, package name, version, first installed date, today's usage duration, daily launch count, and direct policy controls.",
        screens="AppDetailPage (New Route: '/devices/app-detail')",
        actions="Open app detail, view usage graph, toggle access rule, tap 'Save Rule'.",
        ui_states="Loading, App Details Rendered, Rule Selection Active, Saving Busy.",
        controller="AppDetailController",
        model="DeviceAppDetail(packageName, appName, dailyUsageMinutes, currentPolicy)",
        service="ActivityRepository, PoliciesRepository",
        native="None",
        deps="APP-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="AppDetailPage view, controller, route entry in `AppRoutes`, argument contract.",
        priority="P1",
        classification="App Management"
    )

    add_feature(
        fid="APP-03",
        module="Module G: App and Website Management",
        name="App Categorization System",
        expected="Automatically groups detected applications into standardized categories: Games, Social Media, Entertainment, Education, Communication, Utilities. Displays category header sections.",
        screens="InstalledAppsPage, PoliciesPage",
        actions="Expand/collapse category sections, apply bulk policy to entire category.",
        ui_states="Categorized list views with collapsible headers.",
        controller="InstalledAppsController",
        model="AppCategory enum, CategorizedAppGroup",
        service="AppMetadataService",
        native="None",
        deps="APP-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Category enumeration, category metadata mapper, collapsible section list.",
        priority="P1",
        classification="App Management"
    )

    add_feature(
        fid="APP-04",
        module="Module G: App and Website Management",
        name="App Access Rule Toggle",
        expected="Tri-state selector or popup for each app: 'Always Allowed' (never blocked), 'Time Restricted' (subject to daily limits/bedtime), or 'Completely Blocked' (launch immediately intercepted).",
        screens="InstalledAppsPage, AppDetailPage, PoliciesPage",
        actions="Select access rule radio or segmented control, confirm change.",
        ui_states="Allowed (green), Restricted (amber), Blocked (red).",
        controller="AppDetailController.rule, PoliciesController",
        model="AppRuleState enum (`allowed`, `restricted`, `blocked`)",
        service="PoliciesRepository.setAppRule",
        native="None",
        deps="APP-01",
        status="NOT IMPLEMENTED",
        evidence="`policies_repository.dart` only reads raw version strings; no per-app policy mutation UI exists.",
        missing="Tri-state selector component, policy bundle builder, and `device-policy` Edge Function client.",
        priority="P0",
        classification="Policy Control"
    )

    add_feature(
        fid="APP-05",
        module="Module G: App and Website Management",
        name="Per-App Usage Duration Display",
        expected="Displays hours and minutes spent on each app today, relative formatted last used timestamp, and sorted by most used.",
        screens="ActivityPage (Route: '/devices/activity')",
        actions="View usage list, inspect which app was used on which day.",
        ui_states="Loading, Populated Usage Rows, Empty Usage Board, Device Gap Notice.",
        controller="ActivityController (`apps/haven_app/lib/features/device_activity/controllers/activity_controller.dart`)",
        model="UsageBoard, UsageLine (`apps/haven_app/lib/features/device_activity/data/activity_models.dart`)",
        service="ActivityRepository (`apps/haven_app/lib/features/device_activity/data/activity_repository.dart`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_activity/views/widgets/usage_card.dart:45-75\napps/haven_app/lib/features/device_activity/views/pages/activity_page.dart:18-54\ntest/device_activity/activity_page_test.dart",
        missing="None for usage display; backend read relies on deployed `usage_daily` table.",
        priority="P0",
        classification="Usage Display"
    )

    add_feature(
        fid="APP-06",
        module="Module G: App and Website Management",
        name="Installed App Search Bar",
        expected="Real-time live search input field filtering the installed app directory by application title or package identifier.",
        screens="InstalledAppsPage",
        actions="Type search query into search bar, tap clear button.",
        ui_states="All Apps, Filtered Search Results, No Matching Apps Found.",
        controller="InstalledAppsController.searchQuery",
        model="RxString",
        service="None",
        native="None",
        deps="APP-01",
        status="NOT IMPLEMENTED",
        evidence="None in `activity_page.dart`.",
        missing="Search field widget, debounced search listener, and filtered list predicate in controller.",
        priority="P1",
        classification="App Management UX"
    )

    add_feature(
        fid="APP-07",
        module="Module G: App and Website Management",
        name="App Filter by Status & Category",
        expected="Horizontal row of filter chips: 'All', 'Blocked Only', 'Restricted', 'Games', 'Social Media' to quickly filter the application list.",
        screens="InstalledAppsPage",
        actions="Tap filter chip to toggle filter.",
        ui_states="Active chip highlighted, list updated.",
        controller="InstalledAppsController.activeFilter",
        model="AppFilterCriteria",
        service="None",
        native="None",
        deps="APP-01",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Filter chips component and filter predicate in controller.",
        priority="P1",
        classification="App Management UX"
    )

    add_feature(
        fid="APP-08",
        module="Module G: App and Website Management",
        name="App Policy Save & Push Flow",
        expected="Compiles per-app rules into JSON policy bundle; pushes new policy version to backend via `device-policy` function; displays sync status until device acknowledges.",
        screens="InstalledAppsPage, PoliciesPage",
        actions="Tap 'Save Changes', view policy sync banner.",
        ui_states="Refusal Notice ('Blocked by missing bundle constants V/X/Z... client mutation refused'), Submitting, Synced.",
        controller="PoliciesController.savePolicy",
        model="BlockedFailure, DevicePolicyRecord",
        service="PoliciesRepository.savePolicy (`apps/haven_app/lib/features/policies/data/policies_repository.dart:42`)",
        native="None",
        deps="APP-04",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/policies/data/policies_repository.dart:9-25 (notes `device_policies` write is refused at seam).",
        missing="Policy mutation repository method, bundle compiler, and save bar UI.",
        priority="P0",
        classification="Policy Mutation"
    )

    add_feature(
        fid="APP-09",
        module="Module G: App and Website Management",
        name="Website Filtering Dashboard",
        expected="Dedicated web protection dashboard: master toggle to enable/disable web filtering, toggle for SafeSearch enforcement (Google, YouTube, Bing), and blocklist summary.",
        screens="WebFilterPage (New Route: '/devices/web-filter')",
        actions="Toggle Web Filtering On/Off, toggle SafeSearch, tap 'Manage Blocked Sites'.",
        ui_states="Web Protection Enabled (green), Disabled (warning), SafeSearch active.",
        controller="WebFilterController (GetxController)",
        model="WebFilterPolicy(isEnabled, enforceSafeSearch, allowlist, blocklist)",
        service="WebFilterRepository, PoliciesRepository",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="WebFilterPage view, controller, route entry, web policy model.",
        priority="P1",
        classification="Web Filtering"
    )

    add_feature(
        fid="APP-10",
        module="Module G: App and Website Management",
        name="Web Domain Allowlist / Blocklist Manager",
        expected="Tabbed interface to manage Allowed Websites vs Blocked Websites. Displays domain name (e.g. `youtube.com`, `discord.com`), date added, and delete icon.",
        screens="WebFilterPage, WebListManagerPage",
        actions="Switch tabs between Blocklist and Allowlist, view domain rows, tap delete icon.",
        ui_states="Populated Domain List, Empty Tab ('No blocked websites yet').",
        controller="WebFilterController.blockedDomains, WebFilterController.allowedDomains",
        model="WebDomainRule(domain, isAllowed, addedAt)",
        service="WebFilterRepository",
        native="None",
        deps="APP-09",
        status="NOT IMPLEMENTED",
        evidence="None in codebase.",
        missing="Domain list view, tab bar, domain list tile components.",
        priority="P1",
        classification="Web Filtering"
    )

    add_feature(
        fid="APP-11",
        module="Module G: App and Website Management",
        name="Add Website Domain Dialog & URL Validation",
        expected="Modal dialog prompting parent to input a domain or URL. Validates syntax against RFC domain regex, strips `https://` prefix, checks for duplicates, and adds to list.",
        screens="WebFilterPage / AddDomainDialog",
        actions="Tap 'Add Website', enter domain (e.g. 'tiktok.com'), tap 'Block Domain'.",
        ui_states="Dialog Open, Validating Input, Error (invalid URL), Adding Busy.",
        controller="WebFilterController.addDomain",
        model="ValidationResult",
        service="Validation module",
        native="None",
        deps="APP-10, AUTH-08",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Add domain dialog, domain validation regex, add controller method.",
        priority="P1",
        classification="Web Filtering"
    )

    add_feature(
        fid="APP-12",
        module="Module G: App and Website Management",
        name="Edit & Remove Restricted Website Domain",
        expected="Swipe-to-delete or remove button on domain list items with confirmation sheet to remove domain from filter list.",
        screens="WebFilterPage",
        actions="Swipe domain item or tap trash icon, confirm removal in bottom sheet.",
        ui_states="Confirmation Sheet Active, Removing, Removed.",
        controller="WebFilterController.removeDomain",
        model="Result<void>",
        service="WebFilterRepository",
        native="None",
        deps="APP-10",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Swipe-to-dismiss domain tile, confirmation sheet, delete method in repository.",
        priority="P1",
        classification="Web Filtering"
    )

    add_feature(
        fid="APP-13",
        module="Module G: App and Website Management",
        name="Web Content Category Filtering",
        expected="High-level category toggles allowing parent to block entire classes of web content with one tap: Adult & Mature, Gambling, Violence, Weapons, Social Networks.",
        screens="WebFilterPage",
        actions="Toggle category switch on/off, tap save.",
        ui_states="Category cards with switches and descriptions.",
        controller="WebFilterController",
        model="WebCategoryRule(categoryName, isBlocked)",
        service="WebFilterRepository",
        native="None",
        deps="APP-09",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Category switches card, category-to-DNS rule compiler.",
        priority="P2",
        classification="Web Filtering"
    )

    add_feature(
        fid="APP-14",
        module="Module G: App and Website Management",
        name="Policy Change Confirmation Sheet",
        expected="Safety guard dialog warning parent before applying critical restrictions (e.g. blocking phone dialer, emergency SOS, or school portal); requires explicit confirmation.",
        screens="InstalledAppsPage, WebFilterPage",
        actions="Attempt to block system app, view warning sheet, confirm or cancel.",
        ui_states="Warning modal sheet (`ConfirmSheet.confirm`).",
        controller="InstalledAppsController, WebFilterController",
        model="SystemSafetyWarning",
        service="ConfirmSheet (`apps/haven_app/lib/shared/components/confirm_sheet.dart`)",
        native="None",
        deps="APP-04",
        status="NOT IMPLEMENTED",
        evidence="`ConfirmSheet.confirm` exists in core shared components, but is not wired to policy mutations.",
        missing="Critical app whitelist check and policy confirmation sheet trigger.",
        priority="P1",
        classification="Policy UX"
    )

    add_feature(
        fid="APP-15",
        module="Module G: App and Website Management",
        name="Policy Enforcement Sync Status Indicator",
        expected="Displays the exact synchronization status of rule versions on record for the device: 'Applied by device', 'Pending delivery', 'Superseded by newer version'.",
        screens="PoliciesPage (Route: '/devices/policies')",
        actions="Pull to refresh, view rule version status cards.",
        ui_states="Loading, Populated Version Cards, Empty Setup Required.",
        controller="PoliciesController (`apps/haven_app/lib/features/policies/controllers/policies_controller.dart`)",
        model="PolicyBoard, PolicyLine (`apps/haven_app/lib/features/policies/data/policies_models.dart`)",
        service="PoliciesRepository (`apps/haven_app/lib/features/policies/data/policies_repository.dart`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/policies/views/widgets/policy_card.dart:1-105\napps/haven_app/lib/features/policies/views/pages/policies_page.dart:18-54\ntest/policies/policies_page_test.dart",
        missing="Child-side native policy receiver; parent read-only display is complete.",
        priority="P0",
        classification="Policy Telemetry"
    )

    # MODULE H: SCREEN TIME AND SCHEDULES (13 features)
    add_feature(
        fid="TIME-01",
        module="Module H: Screen Time and Schedules",
        name="Daily Screen Time Aggregated Meter",
        expected="Large circular progress or stacked bar meter showing total screen time accumulated today against the configured daily limit (e.g. '1h 45m of 2h 30m used'). Changes color to amber at 80% and red at 100%.",
        screens="ScreenTimePage (New Route: '/devices/screen-time')",
        actions="View daily meter, tap 'Change Limit', tap 'Add Bonus Time'.",
        ui_states="Progress meter rendered, percentage calculated, limit reached state.",
        controller="ScreenTimeController (GetxController)",
        model="DailyUsageSummary(usedSeconds, limitSeconds, remainingSeconds)",
        service="ScreenTimeRepository, ActivityRepository",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="NOT IMPLEMENTED",
        evidence="`activity_page.dart` lists raw day rows; no aggregated progress meter exists.",
        missing="Screen time gauge component, daily sum aggregator, ScreenTimePage route.",
        priority="P0",
        classification="Screen Time Core"
    )

    add_feature(
        fid="TIME-02",
        module="Module H: Screen Time and Schedules",
        name="Weekly Screen Time Bar Chart",
        expected="7-day interactive bar chart showing daily screen time comparison (Monday through Sunday) with daily average line and weekday/weekend split.",
        screens="ScreenTimePage",
        actions="Tap bar to inspect specific day, toggle between This Week and Last Week.",
        ui_states="7-day bar chart with animated bars and day labels.",
        controller="ScreenTimeController.weeklyData",
        model="WeeklyUsageRecord(days: List<DailyUsageSummary>)",
        service="ScreenTimeRepository",
        native="None",
        deps="TIME-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Bar chart widget (`fl_chart` or custom painter), weekly usage aggregator, day selector.",
        priority="P1",
        classification="Screen Time Visualization"
    )

    add_feature(
        fid="TIME-03",
        module="Module H: Screen Time and Schedules",
        name="Per-App Screen Time Ranking",
        expected="Ranked list of applications sorted in descending order of screen time today, displaying app icon, name, formatted duration, and percentage of total time.",
        screens="ScreenTimePage, ActivityPage",
        actions="Scroll app ranking list, tap app to set individual app limit.",
        ui_states="Ranked list of apps with duration bars.",
        controller="ActivityController, ScreenTimeController",
        model="UsageBoard, UsageLine",
        service="ActivityRepository",
        native="None",
        deps="APP-05",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/device_activity/views/widgets/usage_card.dart:45-75\ntest/device_activity/activity_page_test.dart",
        missing="None.",
        priority="P0",
        classification="Usage Visualization"
    )

    add_feature(
        fid="TIME-04",
        module="Module H: Screen Time and Schedules",
        name="Daily Total Screen Time Limit Picker",
        expected="Duration wheel / slider dialog allowing parent to set maximum screen time allowance per day (e.g. 2 hours 30 mins) with option to configure separate Weekday vs Weekend allowances.",
        screens="ScreenTimePage / DailyLimitDialog",
        actions="Adjust hours and minutes sliders, toggle 'Separate Weekend Limit', tap 'Save Limit'.",
        ui_states="Dialog Active, Sliders Updating, Saving Busy, Saved.",
        controller="ScreenTimeController.setDailyLimit",
        model="DailyLimitPolicy(weekdayMinutes, weekendMinutes)",
        service="PoliciesRepository.saveDailyLimit",
        native="None",
        deps="TIME-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Duration picker dialog, daily limit model, and policy mutation binding.",
        priority="P0",
        classification="Screen Time Mutation"
    )

    add_feature(
        fid="TIME-05",
        module="Module H: Screen Time and Schedules",
        name="App-Specific Time Quota Editor",
        expected="Allows parent to set a strict time limit on a specific application or category (e.g. YouTube: max 45 minutes/day). When limit is exhausted, that specific app locks while phone remains usable.",
        screens="AppDetailPage / AppLimitDialog",
        actions="Select app, set duration limit, toggle 'Block when limit reached', tap 'Save'.",
        ui_states="Dialog Active, Duration Picker, Saving, Saved.",
        controller="AppDetailController.setLimit",
        model="AppTimeLimit(packageName, maxMinutesPerDay)",
        service="PoliciesRepository.setAppLimit",
        native="None",
        deps="APP-02, TIME-04",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Per-app limit modal, quota data structure, and policy generator.",
        priority="P1",
        classification="Screen Time Mutation"
    )

    add_feature(
        fid="TIME-06",
        module="Module H: Screen Time and Schedules",
        name="Bedtime / Downtime Schedule Configuration",
        expected="Nightly downtime schedule configuration: bedtime start time (e.g. 9:00 PM) to wake-up end time (e.g. 7:00 AM). Locks child phone overnight except for emergency call dialer.",
        screens="SchedulesPage / BedtimeEditorSheet",
        actions="Select bedtime start time, select end time, choose active days, toggle Bedtime on/off, save.",
        ui_states="Bedtime Card with active hours and day chips, Time Picker Active.",
        controller="SchedulesController (GetxController)",
        model="DowntimeSchedule(startTime, endTime, daysOfWeek, isEnabled)",
        service="PoliciesRepository.saveDowntimeSchedule",
        native="None",
        deps="TIME-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Bedtime schedule editor card, time pickers, active toggle switch.",
        priority="P0",
        classification="Schedules Core"
    )

    add_feature(
        fid="TIME-07",
        module="Module H: Screen Time and Schedules",
        name="School Hours / Focus Schedule Configuration",
        expected="School hours focus schedule (e.g. Mon-Fri 8:30 AM to 3:30 PM). Automatically blocks games, entertainment, and social apps during school while allowing educational apps and phone calls.",
        screens="SchedulesPage / SchoolScheduleEditorSheet",
        actions="Select school hours start/end, select school days, toggle School Mode on/off, save.",
        ui_states="School Schedule Card with time window and category restriction summary.",
        controller="SchedulesController",
        model="SchoolSchedule(startTime, endTime, schoolDays, isEnabled)",
        service="PoliciesRepository.saveSchoolSchedule",
        native="None",
        deps="TIME-06, APP-03",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="School schedule editor UI, day selector, category whitelist selector.",
        priority="P1",
        classification="Schedules Core"
    )

    add_feature(
        fid="TIME-08",
        module="Module H: Screen Time and Schedules",
        name="Custom Schedule Creation & Grid Editor",
        expected="Allows parent to create custom named schedules (e.g. 'Study Hours', 'Dinner Family Time') with custom start/end time and recurring days.",
        screens="SchedulesPage / CustomScheduleEditorPage",
        actions="Tap 'Create New Schedule', type schedule name, pick start/end time, pick days, save.",
        ui_states="Schedule Creation Form, Saving Busy, Saved.",
        controller="SchedulesController.createCustomSchedule",
        model="CustomSchedule(id, name, startTime, endTime, daysOfWeek, isEnabled)",
        service="PoliciesRepository.saveCustomSchedule",
        native="None",
        deps="TIME-06",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Custom schedule creator form, schedule list view, day-time grid widget.",
        priority="P1",
        classification="Schedules Core"
    )

    add_feature(
        fid="TIME-09",
        module="Module H: Screen Time and Schedules",
        name="Schedule Day-of-Week Recurrence Selector",
        expected="7 circular day toggle chips (M, T, W, T, F, S, S) allowing multiselect of recurrence days with quick preset buttons ('Every day', 'Weekdays', 'Weekends').",
        screens="BedtimeEditorSheet, SchoolScheduleEditorSheet, CustomScheduleEditorPage",
        actions="Tap day chips to toggle active recurrence, tap 'Weekdays' preset.",
        ui_states="Selected day chips highlighted in primary accent.",
        controller="DaySelectorWidget state",
        model="List<int> activeDaysOfWeek",
        service="None",
        native="None",
        deps="TIME-06",
        status="NOT IMPLEMENTED",
        evidence="None in codebase.",
        missing="Day toggle chips widget and day-of-week bitmask data structure.",
        priority="P1",
        classification="Schedules UX"
    )

    add_feature(
        fid="TIME-10",
        module="Module H: Screen Time and Schedules",
        name="Schedule Time Window Picker",
        expected="Dual time picker component specifying start time and end time with automatic duration display (e.g. '9:00 PM - 7:00 AM (10 hours)'). Handles overnight wrap-around correctly.",
        screens="Schedule editor sheets",
        actions="Tap start time, select hour/minute, tap end time, select hour/minute.",
        ui_states="Time picker modal dialog, duration display.",
        controller="TimeWindowPicker state",
        model="TimeOfDay startTime, TimeOfDay endTime",
        service="None",
        native="None",
        deps="TIME-06",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Time range picker component and overnight duration calculator.",
        priority="P1",
        classification="Schedules UX"
    )

    add_feature(
        fid="TIME-11",
        module="Module H: Screen Time and Schedules",
        name="Schedule Enabled/Disabled Master Toggle",
        expected="Switch on each schedule card allowing parent to temporarily suspend a schedule (e.g. during school holidays) without deleting its configuration.",
        screens="SchedulesPage",
        actions="Toggle switch on schedule card.",
        ui_states="Active (green), Suspended (grey outline).",
        controller="SchedulesController.toggleSchedule",
        model="ScheduleRecord.isEnabled",
        service="PoliciesRepository.toggleScheduleState",
        native="None",
        deps="TIME-06",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Schedule card toggle switch and policy update dispatch.",
        priority="P0",
        classification="Schedules UX"
    )

    add_feature(
        fid="TIME-12",
        module="Module H: Screen Time and Schedules",
        name="Delete Schedule Confirmation Flow",
        expected="Allows parent to remove a custom schedule with confirmation dialog to avoid accidental deletion.",
        screens="SchedulesPage",
        actions="Tap delete icon on custom schedule, confirm deletion.",
        ui_states="Confirmation Sheet Active, Deleting, Removed.",
        controller="SchedulesController.deleteSchedule",
        model="Result<void>",
        service="PoliciesRepository.deleteSchedule",
        native="None",
        deps="TIME-08",
        status="NOT IMPLEMENTED",
        evidence="None.",
        missing="Delete schedule action and confirmation dialog.",
        priority="P1",
        classification="Schedules UX"
    )

    add_feature(
        fid="TIME-13",
        module="Module H: Screen Time and Schedules",
        name="Limit Reached Alert & Lockout UI Preview",
        expected="Preview of the lockout screen displayed on child device when screen time is exhausted; parent can send a one-tap 'Grant 15m Extension' command.",
        screens="ScreenTimePage / LockoutPreviewPage",
        actions="Tap 'Preview Child Lockout Screen', tap 'Grant 15m Extension'.",
        ui_states="Lockout Screen Preview, Extension Granted Toast.",
        controller="ScreenTimeController.grantBonusTime",
        model="CommandDraft",
        service="CommandsRepository (`apps/haven_app/lib/features/device_commands/data/commands_repository.dart`)",
        native="None",
        deps="TIME-01",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Lockout preview screen and temporary time grant command action.",
        priority="P1",
        classification="Screen Time UX"
    )

    # MODULE I: REMOTE MONITORING AND SESSIONS (12 features)
    add_feature(
        fid="SESS-01",
        module="Module I: Remote Monitoring and Sessions",
        name="Remote Monitoring Hub & Active Sessions Directory",
        expected="Central screen displaying active or past remote sessions, session status chips ('Requested', 'Accepted', 'Active', 'Ended'), and button to initiate a new session.",
        screens="RemoteSessionsPage (Route: '/remote-sessions')",
        actions="Open Remote Sessions, view active/historical sessions, tap session to view detail, pull to refresh.",
        ui_states="Loading, Populated Sessions List, Empty Setup Required.",
        controller="SessionsController (`apps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart`)",
        model="SessionBoard, RemoteSession (`packages/haven_models/lib/src/session_models.dart`)",
        service="SessionsRepository (`apps/haven_app/lib/features/remote_sessions/data/sessions_repository.dart`)",
        native="None",
        deps="AUTH-01, PAIR-09",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/remote_sessions/views/pages/remote_sessions_page.dart:12-52\napps/haven_app/lib/features/remote_sessions/controllers/sessions_controller.dart:25-70\ntest/remote_sessions/remote_sessions_page_test.dart",
        missing="None for directory listing; initiation blocked by RPC grant wall.",
        priority="P0",
        classification="Remote Monitoring"
    )

    add_feature(
        fid="SESS-02",
        module="Module I: Remote Monitoring and Sessions",
        name="Initiate Remote Session Request",
        expected="Button allowing parent to initiate a remote session for a selected child device. Opens dialog to select session type (Live Screen View, Ambient Audio Stream); sends request to backend.",
        screens="RemoteSessionsPage / StartSessionDialog",
        actions="Tap 'Start Session', select session type, tap 'Send Request to Child Phone'.",
        ui_states="Refusal Notice ('Blocked by RPC grant wall... request_remote_session unexecuted'), Dialog Active, Sending, Waiting for Child.",
        controller="SessionsController.startSession",
        model="BlockedFailure, RemoteSessionDraft",
        service="SessionsRepository.requestSession (`session_gaps.dart:13-25`)",
        native="None",
        deps="SESS-01",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/remote_sessions/data/session_gaps.dart:13-25\napps/haven_app/lib/features/remote_sessions/data/sessions_repository.dart:30-40",
        missing="UI renders refusal `BlockedNotice` ('request_remote_session unexecuted'). Initiation dialog and RPC client missing.",
        priority="P0",
        classification="Session Mutation"
    )

    add_feature(
        fid="SESS-03",
        module="Module I: Remote Monitoring and Sessions",
        name="Child Approval & Consent Dialog Mandate",
        expected="Strict privacy invariant: remote session cannot start until child explicitly taps 'Allow' on their phone. Consent boolean is carried in model and validated in all round-trip tests.",
        screens="Child Device Screen / Session Consent Dialog",
        actions="Child taps 'Allow' or 'Decline' on child phone.",
        ui_states="Consent Dialog on Child Phone, Waiting State on Parent Phone.",
        controller="SessionsController",
        model="RemoteSession.consentGiven (`packages/haven_models/lib/src/remote_session.dart:25-45`)",
        service="MediaPeer (`apps/haven_app/lib/features/remote_sessions/services/media_peer.dart`)",
        native="None",
        deps="SESS-02",
        status="COMPLETE",
        evidence="packages/haven_models/lib/src/remote_session.dart:25-45\npackages/haven_models/test/round_trips_test.dart:55-75\napps/haven_app/lib/features/remote_sessions/services/media_peer.dart:45",
        missing="Child-side native consent dialog prompt.",
        priority="P0",
        classification="Privacy Invariant"
    )

    add_feature(
        fid="SESS-04",
        module="Module I: Remote Monitoring and Sessions",
        name="Session Request Rejection & Timeout Handling",
        expected="Handles child refusal or 60-second request timeout cleanly: shows notice ('Request declined by child' or 'No response from device - request timed out').",
        screens="RemoteSessionDetailPage (Route: '/remote-session')",
        actions="View rejection reason, tap 'Close'.",
        ui_states="Rejection Notice with amber tone, Timeout state.",
        controller="SessionDetailController (`apps/haven_app/lib/features/remote_sessions/controllers/session_detail_controller.dart`)",
        model="RemoteSessionStatus enum (`requested`, `accepted`, `rejected`, `ended`)",
        service="SessionDetailRepository",
        native="None",
        deps="SESS-02",
        status="COMPLETE",
        evidence="packages/haven_models/lib/src/enums_sessions.dart:1-25\napps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart:45-52\ntest/remote_sessions/remote_session_detail_test.dart",
        missing="None.",
        priority="P1",
        classification="Session State Machine"
    )

    add_feature(
        fid="SESS-05",
        module="Module I: Remote Monitoring and Sessions",
        name="Active Session Canvas (Live Video / Screen View)",
        expected="Embedded or fullscreen viewport rendering the incoming WebRTC video stream of child's screen or camera once consent is confirmed. Provides mute and expand controls.",
        screens="RemoteSessionDetailPage / ActiveSessionCanvasPage",
        actions="View live stream, tap mute audio, tap expand fullscreen, tap End Session.",
        ui_states="Refusal Notice ('Media peer unreachable: TURN credentials uncreated'), Video Streaming Canvas, Audio Only Indicator.",
        controller="SessionDetailController",
        model="BlockedFailure, RTCVideoRenderer",
        service="MediaPeer (`apps/haven_app/lib/features/remote_sessions/services/media_peer.dart:30-46`)",
        native="Native WebRTC / MediaProjection",
        deps="SESS-03",
        status="PLACEHOLDER",
        evidence="apps/haven_app/lib/features/remote_sessions/services/media_peer.dart:30-46 (`UnspecifiedMediaPeer` returns `blocked(...)`).",
        missing="`flutter_webrtc` plugin integration, RTCVideoRenderer widget, SDP exchange handshake, Coturn server credentials.",
        priority="P2",
        classification="Media Streaming"
    )

    add_feature(
        fid="SESS-06",
        module="Module I: Remote Monitoring and Sessions",
        name="Session Live Timer & Maximum Duration Enforcer",
        expected="Floating timer showing active session duration (e.g. '04:15 / 15:00 max') with animated pulse. Automatically terminates session when 15-minute safety ceiling is reached.",
        screens="RemoteSessionDetailPage",
        actions="Observe timer counting up/down.",
        ui_states="Active Timer, 2-Minute Warning, Auto-Terminated Notice.",
        controller="SessionDetailController.elapsedSeconds",
        model="Duration, RxInt",
        service="Clock",
        native="None",
        deps="SESS-05",
        status="NOT IMPLEMENTED",
        evidence="None in frontend codebase.",
        missing="Live countdown timer widget and auto-terminate scheduler.",
        priority="P1",
        classification="Session UX"
    )

    add_feature(
        fid="SESS-07",
        module="Module I: Remote Monitoring and Sessions",
        name="Terminate Session Action & Confirmation",
        expected="Prominent red 'End Session' button immediately tearing down WebRTC media stream, closing peer connection, and recording session termination timestamp in backend.",
        screens="RemoteSessionDetailPage",
        actions="Tap 'End Session', confirm in modal sheet.",
        ui_states="Active Session, Ending Busy, Session Ended Summary.",
        controller="SessionDetailController.terminateSession",
        model="Result<void>",
        service="SessionsRepository.terminateSession",
        native="None",
        deps="SESS-05",
        status="PARTIAL",
        evidence="apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart:1-76 (displays detail; terminate mutation refused at seam).",
        missing="Terminate button action and peer disconnection trigger.",
        priority="P0",
        classification="Session Lifecycle"
    )

    add_feature(
        fid="SESS-08",
        module="Module I: Remote Monitoring and Sessions",
        name="No Active Session Empty State",
        expected="Clean illustration stating that no remote session is currently active, with educational copy on child consent requirements.",
        screens="RemoteSessionsPage",
        actions="View empty explanation.",
        ui_states="Empty Sessions SectionCard.",
        controller="SessionsController.board",
        model="SessionBoard",
        service="None",
        native="None",
        deps="SESS-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/remote_sessions/views/widgets/session_card.dart:25-35",
        missing="None.",
        priority="P0",
        classification="Session UX"
    )

    add_feature(
        fid="SESS-09",
        module="Module I: Remote Monitoring and Sessions",
        name="Monitoring Privacy & Consent Disclosure Card",
        expected="Educational card explaining that Haven never records audio/video stealthily and child is always notified of active sessions via persistent Android notification.",
        screens="RemoteSessionDetailPage",
        actions="Read privacy promises.",
        ui_states="Educational SectionCard.",
        controller="SessionDetailController",
        model="None (Static privacy text)",
        service="None",
        native="None",
        deps="SESS-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/remote_sessions/views/widgets/session_detail_card.dart:45-80\napps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart:48",
        missing="None.",
        priority="P1",
        classification="Compliance / Legal UI"
    )

    add_feature(
        fid="SESS-10",
        module="Module I: Remote Monitoring and Sessions",
        name="WebRTC Connection Quality & Signalling Status",
        expected="Status badge showing WebRTC connection state: 'Connecting', 'Signalling', 'Connected (Good)', 'Reconnecting', 'Disconnected'.",
        screens="RemoteSessionDetailPage",
        actions="Observe connection status badge.",
        ui_states="Connecting (neutral), Good (green), Reconnecting (amber), Failed (red).",
        controller="SessionDetailController.connectionState",
        model="WebRTCConnectionState enum",
        service="MediaPeer",
        native="None",
        deps="SESS-05",
        status="PARTIAL",
        evidence="packages/haven_models/lib/src/session_models.dart\napps/haven_app/lib/features/remote_sessions/data/session_gaps.dart:29-45",
        missing="Live ICE connection state listener.",
        priority="P2",
        classification="Network / Media Telemetry"
    )

    add_feature(
        fid="SESS-11",
        module="Module I: Remote Monitoring and Sessions",
        name="Connection Failure & Reconnect Retry Flow",
        expected="When media stream drops, displays 'Connection lost' banner with 'Reconnect' button and network failure diagnostic.",
        screens="RemoteSessionDetailPage",
        actions="Tap 'Reconnect' button.",
        ui_states="Connection Failure Banner with retry button.",
        controller="SessionDetailController.retry",
        model="HavenFailure",
        service="SessionDetailRepository",
        native="None",
        deps="SESS-05",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/remote_sessions/views/pages/remote_session_detail_page.dart:70-76\ntest/remote_sessions/remote_session_detail_test.dart",
        missing="None.",
        priority="P1",
        classification="Error Architecture"
    )

    add_feature(
        fid="SESS-12",
        module="Module I: Remote Monitoring and Sessions",
        name="Historic Remote Session Detail Record",
        expected="Read-only audit inspector for past sessions: start time, end time, duration, initiator, child consent timestamp, and termination reason.",
        screens="RemoteSessionDetailPage",
        actions="Scroll session history facts.",
        ui_states="Detailed audit rows.",
        controller="SessionDetailController.detail",
        model="SessionDetail (`apps/haven_app/lib/features/remote_sessions/data/session_detail_models.dart`)",
        service="SessionDetailRepository.load",
        native="None",
        deps="SESS-01",
        status="COMPLETE",
        evidence="apps/haven_app/lib/features/remote_sessions/views/widgets/session_detail_card.dart:15-50\ntest/remote_sessions/session_detail_controller_test.dart",
        missing="None.",
        priority="P1",
        classification="Audit Logging"
    )

print("Modules G, H, I registered.")
