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
  final int type;
  final int deliveryBySeller;
  final int selfPickup;
  final String logo;
  final String description;
  final String workingHours;
  final int statusId;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final String? governmentId;

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
    required this.description,
    required this.workingHours,
    required this.statusId,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.governmentId,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      type: json['type'] ?? 0,
      deliveryBySeller: json['delivery_by_seller'] ?? 0,
      selfPickup: json['self_pickup'] ?? 0,
      logo: json['logo'] ?? '',
      description: json['description'] ?? '',
      workingHours: json['working_hours'] ?? '',
      statusId: json['status_id'] ?? 0,
      approvedAt: json['approved_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      governmentId: json['government_id'],
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
  final String? tags;
  final AttributesJson? attributesJson;
  final int statusId;
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
    this.tags,
    this.attributesJson,
    required this.statusId,
    required this.createdAt,
    required this.updatedAt,
    required this.primaryImage,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      subCategoryId: json['sub_category_id'],
      childCategoryId: json['child_category_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0.00',
      discountPrice: json['discount_price'] ?? '0.00',
      availableQuantity: json['available_quantity'] ?? 0,
      deliveryAvailable: json['delivery_available'] ?? 0,
      deliveryPrice: json['delivery_price'] ?? '0.00',
      deliveryTime: json['delivery_time'] ?? '',
      characteristics: json['characteristics'],
      tags: json['tags'],
      attributesJson: json['attributes_json'] != null
          ? AttributesJson.fromJson(json['attributes_json'])
          : null,
      statusId: json['status_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      primaryImage: json['primaryimage'] ?? '',
    );
  }
}

class AttributesJson {
  final List<String> size;
  final List<String> color;

  AttributesJson({
    required this.size,
    required this.color,
  });

  factory AttributesJson.fromJson(Map<String, dynamic> json) {
    return AttributesJson(
      size: (json['size'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      color: (json['color'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}