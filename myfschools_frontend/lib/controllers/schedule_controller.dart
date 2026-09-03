import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../models/schedule_models.dart';

class ScheduleController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<WeeklyScheduleItem> weeklySchedule = <WeeklyScheduleItem>[].obs;
  final RxString className = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWeeklySchedule();
  }

  Future<void> fetchWeeklySchedule() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('/schedule/weekly');
      if (response.statusCode == 200) {
        className.value = response.data['className'] ?? '';
        final List<dynamic> data = response.data['schedules'];
        weeklySchedule.value = data.map((e) => WeeklyScheduleItem.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải lịch học');
    } finally {
      isLoading.value = false;
    }
  }

  List<WeeklyScheduleItem> getSchedulesByDay(int day) {
    return weeklySchedule.where((s) => s.dayOfWeek == day).toList();
  }
}
