import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class AttendanceController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> myRecords = <Map<String, dynamic>>[].obs;

  // ── Teacher states ──
  final RxList<Map<String, dynamic>> classSheet = <Map<String, dynamic>>[].obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Không tự fetch trong onInit — từng màn hình tự gọi fetch khi cần
    // (tránh GV bị gọi endpoint /attendances/my dẫn đến 403 Forbidden)
  }

  /// Học sinh: lấy lịch sử điểm danh của mình
  Future<void> fetchMyAttendance() async {
    isLoading.value = true;
    try {
      final resp = await ApiClient().dio.get('/attendances/my');
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        // BE trả key hoa (Summary, Records) — đọc cả hoa lẫn thường để an toàn
        final rawSummary = (data['Summary'] ?? data['summary'] ?? {}) as Map;
        final rawRecords = (data['Records'] ?? data['records'] ?? []) as List;

        summary.value = <String, dynamic>{
          'present':       rawSummary['Present']       ?? rawSummary['present']       ?? 0,
          'absent':        rawSummary['Absent']        ?? rawSummary['absent']        ?? 0,
          'late':          rawSummary['Late']          ?? rawSummary['late']          ?? 0,
          'excused':       rawSummary['Excused']       ?? rawSummary['excused']       ?? 0,
          'attendancePct': rawSummary['AttendancePct'] ?? rawSummary['attendancePct'] ?? 0,
        };
        myRecords.value = rawRecords
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              // Normalize keys về lowercase
              return <String, dynamic>{
                'id':        m['Id']        ?? m['id'],
                'date':      m['Date']      ?? m['date'],
                'subject':   m['Subject']   ?? m['subject'],
                'period':    m['Period']    ?? m['period'],
                'startTime': m['StartTime'] ?? m['startTime'],
                'status':    m['Status']    ?? m['status'] ?? 'absent',
                'note':      m['Note']      ?? m['note'],
              };
            })
            .toList();
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải dữ liệu điểm danh');
    } finally {
      isLoading.value = false;
    }
  }

  /// Giáo viên: lấy danh sách HS cần điểm danh
  Future<void> fetchClassSheet(int scheduleId, String date) async {
    isLoading.value = true;
    try {
      final resp = await ApiClient().dio.get(
        '/attendances/class',
        queryParameters: {'scheduleId': scheduleId, 'date': date},
      );
      if (resp.statusCode == 200) {
        classSheet.value = List<Map<String, dynamic>>.from(
          (resp.data['students'] as List).map((e) => Map<String, dynamic>.from(e))
        );
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải danh sách lớp');
    } finally {
      isLoading.value = false;
    }
  }

  /// Giáo viên: cập nhật status của 1 học sinh trong sheet tạm
  void updateStudentStatus(int studentId, String status) {
    final idx = classSheet.indexWhere((s) => s['studentId'] == studentId);
    if (idx >= 0) {
      classSheet[idx] = {...classSheet[idx], 'status': status};
      classSheet.refresh();
    }
  }

  /// Giáo viên: gửi bảng điểm danh lên server
  Future<bool> submitAttendance(int scheduleId, String date) async {
    isSubmitting.value = true;
    try {
      final records = classSheet.map((s) => <String, dynamic>{
        'studentId': s['studentId'],
        'status': s['status'],
        'note': s['note'],
      }).toList();

      final resp = await ApiClient().dio.post('/attendances/submit', data: {
        'scheduleId': scheduleId,
        'date': date,
        'records': records,
      });
      if (resp.statusCode == 200) {
        Get.snackbar('Thành công', resp.data['message'] ?? 'Đã lưu điểm danh',
          backgroundColor: Colors.green.shade50, colorText: Colors.green.shade800);
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể lưu điểm danh');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
