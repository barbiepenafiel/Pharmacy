# Change: Migrate Backend from Next.js + PostgreSQL to Firebase Realtime Database

## Why

The current Next.js backend with Prisma ORM and Neon PostgreSQL requires:
- Separate backend server deployment and maintenance
- Complex database connection pooling configuration
- Network configuration for device-to-server communication
- Two-tier architecture (Flutter → Next.js → PostgreSQL)

Firebase Realtime Database offers:
- Direct Flutter-to-Firebase communication (no backend server needed)
- Real-time data synchronization
- Automatic scaling and hosting
- Built-in authentication integration
- Simplified deployment (no server to manage)
- Offline data persistence
- Lower operational complexity

## What Changes

**BREAKING CHANGES:**
- **Remove entire Next.js backend** - Delete `backend/` directory
- **Remove RESTful API** - Replace HTTP calls with Firebase SDK
- **Change data structure** - Move from relational (SQL) to hierarchical (JSON)
- **Change authentication** - Replace JWT tokens with Firebase Auth
- **Update all API calls** - Convert REST endpoints to Firebase database references

### Backend Changes
- Remove Next.js API routes (`backend/src/app/api/`)
- Remove Prisma ORM and schema (`backend/prisma/`)
- Remove database connection code (`backend/src/lib/prisma.ts`)
- Remove package.json dependencies (Next.js, Prisma, bcrypt, etc.)
- Delete entire `backend/` directory (no longer needed)

### Flutter Changes
- Add Firebase dependencies (`firebase_core`, `firebase_database`, `firebase_auth`)
- Replace `http` package calls with Firebase SDK
- Update `AuthService` to use Firebase Authentication
- Convert all screen data fetching to Firebase real-time listeners
- Update `AppConfig` to store Firebase project configuration
- Implement Firebase security rules for data access control

### Data Structure Changes
- Convert PostgreSQL tables to Firebase JSON nodes:
  - `users` → `/users/{userId}`
  - `products` → `/products/{productId}`
  - `orders` → `/orders/{orderId}`
  - `prescriptions` → `/prescriptions/{prescriptionId}`
  - `inventory` → `/inventory/{productId}`
  - `categories` → `/categories/{categoryId}`

### Authentication Changes
- Replace JWT-based auth with Firebase Authentication
- Use Firebase email/password authentication
- Store user profiles in `/users/{userId}` node
- Implement Firebase Auth state listeners

## Impact

### Affected Specs
- **backend-api** - Completely removed (breaking)
- **network-config** - Simplified (no backend URL configuration needed)
- **database-connection** - Replaced with Firebase SDK
- **authentication** - Changed from JWT to Firebase Auth
- **data-fetching** - Changed from REST to real-time listeners

### Affected Code
- **Remove:** Entire `backend/` directory (~50 files)
- **Update:** `lib/config/app_config.dart` - Replace backend URLs with Firebase config
- **Update:** `lib/services/auth_service.dart` - Complete rewrite for Firebase Auth
- **Update:** All screen files with API calls (~15 files)
- **Add:** `lib/services/firebase_service.dart` - New Firebase database service
- **Update:** `pubspec.yaml` - Add Firebase dependencies

### Migration Considerations
- Existing database data needs migration from PostgreSQL to Firebase
- Firebase has different query capabilities (no JOIN operations)
- Firebase pricing based on bandwidth and storage (vs PostgreSQL per-instance)
- Real-time listeners use more battery than REST polling
- Offline data persistence requires additional configuration

### Benefits
- **Simplified Architecture:** No backend server to maintain
- **Real-time Updates:** Products, orders, inventory update automatically
- **Offline Support:** Built-in offline data persistence
- **Easier Deployment:** No server configuration, only Flutter app
- **Scalability:** Firebase handles scaling automatically
- **Cost:** Free tier covers development, pay-as-you-grow pricing

### Drawbacks
- **No SQL Queries:** Limited to hierarchical queries, no complex joins
- **Data Duplication:** May need to duplicate data for different access patterns
- **Vendor Lock-in:** Tightly coupled to Firebase/Google Cloud
- **Bandwidth Costs:** Real-time listeners consume more bandwidth
- **Migration Effort:** Complete backend rewrite required

## Recommendation

**Proceed with Firebase migration IF:**
- Primary goal is simplifying deployment and reducing operational complexity
- Real-time features (inventory, order tracking) are valuable
- Database queries are simple (no complex joins/aggregations)
- Scale is small to medium (<10,000 concurrent users)

**Stick with current architecture IF:**
- Complex relational queries are essential
- Vendor lock-in is a concern
- Need full control over database and server logic
- Already have PostgreSQL expertise and infrastructure
- Planning to scale to millions of users (Firebase bandwidth costs)

## Next Steps

1. User confirms intention to proceed with Firebase migration
2. Create Firebase project and obtain configuration
3. Set up Firebase Authentication
4. Design Firebase database structure (JSON tree)
5. Implement Flutter Firebase integration
6. Migrate existing data from PostgreSQL to Firebase
7. Test all features with Firebase backend
8. Remove Next.js backend code
9. Update documentation
