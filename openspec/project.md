# Project Context

## Purpose
A modern online pharmacy mobile application built with Flutter that allows customers to:
- Browse and purchase medicines and healthcare products
- Upload prescriptions for medication orders
- Manage orders, addresses, and payment methods
- Access product categories (Medicine, Diabetes, Skin Care, Bandages)
- View promotional offers and new products

The app includes an admin dashboard for inventory management, order processing, and prescription approvals.

## Project Structure

### Flutter App (`/`)
```
lib/
├── main.dart                    # App entry point, routing, navigation
├── config/
│   └── app_config.dart         # Backend URL and app-wide configuration
├── models/
│   └── user.dart               # Data models
├── services/
│   ├── auth_service.dart       # Authentication (singleton)
│   ├── cart_service.dart       # Shopping cart (singleton)
│   └── http_service.dart       # HTTP client wrapper
└── screens/
    ├── login_screen.dart       # User authentication
    ├── home_screen.dart        # Main landing page
    ├── products_screen.dart    # Product catalog
    ├── cart_screen.dart        # Shopping cart
    ├── order_tracker_screen.dart    # Order status
    ├── prescriptions_screen.dart    # Prescription uploads
    ├── admin_dashboard_screen.dart  # Admin panel
    └── ...                     # Other screens

assets/
└── images/                     # Local image assets

test/
└── widget_test.dart            # Widget tests
```

### Backend (`/backend`)
```
backend/
├── src/
│   ├── app/
│   │   └── api/                # API route handlers
│   │       ├── auth/           # Authentication endpoints
│   │       ├── products/       # Product CRUD
│   │       ├── orders/         # Order management
│   │       ├── prescriptions/  # Prescription handling
│   │       └── users/          # User management
│   ├── generated/
│   │   └── prisma/             # Generated Prisma client
│   ├── lib/
│   │   └── prisma.ts           # Prisma singleton, seeding
│   └── middleware/
│       └── auth.ts             # Auth & authorization middleware
├── prisma/
│   ├── schema.prisma           # Database schema
│   └── migrations/             # Database migrations
├── .env                        # Environment variables (gitignored)
├── package.json                # Dependencies and scripts
├── tsconfig.json               # TypeScript configuration
└── next.config.ts              # Next.js configuration
```

### OpenSpec (`/openspec`)
```
openspec/
├── project.md                  # This file - project context
├── AGENTS.md                   # AI assistant instructions
├── specs/                      # Current specifications (empty for now)
└── changes/                    # Change proposals
    ├── fix-product-fetching-and-connectivity/  # Active proposal
    │   ├── proposal.md         # Change description
    │   ├── tasks.md            # Implementation tasks
    │   ├── design.md           # Technical decisions
    │   └── specs/              # Spec deltas
    │       ├── product-api/
    │       └── network-config/
    └── archive/                # Completed changes
```

## Tech Stack

### Frontend (Mobile App)
- **Flutter** ^3.9.2 - Cross-platform mobile framework (iOS & Android)
- **Dart** ^3.9.2 - Programming language
- **Material Design 3** - UI/UX design system
- **Cupertino Icons** ^1.0.8 - iOS-style icons
- **HTTP** ^1.1.0 - API communication
- **Image Picker** ^1.0.0 - Prescription/image uploads
- **MIME** ^1.0.0 - File type handling

### Backend (API Server)
- **Next.js** 16.0.3 - React-based API framework (App Router)
- **TypeScript** ^5 - Type-safe JavaScript (strict mode)
- **Prisma** ^6.19.0 - ORM for database management
  - Custom output path: `src/generated/prisma`
  - Client generation with type safety
- **PostgreSQL (Neon)** - Cloud-hosted serverless database
  - Connection pooling via `DATABASE_URL`
  - Direct URL for migrations via `DIRECT_DATABASE_URL`
  - SSL mode required with channel binding
- **React** 19.2.0 - UI components (admin dashboard)
- **Tailwind CSS** ^4 - Styling framework (PostCSS v4)
- **bcrypt** ^6.0.0 - Password hashing
- **jsonwebtoken** ^9.0.2 - JWT authentication tokens

### Database Schema (Prisma)
- **User** - Authentication and user profiles
  - Fields: id (cuid), email (unique), password (hashed), name, role (customer/admin)
  - Relations: addresses, paymentMethods, prescriptions, orders
