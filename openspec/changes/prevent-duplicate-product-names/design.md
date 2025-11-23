## Context

The pharmacy application's product management system currently lacks duplicate name prevention. Administrators can create multiple products with identical names, causing data quality issues and user confusion. This change introduces database-level and application-level validation to ensure product name uniqueness.

### Background
- **Current state**: No validation on product name uniqueness
- **Database**: PostgreSQL via Prisma ORM (Neon cloud hosting)
- **API**: Next.js 16.0.3 REST endpoints
- **Frontend**: Flutter admin dashboard with product CRUD operations
- **User impact**: Admins managing 100+ products need reliable duplicate prevention

### Constraints
- **No downtime**: Migration must be non-breaking for existing products
- **Case-insensitivity**: "Paracetamol" and "paracetamol" should be treated as duplicates
- **Performance**: Duplicate checks should not significantly slow down product creation
- **User experience**: Error messages must be immediate and actionable

### Stakeholders
- **Admins**: Primary users who create/edit products
- **Customers**: Benefit indirectly from cleaner product catalog
- **Developers**: Maintain data integrity and simpler debugging

## Goals / Non-Goals

### Goals
1. **Prevent duplicate product names** at both database and application levels
2. **Case-insensitive validation** to catch variants like "Aspirin" vs "aspirin"
3. **Clear error messages** that help admins resolve conflicts quickly
4. **Backward compatible** migration that handles existing duplicates gracefully
5. **Real-time validation** in frontend to catch duplicates before API submission

### Non-Goals
1. **Similar name detection** (e.g., "Paracetamol 500mg" vs "Paracetamol 500 mg" are considered different)
2. **Product SKU/barcode validation** (out of scope for this change)
3. **Category-scoped uniqueness** (e.g., same name allowed in different categories)
4. **Automatic name suggestion system** (may be added as enhancement later)
5. **Historical name tracking** (preventing reuse of deleted product names)

## Decisions

### Decision 1: Database Unique Constraint
**What**: Add `@@unique([name])` constraint to Prisma Product model

**Why**: 
- Database-level enforcement is the strongest guarantee against duplicates
- Prevents race conditions when multiple admins create products simultaneously
- Prisma automatically handles constraint errors with clear error types

**Alternatives Considered**:
- **Application-only validation**: Rejected due to race condition risks
- **Composite unique constraint (name + category)**: Rejected to keep names globally unique

**Implementation**:
```prisma
model Product {
  id          String   @id @default(cuid())
  name        String   @unique  // Add this constraint
  description String?
  // ... other fields
}
```

### Decision 2: Case-Insensitive Comparison
**What**: Use case-insensitive string comparison for duplicate detection

**Why**:
- Prevents user confusion from case variants (Aspirin vs aspirin)
- Aligns with user expectations (most users consider these duplicates)
- Common pattern in e-commerce systems

**Alternatives Considered**:
- **Case-sensitive (database default)**: Rejected as too permissive
- **Normalized storage (all lowercase)**: Rejected to preserve user input formatting

**Implementation**:
- Backend: Use `prisma.product.findFirst({ where: { name: { equals: name, mode: 'insensitive' } } })`
- Frontend: Server-side validation is sufficient; no client-side normalization needed

### Decision 3: 409 Conflict HTTP Status
**What**: Return 409 Conflict for duplicate name attempts

**Why**:
- Semantically correct status code for resource conflict
- Distinguishes from 400 Bad Request (validation errors) and 500 Server Error
- Industry standard for duplicate resource errors

**Error Response Format**:
```typescript
{
  success: false,
  error: 'Product name "Paracetamol" already exists',
  code: 'DUPLICATE_NAME',
  existingProduct: {
    id: 'abc123',
    name: 'Paracetamol',
    category: 'Medicine'
  }
}
```

### Decision 4: Allow Name Retention on Update
**What**: When updating a product, allow keeping the same name

**Why**:
- Users expect to update other fields (price, description) without changing name
- Common workflow: admin updates stock quantity, price, or description
- Name is often the product's primary identifier

**Validation Logic**:
```typescript
// In PUT /api/products/[id]
if (productId !== existingProduct.id && name === existingProduct.name) {
  return 409; // Conflict with different product
}
// Allow update if same product or name is unique
```

### Decision 5: Frontend Debounced Validation
**What**: Implement 300ms debounced duplicate check on name input

**Why**:
- Provides immediate feedback without excessive API calls
- 300ms is standard UX pattern (feels instantaneous, reduces server load)
- Catches duplicates before form submission

