import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../bottombar/model/product_model.dart';


class ProductSearchApi {
  static const String baseUrl = "${ApiService.baseUrl}";

  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse(
      "$baseUrl/customer/products/search?search=$query",
    );

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
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
}
