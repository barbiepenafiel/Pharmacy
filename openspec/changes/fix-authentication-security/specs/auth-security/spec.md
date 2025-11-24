# Authentication Security Specification

## ADDED Requirements

### Requirement: Password Hashing
All user passwords MUST be hashed using bcrypt with a minimum of 10 salt rounds before storage. Plain-text passwords MUST NOT be stored in the database or transmitted in API responses.

#### Scenario: User registers with password
- **WHEN** user submits registration form with password "SecurePass123"
- **THEN** backend hashes password using bcrypt with 10 salt rounds
- **AND** hashed password (60 characters starting with "$2b$10$") is stored in database
- **AND** plain-text password is never stored or logged
- **AND** registration response excludes password field

#### Scenario: User logs in with correct password
- **WHEN** user submits login form with correct password
- **THEN** backend retrieves hashed password from database
- **AND** backend uses bcrypt.compare() to verify password
- **AND** comparison returns true
- **AND** login succeeds with JWT token issued

#### Scenario: User logs in with incorrect password
- **WHEN** user submits login form with incorrect password
- **THEN** backend uses bcrypt.compare() to verify password
- **AND** comparison returns false
- **AND** login fails with 401 Unauthorized
- **AND** error message is generic: "Invalid credentials"

#### Scenario: Migration script converts existing passwords
- **WHEN** administrator runs password migration script
- **THEN** script iterates through all users with plain-text passwords
- **AND** each plain-text password is hashed with bcrypt
- **AND** hashed password replaces plain-text password in database
- **AND** migration logs success count and any failures

---

### Requirement: JWT Token Generation
Backend MUST issue cryptographically secure JWT tokens upon successful authentication. Tokens MUST include user identification (userId, email, role) and expiration timestamp. Tokens MUST be signed with a strong secret key (JWT_SECRET) stored securely in environment variables.

#### Scenario: User logs in successfully
- **WHEN** user submits valid credentials
- **THEN** backend generates JWT token with payload: userId, email, role, iat, exp
- **AND** token is signed with JWT_SECRET using HS256 algorithm
- **AND** token expiration is set to 24 hours from issuance
- **AND** response includes token in format "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

#### Scenario: Admin logs in successfully
- **WHEN** admin user submits valid credentials
- **THEN** JWT token payload includes `"role": "admin"`
- **AND** admin can access admin-only endpoints with this token

#### Scenario: Token generation fails due to missing JWT_SECRET
- **WHEN** JWT_SECRET environment variable is not set
- **THEN** login endpoint throws error
- **AND** response returns 500 Internal Server Error
- **AND** error logged: "JWT_SECRET environment variable is not configured"

---

### Requirement: Token Validation Middleware
Backend MUST validate JWT tokens on all protected endpoints. Invalid, expired, or missing tokens MUST result in 401 Unauthorized responses. Token validation MUST verify signature, expiration, and payload structure.

#### Scenario: User accesses protected endpoint with valid token
- **WHEN** user sends request with `Authorization: Bearer <token>` header
- **THEN** middleware extracts token from header
- **AND** middleware verifies token signature with JWT_SECRET
- **AND** token signature is valid
- **AND** token expiration is in the future
- **AND** middleware decodes payload and attaches user data to request
- **AND** request proceeds to endpoint handler

#### Scenario: User accesses protected endpoint with expired token
- **WHEN** user sends request with token issued 25 hours ago
- **THEN** middleware verifies token signature (valid)
- **AND** middleware checks expiration timestamp
- **AND** expiration is in the past
- **AND** middleware rejects request with 401 Unauthorized
- **AND** response body: `{ "success": false, "error": "Token expired" }`

#### Scenario: User accesses protected endpoint without token
- **WHEN** user sends request without Authorization header
- **THEN** middleware rejects request with 401 Unauthorized
- **AND** response body: `{ "success": false, "error": "Authentication required" }`

#### Scenario: User accesses protected endpoint with malformed token
- **WHEN** user sends request with malformed token (not proper JWT format)
- **THEN** middleware attempts to verify token
- **AND** verification fails (invalid format or signature)
- **AND** middleware rejects request with 401 Unauthorized
- **AND** response body: `{ "success": false, "error": "Invalid token" }`

