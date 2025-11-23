# Prevent Duplicate Product Names - Proposal Summary

## 📋 Overview

This OpenSpec change proposal establishes a comprehensive system to prevent duplicate product names in your pharmacy application. The proposal has been validated and is ready for your review and approval.

## 🎯 Problem Being Solved

Currently, administrators can create multiple products with the same name (e.g., two different "Paracetamol" entries), which causes:
- Data inconsistency (same name, different prices/details)
- Customer confusion when browsing products
- Inventory management difficulties
- Overall data quality degradation

## ✅ Proposal Status

**Status**: ✅ VALIDATED (Ready for Review & Approval)

**Validation**: Passed strict OpenSpec validation with no errors

**Change ID**: `prevent-duplicate-product-names`

## 📁 Files Created

```
openspec/changes/prevent-duplicate-product-names/
├── proposal.md           # Why this change is needed and what changes
├── tasks.md              # Step-by-step implementation checklist (33 tasks)
├── design.md             # Technical decisions and architecture
└── specs/
    └── product-management/
        └── spec.md       # Detailed requirements with scenarios
```

## 🔑 Key Features

### 1. **Database Protection**
- Adds unique constraint on Product.name in PostgreSQL
- Prevents duplicates even with race conditions
- Case-insensitive matching ("Aspirin" = "aspirin")

### 2. **Backend Validation**
- POST `/api/products`: Returns 409 Conflict for duplicate names
- PUT `/api/products/[id]`: Allows keeping same name when updating
- Clear error messages with conflicting product details

### 3. **Frontend Validation**
- Real-time duplicate checking (300ms debounced)
- Inline error message below name TextField
- Disabled "Save" button when duplicate detected
- Visual feedback (red border, error text)

### 4. **Migration Safety**
- Pre-migration script to detect existing duplicates
- Manual resolution process before applying constraint
- Graceful handling of edge cases

## 📊 Requirements Summary

The proposal defines **6 main requirements** with **14 scenarios**:

1. **Unique Product Names** (5 scenarios)
   - Create with unique name ✓
   - Reject duplicate on creation ✗
   - Case-insensitive detection ✗
   - Update keeping same name ✓
   - Reject updating to another's name ✗

2. **Database Unique Constraint** (2 scenarios)
   - Database enforces uniqueness
   - Concurrent creation handling

3. **Real-time Frontend Validation** (3 scenarios)
   - Inline validation feedback
   - Clear error on name change
   - Debounced API calls

4. **Informative Error Messages** (2 scenarios)
   - Detailed 409 response format
   - User-friendly SnackBar messages

5. **Migration Safety** (2 scenarios)
   - Pre-migration duplicate detection
   - Manual duplicate resolution process

## 🛠️ Implementation Plan

The proposal includes **33 detailed tasks** organized in **6 phases**:

### Phase 1: Database Schema (5 tasks)
- Check for existing duplicates
- Add unique constraint to Prisma schema
- Generate and apply migration

### Phase 2: Backend API (8 tasks)
- Validate POST /api/products
- Validate PUT /api/products/[id]
- Handle Prisma constraint errors
- Add unit tests

### Phase 3: Frontend (8 tasks)
- Add debounced duplicate checking
- Show inline error messages
- Disable save button on duplicate
- Handle 409 responses gracefully

### Phase 4: UX Enhancements (3 tasks)
- Suggested alternatives (optional)
- Help text and guidance
- Clear error messaging

### Phase 5: Testing (8 tasks)
- Test all creation scenarios
- Test all update scenarios
- Verify error messages
- Edge case testing

### Phase 6: Documentation (4 tasks)
- API documentation updates
- Validation rules documentation
- Troubleshooting guide
- Admin user guide

## 🔍 Technical Decisions

### Key Design Choices:

1. **Database Unique Constraint**: Strongest guarantee against duplicates
2. **Case-Insensitive**: "Paracetamol" = "paracetamol" = "PARACETAMOL"
3. **409 Conflict Status**: Standard HTTP status for duplicate resources
4. **Allow Name Retention**: Can update other fields without changing name
5. **300ms Debounce**: Balance between UX responsiveness and API load

