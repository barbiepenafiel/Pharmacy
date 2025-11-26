# Firebase Security Rules Testing Guide

## Understanding "Simulated read denied"

✅ **This is CORRECT behavior!** Your security rules are working as intended.

The rules require authentication for most operations, so when you simulate without auth, it denies access.

## How to Test Security Rules

### Option 1: Simulator with Authentication

1. Go to Firebase Console → Realtime Database → Rules
2. Click the **"Rules Playground"** tab
3. Configure the test:

**For Public Reads (Products, Categories):**
```
Location: /products
Type: Read
```
Result: ✅ **Allowed** (products are public)

**For User Data (Without Auth):**
```
Location: /users/test-user-id
Type: Read
Authentication: (leave empty)
```
Result: ❌ **Denied** (correct! requires auth)

**For User Data (With Auth):**
```
Location: /users/test-user-id
Type: Read
Authentication:
  Provider: Custom
  UID: test-user-id
```
Result: ✅ **Allowed** (user can read own data)

**For Admin Operations:**
```
Location: /products/product-1
Type: Write
Authentication:
  Provider: Custom
  UID: admin-user-id
  Custom Claims: (click "+ Add custom claim")
    Key: role
    Value: admin
```
Result: ✅ **Allowed** (admin can write products)

### Option 2: Real Testing (Recommended)

The best way to test is with actual authentication:

#### Step 1: Deploy the Rules
```
1. Copy entire contents of firebase-database-rules.json
2. Go to: https://console.firebase.google.com/project/pharmacy-app-67eab/database/rules
3. Paste the rules
4. Click "Publish"
```

#### Step 2: Create Test User
```
1. Go to Authentication tab in Firebase Console
2. Click "Add User"
3. Email: admin@pharmacy.com
4. Password: admin123
5. Click "Add User"
```

#### Step 3: Set Admin Role
```
1. Go to Realtime Database tab
2. Click "+" next to root
3. Add node: users
4. Add child node: [paste the UID from Authentication]
5. Add these fields:
   {
     "email": "admin@pharmacy.com",
     "name": "Admin User",
     "role": "admin",
     "createdAt": 1700000000000,
     "addresses": [],
     "paymentMethods": []
   }
```

#### Step 4: Test in App
```dart
// Run the app and try to login
await AuthService().login(
  email: 'admin@pharmacy.com',
  password: 'admin123',
);
```

## Common Test Scenarios

### ✅ Should ALLOW (Public Access)

```
Location: /products
Type: Read
Auth: None
Result: Allowed ✅
Reason: Products are public
```

```
Location: /categories
Type: Read
Auth: None
Result: Allowed ✅
Reason: Categories are public
```

```
Location: /productsByCategory/electronics
Type: Read
Auth: None
Result: Allowed ✅
Reason: Product indexes are public
```

### ❌ Should DENY (Requires Authentication)

```
Location: /users/user123
Type: Read
Auth: None
Result: Denied ❌
Reason: User data requires authentication
```

```
Location: /orders/order123
Type: Read
Auth: None
Result: Denied ❌
Reason: Orders require authentication
```

```
Location: /prescriptions
Type: Read
Auth: None
Result: Denied ❌
Reason: Prescriptions require authentication
```

### ✅ Should ALLOW (Authenticated User)

```
Location: /users/user123
Type: Read
Auth: UID = user123
Result: Allowed ✅
Reason: User can read own data
```

```
Location: /orders/order456
Type: Read
Auth: UID = user123
Data: order456 has userId = user123
Result: Allowed ✅
Reason: User can read own orders
```

### ❌ Should DENY (Wrong User)

```
Location: /users/user456
Type: Read
Auth: UID = user123
Result: Denied ❌
Reason: Can't read other users' data
```

```
Location: /orders/order789
Type: Read
Auth: UID = user123
Data: order789 has userId = user456
Result: Denied ❌
Reason: Can't read other users' orders
```

### ✅ Should ALLOW (Admin Operations)

```
Location: /products/product1
Type: Write
Auth: UID = admin123, role = admin
Result: Allowed ✅
Reason: Admins can write products
```

