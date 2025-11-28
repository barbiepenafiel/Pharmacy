// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'order_tracker_screen.dart';
import 'stripe_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  void _updateQuantity(String itemId, int quantity) {
    setState(() {
      _cartService.updateQuantity(itemId, quantity);
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _cartService.removeItem(itemId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Shopping Cart'),
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Continue Shopping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Image
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? (item.imageUrl!.startsWith('http')
                                          ? Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey.shade400,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey.shade400,
                                            ))
                                    : Icon(
                                        Icons.medication,
                                        size: 35,
                                        color: Colors.teal.shade700,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              // Product Details
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₱${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantity Controls
                              SizedBox(
                                width: 75,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 28,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: item.quantity > 1
                                                  ? () => _updateQuantity(
                                                      item.id,
                                                      item.quantity - 1,
                                                    )
                                                  : null,
                                              iconSize: 14,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => _updateQuantity(
                                                item.id,
                                                item.quantity + 1,
                                              ),
                                              iconSize: 14,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${(item.price * item.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete Button
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeItem(item.id),
                                  iconSize: 18,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Cart Summary and Checkout
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '₱${_cartService.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shipping:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '₱50.00',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₱${(_cartService.totalPrice + 50).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Checkout Screen
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedAddress = '';
  String _selectedPaymentMethod = 'stripe';
  bool _agreedToTerms = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _userAddresses = [];
  bool _loadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
  }

  Future<void> _loadUserAddresses() async {
    try {
      final addresses = await _firebaseService.getUserAddresses();
      setState(() {
        _userAddresses = addresses;
        _loadingAddresses = false;
        // Set first address as default, or first default address
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (addr) => addr['isDefault'] == true,
            orElse: () => addresses.first,
          );
          _selectedAddress = defaultAddr['id'] ?? '';
        }
      });
    } catch (e) {
      setState(() => _loadingAddresses = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading addresses: $e')));
      }
    }
  }

  final List<Map<String, String>> _paymentMethods = [
    {'label': 'Stripe (Credit/Debit Card)', 'value': 'stripe'},
    {'label': 'GCash', 'value': 'gcash'},
    {'label': 'Cash on Delivery', 'value': 'cod'},
  ];

  void _processPayment() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    // Get selected address details
    final selectedAddressData = _userAddresses.firstWhere(
      (addr) => addr['id'] == _selectedAddress,
      orElse: () => {},
    );

    if (selectedAddressData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid address selected')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Get current user
      final authService = AuthService();
      final user = authService.currentFirebaseUser;

      if (user == null) {
        throw Exception('Please login to place an order');
      }

      // Get user profile for denormalized data
      final userData = await authService.getCurrentUser();
      final userName = userData?['name'] ?? 'Guest User';
      final userEmail = user.email ?? '';

      final subtotal = _cartService.totalPrice;
      final shipping = 50.0;
      final total = subtotal + shipping;

      // Prepare order items
      final orderItems = _cartService.items
          .map(
            (item) => {
              'productId': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'subtotal': item.price * item.quantity,
            },
          )
          .toList();

      // Format delivery address
      final deliveryAddress =
          '${selectedAddressData['address']}, ${selectedAddressData['city']}';

      // Create order in Firebase
      final firebaseService = FirebaseService();
      final orderId = await firebaseService.createOrder({
        'items': orderItems,
        'total': total,
        'subtotal': subtotal,
        'shippingFee': shipping,
        'status': _selectedPaymentMethod == 'stripe'
            ? 'pending_payment'
            : 'pending',
        'deliveryAddress': deliveryAddress,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'stripe'
            ? 'pending'
            : 'not_required',
        // Denormalized user data for efficient queries
        'userName': userName,
        'userEmail': userEmail,
      });

      // Decrease inventory immediately after order is created
      await firebaseService.decreaseInventoryForOrder(orderItems);

      // Handle different payment methods
      if (_selectedPaymentMethod == 'stripe') {
        // Navigate to Stripe payment screen
        setState(() => _isProcessing = false);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StripePaymentScreen(
                amount: total,
                orderId: orderId,
                deliveryAddress: deliveryAddress,
                onPaymentSuccess: () {
                  // Payment successful - update order status
                  _firebaseService.updateOrderStatus(orderId, 'paid');
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderTrackerScreen(
                        orderId: orderId,
                        totalAmount: total,
                        deliveryAddress: deliveryAddress,
                        paymentMethod: _selectedPaymentMethod,
                        items: _cartService.items
                            .map(
                              (item) => {
                                'id': item.id,
                                'name': item.name,
                                'price': item.price,
                                'quantity': item.quantity,
                              },
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
                onPaymentError: (error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else if (_selectedPaymentMethod == 'cod') {
        // Cash on Delivery - Order is confirmed immediately
        _cartService.clearCart();

        setState(() => _isProcessing = false);

        // Navigate to Order Tracker
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackerScreen(
                orderId: orderId,
                totalAmount: total,
                deliveryAddress: deliveryAddress,
                paymentMethod: _selectedPaymentMethod,
                items: _cartService.items
                    .map(
                      (item) => {
                        'id': item.id,
                        'name': item.name,
                        'price': item.price,
                        'quantity': item.quantity,
                      },
                    )
                    .toList(),
              ),
            ),
          );
        }
      } else {
        // GCash and other methods
        _cartService.clearCart();

        setState(() => _isProcessing = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order created! Please complete payment via $_selectedPaymentMethod',
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackerScreen(
                orderId: orderId,
                totalAmount: total,
                deliveryAddress: deliveryAddress,
                paymentMethod: _selectedPaymentMethod,
                items: _cartService.items
                    .map(
                      (item) => {
                        'id': item.id,
                        'name': item.name,
                        'price': item.price,
                        'quantity': item.quantity,
                      },
                    )
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _cartService.totalPrice;
    final shipping = 50.0;
    final total = subtotal + shipping;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Delivery Address
            _buildSection(
              title: 'Delivery Address',
              child: _loadingAddresses
                  ? const Center(child: CircularProgressIndicator())
                  : _userAddresses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'No saved addresses. Please add one in your profile.',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _userAddresses
                          .map(
                            (addr) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAddress = addr['id'] ?? '';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: addr['id'] ?? '',
                                      groupValue: _selectedAddress,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAddress = value ?? '';
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                addr['type'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (addr['isDefault'] ?? false)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Default',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.teal.shade700,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${addr['address'] ?? ''}, ${addr['city'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            addr['phone'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            // Payment Method
            _buildSection(
              title: 'Payment Method',
              child: Column(
                children: _paymentMethods
                    .map(
                      (method) => GestureDetector(
                        onTap: () {
                          setState(
                            () => _selectedPaymentMethod = method['value']!,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: method['value']!,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(
                                    () => _selectedPaymentMethod =
                                        value ?? 'stripe',
                                  );
                                },
                              ),
                              Text(method['label']!),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Order Summary
            _buildSection(
              title: 'Order Summary',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₱${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shipping:'),
                      Text('₱${shipping.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Terms and Conditions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CheckboxListTile(
                title: const Text(
                  'I agree to the terms and conditions',
                  style: TextStyle(fontSize: 12),
                ),
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() => _agreedToTerms = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Place Order Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