---

### Requirement: Admin Authorization Middleware
Backend MUST implement admin authorization middleware to restrict admin-only endpoints. Only users with role "admin" in JWT token MUST be allowed access. Regular users attempting to access admin endpoints MUST receive 403 Forbidden responses.

#### Scenario: Admin accesses admin-only endpoint
- **WHEN** admin user sends request to `POST /api/products` with valid token containing `"role": "admin"`
- **THEN** auth middleware validates token (passes)
- **AND** admin middleware checks `req.user.role`
- **AND** role is "admin"
- **AND** request proceeds to endpoint handler

#### Scenario: Regular user attempts to access admin endpoint
- **WHEN** regular user sends request to `POST /api/products` with valid token containing `"role": "customer"`
- **THEN** auth middleware validates token (passes)
- **AND** admin middleware checks `req.user.role`
- **AND** role is "customer" (not "admin")
- **AND** middleware rejects request with 403 Forbidden
- **AND** response body: `{ "success": false, "error": "Admin access required" }`

#### Scenario: Guest attempts to access admin endpoint
- **WHEN** guest user sends request to `POST /api/products` without Authorization header
- **THEN** auth middleware rejects request with 401 Unauthorized
- **AND** admin middleware is not reached
- **AND** response body: `{ "success": false, "error": "Authentication required" }`

---

### Requirement: Frontend Route Guards
Frontend MUST implement route guards to prevent unauthorized navigation to protected screens. Guards MUST check authentication status before rendering protected routes. Unauthenticated users MUST be redirected to login screen. Non-admin users MUST NOT access admin dashboard.

#### Scenario: Authenticated user navigates to cart screen
- **WHEN** logged-in user taps "Cart" button
- **THEN** route guard checks `authService.isLoggedIn()`
- **AND** check returns true
- **AND** user navigates to `/cart` screen
- **AND** cart screen loads successfully

#### Scenario: Unauthenticated user attempts to access cart screen
- **WHEN** guest user manually navigates to `/cart`
- **THEN** route guard checks `authService.isLoggedIn()`
- **AND** check returns false
- **AND** route guard redirects to `/login`
- **AND** login screen shows message: "Please login to continue"

#### Scenario: Non-admin user attempts to access admin dashboard
- **WHEN** regular user navigates to `/admin`
- **THEN** route guard checks `authService.isLoggedIn()` (true)
- **AND** route guard checks `authService.isAdmin()` (false)
- **AND** route guard redirects to `/products`
- **AND** snackbar shows: "Admin access required"

#### Scenario: Admin user navigates to admin dashboard
- **WHEN** admin user navigates to `/admin`
- **THEN** route guard checks `authService.isLoggedIn()` (true)
- **AND** route guard checks `authService.isAdmin()` (true)
- **AND** admin dashboard screen loads successfully

---

### Requirement: HTTP Service with Auto-Injected Auth Headers
Frontend MUST use a centralized HTTP service that automatically injects Authorization headers with JWT tokens for authenticated requests. All API calls MUST use this service to ensure consistent authentication.

#### Scenario: Authenticated user fetches orders
- **WHEN** user calls `HttpService.get('/api/orders')`
- **THEN** HttpService retrieves token from AuthService
- **AND** HttpService adds header: `Authorization: Bearer <token>`
- **AND** request sent to backend with auth header
- **AND** backend validates token and returns orders

#### Scenario: User token expires mid-session
- **WHEN** user attempts to fetch orders via `HttpService.get('/api/orders')` with expired token
- **THEN** HttpService sends request with expired token
- **AND** backend returns 401 Unauthorized
- **AND** HttpService catches 401 response
- **AND** HttpService calls `authService.logout()`
- **AND** HttpService navigates to `/login`
- **AND** user sees message: "Session expired, please login again"

#### Scenario: Regular user attempts admin action via HttpService
- **WHEN** regular user calls `HttpService.post('/api/products', data)` with customer token
- **THEN** HttpService sends request with customer token
- **AND** backend admin middleware returns 403 Forbidden
- **AND** HttpService catches 403 response
- **AND** HttpService shows error dialog: "You do not have permission to perform this action"

