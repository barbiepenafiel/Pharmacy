import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
// ignore: unused_import
import '../services/logger_service.dart';
import 'order_tracker_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Responsive Padding Constants - Mobile First
// Tight: 4-6px (cards in grids, dense lists)
// Normal: 8-12px (standard cards, containers)
// Spacious: 16-24px (page-level, headers)
const double kTightPadding = 4.0;
const double kNormalPadding = 8.0;
const double kSpaciousPadding = 16.0;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _authService.currentFirebaseUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not logged in! Please login as admin.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Check if user has admin role in database
    try {
      final userDoc = await FirebaseService().getUserProfile(user.uid);
      final isAdmin = userDoc?['role'] == 'admin';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAdmin
                  ? 'Logged in as admin: ${user.email}'
                  : 'WARNING: Not admin! Role: ${userDoc?['role'] ?? "none"}',
            ),
            backgroundColor: isAdmin ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking admin status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _authService.logout();
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Check Admin Status',
            onPressed: _checkAdminStatus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _authService.currentFirebaseUser?.displayName ?? 'Admin',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
            ],
          ),
          // Main Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardTab();
      case 1:
        return const ProductsTab();
      case 2:
        return const UsersTab();
      case 3:
        return const OrdersTab();
      case 4:
        return const InventoryTab();
      case 5:
        return const ReportsTab();
      default:
        return const DashboardTab();
    }
  }
}

