// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../services/cart_service.dart';

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
  String _selectedAddress = 'Home';
  String _selectedPaymentMethod = 'Credit Card';
  bool _agreedToTerms = false;
  bool _isProcessing = false;

  final List<Map<String, String>> _addresses = [
    {'label': 'Home', 'value': '123 Main St, Manila, NCR 1000'},
    {'label': 'Office', 'value': '456 Business Ave, Makati, NCR 1200'},
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'label': 'Credit Card', 'icon': 'credit_card'},
    {'label': 'Debit Card', 'icon': 'payment'},
    {'label': 'GCash', 'icon': 'phone_android'},
    {'label': 'Cash on Delivery', 'icon': 'local_shipping'},
  ];

  void _processPayment() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isProcessing = false);

    if (!mounted) return;

    _cartService.clearCart();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thank you for your purchase!'),
            const SizedBox(height: 16),
            Text(
              'Order #: ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₱${(_cartService.totalPrice + 50).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order will be delivered within 2-3 business days.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close checkout
              Navigator.pop(context); // Close cart
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
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
              child: Column(
                children: _addresses
                    .map(
                      (addr) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedAddress = addr['label']!);
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
                                value: addr['label']!,
                                groupValue: _selectedAddress,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(addr['label']!),
                                    Text(
                                      addr['value']!,
                                      style: const TextStyle(
                                        fontSize: 12,
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
                            () => _selectedPaymentMethod = method['label']!,
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
                                value: method['label']!,
                                groupValue: _selectedPaymentMethod,
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
