# Admin Dashboard Specification Changes

## MODIFIED Requirements

### Requirement: Dashboard Tab Layout
The admin dashboard SHALL display stat cards without layout overflow errors and with proper responsive sizing.

#### Scenario: Stat cards fit within constraints
- **GIVEN** the admin user navigates to the Dashboard tab
- **WHEN** stat cards are rendered (Revenue, Prescriptions, Users, Orders)
- **THEN** no RenderFlex overflow errors appear in the console
- **AND** all card content is fully visible without clipping
- **AND** text displays with appropriate truncation if needed

#### Scenario: Stat cards display trend indicators
- **GIVEN** a stat card has a trend value (e.g., "+12.5%")
- **WHEN** the card is rendered
- **THEN** the trend indicator icon fits within the card bounds
- **AND** the trend text does not cause horizontal overflow
- **AND** the card height accommodates all content with proper spacing

### Requirement: Products Tab Grid Layout
The Products tab SHALL display product cards in a grid without overflow errors.

#### Scenario: Product cards render correctly
- **GIVEN** the admin user navigates to the Products tab
- **WHEN** product cards are displayed in a GridView
- **THEN** each card's image, text, and buttons fit within the card bounds
- **AND** no bottom overflow occurs in the card's Column layout
- **AND** edit and delete buttons are fully visible and clickable

#### Scenario: Product card handles long names
- **GIVEN** a product has a long name (>30 characters)
- **WHEN** the product card is rendered
- **THEN** the product name displays with ellipsis after 2 lines
- **AND** no horizontal overflow occurs
- **AND** the price and buttons remain visible

#### Scenario: Product card images scale appropriately
- **GIVEN** a product card is rendered
- **WHEN** the card has constrained height (from GridView aspect ratio)
- **THEN** the product image height is reduced to fit (78-82px)
- **AND** the image maintains aspect ratio
- **AND** placeholder icons display at appropriate size if image fails to load

### Requirement: Inventory Tab Layout
The Inventory tab SHALL display search, filters, and product list without horizontal or vertical overflow.

#### Scenario: Search and filters fit on one row
- **GIVEN** the admin user navigates to the Inventory tab
- **WHEN** the search bar and filter chips are rendered
- **THEN** the search bar and filters fit within the screen width
- **AND** filter chips scroll horizontally if there are many filters
- **AND** no 54px or 72px right overflow errors appear

#### Scenario: Filter chips scroll horizontally
- **GIVEN** there are 5+ filter chips (All, Low Stock, Expired, By Supplier, etc.)
- **WHEN** the filters exceed available width
- **THEN** the filter chip row scrolls horizontally
- **AND** all filters remain accessible via scrolling
- **AND** no filter chips are cut off or hidden

#### Scenario: Inventory list items fit constraints
- **GIVEN** inventory products are displayed in a ListView
- **WHEN** each product ListTile or Card is rendered
- **THEN** no bottom overflow occurs (including previous 3.3px issue)
- **AND** product image, name, supplier, expiry date, and stock badge fit within bounds
- **AND** text uses ellipsis for overflow handling

### Requirement: Reports Tab Layout
The Reports tab SHALL display period selector, stats, and charts without overflow errors.

#### Scenario: Period selector buttons fit width
- **GIVEN** the admin user navigates to the Reports tab
- **WHEN** period selector buttons are rendered (Today, This Week, This Month)
- **THEN** all buttons fit within the available width
- **AND** no 36px right overflow occurs
- **AND** buttons are evenly spaced or wrapped appropriately

#### Scenario: Report stat cards are responsive
- **GIVEN** the Reports tab displays revenue, prescription, and other stats
- **WHEN** stat cards are rendered in a row or grid
- **THEN** cards scale to fit the available width
- **AND** text within cards uses ellipsis if needed
- **AND** no horizontal overflow occurs

#### Scenario: Charts render within bounds
- **GIVEN** the Reports tab includes a sales trend chart
- **WHEN** the chart container is rendered
- **THEN** the chart width does not exceed screen width
- **AND** the chart height is constrained appropriately
- **AND** chart legends and labels are readable

### Requirement: Text Overflow Handling
All text widgets in the admin dashboard SHALL handle overflow gracefully with ellipsis and maxLines constraints.

#### Scenario: Long text displays ellipsis
- **GIVEN** any Text widget with potentially long content (product names, user emails, etc.)
- **WHEN** the text exceeds available space
- **THEN** the text truncates with an ellipsis (...)
- **AND** the maxLines property is set (1 or 2 as appropriate)
- **AND** overflow property is set to TextOverflow.ellipsis

#### Scenario: Text in Row layouts uses Expanded
- **GIVEN** a Text widget is placed inside a Row with other fixed-width widgets
- **WHEN** the Row is rendered
- **THEN** the Text is wrapped in Expanded or Flexible
- **AND** the Text does not cause horizontal overflow
- **AND** the text remains readable

### Requirement: Type Safety for Firebase Data
All numeric fields from Firebase SHALL be handled with proper type conversion to prevent runtime errors.

#### Scenario: Numeric fields handle int or String types
- **GIVEN** a product or stat has numeric fields (stock, price, expiresAt)
- **WHEN** the data is retrieved from Firebase Realtime Database
- **THEN** the code uses explicit type conversion (.toString() or as int)
- **AND** null values are handled with null coalescing (?? 0)
- **AND** no "type 'int' is not a subtype of type 'String'" errors occur

#### Scenario: Display numeric values safely
- **GIVEN** a numeric value is displayed in a Text widget
- **WHEN** the value might be int or String from Firebase
- **THEN** the code converts it to the expected type before displaying
- **AND** formatting is applied consistently (e.g., currency, percentages)

## ADDED Requirements

### Requirement: Responsive Padding System
The admin dashboard SHALL use consistent, tiered padding values appropriate for mobile screens.

#### Scenario: Card padding uses tight tier
- **GIVEN** a card or container is displayed in a dense layout (grid, list)
- **WHEN** the card is rendered
- **THEN** padding is set to 4-6px (tight tier)
- **AND** content remains readable
- **AND** touch targets are at least 40x40px for buttons

#### Scenario: Page-level containers use spacious tier
- **GIVEN** a page header or main container
- **WHEN** the container is rendered
- **THEN** padding is set to 16-24px (spacious tier)
- **AND** content has breathing room
- **AND** hierarchy is visually clear

#### Scenario: Standard content uses normal tier
- **GIVEN** a standard card or dialog content
- **WHEN** the content is rendered
- **THEN** padding is set to 8-12px (normal tier)
- **AND** balance between density and readability is maintained

### Requirement: Horizontal Scroll Indicators
When content scrolls horizontally, the UI SHALL provide visual cues that scrolling is available through shadow effects or scroll indicators.

#### Scenario: Filter chips show scroll affordance
- **GIVEN** filter chips exceed visible width and scroll horizontally
- **WHEN** the filter section is rendered
- **THEN** the content is wrapped in SingleChildScrollView with horizontal scroll direction
- **AND** users can swipe to see additional filters
- **AND** all filter options remain accessible

#### Scenario: Scrollable content responds to gestures
- **GIVEN** a horizontally scrollable section (filters, buttons)
- **WHEN** the user swipes left or right
- **THEN** the content scrolls smoothly
- **AND** momentum scrolling works naturally
- **AND** scroll position is maintained when navigating away and back

## REMOVED Requirements

None. This change only adds layout fixes and constraints without removing existing functionality.
