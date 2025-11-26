## 1. Firebase Project Setup
- [x] 1.1 Create Firebase project in Firebase Console ✅ (pharmacy-app-67eab)
- [x] 1.2 Enable Firebase Realtime Database ✅ (asia-southeast1)
- [ ] 1.3 Enable Firebase Authentication (Email/Password) (USER ACTION REQUIRED)
- [ ] 1.4 Download `google-services.json` (Android) and place in android/app/ (USER ACTION REQUIRED)
- [ ] 1.5 Configure Firebase security rules for database access

## 2. Flutter Firebase Integration
- [x] 2.1 Add Firebase dependencies to `pubspec.yaml`
- [x] 2.2 Configure Firebase for Android (`android/app/build.gradle.kts`)
- [ ] 2.3 Configure Firebase for iOS (`ios/Runner/AppDelegate.swift`)
- [x] 2.4 Initialize Firebase in `main.dart`
- [ ] 2.5 Test Firebase connection (blocked on google-services.json)

## 3. Firebase Database Structure Design
- [x] 3.1 Design `/users/{userId}` node structure
- [x] 3.2 Design `/products/{productId}` node structure
- [x] 3.3 Design `/orders/{orderId}` node structure
- [x] 3.4 Design `/prescriptions/{prescriptionId}` node structure
- [x] 3.5 Design `/inventory/{productId}` node structure
- [x] 3.6 Design `/categories/{categoryId}` node structure
- [x] 3.7 Document data duplication strategy for queries

## 4. Firebase Security Rules
- [x] 4.1 Write rules for user data access (own data only)
- [x] 4.2 Write rules for product data (read: all, write: admin only)
- [x] 4.3 Write rules for order data (read/write: owner + admin)
- [x] 4.4 Write rules for prescription data (read/write: owner + admin)
- [x] 4.5 Write rules for inventory data (read: all, write: admin only)
- [ ] 4.6 Test security rules with Firebase Emulator (optional - can test in production)

## 5. Create Firebase Service Layer
- [x] 5.1 Create `lib/services/firebase_service.dart`
- [x] 5.2 Implement database reference helpers
- [x] 5.3 Implement CRUD operations for products
- [x] 5.4 Implement CRUD operations for orders
- [x] 5.5 Implement CRUD operations for prescriptions
- [x] 5.6 Implement real-time listeners for data updates

## 6. Update Authentication Service
- [x] 6.1 Rewrite `lib/services/auth_service.dart` for Firebase Auth
- [x] 6.2 Implement email/password registration
- [x] 6.3 Implement email/password login
- [x] 6.4 Implement logout
- [x] 6.5 Implement auth state listener
- [x] 6.6 Update user profile creation to write to `/users/{userId}`
- [x] 6.7 Remove JWT token handling

## 7. Update AppConfig
- [x] 7.1 Remove backend URL configuration from `lib/config/app_config.dart`
- [x] 7.2 Add Firebase project configuration (apiKey, projectId, etc.)
- [x] 7.3 Remove BackendEnvironment enum (no longer needed)
- [x] 7.4 Remove timeout and retry logic (Firebase handles this)

## 8. Update Product Screens
- [x] 8.1 Update `products_screen.dart` to use Firebase real-time listener
- [x] 8.2 Remove HTTP GET calls, replace with `onValue` stream
- [x] 8.3 Add `watchProductsByCategory()` method to FirebaseService
- [x] 8.4 Update error handling for Firebase-specific errors
- [ ] 8.5 Update product deletion (admin) to use Firebase `remove()`
- [ ] 8.6 Remove retry logic (Firebase handles connection automatically)

## 9. Update Cart and Order Screens
- [x] 9.1 Update `cart_screen.dart` to create orders in Firebase
- [x] 9.2 Update `my_orders_screen.dart` to listen to user's orders
- [x] 9.3 Update `order_tracker_screen.dart` for real-time order status
- [x] 9.4 Remove HTTP POST/GET calls, replace with Firebase operations

## 10. Update Prescription Screens
- [x] 10.1 Update `prescriptions_screen.dart` to use Firebase listener
- [x] 10.2 Update prescription upload to Firebase Storage + Database
- [x] 10.3 Update prescription status updates (admin)

## 11. Update Admin Dashboard
- [x] 11.1 Add Firebase watch methods for admin (watchAllOrders, watchAllPrescriptions, watchAllUsers)
- [ ] 11.2 Update admin_dashboard_screen.dart to use Firebase queries
- [ ] 11.3 Implement real-time sales statistics
- [ ] 11.4 Update user management with Firebase

## 12. Update Remaining Screens
- [ ] 12.1 Update `scanner_screen.dart` to query Firebase by barcode
- [ ] 12.2 Update `help_support_screen.dart` if it has backend calls
- [ ] 12.3 Update `settings_screen.dart` for user profile updates
- [ ] 12.4 Review all screens for remaining HTTP calls

## 13. Data Migration
- [ ] 13.1 Export existing data from PostgreSQL (products, users, orders)
- [ ] 13.2 Transform relational data to Firebase JSON structure
- [ ] 13.3 Write data migration script
- [ ] 13.4 Import data to Firebase Realtime Database
- [ ] 13.5 Verify data integrity after migration

## 14. Remove Backend Code
- [ ] 14.1 Delete `backend/` directory
- [ ] 14.2 Remove backend documentation from main README
- [ ] 14.3 Update documentation to reference Firebase
- [ ] 14.4 Archive backend-related OpenSpec changes

## 15. Testing
- [ ] 15.1 Test user registration and login
- [ ] 15.2 Test product browsing and real-time updates
- [ ] 15.3 Test cart and order creation
- [ ] 15.4 Test prescription upload and tracking
- [ ] 15.5 Test admin dashboard functionality
- [ ] 15.6 Test offline mode (airplane mode)
- [ ] 15.7 Test real-time updates (multiple devices)
- [ ] 15.8 Test security rules (unauthorized access attempts)

## 16. Documentation
- [ ] 16.1 Create Firebase setup guide
- [ ] 16.2 Document Firebase database structure
- [ ] 16.3 Document Firebase security rules
- [ ] 16.4 Update main README with Firebase instructions
- [ ] 16.5 Create Firebase deployment checklist
- [ ] 16.6 Document data migration process
