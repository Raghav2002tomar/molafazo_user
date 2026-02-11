import 'package:ecom/screens/bottombar/model/store_model.dart';

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

  final String image;

  final StoreModel store;
  final CategoryMiniModel category;
  final CategoryMiniModel subCategory;

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
    required this.availableQuantity,
    required this.deliveryAvailable,
    required this.deliveryPrice,
    required this.deliveryTime,
    this.attributes,
    required this.tags,
    required this.image,
    required this.store,
    required this.category,
    required this.subCategory,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      storeId: json['store_id'],
      categoryId: json['category_id'],
      subCategoryId: json['sub_category_id'],
      childCategoryId: json['child_category_id'],

      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',

      price: json['price']?.toString() ?? '0',
      discountPrice: json['discount_price']?.toString(),

      availableQuantity: json['available_quantity'] ?? 0,
      deliveryAvailable: json['delivery_available'] == 1,
      deliveryPrice: json['delivery_price']?.toString() ?? '0',
      deliveryTime: json['delivery_time']?.toString() ?? '',

      attributes: json['attributes_json'],
      tags: json['tags'] != null
          ? List<String>.from(
        (json['tags'] is String)
            ? []
            : json['tags'],
      )
          : [],

      image: json['primaryimage']?.toString() ?? '',

      store: StoreModel.fromJson(json['store']),
      category: CategoryMiniModel.fromJson(json['category']),
      subCategory: CategoryMiniModel.fromJson(json['sub_category']),
    );
  }

  /// Helper
  bool get hasDiscount =>
      discountPrice != null && discountPrice != price;
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
      id: json['id'],
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}
