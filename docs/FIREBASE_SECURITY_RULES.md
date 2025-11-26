# Firebase Security Rules Documentation

## How to Deploy Rules

### Option 1: Firebase Console (Recommended for now)

1. Go to: https://console.firebase.google.com/project/pharmacy-app-67eab/database/rules
2. Copy the contents of `firebase-database-rules.json`
3. Paste into the Rules editor
4. Click **"Publish"**

### Option 2: Firebase CLI (Later)

```bash
npm install -g firebase-tools
firebase login
firebase init database
firebase deploy --only database
```

## Security Rules Explanation

### User Access Control

**Users Node:** `/users/{userId}`
- **Read:** Users can read their own data, admins can read all users
- **Write:** Users can write their own data, admins can write all users
- **Validation:** Must have email, name, role, createdAt fields

```javascript
// User can read own data
auth.uid === $userId

// OR admin can read any user
root.child('users').child(auth.uid).child('role').val() === 'admin'
```

### Product Access Control

**Products Node:** `/products/{productId}`
- **Read:** Anyone can read (public)
- **Write:** Only admins
- **Validation:** Must have name, price, category, stock fields
- **Indexes:** Optimized for queries on category, price, name, barcode

```javascript
// Anyone can read
".read": true

// Only admins can write
".write": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'admin'"
```

### Order Access Control

**Orders Node:** `/orders/{orderId}`
- **Read:** Users can read their own orders, admins can read all
- **Write:**
  - Users can CREATE new orders (with their userId)
  - Admins can UPDATE any order (change status, etc.)
- **Validation:** Must have userId, items, total, status, createdAt
- **Indexes:** Optimized for queries on userId, status, createdAt

```javascript
// User can read own orders
data.child('userId').val() === auth.uid

// OR admin can read all orders
root.child('users').child(auth.uid).child('role').val() === 'admin'

// Users can create new orders
!data.exists() && newData.child('userId').val() === auth.uid

// Admins can update existing orders
root.child('users').child(auth.uid).child('role').val() === 'admin'
```

### Prescription Access Control

**Prescriptions Node:** `/prescriptions/{prescriptionId}`
- **Read:** Users can read their own prescriptions, admins can read all
- **Write:**
  - Users can CREATE new prescriptions
  - Users can UPDATE their own IF status is still "pending"
  - Admins can UPDATE any prescription (approve/reject)
- **Validation:** Must have userId, imageUrl, status, createdAt
- **Indexes:** Optimized for queries on userId, status, createdAt

```javascript
// Users can update own prescriptions if still pending
data.child('userId').val() === auth.uid && data.child('status').val() === 'pending'

// Admins can update any prescription
root.child('users').child(auth.uid).child('role').val() === 'admin'
```

### Category Access Control

**Categories Node:** `/categories/{categoryId}`
- **Read:** Anyone can read (public)
- **Write:** Only admins
- **Validation:** Must have name, icon fields

### Index Nodes

**userOrders:** `/userOrders/{userId}/{orderId}`
- **Read:** Users can read their own index, admins can read all
- **Write:** Users can write their own index, admins can write all

**productsByCategory:** `/productsByCategory/{categoryId}/{productId}`
- **Read:** Anyone can read (public)
- **Write:** Only admins

**stats:** `/stats/{date}`
- **Read:** Only admins
- **Write:** Only admins

## Testing Security Rules

### Test as Customer

```dart
// This should succeed (reading own data)
await FirebaseDatabase.instance.ref('users/${currentUserId}').get();

// This should fail (reading another user's data)
await FirebaseDatabase.instance.ref('users/anotherUserId').get();

// This should succeed (reading products)
await FirebaseDatabase.instance.ref('products').get();

// This should fail (writing products as customer)
await FirebaseDatabase.instance.ref('products/prod001').set({...});
```

### Test as Admin

```dart
// This should succeed (reading all users)
await FirebaseDatabase.instance.ref('users').get();

// This should succeed (writing products)
await FirebaseDatabase.instance.ref('products/prod001').set({...});

// This should succeed (updating order status)
await FirebaseDatabase.instance.ref('orders/order001/status').set('shipped');
```

### Test Unauthenticated

```dart
// This should succeed (reading products)
await FirebaseDatabase.instance.ref('products').get();

// This should fail (reading users)
await FirebaseDatabase.instance.ref('users').get();

// This should fail (reading orders)
await FirebaseDatabase.instance.ref('orders').get();
```

## Common Patterns

### Check if User is Admin

```javascript
root.child('users').child(auth.uid).child('role').val() === 'admin'
```

### Check if User Owns Resource

```javascript
data.child('userId').val() === auth.uid
```

### Validate Required Fields

```javascript
newData.hasChildren(['email', 'name', 'role'])
```

### Validate Field Type

```javascript
"email": {
  ".validate": "newData.isString() && newData.val().length > 0"
},
"price": {
  ".validate": "newData.isNumber() && newData.val() >= 0"
}
```

### Allow Creation but Not Deletion

```javascript
".write": "!data.exists() || newData.exists()"
```

## Security Best Practices

### ✅ DO

1. **Always check authentication:** `auth != null`
2. **Validate data types:** Use `.validate` rules
3. **Check ownership:** Verify `userId` matches `auth.uid`
4. **Use indexes:** Add `.indexOn` for common queries
5. **Deny by default:** Only allow what's explicitly permitted

### ❌ DON'T

1. **Don't use `.write: true`** - Anyone can modify data
2. **Don't skip validation** - Invalid data can break app
3. **Don't trust client data** - Always validate server-side
4. **Don't expose sensitive data** - PII, payment info, etc.
5. **Don't allow deep queries** - Use indexes instead

## Monitoring

### Firebase Console

1. Go to: https://console.firebase.google.com/project/pharmacy-app-67eab/database/usage
2. Monitor:
   - Reads/Writes count
   - Storage usage
   - Security rule denials

### Enable Logging

Firebase automatically logs security rule failures. Check:
- Firebase Console → Database → Usage → Rules Evaluation

## Troubleshooting

### "Permission Denied" Error

**Possible causes:**
1. User not authenticated (`auth == null`)
2. User doesn't own the resource
3. User is not admin when admin role required
4. Missing required fields in data

**Debug:**
```dart
try {
  await ref.set(data);
} catch (e) {
  print('Error: $e');
  // Check:
  // - Is user logged in? FirebaseAuth.instance.currentUser
  // - Does user have correct role? Check /users/{uid}/role
  // - Is data valid? Check all required fields present
}
```

### "Index Not Defined" Error

Add index to rules:
```javascript
".indexOn": ["userId", "status", "createdAt"]
```

### Rules Not Taking Effect

1. Ensure rules are **published** in Firebase Console
2. Wait 1-2 minutes for propagation
3. Clear app cache and restart

## Next Steps

1. ✅ Security rules defined
2. 🔄 Deploy rules to Firebase Console
3. 🔄 Implement Firebase Service Layer (next)
4. 🔄 Test with different user roles
