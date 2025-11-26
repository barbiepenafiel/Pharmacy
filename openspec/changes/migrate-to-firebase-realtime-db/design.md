# Design: Firebase Realtime Database Migration

## Context

Migrating from a three-tier architecture (Flutter → Next.js API → PostgreSQL) to a two-tier architecture (Flutter → Firebase Realtime Database). This eliminates the need for a backend server while providing real-time data synchronization.

### Current Architecture
```
Flutter App (Mobile)
    ↓ HTTP REST
Next.js API Server
    ↓ Prisma ORM
Neon PostgreSQL Database
```

### Target Architecture
```
Flutter App (Mobile)
    ↓ Firebase SDK
Firebase Realtime Database (Cloud)
```

## Goals

- **Eliminate backend server** - Remove Next.js deployment and maintenance
- **Real-time sync** - Automatic UI updates when data changes
- **Offline support** - Built-in offline data persistence
- **Simplified deployment** - Only Flutter app needs deployment
- **Reduce complexity** - Direct database access from Flutter

## Non-Goals

- **Complex queries** - Firebase doesn't support SQL joins/aggregations
- **Relational integrity** - No foreign key constraints (handle in app logic)
- **Full-text search** - Limited search capabilities (consider Algolia if needed)
- **Data migration automation** - Manual migration acceptable for first version

## Decisions

### Decision 1: Firebase Realtime Database vs Firestore

**Choice:** Firebase Realtime Database

**Rationale:**
- Simpler data model (single JSON tree)
- Lower latency for small datasets
- Easier real-time listeners
- Lower cost for read-heavy workloads
- Sufficient for pharmacy app scale

**Alternatives Considered:**
- **Firestore:** Better for complex queries, document-based, higher costs
- **Keep PostgreSQL with GraphQL:** Still requires backend server maintenance

### Decision 2: Data Structure Design

**Choice:** Denormalized, query-optimized structure

**Structure:**
```json
{
  "users": {
    "userId1": {
      "email": "user@example.com",
      "name": "John Doe",
      "role": "customer",
      "createdAt": 1234567890
    }
  },
  "products": {
    "productId1": {
      "name": "Aspirin",
      "description": "Pain reliever",
      "price": 9.99,
      "category": "medicine",
      "stock": 100,
      "barcode": "123456789",
      "imageUrl": "https://..."
    }
  },
  "orders": {
    "orderId1": {
      "userId": "userId1",
      "userName": "John Doe",  // Denormalized for display
      "items": {
        "productId1": {
          "name": "Aspirin",  // Denormalized
          "quantity": 2,
          "price": 9.99
        }
      },
      "total": 19.98,
      "status": "pending",
      "createdAt": 1234567890
    }
  },
  "prescriptions": {
    "prescriptionId1": {
      "userId": "userId1",
      "imageUrl": "gs://bucket/prescriptions/prescriptionId1.jpg",
      "status": "pending",
      "notes": "",
      "createdAt": 1234567890
    }
  },
  "categories": {
    "categoryId1": {
      "name": "Medicine",
      "icon": "medical_services"
    }
  },
  "userOrders": {
    // Index for efficient user order queries
    "userId1": {
      "orderId1": true,
      "orderId2": true
    }
  },
  "productsByCategory": {
    // Index for category browsing
    "medicine": {
      "productId1": true,
      "productId2": true
    }
  }
}
```

**Rationale:**
- Denormalize data for read efficiency (e.g., store userName in orders)
- Use separate index nodes for common queries (userOrders, productsByCategory)
- Accept data duplication to avoid complex queries
- Use shallow queries to avoid downloading entire trees

**Trade-offs:**
- **Pro:** Fast reads, no joins needed
- **Con:** Data duplication increases write complexity
- **Con:** Manual consistency management (update in multiple places)

### Decision 3: Authentication Strategy

**Choice:** Firebase Authentication with Email/Password

**Implementation:**
```dart
// Login
final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Store user profile in database
await FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}').set({
  'email': email,
  'name': name,
  'role': 'customer',
  'createdAt': ServerValue.timestamp,
});
```

**Rationale:**
- Firebase Auth handles password hashing, token management
- Integrates seamlessly with Firebase Database security rules
- No JWT token management needed
- Built-in email verification

**Alternatives Considered:**
- **Custom auth server:** More complexity, defeats purpose of simplification

### Decision 4: Security Rules Strategy

**Choice:** Role-based access control via Firebase Security Rules

**Example Rules:**
```javascript
{
  "rules": {
    "users": {
      "$userId": {
        // Users can read/write their own data
        ".read": "auth.uid === $userId",
        ".write": "auth.uid === $userId"
      }
    },
    "products": {
      // Anyone can read products
      ".read": true,
      // Only admins can write
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
    },
    "orders": {
      "$orderId": {
        // User can read their own orders, admins can read all
        ".read": "data.child('userId').val() === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        // User can create orders, admins can update status
        ".write": "!data.exists() && newData.child('userId').val() === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    }
  }
}
```

