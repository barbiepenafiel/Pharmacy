// ignore_for_file: avoid_print

// ignore: duplicate_ignore
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/stripe_payment_service.dart';
import '../services/logger_service.dart';

/// Stripe Payment Screen
/// Handles card payment processing through Stripe
class StripePaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final String deliveryAddress;
  final VoidCallback onPaymentSuccess;
  final Function(String) onPaymentError;

  const StripePaymentScreen({
    required this.amount,
    required this.orderId,
    required this.deliveryAddress,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    super.key,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  final StripePaymentService _stripePaymentService = StripePaymentService();
  bool _isProcessing = false;

  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Step 1: Create payment intent on backend
      logger.info('Creating payment intent for amount: ${widget.amount}');
      final paymentIntent = await _stripePaymentService.createPaymentIntent(
        amount: widget.amount,
        currency: 'PHP',
        description: 'Order #${widget.orderId}',
      );

      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.info(
        'Payment intent created: ${paymentIntent['payment_intent_id']}',
      );
      final clientSecret = paymentIntent['client_secret'];
      final paymentIntentId = paymentIntent['payment_intent_id'];

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Invalid client secret from server');
      }

      // Step 2: Process payment with Stripe
      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.info('Processing payment with Stripe...');
      final result = await _stripePaymentService.processPayment(
        clientSecret: clientSecret,
        amount: widget.amount,
      );

      if (result != null) {
        // ignore: duplicate_ignore
        // ignore: avoid_print
        logger.info('Payment successful! Payment intent ID: $result');

        // Step 3: Confirm payment with backend
        // ignore: duplicate_ignore
        // ignore: avoid_print
        logger.info('Confirming payment with backend...');
        final confirmed = await _stripePaymentService.confirmPayment(
          paymentIntentId: paymentIntentId,
        );

        if (confirmed) {
          // ignore: duplicate_ignore
          // ignore: avoid_print
          logger.info('Payment confirmed! Creating order...');

          // Step 4: Update order payment status
          await _stripePaymentService.updateOrderPaymentStatus(
            orderId: widget.orderId,
            paymentIntentId: paymentIntentId,
            status: 'succeeded',
          );

          if (mounted) {
            widget.onPaymentSuccess();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Order created.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Payment confirmation failed');
        }
      } else {
        throw Exception('Payment was cancelled or failed');
      }
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      logger.error('Payment error: $e');
      if (mounted) {
        widget.onPaymentError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order ID:'),
                          Text(
                            widget.orderId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount:'),
                          Text(
                            '₱${widget.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery:'),
                          Expanded(
                            child: Text(
                              widget.deliveryAddress,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Secure Payment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your payment is secured by Stripe encryption',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
