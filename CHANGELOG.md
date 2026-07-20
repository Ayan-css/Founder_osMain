# Changelog

## 1.3.0 — 2026-07-20

### Added
- **Outreach Interaction Timeline**: Added a full chronological activity log (emails, calls, meetings) to the `OutreachDetailScreen`.
- **Tap-to-Action**: Contact details in `OutreachDetailScreen` can now be tapped to quickly launch native apps (e.g. dialer, email).
- **Outreach Priority & Campaigns**: Prospects can now be tagged with Priority (High, Medium, Low) and assigned to specific Campaigns in the Outreach screen.
- **"To Contact" Status**: Added a new status for tracking raw leads discovered from Google Maps, LinkedIn, etc., before any outreach happens.
- **Templates Hub**: Added a `TemplatesScreen` to save, manage, and copy-paste reusable messaging scripts for various platforms.
- **Outreach Analytics**: Added a new `OutreachAnalyticsScreen` visualizing the conversion funnel and platform distribution via charts.
- **Dashboard Follow-ups Widget**: A new widget displays pending and overdue outreach follow-ups directly on the Dashboard.
- **System Push Notifications**: Integrated local push notifications (`flutter_local_notifications`) to send device reminders at 9 AM for scheduled outreach follow-ups.

## 1.2.0 — 2026-07-14

### Added
- **Kanban View**: Added a toggleable drag-and-drop Kanban board for Outreach tracking.
- **Outreach Export**: Export outreach data to CSV format directly from the app.
- **Contact Details**: Added a new field to `OutreachItem` to track specific contact info (Phone, Email, Instagram, Google Maps link, etc.).
- **Door to Door**: Added 'Door to Door' as a new outreach platform option.
- **MRR Targets**: Set and track Monthly Recurring Revenue (MRR) goals directly from the Dashboard.
- **Farewell Messages**: New Islamic-themed project completion message template in the Client Details WhatsApp menu.
- **App Drawer Redesign**: Redesigned navigation sidebar with a premium header displaying the active Workspace Name and User Role.
- **Project Memory**: Added `memory.md` to persist project architecture and schema for easier AI model handoffs.
- **Calendar Sync**: Integrated `add_2_calendar` to allow saving Meeting Hub items directly to native device calendars.
- **AI Insights Widget**: Added an intelligent, on-device `AIInsightsWidget` to the Dashboard that analyzes Tasks, Meetings, and MRR.
- **Android Widgets Expanded**: Completely modernized Android widget layouts with Material 3 styling. Added two new widgets: "Quick Capture" (shortcuts to add tasks/leads/outreach) and "Target Progress" (MRR tracking).
- **Navigation Links**: Added Tasks and Outreach screens to the main Sidebar drawer.
- **Push Notifications**: Added local push notifications for task deadlines using `flutter_local_notifications`. Notifications are scheduled 15 minutes before the due date.

### Changed
- **UI/UX Flat Overhaul**: Replaced floating shadows, large border radii, and glowing gradients with a flat, structured grid layout mimicking a professional B2B SaaS interface.
- **Android Widget Responsiveness**: Widgets now correctly use `autoSizeTextType="uniform"` and API 12+ responsive attributes (`targetCellWidth`, `targetCellHeight`, `minResizeWidth`, `minResizeHeight`) to prevent text clipping and support dynamic scaling across devices.
- **Email Verification**: Added a persistent Alert Dialog upon sign up to clearly instruct the user to check their email for verification before proceeding.

### Fixed
- **WhatsApp Multiline**: Fixed multiline message truncation on some devices by explicitly encoding WhatsApp deep-link URLs.
- **Background Gradient**: Replaced hard-stop `LinearGradient` with a soft `RadialGradient` in `PremiumBackground` to remove harsh diagonal banding globally.

## 1.1.0+2 — 2026-07-03

### Fixed
- **Workspace isolation**: Data no longer bleeds across workspaces. Each workspace uses a separate Isar database file (`ws_<id>.isar`).
- **Workspace switch**: Switching workspaces now properly stops sync, swaps the Isar DB, invalidates all Riverpod providers, and restarts sync — all in one atomic operation.
- **Workspace join**: Fixed RLS blocking join-by-code. Now uses Supabase RPC (`find_workspace_by_code`) to find a workspace before the user is a member.
- **Workspace list**: Fixed RLS blocking the join query. Now uses Supabase RPC (`get_my_workspaces`) to fetch workspace list reliably.
- **PDF generation**: Fixed "Widget won't fit into page" error on invoice PDFs caused by `CrossAxisAlignment.stretch` in a `MultiPage` layout.
- **PDF blank gray screen**: Fixed blank output on receipts and client briefs caused by `MultiPage` with zero margins.
- **WhatsApp message truncation**: Fixed message being cut at commas and newlines by switching to `Uri.encodeComponent()` for proper URL encoding.
- **Forgot Password**: Button now functional — sends password reset email via Supabase.
- **Sign Out**: Now properly closes Isar DB, clears workspace from SharedPreferences, and navigates to login screen.

### Changed
- **Isar databases**: Separate `.isar` file per workspace (`ws_<workspaceId>.isar`) instead of a single shared `right_craft_media.isar`. Guest mode uses `guest.isar`.
- **All repositories**: Now inject and stamp `workspaceId` on every `create()` call. Provider rebuilds automatically on workspace switch via `currentWorkspaceIdProvider`.
- **Settings service**: Agency name, bank details, QR code path and all other settings are now scoped per workspace using prefixed SharedPreferences keys (`ws_<id>_<key>`).
- **Splash screen**: Reads saved workspace ID and opens the correct Isar DB file on startup.

## 1.0.0+1 — 2026-06-30

### Initial Release
- Complete content agency operating system
- Tasks, Clients, Leads, Transactions, Invoices, Knowledge, Meetings, Journal, Focus, Resources
- Offline-first with Supabase sync
- Team workspaces with role-based access
