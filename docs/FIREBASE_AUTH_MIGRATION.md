# Firebase Authentication Migration Guide

## Overview

The `AuthService` has been completely rewritten to use **Firebase Authentication** instead of JWT tokens from a backend API. This eliminates the need for a backend authentication server.

## Key Changes

### Before (JWT-based)
```dart
// HTTP calls to backend
await http.post(Uri.parse('$baseUrl/api/auth'), ...)
// Manual token storage
String? _authToken;
DateTime? _tokenExpiration;
```

### After (Firebase Auth)
```dart
// Firebase Authentication
await _auth.signInWithEmailAndPassword(email, password)
// Automatic token management
User? currentUser = _auth.currentUser;
```

## New Features

### 1. Registration
```dart
final result = await AuthService().register(
  fullName: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
  confirmPassword: 'password123',
);

// Creates user in Firebase Auth + profile in database
```

### 2. Login
```dart
final result = await AuthService().login(
  email: 'john@example.com',
  password: 'password123',
);

// Returns user's full name on success
if (result.success) {
  print('Welcome ${result.fullName}');
}
```

### 3. Auth State Listener
```dart
// Listen to authentication state changes
AuthService().authStateChanges.listen((User? user) {
  if (user != null) {
    print('User logged in: ${user.email}');
  } else {
    print('User logged out');
  }
});
```

### 4. Password Reset
```dart
final result = await AuthService().sendPasswordResetEmail(
  email: 'john@example.com',
);
// Sends reset email via Firebase
```

### 5. Profile Management
```dart
// Update user profile
await AuthService().updateProfile(
  name: 'John Smith',
  photoUrl: 'https://example.com/photo.jpg',
);

// Delete account
await AuthService().deleteAccount();
```

### 6. Reauthentication
```dart
// Required before sensitive operations
final result = await AuthService().reauthenticate(
  password: 'current_password',
);
```

## Migration Checklist for Screens

When updating screens that use `AuthService`:

### ✅ Already Compatible
These methods work the same way:
- `isLoggedIn()` - Returns true if user is authenticated
- `logout()` - Signs out the user
- `isOfflineMode()` - Always returns false (Firebase handles offline)

### ⚠️ Changed to Async
These methods now return `Future`:
- `getCurrentUser()` → `Future<Map<String, dynamic>?>`
- `getAuthToken()` → `Future<String?>`
- `isAdmin()` → `Future<bool>`

### Example Updates

**Before:**
```dart
final user = AuthService().getCurrentUser();
final isAdmin = AuthService().isAdmin();
```

**After:**
```dart
final user = await AuthService().getCurrentUser();
final isAdmin = await AuthService().isAdmin();
```

## Error Handling

Firebase Authentication provides specific error codes:

```dart
try {
  await AuthService().login(email: email, password: password);
} catch (e) {
  // Error codes include:
  // - user-not-found
  // - wrong-password
  // - invalid-email
  // - user-disabled
  // - too-many-requests
  // - network-request-failed
}
```

## Security Improvements

1. **No Password Storage**: Passwords never stored locally
2. **Automatic Token Refresh**: Firebase handles token refresh
3. **Built-in Rate Limiting**: Protection against brute force
4. **Email Verification**: Optional email verification flow
5. **Multi-Factor Auth**: Can be added in future

## Offline Support

Firebase Auth works offline automatically:
- Users can stay logged in offline
- Token refresh happens when back online
- No manual offline mode needed

## Testing

To test the new authentication:

1. **Deploy Security Rules** (required first!)
2. **Create Test User**:
   ```dart
   await AuthService().register(
     fullName: 'Test User',
     email: 'test@pharmacy.com',
     password: 'test123',
     confirmPassword: 'test123',
   );
   ```
3. **Login**:
   ```dart
   final result = await AuthService().login(
     email: 'test@pharmacy.com',
     password: 'test123',
   );
   ```
4. **Check Authentication**:
   ```dart
   print(AuthService().isLoggedIn()); // true
   ```

## Next Steps

After authentication migration:

1. ✅ Update `AppConfig` to remove backend URL
2. ⏳ Update screens to use async auth methods
3. ⏳ Update login screen UI
4. ⏳ Add email verification (optional)
5. ⏳ Add "Forgot Password" button

## Firebase Console

Monitor authentication at:
https://console.firebase.google.com/project/pharmacy-app-67eab/authentication

You can:
- View registered users
- Disable/enable accounts
- Reset passwords manually
- Configure email templates

## API Compatibility

The new `AuthService` maintains backward compatibility where possible:

| Method | Before | After | Compatible? |
|--------|--------|-------|-------------|
| `login()` | Sync | Async | ✅ Same signature |
| `register()` | Sync | Async | ✅ Same signature |
| `isLoggedIn()` | Sync | Sync | ✅ No changes |
| `logout()` | Sync | Async | ⚠️ Now returns Future |
| `getCurrentUser()` | Sync | Async | ⚠️ Now returns Future |
| `isAdmin()` | Sync | Async | ⚠️ Now returns Future |
| `getAuthToken()` | Sync | Async | ⚠️ Now returns Future |

## Common Issues

### Issue: "User profile not found"
**Solution**: User authenticated but no database entry. Ensure registration creates database record.

### Issue: "Requires recent login"
**Solution**: Sensitive operations need reauthentication:
```dart
await AuthService().reauthenticate(password: password);
await AuthService().deleteAccount();
```

### Issue: "Network error"
**Solution**: Check internet connection. Firebase Auth requires connectivity for login.

## Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/flutter/start)
- [Security Rules Guide](./FIREBASE_SECURITY_RULES.md)
- [Database Structure](./FIREBASE_DATABASE_STRUCTURE.md)