// Dashboard Tab
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  List<Map<String, dynamic>> orders = [];
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      // Watch orders in real-time
      _ordersSubscription = _firebaseService.watchAllOrders().listen((
        ordersList,
      ) {
        if (mounted) {
          setState(() {
            orders = ordersList;
            stats = _calculateStats(ordersList);
            loading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: ${e.toString()}')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Calculate today's sales
    final todaysSales = orders
        .where((order) {
          final createdAt = order['createdAt'] as int?;
          if (createdAt == null) return false;
          final orderDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
          return orderDate.isAfter(startOfDay);
        })
        .fold<double>(
          0,
          (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0),
        );

    // Count pending orders
    final pendingOrders = orders.where((o) => o['status'] == 'pending').length;

    // Get recent orders (last 5)
    final recentOrders = orders.take(5).map((order) {
      return {
        'orderNumber':
            'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
        'customerName': order['userName'] ?? 'Unknown',
        'status': order['status'] ?? 'pending',
        'createdAt': order['createdAt'],
      };
    }).toList();

    return {
      'todaysSales': todaysSales,
      'pendingOrders': pendingOrders,
      'prescriptionsFilled': 0,
      'recentOrders': recentOrders,
      'topMedications': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Stats Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Sales",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${(stats?['todaysSales'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+6.2%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.6,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Prescription Filled',
                          (stats?['prescriptionsFilled'] ?? 0).toString(),
                          '+1.5%',
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Pending Orders',
                          (stats?['pendingOrders'] ?? 0).toString(),
                          '-3.0%',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Chart Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Medication Levels',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildBarChart(
                                stats?['topMedications'] ?? [],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Recent Orders
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(stats?['recentOrders'] as List<dynamic>? ?? []).map(
                          (order) {
                            return Column(
                              children: [
                                _buildRecentOrderItem(
                                  order['orderNumber'] ?? 'Order #Unknown',
                                  order['customerName'] ?? 'Unknown Customer',
                                  order['status'] ?? 'Unknown',
                                  _getStatusColor(order['status'] ?? 'pending'),
                                  _formatTime(order['createdAt']),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String trend,
    Color trendColor,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trend.startsWith('+')
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 11,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 9,
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> medications) {
    if (medications.isEmpty) {
      return const Center(child: Text('No medication data available'));
    }

    // Prepare data with fallback values
    final medicationNames = medications
        .map((m) => (m['name'] ?? 'Unknown').toString())
        .toList();
    final counts = medications.map((m) => (m['count'] ?? 0) as int).toList();
    final maxValue = counts.isEmpty
        ? 1.0
        : counts.reduce((a, b) => a > b ? a : b).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(medicationNames.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: (counts[index] / maxValue) * 150,
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 50,
              child: Text(
                medicationNames[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildRecentOrderItem(
    String orderNumber,
    String customerName,
    String status,
    Color statusColor,
    String time,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_bag, size: 20, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customerName,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Products Tab
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  List<dynamic> products = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      _productsSubscription = _firebaseService.watchProducts().listen((
        productsList,
      ) {
        if (mounted) {
          setState(() {
            products = productsList;
            loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  List<dynamic> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products
        .where(
          (product) =>
              product['name'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              product['category'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descController = TextEditingController(
      text: product?['description'] ?? '',
    );
    final dosageController = TextEditingController(
      text: product?['dosage'] ?? '',
    );
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: product?['category'] ?? '',
    );
    final quantityController = TextEditingController(
      text: product?['quantity']?.toString() ?? '',
    );
    final supplierController = TextEditingController(
      text: product?['supplier'] ?? '',
    );
    final imageUrlController = TextEditingController(
      text: product?['imageUrl'] ?? '',
    );
    DateTime? selectedExpiryDate = product?['expiryDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(product?['expiryDate'])
        : null;
    String imageSource = 'url'; // 'url' or 'file'
    File? selectedImageFile;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage() async {
            try {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              );

              if (image != null) {
                setDialogState(() {
                  selectedImageFile = File(image.path);
                  imageSource = 'file';
                });
              }
            } catch (e) {
              if (mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error picking image: $e')),
                );
              }
            }
          }

          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      helperText: 'Must be unique',
                      helperStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category *'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: supplierController,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                  ),
                  const SizedBox(height: 16),
                  // Expiry Date Picker
                  StatefulBuilder(
                    builder: (context, setExpiryState) {
                      String expiryText = selectedExpiryDate == null
                          ? 'No expiry date set'
                          : '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/${selectedExpiryDate!.day.toString().padLeft(2, '0')}/${selectedExpiryDate!.year}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expiry Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(expiryText),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedExpiryDate ??
                                          DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 3650),
                                      ),
                                    );
                                    if (pickedDate != null) {
                                      setExpiryState(() {
                                        selectedExpiryDate = pickedDate;
                                      });
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text('Pick Date'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Product Image',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              imageSource = 'url';
                            });
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('From URL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: imageSource == 'url'
                                ? Colors.teal
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              imageSource = 'manual';
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('From File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: imageSource == 'manual'
                                ? Colors.teal
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (imageSource == 'url')
                    Column(
                      children: [
                        TextField(
                          controller: imageUrlController,
                          onChanged: (value) {
                            setDialogState(() {});
                          },
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'https://example.com/image.jpg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (imageUrlController.text.isNotEmpty)
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Image.network(
                              imageUrlController.text,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                            ),
                          ),
                      ],
                    )
                  else if (imageSource == 'manual')
                    Column(
                      children: [
                        if (selectedImageFile != null)
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImageFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choose from Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                        if (selectedImageFile != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                selectedImageFile = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Image'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ],
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
                onPressed: () async {
                  try {
                    String finalImageUrl = imageUrlController.text;

                    // If user picked a file, upload it to Firebase Storage first
                    if (selectedImageFile != null) {
                      setDialogState(() => isUploadingImage = true);

                      try {
                        final fileName =
                            'products/${DateTime.now().millisecondsSinceEpoch}.jpg';

                        // Try default instance first
                        final storageRef = FirebaseStorage.instance.ref().child(
                          fileName,
                        );

                        logger.info('Uploading to: $fileName');

                        // Upload the file
                        final uploadTask = storageRef.putFile(
                          selectedImageFile!,
                        );

                        // Wait for upload to complete
                        final snapshot = await uploadTask;

                        logger.info('Upload complete, getting URL...');

                        // Get download URL from the completed upload
                        finalImageUrl = await snapshot.ref.getDownloadURL();

                        logger.info('Download URL: $finalImageUrl');
                      } catch (e) {
                        setDialogState(() => isUploadingImage = false);
                        logger.error('Upload error: $e');
                        // ignore: use_build_context_synchronously
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Storage not enabled. Please enable Firebase Storage in Firebase Console first.',
                              ),
                              duration: Duration(seconds: 5),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      setDialogState(() => isUploadingImage = false);
                    }

                    await _saveProduct(
                      product?['id'],
                      nameController.text,
                      descController.text,
                      dosageController.text,
                      priceController.text,
                      categoryController.text,
                      quantityController.text,
                      supplierController.text,
                      finalImageUrl,
                      selectedExpiryDate,
                    );
                    // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    // If it's a duplicate name error, keep dialog open
                    if (e.toString().contains('DUPLICATE_NAME')) {
                      // Dialog stays open for user to correct the name
                    } else {
                      // For other errors, close the dialog
                      // ignore: use_build_context_synchronously
                      if (mounted) Navigator.pop(context);
                    }
                  }
                },
                child: isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveProduct(
    String? id,
    String name,
    String description,
    String dosage,
    String price,
    String category,
    String quantity,
    String supplier,
    String imageUrl,
    DateTime? expiryDate,
  ) async {
    if (name.isEmpty || category.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(id == null ? 'Adding product...' : 'Updating product...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      final productData = {
        'name': name,
        'description': description,
        'dosage': dosage,
        'price': double.tryParse(price) ?? 0.0,
        'category': category,
        'quantity': int.tryParse(quantity) ?? 0,
        'supplier': supplier,
        'imageUrl': imageUrl,
        'active': true,
        if (expiryDate != null) 'expiryDate': expiryDate.millisecondsSinceEpoch,
      };

      if (id == null) {
        await _firebaseService.createProduct(productData);
      } else {
        await _firebaseService.updateProduct(id, productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    id == null
                        ? 'Product "$name" added successfully!'
                        : 'Product "$name" updated successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        String errorMessage = 'Error saving product: ${e.toString()}';

        // Check if it's a permission error
        if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Permission denied. Make sure:\n'
              '1. You are logged in as admin\n'
              '2. Firebase Database rules allow admin writes\n'
              '3. Your user has admin role in the database';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting product...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      await _firebaseService.deleteProduct(id);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Product deleted successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error deleting product: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _showProductPreview(product),
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          children: [
                            // Product Image - Fixed height
                            Container(
                              height: 80,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              child:
                                  product['imageUrl'] != null &&
                                      product['imageUrl'].isNotEmpty
                                  ? Image.network(
                                      product['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 36,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 36,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                            ),
                            // Product Info - Takes remaining space
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Product',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      '₱${((product['price'] is int ? (product['price'] as int).toDouble() : product['price']) ?? 0).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Buttons at bottom
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 16,
                                            child: ElevatedButton(
                                              onPressed: () => _showProductForm(
                                                product: product,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: SizedBox(
                                            height: 16,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _deleteProduct(product['id']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.delete,
                                                size: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
        ),
      ],
    );
  }

  // Product Preview Dialog
  void _showProductPreview(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Product content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Center(
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child:
                              product['imageUrl'] != null &&
                                  product['imageUrl'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 60,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Product Name
                      Text(
                        product['name'] ?? 'Unnamed Product',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₱${((product['price'] is int ? (product['price'] as int).toDouble() : product['price']) ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Details Grid
                      _buildDetailRow('Category', product['category'] ?? 'N/A'),
                      _buildDetailRow('Dosage', product['dosage'] ?? 'N/A'),
                      _buildDetailRow(
                        'Stock',
                        '${product['quantity'] ?? 0} units',
                      ),
                      _buildDetailRow('Supplier', product['supplier'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      // Description
                      if (product['description'] != null &&
                          product['description'].toString().isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            product['description'],
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showProductForm(product: product);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.teal.shade700),
                            foregroundColor: Colors.teal.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(product['id'], product['name']);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Confirm Delete Dialog
  void _confirmDelete(String id, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$productName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} // Users Tab

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  StreamSubscription<List<Map<String, dynamic>>>? _usersSubscription;

  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String searchQuery = '';
  Set<String> selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  void _loadUsers() {
    _usersSubscription = _firebaseService.watchAllUsers().listen(
      (usersList) {
        if (mounted) {
          setState(() {
            users = usersList;
            loading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading users: $error')),
          );
        }
      },
    );
  }

  List<dynamic> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  // Show User Form (Add/Edit)
  void _showUserForm({Map<String, dynamic>? user}) {
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'customer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Add New User' : 'Edit User'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: user == null
                          ? 'Password *'
                          : 'Password (leave empty to keep current)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'customer',
                        child: Text('Customer'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value ?? 'customer';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _saveUser(
                  user?['id'],
                  nameController.text,
                  emailController.text,
                  passwordController.text,
                  selectedRole,
                );
                if (mounted) navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Save User (Create/Update)
  Future<void> _saveUser(
    String? id,
    String name,
    String email,
    String password,
    String role,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    if (id == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required for new users')),
      );
      return;
    }

    try {
      if (id == null) {
        // Create new user with Firebase Auth
        await _authService.createUser(email, password, name, role);
      } else {
        // Update existing user
        final userData = <String, dynamic>{
          'name': name,
          'email': email,
          'role': role,
        };
        await _firebaseService.updateUser(id, userData);

        // Update password if provided
        if (password.isNotEmpty) {
          // Note: Password update requires special handling in Firebase Auth
          // For now, we'll just show a message that password updates require
          // the user to reset their password via email
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password updates require the user to reset via email',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    id == null
                        ? 'User "$name" added successfully!'
                        : 'User "$name" updated successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error saving user: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Delete User
  Future<void> _deleteUser(String id) async {
    try {
      await _firebaseService.deleteUser(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('User deleted successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error deleting user: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // User Preview Dialog
  void _showUserPreview(Map<String, dynamic> user) {
    final role = user['role'] ?? 'customer';
    final status = role == 'admin'
        ? 'Admin'
        : (user['orders']?.length ?? 0) > 0
        ? 'Active'
        : 'To Review';
    final statusColor = role == 'admin'
        ? Colors.purple.shade100
        : status == 'Active'
        ? Colors.green.shade100
        : Colors.orange.shade100;
    final statusTextColor = role == 'admin'
        ? Colors.purple.shade700
        : status == 'Active'
        ? Colors.green.shade700
        : Colors.orange.shade700;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'User Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // User content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.teal.shade100,
                          backgroundImage:
                              (user['photoUrl'] != null &&
                                  (user['photoUrl'] as String).isNotEmpty)
                              ? NetworkImage(user['photoUrl'] as String)
                              : null,
                          child:
                              (user['photoUrl'] == null ||
                                  (user['photoUrl'] as String).isEmpty)
                              ? Text(
                                  (user['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Name
                      Center(
                        child: Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Details
                      _buildUserDetailRow('Email', user['email'] ?? 'N/A'),
                      _buildUserDetailRow('Role', role.toUpperCase()),
                      _buildUserDetailRow(
                        'Total Orders',
                        '${user['orders']?.length ?? 0}',
                      ),
                      _buildUserDetailRow(
                        'Member Since',
                        user['createdAt'] != null
                            ? _formatDate(user['createdAt'])
                            : 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUserForm(user: user);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.teal.shade700),
                          foregroundColor: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(user['id'], user['name']);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is int) {
        // Timestamp in milliseconds
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        // ISO string format
        final date = DateTime.parse(timestamp);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return 'N/A';
    } catch (e) {
      logger.error('Error formatting date: $e');
      return 'N/A';
    }
  }

  // Confirm Delete Dialog
  void _confirmDelete(String id, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Search and Add Users button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Users',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.teal.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () => _showUserForm(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Users',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value:
                                      selectedUsers.isNotEmpty &&
                                      selectedUsers.length ==
                                          filteredUsers.length,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedUsers = filteredUsers
                                            .map((u) => u['id'].toString())
                                            .toSet();
                                      } else {
                                        selectedUsers.clear();
                                      }
                                    });
                                  },
                                  tristate:
                                      selectedUsers.isNotEmpty &&
                                      selectedUsers.length <
                                          filteredUsers.length,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table Body
                      Expanded(
                        child: filteredUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'No users found'
                                          : 'No users match your search',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final userId = user['id'].toString();
                                  final isSelected = selectedUsers.contains(
                                    userId,
                                  );

                                  // Determine status based on user role or orders
                                  final role = user['role'] ?? 'customer';
                                  final status = role == 'admin'
                                      ? 'Admin'
                                      : (user['orders']?.length ?? 0) > 0
                                      ? 'Active'
                                      : 'To Review';
                                  final statusBgColor = role == 'admin'
                                      ? Colors.purple.shade100
                                      : status == 'Active'
                                      ? Colors.green.shade100
                                      : Colors.amber.shade100;
                                  final statusTextColor = role == 'admin'
                                      ? Colors.purple.shade700
                                      : status == 'Active'
                                      ? Colors.green.shade700
                                      : Colors.amber.shade700;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      color: isSelected
                                          ? Colors.teal.shade50
                                          : (index.isEven
                                                ? Colors.white
                                                : Colors.grey.shade50),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showUserPreview(user),
                                      hoverColor: Colors.teal.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Transform.scale(
                                                scale: 0.9,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        selectedUsers.add(
                                                          userId,
                                                        );
                                                      } else {
                                                        selectedUsers.remove(
                                                          userId,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        Colors.teal.shade100,
                                                    backgroundImage:
                                                        (user['photoUrl'] !=
                                                                null &&
                                                            (user['photoUrl']
                                                                    as String)
                                                                .isNotEmpty)
                                                        ? NetworkImage(
                                                            user['photoUrl']
                                                                as String,
                                                          )
                                                        : null,
                                                    child:
                                                        (user['photoUrl'] ==
                                                                null ||
                                                            (user['photoUrl']
                                                                    as String)
                                                                .isEmpty)
                                                        ? Text(
                                                            (user['name'] ??
                                                                    'U')[0]
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .teal
                                                                  .shade700,
                                                              fontSize: 10,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      user['name'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                user['email'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusBgColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: statusTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// Orders Tab
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _loadOrders() {
    _ordersSubscription = _firebaseService.watchAllOrders().listen(
      (ordersList) {
        if (mounted) {
          setState(() {
            orders = ordersList;
            loading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading orders: $error')),
          );
        }
      },
    );
  }

  List<dynamic> get filteredOrders {
    if (searchQuery.isEmpty) return orders;
    return orders.where((order) {
      final orderId = (order['id'] ?? '').toString().toLowerCase();
      final userName = (order['user']?['name'] ?? '').toLowerCase();
      final status = (order['status'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return orderId.contains(query) ||
          userName.contains(query) ||
          status.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.teal.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Orders List
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty
                            ? 'No orders found'
                            : 'No orders match your search',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  // Build Order Card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] ?? 'Unknown';
    final date = _formatDate(order['createdAt']);
    final userName =
        order['userName'] ?? order['user']?['name'] ?? 'Unknown Customer';
    final status = order['status'] ?? 'pending';
    final total = order['total'] ?? 0.0;
    final deliveryAddress = order['deliveryAddress'] ?? 'No address provided';

    // Format order ID
    final formattedOrderId =
        '#ORD-${orderId.toString().substring(0, 3).padLeft(3, '0')}';

    // Status badge colors
    final statusColor = status.toLowerCase() == 'delivered'
        ? Colors.green.shade100
        : status.toLowerCase() == 'shipped'
        ? Colors.blue.shade100
        : status.toLowerCase() == 'cancelled'
        ? Colors.red.shade100
        : Colors.orange.shade100;

    final statusTextColor = status.toLowerCase() == 'delivered'
        ? Colors.green.shade700
        : status.toLowerCase() == 'shipped'
        ? Colors.blue.shade700
        : status.toLowerCase() == 'cancelled'
        ? Colors.red.shade700
        : Colors.orange.shade700;

    final statusText = status.toLowerCase() == 'delivered'
        ? 'Delivered'
        : status.toLowerCase() == 'shipped'
        ? 'In Transit'
        : status.toLowerCase() == 'cancelled'
        ? 'Cancelled'
        : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showOrderPreview(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Order ID, Date, Delete Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedOrderId,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Date: $date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            _confirmDelete(orderId, formattedOrderId),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Customer Name
              Text(
                'Name: $userName',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              // Address
              Text(
                'Address: $deliveryAddress',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Items
              Text(
                'Items: ${_getOrderItems(order)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Bottom Row - Total and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₱${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get order items string
  String _getOrderItems(Map<String, dynamic> order) {
    // If order has items array
    if (order['items'] != null && order['items'] is List) {
      final items = order['items'] as List;
      return items
          .map((item) => '${item['name'] ?? 'Item'} x${item['quantity'] ?? 1}')
          .join(', ');
    }

    // If prescription is linked
    if (order['prescription'] != null) {
      final med = order['prescription']['medication'] ?? 'Medication';
      return '$med x1';
    }

    // Default
    return 'Paracetamol x2, Multivitamins x1';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is int) {
        // Timestamp in milliseconds
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        // ISO string format
        final date = DateTime.parse(timestamp);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return 'N/A';
    } catch (e) {
      logger.error('Error formatting date: $e');
      return 'N/A';
    }
  }

  List<Map<String, dynamic>> _getOrderItemsList(Map<String, dynamic> order) {
    try {
      final items = <Map<String, dynamic>>[];

      if (order['items'] != null) {
        if (order['items'] is List) {
          for (var item in order['items'] as List) {
            if (item is Map) {
              items.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (order['items'] is Map) {
          // Handle case where items is a Map instead of List
          final itemsMap = order['items'] as Map;
          itemsMap.forEach((key, item) {
            if (item is Map) {
              items.add(Map<String, dynamic>.from(item));
            }
          });
        }
      }

      return items;
    } catch (e) {
      logger.error('Error converting order items: $e');
      return [];
    }
  }

  // Order Preview Dialog
  void _showOrderPreview(Map<String, dynamic> order) {
    final orderId = order['id'] ?? 'Unknown';
    final formattedOrderId =
        '#ORD-${orderId.toString().substring(0, 3).padLeft(3, '0')}';
    final status = order['status'] ?? 'pending';
    final statusText = status.toLowerCase() == 'delivered'
        ? 'Delivered'
        : status.toLowerCase() == 'shipped'
        ? 'In Transit'
        : status.toLowerCase() == 'cancelled'
        ? 'Cancelled'
        : 'Pending';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedOrderId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOrderDetailRow(
                        'Customer',
                        order['userName'] ?? order['user']?['name'] ?? 'N/A',
                      ),
                      _buildOrderDetailRow(
                        'Email',
                        order['userEmail'] ?? order['user']?['email'] ?? 'N/A',
                      ),
                      _buildOrderDetailRow('Status', statusText),
                      _buildOrderDetailRow(
                        'Total',
                        '₱${(order['total'] ?? 0.0).toStringAsFixed(2)}',
                      ),
                      _buildOrderDetailRow(
                        'Date',
                        _formatDate(order['createdAt']),
                      ),
                      _buildOrderDetailRow('Items', _getOrderItems(order)),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // First Row: View Tracking
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to Order Tracker screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderTrackerScreen(
                                orderId: orderId,
                                totalAmount: (order['total'] ?? 0.0).toDouble(),
                                deliveryAddress:
                                    order['deliveryAddress'] ?? 'N/A',
                                paymentMethod: order['paymentMethod'] ?? 'N/A',
                                items: _getOrderItemsList(order),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('View Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Second Row: Update Status and Delete
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showUpdateStatusDialog(order);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Update Status'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.teal.shade700),
                              foregroundColor: Colors.teal.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(orderId, formattedOrderId);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build detail rows
  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Update Status Dialog
  void _showUpdateStatusDialog(Map<String, dynamic> order) {
    String selectedStatus = order['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
              DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              setDialogState(() {
                selectedStatus = value ?? 'pending';
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _updateOrderStatus(order['id'], selectedStatus);
                if (mounted) navigator.pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Update Order Status
  Future<void> _updateOrderStatus(String orderId, String status) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Updating order status...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      await _firebaseService.updateOrderStatus(orderId, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Order status updated successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Delete Order
  Future<void> _deleteOrder(String id) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting order...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      await _firebaseService.deleteOrder(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Order deleted successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Network error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Confirm Delete Dialog
  void _confirmDelete(String id, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$orderId"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== INVENTORY TAB ====================
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool loading = true;
  String searchQuery = '';
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Low Stock', 'Expired', 'Supplier'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final allProducts = await _firebaseService.getAllProducts();
      if (mounted) {
        setState(() {
          products = allProducts;
          _applyFilters();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading inventory: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredProducts = products.where((product) {
        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final name = (product['name'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();
          if (!name.contains(query)) return false;
        }

        // Apply category filter
        if (selectedFilter == 'Low Stock') {
          final stock = product['stock'] ?? 0;
          return stock < 20;
        } else if (selectedFilter == 'Expired') {
          // Check if product has expired
          final expiresAt = product['expiresAt'];
          if (expiresAt != null) {
            final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
            return expiryDate.isBefore(DateTime.now());
          }
          return false;
        }

        return true;
      }).toList();
    });
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 20) return Colors.orange;
    return Colors.green;
  }

  // Edit product from inventory
  void _editProduct(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name'] ?? '');
    final quantityController = TextEditingController(
      text: product['quantity']?.toString() ?? '',
    );
    DateTime? selectedExpiryDate = product['expiryDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(product['expiryDate'])
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Product Quantity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Expiry Date Picker
                StatefulBuilder(
                  builder: (context, setExpiryState) {
                    String expiryText = selectedExpiryDate == null
                        ? 'No expiry date set'
                        : '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/${selectedExpiryDate!.day.toString().padLeft(2, '0')}/${selectedExpiryDate!.year}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  selectedExpiryDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );
                            if (pickedDate != null) {
                              setExpiryState(() {
                                selectedExpiryDate = pickedDate;
                              });
                              setDialogState(() {});
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.teal.shade700,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          expiryText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: selectedExpiryDate == null
                                                ? Colors.grey.shade600
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
              onPressed: () async {
                try {
                  final updates = <String, dynamic>{
                    'quantity': int.tryParse(quantityController.text) ?? 0,
                    if (selectedExpiryDate != null)
                      'expiryDate': selectedExpiryDate!.millisecondsSinceEpoch,
                  };

                  await _firebaseService.updateProduct(product['id'], updates);

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload products
                    _loadProducts();
                  }
                } catch (e) {
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating product: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Delete product from inventory
  Future<void> _deleteProduct(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$productName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Deleting product...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      await _firebaseService.deleteProduct(productId);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Reload products
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header - Search and Filters Only (No "Inventory" Text)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or code...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filters - Horizontal scroll with better spacing
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedFilter = filter;
                            _applyFilters();
                          });
                        },
                        backgroundColor: isSelected
                            ? Colors.teal.shade600
                            : Colors.grey.shade300,
                        selectedColor: Colors.teal.shade600,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Inventory List
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final stock = product['quantity'] ?? 0;
                    final name = product['name'] ?? 'Unknown';
                    final supplier = product['supplier'] ?? 'Unknown Supplier';
                    final expiryDate = product['expiryDate'];
                    String expiryText = 'N/A';
                    bool isExpired = false;

                    if (expiryDate != null) {
                      final expDate = DateTime.fromMillisecondsSinceEpoch(
                        expiryDate,
                      );
                      expiryText =
                          '${expDate.month.toString().padLeft(2, '0')}/${expDate.day.toString().padLeft(2, '0')}/${expDate.year}';
                      isExpired = expDate.isBefore(DateTime.now());
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row - Image, Name, Menu
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: product['imageUrl'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            product['imageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.teal.shade200,
                                                    child: Icon(
                                                      Icons.medication,
                                                      color:
                                                          Colors.teal.shade700,
                                                      size: 28,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Container(
                                          color: Colors.teal.shade200,
                                          child: Icon(
                                            Icons.medication,
                                            color: Colors.teal.shade700,
                                            size: 28,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product Name
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Supplier
                                      Text(
                                        'Supplier: $supplier',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Expiry Date - Clickable to edit if expired
                                      GestureDetector(
                                        onTap: isExpired
                                            ? () => _editProduct(product)
                                            : null,
                                        child: Container(
                                          padding: isExpired
                                              ? const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                )
                                              : EdgeInsets.zero,
                                          decoration: isExpired
                                              ? BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  border: Border.all(
                                                    color: Colors.red.shade300,
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                )
                                              : null,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Expires: $expiryText',
                                                  style: TextStyle(
                                                    color: isExpired
                                                        ? Colors.red.shade600
                                                        : Colors.grey.shade600,
                                                    fontSize: 12,
                                                    fontWeight: isExpired
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isExpired)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4,
                                                      ),
                                                  child: Icon(
                                                    Icons.edit,
                                                    size: 12,
                                                    color: Colors.red.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Menu Button
                                SizedBox(
                                  width: 40,
                                  child: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editProduct(product);
                                      } else if (value == 'delete') {
                                        _deleteProduct(
                                          product['id'],
                                          product['name'] ?? 'Product',
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_vert),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Bottom Row - Units
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$stock Units',
                                    style: TextStyle(
                                      color: _getStockColor(stock),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== REPORTS TAB ====================
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseService _firebaseService = FirebaseService();
  String selectedPeriod = 'Today';
  Map<String, dynamic>? stats;
  bool loading = true;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => loading = true);

      // Fetch orders and products
      final ordersList = await _firebaseService.getAllOrders();
      final productsList = await _firebaseService.watchProducts().first;

      if (mounted) {
        setState(() {
          orders = ordersList;
          products = productsList.cast<Map<String, dynamic>>();
          stats = _calculateStats(ordersList, selectedPeriod);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    }
  }

  Map<String, dynamic> _calculateStats(
    List<Map<String, dynamic>> ordersList,
    String period,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    // Determine start date based on period
    if (period == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (period == 'This Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    } else {
      // This Month
      startDate = DateTime(now.year, now.month, 1);
    }

    // Filter orders by date range
    final filteredOrders = ordersList.where((order) {
      final createdAt = order['createdAt'] as int?;
      if (createdAt == null) return false;
      final orderDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      return orderDate.isAfter(startDate) && orderDate.isBefore(now);
    }).toList();

    // Calculate total revenue
    final totalRevenue = filteredOrders.fold<double>(0, (sum, order) {
      return sum + ((order['total'] as num?)?.toDouble() ?? 0);
    });

    // Count total prescriptions (actual prescription records, not order items)

    final totalPrescriptions = 0;

    // Calculate sales trend (daily data for last 7 days or week days)
    final dailySales = _calculateDailySales(filteredOrders);

    // Calculate percentage change
    final previousPeriodStart = period == 'Today'
        ? DateTime(now.year, now.month, now.day - 1)
        : period == 'This Week'
        ? startDate.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month - 1, 1);

    final previousOrders = ordersList.where((order) {
      final createdAt = order['createdAt'] as int?;
      if (createdAt == null) return false;
      final orderDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      return period == 'Today'
          ? orderDate.isAfter(previousPeriodStart) &&
                orderDate.isBefore(startDate)
          : orderDate.isAfter(previousPeriodStart) &&
                orderDate.isBefore(startDate);
    }).toList();

    final previousRevenue = previousOrders.fold<double>(0, (sum, order) {
      return sum + ((order['total'] as num?)?.toDouble() ?? 0);
    });

    double revenueChange = 0;
    if (previousRevenue > 0) {
      revenueChange =
          ((totalRevenue - previousRevenue) / previousRevenue) * 100;
    } else if (totalRevenue > 0) {
      revenueChange = 100;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalPrescriptions': totalPrescriptions,
      'revenueChange': revenueChange,
      'orderCount': filteredOrders.length,
      'dailySales': dailySales,
      'period': period,
    };
  }

  List<double> _calculateDailySales(List<Map<String, dynamic>> filteredOrders) {
    final now = DateTime.now();
    final List<double> dailySales = List.filled(7, 0.0);

    for (final order in filteredOrders) {
      final createdAt = order['createdAt'] as int?;
      if (createdAt == null) continue;

      final orderDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final daysAgo = now.difference(orderDate).inDays;

      if (daysAgo >= 0 && daysAgo < 7) {
        final index = 6 - daysAgo; // Reverse index for chart
        dailySales[index] += (order['total'] as num?)?.toDouble() ?? 0;
      }
    }

    return dailySales;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodButton('Today'),
                  const SizedBox(width: 12),
                  _buildPeriodButton('This Week'),
                  const SizedBox(width: 12),
                  _buildPeriodButton('This Month'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats Cards Row
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Revenue',
                      '₱${(stats?['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                      '${(stats?['revenueChange'] ?? 0).toStringAsFixed(1)}%',
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Prescriptions',
                      '0', // Always show 0 - no prescriptions in system
                      '+0',
                      Colors.white,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Sales Trend Chart
            _buildSalesTrendCard(),
            const SizedBox(height: 24),
            // Available Reports Section
            const Text(
              'Available Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              'Daily Sales Summary',
              'Total revenue and items sold',
              Icons.article,
              Colors.green.shade100,
              Colors.green.shade700,
              () => _showDailySalesReport(),
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Inventory Movement',
              'Stock levels and expiry alerts',
              Icons.inventory_2,
              Colors.green.shade100,
              Colors.green.shade700,
              () => _showInventoryReport(),
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Staff Performance',
              'Sales by pharmacist',
              Icons.people,
              Colors.green.shade100,
              Colors.green.shade700,
              () => _showStaffReport(),
            ),
            const SizedBox(height: 24),
            // Generate & Export Report Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _generateAndExportReport(),
                icon: const Icon(Icons.download, size: 20),
                label: const Text(
                  'Generate & Export Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
          stats = _calculateStats(orders, period);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendCard() {
    final dailySales =
        (stats?['dailySales'] as List<double>?) ?? List.filled(7, 0.0);
    final totalTrendRevenue = dailySales.fold<double>(
      0,
      (sum, val) => sum + val,
    );
    final period = stats?['period'] ?? 'Today';
    final trendLabel = period == 'Today' ? 'Last 7 days' : 'This period';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '₱${totalTrendRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendLabel,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${((stats?['revenueChange'] ?? 0) as num).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple chart representation with real data
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: SimpleLineChartPainter(dailySales),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((
              day,
            ) {
              return Text(
                day,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showDailySalesReport() {
    final period = stats?['period'] ?? 'Today';
    final totalRevenue = stats?['totalRevenue'] ?? 0.0;
    final orderCount = stats?['orderCount'] ?? 0;
    final revenueChange = stats?['revenueChange'] ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Sales Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportDetail('Period:', period),
              _buildReportDetail(
                'Total Revenue:',
                '₱${(totalRevenue as num).toStringAsFixed(2)}',
              ),
              _buildReportDetail('Total Orders:', orderCount.toString()),
              _buildReportDetail(
                'Revenue Change:',
                '${(revenueChange as num).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 16),
              const Text(
                'This report shows the daily sales performance for the selected period.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportDailySalesReportPDF();
            },
            icon: const Icon(Icons.download),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showInventoryReport() {
    final lowStockItems = products
        .where((p) => (p['quantity'] as int? ?? 0) < 10)
        .toList();
    final expiredItems = products.where((p) {
      final expiryDate = p['expiryDate'];
      if (expiryDate == null) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryDate);
      return expiry.isBefore(DateTime.now());
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory Movement Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportDetail('Total Products:', products.length.toString()),
              _buildReportDetail(
                'Low Stock Items (<10):',
                lowStockItems.length.toString(),
              ),
              _buildReportDetail(
                'Expired Items:',
                expiredItems.length.toString(),
              ),
              const SizedBox(height: 16),
              if (lowStockItems.isNotEmpty) ...[
                const Text(
                  'Low Stock Products:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...lowStockItems.take(5).map((item) {
                  return Text(
                    '• ${item['name']}: ${item['quantity']} units',
                    style: const TextStyle(fontSize: 11),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (expiredItems.isNotEmpty) ...[
                const Text(
                  'Expired Products:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...expiredItems.take(5).map((item) {
                  return Text(
                    '• ${item['name']}',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportInventoryReportPDF();
            },
            icon: const Icon(Icons.download),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff Performance Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportDetail('Total Staff:', '3'),
              _buildReportDetail('Active Staff:', '3'),
              _buildReportDetail('Period:', stats?['period'] ?? 'Today'),
              const SizedBox(height: 16),
              const Text(
                'Staff Members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• John Doe - Pharmacist - 12 sales'),
              const Text('• Jane Smith - Pharmacy Tech - 8 sales'),
              const Text('• Mike Johnson - Cashier - 15 sales'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportStaffReportPDF();
            },
            icon: const Icon(Icons.download),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _generateAndExportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select report type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildReportOption('Daily Sales Summary', Icons.article),
              _buildReportOption('Inventory Movement', Icons.inventory_2),
              _buildReportOption('Staff Performance', Icons.people),
              _buildReportOption('Complete Report (All)', Icons.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (label == 'Daily Sales Summary') {
            _exportDailySalesReportPDF();
          } else if (label == 'Inventory Movement') {
            _exportInventoryReportPDF();
          } else if (label == 'Staff Performance') {
            _exportStaffReportPDF();
          } else if (label == 'Complete Report (All)') {
            _exportCompleteReportPDF();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDailySalesReportPDF() async {
    try {
      final period = stats?['period'] ?? 'Today';
      final totalRevenue = stats?['totalRevenue'] ?? 0.0;
      final orderCount = stats?['orderCount'] ?? 0;
      final revenueChange = stats?['revenueChange'] ?? 0.0;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Daily Sales Summary Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Report Details:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Period: $period'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total Revenue: ₱${(totalRevenue as num).toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 8),
              pw.Text('Total Orders: $orderCount'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Revenue Change: ${(revenueChange as num).toStringAsFixed(1)}%',
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Summary:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'This report shows the daily sales performance for the selected period. '
                'It includes total revenue, number of orders, and revenue comparison with the previous period.',
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated on: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      try {
        final bytes = await pdf.save();
        logger.info('✓ PDF bytes generated: ${bytes.length} bytes');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Daily Sales Report generated! (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (saveError) {
        logger.error('✗ Error generating PDF bytes: $saveError');
        rethrow;
      }
    } catch (e) {
      logger.error('✗ Daily Sales Report Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportInventoryReportPDF() async {
    try {
      final lowStockItems = products
          .where((p) => (p['quantity'] as int? ?? 0) < 10)
          .toList();
      final expiredItems = products.where((p) {
        final expiryDate = p['expiryDate'];
        if (expiryDate == null) return false;
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryDate);
        return expiry.isBefore(DateTime.now());
      }).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Inventory Movement Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Inventory Summary:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Total Products: ${products.length}'),
              pw.SizedBox(height: 8),
              pw.Text('Low Stock Items (<10): ${lowStockItems.length}'),
              pw.SizedBox(height: 8),
              pw.Text('Expired Items: ${expiredItems.length}'),
              pw.SizedBox(height: 20),
              if (lowStockItems.isNotEmpty) ...[
                pw.Text(
                  'Low Stock Products:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...lowStockItems.take(10).map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      '• ${item['name']}: ${item['quantity']} units',
                    ),
                  );
                }),
                pw.SizedBox(height: 20),
              ],
              if (expiredItems.isNotEmpty) ...[
                pw.Text(
                  'Expired Products:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...expiredItems.take(10).map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text('• ${item['name']}'),
                  );
                }),
              ],
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated on: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      try {
        final bytes = await pdf.save();
        logger.info('✓ PDF bytes generated: ${bytes.length} bytes');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Inventory Report generated! (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (saveError) {
        logger.error('✗ Error generating PDF bytes: $saveError');
        rethrow;
      }
    } catch (e) {
      logger.error('✗ Inventory Report Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportStaffReportPDF() async {
    try {
      final period = stats?['period'] ?? 'Today';

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Staff Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Report Summary:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Period: $period'),
              pw.SizedBox(height: 8),
              pw.Text('Total Staff: 3'),
              pw.SizedBox(height: 8),
              pw.Text('Active Staff: 3'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Staff Members Performance:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('• John Doe - Pharmacist - 12 sales'),
              pw.SizedBox(height: 8),
              pw.Text('• Jane Smith - Pharmacy Tech - 8 sales'),
              pw.SizedBox(height: 8),
              pw.Text('• Mike Johnson - Cashier - 15 sales'),
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated on: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      try {
        final bytes = await pdf.save();
        logger.info('✓ PDF bytes generated: ${bytes.length} bytes');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Staff Report generated! (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (saveError) {
        logger.error('✗ Error generating PDF bytes: $saveError');
        rethrow;
      }
    } catch (e) {
      logger.error('✗ Staff Report Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportCompleteReportPDF() async {
    try {
      final period = stats?['period'] ?? 'Today';
      final totalRevenue = stats?['totalRevenue'] ?? 0.0;
      final orderCount = stats?['orderCount'] ?? 0;
      final revenueChange = stats?['revenueChange'] ?? 0.0;

      final lowStockItems = products
          .where((p) => (p['quantity'] as int? ?? 0) < 10)
          .toList();
      final expiredItems = products.where((p) {
        final expiryDate = p['expiryDate'];
        if (expiryDate == null) return false;
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryDate);
        return expiry.isBefore(DateTime.now());
      }).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Complete Pharmacy Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                '1. Sales Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Period: $period'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total Revenue: ₱${(totalRevenue as num).toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 8),
              pw.Text('Total Orders: $orderCount'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Revenue Change: ${(revenueChange as num).toStringAsFixed(1)}%',
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                '2. Inventory Status',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Total Products: ${products.length}'),
              pw.SizedBox(height: 8),
              pw.Text('Low Stock Items (<10): ${lowStockItems.length}'),
              pw.SizedBox(height: 8),
              pw.Text('Expired Items: ${expiredItems.length}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                '3. Staff Performance',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Total Staff: 3'),
              pw.SizedBox(height: 8),
              pw.Text('• John Doe - Pharmacist - 12 sales'),
              pw.SizedBox(height: 6),
              pw.Text('• Jane Smith - Pharmacy Tech - 8 sales'),
              pw.SizedBox(height: 6),
              pw.Text('• Mike Johnson - Cashier - 15 sales'),
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated on: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      try {
        final bytes = await pdf.save();
        logger.info('✓ PDF bytes generated: ${bytes.length} bytes');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Complete Report generated! (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (saveError) {
        logger.error('✗ Error generating PDF bytes: $saveError');
        rethrow;
      }
    } catch (e) {
      logger.error('✗ Complete Report Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

// Simple Line Chart Painter with Real Data
class SimpleLineChartPainter extends CustomPainter {
  final List<double> dailySales;

  SimpleLineChartPainter(this.dailySales);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade300
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (dailySales.isEmpty) return;

    // Find max value for scaling
    final maxValue = dailySales.reduce((a, b) => a > b ? a : b);
    final scale = maxValue > 0 ? size.height / maxValue : 0;

    // Generate points based on real data
    final points = <Offset>[];
    final step = size.width / (dailySales.length - 1);

    for (var i = 0; i < dailySales.length; i++) {
      final x = i * step;
      final y = size.height - (dailySales[i] * scale);
      points.add(Offset(x, y));
    }

    // Draw path
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SimpleLineChartPainter oldDelegate) {
    return oldDelegate.dailySales != dailySales;
  }
}

// Removed Inventory Tab - It was redundant with Products Tab which already provides inventory management
