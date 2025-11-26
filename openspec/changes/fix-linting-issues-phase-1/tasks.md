# Tasks: Linting Fixes - Phase 1

## Preparation
- [x] Audit linting issues (82 total)
- [x] Categorize by type and complexity
- [x] Create proposal and design documents
- [ ] Get approval before implementation

## Phase 1A: Deprecation Fixes

### Task 1: Fix `.withOpacity()` in main.dart
**File:** `lib/main.dart`  
**Lines:** 1730, 2003, 2048, 2051  
**Work:** Replace `.withOpacity(X)` with `.withValues(alpha: X)`  
**Verification:** Build & visual check of home screen  
**Effort:** 5 minutes

### Task 2: Fix `.withOpacity()` in admin_dashboard_screen.dart
**File:** `lib/screens/admin_dashboard_screen.dart`  
**Lines:** 3625  
**Work:** Replace `.withOpacity(X)` with `.withValues(alpha: X)`  
**Verification:** Build & admin dashboard renders correctly  
**Effort:** 2 minutes

### Task 3: Fix `.withOpacity()` in order_tracker_screen.dart
**File:** `lib/screens/order_tracker_screen.dart`  
**Lines:** 499, 537  
**Work:** Replace `.withOpacity(X)` with `.withValues(alpha: X)`  
**Verification:** Build & order tracking map displays correctly  
**Effort:** 2 minutes

### Task 4: Fix `.withOpacity()` in prescriptions_screen.dart
**File:** `lib/screens/prescriptions_screen.dart`  
**Lines:** 398  
**Work:** Replace `.withOpacity(X)` with `.withValues(alpha: X)`  
**Verification:** Build & prescriptions screen renders  
**Effort:** 2 minutes

**Total Phase 1A:** 11 minutes ✅

## Phase 1B: Field Finality

### Task 5: Make fields final in order_tracker_screen.dart
**File:** `lib/screens/order_tracker_screen.dart`  
**Lines:** 38, 39  
**Work:** Add `final` keyword to `_markers` and `_polylines` fields  
**Verification:** Build & compile check  
**Effort:** 2 minutes

**Total Phase 1B:** 2 minutes ✅

## Phase 1C: Documentation

### Task 6: Fix HTML in doc comment
**File:** `lib/services/firebase_service.dart`  
**Lines:** 348  
**Work:** Escape angle brackets in doc comment or use backticks  
**Verification:** `flutter analyze` check  
**Effort:** 1 minute

**Total Phase 1C:** 1 minute ✅

## Phase 1D: Dependencies

### Task 7: Add http dependency to pubspec.yaml
**File:** `pubspec.yaml`  
**Work:** Add `http: ^1.1.0` to dependencies section  
**Verification:** `flutter pub get` succeeds  
**Effort:** 2 minutes

**Total Phase 1D:** 2 minutes ✅

## Validation

### Task 8: Run full lint check
**Command:** `flutter analyze`  
**Expected:** Phase 1 issues eliminated  
**Effort:** 2 minutes

### Task 9: Build and run tests
**Command:** `flutter test` and `flutter run`  
**Expected:** All tests pass, app runs without errors  
**Effort:** 5 minutes

**Total Validation:** 7 minutes ✅

---

## Summary

| Phase | Task Count | Total Time | Status |
|-------|-----------|-----------|--------|
| 1A: Deprecations | 4 | 11 min | ⏳ Not started |
| 1B: Fields | 1 | 2 min | ⏳ Not started |
| 1C: Docs | 1 | 1 min | ⏳ Not started |
| 1D: Dependencies | 1 | 2 min | ⏳ Not started |
| Validation | 2 | 7 min | ⏳ Not started |
| **TOTAL** | **9** | **23 min** | ⏳ Not started |

## Parallelization

**Can run in parallel:**
- Tasks 1-4 (different files)
- Task 5 (independent)
- Task 6 (independent)
- Task 7 (independent)

**Must run sequentially:**
- Tasks 1-7 before validation (Task 8-9)

## Dependencies

None between tasks. All changes are independent.

## Rollback

Each task can be individually reverted using:
```bash
git checkout -- <file>
```

Or entire phase:
```bash
git checkout openspec/changes/fix-linting-issues-phase-1/
```

## Success Criteria

- [ ] All 9 tasks completed
- [ ] No new linting issues introduced
- [ ] All existing tests pass
- [ ] App builds and runs successfully
- [ ] No visual regressions in UI
