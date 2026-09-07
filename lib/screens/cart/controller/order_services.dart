import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../bottombar/MainScreen.dart';
import '../model/order_model.dart';

class OrderService {
  static const String baseURL = '${ApiService.baseUrl}'; // Replace with your actual base URL

  // Place order
  // static Future<Map<String, dynamic>> placeOrder({
  //   required int addressId,
  //   required String deliveryMethod,
  //   required String paymentType,
  // }) async {
  //   try {
  //     final token = await AuthStorage.getToken();
  //     if (token == null) {
  //       return {
  //         'status': false,
  //         'message': 'Please login to place order',
  //         'goHome': true,
  //       };
  //     }
  //
  //     final response = await http.post(
  //       Uri.parse('$baseURL/customer/order/place'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode({
  //         'address_id': addressId,
  //         'delivery_method': deliveryMethod,
  //         'payment_type': paymentType,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     } else if (response.statusCode == 401) {
  //       return {
  //         'status': false,
  //         'message': 'Something went wrong. Please try again.',
  //         'goHome': true,
  //       };
  //     } else {
  //       final errorData = jsonDecode(response.body);
  //       return {
  //         'status': false,
  //         'message': errorData['message'] ?? 'Failed to place order',
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       'status': false,
  //       'message': 'Error: ${e.toString()}',
  //     };
  //   }
  // }



  static Future<Map<String, dynamic>> placeOrder({
     String? addressId,
    required String deliveryMethod,
    required String paymentType,
    Map<String, dynamic>? bankDetails,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      return {
        'status': false,
        'message': 'Please login to continue',
        'goHome': true,
      };
    }

    try {
      // Create request body
      Map<String, dynamic> requestBody = {
        'address_id': addressId,
        'delivery_method': deliveryMethod,
        'payment_type': paymentType,
      };

      // Add bank details if payment type is online AND bankDetails are provided
      // Your backend expects bank_id when payment_type is "online"
      if (paymentType == 'online' && bankDetails != null) {
        requestBody['bank_id'] = bankDetails['bank_id'];
      }

      debugPrint('Order Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseURL/customer/order/place'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      debugPrint('Order Response: $data');

      return data;
    } catch (e) {
      debugPrint('Order placement error: $e');
      return {
        'status': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // You can add other order-related methods here
  static Future<Map<String, dynamic>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      return {
        'status': false,
        'message': 'Please login to continue',
        'goHome': true,
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Order history error: $e');
      return {
        'status': false,
        'message': 'Network error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      return {
        'status': false,
        'message': 'Please login to continue',
        'goHome': true,
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/order/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Order details error: $e');
      return {
        'status': false,
        'message': 'Network error occurred',
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

// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../services/api_service.dart';
//
// class OrderService {
//   static Future<Map<String, dynamic>> placeOrder({
//     required int addressId,
//     required String deliveryMethod,
//     required String paymentType,
//     Map<String, dynamic>? bankDetails, // Add this parameter
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('api_token');
//
//     if (token == null) {
//       return {
//         'status': false,
//         'message': 'Please login to continue',
//         'goHome': true,
//       };
//     }
//
//     try {
//       // Create request body
//       Map<String, dynamic> requestBody = {
//         'address_id': addressId,
//         'delivery_method': deliveryMethod,
//         'payment_type': paymentType,
//       };
//
//       // Add bank details if payment type is bank
//       if (paymentType == 'bank' && bankDetails != null) {
//         requestBody['bank_id'] = bankDetails['bank_id'];
//         // You can add more bank details if your API requires them
//         // requestBody['account_number'] = bankDetails['account_number'];
//         // requestBody['account_holder_name'] = bankDetails['account_holder_name'];
//       }
//
//       debugPrint('Order Request: ${jsonEncode(requestBody)}');
//
//       final response = await http.post(
//         Uri.parse('${ApiService.baseUrl}/order/place'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       final data = jsonDecode(response.body);
//       debugPrint('Order Response: $data');
//
//       return data;
//     } catch (e) {
//       debugPrint('Order placement error: $e');
//       return {
//         'status': false,
//         'message': 'Network error occurred: ${e.toString()}',
//       };
//     }
//   }
//
//   // You can add other order-related methods here
//   static Future<Map<String, dynamic>> getOrderHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('api_token');
//
//     if (token == null) {
//       return {
//         'status': false,
//         'message': 'Please login to continue',
//         'goHome': true,
//       };
//     }
//
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiService.baseUrl}/orders'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//       );
//
//       return jsonDecode(response.body);
//     } catch (e) {
//       debugPrint('Order history error: $e');
//       return {
//         'status': false,
//         'message': 'Network error occurred',
//       };
//     }
//   }
//
//   static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('api_token');
//
//     if (token == null) {
//       return {
//         'status': false,
//         'message': 'Please login to continue',
//         'goHome': true,
//       };
//     }
//
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiService.baseUrl}/order/$orderId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//       );
//
//       return jsonDecode(response.body);
//     } catch (e) {
//       debugPrint('Order details error: $e');
//       return {
//         'status': false,
//         'message': 'Network error occurred',
//       };
//     }
//   }
// }