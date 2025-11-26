# Firebase Realtime Database Structure

This document defines the complete database structure for the Pharmacy app using Firebase Realtime Database.

## Database URL
`https://pharmacy-app-67eab-default-rtdb.asia-southeast1.firebasedatabase.app/`

## Design Principles

1. **Denormalization** - Duplicate data for read efficiency
2. **Flat Structure** - Avoid deep nesting (max 2-3 levels)
3. **Index Nodes** - Separate nodes for efficient queries
4. **Scalability** - Use push() generated IDs for auto-incrementing keys

## Root Structure

```json
{
  "users": {},
  "products": {},
  "orders": {},
  "prescriptions": {},
  "categories": {},
  "inventory": {},
  "userOrders": {},
  "productsByCategory": {},
  "stats": {}
}
```

## 1. Users Node

**Path:** `/users/{userId}`

```json
{
  "users": {
    "user123abc": {
      "email": "john@example.com",
      "name": "John Doe",
      "phone": "+1234567890",
      "role": "customer",
      "createdAt": 1700000000000,
      "lastLogin": 1700100000000,
      "addresses": {
        "addr1": {
          "street": "123 Main St",
          "city": "Manila",
          "zipCode": "1000",
          "isDefault": true
        }
      },
      "paymentMethods": {
        "pm1": {
          "type": "card",
          "last4": "4242",
          "isDefault": true
        }
      }
    }
  }
}
```

**Fields:**
- `email` (string) - User email (lowercase)
- `name` (string) - Full name
- `phone` (string, optional) - Contact number
- `role` (string) - "customer" | "admin" | "pharmacist"
- `createdAt` (timestamp) - Account creation time
- `lastLogin` (timestamp) - Last login time
- `addresses` (object, optional) - Saved addresses
- `paymentMethods` (object, optional) - Saved payment methods

## 2. Products Node

**Path:** `/products/{productId}`

```json
{
  "products": {
    "prod001": {
      "name": "Aspirin 500mg",
      "description": "Pain reliever and fever reducer",
      "price": 9.99,
      "category": "medicine",
      "categoryName": "Medicine",
      "stock": 100,
      "barcode": "8901234567890",
      "imageUrl": "https://storage.googleapis.com/pharmacy-app/products/prod001.jpg",
      "requiresPrescription": false,
      "manufacturer": "PharmaCorp",
      "expiryDate": "2026-12-31",
      "dosage": "500mg tablets",
      "createdAt": 1700000000000,
      "updatedAt": 1700100000000,
      "active": true
    }
  }
}
```

**Fields:**
- `name` (string) - Product name
- `description` (string) - Product description
- `price` (number) - Price in USD/PHP
- `category` (string) - Category ID
- `categoryName` (string) - Denormalized for display
- `stock` (number) - Available quantity
- `barcode` (string, optional) - Product barcode
- `imageUrl` (string, optional) - Product image URL
- `requiresPrescription` (boolean) - Requires prescription?
- `manufacturer` (string, optional) - Manufacturer name
- `expiryDate` (string, optional) - Expiry date (YYYY-MM-DD)
- `dosage` (string, optional) - Dosage information
- `createdAt` (timestamp) - Product creation time
- `updatedAt` (timestamp) - Last update time
- `active` (boolean) - Is product active/visible?

## 3. Orders Node

**Path:** `/orders/{orderId}`

```json
{
  "orders": {
    "order001": {
      "userId": "user123abc",
      "userName": "John Doe",
      "userEmail": "john@example.com",
      "items": {
        "prod001": {
          "name": "Aspirin 500mg",
          "quantity": 2,
          "price": 9.99,
          "subtotal": 19.98
        },
        "prod002": {
          "name": "Vitamin C 1000mg",
          "quantity": 1,
          "price": 15.99,
          "subtotal": 15.99
        }
      },
      "subtotal": 35.97,
      "tax": 3.60,
      "shipping": 5.00,
      "total": 44.57,
      "status": "pending",
      "paymentMethod": "card",
      "paymentStatus": "paid",
      "shippingAddress": {
        "name": "John Doe",
        "street": "123 Main St",
        "city": "Manila",
        "zipCode": "1000",
        "phone": "+1234567890"
      },
      "trackingNumber": "TRACK123456",
      "notes": "Leave at door",
      "createdAt": 1700000000000,
      "updatedAt": 1700100000000
    }
  }
}
```

