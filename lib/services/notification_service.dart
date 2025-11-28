import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggerService _logger = LoggerService();

  int _notificationId = 0;
  StreamSubscription<DatabaseEvent>? _ordersListener;
  StreamSubscription<DatabaseEvent>? _productsListener;
  StreamSubscription<DatabaseEvent>? _offersListener;

  NotificationService._internal() {
    _initializeNotifications();
  }

  factory NotificationService() {
    return _instance;
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    _notificationsPlugin.initialize(initSettings);
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pharmacy_channel',
          'Pharmacy Notifications',
          channelDescription: 'Notifications for pharmacy app',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      _notificationId++,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show a notification for new products
  Future<void> showNewProductNotification(
    String productName,
    String price,
  ) async {
    await showNotification(
      title: '✨ New Product Available',
      body: '$productName just arrived at ₱$price',
      payload: 'new_product:$productName',
    );
  }

  /// Show a notification for order status
  Future<void> showOrderNotification(String orderNumber, String status) async {
    String message = '';
    switch (status.toLowerCase()) {
      case 'processing':
        message = 'Your order #$orderNumber is being processed';
        break;
      case 'shipped':
        message = 'Your order #$orderNumber has been shipped!';
        break;
      case 'delivered':
        message = 'Your order #$orderNumber has been delivered!';
        break;
      default:
        message = 'Update on your order #$orderNumber';
    }

    await showNotification(
      title: '📦 Order Update',
      body: message,
      payload: 'order:$orderNumber',
    );
  }

  /// Show a notification for special offers
  Future<void> showOfferNotification(String offerTitle, String discount) async {
    await showNotification(
      title: '🎉 Special Offer',
      body: '$offerTitle - Save up to $discount!',
      payload: 'offer:$offerTitle',
    );
  }

  /// Show a notification for prescription alerts
  Future<void> showPrescriptionNotification(
    String medicationName,
    String dosage,
  ) async {
    await showNotification(
      title: '💊 Prescription Ready',
      body: '$medicationName ($dosage) is ready for pickup',
      payload: 'prescription:$medicationName',
    );
  }

  /// Listen to real-time order updates from Firebase
  void listenToOrderUpdates() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _ordersListener = _database
          .ref()
          .child('orders')
          .orderByChild('userId')
          .equalTo(user.uid)
          .onValue
          .listen((event) {
            if (!event.snapshot.exists) return;

            final ordersData = event.snapshot.value as Map<dynamic, dynamic>;
            ordersData.forEach((key, value) {
              final order = value as Map<dynamic, dynamic>;
              final orderNumber = order['orderNumber'] ?? key;
              final status = order['status'] ?? 'unknown';
              final previousStatus = order['previousStatus'];

              // Only notify if status changed
              if (previousStatus != null && previousStatus != status) {
                showOrderNotification(
                  orderNumber.toString(),
                  status.toString(),
                );
                _logger.info(
                  'Order update notification: $orderNumber - $status',
                );
              }
            });
          });
    } catch (e) {
      _logger.error('Error listening to order updates: $e');
    }
  }

  /// Listen to new product additions from Firebase
  void listenToNewProducts() {
    try {
      _productsListener = _database
          .ref()
          .child('products')
          .orderByChild('createdAt')
          .onValue
          .listen((event) {
            if (!event.snapshot.exists) return;

            final productsData = event.snapshot.value as Map<dynamic, dynamic>;
            productsData.forEach((key, value) {
              final product = value as Map<dynamic, dynamic>;
              final productName = product['name'] ?? 'New Product';
              final price = product['price'] ?? '0.00';
              final isNew = product['isNew'] ?? false;

              // Notify about new products
              if (isNew) {
                showNewProductNotification(
                  productName.toString(),
                  price.toString(),
                );
                _logger.info(
                  'New product notification: $productName - ₱$price',
                );
              }
            });
          });
    } catch (e) {
      _logger.error('Error listening to new products: $e');
    }
  }

  /// Listen to special offers from Firebase
  void listenToOffers() {
    try {
      _offersListener = _database
          .ref()
          .child('offers')
          .orderByChild('isActive')
          .equalTo(true)
          .onValue
          .listen((event) {
            if (!event.snapshot.exists) return;

            final offersData = event.snapshot.value as Map<dynamic, dynamic>;
            offersData.forEach((key, value) {
              final offer = value as Map<dynamic, dynamic>;
              final offerTitle = offer['title'] ?? 'Special Offer';
              final discount = offer['discount'] ?? '0%';

              showOfferNotification(offerTitle.toString(), discount.toString());
              _logger.info('Offer notification: $offerTitle - $discount off');
            });
          });
    } catch (e) {
      _logger.error('Error listening to offers: $e');
    }
  }

  /// Start all real-time notification listeners
  void startListeners() {
    _logger.info('Starting real-time notification listeners');
    listenToOrderUpdates();
    listenToNewProducts();
    listenToOffers();
  }

  /// Stop all real-time notification listeners
  void stopListeners() {
    _logger.info('Stopping real-time notification listeners');
    _ordersListener?.cancel();
    _productsListener?.cancel();
    _offersListener?.cancel();
  }

  /// Dispose all resources
  void dispose() {
    stopListeners();
  }
}
