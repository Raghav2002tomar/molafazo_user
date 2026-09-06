import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_cache_service.dart';
import '../model/product_model.dart';

class ProductService {
  /// Build the same query key used for cache + API.
  static String _cacheKey({
    int? categoryId,
    int? subCategoryId,
    int? childCategoryId,
    String? city,
    String? country,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    return ProductCacheService.buildListCacheKey(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      childCategoryId: childCategoryId,
      city: city,
      country: country,
      deliveryCity: deliveryCity,
      deliveryType: deliveryType,
      deliveryTimeValue: deliveryTimeValue,
      deliveryTimeUnit: deliveryTimeUnit,
    );
  }

  /// Read cached product list (instant, no network).
  static Future<List<ProductModel>?> getCachedProducts({
    int? categoryId,
    int? subCategoryId,
    int? childCategoryId,
    String? city,
    String? country,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    return ProductCacheService.getProductList(
      _cacheKey(
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        childCategoryId: childCategoryId,
        city: city,
        country: country,
        deliveryCity: deliveryCity,
        deliveryType: deliveryType,
        deliveryTimeValue: deliveryTimeValue,
        deliveryTimeUnit: deliveryTimeUnit,
      ),
    );
  }

  /// Network fetch + write to local cache.
  static Future<List<ProductModel>> fetchProducts({
    int? categoryId,
    int? subCategoryId,
    int? childCategoryId,
    String? city,
    String? country,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) async {
    final Map<String, String> queryParams = {};

    if (categoryId != null) {
      queryParams["category_id"] = categoryId.toString();
    }

    if (subCategoryId != null) {
      queryParams["subcategory_id"] = subCategoryId.toString();
    }

    if (childCategoryId != null) {
      queryParams["child_category_id"] = childCategoryId.toString();
    }

    if (city != null && city.isNotEmpty && city != "null") {
      queryParams["city"] = city;
    }

    if (country != null && country.isNotEmpty) {
      queryParams["country"] = country;
    }
    if (deliveryCity != null && deliveryCity.isNotEmpty) {
      queryParams["delivery_city"] = deliveryCity;
    }
    if (deliveryType != null && deliveryType.isNotEmpty) {
      queryParams["delivery_type"] = deliveryType;
    }

    if (deliveryTimeValue != null) {
      queryParams["delivery_time_value"] = deliveryTimeValue.toString();
    }

    if (deliveryTimeUnit != null && deliveryTimeUnit.isNotEmpty) {
      queryParams["delivery_time_unit"] = deliveryTimeUnit;
    }

    final queryString = queryParams.entries
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
        .join("&");

    final endpoint = queryString.isEmpty
        ? "/customer/products"
        : "/customer/products?$queryString";

    final token = await AuthStorage.getToken();

    final res = await ApiService.get(
      endpoint: endpoint,
      token: token,
    );

    if (res["success"] == true) {
      final List rawList = res["data"] as List;
      final products =
          rawList.map((e) => ProductModel.fromJson(e)).toList();

      // Persist raw JSON for next cold start / revisit
      await ProductCacheService.saveProductList(
        _cacheKey(
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          childCategoryId: childCategoryId,
          city: city,
          country: country,
          deliveryCity: deliveryCity,
          deliveryType: deliveryType,
          deliveryTimeValue: deliveryTimeValue,
          deliveryTimeUnit: deliveryTimeUnit,
        ),
        rawList,
      );

      return products;
    } else {
      throw Exception(res["message"] ?? "Failed to fetch products");
    }
  }

  /// 🔹 Fetch all products
  static Future<List<ProductModel>> fetchAllProducts({
    String? cityId,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    return fetchProducts(
      city: cityId,
      deliveryCity: deliveryCity,
      deliveryType: deliveryType,
      deliveryTimeValue: deliveryTimeValue,
      deliveryTimeUnit: deliveryTimeUnit,
    );
  }

  /// 🔹 Cached all products (same filters as [fetchAllProducts])
  static Future<List<ProductModel>?> getCachedAllProducts({
    String? cityId,
    String? deliveryCity,
    String? deliveryType,
    int? deliveryTimeValue,
    String? deliveryTimeUnit,
  }) {
    return getCachedProducts(
      city: cityId,
      deliveryCity: deliveryCity,
      deliveryType: deliveryType,
      deliveryTimeValue: deliveryTimeValue,
      deliveryTimeUnit: deliveryTimeUnit,
    );
  }

  /// 🔹 Fetch by category only
  static Future<List<ProductModel>> fetchProductsByCategory(int categoryId) {
    return fetchProducts(categoryId: categoryId);
  }
}
