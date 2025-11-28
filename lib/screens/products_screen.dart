import 'package:flutter/material.dart';
import 'dart:async';
import '../services/cart_service.dart';
import '../services/firebase_service.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? categoryFilter;

  const ProductsScreen({super.key, this.categoryFilter});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final CartService _cartService = CartService();
  final FirebaseService _firebaseService = FirebaseService();

  List<Map<String, dynamic>> products = [];
  bool loading = true;
  String searchQuery = '';
  String? errorMessage;

  StreamSubscription? _productsSubscription;

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

  void _loadProducts() {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Use real-time listener for automatic updates
      if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
        // Filter by category using Firebase query
        _productsSubscription = _firebaseService
            .watchProductsByCategory(widget.categoryFilter!)
            .listen(
              (productsList) {
                setState(() {
                  products = productsList;
                  loading = false;
                  errorMessage = null;
                });
              },
              onError: (error) {
                setState(() {
                  loading = false;
                  errorMessage = _getErrorMessage(error);
                });
              },
            );
      } else {
        // Get all products with real-time updates
        _productsSubscription = _firebaseService.watchProducts().listen(
          (productsList) {
            setState(() {
              products = productsList;
              loading = false;
              errorMessage = null;
            });
          },
          onError: (error) {
            setState(() {
              loading = false;
              errorMessage = _getErrorMessage(error);
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Access denied. Please make sure Firebase security rules are deployed.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Error loading products: ${error.toString()}';
    }
  }

  Future<void> _retryLoading() async {
    _productsSubscription?.cancel();
    _loadProducts();
  }

  List<dynamic> get filteredProducts {
    var filtered = products;

    // Apply category filter if provided
    if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
      filtered = filtered
          .where(
            (product) => product['category'].toString().toLowerCase().contains(
              widget.categoryFilter!.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply search filter
    if (searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (product) =>
              product['name'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _addToCart(dynamic product) {
    final cartItem = CartItem(
      id: product['id'] ?? '',
      name: product['name'] ?? product['productName'] ?? 'Product',
      imageUrl: product['imageUrl'] ?? product['image'],
      price: (product['price'] ?? 0).toDouble(),
      quantity: 1,
    );

    _cartService.addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cartItem.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
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
            Text(
              widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty
                  ? '${widget.categoryFilter} Products'
                  : '🏥 Our Products',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Color.fromARGB(80, 0, 0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty
                  ? 'Browse our ${widget.categoryFilter!.toLowerCase()} collection'
                  : 'Quality medicine & health products',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 230, 255, 255),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoading,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 95,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryButton(
                              'Medicine',
                              Icons.medication,
                              'Medicine',
                            ),
                            const SizedBox(width: 10),
                            _buildCategoryButton(
                              'Diabetes',
                              Icons.devices,
                              'Diabetes',
                            ),
                            const SizedBox(width: 10),
                            _buildCategoryButton(
                              'Skin Care',
                              Icons.spa_outlined,
                              'Skin Care',
                            ),
                            const SizedBox(width: 10),
                            _buildCategoryButton(
                              'Bandage',
                              Icons.healing,
                              'Bandage',
                            ),
                            const SizedBox(width: 10),
                            _buildCategoryButton(
                              'Vitamins',
                              Icons.health_and_safety,
                              'Vitamins',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: '🔍 Search products...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.teal.shade700,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.shade200,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.shade200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.shade700,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.teal.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return GestureDetector(
                              onTap: () => _showProductPreview(product),
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            topRight: Radius.circular(4),
                                          ),
                                        ),
                                        child:
                                            product['imageUrl'] != null &&
                                                product['imageUrl']
                                                    .toString()
                                                    .isNotEmpty
                                            ? (product['imageUrl']
                                                      .toString()
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      product['imageUrl'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color: Colors
                                                                .grey
                                                                .shade400,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.image_not_supported,
                                                    ))
                                            : Icon(
                                                Icons.medication,
                                                size: 48,
                                                color: Colors.teal.shade700,
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'Product',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade900,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product['dosage'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.teal.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal.shade700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () =>
                                                    _addToCart(product),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.teal.shade600,
                                                        Colors.teal.shade800,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showProductPreview(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child:
                        product['imageUrl'] != null &&
                            product['imageUrl'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              product['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.medication,
                              size: 80,
                              color: Colors.teal.shade700,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
              // Product Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (product['dosage'] != null &&
                        product['dosage'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product['dosage'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (product['description'] != null &&
                        product['description'].toString().isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product['category'] ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock: ${product['quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (product['supplier'] != null &&
                        product['supplier'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Supplier: ${product['supplier']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _addToCart(product);
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

  Widget _buildCategoryButton(
    String label,
    IconData icon,
    String categoryFilter,
  ) {
    // Map category labels to asset images or URLs
    final labelKey = label.toLowerCase();
    String? assetPath;
    String? imageUrl;

    if (labelKey == 'medicine') {
      assetPath = 'assets/images/medicine.jpg';
    } else if (labelKey == 'diabetes') {
      assetPath = 'assets/images/Diabetes.jpg';
    } else if (labelKey == 'skin care' || labelKey == 'skincare') {
      assetPath = 'assets/images/SkinCare.jpg';
    } else if (labelKey == 'bandage') {
      assetPath = 'assets/images/Bandage.jpg';
    } else if (labelKey == 'vitamins') {
      imageUrl =
          'https://nyumi.com/cdn/shop/articles/blog_multi.png?v=1685079220';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to products screen with category filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductsScreen(categoryFilter: categoryFilter),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade300.withAlpha(102),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: assetPath != null
                  ? Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildIconFallback(icon);
                      },
                    )
                  : imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildIconFallback(icon);
                      },
                    )
                  : _buildIconFallback(icon),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconFallback(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }
}
