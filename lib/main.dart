// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:io';
import 'dart:async';
import 'services/logger_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/saved_addresses_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/order_tracker_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/cart_service.dart';
import 'config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Enable offline persistence for Firebase Realtime Database
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
    10000000,
  ); // 10MB cache

  // Initialize Stripe
  Stripe.publishableKey = StripeConfig.publishableKey;

  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: const WelcomeScreen(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Route guard - checks authentication before navigating to protected routes
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final authService = AuthService();

    switch (settings.name) {
      // Public routes (no authentication required)
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // Protected routes (authentication required) - but guests can still browse
      case '/home':
        // Allow both logged-in users and guests to access home
        return MaterialPageRoute(builder: (_) => const HomePage());

      // Admin-only route
      case '/admin':
        if (!authService.isLoggedIn()) {
          // Not logged in - redirect to login
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          );
        }
        // Let the admin dashboard screen itself check and handle admin role
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      // Default: return null to use the home property
      default:
        return null;
    }
  }
}

// Welcome / Splash Screen with animated background and logo
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Background gradient (static)
  final List<Color> _gradient = [
    const Color(0xFFe0f7fa),
    const Color(0xFFb2dfdb),
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Loop logo animation (pulse)
    _logoController.forward();
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logoController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _logoController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              // Logo and branding section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(31),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pharmacy App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trusted health partner',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Buttons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _navigateToHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade700,
                        side: BorderSide(color: Colors.teal.shade700, width: 2),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final CartService _cartService = CartService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigateToStore: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      const StoreScreen(),
      const TrackerScreen(),
      const ProfileScreen(),
    ];
  }

  int get _cartItemCount {
    return _cartService.itemCount;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        setState(() {});
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.teal.shade700,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(
                Icons.shopping_bag_outlined,
                _cartItemCount,
              ),
              activeIcon: _buildBadgeIcon(Icons.shopping_bag, _cartItemCount),
              label: 'Store',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              label: 'Tracker',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToStore;

  const HomeScreen({super.key, required this.onNavigateToStore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> newProducts = [];
  bool isLoadingProducts = true;
  final FirebaseService _firebaseService = FirebaseService();
  final CartService _cartService = CartService();

  // Notifications state
  final List<Map<String, dynamic>> _notifications = [];
  StreamSubscription<DatabaseEvent>? _ordersListener;
  StreamSubscription<DatabaseEvent>? _productsListener;
  StreamSubscription<DatabaseEvent>? _prescriptionsListener;

  @override
  void initState() {
    super.initState();
    _loadNewProducts();
    _setupNotificationListeners();
  }

  @override
  void dispose() {
    _ordersListener?.cancel();
    _productsListener?.cancel();
    _prescriptionsListener?.cancel();
    super.dispose();
  }

  void _setupNotificationListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen to new products
    _productsListener = FirebaseDatabase.instance
        .ref()
        .child('products')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;
          final productsData = event.snapshot.value as Map<dynamic, dynamic>;

          productsData.forEach((key, value) {
            final product = value as Map<dynamic, dynamic>;
            if (product['isNew'] == true) {
              final notification = {
                'type': 'new_product',
                'title': '✨ New Product Available',
                'body':
                    '${product['name']} just arrived at ₱${product['price']}',
                'icon': Icons.shopping_bag,
                'color': Colors.teal,
                'timestamp':
                    product['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              };

              if (!_notifications.any(
                (n) => n['body'] == notification['body'],
              )) {
                setState(() {
                  _notifications.insert(0, notification);
                  if (_notifications.length > 10) {
                    _notifications.removeLast();
                  }
                });
              }
            }
          });
        });

    // Listen to user's orders
    _ordersListener = FirebaseDatabase.instance
        .ref()
        .child('orders')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;
          final ordersData = event.snapshot.value as Map<dynamic, dynamic>;

          ordersData.forEach((key, value) {
            final order = value as Map<dynamic, dynamic>;
            if (order['userId'] == user.uid) {
              final status = order['status'];
              final orderId = order['id'] ?? key;

              if (status == 'shipped' || status == 'delivered') {
                String title = '';
                IconData icon = Icons.local_shipping;

                if (status == 'shipped') {
                  title = '📦 Order Shipped';
                } else if (status == 'delivered') {
                  title = '✅ Order Delivered';
                  icon = Icons.check_circle;
                }

                final notification = {
                  'type': 'order_update',
                  'title': title,
                  'body':
                      'Your order #${orderId.toString().substring(0, 8)} has been $status!',
                  'icon': icon,
                  'color': status == 'shipped' ? Colors.blue : Colors.green,
                  'timestamp':
                      order['updatedAt'] ??
                      DateTime.now().millisecondsSinceEpoch,
                };

                if (!_notifications.any(
                  (n) => n['body'] == notification['body'],
                )) {
                  setState(() {
                    _notifications.insert(0, notification);
                    if (_notifications.length > 10) {
                      _notifications.removeLast();
                    }
                  });
                }
              }
            }
          });
        });

    // Listen to prescriptions
    _prescriptionsListener = FirebaseDatabase.instance
        .ref()
        .child('prescriptions')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;
          final prescriptionsData =
              event.snapshot.value as Map<dynamic, dynamic>;

          prescriptionsData.forEach((key, value) {
            final prescription = value as Map<dynamic, dynamic>;
            if (prescription['userId'] == user.uid &&
                prescription['status'] == 'approved') {
              final notification = {
                'type': 'prescription',
                'title': '💊 Prescription Approved',
                'body': 'Your prescription is ready for pickup!',
                'icon': Icons.medical_services,
                'color': Colors.purple,
                'timestamp':
                    prescription['approvedAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              };

              if (!_notifications.any(
                (n) => n['body'] == notification['body'],
              )) {
                setState(() {
                  _notifications.insert(0, notification);
                  if (_notifications.length > 10) {
                    _notifications.removeLast();
                  }
                });
              }
            }
          });
        });
  }

  Future<void> _loadNewProducts() async {
    try {
      final allProducts = await _firebaseService.getAllProducts();
      setState(() {
        // Get the latest products (first 6)
        newProducts = allProducts.take(6).toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
      // Silently fail - will show placeholder products
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firebaseUser = authService.currentFirebaseUser;
    final userName = firebaseUser?.displayName ?? 'Guest';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: const DecorationImage(
                              image: AssetImage('assets/images/Logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $userName! 👋',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your health matters to us',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showNotificationsPanel(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 24,
                                color: Colors.black54,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScannerScreen(),
                            ),
                          );
                          if (result != null) {
                            _handleScannedProduct(result);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 24,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Upload Prescription Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload your prescription',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get medicine at your doorstep',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Promotional Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade200, Colors.amber.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade200.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '15% OFF',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Medicine on your doorstep',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Save up to 15% off on new orders',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to products store
                            widget.onNavigateToStore();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Shop Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/3176/3176366.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF006B6B),
                            size: 50,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Popular Categories
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Categories',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToStore,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Row(
                    children: [
                      Text(
                        'SEE ALL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.teal.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryItem(
                  'Medicine',
                  Icons.medication,
                  const Color(0xFFFFB6C1),
                  'Medicine',
                ),
                const SizedBox(width: 12),
                _buildCategoryItem(
                  'Diabetes',
                  Icons.devices,
                  const Color(0xFF87CEEB),
                  'Diabetes',
                ),
                const SizedBox(width: 12),
                _buildCategoryItem(
                  'Skin Care',
                  Icons.spa_outlined,
                  const Color(0xFFFFC0CB),
                  'Skin Care',
                ),
                const SizedBox(width: 12),
                _buildCategoryItem(
                  'Bandage',
                  Icons.healing,
                  const Color(0xFFFFDAB9),
                  'Bandage',
                ),
                const SizedBox(width: 12),
                _buildCategoryItem(
                  'Vitamins',
                  Icons.health_and_safety,
                  const Color(0xFFFFD700),
                  'Vitamins',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // New Products
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest additions to our collection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onNavigateToStore,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Row(
                    children: [
                      Text(
                        'SEE ALL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.teal.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : newProducts.isEmpty
                ? Center(
                    child: Text(
                      'No new products available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: newProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final product = newProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String label,
    IconData icon,
    Color color,
    String categoryFilter,
  ) {
    // Map specific category labels to asset images or URLs. If no asset is found, show the icon.
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
                Scaffold(body: ProductsScreen(categoryFilter: categoryFilter)),
          ),
        );
      },
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: assetPath == null && imageUrl == null
                    ? color.withAlpha(77)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(icon, color: color.withAlpha(204), size: 35),
                      )
                    : imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(icon, color: color.withAlpha(204), size: 35),
                      )
                    : Icon(icon, color: color.withAlpha(204), size: 35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final name = product['name'] ?? 'Unnamed Product';
    final price = product['price'] ?? 0;
    final imageUrl = product['imageUrl'];

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 95,
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
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.medication,
                      color: Colors.teal.shade400,
                      size: 48,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '₱${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade300),
            if (_notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(
                      notification['title'] ?? 'Notification',
                      notification['body'] ?? '',
                      notification['icon'] ?? Icons.notifications,
                      notification['color'] ?? Colors.grey,
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.notifications, color: Colors.white),
                label: const Text('Mark all as read'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(77),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        message,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Text(
        '2m ago',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      ),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Notification: $title')));
        Navigator.pop(context);
      },
    );
  }

  void _handleScannedProduct(dynamic result) {
    // If result is a string (scanned text), just show it
    if (result is String) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code, color: Colors.teal, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan Result',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          border: Border.all(
                            color: Colors.teal.shade700,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Scanned Text:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              result,
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scanned: $result')),
                            );
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(fontSize: 13),
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
      return;
    }

    // If result is a product object
    final product = result as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Product Found!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                product['name'] ?? 'Unknown Product',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '₱${(product['price'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${product['category'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Add to cart
                        final CartItem cartItem = CartItem(
                          id: product['id'] ?? '',
                          name:
                              product['name'] ??
                              product['productName'] ??
                              'Product',
                          imageUrl: product['imageUrl'] ?? product['image'],
                          price: (product['price'] ?? 0).toDouble(),
                          quantity: 1,
                        );
                        _cartService.addItem(cartItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${cartItem.name} added to cart'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                      ),
                      child: const Text('Add to Cart'),
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
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService _authService;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentFirebaseUser;
    if (user != null) {
      try {
        final profile = await _firebaseService.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;
        });
      } catch (e) {
        logger.error('Error loading profile: $e');
      }
    }
  }

  void _showEditProfileDialog() {
    final user = _authService.currentFirebaseUser;
    if (user == null) return;

    final nameController = TextEditingController(
      text: _userProfile?['name'] ?? user.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: _userProfile?['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: _userProfile?['address'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
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
              await _updateProfile(
                nameController.text,
                phoneController.text,
                addressController.text,
              );
              // ignore: use_build_context_synchronously
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String name, String phone, String address) async {
    final user = _authService.currentFirebaseUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Update display name in Firebase Auth
      await user.updateDisplayName(name);
      await user.reload();

      // Update profile in database
      final profileData = {
        'name': name,
        'email': user.email,
        'phone': phone,
        'address': address,
        'photoUrl': _userProfile?['photoUrl'] ?? '',
      };

      await _firebaseService.updateUserProfile(user.uid, profileData);
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final user = _authService.currentFirebaseUser;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to Firebase Storage
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://pharmacy-app-67eab.firebasestorage.app',
      );
      final fileName = 'profile_photos/${user.uid}.jpg';
      final storageRef = storage.ref().child(fileName);
      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile with photo URL
      await _firebaseService.updateUserProfile(user.uid, {
        'photoUrl': downloadUrl,
      });

      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
    final firebaseUser = _authService.currentFirebaseUser;
    final isLoggedIn = firebaseUser != null;
    final photoUrl = _userProfile?['photoUrl'] as String?;

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: isLoggedIn ? _uploadProfilePhoto : null,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal.shade100,
                          image: photoUrl != null && photoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                color: Colors.teal.shade700,
                                size: 48,
                              )
                            : null,
                      ),
                    ),
                    if (isLoggedIn)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isLoggedIn
                      ? (_userProfile?['name'] as String?) ??
                            firebaseUser.displayName ??
                            'User'
                      : 'Guest User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isLoggedIn
                      ? firebaseUser.email ?? 'guest@example.com'
                      : 'Not logged in',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildProfileMenuItem('My Orders', Icons.shopping_bag, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                }),
                _buildProfileMenuItem('Prescriptions', Icons.description, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrescriptionsScreen(),
                    ),
                  );
                }),
                _buildProfileMenuItem('Saved Addresses', Icons.location_on, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen(),
                    ),
                  );
                }),
                _buildProfileMenuItem('Payment Methods', Icons.payment, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  );
                }),
                _buildProfileMenuItem('Settings', Icons.settings, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }),
                _buildProfileMenuItem('Help & Support', Icons.help, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Developers Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Development Team',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDeveloperCard(
                        'Barbie T. Penafiel',
                        'Lead Developer',
                        'barbiepenafiel2019@gmail.com',
                        imagePath: 'assets/images/profi.png',
                      ),
                      const SizedBox(height: 10),
                      _buildDeveloperCard(
                        'Chenybabes Dalougdug',
                        'UI/UX Designer',
                        'chenybabes.dalogdug@gmail.com',
                        imagePath: 'assets/images/cheni.jpg',
                      ),
                      const SizedBox(height: 10),
                      _buildDeveloperCard(
                        'Laiza Pueblo',
                        'Database Engineer',
                        'laiza.pueblo@gmail.com',
                        imagePath: 'assets/images/lai.jpg',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoggedIn)
                  ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDeveloperCard(
    String name,
    String role,
    String email, {
    String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              shape: BoxShape.circle,
              image: imagePath != null
                  ? DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.email, size: 18),
            onPressed: () {
              // Could implement email functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contact: $email'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Store Screen
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductsScreen();
  }
}

