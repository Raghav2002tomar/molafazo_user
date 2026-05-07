import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class ChatService {
  static const String baseUrl =
      "${ApiService.baseUrl}/customer/chat";

  /// 🔐 Get Headers with Token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// ==============================
  /// ✅ Start Conversation
  /// ==============================
  static Future<int?> startConversation({
    required int otherUserId,
    required int productId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/start"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "other_user_id": otherUserId,
        "product_id": productId,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return data['conversation']['id'];
    }

    return null;
  }

  /// ==============================
  /// ✅ Get Conversations
  /// ==============================
  static Future<List<dynamic>> getConversations() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl/conversations"),
      headers: headers,
    );

    final data = jsonDecode(response.body);
    return data['conversations'];
  }

  /// ==============================
  /// ✅ Get Messages
  /// ==============================
  static Future<List<dynamic>> getMessages(
      int conversationId) async {

    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/messages"),
      headers: {
        ...headers,
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "conversation_id": conversationId
      }),
    );

    final data = jsonDecode(response.body);
    return data['messages'];
  }

  /// ==============================
  /// ✅ Send Message
  /// ==============================
  static Future<bool> sendMessage({
    required int conversationId,
    required String message,
  }) async {

    final headers = await _getHeaders();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/send"),
    );

    request.headers.addAll(headers);

    request.fields['conversation_id'] =
        conversationId.toString();
    request.fields['message'] = message;
    request.fields['type'] = "text";

    final response = await request.send();

    return response.statusCode == 200;
  }

  static Future<bool> sendImage({
    required int conversationId,
    required String imagePath,
  }) async {

    final headers = await _getHeaders();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/send"),
    );

    request.headers.addAll(headers);

    request.fields['conversation_id'] =
        conversationId.toString();

    request.fields['type'] = "image";

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imagePath,
      ),
    );

    final response = await request.send();

    return response.statusCode == 200;
  }

  /// ✅ Get Messages With Block Status
  static Future<Map<String, dynamic>> getMessagesWithStatus(
      int conversationId) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/messages"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "conversation_id": conversationId,
      }),
    );

    return jsonDecode(response.body);
  }

  /// ✅ Block / Unblock User
  static Future<Map<String, dynamic>> toggleBlockUser({
    required int blockedUserId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}/toggle-block-user"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "blocked_user_id": blockedUserId,
      }),
    );

    return jsonDecode(response.body);
  }

  /// ✅ Report User
  static Future<Map<String, dynamic>> reportUser({
    required int reportedUserId,
    required String description,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}/store-report"),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "reported_user_id": reportedUserId,
        "description": description,
      }),
    );

    return jsonDecode(response.body);
  }

}
