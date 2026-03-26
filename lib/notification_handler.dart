import 'dart:async';
import 'dart:convert';
import 'package:ecom/screens/cart/order_detail_screen.dart';
import 'package:ecom/screens/cart/order_list_screen.dart';
import 'package:ecom/screens/chat/ConversationScreen.dart';
import 'package:ecom/services/api_service.dart';
import 'package:ecom/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'main.dart'; // 👈 Import your AuthStorage


// // Background message handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("----------- 🌙 FULL FCM MESSAGE (BACKGROUND) ------------");
  print("ID: ${message.messageId}");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
  print("---------------------------------------------------------");
}

class NotificationHandler {
  static final NotificationHandler _instance =
  NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _notificationHandled = false;

  Future<void> init(BuildContext context) async {
    await _firebaseMessaging.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();

    const initSettings =
    InitializationSettings(android: androidInit, iOS: iOSInit);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationClick(details.payload);
      },
    );



    // ✅ ADD THIS BLOCK
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'This channel is used for general notifications.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _fetchAndSaveFcmToken();

    FirebaseMessaging.onMessage.listen((message) {
      print("Foreground message received");

      print("FULL MESSAGE =====");
      print(message.toMap()); // ✅ ADD THIS
      print("DATA ===== ${message.data}");
      print("TITLE ===== ${message.notification?.title}");
      print("BODY ===== ${message.notification?.body}");

      _showLocalNotification(message);
    });


    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("Background message opened");
      _openInterestedPassenger(message.data);
    });

    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("App opened from terminated state");
      _openInterestedPassenger(initialMessage.data);
    }
  }

  // 🔀 ROUTING
  void _openInterestedPassenger(Map<String, dynamic> data) {

    final type = data['notification_type']?.toString() ?? "";

    print("🔔 TYPE: $type");
    print("📦 DATA: $data");

    if (type == "2") {

      final conversationId =
          int.tryParse(data['conversation_id'].toString()) ?? 0;

      final image = data['imageUrl'] ?? "";

      final productName = data['product_name'] ?? "";
      final productImage = data['product_image'] ?? "";

      final senderName = data['store_name'] ?? "Store";
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            name: senderName,
            productname: productName,
            image:
            "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${productImage}",
          ),
        ),
      );
    } else if (type == "3"){
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OrderListScreen(

          ),
        ),
      );
    }else if (type == "5"){
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OrderListScreen(

          ),
        ),
      );
      // navigatorKey.currentState?.push(
      //   MaterialPageRoute(
      //     builder: (_) => OrderDetailScreen(
      //         orderId: order.orderId
      //     ),
      //   ),
      // );
    }
  }

  // 🔔 SHOW LOCAL
  Future<void> _showLocalNotification(RemoteMessage message) async {

    /// Always use data payload (more reliable)
    final title =
        message.data['title'] ??
            message.notification?.title ??
            "New Message";

    final body =
        message.data['body'] ??
            message.notification?.body ??
            "";

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const details = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }



  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    final data = jsonDecode(payload);
    _openInterestedPassenger(data);
  }

  Future<void> _fetchAndSaveFcmToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("fcm token ===== ${token}");
      await AuthStorage.saveFcmToken(token);
    }
  }
}