**Fields:**
- `userId` (string) - User ID reference
- `userName` (string) - Denormalized user name
- `userEmail` (string) - Denormalized user email
- `items` (object) - Order items with product details
- `subtotal` (number) - Items total before tax/shipping
- `tax` (number) - Tax amount
- `shipping` (number) - Shipping cost
- `total` (number) - Final total
- `status` (string) - "pending" | "processing" | "shipped" | "delivered" | "cancelled"
- `paymentMethod` (string) - Payment method used
- `paymentStatus` (string) - "pending" | "paid" | "failed" | "refunded"
- `shippingAddress` (object) - Delivery address
- `trackingNumber` (string, optional) - Shipping tracking number
- `notes` (string, optional) - Order notes
- `createdAt` (timestamp) - Order creation time
- `updatedAt` (timestamp) - Last status update

## 4. Prescriptions Node

**Path:** `/prescriptions/{prescriptionId}`

```json
{
  "prescriptions": {
    "rx001": {
      "userId": "user123abc",
      "userName": "John Doe",
      "userEmail": "john@example.com",
      "imageUrl": "gs://pharmacy-app/prescriptions/rx001.jpg",
      "thumbnailUrl": "gs://pharmacy-app/prescriptions/rx001_thumb.jpg",
      "status": "pending",
      "notes": "",
      "adminNotes": "Approved by Dr. Smith",
      "reviewedBy": "admin456",
      "reviewedAt": 1700100000000,
      "createdAt": 1700000000000,
      "updatedAt": 1700100000000
    }
  }
}
```

**Fields:**
- `userId` (string) - User ID reference
- `userName` (string) - Denormalized user name
- `userEmail` (string) - Denormalized email
- `imageUrl` (string) - Firebase Storage URL for prescription image
- `thumbnailUrl` (string, optional) - Thumbnail image
- `status` (string) - "pending" | "approved" | "rejected"
- `notes` (string, optional) - User notes
- `adminNotes` (string, optional) - Admin/pharmacist notes
- `reviewedBy` (string, optional) - Admin user ID who reviewed
- `reviewedAt` (timestamp, optional) - Review timestamp
- `createdAt` (timestamp) - Upload time
- `updatedAt` (timestamp) - Last update time

## 5. Categories Node

**Path:** `/categories/{categoryId}`

```json
{
  "categories": {
    "medicine": {
      "name": "Medicine",
      "icon": "medical_services",
      "description": "Prescription and over-the-counter medicines",
      "order": 1,
      "active": true
    },
    "devices": {
      "name": "Medical Devices",
      "icon": "devices",
      "description": "Thermometers, blood pressure monitors, etc.",
      "order": 2,
      "active": true
    },
    "skincare": {
      "name": "Skin Care",
      "icon": "face",
      "description": "Skincare products and cosmetics",
      "order": 3,
      "active": true
    },
    "wellness": {
      "name": "Wellness",
      "icon": "spa",
      "description": "Vitamins, supplements, and wellness products",
      "order": 4,
      "active": true
    }
  }
}
```

**Fields:**
- `name` (string) - Category name
- `icon` (string) - Material icon name
- `description` (string) - Category description
- `order` (number) - Display order
- `active` (boolean) - Is category active?

## 6. Index Nodes

### 6.1 User Orders Index

**Path:** `/userOrders/{userId}/{orderId}`

```json
{
  "userOrders": {
    "user123abc": {
      "order001": true,
      "order002": true,
      "order003": true
    }
  }
}
```

**Purpose:** Efficiently query all orders for a specific user

