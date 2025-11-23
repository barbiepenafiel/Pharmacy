# Change: Fix UI Overflow Issues in Home and Admin Dashboard

## Why
Multiple UI overflow errors occur in the mobile app where content exceeds container bounds:
- Home screen "New Products" section: bottom overflowed by 48 pixels
- Admin dashboard: multiple overflow issues in various sections
- These cause visual rendering errors and poor user experience

The root cause is fixed-height containers (SizedBox) with child content that exceeds available space.

## What Changes
- Adjust product card layout in home screen to fit within allocated height
- Replace fixed-height constraints with flexible layouts where appropriate
- Add proper scrolling or wrapping for overflow-prone sections
- Fix similar issues across admin dashboard screens

## Impact
- Affected specs: `ui-layout` (new capability)
- Affected code:
  - `lib/main.dart:709-850` (HomeScreen _buildProductCard widget)
  - `lib/screens/admin_dashboard_screen.dart` (multiple sections with fixed heights)
- User-facing: Eliminates rendering errors and improves visual consistency
- No breaking changes to functionality or data structures
