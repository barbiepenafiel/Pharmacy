// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../config/stripe_config.dart';
import 'stripe_backend_service.dart';
import 'logger_service.dart';

/// Stripe Payment Service
/// Handles payment processing and payment intents
class StripePaymentService {
  static final StripePaymentService _instance =
      StripePaymentService._internal();

  factory StripePaymentService() => _instance;

  StripePaymentService._internal() {
    _initializeStripe();
  }

  void _initializeStripe() {
    Stripe.publishableKey = StripeConfig.publishableKey;
    // For testing in development
    if (StripeConfig.isTestMode) {
      // Additional test configuration if needed
    }
  }

  /// Create a payment intent via backend API
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      return await StripeBackendService.createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
      );
    } catch (e) {
      logger.error('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Process payment using Stripe
  /// Returns the payment intent ID if successful
  Future<String?> processPayment({
    required String clientSecret,
    required double amount,
  }) async {
    try {
      // Initiate payment method
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Pharmacy App',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      // Extract payment intent ID from client secret
      // Format: client_secret = payment_intent_id_secret_xxxx
      final paymentIntentId = clientSecret.split('_secret_')[0];
      return paymentIntentId;
    } catch (e) {
      logger.error('Payment failed: $e');
      if (e is StripeException) {
        logger.error('Stripe error: ${e.error.localizedMessage}');
      }
      return null;
    }
  }

  /// Confirm payment with backend after successful payment sheet
  Future<bool> confirmPayment({required String paymentIntentId}) async {
    try {
      return await StripeBackendService.confirmPayment(
        paymentIntentId: paymentIntentId,
      );
    } catch (e) {
      logger.error('Error confirming payment: $e');
      return false;
    }
  }

  /// Get payment intent status from backend
  Future<String> getPaymentIntentStatus(String paymentIntentId) async {
    try {
      return await StripeBackendService.getPaymentIntentStatus(paymentIntentId);
    } catch (e) {
      logger.error('Error getting payment intent status: $e');
      return 'unknown';
    }
  }

  /// Update order payment status
  Future<bool> updateOrderPaymentStatus({
    required String orderId,
    required String paymentIntentId,
    required String status,
  }) async {
    try {
      return await StripeBackendService.updateOrderPaymentStatus(
        orderId: orderId,
        paymentIntentId: paymentIntentId,
        status: status,
      );
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.error('Error updating order payment status: $e');
      return false;
    }
  }

  /// Get Stripe publishable key (safe to use on frontend)
  String getPublishableKey() => StripeConfig.publishableKey;

  /// Check if Stripe is initialized
  bool isInitialized() => StripeConfig.publishableKey.isNotEmpty;
}
