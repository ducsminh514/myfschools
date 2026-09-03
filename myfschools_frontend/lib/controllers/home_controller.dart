import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import '../models/home_models.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';

class HomeController extends GetxController {
  final Rx<UserInfo?> userInfo = Rx<UserInfo?>(null);
  final RxList<ScheduleItem> todaySchedule = <ScheduleItem>[].obs;
  final RxList<NoticeItem> notices = <NoticeItem>[].obs;
  // Cờ Skeleton UI
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('home/dashboard');
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Cập nhật User Info
        final userParams = data['userInfo'];
        
        // Parse GVCN/GVBM data (chỉ có khi role = teacher)
        final isHomeroom = data['isHomeroom'] ?? false;
        final homeroomClassName = data['homeroomClassName'];
        final teachingSubjectsRaw = data['teachingSubjects'] as List<dynamic>? ?? [];
        final teachingSubjects = teachingSubjectsRaw
            .map((e) => TeachingSubject.fromJson(e as Map<String, dynamic>))
            .toList();

        userInfo.value = UserInfo(
          name: userParams['fullName'] ?? 'Chưa cập nhật',
          className: userParams['className'] ?? 'Khối 10',
          id: userParams['studentCode'] ?? '',
          gpa: (userParams['gpa'] ?? 0).toDouble(),
          attendance: (userParams['attendanceScore'] ?? 0).toDouble(),
          pendingForms: userParams['pendingForms'] ?? 0,
          roles: List<String>.from(userParams['roles'] ?? []),
          isHomeroom: isHomeroom,
          homeroomClassName: homeroomClassName,
          teachingSubjects: teachingSubjects,
        );

        // Cập nhật Danh sách TKB
        final scheduleParams = data['todaySchedule'] as List<dynamic>;
        todaySchedule.value = scheduleParams.map((item) {
          final periodNo = item['periodNo'] ?? 0;
          return ScheduleItem(
            period: 'Tiết $periodNo',
            time: '${item['startTime']} - ${item['endTime']}',
            subject: item['subjectName'] ?? 'N/A',
            room: item['room'] ?? 'N/A',
            teacher: item['teacherName'] ?? 'N/A',
            color: AppColors.orange,
          );
        }).toList();

        // Cập nhật Danh sách Thông báo
        if (data['notices'] != null) {
          final noticeParams = data['notices'] as List<dynamic>;
          notices.value = noticeParams.map((item) => NoticeItem.fromJson(item)).toList();
        }
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi kết nối', 'Không thể nạp dữ liệu từ hệ thống.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red);
    } catch (_) {
      // Get.snackbar('Lỗi', 'Không thể kết nối máy chủ!');
    } finally {
      // Fake delay ngắn xíu để phô diễn hiệu ứng Skeletonizer
      await Future.delayed(const Duration(milliseconds: 800));
      isLoading.value = false;
    }
  }

  /// Trả raw schedule data (gồm id) cho AttendanceSheetPage
  /// Tránh gọi API home/dashboard lần 2 — chỉ gọi endpoint schedule riêng
  Future<List<Map<String, dynamic>>?> fetchScheduleRaw() async {
    try {
      final response = await ApiClient().dio.get('home/dashboard');
      if (response.statusCode == 200) {
        final list = response.data['todaySchedule'] as List<dynamic>? ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return null;
  }
}
