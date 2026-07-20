# Project Quirks & Debug Log

This file tracks recurring issues, edge cases, and known bugs that have been solved. Before attempting to debug an issue, check this list to see if it's a known quirk.

## 1. WhatsApp Multiline Truncation
- **Issue**: Using the native `whatsapp://send?text=...` URI scheme truncates multiline messages (newlines) on many Android devices.
- **Solution**: ALWAYS use the web link `https://wa.me/{phone}?text={encoded}` combined with `Uri.encodeComponent()`. This successfully preserves the `%0A` newlines. (See `whatsapp_helper.dart`).

## 2. Gradient Banding in Premium Background
- **Issue**: Using a `LinearGradient` with hard stops `[0.0, 0.5, 1.0]` across the entire `PremiumBackground` causes harsh diagonal banding.
- **Solution**: Use a smooth `RadialGradient` with a large radius (e.g., `1.8`) to create a softer, more blended effect.

## 3. Workspace Syncing 
- **Issue**: Data bleeding across workspaces.
- **Solution**: Workspaces must remain isolated at the database level. Each workspace gets its own `.isar` file (e.g., `ws_{id}.isar`). When switching workspaces, you must manually stop the `SyncEngine`, switch the Isar instance, invalidate Riverpod providers, and restart sync.
