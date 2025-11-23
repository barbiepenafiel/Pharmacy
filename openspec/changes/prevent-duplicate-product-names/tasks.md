# Implementation Tasks

## 1. Database Schema Update
- [ ] 1.1 Check existing database for duplicate product names
- [ ] 1.2 Create migration script to resolve existing duplicates (if any)
- [ ] 1.3 Add `@@unique([name])` constraint to Product model in `schema.prisma`
- [ ] 1.4 Generate and apply Prisma migration
- [ ] 1.5 Verify unique constraint is active in database

## 2. Backend API Validation
- [ ] 2.1 Implement duplicate name check in POST `/api/products`
  - [ ] 2.1.1 Query database for existing product with same name (case-insensitive)
  - [ ] 2.1.2 Return 409 Conflict with descriptive error message if duplicate found
  - [ ] 2.1.3 Add error response format: `{ success: false, error: 'Product name already exists', existingProduct: { id, name, category } }`
- [ ] 2.2 Implement duplicate name check in PUT `/api/products/[id]`
  - [ ] 2.2.1 Allow same name if updating the same product (id matches)
  - [ ] 2.2.2 Check for conflicts with other products (case-insensitive)
  - [ ] 2.2.3 Return 409 Conflict if duplicate found with different product
- [ ] 2.3 Handle Prisma unique constraint errors gracefully
- [ ] 2.4 Add unit tests for duplicate validation logic

## 3. Frontend Validation (Admin Dashboard)
- [ ] 3.1 Add real-time duplicate name validation in product form
  - [ ] 3.1.1 Debounce name input field (300ms delay)
  - [ ] 3.1.2 Call backend API to check for duplicates
  - [ ] 3.1.3 Show inline error message below name field if duplicate exists
  - [ ] 3.1.4 Disable "Save" button when duplicate detected
- [ ] 3.2 Handle 409 Conflict responses from backend
  - [ ] 3.2.1 Parse error message from response
  - [ ] 3.2.2 Display user-friendly SnackBar with suggestion: "Product name 'X' already exists. Please choose a different name."
  - [ ] 3.2.3 Keep dialog open so user can correct the name
- [ ] 3.3 Add visual feedback (red border, error text) to name TextField on duplicate
- [ ] 3.4 Clear error state when name is changed

## 4. User Experience Enhancements
- [ ] 4.1 Add suggested alternatives when duplicate detected (optional)
  - [ ] 4.1.1 Example: "Paracetamol 500mg" → suggest "Paracetamol 500mg (Brand X)"
- [ ] 4.2 Update product edit dialog to show current name with note: "Keep same name or choose new unique name"
- [ ] 4.3 Add help text: "Product names must be unique"

## 5. Testing & Validation
- [ ] 5.1 Test creating product with new unique name (should succeed)
- [ ] 5.2 Test creating product with existing name (should fail with 409)
- [ ] 5.3 Test creating product with case-variant of existing name (should fail)
- [ ] 5.4 Test updating product keeping same name (should succeed)
- [ ] 5.5 Test updating product to another product's name (should fail)
- [ ] 5.6 Test updating product to new unique name (should succeed)
- [ ] 5.7 Verify error messages are clear and actionable
- [ ] 5.8 Test edge cases: trailing spaces, special characters, empty strings

## 6. Documentation
- [ ] 6.1 Update API documentation with 409 Conflict response
- [ ] 6.2 Document duplicate name validation rules
- [ ] 6.3 Add troubleshooting guide for duplicate name errors
- [ ] 6.4 Update admin user guide with unique name requirement

## Dependencies
- Tasks 2.x depend on 1.x (schema must be updated first)
- Tasks 3.x can be implemented in parallel with 2.x
- Tasks 5.x depend on all implementation tasks being complete
