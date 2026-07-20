# FounderOS (RCM OS) Project Memory

## Overview
FounderOS (or RCM OS) is a comprehensive Content Agency Operating System built with Flutter.

## Architecture
- **Framework**: Flutter
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter
- **Database (Local)**: Isar (NoSQL)
- **Database (Remote)**: Supabase
- **Sync Mechanism**: A custom SyncEngine (`sync_engine.dart`) pushes local Isar changes to Supabase and pulls remote changes to Isar. `SyncMapper` handles JSON conversions between Isar models and Supabase schemas.
- **Styling**: Material 3, heavily utilizing `Theme.of(context).colorScheme`.

## Key Features & Structure
- **Dashboard**: High-level metrics, MRR progress, tasks, recent leads.
- **Content Hub**: Content calendar and tracking.
- **CRM (Outreach & Leads)**: 
  - Manage Cold Outreach, tracks contacts via multiple platforms (Email, LinkedIn, Instagram, WhatsApp, Cold Call, Door to Door).
  - Outreach items sync to `cold_outreach` table.
- **Finance**: Transactions, revenue, invoices.
- **Settings**: Workspace management, User profile, App preferences (Theme, MRR Target).

## Database Schema (Isar Collections)
- `TaskItem`, `ContentItem`, `LeadItem`, `ClientItem`, `TransactionItem`, `KnowledgeItem`, `MeetingItem`, `JournalItem`, `FocusSession`, `ResourceItem`, `InvoiceItem`, `OutreachItem`.

## Recent Modifications
- Added `contactDetail` to `OutreachItem` to track phone/email/ig/map link for different outreach platforms. (SQL schema `cold_outreach` updated).
- Implemented MRR Target progress tracking on the Dashboard.
- Fixed WhatsApp multi-line sharing bug in `WhatsAppHelper`.
- App Drawer redesigned to display active workspace name from `WorkspaceService`.

## Note for Future Models
- **CHANGELOG RULE**: You MUST explicitly update `CHANGELOG.md` after completing any major or mid-sized updates (new features, major UI redesigns, significant bug fixes).
- When altering schemas, update both the Isar collection class (`lib/services/database/collections/`) and run `dart run build_runner build` to regenerate `.g.dart` files. 
- Ensure `SyncMapper` (`lib/services/sync/sync_mapper.dart`) is updated to serialize/deserialize the new fields correctly for Supabase syncing.
- SQL migrations must be run via Supabase SQL Editor if columns are added.
