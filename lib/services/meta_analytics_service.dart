import 'dart:convert';

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meta_config.dart';

/// Isolated Meta App Events wrapper for Ads Manager attribution & optimization.
/// Never throws into UI flows — all SDK failures are swallowed safely.
class MetaAnalyticsService {
  MetaAnalyticsService._();
  static final MetaAnalyticsService instance = MetaAnalyticsService._();

  final FacebookAppEvents _fb = FacebookAppEvents();
  bool _initialized = false;
  static const String _registrationLoggedKey =
      'meta_complete_registration_logged';

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _fb.setGraphApiVersion('v24.0');

      final enableDebug = kDebugMode || MetaConfig.debugLogging;
      await _fb.setAutoLogAppEventsEnabled(true);
      // Collect advertiser ID where the OS allows it (ATT still gates IDFA on iOS).
      await _fb.setAdvertiserIdCollectionEnabled(true);
      await _fb.setDebugLoggingEnabled(enableDebug);

      await _fb.activateApp();
      _initialized = true;
      _log('initialized + activateApp');
    } catch (e, st) {
      _log('initialize failed: $e', st);
    }
  }

  /// App activation / open (also covered by SDK auto events + [activateApp]).
  Future<void> logAppOpen() async {
    await _safe(() async {
      await _fb.activateApp();
      _log('logAppOpen / activateApp');
    });
  }

  Future<void> logLogin({String method = 'phone_otp'}) async {
    await _safe(() async {
      // Custom event — Meta has no standard "Login" App Event name.
      await _fb.logEvent(
        name: 'Login',
        parameters: {
          'method': method,
        },
      );
      _log('logLogin method=$method');
    });
  }

  /// Fired once per install for phone-OTP apps (first successful verify).
  Future<void> logRegistration({String method = 'phone_otp'}) async {
    await _safe(() async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_registrationLoggedKey) == true) {
        _log('logRegistration skipped (already logged)');
        return;
      }

      await _fb.logCompletedRegistration(registrationMethod: method);
      await prefs.setBool(_registrationLoggedKey, true);
      _log('logRegistration method=$method');
    });
  }

  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    String? contentName,
    double? value,
    String currency = MetaConfig.currency,
  }) async {
    await _safe(() async {
      await _fb.logViewContent(
        id: contentId,
        type: contentType,
        currency: currency,
        price: value,
        content: contentName == null
            ? null
            : {
                'id': contentId,
                'quantity': 1,
                if (value != null) 'item_price': value,
                'title': contentName,
              },
      );
      _log('logViewContent id=$contentId value=$value');
    });
  }

  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required double value,
    required int quantity,
    String? contentName,
    String currency = MetaConfig.currency,
  }) async {
    await _safe(() async {
      await _fb.logAddToCart(
        id: contentId,
        type: contentType,
        currency: currency,
        price: value,
        content: {
          'id': contentId,
          'quantity': quantity,
          'item_price': value,
          if (contentName != null) 'title': contentName,
        },
        parameters: {
          FacebookAppEvents.paramNameNumItems: quantity,
        },
      );
      _log('logAddToCart id=$contentId qty=$quantity value=$value');
    });
  }

  Future<void> logInitiateCheckout({
    required double value,
    required int numItems,
    String currency = MetaConfig.currency,
    String? contentIdsJson,
  }) async {
    await _safe(() async {
      await _fb.logInitiatedCheckout(
        totalPrice: value,
        currency: currency,
        numItems: numItems,
        contentType: 'product',
        contentId: contentIdsJson,
        paymentInfoAvailable: false,
      );
      _log('logInitiateCheckout value=$value items=$numItems');
    });
  }

  Future<void> logPurchase({
    required double amount,
    String currency = MetaConfig.currency,
    String? orderId,
    int? numItems,
    String? contentIdsJson,
  }) async {
    await _safe(() async {
      final params = <String, dynamic>{
        if (orderId != null && orderId.isNotEmpty) 'fb_order_id': orderId,
        if (numItems != null) FacebookAppEvents.paramNameNumItems: numItems,
        if (contentIdsJson != null)
          FacebookAppEvents.paramNameContentId: contentIdsJson,
        FacebookAppEvents.paramNameContentType: 'product',
      };

      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: params,
      );
      _log('logPurchase amount=$amount orderId=$orderId');
    });
  }

  /// Force flush — useful while validating in Meta Test Events.
  Future<void> flush() async {
    await _safe(() async {
      await _fb.flush();
      _log('flush');
    });
  }

  static String encodeContentIds(Iterable<Object?> ids) {
    return jsonEncode(ids.map((e) => e.toString()).toList());
  }

  static double? parseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(',', '').trim());
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      await action();
    } catch (e, st) {
      _log('event failed: $e', st);
    }
  }

  void _log(String message, [StackTrace? st]) {
    if (kDebugMode || MetaConfig.debugLogging) {
      debugPrint('[MetaAnalytics] $message');
      if (st != null) debugPrint('$st');
    }
  }
}
