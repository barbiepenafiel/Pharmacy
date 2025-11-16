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
      'type': 'Credit Card',
      'card': '**** **** **** 1234',
      'holder': 'John Doe',
      'expiry': '12/25',
      'isDefault': true,
      'icon': Icons.credit_card,
    },
    {
      'id': 2,
      'type': 'Debit Card',
      'card': '**** **** **** 5678',
      'holder': 'John Doe',
      'expiry': '08/26',
      'isDefault': false,
      'icon': Icons.credit_card,
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
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  hintText: 'Card Type (Credit/Debit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardController,
                decoration: const InputDecoration(
                  hintText: 'Card Number',
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
                  hintText: 'Expiry (MM/YY)',
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
                  });
                });
              } else {
                setState(() {
                  payment['type'] = typeController.text;
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: payment['isDefault']
                        ? LinearGradient(
                            colors: [
                              Colors.teal.shade700,
                              Colors.teal.shade600,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  payment['icon'],
                                  color: payment['isDefault']
                                      ? Colors.white
                                      : Colors.teal.shade700,
                                  size: 24,
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
                                PopupMenuItem(
                                  child: const Text('Delete'),
                                  onTap: () {
                                    setState(() {
                                      paymentMethods.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                            ),
                          ],
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
