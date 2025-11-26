/// Stripe Configuration
/// WARNING: Secret key should only be used in backend/server environments
/// For production, implement tokenization flow on backend
class StripeConfig {
  // Publishable key (safe to expose in frontend)
  static const String publishableKey =
      'pk_test_51SRZ3m6Vaw0Zdf4YfN7ZzQ1Z8qYpj3iySgtzfVUCAZSRo8rwwuGGA9CmkoBZJ8SS63W3mHJuqKdWQlwd00BtUgOh2F';

  // Secret key (SHOULD ONLY BE USED ON BACKEND)
  // ⚠️ IMPORTANT: Never expose secret key in frontend code in production!
  // This is only for testing. Move to backend for production.
  static const String secretKey = 'YOUR_SECRET_KEY_HERE';

  // Stripe API version
  static const String apiVersion = '2023-10-16';

  // Test mode indicator
  static const bool isTestMode = true;
}
