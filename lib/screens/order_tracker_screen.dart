// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../services/logger_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class OrderTrackerScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;

  const OrderTrackerScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.items,
  });

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<Map<String, dynamic>?>? _orderSubscription;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;

  // Map related
  GoogleMapController? _mapController;
  LatLng? _deliveryLocation;
  LatLng? _currentDriverLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _locationUpdateTimer;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Order Placed',
      'description': 'Your order has been confirmed',
      'icon': Icons.shopping_cart,
      'color': Colors.green,
    },
    {
      'title': 'Processing',
      'description': 'We are preparing your order',
      'icon': Icons.hourglass_top,
      'color': Colors.blue,
    },
    {
      'title': 'Shipped',
      'description': 'Your order is on the way',
      'icon': Icons.local_shipping,
      'color': Colors.orange,
    },
    {
      'title': 'Delivered',
      'description': 'Order delivered successfully',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _initializeMap();
    _startLocationUpdates();
  }

  void _initializeMap() {
    // Use delivery address to determine approximate location
    // In a production app, you would use geocoding API
    final address = widget.deliveryAddress.toLowerCase();

    // Map Region 11 (Davao Region) addresses to coordinates
    if (address.contains('davao city') || address.contains('davao')) {
      // Davao City center (near San Pedro Cathedral)
      _deliveryLocation = const LatLng(7.0731, 125.6128);
    } else if (address.contains('tagum')) {
      // Tagum City
      _deliveryLocation = const LatLng(7.4479, 125.8078);
    } else if (address.contains('panabo')) {
      // Panabo City
      _deliveryLocation = const LatLng(7.3089, 125.6836);
    } else if (address.contains('samal') || address.contains('igacos')) {
      // Island Garden City of Samal
      _deliveryLocation = const LatLng(7.0737, 125.7100);
    } else if (address.contains('digos')) {
      // Digos City
      _deliveryLocation = const LatLng(6.7499, 125.3571);
    } else if (address.contains('mati')) {
      // Mati City
      _deliveryLocation = const LatLng(6.9549, 126.2185);
    } else if (address.contains('asuncion')) {
      // Asuncion
      _deliveryLocation = const LatLng(7.6022, 125.5347);
    } else if (address.contains('braulio') || address.contains('dujali')) {
      // Braulio E. Dujali
      _deliveryLocation = const LatLng(7.3628, 125.6481);
    } else if (address.contains('carmen')) {
      // Carmen
      _deliveryLocation = const LatLng(7.2167, 125.5833);
    } else if (address.contains('kapalong')) {
      // Kapalong
      _deliveryLocation = const LatLng(7.6167, 125.5167);
    } else if (address.contains('new corella')) {
      // New Corella
      _deliveryLocation = const LatLng(7.5667, 125.8167);
    } else if (address.contains('san isidro')) {
      // San Isidro (Davao del Norte or Oriental)
      _deliveryLocation = const LatLng(7.3833, 125.6167);
    } else if (address.contains('santo tomas')) {
      // Santo Tomas
      _deliveryLocation = const LatLng(7.5333, 125.6500);
    } else if (address.contains('talaingod')) {
      // Talaingod
      _deliveryLocation = const LatLng(7.5833, 125.5833);
    } else if (address.contains('bansalan')) {
      // Bansalan
      _deliveryLocation = const LatLng(6.7833, 125.2167);
    } else if (address.contains('hagonoy')) {
      // Hagonoy
      _deliveryLocation = const LatLng(6.6167, 125.3167);
    } else if (address.contains('kiblawan')) {
      // Kiblawan
      _deliveryLocation = const LatLng(6.6167, 125.1333);
    } else if (address.contains('magsaysay')) {
      // Magsaysay
      _deliveryLocation = const LatLng(6.5000, 125.1667);
    } else if (address.contains('malalag')) {
      // Malalag
      _deliveryLocation = const LatLng(6.5833, 125.4167);
    } else if (address.contains('matanao')) {
      // Matanao
      _deliveryLocation = const LatLng(6.9167, 125.2833);
    } else if (address.contains('padada')) {
      // Padada
      _deliveryLocation = const LatLng(6.6500, 125.3833);
    } else if (address.contains('santa cruz')) {
      // Santa Cruz
      _deliveryLocation = const LatLng(6.8833, 125.4167);
    } else if (address.contains('sulop')) {
      // Sulop
      _deliveryLocation = const LatLng(6.7000, 125.3333);
    } else if (address.contains('banaybanay')) {
      // Banaybanay
      _deliveryLocation = const LatLng(6.9667, 126.1000);
    } else if (address.contains('baganga')) {
      // Baganga
      _deliveryLocation = const LatLng(7.5667, 126.5667);
    } else if (address.contains('boston')) {
      // Boston
      _deliveryLocation = const LatLng(7.8667, 126.3667);
    } else if (address.contains('caraga')) {
      // Caraga
      _deliveryLocation = const LatLng(7.3167, 126.6000);
    } else if (address.contains('cateel')) {
      // Cateel
      _deliveryLocation = const LatLng(7.7833, 126.4500);
    } else if (address.contains('governor generoso')) {
      // Governor Generoso
      _deliveryLocation = const LatLng(6.5167, 126.0833);
    } else if (address.contains('lupon')) {
      // Lupon
      _deliveryLocation = const LatLng(6.8833, 126.0167);
    } else if (address.contains('manay')) {
      // Manay
      _deliveryLocation = const LatLng(7.1833, 126.5167);
    } else if (address.contains('tarragona')) {
      // Tarragona
      _deliveryLocation = const LatLng(7.3167, 126.0833);
    } else {
      // Default to Davao City center if address not recognized
      _deliveryLocation = const LatLng(7.0731, 125.6128);
    }

    // Set initial driver location (3-5 km away from delivery)
    // Simulate driver starting from a nearby location
    _currentDriverLocation = LatLng(
      _deliveryLocation!.latitude + 0.02, // ~2.2 km north
      _deliveryLocation!.longitude - 0.015, // ~1.5 km west
    );

    _updateMapMarkers();
  }

  void _startLocationUpdates() {
    // Simulate driver location updates every 3 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentDriverLocation != null && _deliveryLocation != null) {
        final currentStep = _getCurrentStep();

        // Only update location if order is in "shipped" status
        if (currentStep == 2) {
          setState(() {
            // Move driver closer to delivery location (simulation)
            final lat =
                _currentDriverLocation!.latitude +
                (_deliveryLocation!.latitude -
                        _currentDriverLocation!.latitude) *
                    0.1;
            final lng =
                _currentDriverLocation!.longitude +
                (_deliveryLocation!.longitude -
                        _currentDriverLocation!.longitude) *
                    0.1;

            _currentDriverLocation = LatLng(lat, lng);
            _updateMapMarkers();

            // Check if driver reached destination
            if (_calculateDistance(
                  _currentDriverLocation!,
                  _deliveryLocation!,
                ) <
                0.1) {
              timer.cancel();
            }
          });
        }
      }
    });
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Delivery Address',
            snippet: widget.deliveryAddress,
          ),
        ),
      );
    }

    if (_currentDriverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentDriverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Delivery Driver',
            snippet: 'On the way to your location',
          ),
        ),
      );

      // Draw route line
      if (_deliveryLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_currentDriverLocation!, _deliveryLocation!],
            color: Colors.blue,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // kilometers
    final double lat1 = start.latitude * 3.14159 / 180;
    final double lat2 = end.latitude * 3.14159 / 180;
    final double dLat = (end.latitude - start.latitude) * 3.14159 / 180;
    final double dLng = (end.longitude - start.longitude) * 3.14159 / 180;

    final double a =
        (1 - cos(dLat)) / 2 + cos(lat1) * cos(lat2) * (1 - cos(dLng)) / 2;
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  void _loadOrderData() {
    _orderSubscription = _firebaseService
        .watchOrder(widget.orderId)
        .listen(
          (orderData) {
            if (mounted) {
              setState(() {
                _orderData = orderData;
                _isLoading = false;
                _error = orderData == null ? 'Order not found' : null;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _error = 'Error loading order: $error';
                _isLoading = false;
              });
            }
          },
        );
  }

  int _getCurrentStep() {
    if (_orderData == null) return 0;

    final status = _orderData!['status']?.toString().toLowerCase() ?? 'pending';
    switch (status) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      case 'cancelled':
        return 0;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Order Tracking'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
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
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrderData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.orderId}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _orderData?['createdAt'] != null
                                        ? _formatDate(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              _orderData!['createdAt'] as int,
                                            ),
                                          )
                                        : _formatDate(DateTime.now()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '₱${(_orderData?['total'] ?? widget.totalAmount).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Live Tracking Map (show when order is shipped)
                    if (_getCurrentStep() >= 2 && _deliveryLocation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Delivery Tracking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _deliveryLocation!,
                                    zoom: 14.0,
                                  ),
                                  markers: _markers,
                                  polylines: _polylines,
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                  },
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                                // Distance/ETA Overlay
                                if (_currentDriverLocation != null)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                size: 16,
                                                color: Colors.blue.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${_calculateDistance(_currentDriverLocation!, _deliveryLocation!).toStringAsFixed(1)} km away',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ETA: ${(_calculateDistance(_currentDriverLocation!, _deliveryLocation!) / 0.5).round()} mins',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Center Map Button
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    onPressed: () {
                                      if (_mapController != null &&
                                          _currentDriverLocation != null &&
                                          _deliveryLocation != null) {
                                        // Calculate bounds to show both markers
                                        final lat1 =
                                            _currentDriverLocation!.latitude;
                                        final lat2 =
                                            _deliveryLocation!.latitude;
                                        final lng1 =
                                            _currentDriverLocation!.longitude;
                                        final lng2 =
                                            _deliveryLocation!.longitude;

                                        _mapController!.animateCamera(
                                          CameraUpdate.newLatLngBounds(
                                            LatLngBounds(
                                              southwest: LatLng(
                                                lat1 < lat2 ? lat1 : lat2,
                                                lng1 < lng2 ? lng1 : lng2,
                                              ),
                                              northeast: LatLng(
                                                lat1 > lat2 ? lat1 : lat2,
                                                lng1 > lng2 ? lng1 : lng2,
                                              ),
                                            ),
                                            50,
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(
                                      Icons.my_location,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Progress Timeline
                    Text(
                      'Delivery Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeline(),
                    const SizedBox(height: 24),

                    // Delivery Details
                    _buildDetailCard(
                      title: 'Delivery Address',
                      content:
                          _orderData?['deliveryAddress'] ??
                          widget.deliveryAddress,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      title: 'Payment Method',
                      content:
                          _orderData?['paymentMethod'] ?? widget.paymentMethod,
                      icon: Icons.payment,
                    ),
                    const SizedBox(height: 24),

                    // Items Summary
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildItemsList(),
                    const SizedBox(height: 24),

                    // Support Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Support team will contact you soon',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Need Help?'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate directly to home and clear the navigation stack
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeline() {
    final currentStep = _getCurrentStep();

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= currentStep;
        final isActive = index == currentStep;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Dot
                Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? step['color']
                            : Colors.grey.shade300,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: step['color'].withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(step['icon'], color: Colors.white, size: 24),
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        width: 3,
                        height: 40,
                        color: isCompleted
                            ? step['color']
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.black
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: step['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'In Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: step['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final List<dynamic> items = [];

    // Try to get items from order data first, then from widget
    if (_orderData != null && _orderData!['items'] != null) {
      final orderItems = _orderData!['items'];
      logger.info('Items from _orderData: $orderItems');
      logger.info('Items type: ${orderItems.runtimeType}');
      if (orderItems is List) {
        items.addAll(orderItems);
      } else if (orderItems is Map) {
        // Convert Map to List of items
        orderItems.forEach((key, value) {
          if (value is Map) {
            items.add(value);
          }
        });
      }
    } else if (widget.items.isNotEmpty) {
      logger.info('Items from widget.items: ${widget.items}');
      items.addAll(widget.items);
    }

    logger.info('Final items list: $items');
    logger.info('Items count: ${items.length}');

    if (items.isEmpty) {
      return Text(
        'No items in this order',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    return Column(
      children: items.map<Widget>((item) {
        try {
          // Debug: log the entire item object
          logger.info('Processing item: $item');
          logger.info('Item type: ${item.runtimeType}');

          // Safely extract item properties
          String? productName;
          int quantity = 1;
          double price = 0.0;

          if (item is Map) {
            logger.info('Item keys: ${item.keys.toList()}');

            // Try different field names for product name
            productName =
                item['productName'] ??
                item['name'] ??
                item['product_name'] ??
                (item['product'] is Map ? item['product']['name'] : null);

            logger.info(
              'Product name candidates - productName: ${item['productName']}, name: ${item['name']}, product_name: ${item['product_name']}',
            );
            logger.info('Extracted productName: $productName');

            quantity = _safeGetInt(item, 'quantity') ?? 1;
            price = _safeGetDouble(item, 'price') ?? 0.0;
          }

          productName ??= 'Unknown Product';

          logger.info(
            'Final display - Item: $productName, Qty: $quantity, Price: $price',
          );

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₱${(price * quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          logger.error('Error rendering item: $e');
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Error loading item',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }
      }).toList(),
    );
  }

  /// Safely extract int value from item
  int? _safeGetInt(dynamic item, String key) {
    try {
      if (item is! Map) return null;
      final value = item[key];
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Safely extract double value from item
  double? _safeGetDouble(dynamic item, String key) {
    try {
      if (item is! Map) return null;
      final value = item[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    } catch (e) {
      return null;
    }
  }
}
