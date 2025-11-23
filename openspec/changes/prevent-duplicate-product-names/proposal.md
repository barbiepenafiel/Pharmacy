# Change: Prevent Duplicate Product Names

## Why

Currently, the product management system allows administrators to create or update products with identical names, leading to:
- **Data inconsistency**: Multiple products with the same name but different prices, categories, or descriptions
- **User confusion**: Customers unable to distinguish between duplicate entries
- **Inventory management issues**: Difficulty tracking stock for products with the same name
- **Data quality degradation**: Accumulation of redundant or conflicting product records

The system needs validation to ensure product names are unique across the database, both when creating new products and updating existing ones.

## What Changes

- **ADDED**: Unique constraint on product name field in database schema
- **ADDED**: Backend validation to check for duplicate product names before create/update operations
- **ADDED**: Frontend validation to provide immediate feedback when duplicate names are entered
- **ADDED**: Case-insensitive duplicate detection (e.g., "Paracetamol" = "paracetamol")
- **ADDED**: User-friendly error messages explaining duplicate name conflicts
- **MODIFIED**: Product creation API to return 409 Conflict status for duplicate names
- **MODIFIED**: Product update API to allow same name only when updating the same product
- **MODIFIED**: Admin dashboard product form to show inline validation errors

## Impact

### Affected Specs
- `product-management` (new capability)

### Affected Code
- **Database Schema**: `backend/prisma/schema.prisma` (add unique constraint to Product.name)
- **Backend API**: 
  - `backend/src/app/api/products/route.ts` (POST validation)
  - `backend/src/app/api/products/[id]/route.ts` (PUT validation)
- **Frontend**: 
  - `lib/screens/admin_dashboard_screen.dart` (ProductsTab validation, lines ~541-1527)

### Breaking Changes
None. This is an additive constraint that improves data quality without breaking existing functionality.

### Migration Considerations
- Existing duplicate product names in the database may prevent migration
- Need to identify and resolve any existing duplicates before applying schema change
- Suggest migration script to append "(1)", "(2)" suffixes to duplicates temporarily

### User Experience Impact
- **Positive**: Prevents confusion from duplicate entries, ensures data integrity
- **Neutral**: Admins must choose unique names (slight friction, but necessary)
- **Error handling**: Clear, actionable error messages guide admins to resolve conflicts