- **Product** - Medicine and healthcare product catalog
  - Fields: id, name (unique), description, dosage, category, price, imageUrl, quantity, supplier
  - Created/updated timestamps
- **Order** - Purchase transactions
  - Fields: id, userId, prescriptionId (optional), total, status, deliveryAddress, paymentMethod
  - Relations: user, prescription, orderItems
  - Status flow: pending → processing → shipped → delivered/cancelled
- **OrderItem** - Line items in orders
  - Fields: id, orderId, productId, productName, price, quantity
- **Prescription** - Customer prescription uploads
  - Fields: id, userId, doctorName, medication, dosage, instructions, status
  - Status: pending → approved/rejected
  - Relations: user, orders
- **Inventory** - Stock management system
  - Fields: id, name, dosage, quantity, supplier, expiryDate, status
  - Status: in_stock, low_stock, expired
- **Address** - Delivery addresses
  - Fields: id, userId, street, city, state, zip, country, isDefault
- **PaymentMethod** - Stored payment options
  - Fields: id, userId, type, details (encrypted/masked)

## Project Conventions

### Code Style

#### Flutter/Dart
- Use `const` constructors wherever possible for performance
- Follow Flutter's official style guide and linting rules (`flutter_lints: ^5.0.0`)
  - Configured in `analysis_options.yaml`
- Use snake_case for file names (e.g., `login_screen.dart`)
- Use PascalCase for class names (e.g., `LoginScreen`)
- Use camelCase for variables and methods
- Prefer `final` over `var` when values don't change
- Use named parameters for optional arguments with clear labels
- Keep widget files organized by screen/feature in `lib/screens/`
- Services in `lib/services/` (e.g., `auth_service.dart`, `cart_service.dart`)
- Models in `lib/models/` (e.g., `user.dart`)
- Configuration in `lib/config/` (e.g., `app_config.dart`)
- Prefer `StatelessWidget` for static UI, `StatefulWidget` only when local state needed
- Use `ScaffoldMessenger` for snackbar notifications
- Implement proper error handling with try-catch blocks
- Always include `key` parameter in constructors for reusable widgets

#### TypeScript/Next.js
- Use TypeScript for all backend code (strict mode enabled in `tsconfig.json`)
- ESLint configuration with Next.js recommended rules (`eslint.config.mjs`)
- Use async/await over promises for asynchronous operations
- Prefer explicit return types on functions for type safety
- Use path aliases (`@/*` for `./src/*`) defined in `tsconfig.json`
- API routes in `src/app/api/` following Next.js App Router conventions
- Database access exclusively through Prisma ORM
- Import Prisma client from `@/lib/prisma` (singleton instance)
- Use middleware pattern for authentication (`auth()`) and authorization (`admin()`)
- Consistent error response format: `{ success: boolean, data?: any, error?: string, code?: string }`
- Always log errors to console with context
- Use HTTP status codes appropriately:
  - 200: Success with data
  - 201: Created
  - 400: Bad request (missing/invalid input)
  - 401: Unauthorized (missing/invalid token)
  - 403: Forbidden (insufficient permissions)
  - 404: Not found
  - 409: Conflict (e.g., duplicate entries)
  - 500: Internal server error
- Environment variables stored in `.env` file (never commit to git)

### Architecture Patterns

#### Mobile App (Flutter)
- **Singleton Services**: `AuthService` and `CartService` use singleton pattern for global state
  - Factory constructors ensure single instance
  - In-memory state management (no persistent storage currently)
- **StatefulWidget vs StatelessWidget**: Use StatefulWidget for screens with local state, StatelessWidget for static content
- **Screen-based navigation**: Named routes defined in `MaterialApp`
- **Bottom navigation**: Tab-based navigation with 4 main sections (Home, Store, Tracker, Account)
- **In-memory state**: Current user and auth token stored in memory (no persistent storage yet)
- **HTTP Communication**:
  - Base URL configuration in `AppConfig.backendBaseUrl`
  - Fallback to `AuthService.baseUrl` for backward compatibility
  - Timeout: 5-10 seconds depending on endpoint
  - Headers: `Content-Type: application/json`, `Accept: application/json`
  - Token passed via `Authorization: Bearer <token>` (when implemented)
