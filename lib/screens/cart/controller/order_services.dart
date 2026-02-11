import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../../bottombar/MainScreen.dart';
import '../model/order_model.dart';

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
          'goHome': true,
        };
      }

      final response = await http.post(
        Uri.parse('$baseURL/customer/order/place'),
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
        return {
          'status': false,
          'message': 'Something went wrong. Please try again.',
          'goHome': true,
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
  /// Get order list
  static Future<List<OrderModel>> getOrders() async {
    final token = await AuthStorage.getToken();

    final res = await http.get(
      Uri.parse('$baseURL/customer/orders'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(res.body);

    // ✅ FIXED HERE
    if (res.statusCode == 200 && body['status'] == true) {
      return (body['data'] as List)
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }

    return [];
  }


  /// Get order details
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Unauthorized");

    final response = await http.get(
      Uri.parse('$baseURL/customer/order/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['status'] == true) {
      return body['data'];
    } else {
      throw Exception('Failed to load order detail');
    }
  }

}