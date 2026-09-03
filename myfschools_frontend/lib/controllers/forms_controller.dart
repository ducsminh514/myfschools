import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData; // Xung đột MultipartFile/FormData với Dio
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';
import '../models/form_model.dart';
import '../services/api_client.dart';

class FormsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<FormModel> myForms = <FormModel>[].obs;
  final RxList<FormModel> teacherForms = <FormModel>[].obs; // Danh sách cho GV

  @override
  void onInit() {
    super.onInit();
    fetchMyForms();
  }

  Future<void> fetchMyForms() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('forms/my-forms');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        myForms.value = data.map((e) => FormModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi mạng', 'Không thể tải danh sách đơn từ');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createForm({
    required String formType,
    required String title,
    required String content,
    String? absentDate,
    XFile? attachment,
    int? assignedTo, // null = gửi GVCN mặc định, có giá trị = gửi cho GVBM cụ thể
  }) async {
    isSubmitting.value = true;
    try {
      // Đóng gói dữ liệu văn bản vào Form Data
      final formData = FormData.fromMap({
        'FormType': formType,
        'Title': title,
        'Content': content,
        if (absentDate != null) 'AbsentDate': absentDate,
        if (assignedTo != null) 'AssignedTo': assignedTo,
      });

      // Nếu có ảnh minh chứng, đóng gói tệp tin vào Form Data
      if (attachment != null) {
        final fileName = p.basename(attachment.path);
        final mimeType = fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        
        formData.files.add(MapEntry(
          'Attachment', // Tên tham số phải trùng khít với `IFormFile Attachment` ở C#
          await MultipartFile.fromFile(
            attachment.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        ));
      }

      final response = await ApiClient().dio.post(
        'forms/create',
        data: formData,
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Thành công',
          'Đơn từ của bạn đã được gửi thành công!',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
        await fetchMyForms(); // await để list được reload TRƯỚC khi navigate back
        return true;
      }
      return false;
    } on DioException catch (e) {
      String msg = 'Lỗi mạng hoặc Server lỗi (500)';
      if (e.response != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? 'Lỗi không xác định khi nộp đơn';
      }
      Get.snackbar('Thất bại', msg, backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteForm(int formId) async {
    try {
      final response = await ApiClient().dio.delete('forms/$formId');
      if (response.statusCode == 200) {
        Get.snackbar('Thành công', 'Đã thu hồi đơn', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
        fetchMyForms(); // Tải lại danh sách
      }
    } on DioException catch (e) {
      String msg = 'Không thể thu hồi đơn';
      if (e.response != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? 'Không thể thu hồi đơn';
      }
      Get.snackbar('Lỗi', msg, backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
    }
  }

  Future<void> fetchTeacherForms() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('forms/teacher/all-forms');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        teacherForms.value = data.map((e) => FormModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách đơn cho giáo viên');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> reviewForm(int formId, String status, String? reason) async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.patch(
        'forms/teacher/review/$formId',
        data: {
          'status': status,
          'rejectReason': reason,
        },
      );
      if (response.statusCode == 200) {
        Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
        await fetchTeacherForms(); // await để list reload trước khi navigate back
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể duyệt đơn');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

