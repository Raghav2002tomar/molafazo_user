import 'dart:convert';

import '../../bottombar/model/product_model.dart';
import '../../bottombar/model/store_model.dart';
import '../../review/model/static_review_model.dart';

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
  final String articlenumber;
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
  bool? isFavorite;   // ⭐ ADD THIS

  // ADD THESE THREE FIELDS
  final double reviewsAvgRating;
  final int reviewsCount;
  final List<Review> reviews;

  final Store? store;
  final Category? category;
  final Category? subCategory;
  final Category? childCategory;
  final List<ProductImage> images;
  final List<OtherSeller> otherSellers;
  final List<ProductCombination> combinations; // Add this



  ProductDetail({
    required this.id,
    required this.storeId,
    required this.categoryId,
    this.subCategoryId,
    this.childCategoryId,
    required this.name,
    required this.articlenumber,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.availableQuantity,
    required this.deliveryAvailable,
    required this.deliveryPrice,
    required this.deliveryTime,
    this.characteristics,
    this.tags,
    this.isFavorite,
    this.attributesJson,
    required this.statusId,
    required this.createdAt,
    required this.updatedAt,
    required this.primaryImage,

    // ADD THESE THREE REQUIRED PARAMETERS
    required this.reviewsAvgRating,
    required this.reviewsCount,
    required this.reviews,

    this.store,
    this.category,
    this.subCategory,
    this.childCategory,
    required this.images,
    required this.otherSellers,
    required this.combinations, // Add this


  });


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

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    List<ProductCombination> combinations = [];
    if (json['combinations'] != null && json['combinations'] is List) {
      combinations = (json['combinations'] as List)
          .map((e) => ProductCombination.fromJson(e))
          .toList();
    }
    return ProductDetail(
      id: json['id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      subCategoryId: json['sub_category_id'],
      childCategoryId: json['child_category_id'],
      name: json['name'] ?? '',
      articlenumber: json['article_number'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0.00',
      discountPrice: json['discount_price'] ?? '0.00',
      availableQuantity: json['available_quantity'] ?? 0,
      deliveryAvailable: json['delivery_available'] ?? 0,
      deliveryPrice: json['delivery_price'] ?? '0.00',
      deliveryTime: json['delivery_time'] ?? '',
      characteristics: json['characteristics'],
      tags: json['tags'],
      isFavorite: json["is_favorite"] ?? false,   // ✅ FIX
      attributesJson: json['attributes_json'] != null
          ? AttributesJson.fromJson(json['attributes_json'])
          : null,
      statusId: json['status_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      primaryImage: json['primaryimage'] ?? '',

      // ADD THESE THREE MAPPINGS
      reviewsAvgRating: _parseDouble(json['reviews_avg_rating']),
      reviewsCount: json['reviews_count'] ?? 0,
      reviews: (json['reviews'] as List?)
          ?.map((e) => Review.fromJson(e))
          .toList() ?? [],

      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      subCategory: json['sub_category'] != null
          ? Category.fromJson(json['sub_category'])
          : null,
      childCategory: json['child_category'] != null
          ? Category.fromJson(json['child_category'])
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromJson(e))
          .toList() ?? [],
      otherSellers: (json['other_sellers'] as List<dynamic>?)
          ?.map((e) => OtherSeller.fromJson(e))
          .toList() ?? [],
      combinations: combinations, // Add this

    );
  }
}

// Add ProductCombination class if not already present
class ProductCombination {
  final int id;
  final int productId;
  final Map<String, dynamic> variant;
  final String? description;
  final String price;
  final String? priceBeforeDiscount;
  final String? costPrice;
  final int stock;
  final List<String> images;

  ProductCombination({
    required this.id,
    required this.productId,
    required this.variant,
    this.description,
    required this.price,
    this.priceBeforeDiscount,
    this.costPrice,
    required this.stock,
    required this.images,
  });

  factory ProductCombination.fromJson(Map<String, dynamic> json) {
    // Parse combination JSON string if needed
    Map<String, dynamic> variant;
    if (json['combination'] is String) {
      variant = jsonDecode(json['combination']);
    } else {
      variant = json['combination'] ?? {};
    }

    // Parse images
    List<String> images = [];
    if (json['images'] is String) {
      try {
        images = List<String>.from(jsonDecode(json['images']));
      } catch (e) {
        images = [json['images']];
      }
    } else if (json['images'] is List) {
      images = List<String>.from(json['images']);
    }

    return ProductCombination(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      variant: variant,
      description: json['description'],
      price: json['price']?.toString() ?? '0.00',
      priceBeforeDiscount: json['price_before_discount']?.toString(),
      costPrice: json['cost_price']?.toString(),
      stock: json['stock'] ?? 0,
      images: images,
    );
  }
}
class OtherSeller {
  final int productId;
  final int storeId;
  final String storeName;
  final String? storeLogo;
  final String price;
  final String discounted_price;
  final String primaryImage;
  final int availableQuantity;

  OtherSeller({
    required this.productId,
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    required this.price,
    required this.discounted_price,
    required this.primaryImage,
    required this.availableQuantity,
  });

  factory OtherSeller.fromJson(Map<String, dynamic> json) {
    return OtherSeller(
      productId: json['product_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      storeName: json['store_name'] ?? '',
      storeLogo: json['store_logo'],
      price: json['price'] ?? '0.00',
      discounted_price: json['discount_price'] ?? '0.00',
      primaryImage: json['primary_image'] ?? '',
      availableQuantity: json['available_quantity'] ?? 0,
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
  final List<int> type;  // Changed from int to List<int>
  final int deliveryBySeller;
  final int selfPickup;
  final String logo;
  final String description;
  final String workingHours;
  final int statusId;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final String? storeBackgroundImage;  // Added this field
  final List<String> governmentId;  // Added this field



  Store({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    required this.type,  // Now a List<int>
    required this.deliveryBySeller,
    required this.selfPickup,
    required this.logo,
    required this.description,
    required this.workingHours,
    required this.statusId,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.storeBackgroundImage,
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
        return [value];
      }
    }

    return [];
  }
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
      type: _parseType(json['type']),  // Use helper method
      deliveryBySeller: json['delivery_by_seller'] ?? 0,
      selfPickup: json['self_pickup'] ?? 0,
      logo: json['logo'] ?? '',
      description: json['description'] ?? '',
      workingHours: json['working_hours'] ?? '',
      statusId: json['status_id'] ?? 0,
      approvedAt: json['approved_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      governmentId: _parseGovernmentId(json['government_id']),
      storeBackgroundImage: json['store_background_image']?.toString(),


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

  /// 🔹 ADD THIS METHOD HERE
  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      storeId: storeId,
      categoryId: categoryId,
      subCategoryId: subCategoryId ?? 0,
      childCategoryId: childCategoryId,

      name: name,
      description: description,

      price: price,
      discountPrice: discountPrice,

      availableQuantity: availableQuantity,
      deliveryAvailable: deliveryAvailable == 1,
      deliveryPrice: deliveryPrice,
      deliveryTime: deliveryTime,

      attributes: null,
      tags: [],

      image: primaryImage,

      reviewsAvgRating: 0,
      reviewsCount: 0,

      store: StoreModel.fromJson({}), // SAFE EMPTY STORE

      category: CategoryMiniModel(
        id: categoryId,
        name: '',
        image: '',
      ),

      subCategory: CategoryMiniModel(
        id: subCategoryId ?? 0,
        name: '',
        image: '',
      ),
    );
  }
}
