import 'dart:convert';

import 'package:ecom/screens/bottombar/model/store_model.dart';

import '../../../services/api_service.dart';
import 'store_model.dart';
import 'category_model.dart';

class ProductModel {
  final int id;
  final int storeId;
  final int categoryId;
  final int subCategoryId;
  final int? childCategoryId;

  final String name;
  final String description;

  final String price;
  final String? discountPrice;

  final int availableQuantity;
  final bool deliveryAvailable;
  final String deliveryPrice;
  final String deliveryTime;

  final Map<String, dynamic>? attributes;
  final List<String> tags;
  bool? isFavorite;   // ⭐ ADD THIS

  final String image;
  final double? reviewsAvgRating;
  final int reviewsCount;

  final StoreModel store;
  final CategoryMiniModel category;
  final CategoryMiniModel subCategory;
  final List<ProductCombination>? combinations; // Add this
  final PrimaryImage? primaryImage;


  ProductModel({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.subCategoryId,
    this.childCategoryId,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    this.isFavorite,
    required this.availableQuantity,
    required this.deliveryAvailable,
    required this.deliveryPrice,
    required this.deliveryTime,
    this.attributes,
    required this.tags,
    required this.image,
    this.reviewsAvgRating,
    required this.reviewsCount,
    required this.store,
    required this.category,
    required this.subCategory,
    this.combinations,
    this.primaryImage

  });


  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<ProductCombination>? combinations;
    if (json['combinations'] != null && json['combinations'] is List) {
      combinations = (json['combinations'] as List)
          .map((e) => ProductCombination.fromJson(e))
          .toList();
    }

    return ProductModel(
      id: BaseModel.parseInt(json['id']),
      storeId: BaseModel.parseInt(json['store_id']),
      categoryId: BaseModel.parseInt(json['category_id']),
      subCategoryId: BaseModel.parseInt(json['sub_category_id']),
      childCategoryId: json['child_category_id'] != null
          ? BaseModel.parseInt(json['child_category_id'])
          : null,

      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isFavorite: json["is_favorite"] ?? false,   // ✅ FIX
      price: json['price']?.toString() ?? '0',
      discountPrice: json['discount_price']?.toString(),

      availableQuantity: BaseModel.parseInt(json['available_quantity']),
      deliveryAvailable: BaseModel.parseBool(json['delivery_available']),
      deliveryPrice: json['delivery_price']?.toString() ?? '0',
      deliveryTime: json['delivery_time']?.toString() ?? '',

      attributes: json['attributes_json'],
      tags: _parseTags(json['tags']),

      image: json['primaryimage']?.toString() ?? '',

      reviewsAvgRating: BaseModel.parseDouble(json['reviews_avg_rating']),
      reviewsCount: BaseModel.parseInt(json['reviews_count']),

      store: StoreModel.fromJson(json['store'] ?? {}),
      category: CategoryMiniModel.fromJson(json['category'] ?? {}),
      subCategory: CategoryMiniModel.fromJson(json['sub_category'] ?? {}),
      combinations: combinations,
      primaryImage: json['primary_image'] != null
          ? PrimaryImage.fromJson(json['primary_image'])
          : null,

    );

  }
  // Helper method to get first combination ID
  int? get firstCombinationId {
    if (combinations != null && combinations!.isNotEmpty) {
      return combinations!.first.id;
    }
    return null;
  }

  // Helper method to get default combination
  ProductCombination? get defaultCombination {
    if (combinations != null && combinations!.isNotEmpty) {
      return combinations!.first;
    }
    return null;
  }

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return List<String>.from(tags.map((e) => e.toString()));
    }
    if (tags is String) {
      try {
        if (tags.startsWith('[') && tags.endsWith(']')) {
          final parsed = jsonDecode(tags);
          if (parsed is List) {
            return List<String>.from(parsed.map((e) => e.toString()));
          }
        }
      } catch (e) {
        // If parsing fails, return empty list
      }
    }
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // static List<String> _parseTags(dynamic tags) {
  //   if (tags == null) return [];
  //   if (tags is List) {
  //     return List<String>.from(tags.map((e) => e.toString()));
  //   }
  //   if (tags is String) {
  //     try {
  //       // Try to parse if it's a JSON string array
  //       if (tags.startsWith('[') && tags.endsWith(']')) {
  //         final parsed = jsonDecode(tags);
  //         if (parsed is List) {
  //           return List<String>.from(parsed.map((e) => e.toString()));
  //         }
  //       }
  //     } catch (e) {
  //       // If parsing fails, return empty list
  //     }
  //   }
  //   return [];
  // }

  /// Helper
  bool get hasDiscount =>
      discountPrice != null && discountPrice != price;
}


class PrimaryImage {
  final int id;
  final int productId;
  final String image;
  final String? color;
  final int isPrimary;

  PrimaryImage({
    required this.id,
    required this.productId,
    required this.image,
    this.color,
    required this.isPrimary,
  });

  factory PrimaryImage.fromJson(Map<String, dynamic> json) {
    return PrimaryImage(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      image: json['image']?.toString() ?? '',
      color: json['color']?.toString(),
      isPrimary: json['is_primary'] ?? 0,
    );
  }
}

class ProductCombination {
  final int id;
  final int productId;
  final Map<String, dynamic> combination;
  final String? description;
  final String price;
  final String? priceBeforeDiscount;
  final String? costPrice;
  final int stock;
  final List<String> images;

  ProductCombination({
    required this.id,
    required this.productId,
    required this.combination,
    this.description,
    required this.price,
    this.priceBeforeDiscount,
    this.costPrice,
    required this.stock,
    required this.images,
  });

  factory ProductCombination.fromJson(Map<String, dynamic> json) {
    // Parse combination
    Map<String, dynamic> combination;
    if (json['combination'] is String) {
      combination = jsonDecode(json['combination']);
    } else {
      combination = json['combination'] ?? {};
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
      combination: combination,
      description: json['description'],
      price: json['price']?.toString() ?? '0',
      priceBeforeDiscount: json['price_before_discount']?.toString(),
      costPrice: json['cost_price']?.toString(),
      stock: json['stock'] ?? 0,
      images: images,
    );
  }
}


class CategoryMiniModel {
  final int id;
  final String name;
  final String image;

  CategoryMiniModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory CategoryMiniModel.fromJson(Map<String, dynamic> json) {
    return CategoryMiniModel(
      id: BaseModel.parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}
class BaseModel {
  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return defaultValue;
  }
}