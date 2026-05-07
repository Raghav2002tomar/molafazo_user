import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../model/user_model.dart';
import 'user_storage.dart';

class ProfileService {
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

  static Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
    File? image,
  }) async {
    final token = await AuthStorage.getToken();

    File? uploadImage = image;

    if (image != null) {
      final compressed = await _compressImage(image);
      if (compressed != null) {
        uploadImage = compressed;
      }
    }

    final res = await ApiService.multipart(
      endpoint: '/customer/update-profile',
      token: token,
      fields: {
        'name': name,
        'email': email,
      },
      files: uploadImage != null ? {'profile_photo': uploadImage} : {},
    );

    print("UPDATE PROFILE RESPONSE: $res");

    final bool isSuccess =
        res['success'] == true ||
            (res['message'] != null &&
                res['message'].toString().toLowerCase().contains('success'));

    if (isSuccess) {
      try {
        if (res['data'] != null && res['data'] is Map<String, dynamic>) {
          await UserStorage.saveUser(
            UserModel.fromJson(Map<String, dynamic>.from(res['data'])),
          );
        }
      } catch (e) {
        print("User save error: $e");
      }
      return;
    }

    if (res['errors'] != null && res['errors'] is Map) {
      final errors = res['errors'] as Map<String, dynamic>;
      final firstKey = errors.keys.first;
      final firstError = errors[firstKey][0];
      throw Exception(firstError);
    }

    throw Exception(res['message'] ?? 'Profile update failed');
  }
}