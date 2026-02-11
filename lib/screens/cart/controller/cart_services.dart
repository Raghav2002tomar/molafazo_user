import 'dart:convert';
import 'package:ecom/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';

class CartService {
  static const String baseURL = "${ApiService.baseUrl}"; // Replace with your actual base URL

  // Add product to cart
  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login to add items to cart',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse('$baseURL/customer/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await AuthStorage.logout();
        return {
          'status': false,
          'message': 'Session expired. Please login again',
          'requiresLogin': true,
        };
      } else {
        return {
          'status': false,
          'message': 'Failed to add product to cart',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Get cart list
  static Future<Map<String, dynamic>> getCartList() async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login to view cart',
          'requiresLogin': true,
        };
      }

      final response = await http.get(
        Uri.parse('$baseURL/customer/cart/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        return {
          'status': false,
          'message': 'Failed to fetch cart',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Update cart item quantity
  static Future<Map<String, dynamic>> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse('$baseURL/customer/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "cart_id": cartItemId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': false,
          'message': 'Failed to update cart',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Remove item from cart
  static Future<Map<String, dynamic>> removeFromCart(int cartItemId) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        return {
          'status': false,
          'message': 'Please login',
          'requiresLogin': true,
        };
      }

      final response = await http.delete(
        Uri.parse('$baseURL/customer/cart/remove/$cartItemId'),
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
          'message': 'Failed to remove item',
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