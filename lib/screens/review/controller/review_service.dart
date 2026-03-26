// lib/screens/review/service/review_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../model/static_review_model.dart';

class ReviewService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<ReviewResponse> fetchProductReviews(int productId) async {
    try {
      final token = await AuthStorage.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/product/$productId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ReviewResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }
}