import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../../bottombar/model/product_model.dart';

class ProductSearchApi {
  static const String baseUrl = ApiService.baseUrl;

  /// OLD API - product search
  Future<List<ProductModel>> searchProducts({
    required String query,
    String? city,
    String? country,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) async {
    if (query.trim().isEmpty && city == null && country == null) {
      return [];
    }

    final token = await AuthStorage.getToken();

    final uri = Uri.parse("$baseUrl/customer/products/search").replace(
      queryParameters: {
        if (query.trim().isNotEmpty) "search": query.trim(),
        if (city != null && city.trim().isNotEmpty) "city": city.trim(),
        if (country != null && country.trim().isNotEmpty) "country": country.trim(),
        if (deliveryCity != null && deliveryCity.trim().isNotEmpty)
          "delivery_city": deliveryCity.trim(),
        if (deliveryType != null && deliveryType.trim().isNotEmpty)
          "delivery_type": deliveryType.trim(),
        if (deliveryTimeValue != null)
          "delivery_time_value": deliveryTimeValue.toString(),
        if (deliveryTimeUnit != null && deliveryTimeUnit.trim().isNotEmpty)
          "delivery_time_unit": deliveryTimeUnit.trim(),
      },
    );

    print("Product Search URI: ${Uri.decodeFull(uri.toString())}");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['status'] == true) {
      return (body['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    }

    throw Exception(body['message'] ?? "Search failed");
  }

  /// NEW API - category + store search
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) async {
    if (query.trim().isEmpty) return {};

    final token = await AuthStorage.getToken();

    final uri = Uri.parse("$baseUrl/global-search").replace(
      queryParameters: {
        "search": query.trim(),

        if (deliveryCity != null && deliveryCity.isNotEmpty)
          "delivery_city": deliveryCity,

        if (deliveryType != null && deliveryType.isNotEmpty)
          "delivery_type": deliveryType,

        if (deliveryTimeValue != null)
          "delivery_time_value": deliveryTimeValue.toString(),

        if (deliveryTimeUnit != null && deliveryTimeUnit.isNotEmpty)
          "delivery_time_unit": deliveryTimeUnit,
      },
    );

    print("Global Search URI: ${Uri.decodeFull(uri.toString())}");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty)
          "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['status'] == true) {
      return Map<String, dynamic>.from(body['data'] ?? {});
    }

    return {};
  }
}