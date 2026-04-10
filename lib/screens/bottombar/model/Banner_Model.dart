import '../../../services/api_service.dart';

class BannerModel {
  final int id;
  final String image;
  final String? title;
  final String? type; // "store", "product", or null
  final List<String>? linkedData; // List of IDs as strings
  final List<String>? cities; // Cities where this banner should appear

  BannerModel({
    required this.id,
    required this.image,
    this.title,
    this.type,
    this.linkedData,
    this.cities,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json["id"],
      image: "${ApiService.ImagebaseUrl}${ApiService.banner_images_URL}${json["image"]}",
      title: json["title"],
      type: json["type"],
      linkedData: json["linked_data"] != null
          ? List<String>.from(json["linked_data"])
          : null,
      cities: json["cities"] != null
          ? List<String>.from(json["cities"])
          : null,
    );
  }
}