import '../../../services/api_service.dart';
import '../model/category_model.dart';

class CategoryService {
  static Future<List<CategoryModel>> fetchCategories() async {
    final response = await ApiService.get(
      endpoint: '/customer/categories',
    );

    if (response['success'] == true) {
      final List list = response['data'] ?? [];
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to load categories');
    }
  }
}
