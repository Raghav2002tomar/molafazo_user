import 'dart:convert';

class StoreDetailResponse {
  final bool status;
  final String message;
  final StoreDetailData data;

  StoreDetailResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StoreDetailResponse.fromJson(Map<String, dynamic> json) {
    return StoreDetailResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: StoreDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

class StoreDetailData {
  final StoreInfo store;
  final List<StoreProduct> products;

  StoreDetailData({
    required this.store,
    required this.products,
  });

  factory StoreDetailData.fromJson(Map<String, dynamic> json) {
    return StoreDetailData(
      store: StoreInfo.fromJson(json['store'] ?? {}),
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => StoreProduct.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class StoreInfo {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String mobile;
  final String country;
  final String city;
  final String address;
  final List<int> type;  // Changed from int to List<int>
  final int deliveryBySeller;
  final int selfPickup;
  final String logo;
  final String storeBackgroundImage;  // Renamed to camelCase
  final String description;
  final String workingHours;
  final int statusId;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final List<String> governmentId;  // Changed to List<String>

  StoreInfo({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    required this.type,
    required this.deliveryBySeller,
    required this.selfPickup,
    required this.logo,
    required this.storeBackgroundImage,
    required this.description,
    required this.workingHours,
    required this.statusId,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.governmentId,
  });

  // Helper method to parse type field
  static List<int> _parseType(dynamic value) {
    if (value == null) return [];

    // If it's already a List
    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    }

    // If it's a String like "[1]"
    if (value is String) {
      try {
        // Remove brackets and split
        final cleaned = value.replaceAll('[', '').replaceAll(']', '');
        if (cleaned.isEmpty) return [];

        final parts = cleaned.split(',');
        return parts.map((part) {
          final trimmed = part.trim();
          return int.tryParse(trimmed) ?? 0;
        }).toList();
      } catch (e) {
        print('Error parsing type: $e');
        return [];
      }
    }

    return [];
  }

  // Helper method to parse government_id
  static List<String> _parseGovernmentId(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If it's not JSON, treat as single string
        return [value];
      }
    }

    return [];
  }

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      type: _parseType(json['type']),
      deliveryBySeller: json['delivery_by_seller'] ?? 0,
      selfPickup: json['self_pickup'] ?? 0,
      logo: json['logo']?.toString() ?? '',
      storeBackgroundImage: json['store_background_image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      workingHours: json['working_hours']?.toString() ?? '',
      statusId: json['status_id'] ?? 0,
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      governmentId: _parseGovernmentId(json['government_id']),
    );
  }
}

class StoreProduct {
  final int id;
  final int storeId;
  final int categoryId;
  final int? subCategoryId;
  final int? childCategoryId;
  final String name;
  final String description;
  final String price;
  final String discountPrice;
  final int availableQuantity;
  final int deliveryAvailable;
  final String deliveryPrice;
  final String deliveryTime;
  final String? characteristics;
  final List<String> tags;  // Changed to List<String>
  final AttributesJson? attributesJson;
  final int statusId;
  final String paymentMode;  // Added this field
  final String createdAt;
  final String updatedAt;
  final String primaryImage;

  StoreProduct({
    required this.id,
    required this.storeId,
    required this.categoryId,
    this.subCategoryId,
    this.childCategoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.availableQuantity,
    required this.deliveryAvailable,
    required this.deliveryPrice,
    required this.deliveryTime,
    this.characteristics,
    required this.tags,
    this.attributesJson,
    required this.statusId,
    required this.paymentMode,
    required this.createdAt,
    required this.updatedAt,
    required this.primaryImage,
  });

  // Helper method to parse tags
  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is String) {
      try {
        final parsed = json.decode(tags);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {
        return [tags];
      }
    }
    if (tags is List) {
      return tags.map((e) => e.toString()).toList();
    }
    return [];
  }

  // Helper method to parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      subCategoryId: json['sub_category_id'],
      childCategoryId: json['child_category_id'],
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      discountPrice: json['discount_price']?.toString() ?? '0.00',
      availableQuantity: json['available_quantity'] ?? 0,
      deliveryAvailable: json['delivery_available'] ?? 0,
      deliveryPrice: json['delivery_price']?.toString() ?? '0.00',
      deliveryTime: json['delivery_time']?.toString() ?? '',
      characteristics: json['characteristics']?.toString(),
      tags: _parseTags(json['tags']),
      attributesJson: json['attributes_json'] != null
          ? AttributesJson.fromJson(json['attributes_json'])
          : null,
      statusId: json['status_id'] ?? 0,
      paymentMode: json['payment_mode']?.toString() ?? 'cod',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      primaryImage: json['primaryimage']?.toString() ?? '',
    );
  }
}

class AttributesJson {
  final List<String> type;
  final List<String> brand;
  final List<String> color;
  final List<String> material;
  final List<String> compatibility;
  final List<String>? ports;
  final List<String>? power;
  final List<String>? capacity;
  final List<String>? features;
  final List<String>? battery;
  final List<String>? storage;
  final List<String>? screenSize;

  AttributesJson({
    required this.type,
    required this.brand,
    required this.color,
    required this.material,
    required this.compatibility,
    this.ports,
    this.power,
    this.capacity,
    this.features,
    this.battery,
    this.storage,
    this.screenSize,
  });

  // Helper method to parse list
  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {
        return [value];
      }
    }
    return [value.toString()];
  }

  factory AttributesJson.fromJson(Map<String, dynamic> json) {
    return AttributesJson(
      type: _parseList(json['type']),
      brand: _parseList(json['brand']),
      color: _parseList(json['color']),
      material: _parseList(json['material']),
      compatibility: _parseList(json['compatibility']),
      ports: json['ports'] != null ? _parseList(json['ports']) : null,
      power: json['power'] != null ? _parseList(json['power']) : null,
      capacity: json['capacity'] != null ? _parseList(json['capacity']) : null,
      features: json['features'] != null ? _parseList(json['features']) : null,
      battery: json['battery'] != null ? _parseList(json['battery']) : null,
      storage: json['storage'] != null ? _parseList(json['storage']) : null,
      screenSize: json['screen_size'] != null ? _parseList(json['screen_size']) : null,
    );
  }
}