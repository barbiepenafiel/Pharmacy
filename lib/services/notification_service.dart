import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  int _notificationId = 0;

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
}