**Rationale:**
- Server-side security enforcement (can't be bypassed)
- No backend API needed for authorization
- Centralized access control logic

### Decision 5: Real-time Listener Strategy

**Choice:** Use `onValue` streams for real-time updates

**Implementation:**
```dart
// In products_screen.dart
StreamSubscription? _productsSubscription;

void initState() {
  super.initState();
  _productsSubscription = FirebaseDatabase.instance
    .ref('products')
    .onValue
    .listen((event) {
      final data = event.snapshot.value as Map?;
      setState(() {
        _products = _parseProducts(data);
      });
    });
}

void dispose() {
  _productsSubscription?.cancel();
  super.dispose();
}
```

**Rationale:**
- Automatic UI updates when data changes
- No polling needed
- Firebase handles reconnection automatically

**Trade-offs:**
- **Pro:** Real-time updates, better UX
- **Con:** Higher battery usage than REST
- **Mitigation:** Cancel listeners when screens not visible

### Decision 6: Offline Data Persistence

**Choice:** Enable Firebase offline persistence globally

**Implementation:**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable offline persistence
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB
  
  runApp(MyApp());
}
```

**Rationale:**
- App works without internet connection
- Automatic sync when connection restored
- Better user experience in poor network

## Migration Plan

### Phase 1: Setup (Week 1)
1. Create Firebase project
2. Configure Flutter for Firebase
3. Set up Firebase Authentication
4. Design database structure
5. Write security rules

### Phase 2: Parallel Implementation (Week 2-3)
1. Implement Firebase service layer
2. Update one screen at a time (products → orders → prescriptions)
3. Keep Next.js backend running during transition
4. Test Firebase integration alongside existing backend

### Phase 3: Data Migration (Week 4)
1. Export data from PostgreSQL
2. Transform to Firebase JSON format
3. Import to Firebase
4. Verify data integrity

### Phase 4: Cutover (Week 4)
1. Switch all screens to Firebase
2. Test thoroughly
3. Delete backend code
4. Update documentation

### Rollback Plan
- Keep PostgreSQL backup for 30 days
- Keep backend code in Git history
- Can revert Flutter changes via Git if issues arise
- Firebase data can be exported to JSON for migration back if needed

## Risks & Trade-offs

### Risk 1: Complex Queries Not Supported
**Impact:** Admin dashboard analytics may be limited

**Mitigation:**
- Precompute statistics and store in database
- Use Cloud Functions to aggregate data on writes
- Consider BigQuery export for complex analytics

### Risk 2: Data Duplication Complexity
**Impact:** Updates require multiple writes, risk of inconsistency

**Mitigation:**
- Use Firebase Transactions for atomic multi-location updates
- Implement data validation in security rules
- Add consistency checks in admin dashboard

### Risk 3: Bandwidth Costs
**Impact:** Real-time listeners may increase Firebase costs

**Mitigation:**
- Use shallow queries (`shallow=true`)
- Limit listener scope (only listen to needed data)
- Monitor Firebase usage dashboard
- Set budget alerts

### Risk 4: Vendor Lock-in
**Impact:** Difficult to migrate away from Firebase later

**Mitigation:**
- Abstract Firebase calls in service layer
- Document data structure clearly
- Firebase data is exportable as JSON
- Keep PostgreSQL backup initially

### Risk 5: Learning Curve
**Impact:** Team needs to learn Firebase patterns

**Mitigation:**
- Comprehensive documentation
- Firebase has excellent tutorials
- Similar to existing real-time systems

## Open Questions

1. **Image Storage:** Should we use Firebase Storage for prescription images?
   - **Answer:** Yes, Firebase Storage integrates well with Realtime Database

2. **Admin Analytics:** How to handle complex analytics queries?
   - **Answer:** Use Cloud Functions to precompute daily/weekly stats

3. **Search:** How to implement product search?
   - **Answer:** Start with client-side filtering, consider Algolia if needed

4. **Notifications:** How to send order status notifications?
   - **Answer:** Use Firebase Cloud Messaging with Cloud Functions triggers

5. **Payment Integration:** Does Firebase work with payment gateways?
   - **Answer:** Yes, integrate Stripe/PayPal in Flutter, store transaction IDs in Firebase

## Success Criteria

- ✅ No backend server to deploy or maintain
- ✅ Real-time updates working (product stock, order status)
- ✅ Offline mode functional (can browse products offline)
- ✅ All existing features working (products, orders, prescriptions, admin)
- ✅ Security rules prevent unauthorized access
- ✅ Data migrated successfully from PostgreSQL
- ✅ Performance acceptable (<2s for screen loads)
- ✅ Firebase costs within budget (<$25/month for development)

## References

- [Firebase Realtime Database Documentation](https://firebase.google.com/docs/database)
- [Firebase Security Rules Guide](https://firebase.google.com/docs/database/security)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Pricing](https://firebase.google.com/pricing)
