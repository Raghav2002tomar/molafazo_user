import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../model/Product_Detail_model.dart';

class ProductDetailService {
  static const String baseURL = 'YOUR_BASE_URL'; // Replace with your actual base URL

  /// Fetch product details by ID
  static Future<ProductDetailResponse> fetchProductDetail(int productId) async {
    final url = Uri.parse('${ApiService.baseUrl}/customer/product/$productId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductDetailResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }
}