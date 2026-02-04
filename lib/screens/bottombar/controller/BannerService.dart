

import '../../../services/api_service.dart';
import '../model/Banner_Model.dart';

class BannerService {
  /// GET /banners
  static Future<List<BannerModel>> fetchBanners({String? token}) async {
    final response = await ApiService.get(
      endpoint: '/banners',
    );

    // ApiService already normalizes response
    if (response["success"] == true) {
      final List list = response["data"] ?? [];
      return list.map((e) => BannerModel.fromJson(e)).toList();
    } else {
      throw Exception(response["message"] ?? "Failed to load banners");
    }
  }
}
