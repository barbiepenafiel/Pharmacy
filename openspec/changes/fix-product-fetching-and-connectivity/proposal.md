# Change: Fix Product Fetching from Neon Database and Non-Debug Backend Connectivity

## Why
Currently, the mobile app fails to fetch products from the Neon PostgreSQL database, and backend connectivity only works when the device is physically connected/debugging in VS Code. This limits the app's usability during production deployment and testing on physical devices outside the development environment.

The issues stem from:
1. Database connection issues between the Next.js backend and Neon PostgreSQL (SSL/channel binding configuration)
2. Hardcoded IP addresses that only work on local network during debug sessions
3. No fallback mechanism for production/cloud-hosted backend URLs
4. Missing error handling and retry logic for database queries
5. Backend server not configured to be accessible from external networks

## What Changes
- Fix Prisma database connection configuration to properly connect to Neon PostgreSQL with SSL
- Update `app_config.dart` to support dynamic backend URL configuration (local, ngrok, cloud)
- Implement proper error handling and logging for product API requests
- Add connection pooling configuration for Neon database
- Configure backend server to accept external connections (0.0.0.0 binding)
- Add environment variable validation and startup checks
- Implement API health check endpoint
- Add retry logic with exponential backoff for failed API requests
- Update Flutter HTTP client with better timeout and error handling

## Impact
- Affected specs: 
  - `product-api` (new capability)
  - `network-config` (new capability)
- Affected code:
  - `backend/src/lib/prisma.ts` - Database connection configuration
  - `backend/src/app/api/products/route.ts` - Product API endpoint
  - `backend/prisma/schema.prisma` - Prisma configuration
  - `lib/config/app_config.dart` - Backend URL configuration
  - `lib/services/auth_service.dart` - Base URL management
  - `lib/screens/products_screen.dart` - Product fetching logic
  - `lib/services/http_service.dart` - HTTP client wrapper (if exists)
  - `backend/.env` - Environment variables
  - `backend/package.json` - Dev server configuration

## Breaking Changes
None - This is a bug fix that enhances existing functionality without changing APIs.
