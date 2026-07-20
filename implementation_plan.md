# Implementation Plan: Transparent Overlays & Widget Links Fix

This plan covers two major improvements to the Android widgets:
1. Creating a transparent overlay for interactive widgets (like Quick Add) so you don't have to launch the full app.
2. Fixing the broken deep links on the other widgets so tapping them correctly routes you to the exact screen in the app.

## Proposed Changes

### 1. Fix Broken Deep Links (GoRouter)
The current widget links use the format `rcmos://dashboard`. In Flutter's GoRouter, this parses as a blank path and drops you on the splash screen! 
- **Fix**: Update all Kotlin widget providers to use the format `rcmos://app/dashboard` and `rcmos://app/tasks/create` so GoRouter correctly reads the path and routes you to the exact page.

### 2. Transparent Overlay Architecture (Quick Add)
For widgets where you just want to input data (Quick Add), opening the full app is too slow. We will build a completely isolated, transparent overlay.
- **Android Native**: Create `OverlayActivity.kt` with a transparent background theme (`@style/Theme.Transparent`) that explicitly launches a custom Flutter entrypoint.
- **Flutter Entrypoint**: Create `@pragma('vm:entry-point') void overlayMain()` in `main.dart`. This bypasses the heavy splash screen and GoRouter, connecting directly to the local database.
- **Overlay UI**: Implement `QuickAddOverlayScreen` as a floating dialog over a blurred background. 
- **Workflow**: 
  1. Tap widget.
  2. Transparent dialog instantly pops up over Android home screen.
  3. Type task & save.
  4. Dialog closes, saving to database, and the widget is instantly refreshed.

## User Review Required

> [!IMPORTANT]
> Since the Quick Add overlay uses a separate lightweight Flutter instance, it will save data instantly to your local database and close. The data will then automatically sync to Supabase in the background the next time the main app runs.
> 
> Does this transparent overlay flow and the deep link fix sound good to you? Once you approve, I'll build it!
