import '../../../services/api_service.dart';

class BannerModel {
  final int id;
  final String image;

  BannerModel({
    required this.id,
    required this.image,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json["id"],
      image:
      "${ApiService.ImagebaseUrl}${ApiService.banner_images_URL}${json["image"]}",
    );
  }
}