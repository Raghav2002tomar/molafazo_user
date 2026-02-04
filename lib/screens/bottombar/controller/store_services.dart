import 'package:ecom/services/api_service.dart';
import '../model/store_model.dart';

class StoreService {
  static Future<List<StoreModel>> fetchStores() async {
    final response = await ApiService.get(
        endpoint: '/customer/stores');

    if (response["success"] == true) {
      final List list = response['data'];
      return list.map((e) => StoreModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }
}