- **Error Handling**:
  - Try-catch blocks around all async operations
  - User-friendly error messages displayed via SnackBar
  - Network errors handled gracefully with retry suggestions
  - FormatException for invalid JSON responses

#### Backend (Next.js)
- **API Routes**: RESTful endpoints under `/api/*`
  - `/api/auth` - Login and registration (POST with action parameter)
  - `/api/products` - Product CRUD operations
  - `/api/products/[id]` - Single product operations (GET, PUT, DELETE)
  - `/api/orders` - Order management
  - `/api/prescriptions` - Prescription handling
  - `/api/users` - User management (admin only)
- **Prisma ORM**: Database access layer with type-safe queries
  - Singleton instance in `src/lib/prisma.ts`
  - Auto-seeding on startup in development mode
  - Custom client output path: `src/generated/prisma`
- **Action-based routing**: Some endpoints use action parameter (e.g., `/api/auth?action=login`)
- **Auto-seeding**: Database seeded with sample data on first run
  - Admin user: `admin@pharmacy.com` / `admin123`
  - Sample customers, products, orders, inventory
- **Middleware Pattern**:
  - `auth(handler)` - Validates JWT token, attaches user to request
  - `admin(handler)` - Ensures user has admin role
  - Composable: `POST = auth(admin(handler))`
- **Error handling**: Consistent error responses with status codes and messages
  - All endpoints return `{ success: boolean, data?: any, error?: string }`
  - Errors logged to console with full stack trace
- **Server Configuration**:
  - Dev server runs on `0.0.0.0:3000` (all interfaces)
  - Script: `next dev -H 0.0.0.0`
  - Accessible from external devices on same network

### Testing Strategy
- **Widget Tests**: Located in `test/` directory
  - Basic widget test template in `test/widget_test.dart`
- **Flutter Test**: Use `flutter test` command
- Run tests before major commits
- Test user flows (login, product browsing, cart operations)
- **Backend testing**: Currently manual API testing
  - Future: Add automated API tests with Jest/Vitest
  - Future: Add integration tests with Prisma
- **Database Testing**: Use separate test database or in-memory SQLite
- **API Testing Tools**: Postman, Thunder Client, or curl for manual testing

### Git Workflow
- **Main branch**: `main` (production-ready code)
- **Repository**: GitHub (Owner: barbiepenafiel, Repo: Pharmacy)
- Commit frequently with descriptive messages
  - Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, etc.
- Test app functionality before pushing
- Use feature branches for major changes
  - Branch naming: `feature/<feature-name>`, `fix/<issue-name>`
- **OpenSpec Integration**:
  - Create proposals in `openspec/changes/<change-id>/` before major features
  - Archive completed changes to `openspec/changes/archive/`
  - Update specs in `openspec/specs/` after implementation

## Domain Context

### Healthcare E-Commerce
- **Prescription Handling**: Customers can upload prescriptions that require admin approval
- **Product Categories**: Medicine, Diabetes supplies, Skin Care, Bandages/First Aid
- **Inventory Management**: Track stock levels, expiry dates, and supplier information
- **Order Fulfillment**: Order lifecycle (pending → shipped → delivered/cancelled)
- **User Roles**: 
  - **Customer**: Browse products, place orders, upload prescriptions
  - **Admin**: Manage inventory, approve prescriptions, process orders

### Business Rules
- Prescription orders require approval before fulfillment
- Products have dosage information (for medicines)
- Inventory tracks expiry dates for medication safety
- Multiple addresses and payment methods per user
- Default address selection for quick checkout

## Important Constraints

### Technical Constraints
- Mobile app must work on both iOS and Android (Flutter cross-platform)
- **Backend URL Configuration**:
  - Development: Local network IP (e.g., `http://192.168.1.20:3000`)
  - Android emulator: Use `http://10.0.2.2:3000` for localhost
  - Physical devices: Use local network IP or ngrok tunnel
  - Production: Cloud hosted URL (Vercel, Railway, etc.)
  - Configured in `lib/config/app_config.dart`
- **Database Connection**:
  - Neon PostgreSQL requires SSL (`sslmode=require`)
  - Channel binding required for security
  - Connection pooling via `DATABASE_URL`
  - Direct URL for migrations via `DIRECT_DATABASE_URL`
