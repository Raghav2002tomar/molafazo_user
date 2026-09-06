import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/product/product_details_screen.dart';
import '../screens/product/store_detail_screen.dart';

/// Handles incoming product / store share deep links.
///
/// Supported formats:
/// - https://mudir.inbozor.app/product/{id}
/// - https://mudir.inbozor.app/store/{id}
/// - inbozor://product/{id}
/// - inbozor://store/{id}
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  int? _pendingProductId;
  int? _pendingStoreId;
  bool _initialized = false;

  static const String shareHost = 'mudir.inbozor.app';
  static const String customScheme = 'inbozor';

  /// Public HTTPS link shared with other users.
  static String productShareUrl(int productId) =>
      'https://$shareHost/product/$productId';

  static String storeShareUrl(int storeId) =>
      'https://$shareHost/store/$storeId';

  /// Custom scheme used by the web landing page to open the app.
  static String productAppUrl(int productId) =>
      '$customScheme://product/$productId';

  static String storeAppUrl(int storeId) =>
      '$customScheme://store/$storeId';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Cold start (app opened from a link)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }

    // Warm start (app already running)
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('DeepLinkService stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    final storeId = parseStoreId(uri);
    if (storeId != null) {
      openStore(storeId);
      return;
    }

    final productId = parseProductId(uri);
    if (productId != null) {
      openProduct(productId);
      return;
    }

    debugPrint('DeepLinkService: ignored uri $uri');
  }

  /// Parse product id from supported deep-link URIs.
  static int? parseProductId(Uri uri) {
    // https://mudir.inbozor.app/product/123
    // https://mudir.inbozor.app/share/product/123
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[segments.length - 2] == 'product') {
      return int.tryParse(segments.last);
    }
    if (segments.isNotEmpty && segments.first == 'product') {
      return int.tryParse(segments.length > 1 ? segments[1] : '');
    }

    // inbozor://product/123  → host=product, path=/123
    if (uri.scheme == customScheme && uri.host == 'product') {
      final idFromPath = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceAll('/', '');
      return int.tryParse(idFromPath);
    }

    // ?product_id=123
    return int.tryParse(uri.queryParameters['product_id'] ?? '');
  }

  /// Parse store id from supported deep-link URIs.
  static int? parseStoreId(Uri uri) {
    // https://mudir.inbozor.app/store/123
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[segments.length - 2] == 'store') {
      return int.tryParse(segments.last);
    }
    if (segments.isNotEmpty && segments.first == 'store') {
      return int.tryParse(segments.length > 1 ? segments[1] : '');
    }

    // inbozor://store/123
    if (uri.scheme == customScheme && uri.host == 'store') {
      final idFromPath = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceAll('/', '');
      return int.tryParse(idFromPath);
    }

    return int.tryParse(uri.queryParameters['store_id'] ?? '');
  }

  void openProduct(int productId) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingProductId = productId;
      _retryPendingNavigation();
      return;
    }

    _pendingProductId = null;
    nav.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  void openStore(int storeId) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingStoreId = storeId;
      _retryPendingNavigation();
      return;
    }

    _pendingStoreId = null;
    nav.push(
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(storeId: storeId),
      ),
    );
  }

  /// Call after splash / main screen is ready so pending links open.
  void flushPending() {
    final storeId = _pendingStoreId;
    if (storeId != null) {
      openStore(storeId);
      return;
    }
    final productId = _pendingProductId;
    if (productId != null) {
      openProduct(productId);
    }
  }

  void _retryPendingNavigation({int attempt = 0}) {
    if ((_pendingProductId == null && _pendingStoreId == null) ||
        attempt > 20) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_pendingProductId == null && _pendingStoreId == null) return;
      if (navigatorKey.currentState != null) {
        flushPending();
      } else {
        _retryPendingNavigation(attempt: attempt + 1);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