```
Location: /users/any-user
Type: Read
Auth: UID = admin123, role = admin
Result: Allowed ✅
Reason: Admins can read all users
```

```
Location: /orders/any-order
Type: Read/Write
Auth: UID = admin123, role = admin
Result: Allowed ✅
Reason: Admins can manage all orders
```

## Simulating Admin Access

To test admin rules in the simulator, you need to set the role in the **database first**, not in custom claims.

The rules check: `root.child('users').child(auth.uid).child('role').val() === 'admin'`

This means:
1. Create a user in `/users/[uid]` with `role: "admin"`
2. Then simulate with that UID
3. The rule will read from the database to check the role

**Example:**

1. Add to database:
```json
{
  "users": {
    "admin-test-uid": {
      "email": "admin@test.com",
      "name": "Admin",
      "role": "admin",
      "createdAt": 1700000000000
    }
  }
}
```

2. Then simulate:
```
Location: /products/product-1
Type: Write
Authentication:
  UID: admin-test-uid
```

Result: ✅ Allowed (because role is "admin" in database)

## Quick Test Checklist

Once rules are deployed:

- [ ] Anonymous user can read products ✅
- [ ] Anonymous user cannot read users ❌
- [ ] Authenticated user can read own profile ✅
- [ ] Authenticated user cannot read other profiles ❌
- [ ] Customer cannot create products ❌
- [ ] Admin can create products ✅
- [ ] User can create own order ✅
- [ ] User cannot create order for another user ❌
- [ ] User can read own orders ✅
- [ ] User cannot read others' orders ❌
- [ ] Admin can read all orders ✅

## Testing from Flutter App

After deploying rules, test with actual app code:

```dart
// Test 1: Public product access (should work)
try {
  final products = await FirebaseService().getProducts();
  print('✅ Public read works: ${products.length} products');
} catch (e) {
  print('❌ Public read failed: $e');
}

// Test 2: Authenticated user data (should work after login)
try {
  await AuthService().login(email: 'test@test.com', password: 'test123');
  final user = await AuthService().getCurrentUser();
  print('✅ Auth read works: ${user?['name']}');
} catch (e) {
  print('❌ Auth read failed: $e');
}

// Test 3: Create order (should work for authenticated user)
try {
  final orderId = await FirebaseService().createOrder(
    userId: 'current-user-id',
    items: [...],
    total: 100.0,
  );
  print('✅ Order creation works: $orderId');
} catch (e) {
  print('❌ Order creation failed: $e');
}
```

## Troubleshooting

### "Permission denied" in app
✅ **Expected** if not logged in  
✅ **Expected** if trying to access other users' data  
❌ **Problem** if logged in and accessing own data

**Solution**: Check that:
1. Rules are deployed
2. User is authenticated
3. UID matches in rules check
4. Role is set correctly in database

### "Simulated read denied" in console
✅ **Expected** for authenticated endpoints without auth in simulator  
✅ **Correct behavior** - rules are working!

### Rules seem too permissive
Check:
- Public endpoints: products, categories (intentional)
- User endpoints: require auth.uid match
- Admin endpoints: require role check

### Rules seem too restrictive
- Make sure user profile exists in database
- Make sure role field is set
- Make sure UID matches exactly

## Security Best Practices

✅ **DO:**
- Deploy rules before adding sensitive data
- Test with multiple user scenarios
- Use Firebase Console monitoring
- Set up alerts for suspicious activity

❌ **DON'T:**
- Make everything public to "fix" permission errors
- Skip authentication checks
- Store sensitive data without encryption
- Use predictable user IDs

## Firebase Console Monitoring

After deployment, monitor at:
https://console.firebase.google.com/project/pharmacy-app-67eab/database/data

You can see:
- Real-time data changes
- Active connections
- Data size
- Read/write operations

## Next Steps

1. ✅ Understand "Simulated read denied" is correct
2. 🎯 Deploy rules to Firebase Console
3. ✅ Create test admin user
4. ✅ Test in actual Flutter app
5. ✅ Monitor Firebase Console for errors

---

**Remember**: "Permission denied" errors are GOOD when they prevent unauthorized access! 🔒