### Error Response Format:
```json
{
  "success": false,
  "error": "Product name 'Aspirin' already exists",
  "code": "DUPLICATE_NAME",
  "existingProduct": {
    "id": "xyz789",
    "name": "Aspirin",
    "category": "Medicine"
  }
}
```

## 📝 API Changes

### POST /api/products
- **New Response**: 409 Conflict for duplicate names
- **Error Body**: Includes existing product details
- **Validation**: Case-insensitive name check before insert

### PUT /api/products/[id]
- **New Response**: 409 Conflict if name conflicts with other product
- **Exception**: Same product can keep its name
- **Validation**: Check if name belongs to different product

## 🗂️ Affected Files

### Backend
- `backend/prisma/schema.prisma` - Add @unique constraint
- `backend/src/app/api/products/route.ts` - POST validation
- `backend/src/app/api/products/[id]/route.ts` - PUT validation

### Frontend
- `lib/screens/admin_dashboard_screen.dart` - ProductsTab (lines ~541-1527)
  - Add debounced name validation
  - Show inline error messages
  - Handle 409 responses

## ⚠️ Risks & Mitigation

### Risk 1: Existing Duplicates
**Issue**: Current database may have duplicate names
**Mitigation**: Pre-migration query + manual resolution script

### Risk 2: Race Conditions
**Issue**: Simultaneous creation with same name
**Mitigation**: Database constraint is final arbiter

### Risk 3: Performance
**Issue**: Case-insensitive queries may be slow
**Mitigation**: Monitor performance; add index if needed (<10ms expected)

## 🚀 Migration Strategy

### Step 1: Pre-Migration Audit
```sql
SELECT name, COUNT(*) as count, STRING_AGG(id, ', ') as product_ids
FROM "Product"
GROUP BY name
HAVING COUNT(*) > 1;
```

### Step 2: Manual Resolution
- Rename one product (add brand/variant suffix)
- Delete if truly redundant
- Merge if same item

### Step 3: Apply Schema Change
```bash
npx prisma migrate dev --name add-unique-product-name
npx prisma migrate deploy
```

### Step 4: Deploy Code
- Backend API validation
- Frontend duplicate checking
- Monitor error rates

### Rollback Plan
```sql
ALTER TABLE "Product" DROP CONSTRAINT "Product_name_key";
```

## ✨ User Experience

### Before Implementation:
- ❌ Can create "Paracetamol" multiple times
- ❌ Confusion for customers and admins
- ❌ Data integrity issues

### After Implementation:
- ✅ Real-time duplicate detection (300ms)
- ✅ Clear error: "Product name 'Paracetamol' already exists. Please choose a different name."
- ✅ Save button disabled until name is unique
- ✅ Database prevents all duplicates

## 📖 Next Steps

1. **Review this proposal** and the detailed specs
2. **Ask questions** or request clarifications
3. **Approve the proposal** to proceed with implementation
4. **Implementation begins** only after approval (per OpenSpec stage 2)

## 📄 View Full Documentation

- **Proposal**: `openspec/changes/prevent-duplicate-product-names/proposal.md`
- **Tasks**: `openspec/changes/prevent-duplicate-product-names/tasks.md`
- **Design**: `openspec/changes/prevent-duplicate-product-names/design.md`
- **Spec**: `openspec/changes/prevent-duplicate-product-names/specs/product-management/spec.md`

## 🔧 OpenSpec Commands

```bash
# View this change
openspec show prevent-duplicate-product-names

# Validate (already passed)
openspec validate prevent-duplicate-product-names --strict

# List all changes
openspec list

# View detailed spec
openspec show product-management --type spec
```

---

**Ready for your review!** 🎉

This proposal provides a complete, validated solution to prevent duplicate product names in your pharmacy application. All requirements are clearly defined with scenarios, implementation is broken into manageable tasks, and migration risks are addressed.
