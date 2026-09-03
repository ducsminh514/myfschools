import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class ClassManagementController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isLoadingStudents = false.obs;
  final RxBool isLoadingDetail = false.obs;
  final Rx<Map<String, dynamic>> dashboard = Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> studentDetail = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
    fetchStudents();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    try {
      final resp = await ApiClient().dio.get('/class/my-class');
      if (resp.statusCode == 200) {
        dashboard.value = Map<String, dynamic>.from(resp.data);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải thông tin lớp');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStudents() async {
    isLoadingStudents.value = true;
    try {
      final resp = await ApiClient().dio.get('/class/students');
      if (resp.statusCode == 200) {
        students.value = List<Map<String, dynamic>>.from(
          (resp.data as List).map((e) => Map<String, dynamic>.from(e))
        );
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải DS học sinh');
    } finally {
      isLoadingStudents.value = false;
    }
  }

  Future<void> fetchStudentDetail(int studentId) async {
    studentDetail.value = {}; // Clear stale data trước để tránh flash data cũ
    isLoadingDetail.value = true;
    try {
      final resp = await ApiClient().dio.get('/class/student/$studentId');
      if (resp.statusCode == 200) {
        studentDetail.value = Map<String, dynamic>.from(resp.data);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải thông tin HS');
    } finally {
      isLoadingDetail.value = false;
    }
  }
}
