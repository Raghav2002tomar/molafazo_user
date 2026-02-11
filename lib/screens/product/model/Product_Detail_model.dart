class ProductDetailResponse {
  final bool status;
  final String message;
  final ProductDetail data;
  final List<RelatedProduct> relatedProducts;

  ProductDetailResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.relatedProducts,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: ProductDetail.fromJson(json['data'] ?? {}),
      relatedProducts: (json['related_products'] as List<dynamic>?)
          ?.map((e) => RelatedProduct.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class ProductDetail {
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
  final Store? store;
  final Category? category;
  final Category? subCategory;
  final Category? childCategory;
  final List<ProductImage> images;

  ProductDetail({
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
    this.store,
    this.category,
    this.subCategory,
    this.childCategory,
    required this.images,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
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
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      category:
      json['category'] != null ? Category.fromJson(json['category']) : null,
      subCategory: json['sub_category'] != null
          ? Category.fromJson(json['sub_category'])
          : null,
      childCategory: json['child_category'] != null
          ? Category.fromJson(json['child_category'])
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class AttributesJson {
  final Map<String, dynamic> data;

  AttributesJson({required this.data});

  factory AttributesJson.fromJson(Map<String, dynamic> json) {
    return AttributesJson(data: json);
  }
}

class Store {
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

  Store({
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
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
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
    );
  }
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final int statusId;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    required this.statusId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'],
      statusId: json['status_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ProductImage {
  final int id;
  final int productId;
  final String image;
  final String? color;
  final int isPrimary;
  final String createdAt;
  final String updatedAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.image,
    this.color,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      image: json['image'] ?? '',
      color: json['color'],
      isPrimary: json['is_primary'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class RelatedProduct {
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
  final String primaryImage;

  RelatedProduct({
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
    required this.primaryImage,
  });

  factory RelatedProduct.fromJson(Map<String, dynamic> json) {
    return RelatedProduct(
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
      primaryImage: json['primaryimage'] ?? '',
    );
  }
}

