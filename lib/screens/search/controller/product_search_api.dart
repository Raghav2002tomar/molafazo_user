import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../bottombar/model/product_model.dart';

class ProductSearchApi {
  static const String baseUrl = ApiService.baseUrl;

  Future<List<ProductModel>> searchProducts({
    required String query,
    String? city,
    String? country,
  }) async {

    if (query.trim().isEmpty && city == null && country == null) {
      return [];
    }

    final prefs = await SharedPreferences.getInstance();
    final token = await AuthStorage.getToken();

    /// 🔹 Build query parameters
    final Map<String, String> queryParams = {
      if (query.trim().isNotEmpty) "search": query,
      if (city != null && city.isNotEmpty) "city": city,
      if (country != null && country.isNotEmpty) "country": country,
    };

    /// 🔹 Build URI
    final uri = Uri.parse(
      "$baseUrl/customer/products/search",
    ).replace(queryParameters: queryParams);

    print("Search URI: $uri");

    /// 🔹 Headers (token only if available)
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final response = await http.get(uri, headers: headers);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['status'] == true) {
      return (body['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    }

    throw Exception(body['message'] ?? "Search failed");
  }

  /// 🔹 Search products with just city filter
  Future<List<ProductModel>> getProductsByCity({
    required String city,
    String? country,
  }) async {
    return searchProducts(query: "", city: city, country: country);
  }

  /// 🔹 Search products with just country filter
  Future<List<ProductModel>> getProductsByCountry(String country) async {
    return searchProducts(query: "", country: country);
  }

  /// 🔹 Search products with query and location
  Future<List<ProductModel>> searchProductsInLocation({
    required String query,
    required String city,
    String? country,
  }) async {
    return searchProducts(query: query, city: city, country: country);
  }
}