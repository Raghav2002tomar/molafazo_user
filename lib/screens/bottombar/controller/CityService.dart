import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';

import '../../../services/api_service.dart';

class CityService {

  Future<List<CityModel>> fetchCities() async {

    final res = await ApiService.get(
      endpoint: "/cities",
    );

    if (res["success"] == true) {

      final List data = res["data"] ?? [];

      return data.map((e) => CityModel.fromJson(e)).toList();

    } else {

      print("City API Error: ${res["message"]}");
      return [];

    }
  }
}

class CityStorage {

  static const cityIdKey = "selected_city_id";
  static const cityNameKey = "selected_city_name";
  static const deliveryCityKey = "delivery_city";
  static const deliveryTypeKey = "delivery_type";
  static const deliveryTimeValueKey = "delivery_time_value";
  static const deliveryTimeUnitKey = "delivery_time_unit";

  static Future<void> saveDeliveryFilter({
    required String city,
    required String deliveryType,
    required int deliveryTimeValue,
    required String deliveryTimeUnit,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(deliveryCityKey, city);
    await prefs.setString(deliveryTypeKey, deliveryType);
    await prefs.setInt(deliveryTimeValueKey, deliveryTimeValue);
    await prefs.setString(deliveryTimeUnitKey, deliveryTimeUnit);
  }

  static Future<Map<String, dynamic>> getDeliveryFilter() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "delivery_city": prefs.getString(deliveryCityKey),
      "delivery_type": prefs.getString(deliveryTypeKey),
      "delivery_time_value": prefs.getInt(deliveryTimeValueKey),
      "delivery_time_unit": prefs.getString(deliveryTimeUnitKey),
    };
  }

  static Future<void> clearDeliveryFilter() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(deliveryCityKey);
    await prefs.remove(deliveryTypeKey);
    await prefs.remove(deliveryTimeValueKey);
    await prefs.remove(deliveryTimeUnitKey);
  }

  /// Save city
  static Future<void> saveCity(int id, String name) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(cityIdKey, id);
    await prefs.setString(cityNameKey, name);
  }

  /// Get city
  static Future<Map<String, dynamic>> getCity() async {

    final prefs = await SharedPreferences.getInstance();

    return {
      "id": prefs.getInt(cityIdKey),
      "name": prefs.getString(cityNameKey),
    };
  }

  /// Remove city
  static Future<void> removeCity() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(cityIdKey);
    await prefs.remove(cityNameKey);
  }
}class CityModel {
  final int id;
  final String name;

  CityModel({
    required this.id,
    required this.name,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json["id"],
      name: json["name"],
    );
  }
}