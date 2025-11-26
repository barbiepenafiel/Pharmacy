# Implementation Tasks

## 1. Fix Dashboard Tab Stat Cards (3.3px Bottom Overflow)
- [x] 1.1 Identify stat card Column at line 396 causing 3.3px bottom overflow
- [x] 1.2 Reduce vertical padding from 6px to 4px
- [x] 1.3 Reduce font sizes: label 9→8, value 16→15, trend 10→9
- [x] 1.4 Reduce spacing between elements (SizedBox heights: 2→1)
- [x] 1.5 Add mainAxisSize: MainAxisSize.min to Column
- [x] 1.6 Test with hot reload and verify no overflow warnings

## 2. Fix Products Tab Grid Cards
- [x] 2.1 Verify previous fix (image 85→82, padding 6→5, buttons 22→20) is applied
- [x] 2.2 If overflow persists, further reduce image to 78px
- [x] 2.3 Reduce button height from 20→18 if needed
- [x] 2.4 Ensure Expanded wrapper on product info Column
- [x] 2.5 Test grid view scrolling and card rendering

## 3. Fix Inventory Tab Horizontal Overflow (54px, 72px)
- [x] 3.1 Locate Row with search and filter chips causing 54/72px overflow
- [x] 3.2 Wrap filter chips section in Expanded with SingleChildScrollView
- [x] 3.3 Add horizontal scroll direction to filter chips
- [x] 3.4 Ensure search field uses flex: 2, filters use flex: 3 or remaining space
- [x] 3.5 Test filter chip scrolling on narrow screens

## 4. Fix Inventory Tab ListTile Bottom Overflow
- [x] 4.1 Verify current fix (image 48x48, padding vertical:8) is applied
- [x] 4.2 If 3.3px overflow persists, use Container instead of ListTile
- [x] 4.3 Implement custom layout with precise height control
- [x] 4.4 Ensure subtitle Column uses mainAxisSize: MainAxisSize.min
- [x] 4.5 Add maxLines: 1 and overflow: TextOverflow.ellipsis to all text

## 5. Fix Reports Tab Overflow (36px Right Overflow)
- [x] 5.1 Locate Row components in Reports tab causing 36px overflow
- [x] 5.2 Identify period selector buttons and stat card rows
- [x] 5.3 Wrap button rows in SingleChildScrollView or use Flexible
- [x] 5.4 Add responsive sizing to report cards (use Expanded in GridView)
- [x] 5.5 Ensure chart containers have maxWidth constraints

## 6. Fix Type Casting Errors
- [x] 6.1 Search for direct int/String assignments in product data
- [x] 6.2 Add .toString() or proper type conversion for numeric fields
- [x] 6.3 Handle null safety for stock, price, expiresAt fields
- [x] 6.4 Test with sample data from Firebase

## 7. Add Comprehensive Text Overflow Handling
- [x] 7.1 Add maxLines and overflow to all Text widgets in cards
- [x] 7.2 Add Flexible/Expanded to Text widgets inside Row/Column
- [x] 7.3 Test with long product names and descriptions
- [x] 7.4 Verify ellipsis appears correctly

## 8. Implement Responsive Padding System
- [x] 8.1 Define padding constants for mobile (small screens)
- [x] 8.2 Use MediaQuery to detect screen width
- [x] 8.3 Apply conditional padding: 4-6px for mobile, 8-12px for larger
- [x] 8.4 Update all Card and Container padding consistently

## 9. Testing & Validation
- [ ] 9.1 Hot reload and navigate to Dashboard tab
- [ ] 9.2 Navigate to Products tab, scroll through grid
- [ ] 9.3 Navigate to Inventory tab, test search and filters
- [ ] 9.4 Navigate to Reports tab, test period selector
- [ ] 9.5 Check console for any remaining overflow warnings
- [ ] 9.6 Verify no yellow/black striped patterns in UI
- [ ] 9.7 Test on different screen orientations (portrait/landscape)

## 10. Documentation
- [ ] 10.1 Document padding standards in code comments
- [ ] 10.2 Add TODO comments for future responsive improvements
- [ ] 10.3 Update any relevant technical documentation
