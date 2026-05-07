// import 'package:ecom/services/api_service.dart';
// import '../model/store_model.dart';
//
// class StoreService {
//   /// 🔹 Fetch stores with optional filters
//   static Future<List<StoreModel>> fetchStores({
//     String? city,
//     String? country,
//   }) async {
//
//     final Map<String, String> queryParams = {};
//
//     /// CITY FILTER
//     if (city != null && city.isNotEmpty && city != "All Cities") {
//       queryParams["city"] = city;
//     }
//
//     /// COUNTRY FILTER
//     if (country != null && country.isNotEmpty) {
//       queryParams["country"] = country;
//     }
//
//     /// BUILD QUERY STRING
//     final queryString = queryParams.entries
//         .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
//         .join("&");
//
//     final endpoint = queryString.isEmpty
//         ? "/customer/stores"
//         : "/customer/stores?$queryString";
//
//     final response = await ApiService.get(endpoint: endpoint);
//
//     if (response["success"] == true) {
//       final List list = response['data'];
//       return list.map((e) => StoreModel.fromJson(e)).toList();
//     } else {
//       return [];
//     }
//   }
//
//   /// 🔹 Fetch all stores (no filters)
//   static Future<List<StoreModel>> fetchAllStores() {
//     return fetchStores();
//   }
//
//   /// 🔹 Fetch stores by city only
//   static Future<List<StoreModel>> fetchStoresByCity(String city) {
//     return fetchStores(city: city);
//   }
//
//   /// 🔹 Fetch stores by country only
//   static Future<List<StoreModel>> fetchStoresByCountry(String country) {
//     return fetchStores(country: country);
//   }
//
//   /// 🔹 Fetch stores by city and country
//   static Future<List<StoreModel>> fetchStoresByLocation({
//     required String city,
//     required String country,
//   }) {
//     return fetchStores(city: city, country: country);
//   }
// }

import 'package:ecom/services/api_service.dart';
import '../model/store_model.dart';

class StoreService {
  /// 🔹 Fetch stores with optional filters
  static Future<List<StoreModel>> fetchStores({
    String? city,
    String? country,

    // ✅ Delivery filters
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) async {
    final Map<String, String> queryParams = {};

    /// OLD CITY FILTER
    /// Use only if you still need normal city filter.
    /// If using delivery_city filter, don't send city.
    if (deliveryCity == null || deliveryCity.isEmpty) {
      if (city != null && city.isNotEmpty && city != "All Cities") {
        queryParams["city"] = city;
      }
    }

    /// COUNTRY FILTER
    if (country != null && country.isNotEmpty) {
      queryParams["country"] = country;
    }

    /// DELIVERY FILTERS
    if (deliveryCity != null && deliveryCity.isNotEmpty) {
      queryParams["delivery_city"] = deliveryCity;
    }

    if (deliveryType != null && deliveryType.isNotEmpty) {
      queryParams["delivery_type"] = deliveryType;
    }

    if (deliveryTimeValue != null) {
      queryParams["delivery_time_value"] = deliveryTimeValue.toString();
    }

    if (deliveryTimeUnit != null && deliveryTimeUnit.isNotEmpty) {
      queryParams["delivery_time_unit"] = deliveryTimeUnit;
    }

    final queryString = queryParams.entries
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
        .join("&");

    final endpoint = queryString.isEmpty
        ? "/customer/stores"
        : "/customer/stores?$queryString";

    final response = await ApiService.get(endpoint: endpoint);

    if (response["success"] == true) {
      final List list = response['data'];
      return list.map((e) => StoreModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  /// 🔹 Fetch all stores
  static Future<List<StoreModel>> fetchAllStores({
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    return fetchStores(
      deliveryCity: deliveryCity,
      deliveryType: deliveryType,
      deliveryTimeValue: deliveryTimeValue,
      deliveryTimeUnit: deliveryTimeUnit,
    );
  }

  /// 🔹 Fetch stores by delivery filter
  static Future<List<StoreModel>> fetchStoresByDeliveryFilter({
    required String deliveryCity,
    required String deliveryType,
    required int deliveryTimeValue,
    required String deliveryTimeUnit,
  }) {
    return fetchStores(
      deliveryCity: deliveryCity,
      deliveryType: deliveryType,
      deliveryTimeValue: deliveryTimeValue,
      deliveryTimeUnit: deliveryTimeUnit,
    );
  }

  /// 🔹 Old methods
  static Future<List<StoreModel>> fetchStoresByCity(String city) {
    return fetchStores(city: city);
  }

  static Future<List<StoreModel>> fetchStoresByCountry(String country) {
    return fetchStores(country: country);
  }

  static Future<List<StoreModel>> fetchStoresByLocation({
    required String city,
    required String country,
  }) {
    return fetchStores(city: city, country: country);
  }
}