- API request timeout: 5-10 seconds (configurable per endpoint)
- Asset images stored locally in `assets/images/` (bundled with app)
- **Build System**:
  - Flutter SDK: ^3.9.2
  - Dart SDK: ^3.9.2
  - Node.js: LTS version (v18+)
  - Package managers: npm (backend), pub (Flutter)
- **Platform-specific**:
  - Android: Min SDK 21, Target SDK 34
  - iOS: Deployment target 12.0+

### Security Constraints
- **Password Security**:
  - Passwords hashed with bcrypt (backend responsibility)
  - Min 6 characters (enforced on both frontend and backend)
  - Never log or expose passwords in responses
- **Authentication**:
  - JWT tokens for session management
  - Tokens stored in memory only (no persistent storage currently)
  - Token expiration: 24 hours
  - Future: Implement refresh tokens
- **Network Security**:
  - HTTPS required for production deployment
  - Local development uses HTTP (acceptable for testing)
  - SSL/TLS for database connections
- **Data Privacy**:
  - Payment method details should be encrypted/masked
  - Prescription data contains sensitive medical information (HIPAA considerations)
  - User emails and personal info protected
- **Authorization**:
  - Role-based access control (customer vs admin)
  - Admin endpoints protected by middleware
  - Validate user permissions on every protected endpoint

### Business Constraints
- Admin approval required for prescription orders
- Inventory must track expiry dates for compliance
- Order status tracking required for customer transparency
- Multiple payment methods supported (card, PayPal, etc.)

## External Dependencies

