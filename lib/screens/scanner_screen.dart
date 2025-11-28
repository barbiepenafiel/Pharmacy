import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/firebase_service.dart';
import '../services/cart_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  bool isProcessing = false;
  String scannedValue = '';
  bool showResults = false;
  bool cameraReady = false;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final FirebaseService _firebaseService = FirebaseService();
  final CartService _cartService = CartService();

  List<Map<String, dynamic>> foundProducts = [];
  int? selectedProductIndex;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          cameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _captureAndRecognizeText() async {
    if (!cameraReady || isProcessing) return;

    try {
      isProcessing = true;
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        setState(() {
          scannedValue = recognizedText.text;
          showResults = true;
        });
        await _searchProduct(scannedValue);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text detected in image')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a valid product code')),
      );
      return;
    }

    try {
      // Get all products from Firebase
      final allProducts = await _firebaseService.getAllProducts();

      // Split the scanned text into keywords (words longer than 2 characters)
      final keywords = query
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((word) => word.isNotEmpty && word.length > 2)
          .toList();

      // Score products based on keyword matches
      final scoredProducts = <MapEntry<Map<String, dynamic>, int>>[];

      for (var product in allProducts) {
        final productName = product['name']?.toString().toLowerCase() ?? '';
        final productId = product['id']?.toString().toLowerCase() ?? '';
        final productDescription =
            product['description']?.toString().toLowerCase() ?? '';
        final productCategory =
            product['category']?.toString().toLowerCase() ?? '';

        int score = 0;

        // Check each keyword
        for (var keyword in keywords) {
          // Exact match in product name (highest score)
          if (productName.contains(keyword)) {
            score += 10;
          }
          // Partial match in product name (at least half the keyword)
          else if (productName.contains(
            keyword.substring(0, (keyword.length / 2).ceil()),
          )) {
            score += 5;
          }

          // Match in product ID
          if (productId.contains(keyword)) {
            score += 8;
          }

          // Match in description
          if (productDescription.contains(keyword)) {
            score += 3;
          }

          // Match in category
          if (productCategory.contains(keyword)) {
            score += 2;
          }
        }

        // Only include products with at least one keyword match
        if (score > 0) {
          scoredProducts.add(MapEntry(product, score));
        }
      }

      // Sort by score (highest first)
      scoredProducts.sort((a, b) => b.value.compareTo(a.value));

      if (scoredProducts.isNotEmpty) {
        setState(() {
          foundProducts = scoredProducts.map((entry) => entry.key).toList();
          selectedProductIndex = 0;
          showResults = true;
        });
      } else {
        if (mounted) {
          setState(() => showResults = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No matching products found. Try scanning again with clearer text.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching product: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Scan Text & Images'),
        elevation: 0,
      ),
      body: scannedValue.isNotEmpty && showResults
          ? _buildScanResultsView()
          : cameraReady
          ? _buildCameraView()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        CameraPreview(_cameraController),
        // Semi-transparent overlay
        Container(color: Colors.black.withValues(alpha: 0.3)),
        // Scanning frame overlay
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Point camera at text, images, or product labels',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _captureAndRecognizeText,
                      icon: const Icon(Icons.camera),
                      label: const Text('Capture & Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
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
    );
  }

  Widget _buildScanResultsView() {
    if (foundProducts.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.search_off, color: Colors.red.shade300, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'No Products Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(
                        color: Colors.orange.shade700,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Scanned Text:',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scannedValue,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No matching products found for this text. Try scanning again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              scannedValue = '';
                              showResults = false;
                              foundProducts = [];
                              selectedProductIndex = null;
                              isProcessing = false;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Scan Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final selectedProduct = foundProducts[selectedProductIndex ?? 0];
    final imageUrl = selectedProduct['imageUrl'] as String?;
    final name = selectedProduct['name'] ?? 'Unknown Product';
    final price = selectedProduct['price'] ?? 0.0;
    final description =
        selectedProduct['description'] ?? 'No description available';
    final stock = selectedProduct['quantity'] ?? 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: const Text(
                    'Product Recommendations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                // Scanned text display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    border: Border.all(color: Colors.teal.shade700, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Scanned Text:',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scannedValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Found products count
                Text(
                  'Found ${foundProducts.length} matching product${foundProducts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                // Product card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.teal.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade100.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Product image
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey.shade400,
                                        size: 48,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Colors.grey.shade400,
                                  size: 48,
                                ),
                              ),
                      ),
                      // Product info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Price
                            Text(
                              '₱${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Stock status
                            Row(
                              children: [
                                Icon(
                                  stock > 0 ? Icons.check_circle : Icons.cancel,
                                  color: stock > 0 ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stock > 0
                                        ? 'In Stock ($stock available)'
                                        : 'Out of Stock',
                                    style: TextStyle(
                                      color: stock > 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Description
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Product selector (if multiple products found)
                if (foundProducts.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Product:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              foundProducts.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedProductIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedProductIndex == index
                                            ? Colors.teal.shade700
                                            : Colors.grey.shade300,
                                        width: selectedProductIndex == index
                                            ? 2
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: selectedProductIndex == index
                                          ? Colors.teal.shade50
                                          : Colors.white,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child:
                                              foundProducts[index]['imageUrl'] !=
                                                  null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    foundProducts[index]['imageUrl'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Icon(
                                                            Icons.shopping_bag,
                                                            color: Colors
                                                                .grey
                                                                .shade400,
                                                          );
                                                        },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.shopping_bag,
                                                  color: Colors.grey.shade400,
                                                ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            scannedValue = '';
                            showResults = false;
                            foundProducts = [];
                            selectedProductIndex = null;
                            isProcessing = false;
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Scan Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: stock > 0
                            ? () {
                                // Create CartItem with quantity = 1
                                final cartItem = CartItem(
                                  id: selectedProduct['id'] ?? '',
                                  name: selectedProduct['name'] ?? '',
                                  imageUrl: selectedProduct['imageUrl'],
                                  price: (selectedProduct['price'] ?? 0)
                                      .toDouble(),
                                  quantity: 1,
                                );
                                _cartService.addItem(cartItem);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to cart!'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                );
                              }
                            : null,
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stock > 0
                              ? Colors.green.shade700
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