// Tracker Screen - Shows all user orders with tracking
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> orders = [];
  bool loading = true;
  String? errorMessage;
  StreamSubscription? _ordersSubscription;

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

  void _loadOrders() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) {
        setState(() {
          loading = false;
          errorMessage = 'Please login to view your orders';
        });
        return;
      }

      // Use real-time listener for automatic updates
      _ordersSubscription = _firebaseService.watchUserOrders().listen(
        (ordersList) {
          setState(() {
            // Sort by createdAt descending (newest first)
            orders = ordersList
              ..sort((a, b) {
                final aTime = a['createdAt'] ?? 0;
                final bTime = b['createdAt'] ?? 0;
                return bTime.compareTo(aTime);
              });
            loading = false;
            errorMessage = null;
          });
        },
        onError: (error) {
          setState(() {
            loading = false;
            errorMessage = 'Error loading orders: ${error.toString()}';
          });
        },
      );
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Error loading orders: ${e.toString()}';
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
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
    } catch (e) {
      return 'N/A';
    }
  }

  String _getOrderItemsSummary(dynamic items) {
    if (items == null) return 'No items';

    try {
      final itemsList = <String>[];

      // Handle Map format
      if (items is Map) {
        items.forEach((key, item) {
          if (item is Map) {
            final name =
                item['name'] ?? item['productName'] ?? 'Unknown Product';
            final qty = item['quantity'] ?? 1;
            itemsList.add('$name (x$qty)');
          }
        });
      }
      // Handle List format
      else if (items is List) {
        for (var item in items) {
          if (item is Map) {
            final name =
                item['name'] ?? item['productName'] ?? 'Unknown Product';
            final qty = item['quantity'] ?? 1;
            itemsList.add('$name (x$qty)');
          }
        }
      }

      if (itemsList.isEmpty) return 'No items';
      return itemsList.join(', ');
    } catch (e) {
      logger.error('Error formatting items: $e');
      return 'Multiple items';
    }
  }

  List<Map<String, dynamic>> _safeConvertItems(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      try {
        return items.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      } catch (e) {
        logger.error('Error converting items: $e');
        return [];
      }
    }
    return [];
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
                  'Order Tracker',
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
              'Track all your orders',
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
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
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
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
                    'Your order tracking will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = order['status'] ?? 'unknown';
                final statusColor = _getStatusColor(status);
                final statusIcon = _getStatusIcon(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.cyan.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade200.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // Navigate to Order Tracker screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackerScreen(
                            orderId: order['id'] ?? '',
                            totalAmount: (order['total'] ?? 0.0).toDouble(),
                            deliveryAddress: order['deliveryAddress'] ?? 'N/A',
                            paymentMethod: order['paymentMethod'] ?? 'N/A',
                            items: _safeConvertItems(order['items']),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.teal.shade900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(order['createdAt']),
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                  _getOrderItemsSummary(order['items']),
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(thickness: 1, height: 1),
                          const SizedBox(height: 12),
                          // Total and Track Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackerScreen(
                                        orderId: order['id'] ?? '',
                                        totalAmount: (order['total'] ?? 0.0)
                                            .toDouble(),
                                        deliveryAddress:
                                            order['deliveryAddress'] ?? 'N/A',
                                        paymentMethod:
                                            order['paymentMethod'] ?? 'N/A',
                                        items: _safeConvertItems(
                                          order['items'],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.location_on, size: 16),
                                label: const Text('Track'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
              },
            ),
    );
  }
}
