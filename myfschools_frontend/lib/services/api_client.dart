import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiEndpoint,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Bỏ qua lỗi 401 nếu đó là request Đăng nhập (Sai email/pass)
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('auth/login')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            
            // Xoá sạch mọi Route xếp chồng trong App và văng về Màn Đăng nhập
            Get.offAllNamed('/login');

            // Hiển thị thông báo (nếu app không bị kill hẳn)
            Get.snackbar(
              'Phiên đăng nhập hết hạn', 
              'Hệ thống đã tự động đăng xuất để bảo mật. Vui lòng đăng nhập lại.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              colorText: Colors.redAccent,
              margin: const EdgeInsets.all(16), 
            );
          }
          return handler.next(e);
        },
      ),
    );
  }
}

