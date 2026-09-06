import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_cache_service.dart';
import '../model/Product_Detail_model.dart';

class ProductDetailService {
  /// Instant read from local cache (no network).
  static Future<ProductDetailResponse?> getCachedProductDetail(int productId) {
    return ProductCacheService.getProductDetail(productId);
  }

  /// Network fetch + write to local cache.
  static Future<ProductDetailResponse?> fetchProductDetail(int productId) async {
    final url = Uri.parse('${ApiService.baseUrl}/customer/product/$productId');
    final token = await AuthStorage.getToken();

    try {
      print('Fetching product detail from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        // Persist full API response for next open
        await ProductCacheService.saveProductDetail(productId, jsonData);

        return ProductDetailResponse.fromJson(jsonData);
      } else {
        print('Failed to load product details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }
}
