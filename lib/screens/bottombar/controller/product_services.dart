import '../../../services/api_service.dart';
import '../model/product_model.dart';

class ProductService {
  /// 🔹 Fetch products with optional filters
  /// Supports:
  /// - category
  /// - category + sub category
  /// - category + sub + child category
  static Future<List<ProductModel>> fetchProducts({
    int? categoryId,
    int? subCategoryId,
    int? childCategoryId,
  }) async {
    /// 🟡 Build query params
    final Map<String, String> queryParams = {};

    if (categoryId != null) {
      queryParams["category_id"] = categoryId.toString();
    }

    if (subCategoryId != null) {
      queryParams["sub_category"] = subCategoryId.toString();
    }

    if (childCategoryId != null) {
      queryParams["child_category_id"] = childCategoryId.toString();
    }

    /// 🔵 Convert params → query string
    final queryString = queryParams.entries
        .map((e) => "${e.key}=${e.value}")
        .join("&");

    final endpoint = queryString.isEmpty
        ? "/customer/products"           // default API call when no filters
        : "/customer/products?$queryString";

    final res = await ApiService.get(endpoint: endpoint);

    if (res["success"] == true) {
      return (res["data"] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } else {
      throw Exception(res["message"] ?? "Failed to fetch products");
    }
  }

  /// 🔹 Fetch all products (no filters)
  static Future<List<ProductModel>> fetchAllProducts() {
    return fetchProducts();
  }

  /// 🔹 Fetch by category only
  static Future<List<ProductModel>> fetchProductsByCategory(int categoryId) {
    return fetchProducts(categoryId: categoryId);
  }
}
