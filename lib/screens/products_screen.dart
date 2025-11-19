import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final CartService _cartService = CartService();
  List<dynamic> products = [];
  bool loading = true;
  String searchQuery = '';

  String get baseUrl => AuthService.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/products'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['data'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      // Error loading products
      setState(() => loading = false);
    }
  }

  List<dynamic> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products
        .where(
          (product) =>
              product['name'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _addToCart(dynamic product) {
    final cartItem = CartItem(
      id: product['id'],
      name: product['name'],
      imageUrl: product['imageUrl'],
      price: (product['price'] ?? 0).toDouble(),
      quantity: 1,
    );

    _cartService.addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
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
        title: const Text('Products'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
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
                            return Card(
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
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['dosage'] ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal.shade700,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _addToCart(product),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
