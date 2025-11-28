import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'logger_service.dart';

/// Service for managing notification preferences with Firebase integration
/// Handles real-time syncing of notification settings (push, email, order updates)
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final LoggerService _logger = LoggerService();

  late StreamSubscription<DatabaseEvent>? _preferencesListener;

  factory NotificationPreferencesService() {
    return _instance;
  }

  NotificationPreferencesService._internal();

  /// Get the notification preferences reference for the current user
  DatabaseReference _getPreferencesRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return _database
        .ref()
        .child('users')
        .child(user.uid)
        .child('notificationPreferences');
  }

  /// Save notification preferences to Firebase
  Future<({bool success, String message})> saveNotificationPreferences({
    required bool pushNotifications,
    required bool emailUpdates,
    required bool orderUpdates,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, message: 'No user logged in');
      }

      await _getPreferencesRef().set({
        'pushNotifications': pushNotifications,
        'emailUpdates': emailUpdates,
        'orderUpdates': orderUpdates,
        'updatedAt': ServerValue.timestamp,
      });

      _logger.info(
        'Notification preferences saved: push=$pushNotifications, email=$emailUpdates, orders=$orderUpdates',
      );

      return (success: true, message: 'Notification preferences saved');
    } catch (e) {
      _logger.error('Error saving notification preferences: $e');
      return (success: false, message: 'Error saving preferences: $e');
    }
  }

  /// Get notification preferences from Firebase
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _getPreferencesRef().get();
      if (!snapshot.exists) {
        // Return defaults if not set
        return {
          'pushNotifications': true,
          'emailUpdates': true,
          'orderUpdates': true,
        };
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      return {
        'pushNotifications': data?['pushNotifications'] ?? true,
        'emailUpdates': data?['emailUpdates'] ?? true,
        'orderUpdates': data?['orderUpdates'] ?? true,
        'updatedAt': data?['updatedAt'],
      };
    } catch (e) {
      _logger.error('Error getting notification preferences: $e');
      return null;
    }
  }

  /// Listen to real-time notification preference changes
  /// Returns a stream of notification preferences
  Stream<Map<String, dynamic>> getNotificationPreferencesStream() {
    try {
      return _getPreferencesRef().onValue.map((event) {
        if (!event.snapshot.exists) {
          return {
            'pushNotifications': true,
            'emailUpdates': true,
            'orderUpdates': true,
          };
        }

        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'pushNotifications': data['pushNotifications'] ?? true,
          'emailUpdates': data['emailUpdates'] ?? true,
          'orderUpdates': data['orderUpdates'] ?? true,
          'updatedAt': data['updatedAt'],
        };
      });
    } catch (e) {
      _logger.error('Error getting notification preferences stream: $e');
      return Stream.value({
        'pushNotifications': true,
        'emailUpdates': true,
        'orderUpdates': true,
      });
    }
  }

  /// Dispose listeners when needed
  void dispose() {
    _preferencesListener?.cancel();
  }
}
