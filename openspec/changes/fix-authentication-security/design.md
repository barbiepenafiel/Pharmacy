## Context

The pharmacy application currently has **critical authentication and authorization vulnerabilities** that expose the system to unauthorized access, privilege escalation, and data breaches.

### Current Security Issues

1. **Plain-text Passwords**: Passwords stored without hashing in PostgreSQL database
2. **Dummy Tokens**: Backend returns `'dummy-token-' + user.id` (predictable, not cryptographic)
3. **No Token Validation**: Frontend stores tokens but never sends them; backend never validates them
4. **Missing Route Guards**: `/admin` route accessible without authentication checks
5. **Guest Bypass**: "Continue as Guest" provides full app access
6. **No Authorization**: Admin APIs don't verify user roles
7. **No Session Management**: Tokens never expire, no refresh mechanism

### Attack Vectors

- Direct URL navigation to `/admin` → instant admin access
- Database breach → all passwords compromised (plain-text)
- Token prediction → hijack any user session
- Guest mode → place orders, access user data without authentication
- API manipulation → regular users can call admin endpoints

### Stakeholders

- **End Users**: Need secure authentication to protect personal/medical data
- **Admins**: Need role-based access control to prevent unauthorized product/user management
- **Business**: Regulatory compliance (HIPAA, GDPR) requires proper authentication
- **Developers**: Need maintainable, secure authentication patterns

### Constraints

- **Backward Compatibility**: Existing users must be able to login after update (migrate passwords)
- **Performance**: Token validation must not add significant latency (<10ms)
- **User Experience**: Session expiration should be reasonable (24h default)
- **Environment**: JWT_SECRET must be configurable per environment (dev/staging/prod)

## Goals / Non-Goals

### Goals

1. **Secure password storage** using industry-standard bcrypt hashing (salt rounds: 10)
2. **Cryptographically secure tokens** using JWT (RS256 or HS256 signing)
3. **Token-based authentication** for all protected API endpoints
4. **Role-based authorization** to separate customer and admin permissions
5. **Frontend route guards** to prevent unauthorized navigation
6. **Session management** with token expiration and auto-logout
7. **Guest mode restrictions** (read-only product browsing only)
8. **Backward compatibility** via password migration script

### Non-Goals

1. **OAuth/Social Login** (e.g., Google, Facebook) - out of scope for initial security fix
2. **Two-Factor Authentication (2FA)** - future enhancement, not required for MVP security
3. **Refresh Tokens** - optional enhancement (access token expiration sufficient for initial fix)
4. **Rate Limiting** - separate security concern (prevent brute-force), not authentication
5. **HTTPS Enforcement** - deployment/infrastructure concern, not application logic
6. **Password Complexity Rules** - future enhancement (current validation sufficient)

## Decisions

### Decision 1: bcrypt for Password Hashing

**What**: Use bcrypt library with salt rounds = 10

**Why**:
- Industry-standard password hashing algorithm (OWASP recommended)
- Adaptive: salt rounds increase computational cost as hardware improves
- Built-in salt generation prevents rainbow table attacks
- Resistant to GPU-based brute-force attacks

**Alternatives Considered**:
- **argon2** - More secure but heavier dependency, overkill for current threat model
- **scrypt** - Good alternative but less ecosystem support in Node.js
- **PBKDF2** - Weaker against GPU attacks than bcrypt

**Implementation**:
```typescript
import bcrypt from 'bcrypt';

// Register
const hashedPassword = await bcrypt.hash(password, 10);

// Login
const isValid = await bcrypt.compare(password, user.password);
```

### Decision 2: JWT with HS256 Signing

**What**: Use JSON Web Tokens with HMAC SHA-256 (HS256) symmetric signing

**Why**:
- Stateless: No server-side session storage required
- Self-contained: Token includes user id, email, role, expiration
- Standard: RFC 7519, wide ecosystem support
- Simple: HS256 symmetric key easier to manage than RS256 asymmetric keys

**Alternatives Considered**:
- **RS256 (asymmetric)** - More complex, requires public/private key management, overkill for single-server deployment
- **Session cookies** - Requires server-side session store (Redis/database), adds complexity and cost
- **Opaque tokens** - Requires database lookup on every request, higher latency

**Token Payload**:
```typescript
{
  userId: string,
  email: string,
  role: 'customer' | 'admin',
  iat: number, // issued at (Unix timestamp)
  exp: number  // expiration (Unix timestamp)
}
```

**Token Expiration**: 24 hours (configurable via `JWT_EXPIRATION` env variable)

### Decision 3: Authorization Header (Bearer Scheme)

**What**: Send JWT tokens in HTTP `Authorization` header using Bearer scheme

**Why**:
- Standard HTTP authentication pattern (RFC 6750)
- Prevents CSRF attacks (unlike cookies)
- Works with CORS and cross-origin requests
- Easy to implement in Flutter http package

**Alternative Considered**:
- **Cookies** - Vulnerable to CSRF, requires additional CSRF tokens, complex CORS handling

**Implementation**:
```dart
// Frontend
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

```typescript
// Backend
const authHeader = request.headers.get('authorization');
const token = authHeader?.replace('Bearer ', '');
```

### Decision 4: Middleware-Based Authorization

**What**: Create reusable middleware functions for authentication and admin authorization

**Why**:
- DRY: Avoid repeating auth logic in every endpoint
- Composable: Can combine auth + admin middlewares
- Maintainable: Centralized auth logic, easier to update
- Testable: Can test middlewares in isolation

**Middleware Chain**:
```typescript
// Protected endpoint (user-only)
auth(async (req) => { /* handler */ })

