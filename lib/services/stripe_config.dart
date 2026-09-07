/// Stripe configuration for inBozor checkout.
///
/// SECURITY: Never commit the live secret key.
/// Create PaymentIntents on Laravel in production.
/// Local/dev: pass secret with
/// `--dart-define=STRIPE_SECRET_KEY=<your_secret_key>`
class StripeConfig {
  StripeConfig._();

  static const String publishableKey =
      'pk_live_51OHbJcKK32cgFU8DKkLxjg7sCj0OY5edxOhJeTXRlnzxoTrFcV3AJjubVz4HgqxvTJjYP9PTHihn6mzdli6Qr8Aa002ENoEVOz';

  /// Live secret must NOT be in git. Pass at run/build time via dart-define.
  static const String secretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
    defaultValue: '',
  );

  static const String merchantDisplayName = 'inBozor';

  /// ISO currency for Stripe (cart UI shows "c." / TJS).
  static const String currency = 'tjs';

  /// Must match your Stripe account country (Dashboard → Settings → Business).
  /// Used by Apple Pay / Google Pay.
  static const String merchantCountryCode = 'US';

  /// Apple Pay Merchant ID from Apple Developer + Stripe Apple Pay settings.
  static const String appleMerchantId = 'merchant.com.inbozor.user';

  /// Return URL scheme for redirect-based payment methods (Link, etc.).
  static const String urlScheme = 'inbozor';

  /// Stripe Dashboard → Settings → Payment methods → Configuration ID.
  static const String paymentMethodConfigurationId =
      'pmc_1RrxsyKK32cgFU8D52Cdpzeh';
}
