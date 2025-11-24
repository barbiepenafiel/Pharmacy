# Change: Fix Authentication Security Vulnerabilities

## Why

The current authentication system has **critical security vulnerabilities** that allow unauthorized access even on production/real devices:

1. **Plain-text password storage and comparison** - Passwords are stored and validated without hashing (bcrypt/argon2)
2. **Dummy token generation** - Backend returns `'dummy-token-' + user.id` which is predictable and not cryptographically secure
3. **No token validation** - Tokens are stored in frontend but never sent or validated on subsequent API requests
4. **Missing route guards** - Admin dashboard route (`/admin`) has no authentication/authorization checks
5. **Guest bypass** - "Continue as Guest" allows full app access without authentication
6. **No session management** - Tokens never expire, no refresh mechanism, no invalidation
7. **Missing authorization middleware** - Backend APIs don't verify tokens or user roles

These vulnerabilities allow:
- Any user to access admin dashboard by navigating to `/admin`
- Guests to use the app without any identity verification
- Token prediction and hijacking
- Password theft if database is compromised
- Privilege escalation attacks

## What Changes

### Backend Security (High Priority)
- **ADDED**: Password hashing with bcrypt (install bcrypt package)
- **ADDED**: JWT token generation with secret key (install jsonwebtoken package)
- **ADDED**: Token validation middleware for protected routes
- **ADDED**: Role-based authorization middleware (admin vs customer)
- **ADDED**: Token expiration and refresh mechanism
- **MODIFIED**: Auth API to hash passwords on register and verify hashed passwords on login
- **MODIFIED**: All protected API endpoints to require valid JWT token
- **MODIFIED**: Admin-only endpoints to require admin role validation

### Frontend Security
- **ADDED**: Auth token injection in HTTP headers for all API requests
- **ADDED**: Route guards for protected screens (admin dashboard, orders, prescriptions)
- **ADDED**: Session expiration handling and auto-logout
- **MODIFIED**: Login flow to handle token refresh
- **MODIFIED**: Guest mode restrictions (read-only product browsing, no orders/cart)
- **REMOVED**: Direct navigation to admin dashboard without authentication check

### Migration & Compatibility
- **ADDED**: Migration script to hash existing plain-text passwords
- **ADDED**: Environment variable for JWT secret key
- **ADDED**: Token expiration configuration (default 24 hours)

## Impact

### Affected Specs
- `auth-security` (new capability)

### Affected Code

**Backend**:
- `backend/package.json` - Add bcrypt and jsonwebtoken dependencies
- `backend/.env` - Add JWT_SECRET environment variable
- `backend/src/app/api/auth/route.ts` - Implement password hashing and JWT tokens
- `backend/src/middleware/auth.ts` - NEW: Token validation middleware
- `backend/src/middleware/admin.ts` - NEW: Admin role authorization middleware
- `backend/src/app/api/products/route.ts` - Add admin auth to POST
- `backend/src/app/api/products/[id]/route.ts` - Add admin auth to PUT/DELETE
- `backend/src/app/api/users/**` - Add admin auth
- `backend/src/app/api/orders/**` - Add user auth
- `backend/src/app/api/prescriptions/**` - Add user auth
- `backend/scripts/hash-passwords.ts` - NEW: Migration script

**Frontend**:
- `lib/services/auth_service.dart` - Add token expiration handling and auto-refresh
- `lib/services/http_service.dart` - NEW: Wrapper for HTTP with auth headers
- `lib/main.dart` - Add route guards for protected routes
- `lib/screens/admin_dashboard_screen.dart` - Add authentication check in initState
- All API-calling screens - Use new HTTP service with auth headers

### Breaking Changes
- **BREAKING**: All protected API endpoints now require `Authorization: Bearer <token>` header
- **BREAKING**: Guest users can only browse products (no cart, orders, or profile features)
- **BREAKING**: Existing sessions will be invalidated (users must re-login)
- **BREAKING**: Existing plain-text passwords must be migrated (run migration script)

### User Experience Impact
- **Positive**: Secure authentication prevents unauthorized access
- **Neutral**: Users must re-login after update (session invalidated)
- **Neutral**: Guest mode becomes read-only (must login to purchase)
- **Positive**: Admin dashboard is properly protected
- **Positive**: Token expiration provides better security (auto-logout after 24h)

### Migration Path
1. Add JWT_SECRET to backend .env file
2. Install new dependencies (bcrypt, jsonwebtoken)
3. Run password migration script to hash existing passwords
4. Deploy backend with new authentication
5. Deploy frontend with route guards and token headers
6. Notify users to re-login (sessions invalidated)
