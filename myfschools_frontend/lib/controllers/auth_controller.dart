import 'dart:convert';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_models.dart';
import '../services/api_client.dart';
import 'home_controller.dart';
import 'notifications_controller.dart';
import 'profile_controller.dart';
import 'messages_controller.dart';
import 'schedule_controller.dart';
import 'attendance_controller.dart';
import 'forms_controller.dart';
import 'class_management_controller.dart';

class AuthController extends GetxController {
  // Biến phản ứng (Reactive state), khi .value đổi thì UI tự động Build lại
  final Rx<UserInfo?> currentUser = Rx<UserInfo?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  // Khôi phục phiên đăng nhập khi mở app — bao gồm cả roles
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      // Đọc roles đã lưu để không bị mất khi khởi động lại app
      final rolesJson = prefs.getString('user_roles') ?? '[]';
      final roles = List<String>.from(jsonDecode(rolesJson));
      final userName = prefs.getString('user_name') ?? 'Đang tải...';
      final studentCode = prefs.getString('user_student_code'); // null nếu là GV

      currentUser.value = UserInfo(
        name: userName,
        className: '---',
        id: studentCode ?? '---',
        gpa: 0.0,
        attendance: 0,
        pendingForms: 0,
        roles: roles,       // ← Khôi phục roles đúng
        studentCode: studentCode,
      );
    }
  }

  Future<bool> login(String phone, String password) async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.post('auth/login', data: {
        'phone': phone,
        'password': password,
      });
      print('Login Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userParams = data['user'];
        final roles = List<String>.from(userParams['roles'] ?? []);

        // Lưu Token JWT và thông tin user vào bộ nhớ điện thoại
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('user_name', userParams['fullName'] ?? '');
        await prefs.setString('user_roles', jsonEncode(roles)); //
        if (userParams['studentCode'] != null) {
          await prefs.setString('user_student_code', userParams['studentCode']);
        } else {
          await prefs.remove('user_student_code');
        }

        // Bơm tạm data vào Auth State để đổi trạng thái isLoggedIn = true.
        // Dữ liệu đầy đủ sẽ tải bằng API riêng của Dashboard.
        currentUser.value = UserInfo(
          name: userParams['fullName'] ?? 'Đang tải...',
          className: '---',
          id: (userParams['studentCode'] ?? userParams['id'] ?? '---').toString(),
          gpa: 0.0,
          attendance: 0,
          pendingForms: 0,
          roles: roles,
          studentCode: userParams['studentCode'],
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Không thể kết nối máy chủ!';
      Get.snackbar('Đăng nhập thất bại', msg, 
        snackPosition: SnackPosition.TOP, 
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red);
      return false;
    } catch (e) {
      Get.snackbar('Lỗi hệ thống', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_roles');
    await prefs.remove('user_name');
    await prefs.remove('user_student_code');
    currentUser.value = null;

    // Xóa TẤT CẢ controllers phụ thuộc session
    // để khi login lại, onInit() chạy lại và fetch data mới
    Get.delete<HomeController>(force: true);
    Get.delete<NotificationsController>(force: true);
    Get.delete<ProfileController>(force: true);
    Get.delete<MessagesController>(force: true);
    Get.delete<ScheduleController>(force: true);
    Get.delete<AttendanceController>(force: true);
    Get.delete<FormsController>(force: true);
    Get.delete<ClassManagementController>(force: true);

    Get.offAllNamed('/login');
  }
}
