# Connection Timeout Fix

## Problem
The Flutter app was getting **"Error connecting to server: Exception: Connection timeout"** when trying to login or access admin features.

## Root Cause
The app was trying to connect to the wrong server address and port:
- **Wrong:** `http://10.0.2.2:3002` (Android emulator syntax with wrong port)
- **Backend running on:** `http://localhost:3000` (Windows development)

## Solution Applied
Fixed all hardcoded backend URLs in two files:

### 1. `lib/services/auth_service.dart`
- Changed `baseUrl` from `http://10.0.2.2:3002` to `http://localhost:3000`
- This fixes login and registration API calls

### 2. `lib/screens/admin_dashboard_screen.dart`
Updated all 6 API endpoints:
- Dashboard stats: `/api/admin/dashboard-public`
- Products list: `/api/admin/products-public`
- Create/update products: `/api/admin/products`
- Delete products: `/api/admin/products/{id}`
- Users list: `/api/admin/users-public`
- Orders list: `/api/admin/orders-public`

## Now Running
✅ Backend: `http://localhost:3000`
✅ Flutter App: Connected to backend

## Admin Credentials
- **Email:** `admin@pharmacy.com`
- **Password:** `Admin@123456`

## To Prevent This Again
Always configure the backend URL in one centralized place. Consider creating a `lib/config/api_config.dart` file for all API configuration in the future.
