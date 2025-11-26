/// Service providing mock data when backend is unavailable
/// Used for offline/demo mode testing
class OfflineDataService {
  static final List<dynamic> mockProducts = [
    {
      'id': '1',
      'name': 'Paracetamol',
      'description': 'Pain reliever and fever reducer',
      'dosage': '500mg',
      'category': 'Pain Relief',
      'price': 5.99,
      'quantity': 150,
      'supplier': 'PharmaCorp',
      'imageUrl': 'https://via.placeholder.com/150?text=Paracetamol',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
    },
    {
      'id': '2',
      'name': 'Ibuprofen',
      'description': 'Anti-inflammatory pain reliever',
      'dosage': '200mg',
      'category': 'Pain Relief',
      'price': 6.99,
      'quantity': 200,
      'supplier': 'MediCare',
      'imageUrl': 'https://via.placeholder.com/150?text=Ibuprofen',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 25))
          .toIso8601String(),
    },
    {
      'id': '3',
      'name': 'Vitamin C',
      'description': 'Immune system support',
      'dosage': '1000mg',
      'category': 'Vitamins',
      'price': 8.99,
      'quantity': 300,
      'supplier': 'NutriHealth',
      'imageUrl': 'https://via.placeholder.com/150?text=Vitamin+C',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 20))
          .toIso8601String(),
    },
  ];

  static final List<dynamic> mockUsers = [
    {
      'id': '1',
      'email': 'admin@pharmacy.com',
      'name': 'Admin User',
      'role': 'admin',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String(),
      'orders': [],
    },
    {
      'id': '2',
      'email': 'john@example.com',
      'name': 'John Doe',
      'role': 'customer',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String(),
      'orders': [1, 2],
    },
    {
      'id': '3',
      'email': 'jane@example.com',
      'name': 'Jane Smith',
      'role': 'customer',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'orders': [3],
    },
  ];

  static final List<dynamic> mockOrders = [
    {
      'id': '1',
      'userId': '2',
      'user': {'id': '2', 'email': 'john@example.com', 'name': 'John Doe'},
      'items': [
        {'name': 'Paracetamol', 'quantity': 2},
        {'name': 'Vitamin C', 'quantity': 1},
      ],
      'total': 21.97,
      'status': 'delivered',
      'address': '123 Main St, City',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 15))
          .toIso8601String(),
    },
    {
      'id': '2',
      'userId': '2',
      'user': {'id': '2', 'email': 'john@example.com', 'name': 'John Doe'},
      'items': [
        {'name': 'Ibuprofen', 'quantity': 1},
      ],
      'total': 6.99,
      'status': 'shipped',
      'address': '123 Main St, City',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    },
    {
      'id': '3',
      'userId': '3',
      'user': {'id': '3', 'email': 'jane@example.com', 'name': 'Jane Smith'},
      'items': [
        {'name': 'Paracetamol', 'quantity': 3},
      ],
      'total': 17.97,
      'status': 'pending',
      'address': '456 Oak Ave, Town',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
  ];

  static final List<dynamic> mockInventory = [
    {
      'id': '1',
      'name': 'Paracetamol',
      'dosage': '500mg',
      'quantity': 150,
      'supplier': 'PharmaCorp',
      'expiryDate': DateTime.now()
          .add(const Duration(days: 180))
          .toIso8601String(),
      'status': 'in_stock',
    },
    {
      'id': '2',
      'name': 'Ibuprofen',
      'dosage': '200mg',
      'quantity': 5,
      'supplier': 'MediCare',
      'expiryDate': DateTime.now()
          .add(const Duration(days: 120))
          .toIso8601String(),
      'status': 'low_stock',
    },
    {
      'id': '3',
      'name': 'Vitamin C',
      'dosage': '1000mg',
      'quantity': 300,
      'supplier': 'NutriHealth',
      'expiryDate': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
      'status': 'expired',
    },
  ];

  /// Get all mock products
  static List<dynamic> getProducts() {
    return List.from(mockProducts);
  }

  /// Get all mock users
  static List<dynamic> getUsers() {
    return List.from(mockUsers);
  }

  /// Get all mock orders
  static List<dynamic> getOrders() {
    return List.from(mockOrders);
  }

  /// Get all mock inventory items
  static List<dynamic> getInventory() {
    return List.from(mockInventory);
  }
}
