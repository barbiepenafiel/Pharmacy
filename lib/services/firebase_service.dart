import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'dart:io';
import 'logger_service.dart';

/// Firebase Service Layer
/// Provides CRUD operations and real-time listeners for all database entities
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== PRODUCTS ====================

  /// Get all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final snapshot = await _database.child('products').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) {
            final product = Map<String, dynamic>.from(entry.value as Map);
            product['id'] = entry.key;
            return product;
          })
          .where((product) => product['active'] == true)
          .toList();
    } catch (e) {
      logger.error('Error getting products: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    try {
      // First get product IDs from index
      final indexSnapshot = await _database
          .child('productsByCategory/$category')
          .get();
      if (!indexSnapshot.exists) return [];

      final Map<dynamic, dynamic> productIds =
          indexSnapshot.value as Map<dynamic, dynamic>;

      // Then fetch each product
      final List<Map<String, dynamic>> products = [];
      for (var productId in productIds.keys) {
        final productSnapshot = await _database
            .child('products/$productId')
            .get();
        if (productSnapshot.exists) {
          final product = Map<String, dynamic>.from(
            productSnapshot.value as Map,
          );
          product['id'] = productId;
          if (product['active'] == true) {
            products.add(product);
          }
        }
      }
      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Get single product by ID
  Future<Map<String, dynamic>?> getProduct(String productId) async {
    try {
      final snapshot = await _database.child('products/$productId').get();
      if (!snapshot.exists) return null;

      final product = Map<String, dynamic>.from(snapshot.value as Map);
      product['id'] = productId;
      return product;
    } catch (e) {
      rethrow;
    }
  }

  /// Get product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final query = _database
          .child('products')
          .orderByChild('barcode')
          .equalTo(barcode);
      final snapshot = await query.get();

      if (!snapshot.exists) return null;

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final entry = data.entries.first;
      final product = Map<String, dynamic>.from(entry.value as Map);
      product['id'] = entry.key;
      return product;
    } catch (e) {
      rethrow;
    }
  }

  /// Create product (admin only)
  Future<String> createProduct(Map<String, dynamic> productData) async {
    try {
      final productRef = _database.child('products').push();
      final productId = productRef.key!;

      // Add metadata
      productData['createdAt'] = ServerValue.timestamp;
      productData['updatedAt'] = ServerValue.timestamp;
      productData['active'] = true;

      await productRef.set(productData);

      // Update category index
      if (productData['category'] != null) {
        await _database
            .child('productsByCategory/${productData['category']}/$productId')
            .set(true);
      }

      return productId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update product (admin only)
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = ServerValue.timestamp;
      await _database.child('products/$productId').update(updates);

      // If category changed, update index
      if (updates.containsKey('category')) {
        // Note: This is simplified. In production, you'd need to:
        // 1. Get old category from current product
        // 2. Remove from old category index
        // 3. Add to new category index
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete product (admin only) - soft delete
  Future<void> deleteProduct(String productId) async {
    try {
      await _database.child('products/$productId').update({
        'active': false,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Real-time listener for products
  Stream<List<Map<String, dynamic>>> watchProducts() {
    return _database.child('products').onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) {
            final product = Map<String, dynamic>.from(entry.value as Map);
            product['id'] = entry.key;
            return product;
          })
          .where((product) => product['active'] == true)
          .toList();
    });
  }

  /// Get all products (one-time fetch for search)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final snapshot = await _database.child('products').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) {
            final product = Map<String, dynamic>.from(entry.value as Map);
            product['id'] = entry.key;
            return product;
          })
          .where((product) => product['active'] == true)
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Real-time listener for products by category
  Stream<List<Map<String, dynamic>>> watchProductsByCategory(String category) {
    return _database.child('products').onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) {
            final product = Map<String, dynamic>.from(entry.value as Map);
            product['id'] = entry.key;
            return product;
          })
          .where(
            (product) =>
                product['active'] == true &&
                product['category']?.toString().toLowerCase() ==
                    category.toLowerCase(),
          )
          .toList();
    });
  }

  // ==================== ORDERS ====================

  /// Create order
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderRef = _database.child('orders').push();
      final orderId = orderRef.key!;

      // Add metadata
      orderData['userId'] = user.uid;
      orderData['createdAt'] = ServerValue.timestamp;
      orderData['updatedAt'] = ServerValue.timestamp;

      // Use atomic update to write both order and index
      final updates = <String, dynamic>{
        'orders/$orderId': orderData,
        'userOrders/${user.uid}/$orderId': true,
      };

      // Decrease inventory for each item in the order
      final dynamic itemsData = orderData['items'];
      if (itemsData != null) {
        if (itemsData is List) {
          // If items is a List
          for (var item in itemsData) {
            if (item is Map) {
              final productId = item['id'];
              final quantity = item['quantity'] ?? 1;
              if (productId != null) {
                // Get current product quantity
                final productSnapshot = await _database
                    .child('products/$productId')
                    .get();
                if (productSnapshot.exists) {
                  final product = productSnapshot.value as Map;
                  final currentQuantity = (product['quantity'] ?? 0) as int;
                  final newQuantity = (currentQuantity - quantity).clamp(
                    0,
                    999999,
                  );
                  updates['products/$productId/quantity'] = newQuantity;
                }
              }
            }
          }
        } else if (itemsData is Map) {
          // If items is a Map (Firebase key-value format)
          itemsData.forEach((productId, item) {
            if (item is Map) {
              final quantity = (item['quantity'] ?? 1) as int;
              // Get current product quantity
              _database.child('products/$productId').get().then((snapshot) {
                if (snapshot.exists) {
                  final product = snapshot.value as Map;
                  final currentQuantity = (product['quantity'] ?? 0) as int;
                  final newQuantity = (currentQuantity - quantity).clamp(
                    0,
                    999999,
                  );
                  updates['products/$productId/quantity'] = newQuantity;
                }
              });
            }
          });
        }
      }

      await _database.update(updates);

      return orderId;
    } catch (e) {
      rethrow;
    }
  }

  /// Decrease product quantity (called after order)
  Future<void> decreaseProductQuantity(String productId, int quantity) async {
    try {
      final productSnapshot = await _database
          .child('products/$productId')
          .get();
      if (productSnapshot.exists) {
        final product = productSnapshot.value as Map;
        final currentQuantity = (product['quantity'] ?? 0) as int;
        final newQuantity = (currentQuantity - quantity).clamp(0, 999999);

        await _database.child('products/$productId/quantity').set(newQuantity);
      }
    } catch (e) {
      logger.error('Error decreasing product quantity: $e');
      rethrow;
    }
  }

  /// Get user's orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get order IDs from index
      final indexSnapshot = await _database
          .child('userOrders/${user.uid}')
          .get();
      if (!indexSnapshot.exists) return [];

      final Map<dynamic, dynamic> orderIds =
          indexSnapshot.value as Map<dynamic, dynamic>;

      // Fetch each order
      final List<Map<String, dynamic>> orders = [];
      for (var orderId in orderIds.keys) {
        final orderSnapshot = await _database.child('orders/$orderId').get();
        if (orderSnapshot.exists) {
          final order = Map<String, dynamic>.from(orderSnapshot.value as Map);
          order['id'] = orderId;
          orders.add(order);
        }
      }

      // Sort by creation date (newest first)
      orders.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Get single order
  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final snapshot = await _database.child('orders/$orderId').get();
      if (!snapshot.exists) return null;

      final order = Map<String, dynamic>.from(snapshot.value as Map);
      order['id'] = orderId;
      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Watch single order for real-time updates
  Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _database.child('orders/$orderId').onValue.map((event) {
      if (!event.snapshot.exists) return null;

      try {
        final data = event.snapshot.value;
        if (data == null) return null;

        // Safely convert Firebase's Map<Object?, Object?> to Map<String, dynamic>
        final order = _convertToStringDynamicMap(data);
        order['id'] = orderId;

        return order;
      } catch (e) {
        return null;
      }
    });
  }

  /// Helper function to safely convert Firebase data to `Map<String, dynamic>`
  Map<String, dynamic> _convertToStringDynamicMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key.toString();
        result[stringKey] = _convertValue(value);
      });
      return result;
    }

    return {};
  }

  /// Recursively convert values to proper types
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertToStringDynamicMap(value);
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    } else {
      return value;
    }
  }

  /// Update order status (admin or owner)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _database.child('orders/$orderId').update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Real-time listener for user's orders
  Stream<List<Map<String, dynamic>>> watchUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database.child('userOrders/${user.uid}').onValue.asyncMap((
      event,
    ) async {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> orderIds =
          event.snapshot.value as Map<dynamic, dynamic>;

      final List<Map<String, dynamic>> orders = [];
      for (var orderId in orderIds.keys) {
        final orderSnapshot = await _database.child('orders/$orderId').get();
        if (orderSnapshot.exists) {
          final order = Map<String, dynamic>.from(orderSnapshot.value as Map);
          order['id'] = orderId;
          orders.add(order);
        }
      }

      orders.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return orders;
    });
  }

  // ==================== PRESCRIPTIONS ====================

  /// Upload prescription image to Firebase Storage
  Future<String> uploadPrescriptionImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(
        'prescriptions/${user.uid}/$fileName',
      );

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Create prescription
  Future<String> createPrescription(
    Map<String, dynamic> prescriptionData,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final prescriptionRef = _database.child('prescriptions').push();
      final prescriptionId = prescriptionRef.key!;

      // Add metadata
      prescriptionData['userId'] = user.uid;
      prescriptionData['status'] = 'pending';
      prescriptionData['createdAt'] = ServerValue.timestamp;
      prescriptionData['updatedAt'] = ServerValue.timestamp;

      await prescriptionRef.set(prescriptionData);

      return prescriptionId;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's prescriptions
  Future<List<Map<String, dynamic>>> getUserPrescriptions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = _database
          .child('prescriptions')
          .orderByChild('userId')
          .equalTo(user.uid);
      final snapshot = await query.get();

      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final prescriptions = data.entries.map((entry) {
        final prescription = Map<String, dynamic>.from(entry.value as Map);
        prescription['id'] = entry.key;
        return prescription;
      }).toList();

      prescriptions.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return prescriptions;
    } catch (e) {
      rethrow;
    }
  }

  /// Watch user's prescriptions for real-time updates
  Stream<List<Map<String, dynamic>>> watchUserPrescriptions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _database
        .child('prescriptions')
        .orderByChild('userId')
        .equalTo(user.uid)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <Map<String, dynamic>>[];

          final Map<dynamic, dynamic> data =
              event.snapshot.value as Map<dynamic, dynamic>;
          final prescriptions = data.entries.map((entry) {
            final prescription = Map<String, dynamic>.from(entry.value as Map);
            prescription['id'] = entry.key;
            return prescription;
          }).toList();

          prescriptions.sort(
            (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
          );
          return prescriptions;
        });
  }

  /// Update prescription status (admin only)
  Future<void> updatePrescriptionStatus(
    String prescriptionId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = {
        'status': status,
        'updatedAt': ServerValue.timestamp,
        'reviewedBy': user.uid,
        'reviewedAt': ServerValue.timestamp,
      };

      if (adminNotes != null) {
        updates['adminNotes'] = adminNotes;
      }

      await _database.child('prescriptions/$prescriptionId').update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final snapshot = await _database.child('categories').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final categories = data.entries
          .map((entry) {
            final category = Map<String, dynamic>.from(entry.value as Map);
            category['id'] = entry.key;
            return category;
          })
          .where((cat) => cat['active'] == true)
          .toList();

      // Sort by order field
      categories.sort(
        (a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999),
      );
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USERS ====================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      if (!snapshot.exists) return null;

      final user = Map<String, dynamic>.from(snapshot.value as Map);
      user['id'] = userId;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Create or update user profile
  Future<void> setUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final snapshot = await _database.child('users/$userId').get();

      if (!snapshot.exists) {
        // New user - add createdAt
        userData['createdAt'] = ServerValue.timestamp;
      }

      userData['lastLogin'] = ServerValue.timestamp;
      await _database.child('users/$userId').set(userData);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _database.child('users/$userId').update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USER ADDRESSES ====================

  /// Get user addresses
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _database
          .child('users/${user.uid}/addresses')
          .get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final address = Map<String, dynamic>.from(entry.value as Map);
        address['id'] = entry.key;
        return address;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new address
  Future<String> addAddress(Map<String, dynamic> addressData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final newAddressRef = _database
          .child('users/${user.uid}/addresses')
          .push();

      await newAddressRef.set(addressData);
      return newAddressRef.key!;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an address
  Future<void> updateAddress(
    String addressId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _database
          .child('users/${user.uid}/addresses/$addressId')
          .update(updates);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _database.child('users/${user.uid}/addresses/$addressId').remove();
    } catch (e) {
      logger.error('Error deleting address: $e');
      rethrow;
    }
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, unset all addresses as default
      final snapshot = await _database
          .child('users/${user.uid}/addresses')
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        for (var key in data.keys) {
          await _database.child('users/${user.uid}/addresses/$key').update({
            'isDefault': false,
          });
        }
      }

      // Then set the selected address as default
      await _database.child('users/${user.uid}/addresses/$addressId').update({
        'isDefault': true,
      });
    } catch (e) {
      logger.error('Error setting default address: $e');
      rethrow;
    }
  }

  // ==================== ADMIN ====================

  /// Get all orders (admin only)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot = await _database.child('orders').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final orders = data.entries.map((entry) {
        final order = Map<String, dynamic>.from(entry.value as Map);
        order['id'] = entry.key;
        return order;
      }).toList();

      orders.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return orders;
    } catch (e) {
      logger.error('Error getting all orders: $e');
      rethrow;
    }
  }

  /// Get all prescriptions (admin only)
  Future<List<Map<String, dynamic>>> getAllPrescriptions() async {
    try {
      final snapshot = await _database.child('prescriptions').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final prescriptions = data.entries.map((entry) {
        final prescription = Map<String, dynamic>.from(entry.value as Map);
        prescription['id'] = entry.key;
        return prescription;
      }).toList();

      prescriptions.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return prescriptions;
    } catch (e) {
      logger.error('Error getting all prescriptions: $e');
      rethrow;
    }
  }

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final user = Map<String, dynamic>.from(entry.value as Map);
        user['id'] = entry.key;
        return user;
      }).toList();
    } catch (e) {
      logger.error('Error getting all users: $e');
      rethrow;
    }
  }

  /// Watch all orders (admin real-time dashboard)
  Stream<List<Map<String, dynamic>>> watchAllOrders() {
    return _database.child('orders').onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final orders = data.entries.map((entry) {
        final order = Map<String, dynamic>.from(entry.value as Map);
        order['id'] = entry.key;
        return order;
      }).toList();

      orders.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return orders;
    });
  }

  /// Watch all prescriptions (admin real-time dashboard)
  Stream<List<Map<String, dynamic>>> watchAllPrescriptions() {
    return _database.child('prescriptions').onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final prescriptions = data.entries.map((entry) {
        final prescription = Map<String, dynamic>.from(entry.value as Map);
        prescription['id'] = entry.key;
        return prescription;
      }).toList();

      prescriptions.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );
      return prescriptions;
    });
  }

  /// Watch all users (admin real-time dashboard)
  Stream<List<Map<String, dynamic>>> watchAllUsers() {
    return _database.child('users').onValue.map((event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final user = Map<String, dynamic>.from(entry.value as Map);
        user['id'] = entry.key;
        return user;
      }).toList();
    });
  }

  /// Update user data (admin)
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _database.child('users/$userId').update(userData);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user (admin)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user data from database
      await _database.child('users/$userId').remove();

      // Note: Deleting Firebase Auth user requires admin SDK
      // For now, we only delete the database record
      // The auth account will remain but be inaccessible without data
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Delete order (admin)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _database.child('orders/$orderId').remove();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // ==================== UTILITIES ====================

  /// Get statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _database.child('stats').get();
      if (!snapshot.exists) {
        // Return default stats if not found
        return {
          'totalUsers': 0,
          'totalOrders': 0,
          'totalSales': 0.0,
          'totalPrescriptions': 0,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };
      }
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      // ignore: avoid_print
      logger.error('Error getting stats: $e');
      return {
        'totalUsers': 0,
        'totalOrders': 0,
        'totalSales': 0.0,
        'totalPrescriptions': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database.child('users/${user.uid}/role').get();
      return snapshot.exists && snapshot.value == 'admin';
    } catch (e) {
      // ignore: avoid_print
      logger.error('Error checking admin status: $e');
      return false;
    }
  }

  /// Disconnect from database
  void dispose() {
    // Cancel any active listeners if needed
  }
}
