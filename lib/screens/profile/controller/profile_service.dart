import 'dart:io';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../model/user_model.dart';
import 'user_storage.dart';

class ProfileService {
  /// 🔹 Fetch profile
  static Future<UserModel> fetchProfile() async {
    final token = await AuthStorage.getToken();

    final res = await ApiService.get(
      endpoint: '/get-profile',
      token: token,
    );

    if (res['success'] == true) {
      final user = UserModel.fromJson(res['data']);
      await UserStorage.saveUser(user);
      return user;
    } else {
      throw res['message'] ?? 'Failed to load profile';
    }
  }

  /// 🔹 Update profile (with optional image)
  static Future<void> updateProfile({
    required String name,
    required String email,
    File? image,
  }) async {
    final token = await AuthStorage.getToken();

    final res = await ApiService.multipart(
      endpoint: '/customer/update-profile',
      token: token,
      fields: {
        'name': name,
        'email': email,
      },
      files: image != null
          ? {'profile_photo': image}
          : {},
    );

    if (res['success'] == true) {
      await UserStorage.saveUser(
        UserModel.fromJson(res['data']),
      );
    } else {
      throw res['message'] ?? 'Profile update failed';
    }
  }
}
