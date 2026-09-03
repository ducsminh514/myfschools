import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../services/api_client.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxMap<String, dynamic> profileData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('/profile');
      if (response.statusCode == 200) {
        profileData.value = response.data;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải thông tin cá nhân');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    try {
      final response = await ApiClient().dio.post('/profile/change-password', data: {
        'oldPassword': oldPass,
        'newPassword': newPass,
      });
      if (response.statusCode == 200) {
        Get.snackbar('Thành công', 'Đổi mật khẩu thành công!');
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Đổi mật khẩu thất bại');
      return false;
    }
  }

  /// Upload ảnh đại diện mới
  Future<void> uploadAvatar(XFile file) async {
    isUploadingAvatar.value = true;
    try {
      final fileName = p.basename(file.path);
      final mimeType = fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await ApiClient().dio.patch('/profile/avatar', data: formData);
      if (response.statusCode == 200) {
        // Cập nhật URL avatar trong state để UI tự reload ảnh
        profileData['avatarUrl'] = response.data['avatarUrl'];
        profileData.refresh();
        Get.snackbar('Thành công', 'Đã cập nhật ảnh đại diện',
          backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể cập nhật ảnh');
    } finally {
      isUploadingAvatar.value = false;
    }
  }
}
