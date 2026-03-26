import '../../../services/api_service.dart';
import '../model/Banner_Model.dart';

import '../../../services/api_service.dart';
import '../model/Banner_Model.dart';

class BannerService {

  static Future<List<BannerModel>> fetchBanners({String? city}) async {

    String endpoint = "/banners";

    /// SEND CITY ONLY IF IT IS A REAL CITY
    if (city != null && city.isNotEmpty && city != "All Cities") {
      endpoint = "/banners?city=${Uri.encodeComponent(city)}";
    }

    final res = await ApiService.get(endpoint: endpoint);

    if (res["success"] == true) {

      final List data = res["data"] ?? [];

      return data.map((e) => BannerModel.fromJson(e)).toList();

    } else {
      return [];
    }
  }
}