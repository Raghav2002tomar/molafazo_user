import 'dart:convert';

import 'package:ecom/screens/bottombar/model/product_model.dart';

class StoreModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String mobile;
  final String country;
  final String city;
  final String address;
  final List<String> types;
  final bool deliveryBySeller;
  final bool selfPickup;
  final String? logo;
  final String? storeBackgroundImage;
  final String? description;
  final String workingHours;
  final int statusId;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final List<String> governmentId;

  StoreModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    required this.types,
    required this.deliveryBySeller,
    required this.selfPickup,
    this.logo,
    this.storeBackgroundImage,
    this.description,
    required this.workingHours,
    required this.statusId,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.governmentId,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: BaseModel.parseInt(json['id']),
      userId: BaseModel.parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      types: _parseStoreTypes(json['type']),
      deliveryBySeller: BaseModel.parseBool(json['delivery_by_seller']),
      selfPickup: BaseModel.parseBool(json['self_pickup']),
      logo: json['logo']?.toString(),
      storeBackgroundImage: json['store_background_image']?.toString(),
      description: json['description']?.toString(),
      workingHours: json['working_hours']?.toString() ?? '',
      statusId: BaseModel.parseInt(json['status_id']),
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      governmentId: _parseGovernmentId(json['government_id']),
    );
  }
  static List<String> _parseStoreTypes(dynamic type) {
    if (type == null) return [];

    if (type is List) {
      return List<String>.from(type.map((e) => e.toString()));
    }

    if (type is String) {
      try {
        if (type.startsWith('[')) {
          final parsed = jsonDecode(type);
          return List<String>.from(parsed.map((e) => e.toString()));
        }
        return [type];
      } catch (e) {
        return [];
      }
    }

    return [];
  }
  static List<String> _parseGovernmentId(dynamic govId) {
    if (govId == null) return [];
    if (govId is List) {
      return List<String>.from(govId.map((e) => e.toString()));
    }
    if (govId is String) {
      try {
        if (govId.startsWith('[') && govId.endsWith(']')) {
          final parsed = jsonDecode(govId);
          if (parsed is List) {
            return List<String>.from(parsed.map((e) => e.toString()));
          }
        }
      } catch (e) {
        return [govId];
      }
    }
    return [];
  }
}