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
  final List<int> type;
  final int deliveryBySeller;
  final int selfPickup;
  final String logo;
  final String storeBackgroundImage;
  final String description;
  final String workingHours;
  final int statusId;
  final String? rejectReason;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final List<String> governmentId;
  final String? backgroundColor;
  final Map<String, dynamic>? returnPolicy;
  final Map<String, dynamic>? deliveryPolicy;
  final String? deliveryDays;
  final List<Map<String, dynamic>>? socialLinks;

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
    this.rejectReason,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.governmentId,
    this.backgroundColor,
    this.returnPolicy,
    this.deliveryPolicy,
    this.deliveryDays,
    this.socialLinks,
  });

  // Helper method to parse type field
  static List<int> _parseType(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    }

    if (value is String) {
      try {
        final cleaned = value.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
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
        return [value];
      }
    }

    return [];
  }

  // Helper method to parse JSON string to Map
  static Map<String, dynamic>? _parseJsonToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        return json.decode(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to parse JSON string to List
  static List<Map<String, dynamic>>? _parseJsonToList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<Map<String, dynamic>>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
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
      rejectReason: json['reject_reason']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      governmentId: _parseGovernmentId(json['government_id']),
      backgroundColor: json['background_color']?.toString(),
      returnPolicy: _parseJsonToMap(json['return_policy']),
      deliveryPolicy: _parseJsonToMap(json['delivery_policy']),
      deliveryDays: json['delivery_days']?.toString(),
      socialLinks: _parseJsonToList(json['social_links']),
    );
  }
}

class StoreProduct {
  final int id;
  final int? parentProductId;
  final int storeId;
  final int categoryId;
  final int? subCategoryId;
  final int? childCategoryId;
  final String name;
  final String? article;
  final String articleNumber;
  final String description;
  final String price;
  final String priceBeforeDiscount;
  final String? costPrice;
  final String? weight;
  final String? length;
  final String? width;
  final String? height;
  final String discountPrice;
  final int availableQuantity;
  final int deliveryAvailable;
  final String? deliveryPrice;
  final String? deliveryTime;
  final String? characteristics;
  final List<String> tags;
  final Map<String, dynamic>? attributesJson;
  final int statusId;
  final String approvalStatus;
  final String? rejectReason;
  final int isOriginal;
  final String createdAt;
  final String updatedAt;
  final String primaryImage;

  StoreProduct({
    required this.id,
    this.parentProductId,
    required this.storeId,
    required this.categoryId,
    this.subCategoryId,
    this.childCategoryId,
    required this.name,
    this.article,
    required this.articleNumber,
    required this.description,
    required this.price,
    required this.priceBeforeDiscount,
    this.costPrice,
    this.weight,
    this.length,
    this.width,
    this.height,
    required this.discountPrice,
    required this.availableQuantity,
    required this.deliveryAvailable,
    this.deliveryPrice,
    this.deliveryTime,
    this.characteristics,
    required this.tags,
    this.attributesJson,
    required this.statusId,
    required this.approvalStatus,
    this.rejectReason,
    required this.isOriginal,
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

  // Helper method to parse attributes JSON
  static Map<String, dynamic>? _parseAttributesJson(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        return json.decode(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] ?? 0,
      parentProductId: json['parent_product_id'],
      storeId: json['store_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      subCategoryId: json['sub_category_id'],
      childCategoryId: json['child_category_id'],
      name: json['name']?.toString() ?? '',
      article: json['article']?.toString(),
      articleNumber: json['article_number']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      priceBeforeDiscount: json['price_before_discount']?.toString() ?? '0.00',
      costPrice: json['cost_price']?.toString(),
      weight: json['weight']?.toString(),
      length: json['length']?.toString(),
      width: json['width']?.toString(),
      height: json['height']?.toString(),
      discountPrice: json['discount_price']?.toString() ?? '0.00',
      availableQuantity: json['available_quantity'] ?? 0,
      deliveryAvailable: json['delivery_available'] ?? 0,
      deliveryPrice: json['delivery_price']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      characteristics: json['characteristics']?.toString(),
      tags: _parseTags(json['tags']),
      attributesJson: _parseAttributesJson(json['attributes_json']),
      statusId: json['status_id'] ?? 0,
      approvalStatus: json['approval_status']?.toString() ?? '',
      rejectReason: json['reject_reason']?.toString(),
      isOriginal: json['is_original'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      primaryImage: json['primaryimage']?.toString() ?? '',
    );
  }
}