import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../model/address_model.dart';

class AddressService {
  /// 🔹 Fetch address list
  static Future<List<AddressModel>> fetchAddresses() async {
    final token = await AuthStorage.getToken();

    final res = await ApiService.get(
      endpoint: '/customer/address/list',
      token: token,
    );

    if (res["success"] == true) {
      return (res['data'] as List)
          .map((e) => AddressModel.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  /// 🔹 Save new address
  static Future<void> saveAddress({
    required Map<String, dynamic> data,
  }) async {
    final token = await AuthStorage.getToken();

    final res = await ApiService.post(
      endpoint: '/customer/address/save',
      body: data,
      token: token,
    );

    if (res['success'] != true) {
      throw res['message'] ?? 'Failed to save address';
    }
  }
}
