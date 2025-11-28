import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 1,
      'type': 'Stripe',
      'card': '**** **** **** 1234',
      'holder': 'Barbie Penafiel',
      'expiry': '12/25',
      'isDefault': true,
      'icon': Icons.credit_card,
      'provider': 'stripe',
      'description': 'Fast, secure, and reliable payment processing',
    },
    {
      'id': 2,
      'type': 'GCash',
      'card': '09633444384',
      'holder': 'Mobile Wallet',
      'expiry': 'N/A',
      'isDefault': false,
      'icon': Icons.phone_in_talk,
      'provider': 'gcash',
      'description': 'Philippine mobile payment',
    },
    {
      'id': 3,
      'type': 'Cash on Delivery',
      'card': 'Pay upon delivery',
      'holder': 'Direct Payment',
      'expiry': 'N/A',
      'isDefault': false,
      'icon': Icons.local_shipping,
      'provider': 'cod',
      'description': 'Pay when your order arrives',
    },
  ];

  void _showPaymentDialog({Map<String, dynamic>? payment}) {
    final typeController = TextEditingController(text: payment?['type'] ?? '');
    final cardController = TextEditingController(text: payment?['card'] ?? '');
    final holderController = TextEditingController(
      text: payment?['holder'] ?? '',
    );
    final expiryController = TextEditingController(
      text: payment?['expiry'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          payment == null ? 'Add Payment Method' : 'Edit Payment Method',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type selection
              if (payment == null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Select Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Stripe',
                      child: Text('Stripe (Recommended)'),
                    ),
                    DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                    DropdownMenuItem(
                      value: 'Cash on Delivery',
                      child: Text('Cash on Delivery'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      typeController.text = value;
                    }
                  },
                )
              else
                TextField(
                  controller: typeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Card Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: cardController,
                decoration: const InputDecoration(
                  hintText: 'Card/Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderController,
                decoration: const InputDecoration(
                  hintText: 'Cardholder Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiryController,
                decoration: const InputDecoration(
                  hintText: 'Expiry (MM/YY) - Optional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (payment == null) {
                setState(() {
                  paymentMethods.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'type': typeController.text,
                    'card': cardController.text,
                    'holder': holderController.text,
                    'expiry': expiryController.text,
                    'isDefault': false,
                    'icon': Icons.credit_card,
                    'provider': typeController.text.toLowerCase(),
                    'description': _getPaymentDescription(typeController.text),
                  });
                });
              } else {
                setState(() {
                  payment['card'] = cardController.text;
                  payment['holder'] = holderController.text;
                  payment['expiry'] = expiryController.text;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    payment == null
                        ? 'Payment method added successfully'
                        : 'Payment method updated successfully',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getPaymentDescription(String type) {
    switch (type.toLowerCase()) {
      case 'stripe':
        return 'Fast, secure card payments via Stripe';
      case 'gcash':
        return 'Philippines mobile payment';
      case 'cash on delivery':
        return 'Pay upon delivery';
      default:
        return 'Payment method';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPaymentDialog(),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
      ),
      body: paymentMethods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Payment Methods',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a payment method to checkout faster',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final payment = paymentMethods[index];
                final isStripe = payment['provider'] == 'stripe';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: payment['isDefault']
                        ? LinearGradient(
                            colors: [
                              isStripe
                                  ? Colors.blue.shade700
                                  : Colors.teal.shade700,
                              isStripe
                                  ? Colors.blue.shade600
                                  : Colors.teal.shade600,
                            ],
                          )
                        : null,
                    color: payment['isDefault'] ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: payment['isDefault']
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and type
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: payment['isDefault']
                                        ? Colors.white24
                                        : (isStripe
                                              ? Colors.blue.shade100
                                              : Colors.teal.shade100),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    payment['icon'],
                                    color: payment['isDefault']
                                        ? Colors.white
                                        : (isStripe
                                              ? Colors.blue.shade700
                                              : Colors.teal.shade700),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment['type'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: payment['isDefault']
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    if (payment['isDefault'])
                                      Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    // Stripe badge
                                    if (isStripe)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade600,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'RECOMMENDED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Text('Edit'),
                                  onTap: () =>
                                      _showPaymentDialog(payment: payment),
                                ),
                                if (payment['provider'] != 'stripe')
                                  PopupMenuItem(
                                    child: const Text('Delete'),
                                    onTap: () {
                                      setState(() {
                                        paymentMethods.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Payment method deleted successfully',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                if (!payment['isDefault'])
                                  PopupMenuItem(
                                    child: const Text('Set as Default'),
                                    onTap: () {
                                      setState(() {
                                        for (var pm in paymentMethods) {
                                          pm['isDefault'] = false;
                                        }
                                        payment['isDefault'] = true;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Default payment method updated',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          payment['description'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: payment['isDefault']
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Card/Account number
                        if (payment['card'] != null)
                          Text(
                            payment['card'],
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 2,
                              color: payment['isDefault']
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Details row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARDHOLDER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: payment['isDefault']
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payment['holder'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: payment['isDefault']
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            if (payment['expiry'] != 'N/A')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'EXPIRES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: payment['isDefault']
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    payment['expiry'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: payment['isDefault']
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'STATUS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: payment['isDefault']
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Stripe security info
                        if (isStripe)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: payment['isDefault']
                                    ? Colors.white10
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: payment['isDefault']
                                        ? Colors.white70
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'PCI-DSS Level 1 Certified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: payment['isDefault']
                                            ? Colors.white70
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
