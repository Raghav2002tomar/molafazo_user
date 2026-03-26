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