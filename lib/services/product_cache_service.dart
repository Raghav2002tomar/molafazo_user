import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../screens/bottombar/model/product_model.dart';
import '../screens/product/model/Product_Detail_model.dart';

/// Local-first product cache using Hive.
/// Stores raw API JSON so models stay untouched and parsing stays consistent.
class ProductCacheService {
  static const String _listBoxName = 'product_list_cache';
  static const String _detailBoxName = 'product_detail_cache';

  static Box? _listBox;
  static Box? _detailBox;

  static Future<void> init() async {
    _listBox ??= await Hive.openBox(_listBoxName);
    _detailBox ??= await Hive.openBox(_detailBoxName);
  }

  static Future<void> _ensureReady() async {
    if (_listBox == null || _detailBox == null) {
      await init();
    }
  }

  /// Build a stable cache key from product-list query params.
  static String buildListCacheKey({
    int? categoryId,
    int? subCategoryId,
    int? childCategoryId,
    String? city,
    String? country,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    final parts = <String>[
      'cat=${categoryId ?? ''}',
      'sub=${subCategoryId ?? ''}',
      'child=${childCategoryId ?? ''}',
      'city=${city ?? ''}',
      'country=${country ?? ''}',
      'dCity=${deliveryCity ?? ''}',
      'dType=${deliveryType ?? ''}',
      'dVal=${deliveryTimeValue ?? ''}',
      'dUnit=${deliveryTimeUnit ?? ''}',
    ];
    return parts.join('|');
  }

  static String _detailKey(int productId) => 'product_$productId';

  // ─── Product list ───────────────────────────────────────────────

  static Future<void> saveProductList(
    String cacheKey,
    List<dynamic> rawList,
  ) async {
    try {
      await _ensureReady();
      await _listBox!.put(
        cacheKey,
        jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'data': rawList,
        }),
      );
    } catch (e) {
      // Cache write failures must never break the app
      print('ProductCacheService.saveProductList error: $e');
    }
  }

  static Future<List<ProductModel>?> getProductList(String cacheKey) async {
    try {
      await _ensureReady();
      final raw = _listBox!.get(cacheKey);
      if (raw == null) return null;

      final Map<String, dynamic> decoded =
          raw is String ? jsonDecode(raw) as Map<String, dynamic> : Map<String, dynamic>.from(raw);

      final data = decoded['data'];
      if (data is! List) return null;

      return data
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      print('ProductCacheService.getProductList error: $e');
      return null;
    }
  }

  /// Returns true if [fresh] is meaningfully different from [cached].
  static bool productListChanged(
    List<ProductModel> cached,
    List<ProductModel> fresh,
  ) {
    if (cached.length != fresh.length) return true;
    for (var i = 0; i < cached.length; i++) {
      final a = cached[i];
      final b = fresh[i];
      if (a.id != b.id ||
          a.price != b.price ||
          a.discountPrice != b.discountPrice ||
          a.name != b.name ||
          a.image != b.image ||
          a.isFavorite != b.isFavorite ||
          a.availableQuantity != b.availableQuantity) {
        return true;
      }
    }
    return false;
  }

  // ─── Product detail ─────────────────────────────────────────────

  static Future<void> saveProductDetail(
    int productId,
    Map<String, dynamic> rawJson,
  ) async {
    try {
      await _ensureReady();
      await _detailBox!.put(
        _detailKey(productId),
        jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'data': rawJson,
        }),
      );
    } catch (e) {
      print('ProductCacheService.saveProductDetail error: $e');
    }
  }

  static Future<ProductDetailResponse?> getProductDetail(int productId) async {
    try {
      await _ensureReady();
      final raw = _detailBox!.get(_detailKey(productId));
      if (raw == null) return null;

      final Map<String, dynamic> decoded =
          raw is String ? jsonDecode(raw) as Map<String, dynamic> : Map<String, dynamic>.from(raw);

      final data = decoded['data'];
      if (data is! Map) return null;

      return ProductDetailResponse.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('ProductCacheService.getProductDetail error: $e');
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      await _ensureReady();
      await _listBox!.clear();
      await _detailBox!.clear();
    } catch (e) {
      print('ProductCacheService.clearAll error: $e');
    }
  }
}
