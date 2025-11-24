# Implementation Tasks

## 1. Backend: Install Security Dependencies
- [x] 1.1 Install bcrypt for password hashing: `npm install bcrypt @types/bcrypt`
- [x] 1.2 Install jsonwebtoken for JWT tokens: `npm install jsonwebtoken @types/jsonwebtoken`
- [x] 1.3 Add JWT_SECRET to `.env` file (generate secure random secret)
- [x] 1.4 Update `package.json` with new dependencies

## 2. Backend: Password Hashing
- [x] 2.1 Update register endpoint to hash passwords with bcrypt (salt rounds: 10)
- [x] 2.2 Update login endpoint to verify hashed passwords with bcrypt.compare()
- [x] 2.3 Create migration script `scripts/hash-passwords.ts` to hash existing plain-text passwords
- [ ] 2.4 Run migration script on database before deployment

## 3. Backend: JWT Token Implementation
- [x] 3.1 Update login endpoint to generate JWT tokens with user id and role
- [x] 3.2 Add token expiration (24 hours default, configurable via env)
- [x] 3.3 Include user id, email, role in JWT payload
- [x] 3.4 Sign tokens with JWT_SECRET from environment

## 4. Backend: Authentication Middleware
- [x] 4.1 Create `src/middleware/auth.ts` middleware to validate JWT tokens
  - [x] 4.1.1 Extract token from Authorization header (Bearer scheme)
  - [x] 4.1.2 Verify token signature with JWT_SECRET
  - [x] 4.1.3 Check token expiration
  - [x] 4.1.4 Attach decoded user to request object
  - [x] 4.1.5 Return 401 Unauthorized if token invalid/missing
- [x] 4.2 Create `src/middleware/admin.ts` middleware to check admin role
  - [x] 4.2.1 Verify user role is 'admin'
  - [x] 4.2.2 Return 403 Forbidden if not admin
- [x] 4.3 Create middleware helper `src/middleware/index.ts` for composing middlewares

## 5. Backend: Protect API Endpoints
- [ ] 5.1 Apply auth middleware to all order endpoints (`/api/orders/**`)
- [ ] 5.2 Apply auth middleware to all prescription endpoints (`/api/prescriptions/**`)
- [ ] 5.3 Apply auth middleware to user profile endpoints (`/api/users/[id]`)
- [x] 5.4 Apply admin middleware to product management endpoints (POST/PUT/DELETE `/api/products/**`)
- [ ] 5.5 Apply admin middleware to user management endpoints (`/api/users/**`)
- [ ] 5.6 Apply admin middleware to inventory management endpoints (`/api/inventory/**`)
- [x] 5.7 Keep product GET endpoints public (allow guest browsing)

## 6. Frontend: HTTP Service with Auth Headers
- [x] 6.1 Create `lib/services/http_service.dart` as wrapper around http package
  - [x] 6.1.1 Automatically inject Authorization header with token
  - [x] 6.1.2 Handle 401 responses (expired token) with auto-logout
  - [x] 6.1.3 Handle 403 responses (insufficient permissions)
  - [x] 6.1.4 Provide methods: get, post, put, delete
- [ ] 6.2 Update AuthService to use HttpService
- [ ] 6.3 Update all screens to use HttpService instead of raw http package

## 7. Frontend: Route Guards
- [x] 7.1 Create route guard function to check authentication before navigation
- [x] 7.2 Wrap `/admin` route with admin-only guard
- [x] 7.3 Wrap `/home` route features requiring auth (orders, prescriptions, profile)
- [x] 7.4 Update main.dart to check auth status on app start
- [x] 7.5 Redirect to login if accessing protected route while unauthenticated

## 8. Frontend: Admin Dashboard Protection
- [x] 8.1 Add authentication check in `AdminDashboardScreen.initState()` (via route guard)
- [x] 8.2 Verify current user is admin role (via route guard)
- [x] 8.3 Redirect to login if not authenticated (via route guard)
- [x] 8.4 Show error and redirect to home if authenticated but not admin (via route guard)

## 9. Frontend: Guest Mode Restrictions
- [x] 9.1 Add isGuest() method to AuthService (implicit: !isLoggedIn())
- [ ] 9.2 Disable cart operations for guests (show "Login to add to cart")
- [ ] 9.3 Disable order placement for guests
- [ ] 9.4 Disable prescription upload for guests
- [ ] 9.5 Show login prompt on protected actions
- [x] 9.6 Allow product browsing for guests (GET endpoints public)

## 10. Frontend: Session Management
- [x] 10.1 Add token expiration check in AuthService
- [x] 10.2 Implement auto-logout when token expires
- [x] 10.3 Show session expired message before logout (via HttpService)
- [ ] 10.4 Add token refresh mechanism (optional: refresh tokens - non-goal)

## 11. Testing & Validation
- [ ] 11.1 Test user registration with password hashing
- [ ] 11.2 Test user login with hashed password verification
- [ ] 11.3 Test JWT token generation and validation
- [ ] 11.4 Test accessing protected endpoints without token (expect 401)
- [ ] 11.5 Test accessing admin endpoints as regular user (expect 403)
- [ ] 11.6 Test accessing admin dashboard as regular user (redirect to login)
- [ ] 11.7 Test guest mode restrictions (cannot add to cart, place orders)
- [ ] 11.8 Test token expiration and auto-logout
- [ ] 11.9 Test migration script on sample data

## 12. Documentation & Deployment
- [ ] 12.1 Document JWT_SECRET generation process
- [ ] 12.2 Update README with new environment variables
- [ ] 12.3 Document authentication flow
- [ ] 12.4 Create deployment checklist (migrate passwords, set JWT_SECRET)
- [ ] 12.5 Add security best practices documentation

## Dependencies
- Tasks 2.x depend on 1.x (dependencies must be installed first)
- Tasks 3.x depend on 1.x (JWT library required)
- Tasks 4.x depend on 3.x (JWT implementation needed for middleware)
- Tasks 5.x depend on 4.x (middleware must exist before applying)
- Tasks 6.x can be implemented in parallel with 4-5.x
- Tasks 7-9.x depend on 6.x (HTTP service must exist)
- Tasks 11.x depend on all implementation tasks