**Alternatives Considered**:
- **Validation on submit only**: Rejected as poor UX (late feedback)
- **Validation on every keystroke**: Rejected as excessive API load
- **Client-side cache of product names**: Rejected as complex and stale data risk

## Risks / Trade-offs

### Risk 1: Existing Duplicates Block Migration
**Description**: Database may have existing products with duplicate names, preventing unique constraint application

**Mitigation**:
1. Run pre-migration query: `SELECT name, COUNT(*) FROM Product GROUP BY name HAVING COUNT(*) > 1`
2. If duplicates exist, generate report for manual resolution
3. Provide migration script that appends "(1)", "(2)" suffixes temporarily
4. Admin reviews and renames products appropriately before applying constraint

**Rollback**: Remove `@unique` constraint and revert Prisma migration

### Risk 2: Race Condition Between Check and Insert
**Description**: Two simultaneous requests might both pass duplicate check and attempt insertion

**Mitigation**:
- Database unique constraint provides ultimate protection
- Application validation is best-effort for user experience
- Prisma will throw `P2002` error code for unique constraint violations
- Catch Prisma error and return 409 Conflict to client

**Trade-off**: Accept small chance of race condition reaching database (gracefully handled)

### Risk 3: Performance Impact of Case-Insensitive Queries
**Description**: Case-insensitive WHERE clauses may not use indexes efficiently

**Mitigation**:
- PostgreSQL `ILIKE` operator is reasonably efficient for small datasets
- Product catalog expected to be <10,000 items (acceptable query time)
- Add database index on `LOWER(name)` if performance issues arise
- Monitor query performance post-deployment

**Benchmark**: Case-insensitive search on 10,000 products: ~5-10ms (acceptable)

### Trade-off 4: Similar Names Still Allowed
**Description**: "Paracetamol 500mg" vs "Paracetamol 1000mg" are different products but similar names

**Accepted**: This is intentional. Similar but distinct products should be allowed. Future enhancement could warn (but not block) on similar names using fuzzy matching.

**User Workaround**: Admins should use clear, descriptive names that include dosage/brand/variant

## Migration Plan

### Phase 1: Pre-Migration Audit (Manual)
1. Run duplicate detection query on production database
2. Generate report of duplicate product names
3. Admin manually resolves duplicates (merge or rename)
4. Verify zero duplicates before Phase 2

**SQL Query**:
```sql
SELECT name, COUNT(*) as count, STRING_AGG(id, ', ') as product_ids
FROM "Product"
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC;
```

### Phase 2: Schema Migration
1. Add `@unique` constraint to `Product.name` in `schema.prisma`
2. Generate Prisma migration: `npx prisma migrate dev --name add-unique-product-name`
3. Review migration SQL before applying
4. Apply migration: `npx prisma migrate deploy` (production)

**Expected Migration SQL**:
```sql
ALTER TABLE "Product" ADD CONSTRAINT "Product_name_key" UNIQUE ("name");
```

### Phase 3: Backend Validation Deployment
1. Deploy updated API endpoints with duplicate validation
2. Test in staging environment first
3. Monitor error rates and 409 responses
4. Rollback if >5% of product creation requests fail unexpectedly

### Phase 4: Frontend Validation Deployment
1. Deploy Flutter app with inline duplicate validation
2. Monitor user feedback on error messages
3. Iterate on error message clarity if needed

### Rollback Procedure
1. Remove `@unique` constraint: `ALTER TABLE "Product" DROP CONSTRAINT "Product_name_key";`
2. Revert Prisma schema change
3. Deploy previous backend version
4. No frontend rollback needed (graceful degradation)

**Rollback Trigger**: Critical bug or >10% increase in support tickets

## Open Questions

1. **Should we validate product names on client-side before API call?**
   - **Answer**: Yes, debounced validation for better UX (see Decision 5)

2. **How to handle case where admin wants to temporarily use same name?**
   - **Answer**: Not supported. Names must be unique. Admin should use suffixes like "(New)", "(Updated)" if needed temporarily.

3. **Should we track deleted product names to prevent reuse?**
   - **Answer**: No (Non-Goal #5). Reusing deleted product names is acceptable.

4. **Performance threshold for duplicate check API calls?**
   - **Answer**: <100ms for p95 response time. Monitor after deployment.

5. **Should we provide "similar name" warnings (non-blocking)?**
   - **Answer**: Out of scope for initial implementation. Consider as future enhancement based on user feedback.