**Query:**
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('userOrders/$userId');
```

### 6.2 Products by Category Index

**Path:** `/productsByCategory/{categoryId}/{productId}`

```json
{
  "productsByCategory": {
    "medicine": {
      "prod001": true,
      "prod002": true
    },
    "wellness": {
      "prod003": true,
      "prod004": true
    }
  }
}
```

**Purpose:** Efficiently query products by category

**Query:**
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('productsByCategory/medicine');
```

## 7. Stats Node (Admin Dashboard)

**Path:** `/stats/{date}`

```json
{
  "stats": {
    "2024-11-26": {
      "totalSales": 1250.50,
      "totalOrders": 25,
      "totalUsers": 150,
      "totalProducts": 85,
      "ordersByStatus": {
        "pending": 5,
        "processing": 8,
        "shipped": 7,
        "delivered": 5
      },
      "topProducts": {
        "prod001": 15,
        "prod002": 12,
        "prod003": 10
      }
    }
  }
}
```

**Purpose:** Pre-computed statistics for admin dashboard

## Data Duplication Strategy

### When Creating an Order:
1. Write to `/orders/{orderId}` with full order details
2. Write to `/userOrders/{userId}/{orderId} = true`
3. Update `/stats/{date}` with aggregated numbers

### When Updating Product:
1. Update `/products/{productId}`
2. If category changed, update `/productsByCategory`
3. Consider updating existing orders (optional, depends on requirement)

### When User Changes Name:
1. Update `/users/{userId}/name`
2. **Do NOT update** existing orders (historical record)
3. New orders will get updated name

## Query Patterns

### Get All Products
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('products');
DataSnapshot snapshot = await ref.get();
```

### Get Products by Category
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('productsByCategory/medicine');
DataSnapshot snapshot = await ref.get();
// Then fetch each product by ID
```

### Get User's Orders
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('userOrders/$userId');
DataSnapshot snapshot = await ref.get();
// Then fetch each order by ID
```

### Get Single Product
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('products/$productId');
DataSnapshot snapshot = await ref.get();
```

### Real-time Listener for Products
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('products');
ref.onValue.listen((event) {
  // UI updates automatically
});
```

### Query with Filters
```dart
// Get products under $10
DatabaseReference ref = FirebaseDatabase.instance.ref('products');
Query query = ref.orderByChild('price').endAt(10.0);
DataSnapshot snapshot = await query.get();
```

## Size Considerations

### Shallow Queries
When you only need IDs, use shallow queries:
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref('products');
DataSnapshot snapshot = await ref.get();
// Add ?shallow=true to URL for REST API
```

### Pagination
For large datasets, implement pagination:
```dart
Query query = ref.orderByKey().limitToFirst(20);
// Get last key, then query startAfter(lastKey)
```

## Backup Strategy

### Daily Export
Use Firebase Console → Realtime Database → Export to JSON

### Programmatic Backup
```dart
DatabaseReference ref = FirebaseDatabase.instance.ref();
DataSnapshot snapshot = await ref.get();
String jsonData = jsonEncode(snapshot.value);
// Save to file or cloud storage
```

## Migration from PostgreSQL

### Data Transformation
1. Export PostgreSQL data to JSON
2. Transform relational structure to denormalized format
3. Generate Firebase push IDs or use existing IDs
4. Import to Firebase using Admin SDK or REST API

### Example: Products Migration
```javascript
// Node.js script
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.database();

// For each product from PostgreSQL
products.forEach(product => {
  db.ref(`products/${product.id}`).set({
    name: product.name,
    price: product.price,
    category: product.category_id,
    categoryName: categories[product.category_id].name, // Denormalize
    stock: product.stock,
    // ... other fields
  });
  
  // Create index
  db.ref(`productsByCategory/${product.category_id}/${product.id}`).set(true);
});
```

## Next Steps

1. ✅ Database structure defined
2. 🔄 Write Firebase Security Rules (next)
3. 🔄 Implement Firebase Service Layer
4. 🔄 Update Authentication Service
5. 🔄 Migrate UI Screens
