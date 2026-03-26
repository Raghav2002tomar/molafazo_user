import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../bottombar/model/product_model.dart';

class FavoriteService {

  static Future<List<ProductModel>> fetchFavorites() async {

    final token = await AuthStorage.getToken();

    if (token == null) {
      throw Exception("User not logged in");
    }

    final res = await ApiService.get(
      endpoint: "/customer/product/favorite/list",
      token: token,
    );

    /// ✅ FIX HERE
    if (res["success"] == true) {

      final List data = res["data"] ?? [];

      return data.map((e) => ProductModel.fromJson(e)).toList();

    } else {

      throw Exception(res["message"] ?? "Failed to load favorites");
    }
  }
}