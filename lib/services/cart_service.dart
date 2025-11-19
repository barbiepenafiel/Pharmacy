import 'dart:convert';

class CartItem {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartService {
  static final CartService _instance = CartService._internal();
  final List<CartItem> _cartItems = [];

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  List<CartItem> get items => _cartItems;

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addItem(CartItem item) {
    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.id == item.id,
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
  }

  void removeItem(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final item = _cartItems.firstWhere(
      (cartItem) => cartItem.id == itemId,
      orElse: () => CartItem(id: '', name: '', price: 0, quantity: 0),
    );
    if (item.id.isNotEmpty) {
      item.quantity = quantity;
    }
  }

  void clearCart() {
    _cartItems.clear();
  }

  String toJson() {
    return jsonEncode(_cartItems.map((item) => item.toMap()).toList());
  }

  void fromJson(String json) {
    _cartItems.clear();
    try {
      final List<dynamic> decoded = jsonDecode(json);
      for (final item in decoded) {
        _cartItems.add(CartItem.fromMap(item));
      }
    } catch (e) {
      // Error loading cart from JSON
    }
  }
}
