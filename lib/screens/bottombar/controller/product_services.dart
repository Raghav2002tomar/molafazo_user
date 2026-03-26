import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../model/product_model.dart';

class ProductService {

  static Future<List<ProductModel>> fetchProducts({
  int? categoryId,
  int? subCategoryId,
  int? childCategoryId,
  String? city,
  String? country,
  }) async {

  final Map<String, String> queryParams = {};

  /// CATEGORY
  if (categoryId != null) {
  queryParams["category_id"] = categoryId.toString();
  }

  /// SUB CATEGORY
  if (subCategoryId != null) {
  queryParams["subcategory_id"] = subCategoryId.toString();
  }

  /// CHILD CATEGORY
  if (childCategoryId != null) {
  queryParams["child_category_id"] = childCategoryId.toString();
  }

  /// CITY FILTER
  if (city != null && city.isNotEmpty && city != "null") {
    queryParams["city"] = city;
  }

  /// COUNTRY FILTER
  if (country != null && country.isNotEmpty) {
  queryParams["country"] = country;
  }

  /// BUILD QUERY STRING
  final queryString = queryParams.entries
      .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
      .join("&");

  final endpoint = queryString.isEmpty
  ? "/customer/products"
      : "/customer/products?$queryString";

  final token = await AuthStorage.getToken();

  final res = await ApiService.get(endpoint: endpoint,
    token: token,   // if null → ApiService will not send Authorization header

  );

  if (res["success"] == true) {
  return (res["data"] as List)
      .map((e) => ProductModel.fromJson(e))
      .toList();
  } else {
  throw Exception(res["message"] ?? "Failed to fetch products");
  }
  }

  /// 🔹 Fetch all products
  static Future<List<ProductModel>> fetchAllProducts({
  String? cityId,
  }) {
  return fetchProducts(city: cityId, );
  }


  /// 🔹 Fetch by category only
  static Future<List<ProductModel>> fetchProductsByCategory(int categoryId) {
    return fetchProducts(categoryId: categoryId);
  }
}
