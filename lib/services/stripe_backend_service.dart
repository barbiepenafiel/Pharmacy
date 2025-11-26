// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'logger_service.dart';

/// Backend Stripe Service
/// Handles API communication with the backend for Stripe payments
class StripeBackendService {
  // Update this to your backend URL
  static const String baseUrl = 'https://your-backend-url.com/api';

  /// Create a payment intent by calling backend API
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/stripe/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
          'description': description,
          'customerId': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'client_secret': data['client_secret'],
          'payment_intent_id': data['payment_intent_id'],
        };
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      logger.error('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Confirm payment with backend
  static Future<bool> confirmPayment({required String paymentIntentId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/stripe/confirm-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to confirm payment: ${response.body}');
      }
    } catch (e) {
      logger.error('Error confirming payment: $e');
      rethrow;
    }
  }

  /// Update order with payment status
  static Future<bool> updateOrderPaymentStatus({
    required String orderId,
    required String paymentIntentId,
    required String status, // 'pending', 'succeeded', 'failed'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/payment-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update order status: ${response.body}');
      }
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.error('Error updating order status: $e');
      rethrow;
    }
  }

  /// Get payment intent status
  static Future<String> getPaymentIntentStatus(String paymentIntentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stripe/payment-intent/$paymentIntentId'),
        headers: {'Authorization': 'Bearer ${await user.getIdToken()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] ?? 'unknown';
      } else {
        throw Exception('Failed to get payment intent status');
      }
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.error('Error getting payment intent status: $e');
      rethrow;
    }
  }
}
