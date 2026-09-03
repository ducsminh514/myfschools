import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../models/grade_models.dart';

class GradesController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<SemesterGrades?> semesterGrades = Rx<SemesterGrades?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchGrades();
  }

  Future<void> fetchGrades() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('grades');
      if (response.statusCode == 200) {
        semesterGrades.value = SemesterGrades.fromJson(response.data);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải bảng điểm');
    } finally {
      isLoading.value = false;
    }
  }
}
