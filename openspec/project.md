# Project Context

## Purpose
A modern online pharmacy mobile application built with Flutter that allows customers to:
- Browse and purchase medicines and healthcare products
- Upload prescriptions for medication orders
- Manage orders, addresses, and payment methods
- Access product categories (Medicine, Diabetes, Skin Care, Bandages)
- View promotional offers and new products

The app includes an admin dashboard for inventory management, order processing, and prescription approvals.

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
- **Next.js** 16.0.3 - React-based API framework
- **TypeScript** ^5 - Type-safe JavaScript
- **Prisma** ^6.19.0 - ORM for database management
- **PostgreSQL (Neon)** - Cloud-hosted database
- **React** 19.2.0 - UI components (admin dashboard)
- **Tailwind CSS** ^4 - Styling framework

### Database Schema
- Users (authentication, roles: customer/admin)
- Products (medicines, healthcare items)
- Orders (purchase history, status tracking)
- Prescriptions (doctor info, medication, approval workflow)
- Inventory (stock management, expiry dates)
- Addresses (delivery locations)
- Payment Methods (stored payment options)

## Project Conventions

### Code Style

#### Flutter/Dart
- Use `const` constructors wherever possible for performance
- Follow Flutter's official style guide and linting rules (`flutter_lints: ^5.0.0`)
- Use snake_case for file names (e.g., `login_screen.dart`)
- Use PascalCase for class names (e.g., `LoginScreen`)
- Use camelCase for variables and methods
- Prefer `final` over `var` when values don't change
- Use named parameters for optional arguments
- Keep widget files organized by screen/feature in `lib/screens/`
- Services in `lib/services/` (e.g., `auth_service.dart`, `cart_service.dart`)
- Models in `lib/models/`

#### TypeScript/Next.js
- Use TypeScript for all backend code (strict mode enabled)
- ESLint configuration with Next.js recommended rules
- Use async/await over promises
- Prefer explicit return types on functions
- Use path aliases (`@/*` for `./src/*`)
- API routes in `src/app/api/` following Next.js App Router conventions

### Architecture Patterns

#### Mobile App (Flutter)
- **Singleton Services**: `AuthService` and `CartService` use singleton pattern for global state
- **StatefulWidget vs StatelessWidget**: Use StatefulWidget for screens with local state, StatelessWidget for static content
- **Screen-based navigation**: Named routes defined in `MaterialApp`
- **Bottom navigation**: Tab-based navigation with 4 main sections (Home, Store, Tracker, Account)
- **In-memory state**: Current user and auth token stored in memory (no persistent storage yet)

#### Backend (Next.js)
- **API Routes**: RESTful endpoints under `/api/*`
- **Prisma ORM**: Database access layer with type-safe queries
- **Action-based routing**: Single endpoint with action parameter (e.g., `/api/auth?action=login`)
- **Auto-seeding**: Database seeded with sample data on first run
- **Error handling**: Consistent error responses with status codes and messages

### Testing Strategy
- **Widget Tests**: Located in `test/` directory
- **Flutter Test**: Use `flutter test` command
- Run tests before major commits
- Test user flows (login, product browsing, cart operations)
- Backend testing: Manual API testing (future: add automated API tests)

### Git Workflow
- **Main branch**: `main` (production-ready code)
- **Repository**: GitHub (Owner: barbiepenafiel)
- Commit frequently with descriptive messages
- Test app functionality before pushing
- Use feature branches for major changes

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
- Mobile app must work on both iOS and Android
- Backend hosted locally during development (`http://192.168.1.7:3000`)
- Database connection requires SSL (`sslmode=require`)
- 10-second timeout for API requests from mobile app
- Asset images stored locally in `assets/images/`

### Security Constraints
- Passwords must be hashed (backend responsibility)
- Auth tokens stored in memory only (no persistent storage)
- HTTPS required for production
- Payment method details should be encrypted/masked
- Prescription data contains sensitive medical information

### Business Constraints
- Admin approval required for prescription orders
- Inventory must track expiry dates for compliance
- Order status tracking required for customer transparency
- Multiple payment methods supported (card, PayPal, etc.)

## External Dependencies

### Database
- **Neon PostgreSQL**: Cloud-hosted PostgreSQL database
- Connection string in `.env` file (backend)
- SSL/TLS required for secure connections
- Channel binding required

### Flutter Assets
- Local image assets in `assets/images/`:
  - `Logo.png` (app logo)
  - `medicine.jpg`, `Diabetes.jpg`, `SkinCare.jpg`, `Bandage.jpg` (category images)

### Development Tools
- **Android Studio / Xcode**: For mobile app development
- **VS Code**: Primary code editor
- **Flutter DevTools**: Performance and debugging
- **Prisma Studio**: Database GUI (optional)

### Network Requirements
- Backend server must be accessible from mobile device/emulator
- Use `localhost` for web, `192.168.1.7` for Android emulator
- Port 3000 (or 3001 if 3000 is occupied)
