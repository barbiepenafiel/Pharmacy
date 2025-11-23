# Product Management Specification

## ADDED Requirements

### Requirement: Unique Product Names
The system SHALL enforce unique product names across all products in the database.

#### Scenario: Create product with unique name
- **GIVEN** no existing product with name "Aspirin 500mg"
- **WHEN** admin creates a product with name "Aspirin 500mg"
- **THEN** the product is successfully created and saved to database

#### Scenario: Reject duplicate product name on creation
- **GIVEN** existing product with name "Paracetamol"
- **WHEN** admin attempts to create another product with name "Paracetamol"
- **THEN** the system returns 409 Conflict status
- **AND** displays error message "Product name 'Paracetamol' already exists"
- **AND** the product is not created

#### Scenario: Case-insensitive duplicate detection
- **GIVEN** existing product with name "Ibuprofen"
- **WHEN** admin attempts to create product with name "ibuprofen" (lowercase)
- **THEN** the system returns 409 Conflict status
- **AND** displays error message indicating the name already exists
- **AND** the product is not created

#### Scenario: Update product keeping same name
- **GIVEN** product with id "abc123" and name "Vitamin C"
- **WHEN** admin updates product "abc123" changing price but keeping name "Vitamin C"
- **THEN** the update succeeds
- **AND** the product retains the name "Vitamin C"

#### Scenario: Reject updating to another product's name
- **GIVEN** product A with name "Aspirin" and product B with name "Paracetamol"
- **WHEN** admin attempts to update product A's name to "Paracetamol"
- **THEN** the system returns 409 Conflict status
- **AND** displays error message indicating "Paracetamol" is already in use
- **AND** product A's name remains "Aspirin"

### Requirement: Database Unique Constraint
The database schema SHALL include a unique constraint on the Product.name field to prevent duplicate names at the data layer.

#### Scenario: Database enforces uniqueness
- **GIVEN** the Product table has a unique constraint on the name column
- **WHEN** a database insert or update operation attempts to create a duplicate name
- **THEN** the database rejects the operation with a unique constraint violation error
- **AND** the application handles this error gracefully

#### Scenario: Concurrent creation attempts
- **GIVEN** two simultaneous API requests to create products with the same name "Antacid"
- **WHEN** both requests pass application-level validation simultaneously
- **THEN** the database unique constraint allows only one to succeed
- **AND** the failed request receives a 409 Conflict response
- **AND** no duplicate product names exist in the database

### Requirement: Real-time Frontend Validation
The admin dashboard product form SHALL provide immediate feedback when a duplicate product name is entered.

#### Scenario: Inline duplicate name validation
- **GIVEN** admin is creating/editing a product in the admin dashboard
- **WHEN** admin types a product name that already exists
- **THEN** an error message appears below the name input field within 500ms
- **AND** the error message states "This product name already exists"
- **AND** the "Save" button is disabled

#### Scenario: Clear error state on name change
- **GIVEN** duplicate name error is displayed
- **WHEN** admin modifies the product name to a unique value
- **THEN** the error message disappears
- **AND** the "Save" button becomes enabled

#### Scenario: Debounced validation reduces API calls
- **GIVEN** admin is typing a product name character by character
- **WHEN** admin types "P-a-r-a-c-e-t-a-m-o-l" in rapid succession
- **THEN** the system waits 300ms after the last keystroke before validating
- **AND** only one validation API call is made (not 12 calls for 12 characters)

### Requirement: Informative Error Messages
The system SHALL provide clear, actionable error messages when duplicate product names are detected.

#### Scenario: Detailed 409 error response
- **GIVEN** duplicate product name "Aspirin" is detected
- **WHEN** the API returns an error response
- **THEN** the response includes status code 409
- **AND** the response body contains:
  - `success: false`
  - `error: "Product name 'Aspirin' already exists"`
  - `code: "DUPLICATE_NAME"`
  - `existingProduct: { id, name, category }` (details of conflicting product)

#### Scenario: User-friendly frontend error message
- **GIVEN** duplicate name error received from API
- **WHEN** the error is displayed to the admin user
- **THEN** a SnackBar appears with message "Product name 'Aspirin' already exists. Please choose a different name."
- **AND** the message is displayed for 5 seconds
- **AND** the product form dialog remains open for correction

### Requirement: Migration Safety
The system SHALL handle existing duplicate product names gracefully during schema migration.

#### Scenario: Pre-migration duplicate detection
- **GIVEN** the database contains products with duplicate names before migration
- **WHEN** the migration script is prepared for execution
- **THEN** a pre-migration check query identifies all duplicate names
- **AND** a report is generated listing product IDs and names of duplicates
- **AND** the migration does not proceed until duplicates are resolved

