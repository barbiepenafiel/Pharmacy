## 1. Backend Database Connection Fix
- [x] 1.1 Update `prisma/schema.prisma` to add connection pool settings for Neon
- [x] 1.2 Modify `src/lib/prisma.ts` to add proper error handling and connection validation
- [x] 1.3 Add database health check on server startup
- [x] 1.4 Test database connection with Neon PostgreSQL
- [x] 1.5 Verify Prisma Client generation with correct SSL configuration

## 2. Backend API Enhancements
- [x] 2.1 Add health check endpoint `/api/health` that tests database connectivity
- [x] 2.2 Enhance error responses in `/api/products/route.ts` with specific error codes
- [ ] 2.3 Add request logging middleware for debugging
- [x] 2.4 Add CORS headers for external access (removed for now due to Next.js 16 proxy deprecation)
- [ ] 2.5 Test products API endpoint returns data successfully

## 3. Backend Network Configuration
- [x] 3.1 Verify `package.json` dev script uses `-H 0.0.0.0` flag
- [x] 3.2 Add environment variable validation on server startup
- [x] 3.3 Document required environment variables in README
- [ ] 3.4 Test backend accessibility from external devices on same network

## 4. Flutter App Configuration Updates
- [x] 4.1 Update `lib/config/app_config.dart` with environment-based backend URLs
- [x] 4.2 Add backend URL selection mechanism (local/ngrok/production)
- [x] 4.3 Update `lib/services/auth_service.dart` to use centralized config
- [x] 4.4 Remove hardcoded IP addresses from all screen files

## 5. Flutter HTTP Client Improvements
- [x] 5.1 Add retry logic with exponential backoff in product fetching
- [x] 5.2 Increase timeout from 5s to 10s for better reliability
- [x] 5.3 Add detailed error messages for different failure scenarios
- [x] 5.4 Implement connection status indicator in UI
- [ ] 5.5 Add offline mode detection and user feedback

## 6. Testing & Validation
- [ ] 6.1 Test product fetching with backend on local network
- [ ] 6.2 Test product fetching with ngrok tunnel
- [ ] 6.3 Test product fetching when device is not plugged in/debugging
- [ ] 6.4 Verify error messages are user-friendly
- [ ] 6.5 Test with poor network conditions (airplane mode, slow connection)
- [ ] 6.6 Verify database connection pool behavior under load

## 7. Documentation
- [x] 7.1 Update README with backend URL configuration instructions
- [x] 7.2 Document ngrok setup for external testing
- [x] 7.3 Add troubleshooting guide for common connection issues
- [x] 7.4 Document production deployment checklist