// Admin-only endpoint
auth(admin(async (req) => { /* handler */ }))
```

### Decision 5: Route Guards on Frontend

**What**: Check authentication status before navigating to protected screens

**Why**:
- Client-side validation prevents unnecessary API calls
- Better UX: immediate feedback instead of loading then error
- Defense-in-depth: Even if bypassed, backend auth still protects APIs

**Implementation**:
```dart
// In main.dart
onGenerateRoute: (settings) {
  if (settings.name == '/admin') {
    if (!authService.isLoggedIn() || !authService.isAdmin()) {
      return MaterialPageRoute(builder: (_) => LoginScreen());
    }
    return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
  }
  // ...
}
```

### Decision 6: Guest Mode = Read-Only Product Browsing

**What**: Guests can browse products but cannot add to cart, place orders, or access profile

**Why**:
- Marketing: Allow users to explore products before registering
- Security: Prevent anonymous actions that require identity (orders, prescriptions)
- Compliance: Medical/prescription data requires authenticated identity

**Guest Restrictions**:
- ✅ Browse products, categories, search
- ❌ Add to cart
- ❌ Place orders
- ❌ Upload prescriptions
- ❌ Access profile, orders, addresses, payment methods

## Risks / Trade-offs

### Risk 1: Password Migration Failure

**Description**: Existing plain-text passwords may fail to migrate if database is unavailable or script has bugs

**Mitigation**:
1. Test migration script on development database first
2. Create database backup before running migration
3. Add error handling to log failed migrations
4. Allow manual password reset as fallback

**Rollback**: Restore database from backup, revert code changes

### Risk 2: Token Expiration UX Friction

**Description**: Users logged out after 24 hours may be frustrated

**Mitigation**:
1. Show clear "Session Expired" message before logout
2. Store intended destination, redirect after re-login
3. Consider refresh tokens in future iteration (non-goal for MVP)

**Trade-off**: Security (shorter expiration) vs UX (longer sessions) → 24h balances both

### Risk 3: Breaking Existing Sessions

**Description**: All users must re-login after deployment (token format changes)

**Mitigation**:
1. Communicate deployment window to users
2. Show friendly message: "Please login again for security update"
3. Deploy during low-traffic hours

**Accepted**: One-time inconvenience for long-term security benefit

### Risk 4: JWT_SECRET Exposure

**Description**: If JWT_SECRET leaks, attackers can forge tokens

**Mitigation**:
1. Store JWT_SECRET in environment variables (not in code)
2. Use strong random secret (32+ characters, alphanumeric + special chars)
3. Rotate secret periodically (invalidates all tokens)
4. Never commit `.env` file to git (add to `.gitignore`)

**Detection**: Monitor for unusual admin API activity, implement audit logs

## Migration Plan

### Phase 1: Preparation (Development)
1. Install dependencies (bcrypt, jsonwebtoken)
2. Generate JWT_SECRET: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`
3. Add JWT_SECRET to backend/.env: `JWT_SECRET=<generated_secret>`
4. Create password migration script
5. Test migration on development database

### Phase 2: Backend Security Implementation
1. Implement password hashing in auth endpoints
2. Implement JWT token generation
3. Create authentication middleware
4. Create admin authorization middleware
5. Apply middlewares to protected endpoints
6. Test all endpoints with Postman/curl

### Phase 3: Frontend Implementation
1. Create HttpService with auto-inject auth headers
2. Update all API calls to use HttpService
3. Implement route guards
4. Add admin dashboard authentication check
5. Implement guest mode restrictions
6. Test authentication flows end-to-end

### Phase 4: Database Migration
1. Backup production database
2. Run password migration script
3. Verify all passwords hashed successfully
4. Keep backup for 7 days (rollback window)

### Phase 5: Deployment
1. Deploy backend with new auth logic
2. Deploy frontend with route guards
3. Monitor error logs for auth failures
4. Notify users to re-login (session invalidated)

### Phase 6: Verification
1. Test user registration → login flow
2. Test admin login → dashboard access
3. Test regular user cannot access admin dashboard
4. Test guest mode restrictions
5. Test token expiration and auto-logout
6. Monitor production metrics for 48 hours

### Rollback Procedure

If critical issues detected within 48 hours:

1. **Backend**: Deploy previous version (restore plain-text password logic)
2. **Database**: Restore from backup (lose passwords created during rollback window)
3. **Frontend**: Deploy previous version (remove route guards)
4. **Communication**: Notify users of rollback, passwords may need reset

**Rollback Trigger**: >10% authentication failure rate OR admin dashboard inaccessible

## Open Questions

1. **Refresh token implementation**?
   - **Answer**: Not required for MVP. Access token expiration (24h) is sufficient. Can add refresh tokens in future iteration based on user feedback.

2. **Password reset flow**?
   - **Answer**: Out of scope for this security fix. Current "Forgot Password?" button is placeholder. Will implement in separate change (email verification required).

3. **Multi-device sessions**?
   - **Answer**: Current implementation allows unlimited concurrent sessions per user. Can add device tracking in future if abuse detected.

4. **Token revocation**?
   - **Answer**: Not implemented (stateless JWT). If user compromised, admin can manually reset password (invalidates future logins). Full revocation requires Redis/database token blacklist (future enhancement).

5. **Password complexity requirements**?
   - **Answer**: Current validation: minimum 6 characters. Sufficient for MVP. Can add complexity rules (uppercase, numbers, special chars) in future based on security audit.
