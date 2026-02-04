import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://grantoma.lt/api";
  static const String ImagebaseUrl = "https://grantoma.lt/";
  static const String gov_id_document_URL = "/assets/gov_id_document/";
  static const String profile_image_URL = "/assets/profile_image/";
  static const String store_logo_URL = "/assets/store_logo/";
  static const String product_images_URL = "/assets/product_images/";
  static const String store_documents_URL = "assets/store_documents/";
  static const String category_images_URL = "assets/category_images/";
  static const String banner_images_URL = "assets/banner_images/";

  /// 🔹 Common headers
  static Map<String, String> _headers({String? token}) {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// =========================
  /// 🔵 GET API
  /// =========================
  static Future<dynamic> get({
    required String endpoint,
    String? token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(baseUrl + endpoint),
        headers: _headers(token: token),
      )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// =========================
  /// 🟢 POST JSON API
  /// =========================
  static Future<dynamic> post({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(baseUrl + endpoint),
        headers: _headers(token: token),
        body: jsonEncode(body ?? {}),
      )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<dynamic> postFormData({
    required String endpoint,
    required Map<String, String> fields,
    String? token,
  }) async {
    try {
      final request =
      http.MultipartRequest("POST", Uri.parse(baseUrl + endpoint));

      request.headers.addAll({
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      });

      request.fields.addAll(fields);

      final streamed = await request.send()
          .timeout(const Duration(seconds: 15));

      final responseBody = await streamed.stream.bytesToString();

      return _handleResponse(
        http.Response(responseBody, streamed.statusCode),
      );
    } catch (e) {
      return _handleError(e);
    }
  }


  /// =========================
  /// 🟣 MULTIPART (IMAGE / FILE)
  /// =========================
  static Future<dynamic> multipart({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, File> files,
    String? token,
  }) async {
    try {
      final request =
      http.MultipartRequest("POST", Uri.parse(baseUrl + endpoint));

      request.headers.addAll({
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      });

      request.fields.addAll(fields);

      files.forEach((key, file) async {
        request.files.add(
          await http.MultipartFile.fromPath(key, file.path),
        );
      });

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      return _handleResponse(
        http.Response(resBody, response.statusCode),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  /// =========================
  /// 🔴 RESPONSE HANDLER
  /// =========================
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        "success": data["status"] == true,
        "data": data["data"],
        "message": data["message"],
      };
    } else {
      return {
        "success": false,
        "message": data["message"] ?? "Something went wrong",
        "status": response.statusCode,
      };
    }
  }


  /// =========================
  /// ❌ ERROR HANDLER
  /// =========================
  static dynamic _handleError(dynamic error) {
    return {
      "success": false,
      "message": error.toString().contains("Timeout")
          ? "Request timeout"
          : "No Internet / Server Error",
    };
  }
}