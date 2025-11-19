import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AuthService _authService;
  int _selectedIndex = 0;

  String get baseUrl => AuthService.baseUrl;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
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
    final currentUser = _authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                currentUser?['fullName'] ?? 'Admin',
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
        return DashboardTab(baseUrl: baseUrl);
      case 1:
        return ProductsTab(baseUrl: baseUrl);
      case 2:
        return UsersTab(baseUrl: baseUrl);
      case 3:
        return OrdersTab(baseUrl: baseUrl);
      case 4:
        return InventoryTab(baseUrl: baseUrl);
      default:
        return DashboardTab(baseUrl: baseUrl);
    }
  }
}

// Dashboard Tab
class DashboardTab extends StatefulWidget {
  final String baseUrl;
  const DashboardTab({super.key, required this.baseUrl});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.baseUrl}/api/admin/dashboard-public'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stats = data;
          loading = false;
        });
      }
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  trend.startsWith('+')
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
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
  final String baseUrl;
  const ProductsTab({super.key, required this.baseUrl});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<dynamic> products = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.baseUrl}/api/products'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            products = data['data'] ?? [];
            loading = false;
          });
        }
      }
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
    String imageSource = 'url'; // 'url' or 'manual'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
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
                            loadingBuilder: (context, child, loadingProgress) {
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
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter an Image URL to preview',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
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
                await _saveProduct(
                  product?['id'],
                  nameController.text,
                  descController.text,
                  dosageController.text,
                  priceController.text,
                  categoryController.text,
                  quantityController.text,
                  supplierController.text,
                  imageUrlController.text,
                );
                // ignore: use_build_context_synchronously
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
  ) async {
    if (name.isEmpty || category.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    try {
      final url = id == null
          ? '${widget.baseUrl}/api/products'
          : '${widget.baseUrl}/api/products/$id';

      final body = {
        'name': name,
        'description': description,
        'dosage': dosage,
        'price': price,
        'category': category,
        'quantity': quantity,
        'supplier': supplier,
        'imageUrl': imageUrl,
      };

      final response = id == null
          ? await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
          : await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(id == null ? 'Product added!' : 'Product updated!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/products/$id'),
      );

      if (response.statusCode == 200) {
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Product deleted!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: ${e.toString()}')),
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
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          // Product Image - Fixed height
                          Container(
                            height: 100,
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
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 40,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                          // Product Info - Takes remaining space
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'Product',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '₱${(product['price'] ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock: ${product['quantity'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Buttons at bottom
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 28,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showProductForm(
                                              product: product,
                                            ),
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 12,
                                            ),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(fontSize: 9),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: SizedBox(
                                          height: 28,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _deleteProduct(product['id']),
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 12,
                                            ),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(fontSize: 9),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Users Tab
class UsersTab extends StatefulWidget {
  final String baseUrl;
  const UsersTab({super.key, required this.baseUrl});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<dynamic> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.baseUrl}/api/admin/users-public'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['data'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/admin/users/$userId'),
      );

      if (response.statusCode == 200) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: ${e.toString()}')),
        );
      }
    }
  }

  void _confirmDeleteUser(int userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(userId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(user['fullName'] ?? ''),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  'Orders: ${user['totalOrders'] ?? 0}',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDeleteUser(
                                  user['id'],
                                  user['fullName'] ?? 'User',
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
      ),
    );
  }
}

// Orders Tab
class OrdersTab extends StatefulWidget {
  final String baseUrl;
  const OrdersTab({super.key, required this.baseUrl});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<dynamic> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.baseUrl}/api/admin/orders-public'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['data'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/admin/orders/$orderId'),
      );

      if (response.statusCode == 200) {
        _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting order: ${e.toString()}')),
        );
      }
    }
  }

  void _confirmDeleteOrder(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete Order #$orderId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteOrder(orderId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('Order #${order['id']}'),
                          subtitle: Text(
                            'Customer: ${order['user']['fullName']} | Status: ${order['status']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${order['totalAmount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDeleteOrder(order['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Inventory Tab
class InventoryTab extends StatefulWidget {
  final String baseUrl;
  const InventoryTab({super.key, required this.baseUrl});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  List<dynamic> inventory = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.baseUrl}/api/inventory'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          inventory = data['data'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      // Error loading inventory
      setState(() => loading = false);
    }
  }

  List<dynamic> get filteredInventory {
    if (searchQuery.isEmpty) return inventory;
    return inventory
        .where(
          (item) =>
              item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              item['dosage'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_stock':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_stock':
        return 'In Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/inventory/$id'),
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        _loadInventory();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final quantityController = TextEditingController();
    final supplierController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
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
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Expiry: ${selectedDate?.toString().split(' ')[0] ?? 'Not set'}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
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
                final response = await http.post(
                  Uri.parse('${widget.baseUrl}/api/inventory'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'quantity': int.parse(quantityController.text),
                    'supplier': supplierController.text,
                    'expiryDate': selectedDate?.toIso8601String(),
                  }),
                );

                if (response.statusCode == 200) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                  _loadInventory();
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  // ignore: use_build_context_synchronously
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
                    hintText: 'Search by name or code...',
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
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredInventory.length,
                  itemBuilder: (context, index) {
                    final item = filteredInventory[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  item['status'],
                                ).withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.medication,
                                  color: _getStatusColor(item['status']),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Supplier: ${item['supplier']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Expires: ${DateTime.parse(item['expiryDate']).toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item['quantity']} Units',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      item['status'],
                                    ).withAlpha(51),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusLabel(item['status']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getStatusColor(item['status']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    100,
                                    100,
                                    0,
                                    0,
                                  ),
                                  items: [
                                    PopupMenuItem(
                                      child: const Text('Edit'),
                                      onTap: () {
                                        // TODO: Implement edit
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text('Delete'),
                                      onTap: () => _deleteItem(item['id']),
                                    ),
                                  ],
                                );
                              },
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
