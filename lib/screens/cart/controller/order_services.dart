import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';

class OrderService {
  static const String baseURL = '${ApiService.baseUrl}'; // Replace with your actual base URL

  // Place order
  static Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required String deliveryMethod,
    required String paymentType,
  }) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login to place order',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse('$baseURL/api/customer/order/place'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'address_id': addressId,
          'delivery_method': deliveryMethod,
          'payment_type': paymentType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await AuthStorage.logout();
        return {
          'status': false,
          'message': 'Session expired. Please login again',
          'requiresLogin': true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': false,
          'message': errorData['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Get order history (optional)
  static Future<Map<String, dynamic>> getOrderHistory() async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login',
          'requiresLogin': true,
        };
      }

      final response = await http.get(
        Uri.parse('$baseURL/api/customer/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Failed to fetch orders',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}