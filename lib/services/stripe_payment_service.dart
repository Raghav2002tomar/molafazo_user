import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'stripe_config.dart';

class StripePaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? message;
  final bool cancelled;

  const StripePaymentResult({
    required this.success,
    this.paymentIntentId,
    this.message,
    this.cancelled = false,
  });
}

/// Stripe PaymentSheet for checkout Pay Online.
///
/// Apple Pay / Google Pay appear as wallet buttons (not separate Visa tiles).
/// They only show on a real device with Wallet set up.
class StripePaymentService {
  StripePaymentService._();
  static final StripePaymentService instance = StripePaymentService._();

  Future<void> configure() async {
    Stripe.publishableKey = StripeConfig.publishableKey.trim();
    Stripe.merchantIdentifier = StripeConfig.appleMerchantId;
    Stripe.urlScheme = StripeConfig.urlScheme;
    await Stripe.instance.applySettings();
  }

  Future<StripePaymentResult> pay({
    required double amountMajor,
    String currency = StripeConfig.currency,
    String? description,
  }) async {
    try {
      await configure();

      if (StripeConfig.secretKey.trim().isEmpty) {
        return const StripePaymentResult(
          success: false,
          message:
              'Stripe secret key missing. Pass STRIPE_SECRET_KEY via dart-define, or create PaymentIntents on your backend.',
        );
      }

      if (amountMajor <= 0) {
        return const StripePaymentResult(
          success: false,
          message: 'Invalid payment amount',
        );
      }

      final amountMinor = (amountMajor * 100).round();
      if (amountMinor < 1) {
        return const StripePaymentResult(
          success: false,
          message: 'Amount too small for payment',
        );
      }

      // Apple Pay only works on real iPhones with a card in Wallet.
      if (Platform.isIOS) {
        final applePayReady = await Stripe.instance.isPlatformPaySupported();
        debugPrint(
          '[Stripe] Apple Pay device ready=$applePayReady '
          'merchantId=${StripeConfig.appleMerchantId} '
          'country=${StripeConfig.merchantCountryCode}',
        );
        if (!applePayReady) {
          debugPrint(
            '[Stripe] Apple Pay button will be hidden. Use a real iPhone, '
            'add a card in Wallet, enable Apple Pay capability in Xcode, '
            'and rebuild the app.',
          );
        }
      }

      debugPrint(
        '[Stripe] Creating PaymentIntent amount=$amountMinor '
        'currency=${currency.toLowerCase()} '
        'platform=${Platform.isIOS ? 'ios' : 'android'}',
      );

      final intent = await _createPaymentIntent(
        amountMinor: amountMinor,
        currency: currency.toLowerCase(),
        description: description,
      );

      if (intent['error'] != null) {
        return StripePaymentResult(
          success: false,
          message: intent['error'].toString(),
        );
      }

      final clientSecret = intent['client_secret'] as String?;
      final paymentIntentId = intent['id'] as String?;

      if (clientSecret == null ||
          clientSecret.isEmpty ||
          !clientSecret.contains('_secret_')) {
        return const StripePaymentResult(
          success: false,
          message: 'Stripe did not return a valid client secret',
        );
      }

      debugPrint(
        '[Stripe] PaymentIntent=$paymentIntentId '
        'types=${intent['payment_method_types']}',
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: StripeConfig.merchantDisplayName,
          style: ThemeMode.system,
          returnURL: '${StripeConfig.urlScheme}://stripe-redirect',
          preferredNetworks: const [
            CardBrand.Visa,
            CardBrand.Mastercard,
            CardBrand.Amex,
          ],
          // IMPORTANT: do NOT set this to only ['card'] — that hides wallets.
          paymentMethodOrder: const [
            'apple_pay',
            'google_pay',
            'card',
            'link',
          ],
          applePay: Platform.isIOS
              ? const PaymentSheetApplePay(
                  merchantCountryCode: StripeConfig.merchantCountryCode,
                  buttonType: PlatformButtonType.pay,
                )
              : null,
          googlePay: Platform.isAndroid
              ? PaymentSheetGooglePay(
                  merchantCountryCode: StripeConfig.merchantCountryCode,
                  currencyCode: currency.toUpperCase(),
                  testEnv: false,
                )
              : null,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
            address: AddressCollectionMode.automatic,
            name: CollectionMode.automatic,
            email: CollectionMode.automatic,
            phone: CollectionMode.automatic,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return StripePaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
      );
    } on StripeException catch (e) {
      final cancelled = e.error.code == FailureCode.Canceled;
      final detail = [
        e.error.localizedMessage,
        e.error.message,
        'code=${e.error.code}',
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' | ');

      debugPrint('[Stripe] StripeException: $detail');
      return StripePaymentResult(
        success: false,
        cancelled: cancelled,
        message: cancelled
            ? 'Payment cancelled'
            : (detail.isNotEmpty ? detail : 'Payment failed'),
      );
    } catch (e) {
      debugPrint('[Stripe] Payment error: $e');
      return StripePaymentResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amountMinor,
    required String currency,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey.trim()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountMinor.toString(),
          'currency': currency,
          // Card + your Dashboard configuration (wallets ride on card).
          'automatic_payment_methods[enabled]': 'true',
          'payment_method_configuration':
              StripeConfig.paymentMethodConfigurationId,
          if (description != null && description.isNotEmpty)
            'description': description,
          'metadata[app]': 'inbozor',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[Stripe] create intent status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data['error'];
        final message = error is Map
            ? error['message']?.toString() ?? 'Stripe error'
            : 'Stripe error (${response.statusCode})';
        debugPrint('[Stripe] create intent failed: $message');

        // Fallback: card-only (Apple Pay still works on top of card).
        return _createCardOnlyIntent(
          amountMinor: amountMinor,
          currency: currency,
          description: description,
        );
      }

      return data;
    } catch (e) {
      return {
        'error': 'Unable to create Stripe PaymentIntent: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _createCardOnlyIntent({
    required int amountMinor,
    required String currency,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer ${StripeConfig.secretKey.trim()}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountMinor.toString(),
        'currency': currency,
        'payment_method_types[0]': 'card',
        if (description != null && description.isNotEmpty)
          'description': description,
        'metadata[app]': 'inbozor',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final message = error is Map
          ? error['message']?.toString() ?? 'Stripe error'
          : 'Stripe error (${response.statusCode})';
      return {'error': message};
    }
    return data;
  }
}