---

### Requirement: Guest Mode Restrictions
Frontend MUST restrict guest users to read-only product browsing. Guests MUST NOT be able to add products to cart, place orders, upload prescriptions, or access profile screens. Attempts to perform restricted actions MUST prompt login.

#### Scenario: Guest browses products
- **WHEN** guest user navigates to products screen
- **THEN** products load and display successfully
- **AND** guest can scroll, search, filter by category
- **AND** "Add to Cart" button shows "Login to Purchase"

#### Scenario: Guest attempts to add product to cart
- **WHEN** guest taps "Login to Purchase" button
- **THEN** app navigates to `/login` screen
- **AND** message shows: "Create an account or login to add products to cart"

#### Scenario: Guest attempts to access orders screen
- **WHEN** guest taps "My Orders" menu item
- **THEN** route guard redirects to `/login`
- **AND** message shows: "Please login to view your orders"

#### Scenario: Logged-in user adds product to cart
- **WHEN** logged-in user taps "Add to Cart" button
- **THEN** product is added to cart (authenticated API call)
- **AND** snackbar shows: "Product added to cart"
- **AND** cart badge updates with item count

---

### Requirement: Session Management and Auto-Logout
Frontend MUST implement session expiration checking and auto-logout. When token expires (24 hours), user MUST be logged out automatically and redirected to login screen with clear message. App MUST check token expiration on app resume and before critical actions.

#### Scenario: User's token expires while app is open
- **WHEN** user attempts to add product to cart after token expired
- **THEN** HttpService sends request with expired token
- **AND** backend returns 401 Unauthorized
- **AND** HttpService calls `authService.logout()`
- **AND** app navigates to `/login`
- **AND** message shows: "Your session has expired. Please login again."

#### Scenario: User resumes app after token expiration
- **WHEN** user resumes app (brings to foreground) after 25 hours
- **THEN** app lifecycle detects resume event
- **AND** AuthService checks `isTokenExpired()`
- **AND** token expiration check returns true
- **AND** AuthService calls `logout()`
- **AND** app navigates to `/login`
- **AND** message shows: "Your session has expired. Please login again."

#### Scenario: User checks token before placing order
- **WHEN** user taps "Place Order" button with valid token
- **THEN** checkout flow checks `authService.isTokenExpired()`
- **AND** token is still valid (within 24 hours)
- **AND** order proceeds normally

#### Scenario: User checks token before placing order (expired)
- **WHEN** user taps "Place Order" button with expired token
- **THEN** checkout flow checks `authService.isTokenExpired()`
- **AND** token is expired
- **AND** AuthService calls `logout()` preemptively
- **AND** app navigates to `/login` before sending order request
- **AND** message shows: "Your session has expired. Please login to complete your order."

---

### Requirement: Password Migration Script
A migration script MUST be provided to convert existing plain-text passwords to bcrypt hashes. Script MUST run safely on production database with error handling, logging, and rollback support. Script MUST be idempotent (safe to run multiple times).

#### Scenario: Migration script runs on database with plain-text passwords
- **WHEN** administrator runs `node backend/migrate-passwords.js`
- **THEN** script connects to database
- **AND** script queries all users with password length < 60 (plain-text)
- **AND** script hashes each plain-text password with bcrypt
- **AND** script updates user record with hashed password
- **AND** script completes with log: "Migration complete: N users updated, 0 failures"

#### Scenario: Migration script runs on already-hashed passwords (idempotent)
- **WHEN** administrator runs migration script on database with bcrypt-hashed passwords
- **THEN** script queries users with password length < 60
- **AND** script finds 0 users (all already hashed)
- **AND** script completes with log: "Migration complete: 0 users updated, 0 failures"
- **AND** no passwords are re-hashed

#### Scenario: Migration script encounters error
- **WHEN** migration script encounters user with null password
- **THEN** script logs error: "User <email> password migration failed: [error details]"
- **AND** script continues to next user (does not crash)
- **AND** script completes with log: "Migration complete: N users updated, 1 failure"
