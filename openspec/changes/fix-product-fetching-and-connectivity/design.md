## Context
The pharmacy mobile app currently has two critical infrastructure issues:
1. **Database connectivity**: The Next.js backend cannot reliably fetch products from Neon PostgreSQL due to improper SSL/connection pooling configuration
2. **Network accessibility**: The backend is only accessible during VS Code debug sessions, making it impossible to test on physical devices without USB connection

These issues block production deployment and realistic testing scenarios.

## Goals
- Enable reliable product fetching from Neon database in all environments
- Support backend access from devices not connected to development machine
- Provide clear error messages and fallback mechanisms
- Support multiple deployment scenarios (local, ngrok tunnel, cloud hosting)

## Non-Goals
- Implementing offline data caching (future enhancement)
- Migrating from Neon to another database provider
- Implementing service worker or PWA features
- Adding authentication to health check endpoints

## Decisions

### Decision 1: Use Environment-Based Configuration
**Rationale**: Support multiple backend URLs (local IP, ngrok, production) without code changes.

**Implementation**:
- Create `AppConfig` class with environment detection
- Use Flutter compile-time constants or runtime configuration
- Provide UI toggle for developers to switch between environments

**Alternatives considered**:
- Build different APKs for each environment → More complex deployment
- Use only production URLs → Makes local development harder

### Decision 2: Add Connection Pooling for Neon
**Rationale**: Neon PostgreSQL requires proper connection pooling to handle serverless cold starts and concurrent requests.

**Implementation**:
```typescript
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  directUrl = env("DIRECT_DATABASE_URL") // For migrations
}
```

**Alternatives considered**:
- Use direct connection only → Poor performance under load
- Implement custom connection management → Unnecessary complexity

### Decision 3: Add Health Check Endpoint
**Rationale**: Enable quick diagnosis of backend and database connectivity issues.

**Implementation**:
- Create `/api/health` endpoint that tests database connection
- Return status code 200 with JSON including database status
- No authentication required (read-only diagnostic)

**Alternatives considered**:
- Rely on product endpoint for health checks → Mixes concerns
- Add authentication to health check → Complicates diagnostics

### Decision 4: Implement Retry Logic with Exponential Backoff
**Rationale**: Handle transient network failures and Neon cold starts gracefully.

**Implementation**:
- 3 retry attempts with delays: 1s, 2s, 4s
- Only retry on network errors, not 4xx client errors
- Show loading indicator during retries

**Alternatives considered**:
- No retry logic → Poor user experience
- Infinite retries → Wastes battery and data

## Risks / Trade-offs

### Risk 1: Neon Connection Pool Exhaustion
**Impact**: High concurrent load could exhaust Neon's connection pool limit
**Mitigation**: 
- Configure appropriate pool size (default: 10)
- Implement connection timeout (30s)
- Monitor connection usage in Neon dashboard

### Risk 2: Hardcoded IP Address Management
**Impact**: Developers must manually update IP when network changes
**Mitigation**:
- Provide clear documentation on updating backend URL
- Add environment switcher in app settings (dev builds only)
- Consider mDNS/Bonjour for automatic discovery (future)

### Risk 3: CORS Configuration Security
**Impact**: Overly permissive CORS could expose backend to attacks
**Mitigation**:
- Use specific origins in production, not wildcard `*`
- Implement rate limiting on API endpoints
- Add authentication middleware for sensitive endpoints

## Migration Plan

### Phase 1: Backend Database Connection (Day 1)
1. Update Prisma schema with connection pooling
2. Run `npx prisma generate` to regenerate client
3. Test database connection with `npx prisma db pull`
4. Restart backend and verify product seeding works

### Phase 2: Backend API & Network (Day 1-2)
1. Add health check endpoint
2. Verify `-H 0.0.0.0` flag in dev script
3. Test backend access from phone on same network
4. Add CORS headers if needed

### Phase 3: Flutter Configuration (Day 2)
1. Update `AppConfig` with environment-based URLs
2. Remove hardcoded IPs from all Dart files
3. Add backend URL selector in settings screen (debug builds)

### Phase 4: Flutter HTTP Client (Day 2-3)
1. Implement retry logic in product fetching
2. Add better error messages
3. Increase timeouts
4. Test with various network conditions

### Phase 5: Testing & Validation (Day 3)
1. Test product fetching with device unplugged
2. Test with ngrok tunnel
3. Test with airplane mode toggle
4. Verify error handling

### Rollback Plan
If issues occur:
1. Revert Prisma schema changes and regenerate client
2. Restore original `app_config.dart` with single hardcoded URL
3. Remove retry logic if causing UI freezes
4. Use git to revert to last working commit

## Open Questions
1. **Q**: Should we store the selected backend URL in persistent storage (SharedPreferences)?
   - **A**: Yes for convenience, but default to production URL to avoid confusion

2. **Q**: Do we need to support multiple Neon database environments (dev, staging, prod)?
   - **A**: For now, single database is sufficient. Can add multiple environments later.

3. **Q**: Should health check endpoint return detailed error messages?
   - **A**: Yes for development, but sanitize in production to avoid exposing internals

4. **Q**: How should we handle Neon serverless cold starts (5-10s delay)?
   - **A**: Implement 10s timeout and show "Connecting to database..." message
