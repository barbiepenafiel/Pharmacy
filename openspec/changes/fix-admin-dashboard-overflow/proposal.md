# Change: Fix Admin Dashboard Layout Overflow Errors

## Why
The admin dashboard displays multiple RenderFlex overflow errors across all tabs (Products, Inventory, Reports), making the UI unprofessional and generating console warnings. The errors include:
- **3.3 pixels bottom overflow** in Products tab grid cards (line 396)
- **54 pixels right overflow** in stat cards or action buttons
- **72 pixels right overflow** in filter chips or search bars
- **36 pixels right overflow** in various Row components
- Additional type cast errors (`'int' is not a subtype of type 'String'`)

These layout issues prevent proper rendering and create visual glitches (yellow/black striped patterns in debug mode).

## What Changes
- Fix Products tab grid cards to eliminate 3.3px bottom overflow
- Fix Inventory tab ListTile and filter chip layouts to prevent horizontal overflow
- Fix Reports tab stat cards and charts to handle constrained widths properly
- Add proper Expanded/Flexible widgets to all Row components with dynamic content
- Implement responsive padding/sizing based on available space
- Add text overflow handling (ellipsis, maxLines) to all long text fields
- Fix type casting errors in data handling (int vs String for numeric values)
- Ensure all tabs use professional, consistent spacing and sizing
- Add SingleChildScrollView wrappers where horizontal content may overflow

## Impact
- **Affected specs**: admin-dashboard
- **Affected code**: 
  - `lib/screens/admin_dashboard_screen.dart` (Products, Inventory, Reports tabs)
  - Stat card widgets (line 396, Dashboard tab)
  - Filter chip implementations (lines 3175-3238 in Inventory)
  - Product grid cards (lines 1120-1250 in Products)
  - Report cards and charts (lines 3400-3680 in Reports)
- **Breaking changes**: None (layout fixes only)
- **Testing**: Hot reload verification on Samsung device (RF8Y40MNCDK)
