import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../model/store_detail.dart';

class StoreDetailService {

  /// Fetch store details by ID
  static Future<StoreDetailResponse> fetchStoreDetail(int storeId) async {
    final url = Uri.parse('${ApiService.baseUrl}/customer/store/$storeId');

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
        return StoreDetailResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load store details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching store details: $e');
    }
  }
}