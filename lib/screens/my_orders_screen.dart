import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../services/logger_service.dart';
import 'order_tracker_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersSubscription = _firebaseService.watchUserOrders().listen(
      (orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = error.toString();
          });
        }
        logger.error('Error loading orders: $error');
      },
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getOrderItemsSummary(dynamic itemsData) {
    if (itemsData == null) return '0 items';
    try {
      final items = <String>[];

      if (itemsData is Map) {
        itemsData.forEach((key, item) {
          if (item is Map) {
            final name =
                item['name'] ?? item['productName'] ?? 'Unknown Product';
            final qty = item['quantity'] ?? 1;
            items.add('$name (x$qty)');
          }
        });
      } else if (itemsData is List) {
        for (var item in itemsData) {
          if (item is Map) {
            final name =
                item['name'] ?? item['productName'] ?? 'Unknown Product';
            final qty = item['quantity'] ?? 1;
            items.add('$name (x$qty)');
          }
        }
      }

      if (items.isEmpty) return '0 items';
      return items.join(', ');
    } catch (e) {
      logger.error('Error formatting items: $e');
      return 'Multiple items';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withAlpha(77),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your order history',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.cyan[100],
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadOrders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to see your orders here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final status = order['status'] ?? 'unknown';
                final statusColor = _getStatusColor(status);

                return GestureDetector(
                  onTap: () {
                    try {
                      final items = <Map<String, dynamic>>[];
                      final itemsList = order['items'];
                      if (itemsList is Map) {
                        itemsList.forEach((key, item) {
                          if (item is Map) {
                            items.add(Map<String, dynamic>.from(item));
                          }
                        });
                      } else if (itemsList is List) {
                        for (var item in itemsList) {
                          if (item is Map) {
                            items.add(Map<String, dynamic>.from(item));
                          }
                        }
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackerScreen(
                            orderId: order['id'] ?? '',
                            totalAmount: (order['total'] ?? 0.0).toDouble(),
                            deliveryAddress: order['deliveryAddress'] ?? 'N/A',
                            paymentMethod: order['paymentMethod'] ?? 'N/A',
                            items: items,
                          ),
                        ),
                      );
                    } catch (e) {
                      logger.error('Error navigating to order: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error loading order details'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade50, Colors.cyan.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.teal.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade200.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.teal.shade900,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withAlpha(77),
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(thickness: 1, height: 1),
                          const SizedBox(height: 12),
                          // Date and Total
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Date: ${_formatDate(order['createdAt'])}',
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₱${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Items
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 16,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Items: ${_getOrderItemsSummary(order['items'])}',
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