### Database
- **Neon PostgreSQL**: Cloud-hosted serverless PostgreSQL database
  - Provider: Neon (https://neon.tech)
  - Region: ap-southeast-1 (Asia Pacific - Singapore)
  - Connection pooler enabled
- **Connection Configuration**:
  - `DATABASE_URL` - Pooled connection for application queries
  - `DIRECT_DATABASE_URL` - Direct connection for migrations (optional)
  - Connection string format: `postgresql://user:pass@host/db?sslmode=require&channel_binding=require`
  - Stored in `backend/.env` file (never commit to git)
- **SSL/TLS Requirements**:
  - `sslmode=require` - Enforces SSL connection
  - `channel_binding=require` - Additional security layer
- **Prisma Configuration**:
  - Schema: `backend/prisma/schema.prisma`
  - Migrations: `backend/prisma/migrations/`
  - Client output: `backend/src/generated/prisma`
  - Commands:
    - `npx prisma generate` - Generate client
    - `npx prisma db push` - Push schema changes
    - `npx prisma studio` - Open database GUI
    - `npx prisma migrate dev` - Create migration

### Flutter Assets
- Local image assets in `assets/images/`:
  - `Logo.png` (app logo)
  - `medicine.jpg`, `Diabetes.jpg`, `SkinCare.jpg`, `Bandage.jpg` (category images)

### Development Tools
- **Code Editors**:
  - VS Code (primary) - Extensions: Flutter, Dart, ESLint, Prisma
  - Android Studio - For Android development and emulation
  - Xcode - For iOS development (macOS only)
- **Flutter Tools**:
  - Flutter DevTools - Performance profiling and debugging
  - `flutter doctor` - Check development environment setup
  - `flutter pub get` - Install dependencies
  - `flutter run` - Run app on device/emulator
  - `flutter build apk/ios` - Build production app
- **Backend Tools**:
  - Node.js & npm - JavaScript runtime and package manager
  - Prisma Studio - Database GUI (`npx prisma studio`)
  - Postman/Thunder Client - API testing
- **Database Tools**:
  - Neon Console - Web-based database management
  - Prisma Studio - Local database GUI
  - psql - PostgreSQL command-line client (optional)
- **Version Control**:
  - Git - Version control system
  - GitHub Desktop (optional) - GUI for Git operations
- **OpenSpec**:
  - CLI tool for spec-driven development
  - Installed globally: `npm install -g openspec`
  - Commands: `openspec list`, `openspec validate`, `openspec show`

### Network Requirements
- **Backend Server Accessibility**:
  - Development: Runs on `0.0.0.0:3000` (all network interfaces)
  - Accessible from devices on same local network
  - Port 3000 (or 3001 if 3000 is occupied)
- **Mobile Device Connection Options**:
  - **Web browser**: `localhost:3000` or `127.0.0.1:3000`
  - **Android emulator**: `10.0.2.2:3000` (special emulator localhost)
  - **iOS simulator**: `localhost:3000` (uses host machine network)
  - **Physical device (same WiFi)**: Local IP address (e.g., `192.168.1.20:3000`)
  - **Physical device (different network)**: Ngrok tunnel or cloud deployment
- **Finding Local IP Address**:
  - Windows: `ipconfig` (look for IPv4 Address)
  - macOS/Linux: `ifconfig` or `ip addr`
  - Scripts provided: `find-ip.bat` (Windows), `find-ip.sh` (Unix)
- **Ngrok Tunnel** (for external access):
  - Install: `npm install -g ngrok`
  - Run: `ngrok http 3000`
  - Use HTTPS URL in `AppConfig.backendBaseUrl`
- **CORS Considerations**:
  - Currently not implemented (may need for web deployment)
  - Add CORS middleware if deploying to different domains

## Common Development Workflows

### Starting the Application
1. **Backend**:
   ```bash
   cd backend
   npm install           # First time only
   npx prisma generate   # After schema changes
   npm run dev           # Start server on 0.0.0.0:3000
   ```

2. **Flutter App**:
   ```bash
   flutter pub get       # First time or after pubspec.yaml changes
   flutter run           # Run on connected device/emulator
   ```

### Database Management
- **View Data**: `npx prisma studio` (opens GUI at localhost:5555)
- **Reset Database**: `npx prisma db push --force-reset` (deletes all data!)
- **Generate Client**: `npx prisma generate` (after schema changes)
- **Create Migration**: `npx prisma migrate dev --name <migration_name>`

### Making Changes
1. **Update Backend API**: Edit files in `backend/src/app/api/`
2. **Update Database Schema**: Edit `backend/prisma/schema.prisma`, then run `npx prisma generate`
3. **Update Flutter UI**: Edit files in `lib/screens/`
4. **Add Service Logic**: Edit files in `lib/services/`
5. **Update Configuration**: Edit `lib/config/app_config.dart`

### Troubleshooting
- **Backend won't start**: Check if port 3000 is in use, verify `.env` file exists
- **App can't connect**: Verify backend URL in `AppConfig`, check firewall settings
- **Database errors**: Verify `DATABASE_URL` in `.env`, check Neon dashboard
- **Flutter build errors**: Run `flutter clean && flutter pub get`
- **Prisma errors**: Run `npx prisma generate` to regenerate client

## Known Issues & Future Enhancements

### Current Known Issues
1. **Database Connectivity**: Products not fetching from Neon database reliably
   - Status: Active proposal `fix-product-fetching-and-connectivity`
   - Issue: SSL/connection pooling configuration needs optimization
2. **Backend Accessibility**: Backend only accessible during VS Code debug sessions
   - Status: Active proposal `fix-product-fetching-and-connectivity`
   - Issue: Device connectivity when not physically connected
3. **Hardcoded URLs**: IP addresses hardcoded in multiple files
   - Status: Active proposal `fix-product-fetching-and-connectivity`
   - Need: Centralized configuration with environment switching

### Planned Enhancements
- **Authentication**: JWT token-based auth (partially implemented)
- **Persistent Storage**: Save user session and cart data locally
- **Offline Mode**: Cache product data for offline browsing
- **Push Notifications**: Order status updates and prescription approvals
- **Payment Integration**: Stripe/PayPal payment processing
- **Image Upload**: Prescription and product image upload to cloud storage
- **Search & Filtering**: Advanced product search with filters
- **Order History**: Detailed order tracking with status timeline
- **Admin Analytics**: Dashboard with sales reports and inventory insights
- **Testing**: Comprehensive unit and integration tests
- **CI/CD**: Automated testing and deployment pipeline
- **Production Deployment**: 
  - Backend: Vercel, Railway, or AWS
  - Database: Production Neon instance
  - App: Google Play Store and Apple App Store

### Technical Debt
- Remove demo/offline mode from `AuthService` (currently unused)
- Implement proper token refresh mechanism
- Add input validation on all form fields
- Implement proper error boundaries in Flutter
- Add API rate limiting and request throttling
- Implement comprehensive logging and monitoring
- Add database connection pooling optimizations
- Standardize error response formats across all endpoints
- Add TypeScript types for all API responses