#### Scenario: Manual duplicate resolution
- **GIVEN** duplicate products "Paracetamol" with IDs "id1" and "id2"
- **WHEN** admin reviews the duplicate report
- **THEN** admin can choose to:
  - Rename one product (e.g., "Paracetamol (Brand A)")
  - Delete one product if it's truly redundant
  - Merge products if they represent the same item
- **AND** after resolution, the migration can proceed safely

## API Specification

### POST /api/products

**Request Body**:
```json
{
  "name": "Aspirin 500mg",
  "description": "Pain reliever",
  "dosage": "500mg",
  "category": "Medicine",
  "price": "5.99",
  "quantity": "100",
  "supplier": "PharmaCorp",
  "imageUrl": "https://example.com/aspirin.jpg"
}
```

**Success Response (201)**:
```json
{
  "success": true,
  "data": {
    "id": "abc123",
    "name": "Aspirin 500mg",
    "description": "Pain reliever",
    "dosage": "500mg",
    "category": "Medicine",
    "price": 5.99,
    "quantity": 100,
    "supplier": "PharmaCorp",
    "imageUrl": "https://example.com/aspirin.jpg",
    "createdAt": "2025-11-24T10:00:00Z",
    "updatedAt": "2025-11-24T10:00:00Z"
  }
}
```

**Duplicate Name Error (409)**:
```json
{
  "success": false,
  "error": "Product name 'Aspirin 500mg' already exists",
  "code": "DUPLICATE_NAME",
  "existingProduct": {
    "id": "xyz789",
    "name": "Aspirin 500mg",
    "category": "Medicine"
  }
}
```

### PUT /api/products/[id]

**Request Body**:
```json
{
  "name": "Aspirin 500mg",
  "description": "Updated description",
  "price": "6.99"
}
```

**Success Response (200)**:
```json
{
  "success": true,
  "data": {
    "id": "abc123",
    "name": "Aspirin 500mg",
    "description": "Updated description",
    "price": 6.99,
    "updatedAt": "2025-11-24T11:00:00Z"
  }
}
```

**Duplicate Name Error (409)**:
```json
{
  "success": false,
  "error": "Product name 'Paracetamol' is already used by another product",
  "code": "DUPLICATE_NAME",
  "existingProduct": {
    "id": "different123",
    "name": "Paracetamol",
    "category": "Medicine"
  }
}
```

## Database Schema

### Prisma Model Update

```prisma
model Product {
  id          String   @id @default(cuid())
  name        String   @unique  // ← NEW: Unique constraint added
  description String?
  dosage      String?
  category    String
  price       Float
  imageUrl    String?
  quantity    Int      @default(0)
  supplier    String?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

## Validation Rules

1. **Name Required**: Product name must not be empty or null
2. **Name Uniqueness**: Product name must be unique (case-insensitive)
3. **Name Length**: Minimum 2 characters, maximum 200 characters (recommended)
4. **Update Exception**: When updating a product, the product can keep its existing name
5. **Trimming**: Leading and trailing whitespace should be trimmed before validation
6. **Case Handling**: "Aspirin", "aspirin", "ASPIRIN" are all considered the same name

## Error Handling

### Frontend Error Display
- **Inline Error**: Red text below name TextField
- **SnackBar**: Top-level notification with dismiss action
- **Button State**: Disable "Save" button when duplicate detected
- **Visual Cue**: Red border on TextField with duplicate name

### Backend Error Response
- **Status Code**: 409 Conflict
- **Error Format**: JSON with `success`, `error`, `code`, and `existingProduct` fields
- **Prisma Error Handling**: Catch `P2002` (unique constraint violation) and convert to 409 response
- **Logging**: Log duplicate attempts for analytics (track common duplicate names)

## Non-Functional Requirements

### Performance
- Duplicate name check SHALL complete in <100ms (p95)
- Frontend debounce SHALL be 300ms after last keystroke
- Database query SHALL use indexed column for efficient lookup

### Usability
- Error messages SHALL be clear and suggest next action
- Validation feedback SHALL appear within 500ms of user input
- Form SHALL remain open after error to allow correction

### Reliability
- Database constraint SHALL be the ultimate source of truth
- Application validation SHALL be defense-in-depth
- Race conditions SHALL be handled gracefully by database constraint

### Maintainability
- Validation logic SHALL be centralized in backend
- Error codes SHALL be consistent (use "DUPLICATE_NAME" constant)
- Test coverage SHALL include all duplicate scenarios
